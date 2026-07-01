local menu = require("madrilla_recode/menu")
local particle_weather = require("madrilla_recode/particle_rain")
local vmt_hook = require("madrilla_recode/utilities/vmt_hook")
local ffi = require("ffi")

-- we have to do shit like this because of issues with ffi overuse
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 200)

-- NOTE:
--      we should probably look into a better way of executing such engine level code
--      for example we could use pcall or xpcall to catch any exceptions that occurr

--PRECIPITATION_TYPE_NONE = -1
--PRECIPITATION_TYPE_RAIN = 0
--PRECIPITATION_TYPE_SNOW = 1
--PRECIPITATION_TYPE_PARTICLERAIN = 4
--PRECIPITATION_TYPE_PARTICLEASH = 5
--PRECIPITATION_TYPE_PARTICLESNOW = 7

ffi.cdef([[
    typedef struct {
        float x, y, z;
    } Vector3;

    typedef void*(*CreateClientClassFN)(int entnum, int serialNum);
    typedef void*(*CreateEventFN)();
    typedef struct {
        CreateClientClassFN	m_pCreate;
        CreateEventFN		m_pCreateEvent;
        char*			    m_pNetworkName;
        void*			    m_pRecvTable;
        void*		        m_pNext;
        int					m_ClassID;
    } ClientClass;

    typedef struct {
        unsigned short solidCountPacked; // solidCount first 15 bits, isPacked last bit
        unsigned short descSize;
        void** solids;
        char* pKeyValues;
        void* pUserData;
    } vcollide_t;
]])

local MAX_EDICTS = 2048
local WeatherUtils = {}

