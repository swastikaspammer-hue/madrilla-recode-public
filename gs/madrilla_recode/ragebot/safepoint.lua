local playerData = {}

local function SetupPlayerData(player)
    local pitch, yaw = entity.get_prop(player, "m_angEyeAngles")
    local currentPlayerData = {
        lastYaw = yaw, 
        jitterAmount = 0,
        averageJitterAmount = 0,
        misses = 0
    }

    playerData[player] = currentPlayerData
end

local function UpdatePlayerData(player)
    local pitch, yaw = entity.get_prop(player, "m_angEyeAngles")
    if yaw ~= nil and playerData[player].lastYaw ~= nil then
        playerData[player].jitterAmount = math.abs(playerData[player].lastYaw - yaw)
        playerData[player].averageJitterAmount = (playerData[player].averageJitterAmount + playerData[player].jitterAmount) / 2
        playerData[player].lastYaw = yaw
    end
end

local function ClearPlayerData()
    for data in pairs(playerData) do
      playerData[data] = nil
    end
end

client.set_event_callback("aim_miss", function(e)
    if e.target and playerData[e.target] then
        playerData[e.target].misses = playerData[e.target].misses + 1
    end
end)

client.set_event_callback("aim_hit", function(e)
    if e.target and playerData[e.target] then
        playerData[e.target].misses = 0
    end
end)

safepoint = {
    OnSetupCommand = function(cmd)
        if not ui.get(menu.ragebot.autoSafepoint.enable) then
            for entityIndex = 1, globals.maxplayers() do
                plist.set(entityIndex, "Override safe point", "-")
            end

            return
        end

        local safepointLow, safepointHigh, safepointLethal, safepointAir, safepointMiss
        for _, item in pairs(ui.get(menu.ragebot.autoSafepoint.options)) do
            if item == "low jitter" then
                safepointLow = true
            elseif item == "high jitter" then
                safepointHigh = true
            elseif item == "lethal" then
                safepointLethal = true
            elseif item == "in air" then
                safepointAir = true
            elseif item == "on miss" then
                safepointMiss = true
            end
        end

        for entityIndex = 1, globals.maxplayers() do
            plist.set(entityIndex, "Override safe point", "Off")

            if not entity.is_dormant(entityIndex) and entity.is_alive(entityIndex) then
               local data = playerData[entityIndex]
                if not data then
                    SetupPlayerData(entityIndex)
                    goto continue
                end

                UpdatePlayerData(entityIndex)

                local lowJitter = data.averageJitterAmount < 30
                local highJitter = data.averageJitterAmount > 30

                local health = entity.get_prop(entityIndex, "m_iHealth") or 100
                local flags = entity.get_prop(entityIndex, "m_fFlags") or 0
                local inAir = bit.band(flags, 1) == 0 -- FL_ONGROUND is 1
                
                local shouldSafepoint = false

                if safepointLow and lowJitter then
                    shouldSafepoint = true
                end
                if safepointHigh and highJitter then
                    shouldSafepoint = true
                end
                
                -- localPlayer active weapon damage could be checked, but for simplicity, below 40 HP is generally lethal
                if safepointLethal and health <= 40 then
                    shouldSafepoint = true
                end
                
                if safepointAir and inAir then
                    shouldSafepoint = true
                end
                
                if safepointMiss and data.misses > 0 then
                    shouldSafepoint = true
                end

                if shouldSafepoint then
                    plist.set(entityIndex, "Override safe point", "On")
                end
                
                ::continue::
            end
        end
    end,

    OnRoundStart = function()
        ClearPlayerData()
    end
}

return safepoint