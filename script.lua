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

    local colorToggle = Instance.new("TextButton")
    colorToggle.Size = UDim2.new(0,220,0,40)
    colorToggle.Position = UDim2.new(0,20,0,95)
    colorToggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    colorToggle.TextColor3 = Color3.fromRGB(255,255,255)
    colorToggle.TextScaled = true
    colorToggle.Text = "Color Detection: OFF"
    colorToggle.BorderSizePixel = 0
    colorToggle.Parent = mainFrame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,20)
    info.Position = UDim2.new(0,5,1,-25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.Text = "Press V to toggle ESP | Hold MB5 to trigger"
    info.Parent = mainFrame

    return espToggle, colorToggle
end

local espToggle, colorToggle = createUI()

--// ESP System
local ESP = {}
ESP.Enabled = false
ESP.ColorDetection = false
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

    local root = character:FindFirstChild("HumanoidRootPart")

    self.Pixels[character] = {
        highlight = highlight,
        root = root
    }

end

function ESP:RemovePixel(character)

    if self.Pixels[character] then

        local data = self.Pixels[character]

        if data.highlight then
            data.highlight:Destroy()
        end

        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()

    for char,data in pairs(self.Pixels) do
        if data.highlight then
            data.highlight:Destroy()
        end
    end

    self.Pixels = {}
end

function ESP:Update()

    if not ESP.Enabled or not ESP.ToggleActive then
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

--// UI Toggles
espToggle.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
    if not ESP.Enabled then ESP:ClearAll() end
end)

colorToggle.MouseButton1Click:Connect(function()
    ESP.ColorDetection = not ESP.ColorDetection
    colorToggle.Text = ESP.ColorDetection and "Color Detection: ON" or "Color Detection: OFF"
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
-- CENTER SCREEN DETECTOR USING HIGHLIGHT BOUNDS
------------------------------------------------------------------

local clicked = false

local function DetectCenterRedPixel()

    if not MB5Held then
        clicked = false
        return
    end

    local centerX = Camera.ViewportSize.X/2
    local centerY = Camera.ViewportSize.Y/2

    for char,data in pairs(ESP.Pixels) do

        if char then

            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local visiblePart = false

            for _,part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then

                    local pos,visible = Camera:WorldToViewportPoint(part.Position)

                    if visible then
                        visiblePart = true

                        minX = math.min(minX,pos.X)
                        minY = math.min(minY,pos.Y)

                        maxX = math.max(maxX,pos.X)
                        maxY = math.max(maxY,pos.Y)
                    end
                end
            end

            if visiblePart then

                if centerX >= minX and centerX <= maxX and
                   centerY >= minY and centerY <= maxY then

                    if not clicked then
                        clicked = true

                        VirtualInputManager:SendMouseButtonEvent(centerX,centerY,0,true,game,0)
                        VirtualInputManager:SendMouseButtonEvent(centerX,centerY,0,false,game,0)

                    end

                    return
                end
            end
        end
    end

    clicked = false
end

--// Main loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterRedPixel()
end)

print("[ESP_UI] Loaded successfully.")
