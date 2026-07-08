local menu = require("madrilla_recode/menu")
local pui = require("gamesense/pui")
local antiaim_funcs = require("gamesense/antiaim_funcs")
local entityLib = require("gamesense/entity")

local hitgroups = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}
local images = require("gamesense/images")
local csgo_weapons = require("gamesense/csgo_weapons")
local vector = require("vector")
local solus_ui = require("madrilla_recode/solus_ui")
local logDamageDealt = pui.reference("Misc", "Miscellaneous", "Log damage dealt")
local logSpreadMisses = pui.reference("Rage", "Other", "Log misses due to spread")

local doubleTapEnable, doubleTapKey = ui.reference("Rage", "Aimbot", "Double tap")

local minDamageEnable, minDamageTapKey, minDamageValue = ui.reference("Rage", "Aimbot", "Minimum damage override")

local damageValue = ui.reference("Rage", "Aimbot", "Minimum damage")

local viewModelFOV = cvar.viewmodel_fov
local viewModelOffsetX = cvar.viewmodel_offset_x
local viewModelOffsetY = cvar.viewmodel_offset_y
local viewModelOffsetZ = cvar.viewmodel_offset_z
local camIdealdist = cvar.cam_idealdist

local aspectRation = cvar.r_aspectratio

local originalViewModelFOV = viewModelFOV:get_float()
local originalViewModelOffsetX = viewModelOffsetX:get_float()
local originalViewModelOffsetY = viewModelOffsetY:get_float()
local originalViewModelOffsetZ = viewModelOffsetZ:get_float()
local originalAspectRatio = aspectRation:get_float()
local originalCamIdealDist = camIdealdist:get_float()

local notify = {}
notify.queue = {}

function notify.push(text)
    table.insert(notify.queue, {
        text = text,
        time = globals.realtime(),
        y_offset = 0,
        alpha = 0
    })
end

local function push_notify(text)
    notify.push(text)
end

local text_cache = {}
local function cached_measure_text(flags, text)
    if not flags then flags = "" end
    if not text then text = "" end
    local key = tostring(flags) .. "_" .. tostring(text)
    if not text_cache[key] then
        local w, h = renderer.measure_text(flags, text)
        text_cache[key] = {w = w, h = h}
    end
    return text_cache[key].w, text_cache[key].h
end

function notify.render()
    local r, g, b, a_cfg = ui.get(menu.config.accent)
    local screen_x, screen_y = client.screen_size()
    
    local active_count = 0
    for i = #notify.queue, 1, -1 do
        local msg = notify.queue[i]
        local time_alive = globals.realtime() - msg.time
        
        if time_alive > 4 then
            table.remove(notify.queue, i)
        else
            active_count = active_count + 1
            
            local alpha_target = 1.0
            if time_alive < 0.2 then
                alpha_target = time_alive / 0.2
            elseif time_alive > 3.5 then
                alpha_target = (4.0 - time_alive) / 0.5
            end
            
            msg.alpha = solus_ui.lerp(msg.alpha, alpha_target, 0.1)
            
            local target_y = active_count * 25
            msg.y_offset = solus_ui.lerp(msg.y_offset, target_y, 0.1)
            
            local text_w = renderer.measure_text("", msg.text)
            local w = text_w + 20
            local h = 20
            
            local x = screen_x / 2 - w / 2
            local y = screen_y - 80 - msg.y_offset
            
            solus_ui.container_glow(x, y, w, h, r, g, b, 200 * msg.alpha, msg.alpha, r, g, b)
            renderer.text(x + 10, y + 4, 255, 255, 255, 255 * msg.alpha, "", 0, msg.text)
        end
    end
end

local function contains(table, val)
    if type(table) ~= "table" then return false end
    for i = 1, #table do
        if table[i] == val then return true end
    end
    return false
end

-- Custom Chat & Money State
local chat_history = {}
local is_typing = false
local typing_text = ""
local current_money = 0
local displayed_money = 0
local money_delta_time = 0
local money_delta_val = 0
local panorama_initialized = false
local was_chat_enabled = nil
local was_money_enabled = nil

client.set_event_callback("player_connect_full", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        panorama_initialized = false
        was_chat_enabled = nil
        was_money_enabled = nil
    end
end)

