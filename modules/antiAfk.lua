local AntiAfk = {}

-- State tracking
AntiAfk.AntiIdleEnabled = false
AntiAfk.AntiKickEnabled = false
AntiAfk.AntiTeleportEnabled = false

-- Hook references for cleanup
local idleConnection = nil
local oldKickFunction = nil
local oldHmmi = nil
local oldHmmnc = nil
local oldHmmiTP = nil
local oldHmmncTP = nil

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Anti-Idle Function
function AntiAfk.EnableAntiIdle()
    if AntiAfk.AntiIdleEnabled then return end
    
    pcall(function()
        if getconnections then
            for _, connection in pairs(getconnections(LocalPlayer.Idled)) do
                if connection["Disable"] then
                    connection:Disable()
                elseif connection["Disconnect"] then
                    connection:Disconnect()
                end
            end
        else
            idleConnection = LocalPlayer.Idled:Connect(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        AntiAfk.AntiIdleEnabled = true
        print("[AntiAfk]: Anti-Idle enabled")
    end)
end

function AntiAfk.DisableAntiIdle()
    AntiAfk.AntiIdleEnabled = false
    if idleConnection then
        idleConnection:Disconnect()
        idleConnection = nil
    end
    print("[AntiAfk]: Anti-Idle disabled")
end

-- Anti-Kick Function
function AntiAfk.EnableAntiKick()
    if AntiAfk.AntiKickEnabled then return end
    
    pcall(function()
        if not hookmetamethod then
            warn("[AntiAfk]: Incompatible Exploit - missing hookmetamethod")
            return
        end
        
        -- Hook Kick function
        if hookfunction then
            oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
        end
        
        -- Hook __index metamethod
        oldHmmi = hookmetamethod(game, "__index", function(self, method)
            if self == LocalPlayer and method:lower() == "kick" then
                return error("Expected ':' not '.' calling member function Kick", 2)
            end
            return oldHmmi(self, method)
        end)
        
        -- Hook __namecall metamethod
        oldHmmnc = hookmetamethod(game, "__namecall", function(self, ...)
            if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
                return
            end
            return oldHmmnc(self, ...)
        end)
        
        AntiAfk.AntiKickEnabled = true
        print("[AntiAfk]: Anti-Kick enabled")
    end)
end

function AntiAfk.DisableAntiKick()
    AntiAfk.AntiKickEnabled = false
    -- Note: Hooks cannot be easily undone, so we just track state
    print("[AntiAfk]: Anti-Kick disabled (hooks may persist)")
end

-- Anti-Teleport Function
function AntiAfk.EnableAntiTeleport()
    if AntiAfk.AntiTeleportEnabled then return end
    
    pcall(function()
        if not hookmetamethod then
            warn("[AntiAfk]: Incompatible Exploit - missing hookmetamethod")
            return
        end
        
        -- Hook __index for TeleportService
        oldHmmiTP = hookmetamethod(game, "__index", function(self, method)
            if self == TeleportService then
                if method:lower() == "teleport" then
                    return error("Expected ':' not '.' calling member function Teleport", 2)
                elseif method == "TeleportToPlaceInstance" then
                    return error("Expected ':' not '.' calling member function TeleportToPlaceInstance", 2)
                end
            end
            return oldHmmiTP(self, method)
        end)
        
        -- Hook __namecall for TeleportService
        oldHmmncTP = hookmetamethod(game, "__namecall", function(self, ...)
            if self == TeleportService and (getnamecallmethod():lower() == "teleport" or getnamecallmethod() == "TeleportToPlaceInstance") then
                return
            end
            return oldHmmncTP(self, ...)
        end)
        
        AntiAfk.AntiTeleportEnabled = true
        print("[AntiAfk]: Anti-Teleport enabled")
    end)
end

function AntiAfk.DisableAntiTeleport()
    AntiAfk.AntiTeleportEnabled = false
    -- Note: Hooks cannot be easily undone, so we just track state
    print("[AntiAfk]: Anti-Teleport disabled (hooks may persist)")
end

-- Cleanup function
function AntiAfk.StopAll()
    AntiAfk.DisableAntiIdle()
    AntiAfk.DisableAntiKick()
    AntiAfk.DisableAntiTeleport()
end

return AntiAfk
