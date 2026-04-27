// Presentation-layer widget tests. Coverage target for GUARD-09.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/presentation/picking_lists_screen.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

/// Wraps [child] in the minimum Material/Riverpod/L10n scaffolding
/// needed to render any screen under test.
Widget buildHarness(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late FakePickingListRepository fakeRepo;
  late FakeAuthRepository fakeAuth;

  setUp(() {
    fakeRepo = FakePickingListRepository();
    fakeAuth = FakeAuthRepository();
  });

  List<Override> overrides() => [
    pickingListRepositoryProvider.overrideWithValue(fakeRepo),
    authRepositoryProvider.overrideWithValue(fakeAuth),
  ];

  group('PickingListsScreen', () {
    testWidgets('shows the seeded picking list', (tester) async {
      await tester.pumpWidget(
        buildHarness(const PickingListsScreen(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thursday morning pick'), findsOneWidget);
    });

    testWidgets('shows status label for published list', (tester) async {
      await tester.pumpWidget(
        buildHarness(const PickingListsScreen(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      // The subtitle includes the status label embedded in a longer string.
      expect(find.textContaining('Published'), findsOneWidget);
    });

    testWidgets('shows sign-out button when a user is signed in', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(const PickingListsScreen(), overrides: overrides()),
      );
      await tester.pumpAndSettle();
      // Sign in after the widget tree is alive so the auth stream propagates.
      await fakeAuth.signIn(
        email: 'manager@farm.test',
        password: 'password123',
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('hides sign-out button when signed out', (tester) async {
      // fakeAuth starts signed out — no signIn call.
      await tester.pumpWidget(
        buildHarness(const PickingListsScreen(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('shows no-lists message when repo is empty', (tester) async {
      // Use a fake that starts empty (no seeded lists).
      final emptyOverrides = [
        pickingListRepositoryProvider.overrideWith(
          (_) => _EmptyFakePickingListRepo(),
        ),
        authRepositoryProvider.overrideWithValue(fakeAuth),
      ];
      await tester.pumpWidget(
        buildHarness(const PickingListsScreen(), overrides: emptyOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('No picking lists yet.'), findsOneWidget);
    });
  });
}

/// A fake that seeds zero lists.
class _EmptyFakePickingListRepo extends FakePickingListRepository {
  @override
  Stream<List<PickingList>> watchLists() async* {
    yield const [];
  }
}
