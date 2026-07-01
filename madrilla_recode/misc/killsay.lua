local menu = require("madrilla_recode/menu")

local trashTalks = {
    air = {
        "nice jump %s, too bad my safepoint shot you out of the air.",
        "stop jumping %s, my resolver doesn't care.",
        "%s thinks they are a bird, but they just got 1-tapped."
    },
    lethal = {
        "didn't even need to try for the head, %s you were basically dead already.",
        "safepoint on lethal is just too easy %s.",
        "%s running around on 1 HP like that's gonna save them."
    },
    miss_fallback = {
        "my resolver missed once, so it safepointed your dump %s.",
        "%s thought their desync was good, but my miss-fallback just bodied you.",
        "nice angle %s, but my fallback resolver still won."
    },
    default = {
        "sit down %s.",
        "1, %s",
        "%s, completely destroyed by madrilla recode."
    }
}

local function GetTrashTalk(context, playerName)
    local lines = trashTalks[context] or trashTalks.default
    local line = lines[math.random(#lines)]
    return string.format(line, playerName)
end

local killsay = {}

client.set_event_callback("player_death", function(e)
    if not ui.get(menu.misc.killsay.enable) then return end

    local attackerIndex = client.userid_to_entindex(e.attacker)
    local victimIndex = client.userid_to_entindex(e.userid)
    local localPlayer = entity.get_local_player()

    if attackerIndex == localPlayer and victimIndex ~= localPlayer then
        local playerName = entity.get_player_name(victimIndex)
        
        -- try to determine context
        local context = "default"
        
        local flags = entity.get_prop(victimIndex, "m_fFlags") or 0
        local inAir = bit.band(flags, 1) == 0

        -- We could hook into resolver data here, but reading victim state is reliable
        if inAir then
            context = "air"
        end

        local msg = GetTrashTalk(context, playerName)
        client.exec("say " .. msg)
    end
end)

return killsay
