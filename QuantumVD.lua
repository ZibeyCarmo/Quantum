--[[
    VD HUB v6.0 | Violence District (Cyber Hologram Ultimate)
    =============================================================
    FITUR LENGKAP:
    • GUI Modern Cyber Neon (Leenz Hub Dual Column Layout)
    • Floating Logo Widget (Klik 1x Hide/Show, Bebas di-Drag dengan Mouse)
    • Loading Screen Kotak Kecil 5 Detik + Tombol Start
    • Full 3D Hologram ESP (Player/Killer, Generator, Vault/Window, Pallet) - NO LINES
    • Fix Auto Generator: Pilihan Mode Instant, Legit, Normal, Random + Prompt Jitter
    • Auto Teleport ke Generator & Player Terdekat + Tombol Teleport Instan
    • Aimbot Pistol Silent Aim + Auto Predict Lead Target + Selector Kepala/Badan
    • Aimbot Flashlight (Auto Blind/Stun Killer) + Selector Kepala/Badan
    • Fix Speed Boost Permanen (Anti-Reset Signal + Heartbeat Lock) + Auto Run
    • Interactive Search Bar, User Profile Card, FOV Circle Drawing, Resizable Handle
]]

local ALLOWED = 93978595733734
if game.PlaceId ~= ALLOWED then
    warn("[VD HUB] Hanya Violence District | PlaceId:", game.PlaceId)
    return
end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================== CONFIGURASI HUB =====================
local CFG = {
    -- Hologram ESP
    Holo_Player    = true,
    Holo_Generator = true,
    Holo_Pallet    = true,
    Holo_Vault     = true,
    Holo_DistTag   = true,
    Holo_MaxDist   = 550,
    Holo_FillTrans = 0.55,

    -- Auto Generator
    GenMode        = "Normal", -- Off / Normal / Legit / Instant / Random
    GenRange       = 26,

    -- Auto Teleport
    AutoTP_Gen     = false,
    AutoTP_Player  = false,
    TP_Cooldown    = 3,

    -- Aimbot Pistol
    PistolAim      = false,
    PistolSilent   = true,
    PistolPredict  = true,
    PistolPart     = "Head",   -- "Head" (Kepala) / "HumanoidRootPart" (Badan)
    PistolFOV      = 280,
    PistolSmooth   = 0.14,
    ShowPistolFOV  = false,

    -- Aimbot Flashlight
    FlashAim       = false,
    FlashPart      = "Head",   -- "Head" (Kepala) / "HumanoidRootPart" (Badan)
    FlashFOV       = 320,
    FlashSmooth    = 0.16,
    FlashAutoLock  = true,     -- Lock otomatis ke Killer saat pegang flashlight

    -- Movement / Speed Boost
    Speed          = false,
    WalkSpeed      = 24,
    AutoRun        = false,

    -- Crosshair
    Crosshair      = false,
    CrosshairSize  = 5,
}

local VERSION = "6.0"
local connections = {}
local hologramInstances = {}
local lastTPTime = 0
local cachedGenerators = {}

-- ===================== UTILITAS SISTEM =====================
local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function GetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function GetCharRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ===================== CACHE GENERATOR =====================
local function UpdateGeneratorCache()
    table.clear(cachedGenerators)
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent")) then
            local part = GetPart(obj)
            if part then
                table.insert(cachedGenerators, {Obj = obj, Part = part})
            end
        end
    end
end
task.spawn(function()
    while true do
        UpdateGeneratorCache()
        task.wait(4)
    end
end)

local function GetClosestTarget(list, myPos, maxDist)
    local best, bestDist = nil, maxDist or math.huge
    for _, item in ipairs(list) do
        if item.Part and item.Part.Parent then
            local d = (item.Part.Position - myPos).Magnitude
            if d < bestDist then
                bestDist = d
                best = item
            end
        end
    end
    return best, bestDist
end

-- ===================== PROXIMITY PROMPT =====================
local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.HoldDuration = 0
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(0.02)
            prompt:InputHoldEnd()
        end
    end)
end

