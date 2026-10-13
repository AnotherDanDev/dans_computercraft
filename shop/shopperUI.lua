-- Work-in-progress redesign of the shop front screen: current shopper,
-- their balance, and a selectable list of everyone else in the shop.
-- Currently driven by placeholder data at the bottom of the file.
local basalt = require("basalt")

local monitor = peripheral.find("monitor") or error("No Monitor attached",0)

local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)
    :setBackground(colors.black)


ShopperLabel1 = {}
ShopperLabel2 = {}
PlayerList = {}

local function constructFrame()

    local title = monitorFrame:addFrame()
        :setPosition(2,2)
        :setSize("parent.w-2","1")
        :addLabel()
        :setText("Welcome to Dan's Shop!")
        :setForeground(colors.red)
        :setBackground(colors.gray)
        :setFontSize(1)
        :setPosition("parent.w/2-12",1)

    ShopperLabel1 = monitorFrame:addLabel()
    :setForeground(colors.green)
    :setBackground(colors.black)
    :setText("User")
    :setPosition("parent.w/2-4",4)
    :setFontSize(2)

    local shopperFrame= monitorFrame:addFrame()
        :setPosition(2,8)
        :setSize("parent.w/2-1","parent.h-8")

    shopperFrame:addLabel()
    :setText("Current Shopper:")
    :setForeground(colors.red)
    :setPosition(2,2)
    :setSize("parent.w",1)

    ShopperLabel2 = shopperFrame:addLabel()
    :setText("Username")
    :setForeground(colors.green)
    :setPosition(4,3)


    shopperFrame:addLabel()
    :setText("Current Balance:")
    :setForeground(colors.red)
    :setPosition(2,6)

    local balanceLabel = shopperFrame:addLabel()
    :setText("$0.00")
    :setForeground(colors.green)
    :setPosition(4,7)


    local listFrame= monitorFrame:addFrame()
        :setPosition("parent.w/2+2",8)
        :setSize("parent.w/2-2","parent.h-8")

    local label3 = listFrame:addLabel()
        :setText("Other Shoppers:")
        :setPosition(2,2)

    PlayerList = listFrame:addList()
    :setPosition(3,3)
    :setSize("parent.w-2","parent.h-2")
    :setSelectionColor(colors.gray,colors.green)
    :addItem("User 1")
    :addItem("User 2")
    :addItem("User 3")


end

local function set_shopper(_username)
    ShopperLabel1:setText(_username)
    :setFontSize(2)
    :setPosition("parent.w/2-"..tostring(#_username*1.5),4)
    ShopperLabel2:setText(_username)
end

local function set_shopper_list(_list)
    PlayerList:clear()
    for index, value in pairs(_list) do
        PlayerList:addItem(value, colors.gray, colors.black )
    end
end



constructFrame()

PlayerList:onSelect(function(self, event, item)
    set_shopper(item.text)
  end)

set_shopper("Player1")
set_shopper_list({"Player1", "Player2"})

basalt.autoUpdate()