-- ==========================================================
-- MOKI - Inyección de Audio Latino Web para mpv
-- Conecta al vuelo la pista de audio en Español Latino desde
-- Flixlatam / Cuevana 3 / JKAnime sobre cualquier seed de Torrent
-- Con Memoria de Sincronía Automática y Pre-carga en RAM
-- Atajos: [L] o [Alt+L] Inyectar audio latino | [Alt+x] / [Alt+z] Sincronía
-- Autor: @makizapa
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local MEDIA_FILE = "/tmp/current_media.json"
local READY_FILE = "/tmp/latino_stream_ready.json"
local SYNC_DIR = os.getenv("HOME") .. "/.config/streaming-cli"
local SYNC_OFFSETS_FILE = SYNC_DIR .. "/sync_offsets.json"
local RESOLVER_BIN = os.getenv("HOME") .. "/.local/bin/latino-audio-resolver"

local is_fetching = false
local latino_injected = false
local prefetch_timer = nil

local function read_json(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    if not content or content == "" then return nil end
    local ok, res = pcall(function() return utils.parse_json(content) end)
    if ok and res then return res end
    return nil
end

local function write_json(path, data)
    local ok, content = pcall(function() return utils.format_json(data) end)
    if not ok or not content then return false end
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function get_clean_media_title()
    local media = read_json(MEDIA_FILE)
    if media and media.title and media.title ~= "" then
        return media.title
    end
    local raw = mp.get_property("media-title") or mp.get_property("filename") or ""
    return raw:gsub("%.%w+$", ""):gsub("^%b[]%s*", ""):gsub("^%(.-%)%s*", "")
end

local function get_saved_sync_offset(title)
    if not title or title == "" then return 0.0 end
    local data = read_json(SYNC_OFFSETS_FILE)
    if not data then return 0.0 end
    local key = string.lower(title):gsub("[^%w]", "")
    return tonumber(data[key]) or 0.0
end

local function save_sync_offset(title, delay)
    if not title or title == "" then return end
    local data = read_json(SYNC_OFFSETS_FILE) or {}
    local key = string.lower(title):gsub("[^%w]", "")
    data[key] = delay
    os.execute("mkdir -p " .. SYNC_DIR)
    write_json(SYNC_OFFSETS_FILE, data)
end

local function show_delay_osd(saved)
    local delay = mp.get_property_number("audio-delay", 0)
    local label = saved and " [Guardado para esta serie]" or " [Alt+z / Alt+x]"
    mp.osd_message(string.format("⏱️ Sincronía de Audio: %+.3f seg%s", delay, label), 1.8)
end

-- Ajustes rápidos de sincronía de audio con persistencia automática
local function delay_plus()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur + 0.100
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt)
    show_delay_osd(true)
end

local function delay_minus()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur - 0.100
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt)
    show_delay_osd(true)
end

local function delay_plus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur + 0.500
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt)
    show_delay_osd(true)
end

local function delay_minus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur - 0.500
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt)
    show_delay_osd(true)
end

local function delay_reset()
    mp.set_property_number("audio-delay", 0.0)
    save_sync_offset(get_clean_media_title(), 0.0)
    mp.osd_message("⏱️ Sincronía de Audio reseteada: 0.000 seg [Guardado]", 1.8)
end

-- Inyectar y aplicar sincronía
local function inject_stream_data(data, title, is_auto)
    if latino_injected or not data then return end
    local target = data.audio_file or data.stream_url
    if not target or target == "" then return end

    local prov = data.provider or "Web"
    local mode = data.audio_file and "RAM" or "Web"
    local track_title = string.format("Español Latino (%s • %s)", mode, prov)

    mp.commandv("audio-add", target, "select", track_title, "spa")
    latino_injected = true

    -- Aplicar memoria de sincronía guardada
    local saved_delay = get_saved_sync_offset(title)
    if saved_delay ~= 0.0 then
        mp.set_property_number("audio-delay", saved_delay)
        mp.osd_message(string.format("🎙️ ¡Audio Latino conectado!\n⏱️ Sincronía recordada: %+.3fs", saved_delay), 4.5)
    else
        local intro = is_auto and "🎙️ ¡Audio Latino pre-cargado listo!" or "🎙️ ¡Audio Latino conectado con éxito!"
        mp.osd_message(string.format("%s\n[# / a] Cambiar idioma | [Alt+z / Alt+x] Sincronizar", intro), 4.5)
    end
end

