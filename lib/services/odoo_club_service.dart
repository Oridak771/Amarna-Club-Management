import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/activity.dart';
import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/work_ticket.dart';
import '../providers/horses_provider.dart';
import 'odoo_jsonrpc_service.dart';

final odooClubServiceProvider = Provider<OdooClubService>((ref) {
  return OdooClubService(ref.watch(odooJsonRpcServiceProvider));
});

/// Latest pool water-quality reading fetched from Odoo.
class PoolReading {
  final double temperature;
  final double chlorine;
  final double ph;
  final double turbidity;
  final DateTime recordedAt;

  const PoolReading({
    required this.temperature,
    required this.chlorine,
    required this.ph,
    required this.turbidity,
    required this.recordedAt,
  });
}

/// Read/write gateway to the `amarna.club.*` models of the Odoo backend
/// suite. Model and field names are fixed by the backend modules — see
/// `amarna_club_base/BACKEND_API.md` in the Odoo addons folder.
///
/// Selection keys on the Odoo side equal the Dart enum names verbatim,
/// so `enum.name` strings are pushed and parsed back with `values.byName`.
class OdooClubService {
  OdooClubService(this._odoo);

  final OdooJsonRpcService _odoo;

  bool get isConfigured => AppEnvironment.isOdooConfigured;

  // ------------------------------------------------------------ Activities

