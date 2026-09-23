import React from "react";
import {
  ArrowRight,
  Receipt,
  Sparkles,
  CheckCircle2,
  Database,
  Lock,
} from "lucide-react";
import { AppColors } from "../theme/colors";
import { AppConfig } from "../config/appConfig";

interface HeroSectionProps {
  onOpenPlayStoreModal: () => void;
  onScrollToShowcase: () => void;
}

export const HeroSection: React.FC<HeroSectionProps> = ({
  onOpenPlayStoreModal,
  onScrollToShowcase,
}) => {
  return (
    <section
      className="hero-ambient-bg hero-section"
      style={{
        paddingTop: "clamp(100px, 12vw, 140px)",
        paddingBottom: "clamp(50px, 8vw, 80px)",
        position: "relative",
        overflow: "hidden",
      }}
    >
      <div className="container-custom" style={{ position: "relative", zIndex: 1 }}>
        <div
          style={{
            maxWidth: "920px",
            margin: "0 auto",
            textAlign: "center",
          }}
        >
          {/* Eyebrow Status Pill */}
          <div
            style={{
              display: "inline-flex",
              flexWrap: "wrap",
              justifyContent: "center",
              textAlign: "center",
              alignItems: "center",
              gap: "0.4rem",
              padding: "0.4rem 0.85rem",
              borderRadius: "9999px",
              backgroundColor: "#FFFFFF",
              border: `1px solid ${AppColors.borderSubtle}`,
              color: AppColors.textPrimary,
              fontSize: "clamp(0.72rem, 2.5vw, 0.84rem)",
              fontWeight: 600,
              marginBottom: "1.5rem",
              boxShadow: "0 2px 8px rgba(0,0,0,0.03)",
              maxWidth: "100%",
              lineHeight: 1.4,
            }}
          >
            <span
              style={{
                width: "8px",
                height: "8px",
                borderRadius: "50%",
                backgroundColor: AppColors.emeraldLight,
                flexShrink: 0,
              }}
              className="pulse-dot"
            />
            <span style={{ color: AppColors.deepTeal, fontWeight: 700 }}>Single-Store Management &amp; CRM</span>
            <span style={{ color: AppColors.textMuted }}>•</span>
            <span>CDSCO &amp; Schedule H/H1 Ready</span>
          </div>

          {/* Main Headline */}
          <h1
            style={{
              fontSize: "clamp(1.9rem, 6.5vw, 4rem)",
              fontWeight: 800,
              letterSpacing: "-0.03em",
              lineHeight: 1.15,
              color: AppColors.textPrimary,
              marginBottom: "1.25rem",
              wordBreak: "break-word",
            }}
          >
            Autonomous Medical Store &amp;{" "}
            <span className="gradient-text">
              Pharmacy Accounting Suite
            </span>
          </h1>

          {/* Subtitle */}
          <p
            style={{
              fontSize: "clamp(0.95rem, 2.8vw, 1.18rem)",
              color: AppColors.textSecondary,
              lineHeight: 1.6,
              maxWidth: "740px",
              margin: "0 auto 2rem auto",
            }}
          >
            Built for retail pharmacies. Counter POS sales billing, real-time FEFO batch expiry tracking,
            physical rack &amp; cold storage (2°C–8°C) locator, and double-entry daybook accounting.
            Synchronized between the <strong>Android Play Store app</strong> and <strong>Cloud Web portal</strong>.
          </p>

          {/* Action Buttons Group */}
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              alignItems: "center",
              justifyContent: "center",
              gap: "0.75rem",
              marginBottom: "2.5rem",
            }}
            className="hero-buttons-container"
          >
            {/* Google Play Store CTA */}
            <button
              onClick={onOpenPlayStoreModal}
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.65rem",
                padding: "0.75rem 1.4rem",
                borderRadius: "14px",
                backgroundColor: AppColors.bgSidebar,
                color: "#FFFFFF",
                fontSize: "0.95rem",
                fontWeight: 700,
                boxShadow: "0 8px 24px -4px rgba(11, 25, 23, 0.35)",
                border: "1px solid rgba(255, 255, 255, 0.14)",
                minWidth: "200px",
              }}
              className="hero-btn"
            >
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
                <path d="M3.6 1.8L14.4 12L3.6 22.2C3.2 21.7 3 21 3 20.2V3.8C3 3 3.2 2.3 3.6 1.8Z" fill="#00C3FF" />
                <path d="M17.9 8.6L14.4 12L17.9 15.4L21.3 13.5C22.3 12.9 22.3 11.1 21.3 10.5L17.9 8.6Z" fill="#FFD400" />
                <path d="M14.4 12L3.6 1.8C4.1 1.3 4.9 1.1 5.8 1.6L17.9 8.6L14.4 12Z" fill="#00E676" />
                <path d="M14.4 12L17.9 15.4L5.8 22.4C4.9 22.9 4.1 22.7 3.6 22.2L14.4 12Z" fill="#FF334B" />
              </svg>
              <div style={{ textAlign: "left", lineHeight: 1.25 }}>
                <div style={{ fontSize: "0.65rem", color: "#94A3B8", fontWeight: 600, letterSpacing: "0.04em" }}>
                  GET IT ON
                </div>
                <div style={{ fontSize: "0.98rem", fontWeight: 800 }}>Google Play</div>
              </div>
            </button>

            {/* Launch Real Cloud Web App */}
            <a
              href={AppConfig.webAppUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.5rem",
                padding: "0.85rem 1.4rem",
                borderRadius: "14px",
                backgroundColor: AppColors.primaryEmerald,
                color: "#FFFFFF",
                fontSize: "0.95rem",
                fontWeight: 700,
                boxShadow: "0 8px 24px -4px rgba(5, 150, 105, 0.4)",
                textDecoration: "none",
                minWidth: "200px",
              }}
              className="hero-btn"
            >
              <span>Launch Live Web App</span>
              <ArrowRight size={17} />
            </a>

            {/* Simulator CTA */}
            <button
              onClick={onScrollToShowcase}
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.45rem",
                padding: "0.85rem 1.2rem",
                borderRadius: "14px",
                backgroundColor: "#FFFFFF",
                color: AppColors.textPrimary,
                fontSize: "0.9rem",
                fontWeight: 600,
                border: `1px solid ${AppColors.borderSubtle}`,
                boxShadow: "0 2px 6px rgba(0,0,0,0.03)",
              }}
              className="hero-btn"
            >
              <Sparkles size={15} color={AppColors.amberWarning} />
              <span>Interactive Simulator</span>
            </button>
          </div>

          {/* System Capabilities Checklist */}
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              alignItems: "center",
              justifyContent: "center",
              gap: "0.75rem 1.25rem",
              marginBottom: "2.75rem",
              fontSize: "0.82rem",
              color: AppColors.textSecondary,
              fontWeight: 500,
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.35rem" }}>
              <CheckCircle2 size={15} color={AppColors.primaryEmerald} style={{ flexShrink: 0 }} />
              <span>Counter POS Billing</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.35rem" }}>
              <CheckCircle2 size={15} color={AppColors.primaryEmerald} style={{ flexShrink: 0 }} />
              <span>FEFO Batch Expiry Radar</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.35rem" }}>
              <CheckCircle2 size={15} color={AppColors.primaryEmerald} style={{ flexShrink: 0 }} />
              <span>Physical Rack &amp; Shelf Locator</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.35rem" }}>
              <CheckCircle2 size={15} color={AppColors.primaryEmerald} style={{ flexShrink: 0 }} />
              <span>24-Account Daybook</span>
            </div>
          </div>

          {/* Responsive Telemetry Highlights Card */}
          <div
            style={{
              display: "grid",
              gap: "0.75rem",
              backgroundColor: "#FFFFFF",
              borderRadius: "18px",
              padding: "1.25rem",
              border: `1px solid ${AppColors.borderSubtle}`,
              boxShadow: "0 10px 25px -5px rgba(15, 23, 42, 0.05)",
            }}
            className="hero-stats-grid"
          >
            <div style={{ padding: "0.5rem" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "0.35rem", marginBottom: "0.2rem" }}>
                <Receipt size={17} color={AppColors.primaryEmerald} />
                <span style={{ fontSize: "1.25rem", fontWeight: 800, color: AppColors.textPrimary }} className="tabular-nums">
                  POS Counter
                </span>
              </div>
              <div style={{ fontSize: "0.76rem", color: AppColors.textSecondary }}>
                Fast GST Billing &amp; Batches
              </div>
            </div>

            <div style={{ padding: "0.5rem" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "0.35rem", marginBottom: "0.2rem" }}>
                <span style={{ fontSize: "1.25rem", fontWeight: 800, color: AppColors.deepTeal }} className="tabular-nums">
                  FEFO Radar
                </span>
              </div>
              <div style={{ fontSize: "0.76rem", color: AppColors.textSecondary }}>
                Real-Time Expiry Quarantine
              </div>
            </div>

            <div style={{ padding: "0.5rem" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "0.35rem", marginBottom: "0.2rem" }}>
                <Database size={17} color={AppColors.primaryCyan} />
                <span style={{ fontSize: "1.25rem", fontWeight: 800, color: AppColors.textPrimary }} className="tabular-nums">
                  24 Accounts
                </span>
              </div>
              <div style={{ fontSize: "0.76rem", color: AppColors.textSecondary }}>
                Daybook &amp; Trial Balance
              </div>
            </div>

            <div style={{ padding: "0.5rem" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "0.35rem", marginBottom: "0.2rem" }}>
                <Lock size={17} color={AppColors.amberWarning} />
                <span style={{ fontSize: "1.25rem", fontWeight: 800, color: AppColors.textPrimary }} className="tabular-nums">
                  Keycloak JWT
                </span>
              </div>
              <div style={{ fontSize: "0.76rem", color: AppColors.textSecondary }}>
                Secure Clinical Session
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .hero-stats-grid {
          grid-template-columns: repeat(4, 1fr);
        }
        @media (max-width: 860px) {
          .hero-stats-grid {
            grid-template-columns: repeat(2, 1fr) !important;
          }
          .hero-buttons-container {
            flex-direction: column !important;
            width: 100% !important;
          }
          .hero-btn {
            width: 100% !important;
            max-width: 100% !important;
            min-width: 0 !important;
          }
        }
        @media (max-width: 440px) {
          .hero-stats-grid {
            grid-template-columns: 1fr !important;
          }
          .hero-stats-grid > div {
            padding: 0.35rem 0 !important;
          }
        }
      `}</style>
    </section>
  );
};
