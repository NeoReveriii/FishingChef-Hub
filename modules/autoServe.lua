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
    RichGuyFish = "salmon", -- Dynamic fish selection for Rich Guy (accepts any fish)
    
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
    local StoreFood = ReplicatedStorage.Packages.Knit.Services.Fish.RE.StoreFood
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        -- Check if food tool is already equipped
        local foodEquipped = false
        local foodNameLower = string.gsub(string.lower(foodName), "_", " ")
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and string.gsub(string.lower(tool.Name), "_", " ") == foodNameLower then
                foodEquipped = true
                break
            end
        end
        
        -- If not equipped, try to equip from backpack
        if not foodEquipped then
            for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if string.gsub(string.lower(tool.Name), "_", " ") == foodNameLower then
                    humanoid:EquipTool(tool)
                    task.wait(0.5) -- Extended humanlike delay
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
    local dishName = ""
    
    -- Check 1: Value Object
    local requestedDish = npc:FindFirstChild("RequestedDish")
    if requestedDish and requestedDish.Value then
        dishName = tostring(requestedDish.Value)
    else
        -- Check 2: Try Attributes if the Value Object doesn't exist
        local attr = npc:GetAttribute("RequestedDish") or npc:GetAttribute("Order")
        if attr then dishName = tostring(attr) end
    end
    
    -- Check 3: Scan UI/BillboardGui for order text
    if dishName == "" then
        local charVal = npc:FindFirstChild("CHAR")
        if charVal and charVal.Value then
            local model = charVal.Value
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
                    for _, textLabel in ipairs(descendant:GetDescendants()) do
                        if textLabel:IsA("TextLabel") or textLabel:IsA("TextBox") then
                            local text = string.lower(textLabel.Text)
                            if text:find("sashimi") or text:find("nigiri") or text:find("sushi") then
                                dishName = textLabel.Text
                                break
                            end
                        end
                    end
                    if dishName ~= "" then break end
                end
            end
        end
    end
    
    -- Normalize the text found
    if dishName ~= "" then
        dishName = string.lower(dishName)
        if dishName:find("sashimi") then return "Sashimi" end
        if dishName:find("nigiri") then return "Nigiri" end
        if dishName:find("sushi") then return "Sushi" end
    end
    
    -- Fallback: check identity for hints
    local identity = string.lower(GetNPCIdentity(npc))
    if identity:find("sashimi") then return "Sashimi" end
    if identity:find("nigiri") then return "Nigiri" end
    if identity:find("sushi") then return "Sushi" end
    
    -- DO NOT DEFAULT! Return nil so the script knows it failed to read it.
    return nil
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

-- Check if NPC is close enough to counter baseplate to overrule sitting requirements
local function IsAtCounter(npc)
    local pos = GetNPCPosition(npc)
    if not pos then return false end
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local plotBase = nil
    pcall(function()
        plotBase = workspace.Code.Plots[LocalPlayer.Name].STALL.Baseplate.Position
    end)
    
    if plotBase then
        -- If customer is physically within serving range of the counter, count them as ready
        return (pos - plotBase).Magnitude < 45
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