local colliderBufferSize = 546
local colliderBuffer = ffi.new("uint8_t[546]", {
    0xB8, 0x01, 0x00, 0x00, 0x56, 0x50, 0x48, 0x59, 0x00, 0x01, 0x00, 0x00, 0x9C, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00,
    0x20, 0x16, 0x6A, 0xC1, 0xC0, 0x0E, 0x1C, 0xC1, 0x80, 0x13, 0xD0, 0x3F, 0xE2, 0x26, 0x11, 0x48,
    0xE2, 0x26, 0x11, 0x48, 0xE2, 0x26, 0x11, 0x48, 0x72, 0x4E, 0x08, 0x44, 0xD1, 0x9C, 0x01, 0x00,
    0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x49, 0x56, 0x50, 0x53,
    0xD0, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x04, 0x15, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00,
    0x00, 0x90, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x01, 0x00, 0x03, 0x00, 0x02, 0x00, 0x12, 0x00,
    0x01, 0x80, 0x00, 0x00, 0x02, 0x00, 0xFD, 0x7F, 0x01, 0x00, 0x15, 0x00, 0x03, 0x00, 0x28, 0x00,
    0x02, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0F, 0x00, 0x01, 0x00, 0xF6, 0x7F,
    0x03, 0xA0, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x05, 0x00, 0x15, 0x00, 0x04, 0x00, 0xFA, 0x7F,
    0x04, 0x70, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x06, 0x00, 0x13, 0x00, 0x05, 0x00, 0xFA, 0x7F,
    0x05, 0x60, 0x00, 0x00, 0x00, 0x00, 0xEE, 0x7F, 0x02, 0x00, 0x18, 0x00, 0x06, 0x00, 0xFA, 0x7F,
    0x06, 0x50, 0x00, 0x00, 0x01, 0x00, 0xF1, 0x7F, 0x04, 0x00, 0x03, 0x00, 0x03, 0x00, 0xEB, 0x7F,
    0x07, 0x40, 0x00, 0x00, 0x03, 0x00, 0xFD, 0x7F, 0x04, 0x00, 0x04, 0x00, 0x07, 0x00, 0x0C, 0x00,
    0x08, 0x10, 0x00, 0x00, 0x05, 0x00, 0x06, 0x00, 0x07, 0x00, 0xFC, 0x7F, 0x04, 0x00, 0xEB, 0x7F,
    0x09, 0x00, 0x00, 0x00, 0x05, 0x00, 0xED, 0x7F, 0x06, 0x00, 0x03, 0x00, 0x07, 0x00, 0xFA, 0x7F,
    0x0A, 0x30, 0x00, 0x00, 0x07, 0x00, 0xFD, 0x7F, 0x06, 0x00, 0x03, 0x00, 0x03, 0x00, 0xF4, 0x7F,
    0x0B, 0x20, 0x00, 0x00, 0x03, 0x00, 0xFD, 0x7F, 0x06, 0x00, 0xE8, 0x7F, 0x02, 0x00, 0xD8, 0x7F,
    0x46, 0xAD, 0x9D, 0xC3, 0x1F, 0x0D, 0x9C, 0xC3, 0x80, 0xAE, 0xAA, 0x43, 0x00, 0x00, 0x00, 0x00,
    0x46, 0xAD, 0x9D, 0xC3, 0x33, 0x4C, 0x92, 0x43, 0x80, 0xAE, 0xAA, 0x43, 0x00, 0x00, 0x00, 0x00,
    0x46, 0xAD, 0x9D, 0xC3, 0x1F, 0x0D, 0x9C, 0xC3, 0x59, 0x0E, 0xA9, 0xC3, 0x00, 0x00, 0x00, 0x00,
    0x46, 0xAD, 0x9D, 0xC3, 0x33, 0x4C, 0x92, 0x43, 0x59, 0x0E, 0xA9, 0xC3, 0x00, 0x00, 0x00, 0x00,
    0xE4, 0x0B, 0x8F, 0x43, 0x33, 0x4C, 0x92, 0x43, 0x80, 0xAE, 0xAA, 0x43, 0x00, 0x00, 0x00, 0x00,
    0xE4, 0x0B, 0x8F, 0x43, 0x1F, 0x0D, 0x9C, 0xC3, 0x80, 0xAE, 0xAA, 0x43, 0x00, 0x00, 0x00, 0x00,
    0xE4, 0x0B, 0x8F, 0x43, 0x1F, 0x0D, 0x9C, 0xC3, 0x59, 0x0E, 0xA9, 0xC3, 0x00, 0x00, 0x00, 0x00,
    0xE4, 0x0B, 0x8F, 0x43, 0x33, 0x4C, 0x92, 0x43, 0x59, 0x0E, 0xA9, 0xC3, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xB0, 0xFE, 0xFF, 0xFF, 0x20, 0x16, 0x6A, 0xC1, 0xC0, 0x0E, 0x1C, 0xC1,
    0x80, 0x13, 0xD0, 0x3F, 0x72, 0x4E, 0x08, 0x44, 0x8A, 0x8B, 0x9C, 0x00, 0x73, 0x6F, 0x6C, 0x69,
    0x64, 0x20, 0x7B, 0x0A, 0x22, 0x69, 0x6E, 0x64, 0x65, 0x78, 0x22, 0x20, 0x22, 0x30, 0x22, 0x0A,
    0x22, 0x6D, 0x61, 0x73, 0x73, 0x22, 0x20, 0x22, 0x35, 0x30, 0x30, 0x30, 0x30, 0x2E, 0x30, 0x30,
    0x30, 0x30, 0x30, 0x30, 0x22, 0x0A, 0x22, 0x73, 0x75, 0x72, 0x66, 0x61, 0x63, 0x65, 0x70, 0x72,
    0x6F, 0x70, 0x22, 0x20, 0x22, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74, 0x22, 0x0A, 0x22, 0x76,
    0x6F, 0x6C, 0x75, 0x6D, 0x65, 0x22, 0x20, 0x22, 0x31, 0x35, 0x30, 0x38, 0x30, 0x32, 0x33, 0x32,
    0x30, 0x35, 0x38, 0x38, 0x38, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x22, 0x0A, 0x7D,
    0x0A, 0x00
})

local _cache = {
    interfaces = {}
}

local interfacePtr = ffi.typeof('void***')
local function get_interface(module, name)
    local key = module .. ":" .. name
    if _cache.interfaces[key] then
        return _cache.interfaces[key]
    end

    local raw = client.create_interface(module, name)
    if not raw then
        return nil
    end

    local casted = ffi.cast(interfacePtr, raw)
    _cache.interfaces[key] = casted

    return casted
end

local ctype_cache = {}
local function get_ctype(type_str)
    local ct = ctype_cache[type_str]
    if ct then return ct end

    ct = ffi.typeof(type_str)
    ctype_cache[type_str] = ct

    return ct
end

local function get_vfunc(vtable, index, ctype)
    return ffi.cast(get_ctype(ctype), vtable[index])
end

function WeatherUtils:GetPhysicsCollision()
    local physicsCollisionInterfaceRaw = get_interface("vphysics.dll", "VPhysicsCollision007")
    if not physicsCollisionInterfaceRaw then 
        return nil 
    end

    return physicsCollisionInterfaceRaw
