# Tiko project status

## Action and card visual refinements
- Permanent subscription/event deletion now uses theme error colors in menus,
  detail-page trash buttons and confirmation buttons. Cancel stays neutral;
  non-destructive confirmations retain primary styling.
- Subscription and History menus share icon/label styling with Delete separated
  by a divider. Edit and Archive/Restore stay neutral; Renew uses the primary
  color. Popup menus have consistent rounded surfaces in light and dark themes.
- Home cards use tinted icon containers, clearer average-cost typography, quieter
  prepaid/break-even labels, rounded progress bars and secondary Details links.
  Existing localized labels, calculations and data behavior are preserved.
- Verification: dart format lib test, flutter analyze, all 48 tests and git diff
  --check pass. Existing widget tests cover large text, navigation, confirmation,
  archive/restore and deletion. No new simulator or physical-device validation.
  Next useful step: review Home and action menus on the phone in light/dark mode,
  Romanian and large text, alongside the outstanding real notification checks.

## Offline expiry notifications
- Added opt-in Settings reminders at 9 AM local time three days before expiry
  and on the expiry date. Permission is requested only when enabling; denied
  permission leaves reminders off and shows guidance. Scheduling errors offer retry.
- Local notifications refresh from reactive subscription/preference changes and
  app resume, including edits, archive/restore, deletion, renewal and imports.
  Only the newest created renewal period is scheduled. Notification taps open
  details on cold/warm launch without recording usage; missing periods use the
  existing recovery screen.
- Preferences use the existing settings table with no schema migration; old
  backups default reminders off. English/Romanian notifications are generated
  from ARB strings. Android has boot/update receivers, a monochrome notification
  icon and Java desugaring; iOS registers its notification delegate.
- flutter_local_notifications is pinned to the compatible v21 major. An initial
  v23 Android build failed on its SDK 37 requirement; the final v21 Android debug
  APK and iOS simulator debug app both build successfully. Existing file-picker /
  share KGP warnings remain. Formatting, analysis and all 48 tests pass; permission
  UI and database-reopen tests also passed on a focused repeat. Whitespace checks
  pass. No notification delivery or simulator/physical-device interaction was
  manually validated for this feature.
- Limits: nearest 64 future requests, past times skipped, Android inexact alarms
  may be delayed, time-zone/system-language changes refresh on resume. See README.
  Next useful step: enable notifications on iPhone/Android and check real delivery,
  denial/re-enable, reboot recovery, tapping from a terminated app, and cancellation
  after editing/renewing/archiving/deleting. Do not claim these device checks yet.

## Undo timeout fix
Recording snackbars explicitly disable persistence so Undo dismisses after five
seconds on the current Flutter SDK. Flutter accessibility behavior is preserved.
Regression tests verify expiry keeps the recorded use and pressing Undo dismisses
the snackbar and deletes the event. Formatting and static analysis pass; all 37
tests pass. No simulator or physical-device validation was performed for this fix.
Recording messages now replace the previous snackbar and include a localized
close button. Tests verify closing preserves the event, and replacement Undo
deletes only the latest event without resurfacing older messages. Formatting,
analysis and all 39 tests pass; whitespace checks pass. No device validation was
performed. Next useful step: verify dismissal/replacement on the installed phone.
Expiry phone notifications are now implemented above.

## Product and decisions
Offline Flutter iOS/Android prepaid subscription tracker. Tagline: Every use counts.
Both iOS and Android use com.sspatari.tiko (Apple rejected the previous com.tiko.app identifier for the configured team). This installs separately from the older com.tiko.tiko app; its data has not been deleted or automatically migrated. Outside-validity entries require an explicit override. No backend, authentication, telemetry or production mock data.

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

## iPhone signing update
The user configured a development team in Xcode. Preserved that configuration and changed all iOS app/test bundle IDs plus URL type name to the personal namespace com.sspatari.tiko. The release build signed successfully. Flutter reported a generic install/launch failure, but Apple devicectl then successfully installed and launched com.sspatari.tiko on the connected physical iPhone. Full interaction, sharing and accessibility testing on that phone remains outstanding.

## Android identity update
Aligned Android applicationId, namespace and MainActivity package/path with com.sspatari.tiko. The user has no existing Android installation to migrate. The Android debug APK builds successfully with the updated identifier.

## Simulator identity verification
Rebuilt and launched com.sspatari.tiko on the iPhone 17 simulator. Confirmed the built bundle ID and successful native process launch. Restarted the simulator after it shut down during verification; a fresh screenshot confirms the branded Home screen and all four navigation tabs render correctly. This verifies startup/rendering, not a new complete interaction test pass.

## Resume checklist
1. Read AGENTS.md, README.md and this file; inspect Git status. The core implementation was committed/pushed as 0438c60 on master to github.com/sspatari/tiko. Application identifiers, the Android package and iOS signing configuration are now aligned in the subsequent identity update. Inspect Git status for later pending work and preserve the user's Xcode signing team.
2. Test the installed app on the physical iPhone: create subscription, +1, exact-event Undo, manual entry/edit/delete, validity override, archive/restore and renewal. Use the release app com.sspatari.tiko. Installation/launch is verified, full interaction testing is not.
3. Test native JSON export/import, repeated imports, file picker and share sheets. Check Romanian, dark mode, large text, VoiceOver/TalkBack and offline restart/persistence. Fix reproduced issues and run relevant checks.
4. Profile large histories/analytics and address the documented future Android plugin KGP compatibility warning before upgrading Flutter.
5. Prepare release signing and TestFlight/store packaging when the user requests distribution. Do not upload/publish automatically based on this checklist alone.
6. Interactive iOS Home Screen widget is optional follow-up; use docs/IOS_WIDGET.md. Opening a deep link must never log an event.

No new feature change or release is currently awaiting automatic execution. The user asked that the handoff be saved for future sessions. Start by reporting the current state and the next relevant checklist item when asked to resume.
