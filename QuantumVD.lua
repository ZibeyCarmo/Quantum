--[[
    VD HUB | Violence District
    Version : 3.2
    - Line ESP (player / vault / pallet / generator)
    - GUI scale: tahan klik kiri di handle merah pojok kanan bawah
    - WorldToViewportPoint: cek depth (Z) + batas layar
    - Place lock
]]

local ALLOWED = 93978595733734
if game.PlaceId ~= ALLOWED then
    warn("[VD HUB] Hanya Violence District | PlaceId:", game.PlaceId)
    return
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CFG = {
    ESP_Player    = true,
    ESP_Vault     = true,
    ESP_Pallet    = true,
    ESP_Generator = true,
    Aimbot        = false,
    AimKey        = Enum.UserInputType.MouseButton2,
    FOV           = 280,
    Smooth        = 0.12,
    Speed         = false,
    WalkSpeed     = 22,
    GenMode       = "Off", -- Off / Instant / Legit / Random
}

local VERSION = "3.2"
local drawings = {}

local function ClearDraw()
    for i = #drawings, 1, -1 do
        local d = drawings[i]
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

--[[
    WorldToViewportPoint(worldPos) → screen (Vector3), onScreen (bool)
    screen.X / screen.Y = pixel di layar
    screen.Z            = depth (depan kamera > 0, belakang < 0)
    Line ESP hanya digambar jika Z > 0 dan kira-kira masih di area layar
]]
local function AddLine(worldPos, color)
    if typeof(worldPos) ~= "Vector3" then return end

    local ok, screen, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(worldPos)
    end)
    if not ok or not screen then return end

    -- depth: di belakang kamera → jangan gambar
    if screen.Z < 0 then return end

    local vp = Camera.ViewportSize
    local sx, sy = screen.X, screen.Y

    -- longgar di tepi (±50px) biar line nggak putus saat target di pinggir
    if sx < -50 or sy < -50 or sx > vp.X + 50 or sy > vp.Y + 50 then
        return
    end

    local from = Vector2.new(vp.X * 0.5, vp.Y - 2) -- bawah tengah layar
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
            if part and (part.Position - root.Position).Magnitude < 20 then
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

-- ===================== GUI =====================
pcall(function()
    local old = CoreGui:FindFirstChild("VD_HUB")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "VD_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- Loading singkat
local Load = Instance.new("Frame")
Load.Size = UDim2.new(1, 0, 1, 0)
Load.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Load.BorderSizePixel = 0
Load.Parent = gui

local LTitle = Instance.new("TextLabel")
LTitle.Size = UDim2.new(1, 0, 0, 36)
LTitle.Position = UDim2.new(0, 0, 0.42, 0)
LTitle.BackgroundTransparency = 1
LTitle.Text = "VD HUB  v" .. VERSION
LTitle.TextColor3 = Color3.fromRGB(220, 40, 40)
LTitle.TextSize = 26
LTitle.Font = Enum.Font.GothamBold
LTitle.Parent = Load

local barBG = Instance.new("Frame")
barBG.Size = UDim2.new(0, 280, 0, 8)
barBG.Position = UDim2.new(0.5, -140, 0.5, 0)
barBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barBG.BorderSizePixel = 0
barBG.Parent = Load
Instance.new("UICorner", barBG).CornerRadius = UDim.new(0, 4)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
bar.BorderSizePixel = 0
bar.Parent = barBG
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

local Start = Instance.new("TextButton")
Start.Size = UDim2.new(0, 150, 0, 38)
Start.Position = UDim2.new(0.5, -75, 0.5, 36)
Start.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
Start.Text = "MULAI"
Start.TextColor3 = Color3.new(1, 1, 1)
Start.TextSize = 15
Start.Font = Enum.Font.GothamBold
Start.Visible = false
Start.Parent = Load
Instance.new("UICorner", Start).CornerRadius = UDim.new(0, 8)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 400, 0, 340)
Main.Position = UDim2.new(0.5, -200, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(50, 50, 60)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VD HUB  v" .. VERSION .. "  |  Line ESP"
Title.TextColor3 = Color3.fromRGB(235, 235, 245)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 24, 0, 24)
Close.Position = UDim2.new(1, -28, 0, 4)
Close.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 12
Close.Parent = TitleBar
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 5)
Close.MouseButton1Click:Connect(function()
    ClearDraw()
    gui:Destroy()
end)