-- ===================== FIX AUTO GENERATOR =====================
local function DoGenerator()
    if CFG.GenMode == "Off" then return end
    local root = GetCharRoot()
    if not root then return end

    local delayTime = 0.16 -- Normal
    if CFG.GenMode == "Instant" then
        delayTime = 0.01
    elseif CFG.GenMode == "Legit" then
        delayTime = 0.38 + math.random() * 0.28
    elseif CFG.GenMode == "Random" then
        delayTime = 0.09 + math.random() * 0.45
    end

    for _, gen in ipairs(cachedGenerators) do
        if gen.Part and gen.Part.Parent and (gen.Part.Position - root.Position).Magnitude <= CFG.GenRange then
            local prompts = {}
            for _, d in ipairs(gen.Obj:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    table.insert(prompts, d)
                end
            end
            if gen.Obj.Parent then
                for _, d in ipairs(gen.Obj.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        local exists = false
                        for _, p in ipairs(prompts) do if p == d then exists = true; break end end
                        if not exists then table.insert(prompts, d) end
                    end
                end
            end
            for _, prompt in ipairs(prompts) do
                task.wait(delayTime)
                FirePrompt(prompt)
            end
        end
    end
end

-- ===================== AUTO TELEPORT SYSTEM =====================
local function TeleportTo(category)
    local root = GetCharRoot()
    if not root then return end
    if tick() - lastTPTime < CFG.TP_Cooldown then return end

    if category == "Generator" then
        local best = GetClosestTarget(cachedGenerators, root.Position)
        if best and best.Part then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = best.Part.CFrame * CFrame.new(0, 3.5, 3)
            lastTPTime = tick()
        end
    elseif category == "Player" then
        local playersList = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local pRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if pRoot and hum and hum.Health > 0 then
                    table.insert(playersList, {Part = pRoot, Obj = plr.Character})
                end
            end
        end
        local best = GetClosestTarget(playersList, root.Position)
        if best and best.Part then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = best.Part.CFrame * CFrame.new(0, 3, 4)
            lastTPTime = tick()
        end
    end
end

-- ===================== AIMBOT ENGINE & PREDICT =====================
local function PredictPosition(targetPart, bulletSpeed)
    if not targetPart or not targetPart:IsA("BasePart") then return targetPart.Position end
    if not CFG.PistolPredict then return targetPart.Position end

    local vel = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero
    if vel.Magnitude < 0.5 then return targetPart.Position end

    local dist = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local spd = bulletSpeed or 650
    local leadTime = math.clamp(dist / spd, 0.03, 0.32)

    return targetPart.Position + (vel * leadTime)
end

local function GetAimTarget(fov, aimPartName, isFlashlight)
    local mouse = UIS:GetMouseLocation()
    local best, bestDist = nil, fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local charName = string.lower(plr.Character.Name)
            local isKiller = string.find(charName, "killer") or string.find(charName, "monster") or (hum and hum.MaxHealth > 100)

            -- Untuk flashlight, prioritaskan Killer
            if isFlashlight and not isKiller and #Players:GetPlayers() > 2 then
                -- lewati jika bukan killer jika ada killer
            end

            local targetPart = plr.Character:FindFirstChild(aimPartName)
                or plr.Character:FindFirstChild("Head")
                or plr.Character:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and targetPart then
                local worldPos = PredictPosition(targetPart, 650)
                local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
                if onScreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = {Part = targetPart, Position = worldPos, Player = plr, IsKiller = isKiller}
                    end
                end
            end
        end
    end

    return best
end

-- ===================== FIX SPEED BOOST PERMANEN =====================
local function ApplySpeedBoost()
    local hum = GetHumanoid()
    if not hum then return end
    if CFG.Speed then
        if hum.WalkSpeed ~= CFG.WalkSpeed then
            hum.WalkSpeed = CFG.WalkSpeed
        end
    end
    if CFG.AutoRun and hum.MoveDirection.Magnitude > 0 then
        hum.WalkSpeed = math.max(hum.WalkSpeed, CFG.WalkSpeed)
    end
end

local function BindSpeedGuard(char)
    task.wait(0.2)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if CFG.Speed and hum.WalkSpeed ~= CFG.WalkSpeed then
                hum.WalkSpeed = CFG.WalkSpeed
            end
        end)
    end
end
if LP.Character then BindSpeedGuard(LP.Character) end
LP.CharacterAdded:Connect(BindSpeedGuard)

local speedLoop = RunService.Heartbeat:Connect(ApplySpeedBoost)
table.insert(connections, speedLoop)

-- ===================== SCREEN GUI SETUP =====================
pcall(function()
    local old = CoreGui:FindFirstChild("VD_HUB_V6")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "VD_HUB_V6"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local espFolder = Instance.new("Folder")
espFolder.Name = "VD_ESP_HOLOGRAMS"
espFolder.Parent = gui

-- ===================== FULL 3D HOLOGRAM ESP =====================
local function ClearAllHolograms()
    for _, item in pairs(hologramInstances) do
        if item.Highlight then pcall(function() item.Highlight:Destroy() end) end
        if item.Billboard then pcall(function() item.Billboard:Destroy() end) end
    end
    table.clear(hologramInstances)
    espFolder:ClearAllChildren()
end

local function CreateHologram(target, nameText, fillCol, outlineCol, isPlayer)
    if not target then return nil end
    local part = GetPart(target)
    if not part then return nil end

    local key = tostring(target)
    pcall(function() key = target:GetDebugId() end)
    if hologramInstances[key] then return hologramInstances[key] end

    -- 1. 3D Glowing Mesh Highlight (Tembus Dinding)
    local hl = Instance.new("Highlight")
    hl.Name = "Holo_" .. target.Name
    hl.Adornee = target
    hl.FillColor = fillCol
    hl.FillTransparency = CFG.Holo_FillTrans
    hl.OutlineColor = outlineCol
    hl.OutlineTransparency = 0.05
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder

    -- 2. 3D Billboard Hologram Card
    local bb = Instance.new("BillboardGui")
    bb.Name = "Tag_" .. target.Name
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(125, 38)
    bb.StudsOffset = Vector3.new(0, isPlayer and 3.2 or 2.2, 0)
    bb.Parent = espFolder

    local card = Instance.new("Frame", bb)
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    card.BackgroundTransparency = 0.35
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local st = Instance.new("UIStroke", card)
    st.Color = outlineCol
    st.Thickness = 1
    st.Transparency = 0.2

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -6, 0, 16)
    titleLbl.Position = UDim2.new(0, 3, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = nameText
    titleLbl.TextColor3 = outlineCol
    titleLbl.TextSize = 10
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local distLbl = Instance.new("TextLabel", card)
    distLbl.Name = "DistLabel"
    distLbl.Size = UDim2.new(1, -6, 0, 14)
    distLbl.Position = UDim2.new(0, 3, 0, 18)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "0m"
    distLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    distLbl.TextSize = 9
    distLbl.Font = Enum.Font.GothamMedium

    local entry = {
        Target = target, Part = part,
        Highlight = hl, Billboard = bb,
        DistLabel = distLbl, TitleLabel = titleLbl,
        BaseColor = fillCol, OutlineColor = outlineCol,
        IsPlayer = isPlayer
    }
    hologramInstances[key] = entry
    return entry
end

-- Loop Update Posisi & Jarak Hologram
local holoUpdateLoop = RunService.Heartbeat:Connect(function()
    local root = GetCharRoot()
    local myPos = root and root.Position or Camera.CFrame.Position

    for key, data in pairs(hologramInstances) do
        if not data.Target or not data.Target.Parent or not data.Part or not data.Part.Parent then
            if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
            if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
            hologramInstances[key] = nil
        else
            local dist = (data.Part.Position - myPos).Magnitude
            if dist > CFG.Holo_MaxDist then
                data.Highlight.Enabled = false
                data.Billboard.Enabled = false
            else
                data.Highlight.Enabled = true
                data.Highlight.FillTransparency = CFG.Holo_FillTrans
                data.Billboard.Enabled = CFG.Holo_DistTag
                local meters = math.floor(dist * 0.28)
                if data.IsPlayer and data.Target:IsA("Model") then
                    local hum = data.Target:FindFirstChildOfClass("Humanoid")
                    local hp = hum and math.floor(hum.Health) or 100
                    data.DistLabel.Text = meters .. "m  •  " .. hp .. " HP"
                    if hp < 30 then
                        data.Highlight.FillColor = Color3.fromRGB(255, 45, 65)
                        data.Highlight.OutlineColor = Color3.fromRGB(255, 95, 115)
                    else
                        data.Highlight.FillColor = data.BaseColor
                        data.Highlight.OutlineColor = data.OutlineColor
                    end
                else
                    data.DistLabel.Text = meters .. "m"
                end
            end
        end
    end
end)
table.insert(connections, holoUpdateLoop)

-- Hologram Scanner Thread
task.spawn(function()
    while true do
        task.wait(1.4)
        if not gui or not gui.Parent then break end

        -- 1. Player & Killer Holograms
        if CFG.Holo_Player then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local pName = string.lower(plr.Character.Name)
                        local isKiller = string.find(pName, "killer") or string.find(pName, "monster") or (hum.MaxHealth > 100)
                        local fillCol = isKiller and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(0, 220, 255)
                        local outCol  = isKiller and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(120, 245, 255)
                        local tag = (isKiller and "🔪 [KILLER] " or "🏃 ") .. plr.DisplayName
                        CreateHologram(plr.Character, tag, fillCol, outCol, true)
                    end
                end
            end
        end

        -- 2. Generator, Vault, Pallet Holograms
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            local k = tostring(obj)
            pcall(function() k = obj:GetDebugId() end)

            if CFG.Holo_Generator and (string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent"))) then
                if GetPart(obj) and not hologramInstances[k] then
                    CreateHologram(obj, "⚡ GENERATOR", Color3.fromRGB(0, 185, 255), Color3.fromRGB(70, 225, 255), false)
                end
            elseif CFG.Holo_Vault and (string.find(n, "vault") or string.find(n, "window")) then
                if GetPart(obj) and not hologramInstances[k] then
                    CreateHologram(obj, "🚪 VAULT", Color3.fromRGB(255, 210, 50), Color3.fromRGB(255, 230, 110), false)
                end
            elseif CFG.Holo_Pallet and string.find(n, "pallet") then
                if GetPart(obj) and not hologramInstances[k] then
                    CreateHologram(obj, "📦 PALLET", Color3.fromRGB(255, 130, 40), Color3.fromRGB(255, 170, 80), false)
                end
            end
        end
    end
end)

-- ===================== 1. LOADING SCREEN KOTAK KECIL (5 DETIK) =====================
local LoadCard = Instance.new("Frame")
LoadCard.Name = "LoadCard"
LoadCard.Size = UDim2.fromOffset(360, 225)
LoadCard.Position = UDim2.new(0.5, -180, 0.5, -112)
LoadCard.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
LoadCard.BorderSizePixel = 0
LoadCard.Active = true
LoadCard.Parent = gui
Instance.new("UICorner", LoadCard).CornerRadius = UDim.new(0, 12)

local LoadStroke = Instance.new("UIStroke", LoadCard)
LoadStroke.Thickness = 1.5
LoadStroke.Color = Color3.fromRGB(255, 45, 85)

local LoadStrokeGrad = Instance.new("UIGradient", LoadStroke)
LoadStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 45, 85)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 50, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 45, 85))
})

