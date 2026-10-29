--[[
    VD HUB v6.2 | Violence District
    - Speed anti-rubberband
    - Hologram ESP match-only
    - Generator via ReplicatedStorage.Remotes.Generator.RepairEvent
    - Mode: Off / Normal / Legit / Instant / Random
    - Toggle OFF = hard stop
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
local RS           = game:GetService("ReplicatedStorage")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CFG = {
    Holo_Player    = true,
    Holo_Generator = true,
    Holo_Pallet    = true,
    Holo_Vault     = true,
    Holo_DistTag   = true,
    Holo_MaxDist   = 550,
    Holo_FillTrans = 0.55,

    GenMode        = "Normal",
    GenRange       = 26,

    AutoTP_Gen     = false,
    AutoTP_Player  = false,
    TP_Cooldown    = 3,

    PistolAim      = false,
    PistolSilent   = true,
    PistolPredict  = true,
    PistolPart     = "Head",
    PistolFOV      = 280,
    PistolSmooth   = 0.14,

    FlashAim       = false,
    FlashPart      = "Head",
    FlashFOV       = 320,
    FlashSmooth    = 0.16,

    Speed          = false,
    WalkSpeed      = 22,
    AutoRun        = false,
}

local VERSION = "6.2"
local connections = {}
local hologramInstances = {}
local lastTPTime = 0
local cachedGenerators = {}
local genBusy = false
local speedConn, speedCharConn = nil, nil

-- Generator remotes (dari Dex)
local RepairEvent
pcall(function()
    RepairEvent = RS:WaitForChild("Remotes", 5)
        :WaitForChild("Generator", 5)
        :WaitForChild("RepairEvent", 5)
end)

local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function GetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChild("GeneratorBody")
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function GetCharRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsInMatch()
    if workspace:FindFirstChild("Map") then return true end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name == "Generator" and o:IsA("Model") then return true end
    end
    return #Players:GetPlayers() >= 2
end

-- ===================== GENERATOR CACHE + REMOTE =====================
local function UpdateGeneratorCache()
    table.clear(cachedGenerators)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            local body = obj:FindFirstChild("GeneratorBody") or GetPart(obj)
            if body then
                table.insert(cachedGenerators, {Model = obj, Part = body})
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(UpdateGeneratorCache)
        task.wait(3)
    end
end)

local function GetClosestTarget(list, myPos, maxDist)
    local best, bestDist = nil, maxDist or math.huge
    for _, item in ipairs(list) do
        local part = item.Part
        if part and part.Parent then
            local d = (part.Position - myPos).Magnitude
            if d < bestDist then bestDist = d best = item end
        end
    end
    return best, bestDist
end

local function GetGenDelay()
    local m = CFG.GenMode
    if m == "Instant" then return 0.03
    elseif m == "Normal" then return 0.20
    elseif m == "Legit" then return 0.50 + math.random() * 0.35
    elseif m == "Random" then return 0.10 + math.random() * 0.50
    end
    return 0.25
end

local function GetGenLoopWait()
    local m = CFG.GenMode
    if m == "Instant" then return 0.08
    elseif m == "Normal" then return 0.25
    elseif m == "Legit" then return 0.60 + math.random() * 0.30
    elseif m == "Random" then return 0.15 + math.random() * 0.45
    end
    return 0.3
end

local function FireRepair(genModel)
    if not genModel or not RepairEvent then return end
    pcall(function() RepairEvent:FireServer(genModel) end)
    pcall(function() RepairEvent:FireServer(genModel, true) end)
end

local function DoGenerator()
    if CFG.GenMode == "Off" then return end
    if genBusy then return end
    genBusy = true
    pcall(function()
        local root = GetCharRoot()
        if not root then return end
        local range = CFG.GenRange or 26
        local nearby = {}
        for _, g in ipairs(cachedGenerators) do
            if g.Part and g.Part.Parent then
                local d = (g.Part.Position - root.Position).Magnitude
                if d <= range then table.insert(nearby, {Gen = g, Dist = d}) end
            end
        end
        table.sort(nearby, function(a, b) return a.Dist < b.Dist end)
        for _, item in ipairs(nearby) do
            if CFG.GenMode == "Off" then break end
            FireRepair(item.Gen.Model)
            task.wait(GetGenDelay())
            if CFG.GenMode == "Instant" then
                FireRepair(item.Gen.Model)
                task.wait(0.02)
            end
        end
    end)
    genBusy = false
end

task.spawn(function()
    while true do
        if CFG.GenMode == "Off" then
            task.wait(0.4)
        else
            task.wait(GetGenLoopWait())
            pcall(DoGenerator)
        end
    end
end)

-- ===================== TELEPORT =====================
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
        local list = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local pr = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if pr and hum and hum.Health > 0 then
                    table.insert(list, {Part = pr})
                end
            end
        end
        local best = GetClosestTarget(list, root.Position)
        if best and best.Part then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = best.Part.CFrame * CFrame.new(0, 3, 4)
            lastTPTime = tick()
        end
    end
end

-- ===================== AIM =====================
local function PredictPosition(targetPart)
    if not targetPart or not targetPart:IsA("BasePart") then
        return targetPart and targetPart.Position or Vector3.zero
    end
    if not CFG.PistolPredict then return targetPart.Position end
    local vel = targetPart.AssemblyLinearVelocity or Vector3.zero
    if vel.Magnitude < 0.5 then return targetPart.Position end
    local dist = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local lead = math.clamp(dist / 650, 0.03, 0.32)
    return targetPart.Position + vel * lead
end

local function GetAimTarget(fov, aimPartName)
    local mouse = UIS:GetMouseLocation()
    local best, bestDist = nil, fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = plr.Character:FindFirstChild(aimPartName)
                or plr.Character:FindFirstChild("Head")
                or plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and part then
                local worldPos = PredictPosition(part)
                local sp, on = Camera:WorldToViewportPoint(worldPos)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = {Position = worldPos}
                    end
                end
            end
        end
    end
    return best
end

-- ===================== SPEED FIX =====================
local function ClearSpeedHooks()
    if speedConn then speedConn:Disconnect() speedConn = nil end
    if speedCharConn then speedCharConn:Disconnect() speedCharConn = nil end
end

local function EnableSpeed()
    ClearSpeedHooks()
    local hum = GetHumanoid()
    if hum and math.abs(hum.WalkSpeed - CFG.WalkSpeed) > 0.5 then
        hum.WalkSpeed = CFG.WalkSpeed
    end
    hum = GetHumanoid()
    if hum then
        speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if CFG.Speed and hum.Parent and math.abs(hum.WalkSpeed - CFG.WalkSpeed) > 0.5 then
                task.defer(function()
                    if CFG.Speed and hum and hum.Parent then
                        hum.WalkSpeed = CFG.WalkSpeed
                    end
                end)
            end
        end)
    end
    speedCharConn = LP.CharacterAdded:Connect(function()
        task.wait(0.35)
        if CFG.Speed then EnableSpeed() end
    end)
