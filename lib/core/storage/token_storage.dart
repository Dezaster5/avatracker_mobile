import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/formatters.dart';

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

  // Устройство-уровневые ключи — переживают выход из аккаунта.
  static const _kConsent = 'consent_json';
  static const _kIntroSeen = 'intro_seen';
  static const _kLocale = 'app_locale';
  static const _kCountryIso = 'country_iso';

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

  /// Факт согласия на обработку персональных данных (App Store §5.1.1).
  Future<void> saveConsent({
    required String iin,
    required String version,
  }) {
    return _storage.write(
      key: _kConsent,
      value: jsonEncode({
        'employee_iin': iin,
        'consent_given': true,
        'consent_version': version,
        'consent_given_at': isoWithOffset(DateTime.now()),
      }),
    );
  }

  Future<Map<String, dynamic>?> readConsent() async {
    final raw = await _storage.read(key: _kConsent);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Информационный экран цели приложения уже показан пользователю.
  Future<bool> get introSeen async =>
      (await _storage.read(key: _kIntroSeen)) == '1';

  Future<void> setIntroSeen() => _storage.write(key: _kIntroSeen, value: '1');

  /// Выбранный язык интерфейса (`ru` / `kk` / `uz`).
  Future<String?> get localeCode => _storage.read(key: _kLocale);
  Future<void> saveLocale(String code) =>
      _storage.write(key: _kLocale, value: code);

  /// ISO-код выбранной страны для телефона (`KZ` / `UZ`).
  Future<String?> get countryIso => _storage.read(key: _kCountryIso);
  Future<void> saveCountryIso(String iso) =>
      _storage.write(key: _kCountryIso, value: iso);

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
