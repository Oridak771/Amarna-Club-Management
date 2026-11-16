// Tests of the tablet's Odoo layer.
//
// 1. Unit tests (always run): time-zone conversions, availability rules and
//    session-cookie parsing.
// 2. Integration tests (need a running Odoo with the amarna_club addons):
//    they exercise the real service classes against the server, as a
//    non-admin staff account. They are skipped unless the following are given:
//
//    flutter test --dart-define-from-file=config/dart_define.local.json \
//      --dart-define=AMARNA_TEST_LOGIN=<staff login> \
//      --dart-define=AMARNA_TEST_PASSWORD=<staff password>
//
// Test records are named "TEST ..." so they are easy to find in Odoo. The
// tablet account cannot delete records, so they are removed by an admin.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:amarna_club/config/app_environment.dart';
import 'package:amarna_club/models/activity.dart';
import 'package:amarna_club/models/reservation.dart';
import 'package:amarna_club/models/work_ticket.dart';
import 'package:amarna_club/services/odoo_club_service.dart';
import 'package:amarna_club/services/odoo_datetime.dart';
import 'package:amarna_club/services/odoo_jsonrpc_service.dart';
import 'package:amarna_club/services/odoo_reservation_service.dart';
import 'package:amarna_club/services/ticket_sync_service.dart';

const _login = String.fromEnvironment('AMARNA_TEST_LOGIN');
const _password = String.fromEnvironment('AMARNA_TEST_PASSWORD');

