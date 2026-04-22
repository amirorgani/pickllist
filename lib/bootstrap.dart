import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pickllist/app.dart';
import 'package:pickllist/core/logging/logger.dart';

/// Async startup: logging, (future) Firebase.initializeApp, then runApp.
///
/// Once `flutterfire configure` runs, import the generated
/// `firebase_options.dart` and call `Firebase.initializeApp(options:
/// DefaultFirebaseOptions.currentPlatform)` here, then override the
/// fake repository providers in [overrides] below.
Future<void> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging(level: Level.INFO);
  appLogger('bootstrap').info('Starting Pickllist POC');

  runApp(ProviderScope(overrides: overrides, child: const PickllistApp()));
}
