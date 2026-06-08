local AutoCook = {}
local loopThread = nil

-- Shared Configuration States
AutoCook.Enabled = false
AutoCook.SelectedFishes = {} -- Array of target fish for processing
AutoCook.SelectedRecipe = "Sashimi" -- Default selected recipe
AutoCook.SelectedMutations = {} -- Array of target mutations (Wet, Moonlit, Cosmic) - empty = any

-- 🛠️ Request inventory directly to generate our dynamic UI dropdown
function AutoCook.GetAvailableFish()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return {} end
    
    local Knit = Packages:FindFirstChild("Knit")
    if not Knit then return {} end
    
    local Services = Knit:FindFirstChild("Services")
    if not Services then return {} end
    
    local FishServices = Services:FindFirstChild("Fish")
    if not FishServices then return {} end
    
    local FishRF = FishServices:FindFirstChild("RF")
    if not FishRF then return {} end
    
    local RequestFishData = FishRF:FindFirstChild("RequestFishData")
    if not RequestFishData then return {} end
    
    local success, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    
    local uniqueFish = {}
    local added = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do
            local fishName = item.CF or item.Name
            if fishName and not added[fishName] then
                added[fishName] = true
                table.insert(uniqueFish, fishName)
            end
        end
    end
    
    return uniqueFish
end

-- Single Cook Function - Cooks one fish with specific recipe (for use by other modules)
function AutoCook.CookSingle(recipe, fishName)
    return AutoCook.CookSingleWithMutations(recipe, fishName, {})
end

-- Single Cook Function with Mutations - Cooks one fish with specific recipe and mutations
function AutoCook.CookSingleWithMutations(recipe, fishName, requiredMutations)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
    if not Packages then
        warn("[AutoCook]: 'Packages' was not found in ReplicatedStorage.")
        return false
    end
    
    local Knit = Packages:WaitForChild("Knit", 5)
    local Services = Knit:WaitForChild("Services", 5)
    
    -- Analytics Services
    local AnalyticsRF = Services:WaitForChild("Analytics"):WaitForChild("RF")
    local LogStep = AnalyticsRF:WaitForChild("LogStep")
    
    -- Fish Services
    local FishServices = Services:WaitForChild("Fish")
    local FishRF = FishServices:WaitForChild("RF")
    local FishRE = FishServices:WaitForChild("RE")
    
    -- Remote Functions
    local RequestFishData = FishRF:WaitForChild("RequestFishData")
    local StartCutSession = FishRF:WaitForChild("StartCutSession")
    local CutFish = FishRF:WaitForChild("CutFish")
    local Cook = FishRF:WaitForChild("Cook")
    local RequestRestaurantData = FishRF:WaitForChild("RequestRestaurauntData")
    
    -- Remote Events
    local CutAction = FishRE:WaitForChild("CutAction")
    local ServerAnims = FishRE:WaitForChild("ServerAnims")
    
    -- Get inventory to find the fish
    local success, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    
    if not success or not inventory then
        warn("[AutoCook]: Failed to fetch inventory.")
        return false
    end
    
    -- Find the specific fish in inventory with matching mutations
    local targetFishItem = nil
    for _, item in pairs(inventory) do
        local itemName = item.CF or item.Name
        if string.lower(itemName):find(string.lower(fishName)) then
            -- Check mutations if required
            local mutationMatch = true
            if requiredMutations and #requiredMutations > 0 then
                local itemMutations = item.Mutations or {}
                mutationMatch = false
                -- Check if fish has ALL required mutations
                local allMutationsFound = true
                for _, reqMutation in ipairs(requiredMutations) do
                    local hasMutation = false
                    for _, itemMutation in ipairs(itemMutations) do
                        if string.lower(itemMutation) == string.lower(reqMutation) then
                            hasMutation = true
                            break
                        end
                    end
                    if not hasMutation then
                        allMutationsFound = false
                        break -- Missing a required mutation
                    end
                end
                mutationMatch = allMutationsFound
            end
            
            if mutationMatch then
                targetFishItem = item
                break
            end
        end
    end
    
    if not targetFishItem then
        local mutationStr = #requiredMutations > 0 and (" with mutations: " .. table.concat(requiredMutations, ", ")) or ""
        warn("[AutoCook]: Could not find fish: " .. fishName .. mutationStr)
        return false
    end
    
    -- Execute the cooking sequence
    local cookSuccess = pcall(function()
        -- Log Step
        LogStep:InvokeServer(7)
        
        -- Start Cut Session
        StartCutSession:InvokeServer()
        task.wait(0.2)
        
        -- Cut Actions - Different sequence for Nigiri/Sushi (2 cuts) vs Sashimi (3 cuts)
        -- Legendary cut values: ~4.2+ gives legendary cut quality
        if recipe == "Nigiri" or recipe == "Sushi" then
            CutAction:FireServer(1, 4.5)
            task.wait(0.1)
            CutAction:FireServer(2, 4.6)
            task.wait(0.2)
        else
            CutAction:FireServer(1, 4.5)
            task.wait(0.1)
            CutAction:FireServer(2, 4.6)
            task.wait(0.1)
            CutAction:FireServer(3, 4.7)
            task.wait(0.2)
        end
        
        -- Server Animations
        local cuttingBoard = nil
        pcall(function()
            cuttingBoard = workspace:WaitForChild("Code", 2):WaitForChild("Plots", 2):WaitForChild(LocalPlayer.Name, 2):WaitForChild("STALL", 2):WaitForChild("CookingStation", 2):WaitForChild("CuttingBoard", 2)
        end)
        
        if cuttingBoard then
            ServerAnims:FireServer("CuttingBoard", cuttingBoard, false)
        end
        task.wait(0.2)
        
        -- Cut Fish
        local fishIdOrWeight = targetFishItem.ID or 1767
        local floatVal = 1.8558929952683516 
        CutFish:InvokeServer(fishIdOrWeight, floatVal)
        task.wait(0.2)
        
        -- Request Restaurant Data
        RequestRestaurantData:InvokeServer()
        task.wait(0.2)
        
        -- Cook Process - Include Mutations if present
        local cookPayload = {
            CF = targetFishItem.CF or fishName,
            Name = "Fish Filet",
            Amount = 1,
            ID = targetFishItem.ID or 15,
            Data = (recipe == "Nigiri" or recipe == "Sushi") and 4 or 5,
            Value = 0,
            Mutations = targetFishItem.Mutations or {} -- Include mutations (Wet, Moonlit, Cosmic)
        }
        
        Cook:InvokeServer(recipe, cookPayload, floatVal)
        print("[AutoCook]: Successfully cooked " .. recipe .. " with " .. fishName)
    end)
    
    if cookSuccess then
        return true
    else
        warn("[AutoCook]: Failed to cook " .. recipe .. " with " .. fishName)
        return false
    end
