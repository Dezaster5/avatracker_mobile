import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Сегментированный ввод SMS-кода: ячейки по цифре, скрытое текстовое поле,
/// автопереход и анимация «тряски» при ошибке.
class PinCodeField extends StatefulWidget {
  const PinCodeField({
    super.key,
    required this.length,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
  });

  final int length;
  final TextEditingController? controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(PinCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shake.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
    final text = _controller.text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final activeIndex = text.length.clamp(0, widget.length - 1);
    final focused = _focusNode.hasFocus;

    return GestureDetector(
      onTap: widget.enabled
          ? () => FocusScope.of(context).requestFocus(_focusNode)
          : null,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          // Затухающая синусоида: смещение по горизонтали до 8 px.
          final progress = _shake.value;
          final offset = math.sin(progress * math.pi * 5) * (1 - progress) * 8;
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },
        child: Stack(
          children: [
            // Невидимое реальное поле ввода: держит клавиатуру и значение.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _PinBox(
                    char: i < text.length ? text[i] : null,
                    isActive: widget.enabled &&
                        focused &&
                        i == activeIndex &&
                        text.length < widget.length,
                    hasError: widget.hasError,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({this.char, required this.isActive, required this.hasError});

  final String? char;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.danger
        : isActive
            ? AppColors.primary
            : char != null
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 56,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: char == null
            ? (isActive
                ? Container(
                    key: const ValueKey('cursor'),
                    width: 2,
                    height: 26,
                    color: AppColors.primary,
                  )
                : const SizedBox.shrink(key: ValueKey('empty')))
            : Text(
                char!,
                key: ValueKey('char_$char'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
      ),
    );
  }
}