-- Función manual para resolver e inyectar audio latino
local function fetch_and_inject_latino_audio()
    if latino_injected then
        -- Si ya está inyectado, alternar entre pistas fácilmente
        mp.commandv("cycle", "audio")
        return
    end

    if is_fetching then
        mp.osd_message("⏳ Ya se está buscando la pista de Audio Latino...", 2)
        return
    end

    local title = get_clean_media_title()
    if not title or title == "" then
        mp.osd_message("⚠️ No se pudo determinar el título para buscar audio latino.", 3)
        return
    end

    -- Si ya estaba pre-cargado en disco/RAM
    local ready = read_json(READY_FILE)
    if ready and ready.status == "success" and (ready.stream_url or ready.audio_file) then
        inject_stream_data(ready, title, false)
        return
    end

    is_fetching = true
    mp.osd_message(string.format("🎙️ Buscando Audio Latino Web para:\n%s...", title), 5)

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {RESOLVER_BIN}
    }, function(success, res)
        is_fetching = false

        if not success or not res or not res.stdout or res.stdout == "" then
            mp.osd_message("⚠️ Error al conectar con el resolver de audio latino.", 4)
            return
        end

        local ok, data = pcall(function() return utils.parse_json(res.stdout) end)
        if not ok or not data or data.status ~= "success" or not (data.stream_url or data.audio_file) then
            local msg = (data and data.message) or "No disponible en catálogos web"
            mp.osd_message(string.format("❌ Audio Latino no encontrado:\n%s", msg), 4)
            return
        end

        inject_stream_data(data, title, false)
    end)
end

-- Al cargar el archivo de video
mp.register_event("file-loaded", function()
    is_fetching = false
    latino_injected = false

    if prefetch_timer then
        prefetch_timer:kill()
        prefetch_timer = nil
    end

    local title = get_clean_media_title()

    -- Comprobar si las pistas de audio nativas del torrent ya incluyen español
    local track_list = mp.get_property_native("track-list") or {}
    local has_spanish = false
    for _, t in ipairs(track_list) do
        if t.type == "audio" then
            local l = string.lower(t.lang or "")
            local trk_title = string.lower(t.title or "")
            if l == "spa" or l == "es" or l == "es-419" or l == "es-la" or 
               trk_title:find("latino") or trk_title:find("spanish") or trk_title:find("español") then
                has_spanish = true
                break
            end
        end
    end

    -- Si el torrent ya tiene español nativo, no necesitamos inyectar
    if has_spanish then
        return
    end

    -- Comprobar si ya existe pre-carga lista de audio
    local ready = read_json(READY_FILE)
    if ready and ready.status == "success" and (ready.stream_url or ready.audio_file) then
        mp.add_timeout(1.0, function()
            inject_stream_data(ready, title, true)
        end)
        return
    end

    -- Si no está listo de inmediato, consultar periódicamente por si se está pre-descargando en segundo plano
    local check_attempts = 0
    prefetch_timer = mp.add_periodic_timer(1.0, function()
        check_attempts = check_attempts + 1
        if latino_injected or check_attempts > 12 then
            if prefetch_timer then
                prefetch_timer:kill()
                prefetch_timer = nil
            end
            return
        end

        local r = read_json(READY_FILE)
        if r and r.status == "success" and (r.stream_url or r.audio_file) then
            if prefetch_timer then
                prefetch_timer:kill()
                prefetch_timer = nil
            end
            inject_stream_data(r, title, true)
        end
    end)

    -- Sugerencia sutil si pasan 4 segundos y aún no se ha inyectado
    mp.add_timeout(3.5, function()
        if not latino_injected and not is_fetching then
            mp.osd_message("💡 Presiona [L] para inyectar Audio Latino Web", 3.5)
        end
    end)
end)

-- Limpieza al cerrar o cambiar de archivo
mp.register_event("end-file", function()
    if prefetch_timer then
        prefetch_timer:kill()
        prefetch_timer = nil
    end
end)

-- Registrar bindings de script
mp.add_key_binding("l", "toggle_latino_audio", fetch_and_inject_latino_audio)
mp.add_key_binding("L", "toggle_latino_audio_upper", fetch_and_inject_latino_audio)
mp.add_key_binding("Alt+l", "toggle_latino_audio_alt", fetch_and_inject_latino_audio)

mp.add_key_binding("Alt+x", "delay_plus", delay_plus)
mp.add_key_binding("Alt+z", "delay_minus", delay_minus)
mp.add_key_binding("Alt+X", "delay_plus_large", delay_plus_large)
mp.add_key_binding("Alt+Z", "delay_minus_large", delay_minus_large)
mp.add_key_binding("Alt+0", "delay_reset", delay_reset)
