import React, { useState, useEffect } from "react";
import {
  FileSpreadsheet,
  Search,
  Filter,
  ArrowUpRight,
  ArrowDownLeft,
  RefreshCw,
  AlertCircle,
  Calendar,
  Layers,
  Clock,
  User,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";

interface StockTransaction {
  id: string;
  transactionType: "PURCHASE" | "SALE" | "RETURN_IN" | "RETURN_OUT" | "ADJUSTMENT_ADD" | "ADJUSTMENT_SUB" | "DAMAGE" | "OPENING";
  quantityDelta: number;
  balanceAfter: number;
  referenceType?: string;
  notes?: string;
  createdAt: string;
  medicine?: {
    name: string;
    genericName?: string;
  };
  batch?: {
    batchNumber: string;
    expiryDate: string;
  };
  performedBy?: {
    firstName: string;
    lastName: string;
    email: string;
  };
}

export const StockLedgerPage: React.FC = () => {
  const [transactions, setTransactions] = useState<StockTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [typeFilter, setTypeFilter] = useState("ALL");
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);

  useEffect(() => {
    loadLedger();
  }, [typeFilter, page]);

  const loadLedger = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const params: Record<string, any> = { page, limit: 50 };
      if (typeFilter !== "ALL") params.transactionType = typeFilter;

      const res = await apiRequest("/inventory/ledger", { params });
      if (res.success && res.data) {
        const items = res.data.items || [];
        setTransactions(items);
        setTotalCount(res.data.pagination?.total || items.length);
      } else {
        setErrorMessage(res.message || "Failed to load stock audit ledger.");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Network error loading ledger.");
    } finally {
      setIsLoading(false);
    }
  };

  const getTransactionBadge = (type: string, delta: number) => {
    const isPositive = delta > 0;
    let label = type.replace("_", " ");
    let color = isPositive ? "#059669" : "#DC2626";
    let bg = isPositive ? "#ECFDF5" : "#FEF2F2";

    if (type === "PURCHASE") label = "Inward Bill";
    if (type === "SALE") label = "POS Bill Sale";
    if (type === "RETURN_IN") label = "Customer Return";
    if (type === "RETURN_OUT") label = "Supplier Debit Note";
    if (type === "DAMAGE") label = "Breakage / Damage";

    return (
      <span
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: "4px",
          backgroundColor: bg,
          color: color,
          padding: "2px 8px",
          borderRadius: "12px",
          fontSize: "0.72rem",
          fontWeight: 700,
        }}
      >
        {isPositive ? <ArrowDownLeft size={12} /> : <ArrowUpRight size={12} />}
        {label}
      </span>
    );
  };

  const filtered = transactions.filter((tx) => {
    const medName = tx.medicine?.name?.toLowerCase() || "";
    const bNum = tx.batch?.batchNumber?.toLowerCase() || "";
    const query = searchTerm.toLowerCase();
    return medName.includes(query) || bNum.includes(query);
  });

  return (
    <div style={{ padding: "1.5rem", maxWidth: "1200px", margin: "0 auto" }}>
      {/* Top Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem" }}>
        <div>
          <h1 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "0.5rem" }}>
            <FileSpreadsheet size={22} color="#0F766E" />
            Stock Movement Audit Ledger
          </h1>
          <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "#64748B" }}>
            Immutable chronological audit log of every medicine in/out transaction, counter sale deduction, and batch adjustment.
          </p>
        </div>

        <button
          onClick={loadLedger}
          style={{
            backgroundColor: "#FFFFFF",
            border: "1px solid #CBD5E1",
            borderRadius: "6px",
            padding: "0.45rem 0.85rem",
            fontSize: "0.82rem",
            fontWeight: 600,
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
            color: "#475569",
          }}
        >
          <RefreshCw size={14} className={isLoading ? "animate-spin" : ""} /> Refresh
        </button>
      </div>

      {errorMessage && (
        <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
          <AlertCircle size={18} />
          {errorMessage}
        </div>
      )}

      {/* Filter Bar */}
      <div style={{ display: "flex", gap: "1rem", alignItems: "center", marginBottom: "1rem", backgroundColor: "#FFFFFF", padding: "0.75rem", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
        <div style={{ display: "flex", alignItems: "center", backgroundColor: "#F8FAF9", border: "1px solid #CBD5E1", borderRadius: "6px", padding: "0.35rem 0.65rem", flex: 1 }}>
          <Search size={15} color="#94A3B8" style={{ marginRight: "0.5rem" }} />
          <input
            type="text"
            placeholder="Search by drug name or batch number..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ border: "none", background: "none", outline: "none", fontSize: "0.82rem", width: "100%" }}
          />
        </div>

        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          style={{ padding: "0.4rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}
        >
          <option value="ALL">All Transaction Types</option>
          <option value="PURCHASE">Inward Purchases</option>
          <option value="SALE">POS Sales Counter</option>
          <option value="RETURN_IN">Customer Sales Returns</option>
          <option value="RETURN_OUT">Supplier Debit Notes</option>
          <option value="ADJUSTMENT_ADD">Stock Added (+)</option>
          <option value="ADJUSTMENT_SUB">Stock Deducted (-)</option>
          <option value="DAMAGE">Damaged / Expired</option>
        </select>
      </div>

      {/* Ledger Table */}
      <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", border: "1px solid #E2E8F0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
          <thead>
            <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Timestamp</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Medicine & Molecule</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Batch Number</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Transaction Type</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700, textAlign: "right" }}>Quantity Changed</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700, textAlign: "right" }}>Closing Balance</th>
              <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Operator / Cashier</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td colSpan={7} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                  Loading stock transactions...
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                  No stock transactions found matching current filters.
                </td>
              </tr>
            ) : (
              filtered.map((tx) => (
                <tr key={tx.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                  <td style={{ padding: "0.75rem 1rem", color: "#64748B", whiteSpace: "nowrap" }}>
                    {new Date(tx.createdAt).toLocaleString()}
                  </td>
                  <td style={{ padding: "0.75rem 1rem" }}>
                    <div style={{ fontWeight: 700, color: "#0F172A" }}>{tx.medicine?.name || "Medicine"}</div>
                    {tx.medicine?.genericName && (
                      <div style={{ fontSize: "0.72rem", color: "#64748B" }}>{tx.medicine.genericName}</div>
                    )}
                  </td>
                  <td style={{ padding: "0.75rem 1rem" }}>
                    <span style={{ backgroundColor: "#F1F5F9", padding: "2px 6px", borderRadius: "4px", fontWeight: 600 }}>
                      {tx.batch?.batchNumber || "—"}
                    </span>
                  </td>
                  <td style={{ padding: "0.75rem 1rem" }}>
                    {getTransactionBadge(tx.transactionType, tx.quantityDelta)}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", textAlign: "right", fontWeight: 800, color: tx.quantityDelta > 0 ? "#059669" : "#DC2626" }}>
                    {tx.quantityDelta > 0 ? `+${tx.quantityDelta}` : tx.quantityDelta}
                  </td>
                  <td style={{ padding: "0.75rem 1rem", textAlign: "right", fontWeight: 700, color: "#0F172A" }}>
                    {tx.balanceAfter} units
                  </td>
                  <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>
                    {tx.performedBy?.firstName ? `${tx.performedBy.firstName} ${tx.performedBy.lastName || ""}` : "System Auto"}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
