import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/quick_action_button.dart';

class PaintballFieldScreen extends StatefulWidget {
  const PaintballFieldScreen({super.key});

  @override
  State<PaintballFieldScreen> createState() => _PaintballFieldScreenState();
}

class _PaintballFieldScreenState extends State<PaintballFieldScreen> {
  bool _isSessionActive = false;
  int _playerCount = 0;
  final int _maxPlayers = 20;

  bool _netsOk = true;
  bool _obstaclesOk = true;

  void _toggleSession() {
    if (!_netsOk || !_obstaclesOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Impossible de démarrer: Terrain non sécurisé.'),
            backgroundColor: context.colors.danger),
      );
      return;
    }

    setState(() {
      _isSessionActive = !_isSessionActive;
      if (!_isSessionActive) {
        _playerCount = 0; // reset players on end
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPage(
      title: 'Terrain Paintball',
      subtitle: _isSessionActive ? 'Session en cours' : 'Aucune session active',
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor:
              _isSessionActive ? colors.danger : colors.paintball,
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
          // Session control panel
          AppPanel(
            padding: const EdgeInsets.all(20),
            color: _isSessionActive
                ? colors.paintball.withValues(alpha: 0.1)
                : null,
            child: Column(
              children: [
                Text(
                  _isSessionActive
                      ? 'Session en cours'
                      : 'Aucune session active',
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
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Retirer un joueur',
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 40),
                        color: colors.textPrimary,
                        onPressed: _playerCount > 0
                            ? () => setState(() => _playerCount--)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_playerCount / $_maxPlayers',
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
                        onPressed: _playerCount < _maxPlayers
                            ? () => setState(() => _playerCount++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _playerCount / _maxPlayers,
                      backgroundColor: colors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _playerCount >= _maxPlayers
                            ? colors.danger
                            : colors.paintball,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Field status overview
          const SectionTitle(
            title: 'État des infrastructures',
            icon: Icons.fact_check_outlined,
          ),
          _buildStatusToggle(
            'Filets de protection',
            _netsOk,
            Icons.grid_4x4,
            (val) {
              if (_isSessionActive) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Impossible de modifier pendant une session.')));
                return;
              }
              setState(() => _netsOk = val);
            },
          ),
          const SizedBox(height: 10),
          _buildStatusToggle(
            'Obstacles gonflables',
            _obstaclesOk,
            Icons.sports_gymnastics,
            (val) {
              if (_isSessionActive) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Impossible de modifier pendant une session.')));
                return;
              }
              setState(() => _obstaclesOk = val);
            },
          ),

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
                  label: 'Stocks (billes, CO2)',
                  color: colors.info,
                  onTap: () => context.go('/plus/inventaire'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ActivityReservationsPanel(
            activityId: 'paintball',
            activityName: 'Paintball',
          ),
          const SizedBox(height: 20),
          const ActivityTicketsPanel(activityId: 'paintball'),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(
      String label, bool isOk, IconData icon, ValueChanged<bool> onChanged) {
    final colors = context.colors;
    final tone = isOk ? colors.success : colors.danger;
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      color: isOk ? null : colors.danger.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(isOk ? 'Sécurisé' : 'Maintenance requise',
                    style: TextStyle(
                        color: isOk ? colors.textSecondary : colors.danger,
                        fontSize: 13,
                        fontWeight:
                            isOk ? FontWeight.w500 : FontWeight.w700)),
              ],
            ),
          ),
          Switch(
            value: isOk,
            onChanged: onChanged,
            activeThumbColor: colors.success,
            inactiveThumbColor: colors.danger,
            inactiveTrackColor: colors.danger.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
