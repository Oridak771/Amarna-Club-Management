import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/activity.dart';
import '../models/asset.dart';
import '../models/safety_checkpoint.dart';
import '../models/inventory_item.dart';
import '../models/work_ticket.dart';
import '../providers/horses_provider.dart';
import 'odoo_datetime.dart';
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

/// Read/write gateway to the `amarna.club.*` models of the Odoo backend.
///
/// Field and model names are defined by the `amarna_club_*` addons in the
/// Odoo repository. Selection keys on the Odoo side equal the Dart enum names
/// (`enum.name`), and every Datetime crosses this boundary in UTC (see
/// `odoo_datetime.dart`).
class OdooClubService {
  OdooClubService(this._odoo);

  final OdooJsonRpcService _odoo;

  bool get isConfigured => AppEnvironment.isOdooConfigured;

  /// Date used for records Odoo has no value for: far in the past, so that
  /// "no date recorded" is shown (and alerted) as overdue rather than fresh.
  static final DateTime neverDate = DateTime.fromMillisecondsSinceEpoch(0);

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
        'mobile_screen',
        'mobile_screen_label',
        'closure_start',
        'closure_end',
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
              screenKey: _str(row['mobile_screen']),
              screenLabel: _str(row['mobile_screen_label']),
              closureStart: fromOdooDateTime(row['closure_start']),
              closureEnd: fromOdooDateTime(row['closure_end']),
            ))
        .toList();
  }

  Future<void> pushActivityOccupancy(String code, int occupancy) {
    return _writeByCode('amarna.club.activity', code,
        {'current_occupancy': occupancy});
  }

  Future<void> pushActivityStatus(String code, ActivityStatus status) {
    return _writeByCode(
        'amarna.club.activity', code, {'mobile_status': status.name});
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
        'in_use_since',
        'is_weapon',
        'image_url',
        'specs_json',
      ],
      order: 'id asc',
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
              lastMaintenance: fromOdooDateTime(row['last_maintenance']),
              nextMaintenance: fromOdooDateTime(row['next_maintenance']),
              inUseSince: fromOdooDateTime(row['in_use_since']),
              isWeapon: row['is_weapon'] == true,
              imageUrl:
                  _str(row['image_url']).isEmpty ? null : _str(row['image_url']),
              technicalSpecsJson: _str(row['specs_json']).isEmpty
                  ? null
                  : _str(row['specs_json']),
            ))
        .toList();
  }

  Future<void> pushAssetStatus(String code, AssetStatus status) {
    return _writeByCode('amarna.club.asset', code, {'status': status.name});
  }

  /// Records a cleaning/maintenance done now (used by the armory screen).
  Future<void> pushAssetCleaned(String code) {
    return _writeByCode('amarna.club.asset', code,
        {'last_maintenance': toOdooDateTime(DateTime.now())});
  }

  // ------------------------------------------------------------ Checkpoints

  /// Control points of an activity, in the order the admin set.
  Future<List<SafetyCheckpoint>> fetchCheckpoints(String activityCode) async {
    final rows = await _odoo.searchRead(
      model: 'amarna.club.checkpoint',
      domain: [
        ['mobile_activity_code', '=', activityCode],
      ],
      fields: const ['name', 'is_ok', 'blocks_session'],
      order: 'sequence asc, id asc',
    );
    return rows
        .map((row) => SafetyCheckpoint(
              id: (row['id'] as num).toInt(),
              name: _str(row['name']),
              isOk: row['is_ok'] == true,
              blocksSession: row['blocks_session'] == true,
            ))
        .toList();
  }

  Future<void> pushCheckpoint(int id, bool isOk) async {
    await _odoo.write(
      model: 'amarna.club.checkpoint',
      id: id,
      values: {'is_ok': isOk},
    );
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
    return _writeByCode('amarna.club.inventory.item', code, {'qty': qty});
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
    );

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
              nextVetVisit: fromOdooDateTime(row['next_vet_visit']),
              lastFarrier: fromOdooDate(row['last_farrier']) ?? neverDate,
              lastVaccine: fromOdooDate(row['last_vaccine']) ?? neverDate,
              lastDeworming: fromOdooDate(row['last_deworming']) ?? neverDate,
            ))
        .toList();
  }

  Future<void> pushHorseStatus(String code, HorseStatus status,
      double fatigue) {
    return _writeByCode('amarna.club.horse', code,
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
      recordedAt: fromOdooDateTime(row['reading_time']) ?? DateTime.now(),
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
        'reading_time': toOdooDateTime(DateTime.now()),
        'temperature': temperature,
        'chlorine': chlorine,
        'ph': ph,
        'turbidity': turbidity,
        if (author != null && author.isNotEmpty) 'author': author,
      },
    );
  }

  // ---------------------------------------------------------- Interventions

  /// Pulls the interventions from Odoo as [WorkTicket]s.
  ///
  /// A ticket created in the tablet has its `mobile_id` as id. A ticket
  /// created in the Odoo back office has no `mobile_id` and gets an
  /// `odoo-<id>` identifier, so the tablet can write changes back to it.
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
        'mobile_asset_code',
        'asset_id',
        'date_due',
        'date_completed',
        'assigned_to',
        'create_date',
      ],
      order: 'create_date desc',
      limit: 1000,
    );

    return rows.map((row) {
      final mobileId = _str(row['mobile_id']);
      final id = mobileId.isNotEmpty ? mobileId : 'odoo-${row['id']}';
      final activityCode = _str(row['mobile_activity_code']);
      final assetCode = _str(row['mobile_asset_code']);
      final assigned = _str(row['assigned_to']);
      return WorkTicket(
        id: id,
        title: _str(row['name']),
        description: _str(row['description']),
        activityId: activityCode,
        activityName:
            _many2oneName(row['activity_id'], fallback: activityCode),
        assetId: assetCode.isEmpty ? null : assetCode,
        assetName: _many2oneName(row['asset_id']).isEmpty
            ? null
            : _many2oneName(row['asset_id']),
        type: _enumByName(TicketType.values, row['type'], TicketType.anomaly),
        priority: _enumByName(
            TicketPriority.values, row['priority'], TicketPriority.medium),
        status:
            _enumByName(TicketStatus.values, row['status'], TicketStatus.open),
        dateCreated: fromOdooDateTime(row['create_date']) ?? DateTime.now(),
        dateDue: fromOdooDateTime(row['date_due']),
        dateCompleted: fromOdooDateTime(row['date_completed']),
        assignedTechnician: assigned.isEmpty ? null : assigned,
      );
    }).toList();
  }

  // ---------------------------------------------------------------- Helpers

  /// Writes [values] to the record whose `code` is [code].
  /// Throws when the record does not exist in Odoo, so the failure is visible.
  Future<void> _writeByCode(
      String model, String code, Map<String, dynamic> values) async {
    final rows = await _odoo.searchRead(
      model: model,
      domain: [
        ['code', '=', code],
      ],
      fields: const ['id'],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Élément « $code » introuvable dans Odoo ($model).');
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

  String _many2oneName(dynamic value, {String fallback = ''}) {
    // Many2one fields come back as [id, "Display Name"], or false when empty.
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
}
