--[[
    AcrylicUI - ColorPicker Component
    
    A full-featured color picker with HSV gradient canvas, hue slider,
    hex input, and preset swatches.
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local PRESETS = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 65, 65),
    Color3.fromRGB(65, 255, 100),
    Color3.fromRGB(65, 140, 255),
    Color3.fromRGB(255, 165, 50),
    Color3.fromRGB(200, 65, 255),
    Color3.fromRGB(255, 230, 50),
    Color3.fromRGB(50, 220, 220),
}

export type ColorPickerConfig = {
    Name: string?,
    Default: Color3?,
    Flag: string?,
    Callback: ((color: Color3) -> ())?
}

function ColorPicker.new(parent: Instance, config: ColorPickerConfig?)
    local self = setmetatable({}, ColorPicker)
    local name = (config and config.Name) or "Color Picker"
    self._callback = (config and config.Callback) or function() end
    self._color = (config and config.Default) or PRESETS[1]
    self._flag = config and config.Flag
    self._expanded = false
    self._connections = {}
    self._draggingSV = false
    self._draggingHue = false
    
    -- Decompose initial color
    local h, s, v = self._color:ToHSV()
    self._hue = h
    self._sat = s
    self._val = v
    
    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "ColorPicker_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.Button.Height),
        ClipsDescendants = false,
        Parent = parent
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    -- Label
    Create.Instance("TextLabel", {
        Name = "Name",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, -60, 1, 0),
        Parent = self._frame
    })

    -- Preview swatch
    self._preview = Create.Instance("Frame", {
        Name = "Preview",
        BackgroundColor3 = self._color,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 35, 0, 16),
        Parent = self._frame
    })
    Create.Corner(self._preview, Sizes.Corner.Small)
    Create.Stroke(self._preview)

    local previewBtn = Create.Instance("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._preview
    })

    -- =========================================================================
    -- Expanded picker panel
    -- =========================================================================
    self._panel = Create.Instance("Frame", {
        Name = "PickerPanel",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 170),
        Position = UDim2.new(0, 0, 1, 5),
        Visible = false,
        ZIndex = 200,
        ClipsDescendants = true,
        Parent = self._frame
    })
    Create.Corner(self._panel, Sizes.Corner.Medium)
    Create.Stroke(self._panel)
    
    -- SV Canvas (saturation-value gradient)
    self._svCanvas = Create.Instance("Frame", {
        Name = "SVCanvas",
        BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1),
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -50, 0, 100),
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent = self._panel
    })
    Create.Corner(self._svCanvas, Sizes.Corner.Small)
    
    -- White gradient overlay (saturation: left=white, right=pure hue)
    Create.Instance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Parent = self._svCanvas
    })
    
    -- Black gradient overlay (value: top=bright, bottom=black)
    local blackOverlay = Create.Instance("Frame", {
        Name = "BlackOverlay",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 202,
        Parent = self._svCanvas
    })
    Create.Corner(blackOverlay, Sizes.Corner.Small)
    
    Create.Instance("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Rotation = 90,
        Parent = blackOverlay
    })
    
    -- SV Cursor
    self._svCursor = Create.Instance("Frame", {
        Name = "SVCursor",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(self._sat, 0, 1 - self._val, 0),
        Size = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
        ZIndex = 205,
        Parent = self._svCanvas
    })
    Create.Corner(self._svCursor, 5)
    Create.Instance("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1.5,
        Parent = self._svCursor
    })
    
    -- SV input layer (sits on top to capture clicks)
    local svInput = Create.Instance("TextButton", {
        Name = "SVInput",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 206,
        Parent = self._svCanvas
    })
    
    -- Hue slider (vertical bar on the right)
    self._hueBar = Create.Instance("Frame", {
        Name = "HueBar",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(1, -30, 0, 10),
        Size = UDim2.new(0, 20, 0, 100),
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent = self._panel
    })
    Create.Corner(self._hueBar, Sizes.Corner.Small)
    
    -- Rainbow gradient for hue
    Create.Instance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
            ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
            ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        }),
        Rotation = 90,
        Parent = self._hueBar
    })
    
    -- Hue cursor
    self._hueCursor = Create.Instance("Frame", {
        Name = "HueCursor",
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, self._hue, 0),
        Size = UDim2.new(1, 4, 0, 4),
        BorderSizePixel = 0,
        ZIndex = 205,
        Parent = self._hueBar
    })
    Create.Corner(self._hueCursor, 2)
    Create.Instance("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        Parent = self._hueCursor
    })
    
    -- Hue input layer
    local hueInput = Create.Instance("TextButton", {
        Name = "HueInput",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 206,
        Parent = self._hueBar
    })
    
    -- Hex input row
    local hexRow = Create.Instance("Frame", {
        Name = "HexRow",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 116),
        Size = UDim2.new(1, -20, 0, 22),
        ZIndex = 201,
        Parent = self._panel
    })
    
    Create.Instance("TextLabel", {
        Name = "HexLabel",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = "#",
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(0, 12, 1, 0),
        ZIndex = 201,
        Parent = hexRow
    })
    
    local hexBg = Create.Instance("Frame", {
        Name = "HexBg",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 62, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent = hexRow
    })
    Create.Corner(hexBg, 3)
    Create.Stroke(hexBg)
    
    self._hexInput = Create.Instance("TextBox", {
        Name = "HexInput",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        PlaceholderText = "FFFFFF",
        PlaceholderColor3 = Colors.TextDark,
        Text = self:_ColorToHex(self._color),
        TextSize = Fonts.Size.Small,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        ZIndex = 202,
        Parent = hexBg
    })
    
    -- Preset swatches row
    local presetRow = Create.Instance("Frame", {
        Name = "PresetRow",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 142),
        Size = UDim2.new(1, -20, 0, 20),
        ZIndex = 201,
        Parent = self._panel
    })
    
    local presetLayout = Create.Instance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5),
        Parent = presetRow
    })
    
    for _, col in ipairs(PRESETS) do
        local swatch = Create.Instance("TextButton", {
            BackgroundColor3 = col,
            Text = "",
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 202,
            Parent = presetRow
        })
        Create.Corner(swatch, 3)
        Create.Instance("UIStroke", {
            Color = Colors.Border,
            Thickness = 1,
            Parent = swatch
        })
        swatch.MouseButton1Click:Connect(function()
            self:SetColor(col)
        end)
    end
    
    -- =========================================================================
    -- Input handling
    -- =========================================================================
    
    -- SV canvas interaction
    svInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._draggingSV = true
            self:_UpdateSVFromInput(input)
        end
    end)
    
    svInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._draggingSV = false
        end
    end)
    
    -- Hue bar interaction
    hueInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._draggingHue = true
            self:_UpdateHueFromInput(input)
        end
    end)
    
    hueInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._draggingHue = false
        end
    end)
    
    -- Global input tracking for drag
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if self._draggingSV then
                self:_UpdateSVFromInput(input)
            elseif self._draggingHue then
                self:_UpdateHueFromInput(input)
            end
        end
    end))
    
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            self._draggingSV = false
            self._draggingHue = false
        end
    end))
    
    -- Hex input submission
    table.insert(self._connections, self._hexInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local hex = self._hexInput.Text:gsub("#", "")
            local color = self:_HexToColor(hex)
            if color then
                self:SetColor(color)
            else
                -- Revert to current color
                self._hexInput.Text = self:_ColorToHex(self._color)
            end
        end
    end))
    
    -- Toggle panel
    previewBtn.MouseButton1Click:Connect(function()
        self._expanded = not self._expanded
        self._panel.Visible = self._expanded
        if self._expanded then
            self._frame.ZIndex = 50
        else
            self._frame.ZIndex = 1
        end
    end)
    
    -- Hover effects on main frame
    self._frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween.Create(self._frame, { BackgroundTransparency = 0.3 }, "Fast")
        end
    end)
    
    self._frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween.Create(self._frame, { BackgroundTransparency = 0.4 }, "Fast")
        end
    end)
    
    return self
