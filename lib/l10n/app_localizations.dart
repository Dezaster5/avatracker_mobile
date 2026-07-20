import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'AvaTracker'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ru, this message translates to:
  /// **'Учет рабочего времени'**
  String get appTagline;

  /// No description provided for @actionContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get actionContinue;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get actionClose;

  /// No description provided for @actionDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get actionDone;

  /// No description provided for @actionUnderstood.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get actionUnderstood;

  /// No description provided for @actionSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get actionSave;

  /// No description provided for @errorConnection.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка соединения. Попробуйте позже'**
  String get errorConnection;

  /// No description provided for @privacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get privacyPolicy;

  /// No description provided for @loginWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите по номеру телефона и паролю'**
  String get loginSubtitle;

  /// No description provided for @fieldPhone.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get fieldPhone;

  /// No description provided for @fieldPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get fieldPassword;

  /// No description provided for @passwordHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get login;

  /// No description provided for @firstTimeHere.
  ///
  /// In ru, this message translates to:
  /// **'Впервые здесь?'**
  String get firstTimeHere;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get register;

  /// No description provided for @enterPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get enterPassword;

  /// No description provided for @validatorPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный номер телефона'**
  String get validatorPhone;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registerTitle;

  /// No description provided for @createAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создайте аккаунт сотрудника'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон, идентификационный номер и пароль. Код подтверждения придёт по SMS.'**
  String get registerSubtitle;

  /// No description provided for @fieldIin.
  ///
  /// In ru, this message translates to:
  /// **'ИИН'**
  String get fieldIin;

  /// No description provided for @iinHint.
  ///
  /// In ru, this message translates to:
  /// **'12 цифр'**
  String get iinHint;

  /// No description provided for @iinExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Нужен только для проверки сотрудника в AvaTracker.'**
  String get iinExplanation;

  /// No description provided for @fieldPinfl.
  ///
  /// In ru, this message translates to:
  /// **'ПИНФЛ'**
  String get fieldPinfl;

  /// No description provided for @pinflHint.
  ///
  /// In ru, this message translates to:
  /// **'14 цифр'**
  String get pinflHint;

  /// No description provided for @pinflExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Нужен только для проверки сотрудника в AvaTracker.'**
  String get pinflExplanation;

  /// No description provided for @passwordMinHint.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get passwordMinHint;

  /// No description provided for @confirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get confirmPassword;

  /// No description provided for @repeatPassword.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get repeatPassword;

  /// No description provided for @getSmsCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить SMS-код'**
  String get getSmsCode;

  /// No description provided for @haveAccount.
  ///
  /// In ru, this message translates to:
  /// **'У меня уже есть аккаунт'**
  String get haveAccount;

  /// No description provided for @consentCheckbox.
  ///
  /// In ru, this message translates to:
  /// **'Я ознакомлен(а) с Политикой конфиденциальности и даю согласие на обработку персональных данных для учёта рабочего времени, проверки активности сотрудника и фиксации отметок прихода/ухода.'**
  String get consentCheckbox;

  /// No description provided for @validatorIin.
  ///
  /// In ru, this message translates to:
  /// **'ИИН должен содержать 12 цифр'**
  String get validatorIin;

  /// No description provided for @validatorPinfl.
  ///
  /// In ru, this message translates to:
  /// **'Введите ПИНФЛ'**
  String get validatorPinfl;

  /// No description provided for @validatorPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль: минимум 6 символов, без пробелов'**
  String get validatorPassword;

  /// No description provided for @validatorPasswordsMatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get validatorPasswordsMatch;

  /// No description provided for @confirmation.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение'**
  String get confirmation;

  /// No description provided for @enterSmsCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите код из SMS'**
  String get enterSmsCode;

  /// No description provided for @sentToNumber.
  ///
  /// In ru, this message translates to:
  /// **'Отправили его на номер'**
  String get sentToNumber;

  /// No description provided for @attemptsLeft.
  ///
  /// In ru, this message translates to:
  /// **'Осталось попыток: {count}'**
  String attemptsLeft(int count);

  /// No description provided for @resendIn.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код повторно через {seconds} с'**
  String resendIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код повторно'**
  String get resendCode;

  /// No description provided for @requestNewCode.
  ///
  /// In ru, this message translates to:
  /// **'Запросить новый код'**
  String get requestNewCode;

  /// No description provided for @resetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get resetTitle;

  /// No description provided for @forgotTitle.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Укажите номер телефона аккаунта — пришлём SMS с кодом для сброса'**
  String get forgotSubtitle;

  /// No description provided for @sendCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код'**
  String get sendCode;

  /// No description provided for @newPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordHeading.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте новый пароль'**
  String get newPasswordHeading;

  /// No description provided for @codeConfirmedFor.
  ///
  /// In ru, this message translates to:
  /// **'Код подтверждён для номера'**
  String get codeConfirmedFor;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get newPasswordLabel;

  /// No description provided for @savePassword.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get savePassword;

  /// No description provided for @passwordChangedLogin.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён. Войдите с новым паролем'**
  String get passwordChangedLogin;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get enterCurrentPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите новый пароль'**
  String get confirmNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён'**
  String get passwordChanged;

  /// No description provided for @tabScanner.
  ///
  /// In ru, this message translates to:
  /// **'Сканер'**
  String get tabScanner;

  /// No description provided for @tabTimesheet.
  ///
  /// In ru, this message translates to:
  /// **'Табель'**
  String get tabTimesheet;

  /// No description provided for @tabAnalytics.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get tabAnalytics;

  /// No description provided for @tabProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get tabProfile;

  /// No description provided for @myData.
  ///
  /// In ru, this message translates to:
  /// **'Мои данные'**
  String get myData;

  /// No description provided for @statusActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In ru, this message translates to:
  /// **'Неактивен'**
  String get statusInactive;

  /// No description provided for @about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get about;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get logout;

  /// No description provided for @aboutSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Корпоративное приложение для учёта рабочего времени сотрудников'**
  String get aboutSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String versionLabel(String version);

  /// No description provided for @consentMenu.
  ///
  /// In ru, this message translates to:
  /// **'Согласие на обработку данных'**
  String get consentMenu;

  /// No description provided for @support.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой'**
  String get support;

  /// No description provided for @supportBody.
  ///
  /// In ru, this message translates to:
  /// **'По вопросам работы приложения и обработки данных:'**
  String get supportBody;

  /// No description provided for @writeEmail.
  ///
  /// In ru, this message translates to:
  /// **'Написать письмо'**
  String get writeEmail;

  /// No description provided for @deleteAccountMenu.
  ///
  /// In ru, this message translates to:
  /// **'Запросить удаление аккаунта'**
  String get deleteAccountMenu;

  /// No description provided for @chooseLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get chooseLanguage;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageKazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKazakh;

  /// No description provided for @languageUzbek.
  ///
  /// In ru, this message translates to:
  /// **'Oʻzbekcha'**
  String get languageUzbek;

  /// No description provided for @chooseCountry.
  ///
  /// In ru, this message translates to:
  /// **'Выберите страну'**
  String get chooseCountry;

  /// No description provided for @actionSelect.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get actionSelect;

  /// No description provided for @actionOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки приложения'**
  String get actionOpenSettings;

  /// No description provided for @scanQrTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметка по QR-коду'**
  String get scanQrTitle;

  /// No description provided for @pointCameraAtQr.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код'**
  String get pointCameraAtQr;

  /// No description provided for @within50m.
  ///
  /// In ru, this message translates to:
  /// **'Вы должны находиться в радиусе 50 м от точки отметки'**
  String get within50m;

  /// No description provided for @stageCheckingPoint.
  ///
  /// In ru, this message translates to:
  /// **'Проверка точки отметки…'**
  String get stageCheckingPoint;

  /// No description provided for @stageCheckingFace.
  ///
  /// In ru, this message translates to:
  /// **'Проверка лица…'**
  String get stageCheckingFace;

  /// No description provided for @stageCheckingLocation.
  ///
  /// In ru, this message translates to:
  /// **'Проверка геолокации…'**
  String get stageCheckingLocation;

  /// No description provided for @stageSendingMark.
  ///
  /// In ru, this message translates to:
  /// **'Отправка отметки…'**
  String get stageSendingMark;

  /// No description provided for @pointDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Эта точка отметки отключена'**
  String get pointDisabled;

  /// No description provided for @qrNotRegistered.
  ///
  /// In ru, this message translates to:
  /// **'QR-код не зарегистрирован в системе'**
  String get qrNotRegistered;

  /// No description provided for @qrCodeValue.
  ///
  /// In ru, this message translates to:
  /// **'Код из QR: «{code}»'**
  String qrCodeValue(String code);

  /// No description provided for @noServerConnection.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения с сервером'**
  String get noServerConnection;

  /// No description provided for @cameraStartFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить камеру'**
  String get cameraStartFailed;

  /// No description provided for @cameraNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к камере'**
  String get cameraNoAccess;

  /// No description provided for @cameraCloseOthers.
  ///
  /// In ru, this message translates to:
  /// **'Закройте другие приложения, использующие камеру, и нажмите «Повторить»'**
  String get cameraCloseOthers;

  /// No description provided for @cameraGrantAccess.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к камере в настройках приложения, чтобы сканировать QR-коды'**
  String get cameraGrantAccess;

  /// No description provided for @identityCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверка личности'**
  String get identityCheck;

  /// No description provided for @identityCheckName.
  ///
  /// In ru, this message translates to:
  /// **'{name}, подтвердите личность'**
  String identityCheckName(String name);

  /// No description provided for @photoVerifyBeforeScan.
  ///
  /// In ru, this message translates to:
  /// **'Фото-верификация перед каждой QR-отметкой'**
  String get photoVerifyBeforeScan;

  /// No description provided for @lookAtCamera.
  ///
  /// In ru, this message translates to:
  /// **'Посмотрите в камеру'**
  String get lookAtCamera;

  /// No description provided for @photoComparedNote.
  ///
  /// In ru, this message translates to:
  /// **'Снимок сравнивается с вашим фото в системе AvaTracker и используется только для подтверждения личности'**
  String get photoComparedNote;

  /// No description provided for @confirmAndContinue.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить и продолжить'**
  String get confirmAndContinue;

  /// No description provided for @noEmployeePhoto.
  ///
  /// In ru, this message translates to:
  /// **'В системе отсутствует фото сотрудника'**
  String get noEmployeePhoto;

  /// No description provided for @noEmployeePhotoNote.
  ///
  /// In ru, this message translates to:
  /// **'Отметка невозможна. Обратитесь к администратору, чтобы добавить фото в AvaTracker.'**
  String get noEmployeePhotoNote;

  /// No description provided for @backToScanner.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к сканеру'**
  String get backToScanner;

  /// No description provided for @faceAttemptsExceeded.
  ///
  /// In ru, this message translates to:
  /// **'Превышено количество попыток проверки лица'**
  String get faceAttemptsExceeded;

  /// No description provided for @scanQrTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте QR-код и попробуйте снова'**
  String get scanQrTryAgain;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сделать снимок. Попробуйте ещё раз'**
  String get photoCaptureFailed;

  /// No description provided for @markAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Отметка засчитана'**
  String get markAccepted;

  /// No description provided for @markNotAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Отметка не засчитана'**
  String get markNotAccepted;

  /// No description provided for @resultLocation.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get resultLocation;

  /// No description provided for @resultDistance.
  ///
  /// In ru, this message translates to:
  /// **'Расстояние до точки'**
  String get resultDistance;

  /// No description provided for @resultTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get resultTime;

  /// No description provided for @markCheckIn.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get markCheckIn;

  /// No description provided for @markCheckOut.
  ///
  /// In ru, this message translates to:
  /// **'Уход'**
  String get markCheckOut;

  /// No description provided for @markPresence.
  ///
  /// In ru, this message translates to:
  /// **'Проверка присутствия'**
  String get markPresence;

  /// No description provided for @latesThisMonth.
  ///
  /// In ru, this message translates to:
  /// **'Опозданий за месяц'**
  String get latesThisMonth;

  /// No description provided for @redMarksLate.
  ///
  /// In ru, this message translates to:
  /// **'Оранжевым отмечены дни опозданий'**
  String get redMarksLate;

  /// No description provided for @cameAt.
  ///
  /// In ru, this message translates to:
  /// **'Пришёл'**
  String get cameAt;

  /// No description provided for @bySchedule.
  ///
  /// In ru, this message translates to:
  /// **'По графику'**
  String get bySchedule;

  /// No description provided for @latenessLabel.
  ///
  /// In ru, this message translates to:
  /// **'Опоздание'**
  String get latenessLabel;

  /// No description provided for @dayNotYet.
  ///
  /// In ru, this message translates to:
  /// **'Ещё не наступило'**
  String get dayNotYet;

  /// No description provided for @dayNoLate.
  ///
  /// In ru, this message translates to:
  /// **'Без опозданий'**
  String get dayNoLate;

  /// No description provided for @dayNotArrivedYet.
  ///
  /// In ru, this message translates to:
  /// **'День ещё не наступил'**
  String get dayNotArrivedYet;

  /// No description provided for @noLatenessThisDay.
  ///
  /// In ru, this message translates to:
  /// **'Опозданий за этот день не зафиксировано'**
  String get noLatenessThisDay;

  /// No description provided for @dayOnTime.
  ///
  /// In ru, this message translates to:
  /// **'Вовремя'**
  String get dayOnTime;

  /// No description provided for @dayAbsent.
  ///
  /// In ru, this message translates to:
  /// **'Пропуск'**
  String get dayAbsent;

  /// No description provided for @dayWeekend.
  ///
  /// In ru, this message translates to:
  /// **'Выходной'**
  String get dayWeekend;

  /// No description provided for @dayWeekendWork.
  ///
  /// In ru, this message translates to:
  /// **'Работа в выходной'**
  String get dayWeekendWork;

  /// No description provided for @dayNoMarks.
  ///
  /// In ru, this message translates to:
  /// **'Нет отметок'**
  String get dayNoMarks;

  /// No description provided for @dayNoData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get dayNoData;

  /// No description provided for @timesheetNoDayData.
  ///
  /// In ru, this message translates to:
  /// **'Данные за этот день отсутствуют'**
  String get timesheetNoDayData;

  /// No description provided for @notMarked.
  ///
  /// In ru, this message translates to:
  /// **'Не отмечено'**
  String get notMarked;

  /// No description provided for @scheduleName.
  ///
  /// In ru, this message translates to:
  /// **'График {name}'**
  String scheduleName(String name);

  /// No description provided for @scheduleStart.
  ///
  /// In ru, this message translates to:
  /// **'начало в {time}'**
  String scheduleStart(String time);

  /// No description provided for @latenessAverage.
  ///
  /// In ru, this message translates to:
  /// **'в среднем {avg}'**
  String latenessAverage(String avg);

  /// No description provided for @latenessMax.
  ///
  /// In ru, this message translates to:
  /// **'макс {max}'**
  String latenessMax(String max);

  /// No description provided for @labelIin.
  ///
  /// In ru, this message translates to:
  /// **'ИИН'**
  String get labelIin;

  /// No description provided for @labelPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get labelPhone;

  /// No description provided for @labelPosition.
  ///
  /// In ru, this message translates to:
  /// **'Должность'**
  String get labelPosition;

  /// No description provided for @labelDivision.
  ///
  /// In ru, this message translates to:
  /// **'Отдел'**
  String get labelDivision;

  /// No description provided for @labelPark.
  ///
  /// In ru, this message translates to:
  /// **'Парк / филиал'**
  String get labelPark;

  /// No description provided for @analyticsWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get analyticsWeek;

  /// No description provided for @analyticsMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get analyticsMonth;

  /// No description provided for @countryKazakhstan.
  ///
  /// In ru, this message translates to:
  /// **'Казахстан'**
  String get countryKazakhstan;

  /// No description provided for @countryUzbekistan.
  ///
  /// In ru, this message translates to:
  /// **'Узбекистан'**
  String get countryUzbekistan;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Для входа понадобятся номер телефона и пароль'**
  String get logoutConfirmMessage;

  /// No description provided for @parkNumber.
  ///
  /// In ru, this message translates to:
  /// **'Парк №{number}'**
  String parkNumber(int number);

  /// No description provided for @changePasswordSessionNote.
  ///
  /// In ru, this message translates to:
  /// **'После смены пароля текущая сессия останется активной. Для входа на других устройствах используйте новый пароль.'**
  String get changePasswordSessionNote;

  /// No description provided for @actionEnableLocation.
  ///
  /// In ru, this message translates to:
  /// **'Включить геолокацию'**
  String get actionEnableLocation;

  /// No description provided for @locationEnableGps.
  ///
  /// In ru, this message translates to:
  /// **'Включите геолокацию (GPS) на устройстве'**
  String get locationEnableGps;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к геолокации для отметки'**
  String get locationPermissionRequired;

  /// No description provided for @locationUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить геолокацию. Попробуйте ещё раз'**
  String get locationUnavailable;

  /// No description provided for @locationMocked.
  ///
  /// In ru, this message translates to:
  /// **'Обнаружена поддельная геолокация. Отметка запрещена'**
  String get locationMocked;

  /// No description provided for @locationLowAccuracy.
  ///
  /// In ru, this message translates to:
  /// **'Низкая точность GPS (±{accuracy} м). Выйдите на открытое место и попробуйте снова'**
  String locationLowAccuracy(int accuracy);

  /// No description provided for @distanceMeters.
  ///
  /// In ru, this message translates to:
  /// **'{meters} м'**
  String distanceMeters(int meters);

  /// No description provided for @distanceWithLimit.
  ///
  /// In ru, this message translates to:
  /// **'{distance} м ({limit} м)'**
  String distanceWithLimit(int distance, int limit);

  /// No description provided for @durationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @previousPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий период'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Следующий период'**
  String get nextPeriod;

  /// No description provided for @analyticsLatenessForWeek.
  ///
  /// In ru, this message translates to:
  /// **'Опоздания за неделю'**
  String get analyticsLatenessForWeek;

  /// No description provided for @analyticsLatenessForMonth.
  ///
  /// In ru, this message translates to:
  /// **'Опоздания за месяц'**
  String get analyticsLatenessForMonth;

  /// No description provided for @analyticsNoLateness.
  ///
  /// In ru, this message translates to:
  /// **'За выбранный период опозданий нет'**
  String get analyticsNoLateness;

  /// No description provided for @analyticsSummary.
  ///
  /// In ru, this message translates to:
  /// **'Суммарно {total} · в среднем {average}'**
  String analyticsSummary(String total, String average);

  /// No description provided for @analyticsSourceNote.
  ///
  /// In ru, this message translates to:
  /// **'Данные берутся из времени первой отметки сотрудника относительно начала смены'**
  String get analyticsSourceNote;

  /// No description provided for @workSchedule.
  ///
  /// In ru, this message translates to:
  /// **'График работы'**
  String get workSchedule;

  /// No description provided for @latenessCases.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =0{0 случаев} one{{count} случай} few{{count} случая} many{{count} случаев} other{{count} случая}}'**
  String latenessCases(int count);

  /// No description provided for @metricCases.
  ///
  /// In ru, this message translates to:
  /// **'случаев'**
  String get metricCases;

  /// No description provided for @metricTotal.
  ///
  /// In ru, this message translates to:
  /// **'суммарно'**
  String get metricTotal;

  /// No description provided for @metricAverage.
  ///
  /// In ru, this message translates to:
  /// **'в среднем'**
  String get metricAverage;

  /// No description provided for @metricMax.
  ///
  /// In ru, this message translates to:
  /// **'макс. опоздание'**
  String get metricMax;

  /// No description provided for @maxLateness.
  ///
  /// In ru, this message translates to:
  /// **'Максимальное опоздание: {duration}'**
  String maxLateness(String duration);

  /// No description provided for @latenessHistory.
  ///
  /// In ru, this message translates to:
  /// **'История опозданий'**
  String get latenessHistory;

  /// No description provided for @plannedArrival.
  ///
  /// In ru, this message translates to:
  /// **'План {planned} · приход {actual}'**
  String plannedArrival(String planned, String actual);

  /// No description provided for @errorSessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите заново'**
  String get errorSessionExpired;

  /// No description provided for @errorEmployeeInactive.
  ///
  /// In ru, this message translates to:
  /// **'Доступ запрещён. Сотрудник неактивен'**
  String get errorEmployeeInactive;

  /// No description provided for @errorEmployeeNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник не найден в системе'**
  String get errorEmployeeNotFound;

  /// No description provided for @errorEmployeeDataMissing.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных сотрудника'**
  String get errorEmployeeDataMissing;

  /// No description provided for @errorInvalidServerResponse.
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат ответа сервера'**
  String get errorInvalidServerResponse;

  /// No description provided for @errorTimesheetUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Табель пока недоступен'**
  String get errorTimesheetUnavailable;

  /// No description provided for @errorResetTokenMissing.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не вернул токен сброса'**
  String get errorResetTokenMissing;

  /// No description provided for @errorLoginFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти'**
  String get errorLoginFailed;

  /// No description provided for @errorAttemptsExceeded.
  ///
  /// In ru, this message translates to:
  /// **'Превышено количество попыток. Запросите новый код'**
  String get errorAttemptsExceeded;

  /// No description provided for @errorConfirmSmsFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала подтвердите SMS-код'**
  String get errorConfirmSmsFirst;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удаление аккаунта'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountAction.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get deleteAccountAction;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите удаление аккаунта приложения. Для повторного входа потребуется новая регистрация.'**
  String get deleteConfirmBody;

  /// No description provided for @actionDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get actionDelete;

  /// No description provided for @accountDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт удалён. Зарегистрируйтесь заново'**
  String get accountDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
