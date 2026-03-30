

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ktrodev/Arcylic/refs/heads/main/src.lua.txt"))()

-- ============================================================================
-- Create Window
-- ============================================================================

local window = Library.new("AcrylicUI Demo", "AcrylicDemoConfigs")

-- Welcome notification
window:Notify({
    Title = "Welcome!",
    Description = "AcrylicUI Demo loaded",
    Duration = 3
})

-- ============================================================================
-- Section: Combat
-- ============================================================================

local combatSection = window:CreateSection("Combat")

-- ============================================================================
-- Tab 1: Aimbot
-- ============================================================================

local aimbotTab = combatSection:CreateTab("Aimbot", "rbxassetid://10723407389")

aimbotTab:CreateSection("General")

local aimbotToggle = aimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "AimbotEnabled",
    Callback = function(enabled)
        print("Aimbot:", enabled)
    end
})

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

aimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = { "Head", "HumanoidRootPart", "Torso", "Random" },
    Default = "Head",
    Flag = "AimbotTarget",
    Callback = function(selected)
        print("Target:", selected)
    end
})

aimbotTab:CreateKeybind({
    Name = "Toggle Key",
    Default = Enum.KeyCode.F,
    Flag = "AimbotKey",
    Callback = function()
        print("Aimbot keybind pressed!")
    end
})

aimbotTab:CreateDivider("Advanced")

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

aimbotTab:CreateToggle({
    Name = "Prediction",
    Default = false,
    Flag = "AimbotPrediction",
    Callback = function(enabled)
        print("Prediction:", enabled)
    end
})

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
-- Tab 2: ESP (Visuals)
-- ============================================================================

local espTab = combatSection:CreateTab("ESP", "rbxassetid://10734898355")

espTab:CreateToggle({
    Name = "Enable ESP",
    Default = false,
    Flag = "ESPEnabled",
    Callback = function(enabled)
        print("ESP:", enabled)
    end
})

espTab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(color)
        print("Color:", color)
    end
})

espTab:CreateDivider("Display Options")

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

espTab:CreateTextBox({
    Name = "Whitelist Player",
    Placeholder = "Enter username...",
    ClearOnFocus = false,
    Flag = "WhitelistPlayer",
    Callback = function(text, enterPressed)
        if enterPressed then
            window:Notify({
                Title = "Whitelisted",
                Description = text .. " added",
                Duration = 2
            })
        end
    end
})

-- ============================================================================
-- Section: Info & Status
-- ============================================================================

local infoSection = window:CreateSection("Info")

-- ============================================================================
-- Tab 3: Live States
-- ============================================================================

local statesTab = infoSection:CreateTab("Live Status")

statesTab:CreateSection("Server Info")

-- Live FPS counter
local fpsLabel = statesTab:CreateLabel({
    Name = "FPS",
    Text = "...",
    Color = Color3.fromRGB(80, 200, 120)
})

-- Live player count
local playerLabel = statesTab:CreateLabel({
    Name = "Players",
    Text = "...",
    Color = Color3.fromRGB(100, 180, 255)
})

-- Live ping
local pingLabel = statesTab:CreateLabel({
    Name = "Ping",
    Text = "...",
    Color = Color3.fromRGB(255, 200, 80)
})

-- Server uptime
local uptimeLabel = statesTab:CreateLabel({
    Name = "Uptime",
    Text = "0s",
    Color = Color3.fromRGB(180, 160, 255)
})

statesTab:CreateDivider("Script Status")

-- Connection status
local statusLabel = statesTab:CreateLabel({
    Name = "Status",
    Text = "Active",
    Color = Color3.fromRGB(80, 200, 120)
})

-- Feature states
local featureLabel = statesTab:CreateLabel({
    Name = "Active Features",
    Text = "0 enabled",
    Color = Color3.fromRGB(200, 200, 200)
})

statesTab:CreateDivider()

statesTab:CreateButton({
    Name = "Toggle Status",
    Callback = function()
        if statusLabel:GetText() == "Active" then
            statusLabel:SetText("Paused")
            statusLabel:SetColor(Color3.fromRGB(255, 80, 80))
        else
            statusLabel:SetText("Active")
            statusLabel:SetColor(Color3.fromRGB(80, 200, 120))
        end
    end
})

