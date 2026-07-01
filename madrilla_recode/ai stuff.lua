local ui_get = ui.get
local ui_set = ui.set
local ui_new_checkbox = ui.new_checkbox
local ui_new_color_picker = ui.new_color_picker
local ui_reference = ui.reference

local entity_get_local_player = entity.get_local_player
local entity_get_prop = entity.get_prop
local entity_get_player_weapon = entity.get_player_weapon
local entity_is_alive = entity.is_alive
local client_screen_size = client.screen_size
local renderer_rectangle = renderer.rectangle
local renderer_text = renderer.text
local renderer_gradient = renderer.gradient
local globals_curtime = globals.curtime

-- UI Elements for the new AI features
local master_switch = ui.new_checkbox("VISUALS", "Other ESP", "Enable AI Custom HUD")
local color_health = ui.new_color_picker("VISUALS", "Other ESP", "Health Bar Color", 130, 255, 130, 255)
local color_armor = ui.new_color_picker("VISUALS", "Other ESP", "Armor Bar Color", 100, 150, 255, 255)
local color_ammo = ui.new_color_picker("VISUALS", "Other ESP", "Ammo Bar Color", 255, 255, 100, 255)
local color_exploit = ui.new_color_picker("VISUALS", "Other ESP", "Exploit Bar Color", 255, 100, 255, 255)

-- References to GameSense native features
local ref_dt, ref_dt_key = ui.reference("RAGE", "Other", "Double tap")
local ref_hs, ref_hs_key = ui.reference("AA", "Other", "On shot anti-aim")

-- Variables for smooth animations
local health_anim = 100
local armor_anim = 100
local ammo_anim = 30
local exploit_anim = 1

local function lerp(a, b, t)
    return a + (b - a) * t
end

client.set_event_callback("paint", function()
    if not ui_get(master_switch) then return end

    local me = entity_get_local_player()
    if not me or not entity_is_alive(me) then return end

    local screen_w, screen_h = client_screen_size()
    local center_x, center_y = screen_w / 2, screen_h / 2
    
    -- Position slightly below the crosshair
    local y_offset = center_y + 45

    -- Fetch current player stats
    local health = entity_get_prop(me, "m_iHealth") or 0
    local armor = entity_get_prop(me, "m_ArmorValue") or 0
    
    local weapon = entity_get_player_weapon(me)
    local ammo = 0
    local max_ammo = 30
    local is_charged = false

    if weapon then
        ammo = entity_get_prop(weapon, "m_iClip1") or 0
        if ammo > 30 then max_ammo = ammo end
        if ammo < 0 then ammo = 0 end -- handles knives and grenades

        -- Exploit charge detection (simplified logic based on attack times)
        local next_attack = entity_get_prop(me, "m_flNextAttack") or 0
        local next_primary_attack = entity_get_prop(weapon, "m_flNextPrimaryAttack") or 0
        local max_time = math.max(next_attack, next_primary_attack)
        
        is_charged = max_time <= globals_curtime()
    end

    -- Update animations
    health_anim = lerp(health_anim, health, 0.1)
    armor_anim = lerp(armor_anim, armor, 0.1)
    ammo_anim = lerp(ammo_anim, ammo, 0.1)

    if is_charged then
        exploit_anim = lerp(exploit_anim, 1, 0.05) -- slowly fill up when charged
    else
        exploit_anim = lerp(exploit_anim, 0, 0.2) -- rapidly empty when fired
    end

    -- Bar Dimensions
    local bar_width = 120
    local bar_height = 4
    local spacing = 8

    local x = center_x - (bar_width / 2)

    -- Backgrounds
    renderer_rectangle(x, y_offset, bar_width, bar_height, 20, 20, 20, 180)
    renderer_rectangle(x, y_offset + spacing, bar_width, bar_height, 20, 20, 20, 180)
    
    if ammo > 0 then
        renderer_rectangle(x, y_offset + spacing * 2, bar_width, bar_height, 20, 20, 20, 180)
    end

    -- Health Bar (Glowing effect using gradients)
    local hr, hg, hb, ha = ui_get(color_health)
    local hp_width = math.max(0, math.min(bar_width, (health_anim / 100) * bar_width))
    renderer_gradient(x, y_offset, hp_width, bar_height, hr, hg, hb, ha, hr, hg, hb, 0, true)
    renderer_text(x - 15, y_offset - 2, 255, 255, 255, 255, "c-", 0, "HP")

    -- Armor Bar
    local ar, ag, ab, aa = ui_get(color_armor)
    local arm_width = math.max(0, math.min(bar_width, (armor_anim / 100) * bar_width))
    renderer_gradient(x, y_offset + spacing, arm_width, bar_height, ar, ag, ab, aa, ar, ag, ab, 0, true)
    renderer_text(x - 15, y_offset + spacing - 2, 255, 255, 255, 255, "c-", 0, "AR")

    -- Ammo Bar
    local current_spacing = spacing * 2
    if ammo > 0 then
        local amr, amg, amb, ama = ui_get(color_ammo)
        local am_width = math.max(0, math.min(bar_width, (ammo_anim / max_ammo) * bar_width))
        renderer_gradient(x, y_offset + current_spacing, am_width, bar_height, amr, amg, amb, ama, amr, amg, amb, 0, true)
        renderer_text(x - 15, y_offset + current_spacing - 2, 255, 255, 255, 255, "c-", 0, "AM")
        current_spacing = current_spacing + spacing
    end

    -- Exploit (DT / HS) Bar
    local dt_enabled = ui_get(ref_dt) and ui_get(ref_dt_key)
    local hs_enabled = ui_get(ref_hs) and ui_get(ref_hs_key)
    
    local exploit_active = dt_enabled or hs_enabled
    local exploit_text = ""
    if dt_enabled then 
        exploit_text = "DT"
    elseif hs_enabled then 
        exploit_text = "HS" 
    end

    if exploit_active then
        local exr, exg, exb, exa = ui_get(color_exploit)
        
        -- Background
        renderer_rectangle(x, y_offset + current_spacing, bar_width, bar_height, 20, 20, 20, 180)
        
        -- Animated Charge Bar
        local exp_width = math.max(0, math.min(bar_width, exploit_anim * bar_width))
        renderer_gradient(x, y_offset + current_spacing, exp_width, bar_height, exr, exg, exb, exa, exr, exg, exb, 0, true)
        renderer_text(x - 15, y_offset + current_spacing - 2, 255, 255, 255, 255, "c-", 0, exploit_text)
    end
end)
