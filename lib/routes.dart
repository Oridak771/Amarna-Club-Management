import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/activities_grid_screen.dart';
import 'screens/activities/gym_equipment_screen.dart';
import 'screens/activities/horse_grid_screen.dart';
import 'screens/activities/horse_profile_screen.dart';
import 'screens/activities/padel_courts_screen.dart';
import 'screens/activities/paintball_field_screen.dart';
import 'screens/activities/pool_gauges_screen.dart';
import 'screens/activities/weapon_list_screen.dart';
import 'screens/asset_profile_screen.dart';
import 'screens/create_reservation_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/global_inventory_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/notification_center_screen.dart';
import 'screens/plus_menu_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/tickets_list_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _accueilNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'accueil');
final GlobalKey<NavigatorState> _planningNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'planning');
final GlobalKey<NavigatorState> _activitesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'activites');
final GlobalKey<NavigatorState> _ticketsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'tickets');
final GlobalKey<NavigatorState> _plusNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'plus');

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _RouterAuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authStatus = ref.read(authProvider).status;
      final isSplash = state.matchedLocation == '/';
      final isLogin = state.matchedLocation == '/login';

      if (authStatus == AuthStatus.initial ||
          authStatus == AuthStatus.authenticating) {
        if (isSplash || isLogin) return null;
        return '/';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isLogin) return '/accueil';
        return null;
      }

      if (isSplash || isLogin) return null;
      return '/login';
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/scan',
        builder: (BuildContext context, GoRouterState state) =>
            const QRScanScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/asset/:id',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id'] ?? '';
          return AssetProfileScreen(id: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationCenterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _accueilNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/accueil',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _planningNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/planning',
                builder: (BuildContext context, GoRouterState state) =>
                    const ReservationsScreen(),
                routes: [
                  GoRoute(
                    path: 'nouvelle',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CreateReservationScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _activitesNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/activites',
                builder: (BuildContext context, GoRouterState state) =>
                    const ActivitiesGridScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (BuildContext context, GoRouterState state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ActivityDetailScreen(id: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'pool-gauges',
                        builder: (context, state) =>
                            PoolGaugesScreen(activityId: state.pathParameters['id'] ?? ''),
                      ),
                      GoRoute(
                        path: 'horses',
                        builder: (context, state) =>
                            HorseGridScreen(activityId: state.pathParameters['id'] ?? ''),
                        routes: [
                          GoRoute(
                            path: ':horseId',
                            builder: (context, state) {
                              final horseId =
                                  state.pathParameters['horseId'] ?? '';
                              return HorseProfileScreen(id: horseId);
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'weapon-list',
                        builder: (context, state) =>
                            WeaponListScreen(activityId: state.pathParameters['id'] ?? ''),
                      ),
                      GoRoute(
                        path: 'paintball-field',
                        builder: (context, state) =>
                            PaintballFieldScreen(activityId: state.pathParameters['id'] ?? ''),
                      ),
                      GoRoute(
                        path: 'gym-equipment',
                        builder: (context, state) =>
                            GymEquipmentScreen(activityId: state.pathParameters['id'] ?? ''),
                      ),
                      GoRoute(
                        path: 'padel-courts',
                        builder: (context, state) =>
                            PadelCourtsScreen(activityId: state.pathParameters['id'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _ticketsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/tickets',
                builder: (BuildContext context, GoRouterState state) =>
                    const TicketsListScreen(),
                routes: [
                  GoRoute(
                    path: 'nouveau',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CreateTicketScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (BuildContext context, GoRouterState state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TicketDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _plusNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/plus',
                builder: (BuildContext context, GoRouterState state) =>
                    const PlusMenuScreen(),
                routes: [
                  GoRoute(
                    path: 'inventaire',
                    builder: (BuildContext context, GoRouterState state) =>
                        const GlobalInventoryScreen(),
                  ),
                  GoRoute(
                    path: 'abonnements',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SubscriptionsScreen(),
                  ),
                  GoRoute(
                    path: 'rapports',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReportsScreen(),
                  ),
                  GoRoute(
                    path: 'aide',
                    builder: (BuildContext context, GoRouterState state) =>
                        const HelpScreen(),
                  ),
                  GoRoute(
                    path: 'profil',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterAuthNotifier extends ChangeNotifier {
  _RouterAuthNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
