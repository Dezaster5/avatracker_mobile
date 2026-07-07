import 'package:flutter/material.dart';

import '../../router/app_router.dart' show rootNavigatorKey;
import '../config/app_config.dart';
import 'dev_tools_screen.dart';

/// Плавающая шестерёнка поверх всех экранов приложения (auth-флоу, табы,
/// диалоги) — открывает [DevToolsScreen]. Оборачивает `MaterialApp.builder`,
/// поэтому не требует правок в каждом отдельном экране. Нет-оп, если
/// [AppConfig.devToolsEnabled] выключен.
class DevToolsOverlay extends StatefulWidget {
  const DevToolsOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  static const _size = 46.0;
  static const _tapSlop = 8.0;
  Offset? _position;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.devToolsEnabled) return widget.child;

    final screen = MediaQuery.sizeOf(context);
    final position = _position ?? Offset(screen.width - _size - 12, screen.height * 0.6);

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _dragDistance = 0,
            onPanUpdate: (details) {
              _dragDistance += details.delta.distance;
              setState(() {
                final next = position + details.delta;
                _position = Offset(
                  next.dx.clamp(0, screen.width - _size),
                  next.dy.clamp(0, screen.height - _size),
                );
              });
            },
            // onTap конкурирует с onPanUpdate в gesture arena и иногда не
            // срабатывает — открываем по итогу onPanEnd, если движения почти
            // не было (это и есть тап).
            onPanEnd: (_) {
              if (_dragDistance < _tapSlop) {
                rootNavigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => const DevToolsScreen()),
                );
              }
            },
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
