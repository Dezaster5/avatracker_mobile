# AvaTracker Mobile

Мобильное приложение учета рабочего времени сотрудников (Flutter):
QR-отметки с контролем геолокации (≤ 50 м), FaceID-сверка с фото из базы,
SMS-авторизация по номеру телефона и ИИН. Реализовано по `AvaTracker_TZ.md`.

## Стек

- Flutter 3.44 / Dart 3
- **flutter_riverpod** — состояние
- **go_router** — навигация c guard'ами по статусу сессии
- **dio** — HTTP + JWT-interceptor с автоматическим refresh
- **mobile_scanner** — QR (ML Kit / AVFoundation)
- **geolocator** — координаты, точность GPS, детекция mock-локации
- **camera** — live-снимок для FaceID
- **flutter_secure_storage** — токены/ИИН (Keychain / Keystore)

## Запуск

```bash
flutter pub get

# Демо без бэкенда (mock-режим, SMS-код: 1234)
flutter run --dart-define=MOCK_API=true

# Боевой API
flutter run --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

Тесты и анализ:

```bash
flutter test
flutter analyze
```

### Запуск в Android Studio

> На Windows открывайте проект из пути без кириллицы и пробелов, например
> `C:\dev\avatracker_mobile_ascii`. Android build-tools могут падать на путях
> вида `C:\Users\Мирас\Desktop\Программирование\...` с ошибкой
> `Illegal byte sequence` при чтении APK.

1. Откройте Android Studio и выберите **Open**.
2. Укажите корневую папку проекта `avatracker_mobile`, не папку `android`.
3. Если Android Studio попросит Flutter SDK, укажите путь `C:\dev\flutter`.
   Настройка также доступна через **Settings → Languages & Frameworks → Flutter**.
4. Дождитесь индексации проекта и нажмите **Pub get** в верхней панели или в
   файле `pubspec.yaml`.
5. Выберите устройство в верхней панели:
   - Android Emulator через **Device Manager**;
   - физический Android-телефон с включенной USB-отладкой.
6. Для demo-запуска откройте **Run → Edit Configurations...**, выберите Flutter
   configuration для `lib/main.dart` и добавьте в **Additional run args**:

```text
--dart-define=MOCK_API=true
```

7. Нажмите **Run** или **Debug**.

Для запуска с реальным API вместо mock-аргумента укажите:

```text
--dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

После установки на устройство разрешите приложению доступ к камере и
геолокации. Для проверки QR/FaceID лучше использовать физический телефон:
на эмуляторе камера и геолокация могут работать ограниченно.

### Mock-режим

`--dart-define=MOCK_API=true` — все эндпоинты обслуживаются локально
([mock_interceptor.dart](lib/core/network/mock_interceptor.dart)):

| Что | Поведение |
|---|---|
| SMS-код | всегда `1234` |
| FaceID | всегда успех (94.5%) |
| QR с текстом `far` | отказ «Вы находитесь далеко от точки отметки» |
| QR с текстом `inactive` | отказ «Эта точка отметки отключена» |
| Любой другой QR | приход → уход → проверка присутствия |

## Структура

```
lib/
  app.dart                 # MaterialApp.router, тема, локализация (ru)
  core/
    config/app_config.dart # BASE_URL, лимиты ТЗ (радиус, попытки, таймауты)
    network/               # ApiClient (JWT+refresh), ApiException, mock
    services/              # LocationService (проверки GPS и mock-location)
    storage/               # TokenStorage (secure storage, ТЗ §18.2)
  features/
    auth/                  # login/register/password, face-verify, employee
      presentation/        # Splash, Login, SmsCode, FaceId перед QR
    attendance/            # scan, timesheet, клиентская analytics
      presentation/        # Scanner, Timesheet, Analytics + result sheet
    profile/               # Мои данные
    shell/                 # Нижняя навигация (4 вкладки, ТЗ §6)
  router/app_router.dart   # Редиректы: unknown→splash, no-token→login,
                           # authenticated→scanner
```

