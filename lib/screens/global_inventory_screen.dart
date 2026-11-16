import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/app_layout.dart';
import '../widgets/inventory_stepper.dart';

/// « Inventaire » — consumables of every activity, with quick stock steppers.
///
/// Search by name, narrow by activity (the list is built from the synced
/// data), or show only what needs restocking.
class GlobalInventoryScreen extends ConsumerStatefulWidget {
  const GlobalInventoryScreen({super.key});

  @override
  ConsumerState<GlobalInventoryScreen> createState() =>
      _GlobalInventoryScreenState();
}

class _GlobalInventoryScreenState extends ConsumerState<GlobalInventoryScreen> {
  String _query = '';
  String? _activityId; // null = every activity
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inventory = ref.watch(inventoryProvider);

    // One chip per activity that actually has consumables.
    final activities = <String, String>{};
    for (final item in inventory) {
      if (item.activityId.isEmpty) continue;
      activities.putIfAbsent(
        item.activityId,
        () => item.activityName.isEmpty ? item.activityId : item.activityName,
      );
    }
    final activityEntries = activities.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final lowCount = inventory.where((i) => i.isLowStock).length;
    final query = _query.trim().toLowerCase();
    final visible = inventory.where((item) {
      if (_activityId != null && item.activityId != _activityId) return false;
      if (_lowOnly && !item.isLowStock) return false;
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Empty and low items first, so restocking is what the eye meets.
        final byRisk = _risk(a).compareTo(_risk(b));
        return byRisk != 0 ? byRisk : a.name.compareTo(b.name);
      });

    return AppPage(
      title: 'Inventaire',
      subtitle: lowCount == 0
          ? '${inventory.length} consommables · stock suffisant'
          : '${inventory.length} consommables · $lowCount à réapprovisionner',
      onRefresh: () => ref.read(inventoryProvider.notifier).refreshFromOdoo(),
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/accueil'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Rechercher un consommable',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppFilterChip(
                  label: 'Toutes les activités',
                  isSelected: _activityId == null,
                  count: inventory.length,
                  onTap: () => setState(() => _activityId = null),
                ),
                const SizedBox(width: 8),
                for (final entry in activityEntries) ...[
                  AppFilterChip(
                    label: entry.value,
                    isSelected: _activityId == entry.key,
                    count: inventory
                        .where((i) => i.activityId == entry.key)
                        .length,
                    onTap: () => setState(() => _activityId = entry.key),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: _lowOnly ? colors.warning : colors.textSecondary,
              ),
              label: Text('Stock bas uniquement ($lowCount)'),
              selected: _lowOnly,
              onSelected: (value) => setState(() => _lowOnly = value),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: _lowOnly ? colors.warning : colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (inventory.isEmpty)
            const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aucun consommable synchronisé',
              message: 'Tirez vers le bas pour actualiser depuis Odoo.',
            )
          else if (visible.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Aucun résultat',
              message: 'Essayez un autre mot ou retirez les filtres.',
            )
          else
            for (final InventoryItem item in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InventoryStepper(
                  item: item,
                  onChanged: (delta) => ref
                      .read(inventoryProvider.notifier)
                      .adjustStock(item.id, delta),
                ),
              ),
        ],
      ),
    );
  }

  static int _risk(InventoryItem item) {
    if (item.isOutOfStock) return 0;
    if (item.isLowStock) return 1;
    return 2;
  }
}
