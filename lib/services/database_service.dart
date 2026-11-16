import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/work_ticket.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar database has not been initialized');
});

/// Local cache of the tablet.
///
/// Activities, assets and inventory are mirrors of Odoo and are reloaded at
/// every start. Tickets are kept while they wait to be pushed; the others are
/// mirrors too. The cache holds no demo data: an earlier build seeded sample
/// activities, assets and tickets, which are purged once here.
class DatabaseService {
  static const _cacheVersion = '2';
  static const _cacheVersionFile = 'amarna_cache_version';

  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ActivitySchema,
        AssetSchema,
        WorkTicketSchema,
        InventoryItemSchema,
      ],
      directory: dir.path,
    );

    final marker = File('${dir.path}/$_cacheVersionFile');
    final upToDate =
        marker.existsSync() && marker.readAsStringSync().trim() == _cacheVersion;
    if (!upToDate) {
      await isar.writeTxn(() async {
        await isar.activitys.clear();
        await isar.assets.clear();
        await isar.inventoryItems.clear();
        // Keep tickets that still have to reach Odoo; drop the other ones.
        await isar.workTickets.filter().syncPendingEqualTo(false).deleteAll();
      });
      marker.writeAsStringSync(_cacheVersion);
    }

    return isar;
  }
}
