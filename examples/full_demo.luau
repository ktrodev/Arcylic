--[[
    AcrylicUI v2.2.0 — Full Example
    
    This example demonstrates every feature of the AcrylicUI library:
    - All 14 component types
    - Config save/load system
    - Watermark / FPS counter
    - Theme switching
    - Tab badges
    - Events
    - Mobile support (automatic)
    
    Usage:
    Place in a Roblox script and require the library path.
]]

local AcrylicUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ktrodev/Arcylic/refs/heads/main/src.lua.txt"))()

-- ============================================================================
-- Create Window
-- ============================================================================

local window = AcrylicUI.CreateWindow({
    Title = "AcrylicUI Demo",
    Size = { Width = 700, Height = 450 },
    ToggleKey = Enum.KeyCode.RightControl,  -- Press RCtrl to toggle
    ConfigFolder = "AcrylicDemo"             -- Folder name for saved configs
})

-- ============================================================================
-- Watermark (FPS / Ping overlay)
-- ============================================================================

window:CreateWatermark({
    Text = "AcrylicUI v2.2",
    ShowFPS = true,
    ShowPing = true,
    ShowTime = true,
    Position = "TopRight"  -- "TopLeft", "TopRight", "BottomLeft", "BottomRight"
})

-- ============================================================================
-- Events
-- ============================================================================

window.OnToggle:Connect(function(visible)
    print("[AcrylicUI] Window toggled:", visible)
end)

window.OnTabChanged:Connect(function(oldTab, newTab)
    print("[AcrylicUI] Tab changed")
end)

window.OnMinimize:Connect(function(minimized)
    print("[AcrylicUI] Minimized:", minimized)
end)

window.OnConfigSaved:Connect(function(configName)
    print("[AcrylicUI] Config saved:", configName)
end)

-- ============================================================================
-- Section: Main Features
-- ============================================================================

local mainSection = window:CreateSection("Main")

-- ============================================================================
-- Tab 1: Toggles & Buttons
-- ============================================================================

local combatTab = mainSection:CreateTab("Combat", "rbxassetid://10723407389")

-- Toggle
local aimbotToggle = combatTab:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "AimbotEnabled",  -- Flag for config saving
    Callback = function(enabled)
        print("Aimbot:", enabled)
    end
})

-- Slider
local fovSlider = combatTab:CreateSlider({
    Name = "FOV Range",
    Min = 10,
    Max = 360,
    Default = 90,
    Increment = 5,
    Flag = "AimbotFOV",
    Callback = function(value)
        print("FOV:", value)
    end
})

-- Dropdown (single select)
combatTab:CreateDropdown({
    Name = "Target Part",
    Options = { "Head", "HumanoidRootPart", "Torso", "Random" },
    Default = "Head",
    Flag = "AimbotTarget",
    Callback = function(selected)
        print("Target:", selected)
    end
})

-- Dropdown (multi-select)
combatTab:CreateDropdown({
    Name = "Ignore Teams",
    Options = { "Team 1", "Team 2", "Team 3", "Team 4" },
    Default = {},
    MultiSelect = true,
    Flag = "IgnoredTeams",
    Callback = function(selected)
        print("Ignoring:", table.concat(selected, ", "))
    end
})

-- Keybind
combatTab:CreateKeybind({
    Name = "Toggle Key",
    Default = Enum.KeyCode.F,
    Flag = "AimbotKey",
    Callback = function()
        print("Aimbot keybind pressed!")
    end
})

-- Button
combatTab:CreateButton({
    Name = "Reset Settings",
    Callback = function()
        aimbotToggle:SetValue(false)
        fovSlider:SetValue(90)
        window:Notify({
            Title = "Reset",
            Description = "Settings reset to default",
            Type = "info",
            Duration = 2
        })
    end
})

-- ============================================================================
-- Tab 2: Visual Components
-- ============================================================================

