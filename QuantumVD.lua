--[[
╔═══════════════════════════════════════════════════════════════╗
║   ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗   ██╗███╗  ║
║  ██╔═══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██║   ██║████╗ ║
║  ██║   ██║██║   ██║███████║██╔██╗ ██║   ██║   ██║   ██║██╔██╗║
║  ██║▄▄ ██║██║   ██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██║
║  ╚██████╔╝╚██████╔╝██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═║
║   ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝  ║
╠═══════════════════════════════════════════════════════════════╣
║  QUANTUM HUB v4.0 — Violence District Roblox                  ║
║  Discord : discord.gg/ojailbreaks  |  @oll.fx                 ║
║  Executor : Synapse X / Solara / Wave / KRNL / Fluxus         ║
║  Match Guard ON — script tidak aktif di lobby                 ║
╚═══════════════════════════════════════════════════════════════╝

  SARAN API UNTUK REAL EXECUTOR:
  ─────────────────────────────────────────────────────────────
  Synapse X   — paling stabil, support mousemoverel, Drawing,
                syn.request, getgenv, hookfunction, decompile.
                Terbaik untuk silent aim + hook exploit.

  Solara      — second best, API nyaris sama dengan Synapse.
                Support Drawing, mousemoverel, loadstring, syn.*

  Wave        — ringan, support Drawing + mouse functions.
                Cocok untuk ESP + aimbot.

  KRNL        — gratis, support Drawing API, mousemoverel.
                Kadang tidak support hookfunction advanced.

  Fluxus      — gratis mobile/PC, support dasar Drawing.
                Tidak semua syn.* tersedia.

  API PENTING YANG DIPAKAI SCRIPT INI:
  ─────────────────────────────────────────────────────────────
  Drawing API          → render ESP box/text/line di layar
                         (builtin executor, bukan Roblox)
  mousemoverel(x,y)    → gerak mouse untuk smooth aimbot
  Mouse.Hit = CFrame   → silent aim override hit position
  hookfunction()       → intercept & redirect function calls
                         (fake parry, auto parry hook)
  getgenv()            → global env executor untuk share var
  syn.request()        → HTTP request dari executor (Synapse)
  game:HttpGet()       → HTTP request dari Roblox (loader)
  loadstring()         → execute string sebagai Lua code
  pcall(fn)            → protected call, catch error tanpa crash
  task.spawn(fn)       → jalankan function di thread baru
  task.delay(t,fn)     → delayed execution
  RunService.RenderStepped → loop per-frame (60fps)
  RunService.Heartbeat     → physics loop (juga per-frame)
  UserInputService     → deteksi key/mouse input
  Camera:WorldToViewportPoint() → kalkulasi posisi 3D → 2D
  Animator:GetPlayingAnimationTracks() → deteksi animasi aktif
  RemoteEvent:FireServer() → trigger server action
  ─────────────────────────────────────────────────────────────
]]

-- ════════════════════════════════════════════════════════════
-- [1] SERVICES — cache semua di atas, jangan GetService() dalam loop
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ════════════════════════════════════════════════════════════
-- [2] MATCH GUARD — tidak jalan di lobby
-- ════════════════════════════════════════════════════════════
local function isInMatch()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    -- cek keberadaan map folder (update nama sesuai VD)
    return workspace:FindFirstChild("GameMap") ~= nil
        or workspace:FindFirstChild("Map")     ~= nil
        or workspace:FindFirstChild("VD_Map")  ~= nil
        or #Players:GetPlayers() > 1
end

