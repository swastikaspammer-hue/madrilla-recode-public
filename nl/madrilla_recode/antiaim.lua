local menu = require("madrilla_recode/menu")

local function CalculateLFO(time, shape, speedPercentage, range, scaleByVelocity)
    local minHz = 0.5
    local maxHz = 15.0
    local speedHz = minHz + ((speedPercentage / 100) * (maxHz - minHz))

    if scaleByVelocity then
        local localPlayer = entity.get_local_player()
        if localPlayer then
            local vel = localPlayer.m_vecVelocity
            if vel then
                local velocity = math.sqrt(vel.x * vel.x + vel.y * vel.y)
                speedHz = speedHz * (1.0 + (velocity / 250.0) * 1.5)
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

local antiaim = {
    prev_sim_time          = 0,
    active_until           = 1,
    ticks                  = 0,
    ticks_from_activation  = 0,
    active                 = false,
    bodyYawSide            = false,
    bodyYawDelay           = 0,
    yawSide                = false,
    yawAmmount             = 0,
    yawDelay               = 0,
    lastHit                = false,
    inversionActive        = false,
    extend_yaw_suppress    = 0,
    was_extending          = false,
    yaw3WayState           = 0,
    yaw5WayState           = 0,
}

antiaim.GetKnifeTarget = function()
    local localPlayer = entity.get_local_player()
    if not localPlayer or not localPlayer:is_alive() then return nil end

    local myPos = localPlayer:get_origin()
    if not myPos then return nil end

    local closestThreat = nil
    local closestDist = 230

    for _, target in ipairs(entity.get_players(true)) do
        if target ~= localPlayer and target:is_alive() then
            local weapon = target:get_player_weapon()
            if weapon and weapon:get_classname() == "CKnife" then
                local enemyPos = target:get_origin()
                if enemyPos then
                    local dx = myPos.x - enemyPos.x
                    local dy = myPos.y - enemyPos.y
                    local dz = myPos.z - enemyPos.z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if dist < closestDist then
                        closestDist = dist
                        closestThreat = target
                    end
                end
            end
        end
    end

    return closestThreat
end

antiaim.UpdateDefensive = function()
    local local_player = entity.get_local_player()
    if not local_player then return end

    local tickcount = globals.tickcount
    local simtimes = local_player:get_simulation_time()
    local sim_time = math.floor(simtimes.current / globals.tickinterval)
    local sim_diff = sim_time - antiaim.prev_sim_time

    if sim_diff < 0 then
        local latency_ticks = math.floor((utils.net_channel().avg_latency[0] + utils.net_channel().avg_latency[1]) / globals.tickinterval)
        local window = math.max(1, math.abs(sim_diff) - latency_ticks)
        antiaim.active_until = tickcount + window
        antiaim.ticks = window
    end

    antiaim.prev_sim_time = sim_time

    if globals.choked_commands <= 1 then
        antiaim.active = antiaim.active_until > tickcount
    end

    if antiaim.active then
        antiaim.ticks_from_activation = antiaim.ticks - (antiaim.active_until - tickcount) + 1
    end
end

