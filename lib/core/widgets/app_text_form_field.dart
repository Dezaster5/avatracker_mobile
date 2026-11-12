import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Текстовое поле форм приложения с единым правилом показа ошибок:
/// - пока человек печатает в поле без ошибки, ошибку не показываем;
/// - ушёл с поля, в котором что-то вводил, — поле проверяется;
///   пустое нетронутое поле проверит отправка формы;
/// - поле с ошибкой перепроверяется на каждый символ: ошибка уходит,
///   как только значение стало верным.
///
/// Поля пароля, телефона и ИИН построены на нём, поэтому правило одинаково
/// во всех формах и его нельзя забыть подключить.
class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  /// Проверяем поле, из которого ушли, только если в нём что-то вводили.
  /// Встроенный `AutovalidateMode.onUnfocus` не подходит: он показывает
  /// ошибку и в поле, которое просто пролистали.
  void _handleFocusChange(bool hasFocus) {
    final field = _fieldKey.currentState;
    if (!hasFocus && field != null && field.hasInteractedByUser) {
      field.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _handleFocusChange,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        // Пока ошибка видна, поле перепроверяется на каждый ввод.
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        decoration: widget.decoration,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        autofocus: widget.autofocus,
        onFieldSubmitted: widget.onFieldSubmitted,
      ),
    );
  }
}
