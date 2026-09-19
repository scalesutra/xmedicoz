import React, { useState, useEffect } from "react";
import { Menu, Activity, ShieldCheck, RefreshCw, ExternalLink } from "lucide-react";
import { useAuth } from "../../context/AuthContext.js";
import { apiRequest } from "../../api/client.js";

interface TopbarProps {
  title: string;
  subtitle?: string;
  onToggleMobileSidebar: () => void;
  isMobile: boolean;
  onRefreshCurrentTab?: () => void;
}

export const SuperadminTopbar: React.FC<TopbarProps> = ({
  title,
  subtitle,
  onToggleMobileSidebar,
  isMobile,
  onRefreshCurrentTab,
}) => {
  const { user } = useAuth();
  const [systemHealthy, setSystemHealthy] = useState<boolean | null>(null);

  useEffect(() => {
    let isMounted = true;
    const checkHealth = async () => {
      const res = await apiRequest("/superadmin/system-health");
      if (isMounted) {
        setSystemHealthy(res.success && res.data?.status === "HEALTHY");
      }
    };
    checkHealth();
    const interval = setInterval(checkHealth, 30000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  const storeAppUrl = typeof window !== "undefined"
    ? `http://${window.location.hostname}:5096`
    : "http://localhost:5096";

  return (
    <header
      style={{
        height: "64px",
        backgroundColor: "#0B0F17",
        borderBottom: "1px solid #1E293B",
        padding: "0 1.25rem",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        position: "sticky",
        top: 0,
        zIndex: 5,
      }}
    >
      {/* Left: Mobile hamburger & Title */}
      <div style={{ display: "flex", alignItems: "center", gap: "1rem", minWidth: 0 }}>
        {isMobile && (
          <button
            onClick={onToggleMobileSidebar}
            style={{
              background: "#1E293B",
              border: "1px solid #334155",
              color: "#E2E8F0",
              borderRadius: "6px",
              padding: "6px",
              display: "flex",
              alignItems: "center",
              cursor: "pointer",
            }}
          >
            <Menu size={20} />
          </button>
        )}

        <div style={{ minWidth: 0 }}>
          <h1
            style={{
              fontSize: isMobile ? "1.05rem" : "1.2rem",
              fontWeight: 800,
              color: "#F8FAFC",
              letterSpacing: "-0.01em",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {title}
          </h1>
          {subtitle && !isMobile && (
            <div
              style={{
                fontSize: "0.75rem",
                color: "#64748B",
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}
            >
              {subtitle}
            </div>
          )}
        </div>
      </div>

      {/* Right: Live Telemetry & Actions */}
      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
        {/* Live System Health Badge */}
        {!isMobile && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "0.3rem 0.65rem",
              borderRadius: "9999px",
              backgroundColor: systemHealthy === true ? "rgba(16, 185, 129, 0.12)" : "rgba(245, 158, 11, 0.12)",
              border: `1px solid ${systemHealthy === true ? "rgba(16, 185, 129, 0.25)" : "rgba(245, 158, 11, 0.25)"}`,
              fontSize: "0.72rem",
              fontWeight: 600,
              color: systemHealthy === true ? "#34D399" : "#FBBF24",
            }}
          >
            <span
              style={{
                width: "7px",
                height: "7px",
                borderRadius: "50%",
                backgroundColor: systemHealthy === true ? "#10B981" : "#F59E0B",
                boxShadow: systemHealthy === true ? "0 0 8px #10B981" : "none",
              }}
            />
            {systemHealthy === true ? "Services Operational" : "Probing Telemetry..."}
          </div>
        )}

        {onRefreshCurrentTab && (
          <button
            onClick={onRefreshCurrentTab}
            title="Refresh current tab"
            style={{
              background: "#1E293B",
              border: "1px solid #334155",
              color: "#94A3B8",
              cursor: "pointer",
              borderRadius: "6px",
              padding: "6px",
              display: "flex",
              alignItems: "center",
            }}
          >
            <RefreshCw size={15} />
          </button>
        )}

        {/* Deep link button to store app */}
        {!isMobile && (
          <a
            href={storeAppUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-secondary btn-sm"
            style={{ textDecoration: "none", display: "inline-flex" }}
          >
            <ExternalLink size={14} />
            Store POS (5096)
          </a>
        )}

        {/* Superadmin Badge */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.5rem",
            padding: "0.3rem 0.65rem",
            background: "rgba(99, 102, 241, 0.15)",
            border: "1px solid rgba(99, 102, 241, 0.3)",
            borderRadius: "6px",
          }}
        >
          <ShieldCheck size={16} color="#818CF8" />
          <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#818CF8" }}>
            SUPERADMIN
          </span>
        </div>
      </div>
    </header>
  );
};
