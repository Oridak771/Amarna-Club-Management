import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gauge_card.dart';

class PoolGaugesScreen extends StatefulWidget {
  const PoolGaugesScreen({super.key});

  @override
  State<PoolGaugesScreen> createState() => _PoolGaugesScreenState();
}

class _PoolGaugesScreenState extends State<PoolGaugesScreen> {
  // Mock values
  double _temperature = 28.5;
  double _chlorine = 1.2;
  double _ph = 7.4;
  double _turbidity = 0.5;

  double get _globalScore {
    // A mock formula for global score
    double score = 100;
    if (_temperature < 26 || _temperature > 30) score -= 20;
    if (_chlorine < 1.0 || _chlorine > 3.0) score -= 30;
    if (_ph < 7.2 || _ph > 7.6) score -= 30;
    if (_turbidity > 1.0) score -= 20;
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gauges Eau (Piscine)'),
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
            // Hero Gauge
            Center(
              child: GaugeCard(
                title: "Qualité Globale",
                value: _globalScore,
                minVal: 0,
                maxVal: 100,
                unit: "/ 100",
                safeMin: 80,
                safeMax: 100,
                isHero: true,
              ),
            ),
            SizedBox(height: 24),

            // Grid of smaller gauges
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    GaugeCard(
                      title: "Température",
                      value: _temperature,
                      minVal: 10,
                      maxVal: 40,
                      unit: "°C",
                      safeMin: 26,
                      safeMax: 30,
                    ),
                    GaugeCard(
                      title: "Chlore",
                      value: _chlorine,
                      minVal: 0,
                      maxVal: 5,
                      unit: "ppm",
                      safeMin: 1.0,
                      safeMax: 3.0,
                    ),
                    GaugeCard(
                      title: "pH",
                      value: _ph,
                      minVal: 0,
                      maxVal: 14,
                      unit: "",
                      safeMin: 7.2,
                      safeMax: 7.6,
                    ),
                    GaugeCard(
                      title: "Turbidité",
                      value: _turbidity,
                      minVal: 0,
                      maxVal: 5,
                      unit: "NTU",
                      safeMin: 0,
                      safeMax: 1.0,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 32),
            Text(
              'Ajustements Manuels (Simulation)',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSlider('Température (°C)', _temperature, 10, 40,
                (val) => setState(() => _temperature = val)),
            _buildSlider('Chlore (ppm)', _chlorine, 0, 5,
                (val) => setState(() => _chlorine = val)),
            _buildSlider('pH', _ph, 0, 14, (val) => setState(() => _ph = val)),
            _buildSlider('Turbidité (NTU)', _turbidity, 0, 5,
                (val) => setState(() => _turbidity = val)),
          ],
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
          '$label: ${value.toStringAsFixed(1)}',
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
