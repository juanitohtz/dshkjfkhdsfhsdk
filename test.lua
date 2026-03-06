--[[ 
    ESP + Triggerbot (L toggle, V hold) + Kill Button + ESP Settings (Photoshop-style) + Resizable UI
    L = Arm/Disarm system (ESP + Trigger)
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
    Enabled = false,
    Armed = false,
    Pixels = {},
    FillColor = Color3.fromRGB(255,0,0),
    OutlineColor = Color3.fromRGB(255,255,255)
}

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

    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return Color3.new(r + m, g + m, b + m)
end

local function RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local d = max - min

    local h = 0
    if d == 0 then
        h = 0
    elseif max == r then
        h = 60 * (((g - b) / d) % 6)
    elseif max == g then
        h = 60 * (((b - r) / d) + 2)
    elseif max == b then
        h = 60 * (((r - g) / d) + 4)
    end

    local s = (max == 0) and 0 or (d / max)
    local v = max

    return h, s, v
end

local function ColorToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function HexToColor(hex)
    hex = tostring(hex or ""):gsub("#","")
    if #hex ~= 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2),16) or 255
    local g = tonumber(hex:sub(3,4),16) or 255
    local b = tonumber(hex:sub(5,6),16) or 255
    return Color3.fromRGB(r,g,b)
end

------------------------------------------------------------------
-- UI (COMPACT, MODULAR STYLE)
------------------------------------------------------------------

local screenGui, mainFrame, resizeHandle
local mainTab, debugTab, settingsTab
local mainContent, debugContent, settingsContent
local espToggle, stateLabel, killButton
local svSquare, hueBar, preview
local rBox, gBox, bBox, hexBox
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

    -- Settings content
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

    svSquare = Instance.new("Frame")
    svSquare.Size = UDim2.new(0,130,0,130)
    svSquare.Position = UDim2.new(0,10,0,10)
    svSquare.BackgroundColor3 = Color3.fromRGB(255,0,0)
    svSquare.BorderSizePixel = 0
    svSquare.Parent = pickerFrame

    hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(0,20,0,130)
    hueBar.Position = UDim2.new(0,150,0,10)
    hueBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = pickerFrame

    preview = Instance.new("Frame")
    preview.Size = UDim2.new(0,40,0,40)
    preview.Position = UDim2.new(0,150,0,145)
    preview.BackgroundColor3 = ESP.FillColor
    preview.BorderSizePixel = 0
    preview.Parent = pickerFrame
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0,4)

    local rgbLabel = Instance.new("TextLabel")
    rgbLabel.Size = UDim2.new(0,120,0,20)
    rgbLabel.Position = UDim2.new(0,230,0,5)
    rgbLabel.BackgroundTransparency = 1
    rgbLabel.TextColor3 = Color3.fromRGB(255,255,255)
    rgbLabel.TextScaled = true
    rgbLabel.Text = "RGB"
    rgbLabel.Parent = settingsContent

    rBox = Instance.new("TextBox")
    rBox.Size = UDim2.new(0,60,0,22)
    rBox.Position = UDim2.new(0,230,0,30)
    rBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    rBox.TextColor3 = Color3.fromRGB(255,255,255)
    rBox.TextScaled = true
    rBox.Text = "255"
    rBox.Parent = settingsContent

    gBox = rBox:Clone()
    gBox.Position = UDim2.new(0,230,0,58)
    gBox.Text = "0"
    gBox.Parent = settingsContent

    bBox = rBox:Clone()
    bBox.Position = UDim2.new(0,230,0,86)
    bBox.Text = "0"
    bBox.Parent = settingsContent

    local hexLabel = rgbLabel:Clone()
    hexLabel.Text = "HEX"
    hexLabel.Position = UDim2.new(0,230,0,114)
    hexLabel.Parent = settingsContent

    hexBox = rBox:Clone()
    hexBox.Position = UDim2.new(0,230,0,139)
    hexBox.Text = "#FF0000"
    hexBox.Parent = settingsContent

    applyFill = Instance.new("TextButton")
    applyFill.Size = UDim2.new(0,120,0,24)
    applyFill.Position = UDim2.new(0,230,0,170)
    applyFill.BackgroundColor3 = Color3.fromRGB(60,120,60)
    applyFill.TextColor3 = Color3.fromRGB(255,255,255)
    applyFill.TextScaled = true
    applyFill.Text = "Apply to Fill"
    applyFill.BorderSizePixel = 0
    applyFill.Parent = settingsContent
    Instance.new("UICorner", applyFill).CornerRadius = UDim.new(0,4)

    applyOutline = applyFill:Clone()
    applyOutline.Text = "Apply to Outline"
    applyOutline.Position = UDim2.new(0,230,0,198)
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
-- RESIZABLE UI (SMOOTH)
------------------------------------------------------------------

do
    local resizing = false
    local startPos, startSize

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startPos = UserInputService:GetMouseLocation()
            startSize = mainFrame.Size
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentPos = UserInputService:GetMouseLocation()
            local dx = currentPos.X - startPos.X
            local dy = currentPos.Y - startPos.Y

            local newW = math.max(300, startSize.X.Offset + dx)
            local newH = math.max(220, startSize.Y.Offset + dy)

            mainFrame.Size = UDim2.new(0,newW,0,newH)
        end
    end)
end

------------------------------------------------------------------
-- COLOR PICKER LOGIC
------------------------------------------------------------------

local currentHue = 0
local currentS = 1
local currentV = 1

local function updateFromHSV()
    local color = HSVToRGB(currentHue, currentS, currentV)
    preview.BackgroundColor3 = color

    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)

    rBox.Text = tostring(r)
    gBox.Text = tostring(g)
    bBox.Text = tostring(b)
    hexBox.Text = ColorToHex(color)

    svSquare.BackgroundColor3 = HSVToRGB(currentHue, 1, 1)
