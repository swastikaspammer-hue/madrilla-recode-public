local menu = require("madrilla_recode/menu")
local entityLib = require("gamesense/entity")
local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        char pad1[0x18];
        float flAnimUpdateDelta;
        char pad2[0xC];
        float flDuckAmount;
        char pad_duck[0xC];
        float flFeetCycle;
        float flFeetYawRate;
        char pad_feet[0x4];
        float flFootYaw;
        float flLastFootYaw;
        float flGoalFeetYaw;
        float flCurrentFeetYaw;
        char pad_yaw[0x14];
        float flVelocityLenght2D;
        float flVelocityLenghtZ;
        float flSpeedAsPortionOfRunTopSpeed;
        float flSpeedAsPortionOfWalkTopSpeed;
        float flSpeedAsPortionOfCrouchTopSpeed;
        float flDurationMoving;
        float flDurationStill;
        bool bOnGround;
        bool bLanding;
        char pad_landing[2];
        float flJumpToFall;
        float flDurationInAir;
        float flLeftGroundHeight;
        float flHitGroundWeight;
        float flWalkToRunTransition;
        char pad3[0x4];
        float flInAirSmoothValue;
        bool bOnLadder;
        char pad_ladder[3];
        float flLadderWeights;
        float flLadderSpeed;
        bool bWalkToRunTransitionState;
        bool bDefuseStarted;
        bool bPlantAnimStarted;
        bool bTwitchAnimStarted;
        bool bAdjustStarted;
        char vecActivityModifiers[20];
        char pad_activity[3];
        float flNextTwitchTime;
        float flTimeOfLastKnownInjury;
        float flLastVelocityTestTime;
        char pad_velocity_test[4];
        float vecVelocityLast[3];
        float vecTargetAcceleration[3];
        float vecAcceleration[3];
        float flAccelerationWeight;
        float flAimMatrixTransition;
        float flAimMatrixTransitionDelay;
        bool bFlashed;
        char pad_flash[3];
        float flStrafeChangeWeight;
        float flStrafeChangeTargetWeight;
        float flStrafeChangeCycle;
        int nStrafeSequence;
        bool bStrafeChanging;
        char pad_strafe[3];
        float flDurationStrafing;
        float flFootLerp;
        bool bFeetCrossed;
        bool bPlayerIsAccelerating;
        char pad4[0x178];
        float flCameraSmoothHeight;
        bool bSmoothHeightValid;
        char pad_smooth[3];
        float flLastTimeVelocityOverTen;
        float flAimYawMin;
        float flAimYawMax;
        float flAimPitchMin;
        float flAimPitchMax;
        int iAnimsetVersion;
    } KS_CCSGOPlayerAnimState;

    typedef struct {
        bool m_bClientBlend;
        float m_flBlendIn;
        void *m_pStudioHdr;
        int m_nDispatchSequence;
        int m_nDispatchSequence_2;
        uint32_t m_nOrder;
        uint32_t m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        float m_flWeightDeltaRate;
        float m_flPlaybackRate;
        float m_flCycle;
        void *m_pOwner;
        int m_nInvalidatePhysicsBits;
    } CAnimationLayer;
]]

local class_ptr = ffi.typeof("void***")
local ks_entity_list_ptr = client.create_interface("client.dll", "VClientEntityList003")
local ks_get_client_entity = ffi.cast("void*(__thiscall*)(void*, int)", ffi.cast(class_ptr, ks_entity_list_ptr)[0][3])

local function ks_get_entity_address(ent_index)
    if ent_index == nil then return nil end
    local ptr = ks_get_client_entity(ks_entity_list_ptr, ent_index)
    if ptr == nil then return nil end
    return ptr
end

local function ks_get_anim_state(player)
    local entity_ptr = ks_get_entity_address(player)
    if entity_ptr == nil then return nil end
    local animstate_ptr = ffi.cast("KS_CCSGOPlayerAnimState**", ffi.cast("char*", entity_ptr) + 0x9960)
    if animstate_ptr == nil or animstate_ptr[0] == nil then return nil end
    return animstate_ptr[0]
end

local function ks_get_anim_layers(player)
    local entity_ptr = ks_get_entity_address(player)
    if entity_ptr == nil then return nil end
    local anim_layer_ptr = ffi.cast("CAnimationLayer**", ffi.cast("char*", entity_ptr) + 0x2990)
    if anim_layer_ptr == nil or anim_layer_ptr[0] == nil then return nil end
    return anim_layer_ptr[0]
end

local CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX = 58.0
local CS_PLAYER_SPEED_RUN                 = 260.0
local CS_PLAYER_SPEED_WALK_MODIFIER       = 0.52
local CS_PLAYER_SPEED_DUCK_MODIFIER       = 0.34
local CSGO_ANIM_AIM_NARROW_WALK          = 0.8
local CSGO_ANIM_AIM_NARROW_RUN           = 0.5
local CSGO_ANIM_AIM_NARROW_CROUCHMOVING  = 0.5

local function ks_angle_diff(dest, src)
    if dest == nil or src == nil then return 0 end
    local delta = (dest - src) % 360
    if delta > 180 then delta = delta - 360 end
    if delta < -180 then delta = delta + 360 end
    return delta
end

local function ks_clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

local function ks_lerp(t, a, b)
    return a + t * (b - a)
end

local function calculate_aim_matrix_width_range(speed, duck_amount, walk_to_run_transition)
    local speed_walk   = speed / (CS_PLAYER_SPEED_RUN * CS_PLAYER_SPEED_WALK_MODIFIER)
    local speed_crouch = speed / (CS_PLAYER_SPEED_RUN * CS_PLAYER_SPEED_DUCK_MODIFIER)

    local width = ks_lerp(
        ks_clamp(speed_walk, 0, 1),
        1.0,
        ks_lerp(walk_to_run_transition, CSGO_ANIM_AIM_NARROW_WALK, CSGO_ANIM_AIM_NARROW_RUN)
    )

    if duck_amount > 0 then
        width = ks_lerp(
            duck_amount * ks_clamp(speed_crouch, 0, 1),
            width,
            CSGO_ANIM_AIM_NARROW_CROUCHMOVING
        )
    end

    return width
end

local function calculate_max_desync(animstate)
    if not animstate then return CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX end
    return CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX * calculate_aim_matrix_width_range(
        animstate.flVelocityLenght2D,
        animstate.flDuckAmount,
        animstate.flWalkToRunTransition
    )
end

-- ─── Lag records ─────────────────────────────────────────────────────────────
local lag_records = {}
for i = 1, 64 do lag_records[i] = {} end

