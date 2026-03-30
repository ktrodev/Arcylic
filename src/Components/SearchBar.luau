--[[
    AcrylicUI - SearchBar Component
    
    A text input with real-time filtering of a list of items.
    Shows matched results in a dropdown-style list.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local SearchBar = {}
SearchBar.__index = SearchBar

export type SearchBarConfig = {
    Name: string?,
    Placeholder: string?,
    Items: { string }?,
    MaxVisible: number?,
    Callback: ((filtered: { string }, query: string) -> ())?
}

--[[
    Creates a new search bar with real-time filtering
    
    @param parent Instance - Parent container
    @param config SearchBarConfig - Configuration
    @return SearchBarObject
    
    @example
    local search = SearchBar.new(container, {
        Name = "Search Players",
        Placeholder = "Type to search...",
        Items = {"Player1", "Player2", "Player3"},
        Callback = function(filtered, query)
            for _, name in ipairs(filtered) do
                print("Match:", name)
            end
        end
    })
]]
function SearchBar.new(parent: Instance, config: SearchBarConfig?)
    local self = setmetatable({}, SearchBar)
    
    local name = (config and config.Name) or "Search"
    local placeholder = (config and config.Placeholder) or "Search..."
    self._items = (config and config.Items) or {}
    self._maxVisible = (config and config.MaxVisible) or 5
    self._callback = (config and config.Callback) or function() end
    self._connections = {}
    self._expanded = false
    
    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "SearchBar_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.Button.Height),
        ClipsDescendants = false,
        Parent = parent
    })
    
    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    
    -- Search icon
    Create.Instance("ImageLabel", {
        Name = "SearchIcon",
        BackgroundTransparency = 1,
        Image = "rbxassetid://10723407389",
        ImageColor3 = Colors.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Parent = self._frame
    })
    
    -- Input field
    self._input = Create.Instance("TextBox", {
        Name = "Input",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Colors.TextDark,
        Text = "",
        TextSize = Fonts.Size.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Parent = self._frame
    })
    
    -- Results container
    self._resultsContainer = Create.Instance("Frame", {
        Name = "Results",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        BorderSizePixel = 0,
        ZIndex = 150,
        ClipsDescendants = true,
        Parent = self._frame
    })
    
    Create.Corner(self._resultsContainer, Sizes.Corner.Medium)
    Create.Stroke(self._resultsContainer)
    
    self._resultsList = Create.Instance("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        ZIndex = 150,
        Parent = self._resultsContainer
    })
    
    Create.ListLayout(self._resultsList, 0)
    
    -- Real-time filtering
    table.insert(self._connections, self._input:GetPropertyChangedSignal("Text"):Connect(function()
        self:_Filter()
    end))
    
    table.insert(self._connections, self._input.Focused:Connect(function()
        self:_Filter()
    end))
    
    table.insert(self._connections, self._input.FocusLost:Connect(function()
        -- Delay to allow click on result
        task.delay(0.15, function()
            self:_HideResults()
        end)
    end))
    
    return self
end

function SearchBar:_Filter()
    local query = self._input.Text:lower()
    
    -- Clear previous results
    for _, child in ipairs(self._resultsList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    if query == "" then
        self:_HideResults()
        self._callback({}, "")
        return
    end
    
    -- Filter items
    local filtered = {}
    for _, item in ipairs(self._items) do
        if item:lower():find(query, 1, true) then
            table.insert(filtered, item)
        end
    end
    
    if #filtered == 0 then
        self:_HideResults()
        self._callback({}, query)
        return
    end
    
    -- Show results
    local visibleCount = math.min(#filtered, self._maxVisible)
    local itemHeight = Sizes.Dropdown.OptionHeight
    
    self._resultsContainer.Size = UDim2.new(1, 0, 0, visibleCount * itemHeight)
    self._resultsList.CanvasSize = UDim2.new(0, 0, 0, #filtered * itemHeight)
    self._resultsContainer.Visible = true
    self._expanded = true
    self._frame.ZIndex = 50
    
    for _, item in ipairs(filtered) do
        local btn = Create.Instance("TextButton", {
            Name = item,
            FontFace = Fonts.Regular,
            TextColor3 = Colors.Text,
            Text = item,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextSize = Fonts.Size.Small,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, itemHeight),
            ZIndex = 150,
            Parent = self._resultsList
        })
        
        Create.Instance("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            Parent = btn
        })
        
        btn.MouseEnter:Connect(function()
            Tween.Create(btn, { BackgroundTransparency = 0.5 }, "Fast")
        end)
        
        btn.MouseLeave:Connect(function()
            Tween.Create(btn, { BackgroundTransparency = 1 }, "Fast")
        end)
        
        btn.MouseButton1Click:Connect(function()
            self._input.Text = item
            self:_HideResults()
            self._callback({ item }, item)
        end)
    end
    
    self._callback(filtered, query)
end

function SearchBar:_HideResults()
    self._resultsContainer.Visible = false
    self._expanded = false
    self._frame.ZIndex = 1
end

function SearchBar:SetItems(items: { string })
    self._items = items
end

function SearchBar:GetText(): string
    return self._input.Text
end

function SearchBar:Clear()
    self._input.Text = ""
    self:_HideResults()
end

function SearchBar:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._frame:Destroy()
end

return SearchBar
