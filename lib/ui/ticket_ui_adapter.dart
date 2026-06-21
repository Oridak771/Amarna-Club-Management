import 'package:flutter/material.dart';
import '../models/work_ticket.dart';

import '../theme/app_theme.dart';
// Re-export so consumers only need one import for theme tokens.
export '../theme/app_theme.dart' show AppSemanticColors;
/// Keeps models free of Flutter/color dependencies.

extension TicketPriorityUI on TicketPriority {
  String get labelFrench {
    switch (this) {
      case TicketPriority.low:
        return 'Faible';
      case TicketPriority.medium:
        return 'Moyen';
      case TicketPriority.high:
        return 'Élevé';
      case TicketPriority.critical:
        return 'Critique';
    }
  }

  Color resolveColor(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    switch (this) {
      case TicketPriority.low:
        return colors.priorityLow;
      case TicketPriority.medium:
        return colors.priorityMedium;
      case TicketPriority.high:
        return colors.priorityHigh;
      case TicketPriority.critical:
        return colors.priorityCritical;
    }
  }
}

extension TicketStatusUI on TicketStatus {
  Color resolveColor(BuildContext context, {TicketType? type}) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    switch (this) {
      case TicketStatus.open:
        return type == TicketType.anomaly
            ? colors.danger
            : colors.textSecondary;
      case TicketStatus.inProgress:
        return colors.warning;
      case TicketStatus.resolved:
        return colors.success;
    }
  }
}

extension TicketTypeUI on TicketType {
  Color resolveColor(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    switch (this) {
      case TicketType.anomaly:
        return colors.priorityCritical;
      case TicketType.preventive:
        return colors.info;
      case TicketType.corrective:
        return colors.accentSecondary;
    }
  }
}

