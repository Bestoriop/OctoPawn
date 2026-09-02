-------------------------------------------------
-- OctoPawn UI/Config.lua
-------------------------------------------------
local editBoxes = {}
local orderedBoxes = {}
local createdFrames = {}
local configFrame, scrollFrame, scrollChild, title
local rolePickerFrame
local compareBtn
local advancedFrame
local advRows = {}
local shareFrame
local allSpecsCheck

local function StatLabel(stat)
    if OctoPawn_StatLabel then return OctoPawn_StatLabel(stat) end
    local map = {
        DPS = "WEAPON DPS", CRIT = "CRIT %", HIT = "HIT %",
        DODGE = "DODGE %", PARRY = "PARRY %", BLOCK = "BLOCK %", HASTE = "HASTE %",
        ["SPELL CRIT"] = "SPELL CRIT %", ["SPELL HIT"] = "SPELL HIT %",
        ["RANGED CRIT"] = "RANGED CRIT %", ["RANGED HASTE"] = "RANGED HASTE %",
        ["HOLY CRIT"] = "HOLY CRIT %", AVOIDANCE = "AVOIDANCE %", RESILIENCE = "RESILIENCE %",
        ["EXTRA ATTACK"] = "EXTRA ATTACK %",
        LIFESTEAL = "LIFESTEAL %", ["CASTING REGEN"] = "CASTING REGEN %",
        ["MOVEMENT SPEED"] = "MOVEMENT SPEED %", ["MOUNT SPEED"] = "MOUNT SPEED %",
    }
    return map[stat] or stat
end

local function UpdateMinimapButtonPosition()
    if not OctoPawnMinimapBtn then return end
    local angle = 200
    if OctoPawnDB and OctoPawnDB.minimapPos then angle = OctoPawnDB.minimapPos end
    local rad = math.rad(angle)
    OctoPawnMinimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * 80, math.sin(rad) * 80)
end

local function CreateMinimapButton()
    if OctoPawnMinimapBtn then return end
    local btn = CreateFrame("Button", "OctoPawnMinimapBtn", Minimap)
    btn:SetWidth(31); btn:SetHeight(31)
    btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8)
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_03"); btn.icon = icon
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53); overlay:SetHeight(53); overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", function()
            local mx, my = GetCursorPosition()
            local cx, cy = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            mx, my = mx / scale, my / scale
            local angle = math.deg(math.atan2(my - cy, mx - cx))
            if angle < 0 then angle = angle + 360 end
            if not OctoPawnDB then OctoPawnDB = {} end
            OctoPawnDB.minimapPos = angle
            UpdateMinimapButtonPosition()
        end)
    end)
    btn:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then ToggleConfigFrame() end
    end)
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("OctoPawn", 0, 1, 0)
        local role = (OctoPawnDB and OctoPawnDB.role) or "none"
        GameTooltip:AddLine("Role: " .. role, 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Left-click: Open config", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UpdateMinimapButtonPosition()
end
CreateMinimapButton()
local delayFrame = CreateFrame("Frame")
delayFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
delayFrame:SetScript("OnEvent", function()
    CreateMinimapButton()
    UpdateMinimapButtonPosition()
end)

configFrame = CreateFrame("Frame", nil, UIParent)
configFrame:SetWidth(420); configFrame:SetHeight(500)
configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
})
configFrame:Hide()
configFrame:EnableMouse(true)
configFrame:SetMovable(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", function() this:StartMoving() end)
configFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", configFrame, "TOP", 0, -18)
title:SetText("OctoPawn")
local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)
scrollFrame = CreateFrame("ScrollFrame", "OctoPawnScrollFrame", configFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -150, 70)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
    local current = this:GetVerticalScroll()
    local maxScroll = this:GetVerticalScrollRange()
    local scrollStep = 28
    if arg1 > 0 then
        local newPos = current - scrollStep
        if newPos < 0 then newPos = 0 end
        this:SetVerticalScroll(newPos)
    else
        local newPos = current + scrollStep
        if newPos > maxScroll then newPos = maxScroll end
        this:SetVerticalScroll(newPos)
    end
end)
scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(250); scrollChild:SetHeight(1600)
scrollFrame:SetScrollChild(scrollChild)

