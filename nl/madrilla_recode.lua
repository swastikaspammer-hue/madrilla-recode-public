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
                if ok and val ~= nil then config[path .. k] = val end
            elseif type(v) == "table" and k ~= "states" then
                traverse(v, path .. k .. ".")
            end
        end
    end
    traverse(menu_ref, "")
    if menu_ref.antiaim and menu_ref.antiaim.states then
        for sn, st in pairs(menu_ref.antiaim.states) do
            traverse(st, "antiaim.states." .. sn .. ".")
        end
    end
    return config
end

local function load_config_table(menu_ref, config)
    local function traverse_import(tbl, path)
        for k, v in pairs(tbl) do
            if type(v) == "table" and v.set and type(v.set) == "function" then
                local val = config[path .. k]
                if val ~= nil then pcall(function() v:set(val) end) end
            elseif type(v) == "table" and k ~= "states" then
                traverse_import(v, path .. k .. ".")
            end
        end
    end
    traverse_import(menu_ref, "")
    if menu_ref.antiaim and menu_ref.antiaim.states then
        for sn, st in pairs(menu_ref.antiaim.states) do
            traverse_import(st, "antiaim.states." .. sn .. ".")
        end
    end
end

local function serialize_config(cfg)
    local parts = {}
    for k, v in pairs(cfg) do
        local vt = type(v)
        if vt == "boolean" then table.insert(parts, k..":b:"..tostring(v))
        elseif vt == "number" then table.insert(parts, k..":n:"..tostring(v))
        elseif vt == "string" then table.insert(parts, k..":s:"..v:gsub(";","_"))
        end
    end
    return "mr_nl_"..enc_b64(table.concat(parts,";"))
end

local function deserialize_config(str)
    if not str:find("^mr_nl_") then return nil end
    local cfg = {}
    for item in dec_b64(str:sub(7)):gmatch("[^;]+") do
        local k,t,val = item:match("^([^:]+):([^:]+):(.*)$")
        if k and t then
            if t=="b" then cfg[k]=(val=="true")
            elseif t=="n" then cfg[k]=tonumber(val)
            elseif t=="s" then cfg[k]=val
            end
        end
    end
    return cfg
end

local menu = {}

do
    local g1 = ui.create("Ragebot","Resolver")
    local g2 = ui.create("Ragebot","Auto Safepoint")
    local g3 = ui.create("Ragebot","Ragebot Helper")
    local g4 = ui.create("Ragebot","Multi-Key Double Tap")
    menu.ragebot = {
        resolver = {
            enable            = g1:switch("Enable Resolver"),
            override          = g1:switch("Force bruteforce (debug)"),
            log               = g1:switch("Log resolver actions"),
            freestanding      = g1:switch("Freestanding trace fallback"),
            freestandingWidth = g1:slider("Freestanding trace width",20,80,40),
        },
        autoSafepoint = {
            enable  = g2:switch("Auto Safepoint"),
            options = g2:selectable("Options","low jitter","high jitter","lethal","in air","on miss"),
        },
        ragebotHelper = {
            enable               = g3:switch("Ragebot Helper"),
            bind                 = g3:hotkey("Helper Key"),
            avoidUnsafeHitboxes  = g3:switch("Avoid unsafe hitboxes"),
            maxTargetTime        = g3:slider("Max target time",0,5,4),
            hitChance            = g3:slider("Hitchance",1,100,80),
            minDamage            = g3:slider("Min damage",1,100,30),
            forceHideshotsSniper = g3:switch("Force hideshots on sniper crouch"),
        },
        multiDT = {
            enable = g4:switch("Multi-key double tap"),
            key1   = g4:hotkey("Double tap key 1"),
            key2   = g4:hotkey("Double tap key 2"),
            key3   = g4:hotkey("Double tap key 3"),
        },
    }
end

do
    local g1 = ui.create("Anti-Aim","General")
    local g2 = ui.create("Anti-Aim","Anti-Backstab")
    local g3 = ui.create("Anti-Aim","Inversion")
    local g4 = ui.create("Anti-Aim","Anti-Bruteforce")
    local g5 = ui.create("Anti-Aim","Manual Direction")
    menu.antiaim = {
        enable             = g1:switch("Enable Custom AA"),
        lbyBreaker         = g1:switch("0.22s LBY Breaker"),
        stateCombo         = g1:combo("State","global","standing","moving","slow walking","crouched","crouch moving","air crouched","air","fakeducking","defensive"),
        enableAntiBackstab = g2:switch("Anti-Backstab"),
        invertOnShot       = g3:switch("Invert desync on shot"),
        invertOnHit        = g3:switch("Invert desync on hit"),
        antiBrute          = g4:switch("Anti-Bruteforce"),
        antiBruteModes     = g4:selectable("Anti-Brute modes","On Hit","On Miss"),
        antiBruteAction    = g4:combo("Anti-Brute action","Invert Side","Randomize","Cycle 3-way"),
        manualLeft         = g5:hotkey("Manual Left"),
        manualRight        = g5:hotkey("Manual Right"),
        manualForward      = g5:hotkey("Manual Forward"),
        manualBack         = g5:hotkey("Manual Back"),
        states             = {},
    }
end

