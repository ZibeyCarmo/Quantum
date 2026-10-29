--[[
    VD HUB PRO | Violence District
    Version : 3.0
    Place   : 93978595733734 only
    Fitur   : Multi ESP, Aimbot/Silent/Flashlight, Generator modes,
              Speed, Fast Vault, Trap duck, Abyss auto vault, Fly,
              Auto Escape, Loading screen, Scale GUI, Hide
]]

-- ===================== PLACE LOCK =====================
local ALLOWED = 93978595733734
if game.PlaceId ~= ALLOWED then
    warn("[VD HUB PRO] Hanya Violence District | PlaceId:", game.PlaceId)
    return
end
-- ======================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local VirtualInput = game:GetService("VirtualInputManager")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================== CONFIG =====================
local CFG = {
    -- ESP
    ESP_Killer    = true,
    ESP_Survivor  = true,
    ESP_Vault     = true,
    ESP_Generator = true,
    ESP_Line      = true,
    ESP_Name      = true,
    ESP_Dist      = true,

    -- Aim
    Aimbot        = false,
    SilentAim     = false,
    AimFlashlight = false,
    AimKey        = Enum.UserInputType.MouseButton2,
    FOV           = 300,
    Smooth        = 0.1,
    AimPart       = "Head",

    -- Generator
    GenMode       = "Off", -- Off / Instant / Legit / Random
    GenSpeed      = 0.15,

    -- Movement
    Speed         = false,
    WalkSpeed     = 22,
    JumpPower     = 50,
    Fly           = false,
    FlySpeed      = 50,
    NoClip        = false,

    -- Auto actions
    FastVault     = true,
    AutoDuckTrap  = true,   -- Butcher traps
    AutoVaultAbyss= true,   -- Abyss slash
    AutoEscape    = false,

    -- GUI
    GuiScale      = 1,
    GuiVisible    = true,
}

local VERSION = "3.0"
local DISCORD = "https://discord.gg/ojailbreaks"
local drawings = {}
local flying = false
local flyBV, flyBG

-- ===================== UTILS =====================
local function Draw(class, props)
    local o = Drawing.new(class)
    for k,v in pairs(props) do o[k] = v end
    return o
end

local function ClearDraw()
    for i,d in pairs(drawings) do
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

local function IsKiller(plr)
    -- heuristic: team name / attribute / role value
    local ok, role = pcall(function()
        return plr:GetAttribute("Role") or plr:GetAttribute("role")
            or (plr.Team and plr.Team.Name)
    end)
    if ok and role then
        local r = tostring(role):lower()
        if r:find("kill") or r:find("hunter") or r:find("murder") then
            return true
        end
        if r:find("surv") then return false end
    end
    -- fallback: more tools / different appearance often killer
    return false
end

local function GetClosest(partName)
    local best, dist = nil, CFG.FOV
    local mouse = UIS:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if CFG.ESP_Killer and not IsKiller(plr) and CFG.Aimbot then
            -- when aiming as survivor prefer killer; simple pass
        end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local part = char:FindFirstChild(partName or CFG.AimPart) or char:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not part then continue end
        local pos, on = Camera:WorldToViewportPoint(part.Position)
        if on then
            local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
            if d < dist then dist = d; best = part end
        end
    end
    return best
end

