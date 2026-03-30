--[[
    AcrylicUI - Paragraph Component
    
    An informational text block with title and content.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Paragraph = {}
Paragraph.__index = Paragraph

export type ParagraphConfig = {
    Title: string?,
    Content: string?
}

--[[
    Creates a new paragraph component
    
    @param parent Instance - Parent container
    @param config ParagraphConfig - Paragraph configuration
    @return ParagraphObject
    
    @example
    local paragraph = Paragraph.new(container, {
        Title = "About",
        Content = "This is an informational text block."
    })
]]
function Paragraph.new(parent: Instance, config: ParagraphConfig?)
    local self = setmetatable({}, Paragraph)
    local title = (config and config.Title) or "Paragraph"
    local content = (config and config.Content) or "Description text here."

    self._frame = Create.Instance("Frame", {
        Name = "Paragraph",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    Create.Padding(self._frame, 10, 10, 10, 10)

    self._title = Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = self._frame
    })

    self._content = Create.Instance("TextLabel", {
        Name = "Content",
        FontFace = Fonts.Light,
        TextColor3 = Colors.TextDark,
        Text = content,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LineHeight = 1.3,
        Parent = self._frame
    })

    return self
end

function Paragraph:SetTitle(text: string)
    self._title.Text = text
end

function Paragraph:SetContent(text: string)
    self._content.Text = text
end

function Paragraph:Destroy()
    self._frame:Destroy()
end

return Paragraph
