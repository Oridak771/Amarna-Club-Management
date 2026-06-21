import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ActivityStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case ActivityStatus.open:
        backgroundColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        icon = Icons.check_circle_outline;
        text = "Ouvert";
        break;
      case ActivityStatus.closed:
        backgroundColor = AppColors.danger.withValues(alpha: 0.15);
        textColor = AppColors.danger;
        icon = Icons.cancel_outlined;
        text = "Ferme";
        break;
      case ActivityStatus.warning:
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        icon = Icons.error_outline;
        text = "Attention";
        break;
      case ActivityStatus.maintenance:
        backgroundColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.info;
        icon = Icons.build_circle_outlined;
        text = "Maintenance";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
