local menu = require("madrilla_recode/menu")
local vector = require("vector")
local bit = require("bit")
local ffi = require("ffi")
local safepoint = require("madrilla_recode/ragebot/safepoint")

local MAX_TARGET_TIME = 5 -- how long we want to keep on targetting an enemy after they go dormant (in seconds)
local MIN_DAMAGE = 1 -- the minimum damage we want to do to consider a target valid, should probably be based on current weapon and stuff but this is good enough for now
local HITCHANCE = 60 -- the minimum hitchance we want to have before shooting, should probably also be based on current weapon and stuff but again good enough for now

local pWeaponSystemAddr = client.find_signature("client.dll", "\x8B\x35\xCC\xCC\xCC\xCC\xFF\x10\x0F\xB7\xC0")
local pWeaponSystem = ffi.cast("void****", ffi.cast("char*", pWeaponSystemAddr) + 0x2)[0]

local CCSWeaponInfo_t = [[
    struct {
        char            __pad00[0x138];         // 0x0000
        float           m_flMaxSpeed;           // 0x0138
        float           m_flMaxSpeedAlt;        // 0x013C
    }
]]

local GetCSWeaponInfo = vtable_thunk(2, CCSWeaponInfo_t .. "*(__thiscall*)(void*, unsigned int)")
local GetClientEntity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")
local IsWeapon = vtable_thunk(166, "bool(__thiscall*)(void*)")
local GetInaccuracy = vtable_thunk(483, "float(__thiscall*)(void*)")

local function NormalizeAngle(angle)
    while angle > 180 do
        angle = angle - 360
    end

    while angle < -180 do
        angle = angle + 360
    end

    return angle
end

local function CreateEnemyTable(index)
    return {
        entityIndex = index,
        lastSeen = globals.realtime(),
        enemyOrigin = vector(0, 0, 0),
        hitboxes = {},
        wasSetUp = false
    }
end

-- if we want to have proper accuracy we should probably make proper hitchance, but this is enough for now.
local function CalculateHitChance(activeWeapon)
    local INACCURACY_EPSILON = 0.0001
    local currentInaccuracy = GetInaccuracy(activeWeapon) or INACCURACY_EPSILON
    currentInaccuracy = math.max(currentInaccuracy, INACCURACY_EPSILON) -- prevent division by zero and stuff, also just in general make sure we don't get weird values

    local hitchance = math.min(math.max(1 / currentInaccuracy, 0), 100)

    --print("current hitchance: " .. hitchance .. "% (inaccuracy: " .. currentInaccuracy .. ")")
    return hitchance
end

local function QuickStop(cmd, fullStop)
    local localPlayer = entity.get_local_player()
    if localPlayer == nil then
        return
    end

    local weaponIndex = entity.get_player_weapon(localPlayer)
    if weaponIndex == nil then
        return
    end

    local itemDefinitionIndex = entity.get_prop(weaponIndex, "m_iItemDefinitionIndex")
    if itemDefinitionIndex == nil then
        return
    end

    itemDefinitionIndex = bit.band(itemDefinitionIndex, 0xFFFF) -- the item definition index is only 16 bits long, but we get it as 32 bit value, map it to 16 bit
    local pWeaponInfo = GetCSWeaponInfo(pWeaponSystem, itemDefinitionIndex)
    if pWeaponInfo == nil then
        return
    end

    local isScoped = entity.get_prop(localPlayer, "m_bIsScoped") == 1
    local maxSpeed = isScoped and pWeaponInfo.m_flMaxSpeedAlt or pWeaponInfo.m_flMaxSpeed
    local accurateSpeed = maxSpeed * 0.34

    local currentVelocity = vector(entity.get_prop(localPlayer, "m_vecVelocity"))
    local currentSpeed = currentVelocity:length2d()
    if not fullStop and currentSpeed < accurateSpeed then
        return
    end

    if currentSpeed <= 15 then -- we could remove the magic number, but too complicated for too little gain
        cmd.forwardmove = 0
        cmd.sidemove = 0
        return
    end

    local viewPitch, viewYaw = client.camera_angles()
    local velocityYaw = math.deg(math.atan2(currentVelocity.y, currentVelocity.x))

    local correctedYawRad = math.rad(NormalizeAngle(viewYaw - velocityYaw))

    currentSpeed = currentSpeed * -1

    cmd.forwardmove = math.cos(correctedYawRad) * currentSpeed
    cmd.sidemove = math.sin(correctedYawRad) * currentSpeed
