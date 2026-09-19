import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ledger_app/core/widgets/unique_otp_v7_sheet.dart';

void main() {
  testWidgets('UniqueOtpV7Sheet renders exact reel UI and triggers animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return const GetMaterialApp(
            home: Scaffold(
              body: UniqueOtpV7Sheet(
                phone: '9876543210',
              ),
            ),
          );
        },
      ),
    );

    await tester.pump();
    expect(find.text("Let's verify your number"), findsOneWidget);
    expect(find.text('Otp Verification'), findsOneWidget);
    expect(find.text('V7'), findsOneWidget);
    expect(find.text('Play Demo Animation (4455)'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));

    // Tap Play Demo Animation (4455)
    await tester.tap(find.text('Play Demo Animation (4455)'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 2500));

    // Verify verified successfully state
    expect(find.text('Verified Successfully'), findsOneWidget);
    expect(find.text('Your number has been verified.'), findsOneWidget);
    expect(find.text('Verified and Secure'), findsOneWidget);
  });
}
