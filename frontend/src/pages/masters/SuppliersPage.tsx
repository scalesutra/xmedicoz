import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR } from "../../utils/formatters.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { Truck, Search, Plus, X, ShieldAlert, Camera, Sparkles, Edit2, Trash2, CreditCard } from "lucide-react";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface SupplierItem {
  id: string;
  name: string;
  contactPerson?: string;
  mobile: string;
  email?: string;
  gstin?: string;
  dlNumber?: string;
  paymentTermsDays: number;
  outstandingBalance: number | string;
}

export const SuppliersPage: React.FC = () => {
  const [suppliers, setSuppliers] = useState<SupplierItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Modal State
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    contactPerson: "",
    mobile: "",
    gstin: "",
    dlNumber: "",
    paymentTermsDays: 30,
  });

  // Edit Supplier State
  const [editingSupplier, setEditingSupplier] = useState<SupplierItem | null>(null);
  const [editFormData, setEditFormData] = useState({
    name: "",
    contactPerson: "",
    mobile: "",
    email: "",
    gstin: "",
    dlNumber: "",
    paymentTermsDays: 30,
  });

  // Pay Supplier State
  const [payingSupplier, setPayingSupplier] = useState<SupplierItem | null>(null);
  const [payAmount, setPayAmount] = useState<number>(0);
  const [payMode, setPayMode] = useState<"CASH" | "UPI" | "BANK_TRANSFER" | "CHEQUE">("BANK_TRANSFER");

  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  const fetchSuppliers = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const res = await apiRequest("/masters/suppliers", {
      params: { search: searchQuery || undefined, limit: 50 },
    });

    if (res.success && res.data) {
      setSuppliers(Array.isArray(res.data) ? res.data : res.data.items || []);
    } else {
      setErrorMessage(res.message || "Failed to retrieve suppliers");
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchSuppliers();
  }, [searchQuery]);

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.mobile) {
      alert("Please provide vendor name and mobile number");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: "Register Supplier / Distributor",
      message: `Confirm registering distributor "${formData.name}" with credit period of ${formData.paymentTermsDays} days?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/masters/suppliers", {
          method: "POST",
          body: JSON.stringify(formData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setIsCreateOpen(false);
          setFormData({
            name: "",
            contactPerson: "",
            mobile: "",
            gstin: "",
            dlNumber: "",
            paymentTermsDays: 30,
          });
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchSuppliers();
        } else {
          alert(res.message || "Failed to create supplier");
        }
      },
    });
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingSupplier) return;

    setConfirmModal({
      isOpen: true,
      title: "Update Supplier Details",
      message: `Confirm updating distributor info for "${editFormData.name}"?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/suppliers/${editingSupplier.id}`, {
          method: "PATCH",
          body: JSON.stringify(editFormData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setEditingSupplier(null);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchSuppliers();
        } else {
          alert(res.message || "Failed to update supplier");
        }
      },
    });
  };

  const handleDeleteSupplier = (supp: SupplierItem) => {
    setConfirmModal({
      isOpen: true,
      title: "Delete Supplier Record",
      message: `Are you sure you want to deactivate distributor "${supp.name}"? Outstanding payable: ${formatINR(supp.outstandingBalance)}.`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/suppliers/${supp.id}`, {
          method: "DELETE",
        });
        setIsSubmitting(false);

        if (res.success) {
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchSuppliers();
        } else {
          alert(res.message || "Failed to delete supplier");
        }
      },
    });
  };

  const handlePaySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!payingSupplier || payAmount <= 0) return;

    setConfirmModal({
      isOpen: true,
      title: "Settle Supplier Outstanding Debt",
      message: `Confirm paying ${formatINR(payAmount)} to distributor "${payingSupplier.name}" via ${payMode}? This will record a formal supplier payment entry.`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/purchases/payments", {
          method: "POST",
          body: JSON.stringify({
            supplierId: payingSupplier.id,
            amount: Number(payAmount),
            paymentMode: payMode,
          }),
        });
        setIsSubmitting(false);

        if (res.success) {
          setPayingSupplier(null);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchSuppliers();
        } else {
          alert(res.message || "Failed to record payment");
        }
      },
    });
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
            placeholder="Search supplier name, GSTIN, DL number..."
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
            <span>AI Scan Bill / Card</span>
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
            Add Supplier
          </button>
        </div>
      </div>

      {/* Main Table */}
      {isLoading ? (
        <div className="glass-card">
          <TableSkeleton rows={5} cols={6} />
        </div>
      ) : errorMessage ? (
        <ErrorCard message={errorMessage} onRetry={fetchSuppliers} />
      ) : (
        <div className="glass-card" style={{ overflowX: "auto", borderRadius: "10px", border: "1px solid #E2E8F0" }}>
          <table style={{ width: "100%", minWidth: "960px", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
            <thead>
              <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                <th style={{ padding: "0.85rem 1.25rem" }}>Supplier / Distributor</th>
                <th style={{ padding: "0.85rem 1rem" }}>Contact Person</th>
                <th style={{ padding: "0.85rem 1rem" }}>Mobile</th>
                <th style={{ padding: "0.85rem 1rem" }}>GSTIN & DL</th>
                <th style={{ padding: "0.85rem 1rem" }}>Credit Period</th>
                <th style={{ padding: "0.85rem 1rem" }}>Outstanding Payable</th>
                <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {suppliers.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "3rem 1rem", color: "#64748B" }}>
                    {searchQuery
                      ? `No distributor matched "${searchQuery}". Try a different keyword.`
                      : "No suppliers registered yet. Click + Add Supplier or AI Scan Bill / Card to register distributors."}
                  </td>
                </tr>
              ) : (
                suppliers.map((supp) => {
                const payable = Number(supp.outstandingBalance || 0);
                return (
                  <tr key={supp.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.9rem 1.25rem", fontWeight: 700, color: "#0F172A" }}>
                      {supp.name}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", color: "#475569" }}>
                      {supp.contactPerson || "N/A"}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", fontFamily: "var(--font-mono)", color: "#0F766E", fontWeight: 600 }}>
                      {supp.mobile}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", fontSize: "0.78rem", color: "#64748B", fontFamily: "var(--font-mono)" }}>
                      <div>GST: {supp.gstin || "Unregistered"}</div>
                      <div>DL: {supp.dlNumber || "N/A"}</div>
                    </td>
                    <td style={{ padding: "0.9rem 1rem", color: "#0F172A", fontWeight: 600 }}>
                      {supp.paymentTermsDays} days
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      {payable > 0 ? (
                        <span style={{ color: "#DC2626", fontWeight: 700 }}>
                          {formatINR(payable)} (Due)
                        </span>
                      ) : (
                        <span style={{ color: "#059669", fontWeight: 600 }}>₹0.00 (Settled)</span>
                      )}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", textAlign: "right" }}>
                      <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                        <button
                          onClick={() => {
                            setPayingSupplier(supp);
                            setPayAmount(payable > 0 ? payable : 1000);
                            setPayMode("BANK_TRANSFER");
                          }}
                          title="Record Supplier Payment"
                          style={{
                            padding: "4px 8px",
                            backgroundColor: "#F0FDF4",
                            border: "1px solid #BBF7D0",
                            color: "#16A34A",
                            borderRadius: "4px",
                            fontSize: "0.72rem",
                            fontWeight: 600,
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: "3px",
                          }}
                        >
                          <CreditCard size={13} /> Pay
                        </button>
                        <button
                          onClick={() => {
                            setEditingSupplier(supp);
                            setEditFormData({
                              name: supp.name,
                              contactPerson: supp.contactPerson || "",
                              mobile: supp.mobile,
                              email: supp.email || "",
                              gstin: supp.gstin || "",
                              dlNumber: supp.dlNumber || "",
                              paymentTermsDays: supp.paymentTermsDays || 30,
                            });
                          }}
                          title="Edit Supplier"
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
                          onClick={() => handleDeleteSupplier(supp)}
                          title="Delete Supplier"
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

      {/* Add Supplier Modal */}
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
              maxWidth: "500px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Register Distributor / Supplier
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
                  <span>Scan Bill / Card</span>
                </button>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Distributor Company Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Apex Medico Distributors"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Contact Person
                  </label>
                  <input
                    type="text"
                    value={formData.contactPerson}
                    onChange={(e) => setFormData({ ...formData, contactPerson: e.target.value })}
                    placeholder="e.g. Sales Executive"
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Mobile Number *
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
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1.25rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    GSTIN
                  </label>
                  <input
                    type="text"
                    value={formData.gstin}
                    onChange={(e) => setFormData({ ...formData, gstin: e.target.value })}
                    placeholder="e.g. 24AAAAA0000A1Z5"
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Credit Terms (Days)
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={formData.paymentTermsDays}
                    onChange={(e) => setFormData({ ...formData, paymentTermsDays: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
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
                  Save Supplier
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Supplier Modal */}
      {editingSupplier && (
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
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, margin: 0 }}>Edit Supplier / Distributor</h3>
              <button onClick={() => setEditingSupplier(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748B" }}>
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleEditSubmit} style={{ padding: "1.25rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Distributor Name *
                </label>
                <input
                  type="text"
                  required
                  value={editFormData.name}
                  onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Contact Person
                  </label>
                  <input
                    type="text"
                    value={editFormData.contactPerson}
                    onChange={(e) => setEditFormData({ ...editFormData, contactPerson: e.target.value })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
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
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    GSTIN
                  </label>
                  <input
                    type="text"
                    value={editFormData.gstin}
                    onChange={(e) => setEditFormData({ ...editFormData, gstin: e.target.value })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Drug License (DL)
                  </label>
                  <input
                    type="text"
                    value={editFormData.dlNumber}
                    onChange={(e) => setEditFormData({ ...editFormData, dlNumber: e.target.value })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Payment Terms (Days)
                </label>
                <input
                  type="number"
                  min="0"
                  value={editFormData.paymentTermsDays}
                  onChange={(e) => setEditFormData({ ...editFormData, paymentTermsDays: Number(e.target.value) })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setEditingSupplier(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Update Supplier
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Pay Supplier Modal */}
      {payingSupplier && (
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
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "12px",
              width: "100%",
              maxWidth: "460px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #CBD5E1",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1rem 1.25rem", borderBottom: "1px solid #E2E8F0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, margin: 0, color: "#0F172A" }}>Pay Distributor</h3>
              <button onClick={() => setPayingSupplier(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748B" }}>
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handlePaySubmit} style={{ padding: "1.25rem" }}>
              <div style={{ padding: "0.75rem", backgroundColor: "#F8FAFC", borderRadius: "6px", marginBottom: "1rem", border: "1px solid #E2E8F0" }}>
                <div style={{ fontSize: "0.85rem", fontWeight: 700, color: "#0F172A" }}>{payingSupplier.name}</div>
                <div style={{ fontSize: "0.78rem", color: "#64748B", marginTop: "2px" }}>
                  Current Outstanding Due: <strong style={{ color: "#DC2626" }}>{formatINR(payingSupplier.outstandingBalance)}</strong>
                </div>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Payment Amount (₹) *
                </label>
                <input
                  type="number"
                  required
                  min="1"
                  step="any"
                  value={payAmount}
                  onChange={(e) => setPayAmount(Number(e.target.value))}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.95rem", fontWeight: 700, outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Payment Mode
                </label>
                <select
                  value={payMode}
                  onChange={(e) => setPayMode(e.target.value as any)}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", backgroundColor: "#FFFFFF" }}
                >
                  <option value="BANK_TRANSFER">Bank NEFT / RTGS</option>
                  <option value="UPI">UPI / QR Code</option>
                  <option value="CASH">Store Cash Drawer</option>
                  <option value="CHEQUE">Bank Cheque</option>
                </select>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setPayingSupplier(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#16A34A", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Record Payment
                </button>
              </div>
            </form>
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
        documentType="SUPPLIER"
        title="Scan Supplier Bill / Visiting Card"
        subtitle="Upload or snap a photo of vendor tax invoice header, business card, or GST certificate to auto-fill supplier master."
        onApply={(data) => {
          setFormData((prev) => ({
            ...prev,
            name: data.fields.name || prev.name,
            contactPerson: data.fields.contactPerson || prev.contactPerson,
            mobile: data.fields.mobile || prev.mobile,
            gstin: data.fields.gstin || prev.gstin,
            dlNumber: data.fields.dlNumber || prev.dlNumber,
            paymentTermsDays: data.fields.paymentTermsDays ? Number(data.fields.paymentTermsDays) : prev.paymentTermsDays,
          }));
          setIsCreateOpen(true);
        }}
      />
    </div>
  );
};
