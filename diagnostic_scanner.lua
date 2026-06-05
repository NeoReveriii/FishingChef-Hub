-- Independent Diagnostic Scanner for Sushi Stall NPCs
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function scanLog(message)
    print("[SCANNER]: " .. message)
end

-- Helper: Get lantern anchor for left/right sorting matching your main script
local function GetLanternAnchor()
    local plot = Workspace:FindFirstChild("Code") 
        and Workspace.Code:FindFirstChild("Plots") 
        and Workspace.Code.Plots:FindFirstChild(LocalPlayer.Name)
    local stall = plot and plot:FindFirstChild("STALL")
    if not stall then return nil end
    local hangingLantern = stall:FindFirstChild("HangingLantern")
    if hangingLantern then
        local basePart = hangingLantern:FindFirstChild("Base")
        if basePart and basePart:IsA("BasePart") then return basePart end
    end
    return nil
end

-- Helper: Get safe position
local function GetNPCPosition(npc)
    local location = npc:FindFirstChild("Location")
    if location and (typeof(location.Value) == "CFrame" or typeof(location.Value) == "Vector3") then
        return typeof(location.Value) == "CFrame" and location.Value.Position or location.Value
    end
    return nil
end

local function DeepScanNPC(npcFolder, slotNumber)
    scanLog("==============================================")
    scanLog(string.format("🟢 ANALYZING SLOT %X | Folder Name: '%s'", slotNumber, npcFolder.Name))
    scanLog("==============================================")
    
    -- 1. Check Display Name / Special Customer Status
    local dispName = npcFolder:FindFirstChild("DisplayName")
    scanLog("• DisplayName Object Value: " .. tostring(dispName and dispName.Value or "NOT FOUND"))
    
    local specCust = npcFolder:FindFirstChild("SpecialCustomer")
    scanLog("• SpecialCustomer Value: " .. tostring(specCust and specCust.Value or "NOT FOUND"))

    -- 2. Scan for the Order inside Object Values
    local requestedDish = npcFolder:FindFirstChild("RequestedDish")
    scanLog("• RequestedDish Object Value: " .. tostring(requestedDish and requestedDish.Value or "NOT FOUND"))
    
    -- 3. Scan all Attributes attached to the folder
    scanLog("--- [Attributes Scan] ---")
    local attributes = npcFolder:GetAttributes()
    local hasAttributes = false
    for key, value in pairs(attributes) do
        hasAttributes = true
        scanLog(string.format("  Attribute -> %s: %s", key, tostring(value)))
    end
    if not hasAttributes then scanLog("  No attributes found on folder.") end

    -- 4. Scan physical Character Model for hidden UI / Chat Bubbles
    scanLog("--- [Character & Bubble UI Scan] ---")
    local charVal = npcFolder:FindFirstChild("CHAR")
    if charVal and charVal.Value then
        local model = charVal.Value
        scanLog("  Character Model found: " .. model:GetFullName())
        
        -- Search through the model for any text or BillboardGuis
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
                scanLog(string.format("  Found UI: %s", descendant:GetFullName()))
                -- Print out text labels inside this UI
                for _, textLabel in ipairs(descendant:GetDescendants()) do
                    if textLabel:IsA("TextLabel") or textLabel:IsA("TextBox") then
                        scanLog(string.format("    ↳ Text Box Content [%s]: '%s'", textLabel.Name, textLabel.Text))
                    end
                end
            end
        end
    else
        scanLog("  ❌ No physical character model (CHAR) loaded yet.")
    end
    print("\n") -- Space out the logs
end

local function RunScanner()
    scanLog("Starting scan...")
    local codeFolder = Workspace:FindFirstChild("Code")
    local activeNPCs = codeFolder and codeFolder:FindFirstChild("ActiveNPCs")
    
    if not activeNPCs then
        scanLog("❌ CRITICAL: Cannot find Workspace.Code.ActiveNPCs folder!")
        return
    end
    
    local lanternBase = GetLanternAnchor()
    local scannedList = {}
    
    -- Gather and sort using your exact math layout
    for _, npc in ipairs(activeNPCs:GetChildren()) do
        local position = GetNPCPosition(npc)
        if position then
            local horizontalOffset = 0
            if lanternBase then
                local objectVector = position - lanternBase.Position
                horizontalOffset = objectVector:Dot(lanternBase.CFrame.RightVector)
            else
                horizontalOffset = position.X
            end
            
            table.insert(scannedList, {
                folder = npc,
                offset = horizontalOffset
            })
        end
    end
    
    -- Sort Left to Right
    table.sort(scannedList, function(a, b) return a.offset < b.offset end)
    
    if #scannedList == 0 then
        scanLog("⚠️ No NPCs detected in front of your stall right now. Wait for them to walk up and run it again!")
        return
    end
    
    scanLog(string.format("Found %d active customer folders. Processing allocations...", #scannedList))
    
    -- Scan Slot 1 and Slot 2
    if scannedList[1] then DeepScanNPC(scannedList[1].folder, 1) end
    if scannedList[2] then DeepScanNPC(scannedList[2].folder, 2) end
end

-- Execute the scanner
RunScanner()