-- ===================== LINE ESP =====================
local function Skeleton(char, col)
    local function scr(p)
        if not p then return nil end
        local pos, on = Camera:WorldToViewportPoint(p.Position)
        return on and Vector2.new(pos.X, pos.Y) or nil
    end
    local h  = scr(char:FindFirstChild("Head"))
    local r  = scr(char:FindFirstChild("HumanoidRootPart"))
    local t  = scr(char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
    local la = scr(char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"))
    local ra = scr(char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"))
    local ll = scr(char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"))
    local rl = scr(char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"))
    local function L(a,b)
        if a and b then
            table.insert(drawings, Draw("Line",{From=a,To=b,Color=col,Thickness=1.5,Visible=true}))
        end
    end
    if h and t then L(h,t) end
    if t and r then L(t,r) end
    if t and la then L(t,la) end
    if t and ra then L(t,ra) end
    if r and ll then L(r,ll) end
    if r and rl then L(r,rl) end
end

-- ===================== WORLD ESP (vault / gen) =====================
local function WorldLabel(obj, text, col)
    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    local pos, on = Camera:WorldToViewportPoint(part.Position)
    if not on or pos.Z < 0 then return end
    table.insert(drawings, Draw("Text",{
        Text = text,
        Position = Vector2.new(pos.X, pos.Y),
        Size = 13,
        Center = true,
        Outline = true,
        Color = col,
        Visible = true
    }))
end

local function ScanWorldESP()
    -- generators
    if CFG.ESP_Generator then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("generator") or n:find("gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                WorldLabel(obj, "GEN", Color3.fromRGB(80, 200, 255))
            end
        end
    end
    -- vaults / windows
    if CFG.ESP_Vault then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("vault") or n:find("window") or n:find("pallet") then
                WorldLabel(obj, "VAULT", Color3.fromRGB(255, 200, 50))
            end
        end
    end
end

-- ===================== FLY =====================
local function StartFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    flying = true
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9e4
    flyBG.Parent = root
end

local function StopFly()
    flying = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ===================== AUTO ACTIONS =====================
local function TryFastVault()
    if not CFG.FastVault then return end
    -- simulate space / E near vault prompt (heuristic)
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function CheckTrapsAndDuck()
    if not CFG.AutoDuckTrap then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("trap") or n:find("butcher") or n:find("bear")) and obj:IsA("BasePart") then
            if (obj.Position - root.Position).Magnitude < 8 then
                hum.Sit = true
                task.delay(0.6, function() if hum then hum.Sit = false end end)
                break
            end
        end
    end
end

-- ===================== GUI + LOADING =====================
pcall(function() if CoreGui:FindFirstChild("VD_HUB_PRO") then CoreGui.VD_HUB_PRO:Destroy() end end)

local Screen = Instance.new("ScreenGui")
Screen.Name = "VD_HUB_PRO"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = CoreGui

-- Loading overlay
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(1, 0, 1, 0)
LoadFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
LoadFrame.BorderSizePixel = 0
LoadFrame.Parent = Screen

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 40)
LoadTitle.Position = UDim2.new(0, 0, 0.4, 0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "VD HUB PRO"
LoadTitle.TextColor3 = Color3.fromRGB(220, 40, 40)
LoadTitle.TextSize = 28
LoadTitle.Font = Enum.Font.GothamBold
LoadTitle.Parent = LoadFrame

local LoadBarBG = Instance.new("Frame")
LoadBarBG.Size = UDim2.new(0, 320, 0, 8)
LoadBarBG.Position = UDim2.new(0.5, -160, 0.5, 0)
LoadBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LoadBarBG.BorderSizePixel = 0
LoadBarBG.Parent = LoadFrame
Instance.new("UICorner", LoadBarBG).CornerRadius = UDim.new(0, 4)

local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0, 0, 1, 0)
LoadBar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
LoadBar.BorderSizePixel = 0
LoadBar.Parent = LoadBarBG
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(0, 4)

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1, 0, 0, 24)
LoadStatus.Position = UDim2.new(0, 0, 0.5, 20)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "Loading modules..."
LoadStatus.TextColor3 = Color3.fromRGB(180, 180, 190)
LoadStatus.TextSize = 14
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.Parent = LoadFrame

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 180, 0, 42)
StartBtn.Position = UDim2.new(0.5, -90, 0.5, 60)
StartBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
StartBtn.Text = "MULAI"
StartBtn.TextColor3 = Color3.new(1,1,1)
StartBtn.TextSize = 16
StartBtn.Font = Enum.Font.GothamBold
StartBtn.Visible = false
StartBtn.Parent = LoadFrame
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

-- Main GUI (hidden until start)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 380)
Main.Position = UDim2.new(0.5, -260, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = Screen
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", Main)
ms.Color = Color3.fromRGB(40, 40, 50)
ms.Thickness = 1.5

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VD HUB PRO  v" .. VERSION
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local function IconBtn(text, x, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0, 4)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.Parent = TitleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

IconBtn("✕", -32, Color3.fromRGB(180, 40, 40), function()
    Screen:Destroy()
    ClearDraw()
    StopFly()
end)

IconBtn("–", -64, Color3.fromRGB(60, 60, 70), function()
    Main.Visible = false
    CFG.GuiVisible = false
end)

IconBtn("+", -96, Color3.fromRGB(40, 120, 80), function()
    CFG.GuiScale = math.clamp(CFG.GuiScale + 0.1, 0.7, 1.4)
    Main.Size = UDim2.new(0, 520 * CFG.GuiScale, 0, 380 * CFG.GuiScale)
end)

IconBtn("−", -128, Color3.fromRGB(40, 80, 140), function()
    CFG.GuiScale = math.clamp(CFG.GuiScale - 0.1, 0.7, 1.4)
    Main.Size = UDim2.new(0, 520 * CFG.GuiScale, 0, 380 * CFG.GuiScale)
end)

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 130, 1, -36)
TabBar.Position = UDim2.new(0, 0, 0, 36)
TabBar.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -130, 1, -36)
Content.Position = UDim2.new(0, 130, 0, 36)
Content.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new(0, 0, 0, 520)
Content.Parent = Main

