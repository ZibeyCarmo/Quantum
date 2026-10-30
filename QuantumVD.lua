--[[
    Quantum Hub v5.2 — Violence District
    Executor compatibility build — Lua 5.1 safe syntax
    discord.gg/ojailbreaks | @oll.fx
    No compound assignment, no continue, no Vector3.zero, no :add()
]]

-- ════════════════════════════════════════════════════════════
-- [1] SERVICES
-- ════════════════════════════════════════════════════════════
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local StarterGui          = game:GetService("StarterGui")
local VirtualUser         = game:GetService("VirtualUser")

local VirtualInputManager = nil
do
    local ok, svc = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and svc then VirtualInputManager = svc end
end

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        Camera = workspace.CurrentCamera
    end
end)

-- ════════════════════════════════════════════════════════════
-- [2] DRAWING PROBE — guarded, never errors if missing
-- ════════════════════════════════════════════════════════════
local DrawingLib = nil
do
    local ok, probe = pcall(function() return Drawing.new("Square") end)
    if ok and probe ~= nil then
        pcall(function() probe:Remove() end)
        DrawingLib = Drawing
    end
end

local function newDrawing(kind)
    if not DrawingLib then return nil end
    local ok, d = pcall(function() return DrawingLib.new(kind) end)
    if ok and d ~= nil then return d end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- [3] STATE (declared before anything reads it)
-- ════════════════════════════════════════════════════════════
local mwActive   = false
local sbActive   = false
local ncActive   = false
local killerSPOn = false
local VFX_BACKUP = nil

-- ════════════════════════════════════════════════════════════
-- [4] PLACE GUARD
-- ════════════════════════════════════════════════════════════
local VD_PLACE_IDS = {
    -- 12345678901,
}

local function isViolenceDistrict()
    if #VD_PLACE_IDS == 0 then return true end
    local pid = game.PlaceId
    for i = 1, #VD_PLACE_IDS do
        if pid == VD_PLACE_IDS[i] then return true end
    end
    return false
end

if not isViolenceDistrict() then
    warn("[Quantum Hub] Not Violence District. PlaceId = " .. tostring(game.PlaceId))
end

-- ════════════════════════════════════════════════════════════
-- [5] CHAR HELPERS
-- ════════════════════════════════════════════════════════════
local function getChar() return LP.Character end

local function getHum()
    local c = getChar()
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = getChar()
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function isInMatch()
    local char = getChar()
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if workspace:FindFirstChild("GameMap") then return true end
    if workspace:FindFirstChild("Map") then return true end
    if workspace:FindFirstChild("VD_Map") then return true end
    if #Players:GetPlayers() > 1 then return true end
    return false
end

-- ════════════════════════════════════════════════════════════
-- [6] CONFIG
-- ════════════════════════════════════════════════════════════
local CFG = {
    ESP_Killer    = true,
    ESP_Survivor  = true,
    ESP_Gen       = true,
    ESP_Pallet    = true,
    ESP_Vault     = true,
    ESP_Chest     = false,
    ESP_Totem     = false,
    ESP_Hatch     = true,
    ESP_Abyss     = true,
    ESP_Style     = "box",
    ESP_Thick     = 2,
    ESP_MaxDist   = 400,
    ESP_ShowDist  = true,
    ESP_ShowName  = true,
    ESP_Flicker   = false,
    ESP_SnapLine  = false,
    ESP_RefreshHz = 4,
    C_Killer      = Color3.fromRGB(255, 51,  51),
    C_Surv        = Color3.fromRGB(51,  255, 136),
    C_Gen         = Color3.fromRGB(255, 238, 51),
    C_Pallet      = Color3.fromRGB(51,  170, 255),
    C_Abyss       = Color3.fromRGB(204, 68,  255),

    Fullbright    = true,
    FB_Level      = 8,
    NoShadow      = true,
    NoFog         = true,
    NoEffects     = true,
    ForceClock    = false,
    ClockTime     = 14,

    AimOn         = false,
    SilentAim     = false,
    AimBone       = "Head",
    AimFOV        = 80,
    AimSmooth     = 6,
    AimPredict    = 3,
    ShowFOV       = true,
    AimKiller     = true,
    AimKey        = "RMB",
    AimOffX       = 0,
    AimOffY       = 0,

    FlashAim      = false,
    FlashPred     = true,
    FlashStr      = 4,
    FlashBone     = "Head",

    VeilOn        = false,
    VeilPred      = true,
    VeilDist      = 30,
    VeilLead      = 5,
    VeilBone      = "Head",
    VeilFire      = false,

    Moonwalk      = false,
    MWKey         = Enum.KeyCode.G,
    SpeedBoost    = false,
    WalkSpeed     = 32,
    SBKey         = Enum.KeyCode.X,
    NoClip        = false,
    NCKey         = Enum.KeyCode.N,
    NCSpeed       = 50,
    NCFly         = false,
    FlyUp         = Enum.KeyCode.Space,
    FlyDown       = Enum.KeyCode.LeftControl,

    AutoGen       = false,
    GenMode       = "legit",
    AutoSkill     = true,
    GenNearest    = true,

    AutoPallet    = false,
    PalletDist    = 8,
    PalletKiller  = true,
    PalletCD      = 3,

    AutoDuck      = false,
    DuckDist      = 15,
    AbyssSkill    = "Slash",
    DuckDur       = 1.0,
    DuckAnim      = true,
    DuckHitbox    = false,

    AutoParry        = false,
    ParryDist        = 10,
    ParryKey         = Enum.KeyCode.F,
    ParryMode        = "auto",
    FakeParryOn      = false,
    FakeParryDist    = 15,
    FakeParryCD      = 2,
    ParryPredict     = true,
    ParryLead        = 3,
    ParrySkillName   = "Dagger",
    ParryHitboxName  = "DaggerHitbox",

    CamOn         = false,
    CamFOV        = 70,
    DBDCam        = false,
    CamPitch      = -35,
    CamDist       = 18,
    CamSmooth     = true,

    CopyAvatar    = false,
    CopyAvatarID  = 0,
    CopyByName    = "",

    AntiAFK       = true,
    InfStam       = false,
    InvisName     = false,

    AutoUnhook       = false,
    AutoUnhookDist   = 8,
    AutoHeal         = false,
    AutoHealDist     = 5,
    AutoHide         = false,
    AutoHideDist     = 20,
    AutoSabotage     = false,
    AutoSabotDist    = 8,
    AutoSabotCD      = 10,
    KillerPingESP    = false,
    KillerPingDist   = 30,
    AbyssAutoSlash   = false,
    AbyssSlashDist   = 15,
    AbyssSlashCD     = 3,
    AutoPickItem     = false,
    AutoPickDist     = 5,
    KillerSpeedHack  = false,
    KillerWS         = 24,
    KillerSpeedKey   = Enum.KeyCode.R,
}

