import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/active_employee_guard.dart';
import '../domain/usecases/change_password.dart';
import '../domain/usecases/confirm_registration.dart';
import '../domain/usecases/delete_account.dart';
import '../domain/usecases/refresh_profile.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/request_registration_code.dart';
import '../domain/usecases/resend_registration_code.dart';
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/restore_session.dart';
import '../domain/usecases/sign_in.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/verify_password_reset_code.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(apiClientProvider).dio),
    local: AuthLocalDataSource(
      tokens: ref.watch(tokenStorageProvider),
      storage: ref.watch(secureStorageProvider),
    ),
  );
});

final _activeEmployeeGuardProvider = Provider(
  (ref) => ActiveEmployeeGuard(ref.watch(authRepositoryProvider)),
);

final restoreSessionProvider = Provider(
  (ref) => RestoreSession(ref.watch(authRepositoryProvider)),
);

final signInProvider = Provider(
  (ref) => SignIn(
    ref.watch(authRepositoryProvider),
    ref.watch(_activeEmployeeGuardProvider),
  ),
);

final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final requestRegistrationCodeProvider = Provider(
  (ref) => RequestRegistrationCode(
    ref.watch(authRepositoryProvider),
    privacyPolicyVersion: AppConfig.privacyPolicyVersion,
  ),
);

final resendRegistrationCodeProvider = Provider(
  (ref) => ResendRegistrationCode(ref.watch(authRepositoryProvider)),
);

final confirmRegistrationProvider = Provider(
  (ref) => ConfirmRegistration(
    ref.watch(authRepositoryProvider),
    ref.watch(_activeEmployeeGuardProvider),
  ),
);

final requestPasswordResetProvider = Provider(
  (ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)),
);

final verifyPasswordResetCodeProvider = Provider(
  (ref) => VerifyPasswordResetCode(ref.watch(authRepositoryProvider)),
);

final resetPasswordProvider = Provider(
  (ref) => ResetPassword(ref.watch(authRepositoryProvider)),
);

final changePasswordProvider = Provider(
  (ref) => ChangePassword(ref.watch(authRepositoryProvider)),
);

final refreshProfileProvider = Provider(
  (ref) => RefreshProfile(
    ref.watch(authRepositoryProvider),
    ref.watch(_activeEmployeeGuardProvider),
  ),
);

final deleteAccountProvider = Provider(
  (ref) => DeleteAccount(ref.watch(authRepositoryProvider)),
);
