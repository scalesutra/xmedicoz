import React, { useState, useEffect } from "react";
import {
  Building2,
  Users,
  ShieldCheck,
  Save,
  Plus,
  RefreshCw,
  AlertCircle,
  CheckCircle2,
  FileText,
  Phone,
  Mail,
  MapPin,
  Award,
  CreditCard,
  UserCheck,
} from "lucide-react";
import { useShop } from "../../context/ShopContext.js";
import { apiRequest } from "../../api/client.js";

interface StaffMember {
  id: string;
  shopId: string;
  userId: string;
  role: "OWNER" | "PHARMACIST" | "CASHIER" | "STAFF";
  status: "ACTIVE" | "INACTIVE";
  createdAt: string;
  user: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phone?: string;
  };
}

export const StoreSettingsPage: React.FC = () => {
  const { currentShop, refreshShops, setIsSubscriptionModalOpen } = useShop();

  const [activeTab, setActiveTab] = useState<"profile" | "staff" | "subscription">("profile");

  // Store Profile State
  const [profileForm, setProfileForm] = useState({
    name: "",
    ownerName: "",
    phone: "",
    email: "",
    drugLicenseNo: "",
    gstin: "",
    address: "",
    city: "",
    state: "",
    pincode: "",
    invoicePrefix: "INV",
  });

  const [isSavingProfile, setIsSavingProfile] = useState(false);
  const [profileSuccess, setProfileSuccess] = useState<string | null>(null);
  const [profileError, setProfileError] = useState<string | null>(null);

  // Staff State
  const [staffList, setStaffList] = useState<StaffMember[]>([]);
  const [isLoadingStaff, setIsLoadingStaff] = useState(false);
  const [staffError, setStaffError] = useState<string | null>(null);

  // Add Staff Modal State
  const [isAddStaffOpen, setIsAddStaffOpen] = useState(false);
  const [newStaff, setNewStaff] = useState({
    email: "",
    firstName: "",
    lastName: "",
    role: "PHARMACIST" as "PHARMACIST" | "CASHIER" | "STAFF",
  });
  const [isSubmittingStaff, setIsSubmittingStaff] = useState(false);
  const [addStaffError, setAddStaffError] = useState<string | null>(null);

  // Sync profileForm when currentShop changes
  useEffect(() => {
    if (currentShop) {
      setProfileForm({
        name: currentShop.name || "",
        ownerName: currentShop.ownerName || "",
        phone: currentShop.phone || "",
        email: currentShop.email || "",
        drugLicenseNo: currentShop.drugLicenseNo || "",
        gstin: currentShop.gstin || "",
        address: currentShop.address || "",
        city: currentShop.city || "",
        state: currentShop.state || "",
        pincode: currentShop.pincode || "",
        invoicePrefix: currentShop.invoicePrefix || "INV",
      });
      loadStaff();
    }
  }, [currentShop?.id]);

  const loadStaff = async () => {
    if (!currentShop?.id) return;
    setIsLoadingStaff(true);
    setStaffError(null);
    try {
      const res = await apiRequest<StaffMember[]>(`/shops/${currentShop.id}/members`);
      if (res.success && Array.isArray(res.data)) {
        setStaffList(res.data);
      } else {
        setStaffError(res.message || "Failed to load staff list.");
      }
    } catch (err: any) {
      setStaffError(err.message || "Failed to load staff list.");
    } finally {
      setIsLoadingStaff(false);
    }
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentShop?.id) return;

    setIsSavingProfile(true);
    setProfileSuccess(null);
    setProfileError(null);

    try {
      const res = await apiRequest(`/shops/${currentShop.id}`, {
        method: "PUT",
        body: JSON.stringify(profileForm),
      });

      if (res.success) {
        setProfileSuccess("Pharmacy profile & invoicing credentials updated successfully!");
        await refreshShops();
        setTimeout(() => setProfileSuccess(null), 5000);
      } else {
        setProfileError(res.message || "Failed to update pharmacy details.");
      }
    } catch (err: any) {
      setProfileError(err.message || "Network error while saving.");
    } finally {
      setIsSavingProfile(false);
    }
  };

  const handleAddStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentShop?.id) return;

    setIsSubmittingStaff(true);
    setAddStaffError(null);

    try {
      const res = await apiRequest(`/shops/${currentShop.id}/members`, {
        method: "POST",
        body: JSON.stringify(newStaff),
      });

      if (res.success) {
        setIsAddStaffOpen(false);
        setNewStaff({ email: "", firstName: "", lastName: "", role: "PHARMACIST" });
        loadStaff();
      } else {
        setAddStaffError(res.message || "Failed to add staff member.");
      }
    } catch (err: any) {
      setAddStaffError(err.message || "Network error adding staff.");
    } finally {
      setIsSubmittingStaff(false);
    }
  };

  const getRoleBadge = (role: string) => {
    switch (role) {
      case "OWNER":
        return <span style={{ backgroundColor: "#FEF3C7", color: "#92400E", padding: "3px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Owner / Admin</span>;
      case "PHARMACIST":
        return <span style={{ backgroundColor: "#E0F2FE", color: "#0369A1", padding: "3px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Dispensing Pharmacist</span>;
      case "CASHIER":
        return <span style={{ backgroundColor: "#DCFCE7", color: "#15803D", padding: "3px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Counter Cashier</span>;
      default:
        return <span style={{ backgroundColor: "#F1F5F9", color: "#475569", padding: "3px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Staff</span>;
    }
  };

  if (!currentShop) {
    return (
      <div style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
        No active pharmacy store selected. Please onboard or select a pharmacy first.
      </div>
    );
  }

  return (
    <div style={{ padding: "1.5rem", maxWidth: "1200px", margin: "0 auto" }}>
      {/* Top Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem" }}>
        <div>
          <h1 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "0.5rem" }}>
            <Building2 size={22} color="#0F766E" />
            Pharmacy Administration & Store Settings
          </h1>
          <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "#64748B" }}>
            Single-store compliance, Drug License numbers, GSTIN, bill headers, and counter staff access.
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", gap: "0.5rem", borderBottom: "1px solid #E2E8F0", marginBottom: "1.5rem" }}>
        <button
          onClick={() => setActiveTab("profile")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "profile" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "profile" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "profile" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Building2 size={16} />
          Pharmacy Profile & Invoicing
        </button>
        <button
          onClick={() => setActiveTab("staff")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "staff" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "staff" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "staff" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Users size={16} />
          Counter Staff & Roles ({staffList.length})
        </button>
        <button
          onClick={() => setActiveTab("subscription")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "subscription" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "subscription" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "subscription" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Award size={16} />
          Plan & Subscription
        </button>
      </div>

      {/* Profile Tab */}
      {activeTab === "profile" && (
        <form onSubmit={handleSaveProfile} style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", border: "1px solid #E2E8F0", padding: "1.5rem", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
          {profileSuccess && (
            <div style={{ backgroundColor: "#ECFDF5", border: "1px solid #A7F3D0", color: "#065F46", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
              <CheckCircle2 size={18} />
              {profileSuccess}
            </div>
          )}
          {profileError && (
            <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
              <AlertCircle size={18} />
              {profileError}
            </div>
          )}

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem", marginBottom: "1.5rem" }}>
            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Pharmacy Trade Name *
              </label>
              <input
                type="text"
                required
                value={profileForm.name}
                onChange={(e) => setProfileForm({ ...profileForm, name: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Registered Owner / Pharmacist In-Charge
              </label>
              <input
                type="text"
                value={profileForm.ownerName}
                onChange={(e) => setProfileForm({ ...profileForm, ownerName: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Drug License Numbers (DL Form 20B / 21B) *
              </label>
              <input
                type="text"
                required
                placeholder="e.g. DL-20B-129482 / DL-21B-129483"
                value={profileForm.drugLicenseNo}
                onChange={(e) => setProfileForm({ ...profileForm, drugLicenseNo: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
              <span style={{ fontSize: "0.7rem", color: "#64748B" }}>Printed automatically on all POS tax invoices for Schedule H/H1 compliance.</span>
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                GSTIN Identification Number
              </label>
              <input
                type="text"
                placeholder="e.g. 07AAAAA0000A1Z5"
                value={profileForm.gstin}
                onChange={(e) => setProfileForm({ ...profileForm, gstin: e.target.value.toUpperCase() })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Primary Pharmacy Phone *
              </label>
              <input
                type="text"
                required
                value={profileForm.phone}
                onChange={(e) => setProfileForm({ ...profileForm, phone: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Official Email Address
              </label>
              <input
                type="email"
                value={profileForm.email}
                onChange={(e) => setProfileForm({ ...profileForm, email: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div style={{ gridColumn: "1 / -1" }}>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Pharmacy Store Street Address
              </label>
              <input
                type="text"
                value={profileForm.address}
                onChange={(e) => setProfileForm({ ...profileForm, address: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                City
              </label>
              <input
                type="text"
                value={profileForm.city}
                onChange={(e) => setProfileForm({ ...profileForm, city: e.target.value })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
              <div>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  State
                </label>
                <input
                  type="text"
                  value={profileForm.state}
                  onChange={(e) => setProfileForm({ ...profileForm, state: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>
              <div>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Pincode
                </label>
                <input
                  type="text"
                  value={profileForm.pincode}
                  onChange={(e) => setProfileForm({ ...profileForm, pincode: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>
            </div>

            <div>
              <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                Sales Bill Prefix (Max 6 chars)
              </label>
              <input
                type="text"
                maxLength={6}
                value={profileForm.invoicePrefix}
                onChange={(e) => setProfileForm({ ...profileForm, invoicePrefix: e.target.value.toUpperCase() })}
                style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
              />
              <span style={{ fontSize: "0.7rem", color: "#64748B" }}>Generated bills will format as e.g. {profileForm.invoicePrefix || "INV"}-2026-0001</span>
            </div>
          </div>

          <div style={{ display: "flex", justifyContent: "flex-end" }}>
            <button
              type="submit"
              disabled={isSavingProfile}
              style={{
                backgroundColor: "#0F766E",
                color: "#FFFFFF",
                border: "none",
                borderRadius: "6px",
                padding: "0.6rem 1.5rem",
                fontSize: "0.85rem",
                fontWeight: 700,
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                boxShadow: "0 2px 4px rgba(15, 118, 110, 0.25)",
              }}
            >
              {isSavingProfile ? <RefreshCw size={16} className="animate-spin" /> : <Save size={16} />}
              Save Store Profile
            </button>
          </div>
        </form>
      )}

      {/* Staff Tab */}
      {activeTab === "staff" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <div>
              <h2 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Counter Staff & Dispensary Access
              </h2>
              <p style={{ margin: "2px 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                Add pharmacists and billing cashiers for this pharmacy store.
              </p>
            </div>
            <button
              onClick={() => setIsAddStaffOpen(true)}
              style={{
                backgroundColor: "#0F766E",
                color: "#FFFFFF",
                border: "none",
                borderRadius: "6px",
                padding: "0.5rem 1rem",
                fontSize: "0.82rem",
                fontWeight: 700,
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                gap: "0.4rem",
              }}
            >
              <Plus size={16} /> Add Staff Member
            </button>
          </div>

          {staffError && (
            <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", fontSize: "0.85rem" }}>
              {staffError}
            </div>
          )}

          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", border: "1px solid #E2E8F0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Staff Name</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Email Address</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Assigned Role</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Status</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Joined Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoadingStaff ? (
                  <tr>
                    <td colSpan={5} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                      Loading team members...
                    </td>
                  </tr>
                ) : staffList.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                      No staff members added yet. Click "+ Add Staff Member" to add pharmacists or cashiers.
                    </td>
                  </tr>
                ) : (
                  staffList.map((member) => (
                    <tr key={member.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.75rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                        {member.user?.firstName} {member.user?.lastName || ""}
                      </td>
                      <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>
                        {member.user?.email}
                      </td>
                      <td style={{ padding: "0.75rem 1rem" }}>
                        {getRoleBadge(member.role)}
                      </td>
                      <td style={{ padding: "0.75rem 1rem" }}>
                        <span style={{ color: member.status === "ACTIVE" ? "#059669" : "#DC2626", fontWeight: 600 }}>
                          ● {member.status}
                        </span>
                      </td>
                      <td style={{ padding: "0.75rem 1rem", color: "#94A3B8" }}>
                        {new Date(member.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Subscription Tab */}
      {activeTab === "subscription" && (
        <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", border: "1px solid #E2E8F0", padding: "1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
            <div>
              <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Active Plan: {currentShop.subscription?.plan?.name || "Trial Edition"}
              </h2>
              <p style={{ margin: "4px 0 0", fontSize: "0.82rem", color: "#64748B" }}>
                Status: <strong style={{ color: "#059669" }}>{currentShop.subscription?.status || "ACTIVE"}</strong>
              </p>
            </div>
            <button
              onClick={() => setIsSubscriptionModalOpen(true)}
              style={{
                backgroundColor: "#0F766E",
                color: "#FFFFFF",
                border: "none",
                borderRadius: "6px",
                padding: "0.55rem 1.2rem",
                fontSize: "0.82rem",
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Upgrade / Renew Plan
            </button>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "1rem" }}>
            <div style={{ padding: "1rem", backgroundColor: "#F8FAF9", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
              <span style={{ fontSize: "0.75rem", color: "#64748B", fontWeight: 600 }}>STAFF USER LIMIT</span>
              <div style={{ fontSize: "1.25rem", fontWeight: 800, color: "#0F172A", marginTop: "4px" }}>
                {staffList.length} / {currentShop.subscription?.plan?.maxUsers || 2} Users
              </div>
            </div>
            <div style={{ padding: "1rem", backgroundColor: "#F8FAF9", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
              <span style={{ fontSize: "0.75rem", color: "#64748B", fontWeight: 600 }}>MAX MONTHLY INVOICES</span>
              <div style={{ fontSize: "1.25rem", fontWeight: 800, color: "#0F172A", marginTop: "4px" }}>
                {currentShop.subscription?.plan?.maxInvoicesPerMonth || 1000} Bills
              </div>
            </div>
            <div style={{ padding: "1rem", backgroundColor: "#F8FAF9", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
              <span style={{ fontSize: "0.75rem", color: "#64748B", fontWeight: 600 }}>MEDICINE INVENTORY CATALOG</span>
              <div style={{ fontSize: "1.25rem", fontWeight: 800, color: "#0F172A", marginTop: "4px" }}>
                {currentShop.subscription?.plan?.maxMedicines || 500} SKUs
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add Staff Modal */}
      {isAddStaffOpen && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "460px", padding: "1.5rem", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <h3 style={{ margin: "0 0 1rem", fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
              Add Staff Member to Store
            </h3>

            {addStaffError && (
              <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.6rem 0.85rem", borderRadius: "6px", marginBottom: "1rem", fontSize: "0.8rem" }}>
                {addStaffError}
              </div>
            )}

            <form onSubmit={handleAddStaff}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  First Name *
                </label>
                <input
                  type="text"
                  required
                  value={newStaff.firstName}
                  onChange={(e) => setNewStaff({ ...newStaff, firstName: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Last Name
                </label>
                <input
                  type="text"
                  value={newStaff.lastName}
                  onChange={(e) => setNewStaff({ ...newStaff, lastName: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Staff Email Address *
                </label>
                <input
                  type="email"
                  required
                  value={newStaff.email}
                  onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Staff Role *
                </label>
                <select
                  value={newStaff.role}
                  onChange={(e) => setNewStaff({ ...newStaff, role: e.target.value as any })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}
                >
                  <option value="PHARMACIST">Dispensing Pharmacist (Full Dispensing & Inventory)</option>
                  <option value="CASHIER">Counter Cashier (Fast Billing & POS)</option>
                  <option value="STAFF">General Dispensary Staff</option>
                </select>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.5rem" }}>
                <button
                  type="button"
                  onClick={() => setIsAddStaffOpen(false)}
                  style={{ padding: "0.5rem 1rem", border: "1px solid #CBD5E1", borderRadius: "6px", background: "none", fontSize: "0.82rem", cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingStaff}
                  style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1.2rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}
                >
                  {isSubmittingStaff ? "Adding..." : "Add Member"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
