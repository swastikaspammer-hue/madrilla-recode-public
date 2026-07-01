local menu = require("madrilla_recode/menu")
local vector = require("vector")

local ref_ping_spike, ref_ping_spike_amt = ui.reference("MISC", "Miscellaneous", "Ping spike")

local fakeping = {
    OnSetupCommand = function(cmd)
        if not ui.get(menu.misc.fakePing.enable) then
            if ui.get(ref_ping_spike) then
                ui.set(ref_ping_spike, false)
            end
            return
        end

        local localPlayer = entity.get_local_player()
        if not localPlayer or not entity.is_alive(localPlayer) then
            return
        end

        local vel = {entity.get_prop(localPlayer, "m_vecVelocity")}
        if not vel[1] or not vel[2] then return end
        
        local speed = math.sqrt(vel[1]^2 + vel[2]^2)

        -- If we aren't moving fast enough to peek, don't ping spike
        if speed < 100 then
            if ui.get(ref_ping_spike) then
                ui.set(ref_ping_spike, false)
            end
            return
        end

        -- trace ray forward based on velocity to detect upcoming corners
        local eyePos = vector(client.eye_position())
        
        local dirX, dirY = vel[1] / speed, vel[2] / speed
        local lookAheadDist = 200 -- 200 units ahead
        local targetPos = eyePos + vector(dirX * lookAheadDist, dirY * lookAheadDist, 0)
        
        local fraction, ent = client.trace_line(localPlayer, eyePos.x, eyePos.y, eyePos.z, targetPos.x, targetPos.y, targetPos.z)
        
        -- if we are moving towards a wall/corner (fraction < 1.0)
        if fraction < 1.0 then
            ui.set(ref_ping_spike, true)
            ui.set(ref_ping_spike_amt, ui.get(menu.misc.fakePing.amount))
        else
            ui.set(ref_ping_spike, false)
        end
    end
}

return fakeping
