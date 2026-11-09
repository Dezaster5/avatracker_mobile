import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Единая конфигурация Keychain / Android Keystore для всех хранилищ.
///
/// На Android другие опции означают другой файл: данные, сохранённые
/// предыдущими версиями приложения (сессия, язык, страна), «пропадут».
const appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
