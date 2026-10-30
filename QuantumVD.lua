--[[
    Quantum Hub v6.3 — Violence District
    Toggle = benar-benar on/off. Setiap efek punya revert.
    Debug dump untuk maintenance saat game update.
    discord.gg/ojailbreaks | @oll.fx
]]

-- ════════════════════════════════════════════════════════════
-- [1] SERVICES
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VirtualInputManager = nil
do
    local ok, svc = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and svc then VirtualInputManager = svc end
end

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then Camera = workspace.CurrentCamera end
end)

local CoreGui = nil
do
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then CoreGui = cg end
end

-- ════════════════════════════════════════════════════════════
-- [2] DRAWING PROBE
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
-- [3] CONFIG
-- ════════════════════════════════════════════════════════════
local CFG = {
    -- ESP
    ESP_Killer    = true,  ESP_Survivor = true,  ESP_Gen    = true,
    ESP_Pallet    = true,  ESP_Vault    = true,  ESP_Chest  = false,
    ESP_Totem     = false, ESP_Hatch    = true,  ESP_Abyss  = true,
    ESP_Lobby     = true,  ESP_Style    = "hologram",
    ESP_Thick     = 2,     ESP_MaxDist   = 400,
    ESP_ShowDist  = true,  ESP_ShowName  = true,
    ESP_Flicker   = false, ESP_SnapLine  = false,
    ESP_RefreshHz = 4,
    ESP_Scan      = true,  ESP_Glow   = true, ESP_Filled  = true,
    ESP_Corners   = true,  ESP_Health = true, ESP_Ring    = true,
    ESP_Pulse     = true,  ESP_ScanSpeed = 0.55, ESP_FillAlpha = 0.90,
    C_Killer = Color3.fromRGB(255, 51, 51),
    C_Surv   = Color3.fromRGB(51, 255, 136),
    C_Gen    = Color3.fromRGB(255, 238, 51),
    C_Pallet = Color3.fromRGB(51, 170, 255),
    C_Abyss  = Color3.fromRGB(204, 68, 255),

    -- VISUAL
    Fullbright = true, FB_Level = 8, NoShadow = true,
    NoFog = true, NoEffects = true, ForceClock = false, ClockTime = 14,

    -- AIM
    AimOn = false, SilentAim = false, AimBone = "Head",
    AimFOV = 80, AimSmooth = 6, AimPredict = 3, ShowFOV = true,
    AimKiller = true, AimKey = "RMB", AimOffX = 0, AimOffY = 0,

    -- FLASHLIGHT / VEIL
    FlashAim = false, FlashPred = true, FlashStr = 4, FlashBone = "Head",
    VeilOn = false, VeilPred = true, VeilDist = 30, VeilLead = 5,
    VeilBone = "Head", VeilFire = false,

    -- MOVEMENT
    Moonwalk = false, MWKey = Enum.KeyCode.G,
    SpeedBoost = false, WalkSpeed = 32, SBKey = Enum.KeyCode.X,
    NoClip = false, NCKey = Enum.KeyCode.N, NCSpeed = 50,
    NCFly = false, FlyUp = Enum.KeyCode.Space, FlyDown = Enum.KeyCode.LeftControl,
    KillerSpeedHack = false, KillerWS = 24, KillerSpeedKey = Enum.KeyCode.R,

    -- GEN
    AutoGen = false, GenMode = "legit", GenNearest = true,
    GenRange = 30, GenRefresh = 1.0,

    -- AUTOS
    AutoPallet = false, PalletDist = 8, PalletKiller = true, PalletCD = 3,
    AutoDuck = false, DuckDist = 15, AbyssSkill = "Slash",
    DuckDur = 1.0, DuckAnim = true, DuckHitbox = false,
    AutoParry = false, ParryDist = 10, ParryKey = Enum.KeyCode.F,
    ParryMode = "auto", FakeParryOn = false, FakeParryDist = 15,
    FakeParryCD = 2, ParryPredict = true, ParryLead = 3,
    ParryHitboxName = "DaggerHitbox",

    -- CAMERA
    CamOn = false, CamFOV = 70, DBDCam = false,
    CamPitch = -35, CamDist = 18, CamSmooth = true,

    -- MISC
    AntiAFK = true, InfStam = false, InvisName = false,

    -- VD
    AutoUnhook = false, AutoUnhookDist = 8,
    AutoHeal = false, AutoHealDist = 5,
    AutoHide = false, AutoHideDist = 20,
    AutoSabotage = false, AutoSabotDist = 8, AutoSabotCD = 10,
    KillerPingESP = false, KillerPingDist = 30,
    AbyssAutoSlash = false, AbyssSlashDist = 15, AbyssSlashCD = 3,
    AutoPickItem = false, AutoPickDist = 5,
}

local GENV = _G
do
    local ok, g = pcall(function() return getgenv() end)
    if ok and type(g) == "table" then GENV = g end
end
GENV.QuantumHub = { CFG = CFG, version = "6.3" }

-- ════════════════════════════════════════════════════════════
-- [4] HELPERS
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

local function getOrigin()
    local hrp = getHRP()
    if hrp then return hrp.Position end
    if Camera then return Camera.CFrame.Position end
    return Vector3.new(0, 0, 0)
end

local function isInMatch()
    local char = getChar()
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if workspace:FindFirstChild("GameMap") then return true end
    if workspace:FindFirstChild("Map") then return true end
    if workspace:FindFirstChild("VD_Map") then return true end
    return false
end

local function W2S(pos)
    if not Camera then return nil, false, 0 end
    local ok, vp, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(pos)
    end)
    if not ok then return nil, false, 0 end
    return Vector2.new(vp.X, vp.Y), (onScreen and vp.Z > 0), vp.Z
end

local function dist3(a, b) return (a - b).Magnitude end

local function notify(title, msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = msg, Duration = 3,
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

local function modelPos(inst)
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        local ok, pivot = pcall(function() return inst:GetPivot() end)
        if ok and pivot then return pivot.Position end
        local pp = inst.PrimaryPart
        if pp then return pp.Position end
        local bp = inst:FindFirstChildOfClass("BasePart")
        if bp then return bp.Position end
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- [5] BASELINE STORE — semua revert bersandar di sini
-- ════════════════════════════════════════════════════════════
local Base = {
    walkSpeed  = 16,
    jumpPower  = 50,
    lighting   = nil,
    effects    = {},
    collide    = {},
    billboard  = {},
    stamina    = {},
    cameraSaved = false,
    camFOV     = 70,
}

local function captureBase()
    local hum = getHum()
    if hum then
        Base.walkSpeed = hum.WalkSpeed
        Base.jumpPower = hum.JumpPower
    end
    if not Base.lighting then
        Base.lighting = {
            Ambient    = Lighting.Ambient,
            Outdoor    = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            Shadows    = Lighting.GlobalShadows,
            ShadowSoft = Lighting.ShadowSoftness,
            FogStart   = Lighting.FogStart,
            FogEnd     = Lighting.FogEnd,
            ClockTime  = Lighting.ClockTime,
            Diffuse    = Lighting.EnvironmentDiffuseScale,
            Specular   = Lighting.EnvironmentSpecularScale,
        }
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(1.0)
    Base.collide = {}
    Base.billboard = {}
    captureBase()
end)

captureBase()

-- ════════════════════════════════════════════════════════════
-- [6] ROLE DETECTION — tahan update (tag / attribute / team)
-- ════════════════════════════════════════════════════════════
local function hasMarker(inst, marker)
    if not inst then return false end
    local ok1, child = pcall(function() return inst:FindFirstChild(marker) end)
    if ok1 and child then return true end
    local ok2, attr = pcall(function() return inst:GetAttribute(marker) end)
    if ok2 and attr ~= nil and attr ~= false then return true end
    local lower = marker:lower()
    local ok3, attr2 = pcall(function() return inst:GetAttribute(lower) end)
    if ok3 and attr2 ~= nil and attr2 ~= false then return true end
    return false
end

local KILLER_MARKERS = { "KillerTag", "Killer", "IsKiller", "killer", "RoleKiller" }
local ABYSS_MARKERS  = { "AbyssTag", "TheAbyss", "IsAbyss", "abyss", "RoleAbyss" }

local function roleOf(plr)
    local char = plr.Character
    if char then
        for i = 1, #KILLER_MARKERS do
            if hasMarker(char, KILLER_MARKERS[i]) then return "killer" end
        end
        for i = 1, #ABYSS_MARKERS do
            if hasMarker(char, ABYSS_MARKERS[i]) then return "abyss" end
        end
    end
    for i = 1, #KILLER_MARKERS do
        if hasMarker(plr, KILLER_MARKERS[i]) then return "killer" end
    end
    for i = 1, #ABYSS_MARKERS do
        if hasMarker(plr, ABYSS_MARKERS[i]) then return "abyss" end
    end
    local team = plr.Team
    if team then
        local tn = team.Name:lower()
        if tn:find("killer", 1, true) then return "killer" end
        if tn:find("abyss", 1, true)  then return "abyss"  end
    end
    return "survivor"
end

local ROLE = { isKiller = false, isSurvivor = true, isAbyss = false, name = "Lobby" }

local function detectMyRole()
    local char = getChar()
    if not char then ROLE.name = "Lobby"; return end
    local r = roleOf(LP)
    if r == "killer" then
        ROLE.isKiller, ROLE.isSurvivor, ROLE.isAbyss = true, false, false
        ROLE.name = "Killer"
    elseif r == "abyss" then
        ROLE.isKiller, ROLE.isSurvivor, ROLE.isAbyss = false, false, true
        ROLE.name = "Abyss"
    else
        ROLE.isKiller, ROLE.isSurvivor, ROLE.isAbyss = false, true, false
        ROLE.name = isInMatch() and "Survivor" or "Lobby"
    end
