local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Teams = cloneref(game:GetService("Teams"))
local TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    }
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?)
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    MobileButtonFrame = nil,
    MobileButtonContainer = nil,
    MobileButtons = {},

    Notifications = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,
    Watermark = false,
    CurrentWindowTitle = "",
    WatermarkFields = {
        Name = true,
        FPS = true,
        Ping = true,
        Executor = false,
    },

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,
    ScrollingDropdown = false,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        AccentGradientStart = Color3.fromRGB(155, 122, 255),
        AccentGradientEnd = Color3.fromRGB(90, 50, 204),

        Red = Color3.fromRGB(255, 50, 50),
        Dark = Color3.new(0, 0, 0),
        White = Color3.new(1, 1, 1),
    },

    Registry = {},
    DPIRegistry = {},
    _ManagedUICorners = {},
    
    ImageManager = CustomImageManager,
}

    -- Watch for changes to ScrollingDropdown and disable scrolling for existing dropdowns when toggled
    do
        local raw_newindex = rawset
        local orig_mt = getmetatable(Library) or {}
        orig_mt.__newindex = function(t, k, v)
            raw_newindex(t, k, v)
            if k == "ScrollingDropdown" then
                -- iterate existing options and clean up any scrolling UI
                for _, opt in pairs(Options) do
                    if type(opt) == "table" and opt.Type == "Dropdown" then
                        -- disconnect active scroll connection
                        if opt._ScrollConnection then
                            pcall(function()
                                if opt._ScrollConnection.Connected then
                                    opt._ScrollConnection:Disconnect()
                                end
                            end)
                            opt._ScrollConnection = nil
                        end

                        -- destroy any scrolling labels or masks under the holder/display
                        if opt.Holder and opt.Holder.Parent then
                            pcall(function()
                                for _, d in pairs(opt.Holder:GetDescendants()) do
                                    if d and d.Name == "ScrollingText" then
                                        d:Destroy()
                                    elseif d and d.Name == "ScrollMask" then
                                        d:Destroy()
                                    end
                                end
                            end)
                        end

                        -- refresh display to show non-scrolling text
                        pcall(function()
                            if opt and type(opt) == "table" and type(opt.Display) ~= "nil" then
                                if type(opt.Display) == "table" or type(opt.Display) == "userdata" or type(opt.Display) == "Instance" then
                                    -- call the dropdown's Display method safely
                                    pcall(function() opt:Display() end)
                                else
                                    pcall(function() if opt.Display then opt.Display = opt.Display end end)
                                end
                            end
                        end)
                    end
                end
            end
        end
        setmetatable(Library, orig_mt)
    end

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer", -- Can be a string or array of strings for cycling
        FooterCycleInterval = 3, -- Seconds between footer changes (when Footer is an array)
        FooterFadeDuration = 0.5, -- Duration of fade transition (when Footer is an array)
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = true,
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        Compact = false,
        EnableSidebarResize = false,
        SidebarMinWidth = 180,
        SidebarCompactWidth = 54,
        SidebarCollapseThreshold = 0.5,
        SidebarHighlightCallback = nil,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        DefaultModifiers = {},
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold", "Click" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Basic Functions \\--
local function ApplyDPIScale(Dimension, ExtraOffset)
    if typeof(Dimension) == "UDim" then
        return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
    end

    if ExtraOffset then
        return UDim2.new(
            Dimension.X.Scale,
            (Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
            Dimension.Y.Scale,
            (Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
        )
    end

    return UDim2.new(
        Dimension.X.Scale,
        Dimension.X.Offset * Library.DPIScale,
        Dimension.Y.Scale,
        Dimension.Y.Offset * Library.DPIScale
    )
end
local function ApplyTextScale(TextSize)
    return TextSize * Library.DPIScale
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end
local function GetLighterColor(Color)
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetAccentGradientSequence()
    local g = self.Scheme and self.Scheme.AccentGradient
    local defaultColor = (self.Scheme and self.Scheme.AccentColor) or Color3.fromRGB(255, 255, 255)

    print("[GRADIENT DEBUG GetAccentGradientSequence] Called, g type:", type(g))
    
    -- If explicit multi-stop gradient is present: normalize, clamp, ensure endpoints
    if type(g) == "table" and type(g.Stops) == "table" and #g.Stops > 0 then
        print("[GRADIENT DEBUG GetAccentGradientSequence] Processing", #g.Stops, "stops")
        local stops = {}
        for i, s in ipairs(g.Stops) do
            local pos = math.clamp(tonumber(s and s.pos) or 0, 0, 1)
            local col = s and s.color
            print("[GRADIENT DEBUG GetAccentGradientSequence] Stop", i, "pos:", pos, "color type:", typeof(col))
            if typeof(col) == "string" and col:match("^#?%x%x%x%x%x%x$") then
                local ok, c = pcall(Color3.fromHex, col:gsub("#", ""))
                col = (ok and typeof(c) == "Color3") and c or defaultColor
            elseif typeof(col) ~= "Color3" then
                col = defaultColor
                print("[GRADIENT DEBUG GetAccentGradientSequence] Using defaultColor for stop", i)
            end
            table.insert(stops, { pos = pos, color = col })
        end

        -- Safety check: if no stops after processing, fall back to default
        if #stops == 0 then
            print("[GRADIENT DEBUG GetAccentGradientSequence] No stops after processing, using default")
            local c = defaultColor
            return ColorSequence.new({ ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, c) })
        end

        table.sort(stops, function(a, b) return a.pos < b.pos end)

        -- Ensure endpoint at 0.0
        if #stops > 0 and stops[1].pos > 0 then
            table.insert(stops, 1, { pos = 0, color = stops[1].color })
        end
        -- Ensure endpoint at 1.0
        if #stops > 0 and stops[#stops].pos < 1 then
            table.insert(stops, { pos = 1, color = stops[#stops].color })
        end

        local keypoints = {}
        for _, s in ipairs(stops) do
            table.insert(keypoints, ColorSequenceKeypoint.new(s.pos, s.color))
        end

        -- Guarantee at least two keypoints
        if #keypoints == 0 then
            print("[GRADIENT DEBUG GetAccentGradientSequence] No keypoints, using default")
            local c = defaultColor
            return ColorSequence.new({ ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, c) })
        elseif #keypoints == 1 then
            table.insert(keypoints, ColorSequenceKeypoint.new(1, keypoints[1].Value))
        end

        print("[GRADIENT DEBUG GetAccentGradientSequence] Returning ColorSequence with", #keypoints, "keypoints")
        return ColorSequence.new(keypoints)
    end

    -- No multi-stop gradient defined: return a solid ColorSequence using AccentColor
    print("[GRADIENT DEBUG GetAccentGradientSequence] No gradient defined, using solid color")
    local c = defaultColor
    return ColorSequence.new({ ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, c) })
end

function Library:GetAccentGradientTransparencySequence()
    local g = self.Scheme and self.Scheme.AccentGradient

    if type(g) == "table" and type(g.Stops) == "table" and #g.Stops > 0 then
        local stops = {}
        for _, s in ipairs(g.Stops) do
            local pos = math.clamp(tonumber(s and s.pos) or 0, 0, 1)
            local transp = math.clamp(tonumber(s and s.transparency) or 0, 0, 1)
            table.insert(stops, { pos = pos, transp = transp })
        end

        -- Safety check: if no stops after processing, fall back to default
        if #stops == 0 then
            return NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0) })
        end

        table.sort(stops, function(a, b) return a.pos < b.pos end)

        if #stops > 0 and stops[1].pos > 0 then
            table.insert(stops, 1, { pos = 0, transp = stops[1].transp })
        end
        if #stops > 0 and stops[#stops].pos < 1 then
            table.insert(stops, { pos = 1, transp = stops[#stops].transp })
        end

        local keypoints = {}
        for _, s in ipairs(stops) do
            table.insert(keypoints, NumberSequenceKeypoint.new(s.pos, s.transp))
        end

        if #keypoints == 0 then
            return NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0) })
        elseif #keypoints == 1 then
            table.insert(keypoints, NumberSequenceKeypoint.new(1, keypoints[1].Value))
        end
        return NumberSequence.new(keypoints)
    end

    -- Default: fully opaque (no transparency) at both ends
    return NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0) })
end

function Library:GetAccentSolidSequence()
    local c = self.Scheme.AccentColor
    if typeof(c) ~= "Color3" then
        if typeof(c) == "string" and c ~= "" then
            local ok, cc = pcall(function() return Color3.fromHex(c) end)
            if ok and typeof(cc) == "Color3" then
                c = cc
            else
                c = Color3.fromRGB(255, 255, 255)
            end
        else
            c = Color3.fromRGB(255, 255, 255)
        end
    end

    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, c),
        ColorSequenceKeypoint.new(1, c),
    })
end

function Library:UpdateKeybindFrame()
    if not Library.KeybindFrame then
        return
    end

    local XSize = 0
    for _, KeybindToggle in pairs(Library.KeybindToggles) do
        if not KeybindToggle.Holder.Visible then
            continue
        end

        local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
        if FullSize > XSize then
            XSize = FullSize
        end
    end

    -- Set displayed size (scaled) and register the unscaled size for DPI updates
    Library.KeybindFrame.Size = UDim2.fromOffset(math.ceil((XSize + 18) * Library.DPIScale), 0)
    Library:UpdateDPI(Library.KeybindFrame, { Size = UDim2.fromOffset(XSize + 18, 0) })
end

function Library:CreateMobileButton(Toggle)
    if not Library.IsMobile or not Toggle then
        return
    end

    if not Library.MobileButtonFrame then
        Library.MobileButtonFrame, Library.MobileButtonContainer = Library:AddDraggableMenu("Mobile Toggles")
        Library.MobileButtonFrame.AnchorPoint = Vector2.new(1, 0.5)
        Library.MobileButtonFrame.Position = UDim2.new(1, -6, 0.5, 0)
        Library.MobileButtonFrame.Visible = true
    end

    local Button = New("TextButton", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(1, 0, 0, 32),
        Text = "",
        Parent = Library.MobileButtonContainer,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Button,
    })
    Library:AddOutline(Button)

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -44, 1, 0),
        Text = Toggle.Text or "Toggle",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Button,
    })

    local Indicator = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Position = UDim2.new(1, -28, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Parent = Button,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Indicator,
    })

    Button.MouseButton1Click:Connect(function()
        Toggle:SetValue(not Toggle.Value)
    end)

    local MobileBtn = {
        Button = Button,
        Label = Label,
        Indicator = Indicator,
        Toggle = Toggle,
    }

    function MobileBtn:Update()
        Indicator.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
        Library.Registry[Indicator].BackgroundColor3 = Toggle.Value and "AccentColor" or "OutlineColor"
    end

    function MobileBtn:Remove()
        Button:Destroy()
        Library.MobileButtons[Toggle] = nil
    end

    MobileBtn:Update()
    Library.MobileButtons[Toggle] = MobileBtn
    return MobileBtn
