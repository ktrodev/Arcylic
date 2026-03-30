--[[
    AcrylicUI - Window Component v2.2.0
    
    The main window container with:
    - Dragging, resizing, minimize support
    - Config system integration
    - Smooth open/close animations
    - Full mobile support (bottom sheet, swipe nav, adaptive layout)
    - Event system (OnToggle, OnTabChanged, OnMinimize)
    - Watermark / FPS overlay
    - Loading screen
    - Tab badge support
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Draggable = require(script.Parent.Parent.Utils.Draggable)
local Device = require(script.Parent.Parent.Utils.Device)
local Signal = require(script.Parent.Parent.Utils.Signal)
local Gesture = require(script.Parent.Parent.Utils.Gesture)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Animation = require(script.Parent.Parent.Constants.Animation)

local AcrylicBlur = require(script.Parent.AcrylicBlur)
local Notification = require(script.Parent.Notification)
local ConfigManager = require(script.Parent.ConfigManager)
local Watermark = require(script.Parent.Watermark)

local Window = {}
Window.__index = Window

export type WindowConfig = {
    Title: string?,
    Size: { Width: number, Height: number }?,
    ToggleKey: Enum.KeyCode?,
    ConfigFolder: string?
}

function Window.new(config: WindowConfig)
    local self = setmetatable({}, Window)
    
    self._title = config.Title or "AcrylicUI"
    self._size = config.Size or { 
        Width = Sizes.Window.Width, 
        Height = Sizes.Window.Height 
    }
    self._toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    self._visible = true
    self._minimized = false
    self._sections = {}
    self._keybinds = {}
    self._connections = {}
    self._currentTab = nil
    self._allTabs = {}
    self._currentTabIndex = 0
    self._originalHeight = self._size.Height
    self._isMobile = Device.IsMobile()
    self._sidebarExpanded = not self._isMobile
    
    -- Config system
    self._configManager = ConfigManager.new(config.ConfigFolder or self._title)
    
    -- Event system
    self.OnToggle = Signal.new()
    self.OnTabChanged = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnConfigSaved = Signal.new()
    self.OnDestroy = Signal.new()
    
    self:_CreateGui()
    self:_SetupKeybinds()
    
    if self._isMobile then
        self:_SetupMobileToggle()
        self:_SetupSwipeNavigation()
    end
    
    self:_PlayLoadingScreen()
    
    return self
end

-- ============================================================================
-- GUI Construction
-- ============================================================================

function Window:_CreateGui()
    local player = Players.LocalPlayer
    
    self._screenGui = Create.Instance("ScreenGui", {
        Name = "AcrylicUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = player:WaitForChild("PlayerGui")
    })
    
    if self._isMobile then
        self:_CreateMobileLayout()
    else
        self:_CreateDesktopLayout()
    end
    
    -- Notification container
    Notification.CreateContainer(self._screenGui)
end

function Window:_CreateDesktopLayout()
    -- Main container
    self._container = Create.Instance("Frame", {
        Name = "Container",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.05,
        Position = UDim2.new(
            0.5, -self._size.Width / 2,
            0.5, -self._size.Height / 2
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(0, self._size.Width, 0, self._size.Height),
        ClipsDescendants = false,
        Parent = self._screenGui
    })
    
    Create.Corner(self._container, Sizes.Corner.Medium)
    Create.Stroke(self._container)
    
    -- Drop shadow
    Create.Instance("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = -1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Parent = self._container
    })
    
    self:_CreateTitleBar()
    self:_CreateContentArea()
    
    -- Draggable
    self._dragConnection = Draggable.Enable(self._container, self._titleLabel)
    
    -- Acrylic blur
    self._acrylicBlur = AcrylicBlur.new(self._container)
end

function Window:_CreateMobileLayout()
    -- Bottom sheet container
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local sheetHeight = math.min(self._size.Height, viewportSize.Y * 0.85)
    
    -- Dim overlay behind sheet
    self._dimOverlay = Create.Instance("Frame", {
        Name = "DimOverlay",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = self._screenGui
    })
    
    self._dimOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self:Toggle()
        end
    end)
    
    -- Bottom sheet
    self._container = Create.Instance("Frame", {
        Name = "Container",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.02,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, sheetHeight),
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = self._screenGui
    })
    
    -- Top rounded corners only
    Create.Instance("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = self._container
    })
    
    -- Drag handle bar
    local handleBar = Create.Instance("Frame", {
        Name = "DragHandle",
        BackgroundColor3 = Colors.TextDark,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 8),
        Size = UDim2.new(0, 40, 0, 4),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = self._container
    })
    Create.Corner(handleBar, 2)
    
    -- Swipe down on handle to minimize
    Gesture.OnSwipe(self._container, function(direction)
        if direction == "Down" then
            self:Toggle()
        end
    end)
    
    self:_CreateTitleBar()
    self:_CreateContentArea()
