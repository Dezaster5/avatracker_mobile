// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'AvaTracker';

  @override
  String get appTagline => 'Ish vaqtini hisobga olish';

  @override
  String get actionContinue => 'Davom etish';

  @override
  String get actionCancel => 'Bekor qilish';

  @override
  String get actionRetry => 'Qayta urinish';

  @override
  String get actionClose => 'Yopish';

  @override
  String get actionDone => 'Tayyor';

  @override
  String get actionUnderstood => 'Tushunarli';

  @override
  String get actionSave => 'Saqlash';

  @override
  String get errorConnection => 'Ulanish xatosi. Keyinroq qayta urinib koʻring';

  @override
  String get privacyPolicy => 'Maxfiylik siyosati';

  @override
  String get loginWelcome => 'Xush kelibsiz!';

  @override
  String get loginSubtitle => 'Telefon raqami va parol bilan kiring';

  @override
  String get fieldPhone => 'Telefon raqami';

  @override
  String get fieldPassword => 'Parol';

  @override
  String get passwordHint => 'Parolni kiriting';

  @override
  String get forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get login => 'Kirish';

  @override
  String get firstTimeHere => 'Birinchi martami?';

  @override
  String get register => 'Roʻyxatdan oʻtish';

  @override
  String get enterPassword => 'Parolni kiriting';

  @override
  String get validatorPhone => 'Toʻgʻri telefon raqamini kiriting';

  @override
  String get registerTitle => 'Roʻyxatdan oʻtish';

  @override
  String get createAccount => 'Xodim hisobini yarating';

  @override
  String get registerSubtitle =>
      'Telefon, IIN va parolni kiriting. Tasdiqlash kodi SMS orqali keladi.';

  @override
  String get fieldIin => 'IIN';

  @override
  String get iinHint => '12 raqam';

  @override
  String get iinExplanation =>
      'Faqat AvaTracker tizimidagi xodimni tekshirish uchun kerak.';

  @override
  String get passwordMinHint => 'Kamida 6 belgi';

  @override
  String get confirmPassword => 'Parolni tasdiqlang';

  @override
  String get repeatPassword => 'Parolni takrorlang';

  @override
  String get getSmsCode => 'SMS kodini olish';

  @override
  String get haveAccount => 'Menda hisob bor';

  @override
  String get consentCheckbox =>
      'Men Maxfiylik siyosati bilan tanishdim va ish vaqtini hisobga olish, xodim faolligini tekshirish hamda kelish/ketish belgilarini qayd etish uchun shaxsiy maʼlumotlarni qayta ishlashga rozilik beraman.';

  @override
  String get validatorIin => 'IIN 12 ta raqamdan iborat boʻlishi kerak';

  @override
  String get validatorPassword => 'Parol: kamida 6 belgi, boʻsh joysiz';

  @override
  String get validatorPasswordsMatch => 'Parollar mos kelmadi';

  @override
  String get confirmation => 'Tasdiqlash';

  @override
  String get enterSmsCode => 'SMS dan kelgan kodni kiriting';

  @override
  String get sentToNumber => 'Uni ushbu raqamga yubordik';

  @override
  String attemptsLeft(int count) {
    return 'Qolgan urinishlar: $count';
  }

  @override
  String resendIn(int seconds) {
    return 'Kodni qayta yuborish $seconds s dan keyin';
  }

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String get requestNewCode => 'Yangi kod soʻrash';

  @override
  String get resetTitle => 'Parolni tiklash';

  @override
  String get forgotTitle => 'Parolni unutdingizmi?';

  @override
  String get forgotSubtitle =>
      'Hisob telefon raqamini kiriting — tiklash kodi bilan SMS yuboramiz';

  @override
  String get sendCode => 'Kodni yuborish';

  @override
  String get newPasswordTitle => 'Yangi parol';

  @override
  String get newPasswordHeading => 'Yangi parol oʻylab toping';

  @override
  String get codeConfirmedFor => 'Kod ushbu raqam uchun tasdiqlandi';

  @override
  String get newPasswordLabel => 'Yangi parol';

  @override
  String get savePassword => 'Parolni saqlash';

  @override
  String get passwordChangedLogin =>
      'Parol oʻzgartirildi. Yangi parol bilan kiring';

  @override
  String get changePasswordTitle => 'Parolni oʻzgartirish';

  @override
  String get currentPassword => 'Joriy parol';

  @override
  String get enterCurrentPassword => 'Joriy parolni kiriting';

  @override
  String get confirmNewPassword => 'Yangi parolni tasdiqlang';

  @override
  String get passwordChanged => 'Parol oʻzgartirildi';

  @override
  String get tabScanner => 'Skaner';

  @override
  String get tabTimesheet => 'Tabel';

  @override
  String get tabAnalytics => 'Tahlil';

  @override
  String get tabProfile => 'Profil';

  @override
  String get myData => 'Mening maʼlumotlarim';

  @override
  String get statusActive => 'Faol';

  @override
  String get statusInactive => 'Faol emas';

  @override
  String get about => 'Ilova haqida';

  @override
  String get language => 'Til';

  @override
  String get logout => 'Hisobdan chiqish';

  @override
  String get aboutSubtitle =>
      'Xodimlarning ish vaqtini hisobga olish uchun korporativ ilova';

  @override
  String versionLabel(String version) {
    return 'Versiya $version';
  }

  @override
  String get consentMenu => 'Maʼlumotlarni qayta ishlashga rozilik';

  @override
  String get support => 'Qoʻllab-quvvatlashga murojaat';

  @override
  String get supportBody =>
      'Ilova ishlashi va maʼlumotlarni qayta ishlash bo‘yicha:';

  @override
  String get writeEmail => 'Xat yozish';

  @override
  String get deleteAccountMenu => 'Hisobni oʻchirishni soʻrash';

  @override
  String get chooseLanguage => 'Tilni tanlang';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get languageUzbek => 'Oʻzbekcha';

  @override
  String get chooseCountry => 'Mamlakatni tanlang';

  @override
  String get actionSelect => 'Tanlash';

  @override
  String get actionOpenSettings => 'Ilova sozlamalarini ochish';

  @override
  String get scanQrTitle => 'QR-kod boʻyicha belgi';

  @override
  String get pointCameraAtQr => 'Kamerani QR-kodga qarating';

  @override
  String get within50m => 'Belgi nuqtasidan 50 m radiusda boʻlishingiz kerak';

  @override
  String get stageCheckingPoint => 'Belgi nuqtasi tekshirilmoqda…';

  @override
  String get stageCheckingFace => 'Yuz tekshirilmoqda…';

  @override
  String get stageCheckingLocation => 'Geolokatsiya tekshirilmoqda…';

  @override
  String get stageSendingMark => 'Belgi yuborilmoqda…';

  @override
  String get pointDisabled => 'Bu belgi nuqtasi oʻchirilgan';

  @override
  String get qrNotRegistered => 'QR-kod tizimda roʻyxatdan oʻtmagan';

  @override
  String qrCodeValue(String code) {
    return 'QR kodi: «$code»';
  }

  @override
  String get noServerConnection => 'Server bilan aloqa yoʻq';

  @override
  String get cameraStartFailed => 'Kamerani ishga tushirib boʻlmadi';

  @override
  String get cameraNoAccess => 'Kameraga ruxsat yoʻq';

  @override
  String get cameraCloseOthers =>
      'Kameradan foydalanayotgan boshqa ilovalarni yoping va «Qayta urinish» ni bosing';

  @override
  String get cameraGrantAccess =>
      'QR-kodlarni skanerlash uchun ilova sozlamalarida kameraga ruxsat bering';

  @override
  String get identityCheck => 'Shaxsni tekshirish';

  @override
  String identityCheckName(String name) {
    return '$name, shaxsingizni tasdiqlang';
  }

  @override
  String get photoVerifyBeforeScan =>
      'Har QR-belgidan oldin foto-verifikatsiya';

  @override
  String get lookAtCamera => 'Kameraga qarang';

  @override
  String get photoComparedNote =>
      'Suratingiz AvaTracker tizimidagi fotongiz bilan solishtiriladi va faqat shaxsni tasdiqlash uchun ishlatiladi';

  @override
  String get confirmAndContinue => 'Tasdiqlab, davom etish';

  @override
  String get noEmployeePhoto => 'Tizimda xodim fotosi yoʻq';

  @override
  String get noEmployeePhotoNote =>
      'Belgi qoʻyish imkonsiz. AvaTracker tizimiga foto qoʻshish uchun administratorga murojaat qiling.';

  @override
  String get backToScanner => 'Skanerga qaytish';

  @override
  String get faceAttemptsExceeded =>
      'Yuzni tekshirish urinishlari soni oshib ketdi';

  @override
  String get scanQrTryAgain => 'QR-kodni skanerlab, qayta urinib koʻring';

  @override
  String get photoCaptureFailed =>
      'Suratga olib boʻlmadi. Qayta urinib koʻring';

  @override
  String get markAccepted => 'Belgi qabul qilindi';

  @override
  String get markNotAccepted => 'Belgi qabul qilinmadi';

  @override
  String get resultLocation => 'Lokatsiya';

  @override
  String get resultDistance => 'Nuqtagacha masofa';

  @override
  String get resultTime => 'Vaqt';

  @override
  String get markCheckIn => 'Kelish';

  @override
  String get markCheckOut => 'Ketish';

  @override
  String get markPresence => 'Ishtirokni tekshirish';

  @override
  String get latesThisMonth => 'Oydagi kechikishlar';

  @override
  String get redMarksLate =>
      'To\'q sariq rang bilan kechikish kunlari belgilangan';

  @override
  String get cameAt => 'Keldi';

  @override
  String get bySchedule => 'Jadval boʻyicha';

  @override
  String get latenessLabel => 'Kechikish';

  @override
  String get dayNotYet => 'Hali kelmagan';

  @override
  String get dayNoLate => 'Kechikishsiz';

  @override
  String get dayNotArrivedYet => 'Kun hali kelmagan';

  @override
  String get noLatenessThisDay => 'Bu kuni kechikish qayd etilmagan';

  @override
  String scheduleName(String name) {
    return 'Jadval $name';
  }

  @override
  String scheduleStart(String time) {
    return 'boshlanishi $time';
  }

  @override
  String latenessAverage(String avg) {
    return 'oʻrtacha $avg';
  }

  @override
  String latenessMax(String max) {
    return 'maks $max';
  }

  @override
  String get labelIin => 'IIN';

  @override
  String get labelPhone => 'Telefon';

  @override
  String get labelPosition => 'Lavozim';

  @override
  String get labelDivision => 'Boʻlim';

  @override
  String get labelPark => 'Park / filial';

  @override
  String get analyticsWeek => 'Hafta';

  @override
  String get analyticsMonth => 'Oy';

  @override
  String get countryKazakhstan => 'Qozogʻiston';

  @override
  String get countryUzbekistan => 'Oʻzbekiston';

  @override
  String get logoutConfirmMessage =>
      'Kirish uchun telefon raqami va parol kerak boʻladi';

  @override
  String parkNumber(int number) {
    return 'Park №$number';
  }

  @override
  String get changePasswordSessionNote =>
      'Parol oʻzgartirilgandan keyin joriy seans faol qoladi. Boshqa qurilmalarda kirish uchun yangi paroldan foydalaning.';

  @override
  String get actionEnableLocation => 'Geolokatsiyani yoqish';

  @override
  String get locationEnableGps => 'Qurilmada geolokatsiyani (GPS) yoqing';

  @override
  String get locationPermissionRequired =>
      'Belgi qoʻyish uchun geolokatsiyaga ruxsat bering';

  @override
  String get locationUnavailable =>
      'Geolokatsiyani aniqlab boʻlmadi. Qayta urinib koʻring';

  @override
  String get locationMocked =>
      'Soxta geolokatsiya aniqlandi. Belgi qoʻyish taqiqlangan';

  @override
  String locationLowAccuracy(int accuracy) {
    return 'GPS aniqligi past (±$accuracy m). Ochiq joyga chiqing va qayta urinib koʻring';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceWithLimit(int distance, int limit) {
    return '$distance m ($limit m)';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes daq';
  }

  @override
  String durationHours(int hours) {
    return '$hours soat';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String get previousPeriod => 'Oldingi davr';

  @override
  String get nextPeriod => 'Keyingi davr';

  @override
  String get analyticsLatenessForWeek => 'Haftadagi kechikishlar';

  @override
  String get analyticsLatenessForMonth => 'Oydagi kechikishlar';

  @override
  String get analyticsNoLateness => 'Tanlangan davrda kechikishlar yoʻq';

  @override
  String analyticsSummary(String total, String average) {
    return 'Jami $total · oʻrtacha $average';
  }

  @override
  String get analyticsSourceNote =>
      'Maʼlumotlar xodimning smena boshlanishiga nisbatan birinchi avtorizatsiyasidan olinadi';

  @override
  String latenessCases(int count) {
    return '$count ta holat';
  }

  @override
  String get metricCases => 'holatlar';

  @override
  String get metricTotal => 'jami';

  @override
  String get metricAverage => 'oʻrtacha';

  @override
  String get metricMax => 'eng katta kechikish';

  @override
  String maxLateness(String duration) {
    return 'Eng katta kechikish: $duration';
  }

  @override
  String get latenessHistory => 'Kechikishlar tarixi';

  @override
  String plannedArrival(String planned, String actual) {
    return 'Reja $planned · kelish $actual';
  }

  @override
  String get errorSessionExpired => 'Seans tugadi. Qayta kiring';

  @override
  String get errorEmployeeInactive => 'Kirish taqiqlangan. Xodim faol emas';

  @override
  String get errorEmployeeNotFound => 'Xodim tizimda topilmadi';

  @override
  String get errorEmployeeDataMissing => 'Xodim maʼlumotlari yoʻq';

  @override
  String get errorInvalidServerResponse => 'Server javobi formati notoʻgʻri';

  @override
  String get errorTimesheetUnavailable => 'Tabel hozircha mavjud emas';

  @override
  String get errorResetTokenMissing => 'Server tiklash tokenini qaytarmadi';

  @override
  String get errorLoginFailed => 'Kirish amalga oshmadi';

  @override
  String get errorAttemptsExceeded =>
      'Urinishlar soni oshib ketdi. Yangi kod soʻrang';

  @override
  String get errorConfirmSmsFirst => 'Avval SMS kodini tasdiqlang';

  @override
  String get deleteAccountTitle => 'Hisobni oʻchirish';

  @override
  String get deleteAccountAction => 'Hisobni oʻchirish';

  @override
  String get deleteConfirmTitle => 'Hisobni oʻchirasizmi?';

  @override
  String get deleteConfirmBody =>
      'Ilova hisobini oʻchirishni tasdiqlang. Qayta kirish uchun yangidan roʻyxatdan oʻtish kerak.';

  @override
  String get actionDelete => 'Oʻchirish';

  @override
  String get accountDeleted => 'Hisob oʻchirildi. Qayta roʻyxatdan oʻting';
}
