import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

enum UniqueSnackbarType { success, error, warning, info }

/// Signature Unique Cyber-Pharma SnackBar System.
/// Provides consistent, ultra-clean, branded notifications with haptic feedback,
/// glowing pill accents, and responsive layout across the entire app.
class UniqueSnackbar {
  static void showSuccess(
    BuildContext? context, {
    required String message,
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: UniqueSnackbarType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext? context, {
    required String message,
    String title = 'Attention Required',
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: UniqueSnackbarType.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext? context, {
    required String message,
    String title = 'Warning',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: UniqueSnackbarType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext? context, {
    required String message,
    String title = 'Information',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: UniqueSnackbarType.info,
      duration: duration,
    );
  }

  static void _show(
    BuildContext? context, {
    required String message,
    required String title,
    required UniqueSnackbarType type,
    required Duration duration,
  }) {
    // Trigger haptic feedback for tactile feel
    try {
      if (type == UniqueSnackbarType.error) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}

    final BuildContext? activeContext = context ?? Get.overlayContext ?? Get.context;
    if (activeContext == null) {
      // Fallback to Get.rawSnackbar
      Get.rawSnackbar(
        title: title,
        message: message,
        backgroundColor: AppColors.darkContrast,
        duration: duration,
      );
      return;
    }

    // Determine colors and icon based on type
    final Color accentColor;
    final IconData icon;

    switch (type) {
      case UniqueSnackbarType.success:
        accentColor = AppColors.primaryEmerald;
        icon = Icons.check_circle_rounded;
        break;
      case UniqueSnackbarType.error:
        accentColor = AppColors.debitRose;
        icon = Icons.error_rounded;
        break;
      case UniqueSnackbarType.warning:
        accentColor = AppColors.amberWarning;
        icon = Icons.warning_amber_rounded;
        break;
      case UniqueSnackbarType.info:
        accentColor = AppColors.clinicalCyan;
        icon = Icons.info_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(activeContext);
    messenger.hideCurrentSnackBar();

    final bottomInset = MediaQuery.of(activeContext).padding.bottom;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: EdgeInsets.fromLTRB(
          16.w,
          0,
          16.w,
          10.h + (bottomInset > 0 ? bottomInset : 4.h),
        ),
        padding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.darkContrast.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.45),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 10.r,
                spreadRadius: 0.5.r,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8.r,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Slim Icon Micro-Badge
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: accentColor, size: 16.sp),
                ),
              ),
              SizedBox(width: 10.w),

              // 2. Concise Message Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty &&
                        title != 'Success' &&
                        title != 'Attention Required' &&
                        title != 'Warning' &&
                        title != 'Information')
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.92),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // 3. Compact Dismiss Button
              GestureDetector(
                onTap: () => messenger.hideCurrentSnackBar(),
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
