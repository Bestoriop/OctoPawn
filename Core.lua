-------------------------------------------------
-- OctoPawn Core.lua
-------------------------------------------------
OctoPawnDB = OctoPawnDB or nil

function OctoPawn_GetClass()
    local _, class = UnitClass("player")
    return class
end

function OctoPawn_GetDefaultWeights()
    local class = OctoPawn_GetClass()
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return {} end
    local role = OctoPawnDB and OctoPawnDB.role
    local base
    if role and classTable[role] then base = classTable[role]
    elseif classTable.Default then base = classTable.Default
    else
        for _, weights in pairs(classTable) do base = weights; break end
    end
    if not base then return {} end
    if OctoPawnDB and OctoPawnDB.defaultOverrides and role then
        local over = OctoPawnDB.defaultOverrides[class] and OctoPawnDB.defaultOverrides[class][role]
        if over and OctoPawn_Merge then
            return OctoPawn_Merge(base, over)
        end
    end
    return base
end

function OctoPawn_GetDefaultsForClass(class)
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return {} end
    if classTable.Default then return classTable.Default end
    for _, weights in pairs(classTable) do return weights end
    return {}
end

function OctoPawn_GetRolesForClass(class)
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return { "Default" } end
    local roles = {}
    for role in pairs(classTable) do table.insert(roles, role) end
    if table.getn(roles) == 0 then return { "Default" } end
    table.sort(roles)
    return roles
end

-- Weights for a specific role: custom if saved, else class defaults (+ overrides)
function OctoPawn_GetWeightsForRole(class, role)
    if not class or not role then return {} end
    local classTable = defaultWeights and defaultWeights[class]
    local base = {}
    if classTable and classTable[role] then
        for k, v in pairs(classTable[role]) do base[k] = v end
    end
    if OctoPawnDB and OctoPawnDB.defaultOverrides and OctoPawnDB.defaultOverrides[class]
        and OctoPawnDB.defaultOverrides[class][role] then
        for k, v in pairs(OctoPawnDB.defaultOverrides[class][role]) do
            base[k] = v
        end
    end
    if OctoPawnDB and OctoPawnDB.customWeights and OctoPawnDB.customWeights[role] then
        for k, v in pairs(OctoPawnDB.customWeights[role]) do
            base[k] = v
        end
    end
    return base
end

function OctoPawn_ApplyRole(role, isCustom)
    local class = OctoPawn_GetClass()
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: No defaults for " .. tostring(class) .. "|r")
        return
    end
    local source = classTable[role]
    if not source then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Unknown role " .. tostring(role) .. "|r")
        return
    end
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    OctoPawnDB.role = role
    OctoPawnDB.weights = {}
    if isCustom and OctoPawnDB.customWeights[role] then
        OctoPawnDB.useCustom = true
        for stat, value in pairs(OctoPawnDB.customWeights[role]) do
            OctoPawnDB.weights[stat] = value
        end
        -- fill any missing from defaults
        for stat, value in pairs(source) do
            if OctoPawnDB.weights[stat] == nil then
                OctoPawnDB.weights[stat] = value
            end
        end
    else
        OctoPawnDB.useCustom = nil
        local weights = source
        if OctoPawnDB.defaultOverrides and OctoPawnDB.defaultOverrides[class]
            and OctoPawnDB.defaultOverrides[class][role] then
            if OctoPawn_Merge then
                weights = OctoPawn_Merge(source, OctoPawnDB.defaultOverrides[class][role])
            end
        end
        for stat, value in pairs(weights) do
            OctoPawnDB.weights[stat] = value
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Using " .. role .. (isCustom and " (custom)" or "") .. " weights.|r")
    if OctoPawn_UpdatePlayerPaperScore then OctoPawn_UpdatePlayerPaperScore() end
end

-------------------------------------------------
-- Sparse import / export (OPW1)
-- OPW1:CLASS:ROLE:*STAT:val|STAT:val
-------------------------------------------------
local function TrimNum(n)
    local s = string.format("%.4f", n)
    s = string.gsub(s, "0+$", "")
    s = string.gsub(s, "%.$", "")
    return s
end

function OctoPawn_ExportWeightsSparse()
    local class = OctoPawn_GetClass()
    local role = OctoPawnDB and OctoPawnDB.role
    if not class or not role then
        return nil, "No active role"
    end
    local classTable = defaultWeights and defaultWeights[class]
    local base = (classTable and classTable[role]) or {}
    local current = (OctoPawnDB and OctoPawnDB.weights) or {}
    local parts = {}
    for stat, val in pairs(current) do
        local b = base[stat]
        if b == nil then b = 0 end
        if math.abs((val or 0) - b) > 0.00005 then
            table.insert(parts, stat .. ":" .. TrimNum(val))
        end
    end
    table.sort(parts)
    if table.getn(parts) == 0 then
        return "OPW1:" .. class .. ":" .. role .. ":*", nil
    end
    local body = parts[1]
    local i
    for i = 2, table.getn(parts) do
        body = body .. "|" .. parts[i]
    end
    return "OPW1:" .. class .. ":" .. role .. ":*" .. body, nil