-- ════════════════════════════════════════════════════════════
-- [3] CONFIG — edit semua setting di sini
-- ════════════════════════════════════════════════════════════
local CFG = {
    -- ── ESP ──────────────────────────────────────────────
    ESP_Killer    = true,
    ESP_Survivor  = true,
    ESP_Gen       = true,
    ESP_Pallet    = true,
    ESP_Vault     = true,
    ESP_Chest     = false,
    ESP_Totem     = false,
    ESP_Hatch     = true,
    ESP_Abyss     = true,
    ESP_Style     = "box",   -- "box" | "corner" | "tracer" | "circle" | "skeleton"
    ESP_Thick     = 2,
    ESP_MaxDist   = 400,
    ESP_ShowDist  = true,
    ESP_ShowHP    = false,
    ESP_ShowName  = true,
    ESP_Flicker   = false,
    ESP_SnapLine  = false,
    C_Killer      = Color3.fromRGB(255, 51,  51),
    C_Surv        = Color3.fromRGB(51,  255, 136),
    C_Gen         = Color3.fromRGB(255, 238, 51),
    C_Pallet      = Color3.fromRGB(51,  170, 255),
    C_Abyss       = Color3.fromRGB(204, 68,  255),

    -- ── VISUAL ───────────────────────────────────────────
    Fullbright    = true,
    FB_Level      = 8,
    NoShadow      = true,
    NoFog         = true,
    NoEffects     = true,
    ForceClock    = false,
    ClockTime     = 14,

    -- ── AIMBOT PISTOL ─────────────────────────────────
    AimOn         = false,
    SilentAim     = false,
    AimBone       = "Head",        -- "Head" | "UpperTorso" | "LowerTorso" | "HumanoidRootPart"
    AimFOV        = 80,
    AimSmooth     = 6,
    AimPredict    = 3,
    ShowFOV       = true,
    AimKiller     = true,
    AimKey        = "RMB",         -- "RMB" | "LMB" | "F" | "Q" | "E" | "T"
    AimOffX       = 0,
    AimOffY       = 0,

    -- ── FLASHLIGHT AIMBOT ─────────────────────────────
    FlashAim      = false,
    FlashPred     = true,
    FlashStr      = 4,
    FlashBone     = "Head",

    -- ── VEIL SILENT AIM ──────────────────────────────
    VeilOn        = false,
    VeilPred      = true,
    VeilDist      = 30,            -- studs
    VeilLead      = 5,             -- studs/s lead
    VeilBone      = "Head",
    VeilFire      = false,

    -- ── MOVEMENT ─────────────────────────────────────
    Moonwalk      = false,
    MWKey         = Enum.KeyCode.G,
    SpeedBoost    = false,
    WalkSpeed     = 32,
    SBKey         = Enum.KeyCode.X,

    -- ── NO CLIP + FLY ────────────────────────────────
    NoClip        = false,
    NCKey         = Enum.KeyCode.N,
    NCSpeed       = 50,
    NCFly         = false,
    FlyUp         = Enum.KeyCode.Space,
    FlyDown       = Enum.KeyCode.LeftControl,

    -- ── AUTO GENERATOR ────────────────────────────────
    AutoGen       = false,
    GenMode       = "legit",       -- "instant" | "legit" | "random" | "normal"
    GenSpeed      = 5,
    AutoSkill     = true,
    GenNearest    = true,
    AutoTPGen     = false,

    -- ── AUTO PALLET ───────────────────────────────────
    AutoPallet    = false,
    PalletDist    = 8,             -- studs trigger
    PalletKiller  = true,
    PalletCD      = 3,             -- detik cooldown

    -- ── AUTO DUCK (ABYSS SLASH) ───────────────────────
    AutoDuck      = false,
    DuckDist      = 15,            -- studs dari abyss
    AbyssSkill    = "Slash",       -- nama animasi Abyss
    DuckDur       = 1.0,           -- detik duck
    DuckAnim      = true,
    DuckHitbox    = false,

    -- ── AUTO PARRY DAGGER ─────────────────────────────
    AutoParry     = false,
    ParryDist     = 10,            -- studs jarak trigger parry
    ParryKey      = Enum.KeyCode.F, -- key parry
    ParryMode     = "auto",        -- "auto" | "fake" | "both"
    FakeParryOn   = false,
    FakeParryDist = 15,            -- studs jarak fake parry
    FakeParryCD   = 2,             -- cooldown fake parry (detik)
    ParryPredict  = true,          -- predict posisi attacker
    ParryLead     = 3,             -- lead frames untuk predict
    ParrySkillName = "Dagger",     -- nama skill/tool dagger
    ParryHitboxName = "DaggerHitbox", -- nama hitbox part attacker
    ParryAutoFire  = true,         -- langsung trigger parry action

    -- ── CAMERA ────────────────────────────────────────
    CamOn         = false,
    CamFOV        = 70,
    DBDCam        = false,
    CamPitch      = -35,           -- derajat pitch
    CamDist       = 18,
    CamLockY      = false,
    CamSmooth     = true,
    CamMode       = "Custom",

    -- ── COPY AVATAR ──────────────────────────────────
    CopyAvatar    = false,
    CopyAvatarID  = 0,             -- isi UserID player target
    CopyByName    = "",            -- atau isi username, kosongkan jika pakai ID

    -- ── MISC ──────────────────────────────────────────
    AntiAFK       = true,
    InfStam       = false,
    InvisName     = false,
    HitLog        = false,
    SafeMode      = false,
}

-- ════════════════════════════════════════════════════════════
-- [4] HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════
local function getChar()  return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function W2S(pos)
    local vp, vis, depth = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), vis, depth
end

local function dist3(a, b)
    return (a - b).Magnitude
end

