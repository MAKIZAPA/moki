-- ==========================================================
-- MOKI - Inyección de Audio Latino Web para mpv
-- Conecta al vuelo la pista de audio en Español Latino desde
-- Flixlatam / Cuevana 3 / JKAnime sobre cualquier seed de Torrent
-- Con Sincronización Automática por Proveedor (Flix 0.0s / Cuevana -2.3s)
-- y Memoria Persistente Independiente por Serie y Servidor.
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
local current_provider = "FLIX"

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

local function is_ready_for_media(ready_data)
    if not ready_data or ready_data.status ~= "success" or not (ready_data.stream_url or ready_data.audio_file) then
        return false
    end
    local media = read_json(MEDIA_FILE)
    if media then
        if media.season and ready_data.season and tonumber(media.season) ~= tonumber(ready_data.season) then
            return false
        end
        if media.episode_num and ready_data.episode and tonumber(media.episode_num) ~= tonumber(ready_data.episode) then
            return false
        end
    end
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

local function get_provider_key(title, provider)
    local c_title = string.lower(title or ""):gsub("[^%w]", "")
    local c_prov = string.upper(provider or current_provider or "FLIX"):gsub("[^%w]", "")
    return c_title .. "__" .. c_prov
end

local function get_saved_sync_offset(title, provider)
    if not title or title == "" then return nil end
    local data = read_json(SYNC_OFFSETS_FILE)
    if not data then return nil end

    local p_key = get_provider_key(title, provider)
    if data[p_key] ~= nil then
        return tonumber(data[p_key])
    end

    -- Fallback a clave tradicional si existe
    local simple_key = string.lower(title):gsub("[^%w]", "")
    if data[simple_key] ~= nil then
        return tonumber(data[simple_key])
    end

    return nil
end

local function save_sync_offset(title, delay, provider)
    if not title or title == "" then return end
    local data = read_json(SYNC_OFFSETS_FILE) or {}
    local p_key = get_provider_key(title, provider)
    data[p_key] = delay
    os.execute("mkdir -p " .. SYNC_DIR)
    write_json(SYNC_OFFSETS_FILE, data)
end

local function show_delay_osd(saved)
    local delay = mp.get_property_number("audio-delay", 0)
    local prov_tag = current_provider or "Web"
    local label = saved and string.format(" [Guardado para %s]", prov_tag) or " [Alt+z / Alt+x]"
    mp.osd_message(string.format(":: Sincronia de Audio: %+.3f seg%s", delay, label), 1.8)
end

-- Cálculo y detección inteligente de sincronía por serie y distribuidora
local function calculate_smart_delay(title, provider)
    local prov = string.upper(provider or current_provider or "FLIX")

    -- 1. Si ya existe un valor recordado para esta serie y este proveedor
    local saved = get_saved_sync_offset(title, prov)
    if saved ~= nil then
        return saved, "recordada (" .. prov .. ")"
    end

    -- 2. Regla de oro para FLIX (FlixLatam):
    -- FlixLatam entrega ripeos WEB-DL puros 1:1 con las cortinillas idénticas al torrent original
    if prov:find("FLIX") then
        save_sync_offset(title, 0.0, prov)
        return 0.0, "FlixLatam 1:1 (Sin desfase)"
    end

    -- 3. Si el proveedor es Cuevana 3 (u otro que recorta intros), aplicar compensación del logo
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
        label = "Cuevana 3 (Logo Amazon Prime)"
    elseif full_ctx:find("HMAX") or full_ctx:find("HBOMAX") or full_ctx:find("HBO") then
        detected_delay = -3.000
        label = "Cuevana 3 (Logo HBO Max)"
    elseif full_ctx:find("DSNP") or full_ctx:find("DISNEY") then
        detected_delay = -2.500
        label = "Cuevana 3 (Logo Disney+)"
    elseif full_ctx:find("NF%.") or full_ctx:find("NETFLIX") or full_ctx:find("NF[%.%-_]") then
        detected_delay = -4.000
        label = "Cuevana 3 (Logo Netflix)"
    elseif full_ctx:find("ATVP") or full_ctx:find("APPLE") then
        detected_delay = -2.000
        label = "Cuevana 3 (Logo Apple TV+)"
    elseif full_ctx:find("HULU") then
        detected_delay = -2.500
        label = "Cuevana 3 (Logo Hulu)"
    elseif full_ctx:find("PARAMOUNT") or full_ctx:find("PMTP") then
        detected_delay = -2.500
        label = "Cuevana 3 (Logo Paramount+)"
    end

    save_sync_offset(title, detected_delay, prov)
    return detected_delay, label
end

-- Ajustes rápidos de sincronía de audio con persistencia automática por proveedor
local function delay_plus()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur + 0.100
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt, current_provider)
    show_delay_osd(true)
end

local function delay_minus()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur - 0.100
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt, current_provider)
    show_delay_osd(true)
end

local function delay_plus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur + 0.500
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt, current_provider)
    show_delay_osd(true)
