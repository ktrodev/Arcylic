--[[
    AcrylicUI - Color Constants
    
    Default theme colors for the UI library.
    Supports dark mode with acrylic/glass aesthetics.
    Includes built-in theme presets and runtime theme switching.
]]

local Colors = {
    -- Primary colors
    Background = Color3.fromRGB(12, 12, 12),
    Secondary = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(39, 39, 39),
    
    -- Text colors
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(93, 93, 93),
    
    -- Accent color (customizable)
    Accent = Color3.fromRGB(255, 255, 255),
    
    -- Toggle specific colors
    Toggle = {
        Enabled = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(32, 32, 32),
        Circle = Color3.fromRGB(20, 20, 20)
    },
    
    -- Notification specific colors
    Notification = {
        Background = Color3.fromRGB(11, 11, 11),
        Border = Color3.fromRGB(26, 26, 26),
        Timer = Color3.fromRGB(255, 255, 255)
    }
}

-- ============================================================================
-- Built-in Theme Presets
-- ============================================================================

Colors.Presets = {
    Dark = {
        Background = Color3.fromRGB(12, 12, 12),
        Secondary = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(39, 39, 39),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(93, 93, 93),
        Accent = Color3.fromRGB(255, 255, 255),
    },
    
    Midnight = {
        Background = Color3.fromRGB(10, 10, 25),
        Secondary = Color3.fromRGB(18, 18, 40),
        Border = Color3.fromRGB(35, 35, 70),
        Text = Color3.fromRGB(220, 220, 255),
        TextDark = Color3.fromRGB(80, 80, 130),
        Accent = Color3.fromRGB(100, 130, 255),
    },
    
    Ocean = {
        Background = Color3.fromRGB(8, 18, 22),
        Secondary = Color3.fromRGB(14, 28, 35),
        Border = Color3.fromRGB(30, 55, 65),
        Text = Color3.fromRGB(200, 240, 255),
        TextDark = Color3.fromRGB(70, 120, 140),
        Accent = Color3.fromRGB(50, 190, 220),
    },
    
    Purple = {
        Background = Color3.fromRGB(15, 10, 20),
        Secondary = Color3.fromRGB(25, 18, 35),
        Border = Color3.fromRGB(50, 35, 65),
        Text = Color3.fromRGB(240, 220, 255),
        TextDark = Color3.fromRGB(110, 80, 140),
        Accent = Color3.fromRGB(160, 80, 255),
    },
    
    Red = {
        Background = Color3.fromRGB(18, 10, 10),
        Secondary = Color3.fromRGB(30, 18, 18),
        Border = Color3.fromRGB(60, 30, 30),
        Text = Color3.fromRGB(255, 220, 220),
        TextDark = Color3.fromRGB(140, 80, 80),
        Accent = Color3.fromRGB(255, 70, 70),
    },
    
    Emerald = {
        Background = Color3.fromRGB(8, 18, 12),
        Secondary = Color3.fromRGB(14, 28, 20),
        Border = Color3.fromRGB(30, 55, 40),
        Text = Color3.fromRGB(210, 255, 230),
        TextDark = Color3.fromRGB(70, 130, 90),
        Accent = Color3.fromRGB(50, 220, 120),
    },
    
    Rose = {
        Background = Color3.fromRGB(18, 10, 14),
        Secondary = Color3.fromRGB(30, 18, 24),
        Border = Color3.fromRGB(60, 30, 45),
        Text = Color3.fromRGB(255, 220, 235),
        TextDark = Color3.fromRGB(140, 80, 110),
        Accent = Color3.fromRGB(255, 90, 160),
    },
}

--[[
    Creates a custom theme by merging with default colors
    
    @param overrides table - Partial color overrides
    @return table - Complete theme colors
]]
function Colors.CreateTheme(overrides: { [string]: any }?): typeof(Colors)
    if not overrides then
        return Colors
    end
    
    local theme = table.clone(Colors)
    for key, value in pairs(overrides) do
        if type(value) == "table" and type(theme[key]) == "table" then
            theme[key] = table.clone(theme[key])
            for subKey, subValue in pairs(value) do
                theme[key][subKey] = subValue
            end
        else
            theme[key] = value
        end
    end
    
    return theme
end

--[[
    Gets the names of all available theme presets
    
    @return { string }
]]
function Colors.GetPresetNames(): { string }
    local names = {}
    for name in pairs(Colors.Presets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return Colors