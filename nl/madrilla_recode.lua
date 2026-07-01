local modules = {
    ["neverlose/clipboard"] = function(require)
        local char_array = ffi.typeof 'char[?]'

        local native_GetClipboardTextCount = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 7, 'int(__thiscall*)(void*)')
        local native_SetClipboardText = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 9, 'void(__thiscall*)(void*, const char*, int)')
        local native_GetClipboardText = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 11, 'int(__thiscall*)(void*, int, const char*, int)')

        local function get()
            local len = native_GetClipboardTextCount()
            if len > 0 then
                local char_arr = char_array(len)
                native_GetClipboardText(0, char_arr, len)
                return ffi.string(char_arr, len - 1)
            end
        end

        local function set(...)
            local text = tostring(table.concat({ ... }))
            native_SetClipboardText(text, string.len(text))
        end

        return {
            set = set,
            get = get
        }
    end,

    ["neverlose/base64"] = function(require)
        local shl, shr, band = bit.lshift, bit.rshift, bit.band
        local char, byte, gsub, sub, format, concat, tostring, error, pairs = string.char, string.byte, string.gsub, string.sub, string.format, table.concat, tostring, error, pairs

        local extract = function(v, from, width)
            return band(shr(v, from), shl(1, width) - 1)
        end

        local function makeencoder(alphabet)
            local encoder, decoder = {}, {}
            for i=1, 65 do
                local chr = byte(sub(alphabet, i, i)) or 32
                if decoder[chr] ~= nil then
                    error('invalid alphabet: duplicate character ' .. tostring(chr), 3)
                end
                encoder[i-1] = chr
                decoder[chr] = i-1
            end
            return encoder, decoder
        end

        local encoders, decoders = {}, {}

        encoders['base64'], decoders['base64'] = makeencoder('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=')
        encoders['base64url'], decoders['base64url'] = makeencoder('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_')

        local alphabet_mt = {
            __index = function(tbl, key)
                if type(key) == 'string' and (key:len() == 64 or key:len() == 65) then
                    encoders[key], decoders[key] = makeencoder(key)
                    return tbl[key]
                end
            end
        }

        setmetatable(encoders, alphabet_mt)
        setmetatable(decoders, alphabet_mt)

        local function encode(str, encoder)
            encoder = encoders[encoder or 'base64'] or error('invalid alphabet specified', 2)
            str = tostring(str)
            local t, k, n = {}, 1, #str
            local lastn = n % 3
            local cache = {}

            for i = 1, n-lastn, 3 do
                local a, b, c = byte(str, i, i+2)
                local v = a*0x10000 + b*0x100 + c
                local s = cache[v]
                if not s then
                    s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
                    cache[v] = s
                end
                t[k] = s
                k = k + 1
            end

            if lastn == 2 then
                local a, b = byte(str, n-1, n)
                local v = a*0x10000 + b*0x100
                t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[64])
            elseif lastn == 1 then
                local v = byte(str, n)*0x10000
                t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[64], encoder[64])
            end
            return concat(t)
        end

        local function decode(b64, decoder)
            decoder = decoders[decoder or 'base64'] or error('invalid alphabet specified', 2)
            local pattern = '[^%w%+%/%=]'
            b64 = gsub(tostring(b64), pattern, '')

            local cache = {}
            local t, k = {}, 1
            local n = #b64
            local padding = sub(b64, -2) == '==' and 2 or sub(b64, -1) == '=' and 1 or 0

            for i = 1, padding > 0 and n-4 or n, 4 do
                local a, b, c, d = byte(b64, i, i+3)
                local v0 = a*0x1000000 + b*0x10000 + c*0x100 + d
                local s = cache[v0]
                if not s then
                    local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
                    s = char(extract(v,16,8), extract(v,8,8), extract(v,0,8))
                    cache[v0] = s
                end
                t[k] = s
                k = k + 1
            end

            if padding == 1 then
                local a, b, c = byte(b64, n-3, n-1)
                local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
                t[k] = char(extract(v,16,8), extract(v,8,8))
            elseif padding == 2 then
                local a, b = byte(b64, n-3, n-2)
                local v = decoder[a]*0x40000 + decoder[b]*0x1000
                t[k] = char(extract(v,16,8))
            end
            return concat(t)
        end

        return {
            encode = encode,
            decode = decode
        }
    end,
    ["neverlose/pui"] = function(require)
        -- perfect user interface
        ----- neverlose

        --------------------------------------------------------------------------------
        -- #region :: Header

        --
        -- #region : Definitions

        local _PUIVERSION = 1

        --#region: localization

        local print, require, print_raw, print_error, color, next, vector, type, pairs, ipairs, getmetatable, setmetatable, assert, rawget, rawset, rawequal, rawlen, unpack, select, tonumber, tostring, error, pcall, xpcall, print_dev =
              print, require, print_raw, print_error, color, next, vector, type, pairs, ipairs, getmetatable, setmetatable, assert, rawget, rawset, rawequal, rawlen, unpack, select, tonumber, tostring, error, pcall, xpcall, print_dev

        local C = function (t) local c = {} for k, v in next, t do c[k] = v end return c end

        local table, math, string, ui = C(table), C(math), C(string), C(ui)

        --#endregion

        --#region: global table

        table.find = function (t, j)  for k, v in next, t do if v == j then return k end end return false  end
        table.ifind = function (t, j)  for i = 1, table.maxn(t) do if t[i] == j then return i end end  end
        table.ihas = function (t, ...) local arg = {...} for i = 1, table.maxn(t) do for j = 1, #arg do if t[i] == arg[j] then return true end end end return false end

        table.filter = function (t)  local res = {} for i = 1, table.maxn(t) do if t[i] ~= nil then res[#res+1] = t[i] end end return res  end
        table.append = function (t, ...)  for i, v in ipairs{...} do table.insert(t, v) end  end
        table.appendf = function (t, ...)  local arg = {...} for i = 1, table.maxn(arg) do local v = arg[i] if v ~= nil then t[#t+1] = v end end  end
        table.range = function (t, i, j)  local r = {} for l = i or 0, j or #t do r[#r+1] = t[l] end return r  end
        table.copy = function (o) if type(o) ~= "table" then return o end local r = {} for k, v in next, o do r[table.copy(k)] = table.copy(v) end return r end

        math.round = function (value)  return math.floor (value + 0.5)  end
        math.lerp = function (a, b, w)  return a + (b - a) * w  end

        local ternary = function (c, a, b)  if c then return a else return b end  end
        local aserror = function (a, msg, level) if not a then error(msg, level and level + 1 or 4) end end
        local contend = function (func, callback, ...)
            local t = { pcall(func, ...) }
            if not t[1] then if type(callback) == "function" then return callback(t[2]) else error(t[2], callback or 2) end end
            return unpack(t, 2)
        end

        local debug = setmetatable({
            warning = function (...)
                print_raw("[\ae09334ffpui", "] ", ...)
            end,
            error = function (...)
                print_raw("[\aef6060ffpui", "] ", ...)
                cvar.play:call("ui/menu_invalid.wav")
                error()
            end
        }, {
            __call = function (self, ...)
                if _IS_MARKET then return end
                print_raw("\a74a6a9ffpui - ", ...)
                print_dev(...)
            end
        })

        --#endregion

        --#region: directory tools

        local dirs = {
            execute = function (t, path, func)
                local p, k for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if t == nil then return end
                end
                if p[k] ~= nil then func(p[k], p) end
            end,
            replace = function (t, path, value)
                local p, k for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if t == nil then return end
                end
                p[k] = value
            end,
            find = function (t, path)
                local p, k
                for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if type(t) ~= "table" then break end
                end
                return p[k]
            end,
        }

        dirs.pave = function (t, place, path)
            local p = t for i, v in ipairs(path) do
                if type(p[v]) == "table" then p = p[v]
                else p[v] = (i < #path) and {} or place  p = p[v]  end
            end return t
        end

        dirs.extract = function (t, path)
            if not path or #path == 0 then return t end
            local j = dirs.find(t, path)
            return dirs.pave({}, j, path)
        end

        --#endregion

        local pui, pui_mt, methods_mt = {}, {}, { element = {}, group = {} }
        local tools, elemence = {}, {}
        local config, is_setup = {}, false

        local stringlist

        --
        local dpi = render.get_scale(1)

        -- #endregion
        --

        --
        -- #region : Elements

        --#region: definitions

        local elements = {
            switch					= { type = "boolean",	arg = 2 },
            slider					= { type = "number",	arg = 6 },
            combo					= { type = "string",	arg = 2, variable = true },
            language				= { type = "string",	arg = 2, variable = true },
            selectable				= { type = "table",		arg = 2, variable = true },
            button					= { type = "function",	arg = 3, unsavable = true },
            list					= { type = "number",	arg = 2, variable = true },
            listable				= { type = "table",		arg = 2, variable = true },
            label					= { type = "string",	arg = 1, unsavable = true },
            texture					= { type = "userdata",	arg = 5, unsavable = true },
            image					= { type = "userdata",	arg = 5, unsavable = true },
            hotkey					= { type = "number",	arg = 2 },
            input					= { type = "string",	arg = 2 },
            textbox					= { type = "string",	arg = 2 },
            color_picker			= { type = "userdata",	arg = 2 },
            value					= { type = "any",		arg = 2 },
            ["sol.lua::LuaVarClr"]	= { type = "userdata",	arg = 2 },
            [""]					= { type = "any",		arg = 2 },
        }

        --#endregion

        --#region: methods parsing

        local __mt = {
            group = {}, wrp_group = {},
            element = {}, wrp_element = {},
            events = {}
        } do
            local element = ui.find("Miscellaneous", "Main", "Movement", "Air Duck")
            local group = element:parent()

            local element_keys, group_keys = { "__eq", "__index", "__name", "__type", "color_picker", "create", "disabled", "export", "get", "get_override", "id", "import", "key", "list", "name", "new", "override", "parent", "reset", "set", "set_callback", "tooltip", "type", "unset_callback", "update", "visibility",
            }, { "__eq", "__index", "__name", "__type", "button", "color_picker", "combo", "create", "disabled", "export", "hotkey", "import", "input", "label", "list", "listable", "name", "parent", "selectable", "slider", "switch", "texture", "value", "visibility", }

            for i = 1, #element_keys do
                local k = element_keys[i]
                local v = element[k]
                __mt.element[k], __mt.wrp_element[k] = v, function (self, ...) return v(self.ref, ...) end
            end

            for i = 1, #group_keys do
                local k = group_keys[i]
                local v = group[k]
                __mt.group[k], __mt.wrp_group[k] = v, function (self, ...) return v(self.ref, ...) end
            end
        end

        --#endregion

        --#region: weak tables

        local icons = setmetatable({}, {
            __mode = "k",
            __index = function (self, name)
                local icon = ui.get_icon(name)
                if #icon == 0 then
                    debug.warning(icon, ("<%s> icon not found"):format(name))
                    return "[?]"
                end
                self[name] = icon
                return self[name]
            end
        })

        local groups = setmetatable({}, {
            __mode = "k",
            __index = function (self, raw)
                local key, group
                local kind = type(raw)

                if kind == "table" then
                    if raw.__name == "pui::group" then return raw.ref end
                    for i = 1, #raw do  raw[i] = tools.format(raw[i])  end

                    key, group = raw[1] .."-".. (raw[2] or ""), ui.create(unpack(raw))
                elseif kind == "userdata" and raw.__name == "sol.lua::LuaGroup" then
                    key, group = tostring(raw), raw
                else
                    raw = tools.format(raw)
                    key, group = tostring(raw), ui.create(raw)
                end

                self[key] = group

                return self[key]
            end
        })

        --#endregion

        -- #endregion
        --

        --
        -- #region : Utils

        --#region: tools

        do
            local fmethods = {
                gradients = function (col, text)
                    local colors = {}; for w in string.gmatch(col, "\b%x+") do
                        colors[#colors+1] = color(string.sub(w, 2))
                    end
                    if #colors > 0 then return tools.gradient(text, colors) end
                end,
                colors = function (col)
                    return pui.colors[col] and ("\a".. pui.colors[col]:to_hex()) or "\aDEFAULT"
                end,
                macros = setmetatable({}, {
                    __newindex = function (self, key, value)
                        local kv = type(value)

                        if kv == "string" then
                        elseif kv == "userdata" and value.__name == "sol.ImColor" then
                            value = "\a" .. value:to_hex()
                        else
                            value = tostring(value)
                        end

                        rawset(self, tostring(key), value)
                    end,
                    __index = function (self, key) return rawget(self, key) end
                })
            }

            pui.macros = fmethods.macros

            tools.format = function (s)
                if type(s) == "string" then
                    if stringlist then stringlist[s] = true end
                    s = string.gsub(s, "\b<(.-)>", fmethods.macros)
                    s = string.gsub(s, "[\v\r]", { ["\v"] = "\a{Link Active}", ["\r"] = "\aDEFAULT" })
                    s = string.gsub(s, "([\b%x]-)%[(.-)%]", fmethods.gradients)
                    s = string.gsub(s, "\a%[(.-)%]", fmethods.colors)
                    s = string.gsub(s, "\f<(.-)>", icons)
                end

                return s
            end

            tools.gradient = function (text, colors)
                local symbols, length = {}, #(text:gsub(".[\128-\191]*", "a"))
                local s = 1 / (#colors - 1)

                local i = 0
                for letter in string.gmatch(text, ".[\128-\191]*") do
                    i = i + 1

                    local weight = i / length
                    local cw = weight / s
                    local j = math.ceil(cw)
                    local w = (cw / j)
                    local L, R = colors[j], colors[j+1]

                    local r = L.r + (R.r - L.r) * w
                    local g = L.g + (R.g - L.g) * w
                    local b = L.b + (R.b - L.b) * w
                    local a = L.a + (R.a - L.a) * w

                    symbols[#symbols+1] = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, letter)
                end

                symbols[#symbols+1] = "\aDEFAULT"

                return table.concat(symbols)
            end
        end

        --#endregion

        --#region: elemence

        do
            elemence.new = function (ref)
                local this = { ref = ref }
                --

                this.__depend = { {}, {} }
                this[0], this[1] = {
                    type = __mt.element.type(this.ref),
                    events = {}, callbacks = {},
                }, {}

                this[0].savable = not elements[this[0].type].unsavable == true
                --

                if this[0].type ~= "button" then
                    local v1, v2 = __mt.element.get(this.ref)
                    if v2 ~= nil then
                        this.value = { v1, v2 }
                        __mt.element.set_callback(this.ref, function (self)
                            this.value = { __mt.element.get(self) }
                        end)
                    else
                        this.value = v1
                        __mt.element.set_callback(this.ref, function (self)
                            this.value = __mt.element.get(self)
                        end)
                    end
                end

                return setmetatable(this, methods_mt.element)
            end

            elemence.group = function (ref)
                return setmetatable({
                    ref = ref, par = ref:parent(),
                    __depend = { {}, {} }
                }, methods_mt.group)
            end

            elemence.dispense = function (key, ...)
                local args, ctx = {...}, elements[key]

                args.n = table.maxn(args)

                local variable, counter = (ctx and ctx.variable) and type(args[2]) == "string", 1
                args.req, args.misc = (ctx and not variable) and ctx.arg or args.n, {}

                for i = 1, args.n do
                    local v = args[i]
                    local kind = type(v)

                    if i == 2 and ctx.variable and not variable then
                        for j = 1, #v do
                            v[j] = tools.format(v[j])
                        end
                    else
                        args[i] = tools.format(v)
                    end

                    if kind == "userdata" and v.__name == "sol.Vector" then  args[i] = v * dpi  end

                    if i > args.req then
                        args.misc[counter], counter = v, counter + 1
                    end
                end

                return args
            end

            elemence.memorize = function (self, path, location)
                if type(self) ~= "table" or self.__name ~= "pui::element" or self[0].skipsave then return end

                location = location or config
                local main = false
                if self[0].savable then
                    dirs.pave(location, self.ref, path)
                    main = true
                end

                if rawget(self, "color") then
                    local pathc = table.copy(path)
                    pathc[#pathc] = (main and "*" or "") .. path[#path]
                    dirs.pave(location, self.color.ref, pathc)
                elseif next(self[1]) then
                    local pathc, gear = table.copy(path), {}
                    pathc[#pathc] = (main and "~" or "") .. path[#path]
                    for k, v in next, self[1] do
                        if v[0].savable and not v[0].skipsave then
                            gear[k] = v.ref
                            if rawget(v, "color") then gear["*"..k] = v.color.ref end
                        end
                    end
                    dirs.pave(location, gear, pathc)
                end
            end

            elemence.features = function (self, args)
                if self[0].type == "image" or self[0].type == "value" then return end

                local had_child, had_tooltip = false, false

                for i = 1, table.maxn(args) do
                    local v = args[i]
                    local t = type(v)

                    if not had_child and t == "function" then
                        local c
                        methods_mt.element.create(self)
                        self[1], c = v(self[0].gear, self)
                        if c ~= nil then self[0].gear:depend{self, c} end
                        had_child = true

                    elseif not had_child and (t == "userdata" and v.__name == "sol.ImColor") or (t == "table" and (v[1] and v[1].__name == "sol.ImColor" or v[next(v)] and v[next(v)][1].__name == "sol.ImColor")) then
                        local im = t == "table"
                        local g = im and v[1] or v
                        local d = v[2]

                        methods_mt.element.color_picker(self, g)
                        if d ~= nil then self.color:depend{self, d} end
                        had_child = true

                    elseif not had_tooltip and t == "string" or (t == "table" and type(v[1]) == "string") then
                        __mt.element.tooltip(self.ref, tools.format(v))
                        had_tooltip = true
                    elseif i == 2 and v == false then
                        self[0].skipsave = true
                    end
                end
            end

            --#region: .depend

            local cases = {
                combo = function (v)
                    if v[3] == true then
                        return v[1].value ~= v[2]
                    else
                        for i = 2, #v do
                            if v[1].value == v[i] then return true end
                        end
                    end
                    return false
                end,
                list = function (v)
                    if v[3] == true then
                        return v[1].value ~= v[2]
                    else
                        for i = 2, #v do
                            if v[1].value == v[i] then return true end
                        end
                    end
                    return false
                end,
                selectable = function (v)
                    if v[2] == true then
                        return #v[1].value > 0
                    elseif v[3] == true then
                        return not table.ihas(v[1].value, unpack(v, 2))
                    else
                        return table.ihas(v[1].value, unpack(v, 2))
                    end
                end,
                listable = function (v)
                    if v[2] == true then
                        return #v[1].value > 0
                    elseif v[3] == true then
                        return not table.ihas(v[1].value, unpack(v, 2))
                    else
                        return table.ihas(v[1].value, unpack(v, 2))
                    end
                end,
                slider = function (v)
                    return v[2] <= v[1].value and v[1].value <= (v[3] or v[2])
                end,
            }

            local depend = function (v)
                local condition = false

                if type(v[2]) == "function" then
                    condition = v[2]( v[1] )
                else
                    local f = cases[v[1][0].type]
                    if f then condition = f(v)
                    else condition = v[1].value == v[2] end
                end

                return condition and true or false
            end

            elemence.dependant = function (__depend, dependant, disabler)
                local count = 0

                for i = 1, #__depend do
                    count = count + ( depend(__depend[i]) and 1 or 0 )
                end

                local eligible = count >= #__depend
                local kind = dependant.__name == "sol.lua::LuaGroup" and "group" or "element"
                __mt[kind][disabler and "disabled" or "visibility"](dependant, ternary(disabler, not eligible, eligible))
            end

            --#endregion
        end

        --#endregion

        -- #endregion
        --


        -- #endregion ------------------------------------------------------------------
        --



        --------------------------------------------------------------------------------
        -- #region :: PUI


        --
        -- #region : pui

        --#region: variables

        pui.version = _PUIVERSION

        pui.colors = {}
        pui.accent, pui.alpha = ui.get_style("Link Active"), ui.get_alpha()
        pui.menu_position, pui.menu_size = ui.get_position(), ui.get_size()

        events.render:set(function ()
            pui.accent, pui.alpha = ui.get_style("Link Active"), ui.get_alpha()
            pui.menu_position, pui.menu_size = ui.get_position(), ui.get_size()
        end)

        --#endregion

        --#region: features

        pui.string = tools.format

        pui.create = function (tab, name, align)
            if type(name) == "table" then
                local collection = {}
                for k, v in ipairs(name) do
                    collection[ v[1] or k ] = elemence.group( groups[{tab, v[2], v[3]}] )
                end
                return collection
            else
                return elemence.group( groups[name and {tab, name, align} or tab] )
            end
        end

        pui.find = function (...)
            local arg = {...}
            local children for i, v in ipairs(arg) do
                if type(v) == "table" then
                    children, arg[i] = v, nil
                break end
            end

            local found = { ui.find( unpack(arg) ) }

            for i, v in ipairs(found) do
                found[i] = elemence[v.__name == "sol.lua::LuaGroup" and "group" or "new"](v)
            end

            if found[2] and found[2].ref.__name == "sol.lua::LuaVar" then
                found[1].color, found[2] = found[2], nil
            elseif children and found[1] then
                for k, v in next, children do
                    local path = {...}
                    path[#path] = v
                    found[1][1][k] = pui.find( unpack(path) )
                end
            end

            return found[1]
        end

        pui.sidebar = function (name, icon)
            name, icon = tools.format(name), icon and tools.format(icon) or nil

            ui.sidebar(name, icon)
        end

        pui.get_icon = function (name)
            return icons[name]
        end

        pui.traverse = function (t, f, p)
            p = p or {}

            if type(t) == "table" and (t.__name ~= "pui::element" and t.__name ~= "pui::group") and t[#t] ~= "~" then
                for k, v in next, t do
                    local np = table.copy(p); np[#np+1] = k
                    pui.traverse(v, f, np)
                end
            else
                f(t, p)
            end
        end

        pui.translate = function (original, translations)
            original = tools.format(original)
            for k, v in next, translations or {} do
                ui.localize(k, original, tools.format(v))
            end
            return original
        end

        do -- categories
            local mt = {
                create = function (self, name, align)
                    return elemence.group(__mt.group.create(self[1], tools.format(name), align))
                end
            }	mt.__index = mt

            local sidebar = ui.find("Aimbot", "Anti Aim"):parent():parent()
            local cats = {}

            pui.category = function (name, tab)
                name, tab = tostring(tools.format(name)), tostring(tools.format(tab))
                local ref = contend(ui.find, function () end, name, tab)

                if not cats[name] then
                    cats[name] = {}
                    if not ref then cats[name][0] = sidebar:create(name) end
                end
                if not cats[name][tab] then
                    if ref then cats[name][tab] = ref
                    else cats[name][tab] = cats[name][0]:create(tab) end
                end

                return setmetatable({cats[name][tab]}, mt)
            end
        end

        pui.string_recorder = {
            open = function () stringlist = {} end,
            close = function ()
                if stringlist then
                    local list, count = {}, 0
                    for k, v in next, stringlist do
                        count = count + 1
                        list[count] = k
                    end
                    stringlist = nil
                    return list
                end
            end
        }

        --#endregion

        --#region: config system

        do
            pui.is_loading_config, pui.is_saving_config = false, false

            local function traverse_b (t, f, p)
                p = p or {}

                if type(t) == "table" and t._S == nil then
                    for k, v in next, t do
                        local np = table.copy(p); np[#np+1] = k
                        traverse_b(v, f, np)
                    end
                else
                    f(t, p)
                end
            end

            local convert = function (t)
                local new = {}
                traverse_b(t, function (v, p)
                    if type(v) == "table" and v._S ~= nil then
                        if v._C then
                            local col = table.copy(p)
                            col[#col] = "*" .. col[#col]
                            dirs.pave(new, v._C, col)
                            dirs.pave(new, v._S, p)
                        else
                            local gear = table.copy(v)
                            gear._S = nil
                            for gk, gv in next, gear do
                                if type(gv) == "table" and gv._C then
                                    gear["*"..gk], gear[gk] = gv._C, gv._S
                                end
                            end

                            local gearpath = table.copy(p)
                            gearpath[#gearpath] = "~" .. gearpath[#gearpath]
                            dirs.pave(new, gear, gearpath)
                            dirs.pave(new, v._S, p)
                        end
                    else
                        dirs.pave(new, v, p)
                    end
                end)
                return new
            end

            local locate = function (init, arg)
                if type(arg[1]) == "table" then
                    local r = {}
                    for i, v in ipairs(arg) do
                        local d = dirs.find(init, v)
                        dirs.pave(r, d, v)
                    end

                    return r
                else
                    return dirs.extract(init, arg)
                end
            end

            local save = function (location, ...)
                pui.is_saving_config = true

                local arg, packed = {...}, {}

                pui.traverse(locate(location, arg), function (ref, path)
                    local etype = __mt.element.type(ref)
                    local value, value2 = __mt.element[etype == "hotkey" and "key" or "get"](ref)
                    local vtype, v2type = type(value), type(value2)

                    if etype == "color_picker" then
                        if vtype == "table" then
                            value2, v2type = value, vtype
                            value, vtype = __mt.element.list(ref)[1], "string"
                        end

                        if value2 then
                            value = { value }
                            if v2type == "table" then
                                for i = 1, #value2 do
                                    value[#value+1] = "#".. value2[i]:to_hex()
                                end
                            else
                                value[2] = "#".. value2:to_hex()
                            end
                            value[#value+1] = "~"
                        else
                            value = "#".. value:to_hex()
                        end
                    elseif vtype == "table" then
                        value[#value+1] = "~"
                    end

                    dirs.pave(packed, value, path)
                end)

                pui.is_saving_config = false
                return packed
            end
            local load = function (location, data, ...)
                if not data then return end

                local arg, reset = {...}, true
                if arg[1] == false then table.remove(arg, 1); reset = false end

                pui.is_loading_config = true

                local packed = convert(locate(data, arg))
                pui.traverse(locate(location, arg), function (ref, path)
                    local value = dirs.find(packed, path)

                    local multicolor
                    local vtype, etype = type(value), __mt.element.type(ref)
                    local object = elements[etype] or elements[ref.__name]

                    if etype == "color_picker" then
                        if vtype == "string" and value:sub(1, 1) == "#" then
                            value = color(value)
                            vtype = "userdata"
                        elseif vtype == "table" then
                            value[#value] = nil
                            for i = 2, #value do value[i] = color(value[i]) end
                            multicolor = true
                            vtype = "userdata"
                        end
                    elseif vtype == "table" and value[#value] == "~" then
                        value[#value] = nil
                    end

                    if not object or (object.type ~= "any" and object.type ~= vtype) then
                        return reset and __mt.element.reset(ref) or nil
                    end

                    pcall(function ()
                        if etype == "hotkey" then
                            __mt.element.key(ref, value)
                        elseif etype == "color_picker" and multicolor then
                            __mt.element.set(ref, value[1])
                            __mt.element.set(ref, value[1], table.range(value, 2))
                        else
                            __mt.element.set(ref, value)
                        end
                    end)
                end)

                pui.is_loading_config = false
            end

            local package_mt = {
                __type = "pui::package", __metatable = false,
                __call = function (self, raw, ...)
                    return (type(raw) == "table" and load or save)(self[0], raw, ...)
                end,
                save = function (self, ...) return save(self[0], ...) end,
                load = function (self, ...) load(self[0], ...) end,
            }	package_mt.__index = package_mt

            pui.setup = function (t, isolate)
                if isolate == true then
                    local package = { [0] = {} }
                    pui.traverse(t, function (r, p) elemence.memorize(r, p, package[0]) end)
                    return setmetatable(package, package_mt)
                else
                    if is_setup then return debug.warning("config is already setup by this or another script") end
                    pui.traverse(t, elemence.memorize)
                    is_setup = true
                    return t
                end
            end

            pui.save = function (...) return save(config, ...) end
            pui.load = function (...) load(config, ...) end
        end

        --#endregion

        -- #endregion
        --

        --
        -- #region : methods

        methods_mt.element = {
            __metatable = false,
            __type = "pui::element", __name = "pui::element",
            __tostring = function (self) return string.format("pui::element.%s \"%s\"", self[0].type, self.ref:name()) end,
            __eq = function (a, b) return __mt.element.__eq(a.ref, b.ref) end,
            __index = function (self, key)
                return rawget(methods_mt.element, key) or rawget(__mt.wrp_element, key) or rawget(self[1], key)
            end,
            __call = function (self, ...)
                return (#{...} == 0 and __mt.element.get or __mt.element.set)(self.ref, ...)
            end,

            --

            create = function (self)
                self[0].gear = self[0].gear or elemence.group(__mt.element.create(self.ref))
                return self[0].gear
            end,

            depend = function (self, ...)
                local arg = {...}
                local disabler = arg[1] == true

                local __depend = self.__depend[disabler and 2 or 1]
                for i = disabler and 2 or 1, table.maxn(arg) do
                    local v = arg[i]
                    if v then
                        if v.__name == "pui::element" then v = {v, true} end

                        v[0] = false
                        __depend[#__depend+1] = v

                        local check = function () elemence.dependant(__depend, self.ref, disabler) end
                        check()

                        __mt.element.set_callback(v[1].ref, check)
                    end
                end

                return self
            end,

            --

            name = function (self, s)
                if s then	__mt.element.name(self.ref, tools.format(s))
                else		return __mt.element.name(self.ref) end
            end,
            set_name = function (self, s)
                __mt.element.name(self.ref, tools.format(s))
            end,
            get_name = function (self)
                return __mt.element.name(self.ref)
            end,

            type = function (self) return self[0].type end,
            get_type = function (self) return self[0].type end,

            list = function (self)
                return __mt.element.list(self.ref)
            end,
            get_list = function (self)
                return __mt.element.list(self.ref)
            end,
            update = function (self, ...)
                __mt.element.update(self.ref, ...)

                if self[0].type == "list" or self[0].type == "listable" then
                    local value, list = __mt.element.get(self.ref), __mt.element.list(self.ref)
                    if not list then return end
                    local max = #list

                    if type(value) == "number" then
                        if value > max then
                            __mt.element.set(self.ref, max)
                            self.value = max
                        end
                    else
                        local id = table.ifind(list, value)

                        if id == nil or id > max then
                            __mt.element.set(self.ref, list[max])
                            self.value = list[max]
                        end
                    end
                end
            end,

            tooltip = function (self, t)
                if t then	__mt.element.tooltip(self.ref, tools.format(t))
                else		return __mt.element.tooltip(self.ref) end
            end,
            set_tooltip = function (self, t)
                __mt.element.tooltip(self.ref, tools.format(t))
            end,
            get_tooltip = function (self)
                return __mt.element.tooltip(self.ref)
            end,

            set_visible = function (self, v)
                __mt.element.visibility(self.ref, v)
            end,
            get_visible = function (self)
                __mt.element.visibility(self.ref)
            end,

            set_disabled = function (self, v)
                __mt.element.disabled(self.ref, v)
            end,
            get_disabled = function (self)
                __mt.element.disabled(self.ref)
            end,

            get_color = function (self)
                return rawget(self, "color") and self.color.value
            end,
            color_picker = function (self, default)
                self.color = elemence.new(__mt.element.color_picker(self.ref, default))

                return self.color
            end,

            set_event = function (self, event, fn, condition)
                if condition == nil then condition = true end
                local fncond, latest = type(condition) == "function", fn

                self[0].events[fn] = function ()
                    local permission

                    if fncond then permission = condition(self) and true or false
                    else permission = self.value == condition end

                    if latest ~= permission then
                        events[event](fn, permission)
                        latest = permission
                    end
                end
                self[0].events[fn]()
                __mt.element.set_callback(self.ref, self[0].events[fn])
            end,
            unset_event = function (self, event, fn)
                events[event].unset(events[event], fn)
                __mt.element.unset_callback(self.ref, self[0].events[fn])
                self[0].events[fn] = nil
            end,

            set_callback = function (self, fn, once)
                self[0].callbacks[fn] = function () fn(self) end
                __mt.element.set_callback(self.ref, self[0].callbacks[fn], once)
            end,
            unset_callback = function (self, fn)
                if self[0].callbacks[fn] then
                    __mt.element.unset_callback(self.ref, self[0].callbacks[fn])
                    self[0].callbacks[fn] = nil
                end
            end,

            override = function (self, ...)
                __mt.element.override(self.ref, ...)
            end,
            get_override = function (self)
                return __mt.element.get_override(self.ref)
            end,
        }

        methods_mt.group = {
            __name = "pui::group", __metatable = false,
            __index = function (self, key)
                return methods_mt.group[key] or (elements[key] and pui_mt.__index(self, key) or __mt.wrp_group[key])
            end,

            name = function (self, s, t)
                local ref = t == true and self.par or self.ref
                if s then	__mt.group.name(ref, tools.format(s))
                else		return __mt.group.name(ref) end
            end,
            set_name = function (self, s, t)
                __mt.group.name(t == true and self.par or self.ref, tools.format(s))
            end,
            get_name = function (self, t)
                return __mt.group.name(t == true and self.par or self.ref)
            end,

            disabled = function (self, b, t)
                local ref = t == true and self.par or self.ref
                if b ~= nil then   __mt.group.disabled(ref, b)
                else		return __mt.group.disabled(ref) end
            end,
            set_disabled = function (self, b, t)
                __mt.group.disabled(t == true and self.par or self.ref, b and true or false)
            end,
            get_disabled = function (self, t)
                return __mt.group.disabled(t == true and self.par or self.ref)
            end,

            set_visible = function (self, b)
                __mt.group.visibility(self.ref, b and true or false)
            end,
            get_visible = function (self)
                return __mt.group.visibility(self.ref)
            end,

            depend = methods_mt.element.depend
        }

        -- #endregion
        --

        --
        -- #region : pui_mt

        do
            local cached = {} for key in next, elements do
                cached[key] = function (origin, ...)
                    local is_child = origin.__name == "pui::group"
                    local group = is_child and origin.ref or groups[origin]

                    local args = elemence.dispense(key, ...)
                    local this = elemence.new( __mt.group[key]( group, unpack(args, 1, args.n < args.req and args.n or args.req) ) )

                    elemence.features(this, args.misc)

                    return this
                end
            end

            pui_mt.__metatable = false
            pui_mt.__name = "pui::basement"
            pui_mt.__index = function (self, key)
                if not elements[key] then return ui[key] end
                return cached[key]
            end
        end

        -- #endregion
        --


        -- #endregion ------------------------------------------------------------------
        --




        return setmetatable(pui, pui_mt) ---------------------------<  enQ • 1927  >----
    end,

["neverlose/smoothy"] = function(require)
        local native_GetTimescale = utils.get_vfunc('engine.dll', 'VEngineClient014', 91, 'float(__thiscall*)(void*)')

        local to_pairs = {
            vector = { 'x', 'y', 'z' },
            imcolor =  { 'r', 'g', 'b', 'a' }
        }

        local function get_type(value)
            local val_type = type(value)

            if val_type == 'userdata' and value.__type then
                return string.lower(value.__type.name)
            end

            if val_type == 'boolean' then
                value = value and 1 or 0
            end

            return val_type
        end

        local function copy_tables(destination, keysTable, valuesTable)
            valuesTable = valuesTable or keysTable
            local mt = getmetatable(keysTable)

            if mt and getmetatable(destination) == nil then
                setmetatable(destination, mt)
            end

            for k,v in pairs(keysTable) do
                if type(v) == 'table' then
                    destination[k] = copy_tables({}, v, valuesTable[k])
                else
                    local value = valuesTable[k]

                    if type(value) == 'boolean' then
                        value = value and 1 or 0
                    end

                    destination[k] = value
                end
            end

            return destination
        end

        local function resolve(easing_fn, previous, new, clock, duration)
            if type(new) == 'boolean' then new = new and 1 or 0 end
            if type(previous) == 'boolean' then previous = previous and 1 or 0 end

            local previous = easing_fn(clock, previous, new - previous, duration)

            if type(new) == 'number' then
                if math.abs(new-previous) <= .001 then
                    previous = new
                end

                if previous % 1 < .0001 then
                    previous = math.floor(previous)
                elseif previous % 1 > .9999 then
                    previous = math.ceil(previous)
                end
            end

            return previous
        end

        local function perform_easing(ntype, easing_fn, previous, new, clock, duration)
            if to_pairs[ntype] then
                for _, key in ipairs(to_pairs[ntype]) do
                    previous[key] = perform_easing(
                        type(v), easing_fn,
                        previous[key], new[key],
                        clock, duration
                    )
                end

                return previous
            end

            if ntype == 'table' then
                for k, v in pairs(new) do
                    previous[k] = previous[k] or v
                    previous[k] = perform_easing(
                        type(v), easing_fn,
                        previous[k], v,
                        clock, duration
                    )
                end

                return previous
            end

            return resolve(easing_fn, previous, new, clock, duration)
        end

        local adjusted_speed

        local new = function(default, easing_fn)
            if type(default) == 'boolean' then
                default = default and 1 or 0
            end

            local mt = { }
            local mt_data = {
                value = default or 0,
                easing = easing_fn or function(t, b, c, d)
                    return c * t / d + b
                end
            }

            function mt.update(self, duration, value, easing, ignore_adj_speed)
                if type(value) == 'boolean' then
                    value = value and 1 or 0
                end

                local clock = globals.frametime / native_GetTimescale()
                local duration = duration or .15
                local value_type = get_type(value)
                local target_type = get_type(self.value)

                assert(value_type == target_type, string.format('type mismatch. expected %s (received %s)', target_type, value_type))

                if self.value == value then
                    return value
                end

                if adjusted_speed and ignore_adj_speed ~= true then
                    duration = duration * adjusted_speed
                end

                if clock <= 0 or clock >= duration then
                    if target_type == 'imcolor' or target_type == 'vector' then
                        self.value = value:clone()
                    elseif target_type == 'table' then
                        copy_tables(self.value, value)
                    else
                        self.value = value
                    end
                else
                    local easing = easing or self.easing

                    self.value = perform_easing(
                        target_type, easing,
                        self.value, value,
                        clock, duration
                    )
                end

                return self.value
            end

            return setmetatable(mt, {
                __metatable = false,
                __call = mt.update,
                __index = mt_data
            })
        end

        local new_interp = function(initial_value)
            return setmetatable({
                previous = initial_value or 0
            }, {
                __call = function(self, new_value, mul)
                    local mul = mul or 1
                    local tickinterval = globals.tickinterval * mul
                    local difference = math.abs(new_value - self.previous)

                    if difference > 0 then
                        local clock = globals.frametime / native_GetTimescale()
                        local time = math.min(tickinterval, clock) / tickinterval

                        self.previous = self.previous + time * (new_value - self.previous)
                    else
                        self.previous = new_value
                    end

                    self.previous = (self.previous % 1 < .0001) and 0 or self.previous

                    return self.previous
                end
            })
        end

        local set_speed = function(new_speed)
            if new_speed == true then return adjusted_speed or 1 end
            if new_speed == nil then adjusted_speed = nil end

            if type(new_speed) == 'number' and new_speed >= 0 then
                adjusted_speed = new_speed
            end

            return adjusted_speed
        end

        return {
            new = new,
            new_interp = new_interp,
            set_speed = set_speed
        }
    end,

    ["ffi"] = function()
        return ffi
    end,
}

local loaded = {}
local loading = {}
local custom_require

local function make_env(modname)
    return setmetatable({ require = custom_require, _MODULE = modname }, { __index = _G })
end

local function load_embedded_module(lib, def)
    if loaded[lib] ~= nil then return loaded[lib] end
    if loading[lib] then error("circular require detected for module: " .. lib, 2) end
    loading[lib] = true

    local ret
    local t = type(def)
    if t == "function" then
        local ok, result = pcall(def, custom_require, lib)
        loading[lib] = nil
        if not ok then error(("failed to load module '%s': %s"):format(lib, tostring(result)), 2) end
        ret = result
    elseif t == "table" then
        loading[lib] = nil
        ret = def
    elseif t == "string" then
        if not compiler then
            loading[lib] = nil
            error(("module '%s' is stored as source string, but load/loadstring is unavailable"):format(lib), 2)
        end
        local chunk, err = compiler(def, "@" .. lib)
        if not chunk then
            loading[lib] = nil
            error(("failed to compile module '%s': %s"):format(lib, tostring(err)), 2)
        end
        if setfenv then setfenv(chunk, make_env(lib)) end
        local ok, result = pcall(chunk, lib)
        loading[lib] = nil
        if not ok then error(("failed to load module '%s': %s"):format(lib, tostring(result)), 2) end
        ret = result
    else
        loading[lib] = nil
        error(("unsupported embedded module type for '%s': %s"):format(lib, t), 2)
    end
    if ret == nil then ret = true end
    loaded[lib] = ret
    return ret
end

custom_require = function(lib)
    if lib == "ffi" then
        return ffi
    end
    local def = modules[lib]
    if def ~= nil then
        return load_embedded_module(lib, def)
    end
    return error("require: " .. lib)
end

require = custom_require

local pui = require("neverlose/pui")

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function enc_b64(data) return ((data:gsub('.', function(x) local r,b='',x:byte() for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end return r end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x) if (#x < 6) then return '' end local c=0 for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end return b64chars:sub(c+1,c+1) end)..({ '', '==', '=' })[#data%3+1]) end
local function dec_b64(data) data = string.gsub(data, '[^'..b64chars..'=]', '') return (data:gsub('.', function(x) if (x == '=') then return '' end local r,f='',(b64chars:find(x)-1) for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end return r end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x) if (#x ~= 8) then return '' end local c=0 for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end return string.char(c) end)) end

pui.sidebar("madrilla recode", "skull")

local tab_main = pui.category("madrilla recode", "Main")
local tab_ragebot = pui.category("madrilla recode", "Ragebot")
local tab_antiaim = pui.category("madrilla recode", "Anti-Aim")
local tab_visuals = pui.category("madrilla recode", "Visuals")
local tab_misc = pui.category("madrilla recode", "Misc")
local tab_config = pui.category("madrilla recode", "Config")

local main_group = tab_main:create("Main")
local ragebot_group = tab_ragebot:create("Ragebot")
local antiaim_group = tab_antiaim:create("Anti-Aim")
local visuals_group = tab_visuals:create("Visuals")
local misc_group = tab_misc:create("Misc")
local config_group = tab_config:create("Config")

local menu = {
    ragebot = {
        resolver = {
            enable = ragebot_group:switch("Enable Resolver"),
            log = ragebot_group:switch("Log resolver actions"),
            freestanding = ragebot_group:switch("Freestanding trace fallback"),
            freestandingWidth = ragebot_group:slider("Freestanding trace width", 20, 80, 40)
        },
        autoSafepoint = {
            enable = ragebot_group:switch("Auto Safepoint"),
            options = ragebot_group:selectable("Options", "low jitter", "high jitter", "lethal", "in air", "on miss")
        },
        ragebotHelper = {
            enable = ragebot_group:switch("Ragebot Helper"),
            bind = ragebot_group:hotkey("Helper Key"),
            avoidUnsafeHitboxes = ragebot_group:switch("Avoid unsafe hitboxes"),
            maxTargetTime = ragebot_group:slider("Max target time", 0, 5, 4),
            hitChance = ragebot_group:slider("Hitchance", 1, 100, 80),
            minDamage = ragebot_group:slider("Min damage", 1, 100, 30),
            forceHideshotsSniper = ragebot_group:switch("Force hideshots on sniper crouch")
        },
        multiDT = {
            enable = ragebot_group:switch("Multi-key double tap"),
            key1 = ragebot_group:hotkey("Double tap key 1"),
            key2 = ragebot_group:hotkey("Double tap key 2"),
            key3 = ragebot_group:hotkey("Double tap key 3")
        }
    },
    antiaim = {
        enable = antiaim_group:switch("Enable Custom AA"),
        lbyBreaker = antiaim_group:switch("0.22s LBY Breaker"),
        stateCombo = antiaim_group:combo("State", "global", "standing", "moving", "slow walking", "crouched", "crouch moving", "air crouched", "air", "fakeducking", "defensive"),
        enableAntiBackstab = antiaim_group:switch("Anti-Backstab"),
        invertOnShot = antiaim_group:switch("Invert desync on shot"),
        invertOnHit = antiaim_group:switch("Invert desync on hit"),
        freestandDesync = antiaim_group:switch("Freestand Desync (Auto-Peek Side)"),
        antiBrute = antiaim_group:switch("Anti-Bruteforce"),
        antiBruteModes = antiaim_group:selectable("Anti-Brute modes", "On Hit", "On Miss"),
        antiBruteAction = antiaim_group:combo("Anti-Brute action", "Invert Side", "Randomize", "Cycle 3-way"),
        manualLeft = antiaim_group:hotkey("Manual Left"),
        manualRight = antiaim_group:hotkey("Manual Right"),
        manualForward = antiaim_group:hotkey("Manual Forward"),
        manualBack = antiaim_group:hotkey("Manual Back"),
        states = {}
    },
    visuals = {
        weather = {
            enable = visuals_group:switch("Weather effects"),
            precipitationType = visuals_group:combo("Type", "none", "rain", "snow", "particle rain", "particle snow", "particle ash")
        },
        grenadeESP = {
            enable = visuals_group:switch("Grenade inventory ESP"),
            position = visuals_group:combo("Position", "Right", "Left", "Top", "Bottom"),
            scale = visuals_group:slider("Icon scale", 6, 10, 8)
        }
    },
    hud = {
        customKillfeed = {
            enable = misc_group:switch("Custom killfeed"),
            advanced = misc_group:switch("Advanced colors"),
            size = misc_group:slider("Size", 10, 30, 16)
        },
        floatingDamage = {
            enable = misc_group:switch("3D Floating damage"),
            duration = misc_group:slider("Duration (s)", 1, 5, 2)
        },
        logs = {
            options = misc_group:selectable("Logs", "console", "hitlog indicator"),
            logOnshot = misc_group:switch("Log onshot status")
        }
    },
    misc = {
        clantag = { enable = misc_group:switch("Animated clantag") },
        autoBuy = {
            enable = misc_group:switch("Auto buy"),
            primary = misc_group:combo("Primary", "-", "scout", "auto", "awp"),
            secondary = misc_group:combo("Secondary", "-", "deagle"),
            equipment = misc_group:selectable("Equipment", "armor", "nades")
        },
        fastLadder = { enable = misc_group:switch("Fast ladder") },
        smartDrop = { enable = misc_group:switch("Smart drop"), bind = misc_group:hotkey("Smart drop key") },
        dropNades = { enable = misc_group:switch("Drop nades"), bind = misc_group:hotkey("Drop nades key") },
        killsay = { enable = misc_group:switch("Smart killsay") }
    }
}

-- Apply dependencies
menu.ragebot.resolver.log:depend({menu.ragebot.resolver.enable, true})
menu.ragebot.resolver.freestanding:depend({menu.ragebot.resolver.enable, true})
menu.ragebot.resolver.freestandingWidth:depend({menu.ragebot.resolver.enable, true})

menu.ragebot.autoSafepoint.options:depend({menu.ragebot.autoSafepoint.enable, true})

menu.ragebot.ragebotHelper.bind:depend({menu.ragebot.ragebotHelper.enable, true})
menu.ragebot.ragebotHelper.avoidUnsafeHitboxes:depend({menu.ragebot.ragebotHelper.enable, true})
menu.ragebot.ragebotHelper.maxTargetTime:depend({menu.ragebot.ragebotHelper.enable, true})
menu.ragebot.ragebotHelper.hitChance:depend({menu.ragebot.ragebotHelper.enable, true})
menu.ragebot.ragebotHelper.minDamage:depend({menu.ragebot.ragebotHelper.enable, true})
menu.ragebot.ragebotHelper.forceHideshotsSniper:depend({menu.ragebot.ragebotHelper.enable, true})

menu.ragebot.multiDT.key1:depend({menu.ragebot.multiDT.enable, true})
menu.ragebot.multiDT.key2:depend({menu.ragebot.multiDT.enable, true})
menu.ragebot.multiDT.key3:depend({menu.ragebot.multiDT.enable, true})

menu.antiaim.lbyBreaker:depend({menu.antiaim.enable, true})
menu.antiaim.stateCombo:depend({menu.antiaim.enable, true})
menu.antiaim.enableAntiBackstab:depend({menu.antiaim.enable, true})
menu.antiaim.invertOnShot:depend({menu.antiaim.enable, true})
menu.antiaim.invertOnHit:depend({menu.antiaim.enable, true})
menu.antiaim.freestandDesync:depend({menu.antiaim.enable, true})
menu.antiaim.antiBrute:depend({menu.antiaim.enable, true})
menu.antiaim.antiBruteModes:depend({menu.antiaim.enable, true})
menu.antiaim.antiBruteAction:depend({menu.antiaim.enable, true})
menu.antiaim.manualLeft:depend({menu.antiaim.enable, true})
menu.antiaim.manualRight:depend({menu.antiaim.enable, true})
menu.antiaim.manualForward:depend({menu.antiaim.enable, true})
menu.antiaim.manualBack:depend({menu.antiaim.enable, true})

menu.visuals.weather.precipitationType:depend({menu.visuals.weather.enable, true})
menu.visuals.grenadeESP.position:depend({menu.visuals.grenadeESP.enable, true})
menu.visuals.grenadeESP.scale:depend({menu.visuals.grenadeESP.enable, true})

menu.hud.customKillfeed.advanced:depend({menu.hud.customKillfeed.enable, true})
menu.hud.customKillfeed.size:depend({menu.hud.customKillfeed.enable, true})
menu.hud.floatingDamage.duration:depend({menu.hud.floatingDamage.enable, true})

menu.misc.autoBuy.primary:depend({menu.misc.autoBuy.enable, true})
menu.misc.autoBuy.secondary:depend({menu.misc.autoBuy.enable, true})
menu.misc.autoBuy.equipment:depend({menu.misc.autoBuy.enable, true})
menu.misc.smartDrop.bind:depend({menu.misc.smartDrop.enable, true})
menu.misc.dropNades.bind:depend({menu.misc.dropNades.enable, true})

-- PUI color pickers attachment
menu.visuals.grenadeESP.enable:color_picker(color(255,255,255,255))
menu.hud.customKillfeed.advanced:color_picker(color(255,255,255,255))
menu.hud.floatingDamage.enable:color_picker(color(255,69,69,255))

local state_names = {"global", "standing", "moving", "slow walking", "crouched", "crouch moving", "air crouched", "air", "fakeducking", "defensive"}
local antiaim_builder = tab_antiaim:create("Builder")

for _, name in ipairs(state_names) do
    local state = { name = name }
    
    local function depSt() return menu.antiaim.stateCombo.value == name and menu.antiaim.enable.value end
    local function depOv() return depSt() and (state.overrideGlobal == nil or state.overrideGlobal.value) end
    
    local depsSt = {{menu.antiaim.stateCombo, depSt}, {menu.antiaim.enable, depSt}}
    local depsOv = {{menu.antiaim.stateCombo, depOv}, {menu.antiaim.enable, depOv}}
    
    if name ~= "global" then
        state.overrideGlobal = antiaim_builder:switch("["..name.."] Override global")
        state.overrideGlobal:depend(unpack(depsSt))
        table.insert(depsOv, {state.overrideGlobal, depOv})
    end
    
    if name ~= "defensive" then
        state.allowDefensive = antiaim_builder:switch("["..name.."] Allow defensive"):depend(unpack(depsOv))
        state.forceDefensive = antiaim_builder:switch("["..name.."] Force defensive"):depend(unpack(depsOv))
    end
    
    state.pitchOffset = antiaim_builder:slider("["..name.."] Pitch offset", -89, 89, 0):depend(unpack(depsOv))
    state.yawOffset = antiaim_builder:slider("["..name.."] Yaw offset", -180, 180, 0):depend(unpack(depsOv))
    state.yawMode = antiaim_builder:combo("["..name.."] Yaw mode", "static", "jitter", "delayed jitter", "random", "spin", "lfo", "switch", "3-way", "5-way"):depend(unpack(depsOv))
    
    local function depJit() return depOv() and (state.yawMode.value == "jitter" or state.yawMode.value == "delayed jitter") end
    local function depLfo() return depOv() and (state.yawMode.value == "lfo") end
    local function depSwc() return depOv() and (state.yawMode.value == "switch") end
    
    local depsJit = {} for i,v in ipairs(depsOv) do table.insert(depsJit, {v[1], depJit}) end table.insert(depsJit, {state.yawMode, depJit})
    local depsLfo = {} for i,v in ipairs(depsOv) do table.insert(depsLfo, {v[1], depLfo}) end table.insert(depsLfo, {state.yawMode, depLfo})
    local depsSwc = {} for i,v in ipairs(depsOv) do table.insert(depsSwc, {v[1], depSwc}) end table.insert(depsSwc, {state.yawMode, depSwc})
    
    state.yawJitterDelayMin = antiaim_builder:slider("["..name.."] Yaw jitter delay min", 1, 10, 3):depend(unpack(depsJit))
    state.yawJitterDelayMax = antiaim_builder:slider("["..name.."] Yaw jitter delay max", 1, 10, 9):depend(unpack(depsJit))
    state.yawLfoShape = antiaim_builder:combo("["..name.."] Yaw LFO shape", "sine", "triangle", "pulse"):depend(unpack(depsLfo))
    state.yawLfoSpeed = antiaim_builder:slider("["..name.."] Yaw LFO speed", 1, 100, 50):depend(unpack(depsLfo))
    state.yawLfoVelocityScale = antiaim_builder:switch("["..name.."] Scale yaw LFO by velocity"):depend(unpack(depsLfo))
    state.yawLfoRange = antiaim_builder:slider("["..name.."] Yaw LFO range", 0, 180, 90):depend(unpack(depsLfo))
    state.yawSwitchDelay = antiaim_builder:slider("["..name.."] Yaw switch delay (ticks)", 1, 100, 30):depend(unpack(depsSwc))
    
    state.bodyYawOffset = antiaim_builder:slider("["..name.."] Body yaw offset", -180, 180, 60):depend(unpack(depsOv))
    state.bodyYawMode = antiaim_builder:combo("["..name.."] Body yaw mode", "static", "jitter", "delayed jitter", "random", "lfo"):depend(unpack(depsOv))
    
    local function depByJit() return depOv() and (state.bodyYawMode.value == "jitter" or state.bodyYawMode.value == "delayed jitter") end
    local function depByLfo() return depOv() and (state.bodyYawMode.value == "lfo") end
    
    local depsByJit = {} for i,v in ipairs(depsOv) do table.insert(depsByJit, {v[1], depByJit}) end table.insert(depsByJit, {state.bodyYawMode, depByJit})
    local depsByLfo = {} for i,v in ipairs(depsOv) do table.insert(depsByLfo, {v[1], depByLfo}) end table.insert(depsByLfo, {state.bodyYawMode, depByLfo})
    
    state.bodyYawJitterDelayMin = antiaim_builder:slider("["..name.."] Body yaw jitter delay min", 1, 10, 3):depend(unpack(depsByJit))
    state.bodyYawJitterDelayMax = antiaim_builder:slider("["..name.."] Body yaw jitter delay max", 1, 10, 9):depend(unpack(depsByJit))
    state.bodyYawLfoShape = antiaim_builder:combo("["..name.."] Body yaw LFO shape", "sine", "triangle", "pulse"):depend(unpack(depsByLfo))
    state.bodyYawLfoSpeed = antiaim_builder:slider("["..name.."] Body yaw LFO speed", 1, 100, 50):depend(unpack(depsByLfo))
    state.bodyYawLfoVelocityScale = antiaim_builder:switch("["..name.."] Scale body yaw LFO by velocity"):depend(unpack(depsByLfo))
    state.bodyYawLfoRange = antiaim_builder:slider("["..name.."] Body yaw LFO range", 0, 180, 60):depend(unpack(depsByLfo))
    
    state.staticPeek = antiaim_builder:switch("["..name.."] Static peek on hit"):depend(unpack(depsOv))
    state.fakeBreaker = antiaim_builder:switch("["..name.."] Extended desync"):depend(unpack(depsOv))
    state.extendFake = antiaim_builder:switch("["..name.."] Extend fake"):depend(unpack(depsOv))
    
    menu.antiaim.states[name] = state
end

pui.setup(menu)

local config_slot = config_group:combo("Config Slot", "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5")
config_group:button("Save to Selected Slot", function()
    local slot = config_slot.value
    local cfgs = db:get("mr_nl_configs") or {}
    cfgs[slot] = pui.save()
    db:set("mr_nl_configs", cfgs)
    common.add_event("[madrilla recode] Saved to "..slot, "floppy-disk")
end)
config_group:button("Load from Selected Slot", function()
    local slot = config_slot.value
    local cfgs = db:get("mr_nl_configs") or {}
    if cfgs[slot] then
        pui.load(cfgs[slot])
        common.add_event("[madrilla recode] Loaded from "..slot, "folder-open")
    else
        common.add_event("[madrilla recode] No config in "..slot, "triangle-exclamation")
    end
end)
config_group:button("Export to Console", function()
    print("[madrilla recode] Config exported to console (JSON).")
    print(json.stringify(pui.save()))
end)

-- LOGIC CORE
local function CalculateLFO(time, shape, speedPct, range, scaleVel)
    local speedHz = 0.5 + (speedPct/100) * 14.5
    if scaleVel then
        local lp = entity.get_local_player()
        if lp then
            local vel = lp.m_vecVelocity
            if vel then speedHz = speedHz * (1.0 + (math.sqrt(vel.x^2+vel.y^2)/250.0)*1.5) end
        end
    end
    local t = time * speedHz * 2 * math.pi
    if shape == "sine" then return math.sin(t)*range
    elseif shape == "triangle" then
        local val = (t/(2*math.pi))%1.0
        if val < 0.5 then return (val*4-1)*range else return ((1-val)*4-1)*range end
    elseif shape == "pulse" then return (math.sin(t)>0) and range or -range
    end
    return 0
end

local nl_refs = {
    pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
    yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
    yaw_base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
    yaw_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
    jitter = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
    jitter_val = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
    body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
    body_yaw_inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
    body_yaw_left = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
    body_yaw_right = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
    body_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
    freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding")
}

local function reset_nl_overrides()
    for k, v in pairs(nl_refs) do
        if v and v.override then v:override() end
    end
end

local antiaim = {
    prev_sim_time=0, active_until=1, ticks=0, ticks_from_activation=0, active=false,
    bodyYawSide=false, bodyYawDelay=0, yawSide=false, yawAmmount=0, yawDelay=0,
    lastHit=false, inversionActive=false, yaw3WayState=0, yaw5WayState=0,
}

antiaim.GetKnifeTarget = function()
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return nil end
    local myPos = lp:get_origin()
    if not myPos then return nil end
    local closest, dist = nil, 230
    for _, t in ipairs(entity.get_players(true)) do
        if t ~= lp and t:is_alive() then
            local w = t:get_player_weapon()
            if w and w:get_classname() == "CKnife" then
                local ep = t:get_origin()
                if ep then
                    local d = math.sqrt((myPos.x-ep.x)^2+(myPos.y-ep.y)^2+(myPos.z-ep.z)^2)
                    if d < dist then dist=d; closest=t end
                end
            end
        end
    end
    return closest
end

antiaim.UpdateDefensive = function()
    local lp = entity.get_local_player()
    if not lp then return end
    local tc = globals.tickcount
    local st = lp:get_simulation_time()
    local sim = math.floor(st.current / globals.tickinterval)
    local diff = sim - antiaim.prev_sim_time
    if diff < 0 then
        local nc = utils.net_channel()
        local lat_t = nc and math.floor((nc.avg_latency[0]+nc.avg_latency[1])/globals.tickinterval) or 0
        local w = math.max(1, math.abs(diff) - lat_t)
        antiaim.active_until = tc + w
        antiaim.ticks = w
    end
    antiaim.prev_sim_time = sim
    if globals.choked_commands <= 1 then antiaim.active = antiaim.active_until > tc end
    if antiaim.active then antiaim.ticks_from_activation = antiaim.ticks - (antiaim.active_until - tc) + 1 end
end

antiaim.GetState = function()
    local lp = entity.get_local_player()
    local flags = lp.m_fFlags or 0
    local onGround = bit.band(flags,1) == 1
    local duckAmt = lp.m_flDuckAmount or 0
    local inDuck = duckAmt > 0.5
    local vel = lp.m_vecVelocity
    local speed = vel and math.sqrt(vel.x^2+vel.y^2) or 0
    if not onGround then
        if inDuck then
            local s = menu.antiaim.states["air crouched"]
            if s.overrideGlobal and s.overrideGlobal.value then return s end
        else
            local s = menu.antiaim.states["air"]
            if s.overrideGlobal and s.overrideGlobal.value then return s end
        end
        return menu.antiaim.states["global"]
    end
    if inDuck then
        if speed > 1.1 then
            local s = menu.antiaim.states["crouch moving"]
            if s.overrideGlobal and s.overrideGlobal.value then return s end
        else
            local s = menu.antiaim.states["crouched"]
            if s.overrideGlobal and s.overrideGlobal.value then return s end
        end
    end
    if speed > 1.1 then
        local s = menu.antiaim.states["moving"]
        if s.overrideGlobal and s.overrideGlobal.value then return s end
    else
        local s = menu.antiaim.states["standing"]
        if s.overrideGlobal and s.overrideGlobal.value then return s end
    end
    return menu.antiaim.states["global"]
end

antiaim.OnSetupCommand = function(cmd)
    antiaim.UpdateDefensive()
    if menu.antiaim.enableAntiBackstab.value then
        local target = antiaim.GetKnifeTarget()
        if target then
            local lp = entity.get_local_player()
            if lp then
                local ep = lp:get_eye_position()
                local tp = target:get_origin()
                if ep and tp then
                    local dx,dy,dz = tp.x-ep.x, tp.y-ep.y, tp.z-ep.z
                    cmd.view_angles.y = math.deg(math.atan2(dy,dx))
                    cmd.view_angles.x = -math.deg(math.atan2(dz,math.sqrt(dx^2+dy^2)))
                end
            end
            return
        end
    end
    if not menu.antiaim.enable.value then reset_nl_overrides(); return end
    
    local function apply_manual(yaw_dir)
        if nl_refs.pitch.override then
            nl_refs.yaw:override(yaw_dir)
            nl_refs.yaw_offset:override(0)
            nl_refs.jitter:override("Disabled")
            nl_refs.body_yaw:override(true)
            nl_refs.body_yaw_left:override(60)
            nl_refs.body_yaw_right:override(-60)
            nl_refs.body_freestanding:override("Off")
            nl_refs.freestanding:override(false)
        end
    end

    if menu.antiaim.manualLeft.value then apply_manual("Left"); return end
    if menu.antiaim.manualRight.value then apply_manual("Right"); return end
    if menu.antiaim.manualBack.value then apply_manual("Backward"); return end
    if menu.antiaim.manualForward.value then apply_manual("Forward"); return end
    
    local state = antiaim.GetState()
    if state.forceDefensive and state.forceDefensive.value then cmd.force_defensive = true end
    if antiaim.active and state.allowDefensive and state.allowDefensive.value then
        local ds = menu.antiaim.states["defensive"]
        if ds.overrideGlobal and ds.overrideGlobal.value then state = ds end
    end
    
    local ym = state.yawMode.value
    if ym == "static" then antiaim.yawSide = true; antiaim.yawAmmount = state.yawOffset.value
    elseif ym == "jitter" then if globals.choked_commands < 1 then antiaim.yawSide = not antiaim.yawSide; antiaim.yawAmmount = state.yawOffset.value/2 end
    elseif ym == "delayed jitter" then
        if antiaim.yawDelay == 0 then antiaim.yawSide = not antiaim.yawSide; antiaim.yawAmmount = state.yawOffset.value/2; antiaim.yawDelay = math.random(state.yawJitterDelayMin.value, state.yawJitterDelayMax.value)
        else antiaim.yawDelay = antiaim.yawDelay - 1 end
    elseif ym == "random" then antiaim.yawSide = math.random(0,1)==1; antiaim.yawAmmount = math.random(-180,180)
    elseif ym == "spin" then antiaim.yawSide = true; local a = (globals.tickcount*(360/30))%360; antiaim.yawAmmount = a > 180 and a-360 or a
    elseif ym == "lfo" then antiaim.yawSide = true; antiaim.yawAmmount = CalculateLFO(globals.realtime, state.yawLfoShape.value, state.yawLfoSpeed.value, state.yawLfoRange.value, state.yawLfoVelocityScale.value)
    elseif ym == "switch" then if globals.tickcount % state.yawSwitchDelay.value == 0 then antiaim.yawSide = not antiaim.yawSide end; antiaim.yawAmmount = state.yawOffset.value
    elseif ym == "3-way" then if globals.choked_commands < 1 then antiaim.yaw3WayState = (antiaim.yaw3WayState+1)%3; local off = state.yawOffset.value; antiaim.yawAmmount = ({[0]=0,[1]=off,[2]=-off})[antiaim.yaw3WayState]; antiaim.yawSide = true end
    elseif ym == "5-way" then if globals.choked_commands < 1 then antiaim.yaw5WayState = (antiaim.yaw5WayState+1)%5; local off = state.yawOffset.value; local vals = {[0]=0,[1]=off/2,[2]=off,[3]=-off/2,[4]=-off}; antiaim.yawAmmount = vals[antiaim.yaw5WayState]; antiaim.yawSide = true end
    end
    
    local bym = state.bodyYawMode.value
    local lfoBody, isBodyLfo = 0, false
    if bym == "delayed jitter" then
        if antiaim.bodyYawDelay == 0 then antiaim.bodyYawSide = not antiaim.bodyYawSide; antiaim.bodyYawDelay = math.random(state.bodyYawJitterDelayMin.value, state.bodyYawJitterDelayMax.value)
        else antiaim.bodyYawDelay = antiaim.bodyYawDelay - 1 end
    elseif bym == "jitter" then if globals.choked_commands < 1 then antiaim.bodyYawSide = not antiaim.bodyYawSide end
    elseif bym == "random" then if globals.choked_commands < 1 then antiaim.bodyYawSide = math.random(0,1)==1 end
    elseif bym == "lfo" then isBodyLfo = true; lfoBody = CalculateLFO(globals.realtime, state.bodyYawLfoShape.value, state.bodyYawLfoSpeed.value, state.bodyYawLfoRange.value, state.bodyYawLfoVelocityScale.value)
    end
    
    local finalYaw = antiaim.yawSide and antiaim.yawAmmount or -antiaim.yawAmmount
    local bodyOff  = state.bodyYawOffset.value
    local finalBody = antiaim.bodyYawSide and bodyOff or -bodyOff
    if antiaim.inversionActive then
        finalYaw = -finalYaw; finalBody = -finalBody
        if isBodyLfo then lfoBody = -lfoBody end
    end
    if menu.antiaim.lbyBreaker:get() then
        local ts = globals.curtime % 0.22
        if ts < globals.tickinterval * 2 then finalBody = globals.tickcount%2==0 and 120 or -120 end
    end
    rage.antiaim:override_hidden_pitch(state.pitchOffset:get())
    
    local override_yaw_offset = isBodyLfo and lfoBody or finalBody
    if state.fakeBreaker and state.fakeBreaker:get() then
        if globals.choked_commands == 2 then override_yaw_offset = 0
        else override_yaw_offset = antiaim.bodyYawSide and 120 or -120 end
    end
    rage.antiaim:override_hidden_yaw_offset(override_yaw_offset)
    
    if nl_refs.pitch.override then
        nl_refs.yaw:override("Backward")
        nl_refs.yaw_offset:override(finalYaw)
        nl_refs.jitter:override("Disabled")
        nl_refs.body_yaw:override(true)
        nl_refs.body_yaw_left:override(override_yaw_offset)
        nl_refs.body_yaw_right:override(-override_yaw_offset)
        nl_refs.body_yaw_inverter:override(false)
        nl_refs.body_freestanding:override(menu.antiaim.freestandDesync:get() and "Peek Fake" or "Off")
        nl_refs.freestanding:override(false)
    end
end

antiaim.OnRoundStart = function()
    antiaim.prev_sim_time=0; antiaim.active_until=1; antiaim.ticks=0
    antiaim.ticks_from_activation=0; antiaim.active=false; antiaim.inversionActive=false
    antiaim.yaw3WayState=0; antiaim.yaw5WayState=0
end

local hit_this_tick = 0
local antiBrutePhase = 0
local function TriggerAntiBrute()
    local action = menu.antiaim.antiBruteAction.value
    if action == "Invert Side" then antiaim.inversionActive = not antiaim.inversionActive
    elseif action == "Randomize" then antiaim.inversionActive = math.random(1,2)==1; antiaim.yaw3WayState = math.random(0,2); antiaim.yaw5WayState = math.random(0,4)
    elseif action == "Cycle 3-way" then
        antiBrutePhase = (antiBrutePhase+1)%3
        if antiBrutePhase==0 then antiaim.inversionActive=false; antiaim.yaw3WayState=0
        elseif antiBrutePhase==1 then antiaim.inversionActive=true; antiaim.yaw3WayState=1
        else antiaim.inversionActive = not antiaim.inversionActive; antiaim.yaw3WayState=2 end
    end
end

events.weapon_fire:set(function(e)
    if not menu.antiaim.invertOnShot.value then return end
    if entity.get(e.userid,true) == entity.get_local_player() then antiaim.inversionActive = not antiaim.inversionActive end
end)

events.player_hurt:set(function(e)
    local me = entity.get_local_player()
    if entity.get(e.userid,true) ~= me then return end
    hit_this_tick = globals.tickcount
    if menu.antiaim.invertOnHit.value then antiaim.inversionActive = not antiaim.inversionActive end
    if menu.antiaim.antiBrute.value then
        for _,m in ipairs(menu.antiaim.antiBruteModes.value) do
            if m=="On Hit" then TriggerAntiBrute(); break end
        end
    end
end)

events.bullet_impact:set(function(e)
    if not menu.antiaim.antiBrute.value then return end
    local has_miss = false
    for _,m in ipairs(menu.antiaim.antiBruteModes.value) do if m=="On Miss" then has_miss=true; break end end
    if not has_miss then return end
    local shooter = entity.get(e.userid,true)
    local me = entity.get_local_player()
    if not shooter or not me or shooter==me then return end
    if shooter.m_iTeamNum == me.m_iTeamNum then return end
    local sh = shooter:get_hitbox_position(0)
    local mo = me:get_origin()
    if not sh or not mo then return end
    local lx,ly,lz = e.x-sh.x, e.y-sh.y, e.z-sh.z
    local len2 = lx^2+ly^2+lz^2
    local mx,my,mz = mo.x, mo.y, mo.z+32
    local dist
    if len2 == 0 then dist = math.sqrt((mx-sh.x)^2+(my-sh.y)^2+(mz-sh.z)^2)
    else
        local t = math.max(0, math.min(1, ((mx-sh.x)*lx+(my-sh.y)*ly+(mz-sh.z)*lz)/len2))
        dist = math.sqrt((mx-(sh.x+t*lx))^2+(my-(sh.y+t*ly))^2+(mz-(sh.z+t*lz))^2)
    end
    if dist < 64 then utils.execute_after(0, function() if hit_this_tick == globals.tickcount then return end; TriggerAntiBrute() end) end
end)

local misc_clantag_frames = {"m","ma","mad","madr","madri","madril","madrilla","madrilla","madrilla |","madrilla | m","madrilla | ma","madrilla | mad","madrilla | madr","madrilla | madri","madrilla | madril","madrilla | madrill","madrilla | madrilla","madrilla | madrilla","madrilla recode","madrilla recode","madrilla recode","madrilla | madrilla","madrilla | madrill","madrilla | madril","madrilla | madri","madrilla | madr","madrilla | mad","madrilla | ma","madrilla | m","madrilla |","madrilla","madril","madri","madr","mad","ma","m"}
local clantag_last = ""
local function misc_run_clantag()
    if not menu.misc.clantag.enable.value then if clantag_last ~= "" then common.set_clan_tag(""); clantag_last="" end; return end
    local fi = math.floor(globals.tickcount/25) % #misc_clantag_frames + 1
    local f = misc_clantag_frames[fi]
    if f ~= clantag_last then common.set_clan_tag(f); clantag_last=f end
end

local function misc_run_fastladder(cmd)
    if not menu.misc.fastLadder.enable.value then return end
    local lp = entity.get_local_player()
    if not lp or lp.m_MoveType ~= 9 then return end
    if cmd.forwardmove == 0 then return end
    local ln = lp.m_vecLadderNormal
    if not ln then return end
    local lnl = math.sqrt(ln.x^2+ln.y^2)
    if lnl < 0.01 then return end
    local pt = math.deg(math.atan2(ln.z+lnl, lnl-ln.z))
    local ps = cmd.view_angles.x < pt and -1 or 1
    if cmd.forwardmove < 0 then ps = ps * -1 end
    cmd.view_angles.x = 89 * ps
    cmd.view_angles.y = math.deg(math.atan2(ln.x, -ln.y))
    cmd.forwardmove = 450
    cmd.sidemove = 0
end

local misc_smartdrop = { ticks=0, oldPitch=nil, going=false }
local function misc_run_smartdrop(cmd)
    if not menu.misc.smartDrop.enable.value then return end
    local pressed = menu.misc.smartDrop.bind.value
    if pressed and not misc_smartdrop.going then misc_smartdrop.going=true; misc_smartdrop.ticks=0; misc_smartdrop.oldPitch=cmd.view_angles.x; cmd.view_angles.x=0 end
    if misc_smartdrop.going then
        misc_smartdrop.ticks = misc_smartdrop.ticks+1
        if misc_smartdrop.ticks==3 then utils.console_exec("drop") end
        if misc_smartdrop.ticks==6 and misc_smartdrop.oldPitch then cmd.view_angles.x=misc_smartdrop.oldPitch end
        if misc_smartdrop.ticks>6 and not pressed then misc_smartdrop.going=false end
    end
end

local misc_buycmds = { ["-"]="",["scout"]="buy ssg08",["auto"]="buy g3sg1; buy scar20",["awp"]="buy awp",["deagle"]="buy deagle",["armor"]="buy vesthelm",["nades"]="buy molotov; buy incgrenade; buy hegrenade; buy smokegrenade" }
local function misc_run_autobuy()
    if not menu.misc.autoBuy.enable.value then return end
    utils.console_exec(misc_buycmds[menu.misc.autoBuy.primary.value] or "")
    utils.console_exec(misc_buycmds[menu.misc.autoBuy.secondary.value] or "")
    for _,item in pairs(menu.misc.autoBuy.equipment.value) do utils.console_exec(misc_buycmds[item] or "") end
end

events.player_death:set(function(e)
    if not menu.misc.killsay.enable.value then return end
    local lp = entity.get_local_player()
    if entity.get(e.attacker,true)==lp and entity.get(e.userid,true)~=lp then
        utils.console_exec("say madrilla recode > you")
    end
end)

local function ragebot_run_createmove(cmd)
    if not menu.ragebot.ragebotHelper.enable.value then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local target = entity.get_threat(true)
    if not target then return end
    
    if menu.ragebot.ragebotHelper.avoidUnsafeHitboxes.value then rage.override_safepoint(target, true) end
    if menu.ragebot.autoSafepoint.enable.value then
        local opts={}; for _,v in ipairs(menu.ragebot.autoSafepoint.options.value) do opts[v]=true end
        local flags = lp.m_fFlags or 0
        if opts["in air"] and bit.band(flags,1)==0 then rage.override_safepoint(target,true) end
    end
    rage.override_min_damage(target, menu.ragebot.ragebotHelper.minDamage.value)
    rage.override_hitchance(target, menu.ragebot.ragebotHelper.hitChance.value)
    if menu.ragebot.multiDT.enable.value then
        if menu.ragebot.multiDT.key1.value or menu.ragebot.multiDT.key2.value or menu.ragebot.multiDT.key3.value then
            rage.override_double_tap(true)
        end
    end
end

events.round_start:set(function()
    antiaim.OnRoundStart()
    utils.execute_after(0.2, misc_run_autobuy)
end)
events.level_init:set(function() antiaim.OnRoundStart() end)
events.createmove:set(function(cmd)
    if not globals.is_in_game then return end
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    antiaim.OnSetupCommand(cmd)
    misc_run_clantag()
    misc_run_fastladder(cmd)
    misc_run_smartdrop(cmd)
    ragebot_run_createmove(cmd)
end)
events.shutdown:set(function() common.set_clan_tag("") end)

math.randomseed(common.get_unixtime())
print("[madrilla recode] loaded on neverlose via PUI")
common.add_event("[madrilla recode] loaded via PUI", "skull")