end

local function DisableSpeed()
    ClearSpeedHooks()
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 end
end

-- ===================== HOLOGRAM ESP =====================
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

local function ClearAllHolograms()
    for _, item in pairs(hologramInstances) do
        if item.Highlight then pcall(function() item.Highlight:Destroy() end) end
        if item.Billboard then pcall(function() item.Billboard:Destroy() end) end
    end
    table.clear(hologramInstances)
    espFolder:ClearAllChildren()
end

local function ClearHologramsByType(kind)
    for key, data in pairs(hologramInstances) do
        local kill = false
        if kind == "player" and data.IsPlayer then kill = true end
        if data.TitleLabel then
            local t = data.TitleLabel.Text
            if kind == "generator" and string.find(t, "GENERATOR") then kill = true end
            if kind == "vault" and string.find(t, "VAULT") then kill = true end
            if kind == "pallet" and string.find(t, "PALLET") then kill = true end
        end
        if kill then
            if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
            if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
            hologramInstances[key] = nil
        end
    end
end

local function CreateHologram(target, nameText, fillCol, outlineCol, isPlayer)
    if not target then return end
    local part = GetPart(target)
    if not part then return end
    local key = tostring(target)
    pcall(function() key = target:GetDebugId() end)
    if hologramInstances[key] then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.FillColor = fillCol
    hl.FillTransparency = CFG.Holo_FillTrans
    hl.OutlineColor = outlineCol
    hl.OutlineTransparency = 0.05
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder

    local bb = Instance.new("BillboardGui")
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(120, 36)
    bb.StudsOffset = Vector3.new(0, isPlayer and 3.2 or 2.2, 0)
    bb.Parent = espFolder

    local card = Instance.new("Frame", bb)
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    card.BackgroundTransparency = 0.35
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", card).Color = outlineCol

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
    distLbl.Size = UDim2.new(1, -6, 0, 14)
    distLbl.Position = UDim2.new(0, 3, 0, 18)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "0m"
    distLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    distLbl.TextSize = 9
    distLbl.Font = Enum.Font.GothamMedium

    hologramInstances[key] = {
        Target = target, Part = part,
        Highlight = hl, Billboard = bb,
        DistLabel = distLbl, TitleLabel = titleLbl,
        BaseColor = fillCol, OutlineColor = outlineCol,
        IsPlayer = isPlayer
    }
