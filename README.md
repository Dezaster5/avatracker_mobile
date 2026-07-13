# AvaTracker Mobile

Корпоративное Flutter-приложение для учёта рабочего времени сотрудников
AvaTracker. Текущая версия: `1.0.3+12`.

## Возможности

- регистрация и вход по номеру телефона;
- подтверждение регистрации и сброса пароля по SMS;
- QR-отметка с проверкой геолокации;
- фото-верификация сотрудника непосредственно перед QR-отметкой;
- месячный табель со временем прихода и ухода за каждый день;
- аналитика опозданий и индивидуальный график сотрудника;
- профиль сотрудника и смена пароля;
- поддержка системного автозаполнения логина/пароля через iOS Passwords /
  Keychain и Android Password Manager;
- локализация на казахский, русский и узбекский;
- телефонные номера Казахстана (`+7`) и Узбекистана (`+998`);
- локальный mock-режим для разработки без backend.

Face verification при обычном входе не выполняется. После чтения QR приложение
делает снимок фронтальной камерой, получает геолокацию и отправляет данные
серверу одним запросом отметки.

## Стек

- Flutter 3.44 / Dart 3;
- Riverpod для состояния;
- GoRouter для навигации;
- Dio для HTTP и обновления JWT;
- Flutter Secure Storage для токенов и данных сессии;
- Mobile Scanner для QR;
- Camera для снимка лица;
- Geolocator для координат и проверки mock-location;
- `gen-l10n` и Intl для локализации.

## Требования

- Flutter stable с Dart `>=3.5.0`;
- Android Studio с Android SDK;
- JDK 17;
- Android API 24 или новее;
- Xcode и CocoaPods для iOS-сборки.

На Windows используйте путь без кириллицы и желательно без пробелов, например
`C:\dev\avatracker_mobile`. Android build-tools могут завершаться с
`Illegal byte sequence`, если проект находится в каталоге вида
`C:\Users\...\Программирование\...`.

## Быстрый запуск

```powershell
flutter pub get
flutter gen-l10n
flutter devices
```

Демо без backend:

```powershell
flutter run --dart-define=MOCK_API=true
```

Демо-аккаунт:

- телефон: `+7 700 123 45 67`;
- пароль: `123456`;
- SMS-код: `1234`.

Для QR можно использовать любую непустую строку. Значение с `far` имитирует
выход за разрешённый радиус, с `inactive` — отключённую точку.

Запуск с production API:

```powershell
flutter run `
  --dart-define=MOCK_API=false `
  --dart-define=TEST_AUTH=false `
  --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

`API_BASE_URL` по умолчанию уже указывает на production. Явное значение в
команде делает режим запуска очевидным.

## Android Studio

1. Откройте корневую папку проекта, не каталог `android`.
2. Укажите Flutter SDK в
   **Settings > Languages & Frameworks > Flutter**.
3. Выполните **Pub get**.
4. Запустите Android Emulator или подключите физический телефон с USB debugging.
5. В **Run > Edit Configurations > Additional run args** добавьте:

```text
--dart-define=MOCK_API=true
```

Для production API замените аргумент на:

```text
--dart-define=MOCK_API=false --dart-define=TEST_AUTH=false --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

Камеру, Face verification и геолокацию корректнее проверять на физическом
устройстве.

## Тест с временным Bearer-токеном

Режим предназначен только для локальной отладки, когда auth API недоступен, но
есть тестовый ИИН и Bearer-токен.

```powershell
Copy-Item .env.example .env.local
notepad .env.local
powershell -ExecutionPolicy Bypass `
  -File tools\run_real_person_test.ps1 `
  -DeviceId emulator-5554
