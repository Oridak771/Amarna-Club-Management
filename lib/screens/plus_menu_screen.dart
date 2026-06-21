import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amarna_club/theme/app_theme.dart';

/// Data class for each menu entry in the Plus screen.
class _PlusMenuItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String route;

  const _PlusMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.route,
  });
}

/// Ecran  Plus  — menu de navigation secondaire.
class PlusMenuScreen extends StatelessWidget {
  const PlusMenuScreen({super.key});

  static const List<_PlusMenuItem> _menuItems = [
    _PlusMenuItem(
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.horses, // orange
      label: 'Inventaire',
      subtitle: 'Gerer les stocks',
      route: '/plus/inventaire',
    ),
    _PlusMenuItem(
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.pool, // cyan
      label: 'Reservations',
      subtitle: 'Voir les reservations',
      route: '/plus/reservations',
    ),
    _PlusMenuItem(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.gym, // purple
      label: 'Rapports',
      subtitle: 'Tableaux de bord (Manager)',
      route: '/plus/rapports',
    ),
    _PlusMenuItem(
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.warning, // amber
      label: 'Mode hors-ligne',
      subtitle: 'Statut de synchronisation',
      route: '/plus/hors-ligne',
    ),
    _PlusMenuItem(
      icon: Icons.help_outline_rounded,
      iconColor: AppColors.padel, // teal
      label: 'Aide',
      subtitle: 'FAQ et support',
      route: '/plus/aide',
    ),
    _PlusMenuItem(
      icon: Icons.person_outline_rounded,
      iconColor: AppColors.accentPrimary, // blue
      label: 'Profil & Parametres',
      subtitle: 'Mon compte',
      route: '/plus/profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return _buildMenuItem(context, item);
                  },
                ),
              ),
            );
          } else {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return _buildMenuItem(context, item);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _PlusMenuItem item) {
    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 24,
              ),
            ),
            title: Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minVerticalPadding: 0,
          ),
        ),
      ),
    );
  }
}
