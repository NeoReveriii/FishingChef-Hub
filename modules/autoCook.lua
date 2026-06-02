local AutoCook = {}
local loopThread = nil

-- Shared Configuration States
AutoCook.Enabled = false
AutoCook.SelectedFishes = {} -- Array of target fish for processing
AutoCook.SelectedRecipe = "Sashimi" -- Default selected recipe

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

-- Background Task Execution Core Loop
function AutoCook.Start()
    if loopThread then task.cancel(loopThread) end
    print("🍳 AutoCook System: Thread initialized safely.")
    
    loopThread = task.spawn(function()
        -- 🛠️ Safely retrieve services INSIDE the background thread to prevent UI freezing
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not Packages then
            warn("🚨 AutoCook Error: 'Packages' was not found in ReplicatedStorage.")
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
                                targetFishItem = item
                                targetFishName = fishTarget
                                matchFound = true
                                break
                            end
                        end
                        if matchFound then break end
                    end
                end
                
                if targetFishItem then
                    print("🔥 AutoCook System: Processing " .. tostring(AutoCook.SelectedRecipe) .. " -> " .. tostring(targetFishName))
                    
                    -- Step 3: Execute the sequence in an isolated pcall to prevent thread crashing
                    pcall(function()
                        -- 3.1: Log Step
                        LogStep:InvokeServer(7)
                        
                        -- 3.2: Start Cut Session
                        StartCutSession:InvokeServer()
                        task.wait(0.2)
                        
                        -- 3.3: Cut Actions (2 Legendary, 1 Amazing as requested)
                        CutAction:FireServer(1)
                        task.wait(0.1)
                        CutAction:FireServer(2)
                        task.wait(0.1)
                        CutAction:FireServer(3)
                        task.wait(0.2)
                        
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
                        
                        -- 3.7: Cook Process
                        local cookPayload = {
                            CF = targetFishItem.CF or targetFishName,
                            Name = "Fish Filet",
                            Amount = 1,
                            ID = targetFishItem.ID or 15,
                            Data = 5, -- 🌟 5 Forces Legendary Quality (3 Perfect Cuts)
                            Value = 0
                        }
                        
                        Cook:InvokeServer(AutoCook.SelectedRecipe, cookPayload, floatVal)
                        print("✅ AutoCook System: Successfully cooked " .. tostring(AutoCook.SelectedRecipe) .. "!")
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
    print("🛑 AutoCook System: Thread cleanly terminated.")
end

return AutoCook