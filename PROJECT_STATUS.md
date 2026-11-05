# Tiko project status

## Product and decisions
Offline Flutter iOS/Android prepaid subscription tracker. Tagline: Every use counts.
Both native identifiers are now com.tiko.app. This installs separately from the older com.tiko.tiko app; its data has not been deleted or automatically migrated. Outside-validity entries require an explicit override. No backend, authentication, telemetry or production mock data.

## Implemented
- Drift schema v2 preserves subscriptions/events and adds persistent preferences; migration/reopen tests cover existing data.
- Complete subscription creation/editing/archive/restore/delete/renewal, linked historical periods and financial details. Optional trolleybus and gym templates.
- Fast shared +1 action, UTC timestamp capture, cross-screen rapid-tap suppression, optional haptics, exact-event Undo and validity confirmation.
- Full editable/manual history, local-date grouping, subscription/date filters, stable bounded reactive loading and filtered CSV export.
- Persistent four-tab navigation: Home, Analytics, History and Settings. Home uses SQL totals and collapsed archived cards; details load only 50 recent events.
- Daily/weekly/monthly usage bars, 12-week calendar heatmap, cumulative cost history, frequency/recency metrics and conservative labeled forecasts. Monetary analytics remain per subscription.
- Generated English/Romanian ARB localization with plurals and local formatting; persistent theme/language/haptics.
- Versioned JSON backups with preview, validation, duplicate skipping, UUID conflict detection and atomic rollback; CSV and native share UI.
- Custom vector-derived Tiko launcher icons, Android adaptive/monochrome icons, native launch screens and matching Flutter loading mark. No artificial splash delay.
- Registered subscription deep links; opening links does not add events. Missing/deleted periods can return Home. Optional widget feasibility is documented in docs/IOS_WIDGET.md; no widget extension is shipped.
- Financial arithmetic ranges are checked in write transactions to prevent overflow; backups reject timestamps below the current database's one-second precision.

## Architecture
Presentation currently shares app providers through Dart library parts. Independent repositories own persistence and pure services own financial/date/analytics calculations. README.md documents schemas, formulas, setup, backup behavior and dependencies. Generated files and pubspec.lock should be committed; secrets, build artifacts and local SDK configuration must remain excluded.

## Verification
All 36 tests pass. Static analysis, formatting and whitespace checks pass. Backup/history tests also pass in Europe/Bucharest across the spring DST boundary. Android debug APK compilation succeeded, and the rebranded app built/launched on the iPhone 17 simulator. Simulator screenshots and URL opening verified that routing reaches a missing-subscription screen; the recovery button is covered by widget tests. The final incremental Android APK build and iPhone 17 simulator build/launch both succeeded. Do not infer manual file-picker/share-sheet or physical-device validation from these results.

## Remaining / next step
Manually exercise native export/import/sharing and accessibility on devices. Profile large analytics histories; analytics currently loads events when its tab opens. Complete release signing/store configuration before publishing. Evaluate a real WidgetKit/AppIntent extension with a registered App Group and shared SQLite migration; deep links are the current fallback. Installed file_picker/share_plus emit a future KGP compatibility warning on Android, although the current build succeeds.
