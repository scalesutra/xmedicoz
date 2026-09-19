/**
 * Production API Client for MedicalCRM Backend
 * Live Base: http://134.195.138.153:5095/api/v1
 * Features:
 *  - Proactive JWT expiry check (auto-refreshes before expiry)
 *  - Deduplicated refresh promise (no race conditions, no hung requests)
 *  - Reactive 401 fallback with transparent request replay
 *  - Background interval & tab focus heartbeat
 */

const API_BASE_URL = "http://134.195.138.153:5095/api/v1";

interface RequestOptions extends RequestInit {
  params?: Record<string, string | number | boolean | undefined>;
  _retry?: boolean;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  code?: string;
  details?: any;
}

// In-flight refresh promise singleton to prevent duplicate concurrent refresh requests
let refreshPromise: Promise<string | null> | null = null;

/**
 * Safely parse JWT payload without external library
 */
function parseJwtPayload(token: string): { exp?: number; [key: string]: any } | null {
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join("")
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

/**
 * Check if a JWT is expired or will expire within threshold seconds (default 120s / 2 mins)
 */
export function isTokenExpiredOrExpiringSoon(token: string, thresholdSeconds = 120): boolean {
  const payload = parseJwtPayload(token);
  if (!payload || !payload.exp) return true;
  const nowInSeconds = Math.floor(Date.now() / 1000);
  return payload.exp - nowInSeconds < thresholdSeconds;
}

/**
 * Perform token refresh against backend /auth/refresh
 */
export async function refreshAccessToken(): Promise<string | null> {
  // If an active refresh is already underway, return the existing promise
  if (refreshPromise) {
    return refreshPromise;
  }

  const refreshToken = localStorage.getItem("mcrm_refresh_token");
  if (!refreshToken) {
    return null;
  }

  refreshPromise = (async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken }),
      });

      if (!res.ok) {
        // If refresh token is expired or unauthorized, clear storage and dispatch event
        if (res.status === 401 || res.status === 400) {
          localStorage.removeItem("mcrm_access_token");
          localStorage.removeItem("mcrm_refresh_token");
          localStorage.removeItem("mcrm_user");
          if (typeof window !== "undefined") {
            window.dispatchEvent(new CustomEvent("mcrm:session:expired"));
          }
        }
        return null;
      }

      const data = await res.json();
      const newAccessToken =
        data.data?.tokens?.accessToken ||
        data.data?.accessToken ||
        data.accessToken;
      const newRefreshToken =
        data.data?.tokens?.refreshToken ||
        data.data?.refreshToken ||
        data.refreshToken;

      if (newAccessToken) {
        localStorage.setItem("mcrm_access_token", newAccessToken);
        if (newRefreshToken) {
          localStorage.setItem("mcrm_refresh_token", newRefreshToken);
        }
        return newAccessToken;
      }
      return null;
    } catch (err) {
      console.warn("Auto-refresh network error (backend might be momentarily restarting):", err);
      return null;
    } finally {
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

/**
 * Proactively check and obtain a valid non-expired access token
 */
async function getValidAccessToken(): Promise<string | null> {
  const token = localStorage.getItem("mcrm_access_token");
  if (!token) return null;

  // If token is expiring within 2 minutes, proactively refresh it right now
  if (isTokenExpiredOrExpiringSoon(token, 120)) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return refreshed;
    }
  }

  return token;
}

/**
 * Universal Production API Request with Proactive & Reactive JWT Management
 */
export async function apiRequest<T = any>(
  endpoint: string,
  options: RequestOptions = {}
): Promise<ApiResponse<T>> {
  // 1. Obtain verified valid token (proactively refreshed if close to expiry)
  const isAuthRoute =
    endpoint.includes("/auth/login") ||
    endpoint.includes("/auth/refresh") ||
    endpoint.includes("/auth/request-otp") ||
    endpoint.includes("/auth/verify-otp");

  let token = !isAuthRoute ? await getValidAccessToken() : localStorage.getItem("mcrm_access_token");

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const activeShopId = localStorage.getItem("mcrm_active_shop_id");
  if (activeShopId) {
    headers["x-shop-id"] = activeShopId;
  }

  let url = `${API_BASE_URL}${endpoint.startsWith("/") ? endpoint : `/${endpoint}`}`;

  if (options.params) {
    const query = new URLSearchParams();
    for (const [key, val] of Object.entries(options.params)) {
      if (val !== undefined && val !== null) {
        query.append(key, String(val));
      }
    }
    const queryString = query.toString();
    if (queryString) {
      url += (url.includes("?") ? "&" : "?") + queryString;
    }
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    // 2. Reactive 401 fallback: If 401 received and not already retried
    if (response.status === 401 && !options._retry && !isAuthRoute) {
      const newToken = await refreshAccessToken();
      if (newToken) {
        // Transparently replay with the new token
        return apiRequest<T>(endpoint, {
          ...options,
          _retry: true,
          headers: {
            ...headers,
            Authorization: `Bearer ${newToken}`,
          },
        });
      } else {
        return {
          success: false,
          code: "UNAUTHORIZED",
          message: "Session expired. Please log in again.",
        };
      }
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errMsg =
        data.error?.message ||
        data.message ||
        (typeof data.error === "string" ? data.error : null) ||
        `Request failed with status ${response.status}`;
      return {
        success: false,
        message: errMsg,
        code: data.error?.code || data.code,
        details: data.error?.details || data.details,
      };
    }

    return {
      success: true,
      data: data.data !== undefined ? data.data : data,
      message: data.message,
    };
  } catch (err: any) {
    return {
      success: false,
      message: err.message || "Network error. Unable to communicate with MedicalCRM backend.",
    };
  }
}

/**
 * Background Heartbeat & Window Focus Listeners
 * Keeps the clinical session alive in the background without disturbing user workflow.
 */
if (typeof window !== "undefined") {
  // 1. Periodic background check every 3 minutes
  setInterval(() => {
    const token = localStorage.getItem("mcrm_access_token");
    if (token && isTokenExpiredOrExpiringSoon(token, 300)) {
      refreshAccessToken().catch(() => {});
    }
  }, 3 * 60 * 1000);

  // 2. Refresh when switching back to tab
  window.addEventListener("focus", () => {
    const token = localStorage.getItem("mcrm_access_token");
    if (token && isTokenExpiredOrExpiringSoon(token, 180)) {
      refreshAccessToken().catch(() => {});
    }
  });

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") {
      const token = localStorage.getItem("mcrm_access_token");
      if (token && isTokenExpiredOrExpiringSoon(token, 180)) {
        refreshAccessToken().catch(() => {});
      }
    }
  });
}
