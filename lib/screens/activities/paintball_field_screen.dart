import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity.dart';
import '../../models/safety_checkpoint.dart';
import '../../providers/activities_provider.dart';
import '../../services/odoo_club_service.dart';
import '../../services/odoo_jsonrpc_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/quick_action_button.dart';

/// Field supervision: players on the field and the control points that must be
/// in order before a session. Both come from Odoo: the player count is the
/// activity's occupancy (capacity 0 = no limit), and the control points are
/// the ones the admin defines under Configuration > Points de contrôle.
class PaintballFieldScreen extends ConsumerStatefulWidget {
  const PaintballFieldScreen({super.key, required this.activityId});

  /// Activity code from the route (`/activites/:id/...`).
  final String activityId;

  @override
  ConsumerState<PaintballFieldScreen> createState() =>
      _PaintballFieldScreenState();
}

class _PaintballFieldScreenState extends ConsumerState<PaintballFieldScreen> {
  bool _isSessionActive = false;
  bool _loadingCheckpoints = true;
  List<SafetyCheckpoint> _checkpoints = const [];

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
  }

  Activity? get _activity {
    final matches =
        ref.watch(activitiesProvider).where((a) => a.id == widget.activityId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _loadCheckpoints() async {
    final club = ref.read(odooClubServiceProvider);
    if (!club.isConfigured) {
      setState(() => _loadingCheckpoints = false);
      return;
    }
    try {
      final items = await club.fetchCheckpoints(widget.activityId);
      if (!mounted) return;
      setState(() {
        _checkpoints = items;
        _loadingCheckpoints = false;
      });
    } catch (error) {
      reportSyncIssue('Points de contrôle (lecture)', error);
      if (mounted) setState(() => _loadingCheckpoints = false);
    }
  }

  bool get _blocked =>
      _checkpoints.any((point) => point.blocksSession && !point.isOk);

  void _setPlayers(int count) {
    ref
        .read(activitiesProvider.notifier)
        .updateOccupancy(widget.activityId, count);
  }

  void _toggleSession() {
    if (!_isSessionActive && _blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Impossible de démarrer: Terrain non sécurisé.'),
            backgroundColor: context.colors.danger),
      );
      return;
    }
    setState(() => _isSessionActive = !_isSessionActive);
    if (!_isSessionActive) _setPlayers(0); // reset players on end
  }

  Future<void> _setCheckpoint(SafetyCheckpoint point, bool isOk) async {
    if (_isSessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de modifier pendant une session.')));
      return;
    }
    setState(() {
      _checkpoints = [
        for (final item in _checkpoints)
          item.id == point.id ? item.copyWith(isOk: isOk) : item,
      ];
    });
    try {
      await ref.read(odooClubServiceProvider).pushCheckpoint(point.id, isOk);
    } catch (error) {
      reportSyncIssue('Point de contrôle « ${point.name} »', error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activity = _activity;
    final players = activity?.currentOccupancy ?? 0;
    final maxPlayers = activity?.maxCapacity ?? 0; // 0 = no limit
    final canAdd = maxPlayers == 0 || players < maxPlayers;

    return AppPage(
      title: 'Terrain Paintball',
      subtitle: _isSessionActive ? 'Session en cours' : 'Aucune session active',
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: _isSessionActive ? colors.danger : colors.paintball,
          foregroundColor: colors.textOnAccent,
        ),
        onPressed: _toggleSession,
        icon: Icon(_isSessionActive
            ? Icons.stop_circle_outlined
            : Icons.play_circle_outline_rounded),
        label: Text(
          _isSessionActive ? 'Terminer la session' : 'Démarrer une session',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            padding: const EdgeInsets.all(20),
            color: _isSessionActive
                ? colors.paintball.withValues(alpha: 0.1)
                : null,
            child: Column(
              children: [
                Text(
                  _isSessionActive ? 'Session en cours' : 'Aucune session active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSessionActive
                        ? colors.paintball
                        : colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_isSessionActive) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Joueurs sur le terrain',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Retirer un joueur',
                        icon: const Icon(Icons.remove_circle_outline, size: 40),
                        color: colors.textPrimary,
                        onPressed:
                            players > 0 ? () => _setPlayers(players - 1) : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        maxPlayers == 0 ? '$players' : '$players / $maxPlayers',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Ajouter un joueur',
                        icon: const Icon(Icons.add_circle_outline, size: 40),
                        color: colors.textPrimary,
                        onPressed: canAdd ? () => _setPlayers(players + 1) : null,
                      ),
                    ],
                  ),
                  if (maxPlayers > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: players / maxPlayers,
                        backgroundColor: colors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          players >= maxPlayers
                              ? colors.danger
                              : colors.paintball,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'État des infrastructures',
            icon: Icons.fact_check_outlined,
          ),
          if (_loadingCheckpoints)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_checkpoints.isEmpty)
            const AppEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Aucun point de contrôle',
              message:
                  'Définissez-les dans Odoo (Configuration > Points de contrôle).',
            )
          else
            for (final point in _checkpoints) ...[
              _buildCheckpoint(point),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.warning,
                  label: 'Signaler Dégât',
                  color: colors.danger,
                  onTap: () => context.go('/tickets/nouveau'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.inventory,
                  label: 'Stocks',
                  color: colors.info,
                  onTap: () => context.go('/plus/inventaire'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ActivityReservationsPanel(activityId: widget.activityId),
          const SizedBox(height: 20),
          ActivityTicketsPanel(activityId: widget.activityId),
        ],
      ),
    );
  }

  Widget _buildCheckpoint(SafetyCheckpoint point) {
    final colors = context.colors;
    final tone = point.isOk ? colors.success : colors.danger;
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      color: point.isOk ? null : colors.danger.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fact_check_outlined, color: tone, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.name,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(point.isOk ? 'Conforme' : 'Maintenance requise',
                    style: TextStyle(
                        color: point.isOk ? colors.textSecondary : colors.danger,
                        fontSize: 13,
                        fontWeight:
                            point.isOk ? FontWeight.w500 : FontWeight.w700)),
              ],
            ),
          ),
          Switch(
            value: point.isOk,
            onChanged: (value) => _setCheckpoint(point, value),
            activeThumbColor: colors.success,
            inactiveThumbColor: colors.danger,
            inactiveTrackColor: colors.danger.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
