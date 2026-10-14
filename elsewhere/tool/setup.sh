#!/usr/bin/env bash
# One-time setup: generates the Android platform scaffolding around the
# hand-written lib/, test/ and pubspec.yaml in this repository.
#
# Requires Flutter (see README for versions) on your PATH.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on your PATH. Install it first: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

flutter create . \
  --org com.example \
  --project-name elsewhere \
  --platforms=android \
  --description "Elsewhere is a collaborative travel companion for planning trips with friends."

# The default template adds a counter-app test that references a MyApp class
# this project does not have. Remove it if it was generated.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

# Launcher name shown on the device.
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i.bak 's|android:label="[^"]*"|android:label="Elsewhere"|' "$MANIFEST" && rm -f "$MANIFEST.bak"
fi

# FlutterFire needs Android minSdk 23 or higher.
for f in android/app/build.gradle.kts android/app/build.gradle; do
  if [ -f "$f" ]; then
    sed -i.bak \
      -e 's|minSdk = flutter.minSdkVersion|minSdk = 23|' \
      -e 's|minSdkVersion flutter.minSdkVersion|minSdkVersion 23|' "$f" && rm -f "$f.bak"
  fi
done

flutter pub get

cat <<'EOF'

Platform scaffolding is ready.
Next steps:
  1. dart pub global activate flutterfire_cli
  2. flutterfire configure --platforms=android   (overwrites lib/firebase_options.dart)
  3. firebase deploy --only firestore:rules      (publishes firestore.rules)
  4. flutter run
See README.md for the full walkthrough.
EOF
