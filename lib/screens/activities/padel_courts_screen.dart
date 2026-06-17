import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class PadelCourt {
  final String id;
  final String name;
  String status; // 'Disponible', 'Occupé', 'Maintenance'
  DateTime? sessionStartTime;

  PadelCourt({required this.id, required this.name, required this.status, this.sessionStartTime});
}

class PadelCourtsScreen extends StatefulWidget {
  const PadelCourtsScreen({super.key});

  @override
  State<PadelCourtsScreen> createState() => _PadelCourtsScreenState();
}

class _PadelCourtsScreenState extends State<PadelCourtsScreen> {
  late List<PadelCourt> courts;

  @override
  void initState() {
    super.initState();
    courts = [
      PadelCourt(id: 'c1', name: 'Terrain 1 (Intérieur)', status: 'Occupé', sessionStartTime: DateTime.now().subtract(const Duration(minutes: 45))),
      PadelCourt(id: 'c2', name: 'Terrain 2 (Intérieur)', status: 'Disponible'),
      PadelCourt(id: 'c3', name: 'Terrain 3 (Extérieur)', status: 'Disponible'),
      PadelCourt(id: 'c4', name: 'Terrain 4 (Extérieur)', status: 'Maintenance'),
    ];
  }

  void _toggleSession(int index) {
    setState(() {
      final court = courts[index];
      if (court.status == 'Disponible') {
        court.status = 'Occupé';
        court.sessionStartTime = DateTime.now();
      } else if (court.status == 'Occupé') {
        court.status = 'Disponible';
        court.sessionStartTime = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terrains de Padel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/plus/reservations'),
            tooltip: 'Réservations',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              return _buildCourtCard(context, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, int index) {
    final court = courts[index];
    Color statusColor;
    
    if (court.status == 'Disponible') {
      statusColor = AppColors.success;
    } else if (court.status == 'Occupé') {
      statusColor = AppColors.padel;
    } else {
      statusColor = AppColors.warning;
    }

    return Card(
      color: AppColors.backgroundSecondary,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: court.status == 'Occupé' ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: statusColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    court.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(court.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (court.status == 'Occupé' && court.sessionStartTime != null) ...[
                    const Icon(Icons.timer, color: AppColors.padel, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'En cours depuis ${DateTime.now().difference(court.sessionStartTime!).inMinutes} min',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ] else if (court.status == 'Disponible') ...[
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
                    const SizedBox(height: 8),
                    const Text('Prêt pour une session', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ] else ...[
                    const Icon(Icons.build, color: AppColors.warning, size: 32),
                    const SizedBox(height: 8),
                    const Text('Intervention nécessaire', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
          
          // Actions
          if (court.status != 'Maintenance')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: court.status == 'Disponible' ? AppColors.padel : AppColors.surface,
                  foregroundColor: court.status == 'Disponible' ? Colors.white : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _toggleSession(index),
                child: Text(
                  court.status == 'Disponible' ? 'Démarrer Session' : 'Terminer Session',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                  foregroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                   setState(() {
                     court.status = 'Disponible';
                   });
                },
                child: const Text(
                  'Marquer Réparé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
