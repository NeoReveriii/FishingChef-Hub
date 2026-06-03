local Utilities = {}
local fpsBoostEnabled = false
local cleanupConnections = {}

function Utilities.EnableFPSBoost()
    if fpsBoostEnabled then return end
    fpsBoostEnabled = true
    
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    
    -- Terrain settings
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    
    -- Lighting settings
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 9e9
    settings().Rendering.QualityLevel = 1
    
    -- Process existing descendants
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow = false
            v.Material = "Plastic"
            v.Reflectance = 0
            v.BackSurface = "SmoothNoOutlines"
            v.BottomSurface = "SmoothNoOutlines"
            v.FrontSurface = "SmoothNoOutlines"
            v.LeftSurface = "SmoothNoOutlines"
            v.RightSurface = "SmoothNoOutlines"
            v.TopSurface = "SmoothNoOutlines"
        elseif v:IsA("Decal") then
            v.Transparency = 1
            v.Texture = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end
    
    -- Disable post effects
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end
    
    -- Handle new descendants
    local connection = workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            elseif child:IsA("BasePart") then
                child.CastShadow = false
            end
        end)
    end)
    
    table.insert(cleanupConnections, connection)
    print("[Utilities]: FPS Boost enabled")
end

function Utilities.DisableFPSBoost()
    if not fpsBoostEnabled then return end
    fpsBoostEnabled = false
    
    -- Cleanup connections
    for _, connection in ipairs(cleanupConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    cleanupConnections = {}
    
    print("[Utilities]: FPS Boost disabled (requires game restart to fully revert)")
end

function Utilities.IsFPSBoostEnabled()
    return fpsBoostEnabled
end

return Utilities
