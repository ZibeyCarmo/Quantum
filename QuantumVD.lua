--[[
    VD HUB | Violence District
    Version : 3.3 (Cyber Glow Edition)
    - Modern Resizable GUI (Mouse Kiri di Grip Pojok Kanan Bawah)
    - Loading Card 5 Detik dengan Progress Bar & Tombol Mulai
    - Glow Neon Gradient Animation (Border & Accent)
    - Tab Menu Terorganisir (Visuals, Combat, Movement, Generator, Settings)
    - Modern Toggle Switches, Interactive Sliders & Action Buttons
    - Line ESP (Player / Vault / Pallet / Generator) dengan WorldToViewportPoint Z-Check
    - Auto Generator dengan Proximity Prompt
    - Drag & Resize Smooth Handler
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

local CFG = {
    ESP_Player    = false,
    ESP_Vault     = false,
    ESP_Pallet    = false,
    ESP_Generator = false,
    Aimbot        = false,
    AimKey        = Enum.UserInputType.MouseButton2,
    FOV           = 280,
    Smooth        = 0.12,
    Speed         = false,
    WalkSpeed     = 22,
    GenMode       = "On", -- Off / Instant / Legit / Random
}

local VERSION = "1.0"
local drawings = {}
local connections = {}

local function ClearDraw()
    for i = #drawings, 1, -1 do
        local d = drawings[i]
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

-- Line ESP Drawing
local function AddLine(worldPos, color)
    if typeof(worldPos) ~= "Vector3" then return end

    local ok, screen, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(worldPos)
    end)
    if not ok or not screen then return end

    -- Depth check: jika di belakang kamera, lewati
    if screen.Z <= 0 then return end

    local vp = Camera.ViewportSize
    local sx, sy = screen.X, screen.Y

    -- Batas tepi layar (±50px)
    if sx < -50 or sy < -50 or sx > vp.X + 50 or sy > vp.Y + 50 then
        return
    end

    local from = Vector2.new(vp.X * 0.5, vp.Y - 2) -- Bawah tengah layar
    local to   = Vector2.new(sx, sy)

    local line = Drawing.new("Line")
    line.From = from
    line.To = to
    line.Color = color
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = true
    table.insert(drawings, line)
end

local function GetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.HoldDuration = 0
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(0.03)
            prompt:InputHoldEnd()
        end
    end)
end

local function DoGenerator()
    if CFG.GenMode == "Off" then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local delayTime = 0.02
    if CFG.GenMode == "Legit" then
        delayTime = 0.35 + math.random() * 0.25
    elseif CFG.GenMode == "Random" then
        delayTime = 0.1 + math.random() * 0.4
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent")) then
            local part = GetPart(obj)
            if part and (part.Position - root.Position).Magnitude < 22 then
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        task.wait(delayTime)
                        FirePrompt(d)
                    end
                end
            end
        end
    end
end

-- ===================== GUI CONTAINER =====================
pcall(function()
    local old = CoreGui:FindFirstChild("VD_HUB")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "VD_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetParent = CoreGui
pcall(function()
    local test = Instance.new("Folder", CoreGui)
    test:Destroy()
end)
gui.Parent = targetParent or LP:WaitForChild("PlayerGui")

-- Helper Tween
local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- ===================== 1. LOADING SCREEN (KOTAK KECIL 5 DETIK) =====================
local LoadCard = Instance.new("Frame")
LoadCard.Name = "LoadCard"
LoadCard.Size = UDim2.fromOffset(360, 225)
LoadCard.Position = UDim2.new(0.5, -180, 0.5, -112)
LoadCard.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
LoadCard.BorderSizePixel = 0
LoadCard.Active = true
LoadCard.ClipsDescendants = false
LoadCard.Parent = gui

local LoadCorner = Instance.new("UICorner", LoadCard)
LoadCorner.CornerRadius = UDim.new(0, 14)

-- Glow border untuk Loading Card
local LoadStroke = Instance.new("UIStroke", LoadCard)
LoadStroke.Thickness = 2
LoadStroke.Color = Color3.fromRGB(245, 45, 85)
LoadStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local LoadStrokeGrad = Instance.new("UIGradient", LoadStroke)
LoadStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 45, 85)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 50, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 45, 85))
})

-- Ambient Glow Shadow Frame
local LoadShadow = Instance.new("Frame", LoadCard)
LoadShadow.Size = UDim2.new(1, 16, 1, 16)
LoadShadow.Position = UDim2.new(0, -8, 0, -8)
LoadShadow.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
LoadShadow.BackgroundTransparency = 0.88
LoadShadow.BorderSizePixel = 0
LoadShadow.ZIndex = LoadCard.ZIndex - 1
Instance.new("UICorner", LoadShadow).CornerRadius = UDim.new(0, 18)

