--[[
    QUANTUM HUB v7.0 | Violence District (Zibey Edition)
    =============================================================
    ARCHITECT: Quantum by zibey
    PATCHED: CoreGui exploits, Stats service crashes, UI rendering.
]]

--// Services & Environment
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()

--// Executor Environment Fallbacks
local uiParent = gethui and gethui() or CoreGui
local fireproximityprompt = fireproximityprompt or function() end

-- ===================== KONFIGURASI GLOBAL =====================
local CFG = {
    Holo_Player = true, Holo_Killer = true, Holo_Generator = true,
    Holo_Vault = true, Holo_Pallet = true, Holo_Gate = true,
    Holo_MaxDist = 600, Holo_FillTrans = 0.55, Holo_DistTag = true,
    GenMode = "Normal", GenRange = 26, AutoSkillcheck = true,
    AutoTP_Gen = false, AutoTP_Player = false, TP_Cooldown = 3,
    PistolAim = false, PistolSilent = true, PistolPredict = true,
    PistolPart = "Head", PistolFOV = 280, PistolSmooth = 0.14,
    FlashAim = false, FlashPart = "Head", FlashFOV = 320,
    FlashSmooth = 0.16, FlashAutoLock = true,
    SpearAim = false, SpearPredict = true, SpearSpeed = 220,
    Speed = false, WalkSpeed = 24, AutoRun = false,
    PerfectLanding = true, AdrenalineRush = false,
}

local VERSION = "v7.0 Zibey"
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
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function GetCharRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- PATCHED: Stats Service Error Fix
local function GetPingSeconds()
    local ping = 0
    pcall(function()
        local stats = game:FindService("Stats") or game:FindFirstChild("Stats")
        if stats and stats.Network and stats.Network.ServerStatsItem then
            local item = stats.Network.ServerStatsItem["Data Ping"]
            if item then ping = item:GetValue() end
        end
    end)
    return math.clamp(ping / 1000, 0, 0.5)
end

-- ===================== GENERATOR SCANNER & CACHE =====================
local function UpdateGeneratorCache()
    table.clear(cachedGenerators)
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent")) then
            local part = GetPart(obj)
            if part then table.insert(cachedGenerators, {Obj = obj, Part = part}) end
        end
    end
end

task.spawn(function()
    while true do
        UpdateGeneratorCache()
        task.wait(3.5)
    end
end)

local function GetClosestTarget(list, myPos, maxDist)
    local best, bestDist = nil, maxDist or math.huge
    for _, item in ipairs(list) do
        if item.Part and item.Part.Parent then
            local d = (item.Part.Position - myPos).Magnitude
            if d < bestDist then bestDist = d; best = item end
        end
    end
    return best, bestDist
end

-- ===================== PROXIMITY PROMPT INTERACTOR =====================
local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.HoldDuration = 0
        fireproximityprompt(prompt)
    end)
end

-- ===================== AUTO GENERATOR SYSTEM =====================
local function DoGenerator()
    if CFG.GenMode == "Off" then return end
    local root = GetCharRoot()
    if not root then return end

    local delayTime = 0.16
    if CFG.GenMode == "Instant" then delayTime = 0.01
    elseif CFG.GenMode == "Legit" then delayTime = 0.38 + math.random() * 0.26
    elseif CFG.GenMode == "Random" then delayTime = 0.09 + math.random() * 0.42 end

    for _, gen in ipairs(cachedGenerators) do
        if gen.Part and gen.Part.Parent and (gen.Part.Position - root.Position).Magnitude <= CFG.GenRange then
            local prompts = {}
            for _, d in ipairs(gen.Obj:GetDescendants()) do
                if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
            end
            for _, prompt in ipairs(prompts) do
                task.spawn(function()
                    task.wait(delayTime)
                    FirePrompt(prompt)
                end)
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
        local pList = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local pRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if pRoot and hum and hum.Health > 0 then
                    table.insert(pList, {Part = pRoot, Obj = plr.Character})
                end
            end
        end
        local best = GetClosestTarget(pList, root.Position)
        if best and best.Part then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = best.Part.CFrame * CFrame.new(0, 3.5, 4)
            lastTPTime = tick()
        end
    elseif category == "Gate" then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if string.find(n, "gate") or string.find(n, "door") or string.find(n, "exit") then
                local part = GetPart(obj)
                if part then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.CFrame = part.CFrame * CFrame.new(0, 3.5, 3)
                    lastTPTime = tick()
                    break
                end
            end
        end
    end
