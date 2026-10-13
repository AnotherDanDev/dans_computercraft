-- Bounty board / buyback counter (computer #2 of the shop).
-- Shows a paged list of items the shop is buying, with prices pulled from
-- Google Sheets and adjusted by how much of each item is already in storage.
-- When the deposit button fires a redstone signal, everything in the barrel
-- is priced, pulled into Refined Storage, and credited to the current shopper.
-- Talks to storeUI.lua over a wired/wireless modem.
local sheetAPI = require("sheetsAPI")
local helper = require("helperFunctions")

local basalt = require("basalt")


local barrel = peripheral.find("inventory") or error("No inventory attached",0)
local bridge = peripheral.find("rsBridge") or error("No RS Bridge attached",0)

local monitor = peripheral.find("monitor") or error("No Monitor attached",0)

local modem = peripheral.wrap("front") or error("No modem attached",0)
local modemChannel = 3
local targetChannel = 4
modem.open(modemChannel)

monitor.clear()

local shopper = nil -- set when storeUI tells us who is in the shop

local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)
    :setBackground(colors.black)

local title = monitorFrame:addFrame()
    :setPosition(2,2)
    :setSize("parent.w-2","4")
    :addLabel()
    :setText("BOUNTIES")
    :setForeground(colors.green)
    :setBackground(colors.gray)
    :setFontSize(2)
    :setPosition(3,2)

local sub = monitorFrame:addFrame()
        :setPosition(2,7)
        :setSize("parent.w-2","parent.h-7")

local function adjust_item(_itemName, _itemData)
    print(_itemName)
    local newPrice = 0
    local itemTable = bridge.getItem({name = _itemName}) 
    if itemTable == nil then
        print("Item not found? " .. _itemName)
        return true, _itemData["Price"]
    end
    if itemTable["amount"] > tonumber(_itemData["Max_Amount"]) then
        return false, _itemData["Price"]
    end
    -- Items without a median point just use their flat price.
    newPrice = tonumber(_itemData["Price"])
    if _itemData["Median_Point"] ~= "NA" then
        local temp = (_itemData["Price"]*_itemData["Median_Point"])/itemTable["amount"]
        print(_itemData["Price"].. " * ".._itemData["Median_Point"])
        newPrice = helper.clamp(temp,tonumber(_itemData["Min_Price"]),tonumber(_itemData["Max_Price"]))
    end
    

    return true,  newPrice
end

local function populate_items()
    print("getting items")
    local items, itemLength = sheetAPI.get_item_costs()
    local pages = math.ceil((itemLength)/17)
    local currentPage = 1

    local itemPages = {}
    local lists = {}

    sub:removeChildren()
    print("Constructing GUI")

    local buttonRefresh = sub:addButton()
    :setText("refresh")
    :setBackground(colors.green)
    :setSize(7,1)
    :setPosition("parent.w/2-3","parent.h")
    :onClick(function(self,event,button,x,y)
        if(event=="mouse_click")and(button==1)then
            populate_items()
        end
    end)


    local buttonLeft = sub:addButton()
    :setText("<-")
    :setBackground(colors.green)
    :setSize(4,1)
    :setPosition(2,"parent.h")
    :onClick(function(self,event,button,x,y)
        if(event=="mouse_click")and(button==1)then
            itemPages[currentPage]:hide()
            if currentPage == 1 then
            currentPage = pages
            else
            currentPage = currentPage - 1
            end
            itemPages[currentPage]:show()
        end
    end)

    local buttonRight = sub:addButton()
    :setText("->")
    :setBackground(colors.green)
    :setSize(4,1)
    :setPosition("parent.w-4","parent.h")
    :onClick(function(self,event,button,x,y)
        if(event=="mouse_click")and(button==1)then
            itemPages[currentPage]:hide()
            if currentPage == pages then
            currentPage = 1
            else
            currentPage = currentPage + 1
            end
            itemPages[currentPage]:show()
        end
    end)

    local label = sub:addLabel()
    :setText("  Item            Reward")
    :setPosition(2,1)
    :setForeground(colors.green)

    for i = 1, pages, 1 do
        local subFrame = sub:addFrame()
        :setPosition(2,2)
        :setSize("parent.w-1","parent.h-2"):hide()
        table.insert(itemPages,subFrame)
        local aList = subFrame:addList()
        :setSize("parent.w","parent.h")
        :setSelectionColor(colors.gray, colors.green)
        table.insert(lists,aList)
    end

    itemPages[1]:show()

    local page = 1
    local count = 1
    for key, value in pairs(items) do
        local name = value["Display_Name"]
        local addToShop, newPrice = adjust_item(key, value)
        if addToShop then
            local padLength = 25 - #tostring(newPrice) - 1 
            name = helper.padString(name,".", padLength)
            name = name .. "$" .. newPrice
            lists[page]:addItem(name, colors.gray, colors.black)
        end
        count = count + 1
        if count > 17 then
            page = page + 1
            count = 1
        end
    end

end



local function update_balance(_username, _balance)
    local message = {
        message_type = "player_balance",
        username = _username,
        balance = _balance,
    }
    modem.transmit(targetChannel, modemChannel, textutils.serialiseJSON(message))
end

local function redstone_handler()
    if redstone.getInput("right") == false then
        return
    end
    if shopper == nil then
        print("Deposit ignored: nobody is in the shop")
        return
    end
    local credit = 0
    local items = barrel.list()
    print(textutils.serialise(items))
    for index, item in pairs(items) do
        print(textutils.serialise(item))
        local exists, itemData = sheetAPI.check_for_item(item)
        if exists then
            local addToShop, newPrice = adjust_item(item["name"], itemData)
            if addToShop and newPrice ~= nil then
                print("Adjusted Price: " .. newPrice)
                credit = credit + newPrice * item["count"]
                bridge.importItem(item, "up")
            end
        end
    end
    
    print("Credit: "..credit)
    if credit > 0 then
        local newBalance = sheetAPI.add_balance(shopper, credit)
        update_balance(shopper, newBalance)
    end
end

local function modem_handler(_side,_channel,_replyChannel,_message,_distance)
    local message = textutils.unserialiseJSON(_message)
    print(_message)
    if message == nil then
        return
    end
    if message["message_type"] == "player_entered" then
        print("Player Entered")
        shopper = message["username"]
        local exists, player = sheetAPI.get_balance(message["username"])
        update_balance(message.username,player.balance)
    end
end

local function basalt_event_listener()
    print("starting loop")
    os.queueEvent("key_down")
    while true do
        local event, arg1, arg2, arg3, arg4, arg5 = os.pullEventRaw()
        if event == "terminate" then
            return
        end
        if event == "redstone" then
            redstone_handler()
        end
        if event == "modem_message" then
            print("message received")
            modem_handler(arg1,arg2,arg3,arg4,arg5)
        end
        basalt.update(event, arg1, arg2, arg3, arg4, arg5)
    end

end

populate_items()

basalt_event_listener()
