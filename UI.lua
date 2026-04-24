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
        accent       = rgb(255, 255, 0),   -- Yellow
        glow         = rgb(0, 0, 0),       -- Black
        
        background   = rgb(16, 16, 19),      
        section      = rgb(20, 20, 24),      
        element      = rgb(28, 28, 32),     
        
        outline      = rgb(35, 35, 40),      
        text         = rgb(245, 245, 245),   
        subtext      = rgb(140, 140, 145),  
        
        tab_active   = rgb(255, 255, 0),   -- Yellow
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

-- Roblox profile images array
Lemon.ProfileImages = {}
Lemon.DefaultProfileImages = {
    "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-123ABC123ABC123ABC123ABC123ABC123ABC-Png/150/150/AvatarHeadshot/Webp/noFilter",
    "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-456DEF456DEF456DEF456DEF456DEF456DEF-Png/150/150/AvatarHeadshot/Webp/noFilter",
    "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-789GHI789GHI789GHI789GHI789GHI789GHI-Png/150/150/AvatarHeadshot/Webp/noFilter",
    "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-JKL012JKL012JKL012JKL012JKL012JKL012-Png/150/150/AvatarHeadshot/Webp/noFilter",
    "https://tr.rbxcdn.com/30DAY-AvatarHeadshot-MNO345MNO345MNO345MNO345MNO345MNO345-Png/150/150/AvatarHeadshot/Webp/noFilter",
}

for _, path in Lemon.Folders do
    pcall(function() makefolder(Lemon.Directory .. path) end)
end

-- misc helpers
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
            pcall(function()
                ins.FontFace = value
            end)
        elseif prop == "Font" then
            pcall(function()
                ins.Font = value
            end)
        else
            pcall(function()
                ins[prop] = value
            end)
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

-- Auto-sizing for different devices
function Lemon:AutoSize(frame)
    local function updateSize()
        local screenSize = Workspace.CurrentCamera.ViewportSize
        local aspectRatio = screenSize.X / screenSize.Y
        
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
    local UIS = game:GetService("UserInputService")
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
    UIS.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X), math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y))
        end
    end)
end

