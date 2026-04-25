import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/app.dart';

void main() {
  testWidgets('boots to login screen when signed out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PickllistApp()));
    await tester.pumpAndSettle();

    // Email + password fields visible = login screen rendered.
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('signing in navigates to picking lists', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PickllistApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'manager@farm.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Seeded "Thursday morning pick" should now be visible.
    expect(find.text('Thursday morning pick'), findsOneWidget);
  });
}
