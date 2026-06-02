local USERNAME = "NeoReveriii"
local REPO     = "FishingChef-Hub"
local cb       = "?cache=" .. math.random(1, 99999)

local GUI_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/gui.lua" .. cb

local function fetch(url)
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success or not result or result == "404: Not Found" then return nil end
    return loadstring(result)()
end

local UI_Module = fetch(GUI_URL)
if UI_Module then
    -- 🛠️ FIX: We need to explicitly handle the ScreenGui parent container connection
    local App = UI_Module.Create()
    
    local CookPage = UI_Module.AddTab("Chef Automation")
    local SettingsPage = UI_Module.AddTab("Utilities & Config")
    
    local fishChoices = {"marlin", "great_white_shark", "yellowtail_kingfish", "moonlight_koi"}
    UI_Module.AddDropdown(CookPage, "Target Species Selection", fishChoices, function(choice)
        print("🎯 Choice Selected: " .. choice)
    end)
    
    UI_Module.AddToggle(CookPage, "Enable AutoCook Engine Loop", function(state)
        print("⚙️ Toggle State: " .. tostring(state))
    end)
    
    print("🚀 [Main Launch]: Interface fully configured and rendering live!")
else
    warn("❌ Main script downloaded but couldn't load gui.lua sub-module link.")
end