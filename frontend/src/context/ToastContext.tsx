import React, { createContext, useContext, useState, useCallback, useEffect } from "react";
import { CheckCircle2, AlertCircle, AlertTriangle, Info, X } from "lucide-react";

export type ToastType = "success" | "error" | "warning" | "info";

export interface ToastItem {
  id: string;
  type: ToastType;
  title?: string;
  message: string;
  duration?: number;
}

interface ToastContextType {
  toasts: ToastItem[];
  showToast: (message: string, type?: ToastType, title?: string, duration?: number) => void;
  success: (message: string, title?: string) => void;
  error: (message: string, title?: string) => void;
  warning: (message: string, title?: string) => void;
  info: (message: string, title?: string) => void;
  removeToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback(
    (message: string, type: ToastType = "info", title?: string, duration = 3800) => {
      const id = Math.random().toString(36).substring(2, 9);
      const newToast: ToastItem = { id, type, title, message, duration };

      setToasts((prev) => [...prev.slice(-4), newToast]); // keep max 5 toasts

      if (duration > 0) {
        setTimeout(() => {
          removeToast(id);
        }, duration);
      }
    },
    [removeToast]
  );

  const success = useCallback((message: string, title?: string) => {
    showToast(message, "success", title || "Action Completed");
  }, [showToast]);

  const error = useCallback((message: string, title?: string) => {
    showToast(message, "error", title || "Attention Required");
  }, [showToast]);

  const warning = useCallback((message: string, title?: string) => {
    showToast(message, "warning", title || "Notice");
  }, [showToast]);

  const info = useCallback((message: string, title?: string) => {
    showToast(message, "info", title || "Information");
  }, [showToast]);

  // Intercept window.alert so even legacy or accidental alert() calls show as modern toasts
  useEffect(() => {
    const originalAlert = window.alert;
    window.alert = (msg: any) => {
      const text = String(msg || "");
      if (text.toLowerCase().includes("success") || text.toLowerCase().includes("completed") || text.toLowerCase().includes("dispatched")) {
        success(text);
      } else if (text.toLowerCase().includes("fail") || text.toLowerCase().includes("error") || text.toLowerCase().includes("cannot")) {
        error(text);
      } else if (text.toLowerCase().includes("please") || text.toLowerCase().includes("select") || text.toLowerCase().includes("provide")) {
        warning(text);
      } else {
        info(text);
      }
    };

    return () => {
      window.alert = originalAlert;
    };
  }, [success, error, warning, info]);

  return (
    <ToastContext.Provider
      value={{
        toasts,
        showToast,
        success,
        error,
        warning,
        info,
        removeToast,
      }}
    >
      {children}

      {/* Floating Toast Notification Container */}
      <div
        style={{
          position: "fixed",
          top: "1.25rem",
          right: "1.25rem",
          zIndex: 99999,
          display: "flex",
          flexDirection: "column",
          gap: "0.65rem",
          pointerEvents: "none",
          maxWidth: "380px",
          width: "calc(100vw - 2.5rem)",
        }}
      >
        {toasts.map((toast) => {
          const config = {
            success: {
              icon: <CheckCircle2 size={18} color="#059669" />,
              border: "#10B981",
              bg: "#FFFFFF",
              badgeBg: "#ECFDF5",
              badgeColor: "#065F46",
              accent: "#059669",
            },
            error: {
              icon: <AlertCircle size={18} color="#DC2626" />,
              border: "#EF4444",
              bg: "#FFFFFF",
              badgeBg: "#FEF2F2",
              badgeColor: "#991B1B",
              accent: "#DC2626",
            },
            warning: {
              icon: <AlertTriangle size={18} color="#D97706" />,
              border: "#F59E0B",
              bg: "#FFFFFF",
              badgeBg: "#FFFBEB",
              badgeColor: "#92400E",
              accent: "#D97706",
            },
            info: {
              icon: <Info size={18} color="#0284C7" />,
              border: "#06B6D4",
              bg: "#FFFFFF",
              badgeBg: "#F0FDFA",
              badgeColor: "#155E75",
              accent: "#0284C7",
            },
          }[toast.type];

          return (
            <div
              key={toast.id}
              className="animate-fade-in"
              style={{
                pointerEvents: "auto",
                backgroundColor: config.bg,
                borderLeft: `4px solid ${config.border}`,
                borderTop: "1px solid #E2E8F0",
                borderRight: "1px solid #E2E8F0",
                borderBottom: "1px solid #E2E8F0",
                borderRadius: "8px",
                padding: "0.85rem 1rem",
                boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.12), 0 8px 10px -6px rgba(0, 0, 0, 0.08)",
                display: "flex",
                alignItems: "flex-start",
                gap: "0.75rem",
                position: "relative",
                overflow: "hidden",
              }}
            >
              <div style={{ flexShrink: 0, marginTop: "1px" }}>{config.icon}</div>

              <div style={{ flex: 1, minWidth: 0 }}>
                {toast.title && (
                  <div
                    style={{
                      fontSize: "0.82rem",
                      fontWeight: 700,
                      color: "#0F172A",
                      marginBottom: "0.15rem",
                    }}
                  >
                    {toast.title}
                  </div>
                )}
                <div
                  style={{
                    fontSize: "0.8rem",
                    color: "#334155",
                    lineHeight: 1.4,
                    wordBreak: "break-word",
                  }}
                >
                  {toast.message}
                </div>
              </div>

              <button
                onClick={() => removeToast(toast.id)}
                style={{
                  background: "none",
                  border: "none",
                  color: "#94A3B8",
                  cursor: "pointer",
                  padding: "0.2rem",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  borderRadius: "4px",
                  flexShrink: 0,
                }}
                onMouseEnter={(e) => (e.currentTarget.style.color = "#475569")}
                onMouseLeave={(e) => (e.currentTarget.style.color = "#94A3B8")}
              >
                <X size={14} />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
};

export const useToast = (): ToastContextType => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider");
  }
  return context;
};
