-- holy fucking brainrot, just shoot me please.
local ffi = require("ffi")
local NULL = 0

local SplitString = function(input, sep)
    if sep == nil then
        sep = "%s"
    end
    
    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    
    return t
end

-- we need "jmp ecx" to build our own custom function trampoline
local jmp_ecx = ffi.cast("void(__thiscall*)(void)", client.find_signature("engine.dll", "\xFF\xE1"))
local GetModuleHandleA_t = ffi.typeof("uint32_t(__thiscall*)(uint32_t, const char*)")
local GetProcAddress_t   = ffi.typeof("uint32_t(__thiscall*)(uint32_t, uint32_t, const char*)")

local GetModuleHandleAddr = client.find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\x85\xC0\x74\x0B")
local GetModuleHandleAPtr = ffi.cast("uint32_t**", ffi.cast("uint32_t", GetModuleHandleAddr) + 0x2)[0][0]

local GetProcAddressAddr = client.find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\xA3\xCC\xCC\xCC\xCC\xEB\x05")
local GetProcAddressPtr = ffi.cast("uint32_t**", ffi.cast("uint32_t", GetProcAddressAddr) + 0x2)[0][0]

local GetModuleHandleAFN = ffi.cast(GetModuleHandleA_t, jmp_ecx)
local GetProcAddressFN  = ffi.cast(GetProcAddress_t, jmp_ecx)
local NativeGetModuleHandleA = function(moduleName)
    return GetModuleHandleAFN(GetModuleHandleAPtr, moduleName)
end

local NativeGetProcAddress = function(moduleHandle, functionName)
    return GetProcAddressFN(GetProcAddressPtr, moduleHandle, functionName)
end

local trampolineCache = {}
local BindAddress = function(address, typedef)
    if type(typedef) ~= "string" then
        error("incorrect usage of \"BindAddress\", typedef must be string!", 2)
    end

    local split = SplitString(typedef, '(')
    if not split[1] or not split[2] or not split[3] then
        error("incorrect usage of \"BindAddress\", invalid typedef format -> \"" .. tostring(typedef) .. "\"", 2)
    end

    typedef = split[1] .. "(" .. split[2] .. "(unsigned int, " .. split[3]
    if trampolineCache[typedef] then
        return function(...)
            return trampolineCache[typedef](address, ...)
        end
    end

    local trampoline = ffi.cast(ffi.typeof(typedef), jmp_ecx)
    trampolineCache[typedef] = trampoline
    
    return function(...)
        return trampoline(address, ...)
    end
end

exports = {
    GetModuleHandle = function(moduleName)
        return NativeGetModuleHandleA(moduleName)
    end,

    GetModuleHandleA = function(moduleName)
        return NativeGetModuleHandleA(moduleName)
    end,

    GetProcAddress = function(moduleHandle, functionName)
        return NativeGetProcAddress(moduleHandle, functionName)
    end,

    -- example usage:
    --      local kernel32 = exports.GetExport("kernel32.dll")
    --      local VirtualProtect = kernel32.VirtualProtect("int(__thiscall*)(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect)")
    --      -- now VirtualProtect can be used freely just like in C++.
    GetExport = setmetatable({}, {
        __call = function(self, moduleName)
            local moduleHandle = exports.GetModuleHandleA(moduleName)
            if moduleHandle == NULL then
                return error("failed to find module[\"" .. moduleName .. "\"], is it loaded?")
            end

            local functionCache = {}
            return setmetatable({
                moduleAddress = moduleHandle,
            }, {
                __index = function(self, functionName)
                    local functionKey = moduleName .. "->" .. functionName
                    if functionCache[functionKey] then
                        return function(typedef)
                            return BindAddress(functionCache[functionKey], typedef)
                        end
                    end

                    local functionAddress = exports.GetProcAddress(moduleHandle, functionName)
                    if functionAddress == NULL then
                        return error("failed to find function[\"" .. functionKey .. "\"]")
                    end

                    functionCache[functionKey] = functionAddress
                    return function(typedef)
                        return BindAddress(functionCache[functionKey], typedef)
                    end
                end
            })
        end,
    })
}

return exports