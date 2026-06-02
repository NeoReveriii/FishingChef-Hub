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
        
        while AutoFish.Enabled do
            pcall(function()
                -- 1. Cast the rod
                CastRequest:InvokeServer(0.8885351153781718)
                
                -- Note: You might need to wait for a specific remote event that tells you a fish has bitten.
                -- For now, we will wait a brief moment and instantly resolve the minigame.
                -- If this doesn't work, we'll need to listen to a FishBitten RemoteEvent!
                task.wait(2.5) 
                
                -- 2. Log step and resolve minigame as a win
                LogStep:InvokeServer(4)
                MinigameResolved:InvokeServer(true)
            end)
            task.wait(1)
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
