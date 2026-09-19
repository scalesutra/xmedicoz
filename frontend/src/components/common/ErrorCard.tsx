import React from "react";
import { AlertCircle, RefreshCw } from "lucide-react";

interface ErrorCardProps {
  title?: string;
  message: string;
  onRetry?: () => void;
}

export const ErrorCard: React.FC<ErrorCardProps> = ({
  title = "Failed to Load Data",
  message,
  onRetry,
}) => {
  return (
    <div
      style={{
        padding: "1.25rem 1.5rem",
        backgroundColor: "rgba(239, 68, 68, 0.08)",
        border: "1px solid rgba(239, 68, 68, 0.25)",
        borderRadius: "10px",
        display: "flex",
        alignItems: "flex-start",
        gap: "1rem",
        margin: "1rem 0",
      }}
    >
      <div style={{ color: "#DC2626", marginTop: "2px" }}>
        <AlertCircle size={22} />
      </div>
      <div style={{ flex: 1 }}>
        <h4 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#991B1B", marginBottom: "0.25rem" }}>
          {title}
        </h4>
        <p style={{ fontSize: "0.85rem", color: "#B91C1C", lineHeight: 1.4 }}>{message}</p>
      </div>
      {onRetry && (
        <button
          onClick={onRetry}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
            padding: "0.45rem 0.85rem",
            backgroundColor: "#DC2626",
            color: "#FFFFFF",
            border: "none",
            borderRadius: "6px",
            fontSize: "0.8rem",
            fontWeight: 600,
            cursor: "pointer",
            alignSelf: "center",
          }}
        >
          <RefreshCw size={14} />
          Retry
        </button>
      )}
    </div>
  );
};
