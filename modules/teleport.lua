local Teleport = {}

-- Store location definitions
Teleport.Locations = {
    ["Koi Pond"] = Vector3.new(-131.915, 3.858, -1308.048),
    ["Razor Reef"] = Vector3.new(-1444.871, 0.7, 1559.375),
    ["Bamboo Forest"] = Vector3.new(-2357.901, 0.803, -928.84),
    ["Moon Tuna"] = Vector3.new(-212, 6, -845),
    ["Moon Tuna Hidden"] = Vector3.new(-199, 11, -837)
}

-- Return an ordered list of location names for dropdowns
function Teleport.GetLocationNames()
    return {"Koi Pond", "Razor Reef", "Bamboo Forest", "Moon Tuna", "Moon Tuna Hidden"}
end

-- Teleport logic execution
function Teleport.To(locationName)
    local pos = Teleport.Locations[locationName]
    if pos then
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Target CFrame with +3.0 Y Safety Padding
            local targetCFrame = CFrame.new(pos.X, pos.Y + 3.0, pos.Z)
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
            print("[Teleport]: Safely teleported to: " .. locationName)
            return true
        end
    else
        warn("[Teleport Error]: Location '" .. tostring(locationName) .. "' not found.")
    end
    return false
end

-- ── Moon Tuna Event Auto-Teleport System ──
Teleport.MoonTunaEnabled = false
Teleport.SavedPosition = nil
Teleport.EventConnections = {}

function Teleport.EnableMoonTunaAutoTeleport()
    if Teleport.MoonTunaEnabled then return end
    Teleport.MoonTunaEnabled = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Trace Knit Engine Pathways
    local Knit = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit")
    local Services = Knit:WaitForChild("Services")
    local RandomEventService = Services:WaitForChild("RandomEvent")
    local RandomEventRE = RandomEventService:WaitForChild("RE")
    local EventStarted = RandomEventRE:WaitForChild("EventStarted", 5)
    local EventEnded = RandomEventRE:WaitForChild("EventEnded", 5)
    
    -- Event Started Handler
    if EventStarted then
        local conn = EventStarted.OnClientEvent:Connect(function(eventParam)
            print(string.format("[MoonTuna] 🚨 EVENT STARTED: %s", tostring(eventParam)))
            
            -- Save current position before teleporting
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local currentPos = LocalPlayer.Character.HumanoidRootPart.Position
                Teleport.SavedPosition = Vector3.new(
                    math.round(currentPos.X),
                    math.round(currentPos.Y),
                    math.round(currentPos.Z)
                )
                print("[MoonTuna]: Saved position: " .. tostring(Teleport.SavedPosition))
            end
            
            -- Teleport to Moon Tuna location
            Teleport.To("Moon Tuna")
            
            -- Desktop notification
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "🚨 EVENT LIVE! 🚨",
                    Text = "Teleported to Moon Tuna location!",
                    Duration = 10
                })
            end)
        end)
        table.insert(Teleport.EventConnections, conn)
    end
    
    -- Event Ended Handler
    if EventEnded then
        local conn = EventEnded.OnClientEvent:Connect(function(eventParam)
            print(string.format("[MoonTuna] 🛑 EVENT ENDED: %s", tostring(eventParam)))
            
            -- Return to saved position
            if Teleport.SavedPosition then
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetCFrame = CFrame.new(
                        Teleport.SavedPosition.X,
                        Teleport.SavedPosition.Y + 3.0,
                        Teleport.SavedPosition.Z
                    )
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
                    print("[MoonTuna]: Returned to saved position: " .. tostring(Teleport.SavedPosition))
                end
                
                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "🛑 EVENT ENDED",
                        Text = "Returned to previous position!",
                        Duration = 10
                    })
                end)
            end
        end)
        table.insert(Teleport.EventConnections, conn)
    end
    
    print("[MoonTuna]: Auto-teleport enabled - monitoring events...")
end

function Teleport.DisableMoonTunaAutoTeleport()
    Teleport.MoonTunaEnabled = false
    Teleport.SavedPosition = nil
    
    -- Disconnect all event listeners
    for _, conn in ipairs(Teleport.EventConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    Teleport.EventConnections = {}
    
    print("[MoonTuna]: Auto-teleport disabled")
end

return Teleport
