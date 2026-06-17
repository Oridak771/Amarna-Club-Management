import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
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
      const SnackBar(
          content: Text(
              'Toutes les machines fonctionnelles marquées comme nettoyées'),
          backgroundColor: AppColors.success),
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: machines.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final machine = machines[index];

          return PriorityIndicator(
            priority:
                machine.isBroken ? TicketPriority.high : TicketPriority.low,
            child: Card(
              color: AppColors.backgroundSecondary,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: machine.isBroken ? AppColors.danger : AppColors.border,
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
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
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
                                        AppColors.danger.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HS',
                                      style: TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            machine.category,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
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
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          const Text('Nettoyé',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
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
                        activeThumbColor: AppColors.success,
                      ),
                    ] else ...[
                      // Broken State Action
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          // Could resolve the issue or show details
                          context.push('/maintenance/nouveau');
                        },
                        icon: const Icon(Icons.build,
                            size: 16, color: AppColors.warning),
                        label: const Text('Réparer',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],

                    // More Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.textSecondary),
                      color: AppColors.backgroundElevated,
                      onSelected: (val) {
                        if (val == 'report') {
                          setState(() {
                            machine.isBroken = true;
                            machine.isCleaned =
                                false; // logic: if broken, cleaning isn't relevant
                          });
                          context.push('/incidents/nouveau');
                        } else if (val == 'resolve') {
                          setState(() {
                            machine.isBroken = false;
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        if (!machine.isBroken)
                          const PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: AppColors.danger, size: 20),
                                SizedBox(width: 8),
                                Text('Signaler Panne',
                                    style: TextStyle(
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem<String>(
                            value: 'resolve',
                            child: Row(
                              children: [
                                Icon(Icons.check,
                                    color: AppColors.success, size: 20),
                                SizedBox(width: 8),
                                Text('Marquer Fonctionnel',
                                    style: TextStyle(
                                        color: AppColors.textPrimary)),
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
        },
      ),
    );
  }
}
