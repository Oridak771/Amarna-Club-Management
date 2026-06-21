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
    final String status =
        id == 'h4' ? 'Blessé' : (id == 'h2' ? 'Au repos' : 'Disponible');
    final double fatigue = id == 'h2' ? 0.8 : 0.2;

    Color statusColor;
    if (status == 'Disponible') {
      statusColor = context.colors.success;
    } else if (status == 'Au repos') {
      statusColor = context.colors.warning;
    } else {
      statusColor = context.colors.danger;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Photo Header
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: context.colors.backgroundPrimary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black54)
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: context.colors.surface,
                    child: Center(
                      child: Icon(Icons.pets,
                          size: 100, color: context.colors.textMuted),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.colors.backgroundPrimary.withValues(alpha: 0.9),
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
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Info Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Race: Selle Français',
                              style: TextStyle(color: context.colors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Âge: 8 ans',
                              style: TextStyle(color: context.colors.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Quick Actions
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        QuickActionButton(
                          icon: Icons.nightlight_round,
                          label: 'Au Repos',
                          color: context.colors.warning,
                          onTap: () {},
                        ),
                        SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.local_hospital,
                          label: 'Signaler Blessure',
                          color: context.colors.danger,
                          onTap: () {},
                        ),
                        SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.restaurant,
                          label: 'Alimentation',
                          color: context.colors.success,
                          onTap: () {},
                        ),
                        SizedBox(width: 12),
                        QuickActionButton(
                          icon: Icons.check_circle_outline,
                          label: 'Disponible',
                          color: context.colors.success,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Health & Status Section
                  Text('Indicateurs de Santé',
                      style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),

                  Card(
                    color: context.colors.backgroundSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.colors.border)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildProgressIndicator(
                              context, 'Fatigue', fatigue, context.colors.horses),
                          SizedBox(height: 16),
                          _buildProgressIndicator(
                              context, 'Hydratation', 0.9, context.colors.pool),
                          SizedBox(height: 16),
                          _buildProgressIndicator(
                              context, 'Poids (Idéal)', 0.95, context.colors.success),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Riding Log
                  Text("Journal de Monte (Aujourd'hui)",
                      style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildLogItem(context, '09:00 - 10:00', 'Entraînement Saut',
                      'Cavalier: Jean Dupont'),
                  _buildLogItem(
                      context, '14:30 - 15:30', 'Balade Forêt', 'Cavalier: Marie Curie'),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: context.colors.textSecondary, fontSize: 13)),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: context.colors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(BuildContext context, String time, String title, String subtitle) {
    return Card(
      color: context.colors.backgroundSecondary,
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.colors.border)),
      child: ListTile(
        leading: Icon(Icons.timer, color: context.colors.textMuted),
        title: Text(title,
            style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    color: context.colors.horses,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    color: context.colors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