local function notify(title, msg)
    -- Gunakan StarterGui untuk notif ringan
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title   = title,
            Text    = msg,
            Duration = 3,
        })
    end)
end

-- ════════════════════════════════════════════════════════════
-- [5] VISUAL — FULLBRIGHT + NO SHADOW
-- ════════════════════════════════════════════════════════════
local function applyVisual()
    if CFG.Fullbright then
        Lighting.Ambient                  = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient           = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness               = CFG.FB_Level
        Lighting.EnvironmentDiffuseScale  = 1
        Lighting.EnvironmentSpecularScale = 1
    end
    if CFG.NoShadow then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end
    if CFG.ForceClock then
        Lighting.ClockTime = CFG.ClockTime
    end
    if CFG.NoFog then
        Lighting.FogEnd   = 1e9
        Lighting.FogStart = 1e9
    end
    if CFG.NoEffects then
        for _, ef in pairs(Lighting:GetChildren()) do
            if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
            or ef:IsA("DepthOfFieldEffect") or ef:IsA("SunRaysEffect") then
                ef.Enabled = false
            end
        end
    end
end
applyVisual()

-- ════════════════════════════════════════════════════════════
-- [6] ESP HOLOGRAM — ALL ENTITIES
-- ════════════════════════════════════════════════════════════
local function flickAlpha()
    if not CFG.ESP_Flicker then return 1 end
    return 0.55 + math.abs(math.sin(tick() * 28)) * 0.45
end

local function drawBox(sp, sz, color, alpha)
    local b = Drawing.new("Square")
    b.Size     = Vector2.new(sz, sz * 1.75)
    b.Position = sp - Vector2.new(sz / 2, sz * 0.875)
    b.Color    = color; b.Thickness = CFG.ESP_Thick
    b.Filled   = false; b.Transparency = alpha; b.Visible = true
end

local function drawTracer(sp, color, alpha)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local ln     = Drawing.new("Line")
    ln.From      = center; ln.To = sp; ln.Color = color
    ln.Thickness = CFG.ESP_Thick; ln.Transparency = alpha; ln.Visible = true
end

local function drawCircle(sp, sz, color, alpha)
    local circ = Drawing.new("Circle")
    circ.Position    = sp; circ.Radius = sz / 2
    circ.Color       = color; circ.Thickness = CFG.ESP_Thick
    circ.Filled      = false; circ.Transparency = alpha; circ.Visible = true
end

local function drawCorners(sp, sz, color, alpha)
    local bLen = sz * 0.28
    local corners = {
        { sp + Vector2.new(-sz/2, -sz*0.875), {{bLen,0},{0,bLen}} },
        { sp + Vector2.new( sz/2, -sz*0.875), {{-bLen,0},{0,bLen}} },
        { sp + Vector2.new(-sz/2,  sz*0.875), {{bLen,0},{0,-bLen}} },
        { sp + Vector2.new( sz/2,  sz*0.875), {{-bLen,0},{0,-bLen}} },
    }
    for _, c in pairs(corners) do
        for _, d in pairs(c[2]) do
            local l = Drawing.new("Line")
            l.From        = c[1]
            l.To          = c[1] + Vector2.new(d[1], d[2])
            l.Color       = color; l.Thickness = CFG.ESP_Thick + 1
            l.Transparency = alpha; l.Visible   = true
        end
    end
end

local function drawLabel(sp, sz, label, dist, color, alpha)
    local txt      = Drawing.new("Text")
    local distStr  = CFG.ESP_ShowDist and (" [" .. math.floor(dist) .. "m]") or ""
    txt.Text       = (CFG.ESP_ShowName and label or "") .. distStr
    txt.Position   = sp - Vector2.new(0, sz * 0.875 + 15)
    txt.Color      = color; txt.Size = 13; txt.Outline = true
    txt.Transparency = alpha; txt.Visible = true; txt.Center = true
end

local function Hologram(pos, color, label, dist)
    local sp, vis, depth = W2S(pos)
    if not vis or depth < 0 then return end
    local sz    = math.clamp(500 / depth, 8, 280)
    local alpha = flickAlpha()
    local style = CFG.ESP_Style
    if style == "box" then
        drawBox(sp, sz, color, alpha)
    elseif style == "tracer" then
        drawTracer(sp, color, alpha)
    elseif style == "circle" then
        drawCircle(sp, sz, color, alpha)
    elseif style == "corner" then
        drawCorners(sp, sz, color, alpha)
    end
    if CFG.ESP_SnapLine then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local snap   = Drawing.new("Line")
        snap.From    = center; snap.To = sp; snap.Color = color
        snap.Thickness = 0.5; snap.Transparency = alpha * 0.35; snap.Visible = true
    end
    if CFG.ESP_ShowName or CFG.ESP_ShowDist then
        drawLabel(sp, sz, label, dist, color, alpha)
    end
