-------------------------------------------------
-- OctoPawn UI/Paperdoll/Paperdoll.lua
-------------------------------------------------
local playerHolder, playerFS, inspectHolder, inspectFS, roleDropdown
local LABEL = "|cFFFFD100OP Score:|r "

local function ScoreColor(n)
    n = n or 0
    if n >= 1700 then return 1.0, 0.15, 0.15
    elseif n >= 1200 then return 1.0, 0.5, 0.0
    elseif n >= 700 then return 0.64, 0.21, 0.93
    elseif n >= 400 then return 0.0, 0.44, 0.87
    elseif n >= 200 then return 0.12, 1.0, 0.0
    elseif n >= 100 then return 1.0, 1.0, 1.0
    else return 0.6, 0.6, 0.6 end
end

local function ColorHex(n)
    local r, g, b = ScoreColor(n)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function FormatScore(n)
    n = n or 0
    return LABEL .. "|cFF" .. ColorHex(n) .. string.format("%.1f|r", n)
end

-- Class-based inspect role (stable)
local function GetInspectRole(class)
    if not class then return nil end
    if OctoPawnDB and OctoPawnDB.inspectRole and OctoPawnDB.inspectRole[class] then
        return OctoPawnDB.inspectRole[class]
    end
    return nil
end

local function GetWeightsForClassRole(class, role)
    local classTable = defaultWeights and defaultWeights[class]
    if not classTable then return {} end
    if role and classTable[role] then return classTable[role] end
    if classTable.Default then return classTable.Default end
    for _, weights in pairs(classTable) do
        return weights
    end
    return {}
end

local function ScoreUnitQuiet(unit, weights)
    if not unit or not UnitExists(unit) then return 0 end
    if OctoPawn_ScoreUnitEquipped then
        return OctoPawn_ScoreUnitEquipped(unit, weights, weights and {} or nil) or 0
    end
    return 0
end

local function ScorePlayer()
    return ScoreUnitQuiet("player", nil)
end

local function ScoreInspect()
    if not UnitExists("target") or not UnitIsPlayer("target") then return nil end
    local _, class = UnitClass("target")
    local role = GetInspectRole(class)
    local weights = GetWeightsForClassRole(class, role)
    return ScoreUnitQuiet("target", weights)
end

OctoPawn_FormatScore = FormatScore
OctoPawn_ScorePlayer = ScorePlayer
OctoPawn_ScoreUnitQuiet = ScoreUnitQuiet
OctoPawn_GetInspectRole = GetInspectRole
OctoPawn_GetWeightsForClassRole = GetWeightsForClassRole

local function RoleMenu_Initialize()
    if not UIDROPDOWNMENU_MENU_VALUE then return end
    local data = UIDROPDOWNMENU_MENU_VALUE
    local class = data.class
    local mode = data.mode
    if not class or not mode then return end

    local roles = {}
    if OctoPawn_GetRolesForClass then
        roles = OctoPawn_GetRolesForClass(class) or {}
    end
    if type(roles) ~= "table" or table.getn(roles) == 0 then
        local classTable = defaultWeights and defaultWeights[class]
        if classTable then
            for r, v in pairs(classTable) do
                if type(v) == "table" then table.insert(roles, r) end
            end
            table.sort(roles)
        end
    end

    local currentPlayer = OctoPawnDB and OctoPawnDB.role
    local currentInspect = GetInspectRole(class)

    local i
    for i = 1, table.getn(roles) do
        local roleName = roles[i]
        local className = class
        local modeName = mode

        local info = {}
        info.text = roleName
        info.value = roleName
        info.func = function()
            if modeName == "player" then
                if OctoPawn_ApplyRole then OctoPawn_ApplyRole(roleName, false) end
                if OctoPawn_WipeConfigUI then OctoPawn_WipeConfigUI() end
                OctoPawn_UpdatePlayerPaperScore()
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Scoring as " .. tostring(roleName) .. ".|r")
            else
                if not OctoPawnDB then OctoPawnDB = {} end
                if not OctoPawnDB.inspectRole then OctoPawnDB.inspectRole = {} end
                OctoPawnDB.inspectRole[className] = roleName
                OctoPawn_UpdateInspectPaperScore()
            end
        end
        if modeName == "player" then
            info.checked = (currentPlayer == roleName) and 1 or nil
        else
            info.checked = (currentInspect == roleName) and 1 or nil
        end
        UIDropDownMenu_AddButton(info, 1)
    end
end

local function ShowRoleMenu(class, mode)
    if not class or not mode then return end
    if not roleDropdown then
        roleDropdown = CreateFrame("Frame", "OctoPawnRoleDropDown", UIParent, "UIDropDownMenuTemplate")
    end
    roleDropdown.opClass = class
    roleDropdown.opMode = mode
    UIDropDownMenu_Initialize(roleDropdown, function()
        UIDROPDOWNMENU_MENU_VALUE = { class = roleDropdown.opClass, mode = roleDropdown.opMode }
        RoleMenu_Initialize()
    end, "MENU")
    ToggleDropDownMenu(1, nil, roleDropdown, "cursor", 0, 0)