end

-- ============================================================================
-- HSV Canvas Interaction
-- ============================================================================

function ColorPicker:_UpdateSVFromInput(input: InputObject)
    local pos = input.Position
    local canvasPos = self._svCanvas.AbsolutePosition
    local canvasSize = self._svCanvas.AbsoluteSize
    
    self._sat = math.clamp((pos.X - canvasPos.X) / canvasSize.X, 0, 1)
    self._val = math.clamp(1 - (pos.Y - canvasPos.Y) / canvasSize.Y, 0, 1)
    
    self:_ApplyColor()
end

function ColorPicker:_UpdateHueFromInput(input: InputObject)
    local pos = input.Position
    local barPos = self._hueBar.AbsolutePosition
    local barSize = self._hueBar.AbsoluteSize
    
    self._hue = math.clamp((pos.Y - barPos.Y) / barSize.Y, 0, 0.999)
    
    -- Update SV canvas background to match hue
    self._svCanvas.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
    
    self:_ApplyColor()
end

function ColorPicker:_ApplyColor()
    self._color = Color3.fromHSV(self._hue, self._sat, self._val)
    
    -- Update visual indicators
    self._preview.BackgroundColor3 = self._color
    self._svCursor.Position = UDim2.new(self._sat, 0, 1 - self._val, 0)
    self._hueCursor.Position = UDim2.new(0.5, 0, self._hue, 0)
    self._hexInput.Text = self:_ColorToHex(self._color)
    
    -- Update cursor color (inverse for visibility)
    local brightness = self._val * (1 - self._sat * 0.5)
    self._svCursor.BackgroundColor3 = brightness > 0.5 
        and Color3.new(0, 0, 0) 
        or Color3.new(1, 1, 1)
    
    self._callback(self._color)
end

-- ============================================================================
-- Hex Utilities
-- ============================================================================

function ColorPicker:_ColorToHex(color: Color3): string
    return string.format(
        "%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function ColorPicker:_HexToColor(hex: string): Color3?
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

-- ============================================================================
-- Public API
-- ============================================================================

function ColorPicker:SetColor(color: Color3)
    local h, s, v = color:ToHSV()
    self._hue = h
    self._sat = s
    self._val = v
    self._svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    self:_ApplyColor()
end

function ColorPicker:GetColor(): Color3
    return self._color
end

-- Config system compatibility
function ColorPicker:GetValue()
    return self._color
end

function ColorPicker:SetValue(value: any)
    if typeof(value) == "Color3" then
        self:SetColor(value)
    end
end

function ColorPicker:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    if self._panel then self._panel:Destroy() end
    self._frame:Destroy()
end

return ColorPicker
