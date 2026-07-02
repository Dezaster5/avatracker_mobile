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

An informational screen explaining the purpose and the processed data is shown
before login, and registration requires explicit consent to personal data
processing. A Privacy Policy is available in the app (Profile → About →
Privacy Policy) and before login.

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

Account deletion: Profile → About → Request account deletion.
```

> Приложите к сабмишену изображение тестового QR-кода (Review Attachment) —
> генерируется так же, как рабочие точки: строка QR = `qr_id` тестовой точки.

---

## 2. App Privacy (App Store Connect → App Privacy)

Указать «Data collected / linked to the user». **Нельзя** ставить «Data Not Collected».

| Категория | Данные | Назначение | Linked |
|---|---|---|---|
| Contact Info | Phone Number | App Functionality | Yes |
| Identifiers | IIN, Employee ID, User ID | App Functionality | Yes |
| Location | Precise Location (только при отметке) | App Functionality | Yes |
| User Content | Employee photo / verification image | App Functionality | Yes |
| Usage Data | Attendance marks, check-in/out history, app activity, login events | App Functionality | Yes |
| Diagnostics | Crash logs, API errors, technical logs | App Functionality | Yes |

- Tracking: **No** (данные не используются для трекинга между приложениями).
- Third-party advertising: **No**.
- Privacy Policy URL: `https://avatracker.online/privacy` (нужно опубликовать
  общедоступную страницу — см. §5).

---

## 3. Что реализовано в приложении (App-side ✅)

| Требование | Где |
|---|---|
| Экран цели приложения перед вводом ИИН/телефона | `/intro` (перед входом) |
| Кнопки «Продолжить» + «Политика конфиденциальности» | экран intro |
| Чекбокс согласия на обработку ПДн, кнопка неактивна без него | экран регистрации |
| Сохранение факта согласия (iin, версия, дата) | secure storage `consent_json` |
| Пояснение назначения ИИН | экран регистрации |
| Privacy Policy внутри приложения (9 разделов) | `/privacy` (Профиль → О приложении, intro, вход) |
| Экран «О приложении» (версия, политика, согласие, удаление, поддержка) | `/about` |
| Запрос на удаление аккаунта | `/delete-account` → `POST /api/v1/mobile/account/delete-request` |
| iOS permission strings (камера, гео When-In-Use, микрофон) | `ios/Runner/Info.plist` |
| Геолокация только When In Use, без Always/фона | нет запроса Always в коде |
| Термин «фото-верификация / проверка лица» (не «Face ID») | экран проверки лица |
| Нет рекламных/трекинговых SDK | зависимости: только функциональные |

---

## 4. Что нужно на стороне бэкенда / App Store Connect (TODO)

1. **Эндпоинт удаления аккаунта**: `POST /api/v1/mobile/account/delete-request`
   тело `{iin, phone, reason}` → `{success, message}`. Приложение уже его вызывает.
2. **Тестовый аккаунт для Apple Review**: активный сотрудник
   `IIN 123456789012`, телефон `+7 700 123 45 67`, **фиксированный SMS‑код `0000`**
   без реальной отправки SMS; с ФИО, должностью, отделом и тестовой историей отметок.
3. **Тестовая QR-точка**: `qr_id` с **неограниченным радиусом** (как существующая
   точка «тест»), чтобы гео-проверка проходила из любого места. Сгенерировать
   QR-изображение и приложить в Review Notes.
4. **Фото-верификация для тестового аккаунта**: пропускать сверку лица (иначе
   ревьюер не пройдёт проверку — его лицо не совпадёт с фото сотрудника).
5. **Публичная страница Privacy Policy** по адресу из App Store Connect
   (текст — в приложении, раздел `/privacy`).

---

## 5. Privacy Policy URL

App Store Connect требует **публичный URL** политики (в дополнение к экрану в
приложении). Опубликуйте страницу с тем же текстом, что в приложении
(`lib/features/legal/legal_content.dart` → `privacySections`), по адресу
`AppConfig.privacyPolicyUrl` (`https://avatracker.online/privacy`).

Также заполните контакты ответственного лица (`AppConfig.supportEmail`,
`AppConfig.companyName`) актуальными значениями компании.

---

## 6. Чего в приложении НЕТ (по требованиям Apple) — и это правильно

Рекламных SDK, сторонней аналитики, скрытого трекинга, фоновой геолокации,
запроса Location Always, сбора данных без объяснения, входа по ИИН без пояснения,
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