antiaim.GetState = function(cmd)
    local localPlayer = entity.get_local_player()
    local flags = localPlayer.m_fFlags or 0
    local onGround = bit.band(flags, 1) == 1
    local duckAmt = localPlayer.m_flDuckAmount or 0
    local inDuck = duckAmt > 0.5

    local vel = localPlayer.m_vecVelocity
    local velocity = vel and math.sqrt(vel.x^2 + vel.y^2) or 0

    if not onGround then
        if inDuck and menu.antiaim.states["air crouched"].overrideGlobal and menu.antiaim.states["air crouched"].overrideGlobal:get() then
            return menu.antiaim.states["air crouched"]
        elseif not inDuck and menu.antiaim.states["air"].overrideGlobal and menu.antiaim.states["air"].overrideGlobal:get() then
            return menu.antiaim.states["air"]
        end
        return menu.antiaim.states["global"]
    end

    if inDuck then
        if velocity > 1.1 and menu.antiaim.states["crouch moving"].overrideGlobal and menu.antiaim.states["crouch moving"].overrideGlobal:get() then
            return menu.antiaim.states["crouch moving"]
        elseif velocity < 1.1 and menu.antiaim.states["crouched"].overrideGlobal and menu.antiaim.states["crouched"].overrideGlobal:get() then
            return menu.antiaim.states["crouched"]
        end
    end

    if velocity > 1.1 and menu.antiaim.states["moving"].overrideGlobal and menu.antiaim.states["moving"].overrideGlobal:get() then
        return menu.antiaim.states["moving"]
    end

    if velocity < 1.1 and menu.antiaim.states["standing"].overrideGlobal and menu.antiaim.states["standing"].overrideGlobal:get() then
        return menu.antiaim.states["standing"]
    end

    return menu.antiaim.states["global"]
end

