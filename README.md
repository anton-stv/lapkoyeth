# ЛапкойЭть

Flutter-приложение для владельцев питомцев. Android и Web используют общую
Firebase Auth/Firestore модель, а Hive остаётся локальным офлайн-кэшем.

## Web

- Production: <https://lapkoyeth.web.app>
- GitHub Pages workflow: `.github/workflows/flutter_web_pages.yml`
- Локальная production-сборка: `flutter build web --release`
- GitHub Pages build: `flutter build web --release --base-href /lapkoyeth/`

## Проверка

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Firebase Web app, Hosting и Firestore rules настроены для проекта `lapkoyeth`.
Перед загрузкой пользовательских фотографий нужно один раз включить Firebase
Storage в консоли и задеплоить `storage.rules`.