end

function WeatherUtils:GetAllClientClasses()
    local clientInterfaceRaw = get_interface("client.dll", "VClient018")
    if not clientInterfaceRaw then 
        return nil
    end

    local clientVTable = clientInterfaceRaw[0]

    local GetAllClasses = get_vfunc(clientVTable, 8, "ClientClass*(__thiscall*)(void*)")
    return GetAllClasses(clientInterfaceRaw)
end

function WeatherUtils:GetPrecipitationClass()
    local currentClass = WeatherUtils:GetAllClientClasses()
    if not currentClass then
        return nil
    end

    while currentClass and currentClass ~= ffi.NULL do
        if currentClass.m_ClassID == 138 then
            return currentClass
        end

        if not currentClass.m_pNext or currentClass.m_pNext == ffi.NULL then
            break
        end

        currentClass = ffi.cast("ClientClass*", currentClass.m_pNext)
    end
    
    return nil
end

function WeatherUtils:GetNetworkable(entityIndex)
    local entityListInterfaceRaw = get_interface("client.dll", "VClientEntityList003")
    if not entityListInterfaceRaw then 
        return nil 
    end

    local entityList = entityListInterfaceRaw
    local entityListVTable = entityList[0]

    local GetClientNetworkable = get_vfunc(entityListVTable, 0, "void*(__thiscall*)(void*, int)")
    return GetClientNetworkable(entityList, entityIndex)
end

local weatherData = {
    uniqueModelIndex = (4096 - 1), -- used for matching the model index
    hasInitialized = false,
    precipitationClass = nil,

    weatherEntity = nil,
    networkableEntity = nil,
    weatherEntityIndex = -1,
    weatherType = -1,

    vCollide = ffi.new("vcollide_t[1]"),
    vCollideInit = false
}

local function IsTypeActive(precipType)
    if precipType == -1 and weatherData.weatherEntity == nil then
        return true
    end

    if weatherData.weatherEntity == nil then
        return false
    end

    if weatherData.weatherType ~= precipType then
        return false
    end

    return true
end

local function UnloadEntity()
    if not weatherData.hasInitialized then
        return
    end

    if weatherData.weatherEntity == nil then
        return
    end

    local physicsCollision = WeatherUtils:GetPhysicsCollision()
    if physicsCollision ~= nil and physicsCollision ~= ffi.NULL then
        local physicsCollisionVTable = physicsCollision[0]
        local VCollideUnload = get_vfunc(physicsCollisionVTable, 37, "void(__thiscall*)(void*, vcollide_t*)")
        
        if weatherData.vCollideInit then
            VCollideUnload(physicsCollision, weatherData.vCollide)
            weatherData.vCollideInit = false
        end
    end

    print("preparing unload")
    entity.set_prop(weatherData.weatherEntityIndex, "m_nModelIndex", 0) -- prevent any lingering entity from matching our vcollide data

    local weatherEntityAddr = tonumber(ffi.cast("uintptr_t", weatherData.weatherEntity))
    --local m_bDormant = ffi.cast("bool*", (weatherEntityAddr + 0xED))

    --m_bDormant[0] = true

    local networkable = ffi.cast("void***", weatherData.weatherEntity)
    local networkableVTable = networkable[0]

    local GetIClientUnknown = get_vfunc(networkableVTable, 0, "void***(__thiscall*)(void*)")
    local NotifyShouldTransmit = get_vfunc(networkableVTable, 3, "void(__thiscall*)(void*, int)")

    --NotifyShouldTransmit(networkable, 1)

    local clientUnknown = GetIClientUnknown(networkable)
    if clientUnknown and clientUnknown ~= ffi.NULL then
        local clientUnknownVTable = clientUnknown[0]
        local GetClientThinkable = get_vfunc(clientUnknownVTable, 8, "void***(__thiscall*)(void*)")

        local clientThinkable = GetClientThinkable(clientUnknown)
        if clientThinkable and clientThinkable ~= ffi.NULL then
            local clientThinkableVTable = clientThinkable[0]
            local Release = get_vfunc(clientThinkableVTable, 4, "void(__thiscall*)(void*)")
            Release(clientThinkable)
        end
    end

    weatherData.hasInitialized = false
    print("finished unload")
end

