import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/add_shop_screen.dart';
import 'unique_snackbar.dart';

/// 100% Faithful Implementation of @code.xr "OTP Verification, but Version 7"
///
/// Signature Animation Flow (as seen in Instagram Reel):
/// 1. Initial State: 4 horizontal boxes. Box 1 has vibrant glowing Orange border.
/// 2. As digits are entered: Focus advances with glowing orange border.
/// 3. Upon 4th digit:
///    - Phase 1: 4 boxes morph from horizontal line into a 2x2 square grid!
///    - Phase 2: Connecting circuit lines draw between all 4 boxes in a closed square!
///    - Phase 3: The 4 boxes and circuit lines collapse/implode into the center!
///    - Phase 4: A single central rounded square with emerald green border pops up with white checkmark `✓`!
///    - Phase 5: Title transforms to green "Verified Successfully", subtitle to "Your number has been verified", and "🔒 Verified and Secure" badge appears.
/// 4. 100% DRY, no hardcoded colors.
class UniqueOtpV7Sheet extends StatefulWidget {
  final String phone;
  final String channel;
  final VoidCallback? onSuccess;

  const UniqueOtpV7Sheet({
    super.key,
    required this.phone,
    this.channel = 'PHONE',
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String phone,
    String channel = 'PHONE',
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: UniqueOtpV7Sheet(
          phone: phone,
          channel: channel,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<UniqueOtpV7Sheet> createState() => _UniqueOtpV7SheetState();
}

class _UniqueOtpV7SheetState extends State<UniqueOtpV7Sheet>
    with TickerProviderStateMixin {
  static const int _otpLength = 4;
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  // Master Animation Controller for the entire Version 7 sequence
  late final AnimationController _animController;

  // Timeline intervals for each phase of the reel:
  // Phase 1: Morph from Horizontal (1x4) to Square Grid (2x2) [0.0 -> 0.35]
  late final Animation<double> _gridMorphAnimation;

  // Phase 2: Draw connecting circuit lines around the 2x2 grid [0.32 -> 0.58]
  late final Animation<double> _circuitLineAnimation;

  // Phase 3: Collapse 4 boxes and lines towards center (0,0) [0.55 -> 0.76]
  late final Animation<double> _implosionAnimation;

  // Phase 4: Scale up single central green checkmark box [0.72 -> 0.94]
  late final Animation<double> _successBoxScaleAnimation;

  // Phase 5: Draw checkmark path & reveal "Verified and Secure" [0.80 -> 1.0]
  late final Animation<double> _checkStrokeAnimation;
  late final Animation<double> _textCrossFadeAnimation;

  // Pulsing glow for the active box during input
  late final AnimationController _activePulseController;

  bool _isAnimatingSequence = false;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    // Pulse glow on active box
    _activePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Master Timeline: 2.2 seconds for the full cinematic reel animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 1. Morph to 2x2 grid
    _gridMorphAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeInOutCubicEmphasized),
    );

    // 2. Circuit line perimeter drawing
    _circuitLineAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.30, 0.56, curve: Curves.easeInOut),
    );

    // 3. Implosion to center
    _implosionAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.54, 0.74, curve: Curves.easeInBack),
    );

    // 4. Central Emerald Box Pop-in
    _successBoxScaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.70, 0.90, curve: Curves.elasticOut),
    );

    // 5. Checkmark path drawing & text reveal
    _checkStrokeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.80, 0.98, curve: Curves.easeInOutCubic),
    );

    _textCrossFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.72, 0.92, curve: Curves.easeIn),
    );

    // Track active focus
    for (int i = 0; i < _otpLength; i++) {
      final idx = i;
      _focusNodes[idx].addListener(() {
        if (_focusNodes[idx].hasFocus && mounted) {
          setState(() {});
        }
      });
    }

    // Auto-focus first box on presentation and autofill dev OTP if received
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          if (auth.serverDevOtp.value.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && !_isAnimatingSequence && !_isVerifying) {
                _autoFillDevOtp(auth.serverDevOtp.value);
              }
            });
          }
        }
      }
    });
  }

  void _autoFillDevOtp(String otp) {
    if (_isAnimatingSequence || _isVerifying) return;
    final clean = otp.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < _otpLength && i < clean.length; i++) {
      Future.delayed(Duration(milliseconds: (i + 1) * 140), () {
        if (!mounted) return;
        _controllers[i].text = clean[i];
        setState(() {});
        if (i == _otpLength - 1) {
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _verifyEnteredOtp();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _activePulseController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyEnteredOtp();
      }
    }
    setState(() {});
  }

  void _handlePaste(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < _otpLength; i++) {
      if (i < clean.length) {
        _controllers[i].text = clean[i];
      } else {
        _controllers[i].clear();
      }
    }
    setState(() {});
    if (clean.length >= _otpLength) {
      FocusScope.of(context).unfocus();
      _verifyEnteredOtp();
    } else {
      _focusNodes[clean.length.clamp(0, _otpLength - 1)].requestFocus();
    }
  }

  Future<void> _verifyEnteredOtp() async {
    if (_isAnimatingSequence || _isVerifying) return;
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length < _otpLength) return;

    setState(() => _isVerifying = true);

    final authController = Get.find<AuthController>();
    final success = await authController.verifyOtp(
      code,
      channel: widget.channel,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (success) {
      _startVersion7Sequence();
    } else {
      UniqueSnackbar.showError(
        context,
        title: 'Verification Failed',
        message: authController.errorMessage.value.isNotEmpty
            ? authController.errorMessage.value
            : 'Invalid OTP code. Please try again.',
      );
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {});
    }
  }

  Future<void> _handleResend() async {
    if (_isResending || _isVerifying || _isAnimatingSequence) return;
    setState(() => _isResending = true);

    final authController = Get.find<AuthController>();
    final success = await authController.requestOtp(
      widget.phone,
      channel: widget.channel,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      final target = widget.channel == 'EMAIL' ? 'your email' : widget.phone;
      UniqueSnackbar.showSuccess(
        context,
        title: 'OTP Resent',
        message: 'A fresh 4-digit OTP has been sent to $target',
      );
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {});
    } else {
      UniqueSnackbar.showError(
        context,
        title: 'Unable to Resend',
        message: authController.errorMessage.value.isNotEmpty
            ? authController.errorMessage.value
            : 'Failed to send OTP. Please wait a moment.',
      );
    }
  }

  void _startVersion7Sequence() {
    if (_isAnimatingSequence) return;
    setState(() => _isAnimatingSequence = true);

    _animController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Get.back();
        }
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          if (Get.find<AuthController>().userShops.isEmpty) {
            Get.offAll(() => const AddShopScreen());
          } else {
            Get.offAllNamed(AppRoutes.main);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          border: Border.all(color: AppColors.borderSubtle, width: 1.4.w),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 36.r,
              offset: Offset(0, -10.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle Ambient Executive Glows in Sheet Background (Static, No Animation Lag)
            Positioned(
              top: -30.h,
              right: -25.w,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              top: 60.h,
              left: -30.w,
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creditGreen.withValues(alpha: 0.07),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                22.w,
                14.h,
                22.w,
                MediaQuery.viewInsetsOf(context).bottom + 20.h,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Top Pill Grab Handle
                  Container(
                    width: 44.w,
                    height: 4.5.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Header: "Otp Verification V7" with glowing orange V7
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.otpV7TopTitle,
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.otpOrangeAccent.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.otpOrangeAccent.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.otpV7TopVersion,
                          style: TextStyle(
                            color: AppColors.otpOrangeAccent,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Dynamic Subtitle / Status text
                  AnimatedBuilder(
                    animation: _textCrossFadeAnimation,
                    builder: (context, _) {
                      final isSuccess = _textCrossFadeAnimation.value > 0.5;
                      return Column(
                        children: [
                          Text(
                            isSuccess
                                ? AppStrings.otpV7SuccessTitle
                                : AppStrings.otpV7Title,
                            style: AppTypography.h3.copyWith(
                              color: isSuccess
                                  ? AppColors.creditGreen
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            isSuccess
                                ? AppStrings.otpV7SuccessSubtitle
                                : widget.channel == 'EMAIL'
                                    ? "We've sent a 4-digit code to ${widget.phone}.\nCheck your inbox & spam folder."
                                    : "We've sent a 4-digit code to ${widget.phone}.\nIt'll auto-verify once entered.",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 14.h),

                  // Dev OTP Auto-Detection & Quick Fill Banner
                  if (!_isAnimatingSequence && Get.isRegistered<AuthController>())
                    Obx(() {
                      final devCode =
                          Get.find<AuthController>().serverDevOtp.value;
                      if (devCode.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: InkWell(
                          onTap: () => _autoFillDevOtp(devCode),
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusPill,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.otpOrangeAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDecorations.radiusPill,
                              ),
                              border: Border.all(
                                color: AppColors.otpOrangeAccent.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.2.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.otpOrangeAccent,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Dev OTP Received: $devCode (Tap to Autofill)',
                                  style: TextStyle(
                                    color: AppColors.otpOrangeAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  SizedBox(height: 10.h),

                  // -------------------------------------------------------------
                  // The Central Reel Morphing Stage (280w x 170h)
                  // -------------------------------------------------------------
                  SizedBox(
                    width: 280.w,
                    height: 170.h,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Layer 1: The Connecting Square Circuit Lines (Phase 2)
                            if (_circuitLineAnimation.value > 0.0 &&
                                _implosionAnimation.value < 1.0)
                              Opacity(
                                opacity: (1.0 - _implosionAnimation.value)
                                    .clamp(0.0, 1.0),
                                child: CustomPaint(
                                  size: Size(280.w, 170.h),
                                  painter: _SquareCircuitPainter(
                                    progress: _circuitLineAnimation.value,
                                    dx:
                                        42.w *
                                        (1.0 - _implosionAnimation.value),
                                    dy:
                                        42.h *
                                        (1.0 - _implosionAnimation.value),
                                    color: AppColors.otpOrangeAccent,
                                  ),
                                ),
                              ),

                            // Layer 2: The 4 Digit Boxes (Morphing & Imploding)
                            if (_implosionAnimation.value < 1.0)
                              ...List.generate(_otpLength, (index) {
                                return _buildMorphingBox(index);
                              }),

                            // Layer 3: Central Emerald Green Checkmark Square (Phase 4 & 5)
                            if (_successBoxScaleAnimation.value > 0.0)
                              Transform.scale(
                                scale: _successBoxScaleAnimation.value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64.r,
                                      height: 64.r,
                                      decoration: BoxDecoration(
                                        color: AppColors.creditGreenBg,
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.creditGreen,
                                          width: 2.2.w,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.creditGreen
                                                .withValues(alpha: 0.30),
                                            blurRadius: 20.r,
                                            spreadRadius: 3.r,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CustomPaint(
                                              size: Size(32.r, 32.r),
                                              painter: _ReelCheckmarkPainter(
                                                progress:
                                                    _checkStrokeAnimation.value,
                                                color: AppColors.creditGreen,
                                              ),
                                            ),
                                            if (_checkStrokeAnimation.value >=
                                                0.85)
                                              Icon(
                                                Icons.check_rounded,
                                                color: AppColors.creditGreen,
                                                size: 34.sp,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 16.h),

                                    // "🔒 Verified and Secure" Badge
                                    Opacity(
                                      opacity: _checkStrokeAnimation.value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            color: AppColors.creditGreenLight,
                                            size: 15.sp,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            AppStrings.otpV7VerifiedAndSecure,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: AppColors
                                                      .creditGreenLight,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                          ),
                                        ],
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

                  SizedBox(height: 24.h),
                  // Footer: Live Resend & Verification state
                  if (!_isAnimatingSequence) ...[
                    if (_isVerifying) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.otpOrangeAccent,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Verifying code with server...',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.otpOrangeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppStrings.otpV7DidntReceive,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          InkWell(
                            onTap: _isResending ? null : _handleResend,
                            child: _isResending
                                ? SizedBox(
                                    width: 12.r,
                                    height: 12.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryEmerald,
                                      ),
                                    ),
                                  )
                                : Text(
                                    AppStrings.otpV7Resend,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primaryEmerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds each morphing digit box that smoothly interpolates between:
  /// - Initial: Horizontal row `[0] [1] [2] [3]`
  /// - Morph: 2x2 Square Grid `[0] [1]` on top, `[2] [3]` on bottom
  /// - Implosion: Collapses into (0, 0)
  Widget _buildMorphingBox(int index) {
    // 1. Starting position in horizontal line
    // Total row span ~ 250.w, step ~ 62.w
    final double initialX = (index - 1.5) * 62.w;
    const double initialY = 0.0;

    // 2. 2x2 Grid Target position (dx = 42.w, dy = 42.h)
    // Box 0: Top-Left  (-42, -42)
    // Box 1: Top-Right (+42, -42)
    // Box 2: Bottom-Left (-42, +42)
    // Box 3: Bottom-Right (+42, +42)
    final double gridX = (index % 2 == 0 ? -42.w : 42.w);
    final double gridY = (index < 2 ? -42.h : 42.h);

    // Interpolate from Initial -> Grid (via _gridMorphAnimation)
    final double currentXBeforeImplosion =
        initialX + (gridX - initialX) * _gridMorphAnimation.value;
    final double currentYBeforeImplosion =
        initialY + (gridY - initialY) * _gridMorphAnimation.value;

    // Interpolate from Grid -> Center (0, 0) (via _implosionAnimation)
    final double finalX =
        currentXBeforeImplosion * (1.0 - _implosionAnimation.value);
    final double finalY =
        currentYBeforeImplosion * (1.0 - _implosionAnimation.value);

    // Scale shrinks to 0.0 as implosion finishes
    final double scale = (1.0 - _implosionAnimation.value).clamp(0.0, 1.0);

    final bool isFocused = !_isAnimatingSequence && _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;

    return Transform.translate(
      offset: Offset(finalX, finalY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 54.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.otpBoxBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isFocused
                  ? AppColors.otpOrangeBorder
                  : (hasValue
                        ? AppColors.otpBoxBorderFilled
                        : AppColors.otpBoxBorderIdle),
              width: isFocused ? 2.0.w : 1.2.w,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.otpOrangeGlow.withValues(
                        alpha: 0.3 + (_activePulseController.value * 0.35),
                      ),
                      blurRadius: 14.r,
                      spreadRadius: 1.5.r,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Displayed Digit
              if (hasValue)
                Text(
                  _controllers[index].text,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),

              // Hidden input field for keyboard handling
              if (!_isAnimatingSequence)
                KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_controllers[index].text.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                        setState(() {});
                      }
                    }
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    cursorColor: AppColors.transparent,
                    style: const TextStyle(color: AppColors.transparent),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => _onDigitChanged(index, val),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the circuit lines connecting the 4 boxes into a closed square (Phase 2)
class _SquareCircuitPainter extends CustomPainter {
  final double progress;
  final double dx;
  final double dy;
  final Color color;

  _SquareCircuitPainter({
    required this.progress,
    required this.dx,
    required this.dy,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 4 Corner nodes of the 2x2 grid
    final pTopLeft = Offset(centerX - dx, centerY - dy);
    final pTopRight = Offset(centerX + dx, centerY - dy);
    final pBottomRight = Offset(centerX + dx, centerY + dy);
    final pBottomLeft = Offset(centerX - dx, centerY + dy);

    final path = Path();
    path.moveTo(pTopLeft.dx, pTopLeft.dy);

    // Segment 1: Top (0.0 -> 0.25)
    if (progress < 0.25) {
      final t = progress / 0.25;
      path.lineTo(pTopLeft.dx + (pTopRight.dx - pTopLeft.dx) * t, pTopLeft.dy);
    } else {
      path.lineTo(pTopRight.dx, pTopRight.dy);

      // Segment 2: Right (0.25 -> 0.50)
      if (progress < 0.50) {
        final t = (progress - 0.25) / 0.25;
        path.lineTo(
          pTopRight.dx,
          pTopRight.dy + (pBottomRight.dy - pTopRight.dy) * t,
        );
      } else {
        path.lineTo(pBottomRight.dx, pBottomRight.dy);

        // Segment 3: Bottom (0.50 -> 0.75)
        if (progress < 0.75) {
          final t = (progress - 0.50) / 0.25;
          path.lineTo(
            pBottomRight.dx + (pBottomLeft.dx - pBottomRight.dx) * t,
            pBottomRight.dy,
          );
        } else {
          path.lineTo(pBottomLeft.dx, pBottomLeft.dy);

          // Segment 4: Left (0.75 -> 1.0)
          final t = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
          path.lineTo(
            pBottomLeft.dx,
            pBottomLeft.dy + (pTopLeft.dy - pBottomLeft.dy) * t,
          );
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquareCircuitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dx != dx ||
        oldDelegate.dy != dy;
  }
}

/// Precise SVG-Style Checkmark Painter for the final central square
class _ReelCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ReelCheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.6.w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * 0.24, size.height * 0.54);
    final p2 = Offset(size.width * 0.44, size.height * 0.74);
    final p3 = Offset(size.width * 0.78, size.height * 0.32);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (progress < 0.40) {
      final t = progress / 0.40;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.40) / 0.60;
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReelCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
