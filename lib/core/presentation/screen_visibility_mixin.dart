import 'package:flutter/widgets.dart';

/// Сообщает экрану, виден ли он пользователю.
///
/// Сигнал — [TickerMode]: Flutter выключает его у экрана, перекрытого
/// непрозрачным маршрутом, а go_router — у неактивных вкладок
/// `StatefulShellRoute`, которые остаются в дереве под `Offstage`. Экран с
/// дорогим ресурсом (камерой) по этому сигналу отпускает его, а не держит
/// работающим за кадром.
mixin ScreenVisibilityMixin<T extends StatefulWidget> on State<T> {
  bool? _visible;

  /// Виден ли экран. Известно после первого `didChangeDependencies`, то есть
  /// не в `initState`.
  bool get isScreenVisible => _visible ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final previous = _visible;
    _visible = visible;
    if (previous != null && previous != visible) {
      onScreenVisibilityChanged(visible);
    }
  }

  /// Экран стал видимым (`true`) или скрылся (`false`). Начальное состояние
  /// не сообщается — его даёт [isScreenVisible].
  void onScreenVisibilityChanged(bool visible);
}
