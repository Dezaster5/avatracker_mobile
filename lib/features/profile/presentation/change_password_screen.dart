import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers.dart';

/// Смена пароля из профиля: текущий пароль + новый + подтверждение.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(changePasswordControllerProvider.notifier).change(
          currentPassword: _currentController.text,
          newPassword: _passwordController.text,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Пароль изменен')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = ref.watch(changePasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сменить пароль'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Текущий пароль'),
                      PasswordField(
                        controller: _currentController,
                        hint: 'Введите текущий пароль',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Введите текущий пароль'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      const FieldLabel('Новый пароль'),
                      PasswordField(
                        controller: _passwordController,
                        hint: 'Минимум 6 символов',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (!isValidPassword(value ?? '')) {
                            return 'Пароль: минимум 6 символов, без пробелов';
                          }
                          if (value == _currentController.text) {
                            return 'Новый пароль совпадает с текущим';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const FieldLabel('Подтвердите новый пароль'),
                      PasswordField(
                        controller: _confirmController,
                        hint: 'Повторите новый пароль',
                        validator: (value) => value == _passwordController.text
                            ? null
                            : 'Пароли не совпадают',
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
              ErrorBanner(message: change.error),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Сохранить',
                icon: Icons.check_rounded,
                loading: change.saving,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              const Text(
                'После смены пароля текущая сессия останется активной. '
                'Для входа на других устройствах используйте новый пароль.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
