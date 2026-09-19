import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

/// Centralized BoxDecorations & Styling Utilities for 100% DRY layouts.
class AppDecorations {
  // Radius values
  static double get radiusSm => 8.r;
  static double get radiusMd => 14.r;
  static double get radiusLg => 20.r;
  static double get radiusXl => 28.r;
  static double get radiusPill => 999.r;
  static double get radiusFull => radiusPill;

  // Primary Glass/Elevated Card
  static BoxDecoration card({
    Color? bgColor,
    Color? borderColor,
    double? radius,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: bgColor ?? AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
      border: Border.all(
        color: borderColor ?? AppColors.borderSubtle,
        width: 1.w,
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                 color: (borderColor ?? AppColors.primaryCyan).withValues(alpha: 0.18),
                blurRadius: 16.r,
                spreadRadius: 1.r,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 14.r,
                spreadRadius: 1.r,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration get cardDecoration => card();

  // Gradient Border High-End Card
  static BoxDecoration gradientCard({
    required Gradient gradient,
    double? radius,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
      border: Border.all(
        color: borderColor ?? AppColors.white.withValues(alpha: 0.15),
        width: 1.w,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.08),
          blurRadius: 14.r,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Badge Container
  static BoxDecoration badge({
    required Color color,
    double? radius,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius ?? radiusPill),
      border: Border.all(
        color: color.withValues(alpha: 0.35),
        width: 1.w,
      ),
    );
  }

  // Input Field Container
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    bool isDense = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11.sp,
      ),
      isDense: isDense,
      filled: true,
      fillColor: AppColors.bgInput,
      hintStyle: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12.5.sp,
      ),
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.sp,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: AppColors.primaryOrange, width: 1.5.w),
      ),
    );
  }

  // Search Field Decoration (Compact, Sleek & Modern)
  static InputDecoration searchDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? focusColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: AppColors.bgInput,
      hintStyle: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: focusColor ?? AppColors.primaryEmerald, width: 1.3.w),
      ),
    );
  }
}