local function UpdateWeatherBounds()
    if not weatherData.weatherEntity then
        return
    end

    --print("preparing update of weather bounds...")
    local networkable = ffi.cast("void***", weatherData.weatherEntity)
    local networkableVTable = networkable[0]
    local GetIClientUnknown = get_vfunc(networkableVTable, 0, "void***(__thiscall*)(void*)")

    local clientUnknown = GetIClientUnknown(networkable)
    if clientUnknown and clientUnknown ~= ffi.NULL then
        local clientUnknownVTable = clientUnknown[0]
        local GetCollideable = get_vfunc(clientUnknownVTable, 3, "void***(__thiscall*)(void*)")

        local collideable = GetCollideable(clientUnknown)
        if collideable and collideable ~= ffi.NULL then
            local collideableVTable = collideable[0]

            local mins = get_vfunc(collideableVTable, 1, "Vector3*(__thiscall*)(void*)")(collideable)
            local maxs = get_vfunc(collideableVTable, 2, "Vector3*(__thiscall*)(void*)")(collideable)

            if mins and maxs and mins ~= ffi.NULL and maxs ~= ffi.NULL then
                mins.x, mins.y, mins.z = -2048, -2048, -2048
                maxs.x, maxs.y, maxs.z = 2048, 2048, 2048
            end
        end
    end

    --print("finished updating weather bounds")
end

local function ApplyWeatherEffect(precipType)
    if precipType == -1 then
        return
    end

    if not weatherData.precipitationClass.m_pCreate then
        return
    end

    weatherData.networkableEntity = weatherData.precipitationClass.m_pCreate(MAX_EDICTS - 1, 0)
    if not weatherData.networkableEntity or weatherData.networkableEntity == ffi.NULL then
        print("failed to create precipitation entity!\n")
        return
    end

    weatherData.weatherEntityIndex = MAX_EDICTS - 1
    weatherData.weatherEntity = WeatherUtils:GetNetworkable(weatherData.weatherEntityIndex)
    if not weatherData.weatherEntity or weatherData.weatherEntity == ffi.NULL then
        print("invalid weather networkable!")
        return
    end

    weatherData.weatherType = precipType
    weatherData.vCollideInit = false
    ffi.fill(weatherData.vCollide[0], ffi.sizeof(weatherData.vCollide[0]))

    local physicsCollision = WeatherUtils:GetPhysicsCollision()
    if physicsCollision ~= nil and physicsCollision ~= ffi.NULL then
        local physicsCollisionVTable = physicsCollision[0]
        local VCollideLoad = get_vfunc(physicsCollisionVTable, 36, "void(__thiscall*)(void*, vcollide_t*, int, const char*, int, bool)")
        
        if not weatherData.vCollideInit then
            VCollideLoad(physicsCollision, weatherData.vCollide, 1, ffi.cast("const char*", colliderBuffer), colliderBufferSize, false)
            weatherData.vCollideInit = true

            print("loaded vcollide data")
        end
    end

    local networkable = ffi.cast("void***", weatherData.weatherEntity)
    local networkableVTable = networkable[0]
    local GetIClientUnknown = get_vfunc(networkableVTable, 0, "void***(__thiscall*)(void*)")
    local PreDataUpdate = get_vfunc(networkableVTable, 6, "void(__thiscall*)(void*, int)")
    local OnPreDataChanged = get_vfunc(networkableVTable, 4, "void(__thiscall*)(void*, int)")
    local OnDataChanged = get_vfunc(networkableVTable, 5, "void(__thiscall*)(void*, int)")
    local PostDataUpdate = get_vfunc(networkableVTable, 7, "void(__thiscall*)(void*, int)")
    local NotifyShouldTransmit = get_vfunc(networkableVTable, 3, "void(__thiscall*)(void*, int)")

    entity.set_prop(weatherData.weatherEntityIndex, "m_nPrecipType", weatherData.weatherType)
    entity.set_prop(weatherData.weatherEntityIndex, "m_nModelIndex", weatherData.uniqueModelIndex)

    local weatherEntityAddr = tonumber(ffi.cast("uintptr_t", weatherData.weatherEntity))
    local m_bParticlePrecipInitialized = ffi.cast("bool*", (weatherEntityAddr + 0xAA1))
    local m_bDormant = ffi.cast("bool*", (weatherEntityAddr + 0xED))

    m_bParticlePrecipInitialized[0] = false -- force particle reinitialization
    m_bDormant[0] = false
    
    -- another requirement might be setting alpha modulation from the alpha property(GetClientAlphaProperty()->SetAlphaModulation)
    local clientUnknown = GetIClientUnknown(networkable)
    if clientUnknown and clientUnknown ~= ffi.NULL then
        local clientUnknownVTable = clientUnknown[0]
        local GetClientAlphaProperty = get_vfunc(clientUnknownVTable, 9, "void***(__thiscall*)(void*)")

        local clientAlphaProperty = GetClientAlphaProperty(clientUnknown)
        if clientAlphaProperty and clientAlphaProperty ~= ffi.NULL then
            local clientAlphaPropertyVTable = clientAlphaProperty[0]
            local SetAlphaModulation = get_vfunc(clientAlphaPropertyVTable, 1, "void(__thiscall*)(void*, unsigned char)")

            SetAlphaModulation(clientAlphaProperty, 255)
            print("set precipitation alpha")
        end
    end

    UpdateWeatherBounds()

    PreDataUpdate(networkable, 0)
    OnPreDataChanged(networkable, 0)
    OnDataChanged(networkable, 0)
    PostDataUpdate(networkable, 0)

    --NotifyShouldTransmit(networkable, 0) -- force dormancy to false

    weatherData.hasInitialized = true

    print("finished initializing weather")
