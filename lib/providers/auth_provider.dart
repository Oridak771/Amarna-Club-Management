import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_environment.dart';
import '../services/odoo_jsonrpc_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  /// Session info returned by Odoo (uid, name, username, ...).
  final Map<String, dynamic>? userDetails;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.userDetails,
  });
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(odooJsonRpcServiceProvider));
});

/// Signs staff in with their own Odoo account.
///
/// Only the Odoo session cookie is ever stored (encrypted by the platform
/// keystore), and only when the user ticks "Se souvenir de moi". The password
/// is never kept: an expired session sends the user back to the login screen.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._odoo, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const AuthState(status: AuthStatus.initial));

  final OdooJsonRpcService _odoo;
  final FlutterSecureStorage _storage;

  static const _keySession = 'odoo_session_id';

  /// Restores the saved session at start-up, if it is still valid.
  Future<void> tryAutoLogin() async {
    if (!AppEnvironment.isOdooConfigured) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Serveur Odoo non configuré dans cette version.',
      );
      return;
    }

    final saved = await _readSafely(_keySession);
    if (saved == null || saved.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    state = const AuthState(status: AuthStatus.authenticating);
    _odoo.useSession(saved);
    try {
      final info = await _odoo.validateSession();
      if (info == null) {
        await _forgetSession();
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          userDetails: info,
        );
      }
    } on OdooException catch (error) {
      // Server unreachable: keep the saved session and let the user retry.
      _odoo.clearSession();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
      );
    }
  }

  Future<void> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AuthState(status: AuthStatus.authenticating);
    try {
      final info = await _odoo.authenticate(username.trim(), password);
      if (rememberMe && _odoo.sessionId != null) {
        await _writeSafely(_keySession, _odoo.sessionId!);
      } else {
        await _forgetSession();
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        userDetails: info,
      );
    } on OdooException catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: error.message,
      );
    }
  }

  Future<void> logout() async {
    await _odoo.logout();
    await _forgetSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called when any screen gets a session-expired error.
  Future<void> sessionExpired() async {
    _odoo.clearSession();
    await _forgetSession();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Votre session a expiré. Veuillez vous reconnecter.',
    );
  }

  Future<void> _forgetSession() async {
    try {
      await _storage.delete(key: _keySession);
    } on Object catch (error) {
      debugPrint('Could not clear saved session: $error');
    }
  }

  Future<String?> _readSafely(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object catch (error) {
      debugPrint('Secure storage read failed: $error');
      return null;
    }
  }

  Future<void> _writeSafely(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on Object catch (error) {
      debugPrint('Secure storage write failed: $error');
    }
  }
}