void main() {
  group('Odoo date conversions', () {
    test('a local time is stored as UTC and read back unchanged', () {
      final local = DateTime(2030, 1, 15, 10, 30);
      final stored = toOdooDateTime(local);
      expect(fromOdooDateTime(stored), local);
      expect(
        fromOdooDateTime('2030-01-15 09:30:00'),
        DateTime.utc(2030, 1, 15, 9, 30).toLocal(),
      );
    });

    test('empty or invalid values give null', () {
      expect(fromOdooDateTime(false), isNull);
      expect(fromOdooDateTime(''), isNull);
      expect(fromOdooDate(null), isNull);
      expect(fromOdooDate('not a date'), isNull);
    });

    test('dates keep their calendar day', () {
      expect(toOdooDate(DateTime(2030, 2, 3, 23, 59)), '2030-02-03');
      expect(fromOdooDate('2030-02-03'), DateTime(2030, 2, 3));
    });

    test('a local day maps to a UTC window of the same length', () {
      final (start, end) = odooDayBounds(DateTime(2030, 1, 15, 17));
      expect(start, toOdooDateTime(DateTime(2030, 1, 15)));
      expect(end, toOdooDateTime(DateTime(2030, 1, 16)));
    });
  });

  group('Activity availability (mirrors amarna.club.activity)', () {
    Activity activity({
      ActivityStatus status = ActivityStatus.open,
      DateTime? closureStart,
      DateTime? closureEnd,
    }) {
      return Activity(
        id: 'horses',
        name: 'Équitation',
        iconKey: 'horses',
        status: status,
        currentOccupancy: 0,
        maxCapacity: 20,
        assignedStaff: '',
        closureStart: closureStart,
        closureEnd: closureEnd,
      );
    }

    final slotStart = DateTime(2030, 1, 15, 10);
    final slotEnd = DateTime(2030, 1, 15, 11);

    test('open and warning activities take bookings', () {
      expect(activity().isAvailableAt(slotStart, slotEnd), isTrue);
      expect(
        activity(status: ActivityStatus.warning).isAvailableAt(slotStart, slotEnd),
        isTrue,
      );
    });

    test('closed and in-maintenance activities do not', () {
      expect(
        activity(status: ActivityStatus.closed).isAvailableAt(slotStart, slotEnd),
        isFalse,
      );
      expect(
        activity(status: ActivityStatus.maintenance)
            .isAvailableAt(slotStart, slotEnd),
        isFalse,
      );
    });

    test('a booking may not overlap a closure window', () {
      final closed = activity(
        closureStart: DateTime(2030, 1, 15, 10, 30),
        closureEnd: DateTime(2030, 1, 15, 12),
      );
      expect(closed.isAvailableAt(slotStart, slotEnd), isFalse);
      // Ending exactly when the closure starts is fine.
      expect(
        closed.isAvailableAt(DateTime(2030, 1, 15, 9), DateTime(2030, 1, 15, 10, 30)),
        isTrue,
      );
    });

    test('an open-ended closure blocks everything after its start', () {
      final closed = activity(closureStart: DateTime(2030, 1, 15, 9));
      expect(closed.isAvailableAt(slotStart, slotEnd), isFalse);
      expect(
        closed.isAvailableAt(DateTime(2030, 1, 15, 7), DateTime(2030, 1, 15, 8)),
        isTrue,
      );
    });

    test('an empty or reversed slot is never available', () {
      expect(activity().isAvailableAt(slotEnd, slotStart), isFalse);
      expect(activity().isAvailableAt(slotStart, slotStart), isFalse);
    });
  });

  group('Session cookie parsing', () {
    test('finds session_id among other cookies and attributes', () {
      expect(
        OdooJsonRpcService.extractSessionId(
          'session_id=abc123; Max-Age=7776000; Expires=Mon, 16 Feb 2027 10:00:00 GMT; '
          'HttpOnly; Path=/; SameSite=Lax',
        ),
        'abc123',
      );
    });

    test('joined Set-Cookie headers still yield the session id', () {
      expect(
        OdooJsonRpcService.extractSessionId(
          'tz=Europe/Paris; Path=/, session_id=xyz789; Path=/',
        ),
        'xyz789',
      );
    });

    test('no session cookie gives null', () {
      expect(OdooJsonRpcService.extractSessionId(null), isNull);
      expect(OdooJsonRpcService.extractSessionId('tz=UTC; Path=/'), isNull);
    });
  });

  group(
    'Odoo integration (staff account)',
    () {
      late OdooJsonRpcService rpc;
      late OdooClubService club;
      late OdooReservationService reservations;
      late TicketSyncService tickets;

      setUpAll(() async {
        rpc = OdooJsonRpcService(http.Client());
        club = OdooClubService(rpc);
        reservations = OdooReservationService(rpc);
        tickets = TicketSyncService(rpc);
        await rpc.authenticate(_login, _password);
      });

      tearDownAll(() async {
        await rpc.logout();
      });

      test('the session is valid after sign-in', () async {
        final info = await rpc.validateSession();
        expect(info, isNotNull);
        expect(info!['uid'], isA<int>());
      });

      test('activities are read from Odoo', () async {
        final activities = await club.fetchActivities();
        expect(activities.map((a) => a.id), contains('horses'));
      });

      test('a ticket created on the tablet comes back with its status', () async {
        final id = 'test-${DateTime.now().microsecondsSinceEpoch}';
        final ticket = WorkTicket(
          id: id,
          title: 'TEST ticket $id',
          description: 'Created by the integration test',
          activityId: 'horses',
          activityName: 'Équitation',
          type: TicketType.anomaly,
          priority: TicketPriority.high,
          status: TicketStatus.open,
          dateCreated: DateTime.now(),
        );

        await tickets.syncTicket(ticket);
        var pulled = (await club.fetchInterventions())
            .firstWhere((t) => t.id == id);
        expect(pulled.status, TicketStatus.open);
        expect(pulled.priority, TicketPriority.high);

        // Pushing the same id again updates the record instead of duplicating it.
        await tickets.syncTicket(ticket.copyWith(status: TicketStatus.inProgress));
        final all = await club.fetchInterventions();
        expect(all.where((t) => t.id == id), hasLength(1));
        pulled = all.firstWhere((t) => t.id == id);
        expect(pulled.status, TicketStatus.inProgress);
      });

      test('a reservation is stored in UTC, found on its day, and checked in',
          () async {
        final day = DateTime(2030, 1, 15, 10);
        final remoteId = await reservations.createReservation(
          activityId: 'horses',
          activityName: 'Équitation',
          clientName: 'TEST client',
          peopleCount: 2,
          status: ReservationStatus.pending,
          startAt: day,
          endAt: day.add(const Duration(hours: 1)),
        );

        final onDay = await reservations.fetchReservationsForDay(day);
        final found = onDay.firstWhere((r) => r.remoteId == remoteId);
        expect(found.clientName, 'TEST client');
        expect(found.startAt, day);
        expect(found.status, ReservationStatus.pending);

        await reservations.updateReservationStatus(
            remoteId, ReservationStatus.checkedIn);
        final after = await reservations.fetchReservationsForDay(day);
        expect(
          after.firstWhere((r) => r.remoteId == remoteId).status,
          ReservationStatus.checkedIn,
        );
      });

      test('a pool reading is stored and read back', () async {
        await club.createPoolReading(
          temperature: 28,
          chlorine: 2,
          ph: 7.4,
          turbidity: 0.5,
          author: 'TEST',
        );
        final latest = await club.fetchLatestPoolReading();
        expect(latest, isNotNull);
        expect(latest!.temperature, closeTo(28, 0.001));
      });
    },
    skip: (AppEnvironment.isOdooConfigured && _login.isNotEmpty && _password.isNotEmpty)
        ? false
        : 'Set AMARNA_ODOO_BASE_URL / AMARNA_ODOO_DB and AMARNA_TEST_LOGIN / AMARNA_TEST_PASSWORD',
  );
}
