import React, { useState } from "react";
import { Check, ExternalLink } from "lucide-react";
import { AppColors } from "../theme/colors";
import { AppConfig } from "../config/appConfig";

export const PricingSection: React.FC = () => {
  const [isAnnual, setIsAnnual] = useState(false);

  // Exact plans matching backend Prisma database and SubscriptionModal.tsx
  const plans = [
    {
      code: "TRIAL",
      name: "Free Trial",
      monthly: "₹0",
      yearly: "₹0",
      users: "2 Staff Users",
      medicines: "500 Medicines",
      invoices: "200 Bills/mo",
      features: [
        "FEFO Stock Ingestion",
        "High-Speed Counter POS Billing",
        "Expiry Alert Telemetry",
        "Cash Counter Drawer",
      ],
      badge: "Free 14 Days",
      popular: false,
      ctaLabel: "Start Free 14-Day Trial",
    },
    {
      code: "STARTER",
      name: "Silver Starter",
      monthly: "₹599",
      yearly: "₹5,990",
      users: "3 Staff Users",
      medicines: "2,500 Medicines",
      invoices: "1,500 Bills/mo",
      features: [
        "FEFO & Expiry Telemetry",
        "WhatsApp / SMS Refill Alerts",
        "Double-Entry Accounting Daybook",
        "Supplier AP Credit Tracking",
        "Thermal Bluetooth POS",
      ],
      badge: "Single Counter",
      popular: false,
      ctaLabel: "Select Silver Starter",
    },
    {
      code: "PRO",
      name: "Gold Professional",
      monthly: "₹1,299",
      yearly: "₹12,990",
      users: "8 Staff Users",
      medicines: "15,000 Medicines",
      invoices: "8,000 Bills/mo",
      features: [
        "Multi-Counter POS Billing",
        "Physical Rack & Cold Storage 2°C–8°C",
        "GST Filing & HSN Reports",
        "Chronic Refill Automation Engine",
        "Complete 24-Account COA Daybook",
      ],
      badge: "Most Popular",
      popular: true,
      ctaLabel: "Select Gold Professional",
    },
    {
      code: "ENTERPRISE",
      name: "Platinum Enterprise",
      monthly: "₹2,499",
      yearly: "₹24,990",
      users: "25 Staff Users",
      medicines: "100,000 Medicines",
      invoices: "Unlimited Bills",
      features: [
        "Unlimited Multi-Counter POS",
        "Wholesale & Retail Counter Modes",
        "Prescription OCR Scanning",
        "Centralized Store Warehouse Inventory",
        "Priority 24/7 SLA Hotline",
      ],
      badge: "Hospital / Chain",
      popular: false,
      ctaLabel: "Select Platinum Enterprise",
    },
  ];

  return (
    <section id="pricing" style={{ padding: "90px 0", backgroundColor: "#FFFFFF" }}>
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
            <span>Verified System Plans</span>
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
            Official Medical Store Subscription Plans
          </h2>

          <p style={{ fontSize: "1.02rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
            Directly provisioned in the backend database. Activate your plan upon onboarding your shop on the Web App or Android App.
          </p>

          {/* Billing Cycle Switcher */}
          <div
            style={{
              display: "inline-flex",
              flexWrap: "wrap",
              justifyContent: "center",
              gap: "0.5rem",
              backgroundColor: AppColors.frostMint,
              padding: "5px 8px",
              borderRadius: "14px",
              border: `1px solid ${AppColors.borderSubtle}`,
              marginTop: "1.75rem",
              maxWidth: "100%",
            }}
          >
            <button
              onClick={() => setIsAnnual(false)}
              style={{
                padding: "6px 16px",
                borderRadius: "8px",
                fontSize: "0.88rem",
                fontWeight: 600,
                backgroundColor: !isAnnual ? AppColors.bgSidebar : "transparent",
                color: !isAnnual ? "#FFFFFF" : AppColors.textSecondary,
              }}
            >
              Monthly Billing
            </button>

            <button
              onClick={() => setIsAnnual(true)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                padding: "6px 16px",
                borderRadius: "8px",
                fontSize: "0.88rem",
                fontWeight: 700,
                backgroundColor: isAnnual ? AppColors.primaryEmerald : "transparent",
                color: isAnnual ? "#FFFFFF" : AppColors.textSecondary,
              }}
            >
              <span>Yearly (2 Months Free)</span>
              <span
                style={{
                  fontSize: "0.7rem",
                  backgroundColor: isAnnual ? "#FFFFFF" : AppColors.tealSurface,
                  color: isAnnual ? AppColors.primaryEmerald : AppColors.deepTeal,
                  padding: "1px 6px",
                  borderRadius: "4px",
                  fontWeight: 800,
                }}
              >
                SAVE 17%
              </span>
            </button>
          </div>
        </div>

        {/* 4 Plans Grid */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 250px), 1fr))",
            gap: "1.5rem",
            alignItems: "stretch",
          }}
        >
          {plans.map((plan) => {
            const price = isAnnual ? plan.yearly : plan.monthly;
            const period = isAnnual ? "/ year" : "/ month";
            return (
              <div
                key={plan.code}
                className={plan.popular ? "pricing-card pricing-card-popular" : "pricing-card"}
                style={{
                  backgroundColor: "#FFFFFF",
                  borderRadius: "20px",
                  border: plan.popular
                    ? `2px solid ${AppColors.primaryEmerald}`
                    : `1px solid ${AppColors.borderSubtle}`,
                  padding: "clamp(1.5rem, 4vw, 2rem) 1.25rem",
                  display: "flex",
                  flexDirection: "column",
                  position: "relative",
                  boxShadow: plan.popular
                    ? "0 16px 36px -8px rgba(5, 150, 105, 0.22)"
                    : "0 4px 12px rgba(0,0,0,0.03)",
                }}
              >
                {plan.popular && (
                  <div
                    style={{
                      position: "absolute",
                      top: "-12px",
                      left: "50%",
                      transform: "translateX(-50%)",
                      backgroundColor: AppColors.primaryEmerald,
                      color: "#FFFFFF",
                      fontSize: "0.72rem",
                      fontWeight: 800,
                      padding: "3px 12px",
                      borderRadius: "9999px",
                      letterSpacing: "0.05em",
                      textTransform: "uppercase",
                    }}
                  >
                    MOST POPULAR
                  </div>
                )}

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.78rem", fontWeight: 700, color: AppColors.deepTeal, marginBottom: "4px" }}>
                    {plan.badge}
                  </div>
                  <h3 style={{ fontSize: "1.35rem", fontWeight: 800, color: AppColors.textPrimary }}>
                    {plan.name}
                  </h3>
                </div>

                {/* Price */}
                <div style={{ marginBottom: "1.5rem", display: "flex", alignItems: "baseline", gap: "4px" }}>
                  <span
                    style={{
                      fontSize: "2.4rem",
                      fontWeight: 800,
                      color: AppColors.textPrimary,
                      letterSpacing: "-0.03em",
                    }}
                    className="tabular-nums"
                  >
                    {price}
                  </span>
                  <span style={{ fontSize: "0.85rem", color: AppColors.textMuted, fontWeight: 500 }}>
                    {plan.code !== "TRIAL" ? period : ""}
                  </span>
                </div>

                {/* Capacity Specs */}
                <div
                  style={{
                    backgroundColor: AppColors.frostMint,
                    borderRadius: "10px",
                    padding: "0.75rem",
                    marginBottom: "1.5rem",
                    fontSize: "0.78rem",
                    color: AppColors.textSecondary,
                    display: "flex",
                    flexDirection: "column",
                    gap: "4px",
                  }}
                >
                  <div><strong>Users:</strong> {plan.users}</div>
                  <div><strong>Catalog:</strong> {plan.medicines}</div>
                  <div><strong>Volume:</strong> {plan.invoices}</div>
                </div>

                {/* Features List */}
                <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", marginBottom: "2rem", flex: 1 }}>
                  {plan.features.map((feat, fIdx) => (
                    <div key={fIdx} style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem" }}>
                      <div
                        style={{
                          width: "18px",
                          height: "18px",
                          borderRadius: "50%",
                          backgroundColor: AppColors.tealSurface,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          color: AppColors.primaryEmerald,
                          flexShrink: 0,
                          marginTop: "2px",
                        }}
                      >
                        <Check size={12} strokeWidth={3} />
                      </div>
                      <span style={{ fontSize: "0.82rem", color: AppColors.textSecondary }}>
                        {feat}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Direct Action Link to real app onboarding */}
                <a
                  href={AppConfig.webAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    width: "100%",
                    padding: "0.85rem",
                    borderRadius: "10px",
                    fontWeight: 700,
                    fontSize: "0.88rem",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "0.45rem",
                    backgroundColor: plan.popular ? AppColors.primaryEmerald : AppColors.bgSidebar,
                    color: "#FFFFFF",
                    textDecoration: "none",
                    boxShadow: plan.popular ? `0 4px 14px ${AppColors.emeraldGlow}` : "none",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "none";
                  }}
                >
                  <span>{plan.ctaLabel}</span>
                  <ExternalLink size={14} />
                </a>
              </div>
            );
          })}
        </div>
      </div>

      <style>{`
        @media (min-width: 992px) {
          .pricing-card-popular {
            transform: scale(1.02);
          }
        }
      `}</style>
    </section>
  );
};