-- Header Logo Loading
local LoadIcon = Instance.new("TextLabel")
LoadIcon.Size = UDim2.fromOffset(38, 38)
LoadIcon.Position = UDim2.new(0, 20, 0, 18)
LoadIcon.BackgroundColor3 = Color3.fromRGB(28, 20, 36)
LoadIcon.Text = "VD"
LoadIcon.TextColor3 = Color3.fromRGB(255, 55, 95)
LoadIcon.TextSize = 18
LoadIcon.Font = Enum.Font.GothamBold
LoadIcon.Parent = LoadCard
Instance.new("UICorner", LoadIcon).CornerRadius = UDim.new(0, 10)
local iconStroke = Instance.new("UIStroke", LoadIcon)
iconStroke.Color = Color3.fromRGB(255, 55, 95)
iconStroke.Thickness = 1.2

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, -75, 0, 22)
LoadTitle.Position = UDim2.new(0, 68, 0, 16)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "VD HUB  v" .. VERSION
LoadTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
LoadTitle.TextSize = 17
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadTitle.Parent = LoadCard

local LoadSubtitle = Instance.new("TextLabel")
LoadSubtitle.Size = UDim2.new(1, -75, 0, 16)
LoadSubtitle.Position = UDim2.new(0, 68, 0, 38)
LoadSubtitle.BackgroundTransparency = 1
LoadSubtitle.Text = "Violence District • System Initializer"
LoadSubtitle.TextColor3 = Color3.fromRGB(150, 150, 175)
LoadSubtitle.TextSize = 12
LoadSubtitle.Font = Enum.Font.Gotham
LoadSubtitle.TextXAlignment = Enum.TextXAlignment.Left
LoadSubtitle.Parent = LoadCard

-- Status Text
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -40, 0, 20)
StatusLabel.Position = UDim2.new(0, 20, 0, 85)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Memulai inisialisasi modul..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = LoadCard

-- Percent Label
local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size = UDim2.fromOffset(60, 20)
PercentLabel.Position = UDim2.new(1, -80, 0, 85)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text = "0%"
PercentLabel.TextColor3 = Color3.fromRGB(255, 75, 110)
PercentLabel.TextSize = 13
PercentLabel.Font = Enum.Font.GothamBold
PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
PercentLabel.Parent = LoadCard

-- Progress Bar Track
local BarTrack = Instance.new("Frame")
BarTrack.Size = UDim2.new(1, -40, 0, 8)
BarTrack.Position = UDim2.new(0, 20, 0, 115)
BarTrack.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
BarTrack.BorderSizePixel = 0
BarTrack.Parent = LoadCard
Instance.new("UICorner", BarTrack).CornerRadius = UDim.new(1, 0)

-- Progress Bar Fill dengan Gradient Glow
local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarTrack
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

local BarGrad = Instance.new("UIGradient", BarFill)
BarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 100)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 50, 255))
})

-- Tombol Mulai (Muncul setelah 5 Detik Loading)
local StartBtn = Instance.new("TextButton")
StartBtn.Name = "StartBtn"
StartBtn.Size = UDim2.new(1, -40, 0, 42)
StartBtn.Position = UDim2.new(0, 20, 0, 150)
StartBtn.BackgroundColor3 = Color3.fromRGB(235, 40, 80)
StartBtn.Text = "🚀  MULAI / BUKA MENU"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 14
StartBtn.Font = Enum.Font.GothamBold
StartBtn.AutoButtonColor = false
StartBtn.Visible = false
StartBtn.Parent = LoadCard
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 10)

local StartGrad = Instance.new("UIGradient", StartBtn)
StartGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 45, 85)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 40, 230))
})

local StartStroke = Instance.new("UIStroke", StartBtn)
StartStroke.Thickness = 1.5
StartStroke.Color = Color3.fromRGB(255, 120, 160)

StartBtn.MouseEnter:Connect(function()
    Tween(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 65, 110)})
end)
StartBtn.MouseLeave:Connect(function()
    Tween(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(235, 40, 80)})
end)

-- Hint awal
local HintLoad = Instance.new("TextLabel")
HintLoad.Size = UDim2.new(1, -40, 0, 18)
HintLoad.Position = UDim2.new(0, 20, 0, 165)
HintLoad.BackgroundTransparency = 1
HintLoad.Text = "Mohon tunggu 5 detik inisialisasi modul..."
HintLoad.TextColor3 = Color3.fromRGB(120, 120, 140)
HintLoad.TextSize = 11
HintLoad.Font = Enum.Font.Gotham
HintLoad.Parent = LoadCard

-- ===================== 2. MAIN GUI (RESIZABLE & CATEGORIZED) =====================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(580, 390)
Main.Position = UDim2.new(0.5, -290, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = false
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Glowing Animated Stroke untuk Main Frame
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(245, 45, 85)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local MainStrokeGrad = Instance.new("UIGradient", MainStroke)
MainStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 45, 85)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(150, 50, 255)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(45, 200, 255)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 45, 85))
})