local function create_lag_record(player)
    local animstate = ks_get_anim_state(player)
    local vx, vy = entity.get_prop(player, "m_vecVelocity")
    local current_feet_yaw = animstate and animstate.flCurrentFeetYaw or 0

    local layer_ptr = ks_get_anim_layers(player)
    local layer3_weight = 0
    local layer3_cycle = 0
    local layer3_weight_delta_rate = 0
    local layer6_playback = 0
    local layer12_weight = 0
    if layer_ptr ~= nil then
        layer3_weight = layer_ptr[3].m_flWeight
        layer3_cycle = layer_ptr[3].m_flCycle
        layer3_weight_delta_rate = layer_ptr[3].m_flWeightDeltaRate
        layer6_playback = layer_ptr[6].m_flPlaybackRate
        layer12_weight = layer_ptr[12].m_flWeight
    end

    -- Grab the previous record to compute LBY delta
    local prev_record = lag_records[player] and lag_records[player][#lag_records[player]]
    local lby_delta = 0
    if prev_record then
        lby_delta = math.abs(ks_angle_diff(current_feet_yaw, prev_record.current_feet_yaw))
    end

    return {
        tick             = globals.tickcount(),
        sim_time         = entity.get_prop(player, "m_flSimulationTime"),
        eye_yaw          = select(2, entity.get_prop(player, "m_angEyeAngles")),
        goal_feet_yaw    = animstate and animstate.flGoalFeetYaw    or 0,
        current_feet_yaw = current_feet_yaw,
        origin           = {entity.get_prop(player, "m_vecOrigin")},
        velocity         = {vx or 0, vy or 0},
        flags            = entity.get_prop(player, "m_fFlags"),
        speed            = math.sqrt((vx or 0)^2 + (vy or 0)^2),
        strafe_changing  = animstate and animstate.bStrafeChanging or false,
        strafe_weight    = animstate and animstate.flStrafeChangeWeight or 0,
        lby_delta        = lby_delta,  -- LBY snap size this tick
        layer3_weight    = layer3_weight,
        layer3_cycle     = layer3_cycle,
        layer3_weight_delta_rate = layer3_weight_delta_rate,
        layer6_playback  = layer6_playback,
        layer12_weight   = layer12_weight
    }
end

-- ─── Per-player resolver state ───────────────────────────────────────────────
local VOTE_WINDOW = 6  -- ticks of history for side hysteresis

local resolver_data = {}
for i = 1, 64 do
    resolver_data[i] = {
        resolved_side    = 0,
        resolved_desync  = 0,
        last_side        = 0,
        committed_side   = 0,  -- majority-voted stable side
        misses           = 0,
        brute_phase      = 0,
        last_logged_side = 0,  -- only log on side flip, not degree change
        side_votes       = {},  -- ring buffer of recent raw side detections
    }
end

-- Returns the majority-vote side from the ring buffer.
-- weight: how many votes this reading casts (default 1, use 3 for LBY-confirmed reads)
-- Requires a clear majority (>60%) to flip; otherwise keeps the current committed side.
local function commit_side(data, raw_side, weight)
    weight = weight or 1
    local votes = data.side_votes
    for _ = 1, weight do
        table.insert(votes, raw_side)
    end
    -- Keep buffer bounded
    while #votes > VOTE_WINDOW + 4 do table.remove(votes, 1) end

    local pos, neg = 0, 0
    -- Only consider the last VOTE_WINDOW entries for the majority
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
    if data.committed_side == 0 then
        data.committed_side = raw_side
    end
    return data.committed_side
end

-- ─── Strafe-based side detection from lag record history ─────────────────────
-- If velocity direction has been consistently one way, the desync likely matches.
local function detect_strafe_side(records)
    if #records < 4 then return 0 end

    local left_count  = 0
    local right_count = 0
    -- look at last 6 ticks
    local start = math.max(1, #records - 5)
    for i = start, #records do
        local r = records[i]
        local prev = records[i - 1]
        if prev then
            -- velocity X delta: positive = strafing right, negative = left
            local dvx = (r.velocity[1] or 0) - (prev.velocity[1] or 0)
            if dvx > 2 then
                right_count = right_count + 1
            elseif dvx < -2 then
                left_count = left_count + 1
            end
        end
    end

    if right_count > left_count + 1 then return  1 end
    if left_count  > right_count + 1 then return -1 end
    return 0
end

-- ─── Geometric Freestanding Trace ──────────────────────────────────────────────
local function do_freestanding_trace(player)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return 0 end

    local eye_x, eye_y, eye_z = client.eye_position()
    local enemy_x, enemy_y, enemy_z = entity.hitbox_position(player, 0) -- head

    if not eye_x or not enemy_x then return 0 end

    local dx = enemy_x - eye_x
    local dy = enemy_y - eye_y
    local yaw = math.deg(math.atan2(dy, dx))

    -- Perpendicular angles: yaw - 90 and yaw + 90
    local right_yaw = math.rad(yaw - 90)
    local left_yaw = math.rad(yaw + 90)

    local offset = ui.get(menu.ragebot.resolver.freestandingWidth) or 40
    local left_x = enemy_x + math.cos(left_yaw) * offset
    local left_y = enemy_y + math.sin(left_yaw) * offset
    local right_x = enemy_x + math.cos(right_yaw) * offset
    local right_y = enemy_y + math.sin(right_yaw) * offset

    local frac_left = client.trace_line(player, left_x, left_y, enemy_z, eye_x, eye_y, eye_z)
    local frac_right = client.trace_line(player, right_x, right_y, enemy_z, eye_x, eye_y, eye_z)

    if frac_left < frac_right then
        -- left is more blocked, real head is safe on left, fake is pushed out to right
        return 1
    elseif frac_right < frac_left then
        -- right is more blocked, real head is safe on right, fake is pushed out to left
        return -1
    end

    return 0
end

-- ─── Core resolution ─────────────────────────────────────────────────────────
local function resolve_player(player)
    local idx = player
    if not idx or idx < 1 or idx > 64 then return end

    local records = lag_records[idx]
    if not records or #records < 2 then return end

    local data      = resolver_data[idx]
    local animstate = ks_get_anim_state(player)
    if not animstate then return end

    local max_desync = calculate_max_desync(animstate)

    local eye_yaw          = select(2, entity.get_prop(player, "m_angEyeAngles"))
    -- Use the CORRECT fields: goal = where feet want to be, current = server feet
    local goal_feet_yaw    = animstate.flGoalFeetYaw
    local current_feet_yaw = animstate.flCurrentFeetYaw

    local desync_goal    = ks_angle_diff(eye_yaw, goal_feet_yaw)
    local desync_current = ks_angle_diff(eye_yaw, current_feet_yaw)

    -- Primary: if goal and current feet disagree by >10°, the player is desynced.
    -- The direction from goal→current tells us the fake side.
    local goal_current_delta = ks_angle_diff(goal_feet_yaw, current_feet_yaw)

    local side         = 0
    local actual_desync = 0

    local is_jittering = false
    if #records >= 3 then
        local r1 = records[#records]
        local r2 = records[#records - 1]
        local r3 = records[#records - 2]
        if r1 and r2 and r3 then
            local ds1 = ks_angle_diff(r1.eye_yaw, r1.goal_feet_yaw)
            local ds2 = ks_angle_diff(r2.eye_yaw, r2.goal_feet_yaw)
            local ds3 = ks_angle_diff(r3.eye_yaw, r3.goal_feet_yaw)
            -- If alternating desync sign across 3 ticks, flag jitter
            if (ds1 > 5 and ds2 < -5 and ds3 > 5) or (ds1 < -5 and ds2 > 5 and ds3 < -5) then
                is_jittering = true
            end
        end
    end

    if is_jittering then
        side = data.last_side ~= 0 and data.last_side or 1
        actual_desync = 0 -- lock to center/zero for rapid jitter
        data.last_side = side
    elseif math.abs(goal_current_delta) > 8.0 then
        -- goal_feet_yaw is the real body, current_feet_yaw is the sent (fake) body.
        -- The fake is in the direction of desync_current.
        side = (desync_current > 0) and 1 or -1
        actual_desync = ks_clamp(math.abs(desync_current), 0, max_desync)
        data.last_side = side
    elseif math.abs(desync_goal) > 5.0 then
        -- Fallback: eye vs goal feet
        side = (desync_goal > 0) and 1 or -1
        actual_desync = ks_clamp(math.abs(desync_goal), 0, max_desync)
        data.last_side = side
    else
        -- No animstate signal — try freestanding, then strafe history, then carry last known side
        local fs_side = 0
        if ui.get(menu.ragebot.resolver.freestanding) then
            fs_side = do_freestanding_trace(player)
        end
        
        local strafe_side = detect_strafe_side(records)
        if fs_side ~= 0 then
            side = fs_side
        elseif strafe_side ~= 0 then
            side = strafe_side
        elseif data.last_side ~= 0 then
            side = data.last_side
        else
            side = -1  -- cold default
        end
        actual_desync = max_desync * 0.5  -- conservative when guessing
    end

    -- ── Brute-force correction on misses ──────────────────────────────────────
    -- Phase 0 = use detected side (normal)
    -- Phase 1 = flip side, max desync
    -- Phase 2 = opposite of flip, half desync
    -- Phase 3 = opposite of flip, zero desync
    -- Phase 4+ = reset to detected
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

    -- Detect LBY update: current_feet_yaw snapped >15° in one tick.
    -- At the moment of LBY update, flCurrentFeetYaw briefly reveals the real body direction.
    -- The direction current_feet_yaw moves relative to eye_yaw = the real desync side.
    local latest_record = records[#records]
    local prev_record = records[#records - 1]
    
    local is_lby_update = false
    local lby_trigger = "anim"
    
    local layer_ptr = ks_get_anim_layers(player)
    if layer_ptr and prev_record then
        local l3 = layer_ptr[3]
        -- Cycle reset + positive weight delta = adjusting
        if l3.m_flCycle < prev_record.layer3_cycle and l3.m_flWeightDeltaRate > 0.0 then
            is_lby_update = true
            lby_trigger = "layer_cycle_reset"
        elseif l3.m_flWeight > 0.0 and prev_record.layer3_weight == 0.0 then
            is_lby_update = true
            lby_trigger = "layer_weight"
        end
    end
    
    if not is_lby_update then
        is_lby_update = latest_record and (latest_record.lby_delta or 0) > 15.0
        if is_lby_update then lby_trigger = "lby_delta" end
    end

    if is_lby_update then
        -- LBY snap direction: where did the feet move relative to eye?
        -- If feet snapped toward eye from the right, body was left (and vice versa)
        local lby_side = (desync_current > 0) and 1 or -1
        local vote_weight = 3  -- Override stale jitter history quickly
        local stable_side = commit_side(data, lby_side, vote_weight)
        data.resolved_side   = stable_side
        data.resolved_desync = max_desync  -- trust the LBY moment fully
        data.max_desync      = max_desync
        data.lby_confirmed   = true
        data.lby_trigger     = lby_trigger
        return stable_side, max_desync, max_desync
    end
    data.lby_confirmed = false
    data.lby_trigger   = "none"

    -- Vote this tick's raw side into the hysteresis buffer
    local stable_side = commit_side(data, side)

    data.resolved_side   = stable_side
    data.resolved_desync = actual_desync
    data.max_desync      = max_desync

    return stable_side, actual_desync, max_desync
end

-- ─── Public API ──────────────────────────────────────────────────────────────
local resolver = {}

resolver.ResetPlayerList = function()
    for i = 1, 64 do
        plist.set(i, "Force body yaw", false)
        plist.set(i, "Force body yaw value", 0)
        plist.set(i, "Force pitch", false)
        plist.set(i, "Force roll", false)
        lag_records[i] = {}
        resolver_data[i] = {
            resolved_side    = 0,
            resolved_desync  = 0,
            last_side        = 0,
            committed_side   = 0,
            misses           = 0,
            brute_phase      = 0,
            last_logged_side = 0,
            side_votes       = {},
        }
    end
end

resolver.OnNetUpdateEnd = function()
    if not ui.get(menu.ragebot.resolver.enable) then return end

    local should_log = ui.get(menu.ragebot.resolver.log)
    local enemies    = entity.get_players(true)

    -- 1. Update lag records
    for _, player in ipairs(enemies) do
        if entity.is_alive(player) and not entity.is_dormant(player) then
            local record = create_lag_record(player)
            table.insert(lag_records[player], record)
            while #lag_records[player] > 32 do
                table.remove(lag_records[player], 1)
            end
        else
            lag_records[player] = {}
        end
    end

    -- 2. Resolve and apply
    for _, player in ipairs(enemies) do
        if entity.is_alive(player) and not entity.is_dormant(player) then
            -- Pitch correction (exploit: pitch < -45 = exploited upward)
            local pitch = ({entity.get_prop(player, "m_angEyeAngles")})[1] or 0
            if pitch < -45 then
                plist.set(player, "Force pitch", true)
                plist.set(player, "Force pitch value", 89)
            else
                plist.set(player, "Force pitch", false)
            end

            -- Roll correction (exploit: roll > 45 or < -45 = exploited roll)
            local roll = ({entity.get_prop(player, "m_angEyeAngles")})[3] or 0
            if math.abs(roll) > 45 then
                plist.set(player, "Force roll", true)
                plist.set(player, "Force roll value", 0)
            else
                plist.set(player, "Force roll", false)
            end

            local side, desync, max_d = resolve_player(player)
            if side and desync then
                local value = ks_clamp(side * desync, -CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX, CSGO_ANIM_AIMMATRIX_DEFAULT_YAW_MAX)

                plist.set(player, "Force body yaw", true)
                plist.set(player, "Force body yaw value", value)

                if should_log then
                    local data = resolver_data[player]
                    if data.last_logged_side ~= side then
                        local tag = data.lby_confirmed and string.format("LBY[%s]", data.lby_trigger) or "anim"
                        client.color_log(255, 100, 200,
                            string.format("[madrilla recode] resolved %s | side: %s | yaw: %ddeg | max: %ddeg | src: %s | misses: %d\000",
                                entity.get_player_name(player),
                                side > 0 and "R" or "L",
                                math.floor(value), math.floor(max_d or 0),
                                tag, data.misses))
                        data.last_logged_side = side
                    end
                end
            else
                plist.set(player, "Force body yaw", false)
            end
        else
            plist.set(player, "Force body yaw", false)
        end
    end
end

-- Gamesense miss reasons: "missed", "spread", "prediction error", "occlusion"
-- We only brute on "missed" (resolver wrong) not spread/occlusion (random/blocked)
resolver.OnAimMiss = function(event)
    if not ui.get(menu.ragebot.resolver.enable) then return end
    local player = event.target
    if not player then return end

    local reason = event.reason or ""
    -- Only count resolver misses, not spread or occlusion
    if reason ~= "missed" and reason ~= "prediction error" and reason ~= "?" then return end

    local data = resolver_data[player]
    if not data then return end

    data.misses     = data.misses + 1
    data.brute_phase = (data.brute_phase % 4) + 1

    if ui.get(menu.ragebot.resolver.log) then
        client.color_log(255, 50, 50,
            string.format("[madrilla recode] miss on %s | reason: %s | total: %d | brute phase: %d",
                entity.get_player_name(player), reason, data.misses, data.brute_phase))
    end
end

resolver.OnAimHit = function(event)
    if not ui.get(menu.ragebot.resolver.enable) then return end
    local player = event.target
    if not player then return end

    local data = resolver_data[player]
    if data then
        data.misses      = 0
        data.brute_phase = 0
    end
end

client.set_event_callback("round_start", function()
    resolver.ResetPlayerList()
end)

return resolver