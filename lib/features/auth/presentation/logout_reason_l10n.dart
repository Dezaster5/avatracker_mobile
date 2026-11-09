import '../../../l10n/app_localizations.dart';
import '../domain/entities/session_restoration.dart';

extension LogoutReasonL10n on AppLocalizations {
  String logoutReasonMessage(LogoutReason reason) => switch (reason) {
        LogoutReason.sessionExpired => errorSessionExpired,
        LogoutReason.employeeInactive => errorEmployeeInactive,
        LogoutReason.employeeNotFound => errorEmployeeNotFound,
        LogoutReason.accountDeleted => accountDeleted,
      };
}
