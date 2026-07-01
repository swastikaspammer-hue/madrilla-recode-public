local solus_ui = {}

local function RoundedRect(x, y, w, h, radius, r, g, b, a)
    renderer.rectangle(x + radius, y, w - radius * 2, radius, r, g, b, a)
    renderer.rectangle(x, y + radius, radius, h - radius * 2, r, g, b, a)
    renderer.rectangle(x + radius, y + h - radius, w - radius * 2, radius, r, g, b, a)
    renderer.rectangle(x + w - radius, y + radius, radius, h - radius * 2, r, g, b, a)
    renderer.rectangle(x + radius, y + radius, w - radius * 2, h - radius * 2, r, g, b, a)
    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25)
    renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
end

local rounding = 4
local rad = rounding + 2
local n = 45
local o = 20

local function OutlineGlow(x, y, w, h, radius, r, g, b, a)
    renderer.rectangle(x + 2, y + radius + rad, 1, h - rad * 2 - radius * 2, r, g, b, a)
    renderer.rectangle(x + w - 3, y + radius + rad, 1, h - rad * 2 - radius * 2, r, g, b, a)
    renderer.rectangle(x + radius + rad, y + 2, w - rad * 2 - radius * 2, 1, r, g, b, a)
    renderer.rectangle(x + radius + rad, y + h - 3, w - rad * 2 - radius * 2, 1, r, g, b, a)
    renderer.circle_outline(x + radius + rad, y + radius + rad, r, g, b, a, radius + rounding, 180, 0.25, 1)
    renderer.circle_outline(x + w - radius - rad, y + radius + rad, r, g, b, a, radius + rounding, 270, 0.25, 1)
    renderer.circle_outline(x + radius + rad, y + h - radius - rad, r, g, b, a, radius + rounding, 90, 0.25, 1)
    renderer.circle_outline(x + w - radius - rad, y + h - radius - rad, r, g, b, a, radius + rounding, 0, 0.25, 1)
end

local function FadedRoundedRect(x, y, w, h, radius, r, g, b, a, glow)
    local n_alpha = a / 255 * n
    renderer.rectangle(x + radius, y, w - radius * 2, 1, r, g, b, a)
    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, 1)
    renderer.gradient(x, y + radius, 1, h - radius * 2, r, g, b, a, r, g, b, n_alpha, false)
    renderer.gradient(x + w - 1, y + radius, 1, h - radius * 2, r, g, b, a, r, g, b, n_alpha, false)
    renderer.circle_outline(x + radius, y + h - radius, r, g, b, n_alpha, radius, 90, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, n_alpha, radius, 0, 0.25, 1)
    renderer.rectangle(x + radius, y + h - 1, w - radius * 2, 1, r, g, b, n_alpha)
    if glow and glow > 0 then
        for i = 4, glow do
            local rad_val = i / 2
            OutlineGlow(x - rad_val, y - rad_val, w + rad_val * 2, h + rad_val * 2, rad_val, r, g, b, glow - rad_val * 2)
        end
    end
end

local function HorizontalFadedRoundedRect(x, y, w, h, radius, r, g, b, a, glow, r1, g1, b1)
    local n_alpha = a / 255 * n
    renderer.rectangle(x, y + radius, 1, h - radius * 2, r, g, b, a)
    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, 1)
    renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, 1)
    renderer.gradient(x + radius, y, w / 3.5 - radius * 2, 1, r, g, b, a, 0, 0, 0, 0, true)
    renderer.gradient(x + radius, y + h - 1, w / 3.5 - radius * 2, 1, r, g, b, a, 0, 0, 0, 0, true)
    renderer.rectangle(x + radius, y + h - 1, w - radius * 2, 1, r1, g1, b1, n_alpha)
    renderer.rectangle(x + radius, y, w - radius * 2, 1, r1, g1, b1, n_alpha)
    renderer.circle_outline(x + w - radius, y + radius, r1, g1, b1, n_alpha, radius, -90, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + h - radius, r1, g1, b1, n_alpha, radius, 0, 0.25, 1)
    renderer.rectangle(x + w - 1, y + radius, 1, h - radius * 2, r1, g1, b1, n_alpha)
    if glow and glow > 0 then
        for i = 4, glow do
            local rad_val = i / 2
            OutlineGlow(x - rad_val, y - rad_val, w + rad_val * 2, h + rad_val * 2, rad_val, r1, g1, b1, glow - rad_val * 2)
        end
    end
