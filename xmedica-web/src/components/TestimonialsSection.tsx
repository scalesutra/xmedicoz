import React from "react";
import { Star, CheckCircle } from "lucide-react";
import { AppColors } from "../theme/colors";

export const TestimonialsSection: React.FC = () => {
  const testimonials = [
    {
      name: "Dr. Arvind Patel",
      role: "Chief Pharmacist & Proprietor",
      pharmacy: "Patel MediCare & Surgical Center",
      location: "Ahmedabad, Gujarat",
      quote:
        "X Medica completely transformed our rush-hour billing. Running the Android POS app on our Sunmi terminal reduced customer checkout times from 2 minutes to under 20 seconds. The automatic FEFO batch warning has saved us over ₹35,000 in expired antibiotics alone.",
      rating: 5,
      avatar: "AP",
    },
    {
      name: "Suresh R. Nair",
      role: "Managing Chemist",
      pharmacy: "Sanjivani Lifeline Pharmacy",
      location: "Kochi, Kerala",
      quote:
        "The WhatsApp refill reminder feature is pure gold. Our diabetic and cardiac patients constantly praise us for reminding them before their monthly strips run out. Our recurring patient retention jumped by 35% within the first 60 days of using X Medica.",
      rating: 5,
      avatar: "SN",
    },
    {
      name: "Meera Deshmukh",
      role: "Dispensary Administrator",
      pharmacy: "Lotus Multi-Speciality Clinic",
      location: "Pune, Maharashtra",
      quote:
        "Passing our annual Drug Inspector audit was always stressful with Schedule H1 registers. With X Medica, we generated the complete narcotic dispensing report and distributor inward reconciliation in two clicks. Flawless compliance.",
      rating: 5,
      avatar: "MD",
    },
  ];

  return (
    <section style={{ padding: "90px 0", backgroundColor: AppColors.white }}>
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
            <span>Real Chemist Experiences</span>
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
            Trusted by 1,200+ Pharmacists Across the Nation
          </h2>

          <p style={{ fontSize: "1.05rem", color: AppColors.textSecondary, lineHeight: 1.6 }}>
            Read how medical store owners eliminated drug expiry waste, accelerated POS queues, and maintained pristine accounts with X Medica.
          </p>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(min(100%, 280px), 1fr))",
            gap: "1.5rem",
          }}
        >
          {testimonials.map((t, idx) => (
            <div
              key={idx}
              style={{
                backgroundColor: AppColors.frostMint,
                borderRadius: "20px",
                padding: "clamp(1.25rem, 4vw, 2rem)",
                border: `1px solid ${AppColors.borderSubtle}`,
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
                boxShadow: "0 4px 12px rgba(0,0,0,0.02)",
              }}
            >
              <div>
                {/* Stars */}
                <div style={{ display: "flex", gap: "3px", marginBottom: "1rem" }}>
                  {[...Array(t.rating)].map((_, i) => (
                    <Star key={i} size={16} fill="#F59E0B" color="#F59E0B" />
                  ))}
                </div>

                {/* Quote */}
                <p
                  style={{
                    fontSize: "0.95rem",
                    color: AppColors.textPrimary,
                    lineHeight: 1.7,
                    fontStyle: "italic",
                    marginBottom: "1.5rem",
                  }}
                >
                  "{t.quote}"
                </p>
              </div>

              {/* Author */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.85rem",
                  paddingTop: "1rem",
                  borderTop: `1px solid ${AppColors.borderSubtle}`,
                }}
              >
                <div
                  style={{
                    width: "44px",
                    height: "44px",
                    borderRadius: "12px",
                    backgroundColor: AppColors.primaryEmerald,
                    color: "#FFFFFF",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: 800,
                    fontSize: "0.95rem",
                  }}
                >
                  {t.avatar}
                </div>
                <div>
                  <div
                    style={{
                      fontWeight: 700,
                      fontSize: "0.95rem",
                      color: AppColors.textPrimary,
                      display: "flex",
                      alignItems: "center",
                      gap: "5px",
                    }}
                  >
                    <span>{t.name}</span>
                    <CheckCircle size={14} color={AppColors.primaryEmerald} />
                  </div>
                  <div style={{ fontSize: "0.78rem", color: AppColors.textMuted }}>
                    {t.pharmacy} • {t.location}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
