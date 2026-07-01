local menu = require("madrilla_recode/menu")

math.randomseed(common.get_unixtime())

local misc = {
    autoBuy = {
        buyCommands = {
            ["-"]      = "",
            ["scout"]  = "buy ssg08",
            ["auto"]   = "buy g3sg1; buy scar20",
            ["awp"]    = "buy awp",
            ["deagle"] = "buy deagle",
            ["armor"]  = "buy vesthelm",
            ["nades"]  = "buy molotov; buy incgrenade; buy hegrenade; buy smokegrenade",
        },

        OnRoundStart = function()
            if not menu.misc.autoBuy.enable:get() then return end
            utils.console_exec(misc.autoBuy.buyCommands[menu.misc.autoBuy.primary:get()])
            utils.console_exec(misc.autoBuy.buyCommands[menu.misc.autoBuy.secondary:get()])
            for _, item in pairs(menu.misc.autoBuy.equipment:get()) do
                utils.console_exec(misc.autoBuy.buyCommands[item])
            end
        end,
    },

    fastLadder = {
        Run = function(cmd)
            local MOVETYPE_LADDER = 9
            if not menu.misc.fastLadder.enable:get() then return end

            local localPlayer = entity.get_local_player()
            if not localPlayer then return end

            local moveType = localPlayer.m_MoveType
            if moveType ~= MOVETYPE_LADDER then return end
            if cmd.forwardmove == 0 then return end

            local ladderNormal = localPlayer.m_vecLadderNormal
            if not ladderNormal then return end

            local ladderNormalLength = math.sqrt(ladderNormal.x * ladderNormal.x + ladderNormal.y * ladderNormal.y)
            if ladderNormalLength < 0.01 then return end

            local pitchThreshold = math.deg(math.atan2(ladderNormal.z + ladderNormalLength, ladderNormalLength - ladderNormal.z))
            local pitchSide = cmd.view_angles.x < pitchThreshold and -1 or 1
            if cmd.forwardmove < 0 then pitchSide = pitchSide * -1 end

            cmd.view_angles.x = 89 * pitchSide
            cmd.view_angles.y = math.deg(math.atan2(ladderNormal.x, -ladderNormal.y))
            cmd.forwardmove = 450
            cmd.sidemove = 0
        end,
    },

    smartDrop = {
        dropTicks = 0,
        oldPitch = nil,
        isDropping = false,

        Run = function(cmd)
            if not menu.misc.smartDrop.enable:get() then return end

            local pressed = menu.misc.smartDrop.bind:get()

            if pressed and not misc.smartDrop.isDropping then
                misc.smartDrop.isDropping = true
                misc.smartDrop.dropTicks = 0
                misc.smartDrop.oldPitch = cmd.view_angles.x
                cmd.view_angles.x = 0
            end

            if misc.smartDrop.isDropping then
                misc.smartDrop.dropTicks = misc.smartDrop.dropTicks + 1

                if misc.smartDrop.dropTicks == 3 then
                    utils.console_exec("drop")
                end

                if misc.smartDrop.dropTicks == 6 and misc.smartDrop.oldPitch ~= nil then
                    cmd.view_angles.x = misc.smartDrop.oldPitch
                end

                if misc.smartDrop.dropTicks > 6 and not pressed then
                    misc.smartDrop.isDropping = false
                end
            end
        end,
    },

    dropNades = {
        state = 0,
        oldPitch = nil,

        Run = function(cmd)
            if not menu.misc.dropNades.enable:get() then return end

            local pressed = menu.misc.dropNades.bind:get()
            local localPlayer = entity.get_local_player()
            if not localPlayer or not localPlayer:is_alive() then
                misc.dropNades.state = 0
                return
            end

            if pressed and misc.dropNades.state == 0 then
                misc.dropNades.state = 1
                misc.dropNades.oldPitch = cmd.view_angles.x
                cmd.view_angles.x = 0
            end

            if misc.dropNades.state > 0 then
                local activeWeapon = localPlayer:get_player_weapon()
                if not activeWeapon then return end
                local weaponIndex = bit.band(activeWeapon.m_iItemDefinitionIndex or 0, 0xFFFF)

                local has_he = false
                local has_molo = false
                local allWeapons = localPlayer:get_player_weapon(true)
                if type(allWeapons) == "table" then
                    for _, w in ipairs(allWeapons) do
                        local def = bit.band(w.m_iItemDefinitionIndex or 0, 0xFFFF)
                        if def == 44 then has_he = true end
                        if def == 46 or def == 48 then has_molo = true end
                    end
                end

                if misc.dropNades.state == 1 then
                    if has_he then
                        utils.console_exec("use weapon_hegrenade")
                        if weaponIndex == 44 then utils.console_exec("drop") end
                    else
                        misc.dropNades.state = 2
                    end
                elseif misc.dropNades.state == 2 then
                    if has_molo then
                        utils.console_exec("use weapon_incgrenade; use weapon_molotov")
                        if weaponIndex == 46 or weaponIndex == 48 then
                            utils.console_exec("drop")
                        end
                    else
                        misc.dropNades.state = 3
                    end
                elseif misc.dropNades.state == 3 then
                    if misc.dropNades.oldPitch ~= nil then
                        cmd.view_angles.x = misc.dropNades.oldPitch
                    end
                    if not pressed then misc.dropNades.state = 0 end
                end
            end
        end,
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
            "id give you the lua but its private and unleaked",
            "you just got mathematically resolved by a private algorithm",
            "madrilla recode internal > your entire setup",
            "enjoy getting tapped by a 0-day method",
            "youre playing checkers im playing with a private build",
            "0.22s state machine = you are dead",
            "cant buy this method invite only sorry",
            "madrilla recode strictly private",
            "my anti-aim is unleaked your anti-aim is public source",
            "another victim to the private resolver",
            "madrilla recode dev build hits different",
            "stop trying you literally cant beat unleaked math",
            "getting tapped by a private lua sad",
            "unleaked safepoint overrides doing the heavy lifting",
            "exclusive madrilla recode user vs public cheat fan",
            "you just witnessed a private method in action",
            "madrilla recode simply owns you",
            "this logic isnt on the forums stay mad",
            "how does it feel losing to an invite-only lua",
            "private algorithm just predicted your whole existence",
            "you got resolved by my LFO math",
            "my sine wave private build absolutely destroying you",
            "strictly unleashing 0-day LFO methods",
            "did my triangle wave leak no you just died to it",
            "my LFO didnt even try and you still died",
            "your LBY tracker caught slipping against my sine wave",
            "getting tapped by madrillas private madrilla recode recode",
            "madrilla had the vision madrilla perfected the execution",
            "tappa klause just delivered your death",
            "merry christmas from tappa klause",
            "you just got resolved by my advanced LFO",
            "tappa klause leaving coal in your inventory",
            "breaking your LC like its absolutely nothing",
            "my LC break is unleaked sit down",
            "lag compensation never heard of it",
            "madrilla recode LC > your pasted movement",
            "enjoy shooting my LC trail while i tap you",
            "tappa klause came to town just to break your LC",
        },

        OnPlayerDeath = function(e)
            if not menu.misc.killsay.enable:get() then return end
            local local_player = entity.get_local_player()
            local attacker = entity.get(e.attacker, true)
            local victim = entity.get(e.userid, true)
            if attacker == local_player and victim ~= local_player then
                local phrase = misc.killsay.phrases[math.random(1, #misc.killsay.phrases)]
                utils.console_exec("say " .. phrase)
            end
        end,
    },

    clantag = {
        frames = {
            "m", "ma", "mad", "madr", "madri", "madril", "madrilla", "madrilla",
            "madrilla |", "madrilla | m", "madrilla | ma", "madrilla | mad",
            "madrilla | madr", "madrilla | madri", "madrilla | madril",
            "madrilla | madrill", "madrilla | madrilla", "madrilla | madrilla",
            "madrilla recode", "madrilla recode", "madrilla recode",
            "madrilla | madrilla", "madrilla | madrill", "madrilla | madril",
            "madrilla | madri", "madrilla | madr", "madrilla | mad", "madrilla | ma",
            "madrilla | m", "madrilla |", "madrilla", "madril", "madri", "madr", "mad", "ma", "m"
        },
        last_frame = "",

        Run = function()
            if not menu.misc.clantag.enable:get() then
                if misc.clantag.last_frame ~= "" then
                    common.set_clan_tag("")
                    misc.clantag.last_frame = ""
                end
                return
            end

            local tickcount = globals.tickcount
            local frame_idx = math.floor(tickcount / 25) % #misc.clantag.frames + 1
            local frame = misc.clantag.frames[frame_idx]

            if frame ~= misc.clantag.last_frame then
                common.set_clan_tag(frame)
                misc.clantag.last_frame = frame
            end
        end,
    },

    OnRoundStart = function()
        utils.execute_after(0.2, misc.autoBuy.OnRoundStart)
    end,

    OnSetupCommand = function(cmd)
        misc.clantag.Run()
        misc.fastLadder.Run(cmd)
        misc.smartDrop.Run(cmd)
        misc.dropNades.Run(cmd)
    end,
}

events.player_death:set(function(e)
    misc.killsay.OnPlayerDeath(e)
end)

events.shutdown:set(function()
    common.set_clan_tag("")
end)

return misc
