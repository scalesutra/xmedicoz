import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/models/purchase_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Signature Cyber-Pharma Animated Stock Purchase Success Modal.
/// Displays an animated emerald checkmark with glowing rings, invoice summary,
/// and live catalog & batch confirmation.
class PurchaseSuccessModal extends StatefulWidget {
  final PurchaseInvoiceModel? invoice;
  final String? invoiceNumber;
  final String? supplierName;
  final double? totalAmount;
  final int? itemCount;
  final VoidCallback? onDone;

  const PurchaseSuccessModal({
    super.key,
    this.invoice,
    this.invoiceNumber,
    this.supplierName,
    this.totalAmount,
    this.itemCount,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    PurchaseInvoiceModel? invoice,
    String? invoiceNumber,
    String? supplierName,
    double? totalAmount,
    int? itemCount,
    VoidCallback? onDone,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PurchaseSuccess',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, anim, secondaryAnim) => PurchaseSuccessModal(
        invoice: invoice,
        invoiceNumber: invoiceNumber,
        supplierName: supplierName,
        totalAmount: totalAmount,
        itemCount: itemCount,
        onDone: onDone,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<PurchaseSuccessModal> createState() => _PurchaseSuccessModalState();
}

class _PurchaseSuccessModalState extends State<PurchaseSuccessModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _checkScaleAnim;
  late final Animation<double> _glowPulseAnim;
  final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _checkScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _glowPulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invNo = widget.invoice?.invoiceNumber ??
        widget.invoiceNumber ??
        'INV-NEW';
    final supp = widget.invoice?.supplier?.name ??
        widget.supplierName ??
        'Stockist Supplier';
    final total = widget.invoice?.totalAmount ?? widget.totalAmount ?? 0.0;
    final count = widget.invoice?.itemCount ??
        widget.invoice?.items.length ??
        widget.itemCount ??
        1;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 420.w),
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Success Checkmark & Glow Halo
                _buildAnimatedHeader(),
                SizedBox(height: 16.h),

                // Title & Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'STOCK INWARD VERIFIED',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryEmeraldDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Purchase Inward Saved!',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkContrast,
                    fontSize: 20.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Batch stocks, medicine catalog, and supplier balance updated.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18.h),

                // Invoice Overview Card
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INVOICE NO',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                invNo,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkContrast,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 13.sp,
                                  color: AppColors.primaryEmeraldDark,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$count Items',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primaryEmeraldDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Divider(color: AppColors.borderSubtle, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SUPPLIER',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  supp,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkContrast,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL INWARD',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _currencyFmt.format(total),
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryEmeraldDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Status updates indicators
                Row(
                  children: [
                    _buildFeaturePill(
                      icon: Icons.check_circle_rounded,
                      text: 'Stock Added',
                    ),
                    SizedBox(width: 6.w),
                    _buildFeaturePill(
                      icon: Icons.qr_code_2_rounded,
                      text: 'Batches Tracked',
                    ),
                    SizedBox(width: 6.w),
                    _buildFeaturePill(
                      icon: Icons.account_balance_wallet_outlined,
                      text: 'Ledger Posted',
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Done Button
                AppButton(
                  title: 'Done & Return',
                  icon: Icons.check_rounded,
                  isFullWidth: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    widget.onDone?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Halo
            Transform.scale(
              scale: _glowPulseAnim.value,
              child: Container(
                width: 84.w,
                height: 84.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryEmerald.withValues(alpha: 0.25),
                    AppColors.clinicalCyan.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Inner check circle with bounce scale
            Transform.scale(
              scale: _checkScaleAnim.value,
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryEmerald,
                      AppColors.primaryEmeraldLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturePill({required IconData icon, required String text}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppColors.bgCardHover,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 11.sp,
              color: AppColors.primaryEmeraldDark,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                text,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkContrast,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
