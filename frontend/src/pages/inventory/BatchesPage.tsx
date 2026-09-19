import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR, formatDate, getExpiryStatus } from "../../utils/formatters.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { Boxes, Search, SlidersHorizontal, AlertTriangle, X, Plus, Camera, Sparkles } from "lucide-react";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface BatchItem {
  id: string;
  batchNumber: string;
  expiryDate: string;
  manufacturingDate?: string;
  mrp: number | string;
  purchaseRate: number | string;
  sellingPrice: number | string;
  currentQuantity: number;
  medicine: {
    id: string;
    name: string;
    genericName: string;
    dosageForm: string;
  };
}

interface MedicineDropdownItem {
  id: string;
  name: string;
  genericName: string;
  dosageForm: string;
}

export const BatchesPage: React.FC = () => {
  const [batches, setBatches] = useState<BatchItem[]>([]);
  const [medicines, setMedicines] = useState<MedicineDropdownItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Create Batch Modal State
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [createFormData, setCreateFormData] = useState({
    medicineId: "",
    batchNumber: "",
    manufacturingDate: "",
    expiryDate: "",
    mrp: 150,
    purchaseRate: 115,
    sellingPrice: 140,
    initialQuantity: 50,
    notes: "",
  });

  // Adjustment Modal State
  const [adjustingBatch, setAdjustingBatch] = useState<BatchItem | null>(null);
  const [adjustType, setAdjustType] = useState<"ADJUSTMENT_ADD" | "ADJUSTMENT_SUB" | "DAMAGE">("ADJUSTMENT_ADD");
  const [adjustQty, setAdjustQty] = useState<number>(1);
  const [adjustReason, setAdjustReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Confirmation Modal State
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  const fetchBatches = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const res = await apiRequest("/inventory/batches", {
      params: { search: searchQuery || undefined, limit: 50 },
    });

    if (res.success && res.data) {
      setBatches(Array.isArray(res.data) ? res.data : res.data.items || []);
    } else {
      setErrorMessage(res.message || "Failed to retrieve batches");
    }
    setIsLoading(false);
  };

  const fetchMedicines = async () => {
    const res = await apiRequest("/masters/medicines", { params: { limit: 100 } });
    if (res.success && res.data) {
      setMedicines(Array.isArray(res.data) ? res.data : res.data.items || []);
    }
  };

  useEffect(() => {
    fetchMedicines();
  }, []);

  useEffect(() => {
    fetchBatches();
  }, [searchQuery]);

  const handleCreateBatchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!createFormData.medicineId || !createFormData.batchNumber || !createFormData.expiryDate) {
      alert("Please specify Medicine, Batch Number, and Expiry Date");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: "Register New Inventory Batch",
      message: `Confirm adding batch "${createFormData.batchNumber}" with ${createFormData.initialQuantity} units (MRP: ₹${createFormData.mrp})?`,
      action: async () => {
        setIsSubmitting(true);
        const isoExpiry = new Date(createFormData.expiryDate).toISOString();
        const isoMfg = createFormData.manufacturingDate ? new Date(createFormData.manufacturingDate).toISOString() : null;

        const res = await apiRequest("/inventory/batches", {
          method: "POST",
          body: JSON.stringify({
            ...createFormData,
            expiryDate: isoExpiry,
            manufacturingDate: isoMfg,
          }),
        });
        setIsSubmitting(false);

        if (res.success) {
          setIsCreateOpen(false);
          setCreateFormData({
            medicineId: "",
            batchNumber: "",
            manufacturingDate: "",
            expiryDate: "",
            mrp: 150,
            purchaseRate: 115,
            sellingPrice: 140,
            initialQuantity: 50,
            notes: "",
          });
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchBatches();
        } else {
          alert(res.message || "Failed to create batch");
        }
      },
    });
  };

  const handleAdjustSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustingBatch || adjustQty <= 0) return;

    const actionTitle =
      adjustType === "DAMAGE"
        ? "Write-off Damaged Stock"
        : adjustType === "ADJUSTMENT_SUB"
        ? "Deduct Stock Adjustment"
        : "Add Stock Adjustment";

    setConfirmModal({
      isOpen: true,
      title: actionTitle,
      message: `Confirm ${adjustType} of ${adjustQty} units for ${adjustingBatch.medicine.name} (Batch: ${adjustingBatch.batchNumber})? Reason: "${adjustReason || "Stock count adjustment"}"`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/inventory/adjustments", {
          method: "POST",
          body: JSON.stringify({
            batchId: adjustingBatch.id,
            type: adjustType,
            quantity: Number(adjustQty),
            reason: adjustReason.trim() || "Manual stock count adjustment",
          }),
        });
        setIsSubmitting(false);

        if (res.success) {
          setAdjustingBatch(null);
          setAdjustQty(1);
          setAdjustReason("");
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchBatches();
        } else {
          alert(res.message || "Adjustment failed");
        }
      },
    });
  };

  const handleQuickWriteOff = (b: BatchItem) => {
    setConfirmModal({
      isOpen: true,
      title: "1-Click Write-Off Expired Batch",
      message: `Zero out all ${b.currentQuantity} expired units of ${b.medicine?.name} (Batch: ${b.batchNumber})? This will immediately record an inventory write-off.`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/inventory/adjustments", {
          method: "POST",
          body: JSON.stringify({
            batchId: b.id,
            type: "DAMAGE",
            quantity: Number(b.currentQuantity),
            reason: "Expired stock zeroed out via quick write-off",
          }),
        });
        setIsSubmitting(false);
        setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        if (res.success) {
          await fetchBatches();
        } else {
          alert(res.message || "Failed to write off expired batch");
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
        <div style={{ position: "relative", flex: "1 1 260px", maxWidth: "420px" }}>
          <div style={{ position: "absolute", left: "0.85rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
            <Search size={16} />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search medicine name or batch number..."
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

        <div style={{ display: "flex", alignItems: "center", gap: "0.85rem", flexWrap: "wrap" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", fontSize: "0.8rem", color: "#64748B", whiteSpace: "nowrap" }}>
            <span>FEFO:</span>
            <span style={{ display: "inline-flex", alignItems: "center", gap: "0.25rem", color: "#059669", fontWeight: 600 }}>● Active</span>
            <span style={{ display: "inline-flex", alignItems: "center", gap: "0.25rem", color: "#D97706", fontWeight: 600 }}>● &lt;90d</span>
            <span style={{ display: "inline-flex", alignItems: "center", gap: "0.25rem", color: "#DC2626", fontWeight: 600 }}>● Expired</span>
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
              <Camera size={16} />
              <span>AI Scan Batch</span>
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
              Register Batch
            </button>
          </div>
        </div>
      </div>

      {/* Main Table */}
      {isLoading ? (
        <div className="glass-card">
          <TableSkeleton rows={6} cols={7} />
        </div>
      ) : errorMessage ? (
        <ErrorCard message={errorMessage} onRetry={fetchBatches} />
      ) : (
        <div className="glass-card" style={{ overflowX: "auto", borderRadius: "10px", border: "1px solid #E2E8F0" }}>
          <table style={{ width: "100%", minWidth: "960px", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
            <thead>
              <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                <th style={{ padding: "0.85rem 1.25rem" }}>Medicine & Formulation</th>
                <th style={{ padding: "0.85rem 1rem" }}>Batch Number</th>
                <th style={{ padding: "0.85rem 1rem" }}>Expiry Date (FEFO)</th>
                <th style={{ padding: "0.85rem 1rem" }}>Purchase Rate</th>
                <th style={{ padding: "0.85rem 1rem" }}>MRP / Sale Price</th>
                <th style={{ padding: "0.85rem 1rem" }}>Available Stock</th>
                <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {batches.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "3rem 1rem", color: "#64748B" }}>
                    {searchQuery
                      ? `No batch matched "${searchQuery}". Try a different keyword.`
                      : "No inventory batches registered yet. Click + Register Batch or AI Scan Batch above to add inventory."}
                  </td>
                </tr>
              ) : (
                batches.map((b) => {
                const expiryInfo = getExpiryStatus(b.expiryDate);
                return (
                  <tr key={b.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.9rem 1.25rem" }}>
                      <div style={{ fontWeight: 700, color: "#0F172A" }}>{b.medicine?.name}</div>
                      <div style={{ fontSize: "0.75rem", color: "#64748B" }}>
                        {b.medicine?.genericName} • {b.medicine?.dosageForm}
                      </div>
                    </td>
                    <td style={{ padding: "0.9rem 1rem", fontFamily: "var(--font-mono)", fontWeight: 700, color: "#0F766E" }}>
                      {b.batchNumber}
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      <div style={{ fontWeight: 600, color: "#334155" }}>{formatDate(b.expiryDate)}</div>
                      <div
                        style={{
                          fontSize: "0.72rem",
                          fontWeight: 700,
                          color:
                            expiryInfo.status === "EXPIRED"
                              ? "#DC2626"
                              : expiryInfo.status === "NEAR_EXPIRY"
                              ? "#D97706"
                              : "#059669",
                        }}
                      >
                        ● {expiryInfo.label}
                      </div>
                    </td>
                    <td style={{ padding: "0.9rem 1rem", color: "#64748B" }}>
                      {formatINR(b.purchaseRate)}
                    </td>
                    <td style={{ padding: "0.9rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                      {formatINR(b.sellingPrice)}
                    </td>
                    <td style={{ padding: "0.9rem 1rem" }}>
                      <span
                        style={{
                          display: "inline-block",
                          padding: "0.2rem 0.6rem",
                          borderRadius: "6px",
                          fontWeight: 700,
                          fontSize: "0.82rem",
                          backgroundColor: b.currentQuantity <= 10 ? "rgba(239, 68, 68, 0.1)" : "#ECFDF5",
                          color: b.currentQuantity <= 10 ? "#DC2626" : "#065F46",
                        }}
                      >
                        {b.currentQuantity} units
                      </span>
                    </td>
                    <td style={{ padding: "0.9rem 1rem", textAlign: "right" }}>
                      {expiryInfo.status === "EXPIRED" && b.currentQuantity > 0 && (
                        <button
                          onClick={() => handleQuickWriteOff(b)}
                          style={{
                            padding: "0.35rem 0.75rem",
                            borderRadius: "6px",
                            border: "1px solid #FECACA",
                            backgroundColor: "#FEF2F2",
                            color: "#DC2626",
                            fontSize: "0.78rem",
                            fontWeight: 700,
                            cursor: "pointer",
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "0.35rem",
                            marginRight: "0.5rem",
                          }}
                          title="1-Click Zero Out Expired Stock"
                        >
                          <AlertTriangle size={14} />
                          Write-Off Expired
                        </button>
                      )}
                      <button
                        onClick={() => setAdjustingBatch(b)}
                        style={{
                          padding: "0.35rem 0.75rem",
                          borderRadius: "6px",
                          border: "1px solid #CBD5E1",
                          backgroundColor: "#FFFFFF",
                          color: "#334155",
                          fontSize: "0.78rem",
                          fontWeight: 600,
                          cursor: "pointer",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "0.35rem",
                        }}
                      >
                        <SlidersHorizontal size={14} />
                        Adjust Stock
                      </button>
                    </td>
                  </tr>
                );
              }))}
            </tbody>
          </table>
        </div>
      )}

      {/* Stock Adjustment Modal */}
      {adjustingBatch && (
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
              maxWidth: "460px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <div>
                <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                  Adjust Batch Stock
                </h3>
                <div style={{ fontSize: "0.78rem", color: "#64748B", marginTop: "2px" }}>
                  {adjustingBatch.medicine.name} (Batch {adjustingBatch.batchNumber})
                </div>
              </div>
              <button onClick={() => setAdjustingBatch(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleAdjustSubmit} style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Adjustment Type
                </label>
                <select
                  value={adjustType}
                  onChange={(e) => setAdjustType(e.target.value as any)}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", backgroundColor: "#FFFFFF" }}
                >
                  <option value="ADJUSTMENT_ADD">Inventory Add (+)</option>
                  <option value="ADJUSTMENT_SUB">Inventory Deduct (-)</option>
                  <option value="DAMAGE">Damaged / Expired Write-off (-)</option>
                </select>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Quantity (Units)
                </label>
                <input
                  type="number"
                  min="1"
                  required
                  value={adjustQty}
                  onChange={(e) => setAdjustQty(Math.max(1, Number(e.target.value)))}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Reason / Audit Note
                </label>
                <input
                  type="text"
                  value={adjustReason}
                  onChange={(e) => setAdjustReason(e.target.value)}
                  placeholder="e.g. Physical stock count reconciliation"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setAdjustingBatch(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{
                    padding: "0.55rem 1.25rem",
                    borderRadius: "6px",
                    border: "none",
                    backgroundColor: adjustType === "DAMAGE" ? "#DC2626" : "#059669",
                    color: "#FFFFFF",
                    fontSize: "0.85rem",
                    fontWeight: 700,
                    cursor: "pointer",
                  }}
                >
                  Confirm Adjustment
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Register New Batch Modal */}
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
              maxWidth: "520px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Register Batch / Stock In
              </h3>
              <button onClick={() => setIsCreateOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateBatchSubmit} style={{ padding: "1.5rem" }}>
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
                  <span>Scan Blister / Foil</span>
                </button>
              </div>

              {/* Medicine Select */}
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Select Medicine *
                </label>
                <select
                  required
                  value={createFormData.medicineId}
                  onChange={(e) => setCreateFormData({ ...createFormData, medicineId: e.target.value })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", backgroundColor: "#FFFFFF" }}
                >
                  <option value="">-- Choose Medicine from Catalog --</option>
                  {medicines.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name} ({m.genericName}) • {m.dosageForm}
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Batch Number (B.No) *
                  </label>
                  <input
                    type="text"
                    required
                    value={createFormData.batchNumber}
                    onChange={(e) => setCreateFormData({ ...createFormData, batchNumber: e.target.value.toUpperCase() })}
                    placeholder="e.g. DL2091"
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", fontFamily: "var(--font-mono)" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Expiry Date (EXP) *
                  </label>
                  <input
                    type="date"
                    required
                    value={createFormData.expiryDate}
                    onChange={(e) => setCreateFormData({ ...createFormData, expiryDate: e.target.value })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    MRP (₹) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={createFormData.mrp}
                    onChange={(e) => setCreateFormData({ ...createFormData, mrp: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Purchase Rate (₹)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={createFormData.purchaseRate}
                    onChange={(e) => setCreateFormData({ ...createFormData, purchaseRate: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Sale Price (₹) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={createFormData.sellingPrice}
                    onChange={(e) => setCreateFormData({ ...createFormData, sellingPrice: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Initial Stock Quantity (Units) *
                </label>
                <input
                  type="number"
                  required
                  min={1}
                  value={createFormData.initialQuantity}
                  onChange={(e) => setCreateFormData({ ...createFormData, initialQuantity: Number(e.target.value) })}
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
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
                  Register Batch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        variant={adjustType === "DAMAGE" ? "danger" : "primary"}
        isLoading={isSubmitting}
        onConfirm={confirmModal.action}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />

      {/* OCR Scanner Modal */}
      <OcrScanModal
        isOpen={isOcrOpen}
        onClose={() => setIsOcrOpen(false)}
        documentType="BATCH"
        title="Scan Batch Details from Blister / Strip"
        subtitle="Upload or snap a photo of the batch/expiry stamp on medicine strip back or bottle to auto-extract B.No, Expiry, and MRP."
        onApply={(data) => {
          const f = data?.fields || data || {};
          let dateStr = "";
          if (f.expiryDate && typeof f.expiryDate === "string") {
            dateStr = f.expiryDate.includes("T") ? f.expiryDate.split("T")[0] : f.expiryDate;
          }
          setCreateFormData((prev) => ({
            ...prev,
            batchNumber: f.batchNumber || prev.batchNumber || "BCH-001",
            manufacturingDate: f.manufacturingDate && typeof f.manufacturingDate === "string" ? f.manufacturingDate.split("T")[0] : prev.manufacturingDate,
            expiryDate: dateStr || prev.expiryDate || "2027-12-31",
            mrp: f.mrp ? Number(f.mrp) : prev.mrp,
            purchaseRate: f.purchaseRate ? Number(f.purchaseRate) : prev.purchaseRate,
            sellingPrice: f.sellingPrice ? Number(f.sellingPrice) : prev.sellingPrice,
            medicineId: f.matchedMedicineId || prev.medicineId,
            initialQuantity: f.initialQuantity ? Number(f.initialQuantity) : prev.initialQuantity,
          }));
          setIsCreateOpen(true);
        }}
      />
    </div>
  );
};
