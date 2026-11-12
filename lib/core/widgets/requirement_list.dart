import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Пункт требования к вводу: подпись и выполнено ли условие.
@immutable
class Requirement {
  const Requirement(this.label, {required this.met});

  final String label;
  final bool met;
}

/// Требования под полем ввода: серые пункты зеленеют, когда условие
/// выполнено. Виджет только рисует список; что и когда пересчитывать,
/// решает тот, кто его строит.
class RequirementList extends StatelessWidget {
  const RequirementList({super.key, required this.requirements});

  final List<Requirement> requirements;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final requirement in requirements) _RequirementRow(requirement),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow(this.requirement);

  final Requirement requirement;

  @override
  Widget build(BuildContext context) {
    final met = requirement.met;
    final color = met ? AppColors.success : AppColors.textSecondary;
    // Диктор читает пункт как отмеченный или нет; иконка — только для глаз.
    return Semantics(
      container: true,
      checked: met,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(met),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(color: color, fontSize: 12.5, height: 1.3),
                child: Text(requirement.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
