local menu = require("madrilla_recode/menu")
local vector = require("vector")
local images = require("gamesense/images")
local pui = require("gamesense/pui")

local bullet_icon = images.get_panorama_image("icons/ui/bullet.svg")

local min_dmg = pui.reference("Rage", "Aimbot", "Minimum damage")
local min_dmg_ovr = { pui.reference("Rage", "Aimbot", "Minimum damage override") }
local dpi_scale = pui.reference("Misc", "Settings", "DPI scale")

local name_esp = { pui.reference("Visuals", "Player ESP", "Name") }
local weapon_text_esp = { pui.reference("Visuals", "Player ESP", "Weapon text") }
local weapon_icon_esp = { pui.reference("Visuals", "Player ESP", "Weapon icon") }

local show_nades_esp
if pcall(function() ui.reference("Visuals", "Player ESP", "Show nades") end) then
    show_nades_esp = ui.reference("Visuals", "Player ESP", "Show nades")
end

local targets = {}
local dpi = 1

local function containsOption(opt)
    local opts = ui.get(menu.visuals.lethalityIndicator.options)
    for _, v in pairs(opts) do
        if v == opt then return true end
    end
    return false
end

local function vector_normalize(v)
	local len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
	if len == 0 then return vector(0, 0, 0) end
	local inv = 1 / len
	return vector(v.x * inv, v.y * inv, v.z * inv)
end

local function calculate_fov(origin, dest, fwd)
	local dir = vector_normalize(vector(origin.x - dest.x, origin.y - dest.y, 0))
	local dot = dir:dot(fwd)
	local fov = math.acos(dot)
	return 180 / math.pi * fov
end

local function for_each_player(flags, callback, fallback)
	for i = 1, globals.maxplayers() do
        local ent = entity.get_prop(entity.get_player_resource(), "m_bConnected", i) and i or nil
		if ent then
			if (not flags:find("A") or entity.is_alive(ent)) and 
               (not flags:find("D") or not entity.is_dormant(ent)) and 
               (not flags:find("E") or entity.is_enemy(ent)) then
				callback(ent)
			end
		elseif fallback then
			fallback(i)
		end
	end
end

