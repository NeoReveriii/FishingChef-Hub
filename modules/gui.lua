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
    AppTitle.Text = "   Kilabot Hub"
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

    local ExitButton = Instance.new("TextButton", MainFrame)
    ExitButton.Size = UDim2.new(0, 24, 0, 24)
    ExitButton.Position = UDim2.new(1, -34, 0, 10)
    ExitButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ExitButton.Text = "×"
    ExitButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    ExitButton.Font = Enum.Font.GothamMedium
    ExitButton.TextSize = 18
    Instance.new("UICorner", ExitButton).CornerRadius = UDim.new(0, 6)

    local CurrentActiveTab = nil
    local OnTerminateCallback = nil
    
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
        PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        
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

    -- 🛠️ UI COMPONENT: SWITCH TOGGLE
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
        Switch.Size = UDim2.new(0, 45, 0, 22)
        Switch.Position = UDim2.new(1, -55, 0.5, -11)
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

    -- 🛠️ UPGRADED UI COMPONENT: FLOATING OVERLAY DROPDOWN (Matches image_4a7bdd.png)
    function GUI.AddDropdown(parentPage, text, listOptions, callback)
        local DropdownFrame = Instance.new("Frame", parentPage)
        DropdownFrame.Size = UDim2.new(0.95, 0, 0, 45)
        DropdownFrame.BackgroundTransparency = 1
        
        -- Left Label Text Description
        local Label = Instance.new("TextLabel", DropdownFrame)
        Label.Size = UDim2.new(0.5, -10, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Right Selection Display Box Container
        local MainBtn = Instance.new("TextButton", DropdownFrame)
        MainBtn.Size = UDim2.new(0.5, 0, 0.8, 0)
        MainBtn.Position = UDim2.new(0.5, 0, 0.1, 0)
        MainBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        MainBtn.Text = "Select...  ↕"
        MainBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
        MainBtn.Font = Enum.Font.GothamMedium
        MainBtn.TextSize = 12
        Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 6)
        
        -- Generate Floating Menu List Portal Layer
        local FloatingList = Instance.new("Frame")
        FloatingList.Name = "FloatingDropdown"
        FloatingList.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        FloatingList.BorderSizePixel = 0
        FloatingList.ZIndex = 100 -- Places it absolutely on top of everything
        FloatingList.Visible = false
        FloatingList.Parent = ScreenGui -- Attach directly to top screen engine hierarchy
        
        Instance.new("UICorner", FloatingList).CornerRadius = UDim.new(0, 6)
        local Stroke = Instance.new("UIStroke", FloatingList)
        Stroke.Color = Color3.fromRGB(35, 35, 35)
        Stroke.Thickness = 1
        
        local ListScroll = Instance.new("ScrollingFrame", FloatingList)
        ListScroll.Size = UDim2.new(1, 0, 1, 0)
        ListScroll.BackgroundTransparency = 1
        ListScroll.ScrollBarThickness = 0
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local listLayout = Instance.new("UIListLayout", ListScroll)
        listLayout.Padding = UDim.new(0, 2)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        -- Populate elements inside overlay panel container
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
            
            -- Simple hover aesthetics
            OptBtn.MouseEnter:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
            OptBtn.MouseLeave:Connect(function() OptBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) end)
            
            OptBtn.MouseButton1Click:Connect(function()
                MainBtn.Text = option .. "  ↕"
                FloatingList.Visible = false
                if callback then callback(option) end
            end)
        end
        
        -- Coordinate recalculation execution logic
        local open = false
        MainBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                local btnAbsolutePos = MainBtn.AbsolutePosition
                FloatingList.Position = UDim2.new(0, btnAbsolutePos.X, 0, btnAbsolutePos.Y + MainBtn.AbsoluteSize.Y + 4)
                FloatingList.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, math.min(#listOptions * 32 + 4, 150))
                FloatingList.Visible = true
            else
                FloatingList.Visible = false
            end
        end)
    end

    function GUI.OnExit(callback)
        OnTerminateCallback = callback
    end

    return GUI
end

return GUI