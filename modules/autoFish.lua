local AutoFish = {}
local loopThread = nil

AutoFish.Enabled = false

function AutoFish.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AutoFish]: Thread initialized.")
    
    loopThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        local Packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not Packages then return end
        
        local Knit = Packages:WaitForChild("Knit", 5)
        local Services = Knit:WaitForChild("Services", 5)
        
        local FishRF = Services:WaitForChild("Fish"):WaitForChild("RF")
        local AnalyticsRF = Services:WaitForChild("Analytics"):WaitForChild("RF")
        
        local CastRequest = FishRF:WaitForChild("CastRequest")
        local MinigameResolved = FishRF:WaitForChild("MinigameResolved")
        local LogStep = AnalyticsRF:WaitForChild("LogStep")
        
        local LocalPlayer = game:GetService("Players").LocalPlayer
        
        while AutoFish.Enabled do
            pcall(function()
                -- 0. Equip Rod
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                            if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
                                humanoid:EquipTool(tool)
                                break
                            end
                        end
                    end
                end
                
                task.wait(0.5) -- wait for equip
                
                -- 1. Cast the rod
                CastRequest:InvokeServer(0.8885351153781718)
                
                -- The reason you didn't catch anything is because 2.5s is too fast!
                -- It reeled in before the fish could bite. Let's wait longer:
                task.wait(6) 
                
                -- 2. Log step and resolve minigame as a win
                LogStep:InvokeServer(4)
                MinigameResolved:InvokeServer(true)
            end)
            task.wait(2)
        end
    end)
end

function AutoFish.Stop()
    AutoFish.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    print("[AutoFish]: Thread terminated.")
end

return AutoFish