-- Phase 1: Radar, Position Detection (Spam Removed)
local function Phase1_RadarDetection()
    local Workspace = game:GetService("Workspace")
    
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
                
                -- Track them even if standing so we don't spam close the stall on them!
                table.insert(validNPCs, {
                    npc = npc, 
                    position = position,
                    identity = identity,
                    horizontalOffset = horizontalOffset
                })
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
    
    local lowerRecipeTarget = string.lower(targetRecipe or "")
    local lowerFishTarget = string.gsub(string.lower(targetFish or ""), "_", " ")

    -- STRICT FIX: Ensures BOTH the fish type AND the preparation method match exactly
    local function tryEquipFoodTool()
        -- Scan Active Hand
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                local tName = string.lower(tool.Name)
                if tName:find("filet") or (tName:find(lowerFishTarget) and tName:find(lowerRecipeTarget)) then
                    return true, tool.Name
                end
            end
        end
        -- Scan Hotbar/Backpack Slots
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local tName = string.lower(tool.Name)
                if tName:find("filet") or (tName:find(lowerFishTarget) and tName:find(lowerRecipeTarget)) then
                    debugLog("[HOTBAR] Found exact matching item: " .. tool.Name)
                    humanoid:EquipTool(tool)
                    task.wait(0.3)
                    return true, tool.Name
                end
            end
        end
        return false, nil
    end
    
    -- Pre-check: If you are already holding the correct combo, serve it immediately
    local alreadyHolding, existingToolName = tryEquipFoodTool()
    if alreadyHolding then
        ServeFood(targetNPC.npc, existingToolName, targetSlot)
        return true
    end
    
    -- Fetch storage cabinet data
    local success, restaurantData = pcall(function() return RequestRestaurauntData:InvokeServer() end)
    if success and restaurantData then
        for itemID, foodItem in pairs(restaurantData) do
            if type(foodItem) == "table" and foodItem.CF and foodItem.Name then
                local internalFishName = string.gsub(string.lower(foodItem.CF), "_", " ")
                local internalRecipeName = string.gsub(string.lower(foodItem.Name), "_", " ")
                local amountValue = tonumber(foodItem.Amount) or 0
                
                -- Verify cabinet item matches BOTH fish species AND recipe type
                if internalFishName == lowerFishTarget and internalRecipeName == lowerRecipeTarget and amountValue > 0 then
                    debugLog("[STORAGE] Found " .. foodItem.CF .. " " .. foodItem.Name .. " in cabinet")
                    
                    -- Form payload using strict network patterns from Remote Spy logs
                    local equipPayload = {
                        CF = foodItem.CF,
                        Name = targetRecipe, -- Sends exact requested text: "Sushi", "Sashimi", or "Nigiri"
                        Amount = 1,
                        ID = foodItem.ID or itemID, -- Uses server "PXX" tracking keys
                        Data = foodItem.Data or 0,
                        Value = foodItem.Value or 0
                    }
                    
                    pcall(function()
                        EquipPlate:FireServer(equipPayload)
                    end)
                    
                    task.wait(1.0)
                    
                    -- Look for the precise tool in inventory with retry logic
                    local toolFound, physicalToolName = tryEquipFoodTool()
                    local retryCount = 0
                    while not toolFound and retryCount < 3 do
                        retryCount = retryCount + 1
                        debugLog("[INVENTORY] Retry " .. retryCount .. "/3: Tool not found, waiting 0.5s...")
                        task.wait(0.5)
                        toolFound, physicalToolName = tryEquipFoodTool()
                    end
                    
                    if toolFound then
                        ServeFood(targetNPC.npc, physicalToolName, targetSlot)
                    else
                        -- Loosen matching for fallback - accept tools matching fish OR recipe
                        debugLog("[INVENTORY] Strict match failed, trying loose match...")
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                local tName = string.lower(tool.Name)
                                if tName:find(lowerFishTarget) or tName:find(lowerRecipeTarget) then
                                    debugLog("[INVENTORY] Found with loose match: " .. tool.Name)
                                    humanoid:EquipTool(tool)
                                    task.wait(0.3)
                                    ServeFood(targetNPC.npc, tool.Name, targetSlot)
                                    return true
                                end
                            end
                        end
                        -- Final fallback
                        debugLog("[INVENTORY] Tool not found in backpack, using fallback")
                        ServeFood(targetNPC.npc, targetRecipe, targetSlot)
                    end
                    
                    return true -- Breaks execution immediately to avoid ghost cook triggers
                end
            end
        end
    end
    
    -- Fallback Operation: Trigger cooking sequence ONLY if storage contains 0 plates
    if targetFish and AutoCookModule then
        debugLog("[COOK] Cooking " .. targetRecipe .. " with " .. targetFish)
        local cookSuccess = pcall(function() return AutoCookModule.CookSingle(targetRecipe, targetFish) end)
        if cookSuccess then
            task.wait(2.2)
            local toolFound, physicalToolName = tryEquipFoodTool()
            if toolFound then
                ServeFood(targetNPC.npc, physicalToolName, targetSlot)
                return true
            else
                debugLog("[COOK] Dish not found after cooking")
            end
        else
            debugLog("[COOK] Failed to cook " .. targetRecipe .. " with " .. targetFish)
        end
    end
    
    return false
end

