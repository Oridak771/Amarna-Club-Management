import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/odoo_club_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/gauge_card.dart';

/// Water quality reading with per-parameter safe ranges.
class _Reading {
  final double temperature;
  final double chlorine;
  final double ph;
  final double turbidity;
  final DateTime recordedAt;

  const _Reading({
    required this.temperature,
    required this.chlorine,
    required this.ph,
    required this.turbidity,
    required this.recordedAt,
  });

  bool get temperatureOk => temperature >= 26 && temperature <= 30;
  bool get chlorineOk => chlorine >= 1.0 && chlorine <= 3.0;
  bool get phOk => ph >= 7.2 && ph <= 7.6;
  bool get turbidityOk => turbidity <= 1.0;

  int get issueCount =>
      [temperatureOk, chlorineOk, phOk, turbidityOk].where((ok) => !ok).length;

  double get globalScore {
    double score = 100;
    if (!temperatureOk) score -= 20;
    if (!chlorineOk) score -= 30;
    if (!phOk) score -= 30;
    if (!turbidityOk) score -= 20;
    return score.clamp(0, 100);
  }
}

class PoolGaugesScreen extends ConsumerStatefulWidget {
  const PoolGaugesScreen({super.key});

  @override
  ConsumerState<PoolGaugesScreen> createState() => _PoolGaugesScreenState();
}

class _PoolGaugesScreenState extends ConsumerState<PoolGaugesScreen> {
  _Reading _current = _Reading(
    temperature: 28.5,
    chlorine: 1.2,
    ph: 7.4,
    turbidity: 0.5,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 35)),
  );

  // Draft values while composing a new reading.
  late double _temperature = _current.temperature;
  late double _chlorine = _current.chlorine;
  late double _ph = _current.ph;
  late double _turbidity = _current.turbidity;

  @override
  void initState() {
    super.initState();
    _loadLatestFromOdoo();
  }

  /// Replaces the local demo reading with the latest one stored in Odoo.
  Future<void> _loadLatestFromOdoo() async {
    final club = ref.read(odooClubServiceProvider);
    if (!club.isConfigured) return;
    try {
      final latest = await club.fetchLatestPoolReading();
      if (latest == null || !mounted) return;
      setState(() {
        _current = _Reading(
          temperature: latest.temperature,
          chlorine: latest.chlorine,
          ph: latest.ph,
          turbidity: latest.turbidity,
          recordedAt: latest.recordedAt,
        );
        _temperature = _current.temperature;
        _chlorine = _current.chlorine;
        _ph = _current.ph;
        _turbidity = _current.turbidity;
      });
    } catch (error) {
      debugPrint('Odoo pool reading pull failed: $error');
    }
  }

  Future<void> _pushReadingToOdoo(_Reading reading) async {
    final club = ref.read(odooClubServiceProvider);
    if (!club.isConfigured) return;
    try {
      await club.createPoolReading(
        temperature: reading.temperature,
        chlorine: reading.chlorine,
        ph: reading.ph,
        turbidity: reading.turbidity,
      );
    } catch (error) {
      debugPrint('Odoo pool reading push failed: $error');
    }
  }

  void _saveReading() {
    setState(() {
      _current = _Reading(
        temperature: _temperature,
        chlorine: _chlorine,
        ph: _ph,
        turbidity: _turbidity,
        recordedAt: DateTime.now(),
      );
    });
    _pushReadingToOdoo(_current);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relevé enregistré ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final conform = _current.issueCount == 0;
    final statusColor = conform
        ? colors.success
        : (_current.issueCount >= 2 ? colors.danger : colors.warning);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualité de l\'eau — Piscine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Conformity summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      conform
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conform
                                ? 'Eau conforme aux normes'
                                : '${_current.issueCount} paramètre${_current.issueCount > 1 ? 's' : ''} hors norme',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dernier relevé : ${DateFormat('HH:mm').format(_current.recordedAt)}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!conform)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.go('/tickets/nouveau'),
                        icon: const Icon(Icons.report_problem_rounded,
                            size: 18),
                        label: const Text('Signaler'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hero gauge
              Center(
                child: GaugeCard(
                  title: 'Qualité Globale',
                  value: _current.globalScore,
                  minVal: 0,
                  maxVal: 100,
                  unit: '/ 100',
                  safeMin: 80,
                  safeMax: 100,
                  isHero: true,
                ),
              ),
              const SizedBox(height: 20),

              // Parameter gauges
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      GaugeCard(
                        title: 'Température',
                        value: _current.temperature,
                        minVal: 10,
                        maxVal: 40,
                        unit: '°C',
                        safeMin: 26,
                        safeMax: 30,
                      ),
                      GaugeCard(
                        title: 'Chlore',
                        value: _current.chlorine,
                        minVal: 0,
                        maxVal: 5,
                        unit: 'ppm',
                        safeMin: 1.0,
                        safeMax: 3.0,
                      ),
                      GaugeCard(
                        title: 'pH',
                        value: _current.ph,
                        minVal: 0,
                        maxVal: 14,
                        unit: '',
                        safeMin: 7.2,
                        safeMax: 7.6,
                      ),
                      GaugeCard(
                        title: 'Turbidité',
                        value: _current.turbidity,
                        minVal: 0,
                        maxVal: 5,
                        unit: 'NTU',
                        safeMin: 0,
                        safeMax: 1.0,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // New reading composer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Nouveau relevé',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildSlider('Température (°C)', _temperature, 10, 40,
                        (val) => setState(() => _temperature = val)),
                    _buildSlider('Chlore (ppm)', _chlorine, 0, 5,
                        (val) => setState(() => _chlorine = val)),
                    _buildSlider(
                        'pH', _ph, 0, 14, (val) => setState(() => _ph = val)),
                    _buildSlider('Turbidité (NTU)', _turbidity, 0, 5,
                        (val) => setState(() => _turbidity = val)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _saveReading,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Enregistrer le relevé'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const ActivityTicketsPanel(activityId: 'pool'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ${value.toStringAsFixed(1)}',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: context.colors.pool,
          inactiveColor: context.colors.surface,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
