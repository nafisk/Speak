#!/bin/sh
set -eu
speak_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$speak_dir/.build/release/speak-tts" ]; then
  echo 'Build first: cd prototypes && swift build -c release -j 4' >&2
  exit 1
fi
exec "$speak_dir/.build/release/speak-tts" "$@"