-- Ambient Glow Shadow Frame Main
local MainShadow = Instance.new("Frame", Main)
MainShadow.Size = UDim2.new(1, 20, 1, 20)
MainShadow.Position = UDim2.new(0, -10, 0, -10)
MainShadow.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
MainShadow.BackgroundTransparency = 0.90
MainShadow.BorderSizePixel = 0
MainShadow.ZIndex = Main.ZIndex - 1
Instance.new("UICorner", MainShadow).CornerRadius = UDim.new(0, 16)

-- Animasi Rotasi Glow Gradient Border
local glowRot = 0
local rotConn = RunService.RenderStepped:Connect(function(dt)
    glowRot = (glowRot + dt * 50) % 360
    if LoadStrokeGrad and LoadStrokeGrad.Parent then
        LoadStrokeGrad.Rotation = glowRot
    end
    if MainStrokeGrad and MainStrokeGrad.Parent then
        MainStrokeGrad.Rotation = glowRot
    end
end)
table.insert(connections, rotConn)

-- ===================== TOPBAR (DRAGGABLE) =====================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

-- Patch sudut bawah TopBar agar rapi
local TopBarPatch = Instance.new("Frame")
TopBarPatch.Size = UDim2.new(1, 0, 0, 10)
TopBarPatch.Position = UDim2.new(0, 0, 1, -10)
TopBarPatch.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
TopBarPatch.BorderSizePixel = 0
TopBarPatch.Parent = TopBar

-- Border pemisah bawah TopBar
local TopDivider = Instance.new("Frame")
TopDivider.Size = UDim2.new(1, 0, 0, 1)
TopDivider.Position = UDim2.new(0, 0, 1, -1)
TopDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
TopDivider.BorderSizePixel = 0
TopDivider.Parent = TopBar

-- Judul & Logo Header
local LogoBadge = Instance.new("TextLabel")
LogoBadge.Size = UDim2.fromOffset(26, 26)
LogoBadge.Position = UDim2.new(0, 12, 0.5, -13)
LogoBadge.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
LogoBadge.Text = "VD"
LogoBadge.TextColor3 = Color3.new(1, 1, 1)
LogoBadge.TextSize = 13
LogoBadge.Font = Enum.Font.GothamBold
LogoBadge.Parent = TopBar
Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 7)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 180, 1, 0)
TitleText.Position = UDim2.new(0, 46, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "VD HUB <font color='#ff2d55'>v" .. VERSION .. "</font>"
TitleText.TextColor3 = Color3.fromRGB(240, 240, 250)
TitleText.TextSize = 15
TitleText.RichText = true
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TopBar

local TagBadge = Instance.new("TextLabel")
TagBadge.Size = UDim2.fromOffset(120, 20)
TagBadge.Position = UDim2.new(0, 175, 0.5, -10)
TagBadge.BackgroundColor3 = Color3.fromRGB(30, 24, 38)
TagBadge.Text = "VIOLENCE DISTRICT"
TagBadge.TextColor3 = Color3.fromRGB(255, 75, 120)
TagBadge.TextSize = 10
TagBadge.Font = Enum.Font.GothamBold
TagBadge.Parent = TopBar
Instance.new("UICorner", TagBadge).CornerRadius = UDim.new(0, 6)
local tagStroke = Instance.new("UIStroke", TagBadge)
tagStroke.Color = Color3.fromRGB(65, 35, 60)
tagStroke.Thickness = 1

-- Tombol Close & Minimize
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 95)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 45, 65), TextColor3 = Color3.new(1, 1, 1)})
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 25, 30), TextColor3 = Color3.fromRGB(255, 75, 95)})
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(26, 26)
MinBtn.Position = UDim2.new(1, -66, 0.5, -13)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(180, 180, 205)
MinBtn.TextSize = 13
MinBtn.Font = Enum.Font.GothamBold
MinBtn.AutoButtonColor = false
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

MinBtn.MouseEnter:Connect(function()
    Tween(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 65), TextColor3 = Color3.new(1, 1, 1)})
end)
MinBtn.MouseLeave:Connect(function()
    Tween(MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 38), TextColor3 = Color3.fromRGB(180, 180, 205)})
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    print("[VD HUB] GUI di-minimize. Tekan tombol RightControl pada keyboard untuk membuka kembali.")
end)

CloseBtn.MouseButton1Click:Connect(function()
    ClearDraw()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    gui:Destroy()
end)

-- Drag Window dengan Mouse Kiri pada TopBar
local isDragging = false
local dragStartMouse = Vector2.zero
local dragStartPos = UDim2.new()

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartMouse = UIS:GetMouseLocation()
        dragStartPos = Main.Position
    end
end)

-- ===================== RESIZE DENGAN MOUSE KIRI (BOTTOM-RIGHT HANDLE) =====================
-- Handle grip yang jelas dan menarik di pojok kanan bawah
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.fromOffset(20, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(30, 22, 38)
ResizeHandle.Text = ""
ResizeHandle.AutoButtonColor = false
ResizeHandle.Parent = Main
Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 6)

