# iOS widget evaluation

Core app ships subscription deep links: `tiko:///subscriptions/<UUID>`.
Opening a link navigates to subscription details; it never records usage.
The URL scheme is registered on iOS and Android. A missing/deleted subscription
shows a useful not-found screen. A Home Screen widget extension is not shipped.

A genuine interactive widget is feasible with a SwiftUI WidgetKit extension and
an AppIntent button. Apple describes executing the intent's perform method when
the user taps a widget button:
https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities

Production integration needs a registered App Group enabled for the app and
extension and a shared persistence strategy:
https://developer.apple.com/documentation/xcode/configuring-app-groups

The current Drift database lives in the application's private container. Do not
create a separate mutable count in widget preferences. A future implementation
must migrate the SQLite file (including WAL/SHM handling) to the shared container,
coordinate schema ownership and transactional event writes across processes,
and refresh both WidgetKit timelines and Drift reads when either process writes.
The intent must create a UUID event with UTC timestamps and retain validity,
archive, duplicate-tap and Undo semantics. Widget configuration selects a period
by UUID. Signing and process-concurrency behavior must be tested on a real device.

Until that work is complete, use the registered URL through an iOS Shortcut's
Open URL action. This opens details and requires tapping +1; it is not described
as a one-tap recording widget. No App Group identifier or signing entitlement is
invented by this project.
