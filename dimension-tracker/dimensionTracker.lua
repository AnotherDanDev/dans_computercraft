-- Intruder alarm for a private dimension (a Tardis Refined interior).
-- Anyone not on the allowlist who enters or leaves the tracked dimension
-- triggers an in-game toast for everyone on the notify list and a Discord message.
--
-- Hidden chat commands (Advanced Peripherals Chat Box, ADMIN only):
--   $setDim               track the dimension you're currently standing in
--   $testAlert            send a test toast
--   $addDim <player>      allow a player     | $subDim <player>     remove them
--   $addNotify <player>   notify a player    | $subNotify <player>  remove them

local ADMIN = "Saratoubi" -- Minecraft username allowed to send commands

dimensionInfo = {}

discord = require("discordWebhook")

playerBox = peripheral.find("playerDetector") or error("No Player Detector attached", 0)
chatBox = peripheral.find("chatBox") or error("No Chat Box attached", 0)

function loadDimInfo()
    if fs.exists("dimensionInfo.json") then
        local dim = fs.open("dimensionInfo.json", "r")
        dimensionInfo = textutils.unserializeJSON(dim.readAll()) or {}
        dim.close()
    end
    dimensionInfo["allowedPlayers"] = dimensionInfo["allowedPlayers"] or {}
    dimensionInfo["notifyPlayers"] = dimensionInfo["notifyPlayers"] or {}
end

function saveDimInfo()
    local dim = fs.open("dimensionInfo.json", "w")
    dim.write(textutils.serializeJSON(dimensionInfo))
    dim.close()
end

function playerDimension()
    event, username, fromDim, toDim = os.pullEvent("playerChangedDimension")
end

function playerMsg()
    event, username, message, uuid, isHidden = os.pullEvent("chat")
end

function checkAllowed(player)
    for index, value in ipairs(dimensionInfo["allowedPlayers"]) do
        if player == value then
            return true
        end
    end
    return false
end

function addAllowed(player)
    if dimensionInfo["allowedPlayers"] == nil then
        dimensionInfo["allowedPlayers"] = {}
    end
    table.insert(dimensionInfo["allowedPlayers"], player)
    saveDimInfo()
end

function addNotify(player)
    if dimensionInfo["notifyPlayers"] == nil then
        dimensionInfo["notifyPlayers"] = {}
    end
    table.insert(dimensionInfo["notifyPlayers"], player)
    saveDimInfo()
end

function subNotify(player)
    local index = 0
    for ind, value in ipairs(dimensionInfo["notifyPlayers"]) do
        if player == value then
            index = ind
        end
    end
    if index ~= 0 then
        table.remove(dimensionInfo["notifyPlayers"],index)
    end
    saveDimInfo()
end

function subAllowed(player)
    local index = 0
    for ind, value in ipairs(dimensionInfo["allowedPlayers"]) do
        if player == value then
            index = ind
        end
    end
    if index ~= 0 then
        table.remove(dimensionInfo["allowedPlayers"],index)
    end
    saveDimInfo()
end


function send_alert_entered(player)
    local title = {
        { text = "Intruder Alert", color = "red"}
    }
    
    local message = {
        { text = player,color = "blue"},
    }
    
    local titleJson = textutils.serializeJSON(title)
    local messageJson = textutils.serialiseJSON(message)

    for index, value in ipairs(dimensionInfo["notifyPlayers"]) do
        print("Sending Alert to " .. value)
        local ok, err = chatBox.sendFormattedToastToPlayer(messageJson, titleJson, value, "&4&lIntruders", "[]", "&4&l")
        sleep(1)
    end
end

function send_alert_left(player)
    local title = {
        { text = "Intruder Left", color = "green"}
    }
    
    local message = {
        { text = player,color = "green"},
    }
    
    local titleJson = textutils.serializeJSON(title)
    local messageJson = textutils.serialiseJSON(message)

    for index, value in ipairs(dimensionInfo["notifyPlayers"]) do
        print("Sending Alert to " .. value)
        local ok, err = chatBox.sendFormattedToastToPlayer(messageJson, titleJson, value, "&4&lIntruders", "[]", "&4&l")
        sleep(1)
    end
end



loadDimInfo()

while true do
    parallel.waitForAny(playerDimension,playerMsg)
    if event == "chat" then
        if username == ADMIN and isHidden == true then
            if message == "setDim" then
                local player = playerBox.getPlayer(ADMIN)
                dimensionInfo["dimension"] = player["dimension"]
                saveDimInfo()
                print("Set new dimension: " .. player["dimension"])
            elseif message == "testAlert" then
                send_alert_entered("TEST")
            else 
                if string.sub(message, 1, 6) == "addDim" then
                    local player = string.sub(message, 8, string.len(message))
                    print("Adding player to allowlist: ".. player)
                    addAllowed(player)
                elseif string.sub(message, 1, 6) == "subDim" then
                    local player = string.sub(message, 8, string.len(message))
                    print("Subtracting player from allowlist: ".. player)
                    subAllowed(player)
                elseif string.sub(message, 1, 9) == "addNotify" then
                    local player = string.sub(message, 11, string.len(message))
                    print("Adding player to Notify List: ".. player)
                    addNotify(player)
                elseif string.sub(message, 1, 9) == "subNotify" then
                    local player = string.sub(message, 11, string.len(message))
                    print("Subtracting player from Notify List: ".. player)
                    subNotify(player)
                else
                    print(string.sub(message, 1, 8))
                end
            end
        end
    end
    if event == "playerChangedDimension" then
        if toDim == dimensionInfo["dimension"] then
            if not checkAllowed(username) then
                send_alert_entered(username)
                discord.send_message("```ansi\n[2;31m[2;34m"..username.."[0m[2;31m[0m [2;31mentered Dan's Tardis![0m ```")
            end
        end
        if fromDim == dimensionInfo["dimension"] then
            if not checkAllowed(username) then
                send_alert_left(username)
                discord.send_message("```ansi\n[2;31m[2;34m[1;34m[0m[2;34m[0m[2;31m[0m[1;2m[1;34m"..username.."[0m [0m[2;36m[0;36m[0;36m[0;36mleft Dan's Tardis![0m[0;36m[0m[0;36m[0m[2;36m[0m[2;31m[2;32m[2;36m[0;36m[0;36m[0;36m[0m[0;36m[0m[0;36m[0m[2;36m[0m[2;32m[0m[2;31m[0m```")
            end
        end
    end
end