  Future<List<Activity>> fetchActivities() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.activity',
      domain: const [],
      fields: const [
        'code',
        'name',
        'icon_key',
        'mobile_status',
        'current_occupancy',
        'max_capacity',
        'assigned_staff',
      ],
      order: 'sequence asc',
    );

    return rows
        .where((row) => _str(row['code']).isNotEmpty)
        .map((row) => Activity(
              id: _str(row['code']),
              name: _str(row['name']),
              iconKey: _str(row['icon_key'], fallback: _str(row['code'])),
              status: _enumByName(
                  ActivityStatus.values, row['mobile_status'],
                  ActivityStatus.open),
              currentOccupancy: _toInt(row['current_occupancy']),
              maxCapacity: _toInt(row['max_capacity']),
              assignedStaff: _str(row['assigned_staff']),
            ))
        .toList();
  }

  Future<void> pushActivityOccupancy(String code, int occupancy) {
    return _writeByCode('amarna.club.activity', 'code', code,
        {'current_occupancy': occupancy});
  }

  Future<void> pushActivityStatus(String code, ActivityStatus status) {
    return _writeByCode(
        'amarna.club.activity', 'code', code, {'mobile_status': status.name});
  }

  // ----------------------------------------------------------------- Assets

  Future<List<Asset>> fetchAssets() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.asset',
      domain: const [],
      fields: const [
        'code',
        'name',
        'serial_number',
        'category',
        'mobile_activity_code',
        'status',
        'last_maintenance',
        'next_maintenance',
        'image_url',
        'specs_json',
      ],
      order: 'id asc',
      limit: 500,
    );

    return rows
        .where((row) => _str(row['code']).isNotEmpty)
        .map((row) => Asset(
              id: _str(row['code']),
              serialNumber: _str(row['serial_number']),
              name: _str(row['name']),
              category: _str(row['category']),
              activityId: _str(row['mobile_activity_code']),
              status: _enumByName(
                  AssetStatus.values, row['status'], AssetStatus.available),
              lastMaintenance: _dateTime(row['last_maintenance']),
              nextMaintenance: _dateTime(row['next_maintenance']),
              imageUrl:
                  _str(row['image_url']).isEmpty ? null : _str(row['image_url']),
              technicalSpecsJson: _str(row['specs_json']).isEmpty
                  ? null
                  : _str(row['specs_json']),
            ))
        .toList();
  }

  Future<void> pushAssetStatus(String code, AssetStatus status) {
    return _writeByCode(
        'amarna.club.asset', 'code', code, {'status': status.name});
  }

  /// Records a cleaning/maintenance done now (used by the armory screen).
  Future<void> pushAssetCleaned(String code) {
    return _writeByCode('amarna.club.asset', 'code', code,
        {'last_maintenance': _formatDateTime(DateTime.now())});
  }

  // -------------------------------------------------------------- Inventory

  Future<List<InventoryItem>> fetchInventory() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.inventory.item',
      domain: const [],
      fields: const [
        'code',
        'name',
        'mobile_activity_code',
        'activity_id',
        'qty',
        'low_threshold',
        'unit',
      ],
      order: 'id asc',
      limit: 500,
    );

    return rows
        .where((row) => _str(row['code']).isNotEmpty)
        .map((row) => InventoryItem(
              id: _str(row['code']),
              name: _str(row['name']),
              activityId: _str(row['mobile_activity_code']),
              activityName: _many2oneName(row['activity_id']),
              currentStock: _toInt(row['qty']),
              lowThreshold: _toInt(row['low_threshold']),
              unitName: _str(row['unit']),
            ))
        .toList();
  }

  Future<void> pushInventoryQty(String code, int qty) {
    return _writeByCode(
        'amarna.club.inventory.item', 'code', code, {'qty': qty});
  }

  // ----------------------------------------------------------------- Horses

  Future<List<Horse>> fetchHorses() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.horse',
      domain: const [],
      fields: const [
        'code',
        'name',
        'breed',
        'age',
        'box_number',
        'status',
        'fatigue',
        'diet',
        'vet_note',
        'next_vet_visit',
        'last_farrier',
        'last_vaccine',
        'last_deworming',
      ],
      order: 'box_number asc',
      limit: 200,
    );

    final fallbackDate = DateTime.now();
    return rows
        .where((row) => _str(row['code']).isNotEmpty)
        .map((row) => Horse(
              id: _str(row['code']),
              name: _str(row['name']),
              breed: _str(row['breed']),
              age: _toInt(row['age']),
              boxNumber: _str(row['box_number']),
              status: _enumByName(
                  HorseStatus.values, row['status'], HorseStatus.available),
              fatigue: _toDouble(row['fatigue']),
              diet: _str(row['diet']),
              vetNote:
                  _str(row['vet_note']).isEmpty ? null : _str(row['vet_note']),
              nextVetVisit: _dateTime(row['next_vet_visit']),
              lastFarrier: _dateTime(row['last_farrier']) ?? fallbackDate,
              lastVaccine: _dateTime(row['last_vaccine']) ?? fallbackDate,
              lastDeworming: _dateTime(row['last_deworming']) ?? fallbackDate,
            ))
        .toList();
  }

  Future<void> pushHorseStatus(String code, HorseStatus status,
      double fatigue) {
    return _writeByCode('amarna.club.horse', 'code', code,
        {'status': status.name, 'fatigue': fatigue});
  }

  // ------------------------------------------------------------------- Pool

  Future<PoolReading?> fetchLatestPoolReading() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.pool.reading',
      domain: const [],
      fields: const [
        'reading_time',
        'temperature',
        'chlorine',
        'ph',
        'turbidity',
      ],
      order: 'reading_time desc',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return PoolReading(
      temperature: _toDouble(row['temperature']),
      chlorine: _toDouble(row['chlorine']),
      ph: _toDouble(row['ph']),
      turbidity: _toDouble(row['turbidity']),
      recordedAt: _dateTime(row['reading_time']) ?? DateTime.now(),
    );
  }

  Future<int> createPoolReading({
    required double temperature,
    required double chlorine,
    required double ph,
    required double turbidity,
    String? author,
  }) {
    return _odoo.create(
      model: 'amarna.club.pool.reading',
      values: {
        'reading_time': _formatDateTime(DateTime.now()),
        'temperature': temperature,
        'chlorine': chlorine,
        'ph': ph,
        'turbidity': turbidity,
        if (author != null && author.isNotEmpty) 'author': author,
      },
    );
  }

  // ---------------------------------------------------------- Interventions

  /// Pulls interventions from Odoo mapped to local [WorkTicket]s so status
  /// changes made in the Odoo UI reach the tablet (two-way sync).
  Future<List<WorkTicket>> fetchInterventions() async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.intervention',
      domain: const [],
      fields: const [
        'mobile_id',
        'name',
        'description',
        'type',
        'status',
        'priority',
        'mobile_activity_code',
        'activity_id',
        'date_due',
        'date_completed',
        'assigned_to',
        'create_date',
      ],
      order: 'create_date desc',
      limit: 300,
    );

    return rows.map((row) {
      final mobileId = _str(row['mobile_id']);
      final id = mobileId.isNotEmpty ? mobileId : 'odoo-${row['id']}';
      var title = _str(row['name']);
      // The app prefixes pushed titles with "[<mobile id>] " — strip it.
      final prefix = '[$mobileId] ';
      if (mobileId.isNotEmpty && title.startsWith(prefix)) {
        title = title.substring(prefix.length);
      }
      return WorkTicket(
        id: id,
        title: title,
        description: _str(row['description']),
        activityId: _str(row['mobile_activity_code']),
        activityName: _many2oneName(row['activity_id'],
            fallback: _str(row['mobile_activity_code'])),
        type: _enumByName(TicketType.values, row['type'], TicketType.anomaly),
        priority: _enumByName(
            TicketPriority.values, row['priority'], TicketPriority.medium),
        status:
            _enumByName(TicketStatus.values, row['status'], TicketStatus.open),
        dateCreated: _dateTime(row['create_date']) ?? DateTime.now(),
        dateDue: _dateTime(row['date_due']),
        dateCompleted: _dateTime(row['date_completed']),
        assignedTechnician: _str(row['assigned_to']).isEmpty
            ? null
            : _str(row['assigned_to']),
      );
    }).toList();
  }

  // ---------------------------------------------------------------- Helpers

  Future<void> _writeByCode(String model, String codeField, String code,
      Map<String, dynamic> values) async {
    final rows = await _odoo.searchRead(
      model: model,
      domain: [
        [codeField, '=', code],
      ],
      fields: const ['id'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }
    await _odoo.write(
      model: model,
      id: (rows.first['id'] as num).toInt(),
      values: values,
    );
  }

  String _str(dynamic value, {String fallback = ''}) {
    // Odoo returns `false` for empty char/text fields.
    return value is String ? value : fallback;
  }

  int _toInt(dynamic value) => value is num ? value.toInt() : 0;

  double _toDouble(dynamic value) => value is num ? value.toDouble() : 0.0;

  DateTime? _dateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _many2oneName(dynamic value, {String fallback = ''}) {
    // Many2one fields come back as [id, "Display Name"].
    if (value is List && value.length >= 2 && value[1] is String) {
      return value[1] as String;
    }
    return fallback;
  }

  T _enumByName<T extends Enum>(List<T> values, dynamic name, T fallback) {
    if (name is! String) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  String _formatDateTime(DateTime value) {
    final utc = value; // Odoo stores naive datetimes; keep local like the rest
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
        '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}';
  }
}
