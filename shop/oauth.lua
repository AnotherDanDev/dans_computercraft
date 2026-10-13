-- Google OAuth 2.0 for a ComputerCraft computer.
-- Credentials and tokens live in sheetsSecrets.json (gitignored; see
-- sheetsSecrets.example.json). First run: call authenticate(), click the link
-- the Chat Box sends you, approve access, then paste the "code" from the
-- redirect URL into the computer. After that, refresh_token() keeps it alive.
local helper = require("helperFunctions")

local ADMIN = "Saratoubi" -- Minecraft username that receives the login link

local OAuthModule = {}
local secrets = {}
local SECRETS_FILE = "sheetsSecrets.json"

local function load_secrets()
    if not fs.exists(SECRETS_FILE) then
        error("Missing " .. SECRETS_FILE .. " - copy sheetsSecrets.example.json and fill it in", 0)
    end
    local f = fs.open(SECRETS_FILE,"r")
    secrets = textutils.unserializeJSON(f.readAll())
    f.close()
end

local function save_secrets()
    local f = fs.open(SECRETS_FILE,"w")
    f.write(textutils.serializeJSON(secrets))
    f.close()
end


function OAuthModule.generate_oauth_url()
    local base_url = "https://accounts.google.com/o/oauth2/v2/auth"
    local scope = "https://www.googleapis.com/auth/spreadsheets"
    local response_type = "code"
    local oauth_url = string.format(
        "%s?scope=%s&access_type=offline&include_granted_scopes=true&response_type=%s&client_id=%s&redirect_uri=%s",
        base_url, scope, response_type, secrets.client_id, secrets.redirect_uri
    )
    return oauth_url
end

function OAuthModule.authenticate()
    local url = OAuthModule.generate_oauth_url()
    local message = {
        {text = "Click "}, 
        {
            text = "OAuth Here",
            underlined = true,
            color = "aqua",
            clickEvent = {
                action = "open_url",
                value = url
            }
        }
    }
    print("Login link sent to " .. ADMIN .. " via chat. Paste the code here:")
    local chatBox = peripheral.find("chatBox") or error("No Chatbox attached", 1)
    
    chatBox.sendFormattedMessageToPlayer(textutils.serializeJSON(message), ADMIN)
    secrets.authcode = read()
    save_secrets()
    OAuthModule.fetch_token(secrets.authcode)
end



function OAuthModule.fetch_token(auth_code)
    local url = "https://oauth2.googleapis.com/token"
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }
    local body = "code=" .. auth_code ..
                 "&client_id=" .. secrets.client_id ..
                 "&client_secret=" .. secrets.client_secret ..
                 "&redirect_uri=" .. secrets.redirect_uri ..
                 "&grant_type=authorization_code"

    local r1, r2, r3 = http.post(url, body, headers)
    if r1 then
        local responseBody = r1.readAll()
        local token_data = textutils.unserializeJSON(responseBody)
        secrets = helper.mergeTables(secrets, token_data)
        save_secrets()
        if token_data.access_token then
            return token_data.access_token, token_data.refresh_token
        else
            print("Failed to get token. Response:", responseBody)
        end
    else
        print("HTTP request failed:", r2)
        error("Failed to get token")
    end
    
end

function OAuthModule.refresh_token()
    local url = "https://oauth2.googleapis.com/token"
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }
    local body = "client_id=" .. secrets.client_id ..
                 "&client_secret=" .. secrets.client_secret ..
                 "&refresh_token=" .. OAuthModule.get_refresh_token() ..
                 "&grant_type=refresh_token"


    local r1, r2, r3 = http.post(url, body, headers)
    if r1 then
        local responseBody = r1.readAll()
        --print(responseBody)
        local token_data = textutils.unserializeJSON(responseBody)
        token_data["refresh_token"] = OAuthModule.get_refresh_token()
        secrets = helper.mergeTables(secrets,token_data)
        save_secrets()
        if token_data.access_token then
            return token_data.access_token, token_data.refresh_token
        else
            print("Failed to get token. Response:", responseBody)
        end
    else
        print("HTTP request failed:", r2)
        error("Failed to get token")
    end
end

function OAuthModule.get_token()
    load_secrets()
    return secrets.access_token
end

function OAuthModule.get_refresh_token()
    load_secrets()
    return secrets.refresh_token
end

-- Read any other value from sheetsSecrets.json (e.g. "sheet_id").
function OAuthModule.get_secret(_key)
    load_secrets()
    return secrets[_key]
end


load_secrets()

return OAuthModule