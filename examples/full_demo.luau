--[[
    AcrylicUI — Full Demo Example
    
    This example demonstrates every feature of the AcrylicUI library
    using the loadstring-compatible bundled version (src.lua.txt).
    
    Components shown:
    - Toggle, Slider, Button, Dropdown
    - Keybind, ColorPicker, TextBox
    - Paragraph, Section Headers
    - Config System (Save/Load/Delete)
    - Notifications
    
    Usage:
    Execute this script in your Roblox executor.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ktrodev/Arcylic/refs/heads/main/src.lua.txt"))()

-- ============================================================================
-- Create Window
-- ============================================================================

local window = Library.new("AcrylicUI Demo", "AcrylicDemoConfigs")

-- Welcome notification
window:Notify({
    Title = "Welcome!",
    Description = "AcrylicUI Demo loaded successfully",
    Duration = 4
})

-- ============================================================================
-- Section: Combat
-- ============================================================================

local combatSection = window:CreateSection("Combat")

-- ============================================================================
-- Tab 1: Aimbot
-- ============================================================================

local aimbotTab = combatSection:CreateTab("Aimbot", "rbxassetid://10723407389")

-- Section header
aimbotTab:CreateSection("General")

-- Toggle
local aimbotToggle = aimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "AimbotEnabled",
    Callback = function(enabled)
        print("Aimbot:", enabled)
    end
})

-- Slider
local fovSlider = aimbotTab:CreateSlider({
    Name = "FOV Range",
    Min = 10,
    Max = 360,
    Default = 90,
    Flag = "AimbotFOV",
    Callback = function(value)
        print("FOV:", value)
    end
})

-- Dropdown (single select)
aimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = { "Head", "HumanoidRootPart", "Torso", "Random" },
    Default = "Head",
    Flag = "AimbotTarget",
    Callback = function(selected)
        print("Target:", selected)
    end
})

-- Keybind
aimbotTab:CreateKeybind({
    Name = "Toggle Key",
    Default = Enum.KeyCode.F,
    Flag = "AimbotKey",
    Callback = function()
        print("Aimbot keybind pressed!")
    end
})

aimbotTab:CreateSection("Advanced")

-- Dropdown (multi-select)
aimbotTab:CreateDropdown({
    Name = "Ignore Teams",
    Options = { "Team 1", "Team 2", "Team 3", "Team 4" },
    Default = {},
    MultiSelect = true,
    Flag = "IgnoredTeams",
    Callback = function(selected)
        if type(selected) == "table" then
            print("Ignoring:", table.concat(selected, ", "))
        end
    end
})

-- Slider
aimbotTab:CreateSlider({
    Name = "Smoothness",
    Min = 1,
    Max = 50,
    Default = 10,
    Flag = "AimbotSmooth",
    Callback = function(value)
        print("Smooth:", value)
    end
})

-- Toggle
aimbotTab:CreateToggle({
    Name = "Prediction",
    Default = false,
    Flag = "AimbotPrediction",
    Callback = function(enabled)
        print("Prediction:", enabled)
    end
})

-- Reset button
aimbotTab:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        aimbotToggle:SetValue(false)
        fovSlider:SetValue(90)
        window:Notify({
            Title = "Reset",
            Description = "Aimbot settings reset",
            Duration = 2
        })
    end
})

-- ============================================================================
-- Tab 2: Silent Aim
-- ============================================================================

local silentTab = combatSection:CreateTab("Silent Aim", "rbxassetid://10734898355")

silentTab:CreateToggle({
    Name = "Enable Silent Aim",
    Default = false,
    Flag = "SilentEnabled",
    Callback = function(enabled)
        print("Silent Aim:", enabled)
    end
})

silentTab:CreateSlider({
    Name = "Hit Chance (%)",
    Min = 0,
    Max = 100,
    Default = 100,
    Flag = "SilentHitChance",
    Callback = function(value)
        print("Hit chance:", value .. "%")
    end
})

silentTab:CreateDropdown({
    Name = "Priority",
    Options = { "Closest", "Lowest HP", "Highest Threat", "Random" },
    Default = "Closest",
    Flag = "SilentPriority",
    Callback = function(selected)
        print("Priority:", selected)
    end
})

silentTab:CreateParagraph({
    Title = "How it works",
    Content = "Silent aim redirects your projectiles to the nearest valid target without visually changing your crosshair position."
})

-- ============================================================================
-- Section: Visuals  
-- ============================================================================

local visualSection = window:CreateSection("Visuals")

-- ============================================================================
-- Tab 3: ESP
-- ============================================================================

local espTab = visualSection:CreateTab("ESP")

espTab:CreateToggle({
    Name = "Enable ESP",
    Default = false,
    Flag = "ESPEnabled",
    Callback = function(enabled)
        print("ESP:", enabled)
    end
})

-- Color Picker
espTab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        print("Color:", color)
    end
})

espTab:CreateSection("Display Options")

