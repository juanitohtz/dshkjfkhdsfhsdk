local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

local holdingV = false
local espEnabled = true

-- UI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,150,0,80)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = gui

local toggleESP = Instance.new("TextButton")
toggleESP.Size = UDim2.new(1,0,0.5,0)
toggleESP.Text = "ESP ON"
toggleESP.Parent = frame

local unload = Instance.new("TextButton")
unload.Size = UDim2.new(1,0,0.5,0)
unload.Position = UDim2.new(0,0,0.5,0)
unload.Text = "Unload"
unload.Parent = frame

-- ESP system
local ESP = {}
ESP.Pixels = {}

function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local originalColor = root.Color
    local originalMaterial = root.Material

    root.Color = Color3.fromRGB(255,0,0)
    root.Material = Enum.Material.Neon

    self.Pixels[character] = {
        root = root,
        originalColor = originalColor,
        originalMaterial = originalMaterial
    }
end

function ESP:RemovePixel(character)
    local data = self.Pixels[character]
    if data then
        if data.root then
            data.root.Color = data.originalColor
            data.root.Material = data.originalMaterial
        end
        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()
    for char,data in pairs(self.Pixels) do
        if data.root then
            data.root.Color = data.originalColor
            data.root.Material = data.originalMaterial
        end
    end
    self.Pixels = {}
end

-- Player scanning
task.spawn(function()
    while task.wait(1) do
        if espEnabled then
            for _,player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    ESP:CreatePixel(player.Character)
                end
            end
        end
    end
end)

-- Toggle ESP
toggleESP.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled

    if espEnabled then
        toggleESP.Text = "ESP ON"
    else
        toggleESP.Text = "ESP OFF"
        ESP:ClearAll()
    end
end)

-- Unload script
unload.MouseButton1Click:Connect(function()
    ESP:ClearAll()
    gui:Destroy()
end)

-- Key detection
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V then
        holdingV = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        holdingV = false
    end
end)

-- Triggerbot loop
task.spawn(function()
    while task.wait() do
        if holdingV and espEnabled then
            for char,data in pairs(ESP.Pixels) do
                if data.root then
                    local screenPos,visible = workspace.CurrentCamera:WorldToViewportPoint(data.root.Position)

                    if visible then
                        local centerX = workspace.CurrentCamera.ViewportSize.X/2
                        local centerY = workspace.CurrentCamera.ViewportSize.Y/2

                        local dist = (Vector2.new(screenPos.X,screenPos.Y) - Vector2.new(centerX,centerY)).Magnitude

                        if dist < 5 then
                            VIM:SendMouseButtonEvent(0,0,0,true,game,0)
                            task.wait()
                            VIM:SendMouseButtonEvent(0,0,0,false,game,0)
                        end
                    end
                end
            end
        end
    end
end)
