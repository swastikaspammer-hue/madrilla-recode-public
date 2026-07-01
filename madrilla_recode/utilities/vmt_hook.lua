local ffi = require("ffi")
local exports = require("madrilla_recode/utilities/exports")

local PAGE_READWRITE = 0x4

local pointerSize = ffi.sizeof("void*")
local kernel32 = exports.GetExport("kernel32.dll")
local VirtualProtect = kernel32.VirtualProtect("int(__thiscall*)(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect)")

vmt_hook = {
    VMTLibrary = (function()
        local VMTHook = {}
        function VMTHook:new(vmt)
            if not vmt then
                return error("attempted to hook with invalid vtable!", 2)
            end

            -- create vmt hook identity
            local hook = {}
            hook.virtualTable = ffi.cast("void***", vmt)[0]
            hook.hookList = {}

            setmetatable(hook, self)
            self.__index = self

            -- make sure this gets unhooked on script load!
            client.set_event_callback("shutdown", function( )
                return hook:unhook_all()
            end)

            print("created vmt hook target")
            return hook
        end

        -- example usage:
        --      local clientVMT = vmt_hook.VMTLibrary:new(get_interface("client.dll", "VClient018"))
        --      clientVMT:hook("Client.FrameStageNotify", 37,           -- "hook name", index,
        --                { "void(__stdcall*)(int stage)", nil },       -- { detour typedef, original typedef },
        --                    hkFrameStageNotify)                       -- detour function
        --      
        --      calling original: clientVMT["Client.FrameStageNotify"](stage)
        function VMTHook:hook(name, index, typedef, detour)
            print("attempting to hook function")
            if type(typedef) ~= "table" then
                error("attempted to hook \"" .. name .. "\" with invalid typedef(table expected)")
            end

            for _, func in pairs(self.hookList) do
                if func.functionIndex == index then
                    return error("attempted to hook already hooked function!", 2)
                end
            end

            local detourCallback = typedef[1] or nil
            local originalCallback = typedef[2] or detourCallback

            local protectionBackup = ffi.new("unsigned long[1]")

            local originalFunction = self.virtualTable[index]
            local callback = ffi.cast(originalCallback, originalFunction)
            local callback2 = ffi.cast(detourCallback, detour)
            table.insert(self.hookList, {
                functionName = name,
                functionIndex = index,
                originalAddress = originalFunction,
                originalCallback = callback,
                functionCallback = callback2
            })

            VirtualProtect(ffi.cast("void*", self.virtualTable + index), pointerSize, PAGE_READWRITE, protectionBackup)
            self.virtualTable[index] = ffi.cast("void*", callback2)
            VirtualProtect(ffi.cast("void*", self.virtualTable + index), pointerSize, protectionBackup[0], protectionBackup)

            self[name] = callback
            print("successfully hooked \"" .. name .. "\"")
            return true
        end

        function VMTHook:unhook_all()
            for i, func in pairs(self.hookList) do
                local protectionBackup = ffi.new("unsigned long[1]")

                VirtualProtect(ffi.cast('void*', self.virtualTable + func.functionIndex), pointerSize, PAGE_READWRITE, protectionBackup)
                self.virtualTable[func.functionIndex] = func.originalAddress
                VirtualProtect(ffi.cast('void*', self.virtualTable + func.functionIndex), pointerSize, protectionBackup[0], protectionBackup)
                print("successfully unhooked \"" .. func.functionName .. "\"")
            end

            self.hookList = {} -- clear out the hooked list
            return true
        end

        return VMTHook
    end)()
}

return vmt_hook