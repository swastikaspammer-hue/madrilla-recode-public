local menu = require("madrilla_recode/menu")
local named_pipes = require("gamesense/named_pipes")
local panorama = panorama.open()
local GameStateAPI = panorama.GameStateAPI
local LobbyAPI = panorama.LobbyAPI

local discord = {
    pipe = nil,
    client_id = "774277207451107398",
    connected = false,
    last_update = 0,
    update_interval = 5,
    start_time = 0
}

local map_names = {
    ["de_mirage"] = "Mirage",
    ["de_dust2"] = "Dust II",
    ["de_inferno"] = "Inferno",
    ["de_overpass"] = "Overpass",
    ["de_vertigo"] = "Vertigo",
    ["de_nuke"] = "Nuke",
    ["de_train"] = "Train",
    ["de_ancient"] = "Ancient",
    ["de_anubis"] = "Anubis",
    ["de_cache"] = "Cache",
    ["de_cbble"] = "Cobblestone"
}

local function pack_int32(n)
    return string.char(bit.band(n, 0xFF), bit.band(bit.rshift(n, 8), 0xFF), bit.band(bit.rshift(n, 16), 0xFF), bit.band(bit.rshift(n, 24), 0xFF))
end

local function send_discord(opcode, payload)
    if not discord.pipe then return false end
    local data = pack_int32(opcode) .. pack_int32(#payload) .. payload
    local success, err = pcall(discord.pipe.write, discord.pipe, data)
    if not success then
        discord.connected = false
        discord.pipe = nil
    end
    return success
end

function discord.connect()
    if discord.connected then return true end

    for i=0, 9 do
        local success, pipe = pcall(named_pipes.open_pipe, "\\\\?\\pipe\\discord-ipc-" .. i)
        if success and pipe then
            discord.pipe = pipe
            -- Send handshake (opcode 0)
            local handshake = '{"v":1,"client_id":"' .. discord.client_id .. '"}'
            if send_discord(0, handshake) then
                discord.connected = true
                local current_time = client.unix_time and client.unix_time() or math.floor(panorama.loadstring("return Date.now()/1000")())
                discord.start_time = current_time
                return true
            end
        end
    end
    return false
end

function discord.disconnect()
    if discord.pipe then
        -- Send close operation (opcode 2)
        send_discord(2, '{"v":1,"client_id":"' .. discord.client_id .. '"}')
        pcall(named_pipes.close_pipe, discord.pipe)
        discord.pipe = nil
    end
    discord.connected = false
end

function discord.update_activity()
    if not discord.connected then return end

    local state = "In Main Menu"
    local details = "Idle"
    local large_image = "csgo-logo2"
    local large_text = "Counter-Strike: Global Offensive"

    if GameStateAPI.IsConnectedOrConnectingToServer() then
        local map = GameStateAPI.GetMapName()
        if map and map ~= "" then
            state = "In Game"
            details = "Playing " .. (map_names[map] or map)
            large_image = "map_" .. map
            large_text = map_names[map] or map
        end
    end

    local payload = string.format([[
    {
        "cmd": "SET_ACTIVITY",
        "args": {
            "pid": 4,
            "activity": {
                "state": "%s",
                "details": "%s",
                "timestamps": {
                    "start": %d000
                },
                "assets": {
                    "large_image": "%s",
                    "large_text": "%s",
                    "small_image": "gamesense",
                    "small_text": "gamesense.pub"
                }
            }
        },
        "nonce": "1"
    }
    ]], state, details, discord.start_time, large_image, large_text)

    send_discord(1, payload)
end

function discord.OnPaintUI()
    local is_enabled = ui.get(menu.misc.discordRpc.enable)
    
    if not is_enabled then
        if discord.connected then
            discord.disconnect()
        end
        return
    end

    if not discord.connected then
        if globals.realtime() - discord.last_update > 5 then
            discord.connect()
            discord.last_update = globals.realtime()
        end
    else
        -- Update activity every `update_interval` seconds
        if globals.realtime() - discord.last_update > discord.update_interval then
            discord.update_activity()
            discord.last_update = globals.realtime()
        end
    end
end

function discord.OnShutdown()
    discord.disconnect()
end

return discord