end

task.spawn(function() task.wait(2); detectMyRole() end)

-- ════════════════════════════════════════════════════════════
-- [7] VISUAL SYNC — apply + revert
-- ════════════════════════════════════════════════════════════
local function syncVisual()
    captureBase()
    local B = Base.lighting

    if CFG.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = CFG.FB_Level
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    else
        Lighting.Ambient = B.Ambient
        Lighting.OutdoorAmbient = B.Outdoor
        Lighting.Brightness = B.Brightness
        Lighting.EnvironmentDiffuseScale = B.Diffuse
        Lighting.EnvironmentSpecularScale = B.Specular
    end

    if CFG.NoShadow then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    else
        Lighting.GlobalShadows = B.Shadows
        Lighting.ShadowSoftness = B.ShadowSoft
    end

    if CFG.NoFog then
        Lighting.FogStart = 1e9
        Lighting.FogEnd = 1e9
    else
        Lighting.FogStart = B.FogStart
        Lighting.FogEnd = B.FogEnd
    end

    if CFG.ForceClock then
        Lighting.ClockTime = CFG.ClockTime
    else
        Lighting.ClockTime = B.ClockTime
    end

    if CFG.NoEffects then
        local kids = Lighting:GetChildren()
        for i = 1, #kids do
            local ef = kids[i]
            if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
            or ef:IsA("DepthOfFieldEffect") or ef:IsA("SunRaysEffect") then
                if ef.Enabled then
                    Base.effects[ef] = true
                    ef.Enabled = false
                end
            end
        end
    else
        for ef in pairs(Base.effects) do
            pcall(function() ef.Enabled = true end)
        end
        Base.effects = {}
    end
end

syncVisual()

-- ════════════════════════════════════════════════════════════
-- [8] MOVEMENT SYNC — apply + revert
-- ════════════════════════════════════════════════════════════
local speedWasOn = false

local function syncSpeed()
    local hum = getHum()
    if not hum then return end
    if CFG.KillerSpeedHack and ROLE.isKiller then
        hum.WalkSpeed = CFG.KillerWS
    elseif CFG.SpeedBoost then
        hum.WalkSpeed = CFG.WalkSpeed
    else
        hum.WalkSpeed = Base.walkSpeed
    end
end

local function tickSpeed()
    local on = CFG.SpeedBoost or (CFG.KillerSpeedHack and ROLE.isKiller)
    if on then
        speedWasOn = true
        syncSpeed()
    elseif speedWasOn then
        speedWasOn = false
        local hum = getHum()
        if hum then hum.WalkSpeed = Base.walkSpeed end
    end
end

local ncWasOn = false

local function tickNoClip()
    local char = getChar()
    if not char then return end
    local desc = char:GetDescendants()

    if CFG.NoClip then
        ncWasOn = true
        for i = 1, #desc do
            local v = desc[i]
            if v:IsA("BasePart") then
                if Base.collide[v] == nil then Base.collide[v] = v.CanCollide end
                v.CanCollide = false
            end
        end
    elseif ncWasOn then
        ncWasOn = false
        for i = 1, #desc do
            local v = desc[i]
            if v:IsA("BasePart") then
                local orig = Base.collide[v]
                if orig == nil then orig = true end
                v.CanCollide = orig
            end
        end
        Base.collide = {}
    end
end

local function tickNameTags()
    local char = getChar()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local kids = head:GetChildren()
    for i = 1, #kids do
        local gui = kids[i]
        if gui:IsA("BillboardGui") then
            if Base.billboard[gui] == nil then Base.billboard[gui] = gui.Enabled end
            gui.Enabled = (not CFG.InvisName)
        end
    end
end

local function tickStamina()
    local char = getChar()
    if char then
        local desc = char:GetDescendants()
        for i = 1, #desc do
            local v = desc[i]
            if v:IsA("NumberValue") and v.Name:lower():find("stamin", 1, true) then
                if CFG.InfStam then
                    if Base.stamina[v] == nil then Base.stamina[v] = v.Value end
                    if v.Value < 5 then v.Value = 100 end
                elseif Base.stamina[v] ~= nil then
                    pcall(function() v.Value = Base.stamina[v] end)
                    Base.stamina[v] = nil
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [9] RESTORE ALL
-- ════════════════════════════════════════════════════════════
local function restoreAll()
    -- kill all toggles
    CFG.Fullbright = false
    CFG.NoShadow   = false
    CFG.NoFog      = false
    CFG.NoEffects  = false
    CFG.ForceClock = false
    CFG.SpeedBoost = false
    CFG.KillerSpeedHack = false
    CFG.NoClip     = false
    CFG.NCFly      = false
    CFG.Moonwalk   = false
    CFG.InfStam    = false
    CFG.InvisName  = false
    CFG.CamOn      = false
    CFG.DBDCam     = false
    CFG.AimOn      = false
    CFG.SilentAim  = false
    CFG.FlashAim   = false
    CFG.VeilOn     = false
    CFG.AutoGen    = false
    CFG.AutoPallet = false
    CFG.AutoDuck   = false
    CFG.AutoParry  = false
    CFG.FakeParryOn = false
    CFG.AutoUnhook = false
    CFG.AutoHeal   = false
    CFG.AutoHide   = false
    CFG.AutoSabotage = false
    CFG.AbyssAutoSlash = false
    CFG.AutoPickItem = false
    CFG.KillerPingESP = false
    CFG.ESP_Killer = false
    CFG.ESP_Survivor = false
    CFG.ESP_Abyss = false
    CFG.ESP_Gen = false
    CFG.ESP_Pallet = false
    CFG.ESP_Vault = false
    CFG.ESP_Chest = false
    CFG.ESP_Totem = false
    CFG.ESP_Hatch = false

    syncVisual()

    local hum = getHum()
    if hum then hum.WalkSpeed = Base.walkSpeed end

    local char = getChar()
    if char then
        local desc = char:GetDescendants()
        for i = 1, #desc do
            local v = desc[i]
            if v:IsA("BasePart") then
                v.CanCollide = true
            elseif v:IsA("BillboardGui") then
                v.Enabled = true
            end
        end
    end

    for v in pairs(Base.stamina) do
        pcall(function() v.Value = Base.stamina[v] end)
    end
    Base.stamina = {}
    Base.collide = {}
    Base.billboard = {}

    if Camera then
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom
            Camera.FieldOfView = 70
        end)
    end

    if syncAllToggles then pcall(syncAllToggles) end
    notify("Quantum Hub", "all features restored")
end

GENV.QuantumHub.restoreAll = restoreAll

-- ════════════════════════════════════════════════════════════
-- [10] DRAWING POOL
-- ════════════════════════════════════════════════════════════
local Pool = { lists = {} }

