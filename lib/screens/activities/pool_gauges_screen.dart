import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/club_config.dart';
import '../../providers/club_config_provider.dart';
import '../../services/odoo_club_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_panels.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/gauge_card.dart';
import '../../services/odoo_jsonrpc_service.dart';

/// Water quality reading. Safe ranges and score penalties come from the
/// club's pool settings, passed in by the caller.
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

  bool temperatureOk(PoolRules rules) => rules.temperature.contains(temperature);
  bool chlorineOk(PoolRules rules) => rules.chlorine.contains(chlorine);
  bool phOk(PoolRules rules) => rules.ph.contains(ph);
  bool turbidityOk(PoolRules rules) => turbidity <= rules.turbidityMax;

  int issueCount(PoolRules rules) => [
        temperatureOk(rules),
        chlorineOk(rules),
        phOk(rules),
        turbidityOk(rules),
      ].where((ok) => !ok).length;

  double globalScore(PoolRules rules) {
    double score = 100;
    if (!temperatureOk(rules)) score -= rules.weightTemperature;
    if (!chlorineOk(rules)) score -= rules.weightChlorine;
    if (!phOk(rules)) score -= rules.weightPh;
    if (!turbidityOk(rules)) score -= rules.weightTurbidity;
    return score.clamp(0, 100).toDouble();
  }
}

class PoolGaugesScreen extends ConsumerStatefulWidget {
  const PoolGaugesScreen({super.key, required this.activityId});

  /// Activity code from the route (`/activites/:id/...`).
  final String activityId;


  @override
  ConsumerState<PoolGaugesScreen> createState() => _PoolGaugesScreenState();
}

class _PoolGaugesScreenState extends ConsumerState<PoolGaugesScreen> {
  /// Latest reading stored in Odoo; null until one exists.
  _Reading? _current;

  // Draft values while composing a new reading, starting in the safe ranges.
  late double _temperature;
  late double _chlorine;
  late double _ph;
  late double _turbidity;

  @override
  void initState() {
    super.initState();
    final rules = ref.read(clubConfigProvider).requireValue.pool;
    _temperature = rules.temperature.midpoint;
    _chlorine = rules.chlorine.midpoint;
    _ph = rules.ph.midpoint;
    _turbidity = rules.turbidityMax / 2;
    _loadLatestFromOdoo();
  }

  /// Loads the latest reading stored in Odoo.
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
      });
    } catch (error) {
      reportSyncIssue('Relevés piscine (lecture)', error);
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
      reportSyncIssue('Relevé piscine', error);
    }
  }

  void _saveReading() {
    final reading = _Reading(
      temperature: _temperature,
      chlorine: _chlorine,
      ph: _ph,
      turbidity: _turbidity,
      recordedAt: DateTime.now(),
    );
    setState(() => _current = reading);
    _pushReadingToOdoo(reading);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relevé enregistré ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rules = ref.watch(clubConfigProvider).requireValue.pool;
    final reading = _current;

    return AppPage(
      title: 'Piscine',
      subtitle: 'Qualité de l\'eau',
      onRefresh: _loadLatestFromOdoo,
      bottomBar: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _saveReading,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Enregistrer le relevé'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reading == null)
            const AppEmptyState(
              icon: Icons.science_outlined,
              title: 'Aucun relevé pour le moment',
              message: 'Saisissez un premier relevé ci-dessous.',
            )
          else
            _buildSummary(context, reading, rules, colors),
          const SizedBox(height: 24),

          // New reading composer
          const SectionTitle(
            title: 'Nouveau relevé',
            icon: Icons.science_outlined,
          ),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSlider('Température (°C)', _temperature, 10, 40,
                    (val) => setState(() => _temperature = val)),
                _buildSlider('Chlore (ppm)', _chlorine, 0, 5,
                    (val) => setState(() => _chlorine = val)),
                _buildSlider(
                    'pH', _ph, 0, 14, (val) => setState(() => _ph = val)),
                _buildSlider('Turbidité (NTU)', _turbidity, 0, 5,
                    (val) => setState(() => _turbidity = val)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ActivityTicketsPanel(activityId: widget.activityId),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, _Reading reading, PoolRules rules,
      AppSemanticColors colors) {
    final issues = reading.issueCount(rules);
    final conform = issues == 0;
    final statusColor = conform
        ? colors.success
        : (issues >= 2 ? colors.danger : colors.warning);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Conformity summary
        AppPanel(
          color: statusColor.withValues(alpha: 0.09),
          child: Row(
            children: [
              Icon(
                conform ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: statusColor,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conform
                          ? 'Eau conforme aux normes'
                          : '$issues paramètre${issues > 1 ? 's' : ''} hors norme',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dernier relevé : ${DateFormat('HH:mm').format(reading.recordedAt)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!conform) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => context.go('/tickets/nouveau'),
                  icon: const Icon(Icons.report_problem_rounded, size: 18),
                  label: const Text('Signaler'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hero gauge
        Center(
          child: GaugeCard(
            title: 'Qualité globale',
            value: reading.globalScore(rules),
            minVal: 0,
            maxVal: 100,
            unit: '/ 100',
            safeMin: 80,
            safeMax: 100,
            isHero: true,
          ),
        ),
        const SizedBox(height: 16),

        // Parameter gauges, safe bands from the club settings
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                GaugeCard(
                  title: 'Température',
                  value: reading.temperature,
                  minVal: 10,
                  maxVal: 40,
                  unit: '°C',
                  safeMin: rules.temperature.min,
                  safeMax: rules.temperature.max,
                ),
                GaugeCard(
                  title: 'Chlore',
                  value: reading.chlorine,
                  minVal: 0,
                  maxVal: 5,
                  unit: 'ppm',
                  safeMin: rules.chlorine.min,
                  safeMax: rules.chlorine.max,
                ),
                GaugeCard(
                  title: 'pH',
                  value: reading.ph,
                  minVal: 0,
                  maxVal: 14,
                  unit: '',
                  safeMin: rules.ph.min,
                  safeMax: rules.ph.max,
                ),
                GaugeCard(
                  title: 'Turbidité',
                  value: reading.turbidity,
                  minVal: 0,
                  maxVal: 5,
                  unit: 'NTU',
                  safeMin: 0,
                  safeMax: rules.turbidityMax,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: colors.pool,
            inactiveColor: colors.surface,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
