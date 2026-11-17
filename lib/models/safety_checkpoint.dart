/// Pre-session control point of an activity (nets, inflatables...), defined by
/// the admin in Odoo (Configuration > Points de contrôle).
class SafetyCheckpoint {
  const SafetyCheckpoint({
    required this.id,
    required this.name,
    required this.isOk,
    required this.blocksSession,
  });

  final int id;
  final String name;
  final bool isOk;

  /// When true and not [isOk], no session may start.
  final bool blocksSession;

  SafetyCheckpoint copyWith({bool? isOk}) => SafetyCheckpoint(
        id: id,
        name: name,
        isOk: isOk ?? this.isOk,
        blocksSession: blocksSession,
      );
}