end
function Library:UpdateDependencyBoxes()
    for _, Depbox in pairs(Library.DependencyBoxes) do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in pairs(Box.Elements) do
        if ElementInfo.Type == "Divider" then
            if ElementInfo.Holder then
                ElementInfo.Holder.Visible = false
            end
            continue
        elseif ElementInfo.SubButton then
            local Visible = false

            if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                Visible = true
            else
                if ElementInfo.Base then
                    ElementInfo.Base.Visible = false
                end
            end

            if ElementInfo.SubButton.Text and ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                if ElementInfo.SubButton.Base then
                    ElementInfo.SubButton.Base.Visible = false
                end
            end

            if ElementInfo.Holder then
                ElementInfo.Holder.Visible = Visible
            end

            if Visible then
                VisibleElements = VisibleElements + 1
            end

            continue
        end

        if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
            if ElementInfo.Holder then
                ElementInfo.Holder.Visible = true
            end
            VisibleElements = VisibleElements + 1
        else
            if ElementInfo.Holder then
                ElementInfo.Holder.Visible = false
            end
        end
    end

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox or not Depbox.Visible then
            continue
        end

        VisibleElements = VisibleElements + CheckDepbox(Depbox, Search)
    end

    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in pairs(Box.Elements) do
        if ElementInfo.Holder then
            ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true
        end

        if ElementInfo.SubButton then
            if ElementInfo.Base then
                ElementInfo.Base.Visible = ElementInfo.Visible
            end
            if ElementInfo.SubButton.Base then
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end
    end

    Box:Resize()
    if Box.Holder then
        Box.Holder.Visible = true
    end

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox or not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in pairs(Library.Tabs) do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    local function ResetTab(Tab)
        if not Tab then
            return
        end

        for _, Groupbox in pairs(Tab.Groupboxes) do
            for _, ElementInfo in pairs(Groupbox.Elements) do
                ElementInfo.Holder.Visible = typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    if ElementInfo.SubButton.Base then
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            Groupbox:Resize()
            Groupbox.Holder.Visible = true
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                for _, ElementInfo in pairs(SubTab.Elements) do
                    ElementInfo.Holder.Visible =
                        typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        if ElementInfo.SubButton.Base then
                            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                        end
                    end
                end

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                SubTab.ButtonHolder.Visible = true
            end

            if Tabbox.ActiveTab then
                Tabbox.ActiveTab:Resize()
            end
            Tabbox.Holder.Visible = true
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                ElementInfo.Holder.Visible =
                    typeof(ElementInfo.Visible) == "boolean" and ElementInfo.Visible or true

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    if ElementInfo.SubButton.Base then
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            DepGroupbox:Resize()
            DepGroupbox.Holder.Visible = true
        end
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in pairs(Library.Tabs) do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local function ApplySearchToTab(Tab)
        if not Tab then
            return
        end

        local HasVisible = false

        --// Loop through Groupboxes to get Elements Info
        for _, Groupbox in pairs(Tab.Groupboxes) do
            local VisibleElements = 0

            for _, ElementInfo in pairs(Groupbox.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            --// Update Groupbox Size and Visibility if found any element
            if VisibleElements > 0 then
                Groupbox:Resize()
                HasVisible = true
            end
            Groupbox.Holder.Visible = VisibleElements > 0
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            local VisibleTabs = 0
            local VisibleElements = {}

            for _, SubTab in pairs(Tabbox.Tabs) do
                VisibleElements[SubTab] = 0

                for _, ElementInfo in pairs(SubTab.Elements) do
                    if ElementInfo.Type == "Divider" then
                        ElementInfo.Holder.Visible = false
                        continue
                    elseif ElementInfo.SubButton then
                        --// Check if any of the Buttons Name matches with Search
                        local Visible = false

                        --// Check if Search matches Element's Name and if Element is Visible
                        if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                            Visible = true
                        else
                            ElementInfo.Base.Visible = false
                        end
                        if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                            Visible = true
                        else
                            ElementInfo.SubButton.Base.Visible = false
                        end
                        ElementInfo.Holder.Visible = Visible
                        if Visible then
                            VisibleElements[SubTab] += 1
                        end

                        continue
                    end

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        ElementInfo.Holder.Visible = true
                        VisibleElements[SubTab] += 1
                    else
                        ElementInfo.Holder.Visible = false
                    end
                end

                for _, Depbox in pairs(SubTab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
                end
            end

            for SubTab, Visible in pairs(VisibleElements) do
                SubTab.ButtonHolder.Visible = Visible > 0
                if Visible > 0 then
                    VisibleTabs += 1
                    HasVisible = true

                    if Tabbox.ActiveTab == SubTab then
                        SubTab:Resize()
                    elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                        SubTab:Show()
                    end
                end
            end

            --// Update Tabbox Visibility if any visible
            Tabbox.Holder.Visible = VisibleTabs > 0
        end

        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            local VisibleElements = 0

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():match(Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and ElementInfo.Text:lower():match(Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements += CheckDepbox(Depbox, Search)
            end

            --// Update Groupbox Size and Visibility if found any element
            if VisibleElements > 0 then
                DepGroupbox:Resize()
                HasVisible = true
            end
            DepGroupbox.Holder.Visible = VisibleElements > 0
        end

        return HasVisible
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in pairs(Library.Registry) do
        -- Check if instance still exists (not destroyed)
        local instanceValid = pcall(function() return Instance.Parent end)
        if not instanceValid then
            continue
        end
        
        for Property, ColorIdx in pairs(Properties) do
            local val = nil
            if typeof(ColorIdx) == "string" then
                val = Library.Scheme[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                local success, result = pcall(ColorIdx)
                if success then
                    val = result
                end
            end

            if Property == "FontFace" and val ~= nil then
                if typeof(val) == "string" then
                    local ok, enumVal = pcall(function() return Enum.Font[val] end)
                    if ok and enumVal then
                        val = Font.fromEnum(enumVal)
                    end
                elseif typeof(val) == "EnumItem" then
                    val = Font.fromEnum(val)
                end
            end

            if val ~= nil then
                pcall(function()
                    Instance[Property] = val
                end)
            end
        end
    end
    
    -- Ensure groupbox backgrounds remain visible after color updates
    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end
        
        for _, Groupbox in pairs(Tab.Groupboxes) do
            pcall(function()
                if Groupbox.Holder and Groupbox.Holder.BackgroundTransparency ~= 0 then
                    Groupbox.Holder.BackgroundTransparency = 0
                end
                if Groupbox.Holder and Groupbox.Holder.Size then
                    local ok, yOff = pcall(function() return Groupbox.Holder.Size.Y.Offset end)
                    local minSize = math.ceil(34 * Library.DPIScale)
                    if ok and tonumber(yOff) and yOff < minSize then
                        Groupbox.Holder.Size = UDim2.new(1, 0, 0, minSize)
                    end
                end
            end)
        end
        
        for _, DepGroupbox in pairs(Tab.DependencyGroupboxes or {}) do
            pcall(function()
                if DepGroupbox.Holder and DepGroupbox.Holder.BackgroundTransparency ~= 0 then
                    DepGroupbox.Holder.BackgroundTransparency = 0
                end
            end)
        end
    end

    -- Recompute sizes for groupboxes and dependent containers that are computed from content
    -- This ensures groupboxes update correctly when DPIScale changes even if they were
    -- using AutomaticSize or excluded from DPIRegistry.
    task.defer(function()
        for _, Tab in pairs(Library.Tabs) do
            if Tab.IsKeyTab then
                continue
            end

            for _, Groupbox in pairs(Tab.Groupboxes) do
                pcall(function()
                    if Groupbox and Groupbox.Container and Groupbox.Holder then
                        local list = Groupbox.Container:FindFirstChildOfClass("UIListLayout")
                        if list then
                            local contentH = list.AbsoluteContentSize.Y or 0
                            Groupbox.Holder.Size = UDim2.new(1, 0, 0, math.ceil((contentH + 53) * Library.DPIScale))
                        end
                        if Groupbox.Holder.BackgroundTransparency ~= 0 then
                            Groupbox.Holder.BackgroundTransparency = 0
                        end
                    end
                end)
            end
        end
    end)
    
    -- Ensure dependency boxes remain visible
    for _, Dep in pairs(Library.DependencyBoxes or {}) do
        pcall(function()
            if Dep.Holder and Dep.Holder.BackgroundTransparency ~= 0 then
                Dep.Holder.BackgroundTransparency = 0
            end
            if Dep.Container and Dep.Container.BackgroundTransparency ~= 0 then
                Dep.Container.BackgroundTransparency = 0
            end
        end)
    end
end

function Library:UpdateDPI(Instance, Properties)
    if not Library.DPIRegistry[Instance] then
        return
    end

    for Property, Value in pairs(Properties) do
        Library.DPIRegistry[Instance][Property] = Value and Value or nil
    end
end

function Library:SetDPIScale(DPIScale: number)
    -- Accept either a percent (e.g. 100) or a ratio (e.g. 1.0).
    local normalized = DPIScale
    if typeof(normalized) ~= "number" then
        normalized = 1
    end
    if normalized > 2 then
        normalized = normalized / 100
    end
    -- clamp to reasonable bounds to avoid near-zero or huge scales
    normalized = math.clamp(normalized, 0.25, 4)

    Library.DPIScale = normalized
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

    for Instance, Properties in pairs(Library.DPIRegistry) do
        local DPIExclude = Properties["DPIExclude"] or {}
        local DPIOffset = Properties["DPIOffset"] or {}
        for Property, Value in pairs(Properties) do
            if Property == "DPIExclude" or Property == "DPIOffset" then
                continue
            elseif DPIExclude[Property] then
                continue
            elseif Property == "TextSize" then
                Instance[Property] = ApplyTextScale(Value)
            elseif Property == "ScrollBarThickness" then
                -- Handle ScrollBarThickness with DPI scaling
                if typeof(Value) == "UDim" then
                    Instance[Property] = math.ceil(Value.Offset * Library.DPIScale)
                elseif typeof(Value) == "number" then
                    Instance[Property] = math.ceil(Value * Library.DPIScale)
                end
            else
                Instance[Property] = ApplyDPIScale(Value, DPIOffset[Property])
            end
        end
    end

    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        Tab:Resize(true)

        for _, Groupbox in pairs(Tab.Groupboxes) do
            Groupbox:Resize()
        end

        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                SubTab:Resize()
            end
        end
    end

    -- Ensure groupbox container visibility matches expanded state after DPI change
    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        for _, Groupbox in pairs(Tab.Groupboxes) do
            pcall(function()
                if Groupbox.Container then
                    Groupbox.Container.Visible = true
                end
                -- Ensure holder background transparency remains visible after DPI change
                if Groupbox.Holder and Groupbox.Holder.BackgroundTransparency ~= 0 then
                    Groupbox.Holder.BackgroundTransparency = 0
                end
            end)
        end
    end

    -- Also ensure any dependency boxes/groupboxes restored
    for _, Dep in pairs(Library.DependencyBoxes) do
        pcall(function()
            if Dep and Dep.Holder and Dep.Holder.BackgroundTransparency ~= 0 then
                Dep.Holder.BackgroundTransparency = 0
            end
            if Dep and Dep.Container and Dep.Container.BackgroundTransparency ~= 0 then
                Dep.Container.BackgroundTransparency = 0
            end
        end)
    end

    for _, Option in pairs(Options) do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        elseif Option.Type == "KeyPicker" then
            Option:Update()
        end
    end

    -- Ensure groupboxes recompute sizes after layout updates settle
    task.defer(function()
        for _, Tab in pairs(Library.Tabs) do
            if Tab.IsKeyTab then
                continue
            end

            for _, Groupbox in pairs(Tab.Groupboxes) do
                pcall(function()
                    if Groupbox and Groupbox.Container and Groupbox.Holder then
                        local list = Groupbox.Container:FindFirstChildOfClass("UIListLayout")
                        if list then
                            local contentH = list.AbsoluteContentSize.Y
                            Groupbox.Holder.Size = UDim2.new(1, 0, 0, math.ceil((contentH + 53) * Library.DPIScale))
                        end
                        if Groupbox.Holder.BackgroundTransparency ~= 0 then
                            Groupbox.Holder.BackgroundTransparency = 0
                        end
                    end
                end)
            end
        end
    end)

    Library:UpdateKeybindFrame()
    for _, Notification in pairs(Library.Notifications) do
        Notification:Resize()
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end
    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}
    local DPIProperties = Library.DPIRegistry[Instance] or {}

    local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
    local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

    for k, v in pairs(Table) do
        if k == "DPIExclude" or k == "DPIOffset" then
            continue
        elseif ThemeProperties[k] then
            ThemeProperties[k] = nil
        elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
            -- me when Red in dropdowns break things (temp fix - or perm idk if deivid will do something about this)
            ThemeProperties[k] = v
            local assigned = Library.Scheme[v] or v()
            if k == "FontFace" then
                if typeof(assigned) == "string" then
                    local ok, enumVal = pcall(function() return Enum.Font[assigned] end)
                    if ok and enumVal then
                        assigned = Font.fromEnum(enumVal)
                    end
                elseif typeof(assigned) == "EnumItem" then
                    assigned = Font.fromEnum(assigned)
                end
            end
            Instance[k] = assigned
            continue
        end

        if not DPIExclude[k] then
            if k == "Position" or k == "Size" or k:match("Padding") then
                DPIProperties[k] = v
                v = ApplyDPIScale(v, DPIOffset[k])
            elseif k == "TextSize" then
                DPIProperties[k] = v
                v = ApplyTextScale(v)
            elseif k == "ScrollBarThickness" then
                DPIProperties[k] = v
                if typeof(v) == "number" then
                    v = math.ceil(v * Library.DPIScale)
                end
            end
        end

        -- Ensure FontFace properties get a proper Font object, not a string
        if k == "FontFace" then
            if typeof(v) == "string" then
                local ok, enumVal = pcall(function() return Enum.Font[v] end)
                if ok and enumVal then
                    v = Font.fromEnum(enumVal)
                end
            elseif typeof(v) == "EnumItem" then
                v = Font.fromEnum(v)
            end
        end

        Instance[k] = v
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
    if GetTableSize(DPIProperties) > 0 then
        DPIProperties["DPIExclude"] = DPIExclude
        DPIProperties["DPIOffset"] = DPIOffset
        Library.DPIRegistry[Instance] = DPIProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    -- Track UICorner instances created through New so we can update their CornerRadius
    if ClassName == "UICorner" then
        Library._ManagedUICorners = Library._ManagedUICorners or {}
        table.insert(Library._ManagedUICorners, Instance)
        -- initialize to current library corner radius if not explicitly provided
        if not Properties["CornerRadius"] then
            Instance.CornerRadius = UDim.new(0, Library.CornerRadius)
        end
    end

    -- Auto-attach accent gradient to lucide-style icons
    if (ClassName == "ImageLabel" or ClassName == "ImageButton") and Properties and Properties.Image and Properties.Image ~= "" then
        local hasRect = Properties.ImageRectSize or Properties.ImageRectOffset
        if hasRect then
            local grad = Instance:FindFirstChild("LucideAccentGradient") or Instance:FindFirstChildOfClass("UIGradient")
            if not grad then
                grad = New("UIGradient", { Name = "LucideAccentGradient", Parent = Instance })
            end

            pcall(function()
                grad.Color = Library:GetAccentGradientSequence()
                grad.Transparency = Library:GetAccentGradientTransparencySequence()
            end)

            Library.Registry[grad] = {
                Color = function()
                    return Library:GetAccentGradientSequence()
                end,
                Transparency = function()
                    return Library:GetAccentGradientTransparencySequence()
                end,
            }
        end
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 999,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
    Library.DPIRegistry[Instance] = nil
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Cursor
local Cursor
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 999,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = CursorV,
    })
end

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed

    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        ZIndex = 2,
        Parent = Frame,
    })	
    local ShadowStroke = New("UIStroke", {
        Color = "Dark",
        Thickness = 2,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

--// Deprecated \\--
function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
	warn("Obsidian:MakeOutline is deprecated, please use Obsidian:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "Dark",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableLabel(Text: string)
    local Table = {}

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
            Size = true,
        }
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Label,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    Library:AddOutline(Label)

    Library:MakeDraggable(Label, Label, true)

    Table.Label = Label

    function Table:SetText(Text: string)
        Label.Text = Text
    end

    function Table:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    return Table
end

function Library:AddDraggableButton(Text: string, Func)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Button,
    })
    Library:AddOutline(Button)

    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    Table.Button = Button

    function Table:SetText(NewText: string)
        local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)

        Button.Text = NewText
        Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
        Library:UpdateDPI(Button, {
            Size = UDim2.fromOffset(X * 2, Y * 2),
        })
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Holder,
    })
    Library:AddOutline(Holder)
    Library:UpdateDPI(Holder, {
        Position = false,
        Size = false,
    })

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)
    return Holder, Container
end

--// Watermark - Deprecated \\--
do
    local WatermarkLabel = Library:AddDraggableLabel("")
    WatermarkLabel:SetVisible(false)

    function Library:SetWatermark(Text: string)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetText(Text)
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        warn("Watermark is deprecated, please use Library:AddDraggableLabel instead.")
        WatermarkLabel:SetVisible(Visible)
    end
end

