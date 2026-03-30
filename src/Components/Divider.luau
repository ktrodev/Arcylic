--[[
    AcrylicUI - Divider Component
    
    A visual separator between component groups.
    Can be plain or with centered text.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Divider = {}
Divider.__index = Divider

--[[
    Creates a new divider
    
    @param parent Instance - Parent container
    @param text string? - Optional centered text
    @return DividerObject
    
    @example
    Divider.new(container)              -- plain line
    Divider.new(container, "Advanced")  -- line with text
]]
function Divider.new(parent: Instance, text: string?)
    local self = setmetatable({}, Divider)
    
    self._frame = Create.Instance("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, text and 22 or 12),
        Parent = parent
    })
    
    if text and text ~= "" then
        -- Left line
        Create.Instance("Frame", {
            Name = "LineLeft",
            BackgroundColor3 = Colors.Border,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.3, -5, 0, 1),
            BorderSizePixel = 0,
            Parent = self._frame
        })
        
        -- Text
        self._text = Create.Instance("TextLabel", {
            Name = "DividerText",
            FontFace = Fonts.Regular,
            TextColor3 = Colors.TextDark,
            Text = text,
            BackgroundTransparency = 1,
            TextSize = Fonts.Size.Tiny,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.4, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = self._frame
        })
        
        -- Right line
        Create.Instance("Frame", {
            Name = "LineRight",
            BackgroundColor3 = Colors.Border,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0.3, -5, 0, 1),
            BorderSizePixel = 0,
            Parent = self._frame
        })
    else
        -- Simple centered line
        Create.Instance("Frame", {
            Name = "Line",
            BackgroundColor3 = Colors.Border,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -20, 0, 1),
            BorderSizePixel = 0,
            Parent = self._frame
        })
    end
    
    return self
end

function Divider:SetText(text: string)
    if self._text then
        self._text.Text = text
    end
end

function Divider:Destroy()
    self._frame:Destroy()
end

return Divider
