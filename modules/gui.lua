local GUI = {}

function GUI.Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StudioAutomation_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 10
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 560, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    
    -- Pocket Mode Anchor
    local MaximizeAnchor = Instance.new("TextButton")
    MaximizeAnchor.Name = "MaximizeAnchor"
    MaximizeAnchor.Size = UDim2.new(0, 50, 0, 50)
    MaximizeAnchor.Position = UDim2.new(0, 20, 0, 20)
    MaximizeAnchor.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    MaximizeAnchor.Text = "HUB"
    MaximizeAnchor.TextColor3 = Color3.fromRGB(255, 255, 255)
    MaximizeAnchor.TextSize = 14
    MaximizeAnchor.Visible = false
    MaximizeAnchor.Active = true
    MaximizeAnchor.Draggable = true
    MaximizeAnchor.Parent = ScreenGui
    Instance.new("UICorner", MaximizeAnchor).CornerRadius = UDim.new(1, 0)
    
    MaximizeAnchor.MouseButton1Click:Connect(function()
        MaximizeAnchor.Visible = false
        MainFrame.Visible = true
    end)
    
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Sidebar.BorderSizePixel = 0
    
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
    
    local SidebarPatch = Instance.new("Frame", Sidebar)
    SidebarPatch.Size = UDim2.new(0, 10, 1, 0)
    SidebarPatch.Position = UDim2.new(1, -10, 0, 0)
    SidebarPatch.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    SidebarPatch.BorderSizePixel = 0
    
    local AppTitle = Instance.new("TextLabel", Sidebar)
    AppTitle.Size = UDim2.new(1, 0, 0, 45)
    AppTitle.BackgroundTransparency = 1
    AppTitle.Text = "   Kilabot Hub v.4a"
    AppTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    AppTitle.Font = Enum.Font.GothamBold
    AppTitle.TextSize = 14
    AppTitle.TextXAlignment = Enum.TextXAlignment.Left

    local NavList = Instance.new("ScrollingFrame", Sidebar)
    NavList.Size = UDim2.new(1, 0, 1, -55)
    NavList.Position = UDim2.new(0, 0, 0, 55)
    NavList.BackgroundTransparency = 1
    NavList.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavList.ScrollBarThickness = 0
    
    local NavLayout = Instance.new("UIListLayout", NavList)
    NavLayout.Padding = UDim.new(0, 4)
    NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentArea = Instance.new("Frame", MainFrame)
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -190, 1, -45)
    ContentArea.Position = UDim2.new(0, 175, 0, 40)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = false

    local ExitButton = Instance.new("TextButton", MainFrame)
    ExitButton.Size = UDim2.new(0, 24, 0, 24)
    ExitButton.Position = UDim2.new(1, -34, 0, 10)
    ExitButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ExitButton.Text = "×"
    ExitButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    ExitButton.Font = Enum.Font.GothamMedium
    ExitButton.TextSize = 18
    Instance.new("UICorner", ExitButton).CornerRadius = UDim.new(0, 6)

    local MinimizeButton = Instance.new("TextButton", MainFrame)
    MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
    MinimizeButton.Position = UDim2.new(1, -64, 0, 10)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    MinimizeButton.Font = Enum.Font.GothamMedium
    MinimizeButton.TextSize = 18
    Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)
    
    MinimizeButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        MaximizeAnchor.Visible = true
    end)

    local CurrentActiveTab = nil
    local OnTerminateCallback = nil
    local allFloatingDropdowns = {}
    
    ExitButton.MouseButton1Click:Connect(function()
        if OnTerminateCallback then OnTerminateCallback() end
        ScreenGui:Destroy()
    end)

    function GUI.AddTab(name)
        local PageFrame = Instance.new("ScrollingFrame", ContentArea)
        PageFrame.Name = name .. "_Page"
        PageFrame.Size = UDim2.new(1, 0, 1, 0)
        PageFrame.BackgroundTransparency = 1
        PageFrame.Visible = false
        PageFrame.ScrollBarThickness = 2
        PageFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
        
        local PageLayout = Instance.new("UIListLayout", PageFrame)
        PageLayout.Padding = UDim.new(0, 10)
        
        local TabBtn = Instance.new("TextButton", NavList)
        TabBtn.Size = UDim2.new(0.9, 0, 0, 32)
        TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        TabBtn.Text = "  " .. name
        TabBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        TabBtn.MouseButton1Click:Connect(function()
            -- Close all open dropdowns when switching tabs
            for _, dropdown in ipairs(allFloatingDropdowns) do
                if dropdown and dropdown.Parent then
                    dropdown.Visible = false
                end
            end
            
            if CurrentActiveTab then
                CurrentActiveTab.Page.Visible = false
                game:GetService("TweenService"):Create(CurrentActiveTab.Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 22), TextColor3 = Color3.fromRGB(160, 160, 160)}):Play()
            end
            PageFrame.Visible = true
            CurrentActiveTab = {Page = PageFrame, Btn = TabBtn}
            game:GetService("TweenService"):Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        
        if not CurrentActiveTab then
            PageFrame.Visible = true
            CurrentActiveTab = {Page = PageFrame, Btn = TabBtn}
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        return PageFrame
    end

    function GUI.AddToggle(parentPage, text, callback)
        local ToggleFrame = Instance.new("Frame", parentPage)
        ToggleFrame.Size = UDim2.new(0.95, 0, 0, 40)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 6)
        
        local Label = Instance.new("TextLabel", ToggleFrame)
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        
        local Switch = Instance.new("TextButton", ToggleFrame)
        Switch.Size = UDim2.new(0, 36, 0, 20)
        Switch.Position = UDim2.new(1, -46, 0.5, -10)
        Switch.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Switch.Text = ""
        Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
        
        local Slider = Instance.new("Frame", Switch)
        Slider.Size = UDim2.new(0, 16, 0, 16)
        Slider.Position = UDim2.new(0, 3, 0.5, -8)
        Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Slider).CornerRadius = UDim.new(1, 0)
        
        local toggled = false
        Switch.MouseButton1Click:Connect(function()
            toggled = not toggled
            local goalColor = toggled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 45, 45)
            local goalPos = toggled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            
            game:GetService("TweenService"):Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
            game:GetService("TweenService"):Create(Slider, TweenInfo.new(0.2), {Position = goalPos}):Play()
            
            if callback then callback(toggled) end
        end)
    end

    function GUI.AddDropdown(parentPage, text, listOptions, multiSelect, callback)
        local DropdownFrame = Instance.new("Frame", parentPage)
        DropdownFrame.Size = UDim2.new(0.95, 0, 0, 40)
        DropdownFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)
        
        local Label = Instance.new("TextLabel", DropdownFrame)
        Label.Size = UDim2.new(0.6, 0, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        
        local MainBtn = Instance.new("TextButton", DropdownFrame)
        MainBtn.Size = UDim2.new(0, 120, 0, 26)
        MainBtn.Position = UDim2.new(1, -130, 0.5, -13)
        MainBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        MainBtn.Text = "--  ▼"
        MainBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
        MainBtn.Font = Enum.Font.GothamMedium
        MainBtn.TextSize = 14
        MainBtn.TextTruncate = Enum.TextTruncate.AtEnd
        MainBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 5)
        
        -- Add padding using spaces instead of TextPadding (TextPadding causes tab visibility issues)
        MainBtn.Text = "   --   ▼"
        
        local FloatingList = Instance.new("Frame")
        FloatingList.Name = "FloatingDropdown"
        FloatingList.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        FloatingList.BorderSizePixel = 0
        FloatingList.ZIndex = 100 
        FloatingList.Visible = false
        FloatingList.Parent = ScreenGui 
        
        -- Register floating dropdown for tab switching cleanup
        table.insert(allFloatingDropdowns, FloatingList)
        
        Instance.new("UICorner", FloatingList).CornerRadius = UDim.new(0, 6)
        local Stroke = Instance.new("UIStroke", FloatingList)
        Stroke.Color = Color3.fromRGB(35, 35, 35)
        Stroke.Thickness = 1
        
        local ListScroll = Instance.new("ScrollingFrame", FloatingList)
        ListScroll.Size = UDim2.new(1, 0, 1, 0)
        ListScroll.BackgroundTransparency = 1
        ListScroll.ScrollBarThickness = 4
        ListScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local listLayout = Instance.new("UIListLayout", ListScroll)
        listLayout.Padding = UDim.new(0, 2)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local selectedItems = {}
        
        local function UpdateMainText()
            if not multiSelect then return end
            local keys = {}
            for k, v in pairs(selectedItems) do 
                if v then table.insert(keys, k) end 
            end
            if #keys > 0 then
                MainBtn.Text = "   " .. table.concat(keys, ", ") .. "   ▼"
            else
                MainBtn.Text = "   --   ▼"
            end
        end
        
        local function populate(options)
            for _, child in ipairs(ListScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            for _, option in ipairs(options) do
                local OptBtn = Instance.new("TextButton", ListScroll)
                OptBtn.Size = UDim2.new(0.95, 0, 0, 30)
                OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = "  " .. tostring(option)
                OptBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
                OptBtn.Font = Enum.Font.GothamMedium
                OptBtn.TextSize = 12
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.ZIndex = 101
                Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 4)
                
                -- Restore visual state if previously selected
                if multiSelect and selectedItems[option] then
                    OptBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
                    OptBtn.Text = "[x] " .. tostring(option)
                end
                
                OptBtn.MouseEnter:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
                OptBtn.MouseLeave:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) end)
                
                OptBtn.MouseButton1Click:Connect(function()
                    if multiSelect then
                        selectedItems[option] = not selectedItems[option]
                        if selectedItems[option] then
                            OptBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
                            OptBtn.Text = "[x] " .. tostring(option)
                        else
                            OptBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
                            OptBtn.Text = "  " .. tostring(option)
                        end
                        UpdateMainText()
                        
                        local activeKeys = {}
                        for k, v in pairs(selectedItems) do if v then table.insert(activeKeys, k) end end
                        if callback then callback(activeKeys) end
                    else
                        MainBtn.Text = "   " .. tostring(option) .. "   ▼"
                        FloatingList.Visible = false
                        if callback then callback(option) end
                    end
                end)
            end
            
            -- Adjust canvas size for scrolling
            ListScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 32)
        end
        
        populate(listOptions)
        
        local open = false
        local posTracker = nil
        
        MainBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                local function syncPos()
                    local btnAbsolutePos = MainBtn.AbsolutePosition
                    FloatingList.Position = UDim2.new(0, btnAbsolutePos.X, 0, btnAbsolutePos.Y + MainBtn.AbsoluteSize.Y + 4)
                end
                syncPos()
                
                local optionCount = 0
                for _, child in ipairs(ListScroll:GetChildren()) do
                    if child:IsA("TextButton") then optionCount = optionCount + 1 end
                end
                
                FloatingList.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, math.min(optionCount * 32 + 4, 150))
                FloatingList.Visible = true
                
                if posTracker then posTracker:Disconnect() end
                posTracker = MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncPos)
            else
                FloatingList.Visible = false
                if posTracker then posTracker:Disconnect(); posTracker = nil end
            end
        end)
        
        -- Return a table with a Refresh function
        return {
            Refresh = function(newOptions)
                populate(newOptions)
            end
        }
    end

    function GUI.CreatePortableDropdown(title, listOptions, callback)
        local PortableFrame = Instance.new("Frame")
        PortableFrame.Name = "PortableTeleportMenu"
        PortableFrame.Size = UDim2.new(0, 160, 0, 45)
        PortableFrame.Position = UDim2.new(0.5, 0, 0.1, 0)
        PortableFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        PortableFrame.Active = true
        PortableFrame.Draggable = true
        PortableFrame.Parent = ScreenGui
        Instance.new("UICorner", PortableFrame).CornerRadius = UDim.new(0, 6)
        
        local DragHandle = Instance.new("TextLabel", PortableFrame)
        DragHandle.Size = UDim2.new(0, 30, 1, 0)
        DragHandle.BackgroundTransparency = 1
        DragHandle.Text = "≡"
        DragHandle.TextColor3 = Color3.fromRGB(150, 150, 150)
        DragHandle.Font = Enum.Font.GothamMedium
        DragHandle.TextSize = 18
        
        local MainBtn = Instance.new("TextButton", PortableFrame)
        MainBtn.Size = UDim2.new(1, -30, 1, 0)
        MainBtn.Position = UDim2.new(0, 30, 0, 0)
        MainBtn.BackgroundTransparency = 1
        MainBtn.Text = title .. "  ↕"
        MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        MainBtn.Font = Enum.Font.GothamMedium
        MainBtn.TextSize = 13
        
        local FloatingList = Instance.new("Frame")
        FloatingList.Name = "PortableFloatingDropdown"
        FloatingList.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        FloatingList.BorderSizePixel = 0
        FloatingList.ZIndex = 100 
        FloatingList.Visible = false
        FloatingList.Parent = ScreenGui 
        
        -- Register floating dropdown for tab switching cleanup
        table.insert(allFloatingDropdowns, FloatingList)
        
        Instance.new("UICorner", FloatingList).CornerRadius = UDim.new(0, 6)
        local Stroke = Instance.new("UIStroke", FloatingList)
        Stroke.Color = Color3.fromRGB(35, 35, 35)
        Stroke.Thickness = 1
        
        local ListScroll = Instance.new("ScrollingFrame", FloatingList)
        ListScroll.Size = UDim2.new(1, 0, 1, 0)
        ListScroll.BackgroundTransparency = 1
        ListScroll.ScrollBarThickness = 4
        ListScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, #listOptions * 32)
        
        local listLayout = Instance.new("UIListLayout", ListScroll)
        listLayout.Padding = UDim.new(0, 2)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        for _, option in ipairs(listOptions) do
            local OptBtn = Instance.new("TextButton", ListScroll)
            OptBtn.Size = UDim2.new(0.95, 0, 0, 30)
            OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            OptBtn.BorderSizePixel = 0
            OptBtn.Text = "  " .. option
            OptBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
            OptBtn.Font = Enum.Font.GothamMedium
            OptBtn.TextSize = 12
            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
            OptBtn.ZIndex = 101
            Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 4)
            
            OptBtn.MouseEnter:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
            OptBtn.MouseLeave:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) end)
            
            OptBtn.MouseButton1Click:Connect(function()
                FloatingList.Visible = false
                if callback then callback(option) end
            end)
        end
        
        local open = false
        local posTracker = nil
        
        MainBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                local function syncPos()
                    local btnAbsolutePos = MainBtn.AbsolutePosition
                    FloatingList.Position = UDim2.new(0, btnAbsolutePos.X, 0, btnAbsolutePos.Y + MainBtn.AbsoluteSize.Y + 4)
                end
                syncPos()
                
                FloatingList.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, math.min(#listOptions * 32 + 4, 150))
                FloatingList.Visible = true
                
                if posTracker then posTracker:Disconnect() end
                posTracker = PortableFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncPos)
            else
                FloatingList.Visible = false
                if posTracker then posTracker:Disconnect(); posTracker = nil end
            end
        end)
        
        return {
            Destroy = function()
                if posTracker then posTracker:Disconnect() end
                FloatingList:Destroy()
                PortableFrame:Destroy()
            end
        }
    end

    -- ── Section Header (Category Title/Group Label) ───────────────────────
    function GUI.AddSectionLabel(parentPage, text)
        local LabelFrame = Instance.new("Frame", parentPage)
        LabelFrame.Size = UDim2.new(0.95, 0, 0, 30)
        LabelFrame.BackgroundTransparency = 1
        
        local Lbl = Instance.new("TextLabel", LabelFrame)
        Lbl.Size = UDim2.new(1, 0, 1, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Text = text
        Lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        Lbl.Font = Enum.Font.GothamBold
        Lbl.TextSize = 14
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- ── Number Input (label + text box for numeric values) ────────────────
    function GUI.AddNumberInput(parentPage, text, defaultValue, minVal, maxVal, callback)
        local InputFrame = Instance.new("Frame", parentPage)
        InputFrame.Size = UDim2.new(0.95, 0, 0, 40)
        InputFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)

        local Label = Instance.new("TextLabel", InputFrame)
        Label.Size = UDim2.new(0.65, 0, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(230, 230, 230)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local InputBox = Instance.new("TextBox", InputFrame)
        InputBox.Size = UDim2.new(0, 68, 0, 26)
        InputBox.Position = UDim2.new(1, -78, 0.5, -13)
        InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        InputBox.Text = tostring(defaultValue)
        InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 13
        InputBox.ClearTextOnFocus = false
        Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 5)

        InputBox.FocusLost:Connect(function(enterPressed)
            local num = tonumber(InputBox.Text)
            if num then
                if minVal then num = math.max(minVal, num) end
                if maxVal then num = math.min(maxVal, num) end
                InputBox.Text = tostring(num)
                if callback then callback(num) end
            else
                InputBox.Text = tostring(defaultValue)
            end
        end)

        return {
            SetValue = function(v)
                InputBox.Text = tostring(v)
            end
        }
    end

    function GUI.OnExit(callback)
        OnTerminateCallback = callback
    end

    return GUI
end

return GUI