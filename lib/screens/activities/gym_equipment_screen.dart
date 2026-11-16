import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';

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
    final colors = context.colors;
    return AppPage(
      title: 'Équipement Gym',
      subtitle: 'Nettoyage et pannes du jour',
      actions: [
        IconButton.filledTonal(
          tooltip: 'Scanner QR',
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push('/scan'),
        ),
      ],
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colors.success,
          foregroundColor: colors.textOnAccent,
        ),
        onPressed: _markAllCleaned,
        icon: const Icon(Icons.cleaning_services_rounded),
        label: const Text('Tout marquer nettoyé'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCleaningHeader(),
          const SizedBox(height: 16),
          for (final machine in machines) ...[
            _buildMachineCard(machine),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
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

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nettoyage du jour : $cleaned/$total machines',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (brokenCount > 0)
                AppPill(
                  label: '$brokenCount HS',
                  color: colors.danger,
                  icon: Icons.build_circle_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
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
    final colors = context.colors;
    return AppPanel(
      accentColor: machine.isBroken ? colors.danger : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        machine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: machine.isBroken
                              ? colors.textSecondary
                              : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: machine.isBroken
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (machine.isBroken) ...[
                      const SizedBox(width: 8),
                      AppPill(label: 'HS', color: colors.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  machine.category,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!machine.isBroken) ...[
            // Cleaning toggle
            Icon(
              machine.isCleaned
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: machine.isCleaned ? colors.success : colors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text('Nettoyé',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            Switch(
              value: machine.isCleaned,
              onChanged: (val) {
                setState(() {
                  machine.isCleaned = val;
                });
              },
              activeThumbColor: colors.success,
            ),
          ] else ...[
            // Broken state action
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => context.go('/tickets/nouveau'),
              icon: Icon(Icons.build, size: 18, color: colors.warning),
              label: const Text('Réparer'),
            ),
          ],

          // More menu
          PopupMenuButton<String>(
            tooltip: 'Actions',
            padding: const EdgeInsets.all(12),
            icon: Icon(Icons.more_vert, color: colors.textSecondary),
            color: colors.backgroundElevated,
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
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (!machine.isBroken)
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Signaler Panne',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                )
              else
                PopupMenuItem<String>(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: colors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('Marquer Fonctionnel',
                          style: TextStyle(color: colors.textPrimary)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
