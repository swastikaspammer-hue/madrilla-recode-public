local clipboard = require("gamesense/clipboard")

-- Base64 implementation for cross-compatible sharing
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function enc_b64(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
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
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function get_config_table()
    local config = {}
    local function traverse(tbl, path)
        for k, v in pairs(tbl) do
            if type(v) == "number" then
                local s, v1, v2, v3, v4 = pcall(ui.get, v)
                if s and v1 ~= nil then
                    -- Detect color picker
                    if v2 ~= nil and type(v1) == "number" and type(v2) == "number" then
                        config[path .. k] = {v1, v2, v3, v4}
                    else
                        config[path .. k] = v1
                    end
                end
            elseif type(v) == "table" and k ~= "states" then
                traverse(v, path .. k .. ".")
            end
        end
    end

    traverse(menu, "")
    for state_name, state_tbl in pairs(menu.antiaim.states) do
        traverse(state_tbl, "antiaim.states." .. state_name .. ".")
    end
    return config
end

local function load_config_table(config)
    local function traverse_import(tbl, path)
        for k, v in pairs(tbl) do
            if type(v) == "number" then
                local val = config[path .. k]
                if val ~= nil then
                    if type(val) == "table" and type(val[1]) == "number" then
                        pcall(ui.set, v, unpack(val)) -- Color picker
                    else
                        pcall(ui.set, v, val)
                    end
                end
            elseif type(v) == "table" and k ~= "states" then
                traverse_import(v, path .. k .. ".")
            end
        end
    end

    traverse_import(menu, "")
    for state_name, state_tbl in pairs(menu.antiaim.states) do
        traverse_import(state_tbl, "antiaim.states." .. state_name .. ".")
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
            table.insert(parts, k .. ":s:" .. v:gsub(";", "_")) -- sanitize
        elseif vt == "table" then
            if type(v[1]) == "number" then
                -- Color
                table.insert(parts, k .. ":c:" .. table.concat(v, ","))
            elseif type(v[1]) == "string" then
                -- Multiselect
                table.insert(parts, k .. ":m:" .. table.concat(v, ","))
            elseif #v == 0 then
                -- Empty multiselect
                table.insert(parts, k .. ":m:")
            end
        end
    end
    return "madrilla_recode_" .. enc_b64(table.concat(parts, ";"))
end

local function deserialize_config(str)
    if not str:find("^madrilla_recode_") then return nil end
    str = dec_b64(str:sub(8))
    local cfg = {}
    for item in str:gmatch("[^;]+") do
        local k, t, val = item:match("^([^:]+):([^:]+):(.*)$")
        if k and t then
            if t == "b" then cfg[k] = (val == "true")
            elseif t == "n" then cfg[k] = tonumber(val)
            elseif t == "s" then cfg[k] = val
            elseif t == "c" then
                local c = {}
                for num in val:gmatch("[^,]+") do table.insert(c, tonumber(num)) end
                cfg[k] = c
            elseif t == "m" then
                local m = {}
                for s in val:gmatch("[^,]+") do table.insert(m, s) end
                cfg[k] = m
            end
        end
    end
    return cfg
end

local function export_config()
    local cfg = get_config_table()
    local str = serialize_config(cfg)
    clipboard.set(str)
    client.color_log(180, 255, 100, "[madrilla recode] Exported config to clipboard!")
end

local function import_config()
    local str = clipboard.get()
    local cfg = deserialize_config(str)
    if cfg then
        load_config_table(cfg)
        client.color_log(180, 255, 100, "[madrilla recode] Imported config from clipboard!")
    else
        client.color_log(255, 96, 71, "[madrilla recode] Invalid config string in clipboard!")
    end
end

local function save_database_config()
    local slot = ui.get(menu.config.config_slot)
    local configs = database.read("madrilla_recode_configs") or {}
    configs[slot] = get_config_table()
    database.write("madrilla_recode_configs", configs)
    client.color_log(180, 255, 100, "[madrilla recode] Saved config to " .. slot .. "!")
end

local function load_database_config()
    local slot = ui.get(menu.config.config_slot)
    local configs = database.read("madrilla_recode_configs") or {}
    if configs[slot] then
        load_config_table(configs[slot])
        client.color_log(180, 255, 100, "[madrilla recode] Loaded config from " .. slot .. "!")
    else
        client.color_log(255, 96, 71, "[madrilla recode] No config found in " .. slot .. "!")
    end
end

menu = {
    tabCombo = ui.new_combobox("LUA", "A", "madrilla recode", "ragebot", "antiaim", "visuals", "hud", "misc", "skins", "player list", "config"),

    antiaim = {
        enableAntiBackstab = ui.new_checkbox("LUA", "A", "anti-backstab"),
        invertOnShot = ui.new_checkbox("LUA", "A", "invert desync on shot"),
        invertOnHit = ui.new_checkbox("LUA", "A", "invert desync on hit"),
        lbyBreaker = ui.new_checkbox("LUA", "A", "0.22s lby breaker"),

        antiBrute = ui.new_checkbox("LUA", "A", "Anti-Bruteforce"),
        antiBruteModes = ui.new_multiselect("LUA", "A", "\nanti-brute-modes", "On Hit", "On Miss"),
        antiBruteAction = ui.new_combobox("LUA", "A", "Anti-Bruteforce action", "Invert Side", "Randomize", "Cycle 3-way"),

        manualLeft = ui.new_hotkey("LUA", "A", "Manual Left"),
        manualRight = ui.new_hotkey("LUA", "A", "Manual Right"),
        manualForward = ui.new_hotkey("LUA", "A", "Manual Forward"),
        manualBack = ui.new_hotkey("LUA", "A", "Manual Back"),

        enable = ui.new_checkbox("LUA", "A", "antiaim"),
        stateCombo = ui.new_combobox("LUA", "A", "state", "global", "standing", "moving", "slow walking", "crouched", "crouch moving", "air crouched", "air", "fakeducking", "defensive"),

        states = {},

        CreateStateMenu = function(name)
            local state = {}

            state.name = name

            if name ~= "global" then
                state.overrideGlobal = ui.new_checkbox("LUA", "A", "override global state " .. name)
            end

            if name ~= "defensive" then
                state.allowDefensive = ui.new_checkbox("LUA", "A", "allow defensive " .. name)
                state.forceDefensive = ui.new_checkbox("LUA", "A", "force defensive " .. name) 
            end

            state.pitchOffset = ui.new_slider("LUA", "A", "pitch offset " .. name, -89, 89, 0)

            state.yawOffset = ui.new_slider("LUA", "A", "yaw offset " .. name, -180, 180, 0)
            state.yawMode = ui.new_combobox("LUA", "A", "yaw mode " .. name, "static", "jitter", "delayed jitter", "random", "spin", "lfo", "switch", "3-way", "5-way")
            state.yawJitterDelayMin = ui.new_slider("LUA", "A", "yaw jitter delay min " .. name, 1, 10, 3)
            state.yawJitterDelayMax = ui.new_slider("LUA", "A", "yaw jitter delay max " .. name, 1, 10, 9)
            state.yawLfoShape = ui.new_combobox("LUA", "A", "yaw lfo shape " .. name, "sine", "triangle", "pulse")
            state.yawLfoSpeed = ui.new_slider("LUA", "A", "yaw lfo speed " .. name, 1, 100, 50, true, "%")
            state.yawLfoVelocityScale = ui.new_checkbox("LUA", "A", "scale yaw lfo speed by velocity " .. name)
            state.yawLfoRange = ui.new_slider("LUA", "A", "yaw lfo range " .. name, 0, 180, 90, true, "°")
            state.yawSwitchDelay = ui.new_slider("LUA", "A", "yaw switch delay " .. name, 1, 100, 30, true, "t")

            state.bodyYawOffset = ui.new_slider("LUA", "A", "body yaw offset " .. name, -180, 180, 60, true, "°")
            state.bodyYawMode = ui.new_combobox("LUA", "A", "body yaw mode " .. name, "static", "jitter", "delayed jitter", "random", "lfo")
            state.bodyYawJitterDelayMin = ui.new_slider("LUA", "A", "body yaw jitter delay min " .. name, 1, 10, 3)
            state.bodyYawJitterDelayMax = ui.new_slider("LUA", "A", "body yaw jitter delay max " .. name, 1, 10, 9)
            state.bodyYawLfoShape = ui.new_combobox("LUA", "A", "body yaw lfo shape " .. name, "sine", "triangle", "pulse")
            state.bodyYawLfoSpeed = ui.new_slider("LUA", "A", "body yaw lfo speed " .. name, 1, 100, 50, true, "%")
            state.bodyYawLfoVelocityScale = ui.new_checkbox("LUA", "A", "scale body yaw lfo speed by velocity " .. name)
            state.bodyYawLfoRange = ui.new_slider("LUA", "A", "body yaw lfo range " .. name, 0, 180, 60, true, "°")

            state.staticPeek = ui.new_checkbox("LUA", "A", "static peek " .. name)
            state.fakeBreaker = ui.new_checkbox("LUA", "A", "Extended Desync " .. name)
            state.extendFake = ui.new_checkbox("LUA", "A", "extend fake " .. name)

            menu.antiaim.states[name] = state
        end,

        OnInitialize = function()
            menu.antiaim.CreateStateMenu("global")
            menu.antiaim.CreateStateMenu("standing")
            menu.antiaim.CreateStateMenu("moving")
            menu.antiaim.CreateStateMenu("slow walking")
            menu.antiaim.CreateStateMenu("crouched")
            menu.antiaim.CreateStateMenu("crouch moving")
            menu.antiaim.CreateStateMenu("air crouched")
            menu.antiaim.CreateStateMenu("air")
            menu.antiaim.CreateStateMenu("fakeducking")
            menu.antiaim.CreateStateMenu("defensive")
        end,

        SetMenuVisibility = function(value)
            if value == false then
                ui.set_visible(menu.antiaim.stateCombo, false)

                for _, state in pairs(menu.antiaim.states) do
                    if state.overrideGlobal ~= nil then
                        ui.set_visible(state.overrideGlobal, false)
                    end

                    if state.allowDefensive ~= nil then
                        ui.set_visible(state.allowDefensive, false)
                        ui.set_visible(state.forceDefensive, false)
                    end

                    ui.set_visible(state.pitchOffset, false)

                    ui.set_visible(state.yawOffset, false)
                    ui.set_visible(state.yawMode, false)
                    ui.set_visible(state.yawJitterDelayMin, false)
                    ui.set_visible(state.yawJitterDelayMax, false)
                    ui.set_visible(state.yawLfoShape, false)
                    ui.set_visible(state.yawLfoSpeed, false)
                    ui.set_visible(state.yawLfoVelocityScale, false)
                    ui.set_visible(state.yawLfoRange, false)
                    ui.set_visible(state.yawSwitchDelay, false)

                    ui.set_visible(state.bodyYawOffset, false)
                    ui.set_visible(state.bodyYawMode, false)
                    ui.set_visible(state.bodyYawJitterDelayMin, false)
                    ui.set_visible(state.bodyYawJitterDelayMax, false)
                    ui.set_visible(state.bodyYawLfoShape, false)
                    ui.set_visible(state.bodyYawLfoSpeed, false)
                    ui.set_visible(state.bodyYawLfoVelocityScale, false)
                    ui.set_visible(state.bodyYawLfoRange, false)

                    ui.set_visible(state.staticPeek, false)
                    ui.set_visible(state.fakeBreaker, false)
                    ui.set_visible(state.extendFake, false)
                end
            else
                ui.set_visible(menu.antiaim.stateCombo, true)

                local currentState = ui.get(menu.antiaim.stateCombo)

                for _, state in pairs(menu.antiaim.states) do
                    if state.overrideGlobal ~= nil then
                        ui.set_visible(state.overrideGlobal, state.name == currentState)
                    end
                    
                    if state.allowDefensive ~= nil then
                        ui.set_visible(state.allowDefensive, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                        ui.set_visible(state.forceDefensive, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and ui.get(state.allowDefensive))
                    end

                    ui.set_visible(state.pitchOffset, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))

                    ui.set_visible(state.yawOffset, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.yawMode, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.yawJitterDelayMin, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "delayed jitter"))
                    ui.set_visible(state.yawJitterDelayMax, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "delayed jitter"))
                    ui.set_visible(state.yawLfoShape, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "lfo"))
                    ui.set_visible(state.yawLfoSpeed, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "lfo"))
                    ui.set_visible(state.yawLfoVelocityScale, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "lfo"))
                    ui.set_visible(state.yawLfoRange, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "lfo"))
                    ui.set_visible(state.yawSwitchDelay, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.yawMode) == "switch"))

                    ui.set_visible(state.bodyYawOffset, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.bodyYawMode, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.bodyYawJitterDelayMin, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "delayed jitter"))
                    ui.set_visible(state.bodyYawJitterDelayMax, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "delayed jitter"))
                    ui.set_visible(state.bodyYawLfoShape, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "lfo"))
                    ui.set_visible(state.bodyYawLfoSpeed, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "lfo"))
                    ui.set_visible(state.bodyYawLfoVelocityScale, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "lfo"))
                    ui.set_visible(state.bodyYawLfoRange, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and (ui.get(state.bodyYawMode) == "lfo"))

                    ui.set_visible(state.staticPeek, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.fakeBreaker, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)))
                    ui.set_visible(state.extendFake, state.name == currentState and (state.overrideGlobal == nil or ui.get(state.overrideGlobal)) and ui.get(state.fakeBreaker))
                end
            end
        end
    },

    ragebot = {
        resolver = {
            enable = ui.new_checkbox("LUA", "A", "resolver"),
            override = ui.new_checkbox("LUA", "A", "force bruteforce (debug)"),
            log = ui.new_checkbox("LUA", "A", "log resolver actions"),
            freestanding = ui.new_checkbox("LUA", "A", "freestanding trace fallback"),
            freestandingWidth = ui.new_slider("LUA", "A", "freestanding trace width", 20, 80, 40, true, "u")
        },

        autoSafepoint = {
            enable = ui.new_checkbox("LUA", "A", "auto safepoint"),
            options = ui.new_multiselect("LUA", "A", "auto safepoint options", "low jitter", "high jitter", "lethal", "in air", "on miss")
        },

        ragebotHelper = {
            enable = ui.new_checkbox("LUA", "A", "ragebot helper"),
            bind = ui.new_hotkey("LUA", "A", "ragebot helper key", true),
            avoidUnsafeHitboxes = ui.new_checkbox("LUA", "A", "avoid unsafe hitboxes"),
            maxTargetTime = ui.new_slider("LUA", "A", "max target time", 0, 5, 4),
            hitChance = ui.new_slider("LUA", "A", "hitchance", 1, 100, 80),
            minDamage = ui.new_slider("LUA", "A", "min damage", 1, 100, 30),
            forceHideshotsSniper = ui.new_checkbox("LUA", "A", "Force hideshots on sniper crouch")
        },

        multiDT = {
            enable = ui.new_checkbox("LUA", "A", "multi-key double tap"),
            key1 = ui.new_hotkey("LUA", "A", "double tap key 1", true),
            key2 = ui.new_hotkey("LUA", "A", "double tap key 2", true),
            key3 = ui.new_hotkey("LUA", "A", "double tap key 3", true)
        }
    },

    visuals = {




        weather = {
            enable = ui.new_checkbox("LUA", "A", "weather"),
            precipitationType = ui.new_combobox("LUA", "A", "precipitation type", "none", "rain", "snow", "particle rain", "particle snow", "particle ash")
        },

        grenadeESP = {
            enable = ui.new_checkbox("LUA", "A", "grenade inventory esp"),
            color = ui.new_color_picker("LUA", "A", "grenade inventory esp color", 255, 255, 255, 255),
            position = ui.new_combobox("LUA", "A", "grenade esp position", "Right", "Left", "Top", "Bottom"),
            scale = ui.new_slider("LUA", "A", "grenade icon scale", 6, 10, 8, true, "x", 0.1)
        },


        viewModelChanger = {
            enable = ui.new_checkbox("LUA", "A", "viewmodel changer"),
            fov = ui.new_slider("LUA", "A", "viewmodel fov", 30, 120, cvar.viewmodel_fov:get_float(), true, nil, 0.1),
            x = ui.new_slider("LUA", "A", "viewmodel x", -20, 20, cvar.viewmodel_offset_x:get_float(), true, nil, 0.1),
            y = ui.new_slider("LUA", "A", "viewmodel y", -20, 20, cvar.viewmodel_offset_y:get_float(), true, nil, 0.1),
            z = ui.new_slider("LUA", "A", "viewmodel z", -20, 20, cvar.viewmodel_offset_z:get_float(), true, nil, 0.1)
        },

        aspectRatioChanger = {
            enable = ui.new_checkbox("LUA", "A", "aspect ratio changer"),
            aspectRatio = ui.new_slider("LUA", "A", "aspect ratio", 0.3, 300.0, cvar.r_aspectratio:get_float(), true, nil, 0.01)
        },

        thirdPersonChanger = {
            enable = ui.new_checkbox("LUA", "A", "third person changer"),
            distance = ui.new_slider("LUA", "A", "third person distance", 25, 200, cvar.cam_idealdist:get_float())
        },

        animBreaker = {
            enable = ui.new_checkbox("LUA", "A", "animation breaker"),
            options = ui.new_multiselect("LUA", "A", "animation breaker options", "Moonwalk (Slide)", "Static Legs in Air", "0 Pitch on Land")
        },

    },


    hud = {
        centerIndicators = {
            enable = ui.new_checkbox("LUA", "A", "center indicators")
        },
        customKillfeed = {
            enable = ui.new_checkbox("LUA", "A", "custom killfeed"),
            advanced = ui.new_checkbox("LUA", "A", "Advanced Killfeed Colors"),
            size = ui.new_slider("LUA", "A", "custom killfeed size", 10, 30, 16),
            bgActiveLabel = ui.new_label("LUA", "A", "Active Background"),
            bg_active = ui.new_color_picker("LUA", "A", "custom killfeed active bg", 30, 30, 30, 200),
            bgInactiveLabel = ui.new_label("LUA", "A", "Inactive Background"),
            bg_inactive = ui.new_color_picker("LUA", "A", "custom killfeed inactive bg", 15, 15, 15, 200),
            attackerColorLabel = ui.new_label("LUA", "A", "Attacker Color"),
            attacker_color = ui.new_color_picker("LUA", "A", "custom killfeed attacker color", 255, 255, 255, 255),
            attackedColorLabel = ui.new_label("LUA", "A", "Attacked Color"),
            attacked_color = ui.new_color_picker("LUA", "A", "custom killfeed attacked color", 255, 50, 50, 255),
            weaponColorLabel = ui.new_label("LUA", "A", "Weapon Color"),
            weapon_color = ui.new_color_picker("LUA", "A", "custom killfeed weapon color", 255, 255, 255, 255),
            headshotColorLabel = ui.new_label("LUA", "A", "Headshot Color"),
            headshot_color = ui.new_color_picker("LUA", "A", "custom killfeed headshot color", 255, 210, 50, 255)
        },
        logs = {
            options = ui.new_multiselect("LUA", "A", "logs", "console", "hitlog indicator"),
            logOnshot = ui.new_checkbox("LUA", "A", "log onshot status")
        },
        floatingDamage = {
            enable = ui.new_checkbox("LUA", "A", "3d floating damage"),
            color = ui.new_color_picker("LUA", "A", "floating damage color", 255, 69, 69, 255),
            duration = ui.new_slider("LUA", "A", "floating damage duration", 1, 5, 2, true, "s")
        },
        customHud = {
            enable = ui.new_checkbox("LUA", "A", "enable custom hud (warning buggy and kinda ass rn will fix later)"),
            advanced = ui.new_checkbox("LUA", "A", "Advanced HUD Colors"),
            advancedLayout = ui.new_checkbox("LUA", "A", "Advanced HUD Layout"),
            options = ui.new_multiselect("LUA", "A", "custom hud elements", "Top Bar", "Health & Armor", "Ammo", "Spectator Panel", "Round End Banner", "Crosshair", "Damage Flash"),
            hideMethod = ui.new_combobox("LUA", "A", "native hud hide method", "Panorama (Best: Hides Native, Keeps Chat/Switch)", "Deathnotices (Hides Topbar, Breaks Chat)", "Keep Weapon Selection (Allows Chat)", "Hide Weapon Selection (Breaks Switch)"),
            bgColorLabel = ui.new_label("LUA", "A", "Background Color"),
            bgColor = ui.new_color_picker("LUA", "A", "Background Color", 15, 15, 15, 100),
            accentColorLabel = ui.new_label("LUA", "A", "Accent Color"),
            accentColor = ui.new_color_picker("LUA", "A", "Accent Color", 255, 69, 69, 255),
            tColorLabel = ui.new_label("LUA", "A", "T Color"),
            tColor = ui.new_color_picker("LUA", "A", "T Color", 255, 180, 50, 255),
            ctColorLabel = ui.new_label("LUA", "A", "CT Color"),
            ctColor = ui.new_color_picker("LUA", "A", "CT Color", 100, 150, 255, 255),
            topBarX = ui.new_slider("LUA", "A", "Top Bar X Offset", -2000, 2000, 0),
            topBarY = ui.new_slider("LUA", "A", "Top Bar Y Offset", -2000, 2000, 0),
            healthX = ui.new_slider("LUA", "A", "Health X Offset", -2000, 2000, 0),
            healthY = ui.new_slider("LUA", "A", "Health Y Offset", -2000, 2000, 0),
            ammoX = ui.new_slider("LUA", "A", "Ammo X Offset", -2000, 2000, 0),
            ammoY = ui.new_slider("LUA", "A", "Ammo Y Offset", -2000, 2000, 0),
            specX = ui.new_slider("LUA", "A", "Spectator X Offset", -2000, 2000, 0),
            specY = ui.new_slider("LUA", "A", "Spectator Y Offset", -2000, 2000, 0)
        },
        solusUi = {
            watermark = ui.new_checkbox("LUA", "A", "solus watermark"),
            keybinds = ui.new_checkbox("LUA", "A", "solus keybinds"),
            statusPanel = ui.new_checkbox("LUA", "A", "solus status panel"),
            statusPanelX = ui.new_slider("LUA", "A", "status panel x", 0, 3000, 300),
            statusPanelY = ui.new_slider("LUA", "A", "status panel y", 0, 3000, 300),
            customChat = ui.new_checkbox("LUA", "A", "solus custom chat"),
            customMoney = ui.new_checkbox("LUA", "A", "solus custom money")
        },
    },

    misc = {
        clantag = {
            enable = ui.new_checkbox("LUA", "A", "animated clantag")
        },

        discordRpc = {
            enable = ui.new_checkbox("LUA", "A", "discord rich presence")
        },

        autoBuy = {
            enable = ui.new_checkbox("LUA", "A", "auto buy"),
            primary = ui.new_combobox("LUA", "A", "primary", "-", "scout", "auto", "awp"),
            secondary = ui.new_combobox("LUA", "A", "secondary", "-", "deagle"),
            equipment = ui.new_multiselect("LUA", "A", "equipment", "armor", "nades")
        },

        delayedFakeduck = {
            enable = ui.new_checkbox("LUA", "A", "delayed fakeduck"),
            bind = ui.new_hotkey("LUA", "A", "delayed fakeduck key", true)
        },

        fastLadder = {
            enable = ui.new_checkbox("LUA", "A", "fast ladder")
        },

        serverJoiner = {
            join2x2 = ui.new_button("LUA", "A", "Join 2x2 Server", function()
                client.exec("connect csgohvh.game.nfoservers.com:27015; password csgo2x2")
            end)
        },

        smartDrop = {
            enable = ui.new_checkbox("LUA", "A", "smart drop (fixes AA drop)"),
            bind = ui.new_hotkey("LUA", "A", "smart drop key", true)
        },

        dropNades = {
            enable = ui.new_checkbox("LUA", "A", "drop nades"),
            bind = ui.new_hotkey("LUA", "A", "drop nades key", true)
        },

        fakePing = {
            enable = ui.new_checkbox("LUA", "A", "dynamic fake ping"),
            amount = ui.new_slider("LUA", "A", "fake ping amount", 1, 200, 100, true, "ms")
        },

        clantag = {
            enable = ui.new_checkbox("LUA", "A", "animated clantag")
        },

        killsay = {
            enable = ui.new_checkbox("LUA", "A", "smart killsay")
        }
    },

    config = {
        accent_label = ui.new_label("LUA", "A", "Accent Color"),
        accent = ui.new_color_picker("LUA", "A", "Accent Color", 255, 96, 71, 255),
        config_slot = ui.new_combobox("LUA", "A", "Config Slot", "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5"),
        db_save_btn = ui.new_button("LUA", "A", "Save to Selected Slot", save_database_config),
        db_load_btn = ui.new_button("LUA", "A", "Load from Selected Slot", load_database_config),
        export_btn = ui.new_button("LUA", "A", "Export to Clipboard", export_config),
        import_btn = ui.new_button("LUA", "A", "Import from Clipboard", import_config)
    },

    OnInitialize = function()
        menu.antiaim.OnInitialize()
        menu.BindCallbacks()
    end,

    BindCallbacks = function()
        local function update()
            menu.OnTabSwitch()
            menu.OnMenuUpdate()
        end
        
        ui.set_callback(menu.tabCombo, update)
        
        -- Ragebot
        ui.set_callback(menu.ragebot.resolver.freestanding, update)
        ui.set_callback(menu.ragebot.ragebotHelper.enable, update)
        ui.set_callback(menu.ragebot.autoSafepoint.enable, update)
        ui.set_callback(menu.ragebot.multiDT.enable, update)

        -- Antiaim
        ui.set_callback(menu.antiaim.enable, update)
        ui.set_callback(menu.antiaim.antiBrute, update)
        ui.set_callback(menu.antiaim.stateCombo, update)
        for _, state in pairs(menu.antiaim.states) do
            if state.overrideGlobal then ui.set_callback(state.overrideGlobal, update) end
            if state.allowDefensive then ui.set_callback(state.allowDefensive, update) end
            ui.set_callback(state.yawMode, update)
            ui.set_callback(state.bodyYawMode, update)
            ui.set_callback(state.fakeBreaker, update)
        end

        -- HUD
        ui.set_callback(menu.hud.customKillfeed.enable, update)
        ui.set_callback(menu.hud.customKillfeed.advanced, update)
        ui.set_callback(menu.hud.floatingDamage.enable, update)
        ui.set_callback(menu.hud.customHud.enable, update)
        ui.set_callback(menu.hud.customHud.advanced, update)
        ui.set_callback(menu.hud.customHud.advancedLayout, update)

        -- Visuals
        ui.set_callback(menu.visuals.weather.enable, update)
        ui.set_callback(menu.visuals.grenadeESP.enable, update)
        ui.set_callback(menu.visuals.viewModelChanger.enable, update)
        ui.set_callback(menu.visuals.animBreaker.enable, update)
        ui.set_callback(menu.visuals.aspectRatioChanger.enable, update)
        ui.set_callback(menu.visuals.thirdPersonChanger.enable, update)

        -- Misc
        ui.set_callback(menu.misc.autoBuy.enable, update)

        -- Initial call to set correct states on load
        update()
    end,

    OnTabSwitch = function()
        tabComboValue = ui.get(menu.tabCombo)

        ui.set_visible(menu.ragebot.resolver.enable, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.resolver.override, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.resolver.log, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.resolver.freestanding, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.resolver.freestandingWidth, ui.get(menu.ragebot.resolver.freestanding) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.autoSafepoint.enable, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.enable, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.bind, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.enable, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.key1, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.key2, tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.key3, tabComboValue == "ragebot")

        ui.set_visible(menu.antiaim.enableAntiBackstab, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.invertOnShot, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.invertOnHit, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.lbyBreaker, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.antiBrute, tabComboValue == "antiaim")

        local isAntiBruteEnabled = tabComboValue == "antiaim" and ui.get(menu.antiaim.antiBrute)
        ui.set_visible(menu.antiaim.antiBruteModes, isAntiBruteEnabled)
        ui.set_visible(menu.antiaim.antiBruteAction, isAntiBruteEnabled)

        ui.set_visible(menu.antiaim.manualLeft, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.manualRight, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.manualForward, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.manualBack, tabComboValue == "antiaim")
        ui.set_visible(menu.antiaim.enable, tabComboValue == "antiaim")
       
        ui.set_visible(menu.hud.centerIndicators.enable, tabComboValue == "hud")
        ui.set_visible(menu.hud.customHud.enable, tabComboValue == "hud")
        ui.set_visible(menu.hud.customHud.advanced, tabComboValue == "hud")
        ui.set_visible(menu.hud.customHud.advancedLayout, tabComboValue == "hud")

        ui.set_visible(menu.hud.customKillfeed.enable, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.advanced, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.size, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.bgActiveLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.bg_active, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.bgInactiveLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.bg_inactive, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.attackerColorLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.attacker_color, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.attackedColorLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.attacked_color, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.weaponColorLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.weapon_color, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.headshotColorLabel, tabComboValue == "hud")
        ui.set_visible(menu.hud.customKillfeed.headshot_color, tabComboValue == "hud")
        ui.set_visible(menu.hud.logs.options, tabComboValue == "hud")
        ui.set_visible(menu.hud.logs.logOnshot, tabComboValue == "hud")
        ui.set_visible(menu.hud.floatingDamage.enable, tabComboValue == "hud")
        ui.set_visible(menu.hud.floatingDamage.color, tabComboValue == "hud")
        ui.set_visible(menu.hud.floatingDamage.duration, tabComboValue == "hud")
        ui.set_visible(menu.visuals.weather.enable, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.enable, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.color, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.position, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.scale, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.viewModelChanger.enable, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.animBreaker.enable, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.animBreaker.options, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.aspectRatioChanger.enable, tabComboValue == "visuals")
        ui.set_visible(menu.visuals.thirdPersonChanger.enable, tabComboValue == "visuals")
        ui.set_visible(menu.hud.solusUi.watermark, tabComboValue == "hud")
        ui.set_visible(menu.hud.solusUi.keybinds, tabComboValue == "hud")
        ui.set_visible(menu.hud.solusUi.statusPanel, tabComboValue == "hud")
        ui.set_visible(menu.hud.solusUi.statusPanelX, false)
        ui.set_visible(menu.hud.solusUi.statusPanelY, false)
        ui.set_visible(menu.hud.solusUi.customChat, false)
        ui.set_visible(menu.hud.solusUi.customMoney, tabComboValue == "hud")

        ui.set_visible(menu.misc.autoBuy.enable, tabComboValue == "misc")

        ui.set_visible(menu.misc.delayedFakeduck.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.delayedFakeduck.bind, tabComboValue == "misc")

        ui.set_visible(menu.misc.fastLadder.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.serverJoiner.join2x2, tabComboValue == "misc")

        ui.set_visible(menu.misc.smartDrop.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.smartDrop.bind, tabComboValue == "misc")

        ui.set_visible(menu.misc.dropNades.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.dropNades.bind, tabComboValue == "misc")
        ui.set_visible(menu.misc.discordRpc.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.fakePing.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.fakePing.amount, tabComboValue == "misc")
        ui.set_visible(menu.misc.clantag.enable, tabComboValue == "misc")
        ui.set_visible(menu.misc.killsay.enable, tabComboValue == "misc")

        ui.set_visible(menu.config.accent_label, tabComboValue == "config")
        ui.set_visible(menu.config.accent, tabComboValue == "config")
        ui.set_visible(menu.config.config_slot, tabComboValue == "config")
        ui.set_visible(menu.config.db_save_btn, tabComboValue == "config")
        ui.set_visible(menu.config.db_load_btn, tabComboValue == "config")
        ui.set_visible(menu.config.export_btn, tabComboValue == "config")
        ui.set_visible(menu.config.import_btn, tabComboValue == "config")
    end,

    OnMenuUpdate = function()
        tabComboValue = ui.get(menu.tabCombo)
        menu.OnTabSwitch()

        ui.set_visible(menu.ragebot.resolver.freestandingWidth, ui.get(menu.ragebot.resolver.freestanding) and tabComboValue == "ragebot")

        ui.set_visible(menu.ragebot.ragebotHelper.avoidUnsafeHitboxes, ui.get(menu.ragebot.ragebotHelper.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.maxTargetTime, ui.get(menu.ragebot.ragebotHelper.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.hitChance, ui.get(menu.ragebot.ragebotHelper.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.minDamage, ui.get(menu.ragebot.ragebotHelper.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.ragebotHelper.forceHideshotsSniper, ui.get(menu.ragebot.ragebotHelper.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.autoSafepoint.options, ui.get(menu.ragebot.autoSafepoint.enable) and tabComboValue == "ragebot")

        ui.set_visible(menu.ragebot.multiDT.key1, ui.get(menu.ragebot.multiDT.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.key2, ui.get(menu.ragebot.multiDT.enable) and tabComboValue == "ragebot")
        ui.set_visible(menu.ragebot.multiDT.key3, ui.get(menu.ragebot.multiDT.enable) and tabComboValue == "ragebot")
        
        menu.antiaim.SetMenuVisibility( ui.get(menu.antiaim.enable) and tabComboValue == "antiaim")

        local isAntiBruteEnabled = ui.get(menu.antiaim.antiBrute) and tabComboValue == "antiaim"
        ui.set_visible(menu.antiaim.antiBruteModes, isAntiBruteEnabled)
        ui.set_visible(menu.antiaim.antiBruteAction, isAntiBruteEnabled)
        
        local isCustomKillfeedEnabled = ui.get(menu.hud.customKillfeed.enable) and tabComboValue == "hud"
        local isKillfeedAdvanced = isCustomKillfeedEnabled and ui.get(menu.hud.customKillfeed.advanced)
        
        ui.set_visible(menu.hud.customKillfeed.advanced, isCustomKillfeedEnabled)
        ui.set_visible(menu.hud.customKillfeed.size, isCustomKillfeedEnabled)
        
        ui.set_visible(menu.hud.customKillfeed.bgActiveLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.bg_active, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.bgInactiveLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.bg_inactive, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.attackerColorLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.attacker_color, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.attackedColorLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.attacked_color, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.weaponColorLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.weapon_color, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.headshotColorLabel, isKillfeedAdvanced)
        ui.set_visible(menu.hud.customKillfeed.headshot_color, isKillfeedAdvanced)

        ui.set_visible(menu.hud.floatingDamage.color, ui.get(menu.hud.floatingDamage.enable) and tabComboValue == "hud")
        ui.set_visible(menu.hud.floatingDamage.duration, ui.get(menu.hud.floatingDamage.enable) and tabComboValue == "hud")
        ui.set_visible(menu.visuals.weather.precipitationType, ui.get(menu.visuals.weather.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.color, ui.get(menu.visuals.grenadeESP.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.position, ui.get(menu.visuals.grenadeESP.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.grenadeESP.scale, ui.get(menu.visuals.grenadeESP.enable) and tabComboValue == "visuals")

        local isCustomHudEnabled = ui.get(menu.hud.customHud.enable) and tabComboValue == "hud"
        local isHudAdvanced = isCustomHudEnabled and ui.get(menu.hud.customHud.advanced)
        
        ui.set_visible(menu.hud.customHud.advanced, isCustomHudEnabled)
        ui.set_visible(menu.hud.customHud.options, isCustomHudEnabled)
        ui.set_visible(menu.hud.customHud.hideMethod, isCustomHudEnabled)
        
        ui.set_visible(menu.hud.customHud.bgColorLabel, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.bgColor, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.accentColorLabel, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.accentColor, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.tColorLabel, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.tColor, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.ctColorLabel, isHudAdvanced)
        ui.set_visible(menu.hud.customHud.ctColor, isHudAdvanced)
        
        local isHudLayoutAdvanced = isCustomHudEnabled and ui.get(menu.hud.customHud.advancedLayout)
        ui.set_visible(menu.hud.customHud.topBarX, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.topBarY, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.healthX, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.healthY, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.ammoX, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.ammoY, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.specX, isHudLayoutAdvanced)
        ui.set_visible(menu.hud.customHud.specY, isHudLayoutAdvanced)

        ui.set_visible(menu.visuals.viewModelChanger.fov, ui.get(menu.visuals.viewModelChanger.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.viewModelChanger.x, ui.get(menu.visuals.viewModelChanger.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.viewModelChanger.y, ui.get(menu.visuals.viewModelChanger.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.viewModelChanger.z, ui.get(menu.visuals.viewModelChanger.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.animBreaker.options, ui.get(menu.visuals.animBreaker.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.aspectRatioChanger.aspectRatio, ui.get(menu.visuals.aspectRatioChanger.enable) and tabComboValue == "visuals")
        ui.set_visible(menu.visuals.thirdPersonChanger.distance, ui.get(menu.visuals.thirdPersonChanger.enable) and tabComboValue == "visuals")

        ui.set_visible(menu.misc.autoBuy.primary, ui.get(menu.misc.autoBuy.enable) and tabComboValue == "misc")
        ui.set_visible(menu.misc.autoBuy.secondary, ui.get(menu.misc.autoBuy.enable) and tabComboValue == "misc")
        ui.set_visible(menu.misc.autoBuy.equipment, ui.get(menu.misc.autoBuy.enable) and tabComboValue == "misc")
    end
}

return menu