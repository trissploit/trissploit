-- copy of UI setup from jjsold.lua
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

--// Player / Camera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

--// Common constructors (worth localizing)
local Vector2 = Vector2
local Vector3 = Vector3
local CFrame = CFrame
local Color3 = Color3
local Enum = Enum
local Instance = Instance
local Drawing = Drawing

-- Remote library loading (the same Obsidian/TrisSploit UI library that jjsold uses)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/library.lua"))()
end)
if not success or not Library then
    warn("Failed to load UI library")
    return
end
Library.ForceCheckbox = true

-- always strip icons from notifications globally
if Library and Library.Notify then
    local _origNotify = Library.Notify
    Library.Notify = function(self, ...)
        local info = select(1, ...)
        if type(info) == "table" then
            info.Icon = nil
            info.IconName = nil
        end
        return _origNotify(self, ...)
    end
end

local success2, ThemeManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/thememanager.lua"))()
end)
if not success2 then
    ThemeManager = nil
end

-- attempt to load local UI customization overrides (if executor supports file access)
pcall(function()
    if ThemeManager and isfile and readfile then
        local path = "UI/Addons/UIcustomization.lua"
        if isfile(path) then
            local ok, custom = pcall(loadstring, readfile(path))
            if ok and type(custom) == "table" then
                for k, v in pairs(custom) do
                    ThemeManager[k] = v
                end
            end
        end
    end
end)

local success3, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/savemanager.lua"))()
end)
if not success3 then
    SaveManager = nil
end

-- Load TrisESP (external player ESP library)
local TrisESPLoaded = false
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/trissploit/trissploit/refs/heads/main/esp.luau"))()
    TrisESPLoaded = true
end)

-- previously we used the TrisROCKS FOV circle system but simplify to a basic drawing
-- (no external dependency)
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.new(1,1,1)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Radius = 100  -- initial value, will be updated

-- persistent bullet TP line
local bulletTPLine = Drawing.new("Line")
bulletTPLine.Visible = false
bulletTPLine.Thickness = 2
bulletTPLine.Color = Color3.new(1,1,1) -- will update later
bulletTPLine.ZIndex = 1005


-- Queue-based ESP setting helper (safe from synchronous callbacks)
local pendingESPSettings = {}
local function applyPendingESPSettings()
    if getgenv().TrisESP and getgenv().TrisESP.Settings then
        for k, v in pairs(pendingESPSettings) do
            getgenv().TrisESP.Settings[k] = v
        end
        pendingESPSettings = {}
    end
end

local function setESPSetting(key, value)
    if getgenv().TrisESP and getgenv().TrisESP.Settings then
        getgenv().TrisESP.Settings[key] = value
    else
        pendingESPSettings[key] = value
        task.spawn(function()
            for i = 1, 20 do
                task.wait(0.1)
                if getgenv().TrisESP and getgenv().TrisESP.Settings then
                    applyPendingESPSettings()
                    return
                end
            end
        end)
    end
end

-- Initialize ESP defaults (disabled until user enables via UI)
if TrisESPLoaded and getgenv().TrisESP then
    getgenv().TrisESP.Settings.Enabled = false
    getgenv().TrisESP.Settings.Boxes = false
    getgenv().TrisESP.Settings.BoxFill = false
    getgenv().TrisESP.Settings.Highlight = false
    getgenv().TrisESP.Settings.ShowDistance = false
    getgenv().TrisESP.Settings.ShowName = false
    getgenv().TrisESP.Settings.Tracers = false
    getgenv().TrisESP.Settings.HealthBarEnabled = false
    getgenv().TrisESP.Settings.ShowHealthText = false
    -- new gradient defaults (static rotation; no animation for text labels)
    getgenv().TrisESP.Settings.NameGradientRotation = 0

    getgenv().TrisESP.Settings.DistanceGradientRotation = 0

    getgenv().TrisESP.Settings.HealthTextGradientRotation = 0
end

-- build the window
local Window = Library:CreateWindow({
    Title = "tris.rocks",
    Footer = "tris.rocks | in development | version: 1.0",
    Icon = "rbxassetid://85419017315177",
    CornerRadius = 0,
    Size = UDim2.fromOffset(580, 460),
    NotifySide = "Right",
    ShowCustomCursor = false,
    Compact = true,
    LocalizedAssets = true,  -- download & use cached assets; no repeated web pulls
})


-- grab the shared options/toggles table (examplelib pattern)
local Options = Library.Options
local Toggles = Library.Toggles

local Tabs = {
    Home = Window:AddTab("Home", "boxes", "Overview & status"),
    Farming = Window:AddTab("Farming", "leaf", "Farming features"),
    Combat = Window:AddTab("Combat", "sword", "Combat options"),
    Visuals = Window:AddTab("Visuals", "eye", "Visual tweaks"),
    World = Window:AddTab("World", "globe", "World / lighting options"),
    Modifications = Window:AddTab("Modifications", "wrench", "Misc modifications"),
    Settings = Window:AddTab("Settings", "cog", "Configuration"),
}

Tabs.Home:UpdateWarningBox({
    Title = "Development Notice",
    Text = "SCRIPT IS IN DEVELOPMENT! Script may have bugs or things may not function properly",
    IsNormal = false,
    Visible = true,
    LockSize = true
})

-- example groupboxes, change or remove as needed
local ChangelogsBox = Tabs.Home:AddLeftGroupbox("Changelogs", "scroll")
ChangelogsBox:AddLabel("Updates posted in Discord server.", true)

local CreditsBox = Tabs.Home:AddRightGroupbox("Credits", "award")
CreditsBox:AddLabel("<font color='rgb(255,0,255)'>worldwide</font> - founder & developer", true)
CreditsBox:AddLabel("<font color='rgb(0,255,255)'>nebula</font> - developer", true)

local function safeSetClipboard(text)
    local ok = pcall(function()
        if setclipboard then setclipboard(text)
        elseif toclipboard then toclipboard(text)
        elseif Clipboard and Clipboard.set then Clipboard.set(text)
        end
    end)
    return ok
end

local SocialBox = Tabs.Home:AddRightGroupbox("Socials", "users")
SocialBox:AddLabel("Join Discord for updates & support!", true)
SocialBox:AddButton("Join Discord", function()
    if safeSetClipboard("https://discord.gg/example") then
        Library:Notify("Discord invite copied!", 3)
        local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9086208311"; s.Volume = 0.3; s.Parent = SoundService; s:Play(); s.Ended:Wait(); s:Destroy()
    else
        Library:Notify("Clipboard not supported!", 3)
    end
end)

-- Farming tab groupbox for tycoon farm auto-buy
local FarmingGroup = Tabs.Farming:AddLeftGroupbox("Tycoon Farm", "leaf")
local autoBuyEnabled = false