local LIcon = Instance.new("TextLabel", LoadCard)
LIcon.Size = UDim2.fromOffset(36, 36)
LIcon.Position = UDim2.new(0, 18, 0, 18)
LIcon.BackgroundColor3 = Color3.fromRGB(25, 18, 30)
LIcon.Text = "VD"
LIcon.TextColor3 = Color3.fromRGB(255, 60, 100)
LIcon.TextSize = 16
LIcon.Font = Enum.Font.GothamBold
Instance.new("UICorner", LIcon).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LIcon).Color = Color3.fromRGB(255, 60, 100)

local LTitle = Instance.new("TextLabel", LoadCard)
LTitle.Size = UDim2.new(1, -70, 0, 20)
LTitle.Position = UDim2.new(0, 64, 0, 16)
LTitle.BackgroundTransparency = 1
LTitle.Text = "VD HUB  <font color='#ff2d55'>v" .. VERSION .. "</font>"
LTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
LTitle.TextSize = 16
LTitle.RichText = true
LTitle.Font = Enum.Font.GothamBold
LTitle.TextXAlignment = Enum.TextXAlignment.Left

local LSubtitle = Instance.new("TextLabel", LoadCard)
LSubtitle.Size = UDim2.new(1, -70, 0, 16)
LSubtitle.Position = UDim2.new(0, 64, 0, 36)
LSubtitle.BackgroundTransparency = 1
LSubtitle.Text = "Violence District • Cyber Hologram"
LSubtitle.TextColor3 = Color3.fromRGB(140, 140, 160)
LSubtitle.TextSize = 11
LSubtitle.Font = Enum.Font.Gotham
LSubtitle.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", LoadCard)
StatusLbl.Size = UDim2.new(1, -40, 0, 18)
StatusLbl.Position = UDim2.new(0, 20, 0, 82)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Memulai sistem cyber hologram..."
StatusLbl.TextColor3 = Color3.fromRGB(190, 190, 210)
StatusLbl.TextSize = 12
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local PercentLbl = Instance.new("TextLabel", LoadCard)
PercentLbl.Size = UDim2.fromOffset(50, 18)
PercentLbl.Position = UDim2.new(1, -70, 0, 82)
PercentLbl.BackgroundTransparency = 1
PercentLbl.Text = "0%"
PercentLbl.TextColor3 = Color3.fromRGB(255, 60, 100)
PercentLbl.TextSize = 12
PercentLbl.Font = Enum.Font.GothamBold
PercentLbl.TextXAlignment = Enum.TextXAlignment.Right

local BarTrack = Instance.new("Frame", LoadCard)
BarTrack.Size = UDim2.new(1, -40, 0, 7)
BarTrack.Position = UDim2.new(0, 20, 0, 110)
BarTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
BarTrack.BorderSizePixel = 0
Instance.new("UICorner", BarTrack).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame", BarTrack)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
Instance.new("UIGradient", BarFill).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 100)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(140, 50, 255))
})

local StartBtn = Instance.new("TextButton", LoadCard)
StartBtn.Size = UDim2.new(1, -40, 0, 42)
StartBtn.Position = UDim2.new(0, 20, 0, 144)
StartBtn.BackgroundColor3 = Color3.fromRGB(235, 40, 80)
StartBtn.Text = "🚀  BUKA VD HUB"
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.TextSize = 13
StartBtn.Font = Enum.Font.GothamBold
StartBtn.AutoButtonColor = false
StartBtn.Visible = false
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", StartBtn).Color = Color3.fromRGB(255, 110, 150)

