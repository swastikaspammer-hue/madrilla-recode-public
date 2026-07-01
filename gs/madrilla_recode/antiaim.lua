local menu = require("madrilla_recode/menu")
local pui = require("gamesense/pui")
local entityLib = require("gamesense/entity")
local resolver = require("madrilla_recode/resolver")
local vector = require("vector")

local pitch_mode, pitch_value = pui.reference('AA', 'Anti-aimbot angles', 'Pitch')
local yaw_base = pui.reference('AA', 'Anti-aimbot angles', 'Yaw base')
local yaw_mode, yaw_value = pui.reference('AA', 'Anti-aimbot angles', 'Yaw')
local yaw_jitter_mode, yaw_jitter_yaw = pui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')
local body_yaw_mode, body_yaw_value = pui.reference('AA', 'Anti-aimbot angles', 'Body Yaw')

local function DisableMicromove(cmd)
    cmd.in_back      = true
    cmd.in_moveleft  = true
    cmd.in_moveright = true
    cmd.in_forward   = true

    cmd.forwardmove = 0
    cmd.sidemove = 0
end
local function CalculateLFO(time, shape, speedPercentage, range, scaleByVelocity)
    -- Normalize speed
    local minHz = 0.5
    local maxHz = 15.0
    local speedHz = minHz + ((speedPercentage / 100) * (maxHz - minHz))

    if scaleByVelocity then
        local localPlayer = entity.get_local_player()
        if localPlayer then
            local velX, velY, velZ = entity.get_prop(localPlayer, "m_vecVelocity")
            if velX ~= nil and velY ~= nil then
                local velocity = math.sqrt(velX * velX + velY * velY)
                -- Scale multiplier: e.g. at 250 units/s, speed is 2x. at 0, speed is 1x.
                local velocityMultiplier = 1.0 + (velocity / 250.0) * 1.5 
                speedHz = speedHz * velocityMultiplier
            end
        end
    end

    local t = time * speedHz * 2 * math.pi
    if shape == "sine" then
        return math.sin(t) * range
    elseif shape == "triangle" then
        local val = (t / (2 * math.pi)) % 1.0
        if val < 0.5 then
            return (val * 4 - 1) * range
        else
            return ((1 - val) * 4 - 1) * range
        end
    elseif shape == "pulse" then
        return (math.sin(t) > 0) and range or -range
    end
    return 0
end

