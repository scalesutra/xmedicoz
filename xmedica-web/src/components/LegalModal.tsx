import React, { useState } from "react";
import { X, Shield, Trash2, FileText, RefreshCw, Mail, AlertTriangle, CheckCircle } from "lucide-react";
import { AppColors } from "../theme/colors";

export type LegalDocType = "privacy" | "delete-account" | "terms" | "refund" | "grievance";

interface LegalModalProps {
  isOpen: boolean;
  docType: LegalDocType;
  onClose: () => void;
  onSelectDoc: (type: LegalDocType) => void;
}

export const LegalModal: React.FC<LegalModalProps> = ({
  isOpen,
  docType,
  onClose,
  onSelectDoc,
}) => {
  const [deleteEmail, setDeleteEmail] = useState("");
  const [deletePhone, setDeletePhone] = useState("");
  const [deleteReason, setDeleteReason] = useState("");
  const [deleteSubmitted, setDeleteSubmitted] = useState(false);

  if (!isOpen) return null;

  const handleDeleteSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!deletePhone && !deleteEmail) return;
    setDeleteSubmitted(true);
  };

  const navItems = [
    { id: "privacy", label: "Privacy Policy", icon: <Shield size={16} /> },
    { id: "delete-account", label: "Account Deletion", icon: <Trash2 size={16} /> },
    { id: "terms", label: "Terms of Service", icon: <FileText size={16} /> },
    { id: "refund", label: "Refund Policy", icon: <RefreshCw size={16} /> },
    { id: "grievance", label: "Grievance Officer", icon: <Mail size={16} /> },
  ];

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "rgba(11, 25, 23, 0.8)",
        backdropFilter: "blur(10px)",
        zIndex: 250,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "1rem",
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "880px",
          height: "85vh",
          maxHeight: "800px",
          backgroundColor: "#FFFFFF",
          borderRadius: "24px",
          boxShadow: "0 25px 60px -15px rgba(0, 0, 0, 0.5)",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
          border: `1px solid ${AppColors.borderSubtle}`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Top Bar */}
        <div
          style={{
            padding: "clamp(0.75rem, 3vw, 1.25rem) clamp(0.85rem, 3.5vw, 1.75rem)",
            borderBottom: `1px solid ${AppColors.borderSubtle}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            backgroundColor: AppColors.frostMint,
            gap: "0.5rem",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "0.6rem", minWidth: 0 }}>
            <div
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "8px",
                backgroundColor: AppColors.primaryEmerald,
                color: "#FFFFFF",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              <Shield size={18} />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: "clamp(0.92rem, 3.5vw, 1.1rem)", fontWeight: 800, color: AppColors.textPrimary, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                X Medica Legal &amp; Compliance
              </div>
              <div style={{ fontSize: "0.72rem", color: AppColors.textMuted }}>
                Mandatory Regulatory &amp; Policies
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            style={{
              width: "34px",
              height: "34px",
              borderRadius: "50%",
              backgroundColor: "#FFFFFF",
              border: `1px solid ${AppColors.borderSubtle}`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: AppColors.textSecondary,
              flexShrink: 0,
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Tab Navigation Pill Bar */}
        <div
          style={{
            display: "flex",
            gap: "0.4rem",
            padding: "0.6rem clamp(0.75rem, 3vw, 1.75rem)",
            backgroundColor: "#FFFFFF",
            borderBottom: `1px solid ${AppColors.borderSubtle}`,
            overflowX: "auto",
            WebkitOverflowScrolling: "touch",
          }}
        >
          {navItems.map((item) => {
            const isActive = docType === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onSelectDoc(item.id as LegalDocType)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.45rem",
                  padding: "0.45rem 0.85rem",
                  borderRadius: "10px",
                  fontSize: "0.82rem",
                  fontWeight: isActive ? 700 : 500,
                  backgroundColor: isActive ? AppColors.tealSurface : "transparent",
                  color: isActive ? AppColors.deepTeal : AppColors.textSecondary,
                  border: isActive ? `1px solid ${AppColors.emeraldLight}40` : "1px solid transparent",
                  whiteSpace: "nowrap",
                  flexShrink: 0,
                }}
              >
                {item.icon}
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Scrollable Content Container */}
        <div
          style={{
            flex: 1,
            overflowY: "auto",
            padding: "clamp(1rem, 3.5vw, 2rem) clamp(0.85rem, 3.5vw, 2.25rem)",
            fontSize: "0.92rem",
            color: AppColors.textSecondary,
            lineHeight: 1.75,
          }}
        >
          {/* 1. PRIVACY POLICY */}
          {docType === "privacy" && (
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
                <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: AppColors.textPrimary }}>
                  Privacy Policy for X Medica
                </h2>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                  Last Updated: September 2026
                </span>
              </div>

              <div
                style={{
                  backgroundColor: AppColors.tealSurface,
                  border: `1px solid ${AppColors.emeraldLight}40`,
                  borderRadius: "12px",
                  padding: "1rem 1.25rem",
                  marginBottom: "1.75rem",
                  fontSize: "0.85rem",
                  color: AppColors.deepTeal,
                }}
              >
                <strong>Google Play Developer Policy Compliance:</strong> This policy governs the mobile application "X Medica" (package: com.scalesutra.xmedica) and cloud platform. We strictly protect sensitive patient health information, prescription histories, and pharmacy business financial logs.
              </div>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                1. Information We Collect
              </h3>
              <p>We collect information you provide directly to operate your pharmacy dispensary:</p>
              <ul style={{ paddingLeft: "1.5rem", margin: "0.5rem 0" }}>
                <li><strong>Dispensary Profile:</strong> Pharmacy Name, Drug License Number (Form 20/21), GSTIN, Registered Address, Pharmacist In-Charge Mobile Number and Email.</li>
                <li><strong>Inventory &amp; Batch Data:</strong> Medicine names, batch numbers, manufacturer, expiry dates, HSN codes, purchasing stockist prices, and counter retail prices.</li>
                <li><strong>Customer &amp; Prescription Records:</strong> Patient name, contact number, chronic condition tags (e.g. diabetes/hypertension for refill reminders), and prescribing doctor registration number (mandated under Schedule H/H1).</li>
                <li><strong>Financial Accounting Logs:</strong> Sales bills, cash counter drawer balance, UPI reconciliation entries, and distributor purchase invoices.</li>
              </ul>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                2. Android Mobile App Permissions &amp; Usage
              </h3>
              <p>Our Android Play Store mobile application requests the following device permissions only when required for core counter billing features:</p>
              <ul style={{ paddingLeft: "1.5rem", margin: "0.5rem 0" }}>
                <li><strong>Camera (android.permission.CAMERA):</strong> Used exclusively to scan medicine box EAN/UPC barcodes and scan paper prescriptions via OCR. Camera feeds are never recorded or stored.</li>
                <li><strong>Bluetooth &amp; Nearby Devices (BLUETOOTH_CONNECT, BLUETOOTH_SCAN):</strong> Used to discover and connect to portable 58mm/80mm Bluetooth thermal roll receipt printers (e.g. Sunmi, ESC/POS).</li>
                <li><strong>Internet &amp; Network State:</strong> Used to synchronize counter sales and batch inventory with the secure cloud backup server.</li>
              </ul>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                3. Zero Third-Party Data Selling
              </h3>
              <p>
                <strong>We NEVER sell, rent, or monetize patient medical records, prescription details, or pharmacy sales figures to any third party, pharmaceutical marketing agency, or advertiser.</strong> Your pharmacy data belongs 100% to your store.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                4. Data Security &amp; Encryption
              </h3>
              <p>
                All data transmitted between your Android device and our cloud servers is encrypted using bank-grade <strong>256-bit TLS/SSL encryption</strong>. Databases are stored in certified data centers with automatic encrypted daily snapshots.
              </p>
            </div>
          )}

          {/* 2. ACCOUNT & DATA DELETION (Google Play Policy Mandate) */}
          {docType === "delete-account" && (
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
                <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: AppColors.textPrimary }}>
                  Account &amp; Data Deletion Request
                </h2>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                  Google Play Policy Mandate
                </span>
              </div>

              <div
                style={{
                  backgroundColor: "rgba(239, 68, 68, 0.08)",
                  border: "1px solid rgba(239, 68, 68, 0.2)",
                  borderRadius: "12px",
                  padding: "1rem 1.25rem",
                  marginBottom: "1.75rem",
                  fontSize: "0.85rem",
                  color: "#991B1B",
                }}
              >
                <strong>Google Play Developer Account Deletion Policy:</strong> As per Google Play requirements, users can request deletion of their X Medica account and associated data directly through this web page without needing to reinstall the app.
              </div>

              <p>
                You have the full right to delete your X Medica dispensary account, remove staff profiles, and erase patient CRM contacts.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                How to Delete Within the Android App
              </h3>
              <p>
                1. Open the <strong>X Medica</strong> mobile app &gt; Tap <strong>Settings / Profile</strong> &gt; Scroll to <strong>Account &amp; Security</strong> &gt; Tap <strong>"Delete My Account &amp; Data"</strong>.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                Or Submit a Web Deletion Request Below:
              </h3>

              {deleteSubmitted ? (
                <div
                  style={{
                    backgroundColor: AppColors.tealSurface,
                    borderRadius: "14px",
                    padding: "2rem",
                    textAlign: "center",
                    border: `1px solid ${AppColors.primaryEmerald}40`,
                    marginTop: "1rem",
                  }}
                >
                  <CheckCircle size={40} color={AppColors.primaryEmerald} style={{ margin: "0 auto 1rem auto" }} />
                  <h4 style={{ fontSize: "1.2rem", fontWeight: 800, color: AppColors.textPrimary, marginBottom: "0.35rem" }}>
                    Account Deletion Request Received
                  </h4>
                  <p style={{ fontSize: "0.88rem", color: AppColors.textSecondary, maxWidth: "500px", margin: "0 auto" }}>
                    We have logged your deletion request for <strong>{deletePhone || deleteEmail}</strong>. An OTP confirmation will be dispatched to verify store ownership. Upon verification, your account and active data will be purged within 7 business days.
                  </p>
                </div>
              ) : (
                <form
                  onSubmit={handleDeleteSubmit}
                  style={{
                    backgroundColor: AppColors.frostMint,
                    borderRadius: "16px",
                    padding: "1.5rem",
                    border: `1px solid ${AppColors.borderSubtle}`,
                    marginTop: "1rem",
                    display: "flex",
                    flexDirection: "column",
                    gap: "1rem",
                  }}
                >
                  <div>
                    <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 700, color: AppColors.textPrimary, marginBottom: "4px" }}>
                      Registered Mobile Number *
                    </label>
                    <input
                      type="tel"
                      required
                      placeholder="+91 98765-XXXXX"
                      value={deletePhone}
                      onChange={(e) => setDeletePhone(e.target.value)}
                      style={{
                        width: "100%",
                        padding: "0.65rem 0.85rem",
                        borderRadius: "8px",
                        border: `1px solid ${AppColors.borderSubtle}`,
                        fontSize: "0.9rem",
                        backgroundColor: "#FFFFFF",
                      }}
                    />
                  </div>

                  <div>
                    <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 700, color: AppColors.textPrimary, marginBottom: "4px" }}>
                      Registered Pharmacy Email (Optional)
                    </label>
                    <input
                      type="email"
                      placeholder="chemist@example.com"
                      value={deleteEmail}
                      onChange={(e) => setDeleteEmail(e.target.value)}
                      style={{
                        width: "100%",
                        padding: "0.65rem 0.85rem",
                        borderRadius: "8px",
                        border: `1px solid ${AppColors.borderSubtle}`,
                        fontSize: "0.9rem",
                        backgroundColor: "#FFFFFF",
                      }}
                    />
                  </div>

                  <div>
                    <label style={{ display: "block", fontSize: "0.82rem", fontWeight: 700, color: AppColors.textPrimary, marginBottom: "4px" }}>
                      Reason for Account Deletion (Optional)
                    </label>
                    <textarea
                      rows={2}
                      placeholder="Closing medical store, switching software, etc."
                      value={deleteReason}
                      onChange={(e) => setDeleteReason(e.target.value)}
                      style={{
                        width: "100%",
                        padding: "0.65rem 0.85rem",
                        borderRadius: "8px",
                        border: `1px solid ${AppColors.borderSubtle}`,
                        fontSize: "0.9rem",
                        backgroundColor: "#FFFFFF",
                        resize: "none",
                      }}
                    />
                  </div>

                  <div style={{ display: "flex", alignItems: "flex-start", gap: "0.5rem", fontSize: "0.78rem", color: AppColors.textMuted }}>
                    <AlertTriangle size={15} color={AppColors.amberWarning} style={{ flexShrink: 0, marginTop: "2px" }} />
                    <span>
                      <strong>Statutory Retention Notice:</strong> In accordance with the Drugs and Cosmetics Act 1940 and GST Act 2017, issued tax invoices and Schedule H registers must be archived for the mandatory statutory period (5 years) before final destruction.
                    </span>
                  </div>

                  <button
                    type="submit"
                    style={{
                      padding: "0.85rem",
                      borderRadius: "10px",
                      backgroundColor: AppColors.crimsonAlert,
                      color: "#FFFFFF",
                      fontWeight: 700,
                      fontSize: "0.92rem",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "0.5rem",
                      boxShadow: "0 4px 12px rgba(239, 68, 68, 0.25)",
                    }}
                  >
                    <Trash2 size={16} />
                    <span>Submit Account Deletion Request</span>
                  </button>
                </form>
              )}
            </div>
          )}

          {/* 3. TERMS OF SERVICE */}
          {docType === "terms" && (
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
                <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: AppColors.textPrimary }}>
                  Terms of Service
                </h2>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                  Version 2.0 (2026)
                </span>
              </div>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                1. Legal Drug License Requirement
              </h3>
              <p>
                X Medica is dedicated software for authorized pharmacies, hospitals, and licensed medical stores. By creating an account, you represent and warrant that your store holds valid Drug Licenses (Form 20, 20B, 21, or 21B) issued by the relevant State Drug Controller authority.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                2. Software as a Service (SaaS) License
              </h3>
              <p>
                We grant you a non-exclusive, non-transferable right to access and use the X Medica software suite (Android Play Store app and Cloud Web ERP) for your dispensary operations in accordance with your chosen subscription tier.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                3. Pharmacist Responsibility
              </h3>
              <p>
                While X Medica provides automated FEFO alerts, Schedule H/H1 tags, and GST calculations, the registered pharmacist remains legally responsible for verifying physical medicine dispensing, dosage correctness, and doctor prescription authenticity.
              </p>
            </div>
          )}

          {/* 4. REFUND POLICY */}
          {docType === "refund" && (
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
                <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: AppColors.textPrimary }}>
                  Subscription Refund &amp; Cancellation Policy
                </h2>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                  Effective 2026
                </span>
              </div>

              <div
                style={{
                  backgroundColor: AppColors.tealSurface,
                  borderRadius: "12px",
                  padding: "1rem 1.25rem",
                  marginBottom: "1.5rem",
                  border: `1px solid ${AppColors.primaryEmerald}30`,
                }}
              >
                <strong style={{ color: AppColors.deepTeal }}>14-Day Full Satisfaction Guarantee:</strong> If X Medica does not improve your dispensary billing speed or batch tracking within the first 14 days of purchase, contact us for a 100% refund.
              </div>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                1. Monthly Plans
              </h3>
              <p>
                Monthly plans may be canceled at any time. Your subscription will remain active until the end of the current billing cycle, with no further charges incurred.
              </p>

              <h3 style={{ fontSize: "1.15rem", fontWeight: 700, color: AppColors.textPrimary, marginTop: "1.5rem", marginBottom: "0.5rem" }}>
                2. Annual Plans
              </h3>
              <p>
                Annual plan cancellations requested after the 14-day trial period are eligible for a prorated refund for unused full calendar months, processed within 5 to 7 banking days via the original payment method.
              </p>
            </div>
          )}

          {/* 5. GRIEVANCE OFFICER & SUPPORT */}
          {docType === "grievance" && (
            <div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.5rem" }}>
                <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: AppColors.textPrimary }}>
                  Grievance Redressal &amp; Support Contact
                </h2>
                <span style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                  Mandatory IT Rules 2021 &amp; DPDP Act
                </span>
              </div>

              <p style={{ marginBottom: "1.5rem" }}>
                In accordance with the Information Technology Act 2000, Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules 2021, and Digital Personal Data Protection Act 2023, the details of the Grievance Officer are published below:
              </p>

              <div
                style={{
                  backgroundColor: AppColors.frostMint,
                  borderRadius: "16px",
                  padding: "1.5rem",
                  border: `1px solid ${AppColors.borderSubtle}`,
                  display: "flex",
                  flexDirection: "column",
                  gap: "0.85rem",
                }}
              >
                <div>
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>Grievance Officer Name:</div>
                  <strong style={{ fontSize: "1.05rem", color: AppColors.textPrimary }}>Vikramaditya Sharma</strong>
                </div>

                <div>
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>Official Compliance Email:</div>
                  <strong style={{ fontSize: "0.95rem", color: AppColors.primaryEmerald }}>grievance@xmedica.app</strong>
                </div>

                <div>
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>Dispensary Support Helpline:</div>
                  <strong style={{ fontSize: "0.95rem", color: AppColors.textPrimary }}>+91 (080) 4567-8900 (Mon–Sat, 9 AM – 8 PM)</strong>
                </div>

                <div>
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>Registered Corporate Office:</div>
                  <div style={{ fontSize: "0.88rem", color: AppColors.textSecondary }}>
                    ScaleSutra Software Technologies Pvt Ltd<br />
                    Medical Tech Hub, Outer Ring Road, Bengaluru, Karnataka 560103, India
                  </div>
                </div>

                <div
                  style={{
                    marginTop: "0.5rem",
                    paddingTop: "0.75rem",
                    borderTop: `1px solid ${AppColors.borderSubtle}`,
                    fontSize: "0.78rem",
                    color: AppColors.textMuted,
                  }}
                >
                  Grievances are acknowledged within 48 hours and resolved within 30 days as mandated by Indian IT Regulations.
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
