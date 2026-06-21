import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count; // Optional bubble showing total count

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? context.colors.accentPrimary.withValues(alpha: 0.10)
          : context.colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? context.colors.accentPrimary : context.colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? context.colors.accentPrimary
                      : context.colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count != null) ...[
                SizedBox(width: 6),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.accentPrimary.withValues(alpha: 0.2)
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected
                          ? context.colors.accentPrimary
                          : context.colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
