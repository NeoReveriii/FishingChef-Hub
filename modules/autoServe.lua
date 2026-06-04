local AutoServe = {}
local loopThread = nil

-- Shared Configuration States
AutoServe.Enabled = false
AutoServe.AutoCookModule = nil -- Reference to AutoCook module for cooking

-- Memory Cache to prevent double-serving stuck VIPs without a timer
local servedNPCsMemory = {}

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

-- Check if player is at restaurant plot
local function IsPlayerAtRestaurant()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return false end
    
    -- Check if player is near their restaurant plot
    local plotPosition = nil
    pcall(function()
        plotPosition = workspace:WaitForChild("Code", 2):WaitForChild("Plots", 2):WaitForChild(LocalPlayer.Name, 2):WaitForChild("STALL", 2):WaitForChild("Baseplate", 2).Position
    end)
    
    if not plotPosition then return false end
    
    local playerPosition = humanoidRootPart.Position
    local distance = (playerPosition - plotPosition).Magnitude
    
    -- If within 50 units of restaurant, consider as being at restaurant
    return distance < 50
end

-- Save current player position
local savedPosition = nil
local function SavePlayerPosition()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        savedPosition = {
            position = humanoidRootPart.Position,
            CFrame = humanoidRootPart.CFrame
        }
        debugLog("Saved player position")
    end
end

-- Restore player position
local function RestorePlayerPosition()
    if not savedPosition then
        debugLog("No saved position to restore")
        return false
    end
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        pcall(function()
            humanoidRootPart.CFrame = savedPosition.CFrame
            debugLog("Restored player position")
        end)
        savedPosition = nil
        return true
    end
    
    return false
end

-- Teleport player to restaurant
local function TeleportToRestaurant()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return false end
    
    local plotPosition = nil
    pcall(function()
        plotPosition = workspace:WaitForChild("Code", 2):WaitForChild("Plots", 2):WaitForChild(LocalPlayer.Name, 2):WaitForChild("STALL", 2):WaitForChild("Baseplate", 2).Position
    end)
    
    if not plotPosition then return false end
    
    pcall(function()
        humanoidRootPart.CFrame = CFrame.new(plotPosition + Vector3.new(0, 5, 0))
        debugLog("Teleported to restaurant")
    end)
    
    task.wait(0.5)
    return true
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

-- CRITICAL FIX: Only considers an NPC valid if the game has assigned it a real 'CHAR' model
local function IsRealCustomer(npc)
    local charVal = npc:FindFirstChild("CHAR")
    return charVal ~= nil and charVal.Value ~= nil
end

-- Get lantern anchor for accurate left/right detection
local function GetLanternAnchor()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local plot = workspace:FindFirstChild("Code") 
        and workspace.Code:FindFirstChild("Plots") 
        and workspace.Code.Plots:FindFirstChild(LocalPlayer.Name)
    
    local stall = plot and plot:FindFirstChild("STALL")
    if not stall then return nil end

    local hangingLantern = stall:FindFirstChild("HangingLantern")
    if hangingLantern then
        local basePart = hangingLantern:FindFirstChild("Base")
        if basePart and basePart:IsA("BasePart") then
            return basePart
        end
    end
    return nil
end

-- Check if NPC is seated
local function IsNPCSeated(npc)
    local animsFolder = npc:FindFirstChild("Anims")
    if animsFolder and animsFolder:FindFirstChild("Sit") then
        debugLog("NPC seated (Anims folder check)")
        return true
    end

    local charVal = npc:FindFirstChild("CHAR")
    if charVal and charVal.Value then
        local npcModel = charVal.Value
        if npcModel and npcModel:IsA("Instance") then
            local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.Sit or humanoid.FloorMaterial == Enum.Material.Air then
                    debugLog("NPC seated (Humanoid check)")
                    return true
                end
            end
        end
    end
    return false
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
    local lanternBase = GetLanternAnchor()
    local validNPCs = {}
    for _, npc in ipairs(activeNPCs:GetChildren()) do
        -- CRITICAL FIX: Only consider NPCs with real CHAR model (filter ghost slots)
        if IsRealCustomer(npc) then
            local position = GetNPCPosition(npc)
            local identity = GetNPCIdentity(npc)
            
            if position then
                local horizontalOffset = 0
                if lanternBase then
                    -- Use lantern anchor for accurate left/right detection
                    local objectVector = position - lanternBase.Position
                    horizontalOffset = objectVector:Dot(lanternBase.CFrame.RightVector)
                else
                    -- Fallback to X-coordinate if lantern not found
                    horizontalOffset = position.X
                end
                
                table.insert(validNPCs, {
                    npc = npc, -- Keeps tracking memory tied directly to this Roblox Instance reference
                    position = position,
                    identity = identity,
                    horizontalOffset = horizontalOffset
                })
                debugLog("Found valid NPC: " .. tostring(identity) .. " at X: " .. tostring(position.X))
            end
        end
    end
    
    -- Sort left-to-right relative to lantern anchor
    table.sort(validNPCs, function(a, b)
        return a.horizontalOffset < b.horizontalOffset
    end)
    
    -- Assign slot positions
    local slot1 = validNPCs[1] or nil
    local slot2 = validNPCs[2] or nil
    
    debugLog("Slot 1 (Left): " .. tostring(slot1 and slot1.identity or "Empty"))
    debugLog("Slot 2 (Right): " .. tostring(slot2 and slot2.identity or "Empty"))
    
    return slot1, slot2
