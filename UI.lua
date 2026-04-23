-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Library init / globals
getgenv().Lemon = getgenv().Lemon or {}
local Lemon = getgenv().Lemon

getgenv().Library = Lemon

Lemon.Directory    = "Lemon"
Lemon.Folders      = {"/configs"}
Lemon.Flags        = {}
Lemon.ConfigFlags  = {}
Lemon.Connections  = {}
Lemon.Notifications= {Notifs = {}}
Lemon.__index      = Lemon

local Flags          = Lemon.Flags
local ConfigFlags    = Lemon.ConfigFlags
local Notifications  = Lemon.Notifications

-- Chat system globals
Lemon.ChatUsers = {}
Lemon.ChatMessages = {}
Lemon.LiveCount = 0
Lemon.ChatEnabled = false
Lemon.DisplayedMessages = {}

-- FastAPI connection
local FASTAPI_URL = "http://212.132.99.151:9611"

local themes = {
    preset = {
        accent       = rgb(255, 255, 0),
        glow         = rgb(0, 0, 0),
        background   = rgb(16, 16, 19),
        section      = rgb(20, 20, 24),
        element      = rgb(28, 28, 32),
        outline      = rgb(35, 35, 40),
        text         = rgb(245, 245, 245),
        subtext      = rgb(140, 140, 145),
        tab_active   = rgb(255, 255, 0),
        tab_inactive = rgb(16, 16, 19),
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

Lemon.ProfileImages = {}
Lemon.DefaultProfileImages = {
    "rbxassetid://11293977610",
    "rbxassetid://11293977610",
    "rbxassetid://11293977610",
}

for _, path in Lemon.Folders do
    pcall(function() makefolder(Lemon.Directory .. path) end)
end

-- Helper functions
function Lemon:Tween(Object, Properties, Info)
    if not Object then return end
    local tween = TweenService:Create(Object, Info or TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
    tween:Play()
    return tween
end

function Lemon:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do 
        if prop == "FontFace" then
            -- Skip FontFace if it's causing issues, use Font instead
        else
            pcall(function() ins[prop] = value end)
        end
    end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

function Lemon:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function Lemon:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
end

function Lemon:AutoSize(frame)
    local function updateSize()
        local screenSize = Workspace.CurrentCamera.ViewportSize
        if screenSize.X < 768 then
            frame.Size = UDim2.new(0, math.min(screenSize.X - 20, 600), 0, math.min(screenSize.Y - 40, 450))
        elseif screenSize.X < 1024 then
            frame.Size = UDim2.new(0, math.min(screenSize.X * 0.8, 700), 0, math.min(screenSize.Y * 0.8, 500))
        else
            frame.Size = UDim2.new(0, 720, 0, 500)
        end
        frame.Position = UDim2.new(0.5, -frame.Size.X.Offset/2, 0.5, -frame.Size.Y.Offset/2)
    end
    updateSize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end

function Lemon:Resizify(Parent)
    local Resizing = Lemon:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 20, 0, 20),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Lemon:Create("ImageLabel", {
        Parent = Resizing, AnchorPoint = vec2(1, 1), Position = dim2(1, -4, 1, -4), Size = dim2(0, 10, 0, 10),
        BackgroundTransparency = 1, Image = "rbxassetid://11293977610", ImageColor3 = themes.preset.subtext, ImageTransparency = 0.5
    })

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(300, 250)
    local MAX_SIZE = vec2(1000, 800)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true; StartInputPos = input.Position; StartSize = Parent.AbsoluteSize
        end
    end)
    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsResizing = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X), math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y))
        end
    end)
end

