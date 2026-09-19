import {
  LayoutDashboard,
  Building2,
  CreditCard,
  Users,
  ShieldCheck,
  Activity,
  LogOut,
  ExternalLink,
  ChevronLeft,
  X,
  Sparkles,
  LucideIcon,
} from "lucide-react";
import { useAuth } from "../../context/AuthContext.js";

export type SuperadminTab = "overview" | "shops" | "plans" | "users" | "audit" | "health";

interface SidebarProps {
  currentTab: SuperadminTab;
  onSelectTab: (tab: SuperadminTab) => void;
  collapsed: boolean;
  onToggleCollapse: () => void;
  isMobile: boolean;
  mobileOpen: boolean;
  onCloseMobile: () => void;
}

export const SuperadminSidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  collapsed,
  onToggleCollapse,
  isMobile,
  mobileOpen,
  onCloseMobile,
}) => {
  const { user, logout } = useAuth();

  const navItems: { id: SuperadminTab; label: string; icon: LucideIcon }[] = [
    { id: "overview", label: "Executive Cockpit", icon: LayoutDashboard },
    { id: "shops", label: "Pharmacies & Tenants", icon: Building2 },
    { id: "plans", label: "Subscription Plans", icon: CreditCard },
    { id: "users", label: "Global Platform Users", icon: Users },
    { id: "audit", label: "Security & Audit Logs", icon: ShieldCheck },
    { id: "health", label: "System Diagnostics", icon: Activity },
  ];

  const handleSelect = (tab: SuperadminTab) => {
    onSelectTab(tab);
    if (isMobile) {
      onCloseMobile();
    }
  };

  const storeAppUrl = typeof window !== "undefined"
    ? `http://${window.location.hostname}:5096`
    : "http://localhost:5096";

  const isEffectiveCollapsed = !isMobile && collapsed;

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobile && mobileOpen && (
        <div
          onClick={onCloseMobile}
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(0, 0, 0, 0.75)",
            zIndex: 998,
            backdropFilter: "blur(2px)",
          }}
        />
      )}

      <aside
        style={{
          position: isMobile ? "fixed" : "sticky",
          top: 0,
          left: 0,
          bottom: 0,
          zIndex: isMobile ? 999 : 10,
          height: "100vh",
          width: isEffectiveCollapsed ? "68px" : "260px",
          transform: isMobile ? (mobileOpen ? "translateX(0)" : "translateX(-100%)") : "none",
          transition: "transform 0.25s cubic-bezier(0.4, 0, 0.2, 1), width 0.2s ease",
          backgroundColor: "#0F172A",
          borderRight: "1px solid #1E293B",
          display: "flex",
          flexDirection: "column",
          flexShrink: 0,
        }}
      >
        {/* Brand Header */}
        <div
          style={{
            padding: isEffectiveCollapsed ? "1rem 0.5rem" : "1.1rem 1.25rem",
            borderBottom: "1px solid #1E293B",
            display: "flex",
            alignItems: "center",
            justifyContent: isEffectiveCollapsed ? "center" : "space-between",
          }}
        >
          {isEffectiveCollapsed ? (
            <div
              style={{
                width: "36px",
                height: "36px",
                borderRadius: "8px",
                background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#FFFFFF",
                fontWeight: 900,
                fontSize: "1.1rem",
                boxShadow: "0 4px 12px rgba(99, 102, 241, 0.4)",
              }}
              title="MedicalCRM Superadmin"
            >
              ⚡
            </div>
          ) : (
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", width: "100%" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
                <div
                  style={{
                    width: "32px",
                    height: "32px",
                    borderRadius: "8px",
                    background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "#FFFFFF",
                    fontWeight: 900,
                    boxShadow: "0 2px 8px rgba(99, 102, 241, 0.4)",
                  }}
                >
                  <Sparkles size={18} />
                </div>
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "5px" }}>
                    <span style={{ fontWeight: 800, color: "#F8FAFC", fontSize: "0.95rem", letterSpacing: "-0.01em" }}>
                      Medical
                    </span>
                    <span style={{ fontWeight: 800, color: "#818CF8", fontSize: "0.95rem" }}>
                      CRM
                    </span>
                  </div>
                  <div
                    style={{
                      fontSize: "0.6rem",
                      fontWeight: 800,
                      color: "#94A3B8",
                      letterSpacing: "0.08em",
                      textTransform: "uppercase",
                    }}
                  >
                    Superadmin Platform
                  </div>
                </div>
              </div>

              {isMobile ? (
                <button
                  onClick={onCloseMobile}
                  style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer", padding: "4px" }}
                >
                  <X size={18} />
                </button>
              ) : (
                <button
                  onClick={onToggleCollapse}
                  style={{
                    background: "transparent",
                    border: "none",
                    color: "#64748B",
                    cursor: "pointer",
                    padding: "4px",
                    display: "flex",
                    alignItems: "center",
                  }}
                  title="Collapse sidebar"
                >
                  <ChevronLeft size={16} />
                </button>
              )}
            </div>
          )}
        </div>

        {/* Navigation Items */}
        <nav
          style={{
            flex: 1,
            overflowY: "auto",
            padding: isEffectiveCollapsed ? "0.75rem 0.35rem" : "0.75rem 0.75rem",
            display: "flex",
            flexDirection: "column",
            gap: "4px",
          }}
        >
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => handleSelect(item.id)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.75rem",
                  padding: isEffectiveCollapsed ? "0.65rem 0" : "0.65rem 0.85rem",
                  justifyContent: isEffectiveCollapsed ? "center" : "flex-start",
                  borderRadius: "8px",
                  border: "none",
                  background: isActive ? "rgba(99, 102, 241, 0.18)" : "transparent",
                  color: isActive ? "#818CF8" : "#94A3B8",
                  cursor: "pointer",
                  fontSize: "0.84rem",
                  fontWeight: isActive ? 700 : 500,
                  transition: "all 0.15s ease",
                  textAlign: "left",
                  width: "100%",
                }}
                title={item.label}
              >
                <Icon size={18} color={isActive ? "#818CF8" : "#64748B"} />
                {!isEffectiveCollapsed && <span>{item.label}</span>}
              </button>
            );
          })}

          {/* Quick jump to Store App */}
          <div style={{ marginTop: "auto", paddingTop: "1rem" }}>
            <a
              href={storeAppUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.75rem",
                padding: isEffectiveCollapsed ? "0.65rem 0" : "0.65rem 0.85rem",
                justifyContent: isEffectiveCollapsed ? "center" : "space-between",
                borderRadius: "8px",
                background: "rgba(16, 185, 129, 0.1)",
                color: "#34D399",
                fontSize: "0.8rem",
                fontWeight: 600,
                textDecoration: "none",
                border: "1px solid rgba(16, 185, 129, 0.2)",
              }}
              title="Launch Pharmacy Store ERP"
            >
              <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
                <ExternalLink size={16} color="#34D399" />
                {!isEffectiveCollapsed && <span>Store App (5096)</span>}
              </div>
            </a>
          </div>
        </nav>

        {/* User Session Footer */}
        <div
          style={{
            padding: isEffectiveCollapsed ? "0.75rem 0.35rem" : "0.75rem 1rem",
            borderTop: "1px solid #1E293B",
            display: "flex",
            alignItems: "center",
            justifyContent: isEffectiveCollapsed ? "center" : "space-between",
            backgroundColor: "rgba(0, 0, 0, 0.25)",
          }}
        >
          {!isEffectiveCollapsed && (
            <div style={{ minWidth: 0 }}>
              <div
                style={{
                  fontSize: "0.8rem",
                  fontWeight: 700,
                  color: "#F8FAFC",
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                }}
              >
                {user?.firstName ? `${user.firstName} ${user.lastName}` : user?.email?.split("@")[0]}
              </div>
              <div style={{ fontSize: "0.68rem", color: "#818CF8", display: "flex", alignItems: "center", gap: "4px" }}>
                <span
                  style={{ width: "6px", height: "6px", borderRadius: "50%", backgroundColor: "#10B981" }}
                />
                Platform Superadmin
              </div>
            </div>
          )}

          <button
            onClick={logout}
            style={{
              background: "transparent",
              border: "none",
              color: "#94A3B8",
              cursor: "pointer",
              padding: "6px",
              display: "flex",
              alignItems: "center",
              borderRadius: "6px",
            }}
            title="Sign out of Superadmin"
          >
            <LogOut size={16} />
          </button>
        </div>
      </aside>
    </>
  );
};