-- Main Start Function
function AutoServe.Start()
    if loopThread then task.cancel(loopThread) end
    AutoServe.Enabled = true
    
    print("[AutoServe]: Started Main Loop with Compliant Non-Spam Configuration.")
    
    loopThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Services = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
        
        local OpenPlot = Services:WaitForChild("GameHandler"):WaitForChild("RE"):WaitForChild("OpenPlot")
        local FishServices = Services:WaitForChild("Fish")
        local EquipPlate = FishServices:WaitForChild("RE"):WaitForChild("EquipPlate")
        local RequestRestaurauntData = FishServices:WaitForChild("RF"):WaitForChild("RequestRestaurauntData")
        
        -- FIXED: Fire OpenPlot EXACTLY ONCE upon initialization to open your restaurant.
        -- This prevents breaking the walking paths and avoids account flagging.
        pcall(function()
            OpenPlot:FireServer(true)
            debugLog("Sent initial OpenPlot initialization signal to Server.")
        end)
        task.wait(1.5)
        
        while AutoServe.Enabled do
            local loopsucceeded, errorMsg = pcall(function()
                -- Read positions safely (no OpenPlot inside)
                local slot1, slot2 = Phase1_RadarDetection()
                
                -- Dynamic Memory Cache Cleanup: If an NPC model leaves, scrub it from memory immediately
                for cachedNpc, _ in pairs(servedNPCsMemory) do
                    if not slot1 or (slot1.npc ~= cachedNpc) then
                        if not slot2 or (slot2.npc ~= cachedNpc) then
                            servedNPCsMemory[cachedNpc] = nil
                        end
                    end
                end
                
                -- If completely empty, wait gracefully for spawns
                if not slot1 and not slot2 then
                    task.wait(4)
                    return
                end
                
                local targetNPC = nil
                local targetSlot = 0
                local targetFoodName = nil
                local targetRecipe = nil
                local targetFish = nil
                
                -- Check Slots Independently (Prevents Slot 1 from paralyzing Slot 2 operations)
                local availableTargets = {}
                if slot1 then table.insert(availableTargets, {data = slot1, id = 1}) end
                if slot2 then table.insert(availableTargets, {data = slot2, id = 2}) end
                
                -- PRIORITY 1: VIP Target Scanning
                if AutoServe.Config.ServeSpecialGuests and #AutoServe.Config.SelectedVIPs > 0 then
                    for _, entry in ipairs(availableTargets) do
                        if entry.data.identity and not servedNPCsMemory[entry.data.npc] then
                            -- NON-BLOCKING CONDITION: Only target if they have safely arrived at their objective position
                            if IsNPCSeated(entry.data.npc) or IsAtCounter(entry.data.npc) then
                                for _, vipName in ipairs(AutoServe.Config.SelectedVIPs) do
                                    if entry.data.identity:find(vipName) then
                                        targetNPC = entry.data; targetSlot = entry.id
                                        local vipOrder = VIP_ORDERS[vipName]
                                        targetFoodName = vipOrder.displayName; targetRecipe = vipOrder.recipe
                                        -- Use dynamic fish for Rich Guy, hardcoded for other VIPs
                                        if vipName == "Rich Guy" then
                                            targetFish = AutoServe.Config.RichGuyFish
                                            targetFoodName = AutoServe.Config.RichGuyFish .. " Nigiri"
                                        else
                                            targetFish = vipOrder.fish
                                        end
                                        debugLog("[VIP] Targeting " .. vipName .. " with " .. targetFoodName)
                                        break
                                    end
                                end
                            end
                        end
                        if targetNPC then break end
                    end
                end
                
                -- PRIORITY 2: Normal Target Scanning (Runs if no VIP matches exist)
                if not targetNPC and AutoServe.Config.ServeNormalNPCs then
                    for _, entry in ipairs(availableTargets) do
                        if not servedNPCsMemory[entry.data.npc] then
                            -- NON-BLOCKING CONDITION: Skip walking customers instantly to evaluate other slots
                            if IsNPCSeated(entry.data.npc) or IsAtCounter(entry.data.npc) then
                                local requestedRecipe = GetNPCRequestedRecipe(entry.data.npc)
                                if requestedRecipe and AutoServe.Config.NormalOrder[requestedRecipe] then
                                    targetNPC = entry.data; targetSlot = entry.id; targetRecipe = requestedRecipe
                                    targetFish = AutoServe.Config.NormalOrder[requestedRecipe].Fish
                                    targetFoodName = AutoServe.Config.NormalOrder[requestedRecipe].DisplayName
                                    debugLog("[NORMAL] Targeting NPC with " .. targetFoodName)
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Scenario C: Cycle Plot (If customers are standing/seated but orders aren't matched or already served)
                if not targetNPC then
                    -- Let walking customers finish their walk paths safely without resetting the stall immediately
                    local anyWalking = false
                    for _, entry in ipairs(availableTargets) do
                        if not IsNPCSeated(entry.data.npc) and not IsAtCounter(entry.data.npc) then
                            anyWalking = true
                            break
                        end
                    end
                    
                    if anyWalking then
                        -- Instantly continue loop to poll next sub-second without cycling plot
                        task.wait(0.5)
                        return
                    end
                    
                    -- If everyone is fully seated but nothing targets, cycle plot cleanly with highly compliant long delays
                    debugLog("[HUMAN COMPLIANCE] Seated customers already fulfilled or unmatched. Cycling stall safely...")
                    pcall(function()
                        OpenPlot:FireServer(false)
                        task.wait(8) -- Anti-detection cooldown extension (8s close)
                        OpenPlot:FireServer(true)
                    end)
                    task.wait(14) -- Master interval break to allow the server to dispatch paths safely
                    return
                end
                
                -- Execute Serving Process
                if targetNPC and targetFoodName then
                    debugLog("[TARGETING] Processing " .. targetNPC.identity .. " at Slot " .. targetSlot)
                    
                    local served = Phase2_SmartFulfillment(
                        targetNPC, targetFoodName, targetSlot, targetRecipe, targetFish, 
                        EquipPlate, RequestRestaurauntData, AutoServe.AutoCookModule
                    )
                    
                    if served then
                        servedNPCsMemory[targetNPC.npc] = os.time()
                        task.wait(3.5) -- Extended post-delivery cooldown to maintain non-suspicious patterns
                    else
                        -- Cautious handling if cooking checks came back empty handed
                        pcall(function()
                            OpenPlot:FireServer(false)
                            task.wait(8)
                            OpenPlot:FireServer(true)
                        end)
                        task.wait(14)
                    end
                end
            end)
            
            if not loopsucceeded then
                debugLog("Loop encountered runtime error: " .. tostring(errorMsg))
            end
            task.wait(0.5) -- Swift loop rate for responsive non-blocking tracking
        end
    end)
end

function AutoServe.Stop()
    AutoServe.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    debugLog("Module loop cleanly halted.")
end

return AutoServe
