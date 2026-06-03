local USERNAME = "NeoReveriii"
local REPO     = "FishingChef-Hub"
local cb       = "?nocache=" .. math.random(11111, 99999)

local GUI_URL  = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/gui.lua" .. cb
local LOOP_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoCook.lua" .. cb
local TELE_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/teleport.lua" .. cb
local FISH_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoFish.lua" .. cb
local SELL_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoSell.lua" .. cb
local UTIL_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/utilities.lua" .. cb
local SERVE_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoServe.lua" .. cb

local function fetch(url)
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success or not result or result == "404: Not Found" then return nil end
    return loadstring(result)()
end

local UI_Module       = fetch(GUI_URL)
local Logic_Module    = fetch(LOOP_URL)
local Teleport_Module = fetch(TELE_URL)
local Fish_Module     = fetch(FISH_URL)
local Sell_Module     = fetch(SELL_URL)
local Util_Module     = fetch(UTIL_URL)
local Serve_Module    = fetch(SERVE_URL)

if UI_Module and Logic_Module and Teleport_Module and Fish_Module and Sell_Module and Util_Module and Serve_Module then
    -- Run layout environment setup
    local App = UI_Module.Create()
    
    -- Exact Sidebar Tab Order requested
    local CookPage     = UI_Module.AddTab("Auto Cooking")
    local SellPage     = UI_Module.AddTab("Shop")
    local TeleportPage = UI_Module.AddTab("Teleport")
    local SettingsPage = UI_Module.AddTab("Auto Fishing")
    local ServePage    = UI_Module.AddTab("Auto Serve")
    local UtilsPage    = UI_Module.AddTab("Utilities")
    local ConfigPage   = UI_Module.AddTab("Config")
    
    -------------------------------------------
    -- TAB 1: Auto Cooking
    -------------------------------------------
    UI_Module.AddDropdown(CookPage, "Target Recipe", {"Sashimi", "Nigiri", "Sushi"}, false, function(choice)
        Logic_Module.SelectedRecipe = choice
        print("[State]: Set target recipe to -> " .. choice)
    end)
    
    local dropdownController = UI_Module.AddDropdown(CookPage, "Type of Fish", {"Loading..."}, true, function(choices)
        Logic_Module.SelectedFishes = choices
        print("[State]: Set target species to -> " .. table.concat(choices, ", "))
    end)
    
    local RefreshBtn = Instance.new("TextButton", CookPage)
    RefreshBtn.Size = UDim2.new(0.95, 0, 0, 30)
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RefreshBtn.Text = "Refresh Inventory"
    RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshBtn.Font = Enum.Font.GothamMedium
    RefreshBtn.TextSize = 13
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)
    
    RefreshBtn.MouseButton1Click:Connect(function()
        RefreshBtn.Text = "Refreshing..."
        task.spawn(function()
            local available = Logic_Module.GetAvailableFish()
            if #available == 0 then available = {"No Fish Found"} end
            dropdownController.Refresh(available)
            RefreshBtn.Text = "Refresh Inventory"
        end)
    end)
    
    task.spawn(function()
        local available = Logic_Module.GetAvailableFish()
        if #available == 0 then available = {"No Fish Found"} end
        dropdownController.Refresh(available)
    end)
    
    local ClearBtn = Instance.new("TextButton", CookPage)
    ClearBtn.Size = UDim2.new(0.95, 0, 0, 30)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    ClearBtn.Text = "Clear Selection"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.Font = Enum.Font.GothamMedium
    ClearBtn.TextSize = 13
    Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)
    
    ClearBtn.MouseButton1Click:Connect(function()
        Logic_Module.SelectedRecipe = "Sashimi"
        Logic_Module.SelectedFishes = {}
        dropdownController.Refresh({"Loading..."})
        Logic_Module.Stop()
        print("[State]: Selection cleared")
    end)
    
    UI_Module.AddToggle(CookPage, "Enable AutoCook", function(state)
        Logic_Module.Enabled = state
        if state then Logic_Module.Start() else Logic_Module.Stop() end
    end)
    
    -------------------------------------------
    -- TAB 2: Shop
    -------------------------------------------
    UI_Module.AddSectionLabel(SellPage, "AUTO SELL")

    -- Multi-select dropdown – starts empty, populated by FetchAllFishTypes()
    local sellDropdown = UI_Module.AddDropdown(
        SellPage,
        "Target Fish Types",
        {"Loading..."},
        true,  -- multiSelect
        function(choices)
            Sell_Module.SelectedFish = choices
            print("[AutoSell]: Target species -> " .. table.concat(choices, ", "))
        end
    )

    -- Shared refresh function (used on load + by button)
    local function refreshSellFishList(btn)
        if btn then btn.Text = "Scanning game..." end
        task.spawn(function()
            local types = Sell_Module.FetchAllFishTypes()
            if #types == 0 then
                types = {"(No fish found – try refreshing)"}
            end
            Sell_Module.AllFishTypes = types
            sellDropdown.Refresh(types)
            if btn then btn.Text = "Refresh Fish List" end
            print("[AutoSell]: Dropdown updated with " .. #types .. " fish types.")
        end)
    end

    -- Refresh button (same style as Chef Automation tab)
    local SellRefreshBtn = Instance.new("TextButton", SellPage)
    SellRefreshBtn.Size = UDim2.new(0.95, 0, 0, 30)
    SellRefreshBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SellRefreshBtn.Text = "Refresh Fish List"
    SellRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SellRefreshBtn.Font = Enum.Font.GothamMedium
    SellRefreshBtn.TextSize = 13
    Instance.new("UICorner", SellRefreshBtn).CornerRadius = UDim.new(0, 6)

    SellRefreshBtn.MouseButton1Click:Connect(function()
        refreshSellFishList(SellRefreshBtn)
    end)

    -- Auto-populate on load
    refreshSellFishList(nil)

    UI_Module.AddNumberInput(
        SellPage,
        "Sell Interval (seconds)",
        10,   -- default
        3,    -- minimum 3 s
        3600, -- maximum 1 hour
        function(value)
            Sell_Module.Interval = value
            print("[AutoSell]: Interval set to " .. value .. "s")
        end
    )

    UI_Module.AddToggle(SellPage, "Auto Sell", function(state)
        Sell_Module.Enabled = state
        if state then Sell_Module.Start() else Sell_Module.Stop() end
    end)
    
    local SellClearBtn = Instance.new("TextButton", SellPage)
    SellClearBtn.Size = UDim2.new(0.95, 0, 0, 30)
    SellClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    SellClearBtn.Text = "Clear Selection"
    SellClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SellClearBtn.Font = Enum.Font.GothamMedium
    SellClearBtn.TextSize = 13
    Instance.new("UICorner", SellClearBtn).CornerRadius = UDim.new(0, 6)
    
    SellClearBtn.MouseButton1Click:Connect(function()
        Sell_Module.SelectedFish = {}
        sellDropdown.Refresh({"Loading..."})
        Sell_Module.Stop()
        print("[AutoSell]: Selection cleared")
    end)

    -------------------------------------------
    -- TAB 3: Teleport
    -------------------------------------------
    local locationNames = Teleport_Module.GetLocationNames()
    
    UI_Module.AddDropdown(TeleportPage, "Select Destination", locationNames, false, function(choice)
        Teleport_Module.To(choice)
    end)
    
    local PortableMenu = nil
    UI_Module.AddToggle(TeleportPage, "Teleport Menu", function(state)
        if state then
            PortableMenu = UI_Module.CreatePortableDropdown("Teleport", locationNames, function(choice)
                Teleport_Module.To(choice)
            end)
        else
            if PortableMenu then
                PortableMenu.Destroy()
                PortableMenu = nil
            end
        end
    end)
    
    -------------------------------------------
    -- TAB 4: Auto Fishing
    -------------------------------------------
    Fish_Module.TeleportModule = Teleport_Module
    Fish_Module.RemoteLocation = "None"
    
    UI_Module.AddDropdown(SettingsPage, "Remote Fishing Location", {"None", "Koi Pond", "Razor Reef", "Bamboo Forest"}, false, function(choice)
        Fish_Module.RemoteLocation = choice
    end)
    
    UI_Module.AddToggle(SettingsPage, "Enable Auto Fishing (Bypass)", function(state)
        Fish_Module.Enabled = state
        if state then Fish_Module.Start() else Fish_Module.Stop() end
    end)
    
    -------------------------------------------
    -- TAB 5: Auto Serve
    -------------------------------------------
    UI_Module.AddSectionLabel(ServePage, "CUSTOMER AUTOMATION")
    
    UI_Module.AddToggle(ServePage, "Enable Auto Serve", function(state)
        Serve_Module.Enabled = state
        if state then Serve_Module.Start() else Serve_Module.Stop() end
    end)
    
    UI_Module.AddSectionLabel(ServePage, "FISH SELECTION PER RECIPE")
    
    -- Get available fish for dropdowns
    local function getAvailableFish()
        local success, inventory = pcall(function()
            return Logic_Module.GetAvailableFish()
        end)
        if success and inventory and #inventory > 0 then
            return inventory
        else
            return {"No Fish Found"}
        end
    end
    
    -- Sashimi fish selection
    local sashimiFishOptions = getAvailableFish()
    local sashimiDropdown = UI_Module.AddDropdown(ServePage, "Sashimi Fish", sashimiFishOptions, false, function(choice)
        if choice == "No Fish Found" then
            Serve_Module.RecipeFish["Sashimi"] = nil
        else
            Serve_Module.RecipeFish["Sashimi"] = choice
        end
        print("[AutoServe]: Sashimi fish set to -> " .. tostring(Serve_Module.RecipeFish["Sashimi"]))
    end)
    
    -- Nigiri fish selection
    local nigiriFishOptions = getAvailableFish()
    local nigiriDropdown = UI_Module.AddDropdown(ServePage, "Nigiri Fish", nigiriFishOptions, false, function(choice)
        if choice == "No Fish Found" then
            Serve_Module.RecipeFish["Nigiri"] = nil
        else
            Serve_Module.RecipeFish["Nigiri"] = choice
        end
        print("[AutoServe]: Nigiri fish set to -> " .. tostring(Serve_Module.RecipeFish["Nigiri"]))
    end)
    
    -- Sushi fish selection
    local sushiFishOptions = getAvailableFish()
    local sushiDropdown = UI_Module.AddDropdown(ServePage, "Sushi Fish", sushiFishOptions, false, function(choice)
        if choice == "No Fish Found" then
            Serve_Module.RecipeFish["Sushi"] = nil
        else
            Serve_Module.RecipeFish["Sushi"] = choice
        end
        print("[AutoServe]: Sushi fish set to -> " .. tostring(Serve_Module.RecipeFish["Sushi"]))
    end)
    
    -- Refresh fish lists button
    local RefreshServeFishBtn = Instance.new("TextButton", ServePage)
    RefreshServeFishBtn.Size = UDim2.new(0.95, 0, 0, 30)
    RefreshServeFishBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RefreshServeFishBtn.Text = "Refresh Fish Lists"
    RefreshServeFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshServeFishBtn.Font = Enum.Font.GothamMedium
    RefreshServeFishBtn.TextSize = 13
    Instance.new("UICorner", RefreshServeFishBtn).CornerRadius = UDim.new(0, 6)
    
    RefreshServeFishBtn.MouseButton1Click:Connect(function()
        RefreshServeFishBtn.Text = "Refreshing..."
        task.spawn(function()
            local available = getAvailableFish()
            sashimiDropdown.Refresh(available)
            nigiriDropdown.Refresh(available)
            sushiDropdown.Refresh(available)
            RefreshServeFishBtn.Text = "Refresh Fish Lists"
        end)
    end)
    
    -------------------------------------------
    -- TAB 6: Utilities
    -------------------------------------------
    UI_Module.AddSectionLabel(UtilsPage, "PERFORMANCE")
    
    local FPSBoostBtn = Instance.new("TextButton", UtilsPage)
    FPSBoostBtn.Size = UDim2.new(0.95, 0, 0, 30)
    FPSBoostBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    FPSBoostBtn.Text = "Enable FPS Boost"
    FPSBoostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FPSBoostBtn.Font = Enum.Font.GothamMedium
    FPSBoostBtn.TextSize = 13
    Instance.new("UICorner", FPSBoostBtn).CornerRadius = UDim.new(0, 6)
    
    FPSBoostBtn.MouseButton1Click:Connect(function()
        if not Util_Module.IsFPSBoostEnabled() then
            Util_Module.EnableFPSBoost()
            FPSBoostBtn.Text = "FPS Boost Enabled"
            FPSBoostBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        else
            print("[Utilities]: FPS Boost already enabled (requires game restart to disable)")
        end
    end)
    
    -------------------------------------------
    -- TAB 7: Config
    -------------------------------------------
    UI_Module.AddSectionLabel(ConfigPage, "SETTINGS")
    
    UI_Module.AddToggle(ConfigPage, "Coming Soon", function(state)
        print("[Config]: Feature coming soon")
    end)
    
    -------------------------------------------
    -- CLEANUP
    -------------------------------------------
    UI_Module.OnExit(function()
        Logic_Module.Stop()
        Fish_Module.Stop()
        Sell_Module.Stop()
        Serve_Module.Stop()
        if PortableMenu then PortableMenu.Destroy() end
    end)
    
    print("[Success]: Hub fully connected to background Knit tracking automation loop.")
else
    warn("[Error]: Script initialization aborted. Check file paths. Ensure all modules are pushed to GitHub!")
end