FarmingGroup:AddToggle("AutoBuy", {
    Text = "Auto Buy",
    Default = false,
    Callback = function(val)
        autoBuyEnabled = val
        if val then
            task.spawn(function()
                while autoBuyEnabled do
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    -- determine team name from GUI using updated path
                    local teamText = nil
                    pcall(function()
                        local plName = LocalPlayer.Name
                        local entry = LocalPlayer.PlayerGui.UI.Container.HUD.PlayerList.PlayerList.ScrollingFrame:FindFirstChild(plName)
                        if entry and entry:FindFirstChild("Stats") and entry.Stats:FindFirstChild("Team") then
                            teamText = entry.Stats.Team.Text
                        end
                    end)
                    if teamText and workspace.Tycoon and workspace.Tycoon.Tycoons:FindFirstChild(teamText) then
                        local buttonFolder = workspace.Tycoon.Tycoons[teamText].UnpurchasedButtons
                        for _, group in ipairs(buttonFolder:GetChildren()) do
                            if hrp then
                                -- ignore specific item by name
                                if group.Name == "FAMAS Group Gun" then
                                    continue
                                end
                                -- check neon color inside the button model
                                local neon = group:FindFirstChild("Neon")
                                if neon and neon:IsA("BasePart") then
                                    local c = neon.Color
                                    if not (c.r == 0 and c.g == 1 and c.b == 0) then
                                        -- check for yellow rebirth item
                                        if c.r == 1 and c.g == 1 and c.b == 0 then
                                            -- try read price
                                            local priceText
                                            pcall(function()
                                                priceText = group.Neon.UI.BillboardGui.Frame.Price.Text
                                            end)
                                            if priceText then
                                                local num = tonumber(priceText:match("%d+")) or 0
                                                local myRebirths = 0
                                                pcall(function()
                                                    local stats = LocalPlayer:FindFirstChild("leaderstats")
                                                    if stats and stats:FindFirstChild("Rebirths") then
                                                        myRebirths = tonumber(stats.Rebirths.Value) or 0
                                                    else
                                                        local entry = LocalPlayer.PlayerGui.UI.Container.HUD.PlayerList.PlayerList.ScrollingFrame:FindFirstChild(LocalPlayer.Name)
                                                        if entry and entry:FindFirstChild("Stats") and entry.Stats:FindFirstChild("Rebirths") then
                                                            myRebirths = tonumber(entry.Stats.Rebirths.Text:match("%d+")) or 0
                                                        end
                                                    end
                                                end)
                                                if num > myRebirths then
                                                    continue
                                                end
                                            end
                                        -- blue cash purchase item
                                        elseif math.abs(c.r - (4/255)) < 0.001 and math.abs(c.g - (175/255)) < 0.001 and math.abs(c.b - (235/255)) < 0.001 then
                                            local priceText
                                            pcall(function()
                                                priceText = group.Neon.UI.BillboardGui.Frame.Price.Text
                                            end)
                                            if priceText then
                                                local num = tonumber(priceText:match("%d+")) or 0
                                                local myCash = 0
                                                pcall(function()
                                                    local stats = LocalPlayer:FindFirstChild("leaderstats")
                                                    if stats and stats:FindFirstChild("Cash") then
                                                        myCash = tonumber(stats.Cash.Value) or 0
                                                    end
                                                end)
                                                if num > myCash then
                                                    continue
                                                end
                                            end
                                        else
                                            continue
                                        end
                                    end
                                end
                                local targetPart = nil
                                if group:IsA("BasePart") then
                                    targetPart = group
                                else
                                    targetPart = group:FindFirstChild("Part")
                                end
                                if targetPart and targetPart:IsA("BasePart") then
                                    -- teleport to point just above the part
                                    local aboveCFrame = targetPart.CFrame + Vector3.new(0, targetPart.Size.Y/2 + 3, 0)
                                    hrp.CFrame = aboveCFrame
                                    -- small shake to trigger purchase
                                    for i = 1, 3 do
                                        hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-1,1),0,math.random(-1,1))
                                        task.wait(0.05)
                                    end
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- additional farming toggle for collecting gradient
local collectEnabled = false
FarmingGroup:AddToggle("AutoCollect", {
    Text = "Auto Collect",
    Default = false,
    Callback = function(val)
        collectEnabled = val
        if val then
            task.spawn(function()
                while collectEnabled do
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local teamText = nil
                    pcall(function()
                        local plName = LocalPlayer.Name
                        local entry = LocalPlayer.PlayerGui.UI.Container.HUD.PlayerList.PlayerList.ScrollingFrame:FindFirstChild(plName)
                        if entry and entry:FindFirstChild("Stats") and entry.Stats:FindFirstChild("Team") then
                            teamText = entry.Stats.Team.Text
                        end
                    end)
                    if teamText and workspace.Tycoon and workspace.Tycoon.Tycoons:FindFirstChild(teamText) then
                        local collector = workspace.Tycoon.Tycoons[teamText].Essentials.CollectorParts:FindFirstChild("Collector")
                        if collector and collector:IsA("BasePart") and hrp then
                            hrp.CFrame = collector.CFrame
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- auto rebirth toggle
local autoRebirthEnabled = false
FarmingGroup:AddToggle("AutoRebirth", {
    Text = "Auto Rebirth",
    Tooltip = "Automatically fires rebirth every 30s",
    Default = false,
    Callback = function(val)
        autoRebirthEnabled = val
        if val then
            task.spawn(function()
                while autoRebirthEnabled do
                    local teamText = nil
                    pcall(function()
                        local plName = LocalPlayer.Name
                        local entry = LocalPlayer.PlayerGui.UI.Container.HUD.PlayerList.PlayerList.ScrollingFrame:FindFirstChild(plName)
                        if entry and entry:FindFirstChild("Stats") and entry.Stats:FindFirstChild("Team") then
                            teamText = entry.Stats.Team.Text
                        end
                    end)
                    if teamText and workspace.Tycoon and workspace.Tycoon.Tycoons:FindFirstChild(teamText) then
                        -- always fire the rebirth remote first
                        pcall(function()
                            local evt = game:GetService("ReplicatedStorage").RebirthEVT
                            if evt then
                                evt:FireServer()
                            end
                        end)

                        -- check cash afterwards
                        local myCash = 0
                        pcall(function()
                            local stats = LocalPlayer:FindFirstChild("leaderstats")
                            if stats and stats:FindFirstChild("Cash") then
                                myCash = tonumber(stats.Cash.Value) or 0
                            end
                        end)
                        if myCash <= 0 then
                            -- teleport to diamond plate for 5 seconds and trigger prompt
                            pcall(function()
                                local ty = workspace.Tycoon.Tycoons[teamText]
                                local diamond = ty.PurchasedObjects["Oil 1"].DiamondPlate
                                if diamond and diamond:IsA("BasePart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = diamond.CFrame + Vector3.new(0, 5, 0)
                                end
                                local prompt = ty.PurchasedObjects["Oil 1"].CB1.DefaultExtractor
                                if prompt and prompt:IsA("ProximityPrompt") then
                                    pcall(function()
                                        prompt.HoldDuration = 0
                                    end)
                                    prompt:InputHoldBegin()
                                    prompt:InputHoldEnd()
                                end
                            end)
                            -- stay there for 5 seconds
                            task.wait(5)
                        end
                    end
                    task.wait(30)
                end
            end)
        end
    end
})

--============================================================
-- COMBAT TAB: Silent Aim
--============================================================
local SilentAimGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim", "crosshair")

local silentAimEnabled = false
local silentAimFOV = 100
local silentAimVisCheck = false
local bulletTPEnabled = false
local bulletManipEnabled = false
local bulletTPColor = Color3.fromRGB(255,255,255)
local bulletManipColor = Color3.fromRGB(255,255,255)
local _activeManipCount = 0  -- tracks concurrent steered bullets; capped to prevent lag
local infiniteAmmoEnabled = false
local noMaxDistEnabled = false
local alwaysAutoEnabled = false
local breakShieldsEnabled = false
local instantHitEnabled = false
local _ammoTable = nil       -- tbl_3_upvr reference (found via GC)
local _origNamecall = nil    -- stored hookmetamethod original
local _fastCastHooked = false

-- turret/vehicle helpers
local localTurretPart = nil
local humveeRoot = nil

local function updateLocalTurret()
    if not humveeRoot then
        local vs = workspace:FindFirstChild("Game Systems")
        vs = vs and vs:FindFirstChild("Vehicle Workspace")
        humveeRoot = vs and vs:FindFirstChild("Humvee")
    end
    if humveeRoot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local seat = LocalPlayer.Character.Humanoid.SeatPart
        if seat and seat:IsDescendantOf(humveeRoot) then
            local part = humveeRoot:FindFirstChild("Misc")
            part = part and part:FindFirstChild("Turrets")
            part = part and part:FindFirstChild("Humvee Weapons")
            part = part and part:FindFirstChild("Mid Turret")
            part = part and part:FindFirstChild("Up/Down")
            part = part and part:FindFirstChild("MovingParts")
            part = part and part:FindFirstChild("Collision")
            localTurretPart = part
        else
            localTurretPart = nil
        end
    else
        localTurretPart = nil
    end
end

RunService.RenderStepped:Connect(updateLocalTurret)
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    updateLocalTurret()
end)

-- simple drawing circle will represent FOV; radius managed below
fovCircle.Radius = silentAimFOV

local SAEnableToggle = SilentAimGroup:AddToggle("SilentAimEnable", {
    Text = "Enable",
    Default = false,
    Callback = function(val)
        silentAimEnabled = val
    end
}):AddKeyPicker("SilentAimKey", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Silent Aim",
})

local SADep = SilentAimGroup:AddDependencyBox()
SADep:SetupDependencies({{SAEnableToggle, true}})

SADep:AddSlider("SilentAimFOVSlider", {
    Text = "FOV Size",
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(val)
        silentAimFOV = val
        fovCircle.Radius = val
    end
})

SADep:AddToggle("SilentAimFOVCircle", {
    Text = "Show FOV Circle",
    Default = false,
    Callback = function(val)
        fovCircle.Visible = val and silentAimEnabled
    end
}):AddColorPicker("SAFovColor", {
    Default = Color3.new(1, 1, 1),
    Title = "FOV Color",
    Transparency = 0,
    Callback = function(val)
        fovCircle.Color = val
    end
})

SADep:AddSlider("SAFovThickness", {
    Text = "Circle Thickness",
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(val) fovCircle.Thickness = val end
})
SADep:AddSlider("SAFovSides", {
    Text = "Circle Sides",
    Default = 64,
    Min = 16,
    Max = 256,
    Rounding = 0,
    Callback = function(val) fovCircle.NumSides = val end
})
SADep:AddToggle("SAFovFilled", {
    Text = "Filled Circle",
    Default = false,
    Callback = function(val) fovCircle.Filled = val end
})

SADep:AddToggle("SilentAimVisCheck", {
    Text = "Visible Check",
    Default = false,
    Callback = function(val)
        silentAimVisCheck = val
    end
})

-- Bullet Features section
SilentAimGroup:AddDivider()

local BTPtoggle = SilentAimGroup:AddToggle("BulletTP", {
    Text = "Bullet TP",
    Tooltip = "Teleports bullet to target. RPGs are more stable.",
    Default = false,
    Callback = function(val)
        bulletTPEnabled = val
    end
})
BTPtoggle:AddColorPicker("BulletTPColor", {
    Title = "TP Trace",
    Default = Color3.fromRGB(255, 255, 255),
    Transparency = 0,
    Callback = function(c) bulletTPColor = c end
})

local BMtoggle = SilentAimGroup:AddToggle("BulletManip", {
    Text = "Bullet Manipulation",
    Tooltip = "Performance heavy — steers bullets around walls",
    Default = false,
    Callback = function(val)
        bulletManipEnabled = val
    end
})
BMtoggle:AddColorPicker("BulletManipColor", {
    Title = "Manip Trace",
    Default = Color3.fromRGB(255, 255, 255),
    Transparency = 0,
    Callback = function(c) bulletManipColor = c end
})
BMtoggle:AddKeyPicker("BulletManipKey", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Bullet Manip",
})


--============================================================
-- COMBAT TAB: Camera Aimbot
--============================================================
local AimbotGroup = Tabs.Combat:AddRightGroupbox("Camera Aimbot", "target")

local aimbotEnabled = false
local aimbotSmoothing = 5
local aimbotFOV = 200
local aimbotTargetBone = "Head"
local aimbotVisCheck = false
local aimbotShowFOV = false
local aimbotPrediction = false
local aimbotPredictionAmount = 0.1
local aimbotStickyTarget = false
local _aimbotLockedTarget = nil

-- Drawing FOV circle for camera aimbot
local aimbotFovCircle = Drawing.new("Circle")
aimbotFovCircle.Thickness = 1
aimbotFovCircle.NumSides = 64
aimbotFovCircle.Filled = false
aimbotFovCircle.Visible = false
aimbotFovCircle.Color = Color3.fromRGB(0, 255, 100)
aimbotFovCircle.Transparency = 0.6

local AimEnableToggle = AimbotGroup:AddToggle("AimbotEnable", {
    Text = "Enable",
    Default = false,
    Callback = function(val)
        aimbotEnabled = val
        if not val then _aimbotLockedTarget = nil end
    end
}):AddKeyPicker("AimbotKey", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Camera Aimbot",
})

local AimDep = AimbotGroup:AddDependencyBox()
AimDep:SetupDependencies({{AimEnableToggle, true}})

AimDep:AddDropdown("AimbotBone", {
    Text = "Target Bone",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(val) aimbotTargetBone = val end
})

AimDep:AddSlider("AimbotSmoothing", {
    Text = "Smoothing",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Tooltip = "Higher = smoother/slower tracking",
    Callback = function(val) aimbotSmoothing = val end
})

AimDep:AddSlider("AimbotFOV", {
    Text = "FOV",
    Default = 200,
    Min = 10,
    Max = 800,
    Rounding = 0,
    Callback = function(val)
        aimbotFOV = val
        aimbotFovCircle.Radius = val
    end
})

AimDep:AddToggle("AimbotVisCheck", {
    Text = "Visibility Check",
    Default = false,
    Callback = function(val) aimbotVisCheck = val end
})

AimDep:AddToggle("AimbotShowFOV", {
    Text = "Show FOV Circle",
    Default = false,
    Callback = function(val)
        aimbotShowFOV = val
        aimbotFovCircle.Visible = val and aimbotEnabled
    end
})

AimDep:AddToggle("AimbotStickyTarget", {
    Text = "Sticky Target",
    Default = false,
    Tooltip = "Lock onto one target until they die or leave FOV",
    Callback = function(val)
        aimbotStickyTarget = val
        if not val then _aimbotLockedTarget = nil end
    end
})

AimDep:AddDivider()

AimDep:AddToggle("AimbotPrediction", {
    Text = "Movement Prediction",
    Default = false,
    Callback = function(val) aimbotPrediction = val end
})

AimDep:AddSlider("AimbotPredictionAmount", {
    Text = "Prediction Factor",
    Default = 0.1,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Tooltip = "How far ahead to predict (seconds)",
    Callback = function(val) aimbotPredictionAmount = val end
})

-- Silent aim helper functions
local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrpCheck = char:FindFirstChild("HumanoidRootPart")
    return hum and hum.Health > 0 and hrpCheck
end

local function isVisible(targetPart)
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, cam}
    local result = Workspace:Raycast(origin, dir, params)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true -- nothing blocking = visible
end

local function getClosestPlayerToCursor()
    local cam = Workspace.CurrentCamera
    local mouse2d = UserInputService:GetMouseLocation()
    local closest = nil
    local closestDist = silentAimFOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not isAlive(plr) then continue end
        -- skip teammates (same team)
        if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end

        local char = plr.Character
        local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        if silentAimVisCheck and not isVisible(targetPart) then continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse2d).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = targetPart
        end
    end
    return closest
end

-- Find nearest enemy base shield for Break Base Shields feature
local function getEnemyShieldTarget()
    local myTeam = nil
    pcall(function()
        local entry = LocalPlayer.PlayerGui.UI.Container.HUD.PlayerList.PlayerList.ScrollingFrame:FindFirstChild(LocalPlayer.Name)
        if entry and entry:FindFirstChild("Stats") and entry.Stats:FindFirstChild("Team") then
            myTeam = entry.Stats.Team.Text
        end
    end)
    if not myTeam then return nil end

    local tycoons = workspace:FindFirstChild("Tycoon") and workspace.Tycoon:FindFirstChild("Tycoons")
    if not tycoons then return nil end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, closestDist = nil, math.huge
    for _, tycoon in ipairs(tycoons:GetChildren()) do
        if tycoon.Name ~= myTeam then
            local shield = nil
            pcall(function()
                shield = tycoon.PurchasedObjects["Base Shield"].Shield
            end)
            if shield and shield:IsA("BasePart") then
                local dist = (shield.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = shield
                end
            end
        end
    end
    return closest
end

--============================================================
-- VISUALS: Variables & helpers (declared before hook)
--============================================================
local vmChamsEnabled = false
local vmChamsFillColor = Color3.fromRGB(75, 0, 130)
local vmChamsOutlineColor = Color3.fromRGB(255, 255, 255)
local vmChamsFillTransparency = 0.5
local vmChamsOutlineTransparency = 0
local vmChamsHighlight = nil

local vmOffsetX = 0
local vmOffsetY = 0
local vmOffsetZ = 0

local tracerEnabled = false
local tracerStartColor = Color3.fromRGB(255, 50, 50)
local tracerEndColor = Color3.fromRGB(255, 50, 50)
local tracerWidth = 0.05
local tracerFadeTime = 0.3

-- 3D beam-based tracer (renders in world space, visible from any angle)
local function drawTracer(origin, endpoint, startC, endC)
    if not tracerEnabled then return end

    local att0 = Instance.new("Attachment")
    att0.WorldPosition = origin
    att0.Parent = Workspace.Terrain

    local att1 = Instance.new("Attachment")
    att1.WorldPosition = endpoint
    att1.Parent = Workspace.Terrain

    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    local sc = startC or tracerStartColor
    local ec = endC or tracerEndColor
    beam.Color = ColorSequence.new(sc, ec)
    beam.Width0 = tracerWidth
    beam.Width1 = tracerWidth
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = att0

    -- Always fade
    local startTick = tick()
    local fadeConn
    fadeConn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTick
        local alpha = math.clamp(elapsed / math.max(tracerFadeTime, 0.01), 0, 1)
        pcall(function()
            beam.Transparency = NumberSequence.new(alpha)
        end)
        if alpha >= 1 then
            fadeConn:Disconnect()
            pcall(function() beam:Destroy() end)
            pcall(function() att0:Destroy() end)
            pcall(function() att1:Destroy() end)
        end
    end)
