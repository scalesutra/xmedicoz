import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

enum Unique3DRefreshState { idle, dragging, armed, refreshing, complete }

/// A signature, high-performance 3D gyroscopic refresh indicator for XMedicoz.
/// Displays an isometric levitating cyber-pharma capsule with orbital rings,
/// real 3D perspective rotation, dynamic ambient glow, and tactile haptic feedback.
///
/// Usage:
/// ```dart
/// Unique3DRefreshIndicator(
///   onRefresh: () async {
///     await controller.fetchData();
///   },
///   child: ListView(...),
/// )
/// ```
class Unique3DRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double triggerOffset;
  final String? title;
  final Color? primaryColor;
  final Color? secondaryColor;

  const Unique3DRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerOffset = 100.0,
    this.title,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<Unique3DRefreshIndicator> createState() => _Unique3DRefreshIndicatorState();
}

class _Unique3DRefreshIndicatorState extends State<Unique3DRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _settleController;

  double _dragOffset = 0.0;
  Unique3DRefreshState _state = Unique3DRefreshState.idle;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    // Continuous 3D rotation while refreshing
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Breathing glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Smooth bounce/settle controller for return to 0
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {
          _dragOffset = _dragOffset * (1.0 - _settleController.value);
        });
      });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  double get _progress => (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0);

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_state == Unique3DRefreshState.refreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0 && notification.scrollDelta! < 0) {
        // Dragging down at the top
        final delta = -notification.scrollDelta!;
        // Non-linear damping for smooth natural drag resistance
        final damp = 1.0 - (_dragOffset / (widget.triggerOffset * 2.5)).clamp(0.0, 0.7);
        setState(() {
          _dragOffset += delta * damp;
          if (_dragOffset >= widget.triggerOffset) {
            if (!_hasTriggeredHaptic) {
              HapticFeedback.mediumImpact();
              _hasTriggeredHaptic = true;
            }
            _state = Unique3DRefreshState.armed;
          } else {
            _hasTriggeredHaptic = false;
            _state = Unique3DRefreshState.dragging;
          }
        });
      } else if (notification.scrollDelta! > 0 && _dragOffset > 0) {
        setState(() {
          _dragOffset = math.max(0.0, _dragOffset - notification.scrollDelta!);
          if (_dragOffset == 0) _state = Unique3DRefreshState.idle;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        final damp = 1.0 - (_dragOffset / (widget.triggerOffset * 2.5)).clamp(0.0, 0.7);
        setState(() {
          _dragOffset += -notification.overscroll * damp;
          if (_dragOffset >= widget.triggerOffset) {
            if (!_hasTriggeredHaptic) {
              HapticFeedback.mediumImpact();
              _hasTriggeredHaptic = true;
            }
            _state = Unique3DRefreshState.armed;
          } else {
            _hasTriggeredHaptic = false;
            _state = Unique3DRefreshState.dragging;
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= widget.triggerOffset) {
        _triggerRefresh();
      } else if (_dragOffset > 0) {
        _settleToZero();
      }
    }
    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _state = Unique3DRefreshState.refreshing;
      _dragOffset = widget.triggerOffset;
    });
    _spinController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        HapticFeedback.lightImpact();
        setState(() {
          _state = Unique3DRefreshState.complete;
        });
        await Future.delayed(const Duration(milliseconds: 180));
        if (mounted) {
          _settleToZero();
        }
      }
    }
  }

  void _settleToZero() {
    _hasTriggeredHaptic = false;
    _settleController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _state = Unique3DRefreshState.idle;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? AppColors.primaryEmerald;
    final secondary = widget.secondaryColor ?? AppColors.clinicalCyan;

    final visibleHeight = _dragOffset.clamp(0.0, widget.triggerOffset * 1.3);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          // Content translated down during pull
          Transform.translate(
            offset: Offset(0, visibleHeight),
            child: widget.child,
          ),

          // 3D Header Area
          if (visibleHeight > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: visibleHeight,
              child: ClipRect(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.none,
                    alignment: Alignment.center,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_spinController, _pulseController]),
                      builder: (context, _) {
                        return _build3DStage(primary, secondary);
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build3DStage(Color primary, Color secondary) {
    final isSpinning = _state == Unique3DRefreshState.refreshing;
    final progress = _progress;

    // 3D Matrix angles
    final double rotX = isSpinning
        ? 0.4 + math.sin(_spinController.value * math.pi * 2) * 0.25
        : (progress * 0.65);
    final double rotY = isSpinning
        ? (_spinController.value * math.pi * 4)
        : (progress * math.pi * 1.5);
    final double rotZ = isSpinning
        ? math.cos(_spinController.value * math.pi * 2) * 0.2
        : (progress * 0.3);

    final double levitation = isSpinning ? (math.sin(_pulseController.value * math.pi) * 6.0) : 0.0;

    String statusText;
    switch (_state) {
      case Unique3DRefreshState.idle:
      case Unique3DRefreshState.dragging:
        statusText = 'Pull to Sync Data';
        break;
      case Unique3DRefreshState.armed:
        statusText = 'Release to Sync';
        break;
      case Unique3DRefreshState.refreshing:
        statusText = widget.title ?? 'Syncing Pharma Ledger...';
        break;
      case Unique3DRefreshState.complete:
        statusText = 'Updated Successfully!';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 3D Levitating Cyber Capsule
        Transform.translate(
          offset: Offset(0, -levitation),
          child: SizedBox(
            width: 72.r,
            height: 48.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floor depth shadow
                Positioned(
                  bottom: 2.h,
                  child: Container(
                    width: 44.w * (1.0 - (levitation / 20.0).clamp(0.0, 0.4)),
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: isSpinning ? 0.35 : 0.2),
                      borderRadius: BorderRadius.all(Radius.elliptical(22.w, 4.h)),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 12.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                  ),
                ),

                // Orbital 3D Ring 1
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(rotX + 0.5)
                    ..rotateY(-rotY * 0.8)
                    ..rotateZ(rotZ),
                  child: Container(
                    width: 58.r,
                    height: 58.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: secondary.withValues(alpha: isSpinning ? 0.6 : progress * 0.5),
                        width: 1.5.w,
                      ),
                    ),
                  ),
                ),

                // Orbital 3D Ring 2 (Counter-rotating)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-rotX * 0.7)
                    ..rotateY(rotY)
                    ..rotateZ(-rotZ * 0.8),
                  child: Container(
                    width: 66.r,
                    height: 66.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primary.withValues(alpha: isSpinning ? 0.7 : progress * 0.4),
                        width: 1.2.w,
                      ),
                    ),
                  ),
                ),

                // Central 3D Cyber-Pharma Pill
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0025)
                    ..rotateX(rotX)
                    ..rotateY(rotY)
                    ..rotateZ(rotZ),
                  child: Container(
                    width: 36.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          secondary,
                          primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: isSpinning ? 0.6 : 0.35),
                          blurRadius: 14.r,
                          spreadRadius: 1.r,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: secondary.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.2.w,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _state == Unique3DRefreshState.complete
                            ? Icons.check_rounded
                            : Icons.local_pharmacy_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.h),

        // Status Micro-Typography
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSpinning) ...[
              SizedBox(
                width: 8.r,
                height: 8.r,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8.w,
                  color: primary,
                ),
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              statusText,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: _state == Unique3DRefreshState.armed || isSpinning
                    ? primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
