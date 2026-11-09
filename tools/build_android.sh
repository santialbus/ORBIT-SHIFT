#!/usr/bin/env bash
# Builds the ORBIT SHIFT beta APK. Requirements: see docs/INSTALL_AND_BUILD.md
# Usage: ANDROID_SDK=/path/to/sdk GODOT=/path/to/godot ./tools/build_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
: "${ANDROID_SDK:?set ANDROID_SDK to your Android SDK folder}"
mkdir -p export
KEYSTORE="export/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
  keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore "$KEYSTORE" \
    -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
fi
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-debug "Android (Beta APK)" export/ORBIT_SHIFT_beta.apk
ls -la export/ORBIT_SHIFT_beta.apk