end

--============================================================
-- REMOTES: Cache for reference (tracers, debug)
--============================================================
local BFS = ReplicatedStorage:WaitForChild("BulletFireSystem")
local _FireGunRemote = BFS:WaitForChild("FireGun")
local _BulletHitRemote = BFS:WaitForChild("BulletHit")
local _FireTurretRemote = BFS:WaitForChild("FireTurret")

-- Pre-computed target reference (updated every frame in RenderStepped)
local _silentAimTarget = nil

RunService.RenderStepped:Connect(function()
    -- update simple drawing circle each frame
    if Toggles.SilentAimFOVCircle and Toggles.SilentAimFOVCircle.Value and silentAimEnabled then
        fovCircle.Visible = true
        fovCircle.Position = UserInputService:GetMouseLocation()
        if _silentAimTarget then
            -- pulsing accent ring when a target is locked (gamesense-style)
            local pulse = math.sin(tick() * 8) * 2.5
            fovCircle.Radius    = math.max(1, silentAimFOV + pulse)
            fovCircle.Thickness = 1.5
            fovCircle.Color     = Color3.fromRGB(255, 70, 70)
        else
            fovCircle.Radius    = silentAimFOV
            fovCircle.Thickness = 1
            fovCircle.Color     = Color3.new(1, 1, 1)
        end
    else
        fovCircle.Visible = false
    end

    -- bullet TP visualization: draw line from camera to target head when enabled
    if bulletTPEnabled and _silentAimTarget then
        local head = _silentAimTarget.Parent and _silentAimTarget.Parent:FindFirstChild("Head") or _silentAimTarget
        if head then
            local camPos = Camera.CFrame.Position
            local headPos = head.Position
            bulletTPLine.Visible = true
            bulletTPLine.From = Vector2.new(camPos.X, camPos.Y) -- we cannot set world positions in Drawing line; better use 3D beam? but keep visible fade
            -- Instead convert to screen coordinates
            local sp = Camera:WorldToViewportPoint(camPos)
            local hp = Camera:WorldToViewportPoint(headPos)
            bulletTPLine.From = Vector2.new(sp.X, sp.Y)
            bulletTPLine.To = Vector2.new(hp.X, hp.Y)
            bulletTPLine.Color = bulletTPColor
        else
            bulletTPLine.Visible = false
        end
    else
        bulletTPLine.Visible = false
    end

    -- find the closest valid target each frame (uses Camera APIs which are NOT
    -- safe inside __namecall, so we must do this here)
    if silentAimEnabled then
        _silentAimTarget = getClosestPlayerToCursor()  -- returns Head or HRP Part
        -- Fall back to enemy shield if no player target and Break Base Shields is on
        if not _silentAimTarget and breakShieldsEnabled then
            _silentAimTarget = getEnemyShieldTarget()
        end
    else
        _silentAimTarget = nil
    end

    -- Camera Aimbot: smoothly rotate camera toward target
    if aimbotEnabled then
        local cam = Workspace.CurrentCamera
        local mouse2d = UserInputService:GetMouseLocation()

        -- Update aimbot FOV circle
        if aimbotShowFOV then
            aimbotFovCircle.Visible = true
            aimbotFovCircle.Position = mouse2d
            aimbotFovCircle.Radius = aimbotFOV
        else
            aimbotFovCircle.Visible = false
        end

        -- Sticky target: reuse locked target if still valid
        local bestTarget = nil
        if aimbotStickyTarget and _aimbotLockedTarget then
            local part = _aimbotLockedTarget
            if part and part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
                local hum = part.Parent:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local sp, onScr = cam:WorldToViewportPoint(part.Position)
                    local d = (Vector2.new(sp.X, sp.Y) - mouse2d).Magnitude
                    if onScr and d < aimbotFOV * 1.5 then
                        bestTarget = part
                    end
                end
            end
            if not bestTarget then _aimbotLockedTarget = nil end
        end

        -- Find new target if needed
        if not bestTarget then
            local bestDist = aimbotFOV
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                if not isAlive(plr) then continue end
                if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
                local char = plr.Character
                local bone = char:FindFirstChild(aimbotTargetBone) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if not bone then continue end
                if aimbotVisCheck and not isVisible(bone) then continue end
                local screenPos, onScreen = cam:WorldToViewportPoint(bone.Position)
                if not onScreen then continue end
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse2d).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestTarget = bone
                end
            end
            if bestTarget and aimbotStickyTarget then
                _aimbotLockedTarget = bestTarget
            end
        end

        if bestTarget then
            local aimPos = bestTarget.Position
            -- Movement prediction: offset aim by velocity * prediction factor
            if aimbotPrediction and bestTarget.Parent then
                local hrp = bestTarget.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity or hrp.Velocity
                    if vel then
                        aimPos = aimPos + vel * aimbotPredictionAmount
                    end
                end
            end
            local targetCF = CFrame.lookAt(cam.CFrame.Position, aimPos)
            cam.CFrame = cam.CFrame:Lerp(targetCF, 1 / math.max(aimbotSmoothing, 1))
        end
    else
        aimbotFovCircle.Visible = false
        _aimbotLockedTarget = nil
    end

end)

--============================================================
-- TURRET SILENT AIM: Hook __namecall
--============================================================
-- Only intercepts FireTurret:FireServer for turret silent aim.
-- ACS gun bullet manipulation is handled by FastCast.Fire hook below.

local function getClosestPlayerWorld(fromPos, maxDist)
    local closest, closestDist = nil, maxDist or math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not isAlive(plr) then continue end
        if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
        local char = plr.Character
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not head then continue end
        local dist = (head.Position - fromPos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = head
        end
    end
    return closest
end

_origNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method ~= "FireServer" then
        return _origNamecall(self, ...)
    end

    -- block the built-in AFK remote
    if self and self.Name == "SendAFK" then
        return
    end

    -- Attempt secondary bulletTP by moving the local gun into the head
    -- and also rewrite remote arguments so the server packet starts/ends at the
    -- target's head.  This serves as a backup when the CastRay hook alone fails,
    -- which helps with faster or non-RPG weapons.
    if self == _FireGunRemote and bulletTPEnabled and _silentAimTarget then
        local args = {...}

        -- visual backup: move the local tool over the head
        pcall(function()
            local tgt = _silentAimTarget
            if tgt and tgt.Parent then
                local head = tgt.Parent:FindFirstChild("Head") or tgt
                if head then
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool and tool.PrimaryPart then
                            tool:SetPrimaryPartCFrame(head.CFrame)
                        elseif tool then
                            for _, part in ipairs(tool:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CFrame = head.CFrame
                                end
                            end
                        end
                    end
                end
            end
        end)

        -- only rewrite server args when they look like the usual (direction +
        -- muzzle Pos) pattern to avoid corrupting non-Vector3 payloads that the
        -- game might sometimes send (some weapons use other formats).
        if typeof(args[1]) == "Vector3" and typeof(args[4]) == "Vector3" then
            if _silentAimTarget and _silentAimTarget.Parent then
                local head = _silentAimTarget.Parent:FindFirstChild("Head") or _silentAimTarget
                if head then
                    local headPos = head.Position
                    local origin = headPos + Vector3.new(0, 0.1, 0)
                    local dir = (headPos - origin).Unit

                    args[1] = dir
                    -- replace subsequent Vector3 entries (muzzlePos, stance,
                    -- etc) with the origin
                    for i = 2, #args do
                        if typeof(args[i]) == "Vector3" then
                            args[i] = origin
                        end
                    end

                    -- noMaxDist is now handled solely by FastCast.MaxDistance
                end
            end
        end

        return _origNamecall(self, unpack(args))
    end




    -- ── VEHICLE TURRET PACKET MODIFIERS ──
    if self == _FireTurretRemote then
        local args = {...}
        -- apply silent‑aim only to the first argument (muzzle direction)
        if silentAimEnabled and _silentAimTarget and typeof(args[1]) == "Vector3" then
            local target = getClosestPlayerWorld(args[1], silentAimFOV)
            if target then
                args[1] = (target.Position - args[1]).Unit
            end
        end
        -- distance limit handled by FastCast; leave args alone
        return _origNamecall(self, unpack(args))
    end

    -- ── SERVER BULLET RANGE EXTENSION ──
    if self == _FireGunRemote and noMaxDistEnabled then
        local args = {...}
        -- args[1]=direction, args[4]=muzzlePos
        if typeof(args[1]) == "Vector3" and typeof(args[4]) == "Vector3" then
            -- push origin backwards to gain extra range
            args[4] = args[4] - args[1] * 800
        end
        return _origNamecall(self, unpack(args))
    end

    return _origNamecall(self, ...)
end))

--============================================================
-- FASTCAST HOOK: Projectile TP / Manipulation / MaxDist
--============================================================
-- ACS fires visual bullets via FastCast.Fire(caster, origin, direction, speed, behavior).
-- We replace FC.Fire on the module table — every caster:Fire() goes through this.
--
--   Projectile TP:   (now handled in namecall remote hook) teleports
--                    the server packet directly to the target's head.
--   Bullet Manip:    computes waypoints around walls via iterative raycasting,
--                    fires toward the first waypoint, then steers the ActiveCast
--                    per-frame through each waypoint with sharp turns.
--   Max Distance:    moved to Modifications tab (noMaxDistEnabled).

