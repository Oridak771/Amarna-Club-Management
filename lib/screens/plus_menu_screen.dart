import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

/// One entry of the « Plus » menu.
class _PlusMenuItem {
  const _PlusMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final String route;
}

/// « Plus » — secondary destinations, grouped by purpose.
///
/// Planning and the activities already have their own tabs; this screen holds
/// everything else, so the bottom bar stays five items wide.
class PlusMenuScreen extends StatelessWidget {
  const PlusMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final groups = <(String, List<_PlusMenuItem>)>[
      (
        'Opérations',
        [
          _PlusMenuItem(
            icon: Icons.inventory_2_outlined,
            color: colors.horses,
            label: 'Inventaire',
            subtitle: 'Consommables et seuils de stock',
            route: '/plus/inventaire',
          ),
          _PlusMenuItem(
            icon: Icons.card_membership_outlined,
            color: colors.accentSecondary,
            label: 'Abonnements',
            subtitle: 'Formules et séances des membres',
            route: '/plus/abonnements',
          ),
        ],
      ),
      (
        'Gestion',
        [
          _PlusMenuItem(
            icon: Icons.bar_chart_rounded,
            color: colors.gym,
            label: 'Rapports',
            subtitle: 'Tableaux de bord pour les managers',
            route: '/plus/rapports',
          ),
        ],
      ),
      (
        'Compte & aide',
        [
          _PlusMenuItem(
            icon: Icons.person_outline_rounded,
            color: colors.accentPrimary,
            label: 'Profil et réglages',
            subtitle: 'Mon compte, thème, déconnexion',
            route: '/plus/profil',
          ),
          _PlusMenuItem(
            icon: Icons.help_outline_rounded,
            color: colors.padel,
            label: 'Aide',
            subtitle: 'Guide d’utilisation et support',
            route: '/plus/aide',
          ),
        ],
      ),
    ];

    return AppPage(
      title: 'Plus',
      subtitle: 'Outils et paramètres',
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
        IconButton.filledTonal(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (title, items) in groups) ...[
            SectionTitle(title: title),
            AppPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    _MenuRow(item: items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _PlusMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => context.push(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
