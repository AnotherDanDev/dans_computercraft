-- Background tab started by storeUI.lua. Polls the Player Detector every
-- 2 seconds and raises "playersInShop" / "shopEmpty" events for the UI.
local playerDetector = peripheral.find("playerDetector") or error("No Player Detector attached", 0)
local storeInfoMod = require("storeInfoManager")
local storeInfo = storeInfoMod.load()

local function check_player()
    while true do
        -- Check for players in the specified coordinates
        local players = playerDetector.getPlayersInCoords(storeInfo["coords"][1], storeInfo["coords"][2])
        if #players > 0 then
            os.queueEvent("playersInShop", players)
            print("Player in shop!")
        else
            os.queueEvent("shopEmpty", players)
        end
        print("Checking for players.")
        
        -- Use parallel API to handle termination
        local function checkPlayers()
            sleep(2)
        end

        local function listenForTerminate()
            os.pullEvent("Done")
            error("Terminated!!!", 0)
        end

        parallel.waitForAny(checkPlayers, listenForTerminate)
    end
end

-- Run the function
check_player()