-- Builds the shared RaycastParams for pathfinding (excludes our character,
-- the target character, and ACS_WorkSpace bullet cosmetics).
local function buildNavParams(targetPart)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = {}
    if LocalPlayer.Character then
        filterList[#filterList + 1] = LocalPlayer.Character
    end
    -- Exclude target character so their hitbox isn't treated as a wall
    if targetPart then
        local tChar = targetPart:FindFirstAncestorOfClass("Model")
        if tChar then filterList[#filterList + 1] = tChar end
    end
    local gameSystems = Workspace:FindFirstChild("Game Systems")
    if gameSystems then
        local acsWS = gameSystems:FindFirstChild("ACS_WorkSpace")
        if acsWS then filterList[#filterList + 1] = acsWS end
    end
    params.FilterDescendantsInstances = filterList
    return params
end

-- Helper: returns true if a ray from `a` to `b` is unobstructed.
local function canReach(a, b, params)
    local dir = b - a
    local ray = Workspace:Raycast(a, dir, params)
    return not ray or (ray.Position - a).Magnitude >= dir.Magnitude - 1
end

-- Computes waypoints from `origin` to `targetPos` that navigate around walls.
-- Two-strategy search per leg:
--   1) Wall-surface scan: slides along the hit wall to find openings (doors, windows).
--   2) Wide-angle probe from current position in 50+ directions × multiple distances.
-- Unlimited sharp turns (up to MAX_LEGS).  No sliders.
local function computeWallNavPath(origin, targetPos, targetPart)
    local params = buildNavParams(targetPart)

    -- Quick direct-LOS check
    if canReach(origin, targetPos, params) then
        return {targetPos}
    end

    local waypoints = {}
    local current   = origin
    local MAX_LEGS  = 25
    local GRID      = 4   -- studs per grid cell for visited tracking

    local visited = {}
    local function markVisited(pos)
        local k = math.floor(pos.X / GRID)
            .. "," .. math.floor(pos.Y / GRID)
            .. "," .. math.floor(pos.Z / GRID)
        if visited[k] then return false end
        visited[k] = true
        return true
    end
    markVisited(origin)

    -- Evaluate a candidate bypass point; updates best* upvalues via closure.
    local bestBypass, bestScore, bestCanSee

    local function evaluate(candidate)
        -- Must be reachable from current
        if not canReach(current, candidate, params) then return end
        -- Target visible from here?
        local see = canReach(candidate, targetPos, params)
        local score = (targetPos - candidate).Magnitude
        local dominated = false
        if see and not bestCanSee then          -- seeing target wins everything
        elseif see == bestCanSee and score < bestScore then
        else dominated = true end
        if not dominated then
            bestBypass = candidate
            bestScore  = score
            bestCanSee = see
        end
    end

    for _leg = 1, MAX_LEGS do
        local toTarget = targetPos - current
        if toTarget.Magnitude < 2 then
            waypoints[#waypoints + 1] = targetPos
            break
        end

        -- Direct LOS from current leg?
        if canReach(current, targetPos, params) then
            waypoints[#waypoints + 1] = targetPos
            break
        end

        -- Blocked — get wall info
        local ray = Workspace:Raycast(current, toTarget, params)
        if not ray then
            waypoints[#waypoints + 1] = targetPos
            break
        end

        local hitPos    = ray.Position
        local hitNormal = ray.Normal
        local travelDir = toTarget.Unit

        -- ── STRATEGY 1: Wall-surface scan (finds doors / windows) ──
        -- Compute two orthogonal directions along the wall surface.
        local wallRight = hitNormal:Cross(Vector3.new(0, 1, 0))
        if wallRight.Magnitude < 0.01 then
            wallRight = hitNormal:Cross(Vector3.new(1, 0, 0))
        end
        wallRight = wallRight.Unit
        local wallUp = hitNormal:Cross(wallRight).Unit

        local wallDirs = {
            wallRight, -wallRight, wallUp, -wallUp,
            (wallRight + wallUp).Unit, (-wallRight + wallUp).Unit,
            (wallRight - wallUp).Unit, (-wallRight - wallUp).Unit,
        }

        bestBypass = nil; bestScore = math.huge; bestCanSee = false

        for _, wDir in ipairs(wallDirs) do
            -- Slide along the wall in 2-stud increments looking for an opening
            for scanDist = 2, 50, 2 do
                -- Point on our side of the wall, offset along its surface
                local probe = hitPos + wDir * scanDist + hitNormal * 2
                -- Check if the wall has ended / there's an opening here
                local passRay = Workspace:Raycast(probe, travelDir * 30, params)
                local opening = not passRay
                    or (passRay.Position - probe).Magnitude > 8
                if opening then
                    evaluate(probe)
                    -- Also try a position slightly past the opening
                    local through = probe + travelDir * 5
                    evaluate(through)
                    break  -- found opening in this scan direction
                end
            end
        end

        -- ── STRATEGY 2: Wide-angle probing from current position ──
        -- 26 uniform (cardinal + diagonal) + target-biased cone directions
        local probeDirs = {}
        for x = -1, 1 do
            for y = -1, 1 do
                for z = -1, 1 do
                    if x ~= 0 or y ~= 0 or z ~= 0 then
                        probeDirs[#probeDirs + 1] = Vector3.new(x, y, z).Unit
                    end
                end
            end
        end

        -- Target-biased cone (rotated off travel direction)
        local cRight = travelDir:Cross(Vector3.new(0, 1, 0))
        if cRight.Magnitude < 0.01 then
            cRight = travelDir:Cross(Vector3.new(1, 0, 0))
        end
        cRight = cRight.Unit
        local cUp = cRight:Cross(travelDir).Unit

        for _, angle in ipairs({15, 30, 50, 70, 90}) do
            local rad = math.rad(angle)
            local cosA, sinA = math.cos(rad), math.sin(rad)
            for i = 0, 7 do
                local az = i * math.pi / 4
                local perpDir = cRight * math.cos(az) + cUp * math.sin(az)
                probeDirs[#probeDirs + 1] = (travelDir * cosA + perpDir * sinA).Unit
            end
        end

        for _, dir in ipairs(probeDirs) do
            for _, dist in ipairs({6, 12, 22, 38, 60}) do
                local candidate = current + dir * dist
                if markVisited(candidate) then
                    evaluate(candidate)
                end
            end
        end

        -- Commit best bypass
        if bestBypass then
            waypoints[#waypoints + 1] = bestBypass
            markVisited(bestBypass)
            current = bestBypass
            if bestCanSee then
                waypoints[#waypoints + 1] = targetPos
                break
            end
        else
            -- No path found; aim directly
            waypoints[#waypoints + 1] = targetPos
            break
        end
    end

    -- Guarantee target is the final waypoint
    if #waypoints == 0 or (waypoints[#waypoints] - targetPos).Magnitude > 1 then
        waypoints[#waypoints + 1] = targetPos
    end

    return waypoints
end

-- Steers an ActiveCast through waypoints with sharp direction changes.
-- Uses FastCast's :SetVelocity() / :SetAcceleration() per-frame.
local function steerActiveCast(activeCast, waypoints, speed, targetRef)
    -- only run manipulation when a valid target reference exists
    if not activeCast or not targetRef or not targetRef.Parent or #waypoints == 0 then return end
    -- cap concurrent steerers to avoid excessive heartbeat callbacks
    local MAX_CONCURRENT_MANIP = 6
    if _activeManipCount >= MAX_CONCURRENT_MANIP then return end
    _activeManipCount += 1

    local wpIndex   = 1
    local threshold = math.clamp(speed * 0.04, 5, 30)
    local currentWaypoints = waypoints
    local lastTargetPos = targetRef.Position

    local conn
    conn = RunService.Heartbeat:Connect(function()
        local ok, pos = pcall(function() return activeCast:GetPosition() end)
        if not ok or not pos then
            if conn.Connected then conn:Disconnect() end
            _activeManipCount -= 1
            return
        end

        if targetRef and targetRef.Parent then
            local targetPos = targetRef.Position

            -- if target moved significantly, recalc fresh path
            if (targetPos - lastTargetPos).Magnitude > 2 then
                local newPath = computeWallNavPath(pos, targetPos, targetRef)
                if newPath and #newPath > 0 then
                    currentWaypoints = newPath
                    wpIndex = 1
                end
                lastTargetPos = targetPos
            end

            -- if we've reached a waypoint but it's no longer near the target,
            -- recompute to chase the moving entity
            if wpIndex and currentWaypoints[wpIndex] then
                local wpCheck = currentWaypoints[wpIndex]
                if (pos - wpCheck).Magnitude < threshold and (wpCheck - targetPos).Magnitude > 5 then
                    local newPath = computeWallNavPath(pos, targetPos, targetRef)
                    if newPath and #newPath > 0 then
                        currentWaypoints = newPath
                        wpIndex = 1
                    else
                        currentWaypoints[#currentWaypoints] = targetPos
                    end
                end
            end
        end

        local wp = currentWaypoints[wpIndex]
        if not wp then
            if conn.Connected then conn:Disconnect() end
            _activeManipCount -= 1
            return
        end

        local toWP = wp - pos
        local dist = toWP.Magnitude

        while dist < threshold do
            wpIndex = wpIndex + 1
            wp = currentWaypoints[wpIndex]
            if not wp then
                if conn.Connected then conn:Disconnect() end
                _activeManipCount -= 1
                return
            end
            toWP = wp - pos
            dist = toWP.Magnitude
        end

        pcall(function()
            activeCast:SetVelocity(toWP.Unit * speed)
            activeCast:SetAcceleration(Vector3.new(0, 0, 0))
        end)
    end)

    task.delay(10, function()
        if conn and conn.Connected then
            conn:Disconnect()
            _activeManipCount -= 1
        end
    end)
end

-- Draws tracers along a waypoint path (origin → wp1 → wp2 → ... → target)
local function drawManipTracer(origin, waypoints)
    if not tracerEnabled then return end
    local prev = origin
    for _, wp in ipairs(waypoints) do
        task.spawn(drawTracer, prev, wp, bulletManipColor or tracerStartColor, bulletManipColor or tracerEndColor)
        prev = wp
    end
end

local function hookFastCast()
    if _fastCastHooked then return end
    local ok, FC = pcall(function()
        return require(ReplicatedStorage:WaitForChild("BulletFireSystem", 10):WaitForChild("FastCastRedux", 10))
    end)
    if not ok or not FC or not FC.Fire then
        Library:Notify("FastCast hook: module not found", 4)
        return
    end

    local origFire = FC.Fire
    _fastCastHooked = true

    FC.Fire = function(caster, origin, direction, speed, behavior)
        -- Always remove max distance when enabled (set very large value)
        if noMaxDistEnabled and behavior then
            behavior.MaxDistance = 1e7
        end

        -- Bullet TP: shift visual bullet origin to just above head and aim at it
        if bulletTPEnabled and _silentAimTarget and _silentAimTarget.Parent then
            local head = _silentAimTarget.Parent:FindFirstChild("Head") or _silentAimTarget
            if head then
                local headPos = head.Position
                local originPos = headPos + Vector3.new(0, 0.1, 0)
                origin = originPos
                -- align direction toward head for better visuals
                direction = (headPos - originPos).Unit
            end
        end

        -- Vehicle turret tracer origin override
        if localTurretPart then
            -- if origin is very near the turret part assume it's a vehicle shot
            if (origin - localTurretPart.Position).Magnitude < 5 then
                origin = localTurretPart.Position
            end
        end

        local target = _silentAimTarget
        local doManip = silentAimEnabled and target and target.Parent
        local _manipWaypoints = nil
        local _manipSpeed     = nil
        local _manipOrigin    = nil
        -- allow piercing everything except the target so the visual cast can't hit walls
        if doManip and behavior then
            behavior.CanPierceFunction = function(cast, rayResult, segVelocity, cosmeticBullet)
                local hitPart = rayResult and rayResult.Instance
                if not hitPart then return true end
                if target and target.Parent then
                    if hitPart == target or hitPart:IsDescendantOf(target.Parent) then
                        -- Spawn hitmarker at impact point for local feedback
                        if hitMarkerEnabled and rayResult.Position then
                            task.defer(spawnHitMarker, rayResult.Position)
                        end
                        if hitSoundEnabled then
                            task.defer(function() pcall(function() hitSound:Play() end) end)
                        end
                        return false
                    end
                end
                return true
            end
        end

        if doManip then
            -- Remove max distance when any bullet feature is active too
            if behavior and (bulletTPEnabled or bulletManipEnabled) then
                behavior.MaxDistance = 999999
            end



            -- ── Bullet Manipulation: wall-navigating pathfinding ──
            -- Computes waypoints around obstacles, fires toward the first,
            -- then steers the ActiveCast per-frame through each waypoint.
            if bulletManipEnabled then
                _manipWaypoints = computeWallNavPath(origin, target.Position, target)
                if _manipWaypoints and #_manipWaypoints > 0 then
                    -- Remove gravity so turns are clean straight-line segments
                    if behavior then
                        behavior.Acceleration = Vector3.new(0, 0, 0)
                    end
                    direction = (_manipWaypoints[1] - origin).Unit
                end
                -- respect instant hit by using enormous speed for steering
                _manipSpeed = instantHitEnabled and 1e6 or (type(speed) == "number" and speed or 500)
                _manipOrigin = origin
            end
        end

        local activeCast = origFire(caster, origin, direction, speed, behavior)

        -- Instant Hit: override bullet speed to extreme value
        if instantHitEnabled then
            pcall(function()
                activeCast:SetVelocity(direction.Unit * 999999)
                activeCast:SetAcceleration(Vector3.new(0, 0, 0))
            end)
        end



        -- Start per-frame steering through waypoints (sharp turns)
        if _manipWaypoints and #_manipWaypoints > 0 then
            steerActiveCast(activeCast, _manipWaypoints, _manipSpeed, target)
            -- Draw tracer along the planned trajectory
            drawManipTracer(_manipOrigin or origin, _manipWaypoints)
        end

        -- Show tracers for normal bullets (always on)
        if tracerEnabled and not doManip then
            local spd = type(speed) == "number" and speed or 500
            local endPoint = origin + direction.Unit * math.min(spd, 500)
            task.spawn(drawTracer, origin, endPoint)
        end

        return activeCast
    end

    Library:Notify("FastCast hooked!", 3)
end

task.spawn(hookFastCast)

--============================================================
-- SILENT AIM: Hook ACS internal GetDir via GC
--============================================================
-- Why __namecall doesn't work:
--   Luau compiler can emit CALL bytecode instead of NAMECALL for
--   :FireServer() calls. When this happens, __namecall never fires.
--
-- Solution: Hook the ACS script's INTERNAL GetDir function directly.
--   GetDir returns the bullet direction vector. This direction flows into
--   CastRay → FireGun:FireServer AND module_4.FireGun (visual).
--   Hooking GetDir redirects EVERYTHING — server + visuals — naturally.
--
-- How we find it:
--   Scan getgc() for a function named "GetDir" with upvalue[8] = an
--   Instance named "Stances" (unique to this function in ACS).

local _aimDebugCount = 0
local _hookStatus = "searching..."
local _origGetDir = nil
local _origCastRay = nil
local _getDir_var31_index = 1    -- upvalue index for var31_upvw (gun viewmodel)
local _heartbeatScanConn = nil   -- current GC scan connection (replaced on respawn)
local _hookedFunctions = {}      -- track func refs we've already hooked so stale closures are skipped

-- Scan GC for ACS functions (new-character-aware)
local function scanGCForACS()
    local currentChar = LocalPlayer.Character
    for _, v in getgc(true) do
        if type(v) == "function" and not _hookedFunctions[v] then
            local ok, info = pcall(getinfo, v)
            if ok and info then

                -- GetDir: upvalue[8] = Instance "Stances", upvalue[2] = Character
                if not _origGetDir then
                    local ok2, stances = pcall(getupvalue, v, 8)
                    if ok2 and typeof(stances) == "Instance" and stances.Name == "Stances" then
                        local ok3, charRef = pcall(getupvalue, v, 2)
                        if ok3 and typeof(charRef) == "Instance" then
                            -- must belong to the CURRENT character (or accept if char is nil yet)
                            if not currentChar or charRef == currentChar then
                                _origGetDir = v
                            end
                        end
                    end
                end

                -- CastRay: upvalue[7] = Instance "FireGun", upvalue[1] = Character
                if not _origCastRay then
                    local ok2, remote = pcall(getupvalue, v, 7)
                    if ok2 and typeof(remote) == "Instance" and remote.Name == "FireGun" then
                        local ok3, charRef = pcall(getupvalue, v, 1)
                        if ok3 and typeof(charRef) == "Instance" then
                            if not currentChar or charRef == currentChar then
                                _origCastRay = v
                            end
                        end
                    end
                end

                -- fireGun: upvalue[22] = GetDir function, upvalue[8] = tbl_3_upvr (ammo table)
                -- We find this to extract the ammo table for infinite ammo
                if not _ammoTable and _origGetDir then
                    local ok2, uv22 = pcall(getupvalue, v, 22)
                    if ok2 and uv22 == _origGetDir then
                        local ok3, ammoTbl = pcall(getupvalue, v, 8)
                        if ok3 and type(ammoTbl) == "table" then
                            _ammoTable = ammoTbl
                        end
                    end
                end
            end
        end
        if _origGetDir and _origCastRay and _ammoTable then break end
    end
end

-- find & hook ACS camera update (for third-person support)
local _origACSCamFunc = nil
local function scanGCForACSCam()
    if _origACSCamFunc then return end
    for _, v in ipairs(getgc(true)) do
        if type(v) == "function" and not _hookedFunctions[v] then
            local ok, info = pcall(getinfo, v, "u")
            if ok and info and info.nups and info.nups > 0 then
                for i = 1, info.nups do
                    local ok2, upv = pcall(getupvalue, v, i)
                    if ok2 and typeof(upv) == "Instance" and upv:IsA("Camera") then
                        _origACSCamFunc = v
                        break
                    end
                end
            end
        end
        if _origACSCamFunc then break end
    end
    if _origACSCamFunc then
        local old = _origACSCamFunc
        local inCamHook = false
        _origACSCamFunc = hookfunction(old, newcclosure(function(...)
            if inCamHook then
                return old(...)
            end
            inCamHook = true
            -- third-person support removed; camera left unchanged

            local res = old(...)
            inCamHook = false
            return res
        end))
        Library:Notify("ACS camera handler hooked for third-person", 3)
    end
end

-- Wire ChildAdded on a character so any tool equip triggers a GC scan
local function watchCharForTools(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.5)   -- wait for ACS to finish initializing
            pcall(scanGCForACS)
        end
    end)
    -- also scan for tools that already exist on the character
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            task.spawn(function()
                task.wait(0.5)
                pcall(scanGCForACS)
            end)
        end
    end
end

-- Core hook setup — builds GetDir + CastRay hooks
local function setupHooks()
    if not _origGetDir then return end

    -- Mark functions so future GC scans skip them
    _hookedFunctions[_origGetDir] = true
    if _origCastRay then _hookedFunctions[_origCastRay] = true end

    -- Hook GetDir — returns bullet direction vector
    local oldGetDir
    do
        local inHook = false
        oldGetDir = hookfunction(_origGetDir, newcclosure(function(spread)
            if inHook then
                return oldGetDir(spread)
            end
            inHook = true
            if silentAimEnabled and _silentAimTarget then
                -- compute muzzle position
                local smokePos = nil
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, obj in ipairs(char:GetChildren()) do
                            if obj:IsA("Model") and obj.Name:sub(1,1) == "S" then
                                local attach = obj:FindFirstChild("MuzzleAttach", true)
                                if attach and attach:IsA("BasePart") then
                                    smokePos = attach.Position
                                    break
                                end
                            end
                        end
                    end
                end)
                if not smokePos then
                    local ok, var31 = pcall(getupvalue, _origGetDir, _getDir_var31_index)
                    if ok and var31 and typeof(var31) == "Instance" then
                        local smokePart = var31:FindFirstChild("SmokePart")
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if smokePart and hrp then
                            smokePos = (smokePart.CFrame * CFrame.new(0, 0,
                                smokePart.CFrame:ToObjectSpace(hrp.CFrame).Z + 0.5)).Position
                        end
                    end
                end
                if not smokePos then
                    smokePos = Camera.CFrame.Position
                end

                local hitPos = _silentAimTarget.Position
                local dir = (hitPos - smokePos).Unit

                _aimDebugCount += 1

                if tracerEnabled then
                    local sC = bulletTPEnabled and bulletTPColor or tracerStartColor
                    local eC = bulletTPEnabled and bulletTPColor or tracerEndColor
                    task.spawn(drawTracer, smokePos, hitPos, sC, eC)
                end

                inHook = false
                return dir
            end

            local ret = oldGetDir(spread)
            inHook = false
            return ret
        end))
    end

    _hookStatus = "GetDir hooked"

    -- ── CastRay hook: Direction override for visual + server ──
    -- CastRay(arg1 = direction) calls BOTH:
    --   module_4.FireGun(player, arg1, tool, var31, muzzlePos)  ← visual (FastCast)
    --   FireGun:FireServer(arg1, tool, serverGun, muzzlePos, stance) ← server
    --
    -- Overriding arg1 here redirects BOTH the visual bullet and the server-side
    -- fire packet toward the target. The FastCast.Fire hook (above) then handles
    -- origin/speed/maxDist modifications when the visual bullet is created.
    if _origCastRay then
        local oldCastRay
        do
            local inHook2 = false
            oldCastRay = hookfunction(_origCastRay, newcclosure(function(arg1, ...)
                local rest = {...}
                if inHook2 then
                    return oldCastRay(arg1, unpack(rest))
                end
                inHook2 = true
                if bulletTPEnabled and _silentAimTarget then
                    -- bullet TP: behave like silent aim but origin just above the head
                    local head = _silentAimTarget.Parent and _silentAimTarget.Parent:FindFirstChild("Head") or _silentAimTarget
                    local newDir
                    if head then
                        local headPos = head.Position
                        local origin = headPos + Vector3.new(0, 0.1, 0)
                        newDir = (headPos - origin).Unit
                        -- replace first vector3 in rest (likely muzzlePos) with origin
                        for idx = 1, #rest do
                            if typeof(rest[idx]) == "Vector3" then
                                rest[idx] = origin
                                break
                            end
                        end
                        -- draw persistent screen line to head
                        if tracerEnabled then
                            local camPos = Camera.CFrame.Position
                            local sp = Camera:WorldToViewportPoint(camPos)
                            local hp = Camera:WorldToViewportPoint(headPos)
                            bulletTPLine.From = Vector2.new(sp.X, sp.Y)
                            bulletTPLine.To = Vector2.new(hp.X, hp.Y)
                            bulletTPLine.Color = bulletTPColor
                            bulletTPLine.Visible = true
                        end
                    end
                    -- override direction to point back at head
                    if newDir then
                        if typeof(arg1) == "Vector3" then
                            arg1 = newDir
                        elseif type(arg1) == "table" then
                            for i = 1, #arg1 do
                                if typeof(arg1[i]) == "Vector3" then
                                    arg1[i] = newDir
                                end
                            end
                        end
                    end
                elseif silentAimEnabled and _silentAimTarget and not bulletTPEnabled and arg1 then
                    local targetPos = _silentAimTarget.Position
                    -- Get muzzle position for direction calc
                    local muzzlePos = Camera.CFrame.Position
                    pcall(function()
                        local char = LocalPlayer.Character
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        if tool then
                            local om = Camera:FindFirstChild(tool.Name)
                            if om then
                                local gm = om:FindFirstChild(tool.Name)
                                local sp = gm and gm:FindFirstChild("SmokePart", true)
                                if sp then muzzlePos = sp.Position end
                            end
                        end
                    end)
                    local newDir = (targetPos - muzzlePos).Unit
                    -- Override direction for both visual bullet and server packet
                    if typeof(arg1) == "Vector3" then
                        arg1 = newDir
                    elseif type(arg1) == "table" then
                        for i = 1, #arg1 do
                            if typeof(arg1[i]) == "Vector3" then
                                arg1[i] = newDir
                            end
                        end
                    end
                end
                local res = oldCastRay(arg1, unpack(rest))
                inHook2 = false
                return res
            end))
            _hookStatus = "GetDir+CastRay hooked"
        end
    end

    Library:Notify("Silent Aim: hooks active!", 4)

    -- ── Infinite Ammo: scan for ammo table now that GetDir is known ──
    pcall(scanGCForACS)  -- re-scan to find fireGun → ammo table
    if _ammoTable then
        Library:Notify("Infinite Ammo: ammo table found!", 3)
    end
end

-- Infinite ammo background loop: keeps ammo at 999 + Chambered = true
-- Runs forever; re-scans for _ammoTable when it's nil (handles respawn)
task.spawn(function()
    while true do
        if infiniteAmmoEnabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                -- If ammo table is lost (respawn), try to re-find it
                if not _ammoTable then
                    pcall(scanGCForACS)
                end
                -- Reset ammo in tbl_3_upvr (client-side ammo table)
                if _ammoTable then
                    -- Set ammo for ALL keys (tools) in the table, not just current
                    for k, v in pairs(_ammoTable) do
                        if typeof(k) == "Instance" and k:IsA("Tool") then
                            _ammoTable[k] = 999
                        end
                    end
                end
                -- Keep Chambered = true (prevents bolt-lock blocking fire)
                pcall(function()
                    local acsGuns = ReplicatedStorage:FindFirstChild("Configurations")
                        and ReplicatedStorage.Configurations:FindFirstChild("ACS_Guns")
                    if acsGuns and acsGuns:FindFirstChild(tool.Name) then
                        local chambered = acsGuns[tool.Name]:FindFirstChild("Chambered")
                        if chambered and chambered:IsA("BoolValue") then
                            chambered.Value = true
                        end
                    end
                end)
            end
        end
        task.wait(0.05)
    end
end)

-- Start (or restart) the GC scan loop, then hook once found.
-- Called at startup and again on every respawn.
local function startHookTask()
    -- reset so we find the NEW ACS closures from the new character
    _origGetDir  = nil
    _origCastRay = nil
    _ammoTable   = nil   -- ammo table changes on respawn (new fireGun closure)
    _hookStatus  = "searching..."

    -- kill previous heartbeat scan if still running
    if _heartbeatScanConn then
        pcall(function() _heartbeatScanConn:Disconnect() end)
        _heartbeatScanConn = nil
    end

    task.spawn(function()
        -- aggressive heartbeat scan
        _heartbeatScanConn = RunService.Heartbeat:Connect(function()
            if _origGetDir and _origCastRay then
                if _heartbeatScanConn then
                    _heartbeatScanConn:Disconnect()
                    _heartbeatScanConn = nil
                end
            else
                pcall(scanGCForACS)
            end
        end)

        -- wait for GetDir to appear (with 60 s timeout)
        local deadline = tick() + 60
        repeat task.wait(0.15) until _origGetDir or tick() > deadline

        if not _origGetDir then
            _hookStatus = "GetDir not found (timeout)"
            return
        end

        -- extra wait so CastRay is also created, then final scan
        task.wait(0.5)
        pcall(scanGCForACS)

        setupHooks()
    end)
end

-- Watch for respawn: new character → new ACS_Client → new closures
LocalPlayer.CharacterAdded:Connect(function(char)
    _hookStatus = "searching... (respawn)"
    -- give the character a moment to fully load + ACS_Client to init
    task.wait(1.5)
    startHookTask()
    watchCharForTools(char)
end)

-- Wire up the CURRENT character right now (handles load-before-shooting)
if LocalPlayer.Character then
    watchCharForTools(LocalPlayer.Character)
end

-- Kick off the initial scan immediately
startHookTask()

-- Debug button to check hook status
SilentAimGroup:AddButton("AimDebugStatus", {
    Text = "Check Hook Status",
    Callback = function()
        local msg = string.format(
            "Hook: %s | Shots redirected: %d | Target: %s",
            _hookStatus,
            _aimDebugCount,
            _silentAimTarget and _silentAimTarget:GetFullName() or "none"
        )
        Library:Notify(msg, 5)
    end
})

--============================================================
-- VISUALS TAB: Viewmodel & Tracers
--============================================================
local ViewmodelGroup = Tabs.Visuals:AddLeftGroupbox("Viewmodel", "eye")

ViewmodelGroup:AddToggle("VMChams", {
    Text = "Viewmodel Chams",
    Default = false,
    Callback = function(val)
        vmChamsEnabled = val
        if not val and vmChamsHighlight then
            vmChamsHighlight:Destroy()
            vmChamsHighlight = nil
        end
    end
})
    :AddColorPicker("VMChamsFill", {
        Default = Color3.fromRGB(75, 0, 130),
        Title = "Fill Color",
        Transparency = 0,
        Callback = function(val)
            vmChamsFillColor = val
            if vmChamsHighlight then vmChamsHighlight.FillColor = val end
        end
    })
    :AddColorPicker("VMChamsOutline", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Outline Color",
        Transparency = 0,
        Callback = function(val)
            vmChamsOutlineColor = val
            if vmChamsHighlight then vmChamsHighlight.OutlineColor = val end
        end
    })

ViewmodelGroup:AddSlider("VMChamsFillTransp", {
    Text = "Fill Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(val)
        vmChamsFillTransparency = val / 100
        if vmChamsHighlight then vmChamsHighlight.FillTransparency = vmChamsFillTransparency end
    end
})

ViewmodelGroup:AddSlider("VMChamsOutlineTransp", {
    Text = "Outline Transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(val)
        vmChamsOutlineTransparency = val / 100
        if vmChamsHighlight then vmChamsHighlight.OutlineTransparency = vmChamsOutlineTransparency end
    end
})

ViewmodelGroup:AddDivider()

ViewmodelGroup:AddSlider("VMOffsetX", {
    Text = "Offset X",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Callback = function(val) vmOffsetX = val end
})

ViewmodelGroup:AddSlider("VMOffsetY", {
    Text = "Offset Y",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Callback = function(val) vmOffsetY = val end
})

ViewmodelGroup:AddSlider("VMOffsetZ", {
    Text = "Offset Z",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Callback = function(val) vmOffsetZ = val end
})

local TracerGroup = Tabs.Visuals:AddRightGroupbox("Bullet Tracers", "zap")

-- additional groupbox for camera FOV
local FOVGroup = Tabs.Visuals:AddRightGroupbox("Camera FOV", "viewfinder")
local cameraFOV = Camera.FieldOfView

FOVGroup:AddSlider("CameraFOV", {
    Text = "Field of View",
    Default = cameraFOV,
    Min = 30,
    Max = 140,
    Rounding = 1,
    Callback = function(val)
        cameraFOV = val
        Camera.FieldOfView = val
    end
})


TracerGroup:AddToggle("TracerEnable", {
    Text = "Enable Tracers",
    Default = false,
    Callback = function(val) tracerEnabled = val end
})
    :AddColorPicker("TracerStartColor", {
        Default = Color3.fromRGB(255, 50, 50),
        Title = "Start Color",
        Transparency = 0,
        Callback = function(val) tracerStartColor = val end
    })
    :AddColorPicker("TracerEndColor", {
        Default = Color3.fromRGB(255, 50, 50),
        Title = "End Color",
        Transparency = 0,
        Callback = function(val) tracerEndColor = val end
    })

TracerGroup:AddSlider("TracerFadeTime", {
    Text = "Fade Time",
    Default = 30,
    Min = 5,
    Max = 200,
    Rounding = 0,
    Suffix = "ms",
    Callback = function(val) tracerFadeTime = val / 100 end
})

TracerGroup:AddSlider("TracerWidth", {
    Text = "Width",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(val) tracerWidth = val / 100 end
})

--============================================================
-- VISUALS: Player ESP (via TrisESP library)
--============================================================
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

-- Master ESP enable
local ESPEnableToggle = ESPGroup:AddToggle("ESPEnable", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v) setESPSetting("Enabled", v) end
})


ESPGroup:AddDivider()

-- Box
local BoxToggle = ESPGroup:AddToggle("BoxESPToggle", {
    Text = "Box",
    Default = false,
    Callback = function(value) setESPSetting("Boxes", value) end
})
local BoxDep = ESPGroup:AddDependencyBox()
BoxDep:SetupDependencies({{BoxToggle, true}})
BoxToggle:AddColorPicker("BoxGradient", {
    Title = "Box Color",
    Default = Color3.fromRGB(255, 0, 0),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("Box", payload)
        end
    end
})
BoxDep:AddDropdown("BoxSizingMode", {
    Text = "Sizing Mode",
    Values = {"Static", "Bounding"},
    Default = "Static",
    Callback = function(v) setESPSetting("BoxSizingMode", v) end
})
BoxDep:AddSlider("StaticBoxWidth", {
    Text = "Static Width Ratio",
    Default = 60,
    Min = 20,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(v) setESPSetting("StaticBoxWidth", v / 100) end
})
BoxDep:AddToggle("BoxOutlineRotationToggle", {
    Text = "Animate",
    Default = false,
    Callback = function(v) setESPSetting("BoxOutlineRotation", v) end
})
BoxDep:AddSlider("BoxOutlineRotationSpeed", {
    Text = "Outline Spin Speed",
    Default = 300,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Suffix = " deg/s",
    Callback = function(v) setESPSetting("BoxOutlineRotationSpeed", v) end
})

-- Box Fill
local BoxFillToggle = ESPGroup:AddToggle("BoxFillESPToggle", {
    Text = "Box Fill",
    Default = false,
    Callback = function(value) setESPSetting("BoxFill", value) end
})
local BoxFillDep = ESPGroup:AddDependencyBox()
BoxFillDep:SetupDependencies({{BoxFillToggle, true}})
BoxFillToggle:AddColorPicker("BoxFillGradient", {
    Title = "Fill Color",
    Default = Color3.fromRGB(68, 0, 255),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("BoxFill", payload)
        end
    end
})
BoxFillDep:AddToggle("BoxFillAnimateToggle", {
    Text = "Animate",
    Default = false,
    Callback = function(v) setESPSetting("AnimateBoxRotation", v) end
})
BoxFillDep:AddSlider("BoxRotationSpeed", {
    Text = "Rotation Speed",
    Default = 300,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Suffix = " deg/s",
    Callback = function(v) setESPSetting("BoxRotationSpeed", v) end
})

-- glow toggle for box outlines/fills


-- Chams
local ChamsToggle = ESPGroup:AddToggle("ChamsESPToggle", {
    Text = "Chams",
    Default = false,
    Callback = function(value) setESPSetting("Highlight", value) end
})
local ChamsDep = ESPGroup:AddDependencyBox()
ChamsDep:SetupDependencies({{ChamsToggle, true}})
ChamsToggle:AddColorPicker("ChamsColor", {
    Title = "Chams Color",
    Default = Color3.fromRGB(0, 170, 255),
    Callback = function(c) setESPSetting("GlobalChamColor", c) end
})
ChamsDep:AddSlider("ChamsFillTransparencySlider", {
    Text = "Fill Transparency",
    Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true,
    Callback = function(value) setESPSetting("FillTransparency", value) end
})
ChamsDep:AddSlider("ChamsOutlineTransparencySlider", {
    Text = "Outline Transparency",
    Min = 0, Max = 1, Default = 0, Rounding = 2, Compact = true,
    Callback = function(value) setESPSetting("OutlineTransparency", value) end
})

-- ESP Tracers (2D screen-space tracers from the ESP library)
local ESPTracerToggle = ESPGroup:AddToggle("ESPTracerToggle", {
    Text = "ESP Tracers",
    Default = false,
    Callback = function(v) setESPSetting("Tracers", v) end
})
local ESPTracerDep = ESPGroup:AddDependencyBox()
ESPTracerDep:SetupDependencies({{ESPTracerToggle, true}})
ESPTracerToggle:AddColorPicker("ESPTracerColor", {
    Title = "Tracer Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) setESPSetting("TracerColor", c) end
})
ESPTracerDep:AddDropdown("ESPTracerFrom", {
    Text = "Tracer Origin",
    Values = {"Bottom", "Top", "Center"},
    Default = "Bottom",
    Callback = function(v) setESPSetting("TracerFrom", v) end
})
ESPTracerDep:AddSlider("ESPTracerThickness", {
    Text = "Thickness",
    Default = 12,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(v) setESPSetting("TracerThickness", v / 10) end
})



-- Distance
local DistanceToggle = ESPGroup:AddToggle("DistanceESPToggle", {
    Text = "Distance",
    Default = false,
    Callback = function(value) setESPSetting("ShowDistance", value) end
})
local DistanceDep = ESPGroup:AddDependencyBox()
DistanceDep:SetupDependencies({{DistanceToggle, true}})
DistanceToggle:AddColorPicker("DistanceGradient", {
    Title = "Distance Color",
    Default = Color3.fromRGB(255, 255, 255),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("Distance", payload)
        end
    end
})

DistanceDep:AddSlider("DistanceGradientRotation", {
    Text = "Gradient Rotation",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Suffix = "°",
    Callback = function(v) setESPSetting("DistanceGradientRotation", v) end
})

-- Name
local NameToggle = ESPGroup:AddToggle("NameESPToggle", {
    Text = "Name",
    Default = false,
    Callback = function(value) setESPSetting("ShowName", value) end
})
local NameDep = ESPGroup:AddDependencyBox()
NameDep:SetupDependencies({{NameToggle, true}})
NameDep:AddDropdown("NameMode", {
    Text = "Name Mode",
    Values = {"Name", "DisplayName", "Both"},
    Default = "DisplayName",
    Callback = function(v) setESPSetting("NameMode", v) end
})
-- gradient options for the name label
NameToggle:AddColorPicker("NameGradient", {
    Title = "Name Color",
    Default = Color3.fromRGB(255, 255, 255),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("Name", payload)
        end
    end
})

NameDep:AddSlider("NameGradientRotation", {
    Text = "Gradient Rotation",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Suffix = "°",
    Callback = function(v) setESPSetting("NameGradientRotation", v) end
})



-- Health
local HealthToggle = ESPGroup:AddToggle("HealthESPToggle", {
    Text = "Health Bar",
    Default = false,
    Callback = function(v) setESPSetting("HealthBarEnabled", v) end
})
local HealthDep = ESPGroup:AddDependencyBox()
HealthDep:SetupDependencies({{HealthToggle, true}})
HealthToggle:AddColorPicker("HealthGradient", {
    Title = "Health Colors",
    Default = Color3.fromRGB(255, 0, 0),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("HealthBar", payload)
        end
    end
})
HealthDep:AddDropdown("HealthBarPosition", {
    Text = "Position",
    Values = {"Left", "Right", "Bottom"},
    Default = "Bottom",
    Callback = function(v) setESPSetting("HealthBarPosition", v) end
})
HealthDep:AddSlider("HealthBarThickness", {
    Text = "Thickness",
    Default = 25,
    Min = 10,
    Max = 80,
    Rounding = 0,
    Callback = function(v) setESPSetting("HealthBarThickness", v / 10) end
})
HealthDep:AddToggle("HealthAnimateToggle", {
    Text = "Animate",
    Default = false,
    Callback = function(v) setESPSetting("HealthGradientEnabled", v) end
})
HealthDep:AddSlider("HealthGradientSpeed", {
    Text = "Gradient Speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Suffix = "%",
    Callback = function(v) setESPSetting("HealthGradientSpeed", v / 100) end
})


local HealthShowTextToggle = HealthDep:AddToggle("HealthShowTextToggle", {
    Text = "Show Text",
    Default = false,
    Callback = function(v) setESPSetting("ShowHealthText", v) end
})
-- health-text gradient and color – linked to the Show Text toggle
HealthShowTextToggle:AddColorPicker("HealthTextGradient", {
    Title = "Text Color",
    Default = Color3.fromRGB(255, 255, 255),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("HealthText", payload)
        end
    end
})

HealthDep:AddSlider("HealthTextGradientRotation", {
    Text = "Text Rotation",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Suffix = "°",
    Callback = function(v) setESPSetting("HealthTextGradientRotation", v) end
})
HealthDep:AddToggle("HealthOutlineResizeToggle", {
    Text = "Outline Resize",
    Default = false,
    Callback = function(v) setESPSetting("HealthOutlineFollow", v) end
})

--============================================================
-- VISUALS: Vehicle ESP (Highlight-based Object ESP)
--============================================================
-- font dropdown moved to bottom of ESP group
ESPGroup:AddDropdown("ESPTextFont", {
    Text = "Font",
    Default = "ProggyClean",
    Values = {"ProggyClean", "Tahoma", "SourceSansBold", "GothamBold", "Gotham", "Roboto", "RobotoMono", "Ubuntu", "Oswald"},
    Callback = function(v) setESPSetting("TextFont", v) end
})

-- Minimum box size
ESPGroup:AddSlider("ESPMinBoxWidth", {
    Text = "Min Box Width",
    Default = 8,
    Min = 0,
    Max = 60,
    Rounding = 0,
    Suffix = "px",
    Callback = function(v) setESPSetting("MinBoxWidth", v) end
})
ESPGroup:AddSlider("ESPMinBoxHeight", {
    Text = "Min Box Height",
    Default = 12,
    Min = 0,
    Max = 80,
    Rounding = 0,
    Suffix = "px",
    Callback = function(v) setESPSetting("MinBoxHeight", v) end
})

--============================================================
-- VISUALS: Skeleton ESP
--============================================================
local SkeletonGroup = Tabs.Visuals:AddLeftGroupbox("Skeleton ESP")

local SkeletonToggle = SkeletonGroup:AddToggle("SkeletonEnable", {
    Text = "Enable Skeleton",
    Default = false,
    Callback = function(v) setESPSetting("SkeletonEnabled", v) end
})
SkeletonToggle:AddColorPicker("SkeletonBoneColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Bone Color",
    Transparency = 0,
    Callback = function(v) setESPSetting("BoneColor", v) end
})

local SkeletonDep = SkeletonGroup:AddDependencyBox()
SkeletonDep:SetupDependencies({{SkeletonToggle, true}})

SkeletonDep:AddSlider("SkeletonThickness", {
    Text = "Thickness",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(v) setESPSetting("BoneThickness", v / 10) end
})

SkeletonDep:AddToggle("SkeletonOutlineEnable", {
    Text = "Outline",
    Default = true,
    Callback = function(v) setESPSetting("SkeletonOutlineEnabled", v) end
}):AddColorPicker("SkeletonOutlineColor", {
    Default = Color3.fromRGB(0, 0, 0),
    Title = "Outline Color",
    Transparency = 0,
    Callback = function(v) setESPSetting("SkeletonOutlineColor", v) end
})

SkeletonDep:AddToggle("SkeletonGradientEnable", {
    Text = "Gradient",
    Default = false,
    Callback = function(v) setESPSetting("SkeletonGradientEnabled", v) end
}):AddColorPicker("SkeletonGradientColors", {
    Title = "Skeleton Gradient",
    Default = Color3.fromRGB(255, 80, 168),
    Gradient = true,
    Transparency = true,
    Callback = function(payload)
        if getgenv().TrisESP and getgenv().TrisESP.HandleColorPickerChange then
            getgenv().TrisESP.HandleColorPickerChange("Skeleton", payload)
        end
    end
})
SkeletonDep:AddSlider("SkeletonGradientSpeed", {
    Text = "Gradient Speed",
    Default = 40,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Suffix = "%",
    Callback = function(v) setESPSetting("SkeletonGradientSpeed", v / 100) end
})

--============================================================
-- VISUALS: Custom Crosshair
--============================================================
local CrosshairGroup = Tabs.Visuals:AddLeftGroupbox("Custom Crosshair", "plus")

local crosshairEnabled = false
local crosshairLength = 10
local crosshairWidth = 2
local crosshairSpacing = 5
local crosshairSpinSpeed = 0
-- Per-line colors: Right, Left, Down, Up
local crosshairColors = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 255, 255),
}
local crosshairPositions = {} -- multi-select: {"Barrel", "Target"} or empty = center only
local _crosshairAngle = 0
local crosshairBounceEnabled = false
local crosshairBounceMin = 2
local crosshairBounceMax = 15
local crosshairBounceSpeed = 3
local _crosshairBounceTime = 0

-- Main crosshair lines + outline lines (behind each, +2px thick, black)
local _crossLines = {}
local _crossOutlines = {}
for i = 1, 4 do
    local outline = Drawing.new("Line")
    outline.Visible = false
    outline.Thickness = 4
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.ZIndex = 999
    _crossOutlines[i] = outline

    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 2
    line.Color = Color3.fromRGB(255, 255, 255)
    line.ZIndex = 1000
    _crossLines[i] = line
end

local CrosshairEnableToggle = CrosshairGroup:AddToggle("CrosshairEnable", {
    Text = "Enable",
    Default = false,
    Callback = function(val)
        crosshairEnabled = val
        for i = 1, 4 do
            _crossLines[i].Visible = val
            _crossOutlines[i].Visible = val
        end
    end
})

-- Per-line color pickers as a DependencyBox
local CrosshairColorBox = CrosshairGroup:AddDependencyBox()
CrosshairColorBox:SetupDependencies({{CrosshairEnableToggle, true}})

local _crossColorNames = {"Right", "Left", "Down", "Up"}
for idx, armName in ipairs(_crossColorNames) do
    CrosshairColorBox:AddLabel(armName .. " Color")
        :AddColorPicker("CrosshairColor" .. armName, {
            Default = Color3.fromRGB(255, 255, 255),
            Title = armName .. " Line",
            Transparency = 0,
            Callback = function(val)
                crosshairColors[idx] = val
                _crossLines[idx].Color = val
            end
        })
end

CrosshairGroup:AddSlider("CrosshairLength", {
    Text = "Length",
    Default = 10,
    Min = 2,
    Max = 50,
    Rounding = 0,
    Callback = function(val) crosshairLength = val end
})

CrosshairGroup:AddSlider("CrosshairWidth", {
    Text = "Width",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(val)
        crosshairWidth = val
        for i = 1, 4 do
            _crossLines[i].Thickness = val
            _crossOutlines[i].Thickness = val + 2
        end
    end
})

CrosshairGroup:AddSlider("CrosshairSpacing", {
    Text = "Spacing",
    Default = 5,
    Min = 0,
    Max = 30,
    Rounding = 0,
    Callback = function(val) crosshairSpacing = val end
})

CrosshairGroup:AddSlider("CrosshairSpinSpeed", {
    Text = "Spin Speed",
    Default = 0,
    Min = 0,
    Max = 720,
    Rounding = 0,
    Suffix = " deg/s",
    Callback = function(val) crosshairSpinSpeed = val end
})

CrosshairGroup:AddDropdown("CrosshairPosition", {
    Text = "Position Mode",
    Default = {},
    Multi = true,
    Values = {"Barrel", "Target"},
    Callback = function(val) crosshairPositions = val end
})

CrosshairGroup:AddDivider()

local BounceToggle = CrosshairGroup:AddToggle("CrosshairBounce", {
    Text = "Distance Bounce",
    Default = false,
    Callback = function(val) crosshairBounceEnabled = val end
})
local BounceDep = CrosshairGroup:AddDependencyBox()
BounceDep:SetupDependencies({{BounceToggle, true}})
BounceDep:AddSlider("CrosshairBounceMin", {
    Text = "Min Distance",
    Default = 2,
    Min = 0,
    Max = 30,
    Rounding = 0,
    Callback = function(val) crosshairBounceMin = val end
})
BounceDep:AddSlider("CrosshairBounceMax", {
    Text = "Max Distance",
    Default = 15,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(val) crosshairBounceMax = val end
})
BounceDep:AddSlider("CrosshairBounceSpeed", {
    Text = "Bounce Speed",
    Default = 3,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(val) crosshairBounceSpeed = val end
})

-- Crosshair update (RenderStepped)
RunService.RenderStepped:Connect(function(dt)
    if not crosshairEnabled then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Position logic: center is default baseline
    -- If both Barrel and Target selected: use barrel, snap to target when target exists
    local useBarrel = crosshairPositions["Barrel"] or false
    local useTarget = crosshairPositions["Target"] or false

    local barrelPos = nil
    if useBarrel then
        pcall(function()
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                local vm = nil
                for _, child in ipairs(Camera:GetChildren()) do
                    if child:IsA("Model") and child.Name == tool.Name then vm = child; break end
                end
                if vm then
                    local sp = vm:FindFirstChild("SmokePart", true)
                    if sp then
                        local screenPos = Camera:WorldToViewportPoint(sp.Position)
                        barrelPos = Vector2.new(screenPos.X, screenPos.Y)
                    end
                end
            end
        end)
    end

    local targetPos = nil
    if useTarget and _silentAimTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(_silentAimTarget.Position)
        if onScreen then
            targetPos = Vector2.new(screenPos.X, screenPos.Y)
        end
    end

    -- Priority: if both selected, prefer target when available, fallback to barrel
    if useTarget and useBarrel then
        center = targetPos or barrelPos or center
    elseif useTarget then
        center = targetPos or center
    elseif useBarrel then
        center = barrelPos or center
    end

    _crosshairAngle = _crosshairAngle + crosshairSpinSpeed * dt
    local rad = math.rad(_crosshairAngle)
    local cosR = math.cos(rad)
    local sinR = math.sin(rad)

    -- Bounce crosshair spacing if enabled
    local effectiveSpacing = crosshairSpacing
    if crosshairBounceEnabled then
        _crosshairBounceTime = _crosshairBounceTime + dt * crosshairBounceSpeed
        local t = (math.sin(_crosshairBounceTime) + 1) / 2 -- 0 to 1
        effectiveSpacing = crosshairBounceMin + (crosshairBounceMax - crosshairBounceMin) * t
    end

    local arms = {
        Vector2.new(1, 0),   -- right
        Vector2.new(-1, 0),  -- left
        Vector2.new(0, 1),   -- down
        Vector2.new(0, -1),  -- up
    }

    for i, dir in ipairs(arms) do
        local rx = dir.X * cosR - dir.Y * sinR
        local ry = dir.X * sinR + dir.Y * cosR
        local rotDir = Vector2.new(rx, ry)
        local from = center + rotDir * effectiveSpacing
        local to = center + rotDir * (effectiveSpacing + crosshairLength)
        -- Outline (behind, thicker, black) – extend endpoints for clean caps
        local capExt = (_crossOutlines[i].Thickness - _crossLines[i].Thickness) / 2
        _crossOutlines[i].From = from - rotDir * capExt
        _crossOutlines[i].To = to + rotDir * capExt
        _crossOutlines[i].Visible = true
        -- Main line
        _crossLines[i].From = from
        _crossLines[i].To = to
        _crossLines[i].Color = crosshairColors[i]
        _crossLines[i].Visible = true
    end
end)

-- Viewmodel chams + offset update
-- Runs at Camera+10 to guarantee it runs AFTER ACS sets the viewmodel CFrame
RunService:BindToRenderStep("VMVisuals", Enum.RenderPriority.Camera.Value + 10, function()
    -- enforce camera FOV every frame (ACS may modify it)
    if cameraFOV then
        Camera.FieldOfView = cameraFOV
    end

    -- Find the viewmodel model parented to Camera
    local vm = nil
    for _, child in Camera:GetChildren() do
        if child:IsA("Model") then
            vm = child
            break
        end
    end

    -- Viewmodel Chams
    if vmChamsEnabled and vm then
        if not vmChamsHighlight or vmChamsHighlight.Parent ~= vm then
            if vmChamsHighlight then pcall(function() vmChamsHighlight:Destroy() end) end
            vmChamsHighlight = Instance.new("Highlight")
            vmChamsHighlight.Name = "_VMChams"
            vmChamsHighlight.Adornee = vm
            vmChamsHighlight.FillColor = vmChamsFillColor
            vmChamsHighlight.OutlineColor = vmChamsOutlineColor
            vmChamsHighlight.FillTransparency = vmChamsFillTransparency
            vmChamsHighlight.OutlineTransparency = vmChamsOutlineTransparency
            vmChamsHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            vmChamsHighlight.Parent = vm
        end
    else
        if vmChamsHighlight then
            pcall(function() vmChamsHighlight:Destroy() end)
            vmChamsHighlight = nil
        end
    end

    -- Viewmodel Offset
    -- ACS sets the viewmodel root part CFrame every frame.
    -- We offset the root part DIRECTLY (not PivotTo) at Camera+10 priority
    -- so we always run after ACS. This moves all child parts via Motor6D joints.
    if vm and (vmOffsetX ~= 0 or vmOffsetY ~= 0 or vmOffsetZ ~= 0) then
        local rootPart = vm.PrimaryPart or vm:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            -- fallback: find any BasePart with Motor6D children
            for _, p in vm:GetDescendants() do
                if p:IsA("BasePart") then
                    rootPart = p
                    break
                end
            end
        end
        if rootPart then
            rootPart.CFrame = rootPart.CFrame * CFrame.new(vmOffsetX, vmOffsetY, vmOffsetZ)
        end
    end
end)

--============================================================
-- VISUALS: Hit Marker & Sound
--============================================================

-- configuration
local hitMarkerEnabled = false
local hitMarkerColor = Color3.fromRGB(255, 0, 0)
local hitMarkerSize = 20
local hitMarkerDuration = 0.3
local hitMarkers = {}

local hitSoundEnabled = false
local hitSoundVolume = 1
local hitSound = Instance.new("Sound")
hitSound.Name = "HitSound"
hitSound.Parent = Camera
hitSound.Volume = hitSoundVolume
hitSound.SoundId = "rbxassetid://0" -- changeable via UI

-- helper to spawn a marker at world position
local function spawnHitMarker(pos)
    local entry = {worldPos = pos, start = tick(), lines = {}}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Thickness = 2
        l.Color = hitMarkerColor
        l.ZIndex = 2000
        l.Visible = true
        table.insert(entry.lines, l)
    end
    table.insert(hitMarkers, entry)
end

-- update / cleanup markers each render step
RunService.RenderStepped:Connect(function()
    local now = tick()
    for i = #hitMarkers, 1, -1 do
        local m = hitMarkers[i]
        local elapsed = now - m.start
        if elapsed >= hitMarkerDuration then
            for _, l in ipairs(m.lines) do
                l.Visible = false
                l:Remove()
            end
            table.remove(hitMarkers, i)
        else
            local screenPos, onScreen = Camera:WorldToViewportPoint(m.worldPos)
            if onScreen then
                local s = hitMarkerSize
                local x, y = screenPos.X, screenPos.Y
                m.lines[1].From = Vector2.new(x - s, y)
                m.lines[1].To   = Vector2.new(x - s/2, y)
                m.lines[2].From = Vector2.new(x + s, y)
                m.lines[2].To   = Vector2.new(x + s/2, y)
                m.lines[3].From = Vector2.new(x, y - s)
                m.lines[3].To   = Vector2.new(x, y - s/2)
                m.lines[4].From = Vector2.new(x, y + s)
                m.lines[4].To   = Vector2.new(x, y + s/2)
                for _, l in ipairs(m.lines) do
                    l.Color = hitMarkerColor
                    l.Visible = true
                end
            else
                for _, l in ipairs(m.lines) do
                    l.Visible = false
                end
            end
        end
    end
end)

-- hook BulletHit remote for visuals/sound (fallback — may not fire for shooter)
pcall(function()
    _BulletHitRemote.OnClientEvent:Connect(function(hitPart, hitPos, damage, ...)
        -- hitPos may be nil or a different type; fall back to hitPart position
        local pos = hitPos
        if typeof(pos) ~= "Vector3" and typeof(hitPart) == "Instance" and hitPart:IsA("BasePart") then
            pos = hitPart.Position
        end
        if hitMarkerEnabled and typeof(pos) == "Vector3" then
            spawnHitMarker(pos)
        end
        if hitSoundEnabled then
            hitSound:Play()
        end
    end)
end)

-- UI controls (appear in crosshair group)
local hmToggle = CrosshairGroup:AddToggle("HitMarkerEnabled", {
    Text = "Hit Marker",
    Default = false,
    Callback = function(val) hitMarkerEnabled = val end,
})
    :AddColorPicker("HitMarkerColor", {
        Default = hitMarkerColor,
        Title = "Marker Color",
        Callback = function(val) hitMarkerColor = val end,
    })

local HMDep = CrosshairGroup:AddDependencyBox()
HMDep:SetupDependencies({{hmToggle, true}})
HMDep:AddSlider("HitMarkerSize", {
    Text = "Size",
    Default = hitMarkerSize,
    Min = 5,
    Max = 100,
    Callback = function(val) hitMarkerSize = val end,
})
HMDep:AddSlider("HitMarkerDuration", {
    Text = "Duration",
    Default = hitMarkerDuration,
    Min = 0.1,
    Max = 1,
    Float = true,
    Callback = function(val) hitMarkerDuration = val end,
})

CrosshairGroup:AddToggle("HitSoundEnabled", {
    Text = "Hit Sound",
    Default = false,
    Callback = function(val) hitSoundEnabled = val end,
})

local HSDep = CrosshairGroup:AddDependencyBox()
HSDep:SetupDependencies({{Toggles.HitSoundEnabled, true}})
HSDep:AddSlider("HitSoundVolume", {
    Text = "Volume",
    Default = hitSoundVolume,
    Min = 0,
    Max = 5,
    Callback = function(val) hitSoundVolume = val; hitSound.Volume = val end,
})
HSDep:AddInput("HitSoundId", {
    Default = hitSound.SoundId,
    Numeric = false,
    Finished = true,
    Text = "Sound ID",
    Callback = function(val) hitSound.SoundId = val end,
})

--============================================================
-- MODIFICATIONS TAB: Gun Modifications
--============================================================
local GunModsGroup = Tabs.Modifications:AddLeftGroupbox("Gun Modifications", "tool")

-- Recoil Modifier (0 = full recoil, 100 = no recoil)
local recoilMultiplier = 0
GunModsGroup:AddSlider("RecoilModifier", {
    Text = "Recoil Reduction",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(val)
        recoilMultiplier = 1 - (val / 100)
    end
})

-- Firerate Modifier (0 = no fire, 100 = normal rate)
local firerateMultiplier = 1
GunModsGroup:AddSlider("FirerateModifier", {
    Text = "Firerate %",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(val)
        firerateMultiplier = val / 100
    end
})

-- Infinite Ammo toggle
GunModsGroup:AddToggle("InfiniteAmmo", {
    Text = "Infinite Ammo",
    Default = false,
    Callback = function(val)
        infiniteAmmoEnabled = val
        if val then
            Library:Notify(_ammoTable and "Infinite Ammo: ON (ammo table found)" or "Infinite Ammo: ON (waiting for ammo table — equip a gun)", 4)
        end
    end
})

GunModsGroup:AddToggle("NoMaxDist", {
    Text = "No Distance Limit",
    Default = false,
    Callback = function(val)
        noMaxDistEnabled = val
    end
})

GunModsGroup:AddToggle("AlwaysAutomatic", {
    Text = "Always Automatic",
    Tooltip = "Forces semi-automatic weapons to fire in full auto",
    Default = false,
    Callback = function(val)
        alwaysAutoEnabled = val
    end
})

GunModsGroup:AddToggle("BreakBaseShields", {
    Text = "Break Base Shields",
    Tooltip = "Redirects fire at enemy base shields when no player target is found",
    Default = false,
    Callback = function(val)
        breakShieldsEnabled = val
    end
})

GunModsGroup:AddToggle("InstantHit", {
    Text = "Instant Hit",
    Tooltip = "Makes bullets travel at extreme speed so they hit instantly",
    Default = false,
    Callback = function(val)
        instantHitEnabled = val
    end
})

-- player modifications group (anti-AFK)
local antiAfkEnabled = false
local antiAfkConn = nil
PlayerModsGroup = Tabs.Modifications:AddRightGroupbox("Player Mods", "user")
PlayerModsGroup:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Tooltip = "Prevents the game from marking you idle",
    Default = false,
    Callback = function(val)
        antiAfkEnabled = val
        if val then
            if antiAfkConn then antiAfkConn:Disconnect() end
            antiAfkConn = LocalPlayer.Idled:Connect(function()
                -- tiny position nudge instead of keyboard events
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0.1)
                end
            end)
        else
            if antiAfkConn then
                antiAfkConn:Disconnect()
                antiAfkConn = nil
            end
        end
    end
})

