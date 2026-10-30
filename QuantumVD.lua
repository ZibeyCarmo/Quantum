--[[
    Quantum Hub v6.0 — Violence District
    GUI build — sidebar tabs, toggle switches, sliders, keybinds
    discord.gg/ojailbreaks | @oll.fx
    Executor-safe syntax (no compound assignment, no continue, no Vector3.zero)
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
local TweenService        = game:GetService("TweenService")

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

local CoreGui = nil
do
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then CoreGui = cg end
end

local GuiParent = CoreGui or LP:WaitForChild("PlayerGui")

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
-- [3] STATE
-- ════════════════════════════════════════════════════════════
local mwActive   = false
local sbActive   = false
local ncActive   = false
local killerSPOn = false
local VFX_BACKUP = nil
local menuOpen   = true

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
    -- ESP
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

    -- VISUAL
    Fullbright    = true,
    FB_Level      = 8,
    NoShadow      = true,
    NoFog         = true,
    NoEffects     = true,
    ForceClock    = false,
    ClockTime     = 14,

    -- AIM
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

    -- FLASHLIGHT
    FlashAim      = false,
    FlashPred     = true,
    FlashStr      = 4,
    FlashBone     = "Head",

    -- VEIL
    VeilOn        = false,
    VeilPred      = true,
    VeilDist      = 30,
    VeilLead      = 5,
    VeilBone      = "Head",
    VeilFire      = false,

    -- MOVEMENT
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

    -- GEN
    AutoGen       = false,
    GenMode       = "legit",
    AutoSkill     = true,
    GenNearest    = true,

    -- PALLET
    AutoPallet    = false,
    PalletDist    = 8,
    PalletKiller  = true,
    PalletCD      = 3,

    -- DUCK
    AutoDuck      = false,
    DuckDist      = 15,
    AbyssSkill    = "Slash",
    DuckDur       = 1.0,
    DuckAnim      = true,
    DuckHitbox    = false,

    -- PARRY
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

    -- CAMERA
    CamOn         = false,
    CamFOV        = 70,
    DBDCam        = false,
    CamPitch      = -35,
    CamDist       = 18,
    CamSmooth     = true,

    -- AVATAR
    CopyAvatar    = false,
    CopyAvatarID  = 0,
    CopyByName    = "",

    -- MISC
    AntiAFK       = true,
    InfStam       = false,
    InvisName     = false,

    -- VD
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
GENV.QuantumHub = { CFG = CFG, version = "6.0" }

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

-- ════════════════════════════════════════════════════════════
-- [8] ROLE
-- ════════════════════════════════════════════════════════════
local ROLE = { isKiller = false, isSurvivor = true, isAbyss = false, name = "Survivor" }

local function detectMyRole()
    local char = getChar()
    if not char then return end
    if char:FindFirstChild("KillerTag") then
        ROLE.isKiller = true; ROLE.isSurvivor = false; ROLE.isAbyss = false
        ROLE.name = "Killer"
    elseif char:FindFirstChild("AbyssTag") or char:FindFirstChild("TheAbyss") then
        ROLE.isKiller = false; ROLE.isSurvivor = false; ROLE.isAbyss = true
        ROLE.name = "Abyss"
    else
        ROLE.isKiller = false; ROLE.isSurvivor = true; ROLE.isAbyss = false
        ROLE.name = "Survivor"
    end
end

LP.CharacterAdded:Connect(function() task.wait(1.5); detectMyRole() end)
task.spawn(function() task.wait(2); detectMyRole() end)

-- ════════════════════════════════════════════════════════════
-- [9] VISUAL
-- ════════════════════════════════════════════════════════════
local function applyVisual()
    if not VFX_BACKUP then
        VFX_BACKUP = {
            Ambient = Lighting.Ambient, Outdoor = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness, Shadows = Lighting.GlobalShadows,
            ShadowSoft = Lighting.ShadowSoftness, FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd, ClockTime = Lighting.ClockTime,
            Diffuse = Lighting.EnvironmentDiffuseScale,
            Specular = Lighting.EnvironmentSpecularScale,
        }
    end
    if CFG.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = CFG.FB_Level
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end
    if CFG.NoShadow then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end
    if CFG.ForceClock then Lighting.ClockTime = CFG.ClockTime end
    if CFG.NoFog then Lighting.FogStart = 1e9; Lighting.FogEnd = 1e9 end
    if CFG.NoEffects then
        local kids = Lighting:GetChildren()
        for i = 1, #kids do
            local ef = kids[i]
            if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
            or ef:IsA("DepthOfFieldEffect") or ef:IsA("SunRaysEffect") then
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

local function flick()
    if not CFG.ESP_Flicker then return 1 end
    return 0.55 + math.abs(math.sin(os.clock() * 28)) * 0.45
end

-- ════════════════════════════════════════════════════════════
-- [11] ESP DATA
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
            sq.Size = Vector2.new(size, size * 1.75)
            sq.Position = sp - Vector2.new(size / 2, size * 0.875)
            sq.Color = color; sq.Thickness = thick
            sq.Filled = false; sq.Transparency = alpha; sq.Visible = true
        end
    elseif style == "corner" then
        local arm = size * 0.28
        local defs = {
            { sp + Vector2.new(-size/2, -size*0.875), Vector2.new(arm,0), Vector2.new(0,arm) },
            { sp + Vector2.new( size/2, -size*0.875), Vector2.new(-arm,0), Vector2.new(0,arm) },
            { sp + Vector2.new(-size/2,  size*0.875), Vector2.new(arm,0), Vector2.new(0,-arm) },
            { sp + Vector2.new( size/2,  size*0.875), Vector2.new(-arm,0), Vector2.new(0,-arm) },
        }
        for c = 1, 4 do
            local origin = defs[c][1]
            for k = 2, 3 do
                local ln = poolAcquire("Line")
                if ln then
                    ln.From = origin; ln.To = origin + defs[c][k]
                    ln.Color = color; ln.Thickness = thick + 1
                    ln.Transparency = alpha; ln.Visible = true
                end
            end
        end
    elseif style == "tracer" then
        local ln = poolAcquire("Line")
        if ln then
            ln.From = Vector2.new(vp.X/2, vp.Y); ln.To = sp
            ln.Color = color; ln.Thickness = thick
            ln.Transparency = alpha; ln.Visible = true
        end
    elseif style == "circle" then
        local ci = poolAcquire("Circle")
        if ci then
            ci.Position = sp; ci.Radius = size/2
            ci.Color = color; ci.Thickness = thick
            ci.Filled = false; ci.Transparency = alpha; ci.Visible = true
        end
    end

    if CFG.ESP_SnapLine then
        local snap = poolAcquire("Line")
        if snap then
            snap.From = Vector2.new(vp.X/2, vp.Y/2); snap.To = sp
            snap.Color = color; snap.Thickness = 0.5
            snap.Transparency = alpha * 0.35; snap.Visible = true
        end
    end

    if CFG.ESP_ShowName or CFG.ESP_ShowDist then
        local txt = poolAcquire("Text")
        if txt then
            local ds = ""
            if CFG.ESP_ShowDist then ds = " [" .. math.floor(dist) .. "m]" end
            txt.Text = (CFG.ESP_ShowName and label or "") .. ds
            txt.Position = sp - Vector2.new(0, size * 0.875 + 15)
            txt.Color = color; txt.Size = 13; txt.Outline = true
            txt.Center = true; txt.Transparency = alpha; txt.Visible = true
        end
    end
end

local function renderESP()
    if not DrawingLib or not isInMatch() then return end
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
        local rec = items[i]; local part = rec.part
        if part and part.Parent and CFG[rec.entry.en] then
            local d = dist3(part.Position, myHRP.Position)
            if d <= CFG.ESP_MaxDist then
                drawHolo(part.Position, CFG[rec.entry.col], rec.entry.lb, d)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [12] DRAWING HUD
-- ════════════════════════════════════════════════════════════
local HUD_LINES = 9
local hudTexts  = {}
local parryHUD  = nil
local pingHUD   = nil
local fovCircle = nil

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
    if not isInMatch() then
        for i = 1, #hudTexts do hudTexts[i].Visible = false end
        if parryHUD then parryHUD.Visible = false end
        if pingHUD then pingHUD.Visible = false end
        if fovCircle then fovCircle.Visible = false end
        return
    end
    local hum = getHum()
    local hp, maxhp = 0, 0
    if hum then hp = math.floor(hum.Health); maxhp = math.floor(hum.MaxHealth) end

    local roleColor = Color3.fromRGB(180, 210, 255)
    if ROLE.isKiller then roleColor = Color3.fromRGB(255, 80, 80) end
    if ROLE.isSurvivor then roleColor = Color3.fromRGB(80, 255, 140) end
    if ROLE.isAbyss then roleColor = Color3.fromRGB(180, 80, 255) end

    local lines = {
        "QUANTUM HUB v6.0 | discord.gg/ojailbreaks",
        "Role      : " .. ROLE.name,
        "HP        : " .. hp .. "/" .. maxhp,
        "AutoParry : " .. tostring(CFG.AutoParry) .. "  Fake: " .. tostring(CFG.FakeParryOn),
        "AutoGen   : " .. tostring(CFG.AutoGen) .. "  Pallet: " .. tostring(CFG.AutoPallet),
        "AutoDuck  : " .. tostring(CFG.AutoDuck) .. "  Hide: " .. tostring(CFG.AutoHide),
        "ESP       : " .. tostring(CFG.ESP_Killer) .. "  NoClip: " .. tostring(ncActive),
        "Fullbright: " .. tostring(CFG.Fullbright) .. "  NoShadow: " .. tostring(CFG.NoShadow),
        "@oll.fx | absolute ollie",
    }
    local baseX = 10
    local baseY = vp.Y - (HUD_LINES * 17) - 10
    for i = 1, #hudTexts do
        local t = hudTexts[i]
        t.Position = Vector2.new(baseX, baseY + (i-1) * 17)
        t.Text = lines[i] or ""
        t.Color = Color3.fromRGB(170, 200, 240)
        if i == 2 then t.Color = roleColor end
        t.Visible = true
    end
    if fovCircle then
        if CFG.ShowFOV and CFG.AimOn then
            fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
            fovCircle.Radius = CFG.AimFOV
            fovCircle.Visible = true
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
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local best, bestD = nil, CFG.AimFOV
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if (not CFG.AimKiller) or isK then
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
    if typeof(mousemoverel) == "function" then
        pcall(mousemoverel, dx, dy); return
    end
    if syn and syn.mouse_move_relative then
        pcall(syn.mouse_move_relative, dx, dy); return
    end
    pcall(function()
        local cf = Camera.CFrame
        local want = CFrame.lookAt(cf.Position, worldPos)
        Camera.CFrame = cf:Lerp(want, math.clamp(1 / CFG.AimSmooth, 0, 1))
    end)
end

local function silentFire(worldPos)
    local remotes = toolRemotes()
    if #remotes == 0 then remotes = findRemotes({ "fire", "attack", "shoot", "hit" }) end
    for i = 1, #remotes do
        pcall(function() remotes[i]:FireServer(worldPos) end)
    end
end

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
    local best, bestD = nil, math.huge
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local part = plr.Character:FindFirstChild(CFG.FlashBone)
            if not part then part = plr.Character:FindFirstChild("HumanoidRootPart") end
            if part then
                local d = dist3(part.Position, myHRP.Position)
                if d < bestD then bestD = d; best = part end
            end
        end
    end
    if best then
        local target = best.Position
        if CFG.FlashPred then target = target + partVelocity(best) * CFG.FlashStr * 0.05 end
        pcall(function() handle.CFrame = CFrame.lookAt(handle.Position, target) end)
    end
end

local function renderVeil()
    if not CFG.VeilOn or not isInMatch() then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local best, bestD = nil, CFG.VeilDist
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character then
            local part = plr.Character:FindFirstChild(CFG.VeilBone)
            if not part then part = plr.Character:FindFirstChild("HumanoidRootPart") end
            if part then
                local d = dist3(part.Position, myHRP.Position)
                if d <= bestD then bestD = d; best = part end
            end
        end
    end
    if best then
        local target = best.Position
        if CFG.VeilPred then target = target + partVelocity(best) * CFG.VeilLead * 0.05 end
        if CFG.VeilFire then silentFire(target) else moveMouseToward(target) end
    end
end

-- ════════════════════════════════════════════════════════════
-- [14] AUTOMATION
-- ════════════════════════════════════════════════════════════
local parryCD, fakeParryCD = 0, 0
local duckActive = false
local palletCD, unhookCD, healCD, sabotCD, slashCD, pickCD = 0, 0, 0, 0, 0, 0
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
    local maxRange = CFG.ParryDist
    if CFG.FakeParryDist > maxRange then maxRange = CFG.FakeParryDist end
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
                                    if tn:find("attack",1,true) or tn:find("slash",1,true) or tn:find("dagger",1,true) then
                                        armed = true; break
                                    end
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
            if CFG.AutoParry then parryHUD.Color = Color3.fromRGB(51,255,136)
            else parryHUD.Color = Color3.fromRGB(255,200,50) end
            parryHUD.Text = "[QH] parry armed — " .. math.floor(atkDist) .. "m | " .. CFG.ParryMode
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
                        if nl:find("slash",1,true) or nl:find("hitbox",1,true) or nl:find("attack",1,true) then
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
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if (not CFG.PalletKiller) or isK then
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

local function genDelay()
    local m = CFG.GenMode
    if m == "instant" then return 0.01 end
    if m == "legit" then return math.random(8,18) * 0.01 end
    if m == "random" then return math.random(2,25) * 0.01 end
    return 0.12
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.AutoGen and isInMatch() then
            local myHRP = getHRP()
            local gens = {}
            local desc = workspace:GetDescendants()
            for i = 1, #desc do
                local obj = desc[i]
                if obj:IsA("Model") and obj.Name:lower():find("generator",1,true) then
                    gens[#gens + 1] = obj
                end
            end
            if myHRP and CFG.GenNearest then
                table.sort(gens, function(a,b)
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
                    if not r then r = gens[i]:FindFirstChildOfClass("RemoteEvent") end
                    if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
                end)
            end
        end
    end
end)

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
                unhookCD = os.clock(); notify("Quantum Hub", "auto unhook fired"); return
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
    if not CFG.AutoHide or not ROLE.isSurvivor or not isInMatch() then return end
    local myHRP = getHRP(); local hum = getHum()
    if not myHRP or not hum then return end
    local near = false
    local plrs = Players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("KillerTag") then
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
        if plr ~= LP and plr.Character and not plr.Character:FindFirstChild("KillerTag") then
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
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("KillerTag") then
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

local function nocollideCharacter(state)
    local char = getChar()
    if not char then return end
    local desc = char:GetDescendants()
    for i = 1, #desc do
        local v = desc[i]
        if v:IsA("BasePart") then
            pcall(function() v.CanCollide = (not state) end)
        end
    end
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or not isInMatch() then return end
    local hum = getHum()
    if CFG.Moonwalk and inp.KeyCode == CFG.MWKey then mwActive = not mwActive end
    if CFG.SpeedBoost and inp.KeyCode == CFG.SBKey then
        sbActive = not sbActive
        if hum then
            if sbActive then hum.WalkSpeed = CFG.WalkSpeed else hum.WalkSpeed = 16 end
        end
    end
    if CFG.NoClip and inp.KeyCode == CFG.NCKey then
        ncActive = not ncActive; nocollideCharacter(ncActive)
        notify("Quantum Hub", "noclip " .. tostring(ncActive))
    end
    if CFG.KillerSpeedHack and ROLE.isKiller and inp.KeyCode == CFG.KillerSpeedKey then
        killerSPOn = not killerSPOn
        if hum then
            if killerSPOn then hum.WalkSpeed = CFG.KillerWS else hum.WalkSpeed = 20 end
        end
        notify("Quantum Hub", "killer speed " .. tostring(killerSPOn))
    end
end)

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
        if v:IsA("NumberValue") and v.Name:lower():find("stamin",1,true) then
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
        if kids[i]:IsA("BillboardGui") then kids[i].Enabled = false end
    end
end

if CFG.InvisName then
    LP.CharacterAdded:Connect(function(c) task.wait(1); hideNameTag(c) end)
    hideNameTag(getChar())
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
        else notify("Quantum Hub", "avatar copy failed, bad UserId") end
    end)
