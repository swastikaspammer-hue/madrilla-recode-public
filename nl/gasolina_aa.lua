_G.SCRIPT_NAME = "G$Z0LINA";

local pui = require("neverlose/pui");
local base64 = require("neverlose/base64");
local clipboard = require("neverlose/clipboard");
local inspect = require("neverlose/inspect");
local smoothy = require("neverlose/smoothy");
local easing = require("neverlose/easing")

local last_update = 1747063995;
--print(common.get_unixtime())
local reference do
    reference = { }

    reference.rage = {
        main = {
            dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),

            hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
            hide_shots_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),

            double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
            double_tap_lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),

            peek_assist = {
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Style"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Auto Stop"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Retreat Mode")
            }
        },

        selection = {
            hit_chance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
            minimum_damage = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
            safe_points = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
            body_aim = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim")
        }
    }

    reference.antiaim = {
        angles = {
            enabled = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
            pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),

            yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
            yaw_base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
            yaw_add = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
            avoid_backstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
            hidden = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),

            yaw_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
            modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),

            body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
            inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
            left_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
            right_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
            options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
            freestanding_body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),

            freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
            freestand_peek = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
            disable_yaw_modifiers = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
            body_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),

            extended_angles = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles"),
            extended_pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Pitch"),
            extended_roll = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Roll")
        },

        fake_lag = {
            enabled = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
            limit = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit")
        },

        misc = {
            fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
            slow_walk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
            leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")
        }
    }

    reference.ping_spike = ui.find("Miscellaneous", "Main", "Other", "Fake Latency")
end

local e_num = {
    states = {
        "Standing", "Running", "Slowing", "Crouching", "Sneaking", "Air", "Air Crouching", "Legit AA", "Freestanding"
    },

    teams = {
        "T", "CT"
    }
}

local log = {}; do
    function log:message(msg)
        print_raw(
            string.format('[\a%sgazolina\aDEFAULT] %s', ui.get_style()["Link Active"]:to_hex(), msg)
        )

    end

    function log:error(msg)
        print_raw(
            string.format('[\a%sgazolina\aDEFAULT] \aFF3E3EFF%s', ui.get_style()["Link Active"]:to_hex(), msg)
        )
    end

end

local screen = render.screen_size();

local windows = {}; do
    function windows:new(name, initial_pos)
        local initial_pos = initial_pos or vector();
        local group = ui.create("DRAGGING$$$)$)$)$");
        local mt = {};
        local mt_data = {
            dragging = false,
            mouse_pos = vector(0, 0),
            mouse_pos_diff = vector(0, 0),
            intersected = nil,

            size = vector(0, 0),
            position = vector(0, 0),

            reference = (function()
                local dragging_vector = {
                    group:slider(('%s:dragging_x'):format(name), -16384, 16384, initial_pos.x),
                    group:slider(('%s:dragging_y'):format(name), -16384, 16384, initial_pos.y)
                }

                dragging_vector[1]:visibility(false)
                dragging_vector[2]:visibility(false)

                return dragging_vector
            end)()
        }

        function mt.intersects(self, mouse, pos, size)
            return
                mouse.x >= pos.x and mouse.x <= pos.x+size.x and
                mouse.y >= pos.y and mouse.y <= pos.y+size.y
        end

        function mt.set_position(self, vec)
            self.reference[1]:set(vec.x);
            self.reference[2]:set(vec.y);
        end

        function mt.is_dragging(self)
            return self.dragging
        end

        function mt.update(self, size)
            local new_mouse_pos = ui.get_mouse_position()
            local menu_pos = ui.get_position()
            local menu_size = ui.get_size()

            local holding_key, intersection_check =
                ui.get_alpha() > 0 and common.is_button_down(1),
                self:intersects(new_mouse_pos, self.position, size) and not
                self:intersects(new_mouse_pos, menu_pos, menu_size)

            self.mouse_pos_diff = -(self.mouse_pos-new_mouse_pos)

            if holding_key and self.intersected == nil then
                self.intersected = intersection_check
            end

            if holding_key and self.intersected then
                self.dragging = true
            elseif not holding_key then
                self.dragging = false
                self.intersected = nil
            end

            if self.dragging then
                local limit, new_pos = size * .5, vector(
                    self.reference[1]:get() + self.mouse_pos_diff.x,
                    self.reference[2]:get() + self.mouse_pos_diff.y
                )

                self.reference[1]:set(math.max(-limit.x, math.min(screen.x-limit.x, new_pos.x)))
                self.reference[2]:set(math.max(-limit.y, math.min(screen.y-limit.y, new_pos.y)))
            end

            local pos = vector(
                self.reference[1]:get(),
                self.reference[2]:get()
            )

            self.mouse_pos = new_mouse_pos
            self.size = size;
            self.position = pos;
        end

        return setmetatable(mt, { __index = mt_data })
    end
end

local cvars = {}; do
    function cvars:get_original(convar)
        return tonumber(convar:string())
    end
end

local text_effects = {}; do
    function text_effects:animate(speed, from, to, text)
        if not text or text:gsub(" ", "") == "" then 
            return text
        end
    
        local output = ""
        local time = globals.realtime * speed
        local i = 1
        local len = #text
    
        while i <= len do
            local byte1 = text:byte(i)
            local is_cyrillic = (byte1 == 0xD0 or byte1 == 0xD1) and text:byte(i + 1)
    
            if is_cyrillic then
                local char = text:sub(i, i + 1)
                local index = (math.sin(time + i / 3) + 1) / 2
                local accent = from:lerp(to, math.clamp(index, 0, 1)):to_hex()
                output = output .. "\a" .. accent .. char -- фикс русских символов братик
                i = i + 2
            else
                local index = (math.sin(time + i / 3) + 1) / 2
                local accent = from:lerp(to, math.clamp(index, 0, 1)):to_hex()
                output = output .. "\a" .. accent .. text:sub(i, i)
                i = i + 1
            end
        end
    
        return output
    end

    function text_effects:format(icon, text, pre_spaces, post_spaces, post_post_spaces, icon_color)
        pre_spaces = pre_spaces or 0
        post_spaces = post_spaces or 0 
        post_post_spaces = post_post_spaces or 0
        text = text or "ERROR"

        local space = "\xE2\x80\x8A"

        local get = ui.get_icon(icon);
        local clean = string.gsub(get, " ", "")

        if clean == "" then
            get = icon;
        end

        if icon_color then
            get = "\a" .. icon_color .. get .. "\r"
        else
            get = "\v" .. get .. "\r"
        end

        return string.rep(space, pre_spaces)  .. get .. string.rep(space, post_spaces) .. text .. string.rep(space, post_post_spaces)
    end

    function text_effects:colored(...)
        local output = "";
        
        for key, value in pairs({...}) do
            local accent = value[2];
            local text = value[1];

            output = output .. "\a" .. accent:to_hex() .. text;
        end

        return output;
    end
