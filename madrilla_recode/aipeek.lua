local ffi = require 'ffi'
local bit = require 'bit'
local vector = require 'vector'
local trace = require 'gamesense/trace'
local menu = require 'madrilla_recode/menu'

local function includes(table, key)
    for i=1, #table do
        if table[i] == key then
            return true
        end
    end
    return false
end

local function extrapolate(player, ticks, x, y, z)
    local xv, yv, zv = entity.get_prop(player, "m_vecVelocity")
    if xv == nil then return x, y, z end
    local new_x = x + globals.tickinterval() * xv * ticks
    local new_y = y + globals.tickinterval() * yv * ticks
    local new_z = z + globals.tickinterval() * zv * ticks
    return new_x, new_y, new_z
end  

local function is_in_air(player)
    local flags = entity.get_prop(player, "m_fFlags")
    if flags == nil then return false end
    return bit.band(flags, 1) == 0
end

local my_old_view = vector(0, 0, 0)
local my_old_vec = vector(0, 0, 0)
local minimum_damage = ui.reference('RAGE', 'Aimbot', 'Minimum damage')
local double_tap, double_tap_key = ui.reference('RAGE', 'Aimbot', 'Double tap')
local ref_yaw, ref_yaw_add = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local ref_yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local ref_pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")

local quick_peek_assist = { ui.reference("RAGE", "Other", "Quick peek assist") }
local quick_peek_assist_mode = { ui.reference("RAGE", "Other", "Quick peek assist mode") }

local IS_WORKING = false
local WORKING_VEC = my_old_vec
local RUN_MOVEMENT = false
local current_cmd = nil
local tickbase_max = 0
local tickbase_diff = 0
local is_teleporting = false

local function init_old()
	local me = entity.get_local_player()
	if me == nil then return end
	local pitch, yaw = client.camera_angles()
	my_old_view = vector(pitch, yaw, 0)
	local x, y, z = entity.hitbox_position(me, 3)
    if x then
	    my_old_vec = vector(x, y, z)
    end
end

local function vector_angles(x1, y1, z1, x2, y2, z2)
	local origin_x, origin_y, origin_z
	local target_x, target_y, target_z
	if x2 == nil then
		target_x, target_y, target_z = x1, y1, z1
		origin_x, origin_y, origin_z = client.eye_position()
		if origin_x == nil then return 0, 0 end
	else
		origin_x, origin_y, origin_z = x1, y1, z1
		target_x, target_y, target_z = x2, y2, z2
	end

	local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z
	if delta_x == 0 and delta_y == 0 then
		return (delta_z > 0 and 270 or 90), 0
	else
		local yaw = math.deg(math.atan2(delta_y, delta_x))
		local hyp = math.sqrt(delta_x*delta_x + delta_y*delta_y)
		local pitch = math.deg(math.atan2(-delta_z, hyp))
		return pitch, yaw
	end
end

local function get_view_point(radius, v, vec)
	local eye_pos = vec
	local viewangle = my_old_view
	local a_vec = eye_pos + vector(0,0,0):init_from_angles(0, (90 + viewangle.y + radius), 0) * v
	return a_vec
end

local function get_predict_point(radius, segament, vec)
	local points = {}
	segament = math.max(2, math.floor(segament))
	local angles_pre_point = 360 / segament
	for i = 0, 360, angles_pre_point do
		local m_p = get_view_point(i, radius, vec)
		table.insert(points, m_p)
	end
	return points
end

local function get_depart_point(vec, my_vec, department, limit_vec)
	local vec_1 = vector(vec.x, vec.y, 0)
	local vec_2 = vector(my_vec.x, my_vec.y, 0)
	local vec_3 = vector(limit_vec.x, limit_vec.y, 0)

	local each_plus = (vec_1 - vec_2) / department
	local limit_vec_cal = (vec_3 - vec_2):length()

	local points = {}
	for i = 1, department do
		local add_vec = each_plus * i
		if add_vec:length() < limit_vec_cal then
			table.insert(points, my_vec + add_vec)
		end
	end
	return points
