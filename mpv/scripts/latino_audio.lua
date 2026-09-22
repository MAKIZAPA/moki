-- ==========================================================
-- MOKI - Inyección de Audio Latino Web para mpv
-- Conecta al vuelo la pista de audio en Español Latino desde
-- Flixlatam / Cuevana 3 / JKAnime sobre cualquier seed de Torrent
-- Con Sincronización Automática Acústica y Memoria por Serie
-- Atajos: [L] Alternar / Recargar | [Alt+x] / [Alt+z] Sincronía fina
-- Autor: @makizapa
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local MEDIA_FILE = "/tmp/current_media.json"
local READY_FILE = "/tmp/latino_stream_ready.json"
local SYNC_DIR = os.getenv("HOME") .. "/.config/streaming-cli"
local SYNC_OFFSETS_FILE = SYNC_DIR .. "/sync_offsets.json"
local RESOLVER_BIN = os.getenv("HOME") .. "/.local/bin/latino-audio-resolver"
local ALIGNER_BIN = os.getenv("HOME") .. "/.local/bin/audio-aligner"

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

-- Cálculo y detección inteligente de sincronía por serie y distribuidora
local function calculate_smart_delay(title)
    -- 1. Si ya existe un valor recordado para esta serie
    local saved = get_saved_sync_offset(title)
    if saved ~= 0.0 then
        return saved, "recordada"
    end

    -- 2. Detección automática por tags de distribuidora en nombre de archivo / release
    local raw_title = mp.get_property("media-title") or mp.get_property("filename") or ""
    local media = read_json(MEDIA_FILE) or {}
    local full_ctx = string.upper(table.concat({
        raw_title,
        media.release_title or "",
        media.title or "",
        title or ""
    }, " "))

    local detected_delay = 0.0
    local label = "estándar"

    if full_ctx:find("AMZN") or full_ctx:find("AMAZON") or full_ctx:find("EDITH") or full_ctx:find("PRIME") then
        detected_delay = -2.300
        label = "Amazon Prime Video"
    elseif full_ctx:find("HMAX") or full_ctx:find("HBOMAX") or full_ctx:find("HBO") then
        detected_delay = -3.000
        label = "HBO Max"
    elseif full_ctx:find("DSNP") or full_ctx:find("DISNEY") then
        detected_delay = -2.500
        label = "Disney+"
    elseif full_ctx:find("NF%.") or full_ctx:find("NETFLIX") or full_ctx:find("NF[%.%-_]") then
        detected_delay = -4.000
        label = "Netflix"
    elseif full_ctx:find("ATVP") or full_ctx:find("APPLE") then
        detected_delay = -2.000
        label = "Apple TV+"
    elseif full_ctx:find("HULU") then
        detected_delay = -2.500
        label = "Hulu"
    elseif full_ctx:find("PARAMOUNT") or full_ctx:find("PMTP") then
        detected_delay = -2.500
        label = "Paramount+"
    end

    if detected_delay ~= 0.0 then
        save_sync_offset(title, detected_delay)
        return detected_delay, label
    end

    return 0.0, "estándar"
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

    -- Aplicar sincronía automática inteligente
    local smart_delay, label = calculate_smart_delay(title)
    if smart_delay ~= 0.0 then
        mp.set_property_number("audio-delay", smart_delay)
        mp.osd_message(string.format("🎙️ ¡Audio Latino conectado!\n⏱️ Sincronía automática: %+.3fs [%s]", smart_delay, label), 4.5)
    else
        mp.osd_message("🎙️ ¡Audio Latino conectado!\n⏱️ Sincronía: 0.000s [Estándar]", 4.0)
    end

    -- Iniciar alineador acústico en segundo plano para calibración fina matemática (FFT)
    local video_path = mp.get_property("path") or ""
    if video_path ~= "" and target ~= "" and utils.file_info(ALIGNER_BIN) then
        mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            capture_stdout = false,
            capture_stderr = false,
            args = {ALIGNER_BIN, video_path, target, title or ""}
        }, function() end)
    end
end

-- Función para resolver e inyectar audio latino
local function fetch_and_inject_latino_audio()
    if latino_injected then
        mp.commandv("cycle", "audio")
        return
    end

    if is_fetching then
        mp.osd_message("⏳ Ya se está conectando la pista de Audio Latino...", 2)
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
    mp.osd_message(string.format("🎙️ Conectando Audio Latino Web para:\n%s...", title), 4)

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
        mp.add_timeout(0.5, function()
            inject_stream_data(ready, title, true)
        end)
        return
    end

    -- Si aún no está listo, mostrar OSD discreto de conexión y chequear prefetch
    mp.osd_message("🎙️ Conectando Audio Latino Web en segundo plano...", 3.0)

    local check_attempts = 0
    prefetch_timer = mp.add_periodic_timer(0.6, function()
        check_attempts = check_attempts + 1
        if latino_injected then
            if prefetch_timer then prefetch_timer:kill(); prefetch_timer = nil end
            return
        end

        local r = read_json(READY_FILE)
        if r and r.status == "success" and (r.stream_url or r.audio_file) then
            if prefetch_timer then prefetch_timer:kill(); prefetch_timer = nil end
            inject_stream_data(r, title, true)
            return
        end

        -- Si pasaron ~3 segundos (5 intentos) y no había pre-carga iniciada, arrancar la búsqueda automáticamente
        if check_attempts >= 5 then
            if prefetch_timer then prefetch_timer:kill(); prefetch_timer = nil end
            if not latino_injected and not is_fetching then
                fetch_and_inject_latino_audio()
            end
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
