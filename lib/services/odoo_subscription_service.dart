import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/subscription.dart';
import 'odoo_jsonrpc_service.dart';

final odooSubscriptionServiceProvider =
    Provider<OdooSubscriptionService>((ref) {
  return OdooSubscriptionService(ref.watch(odooJsonRpcServiceProvider));
});

/// Reads client subscriptions (abonnements) from `amarna.subscription`.
class OdooSubscriptionService {
  OdooSubscriptionService(this._odoo);

  final OdooJsonRpcService _odoo;

  static const _model = 'amarna.subscription';
  static const _fields = [
    'name',
    'partner_id',
    'activity_id',
    'plan_id',
    'remaining_sessions',
    'is_unlimited',
    'start_date',
    'expiration_date',
    'subscription_status',
    'billing_state',
    'amount_total',
    'amount_due',
  ];

  Future<List<Subscription>> fetchSubscriptions({String query = ''}) async {
    final domain = <dynamic>[];
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      // Filter by client name or subscription reference.
      domain.addAll([
        '|',
        ['partner_id', 'ilike', trimmed],
        ['name', 'ilike', trimmed],
      ]);
    }

    final rows = await _odoo.searchRead(
      model: _model,
      domain: domain,
      fields: _fields,
      limit: 100,
      order: 'expiration_date desc',
    );

    return rows.map(Subscription.fromOdoo).toList();
  }

  // ── Writes ─────────────────────────────────────────────────

  /// Sets the remaining session counter (clamped at 0).
  Future<void> setRemainingSessions(int id, int value) {
    return _odoo.write(
      model: _model,
      id: id,
      values: {'remaining_sessions': value < 0 ? 0 : value},
    );
  }

  /// Extends / changes the expiration date.
  Future<void> setExpiration(int id, DateTime date) {
    return _odoo.write(
      model: _model,
      id: id,
      values: {'expiration_date': _fmtDate(date)},
    );
  }

  /// Updates the free-text note.
  Future<void> setNote(int id, String note) {
    return _odoo.write(model: _model, id: id, values: {'note': note});
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get isAvailable => AppEnvironment.isOdooConfigured;
}
