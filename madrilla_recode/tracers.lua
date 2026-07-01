local menu = require("madrilla_recode/menu")
local ffi = require("ffi")

local sprite_map = {
	["Blue glow"] = "sprites/blueglow1.vmt",
	["Light glow"] = "sprites/light_glow02.vmt",
	["Physbeam"] = "sprites/physbeam.vmt",
	["Purple laser"] = "sprites/purplelaser1.vmt"
}

ffi.cdef("    typedef struct { \n        float x; \n        float y; \n        float z;\n    } bbvec3_t;\n\n    struct bbeam_t\n    {\n        int m_nType;\n        void* m_pStartEnt;\n        int m_nStartAttachment;\n        void* m_pEndEnt;\n        int m_nEndAttachment;\n        bbvec3_t m_vecStart;\n        bbvec3_t m_vecEnd;\n        int m_nModelIndex;\n        const char* m_pszModelName;\n        int m_nHaloIndex;\n        const char* m_pszHaloName;\n        float m_flHaloScale;\n        float m_flLife;\n        float m_flWidth;\n        float m_flEndWidth;\n        float m_flFadeLength;\n        float m_flAmplitude;\n        float m_flBrightness;\n        float m_flSpeed;\n        int m_nStartFrame;\n        float m_flFrameRate;\n        float m_flRed;\n        float m_flGreen;\n        float m_flBlue;\n        bool m_bRenderable;\n        int m_nSegments;\n        int m_nFlags;\n        bbvec3_t m_vecCenter;\n        float m_flStartRadius;\n        float m_flEndRadius;\n    };\n")

local client_dll = client.find_signature("client.dll", "\xB9\xCC\xCC\xCC̡\xCC\xCC\xCC\xCC\xFF\x10\xA1\xCC\xCC\xCC̹")
local g_pBeam = ffi.cast("void**", ffi.cast("char*", client_dll) + 1)[0]
local vtable = ffi.cast("void***", g_pBeam)
local UpdateBeamInfo = ffi.cast("void (__thiscall*)(void*, void*)", vtable[0][6])
local CreateBeamPoints = ffi.cast("void*(__thiscall*)(void*, struct bbeam_t&)", vtable[0][12])

local function vec3_to_bbvec3(vec)
	local v = ffi.new("bbvec3_t")
	v.x, v.y, v.z = vec[1], vec[2], vec[3]
	return v
end

local function draw_beam(start_pos, end_pos, color)
    local width = ui.get(menu.visuals.bulletTracers.thickness) * 0.1
	local beam_info = ffi.new("struct bbeam_t")

	beam_info.m_vecStart = vec3_to_bbvec3(start_pos)
	beam_info.m_vecEnd = vec3_to_bbvec3(end_pos)
	beam_info.m_nSegments = 2
	beam_info.m_nType = 0
	beam_info.m_bRenderable = true
	beam_info.m_nFlags = bit.bor(33544)
	beam_info.m_pszModelName = sprite_map[ui.get(menu.visuals.bulletTracers.sprite)]
	beam_info.m_nModelIndex = -1
	beam_info.m_flHaloScale = 0
	beam_info.m_nStartAttachment = 0
	beam_info.m_nEndAttachment = 0
	beam_info.m_flLife = 2.0
	beam_info.m_flWidth = width
	beam_info.m_flEndWidth = width
	beam_info.m_flFadeLength = 0
	beam_info.m_flAmplitude = 0
	beam_info.m_flSpeed = 0
	beam_info.m_flFrameRate = 0
	beam_info.m_nHaloIndex = 0
	beam_info.m_nStartFrame = 0
	beam_info.m_flBrightness = color[4]
	beam_info.m_flRed = color[1]
	beam_info.m_flGreen = color[2]
	beam_info.m_flBlue = color[3]

	local beam = CreateBeamPoints(vtable, beam_info)

	if beam ~= nil then
		UpdateBeamInfo(g_pBeam, beam)
	end
end

local is_firing = false
local last_attack_time = -1
local last_item_def = -1
local active_shots = {}
local pending_shots = {}
local hitgroups_map = {
	{0, 1},
	{4, 5, 6},
	{2, 3},
	{13, 15, 16},
	{14, 17, 18},
	{7, 9, 11},
	{8, 10, 12}
}