end

function Window:_CreateTitleBar()
    -- Title
    self._titleLabel = Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = self._title,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self._isMobile and 14 or 14, 0, self._isMobile and 18 or 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = Fonts.Size.Title,
        Size = UDim2.new(0, 150, 0, 25),
        ZIndex = 2,
        Parent = self._container
    })
    
    -- Title accent underline
    Create.Instance("Frame", {
        Name = "TitleAccent",
        BackgroundColor3 = Colors.Accent,
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0, 14, 0, self._isMobile and 41 or 33),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 40, 0, 2),
        ZIndex = 2,
        Parent = self._container
    })
    
    if not self._isMobile then
        self:_CreateWindowControls()
    end
    
    -- Mobile: hamburger menu button for sidebar
    if self._isMobile then
        self._hamburger = Create.Instance("ImageButton", {
            Name = "Hamburger",
            Image = "rbxassetid://112235310154264",
            ImageColor3 = Colors.Text,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 18),
            Size = UDim2.new(0, 22, 0, 22),
            ZIndex = 5,
            Parent = self._container
        })
        
        self._hamburger.MouseButton1Click:Connect(function()
            self:_ToggleSidebar()
        end)
    end
end

function Window:_CreateWindowControls()
    -- Minimize button
    local minimizeBtn = Create.Instance("ImageLabel", {
        Name = "Minimize",
        ImageColor3 = Colors.TextDark,
        Image = "rbxassetid://82603981310445",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -35, 0, 15),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = self._container
    })
    
    local minimizeClick = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 21, 0, 15),
        Parent = minimizeBtn
    })
    
    minimizeClick.MouseButton1Click:Connect(function()
        self:_ToggleMinimize()
    end)
    
    minimizeBtn.MouseEnter:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.Text }, "Fast")
    end)
    minimizeBtn.MouseLeave:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)
    
    -- Close button
    local closeBtn = Create.Instance("ImageButton", {
        Name = "Close",
        ImageColor3 = Colors.TextDark,
        Image = "rbxassetid://119943770201674",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = self._container
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    closeBtn.MouseEnter:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Color3.fromRGB(255, 100, 100) }, "Fast")
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)
    
    -- Resize handle
    self._resizeBtn = Create.Instance("ImageButton", {
        Name = "Resize",
        ImageColor3 = Color3.fromRGB(110, 110, 110),
        Image = "rbxassetid://120997033468887",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.new(0, 62, 0, 60),
        BorderSizePixel = 0,
        Parent = self._container
    })
    
    self:_SetupResize()
end

