-- Local shop state in storeInfo.json (gitignored; see storeInfo.example.json):
-- the shop's bounding box, its dimension, and cached player balances.
local storeInfo = {}

function storeInfo.load()
    if not fs.exists("storeInfo.json") then
        error("Missing storeInfo.json - copy storeInfo.example.json and fill it in", 0)
    end
    local dim = fs.open("storeInfo.json", "r")
    local json = dim.readAll()
    dim.close()
    local info = textutils.unserializeJSON(json)
    info["userBalances"] = info["userBalances"] or {}
    return info
end

function storeInfo.save(_storeInfo)
    local dim = fs.open("storeInfo.json", "w")
    dim.write(textutils.serializeJSON(_storeInfo))
    dim.close()
end

function storeInfo.fetch_balance(_username)
    local info = storeInfo.load()
    local balance = 0
    if info["userBalances"][_username] == nil then
        info["userBalances"][_username] = 0
        storeInfo.save(info)
    else
        return info["userBalances"][_username]
    end
    return balance
end



return storeInfo