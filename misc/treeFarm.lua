-- Toggles a tree farm on and off from chat.
-- Send the hidden chat command "$treeFarm" (Advanced Peripherals Chat Box)
-- and the redstone output on top of the computer flips.
local ADMIN = "Saratoubi" -- Minecraft username allowed to send commands

local treeFarm = true
redstone.setOutput("top", treeFarm)

while true do
    local event, username, message, uuid, isHidden = os.pullEvent("chat")

    if isHidden == true and username == ADMIN and message == "treeFarm" then
        treeFarm = not treeFarm
        redstone.setOutput("top", treeFarm)
        print("Tree farm " .. (treeFarm and "ON" or "OFF"))
    end
end
