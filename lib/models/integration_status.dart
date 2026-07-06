enum IntegrationHealthState {
  connected,
  disconnected,
  notConfigured,
}

class IntegrationStatus {
  final String name;
  final IntegrationHealthState state;
  final String message;
  final Map<String, String> details;

  const IntegrationStatus({
    required this.name,
    required this.state,
    required this.message,
    this.details = const {},
  });

  bool get isConnected => state == IntegrationHealthState.connected;
}

class IntegrationSnapshot {
  final IntegrationStatus postgres;
  final IntegrationStatus odoo;

  const IntegrationSnapshot({
    required this.postgres,
    required this.odoo,
  });
}
