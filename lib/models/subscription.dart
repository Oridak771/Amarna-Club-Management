/// A client subscription (abonnement) read from the Odoo `amarna.subscription`
/// model over JSON-RPC. Read-only — the mobile app surfaces it, Odoo owns it.
class Subscription {
  final int id;
  final String reference;
  final String clientName;
  final String activityName;
  final String planName;
  final int remainingSessions;

  /// Plan without a session limit (Odoo `is_unlimited`): the counter is meaningless.
  final bool isUnlimited;
  final DateTime? startDate;
  final DateTime? expirationDate;
  /// Odoo `subscription_status`: draft, active, unpaid, expired, cancelled.
  final String status;

  /// Odoo `billing_state` of the current period: free, to_invoice, unpaid,
  /// partial, paid. Driven by the invoices and payments in accounting.
  final String paymentState;
  final double amountTotal;
  final double amountDue;

  const Subscription({
    required this.id,
    required this.reference,
    required this.clientName,
    required this.activityName,
    required this.planName,
    required this.remainingSessions,
    this.isUnlimited = false,
    required this.startDate,
    required this.expirationDate,
    required this.status,
    required this.paymentState,
    required this.amountTotal,
    this.amountDue = 0,
  });

  bool get isExpired =>
      expirationDate != null &&
      expirationDate!.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));

  bool get isActive => status == 'active';

  /// Current period is free or fully paid (access is granted).
  bool get isPaid => paymentState == 'paid' || paymentState == 'free';

  /// Expiring within [warningDays] (club setting) and not already expired.
  bool isExpiringSoon(int warningDays) {
    if (expirationDate == null || isExpired) return false;
    return expirationDate!
        .isBefore(DateTime.now().add(Duration(days: warningDays)));
  }

  String get statusLabelFrench {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'active':
        return 'Actif';
      case 'unpaid':
        return 'Impayé';
      case 'expired':
        return 'Expiré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get paymentLabelFrench {
    switch (paymentState) {
      case 'free':
        return 'Gratuit';
      case 'to_invoice':
        return 'À facturer';
      case 'unpaid':
        return 'Non payé';
      case 'partial':
        return 'Partiel';
      case 'paid':
        return 'Payé';
      default:
        return paymentState;
    }
  }

  static String _m2oName(dynamic value, {String fallback = '—'}) {
    if (value is List && value.length >= 2) return value[1].toString();
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  /// Odoo returns `false` for empty selection/char fields.
  static String _text(Object? value) => value is String ? value : '';

  factory Subscription.fromOdoo(Map<String, dynamic> row) {
    final ref = row['name']?.toString() ?? '';
    return Subscription(
      id: (row['id'] as num?)?.toInt() ?? 0,
      reference: (ref.isEmpty || ref == 'New') ? 'Abonnement' : ref,
      clientName: _m2oName(row['partner_id'], fallback: 'Client inconnu'),
      activityName: _m2oName(row['activity_id'], fallback: 'Toutes activités'),
      planName: _m2oName(row['plan_id'], fallback: '—'),
      remainingSessions: (row['remaining_sessions'] as num?)?.toInt() ?? 0,
      isUnlimited: row['is_unlimited'] == true,
      startDate: _date(row['start_date']),
      expirationDate: _date(row['expiration_date']),
      status: _text(row['subscription_status']),
      paymentState: _text(row['billing_state']),
      amountTotal: (row['amount_total'] as num?)?.toDouble() ?? 0,
      amountDue: (row['amount_due'] as num?)?.toDouble() ?? 0,
    );
  }
}
