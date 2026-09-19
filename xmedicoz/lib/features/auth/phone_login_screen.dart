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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpEmailController = TextEditingController();
  String _otpChannel = 'PHONE'; // 'PHONE' or 'EMAIL'

  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpEmailController.dispose();
    super.dispose();
  }

  void _prefillTestAdmin() {
    HapticFeedback.lightImpact();
    _selectedTab = 0;
    _identifierController.text = 'admin@medicalcrm.local';
    _passwordController.text = 'Admin@MedicalCRM123';
    _identifierController.selection = TextSelection.fromPosition(
      TextPosition(offset: _identifierController.text.length),
    );
    _passwordController.selection = TextSelection.fromPosition(
      TextPosition(offset: _passwordController.text.length),
    );
    if (mounted) setState(() {});
    UniqueSnackbar.showSuccess(
      context,
      title: 'Admin Credentials',
      message: 'Test credentials filled successfully.',
    );
  }

  Future<void> _handlePasswordLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Identifier Required',
        message: 'Please enter your email or phone number.',
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

    final success = await _authController.loginWithPassword(identifier, password);
    if (!mounted) return;

    if (success) {
      UniqueSnackbar.showSuccess(
        context,
        title: 'Login Successful',
        message: 'Welcome back to ${_authController.currentUser.value?.firstName ?? 'XMedicoz'}!',
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
    if (_otpChannel == 'PHONE') {
      final phone = _phoneController.text.trim();
      if (phone.length < 10) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Invalid Mobile Number',
          message: 'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';
      final success = await _authController.requestOtp(
        formattedPhone,
        channel: 'PHONE',
      );

      if (!mounted) return;

      if (success) {
        UniqueOtpV7Sheet.show(
          context,
          phone: formattedPhone,
          channel: 'PHONE',
        );
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
      final email = _otpEmailController.text.trim();
      if (email.isEmpty || !GetUtils.isEmail(email)) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Invalid Email Address',
          message: 'Please enter a valid email address (e.g. chemist@gmail.com).',
        );
        return;
      }

      final success = await _authController.requestOtp(
        email,
        channel: 'EMAIL',
      );

      if (!mounted) return;

      if (success) {
        UniqueOtpV7Sheet.show(
          context,
          phone: email,
          channel: 'EMAIL',
        );
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
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            child: Obx(() {
              final isBusy = _authController.isLoading.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60.r,
                        height: 60.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
                          border: Border.all(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                            width: 1.5.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                              blurRadius: 16.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDecorations.radiusLg - 1.5),
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
                      // Quick Test Admin Fill button
                      if (_selectedTab == 0)
                        InkWell(
                          onTap: _prefillTestAdmin,
                          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
                              border: Border.all(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flash_on_rounded,
                                  color: AppColors.primaryEmerald,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Fill Test Admin',
                                  style: TextStyle(
                                    color: AppColors.primaryEmerald,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  Text(AppStrings.loginTitle, style: AppTypography.h1),
                  SizedBox(height: 6.h),
                  Text(
                    'Access your Medical Store CRM & Autonomous Daybook',
                    style: AppTypography.bodyMedium,
                  ),

                  SizedBox(height: 20.h),

                  // Segmented Mode Switcher (Password vs OTP)
                  Container(
                    height: 44.h,
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: BorderRadius.circular(AppDecorations.radiusMd - 2),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? AppColors.primaryEmerald
                                    : AppColors.transparent,
                                borderRadius: BorderRadius.circular(AppDecorations.radiusMd - 2),
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
                            borderRadius: BorderRadius.circular(AppDecorations.radiusMd - 2),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? AppColors.primaryEmerald
                                    : AppColors.transparent,
                                borderRadius: BorderRadius.circular(AppDecorations.radiusMd - 2),
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

                  // TAB 0: Password Login View
                  if (_selectedTab == 0) ...[
                    AppTextField(
                      controller: _identifierController,
                      hintText: 'admin@xmedicoz.com or +91 98765 43210',
                      labelText: 'Email or Mobile Number',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter account password',
                      labelText: 'Password',
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
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
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
                    // TAB 1: OTP Login View (Mobile or Email)
                    Container(
                      height: 38.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(2.5.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _otpChannel = 'PHONE'),
                              borderRadius: BorderRadius.circular(AppDecorations.radiusSm - 2),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _otpChannel == 'PHONE'
                                      ? AppColors.primaryEmerald.withValues(alpha: 0.18)
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm - 2),
                                  border: Border.all(
                                    color: _otpChannel == 'PHONE'
                                        ? AppColors.primaryEmerald
                                        : AppColors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_android_rounded,
                                      size: 13.sp,
                                      color: _otpChannel == 'PHONE'
                                          ? AppColors.primaryEmerald
                                          : AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Mobile OTP',
                                      style: TextStyle(
                                        color: _otpChannel == 'PHONE'
                                            ? AppColors.primaryEmerald
                                            : AppColors.textSecondary,
                                        fontWeight: _otpChannel == 'PHONE'
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 11.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _otpChannel = 'EMAIL'),
                              borderRadius: BorderRadius.circular(AppDecorations.radiusSm - 2),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _otpChannel == 'EMAIL'
                                      ? AppColors.primaryEmerald.withValues(alpha: 0.18)
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm - 2),
                                  border: Border.all(
                                    color: _otpChannel == 'EMAIL'
                                        ? AppColors.primaryEmerald
                                        : AppColors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 13.sp,
                                      color: _otpChannel == 'EMAIL'
                                          ? AppColors.primaryEmerald
                                          : AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Email OTP',
                                      style: TextStyle(
                                        color: _otpChannel == 'EMAIL'
                                            ? AppColors.primaryEmerald
                                            : AppColors.textSecondary,
                                        fontWeight: _otpChannel == 'EMAIL'
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 11.5.sp,
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
                    if (_otpChannel == 'PHONE')
                      AppTextField(
                        controller: _phoneController,
                        hintText: 'Enter 10-digit number',
                        labelText: AppStrings.phoneHint,
                        prefixText: AppStrings.phonePrefix,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        prefixIcon: const Icon(
                          Icons.call_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      AppTextField(
                        controller: _otpEmailController,
                        hintText: 'chemist@xmedicoz.com',
                        labelText: 'Registered Email Address',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    SizedBox(height: 24.h),
                    AppButton(
                      title: _otpChannel == 'EMAIL'
                          ? 'Send 4-Digit Email OTP'
                          : AppStrings.sendOtp,
                      icon: Icons.send_rounded,
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
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
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
                            'Connected to Medical CRM Server (AES-256 Auth & Keycloak Tokens).',
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
                      style: AppTypography.bodySmall.copyWith(fontSize: 10.5.sp),
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