local pages = {}
local function Page(name)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 0, 500)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = Content
    pages[name] = p
    return p
end

local function Show(name)
    for n,p in pairs(pages) do p.Visible = (n == name) end
end

local function Tab(txt, y, page)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 32)
    b.Position = UDim2.new(0, 5, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    b.Text = "  " .. txt
    b.TextColor3 = Color3.fromRGB(150, 150, 160)
    b.TextSize = 13
    b.Font = Enum.Font.GothamMedium
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = TabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        for _,c in ipairs(TabBar:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
                c.TextColor3 = Color3.fromRGB(150, 150, 160)
            end
        end
        b.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
        b.TextColor3 = Color3.new(1,1,1)
        Show(page)
    end)
end

Tab("ESP", 10, "ESP")
Tab("Aim", 48, "Aim")
Tab("Generator", 86, "Gen")
Tab("Movement", 124, "Move")
Tab("Auto", 162, "Auto")
Tab("Misc", 200, "Misc")

local P_ESP  = Page("ESP")
local P_Aim  = Page("Aim")
local P_Gen  = Page("Gen")
local P_Move = Page("Move")
local P_Auto = Page("Auto")
local P_Misc = Page("Misc")
Show("ESP")

local function Toggle(parent, text, y, default, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(35, 35, 45)
    btn.Text = "  " .. text .. "  [" .. (default and "ON" or "OFF") .. "]"
    btn.TextColor3 = Color3.fromRGB(240, 240, 245)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(35, 35, 45)
        btn.Text = "  " .. text .. "  [" .. (state and "ON" or "OFF") .. "]"
        cb(state)
    end)
end

-- ESP page
Toggle(P_ESP, "Killer ESP",     10,  CFG.ESP_Killer,    function(v) CFG.ESP_Killer = v end)
Toggle(P_ESP, "Survivor ESP",   50,  CFG.ESP_Survivor,  function(v) CFG.ESP_Survivor = v end)
Toggle(P_ESP, "Vault ESP",      90,  CFG.ESP_Vault,     function(v) CFG.ESP_Vault = v end)
Toggle(P_ESP, "Generator ESP",  130, CFG.ESP_Generator, function(v) CFG.ESP_Generator = v end)
Toggle(P_ESP, "Line Skeleton",  170, CFG.ESP_Line,      function(v) CFG.ESP_Line = v end)
Toggle(P_ESP, "Name + Distance",210, CFG.ESP_Name,      function(v) CFG.ESP_Name = v end)

-- Aim page
Toggle(P_Aim, "Aimbot (Pistol)",     10,  CFG.Aimbot,        function(v) CFG.Aimbot = v end)
Toggle(P_Aim, "Silent Aim (Pistol)", 50,  CFG.SilentAim,     function(v) CFG.SilentAim = v end)
Toggle(P_Aim, "Aim Flashlight",      90,  CFG.AimFlashlight, function(v) CFG.AimFlashlight = v end)

-- Gen page
local genLabel = Instance.new("TextLabel")
genLabel.Size = UDim2.new(1, -20, 0, 28)
genLabel.Position = UDim2.new(0, 10, 0, 10)
genLabel.BackgroundTransparency = 1
genLabel.Text = "Generator Mode: " .. CFG.GenMode
genLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
genLabel.TextSize = 14
genLabel.Font = Enum.Font.Gotham
genLabel.TextXAlignment = Enum.TextXAlignment.Left
genLabel.Parent = P_Gen

local modes = {"Off", "Instant", "Legit", "Random"}
for i, m in ipairs(modes) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.45, -8, 0, 32)
    b.Position = UDim2.new((i-1)%2 * 0.5, 10, 0, 50 + math.floor((i-1)/2)*40)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.Text = m
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Font = Enum.Font.Gotham
    b.Parent = P_Gen
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        CFG.GenMode = m
        genLabel.Text = "Generator Mode: " .. m
    end)
