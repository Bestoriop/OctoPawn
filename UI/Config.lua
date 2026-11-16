-------------------------------------------------
-- OctoPawn UI/Config.lua
-------------------------------------------------
local function StatLabel(stat)
    if OctoPawn_StatLabel then return OctoPawn_StatLabel(stat) end
    local map = {
        DPS = "WEAPON DPS", CRIT = "CRIT %", HIT = "HIT %",
        DODGE = "DODGE %", PARRY = "PARRY %", BLOCK = "BLOCK %", HASTE = "HASTE %",
        ["SPELL CRIT"] = "SPELL CRIT %", ["SPELL HIT"] = "SPELL HIT %",
        ["RANGED CRIT"] = "RANGED CRIT %", ["RANGED HASTE"] = "RANGED HASTE %",
        ["HOLY CRIT"] = "HOLY CRIT %", AVOIDANCE = "AVOIDANCE %", RESILIENCE = "RESILIENCE %",
        ["EXTRA ATTACK"] = "EXTRA ATTACK %",
        LIFESTEAL = "LIFESTEAL %", THORNS = "REFLECT DMG", ["CASTING REGEN"] = "CASTING MANA REG %", ["COMBAT HEALTH REG"] = "COMBAT HEALTH REG %",
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
        GameTooltip:AddLine("Profile: " .. role, 0.8, 0.8, 0.8)
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

-------------------------------------------------
-- Fenêtre principale (une seule fenêtre à onglets)
-------------------------------------------------
local editBoxes = {}      -- [stat] = poids
local capBoxes = {}       -- [stat] = cap
local postBoxes = {}      -- [stat] = valeur après cap
local statLabels = {}     -- [stat] = FontString
local orderedBoxes = {}
local createdFrames = {}
local editBaseline = {}   -- poids affichés au dernier BuildEditBoxes
local capBaseline = {}    -- [stat] = { cap, post }
local configFrame, scrollFrame, scrollChild, title
local weightsTab, optionsTab, shareTab
local UpdateWeightsTitle
local tabButtons = {}
local copyBtn, copyDD, listTab
local weightsTitle, building
local listItems = {}
local hdrCap, hdrPost, capHint
local showCapsCheck
local BuildEditBoxes, WipeEditBoxes, SaveWeights, ShowTab, WeightsChanged

local COL_WEIGHT_X, COL_LABEL_X, COL_CAP_X, COL_POST_X = 10, 84, 262, 324

local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
}
local BOXBACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
}

local function Msg(text) DEFAULT_CHAT_FRAME:AddMessage(text) end

local function ShowCapsOn()
    return OctoPawnDB and OctoPawnDB.showCaps and true or false
end

local function FmtNum(v)
    if v == nil then return "0" end
    return tostring(v)
end

configFrame = CreateFrame("Frame", "OctoPawnConfigFrame", UIParent)
configFrame:SetWidth(480); configFrame:SetHeight(540)
configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
configFrame:SetBackdrop(BACKDROP)
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

-- Onglets
local function MakeTabButton(label, key, x, w)
    local b = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    b:SetWidth(w); b:SetHeight(24)
    b:SetPoint("TOPLEFT", configFrame, "TOPLEFT", x, -50)
    b:SetText(label)
    b.tabKey = key
    b:SetScript("OnClick", function() ShowTab(this.tabKey) end)
    tabButtons[key] = b
    return b
end
MakeTabButton("List of profiles", "list", 24, 108)
MakeTabButton("Weights", "weights", 136, 76)
MakeTabButton("Options", "options", 216, 76)
MakeTabButton("Share", "share", 296, 64)

local function MakeTabFrame()
    local f = CreateFrame("Frame", nil, configFrame)
    f:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 16, -80)
    f:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -16, 16)
    f:Hide()
    return f
end
weightsTab = MakeTabFrame()
optionsTab = MakeTabFrame()
shareTab = MakeTabFrame()
listTab = MakeTabFrame()

function ShowTab(key)
    if copyDD and CloseDropDownMenus then CloseDropDownMenus() end
    weightsTab:Hide(); optionsTab:Hide(); shareTab:Hide(); listTab:Hide()
    if key == "list" then
        OctoPawn_BuildProfileList()
        listTab:Show()
    elseif key == "options" then optionsTab:Show()
    elseif key == "share" then shareTab:Show()
    else key = "weights"; weightsTab:Show() end
    local k, b
    for k, b in pairs(tabButtons) do
        if k == key then b:Disable() else b:Enable() end
    end
    configFrame.currentTab = key
end

-------------------------------------------------
-- Onglet Weights
-------------------------------------------------
weightsTitle = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weightsTitle:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", 4, -4)
weightsTitle:SetWidth(270); weightsTitle:SetJustifyH("LEFT")
weightsTitle:SetText("Weights")

