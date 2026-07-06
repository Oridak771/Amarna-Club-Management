// Quick connectivity check for the Odoo PostgreSQL database.
// Usage: dart run tool/check_db.dart
// Reads credentials from the project's .env file.

import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main() async {
  final env = _parseEnv(File('.env'));

  final host = env['AMARNA_DB_HOST'] ?? '10.20.10.49';
  final port = int.tryParse(env['AMARNA_DB_PORT'] ?? '') ?? 5432;
  final database = env['AMARNA_DB_NAME'] ?? 'postgres';
  final username = env['AMARNA_DB_USERNAME'] ?? 'biuser';
  final password = env['AMARNA_DB_PASSWORD'] ?? '';

  stdout.writeln('Connecting to $host:$port/$database as $username ...');

  try {
    final connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: (env['AMARNA_DB_SSL_MODE'] ?? 'disable') == 'require'
            ? SslMode.require
            : SslMode.disable,
        connectTimeout: const Duration(seconds: 10),
      ),
    );

    final result = await connection.execute(
      "select current_database(), current_user, version(), "
      "to_char(now(), 'YYYY-MM-DD HH24:MI:SS')",
    );
    final row = result.first;
    stdout
      ..writeln('CONNECTED ✓')
      ..writeln('  database : ${row[0]}')
      ..writeln('  user     : ${row[1]}')
      ..writeln('  version  : ${row[2]}')
      ..writeln('  time     : ${row[3]}');

    final tables = await connection.execute(
      "select table_name from information_schema.tables "
      "where table_schema = 'public' and table_name in "
      "('res_users', 'calendar_event', 'maintenance_request', 'res_partner') "
      "order by table_name",
    );
    stdout.writeln('  odoo tables found: '
        '${tables.map((r) => r[0]).join(', ')}');

    await connection.close();
    exit(0);
  } catch (error) {
    stdout.writeln('FAILED ✗  $error');
    exit(1);
  }
}

Map<String, String> _parseEnv(File file) {
  if (!file.existsSync()) return {};
  final entries = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final index = trimmed.indexOf('=');
    if (index <= 0) continue;
    entries[trimmed.substring(0, index).trim()] =
        trimmed.substring(index + 1).trim();
  }
  return entries;
}
