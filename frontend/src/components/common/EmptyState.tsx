import React from "react";
import { FolderOpen, Plus } from "lucide-react";

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon,
  title,
  description,
  actionLabel,
  onAction,
}) => {
  return (
    <div
      style={{
        padding: "3.5rem 2rem",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        backgroundColor: "#FFFFFF",
        borderRadius: "12px",
        border: "1px dashed #CBD5E1",
        margin: "1rem 0",
      }}
    >
      <div
        style={{
          width: "56px",
          height: "56px",
          borderRadius: "14px",
          backgroundColor: "#ECFDF5",
          color: "#059669",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: "1rem",
        }}
      >
        {icon || <FolderOpen size={28} />}
      </div>
      <h4 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", marginBottom: "0.5rem" }}>
        {title}
      </h4>
      <p
        style={{
          maxWidth: "420px",
          fontSize: "0.9rem",
          color: "#64748B",
          lineHeight: 1.5,
          marginBottom: actionLabel && onAction ? "1.5rem" : 0,
        }}
      >
        {description}
      </p>
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          style={{
            padding: "0.6rem 1.25rem",
            backgroundColor: "#059669",
            color: "#FFFFFF",
            border: "none",
            borderRadius: "8px",
            fontSize: "0.9rem",
            fontWeight: 600,
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.5rem",
            boxShadow: "0 2px 5px rgba(5, 150, 105, 0.25)",
            transition: "all 0.15s ease",
          }}
        >
          <Plus size={16} />
          {actionLabel}
        </button>
      )}
    </div>
  );
};
