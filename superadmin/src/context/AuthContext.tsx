import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import { apiRequest } from "../api/client.js";

export interface SuperadminUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  roles: string[];
}

interface AuthContextType {
  user: SuperadminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  loginWithPassword: (identifier: string, password: string) => Promise<{ success: boolean; message?: string }>;
  sendOtp: (identifier: string, channel?: string) => Promise<{ success: boolean; message?: string; otp?: string }>;
  verifyOtpAndLogin: (identifier: string, code: string, channel?: string) => Promise<{ success: boolean; message?: string }>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<SuperadminUser | null>(() => {
    const saved = localStorage.getItem("mcrm_superadmin_user");
    return saved ? JSON.parse(saved) : null;
  });
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const isSuperadminRole = (roles: string[] = []) => {
    return roles.some((r) => r.toLowerCase() === "admin" || r.toLowerCase() === "superadmin");
  };

  const refreshProfile = useCallback(async () => {
    const token = localStorage.getItem("mcrm_superadmin_token");
    if (!token) {
      setUser(null);
      setIsLoading(false);
      return;
    }

    const res = await apiRequest<SuperadminUser>("/auth/profile");
    if (res.success && res.data) {
      if (!isSuperadminRole(res.data.roles)) {
        // Reject non-admin users
        localStorage.removeItem("mcrm_superadmin_token");
        localStorage.removeItem("mcrm_superadmin_user");
        setUser(null);
      } else {
        setUser(res.data);
        localStorage.setItem("mcrm_superadmin_user", JSON.stringify(res.data));
      }
    } else {
      localStorage.removeItem("mcrm_superadmin_token");
      localStorage.removeItem("mcrm_superadmin_user");
      setUser(null);
    }
    setIsLoading(false);
  }, []);

  useEffect(() => {
    refreshProfile();

    const handleUnauthorized = () => {
      setUser(null);
    };
    window.addEventListener("mcrm:superadmin:unauthorized", handleUnauthorized);
    return () => {
      window.removeEventListener("mcrm:superadmin:unauthorized", handleUnauthorized);
    };
  }, [refreshProfile]);

  const loginWithPassword = async (identifier: string, password: string) => {
    const res = await apiRequest<{
      tokens?: { accessToken: string };
      accessToken?: string;
      user?: SuperadminUser;
    }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ identifier, password }),
    });

    const token = res.data?.tokens?.accessToken || res.data?.accessToken;
    const userData = res.data?.user;

    if (res.success && token && userData) {
      if (!isSuperadminRole(userData.roles)) {
        return {
          success: false,
          message: "Access Denied: You must have Platform Administrator credentials to access the Superadmin Control Plane.",
        };
      }

      localStorage.setItem("mcrm_superadmin_token", token);
      localStorage.setItem("mcrm_superadmin_user", JSON.stringify(userData));
      setUser(userData);
      return { success: true };
    }

    return {
      success: false,
      message: res.error?.message || "Invalid credentials or unauthorized login.",
    };
  };

  const sendOtp = async (identifier: string, channel: string = "EMAIL") => {
    const res = await apiRequest<{ otp?: string }>("/auth/request-otp", {
      method: "POST",
      body: JSON.stringify({ identifier, channel, purpose: "LOGIN" }),
    });

    if (res.success) {
      return { success: true, otp: res.data?.otp, message: res.message };
    }

    return {
      success: false,
      message: res.error?.message || "Failed to dispatch verification OTP.",
    };
  };

  const verifyOtpAndLogin = async (identifier: string, code: string, channel: string = "EMAIL") => {
    const res = await apiRequest<{
      tokens?: { accessToken: string };
      accessToken?: string;
      user?: SuperadminUser;
    }>("/auth/verify-otp", {
      method: "POST",
      body: JSON.stringify({ identifier, code, channel, purpose: "LOGIN" }),
    });

    const token = res.data?.tokens?.accessToken || res.data?.accessToken;
    const userData = res.data?.user;

    if (res.success && token && userData) {
      if (!isSuperadminRole(userData.roles)) {
        return {
          success: false,
          message: "Access Denied: You must have Platform Administrator credentials to access the Superadmin Control Plane.",
        };
      }

      localStorage.setItem("mcrm_superadmin_token", token);
      localStorage.setItem("mcrm_superadmin_user", JSON.stringify(userData));
      setUser(userData);
      return { success: true };
    }

    return {
      success: false,
      message: res.error?.message || "Invalid or expired OTP code.",
    };
  };

  const logout = () => {
    localStorage.removeItem("mcrm_superadmin_token");
    localStorage.removeItem("mcrm_superadmin_user");
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        loginWithPassword,
        sendOtp,
        verifyOtpAndLogin,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
