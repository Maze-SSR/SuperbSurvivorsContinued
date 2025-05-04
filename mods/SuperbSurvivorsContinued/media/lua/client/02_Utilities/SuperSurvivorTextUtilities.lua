-- SuperSurvivorTextUtilities.lua
-- Utility functions to fetch localized strings for the Survivors Reborn mod.

--- Returns localized text for UI actions (prefix: IGUI_SS_)
--- Used in UI elements and action prompts.
---@param text string
---@return string
function Get_SS_UIActionText(text)
    local result = getText("IGUI_SS_" .. text)
    if result == "IGUI_SS_" .. text then
        print("⚠️ Missing localization for IGUI_SS_" .. text)
    end
    return result
end

--- Returns localized name for a moodle or survivor-specific name (prefix: Moodles_SS_)
--- Formerly 'getName()', renamed to avoid conflict with core functions.
---@param name string
---@return string
function Get_SS_Name(name)
    local result = getText("Moodles_SS_" .. name)
    if result == "Moodles_SS_" .. name then
        print("⚠️ Missing localization for Moodles_SS_" .. name)
    end
    return result
end

--- WIP - Cows: Frankly, I don't understand why "ContextMenus_SS_" prefix is needed.
---@param text string
---@return string
function Get_SS_ContextMenuText(text)
    local result = getText("ContextMenu_SS_" .. text)
    if result == "ContextMenu_SS_" .. text then
        print("⚠️ Missing localization for ContextMenu_SS_" .. text)
    end
    return result
end

--- Returns localized job name from context menu (prefix: ContextMenu_SS_Job_)
--- Cut and pasted here from SuperSurvivorsContextMenu.lua to fix load order issues.
---@param text string
---@return string
function Get_SS_JobText(text)
    return Get_SS_ContextMenuText("Job_" .. text)
end

--- Returns localized dialogue line (prefix: GameSound_Dialogues_SS_)
---@param text string
---@return string
function Get_SS_Dialogue(text)
    local result = getText("GameSound_Dialogues_SS_" .. text)
    if result == "GameSound_Dialogues_SS_" .. text then
        print("⚠️ Missing localization for GameSound_Dialogues_SS_" .. text)
    end
    return result
end