local function poolAcquire(kind)
    local list = Pool.lists[kind]
    if not list then list = {}; Pool.lists[kind] = list end
    for i = 1, #list do
        local d = list[i]
        if d and not d.__used then d.__used = true; return d end
    end
    local d = newDrawing(kind)
    if not d then return nil end
    d.__used = true
    list[#list + 1] = d
    return d
end

local function poolBegin()
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do list[i].__used = false end
    end
end

local function poolEnd()
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do
            local d = list[i]
            if not d.__used and d.Visible then d.Visible = false end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [11] CACHE
-- ════════════════════════════════════════════════════════════
local ESP_MAP = {
    { kw = "generator", en = "ESP_Gen",    col = "C_Gen",    lb = "GEN"    },
    { kw = "generat",   en = "ESP_Gen",    col = "C_Gen",    lb = "GEN"    },
    { kw = "fusebox",   en = "ESP_Gen",    col = "C_Gen",    lb = "FUSE"   },
    { kw = "fuel",      en = "ESP_Gen",    col = "C_Gen",    lb = "FUEL"   },
    { kw = "pallet",    en = "ESP_Pallet", col = "C_Pallet", lb = "PALLET" },
    { kw = "vault",     en = "ESP_Vault",  col = "C_Pallet", lb = "VAULT"  },
    { kw = "exit",      en = "ESP_Vault",  col = "C_Pallet", lb = "EXIT"   },
    { kw = "chest",     en = "ESP_Chest",  col = "C_Gen",    lb = "CHEST"  },
    { kw = "totem",     en = "ESP_Totem",  col = "C_Gen",    lb = "TOTEM"  },
    { kw = "hatch",     en = "ESP_Hatch",  col = "C_Surv",   lb = "HATCH"  },
    { kw = "abyss",     en = "ESP_Abyss",  col = "C_Abyss",  lb = "ABYSS"  },
    { kw = "locker",    en = "ESP_Vault",  col = "C_Pallet", lb = "LOCKER" },
    { kw = "hook",      en = "ESP_Vault",  col = "C_Pallet", lb = "HOOK"   },
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
        if desc[i]:IsA("RemoteEvent") then out[#out + 1] = desc[i] end
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

-- ════════════════════════════════════════════════════════════
-- [12] HOLOGRAM ESP
-- ════════════════════════════════════════════════════════════
local function pulseAlpha()
    if not CFG.ESP_Pulse then return 1 end
    return 0.78 + math.abs(math.sin(os.clock() * 3.4)) * 0.22
end

local function charBox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local head = char:FindFirstChild("Head")
    local topWorld = hrp.Position + Vector3.new(0, 3.2, 0)
    local botWorld = hrp.Position - Vector3.new(0, 3.0, 0)
    if head then topWorld = head.Position + Vector3.new(0, 0.9, 0) end

    local ok1, topV = pcall(function() return Camera:WorldToViewportPoint(topWorld) end)
    local ok2, botV = pcall(function() return Camera:WorldToViewportPoint(botWorld) end)
    local ok3, midV = pcall(function() return Camera:WorldToViewportPoint(hrp.Position) end)
    if not (ok1 and ok2 and ok3) then return nil end
    if topV.Z <= 0 or botV.Z <= 0 then return nil end

    local h = math.abs(botV.Y - topV.Y)
    if h < 12 then h = 12 end
    if h > 1400 then h = 1400 end
    return { x = midV.X, y = (topV.Y + botV.Y) * 0.5, w = h * 0.54, h = h }
end

local function objBox(worldPos)
    local sp, vis, depth = W2S(worldPos)
    if not sp or not vis or depth <= 0 then return nil end
    local size = math.clamp(620 / depth, 16, 260)
    return { x = sp.X, y = sp.Y, w = size, h = size * 1.15 }
end

local function healthColor(pct)
    if pct > 0.5 then return Color3.fromRGB(80, 230, 140) end
    if pct > 0.25 then return Color3.fromRGB(255, 205, 70) end
    return Color3.fromRGB(255, 80, 80)
end

local function renderHolo(cl, color, label, dist, hpPct)
    if not cl then return end
    local x, y, w, h = cl.x, cl.y, cl.w, cl.h
    if h < 10 then h = 10 end
    if w < 6 then w = 6 end
    local L, R = x - w * 0.5, x + w * 0.5
    local TP, BT = y - h * 0.5, y + h * 0.5
    local pa, now = pulseAlpha(), os.clock()

    if CFG.ESP_Filled then
        local f = poolAcquire("Square")
        if f then
            f.Size = Vector2.new(w, h); f.Position = Vector2.new(L, TP)
            f.Color = color; f.Thickness = 1; f.Filled = true
            f.Transparency = CFG.ESP_FillAlpha; f.Visible = true
        end
    end

    if CFG.ESP_Glow then
        local g = poolAcquire("Square")
        if g then
            g.Size = Vector2.new(w + 8, h + 8); g.Position = Vector2.new(L - 4, TP - 4)
            g.Color = color; g.Thickness = 3; g.Filled = false
            g.Transparency = 0.62 * pa; g.Visible = true
        end
    end

    do
        local b = poolAcquire("Square")
        if b then
            b.Size = Vector2.new(w, h); b.Position = Vector2.new(L, TP)
            b.Color = color; b.Thickness = 1.4; b.Filled = false
            b.Transparency = 0; b.Visible = true
        end
    end

    if CFG.ESP_Corners then
        local arm = math.min(w, h) * 0.24
        if arm < 5 then arm = 5 end
        if arm > h * 0.5 then arm = h * 0.5 end
        local segs = {
            { L, TP,  arm, 0 }, { L, TP,  0, arm },
            { R, TP, -arm, 0 }, { R, TP,  0, arm },
            { L, BT,  arm, 0 }, { L, BT,  0, -arm },
            { R, BT, -arm, 0 }, { R, BT,  0, -arm },
        }
        for i = 1, #segs do
            local s = segs[i]
            local ln = poolAcquire("Line")
            if ln then
                ln.From = Vector2.new(s[1], s[2])
                ln.To = Vector2.new(s[1] + s[3], s[2] + s[4])
                ln.Color = color; ln.Thickness = 2
                ln.Transparency = 0.1; ln.Visible = true
            end
        end
    end

    if CFG.ESP_Scan then
        local speed = CFG.ESP_ScanSpeed
        if speed <= 0 then speed = 0.55 end
        local frac = (now * speed) % 1
        local ln = poolAcquire("Line")
        if ln then
            local sy = TP + h * frac
            ln.From = Vector2.new(L, sy); ln.To = Vector2.new(R, sy)
            ln.Color = color; ln.Thickness = 1.5
            ln.Transparency = 0.15; ln.Visible = true
        end
        local ln2 = poolAcquire("Line")
        if ln2 then
            local sy2 = TP + h * ((frac + 0.5) % 1)
            ln2.From = Vector2.new(L, sy2); ln2.To = Vector2.new(R, sy2)
            ln2.Color = color; ln2.Thickness = 1
            ln2.Transparency = 0.55; ln2.Visible = true
        end
    end

    do
        local rails = { { L, TP, L, BT }, { R, TP, R, BT } }
        for i = 1, #rails do
            local rr = rails[i]
            local ln = poolAcquire("Line")
            if ln then
                ln.From = Vector2.new(rr[1], rr[2]); ln.To = Vector2.new(rr[3], rr[4])
                ln.Color = color; ln.Thickness = 1
                ln.Transparency = 0.55; ln.Visible = true
            end
        end
    end

    if CFG.ESP_Health and hpPct then
        local barW, gap = 3, 6
        local bx = L - gap - barW
        local bg = poolAcquire("Square")
        if bg then
            bg.Size = Vector2.new(barW, h); bg.Position = Vector2.new(bx, TP)
            bg.Color = Color3.fromRGB(0,0,0); bg.Thickness = 1
            bg.Filled = true; bg.Transparency = 0.55; bg.Visible = true
        end
        local pct = math.clamp(hpPct, 0, 1)
        local fh = h * pct
        local fg = poolAcquire("Square")
        if fg then
            fg.Size = Vector2.new(barW, fh); fg.Position = Vector2.new(bx, TP + (h - fh))
            fg.Color = healthColor(pct); fg.Thickness = 1
            fg.Filled = true; fg.Transparency = 0; fg.Visible = true
        end
    end

    if CFG.ESP_Ring then
        local ci = poolAcquire("Circle")
        if ci then
            ci.Position = Vector2.new(x, BT); ci.Radius = math.max(w * 0.46, 7)
            ci.Color = color; ci.Thickness = 1.5; ci.Filled = false
            ci.Transparency = 0.45; ci.Visible = true
        end
    end

    do
        local txt = poolAcquire("Text")
        if txt then
            local out = label or ""
            if CFG.ESP_ShowDist and dist then out = out .. "  " .. math.floor(dist) .. "m" end
            txt.Text = out; txt.Position = Vector2.new(x, TP - 15)
            txt.Color = color; txt.Size = 13; txt.Outline = true
            txt.Center = true; txt.Transparency = 0.05; txt.Visible = true
        end
    end

    if CFG.ESP_SnapLine then
        local vp = Camera.ViewportSize
        local snap = poolAcquire("Line")
        if snap then
            snap.From = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            snap.To = Vector2.new(x, y)
            snap.Color = color; snap.Thickness = 1
            snap.Transparency = 0.65; snap.Visible = true
        end
    end
end

local function renderLegacy(cl, color, label, dist)
    if not cl then return end
    local style, thick = CFG.ESP_Style, CFG.ESP_Thick
    local vp = Camera.ViewportSize
    local x, y, w, h = cl.x, cl.y, cl.w, cl.h

    if style == "box" then
        local sq = poolAcquire("Square")
        if sq then
            sq.Size = Vector2.new(w, h)
            sq.Position = Vector2.new(x - w*0.5, y - h*0.5)
            sq.Color = color; sq.Thickness = thick
            sq.Filled = false; sq.Transparency = 0; sq.Visible = true
        end
    elseif style == "corner" then
        local arm = math.min(w, h) * 0.25
        local L, R = x - w*0.5, x + w*0.5
        local TP, BT = y - h*0.5, y + h*0.5
        local segs = {
            { L, TP, arm, 0 }, { L, TP, 0, arm },
            { R, TP, -arm, 0 }, { R, TP, 0, arm },
            { L, BT, arm, 0 }, { L, BT, 0, -arm },
            { R, BT, -arm, 0 }, { R, BT, 0, -arm },
        }
        for i = 1, #segs do
            local s = segs[i]
            local ln = poolAcquire("Line")
            if ln then
                ln.From = Vector2.new(s[1], s[2])
                ln.To = Vector2.new(s[1] + s[3], s[2] + s[4])
                ln.Color = color; ln.Thickness = thick + 1
                ln.Transparency = 0; ln.Visible = true
            end
        end
    elseif style == "tracer" then
        local ln = poolAcquire("Line")
        if ln then
            ln.From = Vector2.new(vp.X*0.5, vp.Y); ln.To = Vector2.new(x, y)
            ln.Color = color; ln.Thickness = thick
            ln.Transparency = 0; ln.Visible = true
        end
    elseif style == "circle" then
        local ci = poolAcquire("Circle")
        if ci then
            ci.Position = Vector2.new(x, y); ci.Radius = w * 0.5
            ci.Color = color; ci.Thickness = thick
            ci.Filled = false; ci.Transparency = 0; ci.Visible = true
        end
    end

    local txt = poolAcquire("Text")
    if txt then
        local out = label or ""
        if CFG.ESP_ShowDist and dist then out = out .. " [" .. math.floor(dist) .. "m]" end
        txt.Text = out; txt.Position = Vector2.new(x, y - h*0.5 - 15)
        txt.Color = color; txt.Size = 13; txt.Outline = true
        txt.Center = true; txt.Transparency = 0; txt.Visible = true
    end
end

local function renderESP()
    if not DrawingLib then return end
    local origin = getOrigin()
    local holo = (CFG.ESP_Style == "hologram")

    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = dist3(hrp.Position, origin)
                if d <= CFG.ESP_MaxDist then
                    local r = roleOf(plr)
                    local color, tag, show
                    if r == "killer" then
                        color, tag, show = CFG.C_Killer, "[KILLER]", CFG.ESP_Killer
                    elseif r == "abyss" then
                        color, tag, show = CFG.C_Abyss, "[ABYSS]", CFG.ESP_Abyss
                    else
                        color, tag, show = CFG.C_Surv, "[SURV]", CFG.ESP_Survivor
                    end
                    if show then
                        local hp = 1
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.MaxHealth > 0 then hp = hum.Health / hum.MaxHealth end
                        local label = plr.Name .. "  " .. tag
                        local box = charBox(plr.Character) or objBox(hrp.Position)
                        if box then
                            if holo then renderHolo(box, color, label, d, hp)
                            else renderLegacy(box, color, label, d) end
                        end
                    end
                end
            end
        end
    end

    if not isInMatch() and not CFG.ESP_Lobby then return end

    local items = ObjCache.items
    for i = 1, #items do
        local rec = items[i]
        local part = rec.part
        if part and part.Parent and CFG[rec.entry.en] then
            local d = dist3(part.Position, origin)
            if d <= CFG.ESP_MaxDist then
                local box = objBox(part.Position)
                if box then
                    local color = CFG[rec.entry.col]
                    if holo then renderHolo(box, color, rec.entry.lb, d, nil)
                    else renderLegacy(box, color, rec.entry.lb, d) end
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [13] HUD
-- ════════════════════════════════════════════════════════════
local HUD_LINES = 9
local hudTexts, parryHUD, pingHUD, fovCircle = {}, nil, nil, nil

for i = 1, HUD_LINES do
    local t = newDrawing("Text")
    if t then
        t.Visible = false; t.Size = 13; t.Outline = true
        t.Color = Color3.fromRGB(170, 200, 240)
        hudTexts[#hudTexts + 1] = t
    end
end
do
    local t = newDrawing("Text")
    if t then t.Visible = false; t.Size = 16; t.Outline = true; t.Center = true; parryHUD = t end
end
do
    local t = newDrawing("Text")
    if t then
        t.Visible = false; t.Size = 18; t.Outline = true; t.Center = true
        t.Color = Color3.fromRGB(255, 80, 80); pingHUD = t
    end
end
do
    local c = newDrawing("Circle")
    if c then
        c.Visible = false; c.Filled = false; c.Thickness = 1.5
        c.Color = Color3.fromRGB(255,255,255); c.Transparency = 0.55; fovCircle = c
    end
end

local function updateHUD()
    if not DrawingLib then return end
    local vp = Camera.ViewportSize
    local hum = getHum()
    local hp, maxhp = 0, 0
    if hum then hp = math.floor(hum.Health); maxhp = math.floor(hum.MaxHealth) end

    local inMatch = isInMatch()
    local roleColor = Color3.fromRGB(180, 210, 255)
    if ROLE.isKiller then roleColor = Color3.fromRGB(255, 80, 80) end
    if ROLE.isSurvivor then roleColor = Color3.fromRGB(80, 255, 140) end
    if ROLE.isAbyss then roleColor = Color3.fromRGB(180, 80, 255) end
    if not inMatch then roleColor = Color3.fromRGB(120, 170, 255) end

    local lines = {
        "QUANTUM HUB v6.3 | discord.gg/ojailbreaks",
        "State    : " .. (inMatch and "MATCH" or "LOBBY"),
        "Role     : " .. ROLE.name .. "  HP: " .. hp .. "/" .. maxhp,
        "Players  : " .. tostring(#Players:GetPlayers()),
        "AutoParry: " .. tostring(CFG.AutoParry) .. "  Gen: " .. tostring(CFG.AutoGen),
        "Pallet   : " .. tostring(CFG.AutoPallet) .. "  Hide: " .. tostring(CFG.AutoHide),
        "ESP      : " .. CFG.ESP_Style .. "  Lobby: " .. tostring(CFG.ESP_Lobby),
        "Speed    : " .. tostring(CFG.SpeedBoost) .. "  Clip: " .. tostring(CFG.NoClip),
        "@oll.fx | absolute ollie",
    }
    local baseX = 10
    local baseY = vp.Y - (HUD_LINES * 17) - 10
    for i = 1, #hudTexts do
        local t = hudTexts[i]
        t.Position = Vector2.new(baseX, baseY + (i-1) * 17)
        t.Text = lines[i] or ""
        t.Color = (i == 2) and roleColor or Color3.fromRGB(170, 200, 240)
        t.Visible = true
    end

    if fovCircle then
        if CFG.ShowFOV and CFG.AimOn and inMatch then
            fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
            fovCircle.Radius = CFG.AimFOV
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [14] AIM
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
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestD = nil, CFG.AimFOV
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local r = roleOf(plr)
            if (not CFG.AimKiller) or r == "killer" then
                local part = plr.Character:FindFirstChild(CFG.AimBone)
                if not part then part = plr.Character:FindFirstChild("HumanoidRootPart") end
                if part then
                    local pred = part.Position + partVelocity(part) * (CFG.AimPredict * 0.05)
                    pred = pred + Vector3.new(CFG.AimOffX * 0.01, CFG.AimOffY * 0.01, 0)
                    local sp, vis = W2S(pred)
                    if vis then
                        local d = (sp - center).Magnitude
                        if d < bestD then bestD = d; best = pred end
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
        if desc[i]:IsA("RemoteEvent") then out[#out + 1] = desc[i] end
    end
    return out
end

local function moveMouseToward(worldPos)
    local sp, vis = W2S(worldPos)
    if not sp or not vis then return end
    local mp = UserInputService:GetMouseLocation()
    local dx = (sp.X - mp.X) / CFG.AimSmooth
    local dy = (sp.Y - mp.Y) / CFG.AimSmooth
    if typeof(mousemoverel) == "function" then pcall(mousemoverel, dx, dy); return end
    if syn and syn.mouse_move_relative then pcall(syn.mouse_move_relative, dx, dy); return end
    pcall(function()
        local cf = Camera.CFrame
        Camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, worldPos), 1 / CFG.AimSmooth)
    end)
end

local function silentFire(worldPos)
    local remotes = toolRemotes()
    if #remotes == 0 then remotes = findRemotes({ "fire", "attack", "shoot", "hit" }) end
    for i = 1, #remotes do pcall(function() remotes[i]:FireServer(worldPos) end) end
end

-- ════════════════════════════════════════════════════════════
-- [15] GENERATOR ENGINE
-- ════════════════════════════════════════════════════════════
local GEN_KEYWORDS = {
    "generator", "generat", "fusebox", "fuel", "repair",
    "machine", "engine", "objective", "task", "fix",
}
local GEN_EXTRA_KEYWORDS = {}

local GenCache, GenClock, GenCooldown = { list = {} }, 0, {}

local GEN_REMOTE_NAMES = {
    "repair", "generator", "gen", "fix", "activate", "interact",
    "complete", "progress", "hold", "charge", "task",
}

local function genKeywordMatch(name)
    local nl = name:lower()
    for i = 1, #GEN_KEYWORDS do
        if nl:find(GEN_KEYWORDS[i], 1, true) then return true end
    end
    for i = 1, #GEN_EXTRA_KEYWORDS do
        if nl:find(GEN_EXTRA_KEYWORDS[i], 1, true) then return true end
    end
    return false
end

local function findGenerators()
    local out, seen = {}, {}
    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder"))
        and not seen[obj] and genKeywordMatch(obj.Name) then
            seen[obj] = true
            out[#out + 1] = obj
        end
    end
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("ProximityPrompt") then
            local nl = obj.Name:lower()
            local act, objt = "", ""
            pcall(function() act = tostring(obj.ActionText):lower() end)
            pcall(function() objt = tostring(obj.ObjectText):lower() end)
            local joined = nl .. " " .. act .. " " .. objt
            for k = 1, #GEN_REMOTE_NAMES do
                if joined:find(GEN_REMOTE_NAMES[k], 1, true) then
                    local root = obj
                    for _ = 1, 4 do
                        if root.Parent and root.Parent ~= workspace then root = root.Parent else break end
                    end
                    if not seen[root] then seen[root] = true; out[#out + 1] = root end
                    break
                end
            end
        end
    end
    GenCache.list = out
end

local function fireGenPrompt(gen)
    local prompt = nil
    if gen:IsA("ProximityPrompt") then prompt = gen
    else
        local ok, p = pcall(function()
            return gen:FindFirstChildWhichIsA("ProximityPrompt", true)
        end)
        if ok then prompt = p end
    end
    if not prompt then return false end
    if type(fireproximityprompt) == "function" then
        return pcall(fireproximityprompt, prompt)
    end
    local done = false
    pcall(function() prompt:InputHoldBegin(); done = true end)
    if done then
        task.delay(prompt.HoldDuration or 0.1, function()
            pcall(function() prompt:InputHoldEnd() end)
        end)
        return true
    end
    return false
end

local function fireGenClick(gen)
    local det = gen:IsA("ClickDetector") and gen or gen:FindFirstChildWhichIsA("ClickDetector", true)
    if not det then return false end
    if type(fireclickdetector) == "function" then return pcall(fireclickdetector, det) end
    return false
end

local function fireGenRemote(gen, myHRP)
    local roots, p, guard = { gen }, gen.Parent, 0
    while p and p ~= workspace and guard < 4 do
        roots[#roots + 1] = p; p = p.Parent; guard = guard + 1
    end
    local sent = false
    for r = 1, #roots do
        local kids = roots[r]:GetDescendants()
        for i = 1, #kids do
            local obj = kids[i]
            if obj:IsA("RemoteEvent") then
                local nl = obj.Name:lower()
                for k = 1, #GEN_REMOTE_NAMES do
                    if nl:find(GEN_REMOTE_NAMES[k], 1, true) then
                        pcall(function() obj:FireServer() end)
                        pcall(function() obj:FireServer(myHRP) end)
                        sent = true; break
                    end
                end
            end
        end
    end
    if not sent then
        local remotes = findRemotes(GEN_REMOTE_NAMES)
        for i = 1, #remotes do pcall(function() remotes[i]:FireServer() end) end
    end
    return sent
end

local function runAutoGen()
    if not CFG.AutoGen then return end
    if os.clock() - GenClock < CFG.GenRefresh then return end
    GenClock = os.clock()
    findGenerators()

    local myHRP = getHRP()
    if not myHRP then return end
    local list = GenCache.list
    if #list == 0 then return end

    if CFG.GenNearest then
        table.sort(list, function(a, b)
            local pa, pb = modelPos(a), modelPos(b)
            if not pa or not pb then return false end
            return dist3(pa, myHRP.Position) < dist3(pb, myHRP.Position)
        end)
    end

    for i = 1, #list do
        local gen = list[i]
        if gen and gen.Parent then
            local pos = modelPos(gen)
            if pos and dist3(pos, myHRP.Position) <= CFG.GenRange then
                local last = GenCooldown[gen]
                if not last or os.clock() - last > 0.6 then
                    GenCooldown[gen] = os.clock()
                    if not fireGenPrompt(gen) then
                        if not fireGenClick(gen) then fireGenRemote(gen, myHRP) end
                    end
                end
                if CFG.GenMode == "legit" then task.wait(math.random(8,18) * 0.01)
                elseif CFG.GenMode == "random" then task.wait(math.random(2,25) * 0.01)
                elseif CFG.GenMode == "normal" then task.wait(0.12) end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [16] DEBUG DUMPS — dipakai saat VD update
-- ════════════════════════════════════════════════════════════
local function dumpRemotes()
    refreshRemotes()
    print("======== QH DUMP: REMOTES (" .. #RemoteCache.list .. ") ========")
    for i = 1, #RemoteCache.list do
        local r = RemoteCache.list[i]
        local path = "?"
        pcall(function() path = r:GetFullName() end)
        print(string.format("  %03d  %s", i, path))
    end
    print("======== end ========")
    notify("Quantum Hub", "remotes dumped: " .. #RemoteCache.list)
end

local function dumpMyCharacter()
    local plr, char = LP, LP.Character
    print("======== QH DUMP: MY CHARACTER ========")
    print("Player name: " .. plr.Name)
    print("UserId     : " .. tostring(plr.UserId))
    print("Team       : " .. tostring(plr.Team and plr.Team.Name or "nil"))
    print("-- Player attributes --")
    if plr then
        for k, v in pairs(plr:GetAttributes()) do print("  " .. tostring(k) .. " = " .. tostring(v)) end
    end
    if char then
        print("-- Character attributes --")
        for k, v in pairs(char:GetAttributes()) do print("  " .. tostring(k) .. " = " .. tostring(v)) end
        print("-- Character children --")
        for _, c in ipairs(char:GetChildren()) do
            print("  " .. c.ClassName .. " : " .. c.Name)
        end
    else
        print("no character")
    end
    print("======== end ========")
end

local function dumpPrompts()
    print("======== QH DUMP: PROXIMITY PROMPTS ========")
    local desc = workspace:GetDescendants()
    local n = 0
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("ProximityPrompt") then
            n = n + 1
            local path, act, objt = "?", "", ""
            pcall(function() path = obj:GetFullName() end)
            pcall(function() act = tostring(obj.ActionText) end)
            pcall(function() objt = tostring(obj.ObjectText) end)
            print(string.format("  %03d  %s", n, path))
            print("       ActionText : " .. act)
            print("       ObjectText : " .. objt)
            print("       HoldDuration: " .. tostring(obj.HoldDuration))
        end
    end
    print("total: " .. n)
    print("======== end ========")
end

local function dumpWorkspaceKeywords()
    print("======== QH DUMP: WORKSPACE KEYWORDS ========")
    local desc = workspace:GetDescendants()
    local n = 0
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local nl = obj.Name:lower()
            if nl:find("gen", 1, true) or nl:find("pallet", 1, true)
            or nl:find("hook", 1, true) or nl:find("hatch", 1, true)
            or nl:find("vault", 1, true) or nl:find("totem", 1, true) then
                n = n + 1
                local path = "?"
                pcall(function() path = obj:GetFullName() end)
                print("  " .. obj.ClassName .. " : " .. path)
            end
        end
    end
    print("total: " .. n)
    print("======== end ========")
end

local function scanGenerators()
    findGenerators()
    print("======== QH SCAN: GENERATORS (" .. #GenCache.list .. ") ========")
    for i = 1, #GenCache.list do
        local g = GenCache.list[i]
        local cls, path = "?", "?"
        pcall(function() cls = g.ClassName end)
        pcall(function() path = g:GetFullName() end)
        print(string.format("  %02d  %s  [%s]", i, path, cls))
        local kids = g:GetDescendants()
        for k = 1, #kids do
            local obj = kids[k]
            if obj:IsA("RemoteEvent") or obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                print("       > " .. obj.ClassName .. " : " .. obj.Name)
            end
        end
    end
    print("======== end ========")
    notify("Quantum Hub", "gen scan: " .. #GenCache.list)
end

GENV.QuantumHub.dump = {
    remotes    = dumpRemotes,
    me         = dumpMyCharacter,
    prompts    = dumpPrompts,
    keywords   = dumpWorkspaceKeywords,
    generators = scanGenerators,
}

-- ════════════════════════════════════════════════════════════
-- [17] AUTOMATION
-- ════════════════════════════════════════════════════════════
local parryCD, fakeParryCD = 0, 0
local duckActive = false
local palletCD, unhookCD, healCD, sabotCD, slashCD, pickCD = 0,0,0,0,0,0
local hideActive = false

local function pressKey(key)
    if not VirtualInputManager then return end
    task.spawn(function()
        pcall(function() VirtualInputManager:SendKeyEvent(true, key, false, game) end)
        task.wait(0.04)
        pcall(function() VirtualInputManager:SendKeyEvent(false, key, false, game) end)
    end)
end

local function findAttacker()
    local myHRP = getHRP()
    if not myHRP then return nil, nil, nil end
    local maxRange = math.max(CFG.ParryDist, CFG.FakeParryDist)
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and roleOf(plr) == "killer" then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP then
                local d = dist3(kHRP.Position, myHRP.Position)
                if d <= maxRange then
                    local armed = false
                    if CFG.ParryHitboxName ~= "" then
                        local hb = plr.Character:FindFirstChild(CFG.ParryHitboxName, true)
                        if hb and hb:IsA("BasePart") then armed = true end
                    end
                    if not armed then
                        local anim = plr.Character:FindFirstChildOfClass("Animator")
                        if anim then
                            local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end)
                            if ok and tracks then
                                for t = 1, #tracks do
                                    local tn = tracks[t].Name:lower()
                                    if tn:find("attack",1,true) or tn:find("slash",1,true)
                                    or tn:find("dagger",1,true) then armed = true; break end
                                end
                            end
                        end
                    end
                    if armed then return plr, kHRP, d end
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
        if fakePos then pcall(function() r:FireServer(fakePos) end)
        else pcall(function() r:FireServer() end) end
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
        parryHUD.Position = Vector2.new(vp.X/2, vp.Y - 80)
        if attacker and atkDist then
            parryHUD.Color = CFG.AutoParry and Color3.fromRGB(51,255,136) or Color3.fromRGB(255,200,50)
            parryHUD.Text = "[QH] parry armed — " .. math.floor(atkDist) .. "m"
            parryHUD.Visible = true
        else parryHUD.Visible = false end
    end
    if not attacker or not attackerHRP then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local predPos = attackerHRP.Position
    if CFG.ParryPredict then predPos = predPos + partVelocity(attackerHRP) * CFG.ParryLead * 0.016 end
    local predDist = dist3(predPos, myHRP.Position)

    if CFG.AutoParry and (CFG.ParryMode == "auto" or CFG.ParryMode == "both") then
        if predDist <= CFG.ParryDist and os.clock() - parryCD > 0.5 then
            parryCD = os.clock(); pressKey(CFG.ParryKey); pcall(fireParryRemotes, nil)
            notify("Quantum Hub", "auto parry — " .. math.floor(predDist) .. "m")
        end
    end
    if CFG.FakeParryOn and (CFG.ParryMode == "fake" or CFG.ParryMode == "both") then
        if predDist <= CFG.FakeParryDist and os.clock() - fakeParryCD > CFG.FakeParryCD then
            fakeParryCD = os.clock(); pressKey(CFG.ParryKey)
            local j = Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            pcall(fireParryRemotes, predPos + j)
        end
    end
end

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
                        local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end)
                        if ok and tracks then
                            for t = 1, #tracks do
                                if tracks[t].Name:lower():find(CFG.AbyssSkill:lower(),1,true) then
                                    armed = true; break
                                end
                            end
                        end
                    end
                end
                if not armed and CFG.DuckHitbox then
                    local desc = plr.Character:GetDescendants()
                    for k = 1, #desc do
                        local nl = desc[k].Name:lower()
                        if nl:find("slash",1,true) or nl:find("hitbox",1,true) then
                            armed = true; break
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
            local r = roleOf(plr)
            if (not CFG.PalletKiller) or r == "killer" then
                local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.PalletDist then
                    near = true; break
                end
            end
        end
    end
    if not near then return end
    local remotes = findRemotes({ "pallet", "throw" })
    for i = 1, #remotes do pcall(function() remotes[i]:FireServer() end) end
    palletCD = os.clock()
end

local function runAutoUnhook()
    if not CFG.AutoUnhook or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - unhookCD < 2 then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") and obj.Name:lower():find("hook",1,true) then
            if dist3(obj.Position, myHRP.Position) < CFG.AutoUnhookDist then
                local remotes = findRemotes({ "unhook", "save", "rescue" })
                for k = 1, #remotes do pcall(function() remotes[k]:FireServer() end) end
                unhookCD = os.clock(); notify("Quantum Hub", "auto unhook"); return
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
        for i = 1, #remotes do pcall(function() remotes[i]:FireServer() end) end
        healCD = os.clock()
    end
end

local function runAutoHide()
    if not CFG.AutoHide or not ROLE.isSurvivor or not isInMatch() then
        local hum = getHum()
        if hum and hideActive then hideActive = false; hum.Sit = false end
        return
    end
    local myHRP = getHRP(); local hum = getHum()
    if not myHRP or not hum then return end
    local near = false
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and roleOf(plr) == "killer" then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.AutoHideDist then
                near = true; break
            end
        end
    end
    if near and not hideActive then hideActive = true; hum.Sit = true
    elseif (not near) and hideActive then hideActive = false; hum.Sit = false end
end

local function runAutoSabot()
    if not CFG.AutoSabotage or not ROLE.isSurvivor or not isInMatch() then return end
    if os.clock() - sabotCD < CFG.AutoSabotCD then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local desc = workspace:GetDescendants()
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") and obj.Name:lower():find("hook",1,true) then
            if dist3(obj.Position, myHRP.Position) < CFG.AutoSabotDist then
                local remotes = findRemotes({ "sabotage", "destroy" })
                if #remotes > 0 then
                    for k = 1, #remotes do pcall(function() remotes[k]:FireServer() end) end
                    sabotCD = os.clock(); notify("Quantum Hub", "hook sabotaged"); return
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
        if plr ~= LP and plr.Character and roleOf(plr) ~= "killer" then
            local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and dist3(tHRP.Position, myHRP.Position) < CFG.AbyssSlashDist then
                local remotes = findRemotes({ "slash", "skill", "abyss" })
                if #remotes > 0 then
                    for k = 1, #remotes do pcall(function() remotes[k]:FireServer(tHRP.Position) end) end
                    slashCD = os.clock(); notify("Quantum Hub", "abyss slash"); return
                end
            end
        end
    end
end

local function runKillerPing()
    if not pingHUD then return end
    if not CFG.KillerPingESP or not ROLE.isSurvivor or not isInMatch() then
        pingHUD.Visible = false; return
    end
    local myHRP = getHRP()
    if not myHRP then return end
    local closest, closestD = nil, math.huge
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and roleOf(plr) == "killer" then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP then
                local d = dist3(kHRP.Position, myHRP.Position)
                if d < closestD then closestD = d; closest = plr end
            end
        end
    end
    local vp = Camera.ViewportSize
    pingHUD.Position = Vector2.new(vp.X/2, 50)
    if closest and closestD < CFG.KillerPingDist then
        pingHUD.Text = "KILLER " .. math.floor(closestD) .. "m — " .. closest.Name
        pingHUD.Transparency = 0.6 + math.abs(math.sin(os.clock() * 6)) * 0.4
        pingHUD.Visible = true
    else pingHUD.Visible = false end
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
            if nl:find("item",1,true) or nl:find("pickup",1,true) then
                if dist3(obj.Position, myHRP.Position) < CFG.AutoPickDist then
                    local remotes = findRemotes({ "pickup", "take", "item" })
                    for k = 1, #remotes do pcall(function() remotes[k]:FireServer() end) end
                    pickCD = os.clock(); return
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [18] INPUT
-- ════════════════════════════════════════════════════════════
local function toggleFlag(key)
    CFG[key] = not CFG[key]
    if syncToggle then pcall(syncToggle, key) end
    return CFG[key]
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == CFG.MWKey and inp.KeyCode ~= nil then
        toggleFlag("Moonwalk")
    end
    if inp.KeyCode == CFG.SBKey then toggleFlag("SpeedBoost") end
    if inp.KeyCode == CFG.NCKey then toggleFlag("NoClip") end
    if inp.KeyCode == CFG.KillerSpeedKey and ROLE.isKiller then
        toggleFlag("KillerSpeedHack")
    end
end)

LP.Idled:Connect(function()
    if not CFG.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ════════════════════════════════════════════════════════════
-- [19] CAMERA
-- ════════════════════════════════════════════════════════════
local camLerp = Vector3.new(0, 0, 0)
local camWasScriptable = false

local function renderCamera(dt)
    if not CFG.CamOn or not CFG.DBDCam or not isInMatch() then
        if camWasScriptable then
            camWasScriptable = false
            pcall(function()
                if Camera.CameraType == Enum.CameraType.Scriptable then
                    Camera.CameraType = Enum.CameraType.Custom
                end
                Camera.FieldOfView = 70
            end)
        elseif CFG.CamOn and not CFG.DBDCam and Camera then
            Camera.FieldOfView = CFG.CamFOV
        end
        return
    end
    local hrp = getHRP()
    if not hrp then return end
    camWasScriptable = true
    Camera.CameraType = Enum.CameraType.Scriptable
    local pitch = math.rad(CFG.CamPitch)
    local offset = Vector3.new(0, -math.sin(pitch) * CFG.CamDist, math.cos(pitch) * CFG.CamDist)
    local targetPos = hrp.Position + offset
    if CFG.CamSmooth then
        camLerp = camLerp:Lerp(targetPos, math.clamp(dt * 8, 0, 1))
        targetPos = camLerp
    end
    Camera.CFrame = CFrame.lookAt(targetPos, hrp.Position)
    Camera.FieldOfView = CFG.CamFOV
end

local function copyAvatarByID(userId)
    task.spawn(function()
        local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
        if ok and desc then
            local hum = getHum()
            if hum then
                pcall(function() hum:ApplyDescription(desc) end)
                notify("Quantum Hub", "avatar copied — " .. tostring(userId))
            end
        else notify("Quantum Hub", "avatar copy failed") end
    end)
end

local function copyAvatarByName(username)
    task.spawn(function()
        local ok, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
        if ok and userId then copyAvatarByID(userId)
        else notify("Quantum Hub", "username not found") end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [20] GUI THEME
-- ════════════════════════════════════════════════════════════
local T = {
    BG = Color3.fromRGB(20,20,26), Panel = Color3.fromRGB(29,29,37),
    Panel2 = Color3.fromRGB(40,40,51), Accent = Color3.fromRGB(150,90,255),
    Accent2 = Color3.fromRGB(90,200,255), Text = Color3.fromRGB(238,238,246),
    Sub = Color3.fromRGB(145,145,162), Red = Color3.fromRGB(255,90,90),
    Stroke = Color3.fromRGB(58,58,74),
}

local function mk(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
    end
    if children then
        for i = 1, #children do children[i].Parent = inst end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, all)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, all); p.PaddingBottom = UDim.new(0, all)
    p.PaddingLeft = UDim.new(0, all); p.PaddingRight = UDim.new(0, all)
    p.Parent = parent
    return p
end

-- ════════════════════════════════════════════════════════════
-- [21] GUI ELEMENTS — registry supaya bisa di-sync
-- ════════════════════════════════════════════════════════════
local ToggleRender = {}
local Elements = {}

function syncToggle(key)
    local fn = ToggleRender[key]
    if fn then fn() end
end

function syncAllToggles()
    for _, fn in pairs(ToggleRender) do pcall(fn) end
end

function Elements.section(parent, text)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Accent2,
        TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text), Parent = row,
    })
    return row
end

function Elements.toggle(parent, text, key, onChange)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,-56,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row,
    })
    local pill = mk("Frame", {
        Size = UDim2.new(0,38,0,20), Position = UDim2.new(1,-38,0.5,-10),
        BackgroundColor3 = T.Panel2, Parent = row,
    })
    corner(pill, 10)
    local dot = mk("Frame", {
        Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,2,0.5,-8),
        BackgroundColor3 = T.Sub, Parent = pill,
    })
    corner(dot, 8)

    local function render()
        local on = CFG[key] and true or false
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and T.Accent or T.Panel2,
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
            BackgroundColor3 = on and Color3.fromRGB(255,255,255) or T.Sub,
        }):Play()
    end
    ToggleRender[key] = render
    render()

    local btn = mk("TextButton", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "",
        ZIndex = 5, Parent = row,
    })
    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        render()
        if onChange then pcall(onChange, CFG[key]) end
    end)
    return row
end

function Elements.slider(parent, text, min, max, key, step, onChange)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,-60,0,18), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row,
    })
    local valLbl = mk("TextLabel", {
        Size = UDim2.new(0,50,0,18), Position = UDim2.new(1,-50,0,0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = T.Accent2,
        TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(CFG[key]), Parent = row,
    })
    local track = mk("Frame", {
        Size = UDim2.new(1,0,0,4), Position = UDim2.new(0,0,0,28),
        BackgroundColor3 = T.Panel2, Parent = row,
    })
    corner(track, 2)
    local fill = mk("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = T.Accent, Parent = track })
    corner(fill, 2)
    local knob = mk("Frame", {
        Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,0,0.5,-6),
        BackgroundColor3 = Color3.fromRGB(255,255,255), Parent = track,
    })
    corner(knob, 6)

    local function refresh()
        local v = CFG[key]
        local a = 0
        if max > min then a = (v - min) / (max - min) end
        a = math.clamp(a, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, -6)
        if step and step >= 1 then valLbl.Text = tostring(math.floor(v))
        else valLbl.Text = string.format("%.2f", v) end
    end
    refresh()

    local dragging = false
    local function apply(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * rel
        if step then v = math.floor(v / step + 0.5) * step end
        CFG[key] = v
        refresh()
        if onChange then pcall(onChange, v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; apply(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then apply(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return row
end

function Elements.cycle(parent, text, key, options, onChange)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,-110,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(0,104,0,24), Position = UDim2.new(1,-104,0.5,-12),
        BackgroundColor3 = T.Panel2, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.Text, Text = tostring(CFG[key]), Parent = row,
    })
    corner(btn, 6)

    local idx = 1
    for i = 1, #options do
        if tostring(options[i]) == tostring(CFG[key]) then idx = i; break end
    end

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        CFG[key] = options[idx]
        btn.Text = tostring(options[idx])
        if onChange then pcall(onChange, options[idx]) end
    end)
    return row
end

function Elements.keybind(parent, text, key, onChange)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,-110,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(0,104,0,24), Position = UDim2.new(1,-104,0.5,-12),
        BackgroundColor3 = T.Panel2, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.Text, Text = CFG[key].Name, Parent = row,
    })
    corner(btn, 6)

    local waiting = false
    btn.MouseButton1Click:Connect(function() waiting = true; btn.Text = "..." end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not waiting or gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CFG[key] = input.KeyCode
            btn.Text = input.KeyCode.Name
            waiting = false
            if onChange then pcall(onChange, input.KeyCode) end
        end
    end)
    return row