-- Get random profile image
function Lemon:GetRandomProfileImage()
    if #Lemon.ProfileImages > 0 then
        return Lemon.ProfileImages[math.random(1, #Lemon.ProfileImages)]
    end
    return Lemon.DefaultProfileImages[math.random(1, #Lemon.DefaultProfileImages)]
end

-- Chat system functions
function Lemon:InitializeChat()
    -- Create chat UI attached to the main wrapper (moves with UI)
    local chatFrame = Lemon:Create("Frame", {
        Parent = Lemon.Gui,
        Name = "ChatSystem",
        Size = UDim2.new(0, 280, 0, 350),
        Position = UDim2.new(0, -300, 0.5, -175),
        BackgroundColor3 = themes.preset.background,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 1000
    })
    Lemon:Create("UICorner", { Parent = chatFrame, CornerRadius = UDim.new(0, 12) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = chatFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    -- Chat header
    local headerFrame = Lemon:Create("Frame", {
        Parent = chatFrame,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0
    })
    Lemon:Create("UICorner", { Parent = headerFrame, CornerRadius = UDim.new(0, 12) })
    
    -- Global Chat text
    local globalChatText = Lemon:Create("TextLabel", {
        Parent = headerFrame,
        Text = "Global Chat",
        TextColor3 = themes.preset.text,
        Position = UDim2.new(0, 15, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 100, 0, 20),
        BackgroundTransparency = 1,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(globalChatText, "text", "TextColor3")
    
    -- Live counter
    local liveCounter = Lemon:Create("TextLabel", {
        Parent = headerFrame,
        Text = "🟢 Live: 0",
        TextColor3 = themes.preset.text,
        Position = UDim2.new(1, -15, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 80, 0, 20),
        BackgroundTransparency = 1,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Lemon:Themify(liveCounter, "text", "TextColor3")
    
    -- Chat messages container
    local messagesFrame = Lemon:Create("ScrollingFrame", {
        Parent = chatFrame,
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(1, 0, 1, -90),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = messagesFrame, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = messagesFrame, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 12) })
    
    -- Chat input
    local inputFrame = Lemon:Create("Frame", {
        Parent = chatFrame,
        Position = UDim2.new(0, 0, 1, -45),
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0
    })
    
    local chatInput = Lemon:Create("TextBox", {
        Parent = inputFrame,
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -24, 0, 32),
        BackgroundColor3 = themes.preset.element,
        Text = "",
        PlaceholderText = "Type a message...",
        TextColor3 = themes.preset.text,
        PlaceholderColor3 = themes.preset.subtext,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 14,
        ClearTextOnFocus = false
    })
    Lemon:Create("UICorner", { Parent = chatInput, CornerRadius = UDim.new(0, 6) })
    Lemon:Themify(chatInput, "element", "BackgroundColor3")
    Lemon:Themify(chatInput, "text", "TextColor3")
    
    -- Store references
    Lemon.ChatFrame = chatFrame
    Lemon.MessagesFrame = messagesFrame
    Lemon.ChatInput = chatInput
    Lemon.LiveCounter = liveCounter
    
    -- Chat input handler
    chatInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and chatInput.Text ~= "" then
            Lemon:SendChatMessage(lp.Name, chatInput.Text)
            chatInput.Text = ""
        end
    end)
    
    -- Connect to FastAPI for chat
    task.spawn(function()
        Lemon:ConnectToChatServer()
    end)
end

function Lemon:SendChatMessage(username, message)
    local timestamp = os.date("%H:%M:%S")
    local profileImage = Lemon:GetRandomProfileImage()
    
    local messageData = {
        username = username,
        message = message,
        timestamp = timestamp,
        profileImage = profileImage
    }
    
    -- Send to FastAPI
    task.spawn(function()
        pcall(function()
            HttpService:PostAsync(FASTAPI_URL .. "/chat/message", HttpService:JSONEncode(messageData))
        end)
    end)
    
    -- Display locally
    Lemon:DisplayChatMessage(messageData)
end

function Lemon:DisplayChatMessage(messageData)
    local messageKey = messageData.username .. messageData.message .. messageData.timestamp
    if Lemon.DisplayedMessages[messageKey] then return end
    Lemon.DisplayedMessages[messageKey] = true
    
    local messageFrame = Lemon:Create("Frame", {
        Parent = Lemon.MessagesFrame,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    -- Profile image (slightly bigger)
    local profileImage = Lemon:Create("ImageLabel", {
        Parent = messageFrame,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 33, 0, 33),
        Image = messageData.profileImage or Lemon:GetRandomProfileImage(),
        BackgroundTransparency = 1
    })
    Lemon:Create("UICorner", { Parent = profileImage, CornerRadius = UDim.new(1, 0) })
    
    -- Username (smaller text)
    local usernameText = Lemon:Create("TextLabel", {
        Parent = messageFrame,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -80, 0, 13),
        BackgroundTransparency = 1,
        Text = messageData.username,
        TextColor3 = themes.preset.accent,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(usernameText, "accent", "TextColor3")
    
    -- Message text (smaller)
    local messageText = Lemon:Create("TextLabel", {
        Parent = messageFrame,
        Position = UDim2.new(0, 40, 0, 15),
        Size = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
        Text = messageData.message,
        TextColor3 = themes.preset.text,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    Lemon:Themify(messageText, "text", "TextColor3")
    
    -- Timestamp
    local timestampText = Lemon:Create("TextLabel", {
        Parent = messageFrame,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 35, 0, 13),
        BackgroundTransparency = 1,
        Text = messageData.timestamp,
        TextColor3 = themes.preset.subtext,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Lemon:Themify(timestampText, "subtext", "TextColor3")
    
    -- Auto scroll to bottom
    local contentHeight = 0
    for _, child in ipairs(Lemon.MessagesFrame:GetChildren()) do
        if child:IsA("Frame") then
            contentHeight = contentHeight + child.AbsoluteSize.Y + 5
        end
    end
    Lemon.MessagesFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

function Lemon:JoinChatMessage(username)
    local systemMessage = {
        username = "System",
        message = username .. " joined the chat",
        timestamp = os.date("%H:%M:%S"),
        profileImage = "rbxassetid://11293977610"
    }
    Lemon:DisplayChatMessage(systemMessage)
    Lemon.LiveCount = Lemon.LiveCount + 1
    Lemon:UpdateLiveCount()
end

function Lemon:LeaveChatMessage(username)
    local systemMessage = {
        username = "System",
        message = username .. " left the chat",
        timestamp = os.date("%H:%M:%S"),
        profileImage = "rbxassetid://11293977610"
    }
    Lemon:DisplayChatMessage(systemMessage)
    Lemon.LiveCount = math.max(0, Lemon.LiveCount - 1)
    Lemon:UpdateLiveCount()
end

function Lemon:UpdateLiveCount()
    if Lemon.LiveCounter then
        Lemon.LiveCounter.Text = "🟢 Live: " .. Lemon.LiveCount
    end
end

function Lemon:ConnectToChatServer()
    task.spawn(function()
        local success, response = pcall(function()
            return game:HttpGet(FASTAPI_URL .. "/profile-images?count=100")
        end)
        
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.images and #data.images > 0 then
                Lemon.ProfileImages = data.images
                print("[Lemon] Successfully loaded " .. #Lemon.ProfileImages .. " profile images from Pexels")
            else
                print("[Lemon] No images from Pexels, using defaults")
                Lemon.ProfileImages = Lemon.DefaultProfileImages
            end
        else
            warn("[Lemon] Failed to fetch profile images: " .. tostring(response))
            Lemon.ProfileImages = Lemon.DefaultProfileImages
        end
        
        Lemon:StartChatPolling()
    end)
end

function Lemon:StartChatPolling()
    task.spawn(function()
        while true do
            if Lemon.ChatEnabled and Lemon.ChatFrame and Lemon.ChatFrame.Visible then
                pcall(function()
                    local response = game:HttpGet(FASTAPI_URL .. "/chat/messages?limit=10")
                    local data = HttpService:JSONDecode(response)
                    
                    if data and data.messages then
                        for _, msg in ipairs(data.messages) do
                            Lemon:DisplayChatMessage(msg)
                        end
                    end
                end)
            end
            task.wait(2)
        end
    end)
end

-- window
function Lemon:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "Lemon", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or "",
        Size = properties.Size or properties.size or dim2(0, 720, 0, 500), 
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
    
    -- Glow
    Items.Glow = Lemon:Create("ImageLabel", {
        ImageColor3 = themes.preset.glow,
        ScaleType = Enum.ScaleType.Slice,
        ImageTransparency = 0.6499999761581421,
        BorderColor3 = rgb(0, 0, 0),
        Parent = Items.Wrapper,
        Name = "\0",
        Size = dim2(1, 40, 1, 40),
        Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1,
        Position = dim2(0, -20, 0, -20),
        BackgroundColor3 = rgb(255, 255, 255),
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
    Lemon:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 2 })

    -- Top Right: Roblox profile image, username and status
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    
    Items.TopRightFrame = Lemon:Create("Frame", {
        Parent = Items.Header,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -12, 0.5, 0),
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
    Lemon:Create("UICorner", { Parent = Items.AvatarFrameTop, CornerRadius = dim(0, 8) })
    
    Items.AvatarTop = Lemon:Create("ImageLabel", {
        Parent = Items.AvatarFrameTop,
        AnchorPoint = vec2(0.5, 0.5),
        Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = headshot,
        ZIndex = 6
    })
    Lemon:Create("UICorner", { Parent = Items.AvatarTop, CornerRadius = dim(0, 8) })
    
    Items.UsernameTop = Lemon:Create("TextLabel", {
        Parent = Items.TopRightFrame,
        Text = Cfg.StreamerMode and "User" or lp.Name,
        TextColor3 = themes.preset.text,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -36, 0, 2),
        Size = dim2(0, 80, 0, 14),
        BackgroundTransparency = 1,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5
    })
    Lemon:Themify(Items.UsernameTop, "text", "TextColor3")
    
    Items.StatusTop = Lemon:Create("TextLabel", {
        Parent = Items.TopRightFrame,
        Text = Cfg.StreamerMode and "Premium" or "Status : Premium",
        TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -36, 0, 18),
        Size = dim2(0, 80, 0, 12),
        BackgroundTransparency = 1,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5
    })
    Lemon:Themify(Items.StatusTop, "subtext", "TextColor3")

    Items.LogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 12, 0, 12),
        Size = dim2(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 12, 0, 26),
        Size = dim2(0, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.SubLogoText, "subtext", "TextColor3")

    Items.PageHolder = Lemon:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 50), Size = dim2(1, 0, 1, -50), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Tabs OUTSIDE the UI at bottom middle - MORE ROUNDED with tiny room at edges
    Items.TabHolder = Lemon:Create("Frame", { 
        Parent = Items.Wrapper, 
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 1, 6), -- Tiny room from edge
        Size = dim2(0, 0, 0, 42), -- Slightly bigger
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = themes.preset.section, 
        BorderSizePixel = 0, 
        ZIndex = 100
    })
    Lemon:Themify(Items.TabHolder, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.TabHolder, CornerRadius = dim(0, 14) }) -- More round
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.TabHolder, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Lemon:Create("UIListLayout", { 
        Parent = Items.TabHolder, 
        FillDirection = Enum.FillDirection.Horizontal, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, 
        VerticalAlignment = Enum.VerticalAlignment.Center, 
        Padding = dim(0, 8) 
    })
    
    -- Add tiny padding to tab holder
    Lemon:Create("UIPadding", { 
        Parent = Items.TabHolder, 
        PaddingLeft = dim(0, 4), -- Tiny room
        PaddingRight = dim(0, 4) -- Tiny room
    })

    Items.Footer = Lemon:Create("Frame", { 
        Parent = Items.Window, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), 
        Size = dim2(1, 0, 0, 45), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 
    })

    -- Settings button - changed to TextButton with emoji
    Items.SettingsBtn = Lemon:Create("TextButton", {
        Parent = Items.Footer, 
        AnchorPoint = vec2(1, 0.5), 
        Position = dim2(1, -12, 0.5, 0),
        Size = dim2(0, 24, 0, 24), 
        BackgroundTransparency = 1, 
        Text = "⚙️",
        TextSize = 18,
        TextColor3 = themes.preset.subtext, 
        ZIndex = 5
    })
    Lemon:Themify(Items.SettingsBtn, "subtext", "TextColor3")
    
    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    -- Dragging Logic
    local Dragging, DragInput, DragStart, StartPos
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
        -- Also toggle chat visibility with UI
        if Lemon.ChatFrame and Lemon.ChatEnabled then
            Lemon.ChatFrame.Visible = uiVisible
        end
    end

    if InputService.TouchEnabled then
        Lemon.ToggleGui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonToggle", IgnoreGuiInset = true })
        local ToggleButton = Lemon:Create("ImageButton", {
            Name = "ToggleButton", Parent = Lemon.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 55, 0, 55),
            BackgroundTransparency = 0.2, BackgroundColor3 = themes.preset.element, Image = "rbxassetid://86658474847671", ZIndex = 10000,
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

    -- Initialize chat system
    Lemon:InitializeChat()

    return setmetatable(Cfg, Lemon)
end

-- tabs
function Lemon:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610", 
        Hidden = properties.Hidden or properties.hidden or false, 
        Items = {} 
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        -- Keep tab buttons same size
        Items.Button = Lemon:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 30, 0, 30), 
            BackgroundColor3 = themes.preset.tab_active,
            BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, ZIndex = 101 
        })
        Lemon:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) }) -- More round
        
        Items.IconImg = Lemon:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 102 
        })
        Lemon:Themify(Items.IconImg, "subtext", "ImageColor3")
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
            Lemon:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
        end

        if Items.Button then 
            Lemon:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            Lemon:Tween(Items.IconImg, {ImageColor3 = rgb(15, 15, 15)}, buttonTween) 
        end
        
        task.spawn(function()
            if oldTab then
                Lemon:Tween(oldTab.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 10)}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Lemon.Other
            end

            Items.Pages.Position = dim2(0, 0, 0, 10) 
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Lemon:Tween(Items.Pages, {GroupTransparency = 0, Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.wait(0.35)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Lemon)
end

-- sections
function Lemon:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610",
        RightIcon = properties.RightIcon or properties.righticon or "rbxassetid://11293977610",
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Lemon:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Lemon:Themify(Items.Section, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 8) }) -- More round

    -- YELLOW LINE ACCENT ON LEFT SIDE
    Items.AccentLine = Lemon:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 2, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })
    Lemon:Themify(Items.AccentLine, "accent", "BackgroundColor3")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    
    Items.Icon = Lemon:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(0, 16, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 14, 0, 14),
        BackgroundTransparency = 1, Image = Cfg.Icon, ImageColor3 = themes.preset.subtext
    })
    Lemon:Themify(Items.Icon, "subtext", "ImageColor3")

    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 38, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -70, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "text", "TextColor3")

    Items.Chevron = Lemon:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(1, -14, 0.5, 0), AnchorPoint = vec2(1, 0.5), Size = dim2(0, 12, 0, 12),
        BackgroundTransparency = 1, Image = Cfg.RightIcon, ImageColor3 = themes.preset.subtext, 
        Rotation = (Cfg.RightIcon == "rbxassetid://11293977610") and 180 or 0
    })
    Lemon:Themify(Items.Chevron, "subtext", "ImageColor3")

    Items.Container = Lemon:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 36), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 12), PaddingLeft = dim(0, 14), PaddingRight = dim(0, 14) })

    return setmetatable(Cfg, Lemon)
