import React, { useState } from "react";
import { X, Smartphone, Check, Copy, ExternalLink, ShieldCheck, Star } from "lucide-react";
import { AppColors } from "../theme/colors";

interface PlayStoreModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const PlayStoreModal: React.FC<PlayStoreModalProps> = ({ isOpen, onClose }) => {
  const [copied, setCopied] = useState(false);
  const playStoreUrl = "https://play.google.com/store/apps/details?id=com.scalesutra.xmedica";

  if (!isOpen) return null;

  const handleCopy = () => {
    navigator.clipboard.writeText(playStoreUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "rgba(11, 25, 23, 0.75)",
        backdropFilter: "blur(8px)",
        zIndex: 200,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "1rem",
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "480px",
          backgroundColor: AppColors.white,
          borderRadius: "24px",
          padding: "clamp(1.25rem, 5vw, 2rem)",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.4)",
          position: "relative",
          border: `1px solid ${AppColors.borderSubtle}`,
          textAlign: "center",
          maxHeight: "90vh",
          overflowY: "auto",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          style={{
            position: "absolute",
            top: "1.25rem",
            right: "1.25rem",
            width: "36px",
            height: "36px",
            borderRadius: "50%",
            backgroundColor: AppColors.frostMint,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: AppColors.textSecondary,
          }}
        >
          <X size={18} />
        </button>

        {/* Brand Icon */}
        <div
          style={{
            width: "56px",
            height: "56px",
            borderRadius: "16px",
            backgroundColor: AppColors.bgSidebar,
            margin: "0 auto 1.25rem auto",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#FFFFFF",
            boxShadow: "0 10px 20px rgba(11, 25, 23, 0.2)",
          }}
        >
          <Smartphone size={28} color={AppColors.emeraldLight} />
        </div>

        <h3 style={{ fontSize: "clamp(1.25rem, 4vw, 1.5rem)", fontWeight: 800, color: AppColors.textPrimary, marginBottom: "0.25rem" }}>
          Get X Medica on Google Play
        </h3>
        <p style={{ fontSize: "0.85rem", color: AppColors.textSecondary, marginBottom: "1.25rem" }}>
          Scan the QR code with your phone camera or click below to open Google Play Store.
        </p>

        {/* QR Code Container */}
        <div
          style={{
            backgroundColor: "#FFFFFF",
            padding: "1rem",
            borderRadius: "16px",
            display: "inline-block",
            marginBottom: "1.25rem",
            border: `2px solid ${AppColors.primaryEmerald}30`,
            boxShadow: "0 8px 20px rgba(5, 150, 105, 0.12)",
          }}
        >
          <svg viewBox="0 0 100 100" width="130" height="130" style={{ display: "block", maxWidth: "100%" }}>
            <rect width="100" height="100" fill="#FFFFFF" />
            <rect x="8" y="8" width="30" height="30" fill="#0F172A" rx="4" />
            <rect x="14" y="14" width="18" height="18" fill="#FFFFFF" rx="2" />
            <rect x="18" y="18" width="10" height="10" fill="#059669" />
            <rect x="62" y="8" width="30" height="30" fill="#0F172A" rx="4" />
            <rect x="68" y="14" width="18" height="18" fill="#FFFFFF" rx="2" />
            <rect x="72" y="18" width="10" height="10" fill="#059669" />
            <rect x="8" y="62" width="30" height="30" fill="#0F172A" rx="4" />
            <rect x="14" y="68" width="18" height="18" fill="#FFFFFF" rx="2" />
            <rect x="18" y="72" width="10" height="10" fill="#059669" />
            {/* Dots pattern */}
            <rect x="44" y="12" width="6" height="6" fill="#0F172A" />
            <rect x="52" y="18" width="5" height="5" fill="#0F172A" />
            <rect x="44" y="26" width="6" height="6" fill="#0F172A" />
            <rect x="12" y="44" width="6" height="6" fill="#0F172A" />
            <rect x="24" y="50" width="6" height="6" fill="#0F172A" />
            <rect x="44" y="44" width="12" height="12" fill="#059669" rx="2" />
            <rect x="62" y="44" width="6" height="6" fill="#0F172A" />
            <rect x="74" y="50" width="6" height="6" fill="#0F172A" />
            <rect x="84" y="44" width="6" height="6" fill="#0F172A" />
            <rect x="44" y="64" width="6" height="6" fill="#0F172A" />
            <rect x="52" y="72" width="6" height="6" fill="#0F172A" />
            <rect x="44" y="82" width="6" height="6" fill="#0F172A" />
            <rect x="64" y="66" width="8" height="8" fill="#0F172A" />
            <rect x="76" y="76" width="10" height="10" fill="#0F172A" />
            <rect x="66" y="82" width="8" height="8" fill="#059669" />
          </svg>
          <div style={{ fontSize: "0.75rem", color: AppColors.textMuted, marginTop: "6px", fontWeight: 600 }}>
            Point phone camera to scan
          </div>
        </div>

        {/* Direct Play Store Link Button */}
        <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", marginBottom: "1.25rem" }}>
          <a
            href={playStoreUrl}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "0.5rem",
              padding: "0.85rem",
              borderRadius: "12px",
              backgroundColor: AppColors.bgSidebar,
              color: "#FFFFFF",
              fontWeight: 700,
              fontSize: "0.95rem",
              textDecoration: "none",
            }}
          >
            <span>Open in Google Play Store</span>
            <ExternalLink size={16} />
          </a>

          <button
            onClick={handleCopy}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "0.45rem",
              padding: "0.75rem",
              borderRadius: "12px",
              backgroundColor: AppColors.frostMint,
              color: AppColors.textPrimary,
              fontWeight: 600,
              fontSize: "0.85rem",
              border: `1px solid ${AppColors.borderSubtle}`,
            }}
          >
            {copied ? (
              <>
                <Check size={16} color={AppColors.primaryEmerald} />
                <span style={{ color: AppColors.primaryEmerald }}>Play Store Link Copied!</span>
              </>
            ) : (
              <>
                <Copy size={16} />
                <span>Copy Shareable Play Store Link</span>
              </>
            )}
          </button>
        </div>

        {/* App Meta Info */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            fontSize: "0.75rem",
            color: AppColors.textMuted,
            paddingTop: "1rem",
            borderTop: `1px solid ${AppColors.borderSubtle}`,
          }}
        >
          <span style={{ display: "flex", alignItems: "center", gap: "4px" }}>
            <ShieldCheck size={14} color={AppColors.primaryEmerald} />
            Play Protect Verified
          </span>
          <span>Size: 18 MB</span>
          <span style={{ display: "flex", alignItems: "center", gap: "2px" }}>
            <Star size={12} fill="#F59E0B" color="#F59E0B" /> 4.9★
          </span>
        </div>
      </div>
    </div>
  );
};
