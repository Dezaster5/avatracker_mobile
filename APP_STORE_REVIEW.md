# AvaTracker — подготовка к App Store / Apple Business Manager

Материалы для App Store Connect и статус реализации требований App Review.
AvaTracker — корпоративное приложение для сотрудников: учёт рабочего времени,
отметки прихода/ухода по QR + геолокация, проверка активности сотрудника по ИИН,
фото-верификация личности.

---

## 1. App Review Notes (вставить в App Store Connect → App Review Information → Notes)

```
This is a corporate employee attendance tracking app for AvaTracker.

The app is used only by company employees to check in and check out, monitor
attendance, and verify employee activity. It is intended for internal/enterprise
distribution.

The app uses the employee IIN (national individual identification number) only to
identify an active employee account in the internal AvaTracker system.

During QR check-in, the app captures a face photo and sends it to our server for
biometric verification against the employee's stored photo, to confirm the person
checking in is the account owner. This is explained in the in-app Privacy Policy
and the explicit consent checkbox shown on the registration screen.

Registration requires explicit consent to personal data processing. A Privacy
Policy is available in the app (Profile → About → Privacy Policy) and before
login.

Test credentials:
IIN: 123456789012
Phone: +7 700 123 45 67
SMS code: 0000

The test account is active and contains sample employee data (name, position,
department, attendance history).

QR check-in requires being near the workplace. For review, please use the test
QR code attached to this submission (App Review Attachment). The test QR point is
configured with an unrestricted radius so location verification passes from any
location. Face verification is bypassed for the test account.

Location is requested only during QR check-in (When In Use) to verify that the
employee is near the workplace. Camera is used only for QR scanning and face
verification. The app does not use background location and contains no advertising
or third‑party tracking SDKs.

Account deletion: Profile → About → Delete account (fully deletes the mobile
account; the user can re-register afterwards).
```

> Приложите к сабмишену изображение тестового QR-кода (Review Attachment) —
> генерируется так же, как рабочие точки: строка QR = `qr_id` тестовой точки.

---

## 2. App Privacy (App Store Connect → App Privacy)

Указать «Data collected / linked to the user». **Нельзя** ставить «Data Not Collected».

| Категория | Данные | Назначение | Linked |
|---|---|---|---|
| Contact Info | Name, Phone Number | App Functionality | Yes |
| Identifiers | IIN, Employee ID, User ID | App Functionality | Yes |
| Location | Precise Location (только во время QR-отметки, When In Use) | App Functionality | Yes |
| Sensitive Info / Health & Fitness¹ | Face photo — **биометрическая верификация личности** | App Functionality | Yes |
| User Content | Employee photo | App Functionality | Yes |
| Usage Data | Attendance marks, check-in/out history, app activity, login events | App Functionality | Yes |
| Diagnostics | Crash logs, API errors, technical logs | App Functionality | Yes |

¹ Apple не имеет отдельной категории «Biometric Data» в форме App Privacy —
фото для верификации личности декларируется как **User Content → Photos or
Videos**, но в описании назначения (Purpose) и в Review Notes нужно явно
написать словом **"biometric"/"биометрическая верификация"**, что фото
используется именно для сверки личности сотрудника (face verification),
а не хранится как медиа-контент. Это соответствует тексту Политики версии 2.0
в `PRIVACY_POLICY.txt`, где биометрия названа явно.

- **Data Use → Purpose**: везде **App Functionality**. Не указывать
  Analytics/Advertising/Third-Party Advertising ни для одной категории.
- **Data linked to identity**: **Yes** для геолокации, фото и всех
  идентификаторов — привязаны к ИИН или ПИНФЛ сотрудника.
- **Tracking**: **No** (данные не используются для трекинга между
  приложениями/сайтами сторонних компаний).
- **Third-party advertising**: **No**.
- **Data shared with third parties**: **No** — данные не передаются
  сторонним организациям (только внутри системы работодателя).
- **Data encrypted in transit**: **Yes** — всё общение с бэкендом идёт по
  HTTPS/TLS (`https://avatracker.online`).
- **Data deletion**: **Yes** — реализовано через `/delete-account`
  (`DELETE /api/mobile/profile/delete/`), см. §3.
- Privacy Policy URL: `https://avatracker.online/privacy-policy/`. Перед новой
  отправкой на review опубликовать по этому адресу текст версии 2.0 из
  `PRIVACY_POLICY.txt`.

### Почему приложение может показаться ревьюеру «непонятным» для App Store

AvaTracker — вход только по корпоративному идентификатору сотрудника, обычный
пользователь App Store не сможет им воспользоваться. Это частая причина
дополнительных вопросов от ревью. Меры уже приняты:
1. Test-аккаунт и тестовые данные обязательно указаны в Review Notes (см. §1)
   — без них ревьюер не сможет пройти дальше экрана входа и отклонит заявку.
