import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// App-wide logger configuration. Call [configureLogging] once at
/// application startup, before any logging happens.
void configureLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}

Logger appLogger(String name) => Logger(name);
