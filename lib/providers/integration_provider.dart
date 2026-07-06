import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/integration_status.dart';
import '../services/odoo_jsonrpc_service.dart';
import '../services/postgres_service.dart';

final integrationRefreshProvider = StateProvider<int>((ref) => 0);

final integrationSnapshotProvider =
    FutureProvider<IntegrationSnapshot>((ref) async {
  ref.watch(integrationRefreshProvider);

  final postgres = await ref.read(postgresServiceProvider).checkHealth();
  final odoo = await ref.read(odooJsonRpcServiceProvider).checkHealth();

  return IntegrationSnapshot(postgres: postgres, odoo: odoo);
});
