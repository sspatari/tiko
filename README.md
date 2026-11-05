# Tiko

Every use counts.

Tiko is an offline Flutter prepaid subscription and usage tracker for iOS and
Android. There is no account, backend, telemetry, or production seed data.

## Features

- Create and edit unlimited subscriptions, including optional trolleybus/gym
  templates, categories, icons, colors, prices, currencies and validity dates.
- Home prioritizes active periods, with archived subscriptions collapsed. Large
  +1 controls record UTC timestamps; rapid taps are suppressed and five-second
  Undo deletes the exact event. Uses outside validity require confirmation.
- Subscription details show usage, average cost, equivalent individual cost,
  savings/unrecovered cost and break-even metrics. Missing reference prices hide
  reference-dependent results.
- Archive/restore, confirmed deletion and transactional renewal. Renewals create
  separate linked periods and preserve historical events.
- History supports manual entry, date/time, quantity and note editing, confirmed
  deletion, local-date grouping, subscription/date filters and 50-event loading
  steps. Its CSV export follows the current filters.
- Analytics includes daily/weekly/monthly usage bars, a calendar heatmap,
  cumulative average cost and frequency. Per-subscription projections require
  seven elapsed days and activity on three dates; expired/archived periods are
  not forecast. Projections are explicitly labeled estimates.
- Persistent system/light/dark appearance, system/English/Romanian language,
  optional haptics and generated localized labels/plurals/date/currency formats.
- Versioned JSON backups, validated transactional import with preview and UUID
  conflict detection, CSV exports and native share sheets.
- Custom Tiko launcher icons, Android adaptive/monochrome icons, native launch
  screens, accessible chart labels and scalable text.

## Run and validate

Install Flutter stable compatible with the Dart constraint in `pubspec.yaml`.
From the project root:

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
dart format lib test
flutter analyze
flutter test
flutter run
```

For iOS install Xcode and an iOS Simulator runtime, select Xcode's command line
tools, open Simulator and run `flutter run`. Physical devices need your own
signing team. For Android install Android Studio/SDK and an emulator, accept SDK
licenses with `flutter doctor --android-licenses`, then run `flutter run` with the
emulator booted. `flutter doctor` diagnoses local setup problems.

Both native identifiers are `com.tiko.app`. This is separate from older
`com.tiko.tiko` installations: their data is not automatically moved. Export a
JSON backup from a compatible old installation before switching if needed.
Flutter commands in a restricted agent session need approval for SDK/cache and
simulator access. An SDK reinstall is not required.

## Architecture and dependencies

Feature directories separate persistence repositories, domain calculations and
presentation. Riverpod owns reactive database/providers and preferences. GoRouter
provides four persistent navigation branches (Home, Analytics, History, Settings)
and subscription-detail routes. Presentation files currently share app providers
as Dart library parts; domain services and repositories are independent of widgets.

Drift/drift_flutter provide SQLite and migrations. intl and flutter_localizations
provide formatting; Flutter generates localization classes from English/Romanian
ARB resources. uuid provides IDs; file_picker and share_plus handle backup files
and native sharing. Built-in Flutter drawing/widgets render the simple charts.
Dependencies are locked in `pubspec.lock`; no cloud services are configured.

## Database and financial calculations

Schema v2 contains subscriptions, usage_events and app_settings. The v1-to-v2
migration adds preferences without rewriting subscriptions/events. Usage events
reference subscriptions with cascading deletion and a subscription/time index.
Renewal groups link periods without merging event histories. Dashboard totals use
SQL aggregates, details load only recent events, and full history is bounded and
reactive. Analytics reads individual events when its tab is opened.

Events store UTC instants at SQLite's current one-second precision and display in
local time. Validity boundaries are calendar dates encoded at UTC midnight; they
are compared to local event-date components without shifting their calendar date.
Date-range filters use local midnight through the exclusive next local midnight,
including 23/25-hour daylight-saving days. Reads refresh when the app resumes.

Money is stored as integer currency minor units. Currency-specific precision
supports, for example, MDL/EUR (2), JPY (0), and KWD (3). Total usage sums event
quantities. Average cost rounds half-up in minor units. Equivalent cost is uses
times reference price; savings subtracts prepaid cost. Break-even uses integer
ceiling division; remaining usage stops at zero. Progress can exceed 100%, with
only the bar visually capped. Different currencies are never combined into one
monetary total. Out-of-range integer results are rejected transactionally rather
than overflowing; the supported exact financial integer maximum is 2^53 - 1.

Forecasts use quantity recorded within validity divided by elapsed calendar days.
Average monthly frequency uses 30.4375 days. Estimated break-even may fall after
expiration and is labeled accordingly; expiration projections require an end date.

## Backup format

JSON schema version 1 contains subscriptions, individual events, preferences and
an export timestamp. IDs and renewal relationships are preserved. Calendar dates
use YYYY-MM-DD; UTC instants use ISO 8601 with Z at database precision (whole
seconds). Imports validate types, UUIDs, monetary ranges, quantities, dates and
relationships before writing. Nonzero subsecond input is rejected to avoid silent
loss of precision and inconsistent repeated imports.

Imports merge by UUID: identical records are skipped, missing records inserted,
and conflicting existing records reject the entire transaction. Preferences are
restored too, as described in the confirmation preview. CSV uses UTF-8, quoted
fields, UTC timestamps and spreadsheet-formula protection for text cells.

## Branding and platform enhancements

The editable mark is `assets/brand/tiko.svg`. To regenerate native PNG sizes on
macOS, run `swift tool/generate_brand.swift` from the project root. The launch
screens add no artificial delay. Android 12+ has dedicated splash theme resources.

`tiko:///subscriptions/<UUID>` opens subscription details and never records a
use. Missing subscriptions have a route back Home. See `docs/IOS_WIDGET.md` for
the optional interactive-widget evaluation; no WidgetKit extension is shipped.

## Verification and remaining platform work

Unit, repository and widget tests cover money, usage, Undo, lifecycle, renewal,
history/filtering/pagination, projections, localization, large text, settings,
database reopening/migration and backup validation/rollback. See PROJECT_STATUS.md
for the latest actual test/build outcomes.

Physical-device testing, native file-picker/share-sheet interactions, accessibility
with VoiceOver/TalkBack, release signing/store packaging and extended performance
profiling remain before a public release. The installed file-picker/share plugins
currently emit a warning about future Flutter Kotlin Gradle Plugin compatibility;
the present Android debug build succeeds. Interactive widgets remain optional.
