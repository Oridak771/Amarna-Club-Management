import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

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
        title: Text('Profil & Paramètres'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Info Card
                Container(
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: context.colors.accentPrimary,
                        child: Text(
                          'OP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Opérateur Principal',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rôle : Superviseur Opérations',
                        style: TextStyle(
                          color: context.colors.accentSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      Divider(color: context.colors.border),
                      SizedBox(height: 8),
                      // Assigned Activities tags
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Activités Affectées :',
                          style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildActivityTag(
                                'Piscine', Color(0xFF00D4FF)),
                            _buildActivityTag(
                                'Équitation', Color(0xFFFFB347)),
                            _buildActivityTag('Padel', Color(0xFF34D399)),
                            _buildActivityTag(
                                'Stand de Tir', Color(0xFFFF4757)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // 2. Preferences / Settings Options
                Text(
                  'Préférences de l\'application',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    children: [
                      // Toggle Notifications
                      _buildSwitchTile(
                        title: 'Notifications Push',
                        subtitle:
                            'Recevoir les alertes d\'incidents en temps réel',
                        icon: Icons.notifications_active_outlined,
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                          });
                        },
                      ),
                      Divider(color: context.colors.border, height: 1),
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
                      Divider(color: context.colors.border, height: 1),
                      // Dark Theme (Read-only as dark theme is default and preferred)
                      _buildSwitchTile(
                        title: 'Mode Sombre',
                        subtitle:
                            'Thème de l\'interface principale (Recommandé)',
                        icon: Icons.dark_mode_outlined,
                        value: true,
                        onChanged: (_) {},
                        isEnabled: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // 3. Logout Button (large, glove-friendly target)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.danger.withValues(alpha: 0.15),
                      foregroundColor: context.colors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: context.colors.danger, width: 1.5),
                      ),
                    ),
                    icon: Icon(Icons.logout),
                    label: Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: context.colors.textPrimary,
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
                SizedBox(height: 48),

                // 4. Version Tag
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Amarna Club Management',
                        style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Version 1.0.0 (Build 2606)',
                        style:
                            TextStyle(color: context.colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTag(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: isEnabled ? onChanged : null,
        activeThumbColor: context.colors.accentPrimary,
        activeTrackColor: context.colors.accentPrimary.withValues(alpha: 0.3),
      ),
    );
  }
}
