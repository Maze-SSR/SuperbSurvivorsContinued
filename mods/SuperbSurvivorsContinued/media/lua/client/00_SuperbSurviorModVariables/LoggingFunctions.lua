ModId = "SuperbSurvivorsContinued";

--[[
    Credit to "haram gaming#4572" in PZ Discord for providing a text file writing example.
    Credit to "albion#0123" for explaining the difference between getFileWriter and getModFileWriter.
    CreateLogLine will create a log file under "<user>/Zomboid/Lua/<ModId>/logs".
--]]
function CreateLogLine(fileName, isEnabled, newLine)
    if isEnabled then
        local timestamp = os.time()
        local formattedTimeDay = os.date("%Y-%m-%d", timestamp)
        local formattedTime = os.date("%Y-%m-%d %H:%M:%S", timestamp)
        local file = getFileWriter(
            ModId .. "/logs/" .. formattedTimeDay .. "_" .. ModId .. "_" .. fileName .. "_Logs.txt",
            true,
            true
        )

        local content = formattedTime .. " : " .. "CreateLogLine called"
        if newLine then
            content = formattedTime .. " : " .. newLine
        end

        file:write(content .. "\r\n")
        file:close()
    end
end

--[[
    Log the key-value pairs of a table to a specified file.
-- ]]
function LogTableKVPairs(fileName, isEnabled, inputTable)
    if (isEnabled) then
        for key, value in pairs(inputTable) do
            CreateLogLine(fileName, isEnabled, "key:" .. tostring(key) .. " | value: " .. tostring(value));
        end
    end
end

-- Example usage:
-- CreateLogLine("SS_Debugger", true, "Start...");
