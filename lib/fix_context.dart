// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  // Fix ticket_detail_screen.dart
  final tDetail = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\ticket_detail_screen.dart');
  if (tDetail.existsSync()) {
    var c = tDetail.readAsStringSync();
    c = c.replaceAll('_buildTypeBadge(ticket)', '_buildTypeBadge(context, ticket)');
    c = c.replaceAll('_buildStatusBadge(ticket)', '_buildStatusBadge(context, ticket)');
    c = c.replaceAll('_buildTimeline(ticket)', '_buildTimeline(context, ticket)');
    
    c = c.replaceAll('Widget _buildTypeBadge(WorkTicket ticket)', 'Widget _buildTypeBadge(BuildContext context, WorkTicket ticket)');
    c = c.replaceAll('Widget _buildStatusBadge(WorkTicket ticket)', 'Widget _buildStatusBadge(BuildContext context, WorkTicket ticket)');
    c = c.replaceAll('Widget _buildTimeline(WorkTicket ticket)', 'Widget _buildTimeline(BuildContext context, WorkTicket ticket)');
    
    c = c.replaceAll("_buildTimelineItem(\n            title:", "_buildTimelineItem(\n            context: context,\n            title:");
    c = c.replaceAll("_buildTimelineItem(\n              title:", "_buildTimelineItem(\n              context: context,\n              title:");
    c = c.replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({\n    required BuildContext context,');
    
    tDetail.writeAsStringSync(c);
  }

  // Fix activity_detail_screen.dart
  final aDetail = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\activity_detail_screen.dart');
  if (aDetail.existsSync()) {
    var c = aDetail.readAsStringSync();
    // It has similar methods: _buildTimeline, _buildActionSection, etc.
    // I'll replace any context.colors that fails.
    c = c.replaceAll('Widget _buildTimeline(Activity activity, BuildContext context)', 'Widget _buildTimeline(BuildContext context, Activity activity)');
    c = c.replaceAll('Widget _buildTimeline(Activity activity)', 'Widget _buildTimeline(BuildContext context, Activity activity)');
    c = c.replaceAll('_buildTimeline(activity)', '_buildTimeline(context, activity)');

    c = c.replaceAll('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({\n    required BuildContext context,');
    c = c.replaceAll("_buildTimelineItem(\n            title:", "_buildTimelineItem(\n            context: context,\n            title:");
    c = c.replaceAll("_buildTimelineItem(\n              title:", "_buildTimelineItem(\n              context: context,\n              title:");

    c = c.replaceAll('Widget _buildActionSection(Activity activity)', 'Widget _buildActionSection(BuildContext context, Activity activity)');
    c = c.replaceAll('_buildActionSection(activity)', '_buildActionSection(context, activity)');

    c = c.replaceAll('Widget _buildActionButton(', 'Widget _buildActionButton(BuildContext context, ');
    c = c.replaceAll('_buildActionButton(\n', '_buildActionButton(context,\n');
    c = c.replaceAll('_buildActionButton(', '_buildActionButton(context, ');

    aDetail.writeAsStringSync(c);
  }

  // Fix plus_menu_screen.dart
  final plusMenu = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens\plus_menu_screen.dart');
  if (plusMenu.existsSync()) {
    var c = plusMenu.readAsStringSync();
    // Replace static const list with a getter taking context
    c = c.replaceAll('static const List<_PlusMenuItem> _menuItems = [', 'List<_PlusMenuItem> _getMenuItems(BuildContext context) {\n    return [');
    c = c.replaceAll('    );\n  ]', '    );\n  ];\n  }');
    c = c.replaceAll('_menuItems.length', '_getMenuItems(context).length');
    c = c.replaceAll('final item = _menuItems[index];', 'final item = _getMenuItems(context)[index];');
    plusMenu.writeAsStringSync(c);
  }

  // Fix gauge_card.dart (undefined context.colors.textSecondary)
  final gauge = File(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\widgets\gauge_card.dart');
  if (gauge.existsSync()) {
    var c = gauge.readAsStringSync();
    c = c.replaceAll('Widget _buildStatusIndicator(', 'Widget _buildStatusIndicator(BuildContext context, ');
    c = c.replaceAll('_buildStatusIndicator(', '_buildStatusIndicator(context, ');
    gauge.writeAsStringSync(c);
  }
}
