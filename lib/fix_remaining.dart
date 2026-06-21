// ignore_for_file: avoid_print
import 'dart:io';

/// Second-pass migration: fix remaining issues after bulk AppColors→context.colors.
/// 1. Remove `const` from any widget constructor call whose argument list contains `context.colors`.
/// 2. Replace remaining `resolveActivityColor(context, ...)` with `resolveActivityColor(context, ...)`.
/// 3. Replace `resolveActivityIcon(activity.iconKey)` with `resolveActivityIcon(activity.iconKey)`.
/// 4. Replace `ticket.status.resolveColor(context)` / `ticket.priority.resolveColor(context)` / `ticket.type.resolveColor(context)`
///    with the adapter extension methods.
/// 5. Replace `asset.status.resolveColor(context)` with the adapter extension method.
void main() {
  final libDir = Directory(r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.dart') &&
          !f.path.endsWith('.g.dart') &&
          !f.path.contains('app_theme.dart') &&
          !f.path.contains('_ui_adapter.dart') &&
          !f.path.contains('fix_remaining.dart'));

  var modified = 0;

  for (final file in dartFiles) {
    var content = file.readAsStringSync();
    var original = content;

    // 1. Remove ALL `const` keywords before constructors where context.colors appears
    //    Broader approach: remove const from lines that contain context.colors on the same or nearby lines
    //    Strategy: find `const ` followed by an uppercase letter (constructor call), within 500 chars of context.colors
    //    Simpler: just remove ALL `const` before known widget constructors if the file uses context.colors
    if (content.contains('context.colors')) {
      // Remove const from TextStyle, BoxDecoration, BorderSide, Icon, IconThemeData, 
      // InputDecoration, EdgeInsets, Row, Column, etc. when the enclosing expression uses context.colors
      // Broadest safe approach: remove `const ` before widget types ONLY in files using context.colors
      content = content.replaceAll(RegExp(r'\bconst\s+(TextStyle\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(BorderSide\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(BoxDecoration\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(InputDecoration\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(IconThemeData\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(LinearGradient\()'), r'$1');
      // Icon(...) — needs to keep const if it doesn't use context.colors
      // But safe to remove since these files now all use context.colors
      content = content.replaceAll(RegExp(r'\bconst\s+(Icon\()'), r'$1');
      // SizedBox, EdgeInsets, Padding are safe to keep const (no colors)
      // Row/Column/etc. that contain children with context.colors
      // Handle by removing `const` from Container, Row, Column, Padding, Center, Stack, ClipRRect etc.
      // that precede an argument list containing context.colors
      // For safety, just remove all remaining `const ` before common widget types
      content = content.replaceAll(RegExp(r'\bconst\s+(Container\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Row\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Column\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Padding\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Center\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Align\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Stack\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Expanded\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Flexible\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Divider\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(DropdownMenuItem\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(DropdownMenuItem<)'), r'DropdownMenuItem<');
      content = content.replaceAll(RegExp(r'\bconst\s+(Text\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(KPITile\()'), r'$1');
      content = content.replaceAll(RegExp(r'\bconst\s+(Border\()'), r'$1');
    }

    // 2. Replace resolveActivityColor(context, xxx) with resolveActivityColor(context, xxx)
    content = content.replaceAllMapped(
      RegExp(r'AppColors\.getActivityColor\(([^)]+)\)'),
      (m) => 'resolveActivityColor(context, ${m.group(1)})',
    );

    // 3. Replace xxx.resolveColor(context) with priority.resolveColor(context)
    content = content.replaceAllMapped(
      RegExp(r'AppColors\.getPriorityColor\(([^)]+)\)'),
      (m) => '${m.group(1)}.resolveColor(context)',
    );

    // 4. Replace resolveActivityIcon(activity.iconKey) with resolveActivityIcon(activity.iconKey)
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.iconData\b'),
      (m) => 'resolveActivityIcon(${m.group(1)}.iconKey)',
    );

    // 5. Replace ticket/asset .statusColor with .status.resolveColor(context)
    // But only for types we know about. Simple heuristic: any .statusColor access
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.statusColor\b'),
      (m) => '${m.group(1)}.status.resolveColor(context)',
    );

    // 6. Replace ticket.priority.resolveColor(context) with ticket.priority.resolveColor(context)
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.priorityColor\b'),
      (m) => '${m.group(1)}.priority.resolveColor(context)',
    );

    // 7. Replace ticket.type.resolveColor(context) with ticket.type.resolveColor(context)
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.typeColor\b'),
      (m) => '${m.group(1)}.type.resolveColor(context)',
    );

    // 8. Fix any remaining bare AppColors references that aren't getActivityColor/getPriorityColor
    // These shouldn't exist after the first migration, but just in case
    // context.colors.xxx where xxx is a field → context.colors.xxx
    content = content.replaceAllMapped(
      RegExp(r'AppColors\.(\w+)'),
      (m) => 'context.colors.${m.group(1)}',
    );

    // 9. Add missing imports where needed
    if (content.contains('resolveActivityColor') || content.contains('resolveActivityIcon')) {
      if (!content.contains("activity_ui_adapter.dart'")) {
        // Add import after the last existing import
        final lastImport = content.lastIndexOf(RegExp(r"^import\s+'[^']+';", multiLine: true));
        if (lastImport >= 0) {
          final endOfLine = content.indexOf('\n', lastImport);
          content = content.substring(0, endOfLine + 1) +
              "import 'package:amarna_club/ui/activity_ui_adapter.dart';\n" +
              content.substring(endOfLine + 1);
        }
      }
    }

    if (content.contains('.status.resolveColor(context)') && content.contains('Asset')) {
      if (!content.contains("asset_ui_adapter.dart'")) {
        final lastImport = content.lastIndexOf(RegExp(r"^import\s+'[^']+';", multiLine: true));
        if (lastImport >= 0) {
          final endOfLine = content.indexOf('\n', lastImport);
          content = content.substring(0, endOfLine + 1) +
              "import 'package:amarna_club/ui/asset_ui_adapter.dart';\n" +
              content.substring(endOfLine + 1);
        }
      }
    }

    if (content.contains('priority.resolveColor') || content.contains('type.resolveColor') ||
        (content.contains('.status.resolveColor') && content.contains('Ticket'))) {
      if (!content.contains("ticket_ui_adapter.dart'")) {
        final lastImport = content.lastIndexOf(RegExp(r"^import\s+'[^']+';", multiLine: true));
        if (lastImport >= 0) {
          final endOfLine = content.indexOf('\n', lastImport);
          content = content.substring(0, endOfLine + 1) +
              "import 'package:amarna_club/ui/ticket_ui_adapter.dart';\n" +
              content.substring(endOfLine + 1);
        }
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      modified++;
      print('Fixed: ${file.path}');
    }
  }

  print('\nDone. Fixed $modified files.');
}