end

-- Toggle element
function Lemon:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 22), BackgroundTransparency = 1, Text = "" })
    
    Items.Checkbox = Lemon:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 6, 0.5, 0), Size = dim2(0, 14, 0, 14), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Lemon:Themify(Items.Checkbox, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Checkbox, CornerRadius = dim(0, 4) }) -- More round

    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 30, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -26, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
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

-- Button element
function Lemon:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 30), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Lemon:Themify(Items.Button, "element", "BackgroundColor3")
    Lemon:Themify(Items.Button, "subtext", "TextColor3")
    Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) }) -- More round

    Items.Button.MouseButton1Click:Connect(function()
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.outline, TextColor3 = themes.preset.text}, TweenInfo.new(0.1))
        task.wait(0.1)
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Lemon)
end

-- Slider element
function Lemon:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or properties.Value or properties.value or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 38), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Val = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right })
    Lemon:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Lemon:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 4, 0, 24), Size = dim2(1, -8, 0, 6), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Lemon:Themify(Items.Track, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })

    Items.Fill = Lemon:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.text })
    Lemon:Themify(Items.Fill, "text", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    Items.Knob = Lemon:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 12, 0, 12), BackgroundColor3 = themes.preset.text })
    Lemon:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    Lemon:Themify(Items.Knob, "text", "BackgroundColor3")

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true; Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) end
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

