import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/ui/screens/analytics/analytics_screen.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/ui/screens/challenges/challenge_details_screen.dart';
import 'package:done_today/ui/screens/challenges/challenge_log_editor_screen.dart';
import 'package:done_today/ui/screens/challenges/challenge_log_view_screen.dart';
import 'package:done_today/ui/screens/challenges/challenges_screen.dart';
import 'package:done_today/ui/screens/debug/debug_screen.dart';
import 'package:done_today/ui/screens/auth/login_screen.dart';
import 'package:done_today/ui/screens/dashboard/dashboard_screen.dart';
import 'package:done_today/ui/screens/logs/log_editor_screen.dart';
import 'package:done_today/ui/screens/logs/log_view_screen.dart';
import 'package:done_today/ui/screens/logs/my_logs_screen.dart';
import 'package:done_today/ui/screens/logs/book_reader_screen.dart';
import 'package:done_today/ui/screens/onboarding/get_started_screen.dart';
import 'package:done_today/ui/screens/settings/profile_screen.dart';
import 'package:done_today/ui/screens/settings/settings_screen.dart';
import 'package:done_today/ui/screens/splash/splash_screen.dart';
import 'package:done_today/ui/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// A notifier that bridges AuthState changes to GoRouter's refreshListenable.
class RouterNotifier extends ChangeNotifier {
  static String? pendingIntent;
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final isLoggedIn = authState is AuthLoggedIn;

    final isAuthPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/onboarding' ||
        state.matchedLocation == '/splash';

    final isPublicPage = isAuthPage ||
        state.matchedLocation == '/debug';

    if (!isLoggedIn) {
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (!isPublicPage) {
        return '/onboarding';
      }

      if (state.matchedLocation == '/splash') {
        return '/onboarding';
      }
      return null;
    }

    if (isAuthPage) {
      if (pendingIntent != null) {
        final redirect = pendingIntent;
        pendingIntent = null;
        return redirect;
      }
      return '/';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  // Use read here to get the notifier once.
  // The GoRouter will handle updates via the refreshListenable.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(body: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/logs',
            name: 'logs',
            builder: (context, state) => const MyLogScreen(),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/challenges',
            name: 'challenges',
            builder: (context, state) => const ChallengesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ChallengeDetailsScreen(challengeId: id);
                },
                routes: [
                  GoRoute(
                    path: 'logs/new',
                    builder: (context, state) {
                      final challenge = state.extra as Challenge;
                      return ChallengeLogEditorScreen(challenge: challenge);
                    },
                  ),
                  GoRoute(
                    path: 'logs/:logId',
                    builder: (context, state) {
                      final logId = state.pathParameters['logId']!;
                      final extra = state.extra as Map<String, dynamic>?;

                      if (extra != null) {
                        return ChallengeLogViewScreen(
                          challenge: extra['challenge'] as Challenge,
                          log: extra['log'] as Log,
                        );
                      }

                      // Fetch from Hive
                      final rawLog = HiveService.getLog(logId);
                      if (rawLog != null) {
                        final log = Log.fromJson(rawLog);
                        final rawChallenge = HiveService.getChallenge(
                          log.challengeId!,
                        );
                        if (rawChallenge != null) {
                          return ChallengeLogViewScreen(
                            challenge: Challenge.fromJson(rawChallenge),
                            log: log,
                          );
                        }
                      }

                      return const ChallengesScreen();
                    },
                  ),
                  GoRoute(
                    path: 'logs/edit/:logId',
                    builder: (context, state) {
                      final logId = state.pathParameters['logId']!;
                      final extra = state.extra as Map<String, dynamic>?;

                      if (extra != null) {
                        return ChallengeLogEditorScreen(
                          challenge: extra['challenge'] as Challenge,
                          existingLog: extra['log'] as Log,
                        );
                      }

                      // Fetch from Hive
                      final rawLog = HiveService.getLog(logId);
                      if (rawLog != null) {
                        final log = Log.fromJson(rawLog);
                        final rawChallenge = HiveService.getChallenge(
                          log.challengeId!,
                        );
                        if (rawChallenge != null) {
                          return ChallengeLogEditorScreen(
                            challenge: Challenge.fromJson(rawChallenge),
                            existingLog: log,
                          );
                        }
                      }

                      return const ChallengesScreen();
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const UserDetailsScreen(),
          ),
          GoRoute(
            path: '/logs/book',
            builder: (context, state) => const BookReaderScreen(),
          ),
          GoRoute(
            path: '/logs/new',
            builder: (context, state) => const LogScreen(),
          ),
          GoRoute(
            path: '/logs/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final extraLog = state.extra as Log?;

              if (extraLog != null) return LogViewScreen(log: extraLog);

              // Try to fetch from Hive if extra is null
              final rawLog = HiveService.getLog(id);
              if (rawLog != null) {
                return LogViewScreen(log: Log.fromJson(rawLog));
              }

              return const MyLogScreen();
            },
          ),
          GoRoute(
            path: '/logs/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final extraLog = state.extra as Log?;

              if (extraLog != null) return LogScreen(log: extraLog);

              // Try to fetch from Hive if extra is null
              final rawLog = HiveService.getLog(id);
              if (rawLog != null) {
                return LogScreen(log: Log.fromJson(rawLog));
              }

              return const LogScreen();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Profile moved to ShellRoute to preserve bottom navigation bar
      GoRoute(
        path: '/activity_fallback',
        name: 'activity_fallback',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
  );
});