end

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
}

local function runESP()
    if not isInMatch() then return end
    local myHRP = getHRP()
    -- Player ESP
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHRP then
                local d    = dist3(hrp.Position, myHRP.Position)
                local isK  = plr.Character:FindFirstChild("KillerTag") ~= nil
                if d <= CFG.ESP_MaxDist then
                    if CFG.ESP_Killer and isK then
                        Hologram(hrp.Position, CFG.C_Killer, plr.Name, d)
                    end
                    if CFG.ESP_Survivor and not isK then
                        Hologram(hrp.Position, CFG.C_Surv, plr.Name, d)
                    end
                end
            end
        end
    end
    -- Map object ESP
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nl = obj.Name:lower()
            for _, entry in pairs(ESP_MAP) do
                if nl:find(entry.kw) and CFG[entry.en] then
                    local pos = obj:IsA("Model")
                        and (obj.PrimaryPart and obj.PrimaryPart.Position
                             or obj:GetModelCFrame().Position)
                        or obj.Position
                    local d2 = myHRP and dist3(pos, myHRP.Position) or 0
                    if d2 <= CFG.ESP_MaxDist then
                        Hologram(pos, CFG[entry.col], entry.lb, d2)
                    end
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [7] AIMBOT PISTOL + SILENT AIM
-- ════════════════════════════════════════════════════════════
local function getBestTarget()
    if not isInMatch() then return nil end
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bd = nil, CFG.AimFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if not CFG.AimKiller or isK then
                local part = plr.Character:FindFirstChild(CFG.AimBone)
                    or plr.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local pred = part.Position + part.Velocity * (CFG.AimPredict * 0.05)
                    local sp, vis = W2S(pred)
                    if vis then
                        local d = (sp - center).Magnitude
                        if d < bd then
                            bd   = d
                            best = pred + Vector3.new(CFG.AimOffX * 0.01, CFG.AimOffY * 0.01, 0)
                        end
                    end
                end
            end
        end
    end
    return best
end

local function isAimHeld()
    if CFG.AimKey == "RMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif CFG.AimKey == "LMB" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    else
        return UserInputService:IsKeyDown(Enum.KeyCode[CFG.AimKey])
    end
end

