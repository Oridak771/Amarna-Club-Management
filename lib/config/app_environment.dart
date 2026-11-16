/// Build-time configuration of the tablet app.
///
/// Nothing secret is compiled into the app: users sign in with their own
/// Odoo account, and the server address is passed at build or run time:
///
///   flutter run --dart-define-from-file=config/dart_define.local.json
///
/// See `config/dart_define.example.json` for the expected keys.
class AppEnvironment {
  const AppEnvironment._();

  /// Root URL of the Odoo server, e.g. `https://odoo.example.com`
  /// (no trailing slash). Production builds must use HTTPS.
  static const String odooBaseUrl =
      String.fromEnvironment('AMARNA_ODOO_BASE_URL');

  /// Odoo database name the tablet signs in to.
  static const String odooDatabase = String.fromEnvironment('AMARNA_ODOO_DB');

  static bool get isOdooConfigured =>
      odooBaseUrl.isNotEmpty && odooDatabase.isNotEmpty;
}
