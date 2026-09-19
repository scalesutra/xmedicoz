import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const XMedicozApp());
    await tester.pump();
    expect(find.byType(XMedicozApp), findsOneWidget);
  });
}