if CFG.AimOn or CFG.SilentAim then
    RunService.RenderStepped:Connect(function()
        if not isInMatch() then return end
        if not isAimHeld() then return end
        local target = getBestTarget()
        if not target then return end
        if CFG.SilentAim then
            Mouse.Hit = CFrame.new(target)
        else
            local sp  = Camera:WorldToScreenPoint(target)
            local dx  = (sp.X - Mouse.X) / CFG.AimSmooth
            local dy  = (sp.Y - Mouse.Y) / CFG.AimSmooth
            mousemoverel(dx, dy)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [8] FLASHLIGHT AIMBOT + PREDICT
-- ════════════════════════════════════════════════════════════
if CFG.FlashAim then
    RunService.RenderStepped:Connect(function()
        if not isInMatch() then return end
        local char   = getChar()
        local tool   = char and char:FindFirstChildWhichIsA("Tool")
        if not tool then return end
        local handle = tool:FindFirstChild("Handle")
        if not handle then return end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local part = plr.Character:FindFirstChild(CFG.FlashBone)
                    or plr.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local tgt = CFG.FlashPred
                        and (part.Position + part.Velocity * CFG.FlashStr * 0.05)
                        or part.Position
                    handle.CFrame = CFrame.lookAt(handle.Position, tgt)
                end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [9] VEIL SILENT AIM
-- ════════════════════════════════════════════════════════════
if CFG.VeilOn then
    RunService.RenderStepped:Connect(function()
        if not isInMatch() then return end
        local myHRP = getHRP()
        if not myHRP then return end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local part = plr.Character:FindFirstChild(CFG.VeilBone)
                    or plr.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local d = dist3(part.Position, myHRP.Position)
                    if d <= CFG.VeilDist then
                        local tgt = CFG.VeilPred
                            and (part.Position + part.Velocity * CFG.VeilLead * 0.05)
                            or part.Position
                        Mouse.Hit = CFrame.new(tgt)
                        if CFG.VeilFire then
                            local tool = getChar():FindFirstChildWhichIsA("Tool")
                            local fire = tool and tool:FindFirstChild("Fire")
                            if fire then pcall(function() fire:FireServer(tgt) end) end
                        end
                    end
                end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [10] AUTO PARRY DAGGER + FAKE PARRY
-- ════════════════════════════════════════════════════════════
--[[
  AUTO PARRY:
    - Deteksi attacker (Killer) yang memakai dagger / skill slash
    - Jika masuk jarak CFG.ParryDist, trigger tombol parry (FireServer)
    - Predict posisi attacker untuk timing yang lebih akurat

  FAKE PARRY:
    - Kirim animasi / tindakan parry ke server TANPA benar-benar
      melakukan parry yang valid — tujuannya bait attacker
    - Bisa dikombinasi dengan auto parry (mode "both")

  JARAK CUSTOM:
    - ParryDist = jarak trigger auto parry (studs)
    - FakeParryDist = jarak trigger fake parry (lebih jauh)
    - Adjust sesuai ping & reaction time killer
]]

local parryCD     = 0
local fakeParryCD = 0

local function findAttacker()
    -- Cari player yang lagi attack (ada hitbox / sedang animasi dagger)
    local myHRP = getHRP()
    if not myHRP then return nil end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if isK then
                local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if kHRP then
                    local d = dist3(kHRP.Position, myHRP.Position)
                    if d <= math.max(CFG.ParryDist, CFG.FakeParryDist) then
                        -- cek ada hitbox dagger / animasi attack
                        local hasHitbox = false
                        for _, v in pairs(plr.Character:GetDescendants()) do
                            local nl = v.Name:lower()
                            if nl:find("hitbox") or nl:find("dagger") or nl:find("parry")
                            or nl:find(CFG.ParrySkillName:lower())
                            or nl:find(CFG.ParryHitboxName:lower()) then
                                hasHitbox = true; break
                            end
                        end
                        -- juga cek via animasi
                        local hasAnim = false
                        local animator = plr.Character:FindFirstChildOfClass("Animator")
                        if animator and animator.GetPlayingAnimationTracks then
                            local ok, tracks = pcall(function()
                                return animator:GetPlayingAnimationTracks()
                            end)
                            if ok and tracks then
                                for _, track in pairs(tracks) do
                                    local tn = track.Name:lower()
                                    if tn:find("attack") or tn:find("slash") or tn:find("dagger") then
                                        hasAnim = true; break
                                    end
                                end
                            end
                        end
                        if hasHitbox or hasAnim then
                            return plr, kHRP, d
                        end
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function triggerParry()
    -- Coba trigger parry via beberapa method:
    -- 1. simulasi key press
    -- 2. cari remote event parry
    -- 3. simulasi mouse click
    local char = getChar()
    if not char then return end
    -- Method 1: Simulasi key parry
    local vui = game:GetService("VirtualInputManager")
    if vui then
        pcall(function()
            vui:SendKeyEvent(true,  CFG.ParryKey, false, game)
            task.wait(0.05)
            vui:SendKeyEvent(false, CFG.ParryKey, false, game)
        end)
    end
    -- Method 2: Scan remote event bernama parry
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local nl = obj.Name:lower()
            if nl:find("parry") or nl:find("block") or nl:find("counter") then
                pcall(function() obj:FireServer() end)
            end
        end
    end
    -- Method 3: Tool action jika punya dagger
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        local action = tool:FindFirstChild("Parry") or tool:FindFirstChild("Block")
        if action and action:IsA("RemoteEvent") then
            pcall(function() action:FireServer() end)
        end
    end
end

local function triggerFakeParry(attackerHRP)
    -- Fake parry: kirim sinyal parry tapi dengan timing yang salah
    -- atau kirim ke arah yang bukan attacker — bait killer
    local char = getChar()
    if not char then return end
    -- Simulasi key parry
    local vui = game:GetService("VirtualInputManager")
    if vui then
        pcall(function()
            vui:SendKeyEvent(true,  CFG.ParryKey, false, game)
            task.wait(0.02)
            vui:SendKeyEvent(false, CFG.ParryKey, false, game)
        end)
    end
    -- FireServer ke arah yang salah (bait)
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local nl = obj.Name:lower()
            if nl:find("parry") or nl:find("block") then
                -- kirim dengan posisi yang sedikit offset = fake
                local fakePos = attackerHRP.Position + Vector3.new(
                    math.random(-5,5), 0, math.random(-5,5)
                )
                pcall(function() obj:FireServer(fakePos) end)
            end
        end
    end
end

local function runAutoParry()
    if not isInMatch() then return end
    if not CFG.AutoParry and not CFG.FakeParryOn then return end

    local attacker, attackerHRP, attackDist = findAttacker()
    if not attacker or not attackerHRP then return end

    -- Predict posisi attacker
    local predPos = CFG.ParryPredict
        and (attackerHRP.Position + attackerHRP.Velocity * CFG.ParryLead * 0.016)
        or attackerHRP.Position
    local myHRP   = getHRP()
    local predDist = myHRP and dist3(predPos, myHRP.Position) or attackDist

    -- AUTO PARRY (mode "auto" atau "both")
    if CFG.AutoParry and (CFG.ParryMode == "auto" or CFG.ParryMode == "both") then
        if predDist <= CFG.ParryDist and tick() - parryCD > 0.5 then
            parryCD = tick()
            triggerParry()
            notify("Quantum Hub", "Auto Parry triggered! (" .. math.floor(predDist) .. "m)")
        end
    end

    -- FAKE PARRY (mode "fake" atau "both")
    if CFG.FakeParryOn and (CFG.ParryMode == "fake" or CFG.ParryMode == "both") then
        if predDist <= CFG.FakeParryDist and tick() - fakeParryCD > CFG.FakeParryCD then
            fakeParryCD = tick()
            triggerFakeParry(attackerHRP)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [11] AUTO DUCK — ABYSS SLASH
-- ════════════════════════════════════════════════════════════
local duckActive = false
local function runAutoDuck()
    if not CFG.AutoDuck or not isInMatch() or duckActive then return end
    local myHRP = getHRP()
    if not myHRP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.DuckDist then
                local triggered = false
                -- Method 1: animasi
                if CFG.DuckAnim then
                    local animator = plr.Character:FindFirstChildOfClass("Animator")
                    if animator and animator.GetPlayingAnimationTracks then
                        local ok, tracks = pcall(function()
                            return animator:GetPlayingAnimationTracks()
                        end)
                        if ok and tracks then
                            for _, track in pairs(tracks) do
                                if track.Name:lower():find(CFG.AbyssSkill:lower()) then
                                    triggered = true; break
                                end
                            end
                        end
                    end
                end
                -- Method 2: hitbox part
                if CFG.DuckHitbox and not triggered then
                    for _, v in pairs(plr.Character:GetDescendants()) do
                        local nl = v.Name:lower()
                        if nl:find("slash") or nl:find("hitbox") or nl:find("attack") then
                            triggered = true; break
                        end
                    end
                end
                if triggered then
                    duckActive = true
                    local hum  = getHum()
                    if hum then hum.Sit = true end
                    task.delay(CFG.DuckDur, function()
                        local h2 = getHum()
                        if h2 then h2.Sit = false end
                        duckActive = false
                    end)
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [12] AUTO PALLET
-- ════════════════════════════════════════════════════════════
local palletCD = 0
local function runAutoPallet()
    if not CFG.AutoPallet or not isInMatch() then return end
    if tick() - palletCD < CFG.PalletCD then return end
    local myHRP = getHRP()
    if not myHRP then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local isK = plr.Character:FindFirstChild("KillerTag") ~= nil
            if not CFG.PalletKiller or isK then
                local kHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if kHRP and dist3(kHRP.Position, myHRP.Position) < CFG.PalletDist then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj.Name:lower():find("pallet") then
                            local palPos = obj:IsA("BasePart") and obj.Position
                                or (obj.PrimaryPart and obj.PrimaryPart.Position)
                            if palPos and dist3(palPos, myHRP.Position) < 22 then
                                local remote = (obj.Parent or obj):FindFirstChildOfClass("RemoteEvent")
                                    or (obj.Parent or obj):FindFirstChild("ThrowPallet")
                                if remote then
                                    pcall(function() remote:FireServer() end)
                                    palletCD = tick()
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [13] AUTO GENERATOR
-- ════════════════════════════════════════════════════════════
local function getGenDelay()
    local m = CFG.GenMode
    if m == "instant" then return 0.01
    elseif m == "legit" then return math.random(8, 18) * 0.01
    elseif m == "random" then return math.random(2, 25) * 0.01
    else return 0.12 end
end

if CFG.AutoGen then
    task.spawn(function()
        while task.wait(0.1) do
            if not isInMatch() then task.wait(1); continue end
            local myHRP = getHRP()
            local gens  = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") and obj:IsA("Model") then
                    table.insert(gens, obj)
                end
            end
            if CFG.GenNearest and myHRP then
                table.sort(gens, function(a, b)
                    local pa = a.PrimaryPart or a:FindFirstChildOfClass("BasePart")
                    local pb = b.PrimaryPart or b:FindFirstChildOfClass("BasePart")
                    if not pa or not pb then return false end
                    return dist3(pa.Position, myHRP.Position)
                        < dist3(pb.Position, myHRP.Position)
                end)
            end
            for _, gen in pairs(gens) do
                task.spawn(function()
                    task.wait(getGenDelay())
                    local remote = gen:FindFirstChildOfClass("RemoteEvent")
                        or gen:FindFirstChild("Repair")
                    if remote then
                        pcall(function() remote:FireServer() end)
                    end
                end)
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [14] CAMERA — POV + DBD STYLE
-- ════════════════════════════════════════════════════════════
if CFG.CamOn then
    Camera.FieldOfView = CFG.CamFOV
    if CFG.DBDCam then
        local camLerp = Vector3.new()
        RunService.RenderStepped:Connect(function(dt)
            if not isInMatch() then return end
            local hrp = getHRP()
            if not hrp then return end
            Camera.CameraType = Enum.CameraType.Scriptable
            local pitch  = math.rad(CFG.CamPitch)
            local offset = Vector3.new(
                0,
                -math.sin(pitch) * CFG.CamDist,
                math.cos(pitch)  * CFG.CamDist
            )
            local targetPos = hrp.Position + offset
            if CFG.CamSmooth then
                camLerp = camLerp:Lerp(targetPos, math.clamp(dt * 8, 0, 1))
                targetPos = camLerp
            end
            Camera.CFrame      = CFrame.lookAt(targetPos, hrp.Position)
            Camera.FieldOfView = CFG.CamFOV
        end)
    end
end

-- ════════════════════════════════════════════════════════════
-- [15] COPY AVATAR — ID / NAME
-- ════════════════════════════════════════════════════════════
--[[
  Copy avatar player lain:
  - Isi CFG.CopyAvatarID = UserID target
  - ATAU isi CFG.CopyByName = "Username" target
  - Script akan apply avatar mereka ke karakter kamu
  - Pakai HumanoidDescription untuk copy appearance
]]
local function copyAvatarByID(userId)
    pcall(function()
        local hum = getHum()
        if not hum then return end
        local desc = Players:GetHumanoidDescriptionFromUserId(userId)
        hum:ApplyDescription(desc)
        notify("Quantum Hub", "Avatar copied! ID: " .. userId)
    end)
end

local function copyAvatarByName(username)
    pcall(function()
        local userId = Players:GetUserIdFromNameAsync(username)
        if userId then
            copyAvatarByID(userId)
        end
    end)
end

local function runCopyAvatar()
    if not CFG.CopyAvatar then return end
    if CFG.CopyByName ~= "" then
        copyAvatarByName(CFG.CopyByName)
    elseif CFG.CopyAvatarID ~= 0 then
        copyAvatarByID(CFG.CopyAvatarID)
    end
end

-- Jalankan sekali saat inject
if CFG.CopyAvatar then
    task.spawn(runCopyAvatar)
end

-- ════════════════════════════════════════════════════════════
-- [16] MOVEMENT: MOONWALK + SPEED BOOST
-- ════════════════════════════════════════════════════════════
local mwActive, sbActive = false, false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or not isInMatch() then return end
    local hum = getHum()
    if CFG.Moonwalk and inp.KeyCode == CFG.MWKey then
        mwActive = not mwActive
    end
    if CFG.SpeedBoost and inp.KeyCode == CFG.SBKey then
        sbActive = not sbActive
        if hum then hum.WalkSpeed = sbActive and CFG.WalkSpeed or 16 end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [17] NO CLIP + FLY
-- ════════════════════════════════════════════════════════════
local ncActive = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or not isInMatch() then return end
    if CFG.NoClip and inp.KeyCode == CFG.NCKey then
        ncActive = not ncActive
        local char = getChar()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = not ncActive
                end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [18] MISC
-- ════════════════════════════════════════════════════════════
-- Anti AFK
if CFG.AntiAFK then
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end

-- Infinite stamina
if CFG.InfStam then
    RunService.Heartbeat:Connect(function()
        if not isInMatch() then return end
        local char = getChar()
        if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if v.Name:lower():find("stamin") and v:IsA("NumberValue") then
                if v.Value < 5 then v.Value = 100 end
            end
        end
    end)
end

-- Invisible nametag
if CFG.InvisName then
    local function hideTag(char)
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head then
            local gui = head:FindFirstChildOfClass("BillboardGui")
            if gui then gui.Enabled = false end
        end
    end
    LP.CharacterAdded:Connect(hideTag)
    hideTag(getChar())
end

-- ════════════════════════════════════════════════════════════
-- [19] MAIN RENDER LOOP
-- ════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    if not isInMatch() then return end

    -- ESP
    runESP()

    -- Auto systems
    runAutoPallet()
    runAutoDuck()
    runAutoParry()

    -- Moonwalk
    if mwActive and CFG.Moonwalk then
        local hrp = getHRP()
        local hum = getHum()
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, (hum.WalkSpeed or 16) * dt * 2)
        end
    end

    -- No clip speed + fly
    if ncActive and CFG.NoClip then
        local hum = getHum()
        if hum then hum.WalkSpeed = CFG.NCSpeed end
        if CFG.NCFly then
            local hrp = getHRP()
            if hrp then
                local flyDir = Vector3.new()
                if UserInputService:IsKeyDown(CFG.FlyUp) then
                    flyDir = flyDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(CFG.FlyDown) then
                    flyDir = flyDir + Vector3.new(0, -1, 0)
                end
                if flyDir.Magnitude > 0 then
                    hrp.Velocity = hrp.Velocity + flyDir * CFG.NCSpeed * dt * 3
                end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [20] FAKE PARRY GUI — toggle panel via key (tidak butuh GUI lib)
-- Fake parry GUI = notifikasi status di layar via Drawing text
-- ════════════════════════════════════════════════════════════
local parryStatusText = Drawing.new("Text")
parryStatusText.Visible  = false
parryStatusText.Size     = 16
parryStatusText.Outline  = true
parryStatusText.Center   = true

RunService.RenderStepped:Connect(function()
    if not isInMatch() then
        parryStatusText.Visible = false
        return
    end
    local vp  = Camera.ViewportSize
    parryStatusText.Position = Vector2.new(vp.X / 2, vp.Y - 80)
    local attacker, _, atkDist = findAttacker()
    if attacker and atkDist then
        local mode = CFG.ParryMode
        local col  = CFG.AutoParry and Color3.fromRGB(51,255,136) or Color3.fromRGB(255,200,50)
        parryStatusText.Color   = col
        parryStatusText.Text    = "[QUANTUM] Parry ready — " ..
            math.floor(atkDist) .. "m | mode: " .. mode
        parryStatusText.Visible = true
    else
        parryStatusText.Visible = false
    end
end)

-- ════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════╗")
print("║  QUANTUM HUB v4.0 — Violence District   ║")
print("║  discord.gg/ojailbreaks | @oll.fx        ║")
print("║  Match Guard: ACTIVE                     ║")
print("║  Auto Parry : " .. tostring(CFG.AutoParry) .. "                       ║")
print("║  Fake Parry : " .. tostring(CFG.FakeParryOn) .. "                      ║")
print("║  Copy Avatar: " .. tostring(CFG.CopyAvatar) .. "                      ║")
print("╚══════════════════════════════════════════╝")

--[[
  ════════════════════════════════════════════════════════════
  CARA PAKAI AUTO PARRY:
  ════════════════════════════════════════════════════════════
  1. Set CFG.AutoParry = true
  2. Set CFG.ParryDist = jarak (studs) kapan parry trigger
     -- 8–12 studs biasanya optimal untuk dagger
  3. Set CFG.ParryMode = "auto" / "fake" / "both"
     -- "auto"  = parry beneran saja
     -- "fake"  = fake parry saja (bait killer)
     -- "both"  = fake dulu, auto parry saat mepet
  4. Set CFG.ParryKey = key yang dipakai untuk parry di VD
     -- default Enum.KeyCode.F
  5. Jika parry tidak trigger, scan nama remote event parry:
     for _,v in pairs(game:GetDescendants()) do
       if v:IsA("RemoteEvent") then print(v.Name, v:GetFullName()) end
     end
     Lalu update nama di fungsi triggerParry()

  CARA PAKAI COPY AVATAR:
  ════════════════════════════════════════════════════════════
  -- Copy by UserID:
  CFG.CopyAvatar   = true
  CFG.CopyAvatarID = 123456789  -- ganti dengan UserID target

  -- Copy by Username:
  CFG.CopyAvatar  = true
  CFG.CopyByName  = "PlayerName"  -- ganti dengan username target

  -- Cara cari UserID player di server:
  for _,p in pairs(game.Players:GetPlayers()) do
    print(p.Name, p.UserId)
  end

  CARA FIX JIKA SCRIPT ERROR SETELAH UPDATE:
  ════════════════════════════════════════════════════════════
  -- Scan semua object:
  for _,v in pairs(workspace:GetDescendants()) do
    print(v.Name, v.ClassName)
  end

  -- Scan remote events:
  for _,v in pairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") then print(v.Name, v:GetFullName()) end
  end

  -- Scan animasi aktif (fix Abyss / Parry detection):
  for _,p in pairs(game.Players:GetPlayers()) do
    local a = p.Character and p.Character:FindFirstChildOfClass("Animator")
    if a and a.GetPlayingAnimationTracks then
      for _,t in pairs(a:GetPlayingAnimationTracks()) do
        print(p.Name, t.Name, t.Animation.AnimationId)
      end
    end
  end
]]
