import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/l10n_ext.dart';
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
  void initState() {
    super.initState();
    // changePasswordControllerProvider не autoDispose — без сброса ошибка
    // прошлой попытки смены пароля осталась бы висеть при повторном заходе.
    Future.microtask(
      () => ref.read(changePasswordControllerProvider.notifier).clearError(),
    );
  }

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
        ..showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = ref.watch(changePasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePasswordTitle),
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
                      FieldLabel(l10n.currentPassword),
                      PasswordField(
                        controller: _currentController,
                        hint: l10n.enterCurrentPassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) => (value == null || value.isEmpty)
                            ? l10n.enterCurrentPassword
                            : null,
                      ),
                      const SizedBox(height: 18),
                      FieldLabel(l10n.newPasswordLabel),
                      PasswordField(
                        controller: _passwordController,
                        hint: l10n.passwordMinHint,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) => isValidPassword(value ?? '')
                            ? null
                            : l10n.validatorPassword,
                      ),
                      const SizedBox(height: 18),
                      FieldLabel(l10n.confirmNewPassword),
                      PasswordField(
                        controller: _confirmController,
                        hint: l10n.repeatPassword,
                        validator: (value) => value == _passwordController.text
                            ? null
                            : l10n.validatorPasswordsMatch,
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
              ErrorBanner(message: change.error),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.actionSave,
                icon: Icons.check_rounded,
                loading: change.saving,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.changePasswordSessionNote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