function Lemon:GetRandomProfileImage()
    if #Lemon.ProfileImages > 0 then
        return Lemon.ProfileImages[math.random(1, #Lemon.ProfileImages)]
    end
    return Lemon.DefaultProfileImages[math.random(1, #Lemon.DefaultProfileImages)]
end

-- Window function
function Lemon:Window(properties)
    local Cfg = {
        Title = properties.Title or "Lemon", 
        Subtitle = properties.Subtitle or "",
        Size = properties.Size or dim2(0, 720, 0, 500), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
        StreamerMode = false,
    }

    if Lemon.Gui then Lemon.Gui:Destroy() end
    if Lemon.Other then Lemon.Other:Destroy() end
    if Lemon.ToggleGui then Lemon.ToggleGui:Destroy() end

    Lemon.Gui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "Lemon", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Lemon.Other = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = Lemon:Create("Frame", {
        Parent = Lemon.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    Lemon:AutoSize(Items.Wrapper)
    
    Items.Glow = Lemon:Create("ImageLabel", {
        ImageColor3 = themes.preset.glow,
        ScaleType = Enum.ScaleType.Slice,
        ImageTransparency = 0.65,
        BorderColor3 = rgb(0, 0, 0),
        Parent = Items.Wrapper,
        Size = dim2(1, 40, 1, 40),
        Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1,
        Position = dim2(0, -20, 0, -20),
        BorderSizePixel = 0,
        SliceCenter = rect(vec2(21, 21), vec2(79, 79)),
        ZIndex = 0
    })
    Lemon:Themify(Items.Glow, "glow", "ImageColor3")

    Items.Window = Lemon:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Lemon:Themify(Items.Window, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 6) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 2 })

    -- Top Right: Profile image, username and status
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    
    Items.TopRightFrame = Lemon:Create("Frame", {
        Parent = Items.Header,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -20, 0.5, 0),
        Size = dim2(0, 130, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 4
    })
    
    Items.AvatarFrameTop = Lemon:Create("Frame", {
        Parent = Items.TopRightFrame,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, 0, 0.5, 0),
        Size = dim2(0, 28, 0, 28),
        BackgroundColor3 = themes.preset.element,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    Lemon:Themify(Items.AvatarFrameTop, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.AvatarFrameTop, CornerRadius = dim(0, 6) })
    
    Items.AvatarTop = Lemon:Create("ImageLabel", {
        Parent = Items.AvatarFrameTop,
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = headshot,
        ZIndex = 6
    })
    Lemon:Create("UICorner", { Parent = Items.AvatarTop, CornerRadius = dim(0, 6) })
    
    Items.UsernameTop = Lemon:Create("TextLabel", {
        Parent = Items.TopRightFrame,
        Text = lp.Name,
        TextColor3 = themes.preset.text,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -36, 0, 2),
        Size = dim2(0, 80, 0, 14),
        BackgroundTransparency = 1,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5
    })
    Lemon:Themify(Items.UsernameTop, "text", "TextColor3")
    
    Items.StatusTop = Lemon:Create("TextLabel", {
        Parent = Items.TopRightFrame,
        Text = "Premium",
        TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -36, 0, 18),
        Size = dim2(0, 80, 0, 12),
        BackgroundTransparency = 1,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5
    })
    Lemon:Themify(Items.StatusTop, "subtext", "TextColor3")

    Items.LogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 20, 0, 12),
        Size = dim2(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 20, 0, 26),
        Size = dim2(0, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.SubLogoText, "subtext", "TextColor3")

    Items.PageHolder = Lemon:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 50), Size = dim2(1, 0, 1, -50), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Tabs at bottom middle
    Items.TabHolder = Lemon:Create("Frame", { 
        Parent = Items.Wrapper, 
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 1, 10),
        Size = dim2(0, 0, 0, 40), 
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = themes.preset.section, 
        BorderSizePixel = 0, 
        ZIndex = 100
    })
    Lemon:Themify(Items.TabHolder, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.TabHolder, CornerRadius = dim(0, 8) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.TabHolder, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Lemon:Create("UIListLayout", { 
        Parent = Items.TabHolder, 
        FillDirection = Enum.FillDirection.Horizontal, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, 
        VerticalAlignment = Enum.VerticalAlignment.Center, 
        Padding = dim(0, 8) 
    })

    Items.Footer = Lemon:Create("Frame", { 
        Parent = Items.Window, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), 
        Size = dim2(1, 0, 0, 45), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 
    })

    -- Settings button - just a simple gear icon text button
    Items.SettingsBtn = Lemon:Create("TextButton", {
        Parent = Items.Footer, 
        AnchorPoint = vec2(1, 0.5), 
        Position = dim2(1, -50, 0.5, 0),
        Size = dim2(0, 80, 0, 24), 
        BackgroundColor3 = themes.preset.element, 
        Text = "⚙ Settings", 
        TextColor3 = themes.preset.text,
        TextSize = 12,
        ZIndex = 5
    })
    Lemon:Themify(Items.SettingsBtn, "element", "BackgroundColor3")
    Lemon:Themify(Items.SettingsBtn, "text", "TextColor3")
    Lemon:Create("UICorner", { Parent = Items.SettingsBtn, CornerRadius = dim(0, 4) })
    
    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    -- Dragging Logic
    local Dragging, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    Lemon:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
        if Items.TabHolder then Items.TabHolder.Visible = uiVisible end
    end

    if InputService.TouchEnabled then
        Lemon.ToggleGui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonToggle", IgnoreGuiInset = true })
        local ToggleButton = Lemon:Create("TextButton", {
            Name = "ToggleButton", Parent = Lemon.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 55, 0, 55),
            BackgroundColor3 = themes.preset.element, Text = "☰", TextColor3 = themes.preset.text, TextSize = 24, ZIndex = 10000,
        })
        Lemon:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 12) })
        Lemon:Themify(ToggleButton, "element", "BackgroundColor3")
        Lemon:Themify(Lemon:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, Lemon)
