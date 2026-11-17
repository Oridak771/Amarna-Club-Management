import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_profile.dart';
import 'odoo_jsonrpc_service.dart';

final odooStaffServiceProvider = Provider<OdooStaffService>((ref) {
  return OdooStaffService(ref.watch(odooJsonRpcServiceProvider));
});

/// Staff the club maintains in Odoo (Configuration > Personnel du club).
class OdooStaffService {
  OdooStaffService(this._odoo);

  static const _model = 'amarna.club.staff';

  final OdooJsonRpcService _odoo;

  /// Staff card of the signed-in user, or null when the admin has not linked
  /// this account to a staff member.
  Future<StaffProfile?> fetchMyProfile() async {
    final result = await _odoo.callKw(model: _model, method: 'amarna_my_profile');
    if (result is Map<String, dynamic> && result.isNotEmpty) {
      return StaffProfile.fromMap(result);
    }
    return null;
  }

  /// Names of every active staff member, proposed when assigning an intervention.
  Future<List<String>> fetchAssignableNames() async {
    final rows = await _odoo.searchRead(
      model: _model,
      domain: [
        ['active', '=', true],
      ],
      fields: const ['name'],
      order: 'name asc',
      limit: 200,
    );
    return rows
        .map((row) => row['name'])
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }
}
