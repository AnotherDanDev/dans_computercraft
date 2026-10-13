-- Mirrors server chat, joins and leaves into a Discord channel.
-- Needs: Advanced Peripherals Chat Box (for the chat events), HTTP enabled,
-- and discordWebhook.lua + webhookURL.txt from /lib on the same computer.
local discord = require("discordWebhook")

while true do
    local event, arg1, arg2, arg3, arg4 = os.pullEventRaw()

    if event == "terminate" then
        return

    elseif event == "chat" then
        -- arg1 = username, arg2 = message, arg4 = isHidden.
        -- Hidden messages are $commands meant for other computers, so skip them.
        if not arg4 then
            discord.send_message("**" .. arg1 .. "**: " .. arg2)
        end

    elseif event == "playerJoin" then
        discord.send_message("**" .. arg1 .. " joined** -- (From Dimension: *" .. arg2 .. "*)")

    elseif event == "playerLeave" then
        discord.send_message("**" .. arg1 .. " left** -- (From Dimension: *" .. arg2 .. "*)")
    end
end
