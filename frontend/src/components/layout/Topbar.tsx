import React, { useState, useEffect } from "react";
import {
  Menu,
  Wifi,
  User,
  Download,
  PhoneCall,
  HelpCircle,
  Settings,
  Bell,
  Keyboard,
  History,
  Store,
  ChevronDown,
  PlusCircle,
  CreditCard,
  Check,
  X,
} from "lucide-react";
import { useAuth } from "../../context/AuthContext.js";
import { useShop, Shop } from "../../context/ShopContext.js";
import { apiRequest } from "../../api/client.js";

interface TopbarProps {
  title?: string;
  subtitle?: string;
  isSidebarCollapsed?: boolean;
  onToggleSidebar?: () => void;
  onSelectTab?: (tab: any) => void;
  isMobile?: boolean;
}

export const Topbar: React.FC<TopbarProps> = ({
  isSidebarCollapsed,
  onToggleSidebar,
  onSelectTab,
  isMobile = false,
}) => {
  const { user } = useAuth();
  const {
    shops,
    currentShop,
    setCurrentShop,
    setIsOnboardModalOpen,
    setIsSubscriptionModalOpen,
  } = useShop();

  const [isShopDropdownOpen, setIsShopDropdownOpen] = useState(false);
  const [isShortcutModalOpen, setIsShortcutModalOpen] = useState(false);
  const [isHelpModalOpen, setIsHelpModalOpen] = useState(false);
  const [isDrugHelplineOpen, setIsDrugHelplineOpen] = useState(false);
  const [isNotificationOpen, setIsNotificationOpen] = useState(false);
  const [unreadNotifications, setUnreadNotifications] = useState<number>(0);
  const [crmNotifications, setCrmNotifications] = useState<any[]>([]);
  const [nearExpiryAlertCount, setNearExpiryAlertCount] = useState<number>(0);

  useEffect(() => {
    let isMounted = true;
    Promise.all([
      apiRequest("/crm/notifications"),
      apiRequest("/inventory/near-expiry?days=30"),
    ])
      .then(([notifRes, expRes]) => {
        if (!isMounted) return;
        let count = 0;
        if (notifRes.success && notifRes.data?.items) {
          setCrmNotifications(notifRes.data.items.slice(0, 5));
          count += Math.min(notifRes.data.items.length, 5);
        }
        if (expRes.success && Array.isArray(expRes.data) && expRes.data.length > 0) {
          setNearExpiryAlertCount(expRes.data.length);
          count += 1;
        }
        setUnreadNotifications(count);
      })
      .catch(() => {});
    return () => {
      isMounted = false;
    };
  }, [currentShop?.id]);

  return (
    <>
      <header
        style={{
          height: "48px",
          backgroundColor: "#0F766E", // Current deep teal theme
          backgroundImage: "linear-gradient(90deg, #0F766E 0%, #0D5D57 100%)",
          color: "#FFFFFF",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 1rem",
          position: "sticky",
          top: 0,
          zIndex: 40,
          boxShadow: "0 2px 4px rgba(0, 0, 0, 0.15)",
          userSelect: "none",
        }}
      >
        {/* Left: Hamburger + Shop Info + Financial Year + Telemetry */}
        <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", minWidth: 0 }}>
          {onToggleSidebar && (
            <button
              onClick={onToggleSidebar}
              title={isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar"}
              style={{
                background: "transparent",
                border: "none",
                color: "#FFFFFF",
                cursor: "pointer",
                padding: "4px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Menu size={20} />
            </button>
          )}

          {/* Shop Switcher Button & Title */}
          <div style={{ position: "relative" }}>
            <button
              onClick={() => setIsShopDropdownOpen(!isShopDropdownOpen)}
              style={{
                background: "transparent",
                border: "none",
                color: "#FFFFFF",
                cursor: "pointer",
                padding: "2px 6px",
                borderRadius: "4px",
                display: "flex",
                alignItems: "center",
                gap: "6px",
                textAlign: "left",
              }}
              title="Change active medical company"
            >
              <Store size={16} color="#A7F3D0" />
              <div style={{ display: "flex", flexDirection: "column" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                  <span
                    style={{
                      fontSize: "0.86rem",
                      fontWeight: 700,
                      letterSpacing: "-0.01em",
                      maxWidth: isMobile ? "120px" : "none",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                      display: "inline-block",
                    }}
                  >
                    {currentShop?.name || "Phrma Wholsl (PHWH)"}
                  </span>
                  <ChevronDown size={12} color="#A7F3D0" />
                </div>
                {!isMobile && (
                  <span style={{ fontSize: "0.66rem", color: "#A7F3D0", opacity: 0.9 }}>
                    Books From 01-04-2026 to 31-03-2027
                  </span>
                )}
              </div>
            </button>

            {/* Shop Selection Dropdown */}
            {isShopDropdownOpen && (
              <div
                style={{
                  position: "absolute",
                  top: "100%",
                  left: 0,
                  marginTop: "6px",
                  width: "280px",
                  backgroundColor: "#FFFFFF",
                  borderRadius: "8px",
                  boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.25), 0 8px 10px -6px rgba(0, 0, 0, 0.2)",
                  border: "1px solid #CBD5E1",
                  padding: "0.5rem",
                  zIndex: 100,
                  color: "#0F172A",
                }}
              >
                <div
                  style={{
                    fontSize: "0.68rem",
                    fontWeight: 700,
                    color: "#64748B",
                    textTransform: "uppercase",
                    padding: "0.3rem 0.5rem",
                  }}
                >
                  Registered Companies & Branches
                </div>
                <div style={{ maxHeight: "200px", overflowY: "auto", display: "flex", flexDirection: "column", gap: "2px" }}>
                  {shops.map((shop) => (
                    <button
                      key={shop.id}
                      onClick={() => {
                        setCurrentShop(shop);
                        setIsShopDropdownOpen(false);
                      }}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        padding: "0.45rem 0.6rem",
                        borderRadius: "5px",
                        border: "none",
                        background: shop.id === currentShop?.id ? "#ECFDF5" : "transparent",
                        color: shop.id === currentShop?.id ? "#047857" : "#334155",
                        fontWeight: shop.id === currentShop?.id ? 700 : 500,
                        fontSize: "0.8rem",
                        cursor: "pointer",
                        textAlign: "left",
                        width: "100%",
                      }}
                    >
                      <span>{shop.name}</span>
                      {shop.id === currentShop?.id && <Check size={14} color="#059669" />}
                    </button>
                  ))}
                </div>
                <div style={{ borderTop: "1px solid #E2E8F0", marginTop: "0.4rem", paddingTop: "0.4rem" }}>
                  <button
                    onClick={() => {
                      setIsShopDropdownOpen(false);
                      setIsOnboardModalOpen(true);
                    }}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.4rem",
                      width: "100%",
                      padding: "0.45rem 0.6rem",
                      background: "transparent",
                      border: "none",
                      color: "#0F766E",
                      fontWeight: 600,
                      fontSize: "0.78rem",
                      cursor: "pointer",
                      borderRadius: "4px",
                    }}
                  >
                    <PlusCircle size={14} /> + Register New Company
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Network & Marg Telemetry Badges */}
          {!isMobile && (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                paddingLeft: "0.6rem",
                borderLeft: "1px solid rgba(255, 255, 255, 0.2)",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                <Wifi size={13} color="#34D399" />
                <span style={{ fontSize: "0.7rem", color: "#A7F3D0", fontWeight: 600 }}>10 Mb/s</span>
              </div>
              <span style={{ fontSize: "0.7rem", color: "#CBD5E1", fontWeight: 500 }}>V. 4.3.586.b</span>
            </div>
          )}
        </div>

        {/* Right: Marg Books Utility Menu Items */}
        <div style={{ display: "flex", alignItems: "center", gap: isMobile ? "0.6rem" : "1rem" }}>
          {/* User Account */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "5px",
              cursor: "pointer",
            }}
            title={`Logged in as ${user?.firstName || user?.email?.split("@")[0] || "ankit"}`}
          >
            <div
              style={{
                width: "24px",
                height: "24px",
                borderRadius: "50%",
                backgroundColor: "rgba(255, 255, 255, 0.2)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <User size={14} color="#FFFFFF" />
            </div>
            {!isMobile && (
              <span style={{ fontSize: "0.76rem", fontWeight: 600, color: "#FFFFFF" }}>
                {user?.firstName || user?.email?.split("@")[0] || "ankit"}
              </span>
            )}
          </div>

          {!isMobile && (
            <>
              {/* Pur. Import */}
              <button
                onClick={() => {
                  if (onSelectTab) {
                    onSelectTab("purchase-bill");
                  }
                }}
                style={{
                  background: "transparent",
                  border: "none",
                  color: "#E2E8F0",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: "2px",
                  padding: "0 2px",
                }}
                title="Purchase Bill Inward / Import"
              >
                <Download size={15} />
                <span style={{ fontSize: "0.62rem" }}>Pur. Import</span>
              </button>

              {/* Drug Helpline */}
              <button
                onClick={() => setIsDrugHelplineOpen(true)}
                style={{
                  background: "transparent",
                  border: "none",
                  color: "#E2E8F0",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: "2px",
                  padding: "0 2px",
                }}
                title="Drug Helpline & Molecules"
              >
                <PhoneCall size={15} />
                <span style={{ fontSize: "0.62rem" }}>Drug Helpline</span>
              </button>

              {/* Help */}
              <button
                onClick={() => setIsHelpModalOpen(true)}
                style={{
                  background: "transparent",
                  border: "none",
                  color: "#E2E8F0",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: "2px",
                  padding: "0 2px",
                }}
                title="Help Desk & Guide"
              >
                <HelpCircle size={15} />
                <span style={{ fontSize: "0.62rem" }}>Help</span>
              </button>
            </>
          )}

          {/* Settings */}
          <button
            onClick={() => setIsSubscriptionModalOpen(true)}
            style={{
              background: "transparent",
              border: "none",
              color: "#E2E8F0",
              cursor: "pointer",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: "2px",
              padding: "0 2px",
            }}
            title="Company Settings & Subscription"
          >
            <Settings size={15} />
            <span style={{ fontSize: "0.62rem" }}>Settings</span>
          </button>

          {/* Notification */}
          <div style={{ position: "relative" }}>
            <button
              onClick={() => setIsNotificationOpen(!isNotificationOpen)}
              style={{
                background: "transparent",
                border: "none",
                color: "#E2E8F0",
                cursor: "pointer",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: "2px",
                padding: "0 2px",
                position: "relative",
              }}
              title="System Notifications"
            >
              <Bell size={15} />
              <span style={{ fontSize: "0.62rem" }}>Notification</span>
              {unreadNotifications > 0 && (
                <span
                  style={{
                    position: "absolute",
                    top: "-3px",
                    right: "10px",
                    width: "7px",
                    height: "7px",
                    borderRadius: "50%",
                    backgroundColor: "#EF4444",
                    border: "1px solid #FFFFFF",
                  }}
                />
              )}
            </button>

            {/* Notification Popover */}
            {isNotificationOpen && (
              <div
                style={{
                  position: "absolute",
                  top: "100%",
                  right: 0,
                  marginTop: "8px",
                  width: "280px",
                  backgroundColor: "#FFFFFF",
                  borderRadius: "8px",
                  boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.25)",
                  border: "1px solid #CBD5E1",
                  padding: "0.65rem",
                  zIndex: 100,
                  color: "#0F172A",
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
                  <span style={{ fontSize: "0.78rem", fontWeight: 700 }}>System Alerts</span>
                  <button
                    onClick={() => setUnreadNotifications(0)}
                    style={{ background: "none", border: "none", color: "#0F766E", fontSize: "0.68rem", cursor: "pointer", fontWeight: 600 }}
                  >
                    Mark read
                  </button>
                </div>
                <div style={{ fontSize: "0.72rem", color: "#475569", display: "flex", flexDirection: "column", gap: "6px", maxHeight: "240px", overflowY: "auto" }}>
                  {nearExpiryAlertCount > 0 && (
                    <div
                      onClick={() => {
                        setIsNotificationOpen(false);
                        if (onSelectTab) onSelectTab("inventory");
                      }}
                      style={{ padding: "6px 8px", backgroundColor: "#FEF2F2", borderRadius: "4px", borderLeft: "3px solid #EF4444", cursor: "pointer" }}
                    >
                      <strong style={{ color: "#B91C1C" }}>Expiry Alert:</strong> {nearExpiryAlertCount} batches expiring within 30 days. Click to inspect &rarr;
                    </div>
                  )}
                  {crmNotifications.length > 0 ? (
                    crmNotifications.map((n) => (
                      <div key={n.id} style={{ padding: "6px 8px", backgroundColor: "#F0FDFA", borderRadius: "4px", borderLeft: "3px solid #0F766E" }}>
                        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "2px" }}>
                          <strong style={{ color: "#0F766E" }}>{n.channel || "Alert"} Dispatched</strong>
                          <span style={{ fontSize: "0.65rem", color: "#64748B" }}>
                            {n.sentAt ? new Date(n.sentAt).toLocaleDateString("en-IN", { day: "numeric", month: "short" }) : "Recent"}
                          </span>
                        </div>
                        <p style={{ margin: 0, color: "#334155", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                          {n.customer?.name ? `To: ${n.customer.name} • ` : ""}{n.message}
                        </p>
                      </div>
                    ))
                  ) : nearExpiryAlertCount === 0 ? (
                    <div style={{ padding: "12px", textAlign: "center", color: "#94A3B8" }}>
                      No unread system alerts. All operational parameters normal.
                    </div>
                  ) : null}
                </div>
              </div>
            )}
          </div>

          {!isMobile && (
            <>
              {/* Shortcut */}
              <button
                onClick={() => setIsShortcutModalOpen(true)}
                style={{
                  background: "transparent",
                  border: "none",
                  color: "#E2E8F0",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: "2px",
                  padding: "0 2px",
                }}
                title="Pharmacy Keyboard Shortcuts (F10, F9, F2, Esc)"
              >
                <Keyboard size={15} />
                <span style={{ fontSize: "0.62rem" }}>Shortcut</span>
              </button>

              {/* History / Audit Log */}
              <button
                onClick={() => {
                  if (onSelectTab) {
                    onSelectTab("accounting");
                  }
                }}
                style={{
                  background: "transparent",
                  border: "none",
                  color: "#E2E8F0",
                  cursor: "pointer",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: "2px",
                  padding: "0 2px",
                }}
                title="Bill Audit History & Daybook"
              >
                <History size={15} />
                <span style={{ fontSize: "0.62rem" }}>History</span>
              </button>
            </>
          )}
        </div>
      </header>

      {/* Pharmacy Keyboard Shortcuts Modal */}
      {isShortcutModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsShortcutModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              width: "100%",
              maxWidth: "520px",
              padding: "1.5rem",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                ⚡ Pharmacy POS Keyboard Shortcuts
              </h3>
              <button
                onClick={() => setIsShortcutModalOpen(false)}
                style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer" }}
              >
                <X size={18} />
              </button>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: "8px", maxHeight: "360px", overflowY: "auto" }}>
              {[
                { key: "F2", desc: "Create New Sale / Purchase Bill" },
                { key: "F9", desc: "Save Inward / Outward Bill" },
                { key: "F10", desc: "Open Search & Filter Drawer" },
                { key: "Esc", desc: "Close Current Dialog / Exit to List" },
                { key: "Alt + M", desc: "Open Medicine Catalog Master" },
                { key: "Alt + C", desc: "Open Customer & Patient CRM" },
                { key: "Alt + S", desc: "Open Supplier / Stockist Directory" },
                { key: "Alt + A", desc: "Open Financial Daybook & Accounting" },
              ].map((sc, i) => (
                <div
                  key={i}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "8px 12px",
                    backgroundColor: "#F8FAF9",
                    borderRadius: "4px",
                    border: "1px solid #E2E8F0",
                  }}
                >
                  <span style={{ color: "#334155", fontWeight: 500 }}>{sc.desc}</span>
                  <span
                    style={{
                      fontFamily: "monospace",
                      fontWeight: 700,
                      color: "#0F766E",
                      backgroundColor: "#ECFDF5",
                      padding: "2px 6px",
                      borderRadius: "4px",
                      border: "1px solid #A7F3D0",
                      fontSize: "0.75rem",
                    }}
                  >
                    {sc.key}
                  </span>
                </div>
              ))}
            </div>

            <div style={{ marginTop: "1.2rem", textAlign: "right" }}>
              <button
                onClick={() => setIsShortcutModalOpen(false)}
                className="marg-btn-teal"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Drug Helpline & Clinical Advisory Modal */}
      {isDrugHelplineOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsDrugHelplineOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              width: "100%",
              maxWidth: "520px",
              padding: "1.5rem",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "8px" }}>
                <PhoneCall size={18} color="#0F766E" /> Pharma Clinical & Drug Advisory
              </h3>
              <button
                onClick={() => setIsDrugHelplineOpen(false)}
                style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer" }}
              >
                <X size={18} />
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "10px", fontSize: "0.85rem", color: "#334155" }}>
              <div style={{ backgroundColor: "#F0FDF4", borderLeft: "4px solid #10B981", padding: "10px 12px", borderRadius: "4px" }}>
                <strong style={{ color: "#065F46" }}>National Poison Information Centre (AIIMS New Delhi):</strong>
                <div style={{ marginTop: "4px", fontSize: "0.95rem", fontWeight: 700, color: "#0F766E" }}>1800-116-117 / 011-26589391</div>
                <div style={{ fontSize: "0.78rem", color: "#64748B" }}>24x7 Emergency Toxicological Advisory</div>
              </div>

              <div style={{ backgroundColor: "#FEF3C7", borderLeft: "4px solid #F59E0B", padding: "10px 12px", borderRadius: "4px" }}>
                <strong style={{ color: "#92400E" }}>CDSCO Schedule H / H1 Compliance:</strong>
                <div style={{ marginTop: "4px", fontSize: "0.82rem", color: "#78350F" }}>
                  Schedule H and H1 medications require registered doctor prescription and separate audit ledger records. MedicalCRM automatically flags schedule categories in the POS.
                </div>
              </div>

              <div style={{ backgroundColor: "#EFF6FF", borderLeft: "4px solid #3B82F6", padding: "10px 12px", borderRadius: "4px" }}>
                <strong style={{ color: "#1E40AF" }}>Pharmacovigilance Programme of India (PvPI):</strong>
                <div style={{ marginTop: "4px", fontSize: "0.82rem", color: "#1E3A8A" }}>
                  Adverse Drug Reaction (ADR) Helpline: <strong>1800-180-3024</strong> (Toll-Free)
                </div>
              </div>
            </div>

            <div style={{ marginTop: "1.2rem", textAlign: "right" }}>
              <button
                onClick={() => setIsDrugHelplineOpen(false)}
                className="marg-btn-teal"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Help Desk & Documentation Modal */}
      {isHelpModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsHelpModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              width: "100%",
              maxWidth: "520px",
              padding: "1.5rem",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "8px" }}>
                <HelpCircle size={18} color="#0F766E" /> MedicalCRM Help & Support Desk
              </h3>
              <button
                onClick={() => setIsHelpModalOpen(false)}
                style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer" }}
              >
                <X size={18} />
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "10px", fontSize: "0.85rem", color: "#334155" }}>
              <div style={{ padding: "8px 12px", border: "1px solid #E2E8F0", borderRadius: "6px" }}>
                <strong style={{ color: "#0F172A" }}>📷 AI Invoice OCR Inward:</strong>
                <p style={{ margin: "4px 0 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Go to Purchases and click <em>"📷 Scan Bill (AI OCR)"</em>. Upload any stockist invoice photo to extract 100% of medicines, batch numbers, expiries, and rates in 2 seconds.
                </p>
              </div>

              <div style={{ padding: "8px 12px", border: "1px solid #E2E8F0", borderRadius: "6px" }}>
                <strong style={{ color: "#0F172A" }}>💊 FEFO Stock Management:</strong>
                <p style={{ margin: "4px 0 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Earliest expiry batches are automatically sorted at the top of POS search to eliminate expiry loss.
                </p>
              </div>

              <div style={{ padding: "8px 12px", border: "1px solid #E2E8F0", borderRadius: "6px" }}>
                <strong style={{ color: "#0F172A" }}>🔔 Chronic Patient CRM:</strong>
                <p style={{ margin: "4px 0 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Use the CRM tab to dispatch automated refill reminder alerts to cardiac, diabetic, and hypertension patients.
                </p>
              </div>
            </div>

            <div style={{ marginTop: "1.2rem", textAlign: "right" }}>
              <button
                onClick={() => setIsHelpModalOpen(false)}
                className="marg-btn-teal"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
