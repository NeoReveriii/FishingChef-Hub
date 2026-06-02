local USERNAME = "NeoReveriii"
local REPO     = "FishingChef-Hub"
local cb       = "?nocache=" .. math.random(11111, 99999)

local GUI_URL  = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/gui.lua" .. cb
local LOOP_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoCook.lua" .. cb
local TELE_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/teleport.lua" .. cb
local FISH_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoFish.lua" .. cb
local SELL_URL = "https://raw.githubusercontent.com/"..USERNAME.."/"..REPO.."/main/modules/autoSell.lua" .. cb

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

if UI_Module and Logic_Module and Teleport_Module and Fish_Module and Sell_Module then
    -- Run layout environment setup
    local App = UI_Module.Create()
    
    -- Exact Sidebar Tab Order requested
    local CookPage     = UI_Module.AddTab("Chef Automation")
    local SellPage     = UI_Module.AddTab("Auto Sell")
    local TeleportPage = UI_Module.AddTab("Map Teleports")
    local SettingsPage = UI_Module.AddTab("Utilities and config")
    
    -------------------------------------------
    -- TAB 1: Chef Automation
    -------------------------------------------
    UI_Module.AddDropdown(CookPage, "Target Recipe Cuisine", {"Sashimi"}, false, function(choice)
        Logic_Module.SelectedRecipe = choice
        print("[State]: Set target recipe to -> " .. choice)
    end)
    
    local dropdownController = UI_Module.AddDropdown(CookPage, "Target Species Selection", {"Loading..."}, true, function(choices)
        Logic_Module.SelectedFishes = choices
        print("[State]: Set target species to -> " .. table.concat(choices, ", "))
    end)
    
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
    
    UI_Module.AddToggle(CookPage, "Enable AutoCook Engine Loop", function(state)
        Logic_Module.Enabled = state
        if state then Logic_Module.Start() else Logic_Module.Stop() end
    end)
    
    -------------------------------------------
    -- TAB 2: Auto Sell
    -------------------------------------------
    UI_Module.AddSectionLabel(SellPage, "Fish to Sell")

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
    SellRefreshBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
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

    UI_Module.AddSectionLabel(SellPage, "Timer Configuration")

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

    UI_Module.AddSectionLabel(SellPage, "Engine")

    UI_Module.AddToggle(SellPage, "Enable Auto Sell Engine", function(state)
        Sell_Module.Enabled = state
        if state then Sell_Module.Start() else Sell_Module.Stop() end
    end)

    -------------------------------------------
    -- TAB 3: Map Teleports
    -------------------------------------------
    local locationNames = Teleport_Module.GetLocationNames()
    
    UI_Module.AddDropdown(TeleportPage, "Select Destination", locationNames, false, function(choice)
        Teleport_Module.To(choice)
    end)
    
    local PortableMenu = nil
    UI_Module.AddToggle(TeleportPage, "Enable Portable Teleport Menu", function(state)
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
    -- TAB 3: Utilities and config
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

    UI_Module.AddSectionLabel(SettingsPage, "Give Fish Probe")

    -- Try to fire every plausible giveFish remote and report back
    local GiveFishBtn = Instance.new("TextButton", SettingsPage)
    GiveFishBtn.Size = UDim2.new(0.95, 0, 0, 30)
    GiveFishBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    GiveFishBtn.Text = "🐟 Try Give Fish"
    GiveFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GiveFishBtn.Font = Enum.Font.GothamMedium
    GiveFishBtn.TextSize = 13
    Instance.new("UICorner", GiveFishBtn).CornerRadius = UDim.new(0, 6)

    GiveFishBtn.MouseButton1Click:Connect(function()
        GiveFishBtn.Text = "Probing..."
        task.spawn(function()
            local RS       = game:GetService("ReplicatedStorage")
            local Players  = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer

            -- All the names we saw / plausible variants
            local remoteNames = {
                "giveFish", "GiveFish", "give_fish", "Give_Fish",
                "giveFishes", "GiveFishes",
            }

            -- Container paths to check for both RE and RF
            local containers = {}
            pcall(function()
                local Services = RS:WaitForChild("Packages",5):WaitForChild("Knit",5):WaitForChild("Services",5)
                local Fish = Services:FindFirstChild("Fish")
                if Fish then
                    table.insert(containers, Fish:FindFirstChild("RE"))
                    table.insert(containers, Fish:FindFirstChild("RF"))
                end
                local Admin = Services:FindFirstChild("DefaultAdmin") or Services:FindFirstChild("Admin")
                if Admin then
                    table.insert(containers, Admin:FindFirstChild("RE"))
                    table.insert(containers, Admin:FindFirstChild("RF"))
                    table.insert(containers, Admin)
                end
            end)

            -- Also search root of RS directly
            table.insert(containers, RS)

            local attempted = 0
            for _, container in ipairs(containers) do
                if not container then continue end
                for _, name in ipairs(remoteNames) do
                    local remote = container:FindFirstChild(name)
                    if remote then
                        attempted = attempted + 1
                        print("[GiveFish]: Found '" .. name .. "' (" .. remote.ClassName .. ") in " .. container:GetFullName())

                        if remote:IsA("RemoteEvent") then
                            -- Try firing with common arg shapes
                            local ok1 = pcall(function() remote:FireServer() end)
                            local ok2 = pcall(function() remote:FireServer(LocalPlayer) end)
                            local ok3 = pcall(function() remote:FireServer("salmon", 1) end)
                            print("[GiveFish]: FireServer attempts: bare=" .. tostring(ok1) .. " player=" .. tostring(ok2) .. " named=" .. tostring(ok3))

                        elseif remote:IsA("RemoteFunction") then
                            local ok, result = pcall(function() return remote:InvokeServer() end)
                            print("[GiveFish]: InvokeServer result: ok=" .. tostring(ok) .. " | " .. tostring(result))
                        end
                    end
                end
            end

            if attempted == 0 then
                print("[GiveFish]: No giveFish remote found in any known location. Server probably handles it via chat command only.")
            end

            GiveFishBtn.Text = "🐟 Try Give Fish"
        end)
    end)
    
    -------------------------------------------
    -- CLEANUP
    -------------------------------------------
    UI_Module.OnExit(function()
        Logic_Module.Stop()
        Fish_Module.Stop()
        Sell_Module.Stop()
        if PortableMenu then PortableMenu.Destroy() end
    end)
    
    print("[Success]: Hub fully connected to background Knit tracking automation loop.")
else
    warn("[Error]: Script initialization aborted. Check file paths. Ensure all modules are pushed to GitHub!")
end