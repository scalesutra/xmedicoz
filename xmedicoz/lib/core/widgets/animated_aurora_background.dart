import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Mesmerizing Animated Aurora, Wave Ribbons & Micro-Particle Background
/// Drifts glowing sunset orange, emerald mint, and sapphire blue ambient fields.
/// 100% DRY - Strictly uses AppColors tokens.
class AnimatedAuroraBackground extends StatefulWidget {
  final Widget child;

  const AnimatedAuroraBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedAuroraBackground> createState() =>
      _AnimatedAuroraBackgroundState();
}

class _AnimatedAuroraBackgroundState extends State<AnimatedAuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid Pearl Canvas Base
        Container(
          color: AppColors.bgPrimary,
        ),

        // Animated Flowing Ambient Orbs & Wave Grid
        AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final double t = _animController.value * 2 * math.pi;

            // Orb 1: Sunset Orange (Top-Right drifting)
            final double orb1X = math.sin(t) * 35.w;
            final double orb1Y = math.cos(t) * 45.h;

            // Orb 2: Emerald Mint (Bottom-Left drifting in opposite phase)
            final double orb2X = math.cos(t + math.pi * 0.7) * 40.w;
            final double orb2Y = math.sin(t + math.pi * 0.7) * 35.h;

            // Orb 3: Royal Sapphire (Center-Right breathing)
            final double orb3Scale = 0.88 + (math.sin(t * 1.4) * 0.14);

            return Stack(
              children: [
                // Orb 1 - Sunset Orange
                Positioned(
                  top: -70.h + orb1Y,
                  right: -70.w + orb1X,
                  child: Container(
                    width: 340.r,
                    height: 340.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryOrange.withValues(alpha: 0.16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.22),
                          blurRadius: 95.r,
                          spreadRadius: 25.r,
                        ),
                      ],
                    ),
                  ),
                ),

                // Orb 2 - Emerald Mint
                Positioned(
                  bottom: -80.h + orb2Y,
                  left: -80.w + orb2X,
                  child: Container(
                    width: 320.r,
                    height: 320.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.creditGreen.withValues(alpha: 0.13),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.creditGreen.withValues(alpha: 0.18),
                          blurRadius: 95.r,
                          spreadRadius: 25.r,
                        ),
                      ],
                    ),
                  ),
                ),

                // Orb 3 - Sapphire Blue
                Positioned(
                  top: 260.h,
                  right: -50.w,
                  child: Transform.scale(
                    scale: orb3Scale,
                    child: Container(
                      width: 250.r,
                      height: 250.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlue.withValues(alpha: 0.11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.16),
                            blurRadius: 85.r,
                            spreadRadius: 20.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Flowing Ambient Waves & Micro Constellation Grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AuroraFlowPainter(progress: _animController.value),
                  ),
                ),
              ],
            );
          },
        ),

        // Foreground Content
        widget.child,
      ],
    );
  }
}

/// Renders smooth flowing sine wave ribbons and floating interconnected ledger nodes
class _AuroraFlowPainter extends CustomPainter {
  final double progress;

  _AuroraFlowPainter({required this.progress});

  static const List<Offset> _fixedNodes = [
    Offset(0.12, 0.18),
    Offset(0.35, 0.14),
    Offset(0.78, 0.22),
    Offset(0.92, 0.38),
    Offset(0.22, 0.52),
    Offset(0.80, 0.64),
    Offset(0.38, 0.78),
    Offset(0.68, 0.88),
    Offset(0.15, 0.90),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw smooth flowing sine wave in the background
    final wavePaint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    final double wavePhase = progress * 2 * math.pi;
    path1.moveTo(0, size.height * 0.4);
    for (double x = 0; x <= size.width; x += 15) {
      final y = size.height * 0.38 +
          math.sin(wavePhase + (x / size.width) * 3 * math.pi) * 32.h;
      path1.lineTo(x, y);
    }
    canvas.drawPath(path1, wavePaint);

    final wavePaint2 = Paint()
      ..color = AppColors.creditGreen.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    for (double x = 0; x <= size.width; x += 15) {
      final y = size.height * 0.62 +
          math.cos(wavePhase * 0.8 + (x / size.width) * 2.5 * math.pi) * 28.h;
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, wavePaint2);

    // 2. Draw drifting interconnected ledger constellation nodes
    final List<Offset> currentPositions = [];
    for (int i = 0; i < _fixedNodes.length; i++) {
      final node = _fixedNodes[i];
      final double y = (node.dy - progress * 0.14 + 1.0) % 1.0;
      final double x = node.dx + math.sin((progress * 2 * math.pi) + i) * 0.02;
      currentPositions.add(Offset(x * size.width, y * size.height));
    }

    // Draw connecting lines between nearby nodes
    final linePaint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < currentPositions.length; i++) {
      for (int j = i + 1; j < currentPositions.length; j++) {
        final d = (currentPositions[i] - currentPositions[j]).distance;
        if (d < 160.w) {
          final lineAlpha = ((1.0 - (d / 160.w)) * 0.12).clamp(0.0, 0.15);
          linePaint.color = AppColors.primaryOrange.withValues(alpha: lineAlpha);
          canvas.drawLine(currentPositions[i], currentPositions[j], linePaint);
        }
      }
    }

    // Draw glowing nodes and particles
    final orangeDot = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final greenDot = Paint()
      ..color = AppColors.creditGreen.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < currentPositions.length; i++) {
      final pos = currentPositions[i];
      final isEven = i % 2 == 0;
      final dotPaint = isEven ? orangeDot : greenDot;

      // Glow halo
      canvas.drawCircle(
        pos,
        6.0,
        Paint()
          ..color = (isEven ? AppColors.primaryOrange : AppColors.creditGreen)
              .withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );

      // Core point
      canvas.drawCircle(pos, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraFlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