end

local function copyAvatarByName(username)
    task.spawn(function()
        local ok, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
        if ok and userId then copyAvatarByID(userId)
        else notify("Quantum Hub", "username not found — " .. tostring(username)) end
    end)
end

local camLerp = Vector3.new(0, 0, 0)

local function renderCamera(dt)
    if not CFG.CamOn then return end
    if not isInMatch() then
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
        return
    end
    if not CFG.DBDCam then Camera.FieldOfView = CFG.CamFOV; return end
    local hrp = getHRP()
    if not hrp then return end
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

-- ════════════════════════════════════════════════════════════
-- [15] GUI THEME + HELPERS
-- ════════════════════════════════════════════════════════════
local T = {
    BG      = Color3.fromRGB(20, 20, 26),
    Panel   = Color3.fromRGB(29, 29, 37),
    Panel2  = Color3.fromRGB(40, 40, 51),
    Accent  = Color3.fromRGB(150, 90, 255),
    Accent2 = Color3.fromRGB(90, 200, 255),
    Text    = Color3.fromRGB(238, 238, 246),
    Sub     = Color3.fromRGB(145, 145, 162),
    Green   = Color3.fromRGB(80, 230, 140),
    Red     = Color3.fromRGB(255, 90, 90),
    Stroke  = Color3.fromRGB(58, 58, 74),
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
    p.PaddingTop = UDim.new(0, all)
    p.PaddingBottom = UDim.new(0, all)
    p.PaddingLeft = UDim.new(0, all)
    p.PaddingRight = UDim.new(0, all)
    p.Parent = parent
    return p
end

-- ════════════════════════════════════════════════════════════
-- [16] GUI ELEMENTS
-- ════════════════════════════════════════════════════════════
local Elements = {}

function Elements.section(parent, text)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = T.Accent2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = string.upper(text),
        Parent = row,
    })
    return row
