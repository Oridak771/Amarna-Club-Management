import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Animated loading splash: dual rotating arcs orbit a pulsing gold emblem
/// while staged status messages play, then the app routes to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // one-shot entrance
  late final AnimationController _spin; // repeating orbit + pulse

  static const _stages = [
    'Initialisation…',
    'Connexion au serveur…',
    'Préparation de votre journée…',
  ];
  int _stageIndex = 0;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Advance status messages, then leave.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _stageIndex = 1);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _stageIndex = 2);
    });
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emblem with orbiting arcs
                AnimatedBuilder(
                  animation: _spin,
                  builder: (context, _) {
                    final pulse =
                        0.5 + 0.5 * math.sin(_spin.value * 2 * math.pi);
                    return SizedBox(
                      width: 148,
                      height: 148,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft breathing halo
                          Container(
                            width: 120 + 14 * pulse,
                            height: 120 + 14 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.accentSecondary
                                  .withValues(alpha: 0.05 + 0.05 * pulse),
                            ),
                          ),
                          // Rotating arcs
                          CustomPaint(
                            size: const Size(148, 148),
                            painter: _OrbitsPainter(
                              progress: _spin.value,
                              primary: colors.accentPrimary,
                              secondary: colors.accentSecondary,
                            ),
                          ),
                          // Gold emblem core
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.accentSecondary
                                      .withValues(alpha: 0.25),
                                  colors.accentSecondary
                                      .withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: colors.accentSecondary
                                    .withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.temple_hindu_rounded,
                              size: 38,
                              color: colors.accentSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'AMARNA CLUB',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opérations en temps réel',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 44),
                // Staged status message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _stages[_stageIndex],
                    key: ValueKey(_stageIndex),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Thin progress line
                SizedBox(
                  width: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 2600),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: colors.surfaceHover,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colors.accentPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two arcs rotating in opposite directions around the emblem.
class _OrbitsPainter extends CustomPainter {
  const _OrbitsPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = progress * 2 * math.pi;

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = primary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 4),
      angle,
      math.pi * 0.55,
      false,
      outer,
    );

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = secondary.withValues(alpha: 0.85);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 16),
      -angle * 1.4,
      math.pi * 0.4,
      false,
      inner,
    );
  }

  @override
  bool shouldRepaint(_OrbitsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
