// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'AvaTracker';

  @override
  String get appTagline => 'Учет рабочего времени';

  @override
  String get actionContinue => 'Продолжить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionUnderstood => 'Понятно';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get errorConnection => 'Ошибка соединения. Попробуйте позже';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get loginWelcome => 'Добро пожаловать!';

  @override
  String get loginSubtitle => 'Войдите по номеру телефона и паролю';

  @override
  String get fieldPhone => 'Номер телефона';

  @override
  String get fieldPassword => 'Пароль';

  @override
  String get passwordHint => 'Введите пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get login => 'Войти';

  @override
  String get firstTimeHere => 'Впервые здесь?';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get validatorPhone => 'Введите корректный номер телефона';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get createAccount => 'Создайте аккаунт сотрудника';

  @override
  String get registerSubtitle =>
      'Введите телефон, идентификационный номер и пароль. Код подтверждения придёт по SMS.';

  @override
  String get fieldIin => 'ИИН';

  @override
  String get iinHint => '12 цифр';

  @override
  String get iinExplanation =>
      'Нужен только для проверки сотрудника в AvaTracker.';

  @override
  String get fieldPinfl => 'ПИНФЛ';

  @override
  String get pinflHint => '14 цифр';

  @override
  String get pinflExplanation =>
      'Нужен только для проверки сотрудника в AvaTracker.';

  @override
  String get passwordMinHint => 'Минимум 6 символов';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get repeatPassword => 'Повторите пароль';

  @override
  String get getSmsCode => 'Получить SMS-код';

  @override
  String get haveAccount => 'У меня уже есть аккаунт';

  @override
  String get consentCheckbox =>
      'Я ознакомлен(а) с Политикой конфиденциальности и даю согласие на обработку персональных данных для учёта рабочего времени, проверки активности сотрудника и фиксации отметок прихода/ухода.';

  @override
  String get validatorIin => 'ИИН должен содержать 12 цифр';

  @override
  String get validatorPinfl => 'Введите ПИНФЛ';

  @override
  String get validatorPassword => 'Пароль: минимум 6 символов, без пробелов';

  @override
  String get validatorPasswordsMatch => 'Пароли не совпадают';

  @override
  String get confirmation => 'Подтверждение';

  @override
  String get enterSmsCode => 'Введите код из SMS';

  @override
  String get sentToNumber => 'Отправили его на номер';

  @override
  String attemptsLeft(int count) {
    return 'Осталось попыток: $count';
  }

  @override
  String resendIn(int seconds) {
    return 'Отправить код повторно через $seconds с';
  }

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get requestNewCode => 'Запросить новый код';

  @override
  String get resetTitle => 'Сброс пароля';

  @override
  String get forgotTitle => 'Забыли пароль?';

  @override
  String get forgotSubtitle =>
      'Укажите номер телефона аккаунта — пришлём SMS с кодом для сброса';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get newPasswordTitle => 'Новый пароль';

  @override
  String get newPasswordHeading => 'Придумайте новый пароль';

  @override
  String get codeConfirmedFor => 'Код подтверждён для номера';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get savePassword => 'Сохранить пароль';

  @override
  String get passwordChangedLogin => 'Пароль изменён. Войдите с новым паролем';

  @override
  String get changePasswordTitle => 'Сменить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get enterCurrentPassword => 'Введите текущий пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get tabScanner => 'Сканер';

  @override
  String get tabTimesheet => 'Табель';

  @override
  String get tabAnalytics => 'Аналитика';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get myData => 'Мои данные';

  @override
  String get statusActive => 'Активен';

  @override
  String get statusInactive => 'Неактивен';

  @override
  String get about => 'О приложении';

  @override
  String get language => 'Язык';

  @override
  String get logout => 'Выйти из аккаунта';

  @override
  String get aboutSubtitle =>
      'Корпоративное приложение для учёта рабочего времени сотрудников';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get consentMenu => 'Согласие на обработку данных';

  @override
  String get support => 'Связаться с поддержкой';

  @override
  String get supportBody => 'По вопросам работы приложения и обработки данных:';

  @override
  String get writeEmail => 'Написать письмо';

  @override
  String get deleteAccountMenu => 'Запросить удаление аккаунта';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get languageUzbek => 'Oʻzbekcha';

  @override
  String get chooseCountry => 'Выберите страну';

  @override
  String get actionSelect => 'Выбрать';

  @override
  String get actionOpenSettings => 'Открыть настройки приложения';

  @override
  String get scanQrTitle => 'Отметка по QR-коду';

  @override
  String get pointCameraAtQr => 'Наведите камеру на QR-код';

  @override
  String get within50m =>
      'Вы должны находиться в радиусе 50 м от точки отметки';

  @override
  String get stageCheckingPoint => 'Проверка точки отметки…';

  @override
  String get stageCheckingFace => 'Проверка лица…';

  @override
  String get stageCheckingLocation => 'Проверка геолокации…';

  @override
  String get stageSendingMark => 'Отправка отметки…';

  @override
  String get pointDisabled => 'Эта точка отметки отключена';

  @override
  String get qrNotRegistered => 'QR-код не зарегистрирован в системе';

  @override
  String qrCodeValue(String code) {
    return 'Код из QR: «$code»';
  }

  @override
  String get noServerConnection => 'Нет соединения с сервером';

  @override
  String get cameraStartFailed => 'Не удалось запустить камеру';

  @override
  String get cameraNoAccess => 'Нет доступа к камере';

  @override
  String get cameraCloseOthers =>
      'Закройте другие приложения, использующие камеру, и нажмите «Повторить»';

  @override
  String get cameraGrantAccess =>
      'Разрешите доступ к камере в настройках приложения, чтобы сканировать QR-коды';

  @override
  String get identityCheck => 'Проверка личности';

  @override
  String identityCheckName(String name) {
    return '$name, подтвердите личность';
  }

  @override
  String get photoVerifyBeforeScan =>
      'Фото-верификация перед каждой QR-отметкой';

  @override
  String get lookAtCamera => 'Посмотрите в камеру';

  @override
  String get photoComparedNote =>
      'Снимок сравнивается с вашим фото в системе AvaTracker и используется только для подтверждения личности';

  @override
  String get confirmAndContinue => 'Подтвердить и продолжить';

  @override
  String get noEmployeePhoto => 'В системе отсутствует фото сотрудника';

  @override
  String get noEmployeePhotoNote =>
      'Отметка невозможна. Обратитесь к администратору, чтобы добавить фото в AvaTracker.';

  @override
  String get backToScanner => 'Вернуться к сканеру';

  @override
  String get faceAttemptsExceeded =>
      'Превышено количество попыток проверки лица';

  @override
  String get scanQrTryAgain => 'Отсканируйте QR-код и попробуйте снова';

  @override
  String get photoCaptureFailed =>
      'Не удалось сделать снимок. Попробуйте ещё раз';

  @override
  String get markAccepted => 'Отметка засчитана';

  @override
  String get markNotAccepted => 'Отметка не засчитана';

  @override
  String get resultLocation => 'Локация';

  @override
  String get resultDistance => 'Расстояние до точки';

  @override
  String get resultTime => 'Время';

  @override
  String get markCheckIn => 'Приход';

  @override
  String get markCheckOut => 'Уход';

  @override
  String get markPresence => 'Проверка присутствия';

  @override
  String get latesThisMonth => 'Опозданий за месяц';

  @override
  String get redMarksLate => 'Оранжевым отмечены дни опозданий';

  @override
  String get cameAt => 'Пришёл';

  @override
  String get bySchedule => 'По графику';

  @override
  String get latenessLabel => 'Опоздание';

  @override
  String get dayNotYet => 'Ещё не наступило';

  @override
  String get dayNoLate => 'Без опозданий';

  @override
  String get dayNotArrivedYet => 'День ещё не наступил';

  @override
  String get noLatenessThisDay => 'Опозданий за этот день не зафиксировано';

  @override
  String get dayOnTime => 'Вовремя';

  @override
  String get dayAbsent => 'Пропуск';

  @override
  String get dayWeekend => 'Выходной';

  @override
  String get dayWeekendWork => 'Работа в выходной';

  @override
  String get dayNoMarks => 'Нет отметок';

  @override
  String get dayNoData => 'Нет данных';

  @override
  String get timesheetNoDayData => 'Данные за этот день отсутствуют';

  @override
  String get notMarked => 'Не отмечено';

  @override
  String scheduleName(String name) {
    return 'График $name';
  }

  @override
  String scheduleStart(String time) {
    return 'начало в $time';
  }

  @override
  String latenessAverage(String avg) {
    return 'в среднем $avg';
  }

  @override
  String latenessMax(String max) {
    return 'макс $max';
  }

  @override
  String get labelIin => 'ИИН';

  @override
  String get labelPhone => 'Телефон';

  @override
  String get labelPosition => 'Должность';

  @override
  String get labelDivision => 'Отдел';

  @override
  String get labelPark => 'Парк / филиал';

  @override
  String get analyticsWeek => 'Неделя';

  @override
  String get analyticsMonth => 'Месяц';

  @override
  String get countryKazakhstan => 'Казахстан';

  @override
  String get countryUzbekistan => 'Узбекистан';

  @override
  String get logoutConfirmMessage =>
      'Для входа понадобятся номер телефона и пароль';

  @override
  String parkNumber(int number) {
    return 'Парк №$number';
  }

  @override
  String get changePasswordSessionNote =>
      'После смены пароля текущая сессия останется активной. Для входа на других устройствах используйте новый пароль.';

  @override
  String get actionEnableLocation => 'Включить геолокацию';

  @override
  String get locationEnableGps => 'Включите геолокацию (GPS) на устройстве';

  @override
  String get locationPermissionRequired =>
      'Разрешите доступ к геолокации для отметки';

  @override
  String get locationUnavailable =>
      'Не удалось определить геолокацию. Попробуйте ещё раз';

  @override
  String get locationMocked =>
      'Обнаружена поддельная геолокация. Отметка запрещена';

  @override
  String locationLowAccuracy(int accuracy) {
    return 'Низкая точность GPS (±$accuracy м). Выйдите на открытое место и попробуйте снова';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters м';
  }

  @override
  String distanceWithLimit(int distance, int limit) {
    return '$distance м ($limit м)';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String durationHours(int hours) {
    return '$hours ч';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get previousPeriod => 'Предыдущий период';

  @override
  String get nextPeriod => 'Следующий период';

  @override
  String get analyticsLatenessForWeek => 'Опоздания за неделю';

  @override
  String get analyticsLatenessForMonth => 'Опоздания за месяц';

  @override
  String get analyticsNoLateness => 'За выбранный период опозданий нет';

  @override
  String analyticsSummary(String total, String average) {
    return 'Суммарно $total · в среднем $average';
  }

  @override
  String get analyticsSourceNote =>
      'Данные берутся из времени первой отметки сотрудника относительно начала смены';

  @override
  String get workSchedule => 'График работы';

  @override
  String latenessCases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count случая',
      many: '$count случаев',
      few: '$count случая',
      one: '$count случай',
      zero: '0 случаев',
    );
    return '$_temp0';
  }

  @override
  String get metricCases => 'случаев';

  @override
  String get metricTotal => 'суммарно';

  @override
  String get metricAverage => 'в среднем';

  @override
  String get metricMax => 'макс. опоздание';

  @override
  String maxLateness(String duration) {
    return 'Максимальное опоздание: $duration';
  }

  @override
  String get latenessHistory => 'История опозданий';

  @override
  String plannedArrival(String planned, String actual) {
    return 'План $planned · приход $actual';
  }

  @override
  String get errorSessionExpired => 'Сессия истекла. Войдите заново';

  @override
  String get errorEmployeeInactive => 'Доступ запрещён. Сотрудник неактивен';

  @override
  String get errorEmployeeNotFound => 'Сотрудник не найден в системе';

  @override
  String get errorEmployeeDataMissing => 'Нет данных сотрудника';

  @override
  String get errorInvalidServerResponse => 'Неверный формат ответа сервера';

  @override
  String get errorTimesheetUnavailable => 'Табель пока недоступен';

  @override
  String get errorResetTokenMissing => 'Сервер не вернул токен сброса';

  @override
  String get errorLoginFailed => 'Не удалось войти';

  @override
  String get errorAttemptsExceeded =>
      'Превышено количество попыток. Запросите новый код';

  @override
  String get errorConfirmSmsFirst => 'Сначала подтвердите SMS-код';

  @override
  String get deleteAccountTitle => 'Удаление аккаунта';

  @override
  String get deleteAccountAction => 'Удалить аккаунт';

  @override
  String get deleteConfirmTitle => 'Удалить аккаунт?';

  @override
  String get deleteConfirmBody =>
      'Подтвердите удаление аккаунта приложения. Для повторного входа потребуется новая регистрация.';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get accountDeleted => 'Аккаунт удалён. Зарегистрируйтесь заново';
}
