-- Shop front display (computer #1 of the shop).
-- Detects who walks into the shop, shows their name and balance on a
-- monitor, logs visits to Discord, and tells itemGUI.lua (over a modem)
-- who to credit. Installs Basalt automatically on first run.
local ADMIN = "Saratoubi" -- Minecraft username allowed to send commands

local filePath = "basalt.lua"
if not (fs.exists(filePath)) then
    shell.run("wget run https://basalt.madefor.cc/install.lua release latest.lua")
end

local storeInfoMod = require("storeInfoManager")
local storeInfo = storeInfoMod.load()
local basalt = require("basalt")
local discord = require("discordWebhook")

local monitor = peripheral.find("monitor")
local playerDetector = peripheral.find("playerDetector")



local modem = peripheral.wrap("right") or error("No modem attached",0)

local modemChannel = 4
local targetChannel = 3
modem.open(modemChannel)


local shopper = ""

local shopChecker = shell.openTab("playerChecker")

local function transmit_player(_username)

    local message = {
        message_type = "player_entered",
        username = _username
    }
    print("Sending message: "..textutils.serialiseJSON(message))
    modem.transmit(targetChannel, modemChannel, textutils.serialiseJSON(message))
end


local function show_balance(_balance)
    BalanceLabel:setText("$" .. tostring(_balance))
        :setFontSize(2)
end

local function set_shopper(_shopper)
    if _shopper ~= "" then
        shopper = _shopper
        print(_shopper)
        PlayerLabel:setText(_shopper)
        :   setFontSize(2)
        BalanceLabel:setText("$"..storeInfoMod.fetch_balance(_shopper))
            :setFontSize(2)
        transmit_player(_shopper)
        discord.send_message("Player Entered Shop: " .. _shopper)
        
    else
        discord.send_message("Player Left Shop: " .. shopper)
        shopper = _shopper
        PlayerLabel:setText("None")
            :setFontSize(2)
        BalanceLabel:setText("$0")
            :setFontSize(2)
    end
    
end




local function chat_handler(_username, _message, _uuid, _isHidden)
    if _username == ADMIN and _isHidden == true then
        if _message == "setDimShop" then
            local player = playerDetector.getPlayer(ADMIN)
            storeInfo["dimension"] = player["dimension"]
            storeInfoMod.save(storeInfo)
            print("Set new dimension: " .. player["dimension"])
        end
    end
end

local function check_player_in_shop(_username)
    local players = playerDetector.getPlayersInCoords(storeInfo["coords"][1],storeInfo["coords"][2])
    for index, value in ipairs(players) do
        if value == _username then
            return true
        end
    end
    return false
end

local function dim_handler(_username, _fromDim, _toDim)
    if _toDim == storeInfo["dimension"] then
        if check_player_in_shop(_username) then
            if shopper == "" then
                set_shopper(_username)
            end
            
        end
    end
    if _fromDim == storeInfo["dimension"] then
        if not check_player_in_shop(_username) then
            if shopper ~= "" then
                set_shopper("")
            end
        end
    end
end

local function modem_handler(_side,_channel,_replyChannel,_message,_distance)
    print(_message)
    local message = textutils.unserialiseJSON(_message)
    if message == nil then
        return
    end
    if message["message_type"] == "player_balance" then
        print("Updating Player Balance")
        storeInfo.userBalances[message.username] = message.balance
        storeInfoMod.save(storeInfo)
        -- Only refresh the label. Calling set_shopper() here re-sent
        -- "player_entered", which made itemGUI reply again: an endless loop.
        if message.username == shopper then
            show_balance(message.balance)
        end
    end

end



local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)
    :setBackground(colors.black)

local aLabel = monitorFrame:addLabel()
    :setForeground(colors.red)
    :setBackground(colors.black)
    :setPosition(2,2)
    :setText("Welcome to Dan's Shop!")
    :setFontSize(1)
    
PlayerLabel = monitorFrame:addLabel()
    :setForeground(colors.blue)
    :setBackground(colors.black)
    :setPosition(8,8)
    :setText("Test2")
    :setFontSize(2)

BalanceLabel = monitorFrame:addLabel()
    :setForeground(colors.green)
    :setBackground(colors.black)
    :setPosition(8,12)
    :setText("$0")
    :setFontSize(2)

local function basalt_event_listener()
    while true do
        local event, arg1, arg2, arg3, arg4, arg5 = os.pullEventRaw()
        if event == "terminate" then
            shell.switchTab(shopChecker)
            os.queueEvent("Done")
            os.queueEvent("key_down")
            return
        end
        if event == "playerChangedDimension" then
            dim_handler(arg1,arg2,arg3)
        end
        if event == "chat" then
            chat_handler(arg1, arg2, arg3, arg4)
        end
        if event == "playersInShop" and shopper == "" then
            set_shopper(arg1[1])
        end
        if event == "shopEmpty" and shopper ~= "" then
            set_shopper("")
        end
        if event == "modem_message" then
            print("message received")
            modem_handler(arg1,arg2,arg3,arg4,arg5)
        end

        basalt.update(event, arg1, arg2, arg3, arg4, arg5)
    end


end

-- Here we would add additional objects

basalt_event_listener() -- Starts listening to incoming events and draw stuff on the screen. This should nearly always be the last line.
