import 'dart:io';

void main() {
  // 1. ticket_detail_screen.dart
  var f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\ticket_detail_screen.dart');
  var c = f.readAsStringSync();
  c = c.replaceAll('_buildTimelineItem(\n            title:', '_buildTimelineItem(\n            context: context,\n            title:');
  c = c.replaceAll('_buildTimelineItem(\n              title:', '_buildTimelineItem(\n              context: context,\n              title:');
  f.writeAsStringSync(c);

  // 2. activity_detail_screen.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\activity_detail_screen.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('Widget _buildActionSection(Activity activity)', 'Widget _buildActionSection(BuildContext context, Activity activity)');
  c = c.replaceAll('_buildActionSection(activity)', '_buildActionSection(context, activity)');
  c = c.replaceAll('Widget _buildTimeline(Activity activity)', 'Widget _buildTimeline(BuildContext context, Activity activity)');
  c = c.replaceAll('_buildTimeline(activity)', '_buildTimeline(context, activity)');
  c = c.replaceAll('_buildTimelineItem(\n            title:', '_buildTimelineItem(\n            context: context,\n            title:');
  c = c.replaceAll('_buildTimelineItem(\n              title:', '_buildTimelineItem(\n              context: context,\n              title:');
  c = c.replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({\n    required BuildContext context,');
  c = c.replaceAll('Widget _buildActionButton(\n      String title,', 'Widget _buildActionButton(BuildContext context,\n      String title,');
  c = c.replaceAll('Widget _buildActionButton(String title,', 'Widget _buildActionButton(BuildContext context, String title,');
  c = c.replaceAll('_buildActionButton(\n                        \'Fermer', '_buildActionButton(context,\n                        \'Fermer');
  c = c.replaceAll('_buildActionButton(\'Ouvrir', '_buildActionButton(context, \'Ouvrir');
  f.writeAsStringSync(c);

  // 3. gauge_card.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\widgets\gauge_card.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('Widget _buildStatusIndicator(', 'Widget _buildStatusIndicator(BuildContext context, ');
  c = c.replaceAll('_buildStatusIndicator(', '_buildStatusIndicator(context, ');
  f.writeAsStringSync(c);

  // 4. timeline_item.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\widgets\timeline_item.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('context.colors.', 'context.colors.');
  c = c.replaceAll('TextStyle', 'TextStyle');
  c = c.replaceAll('Icon', 'Icon');
  f.writeAsStringSync(c);

  // 5. main_navigation_shell.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\main_navigation_shell.dart');
  c = f.readAsStringSync();
  c = c.replaceAll('const PlusMenuScreen()', 'PlusMenuScreen()');
  f.writeAsStringSync(c);

  // 6. onboarding_screen.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\onboarding_screen.dart');
  c = f.readAsStringSync();
  // It has a list of items using context.colors inline. Change it to be generated in build.
  c = c.replaceAll('final List<Map<String, dynamic>> _pages = [', 'List<Map<String, dynamic>> _getPages(BuildContext context) { return [');
  c = c.replaceAll('];\n\n  @override', ']; }\n\n  @override');
  c = c.replaceAll('_pages.length', '_getPages(context).length');
  c = c.replaceAll('_pages[index]', '_getPages(context)[index]');
  c = c.replaceAll('_pages[_currentPage]', '_getPages(context)[_currentPage]');
  f.writeAsStringSync(c);

  // 7. remaining invalid constants in screens
  final screenDir = Directory(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens');
  for (final file in screenDir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var original = content;
      // Strip 'const ' from specific known widgets to fix "Invalid constant value" 
      // where context.colors was added.
      content = content.replaceAll('Text(', 'Text(');
      content = content.replaceAll('TextStyle(', 'TextStyle(');
      content = content.replaceAll('Icon(', 'Icon(');
      content = content.replaceAll('Padding(', 'Padding(');
      content = content.replaceAll('Center(', 'Center(');
      content = content.replaceAll('SizedBox(', 'SizedBox(');
      content = content.replaceAll('Column(', 'Column(');
      content = content.replaceAll('Row(', 'Row(');
      content = content.replaceAll('Align(', 'Align(');
      content = content.replaceAll('Expanded(', 'Expanded(');
      content = content.replaceAll('Flexible(', 'Flexible(');
      content = content.replaceAll('Divider(', 'Divider(');
      content = content.replaceAll('LinearGradient(', 'LinearGradient(');
      content = content.replaceAll('BoxDecoration(', 'BoxDecoration(');
      content = content.replaceAll('InputDecoration(', 'InputDecoration(');
      if (content != original) {
        file.writeAsStringSync(content);
      }
    }
  }

  print('Fixes applied.');
}
