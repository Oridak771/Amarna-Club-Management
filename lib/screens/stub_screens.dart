import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Helper to build a basic template for stub screens
Widget _buildStubPage(BuildContext context, String title, {List<Widget>? actions}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        ...?actions,
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () {
            // Navigator check or router trigger to go to scan
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Écran en cours de développement',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

// LoginScreen is now implemented in lib/screens/login_screen.dart

// OnboardingScreen is now implemented in lib/screens/onboarding_screen.dart

// DashboardScreen is now implemented in lib/screens/dashboard_screen.dart

// ActivitiesGridScreen is now implemented in lib/screens/activities_grid_screen.dart

// ActivityDetailScreen is now implemented in lib/screens/activity_detail_screen.dart

// MaintenanceListScreen is now implemented in lib/screens/maintenance_list_screen.dart

// MaintenanceDetailScreen is now implemented in lib/screens/maintenance_detail_screen.dart

// CreateMaintenanceScreen is now implemented in lib/screens/create_maintenance_screen.dart

// IncidentsListScreen is now implemented in lib/screens/incidents_list_screen.dart

// QuickIncidentReportScreen is now implemented in lib/screens/quick_incident_report_screen.dart

// IncidentDetailScreen is now implemented in lib/screens/incident_detail_screen.dart

// PlusMenuScreen is now implemented in lib/screens/plus_menu_screen.dart

class GlobalInventoryScreen extends StatelessWidget {
  const GlobalInventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Inventaire Global');
  }
}

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Réservations');
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, '📊 Rapports (Manager)');
  }
}



class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Aide & FAQs');
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Profil & Paramètres');
  }
}

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, '📷 Scanner QR / NFC');
  }
}

class AssetProfileScreen extends StatelessWidget {
  final String id;
  const AssetProfileScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Profil Asset: $id');
  }
}

class ChecklistSwipeScreen extends StatelessWidget {
  const ChecklistSwipeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, '📋 Checklist Journalière');
  }
}

class ChecklistSummaryScreen extends StatelessWidget {
  const ChecklistSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildStubPage(context, 'Résumé Checklist');
  }
}

// The following screens are implemented in their respective files in lib/screens/activities/
// - PoolGaugesScreen
// - HorseGridScreen
// - HorseProfileScreen
// - WeaponListScreen
// - PaintballFieldScreen
// - GymEquipmentScreen
// - PadelCourtsScreen