end

local function delay_minus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    local nxt = cur - 0.500
    mp.set_property_number("audio-delay", nxt)
    save_sync_offset(get_clean_media_title(), nxt, current_provider)
    show_delay_osd(true)
end

local function delay_reset()
    mp.set_property_number("audio-delay", 0.0)
    save_sync_offset(get_clean_media_title(), 0.0, current_provider)
    mp.osd_message(string.format(":: Sincronia reseteada: 0.000 seg [Guardado para %s]", current_provider), 1.8)
end

-- Inyectar y aplicar sincronía
local function inject_stream_data(data, title, is_auto)
    if latino_injected or not data then return end
    local target = data.audio_file or data.stream_url
    if not target or target == "" then return end

    local prov = data.provider or "Web"
    current_provider = prov
    local mode = data.audio_file and "RAM" or "Web"
    local track_title = string.format("Español Latino (%s • %s)", mode, prov)

    -- Preservar el id de video original para evitar que streams HLS externos alteren la pista de video
    local cur_vid = mp.get_property("vid")

    local res, err = mp.command_native({
        name = "audio-add",
        url = target,
        flags = "select",
        title = track_title,
        lang = "spa"
    })

    if err then
        pcall(function() os.remove(READY_FILE) end)
        latino_injected = false
        mp.osd_message(string.format("[!] Error al conectar pista de audio (%s)", tostring(err)), 4.0)
        return
    end

    latino_injected = true

    -- Restaurar video original si el stream multiplexado intentó cambiar de video
    if cur_vid and cur_vid ~= "no" then
        mp.set_property("vid", cur_vid)
    end

    -- Asegurar explícitamente la selección de la pista de audio inyectada
    local track_list = mp.get_property_native("track-list") or {}
    for _, t in ipairs(track_list) do
        if t.type == "audio" and (t.external or (t.title and t.title:find("Español Latino"))) then
            if not t.selected then
                mp.set_property("aid", tostring(t.id))
            end
            break
        end
    end

    -- Aplicar sincronía automática inteligente por proveedor
    local smart_delay, label = calculate_smart_delay(title, prov)
    mp.set_property_number("audio-delay", smart_delay)
    if smart_delay ~= 0.0 then
        mp.osd_message(string.format(":: Audio Latino conectado\n-> Sincronia automatica: %+.3fs [%s]", smart_delay, label), 4.5)
    else
        mp.osd_message(string.format(":: Audio Latino conectado\n-> Sincronia perfecta: 0.000s [%s]", label), 4.0)
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
        mp.add_timeout(0.15, function()
            local aid = mp.get_property("aid") or "1"
            local lang = mp.get_property("current-tracks/audio/lang") or ""
            local trk_title = mp.get_property("current-tracks/audio/title") or ""
            local display_name = trk_title ~= "" and trk_title or (lang ~= "" and lang or ("Pista " .. aid))
            mp.osd_message(string.format(":: Pista de audio activa: %s [Pista %s]", display_name, aid), 2.5)
        end)
        return
    end

    if is_fetching then
        mp.osd_message(":: Conectando pista de Audio Latino...", 2)
        return
    end

    local title = get_clean_media_title()
    if not title or title == "" then
        mp.osd_message("[!] No se pudo determinar el titulo para buscar audio latino.", 3)
        return
    end

    -- Si ya estaba pre-cargado en disco/RAM y corresponde al medio actual
    local ready = read_json(READY_FILE)
    if is_ready_for_media(ready) then
        inject_stream_data(ready, title, false)
        return
    end

    is_fetching = true
    mp.osd_message(string.format(":: Conectando Audio Latino Web para:\n%s...", title), 4)

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {RESOLVER_BIN}
    }, function(success, res)
        is_fetching = false

        if not success or not res or not res.stdout or res.stdout == "" then
            mp.osd_message("[!] Error al conectar con el resolver de audio latino.", 4)
            return
        end

        local ok, data = pcall(function() return utils.parse_json(res.stdout) end)
        if not ok or not data or data.status ~= "success" or not (data.stream_url or data.audio_file) then
            local msg = (data and data.message) or "No disponible en catálogos web"
            mp.osd_message(string.format("[-] Audio Latino no encontrado:\n%s", msg), 4)
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
    if is_ready_for_media(ready) then
        mp.add_timeout(0.5, function()
            inject_stream_data(ready, title, true)
        end)
        return
    end

    -- Si aún no está listo, mostrar OSD discreto de conexión y chequear prefetch
    mp.osd_message(":: Conectando Audio Latino Web en segundo plano...", 3.0)

    local check_attempts = 0
    prefetch_timer = mp.add_periodic_timer(0.6, function()
        check_attempts = check_attempts + 1
        if latino_injected then
            if prefetch_timer then prefetch_timer:kill(); prefetch_timer = nil end
            return
        end

        local r = read_json(READY_FILE)
        if is_ready_for_media(r) then
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
