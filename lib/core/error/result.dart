import 'failure.dart';

/// Итог операции: значение или [Failure]. Исключения не выходят за пределы
/// data-слоя — use cases и контроллеры обрабатывают ошибки явно.
sealed class Result<T> {
  const Result();

  /// Значение, а при ошибке — [Failure] как исключение. Для `FutureProvider`,
  /// где ошибка должна попасть в `AsyncValue.error`.
  T getOrThrow() => switch (this) {
        Success(:final value) => value,
        Failed(:final failure) => throw failure,
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}
