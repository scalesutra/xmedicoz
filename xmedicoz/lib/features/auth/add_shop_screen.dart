import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../../core/widgets/country_code_picker.dart';
import 'controllers/auth_controller.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _dlCtrl = TextEditingController(); // Drug License
  final TextEditingController _gstinCtrl = TextEditingController(); // Optional
  final TextEditingController _cashCtrl = TextEditingController();
  final TextEditingController _bankCtrl = TextEditingController();
  Country _selectedCountry = CommonCountryCodePicker.defaultCountry;

  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _dlCtrl.dispose();
    _gstinCtrl.dispose();
    _cashCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateShop() async {
    final name = _shopNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final address = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final dlNo = _dlCtrl.text.trim();
    final cash = double.tryParse(_cashCtrl.text.trim());
    final bank = double.tryParse(_bankCtrl.text.trim());

    if (name.isEmpty || phone.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Missing Required Fields',
        message: 'Please provide Pharmacy Name * and Mobile Number *.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final authController = Get.find<AuthController>();

    // Update user profile with owner name and email if available
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone =
        phone.startsWith('+') ? phone : '+${_selectedCountry.phoneCode}$cleanPhone';

    if (ownerName.isNotEmpty || email.isNotEmpty || password.isNotEmpty) {
      await authController.updateProfile(
        firstName: ownerName.isNotEmpty ? ownerName : null,
        phone: fullPhone.isNotEmpty ? fullPhone : null,
        email: email.isNotEmpty ? email : null,
        password: password.isNotEmpty ? password : null,
      );
    }

    final shopData = <String, dynamic>{
      "name": name,
      "phone": fullPhone,
      if (email.isNotEmpty) "email": email,
      if (dlNo.isNotEmpty) "drugLicenseNo": dlNo.toUpperCase(),
      if (_gstinCtrl.text.trim().isNotEmpty) "gstin": _gstinCtrl.text.trim().toUpperCase(),
      if (address.isNotEmpty) "address": address,
      if (city.isNotEmpty) "city": city,
      if (ownerName.isNotEmpty) "ownerName": ownerName,
      "planCode": "TRIAL",
      if (password.isNotEmpty) "password": password,
      if (cash != null && cash > 0) "openingCashBalance": cash,
      if (bank != null && bank > 0) "openingBankBalance": bank,
    };

    final newShop = await authController.registerShop(shopData);
    
    if (newShop != null) {
      if (mounted) {
        UniqueSnackbar.showSuccess(
          context,
          title: 'Pharmacy Store Created',
          message: 'Pharmacy "${newShop.name}" created and loaded into active session!',
        );
      }
      Get.offAllNamed(AppRoutes.main);
    } else {
      if (mounted) {
        UniqueSnackbar.showError(
          context,
          title: 'Registration Failed',
          message: authController.errorMessage.value.isNotEmpty 
            ? authController.errorMessage.value 
            : 'Could not create shop. Try again.',
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          title: Text(AppStrings.addShopTitle, style: AppTypography.h3),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dedicated Retail Chemist Branch Card
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                    width: 1.2.w,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      ),
                      child: Icon(
                        Icons.local_pharmacy_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Retail Chemist & Medical Store',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmeraldDark,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Single-Counter & Multi-Branch Retail Pharmacy POS',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22.h),

              // Account Setup Section
              Text('Setup Owner Account', style: AppTypography.h3),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _phoneCtrl,
                hintText: 'Enter mobile number',
                labelText: 'Pharmacy Mobile Number *',
                prefixIcon: CommonCountryCodePicker(
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (c) => setState(() => _selectedCountry = c),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _ownerNameCtrl,
                hintText: 'e.g. Dr. Rajesh Sharma (R.Ph)',
                labelText: 'Owner / Chemist Name (Optional)',
                prefixIcon: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
              ),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _emailCtrl,
                hintText: 'your.email@example.com',
                labelText: 'Email Address (Optional)',
                prefixIcon: const Icon(Icons.email_rounded, color: AppColors.textSecondary),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _passwordCtrl,
                hintText: 'Set a strong password for login',
                labelText: 'Account Password (Optional)',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              SizedBox(height: 32.h),

              // Pharmacy Details Section
              Text('Pharmacy Details & License', style: AppTypography.h3),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _shopNameCtrl,
                hintText: 'e.g. Sanjivani Medical & Chemist Store',
                labelText: 'Pharmacy Name *',
                prefixIcon: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primaryEmerald),
              ),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _addressCtrl,
                hintText: 'e.g. Shop #12, Market Complex',
                labelText: 'Street Address (Optional)',
                prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.textSecondary),
              ),
              SizedBox(height: 14.h),

              AppTextField(
                controller: _cityCtrl,
                hintText: 'City, Area',
                labelText: 'City / Region (Optional)',
                prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
              ),
              SizedBox(height: 14.h),

              // Drug License Field (Crucial for Medical Store)
              AppTextField(
                controller: _dlCtrl,
                hintText: 'e.g. DL-20B/21B-449102',
                labelText: 'Drug License Number (DL No.) (Optional)',
                prefixIcon: const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryEmerald),
              ),
              SizedBox(height: 14.h),

              // GSTIN FIELD (EXPLICITLY OPTIONAL)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                  border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16.sp, color: AppColors.primaryEmerald),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'GST Number is completely Optional for Chemists',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryEmerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    AppTextField(
                      controller: _gstinCtrl,
                      hintText: 'e.g. 07AAAAA0000A1Z5 (Leave blank if none)',
                      labelText: AppStrings.gstinOptional,
                      helperText: AppStrings.gstinHelper,
                      prefixIcon: const Icon(Icons.verified_user_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Opening Balances (Counter Cash & Bank)
              Text('Initial Opening Cash & Bank', style: AppTypography.h4),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cashCtrl,
                      hintText: '₹ 25000',
                      labelText: 'Counter Cash (₹)',
                      prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.cashGold),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppTextField(
                      controller: _bankCtrl,
                      hintText: '₹ 120000',
                      labelText: 'Bank Balance (₹)',
                      prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.onlineBlue),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Submit Button
              AppButton(
                title: AppStrings.createShopButton,
                isLoading: _isLoading,
                icon: Icons.check_circle_rounded,
                onPressed: _handleCreateShop,
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
