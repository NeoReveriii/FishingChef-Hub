local USERNAME = "NeoReveriii"
local REPO     = "FishingChef-Hub"
local cb       = "?nocache=" .. math.random(11111, 99999)

local GUI_URL  = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/gui.lua" .. cb
local LOOP_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoCook.lua" .. cb

local function fetch(url)
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success or not result or result == "404: Not Found" then return nil end
    return loadstring(result)()
end

local UI_Module = fetch(GUI_URL)
local Logic_Module = fetch(LOOP_URL)

if UI_Module and Logic_Module then
    -- Run layout environment setup
    local App = UI_Module.Create()
    local CookPage = UI_Module.AddTab("Chef Automation")
    local SettingsPage = UI_Module.AddTab("Utilities & Config")
    
    -- Sync dropdown choice to backend configuration data state
    local fishChoices = {"marlin", "great_white_shark", "yellowtail_kingfish", "moonlight_koi"}
    UI_Module.AddDropdown(CookPage, "Target Species Selection", fishChoices, function(choice)
        Logic_Module.SelectedFish = choice
        print("🎯 State Change: Set target species value to -> " .. choice)
    end)
    
    -- Sync toggle switch directly to background execution thread
    UI_Module.AddToggle(CookPage, "Enable AutoCook Engine Loop", function(state)
        Logic_Module.Enabled = state
        if state then
            Logic_Module.Start()
        else
            Logic_Module.Stop()
        end
    end)
    
    -- Clean cleanup if the window gets closed out
    UI_Module.OnExit(function()
        Logic_Module.Stop()
    end)
    
    print("🚀 [Success]: Hub fully connected to background Knit tracking automation loop.")
else
    warn("❌ [Error]: Script link initialization aborted. Check file paths.")
end