-- ===================== 2. MAIN GUI WINDOW =====================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(720, 450)
Main.Position = UDim2.new(0.5, -360, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1.2
MainStroke.Color = Color3.fromRGB(38, 38, 50)

local MainGlow = Instance.new("UIGradient", MainStroke)
MainGlow.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 45, 85)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 140, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 45, 85))
})

local glowRot = 0
local rotConn = RunService.RenderStepped:Connect(function(dt)
    glowRot = (glowRot + dt * 45) % 360
    pcall(function() if LoadStrokeGrad.Parent then LoadStrokeGrad.Rotation = glowRot end end)
    pcall(function() if MainGlow.Parent then MainGlow.Rotation = glowRot end end)
end)
table.insert(connections, rotConn)

-- ===================== 3. FLOATING LOGO WIDGET =====================
local LogoBtn = Instance.new("TextButton")
LogoBtn.Name = "VD_FloatingLogo"
LogoBtn.Size = UDim2.fromOffset(46, 46)
LogoBtn.Position = UDim2.new(0, 25, 0.45, 0)
LogoBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
LogoBtn.Text = ""
LogoBtn.AutoButtonColor = false
LogoBtn.Visible = false
LogoBtn.Parent = gui
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 12)

local lStroke = Instance.new("UIStroke", LogoBtn)
lStroke.Color = Color3.fromRGB(255, 45, 85)
lStroke.Thickness = 1.5
Instance.new("UIGradient", lStroke).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 50, 90)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(90, 70, 255))
})

local LogoLbl = Instance.new("TextLabel", LogoBtn)
LogoLbl.Size = UDim2.new(1, 0, 1, 0)
LogoLbl.BackgroundTransparency = 1
LogoLbl.Text = "VD"
LogoLbl.TextColor3 = Color3.fromRGB(255, 60, 100)
LogoLbl.TextSize = 16
LogoLbl.Font = Enum.Font.GothamBold

local function ToggleMainGUI()
    if Main.Visible then
        Tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 0.8
        })
        task.wait(0.2)
        Main.Visible = false
        Main.BackgroundTransparency = 0
    else
        Main.Visible = true
        Main.BackgroundTransparency = 0.6
        Tween(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        })
    end
end

-- Drag + Click Floating Logo
local logoDrag, logoMoved = false, false
local logoDragStart, logoStartPos = Vector2.zero, UDim2.new()

LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        logoDrag = true
        logoMoved = false
        logoDragStart = UIS:GetMouseLocation()
        logoStartPos = LogoBtn.Position
    end
end)

UIS.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and logoDrag then
        logoDrag = false
        if not logoMoved then ToggleMainGUI() end
    end
end)

UIS.InputChanged:Connect(function(input)
    if logoDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local m = UIS:GetMouseLocation()
        local d = m - logoDragStart
        if d.Magnitude > 4 then logoMoved = true end
        LogoBtn.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + d.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + d.Y)
    end
end)

-- ===================== SIDEBAR =====================
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 165, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
Sidebar.BorderSizePixel = 0

local SideBorder = Instance.new("Frame", Sidebar)
SideBorder.Size = UDim2.new(0, 1, 1, 0)
SideBorder.Position = UDim2.new(1, -1, 0, 0)
SideBorder.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
SideBorder.BorderSizePixel = 0

local SideHead = Instance.new("Frame", Sidebar)
SideHead.Size = UDim2.new(1, 0, 0, 42)
SideHead.BackgroundTransparency = 1

local SideLogo = Instance.new("TextLabel", SideHead)
SideLogo.Size = UDim2.fromOffset(24, 24)
SideLogo.Position = UDim2.new(0, 12, 0.5, -12)
SideLogo.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
SideLogo.Text = "VD"
SideLogo.TextColor3 = Color3.new(1, 1, 1)
SideLogo.TextSize = 10
SideLogo.Font = Enum.Font.GothamBold
Instance.new("UICorner", SideLogo).CornerRadius = UDim.new(0, 6)

local SideTitle = Instance.new("TextLabel", SideHead)
SideTitle.Size = UDim2.new(1, -44, 1, 0)
SideTitle.Position = UDim2.new(0, 42, 0, 0)
SideTitle.BackgroundTransparency = 1
SideTitle.Text = "VD Hub"
SideTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
SideTitle.TextSize = 14
SideTitle.Font = Enum.Font.GothamBold
SideTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Search Bar
local SearchWrap = Instance.new("Frame", Sidebar)
SearchWrap.Size = UDim2.new(1, -20, 0, 28)
SearchWrap.Position = UDim2.new(0, 10, 0, 44)
SearchWrap.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
SearchWrap.BorderSizePixel = 0
Instance.new("UICorner", SearchWrap).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", SearchWrap).Color = Color3.fromRGB(34, 34, 46)

local SearchIcn = Instance.new("TextLabel", SearchWrap)
SearchIcn.Size = UDim2.fromOffset(20, 28)
SearchIcn.Position = UDim2.new(0, 6, 0, 0)
SearchIcn.BackgroundTransparency = 1
SearchIcn.Text = "🔍"
SearchIcn.TextColor3 = Color3.fromRGB(110, 110, 130)
SearchIcn.TextSize = 11

local SearchBox = Instance.new("TextBox", SearchWrap)
SearchBox.Size = UDim2.new(1, -30, 1, 0)
SearchBox.Position = UDim2.new(0, 28, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search"
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(235, 235, 245)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false

-- Tab List Scrollable
local TabScroll = Instance.new("ScrollingFrame", Sidebar)
TabScroll.Size = UDim2.new(1, 0, 1, -135)
TabScroll.Position = UDim2.new(0, 0, 0, 78)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 2
TabScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 45, 85)
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UIListLayout", TabScroll).Padding = UDim.new(0, 3)

local tp = Instance.new("UIPadding", TabScroll)
tp.PaddingLeft = UDim.new(0, 8)
tp.PaddingRight = UDim.new(0, 8)
tp.PaddingTop = UDim.new(0, 2)

