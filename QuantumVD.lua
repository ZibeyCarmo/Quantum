--[[
    VD HUB | Violence District
    By Zibey Carmo
    Fitur : Line ESP, Aimbot, Speed, NoClip, Theme, Discord
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================== CONFIG =====================
local CFG = {
    ESP        = false,
    LineESP    = true,
    Name       = true,
    Distance   = true,
    Health     = true,

    Aimbot     = false,
    AimKey     = Enum.UserInputType.MouseButton2,
    FOV        = 280,
    Smooth     = 0.12,
    AimPart    = "Head",

    Speed      = false,
    WalkSpeed  = 56,
    JumpPower  = 65,

    NoClip     = false,
}

local VERSION = "2.1"
local DISCORD = "https://discord.gg/ojailbreaks"

-- ===================== THEME =====================
local Theme = {
    Bg       = Color3.fromRGB(12, 12, 16),
    Panel    = Color3.fromRGB(18, 18, 24),
    Tab      = Color3.fromRGB(22, 22, 30),
    Accent   = Color3.fromRGB(220, 40, 40),
    Accent2  = Color3.fromRGB(180, 30, 30),
    Text     = Color3.fromRGB(240, 240, 245),
    TextDim  = Color3.fromRGB(140, 140, 155),
    Success  = Color3.fromRGB(40, 180, 100),
    Stroke   = Color3.fromRGB(40, 40, 50),
}

-- ===================== DRAWING =====================
local drawings = {}

local function Draw(class, props)
    local o = Drawing.new(class)
    for k, v in pairs(props) do o[k] = v end
    return o
end

local function Clear()
    for i, d in pairs(drawings) do
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

-- ===================== AIMBOT =====================
local function GetClosest()
    local best, dist = nil, CFG.FOV
    local mouse = UIS:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local part = char:FindFirstChild(CFG.AimPart) or char:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not part then continue end
        local pos, on = Camera:WorldToViewportPoint(part.Position)
        if on then
            local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
            if d < dist then
                dist = d
                best = part
            end
        end
    end
    return best
end

-- ===================== LINE ESP =====================
local function LineESP(char, col)
    local function scr(p)
        if not p then return nil end
        local pos, on = Camera:WorldToViewportPoint(p.Position)
        return on and Vector2.new(pos.X, pos.Y) or nil
    end

    local head = scr(char:FindFirstChild("Head"))
    local root = scr(char:FindFirstChild("HumanoidRootPart"))
    local torso = scr(char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
    local la = scr(char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"))
    local ra = scr(char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"))
    local ll = scr(char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"))
    local rl = scr(char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"))

    local function L(a, b)
        if a and b then
            local line = Draw("Line", {From = a, To = b, Color = col, Thickness = 1.5, Visible = true})
            table.insert(drawings, line)
        end
    end

    if head and torso then L(head, torso) end
    if torso and root then L(torso, root) end
    if torso and la then L(torso, la) end
    if torso and ra then L(torso, ra) end
    if root and ll then L(root, ll) end
    if root and rl then L(root, rl) end
end

-- ===================== GUI =====================
pcall(function()
    if CoreGui:FindFirstChild("VD_HUB") then CoreGui.VD_HUB:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "VD_HUB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- Main window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 480, 0, 340)
Main.Position = UDim2.new(0.5, -240, 0.5, -170)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Theme.Stroke
stroke.Thickness = 1.5

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Theme.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VD HUB  •  Violence District  v" .. VERSION
Title.TextColor3 = Theme.Text
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -32, 0, 4)
Close.BackgroundColor3 = Theme.Accent
Close.Text = "✕"
Close.TextColor3 = Color3.new(1,1,1)
Close.TextSize = 14
Close.Font = Enum.Font.GothamBold
Close.Parent = TitleBar
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
Close.MouseButton1Click:Connect(function()
    gui:Destroy()
    Clear()
end)

-- Left tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 120, 1, -36)
TabBar.Position = UDim2.new(0, 0, 0, 36)
TabBar.BackgroundColor3 = Theme.Tab
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

-- Content area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -120, 1, -36)
Content.Position = UDim2.new(0, 120, 0, 36)
Content.BackgroundColor3 = Theme.Panel
Content.BorderSizePixel = 0
Content.Parent = Main

local pages = {}

local function MakePage(name)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = Content
    pages[name] = p
    return p
end

local function ShowPage(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
end

-- Tab buttons
local function MakeTab(text, y, pageName)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 34)
    b.Position = UDim2.new(0, 6, 0, y)
    b.BackgroundColor3 = Theme.Tab
    b.Text = "  " .. text
    b.TextColor3 = Theme.TextDim
    b.TextSize = 14
    b.Font = Enum.Font.GothamMedium
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = TabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    b.MouseButton1Click:Connect(function()
        for _, child in ipairs(TabBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Theme.Tab
                child.TextColor3 = Theme.TextDim
            end
        end
        b.BackgroundColor3 = Theme.Accent
        b.TextColor3 = Theme.Text
        ShowPage(pageName)
    end)
    return b
end

MakeTab("Combat", 12, "Combat")
MakeTab("Visuals", 52, "Visuals")
MakeTab("Player", 92, "Player")
MakeTab("Misc", 132, "Misc")

-- Pages
local CombatPage  = MakePage("Combat")
local VisualsPage = MakePage("Visuals")
local PlayerPage  = MakePage("Player")
local MiscPage    = MakePage("Misc")
ShowPage("Combat")

-- Toggle helper
local function AddToggle(parent, text, y, default, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 36)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = default and Theme.Success or Color3.fromRGB(35, 35, 45)
    btn.Text = "  " .. text .. "   [" .. (default and "ON" or "OFF") .. "]"
    btn.TextColor3 = Theme.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Theme.Success or Color3.fromRGB(35, 35, 45)
        btn.Text = "  " .. text .. "   [" .. (state and "ON" or "OFF") .. "]"
        cb(state)
    end)
end

-- Combat page
AddToggle(CombatPage, "Aimbot", 16, CFG.Aimbot, function(v) CFG.Aimbot = v end)

-- Visuals page
AddToggle(VisualsPage, "Line ESP", 16, CFG.ESP, function(v) CFG.ESP = v end)
AddToggle(VisualsPage, "Show Name / Distance", 60, CFG.Name, function(v) CFG.Name = v end)

-- Player page
AddToggle(PlayerPage, "Speed Boost", 16, CFG.Speed, function(v) CFG.Speed = v end)
AddToggle(PlayerPage, "NoClip", 60, CFG.NoClip, function(v) CFG.NoClip = v end)

-- Misc page
local disc = Instance.new("TextButton")
disc.Size = UDim2.new(1, -24, 0, 40)
disc.Position = UDim2.new(0, 12, 0, 16)
disc.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
disc.Text = "  💬  Join Discord"
disc.TextColor3 = Color3.new(1,1,1)
disc.TextSize = 15
disc.Font = Enum.Font.GothamBold
disc.Parent = MiscPage
Instance.new("UICorner", disc).CornerRadius = UDim.new(0, 8)

disc.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DISCORD) end)
    disc.Text = "  ✓  Link Copied!"
    task.wait(1.4)
    disc.Text = "  💬  Join Discord"
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 80)
info.Position = UDim2.new(0, 12, 0, 70)
info.BackgroundTransparency = 1
info.Text = "Klik kanan = Aimbot\nV = Toggle NoClip\nGeser window bebas\nLine ESP = skeleton"
info.TextColor3 = Theme.TextDim
info.TextSize = 13
info.Font = Enum.Font.Gotham
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = MiscPage

-- ===================== LOOPS =====================
RunService.RenderStepped:Connect(function()
    Clear()

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            if CFG.Speed then
                hum.WalkSpeed = CFG.WalkSpeed
                hum.JumpPower = CFG.JumpPower
            else
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
        if CFG.NoClip and root then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end

    if CFG.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            local c = plr.Character
            if not c then continue end
            local hum = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if not hum or hum.Health <= 0 or not root then continue end

            local pos, on = Camera:WorldToViewportPoint(root.Position)
            if not on then continue end

            local col = Color3.fromRGB(0, 255, 130)
            if hum.Health < 30 then col = Color3.fromRGB(255, 60, 60) end
            LineESP(c, col)

            if CFG.Name then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                local txt = Draw("Text", {
                    Text = string.format("%s  |  %dm  |  %dhp", plr.Name, dist, math.floor(hum.Health)),
                    Position = Vector2.new(pos.X, pos.Y - 42),
                    Size = 14,
                    Center = true,
                    Outline = true,
                    Color = Color3.new(1,1,1),
                    Visible = true
                })
                table.insert(drawings, txt)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not CFG.Aimbot then return end
    if not UIS:IsMouseButtonPressed(CFG.AimKey) then return end
    local t = GetClosest()
    if t then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, t.Position), CFG.Smooth)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V then
        CFG.NoClip = not CFG.NoClip
    end
end)

print("[VD HUB] v" .. VERSION .. " loaded")
