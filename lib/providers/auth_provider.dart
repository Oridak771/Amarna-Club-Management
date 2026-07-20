import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/odoo_jsonrpc_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? userDetails;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.userDetails,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    Map<String, dynamic>? userDetails,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userDetails: userDetails ?? this.userDetails,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final odooService = ref.read(odooJsonRpcServiceProvider);
  return AuthNotifier(odooService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final OdooJsonRpcService _odooService;
  final _storage = const FlutterSecureStorage();

  static const _keyUsername = 'odoo_username';
  static const _keyPassword = 'odoo_password';

  AuthNotifier(this._odooService)
      : super(const AuthState(status: AuthStatus.initial));

  Future<void> tryAutoLogin() async {
    try {
      final username = await _storage.read(key: _keyUsername);
      final password = await _storage.read(key: _keyPassword);

      if (username != null && password != null) {
        state = state.copyWith(
          status: AuthStatus.authenticating,
          errorMessage: null,
        );
        final session = await _odooService.authenticate(
          username: username,
          password: password,
          persistSession: true,
        );
        state = AuthState(
          status: AuthStatus.authenticated,
          userDetails: session,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login(String username, String password, {bool rememberMe = false}) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final session = await _odooService.authenticate(
        username: username,
        password: password,
        persistSession: true,
      );

      if (rememberMe) {
        await _storage.write(key: _keyUsername, value: username);
        await _storage.write(key: _keyPassword, value: password);
      } else {
        await _storage.delete(key: _keyUsername);
        await _storage.delete(key: _keyPassword);
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        userDetails: session,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
    _odooService.clearSession();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
