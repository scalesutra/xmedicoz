import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_button.dart';

class OnboardingItem {
  final String title;
  final String highlight;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> tags;

  const OnboardingItem({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tags,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingItem> _slides = [
    OnboardingItem(
      title: 'Doctor Prescription',
      highlight: 'Fast Rx Counter Billing',
      subtitle:
          'Create GST cash memos & doctor prescription invoices in under 10 seconds. Print 2"/3" thermal receipts or send instant PDF bills on WhatsApp.',
      icon: Icons.local_pharmacy_rounded,
      accentColor: AppColors.primaryEmerald,
      tags: ['2" & 3" Thermal Print', 'Schedule H/H1 Warning', 'Instant WhatsApp Rx'],
    ),
    OnboardingItem(
      title: 'Zero Stock Wastage',
      highlight: 'Batch & Expiry Radar',
      subtitle:
          'Track every medicine strip with Batch No, Expiry Date, and Rack location. Get automatic 60-day expiry warnings to return stock on time.',
      icon: Icons.alarm_on_rounded,
      accentColor: AppColors.clinicalCyan,
      tags: ['Near-Expiry Badges', 'Cold Chain / Rack Shelf', 'Zero Loss Guarantee'],
    ),
    OnboardingItem(
      title: 'Accounts Receivable',
      highlight: 'Customer Ledger & Outstanding',
      subtitle:
          'Track customer balances and clinic receivables effortlessly. Send automated WhatsApp payment reminders with dynamic UPI payment QR.',
      icon: Icons.groups_rounded,
      accentColor: AppColors.creditGreen,
      tags: ['Automated Reminders', 'Dynamic UPI QR', 'Aging Analysis'],
    ),
    OnboardingItem(
      title: 'Distributor Inward',
      highlight: 'Purchase Bills & Daybook',
      subtitle:
          'Record stockist purchase bills, calculate purchase margins, and check today\'s net counter profit at shop closing with zero accounting hassle.',
      icon: Icons.warehouse_rounded,
      accentColor: AppColors.primaryBlue,
      tags: ['Purchase Rate Margin', 'Supplier Payables', 'Daily Counter Profit'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      StorageService.setSeenOnboarding();
      Get.offNamed(AppRoutes.login);
    }
  }

  void _onSkip() {
    StorageService.setSeenOnboarding();
    Get.offNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: Brand Pill + Skip Button
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 16.w, 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: AppDecorations.badge(color: AppColors.primaryEmerald),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 14.sp,
                            color: AppColors.primaryEmerald,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'RETAIL CHEMIST EDITION',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.primaryEmeraldDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return _buildSlideContent(item);
                  },
                ),
              ),

              // Bottom Section: Indicators & Action Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
                child: Column(
                  children: [
                    // Smooth Animated Pill Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (idx) {
                        final isSelected = _currentPage == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: isSelected ? 26.w : 7.w,
                          height: 7.h,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryEmerald
                                : AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(4.r),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                                      blurRadius: 6.r,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 24.h),

                    // Primary Action Button
                    AppButton(
                      title: _currentPage == _slides.length - 1
                          ? 'Start Retail Counter'
                          : 'Next Feature',
                      icon: _currentPage == _slides.length - 1
                          ? Icons.local_pharmacy_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _onNext,
                    ),

                    SizedBox(height: 12.h),

                    // Trust Compliance Note
                    Text(
                      '100% Drug License & GST Compliant • Made for Retail Chemists',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5.sp,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(OnboardingItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic 3D Orb / Card Container
          Container(
            width: 170.r,
            height: 170.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  item.accentColor.withValues(alpha: 0.12),
                  item.accentColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.35),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.accentColor.withValues(alpha: 0.25),
                  blurRadius: 36.r,
                  spreadRadius: 2.r,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background ring
                Container(
                  width: 130.r,
                  height: 130.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.accentColor.withValues(alpha: 0.2),
                      width: 1.2.w,
                    ),
                  ),
                ),
                // Icon
                Icon(
                  item.icon,
                  size: 72.sp,
                  color: item.accentColor,
                ),
              ],
            ),
          ),

          SizedBox(height: 36.h),

          // Title & Highlight
          Text(
            item.title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              color: item.accentColor,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 6.h),

          Text(
            item.highlight,
            style: AppTypography.h1.copyWith(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          Text(
            item.subtitle,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),

          // Feature Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: item.tags.map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(
                    color: item.accentColor.withValues(alpha: 0.3),
                    width: 0.9.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13.sp,
                      color: item.accentColor,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
