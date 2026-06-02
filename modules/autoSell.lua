local AutoSell = {}
local loopThread = nil

-- Configuration States
AutoSell.Enabled      = false
AutoSell.SelectedFish = {}   -- Array of fish Name strings to sell (empty = sell ALL)
AutoSell.Interval     = 10   -- Seconds between each auto-sell cycle
AutoSell.AllFishTypes = {}   -- Populated at runtime by FetchAllFishTypes()

-- ─────────────────────────────────────────
-- Utility: recursively scan a container for
-- ModuleScripts whose name hints at fish data
-- ─────────────────────────────────────────
local function scanForFishModule(root, depth)
    depth = depth or 0
    if depth > 5 then return nil end
    for _, child in ipairs(root:GetChildren()) do
        local lname = string.lower(child.Name)
        if child:IsA("ModuleScript") and (
            string.find(lname, "fish") or
            string.find(lname, "catalog") or
            string.find(lname, "types") or
            string.find(lname, "config") or
            string.find(lname, "data")
        ) then
            return child
        end
        local found = scanForFishModule(child, depth + 1)
        if found then return found end
    end
    return nil
end

-- ─────────────────────────────────────────
-- Extract fish names from whatever shape the
-- data module returns (table keyed by name,
-- array of strings, array of objects, etc.)
-- ─────────────────────────────────────────
local function extractNamesFromData(data)
    local names = {}
    local seen  = {}
    if type(data) ~= "table" then return names end

    for k, v in pairs(data) do
        local candidate = nil
        if type(v) == "string" then
            -- { "salmon", "tuna", ... }  or  { salmon = "Salmon", ... }
            candidate = v
        elseif type(v) == "table" then
            -- { { Name="salmon", ... }, ... }  or  { salmon = { DisplayName="Salmon", ... } }
            candidate = v.Name or v.name or v.ID or v.id or
                        v.FishName or v.fishName or (type(k) == "string" and k) or nil
        elseif type(k) == "string" and type(v) ~= "function" then
            -- { salmon = { ... } }
            candidate = k
        end

        if candidate and type(candidate) == "string" then
            local lower = string.lower(candidate)
            if not seen[lower] and lower ~= "" then
                seen[lower] = true
                table.insert(names, candidate)
            end
        end
    end

    table.sort(names)
    return names
end