local handleStroke = Instance.new("UIStroke", ResizeHandle)
handleStroke.Color = Color3.fromRGB(255, 45, 85)
handleStroke.Thickness = 1.2

-- Visual Garis Grip Diagonal
local GripIcon = Instance.new("TextLabel")
GripIcon.Size = UDim2.new(1, 0, 1, 0)
GripIcon.BackgroundTransparency = 1
GripIcon.Text = "⇲"
GripIcon.TextColor3 = Color3.fromRGB(255, 65, 110)
GripIcon.TextSize = 14
GripIcon.Font = Enum.Font.GothamBold
GripIcon.Parent = ResizeHandle

ResizeHandle.MouseEnter:Connect(function()
    Tween(ResizeHandle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 45, 85)})
    Tween(GripIcon, TweenInfo.new(0.2), {TextColor3 = Color3.new(1, 1, 1)})
end)
ResizeHandle.MouseLeave:Connect(function()
    Tween(ResizeHandle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 22, 38)})
    Tween(GripIcon, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 65, 110)})
end)

local isResizing = false
local resizeStartMouse = Vector2.zero
local resizeStartSize  = Vector2.zero

ResizeHandle.MouseButton1Down:Connect(function()
    isResizing = true
    resizeStartMouse = UIS:GetMouseLocation()
    resizeStartSize  = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
end)

-- Global Input Handler untuk Drag & Resize dengan Mouse Kiri
local dragResizeConn = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        isResizing = false
    end
end)
table.insert(connections, dragResizeConn)

local moveConn = UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local m = UIS:GetMouseLocation()
        if isDragging then
            local delta = m - dragStartMouse
            Main.Position = UDim2.new(
                dragStartPos.X.Scale,
                dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale,
                dragStartPos.Y.Offset + delta.Y
            )
        end
        if isResizing then
            local delta = m - resizeStartMouse
            local nx = math.clamp(resizeStartSize.X + delta.X, 480, 850)
            local ny = math.clamp(resizeStartSize.Y + delta.Y, 320, 620)
            Main.Size = UDim2.fromOffset(nx, ny)
        end
    end
end)
table.insert(connections, moveConn)

-- ===================== SIDEBAR TABS (KATEGORI FITUR) =====================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 145, 1, -42)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideDivider = Instance.new("Frame")
SideDivider.Size = UDim2.new(0, 1, 1, 0)
SideDivider.Position = UDim2.new(1, -1, 0, 0)
SideDivider.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
SideDivider.BorderSizePixel = 0
SideDivider.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.FillDirection = Enum.FillDirection.Vertical
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 12)
SidePad.PaddingLeft = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent = Sidebar

-- Area Konten Halaman (Responsive menyesuaikan ukuran window saat diperbesar/diperkecil)
local ContentHolder = Instance.new("Frame")
ContentHolder.Name = "ContentHolder"
ContentHolder.Size = UDim2.new(1, -155, 1, -52)
ContentHolder.Position = UDim2.new(0, 150, 0, 47)
ContentHolder.BackgroundTransparency = 1
ContentHolder.Parent = Main

-- Koleksi Halaman & Tombol Tab
local pages = {}
local tabButtons = {}
local currentTab = "Visuals"

local function SwitchTab(name)
    currentTab = name
    for tabName, btn in pairs(tabButtons) do
        local isActive = (tabName == name)
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        local glowPill = btn:FindFirstChild("GlowPill")

        if isActive then
            Tween(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(32, 22, 40),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            if stroke then stroke.Color = Color3.fromRGB(255, 45, 85) end
            if glowPill then glowPill.Visible = true end
        else
            Tween(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(20, 20, 28),
                TextColor3 = Color3.fromRGB(160, 160, 185)
            })
            if stroke then stroke.Color = Color3.fromRGB(35, 35, 48) end
            if glowPill then glowPill.Visible = false end
        end
    end

    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end
end

local function CreateTabButton(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    btn.Text = "   " .. icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(160, 160, 185)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(35, 35, 48)
    stroke.Thickness = 1

    -- Pill glow indikator aktif
    local glowPill = Instance.new("Frame", btn)
    glowPill.Name = "GlowPill"
    glowPill.Size = UDim2.new(0, 3, 0.6, 0)
    glowPill.Position = UDim2.new(0, 3, 0.2, 0)
    glowPill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    glowPill.BorderSizePixel = 0
    glowPill.Visible = false
    Instance.new("UICorner", glowPill).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)

    tabButtons[name] = btn

    -- Buat ScrollingFrame container untuk halaman tab ini
    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(255, 55, 95)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = ContentHolder

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 4)
    pagePad.PaddingBottom = UDim.new(0, 20)
    pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.Parent = page

    pages[name] = page
    return page
end

