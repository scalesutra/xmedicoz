import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Common, Beautiful, Non-Animated Executive Background for all app screens.
/// 100% DRY - Uses AppColors tokens.
/// Lightweight, zero battery drain, zero CPU overhead, pure visual elegance.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base Luxury Pearl Canvas
        Container(
          color: AppColors.bgPrimary,
        ),

        // 2. Static Top-Right Sunset Orange Ambient Bloom
        Positioned(
          top: -70.h,
          right: -60.w,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  blurRadius: 90.r,
                  spreadRadius: 25.r,
                ),
              ],
            ),
          ),
        ),

        // 3. Static Bottom-Left Emerald Mint Ambient Bloom (Cashflow / Prosperity)
        Positioned(
          bottom: -80.h,
          left: -70.w,
          child: Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.creditGreen.withValues(alpha: 0.06),
              boxShadow: [
                BoxShadow(
                  color: AppColors.creditGreen.withValues(alpha: 0.10),
                  blurRadius: 90.r,
                  spreadRadius: 20.r,
                ),
              ],
            ),
          ),
        ),

        // 4. Static Mid-Right Sapphire Accent
        Positioned(
          top: 260.h,
          right: -50.w,
          child: Container(
            width: 200.r,
            height: 200.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  blurRadius: 70.r,
                  spreadRadius: 15.r,
                ),
              ],
            ),
          ),
        ),

        // 5. Foreground Screen Content
        child,
      ],
    );
  }
}
