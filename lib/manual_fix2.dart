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
  
  fixFile('$basePath\\screens\\activities\\gym_equipment_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('const _StatRow', '_StatRow');
      lines[i] = lines[i].replaceAll('const _buildInfoRow', '_buildInfoRow');
    }
  });

  fixFile('$basePath\\screens\\activities\\weapon_list_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('const _StatRow', '_StatRow');
    }
  });

  fixFile('$basePath\\screens\\activities_grid_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('const _StatRow', '_StatRow');
      lines[i] = lines[i].replaceAll('const _InfoChip', '_InfoChip');
      lines[i] = lines[i].replaceAll('const ActivityCard', 'ActivityCard');
    }
  });

  fixFile('$basePath\\screens\\activity_detail_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Widget _buildTimeline(BuildContext context, Activity activity)')) {
          // Already fixed
      } else if (lines[i].contains('Widget _buildTimeline(Activity activity)')) {
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
      if (lines[i].contains('_buildActionButton(\'Ouvrir')) {
          lines[i] = lines[i].replaceAll('_buildActionButton(\'Ouvrir', '_buildActionButton(context, \'Ouvrir');
      }
      if (lines[i].contains('_buildActionButton(') && lines[i].contains('Fermer')) {
          lines[i] = lines[i].replaceAll('_buildActionButton(', '_buildActionButton(context, ');
      }
      
      lines[i] = lines[i].replaceAll('const _StatRow', '_StatRow');
      lines[i] = lines[i].replaceAll('const ActivityCard', 'ActivityCard');
    }
  });

  fixFile('$basePath\\screens\\create_reservation_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('const _TimeSlotSelector', '_TimeSlotSelector');
      lines[i] = lines[i].replaceAll('const _ParticipantCounter', '_ParticipantCounter');
    }
  });

  fixFile('$basePath\\screens\\profile_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      lines[i] = lines[i].replaceAll('const _ProfileMenu', '_ProfileMenu');
      lines[i] = lines[i].replaceAll('const _StatBox', '_StatBox');
    }
  });

  fixFile('$basePath\\screens\\ticket_detail_screen.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      // Fix syntax errors introduced by previous scripts
      lines[i] = lines[i].replaceAll('context: context, context: context,', 'context: context,');
      lines[i] = lines[i].replaceAll('{required BuildContext context, \n    required BuildContext context,', '{required BuildContext context,');
      lines[i] = lines[i].replaceAll('Widget _buildTimelineItem({required BuildContext context, required BuildContext context,', 'Widget _buildTimelineItem({required BuildContext context,');
      
      if (lines[i].contains('Widget _buildTimelineItem({') && !lines[i].contains('BuildContext context')) {
        lines[i] = lines[i].replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({required BuildContext context, ');
      }
    }
  });

  fixFile('$basePath\\widgets\\gauge_card.dart', (lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Widget _buildStatusIndicator(String label,')) {
         lines[i] = lines[i].replaceAll('Widget _buildStatusIndicator(String label,', 'Widget _buildStatusIndicator(BuildContext context, String label,');
      }
      if (lines[i].contains('_buildStatusIndicator(') && !lines[i].contains('context')) {
         lines[i] = lines[i].replaceAll('_buildStatusIndicator(', '_buildStatusIndicator(context, ');
      }
    }
  });
  
  print('Manual fixes applied');
}