end

-- Background Task Execution Core Loop
function AutoCook.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AutoCook]: Thread initialized safely.")
    
    loopThread = task.spawn(function()
        -- 🛠️ Safely retrieve services INSIDE the background thread to prevent UI freezing
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not Packages then
            warn("[AutoCook Error]: 'Packages' was not found in ReplicatedStorage.")
            AutoCook.Enabled = false
            return
        end
        
        local Knit = Packages:WaitForChild("Knit", 5)
        local Services = Knit:WaitForChild("Services", 5)
        
        -- Analytics Services
        local AnalyticsRF = Services:WaitForChild("Analytics"):WaitForChild("RF")
        local LogStep = AnalyticsRF:WaitForChild("LogStep")
        
        -- Fish Services
        local FishServices = Services:WaitForChild("Fish")
        local FishRF = FishServices:WaitForChild("RF")
        local FishRE = FishServices:WaitForChild("RE")
        
        -- Remote Functions
        local RequestFishData = FishRF:WaitForChild("RequestFishData")
        local StartCutSession = FishRF:WaitForChild("StartCutSession")
        local CutFish = FishRF:WaitForChild("CutFish")
        local Cook = FishRF:WaitForChild("Cook")
        local RequestRestaurantData = FishRF:WaitForChild("RequestRestaurauntData")
        
        -- Remote Events
        local CutAction = FishRE:WaitForChild("CutAction")
        local ServerAnims = FishRE:WaitForChild("ServerAnims")
        
        while AutoCook.Enabled do
            if AutoCook.SelectedFishes and #AutoCook.SelectedFishes > 0 then
                -- Step 1: Request inventory payload
                local success, inventory = pcall(function()
                    return RequestFishData:InvokeServer()
                end)
                
                local targetFishItem = nil
                local targetFishName = nil
                
                if success and inventory then
                    -- Step 2: Match selection item against any of the selected fishes array
                    for _, item in pairs(inventory) do
                        local matchFound = false
                        for _, fishTarget in ipairs(AutoCook.SelectedFishes) do
                            if (item.CF and string.lower(item.CF) == string.lower(fishTarget)) or (item.Name and string.lower(item.Name) == string.lower(fishTarget)) then
                                -- Check mutation filter if set
                                local mutationMatch = true
                                if #AutoCook.SelectedMutations > 0 then
                                    local itemMutations = item.Mutations or {}
                                    mutationMatch = false
                                    -- Check if fish has ALL selected mutations
                                    local allMutationsFound = true
                                    for _, reqMutation in ipairs(AutoCook.SelectedMutations) do
                                        local hasMutation = false
                                        for _, itemMutation in ipairs(itemMutations) do
                                            if string.lower(itemMutation) == string.lower(reqMutation) then
                                                hasMutation = true
                                                break
                                            end
                                        end
                                        if not hasMutation then
                                            allMutationsFound = false
                                            break -- Missing a required mutation
                                        end
                                    end
                                    mutationMatch = allMutationsFound
                                end
                                
                                if mutationMatch then
                                    targetFishItem = item
                                    targetFishName = fishTarget
                                    matchFound = true
                                    break
                                end
                            end
                        end
                        if matchFound then break end
                    end
                end
                
                if targetFishItem then
                    print("[AutoCook]: Processing " .. tostring(AutoCook.SelectedRecipe) .. " -> " .. tostring(targetFishName))
                    
                    -- Step 3: Execute the sequence in an isolated pcall to prevent thread crashing
                    pcall(function()
                        -- 3.1: Log Step
                        LogStep:InvokeServer(7)
                        
                        -- 3.2: Start Cut Session
                        StartCutSession:InvokeServer()
                        task.wait(0.2)
                        
                        -- 3.3: Cut Actions - Different sequence for Nigiri/Sushi (2 cuts) vs Sashimi (3 cuts)
                        -- Legendary cut values: ~4.2+ gives legendary cut quality
                        if AutoCook.SelectedRecipe == "Nigiri" or AutoCook.SelectedRecipe == "Sushi" then
                            -- Nigiri and Sushi require 2 cuts - always legendary
                            CutAction:FireServer(1, 4.5)
                            task.wait(0.1)
                            CutAction:FireServer(2, 4.6)
                            task.wait(0.2)
                        else
                            -- Sashimi requires 3 cuts - always legendary
                            CutAction:FireServer(1, 4.5)
                            task.wait(0.1)
                            CutAction:FireServer(2, 4.6)
                            task.wait(0.1)
                            CutAction:FireServer(3, 4.7)
                            task.wait(0.2)
                        end
                        
                        -- 3.4: Server Animations
                        local cuttingBoard = nil
                        pcall(function()
                            -- Dynamically find the player's cutting board
                            cuttingBoard = workspace:WaitForChild("Code", 2):WaitForChild("Plots", 2):WaitForChild(LocalPlayer.Name, 2):WaitForChild("STALL", 2):WaitForChild("CookingStation", 2):WaitForChild("CuttingBoard", 2)
                        end)
                        
                        if cuttingBoard then
                            ServerAnims:FireServer("CuttingBoard", cuttingBoard, false)
                        end
                        task.wait(0.2)
                        
                        -- 3.5: Cut Fish
                        local fishIdOrWeight = targetFishItem.ID or 1767
                        local floatVal = 4.339033467350943 
                        CutFish:InvokeServer(fishIdOrWeight, floatVal)
                        task.wait(0.2)
                        
                        -- 3.6: Request Restaurant Data
                        RequestRestaurantData:InvokeServer()
                        task.wait(0.2)
                        
                        -- 3.7: Cook Process - Include Mutations if present
                        local cookPayload = {
                            CF = targetFishItem.CF or targetFishName,
                            Name = "Fish Filet",
                            Amount = 1,
                            ID = targetFishItem.ID or 15,
                            Data = (AutoCook.SelectedRecipe == "Nigiri" or AutoCook.SelectedRecipe == "Sushi") and 4 or 5, -- 4 for Nigiri/Sushi, 5 for Sashimi
                            Value = 0,
                            Mutations = targetFishItem.Mutations or {} -- Include mutations (Wet, Moonlit, Cosmic)
                        }
                        
                        Cook:InvokeServer(AutoCook.SelectedRecipe, cookPayload, floatVal)
                        print("[AutoCook]: Successfully cooked " .. tostring(AutoCook.SelectedRecipe) .. "!")
                        
                        task.spawn(function()
                            task.wait(0.5)
                            local char = LocalPlayer.Character
                            if char then
                                local humanoid = char:FindFirstChild("Humanoid")
                                if humanoid then
                                    humanoid:UnequipTools()
                                    task.wait(0.1)
                                    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                                        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
                                            humanoid:EquipTool(tool)
                                            break
                                        end
                                    end
                                end
                            end
                        end)
                    end)
                    
                    task.wait(2) -- Wait before cooking next fish
                else
                    task.wait(1) -- Wait for inventory update if fish is missing
                end
            else
                task.wait(1)
            end
        end
    end)
end

function AutoCook.Stop()
    AutoCook.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    print("[AutoCook]: Thread cleanly terminated.")
end

return AutoCook