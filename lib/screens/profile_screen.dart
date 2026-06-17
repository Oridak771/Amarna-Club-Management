import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Info Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accentPrimary,
                        child: Text(
                          'OP',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Opérateur Principal',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Rôle : Superviseur Opérations',
                        style: TextStyle(
                          color: AppColors.accentSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 8),
                      // Assigned Activities tags
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Activités Affectées :',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildActivityTag('Piscine', const Color(0xFF00D4FF)),
                            _buildActivityTag('Équitation', const Color(0xFFFFB347)),
                            _buildActivityTag('Padel', const Color(0xFF34D399)),
                            _buildActivityTag('Stand de Tir', const Color(0xFFFF4757)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Preferences / Settings Options
                const Text(
                  'Préférences de l\'application',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Toggle Notifications
                      _buildSwitchTile(
                        title: 'Notifications Push',
                        subtitle: 'Recevoir les alertes d\'incidents en temps réel',
                        icon: Icons.notifications_active_outlined,
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                          });
                        },
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      // Toggle Biometry
                      _buildSwitchTile(
                        title: 'Connexion Biométrique',
                        subtitle: 'Empreinte digitale ou FaceID au démarrage',
                        icon: Icons.fingerprint,
                        value: _biometrics,
                        onChanged: (val) {
                          setState(() {
                            _biometrics = val;
                          });
                        },
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      // Dark Theme (Read-only as dark theme is default and preferred)
                      _buildSwitchTile(
                        title: 'Mode Sombre',
                        subtitle: 'Thème de l\'interface principale (Recommandé)',
                        icon: Icons.dark_mode_outlined,
                        value: true,
                        onChanged: (_) {},
                        isEnabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Logout Button (large, glove-friendly target)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      // Redirect to login page
                      context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // 4. Version Tag
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Amarna Club Management',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Version 1.0.0 (Build 2606)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTag(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: isEnabled ? onChanged : null,
        activeThumbColor: AppColors.accentPrimary,
        activeTrackColor: AppColors.accentPrimary.withValues(alpha: 0.3),
      ),
    );
  }
}
