-------------------------------------------------
-- OctoPawn Scoring/ScoringCore.lua
-------------------------------------------------

local DEFAULT_DR = {
    HIT                 = { softCap = 6,  postScale = 0.35 },
    ["SPELL HIT"]       = { softCap = 10, postScale = 0.30 },
    CRIT                = { softCap = 25, postScale = 0.40 },
    ["SPELL CRIT"]      = { softCap = 25, postScale = 0.40 },
    ["RANGED CRIT"]     = { softCap = 25, postScale = 0.40 },
    ["HOLY CRIT"]       = { softCap = 25, postScale = 0.40 },
    DEFENSE             = { softCap = 25, postScale = 0.35 },
    DODGE               = { softCap = 25, postScale = 0.40 },
    PARRY               = { softCap = 20, postScale = 0.40 },
    BLOCK               = { softCap = 25, postScale = 0.40 },
    HASTE               = { softCap = 20, postScale = 0.45 },
    ["RANGED HASTE"]    = { softCap = 20, postScale = 0.45 },
    ["SPELL PENETRATION"] = { softCap = 20, postScale = 0.40 },
    ["ARMOR PENETRATION"] = { softCap = 30, postScale = 0.45 },
}

function OctoPawn_GetDefaultDR()
    return DEFAULT_DR
end

function OctoPawn_GetDR(stat)
    if OctoPawnDB and OctoPawnDB.dr and OctoPawnDB.dr[stat] then
        local d = OctoPawnDB.dr[stat]
        if d.softCap ~= nil and tonumber(d.softCap) == 0 then
            return nil
        end
        return d
    end
    return DEFAULT_DR[stat]
end

local function EffectiveValue(stat, value)
    if not value then return 0 end
    local dr = OctoPawn_GetDR(stat)
    if not dr or not dr.softCap then
        return value
    end
    local soft = tonumber(dr.softCap) or 0
    if soft <= 0 then return value end
    local post = tonumber(dr.postScale)
    if not post then post = 0.5 end
    if value <= soft then
        return value
    end
    return soft + (value - soft) * post
end

