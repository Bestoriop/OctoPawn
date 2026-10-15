-------------------------------------------------
-- OctoPawn Defaults/Helpers.lua
-------------------------------------------------
defaultWeights = defaultWeights or {}

function OctoPawn_Merge(base, over)
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    if over then for k, v in pairs(over) do t[k] = v end end
    return t
end

-- User-facing labels (config, /op breakdown). Internal keys stay the same.
function OctoPawn_StatLabel(stat)
    if not stat then return "" end
    local map = {
        DPS              = "WEAPON DPS",
        CRIT             = "CRIT %",
        HIT              = "HIT %",
        DODGE            = "DODGE %",
        PARRY            = "PARRY %",
        BLOCK            = "BLOCK %",
        HASTE            = "HASTE %",
        ["SPELL CRIT"]   = "SPELL CRIT %",
        ["SPELL HIT"]    = "SPELL HIT %",
        ["RANGED CRIT"]  = "RANGED CRIT %",
        ["RANGED HASTE"] = "RANGED HASTE %",
        ["HOLY CRIT"]    = "HOLY CRIT %",
        AVOIDANCE        = "AVOIDANCE %",
        RESILIENCE       = "RESILIENCE %",
        ["EXTRA ATTACK"] = "EXTRA ATTACK %",
        LIFESTEAL        = "LIFESTEAL %",
        ["CASTING REGEN"] = "CASTING REGEN %",
        ["MOVEMENT SPEED"] = "MOVEMENT SPEED %",
        ["MOUNT SPEED"]  = "MOUNT SPEED %",
    }
    return map[stat] or stat
end

function OctoPawn_Fill(t)
    local keys = {
        "STRENGTH","AGILITY","STAMINA","INTELLECT","SPIRIT","ARMOR","DEFENSE",
        "DODGE","PARRY","BLOCK","BLOCK VALUE","ATTACK POWER","RANGED ATTACK POWER",
        "HIT","CRIT","DPS","HASTE","EXTRA ATTACK","ARMOR PENETRATION","LIFESTEAL",
        "FORTUNE","AVOIDANCE","RESILIENCE","FERAL ATTACK POWER","ATTACK POWER UNDEAD","SPELL DAMAGE UNDEAD",
        "RANGED HASTE","RANGED CRIT","HOLY CRIT","MOUNT SPEED","MOVEMENT SPEED",
        "HEALTH","MANA","HEALTH PER 5","MANA PER 5","CASTING REGEN",
        "SPELL POWER","SPELL DAMAGE","HEALING","SPELL HIT","SPELL CRIT","SPELL PENETRATION",
        "SHADOW DAMAGE","FIRE DAMAGE","FROST DAMAGE","NATURE DAMAGE","ARCANE DAMAGE","HOLY DAMAGE",
        "FIRE RESISTANCE","FROST RESISTANCE","SHADOW RESISTANCE","NATURE RESISTANCE",
        "ARCANE RESISTANCE","ALL RESISTANCES",
        "SWORDS","AXES","MACES","DAGGERS","FIST WEAPONS","POLEARMS","STAVES",
        "BOWS","GUNS","CROSSBOWS","THROWN","WANDS",
    }
    local i
    for i = 1, table.getn(keys) do
        if t[keys[i]] == nil then t[keys[i]] = 0 end
    end
    return t
end
