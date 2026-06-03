local AutoServe = {}
local loopThread = nil

-- Shared Configuration States
AutoServe.Enabled = false

-- Fish selection per recipe type (user configurable)
AutoServe.RecipeFish = {
    ["Sashimi"] = nil, -- nil means auto-select
    ["Nigiri"] = nil,
    ["Sushi"] = nil
}

-- Customer order patterns
local SPECIAL_NPC_ORDERS = {
    ["Rich Guy"] = {recipe = "Nigiri", priority = "high_rarity"},
    ["Ninja"] = {recipe = "Sushi", fish = "salmon"},
    ["Sushi Master"] = {recipe = "Sushi", priority = "high_quality"}
}

-- Debug function
local function debugLog(message)
    print("[AutoServe Debug]: " .. message)
end

function AutoServe.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AutoServe]: Thread initialized safely.")
    debugLog("Starting AutoServe with recipe fish config: " .. tostring(AutoServe.RecipeFish))
    
    loopThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Workspace = game:GetService("Workspace")
        
        local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not Packages then
            debugLog("ERROR: 'Packages' was not found in ReplicatedStorage.")
            warn("[AutoServe Error]: 'Packages' was not found in ReplicatedStorage.")
            AutoServe.Enabled = false
            return
        end
        
        local Knit = Packages:WaitForChild("Knit", 5)
        local Services = Knit:WaitForChild("Services", 5)
        
        -- GameHandler Services
        local GameHandlerServices = Services:WaitForChild("GameHandler")
        local GameHandlerRE = GameHandlerServices:WaitForChild("RE")
        local OpenPlot = GameHandlerRE:WaitForChild("OpenPlot")
        
        -- Open the restaurant plot so NPCs can spawn
        pcall(function()
            OpenPlot:FireServer(true)
            debugLog("Restaurant plot opened")
            print("[AutoServe]: Restaurant plot opened")
        end)
        
        -- Fish Services
        local FishServices = Services:WaitForChild("Fish")
        local FishRE = FishServices:WaitForChild("RE")
        local FishRF = FishServices:WaitForChild("RF")
        
        -- Remote Events
        local StoreFood = FishRE:WaitForChild("StoreFood")
        local EquipPlate = FishRE:WaitForChild("EquipPlate")
        
        -- Remote Functions
        local RequestFishData = FishRF:WaitForChild("RequestFishData")
        local RequestRestaurauntData = FishRF:WaitForChild("RequestRestaurauntData")
        local Cook = FishRF:WaitForChild("Cook")
        
        debugLog("Successfully loaded all required remotes")
        
        -- Equip plate at start
        pcall(function()
            EquipPlate:FireServer()
            debugLog("Plate equipped at startup")
            print("[AutoServe]: Plate equipped at startup")
        end)
        
        while AutoServe.Enabled do
            pcall(function()
                -- Check for active customer
                local customerFolder = Workspace:FindFirstChild("Code", 2)
                if not customerFolder then
                    debugLog("No Code folder found in Workspace")
                    return
                end
                
                local activeNPCs = customerFolder:FindFirstChild("ActiveNPCs", 2)
                if not activeNPCs then
                    debugLog("No ActiveNPCs folder found")
                    return
                end
                
                local customer = activeNPCs:FindFirstChild("Customer", 2)
                if not customer then
                    debugLog("No customer found")
                    return
                end
                
                debugLog("Customer detected at: " .. customer:GetFullName())
                
                -- Detect customer type and order
                local customerType = AutoServe.DetectCustomerType(customer)
                debugLog("Detected customer type: " .. tostring(customerType))
                
                local order = AutoServe.GetCustomerOrder(customer, customerType)
                if order then
                    debugLog("Customer order - Recipe: " .. tostring(order.recipe) .. ", Fish: " .. tostring(order.fish or "any"))
                    
                    -- Cook the required food
                    local success = AutoServe.CookOrder(order, RequestFishData, Cook)
                    
                    if success then
                        debugLog("Successfully cooked food, now serving customer")
                        -- Equip plate before serving
                        pcall(function()
                            EquipPlate:FireServer()
                            debugLog("Plate equipped before serving")
                            task.wait(0.2)
                        end)
                        -- Serve the food
                        AutoServe.ServeCustomer(customer, StoreFood, customerType)
                    else
                        debugLog("Failed to cook food")
                    end
                else
                    debugLog("No order detected for customer")
                end
            end)
            
            task.wait(1) -- Check every second
        end
    end)
end