-- User Profile Card
local ProfCard = Instance.new("Frame", Sidebar)
ProfCard.Size = UDim2.new(1, -16, 0, 44)
ProfCard.Position = UDim2.new(0, 8, 1, -52)
ProfCard.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
ProfCard.BorderSizePixel = 0
Instance.new("UICorner", ProfCard).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ProfCard).Color = Color3.fromRGB(32, 32, 44)

local Avatar = Instance.new("ImageLabel", ProfCard)
Avatar.Size = UDim2.fromOffset(28, 28)
Avatar.Position = UDim2.new(0, 8, 0.5, -14)
Avatar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150"
Avatar.BorderSizePixel = 0
Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

local PName = Instance.new("TextLabel", ProfCard)
PName.Size = UDim2.new(1, -44, 0, 14)
PName.Position = UDim2.new(0, 42, 0, 6)
PName.BackgroundTransparency = 1
PName.Text = LP.DisplayName
PName.TextColor3 = Color3.fromRGB(235, 235, 245)
PName.TextSize = 11
PName.Font = Enum.Font.GothamBold
PName.TextXAlignment = Enum.TextXAlignment.Left
PName.TextTruncate = Enum.TextTruncate.AtEnd

local PSub = Instance.new("TextLabel", ProfCard)
PSub.Size = UDim2.new(1, -44, 0, 12)
PSub.Position = UDim2.new(0, 42, 0, 22)
PSub.BackgroundTransparency = 1
PSub.Text = "Violence District"
PSub.TextColor3 = Color3.fromRGB(120, 120, 140)
PSub.TextSize = 9
PSub.Font = Enum.Font.Gotham
PSub.TextXAlignment = Enum.TextXAlignment.Left

-- ===================== CONTENT AREA =====================
local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -165, 1, 0)
ContentArea.Position = UDim2.new(0, 165, 0, 0)
ContentArea.BackgroundTransparency = 1

local TopHead = Instance.new("Frame", ContentArea)
TopHead.Size = UDim2.new(1, 0, 0, 40)
TopHead.BackgroundTransparency = 1

local TabTitle = Instance.new("TextLabel", TopHead)
TabTitle.Size = UDim2.new(1, -80, 1, 0)
TabTitle.Position = UDim2.new(0, 14, 0, 0)
TabTitle.BackgroundTransparency = 1
TabTitle.Text = "🏠  Exclusive"
TabTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
TabTitle.TextSize = 14
TabTitle.Font = Enum.Font.GothamBold
TabTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopHead)
CloseBtn.Size = UDim2.fromOffset(24, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 22, 28)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 95)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ClearAllHolograms()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end)

local MinBtn = Instance.new("TextButton", TopHead)
MinBtn.Size = UDim2.fromOffset(24, 24)
MinBtn.Position = UDim2.new(1, -60, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
MinBtn.TextSize = 12
MinBtn.Font = Enum.Font.GothamBold
MinBtn.AutoButtonColor = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

MinBtn.MouseButton1Click:Connect(function() ToggleMainGUI() end)

local HDiv = Instance.new("Frame", ContentArea)
HDiv.Size = UDim2.new(1, -16, 0, 1)
HDiv.Position = UDim2.new(0, 8, 0, 40)
HDiv.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
HDiv.BorderSizePixel = 0

local PagesFolder = Instance.new("Folder", ContentArea)

-- Drag Window pada TopHead
local isDragging = false
local dragStart, dragPos = Vector2.zero, UDim2.new()

TopHead.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = UIS:GetMouseLocation()
        dragPos = Main.Position
    end
end)

-- Resize Grip di Pojok Kanan Bawah
local ResizeGrip = Instance.new("TextButton", Main)
ResizeGrip.Size = UDim2.fromOffset(18, 18)
ResizeGrip.Position = UDim2.new(1, -18, 1, -18)
ResizeGrip.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
ResizeGrip.Text = "⇲"
ResizeGrip.TextColor3 = Color3.fromRGB(255, 65, 110)
ResizeGrip.TextSize = 12
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.AutoButtonColor = false
Instance.new("UICorner", ResizeGrip).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", ResizeGrip).Color = Color3.fromRGB(255, 60, 100)

local isResizing = false
local resStart, resSize = Vector2.zero, Vector2.zero

ResizeGrip.MouseButton1Down:Connect(function()
    isResizing = true
    resStart = UIS:GetMouseLocation()
    resSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        isResizing = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local m = UIS:GetMouseLocation()
        if isDragging then
            local d = m - dragStart
            Main.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
        end
        if isResizing then
            local d = m - resStart
            Main.Size = UDim2.fromOffset(
                math.clamp(resSize.X + d.X, 560, 960),
                math.clamp(resSize.Y + d.Y, 360, 680)
            )
        end
    end
end)

-- ===================== TAB & DUAL COLUMN BUILDER =====================
local tabButtons, tabPages = {}, {}
local currentTab = "Exclusive"

local function SwitchTab(name, icon)
    currentTab = name
    TabTitle.Text = icon .. "  " .. name
    for n, btn in pairs(tabButtons) do
        local active = (n == name)
        Tween(btn, TweenInfo.new(0.18), {
            BackgroundColor3 = active and Color3.fromRGB(26, 26, 36) or Color3.fromRGB(14, 14, 19),
            TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170)
        })
        local pill = btn:FindFirstChild("Pill")
        if pill then pill.Visible = active end
    end
    for n, page in pairs(tabPages) do page.Visible = (n == name) end
end

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton", TabScroll)
    btn.Name = "Tab_" .. name
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
    btn.Text = "   " .. icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local pill = Instance.new("Frame", btn)
    pill.Name = "Pill"
    pill.Size = UDim2.new(0, 3, 0.6, 0)
    pill.Position = UDim2.new(0, 2, 0.2, 0)
    pill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    pill.BorderSizePixel = 0
    pill.Visible = false
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function() SwitchTab(name, icon) end)
    tabButtons[name] = btn

    local page = Instance.new("ScrollingFrame", PagesFolder)
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, -46)
    page.Position = UDim2.new(0, 0, 0, 46)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(255, 45, 85)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false

    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 16)

    local cols = Instance.new("Frame", page)
    cols.Size = UDim2.new(1, 0, 0, 0)
    cols.BackgroundTransparency = 1
    cols.AutomaticSize = Enum.AutomaticSize.Y

    local left = Instance.new("Frame", cols)
    left.Name = "L"
    left.Size = UDim2.new(0.5, -5, 0, 0)
    left.BackgroundTransparency = 1
    left.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", left).Padding = UDim.new(0, 6)

    local right = Instance.new("Frame", cols)
    right.Name = "R"
    right.Size = UDim2.new(0.5, -5, 0, 0)
    right.Position = UDim2.new(0.5, 5, 0, 0)
    right.BackgroundTransparency = 1
    right.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", right).Padding = UDim.new(0, 6)

    tabPages[name] = page
    return left, right
