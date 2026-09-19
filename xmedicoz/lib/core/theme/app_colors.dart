import 'package:flutter/material.dart';

/// Centralized unique color tokens & gradients for a modern luxury Medical & Pharmacy ERP aesthetic.
/// 100% DRY - No hardcoded colors anywhere in the codebase.
/// Features:
/// - Signature Clinical Medical Emerald (`#059669` / `#10B981`) & Deep Teal for primary pharmacy branding
/// - Vibrant Rx Crimson / Coral (`#EF4444` / `#F43F5E`) for Schedule H/H1, Near-Expiry alerts, & Payables
/// - Clinical Cyan & Sapphire for digital prescriptions & UPI transfers
/// - Crisp, hygienic Frost Mint & Pearl Canvas (`#F4F8F6` / `#FFFFFF`)
class AppColors {
  // Pure Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Background & Surfaces (Clean Clinical Pearl & Frost Mint Canvas)
  static const Color bgPrimary = Color(0xFFF2F7F5); // Fresh Clinical Mint Canvas
  static const Color bgSurface = Color(0xFFFFFFFF); // Elevated Pure Hospital White
  static const Color bgCard = Color(0xFFFFFFFF);    // Frosted Snow Card
  static const Color bgCardHover = Color(0xFFEDF7F4);
  static const Color bgInput = Color(0xFFEBF3F1);   // Soft Hygiene Field

  // Dock & Drawer Surfaces
  static const Color dockDarkStart = Color(0xFFFFFFFF);
  static const Color dockDarkEnd = Color(0xFFF2F8F6);
  static const Color drawerDarkStart = Color(0xFFFFFFFF);
  static const Color drawerDarkEnd = Color(0xFFF2F8F6);