-- Textbox element
function Lemon:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 32), BackgroundTransparency = 1 })
    Items.Bg = Lemon:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Lemon:Themify(Items.Bg, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 6) }) -- More round

    Items.Input = Lemon:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
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

-- Label element
function Lemon:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 26 or 18), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Cfg.Wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center 
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Lemon)
end

-- Dropdown with search bar - UNDER the button
function Lemon:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or properties.items or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 46), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 16), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Main = Lemon:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 20), Size = dim2(1, 0, 0, 26), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Lemon:Themify(Items.Main, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 6) }) -- More round

    Items.SelectedText = Lemon:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.SelectedText, "subtext", "TextColor3")
    
    Items.Icon = Lemon:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 10, 0, 10), BackgroundTransparency = 1, Image = "rbxassetid://11293977610", ImageColor3 = themes.preset.subtext, Rotation = 180 })

    -- Dropdown frame UNDER the button
    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Lemon.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) }) -- More round

    -- Search bar
    Items.SearchBox = Lemon:Create("TextBox", {
        Parent = Items.DropFrame,
        Position = dim2(0, 4, 0, 4),
        Size = dim2(1, -8, 0, 22),
        BackgroundColor3 = themes.preset.section,
        Text = "",
        PlaceholderText = "Search...",
        TextColor3 = themes.preset.text,
        PlaceholderColor3 = themes.preset.subtext,
        Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 201
    })
    Lemon:Create("UICorner", { Parent = Items.SearchBox, CornerRadius = dim(0, 5) })
    Lemon:Themify(Items.SearchBox, "section", "BackgroundColor3")
    Lemon:Themify(Items.SearchBox, "text", "TextColor3")

    Items.Scroll = Lemon:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -36), Position = dim2(0, 0, 0, 30), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, ZIndex = 201 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false

    function Cfg.UpdatePosition()
        local absPos = Items.Main.AbsolutePosition
        local absSize = Items.Main.AbsoluteSize
        Items.DropFrame.Position = dim2(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
    end

    local function ToggleDropdown()
        if isTweening then return end
        Open = not Open
        isTweening = true

        if Open then
            Items.DropFrame.Visible = true
            Cfg.UpdatePosition()
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            local targetHeight = math.clamp(#Cfg.Options * 24 + 40, 0, 160)
            Lemon:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.3))
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            Lemon:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.3))
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    -- Click off to close
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
        
        local searchText = Items.SearchBox.Text:lower()
        for _, opt in ipairs(Cfg.Options) do
            if searchText == "" or tostring(opt):lower():find(searchText) then
                local btn = Lemon:Create("TextButton", { 
                    Parent = Items.Scroll, Size = dim2(1, 0, 0, 24), BackgroundTransparency = 1, 
                    Text = "   " .. tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 13, 
                    FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
                })
                Lemon:Themify(btn, "subtext", "TextColor3")
                btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
                table.insert(OptionBtns, btn)
            end
        end
    end

    -- Search functionality
    Items.SearchBox.Changed:Connect(function(property)
        if property == "Text" then
            Cfg.RefreshOptions()
        end
    end)

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    RunService.RenderStepped:Connect(function() 
        if Open or isTweening then 
            Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 2)
        end 
    end)
    return setmetatable(Cfg, Lemon)
