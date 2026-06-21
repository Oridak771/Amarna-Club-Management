import 'package:amarna_club/ui/activity_ui_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/activity.dart';
import '../models/checklist_item.dart';
import '../providers/activities_provider.dart';
import '../providers/checklist_provider.dart';
import '../theme/app_theme.dart';

class ChecklistSummaryScreen extends ConsumerWidget {
  final String activityId;
  const ChecklistSummaryScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    final activity = activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => Activity(
        id: activityId,
        name: 'Activité',
        iconKey: 'help',
        status: ActivityStatus.closed,
        currentOccupancy: 0,
        maxCapacity: 10,
        assignedStaff: 'Inconnu',
      ),
    );

    final allChecklists = ref.watch(checklistProvider);
    final activityChecklists =
        allChecklists.where((item) => item.activityId == activityId).toList();

    // Determine overall status
    final hasProblems = activityChecklists
        .any((item) => item.status == ChecklistStatus.problem);
    final overallStatusText =
        hasProblems ? "Activité bloquée" : "Activité ouverte";
    final overallStatusColor =
        hasProblems ? context.colors.danger : context.colors.success;

    return Scaffold(
      appBar: AppBar(
        title: Text('Résumé du Contrôle'),
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
            // Activity Header Card
            Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: context.colors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        activity.status.resolveColor(context).withValues(alpha: 0.2),
                    child: Icon(resolveActivityIcon(activity.iconKey),
                        color: activity.status.resolveColor(context), size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Contrôle quotidien terminé',
                          style: TextStyle(
                            color:
                                context.colors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Overall Status Section
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: overallStatusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: overallStatusColor, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasProblems
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: overallStatusColor,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        overallStatusText.toUpperCase(),
                        style: TextStyle(
                          color: overallStatusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    hasProblems
                        ? 'Des problèmes ont été signalés. L\'activité sera marquée comme fermée.'
                        : 'Aucun problème détecté. L\'activité sera marquée comme ouverte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Checklist Items list header
            Text(
              'Détails des points contrôlés',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activityChecklists.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = activityChecklists[index];
                final isProblem = item.status == ChecklistStatus.problem;

                return Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isProblem
                          ? context.colors.warning.withValues(alpha: 0.5)
                          : context.colors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isProblem
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                            color: isProblem
                                ? context.colors.warning
                                : context.colors.success,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isProblem &&
                          (item.comment != null || item.photoPath != null)) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.comment != null &&
                                  item.comment!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.comment,
                                        color: context.colors.textSecondary,
                                        size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.comment!,
                                        style: TextStyle(
                                          color: context.colors.textSecondary,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.photoPath != null &&
                                  item.photoPath!.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.photo,
                                        color: context.colors.textSecondary,
                                        size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Photo jointe',
                                      style: TextStyle(
                                        color: context.colors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Small preview helper
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: context.colors.backgroundPrimary,
                                        borderRadius: BorderRadius.circular(4),
                                        border:
                                            Border.all(color: context.colors.border),
                                      ),
                                      child: Icon(Icons.image,
                                          color: context.colors.textMuted, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: overallStatusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // Update activity status based on inspection results
                  final newStatus =
                      hasProblems ? ActivityStatus.closed : ActivityStatus.open;
                  ref
                      .read(activitiesProvider.notifier)
                      .updateStatus(activityId, newStatus);

                  // Show animated success dialog
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierLabel: 'Success',
                    barrierColor: Colors.black.withValues(alpha: 0.8),
                    transitionDuration: Duration(milliseconds: 300),
                    pageBuilder: (context, anim1, anim2) {
                      return FadeTransition(
                        opacity: anim1,
                        child: ScaleTransition(
                          scale: anim1,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: context.colors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.colors.border),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: overallStatusColor.withValues(
                                            alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        hasProblems ? Icons.close : Icons.check,
                                        color: overallStatusColor,
                                        size: 48,
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      'Contrôle Enregistré',
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Statut : $overallStatusText',
                                      style: TextStyle(
                                        color: context.colors.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );

                  // Auto dismiss success overlay and pop to activity details after 1.5 seconds
                  Future.delayed(Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      // Pop the success dialog
                      Navigator.of(context).pop();
                      // Navigate back to Activity detail page
                      context.go('/activites/$activityId');
                    }
                  });
                },
                child: Text(
                  'Enregistrer et Finaliser',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
