local menu = require("madrilla_recode/menu")

local duck_peek_assist = ui.reference("RAGE", "Other", "Duck peek assist")

local airlag = {
    OnSetupCommand = function(cmd)
        local local_player = entity.get_local_player()
        if not local_player or not entity.is_alive(local_player) then return end

        local in_air = bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 0

        if ui.get(menu.antiaim.airLag) and ui.get(menu.antiaim.airLagHotkey) and in_air then
            local condition = ui.get(menu.antiaim.airLagCondition)
            local should_lag = true

            if condition == "On hittable" then
                should_lag = false
                local target = client.current_threat()
                if target then
                    local espData = entity.get_esp_data(target)
                    if espData and bit.band(espData.flags, 2048) ~= 0 then
                        should_lag = true
                    end
                end
            end

            if should_lag then
                if globals.tickcount() % ui.get(menu.antiaim.airLagTicks) == 0 then
                    ui.set(duck_peek_assist, "Always on")
                else
                    ui.set(duck_peek_assist, "On hotkey")
                end
            else
                ui.set(duck_peek_assist, "On hotkey")
            end
        else
            ui.set(duck_peek_assist, "On hotkey")
        end
    end
}

return airlag