-- Apply firerate, recoil, and mode modifiers via ACS config
-- We periodically check and modify the ACS config values
task.spawn(function()
    while true do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local acsGuns = ReplicatedStorage:FindFirstChild("Configurations")
                        and ReplicatedStorage.Configurations:FindFirstChild("ACS_Guns")
                    if acsGuns and acsGuns:FindFirstChild(tool.Name) then
                        local settings = acsGuns[tool.Name]:FindFirstChild("Settings")
                        if settings then
                            local cfg = require(settings)

                            -- Always Automatic: force semi weapons into full auto
                            if alwaysAutoEnabled and cfg.Mode == "Semi" then
                                cfg.Mode = "Auto"
                            end

                            -- Firerate modifier
                            if firerateMultiplier ~= 1 then
                                if not tool:GetAttribute("_origFireRate") then
                                    tool:SetAttribute("_origFireRate", cfg.FireRate)
                                end
                                local origRate = tool:GetAttribute("_origFireRate")
                                local newRate = origRate * firerateMultiplier
                                tool:SetAttribute("FireRate", newRate)
                            end

                            -- Recoil modifier
                            if recoilMultiplier ~= 1 then
                                if not tool:GetAttribute("_origVRecoil1") then
                                    tool:SetAttribute("_origVRecoil1", cfg.VRecoil[1])
                                    tool:SetAttribute("_origVRecoil2", cfg.VRecoil[2])
                                    tool:SetAttribute("_origHRecoil1", cfg.HRecoil[1])
                                    tool:SetAttribute("_origHRecoil2", cfg.HRecoil[2])
                                end
                                local ov1 = tool:GetAttribute("_origVRecoil1")
                                local ov2 = tool:GetAttribute("_origVRecoil2")
                                local oh1 = tool:GetAttribute("_origHRecoil1")
                                local oh2 = tool:GetAttribute("_origHRecoil2")
                                tool:SetAttribute("VRecoil", Vector2.new(
                                    math.floor(ov1 * recoilMultiplier),
                                    math.floor(ov2 * recoilMultiplier)
                                ))
                                tool:SetAttribute("HRecoil", Vector2.new(
                                    math.floor(oh1 * recoilMultiplier),
                                    math.floor(oh2 * recoilMultiplier)
                                ))
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.25)
    end