local visualTab = mainSection:CreateTab("Visuals", "rbxassetid://10734898355")

-- Color Picker (full HSV)
visualTab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        print("Color:", color)
    end
})

-- TextBox
visualTab:CreateTextBox({
    Name = "Whitelist Player",
    Placeholder = "Enter username...",
    ClearOnFocus = false,
    Flag = "WhitelistPlayer",
    Callback = function(text, enterPressed)
        if enterPressed then
            print("Whitelisted:", text)
        end
    end
})

-- TextBox (numbers only)
visualTab:CreateTextBox({
    Name = "ESP Distance",
    Placeholder = "Enter max distance...",
    Default = "500",
    NumbersOnly = true,
    Flag = "ESPDistance",
    Callback = function(text)
        print("Distance:", text)
    end
})

-- Divider with text
visualTab:CreateDivider("Display Options")

-- Toggle
visualTab:CreateToggle({
    Name = "Show Names",
    Default = true,
    Flag = "ShowNames",
    Callback = function(val) print("Names:", val) end
})

visualTab:CreateToggle({
    Name = "Show Health Bars",
    Default = true,
    Flag = "ShowHealth",
    Callback = function(val) print("Health:", val) end
})

visualTab:CreateToggle({
    Name = "Show Distance",
    Default = false,
    Flag = "ShowDistance",
    Callback = function(val) print("Distance:", val) end
})

-- ============================================================================
-- Tab 3: New Components (v2.2.0)
-- ============================================================================

local newTab = mainSection:CreateTab("New v2.2")

-- Set a badge to show it's new!
newTab:SetBadge("NEW")