end

function Elements.toggle(parent, text, key, onChange)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, -56, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        Parent = row,
    })
    local pill = mk("Frame", {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = T.Panel2,
        Parent = row,
    })
    corner(pill, 10)
    local dot = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = T.Sub,
        Parent = pill,
    })
    corner(dot, 8)

    local state = CFG[key] and true or false
    local function render()
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and T.Accent or T.Panel2,
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = state and Color3.fromRGB(255,255,255) or T.Sub,
        }):Play()
    end
    render()

    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = row,
    })
    btn.MouseButton1Click:Connect(function()
        state = not state
        CFG[key] = state
        render()
        if onChange then onChange(state) end
    end)
    return row
end

function Elements.slider(parent, text, min, max, key, step, onChange)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, -60, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        Parent = row,
    })
    local valLbl = mk("TextLabel", {
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = T.Accent2,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(CFG[key]),
        Parent = row,
    })
    local track = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = T.Panel2,
        Parent = row,
    })
    corner(track, 2)
    local fill = mk("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        Parent = track,
    })
    corner(fill, 2)
    local knob = mk("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        Parent = track,
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
        else valLbl.Text = string.format("%.1f", v) end
    end
    refresh()

    local dragging = false
    local function apply(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * rel
        if step then v = math.floor(v / step + 0.5) * step end
        CFG[key] = v
        refresh()
        if onChange then onChange(v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            apply(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            apply(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return row
end

function Elements.cycle(parent, text, key, options, onChange)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 104, 0, 24),
        Position = UDim2.new(1, -104, 0.5, -12),
        BackgroundColor3 = T.Panel2,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.Text,
        Text = tostring(CFG[key]),
        Parent = row,
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
        if onChange then onChange(options[idx]) end
    end)
    return row
end

function Elements.keybind(parent, text, key, onChange)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        Parent = row,
    })
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 104, 0, 24),
        Position = UDim2.new(1, -104, 0.5, -12),
        BackgroundColor3 = T.Panel2,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.Text,
        Text = CFG[key].Name,
        Parent = row,
    })
    corner(btn, 6)

    local waiting = false
    btn.MouseButton1Click:Connect(function()
        waiting = true
        btn.Text = "..."
    end)

    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not waiting then return end
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CFG[key] = input.KeyCode
            btn.Text = input.KeyCode.Name
            waiting = false
            if onChange then onChange(input.KeyCode) end
        end
    end)
    return row
