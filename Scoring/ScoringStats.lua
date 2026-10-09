-------------------------------------------------
-- OctoPawn Scoring/ScoringStats.lua
-------------------------------------------------
OctoPawn_StatPatterns = {
    { pattern = "DAMAGE AND HEALING DONE BY MAGICAL SPELLS", stat = "SPELL POWER" },
    { pattern = "DAMAGE AND HEALING DONE BY SPELLS",         stat = "SPELL POWER" },
    { pattern = "DAMAGE DONE BY SHADOW SPELLS",  stat = "SHADOW DAMAGE" },
    { pattern = "DAMAGE DONE BY FIRE SPELLS",    stat = "FIRE DAMAGE" },
    { pattern = "DAMAGE DONE BY FROST SPELLS",   stat = "FROST DAMAGE" },
    { pattern = "DAMAGE DONE BY NATURE SPELLS",  stat = "NATURE DAMAGE" },
    { pattern = "DAMAGE DONE BY ARCANE SPELLS",  stat = "ARCANE DAMAGE" },
    { pattern = "DAMAGE DONE BY HOLY SPELLS",    stat = "HOLY DAMAGE" },
    { pattern = "NATURE SPELL DAMAGE",  stat = "NATURE DAMAGE" },
    { pattern = "FIRE SPELL DAMAGE",    stat = "FIRE DAMAGE" },
    { pattern = "FROST SPELL DAMAGE",   stat = "FROST DAMAGE" },
    { pattern = "SHADOW SPELL DAMAGE",  stat = "SHADOW DAMAGE" },
    { pattern = "ARCANE SPELL DAMAGE",  stat = "ARCANE DAMAGE" },
    { pattern = "HOLY SPELL DAMAGE",    stat = "HOLY DAMAGE" },
    { pattern = "NATURE DAMAGE",        stat = "NATURE DAMAGE" },
    { pattern = "FIRE DAMAGE",          stat = "FIRE DAMAGE" },
    { pattern = "FROST DAMAGE",         stat = "FROST DAMAGE" },
    { pattern = "SHADOW DAMAGE",        stat = "SHADOW DAMAGE" },
    { pattern = "ARCANE DAMAGE",        stat = "ARCANE DAMAGE" },
    { pattern = "HOLY DAMAGE",          stat = "HOLY DAMAGE" },
    { pattern = "INCREASES HEALING DONE",        stat = "HEALING" },
    { pattern = "HEALING DONE BY SPELLS",        stat = "HEALING" },
    { pattern = "HEALING SPELLS %+",             stat = "HEALING" },  -- enchant : "Healing Spells +55"
    { pattern = "DAMAGE DEALT IS RETURNED AS HEALING", stat = "LIFESTEAL" },
    { pattern = "RETURNED AS HEALING",                 stat = "LIFESTEAL" },
    { pattern = "VAMPIRISM",                           stat = "LIFESTEAL" },
    { pattern = "VAMPIRIC",                            stat = "LIFESTEAL" },
    { pattern = "DECREASES THE MAGICAL RESISTANCES OF YOUR SPELL TARGETS", stat = "SPELL PENETRATION" },
    { pattern = "DECREASES THE MAGICAL RESISTANCES",                     stat = "SPELL PENETRATION" },
    { pattern = "SPELL PENETRATION",                                    stat = "SPELL PENETRATION" },
    { pattern = "YOUR ATTACKS IGNORE",                     stat = "ARMOR PENETRATION" },
    { pattern = "IGNORE .* OF THE TARGET'S ARMOR",         stat = "ARMOR PENETRATION" },
    { pattern = "ARMOR PENETRATION",                       stat = "ARMOR PENETRATION" },
    { pattern = "INCREASES YOUR ATTACK AND CASTING SPEED", stat = "HASTE" },
    { pattern = "ATTACK AND CASTING SPEED",                stat = "HASTE" },
    { pattern = "INCREASES YOUR ATTACK SPEED",             stat = "HASTE" },
    { pattern = "INCREASES YOUR CASTING SPEED",            stat = "HASTE" },
    { pattern = "CHANCE TO GRANT .* EXTRA ATTACK",         stat = "EXTRA ATTACK" },
    { pattern = "CHANCE TO GET .* EXTRA ATTACK",           stat = "EXTRA ATTACK" },
    { pattern = "CHANCE ON HIT TO GRANT .* EXTRA ATTACK",  stat = "EXTRA ATTACK" },
    { pattern = "CHANCE OF GETTING AN EXTRA ATTACK",       stat = "EXTRA ATTACK" },
    { pattern = "% CHANCE .* EXTRA ATTACK",                stat = "EXTRA ATTACK" },
    { pattern = "GRANT .* EXTRA ATTACK",                   stat = "EXTRA ATTACK" },
    { pattern = "EXTRA ATTACK",                            stat = "EXTRA ATTACK" },
    { pattern = "CHANCE TO TRIGGER CHANCE BASED ITEM EFFECTS", stat = "FORTUNE" },
    { pattern = "TRIGGER EFFECTS FROM EQUIPPED ITEMS",         stat = "FORTUNE" },
    { pattern = "TRIGGER CHANCE BASED ITEM EFFECTS",           stat = "FORTUNE" },
    { pattern = "INCREASES YOUR CHANCE TO TRIGGER",            stat = "FORTUNE" },
    { pattern = "DAMAGE YOU TAKE FROM AREA OF EFFECT",     stat = "AVOIDANCE" },
    { pattern = "DAMAGE FROM AREA OF EFFECT",              stat = "AVOIDANCE" },
    { pattern = "AREA OF EFFECT ATTACKS BY",               stat = "AVOIDANCE" },
    { pattern = "AVOIDANCE",                               stat = "AVOIDANCE" },
    -- Resilience: crit/DoT damage taken reduction (e.g. Loop of Triage)
    { pattern = "DAMAGE TAKEN FROM CRITICAL HITS AND DAMAGE OVER TIME", stat = "RESILIENCE" },
    { pattern = "DAMAGE TAKEN FROM CRITICAL HITS",         stat = "RESILIENCE" },
    { pattern = "CRITICAL HITS AND DAMAGE OVER TIME",      stat = "RESILIENCE" },
    { pattern = "DAMAGE FROM CRITICAL HITS",               stat = "RESILIENCE" },
    { pattern = "RESILIENCE",                              stat = "RESILIENCE" },
    { pattern = "ATTACK POWER IN CAT, BEAR, DIRE BEAR, AND MOONKIN", stat = "FERAL ATTACK POWER" },
    { pattern = "ATTACK POWER IN CAT, BEAR",               stat = "FERAL ATTACK POWER" },
    { pattern = "ATTACK POWER IN CAT",                     stat = "FERAL ATTACK POWER" },
    { pattern = "ATTACK POWER IN BEAR",                    stat = "FERAL ATTACK POWER" },
    { pattern = "FERAL ATTACK POWER",                      stat = "FERAL ATTACK POWER" },
    { pattern = "ATTACK POWER VERSUS UNDEAD",              stat = "ATTACK POWER UNDEAD" },
    { pattern = "ATTACK POWER AGAINST UNDEAD",             stat = "ATTACK POWER UNDEAD" },
    { pattern = "SPELL DAMAGE VERSUS UNDEAD",              stat = "SPELL DAMAGE UNDEAD" },
    { pattern = "SPELL DAMAGE AGAINST UNDEAD",             stat = "SPELL DAMAGE UNDEAD" },
    { pattern = "DAMAGE TO UNDEAD",                        stat = "SPELL DAMAGE UNDEAD" },
    { pattern = "CHANCE TO HIT WITH SPELLS",               stat = "SPELL HIT" },
    { pattern = "HIT WITH SPELLS",                         stat = "SPELL HIT" },
    { pattern = "SPELL HIT",                               stat = "SPELL HIT" },
    { pattern = "IMPROVES YOUR CHANCE TO HIT",             stat = "HIT" },
    { pattern = "INCREASES YOUR CHANCE TO HIT",            stat = "HIT" },
    { pattern = "INCREASE TO HIT",                         stat = "HIT" },
    { pattern = "TO HIT BY",                               stat = "HIT" },
    { pattern = "CRITICAL STRIKE WITH SPELLS",             stat = "SPELL CRIT" },
    { pattern = "CRITICAL STRIKE WITH HOLY",               stat = "HOLY CRIT" },
    { pattern = "CRITICAL STRIKE WITH RANGED",             stat = "RANGED CRIT" },
    { pattern = "RANGED CRITICAL",                         stat = "RANGED CRIT" },
    { pattern = "STRENGTH",              stat = "STRENGTH" },
    { pattern = "AGILITY",               stat = "AGILITY" },
    { pattern = "STAMINA",               stat = "STAMINA" },
    { pattern = "INTELLECT",             stat = "INTELLECT" },
    { pattern = "SPIRIT",                stat = "SPIRIT" },
    { pattern = "RANGED ATTACK POWER",   stat = "RANGED ATTACK POWER" },
    { pattern = "ATTACK POWER",          stat = "ATTACK POWER" },
    { pattern = "SPELL DAMAGE",          stat = "SPELL DAMAGE" },
    { pattern = "SPELL POWER",           stat = "SPELL POWER" },
    { pattern = "SPELL CRIT",            stat = "SPELL CRIT" },
    { pattern = "HEALTH PER 5",          stat = "HEALTH PER 5" },
    { pattern = "MANA PER 5",            stat = "MANA PER 5" },
    { pattern = "MANA REGENERATION TO CONTINUE WHILE CASTING", stat = "CASTING REGEN" },
    { pattern = "REGENERATION TO CONTINUE WHILE CASTING",     stat = "CASTING REGEN" },
    { pattern = "CONTINUE WHILE CASTING",                     stat = "CASTING REGEN" },
    { pattern = "WHILE CASTING",                              stat = "CASTING REGEN" },
    { pattern = "^%s*HP%s*%+",           stat = "HEALTH" },  -- enchant : "HP +100"
    { pattern = "INCREASES HEALTH",      stat = "HEALTH" },
    { pattern = "HEALTH",                stat = "HEALTH" },
    { pattern = "INCREASES MANA",        stat = "MANA" },
    { pattern = "MANA",                  stat = "MANA" },
    { pattern = "DAMAGE PER SECOND",     stat = "DPS" },
    { pattern = "DPS",                   stat = "DPS" },
    { pattern = "CRIT",                  stat = "CRIT" },
    { pattern = "DEFENSE",               stat = "DEFENSE" },
    { pattern = "DODGE",                 stat = "DODGE" },
    { pattern = "PARRY",                 stat = "PARRY" },
    { pattern = "BLOCK VALUE",           stat = "BLOCK VALUE" },
    { pattern = "BLOCK",                 stat = "BLOCK" },
    { pattern = "ARMOR",                 stat = "ARMOR" },
    { pattern = "ARMOR",                 stat = "ARMOR BONUS" },
    { pattern = "TO ALL RESISTANCES",    stat = "ALL RESISTANCES" },
    { pattern = "ALL RESISTANCES",       stat = "ALL RESISTANCES" },
    { pattern = "ALL RESISTANCE",        stat = "ALL RESISTANCES" },
    { pattern = "FIRE RESISTANCE",       stat = "FIRE RESISTANCE" },
    { pattern = "FROST RESISTANCE",      stat = "FROST RESISTANCE" },
    { pattern = "SHADOW RESISTANCE",     stat = "SHADOW RESISTANCE" },
    { pattern = "NATURE RESISTANCE",     stat = "NATURE RESISTANCE" },
    { pattern = "ARCANE RESISTANCE",     stat = "ARCANE RESISTANCE" },
    { pattern = "RANGED ATTACK SPEED",   stat = "RANGED HASTE" },
    { pattern = "MOUNT SPEED",           stat = "MOUNT SPEED" },
    { pattern = "RUN SPEED",             stat = "MOVEMENT SPEED" },
    { pattern = "MOVEMENT SPEED",        stat = "MOVEMENT SPEED" },
    { pattern = "TO SWORDS",             stat = "SWORDS" },
    { pattern = "TO AXES",               stat = "AXES" },
    { pattern = "TO MACES",              stat = "MACES" },
    { pattern = "TO DAGGERS",            stat = "DAGGERS" },
    { pattern = "TO FIST WEAPONS",       stat = "FIST WEAPONS" },
    { pattern = "TO POLEARMS",           stat = "POLEARMS" },
    { pattern = "TO STAVES",             stat = "STAVES" },
    { pattern = "TO BOWS",               stat = "BOWS" },
    { pattern = "TO GUNS",               stat = "GUNS" },
    { pattern = "TO CROSSBOWS",          stat = "CROSSBOWS" },
    { pattern = "TO THROWN",             stat = "THROWN" },
    { pattern = "TO WANDS",              stat = "WANDS" },
}

