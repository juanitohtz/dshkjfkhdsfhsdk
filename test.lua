--[[ 
    ESP + Triggerbot (L toggle, V hold) + Kill Button + ESP Settings Tab
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
-- UI
------------------------------------------------------------------

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,300,0,260)
    mainFrame.Position = UDim2.new(0,20,0,20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "ESP + Triggerbot"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,-10,0,26)
    tabBar.Position = UDim2.new(0,5,0,32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(1/3,-5,1,0)
    mainTab.Position = UDim2.new(0,0,0,0)
    mainTab.BackgroundColor3 = Color3.fromRGB(50,50,50)
    mainTab.TextColor3 = Color3.fromRGB(255,255,255)
    mainTab.TextScaled = true
    mainTab.Text = "Main"
    mainTab.BorderSizePixel = 0
    mainTab.Parent = tabBar
    Instance.new("UICorner", mainTab).CornerRadius = UDim.new(0,6)

    local debugTab = Instance.new("TextButton")
    debugTab.Size = UDim2.new(1/3,-5,1,0)
    debugTab.Position = UDim2.new(1/3,5,0,0)
    debugTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
    debugTab.TextColor3 = Color3.fromRGB(200,200,200)
    debugTab.TextScaled = true
    debugTab.Text = "Debug"
    debugTab.BorderSizePixel = 0
    debugTab.Parent = tabBar
    Instance.new("UICorner", debugTab).CornerRadius = UDim.new(0,6)

    local settingsTab = Instance.new("TextButton")
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
    local mainContent = Instance.new("Frame")
    mainContent.Size = UDim2.new(1,-10,1,-90)
    mainContent.Position = UDim2.new(0,5,0,60)
    mainContent.BackgroundTransparency = 1
    mainContent.Name = "MainContent"
    mainContent.Parent = mainFrame

    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0,230,0,36)
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

    local killButton = Instance.new("TextButton")
    killButton.Size = UDim2.new(0,230,0,30)
    killButton.Position = UDim2.new(0,20,1,-35)
    killButton.BackgroundColor3 = Color3.fromRGB(150,40,40)
    killButton.TextColor3 = Color3.fromRGB(255,255,255)
    killButton.TextScaled = true
    killButton.Text = "KILL SCRIPT"
    killButton.BorderSizePixel = 0
    killButton.Parent = mainContent
    Instance.new("UICorner", killButton).CornerRadius = UDim.new(0,6)

    -- Debug content
    local debugContent = Instance.new("Frame")
    debugContent.Size = UDim2.new(1,-10,1,-90)
    debugContent.Position = UDim2.new(0,5,0,60)
    debugContent.BackgroundTransparency = 1
    debugContent.Name = "DebugContent"
    debugContent.Visible = false
    debugContent.Parent = mainFrame

    local stateLabel = Instance.new("TextLabel")
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

    -- ESP SETTINGS TAB
    local settingsContent = Instance.new("Frame")
    settingsContent.Size = UDim2.new(1,-10,1,-90)
    settingsContent.Position = UDim2.new(0,5,0,60)
    settingsContent.BackgroundTransparency = 1
    settingsContent.Name = "SettingsContent"
    settingsContent.Visible = false
    settingsContent.Parent = mainFrame

    local fillLabel = Instance.new("TextLabel")
    fillLabel.Size = UDim2.new(1,-10,0,20)
    fillLabel.Position = UDim2.new(0,5,0,5)
    fillLabel.BackgroundTransparency = 1
    fillLabel.TextColor3 = Color3.fromRGB(255,255,255)
    fillLabel.TextScaled = true
    fillLabel.Text = "Fill Color (RGB)"
    fillLabel.Parent = settingsContent

    local function makeBox(x, y, default)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0,60,0,25)
        box.Position = UDim2.new(0,x,0,y)
        box.BackgroundColor3 = Color3.fromRGB(60,60,60)
        box.TextColor3 = Color3.fromRGB(255,255,255)
        box.TextScaled = true
        box.Text = tostring(default)
        box.Parent = settingsContent
        return box
    end

    local fillR = makeBox(5,30,255)
    local fillG = makeBox(75,30,0)
    local fillB = makeBox(145,30,0)

    local outlineLabel = fillLabel:Clone()
    outlineLabel.Text = "Outline Color (RGB)"
    outlineLabel.Position = UDim2.new(0,5,0,70)
    outlineLabel.Parent = settingsContent

    local outR = makeBox(5,95,255)
    local outG = makeBox(75,95,255)
    local outB = makeBox(145,95,255)

    -- TAB SWITCHING
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

    return screenGui, mainFrame, espToggle, stateLabel, killButton,
           fillR, fillG, fillB, outR, outG, outB
end

local screenGui, mainFrame, espToggle, stateLabel, killButton,
      fillR, fillG, fillB, outR, outG, outB = createUI()

------------------------------------------------------------------
-- ESP COLOR UPDATE
------------------------------------------------------------------

local function UpdateESPColors()
    local r1 = tonumber(fillR.Text) or 255
    local g1 = tonumber(fillG.Text) or 0
    local b1 = tonumber(fillB.Text) or 0

    local r2 = tonumber(outR.Text) or 255
    local g2 = tonumber(outG.Text) or 255
    local b2 = tonumber(outB.Text) or 255

    ESP.FillColor = Color3.fromRGB(r1,g1,b1)
    ESP.OutlineColor = Color3.fromRGB(r2,g2,b2)

    for _, highlight in pairs(ESP.Pixels) do
        highlight.FillColor = ESP.FillColor
        highlight.OutlineColor = ESP.OutlineColor
    end
end

local function connectBox(box)
    box.FocusLost:Connect(UpdateESPColors)
end

connectBox(fillR)
connectBox(fillG)
connectBox(fillB)
connectBox(outR)
connectBox(outG)
connectBox(outB)

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
                TriggerState = "LOCKED
