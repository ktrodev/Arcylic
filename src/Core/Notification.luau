--[[
    AcrylicUI - Notification System
    
    Toast-style notifications with auto-dismiss, queue management,
    and smooth stacking animations.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Notification = {}

local Container: Frame? = nil
local MAX_VISIBLE = 5
local activeNotifications = {}

export type NotificationConfig = {
    Title: string?,
    Description: string?,
    Duration: number?,
    Icon: string?,
    Type: string? -- "info", "success", "warning", "error"
}

local TYPE_COLORS = {
    info = Colors.Accent,
    success = Color3.fromRGB(80, 200, 120),
    warning = Color3.fromRGB(255, 180, 50),
    error = Color3.fromRGB(255, 80, 80),
}

--[[
    Creates the notification container
    
    @param screenGui ScreenGui - Parent screen gui
    @return Frame - Container frame
]]
function Notification.CreateContainer(screenGui: ScreenGui): Frame
    if Container then return Container end
    
    Container = Create.Instance("Frame", {
        Name = "NotificationContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -240, 0, 20),
        Size = UDim2.new(0, 220, 1, -40),
        Parent = screenGui
    })
    
    Create.ListLayout(Container, 8)
    
    return Container
end

--[[
    Shows a notification
    
    @param config NotificationConfig - Notification configuration
    @return Frame - Notification frame
    
    @example
    Notification.Show({
        Title = "Success",
        Description = "Operation completed!",
        Duration = 3,
        Icon = "rbxassetid://10709775704",
        Type = "success"
    })
]]
function Notification.Show(config: NotificationConfig): Frame
    if not Container then
        warn("AcrylicUI: Notification container not initialized")
        return nil
    end
    
    local title = config.Title or "Notification"
    local description = config.Description or ""
    local duration = config.Duration or 3
    local icon = config.Icon or "rbxassetid://10709775704"
    local notifType = config.Type or "info"
    local timerColor = TYPE_COLORS[notifType] or Colors.Notification.Timer
    
    -- Limit visible notifications
    if #activeNotifications >= MAX_VISIBLE then
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end
    
    -- Notification frame
    local notification = Create.Instance("Frame", {
        Name = "Notification",
        BackgroundColor3 = Colors.Notification.Background,
        BackgroundTransparency = 0.05,
        Position = UDim2.new(1, 20, 0, 0),
        Size = UDim2.new(1, 0, 0, Sizes.Notification.Height),
        ClipsDescendants = true,
        Parent = Container
    })
    
    table.insert(activeNotifications, notification)
    
    Create.Corner(notification, Sizes.Corner.Small)
    
    Create.Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Colors.Notification.Border,
        Thickness = 1.5,
        Parent = notification
    })
    
    -- Type indicator bar (left edge)
    Create.Instance("Frame", {
        Name = "TypeIndicator",
        BackgroundColor3 = timerColor,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        Parent = notification
    })
    
    -- Title
    Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 14),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, -60, 0, 19),
        Parent = notification
    })
    
    -- Description
    Create.Instance("TextLabel", {
        Name = "Description",
        FontFace = Fonts.Light,
        TextColor3 = Colors.TextDark,
        Text = description,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 36),
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(1, -60, 0, 19),
        Parent = notification
    })
    
    -- Icon
    local iconImage = Create.Instance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = icon,
        ImageColor3 = timerColor,
        Position = UDim2.new(1, -33, 0, 23),
        Size = UDim2.new(0, 19, 0, 19),
        Parent = notification
    })
    
    Create.Instance("UIAspectRatioConstraint", {
        Parent = iconImage
    })
    
    -- Timer bar
    local timerBar = Create.Instance("Frame", {
        Name = "Timer",
        BackgroundColor3 = timerColor,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        Parent = notification
    })
    
    Create.Corner(timerBar, Sizes.Corner.Full)
    
    -- Animate in
    Tween.Create(
        notification,
        { Position = UDim2.new(0, 0, 0, 0) },
        0.3,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )
    
    -- Timer animation
    Tween.Create(
        timerBar,
        { Size = UDim2.new(0, 0, 0, 3) },
        duration,
        Enum.EasingStyle.Linear
    )
    
    -- Auto dismiss
    task.delay(duration, function()
        -- Remove from active list
        local idx = table.find(activeNotifications, notification)
        if idx then
            table.remove(activeNotifications, idx)
        end
        
        Tween.CreateWithCallback(
            notification,
            { Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1 },
            0.3,
            function()
                notification:Destroy()
            end
        )
    end)
    
    return notification
end

return Notification