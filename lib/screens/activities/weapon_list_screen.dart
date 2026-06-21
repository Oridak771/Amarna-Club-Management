import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/priority_indicator.dart';
import '../../models/work_ticket.dart';

class Weapon {
  final String id;
  final String serialNumber;
  final String model;
  final String status; // 'Disponible', 'En utilisation', 'Maintenance'
  final DateTime lastCleaned;

  Weapon({
    required this.id,
    required this.serialNumber,
    required this.model,
    required this.status,
    required this.lastCleaned,
  });
}

class WeaponListScreen extends StatefulWidget {
  WeaponListScreen({super.key});

  @override
  State<WeaponListScreen> createState() => _WeaponListScreenState();
}

class _WeaponListScreenState extends State<WeaponListScreen> {
  late List<Weapon> weapons;

  @override
  void initState() {
    super.initState();
    weapons = [
      Weapon(
          id: 'w1',
          serialNumber: 'SN-GLOCK-001',
          model: 'Glock 17',
          status: 'Disponible',
          lastCleaned: DateTime.now().subtract(Duration(days: 1))),
      Weapon(
          id: 'w2',
          serialNumber: 'SN-GLOCK-002',
          model: 'Glock 17',
          status: 'En utilisation',
          lastCleaned: DateTime.now().subtract(Duration(days: 5))),
      Weapon(
          id: 'w3',
          serialNumber: 'SN-AR15-001',
          model: 'AR-15',
          status: 'Maintenance',
          lastCleaned: DateTime.now().subtract(Duration(days: 30))),
      Weapon(
          id: 'w4',
          serialNumber: 'SN-BERETTA-001',
          model: 'Beretta 92FS',
          status: 'Disponible',
          lastCleaned: DateTime.now().subtract(Duration(days: 2))),
    ];
  }

  void _cleanWeapon(int index) {
    setState(() {
      final w = weapons[index];
      weapons[index] = Weapon(
        id: w.id,
        serialNumber: w.serialNumber,
        model: w.model,
        status: w.status,
        lastCleaned: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Nettoyage enregistré'),
          backgroundColor: context.colors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Armes'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
            tooltip: 'Scanner une arme',
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.0),
        itemCount: weapons.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final weapon = weapons[index];

          Color statusColor;
          TicketPriority priority;
          if (weapon.status == 'Disponible') {
            statusColor = context.colors.success;
            priority = TicketPriority.low;
          } else if (weapon.status == 'En utilisation') {
            statusColor = context.colors.warning;
            priority = TicketPriority.medium;
          } else {
            statusColor = context.colors.danger;
            priority = TicketPriority.critical;
          }

          final bool needsCleaning =
              DateTime.now().difference(weapon.lastCleaned).inDays > 7;
          if (needsCleaning && priority == TicketPriority.low) {
            priority =
                TicketPriority.high; // bump priority if it needs cleaning
          }

          return PriorityIndicator(
            priority: priority,
            child: Card(
              color: context.colors.backgroundSecondary,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      weapon.serialNumber,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        weapon.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6),
                    Text(weapon.model,
                        style: TextStyle(color: context.colors.textSecondary)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.cleaning_services,
                          size: 14,
                          color: needsCleaning
                              ? context.colors.danger
                              : context.colors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Dernier nettoyage : ${DateFormat('dd/MM/yyyy').format(weapon.lastCleaned)}',
                          style: TextStyle(
                            color: needsCleaning
                                ? context.colors.danger
                                : context.colors.textSecondary,
                            fontSize: 12,
                            fontWeight: needsCleaning
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: context.colors.textSecondary),
                  color: context.colors.backgroundElevated,
                  onSelected: (value) {
                    if (value == 'clean') {
                      _cleanWeapon(index);
                    } else if (value == 'maintain') {
                      context.push('/maintenance/nouveau');
                    } else if (value == 'report') {
                      context.push('/incidents/nouveau');
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'clean',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services,
                              color: context.colors.textPrimary, size: 20),
                          SizedBox(width: 8),
                          Text('Marquer nettoyé',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'maintain',
                      child: Row(
                        children: [
                          Icon(Icons.build, color: context.colors.warning, size: 20),
                          SizedBox(width: 8),
                          Text('Créer Maintenance',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: context.colors.danger, size: 20),
                          SizedBox(width: 8),
                          Text('Signaler Problème',
                              style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
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
