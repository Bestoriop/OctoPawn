-------------------------------------------------
-- Defaults/Druid/Restoration.lua based on https://krokats.github.io/resto-sim/
-------------------------------------------------
defaultWeights.DRUID = defaultWeights.DRUID or {}
defaultWeights.DRUID.Restoration = OctoPawn_Fill({
    HEALING = 1, SPIRIT = 0.46, ["INTELLECT"] = 0.3, ["SPELL CRIT"] = 10, ["MANA PER 5"] = 3
})
