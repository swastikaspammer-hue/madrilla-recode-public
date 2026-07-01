local menu = require("madrilla_recode/menu")
local ffi = require("ffi")

local CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX = 58.0
local CS_PLAYER_SPEED_RUN                 = 260.0
local CS_PLAYER_SPEED_WALK_MODIFIER       = 0.52
local CS_PLAYER_SPEED_DUCK_MODIFIER       = 0.34
local CSGO_ANIM_AIM_NARROW_WALK          = 0.8
local CSGO_ANIM_AIM_NARROW_RUN           = 0.5
local CSGO_ANIM_AIM_NARROW_CROUCHMOVING  = 0.5

local VOTE_WINDOW = 6

local lag_records = {}
local resolver_data = {}

local function angle_diff(dest, src)
    if dest == nil or src == nil then return 0 end
    local delta = (dest - src) % 360
    if delta > 180 then delta = delta - 360 end
    if delta < -180 then delta = delta + 360 end
    return delta
end

local function clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local function calculate_aim_matrix_width_range(speed, duck_amount, walk_to_run_transition)
    local speed_walk   = speed / (CS_PLAYER_SPEED_RUN * CS_PLAYER_SPEED_WALK_MODIFIER)
    local speed_crouch = speed / (CS_PLAYER_SPEED_RUN * CS_PLAYER_SPEED_DUCK_MODIFIER)
    local width = lerp(clamp(speed_walk, 0, 1), 1.0,
        lerp(walk_to_run_transition, CSGO_ANIM_AIM_NARROW_WALK, CSGO_ANIM_AIM_NARROW_RUN))
    if duck_amount > 0 then
        width = lerp(duck_amount * clamp(speed_crouch, 0, 1), width, CSGO_ANIM_AIM_NARROW_CROUCHMOVING)
    end
    return width
end

local function calculate_max_desync(animstate)
    if not animstate then return CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX end
    return CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX * calculate_aim_matrix_width_range(
        animstate.velocity_length_xy or 0,
        animstate.anim_duck_amount or 0,
        animstate.walk_run_transition or 0
    )
end

local function init_resolver_data(i)
    resolver_data[i] = {
        resolved_side    = 0,
        resolved_desync  = 0,
        last_side        = 0,
        committed_side   = 0,
        misses           = 0,
        brute_phase      = 0,
        last_logged_side = 0,
        side_votes       = {},
        lby_confirmed    = false,
        lby_trigger      = "none",
        max_desync       = 0,
    }
end

