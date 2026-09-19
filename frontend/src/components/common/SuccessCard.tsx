import React from "react";
import { CheckCircle2, ArrowRight, Printer } from "lucide-react";

interface SuccessCardProps {
  title: string;
  referenceLabel?: string;
  referenceValue?: string;
  message: string;
  primaryActionLabel?: string;
  onPrimaryAction?: () => void;
  printActionLabel?: string;
  onPrintAction?: () => void;
}

export const SuccessCard: React.FC<SuccessCardProps> = ({
  title,
  referenceLabel,
  referenceValue,
  message,
  primaryActionLabel,
  onPrimaryAction,
  printActionLabel,
  onPrintAction,
}) => {
  return (
    <div
      style={{
        padding: "2rem",
        backgroundColor: "#FFFFFF",
        border: "1px solid #10B981",
        borderRadius: "14px",
        boxShadow: "0 10px 25px -5px rgba(16, 185, 129, 0.15)",
        textAlign: "center",
        maxWidth: "500px",
        margin: "1.5rem auto",
      }}
      className="animate-scale-in"
    >
      <div
        style={{
          width: "56px",
          height: "56px",
          borderRadius: "50%",
          backgroundColor: "#ECFDF5",
          color: "#059669",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          margin: "0 auto 1rem auto",
        }}
      >
        <CheckCircle2 size={32} />
      </div>

      <h3 style={{ fontSize: "1.25rem", fontWeight: 700, color: "#0F172A", marginBottom: "0.5rem" }}>
        {title}
      </h3>

      {referenceValue && (
        <div
          style={{
            display: "inline-block",
            padding: "0.35rem 0.85rem",
            backgroundColor: "#F1F5F9",
            borderRadius: "6px",
            fontSize: "0.85rem",
            fontWeight: 600,
            fontFamily: "var(--font-mono)",
            color: "#334155",
            marginBottom: "0.75rem",
          }}
        >
          {referenceLabel || "Reference"}: {referenceValue}
        </div>
      )}

      <p style={{ fontSize: "0.9rem", color: "#64748B", lineHeight: 1.5, marginBottom: "1.5rem" }}>
        {message}
      </p>

      <div style={{ display: "flex", justifyContent: "center", gap: "0.75rem", flexWrap: "wrap" }}>
        {printActionLabel && onPrintAction && (
          <button
            onClick={onPrintAction}
            style={{
              padding: "0.6rem 1.1rem",
              backgroundColor: "#FFFFFF",
              border: "1px solid #CBD5E1",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 600,
              color: "#334155",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.4rem",
            }}
          >
            <Printer size={16} />
            {printActionLabel}
          </button>
        )}
        {primaryActionLabel && onPrimaryAction && (
          <button
            onClick={onPrimaryAction}
            style={{
              padding: "0.6rem 1.25rem",
              backgroundColor: "#059669",
              border: "none",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 600,
              color: "#FFFFFF",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.4rem",
              boxShadow: "0 2px 5px rgba(5, 150, 105, 0.25)",
            }}
          >
            {primaryActionLabel}
            <ArrowRight size={16} />
          </button>
        )}
      </div>
    </div>
  );
};
