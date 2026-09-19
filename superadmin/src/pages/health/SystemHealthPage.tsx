import React, { useState, useEffect } from "react";
import { Activity, Database, Server, Cpu, Clock, RefreshCw, CheckCircle2, AlertTriangle, ShieldCheck } from "lucide-react";
import { apiRequest } from "../../api/client.js";

export const SystemHealthPage: React.FC = () => {
  const [health, setHealth] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchHealth = async () => {
    setIsLoading(true);
    const res = await apiRequest("/superadmin/system-health");
    if (res.success && res.data) {
      setHealth(res.data);
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchHealth();
    let interval: any = null;
    if (autoRefresh) {
      interval = setInterval(fetchHealth, 10000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh]);

  const formatBytes = (bytes: number) => {
    if (!bytes) return "0 MB";
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatUptime = (seconds: number) => {
    if (!seconds) return "0s";
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor((seconds % (3600 * 24)) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    return `${d > 0 ? `${d}d ` : ""}${h > 0 ? `${h}h ` : ""}${m}m ${s}s`;
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "1rem" }}>
        <div>
          <h2 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#F8FAFC" }}>
            Live Infrastructure & Service Diagnostics
          </h2>
          <p style={{ fontSize: "0.8rem", color: "#64748B" }}>
            Active probes for PostgreSQL connection pool, Redis cache layer, and process memory
          </p>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "0.78rem", color: "#94A3B8", cursor: "pointer" }}>
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
            />
            Auto-refresh (10s)
          </label>

          <button onClick={fetchHealth} className="btn btn-secondary" disabled={isLoading}>
            <RefreshCw size={15} className={isLoading ? "animate-spin" : ""} style={{ animation: isLoading ? "spin 1s linear infinite" : "none" }} />
            Ping Services
          </button>
        </div>
      </div>

      {/* Primary Health Banner */}
      <div
        className="card"
        style={{
          borderLeft: `4px solid ${health?.status === "HEALTHY" ? "#10B981" : "#F59E0B"}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: "1rem",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <div
            style={{
              width: "44px",
              height: "44px",
              borderRadius: "12px",
              backgroundColor: health?.status === "HEALTHY" ? "rgba(16, 185, 129, 0.15)" : "rgba(245, 158, 11, 0.15)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: health?.status === "HEALTHY" ? "#34D399" : "#FBBF24",
            }}
          >
            <CheckCircle2 size={24} />
          </div>
          <div>
            <div style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
              {health?.status === "HEALTHY" ? "All Platform Services Operational" : "Telemetry Degraded or Probing"}
            </div>
            <div style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
              Last probe response recorded at {health?.timestamp ? new Date(health.timestamp).toLocaleTimeString() : "—"}
            </div>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: "0.7rem", color: "#64748B", textTransform: "uppercase" }}>Process Uptime</div>
            <div style={{ fontSize: "0.95rem", fontWeight: 800, color: "#F8FAFC" }}>
              {formatUptime(health?.uptimeSeconds || 0)}
            </div>
          </div>
        </div>
      </div>

      {/* Services Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: "1.25rem" }}>
        {/* PostgreSQL Database */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <Database size={18} color="#818CF8" />
              <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC" }}>PostgreSQL 16 Engine</h3>
            </div>
            <span className={`badge ${health?.database?.status === "HEALTHY" ? "badge-active" : "badge-suspended"}`}>
              {health?.database?.status || "PROBING"}
            </span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem", fontSize: "0.82rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Query Ping Latency:</span>
              <strong style={{ color: "#34D399" }}>{health?.database?.latencyMs ?? "—"} ms</strong>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Database Provider:</span>
              <span>{health?.database?.provider || "PostgreSQL Multi-Tenant"}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Tenant Isolation:</span>
              <span style={{ color: "#818CF8" }}>Row-Level + Shop UUID Gating</span>
            </div>
          </div>
        </div>

        {/* Redis Cache */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <Server size={18} color="#06B6D4" />
              <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC" }}>Redis Isolated Cache</h3>
            </div>
            <span className={`badge ${health?.redis?.status === "HEALTHY" ? "badge-active" : "badge-suspended"}`}>
              {health?.redis?.status || "PROBING"}
            </span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem", fontSize: "0.82rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>PING Latency:</span>
              <strong style={{ color: "#34D399" }}>{health?.redis?.latencyMs ?? "—"} ms</strong>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Cache Prefix:</span>
              <span style={{ fontFamily: "monospace" }}>mcrm:</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Dedicated DB Index:</span>
              <span>DB 3</span>
            </div>
          </div>
        </div>

        {/* Host Node & CPU */}
        <div className="card">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <Cpu size={18} color="#F59E0B" />
              <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#F8FAFC" }}>Node & Host Telemetry</h3>
            </div>
            <span className="badge badge-trial">{health?.platform || "Linux"}</span>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem", fontSize: "0.82rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Node.js Runtime:</span>
              <span style={{ fontFamily: "monospace" }}>{health?.nodeVersion || "v20.x"}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Available CPU Cores:</span>
              <strong>{health?.cpus || 1} Cores</strong>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Process Heap Used:</span>
              <span>{formatBytes(health?.memory?.processHeapUsed)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#CBD5E1" }}>
              <span style={{ color: "#64748B" }}>Process RSS Memory:</span>
              <span>{formatBytes(health?.memory?.processRss)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