end

-- ===================== AIMBOT ENGINE =====================
local function PredictPosition(targetPart, projectileSpeed)
    if not targetPart or not targetPart:IsA("BasePart") then return targetPart.Position end
    if not CFG.PistolPredict and not CFG.SpearPredict then return targetPart.Position end
    local vel = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero
    if vel.Magnitude < 0.4 then return targetPart.Position end
    local dist = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local spd = projectileSpeed or 650
    local ping = GetPingSeconds()
    local leadTime = math.clamp((dist / spd) + ping, 0.03, 0.40)
    return targetPart.Position + (vel * leadTime)
end

local function GetAimTarget(fov, aimPartName, isFlashlight)
    local mouseLoc = UserInputService:GetMouseLocation()
    local best, bestDist = nil, fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local charName = string.lower(plr.Character.Name)
            local isKiller = string.find(charName, "killer") or string.find(charName, "monster") or (hum and hum.MaxHealth > 100)
            if isFlashlight and not isKiller and #Players:GetPlayers() > 2 then continue end
            local targetPart = plr.Character:FindFirstChild(aimPartName) or plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and targetPart then
                local worldPos = PredictPosition(targetPart, 650)
                local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
                if onScreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - mouseLoc).Magnitude
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

-- ===================== SPEED & PERKS ENGINE =====================
local function ApplySpeedBoost()
    local hum = GetHumanoid()
    if not hum then return end
    if CFG.Speed then hum.WalkSpeed = CFG.WalkSpeed end
    if CFG.AutoRun and hum.MoveDirection.Magnitude > 0 then hum.WalkSpeed = math.max(hum.WalkSpeed, CFG.WalkSpeed) end
end

local function BindSpeedGuard(char)
    task.wait(0.2)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if CFG.Speed and hum.WalkSpeed ~= CFG.WalkSpeed then hum.WalkSpeed = CFG.WalkSpeed end
        end)
    end
end
if LP.Character then BindSpeedGuard(LP.Character) end
LP.CharacterAdded:Connect(BindSpeedGuard)
table.insert(connections, RunService.Heartbeat:Connect(ApplySpeedBoost))

task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LP.Character
        if char then
            if CFG.PerfectLanding and char:GetAttribute("MovementLocked") then char:SetAttribute("MovementLocked", false) end
            if CFG.AdrenalineRush then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.Health <= 50 then hum.WalkSpeed = math.max(hum.WalkSpeed, 28) end
            end
        end
    end
end)

-- ===================== UI SETUP & ZIBEY BRANDING =====================
pcall(function() local old = uiParent:FindFirstChild("QUANTUM_ZIBEY_GUI") if old then old:Destroy() end end)
local gui = Instance.new("ScreenGui")
gui.Name = "QUANTUM_ZIBEY_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = uiParent

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_FOLDER"
espFolder.Parent = gui

-- ===================== HOLOGRAM ESP =====================
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

    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.FillColor = fillCol
    hl.FillTransparency = CFG.Holo_FillTrans
    hl.OutlineColor = outlineCol
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder

    local bb = Instance.new("BillboardGui")
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(125, 38)
    bb.StudsOffset = Vector3.new(0, isPlayer and 3.2 or 2.2, 0)
    bb.Parent = espFolder

    local card = Instance.new("Frame", bb)
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke", card)
    st.Color = outlineCol
    st.Thickness = 1.5

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(1, -6, 0, 16)
    titleLbl.Position = UDim2.new(0, 3, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = nameText
    titleLbl.TextColor3 = outlineCol
    titleLbl.TextSize = 10
    titleLbl.Font = Enum.Font.GothamBold

    local distLbl = Instance.new("TextLabel", card)
    distLbl.Size = UDim2.new(1, -6, 0, 14)
    distLbl.Position = UDim2.new(0, 3, 0, 18)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "0m"
    distLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    distLbl.TextSize = 9
    distLbl.Font = Enum.Font.GothamMedium

    local entry = {Target = target, Part = part, Highlight = hl, Billboard = bb, DistLabel = distLbl, BaseColor = fillCol, OutlineColor = outlineCol, IsPlayer = isPlayer}
    hologramInstances[key] = entry
    return entry
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    local root = GetCharRoot()
    local myPos = root and root.Position or Camera.CFrame.Position
    for key, data in pairs(hologramInstances) do
        if not data.Target or not data.Target.Parent then
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
                    data.DistLabel.Text = meters .. "m  •  " .. hp .. " HP"
                else
                    data.DistLabel.Text = meters .. "m"
                end
            end
        end
    end
end))

