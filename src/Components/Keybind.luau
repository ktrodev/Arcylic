--[[
    AcrylicUI - Keybind Component
    
    A keybind selector that listens for key presses and registers
    them with the window's keybind system.
]]

local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Keybind = {}
Keybind.__index = Keybind

export type KeybindConfig = {
    Name: string?,
    Default: Enum.KeyCode?,
    Flag: string?,
    Callback: (() -> ())?
}

function Keybind.new(parent: Instance, config: KeybindConfig?, window)
    local self = setmetatable({}, Keybind)

    local name = (config and config.Name) or "Keybind"
    local default = (config and config.Default) or Enum.KeyCode.F
    local callback = (config and config.Callback) or function() end
    
    self._flag = config and config.Flag
    self._connections = {}

    self._frame = Create.Instance("Frame", {
        Name = "Keybind_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, Sizes.Button.Height),
        Parent = parent
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    Create.Instance("TextLabel", {
        Name = "Name",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -10),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(0, 200, 0, 20),
        Parent = self._frame
    })

    self._box = Create.Instance("Frame", {
        Name = "KeyBox",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 26),
        Parent = self._frame
    })

    Create.Corner(self._box, Sizes.Corner.Small)
    self._boxStroke = Create.Stroke(self._box)

    self._label = Create.Instance("TextLabel", {
        Name = "Key",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = default.Name,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._box
    })

    self._listenBtn = Create.Instance("TextButton", {
        Name = "Listen",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._box
    })

    self._currentKey = default
    self._listening = false

    local id = name .. "_" .. tostring(math.floor(os.clock() * 1000))
    window:RegisterKeybind(id, self._currentKey, callback)
    self._keybindId = id
    self._window = window

    local function refresh()
        if self._listening then
            self._label.Text = "..."
            self._box.Size = UDim2.new(0, 43, 0, 26)
            Tween.Create(self._boxStroke, { Color = Colors.Accent }, "Fast")
        else
            local keyName = self._currentKey.Name
            local w = math.max(#keyName * 9 + 10, 24)
            self._box.Size = UDim2.new(0, w, 0, 26)
            self._label.Text = keyName
            Tween.Create(self._boxStroke, { Color = Colors.Border }, "Fast")
        end
    end

    table.insert(self._connections, self._listenBtn.MouseButton1Click:Connect(function()
        self._listening = true
        refresh()
    end))

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gp)
        if not self._listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self._currentKey = input.KeyCode
            self._listening = false
            window:UpdateKeybind(id, self._currentKey)
            refresh()
        end
    end))

    -- Hover effect
    table.insert(self._connections, self._frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween.Create(self._frame, { BackgroundTransparency = 0.3 }, "Fast")
        end
    end))
    
    table.insert(self._connections, self._frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween.Create(self._frame, { BackgroundTransparency = 0.4 }, "Fast")
        end
    end))

    refresh()
    return self
end

function Keybind:SetKey(key: Enum.KeyCode)
    self._currentKey = key
    self._label.Text = key.Name
    local w = math.max(#key.Name * 9 + 10, 24)
    self._box.Size = UDim2.new(0, w, 0, 26)
    if self._window and self._keybindId then
        self._window:UpdateKeybind(self._keybindId, key)
    end
end

function Keybind:GetKey(): Enum.KeyCode
    return self._currentKey
end

-- Config system compatibility
function Keybind:GetValue()
    return self._currentKey
end

function Keybind:SetValue(value: any)
    if typeof(value) == "EnumItem" then
        self:SetKey(value)
    end
end

function Keybind:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._frame:Destroy()
end

return Keybind
