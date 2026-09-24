-- ==========================================================
-- Historial y Reanudación Inteligente para mpv
-- Guarda la posición exacta donde te quedaste.
-- Si superas el 90%, avanza al siguiente capítulo automáticamente.
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local HISTORY_FILE = os.getenv("HOME") .. "/.config/streaming-cli/history.json"
local MEDIA_FILE = "/tmp/current_media.json"

-- Mínimo de tiempo reproducido (en segundos) para registrar en el historial
-- 120 segundos (2 minutos) evita que pruebas rápidas de semillas ensucien 'continuar'
local MIN_WATCH_TIME = 120

local last_pos = 0
local last_dur = 0

-- Rastrear tiempo y duración continuamente (en 'shutdown' mpv ya descargó el archivo y devuelve nil)
mp.observe_property("time-pos", "number", function(_, v)
    if v and v > 0 then last_pos = v end
end)

mp.observe_property("duration", "number", function(_, v)
    if v and v > 0 then last_dur = v end
end)

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

-- Reanudar en el segundo guardado al abrir el video y fijar titulo limpio para MPRIS
mp.register_event("file-loaded", function()
    local media = read_json(MEDIA_FILE)
    if media and media.title and media.title ~= "" then
        local display_title = media.title
        local ep = tonumber(media.episode_num) or tonumber(media.episode)
        local season = tonumber(media.season)
        if ep then
            if season and season > 1 then
                display_title = string.format("%s - T%02dE%02d", media.title, season, ep)
            else
                display_title = string.format("%s - Episodio %s", media.title, tostring(ep))
            end
        elseif media.episode and tostring(media.episode) ~= "" then
            display_title = string.format("%s - %s", media.title, tostring(media.episode))
        end
        mp.set_property("force-media-title", display_title)
    end

    if not media then return end

    local st = tonumber(media.start_time)
    if st and st > 5 then
        -- Delay de 0.8s para que el stream inicialice el demuxer
        mp.add_timeout(0.8, function()
            mp.commandv("seek", st, "absolute", "exact")
            local m = math.floor(st / 60)
            local s = math.floor(st % 60)
            mp.osd_message(string.format(":: Reanudando en %02d:%02d", m, s), 4)
        end)
    end
end)

