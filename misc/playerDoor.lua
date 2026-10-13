-- Opens a door for authorized players only.
-- A Player Detector watches a 2-block radius; when an authorized player is
-- inside it, every attached Redstone Integrator outputs on its top side.
local AUTHED_PLAYERS = { "Saratoubi" }

local detector = peripheral.find("playerDetector") or error("No Player Detector attached", 0)
local integrators = { peripheral.find("redstoneIntegrator") }
if #integrators == 0 then
    error("No Redstone Integrator attached", 0)
end

local function setRedstone(on)
    for _, integrator in ipairs(integrators) do
        integrator.setOutput("top", on)
    end
end

local function isAuthed(name)
    for _, authed in ipairs(AUTHED_PLAYERS) do
        if name == authed then
            return true
        end
    end
    return false
end

while true do
    local open = false
    for _, name in ipairs(detector.getPlayersInCubic(2, 2, 2)) do
        if isAuthed(name) then
            open = true
            break
        end
    end
    setRedstone(open)
    sleep(open and 1 or 0.5)
end