end

table.insert(connections, RunService.Heartbeat:Connect(function()
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
                data.Billboard.Enabled = CFG.Holo_DistTag
                local meters = math.floor(dist * 0.28)
                if data.IsPlayer and data.Target:IsA("Model") then
                    local hum = data.Target:FindFirstChildOfClass("Humanoid")
                    local hp = hum and math.floor(hum.Health) or 100
                    data.DistLabel.Text = meters .. "m | " .. hp .. "hp"
                    if hp < 30 then
                        data.Highlight.FillColor = Color3.fromRGB(255, 45, 65)
                    else
                        data.Highlight.FillColor = data.BaseColor
                    end
                else
                    data.DistLabel.Text = meters .. "m"
                end
            end
        end
    end
end))

task.spawn(function()
    while true do
        task.wait(1.4)
        if not gui.Parent then break end
        if not IsInMatch() then
            ClearAllHolograms()
            continue
        end
        if CFG.Holo_Player then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local isKiller = (hum.MaxHealth > 100)
                        local fill = isKiller and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(0, 220, 255)
                        local out = isKiller and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(120, 245, 255)
                        local tag = (isKiller and "[KILLER] " or "") .. plr.DisplayName
                        CreateHologram(plr.Character, tag, fill, out, true)
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            local k = tostring(obj)
            pcall(function() k = obj:GetDebugId() end)
            if hologramInstances[k] then continue end
            if CFG.Holo_Generator and obj.Name == "Generator" and obj:IsA("Model") then
                CreateHologram(obj, "GENERATOR", Color3.fromRGB(0, 185, 255), Color3.fromRGB(70, 225, 255), false)
            elseif CFG.Holo_Vault and (string.find(n, "vault") or string.find(n, "window")) then
                if GetPart(obj) then
                    CreateHologram(obj, "VAULT", Color3.fromRGB(255, 210, 50), Color3.fromRGB(255, 230, 110), false)
                end
            elseif CFG.Holo_Pallet and string.find(n, "pallet") then
                if GetPart(obj) then
                    CreateHologram(obj, "PALLET", Color3.fromRGB(255, 130, 40), Color3.fromRGB(255, 170, 80), false)
                end
            end
        end
    end
end)

-- ===================== GUI =====================
local LoadCard = Instance.new("Frame")
LoadCard.Size = UDim2.fromOffset(340, 200)
LoadCard.Position = UDim2.new(0.5, -170, 0.5, -100)
LoadCard.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
LoadCard.BorderSizePixel = 0
LoadCard.Parent = gui
Instance.new("UICorner", LoadCard).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", LoadCard).Color = Color3.fromRGB(255, 45, 85)

