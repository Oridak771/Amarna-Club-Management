import 'dart:io';

void main() {
  // ticket_detail_screen.dart
  var f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\ticket_detail_screen.dart');
  var lines = f.readAsLinesSync();
  // We know lines 486, 494, 504 have _buildTimelineItem(
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('_buildTimelineItem(')) {
       // Look ahead to see if it has context:
       if (i+1 < lines.length && !lines[i+1].contains('context:')) {
          lines[i] = lines[i].replaceFirst('_buildTimelineItem(', '_buildTimelineItem(\n            context: context,');
       }
    }
  }
  f.writeAsStringSync(lines.join('\n'));

  // activity_detail_screen.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\activity_detail_screen.dart');
  lines = f.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
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
    if (lines[i].contains('_buildActionButton(\'Ouvrir')) {
      lines[i] = lines[i].replaceAll('_buildActionButton(\'Ouvrir', '_buildActionButton(context, \'Ouvrir');
    }
    if (lines[i].contains('_buildActionButton(') && lines[i].contains('Fermer')) {
      lines[i] = lines[i].replaceAll('_buildActionButton(', '_buildActionButton(context, ');
    }
    if (lines[i].contains('Widget _buildTimelineItem({')) {
      lines[i] = lines[i].replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({required BuildContext context, ');
    }
    if (lines[i].contains('_buildTimelineItem(') && !lines[i].contains('Widget')) {
       if (i+1 < lines.length && !lines[i+1].contains('context:')) {
          lines[i] = lines[i].replaceFirst('_buildTimelineItem(', '_buildTimelineItem(context: context, ');
       }
    }
  }
  f.writeAsStringSync(lines.join('\n'));

  // main_navigation_shell.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\main_navigation_shell.dart');
  var c = f.readAsStringSync();
  c = c.replaceAll('const PlusMenuScreen()', 'PlusMenuScreen()');
  f.writeAsStringSync(c);

  // onboarding_screen.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\onboarding_screen.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('final List<Map<String, dynamic>> _pages = [', 'List<Map<String, dynamic>> get _pages => [');
  f.writeAsStringSync(c);

  // gauge_card.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\widgets\gauge_card.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('Widget _buildStatusIndicator(String label,', 'Widget _buildStatusIndicator(BuildContext context, String label,');
  c = c.replaceAll('_buildStatusIndicator(\'PH\',', '_buildStatusIndicator(context, \'PH\',');
  c = c.replaceAll('_buildStatusIndicator(\'Chlore\',', '_buildStatusIndicator(context, \'Chlore\',');
  c = c.replaceAll('_buildStatusIndicator(\'Temp.\',', '_buildStatusIndicator(context, \'Temp.\',');
  f.writeAsStringSync(c);

  // All files for invalid constants: remove "const "
  final screenDir = Directory(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens');
  for (final file in screenDir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var original = content;
      content = content.replaceAll('const EdgeInsets', 'EdgeInsets');
      content = content.replaceAll('const SliverGridDelegate', 'SliverGridDelegate');
      content = content.replaceAll('const SizedBox', 'SizedBox');
      content = content.replaceAll('const SliverPadding', 'SliverPadding');
      content = content.replaceAll('const SnackBar', 'SnackBar');
      content = content.replaceAll('const Duration', 'Duration');
      content = content.replaceAll('const AlwaysStoppedAnimation', 'AlwaysStoppedAnimation');
      content = content.replaceAll('const BoxConstraints', 'BoxConstraints');
      content = content.replaceAll('const BorderSide', 'BorderSide');
      content = content.replaceAll('const CircleBorder', 'CircleBorder');
      content = content.replaceAll('const RoundedRectangleBorder', 'RoundedRectangleBorder');
      if (content != original) {
        file.writeAsStringSync(content);
      }
    }
  }

  print('Last fixes applied.');
}
