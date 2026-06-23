import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/pin_code_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

/// Назначение SMS-кода: подтверждение регистрации или сброс пароля.
enum SmsFlow { register, reset }

/// Подтверждение SMS-кода (ТЗ 4): сегментированный ввод, автопроверка,
/// повторная отправка через 60 с, не более 5 попыток.
class SmsCodeScreen extends ConsumerStatefulWidget {
  const SmsCodeScreen({super.key, required this.flow});

  final SmsFlow flow;

  @override
  ConsumerState<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends ConsumerState<SmsCodeScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  SmsFlowState get _flowState => widget.flow == SmsFlow.register
      ? ref.read(registrationControllerProvider)
      : ref.read(passwordResetControllerProvider);

  void _startTimer() {
    _timer?.cancel();
    _updateSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsLeft();
      if (_secondsLeft <= 0) _timer?.cancel();
    });
  }

  void _updateSecondsLeft() {
    final sentAt = _flowState.codeSentAt;
    final passed = sentAt == null
        ? AppConfig.smsResendSeconds
        : DateTime.now().difference(sentAt).inSeconds;
    if (!mounted) return;
    setState(() {
      _secondsLeft = (AppConfig.smsResendSeconds - passed)
          .clamp(0, AppConfig.smsResendSeconds);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (widget.flow == SmsFlow.register) {
      ref.read(registrationControllerProvider.notifier).clearError();
    } else {
      ref.read(passwordResetControllerProvider.notifier).clearError();
    }
  }

  Future<void> _verify(String code) async {
    if (code.length < AppConfig.smsCodeLength) return;
    if (widget.flow == SmsFlow.register) {
      // При успехе роутер сам откроет сканер (статус сессии изменится).
      final ok =
          await ref.read(registrationControllerProvider.notifier).verify(code);
      if (!ok) _codeController.clear();
    } else {
      final ok =
          await ref.read(passwordResetControllerProvider.notifier).verify(code);
      if (!mounted) return;
      if (ok) {
        context.pushReplacement('/reset-password');
      } else {
        _codeController.clear();
      }
    }
  }

  Future<void> _resend() async {
    final ok = widget.flow == SmsFlow.register
        ? await ref.read(registrationControllerProvider.notifier).resend()
        : await ref.read(passwordResetControllerProvider.notifier).resend();
    if (ok) {
      _codeController.clear();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SmsFlowState flow = widget.flow == SmsFlow.register
        ? ref.watch(registrationControllerProvider)
        : ref.watch(passwordResetControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Подтверждение'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),  
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Введите код из SMS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Отправили его на номер\n${formatPhone(flow.phone)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            PinCodeField(
              length: AppConfig.smsCodeLength,
              controller: _codeController,
              hasError: flow.error != null,
              enabled: !flow.verifying && flow.attemptsLeft > 0,
              onChanged: (_) {
                if (flow.error != null) _clearError();
              },
              onCompleted: _verify,
            ),
            ErrorBanner(message: flow.error),
            if (flow.attemptsLeft < AppConfig.smsMaxAttempts &&
                flow.attemptsLeft > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Осталось попыток: ${flow.attemptsLeft}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (flow.verifying)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Отправить код повторно через $_secondsLeft с',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: flow.sending ? null : _resend,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Отправить код повторно'),
                      ),
              ),
            if (flow.attemptsLeft <= 0) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Запросить новый код',
                loading: flow.sending,
                onPressed: _resend,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