end

function Elements.textbox(parent, text, placeholder, onSubmit)
    local row = mk("Frame", { Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1, Parent = parent })
    mk("TextLabel", {
        Size = UDim2.new(1,-150,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row,
    })
    local box = mk("TextBox", {
        Size = UDim2.new(0,144,0,24), Position = UDim2.new(1,-144,0.5,-12),
        BackgroundColor3 = T.Panel2, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.Text, PlaceholderText = placeholder, PlaceholderColor3 = T.Sub,
        Text = "", ClearTextOnFocus = false, Parent = row,
    })
    corner(box, 6)
    box.FocusLost:Connect(function(enter)
        if enter and onSubmit then pcall(onSubmit, box.Text) end
    end)
    return row
end

function Elements.button(parent, text, callback, color)
    local btn = mk("TextButton", {
        Size = UDim2.new(1,0,0,30), BackgroundColor3 = color or T.Accent,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.fromRGB(255,255,255), Text = text, Parent = parent,
    })
    corner(btn, 6)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return btn
end

-- ════════════════════════════════════════════════════════════
-- [22] SCREEN
-- ════════════════════════════════════════════════════════════
local screen = Instance.new("ScreenGui")
screen.Name = "QuantumHubUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 999
screen.Enabled = true

local parented = false
if CoreGui then
    local ok = pcall(function() screen.Parent = CoreGui end)
    if ok and screen.Parent then parented = true end
end
if not parented then
    pcall(function() screen.Parent = LP:WaitForChild("PlayerGui") end)
end

local main = mk("Frame", {
    Size = UDim2.new(0,620,0,430), Position = UDim2.new(0.5,-310,0.5,-215),
    BackgroundColor3 = T.BG, BorderSizePixel = 0, Parent = screen,
})
corner(main, 10)
stroke(main, T.Stroke, 1)

local topbar = mk("Frame", {
    Size = UDim2.new(1,0,0,40), BackgroundColor3 = T.Panel,
    BorderSizePixel = 0, Parent = main,
})
corner(topbar, 10)

mk("TextLabel", {
    Size = UDim2.new(1,-120,1,0), Position = UDim2.new(0,14,0,0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "QUANTUM HUB  v6.3", Parent = topbar,
})

local statusLbl = mk("TextLabel", {
    Size = UDim2.new(0,200,1,0), Position = UDim2.new(1,-310,0,0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Right,
    Text = "LOBBY", Parent = topbar,
})

local function windowBtn(text, xOff)
    local b = mk("TextButton", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,xOff,0.5,-13),
        BackgroundColor3 = T.Panel2, Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = T.Text, Text = text, Parent = topbar,
    })
    corner(b, 6)
    return b
end
local minBtn = windowBtn("–", -62)
local closeBtn = windowBtn("X", -30)

do
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local sidebar = mk("Frame", {
    Size = UDim2.new(0,132,1,-48), Position = UDim2.new(0,0,0,44),
    BackgroundTransparency = 1, Parent = main,
})
pad(sidebar, 8)
mk("UIListLayout", { Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })

local content = mk("Frame", {
    Size = UDim2.new(1,-144,1,-48), Position = UDim2.new(0,138,0,44),
    BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = main,
})
corner(content, 8)

local tabFrames, tabButtons = {}, {}

local function makeTab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1,0,0,32), BackgroundColor3 = T.Panel2,
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "  " .. name, LayoutOrder = order, Parent = sidebar,
    })
    corner(btn, 6)

    local frame = mk("ScrollingFrame", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false, Parent = content,
    })
    mk("UIListLayout", { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
    mk("UIPadding", {
        PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10),
        PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), Parent = frame,
    })

    tabFrames[name] = frame
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, f in pairs(tabFrames) do f.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            if n == name then
                b.BackgroundTransparency = 0; b.TextColor3 = T.Text
                TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.Accent}):Play()
            else
                TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.Panel2}):Play()
                b.BackgroundTransparency = 1; b.TextColor3 = T.Sub
            end
        end
    end)
    return frame
