local menu = require("madrilla_recode/menu")
local pui = require("gamesense/pui")
local antiaim_funcs = require("gamesense/antiaim_funcs")
local vector = require("vector")

local duckPeekAssist = pui.reference('Rage', 'Other', 'Duck peek assist')
local doubleTapEnabled, doubleTapKey = pui.reference('Rage', "Aimbot", "Double tap")
local hideShots = pui.reference("AA", "Other", "On shot anti-aim")

-- Seed the random number generator so killsays are actually random every session
math.randomseed(client.unix_time())

misc = {
    autoBuy = {
        buyCommands = {
            ["-"]      = "",
            ["scout"]  = "buy ssg08",
            ["auto"]   = "buy g3sg1; buy scar20",
            ["awp"]    = "buy awp",
            ["deagle"] = "buy deagle",
            ["armor"]  = "buy vesthelm",
            ["nades"]  = "buy molotov; buy incgrenade; buy hegrenade; buy smokegrenade"
        },
        
        OnRoundStart = function()
            if not ui.get(menu.misc.autoBuy.enable) then return end

            client.exec(misc.autoBuy.buyCommands[ui.get(menu.misc.autoBuy.primary)])
            client.exec(misc.autoBuy.buyCommands[ui.get(menu.misc.autoBuy.secondary)])

            for _, item in pairs(ui.get(menu.misc.autoBuy.equipment)) do
                client.exec(misc.autoBuy.buyCommands[item])
            end
        end
    },
    
    delayedFakeduck = {
        Run = function(cmd)
            if not ui.get(menu.misc.delayedFakeduck.enable) then
                return
            end

            doubleTapEnabled:override()
            duckPeekAssist:override({"On hotkey", 0})-- override to to a fuckass key as to not have it run

            local isEnabled = ui.get(menu.misc.delayedFakeduck.bind)
            if isEnabled then
                doubleTapEnabled:override(false)

                if not antiaim_funcs.get_double_tap() then
                    duckPeekAssist:override({"Always on", 0})
                end
            end
        end
    },

    fastLadder = {
        Run = function(cmd)
            local MOVETYPE_LADDER = 9
            if not ui.get(menu.misc.fastLadder.enable) then
                return
            end

            local localPlayer = entity.get_local_player()
            if localPlayer == nil then
                return
            end

            local moveType = entity.get_prop(localPlayer, "m_MoveType")
            if moveType ~= MOVETYPE_LADDER then
                return
            end

            if cmd.forwardmove == 0 then
                return
            end

            local ladderNormal = vector(entity.get_prop(localPlayer, "m_vecLadderNormal"))
            if ladderNormal == nil then
                return
            end

            local ladderNormalLength = math.sqrt(ladderNormal.x * ladderNormal.x + ladderNormal.y * ladderNormal.y)
            if ladderNormalLength < 0.01 then
                return -- this would mean the ladder is basically horizontal, what the fuck?
            end

            cmd.in_back      = false
            cmd.in_moveleft  = false
            cmd.in_moveright = false
            cmd.in_jump      = false

            local pitchThreshold = math.deg(math.atan2(ladderNormal.z + ladderNormalLength, ladderNormalLength - ladderNormal.z))
            local pitchSide = cmd.pitch < pitchThreshold and -1 or 1
            if cmd.forwardmove < 0 then
                pitchSide = pitchSide * -1
            end

            if pitchSide < 0 then
                cmd.in_moveleft = true
            else
                cmd.in_moveright = true
            end

            cmd.pitch = 89 * pitchSide
            cmd.yaw = math.deg(math.atan2(ladderNormal.x, -ladderNormal.y))

            cmd.in_forward  = true
            cmd.forwardmove = 0
            cmd.sidemove    = 0
        end
    },

    smartDrop = {
        dropTicks = 0,
        oldPitch = nil,
        isDropping = false,

        Run = function()
            local pitchRef = ui.reference("AA", "Anti-aimbot angles", "Pitch")
            if not ui.get(menu.misc.smartDrop.enable) then return end
            
            local pressed = ui.get(menu.misc.smartDrop.bind)
            
            if pressed and not misc.smartDrop.isDropping then
                misc.smartDrop.isDropping = true
                misc.smartDrop.dropTicks = 0
                misc.smartDrop.oldPitch = ui.get(pitchRef)
                ui.set(pitchRef, "Off")
            end
            
            if misc.smartDrop.isDropping then
                misc.smartDrop.dropTicks = misc.smartDrop.dropTicks + 1
                
                if misc.smartDrop.dropTicks == 3 then
                    client.exec("drop")
                end
                
                if misc.smartDrop.dropTicks == 6 then
                    ui.set(pitchRef, misc.smartDrop.oldPitch)
                end
                
                if misc.smartDrop.dropTicks > 6 and not pressed then
                    misc.smartDrop.isDropping = false
                end
            end
        end
    },

    dropNades = {
        state = 0,
        oldPitch = nil,

        Run = function()
            local pitchRef = ui.reference("AA", "Anti-aimbot angles", "Pitch")
            if not ui.get(menu.misc.dropNades.enable) then return end

            local pressed = ui.get(menu.misc.dropNades.bind)
            local localPlayer = entity.get_local_player()
            if not localPlayer or not entity.is_alive(localPlayer) then
                misc.dropNades.state = 0
                return
            end

            if pressed and misc.dropNades.state == 0 then
                misc.dropNades.state = 1
                misc.dropNades.oldPitch = ui.get(pitchRef)
                ui.set(pitchRef, "Off")
            end

            if misc.dropNades.state > 0 then
                local activeWeapon = entity.get_prop(localPlayer, "m_hActiveWeapon")
                if not activeWeapon then return end
                local weaponItemIndex = bit.band(entity.get_prop(activeWeapon, "m_iItemDefinitionIndex"), 0xFFFF)
                
                local has_he = false
                local has_molo = false
                for i = 0, 64 do
                    local w = entity.get_prop(localPlayer, "m_hMyWeapons", i)
                    if w ~= nil and w ~= 0 then
                        local def = bit.band(entity.get_prop(w, "m_iItemDefinitionIndex"), 0xFFFF)
                        if def == 44 then has_he = true end
                        if def == 46 or def == 48 then has_molo = true end
                    end
                end

                if misc.dropNades.state == 1 then
                    if has_he then
                        client.exec("use weapon_hegrenade")
                        if weaponItemIndex == 44 then
                            client.exec("drop")
                        end
                    else
                        misc.dropNades.state = 2
                    end
                elseif misc.dropNades.state == 2 then
                    if has_molo then
                        client.exec("use weapon_incgrenade")
                        client.exec("use weapon_molotov")
                        if weaponItemIndex == 46 or weaponItemIndex == 48 then
                            client.exec("drop")
                        end
                    else
                        misc.dropNades.state = 3
                    end
                elseif misc.dropNades.state == 3 then
                    ui.set(pitchRef, misc.dropNades.oldPitch)
                    if not pressed then
                        misc.dropNades.state = 0
                    end
                end
            end
        end
    },

    killsay = {
        phrases = {
            "madrilla recode > you",
            "sit down dog",
            "1",
            "uid issue",
            "my resolver > your fake",
            "0.22s caught you lacking",
            "hit by unleaked private madrilla recode method",
            "private lua > your pasted garbage",
            "unleaked LBY tracker doing work",
            "imagine getting resolved by a private build",
            "madrilla recode private alpha invite only",
            "stop feeding the unleaked method",
            "i'd give you the lua but it's private and unleaked",
            "you just got mathematically resolved by a private algorithm",
            "madrilla recode internal > your entire setup",
            "enjoy getting tapped by a 0-day method",
            "you're playing checkers, i'm playing with a private build",
            "0.22s state machine = you are dead",
            "cant buy this method, invite only sorry",
            "madrilla recode strictly private",
            "my anti-aim is unleaked, your anti-aim is public source",
            "another victim to the private resolver",
            "madrilla recode dev build hits different",
            "stop trying, you literally can't beat unleaked math",
            "getting tapped by a private lua, sad",
            "unleaked safepoint overrides doing the heavy lifting",
            "exclusive madrilla recode user vs public cheat fan",
            "you just witnessed a private method in action",
            "madrilla recode simply owns you",
            "this logic isn't on the forums, stay mad",
            "how does it feel losing to an invite-only lua?",
            "private algorithm just predicted your whole existence",
            "you got resolved by my LFO math",
            "my sine wave private build absolutely destroying you",
            "strictly unleashing 0-day LFO methods",
            "did my triangle wave leak? no, you just died to it",
            "my LFO didn't even try and you still died",
            "your LBY tracker caught slipping against my sine wave",
            "getting tapped by madrilla's private madrilla recode recode",
            "madrilla had the vision, madrilla perfected the execution",
            "madrilla's unleaked recode > your entire setup",
            "imagine losing to my triangle LFO math",
            "madrilla recode madrilla recode strictly private",
            "tappa klause just delivered your death",
            "merry christmas from tappa klause",
            "you just got resolved by my advanced LFO",
            "tappa klause leaving coal in your inventory",
            "breaking your LC like it's absolutely nothing",
            "my LC break is unleaked, sit down",
            "lag compensation? never heard of it",
            "madrilla recode LC > your pasted movement",
            "enjoy shooting my LC trail while i tap you",
            "tappa klause came to town just to break your LC"
        },
        
        OnPlayerDeath = function(e)
            if not ui.get(menu.misc.killsay.enable) then return end
            
            local local_player = entity.get_local_player()
            local attacker = client.userid_to_entindex(e.attacker)
            local victim = client.userid_to_entindex(e.userid)
            
            if attacker == local_player and victim ~= local_player then
                local phrase = misc.killsay.phrases[math.random(1, #misc.killsay.phrases)]
                client.exec("say " .. phrase)
            end
        end
    },

    clantag = {
        frames = {
            "m", "ma", "mad", "madr", "madri", "madril", "madrilla recode", "madrilla recode",
            "madrilla recode |", "madrilla recode | m", "madrilla recode | ma", "madrilla recode | mad",
            "madrilla recode | madr", "madrilla recode | madri", "madrilla recode | madril",
            "madrilla recode | madrill", "madrilla recode | madrilla", "madrilla recode | madrilla",
            "madrilla recode", "madrilla recode", "madrilla recode",
            "madrilla recode | madrilla", "madrilla recode | madrill", "madrilla recode | madril",
            "madrilla recode | madri", "madrilla recode | madr", "madrilla recode | mad", "madrilla recode | ma",
            "madrilla recode | m", "madrilla recode |", "madrilla recode", "madril", "madri", "madr", "mad", "ma", "m"
        },
        last_frame = "",
        Run = function()
            if not ui.get(menu.misc.clantag.enable) then 
                if misc.clantag.last_frame ~= "" then
                    client.set_clan_tag("")
                    misc.clantag.last_frame = ""
                end
                return 
            end

            local tickcount = globals.tickcount()
            local frame_idx = math.floor(tickcount / 25) % #misc.clantag.frames + 1
            local frame = misc.clantag.frames[frame_idx]

            if frame ~= misc.clantag.last_frame then
                client.set_clan_tag(frame)
                misc.clantag.last_frame = frame
            end
        end
    },

    OnRoundStart = function()
        client.delay_call(0.2, misc.autoBuy.OnRoundStart) --idk why i need to delay this in a bot match but i dont care much for fast buying
    end,

    OnSetupCommand = function(cmd)
        misc.clantag.Run()
        misc.delayedFakeduck.Run(cmd)
        misc.fastLadder.Run(cmd)
        misc.smartDrop.Run()
        misc.dropNades.Run()

        if ui.get(menu.ragebot.multiDT.enable) then
            local k1 = ui.get(menu.ragebot.multiDT.key1)
            local k2 = ui.get(menu.ragebot.multiDT.key2)
            local k3 = ui.get(menu.ragebot.multiDT.key3)
            
            if k1 or k2 or k3 then
                doubleTapEnabled:override(true)
            else
                doubleTapEnabled:override(false)
            end
        else
            doubleTapEnabled:override()
        end
        if ui.get(menu.ragebot.ragebotHelper.forceHideshotsSniper) then
            local localPlayer = entity.get_local_player()
            if localPlayer and entity.is_alive(localPlayer) then
                local weapon = entity.get_player_weapon(localPlayer)
                local weaponDefIndex = weapon and bit.band(entity.get_prop(weapon, "m_iItemDefinitionIndex") or 0, 0xFFFF) or 0
                
                if weaponDefIndex == 40 or weaponDefIndex == 9 then
                    local flags = entity.get_prop(localPlayer, "m_fFlags") or 0
                    local onGround = bit.band(flags, 1) == 1
                    local inDuck = cmd.in_duck == 1
                    
                    if onGround and inDuck then
                        if hideShots then hideShots:override(true) end
                        if doubleTapEnabled then doubleTapEnabled:override(false) end
                    else
                        if hideShots then hideShots:override() end
                        -- We do not override doubleTapEnabled here because multiDT handles it above
                    end
                else
                    if hideShots then hideShots:override() end
                end
            else
                if hideShots then hideShots:override() end
            end
        else
            if hideShots then hideShots:override() end
        end
    end
}

client.set_event_callback("shutdown", function()
    local pitchRef = ui.reference("AA", "Anti-aimbot angles", "Pitch")
    if misc.smartDrop and misc.smartDrop.isDropping and misc.smartDrop.oldPitch ~= nil then
        ui.set(pitchRef, misc.smartDrop.oldPitch)
    end
    if misc.dropNades and misc.dropNades.state > 0 and misc.dropNades.oldPitch ~= nil then
        ui.set(pitchRef, misc.dropNades.oldPitch)
    end
end)

return misc