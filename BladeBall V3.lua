--// =========================================================
--// AUTO LMB — COMPACT CIRCLE & 300+ SPEED TRIGGER
--// Added: Smaller Radius Bounds & Fast Parry at >= 300 Speed
--// =========================================================

local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer

--// =========================================================
--// OBFUSCATION HELPERS
--// =========================================================

local ZWS = utf8.char(0x200B)

local function S(str)
    if typeof(str) ~= "string" or str == "" then return str end
    local chars = {}
    local ok = pcall(function()
        for _, code in utf8.codes(str) do
            table.insert(chars, utf8.char(code))
        end
    end)
    if not ok or #chars == 0 then
        for i = 1, #str do
            table.insert(chars, str:sub(i, i))
        end
    end
    return table.concat(chars, ZWS)
end

local function RandName()
    return "R_" .. tostring(math.random(100000, 999999))
end

--// =========================================================
--// CONFIG
--// =========================================================

local Config = {
    Enabled = false,

    -- Reaction Time dalam detik (Jarak / Kecepatan)
    MaxTimeToImpact = 0.35,

    -- Kecepatan bola ekstrem (AUTO LMB / PARRY INSTAN KETIKA SPEED >= 300)
    ExtremeSpeedThreshold = 300,

    -- Kondisi Auto-Spam
    SpamMaxDistance = 40,
    SpamMinSpeed = 240,

    -- Slow Ball Local Feature
    SlowBallEnabled = true,
    SlowBallDistance = 50,
    SlowFactor = 0.5,

    -- Curve Ball Safety Settings
    CurveDotThreshold = 0.3,

    -- Batas visual lingkaran (DIPERKECIL)
    MinRadius = 15,
    MaxRadius = 160,

    -- Reset Cooldown Parried Flag
    ParryCooldown = 0.1,

    -- Visual circle
    ShowCircle = true,
    CircleTransparency = 0.25,

    -- Stealth Humanization
    HumanizeClick = true,
}

--// =========================================================
--// SAFE PARENT
--// =========================================================

local function GetSafeParent()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    if gethui then
        local h = gethui()
        if h then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local safeParent = GetSafeParent()

if getgenv and getgenv()._alUI then
    pcall(function() getgenv()._alUI:Destroy() end)
end

--// =========================================================
--// COLORS
--// =========================================================

local C = {
    Bg = Color3.fromRGB(15, 12, 22),
    HeaderBg = Color3.fromRGB(22, 16, 36),
    Border = Color3.fromRGB(168, 85, 247),
    TextMain = Color3.fromRGB(243, 235, 255),
    TextMuted = Color3.fromRGB(130, 115, 160),
    TrackOff = Color3.fromRGB(30, 24, 42),
    TrackOn = Color3.fromRGB(168, 85, 247),
    KnobOff = Color3.fromRGB(90, 75, 115),
    KnobOn = Color3.fromRGB(255, 255, 255),
    Green = Color3.fromRGB(52, 211, 153),
    Accent = Color3.fromRGB(255, 80, 110),
}

--// =========================================================
--// GUI
--// =========================================================

local gui = Instance.new("ScreenGui")
gui.Name = RandName()
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    pcall(syn.protect_gui, gui)
elseif protectgui then
    pcall(protectgui, gui)
end
gui.Parent = safeParent
if getgenv then getgenv()._alUI = gui end

local main = Instance.new("Frame")
main.Name = RandName()
main.Size = UDim2.new(0, 300, 0, 140)
main.Position = UDim2.new(0.5, -150, 0.45, -70)
main.BackgroundColor3 = C.Bg
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = C.Border
mainStroke.Thickness = 1.2

-- Header
local header = Instance.new("Frame")
header.Name = RandName()
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = C.HeaderBg
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