end

local combatTab = makeTab("Combat", 1)
local visualTab = makeTab("Visuals", 2)
local autoTab   = makeTab("Auto", 3)
local moveTab   = makeTab("Movement", 4)
local miscTab   = makeTab("Misc", 5)

-- ════════════════════════════════════════════════════════════
-- [23] TABS CONTENT
-- ════════════════════════════════════════════════════════════
Elements.section(combatTab, "aimbot")
Elements.toggle(combatTab, "Enable Aimbot", "AimOn")
Elements.toggle(combatTab, "Silent Aim", "SilentAim")
Elements.toggle(combatTab, "Target Killer Only", "AimKiller")
Elements.toggle(combatTab, "Show FOV Circle", "ShowFOV")
Elements.keybind(combatTab, "Aim Key", "AimKey")
Elements.cycle(combatTab, "Aim Bone", "AimBone", { "Head","UpperTorso","LowerTorso","HumanoidRootPart" })
Elements.slider(combatTab, "Aim FOV", 10, 300, "AimFOV", 1)
Elements.slider(combatTab, "Aim Smooth", 1, 20, "AimSmooth", 1)
Elements.slider(combatTab, "Aim Predict", 0, 20, "AimPredict", 1)

Elements.section(combatTab, "parry")
Elements.toggle(combatTab, "Auto Parry", "AutoParry")
Elements.toggle(combatTab, "Fake Parry", "FakeParryOn")
Elements.cycle(combatTab, "Parry Mode", "ParryMode", { "auto","fake","both" })
Elements.slider(combatTab, "Parry Distance", 3, 40, "ParryDist", 1)
Elements.slider(combatTab, "Fake Parry Distance", 3, 40, "FakeParryDist", 1)

