import React, { useState, useRef } from "react";
import { useAuth } from "../../context/AuthContext.js";
import { Lock, Mail, Phone, ShieldCheck, CheckCircle2, Eye, EyeOff } from "lucide-react";

export const LoginPage: React.FC<{ onLoginSuccess?: () => void }> = ({ onLoginSuccess }) => {
  const { loginWithPassword, sendOtp, verifyOtpAndLogin } = useAuth();

  const [activeTab, setActiveTab] = useState<"PASSWORD" | "OTP">("PASSWORD");
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  // OTP State
  const [otpChannel, setOtpChannel] = useState<"SMS" | "WHATSAPP">("SMS");
  const [otpSent, setOtpSent] = useState(false);
  const [devOtp, setDevOtp] = useState<string | null>(null);
  const [otpDigits, setOtpDigits] = useState(["", "", "", "", "", ""]);
  const otpInputRefs = [
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
  ];

  // Animation & Verification State
  const [isVerifying, setIsVerifying] = useState(false);
  const [isVerified, setIsVerified] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Handle Password Submit
  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier || !password) {
      setErrorMessage("Please enter both staff identifier and password");
      return;
    }

    setErrorMessage(null);
    setIsVerifying(true);

    const res = await loginWithPassword(identifier, password);

    if (res.success) {
      setIsVerifying(false);
      setIsVerified(true);
      setTimeout(() => {
        onLoginSuccess ? onLoginSuccess() : (window.location.href = "/");
      }, 700);
    } else {
      setIsVerifying(false);
      setErrorMessage(res.message || "Invalid login credentials. Please try again.");
    }
  };

  // Handle Send OTP
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier) {
      setErrorMessage("Please enter your registered mobile number or email");
      return;
    }

    setErrorMessage(null);
    setIsVerifying(true);

    const res = await sendOtp(identifier, otpChannel);
    setIsVerifying(false);

    if (res.success) {
      setOtpSent(true);
      setTimeout(() => otpInputRefs[0].current?.focus(), 100);
    } else {
      setErrorMessage(res.message || "Unable to send verification code");
    }
  };

  // Handle OTP digit entry
  const handleOtpChange = (index: number, val: string) => {
    if (val.length > 1) val = val.slice(-1);
    const updated = [...otpDigits];
    updated[index] = val;
    setOtpDigits(updated);

    if (val && index < 5) {
      otpInputRefs[index + 1].current?.focus();
    }
  };

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !otpDigits[index] && index > 0) {
      otpInputRefs[index - 1].current?.focus();
    }
  };

  // Handle Verify OTP
  const handleVerifyOtp = async () => {
    const fullOtp = otpDigits.join("");
    if (fullOtp.length !== 6) {
      setErrorMessage("Please enter complete 6-digit code");
      return;
    }

    setErrorMessage(null);
    setIsVerifying(true);

    const res = await verifyOtpAndLogin(identifier, fullOtp, otpChannel);

    if (res.success) {
      setIsVerifying(false);
      setIsVerified(true);
      setTimeout(() => {
        onLoginSuccess ? onLoginSuccess() : (window.location.href = "/");
      }, 700);
    } else {
      setIsVerifying(false);
      setErrorMessage(res.message || "Invalid or expired OTP");
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#0D1822",
        padding: "1.5rem",
        backgroundImage: "radial-gradient(ellipse at 50% 10%, rgba(5, 150, 105, 0.15) 0%, transparent 70%)",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "440px",
          backgroundColor: "#FFFFFF",
          borderRadius: "16px",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.35)",
          border: "1px solid #E2E8F0",
          overflow: "hidden",
        }}
        className="animate-scale-in"
      >
        {/* Brand Header */}
        <div
          style={{
            backgroundColor: "#0F766E",
            backgroundImage: "linear-gradient(135deg, #0F766E 0%, #059669 100%)",
            padding: "2rem 1.75rem",
            color: "#FFFFFF",
            textAlign: "center",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "8px", marginBottom: "0.4rem" }}>
            <div
              style={{
                backgroundColor: "#FFFFFF",
                color: "#0F766E",
                fontWeight: 900,
                fontSize: "1.25rem",
                width: "36px",
                height: "36px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                borderRadius: "8px",
                boxShadow: "0 2px 6px rgba(0, 0, 0, 0.15)",
                lineHeight: 1,
              }}
            >
              +
            </div>
            <div style={{ display: "flex", alignItems: "baseline" }}>
              <span style={{ fontSize: "1.75rem", fontWeight: 900, color: "#FFFFFF", letterSpacing: "-0.02em" }}>
                Medical
              </span>
              <span style={{ fontSize: "1.75rem", fontWeight: 900, color: "#A7F3D0", letterSpacing: "-0.02em" }}>
                CRM
              </span>
            </div>
          </div>
          <p style={{ fontSize: "0.76rem", color: "#D1FAE5", fontWeight: 700, letterSpacing: "0.08em", marginTop: "0.2rem", textTransform: "uppercase" }}>
            Enterprise Pharmacy ERP & Clinical Suite
          </p>
          <p style={{ fontSize: "0.78rem", opacity: 0.9, marginTop: "0.2rem" }}>
            Cloud Pharmacy Billing & Inventory Management
          </p>
        </div>

        {/* Tab Switcher */}
        <div
          style={{
            display: "flex",
            backgroundColor: "#F8FAF9",
            borderBottom: "1px solid #E2E8F0",
            padding: "0.35rem",
          }}
        >
          <button
            onClick={() => {
              setActiveTab("PASSWORD");
              setErrorMessage(null);
            }}
            style={{
              flex: 1,
              padding: "0.65rem",
              borderRadius: "8px",
              border: "none",
              backgroundColor: activeTab === "PASSWORD" ? "#FFFFFF" : "transparent",
              color: activeTab === "PASSWORD" ? "#0F766E" : "#64748B",
              fontWeight: activeTab === "PASSWORD" ? 700 : 500,
              fontSize: "0.85rem",
              cursor: "pointer",
              boxShadow: activeTab === "PASSWORD" ? "0 1px 3px rgba(0, 0, 0, 0.08)" : "none",
              transition: "all 0.15s ease",
            }}
          >
            Staff Password
          </button>
          <button
            onClick={() => {
              setActiveTab("OTP");
              setErrorMessage(null);
            }}
            style={{
              flex: 1,
              padding: "0.65rem",
              borderRadius: "8px",
              border: "none",
              backgroundColor: activeTab === "OTP" ? "#FFFFFF" : "transparent",
              color: activeTab === "OTP" ? "#0F766E" : "#64748B",
              fontWeight: activeTab === "OTP" ? 700 : 500,
              fontSize: "0.85rem",
              cursor: "pointer",
              boxShadow: activeTab === "OTP" ? "0 1px 3px rgba(0, 0, 0, 0.08)" : "none",
              transition: "all 0.15s ease",
            }}
          >
            6-Digit Instant OTP
          </button>
        </div>

        {/* Form Body */}
        <div style={{ padding: "1.75rem" }}>
          {errorMessage && (
            <div
              style={{
                padding: "0.75rem 1rem",
                borderRadius: "8px",
                backgroundColor: "rgba(239, 68, 68, 0.10)",
                border: "1px solid rgba(239, 68, 68, 0.25)",
                color: "#DC2626",
                fontSize: "0.82rem",
                fontWeight: 500,
                marginBottom: "1.25rem",
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
              }}
            >
              <span>⚠️</span>
              <span>{errorMessage}</span>
            </div>
          )}

          {activeTab === "PASSWORD" ? (
            <form onSubmit={handlePasswordSubmit}>
              <div style={{ marginBottom: "1.2rem" }}>
                <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 600, color: "#334155", marginBottom: "0.4rem" }}>
                  Staff Email or Mobile Number
                </label>
                <div style={{ position: "relative" }}>
                  <div style={{ position: "absolute", left: "0.9rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
                    <Mail size={16} />
                  </div>
                  <input
                    type="text"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="e.g. staff@pharmacy.com or +91 98000 00000"
                    style={{
                      width: "100%",
                      padding: "0.7rem 0.9rem 0.7rem 2.4rem",
                      borderRadius: "8px",
                      border: "1px solid #CBD5E1",
                      fontSize: "0.9rem",
                      outline: "none",
                    }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 600, color: "#334155", marginBottom: "0.4rem" }}>
                  Account Password
                </label>
                <div style={{ position: "relative" }}>
                  <div style={{ position: "absolute", left: "0.9rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
                    <Lock size={16} />
                  </div>
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your staff password"
                    style={{
                      width: "100%",
                      padding: "0.7rem 2.5rem 0.7rem 2.4rem",
                      borderRadius: "8px",
                      border: "1px solid #CBD5E1",
                      fontSize: "0.9rem",
                      outline: "none",
                    }}
                  />
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

              {/* Action Button with Animated Verification */}
              <button
                type="submit"
                disabled={isVerifying || isVerified}
                style={{
                  width: "100%",
                  padding: "0.8rem",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: isVerified ? "#059669" : "#0F766E",
                  color: "#FFFFFF",
                  fontSize: "0.92rem",
                  fontWeight: 700,
                  cursor: isVerifying || isVerified ? "default" : "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "0.6rem",
                  boxShadow: "0 4px 10px rgba(15, 118, 110, 0.25)",
                  transition: "all 0.25s ease",
                }}
              >
                {isVerifying ? (
                  <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                    <svg
                      style={{ width: "20px", height: "20px" }}
                      viewBox="0 0 24 24"
                      fill="none"
                      className="animate-spin-slow"
                    >
                      <circle
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="rgba(255,255,255,0.3)"
                        strokeWidth="3"
                      />
                      <path
                        d="M12 2a10 10 0 0 1 10 10"
                        stroke="#FFFFFF"
                        strokeWidth="3"
                        strokeLinecap="round"
                      />
                    </svg>
                    <span>Verifying Credentials...</span>
                  </div>
                ) : isVerified ? (
                  <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }} className="animate-scale-in">
                    <CheckCircle2 size={20} color="#FFFFFF" />
                    <span>Verified! Entering ERP...</span>
                  </div>
                ) : (
                  "Sign In to Portal"
                )}
              </button>
            </form>
          ) : (
            <div>
              {!otpSent ? (
                <form onSubmit={handleSendOtp}>
                  <div style={{ marginBottom: "1.2rem" }}>
                    <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 600, color: "#334155", marginBottom: "0.4rem" }}>
                      Registered Mobile Number or Email
                    </label>
                    <div style={{ position: "relative" }}>
                      <div style={{ position: "absolute", left: "0.9rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
                        <Phone size={16} />
                      </div>
                      <input
                        type="text"
                        value={identifier}
                        onChange={(e) => setIdentifier(e.target.value)}
                        placeholder="e.g. +91 98000 00000 or staff@pharmacy.com"
                        style={{
                          width: "100%",
                          padding: "0.7rem 0.9rem 0.7rem 2.4rem",
                          borderRadius: "8px",
                          border: "1px solid #CBD5E1",
                          fontSize: "0.9rem",
                          outline: "none",
                        }}
                      />
                    </div>
                  </div>

                  <div style={{ marginBottom: "1.5rem" }}>
                    <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 600, color: "#334155", marginBottom: "0.4rem" }}>
                      Delivery Channel
                    </label>
                    <div style={{ display: "flex", gap: "0.75rem" }}>
                      <label style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem", color: "#475569" }}>
                        <input
                          type="radio"
                          name="channel"
                          checked={otpChannel === "SMS"}
                          onChange={() => setOtpChannel("SMS")}
                        />
                        SMS Message
                      </label>
                      <label style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem", color: "#475569" }}>
                        <input
                          type="radio"
                          name="channel"
                          checked={otpChannel === "WHATSAPP"}
                          onChange={() => setOtpChannel("WHATSAPP")}
                        />
                        WhatsApp
                      </label>
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isVerifying}
                    style={{
                      width: "100%",
                      padding: "0.8rem",
                      borderRadius: "8px",
                      border: "none",
                      backgroundColor: "#059669",
                      color: "#FFFFFF",
                      fontSize: "0.92rem",
                      fontWeight: 700,
                      cursor: isVerifying ? "default" : "pointer",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "0.6rem",
                      boxShadow: "0 4px 10px rgba(5, 150, 105, 0.25)",
                    }}
                  >
                    {isVerifying ? (
                      <span className="animate-spin-slow">⏳ Sending Code...</span>
                    ) : (
                      "Send 6-Digit Passcode"
                    )}
                  </button>
                </form>
              ) : (
                <div>
                  <p style={{ fontSize: "0.85rem", color: "#64748B", marginBottom: "1.2rem", textAlign: "center" }}>
                    Enter the 6-digit passcode sent to <strong>{identifier}</strong>
                  </p>

                  {/* 6-Digit Animated Input Boxes */}
                  <div style={{ display: "flex", justifyContent: "center", gap: "0.5rem", marginBottom: "1.5rem" }}>
                    {otpDigits.map((digit, idx) => (
                      <input
                        key={idx}
                        ref={otpInputRefs[idx]}
                        type="text"
                        inputMode="numeric"
                        maxLength={1}
                        value={digit}
                        onChange={(e) => handleOtpChange(idx, e.target.value)}
                        onKeyDown={(e) => handleOtpKeyDown(idx, e)}
                        style={{
                          width: "46px",
                          height: "52px",
                          textAlign: "center",
                          fontSize: "1.35rem",
                          fontWeight: 700,
                          borderRadius: "10px",
                          border: digit ? "2px solid #059669" : "2px solid #CBD5E1",
                          backgroundColor: digit ? "#ECFDF5" : "#FFFFFF",
                          color: "#0F172A",
                          outline: "none",
                          transition: "all 0.15s ease",
                        }}
                      />
                    ))}
                  </div>

                  {/* Verify Action Button */}
                  <button
                    onClick={handleVerifyOtp}
                    disabled={isVerifying || isVerified}
                    style={{
                      width: "100%",
                      padding: "0.8rem",
                      borderRadius: "8px",
                      border: "none",
                      backgroundColor: isVerified ? "#059669" : "#0F766E",
                      color: "#FFFFFF",
                      fontSize: "0.92rem",
                      fontWeight: 700,
                      cursor: isVerifying || isVerified ? "default" : "pointer",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "0.6rem",
                      boxShadow: "0 4px 10px rgba(15, 118, 110, 0.25)",
                    }}
                  >
                    {isVerifying ? (
                      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                        <svg
                          style={{ width: "20px", height: "20px" }}
                          viewBox="0 0 24 24"
                          fill="none"
                          className="animate-spin-slow"
                        >
                          <circle cx="12" cy="12" r="10" stroke="rgba(255,255,255,0.3)" strokeWidth="3" />
                          <path d="M12 2a10 10 0 0 1 10 10" stroke="#FFFFFF" strokeWidth="3" strokeLinecap="round" />
                        </svg>
                        <span>Verifying Passcode...</span>
                      </div>
                    ) : isVerified ? (
                      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                        <CheckCircle2 size={20} color="#FFFFFF" />
                        <span>Passcode Verified! Entering ERP...</span>
                      </div>
                    ) : (
                      "Verify & Enter Portal"
                    )}
                  </button>

                  <div style={{ textAlign: "center", marginTop: "1rem" }}>
                    <button
                      onClick={() => setOtpSent(false)}
                      style={{
                        background: "none",
                        border: "none",
                        color: "#059669",
                        fontSize: "0.82rem",
                        fontWeight: 600,
                        cursor: "pointer",
                      }}
                    >
                      ← Change contact address or resend
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
