import 'package:flutter/material.dart';
import '../models/asset.dart';

import '../theme/app_theme.dart';
export '../theme/app_theme.dart' show AppSemanticColors;

/// UI presentation extensions for [AssetStatus].
/// Keeps models free of Flutter/color dependencies.

extension AssetStatusUI on AssetStatus {
  Color resolveColor(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    switch (this) {
      case AssetStatus.available:
        return colors.success;
      case AssetStatus.inUse:
        return colors.info;
      case AssetStatus.maintenance:
        return colors.warning;
      case AssetStatus.broken:
        return colors.danger;
    }
  }
}
