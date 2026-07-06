import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import '../models/integration_status.dart';

final odooJsonRpcServiceProvider = Provider<OdooJsonRpcService>((ref) {
  return OdooJsonRpcService(http.Client());
});

class OdooJsonRpcService {
  OdooJsonRpcService(this._client);

  final http.Client _client;
  String? _sessionCookie;

  Future<IntegrationStatus> checkHealth() async {
    if (!AppEnvironment.isOdooConfigured) {
      return const IntegrationStatus(
        name: 'Odoo',
        state: IntegrationHealthState.notConfigured,
        message:
            'AMARNA_ODOO_BASE_URL, AMARNA_ODOO_DB, AMARNA_ODOO_USERNAME ou AMARNA_ODOO_PASSWORD manquant.',
      );
    }

    try {
      final sessionInfo = await authenticate();
      return IntegrationStatus(
        name: 'Odoo',
        state: IntegrationHealthState.connected,
        message: 'Session JSON-RPC active.',
        details: {
          'baseUrl': AppEnvironment.odooBaseUrl,
          'database': AppEnvironment.odooDatabase,
          'userId': sessionInfo['uid']?.toString() ?? '',
          'company':
              sessionInfo['user_companies']?['current_company']?.toString() ??
                  '',
        },
      );
    } catch (error) {
      return IntegrationStatus(
        name: 'Odoo',
        state: IntegrationHealthState.disconnected,
        message: error.toString(),
        details: {
          'baseUrl': AppEnvironment.odooBaseUrl,
          'database': AppEnvironment.odooDatabase,
        },
      );
    }
  }

  Future<Map<String, dynamic>> authenticate() async {
    final result = await _post(
      '/web/session/authenticate',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': AppEnvironment.odooDatabase,
          'login': AppEnvironment.odooUsername,
          'password': AppEnvironment.odooPassword,
        },
      },
      allowRetry: false,
    );

    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    required List<dynamic> domain,
    required List<String> fields,
    int limit = 80,
    String order = 'id desc',
  }) async {
    final result = await callKw(
      model: model,
      method: 'search_read',
      args: [domain],
      kwargs: {
        'fields': fields,
        'limit': limit,
        'order': order,
      },
    );

    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    final result = await callKw(
      model: model,
      method: 'create',
      args: [values],
    );

    return (result as num).toInt();
  }

  Future<bool> write({
    required String model,
    required int id,
    required Map<String, dynamic> values,
  }) async {
    final result = await callKw(
      model: model,
      method: 'write',
      args: [
        [id],
        values,
      ],
    );

    return result == true;
  }

  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _ensureAuthenticated();

    final result = await _post(
      '/web/dataset/call_kw/$model/$method',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': method,
          'args': args,
          'kwargs': kwargs,
        },
      },
    );

    return result;
  }

  Future<void> _ensureAuthenticated() async {
    if (_sessionCookie != null) {
      return;
    }

    await authenticate();
  }

  Future<dynamic> _post(
    String path, {
    required Map<String, dynamic> body,
    bool allowRetry = true,
  }) async {
    final uri = Uri.parse('${AppEnvironment.odooBaseUrl}$path');
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (_sessionCookie != null) 'Cookie': _sessionCookie!,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      _sessionCookie = setCookie
          .split(',')
          .map((part) => part.split(';').first.trim())
          .join('; ');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      if (allowRetry && _looksLikeSessionError(decoded['error'])) {
        _sessionCookie = null;
        await authenticate();
        return _post(path, body: body, allowRetry: false);
      }

      throw Exception(_extractOdooError(decoded['error']));
    }

    return decoded['result'];
  }

  bool _looksLikeSessionError(dynamic error) {
    final message = _extractOdooError(error).toLowerCase();
    return message.contains('session') ||
        message.contains('access denied') ||
        message.contains('authentication');
  }

  String _extractOdooError(dynamic error) {
    if (error is Map<String, dynamic>) {
      final data = error['data'];
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      }

      if (error['message'] != null) {
        return error['message'].toString();
      }
    }

    return error.toString();
  }
}
