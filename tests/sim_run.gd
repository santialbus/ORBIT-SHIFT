class_name SimRun
extends RefCounted
## Headless, node-free simulation of a whole run with a scripted "bot" player.
## Uses the real logic classes (OrbitController, DifficultyManager, PatternGenerator, CollisionManager,
## ScoreManager, ComboManager) so fairness is validated in continuous time, not just on paper.

## reaction: seconds between the bot deciding and the tap landing. mode: OrbitController.Mode.
static func run(seed_value: int, duration: float, reaction: float = 0.12, mode: int = OrbitController.Mode.SPLIT, dt: float = 1.0 / 60.0) -> Dictionary:
    var diff := DifficultyManager.new()
    var gen := PatternGenerator.new()
    var orbit := OrbitController.new()
    var score := ScoreManager.new()
    var combo := ComboManager.new()
    orbit.mode = mode
    orbit.reset(1, -PI / 2.0)
    orbit.omega = float(diff.params_at(0.0)["omega"])
    var factor := 1.0 if mode == OrbitController.Mode.SPLIT else 1.9
    gen.reset(seed_value, orbit.theta + GameConfig.START_DELAY * orbit.omega, 1, factor)

    var rows: Array = []
    var obstacles: Array = []
    var queue: Array = []        # [exec_time, side]
    var planned_lane := 1
    var planned_dir := 1
    var t := 0.0
    var rows_total := 0
    var max_omega := 0.0
    var result := {"survived": true, "time": 0.0, "rows": 0, "near_misses": 0, "dodged": 0}

    while t < duration:
        t += dt
        var p := diff.params_at(t)
        orbit.omega = float(p["omega"])
        max_omega = maxf(max_omega, orbit.omega)
        orbit.update(dt)

        # spawn rows ahead
        var guard := 0
        while gen.last_end + float(p["clear_time"]) * float(p["omega"]) <= orbit.theta + OrbitMath.LEAD_ANGLE and guard < 6:
            var row := gen.next_row(p, t)
            rows.append(row)
            for o in row["obstacles"]:
                obstacles.append(o)
            rows_total += 1
            guard += 1

        # bot decision: only look at the next row whose zone is not yet behind the player
        var target_row = null
        for r in rows:
            if orbit.theta <= float(r["center"]) + float(r["eff_half"]) + OrbitMath.PLAYER_HALF_ANGLE:
                target_row = r
                break
        if target_row != null:
            var zone_start: float = float(target_row["center"]) - float(target_row["eff_half"]) - OrbitMath.PLAYER_HALF_ANGLE - 0.02
            var inside: bool = orbit.theta >= zone_start
            if not inside:
                var free: Array = target_row["free"]
                var desired: int = int(free[0])
                var best := 99
                for l in free:
                    var d := absi(int(l) - planned_lane)
                    if d < best:
                        best = d
                        desired = int(l)
                if desired != planned_lane:
                    if mode == OrbitController.Mode.SPLIT:
                        var dir_sign := 1 if desired > planned_lane else -1
                        var n := absi(desired - planned_lane)
                        for k in n:
                            queue.append([t + reaction + float(k) * 0.05, dir_sign])
                        planned_lane = desired
                    else:
                        var k := 0
                        while planned_lane != desired and k < 6:
                            var nxt := planned_lane + planned_dir
                            if nxt < 0 or nxt > 2:
                                planned_dir = -planned_dir
                                nxt = planned_lane + planned_dir
                            planned_lane = nxt
                            if planned_lane == 0:
                                planned_dir = 1
                            elif planned_lane == 2:
                                planned_dir = -1
                            queue.append([t + reaction + float(k) * 0.07, 0])
                            k += 1

        # execute due taps
        while not queue.is_empty() and float(queue[0][0]) <= t:
            var tap: Array = queue.pop_front()
            var left := orbit.target_lane
            if orbit.tap(int(tap[1])):
                CollisionManager.mark_shift(orbit.theta, left, orbit.omega, obstacles, t)

        CollisionManager.track_proximity(orbit.theta, orbit.lane_pos, obstacles, t)
        var hit := CollisionManager.check_hit(orbit.theta, orbit.lane_pos, obstacles, t)
        if hit != null:
            result["survived"] = false
            result["time"] = t
            result["hit_kind"] = hit.kind
            result["hit_lane"] = hit.lane
            result["rows"] = rows_total
            return result
        var passed := CollisionManager.collect_passed(orbit.theta, obstacles, t)
        score.add_dodges(int(passed["dodged"]), combo.multiplier)
        for i in int(passed["near_misses"]):
            score.add_near_miss(combo.multiplier)
            combo.on_near_miss()
        combo.update(dt)
        score.add_survival(dt, combo.multiplier)

        # prune
        while not rows.is_empty() and orbit.theta > float((rows[0] as Dictionary)["center"]) + float((rows[0] as Dictionary)["eff_half"]) + 1.0:
            rows.pop_front()
        var i := obstacles.size() - 1
        while i >= 0:
            var od: ObstacleData = obstacles[i]
            if orbit.theta - od.angle_at(t) - od.half > OrbitMath.BEHIND_ANGLE:
                obstacles.remove_at(i)
            i -= 1
        # memory/pooling sanity: nothing should pile up
        if obstacles.size() > 40:
            result["survived"] = false
            result["time"] = t
            result["error"] = "obstacle pile-up: %d" % obstacles.size()
            return result

    result["time"] = t
    result["rows"] = rows_total
    result["near_misses"] = score.near_misses
    result["dodged"] = score.dodged
    result["score"] = score.value()
    result["max_omega"] = max_omega
    return result
