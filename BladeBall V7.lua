--// =========================================================
--// AUTO LMB — ANTI-CURVE + SLOW BALL FIX + MACRO + SAFE MINI UI
--// =========================================================

local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local LocalPlayer = Players.LocalPlayer

--// OBFUSCATION HELPERS
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

--// CONFIG
local Config = {
    Enabled = false,
    MacroEnabled = false,
    MacroDelay = 0.0001,         -- Delay spam LMB 0.1 ms (0.0001 detik)

    BaseTimeToImpact = 0.25,     -- Waktu reaksi dasar tetap (tanpa Ping)
    ExtremeSpeedThreshold = 300, -- Batas kecepatan bola ekstrem
    FastBonusTime = 0.05,        -- Bonus waktu reaksi saat speed >= 300

    -- Perbaikan Bola Lambat (Mencegah bola kena badan duluan)
    HitboxOffset = 5.0,          -- Jarak permukaan badan + radius bola (studs)
    SlowSpeedThreshold = 80,     -- Batas kecepatan yang dianggap bola lambat
    SlowBonusTime = 0.05,        -- Tambahan waktu reaksi khusus saat bola lambat

    -- Pengaturan Anti-Curve Ball
    StrictDotThreshold = 0.68,   -- Syarat sudut saat bola masih jauh
    CloseDotThreshold = 0.20,    -- Syarat sudut saat bola sudah dekat
    CurveSensitivity = 0.35,     -- Penahan parry saat bola melengkung tajam

    -- Auto-Spam
    SpamMaxDistance = 31,
    SpamMinSpeed = 240,

    MinRadius = 15,
    MaxRadius = 145,
    FallbackReset = 1.2,
    ShowCircle = true,
    HumanizeClick = true,
}

--// SAFE PARENT & CLEANUP
local function GetSafeParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

if getgenv and getgenv()._alUI then
    pcall(function() getgenv()._alUI:Destroy() end)
end

--// LIGHTWEIGHT SAFE UI
local gui = Instance.new("ScreenGui")
gui.Name = RandName()
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    pcall(syn.protect_gui, gui)
elseif protectgui then
    pcall(protectgui, gui)
end
gui.Parent = GetSafeParent()
if getgenv then getgenv()._alUI = gui end

local main = Instance.new("Frame")
main.Name = RandName()
main.Size = UDim2.new(0, 200, 0, 94)
main.Position = UDim2.new(0.5, -100, 0.12, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(168, 85, 247)
stroke.Thickness = 1.2

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = RandName()
toggleBtn.Size = UDim2.new(1, -16, 0, 26)
toggleBtn.Position = UDim2.new(0, 8, 0, 8)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
toggleBtn.AutoButtonColor = false
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.TextColor3 = Color3.fromRGB(243, 235, 255)
toggleBtn.Text = S("ENABLE : OFF [DEL]")
toggleBtn.Parent = main
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)

local macroBtn = Instance.new("TextButton")
macroBtn.Name = RandName()
macroBtn.Size = UDim2.new(1, -16, 0, 26)
macroBtn.Position = UDim2.new(0, 8, 0, 38)
macroBtn.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
macroBtn.AutoButtonColor = false
macroBtn.Font = Enum.Font.GothamBold
macroBtn.TextSize = 11
macroBtn.TextColor3 = Color3.fromRGB(243, 235, 255)
macroBtn.Text = S("MACRO [HOLD E] : OFF")
macroBtn.Parent = main
Instance.new("UICorner", macroBtn).CornerRadius = UDim.new(0, 5)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = RandName()
statusLabel.Size = UDim2.new(1, -16, 0, 18)
statusLabel.Position = UDim2.new(0, 8, 0, 70)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextColor3 = Color3.fromRGB(130, 115, 160)
statusLabel.Text = S("Idle | R:-- | S:--")
statusLabel.Parent = main

--// SAFE MANUAL DRAG
do
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// CIRCLE VISUAL
local circleAdorn = Instance.new("CylinderHandleAdornment")
circleAdorn.Name = RandName()
circleAdorn.Height = 0.05
circleAdorn.Radius = Config.MinRadius
circleAdorn.InnerRadius = Config.MinRadius - 0.3
circleAdorn.Color3 = Color3.fromRGB(170, 80, 255)
circleAdorn.Transparency = 0.25
circleAdorn.AlwaysOnTop = true
circleAdorn.ZIndex = 5
circleAdorn.CFrame = CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0, 2.7)
circleAdorn.Visible = false
circleAdorn.Parent = gui

