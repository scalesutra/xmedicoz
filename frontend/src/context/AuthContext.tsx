import React, { createContext, useContext, useState, useEffect } from "react";
import { apiRequest } from "../api/client.js";

export interface UserProfile {
  id: string;
  email: string;
  phone?: string;
  firstName: string;
  lastName: string;
  status: string;
  roles: string[];
}

interface AuthContextType {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  loginWithPassword: (identifier: string, password: string) => Promise<{ success: boolean; message?: string }>;
  sendOtp: (identifier: string, channel?: string) => Promise<{ success: boolean; message?: string; otp?: string }>;
  verifyOtpAndLogin: (identifier: string, otp: string, channel?: string) => Promise<{ success: boolean; message?: string }>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(() => {
    const saved = localStorage.getItem("mcrm_user");
    return saved ? JSON.parse(saved) : null;
  });
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const refreshProfile = async () => {
    const token = localStorage.getItem("mcrm_access_token");
    if (!token) {
      setUser(null);
      setIsLoading(false);
      return;
    }

    const res = await apiRequest<UserProfile>("/auth/profile");
    if (res.success && res.data) {
      setUser(res.data);
      localStorage.setItem("mcrm_user", JSON.stringify(res.data));
    } else if (res.code === "UNAUTHORIZED") {
      // Truly unauthorized / session expired
      localStorage.removeItem("mcrm_access_token");
      localStorage.removeItem("mcrm_refresh_token");
      localStorage.removeItem("mcrm_user");
      setUser(null);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    refreshProfile();

    const handleExpired = () => {
      setUser(null);
    };
    window.addEventListener("mcrm:session:expired", handleExpired);
    return () => {
      window.removeEventListener("mcrm:session:expired", handleExpired);
    };
  }, []);

  const loginWithPassword = async (identifier: string, password: string) => {
    const res = await apiRequest<{
      tokens?: { accessToken: string; refreshToken?: string };
      accessToken?: string;
      refreshToken?: string;
      user?: UserProfile;
    }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ identifier, password }),
    });

    const accessToken = res.data?.tokens?.accessToken || res.data?.accessToken;
    const refreshToken = res.data?.tokens?.refreshToken || res.data?.refreshToken;
    const userData = res.data?.user;

    if (res.success && accessToken) {
      localStorage.setItem("mcrm_access_token", accessToken);
      if (refreshToken) {
        localStorage.setItem("mcrm_refresh_token", refreshToken);
      }
      if (userData) {
        setUser(userData);
        localStorage.setItem("mcrm_user", JSON.stringify(userData));
      }
      // Refresh profile in background
      refreshProfile().catch(() => {});
      return { success: true };
    }

    return { success: false, message: res.message || "Invalid credentials" };
  };

  const sendOtp = async (identifier: string, _channel = "SMS") => {
    const isEmail = identifier.includes("@");
    const res = await apiRequest<{ expiresInSeconds: number; otp?: string }>("/auth/request-otp", {
      method: "POST",
      body: JSON.stringify({
        identifier,
        channel: isEmail ? "EMAIL" : "PHONE",
        purpose: "LOGIN",
      }),
    });
    return { success: res.success, message: res.message, otp: res.data?.otp };
  };

  const verifyOtpAndLogin = async (identifier: string, otp: string, _channel = "SMS") => {
    const isEmail = identifier.includes("@");
    const res = await apiRequest<{
      tokens?: { accessToken: string; refreshToken?: string };
      accessToken?: string;
      refreshToken?: string;
      user?: UserProfile;
    }>("/auth/verify-otp", {
      method: "POST",
      body: JSON.stringify({
        identifier,
        code: otp,
        channel: isEmail ? "EMAIL" : "PHONE",
        purpose: "LOGIN",
      }),
    });

    const accessToken = res.data?.tokens?.accessToken || res.data?.accessToken;
    const refreshToken = res.data?.tokens?.refreshToken || res.data?.refreshToken;
    const userData = res.data?.user;

    if (res.success && accessToken) {
      localStorage.setItem("mcrm_access_token", accessToken);
      if (refreshToken) {
        localStorage.setItem("mcrm_refresh_token", refreshToken);
      }
      if (userData) {
        setUser(userData);
        localStorage.setItem("mcrm_user", JSON.stringify(userData));
      }
      refreshProfile().catch(() => {});
      return { success: true };
    }

    return { success: false, message: res.message || "Invalid OTP entered" };
  };

  const logout = () => {
    localStorage.removeItem("mcrm_access_token");
    localStorage.removeItem("mcrm_refresh_token");
    localStorage.removeItem("mcrm_user");
    setUser(null);
    window.location.href = "/login";
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

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