function Window:_CreateContentArea()
    local headerY = self._isMobile and 50 or 45
    
    -- Header separator
    Create.Instance("Frame", {
        Name = "HeaderSeparator",
        BackgroundColor3 = Colors.Border,
        Position = UDim2.new(0, 0, 0, headerY),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self._container
    })
    
    -- Main content area
    self._mainContent = Create.Instance("Frame", {
        Name = "MainContent",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, headerY + 1),
        Size = UDim2.new(1, 0, 1, -(headerY + 1)),
        ClipsDescendants = true,
        Parent = self._container
    })
    
    local sidebarWidth = self._isMobile and 0 or Sizes.Sidebar.ExpandedWidth
    
    -- Sections sidebar
    self._sectionsContainer = Create.Instance("ScrollingFrame", {
        Name = "Sections",
        ScrollBarThickness = 0,
        BackgroundColor3 = self._isMobile and Colors.Background or Color3.new(0, 0, 0),
        BackgroundTransparency = self._isMobile and 0.02 or 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = not self._isMobile,
        ZIndex = self._isMobile and 20 or 1,
        ClipsDescendants = true,
        Parent = self._mainContent
    })
    
    if self._isMobile then
        Create.Corner(self._sectionsContainer, 10)
    end
    
    Create.ListLayout(self._sectionsContainer, 0)
    Create.Padding(self._sectionsContainer, 5, 5, 5, 5)
    
    -- Sidebar overlay for mobile (when expanded)
    if self._isMobile then
        self._sidebarOverlay = Create.Instance("Frame", {
            Name = "SidebarOverlay",
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 15,
            Parent = self._mainContent
        })
        
        self._sidebarOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                self:_ToggleSidebar()
            end
        end)
    end
    
    -- Separator (desktop only)
    if not self._isMobile then
        Create.Instance("Frame", {
            Name = "Separator",
            BackgroundColor3 = Colors.Border,
            Position = UDim2.new(0, sidebarWidth, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 1, 1, 0),
            Parent = self._mainContent
        })
    end
    
    -- Content area
    self._contentContainer = Create.Instance("ScrollingFrame", {
        Name = "Content",
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self._isMobile and 0 or (sidebarWidth + 1), 0, 0),
        Size = UDim2.new(1, self._isMobile and 0 or -(sidebarWidth + 1), 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self._mainContent
    })
    
    Create.ListLayout(self._contentContainer, 8)
    Create.Padding(self._contentContainer, 10, 10, 15, 15)
    
    -- Mobile: tab indicator dots
    if self._isMobile then
        self._tabIndicator = Create.Instance("Frame", {
            Name = "TabIndicator",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -5),
            Size = UDim2.new(0, 100, 0, 10),
            ZIndex = 10,
            Parent = self._mainContent
        })
        
        Create.Instance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = self._tabIndicator
        })
    end
end

-- ============================================================================
-- Mobile Features
-- ============================================================================

function Window:_ToggleSidebar()
    self._sidebarExpanded = not self._sidebarExpanded
    
    if self._sidebarExpanded then
        self._sectionsContainer.Visible = true
        if self._sidebarOverlay then
            self._sidebarOverlay.Visible = true
        end
        
        self._sectionsContainer.Position = UDim2.new(-0.7, 0, 0, 10)
        self._sectionsContainer.Size = UDim2.new(0.7, 0, 1, -20)
        
        Tween.Create(self._sectionsContainer, {
            Position = UDim2.new(0, 10, 0, 10)
        }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        if self._sidebarOverlay then
            self._sidebarOverlay.Visible = false
        end
        
        Tween.CreateWithCallback(self._sectionsContainer, {
            Position = UDim2.new(-0.7, 0, 0, 10)
        }, 0.2, function()
            self._sectionsContainer.Visible = false
        end)
    end
end

function Window:_SetupMobileToggle()
    self._mobileToggle = Create.Instance("ImageButton", {
        Name = "MobileToggle",
        Image = "rbxassetid://112235310154264",
        ImageColor3 = Colors.Text,
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 15, 0.85, 0),
        Size = UDim2.new(0, Sizes.MobileToggle.Size, 0, Sizes.MobileToggle.Size),
        AnchorPoint = Vector2.new(0, 0.5),
        Visible = false,
        ZIndex = 100,
        Parent = self._screenGui
    })
    
    Create.Corner(self._mobileToggle, Sizes.MobileToggle.Size / 2)
    Create.Stroke(self._mobileToggle)
    
    -- Make draggable with edge snapping
    self._mobileToggleGesture = Gesture.DraggableWithSnap(self._mobileToggle, 10)
    
    self._mobileToggle.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Pulse animation when hidden
    self._pulseThread = nil
end

function Window:_StartPulse()
    if self._pulseThread then return end
    self._pulseThread = task.spawn(function()
        while self._mobileToggle and self._mobileToggle.Visible do
            Tween.Create(self._mobileToggle, { 
                Size = UDim2.new(0, Sizes.MobileToggle.Size + 6, 0, Sizes.MobileToggle.Size + 6) 
            }, "Slow")
            task.wait(0.5)
            Tween.Create(self._mobileToggle, { 
                Size = UDim2.new(0, Sizes.MobileToggle.Size, 0, Sizes.MobileToggle.Size) 
            }, "Slow")
            task.wait(2)
        end
        self._pulseThread = nil
    end)
end

function Window:_StopPulse()
    if self._pulseThread then
        task.cancel(self._pulseThread)
        self._pulseThread = nil
    end
