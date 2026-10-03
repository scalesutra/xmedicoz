import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

export 'package:country_picker/country_picker.dart';

/// Common reusable country code picker widget powered by `country_picker` package
class CommonCountryCodePicker extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;

  const CommonCountryCodePicker({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  static Country get defaultCountry => Country.parse('IN');

  void _showPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['IN', 'PK', 'AE', 'SA', 'US', 'GB'],
      countryListTheme: CountryListThemeData(
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.76,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        backgroundColor: AppColors.bgSurface,
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        searchTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country name or dial code...',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.sp,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryEmerald,
          ),
          filled: true,
          fillColor: AppColors.bgPrimary,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.primaryEmerald,
              width: 1.8,
            ),
          ),
        ),
      ),
      onSelect: onCountryChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flagEmoji,
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(width: 4.w),
            Text(
              '+${selectedCountry.phoneCode}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
              size: 18.sp,
            ),
            Container(
              height: 20.h,
              width: 1.w,
              margin: EdgeInsets.only(left: 4.w, right: 6.w),
              color: AppColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
