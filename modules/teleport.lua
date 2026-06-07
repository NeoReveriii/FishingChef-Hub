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

return Teleport