2. Privacy Policy доступна до входа, а регистрация требует явного согласия на
   обработку персональных данных.
3. Если приложение остаётся строго внутренним (не для публичного поиска в
   App Store), стоит рассмотреть распространение через **Apple Business
   Manager → Custom Apps** — приватная дистрибуция только для организации,
   с отдельным (упрощённым) процессом ревью, минуя публичный App Store
   (см. §7).

---

## 3. Что реализовано в приложении (App-side ✅)

| Требование | Где |
|---|---|
| Чекбокс согласия на обработку ПДн, кнопка неактивна без него | экран регистрации |
| Сохранение факта согласия (iin, версия, дата) | secure storage `consent_json` |
| Пояснение назначения ИИН | экран регистрации |
| Privacy Policy внутри приложения (9 разделов) | `/privacy` (Профиль → О приложении, вход) |
| Экран «О приложении» (версия, политика, удаление, поддержка) | `/about` |
| Удаление аккаунта | `/delete-account` → `DELETE /api/mobile/profile/delete/` (полное удаление + разлогин) |
| iOS permission strings (камера, гео When-In-Use, микрофон) | `ios/Runner/Info.plist` |
| Геолокация только When In Use, без Always/фона | нет запроса Always в коде |
| Термин «фото-верификация / проверка лица» (не «Face ID») | экран проверки лица |
| Нет рекламных/трекинговых SDK | зависимости: только функциональные |

---

## 4. Что нужно на стороне бэкенда / App Store Connect (TODO)

1. ~~Эндпоинт удаления аккаунта~~ — **готово**: `DELETE /api/mobile/profile/delete/`
   (JWT) полностью удаляет мобильный аккаунт; данные сотрудника сохраняются,
   для входа нужна повторная регистрация. Приложение его вызывает и после
   удаления разлогинивает пользователя на экран входа.
2. **Тестовый аккаунт для Apple Review**: активный сотрудник
   `IIN 123456789012`, телефон `+7 700 123 45 67`, **фиксированный SMS‑код `0000`**
   без реальной отправки SMS; с ФИО, должностью, отделом и тестовой историей отметок.
3. **Тестовая QR-точка**: `qr_id` с **неограниченным радиусом** (как существующая
   точка «тест»), чтобы гео-проверка проходила из любого места. Сгенерировать
   QR-изображение и приложить в Review Notes.
4. **Фото-верификация для тестового аккаунта**: пропускать сверку лица (иначе
   ревьюер не пройдёт проверку — его лицо не совпадёт с фото сотрудника).
5. ~~Публичная страница Privacy Policy~~ — **готово**:
   `https://avatracker.online/privacy-policy/` (текст также доступен в
   приложении, раздел `/privacy`).

---

## 5. Privacy Policy URL

App Store Connect требует **публичный URL** политики (в дополнение к экрану в
приложении). Используется адрес `AppConfig.privacyPolicyUrl`
(`https://avatracker.online/privacy-policy/`) — этот же URL указывается в
App Store Connect и Google Play Console. До отправки версии 1.0.6 на review
разместить по этому адресу Политику версии 2.0.

Текст на сайте должен совпадать с `PRIVACY_POLICY.txt` версии 2.0. Этот же
файл включён в assets приложения и показывается на экране `/privacy`, поэтому
отдельной сокращённой копии политики в Dart-коде больше нет.

Также заполните контакты ответственного лица (`AppConfig.supportEmail`,
`AppConfig.companyName`) актуальными значениями компании.

---

## 6. Чего в приложении НЕТ (по требованиям Apple) — и это правильно

Рекламных SDK, сторонней аналитики, скрытого трекинга, фоновой геолокации,
запроса Location Always, сбора данных без объяснения, входа по идентификатору
без пояснения,
регистрации без Privacy Policy и без согласия.

---

## 7. Сборка iOS

iOS собирается только на macOS (Xcode). На этой машине (Windows) подготовлены
исходники, экраны и `Info.plist`. На Mac:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release   # или через Xcode: Product → Archive
```

Для Custom App (Apple Business Manager) — распространение через Apple Business
Manager после прохождения App Review; bundle id: `kz.avatariya.avatracker_mobile`.

---

## 8. См. также

- [`GOOGLE_PLAY_REVIEW.md`](./GOOGLE_PLAY_REVIEW.md) — заполнение Data Safety
  для Google Play Console (аналог этого документа для Android).
- [`PRIVACY_POLICY.txt`](./PRIVACY_POLICY.txt) — единый текст Политики
  конфиденциальности версии 2.0 для приложения и публикации на
  `https://avatracker.online/privacy-policy/`.
