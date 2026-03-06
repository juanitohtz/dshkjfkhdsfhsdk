--[[ 
    Roblox ESP Pixel Overlay System
    Modified: Uses Highlight instead of Billboard pixels
    Updated: V toggles ESP, MB5 activates trigger
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
    info.Text = "Press V to toggle ESP | Hold MB5 to trigger"
    info.Parent = mainFrame

    return espToggle
end

local espToggle = createUI()

--// ESP System
local ESP = {}
ESP.Enabled = false
ESP.Pixels = {}
ESP.ToggleActive = false

local MB5Held = false

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

    if self.Pixels[character] then
        self.Pixels[character]:Destroy()
        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()

    for _,highlight in pairs(self.Pixels) do
        highlight:Destroy()
    end

    self.Pixels = {}
end

function ESP:Update()

    if not self.Enabled or not self.ToggleActive then
        self:ClearAll()
        return
    end

    for _,player in ipairs(Players:GetPlayers()) do

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

--// UI Toggle
espToggle.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
    if not ESP.Enabled then ESP:ClearAll() end
end)

--// INPUT SYSTEM

UserInputService.InputBegan:Connect(function(input,gp)

    if gp then return end

    if input.KeyCode == Enum.KeyCode.V then
        ESP.ToggleActive = not ESP.ToggleActive

        if not ESP.ToggleActive then
            ESP:ClearAll()
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton5 then
        MB5Held = true
    end

end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton5 then
        MB5Held = false
    end

end)

------------------------------------------------------------------
-- CROSSHAIR RAYCAST TRIGGERBOT (Reliable Version)
------------------------------------------------------------------

local function DetectCenterTarget()

    if not MB5Held then return end

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

        if model and Players:GetPlayerFromCharacter(model) then

            local character = LocalPlayer.Character
            if not character then return end

            local tool = character:FindFirstChildOfClass("Tool")

            if tool then
                tool:Activate()
            end

        end
    end
end
--// Main loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterTarget()
end)
