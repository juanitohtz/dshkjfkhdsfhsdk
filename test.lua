--[[ 
    ESP + Triggerbot (L toggle, V hold) + Kill Button + ESP Settings (HTMLColorCodes-style) + Resizable UI
    L = Arm/Disarm system (Triggerbot + Debug)
    Hold V = Triggerbot
    RightShift = Toggle UI visibility
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

local Running = true
local Connections = {}

local ESP = {
    Enabled = false,      -- ONLY visuals
    Pixels = {},
    FillColor = Color3.fromRGB(255,0,0),
    OutlineColor = Color3.fromRGB(255,255,255)
}

local SystemArmed = false   -- NEW: triggerbot + debug use this
local TriggerHeld = false
local TriggerState = "DISARMED"

------------------------------------------------------------------
-- COLOR HELPERS
------------------------------------------------------------------

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0

    if h < 60 then r,g,b = c,x,0
    elseif h < 120 then r,g,b = x,c,0
    elseif h < 180 then r,g,b = 0,c,x
    elseif h < 240 then r,g,b = 0,x,c
    elseif h < 300 then r,g,b = x,0,c
    else r,g,b = c,0,x end

    return Color3.new(r+m, g+m, b+m)
end

local function RGBToHSV(color)
    local r,g,b = color.R, color.G, color.B
    local max = math.max(r,g,b)
    local min = math.min(r,g,b)
    local d = max - min

    local h = 0
    if d ~= 0 then
        if max == r then h = 60 * (((g-b)/d)%6)
        elseif max == g then h = 60 * (((b-r)/d)+2)
        else h = 60 * (((r-g)/d)+4) end
    end

    local s = (max == 0) and 0 or (d/max)
    local v = max

    return h,s,v
end

------------------------------------------------------------------
-- UI (unchanged except for SystemArmed integration)
------------------------------------------------------------------

local screenGui, mainFrame, resizeHandle
local mainTab, debugTab, settingsTab
local mainContent, debugContent, settingsContent
local espToggle, stateLabel, killButton
local svSquare, hueBar, preview
local applyFill, applyOutline

local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,360,0,260)
    mainFrame.Position = UDim2.new(0,20,0,20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)

    resizeHandle = Instance.new("Frame")
    resizeHandle.Size = UDim2.new(0,14,0,14)
    resizeHandle.AnchorPoint = Vector2.new(1,1)
    resizeHandle.Position = UDim2.new(1,0,1,0)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Parent = mainFrame
    Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0,3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "ESP + Triggerbot"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,-10,0,26)
    tabBar.Position = UDim2.new(0,5,0,32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(1/3,-5,1,0)
    mainTab.Position = UDim2.new(0,0,0,0)
    mainTab.BackgroundColor3 = Color3.fromRGB(50,50,50)
    mainTab.TextColor3 = Color3.fromRGB(255,255,255)
    mainTab.TextScaled = true
    mainTab.Text = "Main"
    mainTab.BorderSizePixel = 0
    mainTab.Parent = tabBar
    Instance.new("UICorner", mainTab).CornerRadius = UDim.new(0,6)

    debugTab = Instance.new("TextButton")
    debugTab.Size = UDim2.new(1/3,-5,1,0)
    debugTab.Position = UDim2.new(1/3,5,0,0)
    debugTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
    debugTab.TextColor3 = Color3.fromRGB(200,200,200)
    debugTab.TextScaled = true
    debugTab.Text = "Debug"
    debugTab.BorderSizePixel = 0
    debugTab.Parent = tabBar
    Instance.new("UICorner", debugTab).CornerRadius = UDim.new(0,6)

    settingsTab = Instance.new("TextButton")
    settingsTab.Size = UDim2.new(1/3,-5,1,0)
    settingsTab.Position = UDim2.new(2/3,10,0,0)
    settingsTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
    settingsTab.TextColor3 = Color3.fromRGB(200,200,200)
    settingsTab.TextScaled = true
    settingsTab.Text = "ESP Settings"
    settingsTab.BorderSizePixel = 0
    settingsTab.Parent = tabBar
    Instance.new("UICorner", settingsTab).CornerRadius = UDim.new(0,6)

    -- Main content
    mainContent = Instance.new("Frame")
    mainContent.Size = UDim2.new(1,-10,1,-90)
    mainContent.Position = UDim2.new(0,5,0,60)
    mainContent.BackgroundTransparency = 1
    mainContent.Name = "MainContent"
    mainContent.Parent = mainFrame

    espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0,260,0,36)
    espToggle.Position = UDim2.new(0,20,0,5)
    espToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    espToggle.TextColor3 = Color3.fromRGB(255,255,255)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: OFF"
    espToggle.BorderSizePixel = 0
    espToggle.Parent = mainContent
    Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0,6)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,40)
    info.Position = UDim2.new(0,5,0,45)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.TextWrapped = true
    info.Text = "L = Arm/Disarm | Hold V = Trigger | RightShift = Hide UI"
    info.Parent = mainContent

    killButton = Instance.new("TextButton")
    killButton.Size = UDim2.new(0,260,0,30)
    killButton.Position = UDim2.new(0,20,1,-35)
    killButton.BackgroundColor3 = Color3.fromRGB(150,40,40)
    killButton.TextColor3 = Color3.fromRGB(255,255,255)
    killButton.TextScaled = true
    killButton.Text = "KILL SCRIPT"
    killButton.BorderSizePixel = 0
    killButton.Parent = mainContent
    Instance.new("UICorner", killButton).CornerRadius = UDim.new(0,6)

    -- Debug content
    debugContent = Instance.new("Frame")
    debugContent.Size = UDim2.new(1,-10,1,-90)
    debugContent.Position = UDim2.new(0,5,0,60)
    debugContent.BackgroundTransparency = 1
    debugContent.Name = "DebugContent"
    debugContent.Visible = false
    debugContent.Parent = mainFrame

    stateLabel = Instance.new("TextLabel")
    stateLabel.Size = UDim2.new(1,-10,0,30)
    stateLabel.Position = UDim2.new(0,5,0,5)
    stateLabel.BackgroundColor3 = Color3.fromRGB(35,35,35)
    stateLabel.TextColor3 = Color3.fromRGB(255,255,255)
    stateLabel.TextScaled = true
    stateLabel.Text = "Trigger state: " .. TriggerState
    stateLabel.BorderSizePixel = 0
    stateLabel.Parent = debugContent
    Instance.new("UICorner", stateLabel).CornerRadius = UDim.new(0,6)

    local debugInfo = Instance.new("TextLabel")
    debugInfo.Size = UDim2.new(1,-10,0,70)
    debugInfo.Position = UDim2.new(0,5,0,40)
    debugInfo.BackgroundTransparency = 1
    debugInfo.TextColor3 = Color3.fromRGB(200,200,200)
    debugInfo.TextScaled = true
    debugInfo.TextWrapped = true
    debugInfo.Text = "DISARMED: L off\nARMED: L on\nHOLDING: L on + V held\nLOCKED & FIRING: enemy in center"
    debugInfo.Parent = debugContent

    -- Settings content (unchanged)
    settingsContent = Instance.new("Frame")
    settingsContent.Size = UDim2.new(1,-10,1,-90)
    settingsContent.Position = UDim2.new(0,5,0,60)
    settingsContent.BackgroundTransparency = 1
    settingsContent.Name = "SettingsContent"
    settingsContent.Visible = false
    settingsContent.Parent = mainFrame

    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.new(0,210,0,160)
    pickerFrame.Position = UDim2.new(0,10,0,5)
    pickerFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    pickerFrame.BorderSizePixel = 0
    pickerFrame.Parent = settingsContent
    Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0,6)

    -- SV square
    svSquare = Instance.new("Frame")
    svSquare.Size = UDim2.new(0,130,0,130)
    svSquare.Position = UDim2.new(0,10,0,10)
    svSquare.BackgroundColor3 = Color3.fromRGB(255,0,0)
    svSquare.BorderSizePixel = 0
    svSquare.Parent = pickerFrame

    -- White overlay
    local whiteOverlay = Instance.new("Frame")
    whiteOverlay.Size = UDim2.new(1,0,1,0)
    whiteOverlay.BackgroundTransparency = 1
    whiteOverlay.Parent = svSquare

    local whiteGrad = Instance.new("UIGradient")
    whiteGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    }
    whiteGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    whiteGrad.Parent = whiteOverlay

    -- Black overlay
    local blackOverlay = Instance.new("Frame")
    blackOverlay.Size = UDim2.new(1,0,1,0)
    blackOverlay.BackgroundTransparency = 1
    blackOverlay.Parent = svSquare

    local blackGrad = Instance.new("UIGradient")
    blackGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }
    blackGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    blackGrad.Rotation = 90
    blackGrad.Parent = blackOverlay

    -- Hue bar
    hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(0,20,0,130)
    hueBar.Position = UDim2.new(0,150,0,10)
    hueBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = pickerFrame

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0))
    }
    hueGrad.Rotation = 90
    hueGrad.Parent = hueBar

    preview = Instance.new("Frame")
    preview.Size = UDim2.new(0,40,0,40)
    preview.Position = UDim2.new(0,150,0,145)
    preview.BackgroundColor3 = ESP.FillColor
    preview.BorderSizePixel = 0
    preview.Parent = pickerFrame
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0,4)

    applyFill = Instance.new("TextButton")
    applyFill.Size = UDim2.new(0,120,0,24)
    applyFill.Position = UDim2.new(0,230,0,20)
    applyFill.BackgroundColor3 = Color3.fromRGB(60,120,60)
    applyFill.TextColor3 = Color3.fromRGB(255,255,255)
    applyFill.TextScaled = true
    applyFill.Text = "Apply to Fill"
    applyFill.BorderSizePixel = 0
    applyFill.Parent = settingsContent
    Instance.new("UICorner", applyFill).CornerRadius = UDim.new(0,4)

    applyOutline = applyFill:Clone()
    applyOutline.Text = "Apply to Outline"
    applyOutline.Position = UDim2.new(0,230,0,50)
    applyOutline.Parent = settingsContent

    -- Tab switching
    local function setTab(which)
        mainContent.Visible = (which == "main")
        debugContent.Visible = (which == "debug")
        settingsContent.Visible = (which == "settings")

        mainTab.BackgroundColor3 = (which == "main") and Color3.fromRGB(50,50,50) or Color3.fromRGB(35,35,35)
        mainTab.TextColor3 = (which == "main") and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)

        debugTab.BackgroundColor3 = (which == "debug") and Color3.fromRGB(50,50,50) or Color3.fromRGB(35,35,35)
        debugTab.TextColor3 = (which == "debug") and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)

        settingsTab.BackgroundColor3 = (which == "settings") and Color3.fromRGB(50,50,50) or Color3.fromRGB(35,35,35)
        settingsTab.TextColor3 = (which == "settings") and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
    end

    mainTab.MouseButton1Click:Connect(function() setTab("main") end)
    debugTab.MouseButton1Click:Connect(function() setTab("debug") end)
    settingsTab.MouseButton1Click:Connect(function() setTab("settings") end)
end

createUI()

------------------------------------------------------------------
-- RESIZABLE UI
------------------------------------------------------------------

do
    local resizing = false
    local startPos, startSize

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
