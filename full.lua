--[[
ESP + Triggerbot (L toggle, V hold)
+ Kill Button
+ ESP Settings (HTMLColorCodes-style)
+ Resizable UI

L = Arm/Disarm ESP system
Hold V = Triggerbot (independent of ESP arm)
RightShift = Toggle UI visibility
]]

------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

local Running = true
local Connections = {}

local ESP = {
    Enabled = false,
    Armed = false,
    Pixels = {},
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 255)
}

local TriggerHeld = false
local TriggerState = "DISARMED"
local clicked = false

------------------------------------------------------------------
-- SETTINGS SYSTEM
------------------------------------------------------------------

local Settings = {
    ESPEnabled = false,
    ESPArmed = false,
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    UISizeX = 360,
    UISizeY = 260
}

local function SaveSettings()
    Settings.ESPEnabled = ESP.Enabled
    Settings.ESPArmed = ESP.Armed
    Settings.FillColor = ESP.FillColor
    Settings.OutlineColor = ESP.OutlineColor

    if mainFrame then
        Settings.UISizeX = mainFrame.Size.X.Offset
        Settings.UISizeY = mainFrame.Size.Y.Offset
    end
end

local function LoadSettings()
    ESP.Enabled = Settings.ESPEnabled
    ESP.Armed = Settings.ESPArmed
    ESP.FillColor = Settings.FillColor
    ESP.OutlineColor = Settings.OutlineColor
end

------------------------------------------------------------------
-- COLOR HELPERS
------------------------------------------------------------------

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local r, g, b = 0, 0, 0

    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return Color3.new(r + m, g + m, b + m)
end

local function RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local d = max - min

    local h = 0

    if d == 0 then
        h = 0
    elseif max == r then
        h = 60 * (((g - b) / d) % 6)
    elseif max == g then
        h = 60 * (((b - r) / d) + 2)
    elseif max == b then
        h = 60 * (((r - g) / d) + 4)
    end

    local s = (max == 0) and 0 or (d / max)
    local v = max

    return h, s, v
end

------------------------------------------------------------------
-- UI REFERENCES
------------------------------------------------------------------

local screenGui, mainFrame, resizeHandle

local mainTab
local debugTab
local settingsTab

local mainContent
local debugContent
local settingsContent

local espToggle
local stateLabel
local killButton

local svSquare
local hueBar
local preview

local applyFill
local applyOutline

local svSelector
local hueSelector

------------------------------------------------------------------
-- UI CREATION
------------------------------------------------------------------

local function createUI()

    LoadSettings()

    local function setDragging(state)
        if mainFrame then
            mainFrame.Draggable = state
        end
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")

    if pg then
        local old = pg:FindFirstChild("ESP_UI")
        if old then
            old:Destroy()
        end
    end

    --------------------------------------------------------------
    -- ScreenGui
    --------------------------------------------------------------

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_UI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    --------------------------------------------------------------
    -- Main Frame
    --------------------------------------------------------------

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 360, 0, 260)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

    --------------------------------------------------------------
    -- Resize Handle
    --------------------------------------------------------------

    resizeHandle = Instance.new("Frame")
    resizeHandle.Size = UDim2.new(0, 14, 0, 14)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, 0, 1, 0)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Parent = mainFrame

    Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 3)

    --------------------------------------------------------------
    -- Title
    --------------------------------------------------------------

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    title.Text = "ESP + Triggerbot"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BorderSizePixel = 0
    title.Parent = mainFrame

    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    --------------------------------------------------------------
    -- Tabs
    --------------------------------------------------------------

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -10, 0, 26)
    tabBar.Position = UDim2.new(0, 5, 0, 32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(1/3, -5, 1, 0)
    mainTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mainTab.Text = "Main"
    mainTab.TextScaled = true
    mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainTab.BorderSizePixel = 0
    mainTab.Parent = tabBar
    Instance.new("UICorner", mainTab).CornerRadius = UDim.new(0, 6)

    debugTab = mainTab:Clone()
    debugTab.Text = "Debug"
    debugTab.Position = UDim2.new(1/3, 5, 0, 0)
    debugTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    debugTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    debugTab.Parent = tabBar

    settingsTab = mainTab:Clone()
    settingsTab.Text = "ESP Settings"
    settingsTab.Position = UDim2.new(2/3, 10, 0, 0)
    settingsTab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    settingsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    settingsTab.Parent = tabBar

end

createUI()

------------------------------------------------------------------
-- ESP FUNCTIONS
------------------------------------------------------------------

function ESP:CreatePixel(character)

    if not character or self.Pixels[character] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = self.FillColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = self.OutlineColor
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    self.Pixels[character] = highlight
end

function ESP:RemovePixel(character)

    if character and self.Pixels[character] then
        self.Pixels[character]:Destroy()
        self.Pixels[character] = nil
    end
end

function ESP:ClearAll()

    for _, h in pairs(self.Pixels) do
        h:Destroy()
    end

    self.Pixels = {}
end

function ESP:Update()

    if not self.Enabled or not self.Armed then
        if next(self.Pixels) ~= nil then
            self:ClearAll()
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do

        if plr ~= LocalPlayer then

            local char = plr.Character

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
-- KILL SCRIPT
------------------------------------------------------------------

local function KillScript()

    Running = false
    ESP:ClearAll()

    if screenGui then
        screenGui:Destroy()
    end

    for _, conn in ipairs(Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
end

table.insert(Connections, killButton.MouseButton1Click:Connect(KillScript))

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------

table.insert(Connections,
    RunService.RenderStepped:Connect(function()

        if not Running then
            return
        end

        ESP:Update()

        if stateLabel then
            stateLabel.Text = "Trigger state: " .. TriggerState
        end

    end)
)