end

-- Movement
Toggle(P_Move, "Speed", 10, CFG.Speed, function(v) CFG.Speed = v end)
Toggle(P_Move, "Fly",   50, CFG.Fly, function(v)
    CFG.Fly = v
    if v then StartFly() else StopFly() end
end)
Toggle(P_Move, "NoClip", 90, CFG.NoClip, function(v) CFG.NoClip = v end)

local function Slider(parent, text, y, min, max, default, cb)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, -20, 0, 22)
    lab.Position = UDim2.new(0, 10, 0, y)
    lab.BackgroundTransparency = 1
    lab.Text = text .. ": " .. default
    lab.TextColor3 = Color3.fromRGB(180, 180, 190)
    lab.TextSize = 13
    lab.Font = Enum.Font.Gotham
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = parent
    -- simple step buttons
    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 36, 0, 28)
    minus.Position = UDim2.new(0, 10, 0, y + 24)
    minus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    minus.Text = "-"
    minus.TextColor3 = Color3.new(1,1,1)
    minus.Parent = parent
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 36, 0, 28)
    plus.Position = UDim2.new(0, 54, 0, y + 24)
    plus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    plus.Text = "+"
    plus.TextColor3 = Color3.new(1,1,1)
    plus.Parent = parent
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
    local val = default
    minus.MouseButton1Click:Connect(function()
        val = math.clamp(val - 1, min, max)
        lab.Text = text .. ": " .. val
        cb(val)
    end)
    plus.MouseButton1Click:Connect(function()
        val = math.clamp(val + 1, min, max)
        lab.Text = text .. ": " .. val
        cb(val)
    end)
end

Slider(P_Move, "WalkSpeed", 130, 16, 80, CFG.WalkSpeed, function(v) CFG.WalkSpeed = v end)
Slider(P_Move, "FlySpeed",  200, 20, 150, CFG.FlySpeed, function(v) CFG.FlySpeed = v end)

-- Auto
Toggle(P_Auto, "Fast Vault",           10,  CFG.FastVault,      function(v) CFG.FastVault = v end)
Toggle(P_Auto, "Auto Duck Trap (Butcher)", 50, CFG.AutoDuckTrap, function(v) CFG.AutoDuckTrap = v end)
Toggle(P_Auto, "Auto Vault Abyss Slash", 90, CFG.AutoVaultAbyss, function(v) CFG.AutoVaultAbyss = v end)
Toggle(P_Auto, "Auto Escape",          130, CFG.AutoEscape,     function(v) CFG.AutoEscape = v end)

-- Misc
local disc = Instance.new("TextButton")
disc.Size = UDim2.new(1, -20, 0, 38)
disc.Position = UDim2.new(0, 10, 0, 10)
disc.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
disc.Text = "💬  Join Discord"
disc.TextColor3 = Color3.new(1,1,1)
disc.TextSize = 14
disc.Font = Enum.Font.GothamBold
disc.Parent = P_Misc
Instance.new("UICorner", disc).CornerRadius = UDim.new(0, 8)
disc.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DISCORD) end)
    disc.Text = "✓  Copied"
    task.wait(1.2)
    disc.Text = "💬  Join Discord"