end

local function BindRoleClick(holder, mode)
    if not holder then return end
    holder:EnableMouse(true)
    holder:SetScript("OnMouseUp", function()
        if arg1 ~= "RightButton" then return end
        local class
        if mode == "player" then
            if OctoPawn_GetClass then class = OctoPawn_GetClass() end
            if not class then
                local _, c = UnitClass("player")
                class = c
            end
        else
            if not UnitExists("target") or not UnitIsPlayer("target") then return end
            local _, c = UnitClass("target")
            class = c
        end
        if class then ShowRoleMenu(class, mode) end
    end)
end

local function EnsurePlayerUI()
    if playerHolder then return end
    local parent = PaperDollFrame or CharacterFrame
    if not parent then return end

    playerHolder = CreateFrame("Frame", "OctoPawnPlayerScoreFrame", parent)
    playerHolder:SetWidth(100)
    playerHolder:SetHeight(15)
    playerHolder:SetFrameStrata("HIGH")
    playerHolder:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0) + 20)
    playerHolder:SetPoint("TOP", parent, "TOP", 0, -57)

    local bg = playerHolder:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(playerHolder)
    bg:SetTexture(0, 0, 0, 0)

    playerFS = playerHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerFS:SetPoint("CENTER", playerHolder, "CENTER", 0, 0)
    playerFS:SetText("OP Score: ...")

    BindRoleClick(playerHolder, "player")
    playerHolder:Show()
end

local function EnsureInspectUI()
    if inspectHolder then return end
    local parent = InspectPaperDollFrame or InspectFrame
    if not parent then return end

    inspectHolder = CreateFrame("Frame", "OctoPawnInspectScoreFrame", parent)
    inspectHolder:SetWidth(100)
    inspectHolder:SetHeight(15)
    inspectHolder:SetFrameStrata("HIGH")
    inspectHolder:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0) + 20)
    inspectHolder:SetPoint("TOP", parent, "TOP", 0, -57)

    local bg = inspectHolder:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(inspectHolder)
    bg:SetTexture(0, 0, 0, 0)

    inspectFS = inspectHolder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    inspectFS:SetPoint("CENTER", inspectHolder, "CENTER", 0, 0)
    inspectFS:SetText("OP Score: ...")

    BindRoleClick(inspectHolder, "inspect")
    inspectHolder:Show()
end

function OctoPawn_UpdatePlayerPaperScore()
    EnsurePlayerUI()
    if not playerFS then return end
    playerFS:SetTextColor(1, 1, 1)
    playerFS:SetText(FormatScore(ScorePlayer()))
    if playerHolder then playerHolder:Show() end
end

function OctoPawn_UpdateInspectPaperScore()
    EnsureInspectUI()
    if not inspectFS then return end
    inspectFS:SetTextColor(1, 1, 1)
    local total = ScoreInspect()
    if total == nil then
        inspectFS:SetText(LABEL .. "|cFF999999--|r")
    else
        inspectFS:SetText(FormatScore(total))
    end
    if inspectHolder then inspectHolder:Show() end
end

local function HookShow(frame, cb)
    if not frame then return end
    local old = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function()
        if old then old() end
        cb()
    end)
end

local function TryHookAll()
    HookShow(CharacterFrame, OctoPawn_UpdatePlayerPaperScore)
    HookShow(PaperDollFrame, OctoPawn_UpdatePlayerPaperScore)
    HookShow(InspectFrame, function()
        local f = CreateFrame("Frame")
        local elapsed = 0
        f:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed > 0.2 then
                f:SetScript("OnUpdate", nil)
                OctoPawn_UpdateInspectPaperScore()
            end
        end)
    end)
    HookShow(InspectPaperDollFrame, OctoPawn_UpdateInspectPaperScore)
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("UNIT_INVENTORY_CHANGED")
ef:RegisterEvent("ADDON_LOADED")
ef:RegisterEvent("PLAYER_TARGET_CHANGED")
ef:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        if not OctoPawnDB then OctoPawnDB = {} end
        if not OctoPawnDB.inspectRole then OctoPawnDB.inspectRole = {} end
        TryHookAll()
        if CharacterFrame and CharacterFrame:IsShown() then
            OctoPawn_UpdatePlayerPaperScore()
        end
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
        TryHookAll()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" and CharacterFrame and CharacterFrame:IsShown() then
            OctoPawn_UpdatePlayerPaperScore()
        elseif InspectFrame and InspectFrame:IsShown() then
            OctoPawn_UpdateInspectPaperScore()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if InspectFrame and InspectFrame:IsShown() then
            OctoPawn_UpdateInspectPaperScore()
        end
    end
end)

TryHookAll()
print("|cFF00FF00OctoPawn|r paperdoll loaded")