local HDR_Y = -26
local hdrWeight = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrWeight:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", COL_WEIGHT_X, HDR_Y)
hdrWeight:SetWidth(62); hdrWeight:SetJustifyH("CENTER"); hdrWeight:SetText("Weight")
local hdrStat = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrStat:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", COL_LABEL_X, HDR_Y)
hdrStat:SetText("Stat")
hdrCap = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrCap:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", COL_CAP_X, HDR_Y)
hdrCap:SetWidth(54); hdrCap:SetJustifyH("CENTER"); hdrCap:SetText("Cap")
hdrPost = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hdrPost:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", COL_POST_X, HDR_Y)
hdrPost:SetWidth(54); hdrPost:SetJustifyH("CENTER"); hdrPost:SetText("After cap")

showCapsCheck = CreateFrame("CheckButton", "OctoPawnShowCapsCheck", weightsTab, "UICheckButtonTemplate")
showCapsCheck:SetWidth(22); showCapsCheck:SetHeight(22)
showCapsCheck:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", 352, 1)
local showCapsLbl = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
showCapsLbl:SetPoint("RIGHT", showCapsCheck, "LEFT", -2, 0)
showCapsLbl:SetText("Show caps")

capHint = weightsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
capHint:SetPoint("BOTTOMLEFT", weightsTab, "BOTTOMLEFT", 4, 40)
capHint:SetWidth(430); capHint:SetJustifyH("LEFT")
capHint:SetTextColor(0.7, 0.7, 0.7)
capHint:SetText("Cap = max total on your gear (0 = none). After cap = value per point above it.")

scrollFrame = CreateFrame("ScrollFrame", "OctoPawnScrollFrame", weightsTab, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", weightsTab, "TOPLEFT", 0, -42)
scrollFrame:SetPoint("BOTTOMRIGHT", weightsTab, "BOTTOMRIGHT", -24, 56)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
    local current = this:GetVerticalScroll()
    local maxScroll = this:GetVerticalScrollRange()
    local step = 28
    local newPos
    if arg1 > 0 then newPos = current - step else newPos = current + step end
    if newPos < 0 then newPos = 0 end
    if newPos > maxScroll then newPos = maxScroll end
    this:SetVerticalScroll(newPos)
end)
scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(390); scrollChild:SetHeight(1600)
scrollFrame:SetScrollChild(scrollChild)

local function ApplyCapsVisibility()
    local on = ShowCapsOn()
    local stat
    for stat in pairs(capBoxes) do
        if on then capBoxes[stat]:Show(); postBoxes[stat]:Show()
        else capBoxes[stat]:Hide(); postBoxes[stat]:Hide() end
    end
    if on then hdrCap:Show(); hdrPost:Show(); capHint:Show()
    else hdrCap:Hide(); hdrPost:Hide(); capHint:Hide() end
    if on then showCapsCheck:SetChecked(1) else showCapsCheck:SetChecked(0) end
end

-- Libellé de la stat ; caps masqués : rappel vert "(cap N)" si un cap est défini
local function RefreshCapLabel(stat)
    local lab = statLabels[stat]
    if not lab then return end
    local text = StatLabel(stat)
    if not ShowCapsOn() and capBoxes[stat] then
        local c = tonumber(capBoxes[stat]:GetText()) or 0
        if c > 0 then text = text .. " |cff40ff40(cap " .. capBoxes[stat]:GetText() .. ")|r" end
    end
    lab:SetText(text)
end
local function RefreshAllCapLabels()
    local stat
    for stat in pairs(statLabels) do RefreshCapLabel(stat) end
end

showCapsCheck:SetScript("OnClick", function()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.showCaps = this:GetChecked() and true or false
    ApplyCapsVisibility()
    RefreshAllCapLabels()
end)

function UpdateWeightsTitle()
    if building or not weightsTitle then return end
    local role = (OctoPawnDB and OctoPawnDB.role) or "Default"
    local suffix = (OctoPawnDB and OctoPawnDB.useCustom) and " (custom)" or ""
    local star = ""
    if next(editBoxes) ~= nil and WeightsChanged() then star = " |cffff9900*|r" end
    weightsTitle:SetText(role .. suffix .. " - Weights" .. star)
end

function WipeEditBoxes()
    local _, f
    for _, f in ipairs(createdFrames) do f:Hide(); f:SetParent(nil) end
    createdFrames = {}; editBoxes = {}; capBoxes = {}; postBoxes = {}; statLabels = {}; orderedBoxes = {}
    if scrollChild then scrollChild:Hide(); scrollChild:SetParent(nil) end
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(390); scrollChild:SetHeight(1600)
    scrollFrame:SetScrollChild(scrollChild)
end

function OctoPawn_WipeConfigUI()
    WipeEditBoxes()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

local function ReadNumBox(box)
    local val = tonumber(box:GetText())
    if val == nil then
        val = 0
        box:SetText("0")
    end
    return val
end

function WeightsChanged()
    local stat, box
    for stat, box in pairs(editBoxes) do
        local val = tonumber(box:GetText()) or 0
        local base = editBaseline[stat]
        if base == nil or math.abs(val - base) > 0.000001 then return true end
    end
    for stat, box in pairs(capBoxes) do
        local cb = capBaseline[stat] or { 0, 0 }
        local c = tonumber(box:GetText()) or 0
        local p = tonumber(postBoxes[stat]:GetText()) or 0
        if math.abs(c - cb[1]) > 0.000001 or math.abs(p - cb[2]) > 0.000001 then return true end
    end
    return false
