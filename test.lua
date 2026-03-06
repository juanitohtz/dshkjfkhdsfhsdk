--[[ 
    Roblox ESP + Triggerbot System
    Controls:
        L = Toggle ESP system (arm/disarm)
        Hold V = Triggerbot
        RightShift = Toggle UI visibility
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------------
-- UI CREATION (TABS + DEBUG)
------------------------------------------------------------------

local TriggerState = "DISARMED" -- for debug tab

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,280,0,190)
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
    tabBar.Size = UDim2.new(1, -10, 0, 26)
    tabBar.Position = UDim2.new(0,5,0,32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(0.5, -5, 1, 0)
    mainTab.Position = UDim2.new(0,0,0,0)
    mainTab.BackgroundColor3 = Color3.fromRGB(50,50,50)
    mainTab.TextColor3 = Color3.fromRGB(255,255,255)
    mainTab.TextScaled = true
    mainTab.Text = "Main"
    mainTab.BorderSizePixel = 0
    mainTab.Parent = tabBar
    Instance.new("UICorner", mainTab).CornerRadius = UDim.new(0,6)

    local debugTab = Instance.new("TextButton")
    debugTab.Size = UDim2.new(0.5, -5, 1, 0)
    debugTab.Position = UDim2.new(0.5,5,0,0)
    debugTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
    debugTab.TextColor3 = Color3.fromRGB(200,200,200)
    debugTab.TextScaled = true
    debugTab.Text = "Debug"
    debugTab.BorderSizePixel = 0
    debugTab.Parent = tabBar
    Instance.new("UICorner", debugTab).CornerRadius = UDim.new(0,6)

    -- Main content
    local mainContent = Instance.new("Frame")
    mainContent.Size = UDim2.new(1,-10,1,-65)
    mainContent.Position = UDim2.new(0,5,0,60)
    mainContent.BackgroundTransparency = 1
    mainContent.Name = "MainContent"
    mainContent.Parent = mainFrame

    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0,230,0,40)
    espToggle.Position = UDim2.new(0,20,0,10)
    espToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    espToggle.TextColor3 = Color3.fromRGB(255,255,255)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: OFF"
    espToggle.BorderSizePixel = 0
    espToggle.Parent = mainContent
    Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0,6)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,20)
    info.Position = UDim2.new(0,5,0,60)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.Text = "L = Toggle ESP | Hold V = Trigger | RightShift = Hide UI"
    info.Parent = mainContent

    -- Debug content
    local debugContent = Instance.new("Frame")
    debugContent.Size = UDim2.new(1,-10,1,-65)
    debugContent.Position = UDim2.new(0,5,0,60)
    debugContent.BackgroundTransparency = 1
    debugContent.Name = "DebugContent"
    debugContent.Visible = false
    debugContent.Parent = mainFrame

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Size = UDim2.new(1,-10,0,30)
    stateLabel.Position = UDim2.new(0,5,0,10)
    stateLabel.BackgroundColor3 = Color3.fromRGB(35,35,35)
    stateLabel.TextColor3 = Color3.fromRGB(255,255,255)
    stateLabel.TextScaled = true
    stateLabel.Text = "Trigger state: " .. TriggerState
    stateLabel.BorderSizePixel = 0
    stateLabel.Parent = debugContent
    Instance.new("UICorner", stateLabel).CornerRadius = UDim.new(0,6)

    local debugInfo = Instance.new("TextLabel")
    debugInfo.Size = UDim2.new(1,-10,0,60)
    debugInfo.Position = UDim2.new(0,5,0,50)
    debugInfo.BackgroundTransparency = 1
    debugInfo.TextColor3 = Color3.fromRGB(200,200,200)
    debugInfo.TextScaled = true
    debugInfo.TextWrapped = true
    debugInfo.Text = "DISARMED: L off\nARMED: L on\nHOLDING: L on + V held\nLOCKED & FIRING: target in center"
    debugInfo.Parent = debugContent

    -- Tab switching
    local function setTab(mainActive)
        mainContent.Visible = mainActive
        debugContent.Visible = not mainActive

        if mainActive then
            mainTab.BackgroundColor3 = Color3.fromRGB(50,50,50)
            mainTab.TextColor3 = Color3.fromRGB(255,255,255)
            debugTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
            debugTab.TextColor3 = Color3.fromRGB(200,200,200)
        else
            mainTab.BackgroundColor3 = Color3.fromRGB(35,35,35)
            mainTab.TextColor3 = Color3.fromRGB(200,200,200)
            debugTab.BackgroundColor3 = Color3.fromRGB(50,50,50)
            debugTab.TextColor3 = Color3.fromRGB(255,255,255)
        end
    end

    mainTab.MouseButton1Click:Connect(function()
        setTab(true)
    end)

    debugTab.MouseButton1Click:Connect(function()
        setTab(false)
    end)

    return screenGui, mainFrame, espToggle, stateLabel
end

local screenGui, mainFrame, espToggle, stateLabel = createUI()

local uiVisible = true

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        mainFrame.Visible = uiVisible
    end
end)

------------------------------------------------------------------
-- ESP SYSTEM
------------------------------------------------------------------

local ESP = {}
ESP.Enabled = false        -- UI toggle (visuals)
ESP.ToggleActive = false   -- L key toggle (system armed)
ESP.Pixels = {}

function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
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
    for _, highlight in pairs(self.Pixels) do
        highlight:Destroy()
    end
    self.Pixels = {}
end

function ESP:Update()
    if not self.Enabled or not self.ToggleActive then
        self:ClearAll()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
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
-- UI BUTTON TOGGLE
------------------------------------------------------------------

espToggle.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
    if not ESP.Enabled then ESP:ClearAll() end
end)

------------------------------------------------------------------
-- INPUT SYSTEM (L TOGGLE ESP, HOLD V FOR TRIGGERBOT)
------------------------------------------------------------------

local TriggerHeld = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.L then
        ESP.ToggleActive = not ESP.ToggleActive
        if not ESP.ToggleActive then
            ESP:ClearAll()
            TriggerState = "DISARMED"
        else
            TriggerState = "ARMED"
        end
    end

    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = true
        if ESP.ToggleActive then
            TriggerState = "HOLDING"
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = false
        if ESP.ToggleActive then
            TriggerState = "ARMED"
        else
            TriggerState = "DISARMED"
        end
    end
end)

------------------------------------------------------------------
-- TRIGGERBOT (WITH DEBUG STATE)
------------------------------------------------------------------

local clicked = false

local function DetectCenterTarget()
    if not ESP.ToggleActive then
        TriggerState = "DISARMED"
        clicked = false
        return
    end

    if not TriggerHeld then
        TriggerState = "ARMED"
        clicked = false
        return
    end

    if not Camera then
        Camera = workspace.CurrentCamera
        if not Camera then
            return
        end
    end

    TriggerState = "HOLDING"

    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    local ray = Camera:ViewportPointToRay(centerX, centerY)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {}
    if LocalPlayer.Character then
        params.FilterDescendantsInstances = {LocalPlayer.Character}
    end

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

    if result and result.Instance then
        local part = result.Instance
        local model = part:FindFirstAncestorOfClass("Model")
        local playerHit = model and Players:GetPlayerFromCharacter(model)

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

    TriggerState = "HOLDING"
    clicked = false
end

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterTarget()
    if stateLabel then
        stateLabel.Text = "Trigger state: " .. TriggerState
    end
end)
