// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'AvaTracker';

  @override
  String get appTagline => 'Жұмыс уақытын есепке алу';

  @override
  String get actionContinue => 'Жалғастыру';

  @override
  String get actionCancel => 'Болдырмау';

  @override
  String get actionRetry => 'Қайталау';

  @override
  String get actionClose => 'Жабу';

  @override
  String get actionDone => 'Дайын';

  @override
  String get actionUnderstood => 'Түсінікті';

  @override
  String get actionSave => 'Сақтау';

  @override
  String get errorConnection => 'Байланыс қатесі. Кейінірек қайталап көріңіз';

  @override
  String get privacyPolicy => 'Құпиялылық саясаты';

  @override
  String get loginWelcome => 'Қош келдіңіз!';

  @override
  String get loginSubtitle => 'Телефон нөмірі мен құпия сөз арқылы кіріңіз';

  @override
  String get fieldPhone => 'Телефон нөмірі';

  @override
  String get fieldPassword => 'Құпия сөз';

  @override
  String get passwordHint => 'Құпия сөзді енгізіңіз';

  @override
  String get forgotPassword => 'Құпия сөзді ұмыттыңыз ба?';

  @override
  String get login => 'Кіру';

  @override
  String get firstTimeHere => 'Алғаш рет пе?';

  @override
  String get register => 'Тіркелу';

  @override
  String get enterPassword => 'Құпия сөзді енгізіңіз';

  @override
  String get validatorPhone => 'Дұрыс телефон нөмірін енгізіңіз';

  @override
  String get registerTitle => 'Тіркелу';

  @override
  String get createAccount => 'Қызметкер аккаунтын жасаңыз';

  @override
  String get registerSubtitle =>
      'Телефонды, сәйкестендіру нөмірін және құпия сөзді енгізіңіз. Растау коды SMS арқылы келеді.';

  @override
  String get fieldIin => 'ЖСН';

  @override
  String get iinHint => '12 сан';

  @override
  String get iinExplanation =>
      'AvaTracker жүйесіндегі қызметкерді тексеру үшін ғана қажет.';

  @override
  String get fieldPinfl => 'ПИНФЛ';

  @override
  String get pinflHint => '14 сан';

  @override
  String get pinflExplanation =>
      'AvaTracker жүйесіндегі қызметкерді тексеру үшін ғана қажет.';

  @override
  String get passwordMinHint => 'Кемінде 6 таңба';

  @override
  String get confirmPassword => 'Құпия сөзді растаңыз';

  @override
  String get repeatPassword => 'Құпия сөзді қайталаңыз';

  @override
  String get getSmsCode => 'SMS кодын алу';

  @override
  String get haveAccount => 'Менде аккаунт бар';

  @override
  String get consentCheckbox =>
      'Мен Құпиялылық саясатымен таныстым және жұмыс уақытын есепке алу, қызметкердің белсенділігін тексеру және келу/кету белгілерін тіркеу үшін дербес деректерді өңдеуге келісім беремін.';

  @override
  String get validatorIin => 'ЖСН 12 саннан тұруы керек';

  @override
  String get validatorPinfl => 'ПИНФЛ енгізіңіз';

  @override
  String get validatorPassword => 'Құпия сөз: кемінде 6 таңба, бос орынсыз';

  @override
  String get validatorPasswordsMatch => 'Құпия сөздер сәйкес келмейді';

  @override
  String get confirmation => 'Растау';

  @override
  String get enterSmsCode => 'SMS-тен келген кодты енгізіңіз';

  @override
  String get sentToNumber => 'Оны мына нөмірге жібердік';

  @override
  String attemptsLeft(int count) {
    return 'Қалған әрекеттер: $count';
  }

  @override
  String resendIn(int seconds) {
    return 'Кодты қайта жіберу $seconds с кейін';
  }

  @override
  String get resendCode => 'Кодты қайта жіберу';

  @override
  String get requestNewCode => 'Жаңа код сұрау';

  @override
  String get resetTitle => 'Құпия сөзді қалпына келтіру';

  @override
  String get forgotTitle => 'Құпия сөзді ұмыттыңыз ба?';

  @override
  String get forgotSubtitle =>
      'Аккаунттың телефон нөмірін көрсетіңіз — қалпына келтіру коды бар SMS жібереміз';

  @override
  String get sendCode => 'Кодты жіберу';

  @override
  String get newPasswordTitle => 'Жаңа құпия сөз';

  @override
  String get newPasswordHeading => 'Жаңа құпия сөз ойлап табыңыз';

  @override
  String get codeConfirmedFor => 'Код мына нөмір үшін расталды';

  @override
  String get newPasswordLabel => 'Жаңа құпия сөз';

  @override
  String get savePassword => 'Құпия сөзді сақтау';

  @override
  String get passwordChangedLogin =>
      'Құпия сөз өзгертілді. Жаңа құпия сөзбен кіріңіз';

  @override
  String get changePasswordTitle => 'Құпия сөзді өзгерту';

  @override
  String get currentPassword => 'Ағымдағы құпия сөз';

  @override
  String get enterCurrentPassword => 'Ағымдағы құпия сөзді енгізіңіз';

  @override
  String get confirmNewPassword => 'Жаңа құпия сөзді растаңыз';

  @override
  String get passwordChanged => 'Құпия сөз өзгертілді';

  @override
  String get tabScanner => 'Сканер';

  @override
  String get tabTimesheet => 'Табель';

  @override
  String get tabAnalytics => 'Аналитика';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get myData => 'Менің деректерім';

  @override
  String get statusActive => 'Белсенді';

  @override
  String get statusInactive => 'Белсенді емес';

  @override
  String get about => 'Қосымша туралы';

  @override
  String get language => 'Тіл';

  @override
  String get logout => 'Аккаунттан шығу';

  @override
  String get aboutSubtitle =>
      'Қызметкерлердің жұмыс уақытын есепке алуға арналған корпоративтік қосымша';

  @override
  String versionLabel(String version) {
    return 'Нұсқа $version';
  }

  @override
  String get consentMenu => 'Деректерді өңдеуге келісім';

  @override
  String get support => 'Қолдау қызметіне хабарласу';

  @override
  String get supportBody =>
      'Қосымша жұмысы және деректерді өңдеу сұрақтары бойынша:';

  @override
  String get writeEmail => 'Хат жазу';

  @override
  String get deleteAccountMenu => 'Аккаунтты жоюды сұрау';

  @override
  String get chooseLanguage => 'Тілді таңдаңыз';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get languageUzbek => 'Oʻzbekcha';

  @override
  String get chooseCountry => 'Елді таңдаңыз';

  @override
  String get actionSelect => 'Таңдау';

  @override
  String get actionOpenSettings => 'Қосымша баптауларын ашу';

  @override
  String get scanQrTitle => 'QR-код бойынша белгі';

  @override
  String get pointCameraAtQr => 'Камераны QR-кодқа бағыттаңыз';

  @override
  String get within50m => 'Белгі нүктесінен 50 м радиуста болуыңыз керек';

  @override
  String get stageCheckingPoint => 'Белгі нүктесін тексеру…';

  @override
  String get stageCheckingFace => 'Бет тексерілуде…';

  @override
  String get stageCheckingLocation => 'Геолокацияны тексеру…';

  @override
  String get stageSendingMark => 'Белгі жіберілуде…';

  @override
  String get pointDisabled => 'Бұл белгі нүктесі өшірілген';

  @override
  String get qrNotRegistered => 'QR-код жүйеде тіркелмеген';

  @override
  String qrCodeValue(String code) {
    return 'QR коды: «$code»';
  }

  @override
  String get noServerConnection => 'Сервермен байланыс жоқ';

  @override
  String get cameraStartFailed => 'Камераны іске қосу мүмкін болмады';

  @override
  String get cameraNoAccess => 'Камераға рұқсат жоқ';

  @override
  String get cameraCloseOthers =>
      'Камераны пайдаланатын басқа қосымшаларды жабыңыз да, «Қайталау» басыңыз';

  @override
  String get cameraGrantAccess =>
      'QR-кодтарды сканерлеу үшін қосымша баптауларында камераға рұқсат беріңіз';

  @override
  String get identityCheck => 'Тұлғаны тексеру';

  @override
  String identityCheckName(String name) {
    return '$name, тұлғаңызды растаңыз';
  }

  @override
  String get photoVerifyBeforeScan => 'Әр QR-белгіден бұрын фото-верификация';

  @override
  String get lookAtCamera => 'Камераға қараңыз';

  @override
  String get photoComparedNote =>
      'Түсірілім AvaTracker жүйесіндегі фотоңызбен салыстырылады және тек тұлғаны растау үшін пайдаланылады';

  @override
  String get confirmAndContinue => 'Растап, жалғастыру';

  @override
  String get noEmployeePhoto => 'Жүйеде қызметкердің фотосы жоқ';

  @override
  String get noEmployeePhotoNote =>
      'Белгі мүмкін емес. AvaTracker жүйесіне фото қосу үшін әкімшіге хабарласыңыз.';

  @override
  String get backToScanner => 'Сканерге оралу';

  @override
  String get faceAttemptsExceeded =>
      'Бет тексеру әрекеттерінің саны асып кетті';

  @override
  String get scanQrTryAgain => 'QR-кодты сканерлеп, қайта көріңіз';

  @override
  String get photoCaptureFailed =>
      'Түсірілім жасау мүмкін болмады. Қайталап көріңіз';

  @override
  String get markAccepted => 'Белгі есептелді';

  @override
  String get markNotAccepted => 'Белгі есептелмеді';

  @override
  String get resultLocation => 'Локация';

  @override
  String get resultDistance => 'Нүктеге дейінгі қашықтық';

  @override
  String get resultTime => 'Уақыт';

  @override
  String get markCheckIn => 'Келу';

  @override
  String get markCheckOut => 'Кету';

  @override
  String get markPresence => 'Қатысуды тексеру';

  @override
  String get latesThisMonth => 'Айдағы кешігулер';

  @override
  String get redMarksLate => 'Қызғылт сары түспен кешігу күндері белгіленген';

  @override
  String get cameAt => 'Келді';

  @override
  String get bySchedule => 'Кесте бойынша';

  @override
  String get latenessLabel => 'Кешігу';

  @override
  String get dayNotYet => 'Әлі болған жоқ';

  @override
  String get dayNoLate => 'Кешігусіз';

  @override
  String get dayNotArrivedYet => 'Күн әлі келген жоқ';

  @override
  String get noLatenessThisDay => 'Бұл күні кешігу тіркелмеген';

  @override
  String get dayOnTime => 'Уақытында';

  @override
  String get dayAbsent => 'Қатыспау';

  @override
  String get dayWeekend => 'Демалыс күні';

  @override
  String get dayWeekendWork => 'Демалыс күнгі жұмыс';

  @override
  String get dayNoMarks => 'Белгілер жоқ';

  @override
  String get dayNoData => 'Деректер жоқ';

  @override
  String get timesheetNoDayData => 'Бұл күн бойынша деректер жоқ';

  @override
  String get notMarked => 'Белгіленбеген';

  @override
  String scheduleName(String name) {
    return 'Кесте $name';
  }

  @override
  String scheduleStart(String time) {
    return 'басталуы $time';
  }

  @override
  String latenessAverage(String avg) {
    return 'орташа $avg';
  }

  @override
  String latenessMax(String max) {
    return 'макс $max';
  }

  @override
  String get labelIin => 'ЖСН';

  @override
  String get labelPhone => 'Телефон';

  @override
  String get labelPosition => 'Лауазым';

  @override
  String get labelDivision => 'Бөлім';

  @override
  String get labelPark => 'Парк / филиал';

  @override
  String get analyticsWeek => 'Апта';

  @override
  String get analyticsMonth => 'Ай';

  @override
  String get countryKazakhstan => 'Қазақстан';

  @override
  String get countryUzbekistan => 'Өзбекстан';

  @override
  String get logoutConfirmMessage =>
      'Кіру үшін телефон нөмірі мен құпия сөз қажет болады';

  @override
  String parkNumber(int number) {
    return 'Парк №$number';
  }

  @override
  String get changePasswordSessionNote =>
      'Құпия сөз өзгертілгеннен кейін ағымдағы сессия белсенді қалады. Басқа құрылғыларда кіру үшін жаңа құпия сөзді пайдаланыңыз.';

  @override
  String get actionEnableLocation => 'Геолокацияны қосу';

  @override
  String get locationEnableGps => 'Құрылғыда геолокацияны (GPS) қосыңыз';

  @override
  String get locationPermissionRequired =>
      'Белгі қою үшін геолокацияға рұқсат беріңіз';

  @override
  String get locationUnavailable =>
      'Геолокацияны анықтау мүмкін болмады. Қайталап көріңіз';

  @override
  String get locationMocked =>
      'Жалған геолокация анықталды. Белгі қоюға тыйым салынған';

  @override
  String locationLowAccuracy(int accuracy) {
    return 'GPS дәлдігі төмен (±$accuracy м). Ашық жерге шығып, қайта көріңіз';
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
    return '$hours сағ';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours сағ $minutes мин';
  }

  @override
  String get previousPeriod => 'Алдыңғы кезең';

  @override
  String get nextPeriod => 'Келесі кезең';

  @override
  String get analyticsLatenessForWeek => 'Аптадағы кешігулер';

  @override
  String get analyticsLatenessForMonth => 'Айдағы кешігулер';

  @override
  String get analyticsNoLateness => 'Таңдалған кезеңде кешігу жоқ';

  @override
  String analyticsSummary(String total, String average) {
    return 'Барлығы $total · орташа $average';
  }

  @override
  String get analyticsSourceNote =>
      'Деректер ауысымның басталуына қатысты қызметкердің алғашқы белгісінің уақытынан алынады';

  @override
  String get workSchedule => 'Жұмыс кестесі';

  @override
  String latenessCases(int count) {
    return '$count жағдай';
  }

  @override
  String get metricCases => 'жағдай';

  @override
  String get metricTotal => 'барлығы';

  @override
  String get metricAverage => 'орташа';

  @override
  String get metricMax => 'ең ұзақ кешігу';

  @override
  String maxLateness(String duration) {
    return 'Ең ұзақ кешігу: $duration';
  }

  @override
  String get latenessHistory => 'Кешігулер тарихы';

  @override
  String plannedArrival(String planned, String actual) {
    return 'Жоспар $planned · келуі $actual';
  }

  @override
  String get errorSessionExpired => 'Сессия аяқталды. Қайта кіріңіз';

  @override
  String get errorEmployeeInactive =>
      'Қолжетімділікке тыйым салынған. Қызметкер белсенді емес';

  @override
  String get errorEmployeeNotFound => 'Қызметкер жүйеде табылмады';

  @override
  String get errorEmployeeDataMissing => 'Қызметкер деректері жоқ';

  @override
  String get errorInvalidServerResponse => 'Сервер жауабының пішімі қате';

  @override
  String get errorTimesheetUnavailable => 'Табель әзірге қолжетімсіз';

  @override
  String get errorResetTokenMissing =>
      'Сервер қалпына келтіру токенін қайтармады';

  @override
  String get errorLoginFailed => 'Кіру мүмкін болмады';

  @override
  String get errorAttemptsExceeded =>
      'Әрекеттер саны асып кетті. Жаңа код сұраңыз';

  @override
  String get errorConfirmSmsFirst => 'Алдымен SMS кодын растаңыз';

  @override
  String get deleteAccountTitle => 'Аккаунтты жою';

  @override
  String get deleteAccountAction => 'Аккаунтты жою';

  @override
  String get deleteConfirmTitle => 'Аккаунтты жоясыз ба?';

  @override
  String get deleteConfirmBody =>
      'Қосымша аккаунтын жоюды растаңыз. Қайта кіру үшін жаңа тіркелу қажет.';

  @override
  String get actionDelete => 'Жою';

  @override
  String get accountDeleted => 'Аккаунт жойылды. Қайта тіркеліңіз';
}