function OctoPawn_ScoreTooltip(tooltip, overrideWeights)
    local weights = overrideWeights
    if not weights then
        weights = (OctoPawnDB and OctoPawnDB.weights) or (OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights()) or {}
    end
    local patterns = OctoPawn_StatPatterns or {}
    local totals = {}
    local pastDPS = false
    local numLines = tooltip:NumLines()
    local i
    for i = 1, numLines do
        local lineObj = getglobal(tooltip:GetName() .. "TextLeft" .. i)
        if lineObj then
            local line = lineObj:GetText()
            if line then
                local upper = string.upper(line)
                local isChanceOnHit = string.find(upper, "CHANCE ON HIT") ~= nil
                if not (OctoPawn_IsSetBonusLine and OctoPawn_IsSetBonusLine(upper)) then
                    if string.find(upper, "DAMAGE PER SECOND") or string.find(upper, "DPS") then pastDPS = true end
                    if pastDPS or not string.find(upper, "DAMAGE") or string.find(upper, "PER SECOND") or string.find(upper, "SPELLS") then
                        if not string.find(upper, "REQUIRES") and not string.find(upper, "SOULBOUND") and
                           not string.find(upper, "UNIQUE") and not string.find(upper, "LEVEL") and
                           not string.find(upper, "BIND") and not string.find(upper, "MADE BY") then
                            local matchedThisLine = {}
                            local _, entry
                            for _, entry in ipairs(patterns) do
                                if string.find(upper, entry.pattern) and not matchedThisLine[entry.stat] then
                                    local skip = false
                                    if entry.stat == "HIT" and isChanceOnHit then skip = true
                                    elseif entry.stat == "HIT" and string.find(upper, "SPELL") then skip = true
                                    elseif isChanceOnHit and (entry.stat == "HIT" or entry.stat == "CRIT"
                                        or entry.stat == "STRENGTH" or entry.stat == "AGILITY"
                                        or entry.stat == "STAMINA" or entry.stat == "INTELLECT"
                                        or entry.stat == "SPIRIT" or entry.stat == "ARMOR"
                                        or entry.stat == "ARMOR BONUS") then
                                        skip = true
                                    elseif entry.stat == "ARMOR" or entry.stat == "ARMOR BONUS" then
                                        -- Armure de base : ligne blanche "123 Armor" (nombre puis Armor, rien d'autre)
                                        -- Bonus : toute autre ligne avec ARMOR (ex. "Reinforced Armor +32", "+32 Armor")
                                        local isBaseArmor = string.find(upper, "^%s*%d+%s+ARMOR%s*$") ~= nil
                                        if string.find(upper, "PENETRATION") or string.find(upper, "IGNORE") then
                                            skip = true
                                        elseif entry.stat == "ARMOR" and not isBaseArmor then
                                            skip = true
                                        elseif entry.stat == "ARMOR BONUS" and isBaseArmor then
                                            skip = true
                                        end
                                    elseif (entry.stat == "SPELL DAMAGE" or entry.stat == "SPELL POWER") then
                                        if matchedThisLine["NATURE DAMAGE"] or matchedThisLine["FIRE DAMAGE"]
                                            or matchedThisLine["FROST DAMAGE"] or matchedThisLine["SHADOW DAMAGE"]
                                            or matchedThisLine["ARCANE DAMAGE"] or matchedThisLine["HOLY DAMAGE"] then
                                            skip = true
                                        end
                                    elseif entry.stat == "ATTACK POWER" then
                                        -- Feral / ranged / undead AP lines contain "ATTACK POWER" but are not melee AP
                                        if matchedThisLine["FERAL ATTACK POWER"]
                                            or matchedThisLine["RANGED ATTACK POWER"]
                                            or matchedThisLine["ATTACK POWER UNDEAD"]
                                            or string.find(upper, "FERAL")
                                            or string.find(upper, "IN CAT")
                                            or string.find(upper, "IN BEAR")
                                            or string.find(upper, "MOONKIN")
                                            or string.find(upper, "RANGED ATTACK POWER")
                                            or string.find(upper, "VERSUS UNDEAD")
                                            or string.find(upper, "AGAINST UNDEAD")
                                            then
                                            skip = true
                                        end
                                    end
                                    if not skip then
                                        local num = OctoPawn_ExtractNumberNearStat and OctoPawn_ExtractNumberNearStat(line, upper, entry.pattern)
                                        if not num then
                                            local _, _, captured = string.find(line, "([%+%-]?%d+%.?%d*)")
                                            if captured then num = tonumber(captured) end
                                        end
                                        if not num and entry.stat == "LIFESTEAL" then
                                            local _, _, captured = string.find(line, "([%+%-]?%d+)%s*%%")
                                            if captured then num = tonumber(captured) end
                                        end
                                        -- Prefer the % chance number on extra-attack proc lines
                                        -- e.g. "2% chance to get 1 extra attack" → 2, not 1
                                        if entry.stat == "EXTRA ATTACK" then
                                            local _, _, pct = string.find(line, "([%+%-]?%d+%.?%d*)%s*%%")
                                            if pct then num = tonumber(pct) end
                                        end
                                        if num then
                                            matchedThisLine[entry.stat] = true
                                            totals[entry.stat] = (totals[entry.stat] or 0) + num
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local results = {}
    local totalScore = 0
    for stat, value in pairs(totals) do
        local weight = weights[stat]
        -- Sans poids dédié, le bonus d'armure hérite du poids de l'armure
        if weight == nil and stat == "ARMOR BONUS" then
            weight = weights["ARMOR"]
        end
        if weight == nil then weight = 1.0 end
        local effective = EffectiveValue(stat, value)
        local contribution = effective * weight
        totalScore = totalScore + contribution
        table.insert(results, {
            stat = stat,
            value = value,
            effective = effective,
            weight = weight,
            score = contribution,
        })
    end
    return totalScore, results
end


local function GetScanTooltip()
    if not OctoPawnScanTooltip then
        OctoPawnScanTooltip = CreateFrame("GameTooltip", "OctoPawnScanTooltip", nil, "GameTooltipTemplate")
        OctoPawnScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return OctoPawnScanTooltip
end

function OctoPawn_GetScanTooltip()
    return GetScanTooltip()
end

function OctoPawn_ScoreUnitEquipped(unit, weights)
    if not unit or not UnitExists(unit) then return 0 end
    local tip = GetScanTooltip()
    local total = 0
    local slot
    for slot = 1, 19 do
        if GetInventoryItemLink(unit, slot) then
            tip:SetOwner(UIParent, "ANCHOR_NONE")
            tip:ClearLines()
            tip.octoPawnScored = nil
            tip:SetInventoryItem(unit, slot)
            tip:Show()
            local score = OctoPawn_ScoreTooltip(tip, weights)
            tip:Hide()
            if score then total = total + score end
        end
    end
    return total
end

function OctoPawn_TooltipItemName(tip)
    local fs = getglobal(tip:GetName() .. "TextLeft1")
    if fs then
        local t = fs:GetText()
        if t and t ~= "" then return t end
    end
    return "Unknown item"
end

function OctoPawn_PrintBreakdown(title, score, results)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00----- " .. title .. " -----|r")
    if not results or table.getn(results) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900No scored stats.|r")
        return
    end
    local _, r
    for _, r in ipairs(results) do
        local label = (OctoPawn_StatLabel and OctoPawn_StatLabel(r.stat)) or r.stat
        if r.effective and r.effective ~= r.value then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFFFFFFFF%s|r: %.1f (eff %.1f) × %.2f = |cFF00FF00%.1f|r",
                label, r.value, r.effective, r.weight, r.score
            ))
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFFFFFFFF%s|r: %.1f × %.2f = |cFF00FF00%.1f|r",
                label, r.value, r.weight, r.score
            ))
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Total: " .. string.format("%.1f", score) .. "|r")
end