Elements.section(combatTab, "flashlight / veil")
Elements.toggle(combatTab, "Flashlight Aim", "FlashAim")
Elements.toggle(combatTab, "Veil Silent Aim", "VeilOn")
Elements.toggle(combatTab, "Veil Auto Fire", "VeilFire")
Elements.slider(combatTab, "Veil Distance", 5, 80, "VeilDist", 1)

Elements.section(visualTab, "players")
Elements.toggle(visualTab, "ESP Killer", "ESP_Killer")
Elements.toggle(visualTab, "ESP Survivor", "ESP_Survivor")
Elements.toggle(visualTab, "ESP Abyss", "ESP_Abyss")
Elements.toggle(visualTab, "ESP in Lobby", "ESP_Lobby")
Elements.toggle(visualTab, "Killer Ping", "KillerPingESP")

Elements.section(visualTab, "objects")
Elements.toggle(visualTab, "ESP Generator", "ESP_Gen")
Elements.toggle(visualTab, "ESP Pallet", "ESP_Pallet")
Elements.toggle(visualTab, "ESP Vault / Exit", "ESP_Vault")
Elements.toggle(visualTab, "ESP Chest", "ESP_Chest")
Elements.toggle(visualTab, "ESP Totem", "ESP_Totem")
Elements.toggle(visualTab, "ESP Hatch", "ESP_Hatch")

