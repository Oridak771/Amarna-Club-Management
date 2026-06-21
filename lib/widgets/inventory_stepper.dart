import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../theme/app_theme.dart';

class InventoryStepper extends StatelessWidget {
  final InventoryItem item;
  final Function(int) onChanged;

  const InventoryStepper({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = item.isLowStock;

    return Card(
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLow
              ? context.colors.danger.withValues(alpha: 0.5)
              : context.colors.border,
          width: isLow ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Unit info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLow)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'STOCK BAS',
                      style: TextStyle(
                        color: context.colors.danger,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),

            // Current stock details
            Row(
              children: [
                Text(
                  'Stock actuel: ',
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
                Text(
                  '${item.currentStock} ${item.unitName}',
                  style: TextStyle(
                    color: isLow ? context.colors.danger : context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Interactive Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decrement Button (min 48x48px target)
                Material(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: item.isOutOfStock ? null : () => onChanged(-1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: item.isOutOfStock
                            ? context.colors.textMuted
                            : context.colors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Value indicator
                Container(
                  width: 80,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.backgroundElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Text(
                    '${item.currentStock}',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Increment Button (min 48x48px target)
                Material(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onChanged(1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Icon(
                        Icons.add,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Warning threshold details
            SizedBox(height: 8),
            Text(
              'Seuil d\'alerte: ${item.lowThreshold} ${item.unitName}',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
