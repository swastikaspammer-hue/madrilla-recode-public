local menu = require("madrilla_recode/menu")
local surface = require("gamesense/surface") or surface
local images = require("gamesense/images")
local solus_ui = require("madrilla_recode/solus_ui")

local hud = {}

local font_big = surface.create_font("Verdana", 24, 800, 0x010 + 0x080)
local font_small = surface.create_font("Verdana", 12, 700, 0x010 + 0x080)
local font_huge = surface.create_font("Verdana", 36, 800, 0x010 + 0x080)

local last_active_weapon = nil
local last_switch_time = 0
local current_am_w = 160
local custom_hud_active = false
local round_end_time = 0
local round_end_winner = 0
local round_end_text = ""
local ct_score = 0
local t_score = 0
local is_warmup = false

-- ONE-TIME RESCUE: Forcefully restore the entire Scoreboard from any previous broken states
panorama.loadstring([[
    var sb = $.GetContextPanel().FindChildTraverse("Scoreboard");
    if (sb) {
        var clean = function(p) {
            if (!p) return;
            if (p.style && p.style.visibility === "collapse") {
                p.style.opacity = "1.0";
                p.style.visibility = "visible";
            }
            if (typeof p.GetChildCount === 'function') {
                for (var i=0; i<p.GetChildCount(); i++) clean(p.GetChild(i));
            }
        };
        clean(sb);
    }
]], "CSGOHud")()

local hud_state = {
    lerped_hp = 100,
    lerped_ap = 100,
    damage_pulse = 0,
    last_hp = 100,
    lerped_ammo = 0,
    panorama_hidden = false,
    spec_hidden = false,
    last_spec_target = 0,
}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local cached_icons = {}
local function get_icon(idx)
    if cached_icons[idx] == nil then
        local success, img = pcall(images.get_weapon_icon, idx)
        if success and img then
            cached_icons[idx] = img
        else
            cached_icons[idx] = false
        end
    end
    return cached_icons[idx]
end

local cached_armor_icons = {}
local function get_armor_icon(has_helmet)
    local key = has_helmet and "helmet" or "kevlar"
    if cached_armor_icons[key] == nil then
        local success, img
        if has_helmet then
            success, img = pcall(images.get_weapon_icon, "item_assaultsuit")
        else
            success, img = pcall(images.get_weapon_icon, "item_kevlar")
        end
        if success and img then
            cached_armor_icons[key] = img
        else
            cached_armor_icons[key] = false
        end
    end
    return cached_armor_icons[key]
end

local cached_game_rules = nil
local function get_game_rules()
    if not cached_game_rules or entity.get_prop(cached_game_rules, "m_bWarmupPeriod") == nil then
        local rules = entity.get_all("CCSGameRulesProxy")
        cached_game_rules = rules and rules[1] or nil
    end
    return cached_game_rules
end

local cached_teams = nil
local function get_teams()
    if not cached_teams or #cached_teams == 0 or entity.get_prop(cached_teams[1], "m_iTeamNum") == nil then
        cached_teams = entity.get_all("CCSTeam")
    end
    return cached_teams
end

local cached_bomb = nil
local function get_bomb()
    if not cached_bomb or entity.get_prop(cached_bomb, "m_flC4Blow") == nil then
        local bombs = entity.get_all("CPlantedC4")
        cached_bomb = bombs and bombs[1] or nil
    end
    return cached_bomb
end

client.set_event_callback("round_end", function(e)
    round_end_winner = e.winner
    round_end_time = globals.curtime()
    if e.winner == 2 then
        round_end_text = "TERRORISTS WIN"
    elseif e.winner == 3 then
        round_end_text = "COUNTER-TERRORISTS WIN"
    else
        round_end_text = "ROUND DRAW"
    end
    
    if ui.get(menu.hud.customHud.enable) then
        local hide_method = ui.get(menu.hud.customHud.hideMethod)
        local opts = ui.get(menu.hud.customHud.options)
        local wants_banner = false
        for i=1, #opts do
            if opts[i] == "Round End Banner" then wants_banner = true break end
        end

        if wants_banner or hide_method == "Panorama (Best: Hides Native, Keeps Chat/Switch)" then
            local js = [[
                var hud = $.GetContextPanel();
                if (hud) {
                    var ids = [
                        "WinPanel", "WinPanelMatch", "WinPanelBasic", "EndMatch",
                        "WinPanelRoot", "HudWinPanel", "SFWinPanel", "CSGOHudWinPanel", "RoundEnd"
                    ];
                    for (var i=0; i<ids.length; i++) {
                        var p = hud.FindChildTraverse(ids[i]);
                        if (p) {
                            p.style.opacity = "0";
                            p.style.visibility = "collapse";
                        }
                    }
                }
            ]]
            panorama.loadstring(js, "CSGOHud")()
            client.delay_call(0.1, function() panorama.loadstring(js, "CSGOHud")() end)
            client.delay_call(0.5, function() panorama.loadstring(js, "CSGOHud")() end)
            client.delay_call(1.0, function() panorama.loadstring(js, "CSGOHud")() end)
        end
    end
end)

client.set_event_callback("round_start", function(e)
    round_end_winner = 0
end)


local weapon_y_offsets = {
    [46] = 12, -- Molotov
    [48] = 12, -- Incendiary
    [44] = 4,  -- HE
    [43] = 4,  -- Flash
    [45] = 4,  -- Smoke
    [47] = 4,  -- Decoy
    [49] = -12 -- C4
}

