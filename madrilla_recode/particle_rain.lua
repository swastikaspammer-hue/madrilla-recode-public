local hvc_droplet = {}
local hvc_droplet_mt = { __index = hvc_droplet }

function hvc_droplet.new(id, x, distance)
    local object = setmetatable({
        id = id, x = x, y = -100, distance = distance, width = 0, height = 0, render_width = 0, render_height = 0, speed = 0
    }, hvc_droplet_mt)
    object:setup()
    return object
end

function hvc_droplet:setup()
    self.width = self.distance / 2
    self.height = self.distance * 3
    self.speed = self.distance * 1.5
    self.render_width = self.width
    self.render_height = self.height
end

local hvc_storm_manager = {}
local hvc_storm_manager_mt = { __index = hvc_storm_manager }

function hvc_storm_manager.new()
    local object = setmetatable({
        animation = { frametime_mod = 400, droplet = { color = { r = 200, g = 200, b = 255, a = 40 } } },
        droplets = {}, screen = { x = 0, y = 0 }, droplet_total_count = 0, droplet_current_count = 0,
        droplet_settings = { spawn_speed = 0.005, last_spawn = globals.realtime(), max_droplets = 150 },
        wind = { last_wind = globals.realtime(), delay = 0.1, increment = 0.001, in_reverse = false, current_reverse_state = false, max_speed = 1, speed_base = 0, speed = 0 },
    }, hvc_storm_manager_mt)
    return object
end

function hvc_storm_manager:setup()
    local x, y = client.screen_size()
    self.screen.x = x
    self.screen.y = y
end

function hvc_storm_manager:wind_fx()
    self.wind.speed = self.wind.speed_base * client.random_float(0.5, 1.5)
    local time_now = globals.realtime()
    if (time_now - self.wind.last_wind > self.wind.delay) then
        if (self.wind.speed_base >= self.wind.max_speed) then self.wind.in_reverse = true
        elseif (self.wind.speed_base <= 0 - self.wind.max_speed) then self.wind.in_reverse = false end

        if (self.wind.in_reverse == true) then self.wind.speed_base = self.wind.speed_base - (self.wind.increment + client.random_float(0, 0.005))
        else self.wind.speed_base = self.wind.speed_base + (self.wind.increment + client.random_float(0, 0.005)) end

        if (self.wind.in_reverse ~= self.wind.current_reverse_state) then
            self.wind.delay = client.random_float(0.045, 0.2)
            self.wind.current_reverse_state = self.wind.in_reverse
        end
        self.wind.last_wind = time_now
    end
end

function hvc_storm_manager:process()
    self:setup()
    self:wind_fx()
    self:rain_visuals()
end

function hvc_storm_manager:rain_visuals()
    local frametime = globals.frametime()
    local camera_pitch, _ = client.camera_angles()
    camera_pitch = math.abs(camera_pitch)
    camera_pitch = 0 - (camera_pitch - 95) / 95
    if camera_pitch == 0 then camera_pitch = 0.01 end -- prevent division by zero

    for _, droplet in pairs(self.droplets) do
        self:translate_droplet(droplet, frametime, camera_pitch)
        self:render_droplet(droplet)
    end

    local time_now = globals.realtime()
    if (time_now - self.droplet_settings.last_spawn < self.droplet_settings.spawn_speed) then return end
    self.droplet_settings.last_spawn = time_now

    if (self.droplet_current_count >= self.droplet_settings.max_droplets) then return end
    self:add_droplet()
end

function hvc_storm_manager:add_droplet()
    local id = self.droplet_total_count + 1
    local droplet = hvc_droplet.new(id, client.random_int(1, self.screen.x), client.random_int(1, 6))
    self.droplet_total_count = id
    self.droplet_current_count = self.droplet_current_count + 1
    self.droplets[id] = droplet
end

function hvc_storm_manager:translate_droplet(droplet, frametime, camera_pitch_mod)
    droplet.render_height = math.max(1, droplet.height * camera_pitch_mod + 1)
    droplet.y = droplet.y + frametime * (droplet.speed / camera_pitch_mod) * self.animation.frametime_mod
    droplet.x = droplet.x + frametime * (self.wind.speed) * self.animation.frametime_mod

    if (droplet.y > self.screen.y) then
        self.droplets[droplet.id] = nil
        self.droplet_current_count = self.droplet_current_count - 1
    end
end

function hvc_storm_manager:render_droplet(droplet)
    renderer.rectangle(
        math.floor(droplet.x), math.floor(droplet.y), 
        math.max(1, math.floor(droplet.render_width)), math.max(1, math.floor(droplet.render_height)),
        self.animation.droplet.color.r, self.animation.droplet.color.g, self.animation.droplet.color.b, self.animation.droplet.color.a
    )
end

local storm_manager = hvc_storm_manager.new()
local particle_weather = {}

function particle_weather.process(type_str)
    if type_str == "particle rain" then
        storm_manager.animation.droplet.color = { r = 200, g = 200, b = 255, a = 60 }
        storm_manager.droplet_settings.max_droplets = 150
        storm_manager.animation.frametime_mod = 400
    elseif type_str == "particle snow" then
        storm_manager.animation.droplet.color = { r = 255, g = 255, b = 255, a = 120 }
        storm_manager.droplet_settings.max_droplets = 200
        storm_manager.animation.frametime_mod = 150
    elseif type_str == "particle ash" then
        storm_manager.animation.droplet.color = { r = 80, g = 80, b = 80, a = 150 }
        storm_manager.droplet_settings.max_droplets = 100
        storm_manager.animation.frametime_mod = 80
    else
        return
    end
    storm_manager:process()
end

return particle_weather
