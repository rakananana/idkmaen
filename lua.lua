local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Feature states
local AimEnabled = false
local WallCheckEnabled = false
local MaxDistance = 100

local ESP_Skeleton = false
local ESP_Box = false
local ESP_Box2D = false
local ESP_Box3D = false

-- Utility for Drawing API check
local hasDrawing, Drawing = pcall(function() return Drawing end)

-- GUI Setup
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "MultiFeatureGUI"
gui.ResetOnSpawn = false
gui.Enabled = true

-- Main frame
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 260, 0, 250)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Tabs container
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 0)
tabContainer.BackgroundTransparency = 1

-- Content container (below tabs)
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1

-- Helper: Create a button
local function createButton(parent, text, posX, width)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(width, -10, 1, -6)
    btn.Position = UDim2.new(posX, 5, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 14
    btn.AutoButtonColor = true
    btn.Name = text.."TabBtn"
    btn.ZIndex = 2
    btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- Helper: Create checkbox toggle button
local function createCheckbox(parent, labelText, yPos, initialState, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10, 0, 30)
    container.Position = UDim2.new(0, 5, 0, yPos)
    container.BackgroundTransparency = 1

    local cb = Instance.new("TextButton", container)
    cb.Size = UDim2.new(0, 25, 0, 25)
    cb.Position = UDim2.new(0, 0, 0, 2)
    cb.BackgroundColor3 = initialState and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(100,100,100)
    cb.Text = initialState and "✔" or ""
    cb.TextColor3 = Color3.new(1,1,1)
    cb.Font = Enum.Font.SourceSansBold
    cb.TextSize = 18
    cb.AutoButtonColor = true
    cb.Name = "Checkbox"

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = labelText
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left

    cb.MouseButton1Click:Connect(function()
        local newState = not (cb.Text == "✔")
        if newState then
            cb.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            cb.Text = "✔"
        else
            cb.BackgroundColor3 = Color3.fromRGB(100,100,100)
            cb.Text = ""
        end
        callback(newState)
    end)

    return container
end

-- Create Tabs buttons
local tabAim = createButton(tabContainer, "Aim Assist", 0, 0.5)
local tabESP = createButton(tabContainer, "ESP", 0.5, 0.5)

-- Create Aim Assist Content Frame
local aimFrame = Instance.new("Frame", contentFrame)
aimFrame.Size = UDim2.new(1,0,1,0)
aimFrame.BackgroundTransparency = 1
aimFrame.Visible = true

-- Create ESP Content Frame
local espFrame = Instance.new("Frame", contentFrame)
espFrame.Size = UDim2.new(1,0,1,0)
espFrame.BackgroundTransparency = 1
espFrame.Visible = false

-- Populate Aim Assist content with toggles
createCheckbox(aimFrame, "Enable Aim Assist", 10, AimEnabled, function(state) AimEnabled = state end)
createCheckbox(aimFrame, "Enable Wall Check", 50, WallCheckEnabled, function(state) WallCheckEnabled = state end)

-- Distance toggle button for Aim Assist
local distBtn = Instance.new("TextButton", aimFrame)
distBtn.Size = UDim2.new(0, 180, 0, 30)
distBtn.Position = UDim2.new(0, 10, 0, 90)
distBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
distBtn.TextColor3 = Color3.new(1,1,1)
distBtn.Text = "Max Distance: "..MaxDistance
distBtn.Font = Enum.Font.SourceSansSemibold
distBtn.TextSize = 16
distBtn.AutoButtonColor = true
Instance.new("UICorner", distBtn).CornerRadius = UDim.new(0, 6)

distBtn.MouseButton1Click:Connect(function()
    if MaxDistance == 100 then
        MaxDistance = 200
    else
        MaxDistance = 100
    end
    distBtn.Text = "Max Distance: "..MaxDistance
end)

-- Populate ESP content with toggles
createCheckbox(espFrame, "Skeleton ESP", 10, ESP_Skeleton, function(state) ESP_Skeleton = state end)
createCheckbox(espFrame, "Box ESP", 50, ESP_Box, function(state) ESP_Box = state end)
createCheckbox(espFrame, "2D Box ESP", 90, ESP_Box2D, function(state) ESP_Box2D = state end)
createCheckbox(espFrame, "3D Box ESP", 130, ESP_Box3D, function(state) ESP_Box3D = state end)

-- Tab switching logic
local function setTab(tabName)
    if tabName == "Aim" then
        aimFrame.Visible = true
        espFrame.Visible = false
        tabAim.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        tabESP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    elseif tabName == "ESP" then
        aimFrame.Visible = false
        espFrame.Visible = true
        tabAim.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabESP.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end
end

tabAim.MouseButton1Click:Connect(function()
    setTab("Aim")
end)

tabESP.MouseButton1Click:Connect(function()
    setTab("ESP")
end)

setTab("Aim") -- default tab

-- Toggle main GUI with RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- ====================
-- AIM ASSIST LOOP
-- ====================
RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not hrp or not head then return end

    local closestTarget = nil
    local shortestDist = MaxDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = player.Character.HumanoidRootPart
            local distance = (hrp.Position - targetHRP.Position).Magnitude

            if distance < shortestDist then
                if WallCheckEnabled then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    rayParams.FilterDescendantsInstances = {character}
                    rayParams.IgnoreWater = true

                    local dir = (targetHRP.Position - head.Position).Unit * distance
                    local result = Workspace:Raycast(head.Position, dir, rayParams)

                    if result and result.Instance:IsDescendantOf(player.Character) then
                        closestTarget = targetHRP
                        shortestDist = distance
                    end
                else
                    closestTarget = targetHRP
                    shortestDist = distance
                end
            end
        end
    end

    if closestTarget then
        local lookAt = Vector3.new(closestTarget.Position.X, hrp.Position.Y, closestTarget.Position.Z)
        hrp.CFrame = CFrame.new(hrp.Position, lookAt)
    end
end)

