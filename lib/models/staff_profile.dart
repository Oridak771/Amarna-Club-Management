/// Staff card of the signed-in user (Odoo: Configuration > Personnel du club).
class StaffProfile {
  const StaffProfile({
    required this.name,
    required this.role,
    required this.phone,
    required this.activities,
  });

  factory StaffProfile.fromMap(Map<String, dynamic> map) {
    final rawActivities = map['activities'];
    return StaffProfile(
      name: map['name'] is String ? map['name'] as String : '',
      role: map['role'] is String ? map['role'] as String : '',
      phone: map['phone'] is String ? map['phone'] as String : '',
      activities: rawActivities is List
          ? rawActivities
              .whereType<Map<String, dynamic>>()
              .map((a) => StaffActivity(
                    code: a['code'] is String ? a['code'] as String : '',
                    name: a['name'] is String ? a['name'] as String : '',
                  ))
              .toList()
          : const [],
    );
  }

  final String name;
  final String role;
  final String phone;
  final List<StaffActivity> activities;
}

class StaffActivity {
  const StaffActivity({required this.code, required this.name});

  final String code;
  final String name;
}
