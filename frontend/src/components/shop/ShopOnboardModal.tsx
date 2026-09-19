import React, { useState } from "react";
import { Store } from "lucide-react";
import { apiRequest } from "../../api/client.js";
import { useShop } from "../../context/ShopContext.js";
import { useToast } from "../../context/ToastContext.js";

export const ShopOnboardModal: React.FC = () => {
  const { isOnboardModalOpen, setIsOnboardModalOpen, refreshShops, setCurrentShop } = useShop();
  const { success, error } = useToast();

  const [formData, setFormData] = useState({
    name: "",
    ownerName: "",
    phone: "",
    email: "",
    drugLicenseNo: "",
    gstin: "",
    address: "",
    city: "New Delhi",
    state: "Delhi",
    pincode: "110001",
    invoicePrefix: "MED",
    planCode: "TRIAL" as "TRIAL" | "STARTER" | "PRO" | "ENTERPRISE",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!isOnboardModalOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.phone.trim()) {
      error("Store Name and Contact Phone are required", "Validation Error");
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await apiRequest("/shops", {
        method: "POST",
        body: JSON.stringify(formData),
      });

      if (res.success && res.data) {
        success(`${formData.name} is ready with isolated inventory & 14-day Free Trial.`, "Medical Store Registered!");
        await refreshShops();
        setCurrentShop(res.data);
        setIsOnboardModalOpen(false);
      } else {
        error(res.message || "Failed to create medical store", "Onboarding Failed");
      }
    } catch (err: any) {
      error(err.message, "Network Error");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(15, 23, 42, 0.65)",
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
          borderRadius: "16px",
          width: "100%",
          maxWidth: "640px",
          maxHeight: "90vh",
          overflowY: "auto",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)",
          border: "1px solid #E2E8F0",
          display: "flex",
          flexDirection: "column",
        }}
      >
        {/* Header */}
        <div
          style={{
            padding: "1.25rem 1.5rem",
            borderBottom: "1px solid #E2E8F0",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            background: "linear-gradient(135deg, #064E3B 0%, #0F766E 100%)",
            color: "#FFFFFF",
            borderTopLeftRadius: "16px",
            borderTopRightRadius: "16px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "rgba(255, 255, 255, 0.2)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "1.25rem",
                fontWeight: 800,
              }}
            >
              <Store size={22} color="#FFFFFF" />
            </div>
            <div>
              <h2 style={{ fontSize: "1.2rem", fontWeight: 700, margin: 0 }}>
                Register New Medical Store
              </h2>
              <p style={{ fontSize: "0.8rem", color: "#A7F3D0", margin: "2px 0 0 0" }}>
                Dedicated multi-tenant pharmacy with 100% isolated stock, billing & accounts
              </p>
            </div>
          </div>
          <button
            onClick={() => setIsOnboardModalOpen(false)}
            style={{
              background: "transparent",
              border: "none",
              color: "#FFFFFF",
              fontSize: "1.25rem",
              cursor: "pointer",
              padding: "0.25rem 0.5rem",
            }}
          >
            ✕
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} style={{ padding: "1.5rem", display: "flex", flexDirection: "column", gap: "1.25rem" }}>
          {/* Store Info */}
          <div>
            <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#1E293B", marginBottom: "0.75rem" }}>
              1. Store Identification & Licensing
            </h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem" }}>
              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  Medical Store / Chemist Name *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Apollo Chemist & Surgical"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  Owner / Registered Pharmacist
                </label>
                <input
                  type="text"
                  placeholder="e.g. Dr. Ramesh Kumar"
                  value={formData.ownerName}
                  onChange={(e) => setFormData({ ...formData, ownerName: e.target.value })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  Primary Contact Phone *
                </label>
                <input
                  type="tel"
                  required
                  placeholder="+91 98765 43210"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  Drug License (Form 20B / 21B)
                </label>
                <input
                  type="text"
                  placeholder="e.g. DL-20B-1082 / DL-21B-1083"
                  value={formData.drugLicenseNo}
                  onChange={(e) => setFormData({ ...formData, drugLicenseNo: e.target.value })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  GSTIN Number
                </label>
                <input
                  type="text"
                  placeholder="e.g. 07AAAAA0000A1Z5"
                  value={formData.gstin}
                  onChange={(e) => setFormData({ ...formData, gstin: e.target.value.toUpperCase() })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  Invoice Bill Prefix
                </label>
                <input
                  type="text"
                  maxLength={6}
                  placeholder="e.g. APOL"
                  value={formData.invoicePrefix}
                  onChange={(e) => setFormData({ ...formData, invoicePrefix: e.target.value.toUpperCase() })}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#475569", marginBottom: "4px" }}>
                  City & State
                </label>
                <input
                  type="text"
                  placeholder="New Delhi, Delhi"
                  value={`${formData.city}, ${formData.state}`}
                  onChange={(e) => {
                    const parts = e.target.value.split(",");
                    setFormData({ ...formData, city: parts[0]?.trim() || "", state: parts[1]?.trim() || "" });
                  }}
                  style={{
                    width: "100%",
                    padding: "0.6rem 0.75rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.9rem",
                    boxSizing: "border-box",
                  }}
                />
              </div>
            </div>
          </div>

          {/* Plan Selection */}
          <div>
            <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#1E293B", marginBottom: "0.75rem" }}>
              2. Select SaaS Subscription Plan
            </h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
              {[
                { code: "TRIAL", title: "14-Day Free Trial", price: "Free", desc: "Up to 2 staff, 200 bills/mo" },
                { code: "STARTER", title: "Silver Starter", price: "₹599/mo", desc: "Up to 3 staff, 1,500 bills/mo" },
                { code: "PRO", title: "Gold Pro (Recommended)", price: "₹1,299/mo", desc: "8 staff, 8,000 bills/mo, Accounting" },
                { code: "ENTERPRISE", title: "Platinum Enterprise", price: "₹2,499/mo", desc: "Unlimited counters & bills, 24/7 support" },
              ].map((p) => (
                <div
                  key={p.code}
                  onClick={() => setFormData({ ...formData, planCode: p.code as any })}
                  style={{
                    border: formData.planCode === p.code ? "2px solid #0F766E" : "1px solid #E2E8F0",
                    borderRadius: "10px",
                    padding: "0.75rem",
                    cursor: "pointer",
                    backgroundColor: formData.planCode === p.code ? "#F0FDF4" : "#F8FAFC",
                    transition: "all 0.15s ease",
                  }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontWeight: 700, fontSize: "0.85rem", color: "#0F172A" }}>{p.title}</span>
                    <span style={{ fontWeight: 700, fontSize: "0.85rem", color: "#0F766E" }}>{p.price}</span>
                  </div>
                  <p style={{ fontSize: "0.75rem", color: "#64748B", margin: "4px 0 0 0" }}>{p.desc}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem", marginTop: "0.5rem" }}>
            <button
              type="button"
              onClick={() => setIsOnboardModalOpen(false)}
              style={{
                padding: "0.6rem 1.25rem",
                borderRadius: "8px",
                border: "1px solid #CBD5E1",
                backgroundColor: "#F8FAFC",
                color: "#475569",
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              style={{
                padding: "0.6rem 1.5rem",
                borderRadius: "8px",
                border: "none",
                background: "linear-gradient(135deg, #059669 0%, #0F766E 100%)",
                color: "#FFFFFF",
                fontWeight: 700,
                cursor: isSubmitting ? "not-allowed" : "pointer",
                boxShadow: "0 4px 12px rgba(15, 118, 110, 0.3)",
              }}
            >
              {isSubmitting ? "Initializing Store..." : "Create & Launch Medical Store"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
