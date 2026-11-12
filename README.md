# AvaTracker Mobile

Корпоративное Flutter-приложение для учёта рабочего времени сотрудников
AvaTracker. Текущая версия исходного кода: `1.0.7+19`.

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
- ИИН Казахстана (12 цифр) и ПИНФЛ/JShShIR Узбекистана (до 14 цифр);
- автоматический выбор казахского или узбекского языка при смене страны;
- локальный mock-режим для разработки без backend.

Face verification при обычном входе не выполняется. После чтения QR приложение
сразу показывает фронтальную камеру, через секунду автоматически выбирает
подходящий по свету и резкости кадр live-потока и бесшумно кодирует его в JPEG
в фоновом изоляте, не блокируя интерфейс.
Затем получает геолокацию и отправляет данные серверу одним запросом отметки.
Поток кадров на сервер не передаётся. BGRA-кадры iOS декодируются с четырьмя
байтами на пиксель и используют уже применённую AVFoundation ориентацию;
Android YUV-кадры корректируются по ориентации сенсора.

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
QR -> проверка точки -> камера 1 с -> автоснимок лица -> GPS -> POST /api/qr/scan/ -> результат
```

Табель строится по `/api/v1/employee-identification-list/`. Клиент
проходит все страницы ответа, группирует `auth_time` по рабочим дням с границей
в `03:00`, показывает первую отметку как приход, а последнюю как уход.
При одной отметке уход остаётся «Не отмечено». `/api/v1/tardiness/` отдаёт
метаданные аналитики, а случаи и минуты опозданий клиент пересчитывает по
первой отметке рабочего дня и индивидуальному времени начала смены. Время
графика берётся из
`/api/v1/employees/{iin}/` с резервом на `/api/v1/employees/?search={iin}`.
Табель повторяет этот расчёт непосредственно по отображаемым отметкам и
актуальному графику сотрудника, поэтому устаревший ответ `/tardiness/` не может
показать «Вовремя» при фактическом опоздании.

QR-сканер живёт в постоянной ветке нижней навигации: при
переключении вкладок `ScannerScreen` и его `MobileScannerController`
не уничтожаются и не создаются заново. Камера при этом работает, только пока
сканер виден: на другой вкладке или под другим экраном она остановлена
(`ScreenVisibilityMixin`, сигнал — `TickerMode`, который go_router выключает
у неактивных веток).
Подробные payload и различия между фактическим и изначально предложенным API
описаны в [API_CONTRACT.md](API_CONTRACT.md).

## Безопасность и хранение

Пароли, SMS-коды и снимки лица приложение локально не сохраняет. Access token,
refresh token, идентификационный номер, телефон и кеш профиля хранятся через
`flutter_secure_storage` в Android Keystore или iOS Keychain.

Телефон и пароль на экранах входа/регистрации размечены через autofill hints.
После успешного входа или регистрации приложение завершает autofill-контекст
с `shouldSave: true`, поэтому iOS Passwords/Keychain и Android Password Manager
могут предложить сохранить данные. Сам пароль остаётся вне storage приложения.

Не коммитьте `.env.local`, Bearer-токены, keystore, `key.properties`, APK/AAB
и provisioning profiles. Дополнительные правила описаны в
[SECURITY.md](SECURITY.md).

## Структура

Clean Architecture по фичам. Вызов API всегда идёт по цепочке
UI → контроллер (Riverpod) → use case → репозиторий → data source.

```text
lib/
  core/                 общее для всех фич, не зависит от features/
    config/             AppConfig: адреса API, dart-define, тайминги
    country/            Country и PhoneNumber — правила номера и ИИН/ПИНФЛ
    di/                 провайдеры инфраструктуры (storage, ApiClient)
    error/              Failure (sealed-каталог ошибок) и Result<T>
    network/            ApiClient (JWT, refresh), ApiEndpoints, guardRequest
    storage/            единая конфигурация secure storage, TokenStorage
    time/               ClockTime (HH:mm) и WorkDay (рабочий день с 03:00)
    widgets/, theme/, devtools/, presentation/, platform/, navigation/
  features/<фича>/
    domain/             сущности, интерфейсы репозиториев, use cases;
                        без Flutter, Dio и JSON
    data/               DTO (fromJson/toEntity), data sources, реализации
                        репозиториев; исключения → Failure через guardRequest
    di/                 сборка data → domain для фичи
    presentation/       контроллеры с иммутабельным состоянием, экраны, виджеты
  features/
    auth/               сессия, вход, регистрация, SMS, пароли, удаление
    attendance/         QR-отметка, FaceID-снимок, геолокация, табель, аналитика
    preferences/        язык интерфейса и страна телефона
    legal/, profile/, shell/   экраны без собственной бизнес-логики
  l10n/                 ARB, сгенерированные локализации, тексты Failure
  router/               маршруты и session guards
test/                   повторяет структуру lib/
tools/                  локальные PowerShell-сценарии
```

Ошибки не передаются строками: data-слой превращает исключения в `Failure`,
а текст на языке интерфейса выбирает `l10n.failureMessage(failure)`. Текст
ошибки из ответа сервера показывается как есть; ответ без текста получает
сообщение по статусу (доступ запрещён, не найдено, ошибка сервера), а не
«нет связи». Причина непредвиденной ошибки в debug- и `DEV_TOOLS`-сборках
пишется в лог панели разработчика.

SMS-код: попытку тратит только отказ сервера по самому коду (400). Нет сети,
таймаут, 429 и 5xx попытку не списывают.

Поля форм построены на `AppTextFormField` с единым правилом ошибок: пока
человек печатает, ошибку не показываем; ушёл с поля, в котором что-то вводил,
— поле проверяется; поле с ошибкой перепроверяется на каждый символ. Ошибка
сервера под формой исчезает при правке любого поля. Под новым паролем
показываются требования `PasswordPolicy.rules` и совпадение с подтверждением:
серые пункты зеленеют по мере ввода. Валидатор и подсказки строятся из одних
правил, поэтому не расходятся.

## Документы

- [API_CONTRACT.md](API_CONTRACT.md) — фактический API и legacy-контракт;
- [AvaTracker_TZ.md](AvaTracker_TZ.md) — исходное техническое задание;
- [APP_STORE_REVIEW.md](APP_STORE_REVIEW.md) — материалы для App Store;
- [RELEASE.md](RELEASE.md) — сборка и подпись релиза;
- [SECURITY.md](SECURITY.md) — правила обращения с секретами;
- [CHANGELOG.md](CHANGELOG.md) — изменения по версиям.
