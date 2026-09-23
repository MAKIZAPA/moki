-- ==========================================================
-- AniSkip para mpv (Detección y salto de Openings / Endings)
-- Usa la API pública de AniSkip + MyAnimeList ID
-- Atajos: [TAB] Salta el opening/ending | [Ctrl+s] Auto-skip ON/OFF
-- ==========================================================

local mp = require("mp")
local utils = require("mp.utils")

local MEDIA_FILE = "/tmp/current_media.json"

local op_start = nil
local op_end = nil
local ed_start = nil
local ed_end = nil

local auto_skip_op = false
local op_skipped = false
local notified_op = false
local notified_ed = false

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

local function format_time(sec)
    sec = math.floor(sec or 0)
    return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local function fetch_skip_times(mal_id, ep_num)
    if not mal_id or mal_id == 0 or not ep_num or ep_num == 0 then return end

    local url = string.format(
        "https://api.aniskip.com/v2/skip-times/%d/%d?types[]=op&types[]=ed&types[]=recap&types[]=mixed-op&types[]=mixed-ed&episodeLength=0",
        mal_id, ep_num
    )

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = false,
        args = {"curl", "-s", "--max-time", "5", url}
    }, function(success, res)
        if not success or not res or not res.stdout or res.stdout == "" then return end

        local ok, data = pcall(function() return utils.parse_json(res.stdout) end)
        if not ok or not data or not data.found or not data.results then return end

        for _, item in ipairs(data.results) do
            local st = item.skipType
            local interval = item.interval
            if interval and interval.startTime and interval.endTime then
                if st == "op" or st == "mixed-op" then
                    op_start = interval.startTime
                    op_end = interval.endTime
                elseif st == "ed" or st == "mixed-ed" then
                    ed_start = interval.startTime
                    ed_end = interval.endTime
                end
            end
        end

        if op_start and op_end then
            mp.osd_message(string.format(":: AniSkip listo: Opening en %s -> %s ([TAB] para saltar)", 
                format_time(op_start), format_time(op_end)), 4)
        end
    end)
end

-- Al cargar el archivo
mp.register_event("file-loaded", function()
    op_start = nil
    op_end = nil
    ed_start = nil
    ed_end = nil
    op_skipped = false
    notified_op = false
    notified_ed = false

    local media = read_json(MEDIA_FILE)
    if not media or media.type ~= "anime" then return end

    local mal_id = tonumber(media.mal_id)
    local ep_num = tonumber(media.episode_num) or 1
    if mal_id and mal_id > 0 then
        fetch_skip_times(mal_id, ep_num)
    end
end)

-- Comprobar si estamos en Opening o Ending durante la reproducción
mp.observe_property("time-pos", "number", function(_, time_pos)
    if not time_pos then return end

    -- Comprobar Opening
    if op_start and op_end and time_pos >= op_start and time_pos < op_end then
        if auto_skip_op and not op_skipped then
            op_skipped = true
            mp.commandv("seek", op_end, "absolute", "exact")
            mp.osd_message(string.format(">> Opening saltado automaticamente (hasta %s) [TAB para volver]", format_time(op_end)), 3)
        elseif not auto_skip_op and not notified_op then
            notified_op = true
            mp.osd_message(string.format(":: Opening detectado [%s - %s] -> Presiona [TAB] para saltar", 
                format_time(op_start), format_time(op_end)), 4)
        end
    else
        notified_op = false
    end

    -- Comprobar Ending
    if ed_start and ed_end and time_pos >= ed_start and time_pos < ed_end then
        if not notified_ed then
            notified_ed = true
            mp.osd_message(string.format(":: Ending detectado [%s] -> Presiona [TAB] para saltar o [Shift+N] siguiente", 
                format_time(ed_start)), 4)
        end
    else
        notified_ed = false
    end
end)

-- Atajo TAB: Salto inteligente de Opening / Ending
mp.add_key_binding("TAB", "aniskip-jump", function()
    local time_pos = mp.get_property_number("time-pos") or 0

    -- Si acabamos de saltar y presiona TAB otra vez, vuelve atrás
    if op_skipped and op_start and math.abs(time_pos - op_end) < 5 then
        op_skipped = false
        mp.commandv("seek", op_start, "absolute", "exact")
        mp.osd_message("<< Regresando al Opening", 2)
        return
    end

    -- Si estamos en el rango del Opening
    if op_start and op_end and time_pos >= (op_start - 3) and time_pos < op_end then
        op_skipped = true
        mp.commandv("seek", op_end, "absolute", "exact")
        mp.osd_message(string.format(">> Opening saltado (hasta %s)", format_time(op_end)), 3)
        return
    end

    -- Si estamos en el rango del Ending
    if ed_start and ed_end and time_pos >= (ed_start - 3) and time_pos < ed_end then
        mp.commandv("seek", ed_end, "absolute", "exact")
        mp.osd_message(string.format(">> Ending saltado (hasta %s)", format_time(ed_end)), 3)
        return
    end

    -- Fallback si no hay AniSkip para este anime: saltar 85 segundos (duración estándar de un opening)
    mp.commandv("seek", 85, "relative", "exact")
    mp.osd_message(">> Salto de 85s (Opening estandar)", 2)
end)

-- Atajo Ctrl+s: Alternar Auto-Skip
mp.add_key_binding("ctrl+s", "aniskip-toggle-auto", function()
    auto_skip_op = not auto_skip_op
    local estado = auto_skip_op and "ACTIVADO" or "DESACTIVADO"
    mp.osd_message(":: Auto-Skip de Opening: " .. estado, 3)
end)
