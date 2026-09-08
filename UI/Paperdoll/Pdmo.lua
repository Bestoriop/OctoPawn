-------------------------------------------------
-- OctoPawn UI/Paperdoll/Pdmo.lua
-------------------------------------------------
local function StripColors(s)
    if not s then return "" end
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|C%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|R", "")
    return s
end

local function BaseName(s)
    s = StripColors(s or "")
    s = string.gsub(s, "%s*%[.*%]$", "")
    s = string.gsub(s, " %- .*$", "")
    return s
end

local function IsMeterTooltip()
    local i
    for i = 1, 20 do
        local fs = getglobal("GameTooltipTextLeft" .. i)
        if fs then
            local u = string.upper(StripColors(fs:GetText() or ""))
            if string.find(u, "^DAMAGE:")
                or string.find(u, "^HEALING:")
                or string.find(u, "^DPS:")
                or string.find(u, "^TPS:")
                or string.find(u, "^THREAT:")
                or string.find(u, "^DURATION:")
                or string.find(u, "BY SPELL")
                or string.find(u, "BY TARGET")
                then
                return true
            end
        end
    end
    return false
end

local function ResolveTooltipUnit()
    if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
        return "mouseover"
    end
    local tipName = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    if not tipName then return nil end
    tipName = BaseName(tipName)
    if tipName == "" then return nil end
    local function nameMatch(unit)
        if not UnitExists(unit) then return false end
        local n = UnitName(unit)
        local p = UnitPVPName and UnitPVPName(unit)
        return (n and n == tipName) or (p and BaseName(p) == tipName)
    end
    if nameMatch("player") then return "player" end
    if nameMatch("target") then return "target" end
    local i
    for i = 1, 4 do
        if nameMatch("party" .. i) then return "party" .. i end
    end
    for i = 1, 40 do
        if nameMatch("raid" .. i) then return "raid" .. i end
    end
    return nil
end

local function AddUnitOPScoreFromShow()
    if GameTooltip.octoPawnUnitScored then return end
    if IsMeterTooltip() then return end
    local unit = ResolveTooltipUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local total = 0
    if UnitIsUnit(unit, "player") then
        total = OctoPawn_ScorePlayer and OctoPawn_ScorePlayer() or 0
    else
        local _, class = UnitClass(unit)
        local role = OctoPawn_GetInspectRole and OctoPawn_GetInspectRole(class)
        local weights = OctoPawn_GetWeightsForClassRole and OctoPawn_GetWeightsForClassRole(class, role) or {}
        total = OctoPawn_ScoreUnitQuiet and OctoPawn_ScoreUnitQuiet(unit, weights) or 0
    end

    GameTooltip.octoPawnUnitScored = true
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(OctoPawn_FormatScore and OctoPawn_FormatScore(total) or ("OP Score: " .. total))
    GameTooltip:Show()
end

do
    local oldTipHide = GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide", function()
        this.octoPawnUnitScored = nil
        if oldTipHide then oldTipHide() end
    end)
end

-- Delay so meter addons can finish writing Damage/DPS lines before we decide
local opTipWatcher = CreateFrame("Frame", nil, GameTooltip)
opTipWatcher:SetScript("OnShow", function()
    local delay = CreateFrame("Frame")
    local elapsed = 0
    delay:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed > 0.08 then
            delay:SetScript("OnUpdate", nil)
            pcall(AddUnitOPScoreFromShow)
        end
    end)
end)

print("|cFF00FF00OctoPawn|r paperdoll mouseover loaded")
