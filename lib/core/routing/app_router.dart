import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/presentation/login_screen.dart';
import 'package:pickllist/features/picking_lists/presentation/picking_list_detail_screen.dart';
import 'package:pickllist/features/picking_lists/presentation/picking_lists_screen.dart';

/// Rebuilds the router configuration when auth state changes so the
/// redirect logic re-runs. We bump a notifier on every auth event,
/// including `fireImmediately` so the initial state counts.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref
    ..listen(
      authStateProvider,
      (_, _) => refreshListenable.value++,
      fireImmediately: true,
    )
    ..onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (ctx, state) {
      // Read the source provider — currentUserProvider is not continuously
      // watched here, so ref.read on it can return a stale cached value.
      final user = ref.read(authStateProvider).valueOrNull;
      final signedIn = user != null;
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn && !atLogin) return '/login';
      if (signedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const PickingListsScreen()),
      GoRoute(
        path: '/lists/:listId',
        builder: (_, st) =>
            PickingListDetailScreen(listId: st.pathParameters['listId']!),
      ),
    ],
  );
});