end

local function CacheHitboxData(entityIndex)
    -- these hitboxes should be pretty safe no matter what yaw or desync side they're on.
    local hitboxesToScan = { 2, 3, 4, 5 } -- HITBOX_PELVIS, HITBOX_STOMACH, HITBOX_LOWER_CHEST, HITBOX_CHEST
    if not ui.get(menu.ragebot.ragebotHelper.avoidUnsafeHitboxes) then
        table.insert(hitboxesToScan, 6) -- HITBOX_UPPER_CHEST
        table.insert(hitboxesToScan, 0) -- HITBOX_HEAD
    end

    ragebot_helper.enemyData[entityIndex].hitboxes = {}
    for _, hitboxIndex in ipairs(hitboxesToScan) do
        local hitboxPos = vector(entity.hitbox_position(entityIndex, hitboxIndex))
        if hitboxPos.x ~= nil and hitboxPos.y ~= nil and hitboxPos.z ~= nil then
            local relativePosX = hitboxPos.x - ragebot_helper.enemyData[entityIndex].enemyOrigin.x
            local relativePosY = hitboxPos.y - ragebot_helper.enemyData[entityIndex].enemyOrigin.y
            local relativePosZ = hitboxPos.z - ragebot_helper.enemyData[entityIndex].enemyOrigin.z

            table.insert(ragebot_helper.enemyData[entityIndex].hitboxes, { index = hitboxIndex, relativePos = vector(relativePosX, relativePosY, relativePosZ) })
        end
    end
end

local function ScanTarget(currentTarget, cmd)
    local localPlayer = entity.get_local_player()
    if localPlayer == nil then
        return false
    end

    local weaponIndex = entity.get_player_weapon(localPlayer)
    if weaponIndex == nil then
        return false
    end

    local activeWeapon = GetClientEntity(weaponIndex)
    if activeWeapon == nil or not IsWeapon(activeWeapon) then
        return false
    end

    if #currentTarget.hitboxes <= 0 then
        return false
    end

    local eyePosition = vector(client.eye_position())
    for _, hitbox in ipairs(currentTarget.hitboxes) do
        local targetPosition = vector(currentTarget.enemyOrigin.x + hitbox.relativePos.x,
                                        currentTarget.enemyOrigin.y + hitbox.relativePos.y,
                                        currentTarget.enemyOrigin.z + hitbox.relativePos.z)
        local hitEntity, damageDone = client.trace_bullet(localPlayer, eyePosition.x, eyePosition.y, eyePosition.z, targetPosition.x, targetPosition.y, targetPosition.z, true)
        
        local passThrough = true -- just preference, as there's no "continue" keyword :sadge: :c
        if damageDone < MIN_DAMAGE then
            --print("cant hit target")
            passThrough = false
        end

        --print("can hit target, damage: " .. damageDone)
        -- we can hit them(hopefully?) --
        if passThrough then
            local currentHitchance = CalculateHitChance(activeWeapon)
            if currentHitchance < HITCHANCE then
                --print("hitchance too low, quickstopping to improve accuracy")
                QuickStop(cmd, false) -- quickstop before shooting to improve accuracy
                return true -- we shouldn't shoot at our current accuracy, just break the loop
            end

            -- TODO: maybe check for autoscope here and apply it if necessary?

            local targetPitch, targetYaw = eyePosition:to(targetPosition):angles()

            cmd.pitch = targetPitch
            cmd.yaw = targetYaw
            cmd.in_attack = 1

            return true
        end
    end
end

client.set_event_callback("player_hurt", function (event)
    local attackerIndex = client.userid_to_entindex(event.attacker)
    if attackerIndex ~= entity.get_local_player() then
        return
    end

    local victimIndex = client.userid_to_entindex(event.userid)
	ragebot_helper.enemyData[victimIndex].lastSeen = globals.realtime() -- update the last seen time, as we just hit them.
end)

