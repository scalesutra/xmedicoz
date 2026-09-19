import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR } from "../../utils/formatters.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { Users, Search, Plus, X, Phone, ShieldCheck, Camera, Sparkles, Edit2, Trash2, History, Receipt, Calendar, Pill } from "lucide-react";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface CustomerItem {
  id: string;
  name: string;
  mobile: string;
  email?: string;
  customerType: string;
  isPermanent: boolean;
  creditLimit: number | string;
  currentBalance: number | string;
  notificationOptOut: boolean;
}

export const CustomersPage: React.FC = () => {
  const [customers, setCustomers] = useState<CustomerItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Modal State
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    mobile: "",
    email: "",
    customerType: "REGULAR",
    isPermanent: false,
    creditLimit: 0,
  });

  // Edit Customer State
  const [editingCustomer, setEditingCustomer] = useState<CustomerItem | null>(null);
  const [editFormData, setEditFormData] = useState({
    name: "",
    mobile: "",
    email: "",
    customerType: "REGULAR",
    isPermanent: false,
    creditLimit: 0,
    notificationOptOut: false,
  });

  // Customer History State
  const [historyCustomer, setHistoryCustomer] = useState<CustomerItem | null>(null);
  const [customerHistory, setCustomerHistory] = useState<any[]>([]);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);

  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  const fetchCustomers = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const res = await apiRequest("/masters/customers", {
      params: { search: searchQuery || undefined, limit: 50 },
    });

    if (res.success && res.data) {
      setCustomers(Array.isArray(res.data) ? res.data : res.data.items || []);
    } else {
      setErrorMessage(res.message || "Failed to retrieve customers");
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchCustomers();
  }, [searchQuery]);

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.mobile) {
      alert("Please provide both customer name and mobile number");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: "Register New Customer",
      message: `Confirm adding customer "${formData.name}" (${formData.mobile}) with ${formData.isPermanent ? `permanent account and credit limit ${formatINR(formData.creditLimit)}` : "regular retail tier"}?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/masters/customers", {
          method: "POST",
          body: JSON.stringify(formData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setIsCreateOpen(false);
          setFormData({
            name: "",
            mobile: "",
            email: "",
            customerType: "REGULAR",
            isPermanent: false,
            creditLimit: 0,
          });
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchCustomers();
        } else {
          alert(res.message || "Failed to create customer");
        }
      },
    });
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingCustomer) return;

    setConfirmModal({
      isOpen: true,
      title: "Update Customer Details",
      message: `Confirm updating details for customer "${editFormData.name}"?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/customers/${editingCustomer.id}`, {
          method: "PATCH",
          body: JSON.stringify(editFormData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setEditingCustomer(null);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchCustomers();
        } else {
          alert(res.message || "Failed to update customer");
        }
      },
    });
  };

  const handleDeleteCustomer = (cust: CustomerItem) => {
    setConfirmModal({
      isOpen: true,
      title: "Delete Customer Record",
      message: `Are you sure you want to deactivate customer "${cust.name}" (${cust.mobile})? Outstanding balance: ${formatINR(cust.currentBalance)}.`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/customers/${cust.id}`, {
          method: "DELETE",
        });
        setIsSubmitting(false);

        if (res.success) {
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchCustomers();
        } else {
          alert(res.message || "Failed to delete customer");
        }
      },
    });
  };

  const handleViewHistory = async (cust: CustomerItem) => {
    setHistoryCustomer(cust);
    setIsHistoryLoading(true);
    const res = await apiRequest(`/crm/customers/${cust.id}/history`);
    if (res.success && Array.isArray(res.data)) {
      setCustomerHistory(res.data);
    } else {
      setCustomerHistory([]);
    }
    setIsHistoryLoading(false);
  };

  return (
    <div className="animate-scale-in" style={{ padding: "1.25rem 1.5rem" }}>
      {/* Controls Bar */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "0.85rem",
          marginBottom: "1.25rem",
        }}
      >
        <div style={{ position: "relative", flex: "1 1 280px", maxWidth: "420px" }}>
          <div style={{ position: "absolute", left: "0.85rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
            <Search size={16} />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by phone number or patient name..."
            style={{
              width: "100%",
              padding: "0.6rem 0.9rem 0.6rem 2.3rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              fontSize: "0.85rem",
              backgroundColor: "#FFFFFF",
              outline: "none",
            }}
          />
        </div>

        <div style={{ display: "flex", gap: "0.6rem", flexWrap: "wrap" }}>
          <button
            onClick={() => setIsOcrOpen(true)}
            style={{
              padding: "0.55rem 1rem",
              backgroundColor: "#EFF6FF",
              color: "#1D4ED8",
              border: "1px solid #BFDBFE",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
              boxShadow: "0 1px 3px rgba(37, 99, 235, 0.1)",
              whiteSpace: "nowrap",
            }}
          >
            <Camera size={16} color="#2563EB" />
            <span>AI Scan Slip / ID</span>
          </button>

          <button
            onClick={() => setIsCreateOpen(true)}
            style={{
              padding: "0.55rem 1.1rem",
              backgroundColor: "#059669",
              color: "#FFFFFF",
              border: "none",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
              boxShadow: "0 2px 5px rgba(5, 150, 105, 0.25)",
              whiteSpace: "nowrap",
            }}
          >
            <Plus size={16} />
            Add Customer
          </button>
        </div>
      </div>

      {/* Main Table */}
      {isLoading ? (
        <div className="glass-card">
          <TableSkeleton rows={6} cols={6} />
        </div>
      ) : errorMessage ? (
        <ErrorCard message={errorMessage} onRetry={fetchCustomers} />
      ) : (
        <div className="glass-card" style={{ overflowX: "auto", borderRadius: "10px", border: "1px solid #E2E8F0" }}>
          <table style={{ width: "100%", minWidth: "960px", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
            <thead>
              <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                <th style={{ padding: "0.85rem 1.25rem" }}>Patient / Customer</th>
                <th style={{ padding: "0.85rem 1rem" }}>Mobile Number</th>
                <th style={{ padding: "0.85rem 1rem" }}>Tier & Classification</th>
                <th style={{ padding: "0.85rem 1rem" }}>Credit Limit</th>
                <th style={{ padding: "0.85rem 1rem" }}>Current Outstanding Debt</th>
                <th style={{ padding: "0.85rem 1rem" }}>Refill Notifications</th>
                <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {customers.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "3rem 1rem", color: "#64748B" }}>
                    {searchQuery
                      ? `No customer matched "${searchQuery}". Try a different keyword.`
                      : "No customer records registered yet. Click + Add Customer or AI Scan Slip / ID to add patients."}
                  </td>
                </tr>
              ) : (
                customers.map((cust) => {
                const debt = Number(cust.currentBalance || 0);
                return (
                  <tr key={cust.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.9rem 1.25rem", fontWeight: 700, color: "#0F172A" }}>
                      {cust.name}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", fontFamily: "var(--font-mono)", color: "#0F766E", fontWeight: 600 }}>
                      {cust.mobile}
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      <span
                        style={{
                          padding: "0.2rem 0.6rem",
                          borderRadius: "9999px",
                          fontSize: "0.75rem",
                          fontWeight: 700,
                          backgroundColor: cust.isPermanent ? "#ECFDF5" : "#F1F5F9",
                          color: cust.isPermanent ? "#065F46" : "#475569",
                          border: cust.isPermanent ? "1px solid rgba(16, 185, 129, 0.3)" : "1px solid #E2E8F0",
                        }}
                      >
                        {cust.isPermanent ? "Permanent Credit" : cust.customerType}
                      </span>
                    </td>
                    <td style={{ padding: "0.9rem 1rem", color: "#475569" }}>
                      {formatINR(cust.creditLimit)}
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      {debt > 0 ? (
                        <span style={{ color: "#DC2626", fontWeight: 700 }}>
                          {formatINR(debt)} (Unpaid)
                        </span>
                      ) : (
                        <span style={{ color: "#059669", fontWeight: 600 }}>₹0.00 (Clear)</span>
                      )}
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      {cust.notificationOptOut ? (
                        <span style={{ color: "#94A3B8", fontSize: "0.75rem" }}>Opted Out</span>
                      ) : (
                        <span style={{ color: "#059669", fontSize: "0.78rem", fontWeight: 600 }}>
                          ✓ Enabled (WhatsApp/SMS)
                        </span>
                      )}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => handleViewHistory(cust)}
                          title="View Medicine Purchase History"
                          style={{
                            padding: "4px 8px",
                            backgroundColor: "#F0FDFA",
                            border: "1px solid #CCFBF1",
                            color: "#0F766E",
                            borderRadius: "4px",
                            fontSize: "0.72rem",
                            fontWeight: 600,
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: "3px",
                          }}
                        >
                          <History size={13} /> History
                        </button>
                        <button
                          onClick={() => {
                            setEditingCustomer(cust);
                            setEditFormData({
                              name: cust.name,
                              mobile: cust.mobile,
                              email: cust.email || "",
                              customerType: cust.customerType,
                              isPermanent: cust.isPermanent,
                              creditLimit: Number(cust.creditLimit || 0),
                              notificationOptOut: cust.notificationOptOut,
                            });
                          }}
                          title="Edit Customer"
                          style={{
                            padding: "4px 8px",
                            backgroundColor: "#EFF6FF",
                            border: "1px solid #DBEAFE",
                            color: "#1D4ED8",
                            borderRadius: "4px",
                            fontSize: "0.72rem",
                            fontWeight: 600,
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: "3px",
                          }}
                        >
                          <Edit2 size={13} /> Edit
                        </button>
                        <button
                          onClick={() => handleDeleteCustomer(cust)}
                          title="Delete Customer"
                          style={{
                            padding: "4px 8px",
                            backgroundColor: "#FEF2F2",
                            border: "1px solid #FEE2E2",
                            color: "#DC2626",
                            borderRadius: "4px",
                            fontSize: "0.72rem",
                            fontWeight: 600,
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: "3px",
                          }}
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              }))}
            </tbody>
          </table>
        </div>
      )}

      {/* Add Customer Modal */}
      {isCreateOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 999,
            backgroundColor: "rgba(13, 24, 34, 0.6)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: "1rem",
          }}
          className="animate-scale-in"
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "14px",
              width: "100%",
              maxWidth: "480px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Register Customer Account
              </h3>
              <button onClick={() => setIsCreateOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} style={{ padding: "1.5rem" }}>
              {/* OCR Assistant Quick Bar */}
              <div
                style={{
                  backgroundColor: "#F0FDF4",
                  border: "1px solid #BBF7D0",
                  borderRadius: "8px",
                  padding: "0.6rem 0.85rem",
                  marginBottom: "1.1rem",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                  <Sparkles size={16} color="#16A34A" />
                  <span style={{ fontSize: "0.8rem", color: "#166534", fontWeight: 600 }}>
                    Auto-fill with AI Scanner?
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setIsOcrOpen(true)}
                  style={{
                    backgroundColor: "#FFFFFF",
                    border: "1px solid #86EFAC",
                    borderRadius: "6px",
                    padding: "0.25rem 0.65rem",
                    fontSize: "0.75rem",
                    fontWeight: 700,
                    color: "#15803D",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: "0.3rem",
                  }}
                >
                  <Camera size={13} />
                  <span>Scan Prescription / ID</span>
                </button>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Customer / Patient Full Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Patient Full Name"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Mobile Number (for POS Lookup & WhatsApp) *
                </label>
                <input
                  type="text"
                  required
                  value={formData.mobile}
                  onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
                  placeholder="e.g. +91 98000 00000"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer", marginBottom: "0.75rem" }}>
                  <input
                    type="checkbox"
                    checked={formData.isPermanent}
                    onChange={(e) => setFormData({ ...formData, isPermanent: e.target.checked, customerType: e.target.checked ? "PERMANENT" : "REGULAR" })}
                  />
                  <span><strong>Permanent Customer</strong> (Allow Credit Billing & Debt)</span>
                </label>

                {formData.isPermanent && (
                  <div>
                    <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                      Credit Limit (₹)
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={formData.creditLimit}
                      onChange={(e) => setFormData({ ...formData, creditLimit: Number(e.target.value) })}
                      placeholder="e.g. 5000"
                      style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                    />
                  </div>
                )}
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Save Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Customer Modal */}
      {editingCustomer && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
            padding: "1rem",
          }}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "12px",
              width: "100%",
              maxWidth: "500px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #CBD5E1",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1rem 1.25rem", borderBottom: "1px solid #E2E8F0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, margin: 0 }}>Edit Customer Profile</h3>
              <button onClick={() => setEditingCustomer(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748B" }}>
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleEditSubmit} style={{ padding: "1.25rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Customer / Patient Full Name *
                </label>
                <input
                  type="text"
                  required
                  value={editFormData.name}
                  onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Mobile Number *
                </label>
                <input
                  type="text"
                  required
                  value={editFormData.mobile}
                  onChange={(e) => setEditFormData({ ...editFormData, mobile: e.target.value })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Email Address (Optional)
                </label>
                <input
                  type="email"
                  value={editFormData.email}
                  onChange={(e) => setEditFormData({ ...editFormData, email: e.target.value })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer", marginBottom: "0.75rem" }}>
                  <input
                    type="checkbox"
                    checked={editFormData.isPermanent}
                    onChange={(e) => setEditFormData({ ...editFormData, isPermanent: e.target.checked, customerType: e.target.checked ? "PERMANENT" : "REGULAR" })}
                  />
                  <span><strong>Permanent Customer</strong> (Allow Credit Billing)</span>
                </label>

                {editFormData.isPermanent && (
                  <div style={{ marginBottom: "0.75rem" }}>
                    <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                      Credit Limit (₹)
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={editFormData.creditLimit}
                      onChange={(e) => setEditFormData({ ...editFormData, creditLimit: Number(e.target.value) })}
                      style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                    />
                  </div>
                )}

                <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={editFormData.notificationOptOut}
                    onChange={(e) => setEditFormData({ ...editFormData, notificationOptOut: e.target.checked })}
                  />
                  <span>Opt-out from Refill SMS / WhatsApp Alerts</span>
                </label>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setEditingCustomer(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Update Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Customer Purchase History Modal */}
      {historyCustomer && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
            padding: "1rem",
          }}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "12px",
              width: "100%",
              maxWidth: "750px",
              maxHeight: "85vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #CBD5E1",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem", borderBottom: "1px solid #E2E8F0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <h3 style={{ fontSize: "1.1rem", fontWeight: 700, margin: 0, color: "#0F172A" }}>
                  Medicine Purchase History
                </h3>
                <p style={{ fontSize: "0.8rem", color: "#64748B", margin: "2px 0 0" }}>
                  Patient: <strong>{historyCustomer.name}</strong> • Phone: <strong>{historyCustomer.mobile}</strong>
                </p>
              </div>
              <button onClick={() => setHistoryCustomer(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748B" }}>
                <X size={20} />
              </button>
            </div>

            <div style={{ flex: 1, overflowY: "auto", padding: "1.25rem" }}>
              {isHistoryLoading ? (
                <TableSkeleton rows={4} cols={5} />
              ) : customerHistory.length === 0 ? (
                <div style={{ textAlign: "center", padding: "2.5rem 1rem", color: "#64748B" }}>
                  <Receipt size={36} color="#94A3B8" style={{ margin: "0 auto 0.75rem" }} />
                  <h4 style={{ margin: "0 0 4px", color: "#1E293B", fontWeight: 600 }}>No Purchase Invoices Found</h4>
                  <p style={{ margin: 0, fontSize: "0.8rem" }}>This patient has not completed any counter sale transactions yet.</p>
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                  {customerHistory.map((inv) => (
                    <div key={inv.id} style={{ border: "1px solid #E2E8F0", borderRadius: "8px", padding: "1rem", backgroundColor: "#F8FAFC" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
                        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                          <span style={{ fontWeight: 700, color: "#0F172A", fontSize: "0.9rem" }}>{inv.invoiceNumber}</span>
                          <span style={{ fontSize: "0.72rem", padding: "2px 6px", borderRadius: "4px", backgroundColor: "#ECFDF5", color: "#065F46", fontWeight: 700 }}>
                            {inv.paymentStatus || "PAID"}
                          </span>
                        </div>
                        <span style={{ fontSize: "0.78rem", color: "#64748B" }}>
                          {inv.invoiceDate ? new Date(inv.invoiceDate).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" }) : ""}
                        </span>
                      </div>

                      {inv.doctorName && (
                        <div style={{ fontSize: "0.75rem", color: "#475569", marginBottom: "0.5rem" }}>
                          Prescribing Doctor: <strong>{inv.doctorName}</strong> {inv.doctorRegNo ? `(${inv.doctorRegNo})` : ""}
                        </div>
                      )}

                      <table style={{ width: "100%", fontSize: "0.78rem", borderCollapse: "collapse", marginTop: "0.4rem" }}>
                        <thead>
                          <tr style={{ borderBottom: "1px solid #CBD5E1", color: "#64748B", textAlign: "left" }}>
                            <th style={{ padding: "4px 0" }}>Medicine</th>
                            <th style={{ padding: "4px 0" }}>Batch</th>
                            <th style={{ padding: "4px 0", textAlign: "right" }}>Qty</th>
                            <th style={{ padding: "4px 0", textAlign: "right" }}>Rate</th>
                            <th style={{ padding: "4px 0", textAlign: "right" }}>Amount</th>
                          </tr>
                        </thead>
                        <tbody>
                          {(inv.items || []).map((it: any) => (
                            <tr key={it.id} style={{ borderBottom: "1px solid #E2E8F0" }}>
                              <td style={{ padding: "4px 0", fontWeight: 600, color: "#0F172A" }}>{it.medicine?.name || "Medicine"}</td>
                              <td style={{ padding: "4px 0", color: "#64748B" }}>{it.batchNumber || it.batch?.batchNumber || "-"}</td>
                              <td style={{ padding: "4px 0", textAlign: "right" }}>{it.quantity}</td>
                              <td style={{ padding: "4px 0", textAlign: "right" }}>{formatINR(it.unitPrice)}</td>
                              <td style={{ padding: "4px 0", textAlign: "right", fontWeight: 600 }}>{formatINR(it.totalAmount)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>

                      <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "0.5rem", fontWeight: 700, fontSize: "0.85rem", color: "#0F766E" }}>
                        Total Billed: {formatINR(inv.totalAmount)}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Action Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        isLoading={isSubmitting}
        onConfirm={confirmModal.action}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />

      {/* OCR Scanner Modal */}
      <OcrScanModal
        isOpen={isOcrOpen}
        onClose={() => setIsOcrOpen(false)}
        documentType="CUSTOMER"
        title="Scan Customer Prescription / ID"
        subtitle="Upload or snap a photo of patient card, doctor prescription header, or clinic receipt to auto-fill customer profile."
        onApply={(data) => {
          setFormData((prev) => ({
            ...prev,
            name: data.fields.name || prev.name,
            mobile: data.fields.mobile || prev.mobile,
            email: data.fields.email || prev.email,
            customerType: data.fields.customerType || prev.customerType,
            isPermanent: data.fields.isPermanent ?? prev.isPermanent,
          }));
          setIsCreateOpen(true);
        }}
      />
    </div>
  );
};
