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

function OctoPawn_MeleeDPS(o)
    return OctoPawn_Fill(OctoPawn_Merge({
        STRENGTH = 1.0, AGILITY = 1.0, STAMINA = 0.45, INTELLECT = 0.05, SPIRIT = 0.05,
        ARMOR = 0.01, DEFENSE = 0.15, DODGE = 1.2, PARRY = 1.2, BLOCK = 0.2, ["BLOCK VALUE"] = 0.1,
        ["ATTACK POWER"] = 1.0, ["RANGED ATTACK POWER"] = 0.15,
        HIT = 2.2, CRIT = 2.2, DPS = 1.6, HASTE = 2.0, ["EXTRA ATTACK"] = 3.0,
        ["ARMOR PENETRATION"] = 1.1, LIFESTEAL = 1.4, FORTUNE = 1.0, AVOIDANCE = 0.35,
        ["ATTACK POWER UNDEAD"] = 0.4, HEALTH = 0.045, ["HEALTH PER 5"] = 0.25,
        ["FIRE RESISTANCE"] = 0.12, ["FROST RESISTANCE"] = 0.12, ["SHADOW RESISTANCE"] = 0.12,
        ["NATURE RESISTANCE"] = 0.12, ["ARCANE RESISTANCE"] = 0.12, ["ALL RESISTANCES"] = 0.45,
        ["MOUNT SPEED"] = 0.08, ["MOVEMENT SPEED"] = 0.2,
    }, o))
end

function OctoPawn_Tank(o)
    return OctoPawn_Fill(OctoPawn_Merge({
        STRENGTH = 0.85, AGILITY = 0.85, STAMINA = 1.6, INTELLECT = 0.1, SPIRIT = 0.1,
        ARMOR = 0.02, DEFENSE = 2.6, DODGE = 2.6, PARRY = 2.4, BLOCK = 2.1, ["BLOCK VALUE"] = 1.15,
        ["ATTACK POWER"] = 0.45, HIT = 1.6, CRIT = 0.7, DPS = 0.45, HASTE = 0.6,
        ["EXTRA ATTACK"] = 0.8, ["ARMOR PENETRATION"] = 0.3, LIFESTEAL = 1.0,
        FORTUNE = 0.5, AVOIDANCE = 1.6, HEALTH = 0.16, ["HEALTH PER 5"] = 0.9,
        ["FIRE RESISTANCE"] = 0.25, ["FROST RESISTANCE"] = 0.25, ["SHADOW RESISTANCE"] = 0.25,
        ["NATURE RESISTANCE"] = 0.25, ["ARCANE RESISTANCE"] = 0.25, ["ALL RESISTANCES"] = 0.9,
        ["MOUNT SPEED"] = 0.08, ["MOVEMENT SPEED"] = 0.15,
    }, o))
end

function OctoPawn_CasterDPS(o)
    return OctoPawn_Fill(OctoPawn_Merge({
        STRENGTH = 0.05, AGILITY = 0.05, STAMINA = 0.4, INTELLECT = 1.05, SPIRIT = 0.55,
        ARMOR = 0.005, DEFENSE = 0.1, DODGE = 0.15,
        DPS = 0.1, HASTE = 1.6, LIFESTEAL = 0.25, FORTUNE = 0.85, AVOIDANCE = 0.3,
        ["SPELL DAMAGE UNDEAD"] = 0.4, HEALTH = 0.04, MANA = 0.09,
        ["HEALTH PER 5"] = 0.2, ["MANA PER 5"] = 1.15, ["CASTING REGEN"] = 2.0,
        ["SPELL POWER"] = 1.0, ["SPELL DAMAGE"] = 1.0, HEALING = 0.25,
        ["SPELL HIT"] = 2.6, ["SPELL CRIT"] = 2.1, ["SPELL PENETRATION"] = 1.25,
        ["FIRE RESISTANCE"] = 0.12, ["FROST RESISTANCE"] = 0.12, ["SHADOW RESISTANCE"] = 0.12,
        ["NATURE RESISTANCE"] = 0.12, ["ARCANE RESISTANCE"] = 0.12, ["ALL RESISTANCES"] = 0.45,
        ["MOUNT SPEED"] = 0.08, ["MOVEMENT SPEED"] = 0.2,
    }, o))
end

function OctoPawn_Healer(o)
    return OctoPawn_Fill(OctoPawn_Merge({
        STRENGTH = 0.05, AGILITY = 0.05, STAMINA = 0.55, INTELLECT = 1.1, SPIRIT = 1.25,
        ARMOR = 0.006, DEFENSE = 0.15, DODGE = 0.2,
        DPS = 0.08, HASTE = 1.25, LIFESTEAL = 0.2, FORTUNE = 0.5, AVOIDANCE = 0.35,
        HEALTH = 0.055, MANA = 0.1, ["HEALTH PER 5"] = 0.3, ["MANA PER 5"] = 1.5,
        ["CASTING REGEN"] = 2.6, ["SPELL POWER"] = 0.55, ["SPELL DAMAGE"] = 0.3,
        HEALING = 1.35, ["SPELL HIT"] = 0.4, ["SPELL CRIT"] = 1.25, ["SPELL PENETRATION"] = 0.2,
        ["FIRE RESISTANCE"] = 0.12, ["FROST RESISTANCE"] = 0.12, ["SHADOW RESISTANCE"] = 0.12,
        ["NATURE RESISTANCE"] = 0.12, ["ARCANE RESISTANCE"] = 0.12, ["ALL RESISTANCES"] = 0.5,
        ["MOUNT SPEED"] = 0.08, ["MOVEMENT SPEED"] = 0.2,
    }, o))
end
