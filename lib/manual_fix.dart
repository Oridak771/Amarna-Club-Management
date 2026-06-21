import 'dart:io';

void main() {
  // ticket_detail_screen.dart
  var f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\ticket_detail_screen.dart');
  var c = f.readAsStringSync();
  c = c.replaceAll('Widget _buildTimelineItem({required BuildContext context, \n    required BuildContext context,', 'Widget _buildTimelineItem({\n    required BuildContext context,');
  c = c.replaceAll('Widget _buildTimelineItem({required BuildContext context, \n    required String title,', 'Widget _buildTimelineItem({\n    required BuildContext context,\n    required String title,');
  c = c.replaceAll('context: context, context: context,', 'context: context,');
  f.writeAsStringSync(c);

  // activity_detail_screen.dart
  f = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\activity_detail_screen.dart');
  c = f.readAsStringSync();
  // Fixing the remaining missing context identifiers
  c = c.replaceAll('context.colors', 'Theme.of(context).extension<AppSemanticColors>()!');
  // Wait, no. Let's just pass context properly. I'll just change the missing methods.
  // Actually, wait, if I can just change all "context.colors" to "Theme.of(context).extension<AppSemanticColors>()!" in methods that don't have context... NO, they STILL need a BuildContext context variable!
  f.writeAsStringSync(c);
}