end

function Window:_SetupSwipeNavigation()
    -- Swipe left/right on content to switch tabs
    Gesture.OnSwipe(self._contentContainer, function(direction)
        if direction == "Left" then
            self:NextTab()
        elseif direction == "Right" then
            self:PreviousTab()
        end
    end)
end

function Window:_UpdateTabIndicator()
    if not self._tabIndicator then return end
    
    -- Clear old dots
    for _, child in ipairs(self._tabIndicator:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create dots for each tab
    for i, tab in ipairs(self._allTabs) do
        local dot = Create.Instance("Frame", {
            Name = "Dot" .. i,
            BackgroundColor3 = (i == self._currentTabIndex) and Colors.Accent or Colors.TextDark,
            Size = UDim2.new(0, (i == self._currentTabIndex) and 16 or 6, 0, 6),
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = self._tabIndicator
        })
        Create.Corner(dot, 3)
    end
end

-- ============================================================================
-- Loading Screen
-- ============================================================================

function Window:_PlayLoadingScreen()
    -- Create loading overlay
    local loading = Create.Instance("Frame", {
        Name = "LoadingScreen",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 999,
        Parent = self._container
    })
    
    -- Logo text
    local logoText = Create.Instance("TextLabel", {
        Name = "Logo",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = self._title,
        TextSize = 20,
        TextTransparency = 1,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.4, 0),
        Size = UDim2.new(0.8, 0, 0, 30),
        ZIndex = 1000,
        Parent = loading
    })
    
    -- Subtitle
    local subtitle = Create.Instance("TextLabel", {
        Name = "Subtitle",
        FontFace = Fonts.Light,
        TextColor3 = Colors.TextDark,
        Text = "Loading...",
        TextSize = 12,
        TextTransparency = 1,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.4, 20),
        Size = UDim2.new(0.8, 0, 0, 20),
        ZIndex = 1000,
        Parent = loading
    })
    
    -- Loading bar
    local barBg = Create.Instance("Frame", {
        Name = "BarBg",
        BackgroundColor3 = Colors.Border,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.4, 48),
        Size = UDim2.new(0.4, 0, 0, 3),
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = loading
    })
    Create.Corner(barBg, 2)
    
    local barFill = Create.Instance("Frame", {
        Name = "Fill",
        BackgroundColor3 = Colors.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 1001,
        Parent = barBg
    })
    Create.Corner(barFill, 2)
    
    -- Animate
    task.defer(function()
        -- Fade in logo
        Tween.Create(logoText, { TextTransparency = 0 }, 0.3)
        task.wait(0.15)
        Tween.Create(subtitle, { TextTransparency = 0 }, 0.3)
        
        -- Fill bar
        task.wait(0.1)
        Tween.Create(barFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        
        task.wait(0.7)
        
        -- Fade out loading screen
        Tween.Create(loading, { BackgroundTransparency = 1 }, 0.3)
        Tween.Create(logoText, { TextTransparency = 1 }, 0.2)
        Tween.Create(subtitle, { TextTransparency = 1 }, 0.2)
        
        task.wait(0.35)
        loading:Destroy()
    end)
end

-- ============================================================================
-- Resize (Desktop)
-- ============================================================================

function Window:_SetupResize()
    local resizing = false
    local startSize, startInput
    
    self._resizeBtn.MouseEnter:Connect(function()
        Tween.Create(self._resizeBtn, { ImageColor3 = Colors.Text }, "Fast")
    end)
    self._resizeBtn.MouseLeave:Connect(function()
        if not resizing then
            Tween.Create(self._resizeBtn, { ImageColor3 = Color3.fromRGB(110, 110, 110) }, "Fast")
        end
    end)
    
    self._resizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startSize = self._container.AbsoluteSize
            startInput = input.Position
            self._originalHeight = startSize.Y
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    Tween.Create(self._resizeBtn, { ImageColor3 = Color3.fromRGB(110, 110, 110) }, "Fast")
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)
    
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if resizing and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            local newWidth = math.clamp(startSize.X + delta.X, Sizes.MinWindow.Width, Sizes.MaxWindow.Width)
            local newHeight = math.clamp(startSize.Y + delta.Y, Sizes.MinWindow.Height, Sizes.MaxWindow.Height)
            self._container.Size = UDim2.new(0, newWidth, 0, newHeight)
            self._originalHeight = newHeight
        end
    end))
