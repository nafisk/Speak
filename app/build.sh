#!/bin/sh
set -eu
speak_app_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
swift build --package-path "$speak_app_dir" -c release -j 4
speak_bundle="$speak_app_dir/build/Speak.app"
mkdir -p "$speak_bundle/Contents/MacOS" "$speak_bundle/Contents/Resources"
cp "$speak_app_dir/.build/release/Speak" "$speak_bundle/Contents/MacOS/Speak"
cp "$speak_app_dir/Info.plist" "$speak_bundle/Contents/Info.plist"
for speak_resource in "$speak_app_dir"/.build/release/*.bundle; do
  [ ! -d "$speak_resource" ] || cp -Rf "$speak_resource" "$speak_bundle/Contents/Resources/"
done
codesign --force --sign - "$speak_bundle"
printf '%s\n' "$speak_bundle"