end)

-- Setup SaveManager and ThemeManager in settings tab

--============================================================
-- WORLD TAB: World Visuals
--============================================================
local Lighting = game:GetService("Lighting")
local WorldGroup = Tabs.World:AddRightGroupbox("World Visuals", "globe")

-- Store original values for reset
local _origLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top,
    ExposureCompensation = Lighting.ExposureCompensation,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

WorldGroup:AddSlider("WorldBrightness", {
    Text = "Brightness",
    Default = math.floor(Lighting.Brightness),
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(val) Lighting.Brightness = val end
})

WorldGroup:AddSlider("WorldClockTime", {
    Text = "Time of Day",
    Default = math.floor(Lighting.ClockTime),
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(val) Lighting.ClockTime = val end
})

WorldGroup:AddSlider("WorldFogEnd", {
    Text = "Fog End",
    Default = math.clamp(math.floor(Lighting.FogEnd), 0, 100000),
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Callback = function(val) Lighting.FogEnd = val end
})

WorldGroup:AddSlider("WorldFogStart", {
    Text = "Fog Start",
    Default = math.clamp(math.floor(Lighting.FogStart), 0, 50000),
    Min = 0,
    Max = 50000,
    Rounding = 0,
    Callback = function(val) Lighting.FogStart = val end
})