local LTitle = Instance.new("TextLabel", LoadCard)
LTitle.Size = UDim2.new(1, -40, 0, 24)
LTitle.Position = UDim2.new(0, 20, 0, 18)
LTitle.BackgroundTransparency = 1
LTitle.Text = "VD HUB  v" .. VERSION
LTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
LTitle.TextSize = 16
LTitle.Font = Enum.Font.GothamBold
LTitle.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", LoadCard)
StatusLbl.Size = UDim2.new(1, -40, 0, 18)
StatusLbl.Position = UDim2.new(0, 20, 0, 70)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Loading..."
StatusLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLbl.TextSize = 12
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local BarTrack = Instance.new("Frame", LoadCard)
BarTrack.Size = UDim2.new(1, -40, 0, 7)
BarTrack.Position = UDim2.new(0, 20, 0, 100)
BarTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
BarTrack.BorderSizePixel = 0
Instance.new("UICorner", BarTrack).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame", BarTrack)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local StartBtn = Instance.new("TextButton", LoadCard)
StartBtn.Size = UDim2.new(1, -40, 0, 40)
StartBtn.Position = UDim2.new(0, 20, 0, 130)
StartBtn.BackgroundColor3 = Color3.fromRGB(235, 40, 80)
StartBtn.Text = "BUKA VD HUB"
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.TextSize = 13
StartBtn.Font = Enum.Font.GothamBold
StartBtn.Visible = false
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(700, 420)
Main.Position = UDim2.new(0.5, -350, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(40, 40, 52)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
Sidebar.BorderSizePixel = 0

local SideTitle = Instance.new("TextLabel", Sidebar)
SideTitle.Size = UDim2.new(1, -12, 0, 36)
SideTitle.Position = UDim2.new(0, 10, 0, 6)
SideTitle.BackgroundTransparency = 1
SideTitle.Text = "VD Hub " .. VERSION
SideTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
SideTitle.TextSize = 13
SideTitle.Font = Enum.Font.GothamBold
SideTitle.TextXAlignment = Enum.TextXAlignment.Left

local TabScroll = Instance.new("ScrollingFrame", Sidebar)
TabScroll.Size = UDim2.new(1, 0, 1, -48)
TabScroll.Position = UDim2.new(0, 0, 0, 44)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 2
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabScroll.CanvasSize = UDim2.new()
Instance.new("UIListLayout", TabScroll).Padding = UDim.new(0, 3)
local padT = Instance.new("UIPadding", TabScroll)
padT.PaddingLeft = UDim.new(0, 8)
padT.PaddingRight = UDim.new(0, 8)

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -150, 1, 0)
ContentArea.Position = UDim2.new(0, 150, 0, 0)
ContentArea.BackgroundTransparency = 1

local TopHead = Instance.new("Frame", ContentArea)
TopHead.Size = UDim2.new(1, 0, 0, 38)
TopHead.BackgroundTransparency = 1

local TabTitle = Instance.new("TextLabel", TopHead)
TabTitle.Size = UDim2.new(1, -70, 1, 0)
TabTitle.Position = UDim2.new(0, 12, 0, 0)
TabTitle.BackgroundTransparency = 1
TabTitle.Text = "Exclusive"
TabTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
TabTitle.TextSize = 14
TabTitle.Font = Enum.Font.GothamBold
TabTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopHead)
CloseBtn.Size = UDim2.fromOffset(24, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 22, 28)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 95)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ClearAllHolograms()
    DisableSpeed()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end)

local MinBtn = Instance.new("TextButton", TopHead)
MinBtn.Size = UDim2.fromOffset(24, 24)
MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local PagesFolder = Instance.new("Folder", ContentArea)
local isDragging, isResizing = false, false
local dragStart, dragPos = Vector2.zero, UDim2.new()
local resStart, resSize = Vector2.zero, Vector2.zero

TopHead.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = UIS:GetMouseLocation()
        dragPos = Main.Position
    end
end)