end

function Elements.textbox(parent, text, placeholder, onSubmit)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    mk("TextLabel", {
        Size = UDim2.new(1, -150, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        Parent = row,
    })
    local box = mk("TextBox", {
        Size = UDim2.new(0, 144, 0, 24),
        Position = UDim2.new(1, -144, 0.5, -12),
        BackgroundColor3 = T.Panel2,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.Text,
        PlaceholderText = placeholder,
        PlaceholderColor3 = T.Sub,
        Text = "",
        ClearTextOnFocus = false,
        Parent = row,
    })
    corner(box, 6)
    box.FocusLost:Connect(function(enter)
        if enter and onSubmit then onSubmit(box.Text) end
    end)
    return row
end

function Elements.button(parent, text, callback, color)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = color or T.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255,255,255),
        Text = text,
        Parent = parent,
    })
    corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return btn
end

-- ════════════════════════════════════════════════════════════
-- [17] WINDOW
-- ════════════════════════════════════════════════════════════
local screen = Instance.new("ScreenGui")
screen.Name = "QuantumHubUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 999
screen.Parent = GuiParent

local main = mk("Frame", {
    Size = UDim2.new(0, 620, 0, 430),
    Position = UDim2.new(0.5, -310, 0.5, -215),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    Parent = screen,
})
corner(main, 10)
stroke(main, T.Stroke, 1)

