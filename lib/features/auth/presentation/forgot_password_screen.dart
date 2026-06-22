import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

/// Сброс пароля, шаг 1: ввод номера — отправляем SMS-код.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(passwordResetControllerProvider.notifier)
        .sendCode(normalizePhone(_phoneController.text));
    if (ok && mounted) context.push('/sms-reset');
  }

  @override
  Widget build(BuildContext context) {
    final reset = ref.watch(passwordResetControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Сброс пароля'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Забыли пароль?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Укажите номер телефона аккаунта —\nпришлем SMS с кодом для сброса',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const FieldLabel('Номер телефона'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '+7 700 000 00 00',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, size: 22),
                ),
                validator: (value) => isValidKzPhone(value ?? '')
                    ? null
                    : 'Введите номер в формате +7 XXX XXX XX XX',
                onFieldSubmitted: (_) => _submit(),
              ),
              ErrorBanner(message: reset.error),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Отправить код',
                icon: Icons.sms_outlined,
                loading: reset.sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