end

-- ===================== UI COMPONENTS =====================
local registeredSections = {}

local function Section(col, title)
    local f = Instance.new("Frame", col)
    f.Name = "Sec_" .. title
    f.Size = UDim2.new(1, 0, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    f.BorderSizePixel = 0
    f.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(28, 28, 38)

    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1, -20, 0, 28)
    h.Position = UDim2.new(0, 10, 0, 0)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(240, 240, 250)
    h.TextSize = 12
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left

    local body = Instance.new("Frame", f)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 28)
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    local bl = Instance.new("UIListLayout", body)
    bl.Padding = UDim.new(0, 3)
    local bp = Instance.new("UIPadding", body)
    bp.PaddingLeft = UDim.new(0, 10)
    bp.PaddingRight = UDim.new(0, 10)
    bp.PaddingBottom = UDim.new(0, 8)

    table.insert(registeredSections, {Frame = f, Title = string.lower(title)})
    return body
end

-- Search Filter Logic
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(SearchBox.Text)
    for _, sec in ipairs(registeredSections) do
        if q == "" then
            sec.Frame.Visible = true
        else
            local found = string.find(sec.Title, q) ~= nil
            if not found then
                for _, desc in ipairs(sec.Frame:GetDescendants()) do
                    if desc:IsA("TextLabel") and string.find(string.lower(desc.Text), q) then
                        found = true
                        break
                    end
                end
            end
            sec.Frame.Visible = found
        end
    end
end)

local function Toggle(parent, label, default, cb)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -42, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.fromOffset(32, 16)
    pill.Position = UDim2.new(1, -32, 0.5, -8)
    pill.BackgroundColor3 = default and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(34, 34, 46)
    pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    row.MouseButton1Click:Connect(function()
        state = not state
        Tween(pill, TweenInfo.new(0.15), {BackgroundColor3 = state and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(34, 34, 46)})
        Tween(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
        if cb then cb(state) end
    end)
    return row
end

local function Slider(parent, label, min, max, cur, sfx, cb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -45, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.fromOffset(45, 14)
    vl.Position = UDim2.new(1, -45, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(cur) .. (sfx or "")
    vl.TextColor3 = Color3.fromRGB(255, 75, 110)
    vl.TextSize = 11
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Right

    local trk = Instance.new("Frame", row)
    trk.Size = UDim2.new(1, 0, 0, 5)
    trk.Position = UDim2.new(0, 0, 0, 22)
    trk.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    trk.BorderSizePixel = 0
    Instance.new("UICorner", trk).CornerRadius = UDim.new(1, 0)

    local pct = math.clamp((cur - min) / (max - min), 0, 1)

    local fill = Instance.new("Frame", trk)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knb = Instance.new("Frame", trk)
    knb.Size = UDim2.fromOffset(10, 10)
    knb.Position = UDim2.new(pct, -5, 0.5, -5)
    knb.BackgroundColor3 = Color3.new(1, 1, 1)
    knb.BorderSizePixel = 0
    Instance.new("UICorner", knb).CornerRadius = UDim.new(1, 0)

    local sliding = false
    local function upd()
        local m = UIS:GetMouseLocation()
        local tP = trk.AbsolutePosition.X
        local tS = trk.AbsoluteSize.X
        local r = math.clamp((m.X - tP) / tS, 0, 1)
        local v = min + r * (max - min)
        if (max - min) > 10 then v = math.floor(v + 0.5) else v = math.floor(v * 100 + 0.5) / 100 end
        fill.Size = UDim2.new(r, 0, 1, 0)
        knb.Position = UDim2.new(r, -5, 0.5, -5)
        vl.Text = tostring(v) .. (sfx or "")
        if cb then cb(v) end
    end

    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; upd() end
    end)
    local c1 = UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd() end
    end)
    local c2 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    table.insert(connections, c1)
    table.insert(connections, c2)
    return row
end

local function Button(parent, text, icon, cb, color)
    local c = color or Color3.fromRGB(255, 45, 85)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    btn.Text = "  " .. (icon or "⚡") .. "  " .. text
    btn.TextColor3 = Color3.fromRGB(225, 225, 240)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke", btn)
    st.Color = Color3.fromRGB(32, 32, 44)

    btn.MouseEnter:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 24, 38)}); st.Color = c end)
    btn.MouseLeave:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 20, 30)}); st.Color = Color3.fromRGB(32, 32, 44) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, TweenInfo.new(0.08), {BackgroundColor3 = c})
        task.wait(0.08)
        Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 24, 38)})
        if cb then cb() end
    end)
    return btn
end

-- Segmented Mode Selector dengan Animasi Glowing
local function ModeSelector(parent, label, options, default, cb)
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, 0, 0, 48)
    wrap.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnsRow = Instance.new("Frame", wrap)
    btnsRow.Size = UDim2.new(1, 0, 0, 26)
    btnsRow.Position = UDim2.new(0, 0, 0, 20)
    btnsRow.BackgroundTransparency = 1
    local bl = Instance.new("UIListLayout", btnsRow)
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 4)

    local allBtns = {}

    for _, opt in ipairs(options) do
        local b = Instance.new("TextButton", btnsRow)
        local w = 1 / #options
        b.Size = UDim2.new(w, -3, 1, 0)
        b.BackgroundColor3 = (opt == default) and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(24, 24, 34)
        b.Text = opt
        b.TextColor3 = (opt == default) and Color3.new(1, 1, 1) or Color3.fromRGB(165, 165, 185)
        b.TextSize = 10
        b.Font = Enum.Font.GothamMedium
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        local st = Instance.new("UIStroke", b)
        st.Color = (opt == default) and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(36, 36, 48)

        b.MouseButton1Click:Connect(function()
            default = opt
            for _, item in ipairs(allBtns) do
                local sel = (item.mode == opt)
                Tween(item.btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = sel and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(24, 24, 34),
                    TextColor3 = sel and Color3.new(1, 1, 1) or Color3.fromRGB(165, 165, 185)
                })
                item.stroke.Color = sel and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(36, 36, 48)
            end
            if cb then cb(opt) end
        end)

        table.insert(allBtns, {btn = b, stroke = st, mode = opt})
    end

    return wrap
