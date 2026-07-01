local menu = require("madrilla_recode/menu")

local target_history = {}
local target_lock_time = {}
local current_target = nil
local last_shot_tick = 0

local function get_velocity_2d(player)
    local vel = player.m_vecVelocity
    if not vel then return 0 end
    return math.sqrt(vel.x * vel.x + vel.y * vel.y)
end

local function is_sniper(weapon)
    if not weapon then return false end
    local info = weapon:get_weapon_info()
    if not info then return false end
    return info.weapon_type == 2 or info.weapon_type == 0 and (info.max_clip1 or 0) <= 10
end

local function get_best_target()
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return nil end

    local best_threat = entity.get_threat(true)
    if best_threat and best_threat:is_alive() and not best_threat:is_dormant() then
        return best_threat
    end

    local enemies = entity.get_players(true)
    local best = nil
    local best_score = -math.huge
    local my_pos = lp:get_origin()
    if not my_pos then return nil end

    for _, enemy in ipairs(enemies) do
        if enemy:is_alive() and not enemy:is_dormant() then
            local epos = enemy:get_origin()
            if epos then
                local dx = epos.x - my_pos.x
                local dy = epos.y - my_pos.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local hp = enemy.m_iHealth or 100
                local vis = enemy:is_visible() and 2 or 0
                local score = vis * 10000 - dist + (100 - hp) * 10
                if score > best_score then
                    best_score = score
                    best = enemy
                end
            end
        end
    end

    return best
end

local function should_safepoint(player)
    if not menu.ragebot.autoSafepoint.enable:get() then return false end

    local options = menu.ragebot.autoSafepoint.options:get()
    local opt_set = {}
    for _, v in ipairs(options) do opt_set[v] = true end

    local lp = entity.get_local_player()
    if not lp then return false end

    local is_airborne = bit.band(lp.m_fFlags or 0, 1) == 0
    local animstate = player and player:get_anim_state()
    local jitter_amt = animstate and (animstate.strafe_change_weight or 0) or 0

    if opt_set["in air"] and is_airborne then return true end
    if opt_set["low jitter"] and jitter_amt < 0.3 then return true end
    if opt_set["high jitter"] and jitter_amt > 0.7 then return true end

    local weapon = lp:get_player_weapon()
    if weapon then
        local hp = player.m_iHealth or 100
        if opt_set["lethal"] and hp <= (weapon:get_weapon_info() and weapon:get_weapon_info().damage or 0) then
            return true
        end
    end

    return false
end

local function is_unsafe_hitbox(hb_idx)
    local safe_hitboxes = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
    return not safe_hitboxes[hb_idx]
end

local ragebot_helper = {
    last_target_switch = 0,
    safepoint_next = false,
    miss_count = {},
    target_times = {},
}

ragebot_helper.OnAimFire = function(e)
    last_shot_tick = globals.tickcount
    local target = e.target
    if not target then return end
    local idx = target:get_index()
    if not idx then return end

    if not ragebot_helper.miss_count[idx] then
        ragebot_helper.miss_count[idx] = 0
    end
end

ragebot_helper.OnAimAck = function(e)
    local target = e.target
    if not target then return end
    local idx = target:get_index()
    if not idx then return end

    if not ragebot_helper.miss_count[idx] then ragebot_helper.miss_count[idx] = 0 end

    if e.state == nil then
        if menu.hud.logs.logOnshot and menu.hud.logs.logOnshot:get() then
            local logs = menu.hud.logs.options:get()
            local opt = {}
            for _, v in ipairs(logs) do opt[v] = true end

            local lp = entity.get_local_player()
            local wp = lp and lp:get_player_weapon()
            local dmg = 0
            if wp and wp.get_weapon_info then
                local info = wp:get_weapon_info()
                dmg = info and info.damage or 0
            end

            if opt["console"] then
                print(string.format("[madrilla recode] hit %s | dmg: %d", target:get_name(), dmg))
            end
            if opt["hitlog indicator"] then
                common.add_event(string.format("hit %s", target:get_name()), "crosshairs")
            end
        end

        ragebot_helper.miss_count[idx] = 0

        if ragebot_helper.safepoint_next then
            ragebot_helper.safepoint_next = false
        end
    else
        local reason = e.state or ""
        if reason == "missed" or reason == "prediction error" or reason == "?" then
            ragebot_helper.miss_count[idx] = (ragebot_helper.miss_count[idx] or 0) + 1

            if menu.hud.logs.logOnshot and menu.hud.logs.logOnshot:get() then
                local logs = menu.hud.logs.options:get()
                local opt = {}
                for _, v in ipairs(logs) do opt[v] = true end

                if opt["console"] then
                    print(string.format("[madrilla recode] miss on %s | reason: %s | total: %d",
                        target:get_name(), reason, ragebot_helper.miss_count[idx]))
                end
            end

            if menu.ragebot.autoSafepoint.enable:get() then
                local opts = menu.ragebot.autoSafepoint.options:get()
                for _, v in ipairs(opts) do
                    if v == "on miss" then
                        ragebot_helper.safepoint_next = true
                        break
                    end
                end
            end
        end
    end
end

ragebot_helper.OnSetupCommand = function(cmd)
    if not menu.ragebot.ragebotHelper.enable:get() then return end

    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end

    local target = get_best_target()
    if not target then return end

    local target_idx = target:get_index()
    if not target_idx then return end

    if not ragebot_helper.target_times[target_idx] then
        ragebot_helper.target_times[target_idx] = globals.realtime
    end

    local max_time = menu.ragebot.ragebotHelper.maxTargetTime:get()
    if max_time > 0 and globals.realtime - ragebot_helper.target_times[target_idx] > max_time then
        ragebot_helper.target_times[target_idx] = globals.realtime
    end

    local weapon = lp:get_player_weapon()
    if not weapon then return end

    local sniper = is_sniper(weapon)
    local in_duck = (lp.m_fFlags or 0) and bit.band(lp.m_fFlags or 0, 4) ~= 0
    local duck_amt = lp.m_flDuckAmount or 0

    if menu.ragebot.ragebotHelper.forceHideshotsSniper:get() and sniper and duck_amt > 0.85 then
        rage.override_min_damage(target, menu.ragebot.ragebotHelper.minDamage:get())
        rage.override_hitchance(target, menu.ragebot.ragebotHelper.hitChance:get())
    end

    if menu.ragebot.ragebotHelper.enable:get() then
        rage.override_min_damage(target, menu.ragebot.ragebotHelper.minDamage:get())
        rage.override_hitchance(target, menu.ragebot.ragebotHelper.hitChance:get())
    end

    if should_safepoint(target) or ragebot_helper.safepoint_next then
        rage.override_safepoint(target, true)
    end

    if menu.ragebot.ragebotHelper.avoidUnsafeHitboxes:get() then
        rage.override_safepoint(target, true)
    end

    if menu.ragebot.multiDT.enable:get() then
        local pressed = menu.ragebot.multiDT.key1:get()
            or menu.ragebot.multiDT.key2:get()
            or menu.ragebot.multiDT.key3:get()
        if pressed then
            rage.override_double_tap(true)
        end
    end
end

events.aim_fire:set(function(e)
    ragebot_helper.OnAimFire(e)
end)

events.aim_ack:set(function(e)
    ragebot_helper.OnAimAck(e)
end)

return ragebot_helper
