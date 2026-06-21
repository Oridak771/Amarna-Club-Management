import 'package:flutter/material.dart';
import '../models/activity.dart';

import '../theme/app_theme.dart';
export '../theme/app_theme.dart' show AppSemanticColors;

/// UI presentation extensions for [Activity] and [ActivityStatus].
/// Keeps models free of Flutter/color dependencies.

extension ActivityStatusUI on ActivityStatus {
  Color resolveColor(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    switch (this) {
      case ActivityStatus.open:
        return colors.success;
      case ActivityStatus.closed:
        return colors.danger;
      case ActivityStatus.warning:
        return colors.warning;
      case ActivityStatus.maintenance:
        return colors.info;
    }
  }
}

/// Resolves the branded colour for an activity by its key/id.
Color resolveActivityColor(BuildContext context, String activityKey) {
  final colors = Theme.of(context).extension<AppSemanticColors>()!;
  switch (activityKey.toLowerCase()) {
    case 'pool':
    case 'piscine':
      return colors.pool;
    case 'horses':
    case 'chevaux':
      return colors.horses;
    case 'paintball':
      return colors.paintball;
    case 'shooting':
    case 'tir':
      return colors.shooting;
    case 'gym':
      return colors.gym;
    case 'padel':
      return colors.padel;
    default:
      return colors.accentPrimary;
  }
}

/// Resolves the icon for an activity by its key.
IconData resolveActivityIcon(String iconKey) {
  switch (iconKey.toLowerCase()) {
    case 'pool':
    case 'piscine':
      return Icons.pool;
    case 'horses':
    case 'chevaux':
      return Icons.pets;
    case 'paintball':
      return Icons.adjust;
    case 'shooting':
    case 'tir':
      return Icons.gps_fixed;
    case 'gym':
      return Icons.fitness_center;
    case 'padel':
      return Icons.sports_tennis;
    default:
      return Icons.help_outline;
  }
}