local function FormatSpecDiff(diff)
    if diff > 0.05 then
        return string.format("|cFF00FF00(+%.1f)|r", diff)
    elseif diff < -0.05 then
        return string.format("|cFFFF0000(%.1f)|r", diff)
    else
        return "|cFFAAAAAA(+0.0)|r"
    end
end

-- Short labels for multi-slot compares (rings/trinkets/weapons)
local SHORT_SLOT_LABEL = {
    [11] = "1",   -- Finger 1
    [12] = "2",   -- Finger 2
    [13] = "1",   -- Trinket 1
    [14] = "2",   -- Trinket 2
    [16] = "MH",  -- Main Hand
    [17] = "OH",  -- Off Hand
}

-- Return list of {score, label} for every equipped item in the slot set
local function EquippedScoresForSlots(slots, weights)
    if not slots then return nil end
    local tip = GetScanTooltip()
    local list = {}
    local s
    for _, s in ipairs(slots) do
        if GetInventoryItemLink("player", s) then
            tip:SetOwner(UIParent, "ANCHOR_NONE")
            tip:ClearLines()
            tip.octoPawnScored = nil
            tip:SetInventoryItem("player", s)
            tip:Show()
            local eqScore = OctoPawn_ScoreTooltip(tip, weights)
            tip:Hide()
            local label = SHORT_SLOT_LABEL[s]
            if not label then
                -- single-slot or fallback: omit label prefix
                label = nil
            end
            table.insert(list, { score = eqScore or 0, label = label, slot = s })
        end
    end
    if table.getn(list) == 0 then return nil end
    return list
end

local function AddAllSpecsToTooltip(tooltip)
    local class = OctoPawn_GetClass and OctoPawn_GetClass()
    if not class then return end
    local roles = OctoPawn_GetRolesForClass and OctoPawn_GetRolesForClass(class) or {}
    local currentRole = OctoPawnDB and OctoPawnDB.role
    local slots = OctoPawn_GetCompareSlotsFromTooltip and OctoPawn_GetCompareSlotsFromTooltip(tooltip)
    local compareOn = not (OctoPawnDB and OctoPawnDB.compareEnabled == false)
    local useTipFilter = OctoPawn_AnyTipSpecsEnabled and OctoPawn_AnyTipSpecsEnabled()
    local legacyAll = OctoPawnDB and OctoPawnDB.showAllSpecs and not useTipFilter

    local ri
    for ri = 1, table.getn(roles) do
        local role = roles[ri]
        local show = false
        if useTipFilter then
            show = OctoPawn_IsTipSpec and OctoPawn_IsTipSpec(role)
        elseif legacyAll then
            show = true
        end
        if show then
            local weights = OctoPawn_GetWeightsForRole and OctoPawn_GetWeightsForRole(class, role) or {}
            local score = OctoPawn_ScoreTooltip(tooltip, weights) or 0
            local line = string.format("%s: |cFFFFFFFF%.1f|r", role, score)
            if compareOn and slots then
                local eqList = EquippedScoresForSlots(slots, weights)
                if eqList then
                    local ei
                    for ei = 1, table.getn(eqList) do
                        local eq = eqList[ei]
                        local diffStr = FormatSpecDiff(score - eq.score)
                        if eq.label then
                            line = line .. " " .. diffStr .. eq.label
                        else
                            line = line .. " " .. diffStr
                        end
                    end
                end
            end
            if currentRole and role == currentRole then
                line = line .. " |cFF00FF00(Current)|r"
            end
            tooltip:AddLine(line)
        end
    end
