import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double minVal;
  final double maxVal;
  final String unit;
  final double safeMin;
  final double safeMax;
  final bool isHero;

  GaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.minVal,
    required this.maxVal,
    required this.unit,
    required this.safeMin,
    required this.safeMax,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color based on safe limits
    final bool isSafe = value >= safeMin && value <= safeMax;
    final Color statusColor = isSafe ? context.colors.success : context.colors.danger;
    final String statusText = isSafe ? "Bon" : "Hors Norme";

    return Card(
      color: context.colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSafe
              ? context.colors.border
              : context.colors.danger.withValues(alpha: 0.5),
          width: isSafe ? 1 : 1.5,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isHero ? 20.0 : 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: isHero ? 14 : 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),

            // Custom Painter Gauge
            SizedBox(
              width: isHero ? 120 : 70,
              height: isHero ? 120 : 70,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: value,
                  minVal: minVal,
                  maxVal: maxVal,
                  safeMin: safeMin,
                  safeMax: safeMax,
                  gaugeColor: statusColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: isHero ? 24 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: isHero ? 12 : 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),
            // Status footer
            if (isHero) ...[
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Limites : $safeMin - $safeMax',
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minVal;
  final double maxVal;
  final double safeMin;
  final double safeMax;
  final Color gaugeColor;

  _GaugePainter({
    required this.value,
    required this.minVal,
    required this.maxVal,
    required this.safeMin,
    required this.safeMax,
    required this.gaugeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    strokeWidth = 8.0;

    // Paint for background track
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Paint for active value
    final activePaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track (270 degrees arc starting at 135 degrees)
    startAngle = 135.0 * pi / 180.0;
    sweepAngleMax = 270.0 * pi / 180.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngleMax,
      false,
      trackPaint,
    );

    // Calculate sweep angle for current value
    final double valueRatio =
        ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    final double sweepAngle = valueRatio * sweepAngleMax;

    // Draw active arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
