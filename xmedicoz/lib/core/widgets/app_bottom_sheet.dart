import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable, high-performance Bottom Sheet helper and wrapper adhering to the DRY principle.
///
/// Features:
/// 1. Keyboard unfocus via [PopScope] when the sheet closes.
/// 2. Keyboard padding only for fields owned by the active sheet.
/// 3. Solid, non-transparent [AppColors.bgSurface] background with rounded top borders.
/// 4. Integrated drag handle, optional standard title bar, and fluid drag-to-dismiss.
class AppBottomSheet {
  AppBottomSheet._();

  /// Opens a standardized modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      barrierColor: barrierColor ?? AppColors.black.withValues(alpha: 0.65),
      builder: builder,
    );
  }
}

class AppKeyboardPadding extends StatelessWidget {
  const AppKeyboardPadding({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Standard bottom sheet container wrapper widget.
/// Wraps content with [PopScope], solid surface decoration, and inner keyboard padding.
class AppBottomSheetWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool showDragHandle;
  final bool showCloseButton;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onClose;
  final double? maxHeightFactor;
  final Widget? footer;

  const AppBottomSheetWrapper({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.showDragHandle = true,
    this.showCloseButton = true,
    this.padding,
    this.onClose,
    this.maxHeightFactor = 0.9,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bottomNavPadding = MediaQuery.paddingOf(context).bottom;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight =
        (screenHeight - bottomInset).clamp(280.0, screenHeight);
    final maxHeight = maxHeightFactor != null
        ? availableHeight * maxHeightFactor!
        : availableHeight * 0.92;

    return PopScope(
      canPop: bottomInset == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.25),
                blurRadius: 20.r,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding:
              padding ??
              EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                bottomInset > 0 ? 12.h : 24.h + bottomNavPadding,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            if (showDragHandle)
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

            // Standard Header (if title is provided)
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: AppTypography.h3.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                  if (showCloseButton) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        FocusScope.of(context).unfocus();
                        if (onClose != null) {
                          onClose!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14.h),
            ],

            // Main Sheet Body
            Flexible(child: child),
            if (footer != null) ...[SizedBox(height: 8.h), footer!],
          ],
        ),
      ),
    ),
  );
}
}
