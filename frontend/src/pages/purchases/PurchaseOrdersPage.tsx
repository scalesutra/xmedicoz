import React, { useState, useEffect } from "react";
import {
  FileText,
  Plus,
  Search,
  Calendar,
  Truck,
  CheckCircle2,
  AlertCircle,
  Clock,
  ChevronRight,
  ArrowRight,
  RefreshCw,
  X,
  Trash2,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";
import { formatINR } from "../../utils/formatters.js";

interface PurchaseOrder {
  id: string;
  orderNumber: string;
  supplierId: string;
  supplier?: {
    id: string;
    name: string;
    mobile?: string;
  };
  status: "DRAFT" | "PLACED" | "PARTIALLY_RECEIVED" | "COMPLETED" | "CANCELLED";
  orderDate: string;
  expectedDate?: string;
  totalAmount?: number;
  notes?: string;
  items?: Array<{
    id: string;
    medicineId: string;
    quantity: number;
    expectedRate: number;
    medicine?: {
      id: string;
      name: string;
      dosageForm?: string;
    };
  }>;
}

interface Supplier {
  id: string;
  name: string;
  mobile?: string;
}

interface Medicine {
  id: string;
  name: string;
  purchaseRate?: number;
  dosageForm?: string;
}

export const PurchaseOrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<PurchaseOrder[]>([]);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");

  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // New PO Modal
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [newOrder, setNewOrder] = useState({
    supplierId: "",
    expectedDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
    notes: "",
    items: [
      { medicineId: "", quantity: 10, expectedRate: 50 },
    ],
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const [ordersRes, suppRes, medsRes] = await Promise.all([
        apiRequest<PurchaseOrder[]>("/purchases/orders"),
        apiRequest<Supplier[]>("/masters/suppliers", { params: { limit: 100 } }),
        apiRequest<Medicine[]>("/masters/medicines", { params: { limit: 300 } }),
      ]);

      if (ordersRes.success && Array.isArray(ordersRes.data)) {
        setOrders(ordersRes.data);
      }
      const suppList = Array.isArray(suppRes?.data) ? suppRes.data : (suppRes?.data as any)?.items || [];
      const medList = Array.isArray(medsRes?.data) ? medsRes.data : (medsRes?.data as any)?.items || [];
      setSuppliers(suppList);
      setMedicines(medList);
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to load purchase orders.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newOrder.supplierId) {
      setErrorMessage("Please select a vendor / supplier.");
      return;
    }
    const validItems = newOrder.items.filter((i) => i.medicineId && i.quantity > 0);
    if (validItems.length === 0) {
      setErrorMessage("Please add at least one medicine item to the purchase order.");
      return;
    }

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const res = await apiRequest("/purchases/orders", {
        method: "POST",
        body: JSON.stringify({
          supplierId: newOrder.supplierId,
          expectedDate: newOrder.expectedDate || undefined,
          notes: newOrder.notes || undefined,
          items: validItems.map((it) => ({
            medicineId: it.medicineId,
            quantity: Number(it.quantity),
            expectedRate: Number(it.expectedRate),
          })),
        }),
      });

      if (res.success) {
        setSuccessMessage("Purchase Order created & registered successfully!");
        setIsCreateOpen(false);
        setNewOrder({
          supplierId: "",
          expectedDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
          notes: "",
          items: [{ medicineId: "", quantity: 10, expectedRate: 50 }],
        });
        loadData();
        setTimeout(() => setSuccessMessage(null), 4000);
      } else {
        setErrorMessage(res.message || "Failed to create purchase order.");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Network error while saving PO.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const addItemRow = () => {
    setNewOrder({
      ...newOrder,
      items: [...newOrder.items, { medicineId: "", quantity: 10, expectedRate: 50 }],
    });
  };

  const removeItemRow = (index: number) => {
    if (newOrder.items.length <= 1) return;
    setNewOrder({
      ...newOrder,
      items: newOrder.items.filter((_, i) => i !== index),
    });
  };

  const updateItemRow = (index: number, field: string, val: any) => {
    const updated = [...newOrder.items];
    const row = { ...updated[index], [field]: val };
    if (field === "medicineId") {
      const med = medicines.find((m) => m.id === val);
      if (med && med.purchaseRate) {
        row.expectedRate = med.purchaseRate;
      }
    }
    updated[index] = row;
    setNewOrder({ ...newOrder, items: updated });
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "COMPLETED":
        return <span style={{ backgroundColor: "#ECFDF5", color: "#065F46", padding: "2px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Received / Completed</span>;
      case "PARTIALLY_RECEIVED":
        return <span style={{ backgroundColor: "#FEF3C7", color: "#92400E", padding: "2px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Partially Inwarded</span>;
      case "PLACED":
        return <span style={{ backgroundColor: "#E0F2FE", color: "#0369A1", padding: "2px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Placed with Stockist</span>;
      case "CANCELLED":
        return <span style={{ backgroundColor: "#FEF2F2", color: "#991B1B", padding: "2px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Cancelled</span>;
      default:
        return <span style={{ backgroundColor: "#F1F5F9", color: "#475569", padding: "2px 8px", borderRadius: "12px", fontSize: "0.72rem", fontWeight: 700 }}>Draft</span>;
    }
  };

  const filteredOrders = orders.filter((o) => {
    const matchesSearch =
      o.orderNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.supplier?.name?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === "ALL" || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div style={{ padding: "1.5rem", maxWidth: "1200px", margin: "0 auto" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem" }}>
        <div>
          <h1 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "0.5rem" }}>
            <FileText size={22} color="#0F766E" />
            Stockist Purchase Orders (PO)
          </h1>
          <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "#64748B" }}>
            Draft, place, and track procurement orders sent to pharmaceutical distributors.
          </p>
        </div>

        <button
          onClick={() => setIsCreateOpen(true)}
          style={{
            backgroundColor: "#0F766E",
            color: "#FFFFFF",
            border: "none",
            borderRadius: "6px",
            padding: "0.55rem 1.2rem",
            fontSize: "0.85rem",
            fontWeight: 700,
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
            boxShadow: "0 2px 4px rgba(15, 118, 110, 0.25)",
          }}
        >
          <Plus size={16} /> New Purchase Order
        </button>
      </div>

      {successMessage && (
        <div style={{ backgroundColor: "#ECFDF5", border: "1px solid #A7F3D0", color: "#065F46", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
          <CheckCircle2 size={18} />
          {successMessage}
        </div>
      )}

      {errorMessage && (
        <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
          <AlertCircle size={18} />
          {errorMessage}
        </div>
      )}

      {/* Filters Bar */}
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "1rem", backgroundColor: "#FFFFFF", padding: "0.75rem", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
        <div style={{ display: "flex", alignItems: "center", backgroundColor: "#F8FAF9", border: "1px solid #CBD5E1", borderRadius: "6px", padding: "0.35rem 0.65rem", flex: 1 }}>
          <Search size={15} color="#94A3B8" style={{ marginRight: "0.5rem" }} />
          <input
            type="text"
            placeholder="Search by PO number or stockist..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ border: "none", background: "none", outline: "none", fontSize: "0.82rem", width: "100%" }}
          />
        </div>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{ padding: "0.4rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}
        >
          <option value="ALL">All Statuses</option>
          <option value="PLACED">Placed</option>
          <option value="PARTIALLY_RECEIVED">Partially Received</option>
          <option value="COMPLETED">Completed</option>
          <option value="DRAFT">Draft</option>
        </select>
      </div>

      {/* Orders Table */}
      <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", border: "1px solid #E2E8F0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
          <thead>
            <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>PO Number</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Stockist / Supplier</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Order Date</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Expected Date</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Status</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Items Count</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td colSpan={6} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                  Loading purchase orders...
                </td>
              </tr>
            ) : filteredOrders.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                  No purchase orders found. Click "+ New Purchase Order" to create one.
                </td>
              </tr>
            ) : (
              filteredOrders.map((po) => (
                <tr key={po.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                  <td style={{ padding: "0.75rem 1rem", fontWeight: 700, color: "#0F766E" }}>
                    {po.orderNumber}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                    {po.supplier?.name || "Stockist"}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>
                    {new Date(po.orderDate).toLocaleDateString()}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>
                    {po.expectedDate ? new Date(po.expectedDate).toLocaleDateString() : "—"}
                  </td>
                  <td style={{ padding: "0.75rem 1rem" }}>
                    {getStatusBadge(po.status)}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", color: "#0F172A", fontWeight: 600 }}>
                    {po.items?.length || 1} items
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* New Purchase Order Modal */}
      {isCreateOpen && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "700px", padding: "1.5rem", maxHeight: "90vh", overflowY: "auto", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ margin: 0, fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
                Create Stockist Purchase Order
              </h3>
              <button onClick={() => setIsCreateOpen(false)} style={{ border: "none", background: "none", color: "#94A3B8", cursor: "pointer" }}>
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleCreateOrder}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Vendor / Stockist *
                  </label>
                  <select
                    required
                    value={newOrder.supplierId}
                    onChange={(e) => setNewOrder({ ...newOrder, supplierId: e.target.value })}
                    style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="">Select Vendor...</option>
                    {suppliers.map((s) => (
                      <option key={s.id} value={s.id}>{s.name} {s.mobile ? `(${s.mobile})` : ""}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Expected Delivery Date
                  </label>
                  <input
                    type="date"
                    value={newOrder.expectedDate}
                    onChange={(e) => setNewOrder({ ...newOrder, expectedDate: e.target.value })}
                    style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                  />
                </div>
              </div>

              {/* Items Section */}
              <div style={{ marginBottom: "1rem" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
                  <label style={{ fontSize: "0.82rem", fontWeight: 700, color: "#0F172A" }}>
                    Ordered Medicines / Items
                  </label>
                  <button
                    type="button"
                    onClick={addItemRow}
                    style={{ backgroundColor: "#F0FDFA", border: "1px solid #0F766E", color: "#0F766E", borderRadius: "4px", padding: "2px 8px", fontSize: "0.75rem", fontWeight: 700, cursor: "pointer" }}
                  >
                    + Add Item
                  </button>
                </div>

                {newOrder.items.map((row, idx) => (
                  <div key={idx} style={{ display: "grid", gridTemplateColumns: "3fr 1fr 1fr 30px", gap: "0.5rem", alignItems: "center", marginBottom: "0.5rem" }}>
                    <select
                      required
                      value={row.medicineId}
                      onChange={(e) => updateItemRow(idx, "medicineId", e.target.value)}
                      style={{ padding: "0.45rem 0.6rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}
                    >
                      <option value="">Select Drug / SKU...</option>
                      {medicines.map((m) => (
                        <option key={m.id} value={m.id}>{m.name} ({m.dosageForm || "Strip"})</option>
                      ))}
                    </select>

                    <input
                      type="number"
                      required
                      min={1}
                      placeholder="Qty"
                      value={row.quantity}
                      onChange={(e) => updateItemRow(idx, "quantity", parseInt(e.target.value) || 1)}
                      style={{ padding: "0.45rem 0.6rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                    />

                    <input
                      type="number"
                      required
                      min={0.1}
                      step="0.01"
                      placeholder="Rate ₹"
                      value={row.expectedRate}
                      onChange={(e) => updateItemRow(idx, "expectedRate", parseFloat(e.target.value) || 0)}
                      style={{ padding: "0.45rem 0.6rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                    />

                    <button
                      type="button"
                      onClick={() => removeItemRow(idx)}
                      style={{ border: "none", background: "none", color: "#EF4444", cursor: "pointer", padding: "2px" }}
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                ))}
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Delivery Instructions / Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. Please deliver by tomorrow morning before 11 AM"
                  value={newOrder.notes}
                  onChange={(e) => setNewOrder({ ...newOrder, notes: e.target.value })}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.5rem" }}>
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  style={{ padding: "0.5rem 1rem", border: "1px solid #CBD5E1", borderRadius: "6px", background: "none", fontSize: "0.82rem", cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1.2rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}
                >
                  {isSubmitting ? "Creating PO..." : "Place Purchase Order"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
