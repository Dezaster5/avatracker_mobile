import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Язык и страна в защищённом хранилище. Ключи устройства — переживают
/// выход из аккаунта.
class PreferencesLocalDataSource {
  const PreferencesLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _kLocale = 'app_locale';
  static const _kCountryIso = 'country_iso';

  Future<String?> readLanguageCode() => _storage.read(key: _kLocale);

  Future<void> saveLanguageCode(String code) =>
      _storage.write(key: _kLocale, value: code);

  Future<String?> readCountryIso() => _storage.read(key: _kCountryIso);

  Future<void> saveCountryIso(String iso) =>
      _storage.write(key: _kCountryIso, value: iso);
}
