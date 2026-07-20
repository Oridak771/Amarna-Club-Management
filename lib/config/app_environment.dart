import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration, read from the bundled `.env` file
/// (see `.env.example`).
class AppEnvironment {
  const AppEnvironment._();

  static String _read(String key, {String defaultValue = ''}) {
    final value = dotenv.maybeGet(key);
    return (value == null || value.isEmpty) ? defaultValue : value;
  }

  /// Loads the `.env` asset. Safe to call when the file is absent.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // No .env bundled — defaults still apply.
    }
  }

  static String get postgresHost =>
      _read('AMARNA_DB_HOST', defaultValue: '10.20.10.49');
  static int get postgresPort =>
      int.tryParse(_read('AMARNA_DB_PORT', defaultValue: '5432')) ?? 5432;
  static String get postgresDatabase =>
      _read('AMARNA_DB_NAME', defaultValue: 'postgres');
  static String get postgresUsername =>
      _read('AMARNA_DB_USERNAME', defaultValue: 'biuser');
  static String get postgresPassword => _read('AMARNA_DB_PASSWORD');
  static String get postgresSslMode =>
      _read('AMARNA_DB_SSL_MODE', defaultValue: 'disable');

  static String get odooBaseUrl => _read('AMARNA_ODOO_BASE_URL');
  static String get odooDatabase => _read('AMARNA_ODOO_DB');
  static String get odooUsername => _read('AMARNA_ODOO_USERNAME');
  static String get odooPassword => _read('AMARNA_ODOO_PASSWORD');

  static String get odooReservationModel =>
      _read('AMARNA_ODOO_RESERVATION_MODEL', defaultValue: 'calendar.event');
  static String get odooReservationStartField =>
      _read('AMARNA_ODOO_RESERVATION_START_FIELD', defaultValue: 'start');
  static String get odooReservationEndField =>
      _read('AMARNA_ODOO_RESERVATION_END_FIELD', defaultValue: 'stop');
  static String get odooReservationActivityField =>
      _read('AMARNA_ODOO_RESERVATION_ACTIVITY_FIELD');
  static String get odooReservationClientField =>
      _read('AMARNA_ODOO_RESERVATION_CLIENT_FIELD');
  static String get odooReservationPeopleCountField =>
      _read('AMARNA_ODOO_RESERVATION_PEOPLE_FIELD');
  static String get odooReservationStatusField =>
      _read('AMARNA_ODOO_RESERVATION_STATUS_FIELD');
  static String get odooReservationNotesField =>
      _read('AMARNA_ODOO_RESERVATION_NOTES_FIELD', defaultValue: 'description');

  static String get odooTicketModel =>
      _read('AMARNA_ODOO_TICKET_MODEL', defaultValue: 'maintenance.request');
  static String get odooTicketDueField => _read('AMARNA_ODOO_TICKET_DUE_FIELD');
  static String get odooTicketStatusField =>
      _read('AMARNA_ODOO_TICKET_STATUS_FIELD');
  static String get odooTicketPriorityField =>
      _read('AMARNA_ODOO_TICKET_PRIORITY_FIELD');
  static String get odooTicketActivityField =>
      _read('AMARNA_ODOO_TICKET_ACTIVITY_FIELD');
  static String get odooTicketAssigneeField =>
      _read('AMARNA_ODOO_TICKET_ASSIGNEE_FIELD');

  static bool get isPostgresConfigured =>
      postgresHost.isNotEmpty &&
      postgresDatabase.isNotEmpty &&
      postgresUsername.isNotEmpty &&
      postgresPassword.isNotEmpty;

  static bool get isOdooConfigured =>
      odooBaseUrl.isNotEmpty &&
      odooDatabase.isNotEmpty;
}
