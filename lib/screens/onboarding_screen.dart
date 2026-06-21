import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> get _slides => [
    {
      'icon': Icons.space_dashboard_outlined,
      'title': 'Gestion Simplifiee',
      'description':
          "Suivez l'etat d'occupation, les KPIs critiques et les taches en cours d'Amarna Club en temps reel.",
      'color': Theme.of(context).extension<AppSemanticColors>()!.accentPrimary,
    },
    {
      'icon': Icons.qr_code_scanner_outlined,
      'title': 'Scanner QR & NFC',
      'description':
          'Scannez instantanement les equipements pour consulter leur historique, signaler des pannes ou lancer des taches.',
      'color': Theme.of(context).extension<AppSemanticColors>()!.pool,
    },
    {
      'icon': Icons.wifi_off_rounded,
      'title': 'Mode Hors-ligne',
      'description':
          'Travaillez sans interruption meme sans reseau. Vos modifications se synchronisent automatiquement avec Odoo ERP des reconnexion.',
      'color': Theme.of(context).extension<AppSemanticColors>()!.warning,
    },
  ];

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  void _completeOnboarding() {
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Passer',
                    style: TextStyle(
                      color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Swipeable content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 60,
                            color: slide['color'] as Color,
                          ),
                        ),
                        SizedBox(height: 40),
                        Text(
                          slide['title'] as String,
                          style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).extension<AppSemanticColors>()!.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination dots and Next/Complete button
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: 8.0),
                        height: 8.0,
                        width: isSelected ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).extension<AppSemanticColors>()!.accentPrimary
                              : Theme.of(context).extension<AppSemanticColors>()!.border,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.accentPrimary,
                      foregroundColor: Theme.of(context).extension<AppSemanticColors>()!.textOnAccent,
                      padding: EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      minimumSize: Size(
                          0, 48), // custom minimal size for onboarding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Commencer'
                          : 'Suivant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
