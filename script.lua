--[[
    Roblox ESP Pixel Overlay System
    --------------------------------
    Features:
    - UI menu with toggle button
    - ESP pixels above all other players
    - Larger, more visible pixels with outline
    - HOLD V keybind: ESP only works while V is held
    - Uses only Roblox APIs (safe & allowed)
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// UI Creation
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 240, 0, 140)
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

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 200, 0, 45)
    toggleButton.Position = UDim2.new(0, 20, 0, 45)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Text = "ESP: OFF"
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = mainFrame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -10, 0, 20)
    info.Position = UDim2.new(0, 5, 1, -25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.TextScaled = true
    info.Text = "Hold V to activate ESP"
    info.Parent = mainFrame

    return toggleButton
end

local toggleButton = createUI()

--// ESP System
local ESP = {}
ESP.Enabled = false
ESP.Pixels = {}
ESP.Color = Color3.fromRGB(255, 0, 0)
ESP.PixelSize = 14 -- Bigger & more visible
ESP.HoldKeyActive = false

-- Create pixel above head
function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, self.PixelSize, 0, self.PixelSize)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = self.Color
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255, 255, 255)
    outline.Parent = frame

    self.Pixels[character] = billboard
end

-- Remove pixel
function ESP:RemovePixel(character)
    if self.Pixels[character] then
        self.Pixels[character]:Destroy()
        self.Pixels[character] = nil
    end
end

-- Clear all
function ESP:ClearAll()
    for char, gui in pairs(self.Pixels) do
        gui:Destroy()
    end
    self.Pixels = {}
end

-- Update loop
function ESP:Update()
    if not self.Enabled or not self.HoldKeyActive then
        self:ClearAll()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Head") then
                self:CreatePixel(char)
            else
                self:RemovePixel(char)
            end
        end
    end
end

--// UI Toggle
toggleButton.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    toggleButton.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"

    if not ESP.Enabled then
        ESP:ClearAll()
    end
end)

--// HOLD V keybind
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

--// Main loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
end)

print("[ESP_UI] Loaded successfully.")
