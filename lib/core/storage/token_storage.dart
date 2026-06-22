import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Безопасное хранилище сессии (Keychain / Android Keystore).
///
/// По ТЗ 18.2 локально храним: access/refresh token, ИИН, телефон,
/// базовый профиль. SMS-коды и фото не сохраняются.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kIin = 'iin';
  static const _kPhone = 'phone';
  static const _kEmployee = 'employee_json';

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get iin => _storage.read(key: _kIin);
  Future<String?> get phone => _storage.read(key: _kPhone);

  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String iin,
    required String phone,
  }) async {
    await saveTokens(access: accessToken, refresh: refreshToken);
    await _storage.write(key: _kIin, value: iin);
    await _storage.write(key: _kPhone, value: phone);
  }

  Future<void> saveEmployeeJson(Map<String, dynamic> json) =>
      _storage.write(key: _kEmployee, value: jsonEncode(json));

  Future<Map<String, dynamic>?> readEmployeeJson() async {
    final raw = await _storage.read(key: _kEmployee);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Очистка сессии при выходе.
  Future<void> clearSession() async {
    for (final key in const [_kAccess, _kRefresh, _kIin, _kPhone, _kEmployee]) {
      await _storage.delete(key: key);
    }
  }
}
