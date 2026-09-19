import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ledger_app/features/auth/controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/storage/storage_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  late final AnimationController _ecgController;

  Timer? _statusTimer;
  Timer? _navTimer;

  int _statusIndex = 0;
  static const List<String> _statusMessages = [
    'Securing Drug License Vault (DL 20B/21B)...',
    'Scanning Batch & Near-Expiry Radar (<60 Days)...',
    'Loading Retail Chemist Daybook & Marg Sync...',
    'Dispensing Ready • Launching Counter...',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();

    // 2. Continuous ECG Heartbeat pulse
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // 3. Progress bar 0.0 -> 1.0 in 2.6 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    // Cycle boot status messages
    _statusTimer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (!mounted) return;
      if (_statusIndex < _statusMessages.length - 1) {
        setState(() => _statusIndex++);
      }
    });

    // Auto navigation to Onboarding after 2.8 seconds
    _navTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      _navigateToOnboarding();
    });
  }

  void _navigateToOnboarding() {
    _statusTimer?.cancel();
    _navTimer?.cancel();
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn.value) {
        Get.offAllNamed(AppRoutes.main);
        return;
      }
    }
    if (StorageService.hasSeenOnboarding()) {
      Get.offNamed(AppRoutes.login);
    } else {
      Get.offNamed(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _navTimer?.cancel();
    _animController.dispose();
    _progressController.dispose();
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 16.h,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2),

                              // Unique Animated 3D Hologram App Icon with Levitating Emerald Pulse
                              const _UniqueAnimatedSplashIcon(),

                              SizedBox(height: 28.h),

                              // Retail Chemist Pill
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 5.h,
                                ),
                                decoration: AppDecorations.badge(
                                  color: AppColors.primaryEmerald,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.health_and_safety_rounded,
                                      size: 15.sp,
                                      color: AppColors.primaryEmerald,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'RETAIL PHARMACY SUITE v7.4',
                                      style: AppTypography.badge.copyWith(
                                        color: AppColors.primaryEmeraldDark,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 14.h),

                              // Brand Title
                              Text(
                                AppStrings.appName,
                                style: AppTypography.h1.copyWith(
                                  fontSize: 32.sp,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.8,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 6.h),

                              Text(
                                'Autonomous Medical Store & Chemist Accounting',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 22.h),

                              // Live ECG Heartbeat Pulse Line
                              SizedBox(
                                width: 220.w,
                                height: 32.h,
                                child: AnimatedBuilder(
                                  animation: _ecgController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: _EcgPulsePainter(
                                        progress: _ecgController.value,
                                        color: AppColors.primaryEmerald,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Feature Pills (Retail Medical Core)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  _buildFeaturePill(
                                    Icons.receipt_long_rounded,
                                    'Rx POS Billing',
                                  ),
                                  _buildFeaturePill(
                                    Icons.alarm_on_rounded,
                                    'Near-Expiry Radar',
                                  ),
                                  _buildFeaturePill(
                                    Icons.groups_rounded,
                                    'Customer Ledger',
                                  ),
                                  _buildFeaturePill(
                                    Icons.warehouse_rounded,
                                    'Stockist Inward',
                                  ),
                                ],
                              ),

                              const Spacer(flex: 3),

                              // Dynamic Real-time Boot Status & Progress Bar
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(
                                    AppDecorations.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryEmerald.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 1.w,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 14.r,
                                          height: 14.r,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primaryEmerald),
                                              ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            child: Text(
                                              _statusMessages[_statusIndex],
                                              key: ValueKey<int>(_statusIndex),
                                              style: TextStyle(
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors
                                                    .primaryEmeraldDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    // Linear Progress Bar
                                    AnimatedBuilder(
                                      animation: _progressAnimation,
                                      builder: (context, _) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            3.r,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: _progressAnimation.value,
                                            minHeight: 4.h,
                                            backgroundColor:
                                                AppColors.borderSubtle,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppColors.primaryEmerald),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Quick Action Button
                              AppButton(
                                title: 'Open Retail Counter',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _navigateToOnboarding,
                              ),

                              SizedBox(height: 10.h),

                              Text(
                                '100% Encrypted • Offline First • Made for Retail Chemists',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10.5.sp,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const Spacer(flex: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(
          color: AppColors.primaryEmerald.withValues(alpha: 0.22),
          width: 0.9.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primaryEmerald),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom ECG Pulse Wave Painter that renders a glowing medical pulse
class _EcgPulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _EcgPulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final h = size.height;
    final w = size.width;
    final mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.20, mid);
    path.lineTo(w * 0.28, mid - 4);
    path.lineTo(w * 0.35, mid + 4);
    path.lineTo(w * 0.42, mid);
    // Sharp QRS complex
    path.lineTo(w * 0.48, mid + 6);
    path.lineTo(w * 0.54, mid - 14);
    path.lineTo(w * 0.60, mid + 12);
    path.lineTo(w * 0.64, mid);
    // T-wave
    path.lineTo(w * 0.72, mid - 7);
    path.lineTo(w * 0.80, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Glowing dot moving along pulse
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final distance = metric.length * progress;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        final dotPaint = Paint()..color = color;
        canvas.drawCircle(tangent.position, 3.5, dotPaint);
        
        // Add a slight glowing trail effect for extra cyberpunk feel
        final trailPaint = Paint()..color = color.withValues(alpha: 0.4);
        canvas.drawCircle(tangent.position, 6.0, trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EcgPulsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Unique Animated 3D Hologram App Icon with Elastic Spring & Levitating Energy Pulse
class _UniqueAnimatedSplashIcon extends StatefulWidget {
  const _UniqueAnimatedSplashIcon();

  @override
  State<_UniqueAnimatedSplashIcon> createState() =>
      _UniqueAnimatedSplashIconState();
}

class _UniqueAnimatedSplashIconState extends State<_UniqueAnimatedSplashIcon>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _tiltAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _pulseHaloAnimation;
  late final Animation<double> _pulseHaloOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Pop & 3D Isometric Perspective Tilt
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _tiltAnimation = Tween<double>(begin: -0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous Breathing Levitation & Energy Halo Pulse
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _pulseHaloAnimation = Tween<double>(begin: 0.95, end: 1.16).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseHaloOpacity = Tween<double>(begin: 0.20, end: 0.50).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _floatController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_tiltAnimation.value * 0.5)
                ..rotateY(_tiltAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Radiant Energy Halo Ring (Signature Medical Emerald)
                    Transform.scale(
                      scale: _pulseHaloAnimation.value,
                      child: Container(
                        width: 140.r,
                        height: 140.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryEmerald.withValues(
                                alpha: _pulseHaloOpacity.value * 0.35,
                              ),
                              AppColors.primaryEmerald.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Middle Concentric Halo Ring
                    Container(
                      width: 118.r,
                      height: 118.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32.r),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: _pulseHaloOpacity.value * 0.6,
                          ),
                          width: 1.2.w,
                        ),
                      ),
                    ),

                    // Hero 3D Squircle Icon Container
                    Container(
                      width: 96.r,
                      height: 96.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.bgCard,
                            AppColors.primaryEmerald.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.38,
                          ),
                          width: 1.8.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.30,
                            ),
                            blurRadius: 32.r,
                            spreadRadius: 2.r,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 8.r,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.r),
                        child: Image.asset(
                          AppAssets.appIcon,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.local_pharmacy_rounded,
                                  color: AppColors.white,
                                  size: 44.sp,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
