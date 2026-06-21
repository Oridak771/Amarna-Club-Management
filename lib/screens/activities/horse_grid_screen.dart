import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class Horse {
  final String id;
  final String name;
  final String status; // 'Disponible', 'Au repos', 'Blessé'
  final double fatigue; // 0.0 to 1.0

  Horse(
      {required this.id,
      required this.name,
      required this.status,
      required this.fatigue});
}

class HorseGridScreen extends StatelessWidget {
  const HorseGridScreen({super.key});

  List<Horse> _getMockHorses() {
    return [
      Horse(id: 'h1', name: 'Tornade', status: 'Disponible', fatigue: 0.2),
      Horse(id: 'h2', name: 'Pégase', status: 'Au repos', fatigue: 0.8),
      Horse(id: 'h3', name: 'Éclair', status: 'Disponible', fatigue: 0.5),
      Horse(id: 'h4', name: 'Ombre', status: 'Blessé', fatigue: 0.0),
      Horse(id: 'h5', name: 'Spirit', status: 'Disponible', fatigue: 0.1),
      Horse(id: 'h6', name: 'Jumper', status: 'Au repos', fatigue: 0.9),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final horses = _getMockHorses();

    return Scaffold(
      appBar: AppBar(
        title: Text('Grille des Chevaux'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 800
              ? 4
              : (constraints.maxWidth > 600 ? 3 : 2);

          return GridView.builder(
            padding: EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: horses.length,
            itemBuilder: (context, index) {
              final horse = horses[index];
              return _buildHorseCard(context, horse);
            },
          );
        },
      ),
    );
  }

  Widget _buildHorseCard(BuildContext context, Horse horse) {
    Color statusColor;
    if (horse.status == 'Disponible') {
      statusColor = context.colors.success;
    } else if (horse.status == 'Au repos') {
      statusColor = context.colors.warning;
    } else {
      statusColor = context.colors.danger;
    }

    return Card(
      color: context.colors.backgroundSecondary,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/activites/horses/${horse.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mock Image Area
            Expanded(
              flex: 3,
              child: Container(
                color: context.colors.surface,
                child: Icon(Icons.pets,
                    size: 48, color: context.colors.textMuted),
              ),
            ),
            // Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horse.name,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        horse.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fatigue',
                          style: TextStyle(
                              color: context.colors.textSecondary, fontSize: 10),
                        ),
                        SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: horse.fatigue,
                            backgroundColor: context.colors.backgroundPrimary,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              horse.fatigue > 0.7
                                  ? context.colors.danger
                                  : context.colors.horses,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
