-------------------------------------------------
-- OctoPawn Commands.lua
-------------------------------------------------
SLASH_OCTOPAWN1 = "/op"
SlashCmdList["OCTOPAWN"] = function(msg)
    msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))
    if msg == "help" or msg == "?" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op|r - Score the hovered item only")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op compare|r - Toggle equip compare")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op profile|r - Profile picker")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op reset|r - Reset weights to profile defaults")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/op help|r - This help")
        return
    end
    if msg == "compare" then
        if not OctoPawnDB then OctoPawnDB = {} end
        if OctoPawnDB.compareEnabled == false then
            OctoPawnDB.compareEnabled = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Compare enabled.|r")
        else
            OctoPawnDB.compareEnabled = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900OctoPawn: Compare disabled.|r")
        end
        if OctoPawn_RefreshCompareButton then OctoPawn_RefreshCompareButton() end
        return
    end
    if msg == "profile" or msg == "profiles" or msg == "spec" then
        if OctoPawn_ShowRolePicker then OctoPawn_ShowRolePicker() end
        return
    end
    if msg == "reset" then
        local role = OctoPawnDB and OctoPawnDB.role
        if role and OctoPawn_ApplyRole then
            OctoPawn_ApplyRole(role, false)
        else
            local defaults = OctoPawn_GetDefaultWeights and OctoPawn_GetDefaultWeights() or {}
            if not OctoPawnDB then OctoPawnDB = {} end
            OctoPawnDB.weights = {}
            for stat, value in pairs(defaults) do OctoPawnDB.weights[stat] = value end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00OctoPawn: Weights reset to defaults.|r")
        end
        return
    end
    -- Prefer any visible tooltip that already has (or can produce) an OP Score
    -- (GameTooltip, AtlasCFMLootTooltip, ItemRefTooltip, Aux-filled tips, etc.)
    local tip = OctoPawn_GetActiveItemTooltip and OctoPawn_GetActiveItemTooltip() or nil
    if not tip then
        if GameTooltip and GameTooltip:IsShown() then
            tip = GameTooltip
        end
    end
    if not tip then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: Hover an item first.|r")
        return
    end
    local score, results = OctoPawn_ScoreTooltip(tip)
    if not results or table.getn(results) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000OctoPawn: No item stats on the current tooltip.|r")
        return
    end
    local name = OctoPawn_TooltipItemName and OctoPawn_TooltipItemName(tip) or "Item"
    OctoPawn_PrintBreakdown(name, score, results)
end
print("|cFF00FF00OctoPawn|r commands loaded")
