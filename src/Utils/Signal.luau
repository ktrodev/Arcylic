--[[
    AcrylicUI - Signal Utility
    
    A lightweight event/signal system for custom event dispatching.
    Similar to RBXScriptSignal but for custom library events.
]]

local Signal = {}
Signal.__index = Signal

export type Connection = {
    Disconnect: (self: Connection) -> (),
    Connected: boolean
}

export type SignalObject = {
    Connect: (self: SignalObject, callback: (...any) -> ()) -> Connection,
    Once: (self: SignalObject, callback: (...any) -> ()) -> Connection,
    Fire: (self: SignalObject, ...any) -> (),
    Wait: (self: SignalObject) -> ...any,
    DisconnectAll: (self: SignalObject) -> (),
    Destroy: (self: SignalObject) -> ()
}

--[[
    Creates a new Signal
    
    @return SignalObject
    
    @example
    local onChanged = Signal.new()
    onChanged:Connect(function(value)
        print("Changed to:", value)
    end)
    onChanged:Fire("hello")
]]
function Signal.new(): SignalObject
    local self = setmetatable({}, Signal)
    self._connections = {}
    self._waiting = {}
    return self
end

--[[
    Connects a callback to the signal
    
    @param callback function - The function to call when fired
    @return Connection
]]
function Signal:Connect(callback: (...any) -> ()): Connection
    local connection = {
        Connected = true,
        _callback = callback,
        _signal = self
    }
    
    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        self._callback = nil
        
        local idx = table.find(self._signal._connections, self)
        if idx then
            table.remove(self._signal._connections, idx)
        end
    end
    
    table.insert(self._connections, connection)
    return connection
end

--[[
    Connects a callback that fires only once then auto-disconnects
    
    @param callback function - The function to call
    @return Connection
]]
function Signal:Once(callback: (...any) -> ()): Connection
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

--[[
    Fires the signal with the given arguments
    
    @param ... any - Arguments to pass to connected callbacks
]]
function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection._callback, ...)
        end
    end
    
    -- Resume any waiting threads
    for _, thread in ipairs(self._waiting) do
        task.spawn(thread, ...)
    end
    table.clear(self._waiting)
end

--[[
    Yields the current thread until the signal fires
    
    @return ... any - The arguments the signal was fired with
]]
function Signal:Wait()
    table.insert(self._waiting, coroutine.running())
    return coroutine.yield()
end

--[[
    Disconnects all connections
]]
function Signal:DisconnectAll()
    for _, connection in ipairs(self._connections) do
        connection.Connected = false
        connection._callback = nil
    end
    table.clear(self._connections)
end

--[[
    Destroys the signal and cleans up
]]
function Signal:Destroy()
    self:DisconnectAll()
    table.clear(self._waiting)
end

return Signal
