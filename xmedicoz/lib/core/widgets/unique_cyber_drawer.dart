import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ledger_app/core/models/models.dart';
import 'package:ledger_app/features/auth/controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'marg_reports_sheet.dart';
import 'unique_snackbar.dart';
import 'unique_toggle_switch.dart';

/// Zoom & Slide Drawer Menu designed to match the perspective card layout.
/// Features a deep medical emerald background, pill-highlighted active items,
/// shop owner profile, biometric toggle, and high-end dialogs.
class UniqueCyberDrawerMenu extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onClose;
  final ShopModel activeShop;

  const UniqueCyberDrawerMenu({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onClose,
    required this.activeShop,
  });

  @override
  State<UniqueCyberDrawerMenu> createState() => _UniqueCyberDrawerMenuState();
}

class _UniqueCyberDrawerMenuState extends State<UniqueCyberDrawerMenu> {
  static const Color _drawerBgStart = Color(0xFF045D44); // Deep Medical Emerald
  static const Color _drawerBgEnd = Color(0xFF023627);   // Obsidian Emerald Forest
  static const Color _activeItemTextColor = Color(0xFF045D44); // Signature Emerald Ink

  bool _biometricsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final shop = widget.activeShop;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_drawerBgStart, _drawerBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: 0.65.sw,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),

              // 1. Profile Header (Avatar + Name + Role)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    // Avatar Ring
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.6.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10.r,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          shop.ownerName.isNotEmpty
                              ? shop.ownerName[0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.ownerName.isNotEmpty
                                ? shop.ownerName
                                : 'Dr. Chemist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            shop.name.isNotEmpty
                                ? shop.name
                                : 'Chief Pharmacist',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              // Top Divider
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),

              SizedBox(height: 10.h),

              // 2. Primary Navigation Menu Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMenuItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        isSelected: widget.selectedIndex == 0,
                        onTap: () {
                          widget.onTabSelected(0);
                          widget.onClose();
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        isSelected: false,
                        onTap: () {
                          widget.onClose();
                          Get.toNamed(AppRoutes.editProfile);
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.inventory_2_rounded,
                        title: 'Inventory & Stock',
                        isSelected: widget.selectedIndex == 1,
                        onTap: () {
                          widget.onTabSelected(1);
                          widget.onClose();
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.receipt_long_rounded,
                        title: 'Daybook & Sales',
                        isSelected: widget.selectedIndex == 3,
                        onTap: () {
                          widget.onTabSelected(3);
                          widget.onClose();
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.groups_rounded,
                        title: 'Parties & Ledger',
                        isSelected: widget.selectedIndex == 2,
                        onTap: () {
                          widget.onTabSelected(2);
                          widget.onClose();
                        },
                      ),

                      SizedBox(height: 12.h),

                      // Secondary Section Divider
                      Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(horizontal: 6.w),
                        color: Colors.white.withValues(alpha: 0.16),
                      ),

                      SizedBox(height: 12.h),

                      // 3. Secondary Actions & Controls
                      _buildMenuItem(
                        icon: Icons.person_search_rounded,
                        title: 'Customer CRM & Refills',
                        isSelected: false,
                        onTap: () {
                          widget.onClose();
                          Get.toNamed(AppRoutes.crmHub);
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.analytics_rounded,
                        title: 'Marg Reports',
                        isSelected: false,
                        onTap: () {
                          widget.onClose();
                          MargReportsSheet.show(context);
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.print_rounded,
                        title: 'Printer POS',
                        isSelected: false,
                        onTap: () {
                          widget.onClose();
                          _showPrinterDialog(context);
                        },
                      ),
                      SizedBox(height: 4.h),

                      // Biometric / Fingerprint Lock Toggle Switch
                      _buildToggleItem(
                        icon: Icons.fingerprint_rounded,
                        title: 'Fingerprint Lock',
                        value: _biometricsEnabled,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _biometricsEnabled = val);
                          UniqueSnackbar.showSuccess(
                            context,
                            title: val ? 'Biometrics Active' : 'Biometrics Off',
                            message: val
                                ? 'Fingerprint quick authentication enabled.'
                                : 'Fingerprint app lock disabled.',
                          );
                        },
                      ),

                      SizedBox(height: 4.h),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        isSelected: false,
                        onTap: () {
                          widget.onClose();
                          _showHelpDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Section Divider
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),

              SizedBox(height: 8.h),

              // 4. Logout Action
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
                child: _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isSelected: false,
                  isLogout: true,
                  onTap: () => _confirmLogout(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final textColor = isSelected
        ? _activeItemTextColor
        : Colors.white.withValues(alpha: isLogout ? 0.95 : 0.88);
    final iconColor = isSelected
        ? _activeItemTextColor
        : Colors.white.withValues(alpha: isLogout ? 0.95 : 0.85);

    return Container(
      width: 0.53.sw,
      height: 42.h,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19.sp,
                  color: iconColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: 0.53.sw,
      height: 42.h,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19.sp,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          UniqueToggleSwitch(
            value: value,
            width: 40.w,
            height: 22.h,
            activeColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showPrinterDialog(BuildContext context) {
    int selectedPaperWidth = 80; // 80mm or 58mm
    bool autoCutEnabled = true;
    bool printQrEnabled = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                width: 1.2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 32.r,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Printer Emblem + Title + Close Button
                Row(
                  children: [
                    Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                            blurRadius: 14.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.print_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thermal POS Printer',
                            style: AppTypography.h3.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'High-Speed ESC/POS Billing Hub',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20.sp),
                      color: AppColors.textMuted,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Connected Hardware Status Card
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bluetooth_connected_rounded,
                          color: AppColors.primaryEmerald,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'POS-80 Bluetooth Wireless',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkContrast,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryEmerald
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5.r,
                                        height: 5.r,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryEmerald,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Ready',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryEmeraldDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'MAC: 00:1B:44:11:3A • 203 DPI Fast Thermal',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Paper Width Selection
                Text(
                  'PAPER ROLL WIDTH',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() => selectedPaperWidth = 58);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: selectedPaperWidth == 58
                                ? AppColors.primaryEmerald
                                : AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: selectedPaperWidth == 58
                                  ? AppColors.primaryEmerald
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '58mm (2-inch)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: selectedPaperWidth == 58
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() => selectedPaperWidth = 80);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: selectedPaperWidth == 80
                                ? AppColors.primaryEmerald
                                : AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: selectedPaperWidth == 80
                                  ? AppColors.primaryEmerald
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '80mm (3-inch Marg)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: selectedPaperWidth == 80
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                // Bill Format Toggles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Auto-Cut Paper After Bill',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkContrast,
                      ),
                    ),
                    Switch(
                      value: autoCutEnabled,
                      activeThumbColor: AppColors.primaryEmerald,
                      onChanged: (val) =>
                          setDialogState(() => autoCutEnabled = val),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Print GSTIN & QR Payment Code',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkContrast,
                      ),
                    ),
                    Switch(
                      value: printQrEnabled,
                      activeThumbColor: AppColors.primaryEmerald,
                      onChanged: (val) =>
                          setDialogState(() => printQrEnabled = val),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 16.sp,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(
                          'Scan New',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          UniqueSnackbar.showSuccess(
                            context,
                            title: 'Bluetooth Scanner',
                            message: 'Scanning for nearby BLE thermal devices...',
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryEmerald
                                  .withValues(alpha: 0.35),
                              blurRadius: 14.r,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.receipt_long_rounded,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Print Test Receipt',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                            UniqueSnackbar.showSuccess(
                              context,
                              title: 'Receipt Printed',
                              message:
                                  'Test bill sent to POS-80 ($selectedPaperWidth mm) successfully.',
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.25),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32.r,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Support Icon Badge
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                      blurRadius: 18.r,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                'Pharmacy Support Desk',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkContrast,
                  letterSpacing: -0.3,
                ),
              ),

              SizedBox(height: 6.h),

              Text(
                '24x7 Dedicated Chemist & Billing Helpline',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
              ),

              SizedBox(height: 16.h),

              // Contact cards
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_in_talk_rounded,
                            color: AppColors.primaryEmerald, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            '1800-419-MEDS (Toll Free)',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkContrast,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            color: AppColors.clinicalCyan, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'support@xmedicoz.com',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Got It',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32.r,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Rose/Red Power Off Icon Badge
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      blurRadius: 20.r,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ),

              SizedBox(height: 18.h),

              // Title
              Text(
                'Sign Out of Workspace?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkContrast,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'All local ledger bills, daybook vouchers, and counter balances are saved safely. You can sign back in anytime.',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Active Store Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 15.sp,
                      color: AppColors.primaryEmerald,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        widget.activeShop.name.isNotEmpty
                            ? widget.activeShop.name
                            : 'Medical Store Workspace',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkContrast,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22.h),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.35),
                            blurRadius: 14.r,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          widget.onClose();
                          final authController = Get.find<AuthController>();
                          await authController.logout();
                          Get.offAllNamed(AppRoutes.login);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility placeholder widget in case referenced elsewhere
class UniqueCyberDrawer extends StatelessWidget {
  const UniqueCyberDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