do
    local state_names = {"global","standing","moving","slow walking","crouched","crouch moving","air crouched","air","fakeducking","defensive"}
    for _, name in ipairs(state_names) do
        local g = ui.create("Anti-Aim","State: "..name)
        local state = { name = name }
        if name ~= "global" then state.overrideGlobal = g:switch("Override global") end
        if name ~= "defensive" then
            state.allowDefensive = g:switch("Allow defensive")
            state.forceDefensive = g:switch("Force defensive")
        end
        state.pitchOffset         = g:slider("Pitch offset",-89,89,0)
        state.yawOffset           = g:slider("Yaw offset",-180,180,0)
        state.yawMode             = g:combo("Yaw mode","static","jitter","delayed jitter","random","spin","lfo","switch","3-way","5-way")
        state.yawJitterDelayMin   = g:slider("Yaw jitter delay min",1,10,3)
        state.yawJitterDelayMax   = g:slider("Yaw jitter delay max",1,10,9)
        state.yawLfoShape         = g:combo("Yaw LFO shape","sine","triangle","pulse")
        state.yawLfoSpeed         = g:slider("Yaw LFO speed",1,100,50)
        state.yawLfoVelocityScale = g:switch("Scale yaw LFO by velocity")
        state.yawLfoRange         = g:slider("Yaw LFO range",0,180,90)
        state.yawSwitchDelay      = g:slider("Yaw switch delay (ticks)",1,100,30)
        state.bodyYawOffset           = g:slider("Body yaw offset",-180,180,60)
        state.bodyYawMode             = g:combo("Body yaw mode","static","jitter","delayed jitter","random","lfo")
        state.bodyYawJitterDelayMin   = g:slider("Body yaw jitter delay min",1,10,3)
        state.bodyYawJitterDelayMax   = g:slider("Body yaw jitter delay max",1,10,9)
        state.bodyYawLfoShape         = g:combo("Body yaw LFO shape","sine","triangle","pulse")
        state.bodyYawLfoSpeed         = g:slider("Body yaw LFO speed",1,100,50)
        state.bodyYawLfoVelocityScale = g:switch("Scale body yaw LFO by velocity")
        state.bodyYawLfoRange         = g:slider("Body yaw LFO range",0,180,60)
        state.staticPeek              = g:switch("Static peek on hit")
        state.fakeBreaker             = g:switch("Extended desync")
        state.extendFake              = g:switch("Extend fake")
        menu.antiaim.states[name] = state
    end
end

do
    local g1 = ui.create("Visuals","Weather")
    local g2 = ui.create("Visuals","Grenade ESP")
    local g3 = ui.create("Visuals","Viewmodel")
    local g4 = ui.create("Visuals","Animation Breaker")
    local g5 = ui.create("Visuals","Aspect Ratio")
    local g6 = ui.create("Visuals","Third Person")
    menu.visuals = {
        weather = {
            enable            = g1:switch("Weather effects"),
            precipitationType = g1:combo("Type","none","rain","snow","particle rain","particle snow","particle ash"),
        },
        grenadeESP = {
            enable   = g2:switch("Grenade inventory ESP"),
            color    = g2:color_picker("Color",color(255,255,255,255)),
            position = g2:combo("Position","Right","Left","Top","Bottom"),
            scale    = g2:slider("Icon scale",6,10,8),
        },
        viewModelChanger = {
            enable = g3:switch("Viewmodel changer"),
            fov    = g3:slider("FOV",30,120,68),
            x      = g3:slider("X",-20,20,0),
            y      = g3:slider("Y",-20,20,0),
            z      = g3:slider("Z",-20,20,0),
        },
        animBreaker = {
            enable  = g4:switch("Animation breaker"),
            options = g4:selectable("Options","Moonwalk (Slide)","Static Legs in Air","0 Pitch on Land"),
        },
        aspectRatioChanger = {
            enable      = g5:switch("Aspect ratio changer"),
            aspectRatio = g5:slider("Aspect ratio x100",30,300,133),
        },
        thirdPersonChanger = {
            enable   = g6:switch("Third person changer"),
            distance = g6:slider("Distance",25,200,100),
        },
    }
end

do
    local g1 = ui.create("HUD","Custom Killfeed")
    local g2 = ui.create("HUD","Floating Damage")
    local g3 = ui.create("HUD","Logs")
    menu.hud = {
        customKillfeed = {
            enable         = g1:switch("Custom killfeed"),
            advanced       = g1:switch("Advanced colors"),
            size           = g1:slider("Size",10,30,16),
            bg_active      = g1:color_picker("Active background",color(30,30,30,200)),
            bg_inactive    = g1:color_picker("Inactive background",color(15,15,15,200)),
            attacker_color = g1:color_picker("Attacker color",color(255,255,255,255)),
            attacked_color = g1:color_picker("Attacked color",color(255,50,50,255)),
            weapon_color   = g1:color_picker("Weapon color",color(255,255,255,255)),
            headshot_color = g1:color_picker("Headshot color",color(255,210,50,255)),
        },
        floatingDamage = {
            enable   = g2:switch("3D Floating damage"),
            color    = g2:color_picker("Color",color(255,69,69,255)),
            duration = g2:slider("Duration (s)",1,5,2),
        },
        logs = {
            options   = g3:selectable("Logs","console","hitlog indicator"),
            logOnshot = g3:switch("Log onshot status"),
        },
    }
end

do
    local g1 = ui.create("Misc","Clantag")
    local g2 = ui.create("Misc","Auto Buy")
    local g3 = ui.create("Misc","Movement")
    local g4 = ui.create("Misc","Chat")
    local g5 = ui.create("Misc","Servers")
    menu.misc = {
        clantag   = { enable = g1:switch("Animated clantag") },
        autoBuy   = {
            enable    = g2:switch("Auto buy"),
            primary   = g2:combo("Primary","-","scout","auto","awp"),
            secondary = g2:combo("Secondary","-","deagle"),
            equipment = g2:selectable("Equipment","armor","nades"),
        },
        fastLadder = { enable = g3:switch("Fast ladder") },
        smartDrop  = { enable = g3:switch("Smart drop"), bind = g3:hotkey("Smart drop key") },
        dropNades  = { enable = g3:switch("Drop nades"), bind = g3:hotkey("Drop nades key") },
        killsay    = { enable = g4:switch("Smart killsay") },
        serverJoiner = {
            join2x2 = g5:button("Join 2x2 Server", function()
                utils.console_exec("connect csgohvh.game.nfoservers.com:27015; password csgo2x2")
            end),
        },
    }
end

