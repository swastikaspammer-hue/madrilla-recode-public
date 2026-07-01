local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function enc_b64(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function dec_b64(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b64chars:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function get_config_table(menu_ref)
    local config = {}
    local function traverse(tbl, path)
        for k, v in pairs(tbl) do
            if type(v) == "table" and v.get and type(v.get) == "function" then
                local ok, val = pcall(function() return v:get() end)
                if ok and val ~= nil then
                    config[path .. k] = val
                end
            elseif type(v) == "table" and k ~= "states" then
                traverse(v, path .. k .. ".")
            end
        end
    end
    traverse(menu_ref, "")
    if menu_ref.antiaim and menu_ref.antiaim.states then
        for state_name, state_tbl in pairs(menu_ref.antiaim.states) do
            traverse(state_tbl, "antiaim.states." .. state_name .. ".")
        end
    end
    return config
end

local function load_config_table(menu_ref, config)
    local function traverse_import(tbl, path)
        for k, v in pairs(tbl) do
            if type(v) == "table" and v.set and type(v.set) == "function" then
                local val = config[path .. k]
                if val ~= nil then
                    pcall(function() v:set(val) end)
                end
            elseif type(v) == "table" and k ~= "states" then
                traverse_import(v, path .. k .. ".")
            end
        end
    end
    traverse_import(menu_ref, "")
    if menu_ref.antiaim and menu_ref.antiaim.states then
        for state_name, state_tbl in pairs(menu_ref.antiaim.states) do
            traverse_import(state_tbl, "antiaim.states." .. state_name .. ".")
        end
    end
end

local function serialize_config(cfg)
    local parts = {}
    for k, v in pairs(cfg) do
        local vt = type(v)
        if vt == "boolean" then
            table.insert(parts, k .. ":b:" .. tostring(v))
        elseif vt == "number" then
            table.insert(parts, k .. ":n:" .. tostring(v))
        elseif vt == "string" then
            table.insert(parts, k .. ":s:" .. v:gsub(";", "_"))
        end
    end
    return "mr_nl_" .. enc_b64(table.concat(parts, ";"))
end

local function deserialize_config(str)
    if not str:find("^mr_nl_") then return nil end
    local cfg = {}
    for item in dec_b64(str:sub(7)):gmatch("[^;]+") do
        local k, t, val = item:match("^([^:]+):([^:]+):(.*)$")
        if k and t then
            if t == "b" then cfg[k] = (val == "true")
            elseif t == "n" then cfg[k] = tonumber(val)
            elseif t == "s" then cfg[k] = val
            end
        end
    end
    return cfg
end

local menu = {}

do
    local g_resolver  = ui.create("Ragebot", "Resolver")
    local g_safepoint = ui.create("Ragebot", "Auto Safepoint")
    local g_helper    = ui.create("Ragebot", "Ragebot Helper")
    local g_multidt   = ui.create("Ragebot", "Multi-Key Double Tap")

    menu.ragebot = {
        resolver = {
            enable            = g_resolver:switch("Enable Resolver"),
            override          = g_resolver:switch("Force bruteforce (debug)"),
            log               = g_resolver:switch("Log resolver actions"),
            freestanding      = g_resolver:switch("Freestanding trace fallback"),
            freestandingWidth = g_resolver:slider("Freestanding trace width", 20, 80, 40),
        },
        autoSafepoint = {
            enable  = g_safepoint:switch("Auto Safepoint"),
            options = g_safepoint:selectable("Options", "low jitter", "high jitter", "lethal", "in air", "on miss"),
        },
        ragebotHelper = {
            enable               = g_helper:switch("Ragebot Helper"),
            bind                 = g_helper:hotkey("Helper Key"),
            avoidUnsafeHitboxes  = g_helper:switch("Avoid unsafe hitboxes"),
            maxTargetTime        = g_helper:slider("Max target time", 0, 5, 4),
            hitChance            = g_helper:slider("Hitchance", 1, 100, 80),
            minDamage            = g_helper:slider("Min damage", 1, 100, 30),
            forceHideshotsSniper = g_helper:switch("Force hideshots on sniper crouch"),
        },
        multiDT = {
            enable = g_multidt:switch("Multi-key double tap"),
            key1   = g_multidt:hotkey("Double tap key 1"),
            key2   = g_multidt:hotkey("Double tap key 2"),
            key3   = g_multidt:hotkey("Double tap key 3"),
        },
    }
end

do
    local g_general = ui.create("Anti-Aim", "General")
    local g_antibs  = ui.create("Anti-Aim", "Anti-Backstab")
    local g_invert  = ui.create("Anti-Aim", "Inversion")
    local g_antib   = ui.create("Anti-Aim", "Anti-Bruteforce")
    local g_manual  = ui.create("Anti-Aim", "Manual Direction")

    menu.antiaim = {
        enable             = g_general:switch("Enable Custom AA"),
        lbyBreaker         = g_general:switch("0.22s LBY Breaker"),
        stateCombo         = g_general:combo("State", "global", "standing", "moving",
                                              "slow walking", "crouched", "crouch moving",
                                              "air crouched", "air", "fakeducking", "defensive"),
        enableAntiBackstab = g_antibs:switch("Anti-Backstab"),
        invertOnShot       = g_invert:switch("Invert desync on shot"),
        invertOnHit        = g_invert:switch("Invert desync on hit"),
        antiBrute          = g_antib:switch("Anti-Bruteforce"),
        antiBruteModes     = g_antib:selectable("Anti-Brute modes", "On Hit", "On Miss"),
        antiBruteAction    = g_antib:combo("Anti-Brute action", "Invert Side", "Randomize", "Cycle 3-way"),
        manualLeft         = g_manual:hotkey("Manual Left"),
        manualRight        = g_manual:hotkey("Manual Right"),
        manualForward      = g_manual:hotkey("Manual Forward"),
        manualBack         = g_manual:hotkey("Manual Back"),
        states             = {},
    }
end

do
    local state_names = {
        "global", "standing", "moving", "slow walking", "crouched",
        "crouch moving", "air crouched", "air", "fakeducking", "defensive"
    }

    local g_builder = ui.create("Anti-Aim", "Builder")

    for _, name in ipairs(state_names) do
        local state = { name = name }

        if name ~= "global" then
            state.overrideGlobal = g_builder:switch("[" .. name .. "] Override global")
        end
        if name ~= "defensive" then
            state.allowDefensive = g_builder:switch("[" .. name .. "] Allow defensive")
            state.forceDefensive = g_builder:switch("[" .. name .. "] Force defensive")
        end

        state.pitchOffset         = g_builder:slider("[" .. name .. "] Pitch offset", -89, 89, 0)
        state.yawOffset           = g_builder:slider("[" .. name .. "] Yaw offset", -180, 180, 0)
        state.yawMode             = g_builder:combo("[" .. name .. "] Yaw mode", "static", "jitter", "delayed jitter", "random", "spin", "lfo", "switch", "3-way", "5-way")
        state.yawJitterDelayMin   = g_builder:slider("[" .. name .. "] Yaw jitter delay min", 1, 10, 3)
        state.yawJitterDelayMax   = g_builder:slider("[" .. name .. "] Yaw jitter delay max", 1, 10, 9)
        state.yawLfoShape         = g_builder:combo("[" .. name .. "] Yaw LFO shape", "sine", "triangle", "pulse")
        state.yawLfoSpeed         = g_builder:slider("[" .. name .. "] Yaw LFO speed", 1, 100, 50)
        state.yawLfoVelocityScale = g_builder:switch("[" .. name .. "] Scale yaw LFO by velocity")
        state.yawLfoRange         = g_builder:slider("[" .. name .. "] Yaw LFO range", 0, 180, 90)
        state.yawSwitchDelay      = g_builder:slider("[" .. name .. "] Yaw switch delay (ticks)", 1, 100, 30)
        state.bodyYawOffset           = g_builder:slider("[" .. name .. "] Body yaw offset", -180, 180, 60)
        state.bodyYawMode             = g_builder:combo("[" .. name .. "] Body yaw mode", "static", "jitter", "delayed jitter", "random", "lfo")
        state.bodyYawJitterDelayMin   = g_builder:slider("[" .. name .. "] Body yaw jitter delay min", 1, 10, 3)
        state.bodyYawJitterDelayMax   = g_builder:slider("[" .. name .. "] Body yaw jitter delay max", 1, 10, 9)
        state.bodyYawLfoShape         = g_builder:combo("[" .. name .. "] Body yaw LFO shape", "sine", "triangle", "pulse")
        state.bodyYawLfoSpeed         = g_builder:slider("[" .. name .. "] Body yaw LFO speed", 1, 100, 50)
        state.bodyYawLfoVelocityScale = g_builder:switch("[" .. name .. "] Scale body yaw LFO by velocity")
        state.bodyYawLfoRange         = g_builder:slider("[" .. name .. "] Body yaw LFO range", 0, 180, 60)
        state.staticPeek              = g_builder:switch("[" .. name .. "] Static peek on hit")
        state.fakeBreaker             = g_builder:switch("[" .. name .. "] Extended desync")
        state.extendFake              = g_builder:switch("[" .. name .. "] Extend fake")

        menu.antiaim.states[name] = state
    end

    events.render:set(function()
        local current_state = menu.antiaim.stateCombo:get()
        local custom_aa_enabled = menu.antiaim.enable:get()
        
        for name, state in pairs(menu.antiaim.states) do
            local is_active = (name == current_state) and custom_aa_enabled

            if state.overrideGlobal then state.overrideGlobal:visibility(is_active) end
            
            local show_settings = is_active
            if name ~= "global" and state.overrideGlobal then
                show_settings = is_active and state.overrideGlobal:get()
            end

            if state.allowDefensive then state.allowDefensive:visibility(show_settings) end
            if state.forceDefensive then state.forceDefensive:visibility(show_settings) end

            state.pitchOffset:visibility(show_settings)
            state.yawOffset:visibility(show_settings)
            state.yawMode:visibility(show_settings)
            
            local y_mode = state.yawMode:get()
            local show_y_jitter = show_settings and (y_mode == 2 or y_mode == 3)
            local show_y_lfo    = show_settings and (y_mode == 6)
            local show_y_switch = show_settings and (y_mode == 7)

            state.yawJitterDelayMin:visibility(show_y_jitter)
            state.yawJitterDelayMax:visibility(show_y_jitter)
            state.yawLfoShape:visibility(show_y_lfo)
            state.yawLfoSpeed:visibility(show_y_lfo)
            state.yawLfoVelocityScale:visibility(show_y_lfo)
            state.yawLfoRange:visibility(show_y_lfo)
            state.yawSwitchDelay:visibility(show_y_switch)

            state.bodyYawOffset:visibility(show_settings)
            state.bodyYawMode:visibility(show_settings)

            local by_mode = state.bodyYawMode:get()
            local show_by_jitter = show_settings and (by_mode == 2 or by_mode == 3)
            local show_by_lfo    = show_settings and (by_mode == 5)

            state.bodyYawJitterDelayMin:visibility(show_by_jitter)
            state.bodyYawJitterDelayMax:visibility(show_by_jitter)
            state.bodyYawLfoShape:visibility(show_by_lfo)
            state.bodyYawLfoSpeed:visibility(show_by_lfo)
            state.bodyYawLfoVelocityScale:visibility(show_by_lfo)
            state.bodyYawLfoRange:visibility(show_by_lfo)

            state.staticPeek:visibility(show_settings)
            state.fakeBreaker:visibility(show_settings)
            state.extendFake:visibility(show_settings)
        end
    end)
end

do
    local g_weather = ui.create("Visuals", "Weather")
    local g_grenade = ui.create("Visuals", "Grenade ESP")
    local g_viewmdl = ui.create("Visuals", "Viewmodel")
    local g_anim    = ui.create("Visuals", "Animation Breaker")
    local g_aspect  = ui.create("Visuals", "Aspect Ratio")
    local g_tp      = ui.create("Visuals", "Third Person")

    menu.visuals = {
        weather = {
            enable            = g_weather:switch("Weather effects"),
            precipitationType = g_weather:combo("Type", "none", "rain", "snow",
                                                 "particle rain", "particle snow", "particle ash"),
        },
        grenadeESP = {
            enable   = g_grenade:switch("Grenade inventory ESP"),
            color    = g_grenade:color_picker("Color", color(255, 255, 255, 255)),
            position = g_grenade:combo("Position", "Right", "Left", "Top", "Bottom"),
            scale    = g_grenade:slider("Icon scale", 6, 10, 8),
        },
        viewModelChanger = {
            enable = g_viewmdl:switch("Viewmodel changer"),
            fov    = g_viewmdl:slider("FOV", 30, 120, 68),
            x      = g_viewmdl:slider("X", -20, 20, 0),
            y      = g_viewmdl:slider("Y", -20, 20, 0),
            z      = g_viewmdl:slider("Z", -20, 20, 0),
        },
        animBreaker = {
            enable  = g_anim:switch("Animation breaker"),
            options = g_anim:selectable("Options", "Moonwalk (Slide)", "Static Legs in Air", "0 Pitch on Land"),
        },
        aspectRatioChanger = {
            enable      = g_aspect:switch("Aspect ratio changer"),
            aspectRatio = g_aspect:slider("Aspect ratio x100", 30, 300, 133),
        },
        thirdPersonChanger = {
            enable   = g_tp:switch("Third person changer"),
            distance = g_tp:slider("Distance", 25, 200, 100),
        },
    }
end

do
    local g_killfeed = ui.create("HUD", "Custom Killfeed")
    local g_floatdmg = ui.create("HUD", "Floating Damage")
    local g_logs     = ui.create("HUD", "Logs")

    menu.hud = {
        customKillfeed = {
            enable         = g_killfeed:switch("Custom killfeed"),
            advanced       = g_killfeed:switch("Advanced colors"),
            size           = g_killfeed:slider("Size", 10, 30, 16),
            bg_active      = g_killfeed:color_picker("Active background", color(30, 30, 30, 200)),
            bg_inactive    = g_killfeed:color_picker("Inactive background", color(15, 15, 15, 200)),
            attacker_color = g_killfeed:color_picker("Attacker color", color(255, 255, 255, 255)),
            attacked_color = g_killfeed:color_picker("Attacked color", color(255, 50, 50, 255)),
            weapon_color   = g_killfeed:color_picker("Weapon color", color(255, 255, 255, 255)),
            headshot_color = g_killfeed:color_picker("Headshot color", color(255, 210, 50, 255)),
        },
        floatingDamage = {
            enable   = g_floatdmg:switch("3D Floating damage"),
            color    = g_floatdmg:color_picker("Color", color(255, 69, 69, 255)),
            duration = g_floatdmg:slider("Duration (s)", 1, 5, 2),
        },
        logs = {
            options   = g_logs:selectable("Logs", "console", "hitlog indicator"),
            logOnshot = g_logs:switch("Log onshot status"),
        },
    }
end

do
    local g_clantag = ui.create("Misc", "Clantag")
    local g_autobuy = ui.create("Misc", "Auto Buy")
    local g_move    = ui.create("Misc", "Movement")
    local g_chat    = ui.create("Misc", "Chat")
    local g_servers = ui.create("Misc", "Servers")

    menu.misc = {
        clantag = {
            enable = g_clantag:switch("Animated clantag"),
        },
        autoBuy = {
            enable    = g_autobuy:switch("Auto buy"),
            primary   = g_autobuy:combo("Primary", "-", "scout", "auto", "awp"),
            secondary = g_autobuy:combo("Secondary", "-", "deagle"),
            equipment = g_autobuy:selectable("Equipment", "armor", "nades"),
        },
        fastLadder = {
            enable = g_move:switch("Fast ladder"),
        },
        smartDrop = {
            enable = g_move:switch("Smart drop (fixes AA drop)"),
            bind   = g_move:hotkey("Smart drop key"),
        },
        dropNades = {
            enable = g_move:switch("Drop nades"),
            bind   = g_move:hotkey("Drop nades key"),
        },
        killsay = {
            enable = g_chat:switch("Smart killsay"),
        },
        serverJoiner = {
            join2x2 = g_servers:button("Join 2x2 Server", function()
                utils.console_exec("connect csgohvh.game.nfoservers.com:27015; password csgo2x2")
            end),
        },
    }
end

do
    local g_cfg = ui.create("Config", "madrilla recode")

    local function export_config()
        local cfg = get_config_table(menu)
        local str = serialize_config(cfg)
        print("[madrilla recode] " .. str)
        common.add_event("[madrilla recode] Config printed to console", "copy")
    end

    local function save_db_config()
        local slot = menu.config.config_slot:get()
        local configs = db:get("mr_nl_configs") or {}
        configs[slot] = get_config_table(menu)
        db:set("mr_nl_configs", configs)
        common.add_event("[madrilla recode] Saved to " .. slot, "floppy-disk")
    end

    local function load_db_config()
        local slot = menu.config.config_slot:get()
        local configs = db:get("mr_nl_configs") or {}
        if configs[slot] then
            load_config_table(menu, configs[slot])
            common.add_event("[madrilla recode] Loaded from " .. slot, "folder-open")
        else
            common.add_event("[madrilla recode] No config in " .. slot, "triangle-exclamation")
        end
    end

    menu.config = {
        accent      = g_cfg:color_picker("Accent Color", color(255, 96, 71, 255)),
        config_slot = g_cfg:combo("Config Slot", "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5"),
        db_save_btn = g_cfg:button("Save to Selected Slot", save_db_config),
        db_load_btn = g_cfg:button("Load from Selected Slot", load_db_config),
        export_btn  = g_cfg:button("Export to Console", export_config),
    }
end

ui.sidebar("madrilla recode", "skull")

return menu
