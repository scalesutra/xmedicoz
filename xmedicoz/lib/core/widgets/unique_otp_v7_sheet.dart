import 'dart:async';
import 'dart:math' as math;
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
    final screenWidth = MediaQuery.of(context).size.width;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      constraints: BoxConstraints(minWidth: screenWidth, maxWidth: screenWidth),
      builder: (_) => SizedBox(
        width: screenWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenWidth,
            maxWidth: screenWidth,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: UniqueOtpV7Sheet(
            phone: phone,
            channel: channel,
            onSuccess: onSuccess,
          ),
        ),
      ),
    );
  }

  @override
  State<UniqueOtpV7Sheet> createState() => _UniqueOtpV7SheetState();
}

class _UniqueOtpV7SheetState extends State<UniqueOtpV7Sheet>
    with TickerProviderStateMixin {
  static const int _otpLength = 6;
  final TextEditingController _masterController = TextEditingController();
  final FocusNode _masterFocusNode = FocusNode();
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  // ─── Orbit Entry ─────────────────────────────────────────────────────────
  late final AnimationController _orbitController;
  late final Animation<double> _orbitProgress;
  bool _orbitDone = false;

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
  Worker? _devOtpWorker;
  Timer? _resendTimer;
  int _resendSeconds = 30;

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // ── Orbit Entry Animation ─────────────────────────────────────────────
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _orbitProgress = CurvedAnimation(
      parent: _orbitController,
      curve: Curves.easeInOutCubic,
    );
    _orbitController.forward().then((_) {
      if (mounted) setState(() => _orbitDone = true);
    });

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

    // Keep individual controllers and boxes in sync with master input
    _masterController.addListener(() {
      final code = _masterController.text;
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < code.length ? code[i] : '';
      }
      if (mounted) setState(() {});
      if (code.length >= _otpLength && !_isVerifying && !_isAnimatingSequence) {
        _masterFocusNode.unfocus();
        _verifyEnteredOtp();
      }
    });

    _masterFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Auto-focus after orbit settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isAnimatingSequence) {
            _masterFocusNode.requestFocus();
          }
        });
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          if (auth.serverDevOtp.value.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_isAnimatingSequence && !_isVerifying) {
                _autoFillDevOtp(auth.serverDevOtp.value);
              }
            });
          }
          _devOtpWorker = ever<String>(auth.serverDevOtp, (code) {
            if (code.isNotEmpty &&
                mounted &&
                !_isAnimatingSequence &&
                !_isVerifying) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && !_isAnimatingSequence && !_isVerifying) {
                  _autoFillDevOtp(code);
                }
              });
            }
          });
        }
      }
    });
  }

  void _autoFillDevOtp(String otp) {
    if (_isAnimatingSequence || _isVerifying) return;
    if (_masterController.text.isNotEmpty) return;

    final clean = otp.replaceAll(RegExp(r'\D'), '');
    if (clean.length < _otpLength) return;

    _masterController.text = clean.substring(0, _otpLength);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _devOtpWorker?.dispose();
    _orbitController.dispose();
    _animController.dispose();
    _activePulseController.dispose();
    _masterController.dispose();
    _masterFocusNode.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyEnteredOtp() async {
    if (_isAnimatingSequence || _isVerifying) return;
    final code = _masterController.text.trim();
    if (code.length < 4) return;

    setState(() => _isVerifying = true);

    final authController = Get.find<AuthController>();
    final success = await authController.verifyOtp(
      code,
      channel: widget.channel,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (success) {
      TextInput.finishAutofillContext();
      _startVersion7Sequence();
    } else {
      UniqueSnackbar.showError(
        context,
        title: 'Verification Failed',
        message: authController.errorMessage.value.isNotEmpty
            ? authController.errorMessage.value
            : 'Invalid OTP code. Please try again.',
      );
      _masterController.clear();
      for (var c in _controllers) {
        c.clear();
      }
      _masterFocusNode.requestFocus();
      setState(() {});
    }
  }

  Future<void> _handleResend() async {
    if (_isResending ||
        _isVerifying ||
        _isAnimatingSequence ||
        _resendSeconds > 0) {
      return;
    }
    setState(() => _isResending = true);

    final authController = Get.find<AuthController>();
    final success = await authController.requestOtp(
      widget.phone,
      channel: widget.channel,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (success) {
      _startResendTimer();
      final target = widget.channel == 'EMAIL' ? 'your email' : widget.phone;
      UniqueSnackbar.showSuccess(
        context,
        title: 'OTP Resent',
        message: 'A fresh 6-digit OTP has been sent to $target',
      );
      _masterController.clear();
      for (var c in _controllers) {
        c.clear();
      }
      _masterFocusNode.requestFocus();
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
    setState(() {
      _orbitDone = true;
      _isAnimatingSequence = true;
    });

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
        width: double.infinity,
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
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Pill Grab Handle
                      Container(
                        width: 44.w,
                        height: 4.5.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),

                      SizedBox(height: 14.h),

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
                                    ? "We've sent a 6-digit code to ${widget.phone}.\nCheck your inbox & spam folder."
                                    : "We've sent a 6-digit code to ${widget.phone}.\nIt'll auto-verify once entered.",
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

                      // Server OTP Auto-Fill Banner (Only shown if real OTP returned by server)
                      if (!_isAnimatingSequence &&
                          Get.isRegistered<AuthController>())
                        Obx(() {
                          final devCode =
                              Get.find<AuthController>().serverDevOtp.value;
                          if (devCode.isEmpty) {
                            return const SizedBox.shrink();
                          }

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
                                  color: AppColors.primaryEmerald.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDecorations.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryEmerald.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1.2.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      color: AppColors.primaryEmerald,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'OTP Received: $devCode (Tap to Fill)',
                                      style: TextStyle(
                                        color: AppColors.primaryEmerald,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      SizedBox(height: 10.h),

                      // ── Central Reel Stage (6-digit, 320w x 180h) ──────────────
                      SizedBox(
                        width: 320.w,
                        height: 180.h,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _orbitProgress,
                            _animController,
                            _activePulseController,
                          ]),
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Phase 2: Circuit lines for 2×3 grid
                                if (_circuitLineAnimation.value > 0.0 &&
                                    _implosionAnimation.value < 1.0)
                                  Opacity(
                                    opacity: (1.0 - _implosionAnimation.value)
                                        .clamp(0.0, 1.0),
                                    child: CustomPaint(
                                      size: Size(320.w, 180.h),
                                      painter: _SixBoxCircuitPainter(
                                        progress: _circuitLineAnimation.value,
                                        colSpacing:
                                            48.w *
                                            (1.0 - _implosionAnimation.value),
                                        rowSpacing:
                                            44.h *
                                            (1.0 - _implosionAnimation.value),
                                        implode: _implosionAnimation.value,
                                        color: AppColors.otpOrangeAccent,
                                      ),
                                    ),
                                  ),

                                // The 6 boxes — orbit entry or morphing+imploding
                                if (_implosionAnimation.value < 1.0)
                                  ...List.generate(_otpLength, (index) {
                                    return _orbitDone
                                        ? _buildMorphingBox(index)
                                        : _buildOrbitBox(index);
                                  }),

                                // Master Transparent Input Overlay: Single stream input prevents out-of-order or reverse typing
                                if (!_isAnimatingSequence && _orbitDone)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        _masterFocusNode.requestFocus();
                                      },
                                      child: Opacity(
                                        opacity: 0.0,
                                        child: TextField(
                                          controller: _masterController,
                                          focusNode: _masterFocusNode,
                                          keyboardType: TextInputType.number,
                                          autofillHints: const [
                                            AutofillHints.oneTimeCode,
                                          ],
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(_otpLength),
                                          ],
                                          enableInteractiveSelection: false,
                                          showCursor: false,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

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
                                                        _checkStrokeAnimation
                                                            .value,
                                                    color:
                                                        AppColors.creditGreen,
                                                  ),
                                                ),
                                                if (_checkStrokeAnimation
                                                        .value >=
                                                    0.85)
                                                  Icon(
                                                    Icons.check_rounded,
                                                    color:
                                                        AppColors.creditGreen,
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
                                                color:
                                                    AppColors.creditGreenLight,
                                                size: 15.sp,
                                              ),
                                              SizedBox(width: 5.w),
                                              Text(
                                                AppStrings
                                                    .otpV7VerifiedAndSecure,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .creditGreenLight,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                              SizedBox(width: 6.w),
                              if (_resendSeconds > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgPrimary,
                                    borderRadius: BorderRadius.circular(
                                      AppDecorations.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 13.sp,
                                        color: AppColors.primaryEmerald,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Resend in ${_resendSeconds.toString().padLeft(2, '0')}s',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: _isResending ? null : _handleResend,
                                  child: _isResending
                                      ? SizedBox(
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
                                        )
                                      : Text(
                                          AppStrings.otpV7Resend,
                                          style: AppTypography.bodySmall
                                              .copyWith(
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
            ),
          ],
        ),
      ),
    );
  }

  // ─── Orbit Entry Box ────────────────────────────────────────────────────
  /// 6 boxes spawn from center, orbit elliptically 1.5 turns,
  /// then snap into horizontal row.
  Widget _buildOrbitBox(int index) {
    final double t = _orbitProgress.value;
    const double orbitEnd = 0.70;

    // Final target in horizontal row
    final double targetX = (index - 2.5) * 53.w;
    const double targetY = 0.0;

    final double orbitRadius = 72.r;
    final double startAngle = (index / _otpLength) * 2 * math.pi;
    const double totalRotation = 1.5 * 2 * math.pi;

    double finalX, finalY, scale;

    if (t <= orbitEnd) {
      final double orbitT = t / orbitEnd;
      final double angle = startAngle + orbitT * totalRotation;
      final double radiusFade = orbitT * orbitRadius;
      finalX = math.cos(angle) * radiusFade * 1.4;
      finalY = math.sin(angle) * radiusFade * 0.6;
      scale = orbitT.clamp(0.0, 1.0);
    } else {
      final double snapT = ((t - orbitEnd) / (1.0 - orbitEnd)).clamp(0.0, 1.0);
      final double easedSnap = Curves.easeOutBack.transform(snapT);
      final double angle = startAngle + totalRotation;
      final double lastX = math.cos(angle) * orbitRadius * 1.4;
      final double lastY = math.sin(angle) * orbitRadius * 0.6;
      finalX = lastX + (targetX - lastX) * easedSnap;
      finalY = lastY + (targetY - lastY) * easedSnap;
      scale = 1.0;
    }

    return Transform.translate(
      offset: Offset(finalX, finalY),
      child: Transform.scale(
        scale: scale,
        child: _buildBoxContainer(index, false, false),
      ),
    );
  }

  // ─── Morphing + Imploding Box (post-orbit / success sequence) ─────────────
  /// Horizontal row → 2×3 grid → implosion to center
  Widget _buildMorphingBox(int index) {
    // 1. Starting: horizontal row of 6, step 53w
    final double initialX = (index - 2.5) * 53.w;
    const double initialY = 0.0;

    // 2. 2×3 grid — col = index%3 ∈ {0,1,2}, row = index<3 (top) vs ≥3 (bottom)
    final double colDx = 48.w;
    final double rowDy = 44.h;
    final double gridX = (index % 3 - 1) * colDx;
    final double gridY = (index < 3 ? -rowDy : rowDy);

    final double currentXBeforeImplosion =
        initialX + (gridX - initialX) * _gridMorphAnimation.value;
    final double currentYBeforeImplosion =
        initialY + (gridY - initialY) * _gridMorphAnimation.value;

    final double finalX =
        currentXBeforeImplosion * (1.0 - _implosionAnimation.value);
    final double finalY =
        currentYBeforeImplosion * (1.0 - _implosionAnimation.value);

    final double scale = (1.0 - _implosionAnimation.value).clamp(0.0, 1.0);

    final int activeIdx =
        _masterController.text.length.clamp(0, _otpLength - 1);
    final bool isFocused = !_isAnimatingSequence &&
        _masterFocusNode.hasFocus &&
        (index == activeIdx);
    final bool hasValue = index < _masterController.text.length;

    return Transform.translate(
      offset: Offset(finalX, finalY),
      child: Transform.scale(
        scale: scale,
        child: _buildBoxContainer(index, isFocused, hasValue),
      ),
    );
  }

  // ─── Shared Box Container ───────────────────────────────────────────────────
  Widget _buildBoxContainer(int index, bool isFocused, bool hasValue) {
    final digit = index < _masterController.text.length
        ? _masterController.text[index]
        : '';

    return Container(
      width: 44.w,
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.otpBoxBg,
        borderRadius: BorderRadius.circular(12.r),
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
      child: Center(
        child: hasValue
            ? Text(
                digit,
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Draws circuit lines connecting the 6 boxes in a 2×3 grid (Phase 2)
class _SixBoxCircuitPainter extends CustomPainter {
  final double progress;
  final double colSpacing;
  final double rowSpacing;
  final double implode;
  final Color color;

  _SixBoxCircuitPainter({
    required this.progress,
    required this.colSpacing,
    required this.rowSpacing,
    required this.implode,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // 6 node positions matching 2×3 grid
    final nodes = [
      Offset(cx - colSpacing, cy - rowSpacing), // 0: top-left
      Offset(cx, cy - rowSpacing), // 1: top-center
      Offset(cx + colSpacing, cy - rowSpacing), // 2: top-right
      Offset(cx - colSpacing, cy + rowSpacing), // 3: bottom-left
      Offset(cx, cy + rowSpacing), // 4: bottom-center
      Offset(cx + colSpacing, cy + rowSpacing), // 5: bottom-right
    ];

    // Perimeter: 0→1→2→5→4→3→0
    final perimeter = [
      nodes[0],
      nodes[1],
      nodes[2],
      nodes[5],
      nodes[4],
      nodes[3],
      nodes[0],
    ];
    final totalSegments = perimeter.length - 1;
    final segProgress = progress * totalSegments;

    final path = Path();
    path.moveTo(perimeter[0].dx, perimeter[0].dy);
    for (int s = 0; s < totalSegments; s++) {
      if (segProgress <= s) break;
      final t = (segProgress - s).clamp(0.0, 1.0);
      final from = perimeter[s];
      final to = perimeter[s + 1];
      path.lineTo(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SixBoxCircuitPainter old) =>
      old.progress != progress || old.implode != implode;
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