end

-- Last tooltip that successfully received an OP Score (for /op breakdown)
local lastScoredTooltip = nil

-- Slot / armor markers that only appear on item tooltips (not spells/abilities)
local ITEM_SLOT_MARKERS = {
    ["Head"] = true, ["Neck"] = true, ["Shoulder"] = true, ["Shirt"] = true,
    ["Chest"] = true, ["Waist"] = true, ["Legs"] = true, ["Feet"] = true,
    ["Wrist"] = true, ["Hands"] = true, ["Finger"] = true, ["Trinket"] = true,
    ["Back"] = true, ["One-Hand"] = true, ["Main Hand"] = true, ["Off Hand"] = true,
    ["Two-Hand"] = true, ["Held In Off-hand"] = true, ["Ranged"] = true,
    ["Wand"] = true, ["Thrown"] = true, ["Gun"] = true, ["Bow"] = true,
    ["Crossbow"] = true, ["Relic"] = true, ["Tabard"] = true, ["Shield"] = true,
    ["Cloth"] = true, ["Leather"] = true, ["Mail"] = true, ["Plate"] = true,
}
-- Also accept localized INVTYPE_* globals if present
do
    local keys = {
        "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_BODY",
        "INVTYPE_CHEST", "INVTYPE_ROBE", "INVTYPE_WAIST", "INVTYPE_LEGS",
        "INVTYPE_FEET", "INVTYPE_WRIST", "INVTYPE_HAND", "INVTYPE_FINGER",
        "INVTYPE_TRINKET", "INVTYPE_CLOAK", "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND",
        "INVTYPE_WEAPONOFFHAND", "INVTYPE_2HWEAPON", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE",
        "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC",
        "INVTYPE_TABARD",
    }
    local i
    for i = 1, table.getn(keys) do
        local v = getglobal(keys[i])
        if v and type(v) == "string" then ITEM_SLOT_MARKERS[v] = true end
    end
end

-- True only for gear/item tooltips — blocks spells, abilities, talents, units, etc.
local function IsItemTooltip(tooltip)
    if not tooltip or not tooltip.NumLines then return false end

    local num = tooltip:NumLines()
    if not num or num < 1 then return false end

    local hasEquipSlot = false
    local hasEquipEvidence = false
    local isRecipeOrConsume = false
    local isMeterOrUnit = false

    local i
    for i = 1, num do
        local fs = getglobal(tooltip:GetName() .. "TextLeft" .. i)
        if fs then
            local txt = fs:GetText()
            if txt and txt ~= "" then
                if ITEM_SLOT_MARKERS[txt] then
                    hasEquipSlot = true
                end
                local u = string.upper(txt)
                -- Damage/heal/threat meters and unit-style tips
                if string.find(u, "STILL ALIVE")
                    or string.find(u, "STILL DEAD")
                    or string.find(u, "^DAMAGE:")
                    or string.find(u, "^HEALING:")
                    or string.find(u, "^DPS:")
                    or string.find(u, "^TPS:")
                    or string.find(u, "^THREAT:")
                    or string.find(u, "^DURATION:")
                    or string.find(u, "BY SPELL")
                    or string.find(u, "^PET:")
                    or string.find(u, "CURRENT MODE")
                    then
                    isMeterOrUnit = true
                end
                -- Recipes / profession books
                if string.find(u, "TEACHES YOU HOW")
                    or string.find(u, "TEACHES YOU TO")
                    or string.find(u, "^PATTERN:")
                    or string.find(u, "^PLANS:")
                    or string.find(u, "^FORMULA:")
                    or string.find(u, "^SCHEMATIC:")
                    or string.find(u, "^MANUAL:")
                    or string.find(u, "^RECIPE:")
                    or string.find(u, "^DESIGN:")
                    then
                    isRecipeOrConsume = true
                end
                -- Item class lines that are not gear
                if u == "CONSUMABLE" or u == "PROJECTILE" or u == "REAGENT"
                    or u == "TRADE GOODS" or u == "QUEST" or u == "KEY"
                    or u == "RECIPE" or u == "JUNK"
                    then
                    isRecipeOrConsume = true
                end
                -- Equippable evidence that meters never have
                if string.find(u, "DURABILITY")
                    or string.find(u, "^EQUIP:")
                    or string.find(u, "CHANCE ON HIT")
                    or string.find(u, "UNIQUE%-EQUIPPED")
                    then
                    hasEquipEvidence = true
                end
            end
        end
    end

    -- Meters/unit tips must never get an OP Score, even if GameTooltip is reused
    if isMeterOrUnit then
        return false
    end
    if isRecipeOrConsume and not hasEquipSlot then
        return false
    end
    -- Equippable gear: slot line (Head/Finger/Main Hand/…) or Equip:/Durability
    if hasEquipSlot or hasEquipEvidence then
        return true
    end
    return false