end

updateFromHSV()

svSquare.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = i.Position - svSquare.AbsolutePosition
                local sx = math.clamp(rel.X / svSquare.AbsoluteSize.X, 0, 1)
                local sy = math.clamp(rel.Y / svSquare.AbsoluteSize.Y, 0, 1)
                currentS = sx
                currentV = 1 - sy
                updateFromHSV()
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(i2)
            if i2.UserInputType == Enum.UserInputType.MouseButton1 then
                if moveConn then moveConn:Disconnect() end
                if endConn then endConn:Disconnect() end
            end
        end)
    end
end)

hueBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = i.Position - hueBar.AbsolutePosition
                local t = math.clamp(rel.Y / hueBar.AbsoluteSize.Y, 0, 1)
                currentHue = t * 360
                updateFromHSV()
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(i2)
            if i2.UserInputType == Enum.UserInputType.MouseButton1 then
                if moveConn then moveConn:Disconnect() end
                if endConn then endConn:Disconnect() end
            end
        end)
    end
end)

local function applyRGBBoxes()
    local r = math.clamp(tonumber(rBox.Text) or 255,0,255)
    local g = math.clamp(tonumber(gBox.Text) or 0,0,255)
    local b = math.clamp(tonumber(bBox.Text) or 0,0,255)
    local color = Color3.fromRGB(r,g,b)
    preview.BackgroundColor3 = color
    hexBox.Text = ColorToHex(color)
    currentHue, currentS, currentV = RGBToHSV(color)
    updateFromHSV()
end

rBox.FocusLost:Connect(applyRGBBoxes)
gBox.FocusLost:Connect(applyRGBBoxes)
bBox.FocusLost:Connect(applyRGBBoxes)

hexBox.FocusLost:Connect(function()
    local color = HexToColor(hexBox.Text)
    preview.BackgroundColor3 = color
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    rBox.Text = tostring(r)
    gBox.Text = tostring(g)
    bBox.Text = tostring(b)
    currentHue, currentS, currentV = RGBToHSV(color)
    updateFromHSV()
end)

local function UpdateESPColors()
    for _, highlight in pairs(ESP.Pixels) do
        highlight.FillColor = ESP.FillColor
        highlight.OutlineColor = ESP.OutlineColor
    end
end

applyFill.MouseButton1Click:Connect(function()
    ESP.FillColor = preview.BackgroundColor3
    UpdateESPColors()
end)

applyOutline.MouseButton1Click:Connect(function()
    ESP.OutlineColor = preview.BackgroundColor3
    UpdateESPColors()
end)

------------------------------------------------------------------
-- ESP FUNCTIONS
------------------------------------------------------------------

function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = self.FillColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = self.OutlineColor
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    self.Pixels[character] = highlight
end

function ESP:RemovePixel(character)
    if character and self.Pixels[character] then
        self.Pixels[character]:Destroy()
        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()
    for _, h in pairs(self.Pixels) do
        h:Destroy()
    end
    self.Pixels = {}
end

function ESP:Update()
    if not self.Enabled or not self.Armed then
        self:ClearAll()
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if not self.Pixels[char] then
                    self:CreatePixel(char)
                end
            else
                self:RemovePixel(char)
            end
        end
    end
end

------------------------------------------------------------------
-- KILL SCRIPT
------------------------------------------------------------------

local function KillScript()
    Running = false
    ESP:ClearAll()
    if screenGui then
        screenGui:Destroy()
    end
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
end

table.insert(Connections, killButton.MouseButton1Click:Connect(KillScript))

------------------------------------------------------------------
-- UI TOGGLE + ESP BUTTON
------------------------------------------------------------------

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if mainFrame then
            mainFrame.Visible = not mainFrame.Visible
        end
    end
end))

table.insert(Connections, espToggle.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
    if not ESP.Enabled then
        ESP:ClearAll()
    end
end))

------------------------------------------------------------------
-- INPUT: L (ARM), V (HOLD)
------------------------------------------------------------------

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.L then
        ESP.Armed = not ESP.Armed
        if ESP.Armed then
            TriggerState = "ARMED"
        else
            TriggerState = "DISARMED"
            ESP:ClearAll()
        end
    end

    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = true
        if ESP.Armed then
            TriggerState = "HOLDING"
        end
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = false
        if ESP.Armed then
            TriggerState = "ARMED"
        else
            TriggerState = "DISARMED"
        end
    end
end))

------------------------------------------------------------------
-- TRIGGERBOT (STRICT, PLAYER-ONLY, ORIGINAL STYLE)
------------------------------------------------------------------

local clicked = false

local function DetectCenterTarget()
    if not ESP.Armed then
        TriggerState = "DISARMED"
        clicked = false
        return
    end

    if not TriggerHeld then
        TriggerState = "ARMED"
        clicked = false
        return
    end

    TriggerState = "HOLDING"

    if not Camera then
        Camera = workspace.CurrentCamera
        if not Camera then return end
    end

    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    local ray = Camera:ViewportPointToRay(centerX, centerY)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

    if result and result.Instance then
        local part = result.Instance
        local model = part:FindFirstAncestorOfClass("Model")

        if model then
            local playerHit = Players:GetPlayerFromCharacter(model)
            if playerHit and playerHit ~= LocalPlayer then
                TriggerState = "LOCKED & FIRING"

                if not clicked then
                    clicked = true
                    mouse1press()
                    task.wait()
                    mouse1release()
                end

                return
            end
        end
    end

    TriggerState = "HOLDING"
    clicked = false
end

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Running then return end
    ESP:Update()
    DetectCenterTarget()
    if stateLabel then
        stateLabel.Text = "Trigger state: " .. TriggerState
    end
end))
