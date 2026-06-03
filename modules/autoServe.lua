local AutoServe = {}
local loopThread = nil

-- Shared Configuration States
AutoServe.Enabled = false

-- UI Configuration
AutoServe.Config = {
    ServeNormalNPCs = true,
    ServeSpecialGuests = false,
    SelectedVIPs = {} -- Array of selected VIP names
}

-- VIP Hardcoded Menu Dictionary (includes recipe type and specific fish)
local VIP_ORDERS = {
    ["Rich Guy"]     = {recipe = "Nigiri", fish = "great_white_shark", displayName = "Great White Shark Nigiri"},
    ["Ninja"]        = {recipe = "Sushi", fish = "salmon", displayName = "Salmon Sushi"},
    ["Food Critic"]  = {recipe = "Nigiri", fish = "pufferfish", displayName = "Pufferfish Nigiri"},
    ["Sushi Chef"]   = {recipe = "Sushi", fish = "shrimp", displayName = "Shrimp Sushi"},
}

-- Available VIP list for dropdown
local AVAILABLE_VIPS = {
    "Rich Guy",
    "Ninja",
    "Food Critic",
    "Sushi Chef"
}

-- Debug function
local function debugLog(message)
    print("[AutoServe]: " .. message)
end

-- Fish Scanner - Fetches all available fish from inventory (similar to autoSell/autoCook)
local function FetchAvailableFish()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local ok, RequestFishData = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("Fish", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("RequestFishData", 5)
    end)
    
    if not ok or not RequestFishData then
        debugLog("Could not reach RequestFishData RF.")
        return {}
    end
    
    local success, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    
    if not success or type(inventory) ~= "table" then
        debugLog("RequestFishData returned no data.")
        return {}
    end
    
    -- Collect unique fish names
    local uniqueFish = {}
    local added = {}
    for _, item in pairs(inventory) do
        local fishName = item.CF or item.Name
        if fishName and type(fishName) == "string" and not added[fishName] then
            added[fishName] = true
            table.insert(uniqueFish, fishName)
        end
    end
    
    debugLog("Found " .. #uniqueFish .. " unique fish types in inventory.")
    return uniqueFish
end

-- UI Creation
function AutoServe.CreateUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Check if UI already exists
    if PlayerGui:FindFirstChild("AutoServeUI") then
        PlayerGui.AutoServeUI:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoServeUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "AutoServe Configuration"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Toggle A: Serve Normal NPCs
    local toggleAFrame = Instance.new("Frame")
    toggleAFrame.Name = "ToggleAFrame"
    toggleAFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleAFrame.Position = UDim2.new(0, 10, 0, 50)
    toggleAFrame.BackgroundTransparency = 1
    toggleAFrame.Parent = mainFrame
    
    local toggleAText = Instance.new("TextLabel")
    toggleAText.Size = UDim2.new(0.7, 0, 1, 0)
    toggleAText.BackgroundTransparency = 1
    toggleAText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleAText.Text = "Serve Normal NPCs"
    toggleAText.TextSize = 14
    toggleAText.TextXAlignment = Enum.TextXAlignment.Left
    toggleAText.Font = Enum.Font.Gotham
    toggleAText.Parent = toggleAFrame
    
    local toggleAButton = Instance.new("TextButton")
    toggleAButton.Name = "ToggleAButton"
    toggleAButton.Size = UDim2.new(0.25, 0, 0.7, 0)
    toggleAButton.Position = UDim2.new(0.75, 0, 0.15, 0)
    toggleAButton.BackgroundColor3 = AutoServe.Config.ServeNormalNPCs and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(158, 158, 158)
    toggleAButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleAButton.Text = AutoServe.Config.ServeNormalNPCs and "ON" or "OFF"
    toggleAButton.TextSize = 12
    toggleAButton.Font = Enum.Font.GothamBold
    toggleAButton.Parent = toggleAFrame
    
    toggleAButton.MouseButton1Click:Connect(function()
        AutoServe.Config.ServeNormalNPCs = not AutoServe.Config.ServeNormalNPCs
        toggleAButton.BackgroundColor3 = AutoServe.Config.ServeNormalNPCs and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(158, 158, 158)
        toggleAButton.Text = AutoServe.Config.ServeNormalNPCs and "ON" or "OFF"
        debugLog("Toggle A (Serve Normal NPCs): " .. tostring(AutoServe.Config.ServeNormalNPCs))
    end)
    
    -- Toggle B: Serve Special Guests
    local toggleBFrame = Instance.new("Frame")
    toggleBFrame.Name = "ToggleBFrame"
    toggleBFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleBFrame.Position = UDim2.new(0, 10, 0, 100)
    toggleBFrame.BackgroundTransparency = 1
    toggleBFrame.Parent = mainFrame
    
    local toggleBText = Instance.new("TextLabel")
    toggleBText.Size = UDim2.new(0.7, 0, 1, 0)
    toggleBText.BackgroundTransparency = 1
    toggleBText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBText.Text = "Serve Special Guests"
    toggleBText.TextSize = 14
    toggleBText.TextXAlignment = Enum.TextXAlignment.Left
    toggleBText.Font = Enum.Font.Gotham
    toggleBText.Parent = toggleBFrame
    
    local toggleBButton = Instance.new("TextButton")
    toggleBButton.Name = "ToggleBButton"
    toggleBButton.Size = UDim2.new(0.25, 0, 0.7, 0)
    toggleBButton.Position = UDim2.new(0.75, 0, 0.15, 0)
    toggleBButton.BackgroundColor3 = AutoServe.Config.ServeSpecialGuests and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(158, 158, 158)
    toggleBButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBButton.Text = AutoServe.Config.ServeSpecialGuests and "ON" or "OFF"
    toggleBButton.TextSize = 12
    toggleBButton.Font = Enum.Font.GothamBold
    toggleBButton.Parent = toggleBFrame
    
    toggleBButton.MouseButton1Click:Connect(function()
        AutoServe.Config.ServeSpecialGuests = not AutoServe.Config.ServeSpecialGuests
        toggleBButton.BackgroundColor3 = AutoServe.Config.ServeSpecialGuests and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(158, 158, 158)
        toggleBButton.Text = AutoServe.Config.ServeSpecialGuests and "ON" or "OFF"
        debugLog("Toggle B (Serve Special Guests): " .. tostring(AutoServe.Config.ServeSpecialGuests))
    end)
    
    -- VIP Dropdown Label
    local vipLabel = Instance.new("TextLabel")
    vipLabel.Name = "VIPLabel"
    vipLabel.Size = UDim2.new(1, -20, 0, 25)
    vipLabel.Position = UDim2.new(0, 10, 0, 150)
    vipLabel.BackgroundTransparency = 1
    vipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    vipLabel.Text = "Select VIPs to Target:"
    vipLabel.TextSize = 14
    vipLabel.TextXAlignment = Enum.TextXAlignment.Left
    vipLabel.Font = Enum.Font.Gotham
    vipLabel.Parent = mainFrame
    
    -- VIP Selection Frame
    local vipFrame = Instance.new("ScrollingFrame")
    vipFrame.Name = "VIPFrame"
    vipFrame.Size = UDim2.new(1, -20, 0, 60)
    vipFrame.Position = UDim2.new(0, 10, 0, 180)
    vipFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    vipFrame.BorderSizePixel = 0
    vipFrame.ScrollBarThickness = 4
    vipFrame.Parent = mainFrame
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = vipFrame
    
    -- Create VIP checkboxes
    for i, vipName in ipairs(AVAILABLE_VIPS) do
        local vipButton = Instance.new("TextButton")
        vipButton.Name = "VIP_" .. vipName
        vipButton.Size = UDim2.new(1, 0, 0, 25)
        vipButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        vipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        vipButton.Text = "☐ " .. vipName
        vipButton.TextSize = 12
        vipButton.Font = Enum.Font.Gotham
        vipButton.Parent = vipFrame
        
        vipButton.MouseButton1Click:Connect(function()
            local index = table.find(AutoServe.Config.SelectedVIPs, vipName)
            if index then
                table.remove(AutoServe.Config.SelectedVIPs, index)
                vipButton.Text = "☐ " .. vipName
                vipButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                table.insert(AutoServe.Config.SelectedVIPs, vipName)
                vipButton.Text = "☑ " .. vipName
                vipButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            end
            debugLog("Selected VIPs: " .. table.concat(AutoServe.Config.SelectedVIPs, ", "))
        end)
    end
    
    debugLog("UI Created successfully")
end

-- Serve Food Wrapper Function
local function ServeFood(npcInstance, foodName, targetSeatSlot)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Knit = Packages:WaitForChild("Knit")
    local Services = Knit:WaitForChild("Services")
    local FishServices = Services:WaitForChild("Fish")
    local FishRE = FishServices:WaitForChild("RE")
    local StoreFood = FishRE:WaitForChild("StoreFood")
    
    -- Verify food is equipped in character's hand before serving
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        -- Check if food tool is already equipped
        local foodEquipped = false
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == foodName then
                foodEquipped = true
                break
            end
        end
        
        -- If not equipped, try to equip from backpack
        if not foodEquipped then
            for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if tool.Name == foodName then
                    humanoid:EquipTool(tool)
                    task.wait(0.3) -- Wait for equip to complete
                    foodEquipped = true
                    break
                end
            end
        end
        
        if foodEquipped then
            debugLog("Food " .. foodName .. " is equipped, serving...")
        else
            debugLog("Warning: Could not equip " .. foodName .. " before serving")
        end
    end
    
    pcall(function()
        StoreFood:FireServer(npcInstance)
        debugLog("Served " .. foodName .. " to NPC at Slot " .. tostring(targetSeatSlot))
    end)
end

-- Get NPC Position Safely
local function GetNPCPosition(npc)
    local location = npc:FindFirstChild("Location")
    if not location then return nil end
    
    local success, value = pcall(function()
        return location.Value
    end)
    
    if not success then return nil end
    
    -- Handle both CFrame and Vector3
    if typeof(value) == "CFrame" then
        return value.Position
    elseif typeof(value) == "Vector3" then
        return value
    end
    
    return nil
end

-- Get NPC Identity Safely
local function GetNPCIdentity(npc)
    -- Try DisplayName first
    local displayName = npc:FindFirstChild("DisplayName")
    if displayName then
        local success, name = pcall(function()
            return displayName.Value
        end)
        if success and name then
            return name
        end
    end
    
    -- Try SpecialCustomer with pcall for streaming safety
    local specialCustomer = npc:FindFirstChild("SpecialCustomer")
    if specialCustomer then
        local success, specialObj = pcall(function()
            return specialCustomer.Value
        end)
        if success and specialObj then
            local nameSuccess, name = pcall(function()
                return specialObj.Name
            end)
            if nameSuccess and name then
                return name
            end
        end
    end
    
    return nil
end

-- Check if NPC is valid
local function IsValidNPC(npc)
    local char = npc:FindFirstChild("CHAR")
    if not char then return false end
    
    local success, value = pcall(function()
        return char.Value
    end)
    
    return success and value ~= nil
end

-- Phase 1: Radar, Position Detection & Recycling
local function Phase1_RadarDetection(OpenPlot, RequestRestaurauntData)
    local Workspace = game:GetService("Workspace")
    
    -- Open plot and wait for customers
    pcall(function()
        OpenPlot:FireServer(true)
        debugLog("Plot opened, waiting 10 seconds for customers...")
    end)
    
    task.wait(10)
    
    -- Get customer folder
    local codeFolder = Workspace:FindFirstChild("Code")
    if not codeFolder then
        debugLog("No Code folder found")
        return nil, nil
    end
    
    local activeNPCs = codeFolder:FindFirstChild("ActiveNPCs")
    if not activeNPCs then
        debugLog("No ActiveNPCs folder found")
        return nil, nil
    end
    
    -- Collect valid NPCs
    local validNPCs = {}
    for _, npc in ipairs(activeNPCs:GetChildren()) do
        if IsValidNPC(npc) then
            local position = GetNPCPosition(npc)
            local identity = GetNPCIdentity(npc)
            
            if position then
                table.insert(validNPCs, {
                    npc = npc,
                    position = position,
                    identity = identity,
                    xCoord = position.X
                })
                debugLog("Found valid NPC: " .. tostring(identity) .. " at X: " .. tostring(position.X))
            end
        end
    end
    
    -- Sort by X-coordinate (lowest to highest)
    table.sort(validNPCs, function(a, b)
        return a.xCoord < b.xCoord
    end)
    
    -- Assign slot positions
    local slot1 = validNPCs[1] or nil
    local slot2 = validNPCs[2] or nil
    
    debugLog("Slot 1 (Left): " .. tostring(slot1 and slot1.identity or "Empty"))
    debugLog("Slot 2 (Right): " .. tostring(slot2 and slot2.identity or "Empty"))
    
    return slot1, slot2
end

-- Phase 2: Smart Fulfillment & Targeted Cooking Chain
local function Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, Cook)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    
    debugLog("Starting smart fulfillment for: " .. targetFoodName .. " (Recipe: " .. targetRecipe .. ", Fish: " .. targetFish .. ")")
    
    -- Step 1: Check Hotbar/Backpack for tool
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool.Name == targetFoodName then
            debugLog("Found " .. targetFoodName .. " in hotbar, equipping...")
            character.Humanoid:EquipTool(tool)
            task.wait(0.2)
            ServeFood(targetNPC.npc, targetFoodName, targetSlot)
            return true
        end
    end
    
    -- Check character for equipped tool
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == targetFoodName then
            debugLog("Found " .. targetFoodName .. " equipped, serving...")
            ServeFood(targetNPC.npc, targetFoodName, targetSlot)
            return true
        end
    end
    
    -- Step 2: Check Inventory for cooked item
    local success, restaurantData = pcall(function()
        return RequestRestaurauntData:InvokeServer()
    end)
    
    if success and restaurantData then
        debugLog("Checking inventory for cooked food...")
        -- Parse restaurant data structure (adjust based on actual data format)
        if restaurantData.FoodStorage then
            for _, foodItem in ipairs(restaurantData.FoodStorage) do
                if foodItem.Name == targetFoodName and foodItem.Amount > 0 then
                    debugLog("Found " .. targetFoodName .. " in food storage, equipping...")
                    pcall(function()
                        EquipPlate:FireServer({
                            CF = foodItem.CF or "unknown",
                            Name = foodItem.Name,
                            Amount = 1,
                            ID = foodItem.ID,
                            Data = foodItem.Data,
                            Value = foodItem.Value
                        })
                    end)
                    task.wait(0.3)
                    ServeFood(targetNPC.npc, targetFoodName, targetSlot)
                    return true
                end
            end
        end
    end
    
    -- Step 3: Auto-cook from raw fish inventory
    debugLog("Food not found, attempting to auto-cook with specific fish: " .. targetFish)
    
    -- Get raw fish inventory
    local fishSuccess, fishData = pcall(function()
        local FishRF = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("Fish"):WaitForChild("RF")
        local RequestFishData = FishRF:WaitForChild("RequestFishData")
        return RequestFishData:InvokeServer()
    end)
    
    if fishSuccess and fishData then
        -- Find the specific fish in inventory (case-insensitive match)
        for _, fishItem in ipairs(fishData) do
            local fishName = fishItem.CF or fishItem.Name
            local fishNameLower = string.lower(fishName)
            local targetFishLower = string.lower(targetFish)
            
            if fishNameLower:find(targetFishLower) then
                debugLog("Found raw " .. fishName .. " (matching " .. targetFish .. "), cooking...")
                
                -- Cook the food with the specified recipe
                local dataValue = 4 -- Default for Nigiri/Sushi (2 cuts)
                if targetRecipe == "Sashimi" then
                    dataValue = 5 -- Sashimi (3 cuts)
                end
                
                local cookPayload = {
                    CF = fishItem.CF or fishItem.Name,
                    Name = "Fish Filet",
                    Amount = 1,
                    ID = fishItem.ID,
                    Data = dataValue,
                    Value = 0
                }
                
                pcall(function()
                    Cook:InvokeServer(targetRecipe, cookPayload)
                    debugLog("Cooked " .. targetRecipe .. " with " .. fishName)
                end)
                
                task.wait(0.5)
                
                -- Equip and serve
                pcall(function()
                    EquipPlate:FireServer({
                        CF = fishItem.CF or fishItem.Name,
                        Name = targetFoodName,
                        Amount = 1,
                        ID = fishItem.ID,
                        Data = dataValue,
                        Value = 0
                    })
                end)
                
                task.wait(0.3)
                ServeFood(targetNPC.npc, targetFoodName, targetSlot)
                return true
            end
        end
        
        debugLog("Could not find " .. targetFish .. " in inventory")
    else
        debugLog("Failed to fetch fish inventory")
    end
    
    debugLog("Failed to fulfill order for: " .. targetFoodName)
    return false
