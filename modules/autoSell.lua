local AutoSell = {}
local loopThread = nil

-- Configuration States
AutoSell.Enabled      = false
AutoSell.SelectedFish = {}   -- Array of fish Name strings to sell (empty = sell ALL)
AutoSell.Interval     = 10   -- Seconds between each auto-sell cycle
AutoSell.AllFishTypes = {}   -- Populated at runtime by FetchAllFishTypes()

-- ─────────────────────────────────────────
-- FetchAllFishTypes()
-- Queries the confirmed RF path and returns
-- every unique fish Name from the player's
-- current inventory. Names are exact internal
-- strings (e.g. "yellowtail_kingfish") as
-- used by the SellFish remote.
-- ─────────────────────────────────────────
function AutoSell.FetchAllFishTypes()
    local RS = game:GetService("ReplicatedStorage")

    local ok, RequestFishData = pcall(function()
        return RS
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("Fish", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("RequestFishData", 5)
    end)

    if not ok or not RequestFishData then
        warn("[AutoSell]: Could not reach RequestFishData RF.")
        return {}
    end

    local success, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)

    if not success or type(inventory) ~= "table" then
        warn("[AutoSell]: RequestFishData returned no data.")
        return {}
    end

    -- Collect unique fish names in the order they appear
    local names = {}
    local seen  = {}
    for _, item in pairs(inventory) do
        -- The game stores the internal fish type in CF or Name
        local fishName = item.CF or item.Name
        if fishName and type(fishName) == "string" then
            local lower = string.lower(fishName)
            if not seen[lower] then
                seen[lower] = true
                table.insert(names, fishName)
            end
        end
    end

    table.sort(names)
    print("[AutoSell]: Discovered " .. #names .. " unique fish types from inventory.")
    return names
end

-- ─────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────
local function getRemotes()
    local RS = game:GetService("ReplicatedStorage")
    local ok, results = pcall(function()
        local Pkgs     = RS:WaitForChild("Packages", 5)
        local Services = Pkgs:WaitForChild("Knit", 5):WaitForChild("Services", 5)
        local FishSvc  = Services:WaitForChild("Fish", 5)
        return
            FishSvc:WaitForChild("RF", 5):WaitForChild("RequestFishData", 5),
            FishSvc:WaitForChild("RE", 5):WaitForChild("SellFish", 5)
    end)
    if not ok then return nil, nil end
    return results -- Lua multiple-return through pcall doesn't work cleanly, see below
end

-- Cleaner approach: individual pcall per remote
local function resolveRemotes()
    local RS = game:GetService("ReplicatedStorage")
    local requestFishData, sellFish

    pcall(function()
        local Services = RS
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
        local FishSvc = Services:WaitForChild("Fish", 5)
        requestFishData = FishSvc:WaitForChild("RF", 5):WaitForChild("RequestFishData", 5)
        sellFish        = FishSvc:WaitForChild("RE", 5):WaitForChild("SellFish", 5)
    end)

    return requestFishData, sellFish
end

-- ─────────────────────────────────────────
-- SellNow()
-- Fetches inventory, filters by selected
-- fish types, skips favorites, fires one
-- batch SellFish call.
-- ─────────────────────────────────────────
function AutoSell.SellNow()
    local RequestFishData, SellFish = resolveRemotes()
    if not (RequestFishData and SellFish) then
        warn("[AutoSell]: Could not reach Fish remotes.")
        return -1
    end

    local ok, inventory = pcall(function()
        return RequestFishData:InvokeServer()
    end)
    if not ok or type(inventory) ~= "table" then
        warn("[AutoSell]: Failed to fetch inventory.")
        return -1
    end

    -- Build lookup set from selected fish
    local sellSet = {}
    local sellAll = (#AutoSell.SelectedFish == 0)
    if not sellAll then
        for _, name in ipairs(AutoSell.SelectedFish) do
            sellSet[string.lower(name)] = true
        end
    end

    -- Build sell batch — skip favorites
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
        print("[AutoSell]: Nothing to sell (empty match or all favorited).")
        return 0
    end

    local sellOk, sellErr = pcall(function()
        SellFish:FireServer(batch)
    end)

    if sellOk then
        print("[AutoSell]: Sold " .. #batch .. " fish.")
        return #batch
    else
        warn("[AutoSell]: SellFish error – " .. tostring(sellErr))
        return -1
    end
end

-- ─────────────────────────────────────────
-- Timer loop
-- ─────────────────────────────────────────
function AutoSell.Start()
    if loopThread then task.cancel(loopThread) end
    print("[AutoSell]: Started. Interval = " .. AutoSell.Interval .. "s")

    loopThread = task.spawn(function()
        while AutoSell.Enabled do
            AutoSell.SellNow()
            -- 1-second tick so interval changes apply without restart
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
    print("[AutoSell]: Stopped.")
end

return AutoSell