Elements.section(visualTab, "hologram")
Elements.cycle(visualTab, "Box Style", "ESP_Style", { "hologram","box","corner","tracer","circle" })
Elements.toggle(visualTab, "Translucent Fill", "ESP_Filled")
Elements.toggle(visualTab, "Outer Glow", "ESP_Glow")
Elements.toggle(visualTab, "Corner Brackets", "ESP_Corners")
Elements.toggle(visualTab, "Scanline Sweep", "ESP_Scan")
Elements.toggle(visualTab, "Feet Ring", "ESP_Ring")
Elements.toggle(visualTab, "Health Bar", "ESP_Health")
Elements.toggle(visualTab, "Pulse", "ESP_Pulse")
Elements.slider(visualTab, "Fill Opacity", 0.5, 0.99, "ESP_FillAlpha", 0.01)
Elements.slider(visualTab, "Scan Speed", 0.1, 2.0, "ESP_ScanSpeed", 0.05)

Elements.section(visualTab, "esp detail")
Elements.slider(visualTab, "Thickness", 1, 6, "ESP_Thick", 1)
Elements.slider(visualTab, "Max Distance", 50, 1000, "ESP_MaxDist", 10)
Elements.toggle(visualTab, "Show Name", "ESP_ShowName")
Elements.toggle(visualTab, "Show Distance", "ESP_ShowDist")
Elements.toggle(visualTab, "Snap Line", "ESP_SnapLine")