end

-- Main Start Function
function AutoServe.Start()
    if loopThread then task.cancel(loopThread) end
    
    -- Create UI
    AutoServe.CreateUI()
    
    print("[AutoServe]: Thread initialized.")
    debugLog("Starting AutoServe with configuration:")
    debugLog("  Serve Normal NPCs: " .. tostring(AutoServe.Config.ServeNormalNPCs))
    debugLog("  Serve Special Guests: " .. tostring(AutoServe.Config.ServeSpecialGuests))
    debugLog("  Selected VIPs: " .. table.concat(AutoServe.Config.SelectedVIPs, ", "))
    
    loopThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        
        local Packages = ReplicatedStorage:WaitForChild("Packages")
        local Knit = Packages:WaitForChild("Knit")
        local Services = Knit:WaitForChild("Services")
        
        -- GameHandler Services
        local GameHandlerServices = Services:WaitForChild("GameHandler")
        local GameHandlerRE = GameHandlerServices:WaitForChild("RE")
        local OpenPlot = GameHandlerRE:WaitForChild("OpenPlot")
        
        -- Fish Services
        local FishServices = Services:WaitForChild("Fish")
        local FishRE = FishServices:WaitForChild("RE")
        local FishRF = FishServices:WaitForChild("RF")
        
        -- Remote Events
        local EquipPlate = FishRE:WaitForChild("EquipPlate")
        
        -- Remote Functions
        local RequestRestaurauntData = FishRF:WaitForChild("RequestRestaurauntData")
        local Cook = FishRF:WaitForChild("Cook")
        
        debugLog("Successfully loaded all required remotes")
        
        while AutoServe.Enabled do
            pcall(function()
                -- Phase 1: Radar Detection
                local slot1, slot2 = Phase1_RadarDetection(OpenPlot, RequestRestaurauntData)
                
                if not slot1 and not slot2 then
                    -- No customers found, recycle
                    debugLog("No customers found, recycling...")
                    pcall(function()
                        OpenPlot:FireServer(false)
                        task.wait(0.5)
                        OpenPlot:FireServer(true)
                    end)
                    task.wait(10)
                    return
                end
                
                -- Decision Branching
                local targetNPC = nil
                local targetSlot = 0
                local targetFoodName = nil
                local targetRecipe = nil
                local targetFish = nil
                
                -- Scenario A: Normal Mode Only
                if AutoServe.Config.ServeNormalNPCs and not AutoServe.Config.ServeSpecialGuests then
                    debugLog("Scenario A: Normal Mode - serving any customer")
                    if slot1 then
                        targetNPC = slot1
                        targetSlot = 1
                        targetFoodName = "Sashimi" -- Default for normal NPCs
                        targetRecipe = "Sashimi"
                        targetFish = nil -- Any fish for normal NPCs
                    elseif slot2 then
                        targetNPC = slot2
                        targetSlot = 2
                        targetFoodName = "Sashimi"
                        targetRecipe = "Sashimi"
                        targetFish = nil
                    end
                end
                
                -- Scenario B: VIP Target Mode
                if AutoServe.Config.ServeSpecialGuests and #AutoServe.Config.SelectedVIPs > 0 then
                    debugLog("Scenario B: VIP Target Mode - checking for selected VIPs")
                    
                    -- Check Slot 1
                    if slot1 and slot1.identity then
                        for _, vipName in ipairs(AutoServe.Config.SelectedVIPs) do
                            if slot1.identity:find(vipName) then
                                targetNPC = slot1
                                targetSlot = 1
                                local vipOrder = VIP_ORDERS[vipName]
                                targetFoodName = vipOrder.displayName
                                targetRecipe = vipOrder.recipe
                                targetFish = vipOrder.fish
                                debugLog("Found target VIP " .. vipName .. " in Slot 1 - " .. targetFoodName)
                                break
                            end
                        end
                    end
                    
                    -- Check Slot 2 if not found in Slot 1
                    if not targetNPC and slot2 and slot2.identity then
                        for _, vipName in ipairs(AutoServe.Config.SelectedVIPs) do
                            if slot2.identity:find(vipName) then
                                targetNPC = slot2
                                targetSlot = 2
                                local vipOrder = VIP_ORDERS[vipName]
                                targetFoodName = vipOrder.displayName
                                targetRecipe = vipOrder.recipe
                                targetFish = vipOrder.fish
                                debugLog("Found target VIP " .. vipName .. " in Slot 2 - " .. targetFoodName)
                                break
                            end
                        end
                    end
                end
                
                -- Scenario C: No Target Found
                if not targetNPC then
                    debugLog("Scenario C: No target found, recycling...")
                    pcall(function()
                        OpenPlot:FireServer(false)
                        task.wait(0.5)
                        OpenPlot:FireServer(true)
                    end)
                    task.wait(10)
                    return
                end
                
                -- Phase 2: Smart Fulfillment
                if targetNPC and targetFoodName then
                    local success = Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, Cook)
                    if success then
                        debugLog("Successfully served customer")
                        task.wait(2)
                    else
                        debugLog("Failed to serve customer, recycling...")
                        pcall(function()
                            OpenPlot:FireServer(false)
                            task.wait(0.5)
                            OpenPlot:FireServer(true)
                        end)
                        task.wait(10)
                    end
                end
            end)
            
            task.wait(1)
        end
    end)
end

function AutoServe.Stop()
    AutoServe.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    
    -- Close plot
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Packages = ReplicatedStorage:WaitForChild("Packages")
        local Knit = Packages:WaitForChild("Knit")
        local Services = Knit:WaitForChild("Services")
        local GameHandlerServices = Services:WaitForChild("GameHandler")
        local GameHandlerRE = GameHandlerServices:WaitForChild("RE")
        local OpenPlot = GameHandlerRE:WaitForChild("OpenPlot")
        OpenPlot:FireServer(false)
    end)
    
    -- Remove UI
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui then
        local ui = PlayerGui:FindFirstChild("AutoServeUI")
        if ui then
            ui:Destroy()
        end
    end
    
    print("[AutoServe]: Thread cleanly terminated.")
end

return AutoServe
