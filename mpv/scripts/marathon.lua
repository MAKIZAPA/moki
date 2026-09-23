-- ==========================================================
-- Modo Maratón para mpv (Anime y Series)
-- Salto automático al siguiente capítulo al terminar o con [Shift+N]
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local MEDIA_FILE = "/tmp/current_media.json"
local MARATHON_NEXT_FILE = "/tmp/marathon_next.json"

local media_info = nil
local countdown_timer = nil
local countdown_val = 5
local triggered_next = false

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

-- Obtener o inferir información de medios
local function get_media_info()
    if media_info and media_info.title and media_info.title ~= "" then
        return media_info
    end
    media_info = read_json(MEDIA_FILE)
    if media_info and media_info.title and media_info.title ~= "" then
        return media_info
    end

    -- Fallback inteligente: inferir nombre, capítulo y grupo desde el archivo en reproducción
    local raw = mp.get_property("filename") or mp.get_property("media-title") or ""
    local clean_raw = raw:gsub("%.%w+$", ""):gsub("^%b[]%s*", ""):gsub("^%(.-%)%s*", "")
    local inferred_title = raw
    local inferred_ep = 1
    local inferred_season = 1

    local n_s, s_num, e_num = clean_raw:match("^(.-)[%s%.%-_]+[Ss](%d+)[Ee](%d+)")
    if n_s then
        inferred_title = n_s:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        inferred_season = tonumber(s_num) or 1
        inferred_ep = tonumber(e_num) or 1
    else
        local n_e, ep_only = clean_raw:match("^(.-)[%s%.%-_]+[Ee](%d+)")
        if n_e then
            inferred_title = n_e:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            inferred_ep = tonumber(ep_only) or 1
        else
            local n_dash, d_ep = clean_raw:match("^(.-)%s+-%s+(%d+)")
            if n_dash then
                inferred_title = n_dash:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                inferred_ep = tonumber(d_ep) or 1
            end
        end
    end

    local g = raw:match("^%[(.-)%]") or raw:match("%-([%w_]+)%.%w+$") or raw:match("%-([%w_]+)%s*%b()") or ""

    media_info = {
        title = inferred_title,
        type = "anime",
        season = inferred_season,
        episode_num = inferred_ep,
        group = g
    }
    return media_info
end

-- Ejecutar el salto al siguiente capítulo
local function trigger_marathon_next()
    if triggered_next then return end
    local m = get_media_info()
    if not m then return end
    triggered_next = true

    if countdown_timer then
        countdown_timer:kill()
        countdown_timer = nil
    end

    local cur_ep = tonumber(m.episode_num) or 1
    local next_data = {
        next = true,
        title = m.title,
        type = m.type or "anime",
        season = tonumber(m.season) or 1,
        next_ep = cur_ep + 1,
        group = m.group or ""
    }

    write_json(MARATHON_NEXT_FILE, next_data)
    mp.osd_message(string.format(":: Modo Maraton: Cargando Capitulo %d...", cur_ep + 1), 3)
    mp.add_timeout(0.3, function()
        mp.command("quit")
    end)
end

-- Iniciar cuenta regresiva al llegar al final
local function start_countdown()
    if triggered_next or countdown_timer then return end
    countdown_val = 5

    local m = get_media_info()
    if not m then return end
    local cur_ep = tonumber(m.episode_num) or 1
    local next_ep = cur_ep + 1

    countdown_timer = mp.add_periodic_timer(1.0, function()
        if countdown_val > 0 then
            mp.osd_message(string.format(":: Fin del capitulo\n-> Capitulo %d en %ds... [ENTER ahora / 'q' salir]", 
                next_ep, countdown_val), 1.2)
            countdown_val = countdown_val - 1
        else
            trigger_marathon_next()
        end
    end)
end

-- Inicializar archivo
mp.register_event("file-loaded", function()
    media_info = read_json(MEDIA_FILE)
    triggered_next = false
    if countdown_timer then
        countdown_timer:kill()
        countdown_timer = nil
    end

    local m = get_media_info()
    if m and (m.type == "anime" or m.type == "series") then
        -- keep-open permite mostrar la cuenta regresiva en vez de cerrar en negro
        mp.set_property("keep-open", "always")
    end
end)

-- Detectar final del video (al llegar al 100% o EOF)
mp.observe_property("eof-reached", "bool", function(_, eof)
    if eof then
        local m = get_media_info()
        if m and (m.type == "anime" or m.type == "series") then
            start_countdown()
        end
    end
end)

-- Detectar si estamos a menos de 8 segundos del final
mp.observe_property("time-pos", "number", function(_, time_pos)
    if not time_pos then return end
    local duration = mp.get_property_number("duration") or 0
    if duration > 60 and time_pos >= (duration - 8) and not countdown_timer and not triggered_next then
        local m = get_media_info()
        if m and (m.type == "anime" or m.type == "series") then
            start_countdown()
        end
    end
end)

-- Atajo Shift+N: Saltar manualmente al siguiente capítulo en cualquier momento
mp.add_key_binding("N", "marathon-next", trigger_marathon_next)
mp.add_key_binding("Shift+n", "marathon-next-shift", trigger_marathon_next)
mp.add_key_binding("Shift+N", "marathon-next-shift-upper", trigger_marathon_next)

-- Atajo ENTER: Aceptar de inmediato si está la cuenta regresiva
mp.add_key_binding("ENTER", "marathon-confirm-now", function()
    local m = get_media_info()
    if countdown_timer or (m and (m.type == "anime" or m.type == "series")) then
        local percent = mp.get_property_number("percent-pos") or 0
        if percent >= 85 or countdown_timer then
            trigger_marathon_next()
        end
    end
end)
