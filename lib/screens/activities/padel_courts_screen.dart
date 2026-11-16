import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';

class PadelCourt {
  final String id;
  final String name;
  String status; // 'Disponible', 'Occupé', 'Maintenance'
  DateTime? sessionStartTime;

  PadelCourt(
      {required this.id,
      required this.name,
      required this.status,
      this.sessionStartTime});
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
      PadelCourt(
          id: 'c1',
          name: 'Terrain 1 (Intérieur)',
          status: 'Occupé',
          sessionStartTime:
              DateTime.now().subtract(const Duration(minutes: 45))),
      PadelCourt(id: 'c2', name: 'Terrain 2 (Intérieur)', status: 'Disponible'),
      PadelCourt(id: 'c3', name: 'Terrain 3 (Extérieur)', status: 'Disponible'),
      PadelCourt(
          id: 'c4', name: 'Terrain 4 (Extérieur)', status: 'Maintenance'),
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
    final free = courts.where((c) => c.status == 'Disponible').length;
    return AppPage(
      title: 'Terrains de Padel',
      subtitle: '$free/${courts.length} terrains libres',
      actions: [
        IconButton.filledTonal(
          tooltip: 'Réservations',
          icon: const Icon(Icons.calendar_month_rounded),
          onPressed: () => context.push('/planning'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 800
                  ? 3
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < courts.length; index++)
                    SizedBox(
                      width: width,
                      child: _buildCourtCard(context, index),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const ActivityReservationsPanel(
            activityId: 'padel',
            activityName: 'Padel',
          ),
          const SizedBox(height: 20),
          const ActivityTicketsPanel(activityId: 'padel'),
        ],
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, int index) {
    final colors = context.colors;
    final court = courts[index];
    final Color statusColor;

    if (court.status == 'Disponible') {
      statusColor = colors.success;
    } else if (court.status == 'Occupé') {
      statusColor = colors.padel;
    } else {
      statusColor = colors.warning;
    }

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: statusColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    court.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppPill(label: court.status, color: statusColor),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                if (court.status == 'Occupé' &&
                    court.sessionStartTime != null) ...[
                  Icon(Icons.timer_outlined, color: colors.padel, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'En cours depuis ${DateTime.now().difference(court.sessionStartTime!).inMinutes} min',
                    style: TextStyle(color: colors.textSecondary, fontSize: 15),
                  ),
                ] else if (court.status == 'Disponible') ...[
                  Icon(Icons.check_circle_outline,
                      color: colors.success, size: 32),
                  const SizedBox(height: 8),
                  Text('Prêt pour une session',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 15)),
                ] else ...[
                  Icon(Icons.build, color: colors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Intervention nécessaire',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 15)),
                ],
                const SizedBox(height: 16),

                // Actions
                if (court.status != 'Maintenance')
                  court.status == 'Disponible'
                      ? SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.padel,
                              foregroundColor: colors.textOnAccent,
                              minimumSize: const Size(0, 52),
                            ),
                            onPressed: () => _toggleSession(index),
                            child: const Text('Démarrer Session'),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              minimumSize: const Size(0, 52),
                            ),
                            onPressed: () => _toggleSession(index),
                            child: const Text('Terminer Session'),
                          ),
                        )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.warning,
                        side: BorderSide(
                            color: colors.warning.withValues(alpha: 0.6)),
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: () {
                        setState(() {
                          court.status = 'Disponible';
                        });
                      },
                      icon: const Icon(Icons.build_circle_outlined),
                      label: const Text('Marquer Réparé'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
