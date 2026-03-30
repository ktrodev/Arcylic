--[[
    AcrylicUI - Label Component
    
    A simple text label for showing live status, info text, or dynamic values.
    Supports custom colors and icon display.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Label = {}
Label.__index = Label

export type LabelConfig = {
    Name: string?,
    Text: string?,
    Color: Color3?,
    Icon: string?
}

--[[
    Creates a new label
    
    @param parent Instance - Parent container
    @param config LabelConfig - Configuration
    @return LabelObject
    
    @example
    local status = Label.new(container, {
        Name = "Status",
        Text = "Connected",
        Color = Color3.fromRGB(80, 200, 120),
        Icon = "rbxassetid://10709775704"
    })
    -- Update later:
    status:SetText("Disconnected")
    status:SetColor(Color3.fromRGB(255, 80, 80))
]]
function Label.new(parent: Instance, config: LabelConfig?)
    local self = setmetatable({}, Label)
    
    local name = (config and config.Name) or "Label"
    local text = (config and config.Text) or ""
    local color = (config and config.Color) or Colors.Text
    local icon = config and config.Icon
    
    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "Label_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.Button.Height),
        Parent = parent
    })
    
    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    
    -- Name label
    Create.Instance("TextLabel", {
        Name = "Name",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -10),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(0, 150, 0, 20),
        Parent = self._frame
    })
    
    -- Status indicator dot
    self._dot = Create.Instance("Frame", {
        Name = "Dot",
        BackgroundColor3 = color,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 8, 0, 8),
        BorderSizePixel = 0,
        Visible = true,
        Parent = self._frame
    })
    Create.Corner(self._dot, 4)
    
    -- Value text (right aligned, before dot)
    self._valueLabel = Create.Instance("TextLabel", {
        Name = "Value",
        FontFace = Fonts.Regular,
        TextColor3 = color,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -24, 0.5, 0),
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(0, 150, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self._frame
    })
    
    -- Optional icon
    if icon then
        self._icon = Create.Instance("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = color,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            Parent = self._frame
        })
        -- Shift text and hide dot when icon is present
        self._valueLabel.Position = UDim2.new(1, -30, 0.5, 0)
        self._dot.Visible = false
    end
    
    return self
end

function Label:SetText(text: string)
    self._valueLabel.Text = text
end

function Label:GetText(): string
    return self._valueLabel.Text
end

function Label:SetColor(color: Color3)
    Tween.Create(self._valueLabel, { TextColor3 = color }, "Fast")
    Tween.Create(self._dot, { BackgroundColor3 = color }, "Fast")
    if self._icon then
        Tween.Create(self._icon, { ImageColor3 = color }, "Fast")
    end
end

function Label:SetVisible(visible: boolean)
    self._frame.Visible = visible
end

function Label:Destroy()
    self._frame:Destroy()
end

return Label
