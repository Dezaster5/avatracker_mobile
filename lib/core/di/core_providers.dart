import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../network/session_expiry.dart';
import '../platform/system_settings.dart';
import '../storage/secure_storage.dart';
import '../storage/token_storage.dart';

/// Инфраструктура, общая для всех feature-модулей. Тесты подменяют эти
/// провайдеры через `ProviderScope.overrides`.
final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => appSecureStorage);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

final sessionExpiryProvider = Provider<SessionExpiryNotifier>((ref) {
  final notifier = SessionExpiryNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final sessionExpiry = ref.watch(sessionExpiryProvider);
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: () async => sessionExpiry.notify(),
  );
});

final systemSettingsProvider =
    Provider<SystemSettings>((ref) => const SystemSettings());
