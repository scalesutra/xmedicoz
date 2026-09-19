import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Next-Gen Cybernetic & Executive Animated Toggle Switch
/// Replaces generic Material Switches with a tactile, spring-physics, glowing capsule.
/// 100% DRY - Uses AppColors tokens.
class UniqueToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Gradient? activeGradient;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final double? width;
  final double? height;

  const UniqueToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeGradient,
    this.activeIcon,
    this.inactiveIcon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.primaryOrange;
    final effectiveGradient = activeGradient ??
        LinearGradient(
          colors: [
            effectiveActiveColor,
            effectiveActiveColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

    final trackWidth = width ?? 54.w;
    final trackHeight = height ?? 30.h;
    final thumbSize = trackHeight - 6.h;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: trackWidth,
        height: trackHeight,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          gradient: value ? effectiveGradient : null,
          color: value ? null : AppColors.bgInput,
          border: Border.all(
            color: value
                ? effectiveActiveColor.withValues(alpha: 0.75)
                : AppColors.borderSubtle,
            width: 1.4.w,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: effectiveActiveColor.withValues(alpha: 0.35),
                    blurRadius: 10.r,
                    spreadRadius: 1.r,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 4.r,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.16),
                  blurRadius: 6.r,
                  offset: const Offset(0, 2),
                ),
                if (value)
                  BoxShadow(
                    color: effectiveActiveColor.withValues(alpha: 0.25),
                    blurRadius: 4.r,
                  ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: value
                    ? (activeIcon != null
                        ? Icon(
                            activeIcon,
                            key: const ValueKey('active_icon'),
                            size: 14.sp,
                            color: effectiveActiveColor,
                          )
                        : Container(
                            key: const ValueKey('active_dot'),
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: effectiveActiveColor,
                              boxShadow: [
                                BoxShadow(
                                  color: effectiveActiveColor.withValues(alpha: 0.5),
                                  blurRadius: 4.r,
                                ),
                              ],
                            ),
                          ))
                    : (inactiveIcon != null
                        ? Icon(
                            inactiveIcon,
                            key: const ValueKey('inactive_icon'),
                            size: 13.sp,
                            color: AppColors.textMuted,
                          )
                        : Container(
                            key: const ValueKey('inactive_dot'),
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textMuted.withValues(alpha: 0.45),
                            ),
                          )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
