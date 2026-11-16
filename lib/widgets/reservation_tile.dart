import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';
import '../providers/checkin_provider.dart';
import '../theme/app_theme.dart';
import '../ui/activity_ui_adapter.dart';
import 'app_layout.dart';

/// One booking: time slot, client, activity and the arrival action.
///
/// The check-in button is the only action on the row, and it is a full 48dp
/// target, so it can be hit quickly at the front desk.
class ReservationTile extends ConsumerWidget {
  const ReservationTile({
    super.key,
    required this.reservation,
    this.showActivity = true,
  });

  final Reservation reservation;

  /// Hide the activity line when the list is already grouped by activity.
  final bool showActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final checkedIn = ref.watch(checkinProvider);
    final arrived = reservation.status == ReservationStatus.checkedIn ||
        checkedIn.contains(reservation.remoteId);
    final cancelled = reservation.status == ReservationStatus.cancelled;
    final canCheckIn =
        !arrived && !cancelled && reservation.remoteId != null;
    final activityColor =
        resolveActivityColor(context, reservation.activityId);
    final start = DateFormat('HH:mm').format(reservation.startAt);
    final end = DateFormat('HH:mm').format(reservation.endAt);
    final client = reservation.clientName.isEmpty
        ? reservation.title
        : reservation.clientName;

    return Opacity(
      opacity: cancelled ? 0.55 : 1,
      child: AppPanel(
        accentColor: activityColor,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    start,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      decoration:
                          cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (showActivity && reservation.activityName.isNotEmpty)
                        reservation.activityName,
                      '${reservation.peopleCount} pers.',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (arrived)
              AppPill(
                label: 'Arrivé',
                color: colors.success,
                icon: Icons.check_rounded,
              )
            else if (canCheckIn)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => runCheckIn(
                  context,
                  ref.read(checkinProvider.notifier),
                  reservation,
                ),
                child: const Text('Arrivée'),
              )
            else
              AppPill(
                label: reservation.statusLabel,
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