local topbar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Parent = main,
})
corner(topbar, 10)

local titleLbl = mk("TextLabel", {
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "QUANTUM HUB  v6.0",
    Parent = topbar,
})

local statusLbl = mk("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(1, -310, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Right,
    Text = "loading...",
    Parent = topbar,
})

local function windowBtn(text, xOff)
    local b = mk("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, xOff, 0.5, -13),
        BackgroundColor3 = T.Panel2,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = T.Text,
        Text = text,
        Parent = topbar,
    })
    corner(b, 6)
    return b
end

local minBtn = windowBtn("–", -62)
local closeBtn = windowBtn("X", -30)

-- drag
do
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [18] SIDEBAR + TABS
-- ════════════════════════════════════════════════════════════
local sidebar = mk("Frame", {
    Size = UDim2.new(0, 132, 1, -48),
    Position = UDim2.new(0, 0, 0, 44),
    BackgroundTransparency = 1,
    Parent = main,
})
pad(sidebar, 8)

local sideList = mk("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = sidebar,
})

local content = mk("Frame", {
    Size = UDim2.new(1, -144, 1, -48),
    Position = UDim2.new(0, 138, 0, 44),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Parent = main,
})
corner(content, 8)
pad(content, 0)

local tabFrames = {}
local tabButtons = {}
local currentTab = nil

