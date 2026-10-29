--[[
    Violence District Premium GUI
    By Zibey
    Version  : 1.0
    Fitur    : Line ESP, Aimbot, Speed, NoClip, More
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local HttpService  = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================== CONFIG =====================
local CFG = {
    ESP         = false,
    LineESP     = true,
    Name        = true,
    Distance    = true,
    HealthText  = true,
    TeamCheck   = false,

    Aimbot      = false,
    AimKey      = Enum.UserInputType.MouseButton2,
    FOV         = 280,
    Smooth      = 0.11,
    AimPart     = "Head",

    Speed       = false,
    WalkSpeed   = 56,
    JumpPower   = 65,

    NoClip      = false,
}

local VERSION = "2.0"
local DISCORD_LINK = "https://discord.gg/ojailbreaks"   -- ganti kalau mau

-- ===================== THEME =====================
local Themes = {
    Dark = {
        Background = Color3.fromRGB(16, 16, 20),
        TitleBar   = Color3.fromRGB(24, 24, 30),
        ButtonOff  = Color3.fromRGB(35, 35, 42),
        ButtonOn   = Color3.fromRGB(0, 170, 120),
        Text       = Color3.fromRGB(230, 230, 240),
        Accent     = Color3.fromRGB(0, 200, 140),
        Stroke     = Color3.fromRGB(50, 50, 60),
    },
    Purple = {
        Background = Color3.fromRGB(22, 16, 30),
        TitleBar   = Color3.fromRGB(32, 22, 45),
        ButtonOff  = Color3.fromRGB(40, 30, 55),
        ButtonOn   = Color3.fromRGB(140, 70, 220),
        Text       = Color3.fromRGB(235, 230, 255),
        Accent     = Color3.fromRGB(170, 100, 255),
        Stroke     = Color3.fromRGB(70, 50, 90),
    },
    Red = {
        Background = Color3.fromRGB(25, 12, 12),
        TitleBar   = Color3.fromRGB(40, 18, 18),
        ButtonOff  = Color3.fromRGB(50, 25, 25),
        ButtonOn   = Color3.fromRGB(200, 50, 50),
        Text       = Color3.fromRGB(255, 230, 230),
        Accent     = Color3.fromRGB(255, 70, 70),
        Stroke     = Color3.fromRGB(80, 30, 30),
    },
    Blue = {
        Background = Color3.fromRGB(12, 16, 28),
        TitleBar   = Color3.fromRGB(18, 24, 42),
        ButtonOff  = Color3.fromRGB(25, 35, 55),
        ButtonOn   = Color3.fromRGB(40, 120, 220),
        Text       = Color3.fromRGB(220, 230, 255),
        Accent     = Color3.fromRGB(60, 150, 255),
        Stroke     = Color3.fromRGB(40, 60, 90),
    },
}

local CurrentTheme = Themes.Dark
local ThemeOrder = {"Dark", "Purple", "Red", "Blue"}
local ThemeIndex = 1

-- ===================== DRAWING =====================
local drawings = {}

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function ClearDrawings()
    for i, d in pairs(drawings) do
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

-- ===================== AIMBOT =====================
local function GetClosest()
    local closest, shortest = nil, CFG.FOV
    local mouse = UIS:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if CFG.TeamCheck and plr.Team and plr.Team == LP.Team then continue end

        local char = plr.Character
        if not char then continue end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local part = char:FindFirstChild(CFG.AimPart) or char:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not part then continue end

        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
            if dist < shortest then
                shortest = dist
                closest = part
            end
        end
    end
    return closest
end

-- ===================== GUI =====================
pcall(function()
    if CoreGui:FindFirstChild("VD_Premium") then
        CoreGui.VD_Premium:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VD_Premium"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 420)
Main.Position = UDim2.new(0, 50, 0.25, 0)
Main.BackgroundColor3 = CurrentTheme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = CurrentTheme.Stroke
MainStroke.Thickness = 1.5

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = CurrentTheme.TitleBar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Violence District  •  v" .. VERSION
Title.TextColor3 = CurrentTheme.Text
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    ClearDrawings()
end)

-- Theme button
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(0, 30, 0, 30)
ThemeBtn.Position = UDim2.new(1, -70, 0, 4)
ThemeBtn.BackgroundColor3 = CurrentTheme.Accent
ThemeBtn.Text = "🎨"
ThemeBtn.TextSize = 14
ThemeBtn.Font = Enum.Font.GothamBold
ThemeBtn.Parent = TitleBar
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 6)

-- Function apply theme
local function ApplyTheme(theme)
    CurrentTheme = theme
    Main.BackgroundColor3 = theme.Background
    TitleBar.BackgroundColor3 = theme.TitleBar
    Title.TextColor3 = theme.Text
    MainStroke.Color = theme.Stroke
    ThemeBtn.BackgroundColor3 = theme.Accent
end

ThemeBtn.MouseButton1Click:Connect(function()
    ThemeIndex = ThemeIndex % #ThemeOrder + 1
    ApplyTheme(Themes[ThemeOrder[ThemeIndex]])
end)

-- Toggle button creator
local function CreateToggle(text, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 36)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = default and CurrentTheme.ButtonOn or CurrentTheme.ButtonOff
    btn.BorderSizePixel = 0
    btn.Text = "  " .. text .. "   " .. (default and "ON" or "OFF")
    btn.TextColor3 = CurrentTheme.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and CurrentTheme.ButtonOn or CurrentTheme.ButtonOff
        btn.Text = "  " .. text .. "   " .. (state and "ON" or "OFF")
        callback(state)
    end)

    -- hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and CurrentTheme.ButtonOn or Color3.fromRGB(
                math.min(CurrentTheme.ButtonOff.R*255 + 20, 255)/255,
                math.min(CurrentTheme.ButtonOff.G*255 + 20, 255)/255,
                math.min(CurrentTheme.ButtonOff.B*255 + 20, 255)/255
            )
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and CurrentTheme.ButtonOn or CurrentTheme.ButtonOff
        }):Play()
    end)

    return btn
