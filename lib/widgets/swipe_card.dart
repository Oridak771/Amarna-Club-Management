import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwipeCard extends StatelessWidget {
  final String title;
  final String category;
  final bool requiresPhoto;
  final Function(DismissDirection) onSwiped;

  const SwipeCard({
    super.key,
    required this.title,
    required this.category,
    required this.requiresPhoto,
    required this.onSwiped,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(title),
      onDismissed: onSwiped,

      // Swipe Right Background (Green - Completed)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'TERMINÉ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // Swipe Left Background (Amber - Problem)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'PROBLÈME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.warning, color: Colors.white, size: 28),
          ],
        ),
      ),

      child: Card(
        color: AppColors.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checklist title description
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (requiresPhoto)
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.info, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Photo obligatoire',
                          style: TextStyle(color: AppColors.info, fontSize: 12),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  // Helper gesture prompt
                  const Row(
                    children: [
                      Text(
                        'Glisser',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      Icon(Icons.swap_horiz,
                          color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
