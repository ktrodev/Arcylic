--[[
    AcrylicUI - Size Constants
    
    Dimension constants for UI components.
    Includes desktop and mobile variants with adaptive sizing.
    All values are in pixels unless otherwise specified.
]]

local UserInputService = game:GetService("UserInputService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Sizes = {
    -- Window dimensions
    Window = {
        Width = isMobile and 380 or 690,
        Height = isMobile and 350 or 446
    },
    
    -- Minimum window size (for resizing)
    MinWindow = {
        Width = isMobile and 300 or 500,
        Height = isMobile and 250 or 300
    },
    
    -- Maximum window size (for resizing)
    MaxWindow = {
        Width = isMobile and 500 or 1200,
        Height = isMobile and 600 or 800
    },
    
    -- Toggle switch dimensions
    Toggle = {
        Width = isMobile and 50 or 38,
        Height = isMobile and 28 or 21,
        Circle = isMobile and 20 or 13
    },
    
    -- Button dimensions
    Button = {
        Height = isMobile and 48 or 39
    },
    
    -- Slider dimensions
    Slider = {
        Height = isMobile and 54 or 46,
        TrackHeight = isMobile and 10 or 7,
        ThumbSize = isMobile and 22 or 14
    },
    
    -- Dropdown dimensions
    Dropdown = {
        Height = isMobile and 48 or 39,
        OptionHeight = isMobile and 40 or 30,
        MaxVisibleOptions = isMobile and 4 or 5
    },
    
    -- Tab dimensions
    Tab = {
        Width = isMobile and 120 or 135,
        Height = isMobile and 40 or 35
    },
    
    -- Color picker dimensions
    ColorPicker = {
        Width = 160,
        Height = 115
    },
    
    -- Notification dimensions
    Notification = {
        Width = isMobile and 260 or 220,
        Height = isMobile and 80 or 70
    },
    
    -- Mobile toggle button
    MobileToggle = {
        Size = 50,
        IconSize = 24
    },
    
    -- Progress bar
    ProgressBar = {
        Height = isMobile and 48 or 39,
        BarHeight = isMobile and 10 or 7
    },
    
    -- Sidebar
    Sidebar = {
        Width = isMobile and 0 or 165, -- 0 = collapsed on mobile
        CollapsedWidth = 0,
        ExpandedWidth = 165
    },
    
    -- Corner radius values
    Corner = {
        Small = 4,
        Medium = 5,
        Large = 6,
        XLarge = 10,
        Full = 100
    },
    
    -- Padding values
    Padding = {
        Small = 5,
        Medium = 10,
        Large = 15
    },
    
    -- Whether mobile mode is active
    IsMobile = isMobile
}

return Sizes