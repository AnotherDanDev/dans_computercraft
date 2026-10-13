-- Minimal Discord webhook helper shared by several projects.
-- The webhook URL lives in webhookURL.txt at the root of the computer
-- (see webhookURL.example.txt). That file is gitignored - never commit it.
local discord = {}

local URL_FILE = "webhookURL.txt"

local function read_url()
    if not fs.exists(URL_FILE) then
        return nil
    end
    local f = fs.open(URL_FILE, "r")
    local url = f.readAll()
    f.close()
    return (url:gsub("%s+", ""))
end

function discord.send_message(_msg)
    local url = read_url()
    if not url or url == "" then
        print("Discord: no webhook configured in " .. URL_FILE)
        return false
    end

    local body = textutils.serializeJSON({
        content = _msg,
        -- Never let relayed player chat ping @everyone / roles / users.
        allowed_mentions = { parse = textutils.empty_json_array },
    })
    local headers = {
        ["Content-Type"] = "application/json",
        ["Source"] = "Minecraft/ComputerCraft/DanHook",
    }

    local response, err = http.post(url, body, headers)
    if response then
        response.close()
    else
        print("Discord: send failed - " .. tostring(err))
    end
    print("Discord Msg: " .. _msg)
    return response ~= nil, err
end

return discord
