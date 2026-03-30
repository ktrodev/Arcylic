--[[
    AcrylicUI - Configuration Manager
    
    Save, load, and manage configuration profiles using executor filesystem APIs.
    Supports auto-save, multiple profiles, and per-component Flag registration.
]]

local HttpService = game:GetService("HttpService")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

export type ConfigManagerObject = {
    RegisterFlag: (self: ConfigManagerObject, flag: string, component: any) -> (),
    SaveConfig: (self: ConfigManagerObject, configName: string) -> boolean,
    LoadConfig: (self: ConfigManagerObject, configName: string) -> boolean,
    DeleteConfig: (self: ConfigManagerObject, configName: string) -> boolean,
    GetConfigs: (self: ConfigManagerObject) -> { string },
    SetAutoSave: (self: ConfigManagerObject, enabled: boolean) -> (),
    Destroy: (self: ConfigManagerObject) -> ()
}

--[[
    Creates a new ConfigManager instance
    
    @param configFolder string - Name of the folder to store configs in
    @return ConfigManagerObject
]]
function ConfigManager.new(configFolder: string?): ConfigManagerObject
    local self = setmetatable({}, ConfigManager)
    
    self._folderName = "AcrylicConfigs/" .. (configFolder or "Default")
    self._flags = {} -- { [flagName] = componentRef }
    self._autoSave = false
    self._autoSaveThread = nil
    
    -- Ensure folder exists
    self:_EnsureFolder()
    
    return self
end

function ConfigManager:_EnsureFolder()
    local ok = pcall(function()
        if not isfolder(self._folderName) then
            makefolder(self._folderName)
        end
    end)
    if not ok then
        -- Folder creation not available (Studio mode)
        -- parent folder
        pcall(function()
            if not isfolder("AcrylicConfigs") then
                makefolder("AcrylicConfigs")
            end
            if not isfolder(self._folderName) then
                makefolder(self._folderName)
            end
        end)
    end
end

function ConfigManager:_GetFilePath(configName: string): string
    return self._folderName .. "/" .. configName .. ".json"
end

--[[
    Registers a component with a flag for config saving
    
    @param flag string - Unique identifier
    @param component any - Component with GetValue/SetValue methods
]]
function ConfigManager:RegisterFlag(flag: string, component: any)
    if flag and flag ~= "" then
        self._flags[flag] = component
    end
end

--[[
    Serializes the current value of a component for JSON storage
]]
function ConfigManager:_SerializeValue(value: any): any
    if typeof(value) == "Color3" then
        return {
            _type = "Color3",
            R = math.floor(value.R * 255),
            G = math.floor(value.G * 255),
            B = math.floor(value.B * 255)
        }
    elseif typeof(value) == "EnumItem" then
        return {
            _type = "EnumItem",
            EnumType = tostring(value.EnumType),
            Name = value.Name
        }
    end
    return value
end

--[[
    Deserializes a value from JSON storage
]]
function ConfigManager:_DeserializeValue(value: any): any
    if type(value) == "table" then
        if value._type == "Color3" then
            return Color3.fromRGB(value.R, value.G, value.B)
        elseif value._type == "EnumItem" then
            local success, result = pcall(function()
                return Enum[value.EnumType][value.Name]
            end)
            if success then return result end
        end
    end
    return value
end

--[[
    Saves the current settings to a config file
    
    @param configName string - Name of the config
    @return boolean - Success
]]
function ConfigManager:SaveConfig(configName: string): boolean
    local data = {}
    
    for flag, component in pairs(self._flags) do
        local success, value = pcall(function()
            if component.GetValue then
                return component:GetValue()
            elseif component.GetColor then
                return component:GetColor()
            elseif component.GetText then
                return component:GetText()
            end
            return nil
        end)
        
        if success and value ~= nil then
            data[flag] = self:_SerializeValue(value)
        end
    end
    
    local success = pcall(function()
        local json = HttpService:JSONEncode(data)
        writefile(self:_GetFilePath(configName), json)
    end)
    
    return success
end

--[[
    Loads settings from a config file
    
    @param configName string - Name of the config to load
    @return boolean - Success
]]
function ConfigManager:LoadConfig(configName: string): boolean
    local success = pcall(function()
        local path = self:_GetFilePath(configName)
        if not isfile(path) then
            error("Config file not found: " .. configName)
        end
        
        local json = readfile(path)
        local data = HttpService:JSONDecode(json)
        
        for flag, rawValue in pairs(data) do
            local component = self._flags[flag]
            if component then
                local value = self:_DeserializeValue(rawValue)
                pcall(function()
                    if component.SetValue then
                        component:SetValue(value)
                    elseif component.SetColor then
                        component:SetColor(value)
                    elseif component.SetText then
                        component:SetText(tostring(value))
                    elseif component.SetKey then
                        component:SetKey(value)
                    end
                end)
            end
        end
    end)
    
    return success
end

--[[
    Deletes a config file
    
    @param configName string - Name of the config to delete
    @return boolean - Success
]]
function ConfigManager:DeleteConfig(configName: string): boolean
    local success = pcall(function()
        local path = self:_GetFilePath(configName)
        if isfile(path) then
            delfile(path)
        end
    end)
    return success
end

--[[
    Returns a list of available config names
    
    @return { string } - Array of config names
]]
function ConfigManager:GetConfigs(): { string }
    local configs = {}
    
    pcall(function()
        if isfolder(self._folderName) then
            local files = listfiles(self._folderName)
            for _, filePath in ipairs(files) do
                local fileName = filePath:match("([^/\\]+)$")
                if fileName and fileName:match("%.json$") then
                    local configName = fileName:gsub("%.json$", "")
                    table.insert(configs, configName)
                end
            end
        end
    end)
    
    return configs
end

--[[
    Enables or disables auto-save (saves every 30 seconds)
    
    @param enabled boolean - Enable or disable
]]
function ConfigManager:SetAutoSave(enabled: boolean)
    self._autoSave = enabled
    
    if self._autoSaveThread then
        task.cancel(self._autoSaveThread)
        self._autoSaveThread = nil
    end
    
    if enabled then
        self._autoSaveThread = task.spawn(function()
            while self._autoSave do
                task.wait(30)
                if self._autoSave then
                    self:SaveConfig("autosave")
                end
            end
        end)
    end
end

--[[
    Destroys the config manager and cleans up
]]
function ConfigManager:Destroy()
    if self._autoSave then
        -- Final save before destroy
        pcall(function()
            self:SaveConfig("autosave")
        end)
    end
    
    self._autoSave = false
    if self._autoSaveThread then
        task.cancel(self._autoSaveThread)
        self._autoSaveThread = nil
    end
    
    table.clear(self._flags)
end

return ConfigManager