antiaim = {
    GetKnifeTarget = function()
        local localPlayer = entity.get_local_player()
        if not localPlayer or not entity.is_alive(localPlayer) then return nil end

        local pos = {}
        pos.x, pos.y, pos.z = entity.get_origin(localPlayer)
        if not pos.x or not pos.y or not pos.z then return nil end

        local closestThreat = nil
        local closestDist = 230
        for entityIndex = 1, globals.maxplayers() do
            local target = entityIndex
            if target == localPlayer or not entity.is_alive(target) or not entity.is_enemy(target) then goto continue end

            local weapon = entity.get_player_weapon(target)
            if weapon and entity.get_classname(weapon) == "CKnife" then
                local enemyPos = {}
                enemyPos.x, enemyPos.y, enemyPos.z = entity.get_origin(target)

                if enemyPos.x and enemyPos.y and enemyPos.z then 
                    local dx = pos.x - enemyPos.x
                    local dy = pos.y - enemyPos.y
                    local dz = pos.z - enemyPos.z
                    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                    if dist < closestDist then
                        closestDist = dist
                        closestThreat = target
                    end
                end
            end

            ::continue::
        end

        return closestThreat
    end,

    prev_sim_time = 0,
    active_until = 1,
    ticks = 0,
    ticks_from_activation = 0,
    active = false,
    UpdateDefensive = function()
        local local_player = entity.get_local_player()
        if not local_player then return end

        local tickcount = globals.tickcount()

        local sim_time = toticks(entity.get_prop(local_player, 'm_flSimulationTime'))
        local sim_diff = sim_time - antiaim.prev_sim_time

        -- Negative sim_diff means the server rolled back our simulation time,
        -- which happens when an incoming shot's lag-compensation fires.
        if sim_diff < 0 then
            -- Give ourselves a window equal to the rollback ticks.
            -- Clamp to minimum 1 tick so latency subtraction can't kill it immediately.
            local latency_ticks = toticks(client.real_latency())
            local window = math.max(1, math.abs(sim_diff) - latency_ticks)
            antiaim.active_until = tickcount + window
            antiaim.ticks = window
        end

        antiaim.prev_sim_time = sim_time

        -- Only clear active if we're past the window AND not choking.
        -- If we're choking we keep the previous active state so the window
        -- isn't artificially shortened by command choke.
        if globals.chokedcommands() <= 1 then
            antiaim.active = antiaim.active_until > tickcount
        end

        if antiaim.active then
            antiaim.ticks_from_activation = antiaim.ticks - (antiaim.active_until - tickcount) + 1
        end
    end,


    GetState = function(cmd)
        local localPlayer = entity.get_local_player()
        local flags = entity.get_prop(localPlayer, "m_fFlags")

        local onGround = bit.band(flags, 1) == 1
        local inDuck = cmd.in_duck == 1

        local slow_motion_hk = ui.reference("AA", "Other", "Slow motion")
        local fakeduck_hk = ui.reference("RAGE", "Other", "Duck peek assist")
        local isFakeducking = ui.get(fakeduck_hk)
        local isSlowWalking = ui.get(slow_motion_hk)

        if not onGround then
            if inDuck then 
                if ui.get(menu.antiaim.states["air crouched"].overrideGlobal) then
                    return menu.antiaim.states["air crouched"]
                end
            else
                 if ui.get(menu.antiaim.states["air"].overrideGlobal) then
                    return menu.antiaim.states["air"]
                end
            end

            return menu.antiaim.states["global"]
        end

        local vecVelocity = {entity.get_prop(localPlayer, "m_vecVelocity")}
        local velocity = math.sqrt(vecVelocity[1] ^ 2 + vecVelocity[2] ^ 2)

        if isFakeducking and ui.get(menu.antiaim.states["fakeducking"].overrideGlobal) then
            return menu.antiaim.states["fakeducking"]
        end

        if inDuck then
            if velocity > 1.1 and ui.get(menu.antiaim.states["crouch moving"].overrideGlobal) then
                return menu.antiaim.states["crouch moving"]
            elseif velocity < 1.1 and ui.get(menu.antiaim.states["crouched"].overrideGlobal) then
                return menu.antiaim.states["crouched"]
            end
        end

        if isSlowWalking and velocity > 1.1 and ui.get(menu.antiaim.states["slow walking"].overrideGlobal) then
            return menu.antiaim.states["slow walking"]
        end

        if velocity > 1.1 and ui.get(menu.antiaim.states["moving"].overrideGlobal) then 
            return menu.antiaim.states["moving"]
        end

        if velocity < 1.1 and ui.get(menu.antiaim.states["standing"].overrideGlobal) then 
            return menu.antiaim.states["standing"]
        end

        return menu.antiaim.states["global"]
    end,

    ResetAntiAimSets = function()
        pitch_mode:override()
        pitch_value:override()
        yaw_base:override()
        yaw_mode:override()
        yaw_value:override()
        yaw_jitter_mode:override()
        yaw_jitter_yaw:override()
        body_yaw_mode:override()
        body_yaw_value:override()
    end,

    bodyYawSide = 0,
    bodyYawDelay = 0,

    yawSide = 0,
    yawAmmount = 0,
    yawDelay = 0,
    lastHit = false,
    OnSetupCommand = function(cmd)
        antiaim.UpdateDefensive()

        if ui.get(menu.antiaim.enableAntiBackstab) then
            local target = antiaim.GetKnifeTarget()
            if target and cmd.in_attack ~= 1 then
                local eyePosition = vector(client.eye_position())
                local targetPitch, targetYaw = eyePosition:to(vector(entity.get_origin(target))):angles()

                cmd.yaw = targetYaw;
                cmd.pitch = targetPitch;

                return;
            end
        end

        if not ui.get(menu.antiaim.enable) then
            antiaim.ResetAntiAimSets() 
            return 
        end

        local state = antiaim.GetState(cmd)

        local shouldStaticPeek = false
        local target = client.current_threat()
        if target then
            local espData = entity.get_esp_data(target)
            if espData then
                local hit = bit.band(espData.flags, 2048) ~= 0
                if hit and not antiaim.lastHit then
                    shouldStaticPeek = true
                end

                antiaim.lastHit = hit
            end
        end

        cmd.force_defensive = ui.get(state.forceDefensive)

        if antiaim.active and ui.get(state.allowDefensive) and ui.get(menu.antiaim.states["defensive"].overrideGlobal) then
            state = menu.antiaim.states["defensive"]
        end

        if ui.get(state.staticPeek) and shouldStaticPeek then
            antiaim.bodyYawDelay = 15
            antiaim.yawDelay = 15
        end

        if ui.get(menu.antiaim.manualLeft) then
            yaw_base:override("Local view")
            yaw_mode:override("180")
            yaw_value:override(-90)
            return
        elseif ui.get(menu.antiaim.manualRight) then
            yaw_base:override("Local view")
            yaw_mode:override("180")
            yaw_value:override(90)
            return
        elseif ui.get(menu.antiaim.manualForward) then
            yaw_base:override("Local view")
            yaw_mode:override("180")
            yaw_value:override(180)
            return
        elseif ui.get(menu.antiaim.manualBack) then
            yaw_base:override("Local view")
            yaw_mode:override("180")
            yaw_value:override(0)
            return
        end

        local yawMode = ui.get(state.yawMode)
        if yawMode == "static" then
            antiaim.yawSide = 1
            antiaim.yawAmmount = ui.get(state.yawOffset)
        elseif yawMode == "jitter" then
            if globals.chokedcommands() < 1 then
                antiaim.yawSide = not antiaim.yawSide
                antiaim.yawAmmount = ui.get(state.yawOffset) / 2
            end
        elseif yawMode == "delayed jitter" then
            if antiaim.yawDelay == 0 then
                antiaim.yawSide = not antiaim.yawSide
                antiaim.yawAmmount = ui.get(state.yawOffset) / 2
                antiaim.yawDelay = math.random(ui.get(state.yawJitterDelayMin), ui.get(state.yawJitterDelayMax))
            else
                antiaim.yawDelay = antiaim.yawDelay -1
            end
        elseif yawMode == "random" then
            antiaim.yawSide = math.random(0, 1) == 1
            antiaim.yawAmmount = math.random(-180, 180)
        elseif yawMode == "spin" then
            local speed = 360 / 30
            antiaim.yawAmmount = (globals.tickcount() * speed) % 360

            if  antiaim.yawAmmount > 180 then
                antiaim.yawAmmount = antiaim.yawAmmount - 360
            end

            if antiaim.yawAmmount < -180 then
                antiaim.yawAmmount = antiaim.yawAmmount + 360
            end
        elseif yawMode == "lfo" then
            antiaim.yawSide = 1
            local shape = ui.get(state.yawLfoShape)
            local speed = ui.get(state.yawLfoSpeed)
            local scaleVelocity = ui.get(state.yawLfoVelocityScale)
            local range = ui.get(state.yawLfoRange)
            antiaim.yawAmmount = CalculateLFO(globals.realtime(), shape, speed, range, scaleVelocity)
        elseif yawMode == "switch" then
            local delay = ui.get(state.yawSwitchDelay)
            if globals.tickcount() % delay == 0 then
                antiaim.yawSide = not antiaim.yawSide
            end
            antiaim.yawAmmount = ui.get(state.yawOffset)
        elseif yawMode == "3-way" then
            if globals.chokedcommands() < 1 then
                if antiaim.yaw3WayState == nil then antiaim.yaw3WayState = 0 end
                antiaim.yaw3WayState = (antiaim.yaw3WayState + 1) % 3
                if antiaim.yaw3WayState == 0 then
                    antiaim.yawAmmount = 0
                elseif antiaim.yaw3WayState == 1 then
                    antiaim.yawAmmount = ui.get(state.yawOffset)
                else
                    antiaim.yawAmmount = -ui.get(state.yawOffset)
                end
                antiaim.yawSide = true
            end
        elseif yawMode == "5-way" then
            if globals.chokedcommands() < 1 then
                if antiaim.yaw5WayState == nil then antiaim.yaw5WayState = 0 end
                antiaim.yaw5WayState = (antiaim.yaw5WayState + 1) % 5
                local offset = ui.get(state.yawOffset)
                if antiaim.yaw5WayState == 0 then antiaim.yawAmmount = 0
                elseif antiaim.yaw5WayState == 1 then antiaim.yawAmmount = offset / 2
                elseif antiaim.yaw5WayState == 2 then antiaim.yawAmmount = offset
                elseif antiaim.yaw5WayState == 3 then antiaim.yawAmmount = -offset / 2
                else antiaim.yawAmmount = -offset end
                antiaim.yawSide = true
            end
        end

        local bodyYawMode = ui.get(state.bodyYawMode)
        local lfoBodyYawAmount = 0
        local isBodyYawLfo = false

        if bodyYawMode == "static" then
            -- Static does not change bodyYawSide automatically
        elseif bodyYawMode == "delayed jitter" then
            if antiaim.bodyYawDelay == 0 then
                antiaim.bodyYawSide = not antiaim.bodyYawSide
                antiaim.bodyYawDelay = math.random(ui.get(state.bodyYawJitterDelayMin), ui.get(state.bodyYawJitterDelayMax))
            else
                antiaim.bodyYawDelay = antiaim.bodyYawDelay - 1
            end
        elseif bodyYawMode == "jitter" then
            if globals.chokedcommands() < 1 then
                antiaim.bodyYawSide = not antiaim.bodyYawSide 
            end
        elseif bodyYawMode == "random" then
            if globals.chokedcommands() < 1 then
                antiaim.bodyYawSide = math.random(0, 1) == 1
            end
        elseif bodyYawMode == "lfo" then
            isBodyYawLfo = true
            local shape = ui.get(state.bodyYawLfoShape)
            local speed = ui.get(state.bodyYawLfoSpeed)
            local scaleVelocity = ui.get(state.bodyYawLfoVelocityScale)
            local range = ui.get(state.bodyYawLfoRange)
            lfoBodyYawAmount = CalculateLFO(globals.realtime(), shape, speed, range, scaleVelocity)
        end

        local finalYawAmmount = antiaim.yawSide and antiaim.yawAmmount or -antiaim.yawAmmount
        local bodyYawOffset = ui.get(state.bodyYawOffset) or 60
        local finalBodyYawSide = antiaim.bodyYawSide and bodyYawOffset or -bodyYawOffset

        if antiaim.inversionActive then
            finalYawAmmount = -finalYawAmmount
            finalBodyYawSide = -finalBodyYawSide
            if isBodyYawLfo then
                lfoBodyYawAmount = -lfoBodyYawAmount
            end
        end

        local lbyBreakerTriggered = false
        -- Handle LBY Breaker
        if ui.get(menu.antiaim.lbyBreaker) then
            local lbyUpdateRate = 0.22
            local curtime = globals.curtime()
            local timeSinceUpdate = curtime % lbyUpdateRate
            if timeSinceUpdate < globals.tickinterval() * 2 then
                lbyBreakerTriggered = true
                finalBodyYawSide = 120
                if globals.tickcount() % 2 == 0 then
                    finalBodyYawSide = -120
                end
            end
        end

        yaw_value:override(finalYawAmmount)

        pitch_mode:override("Custom")
        pitch_value:override(ui.get(state.pitchOffset))     

        if lbyBreakerTriggered then
            body_yaw_mode:override("Static")
            body_yaw_value:override(finalBodyYawSide)
        elseif isBodyYawLfo then
            body_yaw_mode:override("Static")
            body_yaw_value:override(lfoBodyYawAmount)
        else
            body_yaw_mode:override("Static")
            body_yaw_value:override(finalBodyYawSide)
        end

        if ui.get(state.fakeBreaker) then
            if globals.chokedcommands() == 2 then
                antiaim.bodyYawSide = 0
                body_yaw_mode:override("Off")
                body_yaw_value:override(0)
            else
                antiaim.bodyYawSide = 1
                -- Extended Desync pushes maximum body yaw offset during choked ticks
                local overrideYaw = antiaim.bodyYawSide and 120 or -120
                body_yaw_value:override(overrideYaw)
            end

            if ui.get(state.extendFake) then
                antiaim.handle_anti_aim(entity.get_local_player(), cmd)
            end
        end        
    end,

    extend_yaw_suppress = 0,
    was_extending = false,
    extend_suppression_duration = 0,

    handle_anti_aim = function(local_player, cmd)
        local is_moving = math.abs(cmd.forwardmove) > 1 or math.abs(cmd.sidemove) > 1 or cmd.in_jump == 1
        local is_defending = antiaim.active
        
        local extend_active = not is_moving and not is_defending and cmd.in_attack ~= 1

        if extend_active and not antiaim.was_extending then
            antiaim.extend_yaw_suppress = 1
            antiaim.extend_suppression_duration = 5
        elseif not extend_active then
            antiaim.extend_yaw_suppress = 0
        end
        antiaim.was_extending = extend_active

        local suppress_yaw = antiaim.extend_yaw_suppress > 0

        -- Apply body yaw adjustments
        local body_yaw_adjustment = antiaim.bodyYawSide and 120 or -120

        if extend_active then
            if cmd.chokedcommands == 0 then
                body_yaw_adjustment = -body_yaw_adjustment
            else
                DisableMicromove(cmd)
            end
        end

        body_yaw_value:override(body_yaw_adjustment)

        if suppress_yaw and cmd.chokedcommands == 0 then
            antiaim.extend_yaw_suppress = antiaim.extend_yaw_suppress - 1
        end
    end,

    OnRoundStart = function()
        antiaim.prev_sim_time = 0
        antiaim.active_until = 1
        antiaim.ticks = 0
        antiaim.ticks_from_activation = 0
        antiaim.active = false
        antiaim.extend_yaw_suppress = 0
        antiaim.was_extending = false
        antiaim.extend_suppression_duration = 0
        antiaim.inversionActive = false
    end,
}

