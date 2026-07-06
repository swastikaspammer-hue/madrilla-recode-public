

local l_color_0 = color;

-- Hook Steam Username if available from launcher
local function hook_steam_username()
    local ffi = require("ffi")
    -- We redeclare kernel32 functions carefully so we don't conflict with other parts of the script
    ffi.cdef[[
        typedef void* HANDLE_NL;
        HANDLE_NL __stdcall CreateFileA(const char* lpFileName, uint32_t dwDesiredAccess, uint32_t dwShareMode, void* lpSecurityAttributes, uint32_t dwCreationDisposition, uint32_t dwFlagsAndAttributes, void* hTemplateFile);
        bool __stdcall ReadFile(HANDLE_NL hFile, void* lpBuffer, uint32_t nNumberOfBytesToRead, uint32_t* lpNumberOfBytesRead, void* lpOverlapped);
        bool __stdcall CloseHandle(HANDLE_NL hObject);
        uint32_t __stdcall GetFileSize(HANDLE_NL hFile, uint32_t* lpFileSizeHigh);
        int GetEnvironmentVariableA(const char* lpName, char* lpBuffer, int nSize);
    ]]

    local kernel32 = ffi.load("kernel32")
    local local_app_data_buf = ffi.new("char[260]")
    kernel32.GetEnvironmentVariableA("LOCALAPPDATA", local_app_data_buf, 260)
    
    local appdata_path = ffi.string(local_app_data_buf)
    local file_path = appdata_path .. "\\Programs\\launcher\\resources\\nl_cloud\\steam_username.txt"
    
    local hFile = kernel32.CreateFileA(file_path, 0x80000000, 1, nil, 3, 0x80, nil)
    if hFile == ffi.cast("HANDLE_NL", -1) or hFile == nil then
        return nil
    end
    
    local size = kernel32.GetFileSize(hFile, nil)
    if size == 0 or size > 100 then
        kernel32.CloseHandle(hFile)
        return nil
    end
    
    local buf = ffi.new("char[?]", size + 1)
    local read_bytes = ffi.new("uint32_t[1]")
    local success = kernel32.ReadFile(hFile, buf, size, read_bytes, nil)
    kernel32.CloseHandle(hFile)
    
    if success then
        buf[size] = 0
        local name = ffi.string(buf)
        return name:gsub("[\r\n]", "")
    end
    return nil
end

local steam_username = hook_steam_username()
if steam_username and steam_username ~= "" then
    common.get_username = function()
        return steam_username
    end
end

-- [[ AUTO UPDATER ]]
local M_VERSION = "18/06/2025"
local function check_for_updates()
    local ffi = require("ffi")
    ffi.cdef[[
        void* __stdcall URLDownloadToFileA(void* pCaller, const char* szURL, const char* szFileName, int dwReserved, int lpfnCB);
        bool DeleteUrlCacheEntryA(const char* lpszUrlName);
        int GetEnvironmentVariableA(const char* lpName, char* lpBuffer, int nSize);
        void* __stdcall CreateFileA(const char* lpFileName, uint32_t dwDesiredAccess, uint32_t dwShareMode, void* lpSecurityAttributes, uint32_t dwCreationDisposition, uint32_t dwFlagsAndAttributes, void* hTemplateFile);
        bool __stdcall ReadFile(void* hFile, void* lpBuffer, uint32_t nNumberOfBytesToRead, uint32_t* lpNumberOfBytesRead, void* lpOverlapped);
        bool __stdcall CloseHandle(void* hObject);
        uint32_t __stdcall GetFileSize(void* hFile, uint32_t* lpFileSizeHigh);
        uint32_t __stdcall GetTickCount();
    ]]
    local urlmon = ffi.load("UrlMon")
    local wininet = ffi.load("WinInet")
    local kernel32 = ffi.load("kernel32")
    
    local temp_path_buf = ffi.new("char[260]")
    kernel32.GetEnvironmentVariableA("TEMP", temp_path_buf, 260)
    local version_file = ffi.string(temp_path_buf) .. "\\mdrecode_version.txt"
    
    local version_url = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/version.txt?t=" .. tostring(kernel32.GetTickCount())
    wininet.DeleteUrlCacheEntryA(version_url)
    urlmon.URLDownloadToFileA(nil, version_url, version_file, 0, 0)
    
    local hFile = kernel32.CreateFileA(version_file, 0x80000000, 1, nil, 3, 128, nil)
    if hFile ~= ffi.cast("void*", -1) then
        local size = kernel32.GetFileSize(hFile, nil)
        if size > 0 then
            local buf = ffi.new("char[?]", size + 1)
            local bytesRead = ffi.new("uint32_t[1]")
            if kernel32.Readaile(hFile, buf, size, bytesRead, nil) then
                local remote_version = ffi.string(buf, bytesRead[0]):gsub("%s+", "")
                kernel32.CloseHandle(hFile)
                
                if remote_version ~= M_VERSION and remote_version ~= "" then
                    _G.MADRILLA_UPDATE_AVAILABLE = remote_version
                    print("[Madrilla Recode] A new update (" .. remote_version .. ") is available on the GitHub repository!")
                end
            else
                kernel32.CloseHandle(hFile)
            end
        else
            kernel32.CloseHandle(hFile)
        end
    end
end
local success, err = pcall(check_for_updates)
if not success then
    print("[Auto-Updater Error] " .. tostring(err))
end
-- [[ END AUTO UPDATER ]]
local l_vector_0 = vector;
local l_error_0 = error;
local l_getmetatable_0 = getmetatable;
local l_setmetatable_0 = setmetatable;
local l_ipairs_0 = ipairs;
local l_pairs_0 = pairs;
local l_next_0 = next;
local l_require_0 = require;
local l_type_0 = type;
local l_pcall_0 = pcall;
local function v15(v11)
    -- upvalues: l_next_0 (ref)
    local v12 = {};
    for v13, v14 in l_next_0, v11 do
        v12[v13] = v14;
    end;
    return v12;
end;
serialize = function(v16)
    -- upvalues: l_type_0 (ref)
    local v17 = {};
    local v18 = nil;
    local v19 = nil;
    for v20 = 1, #v16 do
        v18 = v16[v20];
        if l_type_0(v18) == "table" then
            v19 = "{" .. serialize(v18) .. "}";
        else
            v19 = tostring(v18);
        end;
        table.insert(v17, v19);
    end;
    return table.concat(v17, ",");
end;
local function v24(v21)
    -- upvalues: l_setmetatable_0 (ref)
    local v22 = l_setmetatable_0({}, {
        __mode = "kv"
    });
    return function(...)
        -- upvalues: v22 (ref), v21 (ref)
        local v23 = serialize({
            ...
        });
        if not v22[v23] then
            v22[v23] = v21(...);
        end;
        return v22[v23];
    end;
end;
local v25 = v15(math);
local v26 = v15(string);
local v27 = v15(table);
local v28 = v15(ui);
local v29 = v15(render);
local v30 = v15(utils);
local v31 = v15(files);
local v32 = v15(entity);
local v33 = v15(l_require_0("ffi"));
local l_tonumber_0 = tonumber;
local l_tostring_0 = tostring;
local v36 = v24(v26.format);
local v37 = v24(v26.lower);
local v38 = v24(v26.sub);
local v39 = nil;
local _ = -1;
local v41 = "Arial";
local v42 = l_color_0(255);
local _ = l_vector_0(0, 0, 0);
local l_pi_0 = v25.pi;
local v45 = "elite";
local v46 = "18/06/2025";
local v47 = true;
local v48 = {};
local v49 = {};
local v50 = {};
local v51 = {};
local v52 = {};
local v53 = {};
local v54 = {};
local v55 = {};
local v56 = {};
local v57 = {};
local v58 = {};
local _ = {};
local v60 = {};
local v61 = {};
local v62 = {};
local v63 = {};
local v64 = {};
local v65 = {};
local v66 = {};
local v67 = {};
local v68 = {};
local v69 = {};
local v70 = {};
local v71 = {};
local v72 = {};
local v73 = {};
local v74 = {};
local v75 = {};
v33.cdef("\n    \n    typedef void*       HKL;\n    typedef void*       HANDLE;\n\n    typedef wchar_t*    LPWSTR;\n\n    typedef const char* LPCSTR;\n    typedef char*       LPSTR;\n\n    typedef uint32_t    UINT;\n    typedef uint32_t    WPARAM;\n    typedef uint32_t    DWORD;\n\n    typedef int64_t     LPARAM;\n    typedef int64_t     LRESULT;\n\n    typedef uint8_t     BYTE;\n    typedef uint8_t*    PBYTE;\n    typedef uint16_t    WORD;\n    \n    typedef HANDLE      HWND;\n    typedef HANDLE      HINSTANCE;\n    typedef HANDLE      HHOOK;\n\n    typedef int         BOOL;\n    typedef long        LONG;\n    typedef char        CHAR;\n    typedef wchar_t     WCHAR;\n    typedef const WCHAR *LPCWSTR;\n\n    // Typedef data structures\n\n    typedef struct \n    {\n        float x;\n        float y;\n        float z;\n    } vector_t;\n\n    typedef struct \n    {\n        uint8_t r;\n        uint8_t g;\n        uint8_t b;\n        uint8_t a;\n    } color_t;\n\n    typedef struct \n    {\n        char        pad_1[0x14];\n\n        uint32_t    m_order;\n        uint32_t    m_sequence;\n        float       m_prev_cycle;\n        float       m_weight;\n        float       m_weight_delta_rate;\n        float       m_playback_rate;\n        float       m_cycle;\n        void*       m_owner;     \n\n        char        pad_2[0x4];\n    } animation_overlay_t;\n\n    typedef struct\n    {\n        char        pad_1[0x60];\n\n        void*       m_entity;\n        void*       m_active_weapon;\n        void*       m_last_active_weapon;\n        float       m_last_update_time; \n        int         m_last_update_frame; \n        float       m_last_update_increment;\n        float       m_eye_yaw;\n        float       m_eye_pitch;\n        float       m_goal_feet_yaw;\n        float       m_last_feet_yaw;\n        float       m_move_yaw;\n        float       m_last_move_yaw;\n        float       m_lean_amount;\n\n        char        pad_2[0x4];\n\n        float       m_feet_cycle;\n        float       m_move_weight;\n        float       m_move_weight_smoothed;\n        float       m_duck_amount;\n        float       m_hit_ground_cycle;\n        float       m_recrouch_weight;\n        vector_t    m_origin;\n        vector_t    m_last_origin;\n        vector_t    m_velocity; \n        vector_t    m_velocity_normalized; \n        vector_t    m_velocity_normalized_non_zero; \n        float       m_velocity_lenght_2D; \n        float       m_jump_fall_velocity; \n        float       m_speed_normalized; \n        float       m_running_speed; \n        float       m_ducking_speed; \n        float       m_duration_moving; \n        float       m_duration_still; \n        bool        m_on_ground;\n        bool        m_hit_ground_animation;\n\n        char        pad_3[0x2];\n\n        float       m_next_lower_body_yaw_update_time;\n        float       m_duration_in_air;\n        float       m_left_ground_height; \n        float       m_hit_ground_weight;\n        float       m_walk_to_run_transition;\n\n        char        pad_4[0x4];\n\n        float       m_affected_fraction;\n\n        char        pad_5[0x208];\n\n        float       m_min_body_yaw;\n        float       m_max_body_yaw;\n        float       m_min_pitch;\n        float       m_max_pitch;\n        int         m_animset_version;\n    } animation_state_t;\n\n    typedef struct {\n        DWORD vkCode;\n        DWORD scanCode;\n        DWORD flags;\n        DWORD time;\n        DWORD dwExtraInfo;\n    } keybaord_low_level_hook_t; //KBDLLHOOKSTRUCT;\n\n    void* __stdcall URLDownloadToFileA(void* pCaller, const char* szURL, const char* szFileName, int dwReserved, int lpfnCB);\n    bool            DeleteUrlCacheEntryA(const char* lpszUrlName);\n\n    int             GetAsyncKeyState(int vKey);\n\n    int             VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);\n    void*           VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);\n    int             VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);\n\n    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85)\n    // https://learn.microsoft.com/he-il/windows/win32/api/winuser/nf-winuser-setwindowshookexa?redirectedfrom=MSDN\n\n    typedef LRESULT (__stdcall *HOOKPROC)(int code, WPARAM wParam, LPARAM lParam);\n    HINSTANCE       GetModuleHandleA(const char* lpModuleName); // FUCK THE PERSON WHO DESCIDED THAT SHIT\n    //HINSTANCE       GetModuleHandle(const char* lpModuleName);\n    HHOOK           SetWindowsHookExA(int idHook, void* lpfn, HINSTANCE hmod, DWORD dwThreadId);\n    LRESULT         CallNextHookEx(HHOOK hhk, int nCode, WPARAM wParam, LPARAM lParam);\n    BOOL            UnhookWindowsHookEx(HHOOK hhk);\n    DWORD           GetLastError();\n    int             ToUnicodeEx(UINT wVirtKey, UINT wScanCode, const BYTE *lpKeyState, LPWSTR pwszBuff, int cchBuff, UINT wFlags, HKL dwhkl); \n    HKL             GetKeyboardLayout(DWORD idThread);\n    int             GetKeyboardState(PBYTE lpKeyState);\n    \n    int             WideCharToMultiByte(UINT CodePage, DWORD dwFlags, const wchar_t* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, const char* lpDefaultChar, BOOL* lpUsedDefaultChar );\n\n    HWND            GetForegroundWindow();\n    HWND            GetWindowTextA(HWND hWnd, LPSTR lpString, int nMaxCount);\n    HWND            FindWindowA(const char* lpClassName, const char* lpWindowName);\n    bool            FlashWindow(HWND hWnd, bool bInvert);\n");
v33.vector_struct = v33.typeof("vector_t");
v33.libraries = {};
v33.library = function(v76)
    -- upvalues: v33 (ref), l_error_0 (ref), v36 (ref)
    if not v33.libraries[v76] then
        v33.libraries[v76] = v33.load(v76) or l_error_0(v36("Failed to load %s", v76));
    end;
    return v33.libraries[v76];
end;
v33.cast_color = v24(function(v77)
    -- upvalues: v33 (ref)
    local v78 = v33.new("color_t");
    local l_r_0 = v77.r;
    local l_g_0 = v77.g;
    local l_b_0 = v77.b;
    v78.a = v77.a;
    v78.b = l_b_0;
    v78.g = l_g_0;
    v78.r = l_r_0;
    return v78;
end);
local v82 = {};
local v83 = {};
v82.__index = v82;
v48.node = function(v84, v85)
    -- upvalues: l_setmetatable_0 (ref), v82 (ref)
    local v86 = {};
    l_setmetatable_0(v86, v82);
    v86.value = v84;
    v86.next = v85;
    return v86;
end;
v82.get_value = function(v87)
    return v87.value;
end;
v82.get_next = function(v88)
    return v88.next;
end;
v82.set_value = function(v89, v90)
    v89.value = v90;
end;
v82.set_next = function(v91, v92)
    v91.next = v92;
end;
v82.has_next = function(v93)
    -- upvalues: v39 (ref)
    return v93.next ~= v39;
end;
v83.__index = v83;
v48.queue = function()
    -- upvalues: l_setmetatable_0 (ref), v83 (ref), v39 (ref)
    local v94 = {};
    l_setmetatable_0(v94, v83);
    v94.tail = v39;
    v94.first = v39;
    return v94;
end;
v83.insert = function(v95, v96)
    -- upvalues: v48 (ref), v39 (ref)
    local v97 = v48.node(v96);
    if v95.first == v39 then
        v95.first = v97;
    else
        v95.tail:set_next(v97);
    end;
    v95.tail = v97;
end;
v83.remove = function(v98)
    -- upvalues: v39 (ref)
    if v98.first == v39 then
        return v39;
    else
        local v99 = v98.first:get_value();
        v98.first = v98.first:get_next();
        if v98.first == v39 then
            v98.tail = v39;
        end;
        return v99;
    end;
end;
v83.head = function(v100)
    -- upvalues: v39 (ref)
    if v100.first == v39 then
        return v39;
    else
        return v100.first:get_value();
    end;
end;
v83.is_empty = function(v101)
    -- upvalues: v39 (ref)
    return v101.first == v39;
end;
v83.copy = function(v102)
    -- upvalues: v48 (ref), v39 (ref)
    local v103 = v48.queue();
    local l_first_0 = v102.first;
    while l_first_0 ~= v39 do
        v103:insert(l_first_0.get_value(l_first_0));
        l_first_0 = l_first_0.get_next(l_first_0);
    end;
    return v103;
end;
v83.size = function(v105)
    -- upvalues: v39 (ref)
    local v106 = 0;
    local l_first_1 = v105.first;
    while l_first_1 ~= v39 do
        v106 = v106 + 1;
        l_first_1 = l_first_1.get_next(l_first_1);
    end;
    return v106;
end;
v83.to_string = function(v108)
    -- upvalues: v39 (ref), v36 (ref)
    local v109 = "";
    local l_first_2 = v108.first;
    while l_first_2 ~= v39 do
        v109 = v36("%s%s", v109, l_first_2.get_value(l_first_2));
        if l_first_2.has_next(l_first_2) then
            v109 = v36("%s, ", v109);
        end;
        l_first_2 = l_first_2.get_next(l_first_2);
    end;
    return v109;
end;
local v111 = {};
local v112 = {};
v111.active_windows = v48.queue();
v111.NO_ATTACH = 1;
v111.CENTER_ATTACH = 2;
v111.mouse_position = v28.get_mouse_position();
v111.active_mouse_position = v28.get_mouse_position();
v111.is_left_pressed = false;
v111.is_right_pressed = false;
v111.is_holding = v39;
v111.fade_back = 0;
v111.find = function(v113)
    -- upvalues: v111 (ref), v39 (ref)
    local l_first_3 = v111.active_windows.first;
    while true do
        if l_first_3 ~= v39 then
            current_window = l_first_3.get_value(l_first_3);
            if current_window._name == v113 then
                return current_window;
            else
                l_first_3 = l_first_3.get_next(l_first_3);
            end;
        else
            return v39;
        end;
    end;
end;
v111.process = function()
    -- upvalues: v111 (ref), v28 (ref), v29 (ref), l_vector_0 (ref), v50 (ref), l_color_0 (ref), v39 (ref)
    v111.active_mouse_position = v28.get_mouse_position();
    v111.is_left_pressed = common.is_button_down(1);
    v111.is_right_pressed = common.is_button_down(2);
    if not v111.is_left_pressed then
        v111.mouse_position = v28.get_mouse_position();
    end;
    if v111.fade_back > 0 then
        v29.rect(l_vector_0(0, 0), v50.screen_size, l_color_0(0, 150 * v111.fade_back));
    end;
    local l_first_4 = v111.active_windows.first;
    while true do
        if l_first_4 ~= v39 then
            current_window = l_first_4.get_value(l_first_4);
            if current_window and current_window._is_moving then
                v111.fade_back = v29.do_animation(v111.fade_back, 1);
                v111.is_holding = current_window;
                return;
            else
                l_first_4 = l_first_4.get_next(l_first_4);
            end;
        else
            v111.fade_back = v29.do_animation(v111.fade_back, 0);
            v111.is_holding = v39;
            return;
        end;
    end;
end;
v111.is_anything_moving = function()
    -- upvalues: v111 (ref), v39 (ref)
    return v111.is_holding ~= v39;
end;
v112.__index = v112;
v48.window = function(v116, v117, v118, v119)
    -- upvalues: l_setmetatable_0 (ref), v112 (ref), l_vector_0 (ref), v111 (ref)
    local v120 = {};
    l_setmetatable_0(v120, v112);
    v120._name = v116;
    v120._position = v117;
    v120._size = v118;
    v120._fade = 0;
    v120._is_moving = false;
    v120._move_delta = l_vector_0(0, 0);
    v120._attach = v119 or v111.NO_ATTACH;
    v120._is_attach = false;
    v120._render_calls = {};
    v111.active_windows:insert(v120);
    return v120;
end;
v112.set_position = function(v121, v122)
    v121._position = v122;
end;
v112.set_size = function(v123, v124)
    v123._size = v124;
end;
v112.set_fade = function(v125, v126)
    v125._fade = v126;
end;
v112.get_position = function(v127)
    return v127._position;
end;
v112.get_size = function(v128)
    return v128._size;
end;
v112.get_fade = function(v129)
    return v129._fade;
end;
v112.get_name = function(v130)
    return v130._name;
end;
v112.is_used = function(v131)
    return v131._is_using;
end;
v112.is_moving = function(v132)
    return v132._is_moving;
end;
v112.register = function(v133, v134, v135)
    v133[v134] = v135;
end;
v112.__call = function(v136, v137)
    -- upvalues: v39 (ref)
    if v137 == v39 then
        return self;
    else
        return v136[v137];
    end;
end;
v112.__eq = function(v138, v139)
    -- upvalues: l_type_0 (ref)
    if l_type_0(v139) == "string" then
        return v138._name == v139;
    else
        return v138._name == v139._name;
    end;
end;
v112.delete = function(v140)
    -- upvalues: v48 (ref), v111 (ref), l_pairs_0 (ref)
    local v141 = v48.queue();
    while not v111.active_windows:is_empty() do
        local v142 = v111.active_windows:remove();
        if v142:get_name() ~= v140:get_name() then
            v141:insert(v142);
        end;
    end;
    while not v141:is_empty() do
        v111.active_windows:insert(v141:remove());
    end;
    for v143 in l_pairs_0(v140._render_calls) do
        events.render:unset(v140._render_calls[v143]);
    end;
end;
v112.unregisrer_render = function(v144, v145)
    events.render:unset(v144._render_calls[v145]);
end;
v112.fade = function(v146, v147)
    -- upvalues: v29 (ref)
    v146._fade = v29.do_animation(v146._fade, v147);
end;
v112.register_render = function(v148, v149, v150)
    -- upvalues: v49 (ref), v39 (ref)
    protect = v49.safe_mode == v39 or v49.safe_mode or true;
    local v151 = protect and v49.protected_call(function()
        -- upvalues: v149 (ref), v148 (ref)
        v149(v148);
    end, v150) or v149;
    events.render:set(v151);
    v148._render_calls[v150] = v151;
end;
v112.override_position = function(v152, v153)
    -- upvalues: v28 (ref), v111 (ref), v51 (ref), v25 (ref), v30 (ref), v50 (ref)
    if v152._fade ~= 1 or v28.get_alpha() ~= 1 then
        return;
    else
        if v111.is_left_pressed and v111.mouse_position:is_in_bounds(v152._position, v153) and not v111.is_anything_moving() and not v51.use_element then
            v152._is_moving = true;
            v152._move_delta.x = v152._position.x - v111.active_mouse_position.x;
            v152._move_delta.y = v152._position.y - v111.active_mouse_position.y;
        end;
        if not v111.is_left_pressed and v152._is_moving then
            v152._is_moving = false;
        end;
        if v152._is_moving then
            v152._position.x = v25.floor(v152._move_delta.x + v111.active_mouse_position.x);
            if not v30.is_virtual_key_pressed(16) then
                v152._position.y = v25.floor(v152._move_delta.y + v111.active_mouse_position.y);
            end;
        end;
        if v152._attach == v111.CENTER_ATTACH then
            if v25.abs(v50.screen_size.x / 2 - (v152._position.x + v153.x / 2)) < 50 then
                v152._position.x = v50.screen_size.x / 2 - v153.x / 2;
                v152._is_attach = true;
            else
                v152._is_attach = false;
            end;
        end;
        return;
    end;
end;
local v154 = nil;
v154 = {
    color_print = v30.get_vfunc("vstdlib.dll", "VEngineCvar007", 25, "void(__cdecl*)(void*, const color_t&, const char*, ...)"), 
    does_file_exist = v30.get_vfunc("filesystem_stdio.dll", "VBaseFileSystem011", 10, "bool(__thiscall*)(void*, const char*, const char*)"), 
    is_console_open = v30.get_vfunc("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)"), 
    play_sound = v30.get_vfunc("engine.dll", "IEngineSoundClient003", 12, "void*(__thiscall*)(void*, const char*, float, int, int, float)"), 
    find_material_by_name = v30.get_vfunc("materialsystem.dll", "VMaterialSystem080", 84, "void*(__thiscall*)(void*, const char*, const char*, bool, const char*)"), 
    sparks = v30.get_vfunc("client.dll", "IEffects001", 3, "void(__thiscall*)(void*, vector_t&, int, int, vector_t&)"), 
    get_clipboard_textcount = v30.get_vfunc("vgui2.dll", "VGUI_System010", 7, "int(__thiscall*)(void*)"), 
    set_clipboard_text = v30.get_vfunc("vgui2.dll", "VGUI_System010", 9, "void(__thiscall*)(void*, const char*, int)"), 
    get_clipboard_text_fn = v30.get_vfunc("vgui2.dll", "VGUI_System010", 11, "void(__thiscall*)(void*, int, const char*, int)"), 
    get_material_name = v30.get_vfunc(0, "const char*(__thiscall*)(void*)"), 
    alpha_modulate = v30.get_vfunc(27, "void(__thiscall*)(void*, float)"), 
    color_modulate = v30.get_vfunc(28, "void(__thiscall*)(void*, float, float, float)"), 
    set_flag = v30.get_vfunc(29, "void(__thiscall*)(void*, int, const bool)"), 
    get_attachment = v30.get_vfunc(84, "bool(__thiscall*)(void*, int, vector_t&)"), 
    get_attachment_index_1 = v30.get_vfunc(468, "int(__thiscall*)(void*, void*)"), 
    get_attachment_index_3 = v30.get_vfunc(469, "int(__thiscall*)(void*)")
};
local _ = print;
print = function(...)
    -- upvalues: v39 (ref), v42 (ref), v154 (ref), v33 (ref), l_tostring_0 (ref)
    local v156 = {
        ...
    };
    for v157 = 1, #v156, 2 do
        local v158 = v156[v157];
        local v159 = v156[v157 + 1];
        if v159 == v39 then
            v159 = v42;
        end;
        v154.color_print(v33.cast_color(v159), l_tostring_0(v158));
    end;
    v154.color_print(v33.cast_color(v42), "\n");
end;
local function v162(v160)
    -- upvalues: l_type_0 (ref), v37 (ref)
    local v161 = l_type_0(v160);
    if v161 == "userdata" and v160.__type then
        return v37(v160.__type.name);
    else
        return v161;
    end;
end;
local v163 = {
    _color = l_getmetatable_0(l_color_0()), 
    _vector = l_getmetatable_0(l_vector_0())
};
v163._color.override = function(v164, v165)
    return v164:alpha_modulate(v164.a * v165);
end;
v163._color.modulate = function(v166, v167)
    return v166:alpha_modulate(v166.a * v167 / 255);
end;
v163._vector.is_in_bounds = function(v168, v169, v170)
    if v168.x < v169.x or v168.x > v169.x + v170.x then
        return false;
    elseif v168.y < v169.y or v168.y > v169.y + v170.y then
        return false;
    else
        return true;
    end;
end;
v163._vector.calculate_angle = function(v171, v172)
    -- upvalues: v25 (ref), l_pi_0 (ref)
    local v173 = v25.atan((v171.y - v172.y) / (v171.x - v172.x));
    v173 = v25.normalize_yaw(v173 * 180 / l_pi_0);
    if v171.x - v172.x >= 0 then
        v173 = v25.normalize_yaw(v173 + 180);
    end;
    return v173;
end;
v163._vector.exterpolate = function(v174, v175, v176)
    return v174 + v175 * (globals.tickinterval * v176);
end;
v25.lerp = function(v177, v178, v179, v180)
    -- upvalues: v25 (ref)
    if v177 == v178 then
        return v178;
    else
        local v181 = (v178 - v177) * v179 + v177;
        if not v180 then
            v180 = 0.01;
        end;
        if v25.abs(v181 - v178) < v180 then
            return v178;
        else
            return v181;
        end;
    end;
end;
v25.clamp = v24(function(v182, v183, v184)
    if v182 < v183 then
        return v183;
    elseif v184 < v182 then
        return v184;
    else
        return v182;
    end;
end);
v25.to_int = v24(function(v185)
    -- upvalues: l_tostring_0 (ref), l_tonumber_0 (ref)
    local v186 = l_tostring_0(v185);
    local v187, _ = v186:find("%.");
    if v187 then
        return l_tonumber_0(v186:sub(1, v187 - 1));
    else
        return v185;
    end;
end);
v25.normalize_yaw = v24(function(v189)
    while v189 > 180 do
        v189 = v189 - 360;
    end;
    while v189 < -180 do
        v189 = v189 + 360;
    end;
    return v189;
end);
v27.clear = function(v190)
    -- upvalues: l_pairs_0 (ref), v39 (ref)
    for v191 in l_pairs_0(v190) do
        v190[v191] = v39;
    end;
end;
original_table_concat = v27.concat;
v27.concat = function(v192, v193)
    -- upvalues: l_type_0 (ref), l_tostring_0 (ref)
    if l_type_0(v192) == "table" then
        return original_table_concat(v192, v193);
    else
        return l_tostring_0(v192);
    end;
end;
v27.find = function(v194, v195)
    -- upvalues: l_pairs_0 (ref), v39 (ref)
    for v196, v197 in l_pairs_0(v194) do
        if v195 == v197 then
            return v196;
        end;
    end;
    return v39;
end;
v27.delete = function(v198, v199)
    -- upvalues: v27 (ref)
    local v200 = v27.find(v198, v199);
    if v200 then
        v27.remove(v198, v200);
    end;
end;
v27.reverse = function(v201)
    -- upvalues: v39 (ref)
    local v202 = {};
    if v201 == v39 then
        return v202;
    else
        for v203 = #v201, 1, -1 do
            v202[#v202 + 1] = v201[v203];
        end;
        return v202;
    end;
end;
v29.loaded_fonts = {};
v29.load_fonts = {};
v29.animation_cache = {};
v29.measures_cache = l_setmetatable_0({}, {
    __mode = "kv"
});
v29.animation_speed = 10;
v29.last_error = "";
v29.low_preformance = false;
v29.original = {
    load_font = v29.load_font, 
    measure_text = v29.measure_text, 
    text = v29.text, 
    blur = v29.blur
};
v29.blurs_options = {
    high = function(v204, v205, v206, v207, v208)
        -- upvalues: v29 (ref)
        v29.original.blur(v204, v205, v206, v207, v208);
    end, 
    low = function(_, _, _, _, _)

    end
};
v29.do_animation = function(v214, v215, v216, v217)
    -- upvalues: v29 (ref), v25 (ref)
    if not v217 then
        v217 = v29.animation_speed;
    end;
    return v25.lerp(v214, v215, globals.frametime * v217, v216);
end;
v29.do_vector_animation = function(v218, v219, v220)
    -- upvalues: v29 (ref)
    v218.x = v29.do_animation(v218.x, v219.x, v220);
    v218.y = v29.do_animation(v218.y, v219.y, v220);
    v218.z = v29.do_animation(v218.z, v219.z, v220);
    return v218;
end;
v29.do_color_animation = function(v221, v222, v223)
    -- upvalues: l_color_0 (ref), v29 (ref)
    local v224 = l_color_0();
    v224.r = v29.do_animation(v221.r, v222.r, v223);
    v224.g = v29.do_animation(v221.g, v222.g, v223);
    v224.b = v29.do_animation(v221.b, v222.b, v223);
    v224.a = v29.do_animation(v221.a, v222.a, v223);
    return v224;
end;
v29.get_animation_value = function(v225)
    -- upvalues: v29 (ref)
    return v29.animation_cache[v225] or 0;
end;
v29.create_animation = function(v226, v227)
    -- upvalues: v29 (ref)
    if not v29.animation_cache[v226] then
        v29.animation_cache[v226] = v227;
    end;
end;
v29.preform_animation = function(v228, v229, v230, v231)
    -- upvalues: v162 (ref), v29 (ref)
    local v232 = v162(v229);
    if not v29.animation_cache[v228] then
        if v232 == "number" then
            v29.animation_cache[v228] = 0;
        else
            v29.animation_cache[v228] = v229;
        end;
    end;
    if v232 == "number" then
        v29.animation_cache[v228] = v29.do_animation(v29.animation_cache[v228], v229, v230, v231);
    elseif v232 == "imcolor" then
        v29.animation_cache[v228] = v29.do_color_animation(v29.animation_cache[v228], v229, v230);
    elseif v232 == "vector" then
        v29.animation_cache[v228] = v29.do_vector_animation(v29.animation_cache[v228], v229, v230);
    end;
    return v29.animation_cache[v228];
end;
v29.clear_cache = function()
    -- upvalues: v27 (ref), v29 (ref)
    v27.clear(v29.animation_cache);
end;
v29.switch_preformance = function()
    -- upvalues: v29 (ref)
    v29.low_preformance = not v29.low_preformance;
    local v233 = v29.low_preformance and "low" or "high";
    v29.blur = v29.blurs_options[v233];
end;
v29.load_font = function(v234, v235, v236, v237)
    -- upvalues: v29 (ref), v39 (ref)
    v29.loaded_fonts[v234] = false;
    v29.load_fonts[#v29.load_fonts + 1] = {
        _name = v234, 
        _size = v235, 
        _data = v236, 
        _other_font = v237 or v39
    };
end;
v29.font = function(v238)
    -- upvalues: v29 (ref)
    return v29.loaded_fonts[v238];
end;
v29.measure_text = function(v239, v240, v241)
    -- upvalues: v36 (ref), v29 (ref)
    local v242 = v36("%s>>%s", v239, v241);
    if not v29.measures_cache[v242] or v29.measures_cache[v242].x == 0 then
        local v243 = v29.original.measure_text(v29.font(v239), v240, v241);
        v29.measures_cache[v242] = v243;
    end;
    return v29.measures_cache[v242];
end;
v29.text = function(v244, v245, v246, v247, v248)
    -- upvalues: v29 (ref)
    v29.original.text(v29.font(v244), v245, v246, v247, v248);
end;
v29.initialize_fonts = function()
    -- upvalues: v29 (ref), v41 (ref), v36 (ref), v27 (ref)
    for v249 = 1, #v29.load_fonts do
        local v250 = v29.load_fonts[v249];
        local v251 = v250._other_font or v41;
        v29.loaded_fonts[v250._name] = v29.original.load_font(v251, v250._size, v250._data);
        if not v29.loaded_fonts[v250._name] then
            v29.last_error = v36("Failed to load %s for %s", v251, v250._name);
            return false;
        end;
    end;
    v27.clear(v29.load_fonts);
    return true;
end;
v26.wrap_text = v24(function(v252, v253, v254)
    -- upvalues: l_ipairs_0 (ref), v36 (ref), v29 (ref), v39 (ref), v27 (ref)
    local v255 = {};
    local v256 = {};
    local v257 = "";
    for v258 in v252:gmatch("%S+") do
        v256[#v256 + 1] = v258;
    end;
    for _, v260 in l_ipairs_0(v256) do
        local v261 = v36("%s%s ", v257, v260);
        if v253 < v29.measure_text(v254, v39, v261).x then
            v255[#v255 + 1] = v257;
            v257 = v36("%s ", v260);
        else
            v257 = v261;
        end;
    end;
    v255[#v255 + 1] = v257;
    return v27.concat(v255, "\n");
end);
v26.fixed_number = v24(function(v262, v263)
    -- upvalues: l_type_0 (ref), l_error_0 (ref), v36 (ref)
    if l_type_0(v262) ~= "number" then
        l_error_0("Number must be a number dumbass");
    end;
    local v264 = "%0" .. v263 .. "d";
    return v36(v264, v262);
end);
v26.clear_color_codes = function(v265)
    -- upvalues: v26 (ref)
    if v26.find(v265, "\aDEFAULT") then
        v265 = v26.gsub(v265, "\aDEFAULT", "");
    end;
    if v26.find(v265, "\a") then
        v265 = v26.sub(v265, 1, v26.find(v265, "\a") - 1) .. v26.sub(v265, v26.find(v265, "\a") + 9);
    end;
    return v265;
end;
v26.clear = function(v266)
    -- upvalues: v26 (ref)
    local v267 = "";
    local v268 = false;
    for v269 = 1, #v266 do
        local v270 = v266:sub(v269, v269);
        if v26.byte(v270) == 0 then
            v268 = true;
        elseif not v268 then
            v267 = v267 .. v270;
        else
            break;
        end;
    end;
    return v267;
end;
v26.remove_last_char = function(v271)
    -- upvalues: v26 (ref)
    local v272 = #v271;
    if v272 == 0 then
        return "";
    else
        local l_v272_0 = v272;
        while true do
            if l_v272_0 > 0 then
                local v274 = v26.byte(v271, l_v272_0);
                if v274 < 128 then
                    return v26.sub(v271, 1, l_v272_0 - 1);
                elseif v274 >= 128 and v274 < 192 then
                    l_v272_0 = l_v272_0 - 1;
                else
                    return v26.sub(v271, 1, l_v272_0 - 1);
                end;
            else
                return "";
            end;
        end;
    end;
end;
v30.csgo_hwnd = v39;
v30.download_file = function(v275, v276)
    -- upvalues: v33 (ref), v39 (ref)
    v33.library("WinInet").DeleteUrlCacheEntryA(v275);
    v33.library("UrlMon").URLDownloadToFileA(v39, v275, v276, 0, 0);
end;
v30.file_exists = function(v277)
    -- upvalues: v154 (ref), v39 (ref)
    return v154.does_file_exist(v277, v39) or false;
end;
v30.is_virtual_key_pressed = function(v278)
    -- upvalues: v33 (ref)
    v33.C.GetAsyncKeyState(v278);
    return v33.C.GetAsyncKeyState(v278) ~= 0;
end;
v30.wide_char_to_multi_byte_string = function(v279)
    -- upvalues: v33 (ref), v39 (ref)
    local v280 = v33.C.WideCharToMultiByte(65001, 0, v279, -1, v39, 0, v39, v39);
    local v281 = v33.new("char[?]", v280);
    v33.C.WideCharToMultiByte(65001, 0, v279, -1, v281, v280, v39, v39);
    return v33.string(v281);
end;
v30.can_hit = function(v282, v283)
    -- upvalues: v32 (ref), v30 (ref)
    if not v283 then
        v283 = 1;
    end;
    local v284 = v32.get_local_player();
    local v285 = v284:get_eye_position():exterpolate(v284.m_vecVelocity, 2);
    local v286 = {
        [1] = 3, 
        [2] = 4, 
        [3] = 5, 
        [4] = 6, 
        [5] = 7, 
        [6] = 1
    };
    for v287 = 1, #v286 do
        local v288 = v282:get_hitbox_position(v286[v287]);
        if v283 < v30.trace_bullet(v284, v285, v288) then
            return true;
        end;
    end;
    return false;
end;
v30.get_worst_damage = function(v289, v290)
    -- upvalues: v30 (ref), v25 (ref)
    local v291 = v289:get_eye_position();
    local v292 = v291:exterpolate(v289.m_vecVelocity, 3);
    local v293 = v30.trace_bullet(v289, v291, v290);
    local v294 = v30.trace_bullet(v289, v292, v290);
    return v25.max(v293, v294);
end;
v30.get_window_text = function(v295)
    -- upvalues: v33 (ref)
    local v296 = v33.new("char[?]", 256);
    v33.C.GetWindowTextA(v295, v296, 256);
    return v33.string(v296);
end;
v30.is_csgo_selected = function()
    -- upvalues: v33 (ref), v30 (ref)
    local v297 = v33.C.GetForegroundWindow();
    return v30.get_window_text(v297) == v30.get_window_text(v30.csgo_hwnd);
end;
v30.flash_icon = function()
    -- upvalues: v30 (ref), v33 (ref)
    if not v30.csgo_hwnd then
        return;
    else
        v33.C.FlashWindow(v30.csgo_hwnd, true);
        return;
    end;
end;
v30.can_fire = function(v298)
    -- upvalues: v32 (ref)
    if not v298 or not v298:is_alive() then
        return false;
    else
        local v299 = v298:get_player_weapon();
        if not v299 then
            return false;
        else
            local v300 = v32.get_game_rules();
            if not v300 then
                return false;
            elseif v300.m_bFreezePeriod then
                return false;
            else
                local l_curtime_0 = globals.curtime;
                if l_curtime_0 < v298.m_flNextAttack then
                    return false;
                elseif l_curtime_0 < v299.m_flNextPrimaryAttack then
                    return false;
                else
                    return true;
                end;
            end;
        end;
    end;
end;
v30.get_clipboard = function()
    -- upvalues: v154 (ref), v33 (ref), v47 (ref)
    local v302 = v154.get_clipboard_textcount();
    if v302 > 0 then
        local v303 = v33.new("char[?]", v302);
        v154.get_clipboard_text_fn(0, v303, v302);
        local v304 = v33.string(v303, v302 - 1);
        if v47 then
            print(#v304);
        end;
        return v304;
    else
        return "";
    end;
end;
v30.set_clipboard = function(v305)
    -- upvalues: v154 (ref)
    if v305 then
        v154.set_clipboard_text(v305, v305:len());
    end;
end;
v163 = nil;
v163 = {
    execute = function(v306, v307)
        -- upvalues: v26 (ref)
        local v308 = "";
        for v309 = 1, #v306 do
            local v310 = v26.sub(v306, v309, v309);
            xor_byte = v26.byte(v310) + v307;
            v308 = v308 .. v26.char(xor_byte);
        end;
        return v308;
    end
};
local v311 = common.get_game_directory();
v31.full_path = v36("%s\\%s\\", v311, "MadrillaRecode");
v31.last_error = "";
v31.default_config = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Files/Config1.Madrilla";
v31.icons_list = {
    ["check.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/check.png", 
    ["tuning.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/tuning.png", 
    ["data.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/data.png", 
    ["sun.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/sun.png", 
    ["rotate.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/rotate.png", 
    ["fire.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/fire.png", 
    ["home.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/home.png", 
    ["location.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/location.png", 
    ["cloud.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/cloud.png", 
    ["unk_rotate.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/unk_rotate.png", 
    ["headshot.svg"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/headshot.svg", 
    ["radar.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/radar.png", 
    ["armor.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/armor.png", 
    ["blind.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/blind.png", 
    ["health.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/health.png", 
    ["bullet.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/bullet.png", 
    ["search.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/search.png", 
    ["arrow.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/arrow.png", 
    ["keyboard.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/keyboard.png", 
    ["warning.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/warning.png", 
    ["color.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/color.png", 
    ["load.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/load.png", 
    ["check_list.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/check_list.png", 
    ["save.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/save.png", 
    ["close.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/close.png",
    ["18plus.png"] = "https://raw.githubusercontent.com/swastikaspammer-hue/mdrecode-assets/main/Files/Icons/18plus.png"
};
v31.sounds_list = {
    ["Tec-9.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/Tec-9.wav", 
    ["R8 Revolver.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/R8%20Revolver.wav", 
    ["USP-S.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/USP-S.wav", 
    ["menu_load.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/menu_load.wav", 
    ["G3SG1.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/G3SG1.wav", 
    ["fast_press.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/fast_press.wav", 
    ["AWP.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/AWP.wav", 
    ["woosh.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/woosh.wav", 
    ["Desert Eagle.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/Desert%20Eagle.wav", 
    ["ui_click.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/ui_click.wav", 
    ["Five-SeveN.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/Five-SeveN.wav", 
    ["error.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/error.wav", 
    ["SSG 08.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/SSG%2008.wav", 
    ["SCAR-20.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/SCAR-20.wav",
    ["weap_cheytac_slmn_short_44k_mono.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_cheytac_slmn_short_44k_mono.wav",
    ["weap_usps_sup_loud_44k_mono.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_usps_sup_loud_44k_mono.wav",
    ["weap_p2000_loud_44k_mono_v2.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_p2000_loud_44k_mono_v2.wav",
    ["weap_glock_loud_44k_mono_v2.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_glock_loud_44k_mono_v2.wav",
    ["weap_p2000_1911_44k_mono.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_p2000_1911_44k_mono.wav",
    ["weap_glock_loud_44k_mono.wav"] = "https://github.com/swastikaspammer-hue/mdrecode-assets/raw/main/Old_Files/MadrillaSounds/weap_glock_loud_44k_mono.wav"
};
local function v315(v312, v313)
    -- upvalues: v36 (ref), v31 (ref), v30 (ref)
    local v314 = v36("%s%s\\%s", v31.full_path, "Icons", v312);
    if not v313 and v30.file_exists(v314) then
        return;
    else
        assert(v31.icons_list[v312], "Invalid Icon Index");
        v30.download_file(v31.icons_list[v312], v314);
        return;
    end;
end;
do
    local l_v311_0, l_v315_0 = v311, v315;
    local function v321(v318, v319)
        -- upvalues: v36 (ref), l_v311_0 (ref), v30 (ref), v31 (ref)
        local v320 = v36("%s\\%s\\%s", l_v311_0, "sound\\MadrillaSounds", v318);
        if not v319 and v30.file_exists(v320) then
            return;
        else
            assert(v31.sounds_list[v318], "Invalid Sound Index");
            v30.download_file(v31.sounds_list[v318], v320);
            return;
        end;
    end;
    v31.load_icon = function(v322, v323)
        -- upvalues: v36 (ref), v31 (ref), v30 (ref), v39 (ref), v29 (ref)
        local v324 = v36("%s%s\\%s", v31.full_path, "Icons", v322);
        if not v30.file_exists(v324) then
            return v39;
        else
            return {
                img = v29.load_image_from_file(v324, v323), 
                size = v323
            };
        end;
    end;
    v31.initialize_icons = function()
        -- upvalues: v31 (ref), l_pcall_0 (ref), l_pairs_0 (ref), l_v315_0 (ref), v36 (ref), v30 (ref)
        v31.create_folder("csgo\\MadrillaRecode");
        v31.create_folder("csgo\\MadrillaRecode\\Icons");
        v31.create_folder("csgo\\MadrillaRecode\\Configs");
        local v328, v329 = l_pcall_0(function()
            -- upvalues: l_pairs_0 (ref), v31 (ref), l_v315_0 (ref), v36 (ref), v30 (ref)
            for v325, _ in l_pairs_0(v31.icons_list) do
                l_v315_0(v325, false);
                local v327 = v36("%s%s\\%s", v31.full_path, "Icons", v325);
                if not v30.file_exists(v327) then
                    v31.last_error = v36("Failed to download / find the file %s", v325);
                    return false;
                end;
            end;
            return true;
        end);
        return v328 and v329;
    end;
    v31.initialize_sounds = function(_)
        -- upvalues: v31 (ref), l_pcall_0 (ref), l_pairs_0 (ref), v321 (ref), v36 (ref), l_v311_0 (ref), v30 (ref)
        v31.create_folder("csgo\\sound\\MadrillaSounds");
        local v334, v335 = l_pcall_0(function()
            -- upvalues: l_pairs_0 (ref), v31 (ref), v321 (ref), v36 (ref), l_v311_0 (ref), v30 (ref)
            for v331, _ in l_pairs_0(v31.sounds_list) do
                v321(v331, false);
                local v333 = v36("%s\\%s\\%s", l_v311_0, "sound\\MadrillaSounds", v331);
                if not v30.file_exists(v333) then
                    v31.last_error = v36("Failed to download / find the file %s", v331);
                    return false;
                end;
            end;
            return true;
        end);
        return v334 and v335;
    end;
    v31.initialize_configs = function(_)
        -- upvalues: v30 (ref), v36 (ref), v31 (ref)
        for v337 = 1, 8 do
            if not v30.file_exists(v36("%sConfigs\\Config%d.Madrilla", v31.full_path, v337)) and not v31.write(v36("csgo\\MadrillaRecode\\Configs\\Config%d.Madrilla", v337), "?") then
                return false;
            end;
        end;
        if not v30.file_exists(v31.full_path .. "Configs\\AutoSave.Madrilla") and not v31.write("csgo\\MadrillaRecode\\Configs\\AutoSave.Madrilla", "?") then
            return false;
        else
            return true;
        end;
    end;
end;
v49.ignored_methods = {};
v49.low_level_keyboard_event = {};
v49.keyboard_handle = v39;
v49.safe_mode = (db._MadrillaRecode_SafeModeHook or {
    is = true
}).is;
v49.new = function(_, _, _, _)

end;
v315 = function(v342, v343, v344)
    -- upvalues: v49 (ref), v33 (ref), v39 (ref)
    if v342 >= 0 then
        for v345 = 1, #v49.low_level_keyboard_event do
            local v346 = v49.low_level_keyboard_event[v345];
            if v346 and v346(v342, v343, v344) == true then
                return 1;
            end;
        end;
    end;
    return v33.C.CallNextHookEx(v39, v342, v343, v344);
end;
v49.protected_call = function(v347, v348)
    -- upvalues: v49 (ref), l_pcall_0 (ref), v154 (ref), v31 (ref), v163 (ref), l_color_0 (ref), v42 (ref), v47 (ref)
    return function(...)
        -- upvalues: v49 (ref), v348 (ref), l_pcall_0 (ref), v347 (ref), v154 (ref), v31 (ref), v163 (ref), l_color_0 (ref), v42 (ref), v47 (ref)
        if v49.ignored_methods[v348] then
            return;
        else
            local v349, v350 = l_pcall_0(v347, ...);
            if not v349 then
                v49.ignored_methods[v348] = true;
                v154.play_sound("MadrillaSounds/error.wav", 1, 100, 0, 0);
                v31.write("csgo\\MadrillaRecode\\ErrorLog.Madrilla", v163.execute(v350, 11));
                local v351 = l_color_0(255, 10, 10, 255);
                print("  Madrilla  \194\183 ", v351, "looks like some error occurred in ", v42, v348, v351, ".\nPlease contact the lua developer in discord server via tickets and provide the next file ", v42, "ErrorLog.Madrilla", v351, " that is located in \n", v42, v31.full_path, v351);
                if true then
                    print(v350);
                end;
                return;
            else
                return v350;
            end;
        end;
    end;
end;
v49.attach = function(v352, v353, v354)
    -- upvalues: v49 (ref)
    protect = v49.safe_mode;
    if v352 == "low_level_keyboard" then
        v49.low_level_keyboard_event[#v49.low_level_keyboard_event + 1] = v49.protected_call(v353, v354);
        return;
    else
        local v355 = protect and v49.protected_call(v353, v354) or v353;
        events[v352]:set(v355);
        return;
    end;
end;
v49.destroy = function()
    -- upvalues: v49 (ref), v33 (ref)
    if v49.keyboard_handle then
        v33.C.UnhookWindowsHookEx(v49.keyboard_handle);
    end;
end;
do
    local l_v315_1 = v315;
    v49.initialize = function()
        -- upvalues: v49 (ref), v33 (ref), l_v315_1 (ref), v39 (ref), v47 (ref)
        v49.keyboard_handle = v33.C.SetWindowsHookExA(13, v33.cast("HOOKPROC", l_v315_1), v33.cast("void*", 0), 0);
        if not v33.istype("void*", v49.keyboard_handle) then
            v49.keyboard_handle = v39;
            if v47 then
                print(v33.C.GetLastError());
            end;
            return false;
        else
            v49.attach("shutdown", v49.destroy, "lua::hooks::destroy");
            return true;
        end;
    end;
end;
v50.selected_theme = "black";
v50.screen_size = v29.screen_size();
v50.default_round = 8;
v29.load_font("theme::font", 16, "ad");
v29.load_font("theme::high", l_vector_0(20, 20, 1), "ad");
v29.load_font("theme::low", l_vector_0(14, 14, 1), "ad");
v29.load_font("manuals::arrows", l_vector_0(30, 25, 1), "ad");
v50.colors = {
    accent = l_color_0(150, 150, 255, 255), 
    background = l_color_0(10, 10, 30, 100), 
    outline = l_color_0(100, 100), 
    on_hover = l_color_0(39, 39, 42, 255), 
    text = l_color_0(247, 247, 247, 255)
};
v50.render_background = function(v357, v358, v359, v360)
    -- upvalues: v50 (ref), v29 (ref)
    if not v360 then
        v360 = v50.default_round;
    end;
    v29.blur(v357, v358, 1, v359, v360);
    v29.rect(v357, v358, v50.colors.background:override(v359), v360);
end;
v50.render_card = function(v361, v362, v363, v364, v365)
    -- upvalues: v50 (ref), v29 (ref)
    if not v365 then
        v365 = 0.3;
    end;
    if not v364 then
        v364 = v50.default_round;
    end;
    local v366 = v50.colors.outline:override(0);
    local v367 = v50.colors.outline:override(v363 * v365);
    v29.gradient(v361, v362, v366, v367, v366, v367, v364);
end;
v50.render_outline = function(v368, v369, v370, v371)
    -- upvalues: v50 (ref), v29 (ref)
    if not v371 then
        v371 = v50.default_round;
    end;
    v29.rect_outline(v368, v369, v50.colors.outline:override(v370), 1, v371);
end;
v50.render_accent = function(v372, v373, v374, v375, v376)
    -- upvalues: v50 (ref), v29 (ref)
    if not v375 then
        v375 = v50.default_round;
    end;
    if not v376 then
        v376 = v50.colors.accent;
    end;
    v29.shadow(v372, v373, v376.override(v376, v374), 40, 0, v375);
    v29.rect(v372, v373, v376.override(v376, v374), v375);
end;
v50.render_half_outline = function(v377, v378, v379, v380, v381)
    -- upvalues: v50 (ref), v29 (ref), l_vector_0 (ref)
    if not v381 then
        v381 = 0.3;
    end;
    if not v380 then
        v380 = v50.default_round;
    end;
    local v382 = v50.colors.outline:override(0);
    local v383 = v50.colors.outline:override(v379);
    local v384 = v50.colors.outline:override(v379 * v381);
    v29.gradient(v377, v378, v382, v384, v382, v384, v380);
    local v385 = (v378.x - v377.x) * 0.5;
    v29.push_clip_rect(l_vector_0(v377.x + v385, v377.y), v378);
    v50.render_outline(v377, v378, v379, v380);
    v29.pop_clip_rect();
    v29.gradient(v377, v377 + l_vector_0(v385, 1), v382, v383, v382, v383);
    v29.gradient(l_vector_0(v377.x, v378.y - 1), l_vector_0(v377.x + v385, v378.y), v382, v383, v382, v383);
end;
v50.render_text = function(v386, v387, v388, v389, ...)
    -- upvalues: v29 (ref), v50 (ref)
    v29.text(v386, v387, v50.colors.text:override(v388), v389, ...);
end;
v50.preform_colors = function()
    -- upvalues: v50 (ref), v51 (ref), v29 (ref)
    local _ = v50[v50.selected_theme];
    v50.colors.accent = v51.get("theme_accent");
    v50.colors.background = v51.get("theme_background");
    v50.screen_size = v29.screen_size();
end;
v311 = nil;
v311 = {
    active = v48.queue(), 
    temp = v48.queue(), 
    pad = 0, 
    screen = v29.screen_size()
};
v311.add = function(v391, v392)
    -- upvalues: v311 (ref)
    v311.active:insert({
        alpha = 0, 
        text = v391, 
        icon = v392, 
        time = globals.realtime
    });
end;
v311.render = function()
    -- upvalues: v311 (ref), v29 (ref), v39 (ref), l_vector_0 (ref), v25 (ref), v50 (ref), l_color_0 (ref)
    v311.pad = 0;
    if v311.active:is_empty() then
        return;
    else
        while not v311.active:is_empty() do
            local v393 = v311.active:remove();
            local v394 = v393.time + 5 > globals.realtime;
            v393.alpha = v29.do_animation(v393.alpha, v394 and 1 or 0, false);
            if v394 or v393.alpha ~= 0 then
                v311.temp:insert(v393);
            end;
            local v395 = v29.measure_text("theme::font", v39, v393.text);
            local v396 = l_vector_0(v395.x + 60 + 40, 60);
            local v397 = 50 * v25.abs(v393.alpha - 1);
            local v398 = l_vector_0(v311.screen.x / 2 - v396.x / 2 + v397, 20 + v311.pad * 90);
            local v399 = l_vector_0(v311.screen.x / 2 + v396.x / 2 + v397, v398.y + v396.y);
            v50.render_background(v398, v399, v393.alpha);
            if v393.icon then
                v29.texture(v393.icon.img, v398 + l_vector_0(20, 10), v393.icon.size, l_color_0(255, 180 * v393.alpha));
            end;
            v50.render_text("theme::font", v398 + l_vector_0(80, 30 - v395.y / 2), v393.alpha, v39, v393.text);
            v311.pad = v311.pad + v393.alpha;
        end;
        while not v311.temp:is_empty() do
            v311.active:insert(v311.temp:remove());
        end;
        return;
    end;
end;
v51.window = v48.window("lua::ui::main_window", l_vector_0(100, 100), l_vector_0(780, 600));
v51.icons = {};
v51.tabs_list = {};
v51.centered_tabs = 0;
v51.binded_keys = {};
v51.global_time = 0;
v51.fix_press = false;
v51.use_element = v39;
v51.active_tab = 1;
v51.hovered_table = "";
v51.color_picker = {
    is_alpha = false, 
    is_value_saturation = false, 
    is_hue = false, 
    hue = {}, 
    saturation = {}, 
    value = {}, 
    alpha = {}, 
    hue_colors = {
        l_color_0(255, 0, 0, 255), 
        l_color_0(255, 255, 0, 255), 
        l_color_0(0, 255, 0, 255), 
        l_color_0(0, 255, 255, 255), 
        l_color_0(0, 0, 255, 255), 
        l_color_0(255, 0, 255, 255), 
        l_color_0(255, 0, 0, 255)
    }, 
    saved_colors = {}
};
v51.is_binding_new_key = false;
v51.is_using_keyboard = false;
v51.keyboard_data = v39;
v51.keybind_data = v39;
v51.elements_ptrs = {};
v29.load_font("ui::item", l_vector_0(22, 20, 1), "a");
v51.virtual_keys = {
    [1] = nil, 
    [2] = nil, 
    [3] = "m3", 
    [4] = nil, 
    [5] = "m4", 
    [6] = "m5", 
    [7] = nil, 
    [8] = "Back", 
    [9] = "Tab", 
    [10] = nil, 
    [11] = nil, 
    [12] = nil, 
    [13] = "Enter", 
    [14] = nil, 
    [15] = nil, 
    [16] = "Shift", 
    [17] = "Ctrl", 
    [18] = "Alt", 
    [19] = "Pause", 
    [20] = "Caps", 
    [21] = nil, 
    [22] = nil, 
    [23] = nil, 
    [24] = nil, 
    [25] = nil, 
    [26] = nil, 
    [27] = "-", 
    [28] = nil, 
    [29] = nil, 
    [30] = nil, 
    [31] = nil, 
    [32] = "Space", 
    [33] = nil, 
    [34] = nil, 
    [35] = "End", 
    [36] = "Home", 
    [37] = "Left", 
    [38] = "Up", 
    [39] = "Right", 
    [40] = "Down", 
    [41] = "Select", 
    [42] = nil, 
    [43] = nil, 
    [44] = nil, 
    [45] = "Insert", 
    [46] = "Del", 
    [47] = nil, 
    [48] = "0", 
    [49] = "1", 
    [50] = "2", 
    [51] = "3", 
    [52] = "4", 
    [53] = "5", 
    [54] = "6", 
    [55] = "7", 
    [56] = "8", 
    [57] = "9", 
    [58] = nil, 
    [59] = nil, 
    [60] = nil, 
    [61] = nil, 
    [62] = nil, 
    [63] = nil, 
    [64] = nil, 
    [65] = "A", 
    [66] = "B", 
    [67] = "C", 
    [68] = "D", 
    [69] = "E", 
    [70] = "F", 
    [71] = "G", 
    [72] = "H", 
    [73] = "I", 
    [74] = "J", 
    [75] = "K", 
    [76] = "L", 
    [77] = "M", 
    [78] = "N", 
    [79] = "O", 
    [80] = "P", 
    [81] = "Q", 
    [82] = "R", 
    [83] = "S", 
    [84] = "T", 
    [85] = "U", 
    [86] = "V", 
    [87] = "W", 
    [88] = "X", 
    [89] = "Y", 
    [90] = "Z", 
    [91] = nil, 
    [92] = nil, 
    [93] = nil, 
    [94] = nil, 
    [95] = nil, 
    [96] = nil, 
    [97] = nil, 
    [98] = nil, 
    [99] = nil, 
    [100] = nil, 
    [101] = nil, 
    [102] = nil, 
    [103] = nil, 
    [104] = nil, 
    [105] = nil, 
    [106] = nil, 
    [107] = nil, 
    [108] = nil, 
    [109] = nil, 
    [110] = nil, 
    [111] = nil, 
    [112] = "F1", 
    [113] = "F2", 
    [114] = "F3", 
    [115] = "F4", 
    [116] = "F5", 
    [117] = "F6", 
    [118] = "F7", 
    [119] = "F8", 
    [120] = "F9", 
    [121] = "F10", 
    [122] = "F11"
};
v51.invalid_vk = {
    [163] = true, 
    [165] = true, 
    [164] = true, 
    [17] = true, 
    [18] = true, 
    [20] = true, 
    [8] = true, 
    [16] = true, 
    [13] = true, 
    [160] = true, 
    [161] = true, 
    [162] = true
};
v51.references = {
    anti_aim_enable = v28.find("Aimbot", "Anti Aim", "Angles", "Enabled"), 
    hidden = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"), 
    pitch = v28.find("Aimbot", "Anti Aim", "Angles", "Pitch"), 
    yaw = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw"), 
    yaw_base = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"), 
    body_yaw = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"), 
    yaw_offset = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"), 
    yaw_modifier = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"), 
    yaw_modifier_offset = v28.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"), 
    body_yaw_options = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"), 
    left_limit = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"), 
    right_limit = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"), 
    freestand_desync = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"), 
    freestand = v28.find("Aimbot", "Anti Aim", "Angles", "Freestanding"), 
    inverter = v28.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"), 
    slow_walk = v28.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"), 
    fake_duck = v28.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"), 
    double_tap = v28.find("Aimbot", "Ragebot", "Main", "Double Tap"), 
    hide_shots = v28.find("Aimbot", "Ragebot", "Main", "Hide Shots"), 
    dormant_aimbot = v28.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"), 
    auto_peek = v28.find("Aimbot", "Ragebot", "Main", "Peek Assist"), 
    lag_options = v28.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"), 
    hide_shots_options = v28.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"), 
    scope = v28.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"), 
    removlas = v28.find("Visuals", "World", "Main", "Removals"), 
    legs_movement = v28.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"), 
    preserve_kill_feed = v28.find("Miscellaneous", "Main", "In-Game", "Preserve Kill Feed"), 
    hitchance = {
        v28.find("Aimbot", "Ragebot", "Selection", "SSG-08", "Hit Chance"), 
        v28.find("Aimbot", "Ragebot", "Selection", "AWP", "Hit Chance"), 
        v28.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Hit Chance"), 
        v28.find("Aimbot", "Ragebot", "Selection", "R8 Revolver", "Hit Chance"), 
        v28.find("Aimbot", "Ragebot", "Selection", "Desert Eagle", "Hit Chance"), 
        v28.find("Aimbot", "Ragebot", "Selection", "Pistols", "Hit Chance")
    }, 
    auto_scope = {
        v28.find("Aimbot", "Ragebot", "Accuracy", "SSG-08", "Auto Scope"), 
        v28.find("Aimbot", "Ragebot", "Accuracy", "AWP", "Auto Scope"), 
        v28.find("Aimbot", "Ragebot", "Accuracy", "AutoSnipers", "Auto Scope")
    }, 
    min_damage = v28.find("Aimbot", "Ragebot", "Selection", "Min. Damage")
};
v51.local_states = {
    [1] = "Global", 
    [2] = "Stand", 
    [3] = "Slow walk", 
    [4] = "Move", 
    [5] = "Air", 
    [6] = "Use"
};
v51.sub_states = {
    [1] = "Regular", 
    [2] = "Crouch", 
    [3] = "Fake lag"
};
v51.weapons = {
    [1] = "Scout", 
    [2] = "AWP", 
    [3] = "Auto", 
    [4] = "R8", 
    [5] = "Deagle", 
    [6] = "Pistols"
};
v51.sounds_list = {
    swao = "MadrillaSounds/woosh.wav", 
    click = "MadrillaSounds/ui_click.wav"
};
v51.get = function(v400)
    -- upvalues: v51 (ref)
    return v51.elements_ptrs[v400].value;
end;
v51.visible = function(v401, v402)
    -- upvalues: v39 (ref), v51 (ref)
    if v402 == v39 then
        return v51.elements_ptrs[v401].is_visible;
    else
        v51.elements_ptrs[v401].is_visible = v402;
        return;
    end;
end;
v51.new = function(v403, v404, ...)
    -- upvalues: v51 (ref)
    v51.elements_ptrs[v403] = v404(...);
end;
v51.has_bind = function(v405)
    -- upvalues: v51 (ref)
    return v51.binded_keys[v405].key ~= 27;
end;
v51.get_bind = function(v406)
    -- upvalues: v51 (ref)
    return v51.binded_keys[v406].value;
end;
v51.find = function(v407, v408, v409, v410)
    -- upvalues: v51 (ref), v39 (ref)
    local v411 = {
        search_point = true, 
        Script = true, 
        Configs = true, 
        result = true
    };
    for v412 = 1, #v51.tabs_list do
        local v413 = v51.tabs_list[v412];
        if (not v410 or v410[v412]) and v413._name == v407 then
            for v414 = 1, #v413.tables do
                local v415 = v413.tables[v414];
                if not v411[v415._name] and v415._name == v408 then
                    for v416 = 1, #v415.elements do
                        local v417 = v415.elements[v416];
                        if v417._name == v409 then
                            return v417;
                        end;
                    end;
                end;
            end;
        end;
    end;
    return v39;
end;
v51.get_config = function()
    -- upvalues: v51 (ref), v163 (ref)
    local v418 = {
        author = common.get_username(), 
        date = common.get_date("%d/%m/%Y"), 
        menu = {}, 
        keybinds = {}
    };
    local v419 = {
        search_point = true, 
        Script = true, 
        Configs = true, 
        result = true
    };
    local v420 = v51.get("tabs_selections");
    for v421 = 1, #v51.tabs_list do
        local v422 = v51.tabs_list[v421];
        if v420[v421] then
            for v423 = 1, #v422.tables do
                local v424 = v422.tables[v423];
                if not v419[v424._name] then
                    for v425 = 1, #v424.elements do
                        local v426 = v424.elements[v425];
                        local l__type_0 = v426._type;
                        if l__type_0 < 6 then
                            if l__type_0 == 5 then
                                local v428 = v51.binded_keys[v426._name];
                                v418.keybinds[#v418.keybinds + 1] = {
                                    _name = v426._name, 
                                    _key = v428.key, 
                                    _mode = v428.mode
                                };
                            else
                                local l_value_0 = v426.value;
                                if l__type_0 == 4 then
                                    l_value_0 = l_value_0:to_hex();
                                end;
                                v418.menu[#v418.menu + 1] = {
                                    _tab = v422._name, 
                                    _table = v424._name, 
                                    _item = v426._name, 
                                    _value = l_value_0
                                };
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    local v430 = json.stringify(v418);
    return (v163.execute(v430, 10));
end;
v51.load_config = function(v431)
    -- upvalues: v163 (ref), v51 (ref), l_color_0 (ref), v27 (ref)
    local v432 = v163.execute(v431, -10);
    local v433 = json.parse(v432);
    local l_author_0 = v433.author;
    local l_date_0 = v433.date;
    local l_menu_0 = v433.menu;
    local l_keybinds_0 = v433.keybinds;
    for v438 = 1, #l_menu_0 do
        local v439 = l_menu_0[v438];
        local v440 = v51.find(v439._tab, v439._table, v439._item, v51.get("tabs_selections"));
        if v440 then
            local l__value_0 = v439._value;
            if v440._type == 4 then
                l__value_0 = l_color_0(l__value_0);
                v27.clear(v51.color_picker.hue);
                v27.clear(v51.color_picker.saturation);
                v27.clear(v51.color_picker.value);
                v27.clear(v51.color_picker.alpha);
            end;
            v440.value = l__value_0;
        end;
    end;
    for v442 = 1, #l_keybinds_0 do
        local v443 = l_keybinds_0[v442];
        if v51.binded_keys[v443._name] then
            v51.binded_keys[v443._name].key = v443._key;
            v51.binded_keys[v443._name].mode = v443._mode;
        end
    end;
    return l_author_0, l_date_0;
end;
v51.is_open = function()
    -- upvalues: v28 (ref)
    return v28.get_alpha() > 0;
end;
v51.create_tab = function(v444, v445, v446)
    -- upvalues: v51 (ref)
    local v447 = #v51.tabs_list + 1;
    if not v446 then
        v446 = false;
    end;
    if not v446 then
        v51.centered_tabs = v51.centered_tabs + 1;
    end;
    v51.tabs_list[v447] = {
        _name = v444, 
        _icon = v445, 
        tables = {}, 
        is_lower = v446
    };
    return v51.tabs_list[v447].tables;
end;
v51.create_table = function(v448, v449, v450, v451)
    local v452 = #v448 + 1;
    v448[v452] = {
        current_length = 0, 
        alpha = 0, 
        animate_name = 0, 
        animate_scroll = 0, 
        scroll_factor = 0, 
        start_scroll = false, 
        _name = v449, 
        is_right = v450 or false, 
        max_length = 10 + v451 * 40, 
        elements = {}
    };
    return v448[v452].elements;
end;
v51.create_checkbox = function(v453, v454, v455, v456)
    -- upvalues: v39 (ref)
    local v457 = v455 or false;
    local v458 = v456 == v39 or v456;
    local v459 = #v453 + 1;
    v453[v459] = {
        menu_size = 1, 
        _type = 1, 
        _name = v454, 
        value = v457, 
        is_visible = v458
    };
    return v453[v459];
end;
v51.create_slider = function(v460, v461, v462, v463, v464, v465, v466)
    local v467 = v464 or v462;
    local v468 = v465 or true;
    local v469 = #v460 + 1;
    v460[v469] = {
        menu_size = 1, 
        _type = 2, 
        _name = v461, 
        value = v467, 
        is_visible = v468, 
        extands = {
            min = v462, 
            max = v463, 
            values_names = v466
        }
    };
    return v460[v469];
end;
v51.create_list = function(v470, v471, v472, v473, v474, v475)
    local v476 = v473 or v472[1];
    if v474 and v476 == v472[1] then
        v476 = false;
    end;
    local v477 = v475 or true;
    local l_v476_0 = v476;
    if v474 then
        l_v476_0 = {};
        for v479 = 1, #v472 do
            l_v476_0[v479] = v476;
        end;
    end;
    local v480 = #v470 + 1;
    v470[v480] = {
        menu_size = 1, 
        _type = 3, 
        _name = v471, 
        value = l_v476_0, 
        is_visible = v477, 
        extands = {
            items = v472, 
            is_multi = v474
        }
    };
    return v470[v480];
end;
v51.create_color = function(v481, v482, v483, v484)
    -- upvalues: l_color_0 (ref)
    local v485 = v483 or l_color_0(255);
    local v486 = v484 or true;
    local v487 = #v481 + 1;
    v481[v487] = {
        menu_size = 1, 
        _type = 4, 
        _name = v482, 
        value = v485, 
        is_visible = v486, 
        extands = {
            default_color = v485:clone()
        }
    };
    return v481[v487];
end;
v51.create_keybind = function(v488, v489, v490, v491, v492)
    -- upvalues: v51 (ref), v39 (ref)
    local v493 = v490 or 27;
    local v494 = v492 or true;
    local v495 = v491 or false;
    v51.binded_keys[v489] = {
        value = false, 
        mode = "hold", 
        key = v493, 
        last_key = v39, 
        is_mode_disabled = v495
    };
    local v496 = #v488 + 1;
    v488[v496] = {
        menu_size = 1, 
        _type = 5, 
        _name = v489, 
        value = v51.binded_keys[v489], 
        is_visible = v494, 
        extands = {
            is_mode_disabled = v495
        }
    };
    return v488[v496];
end;
v51.create_button = function(v497, v498, v499, v500, v501)
    local v502 = v501 or true;
    local v503 = #v497 + 1;
    v497[v503] = {
        menu_size = 1, 
        _type = 6, 
        _name = v498, 
        is_visible = v502, 
        extands = {
            to_call = v499, 
            icon = v500
        }
    };
    return v497[v503];
end;
v51.create_input = function(v504, v505, v506, v507, v508)
    local v509 = v508 or true;
    local v510 = #v504 + 1;
    v504[v510] = {
        menu_size = 2, 
        _type = 7, 
        _name = v505, 
        value = v506 or "", 
        is_visible = v509, 
        extands = {
            callback = v507
        }
    };
    v504[v510].extands.item = v504[v510];
    return v504[v510];
end;
v51.create_text = function(v511, v512, v513, v514)
    local v515 = v514 or true;
    local v516 = #v511 + 1;
    v511[v516] = {
        menu_size = 0, 
        _type = 8, 
        _name = v512, 
        value = v513, 
        is_visible = v515
    };
    return v511[v516];
end;
v51.play_sound = function(v517)
    -- upvalues: v51 (ref), v154 (ref)
    if not v51.get("menu_sounds") then
        return;
    else
        if v517 == "click" then
            v154.play_sound("MadrillaSounds/ui_click.wav", 0.3, 100, 0, 0);
        end;
        if v517 == "swap" then
            v154.play_sound("MadrillaSounds/woosh.wav", 0.3, 100, 0, 0);
        end;
        return;
    end;
end;
v315 = function(v518, v519, v520, v521)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v50 (ref), v39 (ref), l_color_0 (ref)
    local v522 = v111.mouse_position:is_in_bounds(v518, l_vector_0(300, 30)) and not v51.use_element;
    local v523 = v29.preform_animation(v36("%s_hovered_alpha", v521), v522 and 255 or 180) * v520;
    local v524 = v29.preform_animation(v36("%s_color", v521), v519.value and v50.colors.accent or v50.colors.outline);
    local v525 = v29.preform_animation(v36("%s_progress", v521), v519.value and 1 or 0);
    local v526 = v29.measure_text("theme::font", v39, v519._name);
    v50.render_text("theme::font", v518 + l_vector_0(0, 20 - v526.y / 2), v523 / 255, v39, v519._name);
    local v527 = l_vector_0(v518.x + 300 - 38, v518.y + 11);
    local v528 = l_vector_0(v518.x + 300, v518.y + 29);
    v29.shadow(v527, v528, v524:override(v520), 40, 0, 8);
    v29.rect(v527, v528, v524:override(v520), 8);
    v29.circle(l_vector_0(v518.x + 300 - 28 + 19 * v525, v518.y + 20), l_color_0(255, 255 * v520), 7, 0, 1);
    if v520 > 0 and v522 and v111.is_left_pressed and not v51.use_element and not v51.fix_press then
        v519.value = not v519.value;
        v51.fix_press = true;
        v51.play_sound("click");
    end;
end;
local function v547(v529, v530, v531, v532)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), v50 (ref), v25 (ref), v30 (ref)
    local v533 = v111.mouse_position:is_in_bounds(v529, l_vector_0(300, 30)) and not v51.use_element;
    local v534 = v51.use_element == v532;
    local l_extands_0 = v530.extands;
    local v536 = v29.preform_animation(v36("%s_hovered_alpha", v532), (not not v533 or v534) and 255 or 180) * v531;
    local v537 = v29.measure_text("theme::font", v39, v530._name);
    v50.render_text("theme::font", v529 + l_vector_0(0, 20 - v537.y / 2), v536 / 255, v39, v530._name);
    local l_value_1 = v530.value;
    if l_extands_0.values_names and l_extands_0.values_names[l_value_1] then
        l_value_1 = l_extands_0.values_names[l_value_1];
    end;
    local v539 = v29.measure_text("theme::font", v39, l_value_1);
    local v540 = 100;
    local v541 = v529 + l_vector_0(300 - v540, 18);
    local v542 = v529 + l_vector_0(300, 22);
    v29.rect(v541, v542, v50.colors.outline:override(v531), 2);
    local v543 = v540 / (l_extands_0.max - l_extands_0.min);
    local v544 = v25.floor((v530.value - l_extands_0.min) * v543);
    if v544 > 0 then
        v50.render_accent(v529 + l_vector_0(300 - v540, 18), v529 + l_vector_0(300 - v540 + v544, 22), v531, 2);
    end;
    v50.render_text("theme::font", v529 + l_vector_0(300 - v539.x - v540 - 10, 20 - v539.y / 2), v536 / 255, v39, l_value_1);
    v29.circle(v529 + l_vector_0(300 - v540 + v544, 20), v50.colors.accent:override(v531), 2 + v536 / 255 * 6, 0, 1);
    if v531 > 0 and not v51.use_element then
        v541.y = v541.y - 5;
        if v111.mouse_position:is_in_bounds(v541, l_vector_0(v540, 14)) then
            if v111.is_left_pressed then
                v51.use_element = v532;
            end;
            if v30.is_virtual_key_pressed(17) then
                local v545 = v530.value + v25.clamp(common.get_mouse_wheel_delta(), -1, 1);
                temp_value = v25.clamp(v545, l_extands_0.min, l_extands_0.max);
                v530.value = temp_value;
            end;
        end;
    end;
    if v51.use_element == v532 then
        local v546 = l_extands_0.min + v25.to_int((v111.active_mouse_position.x - (v529.x + 300 - v540)) / v543);
        v530.value = v25.clamp(v546, l_extands_0.min, l_extands_0.max);
        if not v111.is_left_pressed then
            v51.use_element = v39;
        end;
    end;
end;
local function v576(v548, v549, v550, v551, v552)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), v50 (ref), v25 (ref), v27 (ref), v38 (ref), l_color_0 (ref), v48 (ref)
    local v553 = v111.mouse_position:is_in_bounds(v548, l_vector_0(300, 40)) and not v51.use_element;
    local v554 = v51.use_element == v551;
    local v555 = v29.preform_animation(v36("%s_hovered_alpha", v551), (not not v553 or v554) and 1 or 0);
    local v556 = 0;
    local v557 = v29.measure_text("theme::font", v39, v549._name);
    v50.render_text("theme::font", v548 + l_vector_0(0, 20 - v557.y / 2), v25.max(180, 255 * v555) * v550 / 255, v39, v549._name);
    v557 = v549.value;
    if v549.extands.is_multi then
        new_value = {};
        for v558 = 1, #v549.extands.items do
            if v549.value[v558] then
                new_value[#new_value + 1] = v549.extands.items[v558];
            end;
        end;
        v557 = v27.concat(new_value, ",");
    end;
    if v557 == "" then
        v557 = "none";
    end;
    local v559 = v29.measure_text("theme::font", v39, v557);
    if v559.x > 100 then
        v557 = v38(v557, 0, 18);
        v557 = v36("%s...", v557);
        v559 = v29.measure_text("theme::font", v39, v557);
    end;
    v29.texture(v51.icons.menu.img, l_vector_0(v548.x + 300 - 30, v548.y), v51.icons.menu.size, l_color_0(255, 100):override(v550 * v555));
    v50.render_text("theme::font", v548 + l_vector_0(300 - v559.x - 40 * v555, 20 - v559.y / 2), v25.max(180, 255 * v555) * v550 / 255, v39, v557);
    v50.render_accent(v548 + l_vector_0(300 - 32 * v555, 10), v548 + l_vector_0(300 - 30 * v555, 30), v555, 1);
    for v560 = 1, #v549.extands.items do
        local v561 = v29.measure_text("theme::font", v39, v549.extands.items[v560]);
        if v556 < v561.x then
            v556 = v561.x;
        end;
    end;
    if v550 > 0 and v553 and v111.is_left_pressed and not v51.use_element then
        v51.use_element = v551;
        v51.play_sound("swap");
        v557 = #v549.extands.items * 40;
        v559 = v556 + 20 + 40;
        local v562 = v48.window(v36("lua::ui::window_%s", v551), v548 + l_vector_0(300 - v559, 40), l_vector_0(v559, v557));
        v562:register("should_draw", true);
        v562:register_render(function(v563)
            -- upvalues: l_vector_0 (ref), v25 (ref), v29 (ref), l_color_0 (ref), v50 (ref), v549 (ref), v36 (ref), v551 (ref), v39 (ref), v111 (ref), v51 (ref), v552 (ref)
            v563:fade(v563("should_draw") and 1 or 0);
            local v564 = v563._position + l_vector_0(-50 * v25.abs(v563._fade - 1), 0);
            v29.shadow(v564, v564 + v563._size, l_color_0(10, 200 * v563._fade), 70, 0, 10);
            v50.render_background(v564, v564 + v563._size, v563._fade, 10);
            for v565 = 1, #v549.extands.items do
                local v566 = v549.extands.items[v565];
                local v567 = v36("%s^%s", v551, v566);
                local v568 = v29.measure_text("theme::font", v39, v566);
                local v569 = v564 + l_vector_0(0, 40 * (v565 - 1));
                local v570 = l_vector_0(v563._size.x, 30);
                local v571 = v111.mouse_position:is_in_bounds(v569, v570);
                local v572 = v549.extands.is_multi and v549.value[v565] or v549.value == v566;
                local v573 = v29.preform_animation(v567, v572 and 1 or 0) * v563._fade;
                local v574 = v29.preform_animation(v36("%s_hover", v567), v571 and 1 or 0);
                local v575 = 40 * (v565 - 1) + 20;
                v50.render_text("theme::font", v564 + l_vector_0(10 + 30 * v573 + 10 * v574, v575 - v568.y / 2), v25.max(180, 255 * v574) * v563._fade / 255, v39, v566);
                v29.texture(v51.icons.check.img, l_vector_0(v564.x + 5, v564.y + 40 * (v565 - 1) + 5), v51.icons.check.size, l_color_0(255, 180):override(v573));
                if v563._fade > 0.9 and v571 and v111.is_left_pressed and not v51.fix_press then
                    v51.fix_press = true;
                    v51.play_sound("click");
                    if v549.extands.is_multi then
                        v549.value[v565] = not v549.value[v565];
                    else
                        v549.value = v566;
                    end;
                end;
            end;
            if not v111.mouse_position:is_in_bounds(v564, v563._size) and v111.is_left_pressed and v563._fade == 1 then
                v563:register("should_draw", false);
                v51.play_sound("swap");
            end;
            if v552._fade ~= 1 and v563("should_draw") then
                v563:register("should_draw", false);
                v51.play_sound("swap");
            end;
            if not v563("should_draw") and v563._fade == 0 then
                v563:delete();
                v51.use_element = v39;
            end;
        end, v36("lua::ui::window_%s::render", v551));
    end;
end;
local function v633(v577, v578, v579, v580, v581)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), v50 (ref), l_color_0 (ref), v48 (ref), v25 (ref), v27 (ref)
    local v582 = v111.mouse_position:is_in_bounds(v577, l_vector_0(300, 40)) and not v51.use_element;
    local v583 = v51.use_element == v580;
    local v584 = v29.preform_animation(v36("%s_hovered_alpha", v580), (not not v582 or v583) and 1 or 0);
    local v585 = v29.measure_text("theme::font", v39, v578._name);
    v50.render_text("theme::font", v577 + l_vector_0(0, 20 - v585.y / 2), (180 + 74 * v584) * v579 / 255, v39, v578._name);
    v29.texture(v51.icons.color.img, l_vector_0(v577.x + 300 - 30, v577.y), v51.icons.color.size, l_color_0(255, 100):override(v579 * v584));
    v29.circle_outline(l_vector_0(v577.x + 300 - 10 - 40 * v584, v577.y + 20), v50.colors.outline:override(v579), 9, 0, 1);
    v29.circle(l_vector_0(v577.x + 300 - 10 - 40 * v584, v577.y + 20), v578.value:override(v579), 8, 0, 1);
    v50.render_accent(v577 + l_vector_0(300 - 32 * v584, 10), v577 + l_vector_0(300 - 30 * v584, 30), v584, 1);
    if v579 > 0 and v582 and v111.is_left_pressed and not v51.use_element then
        v51.use_element = v580;
        v51.play_sound("swap");
        v585 = 310;
        local v586 = 250;
        local v587 = v578.value:clone();
        if not v51.color_picker.hue[v580] then
            local l_hue_0 = v51.color_picker.hue;
            local l_saturation_0 = v51.color_picker.saturation;
            local l_value_2 = v51.color_picker.value;
            local v591, v592, v593 = v587:to_hsv();
            l_value_2[v580] = v593;
            l_saturation_0[v580] = v592;
            l_hue_0[v580] = v591;
        end;
        local v594 = v48.window(v36("lua::ui::window_%s", v580), v577 + l_vector_0(300 - v586, 30), l_vector_0(v586, v585));
        v594:register("should_draw", true);
        v594:register_render(function(v595)
            -- upvalues: l_vector_0 (ref), v25 (ref), v29 (ref), l_color_0 (ref), v50 (ref), v51 (ref), v580 (ref), v578 (ref), v111 (ref), v27 (ref), v581 (ref), v39 (ref)
            v595:fade(v595("should_draw") and 1 or 0);
            local v596 = v595._position + l_vector_0(-50 * v25.abs(v595._fade - 1), 0);
            v29.shadow(v596, v596 + v595._size, l_color_0(10, 200 * v595._fade), 70, 0, 10);
            v50.render_background(v596, v596 + v595._size, v595._fade, 10);
            v50.render_half_outline(v596, v596 + v595._size, v595._fade, 10, 1);
            local v597 = l_vector_0(v596.x + 10, v596.y + 250);
            for v598 = 1, 6 do
                v29.gradient(v597 + l_vector_0((v598 - 1) * 38.333333333333336, 0), v597 + l_vector_0(v598 * 38.333333333333336, 4), v51.color_picker.hue_colors[v598]:override(v595._fade), v51.color_picker.hue_colors[v598 + 1]:override(v595._fade), v51.color_picker.hue_colors[v598]:override(v595._fade), v51.color_picker.hue_colors[v598 + 1]:override(v595._fade));
            end;
            local v599 = l_color_0():as_hsv(v51.color_picker.hue[v580], 1, 1):override(v595._fade);
            v29.circle(v597 + l_vector_0(0, 2), v51.color_picker.hue_colors[1]:override(v595._fade), 2, 90, 0.5);
            v29.circle(v597 + l_vector_0(230, 2), v51.color_picker.hue_colors[1]:override(v595._fade), 2, 270, 0.5);
            v29.circle(v597 + l_vector_0(v51.color_picker.hue[v580] * 230, 2), v599, 6, 0, 1);
            local v600 = v578.value.a / 255;
            v29.gradient(v597 + l_vector_0(-2, 20), v597 + l_vector_0(232, 24), l_color_0(0, 0), v578.value:alpha_modulate(v595._fade * 255), l_color_0(0, 0), v578.value:alpha_modulate(v595._fade * 255), 3);
            local v601 = l_color_0(0, 255):lerp(v578.value:alpha_modulate(255), v600):override(v595._fade);
            v29.circle(v597 + l_vector_0(v600 * 230, 22), v601, 6, 0, 1);
            local v602 = l_color_0(0, 0, 0, 255 * v595._fade);
            local v603 = l_color_0(0, 0, 0, 0);
            local v604 = l_color_0(255, 255 * v595._fade);
            local v605 = v596 + l_vector_0(10, 10);
            v29.gradient(v605, v605 + l_vector_0(230, 230), v604, v599, v604, v599, 5);
            v29.gradient(v605, v605 + l_vector_0(230, 230), v603, v603, v602, v602, 5);
            local v606 = v605 + l_vector_0(230 * v51.color_picker.saturation[v580], 230 * (1 - v51.color_picker.value[v580]));
            v29.circle_outline(v606, l_color_0(230, 170 * v595._fade), 10, 0, 1);
            v29.circle(v606, v578.value:alpha_modulate(255 * v595._fade), 8, 0, 1);
            local v607 = not v51.color_picker.is_hue and not v51.color_picker.is_value_saturation and not v51.color_picker.is_alpha;
            local v608 = l_vector_0(v597.x, v597.y + 30);
            local v609 = l_vector_0(21, 21);
            v29.rect(v608, v608 + v609, l_color_0(10, 10, 30, 50 * v595._fade), 5);
            v29.text("theme::font", l_vector_0(11 + v597.x, v597.y + 41), l_color_0(255, 180 * v595._fade), "c", "+");
            local v610 = #v51.color_picker.saved_colors;
            if v111.is_left_pressed and v610 < 7 and v111.mouse_position:is_in_bounds(v608, v609) and v607 and not v51.fix_press then
                v51.fix_press = true;
                v51.color_picker.saved_colors[#v51.color_picker.saved_colors + 1] = v578.value:clone();
            end;
            if v111.is_right_pressed and v51.global_time + 1 < globals.realtime and v111.mouse_position:is_in_bounds(v608, v609) then
                local v611 = v578.extands.default_color:clone();
                local l_hue_1 = v51.color_picker.hue;
                local l_v580_0 = v580;
                local l_saturation_1 = v51.color_picker.saturation;
                local l_v580_1 = v580;
                local l_value_3 = v51.color_picker.value;
                local l_v580_2 = v580;
                local v618, v619, v620 = v611:to_hsv();
                l_value_3[l_v580_2] = v620;
                l_saturation_1[l_v580_1] = v619;
                l_hue_1[l_v580_0] = v618;
                v600 = v611.a / 255;
            end;
            for v621 = 1, v610 do
                local v622 = v51.color_picker.saved_colors[v621];
                if v622 then
                    local v623 = l_vector_0(40 + v597.x + (v621 - 1) * 30, v597.y + 41);
                    v29.circle_outline(v623, v50.colors.outline:override(v595._fade), 11, 0, 1);
                    v29.circle(v623, v622:override(v595._fade), 10, 0, 1);
                    if v111.mouse_position:is_in_bounds(v623 - l_vector_0(10, 10), l_vector_0(20, 20)) and v607 then
                        if v111.is_left_pressed and not v51.fix_press then
                            v51.fix_press = true;
                            local l_hue_2 = v51.color_picker.hue;
                            local l_v580_3 = v580;
                            local l_saturation_2 = v51.color_picker.saturation;
                            local l_v580_4 = v580;
                            local l_value_4 = v51.color_picker.value;
                            local l_v580_5 = v580;
                            local v630, v631, v632 = v622:to_hsv();
                            l_value_4[l_v580_5] = v632;
                            l_saturation_2[l_v580_4] = v631;
                            l_hue_2[l_v580_3] = v630;
                            v600 = v622.a / 255;
                        end;
                        if v111.is_right_pressed and v51.global_time + 0.5 < globals.realtime then
                            v51.global_time = globals.realtime;
                            v27.remove(v51.color_picker.saved_colors, v621);
                        end;
                    end;
                end;
            end;
            v608 = v111.mouse_position:is_in_bounds(v597, l_vector_0(230, 6));
            v609 = v111.mouse_position:is_in_bounds(v597 + l_vector_0(0, 20), l_vector_0(230, 6));
            v610 = v111.mouse_position:is_in_bounds(v605, l_vector_0(230, 230));
            if v595._fade == 1 and v111.is_left_pressed then
                if v607 then
                    if v608 then
                        v51.color_picker.is_hue = true;
                    end;
                    if v609 then
                        v51.color_picker.is_alpha = true;
                    end;
                    if v610 then
                        v51.color_picker.is_value_saturation = true;
                    end;
                end;
            else
                if v51.color_picker.is_hue then
                    v51.color_picker.is_hue = false;
                end;
                if v51.color_picker.is_value_saturation then
                    v51.color_picker.is_value_saturation = false;
                end;
                if v51.color_picker.is_alpha then
                    v51.color_picker.is_alpha = false;
                end;
            end;
            if v51.color_picker.is_value_saturation then
                v608 = l_vector_0(v111.active_mouse_position.x - v605.x, v111.active_mouse_position.y - v605.y);
                v608.x = v25.clamp(v608.x, 0, 230);
                v608.y = v25.clamp(v608.y, 0, 230);
                v51.color_picker.value[v580] = 1 - v608.y / 230;
                v51.color_picker.saturation[v580] = v608.x / 230;
            end;
            if v51.color_picker.is_hue then
                v608 = v111.active_mouse_position.x - v597.x;
                v608 = v25.clamp(v608, 0, 229);
                v51.color_picker.hue[v580] = v608 / 230;
            end;
            if v51.color_picker.is_alpha then
                v608 = v111.active_mouse_position.x - v597.x;
                v600 = v25.clamp(v608, 0, 230) / 230;
            end;
            v578.value = l_color_0():as_hsv(v51.color_picker.hue[v580], v51.color_picker.saturation[v580], v51.color_picker.value[v580], v600);
            if v607 and not v111.mouse_position:is_in_bounds(v596, v595._size) and v111.is_left_pressed and v595._fade == 1 then
                v595.should_draw = false;
                v51.play_sound("swap");
            end;
            if v581._fade ~= 1 and v595("should_draw") then
                v595.should_draw = false;
                v51.play_sound("swap");
            end;
            if not v595("should_draw") and v595._fade == 0 then
                v595:delete();
                v51.use_element = v39;
            end;
        end, v36("lua::ui::window_%s::render", v580));
    end;
end;
local function v665(v634, v635, v636, v637, v638)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), v50 (ref), l_color_0 (ref), v25 (ref), v48 (ref), v49 (ref), l_pairs_0 (ref), v30 (ref)
    local v639 = v111.mouse_position:is_in_bounds(v634, l_vector_0(300, 40)) and not v51.use_element;
    local v640 = v51.use_element == v637;
    local v641 = v29.preform_animation(v36("%s_hovered_alpha", v637), (not not v639 or v640) and 1 or 0);
    local v642 = v29.measure_text("theme::font", v39, v635._name);
    v50.render_text("theme::font", v634 + l_vector_0(0, 20 - v642.y / 2), (180 + 74 * v641) * v636 / 255, v39, v635._name);
    v642 = v51.binded_keys[v635._name].key;
    local v643 = v51.virtual_keys[v642];
    local v644 = v635.extands.is_mode_disabled and "press" or v51.binded_keys[v635._name].mode;
    local v645 = v36("%s: %s", v644, v643);
    local v646 = v29.measure_text("theme::font", v39, v645);
    v29.texture(v51.icons.keys.img, l_vector_0(v634.x + 300 - 30, v634.y), v51.icons.keys.size, l_color_0(255, 100):override(v636 * v641));
    v50.render_accent(v634 + l_vector_0(300 - 32 * v641, 10), v634 + l_vector_0(300 - 30 * v641, 30), v641, 1);
    v50.render_text("theme::font", v634 + l_vector_0(300 - v646.x - 40 * v641, 20 - v646.y / 2), v25.max(180, 255 * v641) * v636 / 255, v39, v645);
    if v636 > 0 and v639 and v111.is_left_pressed and not v51.use_element then
        v51.use_element = v637;
        v51.play_sound("swap");
        v642 = 100;
        v643 = 150;
        v644 = v48.window(v36("lua::ui::window_%s", v637), v634 + l_vector_0(320 - v643, -v642 / 2), l_vector_0(v643, v642));
        v644:register("should_draw", true);
        v644:register_render(function(v647)
            -- upvalues: l_vector_0 (ref), v25 (ref), v29 (ref), l_color_0 (ref), v50 (ref), v49 (ref), v51 (ref), v635 (ref), v39 (ref), v111 (ref), v36 (ref), v637 (ref), l_pairs_0 (ref), v30 (ref), v638 (ref)
            v647:fade(v647.should_draw and 1 or 0);
            local v648 = v647._position + l_vector_0(-50 * v25.abs(v647._fade - 1), 0);
            v29.shadow(v648, v648 + v647._size, l_color_0(10, 170 * v647._fade), 30, 0, 10);
            v50.render_background(v648, v648 + v647._size, v647._fade, 10);
            local v649 = not v49.keyboard_handle;
            local l_key_0 = v51.binded_keys[v635._name].key;
            local v651 = v51.virtual_keys[l_key_0];
            local v652 = v29.measure_text("theme::font", v39, v651);
            local v653 = v648 + l_vector_0(v647._size.x / 2, 30);
            local v654 = v111.mouse_position:is_in_bounds(v653 - v652 / 2, v652);
            local v655 = v649 and v51.is_binding_new_key or v51.keybind_data ~= v39;
            local v656 = v29.preform_animation(v36("%s_hover_animation", v637), (not not v654 or v655) and 1 or 0);
            local v657 = v29.preform_animation(v36("%s_binding_color", v637), v655 and l_color_0(255, 10, 10, 255) or v50.colors.accent);
            v29.shadow(v653, v653 + l_vector_0(1, 1), v657:override(v647._fade), 40 + 30 * v656);
            v50.render_text("theme::font", v653, v647._fade, "c", v651);
            if v647._fade == 1 and v654 and not v655 and v111.is_left_pressed then
                v51.play_sound("click");
                if v649 then
                    v51.is_binding_new_key = true;
                else
                    v51.is_using_keyboard = true;
                    v51.keybind_data = {
                        _name = v635._name
                    };
                end;
            end;
            v656 = v649 and v51.is_binding_new_key or v51.is_using_keyboard and v51.keybind_data and v51.keybind_data._name == v635._name;
            if not v654 and v656 and v111.is_left_pressed then
                if v649 then
                    v51.is_binding_new_key = false;
                else
                    v51.is_using_keyboard = false;
                    v51.keybind_data = v39;
                end;
            end;
            if v649 and v51.is_binding_new_key then
                for v658, _ in l_pairs_0(v51.virtual_keys) do
                    if v30.is_virtual_key_pressed(v658) then
                        v51.is_binding_new_key = false;
                        v51.binded_keys[v635._name].key = v658;
                    end;
                end;
                if v30.is_virtual_key_pressed(2) then
                    v51.is_binding_new_key = false;
                    v51.binded_keys[v635._name].key = 27;
                end;
            end;
            if not v649 and v51.keybind_data and v30.is_virtual_key_pressed(2) then
                v51.is_using_keyboard = false;
                v51.keybind_data = v39;
                v51.binded_keys[v635._name].key = 27;
            end;
            if not v635.extands.is_mode_disabled then
                v657 = {
                    [1] = "hold", 
                    [2] = "toggle", 
                    [3] = "always"
                };
                local v660 = 0;
                for v661 = 1, 3 do
                    local v662 = v657[v661];
                    local v663 = v29.measure_text("theme::font", v39, v662);
                    local v664 = v648 + l_vector_0(10 + v660, 60);
                    if v51.binded_keys[v635._name].mode == v662 then
                        v50.render_accent(v664 + l_vector_0(2, 18), v664 + l_vector_0(v663.x - 2, 22), v647._fade, 2);
                    end;
                    v50.render_text("theme::font", v664, v647._fade, v39, v662);
                    if v647._fade == 1 and v51.binded_keys[v635._name].mode ~= v662 and v111.mouse_position:is_in_bounds(v664, v663) and v111.is_left_pressed then
                        v51.play_sound("click");
                        v51.binded_keys[v635._name].mode = v662;
                    end;
                    v660 = v660 + v663.x + 10;
                end;
            end;
            if not v111.mouse_position:is_in_bounds(v648, v647._size) and v111.is_left_pressed and v647._fade == 1 then
                v647.should_draw = false;
                v51.play_sound("swap");
            end;
            if v638._fade ~= 1 and v647("should_draw") then
                v647.should_draw = false;
                v51.play_sound("swap");
            end;
            if not v647.should_draw and v647._fade == 0 then
                v647:delete();
                v51.use_element = v39;
                if v656 then
                    v51.is_binding_new_key = false;
                    v51.is_using_keyboard = false;
                    v51.keybind_data = v39;
                end;
            end;
        end, v36("lua::ui::window_%s::render", v637));
    end;
end;
local function v674(v666, v667, v668, v669)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), l_color_0 (ref), v50 (ref)
    local v670 = v111.mouse_position:is_in_bounds(v666, l_vector_0(300, 40)) and not v51.use_element;
    local v671 = v29.preform_animation(v36("%s_hovered_alpha", v669), v670 and 1 or 0);
    local _ = v29.preform_animation(v36("%s_active_alpha", v669), 20);
    local v673 = v29.measure_text("theme::font", v39, v667._name);
    v29.text("theme::font", v666 + l_vector_0(0, 20 - v673.y / 2), l_color_0(255, (180 + 74 * v671) * v668), v39, v667._name);
    v29.texture(v667.extands.icon.img, l_vector_0(v666.x + 300 - 30, v666.y), v667.extands.icon.size, l_color_0(255, 100):override(v668 * v671));
    v50.render_accent(v666 + l_vector_0(300 - 32 * v671, 10), v666 + l_vector_0(300 - 30 * v671, 30), v671, 1);
    if v670 and v111.is_left_pressed and not v51.fix_press then
        v51.fix_press = true;
        v29.animation_cache[v36("%s_active_alpha", v669)] = 255;
        if v667.extands.to_call then
            v667.extands.to_call();
        end;
    end;
end;
local function v686(v675, v676, v677, v678)
    -- upvalues: v111 (ref), l_vector_0 (ref), v51 (ref), v29 (ref), v36 (ref), v39 (ref), l_color_0 (ref), v25 (ref), v50 (ref), v30 (ref)
    local v679 = v111.mouse_position:is_in_bounds(v675, l_vector_0(300, 60)) and not v51.use_element;
    local v680 = v51.use_element == v678;
    local v681 = v29.preform_animation(v36("%s_hovered_alpha", v678), (not not v679 or v680) and 255 or 180);
    local v682 = v29.measure_text("theme::font", v39, v676._name);
    v29.text("theme::font", v675 + l_vector_0(0, 20 - v682.y / 2), l_color_0(255, v681 * v677), v39, v676._name);
    local v683 = v29.preform_animation(v36("%s_used", v678), v680 and 1 or 0);
    local v684 = v29.measure_text("theme::font", v39, v676.value);
    v29.shadow(v675 + l_vector_0(20, 55), v675 + l_vector_0(20 + v684.x, 56), l_color_0(255, 10, 10, 255 * v683), 70);
    v29.text("theme::font", v675 + l_vector_0(20, 55 - v684.y / 2), l_color_0(255, v681 * v677), v39, v676.value);
    if v676.value == "" and not v680 then
        v29.text("theme::font", v675 + l_vector_0(20, 50), l_color_0(255, v681 * v677 * 0.5), v39, "Press here to type");
    end;
    if v683 > 0 then
        local v685 = v25.abs(v25.sin(globals.realtime * 2));
        v50.render_accent(v675 + l_vector_0(22 + v684.x, 47), v675 + l_vector_0(24 + v684.x, 63), v683 * v685, 1);
    end;
    v683 = v111.mouse_position:is_in_bounds(v675 + l_vector_0(0, 40), l_vector_0(300, 30));
    if v676.is_visible and v677 > 0 and v683 and not v51.use_element and v111.is_left_pressed then
        v51.use_element = v678;
        v51.is_using_keyboard = true;
        v51.keyboard_data = v676.extands;
    end;
    if v680 and (v30.is_virtual_key_pressed(27) or v30.is_virtual_key_pressed(13) or not v683 and v111.is_left_pressed or not v676.is_visible or v677 == 0) then
        v51.use_element = v39;
        v51.is_using_keyboard = false;
        v51.keyboard_data = v39;
    end;
end;
local function v693(v687, v688, v689, _)
    -- upvalues: v29 (ref), v39 (ref), l_vector_0 (ref), l_color_0 (ref)
    local v691 = v29.measure_text("theme::font", v39, v688.value);
    local v692 = v688.menu_size * 40 / 2;
    v29.text("theme::font", v687 + l_vector_0(0, v692 - v691.y / 2), l_color_0(255, 255 * v689), v39, v688.value);
end;
local v694 = {
    [1] = v315, 
    [2] = v547, 
    [3] = v576, 
    [4] = v633, 
    [5] = v665, 
    [6] = v674, 
    [7] = v686, 
    [8] = v693
};
do
    local l_v694_0 = v694;
    v51.render_main_window = function(v696)
        -- upvalues: v28 (ref), v111 (ref), v51 (ref), v50 (ref), v29 (ref), l_vector_0 (ref), l_color_0 (ref), v36 (ref), v25 (ref), v39 (ref), v30 (ref), v26 (ref), l_v694_0 (ref)
        local ok, err = pcall(function()
        v696:fade(v28.get_alpha());
        if v696._fade == 0 then
            return;
        else
            if not v111.is_left_pressed then
                v51.fix_press = false;
            end;
            local v697 = v696._position + v696._size;
            v50.render_background(v696._position, v697, v696._fade, 18);
            v29.push_clip_rect(v696._position, v697, true);
            pcall(v29.texture, v51.icons.cloud.img, l_vector_0(v696._position.x + 15, v696._position.y + 14), v51.icons.cloud.size, l_color_0(255, 180 * v696._fade));
            local v698 = v111.is_anything_moving() and 0 or 1;
            local v699 = {
                [1] = l_vector_0(v696._position.x + 90, v696._position.y + 20), 
                [2] = l_vector_0(v696._position.x + 440, v696._position.y + 20)
            };
            local v700 = #v51.tabs_list;
            local v701 = v696._position.y + v696._size.y / 2 - (v51.centered_tabs * 60 - 20) / 2;
            for v702 = 1, v700 do
                local v703 = v51.tabs_list[v702];
                local v704 = v36("ui::menu::tab_%s", v703._name);
                assert(v703, v36("Failed to index %s", v704));
                local v705 = v51.active_tab == v702;
                local v706 = nil;
                if not v703.is_lower then
                    v706 = l_vector_0(v696._position.x + 15 * v696._fade, v701 + (v702 - 1) * 60);
                else
                    v706 = l_vector_0(v696._position.x + 15 * v696._fade, v696._position.y + v696._size.y - 15 - v703._icon.size.y);
                end;
                local v707 = v29.preform_animation(v704, v705 and v698 or 0) * v696._fade;
                v50.render_accent(v706 + l_vector_0(45, 1), v706 + l_vector_0(49, 1 + v703._icon.size.y * v707), v707, 2);
                v29.texture(v703._icon.img, v706, v703._icon.size, l_color_0(255):override(v25.max(0.4, v707 - 0.2) * v696._fade));
                if v111.is_left_pressed and v111.mouse_position:is_in_bounds(v706, v703._icon.size) and v51.active_tab ~= v702 then
                    v51.active_tab = v702;
                    v51.play_sound("swap");
                end;
                if v707 > 0 then
                    local v708 = v25.abs(v707 - 1);
                    local v709 = {
                        [1] = 0, 
                        [2] = 0
                    };
                    for v710 = 1, #v703.tables do
                        local v711 = v703.tables[v710];
                        local v712 = v36("%s::table_%s", v704, v711._name);
                        assert(v711, v36("Failed to index %s", v712));
                        local v713 = v29.get_animation_value(v712) * v707;
                        local v714 = v711.is_right and 2 or 1;
                        local v715 = l_vector_0(v699[v714].x, v699[v714].y + v709[v714] - 50 * v708);
                        local v716 = v25.min(v711.max_length, v711.current_length);
                        local v717 = l_vector_0(v715.x + 320, v715.y + v716);
                        local v718 = v111.mouse_position:is_in_bounds(v715, l_vector_0(320, v716));
                        if v718 then
                            v51.hovered_table = v712;
                        elseif not v718 and v51.hovered_table == v712 then
                            v51.hovered_table = "";
                        end;
                        local v719 = 1;
                        if v51.get("menu_group_names") and v713 > 0 and not v51.use_element and v51.hovered_table ~= "" then
                            if v51.hovered_table ~= v712 then
                                v719 = 0.2;
                                v711.animate_name = v29.do_animation(v711.animate_name, 0);
                            else
                                v711.animate_name = v29.do_animation(v711.animate_name, 1);
                            end;
                        else
                            v711.animate_name = v29.do_animation(v711.animate_name, 0);
                        end;
                        if v711.animate_name > 0 then
                            v29.text("theme::font", v715 + l_vector_0(30, -18), l_color_0(255, 180 * v713 * v711.animate_name), v39, v711._name);
                        end;
                        local v720 = v711.start_scroll and v718;
                        v50.render_half_outline(v715, v717, v713);
                        if not v51.use_element and v720 and not v30.is_virtual_key_pressed(17) then
                            v711.scroll_factor = v711.scroll_factor + common.get_mouse_wheel_delta() * 20;
                            v711.scroll_factor = v25.clamp(v711.scroll_factor, -v711.current_length + v711.max_length, 0);
                        end;
                        if not v711.start_scroll then
                            v711.scroll_factor = 0;
                        end;
                        local v721 = v29.preform_animation(v36("%s_scrolldown", v712), v711.scroll_factor, v39);
                        if v711.start_scroll then
                            local v722 = (v717.y - v715.y) / v711.current_length;
                            local v723 = v711.max_length * v722;
                            local v724 = v25.abs(v721) * v722;
                            v50.render_accent(v715 + l_vector_0(0, v724), v715 + l_vector_0(4, v724 + v723), v713, 2);
                        else
                            v50.render_accent(v715, l_vector_0(v715.x + 4, v717.y), v713, 2);
                        end;
                        local v725 = 5;
                        v29.push_clip_rect(v715, v717, true);
                        for v726 = 1, #v711.elements do
                            local v727 = v711.elements[v726];
                            local v728 = v36("%s::element_%s", v712, v727._name);
                            assert(v727, v36("Failed to index %s", v728));
                            local v729 = l_vector_0(v715.x + 10, v715.y + v725 + v721);
                            if v727._type == 8 and v727.menu_size == 0 then
                                v727.value = v26.wrap_text(v727.value, 300, "theme::font");
                                local v730 = v29.measure_text("theme::font", v39, v727.value);
                                v727.menu_size = v25.ceil(v730.y / 40);
                            end;
                            local v731 = v727.menu_size * 40;
                            if v729:is_in_bounds(l_vector_0(v715.x, v715.y), l_vector_0(320, v716 - v731)) then
                                local _ = v727.is_visible;
                            end;
                            local v733 = v29.preform_animation(v36("%s_alpha", v728), v727.is_visible and 1 or 0);
                            local v734 = v729:is_in_bounds(l_vector_0(v715.x, v715.y), l_vector_0(320, v716 - v731));
                            local v735 = v29.preform_animation(v36("%s_alpha_in_table", v728), (v734 and 1 or 0) * v713) * v733;
                            if v735 > 0 then
                                local ok_el, err_el = pcall(l_v694_0[v727._type], v729, v727, v735, v728, v696);
                                if not ok_el then
                                    print("ELEMENT CRASH! Type: " .. tostring(v727._type) .. " Name: " .. tostring(v727._name) .. " Error: " .. tostring(err_el))
                                end
                            end;
                            v725 = v725 + v731 * v733;
                        end;
                        v29.pop_clip_rect();
                        v725 = v725 + 5;
                        v711.start_scroll = v711.max_length < v725;
                        v29.preform_animation(v712, (v725 > 20 and 1 or 0) * v719);
                        v711.current_length = v29.do_animation(v711.current_length, v725, 100);
                        v709[v714] = v709[v714] + (v716 + 20) * (v713 ~= 0 and 1 or 0);
                    end;
                end;
            end;
            v29.pop_clip_rect();
            v696:override_position(l_vector_0(70, 70));
            return;
        end;
        end)
        if not ok then
            print("========================================")
            print("THE REAL CRASH IS TYPE: " .. type(err))
            if type(err) == "string" then
                print("STRING LENGTH: " .. tostring(#err))
                for i = 1, #err do
                    print("BYTE " .. tostring(i) .. ": " .. tostring(string.byte(err, i)))
                end
            else
                print("TOSTRING: " .. tostring(err))
            end
            print("========================================")
            error(err)
        end
    end;
    v51.handle_keybinds = function()
        -- upvalues: l_pairs_0 (ref), v51 (ref), v30 (ref), v39 (ref), l_error_0 (ref), v36 (ref)
        for v736, v737 in l_pairs_0(v51.binded_keys) do
            if v737.key == 27 then
                v737.value = false;
            elseif v737.mode == "hold" then
                v737.value = v30.is_virtual_key_pressed(v737.key);
            elseif v737.mode == "toggle" then
                if v737.last_key == v39 and v30.is_virtual_key_pressed(v737.key) then
                    v737.last_key = v737.key;
                    v737.value = not v737.value;
                end;
                if v737.last_key ~= v39 and not v30.is_virtual_key_pressed(v737.key) then
                    v737.last_key = v39;
                end;
            elseif v737.mode == "always" then
                v737.value = true;
            else
                l_error_0(v36("Failed to find mode for bind %s", v736));
            end;
        end;
    end;
end;
v51.keyboard_interact = function(_, v739, v740)
    -- upvalues: v51 (ref), v33 (ref), v26 (ref), v39 (ref), v30 (ref)
    if not v51.is_using_keyboard then
        return;
    else
        local v741 = v33.cast("keybaord_low_level_hook_t*", v740);
        if v739 ~= 256 then
            return;
        else
            local l_vkCode_0 = v741.vkCode;
            if v51.keyboard_data and l_vkCode_0 == 8 and v51.keyboard_data.item.value ~= "" then
                v51.keyboard_data.item.value = v26.remove_last_char(v51.keyboard_data.item.value);
                v51.keyboard_data.callback(v51.keyboard_data.item.value);
                return true;
            elseif v51.invalid_vk[l_vkCode_0] then
                return;
            elseif v51.keybind_data and v51.virtual_keys[l_vkCode_0] then
                v51.binded_keys[v51.keybind_data._name].key = l_vkCode_0;
                v51.keybind_data = v39;
                v51.is_using_keyboard = false;
                return true;
            else
                local v743 = v33.new("BYTE[256]");
                v33.C.GetKeyboardState(v743);
                local v744 = v33.C.GetKeyboardLayout(0);
                local v745 = v33.new("wchar_t[3]");
                local v746 = v33.C.ToUnicodeEx(l_vkCode_0, v741.scanCode, v743, v745, 3, 0, v744);
                v745[v746] = 0;
                if v746 > 0 then
                    local v747 = v30.wide_char_to_multi_byte_string(v745);
                    if v51.keyboard_data then
                        if v51.keyboard_data.item.value == v39 then
                            v51.keyboard_data.item.value = "";
                        end;
                        v51.keyboard_data.item.value = v51.keyboard_data.item.value .. v747;
                        v51.keyboard_data.callback(v51.keyboard_data.item.value);
                    end;
                    return true;
                else
                    return;
                end;
            end;
        end;
    end;
end;
v51.mouse_interact = function()
    -- upvalues: v51 (ref)
    if v51.is_open() then
        return false;
    else
        return;
    end;
end;
v51.initialize_icons = function()
    -- upvalues: l_vector_0 (ref), v51 (ref), v31 (ref)
    local v748 = l_vector_0(40, 40);
    local v749 = l_vector_0(30, 30);
    local _ = l_vector_0(64, 64);
    v51.icons.cloud = v31.load_icon("cloud.png", v748);
    v51.icons.home = v31.load_icon("home.png", v748);
    v51.icons.anti_aim = v31.load_icon("rotate.png", v748);
    v51.icons.visuals = v31.load_icon("sun.png", v748);
    v51.icons.indicators = v31.load_icon("data.png", v748);
    v51.icons.misc = v31.load_icon("tuning.png", v748);
    v51.icons.eighteen_plus = v31.load_icon("18plus.png", v748);
    v51.icons.search = v31.load_icon("search.png", v748);
    v51.icons.check = v31.load_icon("check.png", v749);
    v51.icons.open_check = v31.load_icon("check.png", v748);
    v51.icons.menu = v31.load_icon("check_list.png", v748);
    v51.icons.color = v31.load_icon("color.png", v748);
    v51.icons.keys = v31.load_icon("keyboard.png", v748);
    v51.icons.reset = v31.load_icon("rotate.png", v748);
    v51.icons.error = v31.load_icon("warning.png", v748);
    v51.icons.save = v31.load_icon("save.png", v748);
    v51.icons.load = v31.load_icon("load.png", v748);
    v51.icons.keybinds = v31.load_icon("keyboard.png", v749);
    v51.icons.watermark = v31.load_icon("cloud.png", v749);
    v51.icons.warning = v31.load_icon("warning.png", v749);
    v51.icons.hit = v31.load_icon("check.png", v749);
    v51.icons.miss = v31.load_icon("close.png", v749);
    v51.icons.health = v31.load_icon("health.png", v749);
    v51.icons.armor = v31.load_icon("armor.png", v749);
    v51.icons.headshot = v31.load_icon("headshot.svg", l_vector_0(20, 20));
    v51.icons.arrow = v31.load_icon("arrow.png", v749);
    v51.icons.manual = v31.load_icon("arrow.png", l_vector_0(20, 20));
    v51.icons.bullet = v31.load_icon("bullet.png", v749);
    v51.icons.radar = v31.load_icon("radar.png", v749);
    v51.icons.unk_rotate = v31.load_icon("unk_rotate.png", v749);
    v51.icons.location = v31.load_icon("location.png", v749);
    v51.icons.hc = v31.load_icon("hc.png", l_vector_0(48, 48));
    v51.icons.ad = v31.load_icon("ad.png", l_vector_0(48, 48));
    v51.icons.jb = v31.load_icon("jb.png", l_vector_0(48, 48));
    return true;
end;
v51.initialize_elements = function()
    -- upvalues: v51 (ref), v36 (ref), v46 (ref), l_color_0 (ref), v30 (ref), v64 (ref), v29 (ref), v311 (ref), v154 (ref), v26 (ref), v49 (ref), v39 (ref), v31 (ref), v27 (ref), v57 (ref), v37 (ref), v50 (ref), v25 (ref)
    local v751 = v51.create_tab("Home", v51.icons.home);
    local v752 = v51.create_tab("Anti aim", v51.icons.anti_aim);
    local v753 = v51.create_tab("Visuals", v51.icons.visuals);
    local v754 = v51.create_tab("Indicators", v51.icons.indicators);
    local v755 = v51.create_tab("Misc", v51.icons.misc);
    local gc_tab = v51.create_tab("18+", v51.icons.eighteen_plus);
    local v756 = v51.create_tab("Search", v51.icons.search, true);
    local gc_table = v51.create_table(gc_tab, "Goon Corner", false, 6);
    local v757 = v51.create_table(v751, "Welcome", false, 5);
    v51.create_text(v757, "Welcome text", v36("Welcome back %s", common.get_username()));
    v51.create_text(v757, "pad1", " ");
    v51.create_text(v757, "Update", v36("Last update was %s", v46));
    local v758 = v51.create_table(v751, "Theme", false, 5);
    v51.new("theme_accent", v51.create_color, v758, "Theme color", l_color_0(150, 150, 255, 255));
    v51.new("theme_background", v51.create_color, v758, "Background color", l_color_0(10, 10, 30, 100));
    v51.new("menu_sounds", v51.create_checkbox, v758, "Menu sounds", true);
    v51.new("menu_group_names", v51.create_checkbox, v758, "Menu group names", true);
    v51.new("goon_corner_enabled", v51.create_checkbox, gc_table, "Enable Goon Corner", false);
    v51.new("goon_corner_time", v51.create_slider, gc_table, "Image Delay (s)", 1, 30, 5);
    v51.create_text(gc_table, "goon_corner_asmr_track", "[Track: Goth Mommy ASMR]");
    v51.new("goon_corner_asmr_enabled", v51.create_checkbox, gc_table, "Enable Goth ASMR", false);
    v51.new("goon_corner_volume", v51.create_slider, gc_table, "ASMR Volume", 0, 100, 50);
    v51.new("goon_corner_seek", v51.create_slider, gc_table, "ASMR Seek (Sec)", 0, 2224, 0);
    v51.new("animation_speed", v51.create_slider, v758, "Animation speed", 1, 20, 12);
    local v759 = v51.create_table(v751, "Script", false, 4);
    v51.create_text(v759, "Resert explained", "If you experience some fps drops, \nyou can reset render cache or change performance mode");
    v51.new("reset_render", v51.create_button, v759, "Reset render cache", function()
        -- upvalues: v30 (ref), v64 (ref), v29 (ref), v311 (ref), v51 (ref), v154 (ref)
        v30.execute_after(3, function()
            -- upvalues: v64 (ref), v29 (ref)
            v64.clear_killfeed();
            v29.clear_cache();
        end);
        v311.add("Resetting render cache in 3 seconds", v51.icons.reset);
        v154.play_sound("MadrillaSounds/error.wav", 1, 100, 0, 0);
    end, v51.icons.reset);
    v51.new("reset_render", v51.create_button, v759, "Switch performance mode", function()
        -- upvalues: v30 (ref), v29 (ref), v154 (ref), v311 (ref), v51 (ref)
        v30.execute_after(3, function()
            -- upvalues: v29 (ref), v154 (ref)
            v29.switch_preformance();
            v29.clear_cache();
            v154.play_sound("MadrillaSounds/menu_load.wav", 1, 100, 0, 0);
        end);
        v311.add("Reloading performance mode in 3 seconds", v51.icons.reset);
        v154.play_sound("MadrillaSounds/fast_press.wav", 1, 100, 0, 0);
    end, v51.icons.reset);
    v51.create_text(v759, "Safe mode explained", "Disabling Lua\226\128\153s safe mode can slightly improve performance, but it increases the risk of game crashes. Use with caution.");
    v51.create_text(v759, "Safe mode state", v26.format("Safe mode is %s", v49.safe_mode and "on" or "off"));
    v51.new("switch_safe_mode", v51.create_button, v759, "Switch safe mode", function()
        -- upvalues: v49 (ref), v311 (ref), v36 (ref), v51 (ref), v154 (ref), v30 (ref)
        local v760 = not v49.safe_mode;
        db._MadrillaRecode_SafeModeHook = {
            is = v760
        };
        v311.add(v36("Switching safe mode mode in 3 seconds. new state %s", tostring(v760)), v51.icons.reset);
        v154.play_sound("MadrillaSounds/fast_press.wav", 1, 100, 0, 0);
        v30.execute_after(3, function()
            common.reload_script();
        end);
    end, v51.icons.reset);
    local v761 = v51.create_table(v751, "Configs", true, 10);
    local function v766(v762)
        -- upvalues: v39 (ref), v311 (ref), v51 (ref), v154 (ref), v36 (ref)
        if v762 == v39 or v762 == "?" then
            v311.add("Invalid or empty config", v51.icons.error);
            v154.play_sound("physics/glass/glass_cup_break2.wav", 1, 100, 0, 0);
            return;
        else
            local v763, v764 = v51.load_config(v762);
            local v765 = v36("Loaded config by %s. Last update %s", v763, v764);
            v311.add(v765, v51.icons.load);
            v154.play_sound("MadrillaSounds/fast_press.wav", 1, 100, 0, 0);
            return;
        end;
    end;
    do
        local l_v766_0 = v766;
        v51.new("load_autosave", v51.create_button, v761, "Load last settings", function()
            -- upvalues: l_v766_0 (ref), v31 (ref), v36 (ref)
            l_v766_0(v31.read(v36("csgo\\MadrillaRecode\\Configs\\%s.Madrilla", "AutoSave")));
        end, v51.icons.load);
        v51.new("configs_selection", v51.create_list, v761, "Select config", {
            [1] = "Config1", 
            [2] = "Config2", 
            [3] = "Config3", 
            [4] = "Config4", 
            [5] = "Config5", 
            [6] = "Config6", 
            [7] = "Config7", 
            [8] = "Config8"
        });
        v51.new("tabs_selections", v51.create_list, v761, "Select tabs", {
            [1] = "Home", 
            [2] = "Anti aim", 
            [3] = "Visuals", 
            [4] = "Indicators", 
            [5] = "Misc"
        }, true, true);
        v51.new("save_config", v51.create_button, v761, "Save config", function()
            -- upvalues: v51 (ref), v31 (ref), v36 (ref), v311 (ref), v154 (ref)
            local v768 = v51.get_config();
            if not v31.write(v36("csgo\\MadrillaRecode\\Configs\\%s.Madrilla", v51.get("configs_selection")), v768) then
                v311.add("Failed to save config", v51.icons.error);
                v154.play_sound("physics/glass/glass_cup_break2.wav", 1, 100, 0, 0);
                return;
            else
                v311.add("Config saved", v51.icons.save);
                v154.play_sound("MadrillaSounds/fast_press.wav", 1, 100, 0, 0);
                return;
            end;
        end, v51.icons.save);
        v51.new("load_config", v51.create_button, v761, "Load config", function()
            local v769 = v51.get("configs_selection");
            l_v766_0(v31.read(v36("csgo\\MadrillaRecode\\Configs\\%s.Madrilla", v769)));
        end, v51.icons.load);
        v51.new("export_clipboard", v51.create_button, v761, "Export to clipboard", function()
            local clipboard = require("neverlose/clipboard")
            local base64 = require("neverlose/base64")
            local v768 = v51.get_config();
            if v768 then
                clipboard.set(base64.encode(v768))
                v311.add("Config copied to clipboard", v51.icons.save);
                v154.play_sound("MadrillaSounds/fast_press.wav", 1, 100, 0, 0);
            else
                v311.add("Failed to export config", v51.icons.error);
                v154.play_sound("physics/glass/glass_cup_break2.wav", 1, 100, 0, 0);
            end
        end, v51.icons.save);
        v51.new("import_clipboard", v51.create_button, v761, "Import from clipboard", function()
            local clipboard = require("neverlose/clipboard")
            local base64 = require("neverlose/base64")
            local success, data = pcall(function()
                return base64.decode(clipboard.get())
            end)
            if success and data and #data > 0 then
                l_v766_0(data)
            else
                v311.add("Invalid config in clipboard", v51.icons.error);
                v154.play_sound("physics/glass/glass_cup_break2.wav", 1, 100, 0, 0);
            end
        end, v51.icons.load);
    end;
    v757 = v51.create_table(v752, "Main", false, 6);
    v51.new("override_anti_aim", v51.create_checkbox, v757, "Override anti aim");
    v51.new("override_pitch", v51.create_checkbox, v757, "Pitch down");
    v51.new("override_yaw", v51.create_list, v757, "Yaw base", {
        [1] = "None", 
        [2] = "Local view", 
        [3] = "At target"
    });
    v51.new("at_target_in_air", v51.create_checkbox, v757, "At target in air");
    v758 = v51.create_table(v752, "Modes", false, 3);
    v51.new("anti_aim_mode", v51.create_list, v758, "Select anti aim mode", {
        [1] = "Auto presets", 
        [2] = "Default builder"
    });
    v51.new("select_preset", v51.create_list, v758, "Select preset", {
        [1] = "Static", 
        [2] = "Old Center", 
        [3] = "Break"
    });
    v51.new("enable_preset_freestand", v51.create_checkbox, v758, "Enable desync freestand");
    v759 = v51.create_table(v752, "Misc", false, 5);
    v51.new("enable_anti_aim_misc", v51.create_list, v759, "Select misc settings", {
        [1] = "Allow on use", 
        [2] = "Anti bruteforce", 
        [3] = "Break lc in air", 
        [4] = "Disable on round-end", 
        [5] = "Static on manuals", 
        [6] = "Static on warmup", 
        [7] = "Override desync freestand"
    }, v39, true);
    v51.new("resert_anti_bruteforce", v51.create_button, v759, "Reset anti bruteforce", function()
        -- upvalues: v27 (ref), v57 (ref), v311 (ref), v51 (ref), v154 (ref)
        v27.clear(v57.presets);
        v57.misses = 0;
        v311.add("Reset anti bruteforce data", v51.icons.reset);
        v154.play_sound("MadrillaSounds/error.wav", 1, 100, 0, 0);
    end, v51.icons.reset);
    v51.new("invert_freestand", v51.create_checkbox, v759, "Invert desync freestand");
    v51.new("limit_freestand", v51.create_checkbox, v759, "Limit freestand calculations");
    v51.new("edge_yaw", v51.create_keybind, v759, "Edge yaw");
    v51.new("defensive_snap", v51.create_keybind, v759, "Defensive snap");
    v51.new("defensive_pitch", v51.create_slider, v759, "Delay pitch", 1, 20, 8);
    v51.new("defensive_yaw", v51.create_slider, v759, "Delay yaw", 1, 20, 4);
    v51.new("defensive_settings", v51.create_list, v759, "Defensive addons", {
        [1] = "Linear pitch", 
        [2] = "Linear yaw", 
        [3] = "Wide angle"
    }, None, true);
    v51.new("manual_left", v51.create_keybind, v759, "Manual left", v39, true);
    v51.new("manual_right", v51.create_keybind, v759, "Manual right", v39, true);
    v51.new("manual_back", v51.create_keybind, v759, "Manual back", v39, true);
    v757 = v51.create_table(v752, "States", true, 4);
    v51.new("default_states", v51.create_list, v757, "Select state", v51.local_states);
    for v770 = 1, #v51.local_states do
        local v771 = v37(v51.local_states[v770]);
        local v772 = v771 == "global";
        v51.new(v36("enable_state_%s", v771), v51.create_checkbox, v757, v36("Enable %s", v771), v772, false);
        v51.new(v36("select_sub_state_%s", v771), v51.create_list, v757, v36("Select %s sub state", v771), v51.sub_states);
        for v773 = 1, 3 do
            local v774 = v37(v51.sub_states[v773]);
            local v775 = v774 == "regular";
            local v776 = v36("%s_%s", v771, v774);
            v51.new(v36("enable_%s", v776), v51.create_checkbox, v757, v36("Override %s on %s", v774, v771), v775, false);
            local v777 = v51.create_table(v752, v36("%s on %s", v774, v771), true, 9);
            v51.new(v36("yaw_left_%s", v776), v51.create_slider, v777, "Yaw left", -180, 180, 0);
            v51.new(v36("yaw_right_%s", v776), v51.create_slider, v777, "Yaw right", -180, 180, 0);
            v51.new(v36("yaw_modifier_%s", v776), v51.create_list, v777, "Yaw modifier", {
                [1] = "Disabled", 
                [2] = "Center", 
                [3] = "Offset", 
                [4] = "Random", 
                [5] = "Spin", 
                [6] = "3-Way", 
                [7] = "5-Way", 
                [8] = "Devided delta"
            });
            v51.new(v36("yaw_modifier_delta_%s", v776), v51.create_slider, v777, "Modifier degree", -180, 180, 0);
            v51.new(v36("yaw_modifier_mode_%s", v776), v51.create_slider, v777, "Modifier mode", 3, 6, 3);
            v51.new(v36("left_limit_%s", v776), v51.create_slider, v777, "Left limit", 0, 59, 30);
            v51.new(v36("right_limit_%s", v776), v51.create_slider, v777, "Right limit", 0, 59, 30);
            v51.new(v36("fake_options_%s", v776), v51.create_list, v777, "Desync options", {
                [1] = "Avoid overlap", 
                [2] = "Jitter", 
                [3] = "Randomize jitter"
            }, v39, true);
            v51.new(v36("freestand_desync_%s", v776), v51.create_list, v777, "Desync freestand", {
                [1] = "Off", 
                [2] = "Peek fake", 
                [3] = "Peek real"
            });
        end;
    end;
    v757 = v51.create_table(v753, "World", false, 9);
    v51.new("enable_bloom", v51.create_checkbox, v757, "Enable bloom");
    v51.new("bloom_scale", v51.create_slider, v757, "Bloom scale", 1, 100, 30);
    v51.new("exposure_scale", v51.create_slider, v757, "Exposure scale", 1, 100, 50);
    v51.new("model_brightness", v51.create_slider, v757, "Model brightness", 1, 100, 20);
    v51.new("enable_impacts", v51.create_checkbox, v757, "Enable splash impact");
    v51.new("only_local_impacts", v51.create_checkbox, v757, "Only local");
    v51.new("impacts_color", v51.create_color, v757, "Splash impacts color", l_color_0(255));
    v51.new("enable_friendly_molotov", v51.create_checkbox, v757, "Friendly molotov overlay");
    v51.new("friendly_molotov_color", v51.create_color, v757, "Friendly molotov color", l_color_0(0, 255, 0, 70));
    v758 = v51.create_table(v753, "Local", false, 5);
    v51.new("animate_transparency", v51.create_checkbox, v758, "Animate transparency");
    v51.new("select_animation_state", v51.create_list, v758, "Select animation state", {
        [1] = "On move", 
        [2] = "In air", 
        [3] = "On land"
    });
    v51.new("air_legs_movement", v51.create_list, v758, "In air legs", {
        [1] = "Regular", 
        [2] = "Static", 
        [3] = "Move"
    });
    v51.new("air_legs_movement_factor", v51.create_slider, v758, "In air legs factor", 0, 100, 20);
    v51.new("air_body_lean_factor", v51.create_slider, v758, "In air body lean", 0, 101, 100);
    v51.new("move_legs_movement", v51.create_list, v758, "On move legs", {
        [1] = "Regular", 
        [2] = "Static", 
        [3] = "Jitter", 
        [4] = "Move"
    });
    v51.new("move_legs_movement_factor", v51.create_slider, v758, "On move legs factor", 0, 100, 20);
    v51.new("move_body_lean_factor", v51.create_slider, v758, "On move body lean", 0, 101, 100);
    v51.new("on_land_options", v51.create_list, v758, "On land", {
        [1] = "Regular", 
        [2] = "Disable pitch", 
        [3] = "Disable crouch"
    });
    v759 = v51.create_table(v753, "View", true, 10);
    v51.new("select_view_list", v51.create_list, v759, "Select view settings", {
        [1] = "Aspect ratio", 
        [2] = "View model", 
        [3] = "Custom scope"
    });
    v51.new("aspect_ratio", v51.create_slider, v759, "Aspect ratio", 0, 150, 100, v39, {
        [0] = "Disable", 
        [100] = "Default"
    });
    v51.new("enable_view_model", v51.create_checkbox, v759, "Override view model");
    v51.new("view_offset_x", v51.create_slider, v759, "Offset x", -40, 40, 0);
    v51.new("view_offset_y", v51.create_slider, v759, "Offset y", -40, 40, 0);
    v51.new("view_offset_z", v51.create_slider, v759, "Offset z", -40, 40, 0);
    v51.new("view_offset_fov", v51.create_slider, v759, "Offset fov", 0, 170, 60);
    v51.new("view_knife_opposite", v51.create_checkbox, v759, "Knife on opposite hand");
    v51.new("enable_scope", v51.create_checkbox, v759, "Override scope");
    v51.new("scope_origin", v51.create_slider, v759, "Origin", 0, 150, 10);
    v51.new("scope_width", v51.create_slider, v759, "Width", 0, 350, 110);
    v51.new("scope_inner_color", v51.create_color, v759, "Inner color", l_color_0(255));
    v51.new("scope_outer_color", v51.create_color, v759, "Outer color", l_color_0(255, 0));
    v51.new("scope_lines", v51.create_list, v759, "Select lines", {
        [1] = "Top", 
        [2] = "Left", 
        [3] = "Right", 
        [4] = "Bottom"
    }, true, true);
    v51.new("scope_settings", v51.create_list, v759, "Additional settings", {
        [1] = "Spread Offset", 
        [2] = "Second Zoom"
    }, v39, true);
    v757 = v51.create_table(v754, "Window settings", false, 10);
    v51.new("select_window_settings", v51.create_list, v757, "Select window", {
        [1] = "Headup display", 
        [2] = "Keybinds", 
        [3] = "Logs", 
        [4] = "Side indicators", 
        [5] = "Velocity warning", 
        [6] = "Watermark"
    });
    if not v49.keyboard_handle then
        v51.new("warning_hud_text", v51.create_text, v757, "Hud warning", "Warning ! Custom chat doesnt work, do not press the keys to open chat if you enable hud");
    else
        v51.new("warning_hud_text", v51.create_text, v757, "Hud warning", "Warning ! Before you enable HUD, select your in game keybinds for chats");
    end;
    v51.new("enable_all_chat", v51.create_keybind, v757, "All chat", 89, true);
    v51.new("enable_team_chat", v51.create_keybind, v757, "Team chat", 85, true);
    v51.new("enable_hud", v51.create_checkbox, v757, "Enable HUD");
    v51.new("hud_ct_color", v51.create_color, v757, "Counter terrorist color", l_color_0(50, 50, 255, 255));
    v51.new("hud_t_color", v51.create_color, v757, "Terrorist color", l_color_0(255, 50, 50, 255));
    v51.new("hud_local_color", v51.create_color, v757, "Local kill color", l_color_0(255, 50, 50, 255));
    v51.new("enable_keybinds", v51.create_checkbox, v757, "Enable keybinds");
    v51.new("enable_logs", v51.create_checkbox, v757, "Enable logs");
    v51.new("logs_settings", v51.create_list, v757, "Specific logs settings", {
        [1] = "Hit", 
        [2] = "Miss", 
        [3] = "Purchase"
    });
    v51.new("logs_hit_enable", v51.create_list, v757, "Hit logs", {
        [1] = "Console", 
        [2] = "Screen"
    }, v39, true);
    v51.new("logs_hit_color", v51.create_color, v757, "Hit color", l_color_0(255));
    v51.new("logs_falsehit_color", v51.create_color, v757, "False hit color", l_color_0(255));
    v51.new("logs_kill_color", v51.create_color, v757, "Kill color", l_color_0(255));
    v51.new("logs_miss_enable", v51.create_list, v757, "Miss logs", {
        [1] = "Console", 
        [2] = "Screen"
    }, v39, true);
    v51.new("logs_correction_color", v51.create_color, v757, "Correction color", l_color_0(255));
    v51.new("logs_spread_color", v51.create_color, v757, "Spread color", l_color_0(255));
    v51.new("logs_othermiss_color", v51.create_color, v757, "Other miss color", l_color_0(255));
    v51.new("logs_purchase_enable", v51.create_checkbox, v757, "Purchase log");
    v51.new("logs_purchase_color", v51.create_color, v757, "Purchase color", l_color_0(255));
    v51.new("enable_side_indicators", v51.create_checkbox, v757, "Enable side indicators");
    v51.new("side_indicators_style", v51.create_list, v757, "Style", {
        [1] = "Original"
    });
    v51.new("side_indicators_mode", v51.create_list, v757, "Mode", {
        [1] = "Left Screen",
        [2] = "Crosshair",
        [3] = "Muzzle"
    });
    v51.new("side_indicators_options", v51.create_list, v757, "Options", {
        [1] = "Double tap / Hide shots", 
        [2] = "Min damage", 
        [3] = "Dormant aim", 
        [4] = "Auto peek", 
        [5] = "Freestand", 
        [6] = "Defensive snap"
    }, v39, true);
    v51.new("enable_velocity_warning", v51.create_checkbox, v757, "Enable velocity warning");
    v51.new("velocity_warning_effect", v51.create_checkbox, v757, "Warning view Effect");
    v51.new("enable_watermark", v51.create_checkbox, v757, "Enable watermark");
    v51.new("watermark_settings", v51.create_list, v757, "Watermark settings", {
        [1] = "Disable grid", 
        [2] = "Build", 
        [3] = "Name", 
        [4] = "Ping", 
        [5] = "Time"
    }, v39, true);
    v758 = v51.create_table(v754, "World", true, 7);
    v51.new("enable_damage", v51.create_checkbox, v758, "Enable damage markers");
    v51.new("damage_head_color", v51.create_color, v758, "Head damage color", l_color_0(255));
    v51.new("damage_other_color", v51.create_color, v758, "Other damage color", l_color_0(255));
    v51.new("damage_settings", v51.create_list, v758, "Damage settings", {
        [1] = "Glow", 
        [2] = "Animate", 
        [3] = "Local only"
    }, v39, true);
    v51.new("enable_shots", v51.create_checkbox, v758, "Enable shot markers");
    v51.new("hit_color", v51.create_color, v758, "Hit color", l_color_0(255));
    v51.new("miss_color", v51.create_color, v758, "Miss color", l_color_0(255));
    v51.new("manuals_indicators", v51.create_checkbox, v758, "Enable manuals indicators");
    v757 = v51.create_table(v755, "General", false, 4);
    v51.new("clantag", v51.create_checkbox, v757, "Enable clantag");
    v51.new("killsay", v51.create_checkbox, v757, "Enable killsay");
    v51.new("round_flash", v51.create_checkbox, v757, "Notify on round start");
    v51.new("remove", v51.create_list, v757, "Remove", {
        [1] = "Chat", 
        [2] = "Radar", 
        [3] = "Ragdoll Physics", 
        [4] = "Decals", 
        [5] = "Foot Shadow", 
        [6] = "Blood Splash", 
        [7] = "Unsused elements"
    }, v39, true);
    v758 = v51.create_table(v755, "Movement", false, 5);
    v51.new("fast_ladder", v51.create_checkbox, v758, "Fast ladder climb");
    v51.new("avoid_collisions", v51.create_checkbox, v758, "Avoid collisions");
    v51.new("slow_walk", v51.create_slider, v758, "Slow walk", 0, 75, 0, v39, {
        [0] = "Disable"
    });
    v759 = v51.create_table(v755, "Sound", true, 6);
    v51.new("local_hurt", v51.create_list, v759, "Local hurt sound", {
        [1] = "Disable", 
        [2] = "Switch", 
        [3] = "Warning", 
        [4] = "Wood Stop", 
        [5] = "Wood Strain", 
        [6] = "Wood Plank", 
        [7] = "Error 1", 
        [8] = "Woosh"
    });
    v51.new("local_hurt_volume", v51.create_slider, v759, "Sound volume", 0, 100, 80);
    v51.new("weapons_sounds", v51.create_checkbox, v759, "Override weapons sounds");
    v51.new("weapon_sound_pack", v51.create_list, v759, "Weapon Sound Pack", {
        [1] = "MW19 Custom", 
        [2] = "2018 Sounds"
    });
    v51.new("weapons_sounds_volume", v51.create_slider, v759, "Weapons volume", 0, 100, 30);
    local v762 = v51.create_table(v755, "Grenades", true, 4);
    v51.new("enable_smoke_helper", v51.create_checkbox, v762, "Smoke helper");
    v51.new("smoke_helper_key", v51.create_keybind, v762, "Smoke helper key");
    v51.new("smoke_helper_manual", v51.create_checkbox, v762, "Manual crosshair override");
    v51.new("smoke_helper_mode", v51.create_list, v762, "Smoke helper mode", {
        "Auto deploy",
        "Aim helper only"
    });

    v761 = v51.create_table(v755, "Weapons", false, 1);
    v51.new("select_weapon", v51.create_list, v761, "Select weapon", v51.weapons);
    for v778 = 1, #v51.weapons do
        local v779 = v51.weapons[v778];
        local v780 = v51.create_table(v755, v36("%s exploit", v779), false, 3);
        local v781 = v51.create_table(v755, v36("%s hitchace", v779), true, 3);
        v779 = v37(v779);
        v51.new(v36("%s_hideshots", v779), v51.create_checkbox, v780, "Adaptive hideshots");
        v51.new(v36("%s_uncharge_attack", v779), v51.create_checkbox, v780, "Uncharge attack");
        v51.new(v36("%s_uncharge_attack_delay", v779), v51.create_slider, v780, "Uncharge delay", 0, 10, 0);
        v51.new(v36("%s_allow_hideshots", v779), v51.create_checkbox, v780, "Allow hideshots teleport");
        v51.new(v36("%s_air_hitchance", v779), v51.create_slider, v781, "Air hitchance", -1, 100, -1, v39, {
            [-1] = "Disabled"
        });
        if v778 < 4 then
            v51.new(v36("%s_noscope_hitchance", v779), v51.create_slider, v781, "No scope hitchance", -1, 100, -1, v39, {
                [-1] = "Disabled"
            });
            v51.new(v36("%s_noscope_distance", v779), v51.create_slider, v781, "Distance limit", 0, 1000, 350);
        end;
    end;
    if v49.keyboard_handle then
        v757 = v51.create_table(v756, "result", true, 16);
        v758 = v51.create_text(v757, "search_result", "");
        v759 = v51.create_table(v756, "search_point", false, 6);
        v51.create_text(v759, "search_hint", "If you cannot find something. Just type in the text-box");
        do
            local l_v758_0 = v758;
            v51.create_input(v759, "Find", v39, function(v783)
                -- upvalues: v51 (ref), v37 (ref), v26 (ref), v50 (ref), v36 (ref), v27 (ref), v29 (ref), v39 (ref), l_v758_0 (ref), v25 (ref)
                local l_v783_0 = v783;
                if #l_v783_0 < 2 then
                    return;
                else
                    local v785 = {};
                    for v786 = 1, #v51.tabs_list do
                        local v787 = v51.tabs_list[v786];
                        for v788 = 1, #v787.tables do
                            local v789 = v787.tables[v788];
                            for v790 = 1, #v789.elements do
                                local v791 = v789.elements[v790];
                                local v792 = v37(v791._name);
                                local v793 = v37(l_v783_0);
                                if v26.find(v792, v37(l_v783_0)) then
                                    local v794 = v26.gsub(v792, v793, v26.format("\a%s%s\aDEFAULT", v50.colors.accent:to_hex(), v793));
                                    local v795 = #v785 + 1;
                                    local v796 = v36("%d. %s -> %s -> %s", v795, v787._name, v789._name, v794);
                                    v785[v795] = v26.wrap_text(v796, 290, "theme::font");
                                end;
                            end;
                        end;
                    end;
                    if #v785 > 20 then
                        return;
                    else
                        local v797 = v27.concat(v785, "\n");
                        size = v29.measure_text("theme::font", v39, v797);
                        l_v758_0.value = v797;
                        l_v758_0.menu_size = v25.ceil(size.y / 40);
                        return;
                    end;
                end;
            end);
        end;
    else
        v757 = v51.create_table(v756, "result", false, 10);
        v51.create_text(v757, "search_result", "Some error occurred on load, and therefore search option is not available");
    end;
    return true;
end;
v51.organize_elements = function()
    -- upvalues: v51 (ref), v29 (ref), v37 (ref), v36 (ref), v49 (ref), v39 (ref)
    if not v51.is_open() then
        return;
    else
        v29.animation_speed = v51.get("animation_speed");
        if v51.active_tab ~= 1 then
            if v51.active_tab == 2 then
                local v798 = v51.get("override_anti_aim");
                v51.visible("override_pitch", v798);
                v51.visible("override_yaw", v798);
                v51.visible("at_target_in_air", v798 and v51.get("override_yaw") == "Local view");
                v51.visible("anti_aim_mode", v798);
                v51.visible("select_preset", v798 and v51.get("anti_aim_mode") == "Auto presets");
                v51.visible("enable_preset_freestand", v798 and v51.get("anti_aim_mode") == "Auto presets");
                v51.visible("enable_anti_aim_misc", v798);
                v51.visible("resert_anti_bruteforce", v798 and v51.get("enable_anti_aim_misc")[2]);
                v51.visible("invert_freestand", v798 and v51.get("enable_anti_aim_misc")[7]);
                v51.visible("limit_freestand", v798 and v51.get("enable_anti_aim_misc")[7]);
                v51.visible("edge_yaw", v798);
                v51.visible("defensive_snap", v798);
                v51.visible("defensive_pitch", v798 and v51.has_bind("Defensive snap"));
                v51.visible("defensive_yaw", v798 and v51.has_bind("Defensive snap"));
                v51.visible("defensive_settings", v798 and v51.has_bind("Defensive snap"));
                v51.visible("manual_left", v798);
                v51.visible("manual_right", v798);
                v51.visible("manual_back", v798);
                local v799 = v798 and v51.get("anti_aim_mode") == "Default builder";
                v51.visible("default_states", v799);
                local v800 = v37(v51.get("default_states"));
                for v801 = 1, #v51.local_states do
                    local v802 = v37(v51.local_states[v801]);
                    local v803 = v802 == v800 and v799;
                    if v802 ~= "global" then
                        v51.visible(v36("enable_state_%s", v802), v803);
                    end;
                    local v804 = v803 and v51.get(v36("enable_state_%s", v802));
                    v51.visible(v36("select_sub_state_%s", v802), v804);
                    local v805 = v37(v51.get(v36("select_sub_state_%s", v802)));
                    for v806 = 1, 3 do
                        local v807 = v37(v51.sub_states[v806]);
                        local v808 = v36("%s_%s", v802, v807);
                        local v809 = v805 == v807 and v804;
                        if v807 ~= "regular" then
                            v51.visible(v36("enable_%s", v808), v809);
                        end;
                        local v810 = v809 and v51.get(v36("enable_%s", v808));
                        v51.visible(v36("yaw_left_%s", v808), v810);
                        v51.visible(v36("yaw_right_%s", v808), v810);
                        v51.visible(v36("yaw_modifier_%s", v808), v810);
                        local v811 = v51.get(v36("yaw_modifier_%s", v808));
                        v51.visible(v36("yaw_modifier_delta_%s", v808), v810 and v811 ~= "Disabled");
                        v51.visible(v36("yaw_modifier_mode_%s", v808), v810 and v811 == "Devided delta");
                        v51.visible(v36("left_limit_%s", v808), v810);
                        v51.visible(v36("right_limit_%s", v808), v810);
                        v51.visible(v36("fake_options_%s", v808), v810);
                        v51.visible(v36("freestand_desync_%s", v808), v810);
                    end;
                end;
            elseif v51.active_tab == 3 then
                v51.visible("bloom_scale", v51.get("enable_bloom"));
                v51.visible("exposure_scale", v51.get("enable_bloom"));
                v51.visible("model_brightness", v51.get("enable_bloom"));
                v51.visible("only_local_impacts", v51.get("enable_impacts"));
                v51.visible("impacts_color", v51.get("enable_impacts"));
                v51.visible("friendly_molotov_color", v51.get("enable_friendly_molotov"));
                local v812 = v51.get("select_animation_state");
                v51.visible("air_legs_movement", v812 == "In air");
                v51.visible("air_legs_movement_factor", v812 == "In air");
                v51.visible("air_body_lean_factor", v812 == "In air");
                v51.visible("move_legs_movement", v812 == "On move");
                v51.visible("move_legs_movement_factor", v812 == "On move");
                v51.visible("move_body_lean_factor", v812 == "On move");
                v51.visible("on_land_options", v812 == "On land");
                v812 = v51.get("select_view_list");
                local v813 = v812 == "View model" and v51.get("enable_view_model");
                local v814 = v812 == "Custom scope" and v51.get("enable_scope");
                v51.visible("aspect_ratio", v812 == "Aspect ratio");
                v51.visible("enable_view_model", v812 == "View model");
                v51.visible("view_offset_x", v813);
                v51.visible("view_offset_y", v813);
                v51.visible("view_offset_z", v813);
                v51.visible("view_offset_fov", v813);
                v51.visible("view_knife_opposite", v813);
                v51.visible("enable_scope", v812 == "Custom scope");
                v51.visible("scope_origin", v814);
                v51.visible("scope_width", v814);
                v51.visible("scope_inner_color", v814);
                v51.visible("scope_outer_color", v814);
                v51.visible("scope_lines", v814);
                v51.visible("scope_settings", v814);
            elseif v51.active_tab == 4 then
                local v815 = v51.get("select_window_settings");
                v51.visible("enable_keybinds", v815 == "Keybinds");
                v51.visible("enable_logs", v815 == "Logs");
                local v816 = v815 == "Logs" and v51.get("enable_logs");
                v51.visible("logs_settings", v816);
                local v817 = v816 and v51.get("logs_settings") == "Hit";
                v51.visible("logs_hit_enable", v817);
                v51.visible("logs_hit_color", v817);
                v51.visible("logs_falsehit_color", v817);
                v51.visible("logs_kill_color", v817);
                local v818 = v816 and v51.get("logs_settings") == "Miss";
                v51.visible("logs_miss_enable", v818);
                v51.visible("logs_correction_color", v818);
                v51.visible("logs_spread_color", v818);
                v51.visible("logs_othermiss_color", v818);
                local v819 = v816 and v51.get("logs_settings") == "Purchase";
                v51.visible("logs_purchase_enable", v819);
                v51.visible("logs_purchase_color", v819);
                v51.visible("warning_hud_text", v815 == "Headup display");
                v51.visible("enable_all_chat", v815 == "Headup display" and v49.keyboard_handle ~= v39);
                v51.visible("enable_team_chat", v815 == "Headup display" and v49.keyboard_handle ~= v39);
                v51.visible("enable_hud", v815 == "Headup display");
                v816 = v815 == "Headup display" and v51.get("enable_hud");
                v51.visible("hud_ct_color", v816);
                v51.visible("hud_t_color", v816);
                v51.visible("hud_local_color", v816);
                v51.visible("enable_side_indicators", v815 == "Side indicators");
                v51.visible("side_indicators_style", v815 == "Side indicators" and v51.get("enable_side_indicators"));
                v51.visible("side_indicators_mode", v815 == "Side indicators" and v51.get("enable_side_indicators"));
                v51.visible("side_indicators_options", v815 == "Side indicators" and v51.get("enable_side_indicators"));
                v51.visible("enable_velocity_warning", v815 == "Velocity warning");
                v51.visible("velocity_warning_effect", v815 == "Velocity warning" and v51.get("enable_velocity_warning"));
                v51.visible("enable_watermark", v815 == "Watermark");
                v51.visible("watermark_settings", v815 == "Watermark" and v51.get("enable_watermark"));
                v51.visible("damage_head_color", v51.get("enable_damage"));
                v51.visible("damage_other_color", v51.get("enable_damage"));
                v51.visible("damage_settings", v51.get("enable_damage"));
                v51.visible("hit_color", v51.get("enable_shots"));
                v51.visible("miss_color", v51.get("enable_shots"));
                v51.visible("manuals_indicators", v51.get("override_anti_aim"));
            elseif v51.active_tab == 5 then
                v51.visible("smoke_helper_key", v51.get("enable_smoke_helper"));
                v51.visible("smoke_helper_manual", v51.get("enable_smoke_helper"));
                v51.visible("smoke_helper_mode", v51.get("enable_smoke_helper"));
                local v820 = v51.get("select_weapon");
                for v821 = 1, #v51.weapons do
                    local v822 = v51.weapons[v821];
                    local v823 = v822 == v820;
                    v822 = v37(v822);
                    v51.visible(v36("%s_hideshots", v822), v823);
                    v51.visible(v36("%s_uncharge_attack", v822), v823);
                    local v824 = v51.get(v36("%s_uncharge_attack", v822));
                    v51.visible(v36("%s_uncharge_attack_delay", v822), v823 and v824);
                    v51.visible(v36("%s_allow_hideshots", v822), v823 and v824);
                    v51.visible(v36("%s_air_hitchance", v822), v823);
                    if v821 < 4 then
                        v51.visible(v36("%s_noscope_hitchance", v822), v823);
                        v51.visible(v36("%s_noscope_distance", v822), v823);
                    end;
                end;
            end;
        end;
        return;
    end;
end;
v51.destroy = function()
    -- upvalues: v51 (ref), v31 (ref)
    local v825 = v51.get_config();
    v31.write("csgo\\MadrillaRecode\\Configs\\AutoSave.Madrilla", v825);
end;
v51.initialize_window = function()
    -- upvalues: v51 (ref), v48 (ref), l_vector_0 (ref), v49 (ref)
    v51.window = v48.window("lua::ui::main_window", l_vector_0(100, 100), l_vector_0(780, 600));
    v51.window:register_render(v51.render_main_window, "lua::ui::main_window::render");
    v49.attach("render", v51.handle_keybinds, "lua::ui::handle_keybinds");
    v49.attach("render", v51.organize_elements, "lua::ui::organize_elements");
    v49.attach("mouse_input", v51.mouse_interact, "lua::ui::main::mouse_input");
    v49.attach("low_level_keyboard", v51.keyboard_interact, "lua::ui::main::keyboard_input");
    v49.attach("shutdown", v51.destroy, "lua::ui::unload");
    return true;
end;
v52.local_player = v32.get_local_player;
v52.thread = v32.get_threat;
v52.is_alive = false;
v52.is_in_air = false;
v52.is_fake_lag = false;
v52.is_crouch = false;
v52.update = function()
    -- upvalues: v52 (ref), v39 (ref), v30 (ref)
    v52.is_alive = v52.local_player() ~= v39 and v52.local_player().m_iHealth > 0;
    local v826 = v52.local_player() ~= v39 and v52.local_player().m_fFlags or v39;
    v52.is_in_air = v826 ~= v39 and bit.band(v826, 1) == 0 or v30.is_virtual_key_pressed(32);
    v52.is_fake_lag = v52.local_player() ~= v39 and rage.exploit:get() == 0;
    v52.is_crouch = v52.local_player() ~= v39 and v52.local_player().m_flDuckAmount > 0.1;
end;
v52.get_active_weapon = function()
    -- upvalues: v52 (ref), v39 (ref)
    local v827 = v52.local_player():get_player_weapon();
    if not v827 then
        return;
    else
        local v828 = v827:get_weapon_info();
        local v829 = v827:get_weapon_index();
        if v828.is_revolver then
            return "r8";
        elseif v829 == 1 then
            return "deagle";
        elseif v828.weapon_type == 1 then
            return "pistols";
        elseif v829 == 40 then
            return "scout";
        elseif v829 == 9 then
            return "awp";
        elseif v829 == 38 or v829 == 1 then
            return "auto";
        else
            return v39;
        end;
    end;
end;
v52.get_enemy = function()
    -- upvalues: v52 (ref), v39 (ref), v25 (ref), l_ipairs_0 (ref), v32 (ref)
    if not v52.local_player() then
        return v39;
    elseif not v52.local_player():is_alive() then
        return v39;
    else
        local v830 = v52.local_player():get_origin();
        local l_huge_0 = v25.huge;
        local l_v39_0 = v39;
        for _, v834 in l_ipairs_0(v32.get_players(true)) do
            if v834 and v834:is_alive() then
                local v835 = v830:dist((v834:get_origin()));
                if v835 <= l_huge_0 then
                    l_huge_0 = v835;
                    l_v39_0 = v834;
                end;
            end;
        end;
        return l_v39_0;
    end;
end;
v53.destroy = function()
    -- upvalues: v51 (ref), v39 (ref)
    v51.references.hide_shots_options:override(v39);
end;
v53.defensive_activity = 0;
v53.is_lag_exploiting = function(v836)
    -- upvalues: v30 (ref), v25 (ref), v53 (ref)
    local v837 = v30.net_channel();
    local v838 = v836:get_simulation_time();
    local v839 = v25.floor((v838.current - v838.old) / globals.tickinterval + 0.5);
    if v839 < 0 then
        v53.defensive_activity = globals.tickcount + v25.abs(v839) - v25.floor(v837.latency[0] / globals.tickinterval + 0.5);
    end;
    return v53.defensive_activity > globals.tickcount;
end;
v53.hideshots = function()
    -- upvalues: v52 (ref), v51 (ref), v36 (ref), v53 (ref), v32 (ref)
    if not v52.is_alive then
        return;
    else
        local v840 = v52.get_active_weapon();
        if not v840 then
            return;
        elseif not v51.get(v36("%s_hideshots", v840)) then
            v53.destroy();
            return;
        else
            local v841 = v32.get_threat(false);
            if not v841 then
                return;
            else
                v51.references.hide_shots_options:override((not v841:is_visible() or v53.is_lag_exploiting(v52.local_player())) and "Break LC" or "Favor Fire Rate");
                return;
            end;
        end;
    end;
end;
v53.did_teleport = false;
v53.safe_teleport = function()
    -- upvalues: v53 (ref)
    rage.exploit:force_teleport();
    rage.exploit:allow_charge(false);
    v53.did_teleport = true;
end;
v53.uncharge_attack = function()
    -- upvalues: v52 (ref), v51 (ref), v36 (ref), v32 (ref), v30 (ref), v53 (ref)
    if not v52.is_alive then
        return;
    else
        local v842 = v52.get_active_weapon();
        if not v842 then
            return;
        elseif not v51.get(v36("%s_uncharge_attack", v842)) then
            return;
        elseif not v51.get(v36("%s_allow_hideshots", v842)) and v51.references.hide_shots:get() and not v51.references.double_tap:get() then
            return;
        else
            local v843 = v51.get(v36("%s_uncharge_attack_delay", v842)) / 100;
            local v844 = v32.get_threat(true);
            if not v844 then
                return;
            elseif v30.is_virtual_key_pressed(32) then
                return;
            elseif v52.local_player().m_vecVelocity.z > -85 then
                return;
            elseif rage.exploit:get() ~= 1 then
                return;
            elseif v844.m_vecOrigin:dist(v52.local_player().m_vecOrigin) > 1000 or not v30.can_hit(v844) then
                return;
            else
                if v843 == 0 then
                    v53.safe_teleport();
                else
                    v30.execute_after(v843, v53.safe_teleport);
                end;
                return;
            end;
        end;
    end;
end;
v53.handle_charge = function()
    -- upvalues: v52 (ref), v53 (ref), v30 (ref)
    if not v52.is_alive then
        return;
    else
        if v53.did_teleport and not v52.is_in_air then
            v53.did_teleport = false;
            v30.execute_after(1, function()
                rage.exploit:allow_charge(true);
            end);
        end;
        return;
    end;
end;
v54.fixed_disable = false;
v54.destroy = function()
    -- upvalues: v54 (ref), v51 (ref), v39 (ref)
    if v54.fixed_disable then
        return;
    else
        for v845 = 1, #v51.weapons do
            v51.references.hitchance[v845]:override(v39);
            if v51.references.auto_scope[v845] then
                v51.references.auto_scope[v845]:override(v39);
            end;
        end;
        v54.fixed_disable = true;
        return;
    end;
end;
v54.update = function()
    -- upvalues: v52 (ref), v54 (ref), v51 (ref), v37 (ref), v36 (ref), v39 (ref), v25 (ref)
    if not v52.is_alive then
        v54.destroy();
        return;
    else
        local l_m_bIsScoped_0 = v52.local_player().m_bIsScoped;
        local v847 = v52.get_enemy();
        local v848 = -1;
        if v847 then
            v848 = v52.local_player():get_origin():dist(v847:get_origin());
        end;
        for v849 = 1, #v51.weapons do
            local v850 = v37(v51.weapons[v849]);
            local v851 = v849 < 4;
            local v852 = v851 and v848 ~= -1 and v848 < v51.get(v36("%s_noscope_distance", v850));
            local v853 = v851 and v51.get(v36("%s_noscope_hitchance", v850)) or -1;
            local v854 = v852 and v853 ~= -1 and not l_m_bIsScoped_0;
            local v855 = v51.get(v36("%s_air_hitchance", v850));
            local v856 = v855 ~= -1 and v52.is_in_air;
            if v51.references.auto_scope[v849] then
                if v854 then
                    v51.references.auto_scope[v849]:override(false);
                else
                    v51.references.auto_scope[v849]:override(v39);
                end;
            end;
            if not v856 and not v854 then
                v51.references.hitchance[v849]:override(v39);
            elseif v856 and not v854 then
                v51.references.hitchance[v849]:override(v855);
            elseif not v856 and v854 then
                v51.references.hitchance[v849]:override(v853);
            elseif v856 and v854 then
                v51.references.hitchance[v849]:override(v25.max(v853, v855));
            end;
        end;
        return;
    end;
end;
v55.disable_pitch = false;
v55.should_disable = false;
v55.createmove = function(v857)
    -- upvalues: v51 (ref), v55 (ref), v30 (ref), v52 (ref), v39 (ref), v32 (ref)
    if not v51.get("override_anti_aim") or not v51.get("enable_anti_aim_misc")[1] then
        v55.disable_pitch = false;
        return;
    else
        v55.disable_pitch = v30.is_virtual_key_pressed(69);
        v55.should_disable = false;
        local v858 = v52.local_player():get_origin();
        local v859 = v52.local_player():get_player_weapon();
        if v859 == v39 then
            return;
        else
            if v859:get_classname() == "CC4" then
                v55.should_disable = true;
            else
                local v860 = {};
                v860[#v860 + 1] = v32.get_entities(97);
                v860[#v860 + 1] = v32.get_entities("CPropDoorRotating");
                if v52.local_player().m_iTeamNum == 3 then
                    v860[#v860 + 1] = v32.get_entities(129);
                end;
                for v861 = 1, #v860 do
                    local v862 = v860[v861];
                    if v862 ~= v39 then
                        for v863 = 1, #v862 do
                            local v864 = v862[v863];
                            if v864 and v858:dist(v864.m_vecOrigin) < 120 then
                                v55.should_disable = true;
                                break;
                            end;
                        end;
                    end;
                    if v55.should_disable then
                        break;
                    end;
                end;
            end;
            if not v55.should_disable then
                v857.in_use = 0;
            end;
            return;
        end;
    end;
end;
v56.is_wall = false;
v56.yaw = 0;
v56.trace = v39;
v56.createmove = function(_)
    -- upvalues: v56 (ref), v51 (ref), v55 (ref), v52 (ref), v29 (ref), v39 (ref), v25 (ref), l_vector_0 (ref), v30 (ref)
    v56.is_wall = false;
    v56.yaw = 0;
    if not v51.get("override_anti_aim") or not v51.get_bind("Edge yaw") then
        return;
    elseif v55.disable_pitch or not v52.is_alive then
        return;
    else
        local v866 = v52.local_player():get_eye_position();
        if not v866 then
            return;
        else
            local v867 = v29.camera_angles();
            if not v867 then
                return;
            else
                local v868 = 8192;
                local l_v39_1 = v39;
                for v870 = v867.y - 90, v867.y + 90, 15 do
                    local v871 = v25.rad(v870);
                    local v872 = v866 + l_vector_0(v25.cos(v871) * 100, v25.sin(v871) * 100);
                    v56.trace = v30.trace_line(v866, v872, v52.local_player(), v39, 1);
                    if v56.trace.fraction * 100 < v868 then
                        v868 = v56.trace.fraction * 100;
                        l_v39_1 = v872;
                    end;
                end;
                if v868 > 30 then
                    return;
                else
                    local v873 = v866:calculate_angle(l_v39_1);
                    local v874 = v25.normalize_yaw(v867.y - 180);
                    local v875 = v25.normalize_yaw(v873 - v874);
                    v56.is_wall = true;
                    v56.yaw = v875;
                    return;
                end;
            end;
        end;
    end;
end;
v57.is_active = false;
v57.time = 0;
v57.misses = 0;
v57.is_enable = false;
v57.presets = db._MadrillaRecode_AntiBruteforce_ or {};
v57.create_copy = function()
    -- upvalues: v51 (ref)
    return {
        [1] = v51.references.yaw_modifier_offset:get_override() or v51.references.yaw_modifier_offset:get(), 
        [2] = v51.references.body_yaw_options:get_override() or v51.references.body_yaw_options:get(), 
        [3] = false
    };
end;
v57.detect_bullet = function(v876)
    -- upvalues: v57 (ref), v52 (ref), v32 (ref), v39 (ref), l_vector_0 (ref)
    if not v57.is_enable then
        return;
    elseif not v52.is_alive then
        return;
    elseif v57.time == globals.realtime then
        return;
    else
        local v877 = v32.get(v876.userid, true);
        if not v877 then
            return;
        elseif not v877:is_enemy() or v52.local_player() == v877 then
            return;
        else
            local l_x_0 = v876.x;
            local l_y_0 = v876.y;
            local l_z_0 = v876.z;
            if l_x_0 == v39 or l_y_0 == v39 or l_z_0 == v39 then
                return;
            else
                local v881 = l_vector_0(l_x_0, l_y_0, l_z_0);
                local v882 = v52.local_player():get_eye_position();
                if not v882 then
                    return;
                else
                    local v883 = v877:get_eye_position();
                    if not v883 then
                        return;
                    elseif v882:closest_ray_point(v881, v883):dist(v882) > 75 then
                        return;
                    else
                        v57.time = globals.realtime;
                        v57.misses = v57.misses + 1;
                        return;
                    end;
                end;
            end;
        end;
    end;
end;
v57.rework = function()
    -- upvalues: v57 (ref), v39 (ref), v25 (ref), v27 (ref)
    if v57.presets[v57.misses] == v39 then
        return;
    else
        v57.presets[v57.misses][1] = v25.random(-80, 40);
        if v25.random() > 0.5 then
            v27.delete(v57.presets[v57.misses][2], "Jitter");
            v57.presets[v57.misses][3] = v25.random() > 0.5;
        else
            v27.insert(v57.presets[v57.misses][2], "Jitter");
        end;
        return;
    end;
end;
v57.detect_hit = function(v884)
    -- upvalues: v57 (ref), v52 (ref), v32 (ref)
    if not v57.is_enable then
        return;
    elseif not v52.is_alive then
        return;
    elseif v57.time + 5 < globals.realtime or v57.misses == 0 then
        return;
    else
        local v885 = v32.get(v884.userid, true);
        if not v885 or v52.local_player() ~= v885 then
            return;
        else
            local l_hitgroup_0 = v884.hitgroup;
            if not l_hitgroup_0 or l_hitgroup_0 ~= 1 then
                return;
            else
                v57.rework();
                return;
            end;
        end;
    end;
end;
v57.createmove = function(_)
    -- upvalues: v57 (ref), v51 (ref), v52 (ref), v39 (ref)
    v57.is_active = false;
    v57.is_enable = v51.get("override_anti_aim") and v51.get("enable_anti_aim_misc")[2];
    if not v57.is_enable then
        return;
    elseif not v52.is_alive then
        return;
    elseif v57.time + 5 < globals.realtime then
        v57.misses = 0;
        return;
    else
        if not v57.presets[v57.misses] then
            v57.presets[v57.misses] = v57.create_copy();
            v57.rework();
        end;
        v57.is_active = v57.presets[v57.misses] ~= v39;
        return;
    end;
end;
v57.save = function()
    -- upvalues: v57 (ref)
    db._MadrillaRecode_AntiBruteforce_ = v57.presets;
end;
v58.manual_side = 0;
v58.last_key = v39;
v58.disable = false;
v58.override_settings = {
    yaw_offset = 0, 
    yaw_modifier = v39, 
    yaw_modifier_offset = v39, 
    body_options = {}, 
    left_limit = v39, 
    right_limit = v39, 
    freestand = v39
};
v58.fix_close = false;
v58.switch_pitch = 1;
v58.switch_yaw = 1;
v58.jitter_check = false;
v58.override_freestand = v39;
v58.should_freestand = false;
v58.angles = {
    [1] = 90, 
    [2] = 75, 
    [3] = 60, 
    [4] = 30, 
    [5] = -30, 
    [6] = 60, 
    [7] = 75, 
    [8] = 90
};
v58.delta_jitter = {
    override = {}, 
    setup = {}, 
    save = {}
};
v58.did_hit_ground = false;
v58.round_end = function(_)
    -- upvalues: v58 (ref)
    v58.disable = true;
end;
v58.round_start = function(_)
    -- upvalues: v58 (ref)
    v58.disable = false;
end;
v58.death = function(v890)
    -- upvalues: v32 (ref), v52 (ref), v58 (ref)
    local v891 = v32.get(v890.userid, true);
    if v891 and v891 == v52.local_player() then
        v58.manual_side = 0;
    end;
end;
v58.neverlose_ui = function(v892)
    -- upvalues: v51 (ref)
    v51.references.yaw_offset:disabled(v892);
    v51.references.yaw_modifier:disabled(v892);
    v51.references.yaw_modifier_offset:disabled(v892);
    v51.references.body_yaw_options:disabled(v892);
    v51.references.left_limit:disabled(v892);
    v51.references.right_limit:disabled(v892);
    v51.references.freestand_desync:disabled(v892);
    v51.references.hidden:disabled(v892);
end;
v58.static_settings = function(v893, v894)
    -- upvalues: v58 (ref)
    v58.override_settings.yaw_offset = 0;
    v58.override_settings.yaw_modifier = "Disabled";
    v58.override_settings.yaw_modifier_offset = 0;
    v58.override_settings.body_options = {
        [1] = ""
    };
    v58.override_settings.left_limit = v893 and 58 or 0;
    v58.override_settings.right_limit = v893 and 58 or 0;
    v58.override_settings.freestand = v894 and "Peek Fake" or "Off";
end;
v58.find_yaw = function(_)
    -- upvalues: v58 (ref), v55 (ref), v51 (ref), v52 (ref)
    if v58.manual_side ~= 0 or v55.disable_pitch then
        return "Local View";
    elseif v51.get("override_yaw") == "Local view" then
        if v52.is_in_air and v51.get("at_target_in_air") then
            return "At Target";
        else
            return "Local View";
        end;
    else
        return "At Target";
    end;
end;
v58.preform_overrides = function(v896)
    -- upvalues: v57 (ref), v58 (ref), v51 (ref), v56 (ref), v39 (ref), v27 (ref)
    local v897 = v57.presets[v57.misses];
    local v898 = v58.manual_side * 90;
    v51.references.yaw_offset:override(v56.is_wall and v58.manual_side == 0 and v56.yaw or v58.override_settings.yaw_offset + v898);
    v51.references.yaw_modifier:override(v58.override_settings.yaw_modifier);
    v51.references.left_limit:override(v58.override_settings.left_limit);
    v51.references.right_limit:override(v58.override_settings.right_limit);
    if v51.get("enable_anti_aim_misc")[7] then
        v51.references.freestand_desync:override("Off");
        if v58.override_freestand == v39 then
            v58.should_freestand = not v58.should_freestand;
            v51.references.body_yaw_options:override(v57.is_active and v897[2] or v58.override_settings.body_options);
        else
            local v899 = v51.references.body_yaw_options:get_override() or v51.references.body_yaw_options:get();
            v27.delete(v899, "Jitter");
            v51.references.body_yaw_options:override(v899);
        end;
        if v58.override_freestand == 0 then
            rage.antiaim:inverter(true);
        end;
        if v58.override_freestand == 1 then
            rage.antiaim:inverter(false);
        end;
        if v58.override_freestand == 2 then
            rage.antiaim:inverter(v58.should_freestand);
            if v896.choked_commands == 0 then
                v58.should_freestand = not v58.should_freestand;
            end;
        end;
    else
        v51.references.body_yaw_options:override(v57.is_active and v897[2] or v58.override_settings.body_options);
        v51.references.freestand_desync:override(v58.override_settings.freestand);
    end;
    if v57.is_active and not v27.find(v897[2], "Jitter") then
        rage.antiaim:inverter(v897[3]);
        v51.references.yaw_modifier_offset:override(0);
    else
        v51.references.yaw_modifier_offset:override(v57.is_active and v897[1] or v58.override_settings.yaw_modifier_offset);
    end;
end;
v58.preform_general = function(v900)
    -- upvalues: v55 (ref), v51 (ref), v58 (ref), v39 (ref), v52 (ref)
    local v901 = v55.disable_pitch or not v51.get("override_pitch");
    v51.references.pitch:override(v901 and "Disabled" or "Down");
    v901 = v55.disable_pitch or v51.get("override_yaw") == "None";
    v51.references.yaw:override(v901 and "Disabled" or "Backward");
    v51.references.yaw_base:override(v58.find_yaw(v900));
    if v55.disable_pitch then
        v51.references.freestand:override(false);
    else
        v51.references.freestand:override(v39);
    end;
    v901 = v51.get("enable_anti_aim_misc");
    if v901[4] and v58.disable and not v52.thread() then
        v51.references.anti_aim_enable:override(false);
    else
        v51.references.anti_aim_enable:override(v39);
    end;
    v51.references.lag_options:override(v901[3] and v52.is_in_air and "Always on" or v39);
end;
v58.auto_preset = function(_)
    -- upvalues: v51 (ref), v58 (ref)
    local v903 = v51.get("select_preset");
    if v903 == "Static" then
        v58.static_settings(true, v51.get("enable_preset_freestand"));
    elseif v903 == "Old Center" then
        v58.override_settings.yaw_offset = 0;
        v58.override_settings.yaw_modifier = "Center";
        v58.override_settings.yaw_modifier_offset = -73;
        v58.override_settings.body_options = {
            [1] = "Jitter"
        };
        v58.override_settings.left_limit = 58;
        v58.override_settings.right_limit = 58;
        v58.override_settings.freestand = "Off";
    elseif v903 == "Break" then
        v58.override_settings.yaw_offset = rage.antiaim:inverter() and -24 or 37;
        v58.override_settings.yaw_modifier = "Offset";
        v58.override_settings.yaw_modifier_offset = 26;
        v58.override_settings.body_options = {
            [1] = "Jitter", 
            [2] = "Randomize Jitter"
        };
        v58.override_settings.left_limit = 58;
        v58.override_settings.right_limit = 58;
        v58.override_settings.freestand = "Peek Real";
    end;
end;
v58.get_state = function()
    -- upvalues: v52 (ref), v30 (ref), v51 (ref)
    if not v52.local_player() then
        return "global";
    else
        local v904 = v52.local_player().m_vecVelocity:length2d();
        if v30.is_virtual_key_pressed(69) then
            return "use";
        elseif v52.is_in_air then
            return "air";
        elseif v904 <= 5 then
            return "stand";
        elseif v51.references.slow_walk:get() then
            return "slow walk";
        elseif v904 > 5 then
            return "move";
        else
            return "global";
        end;
    end;
end;
v58.get_sub_state = function()
    -- upvalues: v52 (ref)
    if v52.is_fake_lag then
        return "fake lag";
    elseif v52.is_crouch then
        return "crouch";
    else
        return "regular";
    end;
end;
v58.calculate_jitter = function(v905, v906, v907, v908)
    -- upvalues: v58 (ref), v25 (ref)
    if not v58.delta_jitter.override[v908] then
        v58.delta_jitter.override[v908] = 1;
    end;
    if not v58.delta_jitter.setup[v908] then
        v58.delta_jitter.setup[v908] = 0;
    end;
    if not v58.delta_jitter.save[v908] then
        v58.delta_jitter.save[v908] = v907;
    end;
    if v58.delta_jitter.save[v908] ~= v907 then
        v58.delta_jitter.override[v908] = 1;
        v58.delta_jitter.setup[v908] = 0;
        v58.delta_jitter.save[v908] = v907;
    end;
    local v909 = v58.delta_jitter.save[v908] / v906;
    if v905.command_number % 4 > 1 and v905.send_packet ~= false then
        if v25.abs(v58.delta_jitter.setup[v908]) > v25.abs(v58.delta_jitter.save[v908] + v909) then
            v58.delta_jitter.setup[v908] = 0;
        else
            v58.delta_jitter.setup[v908] = v58.delta_jitter.setup[v908] + v909 * v58.delta_jitter.override[v908];
            v58.delta_jitter.override[v908] = v58.delta_jitter.override[v908] * -1;
            v58.delta_jitter.setup[v908] = v58.delta_jitter.setup[v908] * v58.delta_jitter.override[v908];
        end;
    end;
    return v58.delta_jitter.setup[v908];
end;
v58.default_builder = function(v910)
    -- upvalues: v58 (ref), v51 (ref), v36 (ref)
    local v911 = v58.get_state();
    local v912 = v51.get(v36("enable_state_%s", v911)) and v911 or "global";
    local v913 = v58.get_sub_state();
    local v914 = v36("%s_%s", v912, v913);
    if not v51.get(v36("enable_%s", v914)) or not v914 then
        v914 = v36("%s_regular", v912);
    end;
    local v915 = rage.antiaim:inverter();
    local v916 = 0;
    local v917 = v51.get(v36("yaw_modifier_%s", v914));
    local v918 = v51.get(v36("yaw_modifier_delta_%s", v914));
    if v917 == "Devided delta" then
        v58.override_settings.yaw_modifier = "Disabled";
        v58.override_settings.yaw_modifier_offset = 0;
        v916 = v58.calculate_jitter(v910, v51.get(v36("yaw_modifier_mode_%s", v914)), v918, "Builder");
    else
        v58.override_settings.yaw_modifier = v917;
        v58.override_settings.yaw_modifier_offset = v918;
    end;
    v58.override_settings.yaw_offset = v916 + (v915 and v51.get(v36("yaw_left_%s", v914)) or v51.get(v36("yaw_right_%s", v914)));
    local v919 = {};
    local v920 = v51.get(v36("fake_options_%s", v914));
    if v920[1] then
        v919[#v919 + 1] = "Avoid Overlap";
    end;
    if v920[2] then
        v919[#v919 + 1] = "Jitter";
    end;
    if v920[3] then
        v919[#v919 + 1] = "Randomize Jitter";
    end;
    v58.override_settings.body_options = v919;
    v58.override_settings.left_limit = v51.get(v36("left_limit_%s", v914));
    v58.override_settings.right_limit = v51.get(v36("right_limit_%s", v914));
    v58.override_settings.freestand = v51.get(v36("freestand_desync_%s", v914));
end;
v58.decide_settings = function(v921)
    -- upvalues: v51 (ref), v32 (ref), v58 (ref)
    local v922 = v51.get("enable_anti_aim_misc");
    local v923 = v32.get_game_rules();
    if v922[5] and v58.manual_side ~= 0 or v922[6] and v923.m_bWarmupPeriod then
        return v58.static_settings(true, false);
    elseif v51.get("anti_aim_mode") == "Auto presets" then
        return v58.auto_preset();
    else
        v58.default_builder(v921);
        return;
    end;
end;
v58.manuals = function()
    -- upvalues: v52 (ref), v154 (ref), v51 (ref), v58 (ref), v39 (ref), v30 (ref)
    if not v52.is_alive then
        return;
    elseif v154.is_console_open() then
        return;
    elseif v51.get_bind("Manual back") then
        v58.manual_side = 0;
        return;
    else
        if v58.last_key == v39 and v51.get_bind("Manual right") then
            v58.manual_side = v58.manual_side == 1 and 0 or 1;
            v58.last_key = v51.binded_keys["Manual right"].key;
        end;
        if v58.last_key == v39 and v51.get_bind("Manual left") then
            v58.manual_side = v58.manual_side == -1 and 0 or -1;
            v58.last_key = v51.binded_keys["Manual left"].key;
        end;
        if v58.last_key and not v30.is_virtual_key_pressed(v58.last_key) then
            v58.last_key = v39;
        end;
        return;
    end;
end;
v58.get_freestand = function()
    -- upvalues: v51 (ref)
    local v924 = rage.antiaim:get_target();
    local v925 = rage.antiaim:get_target(true);
    if v925 and v924 and v51.references.freestand:get() then
        return v924 + v925;
    else
        return 0;
    end;
end;
v58.render_manuals = function()
    -- upvalues: v52 (ref), v154 (ref), v51 (ref), v58 (ref), v29 (ref), v50 (ref), l_vector_0 (ref)
    if not v52.is_alive then
        return;
    elseif v154.is_console_open() then
        return;
    elseif not v51.get("manuals_indicators") then
        return;
    else
        local v926 = v58.manual_side == -1;
        local v927 = v58.manual_side == 1;
        local v928 = v29.preform_animation("Manual Left", v926 and 1 or 0);
        local v929 = v29.preform_animation("Manual right", v927 and 1 or 0);
        local v930 = v29.preform_animation("Scope manuals offset", v52.local_player().m_bIsScoped and 1 or 0);
        local v931 = v51.icons.manual.size / 2;
        if v928 > 0 then
            v29.push_rotation(270);
            v29.texture(v51.icons.manual.img, v50.screen_size / 2 - v931 - l_vector_0((1 + v928) * 30, v930 * 20), v51.icons.manual.size, v50.colors.accent:override(v928));
            v29.pop_rotation();
        end;
        if v929 > 0 then
            v29.texture(v51.icons.manual.img, v50.screen_size / 2 - v931 + l_vector_0((1 + v929) * 30, -v930 * 20), v51.icons.manual.size, v50.colors.accent:override(v929));
        end;
        return;
    end;
end;
v58.defensive_switch = function()
    -- upvalues: v51 (ref), v58 (ref), v39 (ref), v25 (ref)
    if not v51.get_bind("Defensive snap") and not v58.did_hit_ground then
        v51.references.hidden:override(v39);
        return;
    else
        local v932 = v58.did_hit_ground and -2 or 0;
        local v933 = v51.get("defensive_pitch") + v932;
        local v934 = v51.get("defensive_yaw") + v932;
        local v935 = v51.get("defensive_settings");
        local v936 = v935[3] and -90 or -45;
        local v937 = v935[3] and 90 or 45;
        v51.references.hidden:override(true);
        if v935[1] then
            value = v25.lerp(89, -89, v25.sin(globals.curtime * (20 - v933) % 1));
            rage.antiaim:override_hidden_pitch(value);
        else
            if globals.tickcount % v933 == 0 then
                v58.switch_pitch = v58.switch_pitch * -1;
            end;
            rage.antiaim:override_hidden_pitch(v58.switch_pitch == 1 and -72 or 70);
        end;
        if v935[2] then
            value = v25.lerp(v936, v937, v25.sin(globals.curtime * (20 - v934) % 1));
            rage.antiaim:override_hidden_yaw_offset(value);
        else
            if globals.tickcount % v934 == 0 then
                v58.switch_yaw = v58.switch_yaw * -1;
            end;
            rage.antiaim:override_hidden_yaw_offset(v58.switch_yaw == 1 and v937 or v936);
        end;
        return;
    end;
end;
v58.update_freestand = function()
    -- upvalues: v58 (ref), v39 (ref), v51 (ref), v52 (ref), v25 (ref), l_vector_0 (ref), v30 (ref)
    v58.override_freestand = v39;
    if not v51.get("enable_anti_aim_misc")[7] then
        return;
    elseif not v52.thread() then
        return;
    else
        local v938 = 0;
        local v939 = 0;
        local v940 = v52.local_player():get_origin();
        local v941 = v52.thread():get_origin();
        local v942 = v940:calculate_angle(v941);
        local v943 = v940:dist(v941);
        if v52.thread():is_dormant() and v943 > 2000 then
            return;
        else
            local v944 = v52.local_player():get_hitbox_position(1);
            local v945 = v52.local_player().m_vecVelocity:length();
            v945 = v25.clamp(v945, 30, 200);
            local v946 = #v58.angles;
            if v51.get("limit_freestand") then
                if v946 ~= 4 then
                    v58.angles = {
                        [1] = 90, 
                        [2] = 45, 
                        [3] = -45, 
                        [4] = 90
                    };
                end;
            elseif v946 == 4 then
                v58.angles = {
                    [1] = 90, 
                    [2] = 75, 
                    [3] = 60, 
                    [4] = 30, 
                    [5] = -30, 
                    [6] = 60, 
                    [7] = 75, 
                    [8] = 90
                };
            end;
            for v947 = 1, #v58.angles do
                local v948 = v58.angles[v947];
                local v949 = v25.rad(v942 + v948);
                local v950 = v944 + l_vector_0(v25.cos(v949) * v945, v25.sin(v949) * v945, 0);
                local v951 = v30.get_worst_damage(v52.thread(), v950);
                if v948 > 0 then
                    if v938 < v951 then
                        v938 = v951;
                    end;
                elseif v939 < v951 then
                    v939 = v951;
                end;
            end;
            if v938 + v939 == 0 then
                return;
            else
                local v952 = v51.get("invert_freestand");
                if v939 < v938 then
                    v58.override_freestand = v952 and 1 or 0;
                elseif v938 < v939 then
                    v58.override_freestand = v952 and 0 or 1;
                else
                    v58.override_freestand = 2;
                end;
                return;
            end;
        end;
    end;
end;
v58.destroy = function()
    -- upvalues: v58 (ref), v57 (ref), v51 (ref), v39 (ref)
    v58.neverlose_ui(false);
    v57.save();
    v51.references.freestand:override(v39);
    v51.references.yaw:override(v39);
    v51.references.yaw_base:override(v39);
    v51.references.pitch:override(v39);
    v51.references.yaw_offset:override(v39);
    v51.references.yaw_modifier:override(v39);
    v51.references.yaw_modifier_offset:override(v39);
    v51.references.left_limit:override(v39);
    v51.references.right_limit:override(v39);
    v51.references.body_yaw_options:override(v39);
    v51.references.freestand_desync:override(v39);
    v51.references.anti_aim_enable:override(v39);
    v51.references.hidden:override(v39);
end;
v58.main = function(v953)
    -- upvalues: v51 (ref), v58 (ref), v52 (ref)
    if not v51.get("override_anti_aim") then
        if not v58.fix_close then
            v58.destroy();
            v58.fix_close = true;
        end;
        return;
    else
        v58.fix_close = false;
        if not v52.is_alive then
            return;
        else
            v51.references.body_yaw:override(true);
            v58.update_freestand();
            v58.preform_general(v953);
            v58.decide_settings(v953);
            v58.preform_overrides(v953);
            return;
        end;
    end;
end;
v58.each_frame = function()
    -- upvalues: v51 (ref), v52 (ref), v58 (ref)
    if not v51.get("override_anti_aim") then
        return;
    elseif not v52.is_alive then
        return;
    else
        v58.defensive_switch();
        v58.render_manuals();
        return;
    end;
end;
v60.settings = {};
v60.render = function()
    -- upvalues: v51 (ref), v39 (ref), v52 (ref), v50 (ref), v29 (ref), v25 (ref), l_vector_0 (ref)
    v51.references.scope:override(v39);
    if not v51.get("enable_scope") then
        return;
    elseif not v52.is_alive then
        return;
    else
        local v954 = v52.local_player():get_player_weapon();
        if not v954 then
            return;
        else
            v51.references.scope:override("Remove All");
            local v955 = {
                origin = v51.get("scope_origin"), 
                width = v51.get("scope_width"), 
                inner_color = v51.get("scope_inner_color"), 
                outer_color = v51.get("scope_outer_color"), 
                lines = v51.get("scope_lines"), 
                settings = v51.get("scope_settings")
            };
            local l_m_bIsScoped_1 = v52.local_player().m_bIsScoped;
            local v957 = v954:get_inaccuracy() * 100;
            local v958 = v50.screen_size / 2;
            local v959 = v29.preform_animation("Scope fade", l_m_bIsScoped_1 and 1 or 0);
            local v960 = v29.preform_animation("Scope spread", v955.settings[1] and l_m_bIsScoped_1 and v957 or 0);
            v29.preform_animation("Scope zoom", (v954.m_zoomLevel == 2 and 30 or 0) * v959);
            local v961 = {
                outer = v955.outer_color:override(v959), 
                inner = v955.inner_color:override(v959)
            };
            local v962 = v25.abs(v959 - 1);
            local v963 = v955.origin + v960;
            if v959 == 0 then
                return;
            else
                local v964 = v955.width + v963;
                local v965 = v955.width * v962 + v963;
                if v955.lines[1] then
                    v29.gradient(l_vector_0(v958.x, v958.y - v964), l_vector_0(v958.x + 1, v958.y - v965), v961.outer, v961.outer, v961.inner, v961.inner);
                end;
                if v955.lines[2] then
                    v29.gradient(l_vector_0(v958.x - v964, v958.y), l_vector_0(v958.x - v965, v958.y + 1), v961.outer, v961.inner, v961.outer, v961.inner);
                end;
                if v955.lines[3] then
                    v29.gradient(l_vector_0(v958.x + v965 + 1, v958.y), l_vector_0(v958.x + v964 + 1, v958.y + 1), v961.inner, v961.outer, v961.inner, v961.outer);
                end;
                if v955.lines[4] then
                    v29.gradient(l_vector_0(v958.x, v958.y + v965 + 1), l_vector_0(v958.x + 1, v958.y + v964 + 1), v961.inner, v961.inner, v961.outer, v961.outer);
                end;
                return;
            end;
        end;
    end;
end;
v60.view = function(v966)
    -- upvalues: v51 (ref), v52 (ref), v29 (ref)
    if not v51.get("enable_scope") or not v51.get("scope_settings")[2] then
        return;
    elseif not v52.is_alive then
        return;
    else
        local v967 = v29.get_animation_value("Scope zoom");
        if not v967 or v967 == 0 then
            return;
        else
            v966.fov = v966.fov - v967;
            return;
        end;
    end;
end;
v60.destroy = function()
    -- upvalues: v51 (ref), v39 (ref)
    v51.references.scope:override(v39);
end;
v61.cvars = {
    offset_x = cvar.viewmodel_offset_x, 
    offset_y = cvar.viewmodel_offset_y, 
    offset_z = cvar.viewmodel_offset_z, 
    fov = cvar.viewmodel_fov, 
    aspect_ration = cvar.r_aspectratio, 
    righthand = cvar.cl_righthand
};
v61.fix = {
    aspect_ration = false, 
    change_hand = false, 
    view_model = false, 
    aspect_ration_value = true, 
    original_hand = v61.cvars.righthand:int(), 
    aspect_ration_original = v50.screen_size.x / v50.screen_size.y
};
v29.create_animation("Aspect ratio", v61.fix.aspect_ration_original);
v61.override_view_model = function(v968, v969, v970, v971)
    -- upvalues: v61 (ref)
    v61.cvars.offset_x:int(v968, true);
    v61.cvars.offset_y:int(v969, true);
    v61.cvars.offset_z:int(v970, true);
    v61.cvars.fov:int(v971, true);
end;
v61.override_aspect_ration = function(v972)
    -- upvalues: v61 (ref)
    v61.cvars.aspect_ration:float(v972, true);
    v61.fix.aspect_ration_value = false;
end;
v61.override_knife = function()
    -- upvalues: v51 (ref), v52 (ref), v64 (ref), v61 (ref)
    value = v51.get("view_knife_opposite");
    player = v52.local_player();
    if not player then
        return;
    else
        weapon = player:get_player_weapon();
        if not weapon then
            return;
        else
            weapon_type = v64.weapons_type_sorted[weapon:get_weapon_info().weapon_type];
            if weapon_type == 3 then
                if value then
                    new_value = v61.fix.original_hand == 1 and 0 or 1;
                    v61.cvars.righthand:int(new_value);
                    v61.fix.change_hand = true;
                end;
                return;
            else
                if v61.fix.change_hand then
                    v61.cvars.righthand:int(v61.cvars.righthand:int() == 1 and 0 or 1);
                    v61.fix.change_hand = false;
                end;
                v61.fix.original_hand = v61.cvars.righthand:int();
                return;
            end;
        end;
    end;
end;
v61.view_model = function()
    -- upvalues: v51 (ref), v61 (ref)
    if not v51.get("enable_view_model") then
        if v61.fix.view_model then
            v61.override_view_model(0, 0, 0, 60);
            v61.cvars.righthand:int(v61.fix.original_hand);
            v61.fix.view_model = false;
        end;
        return;
    else
        v61.override_view_model(v51.get("view_offset_x"), v51.get("view_offset_y"), v51.get("view_offset_z"), v51.get("view_offset_fov"));
        v61.override_knife();
        v61.fix.view_model = true;
        return;
    end;
end;
v61.aspect_ratio = function()
    -- upvalues: v29 (ref), v61 (ref), v51 (ref), v50 (ref)
    local v973 = v29.get_animation_value("Aspect ratio");
    if v973 == 0 then
        v973 = v61.fix.aspect_ration_original;
    end;
    if v61.fix.aspect_ration_value then
        v61.override_aspect_ration(v973);
    end;
    local v974 = v51.get("aspect_ratio");
    if v974 == 0 then
        if v973 ~= v61.fix.aspect_ration_original then
            v29.preform_animation("Aspect ratio", v61.fix.aspect_ration_original);
            v61.fix.aspect_ration_value = true;
        end;
        return;
    else
        local v975 = v974 * 0.01;
        local v976 = v50.screen_size.x * v975 / v50.screen_size.y;
        v29.preform_animation("Aspect ratio", v976);
        v61.fix.aspect_ration_value = true;
        return;
    end;
end;
v61.render = function()
    -- upvalues: v52 (ref), v61 (ref)
    if not v52.is_alive then
        return;
    else
        v61.view_model();
        v61.aspect_ratio();
        return;
    end;
end;
v61.destroy = function()
    -- upvalues: v61 (ref)
    v61.fix.aspect_ration_value = true;
    v61.override_aspect_ration(0);
    v61.override_view_model(0, 0, 0, 60);
end;
v62.cvars = {
    disable_bloom = cvar.mat_disable_bloom, 
    model_brightness = cvar.r_modelAmbientMin
};
v62.fixed_bloom = false;
v62.fixed_splash_color = false;
v62.impact_material = v39;
v62.impact_color = l_color_0(255);
v62.override_bloom = function(v977, v978, v979, v980, v981)
    -- upvalues: v62 (ref), v32 (ref), l_ipairs_0 (ref)
    v62.cvars.model_brightness:float(v977, true);
    local v982 = v32.get_entities(69);
    for _, v984 in l_ipairs_0(v982) do
        v984.m_bUseCustomAutoExposureMin = v978;
        v984.m_bUseCustomAutoExposureMax = v978;
        v984.m_flCustomAutoExposureMin = v979;
        v984.m_flCustomAutoExposureMax = v980;
        v984.m_flCustomBloomScale = v981;
    end;
end;
v62.override_material_color = function(v985)
    -- upvalues: v62 (ref), v154 (ref)
    if not v62.impact_material then
        return;
    else
        v154.alpha_modulate(v62.impact_material, v985.a / 255);
        v154.color_modulate(v62.impact_material, v985.r / 255, v985.g / 255, v985.b / 255);
        v62.impact_color = v985;
        return;
    end;
end;
v62.render = function()
    -- upvalues: v62 (ref), v154 (ref), v39 (ref), v51 (ref), v27 (ref)
    if not globals.is_in_game then
        v62.fixed_splash_color = true;
        return;
    else
        if v62.fixed_splash_color then
            v62.impact_material = v154.find_material_by_name("effects/spark", v39, true, v39);
            v62.override_material_color(v51.get("impacts_color"));
            v62.fixed_splash_color = false;
        end;
        if not v51.get("enable_bloom") then
            if v62.fixed_bloom then
                v51.references.removlas:override(v51.references.removlas:get());
                v62.override_bloom(0, false, 0, 0, 0);
                v62.fixed_bloom = false;
            end;
            return;
        else
            local v986 = {
                bloom_scale = v51.get("bloom_scale") / 10, 
                exposure = v51.get("exposure_scale") / 100, 
                model_brightness = v51.get("model_brightness") / 10
            };
            if v62.cvars.disable_bloom:int() == 1 then
                v62.cvars.disable_bloom:int(0, true);
            end;
            v62.override_bloom(v986.model_brightness, true, v986.exposure, v986.exposure, v986.bloom_scale);
            local v987 = v51.references.removlas:get();
            v27.delete(v987, "Post Processing");
            v51.references.removlas:override(v987);
            v62.fixed_bloom = true;
            return;
        end;
    end;
end;
v62.impact = function(v988)
    -- upvalues: v51 (ref), v52 (ref), v32 (ref), v62 (ref), v154 (ref), v39 (ref), v33 (ref)
    if not v51.get("enable_impacts") then
        return;
    elseif not v52.is_alive then
        return;
    else
        local v989 = v32.get(v988.userid, true);
        if not v989 then
            return;
        else
            local v990 = v51.get("only_local_impacts");
            local v991 = v51.get("impacts_color");
            if v990 and v989 ~= v52.local_player() then
                return;
            else
                local l_x_1 = v988.x;
                local l_y_1 = v988.y;
                local l_z_1 = v988.z;
                if not l_x_1 or not l_y_1 or not l_z_1 then
                    return;
                else
                    if not v62.impact_material then
                        v62.impact_material = v154.find_material_by_name("effects/spark", v39, true, v39);
                    end;
                    if v991 ~= v62.impact_color then
                        v62.override_material_color(v991);
                    end;
                    v154.sparks(v33.vector_struct(l_x_1, l_y_1, l_z_1), 3, 2, v33.vector_struct());
                    return;
                end;
            end;
        end;
    end;
end;
v62.destroy = function()
    -- upvalues: v51 (ref), v62 (ref)
    v51.references.removlas:override(v51.references.removlas:get());
    v62.override_bloom(0, false, 0, 0, 0);
end;
v63.get_animation_overlay = function(v995, v996)
    -- upvalues: v33 (ref)
    local v997 = v33.cast("void***", v995[0]);
    return v33.cast("animation_overlay_t**", v33.cast("char*", v997) + 10640)[0][v996 or 0];
end;
v63.get_animation_state = function(v998)
    -- upvalues: v33 (ref)
    local v999 = v33.cast("void***", v998[0]);
    return v33.cast("animation_state_t**", v33.cast("char*", v999) + 39264)[0];
end;
v63.update = function(v1000)
    -- upvalues: v52 (ref), v63 (ref), v51 (ref), v58 (ref), v39 (ref)
    if not v1000 then
        return;
    elseif not v52.is_alive then
        return;
    elseif v1000 ~= v52.local_player() then
        return;
    else
        local v1001 = {
            [12] = v63.get_animation_overlay(v1000, 12), 
            [6] = v63.get_animation_overlay(v1000, 6), 
            [7] = v63.get_animation_overlay(v1000, 7)
        };
        if not v1001[12] or not v1001[6] or not v1001[7] then
            return;
        else
            local v1002 = v63.get_animation_state(v1000);
            if not v1002 then
                return;
            else
                local v1003 = {
                    on_land = v51.get("on_land_options"), 
                    air_legs = v51.get("air_legs_movement"), 
                    air_legs_factor = v51.get("air_legs_movement_factor"), 
                    air_body_factor = v51.get("air_body_lean_factor"), 
                    move_legs = v51.get("move_legs_movement"), 
                    move_legs_factor = v51.get("move_legs_movement_factor"), 
                    move_body_factor = v51.get("move_body_lean_factor")
                };
                v58.did_hit_ground = v1002.m_hit_ground_animation;
                if v1003.on_land == "Disable pitch" then
                    if v1002.m_hit_ground_animation and not common.is_button_down(32) then
                        v1000.m_flPoseParameter[12] = 0.5;
                    end;
                elseif v1003.on_land == "Disable crouch" then
                    v1002.m_hit_ground_animation = false;
                    v1002.m_hit_ground_weight = 1;
                    v1002.m_hit_ground_cycle = 0;
                end;
                local v1004 = v1000.m_vecVelocity:length2d();
                if v52.is_in_air then
                    if v1003.air_body_factor > 0 then
                        v1001[12].m_weight = v1003.air_body_factor / 100;
                        if v1003.move_body_factor == 101 then
                            v1001[7].m_weight = 1;
                            v1001[7].m_sequence = 7;
                        end;
                    end;
                    if v1003.air_legs == "Static" then
                        v1000.m_flPoseParameter[6] = 1 - v1003.air_legs_factor / 100;
                    end;
                    if v1003.air_legs == "Move" and v1004 > 5 then
                        v1001[6].m_weight = 1 - v1003.air_legs_factor / 100;
                    end;
                elseif v1004 > 5 and not v51.references.slow_walk:get() then
                    if v1003.move_body_factor > 0 then
                        v1001[12].m_weight = v1003.move_body_factor / 100;
                        if v1003.move_body_factor == 101 then
                            v1001[7].m_weight = 1;
                            v1001[7].m_sequence = 7;
                        end;
                    end;
                    if v1003.move_legs == "Static" then
                        v51.references.legs_movement:override("Sliding");
                        v1000.m_flPoseParameter[0] = v1003.move_legs_factor / 100;
                    end;
                    if v1003.move_legs == "Jitter" then
                        v51.references.legs_movement:override("Sliding");
                        if globals.tickcount % 4 > 1 then
                            v1000.m_flPoseParameter[0] = v1003.move_legs_factor / 100;
                        end;
                    end;
                    if v1003.move_legs == "Move" then
                        v51.references.legs_movement:override("Walking");
                        v1000.m_flPoseParameter[7] = v1003.move_legs_factor / 100;
                    end;
                end;
                if v1003.move_legs == "Regular" then
                    v51.references.legs_movement:override(v39);
                end;
                return;
            end;
        end;
    end;
end;
v63.destroy = function()
    -- upvalues: v51 (ref), v39 (ref)
    v51.references.legs_movement:override(v39);
end;
v63.transparency = function(v1005)
    -- upvalues: v51 (ref), v52 (ref), v29 (ref)
    if not v51.get("animate_transparency") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1006 = v52.local_player():get_player_weapon();
        if not v1006 then
            return;
        else
            local v1007 = v1006:get_weapon_info().weapon_type == 9;
            if not v52.local_player().m_bIsScoped then
                local _ = v1007;
            end;
            return (v29.preform_animation("Local transperecy", v1005, 30, 30));
        end;
    end;
end;
v64.enable = false;
v64.fixed_chat = false;
v64.safe_zone = l_vector_0(0, 0);
v64.fade = 0;
v64.prepare_ctrl = false;
v64.is_dead = false;
v64.player = v39;
v64.cvars = {
    freeze_time = cvar.mp_freezetime, 
    c4_timer = cvar.mp_c4timer, 
    draw_hud = cvar.cl_drawhud, 
    safe_zone_x = cvar.safezonex, 
    safe_zone_y = cvar.safezoneY, 
    crosshair_size = cvar.cl_crosshairsize, 
    crosshair_dot = cvar.cl_crosshairdot, 
    crosshair_gap = cvar.cl_crosshairgap, 
    crosshair_color = {
        r = cvar.cl_crosshaircolor_r, 
        g = cvar.cl_crosshaircolor_g, 
        b = cvar.cl_crosshaircolor_b, 
        a = cvar.cl_crosshairalpha
    }, 
    crosshair_t = cvar.cl_crosshair_t, 
    crosshair_outline = cvar.cl_crosshair_drawoutline, 
    hide_hud = cvar.hidehud
};
v64.weapons_type_sorted = {
    [0] = 3, 
    [1] = 2, 
    [2] = 1, 
    [3] = 1, 
    [4] = 1, 
    [5] = 1, 
    [6] = 1, 
    [7] = nil, 
    [8] = nil, 
    [9] = 4, 
    [10] = nil, 
    [11] = nil, 
    [12] = nil, 
    [13] = nil, 
    [14] = nil, 
    [15] = nil, 
    [16] = 3
};
v64.global_weapon_data = {
    last = v39, 
    time = globals.realtime
};
v64.weapons_names_load = {
    [1] = "usp_silencer", 
    [2] = "usp_silencer_off", 
    [3] = "inferno", 
    [4] = "hegrenade", 
    [5] = "flashbang", 
    [6] = "smokegrenade", 
    [7] = "decoy", 
    [8] = "molotov", 
    [9] = "ssg08", 
    [10] = "awp", 
    [11] = "g3sg1", 
    [12] = "scar20", 
    [13] = "deagle", 
    [14] = "revolver", 
    [15] = "glock", 
    [16] = "cz75a", 
    [17] = "p250", 
    [18] = "fiveseven", 
    [19] = "elite", 
    [20] = "tec9", 
    [21] = "hkp2000", 
    [22] = "mac10", 
    [23] = "mp9", 
    [24] = "mp7", 
    [25] = "ump45", 
    [26] = "bizon", 
    [27] = "p90", 
    [28] = "galilar", 
    [29] = "famas", 
    [30] = "ak47", 
    [31] = "m4a1", 
    [32] = "m4a1_silencer", 
    [33] = "m4a1_silencer_off", 
    [34] = "sg556", 
    [35] = "aug", 
    [36] = "nova", 
    [37] = "xm1014", 
    [38] = "sawedoff", 
    [39] = "mag7", 
    [40] = "m249", 
    [41] = "negev", 
    [42] = "knife_m9_bayonet", 
    [43] = "knife_widowmaker", 
    [44] = "knife", 
    [45] = "bayonet", 
    [46] = "knife_css", 
    [47] = "knife_flip", 
    [48] = "knife_gut", 
    [49] = "knife_karambit", 
    [50] = "knife_tactical", 
    [51] = "knife_falchion", 
    [52] = "knife_survival_bowie", 
    [53] = "knife_butterfly", 
    [54] = "knife_push", 
    [55] = "knife_cord", 
    [56] = "knife_canis", 
    [57] = "knife_ursus", 
    [58] = "knife_gypsy_jackknife", 
    [59] = "knife_outdoor", 
    [60] = "knife_stiletto", 
    [61] = "knife_skeleton", 
    [62] = "knife_t", 
    [63] = "planted_c4", 
    [64] = "taser"
};
v64.round_data = {
    message = "", 
    team_won = 0, 
    end_time = 0, 
    bomb_time = 0, 
    is_bomb_planted = false, 
    show_end = 0
};
v64.end_particals = {
    [1] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 1, 
        [1] = l_vector_0(-100, 120)
    }, 
    [2] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 1.1, 
        [1] = l_vector_0(100, 110)
    }, 
    [3] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 1.5, 
        [1] = l_vector_0(-70, 100)
    }, 
    [4] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 2, 
        [1] = l_vector_0(60, 150)
    }, 
    [5] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 2.3, 
        [1] = l_vector_0(-120, 120)
    }, 
    [6] = {
        [1] = nil, 
        [2] = 0, 
        [3] = 3, 
        [1] = l_vector_0(-40, 100)
    }
};
v64.enable_type = {
    all = false, 
    team = false
};
v64.csgo_hud = panorama.loadstring("        var is_visible = false;\n\n        var change_hud_state = function(new_opacity) {\n            var ctx_panel = $.GetContextPanel();\n            var panels = ['HudBottomRight', 'HudHealthArmor', 'HudTeamCounter', 'StatusPanel', 'HudDeathNotice', 'HudWinPanel', 'HudMoney', 'MoneyBG', 'spec_topbar'];\n            for (var i = 0; i < panels.length; i++) {\n                var p = ctx_panel.FindChildTraverse(panels[i]);\n                if (p && p.style) {\n                    p.style.opacity = new_opacity;\n                }\n            }\n        }\n\n        return {\n            change_hud_state: change_hud_state,\n        }\n    ", "CSGOHud")();
v64.string_to_send = "";
v64.weapons_icons = {};
v64.deaths = {};
v64.messages = {};
v64.last_error = "";
v64.initialize = function()
    -- upvalues: v64 (ref), v29 (ref), v26 (ref), v36 (ref)
    for v1009 = 1, #v64.weapons_names_load do
        local v1010 = v64.weapons_names_load[v1009];
        v64.weapons_icons[v1010] = v29.load_image_from_file(v26.format("materials/panorama/images/icons/equipment/%s.svg", v1010));
        if not v64.weapons_icons[v1010] then
            v64.last_error = v36("failed to load %s weapon icon", v1010);
            return false;
        end;
    end;
    return true;
end;
v64.setup = function()
    -- upvalues: v51 (ref), v52 (ref), v39 (ref), v64 (ref), v29 (ref), v32 (ref), l_vector_0 (ref), v50 (ref)
    local v1011 = v51.get("enable_hud") and v52.local_player() ~= v39;
    if v1011 then
        v64.fade = v29.do_animation(v64.fade, 1);
    else
        v64.fade = v29.do_animation(v64.fade, 0);
    end;
    v64.enable = v64.fade > 0;
    if not v52.local_player() then
        v64.player = v39;
    elseif not v52.is_alive then
        v64.player = v32.get(v52.local_player().m_hObserverTarget);
    else
        v64.player = v32.get_local_player();
    end;
    if not v1011 and not v64.enable then
        if v64.fixed_chat then
            v64.csgo_hud.change_hud_state(1);
            v64.fixed_chat = false;
        end;
        return;
    else
        local v1012 = l_vector_0(v50.screen_size.x / 2 - 10, v50.screen_size.y / 2 - 10);
        v64.safe_zone.x = v1012.x * (1 - v64.cvars.safe_zone_x:float());
        v64.safe_zone.y = v1012.y * (1 - v64.cvars.safe_zone_y:float());
        v64.fixed_chat = true;
        v64.csgo_hud.change_hud_state(0);
        return;
    end;
end;
v64.destroy = function()
    -- upvalues: v64 (ref)
    v64.csgo_hud.change_hud_state(1);
    v64.fixed_chat = false;
end;
v64.crosshair = function()
    -- upvalues: v64 (ref), l_color_0 (ref), v50 (ref), v29 (ref), l_vector_0 (ref)
    if not v64.enable then
        return;
    else
        return;
    end;
end;
v64.health_and_armor = function()
    -- upvalues: v64 (ref), v25 (ref), v29 (ref), l_vector_0 (ref), v50 (ref), v51 (ref), l_color_0 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1013 = v25.min(v64.player.m_iHealth, 100);
        local v1014 = v25.min(v64.player.m_ArmorValue or 0, 100);
        local v1015 = v1013 / 100;
        local v1016 = 1 - v1015;
        local v1017 = (100 - v1014) / 100;
        local v1018 = v29.preform_animation("Headup health", v1014 > 0 and 1 or 0) * v64.fade;
        local v1019 = l_vector_0(v64.safe_zone.x + 10, v50.screen_size.y - 50 - v1018 * 35 - v64.safe_zone.y);
        v50.render_background(v1019, v1019 + l_vector_0(100, 40 + v1018 * 35), v64.fade, 5);
        v29.texture(v51.icons.health.img, v1019 + l_vector_0(10, 5), v51.icons.health.size, l_color_0(255, v1015 * 255, v1015 * 255, 180 * v64.fade));
        v50.render_accent(v1019 + l_vector_0(51, 5 + 30 * v1016), v1019 + l_vector_0(53, 35), v64.fade, 2);
        v29.text("theme::font", v1019 + l_vector_0(75, 20), l_color_0(255, 180 * v64.fade), "c", v1013);
        if v1018 > 0 then
            v29.texture(v51.icons.armor.img, v1019 + l_vector_0(10, 40), v51.icons.armor.size, l_color_0(255, 180 * v1018));
            v50.render_accent(v1019 + l_vector_0(51, 40 + 30 * v1017), v1019 + l_vector_0(53, 70), v1018, 2);
            v29.text("theme::font", v1019 + l_vector_0(75, 55), l_color_0(255, 180 * v1018), "c", v1014);
        end;
        return;
    end;
end;
v64.get_weapons = function()
    -- upvalues: v64 (ref), v39 (ref), v32 (ref)
    local v1020 = {
        [1] = {}, 
        [2] = {}, 
        [3] = {}, 
        [4] = {}, 
        [5] = {}
    };
    if v64.player.m_hMyWeapons == v39 then
        return;
    else
        for v1021 = 0, 63 do
            local v1022 = v32.get(v64.player.m_hMyWeapons[v1021]);
            if v1022 then
                local l_weapon_type_0 = v1022:get_weapon_info().weapon_type;
                local v1024 = v64.weapons_type_sorted[l_weapon_type_0] or 5;
                v1020[v1024][#v1020[v1024] + 1] = v1022;
            end;
        end;
        return v1020;
    end;
end;
v64.weapons = function()
    -- upvalues: v64 (ref), l_vector_0 (ref), v50 (ref), v39 (ref), v29 (ref), v36 (ref), v27 (ref), l_color_0 (ref), v26 (ref), v25 (ref), v51 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1025 = l_vector_0(v50.screen_size.x - 10 - v64.safe_zone.x, v50.screen_size.y - v64.safe_zone.y);
        local v1026 = v64.get_weapons();
        if v1026 == v39 then
            return;
        else
            local v1027 = v64.player:get_player_weapon();
            if v1027 ~= v64.global_weapon_data.last then
                v64.global_weapon_data.last = v1027;
                v64.global_weapon_data.time = globals.realtime;
            end;
            local v1028 = v29.preform_animation("Headup global weapon", v64.global_weapon_data.time + 5 < globals.realtime and 0 or 1);
            local v1029 = 0;
            local v1030 = #v1026;
            for v1031 = 1, v1030 do
                local v1032 = v1026[v1031];
                assert(v1032, v36("Failed to index %d in weapons", v1031));
                local v1033 = v36("Headup - weapon %d", v1031);
                local v1034 = v1032[v27.find(v1032, v1027) or v1030 + 1];
                local v1035 = #v1032;
                local v1036 = v36("%s width", v1033);
                local v1037 = v36("%s warning", v1033);
                local v1038 = {
                    active = v29.preform_animation(v36("%s active", v1033), v1035 > 0 and v1034 and 1 or 0), 
                    valid = v29.preform_animation(v36("%s valid", v1033), v1035 > 0 and 1 or 0), 
                    warning = v29.get_animation_value(v1037), 
                    width = v29.get_animation_value(v1036)
                };
                local v1039 = v1038.active == 1 and 1 or v1028;
                local v1040 = v64.fade * v1039 * v1038.valid;
                if v1038.valid > 0 then
                    local v1041 = 10;
                    if v1038.warning > 0 then
                        v29.shadow(v1025 - l_vector_0(v1038.width, 50 - v1029), v1025 - l_vector_0(0, 10 - v1029), l_color_0(255, 10, 10, v1038.warning * v1040), 100, 0, 5);
                    end;
                    v50.render_background(v1025 - l_vector_0(v1038.width, 50 - v1029), v1025 - l_vector_0(0, 10 - v1029), v1040, 5);
                    for v1042 = 1, v1035 do
                        local v1043 = v1032[v1042];
                        if v1043 then
                            local v1044 = v1043:get_weapon_icon();
                            local v1045 = v1043 == v1027 and 1 or 0.5;
                            v29.texture(v1044, v1025 - l_vector_0(v1041 + v1044.width, 30 + v1044.height / 2 - v1029), l_vector_0(v1044.width, v1044.height), l_color_0(255, 180 * v1045 * v1040));
                            v1041 = v1041 + v1044.width + 10;
                        end;
                    end;
                    local v1046 = {
                        width = 0, 
                        text = "", 
                        warning = false
                    };
                    if v1031 == 1 or v1031 == 2 then
                        v1046.text = v1034 and v36("\a%s%s \aDEFAULT: %s", v50.colors.accent:to_hex(), v26.fixed_number(v1034.m_iClip1, 2), v26.fixed_number(v1034.m_iPrimaryReserveAmmoCount, 2)) or "";
                        v1046.width = (v29.original.measure_text(v29.font("theme::low"), v39, v1046.text).x + 30) * v1038.active;
                        if v1034 and v1034.m_iClip1 <= 3 then
                            v1046.warning = true;
                        end;
                    end;
                    local v1047 = v1046.warning and 40 or 0;
                    v29.preform_animation(v1037, v1046.warning and v25.abs(v25.sin(globals.realtime)) * 255 or 0);
                    v29.preform_animation(v1036, v1041 + v1046.width + v1047);
                    if v1038.active and v1034 then
                        if v1046.text ~= "" then
                            v50.render_accent(v1025 - l_vector_0(v1041 + 10, 45 - v1029), v1025 - l_vector_0(v1041 + 10 - 2, 15 - v1029), v1038.active * v64.fade);
                            v29.text("theme::low", v1025 - l_vector_0(v1038.width - 10, 38 - v1029), l_color_0(255, 180 * v1038.active * v64.fade), v39, v1046.text);
                        end;
                        if v1046.warning then
                            local v1048 = v25.abs(v25.sin(globals.realtime * 5)) * 180 * v1038.active * v64.fade;
                            v29.texture(v51.icons.warning.img, v1025 - l_vector_0(v1041 + 50, 45 - v1029), v51.icons.warning.size, l_color_0(255, 10, 10, v1048));
                        end;
                    end;
                end;
                v1029 = v1029 + -50 * v1038.valid * v1039;
            end;
            return;
        end;
    end;
end;
v64.get_player_color = function(v1049)
    -- upvalues: l_color_0 (ref), v51 (ref)
    local v1050 = l_color_0(255);
    if v1049.m_iTeamNum == 2 then
        v1050 = v51.get("hud_t_color");
    elseif v1049.m_iTeamNum == 3 then
        v1050 = v51.get("hud_ct_color");
    end;
    return v1050;
end;
v64.on_kill = function(v1051)
    -- upvalues: v64 (ref), v52 (ref), v32 (ref), v39 (ref), l_vector_0 (ref), v29 (ref), v51 (ref)
    if not v64.enable then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1052 = v32.get(v1051.attacker, true);
        local v1053 = v32.get(v1051.userid, true);
        if v1052 == v39 or v1053 == v39 then
            return;
        else
            local l_weapon_0 = v1051.weapon;
            if l_weapon_0 == v39 or l_weapon_0 == "world" then
                return;
            else
                local v1055 = v64.weapons_icons[l_weapon_0];
                if not v1055 then
                    return;
                else
                    local l_headshot_0 = v1051.headshot;
                    if l_headshot_0 == v39 then
                        return;
                    else
                        local v1057 = v1053:get_name();
                        local v1058 = v1052:get_name();
                        local v1059 = 20 / v1055.height;
                        local v1060 = l_vector_0(v1055.width * v1059, v1055.height * v1059);
                        local v1061 = v29.measure_text("theme::low", v39, v1057);
                        local v1062 = v29.measure_text("theme::low", v39, v1058);
                        local v1063 = l_headshot_0 and v51.icons.headshot.size.x + 10 or 0;
                        local v1064 = v1062.x + v1061.x + 64 + v1060.x + v1063 + 20;
                        local v1065 = v1052 == v52.local_player();
                        local v1066 = v1065 and v51.get("hud_local_color") or v64.get_player_color(v1052);
                        local v1067 = v64.get_player_color(v1053);
                        v64.deaths[#v64.deaths + 1] = {
                            fade = 0, 
                            victim = v1057, 
                            attacker = v1058, 
                            weapon = v1055, 
                            icon_size = v1060, 
                            victim_name_size = v1061, 
                            attacker_name_size = v1062, 
                            headshot_scale = v1063, 
                            width = v1064, 
                            time = globals.realtime, 
                            fade_time = v1065 and 9999 or 6, 
                            is_me = v1065, 
                            is_headshot = l_headshot_0, 
                            attacker_color = v1066, 
                            victim_color = v1067
                        };
                        return;
                    end;
                end;
            end;
        end;
    end;
end;
v64.clear_killfeed = function()
    -- upvalues: v27 (ref), v64 (ref)
    v27.clear(v64.deaths);
end;
v64.killfeed = function()
    -- upvalues: v64 (ref), l_vector_0 (ref), v50 (ref), v51 (ref), l_ipairs_0 (ref), v29 (ref), l_color_0 (ref), v39 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1068 = #v64.deaths;
        if v1068 == 0 then
            return;
        else
            local v1069 = l_vector_0(v50.screen_size.x - 10 - v64.safe_zone.x, 50 + v64.safe_zone.y);
            local v1070 = 0;
            local _ = v51.get("hud_local_color");
            for _, v1073 in l_ipairs_0(v64.deaths) do
                if not v51.references.preserve_kill_feed:get() and v1073.fade_time == 9999 then
                    v1073.fade_time = 6;
                end;
                if v1073.time + v1073.fade_time < globals.realtime then
                    v1073.fade = v29.do_animation(v1073.fade, 0);
                else
                    v1073.fade = v29.do_animation(v1073.fade, 1);
                end;
                if v1073.fade ~= 0 and v1073.weapon then
                    local v1074 = v1069 + l_vector_0(-v1073.width, v1070 * 40);
                    local _ = v1070 * 40 + 30;
                    local v1076 = v1073.fade * 180;
                    local v1077 = 20 + v1073.attacker_name_size.x;
                    v50.render_background(v1074, v1074 + l_vector_0(v1077, 30), v1073.fade, 5);
                    v29.text("theme::low", v1074 + l_vector_0(10, 7), l_color_0(255, v1076), v39, v1073.attacker);
                    v1077 = v1077 + 5;
                    v50.render_accent(v1074 + l_vector_0(v1077, 5), v1074 + l_vector_0(v1077 + 2, 25), v1073.fade, 2, v1073.attacker_color:override(v1073.fade));
                    v1077 = v1077 + 7;
                    v50.render_background(v1074 + l_vector_0(v1077, 0), v1074 + l_vector_0(v1077 + 20 + v1073.icon_size.x + v1073.headshot_scale, 30), v1073.fade, 5);
                    v29.texture(v1073.weapon, v1074 + l_vector_0(v1077 + 10, 15 - v1073.icon_size.y / 2), v1073.icon_size, l_color_0(255, v1076));
                    if v1073.is_headshot then
                        v29.texture(v51.icons.headshot.img, v1074 + l_vector_0(v1077 + 20 + v1073.icon_size.x, 15 - v51.icons.headshot.size.y / 2), v51.icons.headshot.size, l_color_0(255, v1076));
                    end;
                    v1077 = v1077 + 5 + 20 + v1073.icon_size.x + v1073.headshot_scale;
                    v50.render_accent(v1074 + l_vector_0(v1077, 5), v1074 + l_vector_0(v1077 + 2, 25), v1073.fade, 2, v1073.victim_color:override(v1073.fade));
                    v1077 = v1077 + 7;
                    v50.render_background(v1074 + l_vector_0(v1077, 0), v1074 + l_vector_0(v1077 + 20 + v1073.victim_name_size.x, 30), v1073.fade, 5);
                    v29.text("theme::low", v1074 + l_vector_0(v1077 + 10, 7), l_color_0(255, v1076), v39, v1073.victim);
                    v1070 = v1070 + v1073.fade;
                end;
            end;
            if v1070 == 0 and v1068 > 0 then
                v64.clear_killfeed();
            end;
            return;
        end;
    end;
end;
v64.round_start = function(_)
    -- upvalues: v64 (ref)
    if not v64.enable then
        return;
    else
        v64.clear_killfeed();
        v64.round_data.is_bomb_planted = false;
        v64.round_data.bomb_time = globals.curtime;
        return;
    end;
end;
v64.player_death = function(v1079)
    -- upvalues: v64 (ref), v52 (ref), v32 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1080 = v52.local_player();
        if not v1080 then
            return;
        else
            local v1081 = v32.get(v1079.userid, true);
            if not v1081 then
                return;
            else
                if v1080 == v1081 then
                    v64.is_dead = true;
                end;
                return;
            end;
        end;
    end;
end;
v64.player_spawn = function()
    -- upvalues: v64 (ref), v52 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1082 = v52.local_player();
        if not v1082 then
            return;
        else
            if v1082:is_alive() and v64.is_dead then
                v64.is_dead = false;
                v64.clear_killfeed();
            end;
            return;
        end;
    end;
end;
v64.round_end = function(v1083)
    -- upvalues: v64 (ref)
    if not v64.enable then
        return;
    elseif v1083.winner ~= 2 and v1083.winner ~= 3 then
        return;
    else
        v64.round_data.end_time = globals.realtime;
        v64.round_data.team_won = v1083.winner;
        v64.round_data.message = (v1083.winner == 3 and "Counter Terrorist" or v1083.winner == 2 and "Terrorist" or "?") .. " won the Round";
        return;
    end;
end;
v64.bomb_planted = function(_)
    -- upvalues: v64 (ref)
    if not v64.enable then
        return;
    else
        v64.round_data.is_bomb_planted = true;
        v64.round_data.bomb_time = globals.curtime;
        return;
    end;
end;
v64.get_round_time = function()
    -- upvalues: v32 (ref), v64 (ref), v25 (ref), v36 (ref), v26 (ref)
    local v1085 = v32.get_game_rules();
    local v1086 = v64.cvars.freeze_time:int();
    local v1087 = v64.round_data.is_bomb_planted and v64.cvars.c4_timer:int() or v1085.m_bFreezePeriod and v1086 or v1085.m_iRoundTime + v1086;
    local v1088 = v64.round_data.bomb_time + v1087 - globals.curtime;
    if v1088 <= 0 then
        return "00:00";
    else
        local v1089 = v25.floor(v1088 / 60);
        local v1090 = v25.floor(v1088 % 59);
        return (v36("%s:%s", v26.fixed_number(v1089, 2), v26.fixed_number(v1090, 2)));
    end;
end;
v64.get_players_alive = function()
    -- upvalues: v32 (ref)
    local v1091 = 0;
    local v1092 = 0;
    local v1093 = v32.get_players(false, true);
    if not v1093 then
        return;
    else
        for v1094 = 1, #v1093 do
            local v1095 = v1093[v1094];
            if v1095 then
                if v1095.m_iTeamNum == 2 and v1095:is_alive() then
                    v1092 = v1092 + 1;
                end;
                if v1095.m_iTeamNum == 3 and v1095:is_alive() then
                    v1091 = v1091 + 1;
                end;
            end;
        end;
        return v1091, v1092;
    end;
end;
v64.round = function()
    -- upvalues: v64 (ref), l_vector_0 (ref), v50 (ref), v32 (ref), v51 (ref), v29 (ref), v39 (ref), v25 (ref), l_color_0 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1096 = l_vector_0(v50.screen_size.x / 2, 10 + v64.safe_zone.y);
        local v1097 = v32.get_game_rules();
        local v1098 = v64.get_round_time();
        local v1099, v1100 = v64.get_players_alive();
        local v1101 = v32.get_entities("CCSTeam");
        if not v1101 then
            return;
        else
            local l_m_scoreTotal_0 = v1101[4].m_scoreTotal;
            local l_m_scoreTotal_1 = v1101[3].m_scoreTotal;
            local _ = v1097.m_bWarmupPeriod;
            local v1105 = v51.get("hud_t_color"):override(v64.fade);
            local v1106 = v51.get("hud_ct_color"):override(v64.fade);
            local v1107 = 180 * v64.fade;
            local v1108 = 0;
            local v1109 = v29.measure_text("theme::low", v39, v25.max(l_m_scoreTotal_0, l_m_scoreTotal_1)).x + 55;
            if v64.round_data.is_bomb_planted then
                v1108 = v25.abs(v25.sin(globals.realtime * 5)) * 255 * v64.fade;
                v29.shadow(v1096 + l_vector_0(-v1109, 0), v1096 + l_vector_0(v1109, 30), l_color_0(255, 10, 10, v1108), 100, 0, 5);
            end;
            v50.render_background(v1096 + l_vector_0(-v1109, 0), v1096 + l_vector_0(v1109, 30), v64.fade, 5);
            v29.text("theme::low", v1096 + l_vector_0(0, 15), l_color_0(255, v1107), "c", v1098);
            v29.text("theme::low", v1096 + l_vector_0(-50, 15), l_color_0(255, v1107), "c", l_m_scoreTotal_1);
            v29.text("theme::low", v1096 + l_vector_0(50, 15), l_color_0(255, v1107), "c", l_m_scoreTotal_0);
            v50.render_accent(v1096 + l_vector_0(-30, 2), v1096 + l_vector_0(-28, 28), v64.fade, 2, v1105);
            v50.render_accent(v1096 + l_vector_0(28, 2), v1096 + l_vector_0(30, 28), v64.fade, 2, v1106);
            v50.render_background(v1096 + l_vector_0(-150, 10), v1096 + l_vector_0(-100, 50), v64.fade, 5);
            v50.render_accent(v1096 + l_vector_0(-140, 30), v1096 + l_vector_0(-110, 32), v64.fade, 2, v1105);
            v29.text("theme::low", v1096 + l_vector_0(-125, 20), l_color_0(255, v1107), "c", v1100);
            v29.text("theme::low", v1096 + l_vector_0(-125, 40), l_color_0(255, v1107), "c", "alive");
            v50.render_background(v1096 + l_vector_0(100, 10), v1096 + l_vector_0(150, 50), v64.fade, 5);
            v50.render_accent(v1096 + l_vector_0(110, 30), v1096 + l_vector_0(140, 32), v64.fade, 2, v1106);
            v29.text("theme::low", v1096 + l_vector_0(125, 20), l_color_0(255, v1107), "c", v1099);
            v29.text("theme::low", v1096 + l_vector_0(125, 40), l_color_0(255, v1107), "c", "alive");
            local v1110 = v29.preform_animation("Headup - round end message", v64.round_data.end_time + 5 < globals.realtime and 0 or 1);
            local v1111 = (v29.measure_text("theme::low", v39, v64.round_data.message).x / 2 + 10) * v1110;
            if v1110 > 0 then
                local v1112 = l_color_0(255);
                if v64.round_data.team_won == 3 then
                    v1112 = v1106;
                elseif v64.round_data.team_won == 2 then
                    v1112 = v1105;
                end;
                for v1113 = 1, #v64.end_particals do
                    local v1114 = v64.end_particals[v1113];
                    v1114[2] = v29.do_animation(v1114[2], v64.round_data.end_time + v1114[3] < globals.realtime and 1 or 0);
                    local v1115 = 40 * v1114[2];
                    local v1116 = v25.abs(v1114[2] - 1);
                    v29.shadow(v1096 + v1114[1] - l_vector_0(v1115, v1115), v1096 + v1114[1] + l_vector_0(v1115, v1115), v1112.override(v1112, v1116), 200, 0, v1115);
                end;
                local v1117 = v1096 + l_vector_0(-v1111, 80 + 20 * v1110);
                local v1118 = v1096 + l_vector_0(v1111, 130 + 20 * v1110);
                v50.render_background(v1117, v1118, v64.fade * v1110, 5);
                v50.render_accent(v1096 + l_vector_0(-v1111 + 10, 135), v1096 + l_vector_0(v1111 - 10, 137), v64.fade * v1110, 2, v1112);
                v29.text("theme::low", v1096 + l_vector_0(0, 100 + 20 * v1110), l_color_0(255, v1107 * v1110), "c", v64.round_data.message);
            end;
            return;
        end;
    end;
end;
v64.capture_messages = function(v1119)
    -- upvalues: v64 (ref), v32 (ref), l_color_0 (ref), v51 (ref), v26 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1120 = v32.get(v1119.userid, true);
        if not v1120 then
            return;
        else
            local l_text_0 = v1119.text;
            if not l_text_0 then
                return;
            else
                local v1122 = v1120:is_alive() and "" or "DEAD \194\183 ";
                local v1123 = l_color_0(255);
                if v1120.m_iTeamNum == 3 then
                    v1123 = v51.get("hud_ct_color");
                elseif v1120.m_iTeamNum == 2 then
                    v1123 = v51.get("hud_t_color");
                end;
                v1123 = v1123.to_hex(v1123);
                local v1124 = v26.format("\aDEFAULT%s\a%s%s\aDEFAULT \194\183 %s", v1122, v1123, v1120:get_name(), l_text_0);
                v1124 = v26.wrap_text(v1124, 400, "theme::low");
                v64.messages[#v64.messages + 1] = {
                    fade = 0, 
                    text = v1124, 
                    time = globals.realtime
                };
                return;
            end;
        end;
    end;
end;
v64.enable_chat = function(_, v1126, v1127)
    -- upvalues: v64 (ref), v30 (ref), v154 (ref), v28 (ref), v33 (ref), v51 (ref)
    if not v64.enable then
        return;
    elseif not v30.is_csgo_selected() then
        return;
    elseif v154.is_console_open() then
        return;
    elseif v28.get_alpha() > 0 then
        return;
    elseif v64.enable_type.all or v64.enable_type.team then
        return;
    else
        local v1128 = v33.cast("keybaord_low_level_hook_t*", v1127);
        if v1126 ~= 256 then
            return;
        else
            local l_vkCode_1 = v1128.vkCode;
            local l_key_1 = v51.binded_keys["All chat"].key;
            local l_key_2 = v51.binded_keys["Team chat"].key;
            if l_vkCode_1 == l_key_1 then
                if v64.player then
                    v64.enable_type.all = true;
                end;
                return true;
            elseif l_vkCode_1 == l_key_2 then
                if v64.player then
                    v64.enable_type.team = true;
                end;
                return true;
            else
                return;
            end;
        end;
    end;
end;
v64.capture_input = function(_, v1133, v1134)
    -- upvalues: v64 (ref), v30 (ref), v154 (ref), v33 (ref), v51 (ref), v26 (ref)
    if not v64.enable then
        return;
    elseif not v30.is_csgo_selected() then
        return;
    elseif not v64.player then
        return;
    elseif v154.is_console_open() then
        return;
    elseif not v64.enable_type.all and not v64.enable_type.team then
        return;
    else
        local v1135 = v33.cast("keybaord_low_level_hook_t*", v1134);
        local l_vkCode_2 = v1135.vkCode;
        if v1133 == 257 and l_vkCode_2 == 162 then
            v64.prepare_ctrl = false;
        end;
        if v1133 == 260 then
            local l_key_3 = v51.binded_keys["All chat"].key;
            local l_key_4 = v51.binded_keys["Team chat"].key;
            if l_vkCode_2 == l_key_3 or l_vkCode_2 == l_key_4 then
                return true;
            end;
        end;
        if v1133 ~= 256 then
            return;
        elseif l_vkCode_2 == 27 then
            v64.enable_type.all = false;
            v64.enable_type.team = false;
            return true;
        elseif l_vkCode_2 == 13 then
            if v64.enable_type.team then
                v30.console_exec(v26.format("say_team \"%s\"", v64.string_to_send));
                v64.enable_type.team = false;
            end;
            if v64.enable_type.all then
                v30.console_exec(v26.format("say \"%s\"", v64.string_to_send));
                v64.enable_type.all = false;
            end;
            v64.string_to_send = "";
            return true;
        elseif l_vkCode_2 == 8 and v64.string_to_send ~= "" then
            if v64.prepare_ctrl then
                v64.string_to_send = "";
            else
                v64.string_to_send = v26.remove_last_char(v64.string_to_send);
            end;
            return true;
        elseif l_vkCode_2 == 162 then
            v64.prepare_ctrl = true;
            return true;
        elseif v51.invalid_vk[l_vkCode_2] then
            return;
        else
            if v64.prepare_ctrl then
                if l_vkCode_2 == 67 then
                    v30.set_clipboard(v64.string_to_send);
                    return true;
                elseif l_vkCode_2 == 86 then
                    local v1139 = v30.get_clipboard();
                    v1139 = v26.clear(v1139);
                    if v1139 ~= "" then
                        v64.string_to_send = v26.format("%s%s", v64.string_to_send, v1139);
                    end;
                    return true;
                end;
            end;
            local v1140 = v33.new("BYTE[256]");
            v33.C.GetKeyboardState(v1140);
            local v1141 = v33.C.GetKeyboardLayout(0);
            local v1142 = v33.new("wchar_t[3]");
            if v33.C.ToUnicodeEx(l_vkCode_2, v1135.scanCode, v1140, v1142, 3, 0, v1141) > 0 then
                local v1143 = v30.wide_char_to_multi_byte_string(v1142);
                if v1143 ~= "" then
                    v64.string_to_send = v26.format("%s%s", v64.string_to_send, tostring(v1143));
                end;
                return true;
            else
                return;
            end;
        end;
    end;
end;
v64.chat = function()
    -- upvalues: v64 (ref), l_vector_0 (ref), v50 (ref), v29 (ref), v26 (ref), v39 (ref), l_color_0 (ref), v25 (ref), v51 (ref), v27 (ref), v111 (ref), v30 (ref)
    if not v64.enable then
        return;
    elseif not v64.player then
        return;
    else
        local v1144 = l_vector_0(v64.safe_zone.x + 10, v50.screen_size.y - 120 - v64.safe_zone.y);
        local v1145 = v64.enable_type.all or v64.enable_type.team;
        local v1146 = v29.preform_animation("Headup - input show", v1145 and 1 or 0) * v64.fade;
        if v1146 > 0 then
            local v1147 = "";
            if v64.enable_type.all then
                v1147 = "All \194\183";
            elseif v64.enable_type.team then
                v1147 = "Team \194\183";
            end;
            v1147 = v26.format("%s %s", v1147, v64.string_to_send);
            local v1148 = v29.measure_text("theme::low", v39, v1147);
            local v1149 = v29.preform_animation("Headup - input width", v1148.x + 20, 2);
            v50.render_background(v1144, v1144 + l_vector_0(v1149, 20), v1146, 4);
            v29.push_clip_rect(v1144, v1144 + l_vector_0(v1149, 20));
            v29.text("theme::low", v1144 + l_vector_0(10, 10 - v1148.y / 2), l_color_0(255, 180 * v1146), v39, v1147);
            v29.pop_clip_rect();
            local v1150 = v25.abs(v25.sin(globals.realtime * 2));
            v50.render_accent(v1144 + l_vector_0(v1149 - 6, 2), v1144 + l_vector_0(v1149 - 4, 18), v1146 * v1150, 1);
        end;
        local v1151 = #v64.messages;
        if v51.get("remove")[1] then
            if v1151 > 0 then
                v27.clear(v64.messages);
            end;
            return;
        else
            if globals.is_in_game then
                if v1151 > 20 then
                    v27.remove(v64.messages, 1);
                end;
            elseif v1151 > 0 then
                v27.clear(v64.messages);
            end;
            v1144 = l_vector_0(v64.safe_zone.x + 10, v50.screen_size.y - 140 - v64.safe_zone.y);
            local v1152 = 0;
            for v1153 = v1151, 1, -1 do
                local v1154 = v64.messages[v1153];
                if v1154 then
                    if v1145 then
                        v1154.fade = v29.do_animation(v1154.fade, 1) * v64.fade;
                    else
                        v1154.fade = v29.do_animation(v1154.fade, v1154.time + 5 < globals.realtime and 0 or 1) * v64.fade;
                    end;
                    if v1154.fade > 0 then
                        local v1155 = v29.measure_text("theme::low", v39, v1154.text);
                        v50.render_background(v1144 + l_vector_0(0, v1152 - v1155.y), v1144 + l_vector_0(v1155.x + 10, v1152 + 10), v1154.fade, 5);
                        v29.text("theme::low", v1144 + l_vector_0(5, v1152 - v1155.y + 4), l_color_0(255, 180 * v1154.fade), v39, v1154.text);
                        if (v64.enable_type.all or v64.enable_type.team) and v111.is_left_pressed and v111.mouse_position:is_in_bounds(v1144 + l_vector_0(0, v1152 - v1155.y), l_vector_0(v1155.x + 10, v1155.y + 10)) and not v51.fix_press then
                            v51.fix_press = true;
                            v30.set_clipboard(v26.clear_color_codes(v26.gsub(v1154.text, "\194\183", ":")));
                        end;
                        v1152 = v1152 - (v1155.y + 20) * v1154.fade;
                    end;
                end;
            end;
            return;
        end;
    end;
end;
v64.capture_mouse = function()
    -- upvalues: v64 (ref)
    if not v64.enable then
        return;
    elseif v64.enable_type.all or v64.enable_type.team then
        return false;
    else
        return;
    end;
end;
v64.show_spectate = function()
    -- upvalues: v64 (ref), v52 (ref), v29 (ref), v26 (ref), v39 (ref), l_vector_0 (ref), v50 (ref), v25 (ref), l_color_0 (ref)
end;
v65.database = db._MadrillaRecode_Keybinds_Position or {
    y = 200, 
    x = 200
};
v65.window = v48.window("lua::keybinds", l_vector_0(v65.database.x, v65.database.y), l_vector_0(150, 30));
v65.modes = {
    [1] = "hold", 
    [2] = "toggle"
};
v65.find_value = function(v1156, v1157)
    -- upvalues: v162 (ref), v38 (ref), v27 (ref), v65 (ref), l_tostring_0 (ref)
    if v162(v1156) == "table" then
        local v1158 = {};
        for v1159 = 1, #v1156 do
            v1158[v1159] = v38(v1156[v1159], 1, 2);
        end;
        return (v27.concat(v1158, ", "));
    elseif v162(v1156) == "boolean" then
        return v65.modes[v1157];
    else
        return l_tostring_0(v1156);
    end;
end;
v65.is_any_active = false;
v65.get = function()
    -- upvalues: v28 (ref), v65 (ref), l_pairs_0 (ref), v51 (ref)
    local v1160 = {};
    local v1161 = v28.get_binds();
    v65.is_any_active = false;
    for v1162, v1163 in l_pairs_0(v51.binded_keys) do
        if not v1163.is_mode_disabled then
            v1160[#v1160 + 1] = {
                _name = v1162, 
                _is_active = v1163.value, 
                _value = v1163.mode
            };
            if v1163.value then
                v65.is_any_active = true;
            end;
        end;
    end;
    for v1164 = 1, #v1161 do
        local v1165 = v1161[v1164];
        v1160[#v1160 + 1] = {
            _name = v1165.name, 
            _is_active = v1165.active, 
            _value = v65.find_value(v1165.value, v1165.mode)
        };
        if v1165.active then
            v65.is_any_active = true;
        end;
    end;
    return v1160;
end;
v65.render = function(v1166)
    -- upvalues: v51 (ref), v65 (ref), v28 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref), v39 (ref), v25 (ref)
    local v1167 = v51.get("enable_keybinds");
    local v1168 = v65.get();
    local v1169 = #v1168;
    v1166:fade(v1167 and (v65.is_any_active or v28.get_alpha() > 0) and 1 or 0);
    if not v1167 and v1166._fade == 0 then
        return;
    else
        local v1170 = 0;
        local v1171 = 0;
        local l__position_0 = v1166._position;
        local v1173 = v29.get_animation_value("Keybinds pad width");
        v50.render_background(l__position_0 + l_vector_0(0, 2), l__position_0 + l_vector_0(38, 2 + v1166._size.y), v1166._fade, 5);
        v29.texture(v51.icons.keybinds.img, l__position_0 + l_vector_0(4, 2), v51.icons.keybinds.size, l_color_0(255, 150 * v1166._fade));
        local v1174 = v29.get_animation_value("Keybinds pad length");
        v50.render_accent(l__position_0 + l_vector_0(44, 0), l__position_0 + l_vector_0(46, v1174), v1166._fade, 2);
        local _ = v29.measure_text("theme::low", v39, "Keybinds");
        l__position_0 = l__position_0 + l_vector_0(54, 0);
        local v1176 = 4;
        for v1177 = 1, v1169 do
            local v1178 = v1168[v1177];
            local v1179 = v29.preform_animation(v1178._name, v1178._is_active and 1 or 0) * v1166._fade;
            local v1180 = v25.abs(v1179 - 1);
            local v1181 = v29.measure_text("theme::low", v39, v1178._name) + l_vector_0(10, 10);
            local v1182 = v29.measure_text("theme::low", v39, v1178._value) + l_vector_0(10, 10);
            if v1179 > 0 then
                if v1170 < v1182.x then
                    v1170 = v1182.x;
                end;
                if v1171 < v1181.x then
                    v1171 = v1181.x;
                end;
            end;
            local v1183 = l__position_0 + l_vector_0(10 * v1180, v1176);
            local v1184 = l__position_0 + l_vector_0(v1173 + 10, v1176);
            v50.render_background(v1183, v1183 + v1182, v1179, 5);
            v29.text("theme::low", v1183 + l_vector_0(5, 5), v50.colors.accent:override(v1179), v39, v1178._value);
            v50.render_background(v1184, v1184 + v1181, v1179, 5);
            v29.text("theme::low", v1184 + l_vector_0(5, 5), l_color_0(255, 180 * v1179), v39, v1178._name);
            v1176 = v1176 + 30 * v1179;
        end;
        v29.preform_animation("Keybinds pad length", v25.max(v1176, v1166._size.y), v39, 8);
        v29.preform_animation("Keybinds pad width", v1170, 1);
        v1166:override_position(l_vector_0(38, v1166._size.y));
        return;
    end;
end;
v65.destroy = function()
    -- upvalues: v65 (ref)
    db._MadrillaRecode_Keybinds_Position = {
        x = v65.window._position.x, 
        y = v65.window._position.y
    };
end;
v66.database = db._MadrillaRecode_Watermark_Position or {
    y = 10, 
    x = 10
};
v66.window = v48.window("lua::watermark", l_vector_0(v66.database.x, v66.database.y), l_vector_0(38, 30), v111.CENTER_ATTACH);
v66.render = function(v1185)
    -- upvalues: v51 (ref), v50 (ref), l_vector_0 (ref), v29 (ref), l_color_0 (ref), v39 (ref), v45 (ref), v30 (ref), v25 (ref), v36 (ref), v26 (ref), v111 (ref)
    local v1186 = v51.get("enable_watermark");
    local v1187 = v51.get("watermark_settings");
    v1185:fade(v1186 and 1 or 0);
    if v1185._fade == 0 then
        return;
    else
        local l__position_1 = v1185._position;
        v50.render_background(l__position_1, l__position_1 + l_vector_0(38, v1185._size.y), v1185._fade, 5);
        v29.texture(v51.icons.watermark.img, l__position_1 + l_vector_0(4, -2), v51.icons.watermark.size, l_color_0(255, 150 * v1185._fade));
        local v1189 = {
            build = v29.preform_animation("Watermark build", v1187[2] and 1 or 0) * v1185._fade, 
            name = v29.preform_animation("Watermark name", v1187[3] and 1 or 0) * v1185._fade, 
            ping = v29.preform_animation("Watermark ping", v1187[4] and 1 or 0) * v1185._fade, 
            time = v29.preform_animation("Watermark time", v1187[5] and 1 or 0) * v1185._fade
        };
        local v1190 = 50;
        if v1189.build > 0 or v1189.name > 0 or v1189.ping > 0 or v1189.time > 0 then
            local v1191 = v29.get_animation_value("Watermark width");
            v50.render_accent(l__position_1 + l_vector_0(43, 0), l__position_1 + l_vector_0(45, v1185._size.y), v1185._fade, 2);
            v50.render_background(l__position_1 + l_vector_0(50, 0), l__position_1 + l_vector_0(50 + v1191, v1185._size.y), v1185._fade, 5);
        end;
        if v1189.build > 0 then
            local v1192 = v29.measure_text("theme::low", v39, v45).x + 10;
            v29.text("theme::low", l__position_1 + l_vector_0(v1190 + 10, 7), l_color_0(255, 180 * v1189.build), v39, v45);
            v1190 = v1190 + (v1192 + 10) * v1189.build;
        end;
        if v1189.name > 0 then
            local v1193 = common.get_username();
            local v1194 = v29.measure_text("theme::low", v39, v1193).x + 10;
            v29.text("theme::low", l__position_1 + l_vector_0(v1190 + 10, 7), l_color_0(255, 180 * v1189.name), v39, v1193);
            v1190 = v1190 + (v1194 + 10) * v1189.name;
        end;
        if v1189.ping > 0 then
            local v1195 = v30.net_channel();
            local v1196 = v25.floor(v1195 and v1195.latency[1] * 1000 or 0);
            local v1197 = v36("%d ms", v1196);
            local v1198 = v29.measure_text("theme::low", v39, v1197).x + 10;
            v29.text("theme::low", l__position_1 + l_vector_0(v1190 + 10, 7), l_color_0(255, 180 * v1189.ping), v39, v1197);
            v1190 = v1190 + (v1198 + 10) * v1189.ping;
        end;
        if v1189.time > 0 then
            local v1199 = common.get_system_time();
            local v1200 = v36("%s:%s", v26.fixed_number(v1199.hours, 2), v26.fixed_number(v1199.minutes, 2));
            local v1201 = v29.measure_text("theme::low", v39, v1200).x + 10;
            v29.text("theme::low", l__position_1 + l_vector_0(v1190 + 10, 7), l_color_0(255, 180 * v1189.time), v39, v1200);
            v1190 = v1190 + (v1201 + 10) * v1189.time;
        end;
        v1185._size.x = v1190;
        v1190 = v1190 - 50;
        v29.preform_animation("Watermark width", v1190, 2);
        v1185:override_position(v1185._size);
        if not v1187[1] then
            v1185._attach = v111.CENTER_ATTACH;
        else
            v1185._attach = v111.NO_ATTACH;
        end;
        return;
    end;
end;
v66.destroy = function()
    -- upvalues: v66 (ref)
    db._MadrillaRecode_Watermark_Position = {
        x = v66.window._position.x, 
        y = v66.window._position.y
    };
end;
v67.hitboxes = {
    [0] = "generic", 
    [1] = "head", 
    [2] = "chest", 
    [3] = "stomach", 
    [4] = "left arm", 
    [5] = "right arm", 
    [6] = "left leg", 
    [7] = "right leg", 
    [8] = "neck", 
    [9] = "generic", 
    [10] = "gear"
};
v67.list = {};
v67.database = db._MadrillaRecode_LogSystem_Position or {
    y = 70, 
    x = 10
};
v67.window = v48.window("lua::log_system", l_vector_0(v67.database.x, v67.database.y), l_vector_0(100, 40), v111.CENTER_ATTACH);
v67.is_center = 0;
v67.rounds_count = 0;
v67.push_event = function(v1202, v1203, v1204)
    -- upvalues: v67 (ref)
    v67.list[#v67.list + 1] = {
        icon_fade = 0, 
        text_fade = 0, 
        text = v1202, 
        icon = v1203, 
        color = v1204, 
        time = globals.realtime
    };
end;
v67.get_text = function(v1205)
    -- upvalues: v36 (ref), v27 (ref)
    local v1206 = {};
    for v1207 = 1, #v1205, 2 do
        local v1208 = v1205[v1207];
        local v1209 = v1205[v1207 + 1];
        v1206[#v1206 + 1] = v36("\a%s%s", v1209:to_hex(), v1208);
    end;
    return v27.concat(v1206);
end;
v67.aim_fire = function(v1210)
    -- upvalues: v51 (ref), v39 (ref), v42 (ref), v67 (ref), l_tostring_0 (ref)
    if not v51.get("enable_logs") then
        return;
    else
        local l_state_0 = v1210.state;
        local l_target_0 = v1210.target;
        if not l_target_0 then
            return;
        else
            local v1213 = l_target_0:get_name();
            if l_state_0 == v39 then
                local v1214 = l_target_0.m_iHealth <= 0;
                local v1215 = v1210.wanted_damage > v1210.damage + 10;
                local v1216 = v51.get("logs_hit_color");
                if v1215 then
                    v1216 = v51.get("logs_falsehit_color");
                end;
                if v1214 then
                    v1216 = v51.get("logs_kill_color");
                end;
                local v1217 = v51.get("logs_hit_enable");
                local v1218 = v1215 and "false hit " or "hit ";
                if v1217[1] then
                    if v1214 then
                        print("  Madrilla  \194\183 ", v1216, "killed ", v42, v1213, v1216, " in ", v42, v67.hitboxes[v1210.hitgroup], v1216, ", bt ", v42, l_tostring_0(v1210.backtrack), v1216, " ticks", v42);
                    else
                        print("  Madrilla  \194\183 ", v1216, v1218, v42, v1213, v1216, "'s ", v42, v67.hitboxes[v1210.hitgroup], v1216, " for ", v42, l_tostring_0(v1210.damage), v1216, " damage (preferred ", v42, l_tostring_0(v1210.wanted_damage), v1216, "), bt ", v42, l_tostring_0(v1210.backtrack), v1216, " ticks", v42);
                    end;
                end;
                if v1217[2] then
                    local l_v39_2 = v39;
                    if v1214 then
                        l_v39_2 = {
                            [1] = "killed ", 
                            [2] = nil, 
                            [3] = nil, 
                            [4] = nil, 
                            [5] = " in ", 
                            [2] = v42, 
                            [3] = v1213, 
                            [4] = v1216, 
                            [6] = v42, 
                            [7] = v67.hitboxes[v1210.hitgroup], 
                            [8] = v1216
                        };
                    else
                        l_v39_2 = {
                            [1] = nil, 
                            [2] = nil, 
                            [3] = nil, 
                            [4] = nil, 
                            [5] = "'s ", 
                            [6] = nil, 
                            [7] = nil, 
                            [8] = nil, 
                            [9] = " for ", 
                            [10] = nil, 
                            [11] = nil, 
                            [12] = nil, 
                            [13] = " damage", 
                            [1] = v1218, 
                            [2] = v42, 
                            [3] = v1213, 
                            [4] = v1216, 
                            [6] = v42, 
                            [7] = v67.hitboxes[v1210.hitgroup], 
                            [8] = v1216, 
                            [10] = v42, 
                            [11] = l_tostring_0(v1210.damage), 
                            [12] = v1216, 
                            [14] = v42
                        };
                    end;
                    v67.push_event(v67.get_text(l_v39_2), v51.icons.hit, v1216);
                end;
                return;
            else
                local v1220 = v51.get("logs_othermiss_color");
                local v1221 = v51.get("logs_miss_enable");
                if l_state_0 == "correction" then
                    v1220 = v51.get("logs_correction_color");
                elseif l_state_0 == "spread" then
                    v1220 = v51.get("logs_spread_color");
                end;
                if v1221[1] then
                    print("  Madrilla  \194\183 ", v1220, "missed ", v42, v1213, v1220, "'s ", v42, v67.hitboxes[v1210.wanted_hitgroup], v1220, " due to ", v42, l_state_0, v1220, " (preferred ", v42, l_tostring_0(v1210.wanted_damage), v1220, " damage), bt ", v42, l_tostring_0(v1210.backtrack), v1220, " ticks", v42);
                end;
                if v1221[2] then
                    local v1222 = {
                        [1] = "missed ", 
                        [2] = nil, 
                        [3] = nil, 
                        [4] = nil, 
                        [5] = "'s ", 
                        [6] = nil, 
                        [7] = nil, 
                        [8] = nil, 
                        [9] = " due to ", 
                        [2] = v42, 
                        [3] = v1213, 
                        [4] = v1220, 
                        [6] = v42, 
                        [7] = v67.hitboxes[v1210.wanted_hitgroup], 
                        [8] = v1220, 
                        [10] = v42, 
                        [11] = l_state_0, 
                        [12] = v1220
                    };
                    v67.push_event(v67.get_text(v1222), v51.icons.miss, v1220);
                end;
                return;
            end;
        end;
    end;
end;
v67.grenades = function(v1223)
    -- upvalues: v51 (ref), v52 (ref), v32 (ref), l_tostring_0 (ref), v42 (ref), v67 (ref)
    if not v51.get("enable_logs") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1224 = v32.get(v1223.attacker, true);
        if not v1224 or v1224 ~= v52.local_player() then
            return;
        else
            local v1225 = v32.get(v1223.userid, true);
            if not v1225 then
                return;
            else
                local v1226 = v1225:get_name();
                local l_dmg_health_0 = v1223.dmg_health;
                if not l_dmg_health_0 then
                    return;
                else
                    local v1228 = l_tostring_0(v1223.weapon);
                    local v1229 = "";
                    if v1228 == "inferno" or v1228 == "hegrenade" then
                        v1229 = v1228 == "inferno" and "burned " or "naded ";
                        local v1230 = v1225.m_iHealth <= 0 and v51.get("logs_kill_color") or v51.get("logs_hit_color");
                        local v1231 = v51.get("logs_hit_enable");
                        if v1231[1] then
                            print("  Madrilla  \194\183 ", v1230, v1229, v42, v1226, v1230, " for ", v42, l_tostring_0(l_dmg_health_0), v1230, " damage", v42);
                        end;
                        if v1231[2] then
                            local v1232 = {
                                [1] = nil, 
                                [2] = nil, 
                                [3] = nil, 
                                [4] = nil, 
                                [5] = " for ", 
                                [6] = nil, 
                                [7] = nil, 
                                [8] = nil, 
                                [9] = " damage", 
                                [1] = v1229, 
                                [2] = v42, 
                                [3] = v1226, 
                                [4] = v1230, 
                                [6] = v42, 
                                [7] = l_tostring_0(l_dmg_health_0), 
                                [8] = v1230, 
                                [10] = v42
                            };
                            v67.push_event(v67.get_text(v1232), v51.icons.hit, v1230);
                        end;
                        return;
                    else
                        return;
                    end;
                end;
            end;
        end;
    end;
end;
v67.purshes = function(v1233)
    -- upvalues: v51 (ref), v52 (ref), v32 (ref), v26 (ref), v42 (ref)
    if not v51.get("enable_logs") or not v51.get("logs_purchase_enable") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1234 = v32.get(userid, true);
        if not v1234 then
            return;
        elseif v1233.team == v52.local_player().m_iTeamNum then
            return;
        else
            local v1235 = v51.get("logs_purchase_color");
            local l_weapon_1 = v1233.weapon;
            local v1237 = v1234:get_name();
            if v26.find(l_weapon_1, "weapon_") then
                l_weapon_1 = v26.gsub(l_weapon_1, "weapon_", "");
            end;
            if v26.find(l_weapon_1, "item_") then
                l_weapon_1 = v26.gsub(l_weapon_1, "item_", "");
            end;
            print("  Madrilla  \194\183 ", v1235, "player ", v42, v1237, v1235, " bought ", v42, l_weapon_1, v1235);
            return;
        end;
    end;
end;
v67.round_start = function()
    -- upvalues: v51 (ref), v67 (ref), v50 (ref), v42 (ref), l_tostring_0 (ref)
    if v51.get("enable_logs") then
        v67.rounds_count = v67.rounds_count + 1;
        print("\n");
        print("  Madrilla  \194\183 ", v50.colors.accent, "round number ", v42, l_tostring_0(v67.rounds_count), v50.colors.accent);
    end;
end;
v67.calculate = function(v1238)
    -- upvalues: v29 (ref), v39 (ref), l_vector_0 (ref)
    local v1239 = v29.measure_text("theme::low", v39, v1238.text);
    return l_vector_0(50 + (v1239.x + 10 + 12) * v1238.text_fade, 30), v1239;
end;
v67.render_log = function(v1240, v1241, v1242, v1243)
    -- upvalues: v50 (ref), l_vector_0 (ref), v29 (ref), l_color_0 (ref), v39 (ref)
    v50.render_background(v1241, v1241 + l_vector_0(40, v1242.y), v1240.icon_fade, 5);
    v29.texture(v1240.icon.img, v1241 + l_vector_0(5, 0), v1240.icon.size, v1240.color:override(v1240.icon_fade));
    v50.render_accent(v1241 + l_vector_0(45, 0), v1241 + l_vector_0(47, v1242.y), v1240.icon_fade, 2, v1240.color);
    v50.render_background(v1241 + l_vector_0(52, 0), v1241 + v1242, v1240.text_fade, 5);
    v29.push_clip_rect(v1241, v1241 + v1242, true);
    v29.text("theme::low", v1241 + l_vector_0(62, 15 - v1243.y / 2), l_color_0(255, 180 * v1240.text_fade), v39, v1240.text);
    v29.pop_clip_rect();
end;
v67.render = function(v1244)
    -- upvalues: v51 (ref), v28 (ref), v50 (ref), v67 (ref), l_vector_0 (ref), v29 (ref), v27 (ref)
    local v1245 = v51.get("enable_logs");
    local v1246 = nil;
    v1244:fade(v28.get_alpha() > 0 and v1245 and 1 or 0);
    local v1247 = {
        text = "this is example log, you can move this around", 
        icon = v51.icons.hit, 
        icon_fade = v1244._fade, 
        text_fade = v1244._fade, 
        color = v50.colors.accent
    };
    local v1248, v1249 = v67.calculate(v1247);
    v67.render_log(v1247, v1244._position, v1248, v1249);
    v1244:override_position(v1248);
    v1246 = l_vector_0(v1244._position.x, v1244._position.y);
    if v1244._is_attach then
        v1246.x = v50.screen_size.x / 2;
        v67.is_center = 1;
    else
        v1246.x = v1244._position.x;
        v67.is_center = 0;
    end;
    if not v1245 then
        return;
    else
        v1247 = 50 * v1244._fade;
        v1248 = false;
        v1249 = #v67.list;
        for v1250 = v1249, 1, -1 do
            local v1251 = v67.list[v1250];
            if v1251 then
                local v1252 = v1251.time + 5 < globals.realtime;
                local v1253, v1254 = v67.calculate(v1251);
                v67.render_log(v1251, v1246 + l_vector_0(-v1253.x / 2 * v67.is_center, v1247), v1253, v1254);
                v1247 = v1247 + (v1253.y + 10) * v1251.icon_fade;
                if v1252 then
                    v1251.text_fade = v29.do_animation(v1251.text_fade, 0);
                    if v1251.text_fade == 0 then
                        v1251.icon_fade = v29.do_animation(v1251.icon_fade, 0);
                    end;
                    if v1251.icon_fade ~= 0 then
                        v1248 = true;
                    end;
                else
                    v1248 = true;
                    v1251.icon_fade = v29.do_animation(v1251.icon_fade, 1);
                    if v1251.icon_fade == 1 then
                        v1251.text_fade = v29.do_animation(v1251.text_fade, 1);
                    end;
                end;
            end;
        end;
        if not v1248 and v1249 > 0 then
            v27.clear(v67.list);
        end;
        return;
    end;
end;
v67.destroy = function()
    -- upvalues: v67 (ref)
    db._MadrillaRecode_LogSystem_Position = {
        x = v67.window._position.x, 
        y = v67.window._position.y
    };
end;
v68.database = db._MadrillaRecode_WarningSystem_Position or {
    y = 100, 
    x = v50.screen_size.x / 2 - 60
};
v68.window = v48.window("lua::warning_system", l_vector_0(v68.database.x, v68.database.y), l_vector_0(150, 30), v111.CENTER_ATTACH);
v68.window:register("view_fade", 0);
v68.render = function(v1255)
    -- upvalues: v52 (ref), v51 (ref), v28 (ref), v29 (ref), v39 (ref), v25 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
    if not v52.local_player() then
        return;
    else
        local l_m_flVelocityModifier_0 = v52.local_player().m_flVelocityModifier;
        if not l_m_flVelocityModifier_0 then
            return;
        else
            if not v51.get("enable_velocity_warning") then
                if v1255._fade == 0 then
                    return;
                else
                    v1255:fade(0);
                end;
            else
                v1255:fade((not (v28.get_alpha() <= 0) or l_m_flVelocityModifier_0 < 1) and 1 or 0);
            end;
            v1255.view_fade = v29.do_animation(v1255.view_fade, l_m_flVelocityModifier_0);
            if v1255._fade > 0 then
                local v1257 = v29.measure_text("theme::low", v39, "Slowed down");
                local v1258 = v25.abs(v25.sin(globals.realtime * 4)) * v1255._fade;
                v50.render_background(v1255._position, v1255._position + l_vector_0(52 + v1257.x + 10, v1255._size.y), v1255._fade, 5);
                v29.texture(v51.icons.warning.img, v1255._position + l_vector_0(5, 0), v51.icons.warning.size, l_color_0(255, 10, 10, 255 * v1258));
                local v1259 = v29.preform_animation("Velocity dropdown", v1255._size.y * l_m_flVelocityModifier_0, v39, 8);
                v50.render_accent(v1255._position + l_vector_0(45, 0), v1255._position + l_vector_0(47, v1259), v1255._fade, 2);
                v29.text("theme::low", v1255._position + l_vector_0(57, 7), l_color_0(255, 180 * v1255._fade), v39, "Slowed down");
                v1255._size.x = 62 + v1257.x;
                v1255:override_position(v1255._size);
                if v25.abs(v50.screen_size.x / 2 - (v1255._position.x + v1255._size.x / 2)) < 50 then
                    v1255._position.x = v50.screen_size.x / 2 - v1255._size.x / 2;
                end;
            end;
            return;
        end;
    end;
end;
v68.view = function(v1260)
    -- upvalues: v51 (ref), v52 (ref), v68 (ref)
    if not v51.get("enable_velocity_warning") or not v51.get("velocity_warning_effect") then
        return;
    elseif not v52.is_alive then
        return;
    else
        if v68.window.view_fade < 1 then
            v1260.fov = v1260.fov - 10 * v68.window._fade * (1 - v68.window.view_fade);
        end;
        return;
    end;
end;
v68.destroy = function()
    -- upvalues: v68 (ref)
    db._MadrillaRecode_WarningSystem_Position = {
        x = v68.window._position.x, 
        y = v68.window._position.y
    };
end;
v69.right_hand = cvar.cl_righthand;
v69.lagcompensation = cvar.cl_lagcompensation;
v69.list = {
    [1] = function(v1261)
        -- upvalues: v51 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
        local v1262 = v51.references.hide_shots:get();
        local v1263 = v51.references.double_tap:get();
        local v1264 = v1263 or v1262;
        local v1265 = v29.preform_animation("Side indicator - double tap", v1264 and 1 or 0);
        if v1265 > 0 then
            local v1266 = v29.preform_animation("Side indicator - hideshors", (not v1262 or v1263) and 1 or 0.2) * v1265;
            local v1267 = v29.preform_animation("Side indicator - double tap charged", rage.exploit:get()) * v1265;
            v50.render_background(v1261, v1261 + l_vector_0(40 + 20 * v1267, 40), v1265, 5);
            v29.texture(v51.icons.arrow.img, v1261 + l_vector_0(10, 5), v51.icons.arrow.size, l_color_0(255, 255 * v1266));
            v29.texture(v51.icons.arrow.img, v1261 + l_vector_0(10 + 15 * v1267, 5), v51.icons.arrow.size, v50.colors.accent:override(v1267));
        end;
        return v1265;
    end, 
    [2] = function(v1268)
        -- upvalues: v28 (ref), v51 (ref), v29 (ref), v25 (ref), v39 (ref), l_vector_0 (ref), v50 (ref), l_color_0 (ref)
        local v1269 = v28.get_binds();
        local v1270 = false;
        local v1271 = v51.references.min_damage:get();
        for v1272 = 1, #v1269 do
            local v1273 = v1269[v1272];
            if v1273.name == "Min. Damage" and v1273.active then
                v1270 = true;
                v1271 = v1273.value;
                break;
            end;
        end;
        local v1274 = v29.preform_animation("Side indicator - min damage", v1270 and 1 or 0);
        v1271 = v29.preform_animation("Side indicator - min damage value", v1271, 1, 16);
        v1271 = v25.floor(v1271);
        if v1274 > 0 then
            local v1275 = v29.measure_text("theme::high", v39, v1271);
            local v1276 = l_vector_0(30 + v1275.x + 30, 40);
            v50.render_background(v1268, v1268 + v1276, v1274, 5);
            v29.texture(v51.icons.bullet.img, v1268 + l_vector_0(10, 5), v51.icons.bullet.size, l_color_0(255, 255 * v1274));
            v29.text("theme::high", v1268 + l_vector_0(50, 20 - v1275.y / 2), v50.colors.accent:override(v1274), v39, v1271);
        end;
        return v1274;
    end, 
    [3] = function(v1277)
        -- upvalues: v51 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
        local v1278 = v51.references.dormant_aimbot:get();
        local v1279 = v29.preform_animation("Side indicator - dormant", v1278 and 1 or 0);
        if v1279 > 0 then
            v50.render_background(v1277, v1277 + l_vector_0(50, 40), v1279, 5);
            v29.texture(v51.icons.blind.img, v1277 + l_vector_0(10, 5), v51.icons.blind.size, l_color_0(255, 255 * v1279));
        end;
        return v1279;
    end, 
    [4] = function(v1280)
        -- upvalues: v51 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
        local v1281 = v51.references.auto_peek:get();
        local v1282 = v29.preform_animation("Side indicator - auto peek", v1281 and 1 or 0);
        if v1282 > 0 then
            v50.render_background(v1280, v1280 + l_vector_0(50, 40), v1282, 5);
            v29.texture(v51.icons.location.img, v1280 + l_vector_0(10, 5), v51.icons.location.size, l_color_0(255, 255 * v1282));
        end;
        return v1282;
    end, 
    [5] = function(v1283)
        -- upvalues: v51 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
        local v1284 = v51.references.freestand:get();
        local v1285 = v29.preform_animation("Side indicator - freestand", v1284 and 1 or 0);
        if v1285 > 0 then
            v50.render_background(v1283, v1283 + l_vector_0(50, 40), v1285, 5);
            v29.texture(v51.icons.radar.img, v1283 + l_vector_0(10, 5), v51.icons.radar.size, l_color_0(255, 255 * v1285));
        end;
        return v1285;
    end, 
    [6] = function(v1286)
        -- upvalues: v51 (ref), v29 (ref), v50 (ref), l_vector_0 (ref), l_color_0 (ref)
        local v1287 = v51.get_bind("Defensive snap");
        local v1288 = v29.preform_animation("Side indicator - defensive", v1287 and 1 or 0);
        if v1288 > 0 then
            v50.render_background(v1286, v1286 + l_vector_0(50, 40), v1288, 5);
            v29.texture(v51.icons.unk_rotate.img, v1286 + l_vector_0(10, 5), v51.icons.unk_rotate.size, l_color_0(255, 255 * v1288));
        end;
        return v1288;
    end
};
v69.get_muzzle = function(v1289)
    -- upvalues: v52 (ref), v32 (ref), v39 (ref), v33 (ref), v154 (ref), l_vector_0 (ref)
    local v1290 = v52.local_player():get_player_weapon();
    if not v1290 then
        return;
    else
        local v1291 = v1289 and v1290.m_hWeaponWorldModel or v52.local_player().m_hViewModel[0];
        local v1292 = v1290[0];
        local v1293 = v32.get(v1291)[0];
        if v1292 == v39 or v1293 == v39 then
            return;
        else
            local v1294 = v33.new("vector_t[1]");
            local v1295 = v1289 and v154.get_attachment_index_3(v1292) or v154.get_attachment_index_1(v1292, v1293);
            if v1295 > 0 and v154.get_attachment(v1293, v1295, v1294[0]) then
                return l_vector_0(v1294[0].x, v1294[0].y, v1294[0].z);
            else
                return v39;
            end;
        end;
    end;
end;
v69.render = function()
    -- upvalues: v51 (ref), v52 (ref), v69 (ref), l_vector_0 (ref), v29 (ref), v50 (ref), v39 (ref), l_color_0 (ref), v28 (ref)
    if not v51.get("enable_side_indicators") then
        return;
    elseif not v52.is_alive then
        return;
    else
        local mode = v51.get("side_indicators_mode");
        local v1296 = mode == "Muzzle";
        local v1297 = nil;
        if v1296 then
            local v1298 = v69.get_muzzle(false);
            local v1299 = v52.local_player():get_origin() + l_vector_0(0, 0, 40);
            if not v1299 then
                return;
            else
                if common.is_in_thirdperson() then
                    v1298 = v1299;
                end;
                if not v1298 then
                    return;
                else
                    v1297 = v29.world_to_screen(v1298);
                    if not v1297 then
                        return;
                    elseif not common.is_in_thirdperson() then
                        if v69.right_hand:int() == 0 then
                            v1297.x = v1297.x + 20;
                        else
                            v1297.x = v1297.x + -100;
                        end;
                    else
                        local v1300 = v29.world_to_screen(v52.local_player():get_origin());
                        if not v1300 then
                            v1297.x = v50.screen_size.x / 2 - 100;
                        else
                            v1297.x = v1300.x - 100;
                        end;
                    end;
                end;
            end;
        elseif mode == "Crosshair" then
            v1297 = l_vector_0(v50.screen_size.x / 2, v50.screen_size.y / 2 + 25);
        else
            local v1301 = v50.screen_size.y / 2 + 5;
            v1297 = l_vector_0(10, v1301);
        end;
        local v1302 = v29.preform_animation("Side indicators position", v1297, v39, 6);
        local v1303 = v51.get("side_indicators_options");
        local style = v51.get("side_indicators_style");

        if style == "Original" then
            local v1304 = 0;
            for v1305 = 1, #v69.list do
                if v1303[v1305] then
                    v1304 = v1304 + 50 * v69.list[v1305](v1302 + l_vector_0(0, v1304));
                end;
            end;
        end;
        return;
    end;
end;
v70.damage_list = {};
v70.shot_list = {};
v70.last_time = 0;
v70.push_damage = function(v1306, v1307, v1308)
    -- upvalues: v70 (ref), v36 (ref), v29 (ref)
    local l_realtime_0 = globals.realtime;
    local v1310 = v70.damage_list[#v70.damage_list];
    if v1310 and v1310._position:dist(v1307) < 20 then
        v1310._damage[#v1310._damage + 1] = {
            [1] = nil, 
            [2] = 0, 
            [1] = v36("%d", v1306)
        };
        v1310._time = l_realtime_0;
    else
        v70.damage_list[#v70.damage_list + 1] = {
            _fade = 0, 
            _damage = {
                [1] = {
                    [1] = nil, 
                    [2] = 0, 
                    [1] = v36("%d", v1306)
                }
            }, 
            _position = v1307, 
            _vector = v29.world_to_screen(v1307), 
            _is_head = v1308, 
            _time = l_realtime_0
        };
    end;
    v70.last_time = l_realtime_0;
end;
v70.push_hurt = function(v1311, v1312)
    -- upvalues: v70 (ref)
    v70.shot_list[#v70.shot_list + 1] = {
        _fade = 0, 
        _position = v1311, 
        _color = v1312
    };
end;
v70.player_hurt = function(v1313)
    -- upvalues: v51 (ref), v52 (ref), v32 (ref), l_vector_0 (ref), v70 (ref)
    if not v51.get("enable_damage") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1314 = v32.get(v1313.userid, true);
        if not v1314 then
            return;
        else
            local v1315 = v32.get(v1313.attacker, true);
            if not v1315 or v51.get("damage_settings")[3] and v1315 ~= v52.local_player() then
                return;
            else
                local l_m_vecOrigin_0 = v1314.m_vecOrigin;
                local v1317 = l_vector_0(l_m_vecOrigin_0.x, l_m_vecOrigin_0.y, l_m_vecOrigin_0.z + v1314.m_vecViewOffset.z);
                if not v1317 then
                    return;
                else
                    v70.push_damage(v1313.dmg_health, v1317, v1313.hitgroup == 1);
                    return;
                end;
            end;
        end;
    end;
end;
v70.shots = function(v1318)
    -- upvalues: v51 (ref), v39 (ref), v70 (ref)
    if not v51.get("enable_shots") then
        return;
    else
        local v1319 = v1318.state == v39 and v51.get("hit_color") or v51.get("miss_color");
        v70.push_hurt(v1318.aim, v1319);
        return;
    end;
end;
v70.render_damage = function()
    -- upvalues: v51 (ref), v52 (ref), v70 (ref), v29 (ref), v39 (ref), l_vector_0 (ref), v27 (ref)
    if not v51.get("enable_damage") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1320 = {
            head_color = v51.get("damage_head_color"), 
            other_color = v51.get("damage_other_color"), 
            settings = v51.get("damage_settings")
        };
        local v1321 = #v70.damage_list;
        local v1322 = false;
        for v1323 = 1, v1321 do
            local v1324 = v70.damage_list[v1323];
            if v1324 then
                local v1325 = v1324._time + 1.5 > globals.realtime;
                v1324._fade = v29.do_animation(v1324._fade, v1325 and 1 or 0);
                if v1324._fade > 0 then
                    local v1326 = (v1324._is_head and v1320.head_color or v1320.other_color):override(v1324._fade);
                    local v1327 = v29.world_to_screen(v1324._position);
                    if v1327 ~= v39 then
                        if v1320.settings[2] and v1324._vector ~= v39 then
                            v1324._vector = v29.do_vector_animation(v1324._vector, v1327);
                        else
                            v1324._vector = v1327;
                        end;
                        local v1328 = #v1324._damage;
                        if v1320.settings[1] then
                            v29.shadow(v1324._vector - l_vector_0(0, -v1328 * 16 / 2), v1324._vector + l_vector_0(0, v1328 * 16 / 2), v1326, 70);
                        end;
                        local v1329 = 0;
                        for v1330 = 1, v1328 do
                            local v1331 = v1324._damage[v1330];
                            v1331[2] = v29.do_animation(v1331[2], 1);
                            v29.text("theme::low", v1324._vector + l_vector_0(0, v1329), v1326:override(v1331[2]), "c", v1331[1]);
                            v1329 = v1329 + 16 * v1331[2];
                        end;
                        v1324._position.z = v1324._position.z + globals.frametime * 10;
                    end;
                    v1322 = true;
                elseif v1325 then
                    v1322 = true;
                end;
            end;
        end;
        if not v1322 and v1321 > 0 then
            v27.clear(v70.damage_list);
        end;
        return;
    end;
end;
v70.render_shots = function()
    -- upvalues: v51 (ref), v52 (ref), v70 (ref), v25 (ref), v29 (ref), l_vector_0 (ref), v27 (ref)
    if not v51.get("enable_shots") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1332 = #v70.shot_list;
        local v1333 = false;
        for v1334 = 1, v1332 do
            local v1335 = v70.shot_list[v1334];
            if v1335 then
                v1335._fade = v25.lerp(v1335._fade, 1, globals.frametime * 2);
                if v1335._fade ~= 1 then
                    v1333 = true;
                end;
                local v1336 = v25.abs(v1335._fade - 1);
                local v1337 = v1335._color:override(v1336);
                local v1338 = v29.world_to_screen(v1335._position);
                if v1338 then
                    v29.shadow(v1338 - l_vector_0(50 * v1335._fade, 50 * v1335._fade), v1338 + l_vector_0(50 * v1335._fade, 50 * v1335._fade), v1337, 100, 0, 50 * v1335._fade);
                end;
            end;
        end;
        if not v1333 and v1332 > 0 then
            v27.clear(v70.shot_list);
        end;
        return;
    end;
end;
v71.build = {
    [1] = "\194\183 ", 
    [2] = " \194\183 ", 
    [3] = "  \194\183 ", 
    [4] = "M  \194\183 ",
    [5] = "Ma  \194\183 ",
    [6] = "Mad  \194\183 ",
    [7] = "Madr  \194\183 ",
    [8] = "Madri  \194\183 ",
    [9] = "Madril  \194\183 ",
    [10] = "Madrill  \194\183 ",
    [11] = "Madrilla  \194\183 ",
    [12] = "Madrilla \194\183 ",
    [13] = "Madrilla R \194\183 ",
    [14] = "Madrilla Re \194\183 ",
    [15] = "Madrilla Rec \194\183 ",
    [16] = "Madrilla Reco \194\183 ",
    [17] = "Madrilla Recod \194\183 ",
    [18] = "Madrilla Recode \194\183 ",
    [19] = "Madrilla Recode \194\183 ",
    [20] = "Madrilla Recode \194\183 ",
    [21] = "adrilla Recode \194\183 ",
    [22] = "drilla Recode \194\183 ",
    [23] = "rilla Recode \194\183 ",
    [24] = "illa Recode \194\183 ",
    [25] = "lla Recode \194\183 ",
    [26] = "la Recode \194\183 ",
    [27] = "a Recode \194\183 ",
    [28] = " Recode \194\183 ",
    [29] = "Recode \194\183 ",
    [30] = "ecode \194\183 ",
    [31] = "code \194\183 ",
    [32] = "ode \194\183 ",
    [33] = "de \194\183 ",
    [34] = "e \194\183 ",
    [35] = " \194\183 "
};
v71.last_text = v39;
v71.update = function(v1339)
    -- upvalues: v71 (ref)
    if v71.last_text ~= v1339 then
        common.set_clan_tag(v1339);
        v71.last_text = v1339;
        return true;
    else
        return false;
    end;
end;
v71.handle = function()
    -- upvalues: v51 (ref), v71 (ref), v39 (ref), v30 (ref), v25 (ref)
    local v1340 = v51.get("clantag");
    if not globals.is_connected then
        v71.last_text = v39;
        return;
    elseif not v1340 then
        v71.update(" ");
        return;
    else
        local v1341 = v30.net_channel();
        if not v1341 then
            return;
        else
            local v1342 = v1341.latency[0] / globals.tickinterval;
            local v1343 = globals.tickcount + v1342;
            local v1344 = v25.floor(v25.fmod(v1343 / 15, #v71.build));
            if v71.build[v1344] then
                v71.update(v71.build[v1344]);
            end;
            return;
        end;
    end;
end;
v71.destroy = function()
    common.set_clan_tag(" ");
end;
v72.phrases = {
    [1] = "1.",
    [2] = "sit nn.",
    [3] = "nice anti-aim, got it from a youtube tutorial?",
    [4] = "refund your sub.",
    [5] = "Madrilla Recode > your paste.",
    [6] = "who are you?",
    [7] = "resolver issue?",
    [8] = "stop staring at the ground.",
    [9] = "nn down.",
    [10] = "fix your config.",
    [11] = "outclassed.",
    [12] = "uid issue.",
    [13] = "do you even have a config?",
    [14] = "my software > your software.",
    [15] = "nice desync.",
    [16] = "nice lua, pasted it yourself?",
    [17] = "ez.",
    [18] = "stay dead.",
    [19] = "uninstall your paste.",
    [20] = "imagine dying to me.",
    [21] = "your lag comp is crying.",
    [22] = "Madrilla on top.",
    [23] = "you missed, I didn't.",
    [24] = "i am the lc inventor.",
    [25] = "did you hit your head?",
    [26] = "1 missed due to spread?",
    [27] = "you are nothing.",
    [28] = "brain issue?",
    [29] = "paste down.",
    [30] = "sub out.",
    [31] = "buy Madrilla Recode.",
    [32] = "your cheat is struggling.",
    [33] = "are you trying to hit me?",
    [34] = "aimbot not working?",
    [35] = "nice safety.",
    [36] = "go back to unranked.",
    [37] = "nice delay.",
    [38] = "who sold you that config?",
    [39] = "another fan.",
    [40] = "easy.",
    [41] = "Madrilla owns you and your friends.",
    [42] = "keep dumping.",
    [43] = "you need a better Lua.",
    [44] = "0 iq.",
    [45] = "are you full blind?",
    [46] = "nice peek.",
    [47] = "too slow.",
    [48] = "stop.",
    [49] = "you're a legend in your own mind.",
    [50] = "i can do this all day."
};
v72.on_death = function(v1345)
    -- upvalues: v51 (ref), v52 (ref), v32 (ref), v72 (ref), v30 (ref), v36 (ref)
    if not v51.get("killsay") then
        return;
    elseif not v52.local_player() then
        return;
    else
        local v1346 = v32.get(v1345.attacker, true);
        if not v1346 then
            return;
        else
            local v1347 = v32.get(v1345.userid, true);
            if not v1347 then
                return;
            elseif v1346 ~= v52.local_player() then
                return;
            elseif v1347 == v52.local_player() then
                return;
            else
                local v1348 = v72.phrases[v30.random_int(1, #v72.phrases)];
                if not v1348 then
                    return;
                else
                    v30.execute_after(v30.random_float(1.1, 3.3), function()
                        -- upvalues: v30 (ref), v36 (ref), v1348 (ref)
                        v30.console_exec(v36("say %s ", tostring(v1348)));
                    end);
                    return;
                end;
            end;
        end;
    end;
end;
v311.on_round_start = function(_)
    -- upvalues: v51 (ref), v30 (ref)
    if not v51.get("round_flash") then
        return;
    elseif not v30.is_csgo_selected() then
        return;
    else
        v30.flash_icon();
        return;
    end;
end;
v73.cvars = {
    chat = cvar.cl_chatfilters, 
    radar = cvar.cl_drawhud_force_radar, 
    ragdoll = cvar.cl_ragdoll_physics_enable, 
    decals = cvar.r_drawdecals, 
    legs_shadow = cvar.cl_foot_contact_shadows, 
    blood = cvar.violence_hblood, 
    disable_freezcam = cvar.cl_disablefreezecam, 
    showhelp = cvar.cl_showhelp, 
    autohelp = cvar.cl_autohelp, 
    rain = cvar.r_drawrain, 
    sprites = cvar.r_drawsprites
};
v73.override = function(v1350)
    -- upvalues: v73 (ref)
    v73.cvars.chat:int(v1350[1] and 0 or 63);
    v73.cvars.radar:int(v1350[2] and -1 or 1);
    v73.cvars.ragdoll:int(v1350[3] and 0 or 1);
    v73.cvars.decals:int(v1350[4] and 0 or 1);
    v73.cvars.legs_shadow:int(v1350[5] and 0 or 1);
    v73.cvars.blood:int(v1350[6] and 0 or 1);
    v73.cvars.disable_freezcam:int(v1350[7] and 1 or 0);
    v73.cvars.showhelp:int(v1350[7] and 0 or 1);
    v73.cvars.autohelp:int(v1350[7] and 0 or 1);
    v73.cvars.rain:int(v1350[7] and 0 or 1);
    v73.cvars.sprites:int(v1350[7] and 0 or 1);
end;
v73.update = function()
    -- upvalues: v51 (ref), v73 (ref)
    if not globals.is_connected then
        return;
    else
        local v1351 = v51.get("remove");
        v73.override(v1351);
        return;
    end;
end;
v73.destroy = function()
    -- upvalues: v73 (ref)
    v73.override({
        [1] = false, 
        [2] = false, 
        [3] = false, 
        [4] = false, 
        [5] = false, 
        [6] = false, 
        [7] = false
    });
end;
v75.trace = v39;
v75.should_crouch = false;
v75.fast_ladder = function(v1352)
    -- upvalues: v51 (ref), v52 (ref), v75 (ref), v25 (ref)
    if not v51.get("fast_ladder") then
        return;
    elseif not v52.is_alive then
        return;
    elseif not (v52.local_player().m_MoveType == 9) then
        if v75.should_crouch then
            v1352.in_duck = 1;
            v75.should_crouch = false;
        end;
        return;
    else
        v75.should_crouch = false;
        if v1352.sidemove == 0 then
            v1352.view_angles.y = v1352.view_angles.y + 45;
        end;
        if v1352.in_forward then
            if v1352.sidemove < 0 then
                v1352.view_angles.y = v25.normalize_yaw(v1352.view_angles.y + 90);
            end;
            v1352.in_moveleft = false;
            v1352.in_moveright = true;
            v1352.in_forward = true;
        end;
        if v1352.in_back then
            if v1352.sidemove > 0 then
                v1352.view_angles.y = v25.normalize_yaw(v1352.view_angles.y + 90);
            end;
            v1352.in_moveleft = true;
            v1352.in_moveright = false;
        end;
        if v1352.view_angles.x > -45 then
            v1352.view_angles.x = -45;
        end;
        if not v75.should_crouch then
            v75.should_crouch = true;
        end;
        return;
    end;
end;
v75.avoid_collisions = function(v1353)
    -- upvalues: v51 (ref), v52 (ref), v29 (ref), v25 (ref), l_vector_0 (ref), v75 (ref), v30 (ref), v39 (ref)
    if not v51.get("avoid_collisions") then
        return;
    elseif not v1353.in_jump then
        return;
    elseif v51.references.slow_walk:get() then
        return;
    elseif v1353.in_moveright or v1353.in_moveleft or v1353.in_back then
        return;
    else
        local v1354 = v52.local_player().m_vecVelocity:length();
        local l_m_vecOrigin_1 = v52.local_player().m_vecOrigin;
        local v1356 = v29.camera_angles();
        local _ = v1356.y;
        local l_huge_1 = v25.huge;
        local l_huge_2 = v25.huge;
        for v1360 = v1356.y - 90, v1356.y + 90, 15 do
            local v1361 = v25.rad(v1360);
            local v1362 = l_m_vecOrigin_1 + l_vector_0(v25.cos(v1361) * 70, v25.sin(v1361) * 70, 30);
            v75.trace = v30.trace_line(l_m_vecOrigin_1, v1362, v52.local_player(), v39, 1);
            local v1363 = l_m_vecOrigin_1:dist(v75.trace.end_pos);
            if v1363 < l_huge_1 then
                l_huge_1 = v1363;
                l_huge_2 = v1360;
            end;
        end;
        if l_huge_1 > 35 then
            return;
        else
            l_huge_2 = l_huge_2 - (v1356.y - 90);
            v1353.forwardmove = v25.abs(v1354 * v25.cos(v25.rad(l_huge_2)));
            v1353.sidemove = v1354 * v25.sin(v25.rad(l_huge_2)) * (l_huge_2 >= 90 and 1 or -1);
            return;
        end;
    end;
end;
v75.slow_walk = function(v1364)
    -- upvalues: v52 (ref), v51 (ref), v25 (ref)
    if not v52.is_alive then
        return;
    elseif not v51.references.slow_walk:get() then
        return;
    else
        local v1365 = v51.get("slow_walk");
        if v1365 == 0 then
            return;
        else
            v1364.forwardmove = v25.clamp(v1364.forwardmove, -v1365, v1365);
            v1364.sidemove = v25.clamp(v1364.sidemove, -v1365, v1365);
            return;
        end;
    end;
end;
v74.locations = {
    ["Error 1"] = "MadrillaSounds/error.wav", 
    ["Wood Plank"] = "physics/wood/wood_plank_impact_hard4.wav", 
    ["Wood Strain"] = "physics/wood/wood_strain7.wav", 
    ["Wood Stop"] = "doors/wood_stop1.wav", 
    Warning = "resource/warning.wav", 
    Switch = "buttons/arena_switch_press_02.wav", 
    Woosh = "MadrillaSounds/menu_load.wav"
};
v74.snd = cvar.snd_setmixer;
v74.on_local_hurt = function(v1366)
    -- upvalues: v32 (ref), v51 (ref), v74 (ref), v154 (ref)
    local v1367 = v32.get_local_player();
    if not v1367 then
        return;
    else
        local v1368 = v51.get("local_hurt");
        if not v1368 or v1368 == "Disable" then
            return;
        else
            local v1369 = v32.get(v1366.userid, true);
            if not v1369 or v1369 ~= v1367 then
                return;
            elseif not v32.get(v1366.attacker, true) then
                return;
            else
                local v1370 = v74.locations[v1368];
                v154.play_sound(v1370, v51.get("local_hurt_volume") / 100, 100, 0, 0);
                return;
            end;
        end;
    end;
end;
v74.player_weapon = function()
    -- upvalues: v52 (ref), v154 (ref), v36 (ref), v51 (ref)
    local v1371 = v52.local_player():get_player_weapon():get_name();
    local snd_name = v1371;
    local vol_mult = 1.0;
    if v51.get("weapon_sound_pack") == "MW19 Custom" then
        if snd_name == "SSG 08" then
            snd_name = "weap_cheytac_slmn_short_44k_mono"
            vol_mult = 0.6;
        elseif snd_name == "Desert Eagle" then
            snd_name = "weap_deserteagle_slmn"
        elseif snd_name == "USP-S" or snd_name == "USP-S Silenced" then
            snd_name = "weap_usps_sup_loud_44k_mono"
        end;
    end;
    if snd_name == "molotov" or snd_name:match("Grenade") or snd_name == "Flashbang" or snd_name == "C4 Explosive" or snd_name:lower():match("glock") or snd_name:lower():match("p2000") then return end
    local sound_path = v36("MadrillaSounds/%s.wav", snd_name);
    local final_vol = (v51.get("weapons_sounds_volume") / 100) * vol_mult;
    v154.play_sound(sound_path, 0, 100, 4, 0);
    v154.play_sound(sound_path, final_vol, 100, 0, 0);
end;
v74.manual_shoot = function(v1372)
    -- upvalues: v74 (ref), v52 (ref), v51 (ref), v30 (ref)
    v74.snd:call("Weapons1", "vol", 0.7);
    if not v52.is_alive then
        return;
    elseif not v51.get("weapons_sounds") then
        return;
    else
        local v1373 = v52.local_player():get_player_weapon();
        if not v1373 then
            return;
        elseif v1373:get_weapon_info().is_revolver then
            return;
        else
            if v1372.in_attack and v30.can_fire(v52.local_player()) and not v51.references.fake_duck:get() then
                v74.player_weapon();
            end;
            v74.snd:call("Weapons1", "vol", 0);
            return;
        end;
    end;
end;
v74.auto_fire = function()
    -- upvalues: v51 (ref), v74 (ref)
    if not v51.get("weapons_sounds") then
        return;
    else
        v74.player_weapon();
        return;
    end;
end;
v315 = nil;
v315 = {};
v547 = function(v1374)
    -- upvalues: v29 (ref), v41 (ref), v154 (ref), v49 (ref), v39 (ref), l_vector_0 (ref), l_color_0 (ref)
    local v1375 = v29.screen_size();
    local v1376 = v29.original.load_font(v41, 16, "ad");
    local v1377 = v29.original.load_font(v41, 70, "abd");
    v154.play_sound("MadrillaSounds/error.wav", 1, 100, 0, 0);
    v49.attach("render", function()
        -- upvalues: v29 (ref), v1376 (ref), v39 (ref), v1374 (ref), l_vector_0 (ref), v1375 (ref), l_color_0 (ref), v1377 (ref)
        local v1378 = v29.preform_animation("lua::error::alpha", 1);
        if v1378 == 0 then
            return;
        else
            local v1379 = v29.original.measure_text(v1376, v39, v1374);
            local v1380 = v1378 * 150;
            v29.push_clip_rect(l_vector_0(100, v1375.y / 2 - 80), l_vector_0(500, v1375.y / 2 + 80));
            v29.circle_gradient(l_vector_0(300, v1375.y / 2), l_color_0(150, 0), l_color_0(150, 150, 255, v1380), 190, 0, 1);
            v29.pop_clip_rect();
            v29.blur(l_vector_0(100, v1375.y / 2 - 80), l_vector_0(501, v1375.y / 2 + 81), v1378 * 0.1, v1378, 10);
            v29.rect(l_vector_0(100, v1375.y / 2 - 80), l_vector_0(500, v1375.y / 2 + 80), l_color_0(10, 10, 30, 100 * v1378), 10);
            v29.original.text(v1376, l_vector_0(120 + v1379.x / 2, v1375.y / 2), l_color_0(255, 255 * v1378), "c", v1374);
            v29.original.text(v1377, l_vector_0(460, v1375.y / 2), l_color_0(255, 255 * v1378), "c", "!");
            return;
        end;
    end, "lua::error::render", false);
end;
do
    local l_v547_0 = v547;
    v315.main = function(_)
        -- upvalues: v47 (ref), v49 (ref), v30 (ref), v33 (ref), v39 (ref), l_v547_0 (ref), v31 (ref), v36 (ref), v29 (ref), v51 (ref), v311 (ref), v64 (ref), v111 (ref), v50 (ref), v71 (ref), v52 (ref), v58 (ref), v70 (ref), v60 (ref), v61 (ref), v62 (ref), v69 (ref), v66 (ref), v65 (ref), v67 (ref), v68 (ref), v74 (ref), v53 (ref), v54 (ref), v73 (ref), v75 (ref), v55 (ref), v56 (ref), v57 (ref), v72 (ref), v63 (ref), v46 (ref), v154 (ref)
        cvar.clear:call();
        if v47 then
            print(v49.safe_mode);
        end;
        v30.csgo_hwnd = v33.C.FindWindowA("Valve001", v39);
        if false then
            return l_v547_0("Failed to find csgo window handle.\nPlease contact our support via Discord sever");
        elseif not v31.initialize_icons() then
            return l_v547_0(v36("Failed to download Icons.\n%s\nTry to avoid using third party application like Migi,\n and join our discord server\nfor more information.", v31.last_error));
        elseif not v31.initialize_sounds() then
            return l_v547_0(v36("Failed to download Sounds.\n%s\nTry to avoid using third party application like Migi,\n and join our discord server\nfor more information.", v31.last_error));
        elseif not v31.initialize_configs() then
            return l_v547_0("Failed to setup Configs.\nPlease Join our discord server\nfor more information.");
        elseif not v29.initialize_fonts() then
            return l_v547_0(v36("Failed to setup render fonts.\nError : %s", v29.last_error));
        elseif not v51.initialize_icons() then
            return l_v547_0("Failed to setup menu icons.\nPlease Join our discord server\nfor more information.");
        else
            if not v49.initialize() then
                v311.add("Failed to setup Keyboard Hook. Some options wont be available", v51.icons.error);
            end;
            if not v51.initialize_elements() then
                return l_v547_0("Failed to setup menu elements.\nPlease Join our discord server\nfor more information.");
            else
                if not v64.initialize() then
                    v311.add(v64.last_error, v51.icons.error);
                end;
                v49.attach("render", v111.process, "lua::windows::process");
                v49.attach("render", v50.preform_colors, "lua::theme::preform_colors");
                v49.attach("render", v71.handle, "lua::clantag::render");
                v49.attach("render", v52.update, "lua::global::update");
                v49.attach("render", v58.manuals, "lua::anti_aim::manuals");
                v49.attach("render", v58.each_frame, "lua::anti_aim::each_frame");
                v49.attach("render", v64.setup, "lua::headup_display::setup");
                v49.attach("render", v64.health_and_armor, "lua::headup_display::setup");
                v49.attach("render", v64.weapons, "lua::headup_display::setup");
                v49.attach("render", v64.killfeed, "lua::headup_display::setup");
                v49.attach("render", v64.round, "lua::headup_display::setup");
                v49.attach("render", v64.chat, "lua::headup_display::setup");
                v49.attach("render", v70.render_shots, "lua::markers::shots");
                v49.attach("render", v70.render_damage, "lua::markers::damage");
                v49.attach("render", v60.render, "lua::scope::render");
                v49.attach("render", v61.render, "lua::view::render");
                v49.attach("render", v62.render, "lua::world::render");

                v49.attach("render", v69.render, "lua::side_indicators::render");
                v49.attach("render", v64.player_spawn, "lua::headup_display::player_spawn");
                v66.window:register_render(v66.render, "lua::watermark::render");
                v65.window:register_render(v65.render, "lua::keybinds::render");
                v67.window:register_render(v67.render, "lua::logs_system::render");
                v68.window:register_render(v68.render, "lua::warning_system::render");
                if not v51.initialize_window() then
                    return l_v547_0("Failed to setup menu window.\nPlease Join our discord server\nfor more information.");
                else
                    v49.attach("low_level_keyboard", v64.enable_chat, "lua::headup_display::enable_chat");
                    v49.attach("low_level_keyboard", v64.capture_input, "lua::headup_display::capture_input");
                    v49.attach("mouse_input", v64.capture_mouse, "lua::headup_display::capture_mouse");
                    v49.attach("render", v311.render, "lua::notify::render");
                    v49.attach("createmove", v74.manual_shoot, "lua::sounds::manual_shoot");
                    v49.attach("createmove", v53.hideshots, "lua::exploits::hideshots");
                    v49.attach("createmove", v53.uncharge_attack, "lua::exploits::uncharge_attack");
                    v49.attach("createmove", v53.handle_charge, "lua::exploits::handle_charge");
                    v49.attach("createmove", v54.update, "lua::hitchance::update");
                    v49.attach("createmove", v73.update, "lua::removes::update");
                    v49.attach("createmove", v75.avoid_collisions, "lua::movement::avoid_collisions");
                    v49.attach("createmove", v75.fast_ladder, "lua::movement::fast_ladder");
                    v49.attach("createmove", v75.slow_walk, "lua::movement::slow_walk");
                    v49.attach("createmove", v55.createmove, "lua::on_use::createmove");
                    v49.attach("createmove", v56.createmove, "lua::edge_yaw::createmove");
                    v49.attach("createmove", v57.createmove, "lua::anti_bruteforce::createmove");
                    v49.attach("createmove", v58.main, "lua::anti_aim::createmove");
                    v49.attach("override_view", v60.view, "lua::scope::view");
                    v49.attach("override_view", v68.view, "lua::warning_system::view");
                    v49.attach("player_death", v58.death, "lua::anti_aim::death");
                    v49.attach("player_death", v72.on_death, "lua::killsay::death");
                    v49.attach("player_death", v64.on_kill, "lua::headup_display::on_kill");
                    v49.attach("player_death", v64.player_death, "lua::headup_display::player_death");
                    v49.attach("round_start", v58.round_start, "lua::anti_aim::round_start");
                    v49.attach("round_start", v67.round_start, "lua::logs_system::round_start");
                    v49.attach("round_start", v311.on_round_start, "lua::notify::round_start");
                    v49.attach("round_start", v64.round_start, "lua::headup_display::round_start");
                    v49.attach("round_end", v58.round_end, "lua::anti_aim::round_end");
                    v49.attach("round_end", v64.round_end, "lua::headup_display::round_end");
                    v49.attach("bomb_planted", v64.bomb_planted, "lua::headup_display::bomb_planted");
                    v49.attach("player_say", v64.capture_messages, "lua::headup_display::capture_messages");
                    v49.attach("player_hurt", v74.on_local_hurt, "lua::sounds::local_hurt");
                    v49.attach("player_hurt", v57.detect_hit, "lua::anti_bruteforce::hurt");
                    v49.attach("player_hurt", v67.grenades, "lua::logs_system::hurt");
                    v49.attach("player_hurt", v70.player_hurt, "lua::markers::hurt");
                    v49.attach("bullet_impact", v57.detect_bullet, "lua::anti_bruteforce::bullet");
                    v49.attach("bullet_impact", v62.impact, "lua::world::bullet");
                    v49.attach("aim_ack", v67.aim_fire, "lua::logs_system::aim_fire");
                    v49.attach("aim_ack", v70.shots, "lua::markers::aim_fire");
                    v49.attach("aim_fire", v74.auto_fire, "lua::sounds::aim_fire");
                    v49.attach("item_purchase", v67.purshes, "lua::logs_system::item_purchase");
                    v49.attach("post_update_clientside_animation", v63.update, "lua::animations::post_update");
                    v49.attach("localplayer_transparency", v63.transparency, "lua::animations::transparency");
                    v49.attach("shutdown", v71.destroy, "lua::clantag::destroy");
                    v49.attach("shutdown", v64.destroy, "lua::headup_display::destroy");
                    v49.attach("shutdown", v58.destroy, "lua::anti_aim::destroy");
                    v49.attach("shutdown", v60.destroy, "lua::scope::destroy");
                    v49.attach("shutdown", v61.destroy, "lua::view::destroy");
                    v49.attach("shutdown", v62.destroy, "lua::world::destroy");
                    v49.attach("shutdown", v65.destroy, "lua::keybinds::destroy");
                    v49.attach("shutdown", v66.destroy, "lua::watermark::destroy");
                    v49.attach("shutdown", v67.destroy, "lua::logs_system::destroy");
                    v49.attach("shutdown", v68.destroy, "lua::warning_system::destroy");
                    v49.attach("shutdown", v73.destroy, "lua::removes::destroy");
                    v49.attach("shutdown", v63.destroy, "lua::animations::destroy");
                    v49.attach("shutdown", v53.destroy, "lua::exploits::destroy");
                    v49.attach("shutdown", v54.destroy, "lua::hitchance::destroy");
                    v311.add(v36("Welcome back %s. Last update was %s", common.get_username(), v46), v51.icons.open_check);
                    if _G.MADRILLA_UPDATE_AVAILABLE then
                        v311.add(v36("Update %s is available on GitHub!", _G.MADRILLA_UPDATE_AVAILABLE), v51.icons.cloud);
                    end
                    v154.play_sound("MadrillaSounds/menu_load.wav", 1, 100, 0, 0);
                    return;
                end;
            end;
        end;
    end;
end;
v315.main();

events.render:set(function()
    if not v51.get("enable_friendly_molotov") then return end
    local me = entity.get_local_player()
    if not me then return end
    local my_team = me.m_iTeamNum
    local col = v51.get("friendly_molotov_color")
    local r, g, b, a = col.r, col.g, col.b, col.a
    local infernos = entity.get_entities("CInferno")
    for i = 1, #infernos do
        local fire = infernos[i]
        local thrower = entity.get(fire.m_hOwnerEntity)
        if thrower then
            local thrower_team = thrower.m_iTeamNum
            local is_harmless = (thrower_team == my_team)
            if is_harmless then
                local origin = fire:get_origin()
                local num_fires = fire.m_nNumFires
                if num_fires and num_fires > 0 then
                    local x_deltas = fire.m_fireXDelta
                    local y_deltas = fire.m_fireYDelta
                    local z_deltas = fire.m_fireZDelta
                    local is_burning = fire.m_bFireIsBurning
                    for j = 0, num_fires - 1 do
                        if is_burning[j] then
                            local flame_pos = vector(origin.x + x_deltas[j], origin.y + y_deltas[j], origin.z + z_deltas[j])
                            render.circle_3d(flame_pos, color(r, g, b, math.max(a - 40, 10)), 40, 2, 1)
                            render.circle_3d(flame_pos, color(r, g, b, a), 20, 1, 0)
                        end
                    end
                else
                    render.circle_3d(origin, color(r, g, b, math.max(a - 40, 10)), 150, 2, 1)
                    render.circle_3d(origin, color(r, g, b, a), 75, 1, 0)
                end
            end
        end
    end
end)

-- [[ SMOKE HELPER ]]
do
    local smoke_helper = {
        targets = {},           -- array of all grenade warnings this tick
        active_target = nil,    -- the target we picked
        active_entity = nil,    -- the entity we picked
        target_time = 0,        -- when we received the warning
        last_switch_time = 0,   -- rate limit weapon switch
        is_throwing = false,    -- are we currently releasing the throw?
        MAX_DISTANCE = 1000,
        SWITCH_COOLDOWN = 1,    -- wait 1s between weapon switch attempts to prevent disconnect spam
        THROW_SPEED = 750
    }

    events.grenade_warning:set(function(e)
        if e.type == "Frag" then return end
        if not v51.get("enable_smoke_helper") then return end
        table.insert(smoke_helper.targets, {origin = e.origin, entity = e.entity})
    end)

    events.createmove:set(function(cmd)
        if not v51.get("enable_smoke_helper") or not v51.get_bind("Smoke helper key") then
            smoke_helper.active_target = nil
            smoke_helper.targets = {}
            return
        end

        local me = entity.get_local_player()
        if not me then return end
        local eye_pos = me:get_eye_position()

        local manual_override = v51.get("smoke_helper_manual")
        local weapon = me:get_player_weapon()
        local wep_name = weapon and weapon:get_name() or ""
        local is_holding_smoke = wep_name == "Smoke Grenade"

        local max_dist = 250
        local vert_dist = 350
        local sync_dist = 500
        
        -- Lag compensation: adjust sync_dist based on real ping so it releases the grenade earlier if ping is high
        local net = utils.net_channel()
        if net and net.latency and net.latency[1] then
            -- Fall speed is approx 800 units/s. Ping is in seconds.
            sync_dist = sync_dist + (net.latency[1] * 800)
        end
        
        local prep_dist = 1200

        if smoke_helper.is_throwing and smoke_helper.active_target then
            -- keep going with active_target
        else
            smoke_helper.active_target = nil
            smoke_helper.active_entity = nil
            local best_target = nil
            local best_entity = nil
            local best_score = 999999
            
            local view_angles = cmd.view_angles

            for i, t in ipairs(smoke_helper.targets) do
                local dx = t.origin.x - eye_pos.x
                local dy = t.origin.y - eye_pos.y
                local dz = t.origin.z - eye_pos.z
                local dist_2d = math.sqrt(dx * dx + dy * dy)
                local dist_z = math.abs(dz)
                
                local p_z = eye_pos.z
                local t_z = t.origin.z + 10 -- Slightly above ground to avoid floor bumps
                local tr_player_height = utils.trace_line(eye_pos, vector(t.origin.x, t.origin.y, p_z), me)
                local tr_molly_height = utils.trace_line(vector(eye_pos.x, eye_pos.y, t_z), vector(t.origin.x, t.origin.y, t_z), me)
                
                -- If BOTH horizontal traces hit something, it's a solid wall blocking the entire path.
                -- If at least one trace is clear, there is an open path (like over a ledge or under an overhang).
                local wall_blocks = (tr_player_height.fraction < 1) and (tr_molly_height.fraction < 1)
                
                local in_auto_range = dist_2d <= max_dist and dist_z <= vert_dist and not wall_blocks
                local is_valid = false
                local score = dist_2d -- Default sort by distance

                if manual_override and is_holding_smoke then
                    local tr = utils.trace_line(eye_pos, t.origin, me)
                    if tr.fraction == 1 then
                        local pitch = math.deg(math.atan2(-dz, dist_2d))
                        local yaw = math.deg(math.atan2(dy, dx))
                        
                        local delta_pitch = math.abs(view_angles.x - pitch)
                        local delta_yaw = view_angles.y - yaw
                        while delta_yaw > 180 do delta_yaw = delta_yaw - 360 end
                        while delta_yaw < -180 do delta_yaw = delta_yaw + 360 end
                        delta_yaw = math.abs(delta_yaw)
                        
                        local fov = math.sqrt(delta_pitch^2 + delta_yaw^2)
                        if fov < 60 then
                            is_valid = true
                            score = fov
                        end
                    end
                end
                
                -- Fallback to auto deploy if manual override didn't select it
                if not is_valid and in_auto_range then
                    is_valid = true
                end

                if is_valid and score < best_score then
                    best_score = score
                    best_target = t.origin
                    best_entity = t.entity
                end
            end

            smoke_helper.active_target = best_target
            smoke_helper.active_entity = best_entity
        end

        smoke_helper.targets = {} -- Clear array for next tick

        local target = smoke_helper.active_target
        if not target then
            return
        end

        local dx = target.x - eye_pos.x
        local dy = target.y - eye_pos.y
        local dz = target.z - eye_pos.z
        local is_auto = v51.get("smoke_helper_mode") == "Auto deploy"
        
        local dist_to_land_3d = math.sqrt(dx * dx + dy * dy + dz * dz)

        -- Check distance to the projectile entity itself
        local molly_ent = smoke_helper.active_entity
        local dist_to_impact = 0 -- Default to 0 (detonated/landed) if entity is invalid
        if molly_ent and type(molly_ent.get_origin) == "function" then
            -- Use pcall in case the entity is destroyed/invalid
            local pcall_success, ent_origin = pcall(function() return molly_ent:get_origin() end)
            if pcall_success and ent_origin then
                -- Distance from the flying projectile to its predicted landing spot
                dist_to_impact = math.sqrt((ent_origin.x - target.x)^2 + (ent_origin.y - target.y)^2 + (ent_origin.z - target.z)^2)
            end
        end

        -- Wait until the molotov is in preparation range before doing ANYTHING (aiming or switching)
        if dist_to_impact > prep_dist then
            -- Let it keep falling
            return
        end
        if wep_name == "Smoke Grenade" then
            -- Get player velocity for compensation (INCLUDE vertical velocity for air throws)
            local vel = me.m_vecVelocity

            -- Calculate the desired throw direction vector
            local horiz_dist = math.sqrt(dx * dx + dy * dy)
            local pitch = math.atan2(-dz, horiz_dist)
            local yaw = math.atan2(dy, dx)

            -- Determine throw type based on distance to landing spot
            local drop_dist = 150
            local med_dist = 330
            local hold_attack1 = false
            local hold_attack2 = false
            local throw_speed = smoke_helper.THROW_SPEED
            local comp_factor = 1.25

            if dist_to_land_3d <= drop_dist then
                hold_attack2 = true
                throw_speed = 300
                comp_factor = 0 -- Disable compensation for drops to prevent wild aim snaps when running
            elseif dist_to_land_3d <= med_dist then
                hold_attack1 = true
                hold_attack2 = true
                throw_speed = 500
                comp_factor = 0.6
            else
                hold_attack1 = true
            end

            -- Build the unit direction vector
            local dir_x = math.cos(pitch) * math.cos(yaw)
            local dir_y = math.cos(pitch) * math.sin(yaw)
            local dir_z = -math.sin(pitch)

            -- Compensate: desired_velocity = direction * throw_speed
            -- actual_throw = desired_velocity - player_velocity * compensation_factor
            local comp_x = dir_x * throw_speed - vel.x * comp_factor
            local comp_y = dir_y * throw_speed - vel.y * comp_factor
            local comp_z = dir_z * throw_speed - vel.z * comp_factor

            -- Convert compensated vector back to view angles
            local comp_horiz = math.sqrt(comp_x * comp_x + comp_y * comp_y)
            cmd.view_angles.x = -math.deg(math.atan2(comp_z, comp_horiz))
            cmd.view_angles.y = math.deg(math.atan2(comp_y, comp_x))

            if is_auto then

                -- Handle the throw: hold attack until pin is pulled, then release when in sync range
                if smoke_helper.is_throwing then
                    -- We've decided to throw, force buttons released
                    cmd.in_attack = false
                    cmd.in_attack2 = false
                elseif weapon.m_bPinPulled then
                    if dist_to_impact <= sync_dist then
                        -- Pin pulled and synced = set throwing flag and release
                        smoke_helper.is_throwing = true
                        cmd.in_attack = false
                        cmd.in_attack2 = false
                    else
                        -- Keep holding it while it falls
                        cmd.in_attack = hold_attack1
                        cmd.in_attack2 = hold_attack2
                    end
                else
                    -- Hold attack to pull pin
                    cmd.in_attack = hold_attack1
                    cmd.in_attack2 = hold_attack2
                end
            end
        else
            -- Not holding smoke grenade, clear throwing state
            smoke_helper.is_throwing = false
            if is_auto then
                -- If we don't have a smoke out, try to switch (rate limited to avoid disconnect spam)
                if globals.curtime - smoke_helper.last_switch_time > smoke_helper.SWITCH_COOLDOWN then
                    smoke_helper.last_switch_time = globals.curtime
                    utils.console_exec("use weapon_smokegrenade", cmd)
                end
            end
        end

        -- Clear target at the end of the tick unless we are actively throwing
        if not smoke_helper.is_throwing then
            smoke_helper.active_target = nil
            smoke_helper.active_entity = nil
        end
    end)
end

-- =========================================================================
-- V's Dynamic Goon Corner (Headless Mode for CS:GO)
-- =========================================================================

-- IMPORTANT: DO NOT USE IMGUR LINKS HERE! 
-- Imgur compresses images into Progressive JPEGs which instantly crash the Neverlose image parser.
-- Use direct image links from Discord, Catbox, or other standard image hosts.
local debug_status = "Loading URLs..."
local goon_corner_urls = {}
local urls_loaded = false

local __RAW_URL_DATA__ = [=[
https://cdn.discordapp.com/attachments/791177690026606593/1514435421956739224/AntiquePeacefulSeahorse.mp4?ex=6a4c50e5&is=6a4aff65&hm=629ac53cb92be696d759afa956b79c7232e94328d7bf863ee67c6e89faab2455&
https://cdn.discordapp.com/attachments/791177690026606593/1514595312415801385/HJ6AtGeXoAA-74u.png?ex=6a4c3d0e&is=6a4aeb8e&hm=d923b2889a5645ddb3c6096608c5254962cc7f01788f1b013b7bf07d2775604f&
https://cdn.discordapp.com/attachments/791177690026606593/1514595312730243224/HKTvSGFXoAAq7fG.png?ex=6a4c3d0e&is=6a4aeb8e&hm=0097c23373b2d0fcd03f6d2343d716e41b3fc5bc343781190082b78b205e60d8&
https://cdn.discordapp.com/attachments/791177690026606593/1514595313221111969/HKefE_KaUAAwBJy.png?ex=6a4c3d0e&is=6a4aeb8e&hm=aef66669473f15b9a699a877bc9a8ddfc14313969335406a650f0b030c90ed5f&
https://cdn.discordapp.com/attachments/791177690026606593/1514646784079560704/RDT_20260611_1604489075738574751876320.jpg?ex=6a4c6cfe&is=6a4b1b7e&hm=bda388efb8adfd2856a75bfc0db999ec387dc1a9e5768a64a8525f59ddd5e921&
https://cdn.discordapp.com/attachments/791177690026606593/1514646801179869235/RDT_20260611_1604262065100141883538839.jpg?ex=6a4c6d02&is=6a4b1b82&hm=5a5695830d430dc8b4aaae77fa78e17646e3b255ae1c4551559905a15ecc32f8&
https://cdn.discordapp.com/attachments/791177690026606593/1514686045604679781/JDYQ7150.mp4?ex=6a4c918e&is=6a4b400e&hm=6a2ec9d8f41f6dd7473915a31fb9bf9933fc253dd29816421248d5a66e98c042&
https://cdn.discordapp.com/attachments/791177690026606593/1514764304090661045/RDT_20260612_041733.mp4?ex=6a4c31b1&is=6a4ae031&hm=68c24db34f607a440b6cc015462aa14f8db0ecfa25c17b30e22107c57a1a41ba&
https://cdn.discordapp.com/attachments/791177690026606593/1514998598570475892/RDT_20260612_1523114287847744018041408.jpg?ex=6a4c6325&is=6a4b11a5&hm=edc96706f771a783b5dd512574b4662b0a75f078b617ae17f96bd74f899a361e&
https://cdn.discordapp.com/attachments/791177690026606593/1514998607399354518/RDT_20260612_1523087914484744130923426.jpg?ex=6a4c6327&is=6a4b11a7&hm=3f9c125205d6def49fa5f5ab704591e561ce1f12bb51429a5b1b6c6fa2e781de&
https://cdn.discordapp.com/attachments/791177690026606593/1514998625191723119/RDT_20260612_1523052837667624009528530.jpg?ex=6a4c632b&is=6a4b11ab&hm=78c76fba77b7449af24ab83ff8d20d6af9798c56d45128d9cd3214d528879a2f&
https://cdn.discordapp.com/attachments/791177690026606593/1514998639213150258/RDT_20260612_1523014222239343034730590.jpg?ex=6a4c632e&is=6a4b11ae&hm=9b870cb18868b816fd8da8558d3b63c8d2e649853c321e9d9712448d0d0e7cdf&
https://cdn.discordapp.com/attachments/791177690026606593/1515428527154135131/ihfao1cvt17h1.webp?ex=6a4ca20c&is=6a4b508c&hm=dba92824c3d7621ce42ac263829a13c36966e143c9fb857f6be2764aa449e73b&
https://cdn.discordapp.com/attachments/1515470177968591008/1515622684996669551/271ndrbpgpeg1.png?ex=6a4c055f&is=6a4ab3df&hm=6b3269776077c5e9dd73c102be87afb3f41878e1cbdcf8d25e49ef7a251009a8&
https://cdn.discordapp.com/attachments/791177690026606593/1515671171058896956/IMG_20260614_135555_286.jpg?ex=6a4c3286&is=6a4ae106&hm=6935762ed554eb9204b03097c985c077526313e069c1d7430cd34c5d447cc190&
https://cdn.discordapp.com/attachments/791177690026606593/1515671171851358208/IMG_20260614_135555_502.jpg?ex=6a4c3287&is=6a4ae107&hm=9fc7b6ca293317270004e84924caa579dd42a986304f6e65a81cf6c332562feb&
https://cdn.discordapp.com/attachments/791177690026606593/1515671172573040740/IMG_20260614_135554_821.jpg?ex=6a4c3287&is=6a4ae107&hm=9761ed4b63473ddb0f1cb5bc697efbab2317c59ab4e9be8d95c691a02414b131&
https://cdn.discordapp.com/attachments/791177690026606593/1515671173390925834/IMG_20260614_135554_724.jpg?ex=6a4c3287&is=6a4ae107&hm=1d6702087d50c5a52fa526ff3eb950e57b6bdb82d6caf5b8f97ce0f4251929a8&
https://cdn.discordapp.com/attachments/791177690026606593/1515671174024269895/IMG_20260614_135554_890.jpg?ex=6a4c3287&is=6a4ae107&hm=aeec9763bf1400960f040ac5eecba69e6538aeb32b42a125d74eb1f926fea88d&
https://cdn.discordapp.com/attachments/791177690026606593/1515671175198412850/IMG_20260614_135554_874.jpg?ex=6a4c3287&is=6a4ae107&hm=283766d9da2492a0dcf71a05a906db81dcab8a24e373a1438dba3f442be83241&
https://cdn.discordapp.com/attachments/791177690026606593/1515719094815428748/RDT_20260614_1505534164891391154003608.jpg?ex=6a4c5f28&is=6a4b0da8&hm=5a61826faddda86e36a826823b3c60a9ad424802666132617c67d04b086345a8&
https://cdn.discordapp.com/attachments/791177690026606593/1515843367865552926/RDT_20260614_2319154480240126516781006.jpg?ex=6a4c2a25&is=6a4ad8a5&hm=15c5ab9a79e0adfcfb67040aa2b011df021136e35660ee2495659a2e372a779a&
https://cdn.discordapp.com/attachments/791177690026606593/1515843367865552926/RDT_20260614_2319154480240126516781006.jpg?ex=6a4c2a25&is=6a4ad8a5&hm=15c5ab9a79e0adfcfb67040aa2b011df021136e35660ee2495659a2e372a779a&=
https://cdn.discordapp.com/attachments/791177690026606593/1515926790554783774/HKn8nTbasAEKzie.png?ex=6a4c77d7&is=6a4b2657&hm=2e2c0e7a5f301904bd8e66bbe3dfdcc17559ad60a24468dd87fd329a1cbe4b24&
https://cdn.discordapp.com/attachments/791177690026606593/1515926790554783774/HKn8nTbasAEKzie.png?ex=6a4c77d7&is=6a4b2657&hm=2e2c0e7a5f301904bd8e66bbe3dfdcc17559ad60a24468dd87fd329a1cbe4b24&=
https://cdn.discordapp.com/attachments/791177690026606593/1515934179425255484/HK0lKebWMAEjAv4.png?ex=6a4c7eb9&is=6a4b2d39&hm=0077aebb090a8d3c02eb1af71b5309ce80d4dd68384352434e58d0d0958ef667&
https://cdn.discordapp.com/attachments/791177690026606593/1515934179425255484/HK0lKebWMAEjAv4.png?ex=6a4c7eb9&is=6a4b2d39&hm=0077aebb090a8d3c02eb1af71b5309ce80d4dd68384352434e58d0d0958ef667&=
https://cdn.discordapp.com/attachments/791177690026606593/1516023942807031898/XDown.app_B0fdAOp3_mgdZ3hU_720p.mp4?ex=6a4c2992&is=6a4ad812&hm=a6b5348fc2454a470474fc99c1c6377e4eee6fdc670e1ada16f03f146b1f2ba9&
https://cdn.discordapp.com/attachments/791177690026606593/1516035350752002058/HBsoz17W4AEgdF2.png?ex=6a4c3432&is=6a4ae2b2&hm=daf3b84c8156d56e1ab4d6a6a7650789900df41f3f122383ca80aebe1d662502&
https://cdn.discordapp.com/attachments/791177690026606593/1516035350752002058/HBsoz17W4AEgdF2.png?ex=6a4c3432&is=6a4ae2b2&hm=daf3b84c8156d56e1ab4d6a6a7650789900df41f3f122383ca80aebe1d662502&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074294281764964/HKtwUaYWgAAzHPc.png?ex=6a4c5877&is=6a4b06f7&hm=bde68e7ea6117bc59e3ad47edb06014b8dba50f4322d6a754517eacca04b5e03&
https://cdn.discordapp.com/attachments/791177690026606593/1516074294281764964/HKtwUaYWgAAzHPc.png?ex=6a4c5877&is=6a4b06f7&hm=bde68e7ea6117bc59e3ad47edb06014b8dba50f4322d6a754517eacca04b5e03&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074294663188532/HKodeetXAAAGpqS.png?ex=6a4c5877&is=6a4b06f7&hm=00c377c29c6ce60c20c179182e99e1e1fc12fea0693a9d6b8cce52df0e72673c&
https://cdn.discordapp.com/attachments/791177690026606593/1516074294663188532/HKodeetXAAAGpqS.png?ex=6a4c5877&is=6a4b06f7&hm=00c377c29c6ce60c20c179182e99e1e1fc12fea0693a9d6b8cce52df0e72673c&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074295099658324/HKm7_IoWEAAfUfB.png?ex=6a4c5877&is=6a4b06f7&hm=b4655baeb8833cf093ca6becf1163eec2684821ddd715b0537e8769f81849495&
https://cdn.discordapp.com/attachments/791177690026606593/1516074295099658324/HKm7_IoWEAAfUfB.png?ex=6a4c5877&is=6a4b06f7&hm=b4655baeb8833cf093ca6becf1163eec2684821ddd715b0537e8769f81849495&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074295502307542/HKjFz_mXkAA-Nx4.png?ex=6a4c5877&is=6a4b06f7&hm=d994d0c2dd97587d9e87ae2e7e495f8b157b378d505cf6a7373a75e75ecbe645&
https://cdn.discordapp.com/attachments/791177690026606593/1516074295502307542/HKjFz_mXkAA-Nx4.png?ex=6a4c5877&is=6a4b06f7&hm=d994d0c2dd97587d9e87ae2e7e495f8b157b378d505cf6a7373a75e75ecbe645&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074295837593737/HKivOfJWAAE7_Nr.png?ex=6a4c5877&is=6a4b06f7&hm=ef0e8dd58e7abd9e6b284fddd265ee225f7706c1a38b7739772eea3ec8b6f410&
https://cdn.discordapp.com/attachments/791177690026606593/1516074295837593737/HKivOfJWAAE7_Nr.png?ex=6a4c5877&is=6a4b06f7&hm=ef0e8dd58e7abd9e6b284fddd265ee225f7706c1a38b7739772eea3ec8b6f410&=
https://cdn.discordapp.com/attachments/791177690026606593/1516074296152162476/HKeG7gjWUAAlpNn.png?ex=6a4c5877&is=6a4b06f7&hm=f047caf6cf84dcf5b8872a35f6165481969589d43f03290786794f8dadb4f6e5&
https://cdn.discordapp.com/attachments/791177690026606593/1516074296152162476/HKeG7gjWUAAlpNn.png?ex=6a4c5877&is=6a4b06f7&hm=f047caf6cf84dcf5b8872a35f6165481969589d43f03290786794f8dadb4f6e5&=
https://cdn.discordapp.com/attachments/791177690026606593/1516154902580166927/IMG_20260615_215725.jpg?ex=6a4ca389&is=6a4b5209&hm=bc620a95d6ed86ff895d8fcb797c1c685957289f107e7624f02261212b8db7b9&
https://cdn.discordapp.com/attachments/791177690026606593/1516154902580166927/IMG_20260615_215725.jpg?ex=6a4ca389&is=6a4b5209&hm=bc620a95d6ed86ff895d8fcb797c1c685957289f107e7624f02261212b8db7b9&=
https://cdn.discordapp.com/attachments/791177690026606593/1516172087771791390/cutealt.jpg?ex=6a4c0aca&is=6a4ab94a&hm=0420feb0c89ea3ab9a33344ccb5b9bc45f76c1e461c6b6af64692fac3d8a2045&
https://cdn.discordapp.com/attachments/791177690026606593/1516172087771791390/cutealt.jpg?ex=6a4c0aca&is=6a4ab94a&hm=0420feb0c89ea3ab9a33344ccb5b9bc45f76c1e461c6b6af64692fac3d8a2045&=
https://cdn.discordapp.com/attachments/791177690026606593/1516253307495256114/L_8r4OqokCVPUJTz.mp4?ex=6a4c566f&is=6a4b04ef&hm=3ee601f316e9ecc9f498a706d2fae05c7ccb429fa829600eec7d04cb3173162c&
https://cdn.discordapp.com/attachments/791177690026606593/1516387841205211256/VID_20260422_010722_316.mp4?ex=6a4c2afa&is=6a4ad97a&hm=e153287ad90b467962606fdcb815c664cc917b18a9d4bf3ae3762b0f675fc773&
https://cdn.discordapp.com/attachments/791177690026606593/1516423631629062174/RDT_20260616_1345564185633019515373923.jpg?ex=6a4c4c4f&is=6a4afacf&hm=4f1a8f53a79ba0ba0e614e2feeffdaa7ba4d32519f74ea7f55e91342c908f8f1&
https://cdn.discordapp.com/attachments/791177690026606593/1516423650553757706/RDT_20260616_1344453045666288402910266.jpg?ex=6a4c4c54&is=6a4afad4&hm=b98520b85be84db170f876688431cf3b0d2e18174de9709677ffebee320531af&
https://cdn.discordapp.com/attachments/791177690026606593/1516427243214340196/image.png?ex=6a4c4fac&is=6a4afe2c&hm=850bda5cd5ef14065fc8a43a31ed973c65fc7725321605d70b4c48251f3f84dc&
https://cdn.discordapp.com/attachments/791177690026606593/1516674795281059940/GvHYfiBW0AAj-PM.png?ex=6a4c8d79&is=6a4b3bf9&hm=6aab8c4567caa75cabe9b6e5bfc7e7d9a82554b3dc01e1c7da2c270a8d38e41c&
https://cdn.discordapp.com/attachments/791177690026606593/1516869629379608626/RDT_20260617_1918015647641423346296925.jpg?ex=6a4c9a2d&is=6a4b48ad&hm=e73b061039f2c71aaaac37359fe420f34056552733da5fb5da2add495a0a0f71&
https://cdn.discordapp.com/attachments/791177690026606593/1516869647490617585/RDT_20260617_1917445622057773315906825.jpg?ex=6a4c9a32&is=6a4b48b2&hm=a5ab6e637c8511e95f2f6a6e4eb230060df7f170c36c764327beaba9750c18ff&
https://cdn.discordapp.com/attachments/791177690026606593/1517072765444685874/Machine_mommy_064_1.mp4?ex=6a4c05dd&is=6a4ab45d&hm=8e1caaa508149f870ae9b6941c09b672d20bbd9390733b017a030802ad4fe618&
https://cdn.discordapp.com/attachments/791177690026606593/1517078550455517265/gxCrBxb2_720p.mp4?ex=6a4c0b40&is=6a4ab9c0&hm=b99a7ec855ecd6a1c2ebf2977d6bcdb833005da38f2ea7a3f34c073ca816696e&
https://cdn.discordapp.com/attachments/791177690026606593/1517101571777888426/EPORNER.COM_-_Z1unRfs3Mr3_comendo_a_namoradinha_gotica_gostosa_1080.mp4?ex=6a4c20b1&is=6a4acf31&hm=21cfd8e3548ababc57e6c77c5b1c3352a1408f63650eff59a55c9187b54162d4&
https://cdn.discordapp.com/attachments/791177690026606593/1517180995999109362/42dcdc2e9a65605f28725c52c533bd55.mp4?ex=6a4c6aa9&is=6a4b1929&hm=8bed1df3573f6486f03f0e58290812ddd3d5450a06758678bea0ad49c39b7906&
https://cdn.discordapp.com/attachments/791177690026606593/1517252131105800253/Goth_Spitreligion_Gives_A_BJ_To_Her_Gamer_BF_PimpBunny.mp4?ex=6a4c0429&is=6a4ab2a9&hm=77f56843304df857343ce1c8395ee5db2cf6936a4a77f253d475d48dfbb6e9bc&
https://cdn.discordapp.com/attachments/791177690026606593/1517345707286069298/HG0-0bTa4AAT2Sj.png?ex=6a4c5b4f&is=6a4b09cf&hm=477c7269c5c8eb1b6dd3689f935418e560ddcac761eee6b91c1020d3d2de7f1f&
https://cdn.discordapp.com/attachments/791177690026606593/1517345707747577917/HG0-0bjagAAX5fu.png?ex=6a4c5b4f&is=6a4b09cf&hm=bafa3869de6a1f8084616cf4e8d77eaee12d522d9ece002d6ac14c66797f2752&
https://cdn.discordapp.com/attachments/791177690026606593/1517359754945495080/GhTqR5tXgAAnnJe.png?ex=6a4c6864&is=6a4b16e4&hm=5b9a6049685e35a0fd453eee540cb3d4b6bea2f65dff819628895407ca8a4b3d&
https://cdn.discordapp.com/attachments/791177690026606593/1517470265120915506/PICS_-_by_Gigafans.net1108.jpg?ex=6a4c2690&is=6a4ad510&hm=e639def6844627c72448ba54b2423bf96f7f0687c134494c84838a02fec12dae&
https://cdn.discordapp.com/attachments/791177690026606593/1517470265120915506/PICS_-_by_Gigafans.net1108.jpg?ex=6a4c2690&is=6a4ad510&hm=e639def6844627c72448ba54b2423bf96f7f0687c134494c84838a02fec12dae&=
https://cdn.discordapp.com/attachments/791177690026606593/1517470266031345765/PICS_-_by_Gigafans.net2164.jpg?ex=6a4c2690&is=6a4ad510&hm=e5c758c23a1b935284c07e84184a8e5b7443eb318862afcc414eee43ed1c1d8e&
https://cdn.discordapp.com/attachments/791177690026606593/1517470266031345765/PICS_-_by_Gigafans.net2164.jpg?ex=6a4c2690&is=6a4ad510&hm=e5c758c23a1b935284c07e84184a8e5b7443eb318862afcc414eee43ed1c1d8e&=
https://cdn.discordapp.com/attachments/791177690026606593/1517470267105087488/PICS_-_by_Gigafans.net64.jpg?ex=6a4c2690&is=6a4ad510&hm=caf164e0bd127526a2f777a2ecf10e0f2d86f053f60354296b429816f4cc5e60&
https://cdn.discordapp.com/attachments/791177690026606593/1517470267105087488/PICS_-_by_Gigafans.net64.jpg?ex=6a4c2690&is=6a4ad510&hm=caf164e0bd127526a2f777a2ecf10e0f2d86f053f60354296b429816f4cc5e60&=
https://cdn.discordapp.com/attachments/791177690026606593/1517470268379889664/PICS_-_by_Gigafans.net263.jpg?ex=6a4c2691&is=6a4ad511&hm=90a6d09217bcd82b78502ecf60a01d48dfcf6a855b9c9de1a4def8447230b260&
https://cdn.discordapp.com/attachments/791177690026606593/1517470268379889664/PICS_-_by_Gigafans.net263.jpg?ex=6a4c2691&is=6a4ad511&hm=90a6d09217bcd82b78502ecf60a01d48dfcf6a855b9c9de1a4def8447230b260&=
https://cdn.discordapp.com/attachments/791177690026606593/1517549696074125384/9qWuZC5qdTG-h4Ti.mp4?ex=6a4c708a&is=6a4b1f0a&hm=c7007062c9201b462f48541797d6d03101d744795ffc283871989e83642865c7&
https://cdn.discordapp.com/attachments/791177690026606593/1517549813984526456/zu9S2qahVTdpJWZj.mp4?ex=6a4c70a6&is=6a4b1f26&hm=0afa9a8ee4c0f7aae9e5b7e6f563844f9e8dfc6c68588bb58cba871079a4ebf6&
https://cdn.discordapp.com/attachments/791177690026606593/1517556329139408927/HEILz5gWMAAjw7z.png?ex=6a4c76b7&is=6a4b2537&hm=66ccd6bdacd2e513d49ba0875d6be15730a985a630c3baa69b318d2a5eb3ebe1&
https://cdn.discordapp.com/attachments/791177690026606593/1517556329139408927/HEILz5gWMAAjw7z.png?ex=6a4c76b7&is=6a4b2537&hm=66ccd6bdacd2e513d49ba0875d6be15730a985a630c3baa69b318d2a5eb3ebe1&=
https://cdn.discordapp.com/attachments/791177690026606593/1517556329571549256/HAFHaALXwAARvIa.png?ex=6a4c76b7&is=6a4b2537&hm=ddcd679cbdc6c66e0485460cfaf6dd6e8aea6e08d1cbc1b70305c36bf8f497a9&
https://cdn.discordapp.com/attachments/791177690026606593/1517556329571549256/HAFHaALXwAARvIa.png?ex=6a4c76b7&is=6a4b2537&hm=ddcd679cbdc6c66e0485460cfaf6dd6e8aea6e08d1cbc1b70305c36bf8f497a9&=
https://cdn.discordapp.com/attachments/791177690026606593/1517556330305687782/G3gQF2LW0AAJXKM.png?ex=6a4c76b7&is=6a4b2537&hm=18d1bec1dd9ea231cfd66deeade07394f0afe13818506c762956fda3e0659b83&
https://cdn.discordapp.com/attachments/791177690026606593/1517556330305687782/G3gQF2LW0AAJXKM.png?ex=6a4c76b7&is=6a4b2537&hm=18d1bec1dd9ea231cfd66deeade07394f0afe13818506c762956fda3e0659b83&=
https://cdn.discordapp.com/attachments/791177690026606593/1517556331085561956/G3gQF2JWkAAmjlc.png?ex=6a4c76b8&is=6a4b2538&hm=763ac2696f03481db741354ee73375777e19d136e37fcbe753f917eebcd71f6a&
https://cdn.discordapp.com/attachments/791177690026606593/1517556331085561956/G3gQF2JWkAAmjlc.png?ex=6a4c76b8&is=6a4b2538&hm=763ac2696f03481db741354ee73375777e19d136e37fcbe753f917eebcd71f6a&=
https://cdn.discordapp.com/attachments/791177690026606593/1517559590240391310/RDT_20260619_1655559016350779370168695.jpg?ex=6a4c79c1&is=6a4b2841&hm=1869dea45f349973824c32679a14091f40249efe75d2a9b825eab5027416e361&
https://cdn.discordapp.com/attachments/791177690026606593/1517559590240391310/RDT_20260619_1655559016350779370168695.jpg?ex=6a4c79c1&is=6a4b2841&hm=1869dea45f349973824c32679a14091f40249efe75d2a9b825eab5027416e361&=
https://cdn.discordapp.com/attachments/791177690026606593/1517723318013263903/IMG_4515.jpeg?ex=6a4c697c&is=6a4b17fc&hm=5b7219652ef6fa546c47419e32ebbb0e458c5ebcb398166f9c2f2c986cadb49c&
https://cdn.discordapp.com/attachments/791177690026606593/1517728308660277298/D2D1A418-EA05-4D2C-B61D-DCEA8D36F60E.gif?ex=6a4c6e22&is=6a4b1ca2&hm=8f1c18f9f8d623faca930a5800e60b91770e5ca0f38d5ea650065be2fb7d064c&
https://cdn.discordapp.com/attachments/791177690026606593/1517728309214187581/26667576.gif?ex=6a4c6e22&is=6a4b1ca2&hm=f4274b6411efb80e96a6cb99c231b17ce29ffbea6edd1feb85494ff99dbff499&
https://cdn.discordapp.com/attachments/791177690026606593/1517728309868232825/image1.gif?ex=6a4c6e23&is=6a4b1ca3&hm=888b60901fc72d694071c27c84b2863de9d43709ae31d30f8e6899cd233d448a&
https://cdn.discordapp.com/attachments/791177690026606593/1517728310577332385/58.gif?ex=6a4c6e23&is=6a4b1ca3&hm=38ecd8b7e90ebee1c36739d537912e04b73f97d0fe8881b39bb3e837ef0ca922&
https://cdn.discordapp.com/attachments/1493568667164868659/1517738326453387345/HKXPKO4WUAAGo_D.png?ex=6a4c7777&is=6a4b25f7&hm=707b41c639e0f982509d0631df81df4e6fc6dd349e0679c606b53c27ef1dfe38&
https://cdn.discordapp.com/attachments/791177690026606593/1517846812558491758/HqDVN_DydXNDxO_t.mp4?ex=6a4c33c0&is=6a4ae240&hm=12071e0ba9d7e2ca5a4e9185954977ed96a438e9a311bde1b480ca504ecd82e7&
https://cdn.discordapp.com/attachments/791177690026606593/1517847006905765990/HLHB926WoAAN1LG.png?ex=6a4c33ee&is=6a4ae26e&hm=e6bff0b5fc70202dea5127c1fc67f54cb271c6be24595d7e637dfba6f85b60ed&
https://cdn.discordapp.com/attachments/791177690026606593/1517947784274247912/viddit_246d7f09.gif?ex=6a4c91c9&is=6a4b4049&hm=412854749d605ce19620c9f45ed729581f5f66aab26a8179799132a90a84c513&
https://cdn.discordapp.com/attachments/791177690026606593/1517948168673820964/RDT_20260620_1843558796991545814656970.jpg?ex=6a4c9225&is=6a4b40a5&hm=b17c63de07fb94727543d3603c0b281804aa7b9a93b09bc0259d6061d4906dcb&
https://cdn.discordapp.com/attachments/791177690026606593/1517948187254587562/RDT_20260620_1843095033138621086619647.jpg?ex=6a4c9229&is=6a4b40a9&hm=3cbb88c40d2ee7e2c95e17d6a241578bee8adef312485df19e96be050475ab1b&
https://cdn.discordapp.com/attachments/791177690026606593/1518173324595822592/rm68relr048h1.png?ex=6a4c1256&is=6a4ac0d6&hm=0a072c3a11904d75369cf0177bb3f394e951d80a70342b3ee1be62182ea724b7&
https://cdn.discordapp.com/attachments/791177690026606593/1518180221570912266/SandybrownTrustingDeermouse.mp4?ex=6a4c18c3&is=6a4ac743&hm=0191bc378e353d3efb5828442fdd3975550ae39429459a9ab4e5a2dad228b34a&
https://cdn.discordapp.com/attachments/791177690026606593/1518190534794149928/KJo7UVgypzauv69R.mp4?ex=6a4c225e&is=6a4ad0de&hm=a3dfb7cae41eb7586bae4f08e6d40e8956987071d2cff8219b25854ced2f48e2&
https://cdn.discordapp.com/attachments/791177690026606593/1518297136024912054/20260407_140425.jpg?ex=6a4c85a5&is=6a4b3425&hm=e17f90b178c12e16ab9005addb34fd204d7fa741154174bfd02a434cd949bb43&
https://cdn.discordapp.com/attachments/791177690026606593/1120668232886538280/ruru_swim.png?ex=6a4c325f&is=6a4ae0df&hm=f7e3af9042eb909a95ca6ba5c8b528035da08bdd6f118f3ce0b484d5b6b86ba9&
https://cdn.discordapp.com/attachments/791177690026606593/1518379644267532308/RDT_20260312_221558.mp4?ex=6a4c29bd&is=6a4ad83d&hm=d780187b4c66c6dd53050450c8106a97a2ab08d10ff16f4477eec153b2c4f0da&
https://cdn.discordapp.com/attachments/791177690026606593/1518455133405581393/GrQooAaWUAAIceO.png?ex=6a4c700b&is=6a4b1e8b&hm=7a1a7fbc4c64b19cfeb05bde96c80a1642be1461602ead58ef7e37c3f1a78f7c&
https://cdn.discordapp.com/attachments/791177690026606593/1518484071653576825/FVygcnkr_720p.mp4?ex=6a4c8afe&is=6a4b397e&hm=5a85e1f9a2789c8b92f846b235a715c6dded68004c9caf408f569b15e8711c48&
https://cdn.discordapp.com/attachments/791177690026606593/1518598821075222599/KdNwRr7QZOcj4SIs.mp4?ex=6a4c4d1d&is=6a4afb9d&hm=f488b9bea44df5ace70160c275c55273bd1693b5315689c01c12b3777d0a5376&
https://cdn.discordapp.com/attachments/791177690026606593/1518599328934002718/RDT_20260622_1350376943829134449625081.jpg?ex=6a4c4d96&is=6a4afc16&hm=ad7a3f8ecb360038b369c965cb5bd61b7935a5bd758eb7d318dcc91cd908bdda&
https://cdn.discordapp.com/attachments/791177690026606593/1518599328934002718/RDT_20260622_1350376943829134449625081.jpg?ex=6a4c4d96&is=6a4afc16&hm=ad7a3f8ecb360038b369c965cb5bd61b7935a5bd758eb7d318dcc91cd908bdda&=
https://cdn.discordapp.com/attachments/791177690026606593/1514595312415801385/HJ6AtGeXoAA-74u.png?ex=6a4c3d0e&is=6a4aeb8e&hm=d923b2889a5645ddb3c6096608c5254962cc7f01788f1b013b7bf07d2775604f&=
https://cdn.discordapp.com/attachments/791177690026606593/1514595312730243224/HKTvSGFXoAAq7fG.png?ex=6a4c3d0e&is=6a4aeb8e&hm=0097c23373b2d0fcd03f6d2343d716e41b3fc5bc343781190082b78b205e60d8&=
https://cdn.discordapp.com/attachments/791177690026606593/1514595313221111969/HKefE_KaUAAwBJy.png?ex=6a4c3d0e&is=6a4aeb8e&hm=aef66669473f15b9a699a877bc9a8ddfc14313969335406a650f0b030c90ed5f&=
https://cdn.discordapp.com/attachments/791177690026606593/1513091697762898031/IMG_2307.jpeg?ex=6a4c0ab4&is=6a4ab934&hm=f103ba7ca8a472e5ef0942b57a6800f294e95b3f1e6d964dd2ce4cf42979665f&
https://cdn.discordapp.com/attachments/791177690026606593/1513094063157547108/m0BlJ9lj_kI.jpg?ex=6a4c0ce8&is=6a4abb68&hm=bd0bed7e5676a64233d81f891ddb7b1ddd3dfacbc8208edf5f6a26a49556eb6f&
https://cdn.discordapp.com/attachments/791177690026606593/1513131280282419290/IMG_20260607_154321_690.jpg?ex=6a4c2f91&is=6a4ade11&hm=cf9824dac2627f92a29fa097da63eccdba6e2b4341d3bc811c42d17cf17687f6&
https://cdn.discordapp.com/attachments/791177690026606593/1513205231411007580/HKE-5VpXEAAGDT7.png?ex=6a4c7471&is=6a4b22f1&hm=bed9713c4fc33d2dd38206376632434a1e685f72c67ab9047f95a5bfff36494c&
https://cdn.discordapp.com/attachments/791177690026606593/1513233180394786857/RDT_20260607_1021372974398905618424864.jpg?ex=6a4c8e78&is=6a4b3cf8&hm=63dcdd2bac6e757c4af515f517ae24ca25d8826a1761b72860c041f83cb2e15b&
https://cdn.discordapp.com/attachments/791177690026606593/1513233180767813694/RDT_20260607_1021508596044442849153417.jpg?ex=6a4c8e78&is=6a4b3cf8&hm=70c681136ad3dde71fed813688aae3a77eb91f403d602b03307942eb2e0dcc1a&
https://cdn.discordapp.com/attachments/791177690026606593/1513233181179121805/MonumentalDrearyElephant.mp4?ex=6a4c8e78&is=6a4b3cf8&hm=7b7fe14872eef1d8054f9119304e81e886c904b12ee2d3a533d7a2f3c429b8ce&
https://cdn.discordapp.com/attachments/791177690026606593/1513233181531177202/TemptingLonelyBighornedsheep.mp4?ex=6a4c8e78&is=6a4b3cf8&hm=315f477899140599f48b21bb49f12408fd96d01f1dec9c350eced7679d2a22ce&
https://cdn.discordapp.com/attachments/791177690026606593/1513283142532862112/IMG_2248_1.jpg?ex=6a4c1440&is=6a4ac2c0&hm=d8e3a4346271a16b5b59858b65dd0d2283bf1725d38ddcd974e4172944778223&
https://cdn.discordapp.com/attachments/791177690026606593/1513309781459341503/boobie.mp4?ex=6a4c2d0f&is=6a4adb8f&hm=6a45be558417d268795ecfe686fab947e127e11170bd325c622c6bc697b9d4b8&
https://cdn.discordapp.com/attachments/791177690026606593/1513321189177823392/IMG_2405.jpeg?ex=6a4c37af&is=6a4ae62f&hm=7d97e1041a3ef61963af07156e801b41df53468f44c7869fae77c0089f0462c4&
https://cdn.discordapp.com/attachments/791177690026606593/1513362077979381880/image.png?ex=6a4c5dc4&is=6a4b0c44&hm=6b823767112f224db732ba6f41e2c98d63ab3a241d383bc94e9fd9eaeca1f821&
https://cdn.discordapp.com/attachments/791177690026606593/1513458558476226640/bj.mp4?ex=6a4c0edf&is=6a4abd5f&hm=9a1a96fb5575f514bca69415fa9427d051585f25f68c09162711d4e994837192&
https://cdn.discordapp.com/attachments/791177690026606593/1513483221881589892/IMG_2415.jpeg?ex=6a4c25d7&is=6a4ad457&hm=6c16f92a43b0e733416e71272fbc99196358e8c6e3137a5d0a51e2419822306a&
https://cdn.discordapp.com/attachments/791177690026606593/1513531474870145108/IMG_20260608_161322_760.jpg?ex=6a4c52c7&is=6a4b0147&hm=e382950e01b190a152d3e5f04c00cf5394dd68a4914d77d190db0d6d4c6398dd&
https://cdn.discordapp.com/attachments/791177690026606593/1513566912699957318/20260608_163405.jpg?ex=6a4c73c8&is=6a4b2248&hm=e48ca0e549d47dbc245471de84e090eae9a8b0c677374c7ed19ce13dca5d32f8&
https://cdn.discordapp.com/attachments/791177690026606593/1513645099295440958/video_2023-04-26_12-42-58.mp4?ex=6a4c13d9&is=6a4ac259&hm=9f8d3ce9f85ab5e7e89ae0ed36dd94cdee2476b0bf25e4ad9c541d6b2caebcbc&
https://cdn.discordapp.com/attachments/791177690026606593/1513756956060287046/rEI1jwTJ5yUcBj03.mp4?ex=6a4c7c06&is=6a4b2a86&hm=a104fda3f090c6f8b97c02908d4f2724f8735fca99138a8b1fd934b4efe308b0&
https://cdn.discordapp.com/attachments/791177690026606593/1513816870833094696/20260608_193301.jpg?ex=6a4c0b13&is=6a4ab993&hm=323eb14804fb4210b1ddc6c69b999caa3ea540db64c3c5ae1051afda1a87d160&
https://cdn.discordapp.com/attachments/791177690026606593/1513890637177688245/viddit_fd147ee6.gif?ex=6a4c4fc6&is=6a4afe46&hm=c19780c3cd4f838483f8434b32fe86fc661591e67ad9892d69a31f06b02bd3ab&
https://cdn.discordapp.com/attachments/791177690026606593/1513890746317406259/RDT_20260609_1357302839894392998987166.jpg?ex=6a4c4fe0&is=6a4afe60&hm=a4517cc46ac0b2bc3c9b13e6140244b409c63ec215733de526ace408a476d3f7&
https://cdn.discordapp.com/attachments/791177690026606593/1514061286672039936/AdmirableTraumaticCalf.mp4?ex=6a4c45f4&is=6a4af474&hm=1b22bed67013ddd6f4d76acd9b4c0f34b1bda83d8deb31fb41fbb91fe018b66d&
https://cdn.discordapp.com/attachments/791177690026606593/1514061287078760610/WornUncomfortableAltiplanochinchillamouse.mp4?ex=6a4c45f4&is=6a4af474&hm=02f2413d6cbc913b8e31afc01eb27076d664ab8919bf664cf15b87086f2e49ba&
https://cdn.discordapp.com/attachments/791177690026606593/1514061287859032094/RDT_20260609_1715364474290508095748736.jpg?ex=6a4c45f4&is=6a4af474&hm=0369a751153180bf88d6725206f2ce3f83a757b5573efbf6dbff7dc4d6dd3300&
https://cdn.discordapp.com/attachments/791177690026606593/1514061288211484763/RDT_20260609_171615185758036550544170.jpg?ex=6a4c45f5&is=6a4af475&hm=4f620c564bc1c8bf0107e20eb4097278ff369ccb59db188296057e37a40ccdf4&
https://cdn.discordapp.com/attachments/791177690026606593/1514061288605487155/RDT_20260609_1714508170003759666275230.jpg?ex=6a4c45f5&is=6a4af475&hm=79214d0f4f990b59b418455b0fc61f0f045ce4a5a60d5ff69df90f2fa709f799&
https://cdn.discordapp.com/attachments/791177690026606593/1514061289146548304/RDT_20260609_1713028094979614896589790.jpg?ex=6a4c45f5&is=6a4af475&hm=af8e8449a9760e73c2c4a22a4e73577e218e6bacf1c3dfd2b0cb411872628bfd&
https://cdn.discordapp.com/attachments/791177690026606593/1514061289448804362/RDT_20260609_1714404591585030255882124.jpg?ex=6a4c45f5&is=6a4af475&hm=87d66a063df22da1fddf0eec423ed8da66904f2060e8a11eb39c4507dc27380b&
https://cdn.discordapp.com/attachments/791177690026606593/1514061290027356270/RDT_20260609_1715396666750313033860752.jpg?ex=6a4c45f5&is=6a4af475&hm=1057b8de0035e1661e8831827ac7226a32bd83f91727090432e6da1818b96ac9&
https://cdn.discordapp.com/attachments/791177690026606593/1514061290383867957/RDT_20260609_1711448447157658047661712.jpg?ex=6a4c45f5&is=6a4af475&hm=fc2c7288ebff18897f0ea30eb8cbbda01979af32ebab231242b6a47f2915f997&
https://cdn.discordapp.com/attachments/791177690026606593/1514061291147497552/RDT_20260609_1716012320546427547576960.jpg?ex=6a4c45f5&is=6a4af475&hm=1fd29416a2b20ce6128d9bd6d146da819b77aa62966adb33931d684871be3c73&
https://cdn.discordapp.com/attachments/791177690026606593/1514168163892465784/ZeqxqEiB0u92dEp6_1-1.mp4?ex=6a4ca97e&is=6a4b57fe&hm=847abf0f2b67be1d7f4da5a587e78ca43f725c953991d0c9b383ed4d8d9cb3b3&
https://cdn.discordapp.com/attachments/791177690026606593/1511385044520796220/HJwyvjmXcAEqDmS.png?ex=6a4c6cc2&is=6a4b1b42&hm=e385f1403174479a57430c0c1271bde9ef97adbc81626d82a5961338fd3bf9bb&
https://cdn.discordapp.com/attachments/791177690026606593/1511416199542734949/RDT_20260602_1807352640131043472745386.jpg?ex=6a4c89c6&is=6a4b3846&hm=745a281ee37e8da5e46373398dec6ae05fe75a9be43ac2a03f25817178976165&
https://cdn.discordapp.com/attachments/791177690026606593/1502677691323646143/image-2.png?ex=6a4c6368&is=6a4b11e8&hm=99cb3daec697deffb49b1961a757b9e4f63bec8f5e50185d6523f64dd6612043&
https://cdn.discordapp.com/attachments/791177690026606593/1511640708799397968/X2Twitter.com_QQJPriYi6dZE5Xn__1280p.mov?ex=6a4c095d&is=6a4ab7dd&hm=98eef31a0c8f5f7e7455ed1d15d5d8d1c0d98e7ee774f442d4ab6afb42b83e41&
https://cdn.discordapp.com/attachments/791177690026606593/1511645614201507860/IMG_20260603_111929_268.jpg?ex=6a4c0def&is=6a4abc6f&hm=a441e7a8c5e3263f7358ee74a7be466e1a7d11bd3154b7e3b660237c1750f91f&
https://cdn.discordapp.com/attachments/791177690026606593/1511684853832093779/fzneCf13y8.png?ex=6a4c327a&is=6a4ae0fa&hm=d31bbbd7d8fb827a1c7f6d2bb96574c6c18f691d4909f064d3460675076a9ad2&
https://cdn.discordapp.com/attachments/791177690026606593/1511684854461235340/wK7nwK8tlS.png?ex=6a4c327b&is=6a4ae0fb&hm=9cdc58ba2c6bb41718ff422b9ba016a2f70a3622c362274a87079e98223d26b0&
https://cdn.discordapp.com/attachments/791177690026606593/1511794453386625235/IMG_20260604_010734_148.jpg?ex=6a4c988d&is=6a4b470d&hm=aa22f9bfda8bda6531afe31007f3afba0b2827557bff92ad907f087d24a09bae&
https://cdn.discordapp.com/attachments/791177690026606593/1511794453784826027/IMG_20260604_010733_863.jpg?ex=6a4c988d&is=6a4b470d&hm=1a740f4a6d5ea6bfefb049bcfc6e2faada647f95d1aca934b4ff8a9a39afd829&
https://cdn.discordapp.com/attachments/791177690026606593/1511794454120366150/IMG_20260604_010734_125.jpg?ex=6a4c988d&is=6a4b470d&hm=b6fee123be1615705d463237ccec7522301bc1f86c093933798240e6a902206c&
https://cdn.discordapp.com/attachments/791177690026606593/1511794454460109020/IMG_20260604_010734_316.jpg?ex=6a4c988d&is=6a4b470d&hm=6e30fad97eee7108b352f459f7279b778ae85b715e2e6d07851704219971d6ae&
https://cdn.discordapp.com/attachments/791177690026606593/1511941973269811360/RDT_20260528_2353315988318988211492777.jpg?ex=6a4c7930&is=6a4b27b0&hm=940255aaa4c52505bd7b190a5f21d3d217adfe69476b1ecd764370632f0b04f0&
https://cdn.discordapp.com/attachments/791177690026606593/1511941974133833882/RDT_20260528_2353199154270143648317498.jpg?ex=6a4c7931&is=6a4b27b1&hm=8262d8a96a0e5ac22d0a56e6534c7048e067f7d687ed602f2465c04250df42c3&
https://cdn.discordapp.com/attachments/791177690026606593/1512077602158809209/RDT_20260604_1356167949688254537837322.jpg?ex=6a4c4ec1&is=6a4afd41&hm=143592d667589516232a4246974f74595fcdb6cf5fc4bd98f8fc1a1a9a683c5d&
https://cdn.discordapp.com/attachments/791177690026606593/1512077602532229333/RDT_20260604_135619354312346301681726.jpg?ex=6a4c4ec1&is=6a4afd41&hm=1b9697629d594578d27431522c6ae13bd45a69a683bf0f5c918dc63ddb3401bb&
https://cdn.discordapp.com/attachments/791177690026606593/1512077858023936090/RDT_20260604_1357162465529145402591619.jpg?ex=6a4c4efe&is=6a4afd7e&hm=772a8f85413eec9c6564054a8217022d4f1f502b8521f3092ba4cffbf9c53fab&
https://cdn.discordapp.com/attachments/791177690026606593/1512204353925287936/mommys-vampire-body-v0-3rukogkcc2yg1.png?ex=6a4c1c0d&is=6a4aca8d&hm=00a1fd914b30c348ad57c80c2e8a229b81ca99efc85ba894a14c41c2a722ae69&
https://cdn.discordapp.com/attachments/1387236779081339113/1512211957954908362/image-1-1.jpg?ex=6a4c2322&is=6a4ad1a2&hm=763add747a51591c483121ba82e9c43f424ca9cc1981e0490e7bfd97247d530c&
https://cdn.discordapp.com/attachments/791177690026606593/1512710134554427422/ssstwitter.com_1780441036202.mp4?ex=6a4ca198&is=6a4b5018&hm=7c213f5c69eef00ac8eabade8b8a82253412850d6c68a9948c118d4948abe500&
https://cdn.discordapp.com/attachments/791177690026606593/1512770239824396398/HospitableFickleIrishterrier.mp4?ex=6a4c30d3&is=6a4adf53&hm=337f5eeb4a39f790d64936770a274606789f801797e45c0b96800ee5d3073637&
https://cdn.discordapp.com/attachments/791177690026606593/1512770240138711070/DarkgreyFondSockeyesalmon.mp4?ex=6a4c30d3&is=6a4adf53&hm=982451ba8fbbcab27ed5abb76bdc23a2558284afe6b2f5178e830237fb9f75f3&
https://cdn.discordapp.com/attachments/791177690026606593/1512804715648258148/IMG_2290.jpeg?ex=6a4c50ee&is=6a4aff6e&hm=79a6f8c10fa7f59918a8133679f2e99401db133fc1d638ad96342256ffbb5945&
https://cdn.discordapp.com/attachments/791177690026606593/1512832805246337154/IMG_20260606_195109_756.jpg?ex=6a4c6b17&is=6a4b1997&hm=bb1cfae1f95042440916dbdc29dc49742fec0e533650e85520abf0383a1c46bd&
https://cdn.discordapp.com/attachments/791177690026606593/1512864617792274442/RDT_20260606_1803356724092020760815658.jpg?ex=6a4c88b8&is=6a4b3738&hm=fe16b3979707c47e305a335520ad35d2db6df0fc5455c4a1a63dae5fe00640da&
https://cdn.discordapp.com/attachments/791177690026606593/1512914436233363578/VID_20260607_012039_960.mp4?ex=6a4c0e5e&is=6a4abcde&hm=874177659d1160d0866494ebd6d502a68ea144b80a32c46906ade74e8fb3ff3f&
https://cdn.discordapp.com/attachments/791177690026606593/1512929929522712616/IMG_20260607_022257_662.jpg?ex=6a4c1ccc&is=6a4acb4c&hm=62a3c080b3acf031b4c884a911a900d8bfa2c4bb610db941c9f21e0bc0d6c816&
https://cdn.discordapp.com/attachments/791177690026606593/1513024417477824573/image-4.png?ex=6a4c74cb&is=6a4b234b&hm=f4dd12ad55c4d222a64c3ea7216dc4de41612251c704696253322a289b397e97&
https://cdn.discordapp.com/attachments/791177690026606593/1513091697762898031/IMG_2307.jpeg?ex=6a4c0ab4&is=6a4ab934&hm=f103ba7ca8a472e5ef0942b57a6800f294e95b3f1e6d964dd2ce4cf42979665f&=
https://cdn.discordapp.com/attachments/791177690026606593/1513094063157547108/m0BlJ9lj_kI.jpg?ex=6a4c0ce8&is=6a4abb68&hm=bd0bed7e5676a64233d81f891ddb7b1ddd3dfacbc8208edf5f6a26a49556eb6f&=
https://cdn.discordapp.com/attachments/791177690026606593/1513131280282419290/IMG_20260607_154321_690.jpg?ex=6a4c2f91&is=6a4ade11&hm=cf9824dac2627f92a29fa097da63eccdba6e2b4341d3bc811c42d17cf17687f6&=
https://cdn.discordapp.com/attachments/791177690026606593/1511385044520796220/HJwyvjmXcAEqDmS.png?ex=6a4c6cc2&is=6a4b1b42&hm=e385f1403174479a57430c0c1271bde9ef97adbc81626d82a5961338fd3bf9bb&=
https://cdn.discordapp.com/attachments/791177690026606593/1511416199542734949/RDT_20260602_1807352640131043472745386.jpg?ex=6a4c89c6&is=6a4b3846&hm=745a281ee37e8da5e46373398dec6ae05fe75a9be43ac2a03f25817178976165&=
https://cdn.discordapp.com/attachments/791177690026606593/1513024417477824573/image-4.png?ex=6a4c74cb&is=6a4b234b&hm=f4dd12ad55c4d222a64c3ea7216dc4de41612251c704696253322a289b397e97&=
https://cdn.discordapp.com/attachments/791177690026606593/1508929987372253257/ppv4508591034284692406f8d6716a-345f-47b7-a61d-597feb2a85b5.mp4?ex=6a4c100f&is=6a4abe8f&hm=f077b3bf0c288f8980f4c6063b363a0c2a2f2bcb9365bf79d321051542ed517e&
https://cdn.discordapp.com/attachments/791177690026606593/1508969155477639258/Screenshot_20260527_005817_X.jpg?ex=6a4c3489&is=6a4ae309&hm=b1915d5d334893c28eae488a08e5c4428d46c3547269511cd29a8a34e3c7288e&
https://cdn.discordapp.com/attachments/791177690026606593/1508969155997601904/Screenshot_20260527_005810_X.jpg?ex=6a4c348a&is=6a4ae30a&hm=2c20cad6f8340e6d6066652d33296c0f7056faf9bde902e3a8bd50fdc427460d&
https://cdn.discordapp.com/attachments/791177690026606593/1509120293027713065/IMG_20260527_120430_768.jpg?ex=6a4c188b&is=6a4ac70b&hm=ba334abc49116eb61202190f463d232ab5f64712fb320775f67e128e4a37ed11&
https://cdn.discordapp.com/attachments/791177690026606593/1509126820706914375/IMG_20260527_122949_127.jpg?ex=6a4c1ea0&is=6a4acd20&hm=25b88fa287545d62f97f256905a65deae14300bc7dbcbaf4e5018d9d871816d7&
https://cdn.discordapp.com/attachments/791177690026606593/1509126821118083092/IMG_20260527_122949_152.jpg?ex=6a4c1ea0&is=6a4acd20&hm=8bf7778e1f8ff79512a544f0f8210f11633d22f625964f771b1df511d0785e85&
https://cdn.discordapp.com/attachments/791177690026606593/1509126821466345583/IMG_20260527_122949_338.jpg?ex=6a4c1ea0&is=6a4acd20&hm=a6553f9d9edb019df54c8be943fdc7246aa92547f1513886759b345f19676849&
https://cdn.discordapp.com/attachments/791177690026606593/1509166031065710834/me0wkkyyy_2026-05-27-05-47-04_1779850024628.mp4?ex=6a4c4324&is=6a4af1a4&hm=e87f3f390839ec9f218d1168d058e074f804674d851783b8c7f6fa97fbd3387d&
https://cdn.discordapp.com/attachments/791177690026606593/1509558510117982228/RDT_20260107_065946.mp4?ex=6a4c5f2b&is=6a4b0dab&hm=cd829a97876b859cfb469c5813af55f3d7ec04e48dc014f4ec54630b0e6b4bb8&
https://cdn.discordapp.com/attachments/791177690026606593/1509750999009591418/PleasingConventionalDutchshepherddog.mp4?ex=6a4c69af&is=6a4b182f&hm=75870cb4ae323760480d7e09322fdb0e52926d8a806c60bbce2cd59dd99678d8&
https://cdn.discordapp.com/attachments/791177690026606593/1510213445394628778/20260530_122704.jpg?ex=6a4c1e1f&is=6a4acc9f&hm=83d4ec2df916da9eab56de38b4fce74179cd921e012495cc6ea58a1c914e9e4a&
https://cdn.discordapp.com/attachments/791177690026606593/1510213445746823168/20260530_122821.jpg?ex=6a4c1e1f&is=6a4acc9f&hm=bc7ecf45ebd2a4ecd1c0624a315bdbcd46e8c0c9635c9f32c224ea00a3e54a75&
https://cdn.discordapp.com/attachments/791177690026606593/1510216750292140142/RDT_20260530_1040572783724935187825160.jpg?ex=6a4c2133&is=6a4acfb3&hm=ef633211d9987467d09fb8b289f9439c4f81ab055126b69cd8265737ba6e933e&
https://cdn.discordapp.com/attachments/791177690026606593/1510293393547329748/IMG_20260530_145936_438.jpg?ex=6a4c6894&is=6a4b1714&hm=6bf14db3929646f95a1e11b8db8803703313f51ac3b7d4c56d808822f826a769&
https://cdn.discordapp.com/attachments/791177690026606593/1510744821873246270/RDT_20260531_2240126648916148153436021.jpg?ex=6a4c12c1&is=6a4ac141&hm=b8731501c6e391380283a00c5ca3d35015e228def3e474139b3b0159fb6139cb&
https://cdn.discordapp.com/attachments/791177690026606593/1510998077899538506/37f2334730456e0a23c026a295d4df3c.mp4?ex=6a4c55de&is=6a4b045e&hm=5944ca105c13b92e58596d04526f97150dd6dcc327fb58f1d32f0bf8db1a3b3f&
https://cdn.discordapp.com/attachments/791177690026606593/1511039963624374322/fdfddfd.MP4?ex=6a4c7ce1&is=6a4b2b61&hm=a478221a40b2aa49620b0756777f182d9cdc8437dd6b8e4dcf7163f24487b614&
https://cdn.discordapp.com/attachments/791177690026606593/1511210699337240616/Unconfirmed_download_https___x.com_i_status_2043860801056903297720P.mp4?ex=6a4c7323&is=6a4b21a3&hm=3a2bd960b0dda587993854dff240ce7f30b40231c6deff686931f66c93ccb075&
https://cdn.discordapp.com/attachments/791177690026606593/1511285035515510875/IMG_20260602_112511_411.jpg?ex=6a4c0f9e&is=6a4abe1e&hm=cb966d7915d6312ea50c770978f9a4e55cd9556a59b96ce38d5e08380b0deda9&
https://cdn.discordapp.com/attachments/791177690026606593/1511364671662329960/IMG_20260602_204116_242.jpg?ex=6a4c59c9&is=6a4b0849&hm=881180029fdc4ee482c1e79a16ca24ac654e974bc3e2cadba935cc6cf9d54236&
https://cdn.discordapp.com/attachments/791177690026606593/1511364672006127797/IMG_20260602_204003_548.jpg?ex=6a4c59c9&is=6a4b0849&hm=33e4b1e359f32d7a769249899901434f3a73fa32c5c92ed0ef9ed0ebd756662c&
https://cdn.discordapp.com/attachments/791177690026606593/1507882863947681912/RDT_20260524_0007123103348054188195547.jpg?ex=6a4c3559&is=6a4ae3d9&hm=0fc3c3e815a484d1b2739c43aed6959900f466d3bcb6e90fb71ccff2db467077&
https://cdn.discordapp.com/attachments/791177690026606593/1507949166138101820/image.png?ex=6a4c7319&is=6a4b2199&hm=9387210ba55bdca61c91e261f02c012c4c6f8c55d7efb2303c8878642cc65797&
https://cdn.discordapp.com/attachments/791177690026606593/1507949166645477589/image.png?ex=6a4c7319&is=6a4b2199&hm=6c63b4b27c9a64454da3db62f6a7ca49c6b6d7fe1c81218487048e4c4350decc&
https://cdn.discordapp.com/attachments/791177690026606593/1507949167069106327/image.png?ex=6a4c7319&is=6a4b2199&hm=5d65037ce581036d8a71711126014c31df9c0e978a4d31ec0b4abf9dc7fe08f7&
https://cdn.discordapp.com/attachments/791177690026606593/1507983994392805517/SnapInsta.to_564893339_18324949930240481_6308808904500180650_n.jpeg?ex=6a4c9389&is=6a4b4209&hm=f95eb2317464d34d9ba6d0b1ea175cb91d38283830a9564ec5d2cfe9f5f2425b&
https://cdn.discordapp.com/attachments/791177690026606593/1508014122195878018/M0DuUT5LXpTubkSv.mov?ex=6a4c06d8&is=6a4ab558&hm=a183cadb3c9a938b2d64263aba99d8378e95fce52cc6c8e99e3380c5aa9a28ab&
https://cdn.discordapp.com/attachments/791177690026606593/1508043355282472990/tell-me-your-size-and-ill-give-you-a-new-lockscreen-v0-8532zl12qdwe1.webp?ex=6a4c2211&is=6a4ad091&hm=f2db1c266d77802b7ed0a193728310f1013ca2057abb09500b66b7d7af8e91f5&
https://cdn.discordapp.com/attachments/791177690026606593/1508043355756695673/is-this-post-safe-enough-for-you-or-are-you-gonna-relapse-v0-n5bprm60vlxe1.webp?ex=6a4c2212&is=6a4ad092&hm=59c417246c8cbbea29eeb3c3bca918bb4b48a00cc8b04979ae93adecd4be9379&
https://cdn.discordapp.com/attachments/791177690026606593/1508057859064201276/IMG_20260524_134310_053.jpg?ex=6a4c2f93&is=6a4ade13&hm=a3574a39b45dc9ba0689ad0add0c19adf0954e9fb920743ef2c9f4184a8f7807&
https://cdn.discordapp.com/attachments/791177690026606593/1508094436490350715/tweeload_xqv43s35.mp4?ex=6a4c51a4&is=6a4b0024&hm=dd68277e0082aa74d388e9c3cc29f110fa3b475cbd1f5d1ae506ee6d2dfe9f4a&
https://cdn.discordapp.com/attachments/791177690026606593/1508117295464190002/RDT_20260524_1539023527576962417123831.jpg?ex=6a4c66ee&is=6a4b156e&hm=9a8b3e7241847a396fe6ccdafe31975902e192090bec153e7b11aa36b0aab3bb&
https://cdn.discordapp.com/attachments/791177690026606593/1508156985852563677/IMG_20260524_171733_839.jpg?ex=6a4c8be5&is=6a4b3a65&hm=a363f8c1ee5057378e3b62c4d71f0dda0f7e620a0cf2ca4fb29f7c4bf83f4c5f&
https://cdn.discordapp.com/attachments/791177690026606593/1508208943292219614/RDT_20260521_1933055393271403169597566.jpg?ex=6a4c1389&is=6a4ac209&hm=06492904b3ffa1f07dd9448db2e7f5cc52d69a8c8d7383b96c73a0e4541a0448&
https://cdn.discordapp.com/attachments/791177690026606593/1508356404401148006/IMG_20250328_114539_647.jpg?ex=6a4c9cde&is=6a4b4b5e&hm=8e3bb517ad3d897bcf09c55fc355b6907e2fea429c70be9f39b083c8ec095930&
https://cdn.discordapp.com/attachments/791177690026606593/1508392402321408090/IMG_20260524_204647_775.jpg?ex=6a4c15a5&is=6a4ac425&hm=f463f4148356fddebb347790b346b2f3bcd4656dbe494198475682a02a0b9521&
https://cdn.discordapp.com/attachments/791177690026606593/1508392402732453958/IMG_20260524_204647_941.jpg?ex=6a4c15a5&is=6a4ac425&hm=d1195f3dcf304a8200dd8bfa7a70c501d7a936818e699adf1ad461a4cd97218c&
https://cdn.discordapp.com/attachments/791177690026606593/1508466019029614804/RDT_20260513_0308582998843473418537523.jpg?ex=6a4c5a34&is=6a4b08b4&hm=e3f33f3ae4c55952b40a5b3c357b3e93ece3e6a8d5b0d0c32d56da3b1c5d30a4&
https://cdn.discordapp.com/attachments/791177690026606593/1508466047945281617/IMG_6765.jpg?ex=6a4c5a3b&is=6a4b08bb&hm=1767d835171384d9c602c0f7f57f46c3fca95ee59eb0a5f2ef2fca89a8537fa3&
https://cdn.discordapp.com/attachments/791177690026606593/1508468398617526402/1a973a3c-f71d-4a73-acd3-206fc15cd52e.png?ex=6a4c5c6c&is=6a4b0aec&hm=51fa076b093ba4799b0eaa81c985d457897ef3ad19d08c54eea8b2355258647e&
https://cdn.discordapp.com/attachments/791177690026606593/1508468399007727826/2d8bffe1-bcef-4b90-9e78-5dd7156718a8.png?ex=6a4c5c6c&is=6a4b0aec&hm=3f7ecc1a23c142224ba8d27ceee0afe2b87511d8bcb423fc7de1e97e66fa48a4&
https://cdn.discordapp.com/attachments/791177690026606593/1508468399754182907/6dbf0a0e-12e3-44a7-bc33-5ac43666bcbf.png?ex=6a4c5c6c&is=6a4b0aec&hm=6d084d0b1066046884aa2010a934304ae3e0c116abf47a8c25ec118580e519b5&
https://cdn.discordapp.com/attachments/791177690026606593/1508468400404303962/889e0495-6c23-4552-ac48-14205e3a259c.png?ex=6a4c5c6c&is=6a4b0aec&hm=d3ef5cf0386a36c952f1325532b95cceb58e181d7dc40596453dc9be943c3044&
https://cdn.discordapp.com/attachments/791177690026606593/1508468401335701515/26384692-2a5c-4e43-ba58-bbba94d10a90.png?ex=6a4c5c6c&is=6a4b0aec&hm=5158799d688330e2918cecce3174f56c4572c07e2ec70454ed5252e222d9b386&
https://cdn.discordapp.com/attachments/791177690026606593/1508468401859727380/b1a2833c-8962-479b-9bfb-2a0a5ea778d5.png?ex=6a4c5c6c&is=6a4b0aec&hm=7f36a8fcee6352d14cacf9e32a7bce24243e19722c8c24ceef75256891d8eaae&
https://cdn.discordapp.com/attachments/791177690026606593/1508468402379817110/2354178c-8c90-4731-9829-2b2c9777e072.png?ex=6a4c5c6d&is=6a4b0aed&hm=b9d6a6364097d38ea89f314f5fa7a53c45a9058ed0cebce08ebfae7ea4e056e6&
https://cdn.discordapp.com/attachments/791177690026606593/1508468403160088737/ba0ec255-cc4d-4870-8132-a42a9f26e1f3.png?ex=6a4c5c6d&is=6a4b0aed&hm=83b7a54d904543743ee92a2577054a27a68190c16d2591b13ae0dcd4b576afda&
https://cdn.discordapp.com/attachments/791177690026606593/1508468403655020574/c9b51f4b-b284-454f-96bb-69a62e74b974.png?ex=6a4c5c6d&is=6a4b0aed&hm=de56d26bc50e571a3e8baac7f45ff852b951aeec8934812a0ac94c29d4024116&
https://cdn.discordapp.com/attachments/791177690026606593/1508468404128972990/321b8256-315b-4734-96a6-f3583c7ee962.png?ex=6a4c5c6d&is=6a4b0aed&hm=11229f4a1aca3efa570b8eb0838c1087787b674b5e8f466e894551a3664e3b05&
https://cdn.discordapp.com/attachments/791177690026606593/1508812955666481214/RDT_20260526_1343397592192254753583747.jpg?ex=6a4c4bd1&is=6a4afa51&hm=e1bf7b5c0bed0e1a23db854b51a247cb24dd0c37cd2c27e0ba100a9ab099e92d&
https://cdn.discordapp.com/attachments/791177690026606593/1508813016207196170/RDT_20260526_1343197247839473687239588.jpg?ex=6a4c4bdf&is=6a4afa5f&hm=70e45bcec33beae397f78f19e3551f64095be18f1d98b24638db268e4b4a9cd7&
https://cdn.discordapp.com/attachments/791177690026606593/1508813038214451261/RDT_20260526_134234.mp4?ex=6a4c4be4&is=6a4afa64&hm=19db6a6c05467a321f544d3d04c4f91316cceaef14df8f5d91c4b223327af1ec&
https://cdn.discordapp.com/attachments/791177690026606593/1511285035515510875/IMG_20260602_112511_411.jpg?ex=6a4c0f9e&is=6a4abe1e&hm=cb966d7915d6312ea50c770978f9a4e55cd9556a59b96ce38d5e08380b0deda9&=
https://cdn.discordapp.com/attachments/791177690026606593/1511364671662329960/IMG_20260602_204116_242.jpg?ex=6a4c59c9&is=6a4b0849&hm=881180029fdc4ee482c1e79a16ca24ac654e974bc3e2cadba935cc6cf9d54236&=
https://cdn.discordapp.com/attachments/791177690026606593/1511364672006127797/IMG_20260602_204003_548.jpg?ex=6a4c59c9&is=6a4b0849&hm=33e4b1e359f32d7a769249899901434f3a73fa32c5c92ed0ef9ed0ebd756662c&=
https://cdn.discordapp.com/attachments/791177690026606593/1507882863947681912/RDT_20260524_0007123103348054188195547.jpg?ex=6a4c3559&is=6a4ae3d9&hm=0fc3c3e815a484d1b2739c43aed6959900f466d3bcb6e90fb71ccff2db467077&=
https://cdn.discordapp.com/attachments/791177690026606593/1507949166138101820/image.png?ex=6a4c7319&is=6a4b2199&hm=9387210ba55bdca61c91e261f02c012c4c6f8c55d7efb2303c8878642cc65797&=
https://cdn.discordapp.com/attachments/791177690026606593/1507949166645477589/image.png?ex=6a4c7319&is=6a4b2199&hm=6c63b4b27c9a64454da3db62f6a7ca49c6b6d7fe1c81218487048e4c4350decc&=
https://cdn.discordapp.com/attachments/791177690026606593/1507949167069106327/image.png?ex=6a4c7319&is=6a4b2199&hm=5d65037ce581036d8a71711126014c31df9c0e978a4d31ec0b4abf9dc7fe08f7&=
https://cdn.discordapp.com/attachments/791177690026606593/1507983994392805517/SnapInsta.to_564893339_18324949930240481_6308808904500180650_n.jpeg?ex=6a4c9389&is=6a4b4209&hm=f95eb2317464d34d9ba6d0b1ea175cb91d38283830a9564ec5d2cfe9f5f2425b&=
https://cdn.discordapp.com/attachments/791177690026606593/1506840331625168947/HG_1bZebEAAqBjm.png?ex=6a4c5eea&is=6a4b0d6a&hm=3ae61002c8d1fa416b11d0ca56982b2f0d55f3f9c083b0e88320d97098fa3adc&
https://cdn.discordapp.com/attachments/791177690026606593/1506840333022003230/HIyZoFXXoAA0hKZ.png?ex=6a4c5eeb&is=6a4b0d6b&hm=6a9e99c15b6eb9bf3c1444df6c234046142bc78d8e4990f3e22185aa0304de67&
https://cdn.discordapp.com/attachments/791177690026606593/1506882493754642512/Gp5wk0ZXEAAtijf.png?ex=6a4c862f&is=6a4b34af&hm=3c0fbd9d3f729ee48e0e74e85df6280043afeec545b553d99bb9c4280dcacf55&
https://cdn.discordapp.com/attachments/791177690026606593/1506999720172716052/image1.png?ex=6a4c4a9b&is=6a4af91b&hm=968bf339b5cfae67402dbd633764e08c87df8dda9f54b86062cf6181a3a4f6fc&
https://cdn.discordapp.com/attachments/791177690026606593/1507034237054750881/20260521_175517.jpg?ex=6a4c6ac1&is=6a4b1941&hm=6d11b7b734cfdfa0923473176935249e0682d34b5a3865808b36a548c44186b8&
https://cdn.discordapp.com/attachments/791177690026606593/1507097806345601196/RDT_20260521_1935211463465413898638515.jpg?ex=6a4ca5f5&is=6a4b5475&hm=fd3abff4e4e6f1e2969c5eb8475ecb5ae3936160772fb636a811ea8c88e9bde6&
https://cdn.discordapp.com/attachments/791177690026606593/1507113372334686362/HospitableFickleIrishterrier.mp4?ex=6a4c0bb4&is=6a4aba34&hm=60631b1c9e059e52bf4f0304f7252064567848437c69615b373eb635ca1612fc&
https://cdn.discordapp.com/attachments/791177690026606593/1507313886939054080/IMG_4797.jpg?ex=6a4c1db3&is=6a4acc33&hm=7f81d8de49d3f1ac58f6d77549bc3b74f9aae09e449ac9c7ba7a7163e7f4f021&
https://cdn.discordapp.com/attachments/791177690026606593/1507444023181185074/IMG_20260522_210333.jpg?ex=6a4c96e6&is=6a4b4566&hm=5470dc368f2cd7a8426ce82b2d672e3e1ca7305ea562e36fb798c40bc1818baa&
https://cdn.discordapp.com/attachments/791177690026606593/1507468398056181810/HIoPv-CWQAAkI_L.png?ex=6a4c04d9&is=6a4ab359&hm=68719021ec23c434413eb63f4c3533422391e65e3da7a301c2d2440f757d8b3a&
https://cdn.discordapp.com/attachments/791177690026606593/1507469042447945769/lHJCskJX.jpg?ex=6a4c0573&is=6a4ab3f3&hm=b4afb8f69f46815842e08aad0cee60b1f8fa6403404b8ce99ded3aa7c31d452f&
https://cdn.discordapp.com/attachments/791177690026606593/1507516786545922069/RDT_20260522_2353005935505195254235957.jpg?ex=6a4c31ea&is=6a4ae06a&hm=f2785a9ba2575911895bf6f2fe0ae65a1ecf50aea5f5136370863109b1c25aa1&
https://cdn.discordapp.com/attachments/791177690026606593/1507597945900367925/image.png?ex=6a4c7d80&is=6a4b2c00&hm=c6307dee95d772396ed2b3d3040cb75074ec6cb9ca4117560938b587cb1ee84f&
https://cdn.discordapp.com/attachments/791177690026606593/1507603086892335174/HI8NiXXWkAAsuCy.png?ex=6a4c8249&is=6a4b30c9&hm=2b60fa0da9dc9d8583d5267ef321ff5361f31026c2265a35c0cbd221a85c0132&
https://cdn.discordapp.com/attachments/791177690026606593/1507603534747668500/bpbuYHp1ZOyiIT4c.mp4?ex=6a4c82b4&is=6a4b3134&hm=335ef29d6431bf29114e3c16430f9faa55d9b3b5b31f9cf0f8704837b3079dbc&
https://cdn.discordapp.com/attachments/791177690026606593/1507605021016068286/HI8idW4WoAA8WdZ.png?ex=6a4c8416&is=6a4b3296&hm=3e9e0f9f0a4707af9c9dbdbf7465cb490e1ab535a08ec72534bfa79e520d42f1&
https://cdn.discordapp.com/attachments/791177690026606593/1507654405007216710/HIxaurkWoAAOO10.jfif?ex=6a4c0955&is=6a4ab7d5&hm=fff3d34b6d4358b1d87047bd57edba9df6e08e7972203442a806eadddc202e97&
https://cdn.discordapp.com/attachments/791177690026606593/1507654405456003152/HIDQvyFa8AAIN8U.jfif?ex=6a4c0955&is=6a4ab7d5&hm=59836e2a4ee2b115a74167ea6706835480e1a3a892103938c111df9feada8096&
https://cdn.discordapp.com/attachments/791177690026606593/1507654405791416430/HDEFP8pXQAE88oZ.jfif?ex=6a4c0955&is=6a4ab7d5&hm=02cdc5ee062e3943f711e055d514a63f9ce76e9dc5152311f43224b3ceb29a5c&
https://cdn.discordapp.com/attachments/791177690026606593/1507654406718492744/705547252_18442706143185655_7387661572250654873_n.jpg?ex=6a4c0955&is=6a4ab7d5&hm=fa22849e711a196c148bb80b72921f547e9b6393c43ea0ae26d6171d169603f5&
https://cdn.discordapp.com/attachments/791177690026606593/1507654407137919036/705365375_18442706152185655_3280616482195517036_n.jpg?ex=6a4c0955&is=6a4ab7d5&hm=aab32083aeaf1cadfc11f0a152532d0c24aaeb1de6045b2e85e5f5d25bca061e&
https://cdn.discordapp.com/attachments/791177690026606593/1507654407448428704/IMG_20260520_182703_199.jpg?ex=6a4c0955&is=6a4ab7d5&hm=a6ea9a518d3f1db6ae5e402022ffdcdbcc02a37d96c7894c2fcc1c1c305bd9fa&
https://cdn.discordapp.com/attachments/791177690026606593/1507654407834173441/IMG_20260520_182703_033.jpg?ex=6a4c0955&is=6a4ab7d5&hm=bee4a5d21de217b1b2f53ab6d8ad845cc10fa8db8e6245d20f927ac3fa223933&
https://cdn.discordapp.com/attachments/791177690026606593/1507654408182173786/20260329_160653.jpg?ex=6a4c0955&is=6a4ab7d5&hm=73e2c4a969e81c4a3ae4b39287d46967565c399245a43f4237d5f13767b98e7f&
https://cdn.discordapp.com/attachments/791177690026606593/1507654408622702592/GtQi82gXgAAWcID.png?ex=6a4c0955&is=6a4ab7d5&hm=b929649db565e836eb38c3a67724ff54dd45fd7192d750783ab960a7a37f0d03&
https://cdn.discordapp.com/attachments/791177690026606593/1507688881594830888/IMG_20260523_131408_523.jpg?ex=6a4c2970&is=6a4ad7f0&hm=61802a16628737c7acf2966ca8c30831646127d310284b2fbf732d4da47b9327&
https://cdn.discordapp.com/attachments/791177690026606593/1507693453629198406/x_3840p_20260523_113254.mp4?ex=6a4c2db2&is=6a4adc32&hm=8af469a1bed039092f0d6075cef899ee9a41ea300fcee657adda76d120cc63fc&
https://cdn.discordapp.com/attachments/791177690026606593/1507787586582745169/a37547d5-18d4-46b3-a83e-d8bc9093f7f7.png?ex=6a4c855d&is=6a4b33dd&hm=0c28fb8067201d0676d1037f3df6ce5c59cb90b23b0f220ac560fc83d1181126&
https://cdn.discordapp.com/attachments/791177690026606593/1507787587102834830/19c930f2-dbbb-4212-ac18-cc2523572c01.png?ex=6a4c855e&is=6a4b33de&hm=f015a983cd155e9838e727dc5df3cc021584d3750c6129a8bc06c08c51b1dc38&
https://cdn.discordapp.com/attachments/791177690026606593/1507787587534979152/cb92d321-dfc9-4157-831f-f170da69d118.png?ex=6a4c855e&is=6a4b33de&hm=d528702d799e2c9ae148c2560a149f7922f9a56c36e9ffa7425798c0feead08e&
https://cdn.discordapp.com/attachments/791177690026606593/1507787588302278848/ebc62726-7bc4-482c-a45b-11da82a4f13d.png?ex=6a4c855e&is=6a4b33de&hm=fd2675652beae626fa97273127a2f206c3f2ea30494ce049465691a36a0b4d12&
https://cdn.discordapp.com/attachments/791177690026606593/1507882850836287638/RDT_20260524_0006416295880426316812700.jpg?ex=6a4c3556&is=6a4ae3d6&hm=50e648e2eb07f7b9e7dab327195685370619d66c1a127a7460ab64227bb50127&
https://cdn.discordapp.com/attachments/791177690026606593/1505591341286162482/IMG_3038.webp?ex=6a4c70f4&is=6a4b1f74&hm=19f94d6f82618e7200ae776266a0b26b9b6b95e84b30ccec3967c185a87273f7&
https://cdn.discordapp.com/attachments/791177690026606593/1505710921430077591/oV6WX1lUjr.jpg?ex=6a4c3792&is=6a4ae612&hm=1463f146e598a1469046e684dfd9a8a57746c284acddb4c4257a613952400ce2&
https://cdn.discordapp.com/attachments/791177690026606593/1505710921765490709/giwH6wpnyM.jpg?ex=6a4c3792&is=6a4ae612&hm=5401c8da64fcc23db2b4f04677e6f87337fad4a2e26266695af18b957e4f81ae&
https://cdn.discordapp.com/attachments/791177690026606593/1505710922029600919/X6gbH68Qm3.jpg?ex=6a4c3792&is=6a4ae612&hm=efdc4c9d34d497e99a7c6b391bd4b38fb99f48a54b6754d0757661fe2b86f71a&
https://cdn.discordapp.com/attachments/791177690026606593/1505710922327658656/YQCiRYlIek.jpg?ex=6a4c3792&is=6a4ae612&hm=850a1d1825861ea3e8a1b84b0ada6a6c0ab603ee44c5572ea30b8ccefd3788d5&
https://cdn.discordapp.com/attachments/791177690026606593/1505710922671460443/HtPAK8D0Fm.jpg?ex=6a4c3792&is=6a4ae612&hm=3bfc3aa89834361715802328d0cb9495bb835d2f8846b33a2248a533ac9f1627&
https://cdn.discordapp.com/attachments/791177690026606593/1505710923011067944/6vcNnUpNeC.jpg?ex=6a4c3792&is=6a4ae612&hm=3b91ce80b08455be9f5e5c21dd8d75b9f2cf9efae20c53fc42f49e43874896f7&
https://cdn.discordapp.com/attachments/791177690026606593/1505710923342680124/ipug7unwaZ.jpg?ex=6a4c3792&is=6a4ae612&hm=115a38b800f3874869745557e9d95b50e0c04d66372362da816ea3b9737324b9&
https://cdn.discordapp.com/attachments/791177690026606593/1505710923741007912/RtzsZYfwC3.jpg?ex=6a4c3792&is=6a4ae612&hm=eb08b12fa4e0d7f91f15cdab75837c3ab010ab72aa6e75d4a3d9f31735d1e9f7&
https://cdn.discordapp.com/attachments/791177690026606593/1505710924076421220/aFuTxizD08.jpg?ex=6a4c3793&is=6a4ae613&hm=a46cee3c6a835eae011d45b20f4a6c0e4de4eb095e42d2a76603dabb4bd09ea8&
https://cdn.discordapp.com/attachments/791177690026606593/1505711006658068521/IMG_20260518_021559.jpg?ex=6a4c37a6&is=6a4ae626&hm=daa952fe0dd86130c6dbdbf29bdadf12a4682c3bcb010cc54fb7e6a4771862e3&
https://cdn.discordapp.com/attachments/791177690026606593/1505711006964518992/IMG_20260518_021546.jpg?ex=6a4c37a6&is=6a4ae626&hm=ecdf184996027a2bd6ba5a925a531ca24711656dd326404eedc3c462ec6d12d9&
https://cdn.discordapp.com/attachments/791177690026606593/1505711007337681056/IMG_20260518_021535.jpg?ex=6a4c37a6&is=6a4ae626&hm=19650524b80b2ac2af5053979a49ef03edfe77351397bb794bc483c215034ab3&
https://cdn.discordapp.com/attachments/791177690026606593/1505711007727882291/IMG_20260518_021521.jpg?ex=6a4c37a7&is=6a4ae627&hm=2d87eaa79022fe0e82a41cd1089475653313029c8cf6e54285c14e5f855d3881&
https://cdn.discordapp.com/attachments/791177690026606593/1505711008155566212/IMG_20260518_021507.jpg?ex=6a4c37a7&is=6a4ae627&hm=1d825847e8a6ef1dfa27145cb097a80baaabd3dae79b58129075d583958a2b41&
https://cdn.discordapp.com/attachments/791177690026606593/1505711008617074808/20260518_010559.jpg?ex=6a4c37a7&is=6a4ae627&hm=87f2e6d0d4fc29982bac1e3240950198ae021018a07ea1ced89843d2c0d7f571&
https://cdn.discordapp.com/attachments/791177690026606593/1505711008927191110/tmp-5183-1772563708983.jpg?ex=6a4c37a7&is=6a4ae627&hm=b55d2f43c5c2e3a34b56325214b25a5bf6d0c8eca06cc806ec89ab8506588480&
https://cdn.discordapp.com/attachments/791177690026606593/1505777686650290196/HIkaWRyaMAEdKO7.png?ex=6a4c75c0&is=6a4b2440&hm=76b77fe6a3bc6fa30e24d64ab76eabfa3a0f091c0704dc0c0ff059cf9c6cbcb6&
https://cdn.discordapp.com/attachments/791177690026606593/1505777687275376761/HIkaWRzbgAA1qaW.png?ex=6a4c75c0&is=6a4b2440&hm=ee4cc4c3868258884101730acb77921f7b6728fcefe9731af623539732a2107e&
https://cdn.discordapp.com/attachments/791177690026606593/1505870305363755128/Twitter_TinkyServer-2.jpg?ex=6a4c2342&is=6a4ad1c2&hm=8a8e508fb780c4f9e8f45c1ffaa6f37dd0e37a7e3fe61ab744a60007e28bec93&
https://cdn.discordapp.com/attachments/791177690026606593/1506016110267334848/IMG_3039.webp?ex=6a4cab0d&is=6a4b598d&hm=68c7e305b355fb4b7f22bc7701bc958ce9de8a28a552a0fbbdb87644cc29bdbb&
https://cdn.discordapp.com/attachments/791177690026606593/1506042901946175508/20250720_175518.jpg?ex=6a4c1b40&is=6a4ac9c0&hm=30d02453c816855653e92746a82afa5a5c2e3aded76250d5907b6da73df11a31&
https://cdn.discordapp.com/attachments/791177690026606593/1506143196906782822/HImZqXXbAAANdbl.png?ex=6a4c78a8&is=6a4b2728&hm=e82d3d1ec76523d2cecca4c2b3264df3ab25226cd23f6ade779e0b1aac8fcdb1&
https://cdn.discordapp.com/attachments/791177690026606593/1506143893471756380/mwaddeleine.mp4?ex=6a4c794f&is=6a4b27cf&hm=d63be34151e6501923ca72db8f3a14743fbff77e25e7ddd8d7be6df3296bd8be&
https://cdn.discordapp.com/attachments/791177690026606593/1506154117960044544/HArqdTGaQAAz_Se.png?ex=6a4c82d4&is=6a4b3154&hm=55ecfe3982cc38cf84d2f506d5e276671e5d3cd96bbddbe522d8fa2df0ac2572&
https://cdn.discordapp.com/attachments/791177690026606593/1506156066965164093/20260519_095628.jpg?ex=6a4c84a5&is=6a4b3325&hm=0f40e7059ae736ecf7cdd28ed60b64681b9d2e5cb9fc89e9c98e52f1ffd7a496&
https://cdn.discordapp.com/attachments/791177690026606593/1506171350216085586/IMG_3040.webp?ex=6a4c92e1&is=6a4b4161&hm=43ee0791e92cbc017347af1d1cbec685af02816432cd933767b8501487817536&
https://cdn.discordapp.com/attachments/791177690026606593/1506240134381572156/RDT_20260505_1459076201999101655027728.jpg?ex=6a4c2a30&is=6a4ad8b0&hm=4cbf7c529202cd5f9393a9569eb9d260069d0e9bd0d6893013d33a97eb9cbd13&
https://cdn.discordapp.com/attachments/791177690026606593/1506331524088336564/IMG_20260519_192323_919.jpg?ex=6a4c7f4d&is=6a4b2dcd&hm=badf0d5435bf1d406fcccb2d4ff3f20002d2cd89a77254bfe090b218f7dc5360&
https://cdn.discordapp.com/attachments/791177690026606593/1506333505477673010/c99dgr2G_1.jpeg?ex=6a4c8126&is=6a4b2fa6&hm=465c9cfaddf4b1d2100f01eada2322a6b6e744b2e3725175cf25e4474809c724&
https://cdn.discordapp.com/attachments/791177690026606593/1506529217305903104/IMG_20260520_132413_586.jpg?ex=6a4c8eab&is=6a4b3d2b&hm=562064723011c24c7da3206b4c073070b45ed242bd5889d8597c4a684b81789b&
https://cdn.discordapp.com/attachments/791177690026606593/1506529217800568942/IMG_20260520_132413_716.jpg?ex=6a4c8eab&is=6a4b3d2b&hm=1c94a134e8c794f86373378a00093c9b25c84996c645d48e3b8cf43782f96d3e&
https://cdn.discordapp.com/attachments/791177690026606593/1506539361498435584/HIu6WlcX0AAQscy.png?ex=6a4c981d&is=6a4b469d&hm=21ba757dd24a69f4950daa67a5e5c607904c0c03b7c3d6f506b65e49884580c0&
https://cdn.discordapp.com/attachments/791177690026606593/1506712398005014579/IMG_20260520_182703_033.jpg?ex=6a4c9085&is=6a4b3f05&hm=1fdd8d73f2e215cb6c9401c1e19184ad644ce7929f3081854f0c739f8cd088de&
https://cdn.discordapp.com/attachments/791177690026606593/1506712398445281280/IMG_20260520_182702_861.jpg?ex=6a4c9085&is=6a4b3f05&hm=cd2e2e1c8dec176f3ec2c0d68a5b33c255570a151b1e4d04c4fa60754c76c005&
https://cdn.discordapp.com/attachments/791177690026606593/1506712398956855396/IMG_20260520_182703_199.jpg?ex=6a4c9085&is=6a4b3f05&hm=00a19948d48a7939a254fd0b95c5e7e96b67cd9070549e393e05107802f5ee51&
https://cdn.discordapp.com/attachments/791177690026606593/1506717853800202320/IMG_20260520_205821_276.jpg?ex=6a4c9599&is=6a4b4419&hm=f5eb6b9e4531871c7ecf5bcb5b7abb91e6c7094ae31031bea531bfa51703eabd&
https://cdn.discordapp.com/attachments/1126557838316146738/1361742868619858061/29346997.gif?ex=6a4c831f&is=6a4b319f&hm=0b8e3564a8da7abc90719953954cb9a19153b3bf4fada307fed3ea61bf5cbbea&
https://cdn.discordapp.com/attachments/791177690026606593/1506840331625168947/HG_1bZebEAAqBjm.png?ex=6a4c5eea&is=6a4b0d6a&hm=3ae61002c8d1fa416b11d0ca56982b2f0d55f3f9c083b0e88320d97098fa3adc&=
https://cdn.discordapp.com/attachments/791177690026606593/1506840333022003230/HIyZoFXXoAA0hKZ.png?ex=6a4c5eeb&is=6a4b0d6b&hm=6a9e99c15b6eb9bf3c1444df6c234046142bc78d8e4990f3e22185aa0304de67&=
https://cdn.discordapp.com/attachments/791177690026606593/1506882493754642512/Gp5wk0ZXEAAtijf.png?ex=6a4c862f&is=6a4b34af&hm=3c0fbd9d3f729ee48e0e74e85df6280043afeec545b553d99bb9c4280dcacf55&=
https://cdn.discordapp.com/attachments/791177690026606593/1506999720172716052/image1.png?ex=6a4c4a9b&is=6a4af91b&hm=968bf339b5cfae67402dbd633764e08c87df8dda9f54b86062cf6181a3a4f6fc&=
https://cdn.discordapp.com/attachments/791177690026606593/1507787586582745169/a37547d5-18d4-46b3-a83e-d8bc9093f7f7.png?ex=6a4c855d&is=6a4b33dd&hm=0c28fb8067201d0676d1037f3df6ce5c59cb90b23b0f220ac560fc83d1181126&=
https://cdn.discordapp.com/attachments/791177690026606593/1507787587102834830/19c930f2-dbbb-4212-ac18-cc2523572c01.png?ex=6a4c855e&is=6a4b33de&hm=f015a983cd155e9838e727dc5df3cc021584d3750c6129a8bc06c08c51b1dc38&=
https://cdn.discordapp.com/attachments/791177690026606593/1507787587534979152/cb92d321-dfc9-4157-831f-f170da69d118.png?ex=6a4c855e&is=6a4b33de&hm=d528702d799e2c9ae148c2560a149f7922f9a56c36e9ffa7425798c0feead08e&=
https://cdn.discordapp.com/attachments/791177690026606593/1507787588302278848/ebc62726-7bc4-482c-a45b-11da82a4f13d.png?ex=6a4c855e&is=6a4b33de&hm=fd2675652beae626fa97273127a2f206c3f2ea30494ce049465691a36a0b4d12&=
https://cdn.discordapp.com/attachments/791177690026606593/1507882850836287638/RDT_20260524_0006416295880426316812700.jpg?ex=6a4c3556&is=6a4ae3d6&hm=50e648e2eb07f7b9e7dab327195685370619d66c1a127a7460ab64227bb50127&=
https://cdn.discordapp.com/attachments/791177690026606593/1505591341286162482/IMG_3038.webp?ex=6a4c70f4&is=6a4b1f74&hm=19f94d6f82618e7200ae776266a0b26b9b6b95e84b30ccec3967c185a87273f7&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710921430077591/oV6WX1lUjr.jpg?ex=6a4c3792&is=6a4ae612&hm=1463f146e598a1469046e684dfd9a8a57746c284acddb4c4257a613952400ce2&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710921765490709/giwH6wpnyM.jpg?ex=6a4c3792&is=6a4ae612&hm=5401c8da64fcc23db2b4f04677e6f87337fad4a2e26266695af18b957e4f81ae&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710922029600919/X6gbH68Qm3.jpg?ex=6a4c3792&is=6a4ae612&hm=efdc4c9d34d497e99a7c6b391bd4b38fb99f48a54b6754d0757661fe2b86f71a&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710922327658656/YQCiRYlIek.jpg?ex=6a4c3792&is=6a4ae612&hm=850a1d1825861ea3e8a1b84b0ada6a6c0ab603ee44c5572ea30b8ccefd3788d5&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710922671460443/HtPAK8D0Fm.jpg?ex=6a4c3792&is=6a4ae612&hm=3bfc3aa89834361715802328d0cb9495bb835d2f8846b33a2248a533ac9f1627&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710923011067944/6vcNnUpNeC.jpg?ex=6a4c3792&is=6a4ae612&hm=3b91ce80b08455be9f5e5c21dd8d75b9f2cf9efae20c53fc42f49e43874896f7&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710923342680124/ipug7unwaZ.jpg?ex=6a4c3792&is=6a4ae612&hm=115a38b800f3874869745557e9d95b50e0c04d66372362da816ea3b9737324b9&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710923741007912/RtzsZYfwC3.jpg?ex=6a4c3792&is=6a4ae612&hm=eb08b12fa4e0d7f91f15cdab75837c3ab010ab72aa6e75d4a3d9f31735d1e9f7&=
https://cdn.discordapp.com/attachments/791177690026606593/1505710924076421220/aFuTxizD08.jpg?ex=6a4c3793&is=6a4ae613&hm=a46cee3c6a835eae011d45b20f4a6c0e4de4eb095e42d2a76603dabb4bd09ea8&=
https://cdn.discordapp.com/attachments/791177690026606593/1506717853800202320/IMG_20260520_205821_276.jpg?ex=6a4c9599&is=6a4b4419&hm=f5eb6b9e4531871c7ecf5bcb5b7abb91e6c7094ae31031bea531bfa51703eabd&=
https://cdn.discordapp.com/attachments/1126557838316146738/1361742868619858061/29346997.gif?ex=6a4c831f&is=6a4b319f&hm=0b8e3564a8da7abc90719953954cb9a19153b3bf4fada307fed3ea61bf5cbbea&=
https://cdn.discordapp.com/attachments/791177690026606593/1504313523680055306/RDT_20260514_0543032098399376947677820.jpg?ex=6a4c6824&is=6a4b16a4&hm=497756e99eaec79792a43209b4707341891e0fedbffea833bee4d70120a184c1&
https://cdn.discordapp.com/attachments/791177690026606593/1504345061050286110/IMG_20260119_204132.jpg?ex=6a4c8583&is=6a4b3403&hm=51c74e8af993b02b46bcdd9a65723bc9f9c582f24b3cb695129852003bddf11e&
https://cdn.discordapp.com/attachments/791177690026606593/1504572046024114186/RDT_20260514_125153.mp4?ex=6a4c0769&is=6a4ab5e9&hm=6302bf1371f0b687958cd6e6fcff9f37b6d6fd993cac065f319cea265a594766&
https://cdn.discordapp.com/attachments/791177690026606593/1504700146636685343/im-actually-modest-v0-xama82b8f5of1.png?ex=6a4c7eb6&is=6a4b2d36&hm=3d05785499eda0a57ab4c09679c95040bf7fdd08c1e7ad40e5a331e0bfe10449&
https://cdn.discordapp.com/attachments/791177690026606593/1504895299481501716/IMG_20260514_123406_782.jpg?ex=6a4c8bb6&is=6a4b3a36&hm=237cb5da24be73d923668c4805f0eb4cf64d30631f3fd1dc541162e48f0ae0e1&
https://cdn.discordapp.com/attachments/791177690026606593/1504895299863318589/IMG_20260514_123408_590.jpg?ex=6a4c8bb7&is=6a4b3a37&hm=4d31df5e88319db83e43ee22c9ae8cb808d36ee8c9b5e9cb3ed7ad3e99858a2f&
https://cdn.discordapp.com/attachments/791177690026606593/1504988688323707010/7562423hg3213165h7565412432131.mp4?ex=6a4c39f0&is=6a4ae870&hm=fbfbf055770f303e6f842825100525c3d7055d8471a3f3aee1d7f5dfc035fc62&
https://cdn.discordapp.com/attachments/791177690026606593/1504988690118607119/7562423hg65h7565412432131.mp4?ex=6a4c39f1&is=6a4ae871&hm=0a125535527431e02edb64e2cb099654a636b975d6557e573bb20a59c3586a84&
https://cdn.discordapp.com/attachments/791177690026606593/1504988692576600185/7562423hg65h75654124.mp4?ex=6a4c39f1&is=6a4ae871&hm=726c0d3561e65ce5a9ede8cf041e0e458300f6adbb8a69ec6a98101debe34922&
https://cdn.discordapp.com/attachments/791177690026606593/1505024299847913544/1125a60b-c68c-4267-8d99-3afa11cdb40c.png?ex=6a4c5b1b&is=6a4b099b&hm=dfe643c9759ed5b22b37a01896971df5d50c517dd7a44dff261fc14774333c19&
https://cdn.discordapp.com/attachments/791177690026606593/1505060322040348863/image.png?ex=6a4c7ca7&is=6a4b2b27&hm=4742f12f288efcfc4196ec8da6d4daf39ca90380825f57da5b1b69877cd517e4&
https://cdn.discordapp.com/attachments/791177690026606593/1505115165861875822/RDT_20260515_2135285892430932823861986.jpg?ex=6a4c06fb&is=6a4ab57b&hm=7d93cd8230bba7df95a3ca1ee2f1e822abd6aa608d056abc1fd3bce4c288d009&
https://cdn.discordapp.com/attachments/791177690026606593/1505115166138830868/RDT_20260515_2135315756941957558858213.jpg?ex=6a4c06fb&is=6a4ab57b&hm=16c316ffc850b4ca712a37fa295cf3781dc4cbb776ec34a136222f64f39a3cf5&
https://cdn.discordapp.com/attachments/791177690026606593/1505115166491279390/RDT_20260515_213524541894662162505638.jpg?ex=6a4c06fb&is=6a4ab57b&hm=6b1fd1a3732728137ee45c6d3a4c0530a131b49f725590d6ed9f4def1ba27922&
https://cdn.discordapp.com/attachments/791177690026606593/1505140099887792319/Messenger_creation_6001399E-01C5-4DA7-AC16-17CBDB941645.mp4?ex=6a4c1e33&is=6a4accb3&hm=26223d65d1da7d893f8e71d1ad7d49ce5d5ff4297b8cc10130edce7cfc72493b&
https://cdn.discordapp.com/attachments/791177690026606593/1505175090004758679/P0F93WNi.jpg?ex=6a4c3eca&is=6a4aed4a&hm=c37f7d39f5582fa952aa2db204a3ec6ac1e159ed71d9589997e6a117f256e2fe&
https://cdn.discordapp.com/attachments/791177690026606593/1505175090307006634/RSupfvIP.jpg?ex=6a4c3eca&is=6a4aed4a&hm=bcead8428637f93d9089b194a44e21b6d2d7f92634745835e25d5a39aa8489c6&
https://cdn.discordapp.com/attachments/791177690026606593/1505175090634035210/NmXHR1I0.jpg?ex=6a4c3eca&is=6a4aed4a&hm=30fa6c841749fc61c84244698b200ec56565ab8922e73b75455dbe9410cd59bb&
https://cdn.discordapp.com/attachments/791177690026606593/1505218308725669938/image.png?ex=6a4c670a&is=6a4b158a&hm=050bf0c8a769f054256a928e8d9746450d3c3d06bef6c0312552907067e960e7&
https://cdn.discordapp.com/attachments/791177690026606593/1505229467017150545/d41d4c50-9e0c-48f6-af4c-ed5e0b1a971a.jpg?ex=6a4c716e&is=6a4b1fee&hm=212f556b2b3d9f7084f4ca8b375fab849c0d1d4a3272cc4511fa7fb6d8e76c6f&
https://cdn.discordapp.com/attachments/791177690026606593/1505338413564559360/20260517_012708.jpg?ex=6a4c2e25&is=6a4adca5&hm=ae681241f7ccb20d30bf69bdc3a10cab84182faf34ee273ef26a82d5dd17173a&
https://cdn.discordapp.com/attachments/791177690026606593/1505338413921079447/20260517_012710.jpg?ex=6a4c2e25&is=6a4adca5&hm=2238e19ca63b4c91390dd54a0576e6daf786797c50813795a6f2733cf1930f89&
https://cdn.discordapp.com/attachments/791177690026606593/1505338440097595495/20260517_012725.jpg?ex=6a4c2e2b&is=6a4adcab&hm=6b135ce7209ab4ff71e893d7e128d172510b86aeadb393ead55fadaa79dbdd46&
https://cdn.discordapp.com/attachments/791177690026606593/1505338440550584514/20260517_012724.jpg?ex=6a4c2e2c&is=6a4adcac&hm=35829ac930ff7ebed0eaa7f21dc086701dfbca56e3a2c21de0f02a1407520708&
https://cdn.discordapp.com/attachments/791177690026606593/1505338470971740321/20260517_012525.jpg?ex=6a4c2e33&is=6a4adcb3&hm=ecb81eef0b770512a120f842b839f3a67ee7d6f61af6e104105894ba9d1e2b6b&
https://cdn.discordapp.com/attachments/791177690026606593/1505338471303086181/20260517_012526.jpg?ex=6a4c2e33&is=6a4adcb3&hm=a438856d802cb29e40b118c4244e8939609a0cb37a256460a2ff0263f0b7b8d6&
https://cdn.discordapp.com/attachments/791177690026606593/1505338532531536003/x_720p_20260517_012501.mp4?ex=6a4c2e41&is=6a4adcc1&hm=873b6bd4161b764fee31f8f395cc42442c2e1b727854f706b1441733d3f083e8&
https://cdn.discordapp.com/attachments/791177690026606593/1505474684697841744/IMG_20260517_103811_478.jpg?ex=6a4cad0f&is=6a4b5b8f&hm=2665c534d99acec847f7ea40846d6fde14a87d8dbaa1b80a8420574c954bc56c&
https://cdn.discordapp.com/attachments/791177690026606593/1505482768790851744/1779005439124076.mov?ex=6a4c0bd6&is=6a4aba56&hm=242f9ba1f84df5a6af78af53c73733abc7ca40d2d133adbb9c91312cf76381f3&
https://cdn.discordapp.com/attachments/791177690026606593/1505482770493866074/-7710495306878806426.mp4?ex=6a4c0bd7&is=6a4aba57&hm=d973acb7526e02f5f64e6ce1bfc923a9850ca3b824d6994f85a1842652dfc4bc&
https://cdn.discordapp.com/attachments/791177690026606593/1504313523680055306/RDT_20260514_0543032098399376947677820.jpg?ex=6a4c6824&is=6a4b16a4&hm=497756e99eaec79792a43209b4707341891e0fedbffea833bee4d70120a184c1&=
https://cdn.discordapp.com/attachments/791177690026606593/1504345061050286110/IMG_20260119_204132.jpg?ex=6a4c8583&is=6a4b3403&hm=51c74e8af993b02b46bcdd9a65723bc9f9c582f24b3cb695129852003bddf11e&=
https://cdn.discordapp.com/attachments/791177690026606593/1505338470971740321/20260517_012525.jpg?ex=6a4c2e33&is=6a4adcb3&hm=ecb81eef0b770512a120f842b839f3a67ee7d6f61af6e104105894ba9d1e2b6b&=
https://cdn.discordapp.com/attachments/791177690026606593/1505338471303086181/20260517_012526.jpg?ex=6a4c2e33&is=6a4adcb3&hm=a438856d802cb29e40b118c4244e8939609a0cb37a256460a2ff0263f0b7b8d6&=
https://cdn.discordapp.com/attachments/791177690026606593/1505474684697841744/IMG_20260517_103811_478.jpg?ex=6a4cad0f&is=6a4b5b8f&hm=2665c534d99acec847f7ea40846d6fde14a87d8dbaa1b80a8420574c954bc56c&=
https://cdn.discordapp.com/attachments/791177690026606593/1502806389779599413/redvid_io_1778280981.mp4?ex=6a4c3284&is=6a4ae104&hm=f8e596fad2f3b9b3e59e5a77c4af562fdc231496e71c9a7bad18c54205ab82c7&
https://cdn.discordapp.com/attachments/791177690026606593/1502822872186490942/cant-stop-stroking-my-huge-cock-to-thick-goths-v0-g053a0g1jj3d1.jpg.webp?ex=6a4c41dd&is=6a4af05d&hm=851ce0bc76aa5dee873bb6fbfb19ab57ec9e337e54bb94b1fa9c811759ce8a2e&
https://cdn.discordapp.com/attachments/791177690026606593/1502968714553983107/Screenshot_20260510-035621.png?ex=6a4c20f1&is=6a4acf71&hm=81a19d901cc4de517c61a9c3417f4133bfe90d58332e39b0afb6f4a89c27f610&
https://cdn.discordapp.com/attachments/791177690026606593/1502968729120800858/Screenshot_20260510-035249.png?ex=6a4c20f4&is=6a4acf74&hm=79fe0fb1f33591236d198e17dc46bffd46671c4f57144d4fb6bbb228a1b69922&
https://cdn.discordapp.com/attachments/791177690026606593/1503073801997647932/image.png?ex=6a4c82d0&is=6a4b3150&hm=1e5d7bca6ccbe2d2bc9cc700e546e3b8eb3ea212d483eb4938cc0f28b19ba154&
https://cdn.discordapp.com/attachments/791177690026606593/1503073802622603523/image.png?ex=6a4c82d0&is=6a4b3150&hm=9a86ab4b8fe24e79cd11ac72f64d356cbb4c0675a5001465e89ec344e9a80688&
https://cdn.discordapp.com/attachments/791177690026606593/1503089845495660564/spit_1.mp4?ex=6a4c91c1&is=6a4b4041&hm=90c00a7ecb06472bd34a48bc1f16af72d0f4fed90b22fde8be4dd501c0a5c129&
https://cdn.discordapp.com/attachments/791177690026606593/1503123978859057282/photo_4_2026-05-10_22-54-59.jpg?ex=6a4c08cb&is=6a4ab74b&hm=85c5fd2abc73f1f142648ceaf24b5cd98ba5ca496b7d0ecbdfbd952ec9905609&
https://cdn.discordapp.com/attachments/791177690026606593/1503374020379148369/VID_20260511_152949_427.mp4?ex=6a4c48e9&is=6a4af769&hm=f7fbb49c95c13646b420f6c58ac7d218f7449ef9d4ac950c0ec8d104e8412383&
https://cdn.discordapp.com/attachments/791177690026606593/1503414636823842897/image.png?ex=6a4c6ebd&is=6a4b1d3d&hm=ec605c602b380ec76678fabd4484184c2be7885470051f7967ee860183548784&
https://cdn.discordapp.com/attachments/791177690026606593/1503463119203336323/9924df03-0da4-41df-a236-b609dc0e08e5.jpg?ex=6a4c9be4&is=6a4b4a64&hm=b67ecf3bb86e256aab61589177300c75e585a4267bca42661f40b93b78db5461&
https://cdn.discordapp.com/attachments/791177690026606593/1503548727816618135/VID_20260512_030245_800.mp4?ex=6a4c42df&is=6a4af15f&hm=e087dd2cb21e0f5e1fb4c250a86da00de4c61f2a45e7cc72512923667f2620c5&
https://cdn.discordapp.com/attachments/791177690026606593/1503569796757979317/Big_Tits_Boobs_Tits_Porn_Gif_by_prettyjaydee_RedGIFs.mp4?ex=6a4c567e&is=6a4b04fe&hm=556e88849ff621ae9ad3b76aa5d896fe4ca13ec2de1291c076ab8c220bdf6343&
https://cdn.discordapp.com/attachments/791177690026606593/1503713884379549808/1000048039.mp4?ex=6a4c33ef&is=6a4ae26f&hm=8cc63598739745272cdd12ecd53356511a673913abd658839d237a86c3b0c28c&
https://cdn.discordapp.com/attachments/791177690026606593/1503721885160968272/RDT_20240221_2215330.mp4?ex=6a4c3b63&is=6a4ae9e3&hm=baf6cdad4bd91b8d49369434c0b4101713157fd111f7e31067d1a4c865266d23&
https://cdn.discordapp.com/attachments/791177690026606593/1503777627159134300/HHLMv2uagAAXCNG.png?ex=6a4c6f4d&is=6a4b1dcd&hm=8ca1a72ef3957dc2c5baf3df000acf478fe1d6d87e8404b1a4e895301e697f38&
https://cdn.discordapp.com/attachments/791177690026606593/1503813901975027942/IMG_0787.jpeg?ex=6a4c9115&is=6a4b3f95&hm=c7cc47020a3eeaaa42d366c21b47b0b94684146c21d4e07578104c87884a03c9&
https://cdn.discordapp.com/attachments/791177690026606593/1503873691795066961/IMG_0788.jpeg?ex=6a4c2004&is=6a4ace84&hm=6beadc3ad81cc4061675ab44b26125cdeb43d57c7f7c962807b93ee16a642534&
https://cdn.discordapp.com/attachments/791177690026606593/1503995729746726933/1_4.png?ex=6a4c91ac&is=6a4b402c&hm=2a4e84a33416edd286bef41cfdfa0053b2090906a475bbb37f25ebfeace72183&
https://cdn.discordapp.com/attachments/791177690026606593/1504233477308940339/image.png?ex=6a4c1d98&is=6a4acc18&hm=81ba0a6223fc7625be745298a13545a18edcc552c93cd9e6e75f92efe321d8f7&
https://cdn.discordapp.com/attachments/791177690026606593/1501235103807045662/IMG_20260505_175123_963.jpg?ex=6a4c69e4&is=6a4b1864&hm=7f65fa28119455566edac0d8a8ef9dd8331e3bd3da8d964a04fb3f3a11e828fd&
https://cdn.discordapp.com/attachments/791177690026606593/1501235104150982686/IMG_20260505_175128_326.jpg?ex=6a4c69e4&is=6a4b1864&hm=e194a1010d87d76deee574e35bb9e07fa5023737bb2d6eb312ef7c22b348e462&
https://cdn.discordapp.com/attachments/791177690026606593/1312432659414126632/db7066125a18ebf94cc05cf46bda7b2e.gif?ex=6a4c6b69&is=6a4b19e9&hm=e429116ea9e7b15770cc301fd8db217a569597cc34a05fa7625bb84a052a9980&
https://cdn.discordapp.com/attachments/791177690026606593/1501371679249666130/RDT_20260505_1459076201999101655027728.jpg?ex=6a4c4056&is=6a4aeed6&hm=f3076a0a235abefedc354314471c38e81e0b080029504537b29d72c729949ee9&
https://cdn.discordapp.com/attachments/1315875779388637184/1420449184238276619/3qzu5aynxilf1.gif?ex=6a4c82a4&is=6a4b3124&hm=1530b13c7b7779cdbc87b2cf89076f7e6a645fc9a3e4075aea5255e877a9a724&
https://cdn.discordapp.com/attachments/1368713454474756256/1416580188338126848/29561300.gif?ex=6a4c471b&is=6a4af59b&hm=76fe24f69b7590e0733aa343c851bc1f1b735f5f96f07ffa4f931a8e31742386&
https://cdn.discordapp.com/attachments/791177690026606593/1501648418399977724/1777861033489182.mp4?ex=6a4c9952&is=6a4b47d2&hm=5ebd079cc596f3c9eaaadf6553269c50997d3faff999c8aa88115f6c5b451b7c&
https://cdn.discordapp.com/attachments/791177690026606593/1501648471319384104/1777857404927396.webm?ex=6a4c995e&is=6a4b47de&hm=f9cd56cb12b1199b920697ec53070d2e344e470befc7d52c4cb51492afb97990&
https://cdn.discordapp.com/attachments/791177690026606593/1501772128930762762/RDT_20260506_09522767644174595841923.jpg?ex=6a4c63c9&is=6a4b1249&hm=7503ba7100d00d042cbf24d372c6e6db15305b84114b6531f0cc7f7b2d6f7098&
https://cdn.discordapp.com/attachments/791177690026606593/1501780144745087048/VID_20260507_085550.mp4?ex=6a4c6b40&is=6a4b19c0&hm=f950940a95e786e5da0476f8415db68aa60a7fdac3b80f4670b0896060b8cb73&
https://cdn.discordapp.com/attachments/791177690026606593/1501952010021240922/VbD4iRYF_720p.mp4?ex=6a4c6290&is=6a4b1110&hm=da7c5ec83077a91476ab232bcae97519f50da675709e44d8c016bebd73843f1a&
https://cdn.discordapp.com/attachments/791177690026606593/1502004494047772692/video_2023-04-26_12-42-58.mp4?ex=6a4c9371&is=6a4b41f1&hm=198455594507c59bdd13a9cab25650ea3932857277f3556b52489e3048a383ae&
https://cdn.discordapp.com/attachments/1407825659761262613/1407828499242287286/17nlvu6skioe1.gif?ex=6a4c1476&is=6a4ac2f6&hm=797ed71f53c3f9f523fca91907abf0bf511ec4990bd2229cf161637bede0837e&
https://cdn.discordapp.com/attachments/791177690026606593/1502199676856832160/tweeload_xqv43s35.mp4?ex=6a4ca078&is=6a4b4ef8&hm=4892a0ad545db737c1b8b5569c4349ad2d04581d02a6ce613e35709094e9afe9&
https://cdn.discordapp.com/attachments/791177690026606593/1502328095477072003/20260508_181149.jpg?ex=6a4c6f51&is=6a4b1dd1&hm=e5d4b7d69735bdff15b61cde5876f346a4361bc74873fa667a668d62f84a1dfe&
https://cdn.discordapp.com/attachments/791177690026606593/1502328096261538045/20260508_180959.jpg?ex=6a4c6f52&is=6a4b1dd2&hm=e353ae2c8ef9de5c576c80f1556056a97bfd36d3b60ee12f928e99b1f4921bca&
https://cdn.discordapp.com/attachments/791177690026606593/1502328097087946945/20260508_180950.jpg?ex=6a4c6f52&is=6a4b1dd2&hm=0a1b00da522c9ae367ce3f7c7b3383f89dcbd70dde2da441257829d3350b0206&
https://cdn.discordapp.com/attachments/791177690026606593/1502328097624555622/20260508_180957.jpg?ex=6a4c6f52&is=6a4b1dd2&hm=162990d65e280d8804a402d11d608aba19dc61ff55a17394f8dcde1dffc03205&
https://cdn.discordapp.com/attachments/791177690026606593/1502381322838999180/IMG_20260508_193756_380.jpg?ex=6a4ca0e4&is=6a4b4f64&hm=54d36ac341e2509c08bec0f2b8b37ef6d5c51d4f334cc856860ed0168181ffd8&
https://cdn.discordapp.com/attachments/791177690026606593/1502663199068131539/image0.jpg?ex=6a4c55e8&is=6a4b0468&hm=9a83ee8b5ed2fe8b9a3793a3c2e9e44d97adff5c81484e18525c84daeeeaa251&
https://cdn.discordapp.com/attachments/791177690026606593/1502806297966411868/StunningEasyTurtle.mp4?ex=6a4c326e&is=6a4ae0ee&hm=8b73e8bbfe840e3172d692c1f9eb40f1ec3b6d427811431101fa6ec96da6e32c&
https://cdn.discordapp.com/attachments/791177690026606593/1502806298893353000/RotatingOrchidFairyfly.mp4?ex=6a4c326e&is=6a4ae0ee&hm=5bd542d11fe7b2e1e2d386188172a93b84830e276db932bf4accd02edd906acb&
https://cdn.discordapp.com/attachments/791177690026606593/1502806299849523301/SimpleTepidAmethystsunbird.mp4?ex=6a4c326e&is=6a4ae0ee&hm=3ce10cb5c7f48f79bb8ffb051133108ac525e0b1300b51e03622bdb972dc0c73&
https://cdn.discordapp.com/attachments/791177690026606593/1502806300692844686/SlowDizzyKite.mp4?ex=6a4c326e&is=6a4ae0ee&hm=2ba0d16f2ea9ffd69a0bf921364e4d433aedc8df7ff73870a56c01c87d163575&
https://cdn.discordapp.com/attachments/791177690026606593/1502806301523312720/CurvyDirectWatermoccasin.mp4?ex=6a4c326f&is=6a4ae0ef&hm=6d115d3baba2dc246b3788adff752dd96208573059a8e6d398e8affdbbadc031&
https://cdn.discordapp.com/attachments/791177690026606593/1502806302462709952/RealisticMediumslatebluePlainsqueaker.mp4?ex=6a4c326f&is=6a4ae0ef&hm=0d4c2e246eb815bd0796266ee0a05dfc9e65b9a9983a77da2687b2e19fc5e12c&
https://cdn.discordapp.com/attachments/791177690026606593/1502806303817597031/InsidiousPastNeedletail.mp4?ex=6a4c326f&is=6a4ae0ef&hm=476bfbaabad9a95a7a032c6279483d452bc38a47e5dbb39a2e0dc4be4398a82b&
https://cdn.discordapp.com/attachments/791177690026606593/1502806305075888138/ImpossibleEnergeticBantamrooster.mp4?ex=6a4c326f&is=6a4ae0ef&hm=60dc81626a10a2fadb481f3581001c3c75a9c764b25d86bfcfa8477458786c4b&
https://cdn.discordapp.com/attachments/791177690026606593/1502806345445933197/OldfashionedWindyRacer.mp4?ex=6a4c3279&is=6a4ae0f9&hm=b25ed964f01bf13205e1d25b6606cd95931f973fcd7fce9b158b453c6251dfea&
https://cdn.discordapp.com/attachments/791177690026606593/1502822872186490942/cant-stop-stroking-my-huge-cock-to-thick-goths-v0-g053a0g1jj3d1.jpg.webp?ex=6a4c41dd&is=6a4af05d&hm=851ce0bc76aa5dee873bb6fbfb19ab57ec9e337e54bb94b1fa9c811759ce8a2e&=
https://cdn.discordapp.com/attachments/791177690026606593/1502968714553983107/Screenshot_20260510-035621.png?ex=6a4c20f1&is=6a4acf71&hm=81a19d901cc4de517c61a9c3417f4133bfe90d58332e39b0afb6f4a89c27f610&=
https://cdn.discordapp.com/attachments/791177690026606593/1503995729746726933/1_4.png?ex=6a4c91ac&is=6a4b402c&hm=2a4e84a33416edd286bef41cfdfa0053b2090906a475bbb37f25ebfeace72183&=
https://cdn.discordapp.com/attachments/791177690026606593/1504233477308940339/image.png?ex=6a4c1d98&is=6a4acc18&hm=81ba0a6223fc7625be745298a13545a18edcc552c93cd9e6e75f92efe321d8f7&=
https://cdn.discordapp.com/attachments/791177690026606593/1501235103807045662/IMG_20260505_175123_963.jpg?ex=6a4c69e4&is=6a4b1864&hm=7f65fa28119455566edac0d8a8ef9dd8331e3bd3da8d964a04fb3f3a11e828fd&=
https://cdn.discordapp.com/attachments/791177690026606593/1501235104150982686/IMG_20260505_175128_326.jpg?ex=6a4c69e4&is=6a4b1864&hm=e194a1010d87d76deee574e35bb9e07fa5023737bb2d6eb312ef7c22b348e462&=
https://cdn.discordapp.com/attachments/791177690026606593/1312432659414126632/db7066125a18ebf94cc05cf46bda7b2e.gif?ex=6a4c6b69&is=6a4b19e9&hm=e429116ea9e7b15770cc301fd8db217a569597cc34a05fa7625bb84a052a9980&=
https://cdn.discordapp.com/attachments/791177690026606593/1501371679249666130/RDT_20260505_1459076201999101655027728.jpg?ex=6a4c4056&is=6a4aeed6&hm=f3076a0a235abefedc354314471c38e81e0b080029504537b29d72c729949ee9&=
https://cdn.discordapp.com/attachments/791177690026606593/1502663199068131539/image0.jpg?ex=6a4c55e8&is=6a4b0468&hm=9a83ee8b5ed2fe8b9a3793a3c2e9e44d97adff5c81484e18525c84daeeeaa251&=
https://cdn.discordapp.com/attachments/791177690026606593/1502677691323646143/image-2.png?ex=6a4c6368&is=6a4b11e8&hm=99cb3daec697deffb49b1961a757b9e4f63bec8f5e50185d6523f64dd6612043&=
https://cdn.discordapp.com/attachments/791177690026606593/1499505288288669868/f1226ae5d83e5cd5.MP4?ex=6a4c0da0&is=6a4abc20&hm=fb2bab2bc5785845ba6d2949893ec9b7e56feee168e7bc699aba7eed1e6cf8cb&
https://cdn.discordapp.com/attachments/791177690026606593/1499505290146746441/770084fa4da76209.MOV?ex=6a4c0da0&is=6a4abc20&hm=fe16b3cacce9ffe54c040f002580230258d313306ac117f1c4871aa8948c3a82&
https://cdn.discordapp.com/attachments/791177690026606593/1499506074867339374/horny-angles-for-your-boner-v0-jp7cu4yr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=8d2f69fd06f287096b7d07d65bb54cca085354d1440857dd06ca6aa47ec3f758&
https://cdn.discordapp.com/attachments/791177690026606593/1499506075337097277/horny-angles-for-your-boner-v0-gfq7rryr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=daff5d5930b5d2e0d9869614d7ec31c2d056a93fd8814e3bf0ad0c762b3bb1e4&
https://cdn.discordapp.com/attachments/791177690026606593/1499506075718914079/horny-angles-for-your-boner-v0-hkjzi5yr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=6213d6d1e99c308f1263cec7dc98dff1d26ca003af08d4922f1bcfe39cf9d30c&
https://cdn.discordapp.com/attachments/791177690026606593/1499506076087881964/horny-angles-for-your-boner-v0-myex66yr19yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=954e426fb0854a8f807639966f1f9b013a8ae2e0c90e5ecf5af496b2ddece82e&
https://cdn.discordapp.com/attachments/791177690026606593/1499506076456976405/horny-angles-for-your-boner-v0-8o71tt3229yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=12f3d7d94f8d732e424535995010219deaf6c135428d22e4684d9993ec4217e3&
https://cdn.discordapp.com/attachments/791177690026606593/1499506076851376188/horny-angles-for-your-boner-v0-lcwl8xl229yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=452583f80d7812668c2442d1e025882503c624038e29092effe29ef6e1c5f0b8&
https://cdn.discordapp.com/attachments/791177690026606593/1499555558271746148/HHMCYFyb0AAL7s0.png?ex=6a4c3c71&is=6a4aeaf1&hm=659e9455d98d1187b8c4bb3cc4ebce02a3e15a3015a221a2fa3f340f43b0a1de&
https://cdn.discordapp.com/attachments/791177690026606593/1499590602621456454/4rv98XjON3pPYiE7.mp4?ex=6a4c5d14&is=6a4b0b94&hm=b255214e8514b31f46c25a9b7d2eda6555184175316bf192c2286b07efcd935a&
https://cdn.discordapp.com/attachments/791177690026606593/1499713880916754503/XNXX_fucking_my_hot_goth_roommate_SD.mp4?ex=6a4c2724&is=6a4ad5a4&hm=1def242c67fe2cfa8c8d25edc7094df788d3073c93c63ae31aae2856b4937f89&
https://cdn.discordapp.com/attachments/791177690026606593/1499794758594461837/IMG_9171.jpeg?ex=6a4c7277&is=6a4b20f7&hm=cc534af679b41b2041f30a01ab06ed4864e03d07bb5a31306f2540daea5c9332&
https://cdn.discordapp.com/attachments/791177690026606593/1499834233227841617/image.png?ex=6a4c973a&is=6a4b45ba&hm=0605af39a600f03e998fa5c3717f274b0d4a5e6839698afaccd2f65184a54d24&
https://cdn.discordapp.com/attachments/791177690026606593/1499877375121428520/1777668937301190.mp4?ex=6a4c16a8&is=6a4ac528&hm=c0e820fde0be30f55982e1bc3ffdb5452d60f4353d1e354f6302268d8665b688&
https://cdn.discordapp.com/attachments/791177690026606593/1499933721472532551/IMG_20260430_184643_654.jpg?ex=6a4c4b22&is=6a4af9a2&hm=07d1e9f96209bfd126f8fee9bb820e76a53d1716c6490cd377180e8b9df56b7f&
https://cdn.discordapp.com/attachments/791177690026606593/1500095027995611246/IMG_20260430_184637_697.jpg?ex=6a4c389d&is=6a4ae71d&hm=5f57b6e872b7099412d5f55253331003705213f7dd55fe6bc89591ae69953317&
https://cdn.discordapp.com/attachments/791177690026606593/1500214822199890140/G3uT3qHXEAAhID2.png?ex=6a4ca82e&is=6a4b56ae&hm=2e5ce57fc044a8aef8702213c3d76c649916be2a3352d35f30a4153cb3332fea&
https://cdn.discordapp.com/attachments/791177690026606593/1500214822761922580/G4InfbJW8AAiTzX.png?ex=6a4ca82e&is=6a4b56ae&hm=d85caaa09d8551c57f2591c9cc7ce26ba7e63d2d811e6eddf417ad9e04cefe20&
https://cdn.discordapp.com/attachments/791177690026606593/1500214823357780172/G5CPEGPbIAUCSnN.png?ex=6a4ca82e&is=6a4b56ae&hm=81bfa80a3941129c46f2424614a3d584e784d1ecf134a187cddb9d6a5a8b3b14&
https://cdn.discordapp.com/attachments/791177690026606593/1500214823986790614/G014XpdaYAEbJ4w.png?ex=6a4ca82e&is=6a4b56ae&hm=6f0d17c518bbb02c8839e9965f876567b9e1402de47e360efb2e9236b3a23e92&
https://cdn.discordapp.com/attachments/791177690026606593/1500214824779386920/G014XpnbEAAo-el.png?ex=6a4ca82e&is=6a4b56ae&hm=14ca833601e4282ca47e57dc226edd87f34d06e707e2f26d0af9857f4c7763da&
https://cdn.discordapp.com/attachments/791177690026606593/1500214825408528576/Gyp8a56acAM5tP0.png?ex=6a4ca82f&is=6a4b56af&hm=8e995afaab5f2ef507a32247c32ecb0840d439cda6e3b764b044e2813ea64ab0&
https://cdn.discordapp.com/attachments/791177690026606593/1500232592765485077/IMG_20260502_175137_038.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=0aa96319a220964ee04900a3e86374c6aee2934d596f4ea7e6abb420c433696f&
https://cdn.discordapp.com/attachments/791177690026606593/1500232593096966255/IMG_20260502_175034_187.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=dcbcde982c812876761579ff2acfa975c7cd017faaada2628953b681a21678d7&
https://cdn.discordapp.com/attachments/791177690026606593/1500232593629777950/IMG_20260502_175015_552.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=4484fea5bb1bbebb5f22ddafb0a9375878e76fe574de862538e86f5d441932e8&
https://cdn.discordapp.com/attachments/791177690026606593/1500232593998741616/IMG_20260502_175031_169.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=216c73d83606aa480708c9fcc470210b5ce2c938d67044609e67561a673dbd03&
https://cdn.discordapp.com/attachments/791177690026606593/1500232594275438674/IMG_20260502_175010_828.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=30c3e197ebf87776e925b550fc9f425f9fc3cf4e6fd99c6d033547c188fa02b6&
https://cdn.discordapp.com/attachments/791177690026606593/1500232594619502643/IMG_20260502_175022_127.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=281d8e5fc32bd4cd244afe9343f6dfaacc5ad88d1121af9b577c4ad24a26447a&
https://cdn.discordapp.com/attachments/791177690026606593/1500232594976145521/IMG_20260502_175121_474.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=467f9bfa6987d546459065c961252e6080a6634fe46582f5bc5d35f3a49168b7&
https://cdn.discordapp.com/attachments/791177690026606593/1500232595345248357/IMG_20260502_174939_545.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=a0ed5b4b07c3e7f536d1278746b6e5f58504575200456de10dc227f708451fc7&
https://cdn.discordapp.com/attachments/791177690026606593/1500232595714211860/IMG_20260502_170805_851.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=3eeb4e59cb3b2ede4860dc2d38188ffa3cfb1617d6b31172af11569350f7ba40&
https://cdn.discordapp.com/attachments/791177690026606593/1500232596066402375/IMG_20260502_170756_146.jpg?ex=6a4c0ffb&is=6a4abe7b&hm=8d2e685379b2782d8160042052b8d18159ed25ea97c303297290aa3ac99cb100&
https://cdn.discordapp.com/attachments/791177690026606593/1500446245137813534/SE-Upload_70ZH0M5ESM5PA1J.mov?ex=6a4c2e35&is=6a4adcb5&hm=613aed36575948927777b13b1d157e6d4a99805ef918cbfa5c23ee42cef95d2f&
https://cdn.discordapp.com/attachments/791177690026606593/1500461803111714977/bj.mp4?ex=6a4c3cb3&is=6a4aeb33&hm=f7d9c89bbf5b3f04442e3a14c4e84badd94a1b63fc18c1f61a43f0a7da3b5626&
https://cdn.discordapp.com/attachments/791177690026606593/1500612844847235123/spit_1.mp4?ex=6a4c209e&is=6a4acf1e&hm=b0044944245062a669da10c2ea6c0c682ee56273995e0c6e8cfbb91bacabd7a5&
https://cdn.discordapp.com/attachments/791177690026606593/1500632354413351043/IMG_20260503_132200_800.jpg?ex=6a4c32c9&is=6a4ae149&hm=52c0b0860e70badd954f1abb5c199a173406eb91a36123d8fe9d3ef942eddf0e&
https://cdn.discordapp.com/attachments/791177690026606593/1500965948364951593/G9mi_QbXYAAVY8v.png?ex=6a4c17f8&is=6a4ac678&hm=88bae83d3043a046ecce28463fac4dff22383a97407157bd050904394410cff7&
https://cdn.discordapp.com/attachments/791177690026606593/1500965948364951593/G9mi_QbXYAAVY8v.png?ex=6a4c17f8&is=6a4ac678&hm=88bae83d3043a046ecce28463fac4dff22383a97407157bd050904394410cff7&=
https://cdn.discordapp.com/attachments/1283067979931844620/1387492066119913552/4994BCB3-5D49-4F91-ABDA-73E5BF2A61FE.gif?ex=6a4c956e&is=6a4b43ee&hm=b8caf2fb64fcc95956051eec5775b8fc7f4862d0647c1504c2a2d5b1ad0b4129&
https://cdn.discordapp.com/attachments/1283067979931844620/1387492066119913552/4994BCB3-5D49-4F91-ABDA-73E5BF2A61FE.gif?ex=6a4c956e&is=6a4b43ee&hm=b8caf2fb64fcc95956051eec5775b8fc7f4862d0647c1504c2a2d5b1ad0b4129&=
https://cdn.discordapp.com/attachments/791177690026606593/1501180588823150682/Screenshot_2026-05-05-13-15-05-365_com.facebook.orca-edit.jpg?ex=6a4c371e&is=6a4ae59e&hm=7acdffabeed341e2a93e595096c3b55f35ec2fae4243f6cb119bc0b06639c9a3&
https://cdn.discordapp.com/attachments/791177690026606593/1501180588823150682/Screenshot_2026-05-05-13-15-05-365_com.facebook.orca-edit.jpg?ex=6a4c371e&is=6a4ae59e&hm=7acdffabeed341e2a93e595096c3b55f35ec2fae4243f6cb119bc0b06639c9a3&=
https://cdn.discordapp.com/attachments/791177690026606593/1497647768628629574/ssstwitter.com_1777137435281.mp4?ex=6a4c8bec&is=6a4b3a6c&hm=ca540bb744f10f6dbdfe120121856f232d0165a9306fcd81837b53a80a362434&
https://cdn.discordapp.com/attachments/791177690026606593/1497647769224085534/ssstwitter.com_1777137423132.mp4?ex=6a4c8bed&is=6a4b3a6d&hm=ae32cf946bc3c3631a7242605394648d5ed75f31ed61d58ac4449f26b351826c&
https://cdn.discordapp.com/attachments/791177690026606593/1497647991337652295/ssstwitter.com_1777137491385.mp4?ex=6a4c8c22&is=6a4b3aa2&hm=b1ac075012ae95f4ce8e4bb184665af1d44141fe5438064ff2a91fef974d8dca&
https://cdn.discordapp.com/attachments/791177690026606593/1497663616231674038/Zrzut_ekranu_2026-04-25_201730.png?ex=6a4c9aaf&is=6a4b492f&hm=4df4afd647d4ed09a421e1386eecd5869486cef2cd224c482fdb4df6c2a914b2&
https://cdn.discordapp.com/attachments/791177690026606593/1497684421669556234/Petite_Argentina_emo_chupando_pija_alt_slut_blowjob_2.mp4?ex=6a4c054f&is=6a4ab3cf&hm=f0cd10d18d622ecd96dbb7efaa7ca4617c25ec87652c7d8aea0f419918e19c4d&
https://cdn.discordapp.com/attachments/791177690026606593/1497781130852827166/HappygoluckySquareBasenji.mp4?ex=6a4c5f61&is=6a4b0de1&hm=a2e50d0180d77f233a32c945012bd5c8fc2607983b1dec8422172b63de846dd9&
https://cdn.discordapp.com/attachments/791177690026606593/1497888166885982219/image.png?ex=6a4c1a50&is=6a4ac8d0&hm=51c0bb4d9538a3bbdc3bb0ee5590319f2e4846b5f7ae85bc32bb6123d8825066&
https://cdn.discordapp.com/attachments/791177690026606593/1497888167179718666/image.png?ex=6a4c1a50&is=6a4ac8d0&hm=baac992686ca82c1cfa9cf7056e0e5c2bf54843fc556858ce1efe7ee279ae12d&
https://cdn.discordapp.com/attachments/791177690026606593/1498095911438651422/Screen_Recording_20260426_184543_Chrome.mp4?ex=6a4c330a&is=6a4ae18a&hm=ee7f9320aa544bf3911637f2356df239a1294b98837593d64d971f430ff21d21&
https://cdn.discordapp.com/attachments/791177690026606593/1498182405842800661/erotica_1lw9sa0_Squeeze_these_soft_balls_and_live_away_your_stress_of_the_day.jpg?ex=6a4c8398&is=6a4b3218&hm=7882ff2b3dd2e4223c6fdc6e831e1f1c3bc78eb1dd8d9d39e5994018dab7d0b3&
https://cdn.discordapp.com/attachments/791177690026606593/1498451935554965677/FearlessCrazyDragonfly.mp4?ex=6a4c2d1d&is=6a4adb9d&hm=a17e240f16a661debdde69216b34e2cbb38389f6ea3de3ef286af8b0b528e916&
https://cdn.discordapp.com/attachments/791177690026606593/1498676537262735491/IMG_20260428_155129_282.jpg?ex=6a4c558a&is=6a4b040a&hm=52c0d8cbd7f721799a654a7be51bee0f568fedcd27bbddb79f5f3063ff6108e0&
https://cdn.discordapp.com/attachments/791177690026606593/1498676537841684480/IMG_20260428_155129_545.jpg?ex=6a4c558a&is=6a4b040a&hm=f6d53750b6313cf5d1c1394aeb8cf3efb78031cd83095aa1d376572c9253f41d&
https://cdn.discordapp.com/attachments/791177690026606593/1498676538269368350/IMG_20260428_155129_000.jpg?ex=6a4c558a&is=6a4b040a&hm=9c8ffc015a3df7eca092b79539a64f35102c078cb6abe1f448c5901f25b55f97&
https://cdn.discordapp.com/attachments/791177690026606593/1496534624304758944/20260422_183335.jpg?ex=6a4c73ba&is=6a4b223a&hm=446ea32a7c03070fbe2b5b1a726b4885b401d5fdfc2aa6ed854ff92bcb423c36&
https://cdn.discordapp.com/attachments/791177690026606593/1498792474183729162/ssstwitter_1648386528.mp4?ex=6a4c18c4&is=6a4ac744&hm=36d16202e7284956b0e6ee4e752b93279b3d46d8afaa835d4c743b3211982135&
https://cdn.discordapp.com/attachments/791177690026606593/1498792474506821772/GOT_20220218_03.mov?ex=6a4c18c4&is=6a4ac744&hm=450e769957b2cd263f69baf194ae84e596150f3f503a4e12740a5a36fc9ac109&
https://cdn.discordapp.com/attachments/791177690026606593/1498792474884177961/GOT_20220218_04.mp4?ex=6a4c18c4&is=6a4ac744&hm=786de901795553a3b5a9711b6c047d8af90b894b7bd5ad95baf2c792ba9ed6e9&
https://cdn.discordapp.com/attachments/791177690026606593/1498792475320652036/GOT_20220218_05.mov?ex=6a4c18c4&is=6a4ac744&hm=59f0b92615ab603f3a7d055f665da769bbc548e8c86ee79a897d4d1ebf5a42d1&
https://cdn.discordapp.com/attachments/791177690026606593/1498792475660128437/GOT_20220218_06.mov?ex=6a4c18c4&is=6a4ac744&hm=d61cd175a29ecfffcf64b5006462db79b42068810d96676f1d1c0c96e48bb34e&
https://cdn.discordapp.com/attachments/791177690026606593/1498792476478279770/GOT_20220218_10.mp4?ex=6a4c18c4&is=6a4ac744&hm=198d0885307c00e5137e64114b6ccc4dc3977456a676df374d9a85d826f5710e&
https://cdn.discordapp.com/attachments/791177690026606593/1498792476981334137/GOT_20220218_11.mp4?ex=6a4c18c4&is=6a4ac744&hm=711bdce8d540b8fdc5da5449f1bab516ef3babbeef70a0d60df4dd8d3a6824b8&
https://cdn.discordapp.com/attachments/791177690026606593/1498792477568667738/GOT_20220218_12.mp4?ex=6a4c18c4&is=6a4ac744&hm=f2bd4c68ba6a364b58ebe8752afcb03575eea7ae2c3ff88aee5b64db969d74d2&
https://cdn.discordapp.com/attachments/791177690026606593/1498792477815996456/GOT_20220218_13.mp4?ex=6a4c18c4&is=6a4ac744&hm=5d7ba6130d7715f301a010d1e72f6ac07184211ad2d8f804ffaec6a6481f40da&
https://cdn.discordapp.com/attachments/791177690026606593/1498792478181036073/ssstwitter_1649905179.mp4?ex=6a4c18c5&is=6a4ac745&hm=e25e5846398500e49939f05c57859cfda03a6eb0152e9d99d843473e330fbaff&
https://cdn.discordapp.com/attachments/791177690026606593/1498839122519785605/HFqzEqdagAAQsP6.png?ex=6a4c4435&is=6a4af2b5&hm=bba7efebf0a26b43efbb8bc3dcdb9ecba88107afdd3f1e06d11f16bfcf1a74a6&
https://cdn.discordapp.com/attachments/791177690026606593/1498863979571712010/image.png?ex=6a4c5b5c&is=6a4b09dc&hm=d27c332d866c0fabf3f84855fb2895fbc477da06afe51ac166c531e2d052adaf&
https://cdn.discordapp.com/attachments/791177690026606593/1499123068675686523/HospitableFickleIrishterrier.mp4?ex=6a4ca3e7&is=6a4b5267&hm=7aa2bfe175a2ce965aa9059b9550059e72bfeadc27a1d4018ce59ce49f80b698&
https://cdn.discordapp.com/attachments/791177690026606593/1499123069376139475/DarkgreyFondSockeyesalmon.mp4?ex=6a4ca3e8&is=6a4b5268&hm=6bd1e40f9c4eb1c492cd821361a8032e7ca3b03a5bf73a46c65a9dec51b3da16&
https://cdn.discordapp.com/attachments/791177690026606593/1499157665706803362/mommys-vampire-body-v0-970fj08cc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=892134cc6087b985165fa4a3866ce476af4ff4ad335b6d252dadf8e156788ef8&
https://cdn.discordapp.com/attachments/791177690026606593/1499157666423898133/mommys-vampire-body-v0-uxvn5wedc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=bce6d472b6d6e9342f07c9fe3d174f1179f1fa2433099c934a830ec9efa5c0d8&
https://cdn.discordapp.com/attachments/791177690026606593/1499157666964967686/mommys-vampire-body-v0-1ao9qfycc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=a379099fe5d3f2c94889ce96ee48c9e5b1fa9c6baf9cf7f182f647194eda154f&
https://cdn.discordapp.com/attachments/791177690026606593/1499157667472609421/mommys-vampire-body-v0-3rukogkcc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=f1b38035181feffc39b50814e3ec90a1db7194ce4182232c081446041c2ea849&
https://cdn.discordapp.com/attachments/791177690026606593/1499268495635120148/TinyBisqueNorthernfurseal.mp4?ex=6a4c8298&is=6a4b3118&hm=20d5be6eb3d9a313b2612c8b71e6804a969c4f1f159fe304637dc33785a54d72&
https://cdn.discordapp.com/attachments/791177690026606593/1499406043149635614/f8c2ff449fe0ea9fa91e6ff67713009a.png?ex=6a4c59f2&is=6a4b0872&hm=470a8fd5efa70cd383a9dcc72ae9a965ce530fee7997f5d637b6c90defdf5176&
https://cdn.discordapp.com/attachments/791177690026606593/1499410753738772520/IMG_20260430_170221_080.jpg?ex=6a4c5e55&is=6a4b0cd5&hm=b80490aa560b531140f7fed99a5723d80b503958b0f344cb2f60cedc051fb3e0&
https://cdn.discordapp.com/attachments/791177690026606593/1499506074867339374/horny-angles-for-your-boner-v0-jp7cu4yr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=8d2f69fd06f287096b7d07d65bb54cca085354d1440857dd06ca6aa47ec3f758&=
https://cdn.discordapp.com/attachments/791177690026606593/1499506075337097277/horny-angles-for-your-boner-v0-gfq7rryr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=daff5d5930b5d2e0d9869614d7ec31c2d056a93fd8814e3bf0ad0c762b3bb1e4&=
https://cdn.discordapp.com/attachments/791177690026606593/1499506075718914079/horny-angles-for-your-boner-v0-hkjzi5yr19yg1.png?ex=6a4c0e5b&is=6a4abcdb&hm=6213d6d1e99c308f1263cec7dc98dff1d26ca003af08d4922f1bcfe39cf9d30c&=
https://cdn.discordapp.com/attachments/791177690026606593/1499506076087881964/horny-angles-for-your-boner-v0-myex66yr19yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=954e426fb0854a8f807639966f1f9b013a8ae2e0c90e5ecf5af496b2ddece82e&=
https://cdn.discordapp.com/attachments/791177690026606593/1499506076456976405/horny-angles-for-your-boner-v0-8o71tt3229yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=12f3d7d94f8d732e424535995010219deaf6c135428d22e4684d9993ec4217e3&=
https://cdn.discordapp.com/attachments/791177690026606593/1499506076851376188/horny-angles-for-your-boner-v0-lcwl8xl229yg1.png?ex=6a4c0e5c&is=6a4abcdc&hm=452583f80d7812668c2442d1e025882503c624038e29092effe29ef6e1c5f0b8&=
https://cdn.discordapp.com/attachments/791177690026606593/1499555558271746148/HHMCYFyb0AAL7s0.png?ex=6a4c3c71&is=6a4aeaf1&hm=659e9455d98d1187b8c4bb3cc4ebce02a3e15a3015a221a2fa3f340f43b0a1de&=
https://cdn.discordapp.com/attachments/791177690026606593/1500632354413351043/IMG_20260503_132200_800.jpg?ex=6a4c32c9&is=6a4ae149&hm=52c0b0860e70badd954f1abb5c199a173406eb91a36123d8fe9d3ef942eddf0e&=
https://cdn.discordapp.com/attachments/791177690026606593/1495810741234827308/ssstwitter.com_1776699457612.mp4?ex=6a4c748f&is=6a4b230f&hm=f9f1af7d021d206a527c6a28f1946801e41b0792a968c65ff727fed8cc31fb20&
https://cdn.discordapp.com/attachments/791177690026606593/1495847160917524490/video_2021-08-22_18-09-44.mp4?ex=6a4c967a&is=6a4b44fa&hm=84715eeb2413ed4fe41bde7e9aa2cc0b94f85888ea5a2fe370c8d23149f229c8&
https://cdn.discordapp.com/attachments/791177690026606593/1495929279823876106/image.png?ex=6a4c3a35&is=6a4ae8b5&hm=67ec292143bc5d4565d572a2153588f2bd01a8c653e2aed4c30d9ee1feb0645d&
https://cdn.discordapp.com/attachments/791177690026606593/1496148243325915269/RDT_20260421_131140.mp4?ex=6a4c5d62&is=6a4b0be2&hm=aa8a66df59cce4ecef9452a15fe75c6ca18b1b589196a6f3f4627fe71deaa9de&
https://cdn.discordapp.com/attachments/791177690026606593/1496186920781221918/SpankBang.com_grshmn4_480p.mp4?ex=6a4c8167&is=6a4b2fe7&hm=0be2871c1cb45326dd6a6defc1d3ebbde790bb447da65a949cbe39ec858834b3&
https://cdn.discordapp.com/attachments/791177690026606593/1496188193895223336/Grshmn_aka_Anastasia_Grishman_-_Fucked_Step_Sis___FAKE_SITUATION_360p.mp4?ex=6a4c8297&is=6a4b3117&hm=c7ab403cc5b3ba1014fd1f76059351ddab416fb67cfe475f703ea12b49215587&
https://cdn.discordapp.com/attachments/791177690026606593/1496323952077836348/HGclHkUakAA4UA4.png?ex=6a4c5846&is=6a4b06c6&hm=1d9907e35efd76a2c3a75823ae9edd86d0e8db7d50baa729ea69b7d4f7bc9d35&
https://cdn.discordapp.com/attachments/791177690026606593/1496343778833727508/InShot_20260421_193013045.mp4?ex=6a4c6abd&is=6a4b193d&hm=0af5056760252c8bf8ae5bb5847cb69053cb302ab788bdaa380458964b65eff3&
https://cdn.discordapp.com/attachments/791177690026606593/1496480785811640430/xdownloader.com__86bdf.mov?ex=6a4c4196&is=6a4af016&hm=9cd64199b80c8e4c2c10aa74741778a052af04a58e2cc311a9702c393073767b&
https://cdn.discordapp.com/attachments/791177690026606593/1496487788588044499/erotica_1lww3lz_four_eyes_goth_slut.jpg?ex=6a4c481c&is=6a4af69c&hm=8c41cf3e9feb374c7ed771b2671fb883459b4a8bdb8a5b1abe3cbc0476848eff&
https://cdn.discordapp.com/attachments/791177690026606593/1496487895333208195/erotica_1lyb3fq_Waiting_for_you_in_my_bed_like_this.jpg?ex=6a4c4835&is=6a4af6b5&hm=833196a7ae9d86963a2f3a3211fe6e495d41c7b23340c0e426ebf23b80d0f975&
https://cdn.discordapp.com/attachments/791177690026606593/1496513771731157112/1776848552406255.webm?ex=6a4c604f&is=6a4b0ecf&hm=ff2429e2d60dc884d339a39fe4199b24aa64d1bc88e7ae2896851134253c3b74&
https://cdn.discordapp.com/attachments/791177690026606593/1496698795780608021/HCLs7H-XUAEpGwI.jpg?ex=6a4c63e0&is=6a4b1260&hm=9fad72c52be6cdfc60f95477d5c330d62b9fc2d257f494dc3455815fb9b442f0&
https://cdn.discordapp.com/attachments/791177690026606593/1496881031943553314/1764106967705795m.jpg?ex=6a4c64d8&is=6a4b1358&hm=ce672205839277b1ad8231f04458572496e1b144d667ecfca2cf1cf3fc886a5b&
https://cdn.discordapp.com/attachments/791177690026606593/1496881037467451513/1755592338232141m.jpg?ex=6a4c64da&is=6a4b135a&hm=a8539003fc58484aa2461a5226b713867ec039702a97155b6b550aeac0a5da5a&
https://cdn.discordapp.com/attachments/791177690026606593/1496881044312424569/1753799198080965m.jpg?ex=6a4c64db&is=6a4b135b&hm=d99c480fc5d5754413b008f27cfbbb55806db9f0756c0080ed2ff6cb8feab3ba&
https://cdn.discordapp.com/attachments/791177690026606593/1497020374129574019/RDT_20260423_062244.mp4?ex=6a4c3dde&is=6a4aec5e&hm=40f3c2d83546dfdf5629d94d8a631ff2ba6a797d42ecfac77cdb72d3d4f3e394&
https://cdn.discordapp.com/attachments/791177690026606593/1497163775890161664/1776867188241002.webm?ex=6a4c1aac&is=6a4ac92c&hm=99539e5827ca1ff8bcb17397ddac4390225a8b94baeb3a6d7d6f91842109ccf8&
https://cdn.discordapp.com/attachments/791177690026606593/1497239696881877113/IMG_20260424_171523_233.jpg?ex=6a4c6161&is=6a4b0fe1&hm=5befe67933e187f0b1b2810619dbda73b8911b98d0c8234b6e07e66351f390c3&
https://cdn.discordapp.com/attachments/791177690026606593/1499157665706803362/mommys-vampire-body-v0-970fj08cc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=892134cc6087b985165fa4a3866ce476af4ff4ad335b6d252dadf8e156788ef8&=
https://cdn.discordapp.com/attachments/791177690026606593/1499157666423898133/mommys-vampire-body-v0-uxvn5wedc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=bce6d472b6d6e9342f07c9fe3d174f1179f1fa2433099c934a830ec9efa5c0d8&=
https://cdn.discordapp.com/attachments/791177690026606593/1499157666964967686/mommys-vampire-body-v0-1ao9qfycc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=a379099fe5d3f2c94889ce96ee48c9e5b1fa9c6baf9cf7f182f647194eda154f&=
https://cdn.discordapp.com/attachments/791177690026606593/1499157667472609421/mommys-vampire-body-v0-3rukogkcc2yg1.png?ex=6a4c1b60&is=6a4ac9e0&hm=f1b38035181feffc39b50814e3ec90a1db7194ce4182232c081446041c2ea849&=
https://cdn.discordapp.com/attachments/791177690026606593/1499406043149635614/f8c2ff449fe0ea9fa91e6ff67713009a.png?ex=6a4c59f2&is=6a4b0872&hm=470a8fd5efa70cd383a9dcc72ae9a965ce530fee7997f5d637b6c90defdf5176&=
https://cdn.discordapp.com/attachments/791177690026606593/1499410753738772520/IMG_20260430_170221_080.jpg?ex=6a4c5e55&is=6a4b0cd5&hm=b80490aa560b531140f7fed99a5723d80b503958b0f344cb2f60cedc051fb3e0&=
https://cdn.discordapp.com/attachments/791177690026606593/1493895187041357864/RDT_20260415_114524.mp4?ex=6a4c140f&is=6a4ac28f&hm=a42019397f89e63f881c61f4042852a7c3fca1803be7560785649d3074f82884&
https://cdn.discordapp.com/attachments/791177690026606593/1493938280423624856/HFtdx0jWoAAjn3c.png?ex=6a4c3c32&is=6a4aeab2&hm=de7e9171996d0c10b13b213f96ef6a323f3cfed9e346d385314c809b696904dc&
https://cdn.discordapp.com/attachments/791177690026606593/1493970563172143134/15893589.mp4?ex=6a4c5a42&is=6a4b08c2&hm=c0399577a73e8829ec1a86e9c7de8f3eff2ed3a8fd1597cb2a4133b3bdbb1adf&
https://cdn.discordapp.com/attachments/791177690026606593/1494000420610379866/HBujEpKbgAExN52.png?ex=6a4c7611&is=6a4b2491&hm=c3e1cd8ed3d157f37dbffe73a8f19781e2ce7d9b42fd24c8a817484d41e59908&
https://cdn.discordapp.com/attachments/791177690026606593/1494000461068374047/G98DDQTaAAAaMMH.png?ex=6a4c761b&is=6a4b249b&hm=7813e7b1e1f1b0b045027d61fb4c1123d1625132bb5deeef553271650bb5b7df&
https://cdn.discordapp.com/attachments/791177690026606593/1494000517012131981/HEmCwC4aIAAqyAz.jpeg?ex=6a4c7628&is=6a4b24a8&hm=24546248364e486112142d2419e25356636635db8810f355afc82786a1b9adb2&
https://cdn.discordapp.com/attachments/791177690026606593/1494100362980753538/RDT_20260416_032028944461071438111001.jpg?ex=6a4c2a65&is=6a4ad8e5&hm=86dc8cb46362c27e865cfac6636ac3eaaca3b545c9fba326afc1e70a76d708d4&
https://cdn.discordapp.com/attachments/791177690026606593/1494102773325889596/RDT_20260416_033038.mp4?ex=6a4c2ca4&is=6a4adb24&hm=80df1c2e9edc05ba6b4189c28d2130fc3795fc16d3742fb4990232349c623bb5&
https://cdn.discordapp.com/attachments/791177690026606593/1494458158553235648/EPORNER.COM_-_W7g484Hs2HB_Demon_Mika_cogiendo_en_latex_negro_1440_1.mp4?ex=6a4c261e&is=6a4ad49e&hm=5b7619b3fe4d8c8b80eec9763e8e611d7e151137cd5f54852f97d8a39abc910c&
https://cdn.discordapp.com/attachments/791177690026606593/1494458158855360686/EPORNER.COM_-_W7g484Hs2HB_Demon_Mika_cogiendo_en_latex_negro_1440.mp4?ex=6a4c261e&is=6a4ad49e&hm=abdfbf2a627a5962311aed5a924c8705ce45757c92a0a44658b6eb77f9fc13df&
https://cdn.discordapp.com/attachments/791177690026606593/1494579284059226222/RDT_20260417_104149.mp4?ex=6a4c96ed&is=6a4b456d&hm=543664079ac36f49ff75bf4dcfa2c948cae757d2dd63451a5afab33bcd7b4249&
https://cdn.discordapp.com/attachments/791177690026606593/1494687296979472515/image.png?ex=6a4c52c5&is=6a4b0145&hm=7344256221ea649a7b1b07948b65f67f19483276056f5ace525d319461fcbd68&
https://cdn.discordapp.com/attachments/791177690026606593/1494687424721453106/image.png?ex=6a4c52e4&is=6a4b0164&hm=f196d0e96243e9324bcdd5796ca9ea0bc0ce228c46674a5298f812364171ba2c&
https://cdn.discordapp.com/attachments/791177690026606593/1494738818740260954/photo-porn-porn-Goth-Girl-Ady_Dark-9058635.png?ex=6a4c82c1&is=6a4b3141&hm=c5a46d4a780adcde8f7d18e6f126bac82b3c46db9dcedc976f0f72955451885d&
https://cdn.discordapp.com/attachments/791177690026606593/1494738819315142847/HF_Ke0DWIAAwElp.png?ex=6a4c82c1&is=6a4b3141&hm=bb8e1d39bba0ed925e2a5a04db5e90d05eb96d54b69aefd8dda613f224e90e10&
https://cdn.discordapp.com/attachments/791177690026606593/1494738819709145320/7869ca1601c9ab01cc40b960b59ddafa6204ff3d583a81a34dc527cfc2f07200.png?ex=6a4c82c1&is=6a4b3141&hm=3dc5ce97fcdcd93dd1451d2cd9399e6745f13f0df514902f0dbb82e59c02636a&
https://cdn.discordapp.com/attachments/791177690026606593/1494998730544517230/RDT_20260417_022741596503570639346977.jpg?ex=6a4c2351&is=6a4ad1d1&hm=41690f1e49a7243a168e2d850fb88e9e38aa48130d093ecabe6b863020e6c736&
https://cdn.discordapp.com/attachments/791177690026606593/1494998730900766780/RDT_20260417_022816765260835967761000.jpg?ex=6a4c2351&is=6a4ad1d1&hm=8ccb5d3a2f0e9f38b318cd9616396333a2618a2a0f998606fad19d7af37130dd&
https://cdn.discordapp.com/attachments/791177690026606593/1494998731261608037/RDT_20260417_023608.mp4?ex=6a4c2351&is=6a4ad1d1&hm=d21f09a07beb981063eb41fe88a8445e782960d32a3af1e408df08cc19210e71&
https://cdn.discordapp.com/attachments/791177690026606593/1494998731555344464/RDT_20260417_024036768666726594871258.jpg?ex=6a4c2351&is=6a4ad1d1&hm=b4c2429399b6b4be9d01e018efe9f7364d034f16283650166cd4b56daaa6aa33&
https://cdn.discordapp.com/attachments/791177690026606593/1494998731983032350/RDT_20260417_022713.mp4?ex=6a4c2351&is=6a4ad1d1&hm=ee3a9ba0a96f0f57422d0de15421db68fc8ed09e7a6496b3d2ee9de620beb4e9&
https://cdn.discordapp.com/attachments/791177690026606593/1494998732431818812/RDT_20260417_021916.mp4?ex=6a4c2351&is=6a4ad1d1&hm=16555b53dd43761a910cfe8aa7c3563ddfaf147428f0150e1c030022c5e730ce&
https://cdn.discordapp.com/attachments/791177690026606593/1495338490273988649/F4zvkrWWwAALRw9.png?ex=6a4c0e3e&is=6a4abcbe&hm=e3418fe3562456c20484a51444c030b1ff76db5f3901ee016158dd84ffd0d3e4&
https://cdn.discordapp.com/attachments/791177690026606593/1495345626567802991/F16ZhFqWcAIvArc.png?ex=6a4c14e3&is=6a4ac363&hm=706ac7483ee64ef04a3100321bb9c5395912977d791fe62a522e94ece150ffea&
https://cdn.discordapp.com/attachments/791177690026606593/1495434994296819722/Screenshot_20241118-034916_X.jpg?ex=6a4c681e&is=6a4b169e&hm=6b696c487d49c0dbbdc07b8efc9e2e84e7fafe29d27158a6180e339c4db15474&
https://cdn.discordapp.com/attachments/791177690026606593/1495547897356357885/HGH202PbAAAxWCF.png?ex=6a4c2884&is=6a4ad704&hm=3697dbdcd55d5b972653cbf342972dc922d6ba770c7979a9d1fc95f913ab2407&
https://cdn.discordapp.com/attachments/791177690026606593/1495706084785258506/IMG_20260420_114127_413.jpg?ex=6a4c1317&is=6a4ac197&hm=49dc6f2592f1cca65cff3f6bfb65526f39c818e9b21dab059f17fe38f6cfdfb3&
https://cdn.discordapp.com/attachments/791177690026606593/1495772370034491432/Alt_Close_Up_Creampie_Creamy_Cum_Covered_Fucking_Goth_Orgasm_Pawg_Riding_Wet_and_Messy_Porn_Gif_by_xninjae___RedGIFs_1.mp4?ex=6a4c50d3&is=6a4aff53&hm=b00c85ae4b74a0cfb43568bd49e43ff907eaa821d7da4014e34b06967a897b51&
https://cdn.discordapp.com/attachments/791177690026606593/1497239696881877113/IMG_20260424_171523_233.jpg?ex=6a4c6161&is=6a4b0fe1&hm=5befe67933e187f0b1b2810619dbda73b8911b98d0c8234b6e07e66351f390c3&=
https://cdn.discordapp.com/attachments/791177690026606593/1491742126625787944/RDT_20260409_120653.mp4?ex=6a4c27de&is=6a4ad65e&hm=6695cbf1a8c8b82ba58bdedc76e9d73b1b3f6d311049ca861edd17991e3999f8&
https://cdn.discordapp.com/attachments/791177690026606593/1491753044172603442/jjkwolwu4e.mp4?ex=6a4c3209&is=6a4ae089&hm=4c0dca7072138d07534a3842d61b2538224e2325ba693b7bbe9df62b8fe11998&
https://cdn.discordapp.com/attachments/791177690026606593/1491844865594626048/image.png?ex=6a4c878d&is=6a4b360d&hm=f38f7f339b90aff95537f737fd4a4e6f36d444525b7cba5a752057981f422623&
https://cdn.discordapp.com/attachments/791177690026606593/1492266329150066730/drop-your-size-and-ill-tell-you-wich-slut-you-get-for-a-v0-ccle4r8h9fug1.jpg?ex=6a4c15d1&is=6a4ac451&hm=d3b70395a328c548ab78b3af8e5a29e67f35adcf8079b770d2deef48a08b25a9&
https://cdn.discordapp.com/attachments/791177690026606593/1492266341153902733/drop-your-size-and-ill-tell-you-wich-slut-you-get-for-a-v0-futgs1ch9fug1.jpg?ex=6a4c15d4&is=6a4ac454&hm=b16b570bbeb2695be0d37992849cb0d23d3d63c944649f1180b8069da4919eb8&
https://cdn.discordapp.com/attachments/791177690026606593/1492521721524260955/EPORNER.COM_-_W7g484Hs2HB_Demon_Mika_cogiendo_en_latex_negro_1440_1.mp4?ex=6a4c5aec&is=6a4b096c&hm=f428dd9b0314d8ed94fb5e617745c496e25e3a11aa604bfecaf8b4fb1030e8ee&
https://cdn.discordapp.com/attachments/791177690026606593/1492521722220646530/EPORNER.COM_-_W7g484Hs2HB_Demon_Mika_cogiendo_en_latex_negro_1440.mp4?ex=6a4c5aec&is=6a4b096c&hm=614208bf9cf5f9c0eb772a10e6dfebee3cebf3c624e20a43d5e3c8df7c8b358b&
https://cdn.discordapp.com/attachments/791177690026606593/1492784891555741746/X2Twitter.com_DcN5cW8hnJqOo0c6_852p.mov?ex=6a4ca744&is=6a4b55c4&hm=e615f18bdf37e51a82fc058c8a6917250afa8fc7998129421c0815b552f3873a&
https://cdn.discordapp.com/attachments/791177690026606593/1492784912166817814/X2Twitter.com_AL2nsStoh_ASdule_852p.mov?ex=6a4ca749&is=6a4b55c9&hm=d2c870ecdc57762522afa780d4a59231dc5e43cff4d01a71605f5bb252493f79&
https://cdn.discordapp.com/attachments/791177690026606593/1492784917543915541/IMG_1308.jpg?ex=6a4ca74a&is=6a4b55ca&hm=2b311e4eb5b61a063064156c98c539e3cc00ce339fe57e4a00f19d09b2ba9a37&
https://cdn.discordapp.com/attachments/791177690026606593/1492889553025892452/G1g-YN1WoAAhsF5.jpg?ex=6a4c5ffd&is=6a4b0e7d&hm=b1b8548034bde98e311f86902dfd580579cdc102c09d16cec48610ee60d271c4&
https://cdn.discordapp.com/attachments/791177690026606593/1492889553437069533/GwRrheXWUAAEpON.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=408177888f449485e8cd8a5261ce9481575b5efe85909c10e54a0280ab6ebf2d&
https://cdn.discordapp.com/attachments/791177690026606593/1492889554183782460/Gwoj3ekWYAIX0RO.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=be03235c8957b99474d4814f59dfa8f05e86e242b5c50f438476d9ff65f1ffca&
https://cdn.discordapp.com/attachments/791177690026606593/1492889554657480945/G1sAvyIWYAAi8cQ.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=aa0a04693946bc39a954712d4e1ca0b3af74c78de39d403b736263c56247aed4&
https://cdn.discordapp.com/attachments/791177690026606593/1492889555383353454/G11ALE3XAAEPkeX.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=c23218b26c7fa3444fcd467a3a2b81d67e80e9f07892c98e1e2108b4af805d7c&
https://cdn.discordapp.com/attachments/791177690026606593/1492889556243058719/G1vwwFEWwAAX7In.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=df2c496c710c1d97f60ed4dba3df91e399f2772625bb33c41da335b1face5682&
https://cdn.discordapp.com/attachments/791177690026606593/1492889556956217427/G6lxsTrXEAA2Kf2.jpg?ex=6a4c5ffe&is=6a4b0e7e&hm=6481e088d874bfeaf271ca392860492a40d7a9b48795632235607341c0777a14&
https://cdn.discordapp.com/attachments/791177690026606593/1492889557413265448/GtvV38BWYAAyyXG.jpg?ex=6a4c5fff&is=6a4b0e7f&hm=79dad38fdc292b8925876988f8e70f57c0374a3d10045d4dc7070ad33ade5819&
https://cdn.discordapp.com/attachments/791177690026606593/1492889558126432346/GuIDvDlWIAA-qYV.jpg?ex=6a4c5fff&is=6a4b0e7f&hm=437d6f95e772636abca478c342fc184c32043023a261121c74378df2e7f33ed3&
https://cdn.discordapp.com/attachments/791177690026606593/1492946387388727366/image.png?ex=6a4c94ec&is=6a4b436c&hm=d7ebbfbc34860d74b796414a188170c611a2e63731777a14af100425e9800efe&
https://cdn.discordapp.com/attachments/791177690026606593/1493096442167034029/HEvzUbMbIAAWWRp.png?ex=6a4c77ec&is=6a4b266c&hm=59dd8450573078405e0decdc01da24281a7ced4dd0dd5669a5147d43a97cdb4e&
https://cdn.discordapp.com/attachments/791177690026606593/1493338523896385677/image.png?ex=6a4c07e0&is=6a4ab660&hm=5b61513077eeb03197a7a5d844e3b9dd721c3ad29c4da3a54dcad7d57eb7e9cb&
https://cdn.discordapp.com/attachments/791177690026606593/1493411586683965592/image.png?ex=6a4c4bec&is=6a4afa6c&hm=5c1f9db491252ea4d2112a8fa4eca17118f586352add18d90dc5094701436148&
https://cdn.discordapp.com/attachments/791177690026606593/1493418759099121725/4ff1a4ec-740b-41b3-a724-407c3a8e90ed-DISCORD-GG-VEXYL_280.mp4?ex=6a4c529a&is=6a4b011a&hm=476a78a7cf643ae0e6056070b6681ba46d5a1c6c5565e97ee86c4bc207b7089b&
https://cdn.discordapp.com/attachments/791177690026606593/1493425287747076308/890_1_1_EnergeticMundaneBarasingha-mobile.mov.E-pCVIQQKV.mp4?ex=6a4c58af&is=6a4b072f&hm=227fc8e167111a0a7ed3840aeac952f0db28190b16279d189620ff283d562b72&
https://cdn.discordapp.com/attachments/791177690026606593/1493605899217141860/so_squishy__3_1.gif?ex=6a4c5824&is=6a4b06a4&hm=ca8f13c20282e14b58068b6a2771bea7323a4e8e0cc411e35709d0b5ac0a4c62&
https://cdn.discordapp.com/attachments/791177690026606593/1493740009969156116/RDT_20260415_032749.mp4?ex=6a4c2c4a&is=6a4adaca&hm=8821193f9c3175b3e1cf2cbc7b0410522a29289cf85d72ff6c9bf0328059801b&
https://cdn.discordapp.com/attachments/791177690026606593/1493740010397106366/RDT_20260415_032741.mp4?ex=6a4c2c4a&is=6a4adaca&hm=2b0f8e403d535b6823b5341bb1a2102101908eb7c9b210d5bf0d45a170ba2a64&
https://cdn.discordapp.com/attachments/791177690026606593/1493740010996760717/RDT_20260415_032733.mp4?ex=6a4c2c4a&is=6a4adaca&hm=b2ad1d24c9afa60aea16bf44b24271cd662d4d0776600b9789df06cada40d27f&
https://cdn.discordapp.com/attachments/791177690026606593/1495547897356357885/HGH202PbAAAxWCF.png?ex=6a4c2884&is=6a4ad704&hm=3697dbdcd55d5b972653cbf342972dc922d6ba770c7979a9d1fc95f913ab2407&=
https://cdn.discordapp.com/attachments/791177690026606593/1495706084785258506/IMG_20260420_114127_413.jpg?ex=6a4c1317&is=6a4ac197&hm=49dc6f2592f1cca65cff3f6bfb65526f39c818e9b21dab059f17fe38f6cfdfb3&=
https://cdn.discordapp.com/attachments/791177690026606593/1493605899217141860/so_squishy__3_1.gif?ex=6a4c5824&is=6a4b06a4&hm=ca8f13c20282e14b58068b6a2771bea7323a4e8e0cc411e35709d0b5ac0a4c62&=
https://cdn.discordapp.com/attachments/791177690026606593/1490382116813279302/IMG_20251211_091245_653.jpg?ex=6a4c7b42&is=6a4b29c2&hm=3ae906ad68de6122745d82005c39973f5ed3c0e3114b4d34cac20fab736108bd&
https://cdn.discordapp.com/attachments/791177690026606593/1490404059180699912/AJ_z5yRc-Vtd2wr2.mp4?ex=6a4c8fb2&is=6a4b3e32&hm=13d48a542823beb84355d518d173d9189fc0b06dd6e1a5025c5187189dafcebe&
https://cdn.discordapp.com/attachments/791177690026606593/1490456251740717278/lmk-your-fav-and-how-big-your-is-and-ill-decide-what-youll-v0-alwk3kz66ftg1.webp?ex=6a4c178d&is=6a4ac60d&hm=695d810bf77037f6bb211f22b263b442d5d0ed51b7a0b8beab693265e18b9790&
https://cdn.discordapp.com/attachments/791177690026606593/1490456442556256446/sdfvgb.webp?ex=6a4c17bb&is=6a4ac63b&hm=36ef59835bb06fb77d1bf1669832c63de2a15cc1a0e66a088117e18e3126202d&
https://cdn.discordapp.com/attachments/791177690026606593/1490460378914885845/Good_boy_hj.mp4?ex=6a4c1b65&is=6a4ac9e5&hm=6edc46f843c7da558fed0e4dc1fb1d7d40fd75230d53edca036527886797e329&
https://cdn.discordapp.com/attachments/791177690026606593/1490464146750181526/uum001lszosg1.png?ex=6a4c1ee8&is=6a4acd68&hm=d302c0ec0479bef950d23f3d9613b376a478888c2a71167c8f8f47c801898b7e&
https://cdn.discordapp.com/attachments/791177690026606593/1490468274020810952/ACh1vebM_720p.mp4?ex=6a4c22c0&is=6a4ad140&hm=75b361d51771b80ac85c551fcb2185d5d0eeb91b4f2f02fb0f40661e7e9f9bbe&
https://cdn.discordapp.com/attachments/791177690026606593/1490496487040356554/4d5ad073-22ee-46d8-96f4-676c214d38f8-DISCORD-GG-VEXYL_238.mp4?ex=6a4c3d06&is=6a4aeb86&hm=9541de07c1b7e253c0e1d355c1d48e6e1032252600db43b5b5496bba2e49b67e&
https://cdn.discordapp.com/attachments/791177690026606593/1490565626333499443/HFKywKbaQAEdUtZ.png?ex=6a4c7d6a&is=6a4b2bea&hm=8556c86ad8997eb4a805a6b619c86f0acd1add825eb3e1fd3a123f7901c94cad&
https://cdn.discordapp.com/attachments/791177690026606593/1490567208353402920/HEvzUbMbIAAWWRp.png?ex=6a4c7ee3&is=6a4b2d63&hm=c1ad03134bfb3e0a0196547f08a5d44dc6864a4dbedd9759718db4c50424505f&
https://cdn.discordapp.com/attachments/791177690026606593/1490684589906198538/q0LrsBTl_720p.mp4?ex=6a4c4375&is=6a4af1f5&hm=fed4799f3a355f29606a4c5653de99f4beaf2012bd1e747b2b16a11a866d2cd3&
https://cdn.discordapp.com/attachments/791177690026606593/1490783773053292666/Goticas_TCN_24.mp4?ex=6a4c9fd4&is=6a4b4e54&hm=ef2ba22226177eb94f97e661ce70bcc4925e8a023fa05ddcfa94e140cb4f6bf8&
https://cdn.discordapp.com/attachments/791177690026606593/1490799830560411730/Goticas_TCN_35.mov?ex=6a4c0609&is=6a4ab489&hm=30f7020bb7cdb0fc0a64d3366af9fffe2611fe23951b07fba5a9992518bd74c3&
https://cdn.discordapp.com/attachments/791177690026606593/1490830949884104814/ssstwitter.com_1775511958924.mp4?ex=6a4c2304&is=6a4ad184&hm=7d8dff3236d3f1822addfffa533eb49a17bef162c6fbfccc823da13ba2190b13&
https://cdn.discordapp.com/attachments/791177690026606593/1490882956137595090/VID_20250912_140449_785.mp4?ex=6a4c5374&is=6a4b01f4&hm=b43441a2fb128307082cdddf81b6e9442dfb2a75029094e3d966329654e460a1&
https://cdn.discordapp.com/attachments/791177690026606593/1490905813391380730/WaterloggedRundownBlueandgoldmackaw-mobile.mov?ex=6a4c68bd&is=6a4b173d&hm=fa27cdc2cf5d83ab83c69bbcb5ad1d2d7694552f91ee91661a787b502b9e14b5&
https://cdn.discordapp.com/attachments/791177690026606593/1491189290460250112/x6mk5hvpzqtg1.jpg?ex=6a4c1f3f&is=6a4acdbf&hm=6c1d1eec5c33d31073babd6e02a8b2b223e3401af66c30351844f7009d39da9f&
https://cdn.discordapp.com/attachments/791177690026606593/1491421139178623086/Screenshot_20260408_224154_Instagram.jpg?ex=6a4c4e6c&is=6a4afcec&hm=8243d3fc5ca28cbf6a71675f2de079a54f03ea0605dee2117647ab28ecf93df1&
https://cdn.discordapp.com/attachments/791177690026606593/1491421139178623086/Screenshot_20260408_224154_Instagram.jpg?ex=6a4c4e6c&is=6a4afcec&hm=8243d3fc5ca28cbf6a71675f2de079a54f03ea0605dee2117647ab28ecf93df1&=
https://cdn.discordapp.com/attachments/791177690026606593/1491533243772571698/image.png?ex=6a4c0e14&is=6a4abc94&hm=9565b6c26c24afa213dc2ef26c1dbedca72dae885565d68e84c434f09f56f4dc&
https://cdn.discordapp.com/attachments/791177690026606593/1491533243772571698/image.png?ex=6a4c0e14&is=6a4abc94&hm=9565b6c26c24afa213dc2ef26c1dbedca72dae885565d68e84c434f09f56f4dc&=
https://cdn.discordapp.com/attachments/791177690026606593/1491680064968851636/qi7t2ddnrztg1.jpg?ex=6a4c96d1&is=6a4b4551&hm=189c0fe3cf5592c2ea9b873ba239c623fab7f9c519fd000fe94d1c808e9247c5&
https://cdn.discordapp.com/attachments/791177690026606593/1490382116813279302/IMG_20251211_091245_653.jpg?ex=6a4c7b42&is=6a4b29c2&hm=3ae906ad68de6122745d82005c39973f5ed3c0e3114b4d34cac20fab736108bd&=
https://cdn.discordapp.com/attachments/791177690026606593/1491189290460250112/x6mk5hvpzqtg1.jpg?ex=6a4c1f3f&is=6a4acdbf&hm=6c1d1eec5c33d31073babd6e02a8b2b223e3401af66c30351844f7009d39da9f&=
]=]

pcall(function()
    for link in __RAW_URL_DATA__:gmatch("(https?://%S+)") do
        local lower_link = link:lower()
        if not lower_link:find("%.mp4") and not lower_link:find("%.mov") and not lower_link:find("%.avi") and not lower_link:find("%.webp") and not lower_link:find("%.gif") then
            link = link:gsub('"', ""):gsub(',', "")
            table.insert(goon_corner_urls, link)
        end
    end
    if #goon_corner_urls > 0 then
        urls_loaded = true
        debug_status = "Loaded " .. tostring(#goon_corner_urls) .. " URLs!"
    end
end)


local ffi = require("ffi")
ffi.cdef[[
    unsigned int __stdcall WinExec(const char* lpCmdLine, unsigned int uCmdShow);
    bool __stdcall DeleteUrlCacheEntryA(const char* lpszUrlName);
    int __stdcall mciSendStringA(const char* lpstrCommand, char* lpstrReturnString, unsigned int uReturnLength, void* hwndCallback);
]]
local urlmon = ffi.load("UrlMon")
local wininet = ffi.load("WinInet")
local winmm = ffi.load("winmm")

if files and files.create_folder then
    files.create_folder("nl/goon_corner")
end

local current_texture = nil
local fetched_textures = {}
local unseen_urls = {}
local next_switch = nil
local asmr_url = "https://www.dropbox.com/scl/fi/whwspuhp52r2bbj6okvah/F4M-Don-t-Call-Me-Mommy-If-You-Can-t-Handle-The-Consequences-Femdom-GFE-ASMR-Audio-Roleplay.mp3?rlkey=lr76sgifcopp9r6bccksozyf2&st=sy3a3igg&dl=1"
local asmr_path = "nl\\goon_corner\\asmr_mommy.mp3"
local asmr_retry_time = 0
local audio_playing = false
local last_toggle_state = false
local config_loading = false
local is_fetching = false
local is_prefetching = false
local next_ready_texture = nil
local pending_fetch_url = nil
local pending_original_url = nil
local pending_fetch_time = 0
local current_asmr_volume = -1
local current_asmr_seek = -1
local current_delay = 5
local was_dragging_seek = false
local last_seek_time = 0
local asmr_pos_buf = ffi.new("char[128]")

local function play_asmr()
    if audio_playing or not winmm then return end
    if globals.realtime < asmr_retry_time then return end

    pcall(function() winmm.mciSendStringA("close goth_asmr", nil, 0, nil) end)
    local status, res = pcall(function() return winmm.mciSendStringA('open "' .. asmr_path .. '" type mpegvideo alias goth_asmr', nil, 0, nil) end)
    if status and res == 0 then
        pcall(function() winmm.mciSendStringA("play goth_asmr repeat", nil, 0, nil) end)
        audio_playing = true
    else
        asmr_retry_time = globals.realtime + 1.0
    end
end

local function stop_asmr()
    if not audio_playing or not winmm then return end
    pcall(function() winmm.mciSendStringA("close goth_asmr", nil, 0, nil) end)
    audio_playing = false
end

pcall(function()
    local ps_cmd = string.format('powershell -windowstyle hidden -command "if (-not (Test-Path \'%s\')) { Invoke-WebRequest -Uri \'%s\' -OutFile \'%s\' }"', asmr_path, asmr_url, asmr_path)
    ffi.C.WinExec(ps_cmd, 0)
end)

math.randomseed(math.floor(globals.realtime * 1000))

if events and events.config_load then
    events.config_load:set(function()
        fetched_textures = {}
        unseen_urls = {}
        current_texture = nil
        next_ready_texture = nil
        config_loading = true
        next_switch = globals.realtime + current_delay
    end)
end

local last_file_check = 0
local function check_pending_fetch()
    if pending_fetch_url then
        if globals.realtime > pending_fetch_time + 30.0 then
            pcall(function() ffi.C.WinExec('powershell -windowstyle hidden -command "Remove-Item -Path \'nl/goon_corner/temp_slideshow.png*\' -ErrorAction SilentlyContinue"', 0) end)
            
            if pending_original_url then
                for i = 1, #goon_corner_urls do
                    if goon_corner_urls[i] == pending_original_url then
                        table.remove(goon_corner_urls, i)
                        break
                    end
                end
                for i = 1, #unseen_urls do
                    if unseen_urls[i] == pending_original_url then
                        table.remove(unseen_urls, i)
                        break
                    end
                end
            end
            
            pending_fetch_url = nil
            pending_original_url = nil
            is_fetching = false
            is_prefetching = false
            debug_status = "Timeout (30s)! Deleted."
            return
        end

        local elapsed = math.floor((globals.realtime - pending_fetch_time) * 10) / 10
        debug_status = "Downloading (" .. tostring(elapsed) .. "s)..."

        if globals.realtime - last_file_check < 0.2 then return end
        last_file_check = globals.realtime

        local error_bytes = nil
        pcall(function() error_bytes = files and files.read and files.read("nl/goon_corner/error.txt") end)
        if error_bytes then
            pcall(function() ffi.C.WinExec('powershell -windowstyle hidden -command "Remove-Item -Path \'nl/goon_corner/error.txt\' -ErrorAction SilentlyContinue; Remove-Item -Path \'nl/goon_corner/temp_slideshow.png*\' -ErrorAction SilentlyContinue"', 0) end)
            
            if pending_original_url then
                for i = 1, #goon_corner_urls do
                    if goon_corner_urls[i] == pending_original_url then
                        table.remove(goon_corner_urls, i)
                        break
                    end
                end
                for i = 1, #unseen_urls do
                    if unseen_urls[i] == pending_original_url then
                        table.remove(unseen_urls, i)
                        break
                    end
                end
            end
            
            pending_fetch_url = nil
            pending_original_url = nil
            is_fetching = false
            is_prefetching = false
            debug_status = "Dead link! Deleted."
            return
        end

        local temp_path = "nl/goon_corner/temp_slideshow.png"
        local bytes = nil
        pcall(function()
            bytes = files and files.read and files.read(temp_path)
        end)
        
        if bytes then
            local is_img = false
            if type(bytes) == "string" and #bytes >= 3 then
                local b1, b2, b3 = bytes:byte(1, 3)
                if (b1 == 137 and b2 == 80 and b3 == 78) or (b1 == 255 and b2 == 216 and b3 == 255) then 
                    is_img = true 
                end
            end

            if is_img then
                local status, img = pcall(function() return render.load_image_from_file(temp_path, vector(200, 200)) end)
                if status and img then
                    fetched_textures[pending_fetch_url] = img
                    if is_prefetching then
                        next_ready_texture = img
                    else
                        current_texture = img
                        next_switch = globals.realtime + current_delay
                    end
                else
                    is_img = false
                end
            end

            if not is_img then
                if pending_original_url then
                    for i = 1, #goon_corner_urls do
                        if goon_corner_urls[i] == pending_original_url then
                            table.remove(goon_corner_urls, i)
                            break
                        end
                    end
                    for i = 1, #unseen_urls do
                        if unseen_urls[i] == pending_original_url then
                            table.remove(unseen_urls, i)
                            break
                        end
                    end
                end
                debug_status = "Invalid format! Deleted."
            end
            
            pcall(function() ffi.C.WinExec('powershell -windowstyle hidden -command "Remove-Item -Path \'nl/goon_corner/temp_slideshow.png\' -ErrorAction SilentlyContinue"', 0) end)

            pending_fetch_url = nil
            pending_original_url = nil
            is_fetching = false
            is_prefetching = false
        end
    end
end

local function fetch_random_image(prefetch)
    if #goon_corner_urls == 0 or is_fetching then return end
    
    if #unseen_urls == 0 then
        for i = 1, #goon_corner_urls do
            unseen_urls[i] = goon_corner_urls[i]
        end
    end

    local rand_idx = math.random(1, #unseen_urls)
    local url = unseen_urls[rand_idx]
    local original_url = url
    table.remove(unseen_urls, rand_idx)
    
    -- Dynamically force Discord's servers to downscale the image to save bandwidth and load instantly!
    if url:find("discord") then
        url = url:gsub("cdn%.discordapp%.com", "media.discordapp.net")
        if not url:find("width=") then
            url = url .. (url:find("%?") and "&" or "?") .. "width=400&height=400"
        end
    end

    if fetched_textures[url] then
        if prefetch then
            next_ready_texture = fetched_textures[url]
        else
            current_texture = fetched_textures[url]
            next_switch = globals.realtime + current_delay
        end
        return
    end

    is_fetching = true
    is_prefetching = prefetch or false
    pending_fetch_url = url
    pending_original_url = original_url
    pending_fetch_time = globals.realtime
    debug_status = "Starting PowerShell..."
    
    local temp_path = "nl/goon_corner/temp_slideshow.png"

    -- Build invisible powershell command to securely wipe old file, download safely to .tmp, then atomically rename it when fully finished
    local ps_cmd = string.format('powershell -windowstyle hidden -command "Remove-Item -Path \'%s*\' -ErrorAction SilentlyContinue; Remove-Item -Path \'nl/goon_corner/error.txt\' -ErrorAction SilentlyContinue; try { Invoke-WebRequest -TimeoutSec 3 -Uri \'%s\' -OutFile \'%s.tmp\'; Move-Item -Force \'%s.tmp\' \'%s\' } catch { Set-Content -Path \'nl/goon_corner/error.txt\' -Value \'failed\' }"', temp_path, url, temp_path, temp_path, temp_path)
    
    -- Execute asynchronously via WinExec (0 = SW_HIDE)
    pcall(function()
        ffi.C.WinExec(ps_cmd, 0)
    end)
end

local gc_pos = type(vector) == "function" and vector(10, 10) or type(vector) == "table" and vector(10, 10) or nil
local gc_size = type(vector) == "function" and vector(200, 200) or type(vector) == "table" and vector(200, 200) or nil
local is_dragging = false
local is_resizing = false
local drag_offset_x = 0
local drag_offset_y = 0

local function on_render()
    local is_enabled = v51 and v51.get and v51.get("goon_corner_enabled")
    local is_asmr_enabled = v51 and v51.get and v51.get("goon_corner_asmr_enabled")
    
    current_delay = v51 and v51.get and v51.get("goon_corner_time") or 5
    local target_vol = v51 and v51.get and v51.get("goon_corner_volume") or 50
    local target_seek = v51 and v51.get and v51.get("goon_corner_seek") or 0

    if is_asmr_enabled then
        play_asmr()
        if audio_playing and winmm then
            if target_vol ~= current_asmr_volume then
                current_asmr_volume = target_vol
                pcall(function() winmm.mciSendStringA("setaudio goth_asmr volume to " .. tostring(target_vol * 10), nil, 0, nil) end)
            end
            local diff = target_seek - current_asmr_seek
            if diff < 0 then diff = -diff end
            local mouse_down = common.is_button_down(1)
            
            if diff > 0 and mouse_down then
                was_dragging_seek = true
                current_asmr_seek = target_seek
            elseif was_dragging_seek and not mouse_down then
                was_dragging_seek = false
                current_asmr_seek = target_seek
                last_seek_time = globals.realtime
                local seek_ms = math.floor(target_seek * 1000)
                pcall(function() winmm.mciSendStringA("play goth_asmr from " .. tostring(seek_ms) .. " repeat", nil, 0, nil) end)
            elseif not was_dragging_seek and globals.realtime > last_seek_time + 1.0 then
                local status_ok = pcall(function() winmm.mciSendStringA("status goth_asmr position", asmr_pos_buf, 128, nil) end)
                if status_ok then
                    local current_ms = tonumber(ffi.string(asmr_pos_buf))
                    if current_ms then
                        local sec = math.floor(current_ms / 1000)
                        if v51.elements_ptrs["goon_corner_seek"] and sec ~= current_asmr_seek then
                            v51.elements_ptrs["goon_corner_seek"].value = sec
                            current_asmr_seek = sec
                        end
                    end
                end
            end
        end
    else
        stop_asmr()
    end

    if not is_enabled then 
        fetched_textures = {}
        unseen_urls = {}
        current_texture = nil
        next_ready_texture = nil
        last_toggle_state = false
        config_loading = false
        return 
    end

    if not next_switch then
        next_switch = globals.realtime
    end

    if not last_toggle_state then
        last_toggle_state = true
        if not config_loading then
            next_switch = globals.realtime -- fetch instantly if manually toggled
        end
    end
    
    config_loading = false -- reset the flag after first frame

    if globals.realtime >= next_switch then
        if next_ready_texture then
            current_texture = next_ready_texture
            next_ready_texture = nil
            next_switch = globals.realtime + current_delay
        elseif not is_fetching then
            fetch_random_image(false)
        end
    elseif globals.realtime > (next_switch - math.min(2.5, current_delay * 0.5)) and not next_ready_texture and not is_fetching then
        fetch_random_image(true)
    end

    check_pending_fetch()

    pcall(function()
        local menu_open = v51 and v51.is_open and v51.is_open()
        local mouse_pos = ui.get_mouse_position and ui.get_mouse_position() or vector(0, 0)
        local is_down = common.is_button_down and common.is_button_down(1)

        if menu_open and gc_pos and gc_size then
            local resize_rect_pos_x = gc_pos.x + gc_size.x - 15
            local resize_rect_pos_y = gc_pos.y + gc_size.y - 15

            if is_down then
                if not is_dragging and not is_resizing then
                    if mouse_pos.x >= resize_rect_pos_x and mouse_pos.y >= resize_rect_pos_y and mouse_pos.x <= gc_pos.x + gc_size.x and mouse_pos.y <= gc_pos.y + gc_size.y then
                        is_resizing = true
                    elseif mouse_pos.x >= gc_pos.x and mouse_pos.y >= gc_pos.y and mouse_pos.x <= gc_pos.x + gc_size.x and mouse_pos.y <= gc_pos.y + gc_size.y then
                        is_dragging = true
                        drag_offset_x = mouse_pos.x - gc_pos.x
                        drag_offset_y = mouse_pos.y - gc_pos.y
                    end
                end
            else
                is_dragging = false
                is_resizing = false
            end

            if is_dragging then
                local nx = mouse_pos.x - drag_offset_x
                local ny = mouse_pos.y - drag_offset_y
                if type(nx) == "number" and nx == nx then gc_pos.x = nx end
                if type(ny) == "number" and ny == ny then gc_pos.y = ny end
            elseif is_resizing then
                local nx = mouse_pos.x - gc_pos.x
                local ny = mouse_pos.y - gc_pos.y
                if type(nx) == "number" and nx == nx then gc_size.x = nx end
                if type(ny) == "number" and ny == ny then gc_size.y = ny end
                if gc_size.x < 50 then gc_size.x = 50 end
                if gc_size.y < 50 then gc_size.y = 50 end
            end

            -- Anti-crash bounds clamping
            local screen = render.screen_size and render.screen_size() or vector(1920, 1080)
            if gc_pos.x < -gc_size.x + 10 then gc_pos.x = -gc_size.x + 10 end
            if gc_pos.y < -gc_size.y + 10 then gc_pos.y = -gc_size.y + 10 end
            if gc_pos.x > screen.x - 10 then gc_pos.x = screen.x - 10 end
            if gc_pos.y > screen.y - 10 then gc_pos.y = screen.y - 10 end
        else
            is_dragging = false
            is_resizing = false
        end

        local clr = type(color) == "function" and color(255, 255, 255, 255) or type(color) == "table" and color(255, 255, 255, 255) or nil
        local pink = type(color) == "function" and color(255, 0, 255, 255) or type(color) == "table" and color(255, 0, 255, 255) or nil
        local accent = v51 and v51.get and v51.get("theme_accent") or pink

        if current_texture and gc_pos and gc_size and clr then
            if render.texture then
                render.texture(current_texture, gc_pos, gc_size, clr)
            elseif render.image then
                render.image(current_texture, gc_pos, gc_size, clr)
            end
            
            -- Media Player UI
            if is_asmr_enabled then
                local yt_bar_height = 30
                local yt_bar_pos = gc_pos + vector(0, gc_size.y)
                local yt_bar_size = vector(gc_size.x, yt_bar_height)
                
                local yt_bg = type(color) == "function" and color(15, 15, 15, 230) or type(color) == "table" and color(15, 15, 15, 230) or nil
                local yt_red = type(color) == "function" and color(255, 0, 0, 255) or type(color) == "table" and color(255, 0, 0, 255) or nil
                local yt_white = type(color) == "function" and color(255, 255, 255, 255) or type(color) == "table" and color(255, 255, 255, 255) or nil
                local yt_gray = type(color) == "function" and color(150, 150, 150, 255) or type(color) == "table" and color(150, 150, 150, 255) or nil

                if render.rect_filled and yt_bg and yt_red then
                    -- Main bar background
                    render.rect_filled(yt_bar_pos, yt_bar_pos + yt_bar_size, yt_bg, 0)
                    
                    if not audio_playing then
                        -- Downloading Animation
                        local dl_bar_width = gc_size.x
                        local bounce_width = 60
                        local bounce_speed = 3
                        local bounce_pos = math.abs(math.sin(globals.realtime * bounce_speed)) * (dl_bar_width - bounce_width)
                        render.rect_filled(yt_bar_pos + vector(bounce_pos, 0), yt_bar_pos + vector(bounce_pos + bounce_width, 3), accent, 0)
                        
                        if render.text then
                            local dot_count = math.floor(globals.realtime * 2) % 4
                            local dots = string.rep(".", dot_count)
                            render.text(1, yt_bar_pos + vector(8, 15), yt_white, "lc", "Downloading Audio (38MB)" .. dots)
                        end
                    else
                        -- YouTube Progress bar
                        local asmr_progress = math.max(0, math.min(1, current_asmr_seek / 2224))
                        local pb_start = yt_bar_pos
                        local pb_end = yt_bar_pos + vector(gc_size.x * asmr_progress, 3)
                        render.rect_filled(pb_start, pb_end, yt_red, 0)
                        
                        -- Text elements
                        if render.text then
                            local play_icon = "||"
                            local safe_seek = math.max(0, current_asmr_seek)
                            local m = math.floor(safe_seek / 60)
                            local s = safe_seek % 60
                            local time_str = string.format("%s  %02d:%02d / 37:04", play_icon, m, s)
                            
                            render.text(1, yt_bar_pos + vector(8, 15), yt_white, "lc", time_str)
                            render.text(1, yt_bar_pos + vector(gc_size.x - 8, 15), yt_gray, "rc", "Goth Mommy ASMR")
                        end
                    end
                end
            end
            
            -- Standard sleek progress bar for image loading
            if next_switch then
                local progress = 0
                local alpha_mod = 255
                
                if is_fetching and not is_prefetching then
                    progress = 1.0
                    alpha_mod = 100 + math.floor(math.abs(math.sin(globals.realtime * 4)) * 155)
                else
                    local time_left = next_switch - globals.realtime
                    progress = 1.0 - (time_left / current_delay)
                    if progress < 0 then progress = 0 end
                    if progress > 1 then progress = 1 end
                end
                
                local bar_bg = type(color) == "function" and color(15, 15, 15, 200) or type(color) == "table" and color(15, 15, 15, 200) or nil
                local bar_accent = type(color) == "function" and color(accent.r, accent.g, accent.b, alpha_mod) or type(color) == "table" and color(accent.r, accent.g, accent.b, alpha_mod) or nil
                local glow_accent = type(color) == "function" and color(accent.r, accent.g, accent.b, math.floor(alpha_mod * 0.3)) or type(color) == "table" and color(accent.r, accent.g, accent.b, math.floor(alpha_mod * 0.3)) or nil
                
                if render.rect and bar_bg and bar_accent then
                    local bar_start_y = is_asmr_enabled and 0 or (gc_size.y - 4)
                    local bar_end_y = is_asmr_enabled and 4 or gc_size.y
                    
                    -- Background track
                    render.rect(gc_pos + vector(0, bar_start_y), gc_pos + vector(gc_size.x, bar_end_y), bar_bg, 2)
                    
                    local fill_end = gc_pos + vector(gc_size.x * progress, bar_end_y)
                    local fill_start = gc_pos + vector(0, bar_start_y)
                    
                    -- Glow layer
                    if glow_accent then
                        render.rect(fill_start - vector(0, 2), fill_end + vector(0, 2), glow_accent, 4)
                    end
                    
                    -- Animated fill
                    render.rect(fill_start, fill_end, bar_accent, 2)
                end
            end
        elseif gc_pos and gc_size and pink then
            local dark_bg = type(color) == "function" and color(25, 25, 25, 200) or type(color) == "table" and color(25, 25, 25, 200) or nil
            local white = type(color) == "function" and color(255, 255, 255, 255) or type(color) == "table" and color(255, 255, 255, 255) or nil
            local gray = type(color) == "function" and color(150, 150, 150, 255) or type(color) == "table" and color(150, 150, 150, 255) or nil
            
            if render.rect and dark_bg then
                render.rect(gc_pos, gc_pos + gc_size, dark_bg, 0)
                if render.text and white and gray then
                    render.text(1, gc_pos + vector(gc_size.x / 2, gc_size.y / 2 - 10), white, "c", "Fetching Image...")
                    local status_txt = debug_status or "Idle"
                    render.text(1, gc_pos + vector(gc_size.x / 2, gc_size.y / 2 + 10), gray, "c", "Status: " .. status_txt)
                end
            end
        end

        if menu_open and render.rect_filled and gc_pos and gc_size then
            local resize_rect_pos = gc_pos + gc_size - vector(15, 15)
            render.rect_filled(resize_rect_pos, resize_rect_pos + vector(15, 15), accent, 0)
        end
    end)
end

local function on_shutdown()
    stop_asmr()
end

if cheat and cheat.RegisterCallback then
    cheat.RegisterCallback("draw", on_render)
    cheat.RegisterCallback("destroy", on_shutdown)
elseif events then
    if events.render then events.render:set(on_render) end
    if events.shutdown then events.shutdown:set(on_shutdown) end
elseif callbacks and callbacks.Register then
    callbacks.Register("Draw", on_render)
    callbacks.Register("Unload", on_shutdown)
end
-- =========================================================================