statesTab:CreateParagraph({
    Title = "Live Updates",
    Content = "The labels above update in real-time.\nFPS and ping are refreshed every 0.5 seconds.\nPlayer count updates when someone joins or leaves."
})

-- ============================================================================
-- Live update loop
-- ============================================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

-- FPS tracker
local frameCount = 0
local lastFPSUpdate = os.clock()
local startTime = os.clock()

local fpsConnection = RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    
    if now - lastFPSUpdate >= 0.5 then
        -- Update FPS
        local fps = math.floor(frameCount / (now - lastFPSUpdate))
        fpsLabel:SetText(tostring(fps) .. " FPS")
        
        if fps >= 50 then
            fpsLabel:SetColor(Color3.fromRGB(80, 200, 120))
        elseif fps >= 30 then
            fpsLabel:SetColor(Color3.fromRGB(255, 200, 80))
        else
            fpsLabel:SetColor(Color3.fromRGB(255, 80, 80))
        end
        
        -- Update ping
        local success, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if success then
            pingLabel:SetText(tostring(ping) .. "ms")
            if ping < 80 then
                pingLabel:SetColor(Color3.fromRGB(80, 200, 120))
            elseif ping < 150 then
                pingLabel:SetColor(Color3.fromRGB(255, 200, 80))
            else
                pingLabel:SetColor(Color3.fromRGB(255, 80, 80))
            end
        end
        
        -- Update player count
        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        playerLabel:SetText(tostring(playerCount) .. "/" .. tostring(maxPlayers))
        
        -- Update uptime
        local elapsed = math.floor(now - startTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        if mins > 0 then
            uptimeLabel:SetText(tostring(mins) .. "m " .. tostring(secs) .. "s")
        else
            uptimeLabel:SetText(tostring(secs) .. "s")
        end
        
        frameCount = 0
        lastFPSUpdate = now
    end
end)

-- Player count change listener
Players.PlayerAdded:Connect(function(player)
    local count = #Players:GetPlayers()
    playerLabel:SetText(tostring(count) .. "/" .. tostring(Players.MaxPlayers))
    window:Notify({
        Title = "Player Joined",
        Description = player.Name .. " joined the server",
        Duration = 2
    })
end)

Players.PlayerRemoving:Connect(function(player)
    task.defer(function()
        local count = #Players:GetPlayers()
        playerLabel:SetText(tostring(count) .. "/" .. tostring(Players.MaxPlayers))
    end)
end)

-- ============================================================================
-- Section: Settings
-- ============================================================================

local settingsSection = window:CreateSection("Settings")

-- ============================================================================
-- Tab 4: Themes
-- ============================================================================

local themeTab = settingsSection:CreateTab("Themes")

themeTab:CreateSection("Theme Preset")

themeTab:CreateDropdown({
    Name = "Select Theme",
    Options = window:GetThemeNames(),
    Default = "Dark",
    Callback = function(selected)
        window:SetTheme(selected)
    end
})

themeTab:CreateDivider("Available Themes")

themeTab:CreateParagraph({
    Title = "Theme Presets",
    Content = "Dark — Pure dark (default)\nMidnight — Deep blue-purple night\nOcean — Teal-cyan deep sea\nPurple — Rich violet\nRed — Crimson dark\nEmerald — Forest green\nRose — Pink-magenta"
})

themeTab:CreateDivider()

themeTab:CreateButton({
    Name = "Cycle All Themes",
    Callback = function()
        local themes = window:GetThemeNames()
        task.spawn(function()
            for _, theme in ipairs(themes) do
                window:SetTheme(theme)
                task.wait(1.5)
            end
            window:SetTheme("Dark")
        end)
    end
})

themeTab:CreateDivider("Background Image")

local bgImageBox = themeTab:CreateTextBox({
    Name = "Image Asset ID",
    Placeholder = "rbxassetid://123456789",
    Default = "",
    Callback = function() end
})

