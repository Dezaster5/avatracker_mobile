import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers.dart';

/// Экран «Мои данные» (ТЗ 11, 19.7).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Для входа понадобятся номер телефона и пароль'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(authControllerProvider).employee;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои данные')),
      body: employee == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .refreshEmployee();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.blueGradient,
                      ),
                      child: CircleAvatar(
                        radius: 47,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 43,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          foregroundImage: employee.hasPhoto
                              ? NetworkImage(employee.photoUrl!)
                              : null,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      employee.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (employee.position != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        employee.position!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Center(
                    child: StatusChip(
                      label: employee.active ? 'Активен' : 'Неактивен',
                      color: employee.active
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Column(
                        children: [
                          _ProfileRow(
                            icon: Icons.badge_outlined,
                            label: 'ИИН',
                            value: employee.iin,
                          ),
                          _ProfileRow(
                            icon: Icons.phone_iphone_rounded,
                            label: 'Телефон',
                            value: employee.phone != null
                                ? formatPhone(employee.phone!)
                                : null,
                          ),
                          _ProfileRow(
                            icon: Icons.work_outline_rounded,
                            label: 'Должность',
                            value: employee.position,
                          ),
                          _ProfileRow(
                            icon: Icons.groups_outlined,
                            label: 'Отдел',
                            value: employee.division,
                          ),
                          _ProfileRow(
                            icon: Icons.apartment_rounded,
                            label: 'Организация',
                            value: employee.organization,
                          ),
                          _ProfileRow(
                            icon: Icons.attractions_rounded,
                            label: 'Парк / филиал',
                            value: employee.parkName ??
                                (employee.parkId != null
                                    ? 'Парк №${employee.parkId}'
                                    : null),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_outline_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          title: const Text(
                            'Сменить пароль',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.navy,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary),
                          onTap: () => context.push('/change-password'),
                        ),
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.outline),
                        ListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(20)),
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: AppColors.danger, size: 20),
                          ),
                          title: const Text(
                            'Выйти из аккаунта',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.danger,
                            ),
                          ),
                          onTap: () => _confirmLogout(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Column(
                        children: const [
                          BrandMark(size: 26),
                          SizedBox(height: 6),
                          Text(
                            'AvaTracker Mobile v0.2.0',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  (value == null || value!.isEmpty) ? '—' : value!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.outline),
      ],
    );
  }
}
