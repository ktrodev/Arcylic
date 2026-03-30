--[[
     Version: 2.2.0                                              
     License: MIT                                                
    
    
    @module AcrylicUI
    @author AcrylicUI Team
    @version 2.2.0
    
    @example
    local AcrylicUI = require(path.to.AcrylicUI)
    
    local window = AcrylicUI.CreateWindow({
        Title = "My Hub",
        ToggleKey = Enum.KeyCode.RightControl,
        ConfigFolder = "MyHubConfigs"
    })
    
    -- Events
    window.OnToggle:Connect(function(visible) print("Visible:", visible) end)
    window.OnTabChanged:Connect(function(oldTab, newTab) print("Tab changed") end)
    
    -- Watermark
    window:CreateWatermark({
        Text = "MyHub v1.0",
        ShowFPS = true,
        ShowPing = true,
        Position = "TopRight"
    })
    
    -- Theme switching
    window:SetTheme("Ocean")
    
    local section = window:CreateSection("Combat")
    local tab = section:CreateTab("Aimbot", "rbxassetid://10723407389")
    
    -- Tab badges
    tab:SetBadge(3)
    
    -- All component types
    tab:CreateToggle({ Name = "Enabled", Flag = "AimbotEnabled", Callback = print })
    tab:CreateSlider({ Name = "FOV", Min = 0, Max = 360, Flag = "AimbotFOV", Callback = print })
    tab:CreateDropdown({ Name = "Target", Options = {"Head", "Torso"}, Flag = "AimbotTarget" })
    tab:CreateTextBox({ Name = "Whitelist", Placeholder = "Player name...", Flag = "Whitelist" })
    tab:CreateSearchBar({ Name = "Search", Items = {"Option1", "Option2"} })
    tab:CreateProgressBar({ Name = "Progress", Max = 100 })
    tab:CreateDivider("Advanced")
    tab:CreateLabel({ Name = "Status", Text = "Active", Color = Color3.fromRGB(80, 200, 120) })
    tab:CreateKeybind({ Name = "Toggle Key", Default = Enum.KeyCode.F, Flag = "AimbotKey" })
    tab:CreateColorPicker({ Name = "Color", Default = Color3.fromRGB(255, 0, 0), Flag = "AimbotColor" })
    tab:CreateParagraph({ Title = "Info", Content = "Aimbot settings" })
    tab:CreateButton({ Name = "Execute", Callback = function() print("Execute!") end })
    
    -- Config section (pre-built UI)
    local configTab = section:CreateTab("Config")
    configTab:CreateConfigSection()
]]

local AcrylicUI = {}
AcrylicUI.__index = AcrylicUI

-- Version info
AcrylicUI.Version = "2.2.0"
AcrylicUI.Author = "Acrylic"

-- Core modules
local Window = require(script.Core.Window)

-- Constants (exposed for customization)
AcrylicUI.Colors = require(script.Constants.Colors)
AcrylicUI.Sizes = require(script.Constants.Sizes)
AcrylicUI.Fonts = require(script.Constants.Fonts)
AcrylicUI.Animation = require(script.Constants.Animation)

-- Utilities (exposed for advanced usage)
AcrylicUI.Utils = {
    Create = require(script.Utils.Create),
    Tween = require(script.Utils.Tween),
    Draggable = require(script.Utils.Draggable),
    Device = require(script.Utils.Device),
    Signal = require(script.Utils.Signal),
    Gesture = require(script.Utils.Gesture)
}

--[[
    Creates a new window
    
    @param config WindowConfig - Configuration options
    @return Window - The created window instance
    
    Features:
    - Adaptive layout (desktop floating window, mobile bottom sheet)
    - Swipe gesture navigation on mobile
    - Config save/load system
    - Event system (OnToggle, OnTabChanged, OnMinimize, OnConfigSaved)
    - Watermark / FPS counter
    - Loading screen animation
    - Runtime theme switching
]]
function AcrylicUI.CreateWindow(config: Window.WindowConfig)
    return Window.new(config)
end

--[[
    Creates a custom theme by merging overrides with defaults
    
    @param overrides table - Color overrides
    @return table - Complete theme colors
]]
function AcrylicUI.CreateTheme(overrides: { [string]: any })
    return AcrylicUI.Colors.CreateTheme(overrides)
end

--[[
    Gets the names of all built-in theme presets
    
    @return { string } - Array of preset names
    
    @example
    local presets = AcrylicUI.GetThemePresets()
    -- {"Dark", "Emerald", "Midnight", "Ocean", "Purple", "Red", "Rose"}
]]
function AcrylicUI.GetThemePresets(): { string }
    return AcrylicUI.Colors.GetPresetNames()
end

--[[
    Gets library information
    
    @return table - Library info
]]
function AcrylicUI.GetInfo()
    return {
        Version = AcrylicUI.Version,
        Author = AcrylicUI.Author,
        Components = {
            "Window", "Section", "Tab",
            "Button", "Toggle", "Slider",
            "Dropdown", "Keybind", "ColorPicker",
            "TextBox", "SearchBar", "ProgressBar",
            "Divider", "Label", "Paragraph",
            "Notification", "Watermark"
        },
        ThemePresets = AcrylicUI.Colors.GetPresetNames()
    }
end

return AcrylicUI