--[[
    AcrylicUI - Gesture Utility
    
    Touch gesture detection for mobile: swipe, long press, pinch.
    Works with Roblox's UserInputService on touch devices.
]]

local UserInputService = game:GetService("UserInputService")

local Gesture = {}

export type GestureConnection = {
    Disconnect: () -> ()
}

local SWIPE_THRESHOLD = 50      -- min distance in pixels
local SWIPE_MAX_TIME = 0.4      -- max seconds for a swipe
local LONG_PRESS_TIME = 0.5     -- seconds to trigger long press

--[[
    Detects swipe gestures on a GuiObject
    
    @param target GuiObject - The element to detect swipes on
    @param callback function - Called with direction ("Left", "Right", "Up", "Down")
    @return GestureConnection
    
    @example
    Gesture.OnSwipe(frame, function(direction)
        if direction == "Left" then
            print("Swiped left!")
        end
    end)
]]
function Gesture.OnSwipe(target: GuiObject, callback: (direction: string) -> ()): GestureConnection
    local connections: { RBXScriptConnection } = {}
    local touchStart: Vector3? = nil
    local touchStartTime: number = 0
    
    table.insert(connections, target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = input.Position
            touchStartTime = os.clock()
        end
    end))
    
    table.insert(connections, target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and touchStart then
            local elapsed = os.clock() - touchStartTime
            if elapsed > SWIPE_MAX_TIME then
                touchStart = nil
                return
            end
            
            local delta = input.Position - touchStart
            local absX = math.abs(delta.X)
            local absY = math.abs(delta.Y)
            
            touchStart = nil
            
            if absX < SWIPE_THRESHOLD and absY < SWIPE_THRESHOLD then
                return -- too small, not a swipe
            end
            
            if absX > absY then
                -- Horizontal swipe
                callback(delta.X < 0 and "Left" or "Right")
            else
                -- Vertical swipe
                callback(delta.Y < 0 and "Up" or "Down")
            end
        end
    end))
    
    return {
        Disconnect = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            table.clear(connections)
        end
    }
end

--[[
    Detects long press on a GuiObject
    
    @param target GuiObject - The element to detect
    @param callback function - Called when long press triggers
    @param duration number? - Hold time in seconds (default 0.5)
    @return GestureConnection
]]
function Gesture.OnLongPress(target: GuiObject, callback: () -> (), duration: number?): GestureConnection
    local holdTime = duration or LONG_PRESS_TIME
    local connections: { RBXScriptConnection } = {}
    local pressing = false
    local pressThread = nil
    
    table.insert(connections, target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressing = true
            pressThread = task.delay(holdTime, function()
                if pressing then
                    callback()
                end
            end)
        end
    end))
    
    table.insert(connections, target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressing = false
            if pressThread then
                task.cancel(pressThread)
                pressThread = nil
            end
        end
    end))
    
    return {
        Disconnect = function()
            pressing = false
            if pressThread then
                task.cancel(pressThread)
            end
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            table.clear(connections)
        end
    }
end

--[[
    Makes a GuiObject draggable with edge snapping (for mobile toggle)
    
    @param target GuiObject - The element to make draggable
    @param snapPadding number? - Padding from screen edges (default 15)
    @return GestureConnection
]]
function Gesture.DraggableWithSnap(target: GuiObject, snapPadding: number?): GestureConnection
    local padding = snapPadding or 15
    local connections: { RBXScriptConnection } = {}
    local dragging = false
    local dragStart: Vector3? = nil
    local startPos: UDim2 = target.Position
    
    table.insert(connections, target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end))
    
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and
           input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end))
    
    local function snapToEdge()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local absPos = target.AbsolutePosition
        local absSize = target.AbsoluteSize
        local centerX = absPos.X + absSize.X / 2
        
        local targetX: number
        if centerX < viewportSize.X / 2 then
            -- Snap to left edge
            targetX = padding
        else
            -- Snap to right edge
            targetX = viewportSize.X - absSize.X - padding
        end
        
        -- Clamp Y
        local targetY = math.clamp(
            absPos.Y,
            padding,
            viewportSize.Y - absSize.Y - padding
        )
        
        -- Animate snap
        local TweenService = game:GetService("TweenService")
        local tween = TweenService:Create(target, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetX, 0, targetY)
        })
        tween:Play()
    end
    
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                dragging = false
                snapToEdge()
            end
        end
    end))
    
    return {
        Disconnect = function()
            dragging = false
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            table.clear(connections)
        end
    }
end

return Gesture
