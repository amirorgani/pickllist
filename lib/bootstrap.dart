import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/app.dart';
import 'package:pickllist/core/logging/logger.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/firebase_auth_repository.dart';
import 'package:pickllist/firebase_options.dart';

/// Initializes app services and starts the widget tree.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  appLogger('bootstrap').info('Starting Pickllist POC');

  final appOverrides = [...overrides];
  final firebaseOptions = configuredFirebaseOptionsForPlatform();

  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
    appOverrides.add(
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      ),
    );
  }

  runApp(ProviderScope(overrides: appOverrides, child: const PickllistApp()));
}

@visibleForTesting
/// Resolves the Firebase options for supported configured platforms, if any.
FirebaseOptions? configuredFirebaseOptionsForPlatform() {
  if (kIsWeb) {
    return null;
  }

  final options = switch (defaultTargetPlatform) {
    TargetPlatform.android => DefaultFirebaseOptions.android,
    TargetPlatform.iOS => DefaultFirebaseOptions.ios,
    TargetPlatform.windows => DefaultFirebaseOptions.windows,
    _ => null,
  };

  if (options == null) {
    return null;
  }

  return hasConfiguredFirebaseOptions(options) ? options : null;
}

@visibleForTesting
/// Returns whether [options] look like real generated Firebase config.
bool hasConfiguredFirebaseOptions(FirebaseOptions options) {
  return options.apiKey.isNotEmpty &&
      options.appId.isNotEmpty &&
      options.projectId.isNotEmpty &&
      !options.apiKey.startsWith('YOUR_') &&
      !options.appId.startsWith('YOUR_') &&
      !options.projectId.startsWith('YOUR_');
}
