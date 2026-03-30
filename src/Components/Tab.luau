--[[
    AcrylicUI - Tab Component v2.2.0
    
    A tab within a sidebar section. Contains content elements and supports:
    - All component types (Toggle, Slider, Button, Dropdown, etc.)
    - New: SearchBar, ProgressBar, Divider, Label
    - Tab badges (notification dots/counts)
    - Component visibility API
    - Config section builder
    - Flag auto-registration
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Button = require(script.Parent.Button)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local Dropdown = require(script.Parent.Dropdown)

local Tab = {}
Tab.__index = Tab

function Tab.new(window, section, name: string, icon: string?)
    local self = setmetatable({}, Tab)
    self._window = window
    self._section = section
    self._name = name
    self._components = {}

    -- Button in sidebar
    self._button = Create.Instance("Frame", {
        Name = name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, Sizes.Tab.Width, 0, Sizes.Tab.Height),
        ClipsDescendants = false,
        Parent = section._tabsContainer
    })

    Create.Corner(self._button, Sizes.Corner.Medium)
    self._stroke = Create.Stroke(self._button, Colors.Border, 1)

    self._icon = Create.Instance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = icon or "rbxassetid://112235310154264",
        ImageColor3 = Colors.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = self._button
    })

    self._text = Create.Instance("TextLabel", {
        Name = "TabText",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 33, 0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        TextSize = Fonts.Size.Small,
        Parent = self._button
    })

    Create.Instance("UIPadding", { PaddingRight = UDim.new(0, 9), Parent = self._text })

    -- Badge (hidden by default)
    self._badge = Create.Instance("Frame", {
        Name = "Badge",
        BackgroundColor3 = Color3.fromRGB(255, 60, 60),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -4, 0, 4),
        Size = UDim2.new(0, 0, 0, 0),
        Visible = false,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self._button
    })
    Create.Corner(self._badge, 8)
    
    self._badgeLabel = Create.Instance("TextLabel", {
        Name = "BadgeText",
        FontFace = Fonts.Bold,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "",
        TextSize = 9,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
        Parent = self._badge
    })

    local click = Create.Instance("TextButton", {
        Name = "Click",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._button
    })

    -- Content frame
    self._content = Create.Instance("Frame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = window:GetContentContainer()
    })

    Create.ListLayout(self._content, 8)

    click.MouseButton1Click:Connect(function()
        window:SelectTab(self)
    end)

    click.MouseEnter:Connect(function()
        if window._currentTab ~= self then
            Tween.Create(self._button, { BackgroundTransparency = 0.7 }, "Fast")
        end
    end)

    click.MouseLeave:Connect(function()
        if window._currentTab ~= self then
            Tween.Create(self._button, { BackgroundTransparency = 1 }, "Fast")
        end
    end)

    -- Register with window for swipe navigation
    window:RegisterTab(self)

    return self
end

function Tab:Select()
    self._content.Visible = true
    Tween.Create(self._button, { BackgroundTransparency = 0.4 }, "Fast")
    Tween.Create(self._text, { TextColor3 = Colors.Text }, "Fast")
    Tween.Create(self._icon, { ImageColor3 = Colors.Text }, "Fast")
    self._stroke.Transparency = 0
end

function Tab:Deselect()
    self._content.Visible = false
    Tween.Create(self._button, { BackgroundTransparency = 1 }, "Fast")
    Tween.Create(self._text, { TextColor3 = Colors.TextDark }, "Fast")
    Tween.Create(self._icon, { ImageColor3 = Colors.TextDark }, "Fast")
    self._stroke.Transparency = 1
end

-- ============================================================================
-- Badge System
-- ============================================================================

