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
local ANTIAFK_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/antiAfk.lua" .. cb

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
local AntiAfk_Module  = fetch(ANTIAFK_URL)

if UI_Module and Logic_Module and Teleport_Module and Fish_Module and Sell_Module and Util_Module and Serve_Module and AntiAfk_Module then
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
        local available = Logic_Module.GetAvailableFish()
        if #available == 0 then available = {"No Fish Found"} end
        dropdownController.Refresh(available)
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

    -- Rarity selection dropdown
    UI_Module.AddDropdown(
        SellPage,
        "Target Rarities",
        {"Common", "Uncommon", "Rare", "Legendary", "Mythical", "Exotic"},
        true,  -- multiSelect
        function(choices)
            Sell_Module.SelectedRarity = choices
            print("[AutoSell]: Target rarities -> " .. table.concat(choices, ", "))
        end
    )

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
        Sell_Module.SelectedRarity = {}
        local types = Sell_Module.FetchAllFishTypes()
        if #types == 0 then types = {"(No fish found – try refreshing)"} end
        Sell_Module.AllFishTypes = types
        sellDropdown.Refresh(types)
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
    
    UI_Module.AddSectionLabel(TeleportPage, "MOON TUNA EVENT")
    
    UI_Module.AddToggle(TeleportPage, "Auto Teleport (Moon Tuna Event)", function(state)
        if state then
            Teleport_Module.EnableMoonTunaAutoTeleport()
        else
            Teleport_Module.DisableMoonTunaAutoTeleport()
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
    
    UI_Module.AddSectionLabel(ServePage, "SERVING MODE")
    
    UI_Module.AddToggle(ServePage, "Serve Normal NPCs", function(state)
        Serve_Module.Config.ServeNormalNPCs = state
        print("[AutoServe]: Serve Normal NPCs -> " .. tostring(state))
    end)
    
    UI_Module.AddToggle(ServePage, "Serve Special Guests", function(state)
        Serve_Module.Config.ServeSpecialGuests = state
        print("[AutoServe]: Serve Special Guests -> " .. tostring(state))
    end)
    
    UI_Module.AddSectionLabel(ServePage, "NORMAL NPC FISH SELECTION")
    
    -- Sashimi Fish Dropdown
    local sashimiFishDropdown = UI_Module.AddDropdown(ServePage, "Sashimi Fish", {"Loading..."}, false, function(choice)
        Serve_Module.Config.NormalOrder.Sashimi.Fish = choice
        Serve_Module.Config.NormalOrder.Sashimi.DisplayName = choice .. " Sashimi"
        print("[AutoServe]: Sashimi Fish -> " .. choice)
    end)
    
    -- Nigiri Fish Dropdown
    local nigiriFishDropdown = UI_Module.AddDropdown(ServePage, "Nigiri Fish", {"Loading..."}, false, function(choice)
        Serve_Module.Config.NormalOrder.Nigiri.Fish = choice
        Serve_Module.Config.NormalOrder.Nigiri.DisplayName = choice .. " Nigiri"
        print("[AutoServe]: Nigiri Fish -> " .. choice)
    end)
    
    -- Sushi Fish Dropdown
    local sushiFishDropdown = UI_Module.AddDropdown(ServePage, "Sushi Fish", {"Loading..."}, false, function(choice)
        Serve_Module.Config.NormalOrder.Sushi.Fish = choice
        Serve_Module.Config.NormalOrder.Sushi.DisplayName = choice .. " Sushi"
        print("[AutoServe]: Sushi Fish -> " .. choice)
    end)
    
    UI_Module.AddSectionLabel(ServePage, "VIP TARGETING")
    
    UI_Module.AddDropdown(ServePage, "Select VIPs to Target", {"Rich Guy", "Ninja", "Food Critic", "Sushi Chef"}, true, function(choices)
        Serve_Module.Config.SelectedVIPs = choices
        print("[AutoServe]: Targeting VIPs -> " .. table.concat(choices, ", "))
    end)
    
    -- Rich Guy Fish Dropdown (dynamic - accepts any fish)
    local richGuyFishDropdown = UI_Module.AddDropdown(ServePage, "Rich Guy Fish (Nigiri)", {"Loading..."}, false, function(choice)
        Serve_Module.Config.RichGuyFish = choice
        print("[AutoServe]: Rich Guy Fish -> " .. choice)
    end)
    
    -- Refresh fish list button
    local RefreshFishBtn = Instance.new("TextButton", ServePage)
    RefreshFishBtn.Size = UDim2.new(0.95, 0, 0, 30)
    RefreshFishBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RefreshFishBtn.Text = "Refresh Fish Lists"
    RefreshFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshFishBtn.Font = Enum.Font.GothamMedium
    RefreshFishBtn.TextSize = 13
    Instance.new("UICorner", RefreshFishBtn).CornerRadius = UDim.new(0, 6)
    
    RefreshFishBtn.MouseButton1Click:Connect(function()
        RefreshFishBtn.Text = "Scanning..."
        task.spawn(function()
            local availableFish = {}
            if Logic_Module and Logic_Module.GetAvailableFish then
                availableFish = Logic_Module.GetAvailableFish()
            end
            if #availableFish == 0 then availableFish = {"No Fish Found"} end
            sashimiFishDropdown.Refresh(availableFish)
            nigiriFishDropdown.Refresh(availableFish)
            sushiFishDropdown.Refresh(availableFish)
            richGuyFishDropdown.Refresh(availableFish)
            RefreshFishBtn.Text = "Refresh Fish Lists"
            print("[AutoServe]: Fish lists updated with " .. #availableFish .. " types.")
        end)
    end)
    
    -- Auto-populate fish lists on load
    task.spawn(function()
        local availableFish = {}
        if Logic_Module and Logic_Module.GetAvailableFish then
            availableFish = Logic_Module.GetAvailableFish()
        end
        if #availableFish == 0 then availableFish = {"No Fish Found"} end
        sashimiFishDropdown.Refresh(availableFish)
        nigiriFishDropdown.Refresh(availableFish)
        sushiFishDropdown.Refresh(availableFish)
        richGuyFishDropdown.Refresh(availableFish)
    end)
    
    -- Pass AutoCook module to AutoServe for cooking integration
    Serve_Module.AutoCookModule = Logic_Module
    
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
    
    UI_Module.AddToggle(UtilsPage, "White Screen (On/Off Render)", function(state)
        Util_Module.SetRenderEnabled(not state)
    end)
    
    UI_Module.AddSectionLabel(UtilsPage, "ANTI-AFK")
    
    UI_Module.AddToggle(UtilsPage, "Anti-Idle (Prevent AFK Kick)", function(state)
        if state then AntiAfk_Module.EnableAntiIdle() else AntiAfk_Module.DisableAntiIdle() end
    end)
    
    UI_Module.AddToggle(UtilsPage, "Anti-Kick (Block LocalScript Kicks)", function(state)
        if state then AntiAfk_Module.EnableAntiKick() else AntiAfk_Module.DisableAntiKick() end
    end)
    
    UI_Module.AddToggle(UtilsPage, "Anti-Teleport (Block Server TP)", function(state)
        if state then AntiAfk_Module.EnableAntiTeleport() else AntiAfk_Module.DisableAntiTeleport() end
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
        AntiAfk_Module.StopAll()
        if PortableMenu then PortableMenu.Destroy() end
    end)
    
    print("[Success]: Hub fully connected to background Knit tracking automation loop.")
else
    warn("[Error]: Script initialization aborted. Check file paths. Ensure all modules are pushed to GitHub!")
end