#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
case "${1:-lib/main.dart}" in
  lib/main.dart|"$project_root/lib/main.dart"|"file://$project_root/lib/main.dart") exit 0 ;;
esac

if [ "${2:-}" != 'com.sspatari.tiko.uitest' ] || [ "${3:-}" != 'tiko-uitest' ]; then
  echo 'Alternate Dart entrypoints require the uitest scheme and isolated app identity. Build refused before deployment.' >&2
  exit 1
fi