end

-- Enregistre poids + caps dans le profil actif (bouton Save Weights uniquement)
function SaveWeights()
    if not OctoPawnDB then OctoPawnDB = {} end
    if not OctoPawnDB.weights then OctoPawnDB.weights = {} end
    if not OctoPawnDB.customWeights then OctoPawnDB.customWeights = {} end
    if type(OctoPawnDB.caps) ~= "table" then OctoPawnDB.caps = {} end
    local role = OctoPawnDB.role
    local stat, box
    if not role then
        for stat, box in pairs(editBoxes) do OctoPawnDB.weights[stat] = ReadNumBox(box) end
        return
    end
    OctoPawnDB.customWeights[role] = {}
    for stat, box in pairs(editBoxes) do
        local val = ReadNumBox(box)
        OctoPawnDB.weights[stat] = val
        OctoPawnDB.customWeights[role][stat] = val
    end
    local newCaps = {}
    for stat, box in pairs(capBoxes) do
        local c = ReadNumBox(box)
        local p = ReadNumBox(postBoxes[stat])
        if c > 0 then newCaps[stat] = { softCap = c, postValue = p } end
    end
    if next(newCaps) then OctoPawnDB.caps[role] = newCaps else OctoPawnDB.caps[role] = nil end
    OctoPawnDB.useCustom = true
end

local function MakeNumBox(parent, x, y, width)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetWidth(width); box:SetHeight(20); box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlight"); box:SetJustifyH("CENTER")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetBackdrop(BOXBACKDROP)
    box:SetBackdropColor(0.1, 0.1, 0.1, 0.9); box:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
    box:SetScript("OnTextChanged", function()
        local text = this:GetText() or ""
        local clean = string.gsub(text, "[^0-9%.%-]", "")
        if clean ~= text then this:SetText(clean) end
        UpdateWeightsTitle()
    end)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    table.insert(createdFrames, box)
    return box
end

local function ScrollToBox(box)
    local y = box.opY or 0
    local target = -y - 10
    if target < 0 then target = 0 end
    local maxScroll = scrollFrame:GetVerticalScrollRange()
    if target > maxScroll then target = maxScroll end
    scrollFrame:SetVerticalScroll(target)
end

local function FocusBox(box)
    box:SetFocus(); box:HighlightText()
    ScrollToBox(box)
end