themeTab:CreateButton({
    Name = "Set Background Image",
    Callback = function()
        local imgId = bgImageBox:GetText()
        if imgId ~= "" then
            window:SetBackgroundImage(imgId, 0.85)
            window:Notify({
                Title = "Background Set",
                Description = "Image applied behind blur",
                Duration = 2
            })
        end
    end
})

themeTab:CreateButton({
    Name = "Remove Background",
    Callback = function()
        window:SetBackgroundImage(nil)
        window:Notify({
            Title = "Background Removed",
            Description = "Reverted to default",
            Duration = 2
        })
    end
})

themeTab:CreateSlider({
    Name = "Image Opacity",
    Min = 0,
    Max = 100,
    Default = 85,
    Callback = function(value)
        if window._bgImage then
            window._bgImage.ImageTransparency = value / 100
        end
    end
})

-- ============================================================================
-- Tab 5: Notifications
-- ============================================================================

local notifTab = settingsSection:CreateTab("Notifications")

notifTab:CreateParagraph({
    Title = "Notification System",
    Content = "Test different notification styles below."
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
            Title = "Important",
            Description = "This one lasts longer!",
            Duration = 6
        })
    end
})

notifTab:CreateButton({
    Name = "Quick Toast",
    Callback = function()
        window:Notify({
            Title = "Quick!",
            Description = "Gone in a flash",
            Duration = 1.5
        })
    end
})

notifTab:CreateButton({
    Name = "Spam Test (5x)",
    Callback = function()
        for i = 1, 5 do
            window:Notify({
                Title = "Notification #" .. i,
                Description = "Testing stacking",
                Duration = 3
            })
        end
    end
})

-- ============================================================================
-- Tab 6: Config
-- ============================================================================

local configTab = settingsSection:CreateTab("Config")

configTab:CreateConfigSection()

configTab:CreateParagraph({
    Title = "Config System",
    Content = "All components with a 'Flag' are auto-saved.\nUse controls above to manage configurations.\nStored as JSON in AcrylicConfigs/."
})

-- ============================================================================
-- Tab 7: About
-- ============================================================================

local aboutTab = settingsSection:CreateTab("About")

aboutTab:CreateParagraph({
    Title = "AcrylicUI",
    Content = "A modern Roblox UI library with:\n• Glassmorphism & acrylic blur\n• 7 built-in theme presets\n• Live status labels\n• Config save/load system\n• Smooth animations\n• Mobile support"
})

aboutTab:CreateDivider("Controls")

aboutTab:CreateLabel({
    Name = "Toggle Key",
    Text = "Right Control",
    Color = Color3.fromRGB(180, 180, 255)
})

aboutTab:CreateLabel({
    Name = "Version",
    Text = "v2.2.0",
    Color = Color3.fromRGB(80, 200, 120)
})

aboutTab:CreateDivider()

aboutTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        window:Notify({
            Title = "Goodbye!",
            Description = "Closing in 2 seconds...",
            Duration = 2
        })
        task.delay(2, function()
            if fpsConnection then
                fpsConnection:Disconnect()
            end
            window:Destroy()
        end)
    end
})

--[[
    API REFERENCE:
    
    WINDOW:
    window:Toggle()                          -- Toggle visibility
    window:SetToggleKey(keyCode)             -- Change toggle key
    window:SetTheme("Ocean")                 -- Switch theme preset
    window:GetThemeNames()                   -- Get available themes
    window:SetBackgroundImage(imageId, 0.85) -- Set bg image (0-1 transparency)
    window:SetBackgroundImage(nil)           -- Remove bg image
    window:Notify({...})                     -- Show notification
    window:SaveConfig("name")                -- Save config
    window:LoadConfig("name")                -- Load config
    window:DeleteConfig("name")              -- Delete config
    window:Destroy()                         -- Clean up everything
    
    COMPONENTS:
    toggle:SetValue(true/false)
    slider:SetValue(50)
    dropdown:SetValue("Head")
    textBox:SetText("hello")
    label:SetText("new text")
    label:SetColor(Color3.new(1,0,0))
    label:GetText()
    
    SEARCH:
    Type in the sidebar search box to filter ALL components
    across ALL tabs. Click a result to jump to that tab.
    
    THEMES: Dark, Midnight, Ocean, Purple, Red, Emerald, Rose
]]
