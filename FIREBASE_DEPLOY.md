# Firebase: подготовка поиска пользователей

Проект Firebase: `lapkoyeth`.

## 1. Установить инструменты и войти

В терминале из корня проекта:

```bash
npm install -g firebase-tools
firebase login
firebase use lapkoyeth
```

Если `firebase use` сообщает об отсутствии доступа, проверьте, что Google-аккаунт
добавлен в Firebase Console → Project settings → Users and permissions.

## 2. Задеплоить правила и индекс

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Затем откройте Firebase Console → Firestore Database → Indexes. Индекс для
`users` (`profilePublic` Ascending + `searchTokens` Arrays) сначала будет в
статусе Building. Продолжайте только после статуса Enabled.

## 3. Мигрировать существующих пользователей

Скрипт дополняет документы полями `displayName`, `publicId`, `searchTokens`,
`profilePublic`, `petsPublic` и удаляет контактные поля из публичной коллекции.
Он идемпотентен: повторный запуск безопасен.

Сначала установите Google Cloud CLI, затем:

```bash
gcloud auth application-default login
gcloud config set project lapkoyeth
cd tools/firebase-migration
npm install
GOOGLE_CLOUD_PROJECT=lapkoyeth npm run migrate
```

Не скачивайте и не пересылайте service-account JSON: для этой операции он не
нужен. Владелец проекта должен иметь право записи в Firestore.

## 4. Проверить

1. В `users/{uid}` должны появиться `profilePublic: true`, `publicId` и массив
   `searchTokens`; полей `email` и `phone` там быть не должно.
2. Войти в приложение двумя разными аккаунтами.
3. В «Петобщество → Найти» искать второй аккаунт по началу имени, фамилии и
   полному `LP-...` ID. Собственный аккаунт намеренно не выводится.
4. Если приложение показывает `failed-precondition`, индекс ещё строится или
   задеплоен не в тот проект. `permission-denied` означает, что правила не
   задеплоены либо приложение подключено к другому Firebase-проекту.

## Откат правил

Перед деплоем Firebase CLI выводит целевой project ID. Если он не `lapkoyeth`,
отмените команду. История опубликованных Rules доступна в Firebase Console;
предыдущую версию можно выбрать и опубликовать повторно.