end

local function AddScoreToTooltip(tooltip)
    if not tooltip or tooltip.octoPawnScored then return end
    -- Never score our private scan tooltip
    local name = tooltip.GetName and tooltip:GetName()
    if name == "OctoPawnScanTooltip" then return end

    -- Only items — never spells, abilities, talents, or unit tips
    if not IsItemTooltip(tooltip) then
        return
    end

    tooltip.octoPawnScored = true
    local score, results = OctoPawn_ScoreTooltip(tooltip)
    if not results or table.getn(results) == 0 then
        -- No stats found yet (lines may still be loading). Allow a later retry.
        tooltip.octoPawnScored = nil
        return
    end

    lastScoredTooltip = tooltip

    tooltip:AddLine(" ")
    local multi = (OctoPawn_AnyTipSpecsEnabled and OctoPawn_AnyTipSpecsEnabled())
        or (OctoPawnDB and OctoPawnDB.showAllSpecs)
    if multi then
        AddAllSpecsToTooltip(tooltip)
    else
        local compact = OctoPawnDB and OctoPawnDB.compactTooltips
        if compact then
            local line = "|cFF00FF00OP Score: " .. string.format("%.1f", score) .. "|r"
            if OctoPawn_FormatCompactDiffs then
                line = line .. (OctoPawn_FormatCompactDiffs(tooltip, score) or "")
            end
            tooltip:AddLine(line)
        else
            tooltip:AddLine("|cFF00FF00OP Score: " .. string.format("%.1f", score) .. "|r")
            if OctoPawn_ShowComparison then OctoPawn_ShowComparison(tooltip, score) end
        end
    end
    tooltip:Show()
end

-- Find any currently-visible tooltip that has (or can produce) an item OP Score.
-- Used by /op so breakdown works on Aux, Atlas-CFM, ItemRef, etc.
function OctoPawn_GetActiveItemTooltip()
    -- Prefer the one we most recently scored, if still visible and still an item
    if lastScoredTooltip and lastScoredTooltip:IsVisible() and IsItemTooltip(lastScoredTooltip) then
        local _, results = OctoPawn_ScoreTooltip(lastScoredTooltip)
        if results and table.getn(results) > 0 then
            return lastScoredTooltip
        end
    end

    -- Fall back: scan known tooltip frames for a visible ITEM with stats
    local names = {
        "GameTooltip",
        "ItemRefTooltip",
        "AtlasCFMLootTooltip",
        "AtlasCFMLootTooltip2",
        "AtlasLootTooltip",
        "AtlasLootTooltip2",
        "ShoppingTooltip1",
        "ShoppingTooltip2",
        "ComparisonTooltip1",
        "ComparisonTooltip2",
        "AtlasTooltip",
        "LinkWrangler",
    }
    local i
    for i = 1, table.getn(names) do
        local tip = getglobal(names[i])
        if tip and tip.IsVisible and tip:IsVisible() and tip.NumLines then
            local tipName = tip:GetName()
            if tipName ~= "OctoPawnScanTooltip" and IsItemTooltip(tip) then
                local _, results = OctoPawn_ScoreTooltip(tip)
                if results and table.getn(results) > 0 then
                    return tip
                end
            end
        end
    end
    return nil
end

-------------------------------------------------
-- Universal tooltip registration (OnShow path)
-- Catches Aux (manual fill), Atlas-CFM custom
-- frames, ItemRefTooltip, shopping tips, etc.
-------------------------------------------------
local registeredTooltips = {}

