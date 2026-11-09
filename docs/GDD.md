# ORBIT SHIFT — Game Design Document (final)

## Pillars
1. Understand in 10 seconds: one finger, three orbits. 2. Fair: death is always the player's fault. 3. Readable: nothing hides the obstacles.
4. Skill is rewarded (combo + perfect shifts). 5. Instant retry.

## Core loop
Start (instant) → play → collect crystals → difficulty rises → collision → results → rewards → PLAY AGAIN (largest button).

## World & physics
* Core at the origin; orbits (lanes) at radii 2.0 / 3.1 / 4.2 units. The sphere advances at angular speed ω (rad/s), set by difficulty.
* The player angle is unwrapped (monotonically increasing); obstacles live at absolute angles ahead of it.
* Lane change: smoothstep over 0.16 s per lane, continuous lane position (no teleport). Hit test uses the continuous position, so passing through an
  intermediate lane while switching is real (and fair).
* Hitbox: angular half-size 0.05 rad, lane tolerance 0.42 (forgiving).

## Controls (documented behaviour)
Split Tap (left/right half = inward/outward) or One Tap (ping-pong). Hard limits at lanes 0 and 2; retargeting mid-transition allowed; no input is dropped.

## Obstacles
| Kind | Behaviour | Identity |
|---|---|---|
| Static barrier | fixed arc | solid coral block |
| Moving barrier | oscillates along its orbit | coral with animated stripes |
| Orbital block | small block counter-orbiting toward the player | bright tall block |
| Danger zone | wide strip, harmless while dim, deadly when bright | pulsing hazard strip (telegraphed) |
Rows can mix kinds ("combined") and chain into patterns: slalom, stairs, tunnel, gate, rails.

## Fairness guarantee (generator)
Each row owns a zone that contains all its obstacles. Between zones there is `clear_time` seconds. For every lane the player may legally be in after the
previous row, some free lane of the next row must be reachable within `steps × 0.16 s × controlFactor + 0.22 s` (reaction margin). Otherwise the row is
replaced by a safe one. Proven by automated tests, including a bot simulation in continuous time.

## Difficulty (resources/difficulty.json, all configurable)
| Time | Phase | ω (rad/s) | clear time | content |
|---|---|---|---|---|
| 0–15 s | INTRO | 1.30→1.55 | 1.60→1.30 s | single static barriers |
| 15–30 s | WARM-UP | →1.80 | →1.05 s | + moving barriers |
| 30–45 s | ADVANCED | →2.10 | →0.88 s | + orbital blocks, zones, double walls, patterns |
| 45–60 s | HARD | →2.40 | →0.74 s | more doubles, mixed rows, patterns 28→40% |
| 60 s+ | EXTREME | grows to 3.0 | shrinks to 0.62 s | everything, capped |

## Scoring & combo
Survival 8 pts/s, crystal 50, perfect shift 100, dodged obstacle 10 — all × multiplier. Chain: crystal +1, perfect shift +2.
Multiplier thresholds 0/4/9/15/22/30/40/52 → x1…x8. The chain breaks on: 7 s without gain, or two consecutive crystal groups missed, or death.
"Perfect shift" = leaving an obstacle's lane in the last 0.45 s, or skimming it laterally while switching.

## Economy
Crystals are the only currency (earned by playing: collected + score/250 bonus; missions and achievements pay too). Only cosmetics are sold; no pay-to-win exists.
20 spheres (0–600 crystals), 5 cores (0–1200; scenery only).

## Retention
Daily missions (3, seeded by local date, no penalty for missing days), 4 endless progressive objectives, 14 achievements (table-driven), personal best, collection.
