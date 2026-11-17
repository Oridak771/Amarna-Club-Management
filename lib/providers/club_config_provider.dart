import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_config.dart';
import '../models/staff_profile.dart';
import '../services/odoo_club_config_service.dart';
import '../services/odoo_staff_service.dart';

/// Club settings from Odoo. Held while the user is signed in (see
/// ClubConfigGate) and fetched again at the next sign-in.
final clubConfigProvider = FutureProvider.autoDispose<ClubConfig>((ref) {
  return ref.watch(odooClubConfigServiceProvider).fetchConfig();
});

/// Staff proposed when assigning an intervention.
final assignableStaffProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(odooStaffServiceProvider).fetchAssignableNames();
});

/// Staff card of the signed-in user (profile screen), null when not linked.
final staffProfileProvider = FutureProvider.autoDispose<StaffProfile?>((ref) {
  return ref.watch(odooStaffServiceProvider).fetchMyProfile();
});