--[[
    Sets a badge on the tab
    
    @param value string | number - Badge text (number shows count, "!" for alert)
    
    @example
    tab:SetBadge(3)     -- shows "3" bubble
    tab:SetBadge("!")   -- shows "!" bubble
]]
function Tab:SetBadge(value: string | number)
    local text = tostring(value)
    self._badgeLabel.Text = text
    
    -- Size badge based on content
    local width = math.max(16, #text * 7 + 8)
    self._badge.Size = UDim2.new(0, width, 0, 16)
    self._badge.Visible = true
    
    -- Pop-in animation
    self._badge.Size = UDim2.new(0, 0, 0, 0)
    Tween.Create(self._badge, {
        Size = UDim2.new(0, width, 0, 16)
    }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

--[[
    Clears the tab badge
]]
function Tab:ClearBadge()
    Tween.CreateWithCallback(self._badge, {
        Size = UDim2.new(0, 0, 0, 0)
    }, 0.15, function()
        self._badge.Visible = false
    end)
end

-- ============================================================================
-- Content creation helpers
-- ============================================================================

local function registerFlag(window, config, component)
    if config and config.Flag then
        window:RegisterFlag(config.Flag, component)
    end
end

function Tab:CreateSection(title: string)
    local label = Create.Instance("TextLabel", {
        Name = "Section" .. title,
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextSize = 15,
        Size = UDim2.new(1, 0, 0, 25),
        Parent = self._content
    })
    return label
end

function Tab:CreateParagraph(config)
    local Paragraph = require(script.Parent.Paragraph)
    local p = Paragraph.new(self._content, config)
    table.insert(self._components, p)
    return p
end

function Tab:CreateButton(config)
    local b = Button.new(self._content, config)
    table.insert(self._components, b)
    return b
end

function Tab:CreateToggle(config)
    local t = Toggle.new(self._content, config)
    registerFlag(self._window, config, t)
    table.insert(self._components, t)
    return t
end

function Tab:CreateSlider(config)
    local s = Slider.new(self._content, config)
    registerFlag(self._window, config, s)
    table.insert(self._components, s)
    return s
end

function Tab:CreateDropdown(config)
    local d = Dropdown.new(self._content, config)
    registerFlag(self._window, config, d)
    table.insert(self._components, d)
    return d
end

function Tab:CreateKeybind(config)
    local Keybind = require(script.Parent.Keybind)
    local k = Keybind.new(self._content, config, self._window)
    registerFlag(self._window, config, k)
    table.insert(self._components, k)
    return k
end

function Tab:CreateColorPicker(config)
    local ColorPicker = require(script.Parent.ColorPicker)
    local c = ColorPicker.new(self._content, config)
    registerFlag(self._window, config, c)
    table.insert(self._components, c)
    return c
end

function Tab:CreateTextBox(config)
    local TextBox = require(script.Parent.TextBox)
    local t = TextBox.new(self._content, config)
    registerFlag(self._window, config, t)
    table.insert(self._components, t)
    return t
end

-- ============================================================================
-- NEW: Wave 2 Components
-- ============================================================================

--[[
    Creates a search bar with real-time filtering
]]
function Tab:CreateSearchBar(config)
    local SearchBar = require(script.Parent.SearchBar)
    local s = SearchBar.new(self._content, config)
    table.insert(self._components, s)
    return s
end

--[[
    Creates a progress bar
]]
function Tab:CreateProgressBar(config)
    local ProgressBar = require(script.Parent.ProgressBar)
    local p = ProgressBar.new(self._content, config)
    registerFlag(self._window, config, p)
    table.insert(self._components, p)
    return p
end

--[[
    Creates a visual divider/separator
    
    @param text string? - Optional centered text
]]
function Tab:CreateDivider(text: string?)
    local Divider = require(script.Parent.Divider)
    local d = Divider.new(self._content, text)
    table.insert(self._components, d)
    return d
end

--[[
    Creates a simple label for status display
]]
function Tab:CreateLabel(config)
    local Label = require(script.Parent.Label)
    local l = Label.new(self._content, config)
    table.insert(self._components, l)
    return l
end

-- ============================================================================
-- Config Section (pre-built UI)
-- ============================================================================

function Tab:CreateConfigSection()
    local configSection = {}
    
    self:CreateSection("Configuration")
    
    local TextBoxMod = require(script.Parent.TextBox)
    local configNameInput = TextBoxMod.new(self._content, {
        Name = "Config Name",
        Default = "",
        Placeholder = "Enter config name..."
    })
    
    local configs = self._window:GetConfigs()
    local configDropdown = Dropdown.new(self._content, {
        Name = "Saved Configs",
        Options = #configs > 0 and configs or {"No configs found"},
        Default = configs[1] or "No configs found"
    })
    
    Button.new(self._content, {
        Name = "Save Config",
        Callback = function()
            local name = configNameInput:GetText()
            if name and name ~= "" then
                local success = self._window:SaveConfig(name)
                self._window:Notify({
                    Title = success and "Config Saved" or "Save Failed",
                    Description = success and ("Saved as '" .. name .. "'") or "Could not save config",
                    Duration = 2,
                    Type = success and "success" or "error"
                })
                if success then configSection:RefreshConfigs() end
            else
                self._window:Notify({ Title = "Error", Description = "Please enter a config name", Duration = 2, Type = "error" })
            end
        end
    })
    
    Button.new(self._content, {
        Name = "Load Config",
        Callback = function()
            local selected = configDropdown:GetValue()
            if selected and selected ~= "No configs found" then
                local success = self._window:LoadConfig(selected)
                self._window:Notify({
                    Title = success and "Config Loaded" or "Load Failed",
                    Description = success and ("Loaded '" .. selected .. "'") or "Could not load config",
                    Duration = 2,
                    Type = success and "success" or "error"
                })
            end
        end
    })
    
    Button.new(self._content, {
        Name = "Delete Config",
        Callback = function()
            local selected = configDropdown:GetValue()
            if selected and selected ~= "No configs found" then
                local success = self._window:DeleteConfig(selected)
                self._window:Notify({
                    Title = success and "Config Deleted" or "Delete Failed",
                    Description = success and ("Deleted '" .. selected .. "'") or "Could not delete config",
                    Duration = 2,
                    Type = success and "success" or "error"
                })
                if success then configSection:RefreshConfigs() end
            end
        end
    })
    
    Button.new(self._content, {
        Name = "Refresh Configs",
        Callback = function()
            configSection:RefreshConfigs()
        end
    })
    
    Toggle.new(self._content, {
        Name = "Auto Save",
        Default = false,
        Callback = function(enabled)
            self._window:SetAutoSave(enabled)
            self._window:Notify({
                Title = "Auto Save",
                Description = enabled and "Auto-save enabled (every 30s)" or "Auto-save disabled",
                Duration = 2,
                Type = "info"
            })
        end
    })
    
    function configSection:RefreshConfigs()
        local newConfigs = self._window and self._window:GetConfigs()
        if not newConfigs then newConfigs = {} end
        configDropdown:Refresh(#newConfigs > 0 and newConfigs or {"No configs found"})
    end
    
    configSection._window = self._window
    return configSection
end

return Tab
