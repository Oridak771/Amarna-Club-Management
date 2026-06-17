import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/stub_screens.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/activities_grid_screen.dart';
import 'screens/maintenance_list_screen.dart';
import 'screens/incidents_list_screen.dart';
import 'screens/plus_menu_screen.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/create_maintenance_screen.dart';
import 'screens/maintenance_detail_screen.dart';
import 'screens/quick_incident_report_screen.dart';
import 'screens/incident_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/offline_dashboard_screen.dart';

// Activity specific screens
import 'screens/activities/pool_gauges_screen.dart';
import 'screens/activities/horse_grid_screen.dart';
import 'screens/activities/horse_profile_screen.dart';
import 'screens/activities/weapon_list_screen.dart';
import 'screens/activities/paintball_field_screen.dart';
import 'screens/activities/gym_equipment_screen.dart';
import 'screens/activities/padel_courts_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _accueilNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'accueil');
final GlobalKey<NavigatorState> _activitesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'activites');
final GlobalKey<NavigatorState> _maintenanceNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'maintenance');
final GlobalKey<NavigatorState> _incidentsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'incidents');
final GlobalKey<NavigatorState> _plusNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'plus');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Start with Splash Screen
  routes: <RouteBase>[
    // Splash, Auth & Onboarding Flows
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
    ),

    // QR & NFC Scan (Global overlay modal)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scan',
      builder: (BuildContext context, GoRouterState state) => const QRScanScreen(),
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

    // Main persistent shell navigation layout
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        // Tab 1: Accueil
        StatefulShellBranch(
          navigatorKey: _accueilNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/accueil',
              builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
            ),
          ],
        ),

        // Tab 2: Activités
        StatefulShellBranch(
          navigatorKey: _activitesNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/activites',
              builder: (BuildContext context, GoRouterState state) => const ActivitiesGridScreen(),
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
                      builder: (context, state) => const PoolGaugesScreen(),
                    ),
                    GoRoute(
                      path: 'horses',
                      builder: (context, state) => const HorseGridScreen(),
                      routes: [
                        GoRoute(
                          path: ':horseId',
                          builder: (context, state) {
                            final horseId = state.pathParameters['horseId'] ?? '';
                            return HorseProfileScreen(id: horseId);
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'weapon-list',
                      builder: (context, state) => const WeaponListScreen(),
                    ),
                    GoRoute(
                      path: 'paintball-field',
                      builder: (context, state) => const PaintballFieldScreen(),
                    ),
                    GoRoute(
                      path: 'gym-equipment',
                      builder: (context, state) => const GymEquipmentScreen(),
                    ),
                    GoRoute(
                      path: 'padel-courts',
                      builder: (context, state) => const PadelCourtsScreen(),
                    ),
                    // Checklists inside activity
                    GoRoute(
                      path: 'checklist',
                      builder: (context, state) => const ChecklistSwipeScreen(),
                    ),
                    GoRoute(
                      path: 'checklist-summary',
                      builder: (context, state) => const ChecklistSummaryScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Maintenance
        StatefulShellBranch(
          navigatorKey: _maintenanceNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/maintenance',
              builder: (BuildContext context, GoRouterState state) => const MaintenanceListScreen(),
              routes: [
                GoRoute(
                  path: 'nouveau',
                  builder: (BuildContext context, GoRouterState state) => const CreateMaintenanceScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id'] ?? '';
                    return MaintenanceDetailScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 4: Incidents
        StatefulShellBranch(
          navigatorKey: _incidentsNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/incidents',
              builder: (BuildContext context, GoRouterState state) => const IncidentsListScreen(),
              routes: [
                GoRoute(
                  path: 'nouveau',
                  builder: (BuildContext context, GoRouterState state) => const QuickIncidentReportScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (BuildContext context, GoRouterState state) {
                    final id = state.pathParameters['id'] ?? '';
                    return IncidentDetailScreen(id: id);
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
              builder: (BuildContext context, GoRouterState state) => const PlusMenuScreen(),
              routes: [
                GoRoute(
                  path: 'inventaire',
                  builder: (BuildContext context, GoRouterState state) => const GlobalInventoryScreen(),
                ),
                GoRoute(
                  path: 'reservations',
                  builder: (BuildContext context, GoRouterState state) => const ReservationsScreen(),
                ),
                GoRoute(
                  path: 'rapports',
                  builder: (BuildContext context, GoRouterState state) => const ReportsScreen(),
                ),
                GoRoute(
                  path: 'hors-ligne',
                  builder: (BuildContext context, GoRouterState state) => const OfflineDashboardScreen(),
                ),
                GoRoute(
                  path: 'aide',
                  builder: (BuildContext context, GoRouterState state) => const HelpScreen(),
                ),
                GoRoute(
                  path: 'profil',
                  builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