end

local function endpos(origin, dest)
    local local_player = entity.get_local_player()
    local tr = trace.line(origin, dest, { skip = local_player })
    return tr.end_pos, tr.fraction
end

local function draw_circle_3d(x, y, z, radius, r, g, b, a, accuracy, width, outline, start_degrees, percentage, fill_r, fill_g, fill_b, fill_a)
	accuracy = accuracy ~= nil and accuracy or 2
	width = width ~= nil and width or 1
	outline = outline ~= nil and outline or false
	start_degrees = start_degrees ~= nil and start_degrees or 0
	percentage = percentage ~= nil and percentage or 4

	local center_x, center_y
	if fill_a then
		center_x, center_y = renderer.world_to_screen(x, y, z)
	end

	local screen_x_line_old, screen_y_line_old
	for rot=start_degrees, percentage*360, accuracy do
		local rot_temp = math.rad(rot)
		local lineX, lineY, lineZ = radius * math.cos(rot_temp) + x, radius * math.sin(rot_temp) + y, z
		local screen_x_line, screen_y_line = renderer.world_to_screen(lineX, lineY, lineZ)
		if screen_x_line ~= nil and screen_x_line_old ~= nil then
			if fill_a and center_x ~= nil then
				renderer.triangle(screen_x_line, screen_y_line, screen_x_line_old, screen_y_line_old, center_x, center_y, fill_r, fill_g, fill_b, fill_a)
			end
			for i=1, width do
				local i=i-1
				renderer.line(screen_x_line, screen_y_line-i, screen_x_line_old, screen_y_line_old-i, r, g, b, a)
				renderer.line(screen_x_line-1, screen_y_line, screen_x_line_old-i, screen_y_line_old, r, g, b, a)
			end
			if outline then
				local outline_a = a/255*160
				renderer.line(screen_x_line, screen_y_line-width, screen_x_line_old, screen_y_line_old-width, 16, 16, 16, outline_a)
				renderer.line(screen_x_line, screen_y_line+1, screen_x_line_old, screen_y_line_old+1, 16, 16, 16, outline_a)
			end
		end
		screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
	end
end

local function calculate_end_pos(draw_line, draw_circle, debug_fraction, vec, my_vec, dr, dg, db, da)
	local me = entity.get_local_player()
	local dx, dy, dz = entity.get_origin(me)
	local debug_vec = vector(my_vec.x, my_vec.y, dz + 5)
	local debug_vec_2 = vector(vec.x, vec.y, dz + 5)
	local pos_1, fraction_1 = endpos(my_vec, vec)
	local pos_2, fraction_2 = endpos(debug_vec, debug_vec_2)

	local end_Pos = vector(pos_2.x, pos_2.y, vec.z)

	if draw_line then
		local x1, y1 = renderer.world_to_screen(pos_2.x, pos_2.y, pos_2.z)
		local x2, y2 = renderer.world_to_screen(debug_vec.x, debug_vec.y, debug_vec.z)
        if x1 and x2 then
		    renderer.line(x1, y1, x2, y2 , dr, dg, db, da)
        end
	end

	if debug_fraction then
		local debug_text = tostring(math.floor(fraction_1) * 100)
		local x3, y3 = renderer.world_to_screen(debug_vec_2.x, debug_vec_2.y, debug_vec_2.z)
        if x3 then
		    renderer.text(x3, y3, dr, dg, db, da, 'c', 0, debug_text)
        end
	end

	return end_Pos
end

