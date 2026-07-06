import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/priority_indicator.dart';
import '../../models/work_ticket.dart';

class GymMachine {
  final String id;
  final String name;
  final String category; // Cardio, Musculation, etc.
  bool isCleaned;
  bool isBroken;

  GymMachine({
    required this.id,
    required this.name,
    required this.category,
    this.isCleaned = false,
    this.isBroken = false,
  });
}

class GymEquipmentScreen extends StatefulWidget {
  const GymEquipmentScreen({super.key});

  @override
  State<GymEquipmentScreen> createState() => _GymEquipmentScreenState();
}

class _GymEquipmentScreenState extends State<GymEquipmentScreen> {
  late List<GymMachine> machines;

  @override
  void initState() {
    super.initState();
    machines = [
      GymMachine(
          id: 'm1',
          name: 'Tapis de course 1',
          category: 'Cardio',
          isCleaned: true),
      GymMachine(
          id: 'm2',
          name: 'Tapis de course 2',
          category: 'Cardio',
          isCleaned: false),
      GymMachine(
          id: 'm3',
          name: 'Vélo elliptique',
          category: 'Cardio',
          isCleaned: true,
          isBroken: true),
      GymMachine(
          id: 'm4',
          name: 'Presse à cuisses',
          category: 'Musculation',
          isCleaned: false),
      GymMachine(
          id: 'm5',
          name: 'Banc développé couché',
          category: 'Musculation',
          isCleaned: true),
      GymMachine(
          id: 'm6',
          name: 'Poulie vis-à-vis',
          category: 'Musculation',
          isCleaned: false),
    ];
  }

  void _markAllCleaned() {
    setState(() {
      for (var m in machines) {
        if (!m.isBroken) {
          m.isCleaned = true;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text(
              'Toutes les machines fonctionnelles marquées comme nettoyées'),
          backgroundColor: context.colors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Équipement Gym'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _markAllCleaned,
            tooltip: 'Tout marquer nettoyé',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCleaningHeader(),
          const SizedBox(height: 14),
          for (final machine in machines) ...[
            _buildMachineCard(machine),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const ActivityTicketsPanel(activityId: 'gym'),
        ],
      ),
    );
  }

  Widget _buildCleaningHeader() {
    final total = machines.where((m) => !m.isBroken).length;
    final cleaned = machines.where((m) => !m.isBroken && m.isCleaned).length;
    final brokenCount = machines.where((m) => m.isBroken).length;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nettoyage du jour : $cleaned/$total machines',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (brokenCount > 0)
                Text(
                  '$brokenCount HS',
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? cleaned / total : 0,
              minHeight: 8,
              backgroundColor: colors.surfaceHover,
              valueColor: AlwaysStoppedAnimation(
                cleaned == total ? colors.success : colors.gym,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCard(GymMachine machine) {
    return PriorityIndicator(
            priority:
                machine.isBroken ? TicketPriority.high : TicketPriority.low,
            child: Card(
              color: context.colors.backgroundSecondary,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: machine.isBroken ? context.colors.danger : context.colors.border,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                machine.name,
                                style: TextStyle(
                                  color: machine.isBroken
                                      ? context.colors.textSecondary
                                      : context.colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: machine.isBroken
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (machine.isBroken) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        context.colors.danger.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('HS',
                                      style: TextStyle(
                                          color: context.colors.danger,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            machine.category,
                            style: TextStyle(
                                color: context.colors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    if (!machine.isBroken) ...[
                      // Cleaning Toggle
                      Column(
                        children: [
                          Icon(
                            machine.isCleaned
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: machine.isCleaned
                                ? context.colors.success
                                : context.colors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text('Nettoyé',
                              style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 10)),
                        ],
                      ),
                      Switch(
                        value: machine.isCleaned,
                        onChanged: (val) {
                          setState(() {
                            machine.isCleaned = val;
                          });
                        },
                        activeThumbColor: context.colors.success,
                      ),
                    ] else ...[
                      // Broken State Action
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.surface,
                          foregroundColor: context.colors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => context.go('/tickets/nouveau'),
                        icon: Icon(Icons.build,
                            size: 16, color: context.colors.warning),
                        label: const Text('Réparer',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],

                    // More Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: context.colors.textSecondary),
                      color: context.colors.backgroundElevated,
                      onSelected: (val) {
                        if (val == 'report') {
                          setState(() {
                            machine.isBroken = true;
                            machine.isCleaned =
                                false; // logic: if broken, cleaning isn't relevant
                          });
                          context.go('/tickets/nouveau');
                        } else if (val == 'resolve') {
                          setState(() {
                            machine.isBroken = false;
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        if (!machine.isBroken)
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: context.colors.danger, size: 20),
                                const SizedBox(width: 8),
                                Text('Signaler Panne',
                                    style: TextStyle(
                                        color: context.colors.textPrimary)),
                              ],
                            ),
                          )
                        else
                          PopupMenuItem<String>(
                            value: 'resolve',
                            child: Row(
                              children: [
                                Icon(Icons.check,
                                    color: context.colors.success, size: 20),
                                const SizedBox(width: 8),
                                Text('Marquer Fonctionnel',
                                    style: TextStyle(
                                        color: context.colors.textPrimary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
