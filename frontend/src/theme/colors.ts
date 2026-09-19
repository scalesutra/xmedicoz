/**
 * Centralized unique color tokens & gradients for MedicalCRM Luxury Pharmacy ERP aesthetic.
 * 100% DRY — Single Source of Truth.
 */
export const AppColors = {
  // Pure Neutrals
  white: "#FFFFFF",
  black: "#000000",
  transparent: "transparent",

  // Signature Clinical Medical Emerald & Deep Teal (Primary Branding)
  primaryEmerald: "#059669",
  primaryEmeraldHover: "#047857",
  emeraldLight: "#10B981",
  emeraldGlow: "rgba(16, 185, 129, 0.25)",
  deepTeal: "#0F766E",
  tealDark: "#134E4A",
  tealSurface: "#ECFDF5",

  // Clinical Cyan & Sapphire (Prescriptions & UPI Transfers)
  primaryCyan: "#06B6D4",
  cyanHover: "#0891B2",
  primaryBlue: "#0284C7",
  blueGlow: "rgba(6, 182, 212, 0.25)",
  cyanSurface: "#F0FDFA",

  // Vibrant Rx Crimson & Coral (Schedule H/H1, Expiry, Payables, Debt)
  debitRose: "#F43F5E",
  crimsonAlert: "#EF4444",
  crimsonHover: "#DC2626",
  crimsonSurface: "rgba(239, 68, 68, 0.10)",

  // Amber Warning (Near Expiry, Low Stock, Due Refills)
  amberWarning: "#F59E0B",
  amberLight: "rgba(245, 158, 11, 0.12)",
  amberSurface: "#FFFBEB",

  // Hygienic Frost Mint & Pearl Canvas
  frostMint: "#F4F8F6",
  pearlWhite: "#FFFFFF",
  bgSurface: "#FFFFFF",
  bgPrimary: "#F8FAF9",
  bgSidebar: "#0D1822",
  bgCardDark: "#132230",
  bgCardHover: "#182C3E",

  // Borders & Dividers
  borderSubtle: "#E2E8F0",
  borderDark: "#1E3345",
  borderActive: "#10B981",

  // Typography
  textPrimary: "#0F172A",
  textSecondary: "#475569",
  textMuted: "#94A3B8",
  textInverse: "#FFFFFF",
  textOnDark: "#E2E8F0",
} as const;

export type AppColorKey = keyof typeof AppColors;