-- ===================== UI BUILDER COMPONENTS (BUTTON, TOGGLE, SLIDER) =====================
local function CreateSectionHeader(parent, title, desc, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(38, 38, 52)
    stroke.Thickness = 1

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 20)
    t.Position = UDim2.new(0, 12, 0, 4)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.TextSize = 13
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = card

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -20, 0, 14)
    d.Position = UDim2.new(0, 12, 0, 22)
    d.BackgroundTransparency = 1
    d.Text = desc
    d.TextColor3 = Color3.fromRGB(140, 140, 165)
    d.TextSize = 11
    d.Font = Enum.Font.Gotham
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.Parent = card
end

local function CreateToggle(parent, title, subtext, flagKey, order)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(19, 19, 27)
    card.Text = ""
    card.AutoButtonColor = false
    card.LayoutOrder = order or 2
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(36, 36, 50)
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(240, 240, 250)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -70, 0, 14)
    sub.Position = UDim2.new(0, 14, 0, 23)
    sub.BackgroundTransparency = 1
    sub.Text = subtext or (CFG[flagKey] and "Status: Aktif" or "Status: Nonaktif")
    sub.TextColor3 = CFG[flagKey] and Color3.fromRGB(75, 220, 130) or Color3.fromRGB(130, 130, 150)
    sub.TextSize = 11
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = card

    -- Switch Pill Container
    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(40, 22)
    pill.Position = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = CFG[flagKey] and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(35, 35, 46)
    pill.BorderSizePixel = 0
    pill.Parent = card
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local pillStroke = Instance.new("UIStroke", pill)
    pillStroke.Color = CFG[flagKey] and Color3.fromRGB(255, 110, 145) or Color3.fromRGB(55, 55, 70)
    pillStroke.Thickness = 1

    -- Switch Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = CFG[flagKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    card.MouseButton1Click:Connect(function()
        CFG[flagKey] = not CFG[flagKey]
        local active = CFG[flagKey]

        sub.Text = subtext or (active and "Status: Aktif" or "Status: Nonaktif")
        Tween(sub, TweenInfo.new(0.2), {
            TextColor3 = active and Color3.fromRGB(75, 220, 130) or Color3.fromRGB(130, 130, 150)
        })

        Tween(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = active and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(35, 35, 46)
        })
        pillStroke.Color = active and Color3.fromRGB(255, 110, 145) or Color3.fromRGB(55, 55, 70)

        Tween(knob, TweenInfo.new(0.2), {
            Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        })
    end)

    card.MouseEnter:Connect(function()
        Tween(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 34)})
    end)
    card.MouseLeave:Connect(function()
        Tween(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(19, 19, 27)})
    end)

    return card
end

local function CreateButton(parent, text, subtext, icon, callback, accentColor, order)
    local col = accentColor or Color3.fromRGB(255, 45, 85)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(40, 40, 54)
    stroke.Thickness = 1

    local icn = Instance.new("TextLabel")
    icn.Size = UDim2.fromOffset(28, 28)
    icn.Position = UDim2.new(0, 8, 0.5, -14)
    icn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    icn.Text = icon or "⚡"
    icn.TextColor3 = col
    icn.TextSize = 14
    icn.Font = Enum.Font.GothamBold
    icn.Parent = btn
    Instance.new("UICorner", icn).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -95, 0, 18)
    lbl.Position = UDim2.new(0, 44, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(240, 240, 250)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -95, 0, 14)
    sub.Position = UDim2.new(0, 44, 0, 22)
    sub.BackgroundTransparency = 1
    sub.Text = subtext or "Klik untuk mengeksekusi"
    sub.TextColor3 = Color3.fromRGB(140, 140, 160)
    sub.TextSize = 11
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(24, 24)
    arrow.Position = UDim2.new(1, -34, 0.5, -12)
    arrow.BackgroundTransparency = 1
    arrow.Text = "➔"
    arrow.TextColor3 = col
    arrow.TextSize = 13
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseEnter:Connect(function()
        Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 24, 38)})
        stroke.Color = col
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 28)})
        stroke.Color = Color3.fromRGB(40, 40, 54)
    end)

    btn.MouseButton1Click:Connect(function()
        Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = col})
        task.wait(0.1)
        Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 24, 38)})
        if callback then callback() end
    end)

    return btn
end