local ResizeGrip = Instance.new("TextButton", Main)
ResizeGrip.Size = UDim2.fromOffset(16, 16)
ResizeGrip.Position = UDim2.new(1, -16, 1, -16)
ResizeGrip.BackgroundColor3 = Color3.fromRGB(255, 50, 90)
ResizeGrip.Text = ""
ResizeGrip.AutoButtonColor = false
Instance.new("UICorner", ResizeGrip).CornerRadius = UDim.new(0, 4)

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
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local m = UIS:GetMouseLocation()
    if isDragging then
        local d = m - dragStart
        Main.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
    end
    if isResizing then
        local d = m - resStart
        Main.Size = UDim2.fromOffset(math.clamp(resSize.X + d.X, 520, 920), math.clamp(resSize.Y + d.Y, 340, 640))
    end
end)

local tabButtons, tabPages = {}, {}
local function SwitchTab(name)
    TabTitle.Text = name
    for n, btn in pairs(tabButtons) do
        local a = n == name
        btn.BackgroundColor3 = a and Color3.fromRGB(26, 26, 36) or Color3.fromRGB(14, 14, 19)
        btn.TextColor3 = a and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 170)
    end
    for n, p in pairs(tabPages) do p.Visible = (n == name) end
end

local function CreateTab(name, order)
    local btn = Instance.new("TextButton", TabScroll)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(14, 14, 19)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    tabButtons[name] = btn

    local page = Instance.new("ScrollingFrame", PagesFolder)
    page.Size = UDim2.new(1, 0, 1, -42)
    page.Position = UDim2.new(0, 0, 0, 42)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local pd = Instance.new("UIPadding", page)
    pd.PaddingLeft = UDim.new(0, 10)
    pd.PaddingRight = UDim.new(0, 10)
    pd.PaddingTop = UDim.new(0, 4)
    pd.PaddingBottom = UDim.new(0, 12)
    local cols = Instance.new("Frame", page)
    cols.Size = UDim2.new(1, 0, 0, 0)
    cols.BackgroundTransparency = 1
    cols.AutomaticSize = Enum.AutomaticSize.Y
    local left = Instance.new("Frame", cols)
    left.Size = UDim2.new(0.5, -4, 0, 0)
    left.BackgroundTransparency = 1
    left.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", left).Padding = UDim.new(0, 6)
    local right = Instance.new("Frame", cols)
    right.Size = UDim2.new(0.5, -4, 0, 0)
    right.Position = UDim2.new(0.5, 4, 0, 0)
    right.BackgroundTransparency = 1
    right.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", right).Padding = UDim.new(0, 6)
    tabPages[name] = page
    return left, right
end

local function Section(col, title)
    local f = Instance.new("Frame", col)
    f.Size = UDim2.new(1, 0, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    f.BorderSizePixel = 0
    f.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(28, 28, 38)
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1, -16, 0, 26)
    h.Position = UDim2.new(0, 8, 0, 0)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(240, 240, 250)
    h.TextSize = 12
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    local body = Instance.new("Frame", f)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 26)
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", body).Padding = UDim.new(0, 3)
    local bp = Instance.new("UIPadding", body)
    bp.PaddingLeft = UDim.new(0, 8)
    bp.PaddingRight = UDim.new(0, 8)
    bp.PaddingBottom = UDim.new(0, 8)
    return body
end

local function Toggle(parent, label, default, cb)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.fromOffset(30, 15)
    pill.Position = UDim2.new(1, -30, 0.5, -7)
    pill.BackgroundColor3 = default and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(34, 34, 46)
    pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.fromOffset(11, 11)
    knob.Position = default and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local state = default
    row.MouseButton1Click:Connect(function()
        state = not state
        pill.BackgroundColor3 = state and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(34, 34, 46)
        knob.Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        if cb then cb(state) end
    end)
end

