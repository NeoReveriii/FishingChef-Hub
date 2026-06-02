local AutoCook = {}
local loopThread = nil

-- Knit Framework Services Mapping (Verified from Dex)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishServices = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("Fish"):WaitForChild("RF")

local StartCutSession = FishServices:WaitForChild("StartCutSession")
local CutFish         = FishServices:WaitForChild("CutFish")
local Cook            = FishServices:WaitForChild("Cook")
local RequestFishData = FishServices:WaitForChild("RequestFishData")

-- Shared Observer Configuration States
AutoCook.Enabled = false
AutoCook.SelectedFish = nil

-- Background Task Execution Core Loop
function AutoCook.Start()
    if loopThread then task.cancel(loopThread) end
    print("🍳 AutoCook System: Observer thread spawned and active.")
    
    loopThread = task.spawn(function()
        while AutoCook.Enabled do
            if AutoCook.SelectedFish then
                -- Step 1: Request your inventory data payload from the server
                local success, inventory = pcall(function()
                    return RequestFishData:InvokeServer()
                end)
                
                local targetFishItem = nil
                if success and inventory then
                    -- Step 2: Look for the specific fish selected in the dropdown
                    for _, item in pairs(inventory) do
                        if item.Name and string.lower(item.Name) == string.lower(AutoCook.SelectedFish) then
                            targetFishItem = item
                            break
                        end
                    end
                end
                
                -- Step 3: If found, fire the recipe logic sequence safely
                if targetFishItem then
                    print("🔥 AutoCook System: Processing target -> " .. tostring(targetFishItem.Name))
                    pcall(function()
                        -- Mimic game sequence requirements
                        StartCutSession:InvokeServer()
                        task.wait(0.5)
                        
                        -- Pass fish weight/attributes directly into processing remotes
                        local weight = targetFishItem.Weight or 1
                        CutFish:InvokeServer(weight, 3.4)
                        task.wait(0.5)
                        
                        -- Finish recipe creation
                        Cook:InvokeServer("Sashimi", targetFishItem, 3.4)
                    end)
                    
                    -- Cool-down delay to let the cooking process finish cleanly on the server
                    task.wait(5)
                else
                    -- No fish found? Sleep briefly before scanning the inventory again
                    task.wait(2)
                end
            else
                -- Nothing selected in the dropdown yet? Wait for the user
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
    print("🛑 AutoCook System: Background thread cleanly terminated.")
end

return AutoCook