local function UpdateCompareButtonText()
    if not compareBtn then return end
    if OctoPawnDB and OctoPawnDB.compareEnabled == false then
        compareBtn:SetText("Compare: OFF")
    else
        compareBtn:SetText("Compare: ON")
    end
end

local function MakeCmdButton(label, yOffset, onClick)
    local b = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    b:SetWidth(105); b:SetHeight(26)
    b:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -18, yOffset)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

MakeCmdButton("Spec", -55, function()
    OctoPawn_ShowRolePicker()
end)
compareBtn = MakeCmdButton("Compare: ON", -88, function()
    if not OctoPawnDB then OctoPawnDB = {} end
    if OctoPawnDB.compareEnabled == false then
        OctoPawnDB.compareEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Item compare ON|r")
    else
        OctoPawnDB.compareEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Item compare OFF|r")
    end
    UpdateCompareButtonText()
end)
MakeCmdButton("Reset", -121, function()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.weights = {}
    OctoPawnDB.role = nil
    OctoPawnDB.useCustom = false
    if OctoPawn_WipeConfigUI then OctoPawn_WipeConfigUI() end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Weights cleared. Choose a role.|r")
    if OctoPawn_ShowRolePicker then OctoPawn_ShowRolePicker() end
end)
MakeCmdButton("Help", -154, function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: /op /op compare /op spec /op reset /op help|r")
end)
MakeCmdButton("Advanced", -187, function()
    if ToggleAdvancedFrame then ToggleAdvancedFrame() end
end)
MakeCmdButton("Share", -220, function()
    if ToggleShareFrame then ToggleShareFrame() end
end)

-------------------------------------------------
-- All-specs checkbox
-------------------------------------------------
allSpecsCheck = CreateFrame("CheckButton", "OctoPawnAllSpecsCheck", configFrame, "UICheckButtonTemplate")
allSpecsCheck:SetWidth(24); allSpecsCheck:SetHeight(24)
allSpecsCheck:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -100, -252)
allSpecsCheck:SetScript("OnClick", function()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.showAllSpecs = this:GetChecked() and true or false
end)
local allSpecsLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
allSpecsLabel:SetPoint("RIGHT", allSpecsCheck, "LEFT", -2, 0)
allSpecsLabel:SetText("All specs on tips")

local function SyncAllSpecsCheck()
    if not allSpecsCheck then return end
    if OctoPawnDB and OctoPawnDB.showAllSpecs then
        allSpecsCheck:SetChecked(1)
    else
        allSpecsCheck:SetChecked(0)
    end
end

-------------------------------------------------
-- Compact tooltips checkbox (off by default)
-------------------------------------------------
local compactCheck = CreateFrame("CheckButton", "OctoPawnCompactCheck", configFrame, "UICheckButtonTemplate")
compactCheck:SetWidth(24); compactCheck:SetHeight(24)
compactCheck:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -100, -276)
compactCheck:SetScript("OnClick", function()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.compactTooltips = this:GetChecked() and true or false
end)
local compactLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
compactLabel:SetPoint("RIGHT", compactCheck, "LEFT", -2, 0)
compactLabel:SetText("Compact tooltips")

local function SyncCompactCheck()
    if not compactCheck then return end
    if OctoPawnDB and OctoPawnDB.compactTooltips then
        compactCheck:SetChecked(1)
    else
        compactCheck:SetChecked(0)
    end
end

function OctoPawn_RefreshCompareButton() UpdateCompareButtonText() end