task.spawn(function()
    while true do
        task.wait(1.5)
        if not gui or not gui.Parent then break end
        if CFG.Holo_Player then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local isKiller = string.find(string.lower(plr.Character.Name), "killer") or (hum.MaxHealth > 100)
                        local fillCol = isKiller and Color3.fromRGB(255, 30, 60) or Color3.fromRGB(0, 220, 255)
                        local outCol  = isKiller and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(120, 245, 255)
                        CreateHologram(plr.Character, (isKiller and "🔪 KILLER " or "🏃 ") .. plr.DisplayName, fillCol, outCol, true)
                    end
                end
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            local k = tostring(obj)
            pcall(function() k = obj:GetDebugId() end)
            if CFG.Holo_Generator and (string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent"))) then
                if GetPart(obj) and not hologramInstances[k] then CreateHologram(obj, "⚡ GENERATOR", Color3.fromRGB(180, 50, 255), Color3.fromRGB(220, 120, 255), false) end
            elseif CFG.Holo_Vault and (string.find(n, "vault") or string.find(n, "window")) then
                if GetPart(obj) and not hologramInstances[k] then CreateHologram(obj, "🚪 VAULT", Color3.fromRGB(255, 210, 50), Color3.fromRGB(255, 230, 110), false) end
            elseif CFG.Holo_Pallet and string.find(n, "pallet") then
                if GetPart(obj) and not hologramInstances[k] then CreateHologram(obj, "📦 PALLET", Color3.fromRGB(255, 130, 40), Color3.fromRGB(255, 170, 80), false) end
            elseif CFG.Holo_Gate and (string.find(n, "gate") or string.find(n, "door") or string.find(n, "exit")) then
                if GetPart(obj) and not hologramInstances[k] then CreateHologram(obj, "🏁 GATE", Color3.fromRGB(50, 235, 120), Color3.fromRGB(100, 255, 160), false) end
            end
        end
    end
end)

-- ===================== ZIBEY CYBERPUNK GUI =====================
local Main = Instance.new("Frame", gui)
Main.Size = UDim2.fromOffset(650, 420)
Main.Position = UDim2.new(0.5, -325, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(180, 50, 255)
local MainGrad = Instance.new("UIGradient", MainStroke)
MainGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 50, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 120))})

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 18, 35)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
local TopFix = Instance.new("Frame", TopBar)
TopFix.Size = UDim2.new(1, 0, 0, 12)
TopFix.Position = UDim2.new(0, 0, 1, -12)
TopFix.BackgroundColor3 = Color3.fromRGB(22, 18, 35)
TopFix.BorderSizePixel = 0

local Logo = Instance.new("TextLabel", TopBar)
Logo.Size = UDim2.fromOffset(30, 30)
Logo.Position = UDim2.new(0, 15, 0.5, -15)
Logo.BackgroundColor3 = Color3.fromRGB(180, 50, 255)
Logo.Text = "Q"
Logo.TextColor3 = Color3.new(1,1,1)
Logo.TextSize = 16
Logo.Font = Enum.Font.GothamBold
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 55, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "QUANTUM HUB <font color='#b432ff'>|</font> <font color='#ff2878'>by zibey</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(240, 240, 250)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.fromOffset(25, 25)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -12.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 120)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ClearAllHolograms()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end)

