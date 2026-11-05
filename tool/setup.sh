#!/bin/sh
# Run in macOS Terminal; exits immediately if any validation fails.
set -eu
cd "$(dirname "$0")/.."
flutter pub get
dart run build_runner build
dart format lib test
flutter analyze
flutter test