-------------------------------------------------
-- Share frame (import / export sparse)
-------------------------------------------------
local function EnsureShareFrame()
    if shareFrame then return end
    shareFrame = CreateFrame("Frame", "OctoPawnShareFrame", UIParent)
    shareFrame:SetWidth(420); shareFrame:SetHeight(200)
    shareFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    shareFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
    })
    shareFrame:SetFrameStrata("DIALOG")
    shareFrame:EnableMouse(true)
    shareFrame:SetMovable(true)
    shareFrame:RegisterForDrag("LeftButton")
    shareFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    shareFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    shareFrame:Hide()

    local st = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    st:SetPoint("TOP", shareFrame, "TOP", 0, -14)
    st:SetText("Share Weights")

    local close = CreateFrame("Button", nil, shareFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", shareFrame, "TOPRIGHT", -4, -4)

    local hint = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", st, "BOTTOM", 0, -4)
    hint:SetText("Sparse export — only stats that differ from role defaults")

    local box = CreateFrame("EditBox", "OctoPawnShareEditBox", shareFrame)
    box:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 20, -50)
    box:SetPoint("BOTTOMRIGHT", shareFrame, "BOTTOMRIGHT", -20, 50)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetMaxLetters(2500)
    box:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    box:SetBackdropColor(0, 0, 0, 0.8)
    box:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
    box:SetTextInsets(6, 6, 6, 6)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    shareFrame.edit = box

    local exportBtn = CreateFrame("Button", nil, shareFrame, "UIPanelButtonTemplate")
    exportBtn:SetWidth(100); exportBtn:SetHeight(26)
    exportBtn:SetPoint("BOTTOMLEFT", shareFrame, "BOTTOMLEFT", 30, 14)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        if not OctoPawn_ExportWeightsSparse then return end
        local s, err = OctoPawn_ExportWeightsSparse()
        if not s then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Export failed — " .. tostring(err) .. "|r")
            return
        end
        shareFrame.edit:SetText(s)
        shareFrame.edit:HighlightText()
        shareFrame.edit:SetFocus()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Exported. Ctrl+C to copy.|r")
    end)

    local importBtn = CreateFrame("Button", nil, shareFrame, "UIPanelButtonTemplate")
    importBtn:SetWidth(100); importBtn:SetHeight(26)
    importBtn:SetPoint("BOTTOMRIGHT", shareFrame, "BOTTOMRIGHT", -30, 14)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local text = shareFrame.edit:GetText() or ""
        if not OctoPawn_ImportWeightsSparse then return end
        local ok, info = OctoPawn_ImportWeightsSparse(text)
        if not ok then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Import failed — " .. tostring(info) .. "|r")
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Imported weights for " .. tostring(info) .. " (custom).|r")
        shareFrame:Hide()
        if configFrame and configFrame:IsShown() then
            WipeEditBoxes()
            BuildEditBoxes()
        end
        if OctoPawn_UpdatePlayerPaperScore then OctoPawn_UpdatePlayerPaperScore() end
    end)
end

function ToggleShareFrame()
    EnsureShareFrame()
    if shareFrame:IsShown() then
        shareFrame:Hide()
    else
        shareFrame.edit:SetText("")
        shareFrame:Show()
    end
end

-------------------------------------------------
-- Advanced soft-cap UI
-------------------------------------------------
local function EnsureAdvancedFrame()
    if advancedFrame then return end
    advancedFrame = CreateFrame("Frame", "OctoPawnAdvancedFrame", UIParent)
    advancedFrame:SetWidth(460); advancedFrame:SetHeight(420)
    advancedFrame:SetPoint("CENTER", 40, 20)
    advancedFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
    })
    advancedFrame:SetFrameStrata("DIALOG")
    advancedFrame:EnableMouse(true)
    advancedFrame:SetMovable(true)
    advancedFrame:RegisterForDrag("LeftButton")
    advancedFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    advancedFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    advancedFrame:Hide()
    local at = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    at:SetPoint("TOP", advancedFrame, "TOP", 0, -14); at:SetText("Advanced — Soft Caps")
    local close = CreateFrame("Button", nil, advancedFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    local hint = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", at, "BOTTOM", 0, -4)
    hint:SetText("Soft Cap 0 = no DR for that stat")

    local hdr1 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr1:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 24, -48)
    hdr1:SetText("Stat")
    local hdr2 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr2:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 200, -48)
    hdr2:SetText("Soft Cap")
    local hdr3 = advancedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr3:SetPoint("TOPLEFT", advancedFrame, "TOPLEFT", 300, -48)
    hdr3:SetText("Post Scale")
    advancedFrame.scroll = CreateFrame("ScrollFrame", "OctoPawnAdvScroll", advancedFrame, "UIPanelScrollFrameTemplate")
    advancedFrame.scroll:SetPoint("TOPLEFT", 16, -64)
    advancedFrame.scroll:SetPoint("BOTTOMRIGHT", -36, 50)
    advancedFrame.child = CreateFrame("Frame", nil, advancedFrame.scroll)
    advancedFrame.child:SetWidth(400); advancedFrame.child:SetHeight(2000)
    advancedFrame.scroll:SetScrollChild(advancedFrame.child)
    local save = CreateFrame("Button", nil, advancedFrame, "UIPanelButtonTemplate")
    save:SetWidth(120); save:SetHeight(26); save:SetPoint("BOTTOM", -70, 16)
    save:SetText("Save Soft Caps")
    save:SetScript("OnClick", function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.dr = {}
        local defaults = OctoPawn_GetDefaultDR and OctoPawn_GetDefaultDR() or {}
        local _, row
        for _, row in ipairs(advRows) do
            local softVal = tonumber(row.soft:GetText()) or 0
            local postVal = tonumber(row.post:GetText())
            if not postVal then postVal = 0.5 end
            if softVal > 0 then
                OctoPawnDB.dr[row.stat] = { softCap = softVal, postScale = postVal }
            elseif defaults[row.stat] then
                OctoPawnDB.dr[row.stat] = { softCap = 0, postScale = postVal }
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Soft caps saved.|r")
    end)
    local clear = CreateFrame("Button", nil, advancedFrame, "UIPanelButtonTemplate")
    clear:SetWidth(100); clear:SetHeight(26); clear:SetPoint("BOTTOM", 70, 16)
    clear:SetText("Clear All")
    clear:SetScript("OnClick", function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.dr = {}
        local _, row
        for _, row in ipairs(advRows) do row.soft:SetText("0"); row.post:SetText("0") end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Soft caps cleared.|r")
    end)
