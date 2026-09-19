import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

import 'core/storage/storage_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/inventory/controllers/master_data_controller.dart';
import 'features/inventory/controllers/batch_controller.dart';
import 'features/purchases/controllers/purchases_controller.dart';
import 'core/network/connectivity_controller.dart';
import 'core/widgets/offline_status_card.dart';
import 'features/sales/controllers/sales_controller.dart';
import 'features/crm/controllers/crm_controller.dart';
import 'features/accounting/controllers/accounting_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await StorageService.init();
  Get.put(ConnectivityController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(MasterDataController(), permanent: true);
  Get.put(BatchController(), permanent: true);
  Get.put(PurchasesController(), permanent: true);
  Get.put(SalesController(), permanent: true);
  Get.put(CrmController(), permanent: true);
  Get.put(AccountingController(), permanent: true);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgSurface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const XMedicozApp());
}

class XMedicozApp extends StatelessWidget {
  const XMedicozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
          defaultTransition: Transition.cupertino,
          builder: (context, widget) {
            return Stack(
              children: [
                widget ?? const SizedBox.shrink(),
                const OfflineStatusCard(),
              ],
            );
          },
        );
      },
    );
  }
}
