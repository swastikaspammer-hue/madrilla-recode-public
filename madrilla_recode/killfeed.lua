local menu = require("madrilla_recode/menu")
local surface = require("gamesense/surface") or surface
local client = client
local ui = ui
local cvar = cvar

local killfeed = {}
local killfeed_entries = {}
local cached_size = 0
local fonts = {}
local images = require("gamesense/images")
local solus_ui = require("madrilla_recode/solus_ui")



local headshot_svg = [[<?xml version="1.0" ?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="#ffffff" d="M256 0C114.6 0 0 100.3 0 224c0 70.1 36.9 132.6 94.5 173.7 9.6 6.9 15.2 18.1 13.5 29.9l-9.4 66.2c-1.4 9.6 6 18.2 15.7 18.2H192v-56c0-4.4 3.6-8 8-8h16c4.4 0 8 3.6 8 8v56h64v-56c0-4.4 3.6-8 8-8h16c4.4 0 8 3.6 8 8v56h77.7c9.7 0 17.1-8.6 15.7-18.2l-9.4-66.2c-1.7-11.7 3.8-23 13.5-29.9C475.1 356.6 512 294.1 512 224 512 100.3 397.4 0 256 0zm-96 320c-35.3 0-64-28.7-64-64s28.7-64 64-64 64 28.7 64 64-28.7 64-64 64zm192 0c-35.3 0-64-28.7-64-64s28.7-64 64-64 64 28.7 64 64-28.7 64-64 64z"/></svg>]]
local headshot_texture = images.get_panorama_image("icons/equipment/headshot.svg") or images.load(headshot_svg)

local function get_weapon_icon(weapon_name)
    return images.get_weapon_icon(weapon_name)
end

local function rebuild_fonts(size)
    if size == cached_size then
        return
    end

    cached_size = size
    fonts.text = surface.create_font('Verdana', size, 700, 0x010 + 0x080)
end

local function measure_name(text)
    local w, h = surface.get_text_size(fonts.text, text)
    return w, h
end

local function draw_name(x, y, r, g, b, a, text)
    surface.draw_text(x, y, r, g, b, a, fonts.text, text)
end

-- Strip Valve color escape codes (0x01-0x08) embedded in CS:GO names
local function strip_color_codes(str)
    if not str then return "" end
    return (str:gsub("[\x01-\x08]", ""))
end

-- Strip clan tag prefix: "[TAG] Name" -> "Name", also handles "(TAG) " and "TAG | "
local function strip_clan_tag(str)
    if not str then return "?" end
    -- Match [TAG], (TAG), or "word | " prefixes
    local stripped = str:match("^%[.-%]%s*(.+)$")
                  or str:match("^%(.-%%)%s*(.+)$")
                  or str:match("^.-%s*|%s*(.+)$")
    return stripped or str
end

local function clean_name(str)
    if not str then return "?" end
    local s = strip_color_codes(str)
    s = strip_clan_tag(s)
    -- Final safety: remove any remaining non-printable ASCII
    s = s:gsub("[%c]", "")
    if s == "" then return "?" end
    return s
end

local function truncate_name(str, max_len)
    if not str then return "?" end
    local len = 0
    local i = 1
    local byte_len = #str
    while i <= byte_len do
        local b = str:byte(i)
        if b < 0x80 then i = i + 1
        elseif b < 0xE0 then i = i + 2
        elseif b < 0xF0 then i = i + 3
        else i = i + 4 end
        len = len + 1
        if len == max_len and i <= byte_len then
            return str:sub(1, i - 1) .. "..."
        end
    end
    return str
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function killfeed.OnPlayerDeath(e)
    if not ui.get(menu.hud.customKillfeed.enable) then return end

    local attacker = client.userid_to_entindex(e.attacker)
    local attacked = client.userid_to_entindex(e.userid)
    local assister = (e.assister and e.assister > 0) and client.userid_to_entindex(e.assister) or 0

    if attacker == nil or attacked == nil then
        return
    end

    if attacker == 0 and attacked == 0 then
        return
    end

    local attacker_name = attacker == 0 and "World" or clean_name(entity.get_player_name(attacker) or '?')
    local attacked_name = attacked == 0 and "World" or clean_name(entity.get_player_name(attacked) or '?')
    local assister_name = (assister ~= 0) and clean_name(entity.get_player_name(assister) or '?') or nil
    
    attacker_name = truncate_name(attacker_name, 18)
    attacked_name = truncate_name(attacked_name, 18)
    if assister_name then
        assister_name = truncate_name(assister_name, 12)
    end

    table.insert(killfeed_entries, 1, {
        attacker = attacker,
        attacked = attacked,
        assister = assister,
        attacker_name = attacker_name,
        attacked_name = attacked_name,
        assister_name = assister_name,
        headshot = e.headshot,
        weapon = e.weapon,
        time = 6,
        alpha = 0,
    })
