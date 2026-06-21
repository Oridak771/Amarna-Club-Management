// ignore_for_file: avoid_print
import 'dart:io';

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
          !f.path.contains('migrate.dart'));

  var modified = 0;

  for (final file in dartFiles) {
    var content = file.readAsStringSync();
    var original = content;

    // 1. Remove const from specific constructs that are frequently used with AppColors.
    // We use a safe replacement that doesn't mess with parentheses.
    final constPatterns = [
      'const TextStyle',
      'const BorderSide',
      'const Icon',
      'const IconThemeData',
      'const BoxDecoration',
      'const InputDecoration',
      'const EdgeInsets',
      'const Row',
      'const Column',
      'const Padding',
      'const Center',
      'const Align',
      'const Stack',
      'const Expanded',
      'const Flexible',
      'const Divider',
      'const Text',
      'const KPITile',
      'const Border',
      'const SizedBox',
      'const Container',
      'const ActivityTile',
      'const PriorityIndicator',
      'const StatusBadge',
      'const OfflineBanner',
      'const GaugeCard',
      'const LinearGradient',
      'const BoxDecoration',
    ];

    // For safety, we just remove the word "const " when it precedes any of these,
    // ONLY if the file contains AppColors.
    if (content.contains('AppColors')) {
      for (final pattern in constPatterns) {
        content = content.replaceAll(pattern, pattern.substring(6)); // remove "const "
      }
    }
    
    // We also have DropdownMenuItem
    if (content.contains('AppColors')) {
      content = content.replaceAll('const DropdownMenuItem', 'DropdownMenuItem');
    }

    // 2. Map old model getters to UI adapters
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.statusColor\b'),
      (m) => '${m.group(1)}.status.resolveColor(context)',
    );
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.priorityColor\b'),
      (m) => '${m.group(1)}.priority.resolveColor(context)',
    );
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.typeColor\b'),
      (m) => '${m.group(1)}.type.resolveColor(context)',
    );
    content = content.replaceAllMapped(
      RegExp(r'(\w+)\.iconData\b'),
      (m) => 'resolveActivityIcon(${m.group(1)}.iconKey)',
    );

    // 3. Map specific static methods
    content = content.replaceAllMapped(
      RegExp(r'AppColors\.getActivityColor\(([^)]+)\)'),
      (m) => 'resolveActivityColor(context, ${m.group(1)})',
    );
    content = content.replaceAllMapped(
      RegExp(r'AppColors\.getPriorityColor\(([^)]+)\)'),
      (m) => '${m.group(1)}.resolveColor(context)',
    );

    // 4. Map the rest of AppColors.xxx to context.colors.xxx
    content = content.replaceAll('AppColors.', 'context.colors.');

    // 5. Add UI adapter imports if needed
    if (content.contains('resolveActivityColor') || content.contains('resolveActivityIcon')) {
      if (!content.contains("activity_ui_adapter.dart'")) {
        content = "import 'package:amarna_club/ui/activity_ui_adapter.dart';\n" + content;
      }
    }
    if (content.contains('.status.resolveColor(context)') && content.contains('Asset')) {
      if (!content.contains("asset_ui_adapter.dart'")) {
        content = "import 'package:amarna_club/ui/asset_ui_adapter.dart';\n" + content;
      }
    }
    if (content.contains('priority.resolveColor') || content.contains('type.resolveColor') ||
        (content.contains('.status.resolveColor') && content.contains('Ticket'))) {
      if (!content.contains("ticket_ui_adapter.dart'")) {
        content = "import 'package:amarna_club/ui/ticket_ui_adapter.dart';\n" + content;
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