local hit_this_tick = 0
local antiBrutePhase = 0

local function distance3d(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

local function distance_point_to_line(px, py, pz, l1x, l1y, l1z, l2x, l2y, l2z)
    local lx, ly, lz = l2x - l1x, l2y - l1y, l2z - l1z
    local length_squared = lx^2 + ly^2 + lz^2
    if length_squared == 0 then return distance3d(px, py, pz, l1x, l1y, l1z) end

    local t = ((px - l1x) * lx + (py - l1y) * ly + (pz - l1z) * lz) / length_squared
    t = math.max(0, math.min(1, t))
    
    local proj_x = l1x + t * lx
    local proj_y = l1y + t * ly
    local proj_z = l1z + t * lz

    return distance3d(px, py, pz, proj_x, proj_y, proj_z)
end

local function TriggerAntiBrute()
    local action = ui.get(menu.antiaim.antiBruteAction)
    if action == "Invert Side" then
        antiaim.inversionActive = not antiaim.inversionActive
    elseif action == "Randomize" then
        antiaim.inversionActive = math.random(1, 2) == 1
        antiaim.yaw3WayState = math.random(0, 2)
        antiaim.yaw5WayState = math.random(0, 4)
    elseif action == "Cycle 3-way" then
        antiBrutePhase = (antiBrutePhase + 1) % 3
        if antiBrutePhase == 0 then
            antiaim.inversionActive = false
            antiaim.yaw3WayState = 0
        elseif antiBrutePhase == 1 then
            antiaim.inversionActive = true
            antiaim.yaw3WayState = 1
        else
            antiaim.inversionActive = not antiaim.inversionActive
            antiaim.yaw3WayState = 2
        end
    end
end

client.set_event_callback("weapon_fire", function(e)
    if not ui.get(menu.antiaim.invertOnShot) then return end
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        antiaim.inversionActive = not antiaim.inversionActive
    end
end)

client.set_event_callback("player_hurt", function(e)
    local me = entity.get_local_player()
    if client.userid_to_entindex(e.userid) == me then
        hit_this_tick = globals.tickcount()
        
        if ui.get(menu.antiaim.invertOnHit) then
            antiaim.inversionActive = not antiaim.inversionActive
        end
        
        if ui.get(menu.antiaim.antiBrute) then
            local modes = ui.get(menu.antiaim.antiBruteModes)
            for _, mode in ipairs(modes) do
                if mode == "On Hit" then
                    TriggerAntiBrute()
                    break
                end
            end
        end
    end
end)

client.set_event_callback("bullet_impact", function(e)
    if not ui.get(menu.antiaim.antiBrute) then return end
    
    local modes = ui.get(menu.antiaim.antiBruteModes)
    local has_on_miss = false
    for _, mode in ipairs(modes) do
        if mode == "On Miss" then has_on_miss = true break end
    end
    
    if not has_on_miss then return end

    local shooter = client.userid_to_entindex(e.userid)
    local me = entity.get_local_player()
    
    if shooter == me or shooter == nil or me == nil then return end
    if entity.get_prop(shooter, "m_iTeamNum") == entity.get_prop(me, "m_iTeamNum") then return end
    
    local sx, sy, sz = entity.hitbox_position(shooter, 0)
    local mx, my, mz = entity.get_prop(me, "m_vecOrigin")
    
    if sx == nil or mx == nil then return end
    
    local dist = distance_point_to_line(mx, my, mz + 32, sx, sy, sz, e.x, e.y, e.z)
    
    if dist < 64 then
        client.delay_call(0, function()
            if hit_this_tick == globals.tickcount() then return end
            TriggerAntiBrute()
        end)
    end
end)

return antiaim