end

local function BuildAdvancedRows()
    EnsureAdvancedFrame()
    local _, row
    for _, row in ipairs(advRows) do
        if row.frame then row.frame:Hide(); row.frame:SetParent(nil) end
    end
    advRows = {}
    local weights = (OctoPawnDB and OctoPawnDB.weights) or {}
    local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
    local statsMap = {}
    for s in pairs(weights) do statsMap[s] = true end
    for s in pairs(defaults) do statsMap[s] = true end
    if not next(statsMap) and defaultWeights then
        for _, classTable in pairs(defaultWeights) do
            if type(classTable) == "table" then
                for k, v in pairs(classTable) do
                    if type(v) == "table" then
                        for s in pairs(v) do statsMap[s] = true end
                    else
                        statsMap[k] = true
                    end
                end
            end
        end
    end
    local stats = {}
    for s in pairs(statsMap) do table.insert(stats, s) end
    table.sort(stats)
    local y = -4
    local i, stat
    for i, stat in ipairs(stats) do
        local f = CreateFrame("Frame", nil, advancedFrame.child)
        f:SetWidth(380); f:SetHeight(24)
        f:SetPoint("TOPLEFT", advancedFrame.child, "TOPLEFT", 4, y)
        local lab = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("LEFT", 2, 0); lab:SetWidth(170); lab:SetJustifyH("LEFT")
        lab:SetText(StatLabel(stat))
        local soft = CreateFrame("EditBox", nil, f)
        soft:SetWidth(70); soft:SetHeight(18); soft:SetPoint("LEFT", 180, 0)
        soft:SetAutoFocus(false); soft:SetFontObject("GameFontHighlight"); soft:SetJustifyH("CENTER")
        soft:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        soft:SetBackdropColor(0.1, 0.1, 0.1, 0.9); soft:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        local post = CreateFrame("EditBox", nil, f)
        post:SetWidth(70); post:SetHeight(18); post:SetPoint("LEFT", 280, 0)
        post:SetAutoFocus(false); post:SetFontObject("GameFontHighlight"); post:SetJustifyH("CENTER")
        post:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        post:SetBackdropColor(0.1, 0.1, 0.1, 0.9); post:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        local dr = nil
        if OctoPawn_GetDR then
            dr = OctoPawn_GetDR(stat)
        end
        if OctoPawnDB and OctoPawnDB.dr and OctoPawnDB.dr[stat] and tonumber(OctoPawnDB.dr[stat].softCap) == 0 then
            soft:SetText("0")
            post:SetText(tostring(OctoPawnDB.dr[stat].postScale or 0))
        elseif dr and dr.softCap then
            soft:SetText(tostring(dr.softCap))
            post:SetText(tostring(dr.postScale or 0.5))
        else
            soft:SetText("0")
            post:SetText("0")
        end
        table.insert(advRows, { frame = f, stat = stat, soft = soft, post = post })
        y = y - 26
    end
    advancedFrame.child:SetHeight(math.max(200, -y + 20))
