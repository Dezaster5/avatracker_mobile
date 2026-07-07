# AvaTracker — подготовка к Google Play (Data Safety / App Content)

Аналог [`APP_STORE_REVIEW.md`](./APP_STORE_REVIEW.md) для Google Play Console.
AvaTracker — корпоративное приложение учёта рабочего времени: отметки
прихода/ухода по QR + геолокация, фото-верификация личности по ИИН.

---

## 1. Data Safety (Play Console → App content → Data safety)

Указывать «Collected», **не** «Not collected» — приложение реально собирает
эти данные и отправляет на сервер.

| Категория (Play Console) | Данные | Собирается | Назначение | Опционально? |
|---|---|---|---|---|
| Personal info | Name | Yes | App functionality | No |
| Personal info | Phone number | Yes | App functionality | No |
| Personal info | User IDs (ИИН как ID сотрудника) | Yes | App functionality | No |
| Location | Approximate location | Yes | App functionality | No |
| Location | Precise location | Yes | App functionality | No |
| Photos or videos | Photos (фото-верификация лица при QR-скане) | Yes | App functionality | No |
| App activity | App interactions (история отметок прихода/ухода) | Yes | App functionality | No |
| App info and performance | Crash logs | Yes | App functionality | No |
| App info and performance | Diagnostics | Yes | App functionality | No |

Для **каждой** из строк выше в форме:
- Purpose: только **App functionality**. Не отмечать Analytics /
  Advertising or marketing / Fraud prevention, security, and compliance —
  если позже добавите анти-фрод/защиту от мок-геолокации как отдельную
  цель, это можно расширить, но сейчас в коде она не заявлена отдельно.
- **"Is this data shared with third parties?"** → **No, data isn't
  shared** (данные не передаются сторонним организациям, обрабатываются
  только на сервере работодателя `avatracker.online`).
- **"Is this data processed ephemerally?"** → **No** (данные сохраняются
  на сервере для учёта, кроме фото — см. ниже).

### Security practices (тот же экран, блок Security practices)

- **"Data is encrypted in transit"** → **Yes** (весь трафик к
  `avatracker.online` идёт по HTTPS/TLS).
- **"Data is encrypted at rest"** → указывать **только если подтверждено
  бэкендером** (шифрование БД/дисков на сервере). Если не подтверждено —
  не отмечать; Google выборочно перепроверяет этот пункт.
- **"You can request that data be deleted"** → **Yes** — в приложении есть
  самостоятельное удаление аккаунта: `/delete-account` →
  `DELETE /api/mobile/profile/delete/` (Профиль → О приложении → Удалить
  аккаунт). Добавить ссылку на `https://avatracker.online/privacy` (раздел
  8 Политики) как способ узнать процедуру и для пользователей без доступа
  к приложению.
- **"Committed to follow the Play Families Policy"** → N/A, приложение не
  для детей.

### Про фото отдельно

Фото лица используется **только для верификации личности в момент
отметки** (сверка на сервере), не хранится как медиа-галерея и не
демонстрируется другим сотрудникам. Это стоит явно прописать в описании
назначения (Data type details → Photos → "Used to verify employee
identity during check-in, not shared or used for any other purpose") —
Google, как и Apple, обращает внимание на формулировки, связанные с
распознаванием лиц/биометрией.

---

## 2. App permissions, задействованные в приложении

Подтверждено по `android/app/src/main/AndroidManifest.xml`:

| Permission | Обоснование |
|---|---|
| `CAMERA` | Сканирование QR-кода на рабочей точке и фото-верификация личности при отметке. |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Подтверждение, что сотрудник находится рядом с рабочей точкой в момент QR-отметки. |
| `INTERNET` | Обмен данными с `avatracker.online`. |

**`ACCESS_BACKGROUND_LOCATION` в манифесте отсутствует** — геолокация
запрашивается только в момент использования (While in use), фоновая
геолокация не используется. Это важно: если бы фоновая геолокация была
нужна, Google требует отдельную форму обоснования (Background Location
permission declaration) — сейчас она не нужна.

---

## 3. Дистрибуция: публичный Play Store vs корпоративная

AvaTracker — вход только по корпоративному ИИН конкретной компании;
случайный пользователь Google Play не сможет им воспользоваться. Варианты:

1. **Closed testing** (Play Console → Testing → Closed testing) — доступ по
   списку email/групп, без публикации в открытом поиске. Хорошо подходит
   на этапе, пока нет полного количества тестеров/отзывов для перехода в
   Production.
2. **Managed Google Play** (через корпоративный Android Enterprise /
   EMM/MDM компании) — приложение публикуется приватно только для
   организации, минуя часть требований публичного стора. Подходит, если
   у компании уже есть корпоративное MDM-решение для сотрудников.
3. Обычная **Production**-публикация тоже возможна, но нужно в App
   content честно объяснить корпоративный характер приложения (в
   Description и, если попросят на ревью, в ответе на запрос Google) —
   аналогично Review Notes для Apple (см. `APP_STORE_REVIEW.md` §1).

Рекомендация: начать с Closed testing, перейти в Production или Managed
Google Play после того, как определится модель распространения сотрудникам
(этот пункт — решение бизнеса, не техническое).

---

## 4. Что уже реализовано в приложении (совпадает с App Store)

Экран intro, чекбокс согласия (с явным упоминанием биометрии — см.
`legal_content.dart` → `consentCheckbox`), Политика конфиденциальности в
9 разделах (`/privacy`), экран «О приложении» (`/about`), самостоятельное
удаление аккаунта (`/delete-account`), отсутствие фоновой геолокации,
отсутствие рекламных/трекинговых SDK. Подробности — `APP_STORE_REVIEW.md`
§3 (тот же список верен для Android-сборки).

---

## 5. TODO

1. Опубликовать `https://avatracker.online/privacy` (текст — см.
   `PRIVACY_POLICY.txt` в корне репозитория, вычитать перед публикацией).
2. Подтвердить у бэкендера, шифруются ли данные на сервере "at rest" —
   от этого зависит, отмечать ли соответствующий пункт Security practices
   в Data Safety.
3. Решить модель дистрибуции (Closed testing / Managed Google Play /
   Production) — см. §3.
4. Подготовить те же тестовые данные, что для Apple Review (тестовый ИИН,
   телефон, фиксированный SMS-код, тестовая QR-точка с неограниченным
   радиусом, обход фото-верификации для тестового аккаунта) — см.
   `APP_STORE_REVIEW.md` §1 и §4, если Google запросит доступ для проверки
   (обычно требуется реже, чем у Apple, но лучше иметь заранее).