local function get_weapon_slot(wep)
    local idx = bit.band(entity.get_prop(wep, "m_iItemDefinitionIndex") or 0, 0xFFFF)
    if idx == 49 then return 5 end -- C4
    
    local grenades = {
        [44] = 4.1, -- HE
        [43] = 4.2, -- Flash
        [45] = 4.3, -- Smoke
        [47] = 4.4, -- Decoy
        [46] = 4.5, -- Molotov
        [48] = 4.5  -- Incendiary
    }
    if grenades[idx] then return grenades[idx] end
    
    local knives = {[42]=true, [59]=true}
    if knives[idx] or idx >= 500 then return 3 end -- Knife
    if idx == 31 then return 3 end -- Zeus
    
    local pistols = {
        [1]=true, [2]=true, [3]=true, [4]=true, [30]=true, 
        [32]=true, [36]=true, [61]=true, [63]=true, [64]=true
    }
    if pistols[idx] then return 2 end
    
    return 1 -- Primary
end

function hud.OnPaintUI()
    local me = entity.get_local_player()
    local is_enabled = ui.get(menu.hud.customHud.enable)
    
    -- Cleanup and restore if disabled or not in game
    if not is_enabled or me == nil then
        cvar.cl_draw_only_deathnotices:set_raw_int(0)
        cvar.cl_drawhud_force_radar:set_raw_int(-1)
        
        local current_target = me
        if me ~= nil and not entity.is_alive(me) then
            current_target = entity.get_prop(me, "m_hObserverTarget") or me
        end
        if current_target and current_target ~= 0 then
            entity.set_prop(current_target, "m_iHideHUD", 0)
        end
        
        if hud_state.panorama_hidden then
            panorama.loadstring([[
                $.madrilla_recode_hide_loop = false;
                var hud = $.GetContextPanel();
                if (hud) {
                    var ids = [
                        "HudTeamCounter", "HudHealthArmor", "HudWeaponSelection", "HudAmmo", "SFHudAmmo",
                        "WinPanel", "WinPanelMatch", "WinPanelBasic", "EndMatch",
                        "WinPanelRoot", "HudWinPanel", "SFWinPanel", "CSGOHudWinPanel", "RoundEnd",
                        "HudSpectatorDeathNotice", "HudObserverElements", 
                        "SFHudSpectator", "HudSpectatorPanel", "HudSpectator", "ObserverPanel",
                        "Ammo", "Health", "HealthArmor", "WeaponSelection"
                    ];
                    for (var i = 0; i < ids.length; i++) {
                        var p = hud.FindChildTraverse(ids[i]);
                        if (p) {
                            p.style.opacity = "1.0";
                            p.style.visibility = "visible";
                        }
                    }
                    var restore_recursively = function(panel) {
                        if (!panel) return;
                        if (panel.id) {
                            var lowerId = panel.id.toLowerCase();
                            if (lowerId.indexOf("score") !== -1 || lowerId.indexOf("freezepanel") !== -1 || lowerId.indexOf("deathpanel") !== -1) return;
                            if (lowerId.indexOf("damage") !== -1 || lowerId.indexOf("report") !== -1 || lowerId.indexOf("info") !== -1 || lowerId.indexOf("killer") !== -1 || lowerId.indexOf("nemesis") !== -1) return;
                            if (lowerId.indexOf("avatar") !== -1 || lowerId.indexOf("player") !== -1 || lowerId.indexOf("image") !== -1 || lowerId.indexOf("icon") !== -1) return;
                            if (lowerId.indexOf("killstreak") !== -1 || lowerId.indexOf("streak") !== -1 || lowerId.indexOf("skull") !== -1) {
                                panel.style.opacity = "1.0";
                                panel.style.visibility = "visible";
                            } else if (lowerId.indexOf("deathnotice") === -1) { // Exempt killfeed
                                if (lowerId.indexOf("ammo") !== -1 || 
                                    lowerId.indexOf("winpanel") !== -1 ||
                                    lowerId.indexOf("spectator") !== -1 ||
                                    lowerId.indexOf("observer") !== -1 ||
                                    lowerId.indexOf("defuser") !== -1 ||
                                    lowerId.indexOf("defus") !== -1 ||
                                    lowerId.indexOf("rescue") !== -1 ||
                                    lowerId.indexOf("health") !== -1 ||
                                    lowerId.indexOf("armor") !== -1 ||
                                    lowerId.indexOf("target") !== -1 ||
                                    lowerId.indexOf("spec") !== -1 ||
                                    lowerId.indexOf("obs") !== -1 ||
                                    lowerId.indexOf("control") !== -1) {
                                    if (lowerId.indexOf("weapon") === -1 && lowerId.indexOf("inventory") === -1) {
                                        panel.style.opacity = "1.0";
                                        panel.style.visibility = "visible";
                                    }
                                }
                            }
                        }
                        if (typeof panel.GetChildCount === 'function') {
                            var count = panel.GetChildCount();
                            for (var j = 0; j < count; j++) {
                                restore_recursively(panel.GetChild(j));
                            }
                        }
                    };
                    restore_recursively(hud);
                }
            ]], "CSGOHud")()
            hud_state.panorama_hidden = false
        end
        return
    end

    local target = me
    if not entity.is_alive(me) then
        target = entity.get_prop(me, "m_hObserverTarget")
    end

    if target == nil or target == 0 or not entity.is_alive(target) then
        cvar.cl_draw_only_deathnotices:set_raw_int(0)
        cvar.cl_drawhud_force_radar:set_raw_int(-1)
        return
    end

    local hide_method = ui.get(menu.hud.customHud.hideMethod)
    cvar.cl_drawhud_force_radar:set_raw_int(-1)
    
    local is_panorama_hide = (hide_method == "Panorama (Best: Hides Native, Keeps Chat/Switch)")

    if not hud_state.panorama_hidden and is_panorama_hide then
        panorama.loadstring([[
            if (!$.madrilla_recode_hide_loop) {
                $.madrilla_recode_hide_loop = true;
                var nuke_recursively = function(panel) {
                    if (!panel) return;
                    if (panel.id) {
                        var lowerId = panel.id.toLowerCase();
                        if (lowerId.indexOf("score") !== -1) return; // Exempt scoreboard completely
                        if (lowerId.indexOf("freezepanel") !== -1 || lowerId.indexOf("deathpanel") !== -1) return; // Exempt death panel
                        if (lowerId.indexOf("damage") !== -1 || lowerId.indexOf("report") !== -1 || lowerId.indexOf("info") !== -1 || lowerId.indexOf("killer") !== -1 || lowerId.indexOf("nemesis") !== -1) return;

                        if (lowerId.indexOf("killstreak") !== -1 || lowerId.indexOf("streak") !== -1 || lowerId.indexOf("skull") !== -1) {
                            panel.style.opacity = "0";
                            panel.style.visibility = "collapse";
                            return;
                        }

                        if (lowerId.indexOf("deathnotice") === -1) { // Exempt killfeed
                            if (lowerId.indexOf("ammo") !== -1 || 
                                lowerId.indexOf("winpanel") !== -1 ||
                                lowerId.indexOf("spectator") !== -1 ||
                                lowerId.indexOf("observer") !== -1 ||
                                lowerId.indexOf("defuser") !== -1 ||
                                lowerId.indexOf("defus") !== -1 ||
                                lowerId.indexOf("rescue") !== -1 ||
                                lowerId.indexOf("health") !== -1 ||
                                lowerId.indexOf("armor") !== -1 ||
                                lowerId.indexOf("target") !== -1 ||
                                lowerId.indexOf("spec") !== -1 ||
                                lowerId.indexOf("obs") !== -1 ||
                                lowerId.indexOf("control") !== -1) {
                                if (lowerId.indexOf("weapon") === -1 && lowerId.indexOf("inventory") === -1) {
                                    panel.style.opacity = "0";
                                    panel.style.visibility = "collapse";
                                }
                            }
                        }
                    }
                    if (typeof panel.GetChildCount === 'function') {
                        var count = panel.GetChildCount();
                        for (var j = 0; j < count; j++) {
                            nuke_recursively(panel.GetChild(j));
                        }
                    }
                };
                var hide_hud = function() {
                    if (!$.madrilla_recode_hide_loop) return;
                    var hud = $.GetContextPanel();
                    if (hud) {
                        var ids = [
                            "HudTeamCounter", "HudHealthArmor", "HudWeaponSelection", "HudAmmo", "SFHudAmmo",
                            "WinPanel", "WinPanelMatch", "WinPanelBasic", "EndMatch",
                            "WinPanelRoot", "HudWinPanel", "SFWinPanel", "CSGOHudWinPanel", "RoundEnd",
                            "Ammo", "Health", "HealthArmor", "WeaponSelection"
                        ];
                        for (var i = 0; i < ids.length; i++) {
                            var p = hud.FindChildTraverse(ids[i]);
                            if (p) {
                                p.style.opacity = "0";
                                p.style.visibility = "collapse";
                            }
                        }
                        nuke_recursively(hud);
                    }
                    $.Schedule(0.05, hide_hud);
                };
                hide_hud();
            }
        ]], "CSGOHud")()
        hud_state.panorama_hidden = true
    elseif hud_state.panorama_hidden and not is_panorama_hide then
        panorama.loadstring([[
            $.madrilla_recode_hide_loop = false;
            var hud = $.GetContextPanel();
            if (hud) {
                var ids = [
                    "HudTeamCounter", "HudHealthArmor", "HudWeaponSelection", "HudAmmo", "SFHudAmmo",
                    "WinPanel", "WinPanelMatch", "WinPanelBasic", "EndMatch",
                    "WinPanelRoot", "HudWinPanel", "SFWinPanel", "CSGOHudWinPanel", "RoundEnd",
                    "HudSpectatorDeathNotice", "HudObserverElements", 
                    "SFHudSpectator", "HudSpectatorPanel", "HudSpectator", "ObserverPanel",
                    "Ammo", "Health", "HealthArmor", "WeaponSelection"
                ];
                for (var i = 0; i < ids.length; i++) {
                    var p = hud.FindChildTraverse(ids[i]);
                    if (p) {
                        p.style.opacity = "1.0";
                        p.style.visibility = "visible";
                    }
                }
                var restore_recursively = function(panel) {
                    if (!panel) return;
                    if (panel.id) {
                        var lowerId = panel.id.toLowerCase();
                        if (lowerId.indexOf("score") !== -1 || lowerId.indexOf("freezepanel") !== -1 || lowerId.indexOf("deathpanel") !== -1) return;
                        if (lowerId.indexOf("damage") !== -1 || lowerId.indexOf("report") !== -1 || lowerId.indexOf("info") !== -1 || lowerId.indexOf("killer") !== -1 || lowerId.indexOf("nemesis") !== -1) return;
                        if (lowerId.indexOf("avatar") !== -1 || lowerId.indexOf("player") !== -1 || lowerId.indexOf("image") !== -1 || lowerId.indexOf("icon") !== -1) return;
                        if (lowerId.indexOf("killstreak") !== -1 || lowerId.indexOf("streak") !== -1 || lowerId.indexOf("skull") !== -1) {
                            panel.style.opacity = "1.0";
                            panel.style.visibility = "visible";
                        } else if (lowerId.indexOf("deathnotice") === -1) { // Exempt killfeed
                            if (lowerId.indexOf("ammo") !== -1 || 
                                lowerId.indexOf("winpanel") !== -1 ||
                                lowerId.indexOf("spectator") !== -1 ||
                                lowerId.indexOf("observer") !== -1 ||
                                lowerId.indexOf("defuser") !== -1 ||
                                lowerId.indexOf("defus") !== -1 ||
                                lowerId.indexOf("rescue") !== -1 ||
                                lowerId.indexOf("health") !== -1 ||
                                lowerId.indexOf("armor") !== -1 ||
                                lowerId.indexOf("target") !== -1 ||
                                lowerId.indexOf("spec") !== -1 ||
                                lowerId.indexOf("obs") !== -1 ||
                                lowerId.indexOf("control") !== -1) {
                                if (lowerId.indexOf("weapon") === -1 && lowerId.indexOf("inventory") === -1) {
                                    panel.style.opacity = "1.0";
                                    panel.style.visibility = "visible";
                                }
                            }
                        }
                    }
                    if (typeof panel.GetChildCount === 'function') {
                        var count = panel.GetChildCount();
                        for (var j = 0; j < count; j++) {
                            restore_recursively(panel.GetChild(j));
                        }
                    }
                };
                restore_recursively(hud);
            }
        ]], "CSGOHud")()
        hud_state.panorama_hidden = false
    end



    if hide_method == "Deathnotices (Hides Topbar, Breaks Chat)" then
        cvar.cl_draw_only_deathnotices:set_raw_int(1)
        if entity.is_alive(me) then
            entity.set_prop(me, "m_iHideHUD", 0)
        end
    else
        cvar.cl_draw_only_deathnotices:set_raw_int(0)
        local current_hide = entity.get_prop(target, "m_iHideHUD") or 0
        current_hide = bit.band(current_hide, bit.bnot(128)) -- ensure Chat (128) is never hidden

        if hide_method == "Hide Weapon Selection (Breaks Switch)" then
            entity.set_prop(target, "m_iHideHUD", bit.bor(current_hide, 1, 8, 256)) -- Removed 64 to allow !admin menus
        elseif hide_method == "Keep Weapon Selection (Allows Chat)" or hide_method == "Panorama (Best: Hides Native, Keeps Chat/Switch)" then
            -- For Panorama method, we still use m_iHideHUD to reliably hide Ammo, Health, and Crosshair 
            -- because the CS:GO engine dynamically overrides Javascript styles for these specific elements.
            local additional_hide = bit.bor(8, 256) -- Removed 64 to allow !admin menus
            if not entity.is_alive(me) then
                additional_hide = bit.bor(additional_hide, 1) -- Hide spectator weapon panel (and killstreaks) natively
            end
            entity.set_prop(target, "m_iHideHUD", bit.bor(current_hide, additional_hide))
        else
            -- Disabled
            entity.set_prop(target, "m_iHideHUD", 0)
        end
    end
    
    -- Hide native killfeed if custom killfeed is enabled
    if ui.get(menu.hud.customKillfeed.enable) then
        cvar.cl_drawhud_force_deathnotices:set_raw_int(-1)
    else
        cvar.cl_drawhud_force_deathnotices:set_raw_int(0)
    end

    local global_acc_r, global_acc_g, global_acc_b, global_acc_a = ui.get(menu.config.accent)
    local acc_r, acc_g, acc_b, acc_a = ui.get(menu.hud.customHud.accentColor)
    local bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customHud.bgColor)
    
    local tr, tg, tb, ta = ui.get(menu.hud.customHud.tColor)
    local ctr, ctg, ctb, cta = ui.get(menu.hud.customHud.ctColor)

    local options = ui.get(menu.hud.customHud.options)
    local function has_option(opt)
        for i=1, #options do
            if options[i] == opt then return true end
        end
        return false
    end

    local sx, sy = client.screen_size()
    
    -- --- Top Bar (Score & Time) ---
    if has_option("Top Bar") then
        local top_w = 300
        local top_h = 46
        local top_x = math.floor((sx / 2) - (top_w / 2)) + ui.get(menu.hud.customHud.topBarX)
        local top_y = 15 + ui.get(menu.hud.customHud.topBarY)

        solus_ui.container_glow(top_x, top_y, top_w, top_h, acc_r, acc_g, acc_b, bg_a, 1, acc_r, acc_g, acc_b)

        local game_rules = get_game_rules()
        local ct_score = 0
        local t_score = 0
        local round_num = 1
        local time_str = "0:00"
        local bomb_active = false

        if game_rules then
            local teams = get_teams()
            for i=1, #teams do
                local tnum = entity.get_prop(teams[i], "m_iTeamNum")
                local score = entity.get_prop(teams[i], "m_scoreTotal") or 0
                if tnum == 2 then t_score = score end
                if tnum == 3 then ct_score = score end
            end
            
            local total_rounds = t_score + ct_score
            round_num = total_rounds + 1
            
            local start_time = entity.get_prop(game_rules, "m_fRoundStartTime") or 0
            local round_time = entity.get_prop(game_rules, "m_iRoundTime") or 0
            local cur_time = globals.curtime()
            
            local time_left = math.max(0, math.ceil((start_time + round_time) - cur_time))
            
            local bomb = get_bomb()
            if bomb then
                local bomb_time = entity.get_prop(bomb, "m_flC4Blow") or 0
                time_left = math.max(0, math.ceil(bomb_time - cur_time))
                bomb_active = true
            end
            
            local is_warmup = entity.get_prop(game_rules, "m_bWarmupPeriod") == 1
            
            local mins = math.floor(time_left / 60)
            local secs = time_left % 60
            
            if is_warmup then
                time_str = "WARMUP"
            elseif bomb_active then
                time_str = string.format("BOMB  %02d", secs)
            else
                time_str = string.format("%d:%02d", mins, secs)
            end
        end

        -- Draw CT Side (Left)
        surface.draw_filled_rect(top_x, top_y, math.floor(top_w / 2), 3, ctr, ctg, ctb, cta)
        surface.draw_text(top_x + 20, top_y + 12, ctr, ctg, ctb, 255, font_big, tostring(ct_score))
        
        -- Draw T Side (Right)
        surface.draw_filled_rect(top_x + math.floor(top_w / 2), top_y, math.floor(top_w / 2), 3, tr, tg, tb, ta)
        local tsw, _ = surface.get_text_size(font_big, tostring(t_score))
        surface.draw_text(top_x + top_w - 20 - tsw, top_y + 12, tr, tg, tb, 255, font_big, tostring(t_score))

        -- Center Text (Round & Time)
        local tr_w, _ = surface.get_text_size(font_small, "ROUND " .. round_num)
        surface.draw_text((sx / 2) - (tr_w / 2), top_y + 8, 200, 200, 200, 255, font_small, "ROUND " .. round_num)
        
        local tt_w, _ = surface.get_text_size(font_big, time_str)
        if bomb_active then
            surface.draw_text((sx / 2) - (tt_w / 2), top_y + 20, 255, 50, 50, 255, font_big, time_str)
        else
            surface.draw_text((sx / 2) - (tt_w / 2), top_y + 20, 255, 255, 255, 255, font_big, time_str)
        end
    end

    -- Round End Banner
    if has_option("Round End Banner") and round_end_winner ~= 0 and globals.curtime() < round_end_time + 5.0 then
        local banner_w = 400
        local banner_h = 50
        local banner_x = (sx / 2) - (banner_w / 2)
        local banner_y = (sy / 4)

        local r, g, b = 255, 255, 255
        if round_end_winner == 2 then
            r, g, b = tr, tg, tb
        elseif round_end_winner == 3 then
            r, g, b = ctr, ctg, ctb
        end

        solus_ui.container_glow(banner_x, banner_y, banner_w, banner_h, r, g, b, bg_a, 1, r, g, b)

        local tw, _ = surface.get_text_size(font_big, round_end_text)
        surface.draw_text((sx / 2) - (tw / 2), banner_y + 13, r, g, b, 255, font_big, round_end_text)
    end

    local hp = entity.get_prop(target, "m_iHealth") or 0
    local frametime = globals.frametime()
    
    if hp < hud_state.last_hp then
        hud_state.damage_pulse = 1.0
    end
    hud_state.last_hp = hp
    hud_state.damage_pulse = lerp(hud_state.damage_pulse, 0, frametime * 4)

    local pulse_alpha = math.floor(hud_state.damage_pulse * 150)

    -- --- Damage Flash (Screen Vignette) ---
    if has_option("Damage Flash") and pulse_alpha > 0 then
        local thick = 40
        surface.draw_filled_gradient_rect(0, 0, sx, thick, 255, 0, 0, pulse_alpha, 255, 0, 0, 0, false)
        surface.draw_filled_gradient_rect(0, sy - thick, sx, thick, 255, 0, 0, 0, 255, 0, 0, pulse_alpha, false)
        surface.draw_filled_gradient_rect(0, 0, thick, sy, 255, 0, 0, pulse_alpha, 255, 0, 0, 0, true)
        surface.draw_filled_gradient_rect(sx - thick, 0, thick, sy, 255, 0, 0, 0, 255, 0, 0, pulse_alpha, true)
    end

    -- --- Health & Armor (Bottom Left) ---
    if has_option("Health & Armor") then
        hud_state.lerped_hp = lerp(hud_state.lerped_hp, hp, frametime * 8)

        local hp_w = 210
        local hp_h = 60
        local hp_x = 20 + ui.get(menu.hud.customHud.healthX)
        local hp_y = sy - hp_h - 20 + ui.get(menu.hud.customHud.healthY)

        -- Container Left
        solus_ui.container_glow(hp_x, hp_y, hp_w, hp_h, acc_r, acc_g, acc_b, bg_a, 1, acc_r, acc_g, acc_b)
        
        -- Damage glow (red pulse)
        if pulse_alpha > 0 then
            surface.draw_filled_rect(hp_x, hp_y, hp_w, hp_h, 255, 50, 50, pulse_alpha)
        end

        surface.draw_filled_rect(hp_x, hp_y, hp_w, 1, math.floor(acc_r * 0.4), math.floor(acc_g * 0.4), math.floor(acc_b * 0.4), 100)
        
        -- Draw the health bar (animated, gradient)
        local bar_w = hp_w - 4
        local hp_bar_w = math.max(0, math.min(bar_w, math.floor((hud_state.lerped_hp / 100) * bar_w)))

        if hp_bar_w > 0 then
            surface.draw_filled_gradient_rect(hp_x + 3, hp_y + hp_h - 4, hp_bar_w, 2, acc_r, acc_g, acc_b, acc_a, math.floor(acc_r*0.5), math.floor(acc_g*0.5), math.floor(acc_b*0.5), acc_a, true)
        end

        surface.draw_filled_rect(hp_x, hp_y, 3, hp_h, acc_r, acc_g, acc_b, acc_a)

        -- Calculate HP text color: White > 93, Yellow at 93, fading to Red at 50
        local text_r = 255
        local text_g = hp > 93 and 255 or math.max(0, math.min(255, math.floor(((hp - 50) / 43) * 255)))
        local text_b = hp > 93 and 255 or 0

        -- Content Left
        surface.draw_text(hp_x + 16, hp_y + 12, text_r, text_g, text_b, 255, font_huge, tostring(hp))
        local hp_str_w = surface.get_text_size(font_huge, tostring(hp))
        surface.draw_text(hp_x + 20 + hp_str_w, hp_y + 30, 150, 150, 150, 255, font_small, "HP")

        -- Armor Icon
        local ap = entity.get_prop(target, "m_ArmorValue") or 0
        local has_helmet = entity.get_prop(target, "m_bHasHelmet") == 1
        
        if ap > 0 then
            local a_img = get_armor_icon(has_helmet)
            if a_img then
                -- Scale down the panorama svg icon
                local aw, ah = a_img:measure()
                if aw > 0 and ah > 0 then
                    local scale = math.min(30 / aw, 26 / ah)
                    local icon_w = math.floor(aw * scale)
                    local icon_h = math.floor(ah * scale)
                    a_img:draw(hp_x + hp_w - icon_w - 15, hp_y + (hp_h / 2) - (icon_h / 2) - 2, icon_w, icon_h, 255, 255, 255, 200)
                end
            end
        end
    end

    -- --- Ammo & Weapon (Bottom Right) ---
    if has_option("Ammo") then
        local active_weapon = entity.get_prop(target, "m_hActiveWeapon")
        if active_weapon then
            if active_weapon ~= last_active_weapon then
                last_active_weapon = active_weapon
                last_switch_time = globals.realtime()
            end

            local time_since_switch = globals.realtime() - last_switch_time
            local list_alpha_mult = 1.0
            if time_since_switch > 3.0 then
                list_alpha_mult = math.max(0, 1.0 - ((time_since_switch - 3.0) * 2)) -- fades out in 0.5s
            end
            
            if list_alpha_mult > 0 then
                local my_weapons = {}
                for i = 0, 63 do
                    local wep = entity.get_prop(target, "m_hMyWeapons", i)
                    if wep ~= nil and wep ~= 0 then
                        table.insert(my_weapons, { ent = wep, slot = get_weapon_slot(wep) })
                    end
                end
                table.sort(my_weapons, function(a, b) 
                    if a.slot == b.slot then return a.ent < b.ent end
                    return a.slot < b.slot 
                end)
                
                local list_w_max = 120 -- just for calculating total height if we need it, but we don't
                local wep_h = 36
                local wep_pad = 4
                local list_h = #my_weapons * (wep_h + wep_pad)
                local list_y = (sy / 2) - (list_h / 2) + ui.get(menu.hud.customHud.ammoY)
                
                for i, item in ipairs(my_weapons) do
                    local is_active = (item.ent == active_weapon)
                    local wep_y = list_y + (i - 1) * (wep_h + wep_pad)
                    
                    local box_a = math.floor((is_active and bg_a or (bg_a * 0.5)) * list_alpha_mult)
                    local content_a = math.floor((is_active and 255 or 150) * list_alpha_mult)
                    
                    local wep_idx = bit.band(entity.get_prop(item.ent, "m_iItemDefinitionIndex") or 0, 0xFFFF)
                    local weapon_img = get_icon(wep_idx)
                    
                    local scaled_w, scaled_h = 0, 0
                    if weapon_img then
                        local w_w, w_h = weapon_img:measure()
                        if w_w > 0 and w_h > 0 then
                            local scale_w = 60 / w_w
                            local scale_h = 24 / w_h
                            local scale = math.min(scale_w, scale_h)
                            scaled_w = math.floor(w_w * scale)
                            scaled_h = math.floor(w_h * scale)
                        end
                    end
                    
                    local wep_w = math.max(60, scaled_w + 30)
                    local wep_x = sx - wep_w - 20 + ui.get(menu.hud.customHud.ammoX)
                    
                    if is_active then
                        solus_ui.container_glow(wep_x, wep_y, wep_w, wep_h, acc_r, acc_g, acc_b, box_a, list_alpha_mult, acc_r, acc_g, acc_b)
                        surface.draw_filled_rect(wep_x + wep_w - 3, wep_y, 3, wep_h, acc_r, acc_g, acc_b, math.floor(255 * list_alpha_mult))
                    else
                        solus_ui.container(wep_x, wep_y, wep_w, wep_h, 0, 0, 0, box_a, 0)
                    end
                    
                    if weapon_img and scaled_w > 0 then
                        local icon_x = wep_x + (wep_w / 2) - (scaled_w / 2)
                        local icon_y = wep_y + (wep_h / 2) - (scaled_h / 2)
                        
                        weapon_img:draw(icon_x, icon_y, scaled_w, scaled_h, 255, 255, 255, content_a)
                    end
                end
            end

            local clip = entity.get_prop(active_weapon, "m_iClip1")
            local has_ammo = (clip ~= nil and clip >= 0)
            local reserve = 0
            local clip_str, res_str = "", ""
            local cw, rw = 0, 0
            
            if has_ammo then
                reserve = entity.get_prop(active_weapon, "m_iPrimaryReserveAmmoCount") or 0
                clip_str = tostring(clip)
                res_str = "/" .. tostring(reserve)
                
                cw, _ = surface.get_text_size(font_big, clip_str)
                rw, _ = surface.get_text_size(font_small, res_str)
            end

            local active_idx = bit.band(entity.get_prop(active_weapon, "m_iItemDefinitionIndex") or 0, 0xFFFF)
            local weapon_img = get_icon(active_idx)
            local icon_w, icon_h = 0, 0
            
            if weapon_img then
                local w_w, w_h = weapon_img:measure()
                if w_w > 0 and w_h > 0 then
                    local scale_w = 60 / w_w
                    local scale_h = 24 / w_h
                    local scale = math.min(scale_w, scale_h)
                    icon_w = math.floor(w_w * scale)
                    icon_h = math.floor(w_h * scale)
                end
            end

            local target_am_w = 30 + icon_w
            if has_ammo then
                target_am_w = target_am_w + 15 + cw + 2 + rw
            end
            target_am_w = math.max(100, target_am_w)
            
            current_am_w = current_am_w + (target_am_w - current_am_w) * globals.frametime() * 15

            local am_w = math.floor(current_am_w)
            local am_h = 50
            local am_x = sx - am_w - 20 + ui.get(menu.hud.customHud.ammoX)
            local am_y = sy - am_h - 20 + ui.get(menu.hud.customHud.ammoY)
            local text_start_x = am_x + am_w - 15

            solus_ui.container_glow(am_x, am_y, am_w, am_h, acc_r, acc_g, acc_b, bg_a, 1, acc_r, acc_g, acc_b)
            surface.draw_filled_rect(am_x, am_y, am_w, 1, math.floor(acc_r * 0.4), math.floor(acc_g * 0.4), math.floor(acc_b * 0.4), 100)
            surface.draw_filled_rect(am_x + am_w - 3, am_y, 3, am_h, acc_r, acc_g, acc_b, acc_a)

            if has_ammo then
                local tx = am_x + am_w - 15 - rw
                surface.draw_text(tx, am_y + 20, 150, 150, 150, 255, font_small, res_str)
                
                tx = tx - cw - 2
                surface.draw_text(tx, am_y + 10, 255, 255, 255, 255, font_big, clip_str)
                text_start_x = tx
            end

            if weapon_img and icon_w > 0 then
                local space_w = text_start_x - am_x
                local icon_x = am_x + (space_w / 2) - (icon_w / 2)
                local icon_y = am_y + (am_h / 2) - (icon_h / 2)
                local offset_y = weapon_y_offsets[active_idx] or 0
                weapon_img:draw(icon_x, icon_y + offset_y, icon_w, icon_h, 255, 255, 255, 255)
            end
        end
    end

    -- --- Spectator Center Panel ---
    local is_spectating = not entity.is_alive(me) and target ~= me
    if has_option("Spectator Panel") and is_spectating then
        -- Resolve observer mode name
        local obs_mode = entity.get_prop(me, "m_iObserverMode") or 0
        local obs_mode_names = { [0]="FREE", [1]="DEATHCAM", [2]="FREEZECAM", [3]="FIXED", [4]="IN-EYE", [5]="CHASE", [6]="ROAMING" }
        local obs_label = obs_mode_names[obs_mode] or "SPECTATING"

        -- Get target info
        local target_name = entity.get_player_name(target) or "UNKNOWN"
        if string.len(target_name) > 18 then
            target_name = string.sub(target_name, 1, 18) .. "..."
        end

        -- Get K/D/A using entity index (player resource uses per-slot arrays)
        local pr = entity.get_player_resource()
        local target_idx = entity.get_entindex and entity.get_entindex(target) or target
        local kills   = (pr and entity.get_prop(pr, "m_iKills",   target_idx)) or 0
        local assists = (pr and entity.get_prop(pr, "m_iAssists", target_idx)) or 0
        local deaths  = (pr and entity.get_prop(pr, "m_iDeaths",  target_idx)) or 0
        local kd = deaths > 0 and (kills / deaths) or kills
        local stats_str = string.format("K %d   A %d   D %d   KD %.2f", kills, assists, deaths, kd)

        -- Build list of other spectators watching same target
        local other_specs = {}
        local all_players = entity.get_players(true) -- include dead/bots
        if all_players then
            for _, pid in ipairs(all_players) do
                if pid ~= me and not entity.is_alive(pid) then
                    local obs_t = entity.get_prop(pid, "m_hObserverTarget")
                    if obs_t == target then
                        local pname = entity.get_player_name(pid) or "?"
                        if string.len(pname) > 12 then pname = string.sub(pname, 1, 12) .. "." end
                        table.insert(other_specs, pname)
                    end
                end
            end
        end

        local spec_w = 360
        local spec_h = 62
        local extra_h = #other_specs > 0 and (14 + #other_specs * 13) or 0
        local spec_x = math.floor((sx / 2) - (spec_w / 2)) + ui.get(menu.hud.customHud.specX)
        local spec_y = sy - 120 + ui.get(menu.hud.customHud.specY)

        -- Background
        solus_ui.container_glow(spec_x, spec_y, spec_w, spec_h + extra_h, acc_r, acc_g, acc_b, bg_a, 1, acc_r, acc_g, acc_b)
        surface.draw_filled_rect(spec_x, spec_y + spec_h - 3, spec_w, 3, acc_r, acc_g, acc_b, acc_a)

        -- Observer mode badge (top-right)
        local badge_w, _ = surface.get_text_size(font_small, obs_label)
        surface.draw_text(spec_x + spec_w - badge_w - 12, spec_y + 10, acc_r, acc_g, acc_b, 200, font_small, obs_label)

        -- Target name
        surface.draw_text(spec_x + 20, spec_y + 10, 255, 255, 255, 255, font_big, target_name)

        -- Stats row
        surface.draw_text(spec_x + 20, spec_y + 36, 180, 180, 180, 255, font_small, stats_str)

        -- Other spectators section
        if #other_specs > 0 then
            surface.draw_text(spec_x + 20, spec_y + spec_h + 4, 120, 120, 120, 255, font_small, "ALSO WATCHING:")
            for j, sname in ipairs(other_specs) do
                surface.draw_text(spec_x + 20, spec_y + spec_h + 4 + j * 13, 180, 180, 180, 255, font_small, sname)
            end
        end
    end

    -- --- Crosshair ---
    if has_option("Crosshair") and target == me then
        local is_scoped = entity.get_prop(target, "m_bIsScoped") == 1
        if not is_scoped then
            local cx = math.floor(sx / 2)
            local cy = math.floor(sy / 2)
            
            -- Outline
            surface.draw_filled_rect(cx - 1, cy - 1, 3, 3, 0, 0, 0, 200)
            -- Inner dot
            surface.draw_filled_rect(cx, cy, 1, 1, acc_r, acc_g, acc_b, 255)
            
            -- Lines
            -- Left
            surface.draw_filled_rect(cx - 6, cy - 1, 4, 3, 0, 0, 0, 200)
            surface.draw_filled_rect(cx - 5, cy, 2, 1, 255, 255, 255, 255)
            -- Right
            surface.draw_filled_rect(cx + 3, cy - 1, 4, 3, 0, 0, 0, 200)
            surface.draw_filled_rect(cx + 4, cy, 2, 1, 255, 255, 255, 255)
            -- Top
            surface.draw_filled_rect(cx - 1, cy - 6, 3, 4, 0, 0, 0, 200)
            surface.draw_filled_rect(cx, cy - 5, 1, 2, 255, 255, 255, 255)
            -- Bottom
            surface.draw_filled_rect(cx - 1, cy + 3, 3, 4, 0, 0, 0, 200)
            surface.draw_filled_rect(cx, cy + 4, 1, 2, 255, 255, 255, 255)
        end
    end

    -- Custom Killfeed is handled in killfeed.lua