-- Función principal para guardar el progreso
local function save_progress()
    local media = read_json(MEDIA_FILE) or {}
    local title = media.title
    local inferred_ep = nil
    local inferred_season = nil

    if not title or title == "" then
        local raw = mp.get_property("media-title") or mp.get_property("filename") or ""
        -- Eliminar extensión .mkv, .mp4, etc.
        raw = raw:gsub("%.%w+$", "")
        local clean_raw = raw:gsub("^%b[]%s*", ""):gsub("^%(.-%)%s*", "")
        -- Buscar patrón S01E09 o E09 en el nombre de archivo crudo
        local n_s, s_num, e_num = clean_raw:match("^(.-)[%s%.%-_]+[Ss](%d+)[Ee](%d+)")
        if n_s then
            title = n_s:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            inferred_season = tonumber(s_num)
            inferred_ep = tonumber(e_num)
        else
            local n_e, ep_only = clean_raw:match("^(.-)[%s%.%-_]+[Ee](%d+)")
            if n_e then
                title = n_e:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                inferred_ep = tonumber(ep_only)
            else
                local n_dash, d_ep = clean_raw:match("^(.-)%s+-%s+(%d+)")
                if n_dash then
                    title = n_dash:gsub("[%._]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                    inferred_ep = tonumber(d_ep)
                else
                    title = raw
                end
            end
        end
    end
    if not title or title == "" then return end

    local time_pos = last_pos
    local duration = last_dur

    -- Solo guardar en el historial si se reprodujeron al menos MIN_WATCH_TIME (2 minutos)
    -- Si solo estabas probando semillas, audio o subtítulos y saliste rápido, no ensucia 'continuar'
    if time_pos < MIN_WATCH_TIME then return end

    local percent = 0
    if duration > 0 then
        percent = (time_pos / duration) * 100
    end

    local history = read_json(HISTORY_FILE) or {}
    local key = title:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    if key == "" then key = "video" end

    local fn = mp.get_property("filename") or ""
    local seed_title = ""
    if fn ~= "" and (fn:find("%.") or fn:find("%-")) then
        seed_title = fn
    elseif media.release_title and media.release_title ~= "" then
        seed_title = media.release_title
    else
        seed_title = title
    end

    local entry = history[key] or {}
    entry.title = seed_title
    entry.clean_title = title
    entry.type = media.type or "anime"
    entry.poster = media.poster or entry.poster or ""
    entry.updated_at = os.time()
    entry.size_gb = media.size_gb or entry.size_gb or 0
    entry.file_idx = media.file_idx or entry.file_idx or ""
    entry.mal_id = media.mal_id or entry.mal_id or 0
    entry.imdb_id = media.imdb_id or entry.imdb_id or ""
    entry.res = media.res or entry.res or ""
    entry.lang_score = media.lang_score or entry.lang_score or 0
    local function extract_group(raw)
        if not raw or raw == "" then return "" end
        local g1 = raw:match("^%[(.-)%]")
        if g1 and g1 ~= "" then return g1 end
        local g2 = raw:match("%-([%w_]+)%.%w+$") or raw:match("%-([%w_]+)%s*%b()") or raw:match("%-([%w_]+)$")
        if g2 and g2 ~= "" then return g2 end
        return ""
    end

    local valid_group = ""
    if media.group and media.group ~= "" then
        valid_group = media.group
    elseif entry.group and entry.group ~= "" then
        valid_group = entry.group
    else
        valid_group = extract_group(mp.get_property("filename"))
        if valid_group == "" then
            valid_group = extract_group(mp.get_property("media-title"))
        end
    end
    entry.group = valid_group

    local valid_rel_title = ""
    if media.release_title and media.release_title ~= "" then
        valid_rel_title = media.release_title
    elseif entry.release_title and entry.release_title ~= "" then
        valid_rel_title = entry.release_title
    else
        valid_rel_title = mp.get_property("filename") or ""
    end
    entry.release_title = valid_rel_title

    local is_series_or_anime = (entry.type == "anime" or entry.type == "series")
    local cur_ep = tonumber(media.episode_num) or tonumber(media.episode) or inferred_ep or entry.episode or 1
    local cur_season = tonumber(media.season) or inferred_season or entry.season or 1

    entry.season = cur_season

    -- Regla del 90%: Si ya viste el 90% o más, se considera completado
    if percent >= 90 then
        if is_series_or_anime then
            entry.episode = cur_ep + 1
            entry.time_pos = 0
            entry.duration = 0
            entry.percent = 0
            entry.completed = false
            entry.next_ready = true
            entry.last_completed_ep = cur_ep
            entry.magnet = "" -- Siguiente capítulo requiere nueva búsqueda
        else
            entry.time_pos = math.floor(time_pos)
            entry.duration = math.floor(duration)
            entry.percent = math.floor(percent)
            entry.completed = true
            entry.next_ready = false
            entry.magnet = media.magnet or entry.magnet or ""
        end
    else
        entry.episode = cur_ep
        entry.time_pos = math.floor(time_pos)
        entry.duration = math.floor(duration)
        entry.percent = math.floor(percent)
        entry.completed = false
        entry.next_ready = false
        entry.magnet = media.magnet or entry.magnet or ""
    end

    history[key] = entry
    write_json(HISTORY_FILE, history)
end

-- Guardar en los eventos de mpv
mp.register_event("shutdown", save_progress)
mp.register_event("end-file", save_progress)

-- Guardar automáticamente cada vez que se pone pausa
mp.observe_property("pause", "bool", function(_, paused)
    if paused then
        save_progress()
    end
end)

-- Auto-guardado periódico cada 20 segundos
mp.add_periodic_timer(20, function()
    save_progress()
end)
