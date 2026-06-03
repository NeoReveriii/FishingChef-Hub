local AntiAfk = {}
local loopThread = nil

AntiAfk.Enabled = false
AntiAfk.Interval = 30 -- Default: perform action every 30 seconds

function AntiAfk.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AntiAfk]: Thread initialized.")
    
    loopThread = task.spawn(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local VirtualInputManager = game:GetService("VirtualInputManager")
        
        while AntiAfk.Enabled do
            pcall(function()
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                
                if humanoid then
                    -- Random action selection
                    local action = math.random(1, 4)
                    
                    if action == 1 then
                        -- Small jump
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        print("[AntiAfk]: Jump action performed")
                    elseif action == 2 then
                        -- Move slightly
                        local moveDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
                        humanoid:MoveTo(character.HumanoidRootPart.Position + (moveDirection * 2))
                        print("[AntiAfk]: Movement action performed")
                    elseif action == 3 then
                        -- Rotate camera slightly
                        local camera = workspace.CurrentCamera
                        if camera then
                            local currentCFrame = camera.CFrame
                            local rotation = CFrame.Angles(0, math.rad(math.random(-10, 10)), 0)
                            camera.CFrame = currentCFrame * rotation
                            print("[AntiAfk]: Camera rotation performed")
                        end
                    else
                        -- Send key press (simulates activity)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        print("[AntiAfk]: Key press simulated")
                    end
                end
            end)
            
            task.wait(AntiAfk.Interval)
        end
    end)
end

function AntiAfk.Stop()
    AntiAfk.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    print("[AntiAfk]: Thread terminated.")
end

return AntiAfk