end

local function CleanUp()
    if weatherData.weatherEntity == nil then
        return
    end

    UnloadEntity()

    weatherData.weatherEntity = nil
    weatherData.weatherEntityIndex = -1
    weatherData.weatherType = -1
end

local function Run()
    if weatherData.precipitationClass == nil then
        weatherData.precipitationClass = WeatherUtils:GetPrecipitationClass()
        if weatherData.precipitationClass == nil then
            return
        end
    end

    local precipType = ui.get(menu.visuals.weather.precipitationType)
    local precipitationType = -1

    if precipType == "rain" then
        precipitationType = 0
    elseif precipType == "snow" then
        precipitationType = 1
    elseif precipType == "particle rain" or precipType == "particle snow" or precipType == "particle ash" then
        precipitationType = -1
    elseif precipType == "none" then
        precipitationType = -1
    else
        print("UNHANDLED INDEX DURING WEATHER HANDLING!")
        return
    end

    if IsTypeActive(precipitationType) then
        if precipitationType ~= -1 then
            UpdateWeatherBounds()
        end
        return -- don't set-up precipitation multiple times for one type
    end

    CleanUp()
    if precipitationType ~= -1 then
        ApplyWeatherEffect(precipitationType)
    end
end

local FRAME_RENDER_START = 5

local modelInfoVMT = vmt_hook.VMTLibrary:new(get_interface("engine.dll", "VModelInfoClient004"))
local clientVMT = vmt_hook.VMTLibrary:new(get_interface("client.dll", "VClient018"))
function hkFrameStageNotify(stage)
    --client.color_log(255, 255, 255, "running stage: " .. stage)
    if stage == FRAME_RENDER_START then
        if not ui.get(menu.visuals.weather.enable) or ui.get(menu.visuals.weather.precipitationType) == "none" then
            CleanUp()
        else
            Run()
        end
    end

    return clientVMT["Client.FrameStageNotify"](stage)
end

function hkGetVCollide(ecx, edx, modelIndex)
    local ret = modelInfoVMT["ModelInfoClient.GetVCollide"](ecx, modelIndex)
    if modelIndex ~= weatherData.uniqueModelIndex or not weatherData.vCollideInit then
        return ret
    end

    client.color_log(255, 255, 255, "attempted to return vCollide!")
    return weatherData.vCollide
end

clientVMT:hook("Client.FrameStageNotify", 37,
                    { "void(__stdcall*)(int stage)", nil },
                        hkFrameStageNotify)

modelInfoVMT:hook("ModelInfoClient.GetVCollide", 6,
                    { "vcollide_t*(__fastcall*)(void* _this, void* edx, int modelIndex)", "vcollide_t*(__thiscall*)(void* _this, int modelIndex)" },
                        hkGetVCollide)

client.set_event_callback("paint", function()
    if not ui.get(menu.visuals.weather.enable) then return end
    local pType = ui.get(menu.visuals.weather.precipitationType)
    if string.match(pType, "particle") then
        particle_weather.process(pType)
    end
end)

precipitation = {    
    OnNetUpdateEnd = function()

    end,

    OnRoundStart = function()
        if not ui.get(menu.visuals.weather.enable) or ui.get(menu.visuals.weather.precipitationType) == "none" then
            return
        end

        UpdateWeatherBounds()
    end
}

return precipitation