--[[
    Simple Character ESP Pixel Overlay with UI Toggle
    ------------------------------------------------
    - Draws tiny "pixels" above other players' heads
    - Toggle via on-screen button
    - Uses only Roblox APIs:
        * game.Players
        * workspace
        * RunService
    - Place this in StarterPlayerScripts or run as a LocalScript
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Main UI Setup
local function createMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 120)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Title bar
    local titleBar = Instance.new("TextLabel")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Text = "ESP Pixel Overlay"
    titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleBar.TextScaled = true
    titleBar.Parent = mainFrame

    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 180, 0, 40)
    toggleButton.Position = UDim2.new(0, 20, 0, 40)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Text = "ESP: OFF"
    toggleButton.Parent = mainFrame

    -- Info label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -10, 0, 20)
    infoLabel.Position = UDim2.new(0, 5, 1, -25)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    infoLabel.TextScaled = true
    infoLabel.Text = "Shows pixels above other players"
    infoLabel.Parent = mainFrame

    return screenGui, mainFrame, toggleButton
end

--// ESP Manager
local ESP = {}
ESP.Enabled = false
ESP.Pixels = {} -- [Character] = BillboardGui
ESP.Color = Color3.fromRGB(255, 0, 0)
ESP.PixelSize = 4

-- Create a pixel above a character's head
function ESP:CreatePixel(character)
    if not character or self.Pixels[character] then
        return
    end

    local head = character:FindFirstChild("Head")
    if not head then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Pixel"
    billboard.Size = UDim2.new(0, self.PixelSize, 0, self.PixelSize)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Pixel"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = self.Color
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    self.Pixels[character] = billboard
end

-- Remove pixel for a character
function ESP:RemovePixel(character)
    local gui = self.Pixels[character]
    if gui then
        gui:Destroy()
        self.Pixels[character] = nil
    end
end

-- Clear all pixels
function ESP:ClearAll()
    for character, gui in pairs(self.Pixels) do
        if gui then
            gui:Destroy()
        end
    end
    self.Pixels = {}
end

-- Update loop: ensure pixels exist for all other players
function ESP:Update()
    if not self.Enabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                self:CreatePixel(character)
            else
                self:RemovePixel(character)
            end
        end
    end
end

-- Handle character removal
local function onCharacterRemoving(character)
    ESP:RemovePixel(character)
end

-- Connect character removing for all players
local function hookPlayer(player)
    player.CharacterRemoving:Connect(onCharacterRemoving)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        hookPlayer(plr)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        hookPlayer(player)
    end
end)

--// UI + Logic Wiring
local screenGui, mainFrame, toggleButton = createMainUI()

toggleButton.MouseButton1Click:Connect(function()
    ESP.Enabled = not ESP.Enabled
    toggleButton.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"

    if not ESP.Enabled then
        ESP:ClearAll()
    end
end)

--// Main Render Loop
RunService.RenderStepped:Connect(function()
    ESP:Update()
end)

-- Optional: initial log
print("[ESP_UI] Loaded ESP Pixel Overlay for", LocalPlayer.Name)