-- Drag Logic
local dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragStart = nil end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Tabs Setup
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(0, 140, 1, -45)
TabFrame.Position = UDim2.new(0, 0, 0, 45)
TabFrame.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
TabFrame.BorderSizePixel = 0
local TabLayout = Instance.new("UIListLayout", TabFrame)
TabLayout.Padding = UDim.new(0, 5)
local TabPad = Instance.new("UIPadding", TabFrame)
TabPad.PaddingTop = UDim.new(0, 10)
TabPad.PaddingLeft = UDim.new(0, 10)
TabPad.PaddingRight = UDim.new(0, 10)

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -140, 1, -45)
ContentArea.Position = UDim2.new(0, 140, 0, 45)
ContentArea.BackgroundTransparency = 1

local PagesFolder = Instance.new("Folder", ContentArea)
local tabButtons, tabPages = {}

local function SwitchTab(name)
    for n, btn in pairs(tabButtons) do
        local active = (n == name)
        Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(180, 50, 255) or Color3.fromRGB(25, 20, 40)})
    end
    for n, page in pairs(tabPages) do page.Visible = (n == name) end
end

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton", TabFrame)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
    btn.Text = " " .. icon .. "  " .. name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    tabButtons[name] = btn

    local page = Instance.new("ScrollingFrame", PagesFolder)
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(180, 50, 255)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    tabPages[name] = page
    return page
end

-- UI Elements Factory
local function Section(parent, title)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(22, 18, 35)
    f.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(35, 28, 55)
    
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1, -20, 0, 35)
    h.Position = UDim2.new(0, 10, 0, 0)
    h.BackgroundTransparency = 1
    h.Text = title
    h.TextColor3 = Color3.fromRGB(180, 50, 255)
    h.TextSize = 13
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    
    local body = Instance.new("Frame", f)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Position = UDim2.new(0, 0, 0, 35)
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    local bl = Instance.new("UIListLayout", body)
    bl.Padding = UDim.new(0, 8)
    local bp = Instance.new("UIPadding", body)
    bp.PaddingLeft = UDim.new(0, 15)
    bp.PaddingRight = UDim.new(0, 15)
    bp.PaddingBottom = UDim.new(0, 15)
    return body
end

local function Toggle(parent, label, default, cb)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, 0, 0, 25)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.fromOffset(36, 18)
    pill.Position = UDim2.new(1, -36, 0.5, -9)
    pill.BackgroundColor3 = default and Color3.fromRGB(180, 50, 255) or Color3.fromRGB(40, 30, 60)
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local state = default
    row.MouseButton1Click:Connect(function()
        state = not state
        Tween(pill, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(180, 50, 255) or Color3.fromRGB(40, 30, 60)})
        Tween(knob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
        if cb then cb(state) end
    end)
end