end

-- Colorpicker with toggle button behavior
function Lemon:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local btn = Lemon:Create("TextButton", { 
        Parent = self.Items.Title or self.Items.Button or self.Items.Container, 
        AnchorPoint = vec2(1, 0.5), 
        Position = dim2(1, -6, 0.5, 0), 
        Size = dim2(0, 30, 0, 14), 
        BackgroundColor3 = Cfg.Color, 
        Text = "" 
    })
    Lemon:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 6)})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    -- Dropdown color picker under the button
    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Lemon.Gui, 
        Size = dim2(0, 150, 0, 0), 
        BackgroundColor3 = themes.preset.element, 
        Visible = false, 
        ZIndex = 200, 
        ClipsDescendants = true 
    })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })

    Items.SVMap = Lemon:Create("TextButton", { 
        Parent = Items.DropFrame, 
        Position = dim2(0, 8, 0, 8), 
        Size = dim2(1, -16, 1, -38), 
        AutoButtonColor = false, 
        Text = "", 
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), 
        ZIndex = 201 
    })
    Lemon:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 5) })
    
    Items.SVImage = Lemon:Create("ImageLabel", { 
        Parent = Items.SVMap, 
        Size = dim2(1, 0, 1, 0), 
        Image = "rbxassetid://4155801252", 
        BackgroundTransparency = 1, 
        BorderSizePixel = 0, 
        ZIndex = 202 
    })
    Lemon:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 5) })
    
    Items.SVKnob = Lemon:Create("Frame", { 
        Parent = Items.SVMap, 
        AnchorPoint = vec2(0.5, 0.5), 
        Size = dim2(0, 4, 0, 4), 
        BackgroundColor3 = rgb(255,255,255), 
        ZIndex = 203 
    })
    Lemon:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    Lemon:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0) })

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
    Lemon:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 5) })
    Lemon:Create("UIGradient", { 
        Parent = Items.HueBar, 
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255,0,0)), 
            ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), 
            ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), 
            ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), 
            ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), 
            ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), 
            ColorSequenceKeypoint.new(1, rgb(255,0,0))
        }) 
    })
    
    Items.HueKnob = Lemon:Create("Frame", { 
        Parent = Items.HueBar, 
        AnchorPoint = vec2(0.5, 0.5), 
        Size = dim2(0, 2, 1, 4), 
        BackgroundColor3 = rgb(255,255,255), 
        ZIndex = 203 
    })
    Lemon:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })

    local Open = false
    local isTweening = false

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
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

    local svDragging, hueDragging = false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if Open or isTweening then 
            Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X + btn.AbsoluteSize.X - 150, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 2) 
        end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Keybind with toggle button behavior