local function CreateSlider(parent, title, minVal, maxVal, currentVal, suffix, callback, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 54)
    card.BackgroundColor3 = Color3.fromRGB(19, 19, 27)
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 4
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(36, 36, 50)
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -90, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(240, 240, 250)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(70, 20)
    valLbl.Position = UDim2.new(1, -84, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(currentVal) .. (suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(255, 75, 110)
    valLbl.TextSize = 13
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = card

    -- Slider Track Bar
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    track.BorderSizePixel = 0
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local initialPercent = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 100)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 50, 255))
    })

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.new(initialPercent, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = Color3.fromRGB(255, 45, 85)
    knobStroke.Thickness = 1.5

    local isSliding = false
    local function UpdateFromMouse()
        local mousePos = UIS:GetMouseLocation()
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        local rel = math.clamp((mousePos.X - trackAbsPos) / trackAbsSize, 0, 1)

        local calculatedVal = minVal + rel * (maxVal - minVal)
        if (maxVal - minVal) > 10 then
            calculatedVal = math.floor(calculatedVal + 0.5)
        else
            calculatedVal = math.floor(calculatedVal * 100 + 0.5) / 100
        end

        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        valLbl.Text = tostring(calculatedVal) .. (suffix or "")

        if callback then callback(calculatedVal) end
    end

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isSliding = true
            UpdateFromMouse()
        end
    end)

    local slideConn = UIS.InputChanged:Connect(function(input)
        if isSliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateFromMouse()
        end
    end)
    table.insert(connections, slideConn)

    local stopConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isSliding = false
        end
    end)
    table.insert(connections, stopConn)

    return card
end

-- ===================== 3. POPULASI HALAMAN TABS =====================

-- [TAB 1: VISUALS]
local pVisuals = CreateTabButton("Visuals", "👁️", 1)
CreateSectionHeader(pVisuals, "ESP & Tracer Lines", "Garis ESP akurat dengan filter Z-Depth kamera", 1)
CreateToggle(pVisuals, "Player Line ESP", "Tracer hijau/merah ke pemain lain", "ESP_Player", 2)
CreateToggle(pVisuals, "Vault & Window ESP", "Tracer kuning ke jendela / vault parkour", "ESP_Vault", 3)
CreateToggle(pVisuals, "Pallet Line ESP", "Tracer oranye ke pallet rintangan", "ESP_Pallet", 4)
CreateToggle(pVisuals, "Generator Line ESP", "Tracer biru cyan ke generator target", "ESP_Generator", 5)

CreateButton(pVisuals, "Bersihkan Garis Layar", "Hapus drawing aktif dan refresh tracer", "🧹", function()
    ClearDraw()
    print("[VD HUB] Drawing cleared & refreshed.")
end, Color3.fromRGB(60, 180, 255), 6)

-- [TAB 2: COMBAT]
local pCombat = CreateTabButton("Combat", "🎯", 2)
CreateSectionHeader(pCombat, "Aimbot Assist", "Auto lock ke kepala lawan saat klik kanan", 1)
CreateToggle(pCombat, "Aimbot Aktif", "Tahan Klik Kanan (Mouse 2) untuk mengunci", "Aimbot", 2)

CreateSlider(pCombat, "Aimbot FOV Radius", 60, 600, CFG.FOV, " px", function(val)
    CFG.FOV = val
end, 3)

CreateSlider(pCombat, "Smoothness Camera", 0.02, 0.40, CFG.Smooth, " s", function(val)
    CFG.Smooth = val
end, 4)

-- [TAB 3: MOVEMENT]
local pMovement = CreateTabButton("Movement", "⚡", 3)
CreateSectionHeader(pMovement, "Speed Modifier", "Ubah kecepatan lari karakter lokal", 1)
CreateToggle(pMovement, "Aktifkan Speed Hack", "Menerapkan WalkSpeed konstan", "Speed", 2)

CreateSlider(pMovement, "WalkSpeed Karakter", 16, 100, CFG.WalkSpeed, " spd", function(val)
    CFG.WalkSpeed = val
    if CFG.Speed and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end, 3)

-- Grid Tombol Preset WalkSpeed
local presetFrame = Instance.new("Frame")
presetFrame.Size = UDim2.new(1, 0, 0, 36)
presetFrame.BackgroundTransparency = 1
presetFrame.LayoutOrder = 4
presetFrame.Parent = pMovement

local presetLayout = Instance.new("UIListLayout")
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.Padding = UDim.new(0, 6)
presetLayout.Parent = presetFrame

local presets = {
    {name = "Normal (16)", spd = 16},
    {name = "Legit (24)",  spd = 24},
    {name = "Fast (38)",   spd = 38},
    {name = "Max (75)",    spd = 75}
}

for _, p in ipairs(presets) do
    local pb = Instance.new("TextButton")
    pb.Size = UDim2.new(0.25, -5, 1, 0)
    pb.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    pb.Text = p.name
    pb.TextColor3 = Color3.fromRGB(220, 220, 235)
    pb.TextSize = 11
    pb.Font = Enum.Font.GothamMedium
    pb.AutoButtonColor = false
    pb.Parent = presetFrame
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 6)
    local pStroke = Instance.new("UIStroke", pb)
    pStroke.Color = Color3.fromRGB(40, 40, 56)

    pb.MouseButton1Click:Connect(function()
        CFG.WalkSpeed = p.spd
        CFG.Speed = true
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = p.spd end
        end
        Tween(pb, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 45, 85)})
        task.wait(0.12)
        Tween(pb, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 34)})
    end)