function AutoServe.DetectCustomerType(customer)
    debugLog("Detecting customer type for: " .. customer:GetFullName())
    
    -- Detect if customer is special NPC or normal
    local owner = customer:FindFirstChild("Owner")
    if owner then
        local ownerValue = owner.Value
        debugLog("Owner value: " .. tostring(ownerValue) .. " (type: " .. type(ownerValue) .. ")")
        
        if type(ownerValue) == "string" then
            -- Check if it matches known special NPCs
            for npcName, _ in pairs(SPECIAL_NPC_ORDERS) do
                if string.find(string.lower(ownerValue), string.lower(npcName)) then
                    debugLog("Matched special NPC: " .. npcName)
                    return npcName
                end
            end
        end
    else
        debugLog("No Owner value found")
    end
    
    -- Check VISUALS for special NPC indicators
    local visuals = customer:FindFirstChild("VISUALS")
    if visuals then
        debugLog("VISUALS folder found, checking for special NPC indicators")
        -- Add logic to detect special NPCs from visuals if needed
    else
        debugLog("No VISUALS folder found")
    end
    
    debugLog("Customer type: Normal")
    return "Normal"
end

function AutoServe.GetCustomerOrder(customer, customerType)
    debugLog("Getting order for customer type: " .. tostring(customerType))
    
    local orderInfo = SPECIAL_NPC_ORDERS[customerType]
    
    if orderInfo then
        debugLog("Found order for special NPC: " .. tostring(orderInfo.recipe))
        return orderInfo
    else
        -- For normal NPCs, we need to detect their order
        -- This might require checking customer attributes or waiting for order display
        -- For now, return a default order or nil
        debugLog("No special order found, using default Sashimi")
        return {recipe = "Sashimi", fish = "any"}
    end
end

function AutoServe.CookOrder(order, RequestFishData, Cook)
    debugLog("Cooking order - Recipe: " .. tostring(order.recipe))
    
    -- Check if user has selected a specific fish for this recipe
    local selectedFish = AutoServe.RecipeFish[order.recipe]
    if selectedFish then
        debugLog("User selected fish for " .. order.recipe .. ": " .. tostring(selectedFish))
    else
        debugLog("No user-selected fish for " .. order.recipe .. ", will auto-select")
    end
    
    -- Get inventory to find suitable fish
    local success, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    
    if not success or not inventory then
        debugLog("ERROR: Failed to get inventory")
        print("[AutoServe]: Failed to get inventory")
        return false
    end
    
    debugLog("Inventory retrieved with " .. tostring(#inventory) .. " items")
    
    -- Find fish matching the order requirements
    local targetFish = nil
    for _, item in pairs(inventory) do
        local fishName = item.CF or item.Name
        debugLog("Checking fish: " .. tostring(fishName))
        
        -- First check if user selected a specific fish for this recipe
        if selectedFish then
            if string.find(string.lower(fishName), string.lower(selectedFish)) then
                targetFish = item
                debugLog("Found user-selected fish: " .. tostring(fishName))
                break
            end
        elseif order.fish == "any" or string.find(string.lower(fishName), string.lower(order.fish or "")) then
            targetFish = item
            debugLog("Found matching fish: " .. tostring(fishName))
            break
        end
    end
    
    if not targetFish then
        debugLog("ERROR: No suitable fish found for order")
        print("[AutoServe]: No suitable fish found for order")
        return false
    end
    
    -- Determine Data value based on recipe
    local dataValue = 5 -- Default for Sashimi (3 cuts)
    if order.recipe == "Nigiri" or order.recipe == "Sushi" then
        dataValue = 4 -- For Nigiri/Sushi (2 cuts)
    end
    
    -- Cook the food (simplified - should integrate with autoCook)
    local cookPayload = {
        CF = targetFish.CF or targetFish.Name,
        Name = "Fish Filet",
        Amount = 1,
        ID = targetFish.ID or 15,
        Data = dataValue,
        Value = 0
    }
    
    debugLog("Cooking payload: " .. tostring(cookPayload.CF) .. " with Data: " .. tostring(dataValue))
    
    pcall(function()
        Cook:InvokeServer(order.recipe, cookPayload)
        print("[AutoServe]: Cooked " .. order.recipe .. " with " .. tostring(targetFish.CF or targetFish.Name))
    end)
    
    task.wait(0.5)
    return true
end

function AutoServe.ServeCustomer(customer, StoreFood, customerType)
    debugLog("Serving customer type: " .. tostring(customerType))
    
    pcall(function()
        if SPECIAL_NPC_ORDERS[customerType] then
            -- Special NPCs use Folder argument
            local args = {Instance.new("Folder", nil)}
            StoreFood:FireServer(unpack(args))
            debugLog("Served special NPC (" .. customerType .. ") with Folder argument")
            print("[AutoServe]: Served special NPC (" .. customerType .. ")")
        else
            -- Normal NPCs use customer folder argument
            local args = {customer}
            StoreFood:FireServer(unpack(args))
            debugLog("Served normal customer with customer folder argument")
            print("[AutoServe]: Served normal customer")
        end
    end)
end

function AutoServe.Stop()
    AutoServe.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    print("[AutoServe]: Thread cleanly terminated.")
end

return AutoServe
