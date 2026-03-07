--[[
    TrisROCKS FOV Circle System
    
    ScreenGui-based FOV circle with:
      • Per-segment gradient coloring (wrapping rainbow or custom stops)
    • Smooth appearance by default (high segment count + rounded caps)
      • Pulse effect (radius oscillates with a sine wave)
      • Optional semi-transparent fill circle
      • Outline (black shadow circle drawn behind the main circle)
      • Center dot
      • Follows mouse or stays at screen center
      • Clean hot-reload: destroys previous instance before rebuilding

    Usage:
        loadstring(game:HttpGet("YOUR_URL_HERE"))()
        
        -- Toggle on and set radius
        getgenv().TrisROCKS_FOV.Settings.Enabled = true
        getgenv().TrisROCKS_FOV.Settings.Radius  = 150
        
        -- Custom gradient (called at any time)
        getgenv().TrisROCKS_FOV.SetGradientStops({
            {pos=0,   color=Color3.fromRGB(255,0,128)},
            {pos=0.5, color=Color3.fromRGB(0,255,128)},
            {pos=1,   color=Color3.fromRGB(255,0,128)},
        })

    API table:  getgenv().TrisROCKS_FOV
--]]

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ── Settings ─────────────────────────────────────────────────────────────────

local Settings = {
    Enabled = false,

    -- Geometry
    Radius   = 150,    -- base radius in pixels
    Segments = 128,     -- base segment count (3–256); higher = smoother circle
    Thickness = 1.5,   -- pixel width of each segment

    -- Gradient coloring
    GradientEnabled  = true,
    GradientStops    = {
        {pos = 0,     color = Color3.fromRGB(255,   0, 128)},
        {pos = 0.25,  color = Color3.fromRGB(255, 200,   0)},
        {pos = 0.5,   color = Color3.fromRGB(  0, 255, 128)},
        {pos = 0.75,  color = Color3.fromRGB(  0, 128, 255)},
        {pos = 1,     color = Color3.fromRGB(255,   0, 128)},  -- closes the loop
    },
    -- Rotate the gradient around the circle over time
    GradientSpinEnabled = true,
    GradientSpinSpeed   = 0.4,   -- full rotations per second
    -- Flat color used when GradientEnabled = false
    FlatColor = Color3.fromRGB(255, 255, 255),
    -- Overall opacity of the main circle (0 = invisible, 1 = opaque)
    Opacity = 0.85,

    -- Pulse: smoothly oscillate the radius with a sine wave
    PulseEnabled   = false,
    PulseAmplitude = 15,   -- max extra radius in pixels
    PulseSpeed     = 2,    -- oscillations per second

    -- Fill: semi-transparent circle behind the main ring
    FillEnabled      = false,
    FillColor        = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.88,  -- 0 = solid, 1 = invisible

    -- Outline: slightly-larger dark circle drawn just below the main ring
    OutlineEnabled   = true,
    OutlineColor     = Color3.fromRGB(0, 0, 0),
    OutlineOpacity   = 1,     -- 0-1
    OutlineThickness = 1,     -- added pixels on top of Thickness for the outline ring

    -- Center dot
    CenterDotEnabled  = false,
    CenterDotRadius   = 3,
    CenterDotColor    = Color3.fromRGB(255, 255, 255),
    CenterDotOpacity  = 0.9,

    -- Position mode: "Mouse" (default) or "Center" (screen center)
    FollowMouse = true,
}

-- ── Persistent state across hot-reloads ──────────────────────────────────────

getgenv()._TrisROCKS_FOV_Persist = getgenv()._TrisROCKS_FOV_Persist or {}
local PERSIST = getgenv()._TrisROCKS_FOV_Persist
PERSIST.GradientPhase = PERSIST.GradientPhase or 0
PERSIST.PulsePhase    = PERSIST.PulsePhase    or 0

-- ── Cleanup previous instance ─────────────────────────────────────────────────

if getgenv()._TrisROCKS_FOV_Cleanup then
    pcall(getgenv()._TrisROCKS_FOV_Cleanup)
    getgenv()._TrisROCKS_FOV_Cleanup = nil
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────

local FOVHolder = Instance.new("ScreenGui")
FOVHolder.Name          = "TrisROCKS_FOVHolder"
FOVHolder.ResetOnSpawn  = false
FOVHolder.IgnoreGuiInset = true
FOVHolder.DisplayOrder  = 100
pcall(function() FOVHolder.Parent = CoreGui end)
if not FOVHolder.Parent then
    FOVHolder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function lerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

