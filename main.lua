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
    local CookPage     = UI_Module.AddTab("Auto Cooking")
    local SellPage     = UI_Module.AddTab("Shop")
    local TeleportPage = UI_Module.AddTab("Teleport")
    local SettingsPage = UI_Module.AddTab("Auto Fishing")
    
    -------------------------------------------
    -- TAB 1: Auto Cooking
    -------------------------------------------
    UI_Module.AddDropdown(CookPage, "Target Recipe Cuisine", {"Sashimi", "Nigiri", "Sushi"}, false, function(choice)
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

    UI_Module.AddSectionLabel(SettingsPage, "Admin Probe")

    -- Step 1: Enumerate everything DefaultAdmin service exposes
    local ScanAdminBtn = Instance.new("TextButton", SettingsPage)
    ScanAdminBtn.Size = UDim2.new(0.95, 0, 0, 30)
    ScanAdminBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    ScanAdminBtn.Text = "🔍 Scan DefaultAdmin Remotes"
    ScanAdminBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ScanAdminBtn.Font = Enum.Font.GothamMedium
    ScanAdminBtn.TextSize = 13
    Instance.new("UICorner", ScanAdminBtn).CornerRadius = UDim.new(0, 6)

    ScanAdminBtn.MouseButton1Click:Connect(function()
        ScanAdminBtn.Text = "Scanning..."
        task.spawn(function()
            local RS = game:GetService("ReplicatedStorage")

            local ok, Services = pcall(function()
                return RS:WaitForChild("Packages",5)
                         :WaitForChild("Knit",5)
                         :WaitForChild("Services",5)
            end)
            if not ok then
                print("[AdminProbe]: Could not reach Knit Services")
                ScanAdminBtn.Text = "🔍 Scan DefaultAdmin Remotes"
                return
            end

            -- Find ANY admin-sounding service
            local adminServices = {}
            for _, svc in ipairs(Services:GetChildren()) do
                local lower = string.lower(svc.Name)
                if string.find(lower, "admin") or string.find(lower, "command") or string.find(lower, "default") then
                    table.insert(adminServices, svc)
                end
            end

            if #adminServices == 0 then
                print("[AdminProbe]: No admin-like services found under Knit Services.")
                ScanAdminBtn.Text = "🔍 Scan DefaultAdmin Remotes"
                return
            end

            for _, svc in ipairs(adminServices) do
                print("[AdminProbe]: ── Service: " .. svc:GetFullName())

                -- Enumerate every child recursively (RE, RF, ModuleScripts, etc.)
                local function enumerate(obj, depth)
                    local indent = string.rep("  ", depth)
                    for _, child in ipairs(obj:GetChildren()) do
                        print("[AdminProbe]: " .. indent .. child.ClassName .. " | " .. child.Name)
                        enumerate(child, depth + 1)
                    end
                end
                enumerate(svc, 1)
            end

            ScanAdminBtn.Text = "🔍 Scan DefaultAdmin Remotes"
        end)
    end)

    -- Step 2: Try common RunCommand-style remotes with giveFish
    local RunCmdBtn = Instance.new("TextButton", SettingsPage)
    RunCmdBtn.Size = UDim2.new(0.95, 0, 0, 30)
    RunCmdBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    RunCmdBtn.Text = "⚡ Try RunCommand giveFish"
    RunCmdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RunCmdBtn.Font = Enum.Font.GothamMedium
    RunCmdBtn.TextSize = 13
    Instance.new("UICorner", RunCmdBtn).CornerRadius = UDim.new(0, 6)

    RunCmdBtn.MouseButton1Click:Connect(function()
        RunCmdBtn.Text = "Trying..."
        task.spawn(function()
            local RS = game:GetService("ReplicatedStorage")
            local LocalPlayer = game:GetService("Players").LocalPlayer

            local ok, Services = pcall(function()
                return RS:WaitForChild("Packages",5)
                         :WaitForChild("Knit",5)
                         :WaitForChild("Services",5)
            end)
            if not ok then
                print("[AdminProbe]: Could not reach Knit Services")
                RunCmdBtn.Text = "⚡ Try RunCommand giveFish"
                return
            end

            -- Names that admin systems typically use for their executor remote
            local runRemoteNames = {
                "RunCommand", "ExecuteCommand", "RunCmd", "Execute",
                "Command", "AdminCommand", "HandleCommand", "ProcessCommand",
                "Run", "Invoke", "CallCommand",
            }

            -- Args shapes to try for each remote
            local argShapes = {
                function(r) r:FireServer("giveFish") end,
                function(r) r:FireServer("giveFish", {}) end,
                function(r) r:FireServer("giveFish", LocalPlayer) end,
                function(r) r:FireServer({cmd = "giveFish"}) end,
                function(r) r:FireServer({command = "giveFish", args = {}}) end,
                function(r) r:InvokeServer("giveFish") end,
                function(r) r:InvokeServer("giveFish", LocalPlayer) end,
            }

            local found = 0
            for _, svc in ipairs(Services:GetChildren()) do
                local lower = string.lower(svc.Name)
                if not (string.find(lower, "admin") or string.find(lower, "command") or string.find(lower, "default")) then
                    continue
                end

                for _, container in ipairs(svc:GetChildren()) do
                    for _, name in ipairs(runRemoteNames) do
                        local remote = container:FindFirstChild(name)
                        if not remote then
                            remote = svc:FindFirstChild(name)
                        end
                        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                            found = found + 1
                            print("[AdminProbe]: Trying '" .. name .. "' in " .. remote:GetFullName())
                            for i, fn in ipairs(argShapes) do
                                local attemptOk, err = pcall(fn, remote)
                                print("[AdminProbe]:   Shape " .. i .. " -> ok=" .. tostring(attemptOk) .. (not attemptOk and (" | " .. tostring(err)) or ""))
                            end
                        end
                    end
                end
            end

            if found == 0 then
                print("[AdminProbe]: No RunCommand-style remote found. The admin system likely only listens to player chat — not exploitable via remote.")
            end

            RunCmdBtn.Text = "⚡ Try RunCommand giveFish"
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