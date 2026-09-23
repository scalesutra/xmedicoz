import React from "react";
import {
  Smartphone,
  QrCode,
  ShieldCheck,
  Star,
  Cpu,
  Printer,
  WifiOff,
} from "lucide-react";
import { AppColors } from "../theme/colors";

interface PlayStoreBannerProps {
  onOpenPlayStoreModal: () => void;
}

export const PlayStoreBanner: React.FC<PlayStoreBannerProps> = ({
  onOpenPlayStoreModal,
}) => {
  return (
    <section
      id="playstore"
      style={{
        padding: "85px 0",
        backgroundColor: AppColors.bgSidebar,
        color: "#FFFFFF",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background Glow */}
      <div
        style={{
          position: "absolute",
          top: "20%",
          right: "-10%",
          width: "500px",
          height: "500px",
          background: `radial-gradient(circle, ${AppColors.emeraldGlow} 0%, rgba(0,0,0,0) 70%)`,
          pointerEvents: "none",
        }}
      />

      <div className="container-custom" style={{ position: "relative", zIndex: 1 }}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 280px), 1fr))",
            gap: "2.5rem",
            alignItems: "center",
          }}
        >
          {/* Left Text & Badges */}
          <div>
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "0.45rem",
                padding: "0.35rem 0.9rem",
                borderRadius: "9999px",
                backgroundColor: "rgba(16, 185, 129, 0.15)",
                color: AppColors.emeraldLight,
                fontSize: "0.82rem",
                fontWeight: 700,
                marginBottom: "1.25rem",
                border: "1px solid rgba(16, 185, 129, 0.3)",
              }}
            >
              <Smartphone size={16} />
              <span>OFFICIAL GOOGLE PLAY STORE RELEASE</span>
            </div>

            <h2
              style={{
                fontSize: "clamp(2rem, 4vw, 2.85rem)",
                fontWeight: 800,
                letterSpacing: "-0.03em",
                lineHeight: 1.2,
                marginBottom: "1.25rem",
              }}
            >
              Pocket POS &amp; Mobile Pharmacy in the Palm of Your Hand
            </h2>

            <p
              style={{
                fontSize: "1.05rem",
                color: "#94A3B8",
                lineHeight: 1.6,
                marginBottom: "2rem",
              }}
            >
              Download <strong>X Medica</strong> on Google Play Store. Turn your smartphone or dedicated
              Android POS terminal into a certified medical counter that scans barcodes, validates batch expiries,
              and generates GST invoices on the fly.
            </p>

            {/* Hardware Specs Grid */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 200px), 1fr))",
                gap: "1rem",
                marginBottom: "2.5rem",
              }}
            >
              <div
                style={{
                  backgroundColor: "rgba(255, 255, 255, 0.04)",
                  padding: "1rem",
                  borderRadius: "12px",
                  border: "1px solid rgba(255, 255, 255, 0.08)",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.4rem" }}>
                  <Cpu size={18} color={AppColors.emeraldLight} />
                  <span style={{ fontSize: "0.9rem", fontWeight: 700 }}>OS Compatibility</span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "#94A3B8" }}>
                  Android 7.0 (Nougat) up to Android 15. Tablet &amp; foldable optimized.
                </div>
              </div>

              <div
                style={{
                  backgroundColor: "rgba(255, 255, 255, 0.04)",
                  padding: "1rem",
                  borderRadius: "12px",
                  border: "1px solid rgba(255, 255, 255, 0.08)",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.4rem" }}>
                  <Printer size={18} color={AppColors.primaryCyan} />
                  <span style={{ fontSize: "0.9rem", fontWeight: 700 }}>Thermal Printers</span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "#94A3B8" }}>
                  Sunmi V2, Bluetooth 58mm/80mm roll printers &amp; ESC/POS commands.
                </div>
              </div>

              <div
                style={{
                  backgroundColor: "rgba(255, 255, 255, 0.04)",
                  padding: "1rem",
                  borderRadius: "12px",
                  border: "1px solid rgba(255, 255, 255, 0.08)",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.4rem" }}>
                  <WifiOff size={18} color={AppColors.amberWarning} />
                  <span style={{ fontSize: "0.9rem", fontWeight: 700 }}>Offline Resilience</span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "#94A3B8" }}>
                  Local SQLite storage ensures zero counter stoppage during WiFi drops.
                </div>
              </div>

              <div
                style={{
                  backgroundColor: "rgba(255, 255, 255, 0.04)",
                  padding: "1rem",
                  borderRadius: "12px",
                  border: "1px solid rgba(255, 255, 255, 0.08)",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.4rem" }}>
                  <ShieldCheck size={18} color={AppColors.emeraldLight} />
                  <span style={{ fontSize: "0.9rem", fontWeight: 700 }}>Google Play Protect</span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "#94A3B8" }}>
                  100% verified by Google Play Protect security scan.
                </div>
              </div>
            </div>

            {/* CTAs */}
            <div
              className="banner-cta-group"
              style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: "1rem" }}
            >
              <button
                onClick={onOpenPlayStoreModal}
                className="banner-cta-btn"
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "0.75rem",
                  padding: "0.85rem 1.75rem",
                  borderRadius: "14px",
                  backgroundColor: "#FFFFFF",
                  color: AppColors.textPrimary,
                  fontSize: "1rem",
                  fontWeight: 800,
                  boxShadow: "0 8px 24px -2px rgba(255, 255, 255, 0.25)",
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = "translateY(-2px)";
                  e.currentTarget.style.boxShadow = "0 12px 30px rgba(255, 255, 255, 0.35)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = "none";
                  e.currentTarget.style.boxShadow = "0 8px 24px -2px rgba(255, 255, 255, 0.25)";
                }}
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                  <path d="M3.6 1.8L14.4 12L3.6 22.2C3.2 21.7 3 21 3 20.2V3.8C3 3 3.2 2.3 3.6 1.8Z" fill="#00C3FF" />
                  <path d="M17.9 8.6L14.4 12L17.9 15.4L21.3 13.5C22.3 12.9 22.3 11.1 21.3 10.5L17.9 8.6Z" fill="#FFD400" />
                  <path d="M14.4 12L3.6 1.8C4.1 1.3 4.9 1.1 5.8 1.6L17.9 8.6L14.4 12Z" fill="#00E676" />
                  <path d="M14.4 12L17.9 15.4L5.8 22.4C4.9 22.9 4.1 22.7 3.6 22.2L14.4 12Z" fill="#FF334B" />
                </svg>
                <span>Get it on Google Play</span>
              </button>

              <button
                onClick={onOpenPlayStoreModal}
                className="banner-cta-btn"
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "0.5rem",
                  padding: "0.9rem 1.35rem",
                  borderRadius: "14px",
                  backgroundColor: "rgba(255,255,255,0.08)",
                  color: "#FFFFFF",
                  fontSize: "0.95rem",
                  fontWeight: 600,
                  border: "1px solid rgba(255,255,255,0.15)",
                }}
              >
                <QrCode size={18} color={AppColors.emeraldLight} />
                <span>Scan QR for Phone</span>
              </button>
            </div>
          </div>

          {/* Right Card / Interactive QR Preview */}
          <div style={{ display: "flex", justifyContent: "center", width: "100%" }}>
            <div
              style={{
                width: "100%",
                maxWidth: "380px",
                backgroundColor: AppColors.bgCardDark,
                borderRadius: "24px",
                padding: "clamp(1.25rem, 4vw, 2rem)",
                border: "1px solid rgba(255, 255, 255, 0.12)",
                boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.5)",
                textAlign: "center",
              }}
            >
              {/* Play Store App Card Badge */}
              <div
                style={{
                  width: "72px",
                  height: "72px",
                  borderRadius: "18px",
                  backgroundColor: AppColors.primaryEmerald,
                  margin: "0 auto 1.25rem auto",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#FFFFFF",
                  boxShadow: `0 10px 25px ${AppColors.emeraldGlow}`,
                }}
              >
                <Smartphone size={36} />
              </div>

              <div style={{ fontSize: "1.35rem", fontWeight: 800, marginBottom: "0.25rem" }}>
                X Medica
              </div>
              <div style={{ fontSize: "0.85rem", color: AppColors.emeraldLight, fontWeight: 600 }}>
                ScaleSutra Medical Tech
              </div>

              {/* Stars */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "4px",
                  marginTop: "0.75rem",
                  marginBottom: "1.25rem",
                }}
              >
                {[...Array(5)].map((_, i) => (
                  <Star key={i} size={16} fill="#F59E0B" color="#F59E0B" />
                ))}
                <span style={{ fontSize: "0.85rem", fontWeight: 700, marginLeft: "4px" }}>
                  4.9 (1.2k+ reviews)
                </span>
              </div>

              {/* QR Code Container */}
              <div
                style={{
                  backgroundColor: "#FFFFFF",
                  padding: "1rem",
                  borderRadius: "16px",
                  display: "inline-block",
                  marginBottom: "1.25rem",
                  boxShadow: "0 8px 16px rgba(0,0,0,0.2)",
                  cursor: "pointer",
                }}
                onClick={onOpenPlayStoreModal}
              >
                <svg
                  viewBox="0 0 100 100"
                  width="140"
                  height="140"
                  style={{ display: "block" }}
                >
                  <rect width="100" height="100" fill="#FFFFFF" />
                  {/* Outer corner top-left */}
                  <rect x="10" y="10" width="28" height="28" fill="#0F172A" rx="4" />
                  <rect x="16" y="16" width="16" height="16" fill="#FFFFFF" rx="2" />
                  <rect x="20" y="20" width="8" height="8" fill="#059669" />
                  {/* Outer corner top-right */}
                  <rect x="62" y="10" width="28" height="28" fill="#0F172A" rx="4" />
                  <rect x="68" y="16" width="16" height="16" fill="#FFFFFF" rx="2" />
                  <rect x="72" y="20" width="8" height="8" fill="#059669" />
                  {/* Outer corner bottom-left */}
                  <rect x="10" y="62" width="28" height="28" fill="#0F172A" rx="4" />
                  <rect x="16" y="68" width="16" height="16" fill="#FFFFFF" rx="2" />
                  <rect x="20" y="72" width="8" height="8" fill="#059669" />
                  {/* Matrix Dots */}
                  <rect x="44" y="12" width="6" height="6" fill="#0F172A" />
                  <rect x="52" y="18" width="5" height="5" fill="#0F172A" />
                  <rect x="44" y="26" width="6" height="6" fill="#0F172A" />
                  <rect x="12" y="44" width="6" height="6" fill="#0F172A" />
                  <rect x="22" y="50" width="6" height="6" fill="#0F172A" />
                  <rect x="44" y="44" width="12" height="12" fill="#059669" rx="2" />
                  <rect x="62" y="44" width="6" height="6" fill="#0F172A" />
                  <rect x="74" y="52" width="6" height="6" fill="#0F172A" />
                  <rect x="84" y="44" width="6" height="6" fill="#0F172A" />
                  <rect x="44" y="62" width="6" height="6" fill="#0F172A" />
                  <rect x="52" y="70" width="6" height="6" fill="#0F172A" />
                  <rect x="44" y="80" width="6" height="6" fill="#0F172A" />
                  <rect x="64" y="66" width="8" height="8" fill="#0F172A" />
                  <rect x="78" y="74" width="10" height="10" fill="#0F172A" />
                  <rect x="66" y="82" width="8" height="8" fill="#059669" />
                </svg>
              </div>

              <div style={{ fontSize: "0.8rem", color: "#94A3B8" }}>
                Point camera to install directly from Google Play Store
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        @media (max-width: 640px) {
          .banner-cta-group {
            flex-direction: column !important;
            width: 100% !important;
          }
          .banner-cta-btn {
            width: 100% !important;
            justify-content: center !important;
          }
        }
      `}</style>
    </section>
  );
};
