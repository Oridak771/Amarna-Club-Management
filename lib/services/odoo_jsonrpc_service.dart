import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';

/// Latest synchronisation problem with Odoo, in French, for the staff banner.
/// `null` when nothing is known to be failing. Cleared when the user dismisses it.
final ValueNotifier<String?> odooSyncIssue = ValueNotifier<String?>(null);

/// Records a failed sync of [what] (e.g. "Activités") and keeps the detail in
/// the debug log. The message stays visible until the staff member dismisses it.
void reportSyncIssue(String what, Object error) {
  final detail = error is OdooException ? error.message : error.toString();
  odooSyncIssue.value = '$what : $detail';
  debugPrint('Odoo sync issue — $what: $error');
}

final odooJsonRpcServiceProvider = Provider<OdooJsonRpcService>((ref) {
  final service = OdooJsonRpcService(http.Client());
  ref.onDispose(service.dispose);
  return service;
});

/// Any failed call to the Odoo server, with a message fit to show the user.
///
/// [sessionExpired] is true when the server no longer recognises the
/// session: the user has to sign in again.
class OdooException implements Exception {
  const OdooException(this.message, {this.sessionExpired = false});

  final String message;
  final bool sessionExpired;

  @override
  String toString() => message;
}

/// JSON-RPC client for the Odoo web API.
///
/// Authentication uses the Odoo session cookie (`session_id`) obtained from
/// `/web/session/authenticate`. The password is only sent for that call and
/// is never stored.
class OdooJsonRpcService {
  OdooJsonRpcService(
    this._client, {
    this.timeout = const Duration(seconds: 15),
  });

  final http.Client _client;
  final Duration timeout;
  String? _sessionId;
  int _requestId = 0;

  /// The current `session_id` cookie value, or null when signed out.
  String? get sessionId => _sessionId;

  bool get hasSession => _sessionId != null;

  /// Reuses a session cookie saved by an earlier sign-in.
  void useSession(String sessionId) => _sessionId = sessionId;

  void clearSession() => _sessionId = null;

  /// Signs in with the user's own Odoo account and keeps the server session.
  /// Returns the session info (uid, name, username, ...).
  Future<Map<String, dynamic>> authenticate(
      String login, String password) async {
    final result = await _call(
      '/web/session/authenticate',
      {
        'db': AppEnvironment.odooDatabase,
        'login': login,
        'password': password,
      },
      captureSession: true,
    );
    final info = Map<String, dynamic>.from(result as Map);
    final uid = info['uid'];
    if (uid is! int || uid <= 0) {
      _sessionId = null;
      throw const OdooException('Identifiant ou mot de passe incorrect.');
    }
    return info;
  }

  /// Returns the session info when the stored session is still valid,
  /// or null when it has expired (or there is none).
  Future<Map<String, dynamic>?> validateSession() async {
    if (!hasSession) return null;
    try {
      final result = await _call('/web/session/get_session_info', const {});
      final info = Map<String, dynamic>.from(result as Map);
      final uid = info['uid'];
      if (uid is! int || uid <= 0) {
        _sessionId = null;
        return null;
      }
      return info;
    } on OdooException catch (error) {
      if (error.sessionExpired) return null;
      rethrow;
    }
  }

  /// Ends the server session (best effort) and forgets it locally.
  Future<void> logout() async {
    if (hasSession) {
      try {
        await _call('/web/session/destroy', const {});
      } on Object {
        // The local session is dropped regardless.
      }
    }
    _sessionId = null;
  }

  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    required List<dynamic> domain,
    required List<String> fields,
    int limit = 500,
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

  /// Creates one record and returns its id.
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    final result = await callKw(
      model: model,
      method: 'create',
      args: [
        [values],
      ],
    );
    // Odoo 17 returns a list of ids for create(); accept a bare id too.
    final id = result is List ? result.first : result;
    return (id as num).toInt();
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
    return result != false;
  }

  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) {
    return _call('/web/dataset/call_kw/$model/$method', {
      'model': model,
      'method': method,
      'args': args,
      'kwargs': kwargs,
    });
  }

  Future<dynamic> _call(
    String path,
    Map<String, dynamic> params, {
    bool captureSession = false,
  }) async {
    if (!AppEnvironment.isOdooConfigured) {
      throw const OdooException(
          'Serveur Odoo non configuré (AMARNA_ODOO_BASE_URL / AMARNA_ODOO_DB).');
    }

    final uri = Uri.parse('${AppEnvironment.odooBaseUrl}$path');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'id': ++_requestId,
      'params': params,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const OdooException(
          'Le serveur Odoo ne répond pas (délai dépassé).');
    } on SocketException {
      throw const OdooException(
          'Connexion au serveur Odoo impossible. Vérifiez le réseau.');
    } on http.ClientException {
      throw const OdooException(
          'Connexion au serveur Odoo impossible. Vérifiez le réseau.');
    }

    // Odoo answers in UTF-8 without declaring it: decode the bytes ourselves.
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw OdooException(
          'Réponse inattendue du serveur Odoo (HTTP ${response.statusCode}).');
    }
    if (decoded is! Map) {
      throw OdooException(
          'Réponse inattendue du serveur Odoo (HTTP ${response.statusCode}).');
    }

    final error = decoded['error'];
    if (error != null) {
      if (_isSessionExpired(error)) {
        _sessionId = null;
        throw const OdooException(
          'Votre session a expiré. Veuillez vous reconnecter.',
          sessionExpired: true,
        );
      }
      throw OdooException(_errorMessage(error));
    }

    if (captureSession) {
      final sessionId = extractSessionId(response.headers['set-cookie']);
      if (sessionId != null) {
        _sessionId = sessionId;
      }
    }

    return decoded['result'];
  }

  /// Pulls the value of the `session_id` cookie out of a Set-Cookie header.
  /// The `http` package joins several Set-Cookie headers with commas, so the
  /// value is matched by name instead of splitting the header.
  static String? extractSessionId(String? setCookie) {
    if (setCookie == null) return null;
    final match = RegExp(r'session_id=([^;,\s]+)').firstMatch(setCookie);
    return match?.group(1);
  }

  static bool _isSessionExpired(Object error) {
    if (error is! Map) return false;
    final data = error['data'];
    final name = data is Map ? data['name']?.toString() : null;
    return name == 'odoo.http.SessionExpiredException' || error['code'] == 100;
  }

  static String _errorMessage(Object error) {
    if (error is! Map) return error.toString();
    final data = error['data'];
    final name = data is Map ? data['name']?.toString() ?? '' : '';
    if (name.endsWith('AccessDenied')) {
      return 'Accès refusé par le serveur Odoo.';
    }
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return error['message']?.toString() ?? 'Erreur inconnue du serveur Odoo.';
  }

  void dispose() => _client.close();
}