local function init_panorama_hooks()
    if panorama_initialized then return end
    local js = [[
        var madrilla_hud_api = {
            chat_visible: true,
            money_visible: true,
            update: function() {
                try {
                    var chat = $.GetContextPanel().FindChildTraverse("HudChat");
                    var dbg = "";
                    
                    if (!chat) {
                        var search_panel = function(panel) {
                            if (!panel) return null;
                            var id = panel.id;
                            if (id && (id.indexOf("Chat") !== -1 || id.indexOf("chat") !== -1)) {
                                if (id === "ChatLinesContainer" || id === "ChatInput") return null;
                                return panel;
                            }
                            var children = panel.Children();
                            if (children) {
                                for (var i = 0; i < children.length; i++) {
                                    var found = search_panel(children[i]);
                                    if (found) return found;
                                }
                            }
                            return null;
                        };
                        var found_chat = search_panel($.GetContextPanel());
                        if (found_chat) {
                            chat = found_chat;
                            dbg += "Found:" + chat.id + " ";
                        } else {
                            dbg += "ChatNull ";
                        }
                    }
                    
                    var is_typing = false;
                    var text = "";
                    
                    if (chat) {
                        var lines = chat.FindChildTraverse("ChatLinesContainer") || chat.FindChildTraverse("chat-lines");
                        var input = chat.FindChildTraverse("ChatInput") || chat.FindChildTraverse("chat-input");
                        
                        if (!this.chat_visible) {
                            if (lines) lines.style.visibility = "collapse";
                            if (input) input.style.opacity = "0.0";
                        } else {
                            if (lines) lines.style.visibility = "visible";
                            if (input) input.style.opacity = "1.0";
                        }
                        
                        if (chat.BHasClass("Active") || chat.BHasClass("active") || chat.BHasClass("chat-open")) is_typing = true;
                        dbg += "C(" + (chat.BHasClass("Active")?"A":"") + ") ";
                        
                        if (input) {
                            if (input.BHasClass("Active") || input.BHasClass("active")) is_typing = true;
                            if (!input.BHasClass("hidden") && !input.BHasClass("Hidden")) is_typing = true;
                            if (input.BHasKeyFocus && input.BHasKeyFocus()) is_typing = true;
                            
                            dbg += "I(" + (input.BHasClass("hidden")?"h":"") + ") ";
                            
                            var entry = input.FindChildTraverse("ChatInputTextEntry") || input.FindChildTraverse("TextEntry");
                            if (entry) {
                                dbg += "E(" + (entry.BHasKeyFocus && entry.BHasKeyFocus()?"f":"") + ") ";
                                if (entry.BHasKeyFocus && entry.BHasKeyFocus()) is_typing = true;
                                text = entry.text || "";
                            } else {
                                dbg += "NoE ";
                                text = input.text || "";
                            }
                        } else {
                            dbg += "NoInput[";
                            var children = chat.Children();
                            if (children) {
                                for (var i = 0; i < children.length; i++) {
                                    if (children[i] && children[i].id) {
                                        dbg += children[i].id + ",";
                                    }
                                }
                            }
                            dbg += "] ";
                        }
                    }
                    
                    if (text === "") {
                        text = dbg;
                    }
                    
                    $.madrilla_recode_is_typing = is_typing;
                    $.madrilla_recode_typing_text = text;
                    
                    var money = $.GetContextPanel().FindChildTraverse("HudMoney");
                    if (money) {
                        money.style.opacity = this.money_visible ? "1.0" : "0.0";
                    }
                } catch(e) {
                    $.madrilla_recode_is_typing = false;
                    $.madrilla_recode_typing_text = "ERR: " + e.toString();
                }
                
                $.Schedule(0.05, this.update.bind(this));
            },
            set_chat_visible: function(visible) {
                this.chat_visible = visible;
            },
            set_money_visible: function(visible) {
                this.money_visible = visible;
            }
        };
        $.GetContextPanel().madrilla_hud_api = madrilla_hud_api;
        madrilla_hud_api.update();
    ]]
    panorama.loadstring(js, "CSGOHud")()
    panorama_initialized = true
end

local function toggle_native_hud(element, visible)
    init_panorama_hooks()
    local js = string.format("if ($.GetContextPanel().madrilla_hud_api) { $.GetContextPanel().madrilla_hud_api.set_%s_visible(%s); }", element, tostring(visible))
    panorama.loadstring(js, "CSGOHud")()
end

local function get_grenades(player)
	local nades = {}
	for i = 0, 64 do
		local weapon = entity.get_prop(player, "m_hMyWeapons", i)
		if weapon ~= nil then
			local wpn_data = csgo_weapons(weapon)
			if wpn_data ~= nil and wpn_data.type == "grenade" then
				table.insert(nades, wpn_data.idx)
			end
		end
	end
	return nades
end

