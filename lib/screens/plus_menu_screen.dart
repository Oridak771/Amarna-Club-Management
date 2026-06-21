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

  List<_PlusMenuItem> _getMenuItems(BuildContext context) {
    return [
      _PlusMenuItem(
        icon: Icons.inventory_2_outlined,
        iconColor: context.colors.horses, // orange
        label: 'Inventaire',
        subtitle: 'Gerer les stocks',
        route: '/plus/inventaire',
      ),
      _PlusMenuItem(
        icon: Icons.calendar_month_outlined,
        iconColor: context.colors.pool, // cyan
        label: 'Reservations',
        subtitle: 'Voir les reservations',
        route: '/plus/reservations',
      ),
      _PlusMenuItem(
        icon: Icons.bar_chart_rounded,
        iconColor: context.colors.gym, // purple
        label: 'Rapports',
        subtitle: 'Tableaux de bord (Manager)',
        route: '/plus/rapports',
      ),
      _PlusMenuItem(
        icon: Icons.wifi_off_rounded,
        iconColor: context.colors.warning, // amber
        label: 'Mode hors-ligne',
        subtitle: 'Statut de synchronisation',
        route: '/plus/hors-ligne',
      ),
      _PlusMenuItem(
        icon: Icons.help_outline_rounded,
        iconColor: context.colors.padel, // teal
        label: 'Aide',
        subtitle: 'FAQ et support',
        route: '/plus/aide',
      ),
      _PlusMenuItem(
        icon: Icons.person_outline_rounded,
        iconColor: context.colors.accentPrimary, // blue
        label: 'Profil & Parametres',
        subtitle: 'Mon compte',
        route: '/plus/profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plus'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner QR',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
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
                constraints: BoxConstraints(maxWidth: 900),
                padding: EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: _getMenuItems(context).length,
                  itemBuilder: (context, index) {
                    final item = _getMenuItems(context)[index];
                    return _buildMenuItem(context, item);
                  },
                ),
              ),
            );
          } else {
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _getMenuItems(context).length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _getMenuItems(context)[index];
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
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.colors.border, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.12),
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
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: context.colors.textMuted,
              size: 24,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minVerticalPadding: 0,
          ),
        ),
      ),
    );
  }
}