end

function killfeed.OnPaintUI()
    if not ui.get(menu.hud.customKillfeed.enable) then 
        cvar.cl_drawhud_force_deathnotices:set_raw_int(0)
        return 
    end

    cvar.cl_drawhud_force_deathnotices:set_raw_int(-1)

    local me = entity.get_local_player()

    if me == nil then
        return
    end

    local font_size = ui.get(menu.hud.customKillfeed.size)
    rebuild_fonts(font_size)

    local sx, sy = client.screen_size()
    local dt = globals.frametime()
    local row_height = font_size + 8
    local padding = math.floor(font_size * 0.7)
    local spacing = math.floor(font_size * 0.35)
    local height = 120

    for i = #killfeed_entries, 1, -1 do
        local entry = killfeed_entries[i]

        if entry.attacker ~= me then
            entry.time = entry.time - dt
        end

        local target_alpha = entry.time <= 0 and 0 or 1
        entry.alpha = lerp(entry.alpha, target_alpha, 0.08)

        if entry.alpha < 0.01 then
            table.remove(killfeed_entries, i)
        end
    end

    for _, entry in ipairs(killfeed_entries) do
        if entry.alpha < 0.01 then
            goto continue
        end

        local a = entry.alpha
        local weapon_img = get_weapon_icon(entry.weapon)
        local weapon_w, icon_h = 0, 0

        if weapon_img then
            local orig_w, orig_h = weapon_img:measure()
            if orig_h > 0 then
                icon_h = math.floor(font_size * 0.7)
                weapon_w = math.floor(orig_w * (icon_h / orig_h))
            end
        else
            weapon_w, icon_h = measure_name(entry.weapon)
        end

        local attacked_w = measure_name(entry.attacked_name)
        local attacker_w = measure_name(entry.attacker_name)

        local headshot_w = 0
        local hs_w, hs_h = 0, 0
        if entry.headshot then
            if headshot_texture then
                hs_h = math.floor(font_size * 0.7)
                hs_w = hs_h -- The skull SVG is square
                headshot_w = hs_w
            else
                hs_w, hs_h = measure_name("[HS]")
                headshot_w = hs_w
            end
        end

        local assister_w = 0
        if entry.assister_name then
            assister_w = measure_name("+" .. entry.assister_name) + spacing
        end
        local total_w = padding * 2 + attacked_w + headshot_w + weapon_w + attacker_w + assister_w + spacing * 4
        
        local x_slide = math.floor((1 - a) * 80)
        local container_x = sx - total_w - 15 + x_slide
        local container_y = 20 + height

        local is_local = (entry.attacker == me or entry.attacked == me or entry.assister == me)

        local bg_r, bg_g, bg_b, bg_a
        if is_local then
            bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customKillfeed.bg_active)
        else
            bg_r, bg_g, bg_b, bg_a = ui.get(menu.hud.customKillfeed.bg_inactive)
        end

        local acc_r, acc_g, acc_b, acc_a = ui.get(menu.config.accent)

        if is_local then
            -- The beautiful solus_ui outer glow 
            solus_ui.container_glow(container_x, container_y, total_w, row_height, acc_r, acc_g, acc_b, math.min(255, math.floor(140 * a)), a, acc_r, acc_g, acc_b)
        end

        -- Sleek translucent inner base (respects user background config)
        surface.draw_filled_rect(container_x, container_y, total_w, row_height, bg_r, bg_g, bg_b, math.floor(bg_a * a))
            
        -- Top highlight rim-light for glass depth effect
        if is_local then
            surface.draw_filled_rect(container_x, container_y, total_w, 1, 
                math.floor(acc_r * 0.4), math.floor(acc_g * 0.4), math.floor(acc_b * 0.4), math.floor(100 * a))
        else
            surface.draw_filled_rect(container_x, container_y, total_w, 1, 
                math.floor(bg_r * 0.4), math.floor(bg_g * 0.4), math.floor(bg_b * 0.4), math.floor(100 * a))
        end
        
        -- Left Accent Line & Progress Bar
        local bar_r, bar_g, bar_b, bar_a = bg_r, bg_g, bg_b, bg_a
        if is_local then
            bar_r, bar_g, bar_b, bar_a = acc_r, acc_g, acc_b, acc_a
        end

        surface.draw_filled_rect(container_x, container_y, 3, row_height, bar_r, bar_g, bar_b, math.floor(bar_a * a))
        local progress_w = math.floor(total_w * math.max(0, entry.time / 6.0))
        surface.draw_filled_rect(container_x, container_y + row_height - 2, progress_w, 2, bar_r, bar_g, bar_b, math.floor(bar_a * a))

        local ar, ag, ab, aa = ui.get(menu.hud.customKillfeed.attacker_color)
        local dr, dg, db, da = ui.get(menu.hud.customKillfeed.attacked_color)
        local wr, wg, wb, wa = ui.get(menu.hud.customKillfeed.weapon_color)

        local text_y = container_y + math.floor((row_height - font_size) / 2)
        local icon_y = text_y + math.floor((font_size - icon_h) / 2) + 1
        local cx = container_x + padding

        draw_name(cx, text_y, ar, ag, ab, math.floor(aa * a), entry.attacker_name)
        cx = cx + attacker_w + spacing

        -- Assister (shown as "+name" between attacker and weapon)
        if entry.assister_name then
            draw_name(cx, text_y, 180, 180, 180, math.floor(aa * a * 0.8), "+" .. entry.assister_name)
            cx = cx + assister_w
        end

        if weapon_img then
            weapon_img:draw(cx + 1, icon_y + 1, weapon_w, icon_h, 0, 0, 0, math.floor(180 * a))
            weapon_img:draw(cx, icon_y, weapon_w, icon_h, wr, wg, wb, math.floor(wa * a))
        else
            draw_name(cx, text_y, wr, wg, wb, math.floor(wa * a), entry.weapon)
        end
        cx = cx + weapon_w + spacing

        if entry.headshot then
            local hr, hg, hb, ha = ui.get(menu.hud.customKillfeed.headshot_color)
            if headshot_texture then
                local sy = icon_y - math.floor((hs_h - icon_h)/2)
                headshot_texture:draw(cx + 1, sy + 1, hs_w, hs_h, 0, 0, 0, math.floor(180 * a))
                headshot_texture:draw(cx, sy, hs_w, hs_h, hr, hg, hb, math.floor(ha * a))
            else
                draw_name(cx + 1, text_y + 1, 0, 0, 0, math.floor(180 * a), "[HS]")
                draw_name(cx, text_y, hr, hg, hb, math.floor(ha * a), "[HS]")
            end
            cx = cx + headshot_w + spacing
        end

        draw_name(cx, text_y, dr, dg, db, math.floor(da * a), entry.attacked_name)

        height = height + (row_height + 2) * a

        ::continue::
    end
end

function killfeed.OnRoundStart()
    killfeed_entries = {}
end

function killfeed.OnShutdown()
    cvar.cl_drawhud_force_deathnotices:set_raw_int(0)
end

return killfeed
