import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/activities_grid_screen.dart';
import 'screens/tickets_list_screen.dart';
import 'screens/plus_menu_screen.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/offline_dashboard_screen.dart';

// Concrete screens
import 'screens/checklist_swipe_screen.dart';
import 'screens/checklist_summary_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/asset_profile_screen.dart';
import 'screens/global_inventory_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/create_reservation_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/help_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_center_screen.dart';

// Activity specific screens
import 'screens/activities/pool_gauges_screen.dart';
import 'screens/activities/horse_grid_screen.dart';
import 'screens/activities/horse_profile_screen.dart';
import 'screens/activities/weapon_list_screen.dart';
import 'screens/activities/paintball_field_screen.dart';
import 'screens/activities/gym_equipment_screen.dart';
import 'screens/activities/padel_courts_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _accueilNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'accueil');
final GlobalKey<NavigatorState> _activitesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'activites');
final GlobalKey<NavigatorState> _ticketsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'tickets');
final GlobalKey<NavigatorState> _plusNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'plus');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Start with Splash Screen
  routes: <RouteBase>[
    // Splash, Auth & Onboarding Flows
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) =>
          OnboardingScreen(),
    ),

    // QR & NFC Scan (Global overlay modal)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scan',
      builder: (BuildContext context, GoRouterState state) =>
          QRScanScreen(),
    ),

    // Asset profile (accessible via QR Scan or links)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/asset/:id',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return AssetProfileScreen(id: id);
      },
    ),

    // Notification center (Global route)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications',
      builder: (BuildContext context, GoRouterState state) =>
          NotificationCenterScreen(),
    ),

    // Main persistent shell navigation layout
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        // Tab 1: Accueil
        StatefulShellBranch(
          navigatorKey: _accueilNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/accueil',
              builder: (BuildContext context, GoRouterState state) =>
                  DashboardScreen(),
            ),
          ],
        ),

        // Tab 2: Activités
        StatefulShellBranch(
          navigatorKey: _activitesNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/activites',
              builder: (BuildContext context, GoRouterState state) =>
                  ActivitiesGridScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id'] ?? '';
                    return ActivityDetailScreen(id: id);
                  },
                  routes: [
                    // Activity specific screens (Pool gauges, Horse grid, etc.)
                    GoRoute(
                      path: 'pool-gauges',
                      builder: (context, state) => PoolGaugesScreen(),
                    ),
                    GoRoute(
                      path: 'horses',
                      builder: (context, state) => HorseGridScreen(),
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
                      builder: (context, state) => WeaponListScreen(),
                    ),
                    GoRoute(
                      path: 'paintball-field',
                      builder: (context, state) => PaintballFieldScreen(),
                    ),
                    GoRoute(
                      path: 'gym-equipment',
                      builder: (context, state) => GymEquipmentScreen(),
                    ),
                    GoRoute(
                      path: 'padel-courts',
                      builder: (context, state) => PadelCourtsScreen(),
                    ),
                    // Checklists inside activity
                    GoRoute(
                      path: 'checklist',
                      builder: (context, state) {
                        final activityId = state.pathParameters['id'] ?? '';
                        return ChecklistSwipeScreen(activityId: activityId);
                      },
                    ),
                    GoRoute(
                      path: 'checklist-summary',
                      builder: (context, state) {
                        final activityId = state.pathParameters['id'] ?? '';
                        return ChecklistSummaryScreen(activityId: activityId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Tickets
        StatefulShellBranch(
          navigatorKey: _ticketsNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/tickets',
              builder: (BuildContext context, GoRouterState state) =>
                  TicketsListScreen(),
              routes: [
                GoRoute(
                  path: 'nouveau',
                  builder: (BuildContext context, GoRouterState state) =>
                      CreateTicketScreen(),
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

        // Tab 5: Plus
        StatefulShellBranch(
          navigatorKey: _plusNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/plus',
              builder: (BuildContext context, GoRouterState state) =>
                  PlusMenuScreen(),
              routes: [
                GoRoute(
                  path: 'inventaire',
                  builder: (BuildContext context, GoRouterState state) =>
                      GlobalInventoryScreen(),
                ),
                GoRoute(
                  path: 'reservations',
                  builder: (BuildContext context, GoRouterState state) =>
                      ReservationsScreen(),
                  routes: [
                    GoRoute(
                      path: 'nouvelle',
                      builder: (BuildContext context, GoRouterState state) =>
                          CreateReservationScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'rapports',
                  builder: (BuildContext context, GoRouterState state) =>
                      ReportsScreen(),
                ),
                GoRoute(
                  path: 'hors-ligne',
                  builder: (BuildContext context, GoRouterState state) =>
                      OfflineDashboardScreen(),
                ),
                GoRoute(
                  path: 'aide',
                  builder: (BuildContext context, GoRouterState state) =>
                      HelpScreen(),
                ),
                GoRoute(
                  path: 'profil',
                  builder: (BuildContext context, GoRouterState state) =>
                      ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