end

-- [TAB 4: GENERATOR]
local pGen = CreateTabButton("Generator", "⚙️", 4)
CreateSectionHeader(pGen, "Auto Fix Generator", "Otomatis menyelesaikan ProximityPrompt generator dekat", 1)

-- Selector Mode Generator (Off, Legit, Instant, Random)
local genCard = Instance.new("Frame")
genCard.Size = UDim2.new(1, 0, 0, 78)
genCard.BackgroundColor3 = Color3.fromRGB(19, 19, 27)
genCard.BorderSizePixel = 0
genCard.LayoutOrder = 2
genCard.Parent = pGen
Instance.new("UICorner", genCard).CornerRadius = UDim.new(0, 8)
local genStroke = Instance.new("UIStroke", genCard)
genStroke.Color = Color3.fromRGB(36, 36, 50)

local genTitle = Instance.new("TextLabel")
genTitle.Size = UDim2.new(1, -20, 0, 20)
genTitle.Position = UDim2.new(0, 12, 0, 6)
genTitle.BackgroundTransparency = 1
genTitle.Text = "Mode Auto Generator"
genTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
genTitle.TextSize = 13
genTitle.Font = Enum.Font.GothamBold
genTitle.TextXAlignment = Enum.TextXAlignment.Left
genTitle.Parent = genCard

local modeContainer = Instance.new("Frame")
modeContainer.Size = UDim2.new(1, -24, 0, 36)
modeContainer.Position = UDim2.new(0, 12, 0, 32)
modeContainer.BackgroundTransparency = 1
modeContainer.Parent = genCard

local modeList = Instance.new("UIListLayout")
modeList.FillDirection = Enum.FillDirection.Horizontal
modeList.Padding = UDim.new(0, 6)
modeList.Parent = modeContainer

local modeBtns = {}
local modes = {"Off", "Legit", "Instant", "Random"}

local function UpdateGenModeButtons()
    for _, item in ipairs(modeBtns) do
        local isSel = (CFG.GenMode == item.mode)
        Tween(item.btn, TweenInfo.new(0.2), {
            BackgroundColor3 = isSel and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(28, 28, 38),
            TextColor3 = isSel and Color3.new(1, 1, 1) or Color3.fromRGB(170, 170, 190)
        })
        if item.stroke then
            item.stroke.Color = isSel and Color3.fromRGB(255, 110, 145) or Color3.fromRGB(45, 45, 60)
        end
    end
end

for _, m in ipairs(modes) do
    local mb = Instance.new("TextButton")
    mb.Size = UDim2.new(0.25, -5, 1, 0)
    mb.BackgroundColor3 = (CFG.GenMode == m) and Color3.fromRGB(255, 45, 85) or Color3.fromRGB(28, 28, 38)
    mb.Text = m
    mb.TextColor3 = Color3.new(1, 1, 1)
    mb.TextSize = 12
    mb.Font = Enum.Font.GothamMedium
    mb.AutoButtonColor = false
    mb.Parent = modeContainer
    Instance.new("UICorner", mb).CornerRadius = UDim.new(0, 6)

    local mStrk = Instance.new("UIStroke", mb)
    mStrk.Color = (CFG.GenMode == m) and Color3.fromRGB(255, 110, 145) or Color3.fromRGB(45, 45, 60)

    mb.MouseButton1Click:Connect(function()
        CFG.GenMode = m
        UpdateGenModeButtons()
    end)

    table.insert(modeBtns, {btn = mb, stroke = mStrk, mode = m})
end

CreateButton(pGen, "Paksa Interaksi Prompt Terdekat", "Trigger langsung semua prompt dalam radius 22 stud", "⚡", function()
    pcall(DoGenerator)
end, Color3.fromRGB(255, 175, 45), 3)

-- [TAB 5: SETTINGS]
local pSettings = CreateTabButton("Settings", "🛠️", 5)
CreateSectionHeader(pSettings, "Hub Configuration & Info", "Status game dan kontrol tampilan menu", 1)

CreateButton(pSettings, "Reset Posisi Menu ke Tengah", "Pindahkan jendela kembali ke tengah layar", "🎯", function()
    Main.Position = UDim2.new(0.5, -Main.AbsoluteSize.X / 2, 0.5, -Main.AbsoluteSize.Y / 2)
end, Color3.fromRGB(130, 80, 255), 2)

CreateButton(pSettings, "Reset Ukuran Default (580x390)", "Kembalikan ukuran window ke ukuran standar", "📐", function()
    Main.Size = UDim2.fromOffset(580, 390)
end, Color3.fromRGB(60, 200, 255), 3)

CreateButton(pSettings, "Unload & Tutup Script", "Hapus semua drawing, disconnect loops & destroy GUI", "❌", function()
    ClearDraw()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    gui:Destroy()
end, Color3.fromRGB(255, 45, 85), 4)

