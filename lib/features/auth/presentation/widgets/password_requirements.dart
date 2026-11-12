import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/widgets/requirement_list.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../domain/policies/password_policy.dart';

/// Подсказки под новым паролем: правила [PasswordPolicy] и совпадение
/// с подтверждением. Пересчитываются на каждый ввод в любое из двух полей;
/// перестраивается только список, а не весь экран.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({
    super.key,
    required this.password,
    required this.confirmation,
  });

  /// Значение нового пароля — обычно контроллер его поля.
  final ValueListenable<TextEditingValue> password;

  /// Значение поля подтверждения.
  final ValueListenable<TextEditingValue> confirmation;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([password, confirmation]),
      builder: (context, _) =>
          RequirementList(requirements: _requirements(context.l10n)),
    );
  }

  List<Requirement> _requirements(AppLocalizations l10n) {
    final value = password.value.text;
    final repeated = confirmation.value.text;
    return [
      // Пустое поле не выполняет правила заранее: «без пробелов» у пустой
      // строки формально верно, но галочка до ввода сбивает с толку.
      for (final rule in PasswordPolicy.rules)
        Requirement(
          l10n._passwordRule(rule),
          met: value.isNotEmpty && rule.isSatisfiedBy(value),
        ),
      Requirement(
        l10n.passwordsMatch,
        met: repeated.isNotEmpty && repeated == value,
      ),
    ];
  }
}

extension on AppLocalizations {
  /// Подпись правила на языке интерфейса. Новое правило в [PasswordRule]
  /// без подписи здесь не скомпилируется.
  String _passwordRule(PasswordRule rule) => switch (rule) {
        MinLengthRule(:final length) => passwordRuleMinLength(length),
        NoSpacesRule() => passwordRuleNoSpaces,
      };
}
