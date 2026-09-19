export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

const getApiBase = () => {
  if (typeof window !== "undefined") {
    const host = window.location.hostname || "localhost";
    return `http://${host}:5095/api/v1`;
  }
  return "http://localhost:5095/api/v1";
};

export const API_BASE = getApiBase();

export async function apiRequest<T = any>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const token = localStorage.getItem("mcrm_superadmin_token");

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const url = endpoint.startsWith("http") ? endpoint : `${API_BASE}${endpoint}`;

  try {
    const res = await fetch(url, {
      ...options,
      headers,
    });

    const json: ApiResponse<T> = await res.json().catch(() => ({
      success: false,
      error: { code: "INVALID_JSON", message: "Failed to parse response" },
    }));

    if (res.status === 401) {
      localStorage.removeItem("mcrm_superadmin_token");
      localStorage.removeItem("mcrm_superadmin_user");
      window.dispatchEvent(new Event("mcrm:superadmin:unauthorized"));
    }

    return json;
  } catch (err: any) {
    return {
      success: false,
      error: {
        code: "NETWORK_ERROR",
        message: err.message || "Network request failed",
      },
    };
  }
}
