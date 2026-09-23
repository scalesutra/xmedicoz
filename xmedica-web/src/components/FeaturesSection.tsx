import React from "react";
import {
  Scan,
  AlertOctagon,
  MessageSquare,
  ThermometerSnowflake,
  FileSpreadsheet,
  Building2,
  Sparkles,
  ArrowRight,
  Smartphone,
} from "lucide-react";
import { AppColors } from "../theme/colors";
import { AppConfig } from "../config/appConfig";

interface FeaturesSectionProps {
  onOpenPlayStoreModal: () => void;
}

export const FeaturesSection: React.FC<FeaturesSectionProps> = ({
  onOpenPlayStoreModal,
}) => {
  return (
    <section id="features" style={{ padding: "100px 0", backgroundColor: "#FFFFFF" }}>
      <div className="container-custom">
        {/* Section Header */}
        <div style={{ textAlign: "center", maxWidth: "760px", margin: "0 auto 4rem auto" }}>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "0.45rem",
              padding: "0.35rem 0.95rem",
              borderRadius: "9999px",
              backgroundColor: AppColors.tealSurface,
              color: AppColors.deepTeal,
              fontSize: "0.82rem",
              fontWeight: 700,
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              marginBottom: "0.85rem",
            }}
          >
            <Sparkles size={14} />
            <span>Architecture &amp; Capabilities</span>
          </div>

          <h2
            style={{
              fontSize: "clamp(2.1rem, 4vw, 3rem)",
              fontWeight: 800,
              letterSpacing: "-0.03em",
              color: AppColors.textPrimary,
              lineHeight: 1.18,
              marginBottom: "1rem",
            }}
          >
            Engineered Specifically for High-Volume Medical Stores
          </h2>

          <p style={{ fontSize: "1.05rem", color: AppColors.textSecondary, lineHeight: 1.65 }}>
            Every feature in <strong>X Medica</strong> is precision-crafted around retail pharmacy workflows —
            preventing medicine expirations, accelerating billing lines, and automating drug compliance.
          </p>
        </div>

        {/* BENTO GRID */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(12, 1fr)",
            gap: "1.75rem",
          }}
        >
          {/* Bento Card 1: High-Speed Counter POS (Span 7) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 7",
              background: "linear-gradient(135deg, #F0FDF4 0%, #FFFFFF 100%)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
              minHeight: "360px",
            }}
          >
            <div>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  marginBottom: "1.25rem",
                }}
              >
                <div
                  style={{
                    width: "48px",
                    height: "48px",
                    borderRadius: "14px",
                    backgroundColor: AppColors.white,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    boxShadow: "0 4px 12px rgba(5, 150, 105, 0.15)",
                    color: AppColors.primaryEmerald,
                  }}
                >
                  <Scan size={24} />
                </div>
                <span
                  style={{
                    fontSize: "0.72rem",
                    fontWeight: 800,
                    letterSpacing: "0.06em",
                    padding: "3px 10px",
                    borderRadius: "6px",
                    backgroundColor: AppColors.tealSurface,
                    color: AppColors.deepTeal,
                  }}
                >
                  HIGH-SPEED POS
                </span>
              </div>

              <h3
                style={{
                  fontSize: "1.45rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.6rem",
                  letterSpacing: "-0.02em",
                }}
              >
                Barcode Sales &amp; Sub-120ms GST Checkout
              </h3>

              <p
                style={{
                  fontSize: "0.95rem",
                  color: AppColors.textSecondary,
                  lineHeight: 1.6,
                  marginBottom: "1.5rem",
                }}
              >
                Built for rush hour lines. Scan barcodes instantly via phone camera or Bluetooth scanner,
                auto-compute multi-tier GST rates (CGST/SGST/IGST), and fire thermal receipts to Sunmi or ESC/POS printers.
              </p>
            </div>

            {/* Visual Pill Mockup inside Card */}
            <div
              style={{
                backgroundColor: AppColors.white,
                borderRadius: "14px",
                padding: "1rem 1.25rem",
                border: `1px solid ${AppColors.borderSubtle}`,
                display: "flex",
                flexWrap: "wrap",
                alignItems: "center",
                justifyContent: "space-between",
                gap: "1rem",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                <span
                  style={{
                    fontSize: "0.72rem",
                    backgroundColor: "#0D1822",
                    color: "#FFFFFF",
                    fontFamily: "var(--font-mono)",
                    padding: "3px 8px",
                    borderRadius: "4px",
                  }}
                >
                  SCAN: 890111700234
                </span>
                <span style={{ fontSize: "0.85rem", fontWeight: 700, color: AppColors.textPrimary }}>
                  Augmentin 625 Duo Tab
                </span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>MRP ₹223.50</span>
                <span style={{ fontSize: "0.95rem", fontWeight: 800, color: AppColors.primaryEmerald }}>
                  ₹201.15
                </span>
              </div>
            </div>
          </div>

          {/* Bento Card 2: FEFO Expiry Radar (Span 5) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 5",
              background: "linear-gradient(135deg, #FEF2F2 0%, #FFFFFF 100%)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
              minHeight: "360px",
            }}
          >
            <div>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  marginBottom: "1.25rem",
                }}
              >
                <div
                  style={{
                    width: "48px",
                    height: "48px",
                    borderRadius: "14px",
                    backgroundColor: AppColors.white,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    boxShadow: "0 4px 12px rgba(239, 68, 68, 0.15)",
                    color: AppColors.crimsonAlert,
                  }}
                >
                  <AlertOctagon size={24} />
                </div>
                <span
                  style={{
                    fontSize: "0.72rem",
                    fontWeight: 800,
                    letterSpacing: "0.06em",
                    padding: "3px 10px",
                    borderRadius: "6px",
                    backgroundColor: "rgba(239, 68, 68, 0.1)",
                    color: AppColors.crimsonAlert,
                  }}
                >
                  FEFO RADAR
                </span>
              </div>

              <h3
                style={{
                  fontSize: "1.4rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.6rem",
                  letterSpacing: "-0.02em",
                }}
              >
                Zero-Wastage Expiry Quarantine
              </h3>

              <p
                style={{
                  fontSize: "0.92rem",
                  color: AppColors.textSecondary,
                  lineHeight: 1.6,
                  marginBottom: "1.25rem",
                }}
              >
                First Expiry First Out (FEFO) algorithm proactively quarantines stock nearing 30, 60, or 90 days
                and blocks expired drugs from counter sale automatically.
              </p>
            </div>

            {/* Visual alert pill */}
            <div
              style={{
                backgroundColor: "rgba(239, 68, 68, 0.08)",
                borderRadius: "12px",
                padding: "0.75rem 1rem",
                border: "1px solid rgba(239, 68, 68, 0.2)",
                fontSize: "0.8rem",
                color: "#991B1B",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <span>Batch CIP-304 (18 days left)</span>
              <strong style={{ color: AppColors.crimsonAlert }}>Auto-Quarantined</strong>
            </div>
          </div>

          {/* Bento Card 3: WhatsApp Chronic Refill CRM (Span 4) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 4",
              background: "linear-gradient(135deg, #F0FDF4 0%, #FFFFFF 100%)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
            }}
          >
            <div>
              <div
                style={{
                  width: "48px",
                  height: "48px",
                  borderRadius: "14px",
                  backgroundColor: AppColors.white,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 4px 12px rgba(37, 211, 102, 0.2)",
                  color: "#25D366",
                  marginBottom: "1.25rem",
                }}
              >
                <MessageSquare size={24} />
              </div>

              <h3
                style={{
                  fontSize: "1.25rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.5rem",
                }}
              >
                1-Click WhatsApp Refills
              </h3>

              <p style={{ fontSize: "0.88rem", color: AppColors.textSecondary, lineHeight: 1.6, marginBottom: "1rem" }}>
                Keep chronic cardiac &amp; diabetic patients coming back. Send automated WhatsApp dosage reminders 3 days before supply ends.
              </p>
            </div>

            <div
              style={{
                backgroundColor: "#25D366",
                color: "#FFFFFF",
                borderRadius: "10px",
                padding: "0.6rem 0.85rem",
                fontSize: "0.78rem",
                fontWeight: 700,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "6px",
              }}
            >
              <MessageSquare size={14} />
              <span>+32% Repeat Patient Retention</span>
            </div>
          </div>

          {/* Bento Card 4: Cold Storage 2°C–8°C Locator (Span 4) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 4",
              background: "linear-gradient(135deg, #ECFEFF 0%, #FFFFFF 100%)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
            }}
          >
            <div>
              <div
                style={{
                  width: "48px",
                  height: "48px",
                  borderRadius: "14px",
                  backgroundColor: AppColors.white,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 4px 12px rgba(6, 182, 212, 0.2)",
                  color: AppColors.primaryCyan,
                  marginBottom: "1.25rem",
                }}
              >
                <ThermometerSnowflake size={24} />
              </div>

              <h3
                style={{
                  fontSize: "1.25rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.5rem",
                }}
              >
                Rack &amp; Cold Storage (2°C–8°C)
              </h3>

              <p style={{ fontSize: "0.88rem", color: AppColors.textSecondary, lineHeight: 1.6, marginBottom: "1rem" }}>
                Visual aisle, rack, and shelf mapping so staff find any medicine in 5 seconds. Dedicated refrigeration unit telemetry for insulin &amp; biologicals.
              </p>
            </div>

            <div
              style={{
                backgroundColor: AppColors.tealSurface,
                color: AppColors.deepTeal,
                borderRadius: "10px",
                padding: "0.6rem 0.85rem",
                fontSize: "0.78rem",
                fontWeight: 700,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <span>Insulin Unit C1</span>
              <span>Telemetry: 3.8°C (Optimal)</span>
            </div>
          </div>

          {/* Bento Card 5: Stockist Inward POs (Span 4) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 4",
              background: "linear-gradient(135deg, #F0FDFA 0%, #FFFFFF 100%)",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
            }}
          >
            <div>
              <div
                style={{
                  width: "48px",
                  height: "48px",
                  borderRadius: "14px",
                  backgroundColor: AppColors.white,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 4px 12px rgba(15, 118, 110, 0.15)",
                  color: AppColors.deepTeal,
                  marginBottom: "1.25rem",
                }}
              >
                <Building2 size={24} />
              </div>

              <h3
                style={{
                  fontSize: "1.25rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.5rem",
                }}
              >
                Stockist Procurement &amp; POs
              </h3>

              <p style={{ fontSize: "0.88rem", color: AppColors.textSecondary, lineHeight: 1.6, marginBottom: "1rem" }}>
                Draft POs, verify distributor inward bills, reconcile free scheme strips, and monitor supplier credit accounts payable with due dates.
              </p>
            </div>

            <div
              style={{
                backgroundColor: AppColors.frostMint,
                borderRadius: "10px",
                padding: "0.6rem 0.85rem",
                fontSize: "0.78rem",
                color: AppColors.textSecondary,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                border: `1px solid ${AppColors.borderSubtle}`,
              }}
            >
              <span>Distributor Reconciliation</span>
              <strong style={{ color: AppColors.primaryEmerald }}>100% Matched</strong>
            </div>
          </div>

          {/* Bento Card 6: Double-Entry Daybook & GST (Span 12) */}
          <div
            className="bento-card"
            style={{
              gridColumn: "span 12",
              background: "linear-gradient(135deg, #FFFBEB 0%, #FFFFFF 100%)",
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 280px), 1fr))",
              gap: "2rem",
              alignItems: "center",
            }}
          >
            <div>
              <div
                style={{
                  width: "48px",
                  height: "48px",
                  borderRadius: "14px",
                  backgroundColor: AppColors.white,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 4px 12px rgba(245, 158, 11, 0.2)",
                  color: AppColors.amberWarning,
                  marginBottom: "1.25rem",
                }}
              >
                <FileSpreadsheet size={24} />
              </div>

              <h3
                style={{
                  fontSize: "1.45rem",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "0.6rem",
                  letterSpacing: "-0.02em",
                }}
              >
                Complete 24-Account Financial Daybook &amp; GST Returns
              </h3>

              <p style={{ fontSize: "0.95rem", color: AppColors.textSecondary, lineHeight: 1.6, marginBottom: "1.25rem" }}>
                Eliminate accountant delays. Cash and bank daybooks update simultaneously with each counter transaction.
                Generate Trial Balance, Profit &amp; Loss, and export one-click GSTR-1 and GSTR-3B audit summaries.
              </p>

              <div style={{ display: "flex", flexWrap: "wrap", gap: "0.6rem" }}>
                <span style={{ fontSize: "0.78rem", backgroundColor: AppColors.white, border: `1px solid ${AppColors.borderSubtle}`, padding: "4px 10px", borderRadius: "6px", fontWeight: 600 }}>
                  ✓ Cash in Drawer vs UPI Reconciliation
                </span>
                <span style={{ fontSize: "0.78rem", backgroundColor: AppColors.white, border: `1px solid ${AppColors.borderSubtle}`, padding: "4px 10px", borderRadius: "6px", fontWeight: 600 }}>
                  ✓ One-Click GSTR-1 JSON Export
                </span>
                <span style={{ fontSize: "0.78rem", backgroundColor: AppColors.white, border: `1px solid ${AppColors.borderSubtle}`, padding: "4px 10px", borderRadius: "6px", fontWeight: 600 }}>
                  ✓ Supplier Debit Notes &amp; Schemes
                </span>
              </div>
            </div>

            {/* Right Mini Preview Table */}
            <div
              style={{
                backgroundColor: AppColors.white,
                borderRadius: "16px",
                padding: "1.25rem",
                border: `1px solid ${AppColors.borderSubtle}`,
                boxShadow: "0 4px 14px rgba(0,0,0,0.03)",
              }}
            >
              <div style={{ fontSize: "0.82rem", fontWeight: 700, color: AppColors.textPrimary, marginBottom: "0.75rem" }}>
                LIVE DAYBOOK CLOSING SUMMARY
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.82rem", padding: "6px 0", borderBottom: `1px solid ${AppColors.frostMint}` }}>
                <span>Counter Cash Collected:</span>
                <strong className="tabular-nums" style={{ color: AppColors.primaryEmerald }}>₹24,850.00</strong>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.82rem", padding: "6px 0", borderBottom: `1px solid ${AppColors.frostMint}` }}>
                <span>UPI / QR Direct Settlement:</span>
                <strong className="tabular-nums" style={{ color: AppColors.primaryEmerald }}>₹31,420.50</strong>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.82rem", padding: "6px 0" }}>
                <span>Stockist AP Due This Week:</span>
                <strong className="tabular-nums" style={{ color: AppColors.crimsonAlert }}>₹16,200.00</strong>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom CTA Banner within Features Section */}
        <div
          style={{
            marginTop: "3.5rem",
            backgroundColor: AppColors.bgSidebar,
            borderRadius: "22px",
            padding: "clamp(1.25rem, 4vw, 2.25rem)",
            display: "flex",
            flexWrap: "wrap",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "1.5rem",
            color: "#FFFFFF",
            boxShadow: "0 16px 36px -8px rgba(11, 25, 23, 0.4)",
          }}
        >
          <div>
            <div style={{ fontSize: "1.25rem", fontWeight: 800, marginBottom: "0.25rem" }}>
              Ready to Upgrade Your Pharmacy Counter?
            </div>
            <div style={{ fontSize: "0.88rem", color: "#94A3B8" }}>
              Install X Medica on Google Play or request a free 15-minute dispensary setup.
            </div>
          </div>
          <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
            <button
              onClick={onOpenPlayStoreModal}
              style={{
                backgroundColor: AppColors.primaryEmerald,
                color: "#FFFFFF",
                padding: "0.75rem 1.4rem",
                borderRadius: "12px",
                fontWeight: 700,
                fontSize: "0.9rem",
                display: "flex",
                alignItems: "center",
                gap: "0.45rem",
                boxShadow: `0 4px 14px ${AppColors.emeraldGlow}`,
              }}
            >
              <Smartphone size={16} />
              <span>Get on Google Play</span>
            </button>
            <a
              href={AppConfig.webAppUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                backgroundColor: "rgba(255,255,255,0.08)",
                color: "#FFFFFF",
                padding: "0.75rem 1.4rem",
                borderRadius: "12px",
                fontWeight: 700,
                fontSize: "0.9rem",
                border: "1px solid rgba(255,255,255,0.15)",
                display: "flex",
                alignItems: "center",
                gap: "0.45rem",
                textDecoration: "none",
              }}
            >
              <span>Launch Live Web App</span>
              <ArrowRight size={16} />
            </a>
          </div>
        </div>

        {/* Section Responsive Breakpoint Overrides */}
        <style>{`
          @media (max-width: 960px) {
            .bento-card {
              grid-column: span 12 !important;
            }
          }
        `}</style>
      </div>
    </section>
  );
};