local function render_beam(player_ent, shot_data)
	local is_local = entity.get_local_player() == player_ent
	local is_enemy_tracers_enabled = ui.get(menu.visuals.bulletTracers.enemyEnable) and entity.is_enemy(player_ent)

	if not is_local and not is_enemy_tracers_enabled then return end

	local r, g, b, a = ui.get(shot_data.is_enemy and menu.visuals.bulletTracers.enemyColor or menu.visuals.bulletTracers.localColor)

	if not ui.get(menu.visuals.bulletTracers.localEnable) and is_local and not shot_data.projected then return end

	if ui.get(menu.visuals.bulletTracers.localHitEnable) and not shot_data.is_enemy and shot_data.projected then
		r, g, b, a = ui.get(menu.visuals.bulletTracers.localHitColor)
	end

	draw_beam(shot_data.origin, shot_data.list[#shot_data.list], {r, g, b, a})
end

local function check_firing()
	if ui.get(menu.visuals.bulletTracers.enable) and (ui.get(menu.visuals.bulletTracers.localEnable) or ui.get(menu.visuals.bulletTracers.localHitEnable)) then
		pending_shots[#pending_shots + 1] = {
			m_bPassed = false,
			m_flLife = globals.realtime() + 0.5,
			m_vecStart = {client.eye_position()}
		}
	end
end

local tracers = {
    OnAimFire = function(event)
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        is_firing = true
        check_firing()
    end,

    OnSetupCommand = function()
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        local lp = entity.get_local_player()
        local wep = entity.get_player_weapon(lp)

        if lp == nil or wep == nil then return end

        local next_attack = entity.get_prop(wep, "m_flNextPrimaryAttack")
        local item_def = bit.band(entity.get_prop(wep, "m_iItemDefinitionIndex") or 0, 65535)

        if is_firing == false and last_attack_time ~= -1 and next_attack ~= last_attack_time and item_def == last_item_def then
            check_firing()
        end

        is_firing = false
        last_attack_time = next_attack
        last_item_def = item_def
    end,

    OnRoundStart = function()
        active_shots = {}
        pending_shots = {}
    end,

    OnWeaponFire = function(event)
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        local tick = globals.tickcount()
        local lp = entity.get_local_player()
        local shooter = client.userid_to_entindex(event.userid)

        if active_shots[shooter] == nil then active_shots[shooter] = {} end
        if active_shots[shooter][tick] == nil then active_shots[shooter][tick] = {} end

        local tick_shots = active_shots[shooter][tick]
        local origin = {entity.hitbox_position(shooter, 0)}
        local is_enemy = shooter ~= lp and entity.is_enemy(shooter)

        if shooter == lp then
            local found = false
            for i = 1, #pending_shots do
                local s = pending_shots[i]
                if s ~= nil and not s.m_bPassed then
                    pending_shots[i].m_bPassed = true
                    origin, found = s.m_vecStart, true
                    break
                end
            end
            if not found then origin = nil end
        end

        active_shots[shooter][tick][#tick_shots + 1] = {
            projected = false,
            list = {},
            origin = origin,
            is_enemy = is_enemy,
            dead_time = globals.realtime() + 0.5
        }
    end,

    OnBulletImpact = function(event)
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        local lp = entity.get_local_player()
        local shooter = client.userid_to_entindex(event.userid)
        local tick = globals.tickcount()

        if active_shots[shooter] == nil or active_shots[shooter][tick] == nil or #active_shots[shooter][tick] <= 0 then return end

        local tick_shots = active_shots[shooter][tick]
        table.insert(active_shots[shooter][tick][#tick_shots].list, {event.x, event.y, event.z})
    end,

    OnPlayerHurt = function(event)
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        local tick = globals.tickcount()
        local lp = entity.get_local_player()
        local attacker = client.userid_to_entindex(event.attacker)

        if active_shots[attacker] == nil or active_shots[attacker][tick] == nil then return end

        local min_dist = math.huge
        local hg_map = hitgroups_map[event.hitgroup]
        local last_shot = active_shots[attacker][tick][#active_shots[attacker][tick]]

        if #last_shot.list <= 0 then return end

        for i = 1, #last_shot.list do
            local impact = last_shot.list[i]
            if hg_map ~= nil then
                for j = 1, #hg_map do
                    local hx, hy, hz = entity.hitbox_position(attacker, hg_map[j])
                    if hx ~= nil then
                        local dist = math.sqrt((impact[1] - hx)^2 + (impact[2] - hy)^2 + (impact[3] - hz)^2)
                        if dist < min_dist then
                            min_dist = dist
                            last_shot.projected = true
                        end
                    end
                end
            end
        end
    end,

    OnPaint = function()
        if not ui.get(menu.visuals.bulletTracers.enable) then return end
        local rt = globals.realtime()
        local lp = entity.get_local_player()

        for shooter, ticks in pairs(active_shots) do
            for tick, shots in pairs(ticks) do
                if #shots <= 0 or shots == {} then
                    active_shots[shooter][tick] = nil
                end

                for i, shot in pairs(shots) do
                    if rt > shot.dead_time or shot.origin == nil or #shot.list <= 0 then
                        active_shots[shooter][tick][i] = nil
                    else
                        render_beam(shooter, shot)
                        active_shots[shooter][tick][i] = nil
                    end
                end
            end
        end

        for i = 1, #pending_shots do
            if pending_shots[i] == nil or pending_shots[i].m_bPassed or rt > pending_shots[i].m_flLife then
                table.remove(pending_shots, i)
                break
            end
        end
    end
}

return tracers