local function calculate_real_point(draw_line, draw_circle, debug_fraction, vec, dr, dg, db, da)
	local points_list = {}
	local my_vec = vec
	local points = get_predict_point(ui.get(menu.antiaim.aiPeek.radius), ui.get(menu.antiaim.aiPeek.segament), my_vec)

	for i, o in pairs(points) do
		if ui.get(menu.antiaim.aiPeek.middle) then
			local halfone = points[i+1]
			halfone = halfone == nil and points[1] or halfone
			local halfpoint = vector((halfone.x + o.x)/2 ,(halfone.y + o.y)/2, o.z)
			local end_pos = calculate_end_pos(draw_line,draw_circle ,debug_fraction, halfpoint, my_vec, dr, dg, db, da)
            table.insert(points_list, {
                endpos = end_pos,
                ideal = halfpoint
            })
		end
        local end_pos = calculate_end_pos(draw_line,draw_circle ,debug_fraction, o, my_vec, dr, dg, db, da)
        table.insert(points_list, {
            endpos = end_pos,
            ideal = o
        })
	end

	return points_list
end

local function run_all_Point(debug_line, debug_cir, debug_fraction, department, vec, dr, dg, db, da)
	local me = entity.get_local_player()
	local m_points = calculate_real_point(debug_line ,debug_cir ,debug_fraction, vec, dr, dg, db, da)
	local dx, dy, dz = entity.get_origin(me)
	local points = {}
	for i, o in pairs(m_points) do
		local calculate_vec = o.ideal
		local limit_vec = o.endpos
		table.insert(points, limit_vec)
		if debug_cir then
			draw_circle_3d(limit_vec.x, limit_vec.y, dz + 5, 5, dr, dg, db, da)
		end

		if department ~= 1 then
			for _, depart_vec in pairs(get_depart_point(calculate_vec, vec, department, limit_vec)) do
				table.insert(points, depart_vec)

				if debug_cir then
					draw_circle_3d(depart_vec.x, depart_vec.y,dz + 5, 5, dr, dg, db, da)
				end
			end
		end
	end

	return points
end

local function get_peek_hitbox(content)
	local hitbox = {}
	if includes(content, 'Head') then table.insert(hitbox, 0) end
	if includes(content, 'Neck') then table.insert(hitbox, 1) end
	if includes(content, 'Chest') then
		table.insert(hitbox, 4) table.insert(hitbox, 5) table.insert(hitbox, 6)
	end
	if includes(content, 'Stomach') then
		table.insert(hitbox, 2) table.insert(hitbox, 3)
	end
	if includes(content, 'Arms') then
		table.insert(hitbox, 13) table.insert(hitbox, 14) table.insert(hitbox, 15)
		table.insert(hitbox, 16) table.insert(hitbox, 17) table.insert(hitbox, 18)
	end
	if includes(content, 'Legs') then
		table.insert(hitbox, 7) table.insert(hitbox, 8) table.insert(hitbox, 9) table.insert(hitbox, 10)
	end
	if includes(content, 'Feet') then
		table.insert(hitbox, 11) table.insert(hitbox, 12)
	end
	return hitbox
end

local function set_movement(cmd, desired_pos)
    local local_player = entity.get_local_player()
    local x, y, z = entity.get_prop(local_player, "m_vecAbsOrigin")
    local pitch, yaw = vector_angles(x, y, z, desired_pos.x, desired_pos.y, desired_pos.z)
    cmd.in_forward = 1
    cmd.in_back = 0
    cmd.in_moveleft = 0
    cmd.in_moveright = 0
    cmd.in_speed = 0
    cmd.forwardmove = 800
    cmd.sidemove = 0
    cmd.move_yaw = yaw
end

local aipeek = {}

