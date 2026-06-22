import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers.dart';

/// Регистрация: телефон + ИИН + пароль, подтверждение SMS-кодом (ТЗ 3.1, 19.2).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _iinController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(registrationControllerProvider.notifier).sendCode(
          phone: normalizePhone(_phoneController.text),
          iin: _iinController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted) context.push('/sms-register');
  }

  @override
  Widget build(BuildContext context) {
    final registration = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Регистрация'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              const SizedBox(height: 8),
              const Text(
                'Создайте аккаунт сотрудника',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Данные проверяются по базе сотрудников AvaTracker. '
                'На указанный номер придет SMS с кодом подтверждения.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel('Номер телефона'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '+7 700 000 00 00',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, size: 22),
                ),
                validator: (value) => isValidKzPhone(value ?? '')
                    ? null
                    : 'Введите номер в формате +7 XXX XXX XX XX',
              ),
              const SizedBox(height: 18),
              const FieldLabel('ИИН'),
              TextFormField(
                controller: _iinController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: const InputDecoration(
                  hintText: '12 цифр',
                  prefixIcon: Icon(Icons.badge_outlined, size: 22),
                ),
                validator: (value) => isValidIin((value ?? '').trim())
                    ? null
                    : 'ИИН должен содержать 12 цифр',
              ),
              const SizedBox(height: 18),
              const FieldLabel('Пароль'),
              PasswordField(
                controller: _passwordController,
                hint: 'Минимум 6 символов',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => isValidPassword(value ?? '')
                    ? null
                    : 'Пароль: минимум 6 символов, без пробелов',
              ),
              const SizedBox(height: 18),
              const FieldLabel('Подтвердите пароль'),
              PasswordField(
                controller: _confirmController,
                hint: 'Повторите пароль',
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Пароли не совпадают',
                onSubmitted: (_) => _submit(),
              ),
              ErrorBanner(message: registration.error),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Получить SMS-код',
                icon: Icons.sms_outlined,
                loading: registration.sending,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('У меня уже есть аккаунт'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