end

function OctoPawn_ImportWeightsSparse(str)
    if not str or str == "" then
        return false, "Empty string"
    end
    str = string.gsub(str, "^%s+", "")
    str = string.gsub(str, "%s+$", "")
    -- OPW1:CLASS:ROLE:*STAT:val|STAT:val
    local _, _, ver, class, role, rest = string.find(str, "^(OPW%d+):([%w_]+):([%w_]+):(.*)$")
    if not ver or not class or not role then
        return false, "Invalid format (need OPW1:CLASS:ROLE:*...)"
    end
    if string.sub(rest, 1, 1) ~= "*" then
        return false, "Only sparse (*) format supported"
    end
    rest = string.sub(rest, 2)
    local playerClass = OctoPawn_GetClass()
    if class ~= playerClass then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Import class is " .. class
            .. ", you are " .. tostring(playerClass) .. " — applying to current role weights anyway.|r")
    end
    local classTable = defaultWeights and defaultWeights[playerClass]
    if not classTable or not classTable[role] then
        -- try imported class table for role existence
        if not (defaultWeights and defaultWeights[class] and defaultWeights[class][role]) then
            return false, "Unknown role: " .. tostring(role)
        end
    end
    local base = {}
    if classTable and classTable[role] then
        for k, v in pairs(classTable[role]) do base[k] = v end
    elseif defaultWeights and defaultWeights[class] and defaultWeights[class][role] then
        for k, v in pairs(defaultWeights[class][role]) do base[k] = v end
    end
    local overrides = {}
    if rest ~= "" then
        local chunk
        for chunk in string.gfind(rest, "[^|]+") do
            local _, _, stat, num = string.find(chunk, "^([^:]+):([%-%d%.]+)$")
            if stat and num then
                local v = tonumber(num)
                if v then overrides[stat] = v end
            end
        end
    end
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    OctoPawnDB.role = role
    OctoPawnDB.useCustom = true
    OctoPawnDB.weights = {}
    OctoPawnDB.customWeights[role] = {}
    for k, v in pairs(base) do
        OctoPawnDB.weights[k] = v
    end
    for k, v in pairs(overrides) do
        OctoPawnDB.weights[k] = v
        OctoPawnDB.customWeights[role][k] = v
    end
    -- store full custom snapshot so ApplyRole(custom) works
    for k, v in pairs(OctoPawnDB.weights) do
        OctoPawnDB.customWeights[role][k] = v
    end
    return true, role
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 ~= "OctoPawn" then return end
        if type(OctoPawnDB) ~= "table" then OctoPawnDB = {} end
        if type(OctoPawnDB.weights) ~= "table" then OctoPawnDB.weights = {} end
        if type(OctoPawnDB.customWeights) ~= "table" then OctoPawnDB.customWeights = {} end
        if type(OctoPawnDB.inspectRole) ~= "table" then OctoPawnDB.inspectRole = {} end
        if type(OctoPawnDB.dr) ~= "table" then OctoPawnDB.dr = {} end
        if type(OctoPawnDB.defaultOverrides) ~= "table" then OctoPawnDB.defaultOverrides = {} end
        if OctoPawnDB.showAllSpecs == nil then OctoPawnDB.showAllSpecs = false end
        if OctoPawnDB.compactTooltips == nil then OctoPawnDB.compactTooltips = false end
        if OctoPawnDB.role then
            local role = OctoPawnDB.role
            if OctoPawnDB.useCustom and OctoPawnDB.customWeights[role] then
                for stat, value in pairs(OctoPawnDB.customWeights[role]) do
                    if OctoPawnDB.weights[stat] == nil then OctoPawnDB.weights[stat] = value end
                end
            end
            local defaults = OctoPawn_GetDefaultWeights()
            for stat, value in pairs(defaults) do
                if OctoPawnDB.weights[stat] == nil then OctoPawnDB.weights[stat] = value end
            end
        end
        if OctoPawn_OnDBReady then OctoPawn_OnDBReady() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        this:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local needsPicker = false
        if not OctoPawnDB.role then needsPicker = true
        else
            local n = 0
            for _ in pairs(OctoPawnDB.weights or {}) do n = n + 1; break end
            if n == 0 then needsPicker = true end
        end
        if needsPicker and OctoPawn_ShowRolePicker then
            pcall(OctoPawn_ShowRolePicker)
        end
    end
end)

print("|cFF00FF00OctoPawn|r core loaded")
