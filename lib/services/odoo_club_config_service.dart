import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_config.dart';
import 'odoo_jsonrpc_service.dart';

final odooClubConfigServiceProvider = Provider<OdooClubConfigService>((ref) {
  return OdooClubConfigService(ref.watch(odooJsonRpcServiceProvider));
});

/// Reads the club settings the admin maintains in Odoo
/// (Configuration > Club Amarna, Piscine, Écurie).
class OdooClubConfigService {
  OdooClubConfigService(this._odoo);

  final OdooJsonRpcService _odoo;

  Future<ClubConfig> fetchConfig() async {
    final result = await _odoo.callKw(
      model: 'res.company',
      method: 'amarna_app_config',
    );
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Configuration du club introuvable.');
    }
    return ClubConfig.fromMap(result);
  }
}