end

function ToggleAdvancedFrame()
    EnsureAdvancedFrame()
    if advancedFrame:IsShown() then advancedFrame:Hide()
    else BuildAdvancedRows(); advancedFrame:Show() end
end

local function WipeEditBoxes()
    for _, frame in ipairs(createdFrames) do frame:Hide(); frame:SetParent(nil) end
    createdFrames = {}; editBoxes = {}; orderedBoxes = {}
    if scrollChild then scrollChild:Hide(); scrollChild:SetParent(nil) end
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(250); scrollChild:SetHeight(1600)
    scrollFrame:SetScrollChild(scrollChild)
end
function OctoPawn_WipeConfigUI()
    WipeEditBoxes()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

local function SaveWeights()
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.weights then OctoPawnDB.weights = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    local role = OctoPawnDB.role
    if not role then
        for stat, box in pairs(editBoxes) do OctoPawnDB.weights[stat] = tonumber(box:GetText()) or 1.0 end
        return
    end
    OctoPawnDB.customWeights[role] = {}
    for stat, box in pairs(editBoxes) do
        local val = tonumber(box:GetText()) or 1.0
        OctoPawnDB.weights[stat] = val
        OctoPawnDB.customWeights[role][stat] = val
    end
    OctoPawnDB.useCustom = true
end

function BuildEditBoxes()
    local playerClass = OctoPawn_GetClass and OctoPawn_GetClass() or "?"
    local role = (OctoPawnDB and OctoPawnDB.role) or "Default"
    local suffix = (OctoPawnDB and OctoPawnDB.useCustom) and " (custom)" or ""
    title:SetText("OctoPawn - " .. playerClass .. " (" .. role .. suffix .. ")")
    if next(editBoxes) ~= nil then
        local saved = (OctoPawnDB and OctoPawnDB.weights) or {}
        local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
        for stat, box in pairs(editBoxes) do
            local value = saved[stat]; if value == nil then value = defaults[stat] or 1.0 end
            box:SetText(tostring(value))
            if box.opLabel then box.opLabel:SetText(StatLabel(stat)) end
        end
        UpdateCompareButtonText()
        SyncAllSpecsCheck()
        SyncCompactCheck()
        return
    end
    local saved = (OctoPawnDB and OctoPawnDB.weights) or {}
    local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
    local allStats = {}
    for stat in pairs(defaults) do allStats[stat] = true end
    for stat in pairs(saved) do allStats[stat] = true end
    local sortedStats = {}
    for stat in pairs(allStats) do table.insert(sortedStats, stat) end
    table.sort(sortedStats, function(a, b)
        local va = saved[a]; if va == nil then va = defaults[a] or 0 end
        local vb = saved[b]; if vb == nil then vb = defaults[b] or 0 end
        if va ~= vb then return va > vb end
        return a < b
    end)
    local y = -10
    for _, stat in ipairs(sortedStats) do
        local value = saved[stat]; if value == nil then value = defaults[stat] or 1.0 end
        local box = CreateFrame("EditBox", nil, scrollChild)
        box:SetWidth(70); box:SetHeight(20); box:SetAutoFocus(false)
        box:SetFontObject("GameFontHighlight"); box:SetText(tostring(value)); box:SetJustifyH("CENTER")
        box:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12 })
        box:SetBackdropColor(0.1, 0.1, 0.1, 0.9); box:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        box:SetScript("OnTextChanged", function()
            local text = this:GetText() or ""
            local clean = string.gsub(text, "[^0-9%.%-]", "")
            if clean ~= text then this:SetText(clean) end
        end)
        local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", box, "RIGHT", 12, 0)
        label:SetText(StatLabel(stat))
        box.opLabel = label
        editBoxes[stat] = box
        table.insert(orderedBoxes, box)
        table.insert(createdFrames, box); table.insert(createdFrames, label)
        y = y - 28
    end
    local function FocusNextBox(current)
        current:HighlightText(0, 0)
        for i, box in ipairs(orderedBoxes) do
            if box == current then
                local nextIndex = i + 1
                if nextIndex > table.getn(orderedBoxes) then nextIndex = 1 end
                local nextBox = orderedBoxes[nextIndex]
                nextBox:SetFocus(); nextBox:HighlightText()
                local _, _, _, _, yOfs = nextBox:GetPoint()
                local targetScroll = -(yOfs or 0) - 10
                if targetScroll < 0 then targetScroll = 0 end
                local maxScroll = scrollFrame:GetVerticalScrollRange()
                if targetScroll > maxScroll then targetScroll = maxScroll end
                scrollFrame:SetVerticalScroll(targetScroll)
                return
            end
        end
    end
    for _, box in ipairs(orderedBoxes) do
        box:SetScript("OnTabPressed", function() FocusNextBox(this) end)
        box:SetScript("OnEnterPressed", function() FocusNextBox(this) end)
    end
    UpdateCompareButtonText()
    SyncAllSpecsCheck()
    SyncCompactCheck()
