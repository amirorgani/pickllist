import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GUARD-02 public_member_api_docs scoping', () {
    test('analysis_options.yaml enables public_member_api_docs', () {
      final yaml = File('analysis_options.yaml').readAsStringSync();
      expect(
        RegExp(r'^\s*public_member_api_docs:\s*true', multiLine: true)
            .hasMatch(yaml),
        isTrue,
        reason:
            'public_member_api_docs must be enabled globally; presentation '
            'and application layers opt out per-file with explanation.',
      );
    });

    test(
      'presentation/application files that opt out have explanatory comment',
      () {
        const optOutFiles = [
          'lib/app.dart',
          'lib/features/auth/presentation/login_screen.dart',
          'lib/features/picking_lists/application/picking_list_providers.dart',
          'lib/features/picking_lists/presentation/picking_list_detail_screen.dart',
          'lib/features/picking_lists/presentation/picking_lists_screen.dart',
          'lib/features/picking_lists/presentation/widgets/picking_item_tile.dart',
          'lib/features/picking_lists/presentation/widgets/quantity_unit_l10n.dart',
          'lib/features/users/application/user_directory_providers.dart',
        ];
        for (final path in optOutFiles) {
          final src = File(path).readAsStringSync();
          expect(
            src.contains('ignore_for_file: public_member_api_docs'),
            isTrue,
            reason: '$path is expected to opt out of public_member_api_docs',
          );
          expect(
            src.contains('GUARD-02'),
            isTrue,
            reason:
                '$path must include a GUARD-02 explanation before the '
                'ignore directive (document_ignores requires it).',
          );
        }
      },
    );
  });
}