-- Buka tab pertama
SwitchTab("Visuals")

-- ===================== 4. LOGIKA ANIMASI LOADING 5 DETIK =====================
task.spawn(function()
    local startTime = tick()
    local totalDuration = 5.0 -- 5 Detik loading

    while true do
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / totalDuration, 0, 1)

        BarFill.Size = UDim2.new(progress, 0, 1, 0)
        PercentLabel.Text = math.floor(progress * 100) .. "%"

        if progress < 0.22 then
            StatusLabel.Text = "Memuat modul VD HUB..."
        elseif progress < 0.45 then
            StatusLabel.Text = "Memeriksa Violence District environment..."
        elseif progress < 0.70 then
            StatusLabel.Text = "Inisialisasi Line ESP & Proximity Prompt..."
        elseif progress < 0.95 then
            StatusLabel.Text = "Menyiapkan Glow Cyber Interface..."
        else
            StatusLabel.Text = "✓ Siap! Tekan tombol di bawah untuk mulai."
            break
        end

        task.wait(0.03)
    end

    -- Selesai 5 Detik: Tampilkan Tombol Mulai dengan animasi bounce
    HintLoad.Visible = false
    StartBtn.Visible = true
    StartBtn.Size = UDim2.new(1, -40, 0, 0)
    Tween(StartBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -40, 0, 42)
    })
end)

-- Klik Tombol MULAI: Tutup Loading Box, Buka Main GUI
StartBtn.MouseButton1Click:Connect(function()
    Tween(LoadCard, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(260, 160),
        Position = UDim2.new(0.5, -130, 0.5, -80),
        BackgroundTransparency = 1
    })

    task.wait(0.28)
    LoadCard:Destroy()

    Main.Visible = true
    Main.Size = UDim2.fromOffset(480, 320)
    Main.Position = UDim2.new(0.5, -240, 0.5, -160)

    Tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(580, 390),
        Position = UDim2.new(0.5, -290, 0.5, -195)
    })
end)

-- Keyboard Shortcut: RightControl untuk Toggle Menu
local toggleConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
    end
end)
table.insert(connections, toggleConn)

-- ===================== 5. BACKGROUND LOOPS (ESP, AIMBOT, SPEED, GEN) =====================

-- RenderStepped: Line ESP & WalkSpeed
local espConn = RunService.RenderStepped:Connect(function()
    ClearDraw()

    -- Speed Modifier
    local char = LP.Character
    if char and CFG.Speed then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = CFG.WalkSpeed end
    end

    -- Player Line ESP
    if CFG.ESP_Player then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            local c = plr.Character
            if not c then continue end
            local hum = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local col = hum.Health < 30 and Color3.fromRGB(255, 55, 55) or Color3.fromRGB(0, 255, 120)
                AddLine(root.Position, col)
            end
        end
    end

    -- World Objects ESP (Vault, Pallet, Generator)
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        local part = GetPart(obj)
        if not part then continue end

        if CFG.ESP_Vault and (string.find(n, "vault") or string.find(n, "window")) then
            AddLine(part.Position, Color3.fromRGB(255, 210, 60))
        end
        if CFG.ESP_Pallet and string.find(n, "pallet") then
            AddLine(part.Position, Color3.fromRGB(255, 150, 40))
        end
        if CFG.ESP_Generator and (string.find(n, "generator") or (string.find(n, "gen") and not string.find(n, "agent"))) then
            AddLine(part.Position, Color3.fromRGB(80, 180, 255))
        end
    end
end)
table.insert(connections, espConn)

-- RenderStepped: Aimbot (Mouse Button 2 Lock)
local aimConn = RunService.RenderStepped:Connect(function()
    if not CFG.Aimbot then return end
    if not UIS:IsMouseButtonPressed(CFG.AimKey) then return end

    local best, dist = nil, CFG.FOV
    local mouse = UIS:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local c = plr.Character
        if not c then continue end
        local hum = c:FindFirstChildOfClass("Humanoid")
        local head = c:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not head then continue end

        local p, on = Camera:WorldToViewportPoint(head.Position)
        if on and p.Z > 0 then
            local d = (Vector2.new(p.X, p.Y) - mouse).Magnitude
            if d < dist then
                dist = d
                best = head
            end
        end
    end

    if best then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, best.Position), CFG.Smooth)
    end
end)
table.insert(connections, aimConn)

-- Thread: Auto Generator
task.spawn(function()
    while true do
        local w = 0.35
        if CFG.GenMode == "Instant" then w = 0.12 end
        if CFG.GenMode == "Legit" then w = 0.5 end
        if CFG.GenMode == "Random" then w = 0.2 + math.random() * 0.45 end
        task.wait(w)

        if CFG.GenMode ~= "Off" then
            pcall(DoGenerator)
        end
    end
end)

print("[VD HUB] v" .. VERSION .. " Cyber Glow Edition loaded successfully!")