```

Заполните в `.env.local` значения `TEST_IIN`, `TEST_BEARER_TOKEN` и при
необходимости `TEST_REFRESH_TOKEN`. Файл игнорируется Git.

Не используйте `TEST_BEARER_TOKEN` при release-сборке: значения
`--dart-define` компилируются в приложение. Тестовый токен предназначен только
для локального debug-запуска.

## Локализация

Исходные строки находятся в:

- `lib/l10n/app_kk.arb`;
- `lib/l10n/app_ru.arb`;
- `lib/l10n/app_uz.arb`.

После изменения ARB-файлов выполните:

```powershell
flutter gen-l10n
```

Сгенерированные `app_localizations*.dart` входят в репозиторий, чтобы сборка
была воспроизводимой.

## Проверки

Перед commit:

```powershell
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Текущий набор содержит unit-, localization- и widget-тесты.

## Release

Production Android-сборка:

```powershell
flutter build apk --release `
  --dart-define=MOCK_API=false `
  --dart-define=TEST_AUTH=false `
  --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

APK создаётся в `build\app\outputs\flutter-apk`. APK/AAB и ключи подписи не
должны попадать в Git; распространяйте их через GitHub Releases, Google Play
или защищённое корпоративное хранилище.

Сейчас проект может собирать release APK с debug-подписью для внутреннего
тестирования. Перед публикацией требуется постоянный production keystore.
Полный чек-лист находится в [RELEASE.md](RELEASE.md).

## API

Приложение использует три API-базы на `avatracker.online`:

| Назначение | База |
|---|---|
| Авторизация и профиль | `/api/mobile` |
| QR-точки и отметка | `/api/qr` |
| Сотрудники и аналитика | `/api/v1` |

Основной flow отметки:

```text
QR -> проверка точки -> снимок лица -> GPS -> POST /api/qr/scan/ -> результат
```

Табель строится по `/api/v1/mobile/attendance/timesheet`: клиент
показывает первую отметку как приход, а последнюю как уход.
Аналитика опозданий строится по `/api/v1/tardiness/`, а время
графика берётся из `/api/v1/employees/{iin}/`.
Подробные payload и различия между фактическим и изначально предложенным API
описаны в [API_CONTRACT.md](API_CONTRACT.md).

## Безопасность и хранение

Пароли, SMS-коды и снимки лица приложение локально не сохраняет. Access token,
refresh token, ИИН, телефон и кеш профиля хранятся через
`flutter_secure_storage` в Android Keystore или iOS Keychain.

Телефон и пароль на экранах входа/регистрации размечены через autofill hints.
После успешного входа или регистрации приложение завершает autofill-контекст
с `shouldSave: true`, поэтому iOS Passwords/Keychain и Android Password Manager
могут предложить сохранить данные. Сам пароль остаётся вне storage приложения.

Не коммитьте `.env.local`, Bearer-токены, keystore, `key.properties`, APK/AAB
и provisioning profiles. Дополнительные правила описаны в
[SECURITY.md](SECURITY.md).

## Структура

```text
lib/
  core/                 конфигурация, сеть, storage, тема, локализация
  features/
    auth/               регистрация, вход, SMS, пароли, фото-верификация
    attendance/         QR, геолокация, табель, аналитика
    legal/              политика, удаление аккаунта, экран «О приложении»
    profile/            профиль сотрудника
    shell/              нижняя навигация
  l10n/                 ARB и сгенерированные локализации
  router/               маршруты и session guards
test/                   unit, localization и widget tests
tools/                  локальные PowerShell-сценарии
```

## Документы

- [API_CONTRACT.md](API_CONTRACT.md) — фактический API и legacy-контракт;
- [AvaTracker_TZ.md](AvaTracker_TZ.md) — исходное техническое задание;
- [APP_STORE_REVIEW.md](APP_STORE_REVIEW.md) — материалы для App Store;
- [RELEASE.md](RELEASE.md) — сборка и подпись релиза;
- [SECURITY.md](SECURITY.md) — правила обращения с секретами;
- [CHANGELOG.md](CHANGELOG.md) — изменения по версиям.