function aipeek.OnPaint()
    if not ui.get(menu.antiaim.aiPeek.enable) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local r, g, b, a = ui.get(menu.antiaim.aiPeek.color)
    
    if ui.get(menu.antiaim.aiPeek.key) == false then
		return 
	end

    local debugger = ui.get(menu.antiaim.aiPeek.debugger)
    local m_points = run_all_Point(
        includes(debugger, 'Line player-predict'),
        includes(debugger, 'Base'),
        includes(debugger, 'Fraction detection'),
        ui.get(menu.antiaim.aiPeek.depart),
        my_old_vec,
        r, g, b, a
    )

    local sort_type = ui.get(menu.antiaim.aiPeek.mode)
    local p_Hitbox = get_peek_hitbox(ui.get(menu.antiaim.aiPeek.hitbox))
    local p_List = {}
    local predict_tick = ui.get(menu.antiaim.aiPeek.tick)

    local target_opt = ui.get(menu.antiaim.aiPeek.target)

    if target_opt ~= 'Current' then
		local players = entity.get_players(true)
		if #players == 0 then
			WORKING_VEC = nil
			IS_WORKING = false
			return 
		end
		for i,o in pairs(m_points) do
			for _,player in pairs(players) do
				local best_target = player
				for _,v in pairs(p_Hitbox) do
					local ex, ey, ez = entity.hitbox_position(best_target, v)
					local new_x, new_y, new_z = extrapolate(best_target, predict_tick, ex, ey, ez)
					local e_vec = vector(new_x, new_y, new_z)
					local _, dmg = client.trace_bullet(me, o.x, o.y, o.z, e_vec.x, e_vec.y, e_vec.z)
					if dmg >= math.min(ui.get(minimum_damage), entity.get_prop(best_target, 'm_iHealth')) then
						table.insert(p_List, { TARGET = best_target, damage = dmg, vec = o, enemy_vec = e_vec })
					end
				end
			end
			if ui.get(menu.antiaim.aiPeek.limit) and #p_List >= ui.get(menu.antiaim.aiPeek.limitNum) then break end
		end
	else
		local best_target = client.current_threat()
		if best_target == nil then
			WORKING_VEC = nil
			IS_WORKING = false
			return 
		end
		for i,o in pairs(m_points) do
			for k,v in pairs(p_Hitbox) do
				local ex, ey, ez = entity.hitbox_position(best_target, v)
				local new_x, new_y, new_z = extrapolate(best_target, predict_tick, ex, ey, ez)
				local e_vec = vector(new_x, new_y, new_z)
				local _, dmg = client.trace_bullet(me, o.x, o.y, o.z, e_vec.x, e_vec.y, e_vec.z)
				if dmg > math.min(ui.get(minimum_damage), entity.get_prop(best_target, 'm_iHealth')) then
					table.insert(p_List, { TARGET = best_target, damage = dmg, vec = o, enemy_vec = e_vec })
				end
			end
			if ui.get(menu.antiaim.aiPeek.limit) and #p_List >= ui.get(menu.antiaim.aiPeek.limitNum) then break end
		end
	end

    table.sort(p_List, function(a, b)
		if sort_type == 'Risky' then
			return a.damage > b.damage
		else
			return a.damage < b.damage
		end
	end)

	for i,o in pairs(p_List) do
		if entity.is_alive(o.TARGET) == false then table.remove(p_List, i) end
	end

    local _, _, debug_point = entity.get_origin(me)
	if #p_List >= 1 then
		local lib = p_List[1]
		local vec = lib.vec
		local damage = lib.damage 
		local e_vec = lib.enemy_vec
		local new_debug = vector(vec.x, vec.y, debug_point + 5)
		local x1, y1 = renderer.world_to_screen(new_debug.x, new_debug.y, new_debug.z)
		if includes(debugger, 'Line predict-target')  then
			local x2, y2 = renderer.world_to_screen(e_vec.x, e_vec.y, e_vec.z)
            if x1 and x2 then renderer.line(x1, y1, x2, y2, r, g, b, a) end
		end

		if y1 ~= nil then y1 = y1 - 12 end

		local render_text = tostring(math.floor(damage))
        if x1 then renderer.text(x1, y1 , r, g, b, a, 0, render_text) end
		IS_WORKING = true 
		WORKING_VEC = vec
	else
		WORKING_VEC = nil
		IS_WORKING = false
	end

    local indr, indg, indb = 0, 255, 0
    if ui.get(menu.antiaim.aiPeek.key) then
        if IS_WORKING and RUN_MOVEMENT and not is_in_air(me) and WORKING_VEC ~= nil then
            indr, indg, indb = 0, 255, 0
        else
            indr, indg, indb = 255, 255, 0
        end
    end
    renderer.indicator(indr, indg, indb, 255, 'AI PEEK')
