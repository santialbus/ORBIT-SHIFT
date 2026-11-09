# Export configuration (export_presets.cfg)
* **Android (Beta APK)** — arm64-v8a only, package `com.orbitshift.game`, version 0.9.0-beta / code 1, signed with the debug keystore, immersive mode,
  `VIBRATE` permission only (no INTERNET: the beta has no network code), adaptive icon layers from `assets/icons/`.
* **Android (Release AAB)** — Gradle build, arm64 + armv7, same identity; needs your release keystore.
* **iOS (prepared)** — bundle id `com.orbitshift.game`, min iOS 12, 1024 px icon; fill team id / provisioning profile on macOS. Not built or tested.
* Excluded from exports: `tests/*, tools/*, docs/*, export/*, *.md`.
* Project settings: portrait orientation, 1080×1920 canvas, `canvas_items` stretch with `expand`, GL Compatibility (widest Android coverage), MSAA off.
* Safe areas: `UIManager.safe_margins()` converts `DisplayServer.get_display_safe_area()` to canvas units; every screen/HUD uses it.
* Lifecycle: gameplay auto-pauses on `NOTIFICATION_APPLICATION_PAUSED / FOCUS_OUT / WM_WINDOW_FOCUS_OUT`; resume uses a 3-2-1 countdown;
  SaveManager saves on pause and quit; Android back = pause/resume in game, back in menus (quit from the main menu).
