import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KPITile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String title;
  final String? subtitle;
  final String? trendText;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  KPITile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.title,
    this.subtitle,
    this.trendText,
    this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.colors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  if (trendText != null)
                    Row(
                      children: [
                        Icon(
                          isPositiveTrend == true
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: isPositiveTrend == true
                              ? context.colors.success
                              : context.colors.danger,
                        ),
                        SizedBox(width: 2),
                        Text(
                          trendText!,
                          style: TextStyle(
                            color: isPositiveTrend == true
                                ? context.colors.success
                                : context.colors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
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
