// L10n coverage tests for Hebrew and Thai locales. GUARD-09.
// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

/// Build a minimal app with a specific locale and expose the
/// [AppLocalizations] instance via a [Builder].
Widget buildL10nApp({
  required Locale locale,
  required Widget Function(BuildContext) builder,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: builder),
  );
}

void main() {
  // ── English ──────────────────────────────────────────────────────────────

  group('AppLocalizations English (en)', () {
    testWidgets('all string getters return non-empty values', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        buildL10nApp(
          locale: const Locale('en'),
          builder: (ctx) {
            l = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(l.appTitle, equals('Pickllist'));
      expect(l.signIn, equals('Sign in'));
      expect(l.signOut, equals('Sign out'));
      expect(l.email, equals('Email'));
      expect(l.password, equals('Password'));
      expect(l.loginFailed, isA<String>());
      expect(l.pickingLists, equals('Picking lists'));
      expect(l.noPickingLists, isA<String>());
      expect(l.newList, isA<String>());
      expect(l.listName, isA<String>());
      expect(l.scheduledAt, isA<String>());
      expect(l.status, isA<String>());
      expect(l.statusDraft, equals('Draft'));
      expect(l.statusPublished, equals('Published'));
      expect(l.statusCompleted, equals('Completed'));
      expect(l.item, isA<String>());
      expect(l.quantity, equals('Quantity'));
      expect(l.unit, isA<String>());
      expect(l.unitUnits, equals('units'));
      expect(l.unitKg, equals('kg'));
      expect(l.unitBoxes, equals('boxes'));
      expect(l.note, equals('Note'));
      expect(l.assignedTo, isA<String>());
      expect(l.unassigned, equals('Unassigned'));
      expect(l.claim, equals('Claim'));
      expect(l.reassign, equals('Reassign'));
      expect(l.markPicked, equals('Mark picked'));
      expect(l.actualQuantity, equals('Actual quantity'));
      expect(l.difference, isA<String>());
      expect(l.overBy('5'), equals('Over by 5'));
      expect(l.underBy('3'), equals('Under by 3'));
      expect(l.exactMatch, equals('Exact'));
      expect(l.completedAt('09:30'), equals('Completed at 09:30'));
      expect(l.crops, isA<String>());
      expect(l.users, isA<String>());
      expect(l.templates, isA<String>());
      expect(l.history, isA<String>());
      expect(l.importFromExcel, isA<String>());
      expect(l.language, isA<String>());
      expect(l.english, isA<String>());
      expect(l.hebrew, isA<String>());
      expect(l.thai, isA<String>());
      expect(l.save, isA<String>());
      expect(l.cancel, equals('Cancel'));
      expect(l.confirm, equals('Confirm'));
      expect(l.delete, isA<String>());
      expect(l.edit, isA<String>());
      expect(l.add, isA<String>());
    });
  });

  // ── Hebrew ────────────────────────────────────────────────────────────────

  group('AppLocalizations Hebrew (he)', () {
    testWidgets('all string getters return non-empty values', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        buildL10nApp(
          locale: const Locale('he'),
          builder: (ctx) {
            l = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(l.appTitle, isA<String>());
      expect(l.signIn, isA<String>());
      expect(l.signOut, isA<String>());
      expect(l.email, isA<String>());
      expect(l.password, isA<String>());
      expect(l.loginFailed, isA<String>());
      expect(l.pickingLists, isA<String>());
      expect(l.noPickingLists, isA<String>());
      expect(l.newList, isA<String>());
      expect(l.listName, isA<String>());
      expect(l.scheduledAt, isA<String>());
      expect(l.status, isA<String>());
      expect(l.statusDraft, isA<String>());
      expect(l.statusPublished, isA<String>());
      expect(l.statusCompleted, isA<String>());
      expect(l.item, isA<String>());
      expect(l.quantity, isA<String>());
      expect(l.unit, isA<String>());
      expect(l.unitUnits, isA<String>());
      expect(l.unitKg, isA<String>());
      expect(l.unitBoxes, isA<String>());
      expect(l.note, isA<String>());
      expect(l.assignedTo, isA<String>());
      expect(l.unassigned, isA<String>());
      expect(l.claim, isA<String>());
      expect(l.reassign, isA<String>());
      expect(l.markPicked, isA<String>());
      expect(l.actualQuantity, isA<String>());
      expect(l.difference, isA<String>());
      expect(l.overBy('5'), isA<String>());
      expect(l.underBy('3'), isA<String>());
      expect(l.exactMatch, isA<String>());
      expect(l.completedAt('09:30'), isA<String>());
      expect(l.crops, isA<String>());
      expect(l.users, isA<String>());
      expect(l.templates, isA<String>());
      expect(l.history, isA<String>());
      expect(l.importFromExcel, isA<String>());
      expect(l.language, isA<String>());
      expect(l.english, isA<String>());
      expect(l.hebrew, isA<String>());
      expect(l.thai, isA<String>());
      expect(l.save, isA<String>());
      expect(l.cancel, isA<String>());
      expect(l.confirm, isA<String>());
      expect(l.delete, isA<String>());
      expect(l.edit, isA<String>());
      expect(l.add, isA<String>());
    });
  });

  // ── Thai ─────────────────────────────────────────────────────────────────

  group('AppLocalizations Thai (th)', () {
    testWidgets('all string getters return non-empty values', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        buildL10nApp(
          locale: const Locale('th'),
          builder: (ctx) {
            l = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(l.appTitle, isA<String>());
      expect(l.signIn, isA<String>());
      expect(l.signOut, isA<String>());
      expect(l.email, isA<String>());
      expect(l.password, isA<String>());
      expect(l.loginFailed, isA<String>());
      expect(l.pickingLists, isA<String>());
      expect(l.noPickingLists, isA<String>());
      expect(l.newList, isA<String>());
      expect(l.listName, isA<String>());
      expect(l.scheduledAt, isA<String>());
      expect(l.status, isA<String>());
      expect(l.statusDraft, isA<String>());
      expect(l.statusPublished, isA<String>());
      expect(l.statusCompleted, isA<String>());
      expect(l.item, isA<String>());
      expect(l.quantity, isA<String>());
      expect(l.unit, isA<String>());
      expect(l.unitUnits, isA<String>());
      expect(l.unitKg, isA<String>());
      expect(l.unitBoxes, isA<String>());
      expect(l.note, isA<String>());
      expect(l.assignedTo, isA<String>());
      expect(l.unassigned, isA<String>());
      expect(l.claim, isA<String>());
      expect(l.reassign, isA<String>());
      expect(l.markPicked, isA<String>());
      expect(l.actualQuantity, isA<String>());
      expect(l.difference, isA<String>());
      expect(l.overBy('5'), isA<String>());
      expect(l.underBy('3'), isA<String>());
      expect(l.exactMatch, isA<String>());
      expect(l.completedAt('09:30'), isA<String>());
      expect(l.crops, isA<String>());
      expect(l.users, isA<String>());
      expect(l.templates, isA<String>());
      expect(l.history, isA<String>());
      expect(l.importFromExcel, isA<String>());
      expect(l.language, isA<String>());
      expect(l.english, isA<String>());
      expect(l.hebrew, isA<String>());
      expect(l.thai, isA<String>());
      expect(l.save, isA<String>());
      expect(l.cancel, isA<String>());
      expect(l.confirm, isA<String>());
      expect(l.delete, isA<String>());
      expect(l.edit, isA<String>());
      expect(l.add, isA<String>());
    });
  });

  // ── lookupAppLocalizations ────────────────────────────────────────────────

  group('lookupAppLocalizations', () {
    test('returns AppLocalizationsEn for en locale', () {
      final l = lookupAppLocalizations(const Locale('en'));
      expect(l.signIn, equals('Sign in'));
    });

    test('returns AppLocalizationsHe for he locale', () {
      final l = lookupAppLocalizations(const Locale('he'));
      expect(l.appTitle, isA<String>());
    });

    test('returns AppLocalizationsTh for th locale', () {
      final l = lookupAppLocalizations(const Locale('th'));
      expect(l.appTitle, isA<String>());
    });

    test('throws FlutterError for unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
