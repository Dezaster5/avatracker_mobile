import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
    headers: {'Accept': 'application/json'},
  ));
  ref.onDispose(() => dio.close(force: true));
  return AppUpdateService(dio: dio);
});

class AppUpdateController extends StateNotifier<AsyncValue<AppUpdate?>> {
  AppUpdateController(this._service) : super(const AsyncLoading());
  final AppUpdateService _service;
  Future<void>? _checking;

  Future<void> check() =>
      _checking ??= _check().whenComplete(() => _checking = null);

  Future<void> _check() async {
    final update = await _service.check();
    if (mounted) state = AsyncData(update);
  }
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateController, AsyncValue<AppUpdate?>>(
  (ref) => AppUpdateController(ref.watch(appUpdateServiceProvider)),
);
