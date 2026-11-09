import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/date_formatters.dart';

/// Локальная сессия (ТЗ 18.2): JWT-пара, ИИН, телефон и кеш профиля.
/// SMS-коды, пароли и фото не сохраняются.
class AuthLocalDataSource {
  const AuthLocalDataSource({
    required TokenStorage tokens,
    required FlutterSecureStorage storage,
  })  : _tokens = tokens,
        _storage = storage;

  final TokenStorage _tokens;
  final FlutterSecureStorage _storage;

  static const _kIin = 'iin';
  static const _kPhone = 'phone';
  static const _kEmployee = 'employee_json';

  /// Ключ устройства — переживает выход из аккаунта.
  static const _kConsent = 'consent_json';

  Future<String?> get accessToken => _tokens.accessToken;

  Future<String?> get iin => _storage.read(key: _kIin);

  /// Токен нужен раньше профиля: запрос `/profile/me/` должен его нести.
  Future<void> saveTokens({required String access, required String refresh}) =>
      _tokens.saveTokens(access: access, refresh: refresh);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String iin,
    required String phone,
  }) async {
    await _tokens.saveTokens(access: accessToken, refresh: refreshToken);
    await _storage.write(key: _kIin, value: iin);
    await _storage.write(key: _kPhone, value: phone);
  }

  Future<Map<String, dynamic>?> readEmployeeJson() async {
    final raw = await _storage.read(key: _kEmployee);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveEmployeeJson(Map<String, dynamic> json) =>
      _storage.write(key: _kEmployee, value: jsonEncode(json));

  Future<void> saveConsent({
    required String iin,
    required String policyVersion,
  }) =>
      _storage.write(
        key: _kConsent,
        value: jsonEncode({
          'employee_iin': iin,
          'consent_given': true,
          'consent_version': policyVersion,
          'consent_given_at': isoWithOffset(DateTime.now()),
        }),
      );

  Future<void> clearSession() async {
    await _tokens.clear();
    for (final key in const [_kIin, _kPhone, _kEmployee]) {
      await _storage.delete(key: key);
    }
  }
}
