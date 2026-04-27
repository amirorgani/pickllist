import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:pickllist/core/logging/logger.dart';

void main() {
  group('appLogger', () {
    test('returns a Logger with the given name', () {
      final log = appLogger('myFeature');

      expect(log, isA<Logger>());
      expect(log.name, equals('myFeature'));
    });

    test('different names return differently named loggers', () {
      final a = appLogger('featureA');
      final b = appLogger('featureB');

      expect(a.name, equals('featureA'));
      expect(b.name, equals('featureB'));
    });
  });

  group('configureLogging', () {
    test('sets root logger level to INFO by default', () {
      configureLogging();

      expect(Logger.root.level, equals(Level.INFO));
    });

    test('sets root logger level to the supplied level', () {
      configureLogging(level: Level.WARNING);

      expect(Logger.root.level, equals(Level.WARNING));

      // Restore default.
      configureLogging();
    });

    test('records can be emitted after configureLogging', () {
      configureLogging();

      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);

      appLogger('test').info('hello coverage');

      sub.cancel();

      expect(records, hasLength(1));
      expect(records.first.message, equals('hello coverage'));
      expect(records.first.loggerName, equals('test'));
    });
  });
}
