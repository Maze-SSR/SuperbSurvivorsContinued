-- SuperSurvivorTablesUtilities.lua
-- Handles safe saving and loading of survivor-related data tables

local isLocalLoggingEnabled = false

--- Gets the full file path for a given save filename
---@param fileName string Any file name
---@return string Full file path
local function getFileFullPath(fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "getFileFullPath() called")
    return getWorld():getWorld() .. getFileSeparator() .. fileName
end

--- Checks whether a file exists in the save directory
---@param fileName string File name to check
---@return boolean True if file exists
function DoesFileExist(fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "DoesFileExist() called")
    local readFile = getModFileReader(ModId, getFileFullPath(fileName), false)
    if readFile then
        readFile:close()
        return true
    else
        return false
    end
end

--- Returns a random value from a table
---@param t table Source table
---@return any Random value from the table
function table.randFrom(t)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "table.randFrom() called")
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    local randKey = ZombRand(1, #keys)
    return keys[randKey]
end

--- Loads a line-by-line table from a .lua file
---@param fileName string Filename without extension
---@return table|nil Table of strings or nil
function table.load(fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "table.load() called")
    local fileTable = {}
    local readFile = getModFileReader(ModId, getFileFullPath(fileName .. ".lua"), true)

    if readFile then
        local line = readFile:readLine()
        while line do
            table.insert(fileTable, line)
            line = readFile:readLine()
        end
        readFile:close()
    else
        return nil
    end

    return fileTable
end

--- Saves a line-by-line table to a .lua file
---@param tbl table Table of strings
---@param fileName string Filename without extension
function table.save(tbl, fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "table.save() called")
    local path = getFileFullPath(fileName .. ".lua")
    local writeFile = getModFileWriter(ModId, path, true, false)

    if not writeFile then
        CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "Failed to open file for writing")
        return
    end

    for i = 1, #tbl do
        writeFile:write(tbl[i] .. "\n")
    end
    writeFile:close()
end

--- Loads a key-value table from a file
---@param fileName string Filename
---@return table Table of key-value pairs
function KVTableLoad(fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "KVTableLoad() called")
    local fileTable = {}
    local readFile = getModFileReader(ModId, getFileFullPath(fileName), true)

    if not readFile then return {} end

    local line = readFile:readLine()
    while line do
        local key, value = line:match("^(%S+)%s+(%S+)$")
        if key and value then
            fileTable[key] = value
        end
        line = readFile:readLine()
    end
    readFile:close()

    return fileTable
end

--- Saves a key-value table to a file
---@param fileTable table Table of key-value pairs
---@param fileName string Filename
---@return boolean True if successful
function KVTablesave(fileTable, fileName)
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "KVTablesave() called")
    if not fileTable then
        CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "fileTable is nil")
        return false
    end

    local writeFile = getModFileWriter(ModId, getFileFullPath(fileName), true, false)
    if not writeFile then
        CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "Failed to open file for writing")
        return false
    end

    for key, value in pairs(fileTable) do
        writeFile:write(tostring(key) .. " " .. tostring(value) .. "\n")
    end
    writeFile:close()
    return true
end

--- Returns the directory path where mod save files are stored
---@return string Full save directory path
function GetModSaveDir()
    CreateLogLine("SuperSurvivorTablesUtilities", isLocalLoggingEnabled, "GetModSaveDir() called")
    return Core.getMyDocumentFolder()
        .. getFileSeparator() .. "Saves"
        .. getFileSeparator() .. getWorld():getGameMode()
        .. getFileSeparator() .. getWorld():getWorld()
        .. getFileSeparator()
end