end

function aipeek.OnRunCommand(cmd)
    current_cmd = cmd.command_number

    local me = entity.get_local_player()
	if me == nil or entity.is_alive(me) == false then return end

	local m_x, m_y, m_z = entity.hitbox_position(me, 3)
	local my_vec = vector(m_x, m_y, m_z)
	local mpitch, myaw = client.camera_angles()

	if ui.get(menu.antiaim.aiPeek.key) == false or ui.get(menu.antiaim.aiPeek.unlock) then
		my_old_view = vector(mpitch, myaw, 0)
	end

	if ui.get(menu.antiaim.aiPeek.key) == false then
		my_old_vec = my_vec
	end
end

function aipeek.OnPredictCommand(cmd)
    if cmd.command_number == current_cmd then
        current_cmd = nil
        local tickbase = entity.get_prop(entity.get_local_player(), "m_nTickBase")
        if tickbase_max ~= nil then
            tickbase_diff = tickbase - tickbase_max
        end
        tickbase_max = math.max(tickbase, tickbase_max or 0)
    end
end

function aipeek.OnAimFire()
    if not ui.get(menu.antiaim.aiPeek.enable) then return end
    RUN_MOVEMENT = false
end

function aipeek.OnSetupCommand(cmd)
    local me = entity.get_local_player()
	if me == nil or not ui.get(menu.antiaim.aiPeek.enable) or not entity.is_alive(me) then return end

    local is_forward = cmd.in_forward == 1
	local is_backward = cmd.in_back == 1
	local is_left = cmd.in_moveleft == 1
	local is_right = cmd.in_moveright == 1

    if tickbase_diff ~= nil and tickbase_diff >= 14 then
        is_teleporting = true
    else
        is_teleporting = false
    end

    if ui.get(menu.antiaim.aiPeek.key) then
        local my_weapon = entity.get_player_weapon(me)
		if my_weapon == nil then return end

        local in_air = is_in_air(me)
		local timer = globals.curtime()
		local can_Fire = (entity.get_prop(me, "m_flNextAttack") <= timer and entity.get_prop(my_weapon, "m_flNextPrimaryAttack") <= timer)
		local x, y, z = entity.get_origin(me)

		if math.abs(x - my_old_vec.x) <= 10 then
			RUN_MOVEMENT = true
		end

		if can_Fire == false then
			RUN_MOVEMENT = false 
		end

		if IS_WORKING and RUN_MOVEMENT and in_air == false and WORKING_VEC ~= nil then
            -- Ideal Tick logic: Enable DT natively
            ui.set(double_tap_key, "On hotkey")

            -- Anti-Aim override logic
            local pitch, yaw = vector_angles(x, y, z, my_old_vec.x, my_old_vec.y, my_old_vec.z)
            ui.set(ref_yaw_base, "Local view")
            ui.set(ref_yaw, "180")
            local yaw_offset = yaw - 180
            if yaw_offset > 180 then yaw_offset = yaw_offset - 360 end
            if yaw_offset < -180 then yaw_offset = yaw_offset + 360 end
            ui.set(ref_yaw_add, yaw_offset)

			set_movement(cmd, WORKING_VEC)
		elseif RUN_MOVEMENT == false and in_air == false and is_forward == false and is_backward == false and is_left == false and is_right == false then
            cmd.force_defensive = true
            
            if is_teleporting and tickbase_diff == 0 then
                ui.set(double_tap_key, 'On hotkey')
            end

            ui.set(ref_yaw_base, "At targets") -- restore logic handled by framework, this serves as reset

			set_movement(cmd, my_old_vec)
		end
    end
end

return aipeek
