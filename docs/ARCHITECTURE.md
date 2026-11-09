# Architecture

Godot 4.3, GDScript, GL Compatibility renderer. Logic, presentation and data are separated: **pure logic classes** (RefCounted, no nodes, unit-testable)
↔ **node views** (3D/UI) ↔ **data** (JSON/catalog/save).

## Autoloads
| Autoload | Role |
|---|---|
| SaveManager | atomic JSON save (temp→rename), rolling backup, checksum, autosave, saves on pause/quit |
| GameStateManager | tiny FSM (BOOT/MENU/PLAYING/PAUSED/DYING/RESULTS/TUTORIAL) with signal |
| GameManager | cross-scene session (last run/summary), play/tutorial flow, vibration, dev flags |
| AudioManager | Music/SFX buses created at runtime, SFX pool (8), looping music, ducking, settings |
| SkinManager | catalog → shader materials and core palettes |
| ProgressionManager | currency, record, stats, purchase/equip, `finish_run()` pipeline |
| MissionManager / AchievementManager | daily refresh + claim helpers / read access |
| UIManager | scene navigation with fade, safe-area insets, Android back |

## Gameplay (scenes/gameplay/gameplay.gd orchestrates)
`OrbitController` (lanes, input modes) · `DifficultyManager` (curve from JSON) · `PatternGenerator` (fair rows) · `ObstacleSpawner` ·
`ObstacleManager` / `CrystalManager` (pooling) · `CollisionManager` (static, pure) · `ScoreManager` · `ComboManager` ·
presentation: `WorldBuilder`, `PlayerView`, `ObstacleView`, `CrystalView`, `FxManager`, `Hud`.
The scene is driven by `tick(delta)`, which tests call directly to simulate minutes of play in milliseconds.

## Data flow of a run
input → `tap_side` → OrbitController → tick: difficulty → orbit.update → spawner → collision/proximity/pass → crystals → combo/score → views/HUD.
On death: `_die` (FX, shake) → 0.9 s → `ProgressionManager.finish_run` (record, stats, missions, achievements, save) → Results.

## Rendering
Procedural meshes (`MeshFactory`, baked to `assets/models/*.tres` by `tools/bake_assets.gd`), custom spatial shaders (`shaders/`): skin (8 styles),
neon, zone, core, glow sprite, line, floor. Bloom via Environment glow (disabled in LOW graphics). No dynamic shadows. CPUParticles3D with pooled emitters.

## Save format
`{v, checksum, data}`; `SaveData.sanitize()` validates every field (types, ranges, known ids), `migrate()` upgrades old versions, mismatching checksum → backup,
corrupt main file → backup → defaults. Save version: 1.

## Extending
New skin: add an entry to `SkinCatalog.SKINS`. New achievement: add to `AchievementLogic.LIST`. New mission type: `MissionLogic.TYPES` + `apply_run`.
New obstacle kind: `ObstacleData.Kind`, `PatternGenerator._make_obstacle`, `ObstacleView.bind`. Tuning: `resources/difficulty.json`.
Monetization hooks: see docs/ROADMAP.md (nothing is simulated; the beta has no ad/IAP code).
