# Tiko development

Read README.md and PROJECT_STATUS.md before starting work. Inspect the current files and Git status rather than assuming the status document is current.

Tiko is an offline Flutter prepaid subscription usage tracker. Every use counts.
Use Riverpod, GoRouter, and Drift/SQLite. Store money in integer currency minor units and event timestamps in UTC. Derive usage totals from events; Undo deletes the exact event UUID. Keep business logic out of widgets and preserve existing database records through migrations.

Validate with dart format lib test, flutter analyze, and flutter test. Report blocked checks honestly. Never add secrets, build artifacts, or local SDK configuration to Git.

Maintain PROJECT_STATUS.md after meaningful changes, including completed work, outstanding work, verification results, and the next useful step. Do not claim simulator or physical-device validation without running it.