local GENV = nil
do
    local ok, g = pcall(function() return getgenv() end)
    if ok and type(g) == "table" then GENV = g else GENV = _G end
end
GENV.QuantumHub = { CFG = CFG, version = "5.2" }

-- ════════════════════════════════════════════════════════════
-- [7] UTILITIES
-- ════════════════════════════════════════════════════════════
local function W2S(pos)
    if not Camera then return nil, false, 0 end
    local ok, vp, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(pos)
    end)
    if not ok then return nil, false, 0 end
    return Vector2.new(vp.X, vp.Y), (onScreen and vp.Z > 0), vp.Z
end

local function dist3(a, b)
    return (a - b).Magnitude
end

local function notify(title, msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = msg,
            Duration = 3,
        })
    end)
end

local function partVelocity(part)
    if not part then return Vector3.new(0, 0, 0) end
    local ok, v = pcall(function() return part.AssemblyLinearVelocity end)
    if ok and v then return v end
    ok, v = pcall(function() return part.Velocity end)
    if ok and v then return v end
    return Vector3.new(0, 0, 0)
end

local function keyCodeFromName(name)
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    if ok and kc then return kc end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- [8] ROLE DETECTION
-- ════════════════════════════════════════════════════════════
local ROLE = { isKiller = false, isSurvivor = true, isAbyss = false, name = "Survivor" }

local function detectMyRole()
    local char = getChar()
    if not char then return end
    if char:FindFirstChild("KillerTag") then
        ROLE.isKiller = true
        ROLE.isSurvivor = false
        ROLE.isAbyss = false
        ROLE.name = "Killer"
    elseif char:FindFirstChild("AbyssTag") or char:FindFirstChild("TheAbyss") then
        ROLE.isKiller = false
        ROLE.isSurvivor = false
        ROLE.isAbyss = true
        ROLE.name = "Abyss"
    else
        ROLE.isKiller = false
        ROLE.isSurvivor = true
        ROLE.isAbyss = false
        ROLE.name = "Survivor"
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    detectMyRole()
end)

task.spawn(function()
    task.wait(2)
    detectMyRole()
end)

-- ════════════════════════════════════════════════════════════
-- [9] VISUAL
-- ════════════════════════════════════════════════════════════
local function applyVisual()
    if not VFX_BACKUP then
        VFX_BACKUP = {
            Ambient     = Lighting.Ambient,
            Outdoor     = Lighting.OutdoorAmbient,
            Brightness  = Lighting.Brightness,
            Shadows     = Lighting.GlobalShadows,
            ShadowSoft  = Lighting.ShadowSoftness,
            FogStart    = Lighting.FogStart,
            FogEnd      = Lighting.FogEnd,
            ClockTime   = Lighting.ClockTime,
            Diffuse     = Lighting.EnvironmentDiffuseScale,
            Specular    = Lighting.EnvironmentSpecularScale,
        }
    end

    if CFG.Fullbright then
        Lighting.Ambient                  = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient           = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness               = CFG.FB_Level
        Lighting.EnvironmentDiffuseScale  = 1
        Lighting.EnvironmentSpecularScale = 1
    end

    if CFG.NoShadow then
        Lighting.GlobalShadows  = false
        Lighting.ShadowSoftness = 0
    end

    if CFG.ForceClock then
        Lighting.ClockTime = CFG.ClockTime
    end

    if CFG.NoFog then
        Lighting.FogStart = 1e9
        Lighting.FogEnd   = 1e9
    end

    if CFG.NoEffects then
        local kids = Lighting:GetChildren()
        for i = 1, #kids do
            local ef = kids[i]
            if ef:IsA("BlurEffect")
            or ef:IsA("ColorCorrectionEffect")
            or ef:IsA("DepthOfFieldEffect")
            or ef:IsA("SunRaysEffect") then
                ef.Enabled = false
            end
        end
    end
end

applyVisual()

-- ════════════════════════════════════════════════════════════
-- [10] DRAWING POOL
-- ════════════════════════════════════════════════════════════
local Pool = { lists = {} }