--// PARRY LOGIC & CURVE TRACKERS
local Parried = false
local LastParryTime = 0
local LastTarget = ""
local LastBallDir = nil
local SmoothedCurveRate = 0
local lastUIUpdate = 0
local IsMacroHolding = false

local HasMouse1Click = (type(mouse1click) == "function")
local HasMouseMove = (type(mousemoverel) == "function")

local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function GetRealBall()
    local ballsFolder = workspace:FindFirstChild("Balls")
    if not ballsFolder then return nil end
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then return ball end
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
    end
end

local function UpdateToggle(state)
    Config.Enabled = state
    toggleBtn.Text = state and S("ENABLE : ON [DEL]") or S("ENABLE : OFF [DEL]")
    toggleBtn.BackgroundColor3 = state and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(30, 24, 42)
end

local function UpdateMacroToggle(state)
    Config.MacroEnabled = state
    if not state then
        IsMacroHolding = false
    end
    macroBtn.Text = state and S("MACRO [HOLD E] : ON") or S("MACRO [HOLD E] : OFF")
    macroBtn.BackgroundColor3 = state and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(30, 24, 42)
end

toggleBtn.MouseButton1Click:Connect(function()
    UpdateToggle(not Config.Enabled)
end)

macroBtn.MouseButton1Click:Connect(function()
    UpdateMacroToggle(not Config.MacroEnabled)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    elseif input.KeyCode == Enum.KeyCode.Delete then
        UpdateToggle(not Config.Enabled)
    elseif input.KeyCode == Enum.KeyCode.E then
        if Config.MacroEnabled and not IsMacroHolding then
            IsMacroHolding = true
            task.spawn(function()
                while IsMacroHolding and Config.MacroEnabled and UserInputService:IsKeyDown(Enum.KeyCode.E) do
                    TriggerParry()
                    task.wait(Config.MacroDelay)
                end
                IsMacroHolding = false
                if not Config.Enabled then
                    statusLabel.Text = S("Idle | R:-- | S:--")
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        IsMacroHolding = false
    end
end)

--// MAIN LOOP
RunService.PreSimulation:Connect(function(dt)
    local hrp = GetHRP()
    if circleAdorn and hrp then
        circleAdorn.Adornee = hrp
        circleAdorn.Visible = Config.Enabled and Config.ShowCircle
    end

    -- Jika E sedang di-hold (Macro aktif), hentikan sementara Auto Parry otomatis
    if IsMacroHolding then
        local now = os.clock()
        if now - lastUIUpdate > 0.1 then
            lastUIUpdate = now
            statusLabel.Text = S("MACRO SPAMMING [E]")
        end
        return
    end

    if not Config.Enabled or not hrp then return end

    local ball = GetRealBall()
    if not ball then
        Parried = false
        LastBallDir = nil
        SmoothedCurveRate = 0
        return
    end

    local ballVelocity = GetBallVelocity(ball)
    local rawSpeed = ballVelocity.Magnitude
    local playerVelocity = hrp.AssemblyLinearVelocity or Vector3.zero
    local toPlayerVec = hrp.Position - ball.Position
    local distance = toPlayerVec.Magnitude
    local dirToPlayer = (distance > 0.01) and toPlayerVec.Unit or Vector3.zAxis

    -- 1. Deteksi Laju Lengkungan Bola (Angular Velocity antar-frame)
    local ballDir = (rawSpeed > 1) and ballVelocity.Unit or dirToPlayer
    local deltaTime = math.max(dt or (1/60), 1/240)

    if LastBallDir and rawSpeed > 5 then
        local angleChange = (ballDir - LastBallDir).Magnitude / deltaTime
        SmoothedCurveRate = SmoothedCurveRate + (angleChange - SmoothedCurveRate) * 0.35
    else
        SmoothedCurveRate = 0
    end
    LastBallDir = ballDir

    -- 2. Hitung Sudut Arah Bola terhadap Pemain
    local alignmentDot = ballDir:Dot(dirToPlayer)
    local isCurvingHard = (SmoothedCurveRate > 2.2) and (alignmentDot < 0.85)

    -- 3. Hitung Kecepatan Mendekat Murni (Closing Speed)
    local relativeVelocity = ballVelocity - playerVelocity
    local closingSpeed = relativeVelocity:Dot(dirToPlayer)

    local minFloorFactor = isCurvingHard and 0.15 or 0.35
    local effectiveSpeed = math.max(closingSpeed, rawSpeed * minFloorFactor)

    -- 4. Waktu Reaksi (Tanpa Ping + Kompensasi Bola Lambat & Cepat)
    local activeReactionTime = Config.BaseTimeToImpact
    if rawSpeed >= Config.ExtremeSpeedThreshold then
        activeReactionTime = activeReactionTime + Config.FastBonusTime
    elseif rawSpeed <= Config.SlowSpeedThreshold then
        -- Tambah kepekaan saat bola berjalan lambat agar tidak kena badan duluan
        local slowRatio = math.clamp(1 - (rawSpeed / Config.SlowSpeedThreshold), 0, 1)
        activeReactionTime = activeReactionTime + (Config.SlowBonusTime * slowRatio)
    end

    -- Jika bola sedang melengkung melebar, tahan waktu reaksi agar tidak parry kepagian
    if isCurvingHard then
        local curvePenalty = math.clamp((1 - alignmentDot) * Config.CurveSensitivity, 0.03, 0.12)
        activeReactionTime = math.max(0.12, activeReactionTime - curvePenalty)
    end

    -- Gunakan HitboxOffset agar jarak dihitung ke permukaan badan, bukan titik tengah perut (HRP)
    local effectiveDistance = math.max(0, distance - Config.HitboxOffset)
    local dynamicRadius = math.clamp((effectiveSpeed * activeReactionTime) + Config.HitboxOffset, Config.MinRadius, Config.MaxRadius)
    local timeToImpact = (closingSpeed > 1) and (effectiveDistance / closingSpeed) or math.huge

    if circleAdorn and Config.ShowCircle then
        circleAdorn.Radius = dynamicRadius
        circleAdorn.InnerRadius = math.max(0.1, dynamicRadius - 0.4)
        circleAdorn.Color3 = isCurvingHard and Color3.fromRGB(255, 140, 50) or Color3.fromRGB(170, 80, 255)
    end

    local currentTarget = ball:GetAttribute("target") or ""
    local isTargeting = (currentTarget == LocalPlayer.Name) or (currentTarget == LocalPlayer.DisplayName)

    if currentTarget ~= LastTarget then
        Parried = false
        LastTarget = currentTarget
    elseif Parried and (os.clock() - LastParryTime) >= Config.FallbackReset then
        Parried = false
    end

    if isTargeting and rawSpeed > 2 then
        -- 5. Dynamic Dot Threshold
        local distRatio = math.clamp((distance - 15) / math.max(dynamicRadius - 15, 1), 0, 1)
        local requiredDot = Config.CloseDotThreshold + (Config.StrictDotThreshold - Config.CloseDotThreshold) * distRatio
        local isHeadingToUs = (alignmentDot >= requiredDot) and (closingSpeed > 0)

        -- KONDISI 1: Auto-Spam jarak dekat & kecepatan tinggi
        if distance <= Config.SpamMaxDistance and rawSpeed >= Config.SpamMinSpeed and alignmentDot >= 0.15 then
            TriggerParry()
            Parried = true
            LastParryTime = os.clock()

        -- KONDISI 2: Normal, Slow, Fast, & Anti-Curve Parry
        elseif not Parried and isHeadingToUs and distance <= dynamicRadius and timeToImpact <= activeReactionTime then
            TriggerParry()
            Parried = true
            LastParryTime = os.clock()
        end
    else
        Parried = false
    end

    local now = os.clock()
    if now - lastUIUpdate > 0.1 then
        lastUIUpdate = now
        local stateText = "Idle"
        if isTargeting then
            stateText = isCurvingHard and "CURVE!" or "TARGET"
        end
        statusLabel.Text = S(string.format("%s | R:%d | S:%d", stateText, dynamicRadius, rawSpeed))
    end
end)
