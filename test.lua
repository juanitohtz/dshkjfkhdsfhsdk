--[[ 
    Roblox ESP + Triggerbot System
    Controls:
        L = Toggle ESP
        Hold V = Triggerbot
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// UI Creation
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,260,0,180)
    mainFrame.Position = UDim2.new(0,20,0,20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(35,35,35)
    title.Text = "ESP Highlight System"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame

    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0,220,0,40)
    espToggle.Position = UDim2.new(0,20,0,45)
    espToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    espToggle.TextColor3 = Color3.fromRGB(255,255,255)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: OFF"
    espToggle.BorderSizePixel = 0
    espToggle.Parent = mainFrame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,20)
    info.Position = UDim2.new(0,5,1,-25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.Text = "Press L to toggle ESP | Hold V to trigger"
    info.Parent = mainFrame

    return espToggle
end

local espToggle = createUI()

--// ESP System
local ESP = {
    Enabled = false,      -- UI toggle
    ToggleActive = false, -- Keybind toggle (L)
    Highlights = {}
}

function ESP:CreateHighlight(character)
    if not character or self.Highlights[character] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = workspace

    self.Highlights[character] = highlight
end

function ESP:RemoveHighlight(character)
    if character and self.Highlights[character] then
        self.Highlights[character]:Destroy()
        self.Highlights[character] = nil
    end
end

function ESP:ClearAll()
    for _, highlight in pairs(self.Highlights) do
        highlight:Destroy()
    end
    self.Highlights = {}
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
                if not self.Highlights[char] then
                    self:CreateHighlight(char)
                end
            else
                self:RemoveHighlight(char)
            end
        end
    end
end

--// UI Toggle (Button)
espToggle.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
    if not ESP.Enabled then
        ESP:ClearAll()
    end
end)

------------------------------------------------------------------
-- INPUT SYSTEM (L TOGGLE ESP, HOLD V FOR TRIGGERBOT)
------------------------------------------------------------------

local TriggerHeld = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- L toggles ESP active state
    if input.KeyCode == Enum.KeyCode.L then
        ESP.ToggleActive = not ESP.ToggleActive
        if not ESP.ToggleActive then
            ESP:ClearAll()
        end
    end

    -- Hold V for triggerbot
    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    -- Release V stops triggerbot
    if input.KeyCode == Enum.KeyCode.V then
        TriggerHeld = false
    end
end)

------------------------------------------------------------------
-- CENTER SCREEN TRIGGERBOT (RAYCAST)
------------------------------------------------------------------

local clicked = false

local function DetectCenterTarget()
    if not ESP.Enabled or not ESP.ToggleActive or not TriggerHeld then
        clicked = false
        return
    end

    local center = Camera.ViewportSize / 2
    local ray = Camera:ViewportPointToRay(center.X, center.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and Players:GetPlayerFromCharacter(model) then
            if not clicked then
                clicked = true

                -- Simulated mouse click at screen center
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
            end
            return
        end
    end

    clicked = false
end

--// Main loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterTarget()
end)
