--[[
    TrisESP - ScreenGui ESP System
    
    Complete rewrite using ScreenGui instead of Drawing.new
    Includes rotation animation and vertical gradients
    
    Load via: loadstring(game:HttpGet("YOUR_URL_HERE"))()
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local renderConn

local ESPObjects = {}
local ESPsCleared = false
local RotationAngle = -90
-- Persistent state across hot-reloads (if executor preserves getgenv)
getgenv()._TrisESP_Persistent = getgenv()._TrisESP_Persistent or {}
local PERSIST = getgenv()._TrisESP_Persistent
PERSIST.HealthPhase = PERSIST.HealthPhase or {}
PERSIST.GradientAngle = PERSIST.GradientAngle or {}
PERSIST.SpinAngle = PERSIST.SpinAngle or RotationAngle


-- Create ScreenGui holder
local ESPHolder = Instance.new("ScreenGui")
ESPHolder.Name = "TrisESPHolder"
ESPHolder.ResetOnSpawn = false
ESPHolder.IgnoreGuiInset = true
pcall(function()
    ESPHolder.Parent = CoreGui
end)
if not ESPHolder.Parent then
    ESPHolder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local ESPSettings = {
    Enabled = true,
    MaxDistance = 150000,
    
    PlayerOverrides = {},
    
    -- Box animation settings
    AnimateBoxRotation = false,
    BoxRotationSpeed = 300,
    
    -- Filtering
    FilterMode = "All",
    WhitelistedPlayers = {},
    BlacklistedPlayers = {},
    TeamCheckEnabled = false,
    -- Custom team filters (strings = team names, objects = Team instances)
    CustomTeams = {},
    CustomTeamObjects = {},
    
    -- Display settings
    ShowName = false,
    -- Name display mode: "Name" | "DisplayName" | "Both"
    -- "Name" shows the Roblox username, "DisplayName" shows the player's display name,
    -- "Both" shows `DisplayName (Name)`
    NameMode = "DisplayName",
    ShowHealthText = false,
    ShowDistance = false,
    -- Font selection: "ProggyClean" | "Tahoma"
    TextFont = "ProggyClean",
    -- Name label gradient
    NameGradientRotation = 0, -- degrees
    NameGradientStops = {
        {pos = 0,   color = Color3.fromRGB(255,  80, 168), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB( 80, 200, 255), transparency = 0},
        {pos = 1,   color = Color3.fromRGB(180,  80, 255), transparency = 0},
    },
    -- Distance label gradient
    DistanceGradientRotation = 0, -- degrees
    DistanceGradientStops = {
        {pos = 0,   color = Color3.fromRGB(255, 200,  50), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB(255, 100,  50), transparency = 0},
        {pos = 1,   color = Color3.fromRGB(255, 200,  50), transparency = 0},
    },
    -- Health text label gradient (the HP/distance text shown below the bar)
    HealthTextGradientRotation = 0, -- degrees
    HealthTextGradientStops = {
        {pos = 0,   color = Color3.fromRGB(  0, 255,  80), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB(255, 255,   0), transparency = 0},
        {pos = 1,   color = Color3.fromRGB(255,  60,  60), transparency = 0},
    },
    
    -- Gradient settings (autorotate enabled internally)
    -- NOTE: UI gradient autorotation is handled internally; GUI animation controls removed

    
    -- Gradient stops (ulib colorpicker compatible)
    BoxGradientStops = {
        {pos = 0, color = Color3.fromRGB(255, 0, 0), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB(0, 255, 55), transparency = 0},
        {pos = 1, color = Color3.fromRGB(0, 0, 255), transparency = 0},
    },
    BoxFillGradientStops = {
        {pos = 0, color = Color3.fromRGB(68, 0, 255), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB(0, 255, 76), transparency = 0},
        {pos = 1, color = Color3.fromRGB(255, 0, 212), transparency = 0},
    },
    
    -- Box settings
    Boxes = false,
    BoxType = "Square",
    -- Box sizing mode: "Static" uses a fixed width ratio, "Bounding" uses dynamic part projection
    BoxSizingMode = "Static",
    -- Width multiplier for Static sizing mode (ratio of height)
    StaticBoxWidth = 0.6,
    BoxColor = Color3.fromRGB(0, 170, 255),
    Thickness = 2,
    BoxOutlineColor = Color3.new(0, 0, 0),
    
    -- Box fill
    BoxFill = false,
    BoxFillColor = Color3.fromRGB(0, 170, 255),
    BoxFillTransparency = 0.5,
    
    -- Tracers
    Tracers = false,
    TracerFrom = "Bottom",
    TracerThickness = 1.2,
    TracerColor = Color3.fromRGB(255, 255, 255),
    
    -- Health bar
    HealthBarEnabled = false,
    -- Health bar position: "Left" (vertical) or "Bottom" (horizontal below box)
    HealthBarPosition = "Bottom",
    HealthBarThickness = 2.5,
    -- Health bar gradient stops
    HealthBarGradientStops = {
        {pos = 0, color = Color3.fromRGB(255, 0, 0), transparency = 0},
        {pos = 0.5, color = Color3.fromRGB(38, 0, 255), transparency = 0},
        {pos = 1, color = Color3.fromRGB(0, 255, 0), transparency = 0},
    },
    -- Health gradient animation speed (cycles per second)
    HealthGradientSpeed = 0.5,
    -- Enable animated health gradient
    HealthGradientEnabled = true,
    -- Number of samples used when building the animated gradient (fixed default)
    -- (setting removed; defaults to 12 samples)
    -- Whether the healthbar outline thickness scales with the filled height
    HealthOutlineFollow = false,
    
    -- Minimum box size (pixels) to prevent tiny boxes at long range
    MinBoxWidth = 6,
    MinBoxHeight = 10,

    -- Skeleton ESP
    SkeletonEnabled = false,
    BoneThickness = 1.5,
    BoneColor = Color3.fromRGB(255, 255, 255),
    SkeletonOutlineEnabled = true,
    SkeletonOutlineColor = Color3.fromRGB(0, 0, 0),
    SkeletonOutlineThickness = 1,
    SkeletonGradientEnabled = false,
    SkeletonGradientSpeed = 0.4,
    SkeletonGradientStops = {
        { pos = 0,   color = Color3.fromRGB(255,  80, 168), transparency = 0 },
        { pos = 0.5, color = Color3.fromRGB( 80, 200, 255), transparency = 0 },
        { pos = 1,   color = Color3.fromRGB(180,  80, 255), transparency = 0 },
    },

    -- Chams
    Highlight = false,
    GlobalChamColor = Color3.fromRGB(0, 170, 255),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
}
--[[
Documentation: TrisESP usage & API

Settings (table: `getgenv().TrisESP.Settings`)
- Enabled (bool): Master system toggle. When false, all ESP is removed.
- MaxDistance (number): Max render distance (studs).
- TextFont (string): "ProggyClean" (monospace) or "Tahoma" (sans-serif).
- AnimateBoxRotation (bool): Rotate box-fill gradients when true.
- BoxRotationSpeed (number): Rotation speed used when AnimateBoxRotation is enabled.
- Boxes (bool): Enable box outlines.
- BoxType (string): "Square" or "Corner".
- BoxSizingMode (string): "Static" uses a fixed width ratio, "Bounding" uses dynamic part projection.
- StaticBoxWidth (number): Width multiplier for Static sizing mode (ratio of height, default 0.6).
- BoxOutlineColor (Color3): Outline color for box frames (outline stroke forced to 1px).
- BoxGradientStops (table): Gradient stops for box outlines ({pos, color, transparency} arrays).
- BoxFill (bool): Enable gradient-filled boxes (independent of `Boxes`).
- BoxFillGradientStops (table): Gradient stops for box fill.
- BoxFillTransparency (number 0-1): Transparency for the box fill layer.

- Tracers (bool), TracerFrom ("Top"|"Bottom"|"Center"), TracerThickness, TracerColor

- HealthBarEnabled (bool): Show vertical health bar.
- HealthBarPosition ("Left"|"Right"|"Bottom"): Side/position to draw health bar.
- HealthBarThickness (number): Pixel width of health bar.
- HealthBarGradientStops (table): Gradient stops used for the health bar.
- HealthGradientEnabled (bool): Animate the health gradient when true.
- HealthGradientSpeed (number): Cycles per second used when HealthGradientEnabled is true.
- ShowHealthText (bool): Show percent value next to the healthbar.
- HealthOutlineFollow (bool): When true the outline height follows the filled height.

- ShowName, NameMode ("Name"|"DisplayName"|"Both"), ShowDistance

Per-player overrides
- `getgenv().TrisESP.Settings.PlayerOverrides` is a table keyed by player UserId (string) or player.Name.
  Each entry is a table of settings which override the global `Settings` for that player.

API Helpers
- _resolvePlayer(ref) -> player object | nil
    Accepts: Player object, numeric UserId, or string player name.

- AddPlayerOverride(playerRef, overrides) -> bool
    `overrides` is a table of setting keys to override for the player. Example:
      getgenv().TrisESP.AddPlayerOverride("SomePlayer", { BoxFill = true })

- SetPlayerColor(playerRef, colorKey, color3) -> bool
    Convenience for a single color override. Example:
      getgenv().TrisESP.SetPlayerColor(12345678, "BoxColor", Color3.fromRGB(0,255,0))

- GetPlayerOverride(playerRef) -> table | nil
    Returns the override table for the player if present.

- RemovePlayerOverride(playerRef) -> bool
    Removes any overrides for the specified player.

- ClearPlayerOverrides() -> bool
    Clears all player-specific overrides.

Examples
- Set per-player gradient via HandleColorPickerChange:
    getgenv().TrisESP.HandleColorPickerChange("BoxFill", Color3.fromRGB(0,150,255))

- Toggle health gradient animation off (global):
    getgenv().TrisESP.Settings.HealthGradientEnabled = false

- Make a single player always invisible to ESP (override):
    getgenv().TrisESP.AddPlayerOverride("Enemy", { Enabled = false })

Notes
- Many settings can also be overridden per-player using `AddPlayerOverride`.
- The system persists per-player gradient/phase angles in `getgenv()._TrisESP_Persistent` where supported by the executor.
- If you want help converting an external UI to call these helpers, provide the UI code and I can wire it.
]]

-- Spin integrator & constants
local AUTOROTATE_SPEED = 60 -- degrees per second for fill gradient
local SpinAngle = PERSIST.SpinAngle or RotationAngle -- persistent integrated angle
local MAX_DT = 0.01 -- cap delta to avoid huge single-frame jumps (seconds)

-- Utility functions
-- rainbow removed

local function lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function createGradientSequence(color1, color2, color3)
    return ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(0.5, color2),
        ColorSequenceKeypoint.new(1, color3)
    }
end

-- Convert arbitrary gradient stops (from ulib colorpicker) to a UIGradient
local function stopsToUIGradient(uiGradient, stops, rotation)
    if not stops or #stops == 0 then return end
    local sorted = {}
    for _, s in ipairs(stops) do sorted[#sorted+1] = s end
    table.sort(sorted, function(a, b) return (a.pos or 0) < (b.pos or 0) end)
    if (sorted[1].pos or 0) > 0 then
        table.insert(sorted, 1, { pos = 0, color = sorted[1].color or Color3.new(1,1,1), transp = sorted[1].transp or sorted[1].transparency or 0 })
    end
    if (sorted[#sorted].pos or 0) < 1 then
        sorted[#sorted+1] = { pos = 1, color = sorted[#sorted].color or Color3.new(1,1,1), transp = sorted[#sorted].transp or sorted[#sorted].transparency or 0 }
    end
    local ckp, tkp = {}, {}
    for _, s in ipairs(sorted) do
        ckp[#ckp+1] = ColorSequenceKeypoint.new(s.pos or 0, s.color or Color3.new(1,1,1))
        tkp[#tkp+1] = NumberSequenceKeypoint.new(s.pos or 0, s.transp or s.transparency or 0)
    end
    uiGradient.Color = ColorSequence.new(ckp)
    uiGradient.Transparency = NumberSequence.new(tkp)
    if rotation then uiGradient.Rotation = rotation end
end

-- Build a ColorSequence from gradient stops with a phase offset (for skeleton gradient animation)
local function buildGradientSequenceFromStops(stops, phase)
    phase = phase or 0
    local kps = {}
    for _, s in ipairs(stops) do
        local p = (s.pos + phase) % 1
        table.insert(kps, ColorSequenceKeypoint.new(p, s.color))
    end
    table.sort(kps, function(a, b) return a.Time < b.Time end)
    if kps[1].Time > 0 then
        table.insert(kps, 1, ColorSequenceKeypoint.new(0, kps[#kps].Value))
    end
    if kps[#kps].Time < 1 then
        table.insert(kps, ColorSequenceKeypoint.new(1, kps[1].Value))
    end
    return ColorSequence.new(kps)
end

-- Sample arbitrary gradient stops down to 3 Color3 values (legacy compat)
local function gradientStopsToThree(stops)
    if not stops or #stops == 0 then
        local w = Color3.new(1,1,1); return w, w, w
    end
    local sorted = {}
    for _, s in ipairs(stops) do sorted[#sorted+1] = s end
    table.sort(sorted, function(a, b) return (a.pos or 0) < (b.pos or 0) end)
    local function sampleAt(target)
        if #sorted == 1 then return sorted[1].color end
        for i = 1, #sorted - 1 do
            if target <= sorted[i+1].pos then
                local range = sorted[i+1].pos - sorted[i].pos
                if range <= 0 then return sorted[i].color end
                return lerpColor(sorted[i].color, sorted[i+1].color, (target - sorted[i].pos) / range)
            end
        end
        return sorted[#sorted].color
    end
    return sampleAt(0), sampleAt(0.5), sampleAt(1)
end

-- Sample color from arbitrary gradient stops at a given position [0..1]
local function sampleStopsAtPosition(stops, pos)
    if not stops or #stops == 0 then return Color3.new(1,1,1) end
    local sorted = {}
    for _, s in ipairs(stops) do sorted[#sorted+1] = s end
    table.sort(sorted, function(a, b) return (a.pos or 0) < (b.pos or 0) end)
    if pos <= sorted[1].pos then return sorted[1].color end
    if pos >= sorted[#sorted].pos then return sorted[#sorted].color end
    for i = 1, #sorted - 1 do
        if pos <= sorted[i+1].pos then
            local range = sorted[i+1].pos - sorted[i].pos
            if range <= 0 then return sorted[i].color end
            return lerpColor(sorted[i].color, sorted[i+1].color, (pos - sorted[i].pos) / range)
        end
    end
    return sorted[#sorted].color
end

-- Build a RichText string that colors each character using a rotatable gradient.
-- This method samples the gradient over a 2D circular stripe so rotation affects
-- the output even on a 1D text line.
local function makeGradientText(text, stops, rotationDeg)
    local len = #text
    if len == 0 then return "" end
    local theta = math.rad((rotationDeg or 0) % 360)
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local parts = {}

    for i = 1, len do
        -- Map index into a circle so any rotation produces visible variation.
        local angle = (i - 1) / math.max(1, len - 1) * math.pi * 2
        local x = math.cos(angle)
        local y = math.sin(angle)
        -- Project onto rotated gradient axis (cosT, sinT).
        local proj = x * cosT + y * sinT
        local samplePos = (proj + 1) / 2  -- map [-1,1] → [0,1]
        local color = sampleStopsAtPosition(stops, samplePos)
        local r = math.floor(color.R * 255 + 0.5)
        local g = math.floor(color.G * 255 + 0.5)
        local b = math.floor(color.B * 255 + 0.5)
        local char = text:sub(i, i)
        char = char:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        parts[i] = string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, char)
    end
    return table.concat(parts)
end

local function getEnumFont(fontName)
    if fontName == "Tahoma" then
        return Enum.Font.SourceSans
    elseif fontName == "SourceSansBold" then
        return Enum.Font.SourceSansBold
    elseif fontName == "GothamBold" then
        return Enum.Font.GothamBold
    elseif fontName == "Gotham" then
        return Enum.Font.Gotham
    elseif fontName == "Roboto" then
        return Enum.Font.Roboto
    elseif fontName == "RobotoMono" then
        return Enum.Font.RobotoMono
    elseif fontName == "Ubuntu" then
        return Enum.Font.Ubuntu
    elseif fontName == "Oswald" then
        return Enum.Font.Oswald
    end
    return Enum.Font.Code -- ProggyClean (default)
end

local function getHealthColor(ratio)
    if ratio > 0.75 then
        return Color3.fromRGB(0, 255, 0)
    elseif ratio > 0.5 then
        return Color3.fromRGB(255, 255, 0)
    elseif ratio > 0.25 then
        return Color3.fromRGB(255, 170, 0)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

local function isSameTeam(player1, player2)
    if not player1 or not player2 or player1 == player2 then return false end
    if player1.Team and player2.Team then
        return player1.Team == player2.Team
    end
    return false
end

local function shouldShowPlayer(player)
    if not player or player == LocalPlayer then return false end
    if ESPSettings.TeamCheckEnabled then
        -- hide teammates (standard behaviour)
        if isSameTeam(player, LocalPlayer) then
            return false
        end
        -- hide players on any configured custom team names
        if player.Team then
            for _, tname in ipairs(ESPSettings.CustomTeams or {}) do
                if tostring(player.Team.Name) == tostring(tname) then
                    return false
                end
            end
                -- hide players on any configured team objects (support many types)
                for _, tobj in ipairs(ESPSettings.CustomTeamObjects or {}) do
                    -- direct Team instance
                    if typeof and typeof(tobj) == "Instance" and tobj:IsA("Team") then
                        if player.Team == tobj then return false end
                    end
                    -- if tobj is a Folder/Container with children named after players or containing values
                    if typeof and typeof(tobj) == "Instance" then
                        if tobj:FindFirstChild(player.Name) then return false end
                        -- check for ObjectValue/StringValue children referencing player
                        for _, child in ipairs(tobj:GetChildren()) do
                            if child:IsA("ObjectValue") and child.Value == player then return false end
                            if child:IsA("StringValue") and child.Value == player.Name then return false end
                        end
                    end
                    -- if tobj is a plain table (list of players/names/ids)
                    if type(tobj) == "table" then
                        for _, v in ipairs(tobj) do
                            if v == player or v == player.UserId or v == player.Name then return false end
                        end
                    end
                    -- if tobj is a number (userid)
                    if type(tobj) == "number" and tobj == player.UserId then return false end
                    -- if tobj is a string (team name) handled earlier in CustomTeams loop
                end
        end
    end
    return true
end

local function getScreenRectForCharacter(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local sizingMode = ESPSettings.BoxSizingMode or "Static"

    if sizingMode == "Bounding" then
        -- Dynamic bounding box: project all character part corners to screen space
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local anyVisible = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local corners = {
                    part.CFrame * CFrame.new(-part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
                    part.CFrame * CFrame.new( part.Size.X/2, -part.Size.Y/2, -part.Size.Z/2),
                    part.CFrame * CFrame.new(-part.Size.X/2,  part.Size.Y/2, -part.Size.Z/2),
                    part.CFrame * CFrame.new( part.Size.X/2,  part.Size.Y/2, -part.Size.Z/2),
                    part.CFrame * CFrame.new(-part.Size.X/2, -part.Size.Y/2,  part.Size.Z/2),
                    part.CFrame * CFrame.new( part.Size.X/2, -part.Size.Y/2,  part.Size.Z/2),
                    part.CFrame * CFrame.new(-part.Size.X/2,  part.Size.Y/2,  part.Size.Z/2),
                    part.CFrame * CFrame.new( part.Size.X/2,  part.Size.Y/2,  part.Size.Z/2),
                }
                for _, corner in ipairs(corners) do
                    local sp = Camera:WorldToViewportPoint(corner.Position)
                    if sp.Z > 0 then
                        anyVisible = true
                        minX = math.min(minX, sp.X)
                        minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X)
                        maxY = math.max(maxY, sp.Y)
                    end
                end
            end
        end
        if not anyVisible or minX == math.huge then return nil end
        local w = maxX - minX
        local h = maxY - minY
        if w < 1 or h < 1 then return nil end
        -- Enforce minimum box size
        local minW = ESPSettings.MinBoxWidth or 6
        local minH = ESPSettings.MinBoxHeight or 10
        if w < minW then
            local diff = minW - w
            minX = minX - diff / 2
            maxX = maxX + diff / 2
            w = minW
        end
        if h < minH then
            local diff = minH - h
            minY = minY - diff / 2
            maxY = maxY + diff / 2
            h = minH
        end
        return { x = minX, y = minY, w = w, h = h, cx = minX + w/2, cy = minY + h/2 }
    else
        -- Static mode: use GetBoundingBox for accurate center + fixed width ratio
        local ok, cf, size = pcall(function()
            local c, s = char:GetBoundingBox()
            return c, s
        end)
        if ok and cf and size and size.Y > 0 then
            local halfH = size.Y / 2
            local center = cf.Position
            local topWorld = center + Vector3.new(0, halfH, 0)
            local bottomWorld = center - Vector3.new(0, halfH, 0)
            local spTop = Camera:WorldToViewportPoint(topWorld)
            local spBottom = Camera:WorldToViewportPoint(bottomWorld)
            if spTop.Z > 0 and spBottom.Z > 0 then
                local h = math.abs(spBottom.Y - spTop.Y)
                local widthRatio = ESPSettings.StaticBoxWidth or 0.6
                local w = h * widthRatio
                -- Enforce minimum box size
                local minW = ESPSettings.MinBoxWidth or 6
                local minH = ESPSettings.MinBoxHeight or 10
                if w < minW then w = minW end
                if h < minH then h = minH end
                local cx = (spTop.X + spBottom.X) / 2
                local cy = (spTop.Y + spBottom.Y) / 2
                local x = cx - w / 2
                local y = cy - h / 2
                return { x = x, y = y, w = w, h = h, cx = cx, cy = cy }
            end
        end
        return nil
    end
end

-- Create ESP object
local function createESPObject()
    local container = Instance.new("Frame")
    container.Name = "ESPContainer"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Parent = ESPHolder
    
    local espObj = {
        Container = container,
        Player = nil,
    }
    espObj.GradientAngle = nil
    espObj.OutlineAngle = 0
    
    -- Name label
    local initFont = getEnumFont(ESPSettings.TextFont)
    espObj.Name = Instance.new("TextLabel")
    espObj.Name.Name = "NameLabel"
    espObj.Name.BackgroundTransparency = 1
    espObj.Name.Size = UDim2.new(0, 100, 0, 20)
    espObj.Name.AnchorPoint = Vector2.new(0.5, 0.5)
    espObj.Name.Font = initFont
    espObj.Name.TextSize = 13
    espObj.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    espObj.Name.TextStrokeTransparency = 0
    espObj.Name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.Name.RichText = true
    espObj.Name.Visible = false
    espObj.Name.ZIndex = 10
    espObj.Name.Parent = container
    
    -- Distance label (AnchorPoint top-center so text stays right below the box)
    espObj.Distance = Instance.new("TextLabel")
    espObj.Distance.Name = "DistanceLabel"
    espObj.Distance.BackgroundTransparency = 1
    espObj.Distance.Size = UDim2.new(0, 100, 0, 20)
    espObj.Distance.AnchorPoint = Vector2.new(0.5, 0)
    espObj.Distance.Font = initFont
    espObj.Distance.TextSize = 13
    espObj.Distance.TextColor3 = Color3.fromRGB(255, 255, 255)
    espObj.Distance.RichText = true
    espObj.Distance.TextStrokeTransparency = 0
    espObj.Distance.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.Distance.Visible = false
    espObj.Distance.ZIndex = 10
    espObj.Distance.Parent = container

    -- Custom text entries (external scripts may populate `espObj.CustomTexts`)
    espObj.CustomTexts = {} -- array of strings
    espObj.CustomTextLabels = {} -- generated TextLabel instances
    
    -- Weapon label
    espObj.Weapon = Instance.new("TextLabel")
    espObj.Weapon.Name = "WeaponLabel"
    espObj.Weapon.BackgroundTransparency = 1
    espObj.Weapon.Size = UDim2.new(0, 100, 0, 20)
    espObj.Weapon.AnchorPoint = Vector2.new(0.5, 0.5)
    espObj.Weapon.Font = initFont
    espObj.Weapon.TextSize = 13
    espObj.Weapon.TextColor3 = Color3.fromRGB(255, 255, 255)
    espObj.Weapon.TextStrokeTransparency = 0
    espObj.Weapon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.Weapon.Visible = false
    espObj.Weapon.ZIndex = 10
    espObj.Weapon.Parent = container
    
    espObj.Box = Instance.new("Frame")
    espObj.Box.Name = "ESPBox"
    espObj.Box.BackgroundColor3 = Color3.fromRGB(1, 1, 1)
    espObj.Box.BackgroundTransparency = 1
    espObj.Box.BorderSizePixel = 0
    espObj.Box.Visible = false
    espObj.Box.ZIndex = 1
    espObj.Box.Parent = container

    -- Box outline stroke (always 1px when enabled)
    espObj.BoxOutline = Instance.new("UIStroke")
    espObj.BoxOutline.Name = "BoxOutline"
    -- stroke color will be overridden by gradient logic later; start black for fallback
    espObj.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    espObj.BoxOutline.Thickness = 1
    espObj.BoxOutline.Transparency = 0
    espObj.BoxOutline.LineJoinMode = Enum.LineJoinMode.Miter
    espObj.BoxOutline.Parent = espObj.Box

    -- Box outline gradient (for colored outlines - parented to UIStroke)
    espObj.OutlineGradient = Instance.new("UIGradient")
    espObj.OutlineGradient.Name = "OutlineGradient"
    espObj.OutlineGradient.Enabled = true
    espObj.OutlineGradient.Rotation = -90
    espObj.OutlineGradient.Parent = espObj.BoxOutline

    -- Inner black outline (1px inside the ESP box)
    espObj.BoxInnerOutline = Instance.new("Frame")
    espObj.BoxInnerOutline.Name = "BoxInnerOutline"
    espObj.BoxInnerOutline.BackgroundTransparency = 1
    espObj.BoxInnerOutline.BorderSizePixel = 0
    espObj.BoxInnerOutline.Visible = false
    espObj.BoxInnerOutline.ZIndex = 2
    espObj.BoxInnerOutline.Parent = container
    espObj.BoxInnerStroke = Instance.new("UIStroke")
    espObj.BoxInnerStroke.Color = Color3.fromRGB(0, 0, 0)
    espObj.BoxInnerStroke.Thickness = 1
    espObj.BoxInnerStroke.Transparency = 0
    espObj.BoxInnerStroke.LineJoinMode = Enum.LineJoinMode.Miter
    espObj.BoxInnerStroke.Parent = espObj.BoxInnerOutline

    -- Outer black outline (1px outside the ESP box)
    espObj.BoxOuterOutline = Instance.new("Frame")
    espObj.BoxOuterOutline.Name = "BoxOuterOutline"
    espObj.BoxOuterOutline.BackgroundTransparency = 1
    espObj.BoxOuterOutline.BorderSizePixel = 0
    espObj.BoxOuterOutline.Visible = false
    espObj.BoxOuterOutline.ZIndex = 0
    espObj.BoxOuterOutline.Parent = container
    espObj.BoxOuterStroke = Instance.new("UIStroke")
    espObj.BoxOuterStroke.Color = Color3.fromRGB(0, 0, 0)
    espObj.BoxOuterStroke.Thickness = 1
    espObj.BoxOuterStroke.Transparency = 0
    espObj.BoxOuterStroke.LineJoinMode = Enum.LineJoinMode.Miter
    espObj.BoxOuterStroke.Parent = espObj.BoxOuterOutline

    -- Separate Box Fill frame (completely independent of Box outline)
    espObj.BoxFill = Instance.new("Frame")
    espObj.BoxFill.Name = "BoxFillLayer"
    espObj.BoxFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    espObj.BoxFill.BackgroundTransparency = 1
    espObj.BoxFill.BorderSizePixel = 0
    espObj.BoxFill.Visible = false
    espObj.BoxFill.ZIndex = 0
    espObj.BoxFill.Parent = container

    -- Box fill gradient (independent)
    espObj.BoxGradient = Instance.new("UIGradient")
    espObj.BoxGradient.Name = "FillGradient"
    espObj.BoxGradient.Enabled = true
    espObj.BoxGradient.Rotation = -90
    espObj.BoxGradient.Parent = espObj.BoxFill
    
    -- Tracer line
    espObj.Tracer = Instance.new("Frame")
    espObj.Tracer.Name = "Tracer"
    espObj.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    espObj.Tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    espObj.Tracer.BorderSizePixel = 0
    espObj.Tracer.Visible = false
    espObj.Tracer.ZIndex = 2
    espObj.Tracer.Parent = container
    -- Tracer outline (UIStroke) for a crisp outline around the rotated tracer
    espObj.TracerOutline = Instance.new("UIStroke")
    espObj.TracerOutline.Name = "TracerOutline"
    espObj.TracerOutline.Color = Color3.fromRGB(0, 0, 0)
    espObj.TracerOutline.Thickness = 1
    espObj.TracerOutline.Transparency = 0
    espObj.TracerOutline.LineJoinMode = Enum.LineJoinMode.Miter
    espObj.TracerOutline.Parent = espObj.Tracer
    
    -- Health bar background
    espObj.HealthBarBG = Instance.new("Frame")
    espObj.HealthBarBG.Name = "HealthBarBG"
    espObj.HealthBarBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    espObj.HealthBarBG.BackgroundTransparency = 0
    espObj.HealthBarBG.BorderSizePixel = 1
    espObj.HealthBarBG.BorderColor3 = Color3.fromRGB(0, 0, 0)
    espObj.HealthBarBG.Visible = false
    espObj.HealthBarBG.ZIndex = 3
    espObj.HealthBarBG.Parent = container
    
    -- Health bar fill
    espObj.HealthBar = Instance.new("Frame")
    espObj.HealthBar.Name = "HealthBar"
    espObj.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    espObj.HealthBar.BackgroundTransparency = 0
    espObj.HealthBar.BorderSizePixel = 0
    espObj.HealthBar.Visible = false
    espObj.HealthBar.ZIndex = 4
    espObj.HealthBar.Parent = container
    
    -- Health bar gradient
    espObj.HealthBarGradient = Instance.new("UIGradient")
    espObj.HealthBarGradient.Name = "HealthGradient"
    espObj.HealthBarGradient.Enabled = true
    espObj.HealthBarGradient.Rotation = -90
                espObj.HealthBarGradient.Color = createGradientSequence(
        Color3.fromRGB(200, 0, 0),
        Color3.fromRGB(60, 60, 125),
        Color3.fromRGB(119, 120, 255)
    )
                if ESPSettings.HealthBarPosition == "Bottom" then
                    espObj.HealthBarGradient.Rotation = 0
                else
                    espObj.HealthBarGradient.Rotation = -90
                end
    espObj.HealthBarGradient.Parent = espObj.HealthBar
    
    -- Health text (RichText enabled for per-character gradient coloring)
    espObj.HealthText = Instance.new("TextLabel")
    espObj.HealthText.Name = "HealthText"
    espObj.HealthText.BackgroundTransparency = 1
    espObj.HealthText.Size = UDim2.new(0, 60, 0, 20)
    espObj.HealthText.AnchorPoint = Vector2.new(0.5, 0.5)
    espObj.HealthText.Font = initFont
    espObj.HealthText.TextSize = 13
    espObj.HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    espObj.HealthText.RichText = true
    espObj.HealthText.TextStrokeTransparency = 0
    espObj.HealthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.HealthText.Visible = false
    espObj.HealthText.ZIndex = 10
    espObj.HealthText.Parent = container
    
    -- HP numeric text (combined HP+distance label below the bottom health bar)
    espObj.HPText = Instance.new("TextLabel")
    espObj.HPText.Name = "HPText"
    espObj.HPText.BackgroundTransparency = 1
    espObj.HPText.Size = UDim2.new(0, 120, 0, 18)
    -- AnchorPoint (0.5, 0) means Position Y sets the TOP edge of the label, preventing overlap with the bar
    espObj.HPText.AnchorPoint = Vector2.new(0.5, 0)
    espObj.HPText.Font = initFont
    espObj.HPText.TextSize = 13
    espObj.HPText.TextColor3 = Color3.fromRGB(255, 255, 255)
    espObj.HPText.RichText = true
    espObj.HPText.TextStrokeTransparency = 0
    espObj.HPText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    espObj.HPText.Visible = false
    espObj.HPText.ZIndex = 11
    espObj.HPText.Parent = container
    
    -- Corner boxes (8 frames)
    espObj.Corners = {}
    for i = 1, 8 do
        local corner = Instance.new("Frame")
        corner.Name = "Corner" .. i
        corner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        corner.BorderSizePixel = 0
        corner.Visible = false
        corner.ZIndex = 5
        corner.Parent = container
        espObj.Corners[i] = corner
    end
    
    -- Highlight/Chams
    espObj.Highlight = Instance.new("Highlight")
    espObj.Highlight.Name = "Chams"
    espObj.Highlight.FillTransparency = 0.5
    espObj.Highlight.OutlineTransparency = 0
    espObj.Highlight.FillColor = Color3.fromRGB(0, 170, 255)
    espObj.Highlight.OutlineColor = Color3.fromRGB(0, 170, 255)
    espObj.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    espObj.Highlight.Enabled = false
    espObj.Highlight.Parent = container

    -- Glow effect: outer UIStroke on box frame for glow
    -- Skeleton bone definitions
    local BONES_R15 = {
        { "HumanoidRootPart", "LowerTorso" },
        { "LowerTorso", "UpperTorso" },
        { "UpperTorso", "Head" },
        { "UpperTorso", "LeftUpperArm" },
        { "LeftUpperArm", "LeftLowerArm" },
        { "LeftLowerArm", "LeftHand" },
        { "UpperTorso", "RightUpperArm" },
        { "RightUpperArm", "RightLowerArm" },
        { "RightLowerArm", "RightHand" },
        { "LowerTorso", "LeftUpperLeg" },
        { "LeftUpperLeg", "LeftLowerLeg" },
        { "LeftLowerLeg", "LeftFoot" },
        { "LowerTorso", "RightUpperLeg" },
        { "RightUpperLeg", "RightLowerLeg" },
        { "RightLowerLeg", "RightFoot" },
    }
    local BONES_R6 = {
        { "Torso", "Head" },
        { "Torso", "Left Arm" },
        { "Torso", "Right Arm" },
        { "Torso", "Left Leg" },
        { "Torso", "Right Leg" },
    }

    -- Skeleton bone lines
    espObj.SkeletonBones = {}
    espObj.SkeletonGradientPhase = 0
    local MAX_SKELETON_BONES = #BONES_R15
    for i = 1, MAX_SKELETON_BONES do
        local line = Instance.new("Frame")
        line.Name = "Bone" .. i
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BackgroundColor3 = Color3.new(1, 1, 1)
        line.BorderSizePixel = 0
        line.Visible = false
        line.ZIndex = 6
        line.Parent = container

        local outline = Instance.new("UIStroke")
        outline.Name = "BoneOutline"
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline.Color = Color3.new(0, 0, 0)
        outline.Thickness = 1
        outline.LineJoinMode = Enum.LineJoinMode.Miter
        outline.Parent = line

        local gradient = Instance.new("UIGradient")
        gradient.Name = "BoneGradient"
        gradient.Rotation = 0
        gradient.Enabled = false
        gradient.Parent = line

        espObj.SkeletonBones[i] = { Line = line, Outline = outline, Gradient = gradient }
    end
    espObj._BONES_R15 = BONES_R15
    espObj._BONES_R6 = BONES_R6
    espObj._MAX_SKELETON_BONES = MAX_SKELETON_BONES
    
    return espObj
end

-- Remove ESP
local function removeESP(espObj)
    if not espObj then return end
    if espObj.Container then
        pcall(function() espObj.Container:Destroy() end)
    end
    if espObj.Highlight then
        pcall(function() espObj.Highlight:Destroy() end)
    end
end

-- Hide ESP
local function hideESP(espObj)
    if espObj.Name then espObj.Name.Visible = false end
    if espObj.Distance then espObj.Distance.Visible = false end
    if espObj.Weapon then espObj.Weapon.Visible = false end
    if espObj.Box then espObj.Box.Visible = false end
    if espObj.BoxInnerOutline then espObj.BoxInnerOutline.Visible = false end
    if espObj.BoxOuterOutline then espObj.BoxOuterOutline.Visible = false end
    if espObj.BoxFill then espObj.BoxFill.Visible = false end
    if espObj.Tracer then espObj.Tracer.Visible = false end
    if espObj.TracerOutline then pcall(function() espObj.TracerOutline.Transparency = 1 end) end
    if espObj.HealthBar then espObj.HealthBar.Visible = false end
    if espObj.HealthBarBG then espObj.HealthBarBG.Visible = false end
    if espObj.HealthText then espObj.HealthText.Visible = false end
    if espObj.HPText then espObj.HPText.Visible = false end
    if espObj.CustomTextLabels then
        for _, lbl in ipairs(espObj.CustomTextLabels) do
            lbl.Visible = false
        end
    end
    if espObj.Corners then
        for _, corner in ipairs(espObj.Corners) do
            corner.Visible = false
        end
    end
    if espObj.Highlight then espObj.Highlight.Enabled = false end
    if espObj.SkeletonBones then
        for _, bone in ipairs(espObj.SkeletonBones) do
            bone.Line.Visible = false
        end
    end
end

-- Position tracer line
local function positionTracer(frame, fromX, fromY, toX, toY, thickness)
    local length = math.sqrt((toX - fromX)^2 + (toY - fromY)^2)
    local angle = math.atan2(toY - fromY, toX - fromX)
    
    frame.Size = UDim2.new(0, length, 0, thickness)
    frame.Position = UDim2.new(0, (fromX + toX) / 2, 0, (fromY + toY) / 2)
    frame.Rotation = math.deg(angle)
end

-- Fade function
local function fadeElement(element, distance, maxDistance)
    local transparency = math.max(0.1, 1 - (distance / maxDistance))
    if element:IsA("TextLabel") then
        element.TextTransparency = 1 - transparency
    elseif element:IsA("Frame") then
        element.BackgroundTransparency = 1 - transparency
    elseif element:IsA("Highlight") then
        element.FillTransparency = 1 - transparency
        element.OutlineTransparency = 1 - transparency
    end
end

local addESP -- forward declaration (defined after updateESP)

-- Main update loop
local function updateESP(deltaTime)
    deltaTime = deltaTime or (1/60)
    -- If global ESP Enabled is false, remove/destroy objects (and re-create when re-enabled)
    if not ESPSettings.Enabled then
        if not ESPsCleared then
            for player, espObj in pairs(ESPObjects) do
                pcall(function() removeESP(espObj) end)
            end
            ESPObjects = {}
            ESPsCleared = true
        end
        return
    else
        if ESPsCleared then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    addESP(player)
                end
            end
            ESPsCleared = false
        end
    end

    -- Rotation animation: integrate SpinAngle using deltaTime (with cap) to guarantee continuous spin
    local dt = math.min(deltaTime or (1/60), MAX_DT)
    local speed = ESPSettings.BoxRotationSpeed or 300 -- degrees per second
    if ESPSettings.AnimateBoxRotation then
        SpinAngle = (SpinAngle + speed * dt) % 360
        RotationAngle = SpinAngle
    else
        RotationAngle = -90
    end
    -- persist spin angle across reloads
    PERSIST.SpinAngle = SpinAngle
    -- Note: gradient autorotation will be integrated per-object below using deltaTime


    for player, espObj in pairs(ESPObjects) do
        pcall(function()
            -- per-player setting accessor: checks ESPSettings.PlayerOverrides by UserId or Name
            local function getSetting(key, default)
                if ESPSettings.PlayerOverrides and player then
                    local idKey = tostring(player.UserId)
                    local nameKey = player.Name
                    local overrides = ESPSettings.PlayerOverrides[idKey] or ESPSettings.PlayerOverrides[nameKey]
                    if overrides and overrides[key] ~= nil then
                        return overrides[key]
                    end
                end
                if ESPSettings[key] ~= nil then return ESPSettings[key] end
                return default
            end

            if not shouldShowPlayer(player) then 
                hideESP(espObj) 
                return 
            end
            
            -- update outline rotation angle per-object
            if getSetting("BoxOutlineRotation", ESPSettings.BoxOutlineRotation) then
                local speed = getSetting("BoxOutlineRotationSpeed", ESPSettings.BoxOutlineRotationSpeed or 300)
                espObj.OutlineAngle = ((espObj.OutlineAngle or 0) + speed * dt) % 360
            else
                espObj.OutlineAngle = -90
            end
            
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if not char or not hrp or not hum or hum.Health <= 0 then
                hideESP(espObj)
                return
            end

            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            if distance > getSetting("MaxDistance", ESPSettings.MaxDistance) then
                hideESP(espObj)
                return
            end

            local rect = getScreenRectForCharacter(char)
            if not rect then
                hideESP(espObj)
                return
            end

            local x, y, w, h = rect.x, rect.y, rect.w, rect.h
            local Dist = distance / 3.5714285714
            
            if getSetting("Enabled", ESPSettings.Enabled) then
                local fontEnum = getEnumFont(getSetting("TextFont", ESPSettings.TextFont))
                -- Dynamic text scale factor based on box height (encodes distance)
                local textScale = math.clamp(h / 80, 0.65, 1.0)
                local scaledTextSize = math.max(9, math.floor(13 * textScale))
                -- Consistent pixel gap used above AND below the box for all text labels
                local nameGap = math.max(8, math.floor(scaledTextSize * 1.1))
                -- Text gradients use fixed rotation in degrees.
                local nameStops = espObj.NameStops or ESPSettings.NameGradientStops
                local nameRotation = getSetting("NameGradientRotation", ESPSettings.NameGradientRotation or 0)

                local distGradStops = espObj.DistanceStops or ESPSettings.DistanceGradientStops
                local distRotation = getSetting("DistanceGradientRotation", ESPSettings.DistanceGradientRotation or 0)

                local htGradStops = espObj.HealthTextStops or ESPSettings.HealthTextGradientStops
                local htRotation = getSetting("HealthTextGradientRotation", ESPSettings.HealthTextGradientRotation or 0)

                -- Name
                if getSetting("ShowName", ESPSettings.ShowName) and espObj.Name then
                    local nameText = ""
                    if getSetting("NameMode", ESPSettings.NameMode) == "DisplayName" then
                        nameText = (player.DisplayName or player.Name or "")
                    elseif getSetting("NameMode", ESPSettings.NameMode) == "Both" then
                        nameText = string.format("%s (%s)", (player.DisplayName or ""), (player.Name or ""))
                    else
                        nameText = (player.Name or player.DisplayName or "")
                    end
                    espObj.Name.Text = makeGradientText(nameText, nameStops, nameRotation)
                    espObj.Name.Font = fontEnum
                    espObj.Name.TextSize = scaledTextSize
                    espObj.Name.Position = UDim2.new(0, x + w/2, 0, y - nameGap)
                    espObj.Name.Visible = true
                else
                    if espObj.Name then espObj.Name.Visible = false end
                end
                
                -- Distance label is always hidden here – it is combined into HPText below the box/bar
                if espObj.Distance then espObj.Distance.Visible = false end
                
                -- Weapon (placeholder)
                if espObj.Weapon then
                    espObj.Weapon.Text = "none"
                    espObj.Weapon.Font = fontEnum
                    espObj.Weapon.Position = UDim2.new(0, x + w/2, 0, y + h + 18)
                    espObj.Weapon.Visible = false
                end
                
                -- Box outline (completely separate from BoxFill)
                if getSetting("Boxes", ESPSettings.Boxes) and espObj.Box then
                    if getSetting("BoxType", ESPSettings.BoxType) == "Square" then
                        espObj.Box.Position = UDim2.new(0, x, 0, y)
                        espObj.Box.Size = UDim2.new(0, w, 0, h)
                        espObj.Box.Visible = true
                        -- Inner black outline (1px inside the box)
                        if espObj.BoxInnerOutline then
                            espObj.BoxInnerOutline.Position = UDim2.new(0, x + 1, 0, y + 1)
                            espObj.BoxInnerOutline.Size = UDim2.new(0, math.max(w - 2, 0), 0, math.max(h - 2, 0))
                            espObj.BoxInnerOutline.Visible = true
                        end
                        -- Outer black outline (1px outside the box)
                        if espObj.BoxOuterOutline then
                            espObj.BoxOuterOutline.Position = UDim2.new(0, x - 1, 0, y - 1)
                            espObj.BoxOuterOutline.Size = UDim2.new(0, w + 2, 0, h + 2)
                            espObj.BoxOuterOutline.Visible = true
                        end
                        -- Outline color fallback (used when gradient disabled)
                        -- Force outline thickness to 1px per user request
                        espObj.BoxOutline.Thickness = 1
                        -- Gradient always enabled on the box outline (parented to UIStroke)
                        local outlineStops = espObj.BoxStops or ESPSettings.BoxGradientStops
                        if outlineStops then
                            -- Set UIStroke Color to white so the UIGradient child is not multiplied by a dark color
                            espObj.BoxOutline.Color = Color3.new(1, 1, 1)
                            stopsToUIGradient(espObj.OutlineGradient, outlineStops)
                            espObj.OutlineGradient.Enabled = true
                        else
                            espObj.BoxOutline.Color = getSetting("BoxOutlineColor", ESPSettings.BoxOutlineColor) or Color3.fromRGB(0, 0, 0)
                            espObj.OutlineGradient.Enabled = false
                        end
                        espObj.OutlineGradient.Rotation = espObj.OutlineAngle
                        -- Hide corner frames when square outline in use
                        for _, corner in ipairs(espObj.Corners) do
                            corner.Visible = false
                        end
                    elseif getSetting("BoxType", ESPSettings.BoxType) == "Corner" then
                        espObj.Box.Visible = true
                        espObj.Box.BackgroundTransparency = 1
                        if espObj.BoxInnerOutline then espObj.BoxInnerOutline.Visible = false end
                        if espObj.BoxOuterOutline then espObj.BoxOuterOutline.Visible = false end
                        local cornerLen = math.min(w, h) * 0.25
                        espObj.Corners[1].Position = UDim2.new(0, x, 0, y)
                        espObj.Corners[1].Size = UDim2.new(0, cornerLen, 0, 1)
                        espObj.Corners[1].Visible = true
                        espObj.Corners[2].Position = UDim2.new(0, x, 0, y)
                        espObj.Corners[2].Size = UDim2.new(0, 1, 0, cornerLen)
                        espObj.Corners[2].Visible = true
                        espObj.Corners[3].Position = UDim2.new(0, x + w - cornerLen, 0, y)
                        espObj.Corners[3].Size = UDim2.new(0, cornerLen, 0, 1)
                        espObj.Corners[3].Visible = true
                        espObj.Corners[4].Position = UDim2.new(0, x + w - 1, 0, y)
                        espObj.Corners[4].Size = UDim2.new(0, 1, 0, cornerLen)
                        espObj.Corners[4].Visible = true
                        espObj.Corners[5].Position = UDim2.new(0, x, 0, y + h - 1)
                        espObj.Corners[5].Size = UDim2.new(0, cornerLen, 0, 1)
                        espObj.Corners[5].Visible = true
                        espObj.Corners[6].Position = UDim2.new(0, x, 0, y + h - cornerLen)
                        espObj.Corners[6].Size = UDim2.new(0, 1, 0, cornerLen)
                        espObj.Corners[6].Visible = true
                        espObj.Corners[7].Position = UDim2.new(0, x + w - cornerLen, 0, y + h - 1)
                        espObj.Corners[7].Size = UDim2.new(0, cornerLen, 0, 1)
                        espObj.Corners[7].Visible = true
                        espObj.Corners[8].Position = UDim2.new(0, x + w - 1, 0, y + h - cornerLen)
                        espObj.Corners[8].Size = UDim2.new(0, 1, 0, cornerLen)
                        espObj.Corners[8].Visible = true
                    end
                else
                    if espObj.Box then espObj.Box.Visible = false end
                    if espObj.BoxInnerOutline then espObj.BoxInnerOutline.Visible = false end
                    if espObj.BoxOuterOutline then espObj.BoxOuterOutline.Visible = false end
                    for _, corner in ipairs(espObj.Corners) do corner.Visible = false end
                end

                -- Box Fill (fully independent of Box outline)
                if getSetting("BoxFill", ESPSettings.BoxFill) and espObj.BoxFill then
                    espObj.BoxFill.Position = UDim2.new(0, x, 0, y)
                    espObj.BoxFill.Size = UDim2.new(0, w, 0, h)
                    espObj.BoxFill.Visible = true

                    local animateBox = getSetting("AnimateBoxRotation", ESPSettings.AnimateBoxRotation)
                    local baseRotation = animateBox and (RotationAngle % 360) or -90
                    local rad = math.rad(baseRotation % 360)
                    local absSin = math.abs(math.sin(rad))
                    local absCos = math.abs(math.cos(rad))
                    local perpSpan = w * absSin + h * absCos
                    local averageSpan = (2 / math.pi) * (w + h)
                    if averageSpan == 0 then averageSpan = 1 end
                    local multiplier = perpSpan / averageSpan
                    local effectiveSpeed = AUTOROTATE_SPEED * multiplier

                    if animateBox then
                        espObj.GradientAngle = (espObj.GradientAngle or 0)
                        espObj.GradientAngle = (espObj.GradientAngle + effectiveSpeed * dt) % 360
                        espObj.BoxGradient.Rotation = (baseRotation + espObj.GradientAngle) % 360
                        if espObj.Player and espObj.Player.UserId then
                            PERSIST.GradientAngle[tostring(espObj.Player.UserId)] = espObj.GradientAngle
                        end
                    else
                        -- Ensure no dynamic rotation when animation is disabled
                        if espObj.Player and espObj.Player.UserId then
                            espObj.GradientAngle = PERSIST.GradientAngle[tostring(espObj.Player.UserId)] or (espObj.GradientAngle or 0)
                        else
                            espObj.GradientAngle = espObj.GradientAngle or 0
                        end
                        espObj.BoxGradient.Rotation = (baseRotation) % 360
                    end

                    -- Fill gradient: always use gradient stops
                    local fillStops = espObj.BoxFillStops or ESPSettings.BoxFillGradientStops
                    if fillStops then
                        stopsToUIGradient(espObj.BoxGradient, fillStops)
                        espObj.BoxFill.BackgroundTransparency = 0
                    end
                    espObj.BoxFill.BackgroundColor3 = Color3.new(1, 1, 1)
                else
                    if espObj.BoxFill then espObj.BoxFill.Visible = false end
                end

                -- Health bar

                -- Health bar
                    -- Custom text ESP: create/update right-side stacked labels
                    if espObj.CustomTexts and #espObj.CustomTexts > 0 then
                        local startX = x + w + 6 -- place to the right of the box
                        local lineHeight = 16
                        for i, txt in ipairs(espObj.CustomTexts) do
                            local textStr = tostring(txt or "")
                            local lbl = espObj.CustomTextLabels[i]
                            if not lbl then
                                lbl = Instance.new("TextLabel")
                                lbl.BackgroundTransparency = 1
                                lbl.Font = fontEnum
                                lbl.TextSize = 13
                                lbl.TextColor3 = Color3.fromRGB(255,255,255)
                                lbl.TextStrokeTransparency = 0
                                lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                                lbl.ZIndex = 11
                                lbl.Parent = espObj.Container
                                espObj.CustomTextLabels[i] = lbl
                            end
                            lbl.Font = fontEnum
                            lbl.Text = textStr
                            lbl.Position = UDim2.new(0, startX, 0, y + (i-1) * lineHeight)
                            lbl.Visible = true
                        end
                        -- hide any surplus GUI labels
                        for j = #espObj.CustomTexts + 1, #espObj.CustomTextLabels do
                            if espObj.CustomTextLabels[j] then espObj.CustomTextLabels[j].Visible = false end
                        end
                    end

                    if getSetting("HealthBarEnabled", ESPSettings.HealthBarEnabled) and espObj.HealthBar then
                        local healthRatio = 1
                        if hum.MaxHealth and hum.MaxHealth > 0 then
                            healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        end
                        local barHeight = h * healthRatio

                        -- Use neutral background so gradient displays correctly
                        espObj.HealthBar.BackgroundColor3 = Color3.new(1, 1, 1)
                        -- Animate health gradient upward by shifting keypoint positions
                        local healthAnim = getSetting("HealthGradientEnabled", ESPSettings.HealthGradientEnabled)
                        local speed = getSetting("HealthGradientSpeed", ESPSettings.HealthGradientSpeed) or 0.5 -- cycles per second
                        if healthAnim then
                            espObj.HealthGradientPhase = (espObj.HealthGradientPhase or 0)
                            espObj.HealthGradientPhase = (espObj.HealthGradientPhase + speed * dt) % 1
                            if espObj.Player and espObj.Player.UserId then
                                PERSIST.HealthPhase[tostring(espObj.Player.UserId)] = espObj.HealthGradientPhase
                            end
                        else
                            -- preserve any persisted phase but do not advance it while animation disabled
                            if espObj.Player and espObj.Player.UserId then
                                espObj.HealthGradientPhase = PERSIST.HealthPhase[tostring(espObj.Player.UserId)] or (espObj.HealthGradientPhase or 0)
                            else
                                espObj.HealthGradientPhase = espObj.HealthGradientPhase or 0
                            end
                        end

                        -- Health gradient: always use gradient stops
                        local healthStops = espObj.HealthBarStops or ESPSettings.HealthBarGradientStops
                        local function sampleBase(u)
                            u = (u % 1 + 1) % 1
                            return sampleStopsAtPosition(healthStops, u)
                        end

                        -- Build the health gradient from sampled keypoints so static and animated modes match
                        local sampleCount = 12
                        local samples = {}
                        for i = 0, (sampleCount - 1) do
                            local basePos = i / (sampleCount - 1)
                            -- subtract phase so sampled colors appear to move upward
                            local samplePos = (basePos - (espObj.HealthGradientPhase or 0)) % 1
                            samples[i+1] = { pos = basePos, color = sampleBase(samplePos) }
                        end
                        local cs = {}
                        for _, s in ipairs(samples) do
                            table.insert(cs, ColorSequenceKeypoint.new(s.pos, s.color))
                        end
                        espObj.HealthBarGradient.Color = ColorSequence.new(cs)

                        -- Determine a color sample for the health text (match gradient at filled/top position)
                        local samplePhase = (espObj.HealthGradientPhase or 0)
                        local samplePosForText = (healthRatio - samplePhase) % 1
                        local healthTextColor = sampleBase(samplePosForText)
                        -- Force health bar outline to 1px black (do not change)
                        espObj.HealthBarBG.BorderColor3 = Color3.fromRGB(0, 0, 0)

                        local thickness = getSetting("HealthBarThickness", ESPSettings.HealthBarThickness) or 2.5
                        local padding = 4
                        local posMode = getSetting("HealthBarPosition", ESPSettings.HealthBarPosition) or "Left"

                        -- Gradient rotation every frame
                        espObj.HealthBarGradient.Rotation = (posMode == "Bottom") and 0 or -90

                        -- Build the shared below-box label text
                        local showHPTxt  = getSetting("ShowHealthText", ESPSettings.ShowHealthText)
                        local showDist   = getSetting("ShowDistance",   ESPSettings.ShowDistance)
                        local hpVal      = hum.Health and math.max(0, math.floor(hum.Health)) or 0
                        local maxVal     = hum.MaxHealth or 0
                        -- Show only raw health values, no percentage
                        local hpStr
                        if maxVal > 0 then
                            hpStr = string.format("%d/%d", hpVal, math.floor(maxVal))
                        else
                            hpStr = string.format("%d", hpVal)
                        end
                        local distStr    = string.format("[%d st]", math.floor(Dist))
                        -- Build below-box text with per-label gradients
                        local belowText
                        local belowRich -- RichText version (used when any gradient is enabled)
                        if showHPTxt and showDist then
                            local hpPart   = makeGradientText(hpStr, htGradStops, htRotation)
                            local distPart = makeGradientText(distStr, distGradStops, distRotation)
                            belowText = hpStr .. "  " .. distStr
                            belowRich = hpPart .. "  " .. distPart
                        elseif showHPTxt then
                            belowText = hpStr
                            belowRich = makeGradientText(hpStr, htGradStops, htRotation)
                        elseif showDist then
                            belowText = distStr
                            belowRich = makeGradientText(distStr, distGradStops, distRotation)
                        end

                        if posMode == "Bottom" then
                            -- Horizontal bar below the box
                            local barX = x
                            local barY = y + h + padding
                            local fullWidth = w
                            local filledWidth = math.floor(fullWidth * (healthRatio or 0))

                            if getSetting("HealthOutlineFollow", ESPSettings.HealthOutlineFollow) then
                                espObj.HealthBarBG.Position = UDim2.new(0, barX, 0, barY)
                                espObj.HealthBarBG.Size = UDim2.new(0, filledWidth, 0, thickness)
                            else
                                espObj.HealthBarBG.Position = UDim2.new(0, barX, 0, barY)
                                espObj.HealthBarBG.Size = UDim2.new(0, fullWidth, 0, thickness)
                            end
                            espObj.HealthBar.Position = UDim2.new(0, barX, 0, barY)
                            espObj.HealthBar.Size = UDim2.new(0, filledWidth, 0, thickness)
                            espObj.HealthBarBG.Visible = true
                            espObj.HealthBar.Visible = true

                            -- HPText: same gap below bar as name text uses above box
                            if espObj.HPText then
                                if belowText then
                                    espObj.HPText.Text = belowRich or belowText
                                    espObj.HPText.Font = fontEnum
                                    espObj.HPText.TextSize = scaledTextSize
                                    -- AnchorPoint.Y=0 → Position.Y is TOP of label, preventing overlap
                                    espObj.HPText.Position = UDim2.new(0, barX + fullWidth / 2, 0, barY + thickness + 5)
                                    espObj.HPText.Visible = true
                                else
                                    espObj.HPText.Visible = false
                                end
                            end

                        else
                            -- Vertical bar on left/right
                            local bgX
                            if posMode == "Right" then
                                bgX = x + w + padding
                            else
                                bgX = x - (thickness + padding)
                            end

                            if getSetting("HealthOutlineFollow", ESPSettings.HealthOutlineFollow) then
                                espObj.HealthBarBG.Position = UDim2.new(0, bgX, 0, y + h - barHeight)
                                espObj.HealthBarBG.Size = UDim2.new(0, thickness, 0, barHeight)
                            else
                                espObj.HealthBarBG.Position = UDim2.new(0, bgX, 0, y)
                                espObj.HealthBarBG.Size = UDim2.new(0, thickness, 0, h)
                            end
                            espObj.HealthBar.Position = UDim2.new(0, bgX, 0, y + h - barHeight)
                            espObj.HealthBar.Size = UDim2.new(0, thickness, 0, barHeight)
                            espObj.HealthBarBG.Visible = true
                            espObj.HealthBar.Visible = true

                            -- HPText: same gap below box as name text uses above box, always centered
                            if espObj.HPText then
                                if belowText then
                                    espObj.HPText.Text = belowRich or belowText
                                    espObj.HPText.Font = fontEnum
                                    espObj.HPText.TextSize = scaledTextSize
                                    espObj.HPText.Position = UDim2.new(0, x + w / 2, 0, y + h + 5)
                                    espObj.HPText.Visible = true
                                else
                                    espObj.HPText.Visible = false
                                end
                            end
                        end

                        -- HealthText retired: always hidden (everything is in HPText now)
                        if espObj.HealthText then espObj.HealthText.Visible = false end
                    else
                        -- Health bar disabled
                        if espObj.HealthBar then espObj.HealthBar.Visible = false end
                        if espObj.HealthBarBG then espObj.HealthBarBG.Visible = false end
                        if espObj.HealthText then espObj.HealthText.Visible = false end
                        -- HPText: show distance-only if ShowDistance enabled (no health bar available)
                        if espObj.HPText then
                            local showDist = getSetting("ShowDistance", ESPSettings.ShowDistance)
                            if showDist then
                                local distOnly = string.format("[%d st]", math.floor(Dist))
                                espObj.HPText.Text = makeGradientText(distOnly, distGradStops, distRotation)
                                espObj.HPText.Font = fontEnum
                                espObj.HPText.TextSize = scaledTextSize
                                espObj.HPText.Position = UDim2.new(0, x + w / 2, 0, y + h + 5)
                                espObj.HPText.Visible = true
                            else
                                espObj.HPText.Visible = false
                            end
                        end
                    end
                
                -- Tracer
                if ESPSettings.Tracers and espObj.Tracer then
                    local tracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    if ESPSettings.TracerFrom == "Top" then
                        tracerFrom = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    elseif ESPSettings.TracerFrom == "Center" then
                        tracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    end
                    
                    local tracerTo = Vector2.new(x + w/2, y + h/2)
                    local thickness = ESPSettings.TracerThickness or 2
                    positionTracer(espObj.Tracer, tracerFrom.X, tracerFrom.Y, tracerTo.X, tracerTo.Y, thickness)
                    espObj.Tracer.BackgroundColor3 = ESPSettings.TracerColor
                    espObj.Tracer.Visible = true
                    -- Configure tracer outline if present
                    if espObj.TracerOutline then
                        pcall(function()
                            espObj.TracerOutline.Color = Color3.fromRGB(0,0,0)
                            espObj.TracerOutline.Transparency = 0
                            espObj.TracerOutline.Thickness = math.max(0.5, thickness * 0.6)
                        end)
                    end
                else
                    if espObj.Tracer then espObj.Tracer.Visible = false end
                    if espObj.TracerOutline then pcall(function() espObj.TracerOutline.Transparency = 1 end) end
                end
                
                -- Chams
                if ESPSettings.Highlight and espObj.Highlight then
                    espObj.Highlight.Adornee = char
                    espObj.Highlight.FillColor = ESPSettings.GlobalChamColor
                    espObj.Highlight.OutlineColor = ESPSettings.GlobalChamColor
                    espObj.Highlight.FillTransparency = ESPSettings.FillTransparency
                    espObj.Highlight.OutlineTransparency = ESPSettings.OutlineTransparency
                    espObj.Highlight.Enabled = true
                end

                -- Skeleton ESP
                if getSetting("SkeletonEnabled", ESPSettings.SkeletonEnabled) and espObj.SkeletonBones then
                    local boneList = (char:FindFirstChild("UpperTorso") and espObj._BONES_R15) or (char:FindFirstChild("Torso") and espObj._BONES_R6)
                    if boneList then
                        local skelGradEnabled = getSetting("SkeletonGradientEnabled", ESPSettings.SkeletonGradientEnabled)
                        if skelGradEnabled then
                            espObj.SkeletonGradientPhase = ((espObj.SkeletonGradientPhase or 0) + dt * (ESPSettings.SkeletonGradientSpeed or 0.4)) % 1
                        end
                        local boneColor = getSetting("BoneColor", ESPSettings.BoneColor)
                        local boneThick = getSetting("BoneThickness", ESPSettings.BoneThickness)
                        local outEnabled = getSetting("SkeletonOutlineEnabled", ESPSettings.SkeletonOutlineEnabled)
                        local outColor = getSetting("SkeletonOutlineColor", ESPSettings.SkeletonOutlineColor)
                        local outThick = getSetting("SkeletonOutlineThickness", ESPSettings.SkeletonOutlineThickness)
                        local skelStops = ESPSettings.SkeletonGradientStops

                        for i, boneDef in ipairs(boneList) do
                            local boneObj = espObj.SkeletonBones[i]
                            if not boneObj then continue end
                            local partA = char:FindFirstChild(boneDef[1])
                            local partB = char:FindFirstChild(boneDef[2])
                            if not partA or not partB then
                                boneObj.Line.Visible = false
                                continue
                            end
                            local spA = Camera:WorldToViewportPoint(partA.Position)
                            local spB = Camera:WorldToViewportPoint(partB.Position)
                            if spA.Z <= 0 or spB.Z <= 0 then
                                boneObj.Line.Visible = false
                                continue
                            end
                            -- Position bone line
                            local dx, dy = spB.X - spA.X, spB.Y - spA.Y
                            local length = math.sqrt(dx * dx + dy * dy)
                            boneObj.Line.Size = UDim2.new(0, math.max(1, length), 0, boneThick)
                            boneObj.Line.Position = UDim2.new(0, (spA.X + spB.X) / 2, 0, (spA.Y + spB.Y) / 2)
                            boneObj.Line.Rotation = math.deg(math.atan2(dy, dx))
                            boneObj.Line.Visible = true
                            -- Color / gradient
                            if skelGradEnabled and skelStops and #skelStops >= 2 then
                                boneObj.Gradient.Enabled = true
                                pcall(function()
                                    boneObj.Gradient.Color = buildGradientSequenceFromStops(skelStops, espObj.SkeletonGradientPhase)
                                end)
                                boneObj.Line.BackgroundColor3 = Color3.new(1, 1, 1)
                            else
                                boneObj.Gradient.Enabled = false
                                boneObj.Line.BackgroundColor3 = boneColor
                            end
                            -- Outline
                            boneObj.Outline.Transparency = outEnabled and 0 or 1
                            boneObj.Outline.Color = outColor
                            boneObj.Outline.Thickness = outThick
                        end
                        -- Hide unused bones
                        for i = #boneList + 1, espObj._MAX_SKELETON_BONES do
                            if espObj.SkeletonBones[i] then
                                espObj.SkeletonBones[i].Line.Visible = false
                            end
                        end
                    else
                        for _, bone in ipairs(espObj.SkeletonBones) do bone.Line.Visible = false end
                    end
                else
                    if espObj.SkeletonBones then
                        for _, bone in ipairs(espObj.SkeletonBones) do bone.Line.Visible = false end
                    end
                end
            else
                hideESP(espObj)
            end
        end)
    end
end

-- Add ESP for player
addESP = function(player)
    if ESPObjects[player] then return end
    local espObj = createESPObject()
    espObj.Player = player
    -- Restore persistent phases/angles if available
    if player and player.UserId then
        local id = tostring(player.UserId)
        espObj.HealthGradientPhase = PERSIST.HealthPhase[id] or math.random()
        espObj.GradientAngle = PERSIST.GradientAngle[id] or 0
    else
        espObj.HealthGradientPhase = espObj.HealthGradientPhase or math.random()
        espObj.GradientAngle = espObj.GradientAngle or 0
    end
    -- Copy gradient stops from global settings
    espObj.BoxFillStops = ESPSettings.BoxFillGradientStops
    espObj.BoxStops = ESPSettings.BoxGradientStops
    espObj.HealthBarStops = ESPSettings.HealthBarGradientStops
    espObj.NameStops = ESPSettings.NameGradientStops
    espObj.DistanceStops = ESPSettings.DistanceGradientStops
    espObj.HealthTextStops = ESPSettings.HealthTextGradientStops
    ESPObjects[player] = espObj
end

-- Remove ESP for player
local function removePlayerESP(player)
    local espObj = ESPObjects[player]
    if espObj then
        hideESP(espObj)
        removeESP(espObj)
        ESPObjects[player] = nil
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        addESP(player)
    end
end

-- Player added/removed events
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        addESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

-- Main render loop
renderConn = RunService.RenderStepped:Connect(function(delta)
    updateESP(delta)
end)

-- Global API
getgenv().TrisESP = {
    Settings = ESPSettings,
    Unload = function()
        if renderConn then renderConn:Disconnect() end
        for player, espObj in pairs(ESPObjects) do
            removeESP(espObj)
        end
        ESPObjects = {}
        if ESPHolder then ESPHolder:Destroy() end
    end,

    -- Apply ulib gradient stops directly to a UIGradient instance
    ApplyGradientToUIGradient = stopsToUIGradient,

    -- Handle a ulib ColorPicker callback payload (Color3 or { Stops = [{pos,color,transparency},...] })
    HandleColorPickerChange = function(settingPrefix, payload)
        if not payload then return false end
        local stops
        if typeof and typeof(payload) == "Color3" then
            -- Single color -> convert to uniform 2-stop gradient
            stops = {
                {pos = 0, color = payload, transparency = 0},
                {pos = 1, color = payload, transparency = 0},
            }
        elseif type(payload) == "table" and payload.Stops then
            stops = payload.Stops
        else
            return false
        end
        -- Store globally
        ESPSettings[settingPrefix .. "GradientStops"] = stops
        -- Update all existing ESP objects
        local stopsKey = (settingPrefix == "BoxFill" and "BoxFillStops")
            or (settingPrefix == "Box" and "BoxStops")
            or (settingPrefix == "HealthBar" and "HealthBarStops")
            or (settingPrefix == "Name" and "NameStops")
            or (settingPrefix == "Distance" and "DistanceStops")
            or (settingPrefix == "HealthText" and "HealthTextStops")
            or (settingPrefix == "Skeleton" and "SkeletonStops")
            or nil
        if stopsKey then
            for _, espObj in pairs(ESPObjects) do
                espObj[stopsKey] = stops
            end
        end
        return true
    end,

    -- Helper to resolve a player reference (player object, userId number, or player name)
    _resolvePlayer = function(ref)
        if not ref then return nil end
        if type(ref) == "table" and ref.UserId then return ref end
        if type(ref) == "number" then
            for _,p in ipairs(Players:GetPlayers()) do
                if p.UserId == ref then return p end
            end
            return nil
        elseif type(ref) == "string" then
            return Players:FindFirstChild(ref)
        end
        return nil
    end,

    AddCustomText = function(playerRef, text)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p then return false end
        if not ESPObjects[p] then addESP(p) end
        local esp = ESPObjects[p]
        esp.CustomTexts = esp.CustomTexts or {}
        -- sanitize and limit external input to avoid UI overflow or malicious strings
        local s = tostring(text or "")
        if #s > 200 then
            s = string.sub(s, 1, 200)
        end
        -- trim leading/trailing whitespace
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        table.insert(esp.CustomTexts, s)
        return true
    end,

    RemoveCustomText = function(playerRef, idxOrText)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p or not ESPObjects[p] then return false end
        local esp = ESPObjects[p]
        esp.CustomTexts = esp.CustomTexts or {}
        if type(idxOrText) == "number" then
            if idxOrText >= 1 and idxOrText <= #esp.CustomTexts then
                table.remove(esp.CustomTexts, idxOrText)
                return true
            end
            return false
        else
            for i, v in ipairs(esp.CustomTexts) do
                if v == tostring(idxOrText) then
                    table.remove(esp.CustomTexts, i)
                    return true
                end
            end
            return false
        end
    end,

    ClearCustomText = function(playerRef)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p or not ESPObjects[p] then return false end
        local esp = ESPObjects[p]
        esp.CustomTexts = {}
        return true
    end,

    -- Team utilities
    _resolveTeam = function(ref)
        if not ref then return nil end
        if typeof and typeof(ref) == "Instance" then
            return ref
        end
        if type(ref) == "table" then
            return ref
        end
        if type(ref) == "string" then
            -- try to find a Team by name first
            for _, t in ipairs(Teams:GetTeams()) do
                if t.Name == ref then return t end
            end
            return ref -- fallback to name string
        end
        if type(ref) == "number" then
            return ref
        end
        return nil
    end,

    AddCustomTeam = function(teamRef)
        local t = getgenv().TrisESP._resolveTeam(teamRef)
        if not t then return false end
        if type(t) == "string" then
            ESPSettings.CustomTeams = ESPSettings.CustomTeams or {}
            for _, v in ipairs(ESPSettings.CustomTeams) do if v == t then return true end end
            table.insert(ESPSettings.CustomTeams, t)
            return true
        else
            ESPSettings.CustomTeamObjects = ESPSettings.CustomTeamObjects or {}
            for _, v in ipairs(ESPSettings.CustomTeamObjects) do if v == t then return true end end
            table.insert(ESPSettings.CustomTeamObjects, t)
            return true
        end
    end,

    RemoveCustomTeam = function(teamRef)
        local t = getgenv().TrisESP._resolveTeam(teamRef)
        if not t then return false end
        if type(t) == "string" then
            ESPSettings.CustomTeams = ESPSettings.CustomTeams or {}
            for i, v in ipairs(ESPSettings.CustomTeams) do
                if v == t then table.remove(ESPSettings.CustomTeams, i) return true end
            end
            return false
        else
            ESPSettings.CustomTeamObjects = ESPSettings.CustomTeamObjects or {}
            for i, v in ipairs(ESPSettings.CustomTeamObjects) do
                if v == t then table.remove(ESPSettings.CustomTeamObjects, i) return true end
            end
            return false
        end
    end,

    ClearCustomTeams = function()
        ESPSettings.CustomTeams = {}
        ESPSettings.CustomTeamObjects = {}
        return true
    end,



    -- Player-specific overrides helpers
    AddPlayerOverride = function(playerRef, overrides)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p then return false end
        ESPSettings.PlayerOverrides = ESPSettings.PlayerOverrides or {}
        local key = tostring(p.UserId) or p.Name
        ESPSettings.PlayerOverrides[key] = ESPSettings.PlayerOverrides[key] or {}
        for k, v in pairs(overrides or {}) do
            ESPSettings.PlayerOverrides[key][k] = v
        end
        return true
    end,

    SetPlayerColor = function(playerRef, colorKey, color3)
        -- colorKey examples: "BoxColor", "BoxFillColor", "TracerColor"
        if not colorKey or not color3 then return false end
        return getgenv().TrisESP.AddPlayerOverride(playerRef, { [colorKey] = color3 })
    end,

    GetPlayerOverride = function(playerRef)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p then return nil end
        local key = tostring(p.UserId)
        return (ESPSettings.PlayerOverrides and (ESPSettings.PlayerOverrides[key] or ESPSettings.PlayerOverrides[p.Name])) or nil
    end,

    RemovePlayerOverride = function(playerRef)
        local p = getgenv().TrisESP._resolvePlayer(playerRef)
        if not p then return false end
        local uid = tostring(p.UserId)
        ESPSettings.PlayerOverrides = ESPSettings.PlayerOverrides or {}
        ESPSettings.PlayerOverrides[uid] = nil
        ESPSettings.PlayerOverrides[p.Name] = nil
        return true
    end,

    ClearPlayerOverrides = function()
        ESPSettings.PlayerOverrides = {}
        return true
    end,
}

-- allow module-style loading
return getgenv().TrisESP

