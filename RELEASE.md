# Release

Чек-лист сборки AvaTracker Mobile для внутреннего тестирования и публикации.

> **Важно:** APK `AvaTracker-v1.0.3.apk` от 2026-07-13 отозван. В нём табель
> обращался к отсутствующему endpoint, а камера могла повторно запускать уже
> работающий контроллер. Не распространяйте этот файл. Исправления находятся
> в исходном коде и требуют проверки на физическом устройстве перед новой
> release-сборкой.

## 1. Версия

Версия задаётся в `pubspec.yaml`:

```yaml
version: 1.0.5+14
```

- `1.0.5` — `versionName`, отображаемая версия;
- `14` — `versionCode`, который должен увеличиваться при каждой публикации.

Строка `AppConfig.appVersion` должна соответствовать `versionName`.

## 2. Проверки

```powershell
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Проверяйте сборку на физическом Android-устройстве: камера, QR, разрешения,
Face verification, GPS, вход, обновление токена и выход из аккаунта.

## 3. Production signing

Release нельзя публиковать с сертификатом `CN=Android Debug`. Создайте один
постоянный upload keystore и храните его вне репозитория с резервной копией.
Потеря ключа осложнит выпуск обновлений приложения.

Пример создания:

```powershell
keytool -genkeypair -v `
  -keystore C:\secure\avatracker-upload.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias avatracker-upload
```

Локальный `android\key.properties`:

```properties
storeFile=C:\\secure\\avatracker-upload.jks
storePassword=<secret>
keyAlias=avatracker-upload
keyPassword=<secret>
```

`key.properties`, `*.jks` и `*.keystore` игнорируются Git. До подключения
этого файла `android/app/build.gradle.kts` использует debug signing только для
локальной release-проверки.

## 4. Android build

На Windows клонируйте проект в ASCII-путь, например
`C:\dev\avatracker_mobile`. Сборка из пути с кириллицей может падать внутри
`aapt` с `Illegal byte sequence`.

APK для внутреннего распространения:

```powershell
flutter build apk --release `
  --dart-define=MOCK_API=false `
  --dart-define=TEST_AUTH=false `
  --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

App Bundle для Google Play:

```powershell
flutter build appbundle --release `
  --dart-define=MOCK_API=false `
  --dart-define=TEST_AUTH=false `
  --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

Не передавайте `TEST_IIN` или `TEST_BEARER_TOKEN` в production build.

## 5. Проверка артефакта

```powershell
aapt dump badging build\app\outputs\flutter-apk\app-release.apk
apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

Проверьте:

- правильные `versionName` и `versionCode`;
- отсутствие `application-debuggable`;
- production certificate вместо `Android Debug`;
- `MOCK_API=false`;
- установку и обновление поверх предыдущей версии с тем же ключом.

Именованный APK можно создать после проверки:

```powershell
Copy-Item `
  build\app\outputs\flutter-apk\app-release.apk `
  AvaTracker-v1.0.5.apk
```

APK и AAB не коммитятся. При необходимости приложите артефакт к GitHub Release.

## 5.1. Текущая внутренняя сборка 2026-07-16

- файл: `AvaTracker-v1.0.5.apk`;
- `versionName`: `1.0.5`;
- `versionCode`: `14`;
- размер: 77 806 872 байта (~74,2 MB);
- SHA-256:
  `afa245bb1deb76c469df04912692d953740a671ab2034ad8e58ff19f257ab3c1`;
- `MOCK_API=false`, `TEST_AUTH=false`,
  `API_BASE_URL=https://avatracker.online/api/v1`;
- Политика конфиденциальности версии 2.0 присутствует в assets APK;
- `flutter analyze` — без ошибок, `flutter test` — 52 теста прошли.

Сборка подписана `CN=Android Debug`, потому что production keystore на машине
не настроен. Она предназначена для внутреннего тестирования и не должна
загружаться в Google Play как финальный релиз.

## 5.2. Отозванная сборка 2026-07-13

Эта сборка сохранена в журнале только для идентификации. Использовать её для
тестирования и распространения нельзя:

- файл: `AvaTracker-v1.0.3.apk`;
- `versionName`: `1.0.3`;
- `versionCode`: `12`;
- размер: 77 637 742 байта (~74 MB);
- SHA-256:
  `bb19679e7d07d1bf0a8071ef695ff84ecd10483b27b7f7baa8dea6e9b027d0b8`;
- `application-debuggable` в manifest отсутствует;
- `MOCK_API=false`, `TEST_AUTH=false`,
  `API_BASE_URL=https://avatracker.online/api/v1`.

Проверки, которые были выполнены перед сборкой:

- `flutter analyze` — без ошибок;
- `flutter test` — 45 тестов прошли;
- `flutter build apk --release` с production dart-defines — успешно.

Ограничение: на машине нет `android/key.properties`, поэтому сборка
подписана `CN=Android Debug`. Дополнительно в ней обнаружены ошибки контракта
табеля и жизненного цикла камеры, поэтому она полностью отозвана.

## 5.3. Требования к следующей сборке

Перед созданием следующего APK на физическом устройстве обязательно проверить:

- быстрое переключение `Сканер -> Табель -> Сканер` не останавливает камеру и
  не вызывает `controllerAlreadyInitialized`;
- табель получает все страницы `/api/v1/employee-identification-list/` и
  показывает первую отметку дня как приход, последнюю как уход;
- при одной отметке уход отображается как отсутствующий;
- график берётся из `schedule_start_time` и `schedule_end_time` сотрудника;
- аналитика продолжает загружаться из `/api/v1/tardiness/`.

## 5.4. Предыдущая сборка 2026-07-08

Последняя локально собранная Android release-сборка:

- файл: `AvaTracker-v1.0.0.apk`;
- `versionName`: `1.0.0`;
- `versionCode`: `9`;
- размер: ~74 MB;
- SHA-256:
  `450a283884ed854efd946c1ac1c7d6c63b827f405a562bbe139a2068065e6abc`;
- команда сборки:

```powershell
flutter build apk --release `
  --dart-define=MOCK_API=false `
  --dart-define=TEST_AUTH=false `
  --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

Проверки перед сборкой:

- `flutter analyze` — без ошибок;
- `flutter test` — 43 теста прошли.

Ограничение: сборка подписана `CN=Android Debug`, потому что production
keystore ещё не подключён. Для Google Play или стабильных обновлений нужен
постоянный release/upload key из раздела 3.

## 6. iOS

iOS release собирается только на macOS:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release
```

Подпись и provisioning настраиваются в Xcode. Материалы для App Store Connect
описаны в `APP_STORE_REVIEW.md`.
