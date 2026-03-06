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

------------------------------------------------------------------
-- UI Creation
------------------------------------------------------------------

local function createUI()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0,260,0,210)
    mainFrame.Position = UDim2.new(0,20,0,20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(35,35,35)
    title.Text = "ESP Pixel Overlay"
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

    local unloadButton = Instance.new("TextButton")
    unloadButton.Size = UDim2.new(0,220,0,40)
    unloadButton.Position = UDim2.new(0,20,0,145)
    unloadButton.BackgroundColor3 = Color3.fromRGB(120,40,40)
    unloadButton.TextColor3 = Color3.fromRGB(255,255,255)
    unloadButton.TextScaled = true
    unloadButton.Text = "UNLOAD"
    unloadButton.BorderSizePixel = 0
    unloadButton.Parent = mainFrame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-10,0,20)
    info.Position = UDim2.new(0,5,1,-25)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextScaled = true
    info.Text = "Hold V to activate ESP"
    info.Parent = mainFrame

    return espToggle,colorToggle,unloadButton,screenGui
end

local espToggle,colorToggle,unloadButton,screenGui = createUI()

------------------------------------------------------------------
-- ESP SYSTEM
------------------------------------------------------------------

local ESP = {}
ESP.Enabled = false
ESP.ColorDetection = false
ESP.Pixels = {}
ESP.PixelSize = 14
ESP.HoldKeyActive = false

function ESP:CreatePixel(character)

    if not character or self.Pixels[character] then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- COLOR THE HRP
    root.Color = Color3.fromRGB(255,0,0)
    root.Material = Enum.Material.Neon

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Pixel"
    billboard.Size = UDim2.new(0,self.PixelSize,0,self.PixelSize)
    billboard.AlwaysOnTop = true
    billboard.Adornee = root
    billboard.MaxDistance = math.huge
    billboard.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.fromRGB(255,0,0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local outline = Instance.new("UIStroke")
    outline.Thickness = 2
    outline.Color = Color3.fromRGB(255,255,255)
    outline.Parent = frame

    self.Pixels[character] = {gui=billboard,frame=frame,root=root}

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

            else
                self:RemovePixel(char)
            end

        end
    end

end

------------------------------------------------------------------
-- UI TOGGLES
------------------------------------------------------------------

espToggle.MouseButton1Click:Connect(function()

    ESP.Enabled = not ESP.Enabled
    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"

    if not ESP.Enabled then
        ESP:ClearAll()
    end

end)

colorToggle.MouseButton1Click:Connect(function()

    ESP.ColorDetection = not ESP.ColorDetection
    colorToggle.Text = ESP.ColorDetection and "Color Detection: ON" or "Color Detection: OFF"

end)

------------------------------------------------------------------
-- UNLOAD BUTTON
------------------------------------------------------------------

local unloaded = false

unloadButton.MouseButton1Click:Connect(function()

    unloaded = true

    ESP:ClearAll()
    screenGui:Destroy()

end)

------------------------------------------------------------------
-- HOLD V
------------------------------------------------------------------

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
-- RED PIXEL CENTER DETECTOR
------------------------------------------------------------------

local clicked = false
local centerMargin = 6

local function DetectCenterRedPixel()

    if unloaded then return end

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

                if color.R > 0.9 and color.G < 0.2 and color.B < 0.2 then

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

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------

RunService.RenderStepped:Connect(function()

    if unloaded then return end

    ESP:Update()
    DetectCenterRedPixel()

end)

print("[ESP_UI] Loaded successfully.")
