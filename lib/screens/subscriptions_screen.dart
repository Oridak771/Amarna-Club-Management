import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/app_environment.dart';
import '../models/subscription.dart';
import '../providers/subscriptions_provider.dart';
import '../services/odoo_subscription_service.dart';
import '../theme/app_theme.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(subscriptionsProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => ref
                      .read(subscriptionQueryProvider.notifier)
                      .state = value,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              ref
                                  .read(subscriptionQueryProvider.notifier)
                                  .state = '';
                            },
                          ),
                  ),
                ),
              ),
              if (!AppEnvironment.isOdooConfigured)
                Expanded(
                  child: _message(
                    context,
                    Icons.cloud_off_rounded,
                    'Odoo n\'est pas configuré.\nContactez l’administrateur.',
                  ),
                )
              else
                Expanded(
                  child: async.when(
                    data: (subs) {
                      if (subs.isEmpty) {
                        return _message(
                          context,
                          Icons.card_membership_outlined,
                          _controller.text.isEmpty
                              ? 'Aucun abonnement enregistré dans Odoo.'
                              : 'Aucun abonnement pour « ${_controller.text} ».',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: subs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _SubscriptionCard(subscription: subs[index]),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _message(
                      context,
                      Icons.error_outline_rounded,
                      'Impossible de charger les abonnements.\n$error',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
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

    final (statusColor, _) = s.isExpired
        ? (colors.danger, 'Expiré')
        : s.isActive
            ? (colors.success, s.statusLabelFrench)
            : (colors.textMuted, s.statusLabelFrench);

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
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
                  borderRadius: BorderRadius.circular(12),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.activityName} · ${s.planName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.isExpired ? 'Expiré' : s.statusLabelFrench,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                      : s.isExpiringSoon
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
          if (s.isExpiringSoon || s.remainingSessions <= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.remainingSessions <= 0
                          ? 'Séances épuisées — renouvellement conseillé.'
                          : 'Abonnement bientôt expiré.',
                      style: TextStyle(
                        color: colors.warning,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_busy || s.remainingSessions <= 0)
                      ? null
                      : _consumeSession,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Consommer une séance'),
                ),
              ),
              const SizedBox(width: 8),
              _actionIcon(
                context,
                icon: Icons.tune_rounded,
                tooltip: 'Ajuster les séances',
                onTap: _busy ? null : _adjustSessions,
              ),
              const SizedBox(width: 8),
              _actionIcon(
                context,
                icon: Icons.event_repeat_rounded,
                tooltip: 'Prolonger l\'expiration',
                onTap: _busy ? null : _extendExpiration,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(BuildContext context,
      {required IconData icon,
      required String tooltip,
      required VoidCallback? onTap}) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon,
                size: 20,
                color: onTap == null ? colors.textMuted : colors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label, String value,
      Color valueColor) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: colors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textMuted, fontSize: 10.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
