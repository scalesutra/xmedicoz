import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Unique kinetic dual-ring orbital gear loader with glowing nodes.
class CustomUniqueLoader extends StatefulWidget {
  final double? size;
  final String? label;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CustomUniqueLoader({
    super.key,
    this.size,
    this.label,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<CustomUniqueLoader> createState() => _CustomUniqueLoaderState();
}

class _CustomUniqueLoaderState extends State<CustomUniqueLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.size ?? 68.r;
    final primary = widget.primaryColor ?? AppColors.primaryCyan;
    final secondary = widget.secondaryColor ?? AppColors.primaryBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _OrbitalGearPainter(
                  progress: _controller.value,
                  primaryColor: primary,
                  secondaryColor: secondary,
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          SizedBox(height: 12.h),
          Text(
            widget.label!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrbitalGearPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _OrbitalGearPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;
    final innerRadius = size.width * 0.28;

    // Center glowing core
    final corePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25 + 0.15 * math.sin(progress * 2 * math.pi))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, size.width * 0.12, corePaint);

    final innerCore = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.06, innerCore);

    // Outer rotating orbital ring
    final outerAngle = progress * 2 * math.pi;
    final outerPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Outer glowing orbital arcs
    final outerArcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor,
          secondaryColor,
        ],
        transform: GradientRotation(outerAngle),
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      outerAngle,
      1.8 * math.pi,
      false,
      outerArcPaint,
    );

    // Inner reverse-spinning ring
    final innerAngle = -progress * 2 * math.pi * 1.5;
    final innerArcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.creditGreen.withValues(alpha: 0.0),
          AppColors.creditGreen,
          primaryColor,
        ],
        transform: GradientRotation(innerAngle),
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      innerAngle,
      1.4 * math.pi,
      false,
      innerArcPaint,
    );

    // 4 Orbital Satellite Nodes
    final nodePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = outerAngle + (i * math.pi / 2);
      final nodeX = center.dx + outerRadius * math.cos(angle);
      final nodeY = center.dy + outerRadius * math.sin(angle);
      nodePaint.color = i.isEven ? primaryColor : secondaryColor;
      canvas.drawCircle(Offset(nodeX, nodeY), 3.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalGearPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
