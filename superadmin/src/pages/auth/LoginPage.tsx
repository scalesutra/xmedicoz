import React, { useState } from "react";
import { useAuth } from "../../context/AuthContext.js";
import { ShieldAlert, KeyRound, Mail, Sparkles, CheckCircle2, Eye, EyeOff } from "lucide-react";

export const LoginPage: React.FC<{ onLoginSuccess?: () => void }> = ({ onLoginSuccess }) => {
  const { loginWithPassword, sendOtp, verifyOtpAndLogin } = useAuth();

  const [authMode, setAuthMode] = useState<"PASSWORD" | "OTP">("PASSWORD");
  const [identifier, setIdentifier] = useState("admin@medicalcrm.local");
  const [password, setPassword] = useState("AdminPassword123!");
  const [showPassword, setShowPassword] = useState(false);
  const [otpCode, setOtpCode] = useState("");
  const [devOtp, setDevOtp] = useState<string | null>(null);
  const [otpSent, setOtpSent] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handlePasswordLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier || !password) {
      setErrorMsg("Please enter both administrator identifier and password.");
      return;
    }

    setIsLoading(true);
    setErrorMsg(null);
    const res = await loginWithPassword(identifier, password);
    setIsLoading(false);

    if (res.success) {
      setSuccessMsg("Superadmin credentials verified! Launching Control Plane...");
      setTimeout(() => {
        onLoginSuccess ? onLoginSuccess() : (window.location.href = "/");
      }, 600);
    } else {
      setErrorMsg(res.message || "Invalid credentials or unauthorized login.");
    }
  };

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier) {
      setErrorMsg("Please enter your registered Superadmin email.");
      return;
    }

    setIsLoading(true);
    setErrorMsg(null);
    const res = await sendOtp(identifier, "EMAIL");
    setIsLoading(false);

    if (res.success) {
      setOtpSent(true);
      if (res.otp) {
        setDevOtp(res.otp);
        setOtpCode(res.otp);
      }
      setSuccessMsg("Verification code dispatched to administrator email.");
    } else {
      setErrorMsg(res.message || "Failed to dispatch verification OTP.");
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otpCode || otpCode.length !== 4) {
      setErrorMsg("Please enter the 4-digit verification code.");
      return;
    }

    setIsLoading(true);
    setErrorMsg(null);
    const res = await verifyOtpAndLogin(identifier, otpCode, "EMAIL");
    setIsLoading(false);

    if (res.success) {
      setSuccessMsg("Superadmin session authenticated! Launching Control Plane...");
      setTimeout(() => {
        onLoginSuccess ? onLoginSuccess() : (window.location.href = "/");
      }, 600);
    } else {
      setErrorMsg(res.message || "Invalid or expired OTP code.");
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#0B0F17",
        backgroundImage: "radial-gradient(ellipse at top, rgba(99, 102, 241, 0.15), transparent 70%)",
        padding: "1.5rem",
        fontFamily: "'Plus Jakarta Sans', sans-serif",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "440px",
          backgroundColor: "#111827",
          border: "1px solid #1E293B",
          borderRadius: "16px",
          padding: "2.25rem",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.7)",
        }}
      >
        {/* Brand Icon & Heading */}
        <div style={{ textAlign: "center", marginBottom: "1.75rem" }}>
          <div
            style={{
              width: "52px",
              height: "52px",
              borderRadius: "14px",
              background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#FFFFFF",
              marginBottom: "1rem",
              boxShadow: "0 10px 25px -5px rgba(99, 102, 241, 0.5)",
            }}
          >
            <Sparkles size={26} />
          </div>
          <h2 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#F8FAFC", letterSpacing: "-0.02em" }}>
            Superadmin Command Center
          </h2>
          <p style={{ fontSize: "0.82rem", color: "#64748B", marginTop: "0.25rem" }}>
            MedicalCRM SaaS Platform Global Control Plane
          </p>
        </div>

        {/* Tab Selector */}
        <div
          style={{
            display: "flex",
            backgroundColor: "#0B0F17",
            borderRadius: "8px",
            padding: "4px",
            marginBottom: "1.5rem",
            border: "1px solid #1E293B",
          }}
        >
          <button
            type="button"
            onClick={() => {
              setAuthMode("PASSWORD");
              setErrorMsg(null);
            }}
            style={{
              flex: 1,
              padding: "0.5rem",
              borderRadius: "6px",
              border: "none",
              fontSize: "0.8rem",
              fontWeight: 700,
              cursor: "pointer",
              background: authMode === "PASSWORD" ? "#1E293B" : "transparent",
              color: authMode === "PASSWORD" ? "#F8FAFC" : "#64748B",
              transition: "all 0.15s ease",
            }}
          >
            Password
          </button>
          <button
            type="button"
            onClick={() => {
              setAuthMode("OTP");
              setErrorMsg(null);
            }}
            style={{
              flex: 1,
              padding: "0.5rem",
              borderRadius: "6px",
              border: "none",
              fontSize: "0.8rem",
              fontWeight: 700,
              cursor: "pointer",
              background: authMode === "OTP" ? "#1E293B" : "transparent",
              color: authMode === "OTP" ? "#F8FAFC" : "#64748B",
              transition: "all 0.15s ease",
            }}
          >
            One-Time Passcode (OTP)
          </button>
        </div>

        {/* Error Alert */}
        {errorMsg && (
          <div
            style={{
              padding: "0.75rem 1rem",
              borderRadius: "8px",
              backgroundColor: "rgba(244, 63, 94, 0.12)",
              border: "1px solid rgba(244, 63, 94, 0.3)",
              color: "#FDA4AF",
              fontSize: "0.8rem",
              marginBottom: "1.25rem",
              display: "flex",
              alignItems: "flex-start",
              gap: "0.6rem",
            }}
          >
            <ShieldAlert size={16} style={{ flexShrink: 0, marginTop: "2px" }} />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Success Alert */}
        {successMsg && (
          <div
            style={{
              padding: "0.75rem 1rem",
              borderRadius: "8px",
              backgroundColor: "rgba(16, 185, 129, 0.12)",
              border: "1px solid rgba(16, 185, 129, 0.3)",
              color: "#34D399",
              fontSize: "0.8rem",
              marginBottom: "1.25rem",
              display: "flex",
              alignItems: "center",
              gap: "0.6rem",
            }}
          >
            <CheckCircle2 size={16} />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Mode 1: Password Form */}
        {authMode === "PASSWORD" && (
          <form onSubmit={handlePasswordLogin} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <div>
              <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                Superadmin Email / Identifier
              </label>
              <div style={{ position: "relative" }}>
                <input
                  type="text"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="admin@medicalcrm.local"
                  className="input-control"
                  style={{ paddingLeft: "2.25rem" }}
                  required
                />
                <Mail size={16} color="#64748B" style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }} />
              </div>
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                Platform Security Password
              </label>
              <div style={{ position: "relative" }}>
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="input-control"
                  style={{ paddingLeft: "2.25rem", paddingRight: "2.5rem" }}
                  required
                />
                <KeyRound size={16} color="#64748B" style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }} />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: "absolute",
                    right: "0.75rem",
                    top: "50%",
                    transform: "translateY(-50%)",
                    background: "none",
                    border: "none",
                    color: "#94A3B8",
                    cursor: "pointer",
                    padding: "4px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                  title={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="btn btn-primary"
              style={{
                width: "100%",
                padding: "0.75rem",
                marginTop: "0.5rem",
                background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
                border: "1px solid #6366F1",
                boxShadow: "0 4px 14px rgba(99, 102, 241, 0.4)",
              }}
            >
              {isLoading ? "Authenticating Session..." : "Authorize Platform Access →"}
            </button>
          </form>
        )}

        {/* Mode 2: OTP Form */}
        {authMode === "OTP" && (
          <div>
            {!otpSent ? (
              <form onSubmit={handleSendOtp} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Registered Administrator Email
                  </label>
                  <div style={{ position: "relative" }}>
                    <input
                      type="text"
                      value={identifier}
                      onChange={(e) => setIdentifier(e.target.value)}
                      placeholder="admin@medicalcrm.local"
                      className="input-control"
                      style={{ paddingLeft: "2.25rem" }}
                      required
                    />
                    <Mail size={16} color="#64748B" style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }} />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="btn btn-primary"
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
                    border: "1px solid #6366F1",
                  }}
                >
                  {isLoading ? "Sending OTP..." : "Send Verification Code"}
                </button>
              </form>
            ) : (
              <form onSubmit={handleVerifyOtp} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                {devOtp && (
                  <div
                    style={{
                      padding: "0.6rem 0.85rem",
                      borderRadius: "6px",
                      backgroundColor: "rgba(6, 182, 212, 0.1)",
                      border: "1px solid rgba(6, 182, 212, 0.25)",
                      fontSize: "0.75rem",
                      color: "#38BDF8",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                    }}
                  >
                    <span>Developer OTP:</span>
                    <strong style={{ fontFamily: "monospace", fontSize: "0.95rem" }}>{devOtp}</strong>
                  </div>
                )}

                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Enter 4-Digit Security Code
                  </label>
                  <input
                    type="text"
                    maxLength={4}
                    value={otpCode}
                    onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
                    placeholder="0000"
                    className="input-control mono"
                    style={{
                      fontSize: "1.5rem",
                      letterSpacing: "0.5rem",
                      textAlign: "center",
                      fontWeight: 700,
                    }}
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="btn btn-primary"
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
                    border: "1px solid #6366F1",
                  }}
                >
                  {isLoading ? "Validating Code..." : "Verify & Sign In →"}
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setOtpSent(false);
                    setDevOtp(null);
                    setOtpCode("");
                  }}
                  style={{
                    background: "transparent",
                    border: "none",
                    color: "#64748B",
                    fontSize: "0.75rem",
                    cursor: "pointer",
                    textDecoration: "underline",
                  }}
                >
                  Change administrator email
                </button>
              </form>
            )}
          </div>
        )}

        {/* Footer info */}
        <div style={{ marginTop: "1.75rem", paddingTop: "1rem", borderTop: "1px solid #1E293B", textAlign: "center" }}>
          <p style={{ fontSize: "0.7rem", color: "#64748B" }}>
            Protected by Keycloak RBAC & isolated PostgreSQL multitenancy.
          </p>
        </div>
      </div>
    </div>
  );
};