local function get_points_in_radius(origin, radius)
	local pts = {}
	for deg = 0, 360, 40 do
		local rad = math.rad(deg)
		pts[#pts + 1] = vector(radius * math.cos(rad) + origin.x, radius * math.sin(rad) + origin.y, origin.z)
	end
	return pts
end

local function has_short_range_weapon(player)
	if player == nil then return false end
	local wep = entity.get_player_weapon(player)
	if wep == nil then return false end
	local class = entity.get_classname(wep)
	if class == "CKnife" or class == "CWeaponTaser" or class == "CSmokeGrenade" or class == "CHEGrenade" or class == "CMolotovGrenade" or class == "CFlashGrenade" or class == "CDecoyGrenade" or class == "CIncendiaryGrenade" then
		return true
	end
	return false
end

client.register_esp_flag("-", 255, 0, 0, function(ent)
	if not ui.get(menu.visuals.lethalityIndicator.enable) or not containsOption("Lethal flag") then return false end
	if targets == nil or targets[ent] == nil then return false end
	
    local t = targets[ent]
	return tostring(t.bullets) ~= "inf", t.bullets <= 1 and "L" or "x" .. t.bullets
end)

client.register_esp_flag("B", 255, 255, 255, function(ent)
	if not ui.get(menu.visuals.lethalityIndicator.enable) or not containsOption("Force flag") then return false end
	return plist.get(ent, "Override prefer body aim") == "Force"
end)

local lethality = {
    OnSetupCommand = function(cmd)
        if not ui.get(menu.visuals.lethalityIndicator.enable) then return end
        local lp = entity.get_local_player()
        if lp == nil or has_short_range_weapon(lp) or not entity.is_alive(lp) then
            targets = {}
            return
        end

        if cmd.chokedcommands > 0 then return end
        targets = {}

        local dmg_setting = min_dmg:get()
        if min_dmg_ovr[1]:get() and min_dmg_ovr[2]:get() then
            dmg_setting = min_dmg_ovr[3]:get()
        end

        local angles = {client.camera_angles()}
        local origin = vector(entity.get_origin(lp))
        local closest = {entity = nil, fov = math.huge}
        local fwd = vector():init_from_angles(unpack(angles))
        local test_points = get_points_in_radius(origin + vector(0, 0, 56), 180, 40)

        if ui.get(menu.visuals.lethalityIndicator.onlyClosest) then
            for_each_player("ADE", function(ent)
                local fov = calculate_fov(vector(entity.get_origin(ent)), origin, fwd)
                if fov < closest.fov then
                    closest = {entity = ent, fov = fov}
                end
            end)
        end

        for_each_player("ADE", function(ent)
            if closest.entity ~= nil and closest.entity ~= ent then return end
            
            if not targets[ent] then
                targets[ent] = {dmg = 0, is_lethal = false, bullets = 0, entity = ent}
            end

            local center = vector(entity.hitbox_position(ent, 5)) -- chest
            local hp = entity.get_prop(ent, "m_iHealth")

            for i = 1, #test_points do
                local pt = test_points[i]
                local _, damage = client.trace_bullet(lp, pt.x, pt.y, pt.z, center.x, center.y, center.z)
                if damage ~= nil and (damage > dmg_setting or hp < damage) then
                    targets[ent].dmg = damage
                end
            end

            targets[ent].is_lethal = hp < targets[ent].dmg
            targets[ent].bullets = math.max(1, math.ceil(hp / targets[ent].dmg))

            if containsOption("Force body aim") then
                local baim_val = targets[ent].bullets <= ui.get(menu.visuals.lethalityIndicator.forceBodyAimShots) and "Force" or "-"
                plist.set(ent, "Override prefer body aim", baim_val)
            end
        end)
    end,

    OnPaint = function()
        if not ui.get(menu.visuals.lethalityIndicator.enable) or not containsOption("Bullet icon") then return end
        
        local lp = entity.get_local_player()
        if not lp or not entity.is_alive(lp) or targets == nil then return end

        local icon_pos = ui.get(menu.visuals.lethalityIndicator.iconPosition)
        dpi = tonumber(dpi_scale:get():sub(1, 3)) * 0.01

        for ent, target in pairs(targets) do
            if target.entity ~= nil and entity.is_alive(target.entity) and target.dmg > 0 then
                local bbox = {entity.get_bounding_box(target.entity)}
                if bbox[1] ~= nil and bbox[5] > 0 then
                    local draw_pos = vector(0, 0)

                    if icon_pos == "Default" then
                        -- Calculate default position based on esp flags (rudimentary implementation)
                        draw_pos = vector(bbox[3], bbox[2]) + vector(2, 0)
                    else
                        local offset = 16
                        if icon_pos == "Above name" then
                            if show_nades_esp and show_nades_esp:get() then offset = offset + 10 end
                            if name_esp[1]:get() then offset = offset + 10 end
                        elseif icon_pos == "Below weapons" then
                            offset = 8
                            if weapon_icon_esp[1]:get() then offset = offset + 15 end
                            if weapon_text_esp[1]:get() then offset = offset + 8 end
                        end

                        local pos_map = {
                            ["Above name"] = {(bbox[1] + bbox[3]) * 0.5 - 8 * dpi, bbox[2] - offset * dpi},
                            ["Below weapons"] = {(bbox[1] + bbox[3]) * 0.5 - 8 * dpi, bbox[4] + offset * dpi},
                            ["Next to health"] = {bbox[1] - 24, (bbox[2] + bbox[4]) * 0.5 - 8 * dpi},
                            ["Top left"] = {bbox[1] - 24 * dpi, bbox[2] - 14 * dpi},
                            ["Top right"] = {bbox[3] + 6 * dpi, bbox[2] - 14 * dpi},
                            ["Bottom left"] = {bbox[1] - 16 * dpi, bbox[4]},
                            ["Bottom right"] = {bbox[3], bbox[4]}
                        }
                        draw_pos.x, draw_pos.y = unpack(pos_map[icon_pos])
                    end

                    renderer.text(draw_pos.x + 6 * dpi, draw_pos.y + 5 * dpi, 220, 220, 220, 255 * bbox[5], "d-", 0, "x" .. target.bullets)
                    bullet_icon:draw(draw_pos.x + 1, draw_pos.y + 4, 12 * dpi, 10 * dpi, 0, 0, 0, 255 * bbox[5])
                    bullet_icon:draw(draw_pos.x, draw_pos.y + 3, 12 * dpi, 10 * dpi, 220, 220, 220, 255 * bbox[5])
                end
            end
        end
    end
}

return lethality