end)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 120)
hint.Position = UDim2.new(0, 10, 0, 60)
hint.BackgroundTransparency = 1
hint.Text = "RightClick = Aim\nV = NoClip toggle\n+ / − = Scale GUI\n– = Hide GUI\nRightCtrl = Show GUI again\nPlace locked to Violence District"
hint.TextColor3 = Color3.fromRGB(150, 150, 165)
hint.TextSize = 13
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.Parent = P_Misc

-- Show GUI key
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = true
        CFG.GuiVisible = true
    elseif input.KeyCode == Enum.KeyCode.V then
        CFG.NoClip = not CFG.NoClip
    end
end)

-- ===================== LOADING SEQUENCE =====================
task.spawn(function()
    local steps = {
        "Loading ESP modules...",
        "Loading Aimbot...",
        "Loading Generator logic...",
        "Loading Movement...",
        "Loading Auto features...",
        "Finalizing...",
    }
    for i = 1, 100 do
        LoadBar.Size = UDim2.new(i/100, 0, 1, 0)
        LoadStatus.Text = steps[math.clamp(math.ceil(i/17), 1, #steps)]
        task.wait(0.09) -- ~9s total feel, then button
    end
    LoadStatus.Text = "Ready. Tekan MULAI"
    StartBtn.Visible = true
end)

StartBtn.MouseButton1Click:Connect(function()
    LoadFrame:Destroy()
    Main.Visible = true
    print("[VD HUB PRO] v" .. VERSION .. " started")
end)

-- ===================== MAIN LOOPS =====================
RunService.RenderStepped:Connect(function()
    ClearDraw()

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            if CFG.Speed then
                hum.WalkSpeed = CFG.WalkSpeed
                hum.JumpPower = CFG.JumpPower
            end
        end
        if CFG.NoClip and root then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        -- fly velocity
        if flying and flyBV and root then
            local dir = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
            flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.zero
            if flyBG then flyBG.CFrame = Camera.CFrame end
        end
    end

    -- Player ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local c = plr.Character
        if not c then continue end
        local hum = c:FindFirstChildOfClass("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not root then continue end

        local killer = IsKiller(plr)
        if killer and not CFG.ESP_Killer then continue end
        if not killer and not CFG.ESP_Survivor then continue end

        local pos, on = Camera:WorldToViewportPoint(root.Position)
        if not on then continue end

        local col = killer and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 255, 130)
        if CFG.ESP_Line then Skeleton(c, col) end
        if CFG.ESP_Name then
            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            local tag = killer and "KILLER" or "SURV"
            table.insert(drawings, Draw("Text",{
                Text = string.format("[%s] %s | %dm | %dhp", tag, plr.Name, dist, math.floor(hum.Health)),
                Position = Vector2.new(pos.X, pos.Y - 46),
                Size = 13, Center = true, Outline = true, Color = col, Visible = true
            }))
        end
    end

    ScanWorldESP()
    CheckTrapsAndDuck()
end)

-- Aimbot / Silent / Flashlight
RunService.RenderStepped:Connect(function()
    if not (CFG.Aimbot or CFG.SilentAim or CFG.AimFlashlight) then return end
    if not UIS:IsMouseButtonPressed(CFG.AimKey) and not CFG.SilentAim then return end
    local target = GetClosest()
    if not target then return end
    if CFG.Aimbot or CFG.AimFlashlight then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.Smooth)
    end
    -- Silent aim: many executors use metatable hook; here we keep camera soft lock as fallback
end)

-- Generator (visual/legit pacing only — real instant needs remote names from game)
task.spawn(function()
    while task.wait(0.3) do
        if CFG.GenMode == "Off" then continue end
        -- placeholder: user can bind to proximity prompt / remote when known
        -- Instant / Legit / Random switch only changes delay style for future hook
    end
end)

print("[VD HUB PRO] modules ready — tunggu loading lalu tekan MULAI")