do
    local g = ui.create("Config","madrilla recode")
    local function save_db()
        local slot = menu.config.config_slot:get()
        local cfgs = db:get("mr_nl_configs") or {}
        cfgs[slot] = get_config_table(menu)
        db:set("mr_nl_configs", cfgs)
        common.add_event("[madrilla recode] Saved to "..slot,"floppy-disk")
    end
    local function load_db()
        local slot = menu.config.config_slot:get()
        local cfgs = db:get("mr_nl_configs") or {}
        if cfgs[slot] then
            load_config_table(menu, cfgs[slot])
            common.add_event("[madrilla recode] Loaded from "..slot,"folder-open")
        else
            common.add_event("[madrilla recode] No config in "..slot,"triangle-exclamation")
        end
    end
    local function export_cfg()
        print("[madrilla recode] "..serialize_config(get_config_table(menu)))
        common.add_event("[madrilla recode] Config printed to console","copy")
    end
    menu.config = {
        accent      = g:color_picker("Accent Color",color(255,96,71,255)),
        config_slot = g:combo("Config Slot","Slot 1","Slot 2","Slot 3","Slot 4","Slot 5"),
        db_save_btn = g:button("Save to Selected Slot",save_db),
        db_load_btn = g:button("Load from Selected Slot",load_db),
        export_btn  = g:button("Export to Console",export_cfg),
    }
end

ui.sidebar("madrilla recode","skull")

local function CalculateLFO(time, shape, speedPct, range, scaleVel)
    local speedHz = 0.5 + (speedPct/100) * 14.5
    if scaleVel then
        local lp = entity.get_local_player()
        if lp then
            local vel = lp.m_vecVelocity
            if vel then speedHz = speedHz * (1.0 + (math.sqrt(vel.x^2+vel.y^2)/250.0)*1.5) end
        end
    end
    local t = time * speedHz * 2 * math.pi
    if shape == "sine" then return math.sin(t)*range
    elseif shape == "triangle" then
        local val = (t/(2*math.pi))%1.0
        if val < 0.5 then return (val*4-1)*range else return ((1-val)*4-1)*range end
    elseif shape == "pulse" then return (math.sin(t)>0) and range or -range
    end
    return 0
end

local antiaim = {
    prev_sim_time=0, active_until=1, ticks=0, ticks_from_activation=0, active=false,
    bodyYawSide=false, bodyYawDelay=0, yawSide=false, yawAmmount=0, yawDelay=0,
    lastHit=false, inversionActive=false, yaw3WayState=0, yaw5WayState=0,
}

antiaim.GetKnifeTarget = function()
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return nil end
    local myPos = lp:get_origin()
    if not myPos then return nil end
    local closest, dist = nil, 230
    for _, t in ipairs(entity.get_players(true)) do
        if t ~= lp and t:is_alive() then
            local w = t:get_player_weapon()
            if w and w:get_classname() == "CKnife" then
                local ep = t:get_origin()
                if ep then
                    local d = math.sqrt((myPos.x-ep.x)^2+(myPos.y-ep.y)^2+(myPos.z-ep.z)^2)
                    if d < dist then dist=d; closest=t end
                end
            end
        end
    end
    return closest
end

antiaim.UpdateDefensive = function()
    local lp = entity.get_local_player()
    if not lp then return end
    local tc = globals.tickcount
    local st = lp:get_simulation_time()
    local sim = math.floor(st.current / globals.tickinterval)
    local diff = sim - antiaim.prev_sim_time
    if diff < 0 then
        local nc = utils.net_channel()
        local lat_t = nc and math.floor((nc.avg_latency[0]+nc.avg_latency[1])/globals.tickinterval) or 0
        local w = math.max(1, math.abs(diff) - lat_t)
        antiaim.active_until = tc + w
        antiaim.ticks = w
    end
    antiaim.prev_sim_time = sim
    if globals.choked_commands <= 1 then antiaim.active = antiaim.active_until > tc end
    if antiaim.active then antiaim.ticks_from_activation = antiaim.ticks - (antiaim.active_until - tc) + 1 end
end