WorldGroup:AddLabel("Ambient Color"):AddColorPicker("WorldAmbient", {
    Default = Lighting.Ambient,
    Title = "Ambient",
    Callback = function(val) Lighting.Ambient = val end
})

WorldGroup:AddLabel("Outdoor Ambient"):AddColorPicker("WorldOutdoorAmbient", {
    Default = Lighting.OutdoorAmbient,
    Title = "Outdoor Ambient",
    Callback = function(val) Lighting.OutdoorAmbient = val end
})

WorldGroup:AddLabel("Fog Color"):AddColorPicker("WorldFogColor", {
    Default = Lighting.FogColor,
    Title = "Fog Color",
    Callback = function(val) Lighting.FogColor = val end
})

WorldGroup:AddToggle("WorldShadows", {
    Text = "Global Shadows",
    Default = Lighting.GlobalShadows,
    Callback = function(val) Lighting.GlobalShadows = val end
})

WorldGroup:AddLabel("Bottom Color"):AddColorPicker("WorldColorShiftBottom", {
    Default = Lighting.ColorShift_Bottom,
    Title = "ColorShift Bottom",
    Callback = function(val) Lighting.ColorShift_Bottom = val end
})

WorldGroup:AddLabel("Top Color"):AddColorPicker("WorldColorShiftTop", {
    Default = Lighting.ColorShift_Top,
    Title = "ColorShift Top",
    Callback = function(val) Lighting.ColorShift_Top = val end
})

WorldGroup:AddSlider("WorldExposure", {
    Text = "Exposure",
    Default = Lighting.ExposureCompensation,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Callback = function(val) Lighting.ExposureCompensation = val end
})

WorldGroup:AddSlider("WorldDiffuseScale", {
    Text = "Diffuse Scale",
    Default = Lighting.EnvironmentDiffuseScale,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(val) Lighting.EnvironmentDiffuseScale = val end
})

WorldGroup:AddSlider("WorldSpecularScale", {
    Text = "Specular Scale",
    Default = Lighting.EnvironmentSpecularScale,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(val) Lighting.EnvironmentSpecularScale = val end
})




-- Settings UI is handled by the UIcustomization addon
if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder('TrisRocks/themes')
    ThemeManager:CreateThemePanels(Tabs.Settings)
end
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetFolder('TrisRocks/jujutsu-shenanigans')
    SaveManager:BuildConfigSection(Tabs.Settings)
end

-- the rest of trisrocks game logic can follow below this UI setup