antiaim.OnSetupCommand = function(cmd)
    antiaim.UpdateDefensive()

    if menu.antiaim.enableAntiBackstab:get() then
        local target = antiaim.GetKnifeTarget()
        if target then
            local lp = entity.get_local_player()
            if lp then
                local eyePos = lp:get_eye_position()
                local targetPos = target:get_origin()
                if eyePos and targetPos then
                    local dx = targetPos.x - eyePos.x
                    local dy = targetPos.y - eyePos.y
                    local dz = targetPos.z - eyePos.z
                    local dist2d = math.sqrt(dx*dx + dy*dy)
                    cmd.view_angles.y = math.deg(math.atan2(dy, dx))
                    cmd.view_angles.x = -math.deg(math.atan2(dz, dist2d))
                end
            end
            return
        end
    end

    if not menu.antiaim.enable:get() then
        rage.antiaim:override_hidden_pitch(nil)
        rage.antiaim:override_hidden_yaw_offset(nil)
        return
    end

    local state = antiaim.GetState(cmd)

    if menu.antiaim.manualLeft:get() then
        cmd.view_angles.y = cmd.view_angles.y - 90
        return
    elseif menu.antiaim.manualRight:get() then
        cmd.view_angles.y = cmd.view_angles.y + 90
        return
    elseif menu.antiaim.manualBack:get() then
        cmd.view_angles.y = cmd.view_angles.y + 180
        return
    elseif menu.antiaim.manualForward:get() then
        return
    end

    if state.forceDefensive and state.forceDefensive:get() then
        cmd.force_defensive = true
    end

    if antiaim.active and state.allowDefensive and state.allowDefensive:get() and
       menu.antiaim.states["defensive"].overrideGlobal and menu.antiaim.states["defensive"].overrideGlobal:get() then
        state = menu.antiaim.states["defensive"]
    end

    local yawMode = state.yawMode:get()
    if yawMode == "static" then
        antiaim.yawSide = true
        antiaim.yawAmmount = state.yawOffset:get()
    elseif yawMode == "jitter" then
        if globals.choked_commands < 1 then
            antiaim.yawSide = not antiaim.yawSide
            antiaim.yawAmmount = state.yawOffset:get() / 2
        end
    elseif yawMode == "delayed jitter" then
        if antiaim.yawDelay == 0 then
            antiaim.yawSide = not antiaim.yawSide
            antiaim.yawAmmount = state.yawOffset:get() / 2
            antiaim.yawDelay = math.random(state.yawJitterDelayMin:get(), state.yawJitterDelayMax:get())
        else
            antiaim.yawDelay = antiaim.yawDelay - 1
        end
    elseif yawMode == "random" then
        antiaim.yawSide = math.random(0, 1) == 1
        antiaim.yawAmmount = math.random(-180, 180)
    elseif yawMode == "spin" then
        local speed = 360 / 30
        antiaim.yawAmmount = (globals.tickcount * speed) % 360
        if antiaim.yawAmmount > 180 then antiaim.yawAmmount = antiaim.yawAmmount - 360 end
        if antiaim.yawAmmount < -180 then antiaim.yawAmmount = antiaim.yawAmmount + 360 end
        antiaim.yawSide = true
    elseif yawMode == "lfo" then
        antiaim.yawSide = true
        antiaim.yawAmmount = CalculateLFO(globals.realtime, state.yawLfoShape:get(),
            state.yawLfoSpeed:get(), state.yawLfoRange:get(), state.yawLfoVelocityScale:get())
    elseif yawMode == "switch" then
        local delay = state.yawSwitchDelay:get()
        if globals.tickcount % delay == 0 then
            antiaim.yawSide = not antiaim.yawSide
        end
        antiaim.yawAmmount = state.yawOffset:get()
    elseif yawMode == "3-way" then
        if globals.choked_commands < 1 then
            antiaim.yaw3WayState = (antiaim.yaw3WayState + 1) % 3
            local offset = state.yawOffset:get()
            if antiaim.yaw3WayState == 0 then antiaim.yawAmmount = 0
            elseif antiaim.yaw3WayState == 1 then antiaim.yawAmmount = offset
            else antiaim.yawAmmount = -offset end
            antiaim.yawSide = true
        end
    elseif yawMode == "5-way" then
        if globals.choked_commands < 1 then
            antiaim.yaw5WayState = (antiaim.yaw5WayState + 1) % 5
            local offset = state.yawOffset:get()
            if antiaim.yaw5WayState == 0 then antiaim.yawAmmount = 0
            elseif antiaim.yaw5WayState == 1 then antiaim.yawAmmount = offset / 2
            elseif antiaim.yaw5WayState == 2 then antiaim.yawAmmount = offset
            elseif antiaim.yaw5WayState == 3 then antiaim.yawAmmount = -offset / 2
            else antiaim.yawAmmount = -offset end
            antiaim.yawSide = true
        end
    end

    local bodyYawMode = state.bodyYawMode:get()
    local lfoBodyYawAmount = 0
    local isBodyYawLfo = false

    if bodyYawMode == "delayed jitter" then
        if antiaim.bodyYawDelay == 0 then
            antiaim.bodyYawSide = not antiaim.bodyYawSide
            antiaim.bodyYawDelay = math.random(
                state.bodyYawJitterDelayMin:get(),
                state.bodyYawJitterDelayMax:get()
            )
        else
            antiaim.bodyYawDelay = antiaim.bodyYawDelay - 1
        end
    elseif bodyYawMode == "jitter" then
        if globals.choked_commands < 1 then
            antiaim.bodyYawSide = not antiaim.bodyYawSide
        end
    elseif bodyYawMode == "random" then
        if globals.choked_commands < 1 then
            antiaim.bodyYawSide = math.random(0, 1) == 1
        end
    elseif bodyYawMode == "lfo" then
        isBodyYawLfo = true
        lfoBodyYawAmount = CalculateLFO(globals.realtime, state.bodyYawLfoShape:get(),
            state.bodyYawLfoSpeed:get(), state.bodyYawLfoRange:get(), state.bodyYawLfoVelocityScale:get())
    end

    local finalYawAmmount = antiaim.yawSide and antiaim.yawAmmount or -antiaim.yawAmmount
    local bodyYawOffset = state.bodyYawOffset:get()
    local finalBodyYawSide = antiaim.bodyYawSide and bodyYawOffset or -bodyYawOffset

    if antiaim.inversionActive then
        finalYawAmmount = -finalYawAmmount
        finalBodyYawSide = -finalBodyYawSide
        if isBodyYawLfo then lfoBodyYawAmount = -lfoBodyYawAmount end
    end

    if menu.antiaim.lbyBreaker:get() then
        local lbyUpdateRate = 0.22
        local curtime = globals.curtime
        local timeSinceUpdate = curtime % lbyUpdateRate
        if timeSinceUpdate < globals.tickinterval * 2 then
            finalBodyYawSide = globals.tickcount % 2 == 0 and 120 or -120
        end
    end

    rage.antiaim:override_hidden_pitch(state.pitchOffset:get())
    rage.antiaim:override_hidden_yaw_offset(isBodyYawLfo and lfoBodyYawAmount or finalBodyYawSide)

    if state.fakeBreaker and state.fakeBreaker:get() then
        if globals.choked_commands == 2 then
            rage.antiaim:override_hidden_yaw_offset(0)
        else
            rage.antiaim:override_hidden_yaw_offset(antiaim.bodyYawSide and 120 or -120)
        end
    end

    cmd.view_angles.y = cmd.view_angles.y + finalYawAmmount
