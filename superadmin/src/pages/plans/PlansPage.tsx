import React, { useState, useEffect } from "react";
import { CreditCard, Check, X, Edit3, RefreshCw, Users, Pill, Receipt, Sparkles } from "lucide-react";
import { apiRequest } from "../../api/client.js";

export const PlansPage: React.FC = () => {
  const [plans, setPlans] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [editingPlan, setEditingPlan] = useState<any | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  // Form states
  const [formData, setFormData] = useState({
    name: "",
    priceMonthly: 0,
    priceYearly: 0,
    maxUsers: 2,
    maxMedicines: 500,
    maxInvoicesPerMonth: 1000,
  });

  const fetchPlans = async () => {
    setIsLoading(true);
    const res = await apiRequest("/superadmin/plans");
    if (res.success && res.data) {
      setPlans(res.data);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  const handleOpenEdit = (plan: any) => {
    setEditingPlan(plan);
    setFormData({
      name: plan.name,
      priceMonthly: plan.priceMonthly,
      priceYearly: plan.priceYearly,
      maxUsers: plan.maxUsers,
      maxMedicines: plan.maxMedicines,
      maxInvoicesPerMonth: plan.maxInvoicesPerMonth,
    });
  };

  const handleSavePlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPlan) return;
    setIsSaving(true);

    const res = await apiRequest(`/superadmin/plans/${editingPlan.id}`, {
      method: "PUT",
      body: JSON.stringify(formData),
    });

    setIsSaving(false);
    if (res.success) {
      setEditingPlan(null);
      fetchPlans();
    } else {
      alert(res.error?.message || "Failed to update plan limits");
    }
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <h2 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#F8FAFC" }}>
            SaaS Subscription Plans & Quota Tiers
          </h2>
          <p style={{ fontSize: "0.8rem", color: "#64748B" }}>
            Configure multi-tenant pharmacy resource limits, pricing, and feature matrices
          </p>
        </div>
        <button onClick={fetchPlans} className="btn btn-secondary">
          <RefreshCw size={15} />
          Refresh
        </button>
      </div>

      {isLoading ? (
        <div style={{ textAlign: "center", padding: "4rem", color: "#818CF8" }}>
          <RefreshCw size={28} className="animate-spin" style={{ animation: "spin 1s linear infinite" }} />
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "1.5rem" }}>
          {plans.map((plan) => {
            const isPro = plan.code === "PRO";
            const isEnterprise = plan.code === "ENTERPRISE";
            return (
              <div
                key={plan.id}
                className="card card-hover"
                style={{
                  position: "relative",
                  border: isPro ? "2px solid #6366F1" : isEnterprise ? "2px solid #F59E0B" : "1px solid #1E293B",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                }}
              >
                {isPro && (
                  <div
                    style={{
                      position: "absolute",
                      top: "-12px",
                      right: "20px",
                      backgroundColor: "#6366F1",
                      color: "#FFFFFF",
                      fontSize: "0.68rem",
                      fontWeight: 800,
                      padding: "2px 8px",
                      borderRadius: "9999px",
                      textTransform: "uppercase",
                      boxShadow: "0 2px 8px rgba(99, 102, 241, 0.5)",
                    }}
                  >
                    Most Popular
                  </div>
                )}

                <div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.5rem" }}>
                    <div>
                      <span className="badge badge-trial">{plan.code}</span>
                      <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC", marginTop: "0.5rem" }}>
                        {plan.name}
                      </h3>
                    </div>
                    <button
                      onClick={() => handleOpenEdit(plan)}
                      className="btn btn-secondary btn-sm"
                      title="Edit Plan Limits"
                    >
                      <Edit3 size={14} />
                    </button>
                  </div>

                  {/* Pricing */}
                  <div style={{ margin: "1rem 0", paddingBottom: "1rem", borderBottom: "1px solid #1E293B" }}>
                    <div style={{ display: "flex", alignItems: "baseline", gap: "4px" }}>
                      <span style={{ fontSize: "1.85rem", fontWeight: 900, color: "#F8FAFC" }}>
                        ₹{plan.priceMonthly.toLocaleString("en-IN")}
                      </span>
                      <span style={{ fontSize: "0.8rem", color: "#64748B" }}>/ month</span>
                    </div>
                    <div style={{ fontSize: "0.75rem", color: "#94A3B8", marginTop: "2px" }}>
                      or ₹{plan.priceYearly.toLocaleString("en-IN")} / year (billed annually)
                    </div>
                  </div>

                  {/* Limits */}
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.65rem", fontSize: "0.82rem", color: "#CBD5E1" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                      <Users size={15} color="#818CF8" />
                      <span>Up to <strong>{plan.maxUsers} staff users</strong></span>
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                      <Pill size={15} color="#34D399" />
                      <span>Up to <strong>{plan.maxMedicines.toLocaleString()} medicines</strong></span>
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                      <Receipt size={15} color="#38BDF8" />
                      <span><strong>{plan.maxInvoicesPerMonth.toLocaleString()} invoices</strong> / month</span>
                    </div>
                  </div>

                  {/* Feature Checks */}
                  <div style={{ margin: "1.25rem 0", display: "flex", flexDirection: "column", gap: "0.45rem", fontSize: "0.78rem" }}>
                    {[
                      { label: "FEFO Batch Stock Tracking", enabled: true },
                      { label: "High-Speed Counter POS", enabled: true },
                      { label: "WhatsApp & SMS Refills", enabled: plan.code !== "TRIAL" },
                      { label: "Double-Entry Accounting", enabled: plan.code === "PRO" || plan.code === "ENTERPRISE" },
                      { label: "Multi-Counter Concurrent POS", enabled: plan.code === "ENTERPRISE" },
                    ].map((f, i) => (
                      <div key={i} style={{ display: "flex", alignItems: "center", gap: "8px", color: f.enabled ? "#E2E8F0" : "#64748B" }}>
                        {f.enabled ? <Check size={14} color="#34D399" /> : <X size={14} color="#64748B" />}
                        <span>{f.label}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Footer status */}
                <div
                  style={{
                    paddingTop: "0.75rem",
                    borderTop: "1px solid #1E293B",
                    fontSize: "0.75rem",
                    color: "#94A3B8",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                  }}
                >
                  <span>Active Tenants:</span>
                  <strong style={{ color: "#F8FAFC" }}>{plan.activeSubscribers || 0} stores</strong>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Edit Plan Modal */}
      {editingPlan && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.25rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
                Edit {editingPlan.name}
              </h3>
              <button
                onClick={() => setEditingPlan(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSavePlan} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
              <div>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                  Plan Display Name
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input-control"
                  required
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Monthly Price (₹)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={formData.priceMonthly}
                    onChange={(e) => setFormData({ ...formData, priceMonthly: parseFloat(e.target.value) || 0 })}
                    className="input-control"
                    required
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Yearly Price (₹)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={formData.priceYearly}
                    onChange={(e) => setFormData({ ...formData, priceYearly: parseFloat(e.target.value) || 0 })}
                    className="input-control"
                    required
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "0.75rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Max Users
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={formData.maxUsers}
                    onChange={(e) => setFormData({ ...formData, maxUsers: parseInt(e.target.value, 10) || 1 })}
                    className="input-control"
                    required
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Max Meds
                  </label>
                  <input
                    type="number"
                    min={100}
                    value={formData.maxMedicines}
                    onChange={(e) => setFormData({ ...formData, maxMedicines: parseInt(e.target.value, 10) || 100 })}
                    className="input-control"
                    required
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                    Max Invoices/Mo
                  </label>
                  <input
                    type="number"
                    min={100}
                    value={formData.maxInvoicesPerMonth}
                    onChange={(e) => setFormData({ ...formData, maxInvoicesPerMonth: parseInt(e.target.value, 10) || 100 })}
                    className="input-control"
                    required
                  />
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem", marginTop: "1rem" }}>
                <button type="button" onClick={() => setEditingPlan(null)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" disabled={isSaving} className="btn btn-primary">
                  {isSaving ? "Saving..." : "Save Quota Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
