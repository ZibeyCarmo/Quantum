
--[[
    QUANTUM HUB
    Standalone Roblox Lua GUI
    RightShift = Show / Hide
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local guiParent = player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("QUANTUM_HUB")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "QUANTUM_HUB"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local enabled = {
    Fullbright = false,
    Shadows = true,
    CameraBoost = false,
}

local original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Shadows = Lighting.GlobalShadows,
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local window = create("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(640, 440),
    Position = UDim2.new(0.5, -320, 0.5, -220),
    BackgroundColor3 = Color3.fromRGB(18, 18, 27),
    BorderSizePixel = 0,
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 12)
}, window)

local header = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Color3.fromRGB(100, 55, 190),
    Text = "QUANTUM HUB  |  CONTROL PANEL",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    BorderSizePixel = 0,
}, window)

create("UICorner", {
    CornerRadius = UDim.new(0, 12)
}, header)

local sidebar = create("Frame", {
    Position = UDim2.fromOffset(12, 60),
    Size = UDim2.new(0, 150, 1, -72),
    BackgroundColor3 = Color3.fromRGB(29, 27, 42),
    BorderSizePixel = 0,
}, window)

create("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, sidebar)

local content = create("ScrollingFrame", {
    Position = UDim2.fromOffset(174, 60),
    Size = UDim2.new(1, -186, 1, -72),
    BackgroundColor3 = Color3.fromRGB(25, 24, 36),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, 700),
}, window)

create("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, content)

local layout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

local function clearContent()
    for _, item in ipairs(content:GetChildren()) do
        if item ~= layout then
            item:Destroy()
        end
    end
end

local function addLabel(text)
    return create("TextLabel", {
        Size = UDim2.new(1, -16, 0, 32),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(205, 185, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
end

local function addButton(text, callback)
    local b = create("TextButton", {
        Size = UDim2.new(1, -16, 0, 38),
        BackgroundColor3 = Color3.fromRGB(61, 48, 88),
        TextColor3 = Color3.new(1, 1, 1),
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = true,
    }, content)

    create("UICorner", {
        CornerRadius = UDim.new(0, 6)
    }, b)

    b.Activated:Connect(callback)
    return b
end

local function addToggle(name, initial, callback)
    local state = initial

    local b = addButton(
        name .. ": " .. (state and "ON" or "OFF"),
        function()
            state = not state
            b.Text = name .. ": " .. (state and "ON" or "OFF")
            b.BackgroundColor3 = state
                and Color3.fromRGB(100, 60, 155)
                or Color3.fromRGB(61, 48, 88)

            local ok, err = pcall(callback, state)
            if not ok then
                warn("[QUANTUM HUB]", name, err)
            end
        end
    )

    b.BackgroundColor3 = state
        and Color3.fromRGB(100, 60, 155)
        or Color3.fromRGB(61, 48, 88)

    return b
end

local function home()
    clearContent()
    addLabel("QUANTUM HUB / DASHBOARD")

    addButton("Current player: " .. player.Name, function()
        print("Player:", player.Name)
    end)

    addButton("Show current FOV", function()
        local cam = workspace.CurrentCamera
        if cam then
            print("Current FOV:", cam.FieldOfView)
        end
    end)

    addButton("Reset FOV to 70", function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = 70
        end
    end)

    addButton("Hide window", function()
        window.Visible = false
    end)
end

local function visualTab()
    clearContent()
    addLabel("VISUAL SETTINGS")

    addToggle("Fullbright", enabled.Fullbright, function(on)
        enabled.Fullbright = on

        if on then
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        else
            Lighting.Brightness = original.Brightness
            Lighting.ClockTime = original.ClockTime
            Lighting.Ambient = original.Ambient
            Lighting.OutdoorAmbient = original.OutdoorAmbient
        end
    end)

    addToggle("Global Shadows", enabled.Shadows, function(on)
        enabled.Shadows = on
        Lighting.GlobalShadows = on
    end)

    addLabel("VISUAL DEBUG")

    addButton("Count tagged debug objects", function()
        local count = 0

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:GetAttribute("DebugTarget") == true then
                count += 1
                print("[QUANTUM DEBUG]", obj:GetFullName())
            end
        end

        print("Debug objects:", count)
    end)
end

local function cameraTab()
    clearContent()
    addLabel("CAMERA SETTINGS")

    addButton("FOV +5", function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = math.clamp(cam.FieldOfView + 5, 40, 100)
        end
    end)

    addButton("FOV -5", function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = math.clamp(cam.FieldOfView - 5, 40, 100)
        end
    end)

    addButton("First Person", function()
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end)

    addButton("Classic Camera", function()
        player.CameraMode = Enum.CameraMode.Classic
    end)

    addButton("Reset Zoom", function()
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 12
    end)
end

local function settingsTab()
    clearContent()
    addLabel("SETTINGS")

    addButton("Print hub version", function()
        print("QUANTUM HUB version 1.0")
    end)

    addButton("Restore lighting", function()
        enabled.Fullbright = false
        Lighting.Brightness = original.Brightness
        Lighting.ClockTime = original.ClockTime
        Lighting.Ambient = original.Ambient
        Lighting.OutdoorAmbient = original.OutdoorAmbient
        Lighting.GlobalShadows = original.Shadows
    end)

    addButton("Close GUI", function()
        gui:Destroy()
    end)
end

local function nav(text, y, callback)
    local b = create("TextButton", {
        Position = UDim2.fromOffset(8, y),
        Size = UDim2.new(1, -16, 0, 38),
        BackgroundColor3 = Color3.fromRGB(65, 48, 91),
        TextColor3 = Color3.new(1, 1, 1),
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BorderSizePixel = 0,
    }, sidebar)

    create("UICorner", {
        CornerRadius = UDim.new(0, 6)
    }, b)

    b.Activated:Connect(callback)
end

nav("Dashboard", 8, home)
nav("Visual", 52, visualTab)
nav("Camera", 96, cameraTab)
nav("Settings", 140, settingsTab)

-- Drag window
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        window.Visible = not window.Visible
    end
end)

home()
print("QUANTUM HUB loaded successfully.")
