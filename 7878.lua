local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Config = {
    AimbotEnabled = false,
    ESPEnabled = false,
    AimSmoothness = 0.2,
    FOVRadius = 120,
    FOVColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = true,
    WallCheck = true,
    ESPTeamCheck = true,
    AimKey = Enum.KeyCode.E,
}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Transparency = 0.9
FOVCircle.Color = Config.FOVColor
FOVCircle.Radius = Config.FOVRadius
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.FOVRadius
    FOVCircle.Color = Config.FOVColor
    FOVCircle.Visible = Config.AimbotEnabled
end)
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true

local function hasLineOfSight(targetChar)
    if not Config.WallCheck then return true end
    if not LocalPlayer.Character then return false end
    local filter = { LocalPlayer.Character, targetChar }
    local teamInd = workspace:FindFirstChild("TeamIndicators")
    if teamInd then table.insert(filter, teamInd) end
    wallParams.FilterDescendantsInstances = filter
    local origin = Camera.CFrame.Position
    local direction = (targetChar.HumanoidRootPart.Position - origin)
    local result = workspace:Raycast(origin, direction, wallParams)
    return result == nil
end

local function isSameTeam(player)
    if not Config.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end
local function getClosestTarget()
    local closest = nil
    local shortest = Config.FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isSameTeam(player) then continue end
        if not player.Character then continue end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist > Config.FOVRadius then continue end
        if not hasLineOfSight(player.Character) then continue end
        if dist < shortest then
            shortest = dist
            closest = hrp
        end
    end
    return closest
end
RunService.RenderStepped:Connect(function()
    if not Config.AimbotEnabled then return end
    local target = getClosestTarget()
    if not target then return end
    local camPos = Camera.CFrame.Position
    local targetPos = target.Position
    local newCFrame = CFrame.new(camPos, camPos:Lerp(targetPos, Config.AimSmoothness))
    Camera.CFrame = newCFrame
end)
local espCache = {}

local function createESP(plr)
    if plr == LocalPlayer then return end
    if espCache[plr] then return end
    local char = plr.Character
    if not char then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game:GetService("CoreGui")
    if Config.ESPTeamCheck and plr.Team == LocalPlayer.Team then
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    else
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    end
    espCache[plr] = highlight
end

local function removeESP(plr)
    if espCache[plr] then
        espCache[plr]:Destroy()
        espCache[plr] = nil
    end
end

local function refreshESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if Config.ESPEnabled then
            createESP(plr)
            local hl = espCache[plr]
            if hl and hl.Adornee then
                if Config.ESPTeamCheck and plr.Team == LocalPlayer.Team then
                    hl.FillColor = Color3.fromRGB(0, 255, 0)
                    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                else
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                end
            end
        else
            removeESP(plr)
        end
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        refreshESP()
    end)
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        refreshESP()
    end)
end)
Players.PlayerRemoving:Connect(removeESP)
RunService.Heartbeat:Connect(refreshESP)
local Window = Rayfield:CreateWindow({
    Name = "Combat Suite",
    LoadingTitle = "加载中...",
    LoadingSubtitle = "by you",
    ConfigurationSaving = { Enabled = false },
})

local AimTab = Window:CreateTab("自瞄", 4483362458)
local ESPTab = Window:CreateTab("透视", 4483362458)

AimTab:CreateSection("自瞄设置")
AimTab:CreateToggle({
    Name = "启用自瞄",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v) Config.AimbotEnabled = v end,
})
AimTab:CreateToggle({
    Name = "队伍识别",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(v) Config.TeamCheck = v end,
})
AimTab:CreateToggle({
    Name = "掩体识别",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(v) Config.WallCheck = v end,
})
AimTab:CreateSlider({
    Name = "自瞄平滑度",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Flag = "AimSmoothness",
    Callback = function(v) Config.AimSmoothness = v end,
})
AimTab:CreateSlider({
    Name = "FOV 范围",
    Range = {30, 400},
    Increment = 5,
    CurrentValue = 120,
    Flag = "FOVRadius",
    Callback = function(v) Config.FOVRadius = v end,
})
AimTab:CreateColorPicker({
    Name = "FOV 圆圈颜色",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "FOVColor",
    Callback = function(c) Config.FOVColor = c end,
})

ESPTab:CreateSection("透视设置")
ESPTab:CreateToggle({
    Name = "启用透视",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v) Config.ESPEnabled = v; refreshESP() end,
})
ESPTab:CreateToggle({
    Name = "透视队伍识别",
    CurrentValue = true,
    Flag = "ESPTeamCheck",
    Callback = function(v) Config.ESPTeamCheck = v; refreshESP() end,
})