end

local keybinds = {}; do
    function keybinds:get_state(name)
        local value, active = 0, false
        local binds = ui.get_binds()
        
        for i = 1, #binds do
            local bind = binds[i]
            if bind.name == name then
                value = bind.value
                active = bind.active
                break
            end
        end

        return {value, active}
    end
end

local menu = {}; do
    local interpoint = "•";

    local info = {}; do
        
        local groups = {
            pui.create(text_effects:format("house", "", 0, 0, 0), " ", 1),
            pui.create(text_effects:format("house", "", 0, 0, 0), "", 1),
            pui.create(text_effects:format("house", "", 0, 0, 0), "  ", 1)
        }

        groups[1]:list("", {text_effects:format("user", "About", 1, 8)})
        groups[2]:label(text_effects:format("triangle-exclamation", "The script is a work in progress and\nsome features may not work as intended.", 1, 3, 0, "aeae61ff"))
        groups[2]:label(text_effects:format("bug", "Report Bugs", 1, 3, 0, "DEFAULT"))
        groups[2]:button(text_effects:format("discord", "Discord Server", 1, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/QwJx52dPSe") end, true)
        groups[2]:button(text_effects:format("", "🦫 Sata Config", 0, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://ru.neverlose.cc/market/item?id=ojYbuQ") end, true)
        groups[2]:button(text_effects:format("youtube", "Sata's YouTube", 0, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/channel/UCN5jetnEx5fkG7Cdr0iYh4g") end, true)

        groups[3]:label(text_effects:format("user", "Welcome back, \v" .. common.get_username(), 0, 8));
        groups[3]:label(text_effects:format("code-branch", "Last update: " .. "\v" .. common.get_date("%m/%d %H:%M", last_update) ..  "\r", 0, 8));


        local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Settings", 1)

        local sidebar = {}; do
            sidebar.label = group:label(text_effects:format(interpoint, "Sidebar", 2, 2, 2))
            local gear = sidebar.label:create();

            sidebar.text = gear:input("Text", _G.SCRIPT_NAME)
            sidebar.color = gear:color_picker(text_effects:format(interpoint, "Color", 5, 5, 5), {
                ["Inner"] = { color(175, 255, 55, 255) },
                ["Outter"] = { color(35, 128, 255, 255) }
            })
            sidebar.speed = gear:slider(text_effects:format(interpoint, "Speed", 5, 5, 5), 1, 32, 4)
            info.sidebar = sidebar;
        end

        local watermark = {}; do
            watermark.label = group:label(text_effects:format(interpoint, "Watermark", 2, 2, 2))
            local gear = watermark.label:create();

            watermark.mode = gear:listable("Options", {
                "Customizable Text",
                "Customizable Color",
                "Customizable Font"
            })

            watermark.text = gear:input("Text", _G.SCRIPT_NAME):depend({watermark.mode, 1})
            watermark.gradient = gear:switch(text_effects:format(interpoint, "Gradient", 2, 2, 2)):depend({watermark.mode, 2})
            watermark.color = gear:color_picker(text_effects:format(interpoint, "Color", 5, 5, 5), {
                ["Inner"] = { color(175, 255, 55, 255) },
                ["Outter"] = { color(35, 128, 255, 255) }
            }):depend({watermark.mode, 2}, {watermark.gradient, true})
            watermark.speed = gear:slider(text_effects:format(interpoint, "Speed", 5, 5, 5), 1, 32, 4):depend({watermark.mode, 2}, {watermark.gradient, true})
            watermark.non_gradient = gear:color_picker(text_effects:format(interpoint, "Color", 2, 2, 2)):depend({watermark.mode, 2}, {watermark.gradient, false})
            watermark.font = gear:combo(text_effects:format(interpoint, "Font", 2, 2, 2), {"Default", "Small", "Console", "Bold"}):depend({watermark.mode, 3})

            info.watermark = watermark;
        end
        
        local notify = {}; do
            notify.label = group:label(text_effects:format(interpoint, "Notifications", 2, 2, 2))
            local gear = notify.label:create();

            notify.style = gear:combo(text_effects:format(interpoint, "Mode", 15, 2, 2), {"Cat"})

            notify.text_color = gear:color_picker(text_effects:format(interpoint, "Text Color", 15, 2, 2), color())
            notify.border_color = gear:color_picker(text_effects:format(interpoint, "Border Color", 15, 2, 2), color())

            notify.spam = gear:switch(text_effects:format(" ", "Test Notification", 25, 15, 35))

            info.notify = notify;
        end

        local presets = {}; do
            local delete_state = {
                false, false
            }
            
            local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Presets", 2);

            presets.list = group:list(text_effects:format("list", "List of available configs", 1, 2, 1), {});
            
            presets.name = group:input(text_effects:format("pen", "Name", 1, 2, 1), "")
            presets.create = group:button(text_effects:format("paste", "", 0, 0, 0, "00BCD4ff"), nil, true);
            presets.create:tooltip("Create preset.")

            presets.load = group:button(text_effects:format("upload", "", 0, 0, 0, "3F51B5ff"), nil, true);
            presets.load:tooltip("Load selected preset.")

            presets.save = group:button(text_effects:format("floppy-disk", "", 0, 0, 0, "388E3Cff"), nil, true);
            presets.save:tooltip("Save selected preset.")

            presets.import = group:button(text_effects:format("file-import", "", 0, 0, 0, "4CAF50ff"), nil, true);
            presets.import:tooltip("Import new preset.")

            presets.export = group:button(text_effects:format("file-export", "", 0, 0, 0, "2196F3ff"), nil, true);
            presets.export:tooltip("Export selected preset.")
            
            local hidden_switch = group:switch(" ", false)
            hidden_switch:visibility(false);


            presets.delete = group:button(text_effects:format("trash", "", 0, 0, 0, "ff0000ff"), function() 
                hidden_switch:set(true);
            end):depend({hidden_switch, false})

            presets.delete_confirm = group:button(text_effects:format("trash-check", "", 0, 0, 0, "45ec4aff"), function()
                hidden_switch:set(false)
            end):depend({hidden_switch, true})

            presets.delete_cancel = group:button(text_effects:format("trash-xmark", "", 0, 0, 0, "ff0000ff"), function() 
                hidden_switch:set(false)
            end):depend({hidden_switch, true})
            
            local information = {}; do
                local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Presets", 2);
                
                information.creator = group:label("Author: \v...")
                presets.information = information
            end
            
            info.presets = presets;
        end

        menu.info = info
    end

    local antiaim = {}; do

        local main = {}; do

            local configure = {}; do
                local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Selection", 1);

                configure.team = group:list(text_effects:format("", "", 0, 0, 0), {
                    "\aFF0000FF" .. interpoint .. "\r  T", "\a8698fdff" .. interpoint .. "\r  CT"
                });

                


                configure.state = group:list(text_effects:format("users", "Select the state you want to change.", 2, 2, 2), e_num.states)

                main.configure = configure
            end

            local additional = {}; do
                local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Tweaks", 1);

                local legit_aa = {}; do
                    legit_aa.enabled = group:switch(text_effects:format("face-zany", "Legit AA", 2, 2, 2));

                    local gear = legit_aa.enabled:create();
                    legit_aa.mode = gear:combo(text_effects:format(interpoint, "Yaw Base", 2, 2, 2), {"Local View", "At Target"}):depend({legit_aa.enabled, true});
                
                    additional.legit_aa = legit_aa;
                end

                local manual_yaw = {}; do
                    manual_yaw.select = group:combo(text_effects:format("rotate", "Manual Yaw", 2, 2, 2), {"Disabled", "Left", "Right", "Forward"});

                    local gear = manual_yaw.select:create();
                    manual_yaw.static = gear:switch(text_effects:format(interpoint, "Static", 2, 2, 2));
                    manual_yaw.inverter = gear:switch(text_effects:format(interpoint, "Inverter", 2, 2, 2)):depend({manual_yaw.static, true})
                
                    additional.manual_yaw = manual_yaw;
                end

                local backstab = {}; do
                    backstab.switch = group:switch(text_effects:format("sword", "Avoid Backstab", 2, 2, 2));

                    additional.backstab = backstab
                end

                local warmup_aa = {}; do
                    warmup_aa.select = group:combo(text_effects:format("gear", "State", 2, 2, 2), {"Disabled", "Warmup", "No Enemies", "Force"});
                    local gear = warmup_aa.select:create();

                    warmup_aa.pitch = gear:combo(text_effects:format(interpoint, "Pitch", 2, 2, 2), "Disabled", "Down"):depend({warmup_aa.select, "Disabled", true})
                    warmup_aa.yaw = gear:combo(text_effects:format(interpoint, "Yaw", 2, 2, 2), "Spin", "Distortion", "L&R"):depend({warmup_aa.select, "Disabled", true})

                    warmup_aa.range = gear:slider(text_effects:format("arrows-left-right", "Range", 2, 2, 2), 1, 360, 360):depend({warmup_aa.yaw, "L&R", true}, {warmup_aa.select, "Disabled", true})
                    warmup_aa.speed = gear:slider(text_effects:format("gauge", "Speed", 2, 2, 2), 1, 128, 32, 1, "t"):depend({warmup_aa.yaw, "L&R", true}, {warmup_aa.select, "Disabled", true})

                    warmup_aa.left_yaw = gear:slider(text_effects:format("arrow-left", "Left Offset", 2, 2, 2), -180, 180, 0):depend({warmup_aa.yaw, "L&R"}, {warmup_aa.select, "Disabled", true})
                    warmup_aa.right_yaw = gear:slider(text_effects:format("arrow-right", "Right Offset", 2, 2, 2), -180, 180, 0):depend({warmup_aa.yaw, "L&R"}, {warmup_aa.select, "Disabled", true})
                    
                    additional.warmup_aa = warmup_aa;
                end

                local safe_head = {}; do
                    safe_head.switch = group:switch(text_effects:format("head-side", "Safe Head", 2, 2, 2));

                    local gear = safe_head.switch:create();
                    safe_head.states = gear:selectable(text_effects:format("list-check", "Conditions", 2, 2, 2), {
                        "Air Crouch",
                        "Zeus",
                        "Knife",
                        "Height Advantage"
                    }):depend({safe_head.switch, true});
                    safe_head.height = gear:slider(text_effects:format("ruler-vertical", "Height", 2, 2, 2), 0, 200, 25, 1, "u."):depend({safe_head.switch, true}, {safe_head.states, "Height Advantage"});
                    safe_head.height:tooltip(text_effects:format("info-circle", "If value equals zero then safe head works only on the same height as your enemy.", 1, 2, 1))

                    additional.safe_head = safe_head;
                end
            
                main.additional = additional
            end

            antiaim.main = main;
        end

        local angles = {}; do
            
            local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Builder", 2);

            local break_lc = {}; do
                break_lc.group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Snap builder"); 
                break_lc.select = break_lc.group:selectable(text_effects:format(interpoint, "Break LC", 2, 5, 2, "9ca7e1ff"), e_num.states);

                local gear = break_lc.select:create();
                break_lc.disable_on_grenade = gear:switch(text_effects:format("", "Disable on Grenade", 0, 0, 0));
                break_lc.hide_shots = gear:combo(text_effects:format("", "Hide Shots", 0, 0, 0), {"Favor Fire Rate", "Favor Fake Lag", "Break LC"})
                
                angles.break_lc = break_lc;
            end

            local ctx = {}; do
                for idx, state in pairs(e_num.states) do
                    ctx[state] = {};

                    for team, i in pairs(e_num.teams) do
                        ctx[state][i] = {};

                        local b = ctx[state][i];
                        local m_team = main.configure.team;
                        local m_state = main.configure.state;


                        b.allow_state = group:switch(text_effects:format("shield-check", ("Allow \v%s\r state"):format(state), 2, 2, 2), true):depend({m_team, team}, {m_state, idx})
                        b.yaw = group:combo(text_effects:format(interpoint, "Yaw", 2, 2, 2), {"Disabled", "Backward"}, "Backward"):depend({m_team, team}, {m_state, idx}) do
                            local gear = b.yaw:create();

                            b.yaw_mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), {"Solo", "L/R"}):depend({b.yaw, "Backward"});
                            b.offset = gear:slider(text_effects:format("turn-down-right", "Offset", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "Solo"});

                            b.yaw_left = gear:slider(text_effects:format("turn-down-right", "Left", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});
                            b.yaw_right = gear:slider(text_effects:format("turn-down-right", "Right", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});

                            b.delay = gear:switch(text_effects:format(interpoint, "Delay", 2, 2, 2, "FFA500FF")):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});
                            b.delay_method = gear:combo(text_effects:format("", "Method", 10, 2, 2), {"Default", "Random", "Custom"}):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay, true});

                            b.delay_default = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFTiming\r", 15, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Default"}, {b.delay, true});

                            b.delay_random_min = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFMin. Timing\r", 18, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Random"}, {b.delay, true});
                            b.delay_random_max = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFMax. Timing\r", 18, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Random"}, {b.delay, true});

                            b.delay_custom_sliders = gear:slider(text_effects:format(interpoint, "Sliders", 17, 2, 2), 2, 6, 2):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Custom"}, {b.delay, true});

                            for i = 1, 6 do
                                b["delay_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 14 + 5 * i, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Custom"}, {b.delay, true}, {b.delay_custom_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.delay_custom_sliders.value >= i
                                end});
                            end
                        end;

                        b.modifier = group:combo(text_effects:format("turn-down-right", "Modifier", 10, 2, 2), {"Disabled", "Center", "Offset", "Random", "Spin", "3-Way", "Bobro", "5-Way"}):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}) do
                            local gear = b.modifier:create();

                            b.randomize = gear:switch(text_effects:format("", "Randomize", 0, 0, 0)):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true});
                            
                            b.modifier_mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), "Default", "Custom"):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true});
                            
                            
                            b.min = gear:slider(text_effects:format("turn-down-right", "Minimum", 10, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Default"})
                            b.max = gear:slider(text_effects:format("turn-down-right", "Maximum", 10, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Default"})

                            b.modifier_custom_sliders = gear:slider(text_effects:format(interpoint, "Sliders", 7, 5, 2), 2, 6, 2):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Custom"});

                            for i = 1, 6 do
                                b["modifier_sliders_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 10 + 5 * i, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Custom"}, {b.modifier_custom_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.modifier_custom_sliders.value >= i
                                end});
                            end

                            b.modifier_offset = gear:slider(text_effects:format(interpoint, "Offset", 2, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, false})
                        end

                        b.body_yaw = group:switch(text_effects:format(interpoint, "Body Yaw", 2, 2, 2)):depend({m_team, team}, {m_state, idx}) do
                            local gear = b.body_yaw:create();

                            b.body_freestanding = gear:combo("Freestanding", {"Off", "Peek Fake", "Peek Real"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});

                            b.mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), {"Static", "Ticks", "Random"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});
                            b.mode_ticks = gear:slider(text_effects:format("turn-down-right", "Ticks", 10, 2, 2), 4, 16, 4, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.mode, "Ticks"});
                            b.mode_random = gear:slider(text_effects:format("turn-down-right", "Random Ticks", 10, 2, 2), 4, 16, 4, 1, "x"):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.mode, "Random"});
                        
                        
                            b.limit_mode = gear:combo(text_effects:format("", "Limit Mode", 0, 0, 0), {"Static", "Random", "From/To", "Speed-based Switch"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});

                            b.left_limit = gear:slider(text_effects:format("turn-down-right", "Left Limit", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Static"});
                            b.right_limit = gear:slider(text_effects:format("turn-down-right", "Right Limit", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Static"});

                            b.minimum_limit = gear:slider(text_effects:format("turn-down-right", "Minimum", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Random"});
                            b.maximum_limit = gear:slider(text_effects:format("turn-down-right", "Maximum", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Random"});

                            b.from_limit = gear:slider(text_effects:format("turn-down-right", "From", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, function()
                                return b.limit_mode:get() == "From/To" or b.limit_mode:get() == "Speed-based Switch"
                            end});

                            b.to_limit = gear:slider(text_effects:format("turn-down-right", "To", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, function()
                                return b.limit_mode:get() == "From/To" or b.limit_mode:get() == "Speed-based Switch"
                            end});

                            b.sb_speed = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFTiming\r", 15, 2, 2), 1, 22, 0):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Speed-based Switch"});

                        end
                        b.body_yaw_options = group:selectable(text_effects:format("turn-down-right", "Options", 10, 2, 2), {"Avoid Overlap", "Jitter", "Randomize Jitter", "Anti Bruteforce"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true})

                        b.send_to_opposite = group:button(text_effects:format("share-from-square", "Send to the opposite side", 17, 2, 20), function ()
                            local opposite_team = m_team:get() == "T" and "CT" or "T";
                            local current_state = m_state:list()[m_state:get()];

                            local original = ctx[current_state][m_team:get()]
                            local opposite = ctx[current_state][opposite_team]
                            for key, value in pairs(original) do

                                for k, v in pairs(opposite) do

                                    if k == key then
                                        v:set(value:get())
                                    end
                                end
                            end

                            cvar.playvol:call("ui/beepclear.wav", 1.0)
                        end, true):depend({m_team, team}, {m_state, idx})

                        b.choke = break_lc.group:combo(text_effects:format(interpoint, "Tickbase", 2, 5, 2, "ff0000ff"), {"Default", "Custom"}):depend({m_team, team}, {m_state, idx}, {break_lc.select, function()
                            return break_lc.select:get(idx)
                        end}); do
                            local gear = b.choke:create();

                            b.random_choke = gear:switch(text_effects:format("", "Random Choke", 0, 0, 0)):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"})
                            b.choke_slider = gear:slider(text_effects:format("turn-down-right", "Choke", 10, 2, 2), 2, 22, 16, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, false})

                            b.choke_method = gear:combo(text_effects:format(interpoint, "Method", 2, 2, 2), {"Default", "Custom"}):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true})
                            b.choke_from = gear:slider(text_effects:format("turn-down-right", "Choke from", 10, 2, 2), 1, 22, 16):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Default"})
                            b.choke_to = gear:slider(text_effects:format("turn-down-right", "Choke to", 10, 2, 2), 1, 22, 16):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Default"})


                            b.choke_sliders = gear:slider(text_effects:format("", "Sliders", 15, 0, 0), 2, 6, 2):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Custom"})
                            for i = 1, 6 do
                                b["choke1_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 14 + 5 * i, 2, 2), 2, 22, 0, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Custom"}, {b.choke_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.choke_sliders.value >= i
                                end});
                            end
                        end

                        ctx[state][i] = b;
                        angles.builder = ctx;
                    end
                end
            end


            local freestanding = {}; do
                freestanding.switch = group:switch(text_effects:format("arrows-rotate", "Freestanding", 2, 2, 2));

                local gear = freestanding.switch:create();
                freestanding.prefer_manual = gear:switch(text_effects:format(interpoint, "Prefer Manual", 2, 2, 2));

                local dsbl_tbl = e_num.states;
                table.remove(dsbl_tbl, 9)

                freestanding.disablers = gear:selectable(text_effects:format(interpoint, "Disablers", 2, 2, 2), dsbl_tbl);
                freestanding.body_fs = gear:switch(text_effects:format(interpoint, "Body Freestanding", 2, 2, 2))
                freestanding.yaw_mod = gear:switch(text_effects:format(interpoint, "Disable Yaw Modifiers", 2, 2, 2))

                angles.freestanding = freestanding;
            end

            local anti_bruteforce = {}; do
                anti_bruteforce.switch = group:switch(text_effects:format("reply-clock", "Anti-Bruteforce", 2, 2, 2));

                local gear =  anti_bruteforce.switch:create();
                anti_bruteforce.states = gear:selectable(text_effects:format(interpoint, "States", 2, 2, 2), e_num.states):depend({anti_bruteforce.switch, true})
                anti_bruteforce.mode = gear:combo(text_effects:format(interpoint, "Mode", 2, 2, 2), {"Increasing", "Decreasing", "Meta"}):depend({anti_bruteforce.switch, true}, {anti_bruteforce.states, true})
                anti_bruteforce.switch:tooltip(text_effects:format("info-circle", "Anti-bruteforce with automatic preset to avoid hs ^_^.", 1, 2, 1))
                
                angles.anti_bruteforce = anti_bruteforce;
            end

            antiaim.angles = angles;
        end


        menu.antiaim = antiaim;
    end
 
local conditions = {};  do

    function conditions.get(is_legit_aa)
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return;
        end

        local animstate = player:get_anim_state();

        if animstate == nil then
            return
        end

        local duck_amount = player.m_flDuckAmount;
        local speed = player.m_vecVelocity:length2d();

        local on_ground = animstate.on_ground and not animstate.landed_on_ground_this_frame

        local team = player.m_iTeamNum == 2 and "T" or "CT";

        local legit_data = menu.antiaim.angles.builder["Legit AA"][team];
        local freestand_data = menu.antiaim.angles.builder["Freestanding"][team];

        if is_legit_aa and legit_data.allow_state:get() then
            return "Legit AA";
        end

        if (reference.antiaim.angles.freestanding:get() or reference.antiaim.angles.freestanding:get_override()) and freestand_data.allow_state:get() then
            return "Freestanding";
        end

        if on_ground then
            if reference.antiaim.misc.slow_walk:get() then
                return "Slowing"
            end

            if speed < 5 then
                if duck_amount > 0 then
                    return "Crouching"
                end

                return "Standing"
            end

            if duck_amount > 0 then
                return "Sneaking"
            end

            return "Running"
        end

        return duck_amount > 0 and "Air Crouching" or "Air"
    end
end

local manual_aa = {}; do
    local list = {
        ["Forward"] = 180,
        ["Left"] = -90,
        ["Right"] = 90
    }

    function manual_aa.think()
        local value = menu.antiaim.main.additional.manual_yaw.select:get()

        if value == "Disabled" then
            return false, 0
        end

        local offset = list[value]

        if not offset then
            return false, 0
        end

        return true, offset;
    end

    function manual_aa.update(e, ctx, data)
        local is_manual_aa, offset = manual_aa.think();
        local is_static = menu.antiaim.main.additional.manual_yaw.static:get();
        local inverter = menu.antiaim.main.additional.manual_yaw.inverter:get();

        if is_manual_aa then
            ctx.yaw_offset = offset;
            ctx.yaw_base = "Local View"

            if is_static then
                ctx.yaw_modifier = "Disabled";
                rage.antiaim:inverter(inverter)
            end
        end
    end
end

local safe_head = {}; do

    function safe_head.think(e)
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        if not menu.antiaim.main.additional.safe_head.switch:get() then
            return false;
        end

        local threat = entity.get_threat();

        if threat == nil or not threat:is_alive() then
            return false;
        end
        
        local class = weapon:get_classname();

        local is_knife = class == "CKnife";
        local is_zeus = class == "CWeaponTaser";

        local origin = me:get_origin();
        local delta = origin - threat:get_origin();

        local height = menu.antiaim.main.additional.safe_head.height:get();

        return {
            ["Air Crouch"] = conditions.get() == "Air Crouching",
            ["Zeus"] = is_zeus,
            ["Knife"] = is_knife,
            ["Height Advantage"] = delta.z >= height
        }
    end

    function safe_head.update(e, ctx, data)
        local is_safe_head_table = safe_head.think(e)

        if type(is_safe_head_table) == "boolean" and not is_safe_head_table then
            return
        end

        for name, value in pairs(is_safe_head_table) do
            if menu.antiaim.main.additional.safe_head.states:get(name) then
                if value then
                    ctx.body_yaw = true;
                    ctx.yaw_offset = 0;
                    ctx.left_limit = 1;
                    ctx.right_limit = 1;
                    ctx.body_yaw_options = {};
                    ctx.yaw_modifier = "Disabled";
                    return true;
                end
            end
        end
    end
end

local warmup_aa = {}; do
    local distortion = 0;

    function warmup_aa.think()
        local me = entity.get_local_player();
    
        if me == nil or not me:is_alive() then
            return false;
        end

        local game_rules = entity.get_game_rules();

        if game_rules == nil then
            return false;
        end

        local mode = menu.antiaim.main.additional.warmup_aa.select:get()

        if mode == "Disabled" then
            return false;
        end

        local are_all_enemies_dead = true

        for i=1, globals.max_players do
            local player = entity.get(i)
            
            if player ~= nil then
                local player_resource = player:get_resource();

                if player_resource.m_bConnected and player_resource.m_bConnected == true then
                    if player:is_enemy() and player:is_alive() then
                        are_all_enemies_dead = false;
                        break;
                    end
                end
            end
        end


        local check_for_idiots = game_rules.m_bWarmupPeriod;
        
        if not check_for_idiots then
            check_for_idiots = are_all_enemies_dead;

            if not check_for_idiots then
                check_for_idiots = game_rules.m_bWarmupPeriod
            end
        end

        return {
            ["Warmup"] = game_rules.m_bWarmupPeriod,
            ["No Enemies"] = are_all_enemies_dead,
            ["Force"] = check_for_idiots     
        }
    end

    function warmup_aa.update(e, ctx, data)
        local is_warmup_aa_table = warmup_aa.think();

        if type(is_warmup_aa_table) ~= "boolean" and not is_warmup_aa_table then
            return
        end

        local mode = menu.antiaim.main.additional.warmup_aa.select:get()

        if mode == "Disabled" then
            return;
        end

        local yaw = menu.antiaim.main.additional.warmup_aa.yaw:get();
        
        local range = menu.antiaim.main.additional.warmup_aa.range:get();
        local speed = menu.antiaim.main.additional.warmup_aa.speed:get();

        local left_yaw = menu.antiaim.main.additional.warmup_aa.left_yaw:get();
        local right_yaw = menu.antiaim.main.additional.warmup_aa.right_yaw:get();

        if is_warmup_aa_table[ mode ] and mode ~= "Disabled" then
            ctx.pitch = menu.antiaim.main.additional.warmup_aa.pitch:get();
            ctx.yaw = "Backward";
            ctx.yaw_modifier = "Disabled";
            
            if yaw == "L&R" then
                ctx.body_yaw = true;
                ctx.body_yaw_options = {"Jitter"}
                ctx.yaw_offset = rage.antiaim:inverter() and left_yaw or right_yaw
            else
                if yaw == "Distortion" then
                    if globals.tickcount % speed == 0 then
                        distortion = utils.random_int(-range, range)
                    end

                    ctx.yaw_offset = distortion
                end

                if yaw == "Spin" then
                    ctx.yaw_offset = (globals.framecount * (speed * .1)) % range
                end

                ctx.body_yaw = false; 
            end
        end
    end
end

local legit_aa = {}; do
    legit_aa.is_working = false;

    local function is_pickup_available(player)
        local eye_position = player:get_eye_position();
        local camera_angles = render.camera_angles();
        local forward = vector():angles(camera_angles)
        local eye_angle = eye_position + forward * 128

        local trace = utils.trace_line(eye_position, eye_angle, 0xFFFFFFFF)
        if trace.entity == nil then
            return false
        end

        local classname = trace.entity:get_classname()

        if classname:find("Weapon") or classname:find("Door") then
            return true
        end

        return false
    end

    local function is_bomb_defuse(player)
        if player.m_iTeamNum ~= 3 then
            return false;
        end

        local origin_ = player:get_origin()

        local CPlantedC4 = entity.get_entities("CPlantedC4");

        for i = 1, #CPlantedC4 do
            local c4 = CPlantedC4[i];

            if c4 == nil then
                return false;
            end
            
            local origin = c4:get_origin()

            if origin == nil then
                return false;
            end
            
            if c4.m_bBombTicking and origin_:dist(origin) < 87.5 then
                return true;
            end
        end
    end

    local function is_hostage_pickup(player)
        local eye_position = player:get_eye_position();
        local camera_angles = render.camera_angles();
        local forward = vector():angles(camera_angles)
        local eye_angle = eye_position + forward * 128

        local mins = vector(-1, -1, -1)
        local maxs = vector(1, 1, 1)

        local mask = bit.bor(0x1, 0x2, 0x8, 0x4000, 0x2000000)

        local trace = utils.trace_hull(eye_position, eye_angle, mins, maxs, player, mask)

        if trace.entity == nil then
            return false;
        end

        local origin = player:get_origin();
        if origin:dist(trace.entity:get_origin()) < 125 and trace.entity:get_classid() == 97 then
            return true;
        end
    
        return false;
    end

    local function is_use_needed(e, player, weapon)
        if weapon then
            local wpn_classname = weapon:get_classname();

            if wpn_classname == 'CC4' then
                return true
            end
        end

        if is_pickup_available(player) then
            return true;
        end

        if is_bomb_defuse(player) then
            return true;
        end

        if is_hostage_pickup(player) then
            return true;
        end

        return false;
    end

    function legit_aa.think(e)
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        if not menu.antiaim.main.additional.legit_aa.enabled:get() then
            return false;
        end

        if not e.in_use then
            return false;
        end

        if is_use_needed(e, me, weapon) then
            return false;
        end


        return true;
    end

    function legit_aa.update(e, ctx, data)
        legit_aa.is_working = legit_aa.think(e);
        if not legit_aa.is_working then
            return
        end

        e.in_use = false;

        ctx.pitch = "Disabled";
        ctx.yaw_base = menu.antiaim.main.additional.legit_aa.mode:get();
    end
end

local break_lc = {}; do
    local current_slider = 1;
    local switch_delay = 0;

    function break_lc.think(e)
        local me = entity.get_local_player();

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        local state = conditions.get();

        if not menu.antiaim.angles.break_lc.select:get(state) then
            return false;
        end

        if menu.antiaim.angles.break_lc.disable_on_grenade:get() and weapon:get_weapon_info().weapon_type == 9 then
            return false;
        end
        
        return true;
    end

    function break_lc.update(e, ctx, data)
        local is_break_lc = break_lc.think(e);

        if not is_break_lc then
            return
        end

        local choke_mode = data.choke:get();
        local choke_random = data.random_choke:get();
        local choke_slider = data.choke_slider:get();
        local choke_method = data.choke_method:get();
        local choke_from = data.choke_from:get();
        local choke_to = data.choke_to:get();
        local choke_sliders = data.choke_sliders:get();

        if e.choked_commands == 0 then
            switch_delay = switch_delay + 1;
            local current_slider_value = data["choke1_" .. current_slider]:get() or 1;
            current_slider_value = math.max(current_slider_value, 1)
            
            if choke_sliders >= current_slider_value then
                switch_delay = 0;
                current_slider = current_slider + 1
                if current_slider > choke_sliders then
                    current_slider = 1
                end
            end
        end

        if choke_mode == "Custom" then
            if not choke_random then
                if globals.tickcount % choke_slider == 0 then
                    ctx.lag_options = "Always On";
                end
            else
                if choke_method == "Default" then
                    local slider = 1;

                    if globals.tickcount % choke_from == 0 then
                        slider = slider + 1;

                        if slider >= 3 then
                            slider = 1
                        end
                    end

                    local ui_slider = slider == 1 and choke_from or choke_to
                    if globals.tickcount % ui_slider == 0 then
                        ctx.lag_options = "Always On";
                    end
                else
                    local choke_value = data["choke1_" .. current_slider]:get() or 1;
                    if globals.tickcount % choke_value == 0 then
                        ctx.lag_options = "Always On"
                    end
                end
            end
        else
            ctx.lag_options = "Always On";
        end

        ctx.hs_options = menu.antiaim.angles.break_lc.hide_shots:get();
    end
end

local freestanding = {}; do

    local function condition_for_freestand()
        -- fuck it
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return;
        end

        local animstate = player:get_anim_state();

        if animstate == nil then
            return
        end

        local duck_amount = player.m_flDuckAmount;
        local speed = player.m_vecVelocity:length2d();

        local on_ground = animstate.on_ground and not animstate.landed_on_ground_this_frame

        local team = player.m_iTeamNum == 2 and "T" or "CT";

        local legit_data = menu.antiaim.angles.builder["Legit AA"][team];

        if is_legit_aa and legit_data.allow_state:get() then
            return "Legit AA";
        end

        if on_ground then
            if reference.antiaim.misc.slow_walk:get() then
                return "Slowing"
            end

            if speed < 5 then
                if duck_amount > 0 then
                    return "Crouching"
                end

                return "Standing"
            end

            if duck_amount > 0 then
                return "Sneaking"
            end

            return "Running"
        end

        return duck_amount > 0 and "Air Crouching" or "Air"
    end
    function freestanding.think(e)
        local fs_condition = condition_for_freestand(legit_aa.is_working);
        if menu.antiaim.angles.freestanding.disablers:get(fs_condition) then
            return false;
        end

        if not menu.antiaim.angles.freestanding.switch:get() then
            return false;
        end

        return true
    end

    function freestanding.update(e, ctx, data)
        local is_freestanding = freestanding.think(e)

        ctx.freestanding = is_freestanding;
        ctx.body_freestanding = menu.antiaim.angles.freestanding.body_fs:get()
        ctx.disable_yaw_modifiers = menu.antiaim.angles.freestanding.yaw_mod:get()
    end
end

local anti_bruteforce = {}; do

    local last_tick_triggered = 0;
    local reset_time = 0;
    local is_working = false;

    local offset = 0;

    function anti_bruteforce.reset()
        is_working = false;
        last_tick_triggered = 0;
        reset_time = 0;
        offset = 0;
    end
    

    function anti_bruteforce.think(e)
        if not menu.antiaim.angles.anti_bruteforce.switch:get() then
            return false;
        end

        if not menu.antiaim.angles.anti_bruteforce.states:get(conditions.get(legit_aa.is_working)) then
            return false
        end

        return true;
    end

    function anti_bruteforce.bullet_impact(e)
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return
        end

        local userid = entity.get(e.userid, true)
    
        if userid == nil or not userid:is_alive() or userid:is_dormant() or not userid:is_enemy() then
            return
        end

        if last_tick_triggered == globals.tickcount then 
            return 
        end

        local impact = vector(e.x, e.y, e.z)
        local userid_pos = userid:get_eye_position()
        local player_pos = player:get_hitbox_position(0);
        local distance = player_pos:closest_ray_point(userid_pos, impact):dist(player_pos)
    
        if distance > 40 then 
            return
        end

        if menu.misc.aimbot.logging.switch:get() and menu.misc.aimbot.logging.mode.select:get(4) then
            notify.new({
                "Anti-Bruteforce updated by ",
                userid:get_name(),
                "'s shot ",
                "", 
                "[", 
                offset, 
                "°;", 
                math.floor(tostring(distance)), 
                "]"
            }, ui.get_style()["Link Active"], "sparkles")
        end
    
        last_tick_triggered = globals.tickcount
        reset_time = globals.realtime + 3
    
        local mode = menu.antiaim.angles.anti_bruteforce.mode:get();

        if mode == "Increasing" then
            offset = math.random(-5, 10)
        elseif mode == "Decreasing" then
            offset = 5
        else
            offset = math.random(-15, 15)
        end
    end

    function anti_bruteforce.update(e, ctx)
        if not anti_bruteforce.think(e) then
            return
        end

        if reset_time <= globals.realtime then
            anti_bruteforce.reset()
        else
            is_working = true
        end

        if not is_working then
            return
        end

        ctx.yaw_offset = ctx.yaw_offset + (rage.antiaim:inverter() and offset or -offset)
    end

    events.bullet_impact(anti_bruteforce.bullet_impact)
end

local instance = {}; do

    local antiaim = {}; do
        function antiaim:reset()
            for key, value in pairs(reference.antiaim.angles) do
                value:override();
            end
        end

        function antiaim:define()
            self.pitch = nil;
            self.yaw = nil;
            self.yaw_offset = nil;
            self.yaw_base = nil;
            self.yaw_modifier = nil;
            self.modifier_offset = nil;
            self.left_limit = nil;
            self.right_limit = nil;

            self.body_yaw = nil;
            self.body_yaw_options = nil;

            self.disable_yaw_modifiers = nil;
            self.body_freestanding = nil;

            self.freestanding = nil;
            self.freestand_peek = nil;

            self.lag_options = nil;
            self.hs_options = nil;

            self.avoid_backstab = nil;

            self.ignore_inverter = false;
        end

        function antiaim:run()
            local pitch = self.pitch or "Disabled";
            reference.antiaim.angles.pitch:override(pitch);

            local yaw = self.yaw or "Disabled";
            reference.antiaim.angles.yaw:override(yaw);

            local yaw_offset = self.yaw_offset or 0;
            reference.antiaim.angles.yaw_add:override(yaw_offset);

            local yaw_base = self.yaw_base or "Local View";
            reference.antiaim.angles.yaw_base:override(yaw_base);

            local yaw_modifier = self.yaw_modifier or "Disabled";
            reference.antiaim.angles.yaw_modifier:override(yaw_modifier);

            local modifier_offset = self.modifier_offset or 0;
            reference.antiaim.angles.modifier_offset:override(modifier_offset);

            local left_limit, right_limit = self.left_limit or 0, self.right_limit or 0;
            reference.antiaim.angles.left_limit:override(left_limit);
            reference.antiaim.angles.right_limit:override(right_limit);

            local body_yaw = self.body_yaw or false;
            reference.antiaim.angles.body_yaw:override(body_yaw);

            local body_yaw_options = self.body_yaw_options or {};
            reference.antiaim.angles.options:override(body_yaw_options);

            local disable_yaw_modifiers = self.disable_yaw_modifiers or false;
            reference.antiaim.angles.disable_yaw_modifiers:override(disable_yaw_modifiers);

            local body_freestanding = self.body_freestanding or false;
            reference.antiaim.angles.body_freestanding:override(body_freestanding);

            local freestanding = self.freestanding or false;
            reference.antiaim.angles.freestanding:override(freestanding);

            local freestand_peek = self.freestand_peek or "Off";
            reference.antiaim.angles.freestand_peek:override(freestand_peek);

            local lag_options = self.lag_options or "On Peek";
            reference.rage.main.double_tap_lag_options:override(lag_options)

            local hs_options = self.hs_options or "Favor Fire Rate";
            reference.rage.main.hide_shots_options:override(hs_options)

            local avoid_backstab = self.avoid_backstab or false;
            reference.antiaim.angles.avoid_backstab:override(avoid_backstab);
        end

        antiaim:reset()
    end

    instance.create_antiaim = function()
        return setmetatable({}, {__index = antiaim})
    end
end

local builder = {}; do
    local data = instance.create_antiaim();

    local current_slider = 1;
    local current_modifier_slider = 1;

    local switch_delay = 0;
    local switch_modifier = 0;

    local side = false;
    local switch = false;

    local ticks = 0;
    local bobro = 1;

    local from_to_ticks = 0;
    local from_to_swap = false;

    function builder.get_exploit_values(offset, index)
        return ({
            [1] = -offset,
            [2] = -offset/2,
            [3] = -offset/3,
            [4] = offset/3,
            [5] = offset/2,
            [6] = offset
        })[index or 1]
    end

    function builder.get_preset(state, team)
        local items = menu.antiaim.angles.builder[state]

        if items == nil then
            return nil
        end

        return items[team]
    end

    function builder.update_yaw(e, ctx, data)
        ctx.pitch = "Down";
        ctx.yaw = data.yaw:get();
        ctx.yaw_base = "At Target";

        local yaw_type = data.yaw_mode:get();
        local is_delay = data.delay:get();

        local left_yaw = data.yaw_left:get();
        local right_yaw = data.yaw_right:get();

        local delay_mode = data.delay_method:get();
        local delay_ticks = data.delay_default:get();
        
        local min_delay = data.delay_random_min:get();
        local max_delay = data.delay_random_max:get();

        local delay_sliders = data.delay_custom_sliders:get();
        local current_slider_value = data["delay_" .. current_slider]:get() or 1;
        current_slider_value = math.max(current_slider_value, 1);

        local div = 1.95

        if yaw_type == "Solo" then
            ctx.yaw_offset = data.offset:get();
        elseif yaw_type == "L/R" then

            if is_delay then
                if e.choked_commands == 0 then
                    switch_delay = switch_delay + 1

                    if delay_mode == "Default" then
                        if switch_delay >= delay_ticks/div then
                            switch_delay = 0;
                            side = not side;
                        end
                    elseif delay_mode == "Random" then
                        if switch_delay >= utils.random_int(min_delay, max_delay)/div then
                            switch_delay = 0;
                            side = not side;
                        end
                    else
                        if switch_delay >= current_slider_value/div then
                            switch_delay = 0;
                            side = not side;

                            current_slider = current_slider + 1

                            if current_slider > delay_sliders then
                                current_slider = 1;
                            end
                        end
                    end
                end
                
                rage.antiaim:inverter(side);
                ctx.yaw_offset = side and left_yaw or right_yaw;
            else
                ctx.yaw_offset = rage.antiaim:inverter() and left_yaw or right_yaw;
            end
        end
    end

    function builder.update_body_yaw(e, ctx, data)
        local body_yaw = data.body_yaw:get();
        local body_yaw_options = data.body_yaw_options:get();
        local body_yaw_mode = data.mode:get()
        local body_yaw_ticks = data.mode_ticks:get();
        local body_yaw_ticks_random = data.mode_random:get();

        if body_yaw_mode == "Static" then
            ctx.body_yaw = body_yaw;
        elseif body_yaw_mode == "Ticks" and not reference.antiaim.misc.fake_duck:get() then
            local amount = body_yaw_ticks;

            if globals.tickcount % amount == 0 then
                switch = not switch
                ticks = 0
            end

            if not switch then
                ticks = ticks + 1
            end

            if ticks >= utils.random_int(2, 6) then
                switch = true
                ticks = 0
            end

            local trigger = utils.random_int(3, 6)


            if trigger == 1 or trigger == 2 then
                trigger = 9
            else
                trigger = trigger + 1
            end

            ctx.body_yaw = switch
        elseif body_yaw_mode == "Random" and not reference.antiaim.misc.fake_duck:get() then
            ctx.body_yaw = globals.tickcount % body_yaw_ticks_random == 0;
        end

        local body_yaw_limit_mode = data.limit_mode:get();
        local body_yaw_limit_minimum = data.minimum_limit:get();
        local body_yaw_limit_maximum = data.maximum_limit:get();

        local body_yaw_limit_from = data.from_limit:get();
        local body_yaw_limit_to = data.to_limit:get();

        local inverter = rage.antiaim:inverter();
        
        if body_yaw_limit_mode == "Speed-based Switch" then
            if e.choked_commands == 0 then
                from_to_ticks = from_to_ticks + 1
            end

            if from_to_ticks >= data.sb_speed:get() then
                from_to_ticks = 0;
                from_to_swap = not from_to_swap;
            end

            inverter = from_to_swap;
        end

        local left, right = 0, 0; do
            if body_yaw_limit_mode == "Static" then
                left = data.left_limit:get();
                right = data.right_limit:get();
            elseif body_yaw_limit_mode == "Random" then
                left = math.random(body_yaw_limit_minimum, body_yaw_limit_maximum);
                right = math.random(body_yaw_limit_minimum, body_yaw_limit_maximum)
            else
                left = inverter and body_yaw_limit_from or body_yaw_limit_to;
                right = inverter and body_yaw_limit_from or body_yaw_limit_to;
            end

            ctx.left_limit = left;
            ctx.right_limit = right;
        end

        ctx.freestand_peek = data.body_freestanding:get()
        ctx.body_yaw_options = body_yaw_options;
    end
    
    function builder.update_modifier(e, ctx, data)
        local yaw_modifier = data.modifier:get();
        local yaw_modifier_mode = data.modifier_mode:get();
        local yaw_modifier_randomize = data.randomize:get();
        local yaw_modifier_minimum = data.min:get();
        local yaw_modifier_maximum = data.max:get();
        local yaw_modifier_sliders = data.modifier_custom_sliders:get();
        local yaw_modifier_offset = data.modifier_offset:get();

        local current_slider_value = data["modifier_sliders_" .. current_modifier_slider]:get() or 1;
        current_slider_value = math.max(current_slider_value, 1);

        if e.choked_commands == 0 then  
            bobro = bobro + 1;
            if bobro >= 7 then
                bobro = 1;
            end
        end


        if yaw_modifier_randomize then
            if yaw_modifier_mode == "Default" then
                local value = math.random(yaw_modifier_minimum, yaw_modifier_maximum);
                ctx.modifier_offset = yaw_modifier == "Bobro" and builder.get_exploit_values(value, bobro) or value; 
            elseif yaw_modifier_mode == "Custom" then
                if e.choked_commands == 0 then
                    switch_modifier = switch_modifier + 1;
                    if switch_modifier >= current_slider_value then
                        switch_modifier = 0;
                        current_modifier_slider = current_modifier_slider + 1;

                        if current_modifier_slider > yaw_modifier_sliders then
                            current_modifier_slider = 1;
                        end
                    end
                end

                local default_value = data["modifier_sliders_" .. current_modifier_slider]:get();
                local bober_value = builder.get_exploit_values(default_value, bobro);
                ctx.modifier_offset = yaw_modifier == "Bobro" and bober_value or default_value;
            end
        else
            local bober_value = builder.get_exploit_values(yaw_modifier_offset, bobro);
            ctx.modifier_offset = yaw_modifier == "Bobro" and bober_value or yaw_modifier_offset;
        end

        ctx.yaw_modifier = yaw_modifier == "Bobro" and "3-Way" or yaw_modifier;
    end 

    function builder.update(e, condition, player)
        data:define();

        local team = player.m_iTeamNum == 2 and "T" or "CT";
        local items = builder.get_preset(condition, team)

        if items == nil then
            return
        end

        if not items.allow_state:get() then goto continue end

        data.avoid_backstab = menu.antiaim.main.additional.backstab.switch:get();
        
        builder.update_yaw(e, data, items)
        builder.update_body_yaw(e, data, items)
        builder.update_modifier(e, data, items)

        anti_bruteforce.update(e, data)

        break_lc.update(e, data, items)
        warmup_aa.update(e, data, items)

        local is_legit_aa = legit_aa.think(e);
        if is_legit_aa then
            legit_aa.update(e, data, items)
            data:run()
            return
        end;

        safe_head.update(e, data, items)
        
        local is_manual_aa = manual_aa.think()
        local is_freestand = freestanding.think()
        

        if menu.antiaim.angles.freestanding.prefer_manual:get() and is_manual_aa then
            manual_aa.update(e, data, items)
        elseif is_freestand then
            freestanding.update(e, data, items)
        else
            manual_aa.update(e, data, items)
        end


        data:run()

        ::continue::
    end

    local function callback(e)
        local me = entity.get_local_player()
        local is_legit_aa = legit_aa.think(e)
        local condition = conditions.get(is_legit_aa);

        builder.update(e, condition, me)
    end

    events.createmove(callback)
end

pui.setup(menu)