function OctoPawn_ExtractNumberNearStat(line, upper, pattern)
    local startPos = string.find(upper, pattern)
    if not startPos then return nil end
    local after = string.sub(line, startPos)
    local _, _, numAfter = string.find(after, "([%+%-]?%d+%.?%d*)")
    if numAfter then return tonumber(numAfter) end
    local before = string.sub(line, 1, startPos - 1)
    local lastNum = nil
    for n in string.gfind(before, "([%+%-]?%d+%.?%d*)") do lastNum = n end
    if lastNum then return tonumber(lastNum) end
    return nil
end

function OctoPawn_IsSetBonusLine(upper)
    if string.find(upper, "%)%s*SET%s*:") then return true end
    if string.find(upper, "^SET%s*:") then return true end
    if string.find(upper, "SET BONUS") then return true end
    return false
end

-------------------------------------------------
-- Detection des enchants (option "Ignore enchants")
-------------------------------------------------
-- Motifs (MAJUSCULES, motifs Lua) TOUJOURS consideres comme un enchant,
-- quelle que soit la couleur de la ligne. A alimenter au fur et a mesure.
OctoPawn_EnchantPatterns = {
    -- "^CRUSADER",
}

-- Motifs JAMAIS consideres comme un enchant (garde-fou si une ligne verte
-- legitime est exclue a tort). A alimenter au fur et a mesure.
OctoPawn_EnchantExceptions = {
}

local function StripColorCodes(upper)
    local s = string.gsub(upper, "|C%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|R", "")
    return s
end

-- upper : texte de la ligne en majuscules ; r, g, b : couleur de la ligne
function OctoPawn_IsEnchantLine(upper, r, g, b)
    if not upper then return false end
    local text = StripColorCodes(upper)
    local i
    for i = 1, table.getn(OctoPawn_EnchantExceptions) do
        if string.find(text, OctoPawn_EnchantExceptions[i]) then return false end
    end
    for i = 1, table.getn(OctoPawn_EnchantPatterns) do
        if string.find(text, OctoPawn_EnchantPatterns[i]) then return true end
    end
    -- Heuristique : ligne verte qui n'est ni un effet Equip / Use / Chance on hit,
    -- ni un bonus de set
    if r and g and b and r < 0.35 and g > 0.8 and b < 0.35 then
        if string.find(text, "^%s*EQUIP%s*:") or string.find(text, "^%s*USE%s*:")
            or string.find(text, "^%s*CHANCE ON HIT") then
            return false
        end
        if OctoPawn_IsSetBonusLine and OctoPawn_IsSetBonusLine(text) then return false end
        return true
    end
    return false
end

print("|cFF00FF00OctoPawn|r scoring stats loaded")