local function makeTab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.Panel2,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = T.Sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "  " .. name,
        LayoutOrder = order,
        Parent = sidebar,
    })
    corner(btn, 6)

    local frame = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = content,
    })
    local layout = mk("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = frame,
    })

    tabFrames[name] = frame
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, f in pairs(tabFrames) do f.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            if n == name then
                b.BackgroundTransparency = 0
                b.TextColor3 = T.Text
                TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.Accent}):Play()
            else
                TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = T.Panel2}):Play()
                b.BackgroundTransparency = 1
                b.TextColor3 = T.Sub
            end
        end
        currentTab = name
    end)

    return frame
end

local combatTab  = makeTab("Combat", 1)
local visualTab  = makeTab("Visuals", 2)
local autoTab    = makeTab("Auto", 3)
local moveTab    = makeTab("Movement", 4)
local miscTab    = makeTab("Misc", 5)

-- ════════════════════════════════════════════════════════════
-- [19] COMBAT TAB
-- ════════════════════════════════════════════════════════════
Elements.section(combatTab, "aimbot")
Elements.toggle(combatTab, "Enable Aimbot", "AimOn")
Elements.toggle(combatTab, "Silent Aim", "SilentAim")
Elements.toggle(combatTab, "Target Killer Only", "AimKiller")
Elements.toggle(combatTab, "Show FOV Circle", "ShowFOV")
Elements.keybind(combatTab, "Aim Key", "AimKey")
Elements.cycle(combatTab, "Aim Bone", "AimBone", {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
})
Elements.slider(combatTab, "Aim FOV", 10, 300, "AimFOV", 1)
Elements.slider(combatTab, "Aim Smooth", 1, 20, "AimSmooth", 1)
Elements.slider(combatTab, "Aim Predict", 0, 20, "AimPredict", 1)

Elements.section(combatTab, "parry")
Elements.toggle(combatTab, "Auto Parry", "AutoParry")
Elements.toggle(combatTab, "Fake Parry", "FakeParryOn")
Elements.cycle(combatTab, "Parry Mode", "ParryMode", { "auto", "fake", "both" })
Elements.slider(combatTab, "Parry Distance", 3, 40, "ParryDist", 1)
Elements.slider(combatTab, "Fake Parry Distance", 3, 40, "FakeParryDist", 1)

Elements.section(combatTab, "flashlight / veil")
Elements.toggle(combatTab, "Flashlight Aim", "FlashAim")
Elements.toggle(combatTab, "Veil Silent Aim", "VeilOn")
Elements.toggle(combatTab, "Veil Auto Fire", "VeilFire")
Elements.slider(combatTab, "Veil Distance", 5, 80, "VeilDist", 1)