-- Sample a wrapping gradient (pos 0..1, looping)
local function sampleGradient(stops, pos)
    if not stops or #stops == 0 then return Color3.new(1, 1, 1) end
    pos = (pos % 1 + 1) % 1

    -- Build a sorted copy; append first color at 1 to close the loop
    local s = {}
    for _, v in ipairs(stops) do s[#s + 1] = v end
    table.sort(s, function(a, b) return (a.pos or 0) < (b.pos or 0) end)
    if (s[#s].pos or 0) < 1 then
        s[#s + 1] = {pos = 1, color = s[1].color}
    end

    if pos <= (s[1].pos or 0) then return s[1].color end
    for i = 1, #s - 1 do
        local p0, p1 = s[i].pos or 0, s[i + 1].pos or 0
        if pos <= p1 then
            local range = p1 - p0
            if range <= 0 then return s[i].color end
            return lerpColor(s[i].color, s[i + 1].color, (pos - p0) / range)
        end
    end
    return s[#s].color
end

-- Position a Frame as a pixel-thin line segment between two screen points
local function positionSegment(f, p1, p2, thickness)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.5 then
        f.Size = UDim2.fromOffset(0, 0)
        return
    end
    local cx = (p1.X + p2.X) * 0.5
    local cy = (p1.Y + p2.Y) * 0.5
    f.Position = UDim2.fromOffset(cx - len * 0.5, cy - thickness * 0.5)
    f.Size     = UDim2.fromOffset(math.ceil(len + 0.5), math.max(1, math.ceil(thickness)))
    f.Rotation = math.deg(math.atan2(dy, dx))
end

-- ── GUI elements ─────────────────────────────────────────────────────────────

local MAX_SEGS = 256

local circleContainer = Instance.new("Frame")
circleContainer.Name                  = "FOVCircle"
circleContainer.BackgroundTransparency = 1
circleContainer.Size                  = UDim2.new(1, 0, 1, 0)
circleContainer.ZIndex                = 100
circleContainer.Parent                = FOVHolder

-- Segment pools: [1..MAX_SEGS]
local mainSegs    = {}
local outlineSegs = {}

local function getOrCreateSeg(pool, idx, isOutline)
    if pool[idx] then return pool[idx] end
    local f = Instance.new("Frame")
    f.Name              = (isOutline and "OL" or "Seg") .. idx
    f.BorderSizePixel   = 0
    f.AnchorPoint       = Vector2.new(0, 0.5)
    f.BackgroundColor3  = Color3.new(1, 1, 1)
    f.ZIndex            = isOutline and 100 or 101
    f.Parent            = circleContainer
    -- add rounded corners so adjacent segments blend smoothly
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0.5, 0)
    uc.Parent = f
    pool[idx]           = f
    return f
end

-- Fill circle
local fillFrame = Instance.new("Frame")
fillFrame.Name                  = "FOVFill"
fillFrame.BorderSizePixel       = 0
fillFrame.BackgroundTransparency = 1
fillFrame.ZIndex                = 99
fillFrame.Parent                = circleContainer
do
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0.5, 0)
    uc.Parent = fillFrame
end

-- Center dot
local centerDot = Instance.new("Frame")
centerDot.Name              = "FOVCenterDot"
centerDot.BorderSizePixel   = 0
centerDot.BackgroundColor3  = Color3.new(1, 1, 1)
centerDot.AnchorPoint       = Vector2.new(0.5, 0.5)
centerDot.ZIndex            = 102
centerDot.Parent            = circleContainer
do
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0.5, 0)
    uc.Parent = centerDot
end

-- ── Segment count bookkeeping ─────────────────────────────────────────────────

local prevSegCount = 0

local function hideExcess(count)
    for i = count + 1, prevSegCount do
        if mainSegs[i]    then mainSegs[i].Visible    = false end
        if outlineSegs[i] then outlineSegs[i].Visible = false end
    end
    prevSegCount = math.max(prevSegCount, count)
end

-- ── Render loop ──────────────────────────────────────────────────────────────

local gradientPhase = PERSIST.GradientPhase
local pulsePhase    = PERSIST.PulsePhase
local renderConn

local function startLoop()
    if renderConn then return end
    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not Settings.Enabled then
            circleContainer.Visible = false
            return
        end
        circleContainer.Visible = true

        local cam          = workspace.CurrentCamera
        local viewSize     = cam.ViewportSize

        -- Center coordinates
        local cx, cy
        if Settings.FollowMouse then
            local mp = UserInputService:GetMouseLocation()
            cx, cy = mp.X, mp.Y
        else
            cx, cy = viewSize.X * 0.5, viewSize.Y * 0.5
        end

        -- Pulse
        if Settings.PulseEnabled then
            pulsePhase = pulsePhase + dt * Settings.PulseSpeed * (2 * math.pi)
            PERSIST.PulsePhase = pulsePhase
        end
        local pulse  = Settings.PulseEnabled
            and (Settings.PulseAmplitude * ((math.sin(pulsePhase) + 1) * 0.5))
            or 0
        local radius = math.max(1, Settings.Radius + pulse)

        -- Gradient spin
        if Settings.GradientSpinEnabled then
            gradientPhase = (gradientPhase + dt * Settings.GradientSpinSpeed) % 1
            PERSIST.GradientPhase = gradientPhase
        end

        -- number of segments: use user value but ensure at least one per pixel of radius
        local segs      = math.clamp(math.floor(Settings.Segments), 3, MAX_SEGS)
        -- if radius is large, boost segment count for smoothness
        if radius > segs then
            segs = math.clamp(math.ceil(radius), segs, MAX_SEGS)
        end
        local thickness = math.max(1, Settings.Thickness)
        local outThick  = thickness + math.max(0, Settings.OutlineThickness)
        local TAU       = 2 * math.pi

        -- Precompute all circle points
        local pts = {}
        for i = 0, segs do
            local a = (i / segs) * TAU
            pts[i] = Vector2.new(cx + math.cos(a) * radius, cy + math.sin(a) * radius)
        end

        -- Fill
        if Settings.FillEnabled then
            local d = radius * 2
            fillFrame.Position             = UDim2.fromOffset(cx - radius, cy - radius)
            fillFrame.Size                 = UDim2.fromOffset(d, d)
            fillFrame.BackgroundColor3     = Settings.FillColor
            fillFrame.BackgroundTransparency = Settings.FillTransparency
            fillFrame.Visible              = true
        else
            fillFrame.Visible = false
        end

        -- Draw segments
        for i = 0, segs - 1 do
            local idx = i + 1
            local p1  = pts[i]
            local p2  = pts[i + 1]

            -- Color = sample gradient at this segment's angular fraction + spin offset
            local gradPos = ((i / segs) + (Settings.GradientSpinEnabled and gradientPhase or 0)) % 1
            local color   = Settings.GradientEnabled
                and sampleGradient(Settings.GradientStops, gradPos)
                or  Settings.FlatColor

            -- Outline segment (drawn first so it sits below the main ring)
            if Settings.OutlineEnabled then
                local ol = getOrCreateSeg(outlineSegs, idx, true)
                positionSegment(ol, p1, p2, outThick)
                ol.BackgroundColor3     = Settings.OutlineColor
                ol.BackgroundTransparency = 1 - Settings.OutlineOpacity
                ol.Visible              = true
            else
                if outlineSegs[idx] then outlineSegs[idx].Visible = false end
            end

            -- Main segment
            local ms = getOrCreateSeg(mainSegs, idx, false)
            positionSegment(ms, p1, p2, thickness)
            ms.BackgroundColor3     = color
            ms.BackgroundTransparency = 1 - Settings.Opacity
            ms.Visible              = true
        end

        hideExcess(segs)

        -- Center dot
        if Settings.CenterDotEnabled then
            local d = Settings.CenterDotRadius * 2
            centerDot.Position             = UDim2.fromOffset(cx, cy)
            centerDot.Size                 = UDim2.fromOffset(d, d)
            centerDot.BackgroundColor3     = Settings.CenterDotColor
            centerDot.BackgroundTransparency = 1 - Settings.CenterDotOpacity
            centerDot.Visible              = true
        else
            centerDot.Visible = false
        end
    end)
end

local function stopLoop()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end

startLoop()

-- ── Hot-reload cleanup callback ───────────────────────────────────────────────

getgenv()._TrisROCKS_FOV_Cleanup = function()
    stopLoop()
    pcall(function() FOVHolder:Destroy() end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

getgenv().TrisROCKS_FOV = {
    Settings = Settings,

    Enable = function()
        Settings.Enabled = true
    end,

    Disable = function()
        Settings.Enabled = false
        circleContainer.Visible = false
    end,

    Toggle = function()
        Settings.Enabled = not Settings.Enabled
        if not Settings.Enabled then circleContainer.Visible = false end
    end,

    -- Replace gradient stops at runtime
    SetGradientStops = function(stops)
        Settings.GradientStops    = stops
        Settings.GradientEnabled  = true
    end,

    -- Switch to a single flat color (disables gradient)
    SetColor = function(color)
        Settings.FlatColor        = color
        Settings.GradientEnabled  = false
    end,

    -- Quick-set helpers
    SetRadius   = function(r) Settings.Radius    = r end,
    SetThickness = function(t) Settings.Thickness = t end,
    SetSegments = function(n) Settings.Segments  = n end,
    SetOpacity  = function(o) Settings.Opacity   = o end,

    -- Enable pulse with given amplitude (px) and speed (Hz)
    SetPulse = function(amplitude, speed)
        Settings.PulseEnabled   = true
        Settings.PulseAmplitude = amplitude or 15
        Settings.PulseSpeed     = speed     or 2
    end,

    -- Restart the render loop (useful after executor hot-reload)
    Restart = function()
        stopLoop()
        startLoop()
    end,
}