antiaim.GetState = function()
    local lp = entity.get_local_player()
    local flags = lp.m_fFlags or 0
    local onGround = bit.band(flags,1) == 1
    local duckAmt = lp.m_flDuckAmount or 0
    local inDuck = duckAmt > 0.5
    local vel = lp.m_vecVelocity
    local speed = vel and math.sqrt(vel.x^2+vel.y^2) or 0
    if not onGround then
        if inDuck then
            local s = menu.antiaim.states["air crouched"]
            if s.overrideGlobal and s.overrideGlobal:get() then return s end
        else
            local s = menu.antiaim.states["air"]
            if s.overrideGlobal and s.overrideGlobal:get() then return s end
        end
        return menu.antiaim.states["global"]
    end
    if inDuck then
        if speed > 1.1 then
            local s = menu.antiaim.states["crouch moving"]
            if s.overrideGlobal and s.overrideGlobal:get() then return s end
        else
            local s = menu.antiaim.states["crouched"]
            if s.overrideGlobal and s.overrideGlobal:get() then return s end
        end
    end
    if speed > 1.1 then
        local s = menu.antiaim.states["moving"]
        if s.overrideGlobal and s.overrideGlobal:get() then return s end
    else
        local s = menu.antiaim.states["standing"]
        if s.overrideGlobal and s.overrideGlobal:get() then return s end
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
                local ep = lp:get_eye_position()
                local tp = target:get_origin()
                if ep and tp then
                    local dx,dy,dz = tp.x-ep.x, tp.y-ep.y, tp.z-ep.z
                    cmd.view_angles.y = math.deg(math.atan2(dy,dx))
                    cmd.view_angles.x = -math.deg(math.atan2(dz,math.sqrt(dx^2+dy^2)))
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
    if menu.antiaim.manualLeft:get()    then cmd.view_angles.y = cmd.view_angles.y - 90; return end
    if menu.antiaim.manualRight:get()   then cmd.view_angles.y = cmd.view_angles.y + 90; return end
    if menu.antiaim.manualBack:get()    then cmd.view_angles.y = cmd.view_angles.y + 180; return end
    if menu.antiaim.manualForward:get() then return end
    local state = antiaim.GetState()
    if state.forceDefensive and state.forceDefensive:get() then cmd.force_defensive = true end
    if antiaim.active and state.allowDefensive and state.allowDefensive:get() then
        local ds = menu.antiaim.states["defensive"]
        if ds.overrideGlobal and ds.overrideGlobal:get() then state = ds end
    end
    local ym = state.yawMode:get()
    if ym == "static" then
        antiaim.yawSide = true; antiaim.yawAmmount = state.yawOffset:get()
    elseif ym == "jitter" then
        if globals.choked_commands < 1 then antiaim.yawSide = not antiaim.yawSide; antiaim.yawAmmount = state.yawOffset:get()/2 end
    elseif ym == "delayed jitter" then
        if antiaim.yawDelay == 0 then
            antiaim.yawSide = not antiaim.yawSide
            antiaim.yawAmmount = state.yawOffset:get()/2
            antiaim.yawDelay = math.random(state.yawJitterDelayMin:get(), state.yawJitterDelayMax:get())
        else antiaim.yawDelay = antiaim.yawDelay - 1 end
    elseif ym == "random" then
        antiaim.yawSide = math.random(0,1)==1; antiaim.yawAmmount = math.random(-180,180)
    elseif ym == "spin" then
        antiaim.yawSide = true
        local a = (globals.tickcount*(360/30))%360
        antiaim.yawAmmount = a > 180 and a-360 or a
    elseif ym == "lfo" then
        antiaim.yawSide = true
        antiaim.yawAmmount = CalculateLFO(globals.realtime, state.yawLfoShape:get(), state.yawLfoSpeed:get(), state.yawLfoRange:get(), state.yawLfoVelocityScale:get())
    elseif ym == "switch" then
        if globals.tickcount % state.yawSwitchDelay:get() == 0 then antiaim.yawSide = not antiaim.yawSide end
        antiaim.yawAmmount = state.yawOffset:get()
    elseif ym == "3-way" then
        if globals.choked_commands < 1 then
            antiaim.yaw3WayState = (antiaim.yaw3WayState+1)%3
            local off = state.yawOffset:get()
            antiaim.yawAmmount = ({[0]=0,[1]=off,[2]=-off})[antiaim.yaw3WayState]
            antiaim.yawSide = true
        end
    elseif ym == "5-way" then
        if globals.choked_commands < 1 then
            antiaim.yaw5WayState = (antiaim.yaw5WayState+1)%5
            local off = state.yawOffset:get()
            local vals = {[0]=0,[1]=off/2,[2]=off,[3]=-off/2,[4]=-off}
            antiaim.yawAmmount = vals[antiaim.yaw5WayState]
            antiaim.yawSide = true
        end
    end
    local bym = state.bodyYawMode:get()
    local lfoBody, isBodyLfo = 0, false
    if bym == "delayed jitter" then
        if antiaim.bodyYawDelay == 0 then
            antiaim.bodyYawSide = not antiaim.bodyYawSide
            antiaim.bodyYawDelay = math.random(state.bodyYawJitterDelayMin:get(), state.bodyYawJitterDelayMax:get())
        else antiaim.bodyYawDelay = antiaim.bodyYawDelay - 1 end
    elseif bym == "jitter" then
        if globals.choked_commands < 1 then antiaim.bodyYawSide = not antiaim.bodyYawSide end
    elseif bym == "random" then
        if globals.choked_commands < 1 then antiaim.bodyYawSide = math.random(0,1)==1 end
    elseif bym == "lfo" then
        isBodyLfo = true
        lfoBody = CalculateLFO(globals.realtime, state.bodyYawLfoShape:get(), state.bodyYawLfoSpeed:get(), state.bodyYawLfoRange:get(), state.bodyYawLfoVelocityScale:get())
    end
    local finalYaw = antiaim.yawSide and antiaim.yawAmmount or -antiaim.yawAmmount
    local bodyOff  = state.bodyYawOffset:get()
    local finalBody = antiaim.bodyYawSide and bodyOff or -bodyOff
    if antiaim.inversionActive then
        finalYaw = -finalYaw; finalBody = -finalBody
        if isBodyLfo then lfoBody = -lfoBody end
    end
    if menu.antiaim.lbyBreaker:get() then
        local ts = globals.curtime % 0.22
        if ts < globals.tickinterval * 2 then
            finalBody = globals.tickcount%2==0 and 120 or -120
        end
    end
    rage.antiaim:override_hidden_pitch(state.pitchOffset:get())
    rage.antiaim:override_hidden_yaw_offset(isBodyLfo and lfoBody or finalBody)
    if state.fakeBreaker and state.fakeBreaker:get() then
        if globals.choked_commands == 2 then rage.antiaim:override_hidden_yaw_offset(0)
        else rage.antiaim:override_hidden_yaw_offset(antiaim.bodyYawSide and 120 or -120) end
    end
    cmd.view_angles.y = cmd.view_angles.y + finalYaw
end

antiaim.OnRoundStart = function()
    antiaim.prev_sim_time=0; antiaim.active_until=1; antiaim.ticks=0
    antiaim.ticks_from_activation=0; antiaim.active=false; antiaim.inversionActive=false
    antiaim.yaw3WayState=0; antiaim.yaw5WayState=0
end

local hit_this_tick = 0
local antiBrutePhase = 0

local function TriggerAntiBrute()
    local action = menu.antiaim.antiBruteAction:get()
    if action == "Invert Side" then antiaim.inversionActive = not antiaim.inversionActive
    elseif action == "Randomize" then
        antiaim.inversionActive = math.random(1,2)==1
        antiaim.yaw3WayState = math.random(0,2)
        antiaim.yaw5WayState = math.random(0,4)
    elseif action == "Cycle 3-way" then
        antiBrutePhase = (antiBrutePhase+1)%3
        if antiBrutePhase==0 then antiaim.inversionActive=false; antiaim.yaw3WayState=0
        elseif antiBrutePhase==1 then antiaim.inversionActive=true; antiaim.yaw3WayState=1
        else antiaim.inversionActive = not antiaim.inversionActive; antiaim.yaw3WayState=2 end
    end
end

events.weapon_fire:set(function(e)
    if not menu.antiaim.invertOnShot:get() then return end
    if entity.get(e.userid,true) == entity.get_local_player() then
        antiaim.inversionActive = not antiaim.inversionActive
    end
end)

events.player_hurt:set(function(e)
    local me = entity.get_local_player()
    if entity.get(e.userid,true) ~= me then return end
    hit_this_tick = globals.tickcount
    if menu.antiaim.invertOnHit:get() then antiaim.inversionActive = not antiaim.inversionActive end
    if menu.antiaim.antiBrute:get() then
        for _,m in ipairs(menu.antiaim.antiBruteModes:get()) do
            if m=="On Hit" then TriggerAntiBrute(); break end
        end
    end
end)