end

-- ============================================================================
-- Minimize
-- ============================================================================

function Window:_ToggleMinimize()
    self._minimized = not self._minimized
    self.OnMinimize:Fire(self._minimized)
    
    if self._minimized then
        Tween.Create(self._mainContent, { Size = UDim2.new(1, 0, 0, 0) }, "Slow")
        Tween.Create(self._container, { 
            Size = UDim2.new(0, self._container.AbsoluteSize.X, 0, 45) 
        }, "Slow")
        if self._resizeBtn then self._resizeBtn.Visible = false end
    else
        Tween.Create(self._container, { 
            Size = UDim2.new(0, self._container.AbsoluteSize.X, 0, self._originalHeight) 
        }, "Slow")
        task.delay(0.1, function()
            local headerY = self._isMobile and 50 or 45
            Tween.Create(self._mainContent, { Size = UDim2.new(1, 0, 1, -(headerY + 1)) }, "Normal")
        end)
        if self._resizeBtn then self._resizeBtn.Visible = true end
    end
end

-- ============================================================================
-- Keybinds
-- ============================================================================

function Window:_SetupKeybinds()
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
        
        for _, keybindData in pairs(self._keybinds) do
            if input.KeyCode == keybindData.key then
                keybindData.callback()
            end
        end
    end))
end

-- ============================================================================
-- Public API
-- ============================================================================