--// Watermark (Name | FPS | PING) - New implementation
do
    local WM = {
        Holder = nil,
        Label = nil,
        Enabled = false,
        Name = "",
        _conn = nil,
    }

    function Library:CreateWatermark(Name)
        if WM.Holder then
            return
        end

        WM.Name = Name or ""

        WM.Holder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.fromOffset(200, 24),
            ZIndex = 999,
            Parent = ScreenGui,
            DPIExclude = {
                Position = true,
            },
        })
        WM.Corner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = WM.Holder })
        
        -- Add accent gradient at the bottom for better look
        local WMAccentBar = New("Frame", {
            BackgroundColor3 = "AccentColor",
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3),
            ZIndex = 1000,
            Parent = WM.Holder,
        })
        New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = WMAccentBar })
        local WMGradient = New("UIGradient", {
            Color = function() return Library:GetAccentGradientSequence() end,
            Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
            Rotation = 0,
            Parent = WMAccentBar,
        })
        
        local WMStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = WM.Holder,
        })

        -- Add padding for better text spacing
        local WMPadding = New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = WM.Holder,
        })

        WM.Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 1, -3),
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1001,
            Parent = WM.Holder,
        })

        Library.Registry[WM.Holder] = { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" }
        Library.Registry[WM.Label] = { TextColor3 = "FontColor", FontFace = "Font" }
        Library.Registry[WMStroke] = { Color = "OutlineColor" }
        Library.Registry[WMAccentBar] = { BackgroundColor3 = "AccentColor" }
        Library.Registry[WMGradient] = {
            Color = function() return Library:GetAccentGradientSequence() end,
            Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
        }

        -- make watermark draggable (only when main UI is open)
        Library:MakeDraggable(WM.Holder, WM.Holder, false)

        local lastTime = tick()
        local frameCount = 0
        local fps = 0

        local function getPingMs()
            local ok, ping = pcall(function()
                if LocalPlayer and typeof(LocalPlayer.GetNetworkPing) == "function" then
                    return LocalPlayer:GetNetworkPing() * 1000
                else
                    return 0
                end
            end)
            if ok and type(ping) == "number" then
                return math.floor(ping)
            end
            return 0
        end

        WM._conn = RunService.RenderStepped:Connect(function(dt)
            if not WM.Enabled then
                return
            end

            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 0.25 then
                fps = math.floor(frameCount / (now - lastTime) + 0.5)
                frameCount = 0
                lastTime = now
            end

            local ping = getPingMs()

            -- build text from selected fields
            local parts = {}
            if Library.WatermarkFields.Name and WM.Name and WM.Name ~= "" then
                table.insert(parts, WM.Name)
            end
            if Library.WatermarkFields.FPS then
                table.insert(parts, tostring(fps) .. " FPS")
            end
            if Library.WatermarkFields.Ping then
                table.insert(parts, tostring(ping) .. "ms")
            end
            if Library.WatermarkFields.Executor then
                local exec_name = (getexecutor or getexecutorname or getidentityexecutor or identifyexecutor or function() return 'Unknown' end)()
                table.insert(parts, exec_name)
            end

            WM.Label.Text = table.concat(parts, " | ")

            -- adjust size automatically using library font to ensure correct measurement
            local X, Y = Library:GetTextBounds(WM.Label.Text, Library.Scheme.Font, WM.Label.TextSize)
            -- Add padding to account for UIPadding (20px horizontal + 8px vertical) and accent bar (3px)
            local targetWidth = X + 20
            local targetHeight = Y + 11
            WM.Holder.Size = UDim2.fromOffset(math.ceil(targetWidth * Library.DPIScale), math.ceil(targetHeight * Library.DPIScale))
            Library:UpdateDPI(WM.Holder, { Size = UDim2.fromOffset(targetWidth, targetHeight) })
        end)

        WM.Holder.Visible = false
        WM.Enabled = false
        return WM
    end

    function Library:ToggleWatermark(Enable)
        if not WM.Holder then
            return
        end
        WM.Enabled = Enable and true or false
        WM.Holder.Visible = WM.Enabled
    end

    function Library:SetWatermarkName(Name)
        if not WM.Holder then
            return
        end
        WM.Name = Name or ""
    end

    function Library:SetWatermarkFields(Fields)
        if typeof(Fields) ~= "table" then
            return
        end
        for k, v in pairs(Fields) do
            if Library.WatermarkFields[k] ~= nil then
                Library.WatermarkFields[k] = v and true or false
            end
        end
    end

    function Library:DestroyWatermark()
        if WM._conn then
            WM._conn:Disconnect()
            WM._conn = nil
        end
        if WM.Holder then
            WM.Holder:Destroy()
            WM.Holder = nil
            WM.Label = nil
            WM.Enabled = false
        end
    end
    -- monitor global/getgenv and Library.Watermark for changes
    task.spawn(function()
        local last = nil
        while not Library.Unloaded do
            local ok, g = pcall(function() return getgenv and getgenv().watermark end)
            local globalVal = (ok and g ~= nil) and g or nil
            -- support both Library.Watermark and Library.watermark (case-insensitive usage)
            local libValUpper = rawget(Library, "Watermark")
            local libVallow = rawget(Library, "watermark")
            local libVal = (libVallow ~= nil) and libVallow or libValUpper

            local want
            if globalVal ~= nil then
                want = globalVal and true or false
            else
                want = (libVal ~= nil) and (libVal and true or false) or false
            end

            if want ~= last then
                if not WM.Holder then
                    Library:CreateWatermark(Library.CurrentWindowTitle or "")
                    -- Update watermark corner to match current Library.CornerRadius
                    if WM.Corner then
                        WM.Corner.CornerRadius = UDim.new(0, Library.CornerRadius)
                    end
                end
                Library:ToggleWatermark(want)
                -- sync both fields so either one works
                Library.Watermark = want
                Library.watermark = want
                last = want
            end

            task.wait(0.2)
        end
    end)
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 0,
            ScrollingEnabled = true,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
                ScrollBarThickness = false,
            },
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    end

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        if typeof(Table.Size) == "function" then
            Menu.Size = Table.Size()
        else
            Menu.Size = ApplyDPIScale(Table.Size)
        end

        -- Ensure menu stays inside the main window bounds (clamp if necessary)
        pcall(function()
            local MF = Library.MainFrame or MainFrame
            if MF and MF.Parent then
                local menuSize = Menu.Size
                -- resolve size in pixels (fall back to AbsoluteSize if needed)
                local menuW = (menuSize and menuSize.X and menuSize.X.Offset) or Menu.AbsoluteSize.X
                local menuH = (menuSize and menuSize.Y and menuSize.Y.Offset) or Menu.AbsoluteSize.Y

                local desiredX = Menu.Position.X.Offset or 0
                local desiredY = Menu.Position.Y.Offset or 0

                local mainX = MF.AbsolutePosition.X
                local mainY = MF.AbsolutePosition.Y
                local mainW = MF.AbsoluteSize.X
                local mainH = MF.AbsoluteSize.Y

                -- smart-placement: prefer opening below holder, flip above if not enough space
                local holderBottom = Holder.AbsolutePosition.Y + Holder.AbsoluteSize.Y
                local spaceBelow = (mainY + mainH) - holderBottom
                local spaceAbove = Holder.AbsolutePosition.Y - mainY

                -- X clamp first
                if menuW > mainW then
                    desiredX = mainX
                else
                    desiredX = math.clamp(desiredX, mainX, mainX + mainW - menuW)
                end

                -- Vertical placement: try below, else above, else clamp
                if menuH <= spaceBelow then
                    -- keep as-is (below)
                    -- desiredY already set from Offset; ensure it's at least holderBottom
                    if desiredY < holderBottom then desiredY = holderBottom end
                elseif menuH <= spaceAbove then
                    -- place above the holder
                    desiredY = Holder.AbsolutePosition.Y - menuH
                else
                    -- clamp within main window
                    if menuH > mainH then
                        desiredY = mainY
                    else
                        desiredY = math.clamp(desiredY, mainY, mainY + mainH - menuH)
                    end
                end

                -- Final clamp to ensure dropdown never goes outside main window bounds
                desiredX = math.clamp(desiredX, mainX, math.max(mainX, mainX + mainW - menuW))
                desiredY = math.clamp(desiredY, mainY, math.max(mainY, mainY + mainH - menuH))

                Menu.Position = UDim2.fromOffset(math.floor(desiredX), math.floor(desiredY))
            end
        end)
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
            -- also clamp while tracking holder movement
            pcall(function()
                local MF2 = Library.MainFrame or MainFrame
                if MF2 and MF2.Parent then
                    local menuSize = Menu.Size
                    local menuW = (menuSize and menuSize.X and menuSize.X.Offset) or Menu.AbsoluteSize.X
                    local menuH = (menuSize and menuSize.Y and menuSize.Y.Offset) or Menu.AbsoluteSize.Y

                    local desiredX = Menu.Position.X.Offset or 0
                    local desiredY = Menu.Position.Y.Offset or 0

                    local mainX = MF2.AbsolutePosition.X
                    local mainY = MF2.AbsolutePosition.Y
                    local mainW = MF2.AbsoluteSize.X
                    local mainH = MF2.AbsoluteSize.Y

                    -- smart-placement while tracking: prefer below, flip above if needed
                    local holderBottom = Holder.AbsolutePosition.Y + Holder.AbsoluteSize.Y
                    local spaceBelow = (mainY + mainH) - holderBottom
                    local spaceAbove = Holder.AbsolutePosition.Y - mainY

                    if menuW > mainW then
                        desiredX = mainX
                    else
                        desiredX = math.clamp(desiredX, mainX, mainX + mainW - menuW)
                    end

                    -- Vertical placement while tracking: prefer below, flip above if needed
                    if menuH <= spaceBelow then
                        if desiredY < holderBottom then desiredY = holderBottom end
                    elseif menuH <= spaceAbove then
                        desiredY = Holder.AbsolutePosition.Y - menuH
                    else
                        if menuH > mainH then
                            desiredY = mainY
                        else
                            desiredY = math.clamp(desiredY, mainY, mainY + mainH - menuH)
                        end
                    end

                    -- Final clamp for tracking update
                    desiredX = math.clamp(desiredX, mainX, math.max(mainX, mainX + mainW - menuW))
                    desiredY = math.clamp(desiredY, mainY, math.max(mainY, mainY + mainH - menuH))

                    Menu.Position = UDim2.fromOffset(math.floor(desiredX), math.floor(desiredY))

                    if menuH <= spaceBelow then
                        if desiredY < holderBottom then desiredY = holderBottom end
                    elseif menuH <= spaceAbove then
                        desiredY = Holder.AbsolutePosition.Y - menuH
                    else
                        if menuH > mainH then
                            desiredY = mainY
                        else
                            desiredY = math.clamp(desiredY, mainY, mainY + mainH - menuH)
                        end
                    end

                    Menu.Position = UDim2.fromOffset(math.floor(desiredX), math.floor(desiredY))
                end
            end)
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end
        Menu.Visible = false

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    BackgroundColor3 = "BackgroundColor",
    BorderColor3 = "OutlineColor",
    BorderSizePixel = 1,
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
local TooltipCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = TooltipLabel })
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, Y = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 4
    )

    TooltipLabel.Size = UDim2.fromOffset((X + 8) * Library.DPIScale, (Y + 4) * Library.DPIScale)
    Library:UpdateDPI(TooltipLabel, {
        Size = UDim2.fromOffset(X, Y),
        DPIOffset = {
            Size = { 8, 4 },
        },
    })
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.BackgroundTransparency = 1
        TooltipLabel.TextTransparency = 1
        TooltipLabel.Visible = true
        
        -- Fade in animation
        TweenService:Create(TooltipLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            TextTransparency = 0,
        }):Play()

        while
            Library.Toggled
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        -- Fade out animation
        local fadeTween = TweenService:Create(TooltipLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        })
        fadeTween.Completed:Connect(function()
            TooltipLabel.Visible = false
        end)
        fadeTween:Play()
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        -- Fade out animation
        local fadeTween = TweenService:Create(TooltipLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        })
        fadeTween.Completed:Connect(function()
            TooltipLabel.Visible = false
        end)
        fadeTween:Play()
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

    --// Tab Info Popup (separate from regular tooltips) --
    local TabInfoHolder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Visible = false,
        ZIndex = 21,
        Parent = ScreenGui,
    })
    local TabInfoCorner = New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = TabInfoHolder,
    })
    New("UIStroke", {
        Color = "Dark",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Parent = TabInfoHolder,
    })

    local TabInfoTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        TextSize = 14,
        TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
        Parent = TabInfoHolder,
    })

    local TabInfoDesc = New("TextLabel", {
        BackgroundTransparency = 1,
        TextSize = 12,
        TextTransparency = 0.4,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = TabInfoHolder,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = TabInfoHolder,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 2),
        Parent = TabInfoHolder,
    })

    local TabInfoRender = nil
    local TabInfoActive = false
    local TabInfoFadeTweens = {}

    local function UpdateTabInfoSize()
        if not TabInfoHolder then return end
        local maxWidth = math.floor(workspace.CurrentCamera.ViewportSize.X * 0.4)
        local pad = 12 -- left+right padding (6+6)
        local titleW, titleH = Library:GetTextBounds(TabInfoTitle.Text, TabInfoTitle.FontFace, TabInfoTitle.TextSize, maxWidth - pad)
        local descW, descH = Library:GetTextBounds(TabInfoDesc.Text, TabInfoDesc.FontFace, TabInfoDesc.TextSize, maxWidth - pad)
        local contentWidth = math.max(titleW, descW)
        local width = contentWidth + pad
        local height = titleH + descH + 8 -- small vertical spacing

        -- Set absolute size scaled by DPI for immediate layout, and register DPI targets
        TabInfoHolder.Size = UDim2.fromOffset(math.ceil(width * Library.DPIScale), math.ceil(height * Library.DPIScale))
        Library:UpdateDPI(TabInfoHolder, { Size = UDim2.fromOffset(width, height) })

        -- Title occupies full content width; center text inside via TextXAlignment
        TabInfoTitle.Size = UDim2.fromOffset(contentWidth, titleH)
        TabInfoDesc.Size = UDim2.fromOffset(contentWidth, descH)

        Library:UpdateDPI(TabInfoTitle, { Size = UDim2.fromOffset(contentWidth, titleH) })
        Library:UpdateDPI(TabInfoDesc, { Size = UDim2.fromOffset(contentWidth, descH) })
    end

    function Library:ShowTabInfo(HoverInstance: GuiObject, Title: string, Description: string)
        if not HoverInstance or typeof(Title) ~= "string" then return end
        
        -- Cancel any ongoing fade-out tweens
        for _, tween in pairs(TabInfoFadeTweens) do
            if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
                tween:Cancel()
            end
        end
        TabInfoFadeTweens = {}
        
        TabInfoTitle.Text = Title
        -- hide the description for tab tooltips; only show the title
        TabInfoDesc.Visible = false
        UpdateTabInfoSize()
    
        -- Set initial transparency for fade in
        TabInfoHolder.BackgroundTransparency = 1
        TabInfoTitle.TextTransparency = 1
        TabInfoHolder.Visible = true
        TabInfoActive = true
    
        -- Fade in animation (title and holder only)
        table.insert(TabInfoFadeTweens, TweenService:Create(TabInfoHolder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        }))
        table.insert(TabInfoFadeTweens, TweenService:Create(TabInfoTitle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0,
        }))
    
        for _, tween in pairs(TabInfoFadeTweens) do
            tween:Play()
        end

        if TabInfoRender and TabInfoRender.Connected then
            TabInfoRender:Disconnect()
            TabInfoRender = nil
        end

    TabInfoRender = RunService.RenderStepped:Connect(function()
        if not TabInfoActive or not HoverInstance or not HoverInstance.Parent or not HoverInstance.AbsolutePosition then
            Library:HideTabInfo()
            return
        end

        local absPos = HoverInstance.AbsolutePosition
        local absSize = HoverInstance.AbsoluteSize
        local centerX = math.floor(absPos.X + (absSize.X / 2))
        
        -- Position 6px above the TabBarWindow (parent of tab buttons)
        local tabBarWindowY = HoverInstance.Parent and HoverInstance.Parent.AbsolutePosition.Y or absPos.Y
        local py = math.floor(tabBarWindowY) - 6 - TabInfoHolder.AbsoluteSize.Y
        local px = math.floor(centerX - (TabInfoHolder.AbsoluteSize.X / 2))
        
        TabInfoHolder.Position = UDim2.fromOffset(px, py)
    end)
    end

    function Library:HideTabInfo()
        TabInfoActive = false
        if TabInfoRender and TabInfoRender.Connected then
            TabInfoRender:Disconnect()
            TabInfoRender = nil
        end
        
        -- Clear old tweens and create new fade-out tweens (title and holder only)
        TabInfoFadeTweens = {}
        
        -- Fade out animation
        local fadeTween = TweenService:Create(TabInfoHolder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        })
        table.insert(TabInfoFadeTweens, fadeTween)
        table.insert(TabInfoFadeTweens, TweenService:Create(TabInfoTitle, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1,
        }))
        
        fadeTween.Completed:Connect(function()
            TabInfoHolder.Visible = false
        end)
        
        for _, tween in pairs(TabInfoFadeTweens) do
            tween:Play()
        end
    end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _, Callback in Library.UnloadSignals do
        Library:SafeCallback(Callback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    Library.Unloaded = true
    
    -- Clean up footer cycle thread if it exists
    if Library._FooterCycleThread then
        task.cancel(Library._FooterCycleThread)
        Library._FooterCycleThread = nil
    end
    
    ScreenGui:Destroy()

    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")
local MoveIcon = Library:GetIcon("move")

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    -- Top ten fixes 🚀
    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers) -- Verify default modifiers

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,

                DPIExclude = {
                    Size = true,
                },
            })

            local Checkbox = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                local X = Library:GetTextBounds(Text, Label.FontFace, Label.TextSize)
                Label.Text = Text
                Label.Size = UDim2.new(0, X, 1, 0)
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22 * Library.DPIScale, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                if KeyPicker.Mode == "Click" then
                    -- invoke callbacks but do not change toggle state
                    Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
                    Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in pairs(Info.Modes) do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, Button in pairs(ModeButtons) do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local X, Y = Library:GetTextBounds(
                PickerText or KeyPicker.DisplayValue,
                Picker.FontFace,
                Picker.TextSize,
                ToggleLabel.AbsoluteSize.X
            )
            Picker.Text = PickerText or KeyPicker.DisplayValue
            Picker.Size = UDim2.fromOffset((X + 9) * Library.DPIScale, (Y + 4) * Library.DPIScale)
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end

            Library:UpdateKeybindFrame()
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers = VerifyModifiers(typeof(Modifiers) == "table" and Modifiers or KeyPicker.Modifiers)
            if GetTableSize(KeyPicker.Modifiers) > 0 then
                KeyPicker.DisplayValue = table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value
            else
                KeyPicker.DisplayValue = KeyPicker.Value
            end

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

            -- Wait for an non modifier key --
            local Input
            local ActiveModifiers = {}

            local GetInput = function()
                Input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() then
                    return true
                end
            end

            repeat
                task.wait()

                -- Wait for any input --
                Picker.Text = "..."
                Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

                if GetInput() then
                    Picking = false
                    KeyPicker:Update()
                    return
                end

                -- Escape --
                if Input.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Handle modifier keys --
                if IsModifierInput(Input) then
                    local StopLoop = false

                    repeat
                        task.wait()
                        if UserInputService:IsKeyDown(Input.KeyCode) then
                            task.wait(0.075)

                            if UserInputService:IsKeyDown(Input.KeyCode) then
                                -- Add modifier to the key list --
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                    KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                end

                                -- Wait for another input --
                                if GetInput() then
                                    StopLoop = true
                                    break -- Invalid Input
                                end

                                -- Escape --
                                if Input.KeyCode == Enum.KeyCode.Escape then
                                    break
                                end

                                -- Stop loop if its a normal key --
                                if not IsModifierInput(Input) then
                                    break
                                end
                            else
                                if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                    break -- Modifier is meant to be used as a normal key --
                                end
                            end
                        end
                    until false

                    if StopLoop then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end
                end

                break -- Input found, end loop
            until false

            local Key = "Unknown"
            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType];
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name;
            end

            if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then
                ActiveModifiers = {}
            end

            KeyPicker.Toggled = false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            -- RunService.RenderStepped:Wait()
            repeat
                task.wait()
            until not IsInputDown(Input) or UserInputService:GetFocusedTextBox()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end
            
            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Click" then
                if HoldingKey then
                    -- call callbacks but do not change toggled state
                    Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
                    Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if Library.Unloaded then
                return
            end

            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,

            -- `Info.Transparency` is used as a boolean flag elsewhere to enable
            -- transparency controls; ensure the stored transparency value is
            -- numeric (default 0) to avoid arithmetic on booleans.
            Transparency = (type(Info.Transparency) == "number" and Info.Transparency) or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })
        -- make the small holder respect the library corner radius
        New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = Holder })

        local _transImg = (CustomImageManager and CustomImageManager.GetAsset) and CustomImageManager.GetAsset("TransparencyTexture") or ""
        local HolderTransparency = New("ImageLabel", {
            Image = _transImg,
            ImageTransparency = (1 - (tonumber(ColorPicker.Transparency) or 0)),
            ScaleType = Enum.ScaleType.Tile,
            Size = UDim2.fromScale(1, 1),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        -- optional gradient overlay on the small holder preview (shows full gradient)
        local HolderGradient = nil

        --// Color Menu \\--
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1
        )
        ColorMenu.List.Padding = UDim.new(0, 8)
        ColorPicker.ColorMenu = ColorMenu

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ColorMenu.Menu,
        })

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorMenu.Menu,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local _satImg = (CustomImageManager and CustomImageManager.GetAsset) and CustomImageManager.GetAsset("SaturationMap") or ""
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = _satImg,
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        -- respect library corner radius for the sat/vib cursor instead of forcing a full circle
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "Dark",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        local HueGradient = New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            BorderColor3 = "Dark",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            local _transSelImg = (CustomImageManager and CustomImageManager.GetAsset) and CustomImageManager.GetAsset("TransparencyTexture") or ""
            TransparencySelector = New("ImageButton", {
                Image = _transSelImg,
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            local TransparencyGradient = New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            local _curTrans = tonumber(ColorPicker.Transparency) or 0
            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "White",
                BorderColor3 = "Dark",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, _curTrans),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)
                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// Gradient Picker (optional) \\--
        local GradientHolder, GradientBar, GradientUI, DotsContainer, PlusButton
        local GradientStops = {}
        local SelectedStop = nil

        local function UpdateGradientRender()
            if not GradientUI then
                return
            end

            -- Sort gradient stops by position once
            table.sort(GradientStops, function(a, b) 
                return (tonumber(a and a.pos) or 0) < (tonumber(b and b.pos) or 0) 
            end)

            -- Build color and transparency sequences directly
            local keypoints, tpoints = {}, {}
            local numStops = #GradientStops
            
            if numStops == 0 then
                -- Default: white gradient with no transparency
                local defaultColor = Color3.new(1, 1, 1)
                keypoints = { ColorSequenceKeypoint.new(0, defaultColor), ColorSequenceKeypoint.new(1, defaultColor) }
                tpoints = { NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0) }
            elseif numStops == 1 then
                -- Single stop: duplicate at both ends
                local s = GradientStops[1]
                local color = s.color or Color3.new(1, 1, 1)
                local transp = math.clamp(tonumber(s.transparency) or 0, 0, 1)
                keypoints = { ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, color) }
                tpoints = { NumberSequenceKeypoint.new(0, transp), NumberSequenceKeypoint.new(1, transp) }
            else
                -- Multiple stops: ensure endpoints at 0 and 1, build sequences
                local firstStop = GradientStops[1]
                local lastStop = GradientStops[numStops]
                
                -- Add first stop at 0 if needed
                if (tonumber(firstStop.pos) or 0) > 0 then
                    local color = firstStop.color or Color3.new(1, 1, 1)
                    local transp = math.clamp(tonumber(firstStop.transparency) or 0, 0, 1)
                    table.insert(keypoints, ColorSequenceKeypoint.new(0, color))
                    table.insert(tpoints, NumberSequenceKeypoint.new(0, transp))
                end
                
                -- Add all stops
                for _, s in ipairs(GradientStops) do
                    local pos = math.clamp(tonumber(s.pos) or 0, 0, 1)
                    local color = s.color or Color3.new(1, 1, 1)
                    local transp = math.clamp(tonumber(s.transparency) or 0, 0, 1)
                    table.insert(keypoints, ColorSequenceKeypoint.new(pos, color))
                    table.insert(tpoints, NumberSequenceKeypoint.new(pos, transp))
                end
                
                -- Add last stop at 1 if needed
                if (tonumber(lastStop.pos) or 0) < 1 then
                    local color = lastStop.color or Color3.new(1, 1, 1)
                    local transp = math.clamp(tonumber(lastStop.transparency) or 0, 0, 1)
                    table.insert(keypoints, ColorSequenceKeypoint.new(1, color))
                    table.insert(tpoints, NumberSequenceKeypoint.new(1, transp))
                end
            end

            -- Update gradient UI with new sequences
            local colorSeq = ColorSequence.new(keypoints)
            local transpSeq = NumberSequence.new(tpoints)
            GradientUI.Color = colorSeq
            GradientUI.Transparency = transpSeq
            
            -- Update preview gradient on holder if present
            if HolderGradient and HolderGradient.Parent then
                pcall(function()
                    HolderGradient.Color = colorSeq
                    HolderGradient.Transparency = transpSeq
                end)
            end

            -- Update dot positions and selection state
            for _, s in ipairs(GradientStops) do
                if s.dot and s.dot.Parent then
                    local pos = math.clamp(tonumber(s.pos) or 0, 0, 1)
                    s.dot.Position = UDim2.new(pos, 0, 0.5, 0)
                    
                    -- Update dot appearance
                    if s.color then
                        s.dot.BackgroundColor3 = s.color
                        s.dot.BorderColor3 = Library:GetDarkerColor(s.color)
                    end
                    
                    -- Update selection outline (use outline if available, otherwise find UIStroke)
                    local isSelected = (s == SelectedStop)
                    if s.outline then
                        s.outline.Transparency = isSelected and 0 or 1
                    else
                        local stroke = s.dot:FindFirstChildOfClass("UIStroke")
                        if stroke and stroke.Name == "AccentOutline" then
                            stroke.Transparency = isSelected and 0 or 1
                        end
                    end
                end
            end
        end

        local function CreateDot(stop)
            local pos = math.clamp(tonumber(stop and stop.pos) or 0, 0, 1)
            local color = (stop and stop.color) or Color3.new(1, 1, 1)
            
            local Dot = New("ImageButton", {
                Size = UDim2.fromOffset(14, 14),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = color,
                BorderColor3 = Library:GetDarkerColor(color),
                Position = UDim2.new(pos, 0, 0.5, 0),
                AutoButtonColor = false,
                Parent = DotsContainer,
            })
            
            -- Apply library corner radius to dots
            New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = Dot })
            
            -- Small persistent dark outline for visibility
            local SmallStroke = New("UIStroke", { 
                Name = "DarkOutline",
                Color = "Dark", 
                Thickness = 1, 
                Transparency = 0, 
                Parent = Dot 
            })
            Library.Registry[SmallStroke] = { Color = "Dark" }
            
            -- Accent outline shown only for selected dot
            local OutlineStroke = New("UIStroke", { 
                Name = "AccentOutline",
                Color = "AccentColor", 
                Thickness = 2, 
                Transparency = 1, 
                Parent = Dot 
            })
            Library.Registry[OutlineStroke] = { Color = "AccentColor" }

            stop.dot = Dot
            stop.outline = OutlineStroke

            -- Click to select this stop
            Dot.MouseButton1Click:Connect(function()
                SelectedStop = stop
                if ColorPicker and type(ColorPicker.SetValueRGB) == "function" then
                    ColorPicker:SetValueRGB(color, tonumber(stop.transparency) or 0)
                end
                UpdateGradientRender()
                -- Open color menu for immediate editing
                if ColorMenu and type(ColorMenu.Open) == "function" then
                    pcall(function() ColorMenu:Open() end)
                end
            end)

            -- Drag to move stop along gradient bar
            Dot.InputBegan:Connect(function(Input)
                if not IsDragInput(Input) or not GradientBar then return end
                
                local function updatePosition()
                    local minX = GradientBar.AbsolutePosition.X
                    local maxX = minX + GradientBar.AbsoluteSize.X
                    local width = maxX - minX
                    if width <= 0 then return false end
                    
                    local mouseX = Mouse.X or 0
                    local posX = math.clamp(mouseX, minX, maxX)
                    stop.pos = (posX - minX) / width
                    return true
                end
                
                task.spawn(function()
                    while IsDragInput(Input) do
                        if updatePosition() then
                            UpdateGradientRender()
                        end
                        RunService.RenderStepped:Wait()
                    end
                end)
            end)

            return Dot
        end

        local function AddGradientStop(pos, color, transparency)
            local p = math.clamp(tonumber(pos) or 0.5, 0, 1)
            local col = color or (ColorPicker and ColorPicker.Value) or Color3.new(1, 1, 1)
            local transp = math.clamp(tonumber(transparency) or (ColorPicker and tonumber(ColorPicker.Transparency)) or 0, 0, 1)
            
            local stop = { pos = p, color = col, transparency = transp }
            table.insert(GradientStops, stop)
            
            if DotsContainer then
                CreateDot(stop)
            elseif GradientBar then
                DotsContainer = New("Frame", { 
                    BackgroundTransparency = 1, 
                    Size = UDim2.fromScale(1, 1), 
                    Parent = GradientBar 
                })
                CreateDot(stop)
            end
            
            SelectedStop = stop
            UpdateGradientRender()
            
            -- Fire callback which will trigger theme manager to update and refresh all gradients
            print("[GRADIENT DEBUG AddGradientStop] Firing callback with", #GradientStops, "stops")
            Library:SafeCallback(ColorPicker.Callback, { Stops = GradientStops })
        end

        if Info.Gradient then
            GradientHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = ColorMenu.Menu })
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = GradientHolder })

            PlusButton = New("ImageButton", {
                Size = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Parent = GradientHolder,
            })

            -- Gradient bar sits between the plus and minus buttons
            GradientBar = New("Frame", { BackgroundColor3 = "White", Size = UDim2.new(1, -36, 0, 12), Parent = GradientHolder })
            New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = GradientBar })

            GradientUI = New("UIGradient", { Parent = GradientBar })
            -- Register GradientUI so it updates when theme changes
            Library.Registry[GradientUI] = {
                Color = function() return Library:GetAccentGradientSequence() end,
                Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
            }

            -- show the gradient on the small holder preview as well
            HolderGradient = New("UIGradient", { Parent = Holder })
            -- Register HolderGradient so it updates when theme changes
            Library.Registry[HolderGradient] = {
                Color = function() return Library:GetAccentGradientSequence() end,
                Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
            }

            -- (removed in-menu preview box; preview shown on the small holder instead)

            DotsContainer = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = GradientBar })

            -- minus button placed on the right side of the bar
            local MinusButton = New("ImageButton", {
                Size = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Parent = GradientHolder,
            })

            -- load icons independently
            local PlusIcon = Library:GetIcon("plus")
            if PlusIcon and PlusIcon.Url then
                pcall(function() PlusButton.Image = PlusIcon.Url end)
                if PlusIcon.ImageRectOffset then pcall(function() PlusButton.ImageRectOffset = PlusIcon.ImageRectOffset end) end
                if PlusIcon.ImageRectSize then pcall(function() PlusButton.ImageRectSize = PlusIcon.ImageRectSize end) end
                if (PlusIcon.ImageRectOffset or PlusIcon.ImageRectSize) then
                    local g = PlusButton:FindFirstChild("LucideAccentGradient") or PlusButton:FindFirstChildOfClass("UIGradient")
                    if not g then
                        g = New("UIGradient", { Name = "LucideAccentGradient", Parent = PlusButton })
                    end
                    pcall(function()
                        g.Color = Library:GetAccentGradientSequence()
                        g.Transparency = Library:GetAccentGradientTransparencySequence()
                    end)
                    Library.Registry[g] = {
                        Color = function()
                            return Library:GetAccentGradientSequence()
                        end,
                        Transparency = function()
                            return Library:GetAccentGradientTransparencySequence()
                        end,
                    }
                end
            end
            local MinusIcon = Library:GetIcon("minus")
            if MinusIcon and MinusIcon.Url then
                pcall(function() MinusButton.Image = MinusIcon.Url end)
                if MinusIcon.ImageRectOffset then pcall(function() MinusButton.ImageRectOffset = MinusIcon.ImageRectOffset end) end
                if MinusIcon.ImageRectSize then pcall(function() MinusButton.ImageRectSize = MinusIcon.ImageRectSize end) end
                if (MinusIcon.ImageRectOffset or MinusIcon.ImageRectSize) then
                    local g2 = MinusButton:FindFirstChild("LucideAccentGradient") or MinusButton:FindFirstChildOfClass("UIGradient")
                    if not g2 then
                        g2 = New("UIGradient", { Name = "LucideAccentGradient", Parent = MinusButton })
                    end
                    pcall(function()
                        g2.Color = Library:GetAccentGradientSequence()
                        g2.Transparency = Library:GetAccentGradientTransparencySequence()
                    end)
                    Library.Registry[g2] = {
                        Color = function()
                            return Library:GetAccentGradientSequence()
                        end,
                        Transparency = function()
                            return Library:GetAccentGradientTransparencySequence()
                        end,
                    }
                end
            end -- end MinusIcon block

            -- Plus button adds a new gradient stop at cursor position or middle
            PlusButton.MouseButton1Click:Connect(function()
                pcall(function()
                    AddGradientStop(0.5)
                end)
            end)

            MinusButton.MouseButton1Click:Connect(function()
                pcall(function()
                    if not SelectedStop then return end
                    if #GradientStops <= 1 then return end
                    local idx = nil
                    for i, s in ipairs(GradientStops) do
                        if s == SelectedStop then idx = i break end
                    end
                    if idx then
                        table.remove(GradientStops, idx)
                        if SelectedStop.dot and SelectedStop.dot.Parent then
                            pcall(function() SelectedStop.dot:Destroy() end)
                        end
                        SelectedStop = nil
                        UpdateGradientRender()
                        Library:SafeCallback(ColorPicker.Callback, { Stops = GradientStops })
                    end
                end)
            end)

            -- initialize with one stop in middle
            AddGradientStop(0.5)

            -- Preview handled via HolderGradient
        end

        --// End \\--

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            local _curTrans = tonumber(ColorPicker.Transparency) or 0
            if Info.Gradient then
                -- Show the full bar gradient on a white background; hide checker overlay
                Holder.BackgroundColor3 = Color3.new(1, 1, 1)
                Holder.BorderColor3 = Library:GetDarkerColor(Holder.BackgroundColor3)
                HolderTransparency.ImageTransparency = 1
            else
                HolderTransparency.ImageTransparency = (1 - _curTrans)
                Holder.BackgroundColor3 = ColorPicker.Value
                Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            end

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, _curTrans)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")

            -- sync gradient selected stop with current picker color
            if Info.Gradient and SelectedStop then
                SelectedStop.color = ColorPicker.Value
                SelectedStop.transparency = tonumber(ColorPicker.Transparency) or 0
                UpdateGradientRender()
            end
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            if Info.Gradient then
                print("[GRADIENT DEBUG ColorPicker:Update] Firing callbacks with", #GradientStops, "stops")
                Library:SafeCallback(ColorPicker.Callback, { Stops = GradientStops })
                Library:SafeCallback(ColorPicker.Changed, { Stops = GradientStops })
            else
                Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
                Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
            end
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        -- Expose gradient stop API so external callers (ThemeManager, savers) can
        -- read and populate the full gradient (pos, color, transparency).
        function ColorPicker:GetGradientStops()
            local out = {}
            for i, s in ipairs(GradientStops) do
                table.insert(out, { pos = tonumber(s.pos) or 0, color = s.color, transparency = tonumber(s.transparency) or 0 })
            end
            return out
        end

        function ColorPicker:SetGradientStops(stops)
            -- destroy existing dots
            for _, s in ipairs(GradientStops) do
                if s and s.dot and s.dot.Parent then
                    pcall(function() s.dot:Destroy() end)
                end
            end

            GradientStops = {}
            SelectedStop = nil

            if type(stops) == "table" then
                for _, s in ipairs(stops) do
                    local pos = tonumber((s and s.pos) or 0) or 0
                    local col = s and s.color
                    if typeof(col) == "string" and col:match("^#?%x%x%x%x%x%x$") then
                        local ok, c = pcall(Color3.fromHex, col:gsub("#", ""))
                        if ok and typeof(c) == "Color3" then
                            col = c
                        end
                    end
                    local transp = tonumber((s and s.transparency) or 0) or 0
                    AddGradientStop(pos, col, transp)
                end
            end

            -- if we have at least one stop, make the first stop the selected value
            if #GradientStops > 0 and GradientStops[1] then
                SelectedStop = GradientStops[1]
                ColorPicker:SetValueRGB(SelectedStop.color or Color3.new(1,1,1), SelectedStop.transparency or 0)
            end

            UpdateGradientRender()
        end

        Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider(Text)
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 12),
            Parent = Container,
        })

        if Text then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Text = Text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = Holder,
            })

            local X, _ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            local SizeX = X//2 + 10

            local LeftLine = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "AccentColor",
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 1),
                Parent = Holder,
            })
            local LeftGrad = New("UIGradient", {
                Color = Library:GetAccentSolidSequence(),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Parent = LeftLine,
            })
            Library.Registry[LeftGrad] = {
                Color = function()
                    return Library:GetAccentSolidSequence()
                end,
            }

            local RightLine = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "AccentColor",
                BorderSizePixel = 0,
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 1),
                Parent = Holder,
            })
            local RightGrad = New("UIGradient", {
                Color = Library:GetAccentSolidSequence(),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = RightLine,
            })
            Library.Registry[RightGrad] = {
                Color = function()
                    return Library:GetAccentSolidSequence()
                end,
            }
        else
            local Line = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "AccentColor",
                BorderSizePixel = 0,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, 0, 0, 1),
                Parent = Holder,
            })
            local LineGrad = New("UIGradient", {
                Color = Library:GetAccentSolidSequence(),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = Line,
            })
            Library.Registry[LineGrad] = {
                Color = function()
                    return Library:GetAccentSolidSequence()
                end,
            }
        end

        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, (Y + 4) * Library.DPIScale)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local _, Y =
                Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            TextLabel.Size = UDim2.new(1, 0, 0, (Y + 4) * Library.DPIScale)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        if Data.DoesWrap then
            local Last = TextLabel.AbsoluteSize

            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, (Y + 4) * Library.DPIScale)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function Funcs:AddButton(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()
                TweenService:Create(Button.Stroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()
                TweenService:Create(Button.Stroke, Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                }):Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.Red or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "Red" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.Red
                Library.Registry[SubButton.Base].TextColor3 = "Red"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.Red
            Library.Registry[Button.Base].TextColor3 = "Red"
        end

        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Checkbox,
        })

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        -- Add hover effect to checkbox
        Button.MouseEnter:Connect(function()
            if Toggle.Disabled then return end
            TweenService:Create(CheckboxStroke, Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end)
        Button.MouseLeave:Connect(function()
            if Toggle.Disabled then return end
            TweenService:Create(CheckboxStroke, Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end)

        local CheckboxGradient = New("UIGradient", {
            Color = Library:GetAccentGradientSequence(),
            Transparency = Library:GetAccentGradientTransparencySequence(),
            Rotation = 60,
            Enabled = false,
            Parent = Checkbox,
        })
        Library.Registry[CheckboxGradient] = {
            Color = function()
                return Library:GetAccentGradientSequence()
            end,
            Transparency = function()
                return Library:GetAccentGradientTransparencySequence()
            end,
        }

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Visible = false, -- Hide the check image since we're filling the checkbox instead
            Parent = Checkbox,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                -- Disable gradient and use dark background when disabled
                CheckboxGradient.Enabled = false
                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"
                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()

            -- Enable gradient only when checked, restore accent gradient colors
            CheckboxGradient.Color = Library:GetAccentGradientSequence()
            CheckboxGradient.Transparency = Library:GetAccentGradientTransparencySequence()
            CheckboxGradient.Enabled = Toggle.Value

            -- Fill the checkbox with gradient start color when checked, main color when unchecked
            Checkbox.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentGradientStart or Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = Toggle.Value and "AccentGradientStart" or "MainColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            if Toggle.MobileButton then
                Toggle.MobileButton:Update()
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        if Library.IsMobile then
            Toggle.MobileButton = Library:CreateMobileButton(Toggle)
        end

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            if Toggle.MobileButton then
                Toggle.MobileButton:Update()
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        if Library.IsMobile then
            Toggle.MobileButton = Library:CreateMobileButton(Toggle)
        end

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value

        Options[Idx] = Input

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = Slider.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 13),
            Text = "",
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Bar,
        })
        local BarStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        -- Add hover effect to slider
        Bar.MouseEnter:Connect(function()
            if Slider.Disabled then return end
            TweenService:Create(BarStroke, Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end)
        Bar.MouseLeave:Connect(function()
            if Slider.Disabled then return end
            TweenService:Create(BarStroke, Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end)

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = 2,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "Dark",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentGradientStart",
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,

            DPIExclude = {
                Size = true,
            },
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Fill,
        })
        local FillGradient = New("UIGradient", {
            Color = Library:GetAccentGradientSequence(),
            Transparency = Library:GetAccentGradientTransparencySequence(),
            Rotation = 90,
            Parent = Fill,
        })
        Library.Registry[FillGradient] = {
            Color = function()
                return Library:GetAccentGradientSequence()
            end,
            Transparency = function()
                return Library:GetAccentGradientTransparencySequence()
            end,
        }

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            FillGradient.Enabled = not Slider.Disabled
            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentGradientStart
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentGradientStart"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")
    
            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value)) --this will make  so it updates. and im calling this so i dont need to add an if :P
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")
    
            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max)) --same here. adding these comments for the funny
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = false
            end

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = true
            end
        end)

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            Multi = Info.Multi,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
            
            _ScrollConnection = nil,
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 39 or 21),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            Parent = Holder,
        })

        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = "---",
            TextSize = 14,
            FontFace = Library.Scheme.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Display,
        })
        local DisplayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Display,
        })

        -- Add hover effect to dropdown
        Display.MouseEnter:Connect(function()
            if Dropdown.Disabled then return end
            TweenService:Create(DisplayStroke, Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end)
        Display.MouseLeave:Connect(function()
            if Dropdown.Disabled then return end
            TweenService:Create(DisplayStroke, Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end)

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = Display,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = Display,
        })
        -- Ensure arrow is drawn above scrolling text
        ArrowImage.ZIndex = Display.ZIndex + 2
        -- Optionally create a left-aligned clipping frame to contain scrolling text so it never reaches the arrow
        local ScrollMask = nil
        if Library.ScrollingDropdown then
            ScrollMask = New("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(math.max(0, Display.AbsoluteSize.X - 24), Display.AbsoluteSize.Y),
                ZIndex = Display.ZIndex,
                Name = "ScrollMask",
                Parent = Display,
                ClipsDescendants = true,
            })
            -- Keep ScrollMask sized to leave room for the arrow + some padding
            Display:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if ScrollMask and ScrollMask.Parent then
                    local arrowW = (ArrowImage and ArrowImage.AbsoluteSize and ArrowImage.AbsoluteSize.X) or 16
                    local pad = 8
                    ScrollMask.Size = UDim2.fromOffset(math.max(0, Display.AbsoluteSize.X - (arrowW + pad)), Display.AbsoluteSize.Y)
                end
            end)
        end

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = Display,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })
        end

        local MenuTable = Library:AddContextMenu(
            Display,
            function()
                return UDim2.fromOffset(Display.AbsoluteSize.X, 0)
            end,
            function()
                return { 0.5, Display.AbsoluteSize.Y + 1.5 }
            end,
            2,
            function(Active: boolean)
                Display.TextTransparency = (Active and SearchBox) and 1 or 0
                ArrowImage.ImageTransparency = Active and 0 or 0.5
                ArrowImage.Rotation = Active and 180 or 0
                
                -- Stop scrolling when menu is open
                if Active and Dropdown._ScrollConnection then
                    Dropdown._ScrollConnection:Disconnect()
                    Dropdown._ScrollConnection = nil
                    local scrollLabel = Display:FindFirstChild("ScrollingText", true)
                    if scrollLabel then
                        scrollLabel:Destroy()
                    end
                elseif not Active then
                    -- Resume scrolling when menu closes
                    Dropdown:Display()
                end
                
                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end
            end
        )
        Dropdown.Menu = MenuTable
        Library:UpdateDPI(MenuTable.Menu, {
            Position = false,
            Size = false,
        })

        function Dropdown:RecalculateListSize(Count)
            local Y = math.clamp(
                (Count or GetTableSize(Dropdown.Values)) * (21 * Library.DPIScale),
                0,
                Info.MaxVisibleDropdownItems * (21 * Library.DPIScale)
            )

            MenuTable:SetSize(function()
                return UDim2.fromOffset(Display.AbsoluteSize.X, Y)
            end)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        local function FormatDisplayText()
            local s = ""
            if Info.Multi then
                for _, Value in pairs(Dropdown.Values) do
                    if Dropdown.Value[Value] then
                        s = s .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value)) .. ", "
                    end
                end
                s = s:sub(1, #s - 2)
            else
                s = Dropdown.Value and tostring(Dropdown.Value) or ""
                if s ~= "" and Info.FormatDisplayValue then
                    s = tostring(Info.FormatDisplayValue(s))
                end
            end
            return s
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = FormatDisplayText()

            -- Stop any existing scroll
            if Dropdown._ScrollConnection then
                Dropdown._ScrollConnection:Disconnect()
                Dropdown._ScrollConnection = nil
            end

            -- Check if text is too long. Reserve space for arrow and padding.
            local arrowWidth = (ArrowImage and ArrowImage.AbsoluteSize and ArrowImage.AbsoluteSize.X) or 16
            local paddingLeft = 8
            local paddingRight = 8
            local maxWidth = math.max(0, Display.AbsoluteSize.X - arrowWidth - paddingLeft - paddingRight)
            local fontForMeasure = Display.FontFace or Library.Scheme.Font
            local textWidth = Library:GetTextBounds(Str, fontForMeasure, Display.TextSize)
            
            if Library.ScrollingDropdown and textWidth > maxWidth and Str ~= "" then
                -- Text is too long, enable scrolling
                Display.Text = ""
                Display.TextXAlignment = Enum.TextXAlignment.Left
                Display.ClipsDescendants = true

                local startTime = tick()
                local scrollSpeed = 20 -- pixels per second
                local pauseDuration = 0.5 -- pause at each end (start delay)

                Dropdown._ScrollConnection = RunService.RenderStepped:Connect(function()
                    if not Display or not Display.Parent then
                        if Dropdown._ScrollConnection then
                            Dropdown._ScrollConnection:Disconnect()
                            Dropdown._ScrollConnection = nil
                        end
                        return
                    end

                    local elapsed = tick() - startTime
                    local overflow = textWidth - maxWidth
                    local cycleDuration = (overflow / scrollSpeed) * 2 + pauseDuration * 2
                    local phase = (elapsed % cycleDuration) / cycleDuration

                    local relOffset = 0
                    if phase < 0.25 then
                        relOffset = 0
                    elseif phase < 0.5 then
                        local scrollPhase = (phase - 0.25) / 0.25
                        relOffset = -overflow * scrollPhase
                    elseif phase < 0.75 then
                        relOffset = -overflow
                    else
                        local scrollPhase = (phase - 0.75) / 0.25
                        relOffset = -overflow * (1 - scrollPhase)
                    end

                    -- Use a TextLabel child inside the ScrollMask for smoother scrolling; size it to the full text width
                    local scrollLabel = ScrollMask:FindFirstChild("ScrollingText")
                    if not scrollLabel then
                        scrollLabel = New("TextLabel", {
                            Name = "ScrollingText",
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(0, 0),
                            Size = UDim2.fromOffset(math.ceil(textWidth), Display.AbsoluteSize.Y),
                            Text = Str,
                            TextSize = Display.TextSize,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            FontFace = fontForMeasure,
                            ZIndex = ScrollMask.ZIndex + 1,
                            Parent = ScrollMask,
                        })
                    end

                    scrollLabel.Size = UDim2.fromOffset(math.ceil(textWidth), Display.AbsoluteSize.Y)
                    scrollLabel.Text = Str
                    scrollLabel.FontFace = fontForMeasure
                    -- Position is relative to ScrollMask; apply animated offset only
                    scrollLabel.Position = UDim2.fromOffset(math.floor(relOffset), 0)
                end)
            else
                -- Text fits or scrolling disabled; ensure old (non-scrolling) mode shows ellipses and fits
                local displayStr = Str
                local fontForMeasure = Display.FontFace or Library.Scheme.Font
                if not Library.ScrollingDropdown and textWidth > maxWidth and displayStr ~= "" then
                    local ell = "..."
                    local low, high = 0, #displayStr
                    local best = nil
                    while low <= high do
                        local mid = math.floor((low + high) / 2)
                        local s = displayStr:sub(1, mid) .. ell
                        local w = Library:GetTextBounds(s, fontForMeasure, Display.TextSize)
                        if w <= maxWidth then
                            best = s
                            low = mid + 1
                        else
                            high = mid - 1
                        end
                    end

                    displayStr = best or (displayStr:sub(1, 1) .. ell)
                else
                    if #displayStr > 25 then
                        displayStr = displayStr:sub(1, 22) .. "..."
                    end
                end

                Display.Text = (displayStr == "" and "---" or displayStr)
                Display.ClipsDescendants = false
                -- Remove scrolling label if it exists anywhere under Display
                local scrollLabel = Display:FindFirstChild("ScrollingText", true)
                if scrollLabel then
                    scrollLabel:Destroy()
                end
            end
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}

                for Value, _ in pairs(Dropdown.Value) do
                    table.insert(Table, Value)
                end

                return Table
            end

            return Dropdown.Value and 1 or 0
        end

        local Buttons = {}
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues

            for Button, _ in pairs(Buttons) do
                Button:Destroy()
            end
            table.clear(Buttons)

            local Count = 0
            for _, Value in pairs(Values) do
                if SearchBox and not tostring(Value):lower():match(SearchBox.Text:lower()) then
                    continue
                end

                Count += 1
                local IsDisabled = table.find(DisabledValues, Value)
                local Table = {}

                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = tostring(Value),
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MenuTable.Menu,
                })
                local ButtonGradient = New("UIGradient", {
                    Color = Library:GetAccentGradientSequence(),
                    Transparency = Library:GetAccentGradientTransparencySequence(),
                    Rotation = 90,
                    Enabled = false,
                    Parent = Button,
                })
                Library.Registry[ButtonGradient] = {
                    Color = function()
                        return Library:GetAccentGradientSequence()
                    end,
                    Transparency = function()
                        return Library:GetAccentGradientTransparencySequence()
                    end,
                }
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    Parent = Button,
                })

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    Button.BackgroundTransparency = Selected and 0 or 1
                    Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.5
                    ButtonGradient.Enabled = Selected and not IsDisabled
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function()
                        local Try = not Selected

                        if not (Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull) then
                            Selected = Try
                            if Info.Multi then
                                Dropdown.Value[Value] = Selected and true or nil
                            else
                                Dropdown.Value = Selected and Value or nil
                            end

                            for _, OtherButton in pairs(Buttons) do
                                OtherButton:UpdateButton()
                            end
                        end

                        Table:UpdateButton()

                        -- Cleanup any existing scrolling text before updating display
                        if Dropdown._ScrollConnection then
                            Dropdown._ScrollConnection:Disconnect()
                            Dropdown._ScrollConnection = nil
                        end
                        local scrollLabelAnyLocal = Display:FindFirstChild("ScrollingText", true)
                        if scrollLabelAnyLocal then
                            scrollLabelAnyLocal:Destroy()
                        end

                        Dropdown:Display()

                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:UpdateDependencyBoxes()
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Dropdown:RecalculateListSize(Count)
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            -- Cleanup scrolling artifacts when value changes (or is cleared)
            if Dropdown._ScrollConnection then
                Dropdown._ScrollConnection:Disconnect()
                Dropdown._ScrollConnection = nil
            end
            local scrollLabelAny = Display:FindFirstChild("ScrollingText", true)
            if scrollLabelAny then
                scrollLabelAny:Destroy()
            end

            Dropdown:Display()
            for _, Button in pairs(Buttons) do
                Button:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                Library:UpdateDependencyBoxes()
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in pairs(Values) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            Display.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            
            -- Stop scrolling when hidden
            if not Visible and Dropdown._ScrollConnection then
                Dropdown._ScrollConnection:Disconnect()
                Dropdown._ScrollConnection = nil
            end
            
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, (Text and 39 or 21) * Library.DPIScale)

            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end)

        if SearchBox then
            SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList)
        end

        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end

        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
            
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if not Info.Multi then
                    break
                end
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local Viewport = {
            Object = ViewportObject,
            Camera = Info.Camera or Instance.new("Camera"),
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude

            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta

            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        return Passthrough
    end

    function Funcs:AddDependencyBox()
        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
                DPIExclude = {
                    BackgroundTransparency = true,
                },
            })
            local transparencyConnection = DepboxContainer:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                if DepboxContainer.BackgroundTransparency ~= 0 then
                    DepboxContainer.BackgroundTransparency = 0
                end
            end)
            -- Store connection to prevent garbage collection
            Library:GiveSignal(transparencyConnection)
            -- Explicitly ensure transparency is 0 after signal connection
            DepboxContainer.BackgroundTransparency = 0

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {},
        }

        local function ResizeDepbox()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y * Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Resize() task.defer(ResizeDepbox) end

        function Depbox:Update(CancelSearch)
            for _, Dependency in pairs(Depbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BackgroundTransparency = 0,
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
                DPIExclude = {
                    BackgroundTransparency = true,
                    Size = true,
                },
            })
            pcall(function()
                if Library.DPIRegistry and Library.DPIRegistry[DepGroupboxContainer] then
                    Library.DPIRegistry[DepGroupboxContainer]["Size"] = nil
                end
            end)
            local transparencyConnection = DepGroupboxContainer:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                if DepGroupboxContainer.BackgroundTransparency ~= 0 then
                    DepGroupboxContainer.BackgroundTransparency = 0
                end
            end)
            -- Store connection to prevent garbage collection
            Library:GiveSignal(transparencyConnection)
            -- Explicitly ensure transparency is 0 after signal connection
            DepGroupboxContainer.BackgroundTransparency = 0
            -- Prevent accidental collapse of dependency groupbox size
            do
                local _depSizeGuard = false
                local depSizeConnection = DepGroupboxContainer:GetPropertyChangedSignal("Size"):Connect(function()
                    if _depSizeGuard then return end
                    _depSizeGuard = true
                    local ok, yOff = pcall(function() return DepGroupboxContainer.Size.Y.Offset end)
                    if ok and tonumber(yOff) and yOff < math.ceil(18 * Library.DPIScale) then
                        DepGroupboxContainer.Size = UDim2.new(1, 0, 0, math.ceil(18 * Library.DPIScale))
                    end
                    _depSizeGuard = false
                end)
                Library:GiveSignal(depSizeConnection)
            end
            
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = DepGroupboxContainer,
            })
            Library:AddOutline(DepGroupboxContainer)
            Library:UpdateDPI(DepGroupboxContainer, {
                Size = false,
            })

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = DepGroupboxContainer,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        local function ResizeDepGroupbox()
            DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y + 18) * Library.DPIScale)
        end

        function DepGroupbox:Resize() task.defer(ResizeDepGroupbox) end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in pairs(DepGroupbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepGroupboxContainer.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                DepGroupboxContainer.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    elseif typeof(FontFace) == "string" then
        local ok, enumVal = pcall(function() return Enum.Font[FontFace] end)
        if ok and enumVal then
            FontFace = Font.fromEnum(enumVal)
        end
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Type = Info.Type
        Data.Persist = Info.Persist
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,

        DPIExclude = {
            Size = true,
        },
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = FakeBackground,

        DPIExclude = {
            Position = true,
            Size = true,
        }
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })
    Library:AddOutline(Holder)

    -- Determine notification style (default = MainColor).
    local notifyColorName = "MainColor"
    local iconData = nil
    if Data.Type then
        local t = tostring(Data.Type):lower()
        if t == "warning" or t == "warn" then
            notifyColorName = "Red"
            -- intentionally no icon for warning notifications
        end
    end

    if Library.Scheme[notifyColorName] then
        Holder.BackgroundColor3 = Library.Scheme[notifyColorName]
    end

    -- Decide icon for the notification (allow override via Info.Icon or Info.IconName)
    local iconData = nil
    do
        local iconName = nil
        if Info.IconName then
            iconName = Info.IconName
        elseif Info.Icon then
            iconName = Info.Icon
        else
            local t = Data.Type and tostring(Data.Type):lower() or "info"
            local TypeIconMap = {
                info = "bell",
                notice = "bell",
                success = "check-circle",
                ok = "check-circle",
                error = "x-circle",
                fail = "x-circle",
                warning = "alert-triangle",
                warn = "alert-triangle",
            }
            iconName = TypeIconMap[t] or "bell"
        end

        if iconName then
            -- prefer custom URL if provided; otherwise try lucide asset
            local ok, data = pcall(function() return Library:GetCustomIcon(iconName) end)
            if ok and data then
                iconData = data
            else
                pcall(function() iconData = Library:GetIcon(iconName) end)
            end
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    function Data:Resize()
        if Title then
            local X, Y = Library:GetTextBounds(
                Title.Text,
                Title.FontFace,
                Title.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Title.Size = UDim2.fromOffset(math.ceil(X), Y)
            TitleX = X
        end

        if Desc then
            local X, Y = Library:GetTextBounds(
                Desc.Text,
                Desc.FontFace,
                Desc.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Desc.Size = UDim2.fromOffset(math.ceil(X), Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset((TitleX > DescX and TitleX or DescX) + (24 * Library.DPIScale), 0)
    end

    function Data:ChangeTitle(NewText)
        if Title then
            Data.Title = tostring(NewText)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(NewText)
        if Desc then
            Data.Description = tostring(NewText)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end
        
        if DeleteConnection then
            DeleteConnection:Disconnect()
        end
        -- cleanup icon and its connections if present
        if Data._icon_conns then
            pcall(function()
                for _, c in pairs(Data._icon_conns) do
                    if c and c.Connected then
                        c:Disconnect()
                    end
                end
            end)
            Data._icon_conns = nil
        end
        if Data._icon then
            pcall(function() Data._icon:Destroy() end)
            Data._icon = nil
        end

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()
        
        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    -- Create icon inside the Holder after sizing so it moves with the notification
    if iconData then
        local Img = New("ImageLabel", {
            Size = UDim2.fromOffset(14 * Library.DPIScale, 14 * Library.DPIScale),
            BackgroundTransparency = 1,
            Image = iconData.Url,
            Parent = ScreenGui, -- use absolute positioning relative to screen
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(0, 0),
            ZIndex = 10,
            ScaleType = Enum.ScaleType.Crop,
            Visible = false, -- Start invisible until notification slides in
        })
        -- store reference
        Data._icon = Img

        -- Reposition the icon to top-right of the FakeBackground using absolute coordinates
        local function UpdateIconPosition()
            pcall(function()
                if not (FakeBackground and FakeBackground.Parent and Img and Img.Parent) then return end
                local fbPos = FakeBackground.AbsolutePosition
                local fbSize = FakeBackground.AbsoluteSize
                local imgSizeX = Img.AbsoluteSize.X
                local padding = math.floor(8 * Library.DPIScale)
                local x = fbPos.X + fbSize.X - padding - imgSizeX
                local y = fbPos.Y + padding
                Img.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
            end)
        end

        -- Connect updates and run once
        local conn1 = FakeBackground:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateIconPosition)
        local conn2 = FakeBackground:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateIconPosition)
        local conn3 = Img:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateIconPosition)
        UpdateIconPosition()
        -- Store connections so they can be cleaned up when notification is destroyed
        Data._icon_conns = { conn1, conn2, conn3 }
            if iconData.ImageRectOffset then
            pcall(function() Img.ImageRectOffset = iconData.ImageRectOffset end)
        end
        if iconData.ImageRectSize then
            pcall(function() Img.ImageRectSize = iconData.ImageRectSize end)
        end
        if iconData.ImageRectOffset or iconData.ImageRectSize then
            local g = Img:FindFirstChild("LucideAccentGradient") or Img:FindFirstChildOfClass("UIGradient")
            if not g then
                g = New("UIGradient", { Name = "LucideAccentGradient", Parent = Img })
            end
            pcall(function()
                g.Color = Library:GetAccentGradientSequence()
                g.Transparency = Library:GetAccentGradientTransparencySequence()
            end)
            Library.Registry[g] = {
                Color = function() return Library:GetAccentGradientSequence() end,
                Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
            }
        end
    end

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "White",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    -- Ensure progress/timer fill always uses the white scheme regardless of type
    pcall(function()
        if Library.Scheme.White then
            TimerFill.BackgroundColor3 = Library.Scheme.White
        end
    end)

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        New("Sound", {
            SoundId = SoundId,
            Volume = 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    local showTween = TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    })
    showTween:Play()
    -- Show icon after notification slides in
    if Data._icon then
        showTween.Completed:Connect(function()
            if Data._icon and Data._icon.Parent then
                Data._icon.Visible = true
            end
        end)
    end

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize = Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Library.OriginalMinSize

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    
    -- Update tooltip/watermark/tab info corners
    if TooltipCorner then
        TooltipCorner.CornerRadius = UDim.new(0, Library.CornerRadius)
    end
    if TabInfoCorner then
        TabInfoCorner.CornerRadius = UDim.new(0, Library.CornerRadius)
    end
    -- Update any other UICorners created through New
    if Library._ManagedUICorners then
        for _, c in ipairs(Library._ManagedUICorners) do
            if c and c.Parent and c:IsA("UICorner") then
                pcall(function()
                    c.CornerRadius = UDim.new(0, Library.CornerRadius)
                end)
            end
        end
    end
    
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    -- Update watermark name to the window title if watermark exists
    if typeof(Library.SetWatermarkName) == "function" then
        pcall(function()
            Library:SetWatermarkName(WindowInfo.Title)
        end)
    end
    Library.CurrentWindowTitle = WindowInfo.Title
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local Window
    local WindowTitle

    local SidebarHighlightCallback = WindowInfo.SidebarHighlightCallback

    local TopBarHeight = 48
    local TabBarHeight = 52
    local BottomBarHeight = 20
    local TopContentOffset = TopBarHeight + 1
    local BottomContentOffset = BottomBarHeight + 1

    local LayoutState = {
        IsCompact = WindowInfo.Compact,
        MinWidth = WindowInfo.SidebarMinWidth,
        CompactWidth = WindowInfo.SidebarCompactWidth,
        MinContentWidth = WindowInfo.MinContentWidth or 260,
        CollapseThreshold = WindowInfo.SidebarCollapseThreshold,
        CurrentWidth = nil,
        LastExpandedWidth = nil,
        MaxWidth = nil,
        GrabberHighlighted = false,
    }

    if LayoutState.MinWidth <= LayoutState.CompactWidth then
        LayoutState.MinWidth = LayoutState.CompactWidth + 32
    end

    if LayoutState.CollapseThreshold <= 0 then
        LayoutState.CollapseThreshold = 0.5
    elseif LayoutState.CollapseThreshold >= 1 then
        LayoutState.CollapseThreshold = 0.9
    end

    local InitialFrameWidth = math.max(WindowInfo.Size.X.Offset, LayoutState.MinWidth + LayoutState.MinContentWidth)
    local InitialExpandedWidth = WindowInfo.InitialSidebarWidth
        or math.floor(InitialFrameWidth * (WindowInfo.InitialSidebarScale or 0.3))
    LayoutState.CurrentWidth = math.max(LayoutState.MinWidth, InitialExpandedWidth)
    LayoutState.LastExpandedWidth = LayoutState.CurrentWidth

    local LayoutRefs = {
        DividerLine = nil,
        TitleHolder = nil,
        WindowIcon = nil,
        WindowTitle = nil,
        RightWrapper = nil,
        TabsFrame = nil,
        TabBarWindow = nil,
        ContainerFrame = nil,
        SidebarGrabber = nil,
        TabPadding = {},
        TabLabels = {},
    }

    local MoveReservedWidth = (MoveIcon and 28 + 12) or 0

    local SidebarDrag = {
        Active = false,
        StartWidth = 0,
        StartX = 0,
        TouchId = nil,
    }

    local function GetSidebarWidth()
        if MainFrame then
            return math.max(0, MainFrame.AbsoluteSize.X)
        end

        return LayoutState.IsCompact and LayoutState.CompactWidth or LayoutState.CurrentWidth
    end

    local function EnsureSidebarBounds()
        local Width = MainFrame and MainFrame.AbsoluteSize.X or WindowInfo.Size.X.Offset
        if Width <= 0 then
            return
        end

        LayoutState.MaxWidth = Width
        LayoutState.CurrentWidth = Width
        LayoutState.LastExpandedWidth = Width
    end

    local function SetSidebarHighlight(IsActive)
        local DividerLine = LayoutRefs.DividerLine
        if not DividerLine then
            return
        end

        LayoutState.GrabberHighlighted = IsActive == true

        if typeof(SidebarHighlightCallback) == "function" then
            Library:SafeCallback(SidebarHighlightCallback, DividerLine, LayoutState.GrabberHighlighted)
        else
            local TargetColor = LayoutState.GrabberHighlighted and GetLighterColor(Library.Scheme.OutlineColor)
                or Library.Scheme.OutlineColor

            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = TargetColor,
            }):Play()
        end
    end

    local function ApplySidebarLayout()
        EnsureSidebarBounds()

        local SidebarWidth = GetSidebarWidth()
        local IsCompact = LayoutState.IsCompact
        local TabStartY = TopContentOffset
        local ContentStartY = TabStartY + TabBarHeight

        if LayoutRefs.DividerLine then
            LayoutRefs.DividerLine.Visible = false
        end

        -- Update tab bar window position to stay centered above main window
        if LayoutRefs.TabBarWindow and LayoutRefs.TabsFrame and LayoutRefs.TabsList then
            -- Use the same logic as UpdateTabBarSize for consistency
            local tabsWidth = LayoutRefs.TabsList.AbsoluteContentSize.X + 12
            tabsWidth = math.max(tabsWidth, 100)  -- Minimum width
            local mainPos = MainFrame.AbsolutePosition
            local mainSize = MainFrame.AbsoluteSize
            local centerX = mainPos.X + (mainSize.X / 2)
            local tabBarY = mainPos.Y - TabBarHeight - 6  -- 6px gap above main window
            
            LayoutRefs.TabBarWindow.Position = UDim2.fromOffset(math.floor(centerX), math.floor(tabBarY))
            LayoutRefs.TabBarWindow.Size = UDim2.fromOffset(math.floor(tabsWidth), TabBarHeight)
        end

        if LayoutRefs.ContainerFrame then
            LayoutRefs.ContainerFrame.Position = UDim2.fromOffset(0, TopContentOffset)
            LayoutRefs.ContainerFrame.Size = UDim2.new(1, 0, 1, -(TopContentOffset + BottomContentOffset))
        end

        if LayoutRefs.SidebarGrabber then
            LayoutRefs.SidebarGrabber.Visible = false
        end

        local TitleWidth = LayoutState.CompactWidth
        if LayoutRefs.WindowTitle then
            LayoutRefs.WindowTitle.Visible = not IsCompact
            if not IsCompact then
                local TextWidth = Library:GetTextBounds(LayoutRefs.WindowTitle.Text, Library.Scheme.Font, 20)
                LayoutRefs.WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
                TitleWidth = math.max(
                    LayoutState.CompactWidth,
                    TextWidth + (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12)
                )
            else
                LayoutRefs.WindowTitle.Size = UDim2.new(0, 0, 1, 0)
                TitleWidth = LayoutState.CompactWidth
            end
        end

        if LayoutRefs.TitleHolder then
            LayoutRefs.TitleHolder.Size = UDim2.new(0, TitleWidth, 1, 0)
        end

        if LayoutRefs.WindowIcon then
            LayoutRefs.WindowIcon.Visible = WindowInfo.Icon ~= nil or IsCompact
        end

        if LayoutRefs.RightWrapper then
            local PositionX = TitleWidth + 8
            LayoutRefs.RightWrapper.Position = UDim2.new(0, PositionX, 0.5, 0)
            LayoutRefs.RightWrapper.Size = UDim2.new(1, -PositionX - 8 - MoveReservedWidth, 1, -16)
        end

        for _, Padding in ipairs(LayoutRefs.TabPadding) do
            Padding.PaddingLeft = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingRight = UDim.new(0, IsCompact and 14 or 12)
            Padding.PaddingTop = UDim.new(0, IsCompact and 7 or 11)
            Padding.PaddingBottom = UDim.new(0, IsCompact and 7 or 11)
        end

        for _, LabelObject in ipairs(LayoutRefs.TabLabels) do
            LabelObject.Visible = not IsCompact
        end

        SetSidebarHighlight(LayoutState.GrabberHighlighted)

        WindowInfo.Compact = LayoutState.IsCompact

        for _, TabObject in pairs(Library.Tabs) do
            if TabObject.UpdateButtonWidth then
                TabObject:UpdateButtonWidth()
            end

            if TabObject.RefreshSides then
                TabObject:RefreshSides()
            end
        end
    end

    local function SetSidebarWidth(Width)
        EnsureSidebarBounds()

        Width = Width or LayoutState.CurrentWidth

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        local WasCompact = LayoutState.IsCompact

        if Width <= Threshold then
            if not WasCompact then
                LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            end
            LayoutState.IsCompact = true
        else
            local TargetWidth = Width
            if WasCompact then
                TargetWidth = math.max(Width, LayoutState.MinWidth)
            end

            LayoutState.CurrentWidth = math.clamp(TargetWidth, LayoutState.MinWidth, LayoutState.MaxWidth)
            LayoutState.LastExpandedWidth = LayoutState.CurrentWidth
            LayoutState.IsCompact = false
        end

        ApplySidebarLayout()
    end

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
        -- Store MainFrame on Library so AddContextMenu can access it for dropdown clamping
        Library.MainFrame = MainFrame
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = MainFrame,
        })
        Library:AddOutline(MainFrame)

        -- rotating outline removed

        local InitialTitleWidth = math.max(
            LayoutState.CompactWidth,
            Library:GetTextBounds(WindowInfo.Title, Library.Scheme.Font, 20)
                + (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 12 or 12)
        )
        LayoutRefs.DividerLine = Library:MakeLine(MainFrame, {
            Position = UDim2.fromOffset(0, TopContentOffset + TabBarHeight),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 2,
        })

        local Lines = {
            {
                Position = UDim2.fromOffset(0, 48),
                Size = UDim2.new(1, 0, 0, 1),
            },
            {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -20),
                Size = UDim2.new(1, 0, 0, 1),
            },
        }
        for _, Info in pairs(Lines) do
            Library:MakeLine(MainFrame, Info)
        end

        if WindowInfo.BackgroundImage then
            New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })
        end

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, TopBarHeight),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        --// Title
        local TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, InitialTitleWidth, 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })
        LayoutRefs.TitleHolder = TitleHolder

        local WindowIcon
        if WindowInfo.Icon then
            WindowIcon = New("ImageButton", {
                Image = tonumber(WindowInfo.Icon) and string.format("rbxassetid://%d", WindowInfo.Icon) or WindowInfo.Icon,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        else
            WindowIcon = New("TextButton", {
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Size = WindowInfo.IconSize,
                BackgroundTransparency = 1,
                Parent = TitleHolder,
            })
        end
        WindowIcon.Visible = WindowInfo.Icon ~= nil or LayoutState.IsCompact
        LayoutRefs.WindowIcon = WindowIcon

        WindowTitle = New("TextButton", {
            BackgroundTransparency = 1,
            Text = WindowInfo.Title,
            TextSize = 20,
            Visible = not LayoutState.IsCompact,
            Parent = TitleHolder,
        })
        if not LayoutState.IsCompact then
            local TextWidth = Library:GetTextBounds(WindowTitle.Text, Library.Scheme.Font, 20)
            WindowTitle.Size = UDim2.new(0, TextWidth, 1, 0)
        else
            WindowTitle.Size = UDim2.new(0, 0, 1, 0)
        end

        LayoutRefs.WindowTitle = WindowTitle

        WindowTitle:GetPropertyChangedSignal("Text"):Connect(function()
            Library.CurrentWindowTitle = WindowTitle.Text
            pcall(function()
                Library:SetWatermarkName(WindowTitle.Text)
            end)
        end)

        --// Top Right Bar
        local RightWrapper = New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, InitialTitleWidth + 8, 0.5, 0),
            Size = UDim2.new(1, -(InitialTitleWidth + 16 + MoveReservedWidth), 1, -16),
            Parent = TopBar,
        })
        LayoutRefs.RightWrapper = RightWrapper

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search",
            Size = WindowInfo.SearchbarSize,
            TextScaled = true,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = SearchBox,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = SearchBox,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = SearchBox,
            })
        end

        if MoveIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Image = MoveIcon.Url,
                ImageColor3 = "OutlineColor",
                ImageRectOffset = MoveIcon.ImageRectOffset,
                ImageRectSize = MoveIcon.ImageRectSize,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TopBar,
            })
        end

        --// Bottom Bar \\--
        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, BottomBarHeight),
            Parent = MainFrame,
        })
        do
            local Cover = Library:MakeCover(BottomBar, "Top")
            Library:AddToRegistry(Cover, {
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
                end,
            })
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = BottomBar,
        })

        --// Footer
        local FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = typeof(WindowInfo.Footer) == "table" and WindowInfo.Footer[1] or WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            Parent = BottomBar,
        })
        
        -- Dynamic footer cycling for array footers
        if typeof(WindowInfo.Footer) == "table" and #WindowInfo.Footer > 1 then
            local footerIndex = 1
            local footerCycleInterval = WindowInfo.FooterCycleInterval or 3 -- seconds between changes
            local footerFadeDuration = WindowInfo.FooterFadeDuration or 0.5 -- fade transition duration
            
            local footerCycleThread = task.spawn(function()
                while not Library.Unloaded do
                    task.wait(footerCycleInterval)
                    if Library.Unloaded then break end
                    
                    -- Fade out
                    local fadeOut = TweenService:Create(FooterLabel, TweenInfo.new(footerFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextTransparency = 1
                    })
                    fadeOut:Play()
                    task.wait(footerFadeDuration)
                    
                    if Library.Unloaded then break end
                    
                    -- Change text
                    footerIndex = footerIndex % #WindowInfo.Footer + 1
                    FooterLabel.Text = WindowInfo.Footer[footerIndex]
                    
                    -- Fade in
                    local fadeIn = TweenService:Create(FooterLabel, TweenInfo.new(footerFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        TextTransparency = 0.5
                    })
                    fadeIn:Play()
                    task.wait(footerFadeDuration)
                end
            end)
            
            -- Clean up on unload
            Library._FooterCycleThread = footerCycleThread
        end

        --// Resize Button
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                ApplySidebarLayout()
                for _, Tab in pairs(Library.Tabs) do
                    Tab:Resize(true)
                end
            end)
        end

        New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })

        --// Tab Bar Window (separate floating window above main) \\--
        local TabBarWindow = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(200, TabBarHeight),
            Visible = false,
            ZIndex = 5,
            Parent = ScreenGui,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
            Parent = TabBarWindow,
        })
        Library:AddOutline(TabBarWindow)
        LayoutRefs.TabBarWindow = TabBarWindow
        -- initialize tab bar visibility to match main window
        TabBarWindow.Visible = MainFrame and MainFrame.Visible or false

        --// Tabs \\--
        Tabs = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = TabBarWindow,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            Parent = Tabs,
        })
        local TabsList = New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = Tabs,
        })
        LayoutRefs.TabsFrame = Tabs
        LayoutRefs.TabsList = TabsList

        -- rotating outline removed

        -- Update tab bar window size when tabs change
        local function UpdateTabBarSize()
            if not LayoutRefs.TabsFrame or not LayoutRefs.TabBarWindow or not LayoutRefs.TabsList then return end
            local tabsWidth = LayoutRefs.TabsList.AbsoluteContentSize.X + 12
            tabsWidth = math.max(tabsWidth, 100)
            local mainPos = MainFrame.AbsolutePosition
            local mainSize = MainFrame.AbsoluteSize
            local centerX = mainPos.X + (mainSize.X / 2)
            local tabBarY = mainPos.Y - TabBarHeight - 6

            LayoutRefs.TabBarWindow.Position = UDim2.fromOffset(math.floor(centerX), math.floor(tabBarY))
            LayoutRefs.TabBarWindow.Size = UDim2.fromOffset(math.floor(tabsWidth), TabBarHeight)
        end
        
        LayoutRefs.TabsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateTabBarSize)
        MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateTabBarSize)
        MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateTabBarSize)

        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.fromOffset(0, TopContentOffset),
            Size = UDim2.new(1, 0, 1, -(TopContentOffset + BottomContentOffset)),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })

        LayoutRefs.ContainerFrame = Container

        if WindowInfo.EnableSidebarResize then
            warn("Sidebar resizing is disabled when using the top-aligned tab bar layout")
        end

        task.defer(ApplySidebarLayout)
    end

    --// Window Table \\--
    Window = {}

    function Window:GetSidebarWidth()
        return GetSidebarWidth()
    end

    function Window:IsSidebarCompacted()
        return LayoutState.IsCompact
    end

    function Window:SetSidebarWidth(Width)
        SetSidebarWidth(Width)
    end

    function Window:SetCompact(State)
        assert(typeof(State) == "boolean", "State must be a boolean")

        local Threshold = LayoutState.MinWidth * LayoutState.CollapseThreshold
        if State then
            SetSidebarWidth(Threshold * 0.5)
        else
            SetSidebarWidth(LayoutState.LastExpandedWidth or LayoutState.CurrentWidth or LayoutState.MinWidth)
        end
    end

    function Window:ApplyLayout()
        ApplySidebarLayout()
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))
        
        WindowTitle.Text = title
        WindowInfo.Title = title
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon
        local UpdateTabWidth

        local TabContainer
        local TabLeft
        local TabRight

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.fromOffset(120, 40),
                Text = "",
                Parent = Tabs,
            })

            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = TabButton,
            })

            local TabOutline, TabShadow = Library:AddOutline(TabButton)
            if not Library.Registry[TabButton] then
                Library:AddToRegistry(TabButton, {})
            end
            Library.Registry[TabButton].BackgroundColor3 = "MainColor"

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = TabButton,
            })

            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, ButtonPadding)

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, Library:GetTextBounds(Name, Library.Scheme.Font, 16), 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromOffset(24, 24),
                    Parent = TabButton,
                })
            end

            UpdateTabWidth = function()
                local textWidth = Library:GetTextBounds(Name, Library.Scheme.Font, 16)
                local iconWidth = 0

                if TabIcon then
                    iconWidth = 24 + 6  -- icon width + padding
                end

                local paddingWidth = (LayoutState.IsCompact and 14 or 12) * 2
                local spacingWidth = TabIcon and 6 or 0  -- padding between icon and text
                local targetWidth

                if LayoutState.IsCompact then
                    targetWidth = 40  -- just fit the icon or minimal
                else
                    targetWidth = math.max(96, textWidth + iconWidth + paddingWidth + spacingWidth)
                end

                TabButton.Size = UDim2.fromOffset(targetWidth, 40)
            end

            UpdateTabWidth()

            TabButton.MouseEnter:Connect(function()
                Library:ShowTabInfo(TabButton, Name, Description)
            end)
            TabButton.MouseLeave:Connect(function()
                Library:HideTabInfo()
            end)

            TabButton.MouseEnter:Connect(function()
                Library:ShowTabInfo(TabButton, Name, Description)
            end)
            TabButton.MouseLeave:Connect(function()
                Library:HideTabInfo()
            end)

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                ScrollBarImageColor3 = "OutlineColor",
                ScrollingEnabled = true,
                BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                Parent = TabContainer,
                
                DPIExclude = {
                    ScrollBarThickness = false,
                },
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabLeft,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })

                TabLeft.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabLeft, { Size = TabLeft.Size })

                TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    TabLeft.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                    Library:UpdateDPI(TabLeft, { Size = TabLeft.Size })
                end)
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarThickness = 0,
                ScrollBarImageColor3 = "OutlineColor",
                ScrollingEnabled = true,
                BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                Parent = TabContainer,
                
                DPIExclude = {
                    ScrollBarThickness = false,
                },
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabRight,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })

                TabRight.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabRight, { Size = TabRight.Size })

                TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    TabRight.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                    Library:UpdateDPI(TabRight, { Size = TabRight.Size })
                end)
            end
		end

        --// Warning Box \\--
		local WarningBoxHolder = New("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.fromScale(1, 0),
			Visible = false,
			Parent = TabContainer
		})

		local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
		local WarningBoxScrollingFrame
		local WarningTitle
		local WarningStroke
		local WarningText
		do
            WarningBox = New("Frame", {
				BackgroundColor3 = "BackgroundColor",
				Size = UDim2.fromScale(1, 0),
				Parent = WarningBoxHolder,
			})
			New("UICorner", {
				CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
				Parent = WarningBox,
			})
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)
            Library:UpdateDPI(WarningBox, {
                Size = false,
            })
			
			WarningBoxScrollingFrame = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Parent = WarningBox,
			})
			New("UIPadding", {
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 4),
				Parent = WarningBoxScrollingFrame,
			})
			
			WarningTitle = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -4, 0, 14),
				Text = "",
				TextColor3 = Color3.fromRGB(255, 50, 50),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = WarningBoxScrollingFrame,
			})
			
			WarningStroke = New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = Color3.fromRGB(169, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Miter,
				Parent = WarningTitle,
			})
			
			WarningText = New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 16),
				Size = UDim2.new(1, -4, 0, 0),
				Text = "",
				TextSize = 14,
				TextWrapped = true,
				Parent = WarningBoxScrollingFrame,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})
			
			New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = "Dark",
				LineJoinMode = Enum.LineJoinMode.Miter,
				Parent = WarningText,
			})
		end

        --// Tab Table \\--
        local Tab = {
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
            UpdateButtonWidth = UpdateTabWidth,
            Sides = {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },
        }

        function Tab:UpdateWarningBox(Info)
			if typeof(Info.IsNormal) == "boolean" then
				Tab.WarningBox.IsNormal = Info.IsNormal
			end
			if typeof(Info.LockSize) == "boolean" then
				Tab.WarningBox.LockSize = Info.LockSize
			end
			if typeof(Info.Visible) == "boolean" then
				Tab.WarningBox.Visible = Info.Visible
			end
			if typeof(Info.Title) == "string" then
				Tab.WarningBox.Title = Info.Title
			end
			if typeof(Info.Text) == "string" then
				Tab.WarningBox.Text = Info.Text
			end

			WarningBoxHolder.Visible = Tab.WarningBox.Visible
			WarningTitle.Text = Tab.WarningBox.Title
			WarningText.Text = Tab.WarningBox.Text
			Tab:Resize(true)

			WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
				or Color3.fromRGB(127, 0, 0)

			WarningBoxShadowOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.Dark
				or Color3.fromRGB(169, 0, 0)
			WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
				or Color3.fromRGB(255, 50, 50)
			
			WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
				or Color3.fromRGB(255, 50, 50)
			WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
				or Color3.fromRGB(169, 0, 0)

			if not Library.Registry[WarningBox] then
				Library:AddToRegistry(WarningBox, {})
			end
			if not Library.Registry[WarningBoxShadowOutline] then
				Library:AddToRegistry(WarningBoxShadowOutline, {})
			end
			if not Library.Registry[WarningBoxOutline] then
				Library:AddToRegistry(WarningBoxOutline, {})
			end
			if not Library.Registry[WarningTitle] then
				Library:AddToRegistry(WarningTitle, {})
			end
			if not Library.Registry[WarningStroke] then
				Library:AddToRegistry(WarningStroke, {})
			end

			Library.Registry[WarningBox].BackgroundColor3 = function()
				return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
			end

			Library.Registry[WarningBoxShadowOutline].Color = function()
				return Tab.WarningBox.IsNormal == true and Library.Scheme.Dark or Color3.fromRGB(169, 0, 0)
			end
			
			Library.Registry[WarningBoxOutline].Color = function()
				return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
			end

			Library.Registry[WarningTitle].TextColor3 = function()
				return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
			end

			Library.Registry[WarningStroke].Color = function()
				return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
			end
		end

        function Tab:RefreshSides()
			local Offset = WarningBoxHolder.Visible and WarningBox.AbsoluteSize.Y + 6 or 0
			for _, Side in pairs(Tab.Sides) do
				Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
				Side.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, -Offset)
				Library:UpdateDPI(Side, {
					Position = Side.Position,
					Size = Side.Size,
				})
			end
		end

        -- Connect to TabContainer size changes to refresh sides automatically
        TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if Tab == Library.ActiveTab then
                Tab:RefreshSides()
            end
        end)

        function Tab:Resize(ResizeWarningBox: boolean?)
			if ResizeWarningBox then
				local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
				local _, YText = Library:GetTextBounds(
					WarningText.Text,
					Library.Scheme.Font,
					WarningText.TextSize,
					WarningText.AbsoluteSize.X
				)

				local YBox = 24 + YText
				if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
					WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
					YBox = MaximumSize
				else
					WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
				end

				WarningText.Size = UDim2.new(1, -4, 0, YText)
				Library:UpdateDPI(WarningText, { Size = WarningText.Size })

				WarningBox.Size = UDim2.new(1, 0, 0, (YBox + 4) * Library.DPIScale)
                Library:UpdateDPI(WarningBox, { Size = WarningBox.Size })
			end

			Tab:RefreshSides()
		end

        function Tab:AddGroupbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local GroupboxHolder
            local GroupboxLabel

            local GroupboxContainer
            local GroupboxList

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.new(1, 0, 0, math.ceil(34 * Library.DPIScale)),
                    Parent = BoxHolder,
                    DPIExclude = {
                        BackgroundTransparency = true,
                        Size = true,
                    },
                })
                -- Ensure no leftover DPI registry Size entry overrides this holder
                pcall(function()
                    if Library.DPIRegistry and Library.DPIRegistry[GroupboxHolder] then
                        Library.DPIRegistry[GroupboxHolder]["Size"] = nil
                    end
                end)
                -- Force background to be opaque and prevent any accidental transparency changes
                local transparencyConnection = GroupboxHolder:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                    if GroupboxHolder.BackgroundTransparency ~= 0 then
                        GroupboxHolder.BackgroundTransparency = 0
                    end
                end)
                -- Store connection to prevent garbage collection
                Library:GiveSignal(transparencyConnection)
                -- Explicitly ensure transparency is 0 and color is applied
                GroupboxHolder.BackgroundTransparency = 0
                if Library.Scheme and Library.Scheme.BackgroundColor then
                    GroupboxHolder.BackgroundColor3 = Library.Scheme.BackgroundColor
                end
                -- Force re-apply after a frame to ensure it sticks
                task.defer(function()
                    if GroupboxHolder and GroupboxHolder.Parent then
                        GroupboxHolder.BackgroundTransparency = 0
                        if Library.Scheme and Library.Scheme.BackgroundColor then
                            GroupboxHolder.BackgroundColor3 = Library.Scheme.BackgroundColor
                        end
                    end
                end)
                -- Prevent accidental collapse of groupbox holder size
                do
                    local _sizeGuard = false
                    local sizeConnection = GroupboxHolder:GetPropertyChangedSignal("Size"):Connect(function()
                        if _sizeGuard then return end
                        _sizeGuard = true
                        local ok, yOff = pcall(function() return GroupboxHolder.Size.Y.Offset end)
                        local minSize = math.ceil(34 * Library.DPIScale)
                        if ok and tonumber(yOff) and yOff < minSize then
                            GroupboxHolder.Size = UDim2.new(1, 0, 0, minSize)
                        end
                        _sizeGuard = false
                    end)
                    Library:GiveSignal(sizeConnection)
                end
                
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = GroupboxHolder,
                })
                Library:AddOutline(GroupboxHolder)
                Library:UpdateDPI(GroupboxHolder, {
                    Size = false,
                })

                Library:MakeLine(GroupboxHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "White" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(6, 6),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = Info.Name,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                    Parent = GroupboxLabel,
                })

                GroupboxContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = GroupboxContainer,
                })

                DepGroupboxContainer = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.new(1, 0, 0, math.ceil(18 * Library.DPIScale)),
                    Visible = false,
                    Parent = BoxHolder,
                    DPIExclude = {
                        BackgroundTransparency = true,
                        Size = true,
                    },
                })
                -- Register dependency groupbox container for immediate theming
                Library:AddToRegistry(DepGroupboxContainer, { BackgroundColor3 = "BackgroundColor" })
                Library:UpdateColorsUsingRegistry()
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = DepGroupboxContainer,
                })
            end

            local Groupbox = {
                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,

                Tab = Tab,
                DependencyBoxes = {},
                Elements = {},
            }

            local function ResizeGroupbox()
                task.defer(function()
                    if not GroupboxList or not GroupboxHolder then return end
                    local contentH = GroupboxList.AbsoluteContentSize.Y or 0
                    local newHeight = math.ceil((contentH + 53) * Library.DPIScale)
                    GroupboxHolder.Size = UDim2.new(1, 0, 0, newHeight)
                    -- Reapply theme colors after resize to ensure backgrounds remain visible
                    Library:UpdateColorsUsingRegistry()
                end)
            end

            function Groupbox:Resize() task.defer(ResizeGroupbox) end

            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName })
        end

        function Tab:AddRightGroupbox(Name, IconName)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName })
        end

        function Tab:AddAimbotGroupbox(Info)
            Info = Info or {}
            
            -- Get style from parameter (default to r15)
            local style = Info.AimbotGroupboxStyle or "r15"
            style = string.lower(style)
            
            -- Use standard groupbox structure
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local GroupboxHolder = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                BackgroundTransparency = 0,
                Size = UDim2.new(1, 0, 0, math.ceil(34 * Library.DPIScale)),
                Parent = BoxHolder,
                DPIExclude = {
                    BackgroundTransparency = true,
                    Size = true,
                },
            })
            pcall(function()
                if Library.DPIRegistry and Library.DPIRegistry[GroupboxHolder] then
                    Library.DPIRegistry[GroupboxHolder]["Size"] = nil
                end
            end)
            local transparencyConnection = GroupboxHolder:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                if GroupboxHolder.BackgroundTransparency ~= 0 then
                    GroupboxHolder.BackgroundTransparency = 0
                end
            end)
            -- Store connection to prevent garbage collection
            Library:GiveSignal(transparencyConnection)
            -- Explicitly ensure transparency is 0 after signal connection
            GroupboxHolder.BackgroundTransparency = 0
            -- Prevent accidental collapse of aimbot groupbox size
            do
                local _aimSizeGuard = false
                local aimSizeConnection = GroupboxHolder:GetPropertyChangedSignal("Size"):Connect(function()
                    if _aimSizeGuard then return end
                    _aimSizeGuard = true
                    local ok, yOff = pcall(function() return GroupboxHolder.Size.Y.Offset end)
                    local minSize = math.ceil(34 * Library.DPIScale)
                    if ok and tonumber(yOff) and yOff < minSize then
                        GroupboxHolder.Size = UDim2.new(1, 0, 0, minSize)
                    end
                    _aimSizeGuard = false
                end)
                Library:GiveSignal(aimSizeConnection)
            end
            
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = GroupboxHolder,
            })
            Library:AddOutline(GroupboxHolder)
            Library:UpdateDPI(GroupboxHolder, {
                Size = false,
            })

            Library:MakeLine(GroupboxHolder, {
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local GroupboxLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 34),
                Text = Info.Text or "Aimbot Configuration",
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = GroupboxHolder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = GroupboxLabel,
            })

            local GroupboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                Parent = GroupboxHolder,
            })

            local GroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = GroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = GroupboxContainer,
            })

            -- Body canvas container
            local BodyCanvas = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 300),
                Parent = GroupboxContainer,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BodyCanvas,
            })
            Library:AddOutline(BodyCanvas)

            local AimbotBox = {
                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,
                HitChances = {},
                SelectedPart = nil,
                Callback = Info.Callback or function() end,
            }

            -- Body part buttons
            local BodyPartButtons = {}
            local SkinColor = Color3.fromRGB(255, 255, 255)
            local SelectedColor = SkinColor

            -- Spacing constant
            local SPACING = 3
            -- Standard width for limbs
            local LIMB_WIDTH = 20

            -- Create slider that appears on top of body parts
            local SliderFrame = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromOffset(120, 60),
                Position = UDim2.fromOffset(0, 0),
                Visible = false,
                ZIndex = 10,
                Parent = BodyCanvas,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = SliderFrame,
            })
            Library:AddOutline(SliderFrame)
            Library.Registry[SliderFrame] = Library.Registry[SliderFrame] or {}
            Library.Registry[SliderFrame].BackgroundColor3 = "BackgroundColor"

            local SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 4),
                Size = UDim2.new(1, -12, 0, 16),
                Text = "Hit Chance",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = SliderFrame,
            })
            Library.Registry[SliderLabel] = Library.Registry[SliderLabel] or {}
            Library.Registry[SliderLabel].TextColor3 = "FontColor"

            -- Use existing slider visuals (bar + gradient fill + value text)
            local Bar = New("TextButton", {
                Active = true,
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromOffset(6, 26),
                Size = UDim2.new(1, -12, 0, 20),
                Text = "",
                Parent = SliderFrame,
            })
            New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = Bar })
            local BarStroke = New("UIStroke", { Color = "OutlineColor", Parent = Bar })

            local DisplayLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "100%",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 2,
                Parent = Bar,
            })
            Library.Registry[DisplayLabel] = Library.Registry[DisplayLabel] or {}
            Library.Registry[DisplayLabel].TextColor3 = "FontColor"
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "Dark",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = DisplayLabel,
            })

            local Fill = New("Frame", {
                BackgroundColor3 = "AccentGradientStart",
                Size = UDim2.fromScale(1, 1),
                Parent = Bar,
                DPIExclude = { Size = true },
            })
            New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = Fill })
            local FillGradient = New("UIGradient", { Color = Library:GetAccentGradientSequence(), Transparency = Library:GetAccentGradientTransparencySequence(), Rotation = 90, Parent = Fill })
            Library.Registry[FillGradient] = {
                Color = function() return Library:GetAccentGradientSequence() end,
                Transparency = function() return Library:GetAccentGradientTransparencySequence() end,
            }

            -- Slider interaction (reusing library slider behavior)
            local SliderMin, SliderMax, SliderRounding = 0, 100, 0
            local SliderValueNum = 100

            local function GetRemainingFor(partName)
                local sum = 0
                for name, v in pairs(AimbotBox.HitChances) do
                    if name ~= partName then
                        sum = sum + (tonumber(v) or 0)
                    end
                end
                return math.max(0, 100 - sum)
            end

            Bar.MouseEnter:Connect(function()
                TweenService:Create(BarStroke, Library.TweenInfo, { Color = Library.Scheme.AccentColor }):Play()
            end)
            Bar.MouseLeave:Connect(function()
                TweenService:Create(BarStroke, Library.TweenInfo, { Color = Library.Scheme.OutlineColor }):Play()
            end)

            Bar.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) or not AimbotBox.SelectedPart then return end

                for _, Side in pairs(Library.ActiveTab.Sides) do
                    Side.ScrollingEnabled = false
                end

                while IsDragInput(Input) do
                    local Location = Mouse.X
                    local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                    local OldValue = SliderValueNum
                    SliderValueNum = Round(SliderMin + ((SliderMax - SliderMin) * Scale), SliderRounding)

                    local denom = (SliderMax - SliderMin)
                    if denom <= 0 then denom = 1 end
                    Fill.Size = UDim2.fromScale((SliderValueNum - SliderMin) / denom, 1)
                    DisplayLabel.Text = tostring(SliderValueNum) .. "%"

                    AimbotBox.HitChances[AimbotBox.SelectedPart] = SliderValueNum
                    -- update percent label on the selected part
                    local sel = AimbotBox.SelectedPart
                    if sel and BodyPartButtons[sel] and BodyPartButtons[sel].Label then
                        BodyPartButtons[sel].Label.Text = tostring(SliderValueNum) .. "%"
                    end
                    if SliderValueNum ~= OldValue then
                        Library:SafeCallback(AimbotBox.Callback, AimbotBox.SelectedPart, SliderValueNum, AimbotBox.HitChances)
                    end

                    RunService.RenderStepped:Wait()
                end

                for _, Side in pairs(Library.ActiveTab.Sides) do
                    Side.ScrollingEnabled = true
                end
            end)

            -- Roblox R15 proportions (blocky, with spacing, uniform limb width)
            local R15BodyParts = {
                {Name = "Head", Position = UDim2.new(0.5, -25, 0, 15), Size = UDim2.fromOffset(50, 50)},
                {Name = "UpperTorso", Position = UDim2.new(0.5, -35, 0, 68 + SPACING), Size = UDim2.fromOffset(70, 45)},
                {Name = "LowerTorso", Position = UDim2.new(0.5, -30, 0, 116 + SPACING * 2), Size = UDim2.fromOffset(60, 38)},
                {Name = "LeftUpperArm", Position = UDim2.new(0.5, -45 - LIMB_WIDTH - SPACING, 0, 68 + SPACING), Size = UDim2.fromOffset(LIMB_WIDTH, 42)},
                {Name = "LeftLowerArm", Position = UDim2.new(0.5, -45 - LIMB_WIDTH - SPACING, 0, 113 + SPACING * 2), Size = UDim2.fromOffset(LIMB_WIDTH, 38)},
                {Name = "LeftHand", Position = UDim2.new(0.5, -45 - LIMB_WIDTH - SPACING, 0, 154 + SPACING * 3), Size = UDim2.fromOffset(LIMB_WIDTH, 16)},
                {Name = "RightUpperArm", Position = UDim2.new(0.5, 45 + SPACING, 0, 68 + SPACING), Size = UDim2.fromOffset(LIMB_WIDTH, 42)},
                {Name = "RightLowerArm", Position = UDim2.new(0.5, 45 + SPACING, 0, 113 + SPACING * 2), Size = UDim2.fromOffset(LIMB_WIDTH, 38)},
                {Name = "RightHand", Position = UDim2.new(0.5, 45 + SPACING, 0, 154 + SPACING * 3), Size = UDim2.fromOffset(LIMB_WIDTH, 16)},
                {Name = "LeftUpperLeg", Position = UDim2.new(0.5, -30, 0, 157 + SPACING * 3), Size = UDim2.fromOffset(LIMB_WIDTH, 50)},
                {Name = "LeftLowerLeg", Position = UDim2.new(0.5, -30, 0, 210 + SPACING * 4), Size = UDim2.fromOffset(LIMB_WIDTH, 45)},
                {Name = "LeftFoot", Position = UDim2.new(0.5, -30, 0, 258 + SPACING * 5), Size = UDim2.fromOffset(LIMB_WIDTH, 12)},
                {Name = "RightUpperLeg", Position = UDim2.new(0.5, 10, 0, 157 + SPACING * 3), Size = UDim2.fromOffset(LIMB_WIDTH, 50)},
                {Name = "RightLowerLeg", Position = UDim2.new(0.5, 10, 0, 210 + SPACING * 4), Size = UDim2.fromOffset(LIMB_WIDTH, 45)},
                {Name = "RightFoot", Position = UDim2.new(0.5, 10, 0, 258 + SPACING * 5), Size = UDim2.fromOffset(LIMB_WIDTH, 12)},
            }

            local R6BodyParts = {
                {Name = "Head", Position = UDim2.new(0.5, -32, 0, 20), Size = UDim2.fromOffset(64, 64)},
                {Name = "Torso", Position = UDim2.new(0.5, -40, 0, 87 + SPACING), Size = UDim2.fromOffset(80, 64)},
                {Name = "Left Arm", Position = UDim2.new(0.5, -50 - LIMB_WIDTH - SPACING, 0, 87 + SPACING), Size = UDim2.fromOffset(LIMB_WIDTH, 64)},
                {Name = "Right Arm", Position = UDim2.new(0.5, 50 + SPACING, 0, 87 + SPACING), Size = UDim2.fromOffset(LIMB_WIDTH, 64)},
                {Name = "Left Leg", Position = UDim2.new(0.5, -30, 0, 154 + SPACING * 2), Size = UDim2.fromOffset(LIMB_WIDTH, 64)},
                {Name = "Right Leg", Position = UDim2.new(0.5, 10, 0, 154 + SPACING * 2), Size = UDim2.fromOffset(LIMB_WIDTH, 64)},
            }

            local function CreateBodyParts(partsList)
                -- Clear existing parts
                for name, data in pairs(BodyPartButtons) do
                    if data.Button then
                        data.Button:Destroy()
                    end
                end
                BodyPartButtons = {}
                AimbotBox.HitChances = {}

                for _, partInfo in ipairs(partsList) do
                    AimbotBox.HitChances[partInfo.Name] = Info.DefaultChances and Info.DefaultChances[partInfo.Name] or 100

                    local btn = New("TextButton", {
                        BackgroundColor3 = SkinColor,
                        Position = partInfo.Position,
                        Size = partInfo.Size,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        Parent = BodyCanvas,
                    })

                    local percLabel = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = tostring(AimbotBox.HitChances[partInfo.Name]) .. "%",
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        Parent = btn,
                    })
                    Library.Registry[percLabel] = Library.Registry[percLabel] or {}
                    Library.Registry[percLabel].TextColor3 = "FontColor"

                    -- add outline stroke to percent label so outline follows theme
                    New("UIStroke", {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                        Color = "OutlineColor",
                        Thickness = 1,
                        Parent = percLabel,
                    })

                    BodyPartButtons[partInfo.Name] = {
                        Button = btn,
                        Info = partInfo,
                        Label = percLabel,
                    }

                    if not partInfo.NoSelect then
                        btn.MouseEnter:Connect(function() end)

                        btn.MouseLeave:Connect(function() end)

                        btn.MouseButton1Click:Connect(function()
                            -- Deselect old
                            if AimbotBox.SelectedPart and BodyPartButtons[AimbotBox.SelectedPart] then
                                local oldBtn = BodyPartButtons[AimbotBox.SelectedPart].Button
                                TweenService:Create(oldBtn, Library.TweenInfo, {
                                    BackgroundColor3 = SkinColor
                                }):Play()
                            end

                            -- Select new
                            AimbotBox.SelectedPart = partInfo.Name
                            TweenService:Create(btn, Library.TweenInfo, {
                                BackgroundColor3 = SelectedColor
                            }):Play()

                            -- Show slider on top of the clicked part
                            local chance = AimbotBox.HitChances[partInfo.Name] or 100
                            -- compute allowed max based on other parts so total <= 100
                            local allowedMax = GetRemainingFor(partInfo.Name)
                            if chance > allowedMax then
                                chance = allowedMax
                                AimbotBox.HitChances[partInfo.Name] = chance
                            end
                            SliderMax = allowedMax
                            SliderValueNum = chance
                            -- update label for the clicked part
                            if BodyPartButtons[partInfo.Name] and BodyPartButtons[partInfo.Name].Label then
                                BodyPartButtons[partInfo.Name].Label.Text = tostring(chance) .. "%"
                            end

                            local denom = (SliderMax - SliderMin)
                            if denom <= 0 then denom = 1 end
                            Fill.Size = UDim2.fromScale((chance - SliderMin) / denom, 1)
                            DisplayLabel.Text = chance .. "%"
                            SliderLabel.Text = partInfo.Name

                            -- Position slider above the part using absolute coordinates
                            local canvasPos = BodyCanvas.AbsolutePosition
                            local btnPos = btn.AbsolutePosition
                            local btnSize = btn.AbsoluteSize

                            local sliderW = SliderFrame.AbsoluteSize.X
                            local sliderH = SliderFrame.AbsoluteSize.Y
                            if sliderW == 0 then sliderW = SliderFrame.Size.X.Offset end
                            if sliderH == 0 then sliderH = SliderFrame.Size.Y.Offset end

                            local localX = math.floor(btnPos.X - canvasPos.X + (btnSize.X * 0.5) - (sliderW * 0.5))
                            local localY = math.floor(btnPos.Y - canvasPos.Y - sliderH - 8)

                            local maxX = math.max(4, BodyCanvas.AbsoluteSize.X - sliderW - 4)
                            local clampedX = math.clamp(localX, 4, maxX)
                            SliderFrame.Position = UDim2.fromOffset(clampedX, math.max(4, localY))
                            SliderFrame.Visible = true

                            Library:SafeCallback(AimbotBox.Callback, AimbotBox.SelectedPart, chance, AimbotBox.HitChances)
                        end)
                    end
                end

                -- Normalize defaults so total doesn't exceed 100
                do
                    local total = 0
                    for k, v in pairs(AimbotBox.HitChances) do
                        total = total + (tonumber(v) or 0)
                    end
                    if total > 100 and total > 0 then
                        for k, v in pairs(AimbotBox.HitChances) do
                            local scaled = math.floor(((tonumber(v) or 0) / total) * 100)
                            AimbotBox.HitChances[k] = math.max(0, scaled)
                        end
                        -- update labels after normalization
                        for k, data in pairs(BodyPartButtons) do
                            if data and data.Label and AimbotBox.HitChances[k] ~= nil then
                                data.Label.Text = tostring(AimbotBox.HitChances[k]) .. "%"
                            end
                        end
                    end
                end

            end

            -- Click outside to deselect
            Library:GiveSignal(BodyCanvas.InputBegan:Connect(function(Input)
                if IsClickInput(Input) then
                    -- Check if click is outside all body parts
                    local clickPos = Vector2.new(Input.Position.X, Input.Position.Y)
                    local canvasPos = BodyCanvas.AbsolutePosition
                    local relativeClick = clickPos - canvasPos
                    
                    local clickedOnPart = false
                    for _, data in pairs(BodyPartButtons) do
                        local btn = data.Button
                        local btnPos = Vector2.new(btn.AbsolutePosition.X, btn.AbsolutePosition.Y)
                        local btnSize = Vector2.new(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)
                        
                        if relativeClick.X >= (btnPos.X - canvasPos.X) and relativeClick.X <= (btnPos.X - canvasPos.X + btnSize.X) and
                           relativeClick.Y >= (btnPos.Y - canvasPos.Y) and relativeClick.Y <= (btnPos.Y - canvasPos.Y + btnSize.Y) then
                            clickedOnPart = true
                            break
                        end
                    end
                    
                    if not clickedOnPart and AimbotBox.SelectedPart then
                        -- Deselect
                        if BodyPartButtons[AimbotBox.SelectedPart] then
                            local oldBtn = BodyPartButtons[AimbotBox.SelectedPart].Button
                            TweenService:Create(oldBtn, Library.TweenInfo, {
                                BackgroundColor3 = SkinColor
                            }):Play()
                        end
                        AimbotBox.SelectedPart = nil
                        SliderFrame.Visible = false
                    end
                end
            end))

            -- Initialize with the specified style
            CreateBodyParts(style == "r6" and R6BodyParts or R15BodyParts)

            function AimbotBox:GetHitChances()
                return AimbotBox.HitChances
            end

            function AimbotBox:SetHitChance(partName, value)
                if AimbotBox.HitChances[partName] ~= nil then
                            -- clamp value to remaining budget (including this part's current value)
                            local numeric = math.clamp(value, 0, 100)
                            -- compute allowed remaining with this part excluded
                            local allowed = GetRemainingFor(partName)
                            numeric = math.clamp(numeric, 0, allowed)
                            AimbotBox.HitChances[partName] = numeric
                            -- update label (always) and overlay if currently selected
                            if BodyPartButtons[partName] and BodyPartButtons[partName].Label then
                                BodyPartButtons[partName].Label.Text = tostring(numeric) .. "%"
                            end
                            if AimbotBox.SelectedPart == partName then
                                SliderMax = allowed
                                local denom = (SliderMax - SliderMin)
                                if denom <= 0 then denom = 1 end
                                Fill.Size = UDim2.fromScale((numeric - SliderMin) / denom, 1)
                                DisplayLabel.Text = numeric .. "%"
                                SliderValueNum = numeric
                            end
                end
            end

            function AimbotBox:SetVisible(visible)
                BoxHolder.Visible = visible
            end

            -- Resize groupbox
            local function ResizeGroupbox()
                GroupboxHolder.Size = UDim2.new(1, 0, 0, (GroupboxList.AbsoluteContentSize.Y + 53) * Library.DPIScale)
            end

            function AimbotBox:Resize()
                task.defer(ResizeGroupbox)
            end

            AimbotBox:Resize()

            return AimbotBox
        end

        function Tab:AddTabbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.new(1, 0, 0, math.ceil(34 * Library.DPIScale)),
                    Parent = BoxHolder,
                    DPIExclude = {
                        BackgroundTransparency = true,
                        Size = true,
                    },
                })
                pcall(function()
                    if Library.DPIRegistry and Library.DPIRegistry[TabboxHolder] then
                        Library.DPIRegistry[TabboxHolder]["Size"] = nil
                    end
                end)
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = TabboxHolder,
                })
                Library:AddOutline(TabboxHolder)
                Library:UpdateDPI(TabboxHolder, {
                    Size = false,
                })
                -- Prevent accidental collapse of tabbox holder size
                do
                    local _tabSizeGuard = false
                    local tabSizeConnection = TabboxHolder:GetPropertyChangedSignal("Size"):Connect(function()
                        if _tabSizeGuard then return end
                        _tabSizeGuard = true
                        local ok, yOff = pcall(function() return TabboxHolder.Size.Y.Offset end)
                        local minSize = math.ceil(34 * Library.DPIScale)
                        if ok and tonumber(yOff) and yOff < minSize then
                            TabboxHolder.Size = UDim2.new(1, 0, 0, minSize)
                        end
                        _tabSizeGuard = false
                    end)
                    Library:GiveSignal(tabSizeConnection)
                end

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })
            end

            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = TabboxHolder,
                Tabs = {},
            }

            function Tabbox:AddTab(Name)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = TabboxButtons,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    ButtonHolder = Button,
                    Container = Container,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    Button.TextTransparency = 0
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    Button.TextTransparency = 0.5
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                local function ResizeTab()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end

                    TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y + 53) * Library.DPIScale)
                end

                function Tab:Resize() task.defer(ResizeTab) end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab

                return Tab
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            if Description then
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
            end

            TabContainer.Visible = true
            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon
        local UpdateTabWidth

        local TabContainer

        Icon = (Icon == "key") and KeyIcon or Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.None,
                Size = UDim2.fromOffset(120, 40),
                Text = "",
                Parent = Tabs,
            })

            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = TabButton,
            })

            local KeyTabOutline, KeyTabShadow = Library:AddOutline(TabButton)
            if not Library.Registry[TabButton] then
                Library:AddToRegistry(TabButton, {})
            end
            Library.Registry[TabButton].BackgroundColor3 = "MainColor"
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = TabButton,
            })

            local KeyTabPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                PaddingLeft = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingRight = UDim.new(0, LayoutState.IsCompact and 14 or 12),
                PaddingTop = UDim.new(0, LayoutState.IsCompact and 7 or 11),
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabPadding, KeyTabPadding)

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, Library:GetTextBounds(Name, Library.Scheme.Font, 16), 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not LayoutState.IsCompact,
                Parent = TabButton,
            })
            table.insert(LayoutRefs.TabLabels, TabLabel)

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "White" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromOffset(24, 24),
                    Parent = TabButton,
                })
            end

            UpdateTabWidth = function()
                local textWidth = Library:GetTextBounds(Name, Library.Scheme.Font, 16)
                local iconWidth = 0

                if TabIcon then
                    iconWidth = 24 + 6  -- icon width + padding
                end

                local paddingWidth = (LayoutState.IsCompact and 14 or 12) * 2
                local spacingWidth = TabIcon and 6 or 0  -- padding between icon and text
                local targetWidth

                if LayoutState.IsCompact then
                    targetWidth = 40  -- just fit the icon or minimal
                else
                    targetWidth = math.max(96, textWidth + iconWidth + paddingWidth + spacingWidth)
                end

                TabButton.Size = UDim2.fromOffset(targetWidth, 40)
            end

            UpdateTabWidth()

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Elements = {},
            UpdateButtonWidth = UpdateTabWidth,
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })

            Button.InputBegan:Connect(function(Input) 
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end
            TabContainer.Visible = true

            if Description then
                CurrentTabInfo.Visible = true

                if IsDefaultSearchbarSize then
                    SearchBox.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            if IsDefaultSearchbarSize then
                SearchBox.Size = UDim2.fromScale(1, 1)
            end

            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Library:Toggle(Value: boolean?)
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        MainFrame.Visible = Library.Toggled
        
        -- Also toggle the tab bar window visibility
        if LayoutRefs.TabBarWindow then
            LayoutRefs.TabBarWindow.Visible = Library.Toggled
        end

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            pcall(function()
                RunService:UnbindFromRenderStep("ShowCursor")
            end)
            RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep("ShowCursor")
                end
            end)

        elseif not Library.Toggled then
            SetSidebarHighlight(false)
            TooltipLabel.Visible = false

            for _, Option in pairs(Library.Options) do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()

                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    if WindowInfo.AutoShow then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)

            LockButton.Button.Position = UDim2.new(1, -6, 0, 46)
            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
        else
            LockButton.Button.Position = UDim2.fromOffset(6, 46)
        end
    end

    --// Execution \\--
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library
return Library