local function BuildImpl()
    local playerClass = OctoPawn_GetClass and OctoPawn_GetClass() or "?"
    local role = (OctoPawnDB and OctoPawnDB.role) or "Default"
    local suffix = (OctoPawnDB and OctoPawnDB.useCustom) and " (custom)" or ""
    title:SetText("OctoPawn - " .. tostring(playerClass))
    local saved = (OctoPawnDB and OctoPawnDB.weights) or {}
    local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
    local roleCaps = OctoPawn_GetCapsForRole and OctoPawn_GetCapsForRole(OctoPawnDB and OctoPawnDB.role) or {}
    local allStats = {}
    local stat
    for stat in pairs(defaults) do allStats[stat] = true end
    for stat in pairs(saved) do allStats[stat] = true end
    allStats["ARMOR BONUS"] = true
    local vals = {}
    for stat in pairs(allStats) do
        local v = saved[stat]
        if v == nil then v = defaults[stat] end
        if v == nil and stat == "ARMOR BONUS" then
            v = saved["ARMOR"]
            if v == nil then v = defaults["ARMOR"] end
        end
        if v == nil then v = 1.0 end
        vals[stat] = v
    end
    editBaseline = vals
    capBaseline = {}
    for stat in pairs(allStats) do
        local c = roleCaps[stat]
        if c and tonumber(c.softCap) and tonumber(c.softCap) > 0 then
            capBaseline[stat] = { tonumber(c.softCap), tonumber(c.postValue) or 0 }
        else
            capBaseline[stat] = { 0, 0 }
        end
    end
    if next(editBoxes) ~= nil then
        for stat, box in pairs(editBoxes) do
            local value = vals[stat]; if value == nil then value = 1.0 end
            box:SetText(tostring(value))
            local cb = capBaseline[stat] or { 0, 0 }
            capBoxes[stat]:SetText(FmtNum(cb[1])); postBoxes[stat]:SetText(FmtNum(cb[2]))
        end
        ApplyCapsVisibility(); RefreshAllCapLabels()
        if OctoPawn_RefreshCompareButton then OctoPawn_RefreshCompareButton() end
        return
    end
    local sortedStats = {}
    for stat in pairs(allStats) do table.insert(sortedStats, stat) end
    table.sort(sortedStats, function(a, b)
        local va, vb = vals[a], vals[b]
        if va ~= vb then return va > vb end
        local la, lb = StatLabel(a), StatLabel(b)
        if la ~= lb then return la < lb end
        return a < b
    end)
    local y = -6
    local _
    for _, stat in ipairs(sortedStats) do
        local wbox = MakeNumBox(scrollChild, COL_WEIGHT_X, y, 62)
        wbox:SetText(tostring(vals[stat]))
        wbox.opY = y; wbox.opStat = stat
        local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", COL_LABEL_X, y - 3)
        label:SetWidth(172); label:SetJustifyH("LEFT")
        label:SetText(StatLabel(stat))
        statLabels[stat] = label
        local cb = capBaseline[stat]
        local cbox = MakeNumBox(scrollChild, COL_CAP_X, y, 54)
        cbox:SetText(FmtNum(cb[1])); cbox.opY = y
        local pbox = MakeNumBox(scrollChild, COL_POST_X, y, 54)
        pbox:SetText(FmtNum(cb[2])); pbox.opY = y
        cbox.opStat = stat
        cbox:SetScript("OnTextChanged", function()
            local text = this:GetText() or ""
            local clean = string.gsub(text, "[^0-9%.%-]", "")
            if clean ~= text then this:SetText(clean) return end
            RefreshCapLabel(this.opStat)
            UpdateWeightsTitle()
        end)
        editBoxes[stat] = wbox; capBoxes[stat] = cbox; postBoxes[stat] = pbox
        wbox.opCap = cbox; cbox.opPost = pbox; pbox.opRowCap = cbox
        table.insert(orderedBoxes, wbox)
        table.insert(createdFrames, label)
        y = y - 28
    end
    scrollChild:SetHeight(-y + 10)
    -- Navigation Tab / Entrée : poids -> poids suivant ; cap -> after cap -> cap suivant
    local n = table.getn(orderedBoxes)
    local i
    for i = 1, n do
        local wbox = orderedBoxes[i]
        local nextW = orderedBoxes[i + 1] or orderedBoxes[1]
        local nextRowCap = capBoxes[nextW.opStat]
        wbox.opNext = nextW
        wbox.opNextCap = nextRowCap
        local function goNext()
            this:HighlightText(0, 0)
            FocusBox(this.opNext)
        end
        wbox:SetScript("OnTabPressed", goNext)
        wbox:SetScript("OnEnterPressed", goNext)
        local cbox = wbox.opCap
        cbox.opNextCap = nextRowCap
        cbox:SetScript("OnTabPressed", function() this:HighlightText(0, 0); FocusBox(this.opPost) end)
        cbox:SetScript("OnEnterPressed", function() this:HighlightText(0, 0); FocusBox(this.opPost) end)
        local pbox = cbox.opPost
        pbox:SetScript("OnTabPressed", function() this:HighlightText(0, 0); FocusBox(this.opRowCap.opNextCap) end)
        pbox:SetScript("OnEnterPressed", function() this:HighlightText(0, 0); FocusBox(this.opRowCap.opNextCap) end)
    end
    ApplyCapsVisibility(); RefreshAllCapLabels()
    if OctoPawn_RefreshCompareButton then OctoPawn_RefreshCompareButton() end
end

function BuildEditBoxes()
    building = true
    BuildImpl()
    building = false
    UpdateWeightsTitle()
end

local saveBtn = CreateFrame("Button", nil, weightsTab, "UIPanelButtonTemplate")
saveBtn:SetPoint("BOTTOMRIGHT", weightsTab, "BOTTOMRIGHT", -8, 4)
saveBtn:SetWidth(130); saveBtn:SetHeight(28); saveBtn:SetText("Save Weights")
saveBtn:SetScript("OnClick", function()
    SaveWeights(); WipeEditBoxes(); BuildEditBoxes(); scrollFrame:SetVerticalScroll(0)
    local role = (OctoPawnDB and OctoPawnDB.role) or "current"
    Msg("|cFF00FF00OctoPawn: Saved as " .. role .. " (custom).|r")
    if OctoPawn_UpdatePlayerPaperScore then OctoPawn_UpdatePlayerPaperScore() end
end)

local clearBtn = CreateFrame("Button", nil, weightsTab, "UIPanelButtonTemplate")
clearBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
clearBtn:SetWidth(130); clearBtn:SetHeight(28); clearBtn:SetText("Clear Weights")
clearBtn:SetScript("OnClick", function()
    local stat, box
    for stat, box in pairs(editBoxes) do box:SetText("0") end
    Msg("|cFFFF9900OctoPawn: All weights set to 0 - click Save Weights to apply (pick a profile again to reload its weights).|r")
end)

copyBtn = CreateFrame("Button", nil, weightsTab, "UIPanelButtonTemplate")
copyBtn:SetPoint("RIGHT", clearBtn, "LEFT", -8, 0)
copyBtn:SetWidth(130); copyBtn:SetHeight(28); copyBtn:SetText("Copy from...")

-- Fermer la fenêtre n'enregistre rien
configFrame:SetScript("OnHide", function()
    if CloseDropDownMenus then CloseDropDownMenus() end
    if next(editBoxes) ~= nil and WeightsChanged() then
        Msg("|cFFFF9900OctoPawn: Unsaved changes discarded.|r")
    end
end)

function ToggleConfigFrame()
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        WipeEditBoxes(); BuildEditBoxes()
        ShowTab("weights")
        configFrame:Show()
    end
end

local function OpenConfig(tab)
    if not configFrame:IsShown() then
        WipeEditBoxes(); BuildEditBoxes()
        configFrame:Show()
    end
    ShowTab(tab or configFrame.currentTab or "weights")
