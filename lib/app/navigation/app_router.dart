import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/ui/archive_screen.dart';
import '../../features/editor/ui/editor_screen.dart';
import '../../features/library/ui/library_screen.dart';
import '../../features/onboarding/ui/role_screen.dart';
import '../../features/onboarding/ui/welcome_screen.dart';
import '../../features/paywall/ui/paywall_screen.dart';
import '../../features/wizard/ui/wizard_screen.dart';
import '../state/providers.dart';
import 'shell_route_wrapper.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AsyncValue<UserState>>(const AsyncValue.loading());

  ref.listen<AsyncValue<UserState>>(
    userProvider,
    (_, next) => notifier.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final userState = ref.read(userProvider);

      // Handle loading/error states
      if (userState.isLoading && !userState.hasValue) {
        return '/splash';
      }

      if (userState.hasError && !userState.hasValue) {
        return null; // Stay on splash or show error widget if implemented
      }

      final user = userState.valueOrNull;
      if (user == null) return '/splash'; // Should be covered by loading check, but safety

      // Route logic
      final isSplash = state.uri.path == '/splash';
      final isOnboarding = state.uri.path == '/welcome' || state.uri.path == '/role';

      if (!user.onboardingDone) {
        return isOnboarding ? null : '/welcome';
      }

      if (isSplash || isOnboarding) {
        return '/library';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleScreen(),
      ),
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PaywallScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'editor/:id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EditorScreen(presentationId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create_placeholder',
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/archive',
                builder: (context, state) => const ArchiveScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/wizard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WizardScreen(),
      ),
    ],
  );
});