-- ════════════════════════════════════════════════════════════
-- [20] VISUALS TAB
-- ════════════════════════════════════════════════════════════
Elements.section(visualTab, "players")
Elements.toggle(visualTab, "ESP Killer", "ESP_Killer")
Elements.toggle(visualTab, "ESP Survivor", "ESP_Survivor")
Elements.toggle(visualTab, "Killer Ping", "KillerPingESP")

Elements.section(visualTab, "objects")
Elements.toggle(visualTab, "ESP Generator", "ESP_Gen")
Elements.toggle(visualTab, "ESP Pallet", "ESP_Pallet")
Elements.toggle(visualTab, "ESP Vault / Exit", "ESP_Vault")
Elements.toggle(visualTab, "ESP Chest", "ESP_Chest")
Elements.toggle(visualTab, "ESP Totem", "ESP_Totem")
Elements.toggle(visualTab, "ESP Hatch", "ESP_Hatch")
Elements.toggle(visualTab, "ESP Abyss", "ESP_Abyss")

Elements.section(visualTab, "esp style")
Elements.cycle(visualTab, "Box Style", "ESP_Style", { "box", "corner", "tracer", "circle" })
Elements.slider(visualTab, "Thickness", 1, 6, "ESP_Thick", 1)
Elements.slider(visualTab, "Max Distance", 50, 1000, "ESP_MaxDist", 10)
Elements.toggle(visualTab, "Show Name", "ESP_ShowName")
Elements.toggle(visualTab, "Show Distance", "ESP_ShowDist")
Elements.toggle(visualTab, "Flicker", "ESP_Flicker")
Elements.toggle(visualTab, "Snap Line", "ESP_SnapLine")

Elements.section(visualTab, "lighting")
Elements.toggle(visualTab, "Fullbright", "Fullbright", function() applyVisual() end)
Elements.toggle(visualTab, "No Shadow", "NoShadow", function() applyVisual() end)
Elements.toggle(visualTab, "No Fog", "NoFog", function() applyVisual() end)
Elements.toggle(visualTab, "Force Clock", "ForceClock", function() applyVisual() end)
Elements.slider(visualTab, "Brightness", 1, 20, "FB_Level", 1, function() applyVisual() end)
Elements.slider(visualTab, "Clock Time", 0, 24, "ClockTime", 1, function() applyVisual() end)

-- ════════════════════════════════════════════════════════════
-- [21] AUTO TAB
-- ════════════════════════════════════════════════════════════
Elements.section(autoTab, "generator")
Elements.toggle(autoTab, "Auto Generator", "AutoGen")
Elements.cycle(autoTab, "Gen Mode", "GenMode", { "legit", "instant", "random", "normal" })
Elements.toggle(autoTab, "Nearest First", "GenNearest")

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

-- ════════════════════════════════════════════════════════════
-- [22] MOVEMENT TAB
-- ════════════════════════════════════════════════════════════
Elements.section(moveTab, "speed")
Elements.toggle(moveTab, "Speed Boost", "SpeedBoost")
Elements.keybind(moveTab, "Speed Key", "SBKey")
Elements.slider(moveTab, "Walk Speed", 16, 200, "WalkSpeed", 1)
Elements.toggle(moveTab, "Killer Speed Hack", "KillerSpeedHack")
Elements.keybind(moveTab, "Killer Speed Key", "KillerSpeedKey")
Elements.slider(moveTab, "Killer Walk Speed", 20, 200, "KillerWS", 1)

Elements.section(moveTab, "noclip")
Elements.toggle(moveTab, "No Clip", "NoClip")
Elements.keybind(moveTab, "No Clip Key", "NCKey")
Elements.toggle(moveTab, "No Clip Fly", "NCFly")
Elements.slider(moveTab, "Fly Speed", 10, 300, "NCSpeed", 1)

Elements.section(moveTab, "misc")
Elements.toggle(moveTab, "Moonwalk", "Moonwalk")
Elements.keybind(moveTab, "Moonwalk Key", "MWKey")

-- ════════════════════════════════════════════════════════════
-- [23] MISC TAB
-- ════════════════════════════════════════════════════════════
Elements.section(miscTab, "presence")
Elements.toggle(miscTab, "Anti AFK", "AntiAFK")
Elements.toggle(miscTab, "Infinite Stamina", "InfStam")
Elements.toggle(miscTab, "Hide Name Tag", "InvisName", function(on)
    if on then hideNameTag(getChar()) end
end)

