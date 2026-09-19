import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/controllers/ledger_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/unique_cyber_drawer.dart';
import '../../core/widgets/unique_cyber_nav_bar.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../ledger/ledger_screen.dart';
import '../vouchers/marg_sale_invoice_modal.dart';
import '../vouchers/vouchers_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _drawerController;
  late final Animation<double> _animCurve;
  late final LedgerController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LedgerController());
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      reverseDuration: const Duration(milliseconds: 170),
    );
    _animCurve = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad,
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    HapticFeedback.mediumImpact();
    _drawerController.forward();
  }

  void _closeDrawer() {
    HapticFeedback.lightImpact();
    _drawerController.reverse();
  }

  void _toggleDrawer() {
    if (_drawerController.value > 0.5) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
      final activeShop = controller.activeShop.value;

      final List<Widget> screens = [
        DashboardScreen(
          onNavigateToInventory: () => setState(() => _currentIndex = 1),
          onNavigateToLedger: () => setState(() => _currentIndex = 2),
          onNavigateToVouchers: () => setState(() => _currentIndex = 3),
          onToggleDrawer: _toggleDrawer,
        ),
        InventoryScreen(activeShop: activeShop),
        LedgerScreen(activeShop: activeShop),
        VouchersScreen(activeShop: activeShop),
      ];

      // Pre-composed, GPU-cached main screen content.
      // Wrapped in RepaintBoundary to avoid re-laying out the dashboard tree during animation.
      final Widget mainCardContent = RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28.r,
                spreadRadius: 1.r,
                offset: const Offset(-8, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: AppBackground(
              child: Scaffold(
                backgroundColor: AppColors.transparent,
                extendBody: true,
                resizeToAvoidBottomInset: false,
                body: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
                bottomNavigationBar: UniqueCyberNavBar(
                  selectedIndex: _currentIndex,
                  onTabSelected: (index) =>
                      setState(() => _currentIndex = index),
                  onFabPressed: () => MargSaleInvoiceModal.show(context),
                ),
              ),
            ),
          ),
        ),
      );

      return AnimatedBuilder(
        animation: _animCurve,
        child: mainCardContent,
        builder: (context, cachedChild) {
          final value = _animCurve.value;
          final isDrawerOpen = value > 0.05;

          return PopScope(
            canPop: !isDrawerOpen,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _closeDrawer();
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: const Color(0xFF023627), // Deep Obsidian Emerald base
              body: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  // Edge swipe to open
                  if (_drawerController.value == 0 &&
                      details.globalPosition.dx < 40.w &&
                      (details.primaryDelta ?? 0) > 6) {
                    _openDrawer();
                  }
                },
                child: Stack(
                  children: [
                    // 1. Drawer Menu in Background
                    UniqueCyberDrawerMenu(
                      selectedIndex: _currentIndex,
                      onTabSelected: (index) =>
                          setState(() => _currentIndex = index),
                      onClose: _closeDrawer,
                      activeShop: activeShop,
                    ),

                    // 2. Hardware-accelerated perspective card transformation
                    if (value == 0)
                      // Fast-path: When closed, render directly without transforms
                      AppBackground(
                        child: Scaffold(
                          backgroundColor: AppColors.transparent,
                          extendBody: true,
                          resizeToAvoidBottomInset: false,
                          body: IndexedStack(
                            index: _currentIndex,
                            children: screens,
                          ),
                          bottomNavigationBar: UniqueCyberNavBar(
                            selectedIndex: _currentIndex,
                            onTabSelected: (index) =>
                                setState(() => _currentIndex = index),
                            onFabPressed: () =>
                                MargSaleInvoiceModal.show(context),
                          ),
                        ),
                      )
                    else ...[
                      // Secondary depth card layer peeking out (lightweight)
                      Transform(
                        transform: Matrix4.identity()
                          ..translate(screenWidth * 0.58 * value, 0)
                          ..scale(1.0 - (0.26 * value)),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16 * value),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                        ),
                      ),

                      // Main Scaled Card using pre-cached GPU texture
                      Transform(
                        transform: Matrix4.identity()
                          ..translate(screenWidth * 0.68 * value, 0)
                          ..scale(1.0 - (0.22 * value)),
                        alignment: Alignment.centerLeft,
                        child: cachedChild,
                      ),

                      // Full-screen overlay to intercept clicks & left drags while drawer is open
                      Positioned.fill(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(screenWidth * 0.68 * value, 0)
                            ..scale(1.0 - (0.22 * value)),
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _closeDrawer,
                            onHorizontalDragUpdate: (details) {
                              if ((details.primaryDelta ?? 0) < -6) {
                                _closeDrawer();
                              }
                            },
                            child: Container(color: AppColors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