local function commit_side(data, raw_side, weight)
    weight = weight or 1
    local votes = data.side_votes
    for _ = 1, weight do table.insert(votes, raw_side) end
    while #votes > VOTE_WINDOW + 4 do table.remove(votes, 1) end

    local pos, neg = 0, 0
    local start = math.max(1, #votes - VOTE_WINDOW + 1)
    for i = start, #votes do
        if votes[i] > 0 then pos = pos + 1 else neg = neg + 1 end
    end

    local total = pos + neg
    if total == 0 then return data.committed_side end

    if pos / total > 0.6 then
        data.committed_side = 1
    elseif neg / total > 0.6 then
        data.committed_side = -1
    end
    if data.committed_side == 0 then data.committed_side = raw_side end
    return data.committed_side
end

local function create_lag_record(player)
    local animstate = player:get_anim_state()
    local vel = player.m_vecVelocity
    local vx = vel and vel.x or 0
    local vy = vel and vel.y or 0

    local current_feet_yaw = animstate and (animstate.abs_yaw or 0) or 0
    local goal_feet_yaw    = animstate and (animstate.move_yaw_ideal or 0) or 0
    local eye_yaw_ang      = player.m_angEyeAngles
    local eye_yaw          = eye_yaw_ang and eye_yaw_ang.y or 0

    local prev_records = lag_records[player:get_index()]
    local prev_record  = prev_records and prev_records[#prev_records]
    local lby_delta = 0
    if prev_record then
        lby_delta = math.abs(angle_diff(current_feet_yaw, prev_record.current_feet_yaw))
    end

    local layer3 = player:get_anim_overlay(3)
    local layer6 = player:get_anim_overlay(6)
    local layer12 = player:get_anim_overlay(12)

    return {
        tick             = globals.tickcount,
        sim_time         = player:get_simulation_time().current,
        eye_yaw          = eye_yaw,
        goal_feet_yaw    = goal_feet_yaw,
        current_feet_yaw = current_feet_yaw,
        origin           = player:get_origin(),
        velocity         = { x = vx, y = vy },
        flags            = player.m_fFlags or 0,
        speed            = math.sqrt(vx^2 + vy^2),
        strafe_changing  = animstate and animstate.strafe_changing or false,
        strafe_weight    = animstate and animstate.strafe_change_weight or 0,
        lby_delta        = lby_delta,
        layer3_weight    = layer3 and layer3.weight or 0,
        layer3_cycle     = layer3 and layer3.cycle or 0,
        layer3_weight_delta_rate = layer3 and layer3.weight_delta_rate or 0,
        layer6_playback  = layer6 and layer6.playback_rate or 0,
        layer12_weight   = layer12 and layer12.weight or 0,
    }
end

local function detect_strafe_side(records)
    if #records < 4 then return 0 end
    local left_count  = 0
    local right_count = 0
    local start = math.max(1, #records - 5)
    for i = start, #records do
        local r = records[i]
        local prev = records[i - 1]
        if prev then
            local dvx = (r.velocity.x or 0) - (prev.velocity.x or 0)
            if dvx > 2 then right_count = right_count + 1
            elseif dvx < -2 then left_count = left_count + 1 end
        end
    end
    if right_count > left_count + 1 then return 1 end
    if left_count > right_count + 1 then return -1 end
    return 0
end

local function do_freestanding_trace(player)
    local local_player = entity.get_local_player()
    if not local_player or not local_player:is_alive() then return 0 end

    local eye_pos   = local_player:get_eye_position()
    local enemy_pos = player:get_hitbox_position(0)
    if not eye_pos or not enemy_pos then return 0 end

    local dx  = enemy_pos.x - eye_pos.x
    local dy  = enemy_pos.y - eye_pos.y
    local yaw = math.deg(math.atan2(dy, dx))

    local offset = menu.ragebot.resolver.freestandingWidth:get()
    local right_yaw = math.rad(yaw - 90)
    local left_yaw  = math.rad(yaw + 90)

    local left_from  = vector(enemy_pos.x + math.cos(left_yaw) * offset, enemy_pos.y + math.sin(left_yaw) * offset, enemy_pos.z)
    local right_from = vector(enemy_pos.x + math.cos(right_yaw) * offset, enemy_pos.y + math.sin(right_yaw) * offset, enemy_pos.z)

    local tr_left  = utils.trace_line(left_from, eye_pos, local_player)
    local tr_right = utils.trace_line(right_from, eye_pos, local_player)

    if tr_left.fraction < tr_right.fraction then return 1
    elseif tr_right.fraction < tr_left.fraction then return -1
    end
    return 0
end

local function resolve_player(player)
    local idx = player:get_index()
    if not idx or idx < 1 then return end

    local records = lag_records[idx]
    if not records or #records < 2 then return end

    local data      = resolver_data[idx]
    local animstate = player:get_anim_state()
    if not animstate then return end

    local max_desync = calculate_max_desync(animstate)

    local eye_yaw_ang = player.m_angEyeAngles
    local eye_yaw = eye_yaw_ang and eye_yaw_ang.y or 0

    local goal_feet_yaw    = animstate.move_yaw_ideal or 0
    local current_feet_yaw = animstate.abs_yaw or 0

    local desync_goal    = angle_diff(eye_yaw, goal_feet_yaw)
    local desync_current = angle_diff(eye_yaw, current_feet_yaw)
    local goal_current_delta = angle_diff(goal_feet_yaw, current_feet_yaw)

    local side = 0
    local actual_desync = 0

    local is_jittering = false
    if #records >= 3 then
        local r1 = records[#records]
        local r2 = records[#records - 1]
        local r3 = records[#records - 2]
        if r1 and r2 and r3 then
            local ds1 = angle_diff(r1.eye_yaw, r1.goal_feet_yaw)
            local ds2 = angle_diff(r2.eye_yaw, r2.goal_feet_yaw)
            local ds3 = angle_diff(r3.eye_yaw, r3.goal_feet_yaw)
            if (ds1 > 5 and ds2 < -5 and ds3 > 5) or (ds1 < -5 and ds2 > 5 and ds3 < -5) then
                is_jittering = true
            end
        end
    end

    if is_jittering then
        side = data.last_side ~= 0 and data.last_side or 1
        actual_desync = 0
        data.last_side = side
    elseif math.abs(goal_current_delta) > 8.0 then
        side = (desync_current > 0) and 1 or -1
        actual_desync = clamp(math.abs(desync_current), 0, max_desync)
        data.last_side = side
    elseif math.abs(desync_goal) > 5.0 then
        side = (desync_goal > 0) and 1 or -1
        actual_desync = clamp(math.abs(desync_goal), 0, max_desync)
        data.last_side = side
    else
        local fs_side = 0
        if menu.ragebot.resolver.freestanding:get() then
            fs_side = do_freestanding_trace(player)
        end
        local strafe_side = detect_strafe_side(records)
        if fs_side ~= 0 then side = fs_side
        elseif strafe_side ~= 0 then side = strafe_side
        elseif data.last_side ~= 0 then side = data.last_side
        else side = -1 end
        actual_desync = max_desync * 0.5
    end

    if data.misses > 0 then
        local phase = data.brute_phase
        if phase == 1 then
            side = -side
            actual_desync = max_desync
        elseif phase == 2 then
            actual_desync = max_desync * 0.5
        elseif phase == 3 then
            actual_desync = 0
        else
            data.brute_phase = 0
        end
    end

    local latest_record = records[#records]
    local prev_record   = records[#records - 1]
    local is_lby_update = false
    local lby_trigger   = "anim"

    local layer3 = player:get_anim_overlay(3)
    if layer3 and prev_record then
        if layer3.cycle < prev_record.layer3_cycle and layer3.weight_delta_rate > 0.0 then
            is_lby_update = true
            lby_trigger = "layer_cycle_reset"
        elseif layer3.weight > 0.0 and prev_record.layer3_weight == 0.0 then
            is_lby_update = true
            lby_trigger = "layer_weight"
        end
    end

    if not is_lby_update then
        is_lby_update = latest_record and (latest_record.lby_delta or 0) > 15.0
        if is_lby_update then lby_trigger = "lby_delta" end
    end

    if is_lby_update then
        local lby_side = (desync_current > 0) and 1 or -1
        local stable_side = commit_side(data, lby_side, 3)
        data.resolved_side   = stable_side
        data.resolved_desync = max_desync
        data.max_desync      = max_desync
        data.lby_confirmed   = true
        data.lby_trigger     = lby_trigger
        return stable_side, max_desync, max_desync
    end

    data.lby_confirmed = false
    data.lby_trigger   = "none"

    local stable_side = commit_side(data, side)
    data.resolved_side   = stable_side
    data.resolved_desync = actual_desync
    data.max_desync      = max_desync

    return stable_side, actual_desync, max_desync
end

local resolver = {}

resolver.ResetPlayerList = function()
    for i = 1, globals.max_players do
        lag_records[i]    = {}
        init_resolver_data(i)
    end
end

for i = 1, 65 do
    lag_records[i] = {}
    init_resolver_data(i)
end

resolver.OnNetUpdateEnd = function()
    if not menu.ragebot.resolver.enable:get() then return end

    local should_log = menu.ragebot.resolver.log:get()
    local enemies    = entity.get_players(true)

    for _, player in ipairs(enemies) do
        local idx = player:get_index()
        if player:is_alive() and not player:is_dormant() then
            local record = create_lag_record(player)
            table.insert(lag_records[idx], record)
            while #lag_records[idx] > 32 do table.remove(lag_records[idx], 1) end
        else
            lag_records[idx] = {}
        end
    end

    for _, player in ipairs(enemies) do
        local idx = player:get_index()
        if player:is_alive() and not player:is_dormant() then
            local eye_ang = player.m_angEyeAngles
            local pitch = eye_ang and eye_ang.x or 0
            local roll  = eye_ang and eye_ang.z or 0

            local side, desync, max_d = resolve_player(player)
            if side and desync then
                local value = clamp(side * desync, -CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX, CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX)

                if should_log then
                    local data = resolver_data[idx]
                    if data.last_logged_side ~= side then
                        local tag = data.lby_confirmed and ("LBY[" .. data.lby_trigger .. "]") or "anim"
                        print(string.format("[madrilla recode] resolved %s | side: %s | yaw: %ddeg | max: %ddeg | src: %s | misses: %d",
                            player:get_name(),
                            side > 0 and "R" or "L",
                            math.floor(value), math.floor(max_d or 0),
                            tag, data.misses))
                        data.last_logged_side = side
                    end
                end
            end
        end
    end
end

resolver.OnAimAck = function(e)
    if not menu.ragebot.resolver.enable:get() then return end
    local player = e.target
    if not player then return end
    local idx = player:get_index()
    if not idx then return end

    local data = resolver_data[idx]
    if not data then return end

    if e.state == nil then
        data.misses      = 0
        data.brute_phase = 0
    else
        local reason = e.state or ""
        if reason == "missed" or reason == "prediction error" or reason == "?" then
            data.misses      = data.misses + 1
            data.brute_phase = (data.brute_phase % 4) + 1

            if menu.ragebot.resolver.log:get() then
                print(string.format("[madrilla recode] miss on %s | reason: %s | total: %d | brute phase: %d",
                    player:get_name(), reason, data.misses, data.brute_phase))
            end
        end
    end
end

events.round_start:set(function()
    resolver.ResetPlayerList()
end)

events.net_update_end:set(function()
    resolver.OnNetUpdateEnd()
end)

events.aim_ack:set(function(e)
    resolver.OnAimAck(e)
end)

return resolver
