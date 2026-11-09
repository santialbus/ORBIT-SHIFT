# Known limitations (beta)
* **No APK shipped in this package:** the Android SDK could not be downloaded in the build environment. Use `tools/build_android.sh` (docs/INSTALL_AND_BUILD.md).
* **iOS:** preset only; never built.
* **No device testing:** 60 FPS target and mid-range stability are design goals backed by lightweight rendering (GL Compatibility, no shadows, pooled objects,
  ≤ ~6 active obstacles, ~150 star instances), not measured numbers. A LOW graphics option exists (no bloom, half particles).
* **Art is procedural:** faceted low-poly meshes + shaders instead of hand-modelled assets; audio is synthesized, not composed.
* **UI text is English only** and defined in code (no localisation yet). Orbitron's zero is slashed (font design), which can look like a missing glyph.
* **Save integrity** uses a checksum with a static salt: it detects corruption/casual edits, it is not anti-cheat.
* **No monetization, analytics, cloud save or leaderboards** in the beta (architecture notes in ROADMAP).
* `Hud` popups/banners are simple tweens; no accessibility options (colour-blind mode, reduce motion) yet.
* The first-run tutorial is skipped if disabled in Settings; "Replay tutorial" always works.
* Headless runs print harmless `mesh_get_surface_count` errors from Godot's dummy renderer; they do not occur with a real renderer.
