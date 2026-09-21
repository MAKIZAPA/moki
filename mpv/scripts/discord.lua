-- ==========================================================
-- Discord Rich Presence for mpv (Ultra-ligero, 100% seguro)
-- Utiliza LuaJIT FFI nativo sin dependencias externas ni pip.
-- ==========================================================

local ffi = require("ffi")
local mp = require("mp")

ffi.cdef[[
    int socket(int domain, int type, int protocol);
    int connect(int sockfd, const void *addr, unsigned int addrlen);
    int close(int fd);
    long write(int fd, const void *buf, unsigned long count);
    long read(int fd, void *buf, unsigned long count);
    int getuid(void);
    struct sockaddr_un {
        unsigned short sun_family;
        char sun_path[108];
    };
]]

local CLIENT_ID = "737663962677510245"
local socket_fd = -1
local last_update_time = 0
local uid = ffi.C.getuid()

-- Localizar el socket de Discord en Linux
local function find_discord_socket()
    local paths = {
        "/run/user/" .. tostring(uid) .. "/discord-ipc-0",
        "/run/user/" .. tostring(uid) .. "/app/com.discordapp.Discord/discord-ipc-0",
        "/tmp/discord-ipc-0"
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            f:close()
            return p
        end
    end
    return paths[1]
end

-- Conectar con Discord
local function connect_discord()
    if socket_fd >= 0 then
        pcall(function() ffi.C.close(socket_fd) end)
        socket_fd = -1
    end

    local path = find_discord_socket()
    local fd = ffi.C.socket(1, 1, 0) -- AF_UNIX=1, SOCK_STREAM=1
    if fd < 0 then return false end

    local addr = ffi.new("struct sockaddr_un")
    addr.sun_family = 1
    ffi.copy(addr.sun_path, path)

    local res = ffi.C.connect(fd, addr, ffi.sizeof("struct sockaddr_un"))
    if res ~= 0 then
        ffi.C.close(fd)
        return false
    end

    -- Handshake (Opcode 0)
    local payload = '{"v":1,"client_id":"' .. CLIENT_ID .. '"}'
    local header = ffi.new("uint32_t[2]", {0, #payload})
    ffi.C.write(fd, header, 8)
    ffi.C.write(fd, payload, #payload)

    -- Leer confirmación de Discord
    local resp_hdr = ffi.new("uint32_t[2]")
    local read_bytes = ffi.C.read(fd, resp_hdr, 8)
    if read_bytes < 8 then
        ffi.C.close(fd)
        return false
    end

    local resp_len = resp_hdr[1]
    if resp_len > 0 and resp_len < 65536 then
        local resp_buf = ffi.new("char[?]", resp_len + 1)
        ffi.C.read(fd, resp_buf, resp_len)
    end

    socket_fd = fd
    return true
end

-- Escapar texto para formato JSON seguro
local function json_escape(str)
    if not str then return "" end
    str = str:gsub('\\', '\\\\')
    str = str:gsub('"', '\\"')
    str = str:gsub('\n', ' ')
    str = str:gsub('\r', '')
    str = str:gsub('\t', ' ')
    return str
end

-- Limpiar títulos feos de torrents para que se vean bonitos en Discord
local function sanitize_title(title)
    if not title or title == "" then 
        return "Reproduciendo video", "Streaming en vivo" 
    end

    -- Quitar ruta de archivo si viene con directorios
    title = title:match("([^/\\]+)$") or title

    -- Quitar extensión (.mkv, .mp4, etc.)
    title = title:gsub("%.%w%w%w?%w?$", "")

    -- Detectar formato de Serie: S01E02 / T01E02 / 1x02
    local s, e = title:match("[SsTt](%d+)[Ee](%d+)")
    if not s then
        s, e = title:match("(%d+)[xX](%d+)")
    end
    if s and e then
        local name = title:match("^(.-)%s*[SsTt]%d+[Ee]%d+") or title:match("^(.-)%s*%d+[xX]%d+") or title
        name = name:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", ""):gsub("[%._]", " "):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
        if #name == 0 then name = "Serie" end
        return name, "Temporada " .. tonumber(s) .. " • Episodio " .. tonumber(e)
    end

    -- Detectar formato Anime con grupo y capítulo: ej. [PuyaSubs!] Dandadan - 01
    local anime_name, ep = title:match("^%[?.-%]?%s*([%w%s%-%_]+)%s*-%s*(%d%d?)")
    if anime_name and ep then
        anime_name = anime_name:gsub("^%s*(.-)%s*$", "%1")
        return anime_name, "Episodio " .. tonumber(ep)
    end

    -- Películas: Limpiar etiquetas de resolución, codecs y grupos
    local clean = title:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", "")
    clean = clean:gsub("[%._]", " ")
    clean = clean:gsub("%b()", "")
    clean = clean:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

    if #clean > 1 then
        return clean, "Película"
    end
    return title, "Reproduciendo"
end

-- Leer metadatos limpios y póster si existen (creados por serie o anime)
local function get_custom_metadata()
    local f = io.open("/tmp/current_media.json", "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    if not content or content == "" then return nil end

    local title = content:match('"title"%s*:%s*"([^"]+)"')
    local episode = content:match('"episode"%s*:%s*"([^"]+)"')
    local poster = content:match('"poster"%s*:%s*"([^"]+)"')
    return {
        title = title,
        episode = episode,
        poster = poster
    }
end

-- Capitalizar palabras si vienen en minúsculas (ej. "black torch" -> "Black Torch")
local function capitalize_words(str)
    if not str or str == "" then return "" end
    if not str:find("[A-Z]") then
        return (str:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end))
    end
    return str
end

-- Enviar presencia a Discord
local function update_presence()
    local now = os.time()
    -- Throttle para no saturar Discord (máximo 1 envío por segundo)
    if now - last_update_time < 1 then return end
    last_update_time = now

    if socket_fd < 0 then
        if not connect_discord() then return end
    end

    local title = mp.get_property("media-title")
    if not title or title == "" then
        title = mp.get_property("filename")
    end
    if not title or title == "" then return end

    local is_paused = mp.get_property_bool("pause", false)
    local time_pos = mp.get_property_number("time-pos", 0) or 0
    local duration = mp.get_property_number("duration", 0) or 0

    local custom = get_custom_metadata()
    local activity_name, details, state, large_image, large_text

    if custom and custom.title and custom.title ~= "" then
        activity_name = capitalize_words(custom.title)
        details = custom.episode or "Reproduciendo"
        state = is_paused and "En pausa" or "Reproduciendo"
        if custom.poster and custom.poster:find("^https?://") then
            large_image = custom.poster
            large_text = activity_name
        else
            large_image = "mpv"
            large_text = activity_name
        end
    else
        local clean_title, sub = sanitize_title(title)
        activity_name = capitalize_words(clean_title)
        details = sub or "Reproduciendo"
        state = is_paused and "En pausa" or "Reproduciendo"
        large_image = "mpv"
        large_text = activity_name
    end

    local ts_json = ""
    if not is_paused and duration > 0 and time_pos >= 0 then
        local start_ts = math.floor(now - time_pos)
        local end_ts = math.floor(now - time_pos + duration)
        ts_json = string.format(',"timestamps":{"start":%d,"end":%d}', start_ts, end_ts)
    elseif is_paused and duration > 0 then
        local cur_m = math.floor(time_pos / 60)
        local cur_s = math.floor(time_pos % 60)
        local dur_m = math.floor(duration / 60)
        local dur_s = math.floor(duration % 60)
        state = string.format("Pausa (%02d:%02d / %02d:%02d)", cur_m, cur_s, dur_m, dur_s)
    end

    local small_icon = is_paused and "pause" or "play"
    local small_text = is_paused and "En pausa" or "Reproduciendo"

    local payload = string.format(
        '{"cmd":"SET_ACTIVITY","args":{"pid":%d,"activity":{"name":"%s","type":3,"details":"%s","state":"%s"%s,"assets":{"large_image":"%s","large_text":"%s","small_image":"%s","small_text":"%s"}}},"nonce":"%d"}',
        uid,
        json_escape(activity_name),
        json_escape(details),
        json_escape(state),
        ts_json,
        json_escape(large_image),
        json_escape(large_text),
        small_icon,
        small_text,
        now
    )

    local header = ffi.new("uint32_t[2]", {1, #payload})
    local w1 = ffi.C.write(socket_fd, header, 8)
    local w2 = ffi.C.write(socket_fd, payload, #payload)

    if w1 < 0 or w2 < 0 then
        pcall(function() ffi.C.close(socket_fd) end)
        socket_fd = -1
    end
end

-- Limpiar presencia al cerrar mpv
local function cleanup_presence()
    if socket_fd >= 0 then
        pcall(function()
            local payload = string.format('{"cmd":"SET_ACTIVITY","args":{"pid":%d,"activity":null},"nonce":"end"}', uid)
            local header = ffi.new("uint32_t[2]", {1, #payload})
            ffi.C.write(socket_fd, header, 8)
            ffi.C.write(socket_fd, payload, #payload)
            ffi.C.close(socket_fd)
        end)
        socket_fd = -1
    end
end

-- Eventos de mpv
mp.register_event("file-loaded", function()
    last_update_time = 0
    update_presence()
end)

mp.observe_property("pause", "bool", function()
    update_presence()
end)

mp.observe_property("playback-time", "number", function()
    -- Actualizar cada 15 segundos o si hay cambios
    local now = os.time()
    if now - last_update_time >= 15 then
        update_presence()
    end
end)

mp.register_event("shutdown", cleanup_presence)
