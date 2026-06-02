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
    
    -- Target Recipe Cuisine (Single-Select)
    UI_Module.AddDropdown(CookPage, "Target Recipe Cuisine", {"Sashimi"}, false, function(choice)
        Logic_Module.SelectedRecipe = choice
        print("🍽️ State Change: Set target recipe to -> " .. choice)
    end)
    
    -- Sync dropdown choice to backend configuration data state (Multi-Select)
    local dropdownController = UI_Module.AddDropdown(CookPage, "Target Species Selection", {"Loading..."}, true, function(choices)
        Logic_Module.SelectedFishes = choices
        print("🎯 State Change: Set target species to -> " .. table.concat(choices, ", "))
    end)
    
    -- Refresh button to fetch inventory and update dropdown
    local RefreshBtn = Instance.new("TextButton", CookPage)
    RefreshBtn.Size = UDim2.new(0.95, 0, 0, 30)
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    RefreshBtn.Text = "Refresh Inventory"
    RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshBtn.Font = Enum.Font.GothamMedium
    RefreshBtn.TextSize = 13
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)
    
    RefreshBtn.MouseButton1Click:Connect(function()
        RefreshBtn.Text = "Refreshing..."
        task.spawn(function()
            local available = Logic_Module.GetAvailableFish()
            if #available == 0 then
                available = {"No Fish Found"}
            end
            dropdownController.Refresh(available)
            RefreshBtn.Text = "Refresh Inventory"
        end)
    end)
    
    -- Initial population
    task.spawn(function()
        local available = Logic_Module.GetAvailableFish()
        if #available == 0 then available = {"No Fish Found"} end
        dropdownController.Refresh(available)
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