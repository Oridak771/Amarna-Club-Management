// Live integration test of the app's Odoo sync layer.
//
// Runs the REAL service classes (OdooJsonRpcService, OdooClubService,
// TicketSyncService) against the local Odoo backend configured in `.env`.
// Requires the Odoo server to be running; skipped otherwise.
//
//   flutter test test/odoo_sync_integration_test.dart

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:amarna_club/config/app_environment.dart';
import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/asset.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/providers/horses_provider.dart';
import 'package:amarna_club/services/odoo_club_service.dart';
import 'package:amarna_club/services/odoo_jsonrpc_service.dart';
import 'package:amarna_club/services/ticket_sync_service.dart';

Future<bool> _odooReachable() async {
  try {
    final client = HttpClient();
    final request = await client
        .getUrl(Uri.parse('${AppEnvironment.odooBaseUrl}/web/login'))
        .timeout(const Duration(seconds: 5));
    final response = await request.close();
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  // Load .env from disk (no asset bundle in the test VM).
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());

  final odoo = OdooJsonRpcService(http.Client());
  final club = OdooClubService(odoo);
  final ticketSync = TicketSyncService(odoo);

  late final bool reachable;

  setUpAll(() async {
    reachable = AppEnvironment.isOdooConfigured && await _odooReachable();
  });

  test('environment is configured for Odoo', () {
    expect(AppEnvironment.isOdooConfigured, isTrue,
        reason: '.env must contain the Odoo credentials');
  });

  test('activities: fetch and occupancy round-trip', () async {
    if (!reachable) return;
    final activities = await club.fetchActivities();
    expect(activities.length, greaterThanOrEqualTo(6));
    final pool = activities.firstWhere((a) => a.id == 'pool');
    expect(pool.maxCapacity, 60);
    expect(pool.status, isA<ActivityStatus>());

    await club.pushActivityOccupancy('pool', pool.currentOccupancy + 1);
    final after = (await club.fetchActivities())
        .firstWhere((a) => a.id == 'pool');
    expect(after.currentOccupancy, pool.currentOccupancy + 1);
    await club.pushActivityOccupancy('pool', pool.currentOccupancy);
  });

  test('assets: fetch armory and status round-trip', () async {
    if (!reachable) return;
    final assets = await club.fetchAssets();
    expect(assets.length, greaterThanOrEqualTo(12));
    final weapons = assets.where((a) =>
        a.activityId == 'shooting' &&
        a.category.toLowerCase().contains('arme'));
    expect(weapons.length, 4);

    final treadmill =
        assets.firstWhere((a) => a.id == 'asset-gym-treadmill-1');
    await club.pushAssetStatus(treadmill.id, AssetStatus.broken);
    final after = (await club.fetchAssets())
        .firstWhere((a) => a.id == treadmill.id);
    expect(after.status, AssetStatus.broken);
    await club.pushAssetStatus(treadmill.id, treadmill.status);
  });

  test('inventory: fetch and quantity round-trip', () async {
    if (!reachable) return;
    final items = await club.fetchInventory();
    expect(items.length, greaterThanOrEqualTo(9));
    final chlore = items.firstWhere((i) => i.id == 'inv-pool-01');
    expect(chlore.activityName, isNotEmpty);

    await club.pushInventoryQty(chlore.id, chlore.currentStock - 1);
    final after = (await club.fetchInventory())
        .firstWhere((i) => i.id == chlore.id);
    expect(after.currentStock, chlore.currentStock - 1);
    await club.pushInventoryQty(chlore.id, chlore.currentStock);
  });

  test('horses: fetch herd and status round-trip', () async {
    if (!reachable) return;
    final horses = await club.fetchHorses();
    expect(horses.length, greaterThanOrEqualTo(6));
    final pegase = horses.firstWhere((h) => h.id == 'h2');
    expect(pegase.farrierDue, isTrue);
    expect(pegase.dewormingDue, isTrue);

    final jumper = horses.firstWhere((h) => h.id == 'h6');
    await club.pushHorseStatus(jumper.id, HorseStatus.available, 0.0);
    final after =
        (await club.fetchHorses()).firstWhere((h) => h.id == jumper.id);
    expect(after.status, HorseStatus.available);
    await club.pushHorseStatus(jumper.id, jumper.status, jumper.fatigue);
  });

  test('pool: latest reading fetch and new reading push', () async {
    if (!reachable) return;
    final latest = await club.fetchLatestPoolReading();
    expect(latest, isNotNull);

    final id = await club.createPoolReading(
      temperature: 27.8,
      chlorine: 1.4,
      ph: 7.3,
      turbidity: 0.4,
      author: 'Test integration',
    );
    expect(id, greaterThan(0));

    final after = await club.fetchLatestPoolReading();
    expect(after!.temperature, closeTo(27.8, 0.01));
  });

  test('tickets: push, dedupe, pull back (two-way)', () async {
    if (!reachable) return;
    final mobileId = 'it-${DateTime.now().millisecondsSinceEpoch}';
    final ticket = WorkTicket(
      id: mobileId,
      title: 'Test intégration sync',
      description: 'Ticket créé par le test d\'intégration.',
      activityId: 'gym',
      activityName: 'Salle de Gym',
      type: TicketType.anomaly,
      priority: TicketPriority.high,
      status: TicketStatus.open,
      dateCreated: DateTime.now(),
      assignedTechnician: 'Amarna Mobile',
    );

    // Push (create) then push again (must dedupe into a write, not a copy).
    await ticketSync.syncTicket(ticket);
    await ticketSync.syncTicket(ticket.copyWith(
      status: TicketStatus.inProgress,
    ));

    final remote = await club.fetchInterventions();
    final matches = remote.where((t) => t.id == mobileId).toList();
    expect(matches.length, 1, reason: 'dedupe must prevent duplicates');
    expect(matches.first.status, TicketStatus.inProgress);
    expect(matches.first.activityId, 'gym');
    expect(matches.first.title, 'Test intégration sync');
  });

  test('reservations config points at the club model', () {
    expect(AppEnvironment.odooReservationModel, 'amarna.club.reservation');
    expect(AppEnvironment.odooTicketModel, 'amarna.club.intervention');
  });
}
