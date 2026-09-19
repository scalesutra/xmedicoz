import React, { useState } from "react";
import {
  Gauge,
  BookOpen,
  ShoppingBag,
  ShoppingCart,
  Calculator,
  PieChart,
  Landmark,
  FileText,
  Package,
  Search,
  Plus,
  ChevronDown,
  ChevronRight,
  ChevronLeft,
  LogOut,
  Pill,
  Users,
  Truck,
  HeartPulse,
  Layers,
  Building2,
  X,
} from "lucide-react";
import { useAuth } from "../../context/AuthContext.js";

export type NavTab =
  | "dashboard"
  | "pos"
  | "pos-bill"
  | "pos-list"
  | "inventory"
  | "racks"
  | "purchases"
  | "purchase-bill"
  | "purchase-list"
  | "crm"
  | "accounting"
  | "medicines"
  | "customers"
  | "suppliers"
  | "lookups"
  | "purchase-orders"
  | "stock-ledger"
  | "settings";

interface SidebarProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  collapsed?: boolean;
  onToggleCollapse?: () => void;
  isMobile?: boolean;
  mobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  collapsed = false,
  onToggleCollapse,
  isMobile = false,
  mobileOpen = false,
  onCloseMobile,
}) => {
  const { user, logout } = useAuth();
  const [searchTerm, setSearchTerm] = useState("");

  const handleSelectTab = (tab: NavTab) => {
    onSelectTab(tab);
    if (isMobile && onCloseMobile) {
      onCloseMobile();
    }
  };

  const isEffectiveCollapsed = isMobile ? false : collapsed;

  // Expand states for collapsible menu items
  const [isSaleOpen, setIsSaleOpen] = useState(true);
  const [isPurchaseOpen, setIsPurchaseOpen] = useState(true);
  const [isMasterOpen, setIsMasterOpen] = useState(false);

  // Quick helper to check if a group is active
  const isSaleActive = currentTab === "pos" || currentTab === "pos-bill" || currentTab === "pos-list";
  const isPurchaseActive = currentTab === "purchases" || currentTab === "purchase-bill" || currentTab === "purchase-list";
  const isMasterActive = currentTab === "medicines" || currentTab === "customers" || currentTab === "suppliers";

  return (
    <>
      {isMobile && mobileOpen && (
        <div
          onClick={onCloseMobile}
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            zIndex: 998,
          }}
        />
      )}
      <aside
        style={
          isMobile
            ? {
                position: "fixed",
                top: 0,
                left: 0,
                bottom: 0,
                width: "280px",
                maxWidth: "85vw",
                backgroundColor: "#0B1917",
                backgroundImage: "linear-gradient(180deg, #0B1917 0%, #081412 100%)",
                color: "#E2E8F0",
                display: "flex",
                flexDirection: "column",
                zIndex: 999,
                boxShadow: mobileOpen ? "4px 0 25px rgba(0, 0, 0, 0.5)" : "none",
                transform: mobileOpen ? "translateX(0)" : "translateX(-100%)",
                transition: "transform 0.25s cubic-bezier(0.16, 1, 0.3, 1)",
                userSelect: "none",
              }
            : {
                width: collapsed ? "64px" : "250px",
                backgroundColor: "#0B1917",
                backgroundImage: "linear-gradient(180deg, #0B1917 0%, #081412 100%)",
                color: "#E2E8F0",
                display: "flex",
                flexDirection: "column",
                borderRight: "1px solid #162E2A",
                flexShrink: 0,
                height: "100vh",
                position: "sticky",
                top: 0,
                zIndex: 50,
                transition: "width 0.2s cubic-bezier(0.16, 1, 0.3, 1)",
                userSelect: "none",
              }
        }
      >
        {/* MedicalCRM Top Brand Identity Box */}
        <div
          style={{
            backgroundColor: "#FFFFFF",
            padding: isEffectiveCollapsed ? "0.6rem 0.25rem" : "0.55rem 0.85rem",
            display: "flex",
            flexDirection: "column",
            alignItems: isEffectiveCollapsed ? "center" : "flex-start",
            borderBottom: "1px solid #CBD5E1",
            minHeight: "56px",
            justifyContent: "center",
          }}
        >
          {isEffectiveCollapsed ? (
          <div
            style={{
              width: "32px",
              height: "32px",
              backgroundColor: "#059669",
              borderRadius: "6px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#FFFFFF",
              fontWeight: 900,
              fontSize: "1.1rem",
              boxShadow: "0 2px 4px rgba(5, 150, 105, 0.3)",
            }}
            title="MedicalCRM"
          >
            +
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", width: "100%" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <div
                  style={{
                    backgroundColor: "#059669",
                    color: "#FFFFFF",
                    fontWeight: 900,
                    fontSize: "0.85rem",
                    padding: "0.15rem 0.4rem",
                    borderRadius: "5px",
                    boxShadow: "0 2px 4px rgba(5, 150, 105, 0.25)",
                    lineHeight: 1.1,
                  }}
                >
                  +
                </div>
                <div style={{ display: "flex", alignItems: "baseline" }}>
                  <span style={{ fontSize: "1.18rem", fontWeight: 900, color: "#0F172A", letterSpacing: "-0.01em" }}>
                    Medical
                  </span>
                  <span style={{ fontSize: "1.18rem", fontWeight: 900, color: "#059669", letterSpacing: "-0.01em" }}>
                    CRM
                  </span>
                </div>
              </div>
              {isMobile ? (
                <button
                  onClick={onCloseMobile}
                  title="Close sidebar"
                  style={{
                    border: "none",
                    background: "transparent",
                    color: "#64748B",
                    cursor: "pointer",
                    padding: "4px",
                    display: "flex",
                    alignItems: "center",
                  }}
                >
                  <X size={18} />
                </button>
              ) : (
                onToggleCollapse && (
                  <button
                    onClick={onToggleCollapse}
                    title="Collapse sidebar"
                    style={{
                      border: "none",
                      background: "transparent",
                      color: "#64748B",
                      cursor: "pointer",
                      padding: "2px",
                      display: "flex",
                      alignItems: "center",
                    }}
                  >
                    <ChevronLeft size={16} />
                  </button>
                )
              )}
            </div>
            <div
              style={{
                fontSize: "0.58rem",
                color: "#64748B",
                fontWeight: 700,
                letterSpacing: "0.06em",
                marginTop: "2px",
                textTransform: "uppercase",
              }}
            >
              Enterprise Pharmacy ERP
            </div>
          </div>
        )}
      </div>

      {/* Search Input Box */}
      {!isEffectiveCollapsed && (
        <div style={{ padding: "0.6rem 0.75rem 0.35rem 0.75rem" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              backgroundColor: "rgba(255, 255, 255, 0.07)",
              borderRadius: "4px",
              border: "1px solid rgba(255, 255, 255, 0.12)",
              padding: "0.32rem 0.55rem",
              gap: "0.4rem",
            }}
          >
            <input
              type="text"
              placeholder="Type to search"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{
                background: "transparent",
                border: "none",
                outline: "none",
                color: "#E2E8F0",
                fontSize: "0.78rem",
                width: "100%",
                fontFamily: "inherit",
              }}
            />
            <Search size={14} color="#94A3B8" />
          </div>
        </div>
      )}

      {/* Sidebar Navigation Tree */}
      <nav
        style={{
          flex: 1,
          overflowY: "auto",
          padding: collapsed ? "0.6rem 0.25rem" : "0.4rem 0.5rem",
          display: "flex",
          flexDirection: "column",
          gap: "2px",
        }}
      >
        {/* Dashboard */}
        <button
          onClick={() => handleSelectTab("dashboard")}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.65rem",
            padding: "0.55rem 0.65rem",
            borderRadius: "4px",
            border: "none",
            background: currentTab === "dashboard" ? "rgba(16, 185, 129, 0.2)" : "transparent",
            color: currentTab === "dashboard" ? "#34D399" : "#CBD5E1",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontWeight: currentTab === "dashboard" ? 700 : 500,
            textAlign: "left",
            width: "100%",
          }}
          title="Dashboard"
        >
          <Gauge size={16} color={currentTab === "dashboard" ? "#34D399" : "#94A3B8"} />
          {!isEffectiveCollapsed && <span>Dashboard</span>}
        </button>

        {/* Master Group */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => setIsMasterOpen(!isMasterOpen)}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: isMasterActive ? "rgba(16, 185, 129, 0.15)" : "transparent",
              color: isMasterActive ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: isMasterActive ? 700 : 500,
              width: "100%",
            }}
            title="Master"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <BookOpen size={16} color={isMasterActive ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Master</span>}
            </div>
            {!isEffectiveCollapsed && (
              isMasterOpen ? <ChevronDown size={14} color="#94A3B8" /> : <ChevronRight size={14} color="#94A3B8" />
            )}
          </button>
          {!isEffectiveCollapsed && isMasterOpen && (
            <div style={{ display: "flex", flexDirection: "column", paddingLeft: "1.5rem", gap: "1px" }}>
              <button
                onClick={() => handleSelectTab("medicines")}
                style={{
                  padding: "0.35rem 0.5rem",
                  background: currentTab === "medicines" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "medicines" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.4rem",
                }}
              >
                <Pill size={13} /> Medicine Master
              </button>
              <button
                onClick={() => handleSelectTab("customers")}
                style={{
                  padding: "0.35rem 0.5rem",
                  background: currentTab === "customers" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "customers" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.4rem",
                }}
              >
                <Users size={13} /> Patient / Customer
              </button>
              <button
                onClick={() => handleSelectTab("suppliers")}
                style={{
                  padding: "0.35rem 0.5rem",
                  background: currentTab === "suppliers" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "suppliers" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.4rem",
                }}
              >
                <Truck size={13} /> Vendor / Supplier
              </button>
              <button
                onClick={() => handleSelectTab("lookups")}
                style={{
                  padding: "0.35rem 0.5rem",
                  background: currentTab === "lookups" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "lookups" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.4rem",
                }}
              >
                <Layers size={13} /> Catalogs & Tax Slabs
              </button>
            </div>
          )}
        </div>

        {/* SALE Group (Expanded as in Screenshot 1) */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => setIsSaleOpen(!isSaleOpen)}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: isSaleActive ? "rgba(16, 185, 129, 0.18)" : "transparent",
              color: isSaleActive ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: isSaleActive ? 700 : 500,
              width: "100%",
            }}
            title="Sale"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <ShoppingBag size={16} color={isSaleActive ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Sale</span>}
            </div>
            {!isEffectiveCollapsed && (
              isSaleOpen ? <ChevronDown size={14} color="#94A3B8" /> : <ChevronRight size={14} color="#94A3B8" />
            )}
          </button>

          {!isEffectiveCollapsed && isSaleOpen && (
            <div style={{ display: "flex", flexDirection: "column", paddingLeft: "1.4rem", gap: "2px" }}>
              <button
                onClick={() => handleSelectTab("pos-bill")}
                style={{
                  padding: "0.4rem 0.55rem",
                  background: currentTab === "pos-bill" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "pos-bill" ? "#34D399" : "#CBD5E1",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  fontWeight: currentTab === "pos-bill" ? 700 : 500,
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                }}
              >
                <span>POS Counter Bill (F2)</span>
                <span
                  style={{
                    fontSize: "0.62rem",
                    padding: "1px 5px",
                    borderRadius: "3px",
                    backgroundColor: "rgba(16, 185, 129, 0.2)",
                    color: "#34D399",
                    fontWeight: 700,
                  }}
                >
                  NEW
                </span>
              </button>
              <button
                onClick={() => handleSelectTab("pos-list")}
                style={{
                  padding: "0.4rem 0.55rem",
                  background: currentTab === "pos-list" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "pos-list" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  fontWeight: currentTab === "pos-list" ? 700 : 500,
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                }}
              >
                <span style={{ color: "#64748B" }}>→</span> Sales Register & Invoices
              </button>
            </div>
          )}
        </div>

        {/* PURCHASE Group (Expanded as in Screenshot 2) */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => setIsPurchaseOpen(!isPurchaseOpen)}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: isPurchaseActive ? "rgba(16, 185, 129, 0.18)" : "transparent",
              color: isPurchaseActive ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: isPurchaseActive ? 700 : 500,
              width: "100%",
            }}
            title="Purchase"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <ShoppingCart size={16} color={isPurchaseActive ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Purchase</span>}
            </div>
            {!isEffectiveCollapsed && (
              isPurchaseOpen ? <ChevronDown size={14} color="#94A3B8" /> : <ChevronRight size={14} color="#94A3B8" />
            )}
          </button>

          {!isEffectiveCollapsed && isPurchaseOpen && (
            <div style={{ display: "flex", flexDirection: "column", paddingLeft: "1.4rem", gap: "2px" }}>
              <button
                onClick={() => handleSelectTab("purchase-bill")}
                style={{
                  padding: "0.4rem 0.55rem",
                  background: currentTab === "purchase-bill" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "purchase-bill" ? "#34D399" : "#CBD5E1",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  fontWeight: currentTab === "purchase-bill" ? 700 : 500,
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                }}
              >
                <span>New Purchase Bill (Inward)</span>
                <span
                  style={{
                    fontSize: "0.62rem",
                    padding: "1px 5px",
                    borderRadius: "3px",
                    backgroundColor: "rgba(16, 185, 129, 0.2)",
                    color: "#34D399",
                    fontWeight: 700,
                  }}
                >
                  NEW
                </span>
              </button>
              <button
                onClick={() => handleSelectTab("purchase-list")}
                style={{
                  padding: "0.4rem 0.55rem",
                  background: currentTab === "purchase-list" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "purchase-list" ? "#34D399" : "#94A3B8",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  fontWeight: currentTab === "purchase-list" ? 700 : 500,
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                }}
              >
                <span style={{ color: "#64748B" }}>→</span> Purchase Inward Register
              </button>
              <button
                onClick={() => handleSelectTab("purchase-orders")}
                style={{
                  padding: "0.4rem 0.55rem",
                  background: currentTab === "purchase-orders" ? "rgba(16, 185, 129, 0.25)" : "transparent",
                  color: currentTab === "purchase-orders" ? "#34D399" : "#CBD5E1",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "0.78rem",
                  fontWeight: currentTab === "purchase-orders" ? 700 : 500,
                  textAlign: "left",
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                }}
              >
                <span style={{ color: "#64748B" }}>→</span> Purchase Orders (PO)
              </button>
            </div>
          )}
        </div>

        {/* Accounting Trans. */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => handleSelectTab("accounting")}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: currentTab === "accounting" ? "rgba(16, 185, 129, 0.2)" : "transparent",
              color: currentTab === "accounting" ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: currentTab === "accounting" ? 700 : 500,
              width: "100%",
            }}
            title="Accounting Trans."
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <Calculator size={16} color={currentTab === "accounting" ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Accounting Trans.</span>}
            </div>
            {!isEffectiveCollapsed && <ChevronRight size={14} color="#94A3B8" />}
          </button>
        </div>

        {/* Stock Management */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => handleSelectTab("inventory")}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: currentTab === "inventory" ? "rgba(16, 185, 129, 0.2)" : "transparent",
              color: currentTab === "inventory" ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: currentTab === "inventory" ? 700 : 500,
              width: "100%",
            }}
            title="Stock & Batches FEFO"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <PieChart size={16} color={currentTab === "inventory" ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Stock & Batches</span>}
            </div>
            {!isEffectiveCollapsed && <ChevronRight size={14} color="#94A3B8" />}
          </button>
        </div>

        {/* Physical Racks & Shelves */}
        <div style={{ display: "flex", flexDirection: "column" }}>
          <button
            onClick={() => handleSelectTab("racks")}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0.55rem 0.65rem",
              borderRadius: "4px",
              border: "none",
              background: currentTab === "racks" ? "rgba(16, 185, 129, 0.2)" : "transparent",
              color: currentTab === "racks" ? "#34D399" : "#CBD5E1",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontWeight: currentTab === "racks" ? 700 : 500,
              width: "100%",
            }}
            title="Physical Racks & Cold Storage"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem" }}>
              <Layers size={16} color={currentTab === "racks" ? "#34D399" : "#94A3B8"} />
              {!isEffectiveCollapsed && <span>Racks & Shelves</span>}
            </div>
            {!isEffectiveCollapsed && <ChevronRight size={14} color="#94A3B8" />}
          </button>
        </div>

        {/* Patient CRM / Chronic Reminders */}
        <button
          onClick={() => handleSelectTab("crm")}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.65rem",
            padding: "0.55rem 0.65rem",
            borderRadius: "4px",
            border: "none",
            background: currentTab === "crm" ? "rgba(16, 185, 129, 0.2)" : "transparent",
            color: currentTab === "crm" ? "#34D399" : "#CBD5E1",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontWeight: currentTab === "crm" ? 700 : 500,
            textAlign: "left",
            width: "100%",
          }}
          title="Patient CRM & Refills"
        >
          <HeartPulse size={16} color={currentTab === "crm" ? "#34D399" : "#94A3B8"} />
          {!isEffectiveCollapsed && <span>Patient CRM</span>}
        </button>

        {/* Stock Ledger */}
        <button
          onClick={() => handleSelectTab("stock-ledger")}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.65rem",
            padding: "0.55rem 0.65rem",
            borderRadius: "4px",
            border: "none",
            background: currentTab === "stock-ledger" ? "rgba(16, 185, 129, 0.2)" : "transparent",
            color: currentTab === "stock-ledger" ? "#34D399" : "#CBD5E1",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontWeight: currentTab === "stock-ledger" ? 700 : 500,
            textAlign: "left",
            width: "100%",
          }}
          title="Stock Movement Audit Ledger"
        >
          <FileText size={16} color={currentTab === "stock-ledger" ? "#34D399" : "#94A3B8"} />
          {!isEffectiveCollapsed && <span>Stock Movement Ledger</span>}
        </button>

        {/* Store Settings */}
        <button
          onClick={() => handleSelectTab("settings")}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "0.65rem",
            padding: "0.55rem 0.65rem",
            borderRadius: "4px",
            border: "none",
            background: currentTab === "settings" ? "rgba(16, 185, 129, 0.2)" : "transparent",
            color: currentTab === "settings" ? "#34D399" : "#CBD5E1",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontWeight: currentTab === "settings" ? 700 : 500,
            textAlign: "left",
            width: "100%",
            marginTop: "auto",
          }}
          title="Store Settings & Staff"
        >
          <Building2 size={16} color={currentTab === "settings" ? "#34D399" : "#94A3B8"} />
          {!isEffectiveCollapsed && <span>Store Settings & Staff</span>}
        </button>


      </nav>

      {/* User Session Logout Footer */}
      <div
        style={{
          padding: isEffectiveCollapsed ? "0.6rem 0.25rem" : "0.6rem 0.75rem",
          borderTop: "1px solid #162E2A",
          display: "flex",
          alignItems: "center",
          justifyContent: isEffectiveCollapsed ? "center" : "space-between",
          backgroundColor: "rgba(0, 0, 0, 0.2)",
        }}
      >
        {!isEffectiveCollapsed && (
          <div style={{ display: "flex", flexDirection: "column", minWidth: 0 }}>
            <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "#E2E8F0", textOverflow: "ellipsis", overflow: "hidden", whiteSpace: "nowrap" }}>
              {user?.firstName || user?.email?.split("@")[0] || "ankit"}
            </span>
            <span style={{ fontSize: "0.65rem", color: "#34D399" }}>Online • MedicalCRM</span>
          </div>
        )}
        <button
          onClick={logout}
          title="Sign out"
          style={{
            background: "transparent",
            border: "none",
            color: "#94A3B8",
            cursor: "pointer",
            padding: "4px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <LogOut size={16} />
        </button>
      </div>
    </aside>
    </>
  );
};
