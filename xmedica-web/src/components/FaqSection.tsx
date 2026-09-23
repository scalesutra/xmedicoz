import React, { useState } from "react";
import { ChevronDown, HelpCircle } from "lucide-react";
import { AppColors } from "../theme/colors";

export const FaqSection: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    {
      q: "How do I install X Medica from the Google Play Store?",
      a: "Simply search 'X Medica' on Google Play Store on any Android smartphone, tablet, or Sunmi POS terminal, or click the 'Get on Google Play' button on this site. Tap Install, enter your registered dispensary mobile number, and complete the instant OTP verification to start billing.",
    },
    {
      q: "Does X Medica work with our existing thermal printer and barcode scanner?",
      a: "Yes! X Medica natively supports all standard 58mm (2-inch) and 80mm (3-inch) Bluetooth thermal receipt printers, USB OTG thermal printers, camera-based barcode scanning, and 2.4GHz wireless handheld laser scanners without requiring special drivers.",
    },
    {
      q: "Can I migrate our existing medicine inventory, supplier ledger, and patient records?",
      a: "Absolutely. X Medica provides pre-built 1-click Excel/CSV import templates for medicines, batches, stockist contacts, and customer directories. You can also import existing data from legacy pharmacy software like Marg, RedBook, and Excel in under 10 minutes.",
    },
    {
      q: "What happens if our pharmacy internet connection goes down during rush hour?",
      a: "X Medica features an intelligent Offline First architecture. The mobile app continues issuing bills, scanning barcodes, calculating taxes, and printing receipts uninterrupted. All transactions automatically sync to the secure cloud ledger the moment connectivity resumes.",
    },
    {
      q: "Is X Medica compliant with Schedule H and Schedule H1 narcotic record-keeping?",
      a: "Yes. Every Schedule H and H1 formulation is tagged in the master catalog. During billing, the system prompts for the prescribing physician's registration number and patient details, automatically compiling the mandatory inspection log demanded by Drug Inspectors.",
    },
    {
      q: "Can multiple pharmacy staff members bill from different devices at the same time?",
      a: "Yes! With our Professional and Enterprise plans, multiple staff members can bill concurrently from separate Android phones, tablets, or counter laptops while sharing a live, synchronized stock pool.",
    },
  ];

  return (
    <section id="faq" style={{ padding: "90px 0", backgroundColor: AppColors.bgPrimary }}>
      <div className="container-custom">
        <div style={{ textAlign: "center", maxWidth: "750px", margin: "0 auto 3.5rem auto" }}>
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
              marginBottom: "0.75rem",
            }}
          >
            <HelpCircle size={14} />
            <span>Frequently Asked Questions</span>
          </div>

          <h2
            style={{
              fontSize: "clamp(2rem, 4vw, 2.75rem)",
              fontWeight: 800,
              letterSpacing: "-0.03em",
              color: AppColors.textPrimary,
              lineHeight: 1.2,
              marginBottom: "1rem",
            }}
          >
            Everything You Need to Know About X Medica
          </h2>

          <p style={{ fontSize: "1.05rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
            Got questions about hardware compatibility, data migration, or Play Store setup? We're here to help.
          </p>
        </div>

        <div style={{ maxWidth: "800px", margin: "0 auto", display: "flex", flexDirection: "column", gap: "1rem" }}>
          {faqs.map((faq, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div
                key={idx}
                style={{
                  backgroundColor: AppColors.white,
                  borderRadius: "16px",
                  border: `1px solid ${isOpen ? AppColors.primaryEmerald : AppColors.borderSubtle}`,
                  overflow: "hidden",
                  transition: "all 0.25s ease",
                  boxShadow: isOpen ? "0 6px 20px -5px rgba(5, 150, 105, 0.12)" : "0 2px 6px rgba(0,0,0,0.02)",
                }}
              >
                <button
                  onClick={() => setOpenIndex(isOpen ? null : idx)}
                  style={{
                    width: "100%",
                    padding: "1.25rem 1.5rem",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    textAlign: "left",
                    background: "none",
                    gap: "1rem",
                  }}
                >
                  <span
                    style={{
                      fontSize: "1.02rem",
                      fontWeight: 700,
                      color: isOpen ? AppColors.primaryEmerald : AppColors.textPrimary,
                    }}
                  >
                    {faq.q}
                  </span>
                  <div
                    style={{
                      width: "32px",
                      height: "32px",
                      borderRadius: "50%",
                      backgroundColor: isOpen ? AppColors.tealSurface : AppColors.frostMint,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: isOpen ? AppColors.primaryEmerald : AppColors.textMuted,
                      flexShrink: 0,
                      transform: isOpen ? "rotate(180deg)" : "none",
                      transition: "transform 0.25s ease",
                    }}
                  >
                    <ChevronDown size={18} />
                  </div>
                </button>

                {isOpen && (
                  <div
                    style={{
                      padding: "0 1.5rem 1.25rem 1.5rem",
                      fontSize: "0.92rem",
                      color: AppColors.textSecondary,
                      lineHeight: 1.7,
                      borderTop: `1px solid ${AppColors.frostMint}`,
                      paddingTop: "1rem",
                    }}
                  >
                    {faq.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