local headerFix = Instance.new("Frame")
headerFix.Name = RandName()
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = C.HeaderBg
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Name = RandName()
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = S("AUTO LMB — SMALL CIRCLE (300+)")
title.TextColor3 = C.Border
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = RandName()
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = C.TextMuted
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header
closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- Draggable
do
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Toggle UI
local toggleRow = Instance.new("Frame")
toggleRow.Name = RandName()
toggleRow.Size = UDim2.new(1, -20, 0, 32)
toggleRow.Position = UDim2.new(0, 10, 0, 36)
toggleRow.BackgroundTransparency = 1
toggleRow.Parent = main

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Name = RandName()
toggleLabel.Size = UDim2.new(1, -60, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = S("Enable")
toggleLabel.TextColor3 = C.TextMain
toggleLabel.TextSize = 12
toggleLabel.Font = Enum.Font.GothamMedium
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

local track = Instance.new("TextButton")
track.Name = RandName()
track.Size = UDim2.new(0, 36, 0, 18)
track.Position = UDim2.new(1, -44, 0.5, -9)
track.BackgroundColor3 = C.TrackOff
track.AutoButtonColor = false
track.Text = ""
track.Parent = toggleRow
Instance.new("UICorner", track).CornerRadius = UDim.new(0, 9)

local trackStroke = Instance.new("UIStroke", track)
trackStroke.Color = Color3.fromRGB(50, 38, 72)
trackStroke.Thickness = 1

local knob = Instance.new("Frame")
knob.Name = RandName()
knob.Size = UDim2.new(0, 14, 0, 14)
knob.Position = UDim2.new(0, 2, 0.5, -7)
knob.BackgroundColor3 = C.KnobOff
knob.BorderSizePixel = 0
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 3)

local function UpdateToggle(state)
    local pos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local tc = state and C.TrackOn or C.TrackOff
    local kc = state and C.KnobOn or C.KnobOff
    local sc = state and Color3.fromRGB(120, 68, 185) or Color3.fromRGB(50, 38, 72)
    TweenService:Create(knob, TweenInfo.new(0.18), { Position = pos, BackgroundColor3 = kc }):Play()
    TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = tc }):Play()
    TweenService:Create(trackStroke, TweenInfo.new(0.18), { Color = sc }):Play()
end

track.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    UpdateToggle(Config.Enabled)
end)

-- Status Labels
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Name = RandName()
radiusLabel.Size = UDim2.new(1, -20, 0, 18)
radiusLabel.Position = UDim2.new(0, 10, 0, 76)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = S("Radius: -- | Speed: --")
radiusLabel.TextColor3 = C.TextMuted
radiusLabel.TextSize = 10
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = main

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = RandName()
statusLabel.Size = UDim2.new(1, -20, 0, 18)
statusLabel.Position = UDim2.new(0, 10, 0, 96)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = S("Idle")
statusLabel.TextColor3 = C.TextMuted
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local footer = Instance.new("TextLabel")
footer.Name = RandName()
footer.Size = UDim2.new(1, -20, 0, 12)
footer.Position = UDim2.new(0, 10, 1, -16)
footer.BackgroundTransparency = 1
footer.Text = S("RS=UI | DEL=OFF")
footer.TextColor3 = Color3.fromRGB(70, 60, 90)
footer.TextSize = 9
footer.Font = Enum.Font.Gotham
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = main

--// =========================================================
--// PERMANENT CIRCLE VISUAL
--// =========================================================

local circleAdorn = Instance.new("CylinderHandleAdornment")
circleAdorn.Name = RandName()
circleAdorn.Height = 0.05
circleAdorn.Radius = Config.MinRadius
circleAdorn.InnerRadius = math.max(0.1, Config.MinRadius - 0.3)
circleAdorn.Color3 = Color3.fromRGB(170, 80, 255)
circleAdorn.Transparency = Config.CircleTransparency
circleAdorn.AlwaysOnTop = true
circleAdorn.ZIndex = 5
circleAdorn.CFrame = CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0, 2.7)
circleAdorn.Visible = false
circleAdorn.Parent = gui

--// =========================================================
--// LOGICAL DETECTORS & SLOW BALL OVERRIDE
--// =========================================================

local Parried = false
local LastParryTime = 0

local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function GetRealBall()
    local ballsFolder = workspace:FindFirstChild("Balls")
    if not ballsFolder then return nil end
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            return ball
        end
    end
    return nil
end

local function GetBallVelocity(ball)
    if not ball then return Vector3.zero end
    local zoomies = ball:FindFirstChild("zoomies")
    if zoomies then
        if zoomies:IsA("Vector3Value") then return zoomies.Value end
        if zoomies:IsA("LinearVelocity") then return zoomies.VectorVelocity end
    end
    return ball.AssemblyLinearVelocity or Vector3.zero
end

local function ApplySlowBall(ball)
    if not ball then return end
    local zoomies = ball:FindFirstChild("zoomies")
    if zoomies then
        if zoomies:IsA("Vector3Value") then
            zoomies.Value = zoomies.Value * Config.SlowFactor
        elseif zoomies:IsA("LinearVelocity") then
            zoomies.VectorVelocity = zoomies.VectorVelocity * Config.SlowFactor
        end
    end
    if ball.AssemblyLinearVelocity then
        ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity * Config.SlowFactor
    end
