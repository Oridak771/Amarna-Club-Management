/// Build-time configuration of the tablet app.
///
/// Nothing secret is compiled into the app: users sign in with their own
/// Odoo account. The server address defaults to the club's Odoo server and can
/// be replaced at build or run time, for example to test on another server:
///
///   flutter run --dart-define-from-file=config/dart_define.local.json
///
/// See `config/dart_define.example.json` for the expected keys.
class AppEnvironment {
  const AppEnvironment._();

  /// Root URL of the Odoo server (no trailing slash). The club server runs on
  /// plain HTTP inside the local network; prefer HTTPS when it is exposed.
  static const String odooBaseUrl = String.fromEnvironment(
    'AMARNA_ODOO_BASE_URL',
    defaultValue: 'http://10.20.10.49:8069',
  );

  /// Odoo database name the tablet signs in to.
  static const String odooDatabase = String.fromEnvironment(
    'AMARNA_ODOO_DB',
    defaultValue: 'hasnaoui_amarna',
  );

  static bool get isOdooConfigured =>
      odooBaseUrl.isNotEmpty && odooDatabase.isNotEmpty;
}
