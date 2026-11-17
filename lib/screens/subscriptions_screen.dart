import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_environment.dart';
import '../models/subscription.dart';
import '../providers/club_config_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../services/odoo_subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

/// Abonnements — front-desk lookup of client subscriptions from Odoo.
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscriptionsProvider);

    return AppPage(
      title: 'Abonnements',
      subtitle: 'Séances et échéances des clients',
      scrollable: true,
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualiser',
          onPressed: () => ref.invalidate(subscriptionsProvider),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (value) => ref
                .read(subscriptionQueryProvider.notifier)
                .state = value,
            decoration: InputDecoration(
              hintText: 'Rechercher un client…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        ref.read(subscriptionQueryProvider.notifier).state =
                            '';
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: !AppEnvironment.isOdooConfigured
                ? ListView(
                    children: const [
                      AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Odoo n\'est pas configuré.',
                        message: 'Contactez l\'administrateur.',
                      ),
                    ],
                  )
                : async.when(
                    data: (subs) {
                      if (subs.isEmpty) {
                        return ListView(
                          children: [
                            AppEmptyState(
                              icon: Icons.card_membership_outlined,
                              title: _controller.text.isEmpty
                                  ? 'Aucun abonnement enregistré'
                                  : 'Aucun abonnement trouvé',
                              message: _controller.text.isEmpty
                                  ? 'Aucun abonnement n\'est enregistré dans Odoo.'
                                  : 'Aucun abonnement pour « ${_controller.text} ».',
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: subs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _SubscriptionCard(subscription: subs[index]),
                      );
                    },
                    loading: () => ListView(
                      children: const [
                        AppLoadingState(
                            message: 'Chargement des abonnements…'),
                      ],
                    ),
                    error: (error, _) => ListView(
                      children: [
                        AppErrorState(
                          title: 'Impossible de charger les abonnements',
                          message: '$error',
                          onRetry: () => ref.invalidate(subscriptionsProvider),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerStatefulWidget {
  const _SubscriptionCard({required this.subscription});

  final Subscription subscription;

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _busy = false;

  OdooSubscriptionService get _service =>
      ref.read(odooSubscriptionServiceProvider);

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(subscriptionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(okMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'écriture Odoo : $error'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _consumeSession() {
    final s = widget.subscription;
    return _run(
      () => _service.setRemainingSessions(s.id, s.remainingSessions - 1),
      'Séance décomptée — ${s.remainingSessions - 1} restante(s) ✓',
    );
  }

  Future<void> _adjustSessions() async {
    final s = widget.subscription;
    final controller =
        TextEditingController(text: '${s.remainingSessions}');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajuster les séances'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Séances restantes'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (value != null) {
      await _run(() => _service.setRemainingSessions(s.id, value),
          'Séances mises à jour : $value ✓');
    }
  }

  Future<void> _extendExpiration() async {
    final s = widget.subscription;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: s.expirationDate != null && s.expirationDate!.isAfter(now)
          ? s.expirationDate!
          : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Nouvelle date d\'expiration',
    );
    if (picked != null) {
      await _run(() => _service.setExpiration(s.id, picked),
          'Expiration prolongée ✓');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = widget.subscription;
    final expiryWarningDays =
        ref.watch(clubConfigProvider).requireValue.subscriptions.expiryWarningDays;

    final statusColor = s.isExpired
        ? colors.danger
        : s.isActive
            ? colors.success
            : colors.textMuted;

    final dateFormat = DateFormat('dd/MM/yyyy');

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.card_membership_rounded,
                    color: colors.accentSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.activityName} · ${s.planName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppPill(
                label: s.isExpired ? 'Expiré' : s.statusLabelFrench,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _stat(
                  context,
                  Icons.confirmation_number_outlined,
                  'Séances restantes',
                  '${s.remainingSessions}',
                  s.remainingSessions <= 0 ? colors.danger : colors.textPrimary,
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  Icons.event_busy_outlined,
                  'Expiration',
                  s.expirationDate != null
                      ? dateFormat.format(s.expirationDate!)
                      : '—',
                  s.isExpired
                      ? colors.danger
                      : s.isExpiringSoon(expiryWarningDays)
                          ? colors.warning
                          : colors.textPrimary,
                ),
              ),
              Expanded(
                child: _stat(
                  context,
                  Icons.payments_outlined,
                  'Paiement',
                  s.paymentLabelFrench,
                  s.isPaid ? colors.success : colors.warning,
                ),
              ),
            ],
          ),
          if (s.isExpiringSoon(expiryWarningDays) || s.remainingSessions <= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.remainingSessions <= 0
                          ? 'Séances épuisées — renouvellement conseillé.'
                          : 'Abonnement bientôt expiré.',
                      style: TextStyle(
                        color: colors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_busy || s.remainingSessions <= 0)
                      ? null
                      : _consumeSession,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: const Text('Consommer une séance'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Ajuster les séances',
                onPressed: _busy ? null : _adjustSessions,
                icon: const Icon(Icons.tune_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Prolonger l\'expiration',
                onPressed: _busy ? null : _extendExpiration,
                icon: const Icon(Icons.event_repeat_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label, String value,
      Color valueColor) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