local function Slider(parent, label, min, max, cur, sfx, cb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -50, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.fromOffset(50, 15)
    vl.Position = UDim2.new(1, -50, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(cur) .. (sfx or "")
    vl.TextColor3 = Color3.fromRGB(255, 40, 120)
    vl.TextSize = 12
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Right
    
    local trk = Instance.new("Frame", row)
    trk.Size = UDim2.new(1, 0, 0, 6)
    trk.Position = UDim2.new(0, 0, 0, 25)
    trk.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    Instance.new("UICorner", trk).CornerRadius = UDim.new(1, 0)
    
    local pct = math.clamp((cur - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", trk)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 50, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local sliding = false
    local function upd()
        local m = UserInputService:GetMouseLocation()
        local tP = trk.AbsolutePosition.X
        local tS = trk.AbsoluteSize.X
        local r = math.clamp((m.X - tP) / tS, 0, 1)
        local v = math.floor(min + r * (max - min))
        fill.Size = UDim2.new(r, 0, 1, 0)
        vl.Text = tostring(v) .. (sfx or "")
        if cb then cb(v) end
    end
    row.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; upd() end end)
    local c1 = UserInputService.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then upd() end end)
    local c2 = UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    table.insert(connections, c1)
    table.insert(connections, c2)
end

-- Build Tabs
local pgESP = CreateTab("Hologram", "👁️", 1)
local secESP = Section(pgESP, "ZIBEY ESP MATRIX")
Toggle(secESP, "Player & Killer Hologram", CFG.Holo_Player, function(v) CFG.Holo_Player = v end)
Toggle(secESP, "Generator Hologram (Neon Purple)", CFG.Holo_Generator, function(v) CFG.Holo_Generator = v end)
Toggle(secESP, "Vault & Window Hologram", CFG.Holo_Vault, function(v) CFG.Holo_Vault = v end)
Toggle(secESP, "Pallet Hologram", CFG.Holo_Pallet, function(v) CFG.Holo_Pallet = v end)
Toggle(secESP, "Escape Gate Hologram", CFG.Holo_Gate, function(v) CFG.Holo_Gate = v end)
Slider(secESP, "Max ESP Distance", 100, 900, CFG.Holo_MaxDist, "m", function(v) CFG.Holo_MaxDist = v end)

local pgMove = CreateTab("Movement", "🏃", 2)
local secMove = Section(pgMove, "SPEED & PHYSICS OVERRIDE")
Toggle(secMove, "Aktifkan Speed Boost", CFG.Speed, function(v) CFG.Speed = v; ApplySpeedBoost() end)
Toggle(secMove, "Auto Run Otomatis", CFG.AutoRun, function(v) CFG.AutoRun = v end)
Toggle(secMove, "Perfect Landing (No Fall Damage)", CFG.PerfectLanding, function(v) CFG.PerfectLanding = v end)
Slider(secMove, "WalkSpeed Multiplier", 16, 120, CFG.WalkSpeed, " spd", function(v) CFG.WalkSpeed = v; ApplySpeedBoost() end)

local pgCombat = CreateTab("Combat", "🔪", 3)
local secAim = Section(pgCombat, "SILENT AIM ENGINE")
Toggle(secAim, "Enable Pistol Aimbot", CFG.PistolAim, function(v) CFG.PistolAim = v end)
Toggle(secAim, "Silent Aim Mode (Instan Snap)", CFG.PistolSilent, function(v) CFG.PistolSilent = v end)
Toggle(secAim, "Auto Predict Target Movement", CFG.PistolPredict, function(v) CFG.PistolPredict = v end)
Toggle(secAim, "Enable Flashlight Aimbot", CFG.FlashAim, function(v) CFG.FlashAim = v end)
Slider(secAim, "Aimbot FOV Radius", 50, 600, CFG.PistolFOV, "px", function(v) CFG.PistolFOV = v; CFG.FlashFOV = v end)

local pgGen = CreateTab("Survivor", "⚡", 4)
local secGen = Section(pgGen, "AUTO GENERATOR & TP")
Toggle(secGen, "Auto TP ke Generator (Loop)", CFG.AutoTP_Gen, function(v) CFG.AutoTP_Gen = v end)
Toggle(secGen, "Auto TP ke Player (Loop)", CFG.AutoTP_Player, function(v) CFG.AutoTP_Player = v end)
Slider(secGen, "Generator Detection Range", 10, 45, CFG.GenRange, " studs", function(v) CFG.GenRange = v end)

SwitchTab("Hologram")

-- Runtime Aimbot & TP Loops
table.insert(connections, RunService.RenderStepped:Connect(function()
    if CFG.PistolAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetAimTarget(CFG.PistolFOV, CFG.PistolPart, false)
        if target then
            local cam = Camera.CFrame
            if CFG.PistolSilent then Camera.CFrame = CFrame.new(cam.Position, target.Position)
            else Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.PistolSmooth) end
        end
    end
    if CFG.FlashAim then
        local char = LP.Character
        local holdingFlash = char and char:FindFirstChildOfClass("Tool") and string.find(string.lower(char:FindFirstChildOfClass("Tool").Name), "flash")
        if holdingFlash or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetAimTarget(CFG.FlashFOV, CFG.FlashPart, true)
            if target then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), CFG.FlashSmooth) end
        end
    end
end))

task.spawn(function()
    while true do
        task.wait(1.0)
        if not gui or not gui.Parent then break end
        if CFG.AutoTP_Gen then TeleportTo("Generator") end
        if CFG.AutoTP_Player then TeleportTo("Player") end
        if CFG.GenMode ~= "Off" then pcall(DoGenerator) end
    end
end)

print("[QUANTUM HUB] v" .. VERSION .. " compiled by zibey. Systems online.")
