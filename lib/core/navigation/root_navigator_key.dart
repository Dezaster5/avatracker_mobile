import 'package:flutter/widgets.dart';

/// Ключ корневого `Navigator`, созданного go_router. `MaterialApp.builder`
/// (см. `DevToolsOverlay`) рисуется НАД этим навигатором, а не под ним, поэтому
/// `Navigator.of(context)` из builder'а его не находит — берём напрямую по ключу.
final rootNavigatorKey = GlobalKey<NavigatorState>();
