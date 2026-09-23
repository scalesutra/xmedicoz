import React from "react";
import { Plus, Smartphone, ShieldCheck, Heart, Trash2, Shield, FileText, RefreshCw, Mail } from "lucide-react";
import { AppColors } from "../theme/colors";
import { LegalDocType } from "./LegalModal";
import { AppConfig } from "../config/appConfig";

interface FooterProps {
  onOpenPlayStoreModal: () => void;
  onOpenLegalModal: (doc: LegalDocType) => void;
}

export const Footer: React.FC<FooterProps> = ({
  onOpenPlayStoreModal,
  onOpenLegalModal,
}) => {
  return (
    <footer
      style={{
        backgroundColor: AppColors.bgSidebar,
        color: "#FFFFFF",
        borderTop: "1px solid #1E3345",
        paddingTop: "75px",
        paddingBottom: "40px",
      }}
    >
      <div className="container-custom">
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(210px, 1fr))",
            gap: "2.5rem",
            marginBottom: "3.5rem",
          }}
        >
          {/* Col 1: Brand & Play Store */}
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "0.65rem", marginBottom: "1rem" }}>
              <div
                style={{
                  width: "38px",
                  height: "38px",
                  borderRadius: "10px",
                  background: `linear-gradient(135deg, ${AppColors.primaryEmerald} 0%, ${AppColors.deepTeal} 100%)`,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#FFFFFF",
                }}
              >
                <Plus size={22} strokeWidth={3.5} />
              </div>
              <span style={{ fontSize: "1.35rem", fontWeight: 800, letterSpacing: "-0.02em" }}>
                X Medica
              </span>
            </div>

            <p style={{ fontSize: "0.85rem", color: "#94A3B8", lineHeight: 1.6, marginBottom: "1.25rem" }}>
              The high-performance autonomous operating suite for medical stores, dispensaries, and retail pharmacies.
            </p>

            <button
              onClick={onOpenPlayStoreModal}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "0.5rem",
                padding: "0.6rem 1.1rem",
                borderRadius: "10px",
                backgroundColor: "rgba(255, 255, 255, 0.08)",
                color: "#FFFFFF",
                fontSize: "0.85rem",
                fontWeight: 600,
                border: "1px solid rgba(255, 255, 255, 0.15)",
              }}
            >
              <Smartphone size={16} color={AppColors.emeraldLight} />
              <span>Get on Google Play</span>
            </button>
          </div>

          {/* Col 2: Platform & Features */}
          <div>
            <div style={{ fontSize: "0.92rem", fontWeight: 700, marginBottom: "1.1rem", color: "#E2E8F0" }}>
              Platform &amp; Apps
            </div>
            <ul style={{ listStyle: "none", display: "flex", flexDirection: "column", gap: "0.7rem", fontSize: "0.85rem", color: "#94A3B8" }}>
              <li>
                <a href="#playstore" onClick={onOpenPlayStoreModal} style={{ color: "#94A3B8" }}>
                  Android Play Store App
                </a>
              </li>
              <li>
                <a
                  href={AppConfig.webAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{ color: "#94A3B8" }}
                >
                  Launch Web App (Port 5096)
                </a>
              </li>
              <li>
                <a href="#features" style={{ color: "#94A3B8" }}>
                  Counter POS &amp; Thermal Printing
                </a>
              </li>
              <li>
                <a href="#features" style={{ color: "#94A3B8" }}>
                  FEFO Expiry Batch Radar
                </a>
              </li>
              <li>
                <a href="#features" style={{ color: "#94A3B8" }}>
                  WhatsApp Chronic Refill CRM
                </a>
              </li>
            </ul>
          </div>

          {/* Col 3: Compliance & Backoffice */}
          <div>
            <div style={{ fontSize: "0.92rem", fontWeight: 700, marginBottom: "1.1rem", color: "#E2E8F0" }}>
              Compliance &amp; Finance
            </div>
            <ul style={{ listStyle: "none", display: "flex", flexDirection: "column", gap: "0.7rem", fontSize: "0.85rem", color: "#94A3B8" }}>
              <li>
                <a href="#compliance" style={{ color: "#94A3B8" }}>
                  Schedule H &amp; H1 Narcotic Registers
                </a>
              </li>
              <li>
                <a href="#compliance" style={{ color: "#94A3B8" }}>
                  GST e-Invoicing &amp; HSN Lookups
                </a>
              </li>
              <li>
                <a href="#showcase" style={{ color: "#94A3B8" }}>
                  Cold Storage 2°C–8°C Units
                </a>
              </li>
              <li>
                <a href="#showcase" style={{ color: "#94A3B8" }}>
                  Double-Entry Daybook Ledger
                </a>
              </li>
              <li>
                <a href="#roi" style={{ color: "#94A3B8" }}>
                  ROI &amp; Expiry Loss Calculator
                </a>
              </li>
            </ul>
          </div>

          {/* Col 4: Mandatory Google Play Legal Policies */}
          <div>
            <div style={{ fontSize: "0.92rem", fontWeight: 700, marginBottom: "1.1rem", color: "#E2E8F0" }}>
              Mandatory Legal &amp; Policies
            </div>
            <ul style={{ listStyle: "none", display: "flex", flexDirection: "column", gap: "0.7rem", fontSize: "0.85rem" }}>
              <li>
                <button
                  onClick={() => onOpenLegalModal("privacy")}
                  style={{
                    background: "none",
                    color: AppColors.emeraldLight,
                    textAlign: "left",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    fontWeight: 600,
                  }}
                >
                  <Shield size={14} />
                  <span>Privacy Policy (Play Store)</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenLegalModal("delete-account")}
                  style={{
                    background: "none",
                    color: "#FCA5A5",
                    textAlign: "left",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                    fontWeight: 600,
                  }}
                >
                  <Trash2 size={14} />
                  <span>Delete Account &amp; Data</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenLegalModal("terms")}
                  style={{
                    background: "none",
                    color: "#94A3B8",
                    textAlign: "left",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                >
                  <FileText size={14} />
                  <span>Terms of Service</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenLegalModal("refund")}
                  style={{
                    background: "none",
                    color: "#94A3B8",
                    textAlign: "left",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                >
                  <RefreshCw size={14} />
                  <span>Refund &amp; Cancellation Policy</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenLegalModal("grievance")}
                  style={{
                    background: "none",
                    color: "#94A3B8",
                    textAlign: "left",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                >
                  <Mail size={14} />
                  <span>Grievance Officer (IT Rules)</span>
                </button>
              </li>
            </ul>
          </div>
        </div>

        {/* Regulatory & Google Play Requirement Note */}
        <div
          style={{
            padding: "1.25rem",
            backgroundColor: "rgba(255, 255, 255, 0.03)",
            borderRadius: "14px",
            border: "1px solid rgba(255, 255, 255, 0.06)",
            fontSize: "0.78rem",
            color: "#64748B",
            lineHeight: 1.6,
            marginBottom: "2rem",
            display: "flex",
            alignItems: "flex-start",
            gap: "0.75rem",
          }}
        >
          <ShieldCheck size={18} color={AppColors.emeraldLight} style={{ flexShrink: 0, marginTop: "2px" }} />
          <div>
            <strong>Google Play Developer &amp; CDSCO Regulatory Adherence:</strong> X Medica complies with Google Play Developer Policies (Account Deletion &amp; Sensitive Health Data Protection), the Drugs and Cosmetics Act 1940, Schedule H/H1 registers, and Digital Personal Data Protection (DPDP) Act.
          </div>
        </div>

        {/* Bottom Bar with Quick Legal Links */}
        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "1rem",
            fontSize: "0.82rem",
            color: "#64748B",
            borderTop: "1px solid rgba(255, 255, 255, 0.08)",
            paddingTop: "1.5rem",
          }}
        >
          <div>
            © {new Date().getFullYear()} X Medica. All rights reserved.
          </div>

          <div style={{ display: "flex", flexWrap: "wrap", alignItems: "center", gap: "1.25rem", fontSize: "0.8rem" }}>
            <button onClick={() => onOpenLegalModal("privacy")} style={{ background: "none", color: "#94A3B8" }}>
              Privacy Policy
            </button>
            <button onClick={() => onOpenLegalModal("delete-account")} style={{ background: "none", color: "#FCA5A5" }}>
              Delete Account
            </button>
            <button onClick={() => onOpenLegalModal("terms")} style={{ background: "none", color: "#94A3B8" }}>
              Terms of Service
            </button>
            <button onClick={() => onOpenLegalModal("grievance")} style={{ background: "none", color: "#94A3B8" }}>
              Grievance Officer
            </button>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
            <span>Crafted for retail pharmacists with</span>
            <Heart size={14} color={AppColors.crimsonAlert} fill={AppColors.crimsonAlert} />
          </div>
        </div>
      </div>
    </footer>
  );
};