end

-- Tab
function Lemon:Tab(properties)
    local Cfg = { 
        Name = properties.Name or "Tab", 
        Icon = properties.Icon or "rbxassetid://11293977610", 
        Hidden = properties.Hidden or false, 
        Items = {} 
    }
    local Items = Cfg.Items

    if not Cfg.Hidden then
        Items.Button = Lemon:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 30, 0, 30), 
            BackgroundColor3 = themes.preset.tab_active,
            BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, ZIndex = 101 
        })
        Lemon:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
        
        Items.IconImg = Lemon:Create("TextLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Text = Cfg.Name:sub(1,1), TextColor3 = themes.preset.subtext, 
            TextSize = 12, ZIndex = 102 
        })
        Lemon:Themify(Items.IconImg, "subtext", "TextColor3")
    end

    Items.Pages = Lemon:Create("CanvasGroup", { Parent = Lemon.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Lemon:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 10), PaddingBottom = dim(0, 10), PaddingRight = dim(0, 20), PaddingLeft = dim(0, 20) })

    Items.Left = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 10) })

    Items.Right = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 10) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            Lemon:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween)
            Lemon:Tween(oldTab.IconImg, {TextColor3 = themes.preset.subtext}, buttonTween)
        end

        if Items.Button then 
            Lemon:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            Lemon:Tween(Items.IconImg, {TextColor3 = rgb(15, 15, 15)}, buttonTween) 
        end
        
        task.spawn(function()
            if oldTab then
                Lemon:Tween(oldTab.Pages, {GroupTransparency = 1}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Lemon.Other
            end

            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Lemon:Tween(Items.Pages, {GroupTransparency = 0}, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.wait(0.35)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Lemon)
end

-- Section
function Lemon:Section(properties)
    local Cfg = { 
        Name = properties.Name or "Section", 
        Side = properties.Side or "Left", 
        Icon = properties.Icon or "rbxassetid://11293977610",
        RightIcon = properties.RightIcon or "rbxassetid://11293977610",
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Lemon:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Lemon:Themify(Items.Section, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 6) })

    Items.AccentLine = Lemon:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 2, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })
    Lemon:Themify(Items.AccentLine, "accent", "BackgroundColor3")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 14, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -20, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "text", "TextColor3")

    Items.Container = Lemon:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 36), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 12), PaddingLeft = dim(0, 14), PaddingRight = dim(0, 14) })

    return setmetatable(Cfg, Lemon)
end

-- Toggle
function Lemon:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or "Toggle", 
        Flag = properties.Flag, 
        Default = properties.Default or false, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 22), BackgroundTransparency = 1, Text = "" })
    
    Items.Checkbox = Lemon:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 6, 0.5, 0), Size = dim2(0, 14, 0, 14), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Lemon:Themify(Items.Checkbox, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Checkbox, CornerRadius = dim(0, 3) })

    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 30, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -26, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    local State = false
    function Cfg.set(bool)
        State = bool
        Lemon:Tween(Items.Checkbox, {BackgroundColor3 = State and themes.preset.text or themes.preset.element}, TweenInfo.new(0.2))
        Lemon:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.2))
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

