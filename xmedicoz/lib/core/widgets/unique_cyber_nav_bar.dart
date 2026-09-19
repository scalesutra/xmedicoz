import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color accentColor;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accentColor,
  });
}

/// Ultra-Modern, Glassmorphic & Kinetic Bottom Navigation Dock
/// Features spring tactile feedback, glowing active indicators,
/// and a sculpted 3D kinetic F8 Sale launcher.
/// 100% DRY - Strictly uses AppColors tokens.
class UniqueCyberNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabPressed;

  const UniqueCyberNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onFabPressed,
  });

  @override
  State<UniqueCyberNavBar> createState() => _UniqueCyberNavBarState();
}

class _UniqueCyberNavBarState extends State<UniqueCyberNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _gearController;
  late final AnimationController _pulseController;
  late final AnimationController _fabScaleController;

  static const List<NavItemData> _leftTabs = [
    NavItemData(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      accentColor: AppColors.primaryEmerald,
    ),
    NavItemData(
      icon: Icons.medication_outlined,
      activeIcon: Icons.medication_rounded,
      label: 'Stock',
      accentColor: AppColors.primaryEmerald,
    ),
  ];

  static const List<NavItemData> _rightTabs = [
    NavItemData(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Ledger',
      accentColor: AppColors.creditGreen,
    ),
    NavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Daybook',
      accentColor: AppColors.primaryBlue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fabScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.90,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _gearController.dispose();
    _pulseController.dispose();
    _fabScaleController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (widget.selectedIndex != index) {
      HapticFeedback.selectionClick();
      widget.onTabSelected(index);
    }
  }

  void _onFabTapped() async {
    HapticFeedback.mediumImpact();
    await _fabScaleController.reverse();
    await _fabScaleController.forward();
    widget.onFabPressed();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        bottomInset > 0 ? (bottomInset + 4.h) : 8.h,
      ),
      height: 62.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Frosted Glassmorphic Pod Dock (Slim & Sleek)
          ClipRRect(
            borderRadius: BorderRadius.circular(26.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    width: 1.2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                      blurRadius: 20.r,
                      spreadRadius: 1.r,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 12.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left 2 items (Dashboard, Inventory)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTabItem(0, _leftTabs[0]),
                          _buildTabItem(1, _leftTabs[1]),
                        ],
                      ),
                    ),

                    // Central Spacing for the Floating 3D Launcher
                    SizedBox(width: 50.w),

                    // Right 2 items (Ledger, Daybook)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTabItem(2, _rightTabs[0]),
                          _buildTabItem(3, _rightTabs[1]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Sculpted Central 3D Kinetic F8 Launcher
          Positioned(
            top: -10.h,
            child: _buildSculptedCenterLauncher(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, NavItemData data) {
    final isSelected = widget.selectedIndex == index;
    final color = data.accentColor;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 8.w : 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.10) : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.30) : AppColors.transparent,
            width: 1.0.w,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Smooth Floating Lift on active
            AnimatedSlide(
              offset: isSelected ? const Offset(0, -0.06) : Offset.zero,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? data.activeIcon : data.icon,
                size: isSelected ? 18.sp : 17.sp,
                color: isSelected ? color : AppColors.textMuted,
              ),
            ),
            SizedBox(height: 1.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            // Glowing Indicator Dash
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 10.w : 0,
              height: 2.0.h,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppDecorations.radiusFull),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 4.r,
                          spreadRadius: 0.5.r,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSculptedCenterLauncher() {
    return ScaleTransition(
      scale: _fabScaleController,
      child: GestureDetector(
        onTap: _onFabTapped,
        child: AnimatedBuilder(
          animation: Listenable.merge([_gearController, _pulseController]),
          builder: (context, child) {
            final pulseVal = _pulseController.value;
            final glowScale = 1.0 + (pulseVal * 0.10);

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Kinetic rotating outer orbital gear dots
                Transform.rotate(
                  angle: _gearController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(54.r, 54.r),
                    painter: _RotatingGearAuraPainter(color: AppColors.primaryOrange),
                  ),
                ),

                // 2. Radiant Pulsing Aura
                Transform.scale(
                  scale: glowScale,
                  child: Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryOrange.withValues(alpha: 0.16 * (1 - pulseVal * 0.35)),
                    ),
                  ),
                ),

                // 3. Central 3D Elevated Sunset Orange Orb
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                      color: AppColors.white,
                      width: 2.0.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.45),
                        blurRadius: 14.r,
                        spreadRadius: 1.5.r,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.12),
                        blurRadius: 8.r,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_pharmacy_rounded,
                        size: 18.sp,
                        color: AppColors.white,
                      ),
                      Text(
                        'Rx BILL',
                        style: TextStyle(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: 0.3,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RotatingGearAuraPainter extends CustomPainter {
  final Color color;

  _RotatingGearAuraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw 8 satellite micro-dots around circular orbit
    const int count = 8;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count;
      final x = center.dx + (radius - 3) * math.cos(angle);
      final y = center.dy + (radius - 3) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
