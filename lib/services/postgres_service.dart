import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgres/postgres.dart';

import '../config/app_environment.dart';
import '../models/integration_status.dart';

final postgresServiceProvider = Provider<PostgresService>((ref) {
  return const PostgresService();
});

class PostgresService {
  const PostgresService();

  Future<IntegrationStatus> checkHealth() async {
    if (!AppEnvironment.isPostgresConfigured) {
      return const IntegrationStatus(
        name: 'PostgreSQL',
        state: IntegrationHealthState.notConfigured,
        message: 'AMARNA_DB_PASSWORD ou AMARNA_DB_NAME manquant.',
      );
    }

    try {
      final connection = await _openConnection();
      try {
        final result = await connection.execute(
          Sql.named(
            'select current_database() as database_name, '
            'current_user as username, '
            "to_char(now(), 'YYYY-MM-DD HH24:MI:SS') as server_time",
          ),
        );

        final firstRow = result.firstOrNull;
        return IntegrationStatus(
          name: 'PostgreSQL',
          state: IntegrationHealthState.connected,
          message: 'Connexion directe disponible.',
          details: {
            'host': AppEnvironment.postgresHost,
            'database':
                firstRow?[0]?.toString() ?? AppEnvironment.postgresDatabase,
            'user': firstRow?[1]?.toString() ?? AppEnvironment.postgresUsername,
            'serverTime': firstRow?[2]?.toString() ?? '',
          },
        );
      } finally {
        await connection.close();
      }
    } catch (error) {
      return IntegrationStatus(
        name: 'PostgreSQL',
        state: IntegrationHealthState.disconnected,
        message: error.toString(),
        details: {
          'host': AppEnvironment.postgresHost,
          'database': AppEnvironment.postgresDatabase,
          'user': AppEnvironment.postgresUsername,
        },
      );
    }
  }

  Future<List<Map<String, Object?>>> executeRead(
    String sql, {
    Map<String, Object?> parameters = const {},
  }) async {
    final connection = await _openConnection();
    try {
      final result = await connection.execute(
        Sql.named(sql),
        parameters: parameters,
      );

      return result.map((row) {
        final values = row.toColumnMap();
        return Map<String, Object?>.from(
          values.map((key, value) => MapEntry(key, value)),
        );
      }).toList();
    } finally {
      await connection.close();
    }
  }

  Future<Connection> _openConnection() {
    return Connection.open(
      Endpoint(
        host: AppEnvironment.postgresHost,
        port: AppEnvironment.postgresPort,
        database: AppEnvironment.postgresDatabase,
        username: AppEnvironment.postgresUsername,
        password: AppEnvironment.postgresPassword,
      ),
      settings: ConnectionSettings(
        sslMode: AppEnvironment.postgresSslMode.toLowerCase() == 'require'
            ? SslMode.require
            : SslMode.disable,
      ),
    );
  }
}
