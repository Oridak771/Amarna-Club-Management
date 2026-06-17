import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quick_action_button.dart';

class HorseProfileScreen extends StatelessWidget {
  final String id;
  const HorseProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Mock horse data based on ID
    final String name = id == 'h1' ? 'Tornade' : 'Cheval $id';
    final String status = id == 'h4' ? 'Blessé' : (id == 'h2' ? 'Au repos' : 'Disponible');
    final double fatigue = id == 'h2' ? 0.8 : 0.2;
    
    Color statusColor;
    if (status == 'Disponible') {
      statusColor = AppColors.success;
    } else if (status == 'Au repos') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.danger;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Photo Header
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: AppColors.backgroundPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.pets, size: 100, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.backgroundPrimary.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Info Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Race: Selle Français', style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Âge: 8 ans', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        QuickActionButton(
                          icon: Icons.nightlight_round,
                          label: 'Au Repos',
                          color: AppColors.warning,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.local_hospital,
                          label: 'Signaler Blessure',
                          color: AppColors.danger,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.restaurant,
                          label: 'Alimentation',
                          color: AppColors.success,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.check_circle_outline,
                          label: 'Disponible',
                          color: AppColors.success,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Health & Status Section
                  const Text('Indicateurs de Santé', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: AppColors.backgroundSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildProgressIndicator('Fatigue', fatigue, AppColors.horses),
                          const SizedBox(height: 16),
                          _buildProgressIndicator('Hydratation', 0.9, AppColors.pool),
                          const SizedBox(height: 16),
                          _buildProgressIndicator('Poids (Idéal)', 0.95, AppColors.success),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Riding Log
                  const Text("Journal de Monte (Aujourd'hui)", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLogItem('09:00 - 10:00', 'Entraînement Saut', 'Cavalier: Jean Dupont'),
                  _buildLogItem('14:30 - 15:30', 'Balade Forêt', 'Cavalier: Marie Curie'),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(String time, String title, String subtitle) {
    return Card(
      color: AppColors.backgroundSecondary,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        leading: const Icon(Icons.timer, color: AppColors.textMuted),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: AppColors.horses, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