end

local function IsMovingTowardsPlayer(ball, hrp)
    local ballVel = GetBallVelocity(ball)
    if ballVel.Magnitude <= 1 then return true end

    local dirToPlayer = (hrp.Position - ball.Position).Unit
    local ballDirection = ballVel.Unit

    local dot = ballDirection:Dot(dirToPlayer)
    return dot >= Config.CurveDotThreshold
end

local HasMouse1Click = (type(mouse1click) == "function")
local HasMouseMove = (type(mousemoverel) == "function")

local function TriggerParry()
    if Config.HumanizeClick and HasMouseMove then
        task.spawn(function()
            mousemoverel(math.random(-1, 1), math.random(-1, 1))
        end)
    end

    if HasMouse1Click then
        mouse1click()
    elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
        mouse1press()
        task.defer(mouse1release)
    else
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.defer(function()
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

--// =========================================================
--// MAIN LOOP (PreSimulation)
--// =========================================================

local lastUIUpdate = 0

RunService.PreSimulation:Connect(function()
    local hrp = GetHRP()

    if circleAdorn and hrp then
        circleAdorn.Adornee = hrp
        if Config.ShowCircle then circleAdorn.Visible = true end
    end

    if not Config.Enabled or not hrp then return end

    local ball = GetRealBall()
    if not ball then return end

    local ballVelocity = GetBallVelocity(ball)
    local speed = ballVelocity.Magnitude
    local distance = (hrp.Position - ball.Position).Magnitude
    
    local timeToImpact = (speed > 0) and (distance / speed) or math.huge

    -- PERKECIL UKURAN LINGKARAN DENGAN CLAMP BARU
    local dynamicRadius = math.clamp(speed * Config.MaxTimeToImpact, Config.MinRadius, Config.MaxRadius)
    if circleAdorn and Config.ShowCircle then
        circleAdorn.Radius = dynamicRadius
        circleAdorn.InnerRadius = math.max(0.1, dynamicRadius - 0.4)
    end

    if Parried and (os.clock() - LastParryTime) >= Config.ParryCooldown then
        Parried = false
    end

    local isTargeting = (ball:GetAttribute("target") == LocalPlayer.Name) or (ball:GetAttribute("target") == LocalPlayer.DisplayName)

    if isTargeting then
        if Config.SlowBallEnabled and distance <= Config.SlowBallDistance and speed > 100 then
            ApplySlowBall(ball)
        end

        local isHeadingToUs = IsMovingTowardsPlayer(ball, hrp)

        -- KONDISI 1: Auto-Spam LMB (Jarak < 40 DAN Kecepatan > 240)
        if distance < Config.SpamMaxDistance and speed > Config.SpamMinSpeed then
            TriggerParry()
            Parried = true
            LastParryTime = os.clock()

        -- KONDISI 2: Auto LMB Kecepatan 300 ke atas (Langsung Trigger Instan)
        elseif speed >= Config.ExtremeSpeedThreshold and not Parried and isHeadingToUs then
            TriggerParry()
            Parried = true
            LastParryTime = os.clock()

        -- KONDISI 3: Normal Parry (Berdasarkan Lingkaran / Waktu Diterima)
        elseif not Parried and isHeadingToUs and (timeToImpact <= Config.MaxTimeToImpact or distance <= dynamicRadius) then
            TriggerParry()
            Parried = true
            LastParryTime = os.clock()
        end
    end

    local now = os.clock()
    if now - lastUIUpdate > 0.1 then
        lastUIUpdate = now
        radiusLabel.Text = S("Radius: " .. math.floor(dynamicRadius) .. " | Speed: " .. math.floor(speed))
        if isTargeting then
            if distance < Config.SpamMaxDistance and speed > Config.SpamMinSpeed then
                statusLabel.Text = S("SPAMMING!")
                statusLabel.TextColor3 = C.Green
            elseif speed >= Config.ExtremeSpeedThreshold then
                statusLabel.Text = S("FAST BALL (300+)")
                statusLabel.TextColor3 = C.Green
            else
                statusLabel.Text = S("TARGETED")
                statusLabel.TextColor3 = C.Accent
            end
        else
            statusLabel.Text = S("Watching...")
            statusLabel.TextColor3 = C.TextMuted
        end
    end
end)

--// =========================================================
--// KEYBINDS & TOGGLES
--// =========================================================

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Config.Enabled = not Config.Enabled
        UpdateToggle(Config.Enabled)
    end
end)

UpdateToggle(Config.Enabled)