events.bullet_impact:set(function(e)
    if not menu.antiaim.antiBrute:get() then return end
    local has_miss = false
    for _,m in ipairs(menu.antiaim.antiBruteModes:get()) do if m=="On Miss" then has_miss=true; break end end
    if not has_miss then return end
    local shooter = entity.get(e.userid,true)
    local me = entity.get_local_player()
    if not shooter or not me or shooter==me then return end
    if shooter.m_iTeamNum == me.m_iTeamNum then return end
    local sh = shooter:get_hitbox_position(0)
    local mo = me:get_origin()
    if not sh or not mo then return end
    local lx,ly,lz = e.x-sh.x, e.y-sh.y, e.z-sh.z
    local len2 = lx^2+ly^2+lz^2
    local mx,my,mz = mo.x, mo.y, mo.z+32
    local dist
    if len2 == 0 then
        dist = math.sqrt((mx-sh.x)^2+(my-sh.y)^2+(mz-sh.z)^2)
    else
        local t = math.max(0, math.min(1, ((mx-sh.x)*lx+(my-sh.y)*ly+(mz-sh.z)*lz)/len2))
        dist = math.sqrt((mx-(sh.x+t*lx))^2+(my-(sh.y+t*ly))^2+(mz-(sh.z+t*lz))^2)
    end
    if dist < 64 then
        utils.execute_after(0, function()
            if hit_this_tick == globals.tickcount then return end
            TriggerAntiBrute()
        end)
    end
end)

local misc_clantag_frames = {
    "m","ma","mad","madr","madri","madril","madrilla","madrilla","madrilla |",
    "madrilla | m","madrilla | ma","madrilla | mad","madrilla | madr","madrilla | madri",
    "madrilla | madril","madrilla | madrill","madrilla | madrilla","madrilla | madrilla",
    "madrilla recode","madrilla recode","madrilla recode",
    "madrilla | madrilla","madrilla | madrill","madrilla | madril","madrilla | madri",
    "madrilla | madr","madrilla | mad","madrilla | ma","madrilla | m","madrilla |",
    "madrilla","madril","madri","madr","mad","ma","m"
}
local clantag_last = ""

local killsay_phrases = {
    "madrilla recode > you","sit down dog","1","uid issue",
    "my resolver > your fake","0.22s caught you lacking",
    "hit by unleaked private madrilla recode method",
    "private lua > your pasted garbage",
    "unleaked LBY tracker doing work",
    "hit by a private build invite only",
    "imagine getting resolved by a private build",
    "madrilla recode private alpha invite only",
    "id give you the lua but its private and unleaked",
    "youre playing checkers im playing with a private build",
    "0.22s state machine = you are dead",
    "cant buy this method invite only sorry",
    "madrilla recode strictly private",
    "my anti-aim is unleaked your anti-aim is public source",
    "another victim to the private resolver",
    "madrilla recode dev build hits different",
    "stop trying you literally cant beat unleaked math",
    "getting tapped by a private lua sad",
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
    "getting tapped by madrillas private madrilla recode",
    "tappa klause just delivered your death",
    "merry christmas from tappa klause",
    "tappa klause leaving coal in your inventory",
    "breaking your LC like its absolutely nothing",
    "lag compensation never heard of it",
    "madrilla recode LC > your pasted movement",
}

local misc_smartdrop = { ticks=0, oldPitch=nil, going=false }
local misc_dropnades = { state=0, oldPitch=nil }
local misc_buycmds = {
    ["-"]="",["scout"]="buy ssg08",["auto"]="buy g3sg1; buy scar20",["awp"]="buy awp",
    ["deagle"]="buy deagle",["armor"]="buy vesthelm",["nades"]="buy molotov; buy incgrenade; buy hegrenade; buy smokegrenade",
}

local function misc_run_clantag()
    if not menu.misc.clantag.enable:get() then
        if clantag_last ~= "" then common.set_clan_tag(""); clantag_last="" end
        return
    end
    local fi = math.floor(globals.tickcount/25) % #misc_clantag_frames + 1
    local f = misc_clantag_frames[fi]
    if f ~= clantag_last then common.set_clan_tag(f); clantag_last=f end
end

local function misc_run_fastladder(cmd)
    if not menu.misc.fastLadder.enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or lp.m_MoveType ~= 9 then return end
    if cmd.forwardmove == 0 then return end
    local ln = lp.m_vecLadderNormal
    if not ln then return end
    local lnl = math.sqrt(ln.x^2+ln.y^2)
    if lnl < 0.01 then return end
    local pt = math.deg(math.atan2(ln.z+lnl, lnl-ln.z))
    local ps = cmd.view_angles.x < pt and -1 or 1
    if cmd.forwardmove < 0 then ps = ps * -1 end
    cmd.view_angles.x = 89 * ps
    cmd.view_angles.y = math.deg(math.atan2(ln.x, -ln.y))
    cmd.forwardmove = 450
    cmd.sidemove = 0
end

local function misc_run_smartdrop(cmd)
    if not menu.misc.smartDrop.enable:get() then return end
    local pressed = menu.misc.smartDrop.bind:get()
    if pressed and not misc_smartdrop.going then
        misc_smartdrop.going=true; misc_smartdrop.ticks=0; misc_smartdrop.oldPitch=cmd.view_angles.x
        cmd.view_angles.x=0
    end
    if misc_smartdrop.going then
        misc_smartdrop.ticks = misc_smartdrop.ticks+1
        if misc_smartdrop.ticks==3 then utils.console_exec("drop") end
        if misc_smartdrop.ticks==6 and misc_smartdrop.oldPitch then cmd.view_angles.x=misc_smartdrop.oldPitch end
        if misc_smartdrop.ticks>6 and not pressed then misc_smartdrop.going=false end
    end
end

local function misc_run_autobuy()
    if not menu.misc.autoBuy.enable:get() then return end
    utils.console_exec(misc_buycmds[menu.misc.autoBuy.primary:get()] or "")
    utils.console_exec(misc_buycmds[menu.misc.autoBuy.secondary:get()] or "")
    for _,item in pairs(menu.misc.autoBuy.equipment:get()) do
        utils.console_exec(misc_buycmds[item] or "")
    end
