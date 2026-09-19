import React, { useState, useEffect } from "react";
import {
  Building2,
  TrendingUp,
  Clock,
  Users,
  Receipt,
  Pill,
  CheckCircle2,
  AlertTriangle,
  ArrowUpRight,
  ExternalLink,
  ShieldCheck,
  RefreshCw,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";
import { SuperadminTab } from "../../components/layout/SuperadminSidebar.js";

export const OverviewPage: React.FC<{ onNavigate: (tab: SuperadminTab) => void }> = ({ onNavigate }) => {
  const [data, setData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  const fetchOverview = async () => {
    setIsLoading(true);
    const res = await apiRequest("/superadmin/overview");
    if (res.success && res.data) {
      setData(res.data);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchOverview();
  }, []);

  if (isLoading && !data) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "50vh", color: "#818CF8" }}>
        <RefreshCw size={28} className="animate-spin" style={{ animation: "spin 1s linear infinite" }} />
      </div>
    );
  }

  const m = data?.metrics || {};
  const plans = data?.planBreakdown || {};
  const recentShops = data?.recentShops || [];
  const auditLogs = data?.recentAuditLogs || [];

  const storeAppUrl = typeof window !== "undefined"
    ? `http://${window.location.hostname}:5096`
    : "http://localhost:5096";

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
      {/* KPI Metrics Cards Grid */}
      <div className="grid-metrics">
        {/* Metric 1: Total Pharmacies */}
        <div className="card card-hover" style={{ borderLeft: "4px solid #6366F1" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", textTransform: "uppercase" }}>
                Medical Stores
              </div>
              <div style={{ fontSize: "1.85rem", fontWeight: 900, color: "#F8FAFC", marginTop: "0.25rem" }}>
                {m.totalShops || 0}
              </div>
            </div>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "rgba(99, 102, 241, 0.15)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#818CF8",
              }}
            >
              <Building2 size={20} />
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "8px", marginTop: "0.75rem", fontSize: "0.75rem" }}>
            <span style={{ color: "#34D399", fontWeight: 700 }}>● {m.activeShops || 0} Active</span>
            <span style={{ color: "#64748B" }}>|</span>
            <span style={{ color: m.suspendedShops > 0 ? "#FB7185" : "#64748B" }}>
              {m.suspendedShops || 0} Suspended
            </span>
          </div>
        </div>

        {/* Metric 2: Estimated MRR */}
        <div className="card card-hover" style={{ borderLeft: "4px solid #10B981" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", textTransform: "uppercase" }}>
                Platform MRR (Est.)
              </div>
              <div style={{ fontSize: "1.85rem", fontWeight: 900, color: "#34D399", marginTop: "0.25rem" }}>
                ₹{(m.estimatedMRR || 0).toLocaleString("en-IN")}
              </div>
            </div>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "rgba(16, 185, 129, 0.15)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#34D399",
              }}
            >
              <TrendingUp size={20} />
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "0.75rem", fontSize: "0.75rem", color: "#94A3B8" }}>
            <span>{m.activeSubscriptions || 0} Paid Tenant Subscriptions</span>
          </div>
        </div>

        {/* Metric 3: Trials & Expirations */}
        <div className="card card-hover" style={{ borderLeft: "4px solid #06B6D4" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", textTransform: "uppercase" }}>
                Free Trials
              </div>
              <div style={{ fontSize: "1.85rem", fontWeight: 900, color: "#38BDF8", marginTop: "0.25rem" }}>
                {m.trialSubscriptions || 0}
              </div>
            </div>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "rgba(6, 182, 212, 0.15)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#38BDF8",
              }}
            >
              <Clock size={20} />
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "0.75rem", fontSize: "0.75rem", color: m.expiringTrials7Days > 0 ? "#FBBF24" : "#94A3B8" }}>
            <AlertTriangle size={13} />
            <span>{m.expiringTrials7Days || 0} Expiring in 7 Days</span>
          </div>
        </div>

        {/* Metric 4: Platform Users */}
        <div className="card card-hover" style={{ borderLeft: "4px solid #F59E0B" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", textTransform: "uppercase" }}>
                Registered Users
              </div>
              <div style={{ fontSize: "1.85rem", fontWeight: 900, color: "#FBBF24", marginTop: "0.25rem" }}>
                {m.totalUsers || 0}
              </div>
            </div>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "rgba(245, 158, 11, 0.15)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#FBBF24",
              }}
            >
              <Users size={20} />
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "0.75rem", fontSize: "0.75rem", color: "#94A3B8" }}>
            <span>Across all pharmacies & store branches</span>
          </div>
        </div>
      </div>

      {/* Secondary Metrics Row */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))", gap: "1.25rem" }}>
        {/* Global Sales Volume */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <Receipt size={18} color="#818CF8" />
              <h3 style={{ fontSize: "0.92rem", fontWeight: 700, color: "#F8FAFC" }}>Total Invoices & Gross Sales</h3>
            </div>
            <span className="badge badge-active">Live Counter</span>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#F8FAFC" }}>
            ₹{(m.totalSalesVolume || 0).toLocaleString("en-IN", { maximumFractionDigits: 2 })}
          </div>
          <div style={{ fontSize: "0.8rem", color: "#94A3B8", marginTop: "0.25rem" }}>
            Issued across {m.totalInvoices || 0} counter sales invoices platform-wide
          </div>
        </div>

        {/* Medicines Catalog */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <Pill size={18} color="#34D399" />
              <h3 style={{ fontSize: "0.92rem", fontWeight: 700, color: "#F8FAFC" }}>Cataloged Drug Formulations</h3>
            </div>
            <span className="badge badge-trial">FEFO Enabled</span>
          </div>
          <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#F8FAFC" }}>
            {m.totalMedicines || 0} Medicines
          </div>
          <div style={{ fontSize: "0.8rem", color: "#94A3B8", marginTop: "0.25rem" }}>
            With Schedule H/H1 tags, molecular mappings & GST slabs
          </div>
        </div>
      </div>

      {/* Plan Distribution & Recent Stores */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(400px, 1fr))", gap: "1.25rem" }}>
        {/* Plan Breakdown */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC" }}>
              Subscription Tier Distribution
            </h3>
            <button onClick={() => onNavigate("plans")} className="btn btn-secondary btn-sm">
              Manage Tiers →
            </button>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.85rem" }}>
            {[
              { code: "TRIAL", label: "Free Trial (14 Days)", color: "#06B6D4" },
              { code: "STARTER", label: "Silver Starter (₹599/mo)", color: "#10B981" },
              { code: "PRO", label: "Gold Professional (₹1,299/mo)", color: "#6366F1" },
              { code: "ENTERPRISE", label: "Platinum Enterprise (₹2,499/mo)", color: "#F59E0B" },
            ].map((tier) => {
              const count = plans[tier.code] || 0;
              const pct = m.totalShops > 0 ? Math.round((count / m.totalShops) * 100) : 0;
              return (
                <div key={tier.code}>
                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.8rem", marginBottom: "0.25rem" }}>
                    <span style={{ color: "#E2E8F0", fontWeight: 600 }}>{tier.label}</span>
                    <span style={{ color: "#94A3B8" }}>{count} stores ({pct}%)</span>
                  </div>
                  <div style={{ height: "6px", backgroundColor: "#0B0F17", borderRadius: "9999px", overflow: "hidden" }}>
                    <div
                      style={{
                        height: "100%",
                        width: `${pct}%`,
                        backgroundColor: tier.color,
                        borderRadius: "9999px",
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Quick Actions Panel */}
        <div className="card">
          <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC", marginBottom: "1rem" }}>
            Administrative Actions
          </h3>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem" }}>
            <button
              onClick={() => onNavigate("shops")}
              className="btn btn-secondary"
              style={{ justifyContent: "space-between", padding: "0.75rem 1rem" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <Building2 size={16} color="#818CF8" />
                <span>Search & Inspect Tenant Pharmacies</span>
              </div>
              <ArrowUpRight size={14} color="#64748B" />
            </button>

            <button
              onClick={() => onNavigate("plans")}
              className="btn btn-secondary"
              style={{ justifyContent: "space-between", padding: "0.75rem 1rem" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <TrendingUp size={16} color="#34D399" />
                <span>Configure SaaS Plan Pricing & Quotas</span>
              </div>
              <ArrowUpRight size={14} color="#64748B" />
            </button>

            <button
              onClick={() => onNavigate("health")}
              className="btn btn-secondary"
              style={{ justifyContent: "space-between", padding: "0.75rem 1rem" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <CheckCircle2 size={16} color="#38BDF8" />
                <span>Check Live Infrastructure Telemetry</span>
              </div>
              <ArrowUpRight size={14} color="#64748B" />
            </button>

            <a
              href={storeAppUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-primary"
              style={{ justifyContent: "space-between", padding: "0.75rem 1rem", textDecoration: "none" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <ExternalLink size={16} />
                <span>Open Tenant Store ERP Portal (Port 5096)</span>
              </div>
              <span>→</span>
            </a>
          </div>
        </div>
      </div>

      {/* Recent Onboarded Stores Table */}
      <div className="card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
          <div>
            <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC" }}>Recent Onboarded Medical Stores</h3>
            <p style={{ fontSize: "0.75rem", color: "#64748B" }}>Latest pharmacies initialized on the platform</p>
          </div>
          <button onClick={() => onNavigate("shops")} className="btn btn-secondary btn-sm">
            View All ({m.totalShops || 0}) →
          </button>
        </div>

        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Pharmacy Name</th>
                <th>Owner Contact</th>
                <th>Location</th>
                <th>Subscription</th>
                <th>Usage</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {recentShops.map((s: any) => (
                <tr key={s.id}>
                  <td>
                    <div style={{ fontWeight: 700, color: "#F8FAFC" }}>{s.name}</div>
                    <div style={{ fontSize: "0.7rem", color: "#64748B" }}>{s.slug} • DL: {s.drugLicenseNo || "N/A"}</div>
                  </td>
                  <td>
                    <div>{s.ownerName || "Administrator"}</div>
                    <div style={{ fontSize: "0.7rem", color: "#64748B" }}>{s.phone || s.email || "—"}</div>
                  </td>
                  <td>
                    <div>{s.city || "—"}</div>
                    <div style={{ fontSize: "0.7rem", color: "#64748B" }}>{s.state || ""}</div>
                  </td>
                  <td>
                    <span className={`badge ${s.subscription?.status === "ACTIVE" ? "badge-active" : "badge-trial"}`}>
                      {s.subscription?.plan?.name || s.subscription?.status || "TRIAL"}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
                      {s._count?.medicines || 0} meds • {s._count?.salesInvoices || 0} sales
                    </div>
                  </td>
                  <td>
                    <span className={`badge ${s.status === "ACTIVE" ? "badge-active" : "badge-suspended"}`}>
                      {s.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
