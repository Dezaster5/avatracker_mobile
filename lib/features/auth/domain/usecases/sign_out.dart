import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Выход с отзывом постоянного ключа; настройки устройства остаются.
final class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.logout();
}
