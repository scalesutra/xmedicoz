import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../network/connectivity_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A sleek, floating cyber-pharma network status card that automatically
/// slides in whenever internet disconnects or server is unreachable.
class OfflineStatusCard extends StatelessWidget {
  const OfflineStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityController>()) {
      return const SizedBox.shrink();
    }

    final controller = ConnectivityController.to;

    return Obx(() {
      final isOffline = controller.isOffline.value;
      final showBackOnline = controller.showBackOnline.value;

      if (!isOffline && !showBackOnline) {
        return const SizedBox.shrink();
      }

      final isSuccess = showBackOnline && !isOffline;

      return Positioned(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 16.w,
        right: 16.w,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess
                    ? [
                        const Color(0xFF0F382A),
                        const Color(0xFF134E39),
                      ]
                    : [
                        const Color(0xFF381015),
                        const Color(0xFF280B10),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSuccess
                    ? AppColors.primaryEmerald.withValues(alpha: 0.8)
                    : AppColors.debitRose.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSuccess
                      ? AppColors.primaryEmerald.withValues(alpha: 0.25)
                      : AppColors.debitRose.withValues(alpha: 0.35),
                  blurRadius: 16.r,
                  spreadRadius: 1.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Glowing Icon Indicator
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSuccess
                        ? AppColors.primaryEmerald.withValues(alpha: 0.2)
                        : AppColors.debitRose.withValues(alpha: 0.2),
                    border: Border.all(
                      color: isSuccess
                          ? AppColors.primaryEmerald
                          : AppColors.debitRose,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    color: isSuccess
                        ? AppColors.primaryEmerald
                        : AppColors.debitRose,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),

                // Text Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isSuccess
                            ? 'Connection Restored'
                            : 'No Internet Connection',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSuccess
                              ? AppColors.primaryEmerald
                              : AppColors.debitRose,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isSuccess
                            ? 'Pharmacy ledger synced with server.'
                            : controller.statusMessage.value,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Retry / Status Action
                if (!isSuccess) ...[
                  SizedBox(width: 8.w),
                  Obx(() {
                    final checking = controller.isChecking.value;
                    return InkWell(
                      onTap: checking
                          ? null
                          : () => controller.checkConnectivity(),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.debitRose.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.debitRose.withValues(alpha: 0.4),
                          ),
                        ),
                        child: checking
                            ? SizedBox(
                                width: 14.r,
                                height: 14.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.debitRose,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 14.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