-- ─────────────────────────────────────────
-- Try to call a RemoteFunction by name and
-- extract fish names from the result
-- ─────────────────────────────────────────
local function tryRemote(rfFolder, remoteName)
    local rf = rfFolder:FindFirstChild(remoteName)
    if not rf then return nil end
    local ok, result = pcall(function() return rf:InvokeServer() end)
    if not ok or type(result) ~= "table" then return nil end
    local names = extractNamesFromData(result)
    if #names > 0 then
        print("[AutoSell]: Got " .. #names .. " fish types from remote '" .. remoteName .. "'")
        return names
    end
    return nil
end

-- ─────────────────────────────────────────
-- FetchAllFishTypes()
--   Priority order:
--   1. Known RF names (GetFishTypes, RequestFishTypes, etc.)
--   2. Scan RS for a fish data ModuleScript → require it
--   3. Harvest unique names already in the player's inventory
--      (partial – only covers what the player has caught)
-- ─────────────────────────────────────────
function AutoSell.FetchAllFishTypes()
    local RS       = game:GetService("ReplicatedStorage")
    local Packages = RS:FindFirstChild("Packages")
    if not Packages then
        warn("[AutoSell]: Packages not found – cannot discover fish types.")
        return {}
    end

    local Knit     = Packages:FindFirstChild("Knit")
    if not Knit then return {} end
    local Services = Knit:FindFirstChild("Services")
    if not Services then return {} end

    local FishSvc = Services:FindFirstChild("Fish")
    if not FishSvc then return {} end

    local FishRF = FishSvc:FindFirstChild("RF")

    -- ── Method 1: well-known RF names ───────────────────────────────────
    if FishRF then
        local knownRemotes = {
            "GetFishTypes",
            "RequestFishTypes",
            "GetFishCatalog",
            "RequestFishCatalog",
            "GetAllFish",
            "RequestAllFish",
            "FishTypes",
            "FishCatalog",
            "GetFishData",
        }
        for _, name in ipairs(knownRemotes) do
            local result = tryRemote(FishRF, name)
            if result and #result > 0 then return result end
        end
    end

    -- ── Method 2: scan RS for any fish data ModuleScript ────────────────
    local dataSources = {
        RS,
        RS:FindFirstChild("FishData"),
        RS:FindFirstChild("GameData"),
        RS:FindFirstChild("Data"),
        RS:FindFirstChild("Config"),
        RS:FindFirstChild("Shared"),
        Packages,
    }
    for _, source in ipairs(dataSources) do
        if source then
            local mod = scanForFishModule(source)
            if mod then
                local ok, data = pcall(function() return require(mod) end)
                if ok and type(data) == "table" then
                    local names = extractNamesFromData(data)
                    if #names > 0 then
                        print("[AutoSell]: Got " .. #names .. " fish types from module '" .. mod.Name .. "'")
                        return names
                    end
                end
            end
        end
    end

    -- ── Method 3: mine the player's current inventory ───────────────────
    -- This only returns fish the player already has, but it's better than
    -- a stale hardcoded list of fictional fish names.
    local FishRFNode = FishSvc:FindFirstChild("RF")
    if FishRFNode then
        local RequestFishData = FishRFNode:FindFirstChild("RequestFishData")
        if RequestFishData then
            local ok, inventory = pcall(function()
                return RequestFishData:InvokeServer()
            end)
            if ok and type(inventory) == "table" then
                local names = {}
                local seen  = {}
                for _, item in pairs(inventory) do
                    local fishName = item.CF or item.Name
                    if fishName then
                        local lower = string.lower(fishName)
                        if not seen[lower] then
                            seen[lower] = true
                            table.insert(names, fishName)
                        end
                    end
                end
                table.sort(names)
                if #names > 0 then
                    print("[AutoSell]: Discovered " .. #names .. " fish types from inventory (partial).")
                    return names
                end
            end
        end
    end

    warn("[AutoSell]: Could not discover fish types automatically. Returning empty list.")
    return {}
end

-- ─────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────
local function getRemotes()
    local RS       = game:GetService("ReplicatedStorage")
    local Packages = RS:WaitForChild("Packages", 5)
    if not Packages then return nil, nil end
    local Knit     = Packages:WaitForChild("Knit", 5)
    local Services = Knit:WaitForChild("Services", 5)
    local FishSvc  = Services:WaitForChild("Fish", 5)
    local FishRF   = FishSvc:WaitForChild("RF", 5)
    local FishRE   = FishSvc:WaitForChild("RE", 5)
    local RequestFishData = FishRF:WaitForChild("RequestFishData", 5)
    local SellFish        = FishRE:WaitForChild("SellFish", 5)
    return RequestFishData, SellFish
end

-- ─────────────────────────────────────────
-- Sell all matching fish in one batch call
-- Returns number of fish sold (or -1 on error)
-- ─────────────────────────────────────────
function AutoSell.SellNow()
    local RequestFishData, SellFish = getRemotes()
    if not (RequestFishData and SellFish) then
        warn("[AutoSell]: Could not reach Fish remotes.")
        return -1
    end

    -- Fetch live inventory
    local ok, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    if not ok or type(inventory) ~= "table" then
        warn("[AutoSell]: Failed to fetch inventory.")
        return -1
    end

    -- Build selection set for quick lookup
    local sellSet = {}
    local sellAll = (#AutoSell.SelectedFish == 0)
    if not sellAll then
        for _, name in ipairs(AutoSell.SelectedFish) do
            sellSet[string.lower(name)] = true
        end
    end

    -- Filter – skip favorites, only include selected fish types
    local batch = {}
    for _, item in pairs(inventory) do
        if item.Favorite then continue end

        local fishName = item.CF or item.Name
        if not fishName then continue end

        local lowerName = string.lower(fishName)
        if sellAll or sellSet[lowerName] then
            table.insert(batch, {
                ID     = item.ID,
                Name   = fishName,
                Weight = item.Weight or 1
            })
        end
    end

    if #batch == 0 then
        print("[AutoSell]: No matching fish to sell (or all are favorited).")
        return 0
    end

    -- Fire SellFish remote with the batch payload
    local sellOk, sellErr = pcall(function()
        SellFish:FireServer(batch)
    end)

    if sellOk then
        print("[AutoSell]: Sold " .. #batch .. " fish.")
        return #batch
    else
        warn("[AutoSell]: SellFish remote error – " .. tostring(sellErr))
        return -1
    end
end

-- ─────────────────────────────────────────
-- Timer loop
-- ─────────────────────────────────────────
function AutoSell.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AutoSell]: Thread initialized. Interval = " .. AutoSell.Interval .. "s")

    loopThread = task.spawn(function()
        while AutoSell.Enabled do
            AutoSell.SellNow()
            local waited = 0
            while AutoSell.Enabled and waited < AutoSell.Interval do
                task.wait(1)
                waited = waited + 1
            end
        end
    end)
end

function AutoSell.Stop()
    AutoSell.Enabled = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    print("[AutoSell]: Thread terminated.")
end

return AutoSell