-- Button
function Lemon:Button(properties)
    local Cfg = { 
        Name = properties.Name or "Button", 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 30), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, AutoButtonColor = false 
    })
    Lemon:Themify(Items.Button, "element", "BackgroundColor3")
    Lemon:Themify(Items.Button, "subtext", "TextColor3")
    Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 4) })

    Items.Button.MouseButton1Click:Connect(function()
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.outline, TextColor3 = themes.preset.text}, TweenInfo.new(0.1))
        task.wait(0.1)
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Lemon)
end

-- Slider
function Lemon:Slider(properties)
    local Cfg = { 
        Name = properties.Name or "Slider", 
        Flag = properties.Flag, 
        Min = properties.Min or 0, 
        Max = properties.Max or 100, 
        Default = properties.Default or 0, 
        Increment = properties.Increment or 1, 
        Suffix = properties.Suffix or "", 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 38), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Val = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
    Lemon:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Lemon:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 4, 0, 24), Size = dim2(1, -8, 0, 6), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Lemon:Themify(Items.Track, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })

    Items.Fill = Lemon:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.text })
    Lemon:Themify(Items.Fill, "text", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })

    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        Lemon:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.15))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = true
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) 
        end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Textbox
function Lemon:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or "", 
        Placeholder = properties.Placeholder or "Enter text...", 
        Default = properties.Default or "", 
        Flag = properties.Flag, 
        Numeric = properties.Numeric or false, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 32), BackgroundTransparency = 1 })
    Items.Bg = Lemon:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Lemon:Themify(Items.Bg, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 4) })

    Items.Input = Lemon:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Lemon:Themify(Items.Input, "text", "TextColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

-- Label
function Lemon:Label(properties)
    local Cfg = { 
        Name = properties.Name or "Label", 
        Wrapped = properties.Wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 18), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Lemon)
end

-- Dropdown
function Lemon:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or "Dropdown", 
        Flag = properties.Flag, 
        Options = properties.Options or {}, 
        Default = properties.Default, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 46), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 16), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Main = Lemon:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 20), Size = dim2(1, 0, 0, 26), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Lemon:Themify(Items.Main, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 4) })

    Items.SelectedText = Lemon:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.subtext, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.SelectedText, "subtext", "TextColor3")
    
    Items.Icon = Lemon:Create("TextLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 10, 0, 10), BackgroundTransparency = 1, Text = "▼", TextColor3 = themes.preset.subtext, TextSize = 10 })

    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Lemon.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })

    Items.Scroll = Lemon:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -8), Position = dim2(0, 0, 0, 4), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, ZIndex = 201 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false

    local function ToggleDropdown()
        if isTweening then return end
        Open = not Open
        isTweening = true

        if Open then
            Items.DropFrame.Visible = true
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 4)
            local targetHeight = math.clamp(#Cfg.Options * 24 + 8, 0, 150)
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
                
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
                   not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    ToggleDropdown()
                end
            end
        end
    end)

    local OptionBtns = {}
    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, btn in ipairs(OptionBtns) do btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = Lemon:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 24), BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 13, 
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
            })
            Lemon:Themify(btn, "subtext", "TextColor3")
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, btn)
        end
    end

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

-- Colorpicker
function Lemon:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or rgb(255, 255, 255), 
        Callback = properties.Callback or function() end, 
        Flag = properties.Flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local btn = Lemon:Create("TextButton", { 
        Parent = self.Items.Title or self.Items.Container, 
        AnchorPoint = vec2(1, 0.5), 
        Position = dim2(1, -6, 0.5, 0), 
        Size = dim2(0, 30, 0, 14), 
        BackgroundColor3 = Cfg.Color, 
        Text = "" 
    })
    Lemon:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 4)})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Lemon.Gui, 
        Size = dim2(0, 150, 0, 0), 
        BackgroundColor3 = themes.preset.element, 
        Visible = false, 
        ZIndex = 200, 
        ClipsDescendants = true 
    })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })

    Items.HueBar = Lemon:Create("TextButton", { 
        Parent = Items.DropFrame, 
        Position = dim2(0, 8, 1, -22), 
        Size = dim2(1, -16, 0, 14), 
        AutoButtonColor = false, 
        Text = "", 
        BorderSizePixel = 0, 
        BackgroundColor3 = rgb(255, 255, 255), 
        ZIndex = 201 
    })
    Lemon:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 3) })

    local Open = false
    local isTweening = false

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
            Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X + btn.AbsoluteSize.X - 150, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 2)
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, 150, 0, 140)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, 150, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = btn.AbsolutePosition, btn.AbsoluteSize
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    Toggle()
                end
            end
        end
    end)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local hueDragging = false
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
            h = 1 - x
            Cfg.set(Color3.fromHSV(h, 1, 1))
        end
    end)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Keybind
