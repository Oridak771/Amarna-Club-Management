import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/sync_provider.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    var showBanner = false;
    var backgroundColor = context.colors.warning;
    var icon = Icons.cloud_off;
    var text = '';

    if (!syncState.isOnline) {
      showBanner = true;
      backgroundColor = context.colors.warning;
      icon = Icons.cloud_off;

      final timeStr = syncState.lastSyncTime != null
          ? DateFormat('HH:mm').format(syncState.lastSyncTime!)
          : 'non specifiee';

      if (syncState.pendingSyncCount > 0) {
        text =
            'Hors-ligne - ${syncState.pendingSyncCount} modification(s) en attente (Derniere synchro : $timeStr)';
      } else {
        text = 'Mode hors-ligne actif (Derniere synchro : $timeStr)';
      }
    } else if (syncState.isSyncing) {
      showBanner = true;
      backgroundColor = context.colors.info;
      icon = Icons.sync;
      text = 'Synchronisation en cours avec Odoo ERP...';
    } else if (syncState.pendingSyncCount > 0) {
      showBanner = true;
      backgroundColor = context.colors.accentSecondary;
      icon = Icons.sync_problem;
      text =
          'Modifications en attente de synchronisation (${syncState.pendingSyncCount})';
    }

    return AnimatedCrossFade(
      firstChild: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: backgroundColor,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (syncState.isSyncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
      secondChild: SizedBox.shrink(),
      crossFadeState:
          showBanner ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
    );
  }
}
