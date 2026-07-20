/// A client subscription (abonnement) read from the Odoo `amarna.subscription`
/// model over JSON-RPC. Read-only — the mobile app surfaces it, Odoo owns it.
class Subscription {
  final int id;
  final String reference;
  final String clientName;
  final String activityName;
  final String planName;
  final int remainingSessions;
  final DateTime? startDate;
  final DateTime? expirationDate;
  final String status; // subscription_status key
  final String paymentState; // payment_state key
  final double amountTotal;

  const Subscription({
    required this.id,
    required this.reference,
    required this.clientName,
    required this.activityName,
    required this.planName,
    required this.remainingSessions,
    required this.startDate,
    required this.expirationDate,
    required this.status,
    required this.paymentState,
    required this.amountTotal,
  });

  bool get isExpired =>
      expirationDate != null &&
      expirationDate!.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));

  bool get isActive => status == 'running' || status == 'paid';

  bool get isPaid => paymentState == 'paid';

  /// Expiring within the next 7 days (and not already expired).
  bool get isExpiringSoon {
    if (expirationDate == null || isExpired) return false;
    return expirationDate!
        .isBefore(DateTime.now().add(const Duration(days: 7)));
  }

  String get statusLabelFrench {
    switch (status) {
      case 'draft':
        return 'Devis';
      case 'running':
        return 'En cours';
      case 'paid':
        return 'Payé';
      case 'closed':
        return 'Clos';
      case 'cancel':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get paymentLabelFrench {
    switch (paymentState) {
      case 'paid':
        return 'Payé';
      case 'not_paid':
        return 'Non payé';
      case 'partial':
        return 'Partiel';
      case 'in_payment':
        return 'En paiement';
      case 'reversed':
        return 'Remboursé';
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

  factory Subscription.fromOdoo(Map<String, dynamic> row) {
    final ref = row['name']?.toString() ?? '';
    return Subscription(
      id: (row['id'] as num?)?.toInt() ?? 0,
      reference: (ref.isEmpty || ref == 'New') ? 'Abonnement' : ref,
      clientName: _m2oName(row['partner_id'], fallback: 'Client inconnu'),
      activityName: _m2oName(row['activity_id'], fallback: 'Toutes activités'),
      planName: _m2oName(row['plan_id'], fallback: '—'),
      remainingSessions: (row['remaining_sessions'] as num?)?.toInt() ?? 0,
      startDate: _date(row['start_date']),
      expirationDate: _date(row['expiration_date']),
      status: row['subscription_status']?.toString() ?? '',
      paymentState: row['payment_state']?.toString() ?? '',
      amountTotal: (row['amount_total'] as num?)?.toDouble() ?? 0,
    );
  }
}