-- Scale handle: tahan klik kiri + geser
local Handle = Instance.new("TextButton")
Handle.Name = "ScaleHandle"
Handle.Size = UDim2.new(0, 16, 0, 16)
Handle.Position = UDim2.new(1, -16, 1, -16)
Handle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
Handle.Text = ""
Handle.AutoButtonColor = false
Handle.Parent = Main
Instance.new("UICorner", Handle).CornerRadius = UDim.new(0, 3)

local scaling = false
local originMouse = Vector2.zero
local originSize  = Vector2.zero

Handle.MouseButton1Down:Connect(function()
    scaling = true
    originMouse = UIS:GetMouseLocation()
    originSize  = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        scaling = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not scaling then return end
    local m = UIS:GetMouseLocation()
    local nx = math.clamp(originSize.X + (m.X - originMouse.X), 300, 720)
    local ny = math.clamp(originSize.Y + (m.Y - originMouse.Y), 220, 560)
    Main.Size = UDim2.fromOffset(nx, ny)
end)

local function AddToggle(label, y, flag)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = CFG[flag] and Color3.fromRGB(40, 150, 90) or Color3.fromRGB(36, 36, 46)
    b.Text = "  " .. label .. "  [" .. (CFG[flag] and "ON" or "OFF") .. "]"
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.TextSize = 13
    b.Font = Enum.Font.Gotham
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = Main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        CFG[flag] = not CFG[flag]
        b.BackgroundColor3 = CFG[flag] and Color3.fromRGB(40, 150, 90) or Color3.fromRGB(36, 36, 46)
        b.Text = "  " .. label .. "  [" .. (CFG[flag] and "ON" or "OFF") .. "]"
    end)
end

AddToggle("Player Line ESP", 40,  "ESP_Player")
AddToggle("Vault Line ESP",  72,  "ESP_Vault")
AddToggle("Pallet Line ESP", 104, "ESP_Pallet")
AddToggle("Generator Line",  136, "ESP_Generator")
AddToggle("Aimbot",          168, "Aimbot")
AddToggle("Speed",           200, "Speed")

local modes = {"Off", "Instant", "Legit", "Random"}
for i, m in ipairs(modes) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 88, 0, 26)
    b.Position = UDim2.new(0, 10 + (i - 1) * 94, 0, 240)
    b.BackgroundColor3 = (CFG.GenMode == m) and Color3.fromRGB(220, 40, 40) or Color3.fromRGB(40, 40, 52)
    b.Text = "Gen " .. m
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Parent = Main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function()
        CFG.GenMode = m
        for _, c in ipairs(Main:GetChildren()) do
            if c:IsA("TextButton") and c.Text:find("Gen ") then
                c.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
            end
        end
        b.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    end)
end

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 40)
hint.Position = UDim2.new(0, 10, 1, -52)
hint.BackgroundTransparency = 1
hint.Text = "Handle merah pojok kanan bawah = scale (tahan klik kiri)\nZ<0 di WorldToViewportPoint = skip line (di belakang kamera)"
hint.TextColor3 = Color3.fromRGB(140, 140, 155)
hint.TextSize = 11
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = Main

task.spawn(function()
    for i = 1, 100 do
        bar.Size = UDim2.new(i / 100, 0, 1, 0)
        task.wait(0.06)
    end
    Start.Visible = true
end)

Start.MouseButton1Click:Connect(function()
    Load:Destroy()
    Main.Visible = true
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = true
    end
end)

-- ===================== LOOPS =====================
RunService.RenderStepped:Connect(function()
    ClearDraw()

    local char = LP.Character
    if char and CFG.Speed then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = CFG.WalkSpeed end
    end

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

RunService.RenderStepped:Connect(function()
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
            if d < dist then dist = d; best = head end
        end
    end
    if best then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, best.Position), CFG.Smooth)
    end
end)

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

print("[VD HUB] v" .. VERSION .. " | scale + line ESP + WorldToViewportPoint check")