visuals = {
    offset = 0,
    floating_damage = {},
    ground_ticks = 0,
    onshot_tracker = {},
    RenderCenterInd = function(text, flags, r, g, b, a)
        local screensize = {} 
        screensize.x, screensize.y = client.screen_size()

        local pos = {}
        pos.x = screensize.x / 2 
        pos.y = screensize.y / 2 + visuals.offset

        renderer.text(pos.x, pos.y, r, g, b, a, flags, 0, text)

        local width, height = cached_measure_text(flags, text)

        visuals.offset = visuals.offset + height
    end,

    ResetViewModelChanger = function()
        viewModelFOV:set_raw_float(originalViewModelFOV)
        viewModelOffsetX:set_raw_float(originalViewModelOffsetX)
        viewModelOffsetY:set_raw_float(originalViewModelOffsetY)
        viewModelOffsetZ:set_raw_float(originalViewModelOffsetZ)
    end,

    ViewModelChanger = function()
        if not ui.get(menu.visuals.viewModelChanger.enable) then 
            visuals.ResetViewModelChanger()
            return
        end

        local localPlayer = entity.get_local_player()
        if not localPlayer or not entity.is_alive(localPlayer) then return end

        viewModelFOV:set_raw_float(ui.get(menu.visuals.viewModelChanger.fov))
        viewModelOffsetX:set_raw_float(ui.get(menu.visuals.viewModelChanger.x))
        viewModelOffsetY:set_raw_float(ui.get(menu.visuals.viewModelChanger.y))
        viewModelOffsetZ:set_raw_float(ui.get(menu.visuals.viewModelChanger.z))
    end,

    ResetAspectRatioChanger = function()
        aspectRation:set_raw_float(originalAspectRatio)
    end,

    AspectRatioChanger = function()
        if not ui.get(menu.visuals.aspectRatioChanger.enable) then 
            visuals.ResetAspectRatioChanger()
            return
        end

        aspectRation:set_raw_float(ui.get(menu.visuals.aspectRatioChanger.aspectRatio) * 0.01)
    end,

    ResetThirdPersonDistance = function()
        camIdealdist:set_raw_float(originalCamIdealDist)
    end,

    ThirdPersonDistanceChanger = function()
        if not ui.get(menu.visuals.thirdPersonChanger.enable) then 
            visuals.ResetThirdPersonDistance()
            return
        end

        camIdealdist:set_raw_float(ui.get(menu.visuals.thirdPersonChanger.distance))
    end,

    RenderCenter = function()
        if not ui.get(menu.hud.centerIndicators.enable) then return end

        local localPlayer = entity.get_local_player()
        if not localPlayer or not entity.is_alive(localPlayer) then return end

        local screensize = {} 
        screensize.x, screensize.y = client.screen_size()

        local bodyyaw = math.max(-60, math.min(60, math.floor((entity.get_prop(localPlayer, "m_flPoseParameter", 11) or 0) * 120 - 60)))
        local side = bodyyaw >= 0 and true or false

        renderer.triangle(screensize.x/2 - 40 ,screensize.y/2 - 10, screensize.x/2 - 40,screensize.y/2 + 10, screensize.x/2 - 55,screensize.y/2 , 0, 0, 0, 100)
        renderer.triangle(screensize.x/2 + 40 ,screensize.y/2 - 10, screensize.x/2 + 40,screensize.y/2 + 10, screensize.x/2 + 55,screensize.y/2 , 0, 0, 0, 100)

        local r, g, b, a = ui.get(menu.config.accent)

        renderer.rectangle(screensize.x/2 - 37, screensize.y/2 - 10, -2, 20, side == true and r or 0, side == true and g or 0, side == true and b or 0, 100)
        renderer.rectangle(screensize.x/2 + 37, screensize.y/2 - 10, 2, 20, side == false and r or 0, side == false and g or 0, side == false and b or 0, 100)

        visuals.RenderCenterInd("madrilla recode", "c", 255, 255, 255, 255)

        if ui.get(doubleTapEnable) and ui.get(doubleTapKey) then
            local charged = antiaim_funcs.get_double_tap()

            if not charged then
                visuals.RenderCenterInd("DT", "c-", 255, 69, 69, 255)
            else
                visuals.RenderCenterInd("DT", "c-", 255, 255, 255, 255)
            end
        end

        if ui.get(minDamageEnable) and ui.get(minDamageTapKey) then
            visuals.RenderCenterInd("MD", "c-", 255, 255, 255, 255)
        end

        local dmg = (ui.get(minDamageEnable) and ui.get(minDamageTapKey)) and ui.get(minDamageValue) or ui.get(damageValue)
        renderer.text(screensize.x/2 + 20, screensize.y/2 - 20, 255, 255, 255, 255, "c", 0, tostring(dmg)) 
    end,

    RunAnimBreaker = function()
        if not ui.get(menu.visuals.animBreaker.enable) then return end
        local opts = ui.get(menu.visuals.animBreaker.options)

        local localPlayer = entity.get_local_player()
        if not localPlayer or not entity.is_alive(localPlayer) then return end

        if contains(opts, "Static Legs in Air") then
            entity.set_prop(localPlayer, "m_flPoseParameter", 1, 6)
        end

        if contains(opts, "0 Pitch on Land") then
            if visuals.ground_ticks > 0 and visuals.ground_ticks < 15 then
                entity.set_prop(localPlayer, "m_flPoseParameter", 0.5, 12) -- 0.5 = 0 degrees (forward)
            end
        end
    end,

    OnSetupCommand = function(cmd)
        if not ui.get(menu.visuals.animBreaker.enable) then return end
        local opts = ui.get(menu.visuals.animBreaker.options)
        
        if contains(opts, "Moonwalk (Slide)") or contains(opts, "0 Pitch on Land") then
            local localPlayer = entity.get_local_player()
            if not localPlayer or not entity.is_alive(localPlayer) then return end
            
            local flags = entity.get_prop(localPlayer, "m_fFlags")
            local on_ground = bit.band(flags, 1) == 1
            
            if on_ground then
                visuals.ground_ticks = visuals.ground_ticks + 1
            else
                visuals.ground_ticks = 0
            end
            
            if contains(opts, "Moonwalk (Slide)") and on_ground then
                if cmd.forwardmove > 0 then
                    cmd.in_forward = 0
                    cmd.in_back = 1
                elseif cmd.forwardmove < 0 then
                    cmd.in_forward = 1
                    cmd.in_back = 0
                end

                if cmd.sidemove > 0 then
                    cmd.in_moveright = 0
                    cmd.in_moveleft = 1
                elseif cmd.sidemove < 0 then
                    cmd.in_moveright = 1
                    cmd.in_moveleft = 0
                end
            end
        end
    end,

    OnPaintUI = function()
        local logs_opts = ui.get(menu.hud.logs.options)
        if contains(logs_opts, "console") then
            logDamageDealt:set(false)
            logSpreadMisses:set(false)
        else
            -- If user doesn't want madrilla recode logs, restore default gamesense logs if desired
            -- Ideally we should track the original state, but usually people want them on if console is disabled
            logSpreadMisses:set(true)
            logDamageDealt:set(true)
        end

        if ui.get(menu.ragebot.ragebotHelper.enable) and ui.get(menu.ragebot.ragebotHelper.bind) then
            renderer.indicator(203, 203, 203, 255, "DA")
        end

        visuals.ViewModelChanger()
        visuals.AspectRatioChanger()
        visuals.ThirdPersonDistanceChanger()

        visuals.offset = 25
        visuals.RenderCenter()

        visuals.HitlogRender()
        visuals.SolusWatermark()
        visuals.SolusKeybinds()
        visuals.SolusStatusPanel()
        visuals.SolusChat()
        visuals.SolusMoney()
    end,

    OnPlayerChat = function(event)
        do return end -- customChat removed
        
        local userid = event.userid
        local ent = 0
        if userid ~= nil then
            ent = client.userid_to_entindex(userid)
        end
        
        local name = "Console"
        if ent ~= 0 then
            name = entity.get_player_name(ent) or "unknown"
        end
        
        local text = event.text or ""
        if text == "" then
            -- Fallback in case the event string is stored in another field or just to debug
            local dbg = ""
            for k,v in pairs(event) do 
                if k ~= "userid" and k ~= "text" and k ~= "teamonly" then
                    dbg = dbg .. k .. "=" .. tostring(v) .. " " 
                end
            end
            if dbg ~= "" then text = dbg end
        end
        
        table.insert(chat_history, {
            name = name,
            text = text,
            time = globals.realtime(),
            alpha = 0,
            is_team = event.teamonly or false
        })
        
        -- keep only last 10 messages
        if #chat_history > 10 then
            table.remove(chat_history, 1)
        end
    end,

    OnAimFire = function(event)
        local logs_opts = ui.get(menu.hud.logs.options)
        local log_onshot = ui.get(menu.hud.logs.logOnshot)
        
        local is_onshot = false
        local target = event.target
        local target_wep = entity.get_prop(target, "m_hActiveWeapon")
        if target_wep then
            local last_shot = entity.get_prop(target_wep, "m_fLastShotTime")
            if last_shot and globals.curtime() - last_shot < 0.5 then
                is_onshot = true
            end
        end
        visuals.onshot_tracker[event.id] = is_onshot

        if not contains(logs_opts, "console") then return end

        local onshot_str = (log_onshot and is_onshot) and " | ONSHOT" or ""

        local log = string.format(
            " Fired a shot at %s(hc: %d, hb: %s, dmg: %d, bt: %dT, lc: %s, extrap %s, interp %s, acc %s, prio %s)%s",
            entity.get_player_name(event.target),
            event.hit_chance,
            hitgroups[event.hitgroup + 1] or "?",
            event.damage,
            globals.tickcount() - event.tick,
            event.teleported and "broken" or "active",
            event.extrapolated and "true" or "false",
            event.ininterpolated and "true" or "false",
            event.boosted and "true" or "false",
            event.high_priority and "true" or "false",
            onshot_str
        )

        local r, g, b, a = ui.get(menu.config.accent)

        client.color_log(r, g, b, "[madrilla recode] \0")
        client.color_log(255, 255, 255, log)
    end,

    OnAimHit = function(event)
        local logs_opts = ui.get(menu.hud.logs.options)
        local console = contains(logs_opts, "console")
        local hitlog = contains(logs_opts, "hitlog indicator")
        local log_onshot = ui.get(menu.hud.logs.logOnshot)

        if not console and not hitlog then return end

        local target_name = entity.get_player_name(event.target):lower()
        local hitbox = hitgroups[event.hitgroup + 1] or "?"
        local dmg = event.damage
        local hp = entity.get_prop(event.target, "m_iHealth")
        
        local is_onshot = visuals.onshot_tracker[event.id] or false
        local onshot_str = (log_onshot and is_onshot) and " [ONSHOT]" or ""

        if ui.get(menu.hud.floatingDamage.enable) then
            local hx, hy, hz = entity.hitbox_position(event.target, event.hitgroup)
            if hx ~= nil then
                hx = hx + math.random(-10, 10)
                hy = hy + math.random(-10, 10)
                hz = hz + math.random(-10, 10)
                table.insert(visuals.floating_damage, {
                    damage = dmg,
                    x = hx,
                    y = hy,
                    z = hz,
                    time = globals.realtime()
                })
            end
        end

        if console then
            local log = string.format(
                " Tapped %s in the %s for %d damage%s",
                target_name, hitbox, dmg, onshot_str
            )

            local r, g, b, a = ui.get(menu.config.accent)

            client.color_log(r, g, b, "[madrilla recode] \0")
            client.color_log(255, 255, 255, log)
        end

        if hitlog then
            push_notify("Hit " .. target_name .. "'s " .. hitbox .. " for " .. dmg .. "!" .. onshot_str)
        end
    end,

    OnAimMiss = function(event)
        local logs_opts = ui.get(menu.hud.logs.options)
        local console = contains(logs_opts, "console")
        local hitlog = contains(logs_opts, "hitlog indicator")
        local log_onshot = ui.get(menu.hud.logs.logOnshot)

        if not console and not hitlog then return end

        local target_name = entity.get_player_name(event.target):lower()
        local hitbox = hitgroups[event.hitgroup + 1] or "?"
        local reason = event.reason == "?" and "resolver" or event.reason
        
        local is_onshot = visuals.onshot_tracker[event.id] or false
        local onshot_str = (log_onshot and is_onshot) and " [ONSHOT]" or ""

        if console then
            local log = string.format(
                " Missed %s in the %s due to %s (Hitchance: %d%%)%s",
                target_name, hitbox, reason, event.hit_chance or 0, onshot_str
            )

            local r, g, b, a = ui.get(menu.config.accent)

            client.color_log(r, g, b, "[madrilla recode] \0")
            client.color_log(255, 255, 255, log)
        end

        if hitlog then
            push_notify("Missed " .. target_name .. "'s " .. hitbox .. " due to " .. reason .. "!" .. onshot_str)
        end
    end,

    OnPreRender = function()
        visuals.RunAnimBreaker()
    end,

    HitlogRender = function()
        local logs_opts = ui.get(menu.hud.logs.options)
        if not contains(logs_opts, "hitlog indicator") then return end
        notify.render()
    end,

    GrenadeESP = function()
        if not ui.get(menu.visuals.grenadeESP.enable) then return end

        local r, g, b, a = ui.get(menu.visuals.grenadeESP.color)
        local pos = ui.get(menu.visuals.grenadeESP.position)
        local scale = ui.get(menu.visuals.grenadeESP.scale) / 10
        local players = entity.get_players(true)

        for _, player in ipairs(players) do
            local nades = get_grenades(player)

            if #nades > 0 then
                local x1, y1, x2, y2, alpha_multiplier = entity.get_bounding_box(player)

                if y2 ~= nil and alpha_multiplier > 0 then
                    local est_w, est_h = math.floor(24 * scale), math.floor(24 * scale)
                    local padding = 4
                    local total_w = #nades * est_w + math.max(0, #nades - 1) * padding
                    local total_h = #nades * est_h + math.max(0, #nades - 1) * padding
                    
                    local draw_x, draw_y = 0, 0
                    local offset_x, offset_y = 0, 0
                    
                    if pos == "Top" then
                        draw_x = x1 + (x2 - x1) / 2 - total_w / 2
                        draw_y = y1 - est_h - 15
                        offset_x = est_w + padding
                    elseif pos == "Bottom" then
                        draw_x = x1 + (x2 - x1) / 2 - total_w / 2
                        draw_y = y2 + 15
                        offset_x = est_w + padding
                    elseif pos == "Left" then
                        draw_x = x1 - est_w - 18
                        draw_y = y1 + (y2 - y1) / 2 - total_h / 2
                        offset_y = est_h + padding
                    elseif pos == "Right" then
                        draw_x = x2 + 18
                        draw_y = y1 + (y2 - y1) / 2 - total_h / 2
                        offset_y = est_h + padding
                    end

                    for _, nade_idx in ipairs(nades) do
                        local icon = images.get_weapon_icon(nade_idx)
                        local iw, ih = icon:measure()
                        local w = math.floor(iw * scale)
                        local h = math.floor(ih * scale)
                        
                        local center_ox = (est_w - w) / 2
                        local center_oy = (est_h - h) / 2

                        icon:draw(draw_x + center_ox - 2, draw_y + center_oy - 2, w + 4, h + 4, 0, 0, 0, 225)
                        icon:draw(draw_x + center_ox, draw_y + center_oy, w, h, r, g, b, a)

                        draw_x = draw_x + offset_x
                        draw_y = draw_y + offset_y
                    end
                end
            end
        end
    end,

    OnPaint = function()
        visuals.GrenadeESP()
        visuals.RenderFloatingDamage()
    end,

    RenderFloatingDamage = function()
        if not ui.get(menu.hud.floatingDamage.enable) then return end
        
        local current_time = globals.realtime()
        local duration = ui.get(menu.hud.floatingDamage.duration)
        local r, g, b, a_max = ui.get(menu.hud.floatingDamage.color)
        
        for i = #visuals.floating_damage, 1, -1 do
            local hit = visuals.floating_damage[i]
            local time_alive = current_time - hit.time

            if time_alive > duration then
                table.remove(visuals.floating_damage, i)
            else
                hit.z = hit.z + (globals.frametime() * 20)
                
                local a = a_max
                if time_alive > (duration - 0.5) then
                    a = math.floor(a_max * (duration - time_alive) / 0.5)
                end
                
                local sx, sy = renderer.world_to_screen(hit.x, hit.y, hit.z)
                if sx ~= nil and sy ~= nil then
                    renderer.text(sx, sy, r, g, b, a, "cb", 0, "-" .. hit.damage)
                end
            end
        end
    end,

    drag_state = {
        watermark = {
            x = database.read("madrilla_recode_watermark_x") or 1000, 
            y = database.read("madrilla_recode_watermark_y") or 15, 
            drag_x = 0, drag_y = 0, dragging = false
        },
        keybinds = {
            x = database.read("madrilla_recode_keybinds_x") or 15, 
            y = database.read("madrilla_recode_keybinds_y") or 400, 
            drag_x = 0, drag_y = 0, dragging = false
        },
        statusPanel = {
            x = database.read("madrilla_recode_statuspanel_x") or 15,
            y = database.read("madrilla_recode_statuspanel_y") or 600,
            drag_x = 0, drag_y = 0, dragging = false
        },
        customChat = {
            x = database.read("madrilla_recode_customchat_x") or 15,
            y = database.read("madrilla_recode_customchat_y") or 700,
            drag_x = 0, drag_y = 0, dragging = false
        },
        customMoney = {
            x = database.read("madrilla_recode_custommoney_x") or 15,
            y = database.read("madrilla_recode_custommoney_y") or 800,
            drag_x = 0, drag_y = 0, dragging = false
        }
    },

    HandleDrag = function(id, w, h)
        local state = visuals.drag_state[id]
        if not ui.is_menu_open() then
            state.dragging = false
            return state.x, state.y
        end
        
        local mouse_x, mouse_y = ui.mouse_position()
        local is_hovered = mouse_x >= state.x and mouse_x <= state.x + w and mouse_y >= state.y and mouse_y <= state.y + h
        
        if client.key_state(0x01) then
            if state.dragging then
                state.x = mouse_x - state.drag_x
                state.y = mouse_y - state.drag_y
            elseif is_hovered then
                state.dragging = true
                state.drag_x = mouse_x - state.x
                state.drag_y = mouse_y - state.y
            end
        else
            if state.dragging then
                -- Save to database when dragging stops
                database.write("madrilla_recode_" .. id .. "_x", state.x)
                database.write("madrilla_recode_" .. id .. "_y", state.y)
            end
            state.dragging = false
        end
        
        -- Screen bounds check
        local screen_x, screen_y = client.screen_size()
        state.x = math.max(0, math.min(screen_x - w, state.x))
        state.y = math.max(0, math.min(screen_y - h, state.y))
        
        return state.x, state.y
    end,

    SolusWatermark = function()
        if not ui.get(menu.hud.solusUi.watermark) then return end
        
        local r, g, b, a = ui.get(menu.config.accent)
        local screen_x, screen_y = client.screen_size()
        
        local ping = math.floor(client.latency() * 1000)
        local hours, minutes, seconds = client.system_time()
        local time = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        local user = "madrilla_recode"
        local local_player = entity.get_local_player()
        if local_player then
            local name = entity.get_player_name(local_player)
            if name then user = name end
        end
        
        local text = string.format("madrilla_recode | %s | %dms | %s", user, ping, time)
        local text_w = renderer.measure_text("", text)
        local w = text_w + 20
        local h = 20
        
        local x, y = visuals.HandleDrag("watermark", w, h)
        
        solus_ui.container_glow(x, y, w, h, r, g, b, 200, 1.0, r, g, b)
        renderer.text(x + 10, y + 4, 255, 255, 255, 255, "", 0, text)
    end,

    keybinds_anim = {
        width = 100,
        height = 25,
        binds = {}
    },

    SolusKeybinds = function()
        if not ui.get(menu.hud.solusUi.keybinds) then return end
        
        local current_binds = {}
        
        local function add_bind(name, state)
            current_binds[name] = state
        end
        
        if ui.get(menu.ragebot.ragebotHelper.enable) and ui.get(menu.ragebot.ragebotHelper.bind) then
            add_bind("Ragebot helper", "[toggled]")
        end
        if ui.get(menu.misc.delayedFakeduck.enable) and ui.get(menu.misc.delayedFakeduck.bind) then
            add_bind("Delayed fakeduck", "[held]")
        end
        if ui.get(menu.misc.smartDrop.enable) and ui.get(menu.misc.smartDrop.bind) then
            add_bind("Smart drop", "[held]")
        end
        if ui.get(menu.misc.dropNades.enable) and ui.get(menu.misc.dropNades.bind) then
            add_bind("Drop nades", "[held]")
        end
        local function check_reference(tab, subtab, name, bind_name)
            local success, ref1, ref2 = pcall(ui.reference, tab, subtab, name)
            if success and ref1 then
                if ref2 then
                    if ui.get(ref1) and ui.get(ref2) then
                        add_bind(bind_name, "[toggled]")
                    end
                else
                    if ui.get(ref1) then
                        add_bind(bind_name, "[toggled]")
                    end
                end
            end
        end

        check_reference("Rage", "Aimbot", "Double tap", "Double tap")
        check_reference("Rage", "Aimbot", "Minimum damage override", "Minimum damage")
        check_reference("AA", "Other", "On shot anti-aim", "Hide shots")
        check_reference("Rage", "Other", "Quick peek assist", "Quick peek")
        check_reference("Rage", "Other", "Force body aim", "Force baim")
        check_reference("Rage", "Other", "Force safe point", "Safe point")
        
        local active_names = {}
        for name, state in pairs(current_binds) do
            active_names[name] = true
            local found = false
            for i, bind in ipairs(visuals.keybinds_anim.binds) do
                if bind.name == name then
                    bind.state = state
                    bind.active = true
                    found = true
                    break
                end
            end
            if not found then
                table.insert(visuals.keybinds_anim.binds, {name = name, state = state, alpha = 0, active = true})
            end
        end
        
        for i, bind in ipairs(visuals.keybinds_anim.binds) do
            if not active_names[bind.name] then
                bind.active = false
            end
        end
        
        local title = "keybinds"
        local title_w = cached_measure_text("", title)
        local target_w = title_w + 50
        local active_count = 0
        
        for i = #visuals.keybinds_anim.binds, 1, -1 do
            local bind = visuals.keybinds_anim.binds[i]
            
            if bind.active then
                bind.alpha = solus_ui.lerp(bind.alpha, 1.0, globals.frametime() * 8)
            else
                bind.alpha = solus_ui.lerp(bind.alpha, 0.0, globals.frametime() * 12)
            end
            
            if bind.alpha < 0.01 and not bind.active then
                table.remove(visuals.keybinds_anim.binds, i)
            else
                local w1 = cached_measure_text("", bind.name)
                local w2 = cached_measure_text("", bind.state)
                if w1 + w2 + 30 > target_w then
                    target_w = w1 + w2 + 30
                end
                active_count = active_count + bind.alpha
            end
        end
        
        local target_h = 25 + (active_count * 15)
        if #visuals.keybinds_anim.binds == 0 then target_h = 25 end
        
        visuals.keybinds_anim.width = solus_ui.lerp(visuals.keybinds_anim.width, target_w, globals.frametime() * 15)
        visuals.keybinds_anim.height = target_h -- Remove double lerp so height matches alpha perfectly
        
        local r, g, b, a = ui.get(menu.config.accent)
        local w = visuals.keybinds_anim.width
        local h = visuals.keybinds_anim.height
        
        local x, y = visuals.HandleDrag("keybinds", w, h)
        
        solus_ui.container_glow(x, y, w, h, r, g, b, 200, 1.0, r, g, b)
        
        renderer.text(x + w/2 - title_w/2, y + 5, 255, 255, 255, 255, "", 0, title)
        
        if #visuals.keybinds_anim.binds > 0 then
            renderer.line(x + 5, y + 20, x + w - 5, y + 20, 255, 255, 255, 50)
            
            local current_y = y + 25
            for i=1, #visuals.keybinds_anim.binds do
                local bind = visuals.keybinds_anim.binds[i]
                local alpha_255 = math.floor(bind.alpha * 255)
                
                renderer.text(x + 5, current_y, 255, 255, 255, alpha_255, "", 0, bind.name)
                local sw = cached_measure_text("", bind.state)
                
                -- Render relative to current width so it never draws outside the box
                renderer.text(x + w - 5 - sw, current_y, 255, 255, 255, alpha_255, "", 0, bind.state)
                
                current_y = current_y + (15 * bind.alpha)
            end
        end
    end,
    
    SolusStatusPanel = function()
        if not ui.get(menu.hud.solusUi.statusPanel) then return end
        
        local r, g, b, a = ui.get(menu.config.accent)
        local screen_x, screen_y = client.screen_size()
        
        local title = "madrilla recode status"
        local title_w = cached_measure_text("", title)
        
        -- Get current state
        local state = "Global"
        local localPlayer = entity.get_local_player()
        if localPlayer and entity.is_alive(localPlayer) then
            local flags = entity.get_prop(localPlayer, "m_fFlags")
            local on_ground = bit.band(flags, 1) == 1
            local duckAmount = entity.get_prop(localPlayer, "m_flDuckAmount") or 0
            local inDuck = duckAmount > 0.7
            local velX, velY = entity.get_prop(localPlayer, "m_vecVelocity")
            local velocity = 0
            if velX and velY then velocity = math.sqrt(velX^2 + velY^2) end
            
            if not on_ground then
                state = inDuck and "Air Crouch" or "Air"
            elseif inDuck then
                state = velocity > 1.1 and "Crouch Move" or "Crouched"
            elseif velocity > 1.1 then
                state = "Moving"
            else
                state = "Standing"
            end
        end

        local desync_angle = math.floor(antiaim_funcs.get_desync(2) or 0)
        local is_desyncing = math.abs(desync_angle) > 10
        
        -- Get anti-bruteforce info from antiaim or resolver if available
        local ab_mode = ui.get(menu.antiaim.antiBruteModes)
        local ab_status = "Inactive"
        if ui.get(menu.antiaim.antiBrute) then
            ab_status = ab_mode or "Active"
        end

        local w = 150
        local h = 80
        
        local x, y = visuals.HandleDrag("statusPanel", w, h)
        
        solus_ui.container_glow(x, y, w, h, r, g, b, 200, 1.0, r, g, b)
        
        renderer.text(x + w/2 - title_w/2, y + 5, 255, 255, 255, 255, "", 0, title)
        renderer.line(x + 5, y + 20, x + w - 5, y + 20, 255, 255, 255, 50)
        
        renderer.text(x + 10, y + 30, 255, 255, 255, 255, "", 0, "State:")
        renderer.text(x + w - 10 - cached_measure_text("", state), y + 30, r, g, b, 255, "", 0, state)
        
        renderer.text(x + 10, y + 45, 255, 255, 255, 255, "", 0, "Desync:")
        local desync_str = tostring(desync_angle) .. "°"
        local dr, dg, db = 255, 255, 255
        if is_desyncing then dr, dg, db = r, g, b end
        renderer.text(x + w - 10 - cached_measure_text("", desync_str), y + 45, dr, dg, db, 255, "", 0, desync_str)
        
        renderer.text(x + 10, y + 60, 255, 255, 255, 255, "", 0, "A-Brute:")
        renderer.text(x + w - 10 - cached_measure_text("", ab_status), y + 60, 200, 200, 200, 255, "", 0, ab_status)
    end,
    
    SolusChat = function()
        local chat_enabled = false
        if chat_enabled ~= was_chat_enabled then
            toggle_native_hud("chat", not chat_enabled)
            was_chat_enabled = chat_enabled
        end
        
        if not chat_enabled then return end
        
        local r, g, b, a = ui.get(menu.config.accent)
        local w = 350
        local h = 250
        
        local x, y = visuals.HandleDrag("customChat", w, h)
        
        -- Check if chat is open in panorama via our global api
        local typing_check = panorama.loadstring("return $.madrilla_recode_is_typing === true", "CSGOHud")
        if typing_check then
            is_typing = typing_check()
        end
        
        local get_text = panorama.loadstring("return $.madrilla_recode_typing_text || ''", "CSGOHud")
        if get_text then
            typing_text = get_text() or ""
        end
        
        local acc_r, acc_g, acc_b, acc_a = ui.get(menu.hud.customHud.accentColor)
        local bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customHud.bgColor)
        
        renderer.text(x, y + h - 60, 255, 0, 0, 255, "", 0, "DEBUG -> is_typing: " .. tostring(is_typing) .. " | text: " .. tostring(typing_text))
        
        -- Draw history
        local y_offset = y + h - 40
        for i = #chat_history, 1, -1 do
            local msg = chat_history[i]
            local time_alive = globals.realtime() - msg.time
            
            -- Alpha logic
            local target_alpha = 0
            if is_typing then
                target_alpha = 1.0
            else
                if time_alive < 10 then
                    target_alpha = 1.0
                elseif time_alive < 11 then
                    target_alpha = 1.0 - (time_alive - 10)
                end
            end
            
            msg.alpha = solus_ui.lerp(msg.alpha, target_alpha, globals.frametime() * 10)
            
            if msg.alpha > 0.01 then
                local prefix = msg.is_team and "[TEAM] " or ""
                local name_w = cached_measure_text("", prefix .. msg.name .. ": ")
                
                -- Glow container for each msg
                solus_ui.container_glow(x, y_offset, w, 20, bg_r, bg_g, bg_b, math.floor(bg_a * msg.alpha), msg.alpha, bg_r, bg_g, bg_b)
                
                renderer.text(x + 10, y_offset + 3, acc_r, acc_g, acc_b, math.floor(255 * msg.alpha), "", 0, prefix .. msg.name .. ": ")
                renderer.text(x + 10 + name_w, y_offset + 3, 255, 255, 255, math.floor(255 * msg.alpha), "", 0, msg.text)
            end
            
            y_offset = y_offset - 25 * msg.alpha
        end
        
        -- Draw typing box if active
        if is_typing then
            local get_text = panorama.loadstring("return $.madrilla_recode_typing_text || ''", "CSGOHud")
            if get_text then
                typing_text = get_text() or ""
            end
            
            local acc_r, acc_g, acc_b, acc_a = ui.get(menu.hud.customHud.accentColor)
            local bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customHud.bgColor)
            local box_y = y + h - 10
            
            solus_ui.container_glow(x, box_y, w, 25, acc_r, acc_g, acc_b, 100, 1.0, acc_r, acc_g, acc_b)
            renderer.rectangle(x, box_y, w, 25, bg_r, bg_g, bg_b, bg_a)
            renderer.rectangle(x, box_y, w, 1, math.floor(acc_r * 0.4), math.floor(acc_g * 0.4), math.floor(acc_b * 0.4), 100)
            renderer.rectangle(x, box_y, 3, 25, acc_r, acc_g, acc_b, acc_a)
            
            renderer.text(x + 10, box_y + 6, 255, 255, 255, 255, "", 0, "Say: " .. typing_text .. "_")
        end
    end,
    
    SolusMoney = function()
        local money_enabled = ui.get(menu.hud.solusUi.customMoney)
        if money_enabled ~= was_money_enabled then
            toggle_native_hud("money", not money_enabled)
            was_money_enabled = money_enabled
        end
        
        if not money_enabled then return end
        
        local localPlayer = entity.get_local_player()
        if not localPlayer then return end
        
        local actual_money = entity.get_prop(localPlayer, "m_iAccount") or 0
        
        if actual_money ~= current_money then
            money_delta_val = actual_money - current_money
            money_delta_time = globals.realtime()
            current_money = actual_money
        end
        
        displayed_money = solus_ui.lerp(displayed_money, current_money, globals.frametime() * 10)
        
        local acc_r, acc_g, acc_b, acc_a = ui.get(menu.hud.customHud.accentColor)
        local bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customHud.bgColor)
        local h = 35
        
        local money_str = string.format("$%d", math.floor(displayed_money))
        local money_w = cached_measure_text("b", money_str)
        
        local time_since_delta = globals.realtime() - money_delta_time
        local show_delta = time_since_delta < 3 and money_delta_val ~= 0
        local delta_str = ""
        local delta_w = 0
        
        local dr, dg, db = 255, 50, 50
        local sign = "-"
        if money_delta_val > 0 then
            dr, dg, db = 133, 186, 101
            sign = "+"
        end
        
        if show_delta then
            delta_str = string.format("%s$%d", sign, math.abs(money_delta_val))
            delta_w = cached_measure_text("b", delta_str)
        end
        
        local w = 40 + money_w + (show_delta and (10 + delta_w) or 0)
        if w < 100 then w = 100 end
        
        local x, y = visuals.HandleDrag("customMoney", w, h)
        
        solus_ui.container_glow(x, y, w, h, acc_r, acc_g, acc_b, 100, 1.0, acc_r, acc_g, acc_b)
        renderer.rectangle(x, y, w, h, bg_r, bg_g, bg_b, bg_a)
        renderer.rectangle(x, y, w, 1, math.floor(acc_r * 0.4), math.floor(acc_g * 0.4), math.floor(acc_b * 0.4), 100)
        renderer.rectangle(x, y, 3, h, acc_r, acc_g, acc_b, acc_a)
        
        -- Money Icon / Text
        renderer.text(x + 15, y + 10, 133, 186, 101, 255, "b", 0, money_str)
        
        -- Draw delta
        if show_delta then
            local delta_alpha = 1.0
            if time_since_delta > 2 then
                delta_alpha = 1.0 - (time_since_delta - 2)
            end
            
            local dy = y + 10 -- No vertical movement, just fade out in place
            
            renderer.text(x + 15 + money_w + 10, dy, dr, dg, db, math.floor(255 * delta_alpha), "b", 0, delta_str)
        end
    end
}

return visuals