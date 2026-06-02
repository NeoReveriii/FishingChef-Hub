local AutoCook = {}
local loopThread = nil

-- Shared Configuration States
AutoCook.Enabled = false
AutoCook.SelectedFish = nil

-- Background Task Execution Core Loop
function AutoCook.Start()
    if loopThread then task.cancel(loopThread) end
    print("🍳 AutoCook System: Thread initialized safely.")
    
    loopThread = task.spawn(function()
        -- 🛠️ FIX: Safely retrieve services INSIDE the background thread so it never freezes your UI startup
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local KnitFolder = ReplicatedStorage:FindFirstChild("Knit")
        
        if not KnitFolder then
            warn("🚨 AutoCook Error: 'Knit' was not found in ReplicatedStorage. Is it named differently?")
            AutoCook.Enabled = false
            return
        end
        
        local FishServices = KnitFolder:WaitForChild("Services"):WaitForChild("Fish"):WaitForChild("RF")
        local StartCutSession = FishServices:WaitForChild("StartCutSession")
        local CutFish         = FishServices:WaitForChild("CutFish")
        local Cook            = FishServices:WaitForChild("Cook")
        local RequestFishData = FishServices:WaitForChild("RequestFishData")
        
        while AutoCook.Enabled do
            if AutoCook.SelectedFish then
                -- Step 1: Request inventory payload
                local success, inventory = pcall(function()
                    return RequestFishData:InvokeServer()
                end)
                
                local targetFishItem = nil
                if success and inventory then
                    -- Step 2: Match selection item name
                    for _, item in pairs(inventory) do
                        if item.Name and string.lower(item.Name) == string.lower(AutoCook.SelectedFish) then
                            targetFishItem = item
                            break
                        end
                    end
                end
                
                if targetFishItem then
                    print("🔥 AutoCook System: Processing target -> " .. tostring(targetFishItem.Name))
                    pcall(function()
                        StartCutSession:InvokeServer()
                        task.wait(0.5)
                        
                        local weight = targetFishItem.Weight or 1
                        CutFish:InvokeServer(weight, 3.4)
                        task.wait(0.5)
                        
                        Cook:InvokeServer("Sashimi", targetFishItem, 3.4)
                    end)
                    task.wait(5)
                else
                    task.wait(2)
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