end

-- Phase 2: Smart Fulfillment & Targeted Cooking Chain
local function Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, Cook, AutoCookModule)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local humanoid = character:WaitForChild("Humanoid")
    
    debugLog("Starting smart fulfillment for: " .. targetFoodName .. " (Recipe: " .. targetRecipe .. ", Fish: " .. targetFish .. ")")
    
    -- Helper function to equip tool with hotbar management
    local function safeEquipTool(tool)
        -- Count equipped tools
        local equippedCount = 0
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                equippedCount = equippedCount + 1
            end
        end
        
        -- If hotbar is full (typically 6 slots), unequip a non-food tool first
        if equippedCount >= 6 then
            debugLog("Hotbar full, unequipping a tool to make room...")
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("Tool") and child.Name ~= targetFoodName then
                    humanoid:UnequipTools(child)
                    task.wait(0.1)
                    break
                end
            end
        end
        
        humanoid:EquipTool(tool)
        task.wait(0.2)
    end
    
    -- Step 1: Check Hotbar/Backpack for tool
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool.Name == targetFoodName then
            debugLog("Found " .. targetFoodName .. " in hotbar, equipping...")
            safeEquipTool(tool)
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
    
    -- Step 3: Auto-cook using AutoCook module
    if targetFish and AutoCookModule then
        debugLog("Food not found, attempting to auto-cook with specific fish: " .. targetFish .. " using AutoCook module")
        
        local cookSuccess = pcall(function()
            return AutoCookModule.CookSingle(targetRecipe, targetFish)
        end)
        
        if cookSuccess then
            debugLog("Successfully cooked " .. targetRecipe .. " with " .. targetFish)
            task.wait(1) -- Wait for food to be added to inventory
            
            -- Try to equip and serve the cooked food
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool.Name == targetFoodName then
                    debugLog("Found " .. targetFoodName .. " in hotbar after cooking, equipping...")
                    safeEquipTool(tool)
                    ServeFood(targetNPC.npc, targetFoodName, targetSlot)
                    return true
                end
            end
            
            -- Check character for equipped tool
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and tool.Name == targetFoodName then
                    debugLog("Found " .. targetFoodName .. " equipped after cooking, serving...")
                    ServeFood(targetNPC.npc, targetFoodName, targetSlot)
                    return true
                end
            end
            
            debugLog("Could not find " .. targetFoodName .. " after cooking")
        else
            debugLog("AutoCook failed to cook " .. targetRecipe .. " with " .. targetFish)
        end
    else
        debugLog("No target fish specified or AutoCook module not available")
    end
    
    debugLog("Failed to fulfill order for: " .. targetFoodName)
    return false
end

-- Main Start Function
function AutoServe.Start()
    if loopThread then task.cancel(loopThread) end
    AutoServe.Enabled = true -- Fixes state check immediately
    
    print("[AutoServe]: Thread initialized with Loop-Fix Memory.")
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
                local currentTime = os.time()
                
                -- Clean up memory cache (items older than 75 seconds get released)
                for targetInstance, timestamp in pairs(servedNPCsMemory) do
                    if currentTime - timestamp > 75 then
                        servedNPCsMemory[targetInstance] = nil
                    end
                end
                
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
                    if slot1 and not servedNPCsMemory[slot1.npc] then
                        targetNPC = slot1
                        targetSlot = 1
                        targetFoodName = "Sashimi" -- Default for normal NPCs
                        targetRecipe = "Sashimi"
                        targetFish = nil -- Any fish for normal NPCs
                    end
                    if not targetNPC and slot2 and not servedNPCsMemory[slot2.npc] then
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
                    if slot1 and slot1.identity and not servedNPCsMemory[slot1.npc] then
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
                    
                    -- Check Slot 2
                    if not targetNPC and slot2 and slot2.identity and not servedNPCsMemory[slot2.npc] then
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
                
                -- Scenario C: No Target Found (or target already has been served)
                if not targetNPC then
                    debugLog("No unserved targets found in slots. Cycling plot alternative...")
                    pcall(function()
                        OpenPlot:FireServer(false)
                        task.wait(0.5)
                        OpenPlot:FireServer(true)
                    end)
                    task.wait(5)
                    return
                end
                
                -- Phase 2: Smart Fulfillment
                if targetNPC and targetFoodName then
                    -- Wait for NPC to be seated before serving
                    local seatTimeout = 0
                    while not IsNPCSeated(targetNPC.npc) and seatTimeout < 8 do
                        task.wait(0.5)
                        seatTimeout = seatTimeout + 0.5
                    end
                    
                    local success = Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, Cook, AutoServe.AutoCookModule)
                    if success then
                        debugLog("Successfully served customer! Blacklisting unique NPC object reference.")
                        
                        -- Save the unique Folder instance to memory cache
                        servedNPCsMemory[targetNPC.npc] = os.time()
                        
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
    
    print("[AutoServe]: Thread cleanly terminated.")
end

return AutoServe