-- ====================
-- ESP IMPLEMENTATION
-- ====================
local espObjects = {}

local function createLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 2
    line.Transparency = 1
    return line
end

local function createSquare()
    local square = Drawing.new("Square")
    square.Visible = false
    square.Thickness = 2
    square.Filled = false
    square.Transparency = 1
    return square
end

local function createFilledBoxPart()
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 0.6
    p.Material = Enum.Material.Neon
    p.Size = Vector3.new(4, 7, 2) -- Adjust as needed
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    return p
end

local skeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function getCharacterLimbs(character)
    local limbs = {}
    local parts = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot"
    }
    for _, partName in pairs(parts) do
        local part = character:FindFirstChild(partName)
        if part then
            limbs[partName] = part
        end
    end
    return limbs
end

local function isVisibleToLocalPlayer(targetPart)
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("Head") then return false end
    local headPos = localChar.Head.Position
    local targetPos = targetPart.Position
    local direction = targetPos - headPos

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localChar}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local result = Workspace:Raycast(headPos, direction, rayParams)
    if not result then
        return true
    else
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
end

local function initSkeletonESP(player)
    espObjects[player] = espObjects[player] or {}
    local obj = espObjects[player]
    if not obj.skeletonLines then
        obj.skeletonLines = {}
        for _ = 1, #skeletonConnections do
            local line = createLine()
            line.Color = Color3.new(0, 1, 0) -- default green
            table.insert(obj.skeletonLines, line)
        end
    end
end

local function updateSkeletonESP(player, limbs)
    if not espObjects[player] or not espObjects[player].skeletonLines then return end
    local lines = espObjects[player].skeletonLines
    local cam = Workspace.CurrentCamera
    local index = 1

    local visible = false
    for _, part in pairs(limbs) do
        if isVisibleToLocalPlayer(part) then
            visible = true
            break
        end
    end

    local color = visible and Color3.new(0,1,0) or Color3.new(1,0,0)

    for _, connection in ipairs(skeletonConnections) do
        local p1 = limbs[connection[1]]
        local p2 = limbs[connection[2]]

        if p1 and p2 then
            local p1pos, onScreen1 = cam:WorldToViewportPoint(p1.Position)
            local p2pos, onScreen2 = cam:WorldToViewportPoint(p2.Position)

            if onScreen1 and onScreen2 then
                local line = lines[index]
                line.From = Vector2.new(p1pos.X, p1pos.Y)
                line.To = Vector2.new(p2pos.X, p2pos.Y)
                line.Visible = true
                line.Color = color
            else
                lines[index].Visible = false
            end
        else
            lines[index].Visible = false
        end
        index = index + 1
    end
