import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_layout.dart';

class HorseProfileScreen extends ConsumerWidget {
  final String id;
  const HorseProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final horse = ref.watch(horseByIdProvider(id));

    if (horse == null) {
      return const AppPage(
        title: 'Cheval introuvable',
        body: AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Ce cheval n\'existe pas.',
          message: 'Revenez à la liste de l\'écurie pour choisir un cheval.',
        ),
      );
    }

    final statusColor = switch (horse.status) {
      HorseStatus.available => colors.success,
      HorseStatus.resting => colors.warning,
      HorseStatus.injured => colors.danger,
    };

    return AppPage(
      title: horse.name,
      subtitle: '${horse.breed} · ${horse.age} ans · ${horse.boxNumber}',
      maxWidth: 860,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIdentityCard(context, horse, statusColor),
          const SizedBox(height: 14),
          _buildStatusSelector(context, ref, horse),
          if (horse.vetNote != null) ...[
            const SizedBox(height: 14),
            _buildVetNote(context, horse),
          ],
          const SizedBox(height: 14),
          _buildHealthCard(context, horse),
          const SizedBox(height: 14),
          _buildCareCard(context, horse),
          const SizedBox(height: 14),
          _buildFeedingCard(context, horse),
          const SizedBox(height: 14),
          _buildRidesCard(context, horse),
          const SizedBox(height: 22),
          _buildInjuryButton(context, ref, horse),
        ],
      ),
    );
  }

  // ── Injury shortcut (inline, not sticky: it changes the horse status) ──

  Widget _buildInjuryButton(BuildContext context, WidgetRef ref, Horse horse) {
    final colors = context.colors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.danger,
        side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed: () {
        ref
            .read(horsesProvider.notifier)
            .updateStatus(horse.id, HorseStatus.injured);
        context.go('/tickets/nouveau');
      },
      icon: const Icon(Icons.healing_outlined),
      label: Text('Signaler une blessure — ${horse.name}'),
    );
  }

  // ── Identity ───────────────────────────────────────────────

  Widget _buildIdentityCard(
      BuildContext context, Horse horse, Color statusColor) {
    return AppPanel(
      color: statusColor.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.bedroom_baby_outlined,
                size: 34, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut actuel',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AppPill(
                  label: horse.status.labelFrench,
                  color: statusColor,
                  filled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status change (functional) ─────────────────────────────

  Widget _buildStatusSelector(BuildContext context, WidgetRef ref, Horse horse) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Changer le statut',
            icon: Icons.swap_horiz_rounded,
          ),
          SegmentedButton<HorseStatus>(
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(0, 48)),
            ),
            segments: const [
              ButtonSegment(
                value: HorseStatus.available,
                label: Text('Disponible'),
                icon: Icon(Icons.check_circle_outline_rounded),
              ),
              ButtonSegment(
                value: HorseStatus.resting,
                label: Text('Au repos'),
                icon: Icon(Icons.nightlight_outlined),
              ),
              ButtonSegment(
                value: HorseStatus.injured,
                label: Text('Blessé'),
                icon: Icon(Icons.healing_outlined),
              ),
            ],
            selected: {horse.status},
            onSelectionChanged: (selection) {
              final status = selection.first;
              ref.read(horsesProvider.notifier).updateStatus(horse.id, status);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${horse.name} → ${status.labelFrench} ✓'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVetNote(BuildContext context, Horse horse) {
    final colors = context.colors;
    return AppPanel(
      color: colors.danger.withValues(alpha: 0.07),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined,
              color: colors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consigne vétérinaire',
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  horse.vetNote!,
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Health indicators ──────────────────────────────────────

  Widget _buildHealthCard(BuildContext context, Horse horse) {
    final colors = context.colors;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'État de forme',
            icon: Icons.favorite_outline_rounded,
          ),
          _gauge(context, 'Fatigue', horse.fatigue,
              horse.fatigue > 0.7 ? colors.danger : colors.horses,
              invertLabel: true),
        ],
      ),
    );
  }

  Widget _gauge(BuildContext context, String label, double value, Color color,
      {bool invertLabel = false}) {
    final colors = context.colors;
    final display = invertLabel
        ? (value <= 0.3
            ? 'Reposé'
            : value <= 0.7
                ? 'Modérée'
                : 'Élevée — repos conseillé')
        : '${(value * 100).toInt()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            Text(display,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: colors.surfaceHover,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ── Care record ────────────────────────────────────────────

  Widget _buildCareCard(BuildContext context, Horse horse) {
    final colors = context.colors;
    final dateFormat = DateFormat('dd/MM/yyyy');

    Widget row(IconData icon, String label, String value,
        {bool alert = false}) {
      final color = alert ? colors.warning : colors.textSecondary;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            ),
            Text(
              value,
              style: TextStyle(
                color: alert ? colors.warning : colors.textPrimary,
                fontSize: 14,
                fontWeight: alert ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (alert) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: colors.warning),
            ],
          ],
        ),
      );
    }

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'Carnet de soins',
            icon: Icons.menu_book_outlined,
          ),
          if (horse.nextVetVisit != null)
            row(
              Icons.medical_services_outlined,
              'Prochaine visite vétérinaire',
              DateFormat('dd/MM à HH:mm').format(horse.nextVetVisit!),
            ),
          row(
            Icons.build_outlined,
            'Maréchal-ferrant',
            dateFormat.format(horse.lastFarrier),
            alert: horse.farrierDue,
          ),
          row(
            Icons.vaccines_outlined,
            'Dernier vaccin',
            dateFormat.format(horse.lastVaccine),
          ),
          row(
            Icons.medication_outlined,
            'Dernier vermifuge',
            dateFormat.format(horse.lastDeworming),
            alert: horse.dewormingDue,
          ),
          if (horse.farrierDue || horse.dewormingDue) ...[
            const SizedBox(height: 6),
            Text(
              horse.farrierDue
                  ? 'Ferrage recommandé toutes les 6 semaines — à planifier.'
                  : 'Vermifuge recommandé tous les 3 mois — à planifier.',
              style: TextStyle(
                  color: colors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  // ── Feeding ────────────────────────────────────────────────

  Widget _buildFeedingCard(BuildContext context, Horse horse) {
    final colors = context.colors;
    return AppPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.restaurant_outlined, color: colors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alimentation',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  horse.diet,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Riding log ─────────────────────────────────────────────

  Widget _buildRidesCard(BuildContext context, Horse horse) {
    final colors = context.colors;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: 'Montes du jour',
            count: horse.ridesToday.length,
            icon: Icons.event_note_outlined,
          ),
          if (horse.ridesToday.isEmpty)
            Text(
              horse.status == HorseStatus.available
                  ? 'Aucune monte planifiée aujourd\'hui.'
                  : 'Pas de monte — ${horse.status.labelFrench.toLowerCase()}.',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            )
          else
            for (final ride in horse.ridesToday)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.horses.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ride.timeRange,
                        style: TextStyle(
                          color: colors.horses,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.label,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          Text(ride.rider,
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
