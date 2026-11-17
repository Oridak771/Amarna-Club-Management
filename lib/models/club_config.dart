/// Settings of the club, read from Odoo (`res.company.amarna_app_config`).
///
/// Every value comes from the server: the app keeps no copy of a price, a
/// threshold, an opening hour or a contact. Fields are required so that a
/// missing setting surfaces as an error instead of a silent default.
class ClubConfig {
  const ClubConfig({
    required this.club,
    required this.currency,
    required this.tax,
    required this.subscriptions,
    required this.tickets,
    required this.support,
    required this.horses,
    required this.pool,
    required this.reservations,
    required this.armory,
    required this.reports,
  });

  factory ClubConfig.fromMap(Map<String, dynamic> map) {
    return ClubConfig(
      club: ClubHours.fromMap(_section(map, 'club')),
      currency: CurrencyInfo.fromMap(_section(map, 'currency')),
      tax: TaxInfo.fromMap(_section(map, 'tax')),
      subscriptions: SubscriptionRules.fromMap(_section(map, 'subscriptions')),
      tickets: TicketRules.fromMap(_section(map, 'tickets')),
      support: SupportContact.fromMap(_section(map, 'support')),
      horses: HorseRules.fromMap(_section(map, 'horses')),
      pool: PoolRules.fromMap(_section(map, 'pool')),
      reservations: ReservationRules.fromMap(_section(map, 'reservations')),
      armory: ArmoryRules.fromMap(_section(map, 'armory')),
      reports: ReportRules.fromMap(_section(map, 'reports')),
    );
  }

  final ClubHours club;
  final CurrencyInfo currency;
  final TaxInfo tax;
  final SubscriptionRules subscriptions;
  final TicketRules tickets;
  final SupportContact support;
  final HorseRules horses;
  final PoolRules pool;
  final ReservationRules reservations;
  final ArmoryRules armory;
  final ReportRules reports;

  static Map<String, dynamic> _section(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Configuration du club incomplète : « $key » absent.');
  }
}

double _double(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is num) return value.toDouble();
  throw FormatException('Configuration du club : « $key » invalide.');
}

int _int(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is num) return value.toInt();
  throw FormatException('Configuration du club : « $key » invalide.');
}

String _string(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is String ? value : '';
}

/// Opening hours and the default slot, as decimal hours (9.5 = 9h30).
class ClubHours {
  const ClubHours({
    required this.name,
    required this.openingHour,
    required this.closingHour,
    required this.defaultStartHour,
    required this.defaultEndHour,
  });

  factory ClubHours.fromMap(Map<String, dynamic> map) => ClubHours(
        name: _string(map, 'name'),
        openingHour: _double(map, 'opening_hour'),
        closingHour: _double(map, 'closing_hour'),
        defaultStartHour: _double(map, 'default_start_hour'),
        defaultEndHour: _double(map, 'default_end_hour'),
      );

  final String name;
  final double openingHour;
  final double closingHour;
  final double defaultStartHour;
  final double defaultEndHour;
}

class CurrencyInfo {
  const CurrencyInfo({required this.code, required this.symbol});

  factory CurrencyInfo.fromMap(Map<String, dynamic> map) => CurrencyInfo(
        code: _string(map, 'code'),
        symbol: _string(map, 'symbol'),
      );

  final String code;
  final String symbol;
}

/// Default VAT of the club. `id` and `rate` are null when none is set.
class TaxInfo {
  const TaxInfo({required this.id, required this.name, required this.rate});

  factory TaxInfo.fromMap(Map<String, dynamic> map) => TaxInfo(
        id: map['id'] is num ? (map['id'] as num).toInt() : null,
        name: map['name'] is String ? map['name'] as String : null,
        rate: map['rate'] is num ? (map['rate'] as num).toDouble() : null,
      );

  final int? id;
  final String? name;
  final double? rate;
}

class SubscriptionRules {
  const SubscriptionRules({required this.expiryWarningDays});

  factory SubscriptionRules.fromMap(Map<String, dynamic> map) =>
      SubscriptionRules(expiryWarningDays: _int(map, 'expiry_warning_days'));

  final int expiryWarningDays;
}

class TicketRules {
  const TicketRules({required this.dueDays});

