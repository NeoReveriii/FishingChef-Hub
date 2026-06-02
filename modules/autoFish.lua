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
                    task.wait(0.1) -- Near-instant teleport
                end
                
                -- 1. Equip Rod (check if already equipped first)
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChild("Humanoid")
                local rodEquipped = false
                
                if char and humanoid then
                    -- Check if rod is already in character
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
                            rodEquipped = true
                            break
                        end
                    end
                    
                    -- Only equip if not already equipped
                    if not rodEquipped then
                        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                            if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
                                humanoid:EquipTool(tool)
                                break
                            end
                        end
                    end
                end
                
                task.wait(0.05) -- Minimal equip delay
                
                -- 2. Cast the rod
                CastRequest:InvokeServer(0.8885351153781718)
                
                -- 3. INSTANT CATCH ATTEMPT - Try to catch immediately after cast
                -- This may not work if server requires minimum bite time
                task.wait(0.5) -- Aggressive reduction - testing instant catch
                
                -- 4. Log step and resolve minigame as a win
                LogStep:InvokeServer(4)
                MinigameResolved:InvokeServer(true)
                
                -- 5. Return to Restaurant/Plot
                if AutoFish.RemoteLocation and AutoFish.RemoteLocation ~= "None" and GoPlot then
                    GoPlot:FireServer()
                    task.wait(0.1) -- Near-instant return
                end
            end)
            task.wait(0.1) -- Minimal loop delay
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
