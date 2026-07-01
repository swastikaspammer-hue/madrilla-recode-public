local menu = require("madrilla_recode/menu")
local fnt_killfeed = render.load_font("Verdana", 16, "ab")

local FEED_MAX      = 10
local FADE_TIME     = 5.0
local SLIDE_TIME    = 0.3
local ENTRY_HEIGHT  = 22
local ENTRY_PAD     = 4
local BOX_W         = 310
local MARGIN_X      = 14
local MARGIN_Y      = 14

local feed = {}

local function add_entry(attacker_name, attacked_name, weapon_name, is_headshot, is_me_attacker, is_me_victim)
    local entry = {
        attacker    = attacker_name,
        attacked    = attacked_name,
        weapon      = weapon_name,
        headshot    = is_headshot,
        time        = globals.realtime,
        me_attack   = is_me_attacker,
        me_victim   = is_me_victim,
    }
    table.insert(feed, 1, entry)
    while #feed > FEED_MAX do table.remove(feed) end
end

local floating_damages = {}

local function add_floating_damage(damage, victim_entity)
    if not victim_entity then return end
    local pos = victim_entity:get_hitbox_position(0)
    if not pos then return end
    table.insert(floating_damages, {
        damage   = damage,
        pos      = pos,
        born     = globals.realtime,
        duration = menu.hud.floatingDamage.duration:get(),
    })
end

events.player_death:set(function(e)
    if not menu.hud.customKillfeed.enable:get() then return end

    local lp = entity.get_local_player()
    local attacker_ent = entity.get(e.attacker, true)
    local victim_ent   = entity.get(e.userid, true)

    local attacker_name = attacker_ent and attacker_ent:get_name() or "?"
    local victim_name   = victim_ent and victim_ent:get_name() or "?"

    local is_headshot  = e.headshot == 1
    local weapon_name  = e.weapon or "?"
    local is_me_attack = (attacker_ent == lp)
    local is_me_victim = (victim_ent == lp)

    add_entry(attacker_name, victim_name, weapon_name, is_headshot, is_me_attack, is_me_victim)
end)

events.player_hurt:set(function(e)
    if not menu.hud.floatingDamage.enable:get() then return end
    local lp = entity.get_local_player()
    local attacker_ent = entity.get(e.attacker, true)
    if attacker_ent ~= lp then return end
    local victim_ent = entity.get(e.userid, true)
    if not victim_ent then return end
    add_floating_damage(e.dmg_health or 0, victim_ent)
end)

local function lerp_color(ca, cb, t)
    local function ci(a, b, tt) return math.floor(a + (b - a) * tt) end
    return color(ci(ca.r, cb.r, t), ci(ca.g, cb.g, t), ci(ca.b, cb.b, t), ci(ca.a, cb.a, t))
end

local kf_cached_font_size = 0
local kf_cached_font = nil

events.render:set(function()
    if not globals.is_in_game then return end

    local screen_w, screen_h = render.screen_size()
    local size    = menu.hud.customKillfeed.size:get()
    local now     = globals.realtime
    
    if size ~= kf_cached_font_size or not kf_cached_font then
        kf_cached_font = render.load_font("Verdana", size, "ab")
        kf_cached_font_size = size
    end
    local font = kf_cached_font


    if menu.hud.customKillfeed.enable:get() then
        local adv         = menu.hud.customKillfeed.advanced:get()
        local c_attacker  = adv and menu.hud.customKillfeed.attacker_color:get() or color(255, 255, 255, 255)
        local c_attacked  = adv and menu.hud.customKillfeed.attacked_color:get()  or color(255, 50, 50, 255)
        local c_weapon    = adv and menu.hud.customKillfeed.weapon_color:get()    or color(255, 255, 255, 255)
        local c_hs        = adv and menu.hud.customKillfeed.headshot_color:get()  or color(255, 210, 50, 255)
        local c_bg_active   = adv and menu.hud.customKillfeed.bg_active:get()    or color(30, 30, 30, 200)
        local c_bg_inactive = adv and menu.hud.customKillfeed.bg_inactive:get()  or color(15, 15, 15, 200)

        local base_x = screen_w - BOX_W - MARGIN_X
        local base_y = MARGIN_Y

        for i, entry in ipairs(feed) do
            local age   = now - entry.time
            if age > FADE_TIME then break end

            local alpha = 1.0
            if age > FADE_TIME - 1.0 then
                alpha = (FADE_TIME - age)
            elseif age < SLIDE_TIME then
                alpha = age / SLIDE_TIME
            end

            local entry_y = base_y + (i - 1) * (ENTRY_HEIGHT + ENTRY_PAD)
            local is_active = age < 3.0
            local bg_base = is_active and c_bg_active or c_bg_inactive
            local bg = color(bg_base.r, bg_base.g, bg_base.b, math.floor(bg_base.a * alpha))

            render.filled_rect(vector(base_x, entry_y), vector(BOX_W, ENTRY_HEIGHT), bg)
            render.rect(vector(base_x, entry_y), vector(BOX_W, ENTRY_HEIGHT), color(50, 50, 50, math.floor(100 * alpha)))

            local accent = is_active and color(255, 96, 71, math.floor(230 * alpha)) or color(100, 100, 100, math.floor(200 * alpha))
            render.filled_rect(vector(base_x, entry_y), vector(3, ENTRY_HEIGHT), accent)

            local text_y = entry_y + (ENTRY_HEIGHT - size) / 2
            local px = base_x + 8

            local a_col   = color(c_attacker.r, c_attacker.g, c_attacker.b, math.floor(255 * alpha))
            local vic_col = color(c_attacked.r, c_attacked.g, c_attacked.b, math.floor(255 * alpha))
            local wp_col  = color(c_weapon.r, c_weapon.g, c_weapon.b, math.floor(180 * alpha))
            local hs_col  = color(c_hs.r, c_hs.g, c_hs.b, math.floor(255 * alpha))

            render.text(font, vector(px, text_y), a_col, entry.attacker)
            px = px + render.text_size(font, entry.attacker) + 5
            render.text(font, vector(px, text_y), wp_col, "[" .. entry.weapon .. "]")
            px = px + render.text_size(font, "[" .. entry.weapon .. "]") + 5
            if entry.headshot then
                render.text(font, vector(px, text_y), hs_col, "[hs]")
                px = px + render.text_size(font, "[hs]") + 5
            end
            render.text(font, vector(px, text_y), vic_col, entry.attacked)
        end
    end

    if menu.hud.floatingDamage.enable:get() then
        local lp = entity.get_local_player()
        local dmg_color = menu.hud.floatingDamage.color:get()

        local i = 1
        while i <= #floating_damages do
            local fd  = floating_damages[i]
            local age = now - fd.born
            if age >= fd.duration then
                table.remove(floating_damages, i)
            else
                local progress = age / fd.duration
                local alpha    = math.floor(255 * (1 - progress))
                local c        = color(dmg_color.r, dmg_color.g, dmg_color.b, alpha)

                local float_pos = vector(fd.pos.x, fd.pos.y, fd.pos.z + 10 + progress * 30)
                local sx, sy = render.world_to_screen(float_pos)
                if sx and sy then
                    local label = "-" .. tostring(fd.damage)
                    local tw = render.text_size(font, label)
                    render.text(font, vector(sx - tw / 2, sy), c, label)
                end
                i = i + 1
            end
        end
    end
end)

return {
    add_entry          = add_entry,
    add_floating_damage = add_floating_damage,
}