function Window:Toggle()
    self._visible = not self._visible
    self.OnToggle:Fire(self._visible)
    
    if self._isMobile then
        if self._visible then
            self._screenGui.Enabled = true
            if self._dimOverlay then self._dimOverlay.Visible = true end
            self._container.Position = UDim2.new(0, 0, 1, 0 + self._container.AbsoluteSize.Y)
            Tween.Create(self._container, {
                Position = UDim2.new(0, 0, 1, 0)
            }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            
            if self._mobileToggle then
                self._mobileToggle.Visible = false
                self:_StopPulse()
            end
        else
            if self._dimOverlay then self._dimOverlay.Visible = false end
            Tween.CreateWithCallback(self._container, {
                Position = UDim2.new(0, 0, 1, self._container.AbsoluteSize.Y)
            }, 0.2, function()
                if not self._visible then
                    -- Don't disable screenGui — mobile toggle lives there
                end
            end)
            
            if self._mobileToggle then
                self._mobileToggle.Visible = true
                self:_StartPulse()
            end
            
            -- Close sidebar if open
            if self._sidebarExpanded then
                self._sidebarExpanded = false
                self._sectionsContainer.Visible = false
                if self._sidebarOverlay then self._sidebarOverlay.Visible = false end
            end
        end
    else
        if self._visible then
            self._screenGui.Enabled = true
            self._container.BackgroundTransparency = 0.5
            Tween.Create(self._container, {
                BackgroundTransparency = 0.05,
            }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween.CreateWithCallback(self._container, {
                BackgroundTransparency = 0.5,
            }, 0.15, function()
                if not self._visible then
                    self._screenGui.Enabled = false
                end
            end)
        end
        
        if self._mobileToggle then
            self._mobileToggle.Visible = not self._visible
        end
    end
end

function Window:SetToggleKey(keyCode: Enum.KeyCode)
    self._toggleKey = keyCode
end

function Window:Notify(config)
    return Notification.Show(config)
end

function Window:CreateSection(name: string)
    local Section = require(script.Parent.Parent.Components.Section)
    local section = Section.new(self, name)
    table.insert(self._sections, section)
    return section
end

function Window:SelectTab(tab)
    if self._currentTab then
        self._currentTab:Deselect()
    end
    
    local oldTab = self._currentTab
    self._currentTab = tab
    tab:Select()
    
    -- Track index for swipe navigation
    self._currentTabIndex = table.find(self._allTabs, tab) or 0
    
    self.OnTabChanged:Fire(oldTab, tab)
    self:_UpdateTabIndicator()
    
    -- Close sidebar on mobile after tab selection
    if self._isMobile and self._sidebarExpanded then
        self:_ToggleSidebar()
    end
end

function Window:RegisterTab(tab)
    table.insert(self._allTabs, tab)
    self:_UpdateTabIndicator()
end

function Window:NextTab()
    if #self._allTabs == 0 then return end
    local nextIndex = (self._currentTabIndex % #self._allTabs) + 1
    self:SelectTab(self._allTabs[nextIndex])
end

function Window:PreviousTab()
    if #self._allTabs == 0 then return end
    local prevIndex = ((self._currentTabIndex - 2) % #self._allTabs) + 1
    self:SelectTab(self._allTabs[prevIndex])
end

function Window:RegisterKeybind(id: string, key: Enum.KeyCode, callback: () -> ())
    self._keybinds[id] = { key = key, callback = callback }
end

function Window:UpdateKeybind(id: string, key: Enum.KeyCode)
    if self._keybinds[id] then
        self._keybinds[id].key = key
    end
end

function Window:GetContentContainer(): ScrollingFrame
    return self._contentContainer
end

function Window:GetSectionsContainer(): ScrollingFrame
    return self._sectionsContainer
end

-- ============================================================================
-- Watermark
-- ============================================================================

function Window:CreateWatermark(config)
    self._watermark = Watermark.new(self._screenGui, config)
    return self._watermark
end

-- ============================================================================
-- Theme Switching
-- ============================================================================

function Window:SetTheme(presetNameOrTable: string | { [string]: any })
    local theme
    if type(presetNameOrTable) == "string" then
        theme = Colors.Presets[presetNameOrTable]
        if not theme then
            warn("AcrylicUI: Unknown theme preset: " .. presetNameOrTable)
            return
        end
    else
        theme = presetNameOrTable
    end
    
    -- Update the Colors module values
    for key, value in pairs(theme) do
        if type(value) == "table" and type(Colors[key]) == "table" then
            for subKey, subValue in pairs(value) do
                Colors[key][subKey] = subValue
            end
        else
            Colors[key] = value
        end
    end
    
    -- Re-color current window elements
    self._container.BackgroundColor3 = Colors.Background
    if self._titleLabel then
        self._titleLabel.TextColor3 = Colors.Text
    end
    
    self:Notify({
        Title = "Theme Applied",
        Description = type(presetNameOrTable) == "string" and presetNameOrTable or "Custom Theme",
        Duration = 2,
        Type = "info"
    })
end

-- ============================================================================
-- Config System
-- ============================================================================

function Window:RegisterFlag(flag: string, component: any)
    self._configManager:RegisterFlag(flag, component)
end

function Window:SaveConfig(configName: string): boolean
    local success = self._configManager:SaveConfig(configName)
    if success then
        self.OnConfigSaved:Fire(configName)
    end
    return success
end

function Window:LoadConfig(configName: string): boolean
    return self._configManager:LoadConfig(configName)
end

function Window:DeleteConfig(configName: string): boolean
    return self._configManager:DeleteConfig(configName)
end

function Window:GetConfigs(): { string }
    return self._configManager:GetConfigs()
end

function Window:SetAutoSave(enabled: boolean)
    self._configManager:SetAutoSave(enabled)
end

-- ============================================================================
-- Destroy
-- ============================================================================

function Window:Destroy()
    self.OnDestroy:Fire()
    
    -- Animate out
    if self._isMobile then
        Tween.Create(self._container, {
            Position = UDim2.new(0, 0, 1, self._container.AbsoluteSize.Y)
        }, 0.2)
    else
        Tween.Create(self._container, {
            BackgroundTransparency = 1,
        }, 0.2)
    end
    
    task.delay(0.25, function()
        for _, connection in ipairs(self._connections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        
        if self._dragConnection then
            self._dragConnection.Disconnect()
        end
        
        if self._acrylicBlur then
            self._acrylicBlur:Destroy()
        end
        
        if self._configManager then
            self._configManager:Destroy()
        end
        
        if self._watermark then
            self._watermark:Destroy()
        end
        
        if self._mobileToggleGesture then
            self._mobileToggleGesture.Disconnect()
        end
        
        self:_StopPulse()
        
        -- Destroy signals
        self.OnToggle:Destroy()
        self.OnTabChanged:Destroy()
        self.OnMinimize:Destroy()
        self.OnConfigSaved:Destroy()
        self.OnDestroy:Destroy()
        
        if self._screenGui then
            self._screenGui:Destroy()
        end
    end)
end

return Window