end

local function init2DBoxESP(player)
    espObjects[player] = espObjects[player] or {}
    local obj = espObjects[player]
    if not obj.box2D then
        local box = createSquare()
        box.Color = Color3.new(0, 1, 0)
        obj.box2D = box
    end
end

local function update2DBoxESP(player, hrp)
    if not espObjects[player] or not espObjects[player].box2D then return end
    local box = espObjects[player].box2D
    local cam = Workspace.CurrentCamera
    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)

    if onScreen then
        local visible = isVisibleToLocalPlayer(hrp)
        local color = visible and Color3.new(0,1,0) or Color3.new(1,0,0)

        local size = math.clamp(3000 / pos.Z, 40, 150)
        box.Size = Vector2.new(size, size * 1.4)
        box.Position = Vector2.new(pos.X - box.Size.X/2, pos.Y - box.Size.Y/2)
        box.Visible = true
        box.Color = color
        box.Filled = false
        box.Thickness = 2
    else
        box.Visible = false
    end
end

local function init3DBoxESP(player, hrp)
    espObjects[player] = espObjects[player] or {}
    local obj = espObjects[player]

    if not obj.box3D or not obj.box3D.Parent then
        if obj.box3D and obj.box3D.Parent then
            obj.box3D:Destroy()
        end
        local box = createFilledBoxPart()
        box.Parent = Workspace
        obj.box3D = box
    end
end

local function update3DBoxESP(player, hrp)
    local obj = espObjects[player]
    if not obj or not obj.box3D then return end
    local box = obj.box3D

    local visible = isVisibleToLocalPlayer(hrp)
    local color = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

    box.Size = Vector3.new(4, 7, 2)
    box.CFrame = hrp.CFrame
    box.Transparency = 0.6
    box.Color = color
    box.Anchored = true
    box.CanCollide = false
end

local function cleanupESP(player)
    local obj = espObjects[player]
    if not obj then return end

    if obj.skeletonLines then
        for _, line in ipairs(obj.skeletonLines) do
            line.Visible = false
            line:Remove()
        end
        obj.skeletonLines = nil
    end

    if obj.box2D then
        obj.box2D.Visible = false
        obj.box2D:Remove()
        obj.box2D = nil
    end

    if obj.box3D then
        if obj.box3D.Parent then
            obj.box3D:Destroy()
        end
        obj.box3D = nil
    end
end

Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
    espObjects[player] = nil
end)

RunService.RenderStepped:Connect(function()
    if not (ESP_Skeleton or ESP_Box2D or ESP_Box3D) then
        for player, _ in pairs(espObjects) do
            cleanupESP(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local limbs = getCharacterLimbs(player.Character)

            if ESP_Skeleton then
                initSkeletonESP(player)
                updateSkeletonESP(player, limbs)
            else
                if espObjects[player] and espObjects[player].skeletonLines then
                    for _, line in ipairs(espObjects[player].skeletonLines) do
                        line.Visible = false
                    end
                end
            end

            if ESP_Box2D then
                init2DBoxESP(player)
                update2DBoxESP(player, hrp)
            else
                if espObjects[player] and espObjects[player].box2D then
                    espObjects[player].box2D.Visible = false
                end
            end

            if ESP_Box3D then
                init3DBoxESP(player, hrp)
                update3DBoxESP(player, hrp)
            else
                if espObjects[player] and espObjects[player].box3D then
                    if espObjects[player].box3D.Parent then
                        espObjects[player].box3D:Destroy()
                    end
                    espObjects[player].box3D = nil
                end
            end
        else
            cleanupESP(player)
        end
    end
end)