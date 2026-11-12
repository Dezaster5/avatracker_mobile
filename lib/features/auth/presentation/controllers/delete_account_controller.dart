import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/session_restoration.dart';
import 'auth_controller.dart';

@immutable
class DeleteAccountState {
  const DeleteAccountState({this.deleting = false, this.failure});

  final bool deleting;
  final Failure? failure;
}

/// Удаление аккаунта приложения (App Store §5.1.1(v)).
class DeleteAccountController extends AutoDisposeNotifier<DeleteAccountState> {
  @override
  DeleteAccountState build() => const DeleteAccountState();

  Future<void> delete() async {
    state = const DeleteAccountState(deleting: true);
    switch (await ref.read(deleteAccountProvider).call()) {
      case Success():
        state = const DeleteAccountState();
        // Сессия очищена — роутер уведёт на вход, нужна новая регистрация.
        ref
            .read(authControllerProvider.notifier)
            .signedOut(LogoutReason.accountDeleted);
      case Failed(:final failure):
        state = DeleteAccountState(failure: failure);
    }
  }
}

final deleteAccountControllerProvider =
    AutoDisposeNotifierProvider<DeleteAccountController, DeleteAccountState>(
  DeleteAccountController.new,
);
