import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
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
            content: Text('Impossible de démarrer: Terrain non sécurisé.'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Terrain Paintball'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Control Card
            Card(
              color: _isSessionActive
                  ? context.colors.paintball.withValues(alpha: 0.1)
                  : context.colors.backgroundSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      _isSessionActive ? context.colors.paintball : context.colors.border,
                  width: _isSessionActive ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _isSessionActive
                          ? 'Session en cours'
                          : 'Aucune session active',
                      style: TextStyle(
                        color: _isSessionActive
                            ? context.colors.paintball
                            : context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_isSessionActive) ...[
                      Text(
                        'Joueurs sur le terrain',
                        style: TextStyle(
                            color: context.colors.textSecondary, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                size: 40),
                            color: context.colors.textMuted,
                            onPressed: _playerCount > 0
                                ? () => setState(() => _playerCount--)
                                : null,
                          ),
                          SizedBox(width: 24),
                          Text(
                            '$_playerCount / $_maxPlayers',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 24),
                          IconButton(
                            icon:
                                Icon(Icons.add_circle_outline, size: 40),
                            color: context.colors.textPrimary,
                            onPressed: _playerCount < _maxPlayers
                                ? () => setState(() => _playerCount++)
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _playerCount / _maxPlayers,
                          backgroundColor: context.colors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _playerCount >= _maxPlayers
                                ? context.colors.danger
                                : context.colors.paintball,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSessionActive
                              ? context.colors.danger
                              : context.colors.paintball,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _toggleSession,
                        child: Text(
                          _isSessionActive
                              ? 'Terminer la session'
                              : 'Démarrer une session',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Field Status Overview
            Text(
              'État des Infrastructures',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            _buildStatusToggle(
              'Filets de protection',
              _netsOk,
              Icons.grid_4x4,
              (val) {
                if (_isSessionActive) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Impossible de modifier pendant une session.')));
                  return;
                }
                setState(() => _netsOk = val);
              },
            ),
            SizedBox(height: 12),
            _buildStatusToggle(
              'Obstacles gonflables',
              _obstaclesOk,
              Icons.sports_gymnastics,
              (val) {
                if (_isSessionActive) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Impossible de modifier pendant une session.')));
                  return;
                }
                setState(() => _obstaclesOk = val);
              },
            ),

            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.warning,
                    label: 'Signaler Dégât',
                    color: context.colors.danger,
                    onTap: () => context.push('/incidents/nouveau'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.inventory,
                    label: 'Voir Lanceurs',
                    color: context.colors.info,
                    onTap: () => context.push('/activites/paintball'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(
      String label, bool isOk, IconData icon, ValueChanged<bool> onChanged) {
    return Card(
      color: context.colors.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isOk ? context.colors.border : context.colors.danger),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isOk ? context.colors.success : context.colors.danger)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isOk ? context.colors.success : context.colors.danger),
        ),
        title: Text(label,
            style: TextStyle(
                color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(isOk ? 'Sécurisé' : 'Maintenance requise',
            style: TextStyle(
                color: isOk ? context.colors.textSecondary : context.colors.danger)),
        trailing: Switch(
          value: isOk,
          onChanged: onChanged,
          activeThumbColor: context.colors.success,
          inactiveThumbColor: context.colors.danger,
          inactiveTrackColor: context.colors.danger.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
