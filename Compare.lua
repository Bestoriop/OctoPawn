-------------------------------------------------
-- OctoPawn Compare.lua
-------------------------------------------------
local INV_SLOT_MAP = {}
local function AddSlot(key, slots)
    if key then INV_SLOT_MAP[key] = slots end
end
AddSlot(INVTYPE_HEAD, {1}); AddSlot(INVTYPE_NECK, {2}); AddSlot(INVTYPE_SHOULDER, {3})
AddSlot(INVTYPE_BODY, {4}); AddSlot(INVTYPE_CHEST, {5}); AddSlot(INVTYPE_ROBE, {5})
AddSlot(INVTYPE_WAIST, {6}); AddSlot(INVTYPE_LEGS, {7}); AddSlot(INVTYPE_FEET, {8})
AddSlot(INVTYPE_WRIST, {9}); AddSlot(INVTYPE_HAND, {10}); AddSlot(INVTYPE_FINGER, {11, 12})
AddSlot(INVTYPE_TRINKET, {13, 14}); AddSlot(INVTYPE_CLOAK, {15})
AddSlot(INVTYPE_WEAPON, {16, 17}); AddSlot(INVTYPE_WEAPONMAINHAND, {16})
AddSlot(INVTYPE_WEAPONOFFHAND, {17}); AddSlot(INVTYPE_2HWEAPON, {16, 17})
AddSlot(INVTYPE_SHIELD, {17}); AddSlot(INVTYPE_HOLDABLE, {17})
AddSlot(INVTYPE_RANGED, {18}); AddSlot(INVTYPE_RANGEDRIGHT, {18})
AddSlot(INVTYPE_THROWN, {18}); AddSlot(INVTYPE_RELIC, {18}); AddSlot(INVTYPE_TABARD, {19})
local ENGLISH_FALLBACK = {
    ["Head"]={1},["Neck"]={2},["Shoulder"]={3},["Shirt"]={4},["Chest"]={5},["Waist"]={6},
    ["Legs"]={7},["Feet"]={8},["Wrist"]={9},["Hands"]={10},["Finger"]={11,12},
    ["Trinket"]={13,14},["Back"]={15},["One-Hand"]={16,17},["Main Hand"]={16},
    ["Off Hand"]={17},["Two-Hand"]={16,17},["Held In Off-hand"]={17},
    ["Ranged"]={18},["Wand"]={18},["Thrown"]={18},["Gun"]={18},["Bow"]={18},
    ["Crossbow"]={18},["Relic"]={18},["Tabard"]={19},
}
for k,v in pairs(ENGLISH_FALLBACK) do
    if not INV_SLOT_MAP[k] then INV_SLOT_MAP[k] = v end
end
local SLOT_LABEL = {
    [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",[7]="Legs",[8]="Feet",
    [9]="Wrist",[10]="Hands",[11]="Finger 1",[12]="Finger 2",[13]="Trinket 1",[14]="Trinket 2",
    [15]="Back",[16]="Main Hand",[17]="Off Hand",[18]="Ranged",[19]="Tabard",
}
function OctoPawn_GetCompareSlotsFromTooltip(tooltip)
    local num = tooltip:NumLines()
    local i
    for i = 1, num do
        local fs = getglobal(tooltip:GetName() .. "TextLeft" .. i)
        if fs then
            local t = fs:GetText()
            if t and INV_SLOT_MAP[t] then return INV_SLOT_MAP[t], t end
        end
    end
    return nil, nil
end
local function FormatDiff(diff)
    if diff > 0.05 then return string.format("|cFF00FF00(+%.1f)|r", diff)
    elseif diff < -0.05 then return string.format("|cFFFF0000(%.1f)|r", diff)
    else return "|cFFAAAAAA(+0.0)|r" end
end

-- Returns list of { score, label, slot } for equipped items in the same slot set.
-- Returns nil if compare is off, no slots, or item is already equipped.
local function CollectEquippedComparisons(tooltip, score)
    if OctoPawnDB and OctoPawnDB.compareEnabled == false then return nil end
    if not score then return nil end
    local slots = OctoPawn_GetCompareSlotsFromTooltip(tooltip)
    if not slots then return nil end
    local link = tooltip.itemLink
    local s
    for _, s in ipairs(slots) do
        local eq = GetInventoryItemLink("player", s)
        if link and eq and link == eq then return nil end
    end
    local tip = OctoPawn_GetScanTooltip and OctoPawn_GetScanTooltip()
    if not tip then return nil end
    local equippedList = {}
    for _, s in ipairs(slots) do
        if GetInventoryItemLink("player", s) then
            tip:SetOwner(UIParent, "ANCHOR_NONE")
            tip:ClearLines()
            tip.octoPawnScored = nil
            tip:SetInventoryItem("player", s)
            tip:Show()
            local eqScore = OctoPawn_ScoreTooltip(tip)
            tip:Hide()
            table.insert(equippedList, { score = eqScore or 0, label = SLOT_LABEL[s] or ("Slot "..s), slot = s })
        end
    end
    if table.getn(equippedList) == 0 then return nil end
    return equippedList
end

-- Compact: space-separated diffs only, no slot names. e.g. " (+1.2) (-0.3)"
function OctoPawn_FormatCompactDiffs(tooltip, score)
    local equippedList = CollectEquippedComparisons(tooltip, score)
    if not equippedList then return "" end
    local parts = ""
    local _, eq
    for _, eq in ipairs(equippedList) do
        parts = parts .. " " .. FormatDiff(score - eq.score)
    end
    return parts
end

function OctoPawn_ShowComparison(tooltip, score)
    local equippedList = CollectEquippedComparisons(tooltip, score)
    if not equippedList then return end
    if OctoPawnDB and OctoPawnDB.compactTooltips then
        -- Compact path is handled by AddScoreToTooltip via FormatCompactDiffs
        return
    end
    local _, eq
    for _, eq in ipairs(equippedList) do
        tooltip:AddLine(FormatDiff(score - eq.score) .. " |cFFAAAAAAvs " .. eq.label .. "|r")
    end
end
print("|cFF00FF00OctoPawn|r compare loaded")
