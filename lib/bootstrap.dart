import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/app.dart';
import 'package:pickllist/core/logging/logger.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/firebase_auth_repository.dart';
import 'package:pickllist/firebase_options.dart';

/// Async startup: logging, conditional Firebase.initializeApp, then runApp.
///
/// When `firebase_options.dart` contains real values (i.e. `flutterfire
/// configure` has run), Firebase is initialized and the auth repository
/// is overridden with [FirebaseAuthRepository]. Otherwise the in-memory
/// fake from [authRepositoryProvider] is used so the POC still runs.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  appLogger('bootstrap').info('Starting Pickllist POC');

  final allOverrides = <Override>[...overrides];
  if (hasRealFirebaseConfig(DefaultFirebaseOptions.currentPlatform)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    allOverrides.add(
      authRepositoryProvider.overrideWith(
        (ref) => FirebaseAuthRepository(
          auth: fb.FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      ),
    );
  } else {
    appLogger('bootstrap').info(
      'Firebase options are placeholders; using fake auth.',
    );
  }

  runApp(
    ProviderScope(overrides: allOverrides, child: const PickllistApp()),
  );
}

/// Returns true when [options] looks like a real flutterfire-generated
/// config rather than the placeholder values left behind when the CLI
/// hasn't been run for this platform.
bool hasRealFirebaseConfig(FirebaseOptions options) {
  bool isPlaceholder(String? v) {
    if (v == null || v.isEmpty) return true;
    final upper = v.toUpperCase();
    return upper.contains('YOUR-') ||
        upper.contains('PLACEHOLDER') ||
        upper.contains('XXXX');
  }

  return !isPlaceholder(options.apiKey) &&
      !isPlaceholder(options.appId) &&
      !isPlaceholder(options.projectId);
}
