-- Violence District | ESP + Aimbot + Speed
-- Buat Executor Real

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local CFG = {
    ESP = true,
    Box = true,
    Name = true,
    Distance = true,
    HealthBar = true,
    TeamCheck = false,

    Aimbot = true,
    AimKey = Enum.UserInputType.MouseButton2,
    FOV = 250,
    Smooth = 0.11,
    AimPart = "Head",

    WalkSpeed = 55,
    JumpPower = 65,
    NoClip = false,
}

local drawings = {}

local function draw(class, props)
    local o = Drawing.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

local function clear()
    for i, d in pairs(drawings) do
        pcall(function() d:Remove() end)
        drawings[i] = nil
    end
end

local function getClosest()
    local closest, shortest = nil, CFG.FOV
    local mouse = UIS:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if CFG.TeamCheck and plr.Team and plr.Team == LP.Team then continue end

        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
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

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V then
        CFG.NoClip = not CFG.NoClip
        print("[VD] NoClip:", CFG.NoClip and "ON" or "OFF")
    end
end)

RunService.RenderStepped:Connect(function()
    clear()

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        if hum then
            hum.WalkSpeed = CFG.WalkSpeed
            hum.JumpPower = CFG.JumpPower
        end

        if CFG.NoClip and root then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    if not CFG.ESP then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if CFG.TeamCheck and plr.Team and plr.Team == LP.Team then continue end

        local c = plr.Character
        if not c then continue end
        local hum = c:FindFirstChildOfClass("Humanoid")
        local root = c:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not root then continue end

        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end

        local size = 2000 / pos.Z
        local x, y = pos.X, pos.Y

        if CFG.Box then
            local box = draw("Square", {
                Size = Vector2.new(size, size * 1.6),
                Position = Vector2.new(x - size/2, y - size*0.8),
                Color = Color3.fromRGB(255, 50, 50),
                Thickness = 1.3,
                Filled = false,
                Visible = true
            })
            table.insert(drawings, box)
        end

        if CFG.HealthBar then
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barH = size * 1.6
            local bar = draw("Square", {
                Size = Vector2.new(3, barH * hp),
                Position = Vector2.new(x - size/2 - 6, y - size*0.8 + barH * (1-hp)),
                Color = Color3.fromRGB(0, 255, 80),
                Filled = true,
                Visible = true
            })
            table.insert(drawings, bar)
        end

        if CFG.Name or CFG.Distance then
            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            local txt = draw("Text", {
                Text = string.format("%s  [%.0fm]", plr.Name, dist),
                Position = Vector2.new(x, y - size*0.95 - 15),
                Size = 14,
                Center = true,
                Outline = true,
                Color = Color3.fromRGB(255, 255, 255),
                Visible = true
            })
            table.insert(drawings, txt)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not CFG.Aimbot then return end
    if not UIS:IsMouseButtonPressed(CFG.AimKey) then return end

    local target = getClosest()
    if target then
        local cam = Camera.CFrame
        Camera.CFrame = cam:Lerp(CFrame.new(cam.Position, target.Position), CFG.Smooth)
    end
end)

print("[Violence District] loaded | tekan V untuk NoClip")