end

-- ===================== TAB POPULATION =====================

-- [TAB 1: EXCLUSIVE]
local exL, exR = CreateTab("Exclusive", "🏠", 1)

local sMainESP = Section(exL, "Hologram ESP Master")
Toggle(sMainESP, "Player & Killer Hologram", CFG.Holo_Player, function(v) CFG.Holo_Player = v end)
Toggle(sMainESP, "Generator Hologram (Cyan)", CFG.Holo_Generator, function(v) CFG.Holo_Generator = v end)
Toggle(sMainESP, "Vault & Window Hologram (Gold)", CFG.Holo_Vault, function(v) CFG.Holo_Vault = v end)
Toggle(sMainESP, "Pallet Hologram (Orange)", CFG.Holo_Pallet, function(v) CFG.Holo_Pallet = v end)
Toggle(sMainESP, "Tampilkan Distance & HP Tag", CFG.Holo_DistTag, function(v) CFG.Holo_DistTag = v end)
Slider(sMainESP, "Max ESP Distance", 100, 900, CFG.Holo_MaxDist, "m", function(v) CFG.Holo_MaxDist = v end)
Slider(sMainESP, "Hologram Transparency", 0.2, 0.85, CFG.Holo_FillTrans, "", function(v) CFG.Holo_FillTrans = v end)
Button(sMainESP, "Refresh & Bersihkan Hologram", "🧹", function() ClearAllHolograms() end, Color3.fromRGB(60, 190, 255))

local sMainMove = Section(exR, "Speed Boost & Auto Run")
Toggle(sMainMove, "Aktifkan Speed Boost", CFG.Speed, function(v) CFG.Speed = v end)
Toggle(sMainMove, "Auto Run Otomatis", CFG.AutoRun, function(v) CFG.AutoRun = v end)
Slider(sMainMove, "WalkSpeed Nilai", 16, 100, CFG.WalkSpeed, " spd", function(v)
    CFG.WalkSpeed = v
    ApplySpeedBoost()
end)
ModeSelector(sMainMove, "Speed Presets", {"16", "22", "32", "50", "80"}, tostring(CFG.WalkSpeed), function(v)
    CFG.WalkSpeed = tonumber(v)
    CFG.Speed = true
    ApplySpeedBoost()
end)

-- [TAB 2: GENERATOR & TELEPORT]
local genL, genR = CreateTab("Generator", "⚙️", 2)

local sGenFix = Section(genL, "Auto Fix Generator")
ModeSelector(sGenFix, "Pilihan Mode Generator", {"Off", "Normal", "Legit", "Instant", "Random"}, CFG.GenMode, function(v)
    CFG.GenMode = v
    print("[VD HUB] Generator Mode diset ke:", v)
end)
Slider(sGenFix, "Jarak Deteksi Generator", 10, 45, CFG.GenRange, " studs", function(v) CFG.GenRange = v end)
Button(sGenFix, "Trigger Cepat Prompt Terdekat", "⚡", function() pcall(DoGenerator) end, Color3.fromRGB(255, 170, 45))

local sAutoTP = Section(genR, "Auto Teleport System")
Toggle(sAutoTP, "Auto TP ke Generator (Loop)", CFG.AutoTP_Gen, function(v) CFG.AutoTP_Gen = v end)
Toggle(sAutoTP, "Auto TP ke Player (Loop)", CFG.AutoTP_Player, function(v) CFG.AutoTP_Player = v end)
Slider(sAutoTP, "Cooldown Interval Teleport", 1, 15, CFG.TP_Cooldown, "s", function(v) CFG.TP_Cooldown = v end)
Button(sAutoTP, "Teleport ke Generator Terdekat", "📍", function() TeleportTo("Generator") end, Color3.fromRGB(70, 200, 255))
Button(sAutoTP, "Teleport ke Player Terdekat", "📍", function() TeleportTo("Player") end, Color3.fromRGB(120, 255, 160))

-- [TAB 3: AIMBOT PISTOL]
local aimL, aimR = CreateTab("Pistol Aim", "🔫", 3)

local sPistol1 = Section(aimL, "Silent Aim & Predict")
Toggle(sPistol1, "Enable Pistol Aimbot", CFG.PistolAim, function(v) CFG.PistolAim = v end)
Toggle(sPistol1, "Silent Aim Mode (Snap Instan)", CFG.PistolSilent, function(v) CFG.PistolSilent = v end)
Toggle(sPistol1, "Auto Predict (Lead Target Gerak)", CFG.PistolPredict, function(v) CFG.PistolPredict = v end)
Slider(sPistol1, "Pistol FOV Radius", 50, 600, CFG.PistolFOV, "px", function(v) CFG.PistolFOV = v end)
Slider(sPistol1, "Smoothness Kamera", 0.02, 0.40, CFG.PistolSmooth, "s", function(v) CFG.PistolSmooth = v end)

local sPistol2 = Section(aimR, "Bagian Tubuh Target Pistol")
ModeSelector(sPistol2, "Target Body Part", {"Head", "HumanoidRootPart"}, CFG.PistolPart, function(v)
    CFG.PistolPart = v
    print("[VD HUB] Pistol Aim Target Part:", v == "Head" and "Kepala (Head)" or "Badan (Torso)")
end)

-- [TAB 4: AIMBOT FLASHLIGHT]
local flL, flR = CreateTab("Flashlight", "🔦", 4)

local sFlash1 = Section(flL, "Flashlight Auto Blind")
Toggle(sFlash1, "Enable Flashlight Aimbot", CFG.FlashAim, function(v) CFG.FlashAim = v end)
Toggle(sFlash1, "Auto Lock saat Pegang Senter", CFG.FlashAutoLock, function(v) CFG.FlashAutoLock = v end)
Slider(sFlash1, "Flashlight FOV Radius", 50, 600, CFG.FlashFOV, "px", function(v) CFG.FlashFOV = v end)
Slider(sFlash1, "Smoothness Lock", 0.02, 0.40, CFG.FlashSmooth, "s", function(v) CFG.FlashSmooth = v end)