local function RegisterTooltip(tip)
    if not tip or type(tip) ~= "table" then return end
    if registeredTooltips[tip] then return end
    -- Only GameTooltip-like frames (have NumLines + TextLeft1)
    if not tip.NumLines or not tip.GetName then return end
    local tipName = tip:GetName()
    if not tipName or tipName == "OctoPawnScanTooltip" then return end
    if not getglobal(tipName .. "TextLeft1") then return end

    registeredTooltips[tip] = true

    local oldShow = tip:GetScript("OnShow")
    tip:SetScript("OnShow", function()
        if oldShow then oldShow() end
        -- Deferred one-frame retry covers addons that Show() before all lines are written
        if this.octoPawnScored then return end
        AddScoreToTooltip(this)
        if not this.octoPawnScored then
            local f = this
            local delay = CreateFrame("Frame")
            local elapsed = 0
            delay:SetScript("OnUpdate", function()
                elapsed = elapsed + arg1
                if elapsed > 0.05 then
                    delay:SetScript("OnUpdate", nil)
                    if f and f:IsVisible() and not f.octoPawnScored then
                        AddScoreToTooltip(f)
                    end
                end
            end)
        end
    end)

    local oldHide = tip:GetScript("OnHide")
    tip:SetScript("OnHide", function()
        this.octoPawnScored = nil
        if lastScoredTooltip == this then
            lastScoredTooltip = nil
        end
        if oldHide then oldHide() end
    end)
end

-- Known tooltip frame names used by Blizzard + common 1.12 addons
local KNOWN_TOOLTIP_NAMES = {
    "GameTooltip",
    "ItemRefTooltip",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "AtlasCFMLootTooltip",
    "AtlasCFMLootTooltip2",
    "AtlasLootTooltip",
    "AtlasLootTooltip2",
    "AtlasTooltip",
    "LinkWrangler",
    "ComparisonTooltip1",
    "ComparisonTooltip2",
}

local function RegisterKnownTooltips()
    local i
    for i = 1, table.getn(KNOWN_TOOLTIP_NAMES) do
        local tip = getglobal(KNOWN_TOOLTIP_NAMES[i])
        if tip then RegisterTooltip(tip) end
    end
end

RegisterKnownTooltips()

-- Re-scan after other addons load (Atlas-CFM, Aux, etc. may create frames late)
local regFrame = CreateFrame("Frame")
regFrame:RegisterEvent("ADDON_LOADED")
regFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
regFrame:SetScript("OnEvent", function()
    RegisterKnownTooltips()
end)

-- Lightweight periodic discovery for late-created custom tooltips (first 30s only)
do
    local discover = CreateFrame("Frame")
    local t = 0
    local ticks = 0
    discover:SetScript("OnUpdate", function()
        t = t + arg1
        if t < 2 then return end
        t = 0
        ticks = ticks + 1
        RegisterKnownTooltips()
        if ticks >= 15 then
            discover:SetScript("OnUpdate", nil)
        end
    end)
end

-------------------------------------------------
-- Keep classic Set* hooks for itemLink + early score
-- (still the fastest path for bags / paperdoll / links)
-------------------------------------------------
local function hook(method, after)
    local orig = GameTooltip[method]
    if not orig then return end
    GameTooltip[method] = function(self, a1, a2, a3, a4, a5)
        self.octoPawnScored = nil
        local result = orig(self, a1, a2, a3, a4, a5)
        if after then after(self, a1, a2) end
        AddScoreToTooltip(self)
        return result
    end
end

hook("SetBagItem", function(self, bag, slot)
    self.itemLink = GetContainerItemLink(bag, slot)
end)
hook("SetInventoryItem", function(self, unit, slot)
    self.itemLink = GetInventoryItemLink(unit, slot)
end)
if GameTooltip.SetHyperlink then
    hook("SetHyperlink", function(self, link) self.itemLink = link end)
end
if GameTooltip.SetAuctionItem then
    hook("SetAuctionItem", function(self, type, index)
        if GetAuctionItemLink then self.itemLink = GetAuctionItemLink(type, index) end
    end)
end
if GameTooltip.SetAuctionSellItem then hook("SetAuctionSellItem") end
if GameTooltip.SetLootRollItem then hook("SetLootRollItem") end
if GameTooltip.SetQuestItem then hook("SetQuestItem") end
if GameTooltip.SetQuestLogItem then hook("SetQuestLogItem") end
if GameTooltip.SetMerchantItem then
    hook("SetMerchantItem", function(self, slot)
        if GetMerchantItemLink then self.itemLink = GetMerchantItemLink(slot) end
    end)
end
if GameTooltip.SetLootItem then
    hook("SetLootItem", function(self, slot)
        if GetLootSlotLink then self.itemLink = GetLootSlotLink(slot) end
    end)
end
if GameTooltip.SetInboxItem then hook("SetInboxItem") end
if GameTooltip.SetTradeSkillItem then hook("SetTradeSkillItem") end
if GameTooltip.SetCraftItem then hook("SetCraftItem") end

print("|cFF00FF00OctoPawn|r scoring core loaded")
