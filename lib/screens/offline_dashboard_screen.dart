import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sync_provider.dart';
import '../theme/app_theme.dart';

class OfflineDashboardScreen extends ConsumerStatefulWidget {
  const OfflineDashboardScreen({super.key});

  @override
  ConsumerState<OfflineDashboardScreen> createState() =>
      _OfflineDashboardScreenState();
}

class _OfflineDashboardScreenState
    extends ConsumerState<OfflineDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    // Auto scroll logs when new entries appear
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final String timeStr = syncState.lastSyncTime != null
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(syncState.lastSyncTime!)
        : 'Jamais';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mode Hors-ligne'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Simulation Card
            Card(
              color: context.colors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.border, width: 1.5),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          syncState.isOnline ? Icons.wifi : Icons.wifi_off,
                          color: syncState.isOnline
                              ? context.colors.success
                              : context.colors.warning,
                          size: 28,
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulation Réseau',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              syncState.isOnline
                                  ? 'Connecté (Simulation)'
                                  : 'Hors-ligne (Simulation)',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: syncState.isOnline,
                      activeThumbColor: context.colors.success,
                      activeTrackColor:
                          context.colors.success.withValues(alpha: 0.3),
                      inactiveThumbColor: context.colors.warning,
                      inactiveTrackColor:
                          context.colors.warning.withValues(alpha: 0.3),
                      onChanged: (value) {
                        ref.read(syncProvider.notifier).setOnlineStatus(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Statistics Grid (2 Columns)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Modifications',
                    '${syncState.pendingSyncCount}',
                    'En attente',
                    Icons.sync_problem,
                    syncState.pendingSyncCount > 0
                        ? context.colors.warning
                        : context.colors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Dernière Sync',
                    syncState.lastSyncTime != null
                        ? DateFormat('HH:mm').format(syncState.lastSyncTime!)
                        : 'Aucune',
                    syncState.lastSyncTime != null
                        ? 'Aujourd\'hui'
                        : 'Non synchronisé',
                    Icons.access_time,
                    context.colors.info,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Manual Sync Button
            SizedBox(
              width: double.infinity,
              height: 56, // Touch target height
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.accentPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: context.colors.surface,
                  disabledForegroundColor: context.colors.textMuted,
                ),
                icon: syncState.isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.sync),
                label: Text(
                  syncState.isSyncing
                      ? 'Synchronisation...'
                      : 'Synchroniser maintenant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: (!syncState.isOnline ||
                        syncState.isSyncing ||
                        syncState.pendingSyncCount == 0)
                    ? null
                    : () {
                        ref.read(syncProvider.notifier).triggerSync();
                      },
              ),
            ),
            SizedBox(height: 24),

            // Sync Logs Panel
            Text(
              'Journal de Synchronisation',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF070A0F), // Ultra dark terminal background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border, width: 1.5),
              ),
              padding: EdgeInsets.all(12.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: syncState.syncLogs.length,
                itemBuilder: (context, index) {
                  final log = syncState.syncLogs[index];
                  // Simple log coloring based on content
                  Color logColor = context.colors.textSecondary;
                  if (log.contains('réussie') || log.contains('rétablie')) {
                    logColor = context.colors.success;
                  } else if (log.contains('perdue') ||
                      log.contains('Hors-ligne')) {
                    logColor = context.colors.warning;
                  } else if (log.contains('Début') ||
                      log.contains('en cours')) {
                    logColor = context.colors.info;
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: logColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Dernière synchro globale : $timeStr',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.border, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