end

events.player_death:set(function(e)
    if not menu.misc.killsay.enable:get() then return end
    local lp = entity.get_local_player()
    local att = entity.get(e.attacker,true)
    local vic = entity.get(e.userid,true)
    if att==lp and vic~=lp then
        utils.console_exec("say "..killsay_phrases[math.random(1,#killsay_phrases)])
    end
end)

local FEED_MAX, FADE_TIME, ENTRY_H, ENTRY_PAD, BOX_W = 10, 5.0, 22, 4, 310
local killfeed_entries = {}
local floating_damages = {}

events.player_death:set(function(e)
    if not menu.hud.customKillfeed.enable:get() then return end
    local lp = entity.get_local_player()
    local att = entity.get(e.attacker,true)
    local vic = entity.get(e.userid,true)
    table.insert(killfeed_entries,1,{
        attacker=att and att:get_name() or "?",
        attacked=vic and vic:get_name() or "?",
        weapon=e.weapon or "?", headshot=e.headshot==1,
        time=globals.realtime,
        me_attack=(att==lp), me_victim=(vic==lp),
    })
    while #killfeed_entries>FEED_MAX do table.remove(killfeed_entries) end
end)

events.player_hurt:set(function(e)
    if not menu.hud.floatingDamage.enable:get() then return end
    local lp = entity.get_local_player()
    if entity.get(e.attacker,true)~=lp then return end
    local vic = entity.get(e.userid,true)
    if not vic then return end
    local pos = vic:get_hitbox_position(0)
    if not pos then return end
    table.insert(floating_damages,{
        damage=e.dmg_health or 0, pos=pos, born=globals.realtime,
        duration=menu.hud.floatingDamage.duration:get(),
    })
end)

events.render:set(function()
    if not globals.is_in_game then return end
    local now = globals.realtime
    local sz  = menu.hud.customKillfeed.size:get()
    local fnt = render.load_font("Verdana",sz,"ab")
    local sw, sh = render.screen_size()

    if menu.hud.customKillfeed.enable:get() then
        local adv   = menu.hud.customKillfeed.advanced:get()
        local catt  = adv and menu.hud.customKillfeed.attacker_color:get() or color(255,255,255,255)
        local cvic  = adv and menu.hud.customKillfeed.attacked_color:get()  or color(255,50,50,255)
        local cwpn  = adv and menu.hud.customKillfeed.weapon_color:get()    or color(200,200,200,255)
        local chs   = adv and menu.hud.customKillfeed.headshot_color:get()  or color(255,210,50,255)
        local cbga  = adv and menu.hud.customKillfeed.bg_active:get()       or color(30,30,30,200)
        local cbgi  = adv and menu.hud.customKillfeed.bg_inactive:get()     or color(15,15,15,200)
        local bx    = sw - BOX_W - 14
        local by    = 14
        for i,ent in ipairs(killfeed_entries) do
            local age = now - ent.time
            if age > FADE_TIME then break end
            local al = 1.0
            if age > FADE_TIME-1.0 then al = FADE_TIME-age
            elseif age < 0.3 then al = age/0.3 end
            local ey = by + (i-1)*(ENTRY_H+ENTRY_PAD)
            local active = age < 3.0
            local bg = active and cbga or cbgi
            render.filled_rect(vector(bx,ey), vector(BOX_W,ENTRY_H), color(bg.r,bg.g,bg.b,math.floor(bg.a*al)))
            render.rect(vector(bx,ey), vector(BOX_W,ENTRY_H), color(50,50,50,math.floor(100*al)))
            local accent = active and color(255,96,71,math.floor(230*al)) or color(80,80,80,math.floor(150*al))
            render.filled_rect(vector(bx,ey), vector(3,ENTRY_H), accent)
            local ty = ey + (ENTRY_H-sz)/2
            local px = bx+8
            local fa = math.floor(255*al)
            render.text(fnt, vector(px,ty), color(catt.r,catt.g,catt.b,fa), ent.attacker)
            px = px + render.text_size(fnt, ent.attacker) + 5
            render.text(fnt, vector(px,ty), color(cwpn.r,cwpn.g,cwpn.b,fa), "["..ent.weapon.."]")
            px = px + render.text_size(fnt, "["..ent.weapon.."]") + 5
            if ent.headshot then
                render.text(fnt, vector(px,ty), color(chs.r,chs.g,chs.b,fa), "[hs]")
                px = px + render.text_size(fnt, "[hs]") + 5
            end
            render.text(fnt, vector(px,ty), color(cvic.r,cvic.g,cvic.b,fa), ent.attacked)
        end
    end

    if menu.hud.floatingDamage.enable:get() then
        local dc = menu.hud.floatingDamage.color:get()
        local i = 1
        while i <= #floating_damages do
            local fd = floating_damages[i]
            local age = now - fd.born
            if age >= fd.duration then
                table.remove(floating_damages, i)
            else
                local prog = age/fd.duration
                local al = math.floor(255*(1-prog))
                local wp = vector(fd.pos.x, fd.pos.y, fd.pos.z+10+prog*30)
                local sx, sy = render.world_to_screen(wp)
                if sx and sy then
                    local lbl = "-"..tostring(fd.damage)
                    render.text(fnt, vector(sx - render.text_size(fnt,lbl)/2, sy), color(dc.r,dc.g,dc.b,al), lbl)
                end
                i = i+1
            end
        end
    end
end)

local resolver_data = {}
local lag_records   = {}

local DESYNC_MAX = 58.0

local function angle_diff(a,b)
    local d = (a-b)%360
    if d>180 then d=d-360 end
    if d<-180 then d=d+360 end
    return d
end

local function clamp(v,lo,hi) return v<lo and lo or v>hi and hi or v end

local function init_rd(i)
    resolver_data[i] = {
        resolved_side=0, resolved_desync=0, last_side=0, committed_side=0,
        misses=0, brute_phase=0, last_logged_side=0, side_votes={},
        lby_confirmed=false, lby_trigger="none", max_desync=0,
    }
end

for i=1,65 do lag_records[i]={}; init_rd(i) end

local function commit_side(data, raw, weight)
    weight = weight or 1
    local v = data.side_votes
    for _=1,weight do table.insert(v,raw) end
    while #v>10 do table.remove(v,1) end
    local pos,neg=0,0
    local s = math.max(1,#v-5)
    for i=s,#v do if v[i]>0 then pos=pos+1 else neg=neg+1 end end
    local total = pos+neg
    if total==0 then return data.committed_side end
    if pos/total>0.6 then data.committed_side=1
    elseif neg/total>0.6 then data.committed_side=-1
    end
    if data.committed_side==0 then data.committed_side=raw end
    return data.committed_side
end

local function calc_max_desync(astate)
    if not astate then return DESYNC_MAX end
    local spd = astate.velocity_length_xy or 0
    local duck = astate.anim_duck_amount or 0
    local wrt  = astate.walk_run_transition or 0
    local sw = spd/(260*0.52)
    local sr = spd/(260*0.34)
    local w = sw<1 and (1+(0.8-1)*sw) or 0.8
    w = w + wrt*(0.5-w)
    if duck > 0 then w = w + duck*(math.min(sr,1))*(0.5-w) end
    return DESYNC_MAX * math.max(0,math.min(1,w))
end

local function do_freestanding(player)
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return 0 end
    local ep = lp:get_eye_position()
    local hp = player:get_hitbox_position(0)
    if not ep or not hp then return 0 end
    local yaw = math.deg(math.atan2(hp.y-ep.y, hp.x-ep.x))
    local off = menu.ragebot.resolver.freestandingWidth:get()
    local lyr = math.rad(yaw+90)
    local ryr = math.rad(yaw-90)
    local lf = vector(hp.x+math.cos(lyr)*off, hp.y+math.sin(lyr)*off, hp.z)
    local rf = vector(hp.x+math.cos(ryr)*off, hp.y+math.sin(ryr)*off, hp.z)
    local tl = utils.trace_line(lf, ep, lp)
    local tr = utils.trace_line(rf, ep, lp)
    if tl.fraction < tr.fraction then return 1
    elseif tr.fraction < tl.fraction then return -1 end
    return 0
end

local function resolve_player(player)
    local idx = player:get_index()
    if not idx then return end
    local recs = lag_records[idx]
    if not recs or #recs < 2 then return end
    local data = resolver_data[idx]
    local astate = player:get_anim_state()
    if not astate then return end
    local max_d = calc_max_desync(astate)
    local eye_ang = player.m_angEyeAngles
    local ey = eye_ang and eye_ang.y or 0
    local gfy = astate.move_yaw_ideal or 0
    local cfy = astate.abs_yaw or 0
    local dg  = angle_diff(ey, gfy)
    local dc  = angle_diff(ey, cfy)
    local gc  = angle_diff(gfy, cfy)
    local side, actual = 0, 0

    local jitter = false
    if #recs >= 3 then
        local ds1 = angle_diff(recs[#recs].eye_yaw, recs[#recs].gfy)
        local ds2 = angle_diff(recs[#recs-1].eye_yaw, recs[#recs-1].gfy)
        local ds3 = angle_diff(recs[#recs-2].eye_yaw, recs[#recs-2].gfy)
        if (ds1>5 and ds2<-5 and ds3>5) or (ds1<-5 and ds2>5 and ds3<-5) then jitter=true end
    end

    if jitter then
        side = data.last_side~=0 and data.last_side or 1; actual=0
    elseif math.abs(gc)>8 then
        side = dc>0 and 1 or -1; actual = clamp(math.abs(dc),0,max_d)
    elseif math.abs(dg)>5 then
        side = dg>0 and 1 or -1; actual = clamp(math.abs(dg),0,max_d)
    else
        local fs = menu.ragebot.resolver.freestanding:get() and do_freestanding(player) or 0
        local ss = 0
        if #recs>=4 then
            local pos,neg=0,0
            for i=math.max(1,#recs-5),#recs do
                local r=recs[i]; local p=recs[i-1]
                if p then
                    local dv=(r.vx or 0)-(p.vx or 0)
                    if dv>2 then pos=pos+1 elseif dv<-2 then neg=neg+1 end
                end
            end
            if pos>neg+1 then ss=1 elseif neg>pos+1 then ss=-1 end
        end
        side = fs~=0 and fs or ss~=0 and ss or data.last_side~=0 and data.last_side or -1
        actual = max_d*0.5
    end

    if data.misses>0 then
        local ph=data.brute_phase
        if ph==1 then side=-side; actual=max_d
        elseif ph==2 then actual=max_d*0.5
        elseif ph==3 then actual=0
        else data.brute_phase=0 end
    end

    local lr  = recs[#recs]
    local lpr = recs[#recs-1]
    local is_lby, lby_tag = false, "anim"
    local l3 = player:get_anim_overlay(3)
    if l3 and lpr then
        if l3.cycle < (lpr.l3c or 0) and l3.weight_delta_rate > 0 then
            is_lby=true; lby_tag="layer_cycle_reset"
        elseif l3.weight>0 and (lpr.l3w or 0)==0 then
            is_lby=true; lby_tag="layer_weight"
        end
    end
    if not is_lby and lr and (lr.lby_delta or 0)>15 then is_lby=true; lby_tag="lby_delta" end

    if is_lby then
        local lby_side = dc>0 and 1 or -1
        local stable   = commit_side(data, lby_side, 3)
        data.resolved_side=stable; data.resolved_desync=max_d; data.max_desync=max_d
        data.lby_confirmed=true; data.lby_trigger=lby_tag
        return stable, max_d, max_d
    end

    data.lby_confirmed=false; data.lby_trigger="none"
    data.last_side = side
    local stable = commit_side(data, side)
    data.resolved_side=stable; data.resolved_desync=actual; data.max_desync=max_d
    return stable, actual, max_d
end

events.net_update_end:set(function()
    if not menu.ragebot.resolver.enable:get() then return end
    local should_log = menu.ragebot.resolver.log:get()
    local enemies = entity.get_players(true)
    for _,p in ipairs(enemies) do
        local idx = p:get_index()
        if p:is_alive() and not p:is_dormant() then
            local astate = p:get_anim_state()
            local vel = p.m_vecVelocity
            local l3 = p:get_anim_overlay(3)
            local ea = p.m_angEyeAngles
            local ey = ea and ea.y or 0
            local cfy = astate and (astate.abs_yaw or 0) or 0
            local gfy = astate and (astate.move_yaw_ideal or 0) or 0
            local prev = lag_records[idx]
            local prev_r = prev and prev[#prev]
            local lby_d = 0
            if prev_r then lby_d = math.abs(angle_diff(cfy, prev_r.cfy or cfy)) end
            local vx = vel and vel.x or 0
            local vy = vel and vel.y or 0
            local rec = {
                eye_yaw=ey, gfy=gfy, cfy=cfy,
                vx=vx, vy=vy, lby_delta=lby_d,
                l3c=l3 and l3.cycle or 0, l3w=l3 and l3.weight or 0,
            }
            table.insert(lag_records[idx], rec)
            while #lag_records[idx]>32 do table.remove(lag_records[idx],1) end
        else
            lag_records[idx]={}
        end
    end
    for _,p in ipairs(enemies) do
        local idx = p:get_index()
        if p:is_alive() and not p:is_dormant() then
            local side, actual, max_d = resolve_player(p)
            if side and actual and should_log then
                local data = resolver_data[idx]
                if data.last_logged_side ~= side then
                    local val = clamp(side*actual, -DESYNC_MAX, DESYNC_MAX)
                    local tag = data.lby_confirmed and ("LBY["..data.lby_trigger.."]") or "anim"
                    print(string.format("[madrilla recode] resolved %s | side:%s | yaw:%d | max:%d | src:%s | misses:%d",
                        p:get_name(), side>0 and "R" or "L", math.floor(val), math.floor(max_d or 0), tag, data.misses))
                    data.last_logged_side = side
                end
            end
        end
    end
end)

local rb_miss = {}
local rb_safepoint_next = false

events.aim_ack:set(function(e)
    if not menu.ragebot.resolver.enable:get() and not menu.ragebot.ragebotHelper.enable:get() then return end
    local target = e.target
    if not target then return end
    local idx = target:get_index()
    if not idx then return end
    local data = resolver_data[idx]
    if data then
        if e.state == nil then
            data.misses=0; data.brute_phase=0
        else
            local reason = e.state or ""
            if reason=="missed" or reason=="prediction error" or reason=="?" then
                data.misses=data.misses+1
                data.brute_phase=(data.brute_phase%4)+1
                if menu.ragebot.resolver.log:get() then
                    print(string.format("[madrilla recode] miss on %s | reason:%s | total:%d | phase:%d",
                        target:get_name(), reason, data.misses, data.brute_phase))
                end
            end
        end
    end
    if not rb_miss[idx] then rb_miss[idx]=0 end
    if e.state == nil then
        rb_miss[idx]=0; rb_safepoint_next=false
        if menu.hud.logs.logOnshot:get() then
            local opts={}; for _,v in ipairs(menu.hud.logs.options:get()) do opts[v]=true end
            if opts["console"] then print("[madrilla recode] hit "..target:get_name()) end
            if opts["hitlog indicator"] then common.add_event("hit "..target:get_name(),"crosshairs") end
        end
    else
        local reason = e.state or ""
        if reason=="missed" or reason=="prediction error" or reason=="?" then
            rb_miss[idx]=rb_miss[idx]+1
            if menu.hud.logs.logOnshot:get() then
                local opts={}; for _,v in ipairs(menu.hud.logs.options:get()) do opts[v]=true end
                if opts["console"] then
                    print(string.format("[madrilla recode] miss on %s | reason:%s | total:%d", target:get_name(), reason, rb_miss[idx]))
                end
            end
            if menu.ragebot.autoSafepoint.enable:get() then
                for _,v in ipairs(menu.ragebot.autoSafepoint.options:get()) do
                    if v=="on miss" then rb_safepoint_next=true; break end
                end
            end
        end
    end
end)

local function ragebot_run_createmove(cmd)
    if not menu.ragebot.ragebotHelper.enable:get() then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local target = entity.get_threat(true)
    if not target then return end
    if rb_safepoint_next or menu.ragebot.ragebotHelper.avoidUnsafeHitboxes:get() then
        rage.override_safepoint(target, true)
    end
    if menu.ragebot.autoSafepoint.enable:get() then
        local opts={}; for _,v in ipairs(menu.ragebot.autoSafepoint.options:get()) do opts[v]=true end
        local flags = lp.m_fFlags or 0
        if opts["in air"] and bit.band(flags,1)==0 then rage.override_safepoint(target,true) end
    end
    rage.override_min_damage(target, menu.ragebot.ragebotHelper.minDamage:get())
    rage.override_hitchance(target, menu.ragebot.ragebotHelper.hitChance:get())
    if menu.ragebot.multiDT.enable:get() then
        if menu.ragebot.multiDT.key1:get() or menu.ragebot.multiDT.key2:get() or menu.ragebot.multiDT.key3:get() then
            rage.override_double_tap(true)
        end
    end
end

events.round_start:set(function()
    antiaim.OnRoundStart()
    utils.execute_after(0.2, misc_run_autobuy)
    for i=1,65 do lag_records[i]={}; init_rd(i) end
end)

events.level_init:set(function()
    antiaim.OnRoundStart()
    for i=1,65 do lag_records[i]={}; init_rd(i) end
end)

events.createmove:set(function(cmd)
    if not globals.is_in_game then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    antiaim.OnSetupCommand(cmd)
    misc_run_clantag()
    misc_run_fastladder(cmd)
    misc_run_smartdrop(cmd)
    ragebot_run_createmove(cmd)
end)

events.shutdown:set(function()
    rage.antiaim:override_hidden_pitch(nil)
    rage.antiaim:override_hidden_yaw_offset(nil)
    common.set_clan_tag("")
end)

math.randomseed(common.get_unixtime())
print("[madrilla recode] loaded on neverlose")
common.add_event("[madrilla recode] loaded","skull")