end

-------------------------------------------------
-- Onglet Options
-------------------------------------------------
local function MakeOption(name, y, label, desc, onClick)
    local cb = CreateFrame("CheckButton", name, optionsTab, "UICheckButtonTemplate")
    cb:SetWidth(24); cb:SetHeight(24)
    cb:SetPoint("TOPLEFT", optionsTab, "TOPLEFT", 8, y)
    cb:SetScript("OnClick", onClick)
    local l = optionsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    l:SetText(label)
    local d = optionsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    d:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, 2)
    d:SetWidth(400); d:SetJustifyH("LEFT"); d:SetTextColor(0.7, 0.7, 0.7)
    d:SetText(desc)
    return cb
end

local compareCheck = MakeOption("OctoPawnCompareCheck", -10, "Show upgrade +/-",
    "Compare an item with the gear you wear and show the score difference on tooltips.",
    function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.compareEnabled = this:GetChecked() and true or false
    end)
local compactCheck = MakeOption("OctoPawnCompactCheck", -70, "Compact tooltips",
    "With Show upgrade +/-: one line (OP Score: 42.3 (+1.2) (-0.3)), no slot names.",
    function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.compactTooltips = this:GetChecked() and true or false
    end)
local ignoreEnchantsCheck = MakeOption("OctoPawnIgnoreEnchantsCheck", -130, "Ignore enchants",
    "Do not count enchant bonuses when scoring items and totals.",
    function()
        if not OctoPawnDB then OctoPawnDB = {} end
        OctoPawnDB.ignoreEnchants = this:GetChecked() and true or false
    end)

local function SyncCompareCheck()
    if OctoPawnDB and OctoPawnDB.compareEnabled == false then compareCheck:SetChecked(0) else compareCheck:SetChecked(1) end
end
local function SyncCompactCheck()
    if OctoPawnDB and OctoPawnDB.compactTooltips then compactCheck:SetChecked(1) else compactCheck:SetChecked(0) end
end
local function SyncIgnoreEnchantsCheck()
    if OctoPawnDB and OctoPawnDB.ignoreEnchants then ignoreEnchantsCheck:SetChecked(1) else ignoreEnchantsCheck:SetChecked(0) end
end
compareCheck:SetScript("OnShow", SyncCompareCheck)
compactCheck:SetScript("OnShow", SyncCompactCheck)
ignoreEnchantsCheck:SetScript("OnShow", SyncIgnoreEnchantsCheck)
function OctoPawn_RefreshCompareButton() SyncCompareCheck() end

-------------------------------------------------
-- Onglet Share
-------------------------------------------------
local shareHint = shareTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
shareHint:SetPoint("TOPLEFT", shareTab, "TOPLEFT", 4, -4)
shareHint:SetWidth(430); shareHint:SetJustifyH("LEFT")
shareHint:SetText("Sparse export - only stats that differ from the profile defaults (caps are not included).")

local shareBox = CreateFrame("EditBox", "OctoPawnShareEditBox", shareTab)
shareBox:SetPoint("TOPLEFT", shareTab, "TOPLEFT", 4, -26)
shareBox:SetPoint("BOTTOMRIGHT", shareTab, "BOTTOMRIGHT", -4, 50)
shareBox:SetMultiLine(true)
shareBox:SetAutoFocus(false)
shareBox:SetFontObject("GameFontHighlightSmall")
shareBox:SetMaxLetters(2500)
shareBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
shareBox:SetBackdropColor(0, 0, 0, 0.8)
shareBox:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
shareBox:SetTextInsets(6, 6, 6, 6)
shareBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)

local exportBtn = CreateFrame("Button", nil, shareTab, "UIPanelButtonTemplate")
exportBtn:SetWidth(110); exportBtn:SetHeight(26)
exportBtn:SetPoint("BOTTOMLEFT", shareTab, "BOTTOMLEFT", 30, 8)
exportBtn:SetText("Export")
exportBtn:SetScript("OnClick", function()
    if not OctoPawn_ExportWeightsSparse then return end
    local s, err = OctoPawn_ExportWeightsSparse()
    if not s then
        Msg("|cFFFF0000OctoPawn: Export failed - " .. tostring(err) .. "|r")
        return
    end
    shareBox:SetText(s)
    shareBox:HighlightText()
    shareBox:SetFocus()
    Msg("|cFF00FF00OctoPawn: Exported. Ctrl+C to copy.|r")
end)

local importBtn = CreateFrame("Button", nil, shareTab, "UIPanelButtonTemplate")
importBtn:SetWidth(110); importBtn:SetHeight(26)
importBtn:SetPoint("BOTTOMRIGHT", shareTab, "BOTTOMRIGHT", -30, 8)
importBtn:SetText("Import")
importBtn:SetScript("OnClick", function()
    if not OctoPawn_ImportWeightsSparse then return end
    local ok, info = OctoPawn_ImportWeightsSparse(shareBox:GetText() or "")
    if not ok then
        Msg("|cFFFF0000OctoPawn: Import failed - " .. tostring(info) .. "|r")
        return
    end
    Msg("|cFF00FF00OctoPawn: Imported weights for " .. tostring(info) .. " (custom).|r")
    shareBox:SetText("")
    WipeEditBoxes(); BuildEditBoxes()
    ShowTab("weights")
    if OctoPawn_UpdatePlayerPaperScore then OctoPawn_UpdatePlayerPaperScore() end
end)
shareTab:SetScript("OnShow", function() shareBox:SetText("") end)

