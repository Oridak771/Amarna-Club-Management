// End-to-end flows on a device or emulator, against the real Odoo server.
//
//   flutter test integration_test/staff_flow_test.dart -d emulator-5554 \
//     --dart-define-from-file=config/dart_define.local.json \
//     --dart-define=AMARNA_TEST_LOGIN=<staff login> \
//     --dart-define=AMARNA_TEST_PASSWORD=<staff password>
//
// The account must be a staff account, not an administrator: the tests show
// what a tablet user can see and do. Records created here are named "TEST".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:amarna_club/main.dart';
import 'package:amarna_club/models/reservation.dart';
import 'package:amarna_club/services/database_service.dart';
import 'package:amarna_club/services/odoo_club_service.dart';
import 'package:amarna_club/services/odoo_jsonrpc_service.dart';
import 'package:amarna_club/services/odoo_reservation_service.dart';

const _login = String.fromEnvironment('AMARNA_TEST_LOGIN');
const _password = String.fromEnvironment('AMARNA_TEST_PASSWORD');

/// On failure, print what the screen shows so the run can be diagnosed.
void _logVisibleText(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
  debugPrint('VISIBLE TEXT: ${texts.take(120).join(' | ')}');
}

/// Pumps frames until [finder] matches, or fails after [timeout].
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
  required String reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (!tester.any(finder)) {
    if (DateTime.now().isAfter(end)) {
      _logVisibleText(tester);
      fail('Timed out waiting for $reason');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Isar? _isar;

/// Types [text] into the text field whose hint is [hint].
Future<void> _enter(WidgetTester tester, String hint, String text) async {
  final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);
  await _waitFor(tester, field, reason: 'field "$hint"');
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 300));
  final typed = tester
      .widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)))
      .controller
      .text;
  expect(typed, text, reason: 'text typed into "$hint"');
}

/// Scrolls [finder] into view, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Starts the app and signs the staff account in; returns on the home screen.
Future<void> _signIn(WidgetTester tester) async {
  expect(_login, isNotEmpty, reason: 'AMARNA_TEST_LOGIN is required');
  expect(_password, isNotEmpty, reason: 'AMARNA_TEST_PASSWORD is required');

  await initializeDateFormatting('fr_FR');
  // Isar can be opened only once per process: share it between tests.
  final isar = _isar ??= await DatabaseService.init();
  await tester.pumpWidget(ProviderScope(
    overrides: [isarProvider.overrideWithValue(isar)],
    child: const AmarnaClubApp(),
  ));

  await _waitFor(tester, find.text('Connexion'), reason: 'login screen');
  await _enter(tester, 'Entrez votre identifiant', _login);
  await _enter(tester, 'Entrez votre mot de passe', _password);
  await _tap(tester, find.text('Connexion'));
  await _waitFor(tester, find.text('Ma journée'),
      timeout: const Duration(seconds: 60), reason: 'home screen after login');
}

/// The same Odoo session the app uses, for checking what reached the server.
Future<OdooJsonRpcService> _serverSession() async {
  final rpc = OdooJsonRpcService(http.Client());
  await rpc.authenticate(_login, _password);
  return rpc;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('staff signs in and the home screen shows Odoo data',
      (tester) async {
    await _signIn(tester);

    await _waitFor(tester, find.textContaining('activités ouvertes'),
        reason: 'activity summary from Odoo');
    await _waitFor(tester, find.textContaining('Piscine'),
        reason: 'pool status chip from Odoo');
    await _waitFor(tester, find.textContaining('Équitation'),
        reason: 'horse status chip from Odoo');
    await _waitFor(tester, find.textContaining('selle abime'),
        reason: 'ticket migrated from maintenance to interventions');

    // A failed read would show the sync banner; none must be visible.
    expect(find.textContaining('Synchronisation Odoo interrompue'), findsNothing);
  });

  testWidgets('staff reports an incident and it reaches Odoo', (tester) async {
    await _signIn(tester);

    final title = 'TEST incident ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.text('Signaler'));
    await _waitFor(tester, find.text('Nouvelle intervention'),
        reason: 'incident form');

    await _enter(tester, 'Ex: Filtre de pompe obstrué', title);
    await tester.pump(const Duration(milliseconds: 300));
    await _tap(tester, find.text("Signaler l'incident"));

    // The form closes back to the ticket list, where the new ticket appears.
    await _waitFor(tester, find.text(title),
        reason: 'new incident listed after saving');
    // Give the background push to Odoo time to finish.
    await tester.pump(const Duration(seconds: 3));

    final rpc = await _serverSession();
    final tickets = await OdooClubService(rpc).fetchInterventions();
    expect(tickets.map((t) => t.title), contains(title),
        reason: 'incident visible in Odoo');
  });

  testWidgets('a reservation is checked in from the home screen',
      (tester) async {
    final rpc = await _serverSession();
    final reservations = OdooReservationService(rpc);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 15);
    final client = 'TEST check-in ${now.millisecondsSinceEpoch}';
    final remoteId = await reservations.createReservation(
      activityId: 'horses',
      activityName: 'Équitation',
      clientName: client,
      peopleCount: 1,
      status: ReservationStatus.confirmed,
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
    );

    await _signIn(tester);
    await _waitFor(tester, find.text(client),
        reason: "today's reservation on the home screen");
    await _tap(tester, find.byKey(ValueKey('checkin-$remoteId')));
    await _waitFor(tester, find.textContaining('arrivée enregistrée'),
        reason: 'check-in confirmation');

    final onDay = await reservations.fetchReservationsForDay(start);
    final checked = onDay.firstWhere((r) => r.remoteId == remoteId);
    expect(checked.status, ReservationStatus.checkedIn,
        reason: 'check-in stored in Odoo');
  });
}
