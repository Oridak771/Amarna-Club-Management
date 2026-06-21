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
        hasProblems ? AppColors.danger : AppColors.success;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé du Contrôle'),
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
            // Activity Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        activity.statusColor.withValues(alpha: 0.2),
                    child: Icon(activity.iconData,
                        color: activity.statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contrôle quotidien terminé',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overall Status Section
            Container(
              padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 8),
                  Text(
                    hasProblems
                        ? 'Des problèmes ont été signalés. L\'activité sera marquée comme fermée.'
                        : 'Aucun problème détecté. L\'activité sera marquée comme ouverte.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checklist Items list header
            const Text(
              'Détails des points contrôlés',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activityChecklists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = activityChecklists[index];
                final isProblem = item.status == ChecklistStatus.problem;

                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isProblem
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : AppColors.border,
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
                                ? AppColors.warning
                                : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isProblem &&
                          (item.comment != null || item.photoPath != null)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.comment != null &&
                                  item.comment!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.comment,
                                        color: AppColors.textSecondary,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.comment!,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.photo,
                                        color: AppColors.textSecondary,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Photo jointe',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Small preview helper
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundPrimary,
                                        borderRadius: BorderRadius.circular(4),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: const Icon(Icons.image,
                                          color: AppColors.textMuted, size: 20),
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
            const SizedBox(height: 32),

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
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, anim1, anim2) {
                      return FadeTransition(
                        opacity: anim1,
                        child: ScaleTransition(
                          scale: anim1,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
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
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Contrôle Enregistré',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Statut : $overallStatusText',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
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
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      // Pop the success dialog
                      Navigator.of(context).pop();
                      // Navigate back to Activity detail page
                      context.go('/activites/$activityId');
                    }
                  });
                },
                child: const Text(
                  'Enregistrer et Finaliser',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
