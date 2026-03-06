--[[ Added: Center-Screen Red Pixel Auto-Click ]]--

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse() -- for center pixel GUI detection

--// UI Creation
local espToggle, colorToggle
do
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

        local espToggleBtn = Instance.new("TextButton")
        espToggleBtn.Size = UDim2.new(0, 220, 0, 40)
        espToggleBtn.Position = UDim2.new(0, 20, 0, 45)
        espToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        espToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        espToggleBtn.TextScaled = true
        espToggleBtn.Text = "ESP: OFF"
        espToggleBtn.BorderSizePixel = 0
        espToggleBtn.Parent = mainFrame

        local colorToggleBtn = Instance.new("TextButton")
        colorToggleBtn.Size = UDim2.new(0, 220, 0, 40)
        colorToggleBtn.Position = UDim2.new(0, 20, 0, 95)
        colorToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        colorToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        colorToggleBtn.TextScaled = true
        colorToggleBtn.Text = "Color Detection: OFF"
        colorToggleBtn.BorderSizePixel = 0
        colorToggleBtn.Parent = mainFrame

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -10, 0, 20)
        info.Position = UDim2.new(0, 5, 1, -25)
        info.BackgroundTransparency = 1
        info.TextColor3 = Color3.fromRGB(180, 180, 180)
        info.TextScaled = true
        info.Text = "Hold V to activate ESP"
        info.Parent = mainFrame

        return espToggleBtn, colorToggleBtn
    end

    espToggle, colorToggle = createUI()
end

--// ESP System
local ESP = {}
ESP.Enabled = false
ESP.ColorDetection = false
ESP.Pixels = {}
ESP.PixelSize = 14
ESP.HoldKeyActive = false

-- Create pixel on HumanoidRootPart
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
    billboard.SizeOffset = Vector2.new(0, 0)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = self.ColorDetection and root.Color or Color3.fromRGB(255, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255, 255, 255)
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
    for char, data in pairs(self.Pixels) do
        data.gui:Destroy()
    end
    self.Pixels = {}
end

function ESP:Update()
    if not self.Enabled or not self.HoldKeyActive then
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

                -- Update color if color detection is enabled
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

--// Center-Screen Red Pixel Auto-Click
local redColor = Color3.fromRGB(255, 0, 0)
local threshold = 0.1
local clicked = false

local function isRed(color)
    local dr = color.R - redColor.R
    local dg = color.G - redColor.G
    local db = color.B - redColor.B
    local dist = math.sqrt(dr*dr + dg*dg + db*db)
    return dist < threshold
end

local function clickGUI()
    local centerX = workspace.CurrentCamera.ViewportSize.X / 2
    local centerY = workspace.CurrentCamera.ViewportSize.Y / 2
    local guiObjects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(centerX, centerY)
    for _, gui in ipairs(guiObjects) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local color = gui:IsA("ImageButton") and gui.ImageColor3 or gui.BackgroundColor3
            if isRed(color) and not clicked then
                gui:Activate()
                clicked = true
                print("[Red Click] Activated button at center!")
            elseif not isRed(color) then
                clicked = false
            end
            break
        end
    end
end

--// Main loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
    clickGUI() -- check center pixel and auto-click
end)

print("[ESP_UI] Loaded successfully with Red Pixel Auto-Click.")
