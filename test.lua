--[[ 
    Roblox ESP + Triggerbot System
    Controls:
        L = Toggle ESP system
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
-- UI CREATION (CLEANER + TOGGLEABLE)
------------------------------------------------------------------

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,260,0,160)
    mainFrame.Position = UDim2.new(0,20,0,20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,32)
    title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    title.Text = "ESP + Triggerbot"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame

    Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0,220,0,40)
    espToggle.Position = UDim2.new(0,20,0,50)
    espToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    espToggle.TextColor3 = Color3.fromRGB(255,255,255)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: OFF"
    espToggle.BorderSizePixel = 0
    espToggle.Parent = mainFrame

    Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0,6)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,20)
    info.Position = UDim2.new(0,5,1,-25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.Text = "L = Toggle ESP | Hold V = Trigger | RightShift = Hide UI"
    info.Parent = mainFrame

    return screenGui, mainFrame, espToggle
end

local screenGui, mainFrame, espToggle = createUI()

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
ESP.Enabled = false        -- UI toggle
ESP.ToggleActive = false   -- L key toggle
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
        if not ESP.ToggleActive then ESP:ClearAll() end
    end

    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = false
    end
end)

------------------------------------------------------------------
-- TRIGGERBOT (WORKS EVEN IF ESP IS OFF)
------------------------------------------------------------------

local clicked = false

local function DetectCenterTarget()
    if not ESP.ToggleActive or not TriggerHeld then
        clicked = false
        return
    end

    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    local ray = Camera:ViewportPointToRay(centerX, centerY)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then
            if not clicked then
                clicked = true
                mouse1press()
                task.wait()
                mouse1release()
            end
            return
        end
    end

    clicked = false
end

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterTarget()
end)
