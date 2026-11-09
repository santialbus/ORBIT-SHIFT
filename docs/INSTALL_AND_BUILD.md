# Install & build

## Requirements
* Godot **4.3-stable** (standard) + **export templates 4.3-stable** (Editor → Manage Export Templates).
* Android: JDK 17, Android SDK (platform-tools, build-tools 34.0.0, platform android-34, cmdline-tools 11076708), set in
  Editor → Editor Settings → Export → Android (SDK path, JDK path).
* iOS: macOS + Xcode 15+, Apple Developer account.

## Run from the editor
Open `project.godot`, wait for the first import, F5. For a phone-like window use the project's 450×800 override.

## Android debug APK (one command)
```
ANDROID_SDK=$HOME/Android/Sdk GODOT=/path/to/Godot_v4.3-stable ./tools/build_android.sh
```
The script creates a debug keystore (keytool), imports, and exports `export/ORBIT_SHIFT_beta.apk` using the preset "Android (Beta APK)".
Install: `adb install -r export/ORBIT_SHIFT_beta.apk`.
Manual alternative: Project → Export → "Android (Beta APK)" → Export Project (untick "Export With Debug" for release).

## Release
Preset "Android (Release AAB)" uses the Gradle build (Project → Install Android Build Template first) and your own release keystore
(fill `keystore/release*` in the preset or via environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD`). Never commit keystores.

## Headless checks
```
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/integration_run.gd
godot --headless --path . --export-pack "Android (Beta APK)" /tmp/orbit_shift.pck   # packaging sanity (no SDK needed)
```