  // Dark Inks for high-contrast readability on clinical cards
  static const Color darkContrast = Color(0xFF0B2520);
  static const Color darkInk = Color(0xFF0F2922);
  static const Color darkCharcoal = Color(0xFF1B3B32);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFD6EAE3); // Crisp subtle mint silver
  static const Color borderHighlight = Color(0xFF059669); // Glowing Medical Emerald Accent
  static const Color borderLight = Color(0xFFC7E2D9);
  static const Color borderMedium = Color(0xFFB5D7CC);

  // Signature Clinical Emerald & Mint Tokens (Pharma Primary)
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color primaryEmeraldLight = Color(0xFF10B981);
  static const Color primaryEmeraldDark = Color(0xFF047857);
  static const Color primaryTeal = Color(0xFF0D9488);

  // Compatibility aliases for existing references
  static const Color primaryOrange = Color(0xFF059669); // Mapped to Medical Emerald
  static const Color primaryOrangeLight = Color(0xFF10B981);
  static const Color primaryOrangeAmber = Color(0xFF0D9488);
  static const Color primaryOrangeGlow = Color(0x4D059669);

  // Primary Futuristic Medical Brand Accents
  static const Color primaryCyan = Color(0xFF059669);   // Signature Medical Emerald
  static const Color clinicalCyan = Color(0xFF0891B2);  // Electric Medical Cyan
  static const Color primaryBlue = Color(0xFF0284C7);   // Hospital Sapphire
  static const Color primaryPurple = Color(0xFF6366F1); // Biotech Violet
  static const Color primaryIndigo = Color(0xFF4F46E5); // Diagnostic Indigo
  static const Color pinkCategory = Color(0xFF0D9488);  // Wellness Teal

  // Financial & Medical Status Accents
  static const Color creditGreen = Color(0xFF10B981);   // Emerald (Medicine Sale, Cash In, Inflow, Jama)
  static const Color creditGreenLight = Color(0xFF059669);
  static const Color creditGreenBg = Color(0xFFECFDF5); // Soft Mint Pastel
  static const Color creditGreenDark = Color(0xFF047857);

  static const Color debitRose = Color(0xFFEF4444);     // Rx Crimson (Stockist Outflow, Dena, Purchase)
  static const Color debitRoseLight = Color(0xFFDC2626);
  static const Color debitRoseBg = Color(0xFFFEF2F2);   // Soft Rose Pastel
  static const Color debitRoseDark = Color(0xFFB91C1C);

  static const Color amberWarning = Color(0xFFF59E0B);  // Low Stock / Attention
  static const Color amberWarningLight = Color(0xFFD97706);
  static const Color amberWarningBg = Color(0xFFFFFBEB); // Soft Amber Pastel
  static const Color amberWarningDark = Color(0xFFB45309);

  // Special Pharma Tags
  static const Color nearExpiryColor = Color(0xFFF97316); // Amber Orange (<60 Days)
  static const Color expiredColor = Color(0xFFDC2626);    // Urgent Red
  static const Color scheduleHColor = Color(0xFFE11D48);  // Rx Schedule H Red
  static const Color otcColor = Color(0xFF10B981);        // OTC Green

  static const Color onlineBlue = Color(0xFF0284C7);    // UPI / Digital Payment
  static const Color cashGold = Color(0xFFD97706);      // Counter Cash

  static const Color accentTeal = primaryTeal;
  static const Color textTertiary = textMuted;

  // Typography Colors (Crisp Clinical Deep Teal-Navy)
  static const Color textPrimary = Color(0xFF0F2420);   // Deep Luxury Forest Navy
  static const Color textSecondary = Color(0xFF37544C); // Refined Sage Graphite
  static const Color textMuted = Color(0xFF5F7E76);
  static const Color textDisabled = Color(0xFF96B3AB);

  // OTP Verification v7 Tokens (Medical Emerald & Mint Glow)
  static const Color otpBoxBg = Color(0xFFFFFFFF);
  static const Color otpBoxBorderIdle = Color(0xFFD3E7E0);
  static const Color otpBoxBorderActive = Color(0xFF059669); // Emerald Focus
  static const Color otpBoxBorderFilled = Color(0xFF047857);
  static const Color otpGlowCyan = Color(0x33059669);
  static const Color otpGlowSuccess = Color(0x3310B981);
  static const Color otpGlowError = Color(0x33EF4444);
  static const Color otpParticleGold = Color(0xFF10B981);
  static const Color otpParticleCyan = Color(0xFF0891B2);
  static const Color otpParticleGreen = Color(0xFF059669);
  static const Color otpSuccessRingStart = Color(0x3310B981);
  static const Color otpSuccessRingEnd = Color(0x0A10B981);
  static const Color otpOrangeAccent = Color(0xFF059669);
  static const Color otpOrangeBorder = Color(0xFF059669);
  static const Color otpOrangeGlow = Color(0x55059669);

  // Launcher Gradient Colors
  static const Color launcherCyan = Color(0xFF059669);
  static const Color launcherBlue = Color(0xFF0D9488);
  static const Color launcherDarkBlue = Color(0xFF0891B2);

  // -------------------------------------------------------------
  // CURATED CLINICAL PHARMACY GRADIENTS
  // -------------------------------------------------------------

  // Signature Medical Emerald Button & Hero Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF059669),
      Color(0xFF0D9488),
      Color(0xFF0891B2),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeSunsetGradient = LinearGradient(
    colors: [
      Color(0xFF047857),
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraPurpleGradient = LinearGradient(
    colors: [
      Color(0xFF0D9488),
      Color(0xFF0284C7),
      Color(0xFF6366F1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sapphireBlueGradient = LinearGradient(
    colors: [
      Color(0xFF0284C7),
      Color(0xFF0891B2),
      Color(0xFF0D9488),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryCardGradient = LinearGradient(
    colors: [bgCard, bgSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creditGradient = LinearGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
      Color(0xFF047857),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient debitGradient = LinearGradient(
    colors: [
      Color(0xFFEF4444),
      Color(0xFFDC2626),
      Color(0xFFB91C1C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [
      Color(0xFF0D9488),
      Color(0xFF047857),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient launcherGradient = LinearGradient(
    colors: [
      launcherCyan,
      launcherBlue,
      launcherDarkBlue,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
