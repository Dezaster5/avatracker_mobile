import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Короткий доступ к строкам: `context.l10n.login`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsFormatX on AppLocalizations {
  /// 275 → «4 ч 35 мин» в текущей локали.
  String formatDuration(int value) {
    final minutes = value.abs();
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return durationMinutes(remainder);
    if (remainder == 0) return durationHours(hours);
    return durationHoursMinutes(hours, remainder);
  }
}
