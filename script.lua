--[[
    Roblox ESP Pixel Overlay System
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
    mainFrame.Size = UDim2.new(0, 260, 0, 180)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.Text = "ESP Pixel Overlay"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame

    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(0, 220, 0, 40)
    espToggle.Position = UDim2.new(0, 20, 0, 45)
    espToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: OFF"
    espToggle.BorderSizePixel = 0
    espToggle.Parent = mainFrame

    local colorToggle = Instance.new("TextButton")
    colorToggle.Size = UDim2.new(0, 220, 0, 40)
    colorToggle.Position = UDim2.new(0, 20, 0, 95)
    colorToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    colorToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorToggle.TextScaled = true
    colorToggle.Text = "Color Detection: OFF"
    colorToggle.BorderSizePixel = 0
    colorToggle.Parent = mainFrame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -10, 0, 20)
    info.Position = UDim2.new(0, 5, 1, -25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.TextScaled = true
    info.Text = "Hold V to activate ESP"
    info.Parent = mainFrame

    return espToggle, colorToggle
end

local espToggle, colorToggle = createUI()

--// ESP System
local ESP = {}
ESP.Enabled = false
ESP.ColorDetection = false
ESP.Pixels = {}
ESP.PixelSize = 75 -- 🔥 CHANGED (was 14)
ESP.HoldKeyActive = false

function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Pixel"
    billboard.Size = UDim2.new(0, self.PixelSize, 0, self.PixelSize)
    billboard.AlwaysOnTop = true
    billboard.Adornee = root
    billboard.MaxDistance = math.huge
    billboard.LightInfluence = 0
    billboard.SizeOffset = Vector2.new(0,0)
    billboard.StudsOffset = Vector3.new(0,0,0)
    billboard.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = self.ColorDetection and root.Color or Color3.fromRGB(255,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255,255,255)
    outline.Parent = frame

    self.Pixels[character] = {gui = billboard, frame = frame, root = root}
end

function ESP:RemovePixel(character)
    if self.Pixels[character] then
        self.Pixels[character].gui:Destroy()
        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()
    for char,data in pairs(self.Pixels) do
        data.gui:Destroy()
    end
    self.Pixels = {}
end

function ESP:Update()
    if not self.Enabled or not self.HoldKeyActive then
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

                if self.ColorDetection then
                    local root = self.Pixels[char].root
                    self.Pixels[char].frame.BackgroundColor3 = root.Color
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

--// HOLD V
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        ESP.HoldKeyActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        ESP.HoldKeyActive = false
        ESP:ClearAll()
    end
end)

------------------------------------------------------------------
-- CENTER SCREEN RED PIXEL DETECTOR
------------------------------------------------------------------

local clicked = false
local centerMargin = 6

local function DetectCenterRedPixel()

    if not ESP.Enabled or not ESP.HoldKeyActive then
        clicked = false
        return
    end

    local centerX = Camera.ViewportSize.X/2
    local centerY = Camera.ViewportSize.Y/2

    for _,data in pairs(ESP.Pixels) do

        local pos,visible = Camera:WorldToViewportPoint(data.root.Position)

        if visible then

            local dx = math.abs(pos.X-centerX)
            local dy = math.abs(pos.Y-centerY)

            if dx <= centerMargin and dy <= centerMargin then

                local color = data.frame.BackgroundColor3

                if color.R>0.9 and color.G<0.2 and color.B<0.2 then

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

    clicked=false
end

RunService.RenderStepped:Connect(function()
    ESP:Update()
    DetectCenterRedPixel()
end)

print("[ESP_UI] Loaded successfully.")