## Флоу сессии (ТЗ §5, §19.1)

```
Splash → токен есть? → GET /employees/{iin} → активен? → Главный экран
            └ нет → Login / Регистрация → Главный экран

QR найден → FaceID для этого QR → GPS → POST attendance/scan → результат
```

Активность сотрудника перепроверяется при каждом входе; неактивный
сотрудник разлогинивается с сообщением «Доступ запрещен. Сотрудник неактивен».

## Контракт API (бэкенд — следующий этап)

Используются эндпоинты из ТЗ §13 + один дополнительный:

| Метод | Путь | Примечание |
|---|---|---|
| GET | `/api/v1/employees/{iin}/` | уже есть в avatracker-back |
| POST | `/api/v1/mobile/auth/register/send-code` | SMSC.kz, код регистрации |
| POST | `/api/v1/mobile/auth/register/verify` | подтверждение кода, выдает JWT |
| POST | `/api/v1/mobile/auth/login` | вход по телефону и паролю |
| POST | `/api/v1/mobile/auth/refresh` | **доп. к ТЗ**: обновление access-токена |
| POST | `/api/v1/mobile/auth/face-verify` | FaceID конкретного QR, возвращает одноразовый токен |
| GET | `/api/v1/mobile/qr-points/{qr_id}` | ТЗ 13.5 |
| POST | `/api/v1/mobile/attendance/scan` | QR + GPS + `face_verification_token` |
| GET | `/api/v1/mobile/attendance/timesheet` | ТЗ 13.7 |

В запрос отметки приложение дополнительно передает `accuracy_meters` и
`is_mock_location` и одноразовый FaceID-токен — для серверного антифрода.
Решение о зачете отметки (FaceID, радиус, повторы, активность) принимает сервер.

Экран «Аналитика» отдельный API не вызывает: отработанное время и опоздания за
неделю/месяц рассчитываются из месячного табеля по индивидуальному
`work_start` и первой отметке `check_in`.

### Настройка SMSC.kz

Логин и пароль SMSC.kz указываются **только в `.env` backend-проекта
`avatracker-back`**, не в Flutter и не через `--dart-define`:

```dotenv
SMSC_LOGIN=
SMSC_PASSWORD=
SMSC_SENDER=
SMSC_API_URL=https://smsc.kz/rest/send/
```

Подробный запрос и требования описаны в `API_CONTRACT.md`. Официальная
документация: https://smsc.kz/api/http/send/

## Итоговая сводка и инструкция запуска

MVP мобильного приложения реализован по `AvaTracker_TZ.md`: вход по телефону и
ИИН, подтверждение SMS-кодом, проверка активности сотрудника при старте,
FaceID перед каждой QR-отметкой, геолокация, табель, аналитика опозданий,
профиль и нижняя навигация на 4 вкладки.

Для демонстрации без бэкенда используйте mock-режим:

```bash
flutter pub get
flutter run --dart-define=MOCK_API=true
```

В mock-режиме SMS-код всегда `1234`, FaceID выдает одноразовый токен, обычный
QR засчитывает отметку, QR с текстом `far` имитирует выход за радиус, QR с
текстом `inactive` имитирует отключенную точку.

Для запуска с реальным API:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://avatracker.online/api/v1
```

Перед передачей сборки проверьте проект:

```bash
flutter analyze
flutter test
```

На физическом устройстве нужно выдать приложению доступ к камере и геолокации.
Android и iOS permissions уже прописаны в проекте.

## Что дальше (вне MVP мобилки)

- [ ] Бэкенд: Django-приложение `mobile` в avatracker-back
      (JWT simplejwt, SMSc.kz, InsightFace, QR-точки, отметки)
- [ ] Push-уведомления (FCM) — ТЗ §12
- [ ] Liveness-проверка на устройстве (ML Kit face detection) — ТЗ §5.3
- [ ] Вкладка «AvaTracker Mobile» в веб-админке — ТЗ §14, §21
