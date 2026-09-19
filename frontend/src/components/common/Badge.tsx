import React from "react";

interface BadgeProps {
  variant?: "success" | "danger" | "warning" | "info" | "neutral";
  children: React.ReactNode;
  size?: "sm" | "md";
}

export const Badge: React.FC<BadgeProps> = ({
  variant = "neutral",
  children,
  size = "md",
}) => {
  const styles: Record<string, { bg: string; color: string; border: string }> = {
    success: { bg: "#ECFDF5", color: "#065F46", border: "rgba(16, 185, 129, 0.3)" },
    danger: { bg: "rgba(239, 68, 68, 0.1)", color: "#991B1B", border: "rgba(239, 68, 68, 0.25)" },
    warning: { bg: "#FFFBEB", color: "#92400E", border: "rgba(245, 158, 11, 0.3)" },
    info: { bg: "#F0FDFA", color: "#115E59", border: "rgba(6, 182, 212, 0.3)" },
    neutral: { bg: "#F1F5F9", color: "#334155", border: "#E2E8F0" },
  };

  const current = styles[variant] || styles.neutral;

  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "0.3rem",
        padding: size === "sm" ? "0.15rem 0.5rem" : "0.25rem 0.65rem",
        borderRadius: "9999px",
        fontSize: size === "sm" ? "0.72rem" : "0.78rem",
        fontWeight: 600,
        backgroundColor: current.bg,
        color: current.color,
        border: `1px solid ${current.border}`,
        whiteSpace: "nowrap",
      }}
    >
      {children}
    </span>
  );
};
