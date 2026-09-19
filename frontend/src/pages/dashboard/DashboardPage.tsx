import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR } from "../../utils/formatters.js";
import { CardSkeleton } from "../../components/common/LoadingSkeleton.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import {
  TrendingUp,
  Boxes,
  AlertTriangle,
  Clock,
  HeartPulse,
  Landmark,
  PlusCircle,
  Receipt,
  ShoppingCart,
  BookOpen,
  ShieldCheck,
} from "lucide-react";
import type { NavTab } from "../../components/layout/Sidebar.js";

interface DashboardStats {
  valuation?: {
    totalCostValue: number;
    totalRetailValue: number;
    estimatedGrossMarginPercentage: number;
    activeBatchCount: number;
  };
  daybook?: {
    cash: { closingBalance: number; totalIn: number; totalOut: number };
    bank: { closingBalance: number; totalIn: number; totalOut: number };
  };
  lowStockCount?: number;
  nearExpiryCount?: number;
  dueRefillsCount?: number;
}

export const DashboardPage: React.FC<{ onNavigate: (tab: NavTab) => void }> = ({ onNavigate }) => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fetchDashboardData = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const [valRes, dayRes, lowRes, nearRes, dueRes] = await Promise.all([
        apiRequest("/inventory/valuation"),
        apiRequest("/accounting/daybook"),
        apiRequest("/inventory/low-stock"),
        apiRequest("/inventory/near-expiry?days=90"),
        apiRequest("/crm/refills/due?days=7"),
      ]);

      setStats({
        valuation: valRes.success ? valRes.data : undefined,
        daybook: dayRes.success ? dayRes.data : undefined,
        lowStockCount: lowRes.success ? (Array.isArray(lowRes.data) ? lowRes.data.length : 0) : 0,
        nearExpiryCount: nearRes.success ? (Array.isArray(nearRes.data) ? nearRes.data.length : 0) : 0,
        dueRefillsCount: dueRes.success ? (Array.isArray(dueRes.data) ? dueRes.data.length : 0) : 0,
      });
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to load dashboard metrics");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  if (isLoading) {
    return (
      <div>
        <div style={{ marginBottom: "1.5rem" }}>
          <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: "#0F172A" }}>Live Pharmacy Overview</h3>
          <p style={{ fontSize: "0.82rem", color: "#64748B" }}>Fetching real-time inventory and financial telemetry...</p>
        </div>
        <CardSkeleton count={4} />
        <CardSkeleton count={3} />
      </div>
    );
  }

  if (errorMessage) {
    return <ErrorCard message={errorMessage} onRetry={fetchDashboardData} />;
  }

  const costValue = stats?.valuation?.totalCostValue || 0;
  const retailValue = stats?.valuation?.totalRetailValue || 0;
  const grossMargin = stats?.valuation?.estimatedGrossMarginPercentage || 0;
  const cashClosing = stats?.daybook?.cash?.closingBalance || 0;
  const bankClosing = stats?.daybook?.bank?.closingBalance || 0;

  return (
    <div className="animate-scale-in">
      {/* Action Banner */}
      <div
        style={{
          padding: "1.25rem 1.75rem",
          backgroundColor: "#0F766E",
          backgroundImage: "linear-gradient(135deg, #0F766E 0%, #059669 100%)",
          borderRadius: "14px",
          color: "#FFFFFF",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: "1rem",
          marginBottom: "1.75rem",
          boxShadow: "0 4px 15px rgba(15, 118, 110, 0.2)",
        }}
      >
        <div>
          <h3 style={{ fontSize: "1.2rem", fontWeight: 800, margin: 0 }}>
            Operational Pharmacy Counter & ERP
          </h3>
          <p style={{ fontSize: "0.85rem", opacity: 0.9, marginTop: "0.25rem" }}>
            Double-entry bookkeeping, FEFO inventory tracking, and chronic refill automation.
          </p>
        </div>

        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
          <button
            onClick={() => onNavigate("pos")}
            style={{
              padding: "0.6rem 1.25rem",
              backgroundColor: "#FFFFFF",
              color: "#0F766E",
              border: "none",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
              boxShadow: "0 2px 5px rgba(0,0,0,0.1)",
            }}
          >
            <Receipt size={16} />
            POS Counter Bill (F2)
          </button>
          <button
            onClick={() => onNavigate("purchases")}
            style={{
              padding: "0.6rem 1.25rem",
              backgroundColor: "rgba(255, 255, 255, 0.18)",
              backdropFilter: "blur(8px)",
              color: "#FFFFFF",
              border: "1px solid rgba(255, 255, 255, 0.3)",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 600,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
            }}
          >
            <ShoppingCart size={16} />
            Receive Stock
          </button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: "1.25rem",
          marginBottom: "1.75rem",
        }}
      >
        {/* Card 1: Stock Valuation */}
        <div className="glass-card" style={{ padding: "1.25rem 1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem" }}>
            <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "#64748B", letterSpacing: "0.04em" }}>
              TOTAL INVENTORY VALUATION
            </span>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "#ECFDF5", color: "#059669", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Boxes size={18} />
            </div>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#0F172A", marginBottom: "0.3rem" }}>
            {formatINR(costValue)}
          </div>
          <div style={{ fontSize: "0.78rem", color: "#059669", fontWeight: 600 }}>
            Retail Value: {formatINR(retailValue)} ({grossMargin.toFixed(1)}% margin)
          </div>
        </div>

        {/* Card 2: Cash in Drawer */}
        <div className="glass-card" style={{ padding: "1.25rem 1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem" }}>
            <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "#64748B", letterSpacing: "0.04em" }}>
              CASH IN DRAWER (DAYBOOK)
            </span>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "#F0FDFA", color: "#0F766E", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Landmark size={18} />
            </div>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#0F172A", marginBottom: "0.3rem" }}>
            {formatINR(cashClosing)}
          </div>
          <div style={{ fontSize: "0.78rem", color: "#0284C7", fontWeight: 600 }}>
            Bank Current Balance: {formatINR(bankClosing)}
          </div>
        </div>

        {/* Card 3: Due Refills */}
        <div className="glass-card" style={{ padding: "1.25rem 1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem" }}>
            <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "#64748B", letterSpacing: "0.04em" }}>
              REFILLS DUE (NEXT 7 DAYS)
            </span>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "rgba(245, 158, 11, 0.12)", color: "#D97706", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <HeartPulse size={18} />
            </div>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#0F172A", marginBottom: "0.3rem" }}>
            {stats?.dueRefillsCount || 0} Patients
          </div>
          <button
            onClick={() => onNavigate("crm")}
            style={{ background: "none", border: "none", fontSize: "0.78rem", color: "#059669", fontWeight: 700, cursor: "pointer", padding: 0 }}
          >
            Review & Dispatch WhatsApp Alerts →
          </button>
        </div>

        {/* Card 4: Near Expiry Alerts */}
        <div className="glass-card" style={{ padding: "1.25rem 1.5rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem" }}>
            <span style={{ fontSize: "0.78rem", fontWeight: 700, color: "#64748B", letterSpacing: "0.04em" }}>
              EXPIRY & LOW STOCK ALERTS
            </span>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "rgba(239, 68, 68, 0.1)", color: "#DC2626", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <AlertTriangle size={18} />
            </div>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#0F172A", marginBottom: "0.3rem" }}>
            {stats?.nearExpiryCount || 0} Batches
          </div>
          <div style={{ fontSize: "0.78rem", color: "#DC2626", fontWeight: 600 }}>
            {stats?.lowStockCount || 0} Medicines below reorder level
          </div>
        </div>
      </div>

      {/* Action Operations & Shortcuts Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: "1.5rem" }}>
        {/* Quick Access Card */}
        <div className="glass-card" style={{ padding: "1.5rem" }}>
          <h4 style={{ fontSize: "1rem", fontWeight: 700, color: "#0F172A", marginBottom: "1rem" }}>
            Quick Operations
          </h4>
          <div style={{ display: "flex", flexDirection: "column", gap: "0.65rem" }}>
            <button
              onClick={() => onNavigate("pos")}
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "0.85rem 1rem",
                borderRadius: "8px",
                border: "1px solid #E2E8F0",
                backgroundColor: "#F8FAF9",
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                <Receipt size={18} color="#059669" />
                <div>
                  <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#0F172A" }}>Counter Sales POS</div>
                  <div style={{ fontSize: "0.75rem", color: "#64748B" }}>Auto-FEFO batch prioritization & split payments</div>
                </div>
              </div>
              <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#059669" }}>Launch →</span>
            </button>

            <button
              onClick={() => onNavigate("purchases")}
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "0.85rem 1rem",
                borderRadius: "8px",
                border: "1px solid #E2E8F0",
                backgroundColor: "#F8FAF9",
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                <ShoppingCart size={18} color="#0284C7" />
                <div>
                  <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#0F172A" }}>Goods Receipt (Inward Bills)</div>
                  <div style={{ fontSize: "0.75rem", color: "#64748B" }}>Multi-item supplier invoice ingestion & batch creation</div>
                </div>
              </div>
              <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#0284C7" }}>Receive →</span>
            </button>

            <button
              onClick={() => onNavigate("accounting")}
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "0.85rem 1rem",
                borderRadius: "8px",
                border: "1px solid #E2E8F0",
                backgroundColor: "#F8FAF9",
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                <BookOpen size={18} color="#D97706" />
                <div>
                  <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#0F172A" }}>Double-Entry Accounting & Daybook</div>
                  <div style={{ fontSize: "0.75rem", color: "#64748B" }}>Store expenses, trial balance, and AR/AP aging</div>
                </div>
              </div>
              <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#D97706" }}>Audit →</span>
            </button>
          </div>
        </div>

        {/* Pharmacy Regulatory & Operational Safeguards Card */}
        <div className="glass-card" style={{ padding: "1.5rem" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "1rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <ShieldCheck size={20} color="#059669" />
              <h4 style={{ fontSize: "1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Store Compliance & Safety Safeguards
              </h4>
            </div>
            <span
              style={{
                fontSize: "0.75rem",
                fontWeight: 600,
                color: "#059669",
                backgroundColor: "#ECFDF5",
                padding: "0.2rem 0.6rem",
                borderRadius: "999px",
                border: "1px solid #A7F3D0",
              }}
            >
              Active & Protected
            </span>
          </div>
          <ul style={{ listStyle: "none", padding: 0, margin: 0, fontSize: "0.85rem", color: "#475569", lineHeight: 1.8 }}>
            <li style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem", marginBottom: "0.4rem" }}>
              <span style={{ color: "#059669", fontWeight: 700 }}>✓</span>
              <span><strong>FEFO Counter Dispatch:</strong> Earliest expiring medicine batch automatically prioritized to eliminate shelf write-offs.</span>
            </li>
            <li style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem", marginBottom: "0.4rem" }}>
              <span style={{ color: "#059669", fontWeight: 700 }}>✓</span>
              <span><strong>Multi-Counter Stock Protection:</strong> Real-time inventory safeguard prevents duplicate billing and negative stock during peak counter rush.</span>
            </li>
            <li style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem", marginBottom: "0.4rem" }}>
              <span style={{ color: "#059669", fontWeight: 700 }}>✓</span>
              <span><strong>GST & Double-Entry Financial Audit:</strong> Automatically balanced ledger with zero debit/credit discrepancy.</span>
            </li>
            <li style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem" }}>
              <span style={{ color: "#059669", fontWeight: 700 }}>✓</span>
              <span><strong>Schedule H / H1 Regulatory Compliance:</strong> Prescription mandatory verification safeguard active for clinical medicines.</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};
