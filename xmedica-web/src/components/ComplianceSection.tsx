import React from "react";
import { ShieldCheck, FileCheck, Lock, Database } from "lucide-react";
import { AppColors } from "../theme/colors";

export const ComplianceSection: React.FC = () => {
  const complianceItems = [
    {
      icon: <ShieldCheck size={28} color={AppColors.primaryEmerald} />,
      title: "Schedule H & H1 Registers",
      description:
        "Mandatory Drug Controller compliant audit registers for antibiotics and restricted narcotics. Tracks prescribing doctor, patient name, batch, and quantity.",
    },
    {
      icon: <FileCheck size={28} color={AppColors.primaryCyan} />,
      title: "GST e-Invoicing & HSN Slabs",
      description:
        "Pre-loaded pharmaceutical HSN directory with automatic 0%, 5%, 12%, and 18% GST tax rate application and one-click monthly GSTR summaries.",
    },
    {
      icon: <Lock size={28} color={AppColors.deepTeal} />,
      title: "Role-Based Dispensary Access",
      description:
        "Granular access control prevents unauthorized inventory edits or rate modifications. Cashier counter mode restricts backoffice accounting and stockist POs.",
    },
    {
      icon: <Database size={28} color={AppColors.amberWarning} />,
      title: "256-Bit TLS Cloud Backups",
      description:
        "Daily automated encrypted database snapshots with off-site replication. Your store ledger and batch history remain protected against hardware loss.",
    },
  ];

  return (
    <section id="compliance" style={{ padding: "85px 0", backgroundColor: AppColors.white }}>
      <div className="container-custom">
        <div style={{ textAlign: "center", maxWidth: "750px", margin: "0 auto 3rem auto" }}>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "0.4rem",
              padding: "0.3rem 0.85rem",
              borderRadius: "9999px",
              backgroundColor: AppColors.tealSurface,
              color: AppColors.deepTeal,
              fontSize: "0.8rem",
              fontWeight: 700,
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              marginBottom: "0.75rem",
            }}
          >
            <ShieldCheck size={14} />
            <span>Drug Regulatory Adherence</span>
          </div>

          <h2
            style={{
              fontSize: "clamp(2rem, 4vw, 2.75rem)",
              fontWeight: 800,
              letterSpacing: "-0.03em",
              color: AppColors.textPrimary,
              lineHeight: 1.2,
              marginBottom: "1rem",
            }}
          >
            Built to Pass Every Drug Inspector &amp; GST Audit
          </h2>

          <p style={{ fontSize: "1.05rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
            Pharmacy compliance isn't an afterthought in X Medica — it's baked into every sale, inward receipt, and inventory movement.
          </p>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 250px), 1fr))",
            gap: "1.5rem",
          }}
        >
          {complianceItems.map((item, idx) => (
            <div
              key={idx}
              style={{
                backgroundColor: AppColors.frostMint,
                borderRadius: "18px",
                padding: "clamp(1.25rem, 4vw, 2rem)",
                border: `1px solid ${AppColors.borderSubtle}`,
                transition: "all 0.25s ease",
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.white;
                e.currentTarget.style.transform = "translateY(-4px)";
                e.currentTarget.style.borderColor = AppColors.primaryEmerald;
                e.currentTarget.style.boxShadow = "0 10px 25px -5px rgba(5, 150, 105, 0.12)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = AppColors.frostMint;
                e.currentTarget.style.transform = "none";
                e.currentTarget.style.borderColor = AppColors.borderSubtle;
                e.currentTarget.style.boxShadow = "none";
              }}
            >
              <div
                style={{
                  width: "56px",
                  height: "56px",
                  borderRadius: "14px",
                  backgroundColor: AppColors.white,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 4px 10px rgba(0,0,0,0.04)",
                  marginBottom: "1.25rem",
                }}
              >
                {item.icon}
              </div>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginBottom: "0.5rem" }}>
                {item.title}
              </h3>

              <p style={{ fontSize: "0.88rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
                {item.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
