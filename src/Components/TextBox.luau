--[[
    AcrylicUI - TextBox Component
    
    A text input field with placeholder text, validation, and focus support.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local TextBox = {}
TextBox.__index = TextBox

export type TextBoxConfig = {
    Name: string?,
    Default: string?,
    Placeholder: string?,
    ClearOnFocus: boolean?,
    NumbersOnly: boolean?,
    Flag: string?,
    Callback: ((text: string, enterPressed: boolean) -> ())?
}

export type TextBoxObject = {
    SetText: (self: TextBoxObject, text: string) -> (),
    GetText: (self: TextBoxObject) -> string,
    SetPlaceholder: (self: TextBoxObject, placeholder: string) -> (),
    Focus: (self: TextBoxObject) -> (),
    Destroy: (self: TextBoxObject) -> ()
}

--[[
    Creates a new text box component
    
    @param parent Instance - Parent container
    @param config TextBoxConfig - TextBox configuration
    @return TextBoxObject - TextBox control object
    
    @example
    local textBox = TextBox.new(container, {
        Name = "Player Name",
        Default = "",
        Placeholder = "Enter name...",
        ClearOnFocus = false,
        NumbersOnly = false,
        Callback = function(text, enterPressed)
            print("Text:", text, "Enter:", enterPressed)
        end
    })
]]
function TextBox.new(parent: Instance, config: TextBoxConfig): TextBoxObject
    local self = setmetatable({}, TextBox)
    
    local name = config.Name or "TextBox"
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Type here..."
    local clearOnFocus = config.ClearOnFocus or false
    local numbersOnly = config.NumbersOnly or false
    self._callback = config.Callback or function() end
    self._flag = config.Flag
    self._connections = {}
    
    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "TextBox_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.Button.Height),
        Parent = parent
    })
    
    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    
    -- Label
    Create.Instance("TextLabel", {
        Name = "Label",
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
    
    -- Input box background
    local inputBg = Create.Instance("Frame", {
        Name = "InputBackground",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 160, 0, 26),
        Parent = self._frame
    })
    
    Create.Corner(inputBg, Sizes.Corner.Small)
    self._inputStroke = Create.Stroke(inputBg, Colors.Border, 0, 1)
    
    -- TextBox input
    self._input = Create.Instance("TextBox", {
        Name = "Input",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Colors.TextDark,
        Text = default,
        TextSize = Fonts.Size.Small,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = clearOnFocus,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        ClipsDescendants = true,
        Parent = inputBg
    })
    
    -- Focus visual feedback
    table.insert(self._connections, self._input.Focused:Connect(function()
        Tween.Create(self._inputStroke, { Color = Colors.Accent }, "Fast")
    end))
    
    table.insert(self._connections, self._input.FocusLost:Connect(function(enterPressed)
        Tween.Create(self._inputStroke, { Color = Colors.Border }, "Fast")
        
        local text = self._input.Text
        
        -- Validate numbers only
        if numbersOnly then
            local filtered = text:gsub("[^%d%.%-]", "")
            if filtered ~= text then
                self._input.Text = filtered
                text = filtered
            end
        end
        
        self._callback(text, enterPressed)
    end))
    
    -- Hover effect
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

function TextBox:SetText(text: string)
    self._input.Text = text
end

function TextBox:GetText(): string
    return self._input.Text
end

function TextBox:SetPlaceholder(placeholder: string)
    self._input.PlaceholderText = placeholder
end

function TextBox:Focus()
    self._input:CaptureFocus()
end

function TextBox:GetValue()
    return self._input.Text
end

function TextBox:SetValue(value: any)
    self._input.Text = tostring(value)
end

function TextBox:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._frame:Destroy()
end

return TextBox
