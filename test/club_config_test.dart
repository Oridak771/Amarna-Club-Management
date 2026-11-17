import 'package:flutter_test/flutter_test.dart';

import 'package:amarna_club/models/club_config.dart';

/// Same shape as `res.company.amarna_app_config()` on the Odoo side.
Map<String, dynamic> _payload() => {
      'club': {
        'name': 'Club test',
        'opening_hour': 9.0,
        'closing_hour': 22.0,
        'default_start_hour': 9.5,
        'default_end_hour': 10.5,
      },
      'currency': {'code': 'DZD', 'symbol': 'DA'},
      'tax': {'id': 7, 'name': 'TVA 19 %', 'rate': 19.0},
      'subscriptions': {'expiry_warning_days': 7},
      'tickets': {'due_days': 3},
      'reservations': {'horizon_days': 365, 'default_people_count': 1},
      'support': {'phone': '0550', 'email': 'aide@club.test', 'hours': 'de 8h à 20h'},
      'armory': {'weapon_cleaning_days': 7},
      'reports': {'period_days': [7, 30, 90, 365], 'default_days': 30},
      'horses': {
        'fatigue_alert': 0.7,
        'fatigue_rested': 0.3,
        'farrier_interval_days': 42,
        'deworming_interval_days': 90,
      },
      'pool': {
        'temperature': {'min': 26.0, 'max': 30.0},
        'chlorine': {'min': 1.0, 'max': 3.0},
        'ph': {'min': 7.2, 'max': 7.6},
        'turbidity': {'max': 1.0},
        'weights': {'temperature': 20, 'chlorine': 30, 'ph': 30, 'turbidity': 20},
      },
    };

void main() {
  test('parses every section of the Odoo payload', () {
    final config = ClubConfig.fromMap(_payload());

    expect(config.club.defaultStartHour, 9.5);
    expect(config.club.closingHour, 22.0);
    expect(config.currency.symbol, 'DA');
    expect(config.tax.id, 7);
    expect(config.tax.rate, 19.0);
    expect(config.subscriptions.expiryWarningDays, 7);
    expect(config.tickets.dueDays, 3);
    expect(config.reservations.horizonDays, 365);
    expect(config.reservations.defaultPeopleCount, 1);
    expect(config.support.phone, '0550');
    expect(config.armory.weaponCleaningDays, 7);
    expect(config.horses.fatigueAlert, 0.7);
    expect(config.horses.farrierIntervalDays, 42);
    expect(config.horses.fatigueRested, 0.3);
    expect(config.reports.periodDays, [7, 30, 90, 365]);
    expect(config.reports.defaultDays, 30);
    expect(config.pool.chlorine.contains(2.0), isTrue);
    expect(config.pool.chlorine.contains(3.5), isFalse);
    expect(config.pool.weightChlorine, 30);
  });

  test('a missing tax is null, not zero', () {
    final map = _payload()
      ..['tax'] = {'id': null, 'name': null, 'rate': null};
    final config = ClubConfig.fromMap(map);
    expect(config.tax.id, isNull);
    expect(config.tax.rate, isNull);
  });

  test('a missing section fails loudly instead of using a default', () {
    final map = _payload()..remove('pool');
    expect(() => ClubConfig.fromMap(map), throwsA(isA<FormatException>()));
  });

  test('a missing number fails loudly', () {
    final map = _payload();
    (map['horses'] as Map<String, dynamic>).remove('fatigue_alert');
    expect(() => ClubConfig.fromMap(map), throwsA(isA<FormatException>()));
  });

  test('pool midpoint starts a slider inside the safe range', () {
    final config = ClubConfig.fromMap(_payload());
    expect(config.pool.temperature.midpoint, 28.0);
    expect(config.pool.temperature.contains(config.pool.temperature.midpoint), isTrue);
  });
}
