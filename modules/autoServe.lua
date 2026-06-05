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
    SelectedVIPs = {}, -- Array of selected VIP names
    
    -- Normal NPC Order Configuration - separate fish for each recipe
    NormalOrder = {
        Sashimi = {
            Fish = "salmon",
            DisplayName = "Salmon Sashimi"
        },
        Nigiri = {
            Fish = "tuna",
            DisplayName = "Tuna Nigiri"
        },
        Sushi = {
            Fish = "shrimp",
            DisplayName = "Shrimp Sushi"
        }
    }
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

-- CRITICAL FIX: Only considers an NPC valid if it has a physical character model attached
local function IsRealCustomer(npc)
    local charVal = npc:FindFirstChild("CHAR")
    return charVal ~= nil and charVal.Value ~= nil
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
    
    if typeof(value) == "CFrame" then
        return value.Position
    elseif typeof(value) == "Vector3" then
        return value
    end
    
    return nil
end

-- Get NPC Identity Safely
local function GetNPCIdentity(npc)
    local displayName = npc:FindFirstChild("DisplayName")
    if displayName and displayName.Value then
        return displayName.Value
    end
    
    local specialCustomer = npc:FindFirstChild("SpecialCustomer")
    if specialCustomer and specialCustomer.Value then
        return specialCustomer.Value.Name
    end
    
    return npc.Name or "Unknown Customer"
end

-- Get NPC Requested Recipe (for normal NPCs)
local function GetNPCRequestedRecipe(npc)
    local requestedDish = npc:FindFirstChild("RequestedDish")
    if requestedDish and requestedDish.Value then
        local dishName = tostring(requestedDish.Value)
        -- Normalize to match our recipe names
        if dishName:find("Sashimi") then return "Sashimi" end
        if dishName:find("Nigiri") then return "Nigiri" end
        if dishName:find("Sushi") then return "Sushi" end
    end
    
    -- Fallback: check identity for hints
    local identity = GetNPCIdentity(npc)
    if identity:find("Sashimi") then return "Sashimi" end
    if identity:find("Nigiri") then return "Nigiri" end
    if identity:find("Sushi") then return "Sushi" end
    
    -- Default to Sashimi if no indication
    return "Sashimi"
end

-- Check if NPC is seated
local function IsNPCSeated(npc)
    local charVal = npc:FindFirstChild("CHAR")
    if charVal and charVal.Value then
        local npcModel = charVal.Value
        if npcModel and npcModel:IsA("Instance") then
            local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.Sit or humanoid.FloorMaterial == Enum.Material.Air then
                    return true
                end
            end
        end
    end

    local animsFolder = npc:FindFirstChild("Anims")
    if animsFolder and animsFolder:FindFirstChild("Sit") then
        return true
    end

    return false
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

-- Serve Food Wrapper Function
local function ServeFood(npcInstance, foodName, targetSeatSlot)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StoreFood = ReplicatedStorage.Packages.Knit.Services.Fish.RE.StoreFood
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        local foodEquipped = false
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == foodName then
                foodEquipped = true
                break
            end
        end
        
        if not foodEquipped then
            for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if tool.Name == foodName then
                    humanoid:EquipTool(tool)
                    task.wait(0.3)
                    foodEquipped = true
                    break
                end
            end
        end
    end
    
    pcall(function()
        StoreFood:FireServer(npcInstance)
        debugLog("Served " .. foodName .. " to NPC at Slot " .. tostring(targetSeatSlot))
    end)
end

-- Phase 1: Radar, Position Detection & Recycling (Fully Filtered)
local function Phase1_RadarDetection(OpenPlot)
    local Workspace = game:GetService("Workspace")
    
    pcall(function()
        OpenPlot:FireServer(true)
    end)
    
    local codeFolder = Workspace:FindFirstChild("Code")
    if not codeFolder then return nil, nil end
    
    local activeNPCs = codeFolder:FindFirstChild("ActiveNPCs")
    if not activeNPCs then return nil, nil end
    
    local lanternBase = GetLanternAnchor()
    local validNPCs = {}
    
    for _, npc in ipairs(activeNPCs:GetChildren()) do
        -- GHOST FILTER: Only look at folders that have a physical character
        if IsRealCustomer(npc) then
            local identity = GetNPCIdentity(npc)
            local position = GetNPCPosition(npc)
            
            if position then
                local horizontalOffset = 0
                if lanternBase then
                    local objectVector = position - lanternBase.Position
                    horizontalOffset = objectVector:Dot(lanternBase.CFrame.RightVector)
                else
                    horizontalOffset = position.X
                end
                
                -- CRITICAL FIX: Track them even if standing so we don't spam close the stall on them!
                table.insert(validNPCs, {
                    npc = npc, 
                    position = position,
                    identity = identity,
                    horizontalOffset = horizontalOffset
                })
                
                if IsNPCSeated(npc) then
                    debugLog("[✔ SEATED] " .. identity)
                else
                    debugLog("[⏳ WALKING] " .. identity .. " (Waiting to sit...)")
                end
            end
        end
    end
    
    -- Sort left-to-right relative to anchor layout
    table.sort(validNPCs, function(a, b)
        return a.horizontalOffset < b.horizontalOffset
    end)
    
    local slot1 = validNPCs[1] or nil
    local slot2 = validNPCs[2] or nil
    
    return slot1, slot2