function Lemon:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
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
    Lemon:Create("UICorner", {Parent = KeyBtnContainer, CornerRadius = dim(0, 6)})
    
    local KeyBtn = Lemon:Create("TextLabel", {
        Parent = KeyBtnContainer,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = themes.preset.subtext, 
        Text = Keys[Cfg.Default] or "None", 
        TextSize = 12, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Center
    })
    Lemon:Themify(KeyBtn, "subtext", "TextColor3")
    
    local binding = false
    local isOpen = false
    
    local function ToggleBinding()
        isOpen = not isOpen
        binding = isOpen
        
        if isOpen then
            KeyBtn.Text = "..."
            KeyBtnContainer.BackgroundColor3 = themes.preset.accent
        else
            binding = false
            KeyBtnContainer.BackgroundColor3 = themes.preset.element
        end
    end
    
    KeyBtnContainer.MouseButton1Click:Connect(function()
        if not isOpen then
            ToggleBinding()
        end
    end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                ToggleBinding()
                Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                ToggleBinding()
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

-- Configs and Server Menu
function Lemon:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "", Hidden = true })
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
    SectionRight:Label({Name = "Glow Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("glow", color3) end, Color = themes.preset.glow })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("text", color3) end, Color = themes.preset.text })

    -- Settings with Streamer Mode and Live Chat toggle
    local SettingsSection = Tab:Section({Name = "Settings", Side = "Right"})
    
    SettingsSection:Toggle({
        Name = "Streamer Mode",
        Default = false,
        Callback = function(state)
            window.StreamerMode = state
            if state then
                window.Items.UsernameTop.Text = "User"
                window.Items.StatusTop.Text = "Premium"
            else
                window.Items.UsernameTop.Text = lp.Name
                window.Items.StatusTop.Text = "Status : Premium"
            end
        end,
        Flag = "streamer_mode"
    })
    
    SettingsSection:Toggle({
        Name = "Live Chat",
        Default = false,
        Callback = function(state)
            Lemon.ChatEnabled = state
            if Lemon.ChatFrame then
                if state then
                    Lemon.ChatFrame.Visible = true
                    Lemon:JoinChatMessage(lp.Name)
                else
                    Lemon.ChatFrame.Visible = false
                    Lemon:LeaveChatMessage(lp.Name)
                end
            end
        end,
        Flag = "live_chat"
    })

    window.Tweening = true
    SettingsSection:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })
end

-- Save/Load functions
function Lemon:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

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
        Name = properties.Name or properties.name or "Notification"; 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = Lemon:Create("Frame", { Parent = Lemon.Gui; Position = dim_offset(-500, 50); Size = dim2(0, 300, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.background; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true })
    Lemon:Themify(Items.Outline, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 6) })
   
    Items.Name = Lemon:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Lemon:Themify(Items.Name, "text", "TextColor3")
   
    Lemon:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 10); PaddingBottom = dim(0, 10); PaddingRight = dim(0, 12); PaddingLeft = dim(0, 12); })
   
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
