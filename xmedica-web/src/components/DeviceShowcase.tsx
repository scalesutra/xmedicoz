import React, { useState } from "react";
import {
  Smartphone,
  Monitor,
  Scan,
  AlertTriangle,
  Send,
  CheckCircle,
  Plus,
  Layers,
  FileText,
  Clock,
  ExternalLink,
  ChevronRight,
  Shield,
  Wifi,
  Battery,
} from "lucide-react";
import { AppColors } from "../theme/colors";
import { AppConfig } from "../config/appConfig";

interface DeviceShowcaseProps {
  onOpenPlayStoreModal: () => void;
}

export const DeviceShowcase: React.FC<DeviceShowcaseProps> = ({
  onOpenPlayStoreModal,
}) => {
  const [activePlatform, setActivePlatform] = useState<"mobile" | "web">("mobile");
  const [mobileFeatureTab, setMobileFeatureTab] = useState<"pos" | "fefo" | "crm">("pos");

  return (
    <section
      id="showcase"
      style={{
        padding: "90px 0",
        backgroundColor: "#F1F5F4",
        borderTop: `1px solid ${AppColors.borderSubtle}`,
        borderBottom: `1px solid ${AppColors.borderSubtle}`,
        position: "relative",
      }}
    >
      <div className="container-custom">
        {/* Section Header */}
        <div style={{ textAlign: "center", maxWidth: "720px", margin: "0 auto 3rem auto" }}>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "0.4rem",
              padding: "0.3rem 0.85rem",
              borderRadius: "9999px",
              backgroundColor: AppColors.tealSurface,
              color: AppColors.deepTeal,
              fontSize: "0.8rem",
              fontWeight: 700,
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              marginBottom: "0.85rem",
            }}
          >
            <Layers size={14} />
            <span>Interactive Platform Simulator</span>
          </div>

          <h2
            style={{
              fontSize: "clamp(1.9rem, 3.8vw, 2.75rem)",
              fontWeight: 800,
              letterSpacing: "-0.03em",
              color: AppColors.textPrimary,
              lineHeight: 1.18,
              marginBottom: "1rem",
            }}
          >
            One Cohesive System.{" "}
            <span className="gradient-text">
              Pocket POS to Cloud ERP.
            </span>
          </h2>

          <p style={{ fontSize: "1.02rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
            Toggle between the <strong>Android Play Store Mobile App</strong> for rush-hour counter sales
            and the <strong>Cloud Web Product App</strong> for complete back-office inventory, rack mapping, and double-entry accounting.
          </p>

          {/* Platform Switcher Buttons */}
          <div
            className="platform-switcher-container"
            style={{
              display: "inline-flex",
              flexWrap: "wrap",
              justifyContent: "center",
              alignItems: "center",
              padding: "4px",
              backgroundColor: "#FFFFFF",
              borderRadius: "14px",
              border: `1px solid ${AppColors.borderSubtle}`,
              boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
              marginTop: "1.75rem",
              gap: "4px",
              maxWidth: "100%",
            }}
          >
            <button
              onClick={() => setActivePlatform("mobile")}
              className="platform-switcher-btn"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                padding: "0.6rem 1.1rem",
                borderRadius: "10px",
                fontSize: "0.85rem",
                fontWeight: 700,
                backgroundColor:
                  activePlatform === "mobile" ? AppColors.primaryEmerald : "transparent",
                color: activePlatform === "mobile" ? "#FFFFFF" : AppColors.textSecondary,
                boxShadow:
                  activePlatform === "mobile"
                    ? `0 4px 12px ${AppColors.emeraldGlow}`
                    : "none",
              }}
            >
              <Smartphone size={17} />
              <span>Android Mobile POS (Play Store)</span>
            </button>

            <button
              onClick={() => setActivePlatform("web")}
              className="platform-switcher-btn"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                padding: "0.6rem 1.1rem",
                borderRadius: "10px",
                fontSize: "0.85rem",
                fontWeight: 700,
                backgroundColor:
                  activePlatform === "web" ? AppColors.bgSidebar : "transparent",
                color: activePlatform === "web" ? "#FFFFFF" : AppColors.textSecondary,
                boxShadow:
                  activePlatform === "web" ? "0 4px 12px rgba(11,25,23,0.3)" : "none",
              }}
            >
              <Monitor size={17} />
              <span>Cloud Web ERP (Product App)</span>
            </button>
          </div>
        </div>

        {/* Dynamic Display Container */}
        {activePlatform === "mobile" ? (
          /* MOBILE SHOWCASE */
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 290px), 1fr))",
              gap: "2.5rem",
              alignItems: "center",
              maxWidth: "1040px",
              margin: "0 auto",
              width: "100%",
            }}
          >
            {/* Interactive Phone Frame */}
            <div style={{ display: "flex", justifyContent: "center", width: "100%" }}>
              <div
                style={{
                  width: "min(330px, calc(100vw - 32px))",
                  height: "clamp(540px, 80vh, 650px)",
                  borderRadius: "clamp(32px, 8vw, 46px)",
                  backgroundColor: "#0B1917",
                  border: "clamp(6px, 1.8vw, 10px) solid #1E293B",
                  boxShadow: "0 30px 60px -15px rgba(11, 25, 23, 0.45)",
                  overflow: "hidden",
                  display: "flex",
                  flexDirection: "column",
                  position: "relative",
                  margin: "0 auto",
                }}
              >
                {/* Dynamic Camera Punch Hole */}
                <div
                  style={{
                    position: "absolute",
                    top: "12px",
                    left: "50%",
                    transform: "translateX(-50%)",
                    width: "80px",
                    height: "18px",
                    backgroundColor: "#000000",
                    borderRadius: "12px",
                    zIndex: 25,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "6px",
                  }}
                >
                  <div style={{ width: "8px", height: "8px", borderRadius: "50%", backgroundColor: "#1E293B" }} />
                  <div style={{ width: "30px", height: "3px", borderRadius: "2px", backgroundColor: "#1E293B" }} />
                </div>

                {/* Status Bar */}
                <div
                  style={{
                    height: "38px",
                    padding: "0 20px",
                    display: "flex",
                    alignItems: "flex-end",
                    justifyContent: "space-between",
                    fontSize: "0.72rem",
                    fontWeight: 700,
                    color: "#94A3B8",
                    paddingBottom: "4px",
                    zIndex: 10,
                  }}
                >
                  <span>09:41</span>
                  <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                    <Wifi size={12} />
                    <Battery size={13} />
                  </div>
                </div>

                {/* App Header */}
                <div
                  style={{
                    backgroundColor: AppColors.bgSidebar,
                    padding: "10px 16px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    borderBottom: "1px solid #1E3345",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <div
                      style={{
                        width: "28px",
                        height: "28px",
                        borderRadius: "8px",
                        backgroundColor: AppColors.primaryEmerald,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#FFFFFF",
                        fontSize: "0.85rem",
                        fontWeight: 800,
                      }}
                    >
                      <Plus size={16} strokeWidth={3.5} />
                    </div>
                    <div>
                      <div style={{ fontSize: "0.82rem", fontWeight: 700, color: "#FFFFFF" }}>
                        X Medica POS
                      </div>
                      <div style={{ fontSize: "0.65rem", color: AppColors.emeraldLight }}>
                        Online • Live Counter Sync
                      </div>
                    </div>
                  </div>
                  <span
                    style={{
                      fontSize: "0.65rem",
                      backgroundColor: "rgba(16, 185, 129, 0.2)",
                      color: AppColors.emeraldLight,
                      padding: "2px 6px",
                      borderRadius: "4px",
                      fontWeight: 600,
                    }}
                  >
                    Play Store v1.0
                  </span>
                </div>

                {/* In-App Screen Content (Interactive Dynamic Tabs) */}
                <div
                  style={{
                    flex: 1,
                    backgroundColor: "#0D1822",
                    padding: "14px",
                    display: "flex",
                    flexDirection: "column",
                    gap: "10px",
                    overflowY: "auto",
                  }}
                >
                  {mobileFeatureTab === "pos" && (
                    <>
                      {/* Barcode Scanned Medicine Box */}
                      <div
                        style={{
                          backgroundColor: "#132230",
                          borderRadius: "12px",
                          padding: "12px",
                          border: "1px solid #1E3345",
                        }}
                      >
                        <div
                          style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            marginBottom: "6px",
                          }}
                        >
                          <span style={{ fontSize: "0.7rem", color: "#94A3B8", fontWeight: 600 }}>
                            BARCODE SCANNED (120ms)
                          </span>
                          <span
                            style={{
                              fontSize: "0.68rem",
                              color: AppColors.emeraldLight,
                              fontWeight: 600,
                              display: "flex",
                              alignItems: "center",
                              gap: "3px",
                            }}
                          >
                            <CheckCircle size={11} /> 890111700234
                          </span>
                        </div>
                        <div style={{ fontSize: "0.92rem", fontWeight: 700, color: "#FFFFFF" }}>
                          Augmentin 625 Duo Tab
                        </div>
                        <div
                          style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "6px",
                            fontSize: "0.7rem",
                            color: "#94A3B8",
                            marginTop: "2px",
                          }}
                        >
                          <span>Batch: AUG892</span>
                          <span>•</span>
                          <span style={{ color: AppColors.emeraldLight }}>Exp: 11/26</span>
                          <span>•</span>
                          <span>Rack: A2-04</span>
                        </div>
                        <div
                          style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            marginTop: "8px",
                            paddingTop: "6px",
                            borderTop: "1px solid #1E3345",
                          }}
                        >
                          <span style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
                            MRP: ₹223.50 (GST 12%)
                          </span>
                          <span
                            style={{
                              fontSize: "0.95rem",
                              fontWeight: 800,
                              color: AppColors.emeraldLight,
                            }}
                          >
                            ₹201.15
                          </span>
                        </div>
                      </div>

                      {/* Current Bill Items */}
                      <div
                        style={{
                          backgroundColor: "#132230",
                          borderRadius: "12px",
                          padding: "12px",
                          border: "1px solid #1E3345",
                        }}
                      >
                        <div
                          style={{
                            fontSize: "0.7rem",
                            fontWeight: 700,
                            color: "#94A3B8",
                            marginBottom: "6px",
                            display: "flex",
                            justifyContent: "space-between",
                          }}
                        >
                          <span>ACTIVE COUNTER BILL</span>
                          <span style={{ color: AppColors.emeraldLight }}>2 Items</span>
                        </div>
                        <div
                          style={{
                            display: "flex",
                            justifyContent: "space-between",
                            fontSize: "0.75rem",
                            color: "#E2E8F0",
                            marginBottom: "4px",
                          }}
                        >
                          <span>1x Pan D Capsule</span>
                          <span style={{ fontWeight: 600 }}>₹142.00</span>
                        </div>
                        <div
                          style={{
                            display: "flex",
                            justifyContent: "space-between",
                            fontSize: "0.75rem",
                            color: "#E2E8F0",
                          }}
                        >
                          <span>1x Augmentin 625 Duo</span>
                          <span style={{ fontWeight: 600 }}>₹201.15</span>
                        </div>
                        <div
                          style={{
                            marginTop: "8px",
                            paddingTop: "6px",
                            borderTop: "1px dashed #1E3345",
                            display: "flex",
                            justifyContent: "space-between",
                            fontSize: "0.85rem",
                            fontWeight: 700,
                            color: "#FFFFFF",
                          }}
                        >
                          <span>Bill Total (Inc. GST)</span>
                          <span style={{ color: AppColors.emeraldLight }}>₹343.15</span>
                        </div>
                      </div>

                      {/* Bluetooth Print Button */}
                      <button
                        style={{
                          backgroundColor: AppColors.primaryEmerald,
                          color: "#FFFFFF",
                          padding: "10px",
                          borderRadius: "10px",
                          fontSize: "0.85rem",
                          fontWeight: 700,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                          marginTop: "auto",
                        }}
                      >
                        <FileText size={15} />
                        <span>Print Bill (Sunmi / Bluetooth POS)</span>
                      </button>
                    </>
                  )}

                  {mobileFeatureTab === "fefo" && (
                    <>
                      <div
                        style={{
                          backgroundColor: "#132230",
                          borderRadius: "12px",
                          padding: "12px",
                          border: "1px solid #1E3345",
                        }}
                      >
                        <div
                          style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "6px",
                            color: AppColors.crimsonAlert,
                            fontSize: "0.75rem",
                            fontWeight: 700,
                            marginBottom: "6px",
                          }}
                        >
                          <AlertTriangle size={14} />
                          <span>EXPIRY QUARANTINE RADAR</span>
                        </div>
                        <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#FFFFFF" }}>
                          Cipcal 500mg (15 Tabs)
                        </div>
                        <div style={{ fontSize: "0.7rem", color: "#94A3B8" }}>
                          Batch: CIP-304 | Expires in 18 days
                        </div>
                        <div
                          style={{
                            marginTop: "8px",
                            backgroundColor: "rgba(239, 68, 68, 0.15)",
                            padding: "6px",
                            borderRadius: "6px",
                            fontSize: "0.7rem",
                            color: "#FCA5A5",
                          }}
                        >
                          Status: Automatically blocked from counter billing
                        </div>
                      </div>

                      <div
                        style={{
                          backgroundColor: "#132230",
                          borderRadius: "12px",
                          padding: "12px",
                          border: "1px solid #1E3345",
                        }}
                      >
                        <div
                          style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "6px",
                            color: AppColors.amberWarning,
                            fontSize: "0.75rem",
                            fontWeight: 700,
                            marginBottom: "6px",
                          }}
                        >
                          <Clock size={14} />
                          <span>NEAR EXPIRY (60 DAYS)</span>
                        </div>
                        <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#FFFFFF" }}>
                          Telma 40mg (Strip of 10)
                        </div>
                        <div style={{ fontSize: "0.7rem", color: "#94A3B8" }}>
                          Batch: TL-991 | Qty: 14 strips | Supplier: Glenmark
                        </div>
                      </div>
                    </>
                  )}

                  {mobileFeatureTab === "crm" && (
                    <>
                      <div
                        style={{
                          backgroundColor: "#132230",
                          borderRadius: "12px",
                          padding: "12px",
                          border: "1px solid #1E3345",
                        }}
                      >
                        <div
                          style={{
                            display: "flex",
                            justifyContent: "space-between",
                            alignItems: "center",
                            marginBottom: "6px",
                          }}
                        >
                          <span style={{ fontSize: "0.72rem", color: AppColors.emeraldLight, fontWeight: 700 }}>
                            CHRONIC REFILL DUE TODAY
                          </span>
                          <span style={{ fontSize: "0.68rem", color: "#94A3B8" }}>Hypertension</span>
                        </div>
                        <div style={{ fontSize: "0.88rem", fontWeight: 700, color: "#FFFFFF" }}>
                          Ramesh Verma (+91 98765-XXXXX)
                        </div>
                        <div style={{ fontSize: "0.7rem", color: "#94A3B8", marginTop: "2px" }}>
                          Rx: Amlodac 5mg (30-day supply ended yesterday)
                        </div>
                        <button
                          style={{
                            width: "100%",
                            marginTop: "10px",
                            backgroundColor: "#25D366",
                            color: "#FFFFFF",
                            padding: "8px",
                            borderRadius: "8px",
                            fontSize: "0.75rem",
                            fontWeight: 700,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            gap: "5px",
                          }}
                        >
                          <Send size={13} />
                          <span>Dispatch 1-Click WhatsApp Refill</span>
                        </button>
                      </div>
                    </>
                  )}
                </div>

                {/* Interactive In-Phone Tab Bar */}
                <div
                  style={{
                    height: "54px",
                    backgroundColor: "#0B1917",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-around",
                    borderTop: "1px solid #1E3345",
                    padding: "0 10px",
                  }}
                >
                  <button
                    onClick={() => setMobileFeatureTab("pos")}
                    style={{
                      background: "none",
                      color: mobileFeatureTab === "pos" ? AppColors.emeraldLight : "#64748B",
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      gap: "2px",
                      fontSize: "0.65rem",
                      fontWeight: 700,
                    }}
                  >
                    <Scan size={16} />
                    <span>POS Counter</span>
                  </button>

                  <button
                    onClick={() => setMobileFeatureTab("fefo")}
                    style={{
                      background: "none",
                      color: mobileFeatureTab === "fefo" ? AppColors.emeraldLight : "#64748B",
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      gap: "2px",
                      fontSize: "0.65rem",
                      fontWeight: 700,
                    }}
                  >
                    <AlertTriangle size={16} />
                    <span>FEFO Radar</span>
                  </button>

                  <button
                    onClick={() => setMobileFeatureTab("crm")}
                    style={{
                      background: "none",
                      color: mobileFeatureTab === "crm" ? AppColors.emeraldLight : "#64748B",
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      gap: "2px",
                      fontSize: "0.65rem",
                      fontWeight: 700,
                    }}
                  >
                    <Send size={16} />
                    <span>WhatsApp CRM</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Explanatory Content for Mobile */}
            <div>
              <div
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "0.4rem",
                  padding: "0.3rem 0.8rem",
                  borderRadius: "6px",
                  backgroundColor: AppColors.tealSurface,
                  color: AppColors.deepTeal,
                  fontSize: "0.8rem",
                  fontWeight: 700,
                  marginBottom: "1rem",
                }}
              >
                <Smartphone size={14} />
                <span>Google Play Store Edition</span>
              </div>

              <h3
                style={{
                  fontSize: "clamp(1.6rem, 3vw, 2.2rem)",
                  fontWeight: 800,
                  color: AppColors.textPrimary,
                  marginBottom: "1rem",
                  letterSpacing: "-0.02em",
                  lineHeight: 1.25,
                }}
              >
                Turn Any Android Tablet or Phone into a High-Speed Billing Counter
              </h3>

              <p
                style={{
                  fontSize: "1.02rem",
                  color: AppColors.textSecondary,
                  lineHeight: 1.6,
                  marginBottom: "1.5rem",
                }}
              >
                Built specifically for retail chemists during peak rush hours. Scan barcodes directly with the
                phone camera or connect Sunmi/ESC POS Bluetooth thermal printers. Never keep patients waiting.
              </p>

              {/* Feature Checklist */}
              <div style={{ display: "flex", flexDirection: "column", gap: "1rem", marginBottom: "2rem" }}>
                <div style={{ display: "flex", alignItems: "flex-start", gap: "0.75rem" }}>
                  <div
                    style={{
                      width: "24px",
                      height: "24px",
                      borderRadius: "6px",
                      backgroundColor: AppColors.tealSurface,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: AppColors.primaryEmerald,
                      flexShrink: 0,
                    }}
                  >
                    <CheckCircle size={15} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: "0.95rem", color: AppColors.textPrimary }}>
                      Instant Barcode Scanning (&lt;120ms)
                    </div>
                    <div style={{ fontSize: "0.85rem", color: AppColors.textSecondary }}>
                      Scan medicine box EAN/UPC barcodes in under 120ms even under dim dispensary lights.
                    </div>
                  </div>
                </div>

                <div style={{ display: "flex", alignItems: "flex-start", gap: "0.75rem" }}>
                  <div
                    style={{
                      width: "24px",
                      height: "24px",
                      borderRadius: "6px",
                      backgroundColor: AppColors.tealSurface,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: AppColors.primaryEmerald,
                      flexShrink: 0,
                    }}
                  >
                    <CheckCircle size={15} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: "0.95rem", color: AppColors.textPrimary }}>
                      Instant Bluetooth POS Thermal Printing
                    </div>
                    <div style={{ fontSize: "0.85rem", color: AppColors.textSecondary }}>
                      Compatible with 2-inch and 3-inch roll receipt printers with customized dispensary headers.
                    </div>
                  </div>
                </div>

                <div style={{ display: "flex", alignItems: "flex-start", gap: "0.75rem" }}>
                  <div
                    style={{
                      width: "24px",
                      height: "24px",
                      borderRadius: "6px",
                      backgroundColor: AppColors.tealSurface,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: AppColors.primaryEmerald,
                      flexShrink: 0,
                    }}
                  >
                    <CheckCircle size={15} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: "0.95rem", color: AppColors.textPrimary }}>
                      Offline-First Resilience
                    </div>
                    <div style={{ fontSize: "0.85rem", color: AppColors.textSecondary }}>
                      Keep billing even during internet outages; local storage auto-syncs when reconnecting.
                    </div>
                  </div>
                </div>
              </div>

              {/* Play Store CTA */}
              <button
                onClick={onOpenPlayStoreModal}
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "0.65rem",
                  padding: "0.85rem 1.6rem",
                  borderRadius: "12px",
                  backgroundColor: AppColors.bgSidebar,
                  color: "#FFFFFF",
                  fontWeight: 700,
                  fontSize: "0.95rem",
                  boxShadow: "0 6px 20px rgba(11,25,23,0.3)",
                }}
              >
                <span>Get on Google Play Store</span>
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        ) : (
          /* WEB ERP SHOWCASE */
          <div
            style={{
              backgroundColor: AppColors.white,
              borderRadius: "24px",
              border: `1px solid ${AppColors.borderSubtle}`,
              boxShadow: "0 20px 40px -10px rgba(0,0,0,0.08)",
              overflow: "hidden",
            }}
          >
            {/* Browser Header Bar */}
            <div
              style={{
                backgroundColor: AppColors.bgSidebar,
                padding: "10px 16px",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                borderBottom: "1px solid #1E3345",
                gap: "8px",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px", minWidth: 0 }}>
                <div style={{ display: "flex", gap: "5px", flexShrink: 0 }}>
                  <div style={{ width: "9px", height: "9px", borderRadius: "50%", backgroundColor: "#EF4444" }} />
                  <div style={{ width: "9px", height: "9px", borderRadius: "50%", backgroundColor: "#F59E0B" }} />
                  <div style={{ width: "9px", height: "9px", borderRadius: "50%", backgroundColor: "#10B981" }} />
                </div>
                <span
                  className="browser-url-text"
                  style={{
                    fontSize: "0.75rem",
                    color: "#94A3B8",
                    fontFamily: "var(--font-mono)",
                    backgroundColor: "rgba(255,255,255,0.08)",
                    padding: "3px 10px",
                    borderRadius: "6px",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                >
                  https://app.xmedica.com/dashboard
                </span>
              </div>
              <span
                className="browser-ssl-text"
                style={{
                  fontSize: "0.72rem",
                  color: AppColors.emeraldLight,
                  display: "flex",
                  alignItems: "center",
                  gap: "4px",
                  fontWeight: 600,
                  flexShrink: 0,
                }}
              >
                <Shield size={12} /> 256-Bit SSL
              </span>
            </div>

            {/* Dashboard Content Mockup */}
            <div style={{ padding: "clamp(1rem, 3vw, 2rem)", backgroundColor: AppColors.bgPrimary }}>
              {/* Executive KPI Bar */}
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 190px), 1fr))",
                  gap: "1rem",
                  marginBottom: "1.5rem",
                }}
              >
                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted, fontWeight: 600 }}>
                    TODAY'S COUNTER REVENUE
                  </div>
                  <div
                    style={{
                      fontSize: "1.6rem",
                      fontWeight: 800,
                      color: AppColors.primaryEmerald,
                      margin: "4px 0",
                    }}
                    className="tabular-nums"
                  >
                    ₹48,920.50
                  </div>
                  <div style={{ fontSize: "0.72rem", color: AppColors.primaryEmerald, fontWeight: 600 }}>
                    ↑ +14.2% vs yesterday (162 Bills)
                  </div>
                </div>

                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted, fontWeight: 600 }}>
                    FEFO QUARANTINE ITEMS
                  </div>
                  <div
                    style={{
                      fontSize: "1.6rem",
                      fontWeight: 800,
                      color: AppColors.crimsonAlert,
                      margin: "4px 0",
                    }}
                    className="tabular-nums"
                  >
                    3 Batches
                  </div>
                  <div style={{ fontSize: "0.72rem", color: AppColors.crimsonAlert, fontWeight: 600 }}>
                    Action taken: Blocked from billing
                  </div>
                </div>

                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted, fontWeight: 600 }}>
                    PHYSICAL RACKS & COLD UNITS
                  </div>
                  <div
                    style={{
                      fontSize: "1.6rem",
                      fontWeight: 800,
                      color: AppColors.primaryCyan,
                      margin: "4px 0",
                    }}
                    className="tabular-nums"
                  >
                    18 Units (4.2°C)
                  </div>
                  <div style={{ fontSize: "0.72rem", color: AppColors.textSecondary }}>
                    Cold storage insulin telemetry OK
                  </div>
                </div>

                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted, fontWeight: 600 }}>
                    CHRONIC REFILLS ENGAGED
                  </div>
                  <div
                    style={{
                      fontSize: "1.6rem",
                      fontWeight: 800,
                      color: AppColors.deepTeal,
                      margin: "4px 0",
                    }}
                    className="tabular-nums"
                  >
                    92%
                  </div>
                  <div style={{ fontSize: "0.72rem", color: AppColors.deepTeal, fontWeight: 600 }}>
                    42 WhatsApp alerts sent
                  </div>
                </div>
              </div>

              {/* Backoffice Grid: Rack Navigator & Daybook */}
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 280px), 1fr))",
                  gap: "1.5rem",
                }}
              >
                {/* Rack & Shelf Navigator */}
                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      marginBottom: "1rem",
                    }}
                  >
                    <div style={{ fontWeight: 700, fontSize: "0.95rem", color: AppColors.textPrimary }}>
                      Physical Rack &amp; Shelf Locator
                    </div>
                    <span
                      style={{
                        fontSize: "0.72rem",
                        backgroundColor: AppColors.tealSurface,
                        color: AppColors.deepTeal,
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontWeight: 700,
                      }}
                    >
                      Instant Drug Finder
                    </span>
                  </div>

                  <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
                    <div
                      style={{
                        padding: "8px 12px",
                        backgroundColor: AppColors.frostMint,
                        borderRadius: "8px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        fontSize: "0.82rem",
                      }}
                    >
                      <div>
                        <strong>Rack A1 (Antibiotics)</strong>
                        <div style={{ fontSize: "0.72rem", color: AppColors.textMuted }}>
                          Shelf 02 • 14 Molecules
                        </div>
                      </div>
                      <span style={{ color: AppColors.primaryEmerald, fontWeight: 700 }}>In Stock</span>
                    </div>

                    <div
                      style={{
                        padding: "8px 12px",
                        backgroundColor: AppColors.frostMint,
                        borderRadius: "8px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        fontSize: "0.82rem",
                      }}
                    >
                      <div>
                        <strong>Unit C1 (Cold Storage 2°C–8°C)</strong>
                        <div style={{ fontSize: "0.72rem", color: AppColors.textMuted }}>
                          Insulin, Vaccines, Biologicals
                        </div>
                      </div>
                      <span style={{ color: AppColors.primaryCyan, fontWeight: 700 }}>Telemetry 3.8°C</span>
                    </div>

                    <div
                      style={{
                        padding: "8px 12px",
                        backgroundColor: AppColors.frostMint,
                        borderRadius: "8px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        fontSize: "0.82rem",
                      }}
                    >
                      <div>
                        <strong>Vault S (Schedule H/H1 Narcotics)</strong>
                        <div style={{ fontSize: "0.72rem", color: AppColors.textMuted }}>
                          Double-verification mandatory
                        </div>
                      </div>
                      <span style={{ color: AppColors.amberWarning, fontWeight: 700 }}>Locked</span>
                    </div>
                  </div>
                </div>

                {/* Double-Entry Daybook & Settlement */}
                <div
                  style={{
                    backgroundColor: AppColors.white,
                    padding: "1.25rem",
                    borderRadius: "14px",
                    border: `1px solid ${AppColors.borderSubtle}`,
                  }}
                >
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      marginBottom: "1rem",
                    }}
                  >
                    <div style={{ fontWeight: 700, fontSize: "0.95rem", color: AppColors.textPrimary }}>
                      Double-Entry Daybook Ledger
                    </div>
                    <span
                      style={{
                        fontSize: "0.72rem",
                        backgroundColor: "rgba(6, 182, 212, 0.15)",
                        color: AppColors.primaryCyan,
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontWeight: 700,
                      }}
                    >
                      Reconciled
                    </span>
                  </div>

                  <div style={{ width: "100%", overflowX: "auto" }}>
                    <table style={{ width: "100%", minWidth: "260px", fontSize: "0.82rem", borderCollapse: "collapse" }}>
                      <thead>
                        <tr style={{ color: AppColors.textMuted, borderBottom: `1px solid ${AppColors.borderSubtle}` }}>
                          <th style={{ textAlign: "left", paddingBottom: "6px" }}>Account Head</th>
                          <th style={{ textAlign: "right", paddingBottom: "6px" }}>Debit</th>
                          <th style={{ textAlign: "right", paddingBottom: "6px" }}>Credit</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr style={{ borderBottom: `1px solid ${AppColors.frostMint}` }}>
                          <td style={{ padding: "6px 0" }}>Cash in Dispensary Drawer</td>
                          <td style={{ textAlign: "right", fontWeight: 700, color: AppColors.primaryEmerald }}>
                            ₹22,400.00
                          </td>
                          <td style={{ textAlign: "right", color: AppColors.textMuted }}>-</td>
                        </tr>
                        <tr style={{ borderBottom: `1px solid ${AppColors.frostMint}` }}>
                          <td style={{ padding: "6px 0" }}>UPI / QR Direct Settlement</td>
                          <td style={{ textAlign: "right", fontWeight: 700, color: AppColors.primaryEmerald }}>
                            ₹26,520.50
                          </td>
                          <td style={{ textAlign: "right", color: AppColors.textMuted }}>-</td>
                        </tr>
                        <tr>
                          <td style={{ padding: "6px 0" }}>Stockist AP (Procurement)</td>
                          <td style={{ textAlign: "right", color: AppColors.textMuted }}>-</td>
                          <td style={{ textAlign: "right", fontWeight: 700, color: AppColors.crimsonAlert }}>
                            ₹18,150.00
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>

              {/* Web App CTA Button */}
              <div style={{ marginTop: "1.75rem", textAlign: "center" }}>
                <a
                  href={AppConfig.webAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "0.5rem",
                    padding: "0.85rem 1.75rem",
                    borderRadius: "12px",
                    backgroundColor: AppColors.primaryEmerald,
                    color: "#FFFFFF",
                    fontWeight: 700,
                    fontSize: "0.95rem",
                    textDecoration: "none",
                    boxShadow: `0 8px 20px ${AppColors.emeraldGlow}`,
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = AppColors.primaryEmeraldHover;
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = AppColors.primaryEmerald;
                  }}
                >
                  <span>Launch Cloud Web App (Port 5096)</span>
                  <ExternalLink size={16} />
                </a>
              </div>
            </div>
          </div>
        )}
      </div>

      <style>{`
        @media (max-width: 640px) {
          .platform-switcher-container {
            width: 100% !important;
          }
          .platform-switcher-btn {
            width: 100% !important;
            justify-content: center !important;
          }
          .browser-url-text {
            max-width: 130px !important;
          }
          .browser-ssl-text {
            display: none !important;
          }
        }
      `}</style>
    </section>
  );
};