local function poolAcquire(kind)
    local list = Pool.lists[kind]
    if not list then
        list = {}
        Pool.lists[kind] = list
    end
    for i = 1, #list do
        local d = list[i]
        if d and not d.__used then
            d.__used = true
            return d
        end
    end
    local d = newDrawing(kind)
    if not d then return nil end
    d.__used = true
    list[#list + 1] = d
    return d
end

local function poolBegin()
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do
            list[i].__used = false
        end
    end
end

local function poolEnd()
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do
            local d = list[i]
            if not d.__used and d.Visible then
                d.Visible = false
            end
        end
    end
end

local function flick()
    if not CFG.ESP_Flicker then return 1 end
    return 0.55 + math.abs(math.sin(os.clock() * 28)) * 0.45
end

-- ════════════════════════════════════════════════════════════
-- [11] ESP OBJECT
-- ════════════════════════════════════════════════════════════
local ESP_MAP = {
    { kw = "generator", en = "ESP_Gen",    col = "C_Gen",    lb = "Generator" },
    { kw = "pallet",    en = "ESP_Pallet", col = "C_Pallet", lb = "Pallet"    },
    { kw = "vault",     en = "ESP_Vault",  col = "C_Pallet", lb = "Vault"     },
    { kw = "exit",      en = "ESP_Vault",  col = "C_Pallet", lb = "Exit"      },
    { kw = "chest",     en = "ESP_Chest",  col = "C_Gen",    lb = "Chest"     },
    { kw = "totem",     en = "ESP_Totem",  col = "C_Gen",    lb = "Totem"     },
    { kw = "hatch",     en = "ESP_Hatch",  col = "C_Surv",   lb = "Hatch"     },
    { kw = "abyss",     en = "ESP_Abyss",  col = "C_Abyss",  lb = "Abyss"     },
    { kw = "locker",    en = "ESP_Vault",  col = "C_Pallet", lb = "Locker"    },
    { kw = "hook",      en = "ESP_Vault",  col = "C_Pallet", lb = "Hook"      },
}

local ObjCache    = { items = {} }
local RemoteCache = { list = {} }
local remoteClock = 0

local function refreshObjects()
    local out = {}
    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") then
            local nl = obj.Name:lower()
            for k = 1, #ESP_MAP do
                local e = ESP_MAP[k]
                if nl:find(e.kw, 1, true) then
                    out[#out + 1] = { part = obj, entry = e }
                    break
                end
            end
        end
    end
    ObjCache.items = out
end

local function refreshRemotes()
    local out = {}
    local desc = game:GetDescendants()
    for i = 1, #desc do
        if desc[i]:IsA("RemoteEvent") then
            out[#out + 1] = desc[i]
        end
    end
    RemoteCache.list = out
end

local function findRemotes(keywords)
    local out = {}
    for i = 1, #RemoteCache.list do
        local r = RemoteCache.list[i]
        if r.Parent then
            local nl = r.Name:lower()
            for k = 1, #keywords do
                if nl:find(keywords[k], 1, true) then
                    out[#out + 1] = r
                    break
                end
            end
        end
    end
    return out
end

local function drawHolo(worldPos, color, label, dist)
    local sp, vis, depth = W2S(worldPos)
    if not sp or not vis or depth <= 0 then return end

    local size  = math.clamp(500 / depth, 8, 280)
    local alpha = flick()
    local style = CFG.ESP_Style
    local thick = CFG.ESP_Thick
    local vp    = Camera.ViewportSize

    if style == "box" then
        local sq = poolAcquire("Square")
        if sq then
            sq.Size         = Vector2.new(size, size * 1.75)
            sq.Position     = sp - Vector2.new(size / 2, size * 0.875)
            sq.Color        = color
            sq.Thickness    = thick
            sq.Filled       = false
            sq.Transparency = alpha
            sq.Visible      = true
        end

    elseif style == "corner" then
        local arm = size * 0.28
        local defs = {
            { sp + Vector2.new(-size / 2, -size * 0.875), Vector2.new( arm, 0), Vector2.new(0,  arm) },
            { sp + Vector2.new( size / 2, -size * 0.875), Vector2.new(-arm, 0), Vector2.new(0,  arm) },
            { sp + Vector2.new(-size / 2,  size * 0.875), Vector2.new( arm, 0), Vector2.new(0, -arm) },
            { sp + Vector2.new( size / 2,  size * 0.875), Vector2.new(-arm, 0), Vector2.new(0, -arm) },
        }
        for c = 1, 4 do
            local origin = defs[c][1]
            for k = 2, 3 do
                local ln = poolAcquire("Line")
                if ln then
                    ln.From         = origin
                    ln.To           = origin + defs[c][k]
                    ln.Color        = color
                    ln.Thickness    = thick + 1
                    ln.Transparency = alpha
                    ln.Visible      = true
                end
            end
        end

    elseif style == "tracer" then
        local ln = poolAcquire("Line")
        if ln then
            ln.From         = Vector2.new(vp.X / 2, vp.Y)
            ln.To           = sp
            ln.Color        = color
            ln.Thickness    = thick
            ln.Transparency = alpha
            ln.Visible      = true
        end

    elseif style == "circle" then
        local ci = poolAcquire("Circle")
        if ci then
            ci.Position     = sp
            ci.Radius       = size / 2
            ci.Color        = color
            ci.Thickness    = thick
            ci.Filled       = false
            ci.Transparency = alpha
            ci.Visible      = true
        end
    end

    if CFG.ESP_SnapLine then
        local snap = poolAcquire("Line")
        if snap then
            snap.From         = Vector2.new(vp.X / 2, vp.Y / 2)
            snap.To           = sp
            snap.Color        = color
            snap.Thickness    = 0.5
            snap.Transparency = alpha * 0.35
            snap.Visible      = true
        end
    end

    if CFG.ESP_ShowName or CFG.ESP_ShowDist then
        local txt = poolAcquire("Text")
        if txt then
            local distStr = ""
            if CFG.ESP_ShowDist then
                distStr = " [" .. math.floor(dist) .. "m]"
            end
            txt.Text         = (CFG.ESP_ShowName and label or "") .. distStr
            txt.Position     = sp - Vector2.new(0, size * 0.875 + 15)
            txt.Color        = color
            txt.Size         = 13
            txt.Outline      = true
            txt.Center       = true
            txt.Transparency = alpha
            txt.Visible      = true
        end
    end
end

local function renderESP()
    if not DrawingLib then return end
    if not isInMatch() then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = dist3(hrp.Position, myHRP.Position)
                if d <= CFG.ESP_MaxDist then
                    local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
                    if isK and CFG.ESP_Killer then
                        drawHolo(hrp.Position, CFG.C_Killer, plr.Name, d)
                    elseif (not isK) and CFG.ESP_Survivor then
                        drawHolo(hrp.Position, CFG.C_Surv, plr.Name, d)
                    end
                end
            end
        end
    end

    local items = ObjCache.items
    for i = 1, #items do
        local rec  = items[i]
        local part = rec.part
        if part and part.Parent and CFG[rec.entry.en] then
            local d = dist3(part.Position, myHRP.Position)
            if d <= CFG.ESP_MaxDist then
                drawHolo(part.Position, CFG[rec.entry.col], rec.entry.lb, d)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [12] HUD
-- ════════════════════════════════════════════════════════════
local HUD_LINES = 9
local hudTexts  = {}
local parryHUD  = nil
local pingHUD   = nil
local fovCircle = nil

for i = 1, HUD_LINES do
    local t = newDrawing("Text")
    if t then
        t.Visible = false
        t.Size    = 13
        t.Outline = true
        t.Color   = Color3.fromRGB(170, 200, 240)
        hudTexts[#hudTexts + 1] = t
    end
end

do
    local t = newDrawing("Text")
    if t then
        t.Visible = false
        t.Size    = 16
        t.Outline = true
        t.Center  = true
        parryHUD  = t
    end
end

do
    local t = newDrawing("Text")
    if t then
        t.Visible = false
        t.Size    = 18
        t.Outline = true
        t.Center  = true
        t.Color   = Color3.fromRGB(255, 80, 80)
        pingHUD   = t
    end
end

do
    local c = newDrawing("Circle")
    if c then
        c.Visible      = false
        c.Filled       = false
        c.Thickness    = 1.5
        c.Color        = Color3.fromRGB(255, 255, 255)
        c.Transparency = 0.55
        fovCircle      = c
    end
end

local function updateHUD()
    if not DrawingLib then return end
    local vp = Camera.ViewportSize

    if not isInMatch() then
        for i = 1, #hudTexts do hudTexts[i].Visible = false end
        if parryHUD  then parryHUD.Visible  = false end
        if pingHUD   then pingHUD.Visible   = false end
        if fovCircle then fovCircle.Visible = false end
        return
    end

    local hum   = getHum()
    local hp    = 0
    local maxhp = 0
    if hum then
        hp    = math.floor(hum.Health)
        maxhp = math.floor(hum.MaxHealth)
    end

    local roleColor = Color3.fromRGB(180, 210, 255)
    if ROLE.isKiller   then roleColor = Color3.fromRGB(255, 80, 80)  end
    if ROLE.isSurvivor then roleColor = Color3.fromRGB(80, 255, 140) end
    if ROLE.isAbyss    then roleColor = Color3.fromRGB(180, 80, 255) end

    local lines = {
        "QUANTUM HUB v5.2 | discord.gg/ojailbreaks",
        "Role      : " .. ROLE.name,
        "HP        : " .. hp .. "/" .. maxhp,
        "AutoParry : " .. tostring(CFG.AutoParry) .. "  Fake: " .. tostring(CFG.FakeParryOn),
        "AutoGen   : " .. tostring(CFG.AutoGen)   .. "  Pallet: " .. tostring(CFG.AutoPallet),
        "AutoDuck  : " .. tostring(CFG.AutoDuck)  .. "  Hide: " .. tostring(CFG.AutoHide),
        "ESP       : " .. tostring(CFG.ESP_Killer) .. "  NoClip: " .. tostring(ncActive),
        "Fullbright: " .. tostring(CFG.Fullbright) .. "  NoShadow: " .. tostring(CFG.NoShadow),
        "@oll.fx | absolute ollie",
    }

    local baseX = 10
    local baseY = vp.Y - (HUD_LINES * 17) - 10

    for i = 1, #hudTexts do
        local t = hudTexts[i]
        t.Position = Vector2.new(baseX, baseY + (i - 1) * 17)
        t.Text     = lines[i] or ""
        t.Color    = roleColor
        if i ~= 2 then
            t.Color = Color3.fromRGB(170, 200, 240)
        end
        t.Visible  = true
    end

    if fovCircle then
        if CFG.ShowFOV and CFG.AimOn then
            fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
            fovCircle.Radius   = CFG.AimFOV
            fovCircle.Visible  = true
        else
            fovCircle.Visible = false
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [13] AIM
-- ════════════════════════════════════════════════════════════
local function aimKeyDown()
    if CFG.AimKey == "RMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif CFG.AimKey == "LMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    local kc = keyCodeFromName(CFG.AimKey)
    if kc then return UserInputService:IsKeyDown(kc) end
    return false
end

local function pickTarget()
    if not isInMatch() then return nil end
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best   = nil
    local bestD  = CFG.AimFOV

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if (not CFG.AimKiller) or isK then
                local part = plr.Character:FindFirstChild(CFG.AimBone)
                if not part then
                    part = plr.Character:FindFirstChild("HumanoidRootPart")
                end
                if part then
                    local pred = part.Position
                    pred = pred + partVelocity(part) * (CFG.AimPredict * 0.05)
                    pred = pred + Vector3.new(CFG.AimOffX * 0.01, CFG.AimOffY * 0.01, 0)

                    local sp, vis = W2S(pred)
                    if vis then
                        local d = (sp - center).Magnitude
                        if d < bestD then
                            bestD = d
                            best  = pred
                        end
                    end
                end
            end
        end
    end
    return best
end

local function toolRemotes()
    local char = getChar()
    if not char then return {} end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return {} end
    local out = {}
    local desc = tool:GetDescendants()
    for i = 1, #desc do
        if desc[i]:IsA("RemoteEvent") then
            out[#out + 1] = desc[i]
        end
    end
    return out
end

local function moveMouseToward(worldPos)
    local sp, vis = W2S(worldPos)
    if not sp or not vis then return end
    local mousePos = UserInputService:GetMouseLocation()
    local dx = (sp.X - mousePos.X) / CFG.AimSmooth
    local dy = (sp.Y - mousePos.Y) / CFG.AimSmooth

    if typeof(mousemoverel) == "function" then
        pcall(mousemoverel, dx, dy)
        return
    end
    if syn and syn.mouse_move_relative then
        pcall(syn.mouse_move_relative, dx, dy)
        return
    end

    pcall(function()
        local cf   = Camera.CFrame
        local want = CFrame.lookAt(cf.Position, worldPos)
        Camera.CFrame = cf:Lerp(want, math.clamp(1 / CFG.AimSmooth, 0, 1))
    end)
end

local function silentFire(worldPos)
    local remotes = toolRemotes()
    if #remotes == 0 then
        remotes = findRemotes({ "fire", "attack", "shoot", "hit" })
    end
    for i = 1, #remotes do
        pcall(function() remotes[i]:FireServer(worldPos) end)
    end
end

-- ════════════════════════════════════════════════════════════
-- [14] FLASHLIGHT AIM
-- ════════════════════════════════════════════════════════════
local function renderFlashlight()
    if not CFG.FlashAim or not isInMatch() then return end
    local char = getChar()
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    local myHRP = getHRP()
    if not myHRP then return end

    local best  = nil
    local bestD = math.huge
    local plrs  = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local part = plr.Character:FindFirstChild(CFG.FlashBone)
            if not part then
                part = plr.Character:FindFirstChild("HumanoidRootPart")
            end
            if part then
                local d = dist3(part.Position, myHRP.Position)
                if d < bestD then
                    bestD = d
                    best  = part
                end
            end
        end
    end

    if best then
        local target = best.Position
        if CFG.FlashPred then
            target = target + partVelocity(best) * CFG.FlashStr * 0.05
        end
        pcall(function()
            handle.CFrame = CFrame.lookAt(handle.Position, target)
        end)
    end
end

-- ════════════════════════════════════════════════════════════
-- [15] VEIL
-- ════════════════════════════════════════════════════════════
local function renderVeil()
    if not CFG.VeilOn or not isInMatch() then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local best  = nil
    local bestD = CFG.VeilDist
    local plrs  = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local part = plr.Character:FindFirstChild(CFG.VeilBone)
            if not part then
                part = plr.Character:FindFirstChild("HumanoidRootPart")
            end
            if part then
                local d = dist3(part.Position, myHRP.Position)
                if d <= bestD then
                    bestD = d
                    best  = part
                end
            end
        end
    end

    if best then
        local target = best.Position
        if CFG.VeilPred then
            target = target + partVelocity(best) * CFG.VeilLead * 0.05
        end
        if CFG.VeilFire then
            silentFire(target)
        else
            moveMouseToward(target)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [16] PARRY
-- ════════════════════════════════════════════════════════════
local parryCD     = 0
local fakeParryCD = 0

local function pressKey(key)
    if not VirtualInputManager then return end
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
        end)
        task.wait(0.04)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end)
end

local function findAttacker()
    local myHRP = getHRP()
    if not myHRP then return nil, nil, nil end
    local maxRange = CFG.ParryDist
    if CFG.FakeParryDist > maxRange then
        maxRange = CFG.FakeParryDist
    end

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("KillerTag") then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP then
                local d = dist3(kHRP.Position, myHRP.Position)
                if d <= maxRange then
                    local armed = false

                    if CFG.ParryHitboxName ~= "" then
                        local hitbox = plr.Character:FindFirstChild(CFG.ParryHitboxName, true)
                        if hitbox and hitbox:IsA("BasePart") then
                            armed = true
                        end
                    end

                    if not armed then
                        local anim = plr.Character:FindFirstChildOfClass("Animator")
                        if anim then
                            local ok, tracks = pcall(function()
                                return anim:GetPlayingAnimationTracks()
                            end)
                            if ok and tracks then
                                for t = 1, #tracks do
                                    local tn = tracks[t].Name:lower()
                                    if tn:find("attack", 1, true)
                                    or tn:find("slash", 1, true)
                                    or tn:find("dagger", 1, true) then
                                        armed = true
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if armed then
                        return plr, kHRP, d
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function fireParryRemotes(fakePos)
    local remotes = findRemotes({ "parry", "block", "counter", "dagger" })
    for i = 1, #remotes do
        local r = remotes[i]
        if fakePos then
            pcall(function() r:FireServer(fakePos) end)
        else
            pcall(function() r:FireServer() end)
        end
    end
end

local function runAutoParry()
    if not CFG.AutoParry and not CFG.FakeParryOn then
        if parryHUD then parryHUD.Visible = false end
        return
    end
    if not isInMatch() then return end

    local attacker, attackerHRP, atkDist = findAttacker()

    if parryHUD then
        local vp = Camera.ViewportSize
        parryHUD.Position = Vector2.new(vp.X / 2, vp.Y - 80)
        if attacker and atkDist then
            if CFG.AutoParry then
                parryHUD.Color = Color3.fromRGB(51, 255, 136)
            else
                parryHUD.Color = Color3.fromRGB(255, 200, 50)
            end
            parryHUD.Text    = "[QH] parry armed — " .. math.floor(atkDist) .. "m | " .. CFG.ParryMode
            parryHUD.Visible = true
        else
            parryHUD.Visible = false
        end
    end

    if not attacker or not attackerHRP then return end

    local myHRP = getHRP()
    if not myHRP then return end

    local predPos = attackerHRP.Position
    if CFG.ParryPredict then
        predPos = predPos + partVelocity(attackerHRP) * CFG.ParryLead * 0.016
    end
    local predDist = dist3(predPos, myHRP.Position)

    if CFG.AutoParry then
        if CFG.ParryMode == "auto" or CFG.ParryMode == "both" then
            if predDist <= CFG.ParryDist and os.clock() - parryCD > 0.5 then
                parryCD = os.clock()
                pressKey(CFG.ParryKey)
                pcall(fireParryRemotes, nil)
                notify("Quantum Hub", "auto parry — " .. math.floor(predDist) .. "m")
            end
        end
    end

    if CFG.FakeParryOn then
        if CFG.ParryMode == "fake" or CFG.ParryMode == "both" then
            if predDist <= CFG.FakeParryDist and os.clock() - fakeParryCD > CFG.FakeParryCD then
                fakeParryCD = os.clock()
                pressKey(CFG.ParryKey)
                local jitter = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
                pcall(fireParryRemotes, predPos + jitter)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [17] DUCK
-- ════════════════════════════════════════════════════════════
local duckActive = false

local function runAutoDuck()
    if not CFG.AutoDuck or duckActive or not isInMatch() then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.DuckDist then
                local armed = false

                if CFG.DuckAnim then
                    local anim = plr.Character:FindFirstChildOfClass("Animator")
                    if anim then
                        local ok, tracks = pcall(function()
                            return anim:GetPlayingAnimationTracks()
                        end)
                        if ok and tracks then
                            for t = 1, #tracks do
                                if tracks[t].Name:lower():find(CFG.AbyssSkill:lower(), 1, true) then
                                    armed = true
                                    break
                                end
                            end
                        end
                    end
                end

                if not armed and CFG.DuckHitbox then
                    local desc = plr.Character:GetDescendants()
                    for k = 1, #desc do
                        local nl = desc[k].Name:lower()
                        if nl:find("slash", 1, true)
                        or nl:find("hitbox", 1, true)
                        or nl:find("attack", 1, true) then
                            armed = true
                            break
                        end
                    end
                end

                if armed then
                    duckActive = true
                    local hum = getHum()
                    if hum then hum.Sit = true end
                    task.delay(CFG.DuckDur, function()
                        local h2 = getHum()
                        if h2 then h2.Sit = false end
                        duckActive = false
                    end)
                    return
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [18] PALLET
-- ════════════════════════════════════════════════════════════
local palletCD = 0

local function runAutoPallet()
    if not CFG.AutoPallet or not isInMatch() then return end
    if os.clock() - palletCD < CFG.PalletCD then return end

    local myHRP = getHRP()
    if not myHRP then return end

    local near = false
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if (not CFG.PalletKiller) or isK then
                local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.PalletDist then
                    near = true
                    break
                end
            end
        end
    end
    if not near then return end

    local remotes = findRemotes({ "pallet", "throw" })
    for i = 1, #remotes do
        pcall(function() remotes[i]:FireServer() end)
    end
    palletCD = os.clock()
end

-- ════════════════════════════════════════════════════════════
-- [19] GENERATOR
-- ════════════════════════════════════════════════════════════
local function genDelay()
    local m = CFG.GenMode
    if m == "instant" then return 0.01 end
    if m == "legit"   then return math.random(8, 18) * 0.01 end
    if m == "random"  then return math.random(2, 25) * 0.01 end
    return 0.12
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.AutoGen and isInMatch() then
            local myHRP = getHRP()
            local gens  = {}
            local desc  = workspace:GetDescendants()
            for i = 1, #desc do
                local obj = desc[i]
                if obj:IsA("Model") and obj.Name:lower():find("generator", 1, true) then
                    gens[#gens + 1] = obj
                end
            end
            if myHRP and CFG.GenNearest then
                table.sort(gens, function(a, b)
                    local pa = a:FindFirstChildOfClass("BasePart")
                    local pb = b:FindFirstChildOfClass("BasePart")
                    if not pa or not pb then return false end
                    return dist3(pa.Position, myHRP.Position) < dist3(pb.Position, myHRP.Position)
                end)
            end
            for i = 1, #gens do
                task.spawn(function()
                    task.wait(genDelay())
                    local r = gens[i]:FindFirstChild("Repair")
                    if not r then
                        r = gens[i]:FindFirstChildOfClass("RemoteEvent")
                    end
                    if r and r:IsA("RemoteEvent") then
                        pcall(function() r:FireServer() end)
                    end
                end)
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [20] CAMERA
-- ════════════════════════════════════════════════════════════
local camLerp = Vector3.new(0, 0, 0)

local function renderCamera(dt)
    if not CFG.CamOn then return end
    if not isInMatch() then
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
        return
    end
    if not CFG.DBDCam then
        Camera.FieldOfView = CFG.CamFOV
        return
    end
    local hrp = getHRP()
    if not hrp then return end

    Camera.CameraType = Enum.CameraType.Scriptable
    local pitch  = math.rad(CFG.CamPitch)
    local offset = Vector3.new(
        0,
        -math.sin(pitch) * CFG.CamDist,
         math.cos(pitch) * CFG.CamDist
    )
    local targetPos = hrp.Position + offset

    if CFG.CamSmooth then
        camLerp   = camLerp:Lerp(targetPos, math.clamp(dt * 8, 0, 1))
        targetPos = camLerp
    end

    Camera.CFrame      = CFrame.lookAt(targetPos, hrp.Position)
    Camera.FieldOfView = CFG.CamFOV
end

-- ════════════════════════════════════════════════════════════
-- [21] AVATAR
-- ════════════════════════════════════════════════════════════
local function copyAvatarByID(userId)
    task.spawn(function()
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if ok and desc then
            local hum = getHum()
            if hum then
                pcall(function() hum:ApplyDescription(desc) end)
                notify("Quantum Hub", "avatar copied — " .. tostring(userId))
            end
        else
            notify("Quantum Hub", "avatar copy failed, bad UserId")
        end
    end)
end

local function copyAvatarByName(username)
    task.spawn(function()
        local ok, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        if ok and userId then
            copyAvatarByID(userId)
        else
            notify("Quantum Hub", "username not found — " .. tostring(username))
        end
    end)
end

if CFG.CopyAvatar then
    if CFG.CopyByName ~= "" then
        copyAvatarByName(CFG.CopyByName)
    elseif CFG.CopyAvatarID ~= 0 then
        copyAvatarByID(CFG.CopyAvatarID)
    end
end

-- ════════════════════════════════════════════════════════════
-- [22] VD FEATURES
-- ════════════════════════════════════════════════════════════
local unhookCD = 0
local healCD   = 0
local sabotCD  = 0
local slashCD  = 0
local pickCD   = 0

local function runAutoUnhook()
    if not CFG.AutoUnhook or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - unhookCD < 2 then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") and obj.Name:lower():find("hook", 1, true) then
            if dist3(obj.Position, myHRP.Position) < CFG.AutoUnhookDist then
                local remotes = findRemotes({ "unhook", "save", "rescue" })
                for k = 1, #remotes do
                    pcall(function() remotes[k]:FireServer() end)
                end
                unhookCD = os.clock()
                notify("Quantum Hub", "auto unhook fired")
                return
            end
        end
    end
end

local function runAutoHeal()
    if not CFG.AutoHeal or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - healCD < 3 then return end
    local hum = getHum()
    if not hum then return end
    if hum.Health < hum.MaxHealth * 0.6 then
        local remotes = findRemotes({ "heal", "mend" })
        for i = 1, #remotes do
            pcall(function() remotes[i]:FireServer() end)
        end
        healCD = os.clock()
    end
end

local hideActive = false

local function runAutoHide()
    if not CFG.AutoHide or not ROLE.isSurvivor or not isInMatch() then return end
    local myHRP = getHRP()
    local hum   = getHum()
    if not myHRP or not hum then return end

    local near = false
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("KillerTag") then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.AutoHideDist then
                near = true
                break
            end
        end
    end

    if near and not hideActive then
        hideActive = true
        hum.Sit = true
    elseif (not near) and hideActive then
        hideActive = false
        hum.Sit = false
    end
end

local function runAutoSabot()
    if not CFG.AutoSabotage or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - sabotCD < CFG.AutoSabotCD then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") and obj.Name:lower():find("hook", 1, true) then
            if dist3(obj.Position, myHRP.Position) < CFG.AutoSabotDist then
                local remotes = findRemotes({ "sabotage", "destroy" })
                if #remotes > 0 then
                    for k = 1, #remotes do
                        pcall(function() remotes[k]:FireServer() end)
                    end
                    sabotCD = os.clock()
                    notify("Quantum Hub", "hook sabotaged")
                    return
                end
            end
        end
    end
end

local function runAbyssSlash()
    if not CFG.AbyssAutoSlash or not ROLE.isAbyss or not isInMatch() then return end
    if os.clock() - slashCD < CFG.AbyssSlashCD then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and not plr.Character:FindFirstChild("KillerTag") then
            local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and dist3(tHRP.Position, myHRP.Position) < CFG.AbyssSlashDist then
                local remotes = findRemotes({ "slash", "skill", "abyss" })
                if #remotes > 0 then
                    for k = 1, #remotes do
                        pcall(function() remotes[k]:FireServer(tHRP.Position) end)
                    end
                    slashCD = os.clock()
                    notify("Quantum Hub", "abyss slash")
                    return
                end
            end
        end
    end
end

local function runKillerPing()
    if not pingHUD then return end
    if not CFG.KillerPingESP or not ROLE.isSurvivor or not isInMatch() then
        pingHUD.Visible = false
        return
    end
    local myHRP = getHRP()
    if not myHRP then return end

    local closest  = nil
    local closestD = math.huge
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("KillerTag") then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP then
                local d = dist3(kHRP.Position, myHRP.Position)
                if d < closestD then
                    closestD = d
                    closest  = plr
                end
            end
        end
    end

    local vp = Camera.ViewportSize
    pingHUD.Position = Vector2.new(vp.X / 2, 50)

    if closest and closestD < CFG.KillerPingDist then
        pingHUD.Text         = "KILLER " .. math.floor(closestD) .. "m — " .. closest.Name
        pingHUD.Transparency = 0.6 + math.abs(math.sin(os.clock() * 6)) * 0.4
        pingHUD.Visible      = true
    else
        pingHUD.Visible = false
    end
end

local function runAutoPick()
    if not CFG.AutoPickItem or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - pickCD < 1 then return end
    local myHRP = getHRP()
    if not myHRP then return end

    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") then
            local nl = obj.Name:lower()
            if nl:find("item", 1, true) or nl:find("pickup", 1, true) then
                if dist3(obj.Position, myHRP.Position) < CFG.AutoPickDist then
                    local remotes = findRemotes({ "pickup", "take", "item" })
                    for k = 1, #remotes do
                        pcall(function() remotes[k]:FireServer() end)
                    end
                    pickCD = os.clock()
                    return
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [23] MOVEMENT
-- ════════════════════════════════════════════════════════════
local function nocollideCharacter(state)
    local char = getChar()
    if not char then return end
    local desc = char:GetDescendants()
    for i = 1, #desc do
        local v = desc[i]
        if v:IsA("BasePart") then
            pcall(function()
                v.CanCollide = (not state)
            end)
        end
    end
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or not isInMatch() then return end
    local hum = getHum()

    if CFG.Moonwalk and inp.KeyCode == CFG.MWKey then
        mwActive = not mwActive
    end

    if CFG.SpeedBoost and inp.KeyCode == CFG.SBKey then
        sbActive = not sbActive
        if hum then
            if sbActive then
                hum.WalkSpeed = CFG.WalkSpeed
            else
                hum.WalkSpeed = 16
            end
        end
    end

    if CFG.NoClip and inp.KeyCode == CFG.NCKey then
        ncActive = not ncActive
        nocollideCharacter(ncActive)
        notify("Quantum Hub", "noclip " .. tostring(ncActive))
    end

    if CFG.KillerSpeedHack and ROLE.isKiller and inp.KeyCode == CFG.KillerSpeedKey then
        killerSPOn = not killerSPOn
        if hum then
            if killerSPOn then
                hum.WalkSpeed = CFG.KillerWS
            else
                hum.WalkSpeed = 20
            end
        end
        notify("Quantum Hub", "killer speed " .. tostring(killerSPOn))
    end
end)

-- ════════════════════════════════════════════════════════════
-- [24] MISC
-- ════════════════════════════════════════════════════════════
if CFG.AntiAFK then
    LP.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function tickStamina()
    if not CFG.InfStam or not isInMatch() then return end
    local char = getChar()
    if not char then return end
    local desc = char:GetDescendants()
    for i = 1, #desc do
        local v = desc[i]
        if v:IsA("NumberValue") and v.Name:lower():find("stamin", 1, true) then
            if v.Value < 5 then v.Value = 100 end
        end
    end
end

local function hideNameTag(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local kids = head:GetChildren()
    for i = 1, #kids do
        if kids[i]:IsA("BillboardGui") then
            kids[i].Enabled = false
        end
    end
end

if CFG.InvisName then
    LP.CharacterAdded:Connect(function(c)
        task.wait(1)
        hideNameTag(c)
    end)
    hideNameTag(getChar())
end

-- ════════════════════════════════════════════════════════════
-- [25] RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    if DrawingLib then
        poolBegin()
    end

    local active = isInMatch()

    if active then
        renderESP()
        updateHUD()
        renderFlashlight()
        renderVeil()
        renderCamera(dt)

        if CFG.AimOn and aimKeyDown() then
            local target = pickTarget()
            if target then
                if CFG.SilentAim then
                    silentFire(target)
                else
                    moveMouseToward(target)
                end
            end
        end

        if mwActive and CFG.Moonwalk then
            local hrp = getHRP()
            local hum = getHum()
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    hrp.CFrame = hrp.CFrame
                        * CFrame.new(0, 0, (hum.WalkSpeed or 16) * dt * 2)
                end)
            end
        end

        if ncActive and CFG.NoClip and CFG.NCFly then
            local hrp = getHRP()
            if hrp then
                local dir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(CFG.FlyUp) then
                    dir = dir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(CFG.FlyDown) then
                    dir = dir + Vector3.new(0, -1, 0)
                end
                if dir.Magnitude > 0 then
                    pcall(function()
                        hrp.AssemblyLinearVelocity =
                            hrp.AssemblyLinearVelocity + dir * CFG.NCSpeed * dt * 3
                    end)
                end
            end
        end
    else
        for i = 1, #hudTexts do hudTexts[i].Visible = false end
        if parryHUD  then parryHUD.Visible  = false end
        if pingHUD   then pingHUD.Visible   = false end
        if fovCircle then fovCircle.Visible = false end
    end

    if DrawingLib then
        poolEnd()
    end
end)

-- ════════════════════════════════════════════════════════════
-- [26] LOGIC LOOP — 20 Hz
-- ════════════════════════════════════════════════════════════
local logicAccum = 0
local roleAccum  = 0
local cacheAccum = 0

RunService.Heartbeat:Connect(function(dt)
    logicAccum = logicAccum + dt
    roleAccum  = roleAccum  + dt
    cacheAccum = cacheAccum + dt

    local hz = CFG.ESP_RefreshHz
    if hz < 1 then hz = 1 end
    if cacheAccum >= 1 / hz then
        cacheAccum = 0
        refreshObjects()
        if os.clock() - remoteClock > 2 then
            remoteClock = os.clock()
            refreshRemotes()
        end
    end

    if roleAccum >= 1 then
        roleAccum = 0
        detectMyRole()
    end

    if logicAccum < 0.05 then return end
    logicAccum = 0

    if not isInMatch() then return end

    runAutoParry()
    runAutoDuck()
    runAutoPallet()
    runAutoUnhook()
    runAutoHeal()
    runAutoHide()
    runAutoSabot()
    runAbyssSlash()
    runKillerPing()
    runAutoPick()
    tickStamina()
end)

-- ════════════════════════════════════════════════════════════
-- [27] UNLOAD
-- ════════════════════════════════════════════════════════════
local function unload()
    if VFX_BACKUP then
        pcall(function()
            Lighting.Ambient                  = VFX_BACKUP.Ambient
            Lighting.OutdoorAmbient           = VFX_BACKUP.Outdoor
            Lighting.Brightness               = VFX_BACKUP.Brightness
            Lighting.GlobalShadows            = VFX_BACKUP.Shadows
            Lighting.ShadowSoftness           = VFX_BACKUP.ShadowSoft
            Lighting.FogStart                 = VFX_BACKUP.FogStart
            Lighting.FogEnd                   = VFX_BACKUP.FogEnd
            Lighting.ClockTime                = VFX_BACKUP.ClockTime
            Lighting.EnvironmentDiffuseScale  = VFX_BACKUP.Diffuse
            Lighting.EnvironmentSpecularScale = VFX_BACKUP.Specular
        end)
    end
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do
            pcall(function() list[i]:Remove() end)
        end
    end
    for i = 1, #hudTexts do
        pcall(function() hudTexts[i]:Remove() end)
    end
    if parryHUD  then pcall(function() parryHUD:Remove()  end) end
    if pingHUD   then pcall(function() pingHUD:Remove()   end) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Custom
    end
    notify("Quantum Hub", "unloaded")
end

GENV.QuantumHub.unload = unload

-- ════════════════════════════════════════════════════════════
print("==============================================")
print("  QUANTUM HUB v5.2 — Violence District")
print("  discord.gg/ojailbreaks | @oll.fx")
print("  PlaceId : " .. tostring(game.PlaceId))
if DrawingLib then
    print("  Drawing : ok")
else
    print("  Drawing : MISSING — ESP/HUD disabled, rest runs")
end
if VirtualInputManager then
    print("  VIM     : ok")
else
    print("  VIM     : missing — parry key press disabled")
end
print("==============================================")
