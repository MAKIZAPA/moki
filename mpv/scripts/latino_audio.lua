-- ==========================================================
-- MOKI - Inyección de Audio Latino Web para mpv
-- Conecta al vuelo la pista de audio en Español Latino desde
-- Flixlatam / Cuevana 3 / JKAnime sobre cualquier seed de Torrent
-- Atajos: [L] o [Alt+L] Inyectar audio latino | [Alt+x] / [Alt+z] Sincronía
-- Autor: @makizapa
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local MEDIA_FILE = "/tmp/current_media.json"
local RESOLVER_BIN = os.getenv("HOME") .. "/.local/bin/latino-audio-resolver"

local is_fetching = false
local latino_injected = false

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

local function show_delay_osd()
    local delay = mp.get_property_number("audio-delay", 0)
    mp.osd_message(string.format("⏱️ Sincronía de Audio: %+.3f seg [Alt+z / Alt+x]", delay), 1.5)
end

-- Ajustes rápidos de sincronía de audio
local function delay_plus()
    local cur = mp.get_property_number("audio-delay", 0)
    mp.set_property_number("audio-delay", cur + 0.100)
    show_delay_osd()
end

local function delay_minus()
    local cur = mp.get_property_number("audio-delay", 0)
    mp.set_property_number("audio-delay", cur - 0.100)
    show_delay_osd()
end

local function delay_plus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    mp.set_property_number("audio-delay", cur + 0.500)
    show_delay_osd()
end

local function delay_minus_large()
    local cur = mp.get_property_number("audio-delay", 0)
    mp.set_property_number("audio-delay", cur - 0.500)
    show_delay_osd()
end

local function delay_reset()
    mp.set_property_number("audio-delay", 0.0)
    mp.osd_message("⏱️ Sincronía de Audio reseteada: 0.000 seg", 1.5)
end

-- Función principal para resolver e inyectar audio latino
local function fetch_and_inject_latino_audio()
    if is_fetching then
        mp.osd_message("⏳ Ya se está buscando la pista de Audio Latino...", 2)
        return
    end

    local media = read_json(MEDIA_FILE)
    local title = ""
    local season = 1
    local ep_num = 1
    local is_series = true

    if media and media.title and media.title ~= "" then
        title = media.title
        season = tonumber(media.season) or 1
        ep_num = tonumber(media.episode_num) or 1
        is_series = (media.type ~= "movie")
    else
        -- Fallback a propiedades de mpv
        local raw = mp.get_property("media-title") or mp.get_property("filename") or ""
        title = raw:gsub("%.%w+$", ""):gsub("^%b[]%s*", ""):gsub("^%(.-%)%s*", "")
    end

    if not title or title == "" then
        mp.osd_message("⚠️ No se pudo determinar el título para buscar audio latino.", 3)
        return
    end

    is_fetching = true
    local desc = title
    if is_series then
        desc = string.format("%s (T%02dE%02d)", title, season, ep_num)
    end
    mp.osd_message(string.format("🎙️ Buscando Audio Latino Web para:\n%s...", desc), 5)

    -- Ejecutar resolver en segundo plano sin congelar la reproducción
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
        if not ok or not data or data.status ~= "success" or not data.stream_url then
            local msg = (data and data.message) or "No disponible en catálogos web"
            mp.osd_message(string.format("❌ Audio Latino no encontrado:\n%s", msg), 4)
            return
        end

        local stream_url = data.stream_url
        local prov = data.provider or "Web"
        local track_title = string.format("Español Latino (Web • %s)", prov)

        -- Inyectar y seleccionar la nueva pista de audio en mpv
        mp.commandv("audio-add", stream_url, "select", track_title, "spa")
        latino_injected = true

        mp.osd_message(string.format("✅ ¡Audio Latino Web conectado con éxito!\n[# / a] Cambiar idioma | [Alt+z / Alt+x] Sincronizar desfase"), 5)
    end)
end

-- Al cargar el archivo de video
mp.register_event("file-loaded", function()
    is_fetching = false
    latino_injected = false

    -- Comprobar si las pistas de audio ya incluyen español
    local track_list = mp.get_property_native("track-list") or {}
    local has_spanish = false
    for _, t in ipairs(track_list) do
        if t.type == "audio" then
            local l = string.lower(t.lang or "")
            local title = string.lower(t.title or "")
            if l == "spa" or l == "es" or l == "es-419" or l == "es-la" or 
               title:find("latino") or title:find("spanish") or title:find("español") then
                has_spanish = true
                break
            end
        end
    end

    -- Si el torrent no tiene audio en español, mostrar sutil sugerencia OSD
    if not has_spanish then
        mp.add_timeout(2.5, function()
            if not latino_injected then
                mp.osd_message("💡 Presiona [L] para inyectar Audio Latino Web", 4)
            end
        end)
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
