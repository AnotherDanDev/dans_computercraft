-- Thin wrapper around the Google Sheets v4 REST API, used as the shop's
-- database. Sheet layout:
--   ItemBounties   A:I  item id, price, scale, min/max price, min/max amount,
--                       median point, display name
--   PlayerBalances A:B  username, balance
-- The spreadsheet ID comes from sheetsSecrets.json, never from code.
local oauth = require("oauth")
local sheetsAPIMod = {}

sheetsAPIMod.sheet_id = oauth.get_secret("sheet_id") or error("sheet_id missing from sheetsSecrets.json", 0)
sheetsAPIMod.url = "https://sheets.googleapis.com/v4/spreadsheets/" .. sheetsAPIMod.sheet_id

sheetsAPIMod.itemList = {}


function sheetsAPIMod.save_items()
    local f = fs.open("itemCosts.json", "w")
    f.write(textutils.serializeJSON(sheetsAPIMod.itemList))
    f.close()
end


local function sheets_post(_url, _body)
    local _headers = {
        ["Authorization"] = "Bearer " .. oauth.get_token(),
        ["Content-Type"] = "application/json"
    }   
    local r1, r2, r3 = http.post(_url, _body, _headers)
    if r1 then
        local responseBody = r1.readAll()
        -- print(responseBody)
        local data = textutils.unserializeJSON(responseBody)
        if data then
            return data
        else
            print("Failed to decode JSON response.")
        end
    else
        print("HTTP request failed with status:", r1)
        print(r2)
        if r3 then print(r3.readAll()) end
        error("Failed to access Google Sheets API")
    end
end


local function sheets_put(_url, _body)
    local _headers = {
        ["Authorization"] = "Bearer " .. oauth.get_token(),
        ["Content-Type"] = "application/json"
    }  
    local r1, r2, r3 = http.post({url = _url, body= _body, headers = _headers, method = "PUT"})
    if r1 then
        local responseBody = r1.readAll()
        -- print(responseBody)
        local data = textutils.unserializeJSON(responseBody)
        if data then
            return data
        else
            print("Failed to decode JSON response.")
        end
    else
        print("HTTP request failed with status:", r1)
        print(r2)
        if r3 then print(r3.readAll()) end
        error("Failed to access Google Sheets API")
    end
end

local function sheets_get(_url)
    local headers = {
        ["Authorization"] = "Bearer " .. oauth.get_token()
    }

    local r1, r2, r3 = http.get(_url, headers)

    if r1 then
        local responseBody = r1.readAll()
        --print(responseBody)
        local data = textutils.unserializeJSON(responseBody)
        if data then
            return data
        else
            print("Failed to decode JSON response.")
        end
    else
        print("Failed")
        print("HTTP request failed with status:", r1)
        print(r2)
        if r3 then print(r3.readAll()) end
        error("Failed to access Google Sheets API")
    end
end




function sheetsAPIMod.read_range_OAUTH(_range)
    local url = sheetsAPIMod.url .. "/values/" .. _range
    return sheets_get(url)
end

function sheetsAPIMod.print_table(_table)
 print(textutils.serialise(_table))
end

function sheetsAPIMod.get_item_costs()
    local length = 0
    local data = sheetsAPIMod.read_range_OAUTH("ItemBounties!A2:I")
    for index, value in ipairs(data["values"]) do
        sheetsAPIMod.itemList[value[1]] = {["Price"] = value[2], ["Scale"] = value[3],
        ["Min_Price"] = value[4],["Max_Price"] = value[5],["Min_Amount"] = value[6],["Max_Amount"] = value[7],["Median_Point"]=value[8],
        ["Display_Name"] = value[9]}
        length = length + 1
    end
    sheetsAPIMod.save_items()
    return sheetsAPIMod.itemList, length
end


function sheetsAPIMod.get_balance(_username)
    local player = {username = _username, balance = 0}
    local data = sheetsAPIMod.read_range_OAUTH("PlayerBalances!A2:C")
    local rows = 0
    if data["values"] ~= nil then
        rows = #data["values"]
        for index, value in ipairs(data["values"]) do
            if _username == value[1] then
                player["balance"] = tonumber(value[2]) or 0
                return true, player, index
            end
        end
    end
    -- New player: append a row and return where it landed so callers can update it.
    sheetsAPIMod.new_balance(player)
    return false, player, rows + 1
end

function sheetsAPIMod.add_balance(_username, _balance)
    local exists, player, index = sheetsAPIMod.get_balance(_username)
    player["balance"] = player["balance"] + _balance
    local url = sheetsAPIMod.url .. "/values/PlayerBalances!B" .. index+1 .. "?valueInputOption=RAW"
    local body = textutils.serializeJSON({
        values = {{player["balance"]}}
    })
    sheets_put(url, body)
    return player.balance
end


function sheetsAPIMod.new_balance(_player)
    print("New player: " .. _player["username"])
    local url = sheetsAPIMod.url .. "/values/PlayerBalances!A:B" .. ":append?valueInputOption=RAW"
    local headers = {
        ["Authorization"] = "Bearer " .. oauth.get_token(),
    }

    local body = textutils.serializeJSON({
        values = {{_player["username"],_player["balance"]}}
    })
    
    return sheets_post(url,body)
end



function sheetsAPIMod.add_item(_item)
    local url = sheetsAPIMod.url .. "/values/ItemBounties!A:A" .. ":append?valueInputOption=RAW"
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local body = textutils.serializeJSON({
        values = {{_item}}
    })

    return sheets_post(url,body)
end

function sheetsAPIMod.check_for_item(_item)
    for key, value in pairs(sheetsAPIMod.itemList) do
        if _item["name"] == key then
            return true, value
        end
    end
    return false
end

print("refreshing token...")
oauth.refresh_token()

--sheetsAPIMod.read_range_OAUTH("ItemBounties!A:A")

return sheetsAPIMod