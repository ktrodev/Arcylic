--[[
    AcrylicUI - ProgressBar Component
    
    A visual progress indicator with animated fill, gradient color,
    and optional text overlay.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local ProgressBar = {}
ProgressBar.__index = ProgressBar

export type ProgressBarConfig = {
    Name: string?,
    Max: number?,
    Default: number?,
    Flag: string?,
    Callback: ((value: number) -> ())?
}

--[[
    Creates a new progress bar
    
    @param parent Instance - Parent container
    @param config ProgressBarConfig - Configuration
    @return ProgressBarObject
    
    @example
    local progress = ProgressBar.new(container, {
        Name = "Farm Progress",
        Max = 100,
        Default = 0
    })
    progress:SetValue(75)
    progress:SetText("75/100 kills")
]]
function ProgressBar.new(parent: Instance, config: ProgressBarConfig?)
    local self = setmetatable({}, ProgressBar)
    
    local name = (config and config.Name) or "Progress"
    self._max = (config and config.Max) or 100
    self._value = (config and config.Default) or 0
    self._callback = (config and config.Callback) or function() end
    self._flag = config and config.Flag
    
    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "ProgressBar_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.ProgressBar.Height),
        Parent = parent
    })
    
    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    
    -- Label
    self._label = Create.Instance("TextLabel", {
        Name = "Label",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 4),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(0, 200, 0, 18),
        Parent = self._frame
    })
    
    -- Value / custom text
    self._textLabel = Create.Instance("TextLabel", {
        Name = "ValueText",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = tostring(self._value) .. "/" .. tostring(self._max),
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 4),
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(0, 50, 0, 18),
        Parent = self._frame
    })
    
    -- Track
    self._track = Create.Instance("Frame", {
        Name = "Track",
        BackgroundColor3 = Color3.fromRGB(11, 11, 11),
        Position = UDim2.new(0, 10, 0, 26),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, Sizes.ProgressBar.BarHeight),
        Parent = self._frame
    })
    
    Create.Corner(self._track, Sizes.Corner.Full)
    
    -- Fill
    local initialRatio = math.clamp(self._value / self._max, 0, 1)
    self._fill = Create.Instance("Frame", {
        Name = "Fill",
        BackgroundColor3 = self:_GetFillColor(initialRatio),
        BorderSizePixel = 0,
        Size = UDim2.new(initialRatio, 0, 1, 0),
        Parent = self._track
    })
    
    Create.Corner(self._fill, Sizes.Corner.Full)
    
    -- Gradient overlay for premium look
    Create.Instance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.85, 0.85, 0.85))
        }),
        Rotation = 90,
        Parent = self._fill
    })
    
    return self
end

-- Color transitions: red → orange → yellow → green based on progress
function ProgressBar:_GetFillColor(ratio: number): Color3
    if ratio < 0.33 then
        -- Red to Orange
        local t = ratio / 0.33
        return Color3.fromRGB(
            255,
            math.floor(80 + 100 * t),
            math.floor(60 * t)
        )
    elseif ratio < 0.66 then
        -- Orange to Yellow
        local t = (ratio - 0.33) / 0.33
        return Color3.fromRGB(
            255,
            math.floor(180 + 50 * t),
            math.floor(60 - 10 * t)
        )
    else
        -- Yellow to Green
        local t = (ratio - 0.66) / 0.34
        return Color3.fromRGB(
            math.floor(255 - 175 * t),
            math.floor(200 + 30 * t),
            math.floor(50 + 70 * t)
        )
    end
end

function ProgressBar:_UpdateVisual()
    local ratio = math.clamp(self._value / self._max, 0, 1)
    Tween.Create(self._fill, { 
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = self:_GetFillColor(ratio)
    }, "Normal")
    self._textLabel.Text = tostring(math.floor(self._value)) .. "/" .. tostring(self._max)
end

function ProgressBar:SetValue(value: number)
    self._value = math.clamp(value, 0, self._max)
    self:_UpdateVisual()
    self._callback(self._value)
end

function ProgressBar:Increment(amount: number?)
    self:SetValue(self._value + (amount or 1))
end

function ProgressBar:GetValue(): number
    return self._value
end

function ProgressBar:SetMax(max: number)
    self._max = max
    self:_UpdateVisual()
end

function ProgressBar:SetText(text: string)
    self._textLabel.Text = text
end

function ProgressBar:SetLabel(text: string)
    self._label.Text = text
end

function ProgressBar:Destroy()
    self._frame:Destroy()
end

return ProgressBar
