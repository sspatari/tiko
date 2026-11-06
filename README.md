# Tiko

Every use counts.

Tiko is an offline Flutter prepaid subscription and usage tracker for iOS and
Android. There is no account, backend, telemetry, or production seed data.

## Features

- Create and edit unlimited subscriptions, including optional trolleybus/gym
  templates, categories, icons, colors, prices, currencies and validity dates.
- Home supports pinned subscriptions, saved ordering and optional compact cards
  through Customize Home. Archived subscriptions remain collapsed. Large
  +1 controls record UTC timestamps; rapid taps are suppressed and five-second
  Undo deletes the exact event. Uses outside validity require confirmation.
- Subscription details show usage, average cost, equivalent individual cost,
  savings/unrecovered cost and break-even metrics. Missing reference prices hide
  reference-dependent results. Home/details explain remaining uses and celebrate
  recovering prepaid cost compared with paying per use; closed periods show a
  shortfall rather than suggesting future uses. Free subscriptions have separate
  wording, and missing single-use prices hide the comparison.
- Archive/restore, confirmed deletion and transactional renewal. Renewals create
  separate linked periods and preserve historical events.
- History supports manual entry, date/time, quantity and note editing, confirmed
  deletion, local-date grouping, subscription/date filters and 50-event loading
  steps. Its CSV export follows the current filters.
- Analytics includes daily/weekly/monthly usage bars, a calendar heatmap,
  cumulative average cost and frequency. Per-subscription projections require
  seven elapsed days and activity on three dates; expired/archived periods are
  not forecast. Projections are explicitly labeled estimates.
- Optional offline expiry notifications, enabled in Settings: three days before
  expiry and on the expiry date at 9 AM local time. Tapping opens the subscription.
- Persistent system/light/dark appearance, system/English/Romanian language,
  optional haptics and generated localized labels/plurals/date/currency formats.
- Versioned JSON backups, validated transactional import with preview and UUID
  conflict detection, CSV exports and native share sheets.
- Custom Tiko launcher icons, Android adaptive/monochrome icons, native launch
  screens, accessible chart labels and scalable text.

## Continue development

The unfinished feature ideas are a last successful backup indicator with optional
reminders and Home Screen widgets. Clearer break-even milestone messages, Home
customization, expiry badges, animations and grouped forms are implemented.

See [the continuation backlog in PROJECT_STATUS.md](PROJECT_STATUS.md#continuation-backlog)
for feature checklists, incomplete device verification and the test-isolation work
that must happen before any further automated phone testing.

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

Both iOS and Android use `com.sspatari.tiko`.
These are separate from older `com.tiko.tiko` installations: their data is not automatically moved. Export a
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

## Expiry reminders

Enable **Settings → Expiry reminders** to request notification permission. No
permission prompt appears at startup. Denial leaves the switch off; enable Tiko
notifications in phone settings and retry. Existing in-app expiry labels remain
available without notification permission.

Reminders use local OS scheduling and work without internet or an open app.
Edits, renewal, archive/restore, deletion, backup import and preference changes
refresh the schedule. Only the newest created period in each renewal group gets
reminders. Past reminder times are skipped. Disabling cancels Tiko notifications.
The preference uses the existing app_settings table; old backups default it off.
Restored preferences never prompt for OS permission automatically.

The nearest 64 future notifications are scheduled to respect iOS limits; opening
the app replenishes the schedule. Android uses inexact alarms without requiring
special exact-alarm access, so delivery can be delayed by the OS. Android reboot
and app-update receivers restore scheduled reminders. Time-zone and system-language
changes refresh on app resume; reopen Tiko after travel to refresh local times.
Notifications are localized in English/Romanian. OS delivery, permission prompts,
reboot recovery and tap routing still need physical-device validation.

## Home layout

Use the **Customize Home** button in the Home toolbar to pin subscriptions,
reorder within pinned/unpinned groups, and enable compact cards. The row menus
also provide Move up/Move down for accessibility. Save applies changes; going
back discards the draft. Reset Home layout restores full cards and the default
validity/alphabetical order when saved.

Pinned subscriptions appear first; explicit order takes priority over validity
sorting. New subscriptions follow existing arranged cards. Archived subscriptions
stay collapsed and retain their layout preferences for restoration. Deleted or
missing IDs are ignored and cleaned up the next time the layout is saved.
Layout preferences use the existing app_settings table and are included in JSON
backups. Old backups default to full cards without pins or manual ordering.

## Isolated UI test workflow

The production identity remains `com.sspatari.tiko`. Integration builds use
`com.sspatari.tiko.uitest`, the name **Tiko UI Test**, and the `tiko-uitest` URL
scheme. No shared App Group or shared database is configured.

- iOS uses the separate `uitest` scheme/configurations. A build guard rejects
  alternate Dart entrypoints using the production identity or URL scheme.
- Android assigns the test identity to alternate Dart entrypoints automatically.
  Normal `lib/main.dart` builds retain the production identity.
- The supported runner refuses physical devices before building. It checks the
  built bundle/APK's actual application ID before invoking the test runner.

Use a disposable, booted simulator/emulator with synthetic data:

```sh
dart run tool/run_ui_review.dart ios <simulator-id>
# Or:
dart run tool/run_ui_review.dart android <emulator-id>
```

The runner builds the test entrypoint, verifies the artifact, and runs the review
from a temporary verified copy so concurrent normal builds cannot replace it.
On Android it needs the SDK's `aapt` to inspect the manifest; inability to inspect
identity aborts deployment. Screenshots, results and failure metadata go to the
host temporary directory under `tiko-ui-review` (override with
`TIKO_SCREENSHOT_DIR`). No build artifacts or screenshots belong in Git.

Do not bypass these checks or run raw `flutter drive` against a production app.
Flutter drive uninstalls its app by default after tests, including failures.
In-memory fixtures and `--keep-app-running` are not substitutes for an isolated
native identity. Physical-device runs remain outside the supported workflow.

The workflow passed an end-to-end check on a newly created iPhone simulator:
the test app was automatically uninstalled while the normal app, its container
and all rows in a controlled synthetic database baseline remained intact. This
verification used no phone data. See PROJECT_STATUS.md for evidence and limits.

### Previous data-loss incident

Earlier phone tests used the production identity and likely removed the user's
original database through automatic test cleanup. The previous assurance that
those tests preserved the data was wrong. Reinstalling the normal release does
not recover deleted records; no pre-test backup or recovery has been verified.

Previous phone runs checked usage/Undo, Home layout and light/dark, Romanian and
2x-text rendering. Full native keyboard/form validation, notification delivery
and VoiceOver/TalkBack review remain incomplete. See PROJECT_STATUS.md for the
latest verification of the repaired harness; do not infer those checks passed
from its implementation. No further phone testing or changes are authorized by
this handoff.
