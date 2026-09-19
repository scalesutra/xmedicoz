import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/controllers/ledger_controller.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/unique_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = Get.find<LedgerController>();

  late TextEditingController _ownerNameCtrl;
  late TextEditingController _shopNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dlCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _cityCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final shop = controller.activeShop.value;
    _ownerNameCtrl = TextEditingController(text: shop.ownerName);
    _shopNameCtrl = TextEditingController(text: shop.name);
    _phoneCtrl = TextEditingController(text: shop.phone);
    _dlCtrl = TextEditingController(text: shop.drugLicenseNo);
    _gstinCtrl = TextEditingController(text: shop.gstin ?? '');
    _cityCtrl = TextEditingController(text: shop.city);
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _shopNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dlCtrl.dispose();
    _gstinCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final ownerName = _ownerNameCtrl.text.trim();
    final shopName = _shopNameCtrl.text.trim();

    if (ownerName.isEmpty || shopName.isEmpty) {
      UniqueSnackbar.showError(
        context,
        title: 'Missing Required Fields',
        message: 'Owner Name and Medical Store Name are required.',
      );
      return;
    }

    setState(() => _isSaving = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final current = controller.activeShop.value;
      final updatedShop = ShopModel(
        id: current.id,
        name: shopName,
        category: current.category,
        ownerName: ownerName,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : current.phone,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : current.city,
        drugLicenseNo: _dlCtrl.text.trim().isNotEmpty ? _dlCtrl.text.trim().toUpperCase() : current.drugLicenseNo,
        gstin: _gstinCtrl.text.trim().isNotEmpty ? _gstinCtrl.text.trim().toUpperCase() : null,
        cashInHand: current.cashInHand,
        bankBalance: current.bankBalance,
        bankName: current.bankName,
      );

      // Update in controller
      controller.updateShop(updatedShop);

      setState(() => _isSaving = false);

      UniqueSnackbar.showSuccess(
        context,
        title: 'Pharmacy Profile Saved',
        message: 'Store details & Drug License credentials updated successfully!',
      );

      Get.back();
    });
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Edit Pharmacy Profile',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: const Icon(Icons.check_rounded, color: AppColors.primaryEmerald, size: 18),
                label: Text(
                  'SAVE',
                  style: TextStyle(
                    color: AppColors.primaryEmerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 36.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Avatar Header Card
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 86.r,
                            height: 86.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              border: Border.all(color: AppColors.white, width: 3.w),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                                  blurRadius: 20.r,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _ownerNameCtrl.text.trim().isNotEmpty
                                    ? _ownerNameCtrl.text.trim()[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 34.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2.w),
                            ),
                            child: Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 15.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: AppDecorations.badge(color: AppColors.primaryEmerald),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, size: 13.sp, color: AppColors.primaryEmerald),
                            SizedBox(width: 5.w),
                            Text(
                              'REGISTERED PHARMACIST',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.primaryEmeraldDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // 2. Personal & Pharmacist Details Section
                _sectionHeader('PHARMACIST & OWNER INFO', Icons.person_rounded),
                SizedBox(height: 12.h),

                AppTextField(
                  controller: _ownerNameCtrl,
                  hintText: 'e.g. Rajesh Kumar Sharma, R.Ph.',
                  labelText: 'Pharmacist / Owner Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryEmerald),
                ),

                SizedBox(height: 14.h),

                AppTextField(
                  controller: _phoneCtrl,
                  hintText: '+91 98201 00000',
                  labelText: 'Contact Phone Number',
                  prefixIcon: const Icon(Icons.call_rounded, color: AppColors.textSecondary),
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 24.h),

                // 3. Medical Store & License Section
                _sectionHeader('RETAIL PHARMACY DETAILS', Icons.storefront_rounded),
                SizedBox(height: 12.h),

                AppTextField(
                  controller: _shopNameCtrl,
                  hintText: 'e.g. Sanjivani Medical & Chemist Store',
                  labelText: 'Medical Store Trade Name',
                  prefixIcon: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primaryEmerald),
                ),

                SizedBox(height: 14.h),

                AppTextField(
                  controller: _dlCtrl,
                  hintText: 'e.g. DL-20B/21B-449102',
                  labelText: 'Drug License Number (DL 20B/21B)',
                  prefixIcon: const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryEmerald),
                ),

                SizedBox(height: 14.h),

                AppTextField(
                  controller: _cityCtrl,
                  hintText: 'e.g. Connaught Place, New Delhi',
                  labelText: 'Store Location / City',
                  prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                ),

                SizedBox(height: 14.h),

                AppTextField(
                  controller: _gstinCtrl,
                  hintText: 'e.g. 07AAAAA0000A1Z5 (Optional)',
                  labelText: 'GSTIN Number (Optional for Chemists)',
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.textMuted),
                ),

                SizedBox(height: 32.h),

                // 4. Save Button
                AppButton(
                  title: 'Save Profile Changes',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSaving,
                  onPressed: _saveProfile,
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primaryEmerald),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
