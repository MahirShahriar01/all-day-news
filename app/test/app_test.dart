import 'package:all_in_one_news/app.dart';
import 'package:all_in_one_news/data/local/local_store.dart';
import 'package:all_in_one_news/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // A typical phone: 393 x 852 logical pixels.
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))], child: const AllInOneNewsApp()),
  );
  // Let the bundled configuration load (real asset I/O happens outside the fake clock).
  for (var i = 0; i < 50 && find.byType(CustomScrollView).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(seconds: 1));
  expect(find.byType(CustomScrollView), findsWidgets, reason: 'home content should be visible');
}

void main() {
  // The asset cache would otherwise hand later tests a future bound to an
  // earlier test's fake-async zone.
  setUp(rootBundle.clear);

  testWidgets('home shows branding, featured section and categories', (tester) async {
    await _pumpApp(tester);
    expect(find.text('All in One News'), findsWidgets);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('News'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a category tab filters the grid', (tester) async {
    await _pumpApp(tester);
    // Scroll so the (pinned) category tabs sit at the top of the screen.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(AnimatedContainer, 'News'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Reuters'), findsWidgets);
    // Other categories' sections are no longer shown.
    expect(find.text('Khan Academy'), findsNothing);
    expect(find.text('See all'), findsNothing);
  });

  testWidgets('search finds websites by name', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Search').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), 'wiki');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Wikipedia'), findsOneWidget);
    expect(find.text('BBC News'), findsNothing);
  });

  testWidgets('favourites tab shows the empty state', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Favourites'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No favourites yet'), findsOneWidget);
  });
}