-------------------------------------------------
-- Helpers classe / profils
-------------------------------------------------
local function PlayerClassSafe()
    local class = OctoPawn_GetClass and OctoPawn_GetClass()
    if not class then
        local _, c = UnitClass("player")
        class = c or "WARRIOR"
    end
    return class
end

local function RolesForClassSafe(class)
    local roles = {}
    if OctoPawn_GetRolesForClass then
        local ok, result = pcall(OctoPawn_GetRolesForClass, class)
        if ok and type(result) == "table" then roles = result end
    end
    if table.getn(roles) == 0 and defaultWeights and defaultWeights[class] then
        local r, v
        for r, v in pairs(defaultWeights[class]) do
            if type(v) == "table" then table.insert(roles, r) end
        end
        table.sort(roles)
    end
    if table.getn(roles) == 0 then table.insert(roles, "Default") end
    return roles
end

-------------------------------------------------
-- Copy from... (liste déroulante ; remplit les cases, puis Save Weights)
-------------------------------------------------
local function CopyFromRole(src)
    local class = PlayerClassSafe()
    local w = OctoPawn_GetWeightsForRole and OctoPawn_GetWeightsForRole(class, src) or {}
    local c = OctoPawn_GetCapsForRole and OctoPawn_GetCapsForRole(src) or {}
    local stat, box
    for stat, box in pairs(editBoxes) do
        local v = w[stat]
        if v == nil and stat == "ARMOR BONUS" then v = w["ARMOR"] end
        if v == nil then v = 0 end
        box:SetText(tostring(v))
        local cd = c[stat]
        if cd and tonumber(cd.softCap) and tonumber(cd.softCap) > 0 then
            capBoxes[stat]:SetText(FmtNum(cd.softCap)); postBoxes[stat]:SetText(FmtNum(cd.postValue))
        else
            capBoxes[stat]:SetText("0"); postBoxes[stat]:SetText("0")
        end
    end
    RefreshAllCapLabels()
    UpdateWeightsTitle()
    Msg("|cFF00FF00OctoPawn: Copied weights and caps from " .. tostring(src) .. " - click Save Weights to apply.|r")
end

local function CopyMenu_Initialize()
    local class = PlayerClassSafe()
    local roles = RolesForClassSafe(class)
    local current = OctoPawnDB and OctoPawnDB.role
    local ri
    for ri = 1, table.getn(roles) do
        local r = roles[ri]
        if r ~= current then
            local roleName = r
            local info = {}
            local custom = OctoPawn_HasCustomWeights and OctoPawn_HasCustomWeights(r)
            if custom then info.text = r .. " (custom)" else info.text = r end
            info.value = r
            info.notCheckable = 1
            info.func = function() CopyFromRole(roleName) end
            UIDropDownMenu_AddButton(info, 1)
        end
    end
end

copyBtn:SetScript("OnClick", function()
    if not copyDD then
        copyDD = CreateFrame("Frame", "OctoPawnCopyFromDropDown", UIParent, "UIDropDownMenuTemplate")
    end
    UIDropDownMenu_Initialize(copyDD, CopyMenu_Initialize, "MENU")
    ToggleDropDownMenu(1, nil, copyDD, copyBtn, 0, 0)
end)

-------------------------------------------------
-- Onglet "List of profiles" : Tip / supprimer / renommer / nouveau
-------------------------------------------------
local listHint
local renameBox, renameOk

local function ClearListItems()
    local i
    for i = 1, table.getn(listItems) do
        local b = listItems[i]
        if b then b:Hide(); b:SetParent(nil) end
    end
    listItems = {}
end

