# Testing results (run on 2026-11-09, Godot 4.3-stable, Linux)

## What was run
| Suite | Command | Result |
|---|---|---|
| Unit + simulation | `godot --headless --path . -s tests/run_tests.gd` | **67 tests, 46,149 assertions, 0 failed** |
| Scene integration | `godot --headless --path . -s tests/integration_run.gd` | **35 checks passed, 0 failed** |
| Real-GPU smoke (Mesa llvmpipe, xvfb) | `tools/flow_test.gd`, `tools/screenshot.gd` | splash→menu→gameplay→death→results→play again→collection→menu all load; screens rendered and inspected (`docs/screenshots/`) |
| Packaging | `--export-pack "Android (Beta APK)"` + boot of the .pck | packs all resources; packed game boots without script errors |
Raw logs: `docs/test_output_unit.txt`, `docs/test_output_integration.txt`.

## Coverage
* **Orbital movement / lanes / limits:** split + ping-pong sequences, hard limits, smooth monotonic transitions, mid-transition retargeting, angular speed.
* **Collisions:** same/other lane, before/after, tolerance boundary, moving/orbital/zone obstacles, dodge counting (never twice), perfect-shift detection.
* **Generation:** every row has a free lane; reachability of every transition (both control factors); clear gaps; obstacles stay inside their zones;
  determinism per seed; all 4 kinds appear; crystals on safe lanes.
* **Fairness in continuous time:** a bot with 0.15 s reaction survives 12 seeds × 180 s (split) and 8 seeds × 150 s (one-tap); an idle player dies before 45 s
  (the game is not trivially safe).
* **Difficulty:** phase boundaries 0/15/30/45/60, monotonic speed/clear time, bounds, one lane change always possible, config fallback.
* **Score/combo:** thresholds, signals, break, timeout, level progress bar, multiplier scaling.
* **Progression:** catalog (20 skins, 5 cores, required names), purchase/equip rules, run application, records, stats, missions (deterministic per date, refresh,
  claim, no double claim, progressive tiers), achievements (spec list, once-only, rewards).
* **Save:** defaults, roundtrip, garbage input, tamper detection, sanitising/clamping, migration v0→v1, real disk write/reload, backup recovery after corruption.
* **Scene integration:** boot, pause/resume/countdown, 135 s god-mode run (pooling bounded: max 4 obstacle views, EXTREME phase reached), death → results hand-off →
  stats persisted and valid on disk, tutorial completes all 5 steps and saves the flag, one-tap mode.

## Errors found and fixed during testing
1. Infinite recursion in the Missions screen (`MissionManager.refresh` emitted a signal that triggered a rebuild) — fixed.
2. HUD anchored to the wrong rectangle under a `CanvasLayer` — fixed (`set_anchors_and_offsets_preset`).
3. Orbit lines invisible (back-face culled) — new `line.gdshader`.
4. Volume rounding made the default save differ from its sanitised copy — fixed with exact 2-decimal rounding.
5. Collection 3D preview hidden behind the list — camera offset corrected.
6. `Array.shuffle_with` does not exist — replaced with a seeded Fisher-Yates (also needed for determinism).

## NOT tested (be aware)
* No physical Android/iOS device: real FPS, memory, thermals, touch latency, notch/safe-area values, vibration, lock-screen/app-switch behaviour are **unverified**.
  (Auto-pause on app pause/focus loss is implemented but only logic-tested.)
* No APK was generated or installed. Audio was not listened to on hardware (generated and loaded, plays through the dummy driver in CI).
* Performance on real GPUs unmeasured; software-GL screenshots only prove it renders correctly.
## Manual test checklist for the beta
Fresh install → tutorial → 3 runs → record animation → buy a skin → equip → kill app mid-run → relaunch (progress kept) → lock screen during run (auto-pause) →
rotate/split-screen sanity → change date forward (new daily missions) → reset data.
