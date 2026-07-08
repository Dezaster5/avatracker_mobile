# Security

## Секреты

Запрещено коммитить:

- `.env`, `.env.local` и другие локальные env-файлы;
- access/refresh/Bearer-токены;
- SMSC.kz login, password или API key;
- `android/key.properties`, `*.jks`, `*.keystore`;
- Apple `*.p8`, `*.p12`, provisioning profiles;
- APK, AAB и IPA.

В репозитории разрешены только шаблоны `.env.example` и
`*.env.example` с placeholders.

Если секрет попал в commit, удаления файла следующим commit недостаточно.
Нужно немедленно отозвать токен или ключ, выпустить новый и очистить Git history.

## Персональные данные

Не используйте реальные ИИН, ФИО, телефоны, фотографии и email сотрудников в
тестах, документации или mock-данных. Для фикстур применяются синтетические
значения.

Production-данные нельзя прикладывать к issue, pull request, CI log или GitHub
Release.

## Локальное хранение

Приложение сохраняет access token, refresh token, ИИН, телефон, выбранную
локаль/страну и кеш профиля через `flutter_secure_storage`.

Приложение не должно сохранять пароль, SMS-код или снимок для Face verification.

Сохранение логина/пароля пользователем выполняется только через системный
менеджер паролей устройства:

- iOS Passwords / Keychain с доступом через Face ID или код устройства;
- Android Password Manager / Google Password Manager.

Для этого поля входа и регистрации размечены `AutofillHints.username`,
`AutofillHints.telephoneNumber`, `AutofillHints.password` и
`AutofillHints.newPassword`, а после успешной авторизации приложение вызывает
`TextInput.finishAutofillContext(shouldSave: true)`. Пароль при этом не
появляется в `flutter_secure_storage` и не пишется в кеш приложения.

## Отчёт об уязвимости

Не создавайте публичный issue с токенами, персональными данными или инструкцией
по эксплуатации уязвимости. Передайте описание владельцу приватного
репозитория или на `info@avtch.io`, указав версию приложения, платформу и
минимальные шаги воспроизведения.