end

function hud.OnShutdown()
    if hud_state.panorama_hidden then
        panorama.loadstring([[
            var hud = $.GetContextPanel();
            if (hud) {
                var ids = [
                    "HudTeamCounter", "HudHealthArmor", "HudWeaponSelection", "HudAmmo", "SFHudAmmo",
                    "WinPanel", "WinPanelMatch", "WinPanelBasic", "EndMatch",
                    "WinPanelRoot", "HudWinPanel", "SFWinPanel", "CSGOHudWinPanel", "RoundEnd"
                ];
                for (var i = 0; i < ids.length; i++) {
                    var p = hud.FindChildTraverse(ids[i]);
                    if (p) {
                        p.style.opacity = "1.0";
                        p.style.visibility = "visible";
                    }
                }
            }
        ]], "CSGOHud")()
        hud_state.panorama_hidden = false
    end

    -- Always restore spectator panels on shutdown regardless of spec_hidden flag,
    -- in case the state got desynced (e.g. script reload while dead)
    panorama.loadstring([[
        var hud = $.GetContextPanel();
        if (hud) {
            var ids = [
                "HudSpectatorDeathNotice",
                "HudObserverElements",
                "SFHudSpectator",
                "HudSpectatorPanel",
                "HudSpectator",
                "ObserverPanel"
            ];
            for (var i = 0; i < ids.length; i++) {
                var p = hud.FindChildTraverse(ids[i]);
                if (p) {
                    p.style.visibility = "";
                }
            }
        }
    ]], "CSGOHud")()
    hud_state.spec_hidden = false
    
    local me = entity.get_local_player()
    local target = entity.is_alive(me) and me or (entity.get_prop(me, "m_hObserverTarget") or me)
    if target and target ~= 0 then
        entity.set_prop(target, "m_iHideHUD", 0)
    end
    cvar.cl_draw_only_deathnotices:set_raw_int(0)
    cvar.cl_drawhud_force_radar:set_raw_int(-1)
end

return hud
