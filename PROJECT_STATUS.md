# Tiko project status

## Continuation backlog

Saved at the user's request; this is a handoff, not authorization to start more
phone testing. Inspect current files/Git status when resuming. Latest completed
code verification was formatting, static analysis and 58 passing unit/widget
tests; those checks have not been rerun for this documentation-only update.

### Fix device-test isolation first
- [ ] Give integration builds a distinct iOS bundle ID and Android application ID;
  verify the installed identity before deployment and that cleanup cannot remove
  the production app or its database. Keep fixtures in a separate database.
- [ ] Repair the profile-mode input/keyboard harness and make failures produce
  actionable diagnostics. First validate on disposable simulators/emulators.
- [x] Correct the unsafe README procedure and earlier data-preservation claims.
- [ ] If the user requests recovery help, check for a pre-test Tiko JSON export or
  iPhone backup. None has been verified and no recovery has been performed.

### Feature ideas not implemented
- [ ] **Clearer break-even milestones:** improve the existing progress copy,
  especially a positive message once prepaid cost has been recovered. Keep the
  current financial calculations; hide reference-dependent copy without a single-
  use price. Localize English/Romanian, including singular/plural cases.
- [ ] **Backup confidence:** show the last successful backup date and offer an
  optional backup reminder. Define what counts as a completed export with native
  file/share APIs; do not claim an external file was saved without confirmation.
  Decide reminder timing when implementing. Existing JSON export/import is done.
- [ ] **Home Screen widgets:** show usage and average cost without opening Tiko.
  Start with the existing iOS feasibility notes in docs/IOS_WIDGET.md; iOS needs
  a real WidgetKit/AppIntent extension and shared-storage design. Android widgets
  are also unimplemented. Decide platform order and whether +1 is included before
  implementation; opening a subscription must never itself record a use.

### Implemented features with incomplete verification
- [ ] **Expiry notifications:** actual delivery with the app closed, permission
  denial/re-enable, reboot recovery, time-zone changes, tapping from a terminated
  app, and cancellation/rescheduling after editing, renewing, archiving or deleting.
  Notification code and automated scheduling tests are already implemented.
- [ ] **Forms/keyboard on a physical phone:** complete text entry, scrolling and
  Save checks with the keyboard open, large text, both themes and Romanian. The
  previous physical integration attempt did not complete this check successfully.
- [ ] **Accessibility:** full VoiceOver/TalkBack review, reading order, action
  labels, focus, large text and reduced motion. Automated coverage is not a
  substitute for screen-reader validation.
- [ ] Existing platform follow-ups: native import/export/share sheets, large-history
  analytics profiling, future Android plugin KGP compatibility and store packaging.
  Do not upload or publish without a separate user request.

Home pinning/reordering/compact mode, badges, subtle animations, typography and
form grouping are implemented; do not list them as new unfinished features.

## Device-data incident — 2026-11-06

The assistant ran the integration harness against `com.sspatari.tiko`, the same
identity as the user's installed release. Although the fixtures used an in-memory
database, the installed Flutter SDK's drive-service cleanup stops and uninstalls
the package after tests by default, even on test failure. Those runs likely
removed the user's original on-device database. Earlier assurances that the data
would remain untouched were wrong. Restoring/relaunching the normal release did
not establish data preservation and does not recover deleted records.

The normal release was subsequently installed/launched and further phone testing
was stopped at the user's request. No usable pre-test backup or recovery has been
verified. Do not repeat the production-identity test workflow. The current harness
is unsafe for a phone with real Tiko data until isolation is implemented above.

## Home customization and phone polish
- Added Customize Home in the Home toolbar: pin subscriptions, reorder within
  pinned/unpinned groups using drag handles or accessible Move up/Move down menus,
  and choose compact cards. Save applies the draft; Back discards it; Reset only
  affects Home layout. Archived subscriptions remain collapsed and retain their
  pin/order preferences for restoration.
- Layout persists in the existing app_settings table and JSON backups, with no
  schema migration. Old backups default to full cards/default order. Unknown IDs
  are ignored and pruned on layout save. Explicit order overrides validity order;
  new unarranged subscriptions follow arranged subscriptions.
- Compact cards preserve status/dates, counts, average cost when available and
  the same full-size +1 control. They omit secondary metrics/links and redundant
  empty-usage text. Home scrolls to the top after a saved layout change. Compact
  mode/large text use an icon-only Create FAB with a localized tooltip. Subscription
  icons adapt to light/dark contrast without modifying stored colors.
- Added an integration_test harness with in-memory synthetic records and
  temporary screenshots. It did not directly open production data or request
  notification permission, but its production app identity and automatic uninstall
  made the deployment unsafe. See the incident above; the old README procedure
  has been removed. Signed iPhone release build passes.
- Formatting, flutter analyze and all 58 unit/widget tests pass, including saved
  layouts across DB reopening, backup compatibility, ordering/pin boundaries,
  accessible reordering, compact +1/Undo, reset and draft cancellation. Whitespace
  checks pass. Physical iPhone runs verified usage/Undo, saved pin/order/compact
  layout, light/dark rendering, Romanian and 2x text using isolated data. Screenshots
  were reviewed and informed the contrast, compact-copy and Create-button fixes.
  Full form/keyboard verification remains incomplete: debug launching was unreliable
  and the profile harness hit text-input/keyboard simulation limitations. Further
  testing stopped at the user's request. Normal signed release build succeeded;
  the latest normal app was installed and launched after the temporary test installation. Native
  notification delivery and full VoiceOver/TalkBack checks remain unverified.

## Completed premium UI refinements
- Home and subscription details show icon/text badges for Active, Expires soon,
  Upcoming, Expired and Archived. The expiry warning includes the final three
  calendar days and expiry day; exact dates remain visible. Pure domain logic
  handles calendar boundaries, and a disposable Riverpod midnight timer plus
  resume invalidation refreshes dates without requiring a new usage event.
- Usage totals fade briefly when persisted totals change, with screen-reader
  live announcements; break-even progress animates smoothly. Both respect the
  system reduced-motion setting. Numeric totals/financial values use tabular
  figures, and average cost appears before date metadata on details.
- Subscription forms now group details, pricing, validity and appearance, with
  consistent spacing, clearer date affordances, reference-price help, focused
  field borders and multiline errors. Usage forms group date/time and usage
  details. Save actions remain outside scrolling content, and saving dismisses
  the keyboard. New copy is localized in English and Romanian.
- Verification: dart format lib test, flutter analyze, all 53 tests and git diff
  --check pass. New tests cover expiry boundaries/precedence, month/leap/DST
  boundaries and ordinary/reduced-motion feedback. Existing large-text,
  persistence, form editing and Undo tests pass. No simulator/phone visual
  validation or new native builds were performed for these Dart-only changes.
- Next useful step: review badges and form scrolling on a phone in both themes,
  Romanian, large text, reduced motion and with the keyboard open. The previously
  documented real-notification delivery checks remain outstanding.

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

## Earlier verification (before the UI and Home changes)
All 36 tests passed at that stage. Static analysis, formatting and whitespace checks pass. Backup/history tests also pass in Europe/Bucharest across the spring DST boundary. Android debug APK compilation succeeded, and the rebranded app built/launched on the iPhone 17 simulator. Simulator screenshots and URL opening verified that routing reaches a missing-subscription screen; the recovery button is covered by widget tests. The final incremental Android APK build and iPhone 17 simulator build/launch both succeeded. Do not infer manual file-picker/share-sheet or physical-device validation from these results.

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
