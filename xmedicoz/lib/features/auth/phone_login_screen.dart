import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/unique_otp_v7_sheet.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../../core/widgets/country_code_picker.dart';
import 'controllers/auth_controller.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  // 0 = Password Login, 1 = OTP Login
  int _selectedTab = 0;

  // Controllers for Password Login
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Controller for OTP Login
  final TextEditingController _otpIdentifierController = TextEditingController();
  Country _selectedCountry = CommonCountryCodePicker.defaultCountry;

  bool get _isPasswordInputEmail {
    final text = _identifierController.text.trim();
    if (text.isEmpty) return false;
    return text.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  bool get _isOtpInputEmail {
    final text = _otpIdentifierController.text.trim();
    if (text.isEmpty) return false;
    return text.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpIdentifierController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    final rawInput = _identifierController.text.trim();
    final password = _passwordController.text;

    if (rawInput.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Identifier Required',
        message: 'Please enter your mobile number or email address.',
      );
      return;
    }
    if (password.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Password Required',
        message: 'Please enter your account password.',
      );
      return;
    }

    final String identifier;
    if (_isPasswordInputEmail) {
      identifier = rawInput;
    } else {
      final clean = rawInput.replaceAll(RegExp(r'\D'), '');
      identifier = rawInput.startsWith('+')
          ? rawInput
          : '+${_selectedCountry.phoneCode}$clean';
    }

    final success = await _authController.loginWithPassword(
      identifier,
      password,
    );
    if (!mounted) return;

    if (success) {
      UniqueSnackbar.showSuccess(
        context,
        title: 'Login Successful',
        message:
            'Welcome back to ${_authController.currentUser.value?.firstName ?? 'XMedicoz'}!',
      );
      Get.offAllNamed(AppRoutes.main);
    } else {
      UniqueSnackbar.showError(
        context,
        title: 'Authentication Failed',
        message: _authController.errorMessage.value.isNotEmpty
            ? _authController.errorMessage.value
            : 'Invalid credentials. Please verify your details.',
      );
    }
  }

  Future<void> _handleSendOtp() async {
    final rawInput = _otpIdentifierController.text.trim();
    if (rawInput.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Identifier Required',
        message: 'Please enter your mobile number or registered email address.',
      );
      return;
    }

    if (_isOtpInputEmail) {
      if (!GetUtils.isEmail(rawInput)) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Invalid Email Address',
          message:
              'Please enter a valid email address (e.g. chemist@gmail.com).',
        );
        return;
      }

      final success = await _authController.requestOtp(
        rawInput,
        channel: 'EMAIL',
      );

      if (!mounted) return;

      if (success) {
        FocusManager.instance.primaryFocus?.unfocus();
        FocusScope.of(context).unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        UniqueOtpV7Sheet.show(context, phone: rawInput, channel: 'EMAIL');
      } else {
        UniqueSnackbar.showError(
          context,
          title: 'Failed to Send OTP',
          message: _authController.errorMessage.value.isNotEmpty
              ? _authController.errorMessage.value
              : 'Unable to request OTP from the server.',
        );
      }
    } else {
      final cleanPhone = rawInput.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length < 5) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Invalid Mobile Number',
          message: 'Please enter a valid mobile number.',
        );
        return;
      }

      final formattedPhone = rawInput.startsWith('+')
          ? rawInput
          : '+${_selectedCountry.phoneCode}$cleanPhone';
      final success = await _authController.requestOtp(
        formattedPhone,
        channel: 'PHONE',
      );

      if (!mounted) return;

      if (success) {
        FocusManager.instance.primaryFocus?.unfocus();
        FocusScope.of(context).unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        UniqueOtpV7Sheet.show(context, phone: formattedPhone, channel: 'PHONE');
      } else {
        UniqueSnackbar.showError(
          context,
          title: 'Failed to Send OTP',
          message: _authController.errorMessage.value.isNotEmpty
              ? _authController.errorMessage.value
              : 'Unable to request OTP from the server.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 80.h, 24.w, 20.h),
            child: Obx(() {
              final isBusy = _authController.isLoading.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon Badge
                  Container(
                    width: 60.r,
                    height: 60.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusLg,
                      ),
                      border: Border.all(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                        width: 1.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 16.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusLg - 1.5,
                      ),
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
                                size: 30.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  Text(AppStrings.loginTitle, style: AppTypography.h1),
                  SizedBox(height: 6.h),
                  Text(
                    'Access your Medical Store CRM',
                    style: AppTypography.bodyMedium,
                  ),

                  SizedBox(height: 20.h),

                  // Segmented Mode Switcher (Password vs OTP)
                  Container(
                    height: 44.h,
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusMd - 2,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? AppColors.primaryEmerald
                                    : AppColors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppDecorations.radiusMd - 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.key_rounded,
                                    size: 15.sp,
                                    color: _selectedTab == 0
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Password Login',
                                    style: TextStyle(
                                      color: _selectedTab == 0
                                          ? AppColors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 1),
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusMd - 2,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? AppColors.primaryEmerald
                                    : AppColors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppDecorations.radiusMd - 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sms_rounded,
                                    size: 15.sp,
                                    color: _selectedTab == 1
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'OTP Login',
                                    style: TextStyle(
                                      color: _selectedTab == 1
                                          ? AppColors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // TAB 0: Password Login View (Smart Auto-Detecting Phone vs Email)
                  if (_selectedTab == 0) ...[
                    AppTextField(
                      controller: _identifierController,
                      hintText: _isPasswordInputEmail
                          ? 'Enter registered email address'
                          : 'Enter mobile number or email',
                      labelText: _isPasswordInputEmail
                          ? 'Registered Email Address *'
                          : 'Mobile Number or Email *',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      prefixIcon: _isPasswordInputEmail
                          ? const Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryEmerald,
                            )
                          : CommonCountryCodePicker(
                              selectedCountry: _selectedCountry,
                              onCountryChanged: (c) =>
                                  setState(() => _selectedCountry = c),
                            ),
                      suffixIcon: _identifierController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                                size: 18.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  _identifierController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter account password',
                      labelText: 'Password *',
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    AppButton(
                      title: 'Sign In to Store',
                      icon: Icons.login_rounded,
                      isLoading: isBusy,
                      onPressed: _handlePasswordLogin,
                    ),
                  ] else ...[
                    // TAB 1: OTP Login View (Smart Auto-Detecting Phone vs Email)
                    AppTextField(
                      controller: _otpIdentifierController,
                      hintText: _isOtpInputEmail
                          ? 'Enter registered email address'
                          : 'Enter mobile number or email',
                      labelText: _isOtpInputEmail
                          ? 'Registered Email Address *'
                          : 'Mobile Number or Email *',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      prefixIcon: _isOtpInputEmail
                          ? const Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryEmerald,
                            )
                          : CommonCountryCodePicker(
                              selectedCountry: _selectedCountry,
                              onCountryChanged: (c) =>
                                  setState(() => _selectedCountry = c),
                            ),
                      suffixIcon: _otpIdentifierController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                                size: 18.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  _otpIdentifierController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    SizedBox(height: 24.h),
                    AppButton(
                      title: _isOtpInputEmail
                          ? 'Send Email OTP'
                          : 'Send Mobile OTP',
                      icon: _isOtpInputEmail
                          ? Icons.mark_email_read_rounded
                          : Icons.sms_rounded,
                      isLoading: isBusy,
                      onPressed: _handleSendOtp,
                    ),
                  ],

                  SizedBox(height: 28.h),

                  // Enterprise Security Note
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: AppColors.creditGreenLight,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Connected to Medical CRM.',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Center(
                    child: Text(
                      AppStrings.termsNotice,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