end

-- Phase 2: Smart Fulfillment & Targeted Cooking Chain
local function Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, AutoCookModule)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local humanoid = character:WaitForChild("Humanoid")
    
    local function safeEquipTool(tool)
        local equippedCount = 0
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then equippedCount = equippedCount + 1 end
        end
        
        if equippedCount >= 6 then
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
    
    -- Check Hotbar
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool.Name == targetFoodName then
            safeEquipTool(tool)
            ServeFood(targetNPC.npc, targetFoodName, targetSlot)
            return true
        end
    end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == targetFoodName then
            ServeFood(targetNPC.npc, targetFoodName, targetSlot)
            return true
        end
    end
    
    -- Check Storage Inventory
    local success, restaurantData = pcall(function() return RequestRestaurauntData:InvokeServer() end)
    if success and restaurantData and restaurantData.FoodStorage then
        for _, foodItem in ipairs(restaurantData.FoodStorage) do
            if foodItem.Name == targetFoodName and foodItem.Amount > 0 then
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
    
    -- Auto Cook Execution
    if targetFish and AutoCookModule then
        local cookSuccess = pcall(function() return AutoCookModule.CookSingle(targetRecipe, targetFish) end)
        if cookSuccess then
            task.wait(1)
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool.Name == targetFoodName then
                    safeEquipTool(tool)
                    ServeFood(targetNPC.npc, targetFoodName, targetSlot)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Main Start Function
