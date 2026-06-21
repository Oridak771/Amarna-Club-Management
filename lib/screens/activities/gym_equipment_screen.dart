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
  GymEquipmentScreen({super.key});

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
          content: Text(
              'Toutes les machines fonctionnelles marquées comme nettoyées'),
          backgroundColor: context.colors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Équipement Gym'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: _markAllCleaned,
            tooltip: 'Tout marquer nettoyé',
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.0),
        itemCount: machines.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final machine = machines[index];

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
                padding: EdgeInsets.all(16.0),
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
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
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
                          SizedBox(height: 4),
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
                          SizedBox(height: 4),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          // Could resolve the issue or show details
                          context.push('/maintenance/nouveau');
                        },
                        icon: Icon(Icons.build,
                            size: 16, color: context.colors.warning),
                        label: Text('Réparer',
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
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: context.colors.danger, size: 20),
                                SizedBox(width: 8),
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
                                SizedBox(width: 8),
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
        },
      ),
    );
  }
}