end

local function FadedRoundedGlow(x, y, w, h, radius, r, g, b, a, glow, r1, g1, b1)
    local n_alpha = a / 255 * n
    renderer.rectangle(x + radius, y, w - radius * 2, 1, r, g, b, n_alpha)
    renderer.circle_outline(x + radius, y + radius, r, g, b, n_alpha, radius, 180, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + radius, r, g, b, n_alpha, radius, 270, 0.25, 1)
    renderer.rectangle(x, y + radius, 1, h - radius * 2, r, g, b, n_alpha)
    renderer.rectangle(x + w - 1, y + radius, 1, h - radius * 2, r, g, b, n_alpha)
    renderer.circle_outline(x + radius, y + h - radius, r, g, b, n_alpha, radius, 90, 0.25, 1)
    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, n_alpha, radius, 0, 0.25, 1)
    renderer.rectangle(x + radius, y + h - 1, w - radius * 2, 1, r, g, b, n_alpha)
    if glow and glow > 0 then
        for i = 4, glow do
            local rad_val = i / 2
            OutlineGlow(x - rad_val, y - rad_val, w + rad_val * 2, h + rad_val * 2, rad_val, r1, g1, b1, glow - rad_val * 2)
        end
    end
end

solus_ui.linear_interpolation = function(start, _end, time)
    return (_end - start) * time + start
end

solus_ui.clamp = function(value, minimum, maximum)
    if minimum > maximum then
        return math.min(math.max(value, maximum), minimum)
    else
        return math.min(math.max(value, minimum), maximum)
    end
end

solus_ui.lerp = function(start, _end, time)
    time = time or 0.005
    time = solus_ui.clamp(globals.frametime() * time * 175.0, 0.01, 1.0)
    local a = solus_ui.linear_interpolation(start, _end, time)
    if _end == 0.0 and a < 0.01 and a > -0.01 then
        a = 0.0
    elseif _end == 1.0 and a < 1.01 and a > 0.99 then
        a = 1.0
    end
    return a
end

solus_ui.container = function(x, y, w, h, r, g, b, a, alpha, fn)
    if alpha * 255 > 0 then
        renderer.blur(x, y, w, h)
    end
    RoundedRect(x, y, w, h, rounding, 17, 17, 17, a)
    FadedRoundedRect(x, y, w, h, rounding, r, g, b, alpha * 255, alpha * o)
    if fn then
        fn(x + rounding, y + rounding, w - rounding * 2, h - rounding * 2.0)
    end
end

solus_ui.horizontal_container = function(x, y, w, h, r, g, b, a, alpha, r1, g1, b1, fn)
    if alpha * 255 > 0 then
        renderer.blur(x, y, w, h)
    end
    RoundedRect(x, y, w, h, rounding, 17, 17, 17, a)
    HorizontalFadedRoundedRect(x, y, w, h, rounding, r, g, b, alpha * 255, alpha * o, r1, g1, b1)
    if fn then
        fn(x + rounding, y + rounding, w - rounding * 2, h - rounding * 2.0)
    end
end

solus_ui.container_glow = function(x, y, w, h, r, g, b, a, alpha, r1, g1, b1, fn)
    if alpha * 255 > 0 then
        renderer.blur(x, y, w, h)
    end
    RoundedRect(x, y, w, h, rounding, 17, 17, 17, a)
    FadedRoundedGlow(x, y, w, h, rounding, r, g, b, alpha * 255, alpha * o, r1, g1, b1)
    if fn then
        fn(x + rounding, y + rounding, w - rounding * 2, h - rounding * 2.0)
    end
end

solus_ui.measure_multitext = function(flags, _table)
    local a = 0
    for b, c in pairs(_table) do
        c.flags = c.flags or ''
        a = a + renderer.measure_text(c.flags, c.text)
    end
    return a
end

solus_ui.multitext = function(x, y, _table)
    for a, b in pairs(_table) do
        b.flags = b.flags or ''
        b.limit = b.limit or 0
        b.color = b.color or {255, 255, 255, 255}
        b.color[4] = b.color[4] or 255
        renderer.text(x, y, b.color[1], b.color[2], b.color[3], b.color[4], b.flags, b.limit, b.text)
        x = x + renderer.measure_text(b.flags, b.text)
    end
end

return solus_ui
