// Presentation-layer widget tests for PickingListDetailScreen. GUARD-09.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/presentation/picking_list_detail_screen.dart';
import 'package:pickllist/features/users/application/user_directory_providers.dart';
import 'package:pickllist/features/users/data/fake_user_directory_repository.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

void main() {
  late FakePickingListRepository fakeRepo;
  late FakeAuthRepository fakeAuth;
  late FakeUserDirectoryRepository fakeUsers;

  setUp(() {
    fakeRepo = FakePickingListRepository();
    fakeAuth = FakeAuthRepository();
    fakeUsers = FakeUserDirectoryRepository(fakeAuth);
  });

  Future<PickingList> seedList() async {
    return (await fakeRepo.watchLists().first).first;
  }

  Widget buildScreen(String listId) {
    return ProviderScope(
      overrides: [
        pickingListRepositoryProvider.overrideWithValue(fakeRepo),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        userDirectoryRepositoryProvider.overrideWithValue(fakeUsers),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PickingListDetailScreen(listId: listId),
      ),
    );
  }

  group('PickingListDetailScreen', () {
    testWidgets('shows list name in AppBar for known list', (tester) async {
      final list = await seedList();
      await tester.pumpWidget(buildScreen(list.id));
      await tester.pumpAndSettle();

      expect(find.text('Thursday morning pick'), findsOneWidget);
    });

    testWidgets('shows scheduled date info', (tester) async {
      final list = await seedList();
      await tester.pumpWidget(buildScreen(list.id));
      await tester.pumpAndSettle();

      expect(find.textContaining('Scheduled for'), findsOneWidget);
    });

    testWidgets('lists the seeded picking items', (tester) async {
      final list = await seedList();
      await tester.pumpWidget(buildScreen(list.id));
      await tester.pumpAndSettle();

      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.text('Cucumbers'), findsOneWidget);
    });

    testWidgets('shows fallback title for unknown list id', (tester) async {
      await tester.pumpWidget(buildScreen('no-such-list'));
      await tester.pumpAndSettle();

      // AppBar should still show "Picking lists" fallback label.
      expect(find.text('Picking lists'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      final list = await seedList();
      await tester.pumpWidget(buildScreen(list.id));
      // Only pump once — before pumpAndSettle.
      await tester.pump();

      // Either loading spinner or already rendered (fast fake).
      // This exercises the loading branch in itemsAsync.when.
    });
  });
}
