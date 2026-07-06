import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/horses_provider.dart';
import '../../theme/app_theme.dart';

class HorseProfileScreen extends ConsumerWidget {
  final String id;
  const HorseProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final horse = ref.watch(horseByIdProvider(id));

    if (horse == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cheval introuvable')),
        body: const Center(child: Text('Ce cheval n\'existe pas.')),
      );
    }

    final statusColor = switch (horse.status) {
      HorseStatus.available => colors.success,
      HorseStatus.resting => colors.warning,
      HorseStatus.injured => colors.danger,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(horse.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildIdentityCard(context, horse, statusColor),
              const SizedBox(height: 16),
              _buildStatusSelector(context, ref, horse),
              if (horse.vetNote != null) ...[
                const SizedBox(height: 16),
                _buildVetNote(context, horse),
              ],
              const SizedBox(height: 16),
              _buildHealthCard(context, horse),
              const SizedBox(height: 16),
              _buildCareCard(context, horse),
              const SizedBox(height: 16),
              _buildFeedingCard(context, horse),
              const SizedBox(height: 16),
              _buildRidesCard(context, horse),
              const SizedBox(height: 16),
              _buildInjuryButton(context, ref, horse),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Identity ───────────────────────────────────────────────

  Widget _buildIdentityCard(
      BuildContext context, Horse horse, Color statusColor) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.12),
            colors.backgroundSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.bedroom_baby_outlined,
                size: 38, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(horse.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  '${horse.breed} · ${horse.age} ans · ${horse.boxNumber}',
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    horse.status.labelFrench,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
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
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Changer le statut',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<HorseStatus>(
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined,
              color: colors.danger, size: 20),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  horse.vetNote!,
                  style: TextStyle(
                      color: colors.textPrimary, fontSize: 13, height: 1.4),
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
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('État de forme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
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
                style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text(display,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w800)),
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
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ),
            Text(
              value,
              style: TextStyle(
                color: alert ? colors.warning : colors.textPrimary,
                fontSize: 13,
                fontWeight: alert ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (alert) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded,
                  size: 15, color: colors.warning),
            ],
          ],
        ),
      );
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Carnet de soins', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
                  fontSize: 12,
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
    return _card(
      context,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_outlined,
                color: colors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alimentation',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  horse.diet,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 13),
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
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Montes du jour (${horse.ridesToday.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (horse.ridesToday.isEmpty)
            Text(
              horse.status == HorseStatus.available
                  ? 'Aucune monte planifiée aujourd\'hui.'
                  : 'Pas de monte — ${horse.status.labelFrench.toLowerCase()}.',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            )
          else
            for (final ride in horse.ridesToday)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.horses.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ride.timeRange,
                        style: TextStyle(
                          color: colors.horses,
                          fontSize: 11.5,
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
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text(ride.rider,
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
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

  // ── Injury shortcut ────────────────────────────────────────

  Widget _buildInjuryButton(BuildContext context, WidgetRef ref, Horse horse) {
    final colors = context.colors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.danger,
        side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
        minimumSize: const Size(0, 52),
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

  // ── Shared card ────────────────────────────────────────────

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
