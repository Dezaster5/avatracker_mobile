import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

enum AuthScheme { jwt, opaque }

typedef TokenSession = ({String? access, String? refresh, AuthScheme scheme});

/// Ключи текущей сессии в прежнем Keychain / Keystore.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? appSecureStorage;

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kScheme = 'auth_scheme';

  Future<void> _pending = Future.value();

  // Записи нескольких ключей и чтения не должны перемешиваться с refresh.
  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<TokenSession> _read() async => (
        access: await _storage.read(key: _kAccess),
        refresh: await _storage.read(key: _kRefresh),
        // Сессии, сохранённые предыдущей версией, остаются JWT.
        scheme: await _storage.read(key: _kScheme) == AuthScheme.opaque.name
            ? AuthScheme.opaque
            : AuthScheme.jwt,
      );

  Future<TokenSession> readSession() => _serial(_read);
  Future<String?> get accessToken async => (await readSession()).access;
  Future<String?> get refreshToken async => (await readSession()).refresh;

  Future<void> saveTokens({
    required String access,
    String? refresh,
    AuthScheme scheme = AuthScheme.jwt,
  }) =>
      _serial(() => _write(access: access, refresh: refresh, scheme: scheme));

  Future<void> _write({
    required String access,
    String? refresh,
    required AuthScheme scheme,
  }) async {
    await _storage.write(key: _kScheme, value: scheme.name);
    if (scheme == AuthScheme.jwt && refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refresh);
    } else {
      await _storage.delete(key: _kRefresh);
    }
    await _storage.write(key: _kAccess, value: access);
  }

  /// Поздний ответ JWT refresh не должен затереть новый вход через v2.
  Future<void> replaceJwtTokens({
    required TokenSession previous,
    required String access,
    required String refresh,
  }) =>
      _serial(() async {
        final current = await _read();
        if (current != previous || current.scheme != AuthScheme.jwt) return;
        await _write(access: access, refresh: refresh, scheme: AuthScheme.jwt);
      });

  Future<bool> clearIfCurrent(String access) => _serial(() async {
        if (await _storage.read(key: _kAccess) != access) return false;
        await _clear();
        return true;
      });

  Future<void> clear() => _serial(_clear);

  Future<void> _clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kScheme);
  }
}
