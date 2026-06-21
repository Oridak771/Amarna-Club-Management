import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class GlobalInventoryScreen extends ConsumerStatefulWidget {
  const GlobalInventoryScreen({super.key});

  @override
  ConsumerState<GlobalInventoryScreen> createState() =>
      _GlobalInventoryScreenState();
}

class _GlobalInventoryScreenState extends ConsumerState<GlobalInventoryScreen> {
  String _searchQuery = '';
  String _selectedActivityId = 'all';

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);

    // List of unique activities for filtering
    final activities = [
      {'id': 'all', 'name': 'Tout'},
      {'id': 'pool', 'name': 'Piscine'},
      {'id': 'horses', 'name': 'Équitation'},
      {'id': 'paintball', 'name': 'Paintball'},
      {'id': 'shooting', 'name': 'Stand de Tir'},
      {'id': 'gym', 'name': 'Gym'},
      {'id': 'padel', 'name': 'Padel'},
    ];

    // Filter and search
    final filteredItems = inventory.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesActivity = _selectedActivityId == 'all' ||
          item.activityId == _selectedActivityId;
      return matchesSearch && matchesActivity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventaire Global'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher un consommable...',
                hintStyle: TextStyle(color: context.colors.textMuted),
                prefixIcon:
                    Icon(Icons.search, color: context.colors.textSecondary),
                filled: true,
                fillColor: context.colors.backgroundSecondary,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.accentPrimary),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // 2. Horizontal Activity Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: activities.map((act) {
                final isSelected = _selectedActivityId == act['id'];
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(act['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivityId = selected ? act['id']! : 'all';
                      });
                    },
                    backgroundColor: context.colors.backgroundSecondary,
                    selectedColor: context.colors.accentPrimary,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : context.colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : context.colors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Main List/Grid View (Responsive design)
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double screenWidth = constraints.maxWidth;
                      final int crossAxisCount = screenWidth > 600 ? 2 : 1;

                      if (crossAxisCount > 1) {
                        // Tablet/Desktop Grid
                        return GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 140,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildInventoryCard(filteredItems[index]);
                          },
                        );
                      } else {
                        // Mobile List
                        return ListView.separated(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildInventoryCard(filteredItems[index]);
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: context.colors.textMuted),
            SizedBox(height: 16),
            Text(
              'Aucun article trouvé',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Essayez de modifier votre recherche ou le filtre d\'activité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final isLowStock = item.isLowStock;
    final isOutOfStock = item.isOutOfStock;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutOfStock
              ? context.colors.danger.withValues(alpha: 0.6)
              : isLowStock
                  ? context.colors.warning.withValues(alpha: 0.6)
                  : context.colors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Activity Pill Tag
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getActivityColor(item.activityId)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.activityName,
                    style: TextStyle(
                      color: _getActivityColor(item.activityId),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // Item Name
                Text(
                  item.name,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),

                // Stock Level Text
                Row(
                  children: [
                    Text(
                      'Stock : ${item.currentStock} ${item.unitName}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? context.colors.danger
                            : isLowStock
                                ? context.colors.warning
                                : context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isLowStock ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isOutOfStock) ...[
                      SizedBox(width: 8),
                      Text(
                        '⚠️ ÉPUISÉ',
                        style: TextStyle(
                            color: context.colors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ] else if (isLowStock) ...[
                      SizedBox(width: 8),
                      Text(
                        '⚠️ SEUIL BAS',
                        style: TextStyle(
                            color: context.colors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),

          // Right Content: Quantitative Stepper (48x48px touch targets)
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                // Decrement Button
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    onTap: item.currentStock > 0
                        ? () {
                            ref
                                .read(inventoryProvider.notifier)
                                .adjustStock(item.id, -1);
                          }
                        : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.remove,
                        color: context.colors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Divider
                Container(width: 1, height: 28, color: context.colors.border),
                // Quantifier label
                Container(
                  constraints: BoxConstraints(minWidth: 40),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.currentStock}',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Divider
                Container(width: 1, height: 28, color: context.colors.border),
                // Increment Button
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    onTap: () {
                      ref
                          .read(inventoryProvider.notifier)
                          .adjustStock(item.id, 1);
                    },
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.add,
                        color: context.colors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String activityId) {
    switch (activityId.toLowerCase()) {
      case 'pool':
        return const Color(0xFF00D4FF); // Cyan
      case 'horses':
        return const Color(0xFFFFB347); // Amber
      case 'paintball':
        return const Color(0xFF7CFC00); // Lime
      case 'shooting':
        return const Color(0xFFFF4757); // Red
      case 'gym':
        return const Color(0xFFA855F7); // Purple
      case 'padel':
        return const Color(0xFF34D399); // Emerald
      default:
        return context.colors.accentPrimary;
    }
  }
}