-- SearchBar
newTab:CreateSearchBar({
    Name = "Search Features",
    Placeholder = "Type to search...",
    Items = {
        "Aimbot", "ESP", "Speed", "Fly", "Noclip",
        "Teleport", "Infinite Jump", "Auto Farm",
        "Kill Aura", "Reach", "Anti-AFK"
    },
    Callback = function(filtered, query)
        print("Search:", query, "Found:", #filtered, "results")
    end
})

-- Divider
newTab:CreateDivider()

-- ProgressBar
local farmProgress = newTab:CreateProgressBar({
    Name = "Farm Progress",
    Max = 100,
    Default = 0,
    Callback = function(value)
        print("Progress:", value)
    end
})

-- Button to simulate progress
newTab:CreateButton({
    Name = "Simulate Farm (+10)",
    Callback = function()
        farmProgress:Increment(10)
        if farmProgress:GetValue() >= 100 then
            window:Notify({
                Title = "Farm Complete!",
                Description = "Reached 100%",
                Type = "success",
                Duration = 3
            })
            farmProgress:SetValue(0) -- Reset
        end
    end
})

-- Divider with text
newTab:CreateDivider("Status Info")

-- Labels
local statusLabel = newTab:CreateLabel({
    Name = "Connection",
    Text = "Connected",
    Color = Color3.fromRGB(80, 200, 120)
})

newTab:CreateLabel({
    Name = "Players",
    Text = "12 online",
    Color = Color3.fromRGB(100, 180, 255)
})

newTab:CreateLabel({
    Name = "Server",
    Text = "US-East",
    Color = Color3.fromRGB(255, 200, 80)
})

-- Button to toggle status
newTab:CreateButton({
    Name = "Toggle Status",
    Callback = function()
        if statusLabel:GetText() == "Connected" then
            statusLabel:SetText("Disconnected")
            statusLabel:SetColor(Color3.fromRGB(255, 80, 80))
        else
            statusLabel:SetText("Connected")
            statusLabel:SetColor(Color3.fromRGB(80, 200, 120))
        end
    end
})

-- Paragraph
newTab:CreateParagraph({
    Title = "What's New in v2.2.0",
    Content = "• Full mobile support (bottom sheet, swipe navigation)\n• SearchBar, ProgressBar, Divider, Label components\n• 7 theme presets with runtime switching\n• Watermark / FPS counter\n• Tab badges\n• Event system"
})

-- ============================================================================
-- Section: Settings
-- ============================================================================

local settingsSection = window:CreateSection("Settings")

-- ============================================================================
-- Tab 4: Theme Settings
-- ============================================================================

local themeTab = settingsSection:CreateTab("Themes")

-- Theme selector
themeTab:CreateDropdown({
    Name = "Theme Preset",
    Options = AcrylicUI.GetThemePresets(),
    Default = "Dark",
    Callback = function(selected)
        window:SetTheme(selected)
    end
})

themeTab:CreateDivider("Available Themes")

themeTab:CreateParagraph({
    Title = "Theme Presets",
    Content = "Dark — Pure dark (default)\nMidnight — Deep blue-purple\nOcean — Teal-cyan\nPurple — Rich violet\nRed — Crimson\nEmerald — Forest green\nRose — Pink-magenta"
})

-- ============================================================================
-- Tab 5: Notifications Demo
-- ============================================================================

local notifTab = settingsSection:CreateTab("Notifications")

notifTab:CreateButton({
    Name = "Info Notification",
    Callback = function()
        window:Notify({
            Title = "Info",
            Description = "This is an informational message",
            Type = "info",
            Duration = 3
        })
    end
})

notifTab:CreateButton({
    Name = "Success Notification",
    Callback = function()
        window:Notify({
            Title = "Success!",
            Description = "Operation completed successfully",
            Type = "success",
            Duration = 3
        })
    end
})

notifTab:CreateButton({
    Name = "Warning Notification",
    Callback = function()
        window:Notify({
            Title = "Warning",
            Description = "Something might need attention",
            Type = "warning",
            Duration = 3
        })
    end
})

notifTab:CreateButton({
    Name = "Error Notification",
    Callback = function()
        window:Notify({
            Title = "Error",
            Description = "Something went wrong!",
            Type = "error",
            Duration = 3
        })
    end
})

-- ============================================================================
-- Tab 6: Config Management
-- ============================================================================

local configTab = settingsSection:CreateTab("Config")

-- This creates a full pre-built config UI with:
-- Config name input, saved configs dropdown,
-- Save/Load/Delete/Refresh buttons, and Auto-save toggle
configTab:CreateConfigSection()

-- ============================================================================
-- Initial notification
-- ============================================================================

window:Notify({
    Title = "Welcome!",
    Description = "AcrylicUI v2.2.0 loaded successfully",
    Type = "success",
    Duration = 4
})

-- ============================================================================
-- Notes
-- ============================================================================

--[[
    MOBILE SUPPORT:
    On mobile devices, the UI automatically:
    - Renders as a bottom sheet (slides up from bottom)
    - Shows a draggable toggle button when hidden
    - Supports swipe left/right to change tabs
    - Uses larger touch targets for all components
    - Shows tab indicator dots at the bottom
    - Has a hamburger menu for the sidebar
    
    KEYBOARD SHORTCUTS:
    - RightControl: Toggle window visibility
    - Any keybind you set: Triggers the callback
    
    CONFIG SYSTEM:
    All components with a "Flag" field are automatically tracked.
    Use the Config tab to save/load/delete configurations.
    Configs are stored as JSON files in the executor's filesystem.
    
    PROGRAMMATIC CONTROL:
    window:Toggle()           -- Toggle visibility
    window:SetTheme("Ocean")  -- Switch theme
    window:SaveConfig("name") -- Save config
    window:LoadConfig("name") -- Load config
    window:Destroy()          -- Clean up everything
    
    toggle:SetValue(true)     -- Set component values
    slider:SetValue(50)
    dropdown:SetValue("Head")
    textBox:SetText("hello")
    progress:SetValue(75)
    label:SetText("New text")
    label:SetColor(Color3.new(1,0,0))
]]
