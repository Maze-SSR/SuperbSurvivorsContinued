--[[ 
    SuperSurvivorKeyBindings.lua
    Updated for Build 42 compatibility using addKeyBinding()
    This method is safer and preferred over modifying the keyBinding table directly.

    Credit:
    - Cows: Original keybinding list.
    - Project Zomboid API: https://projectzomboid.com/modding/zombie/core/Core.html#addKeyBinding
--]]

-- Optional: local logging toggle
local isLocalLoggingEnabled = false

-- Add keybindings safely at game boot
local function registerSuperSurvivorKeyBindings()
    CreateLogLine("SuperSurvivorsKeyBindings", isLocalLoggingEnabled, "registerSuperSurvivorKeyBindings() called")

    addKeyBinding("Call Closest Group Member", 55)        -- Numpad *
    addKeyBinding("Call Closest Non-Group Member", 181)   -- Numpad /
    addKeyBinding("Ask Closest Group Member to Follow", 209) -- Page Down
    addKeyBinding("Toggle Group Window", 201)             -- Page Up
    addKeyBinding("Spawn Wild Survivor", 156)             -- Numpad Enter
    addKeyBinding("Lower Follow Distance", 74)            -- Numpad -
    addKeyBinding("Raise Follow Distance", 78)            -- Numpad +
    addKeyBinding("SSHotkey_1", 200)                      -- Up Arrow
    addKeyBinding("SSHotkey_2", 208)                      -- Down Arrow
    addKeyBinding("SSHotkey_3", 203)                      -- Left Arrow
    addKeyBinding("SSHotkey_4", 205)                      -- Right Arrow
    addKeyBinding("NumPad_5", 76)                         -- Numpad 5
end

Events.OnGameBoot.Add(registerSuperSurvivorKeyBindings)