import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/phone_number.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../di/auth_providers.dart';
import 'auth_controller.dart';

@immutable
class LoginState {
  const LoginState({this.submitting = false, this.failure});

  final bool submitting;
  final Failure? failure;
}

/// Вход по телефону и паролю.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<bool> login({
    required PhoneNumber phone,
    required String password,
  }) async {
    state = const LoginState(submitting: true);
    final result =
        await ref.read(signInProvider).call(phone: phone, password: password);
    switch (result) {
      case Success(:final value):
        ref.read(authControllerProvider.notifier).signedIn(value);
        state = const LoginState();
        return true;
      case Failed(:final failure):
        state = LoginState(failure: failure);
        return false;
    }
  }

  void clearError() => state = const LoginState();
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);