function AutoServe.Start()
    if loopThread then task.cancel(loopThread) end
    AutoServe.Enabled = true
    
    print("[AutoServe]: Started Main Loop with Ghost-Filtering Configuration.")
    
    loopThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Services = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
        
        local OpenPlot = Services:WaitForChild("GameHandler"):WaitForChild("RE"):WaitForChild("OpenPlot")
        local FishServices = Services:WaitForChild("Fish")
        local EquipPlate = FishServices:WaitForChild("RE"):WaitForChild("EquipPlate")
        local RequestRestaurauntData = FishServices:WaitForChild("RF"):WaitForChild("RequestRestaurauntData")
        
        while AutoServe.Enabled do
            local loopsucceeded, errorMsg = pcall(function()
                local currentTime = os.time()
                
                -- Cache Timout Cleanup
                for targetInstance, timestamp in pairs(servedNPCsMemory) do
                    if currentTime - timestamp > 75 then
                        servedNPCsMemory[targetInstance] = nil
                    end
                end
                
                -- Check Seats
                local slot1, slot2 = Phase1_RadarDetection(OpenPlot)
                
                -- If completely empty, wait gracefully for spawns
                if not slot1 and not slot2 then
                    debugLog("Waiting 8 seconds for new batch to populate...")
                    task.wait(8)
                    slot1, slot2 = Phase1_RadarDetection(OpenPlot)
                end
                
                local targetNPC = nil
                local targetSlot = 0
                local targetFoodName = nil
                local targetRecipe = nil
                local targetFish = nil
                
                -- Branch A: Targeted VIP Mode (Priority 1)
                if AutoServe.Config.ServeSpecialGuests and #AutoServe.Config.SelectedVIPs > 0 then
                    if slot1 and slot1.identity and not servedNPCsMemory[slot1.npc] then
                        for _, vipName in ipairs(AutoServe.Config.SelectedVIPs) do
                            if slot1.identity:find(vipName) then
                                targetNPC = slot1; targetSlot = 1
                                local vipOrder = VIP_ORDERS[vipName]
                                targetFoodName = vipOrder.displayName; targetRecipe = vipOrder.recipe; targetFish = vipOrder.fish
                                break
                            end
                        end
                    end
                    if not targetNPC and slot2 and slot2.identity and not servedNPCsMemory[slot2.npc] then
                        for _, vipName in ipairs(AutoServe.Config.SelectedVIPs) do
                            if slot2.identity:find(vipName) then
                                targetNPC = slot2; targetSlot = 2
                                local vipOrder = VIP_ORDERS[vipName]
                                targetFoodName = vipOrder.displayName; targetRecipe = vipOrder.recipe; targetFish = vipOrder.fish
                                break
                            end
                        end
                    end
                end
                
                -- Branch B: Normal Serving Mode (Priority 2 - only runs if VIP mode didn't find target)
                if not targetNPC and AutoServe.Config.ServeNormalNPCs then
                    if slot1 and not servedNPCsMemory[slot1.npc] then
                        targetNPC = slot1; targetSlot = 1
                        local requestedRecipe = GetNPCRequestedRecipe(slot1.npc)
                        targetRecipe = requestedRecipe
                        targetFish = AutoServe.Config.NormalOrder[requestedRecipe].Fish
                        targetFoodName = AutoServe.Config.NormalOrder[requestedRecipe].DisplayName
                    elseif slot2 and not servedNPCsMemory[slot2.npc] then
                        targetNPC = slot2; targetSlot = 2
                        local requestedRecipe = GetNPCRequestedRecipe(slot2.npc)
                        targetRecipe = requestedRecipe
                        targetFish = AutoServe.Config.NormalOrder[requestedRecipe].Fish
                        targetFoodName = AutoServe.Config.NormalOrder[requestedRecipe].DisplayName
                    end
                end
                
                -- Scenario C: Cycle Plot (No targets matched or unwanted customers occupying seats)
                if not targetNPC then
                    local reason = "No valid targets found"
                    if slot1 or slot2 then
                        reason = "All seated customers already served in this cycle"
                    end
                    debugLog("[CYCLE] " .. reason .. ". Recycling plot...")
                    pcall(function()
                        OpenPlot:FireServer(false)
                        task.wait(1)
                        OpenPlot:FireServer(true)
                    end)
                    task.wait(8) -- Humanlike network rest step
                    return
                end
                
                -- Execute Serving Process
                if targetNPC and targetFoodName then
                    -- Log targeting info
                    if not IsNPCSeated(targetNPC.npc) then
                        debugLog("[TARGET] " .. targetNPC.identity .. " at Slot " .. targetSlot .. " (Walking - waiting for seat...)")
                    else
                        debugLog("[TARGET] " .. targetNPC.identity .. " at Slot " .. targetSlot .. " (Seated - serving " .. targetFoodName .. ")")
                    end
                    
                    local seatTimeout = 0
                    while not IsNPCSeated(targetNPC.npc) and seatTimeout < 8 do
                        task.wait(0.5)
                        seatTimeout = seatTimeout + 0.5
                    end
                    
                    -- Check if they seated in time
                    if not IsNPCSeated(targetNPC.npc) then
                        debugLog("[TIMEOUT] " .. targetNPC.identity .. " failed to seat within 8s. Recycling plot...")
                        pcall(function()
                            OpenPlot:FireServer(false)
                            task.wait(1)
                            OpenPlot:FireServer(true)
                        end)
                        task.wait(8)
                        return
                    end
                    
                    local success = Phase2_SmartFulfillment(targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, EquipPlate, RequestRestaurauntData, AutoServe.AutoCookModule)
                    if success then
                        debugLog("[SUCCESS] Served " .. targetFoodName .. " to " .. targetNPC.identity .. ". Caching for 75s...")
                        servedNPCsMemory[targetNPC.npc] = os.time()
                        task.wait(2)
                    else
                        debugLog("[ERROR] Failed to serve " .. targetFoodName .. " to " .. targetNPC.identity .. " (missing ingredients). Recycling plot...")
                        pcall(function()
                            OpenPlot:FireServer(false)
                            task.wait(1)
                            OpenPlot:FireServer(true)
                        end)
                        task.wait(8)
                    end
                end
            end)
            
            if not loopsucceeded then
                debugLog("Loop exception handled: " .. tostring(errorMsg))
            end
            
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
    
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local OpenPlot = ReplicatedStorage.Packages.Knit.Services.GameHandler.RE.OpenPlot
        OpenPlot:FireServer(false)
    end)
    
    print("[AutoServe]: Module loop cleanly halted.")
end

return AutoServe
