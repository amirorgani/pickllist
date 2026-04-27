// Presentation-layer widget tests for LoginScreen. GUARD-09.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/auth/presentation/login_screen.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

/// A fake auth repo that throws a generic [Exception] (not [AuthException])
/// on sign-in, to exercise the `on Exception` catch branch.
class _GenericExceptionAuthRepo extends FakeAuthRepository {
  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    throw Exception('network-error');
  }
}

Widget buildLoginScreen({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields with defaults', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      // Default email is pre-filled.
      expect(find.text('manager@farm.test'), findsOneWidget);
    });

    testWidgets('sign-in button is visible', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('empty email field shows validation error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Clear the email field.
      await tester.enterText(
        find.byType(TextFormField).first,
        '',
      );
      // Tap sign-in to trigger validation.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // The validator returns the field label as error text.
      expect(find.text('Email'), findsWidgets);
    });

    testWidgets('bad credentials show login failed error', (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(
        buildLoginScreen(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong password.
      await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not sign in. Check your email and password.'),
        findsOneWidget,
      );
    });

    testWidgets('successful sign-in calls signIn on the repo', (tester) async {
      AppUser? signedIn;
      final repo = FakeAuthRepository();
      await tester.pumpWidget(
        buildLoginScreen(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      // Default credentials are pre-filled; tap sign-in.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      signedIn = repo.currentUser;
      expect(signedIn?.email, equals('manager@farm.test'));
    });

    testWidgets('empty password field shows validation error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Clear the password field.
      await tester.enterText(find.byType(TextFormField).last, '');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('generic Exception shows login failed error', (tester) async {
      final repo = _GenericExceptionAuthRepo();
      await tester.pumpWidget(
        buildLoginScreen(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      // Default credentials are pre-filled; tap sign-in.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not sign in. Check your email and password.'),
        findsOneWidget,
      );
    });
  });
}