espTab:CreateToggle({
    Name = "Show Names",
    Default = true,
    Flag = "ShowNames",
    Callback = function(val) print("Names:", val) end
})

espTab:CreateToggle({
    Name = "Show Health Bars",
    Default = true,
    Flag = "ShowHealth",
    Callback = function(val) print("Health:", val) end
})

espTab:CreateToggle({
    Name = "Show Distance",
    Default = false,
    Flag = "ShowDistance",
    Callback = function(val) print("Distance:", val) end
})

-- TextBox (numbers only)
espTab:CreateTextBox({
    Name = "Max Distance",
    Default = "500",
    Placeholder = "Enter max distance...",
    NumbersOnly = true,
    Flag = "ESPDistance",
    Callback = function(text)
        print("Max distance:", text)
    end
})

-- TextBox (text input)
espTab:CreateTextBox({
    Name = "Whitelist Player",
    Placeholder = "Enter username...",
    ClearOnFocus = false,
    Flag = "WhitelistPlayer",
    Callback = function(text, enterPressed)
        if enterPressed then
            print("Whitelisted:", text)
            window:Notify({
                Title = "Player Added",
                Description = text .. " added to whitelist",
                Duration = 2
            })
        end
    end
})

-- ============================================================================
-- Section: Settings
-- ============================================================================

local settingsSection = window:CreateSection("Settings")

-- ============================================================================
-- Tab 4: Notifications Demo
-- ============================================================================

local notifTab = settingsSection:CreateTab("Notifications")

notifTab:CreateParagraph({
    Title = "Notification System",
    Content = "AcrylicUI includes a built-in notification system. Click the buttons below to test different notification styles."
})

notifTab:CreateButton({
    Name = "Info Notification",
    Callback = function()
        window:Notify({
            Title = "Info",
            Description = "This is an informational message",
            Duration = 3
        })
    end
})

notifTab:CreateButton({
    Name = "Long Notification",
    Callback = function()
        window:Notify({
            Title = "Important Update",
            Description = "This notification lasts longer",
            Duration = 6
        })
    end
})

notifTab:CreateButton({
    Name = "Quick Toast",
    Callback = function()
        window:Notify({
            Title = "Quick!",
            Description = "This disappears fast",
            Duration = 1.5
        })
    end
})

notifTab:CreateButton({
    Name = "Spam Test (5 at once)",
    Callback = function()
        for i = 1, 5 do
            window:Notify({
                Title = "Notification #" .. i,
                Description = "Testing notification stacking",
                Duration = 3
            })
        end
    end
})

-- ============================================================================
-- Tab 5: Config Management
-- ============================================================================

local configTab = settingsSection:CreateTab("Config")

-- Pre-built config section with Save/Load/Delete/Refresh/AutoSave
configTab:CreateConfigSection()

configTab:CreateParagraph({
    Title = "Config System",
    Content = "All components with a 'Flag' are automatically saved.\nUse the controls above to manage your configurations.\nConfigs are stored as JSON files in AcrylicConfigs/."
})

-- ============================================================================
-- Tab 6: About
-- ============================================================================

local aboutTab = settingsSection:CreateTab("About")

aboutTab:CreateParagraph({
    Title = "AcrylicUI",
    Content = "A modern Roblox UI library with glassmorphism,\nsmooth animations, and a built-in config system.\n\nVersion: 2.0.0\nToggle Key: Right Control"
})

aboutTab:CreateButton({
    Name = "Toggle Key: RightControl",
    Callback = function()
        window:Notify({
            Title = "Toggle Key",
            Description = "Press Right Control to show/hide the UI",
            Duration = 3
        })
    end
})

aboutTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        window:Notify({
            Title = "Goodbye!",
            Description = "UI will close in 2 seconds...",
            Duration = 2
        })
        task.delay(2, function()
            window:Destroy()
        end)
    end
})

--[[
    NOTES:
    
    KEYBOARD SHORTCUTS:
    - RightControl: Toggle window visibility
    - Any keybind you set: Triggers the callback
    
    CONFIG SYSTEM:
    All components with a "Flag" field are automatically tracked.
    Use the Config tab to save/load/delete configurations.
    Configs are stored as JSON files in AcrylicConfigs/.
    
    MOBILE:
    A draggable toggle button appears on mobile devices.
    Drag it around the screen, tap to show/hide the UI.
    
    API REFERENCE:
    window:Toggle()              -- Toggle visibility
    window:SetToggleKey(keyCode) -- Change toggle key
    window:SaveConfig("name")   -- Save config
    window:LoadConfig("name")   -- Load config
    window:DeleteConfig("name") -- Delete config
    window:GetConfigs()          -- List saved configs
    window:SetAutoSave(true)     -- Enable auto-save (30s)
    window:Notify({...})         -- Show notification
    window:Destroy()             -- Clean up everything
    
    toggle:SetValue(true/false)
    slider:SetValue(50)
    dropdown:SetValue("Head")
]]
