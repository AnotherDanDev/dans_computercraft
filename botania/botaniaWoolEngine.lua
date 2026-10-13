-- Keeps a Botania Spectrolus fed with wool in the exact color order it wants.
--
-- One wool is worth 1200 mana and a full flower holds 16000, so it takes
-- 14 wool to fill it from empty. The Block Reader exposes the flower's
-- current mana and which color it wants next (0-15, matching woolOrder.json),
-- and the RS Bridge pulls that wool out of Refined Storage into an open crate
-- that drops it onto the flower.

local crate = peripheral.find("botania:open_crate") or error("No open crate attached", 0)
local bridge = peripheral.find("rsBridge") or error("No RS Bridge attached", 0)
local reader = peripheral.find("blockReader") or error("No Block Reader attached", 0)
local crateName = peripheral.getName(crate)

local f = fs.open("woolOrder.json", "r")
local woolOrder = textutils.unserializeJSON(f.readAll())
f.close()

local MAX_MANA = 16000
local EAT_TIMEOUT = 10 -- seconds to wait for the flower to eat a wool

while true do
    local flowerData = reader.getBlockData()

    if flowerData.mana < MAX_MANA then
        local wool = woolOrder[flowerData.nextColor + 1]
        bridge.exportItemToPeripheral({ name = wool, count = 1 }, crateName)

        -- Send one wool at a time and wait for the flower to eat it (its
        -- nextColor advances) so we never overfeed while mana catches up.
        local deadline = os.clock() + EAT_TIMEOUT
        repeat
            sleep(0.5)
        until reader.getBlockData().nextColor ~= flowerData.nextColor or os.clock() > deadline
    else
        sleep(1)
    end
end