end

CreateToggle("Line ESP",     50,  CFG.ESP,     function(v) CFG.ESP = v end)
CreateToggle("Aimbot",       95,  CFG.Aimbot,  function(v) CFG.Aimbot = v end)
CreateToggle("Speed Boost",  140, CFG.Speed,   function(v) CFG.Speed = v end)
CreateToggle("NoClip",       185, CFG.NoClip,  function(v) CFG.NoClip = v end)

-- Discord Button
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(1, -24, 0, 40)
DiscordBtn.Position = UDim2.new(0, 12, 0, 240)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordBtn.Text = "  💬  Join Discord"
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.TextSize = 15
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.Parent = Main
Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 8)

DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard(DISCORD_LINK)
    end)
    pcall(function()
        -- beberapa executor support
        if request then
            request({Url = DISCORD_LINK, Method = "GET"})
        end
    end)
    DiscordBtn.Text = "  ✓  Link Copied!"
    task.wait(1.5)
    DiscordBtn.Text = "  💬  Join Discord"
end)

-- Info
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -24, 0, 70)
Info.Position = UDim2.new(0, 12, 0, 300)
Info.BackgroundTransparency = 1
Info.Text = "Klik kanan = Aimbot\nV = Toggle NoClip\n🎨 = Ganti Theme\nLine ESP = skeleton"
Info.TextColor3 = Color3.fromRGB(150, 150, 165)
Info.TextSize = 13
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.Parent = Main

-- ===================== LINE ESP =====================
local function DrawLineESP(char, color)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")

    if not (head and root) then return end

    local function toScreen(part)
        if not part then return nil end
        local pos, on = Camera:WorldToViewportPoint(part.Position)
        if on then return Vector2.new(pos.X, pos.Y) end
        return nil
    end

    local h = toScreen(head)
    local r = toScreen(root)
    local t = toScreen(torso)
    local la = toScreen(leftArm)
    local ra = toScreen(rightArm)
    local ll = toScreen(leftLeg)
    local rl = toScreen(rightLeg)

    local function line(from, to)
        if from and to then
            local l = CreateDrawing("Line", {
                From = from,
                To = to,
                Color = color,
                Thickness = 1.6,
                Visible = true
            })
            table.insert(drawings, l)
        end
    end

    -- skeleton connections
    if h and t then line(h, t) end
    if t and r then line(t, r) end
    if t and la then line(t, la) end
    if t and ra then line(t, ra) end
    if r and ll then line(r, ll) end
    if r and rl then line(r, rl) end
end

-- ===================== MAIN LOOP =====================
RunService.RenderStepped:Connect(function()
    ClearDrawings()

    local char = LP.Character
    if char then
        local hum  = char:FindFirstChildOfClass("Humanoid")
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
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end

    if CFG.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            if CFG.TeamCheck and plr.Team and plr.Team == LP.Team then continue end

            local c = plr.Character
            if not c then continue end
            local hum  = c:FindFirstChildOfClass("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            local head = c:FindFirstChild("Head")
            if not hum or hum.Health <= 0 or not root then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if not onScreen then continue end

            -- Line / Skeleton ESP
            if CFG.LineESP then
                local col = Color3.fromRGB(0, 255, 140)
                if hum.Health < 30 then col = Color3.fromRGB(255, 60, 60) end
                DrawLineESP(c, col)
            end

            -- Name + Distance + Health
            if CFG.Name or CFG.Distance or CFG.HealthText then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                local hp = math.floor(hum.Health)
                local text = string.format("%s  |  %dm  |  %dhp", plr.Name, dist, hp)

                local txt = CreateDrawing("Text", {
                    Text = text,
                    Position = Vector2.new(pos.X, pos.Y - 45),
                    Size = 14,
                    Center = true,
                    Outline = true,
                    Color = Color3.fromRGB(255, 255, 255),
                    Visible = true
                })
                table.insert(drawings, txt)
            end
        end
    end
end)

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not CFG.Aimbot then return end
    if not UIS:IsMouseButtonPressed(CFG.AimKey) then return end
    local target = GetClosest()
    if target then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.Smooth)
    end
end)

-- Hotkey
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V then
        CFG.NoClip = not CFG.NoClip
    end
end)

print("[VD Premium] v" .. VERSION .. " loaded | Theme + Line ESP aktif")
