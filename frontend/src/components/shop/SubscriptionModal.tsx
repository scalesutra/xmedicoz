import React, { useState } from "react";
import { apiRequest } from "../../api/client.js";
import { useShop } from "../../context/ShopContext.js";
import { useToast } from "../../context/ToastContext.js";

export const SubscriptionModal: React.FC = () => {
  const { currentShop, isSubscriptionModalOpen, setIsSubscriptionModalOpen, refreshShops } = useShop();
  const { success, error } = useToast();

  const [billingCycle, setBillingCycle] = useState<"MONTHLY" | "YEARLY">("MONTHLY");
  const [isUpgrading, setIsUpgrading] = useState(false);

  if (!isSubscriptionModalOpen || !currentShop) return null;

  const currentPlanCode = currentShop.subscription?.plan?.code || "TRIAL";
  const status = currentShop.subscription?.status || "TRIAL";
  const endDate = currentShop.subscription?.endDate
    ? new Date(currentShop.subscription.endDate).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        year: "numeric",
      })
    : "N/A";

  const handleUpgrade = async (planCode: string) => {
    setIsUpgrading(true);
    try {
      const res = await apiRequest(`/shops/${currentShop.id}/subscribe`, {
        method: "POST",
        body: JSON.stringify({ planCode, billingCycle }),
      });

      if (res.success) {
        success(`Your medical store has been upgraded to ${planCode} (${billingCycle}).`, "Subscription Updated!");
        await refreshShops();
        setIsSubscriptionModalOpen(false);
      } else {
        error(res.message || "Failed to update subscription", "Upgrade Failed");
      }
    } catch (err: any) {
      error(err.message, "Error");
    } finally {
      setIsUpgrading(false);
    }
  };

  const [apiPlans, setApiPlans] = useState<any[]>([]);

  React.useEffect(() => {
    if (isSubscriptionModalOpen) {
      apiRequest("/shops/plans").then((res) => {
        if (res.success && Array.isArray(res.data)) {
          setApiPlans(res.data);
        }
      });
    }
  }, [isSubscriptionModalOpen]);

  const defaultPlans = [
    {
      code: "TRIAL",
      name: "Free Trial",
      monthly: "₹0",
      yearly: "₹0",
      users: "2 Staff Users",
      medicines: "500 Medicines",
      invoices: "200 Bills/mo",
      features: ["FEFO Stock Ingestion", "High-speed POS Billing", "Expiry Alert Telemetry"],
      badge: "Free 14 Days",
    },
    {
      code: "STARTER",
      name: "Silver Starter",
      monthly: "₹599/mo",
      yearly: "₹5,990/yr",
      users: "3 Staff Users",
      medicines: "2,500 Medicines",
      invoices: "1,500 Bills/mo",
      features: ["FEFO & Expiry Telemetry", "WhatsApp/SMS Reminders", "Double-Entry Accounting", "Supplier AP Tracking"],
      badge: "Small Clinics",
    },
    {
      code: "PRO",
      name: "Gold Professional",
      monthly: "₹1,299/mo",
      yearly: "₹12,990/yr",
      users: "8 Staff Users",
      medicines: "15,000 Medicines",
      invoices: "8,000 Bills/mo",
      features: [
        "Multi-Counter POS Billing",
        "GST Filing Reports",
        "Refill Automation Engine",
        "Complete 24-Account Daybook",
        "Priority Support",
      ],
      badge: "Most Popular",
      recommended: true,
    },
    {
      code: "ENTERPRISE",
      name: "Platinum Enterprise",
      monthly: "₹2,499/mo",
      yearly: "₹24,990/yr",
      users: "25 Staff Users",
      medicines: "100,000 Medicines",
      invoices: "Unlimited Bills",
      features: [
        "Unlimited Multi-Counter POS",
        "Wholesale & Retail Modes",
        "Custom Prescription Print Layouts",
        "Dedicated Account Manager",
        "24/7 SLA Hotline",
      ],
      badge: "Hospital / Chain",
    },
  ];

  const plans = apiPlans.length > 0
    ? apiPlans.map((p) => {
        const fallback = defaultPlans.find((dp) => dp.code === p.code);
        return {
          code: p.code,
          name: p.name,
          monthly: `₹${Number(p.priceMonthly || 0).toLocaleString("en-IN")}/mo`,
          yearly: `₹${Number(p.priceYearly || 0).toLocaleString("en-IN")}/yr`,
          users: `${p.maxUsers} Staff Users`,
          medicines: `${Number(p.maxMedicines).toLocaleString("en-IN")} Medicines`,
          invoices: p.maxInvoicesPerMonth >= 999999 ? "Unlimited Bills" : `${Number(p.maxInvoicesPerMonth).toLocaleString("en-IN")} Bills/mo`,
          features: fallback?.features || ["FEFO Stock Ingestion", "High-speed POS Billing", "Multi-Counter POS"],
          badge: fallback?.badge || p.code,
          recommended: p.code === "PRO",
        };
      })
    : defaultPlans;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(15, 23, 42, 0.7)",
        backdropFilter: "blur(4px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 9999,
        padding: "1rem",
      }}
    >
      <div
        style={{
          backgroundColor: "#FFFFFF",
          borderRadius: "20px",
          width: "100%",
          maxWidth: "920px",
          maxHeight: "92vh",
          overflowY: "auto",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.3)",
          border: "1px solid #E2E8F0",
        }}
      >
        {/* Header */}
        <div
          style={{
            padding: "1.5rem 2rem",
            background: "linear-gradient(135deg, #0F766E 0%, #064E3B 100%)",
            color: "#FFFFFF",
            borderTopLeftRadius: "20px",
            borderTopRightRadius: "20px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.25rem" }}>
              <span style={{ fontSize: "1.35rem", fontWeight: 800 }}>MedicalCRM SaaS Subscription</span>
              <span
                style={{
                  fontSize: "0.75rem",
                  fontWeight: 700,
                  padding: "0.2rem 0.6rem",
                  borderRadius: "20px",
                  backgroundColor: status === "ACTIVE" ? "#10B981" : "#F59E0B",
                  color: "#FFFFFF",
                }}
              >
                {status}
              </span>
            </div>
            <p style={{ margin: 0, fontSize: "0.85rem", color: "#CCFBF1" }}>
              Store: <strong style={{ color: "#FFFFFF" }}>{currentShop.name}</strong> • Valid until:{" "}
              <strong style={{ color: "#FFFFFF" }}>{endDate}</strong>
            </p>
          </div>
          <button
            onClick={() => setIsSubscriptionModalOpen(false)}
            style={{
              background: "rgba(255, 255, 255, 0.15)",
              border: "none",
              borderRadius: "50%",
              width: "36px",
              height: "36px",
              color: "#FFFFFF",
              fontSize: "1.1rem",
              cursor: "pointer",
            }}
          >
            ✕
          </button>
        </div>

        {/* Content */}
        <div style={{ padding: "1.5rem 2rem" }}>
          {/* Billing Toggle */}
          <div style={{ display: "flex", justifyContent: "center", marginBottom: "1.5rem" }}>
            <div
              style={{
                display: "flex",
                backgroundColor: "#F1F5F9",
                borderRadius: "12px",
                padding: "4px",
                border: "1px solid #CBD5E1",
              }}
            >
              <button
                type="button"
                onClick={() => setBillingCycle("MONTHLY")}
                style={{
                  padding: "0.5rem 1.25rem",
                  borderRadius: "8px",
                  border: "none",
                  fontWeight: 700,
                  fontSize: "0.85rem",
                  cursor: "pointer",
                  backgroundColor: billingCycle === "MONTHLY" ? "#0F766E" : "transparent",
                  color: billingCycle === "MONTHLY" ? "#FFFFFF" : "#64748B",
                  transition: "all 0.15s ease",
                }}
              >
                Monthly Billing
              </button>
              <button
                type="button"
                onClick={() => setBillingCycle("YEARLY")}
                style={{
                  padding: "0.5rem 1.25rem",
                  borderRadius: "8px",
                  border: "none",
                  fontWeight: 700,
                  fontSize: "0.85rem",
                  cursor: "pointer",
                  backgroundColor: billingCycle === "YEARLY" ? "#0F766E" : "transparent",
                  color: billingCycle === "YEARLY" ? "#FFFFFF" : "#64748B",
                  transition: "all 0.15s ease",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.4rem",
                }}
              >
                Yearly Billing
                <span style={{ fontSize: "0.7rem", backgroundColor: "#10B981", color: "#FFFFFF", padding: "1px 5px", borderRadius: "10px" }}>
                  2 Months Free
                </span>
              </button>
            </div>
          </div>

          {/* Cards Grid */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "1rem" }}>
            {plans.map((p) => {
              const isCurrent = currentPlanCode === p.code;
              return (
                <div
                  key={p.code}
                  style={{
                    borderRadius: "14px",
                    border: p.recommended
                      ? "2px solid #0F766E"
                      : isCurrent
                      ? "2px solid #3B82F6"
                      : "1px solid #E2E8F0",
                    backgroundColor: isCurrent ? "#F0FDF4" : "#FFFFFF",
                    padding: "1.25rem 1rem",
                    display: "flex",
                    flexDirection: "column",
                    justifyContent: "space-between",
                    position: "relative",
                    boxShadow: p.recommended ? "0 10px 25px -5px rgba(15, 118, 110, 0.15)" : "none",
                  }}
                >
                  {p.recommended && (
                    <div
                      style={{
                        position: "absolute",
                        top: "-12px",
                        left: "50%",
                        transform: "translateX(-50%)",
                        backgroundColor: "#0F766E",
                        color: "#FFFFFF",
                        fontSize: "0.7rem",
                        fontWeight: 800,
                        padding: "2px 10px",
                        borderRadius: "20px",
                      }}
                    >
                      {p.badge}
                    </div>
                  )}

                  <div>
                    <h4 style={{ margin: "0 0 0.5rem 0", fontSize: "1rem", fontWeight: 800, color: "#0F172A" }}>
                      {p.name}
                    </h4>
                    <div style={{ fontSize: "1.4rem", fontWeight: 800, color: "#0F766E", marginBottom: "0.75rem" }}>
                      {billingCycle === "YEARLY" ? p.yearly : p.monthly}
                    </div>

                    <div style={{ fontSize: "0.75rem", fontWeight: 600, color: "#64748B", marginBottom: "1rem", lineHeight: "1.5" }}>
                      <div>• {p.users}</div>
                      <div>• {p.medicines}</div>
                      <div>• {p.invoices}</div>
                    </div>

                    <div style={{ borderTop: "1px solid #E2E8F0", paddingTop: "0.75rem", marginBottom: "1rem" }}>
                      {p.features.map((feat, i) => (
                        <div key={i} style={{ fontSize: "0.75rem", color: "#334155", display: "flex", gap: "0.35rem", marginBottom: "0.35rem" }}>
                          <span style={{ color: "#10B981", fontWeight: 800 }}>✓</span>
                          <span>{feat}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <button
                    onClick={() => handleUpgrade(p.code)}
                    disabled={isCurrent || isUpgrading}
                    style={{
                      width: "100%",
                      padding: "0.6rem",
                      borderRadius: "8px",
                      fontWeight: 700,
                      fontSize: "0.8rem",
                      cursor: isCurrent ? "default" : "pointer",
                      border: isCurrent ? "1px solid #10B981" : "none",
                      backgroundColor: isCurrent ? "#DCFCE7" : p.recommended ? "#0F766E" : "#1E293B",
                      color: isCurrent ? "#15803D" : "#FFFFFF",
                      transition: "all 0.15s ease",
                    }}
                  >
                    {isCurrent ? "Current Plan" : isUpgrading ? "Processing..." : `Upgrade to ${p.name.split(" ")[0]}`}
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
