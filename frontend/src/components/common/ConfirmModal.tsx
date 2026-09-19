import React from "react";
import { AlertTriangle, X } from "lucide-react";

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: "danger" | "primary" | "warning";
  isLoading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title,
  message,
  confirmLabel = "Confirm Action",
  cancelLabel = "Cancel",
  variant = "primary",
  isLoading = false,
  onConfirm,
  onCancel,
}) => {
  if (!isOpen) return null;

  const getButtonBg = () => {
    switch (variant) {
      case "danger":
        return "bg-crimson";
      case "warning":
        return "bg-amber";
      default:
        return "bg-emerald";
    }
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 9999,
        backgroundColor: "rgba(13, 24, 34, 0.6)",
        backdropFilter: "blur(4px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "1rem",
      }}
      className="animate-scale-in"
    >
      <div
        style={{
          backgroundColor: "#FFFFFF",
          borderRadius: "14px",
          width: "100%",
          maxWidth: "460px",
          boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
          border: "1px solid #E2E8F0",
          overflow: "hidden",
        }}
      >
        {/* Header */}
        <div
          style={{
            padding: "1.25rem 1.5rem",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            borderBottom: "1px solid #F1F5F9",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "8px",
                backgroundColor:
                  variant === "danger"
                    ? "rgba(239, 68, 68, 0.12)"
                    : variant === "warning"
                    ? "rgba(245, 158, 11, 0.12)"
                    : "rgba(5, 150, 105, 0.12)",
                color:
                  variant === "danger"
                    ? "#DC2626"
                    : variant === "warning"
                    ? "#D97706"
                    : "#059669",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <AlertTriangle size={20} />
            </div>
            <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
              {title}
            </h3>
          </div>
          <button
            onClick={onCancel}
            disabled={isLoading}
            style={{
              background: "none",
              border: "none",
              cursor: "pointer",
              color: "#94A3B8",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div style={{ padding: "1.5rem", color: "#475569", fontSize: "0.95rem", lineHeight: 1.6 }}>
          {message}
        </div>

        {/* Footer */}
        <div
          style={{
            padding: "1rem 1.5rem",
            backgroundColor: "#F8FAF9",
            borderTop: "1px solid #F1F5F9",
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.75rem",
          }}
        >
          <button
            onClick={onCancel}
            disabled={isLoading}
            style={{
              padding: "0.55rem 1.1rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              backgroundColor: "#FFFFFF",
              color: "#334155",
              fontWeight: 600,
              fontSize: "0.9rem",
              cursor: "pointer",
              transition: "all 0.15s ease",
            }}
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={isLoading}
            style={{
              padding: "0.55rem 1.25rem",
              borderRadius: "8px",
              border: "none",
              backgroundColor:
                variant === "danger"
                  ? "#DC2626"
                  : variant === "warning"
                  ? "#D97706"
                  : "#059669",
              color: "#FFFFFF",
              fontWeight: 600,
              fontSize: "0.9rem",
              cursor: isLoading ? "not-allowed" : "pointer",
              opacity: isLoading ? 0.7 : 1,
              display: "flex",
              alignItems: "center",
              gap: "0.5rem",
              boxShadow: "0 2px 4px rgba(0, 0, 0, 0.1)",
            }}
          >
            {isLoading ? (
              <>
                <span
                  style={{
                    width: "14px",
                    height: "14px",
                    border: "2px solid #FFFFFF",
                    borderTopColor: "transparent",
                    borderRadius: "50%",
                    display: "inline-block",
                  }}
                  className="animate-spin-slow"
                />
                Processing...
              </>
            ) : (
              confirmLabel
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