Elements.section(visualTab, "lighting")
Elements.toggle(visualTab, "Fullbright", "Fullbright", function() syncVisual() end)
Elements.toggle(visualTab, "No Shadow", "NoShadow", function() syncVisual() end)
Elements.toggle(visualTab, "No Fog", "NoFog", function() syncVisual() end)
Elements.toggle(visualTab, "No Effects", "NoEffects", function() syncVisual() end)
Elements.toggle(visualTab, "Force Clock", "ForceClock", function() syncVisual() end)
Elements.slider(visualTab, "Brightness", 1, 20, "FB_Level", 1, function() syncVisual() end)
Elements.slider(visualTab, "Clock Time", 0, 24, "ClockTime", 1, function() syncVisual() end)

Elements.section(autoTab, "generator")
Elements.toggle(autoTab, "Auto Generator", "AutoGen")
Elements.cycle(autoTab, "Gen Mode", "GenMode", { "legit","instant","random","normal" })
Elements.toggle(autoTab, "Nearest First", "GenNearest")
Elements.slider(autoTab, "Gen Range", 5, 60, "GenRange", 1)
Elements.button(autoTab, "Scan Generators", scanGenerators, T.Accent2)

Elements.section(autoTab, "survivor")
Elements.toggle(autoTab, "Auto Pallet", "AutoPallet")
Elements.slider(autoTab, "Pallet Distance", 3, 30, "PalletDist", 1)
Elements.toggle(autoTab, "Auto Unhook", "AutoUnhook")
Elements.slider(autoTab, "Unhook Distance", 3, 30, "AutoUnhookDist", 1)
Elements.toggle(autoTab, "Auto Heal", "AutoHeal")
Elements.toggle(autoTab, "Auto Hide", "AutoHide")
Elements.slider(autoTab, "Hide Distance", 5, 60, "AutoHideDist", 1)
Elements.toggle(autoTab, "Auto Sabotage", "AutoSabotage")
Elements.toggle(autoTab, "Auto Pickup", "AutoPickItem")
Elements.slider(autoTab, "Pickup Distance", 2, 20, "AutoPickDist", 1)

Elements.section(autoTab, "abyss")
Elements.toggle(autoTab, "Auto Duck", "AutoDuck")
Elements.slider(autoTab, "Duck Distance", 5, 40, "DuckDist", 1)
Elements.toggle(autoTab, "Abyss Auto Slash", "AbyssAutoSlash")
Elements.slider(autoTab, "Slash Distance", 5, 40, "AbyssSlashDist", 1)

Elements.section(moveTab, "speed")
Elements.toggle(moveTab, "Speed Boost", "SpeedBoost", function() syncSpeed() end)
Elements.keybind(moveTab, "Speed Key", "SBKey")
Elements.slider(moveTab, "Walk Speed", 16, 200, "WalkSpeed", 1, function() syncSpeed() end)
Elements.toggle(moveTab, "Killer Speed Hack", "KillerSpeedHack", function() syncSpeed() end)
Elements.keybind(moveTab, "Killer Speed Key", "KillerSpeedKey")
Elements.slider(moveTab, "Killer Walk Speed", 20, 200, "KillerWS", 1, function() syncSpeed() end)

Elements.section(moveTab, "noclip")
Elements.toggle(moveTab, "No Clip", "NoClip", function() tickNoClip() end)
Elements.keybind(moveTab, "No Clip Key", "NCKey")
Elements.toggle(moveTab, "No Clip Fly", "NCFly")
Elements.slider(moveTab, "Fly Speed", 10, 300, "NCSpeed", 1)

Elements.section(moveTab, "misc")
Elements.toggle(moveTab, "Moonwalk", "Moonwalk")
Elements.keybind(moveTab, "Moonwalk Key", "MWKey")

Elements.section(miscTab, "presence")
Elements.toggle(miscTab, "Anti AFK", "AntiAFK")
Elements.toggle(miscTab, "Infinite Stamina", "InfStam")
Elements.toggle(miscTab, "Hide Name Tag", "InvisName")

Elements.section(miscTab, "camera")
Elements.toggle(miscTab, "DBD Camera", "CamOn")
Elements.toggle(miscTab, "DBD Camera Style", "DBDCam")
Elements.slider(miscTab, "Camera FOV", 40, 120, "CamFOV", 1)
Elements.slider(miscTab, "Camera Distance", 5, 40, "CamDist", 1)
Elements.slider(miscTab, "Camera Pitch", -80, 0, "CamPitch", 1)

Elements.section(miscTab, "avatar")
Elements.textbox(miscTab, "Copy by Username", "username...", function(txt)
    if txt and txt ~= "" then copyAvatarByName(txt) end
end)
Elements.textbox(miscTab, "Copy by UserId", "123456789", function(txt)
    local id = tonumber(txt)
    if id then copyAvatarByID(id) end
end)

Elements.section(miscTab, "debug")
Elements.button(miscTab, "Dump Remotes", dumpRemotes, T.Accent2)
Elements.button(miscTab, "Dump My Character", dumpMyCharacter, T.Accent2)
Elements.button(miscTab, "Dump Prompts", dumpPrompts, T.Accent2)
Elements.button(miscTab, "Dump Workspace Keywords", dumpWorkspaceKeywords, T.Accent2)

Elements.section(miscTab, "session")
Elements.button(miscTab, "RESTORE EVERYTHING", function() restoreAll() end, T.Red)
Elements.button(miscTab, "Unload Script", function()
    if GENV.QuantumHub and GENV.QuantumHub.unload then GENV.QuantumHub.unload() end
end, T.Red)

-- ════════════════════════════════════════════════════════════
-- [24] OPEN / CLOSE
-- ════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
minBtn.MouseButton1Click:Connect(function() main.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

for n, f in pairs(tabFrames) do f.Visible = (n == "Combat") end
for n, b in pairs(tabButtons) do
    if n == "Combat" then
        b.BackgroundTransparency = 0; b.TextColor3 = T.Text; b.BackgroundColor3 = T.Accent
    else
        b.BackgroundTransparency = 1; b.TextColor3 = T.Sub
    end
end

-- ════════════════════════════════════════════════════════════
-- [25] RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    if DrawingLib then poolBegin() end

    renderESP()
    updateHUD()

    if isInMatch() then
        renderCamera(dt)

        if CFG.AimOn and aimKeyDown() then
            local target = pickTarget()
            if target then
                if CFG.SilentAim then silentFire(target) else moveMouseToward(target) end
            end
        end

        if CFG.Moonwalk then
            local hrp, hum = getHRP(), getHum()
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, (hum.WalkSpeed or 16) * dt * 2)
                end)
            end
        end

        if CFG.NoClip and CFG.NCFly then
            local hrp = getHRP()
            if hrp then
                local dir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(CFG.FlyUp) then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(CFG.FlyDown) then dir = dir + Vector3.new(0,-1,0) end
                if dir.Magnitude > 0 then
                    pcall(function()
                        hrp.AssemblyLinearVelocity =
                            hrp.AssemblyLinearVelocity + dir * CFG.NCSpeed * dt * 3
                    end)
                end
            end
        end
    else
        renderCamera(dt)
        if parryHUD then parryHUD.Visible = false end
        if pingHUD then pingHUD.Visible = false end
    end

    if DrawingLib then poolEnd() end
end)

-- ════════════════════════════════════════════════════════════
-- [26] LOGIC LOOP
-- ════════════════════════════════════════════════════════════
local logicAccum, roleAccum, cacheAccum = 0, 0, 0

RunService.Heartbeat:Connect(function(dt)
    logicAccum = logicAccum + dt
    roleAccum  = roleAccum + dt
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
        if statusLbl then
            statusLbl.Text = (isInMatch() and "MATCH" or "LOBBY")
                .. "  |  " .. tostring(#Players:GetPlayers()) .. "p"
        end
    end

    -- selalu jalan: ini yang bikin toggle off = normal
    tickSpeed()
    tickNoClip()
    tickNameTags()
    tickStamina()

    if logicAccum < 0.05 then return end
    logicAccum = 0

    if not isInMatch() then return end

    runAutoParry()
    runAutoDuck()
    runAutoPallet()
    runAutoGen()
    runAutoUnhook()
    runAutoHeal()
    runAutoHide()
    runAutoSabot()
    runAbyssSlash()
    runKillerPing()
    runAutoPick()
end)

-- ════════════════════════════════════════════════════════════
-- [27] UNLOAD
-- ════════════════════════════════════════════════════════════
local function unload()
    restoreAll()
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do pcall(function() list[i]:Remove() end) end
    end
    for i = 1, #hudTexts do pcall(function() hudTexts[i]:Remove() end) end
    if parryHUD then pcall(function() parryHUD:Remove() end) end
    if pingHUD then pcall(function() pingHUD:Remove() end) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    pcall(function() screen:Destroy() end)
    notify("Quantum Hub", "unloaded")
end

GENV.QuantumHub.unload = unload

print("==============================================")
print("  QUANTUM HUB v6.3 — full toggle/revert")
print("  discord.gg/ojailbreaks | @oll.fx")
print("  RightShift = toggle menu")
print("  PlaceId   : " .. tostring(game.PlaceId))
if DrawingLib then print("  Drawing   : ok") else print("  Drawing   : MISSING") end
print("  Dump: getgenv().QuantumHub.dump")
print("==============================================")
