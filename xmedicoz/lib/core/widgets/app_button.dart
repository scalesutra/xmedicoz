import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { gradient, glass, outlined, danger, success }

class AppButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double? height;
  final bool? isFullWidth;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.variant = ButtonVariant.gradient,
    this.isLoading = false,
    this.width,
    this.height,
    this.isFullWidth,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.height ?? 50.h;

    Decoration decoration;
    Color textColor = AppColors.white;

    switch (widget.variant) {
      case ButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrangeGlow,
              blurRadius: 16.r,
              spreadRadius: 1.r,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = AppColors.white; // High contrast crisp white on vibrant orange gradient
        break;
      case ButtonVariant.glass:
        decoration = BoxDecoration(
          color: AppColors.bgCardHover,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          border: Border.all(color: AppColors.borderSubtle, width: 1.w),
        );
        textColor = AppColors.textPrimary;
        break;
      case ButtonVariant.outlined:
        decoration = BoxDecoration(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          border: Border.all(color: AppColors.primaryCyan, width: 1.5.w),
        );
        textColor = AppColors.primaryCyan;
        break;
      case ButtonVariant.danger:
        decoration = BoxDecoration(
          gradient: AppColors.debitGradient,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.debitRose.withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = AppColors.white;
        break;
      case ButtonVariant.success:
        decoration = BoxDecoration(
          gradient: AppColors.creditGradient,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.creditGreen.withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = AppColors.white;
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: effectiveHeight,
          decoration: decoration,
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18.sp, color: textColor),
                        SizedBox(width: 6.w),
                      ],
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.button.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Ultra-Unique Centralized Cyber Floating Action Button for Inventory, Ledger & Vouchers
class AppFloatingButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? glowColor;

  const AppFloatingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.glowColor,
  });

  @override
  State<AppFloatingButton> createState() => _AppFloatingButtonState();
}

class _AppFloatingButtonState extends State<AppFloatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.glowColor ?? AppColors.primaryOrangeGlow;
    final effectiveGradient = widget.gradient ?? AppColors.primaryGradient;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 74.h + (bottomInset > 0 ? bottomInset : 0),
      ), // Suspended gracefully above the floating cyber dock & Android nav bar
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: Container(
            height: 46.h,
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 18.w, 4.h),
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.7),
                width: 1.2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveGlow.withValues(alpha: 0.45),
                  blurRadius: 20.r,
                  spreadRadius: 1.r,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 10.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing circular micro-badge around icon
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.black.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 16.sp,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 9.w),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
