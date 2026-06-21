import 'dart:io';

void fixFile(String path, void Function(List<String>) fixer) {
  final file = File(path);
  if (!file.existsSync()) return;
  final lines = file.readAsLinesSync();
  fixer(lines);
  file.writeAsStringSync(lines.join('\n'));
}

void main() {
  final basePath = r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib';

  fixFile('$basePath\\screens\\onboarding_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('AppColors.', 'Theme.of(context).extension<AppSemanticColors>()!.');
      if (lines[i].contains('final List<Map<String, dynamic>> _pages = [')) {
        lines[i] = lines[i].replaceAll('final List<Map<String, dynamic>> _pages = [', 'List<Map<String, dynamic>> get _pages => [');
      }
    }
  });

  fixFile('$basePath\\widgets\\gauge_card.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      // In _GaugePainter, we don't have context, so pass color directly
      if (lines[i].contains('AppColors.surface')) {
        lines[i] = lines[i].replaceAll('AppColors.surface', 'Colors.grey.withOpacity(0.2)'); // Safe fallback
      }
      lines[i] = lines[i].replaceAll('AppColors.', 'context.colors.');
      
      if (lines[i].contains('Widget _buildStatusIndicator(String label,')) {
         lines[i] = lines[i].replaceAll('Widget _buildStatusIndicator(String label,', 'Widget _buildStatusIndicator(BuildContext context, String label,');
      }
      if (lines[i].contains('_buildStatusIndicator(') && !lines[i].contains('context')) {
         lines[i] = lines[i].replaceAll('_buildStatusIndicator(', '_buildStatusIndicator(context, ');
      }
    }
  });

  fixFile('$basePath\\screens\\activity_detail_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('AppColors.', 'Theme.of(context).extension<AppSemanticColors>()!.');
      lines[i] = lines[i].replaceAll('activity.iconData', 'resolveActivityIcon(activity.iconKey)');
      lines[i] = lines[i].replaceAll('asset.statusColor', 'asset.status.resolveColor(context)');
      lines[i] = lines[i].replaceAll('ticket.statusColor', 'ticket.status.resolveColor(context)');
      lines[i] = lines[i].replaceAll('ticket.typeColor', 'ticket.type.resolveColor(context)');

      if (lines[i].contains('Widget _buildEmptyState(IconData icon')) {
        lines[i] = lines[i].replaceAll('Widget _buildEmptyState(IconData icon', 'Widget _buildEmptyState(BuildContext context, IconData icon');
      }
      if (lines[i].contains('return _buildEmptyState(') && !lines[i].contains('context,')) {
        lines[i] = lines[i].replaceAll('return _buildEmptyState(', 'return _buildEmptyState(context, ');
      }

      // Add context to other build methods that need Theme.of(context) now
      if (lines[i].contains('Widget _buildTimeline(Activity activity)')) {
          lines[i] = lines[i].replaceAll('Widget _buildTimeline(Activity activity)', 'Widget _buildTimeline(BuildContext context, Activity activity)');
      }
      if (lines[i].contains('_buildTimeline(activity)')) {
          lines[i] = lines[i].replaceAll('_buildTimeline(activity)', '_buildTimeline(context, activity)');
      }
      
      if (lines[i].contains('Widget _buildActionSection(Activity activity)')) {
          lines[i] = lines[i].replaceAll('Widget _buildActionSection(Activity activity)', 'Widget _buildActionSection(BuildContext context, Activity activity)');
      }
      if (lines[i].contains('_buildActionSection(activity)')) {
          lines[i] = lines[i].replaceAll('_buildActionSection(activity)', '_buildActionSection(context, activity)');
      }
      
      if (lines[i].contains('Widget _buildActionButton(String title,')) {
          lines[i] = lines[i].replaceAll('Widget _buildActionButton(String title,', 'Widget _buildActionButton(BuildContext context, String title,');
      }
      if (lines[i].contains('Widget _buildActionButton(\n      String title,')) {
          lines[i] = lines[i].replaceAll('Widget _buildActionButton(\n      String title,', 'Widget _buildActionButton(BuildContext context,\n      String title,');
      }
      if (lines[i].contains('_buildActionButton(\'Ouvrir')) {
          lines[i] = lines[i].replaceAll('_buildActionButton(\'Ouvrir', '_buildActionButton(context, \'Ouvrir');
      }
      if (lines[i].contains('_buildActionButton(') && lines[i].contains('Fermer')) {
          lines[i] = lines[i].replaceAll('_buildActionButton(', '_buildActionButton(context, ');
      }
      
      // Fix const with Theme.of(context)
      lines[i] = lines[i].replaceAll('const TextStyle(', 'TextStyle(');
      lines[i] = lines[i].replaceAll('const Icon(', 'Icon(');
      lines[i] = lines[i].replaceAll('const BoxDecoration(', 'BoxDecoration(');
      lines[i] = lines[i].replaceAll('const Expanded(', 'Expanded(');
      lines[i] = lines[i].replaceAll('const SizedBox(', 'SizedBox(');
      lines[i] = lines[i].replaceAll('const Center(', 'Center(');
      lines[i] = lines[i].replaceAll('const Text(', 'Text(');
    }
  });

  fixFile('$basePath\\screens\\ticket_detail_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('AppColors.', 'Theme.of(context).extension<AppSemanticColors>()!.');
      lines[i] = lines[i].replaceAll('ticket.statusColor', 'ticket.status.resolveColor(context)');
      lines[i] = lines[i].replaceAll('ticket.typeColor', 'ticket.type.resolveColor(context)');
      
      if (lines[i].contains('Widget _buildTypeBadge(WorkTicket ticket)')) {
        lines[i] = lines[i].replaceAll('Widget _buildTypeBadge(WorkTicket ticket)', 'Widget _buildTypeBadge(BuildContext context, WorkTicket ticket)');
      }
      if (lines[i].contains('_buildTypeBadge(ticket)')) {
        lines[i] = lines[i].replaceAll('_buildTypeBadge(ticket)', '_buildTypeBadge(context, ticket)');
      }
      if (lines[i].contains('Widget _buildStatusBadge(WorkTicket ticket)')) {
        lines[i] = lines[i].replaceAll('Widget _buildStatusBadge(WorkTicket ticket)', 'Widget _buildStatusBadge(BuildContext context, WorkTicket ticket)');
      }
      if (lines[i].contains('_buildStatusBadge(ticket)')) {
        lines[i] = lines[i].replaceAll('_buildStatusBadge(ticket)', '_buildStatusBadge(context, ticket)');
      }
      if (lines[i].contains('Widget _buildTimeline(WorkTicket ticket)')) {
        lines[i] = lines[i].replaceAll('Widget _buildTimeline(WorkTicket ticket)', 'Widget _buildTimeline(BuildContext context, WorkTicket ticket)');
      }
      if (lines[i].contains('_buildTimeline(ticket)')) {
        lines[i] = lines[i].replaceAll('_buildTimeline(ticket)', '_buildTimeline(context, ticket)');
      }
      if (lines[i].contains('Widget _buildTimelineItem({')) {
        lines[i] = lines[i].replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({required BuildContext context, ');
      }
      
      // Look for _buildTimelineItem call without context
      if (lines[i].contains('_buildTimelineItem(') && !lines[i].contains('Widget')) {
         if (i+1 < lines.length && !lines[i+1].contains('context:')) {
            lines[i] = lines[i].replaceFirst('_buildTimelineItem(', '_buildTimelineItem(context: context, ');
         }
      }
      
      // Fix const
      lines[i] = lines[i].replaceAll('const TextStyle(', 'TextStyle(');
      lines[i] = lines[i].replaceAll('const Icon(', 'Icon(');
      lines[i] = lines[i].replaceAll('const BoxDecoration(', 'BoxDecoration(');
    }
  });

  print('Final safe replacements applied.');
}
