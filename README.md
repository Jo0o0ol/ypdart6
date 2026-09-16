# Практическая работа №6 — Адаптивная вёрстка, сборка, публикация и тестирование

Продолжение ПР5 на базе исходного библиотечного проекта.

## Локальный запуск

Терминал 1:

```bat
node api\mock-server.js --port 8080 --origin http://localhost:5555
```

Терминал 2:

```bat
flutter pub get
flutter run -d chrome --web-port=5555 --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080/api
```

## Проверки

```bat
flutter analyze
flutter test
dart format --set-exit-if-changed lib test
```

## Адаптивность

Проверить ширины `360`, `768`, `1280`, `1920`. На телефоне — карточки и нижняя навигация; на среднем — NavigationRail; на широком — таблицы и развёрнутая боковая навигация.

## Release

```bat
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080/api
```

## WASM

```bat
flutter build web --release --wasm --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080/api
```

В проекте есть стартовая HTML-заглушка, offline/error state, модульные и widget-тесты, `BUILD_MEASUREMENTS.md` и workflow для GitHub Pages. Для публикации обязательно заменить `--base-href` на имя своего репозитория и указать HTTPS API.