end

antiaim.OnRoundStart = function()
    antiaim.prev_sim_time         = 0
    antiaim.active_until          = 1
    antiaim.ticks                 = 0
    antiaim.ticks_from_activation = 0
    antiaim.active                = false
    antiaim.extend_yaw_suppress   = 0
    antiaim.was_extending         = false
    antiaim.inversionActive       = false
    antiaim.yaw3WayState          = 0
    antiaim.yaw5WayState          = 0
end

local hit_this_tick = 0
local antiBrutePhase = 0

local function TriggerAntiBrute()
    local action = menu.antiaim.antiBruteAction:get()
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

events.weapon_fire:set(function(e)
    if not menu.antiaim.invertOnShot:get() then return end
    local shooter = entity.get(e.userid, true)
    if shooter == entity.get_local_player() then
        antiaim.inversionActive = not antiaim.inversionActive
    end
end)

events.player_hurt:set(function(e)
    local me = entity.get_local_player()
    local victim = entity.get(e.userid, true)
    if victim ~= me then return end

    hit_this_tick = globals.tickcount

    if menu.antiaim.invertOnHit:get() then
        antiaim.inversionActive = not antiaim.inversionActive
    end

    if menu.antiaim.antiBrute:get() then
        local modes = menu.antiaim.antiBruteModes:get()
        for _, mode in ipairs(modes) do
            if mode == "On Hit" then
                TriggerAntiBrute()
                break
            end
        end
    end
end)

events.bullet_impact:set(function(e)
    if not menu.antiaim.antiBrute:get() then return end

    local modes = menu.antiaim.antiBruteModes:get()
    local has_on_miss = false
    for _, mode in ipairs(modes) do
        if mode == "On Miss" then has_on_miss = true break end
    end
    if not has_on_miss then return end

    local shooter = entity.get(e.userid, true)
    local me = entity.get_local_player()
    if not shooter or not me or shooter == me then return end
    if shooter.m_iTeamNum == me.m_iTeamNum then return end

    local shooterHead = shooter:get_hitbox_position(0)
    local myOrigin = me:get_origin()
    if not shooterHead or not myOrigin then return end

    local impact = vector(e.x, e.y, e.z)
    local lx = impact.x - shooterHead.x
    local ly = impact.y - shooterHead.y
    local lz = impact.z - shooterHead.z
    local len2 = lx*lx + ly*ly + lz*lz

    local myCheck = vector(myOrigin.x, myOrigin.y, myOrigin.z + 32)
    local dist
    if len2 == 0 then
        local dx = myCheck.x - shooterHead.x
        local dy = myCheck.y - shooterHead.y
        local dz = myCheck.z - shooterHead.z
        dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    else
        local t = ((myCheck.x - shooterHead.x)*lx + (myCheck.y - shooterHead.y)*ly + (myCheck.z - shooterHead.z)*lz) / len2
        t = math.max(0, math.min(1, t))
        local px = shooterHead.x + t*lx
        local py = shooterHead.y + t*ly
        local pz = shooterHead.z + t*lz
        local dx = myCheck.x - px
        local dy = myCheck.y - py
        local dz = myCheck.z - pz
        dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    if dist < 64 then
        utils.execute_after(0, function()
            if hit_this_tick == globals.tickcount then return end
            TriggerAntiBrute()
        end)
    end
end)

return antiaim
