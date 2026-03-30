--[[
    AcrylicUI - Watermark / FPS Counter
    
    A small overlay showing FPS, ping, custom text, and time.
    Typically positioned in a corner of the screen.
]]

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Watermark = {}
Watermark.__index = Watermark

export type WatermarkConfig = {
    Text: string?,
    ShowFPS: boolean?,
    ShowPing: boolean?,
    ShowTime: boolean?,
    Position: string? -- "TopLeft", "TopRight", "BottomLeft", "BottomRight"
}

local POSITION_MAP = {
    TopLeft = UDim2.new(0, 10, 0, 10),
    TopRight = UDim2.new(1, -10, 0, 10),
    BottomLeft = UDim2.new(0, 10, 1, -35),
    BottomRight = UDim2.new(1, -10, 1, -35)
}

local ANCHOR_MAP = {
    TopLeft = Vector2.new(0, 0),
    TopRight = Vector2.new(1, 0),
    BottomLeft = Vector2.new(0, 1),
    BottomRight = Vector2.new(1, 1)
}

--[[
    Creates a new watermark overlay
    
    @param screenGui ScreenGui - Parent screen gui
    @param config WatermarkConfig - Configuration
    @return Watermark
    
    @example
    window:CreateWatermark({
        Text = "MyHub v1.0",
        ShowFPS = true,
        ShowPing = true,
        Position = "TopRight"
    })
]]
function Watermark.new(screenGui: ScreenGui, config: WatermarkConfig?)
    local self = setmetatable({}, Watermark)
    
    local text = (config and config.Text) or "AcrylicUI"
    local showFPS = if config and config.ShowFPS ~= nil then config.ShowFPS else true
    local showPing = if config and config.ShowPing ~= nil then config.ShowPing else false
    local showTime = if config and config.ShowTime ~= nil then config.ShowTime else false
    local position = (config and config.Position) or "TopRight"
    
    self._text = text
    self._showFPS = showFPS
    self._showPing = showPing
    self._showTime = showTime
    self._connections = {}
    
    -- Container
    self._frame = Create.Instance("Frame", {
        Name = "Watermark",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.3,
        AnchorPoint = ANCHOR_MAP[position] or Vector2.new(1, 0),
        Position = POSITION_MAP[position] or POSITION_MAP.TopRight,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        Parent = screenGui
    })
    
    Create.Instance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self._frame
    })
    
    Create.Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Colors.Border,
        Thickness = 1,
        Transparency = 0.3,
        Parent = self._frame
    })
    
    Create.Instance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        Parent = self._frame
    })
    
    Create.Instance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self._frame
    })
    
    -- Custom text
    self._textLabel = Create.Instance("TextLabel", {
        Name = "CustomText",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = text,
        BackgroundTransparency = 1,
        TextSize = 11,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        LayoutOrder = 1,
        Parent = self._frame
    })
    
    -- Separator + FPS
    if showFPS then
        self:_AddSeparator(2)
        self._fpsLabel = Create.Instance("TextLabel", {
            Name = "FPS",
            FontFace = Fonts.Regular,
            TextColor3 = Color3.fromRGB(80, 200, 120),
            Text = "60 FPS",
            BackgroundTransparency = 1,
            TextSize = 11,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = 3,
            Parent = self._frame
        })
    end
    
    -- Separator + Ping
    if showPing then
        self:_AddSeparator(4)
        self._pingLabel = Create.Instance("TextLabel", {
            Name = "Ping",
            FontFace = Fonts.Regular,
            TextColor3 = Color3.fromRGB(255, 200, 80),
            Text = "0ms",
            BackgroundTransparency = 1,
            TextSize = 11,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = 5,
            Parent = self._frame
        })
    end
    
    -- Separator + Time
    if showTime then
        self:_AddSeparator(6)
        self._timeLabel = Create.Instance("TextLabel", {
            Name = "Time",
            FontFace = Fonts.Regular,
            TextColor3 = Colors.TextDark,
            Text = "00:00",
            BackgroundTransparency = 1,
            TextSize = 11,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = 7,
            Parent = self._frame
        })
    end
    
    -- Start update loop
    self:_StartUpdating()
    
    return self
end

function Watermark:_AddSeparator(order: number)
    Create.Instance("Frame", {
        Name = "Sep",
        BackgroundColor3 = Colors.Border,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(0, 1, 0.7, 0),
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = self._frame
    })
end

function Watermark:_StartUpdating()
    local frameCount = 0
    local lastFPSUpdate = os.clock()
    
    table.insert(self._connections, RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = os.clock()
        
        -- Update every 0.5 seconds
        if now - lastFPSUpdate >= 0.5 then
            if self._fpsLabel then
                local fps = math.floor(frameCount / (now - lastFPSUpdate))
                self._fpsLabel.Text = tostring(fps) .. " FPS"
                
                -- Color based on FPS
                if fps >= 50 then
                    self._fpsLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                elseif fps >= 30 then
                    self._fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                else
                    self._fpsLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            end
            
            if self._pingLabel then
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                self._pingLabel.Text = tostring(ping) .. "ms"
                
                if ping < 80 then
                    self._pingLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                elseif ping < 150 then
                    self._pingLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                else
                    self._pingLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            end
            
            if self._timeLabel then
                self._timeLabel.Text = os.date("%H:%M")
            end
            
            frameCount = 0
            lastFPSUpdate = now
        end
    end))
end

function Watermark:SetText(text: string)
    self._text = text
    self._textLabel.Text = text
end

function Watermark:SetVisible(visible: boolean)
    self._frame.Visible = visible
end

function Watermark:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._frame:Destroy()
end

return Watermark