ragebot_helper = {
    setupCount = 0,
    enemyData = {},

    OnRoundStart = function()
        safepoint.OnRoundStart()

        for entityIndex = 1, globals.maxplayers() do
            ragebot_helper.enemyData[entityIndex] = CreateEnemyTable(entityIndex)
        end

        ragebot_helper.setupCount = globals.maxplayers()
    end,

    OnSetupCommand = function(cmd)
        safepoint.OnSetupCommand(cmd)

        if ragebot_helper.setupCount ~= globals.maxplayers() then
            ragebot_helper.OnRoundStart()
            return
        end

        if not ui.get(menu.ragebot.ragebotHelper.enable) or not ui.get(menu.ragebot.ragebotHelper.bind) then
            return
        end

        MAX_TARGET_TIME = ui.get(menu.ragebot.ragebotHelper.maxTargetTime) or 5
        MIN_DAMAGE = ui.get(menu.ragebot.ragebotHelper.minDamage) or 1
        HITCHANCE = ui.get(menu.ragebot.ragebotHelper.hitChance) or 60

        local localPlayer = entity.get_local_player()
        if localPlayer == nil then
            return
        end

        local weaponIndex = entity.get_player_weapon(localPlayer)
        if weaponIndex == nil then
            return
        end

        local activeWeapon = GetClientEntity(weaponIndex)
        if activeWeapon == nil or not IsWeapon(activeWeapon) then
            --print("invalid weapon?")
            return
        end
        
        local itemDefinitionIndex = entity.get_prop(weaponIndex, "m_iItemDefinitionIndex")
        if itemDefinitionIndex == nil then
            return
        end

        itemDefinitionIndex = bit.band(itemDefinitionIndex, 0xFFFF) -- the item definition index is only 16 bits long, but we get it as 32 bit value, map it to 16 bit

        local tickBase = entity.get_prop(localPlayer, "m_nTickBase") or 0
        local currentTime = tickBase * globals.tickinterval()
        local nextAttack = entity.get_prop(localPlayer, "m_flNextAttack") or 0.0
        local nextPrimaryAttack = entity.get_prop(weaponIndex, "m_flNextPrimaryAttack") or 0.0

        local canShoot = currentTime >= nextAttack and currentTime >= nextPrimaryAttack
        if not canShoot then
            return
        end

        local targetList = {}
        local currentTime = globals.realtime()
        for entityIndex = 1, globals.maxplayers() do
            local originX, originY, originZ = entity.get_origin(entityIndex)
            if originX ~= nil and originY ~= nil and originZ ~= nil then
                local currentOrigin = vector(originX, originY, originZ)
                local enemyOrigin = ragebot_helper.enemyData[entityIndex].enemyOrigin
                if (currentOrigin.x ~= enemyOrigin.x or currentOrigin.y ~= enemyOrigin.y or currentOrigin.z ~= enemyOrigin.z) or not entity.is_dormant(entityIndex) then
                    ragebot_helper.enemyData[entityIndex].lastSeen = currentTime
                    ragebot_helper.enemyData[entityIndex].enemyOrigin = currentOrigin
                    ragebot_helper.enemyData[entityIndex].wasSetUp = true
                end

                if not entity.is_dormant(entityIndex) then
                    CacheHitboxData(entityIndex) -- cache hitbox data for non-dormant enemies so we can use it when they go dormant
                end

                if entity.is_dormant(entityIndex) and ragebot_helper.enemyData[entityIndex].wasSetUp and math.abs(currentTime - ragebot_helper.enemyData[entityIndex].lastSeen) <= MAX_TARGET_TIME then -- the enemy updated recently, we can still target them accurately
                    local passThrough = true -- this is just preference, as there's no "continue" keyword :sadge: :c
                    if passThrough and not entity.is_enemy(entityIndex) then
                        passThrough = false
                    end
                    
                    if passThrough and not entity.is_alive(entityIndex) then
                        ragebot_helper.enemyData[entityIndex] = CreateEnemyTable(entityIndex)
                        passThrough = false
                    end

                    local hasImmunity = entity.get_prop(entityIndex, "m_bGunGameImmunity") == 1
                    if passThrough and hasImmunity then
                        ragebot_helper.enemyData[entityIndex] = CreateEnemyTable(entityIndex)
                        passThrough = false
                    end

                    if passThrough then -- they're a valid enemy, we should attempt to target them
                        table.insert(targetList, ragebot_helper.enemyData[entityIndex])
                    end
                end
            end
        end

        if #targetList <= 0 then
            return
        end

        -- sort the target list by most recently seen so we prioritize them over enemies that have been dormant for a while
        table.sort(targetList, function(a, b)
            return a.lastSeen > b.lastSeen
        end)

        for i, currentTarget in ipairs(targetList) do
            local ret = ScanTarget(currentTarget, cmd)
            if (ret) then
                --print("fired a shot at target")
                break -- we fired a shot, no need to continue scanning other targets
            end
        end
    end
}

-- initialize the enemy data table on script load
ragebot_helper.OnRoundStart()
return ragebot_helper