Elements.section(miscTab, "camera")
Elements.toggle(miscTab, "DBD Camera", "DBDCam", function(on)
    CFG.CamOn = on
end)
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

Elements.section(miscTab, "session")
Elements.button(miscTab, "Unload Script", function()
    if GENV.QuantumHub and GENV.QuantumHub.unload then GENV.QuantumHub.unload() end
end, T.Red)

-- ════════════════════════════════════════════════════════════
-- [24] OPEN / CLOSE
-- ════════════════════════════════════════════════════════════
local function setMenu(open)
    menuOpen = open
    main.Visible = open
end

closeBtn.MouseButton1Click:Connect(function() setMenu(false) end)
minBtn.MouseButton1Click:Connect(function() setMenu(false) end)

local minimizedBar = mk("TextButton", {
    Size = UDim2.new(0, 150, 0, 30),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundColor3 = T.Panel,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = T.Accent,
    Text = "QUANTUM HUB  v6.0",
    Visible = false,
    Parent = screen,
})
corner(minimizedBar, 6)
stroke(minimizedBar, T.Accent, 1)
minimizedBar.MouseButton1Click:Connect(function() setMenu(true) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if main.Visible then
            main.Visible = false
            minimizedBar.Visible = true
        else
            main.Visible = true
            minimizedBar.Visible = false
        end
        menuOpen = main.Visible
    end
end)

-- open default tab
if tabButtons["Combat"] then
    for n, f in pairs(tabFrames) do f.Visible = (n == "Combat") end
    for n, b in pairs(tabButtons) do
        if n == "Combat" then
            b.BackgroundTransparency = 0
            b.TextColor3 = T.Text
            b.BackgroundColor3 = T.Accent
        else
            b.BackgroundTransparency = 1
            b.TextColor3 = T.Sub
        end
    end
    currentTab = "Combat"
end

-- ════════════════════════════════════════════════════════════
-- [25] RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    if DrawingLib then poolBegin() end

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
                if CFG.SilentAim then silentFire(target)
                else moveMouseToward(target) end
            end
        end

        if mwActive and CFG.Moonwalk then
            local hrp = getHRP(); local hum = getHum()
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, (hum.WalkSpeed or 16) * dt * 2)
                end)
            end
        end

        if ncActive and CFG.NoClip and CFG.NCFly then
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
        for i = 1, #hudTexts do hudTexts[i].Visible = false end
        if parryHUD then parryHUD.Visible = false end
        if pingHUD then pingHUD.Visible = false end
        if fovCircle then fovCircle.Visible = false end
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
            statusLbl.Text = "role: " .. ROLE.name .. "  |  in match: " .. tostring(isInMatch())
        end
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
            Lighting.Ambient = VFX_BACKUP.Ambient
            Lighting.OutdoorAmbient = VFX_BACKUP.Outdoor
            Lighting.Brightness = VFX_BACKUP.Brightness
            Lighting.GlobalShadows = VFX_BACKUP.Shadows
            Lighting.ShadowSoftness = VFX_BACKUP.ShadowSoft
            Lighting.FogStart = VFX_BACKUP.FogStart
            Lighting.FogEnd = VFX_BACKUP.FogEnd
            Lighting.ClockTime = VFX_BACKUP.ClockTime
            Lighting.EnvironmentDiffuseScale = VFX_BACKUP.Diffuse
            Lighting.EnvironmentSpecularScale = VFX_BACKUP.Specular
        end)
    end
    for _, list in pairs(Pool.lists) do
        for i = 1, #list do pcall(function() list[i]:Remove() end) end
    end
    for i = 1, #hudTexts do pcall(function() hudTexts[i]:Remove() end) end
    if parryHUD then pcall(function() parryHUD:Remove() end) end
    if pingHUD then pcall(function() pingHUD:Remove() end) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    pcall(function() screen:Destroy() end)
    if Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Custom
    end
    notify("Quantum Hub", "unloaded")
end

GENV.QuantumHub.unload = unload

-- ════════════════════════════════════════════════════════════
print("==============================================")
print("  QUANTUM HUB v6.0 — GUI BUILD")
print("  discord.gg/ojailbreaks | @oll.fx")
print("  RightShift  = toggle menu")
print("  PlaceId     : " .. tostring(game.PlaceId))
if DrawingLib then print("  Drawing     : ok")
else print("  Drawing     : MISSING — ESP/HUD disabled") end
print("==============================================")
