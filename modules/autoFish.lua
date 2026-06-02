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
        local GameHandler = Services:WaitForChild("GameHandler", 5)
        local GoPlot = nil
        if GameHandler then
            local GameHandlerRE = GameHandler:WaitForChild("RE", 5)
            if GameHandlerRE then GoPlot = GameHandlerRE:WaitForChild("GoPlot", 5) end
        end
        
        local LocalPlayer = game:GetService("Players").LocalPlayer
        
        while AutoFish.Enabled do
            pcall(function()
                -- 0. Remote Teleport
                if AutoFish.RemoteLocation and AutoFish.RemoteLocation ~= "None" and AutoFish.TeleportModule then
                    AutoFish.TeleportModule.To(AutoFish.RemoteLocation)
                    task.wait(0.8) -- Wait for character to physically arrive
                end
                
                -- 1. Equip Rod
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
                
                -- 2. Cast the rod
                CastRequest:InvokeServer(0.8885351153781718)
                
                -- The reason you didn't catch anything is because 2.5s is too fast!
                -- It reeled in before the fish could bite. Let's wait longer:
                task.wait(6) 
                
                -- 3. Log step and resolve minigame as a win
                LogStep:InvokeServer(4)
                MinigameResolved:InvokeServer(true)
                
                -- 4. Return to Restaurant/Plot
                if AutoFish.RemoteLocation and AutoFish.RemoteLocation ~= "None" and GoPlot then
                    GoPlot:FireServer()
                    task.wait(0.8)
                end
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
    
    -- Attempt to fix invisible hotbar by unequipping rod and re-enabling CoreGui Backpack
    pcall(function()
        local LocalPlayer = game:GetService("Players").LocalPlayer
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then humanoid:UnequipTools() end
        end
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
    
    print("[AutoFish]: Thread terminated.")
end

return AutoFish
