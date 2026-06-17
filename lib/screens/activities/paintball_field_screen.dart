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
        const SnackBar(content: Text('Impossible de démarrer: Terrain non sécurisé.'), backgroundColor: AppColors.danger),
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
        title: const Text('Terrain Paintball'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Control Card
            Card(
              color: _isSessionActive ? AppColors.paintball.withValues(alpha: 0.1) : AppColors.backgroundSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isSessionActive ? AppColors.paintball : AppColors.border,
                  width: _isSessionActive ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _isSessionActive ? 'Session en cours' : 'Aucune session active',
                      style: TextStyle(
                        color: _isSessionActive ? AppColors.paintball : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isSessionActive) ...[
                      const Text(
                        'Joueurs sur le terrain',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 40),
                            color: AppColors.textMuted,
                            onPressed: _playerCount > 0 ? () => setState(() => _playerCount--) : null,
                          ),
                          const SizedBox(width: 24),
                          Text(
                            '$_playerCount / $_maxPlayers',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 40),
                            color: AppColors.textPrimary,
                            onPressed: _playerCount < _maxPlayers ? () => setState(() => _playerCount++) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _playerCount / _maxPlayers,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _playerCount >= _maxPlayers ? AppColors.danger : AppColors.paintball,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSessionActive ? AppColors.danger : AppColors.paintball,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _toggleSession,
                        child: Text(
                          _isSessionActive ? 'Terminer la session' : 'Démarrer une session',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Field Status Overview
            const Text(
              'État des Infrastructures',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildStatusToggle(
              'Filets de protection',
              _netsOk,
              Icons.grid_4x4,
              (val) {
                if (_isSessionActive) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de modifier pendant une session.')));
                  return;
                }
                setState(() => _netsOk = val);
              },
            ),
            const SizedBox(height: 12),
            _buildStatusToggle(
              'Obstacles gonflables',
              _obstaclesOk,
              Icons.sports_gymnastics,
              (val) {
                if (_isSessionActive) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de modifier pendant une session.')));
                  return;
                }
                setState(() => _obstaclesOk = val);
              },
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.warning,
                    label: 'Signaler Dégât',
                    color: AppColors.danger,
                    onTap: () => context.push('/incidents/nouveau'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.inventory,
                    label: 'Voir Lanceurs',
                    color: AppColors.info,
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

  Widget _buildStatusToggle(String label, bool isOk, IconData icon, ValueChanged<bool> onChanged) {
    return Card(
      color: AppColors.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isOk ? AppColors.border : AppColors.danger),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isOk ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isOk ? AppColors.success : AppColors.danger),
        ),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(isOk ? 'Sécurisé' : 'Maintenance requise', style: TextStyle(color: isOk ? AppColors.textSecondary : AppColors.danger)),
        trailing: Switch(
          value: isOk,
          onChanged: onChanged,
          activeThumbColor: AppColors.success,
          inactiveThumbColor: AppColors.danger,
          inactiveTrackColor: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