  factory TicketRules.fromMap(Map<String, dynamic> map) =>
      TicketRules(dueDays: _int(map, 'due_days'));

  final int dueDays;
}

class ReservationRules {
  const ReservationRules({required this.horizonDays, required this.defaultPeopleCount});

  factory ReservationRules.fromMap(Map<String, dynamic> map) => ReservationRules(
        horizonDays: _int(map, 'horizon_days'),
        defaultPeopleCount: _int(map, 'default_people_count'),
      );

  final int horizonDays;
  final int defaultPeopleCount;
}

class ArmoryRules {
  const ArmoryRules({required this.weaponCleaningDays});

  factory ArmoryRules.fromMap(Map<String, dynamic> map) =>
      ArmoryRules(weaponCleaningDays: _int(map, 'weapon_cleaning_days'));

  final int weaponCleaningDays;
}

/// Periods offered by the reports screen, in days.
class ReportRules {
  const ReportRules({required this.periodDays, required this.defaultDays});

  factory ReportRules.fromMap(Map<String, dynamic> map) {
    final raw = map['period_days'];
    if (raw is! List || raw.isEmpty || raw.any((day) => day is! num)) {
      throw const FormatException('Configuration du club : « period_days » invalide.');
    }
    return ReportRules(
      periodDays: raw.map((day) => (day as num).toInt()).toList(),
      defaultDays: _int(map, 'default_days'),
    );
  }

  final List<int> periodDays;
  final int defaultDays;
}

class SupportContact {
  const SupportContact({required this.phone, required this.email, required this.hours});

  factory SupportContact.fromMap(Map<String, dynamic> map) => SupportContact(
        phone: _string(map, 'phone'),
        email: _string(map, 'email'),
        hours: _string(map, 'hours'),
      );

  final String phone;
  final String email;
  final String hours;
}

class HorseRules {
  const HorseRules({
    required this.fatigueAlert,
    required this.fatigueRested,
    required this.farrierIntervalDays,
    required this.dewormingIntervalDays,
  });

  factory HorseRules.fromMap(Map<String, dynamic> map) => HorseRules(
        fatigueAlert: _double(map, 'fatigue_alert'),
        fatigueRested: _double(map, 'fatigue_rested'),
        farrierIntervalDays: _int(map, 'farrier_interval_days'),
        dewormingIntervalDays: _int(map, 'deworming_interval_days'),
      );

  final double fatigueAlert;
  final double fatigueRested;
  final int farrierIntervalDays;
  final int dewormingIntervalDays;
}

class PoolRange {
  const PoolRange({required this.min, required this.max});

  bool contains(double value) => value >= min && value <= max;

  /// Starting point for a slider: the middle of the safe range.
  double get midpoint => (min + max) / 2;

  final double min;
  final double max;
}

class PoolRules {
  const PoolRules({
    required this.temperature,
    required this.chlorine,
    required this.ph,
    required this.turbidityMax,
    required this.weightTemperature,
    required this.weightChlorine,
    required this.weightPh,
    required this.weightTurbidity,
  });

  factory PoolRules.fromMap(Map<String, dynamic> map) {
    final range = _section(map, 'temperature');
    final chlorine = _section(map, 'chlorine');
    final ph = _section(map, 'ph');
    final turbidity = _section(map, 'turbidity');
    final weights = _section(map, 'weights');
    return PoolRules(
      temperature: PoolRange(min: _double(range, 'min'), max: _double(range, 'max')),
      chlorine: PoolRange(min: _double(chlorine, 'min'), max: _double(chlorine, 'max')),
      ph: PoolRange(min: _double(ph, 'min'), max: _double(ph, 'max')),
      turbidityMax: _double(turbidity, 'max'),
      weightTemperature: _int(weights, 'temperature'),
      weightChlorine: _int(weights, 'chlorine'),
      weightPh: _int(weights, 'ph'),
      weightTurbidity: _int(weights, 'turbidity'),
    );
  }

  static Map<String, dynamic> _section(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Configuration piscine incomplète : « $key » absent.');
  }

  final PoolRange temperature;
  final PoolRange chlorine;
  final PoolRange ph;
  final double turbidityMax;
  final int weightTemperature;
  final int weightChlorine;
  final int weightPh;
  final int weightTurbidity;
}
