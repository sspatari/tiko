# Tiko

Every use counts.

## Current status

Core implementation in progress: counter creation, Drift tables, timestamped +1
recording, per-counter tap suppression, exact-event Undo, basic history and
financial calculations are implemented. Database bindings are generated in `lib/core/database/database.g.dart`.
Initial validation passed all seven tests; physical-device validation is pending.

Localization of app labels, lifecycle management, complete history editing,
analytics, backups, settings and widgets remain outstanding.

## Generate and validate

Run from the project directory in macOS Terminal:

```sh
flutter pub get
dart run build_runner build
dart format lib test
flutter analyze
flutter test
```

## Tooling

Flutter runs successfully outside the restricted execution sandbox. Commands
launched by the coding agent require approval to run outside that sandbox,
because macOS CPU queries used by Dart are blocked inside it. Flutter works
normally in macOS Terminal; no SDK reinstall is needed.

Full Xcode configuration is required for iOS device/simulator builds.

## Intended architecture

Feature-first Flutter application with Riverpod, GoRouter, Drift/SQLite,
English/Romanian localization and no backend. Individual timestamped usage
events are the source of counts. Money is stored in integer minor units.
The domain calculator rounds average cost to the nearest minor unit, calculates
break-even using integer ceiling division, and leaves progress uncapped.