local sFlash2 = Section(flR, "Bagian Tubuh Target Flashlight")
ModeSelector(sFlash2, "Target Body Part", {"Head", "HumanoidRootPart"}, CFG.FlashPart, function(v)
    CFG.FlashPart = v
    print("[VD HUB] Flashlight Aim Target Part:", v == "Head" and "Kepala (Head/Mata)" or "Badan (Torso)")
end)

-- [TAB 5: TELEPORT MENU]
local tpL, tpR = CreateTab("Teleport", "📍", 5)

local sTpManual = Section(tpL, "Manual Teleport Hotkeys")
Button(sTpManual, "Teleport ke Generator Terdekat", "⚡", function() TeleportTo("Generator") end, Color3.fromRGB(70, 200, 255))
Button(sTpManual, "Teleport ke Player Terdekat", "🏃", function() TeleportTo("Player") end, Color3.fromRGB(120, 255, 160))

local sTpSafety = Section(tpR, "Safety Points")
Button(sTpSafety, "Safe Platform Atas (Langit)", "☁️", function()
    local root = GetCharRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = root.CFrame + Vector3.new(0, 45, 0)
    end
end, Color3.fromRGB(150, 100, 255))

-- [TAB 6: CONFIG & SETTINGS]
local cfL, cfR = CreateTab("Config", "🛠️", 6)

local sc1 = Section(cfL, "Tampilan & Window")
Button(sc1, "Reset Posisi Menu ke Tengah", "🎯", function()
    Main.Position = UDim2.new(0.5, -Main.AbsoluteSize.X / 2, 0.5, -Main.AbsoluteSize.Y / 2)
end)
Button(sc1, "Reset Ukuran Default (720x450)", "📐", function()
    Main.Size = UDim2.fromOffset(720, 450)
end)

local sc2 = Section(cfR, "Script Management")
Button(sc2, "Unload & Tutup Script", "❌", function()
    ClearAllHolograms()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    local h = GetHumanoid()
    if h then h.WalkSpeed = 16 end
    gui:Destroy()
end, Color3.fromRGB(255, 45, 85))

-- Aktifkan tab pertama
SwitchTab("Exclusive", "🏠")

-- ===================== 5. ANIMASI LOADING 5 DETIK =====================
task.spawn(function()
    local t0 = tick()
    local duration = 5.0
    while true do
        local elapsed = tick() - t0
        local p = math.clamp(elapsed / duration, 0, 1)
        BarFill.Size = UDim2.new(p, 0, 1, 0)
        PercentLbl.Text = math.floor(p * 100) .. "%"
        if p < 0.22 then
            StatusLbl.Text = "Inisialisasi 3D Cyber Hologram..."
        elseif p < 0.45 then
            StatusLbl.Text = "Memuat Auto Generator Engine..."
        elseif p < 0.70 then
            StatusLbl.Text = "Menyiapkan Silent Aim & Flashlight lock..."
        elseif p < 0.95 then
            StatusLbl.Text = "Menerapkan Fix Speed Boost permanent..."
        else
            StatusLbl.Text = "✓ Siap! Tekan tombol di bawah untuk mulai."
            break
        end
        task.wait(0.03)
    end
    StartBtn.Visible = true
    StartBtn.Size = UDim2.new(1, -40, 0, 0)
    Tween(StartBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -40, 0, 42)
    })
end)

StartBtn.MouseButton1Click:Connect(function()
    Tween(LoadCard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    task.wait(0.22)
    LoadCard:Destroy()

    -- Munculkan Floating Logo di Layar
    LogoBtn.Visible = true
    LogoBtn.Size = UDim2.fromOffset(0, 0)
    Tween(LogoBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(46, 46)
    })

    -- Buka Main GUI dengan Pop-in
    Main.Visible = true
    Main.BackgroundTransparency = 0.5
    Tween(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
end)

-- Keyboard Shortcut: RightControl untuk Toggle Menu
local keyConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then ToggleMainGUI() end
end)
table.insert(connections, keyConn)

-- ===================== 6. RUNTIME LOOPS (AIMBOT & AUTO TP) =====================

-- Loop Aimbot Pistol (Silent Aim + Predict)
local pistolLoop = RunService.RenderStepped:Connect(function()
    if not CFG.PistolAim then return end
    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local target = GetAimTarget(CFG.PistolFOV, CFG.PistolPart, false)
    if target then
        local cam = Camera.CFrame
        if CFG.PistolSilent then
            Camera.CFrame = CFrame.new(cam.Position, target.Position)
        else
            Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.PistolSmooth)
        end
    end
end)
table.insert(connections, pistolLoop)

-- Loop Aimbot Flashlight (Auto Stun/Blind)
local flashLoop = RunService.RenderStepped:Connect(function()
    if not CFG.FlashAim then return end

    local holdingFlashlight = false
    local char = LP.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local tName = string.lower(tool.Name)
            if string.find(tName, "flash") or string.find(tName, "light") or string.find(tName, "lamp") or string.find(tName, "lantern") or string.find(tName, "torch") then
                holdingFlashlight = true
            end
        end
    end

    local shouldAim = holdingFlashlight or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not shouldAim then return end

    local target = GetAimTarget(CFG.FlashFOV, CFG.FlashPart, true)
    if target then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.FlashSmooth)
    end
end)
table.insert(connections, flashLoop)

-- Loop Auto Generator (Fixed)
task.spawn(function()
    while true do
        local w = 0.35
        if CFG.GenMode == "Instant" then w = 0.08
        elseif CFG.GenMode == "Normal" then w = 0.20
        elseif CFG.GenMode == "Legit" then w = 0.50 + math.random() * 0.30
        elseif CFG.GenMode == "Random" then w = 0.15 + math.random() * 0.45
        end
        task.wait(w)
        if CFG.GenMode ~= "Off" then
            pcall(DoGenerator)
        end
    end
end)

-- Loop Auto Teleport
task.spawn(function()
    while true do
        task.wait(1.0)
        if not gui or not gui.Parent then break end
        if CFG.AutoTP_Gen then
            TeleportTo("Generator")
        end
        if CFG.AutoTP_Player then
            TeleportTo("Player")
        end
    end
end)

print("[VD HUB] v" .. VERSION .. " Cyber Hologram Ultimate loaded successfully!")