end

local saveBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
saveBtn:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 20)
saveBtn:SetWidth(120); saveBtn:SetHeight(28); saveBtn:SetText("Save Weights")
saveBtn:SetScript("OnClick", function()
    SaveWeights(); WipeEditBoxes(); BuildEditBoxes(); scrollFrame:SetVerticalScroll(0)
    local role = (OctoPawnDB and OctoPawnDB.role) or "current"
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Saved as " .. role .. " (custom).|r")
end)
configFrame:SetScript("OnHide", function() SaveWeights() end)

function ToggleConfigFrame()
    if configFrame:IsShown() then configFrame:Hide()
    else BuildEditBoxes(); UpdateCompareButtonText(); SyncAllSpecsCheck(); SyncCompactCheck(); configFrame:Show() end
end

function OctoPawn_ShowRolePicker()
    if not rolePickerFrame then
        rolePickerFrame = CreateFrame("Frame", "OctoPawnRolePicker", UIParent)
        rolePickerFrame:SetWidth(360)
        rolePickerFrame:SetHeight(360)
        rolePickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        rolePickerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        rolePickerFrame:SetFrameStrata("DIALOG")
        rolePickerFrame:EnableMouse(true)
        rolePickerFrame:SetMovable(true)
        rolePickerFrame:RegisterForDrag("LeftButton")
        rolePickerFrame:SetScript("OnDragStart", function() this:StartMoving() end)
        rolePickerFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        local pickerTitle = rolePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        pickerTitle:SetPoint("TOP", rolePickerFrame, "TOP", 0, -14)
        pickerTitle:SetText("Choose Role")
        rolePickerFrame.title = pickerTitle
        local hint = rolePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOP", pickerTitle, "BOTTOM", 0, -4)
        hint:SetTextColor(0.7, 0.7, 0.7)
        hint:SetText("Tip = show this spec on item tooltips")
        rolePickerFrame.hint = hint
        rolePickerFrame.buttons = {}
    end

    if rolePickerFrame.buttons then
        local bi
        for bi = 1, table.getn(rolePickerFrame.buttons) do
            local b = rolePickerFrame.buttons[bi]
            if b then b:Hide(); b:SetParent(nil) end
        end
    end
    rolePickerFrame.buttons = {}

    local class = nil
    if OctoPawn_GetClass then class = OctoPawn_GetClass() end
    if not class then
        local _, c = UnitClass("player")
        class = c or "WARRIOR"
    end

    local roles = {}
    if OctoPawn_GetRolesForClass then
        local ok, result = pcall(OctoPawn_GetRolesForClass, class)
        if ok and type(result) == "table" then roles = result end
    end
    if table.getn(roles) == 0 and defaultWeights and defaultWeights[class] then
        for r, v in pairs(defaultWeights[class]) do
            if type(v) == "table" then table.insert(roles, r) end
        end
        table.sort(roles)
    end
    if table.getn(roles) == 0 then
        table.insert(roles, "Default")
    end

    rolePickerFrame.title:SetText("OctoPawn - " .. tostring(class))

    local y = -50
    local buttonCount = 0
    local ri

    local function Track(frame)
        table.insert(rolePickerFrame.buttons, frame)
    end

    local function SelectRole(roleName, isCustom)
        if OctoPawn_ApplyRole then OctoPawn_ApplyRole(roleName, isCustom) end
        rolePickerFrame:Hide()
        WipeEditBoxes()
        if configFrame and configFrame:IsShown() then BuildEditBoxes() end
    end

    for ri = 1, table.getn(roles) do
        local role = roles[ri]
        local isBuiltIn = OctoPawn_IsBuiltInRole and OctoPawn_IsBuiltInRole(class, role)
        local hasCustom = OctoPawn_HasCustomWeights and OctoPawn_HasCustomWeights(role)
        local isPureCustom = hasCustom and not isBuiltIn

        local btn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
        btn:SetWidth(isPureCustom and 160 or 180)
        btn:SetHeight(26)
        btn:SetPoint("TOPLEFT", rolePickerFrame, "TOPLEFT", 24, y)
        btn:SetText(role)
        btn.roleName = role
        btn:SetScript("OnClick", function()
            SelectRole(this.roleName, isPureCustom and true or false)
        end)
        Track(btn)

        local tip = CreateFrame("CheckButton", nil, rolePickerFrame, "UICheckButtonTemplate")
        tip:SetWidth(24); tip:SetHeight(24)
        tip:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        tip.roleName = role
        if OctoPawn_IsTipSpec and OctoPawn_IsTipSpec(role) then tip:SetChecked(1) else tip:SetChecked(0) end
        tip:SetScript("OnClick", function()
            if OctoPawn_SetTipSpec then
                OctoPawn_SetTipSpec(this.roleName, this:GetChecked() and true or false)
            end
        end)
        tip:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Show on tip", 1, 1, 1)
            GameTooltip:AddLine("Include this spec on item tooltips", 0.7, 0.7, 0.7, 1)
            GameTooltip:Show()
        end)
        tip:SetScript("OnLeave", function() GameTooltip:Hide() end)
        Track(tip)

        local tipLbl = rolePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tipLbl:SetPoint("LEFT", tip, "RIGHT", 0, 0)
        tipLbl:SetText("Tip")
        Track(tipLbl)

        if hasCustom then
            local del = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
            del:SetWidth(28); del:SetHeight(24)
            del:SetPoint("LEFT", tipLbl, "RIGHT", 8, 0)
            del:SetText("X")
            del.roleName = role
            del:SetScript("OnClick", function()
                local ok, err = OctoPawn_DeleteCustomSpec and OctoPawn_DeleteCustomSpec(this.roleName)
                if ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Deleted custom '" .. tostring(this.roleName) .. "'.|r")
                    OctoPawn_ShowRolePicker()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: " .. tostring(err or "delete failed") .. "|r")
                end
            end)
            del:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete custom", 1, 0.3, 0.3)
                if isBuiltIn then
                    GameTooltip:AddLine("Removes saved custom weights for this role", 0.7, 0.7, 0.7, 1)
                else
                    GameTooltip:AddLine("Deletes this custom profile entirely", 0.7, 0.7, 0.7, 1)
                end
                GameTooltip:Show()
            end)
            del:SetScript("OnLeave", function() GameTooltip:Hide() end)
            Track(del)

            if isPureCustom then
                local ren = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
                ren:SetWidth(40); ren:SetHeight(24)
                ren:SetPoint("LEFT", del, "RIGHT", 2, 0)
                ren:SetText("Ren")
                ren.roleName = role
                ren:SetScript("OnClick", function()
                    if rolePickerFrame.renameBox then
                        rolePickerFrame.renameBox:Show()
                        rolePickerFrame.renameBox:SetText(this.roleName)
                        rolePickerFrame.renameBox.oldName = this.roleName
                        rolePickerFrame.renameBox:SetFocus()
                    end
                end)
                Track(ren)
            end
        end

        y = y - 30
        buttonCount = buttonCount + 1

        if isBuiltIn and hasCustom then
            local cbtn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
            cbtn:SetWidth(180)
            cbtn:SetHeight(26)
            cbtn:SetPoint("TOPLEFT", rolePickerFrame, "TOPLEFT", 24, y)
            cbtn:SetText(role .. " (custom)")
            cbtn.roleName = role
            cbtn:SetScript("OnClick", function()
                SelectRole(this.roleName, true)
            end)
            Track(cbtn)
            y = y - 30
            buttonCount = buttonCount + 1
        end
    end

    y = y - 6
    local newLbl = rolePickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newLbl:SetPoint("TOPLEFT", rolePickerFrame, "TOPLEFT", 28, y)
    newLbl:SetText("New profile:")
    Track(newLbl)

    local newBox = CreateFrame("EditBox", "OctoPawnNewSpecBox", rolePickerFrame)
    newBox:SetWidth(120); newBox:SetHeight(22)
    newBox:SetPoint("LEFT", newLbl, "RIGHT", 6, 0)
    newBox:SetAutoFocus(false)
    newBox:SetFontObject(GameFontHighlight)
    newBox:SetText("")
    if newBox.SetBackdrop then
        newBox:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        newBox:SetBackdropColor(0, 0, 0, 0.8)
    end
    Track(newBox)

    local newBtn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
    newBtn:SetWidth(50); newBtn:SetHeight(24)
    newBtn:SetPoint("LEFT", newBox, "RIGHT", 4, 0)
    newBtn:SetText("Add")
    newBtn:SetScript("OnClick", function()
        local name = newBox:GetText() or ""
        local ok, err = OctoPawn_CreateCustomSpec and OctoPawn_CreateCustomSpec(name)
        if ok then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Created profile '" .. name .. "'.|r")
            newBox:SetText("")
            OctoPawn_ShowRolePicker()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: " .. tostring(err or "create failed") .. "|r")
        end
    end)
    Track(newBtn)
    y = y - 28

    if not rolePickerFrame.renameBox then
        local rb = CreateFrame("EditBox", "OctoPawnRenameSpecBox", rolePickerFrame)
        rb:SetWidth(140); rb:SetHeight(22)
        rb:SetPoint("BOTTOM", rolePickerFrame, "BOTTOM", -30, 36)
        rb:SetAutoFocus(false)
        rb:SetFontObject(GameFontHighlight)
        rb:Hide()
        if rb.SetBackdrop then
            rb:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            rb:SetBackdropColor(0, 0, 0, 0.9)
        end
        rolePickerFrame.renameBox = rb
        local rok = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
        rok:SetWidth(50); rok:SetHeight(24)
        rok:SetPoint("LEFT", rb, "RIGHT", 4, 0)
        rok:SetText("OK")
        rok:SetScript("OnClick", function()
            local old = rb.oldName
            local newn = rb:GetText() or ""
            local ok, err = OctoPawn_RenameCustomSpec and OctoPawn_RenameCustomSpec(old, newn)
            if ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Renamed to '" .. newn .. "'.|r")
                rb:Hide(); rok:Hide()
                OctoPawn_ShowRolePicker()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: " .. tostring(err or "rename failed") .. "|r")
            end
        end)
        rok:Hide()
        rolePickerFrame.renameOk = rok
        rb:SetScript("OnShow", function() if rolePickerFrame.renameOk then rolePickerFrame.renameOk:Show() end end)
        rb:SetScript("OnHide", function() if rolePickerFrame.renameOk then rolePickerFrame.renameOk:Hide() end end)
    else
        rolePickerFrame.renameBox:Hide()
        if rolePickerFrame.renameOk then rolePickerFrame.renameOk:Hide() end
    end

    local closeBtn = CreateFrame("Button", nil, rolePickerFrame, "UIPanelButtonTemplate")
    closeBtn:SetWidth(80); closeBtn:SetHeight(24)
    closeBtn:SetPoint("BOTTOM", rolePickerFrame, "BOTTOM", 0, 12)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() rolePickerFrame:Hide() end)
    Track(closeBtn)

    local height = 100 + (buttonCount * 30) + 60
    if height < 200 then height = 200 end
    if height > 520 then height = 520 end
    rolePickerFrame:SetHeight(height)
    rolePickerFrame:Show()
end

function OctoPawn_OnDBReady() end
print("|cFF00FF00OctoPawn|r UI loaded")
