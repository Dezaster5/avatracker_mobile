import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';

@immutable
class ChangePasswordState {
  const ChangePasswordState({this.saving = false, this.failure});

  final bool saving;
  final Failure? failure;
}

/// Смена пароля внутри приложения (Профиль → Сменить пароль).
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  Future<bool> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const ChangePasswordState(saving: true);
    final result = await ref.read(changePasswordProvider).call(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    switch (result) {
      case Success():
        state = const ChangePasswordState();
        return true;
      case Failed(:final failure):
        state = ChangePasswordState(failure: failure);
        return false;
    }
  }

  void clearError() => state = const ChangePasswordState();
}

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, ChangePasswordState>(
  ChangePasswordController.new,
);