function Lemon:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or "Keybind", 
        Flag = properties.Flag, 
        Default = properties.Default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    
    local KeyBtnContainer = Lemon:Create("TextButton", { 
        Parent = self.Items.Title or self.Items.Container, 
        AnchorPoint = vec2(1, 0.5), 
        Position = dim2(1, -6, 0.5, 0), 
        Size = dim2(0, 40, 0, 16), 
        BackgroundColor3 = themes.preset.element, 
        Text = "", 
        AutoButtonColor = false 
    })
    Lemon:Themify(KeyBtnContainer, "element", "BackgroundColor3")
    Lemon:Create("UICorner", {Parent = KeyBtnContainer, CornerRadius = dim(0, 4)})
    
    local KeyBtn = Lemon:Create("TextLabel", {
        Parent = KeyBtnContainer,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = themes.preset.subtext, 
        Text = Keys[Cfg.Default] or "None", 
        TextSize = 12
    })
    Lemon:Themify(KeyBtn, "subtext", "TextColor3")
    
    local binding = false
    
    KeyBtnContainer.MouseButton1Click:Connect(function()
        binding = true
        KeyBtn.Text = "..."
    end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false
                Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false
                Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Configs
function Lemon:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "Settings", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left"})

    local ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    function Lemon:UpdateConfigList()
        if not ConfigHolder then return end
        local List = {}
        for _, file in listfiles(Lemon.Directory .. "/configs") do
            local Name = file:gsub(Lemon.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Lemon.Directory .. "\\configs\\", "")
            List[#List + 1] = Name
        end
        ConfigHolder.RefreshOptions(List)
    end

    Lemon:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Lemon:GetConfig())
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            Lemon:LoadConfig(readfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Theme Settings", Side = "Right"})

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("text", color3) end, Color = themes.preset.text })

    local SettingsSection = Tab:Section({Name = "Settings", Side = "Right"})
    
    SettingsSection:Toggle({
        Name = "Streamer Mode",
        Default = false,
        Callback = function(state)
            window.StreamerMode = state
            if state then
                window.Items.UsernameTop.Text = "User"
            else
                window.Items.UsernameTop.Text = lp.Name
            end
        end,
        Flag = "streamer_mode"
    })

    window.Tweening = true
    SettingsSection:Label({Name = "Menu Bind"}):Keybind({
        Default = Enum.KeyCode.RightShift,
        Callback = function() if window.Tweening then return end window.ToggleMenu() end,
        Flag = "menu_bind"
    })
    task.delay(1, function() window.Tweening = false end)
end

-- Get Config
function Lemon:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

-- Load Config
function Lemon:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

-- Notifications
function Notifications:RefreshNotifications()
    local offset = 50
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 36)
        Lemon:Tween(v, {Position = dim_offset(20, offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 10)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Name = properties.Name or "Notification", 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5, 
        Items = {} 
    }
    local Items = Cfg.Items
   
    Items.Outline = Lemon:Create("Frame", { Parent = Lemon.Gui, Position = dim_offset(-500, 50), Size = dim2(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 300, ClipsDescendants = true })
    Lemon:Themify(Items.Outline, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 4) })
   
    Items.Name = Lemon:Create("TextLabel", {
        Parent = Items.Outline, Text = Cfg.Name, TextColor3 = themes.preset.text,
        BackgroundTransparency = 1, Size = dim2(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 302
    })
    Lemon:Themify(Items.Name, "text", "TextColor3")
   
    Lemon:Create("UIPadding", { Parent = Items.Name, PaddingTop = dim(0, 10), PaddingBottom = dim(0, 10), PaddingRight = dim(0, 12), PaddingLeft = dim(0, 12) })
   
    Items.TimeBar = Lemon:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 2), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Lemon:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 50)
        Notifications:RefreshNotifications()
        Lemon:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 2)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        Lemon:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.4)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        task.wait(0.05)
        Notifications:RefreshNotifications()
    end)
end

return Lemon