function OctoPawn_BuildProfileList()
    if not listHint then
        listHint = listTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        listHint:SetPoint("TOPLEFT", listTab, "TOPLEFT", 8, -4)
        listHint:SetWidth(430); listHint:SetJustifyH("LEFT")
        listHint:SetTextColor(0.7, 0.7, 0.7)
        listHint:SetText("Click a profile to edit its weights.  Tip = show this profile on item tooltips.")
    end
    ClearListItems()

    local class = PlayerClassSafe()
    local roles = RolesForClassSafe(class)
    local activeRole = OctoPawnDB and OctoPawnDB.role
    local activeCustom = OctoPawnDB and OctoPawnDB.useCustom
    local y = -28
    local function Track(frame) table.insert(listItems, frame) end

    local function SelectRole(roleName, isCustom)
        if WeightsChanged() then
            Msg("|cFFFF9900OctoPawn: Unsaved changes discarded.|r")
        end
        if OctoPawn_ApplyRole then OctoPawn_ApplyRole(roleName, isCustom) end
        WipeEditBoxes(); BuildEditBoxes()
        scrollFrame:SetVerticalScroll(0)
        ShowTab("weights")
    end

    local rows, customRows, headerAt = {}, {}, {}
    local nDefault = 0
    local ri
    for ri = 1, table.getn(roles) do
        local r = roles[ri]
        local builtIn = OctoPawn_IsBuiltInRole and OctoPawn_IsBuiltInRole(class, r)
        local hasC = OctoPawn_HasCustomWeights and OctoPawn_HasCustomWeights(r)
        if builtIn then
            table.insert(rows, { role = r, kind = "default" })
            nDefault = nDefault + 1
            if hasC then table.insert(customRows, { role = r, kind = "derived" }) end
        else
            table.insert(customRows, { role = r, kind = "custom" })
        end
    end
    if nDefault > 0 then headerAt[1] = { "Default profiles", 1, 0.82, 0 } end
    if table.getn(customRows) > 0 then
        headerAt[nDefault + 1] = { "Custom profiles", 0.25, 1, 0.25 }
        for ri = 1, table.getn(customRows) do table.insert(rows, customRows[ri]) end
    end

    for ri = 1, table.getn(rows) do
        local role = rows[ri].role
        local kind = rows[ri].kind
        local hasCustom = OctoPawn_HasCustomWeights and OctoPawn_HasCustomWeights(role)
        local loadCustom = (kind == "derived") or (kind == "custom" and hasCustom and true or false)

        if headerAt[ri] then
            if ri > 1 then y = y - 6 end
            local hdr = listTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hdr:SetPoint("TOPLEFT", listTab, "TOPLEFT", 12, y)
            hdr:SetText(headerAt[ri][1])
            hdr:SetTextColor(headerAt[ri][2], headerAt[ri][3], headerAt[ri][4])
            Track(hdr)
            y = y - 18
        end

        local btn = CreateFrame("Button", nil, listTab, "UIPanelButtonTemplate")
        btn:SetWidth(240); btn:SetHeight(26)
        btn:SetPoint("TOPLEFT", listTab, "TOPLEFT", 8, y)
        btn.roleName = role
        btn:SetScript("OnClick", function() SelectRole(this.roleName, loadCustom) end)
        Track(btn)

        -- Profil actif : "(current)" dans le nom du bouton
        local isCurrent = false
        if activeRole == role then
            if kind == "default" then isCurrent = not activeCustom
            elseif kind == "derived" then isCurrent = activeCustom and true or false
            else isCurrent = true end
        end
        local label
        if kind == "default" then label = role
        elseif kind == "derived" then label = "|cff40ff40" .. role .. " (custom)|r"
        else label = "|cff40ff40" .. role .. "|r" end
        if isCurrent then label = label .. " |cff40ff40(current)|r" end
        btn:SetText(label)

        -- Tip : colonne fixe
        if kind ~= "derived" then
            local tip = CreateFrame("CheckButton", nil, listTab, "UICheckButtonTemplate")
            tip:SetWidth(24); tip:SetHeight(24)
            tip:SetPoint("TOPLEFT", listTab, "TOPLEFT", 250, y - 1)
            tip.roleName = role
            if OctoPawn_IsTipSpec and OctoPawn_IsTipSpec(role) then tip:SetChecked(1) else tip:SetChecked(0) end
            tip:SetScript("OnClick", function()
                if OctoPawn_SetTipSpec then OctoPawn_SetTipSpec(this.roleName, this:GetChecked() and true or false) end
            end)
            tip:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Show on tip", 1, 1, 1)
                GameTooltip:AddLine("Include this profile on item tooltips", 0.7, 0.7, 0.7, 1)
                GameTooltip:Show()
            end)
            tip:SetScript("OnLeave", function() GameTooltip:Hide() end)
            Track(tip)
            local tipLbl = listTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tipLbl:SetPoint("LEFT", tip, "RIGHT", 0, 0)
            tipLbl:SetText("Tip")
            Track(tipLbl)
        end

        if kind ~= "default" and hasCustom then
            local del = CreateFrame("Button", nil, listTab, "UIPanelButtonTemplate")
            del:SetWidth(28); del:SetHeight(24)
            del:SetPoint("TOPLEFT", listTab, "TOPLEFT", 304, y - 1)
            del:SetText("X")
            del.roleName = role
            del:SetScript("OnClick", function()
                local ok, err = OctoPawn_DeleteCustomSpec and OctoPawn_DeleteCustomSpec(this.roleName)
                if ok then
                    Msg("|cFF00FF00OctoPawn: Deleted custom '" .. tostring(this.roleName) .. "'.|r")
                    WipeEditBoxes(); BuildEditBoxes()
                    OctoPawn_BuildProfileList()
                else
                    Msg("|cFFFF0000OctoPawn: " .. tostring(err or "delete failed") .. "|r")
                end
            end)
            del:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete custom", 1, 0.3, 0.3)
                if kind == "derived" then
                    GameTooltip:AddLine("Removes your changes; the default profile is kept", 0.7, 0.7, 0.7, 1)
                else
                    GameTooltip:AddLine("Deletes this custom profile entirely", 0.7, 0.7, 0.7, 1)
                end
                GameTooltip:Show()
            end)
            del:SetScript("OnLeave", function() GameTooltip:Hide() end)
            Track(del)

            local ren = CreateFrame("Button", nil, listTab, "UIPanelButtonTemplate")
            ren:SetWidth(64); ren:SetHeight(24)
            ren:SetPoint("LEFT", del, "RIGHT", 2, 0)
            ren:SetText("Rename")
            ren.roleName = role
            ren:SetScript("OnClick", function()
                renameBox:Show()
                renameBox:SetText(this.roleName)
                renameBox.oldName = this.roleName
                renameBox:SetFocus()
            end)
            Track(ren)
        end
        y = y - 28
    end

    -- Nouveau profil
    y = y - 10
    local newLbl = listTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newLbl:SetPoint("TOPLEFT", listTab, "TOPLEFT", 12, y - 4)
    newLbl:SetText("New profile:")
    Track(newLbl)

    local newBox = CreateFrame("EditBox", "OctoPawnNewSpecBox", listTab)
    newBox:SetWidth(140); newBox:SetHeight(22)
    newBox:SetPoint("LEFT", newLbl, "RIGHT", 8, 0)
    newBox:SetAutoFocus(false)
    newBox:SetFontObject(GameFontHighlight)
    newBox:SetText("")
    newBox:SetTextInsets(4, 4, 0, 0)
    newBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    newBox:SetBackdropColor(0, 0, 0, 0.8)
    newBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    Track(newBox)

    local newBtn = CreateFrame("Button", nil, listTab, "UIPanelButtonTemplate")
    newBtn:SetWidth(60); newBtn:SetHeight(24)
    newBtn:SetPoint("LEFT", newBox, "RIGHT", 6, 0)
    newBtn:SetText("Add")
    newBtn:SetScript("OnClick", function()
        local name = newBox:GetText() or ""
        local ok, err = OctoPawn_CreateCustomSpec and OctoPawn_CreateCustomSpec(name)
        if ok then
            Msg("|cFF00FF00OctoPawn: Created profile '" .. name .. "'.|r")
            newBox:SetText("")
            OctoPawn_BuildProfileList()
        else
            Msg("|cFFFF0000OctoPawn: " .. tostring(err or "create failed") .. "|r")
        end
    end)
    Track(newBtn)

    -- Zone de renommage (créée une seule fois, en bas de l'onglet)
    if not renameBox then
        renameBox = CreateFrame("EditBox", "OctoPawnRenameSpecBox", listTab)
        renameBox:SetWidth(160); renameBox:SetHeight(22)
        renameBox:SetPoint("BOTTOMLEFT", listTab, "BOTTOMLEFT", 70, 10)
        renameBox:SetAutoFocus(false)
        renameBox:SetFontObject(GameFontHighlight)
        renameBox:SetTextInsets(4, 4, 0, 0)
        renameBox:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        renameBox:SetBackdropColor(0, 0, 0, 0.9)
        renameBox:SetScript("OnEscapePressed", function() this:ClearFocus(); this:Hide() end)
        renameBox:Hide()
        local rlbl = listTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rlbl:SetPoint("RIGHT", renameBox, "LEFT", -6, 0)
        rlbl:SetText("Rename to:")
        renameOk = CreateFrame("Button", nil, listTab, "UIPanelButtonTemplate")
        renameOk:SetWidth(50); renameOk:SetHeight(24)
        renameOk:SetPoint("LEFT", renameBox, "RIGHT", 6, 0)
        renameOk:SetText("OK")
        renameOk:SetScript("OnClick", function()
            local old = renameBox.oldName
            local newn = renameBox:GetText() or ""
            local ok, err = OctoPawn_RenameCustomSpec and OctoPawn_RenameCustomSpec(old, newn)
            if ok then
                Msg("|cFF00FF00OctoPawn: Renamed to '" .. newn .. "'.|r")
                renameBox:Hide()
                WipeEditBoxes(); BuildEditBoxes()
                OctoPawn_BuildProfileList()
            else
                Msg("|cFFFF0000OctoPawn: " .. tostring(err or "rename failed") .. "|r")
            end
        end)
        renameOk:Hide()
        renameBox:SetScript("OnShow", function() renameOk:Show(); rlbl:Show() end)
        renameBox:SetScript("OnHide", function() renameOk:Hide(); rlbl:Hide() end)
        rlbl:Hide()
    else
        renameBox:Hide()
    end
end

function OctoPawn_ShowRolePicker()
    OpenConfig("list")
end

-------------------------------------------------
-- Points d'entrée conservés (compatibilité)
-------------------------------------------------
function ToggleShareFrame()
    if configFrame:IsShown() and configFrame.currentTab == "share" then
        configFrame:Hide()
    else
        OpenConfig("share")
    end
end

function ToggleAdvancedFrame()
    if not OctoPawnDB then OctoPawnDB = {} end
    OctoPawnDB.showCaps = true
    OpenConfig("weights")
    ApplyCapsVisibility(); RefreshAllCapLabels()
end

function OctoPawn_OnDBReady() end
print("|cFF00FF00OctoPawn|r UI loaded")

