// Presentation/application layer — public_member_api_docs is enforced
// on lib/core/, lib/features/*/domain/, and lib/features/*/data/ only,
// per GUARD-02. Widget classes don't need docstrings on every member.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/core/providers/locale_provider.dart';
import 'package:pickllist/core/routing/app_router.dart';
import 'package:pickllist/core/theme/app_theme.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

class PickllistApp extends ConsumerWidget {
  const PickllistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Pickllist',
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      debugShowCheckedModeBanner: false,
    );
  }
}
