import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotifications = true;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final user = authState.userDetails ?? const <String, dynamic>{};
    final displayName = _displayName(user);
    final login = _login(user);
    final role = _roleLabel(user);
    final initials = _buildInitials(displayName);

    return AppPage(
      title: 'Profil & paramètres',
      subtitle: 'Votre session et vos préférences',
      maxWidth: 800,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.accentPrimary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: colors.textOnAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.accentSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (login.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    login,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Activités affectées',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppPill(label: 'Piscine', color: colors.pool),
                      AppPill(label: 'Équitation', color: colors.horses),
                      AppPill(label: 'Padel', color: colors.padel),
                      AppPill(label: 'Stand de Tir', color: colors.shooting),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'Préférences de l\'application',
            icon: Icons.tune_rounded,
          ),
          AppPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Notifications push',
                  subtitle: 'Recevoir les alertes d\'incidents en temps réel',
                  icon: Icons.notifications_active_outlined,
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() {
                      _pushNotifications = val;
                    });
                  },
                ),
                Divider(color: colors.border, height: 1),
                _buildSwitchTile(
                  title: 'Connexion biométrique',
                  subtitle: 'Empreinte digitale ou Face ID au démarrage',
                  icon: Icons.fingerprint_rounded,
                  value: _biometrics,
                  onChanged: (val) {
                    setState(() {
                      _biometrics = val;
                    });
                  },
                ),
                Divider(color: colors.border, height: 1),
                _buildThemeModeTile(),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.danger,
              side: BorderSide(color: colors.danger.withValues(alpha: 0.6)),
              minimumSize: const Size.fromHeight(56),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text(
                  'Amarna Club Management',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Build 2606)',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(Map<String, dynamic> user) {
    final value = user['name']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Utilisateur Odoo';
  }

  String _login(Map<String, dynamic> user) {
    final username = user['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
    final login = user['login']?.toString().trim();
    if (login != null && login.isNotEmpty) return login;
    return '';
  }

  String _roleLabel(Map<String, dynamic> user) {
    final company = user['user_companies']?['current_company']?.toString().trim();
    if (company != null && company.isNotEmpty) {
      return 'Société : $company';
    }

    return 'Session authentifiée via Odoo';
  }

  String _buildInitials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'OD';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  Widget _buildThemeModeTile() {
    final colors = context.colors;
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6_outlined, color: colors.textSecondary),
              const SizedBox(width: 16),
              Text(
                'Apparence',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, 48)),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Auto'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEnabled = true,
  }) {
    final colors = context.colors;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Icon(icon, color: colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeThumbColor: colors.accentPrimary,
      activeTrackColor: colors.accentPrimary.withValues(alpha: 0.3),
    );
  }
}
