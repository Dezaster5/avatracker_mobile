import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Политика конфиденциальности из единого публикуемого файла.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static final Future<String> _policy =
      rootBundle.loadString('PRIVACY_POLICY.txt');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Политика конфиденциальности'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _policy,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Не удалось загрузить Политику конфиденциальности'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _PolicyDocument(text: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _PolicyDocument extends StatelessWidget {
  const _PolicyDocument({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: paragraphs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final paragraph = paragraphs[index];
        final isDocumentTitle = index < 2;
        final isSectionTitle = RegExp(r'^\d+\.\s+[А-ЯЁ]').hasMatch(paragraph);
        final isSubheading = const {
          'Идентификационные данные',
          'Кадровые сведения',
          'Данные учета рабочего времени',
          'Геолокационные данные',
          'Биометрические персональные данные',
          'Изображение с камеры',
          'Технические данные',
        }.contains(paragraph);

        return SelectableText(
          paragraph,
          textAlign: isDocumentTitle ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: isDocumentTitle || isSectionTitle || isSubheading
                ? AppColors.navy
                : AppColors.textSecondary,
            fontSize: isDocumentTitle ? 17 : 14,
            fontWeight: isDocumentTitle || isSectionTitle || isSubheading
                ? FontWeight.w700
                : FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
        );
      },
    );
  }
}
