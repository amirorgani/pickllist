import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected app locale. `null` means "follow system". Persisted only
/// in-memory for the POC; persistence (shared_preferences) is planned.
final localeProvider = StateProvider<Locale?>((ref) => null);

/// Locales the app ships translations for.
const supportedLocales = <Locale>[Locale('en'), Locale('he'), Locale('th')];
