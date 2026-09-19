import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/widgets/searchable_dropdown.dart';
import 'package:ledger_app/core/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets(
    'search keyboard leaves no sheet gap and next form field still resizes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AppKeyboardPadding(
                      child: SizedBox(
                        height: 240,
                        child: Column(
                          children: [
                            const TextField(key: Key('sheet-field')),
                            SearchableDropdown<String>(
                              items: const ['Medicine'],
                              label: (value) => value,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      double sheetInset() =>
          (tester
                      .widget<Padding>(
                        find
                            .descendant(
                              of: find.byType(AppKeyboardPadding),
                              matching: find.byType(Padding),
                            )
                            .first,
                      )
                      .padding
                  as EdgeInsets)
              .bottom;
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sheet-field')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      expect(sheetInset(), 250);
      await tester.tap(find.byType(SearchableDropdown<String>));
      await tester.pumpAndSettle();
      expect(sheetInset(), 0);
      final search = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      final searchTop = tester.getTopLeft(search).dy;
      await tester.enterText(search, 'Medicine');
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(search).dy, searchTop);
      expect(sheetInset(), 0);
      await tester.tap(find.widgetWithText(ListTile, 'Medicine'));
      await tester.pumpAndSettle();
      // Android can report the old keyboard height after the popup has gone.
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(sheetInset(), 0);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sheet-field')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(sheetInset(), 220);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard padding does not rebuild the form content', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppKeyboardPadding(
            child: Builder(
              builder: (_) {
                builds++;
                return const Text('Form content');
              },
            ),
          ),
        ),
      ),
    );
    final initialBuilds = builds;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(builds, initialBuilds);
  });

  testWidgets('supplier search closes without popping the underlying sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => SearchableDropdown<String>(
                    items: const ['Stockist one', 'Stockist two'],
                    label: (value) => value,
                    itemName: 'supplier / stockist',
                    itemPlural: 'suppliers / stockists',
                    itemIcon: Icons.local_shipping_outlined,
                    onChanged: (_) {},
                  ),
                ),
                child: const Text('Open purchase'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open purchase'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'two');
    await tester.pump();
    expect(find.text('Stockist two'), findsOneWidget);
    expect(find.text('Stockist one'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });
  Widget host({required Widget child}) => ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('selection callback waits for the popup exit animation', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        child: SearchableDropdown<String>(
          items: const ['Medicine'],
          label: (item) => item,
          onChanged: (item) => selected = item,
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.text('Medicine'));
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    expect(selected, isNull);
    await tester.pump(const Duration(milliseconds: 50));
    expect(selected, isNull);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(selected, 'Medicine');
  });

  testWidgets(
    'catalog work starts after entry and ignores late results during exit',
    (tester) async {
      final catalog = Completer<List<String>>();
      var loads = 0;
      await tester.pumpWidget(
        host(
          child: SearchableDropdown<String>(
            items: const ['Existing medicine'],
            label: (item) => item,
            loadItems: () {
              loads++;
              return catalog.future;
            },
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(InputDecorator));
      await tester.pump();
      expect(loads, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(loads, 1);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      catalog.complete(['New medicine']);
      await tester.pump();
      expect(find.text('New medicine'), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small screen with keyboard keeps search and validation usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      host(
        child: Form(
          key: form,
          child: SearchableDropdown<String>(
            items: const ['Medicine'],
            label: (value) => value,
            validator: (value) => value == null ? 'Required' : null,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.tap(find.text('Medicine'));
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('600 choices are lazy, searchable, clearable and selectable', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        child: SearchableDropdown<String>(
          items: List.generate(600, (i) => 'Medicine $i'),
          label: (value) => value,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile).evaluate().length, lessThan(50));
    await tester.enterText(find.byType(TextField), '  MEDICINE 599  ');
    await tester.pump();
    expect(find.text('Medicine 599'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no matching medicine');
    await tester.pump();
    expect(find.text('No medicines match your search'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Medicine 0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'medicine 599');
    await tester.pump();
    await tester.tap(find.text('Medicine 599'));
    await tester.pumpAndSettle();
    expect(selected, 'Medicine 599');
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Medicine 599'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'async catalog preserves current query and cancellation selection',
    (tester) async {
      final catalog = Completer<List<String>>();
      String? selected;
      await tester.pumpWidget(
        host(
          child: SearchableDropdown<String>(
            items: const [],
            value: 'Existing medicine',
            label: (value) => value,
            loadItems: () => catalog.future,
            onChanged: (value) => selected = value,
          ),
        ),
      );
      await tester.tap(find.byType(InputDecorator));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'second');
      catalog.complete(['First medicine', 'Second medicine']);
      await tester.pumpAndSettle();
      expect(find.text('Second medicine'), findsOneWidget);
      expect(find.text('First medicine'), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.text('Existing medicine'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
