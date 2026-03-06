--[[
    Roblox HRP ESP + Center Triggerbot
    -----------------------------------
    Features:
    - UI menu
    - ESP colors enemy HumanoidRootPart red
    - Hold V to activate
    - Detects HRP in center of screen
    - Sends MB1 click
    - Unload button destroys everything
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------------
-- UI
------------------------------------------------------------------

local connections = {}
local ESP = {}
ESP.Enabled = false
ESP.HoldKeyActive = false
ESP.Targets = {}

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
title.Text = "ESP Trigger System"
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

local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(0,220,0,40)
unloadBtn.Position = UDim2.new(0,20,0,95)
unloadBtn.BackgroundColor3 = Color3.fromRGB(120,40,40)
unloadBtn.TextColor3 = Color3.fromRGB(255,255,255)
unloadBtn.TextScaled = true
unloadBtn.Text = "UNLOAD SCRIPT"
unloadBtn.BorderSizePixel = 0
unloadBtn.Parent = mainFrame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-10,0,20)
info.Position = UDim2.new(0,5,1,-25)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextScaled = true
info.Text = "Hold V to activate"
info.Parent = mainFrame

------------------------------------------------------------------
-- ESP HRP Coloring
------------------------------------------------------------------

function ESP:Apply(player)

    if player == LocalPlayer then return end

    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if self.Targets[player] then return end

    self.Targets[player] = {
        part = root,
        originalColor = root.Color,
        originalMaterial = root.Material
    }

    root.Color = Color3.fromRGB(255,0,0)
    root.Material = Enum.Material.Neon

end


function ESP:Clear()

    for player,data in pairs(self.Targets) do
        if data.part then
            data.part.Color = data.originalColor
            data.part.Material = data.originalMaterial
        end
    end

    self.Targets = {}

end

------------------------------------------------------------------
-- Triggerbot
------------------------------------------------------------------

local clicked = false
local centerMargin = 6

local function DetectCenter()

    if not ESP.Enabled or not ESP.HoldKeyActive then
        clicked = false
        return
    end

    local centerX = Camera.ViewportSize.X/2
    local centerY = Camera.ViewportSize.Y/2

    for _,data in pairs(ESP.Targets) do

        local pos,visible = Camera:WorldToViewportPoint(data.part.Position)

        if visible then

            local dx = math.abs(pos.X-centerX)
            local dy = math.abs(pos.Y-centerY)

            if dx <= centerMargin and dy <= centerMargin then

                if not clicked then

                    clicked = true

                    VirtualInputManager:SendMouseButtonEvent(
                        centerX,
                        centerY,
                        0,
                        true,
                        game,
                        0
                    )

                    VirtualInputManager:SendMouseButtonEvent(
                        centerX,
                        centerY,
                        0,
                        false,
                        game,
                        0
                    )

                end

                return
            end
        end
    end

    clicked = false
end

------------------------------------------------------------------
-- Input
------------------------------------------------------------------

table.insert(connections,
UserInputService.InputBegan:Connect(function(input,gpe)

    if gpe then return end

    if input.KeyCode == Enum.KeyCode.V then
        ESP.HoldKeyActive = true
    end

end))

table.insert(connections,
UserInputService.InputEnded:Connect(function(input)

    if input.KeyCode == Enum.KeyCode.V then
        ESP.HoldKeyActive = false
    end

end))

------------------------------------------------------------------
-- UI
------------------------------------------------------------------

espToggle.MouseButton1Click:Connect(function()

    ESP.Enabled = not ESP.Enabled

    espToggle.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"

    if not ESP.Enabled then
        ESP:Clear()
    end

end)

------------------------------------------------------------------
-- Unload
------------------------------------------------------------------

unloadBtn.MouseButton1Click:Connect(function()

    ESP:Clear()

    for _,c in pairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    if screenGui then
        screenGui:Destroy()
    end

end)

------------------------------------------------------------------
-- Main Loop
------------------------------------------------------------------

table.insert(connections,
RunService.RenderStepped:Connect(function()

    if ESP.Enabled and ESP.HoldKeyActive then

        for _,player in ipairs(Players:GetPlayers()) do
            ESP:Apply(player)
        end

    else
        ESP:Clear()
    end

    DetectCenter()

end))
