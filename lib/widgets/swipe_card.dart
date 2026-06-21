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
        padding: EdgeInsets.only(left: 30),
        decoration: BoxDecoration(
          color: context.colors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
        padding: EdgeInsets.only(right: 30),
        decoration: BoxDecoration(
          color: context.colors.warning,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
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
        color: context.colors.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.colors.border, width: 1.5),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category tag
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Checklist title description
              Text(
                title,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 24),

              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (requiresPhoto)
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: context.colors.info, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Photo obligatoire',
                          style: TextStyle(color: context.colors.info, fontSize: 12),
                        ),
                      ],
                    )
                  else
                    SizedBox.shrink(),

                  // Helper gesture prompt
                  Row(
                    children: [
                      Text(
                        'Glisser',
                        style:
                            TextStyle(color: context.colors.textMuted, fontSize: 11),
                      ),
                      Icon(Icons.swap_horiz,
                          color: context.colors.textMuted, size: 16),
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
