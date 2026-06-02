local USERNAME = "NeoReveriii"
local REPO     = "FishingChef-Hub"
local cb       = "?nocache=" .. math.random(11111, 99999)

local APP_URL  = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/app.lua" .. cb

local function fetch(url)
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success or not result or result == "404: Not Found" then return nil end
    return loadstring(result)()
end

local App_Module = fetch(APP_URL)

if App_Module then
    App_Module.Init(USERNAME, REPO, cb)
else
    warn("❌ [Error]: Script initialization aborted. Check file paths.")
end