local function Slider(parent, label, min, max, cur, cb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -40, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.fromOffset(40, 14)
    vl.Position = UDim2.new(1, -40, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(cur)
    vl.TextColor3 = Color3.fromRGB(255, 75, 110)
    vl.TextSize = 11
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Right
    local trk = Instance.new("Frame", row)
    trk.Size = UDim2.new(1, 0, 0, 5)
    trk.Position = UDim2.new(0, 0, 0, 20)
    trk.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    trk.BorderSizePixel = 0
    Instance.new("UICorner", trk).CornerRadius = UDim.new(1, 0)
    local pct = math.clamp((cur - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", trk)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local sliding = false
    local function upd()
        local m = UIS:GetMouseLocation()
        local r = math.clamp((m.X - trk.AbsolutePosition.X) / math.max(trk.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor(min + r * (max - min) + 0.5)
        fill.Size = UDim2.new(r, 0, 1, 0)
        vl.Text = tostring(v)
        if cb then cb(v) end
    end
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true upd() end
    end)
    table.insert(connections, UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd() end
    end))
    table.insert(connections, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end))
end

local function Button(parent, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    b.Text = "  " .. text
    b.TextColor3 = Color3.fromRGB(225, 225, 240)
    b.TextSize = 11
    b.Font = Enum.Font.GothamMedium
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
end

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
    local row = Instance.new("Frame", wrap)
    row.Size = UDim2.new(1, 0, 0, 26)
    row.Position = UDim2.new(0, 0, 0, 18)
    row.BackgroundTransparency = 1
    local lay = Instance.new("UIListLayout", row)
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding = UDim.new(0, 4)
    local btns = {}
    for _, opt in ipairs(options) do
        local b = Instance.new("TextButton", row)
        b.Size = UDim2.new(1 / #options, -3, 1, 0)
        b.BackgroundColor3 = (opt == default) and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(24, 24, 34)
        b.Text = opt
        b.TextColor3 = (opt == default) and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 180)
        b.TextSize = 10
        b.Font = Enum.Font.GothamMedium
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        b.MouseButton1Click:Connect(function()
            for _, item in ipairs(btns) do
                local sel = item.mode == opt
                item.btn.BackgroundColor3 = sel and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(24, 24, 34)
                item.btn.TextColor3 = sel and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 180)
            end
            if cb then cb(opt) end
        end)
        table.insert(btns, {btn = b, mode = opt})
    end
end

-- Tabs
local exL, exR = CreateTab("Exclusive", 1)
local sESP = Section(exL, "Hologram ESP")
Toggle(sESP, "Player / Killer", CFG.Holo_Player, function(v)
    CFG.Holo_Player = v
    if not v then ClearHologramsByType("player") end
end)
Toggle(sESP, "Generator", CFG.Holo_Generator, function(v)
    CFG.Holo_Generator = v
    if not v then ClearHologramsByType("generator") end
end)
Toggle(sESP, "Vault", CFG.Holo_Vault, function(v)
    CFG.Holo_Vault = v
    if not v then ClearHologramsByType("vault") end
end)
Toggle(sESP, "Pallet", CFG.Holo_Pallet, function(v)
    CFG.Holo_Pallet = v
    if not v then ClearHologramsByType("pallet") end
end)
Toggle(sESP, "Distance Tag", CFG.Holo_DistTag, function(v) CFG.Holo_DistTag = v end)
Slider(sESP, "Max Distance", 100, 900, CFG.Holo_MaxDist, function(v) CFG.Holo_MaxDist = v end)
Button(sESP, "Clear Holograms", function() ClearAllHolograms() end)

local sMove = Section(exR, "Speed")
Toggle(sMove, "Speed Boost", CFG.Speed, function(v)
    CFG.Speed = v
    if v then EnableSpeed() else DisableSpeed() end
end)
Slider(sMove, "WalkSpeed", 16, 40, CFG.WalkSpeed, function(v)
    CFG.WalkSpeed = v
    if CFG.Speed then EnableSpeed() end
end)

local genL, genR = CreateTab("Generator", 2)
local sGen = Section(genL, "Auto Generator (Remote)")
ModeSelector(sGen, "Mode", {"Off", "Normal", "Legit", "Instant", "Random"}, CFG.GenMode, function(v)
    CFG.GenMode = v
end)
Slider(sGen, "Range", 10, 45, CFG.GenRange, function(v) CFG.GenRange = v end)
Button(sGen, "Trigger Repair Now", function() pcall(DoGenerator) end)

local sTP = Section(genR, "Teleport")
Toggle(sTP, "Auto TP Gen", CFG.AutoTP_Gen, function(v) CFG.AutoTP_Gen = v end)
Toggle(sTP, "Auto TP Player", CFG.AutoTP_Player, function(v) CFG.AutoTP_Player = v end)
Slider(sTP, "Cooldown sec", 1, 15, CFG.TP_Cooldown, function(v) CFG.TP_Cooldown = v end)
Button(sTP, "TP Generator", function() TeleportTo("Generator") end)
Button(sTP, "TP Player", function() TeleportTo("Player") end)

local aimL, aimR = CreateTab("Pistol Aim", 3)
local sP = Section(aimL, "Pistol")
Toggle(sP, "Enable", CFG.PistolAim, function(v) CFG.PistolAim = v end)
Toggle(sP, "Silent", CFG.PistolSilent, function(v) CFG.PistolSilent = v end)
Toggle(sP, "Predict", CFG.PistolPredict, function(v) CFG.PistolPredict = v end)
Slider(sP, "FOV", 50, 600, CFG.PistolFOV, function(v) CFG.PistolFOV = v end)
local sP2 = Section(aimR, "Part")
ModeSelector(sP2, "Target", {"Head", "HumanoidRootPart"}, CFG.PistolPart, function(v) CFG.PistolPart = v end)

local flL, flR = CreateTab("Flashlight", 4)
local sF = Section(flL, "Flash Aim")
Toggle(sF, "Enable", CFG.FlashAim, function(v) CFG.FlashAim = v end)
Slider(sF, "FOV", 50, 600, CFG.FlashFOV, function(v) CFG.FlashFOV = v end)
local sF2 = Section(flR, "Part")
ModeSelector(sF2, "Target", {"Head", "HumanoidRootPart"}, CFG.FlashPart, function(v) CFG.FlashPart = v end)

SwitchTab("Exclusive")

task.spawn(function()
    local t0 = tick()
    while tick() - t0 < 4 do
        local p = (tick() - t0) / 4
        BarFill.Size = UDim2.new(p, 0, 1, 0)
        StatusLbl.Text = "Loading " .. math.floor(p * 100) .. "%"
        task.wait(0.03)
    end
    StatusLbl.Text = "Siap — RepairEvent linked"
    StartBtn.Visible = true
end)

StartBtn.MouseButton1Click:Connect(function()
    LoadCard:Destroy()
    Main.Visible = true
    if not RepairEvent then
        warn("[VD HUB] RepairEvent tidak ketemu — cek Remotes.Generator")
    else
        print("[VD HUB] RepairEvent OK:", RepairEvent:GetFullName())
    end
end)

table.insert(connections, UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
    end
end))

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not CFG.PistolAim then return end
    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local t = GetAimTarget(CFG.PistolFOV, CFG.PistolPart)
    if t then
        local cam = Camera.CFrame
        if CFG.PistolSilent then
            Camera.CFrame = CFrame.new(cam.Position, t.Position)
        else
            Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, t.Position), CFG.PistolSmooth)
        end
    end
end))

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not CFG.FlashAim then return end
    local hold = false
    local char = LP.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local n = string.lower(tool.Name)
            if string.find(n, "flash") or string.find(n, "light") or string.find(n, "torch") then
                hold = true
            end
        end
    end
    if not (hold or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then return end
    local t = GetAimTarget(CFG.FlashFOV, CFG.FlashPart)
    if t then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), CFG.FlashSmooth)
    end
end))

task.spawn(function()
    while true do
        task.wait(1)
        if not gui.Parent then break end
        if CFG.AutoTP_Gen then TeleportTo("Generator") end
        if CFG.AutoTP_Player then TeleportTo("Player") end
    end
end)

print("[VD HUB] v" .. VERSION .. " | RepairEvent + speed fix + match ESP")
