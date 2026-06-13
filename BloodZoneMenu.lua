-- Grok Universal ESP + Aimbot + Gun Mods + Improved Safe Mode
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==================== SETTINGS ====================
local ESP = {}
local Allies = {}
local Settings = {
    Enabled = false,
    Boxes = true,
    Names = true,
    Health = true,
    Distance = true,
    Tracers = false,
    TeamCheck = true,
    MaxDistance = 1000,
}

-- Aimbot
local aimFov = 100
local aimParts = {"Head"}
local aiming = false
local predictionStrength = 0.065
local smoothing = 0.05
local aimbotEnabled = false
local wallCheck = false
local stickyAimEnabled = false
local teamCheckAimbot = false

-- Gun Mods
local noRecoilEnabled = false
local allGunsAutoEnabled = false

-- Safe Mode
local safeModeEnabled = false

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Visible = false

local currentTarget = nil
local Connections = {}

-- ==================== EASY TO EDIT KEYWORDS ====================
local badKeywords = {
    "script", "scripts", "scripting", "scripter", "scripted",
    "hack", "hacks", "hacking", "hacker", "hackers",
    "cheat", "cheats", "cheating", "cheater", "cheaters",
    "exploit", "exploits", "exploiter", "exploiters",
    "report", "reported", "reporting", "bot", "aimbot", "aim bot"
}

-- ==================== DRAWING & ESP ====================
local function NewDrawing(class)
    local obj = Drawing.new(class)
    obj.Visible = false
    obj.Transparency = 1
    return obj
end

local function IsAlly(plr)
    return Allies[plr.Name] or Allies[plr.DisplayName]
end

local function CheckWall(targetCharacter)
    if not wallCheck then return false end
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetHead then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetHead.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character or {}, targetCharacter}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    return workspace:Raycast(origin, direction, params) ~= nil
end

local function DestroyESP(plr)
    local data = ESP[plr]
    if data then
        for _, line in pairs(data.Box) do if line then line:Remove() end end
        if data.Name then data.Name:Remove() end
        if data.Distance then data.Distance:Remove() end
        if data.HealthBar.Outline then data.HealthBar.Outline:Remove() end
        if data.HealthBar.Bar then data.HealthBar.Bar:Remove() end
        if data.Tracer then data.Tracer:Remove() end
        ESP[plr] = nil
    end
end

local function CreateESP(plr)
    if plr == LocalPlayer then return end
    DestroyESP(plr)

    local esp = {
        Box = {Top = NewDrawing("Line"), Bottom = NewDrawing("Line"), Left = NewDrawing("Line"), Right = NewDrawing("Line")},
        Name = NewDrawing("Text"),
        HealthBar = {Outline = NewDrawing("Line"), Bar = NewDrawing("Line")},
        Distance = NewDrawing("Text"),
        Tracer = NewDrawing("Line")
    }

    esp.Name.Size = 14; esp.Name.Center = true; esp.Name.Outline = true
    esp.Distance.Size = 13; esp.Distance.Center = true; esp.Distance.Outline = true

    for _, line in pairs(esp.Box) do line.Thickness = 1.5 end
    esp.Tracer.Thickness = 1.5

    ESP[plr] = esp
end

local function RefreshAllESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then CreateESP(plr) end
    end
end

local function UpdateESP()
    if not Settings.Enabled then
        for _, data in pairs(ESP) do
            for _, v in pairs(data.Box) do v.Visible = false end
            data.Name.Visible = false
            data.Distance.Visible = false
            data.HealthBar.Outline.Visible = false
            data.HealthBar.Bar.Visible = false
            data.Tracer.Visible = false
        end
        return
    end

    for plr, data in pairs(ESP) do
        local char = plr.Character
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
            local root = char.HumanoidRootPart
            local hum = char.Humanoid
            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            if dist > Settings.MaxDistance then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen and screenPos.Z > 0 then
                local size = (Camera:WorldToViewportPoint(root.Position - Vector3.new(2.5,3,0)).X - Camera:WorldToViewportPoint(root.Position + Vector3.new(2.5,3,0)).X) * 1.8
                local x, y = screenPos.X, screenPos.Y

                local isAlly = IsAlly(plr)
                local boxColor = isAlly and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 255, 0)

                if Settings.Boxes then
                    local tl = Vector2.new(x - size/2, y - size)
                    local br = Vector2.new(x + size/2, y + size/2)
                    data.Box.Top.From = tl; data.Box.Top.To = Vector2.new(br.X, tl.Y); data.Box.Top.Color = boxColor; data.Box.Top.Visible = true
                    data.Box.Bottom.From = Vector2.new(tl.X, br.Y); data.Box.Bottom.To = br; data.Box.Bottom.Color = boxColor; data.Box.Bottom.Visible = true
                    data.Box.Left.From = tl; data.Box.Left.To = Vector2.new(tl.X, br.Y); data.Box.Left.Color = boxColor; data.Box.Left.Visible = true
                    data.Box.Right.From = Vector2.new(br.X, tl.Y); data.Box.Right.To = br; data.Box.Right.Color = boxColor; data.Box.Right.Visible = true
                end

                if Settings.Names then
                    data.Name.Text = plr.DisplayName
                    data.Name.Position = Vector2.new(x, y - size - 18)
                    data.Name.Color = isAlly and Color3.fromRGB(100,200,255) or Color3.fromRGB(255,255,255)
                    data.Name.Visible = true
                end

                if Settings.Distance then
                    data.Distance.Text = math.floor(dist) .. " studs"
                    data.Distance.Position = Vector2.new(x, y + size/2 + 8)
                    data.Distance.Visible = true
                end

                if Settings.Health then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barH = size * hp
                    data.HealthBar.Outline.From = Vector2.new(x - size/2 - 6, y - size)
                    data.HealthBar.Outline.To = Vector2.new(x - size/2 - 6, y + size/2)
                    data.HealthBar.Outline.Color = Color3.new(0,0,0); data.HealthBar.Outline.Thickness = 3; data.HealthBar.Outline.Visible = true

                    data.HealthBar.Bar.From = Vector2.new(x - size/2 - 5, y + size/2 - barH)
                    data.HealthBar.Bar.To = Vector2.new(x - size/2 - 5, y + size/2)
                    data.HealthBar.Bar.Color = Color3.fromRGB(255 - 255*hp, 255*hp, 0); data.HealthBar.Bar.Thickness = 2; data.HealthBar.Bar.Visible = true
                end

                if Settings.Tracers then
                    data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    data.Tracer.To = Vector2.new(x, y + size/2)
                    data.Tracer.Color = boxColor; data.Tracer.Visible = true
                end
            else
                for _, v in pairs(data.Box) do v.Visible = false end
                data.Name.Visible = false
                data.Distance.Visible = false
                data.HealthBar.Outline.Visible = false
                data.HealthBar.Bar.Visible = false
                data.Tracer.Visible = false
            end
        else
            for _, v in pairs(data.Box) do v.Visible = false end
            data.Name.Visible = false
            data.Distance.Visible = false
            data.HealthBar.Outline.Visible = false
            data.HealthBar.Bar.Visible = false
            data.Tracer.Visible = false
        end
    end
end

-- ==================== GUN MODS ====================
local function ApplyGunMods()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    local tools = {}

    if backpack then for _, t in pairs(backpack:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end
    if character then for _, t in pairs(character:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end end

    for _, tool in pairs(tools) do
        local settingsFolder = tool:FindFirstChild("Settings")
        if not settingsFolder or not settingsFolder:IsA("Configuration") then continue end

        if noRecoilEnabled then
            local spread = settingsFolder:FindFirstChild("Spread")
            if spread and spread:IsA("NumberValue") and spread.Value ~= 0 then spread.Value = 0 end
            local recoil = settingsFolder:FindFirstChild("Recoil")
            if recoil and recoil:IsA("NumberValue") and recoil.Value ~= 0 then recoil.Value = 0 end
        end

        if allGunsAutoEnabled then
            local gunType = settingsFolder:FindFirstChild("GunType")
            if gunType and gunType:IsA("StringValue") and gunType.Value ~= "Auto" then gunType.Value = "Auto" end
        end
    end
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if noRecoilEnabled or allGunsAutoEnabled then
        ApplyGunMods()
    end
end))

-- ==================== SAFE MODE ====================
local function ServerHop()
    print("🚨 Safe Mode triggered! Server hopping...")
    local placeId = game.PlaceId

    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)

    if success and servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(placeId, server.id)
                return
            end
        end
    end

    TeleportService:Teleport(placeId)
end

local function CheckChatMessage(message)
    if not safeModeEnabled then return end
    local lower = string.lower(message)
    for _, keyword in ipairs(badKeywords) do
        if string.find(lower, keyword) then
            print("🚨 Detected trigger word: " .. keyword .. " | Message: " .. message)
            ServerHop()
            return
        end
    end
end

-- Chat monitoring
table.insert(Connections, LocalPlayer.Chatted:Connect(function(msg)
    CheckChatMessage(msg)
end))

local TextChatService = game:GetService("TextChatService")
if TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource then
            CheckChatMessage(textChatMessage.Text)
        end
    end)
end

-- ==================== AIMBOT ====================
local function checkTeamAimbot(player)
    if teamCheckAimbot and player.Team == LocalPlayer.Team then return true end
    return false
end

local function getClosestPart(character)
    local shortest = aimFov + 1
    local best = nil
    for _, name in ipairs(aimParts) do
        local part = character:FindFirstChild(name)
        if part then
            local vp = Camera:WorldToViewportPoint(part.Position)
            local dist = (Vector2.new(vp.X, vp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if dist < shortest and vp.Z > 0 then
                shortest = dist
                best = part
            end
        end
    end
    return best
end

local function getTarget()
    local bestPlayer, bestPart = nil, nil
    local shortestDistance = aimFov + 1

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not checkTeamAimbot(plr) and not IsAlly(plr) then
            local part = getClosestPart(plr.Character)
            if part then
                local screenPos = Camera:WorldToViewportPoint(part.Position)
                local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if cursorDist < shortestDistance then
                    if not wallCheck or not CheckWall(plr.Character) then
                        shortestDistance = cursorDist
                        bestPlayer = plr
                        bestPart = part
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

local function predict(player, part)
    local vel = player.Character.HumanoidRootPart.Velocity
    return part.Position + vel * predictionStrength
end

local function smoothCam(from, to)
    return from:Lerp(to, smoothing)
end

local function aimAt(player, part)
    local pred = predict(player, part)
    if pred then
        local targetCF = CFrame.new(Camera.CFrame.Position, pred)
        Camera.CFrame = smoothCam(Camera.CFrame, targetCF)
    end
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 50)
    fovCircle.Radius = aimFov

    if aiming then
        if stickyAimEnabled and currentTarget and currentTarget.Character then
            local headPos = Camera:WorldToViewportPoint(currentTarget.Character.Head.Position)
            if (Vector2.new(headPos.X, headPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude > aimFov then
                currentTarget = nil
            end
        end

        if not stickyAimEnabled or not currentTarget then
            local t, p = getTarget()
            currentTarget = t
        end

        if currentTarget and currentTarget.Character then
            local part = getClosestPart(currentTarget.Character)
            if part then aimAt(currentTarget, part) end
        end
    end
end))

Mouse.Button2Down:Connect(function() if aimbotEnabled then aiming = true end end)
Mouse.Button2Up:Connect(function() if aimbotEnabled then aiming = false end end)

-- ==================== MENU ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrokMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 520)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "GROK UNIVERSAL"
Title.TextColor3 = Color3.fromRGB(0, 255, 80)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -10, 1, -180)
Scrolling.Position = UDim2.new(0, 5, 0, 40)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 4
Scrolling.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Scrolling

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 55, 0, 24)
    button.Position = UDim2.new(1, -65, 0.5, -12)
    button.BackgroundColor3 = default and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
    button.Text = default and "ON" or "OFF"
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 13
    button.Font = Enum.Font.SourceSansBold
    button.Parent = frame

    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        button.Text = state and "ON" or "OFF"
        callback(state)
        print(text .. " set to " .. (state and "ON" or "OFF"))
    end)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSans
    btn.Parent = parent

    btn.MouseButton1Click:Connect(function()
        callback()
        print(text .. " clicked")
    end)
end

local function CreateSlider(parent, text, minVal, maxVal, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(70,70,70)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    fill.Parent = bar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((default-minVal)/(maxVal-minVal), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Text = ""
    knob.Parent = bar

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            local val = math.floor(minVal + rel * (maxVal - minVal))
            label.Text = text .. ": " .. val
            callback(val)
            print(text .. " set to " .. val)
        end
    end)
end

local function CreateTextbox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 32)
    box.BackgroundColor3 = Color3.fromRGB(45,45,45)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.TextSize = 14
    box.Font = Enum.Font.SourceSans
    box.Parent = parent
    return box
end

-- Menu Items
CreateToggle(Scrolling, "ESP Enabled", false, function(v) Settings.Enabled = v end)
CreateToggle(Scrolling, "Boxes", true, function(v) Settings.Boxes = v end)
CreateToggle(Scrolling, "Names", true, function(v) Settings.Names = v end)
CreateToggle(Scrolling, "Health Bars", true, function(v) Settings.Health = v end)
CreateToggle(Scrolling, "Distance", true, function(v) Settings.Distance = v end)
CreateToggle(Scrolling, "Tracers", false, function(v) Settings.Tracers = v end)
CreateToggle(Scrolling, "Team Check", true, function(v) Settings.TeamCheck = v end)

local allyBox = CreateTextbox(Scrolling, "Username for ally...")

CreateButton(Scrolling, "Add Ally", function()
    local name = allyBox.Text
    if name and name ~= "" then Allies[name] = true; print("Added ally: " .. name) end
end)

CreateButton(Scrolling, "Remove Ally", function()
    local name = allyBox.Text
    if name and Allies[name] then Allies[name] = nil; print("Removed ally: " .. name)
    else print("No ally found: " .. (name or "")) end
end)

CreateToggle(Scrolling, "Aimbot", false, function(v) aimbotEnabled = v; fovCircle.Visible = v end)
CreateSlider(Scrolling, "FOV", 0, 800, 100, function(v) aimFov = v; fovCircle.Radius = v end)
CreateToggle(Scrolling, "Show FOV Circle", true, function(v) fovCircle.Visible = v and aimbotEnabled end)
CreateToggle(Scrolling, "Wall Check", false, function(v) wallCheck = v end)
CreateToggle(Scrolling, "Team Check (Aimbot)", false, function(v) teamCheckAimbot = v end)
CreateSlider(Scrolling, "Smoothing", 0, 100, 5, function(v) smoothing = 1 - (v / 100) end)
CreateSlider(Scrolling, "Prediction", 0, 0.2, 0.065, function(v) predictionStrength = v end)

CreateToggle(Scrolling, "No Recoil & Spread", false, function(v) noRecoilEnabled = v end)
CreateToggle(Scrolling, "All Guns Auto", false, function(v) allGunsAutoEnabled = v end)
CreateToggle(Scrolling, "Safe Mode (Anti-Report)", false, function(v) safeModeEnabled = v end)

CreateButton(Scrolling, "Unload Script", function()
    print("Unloading script...")
    for plr,_ in pairs(ESP) do DestroyESP(plr) end
    for _,c in ipairs(Connections) do if c then c:Disconnect() end end
    if ScreenGui then ScreenGui:Destroy() end
    if fovCircle then fovCircle:Remove() end
    print("Script fully unloaded.")
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 70, 0, 28)
CloseBtn.Position = UDim2.new(1, -80, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "Close"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.SourceSans
CloseBtn.Parent = MainFrame

CloseBtn.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)

-- Draggable
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Insert Toggle
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        ScreenGui.Enabled = not ScreenGui.Enabled
        print("Menu toggled")
    end
end))

-- Player Setup
local function SetupPlayer(plr)
    if plr == LocalPlayer then return end
    CreateESP(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.3) CreateESP(plr) end)
    plr.CharacterRemoving:Connect(function() DestroyESP(plr) end)
end

for _, plr in pairs(Players:GetPlayers()) do SetupPlayer(plr) end
Players.PlayerAdded:Connect(SetupPlayer)

LocalPlayer.CharacterAdded:Connect(function() task.wait(1) RefreshAllESP() end)

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if math.floor(tick()) % 90 == 0 then RefreshAllESP() end
end))

RunService.RenderStepped:Connect(UpdateESP)

print("Blood Zone Semi-Universal Script Loaded!")
print("Press INSERT (Ins) to open menu.")
print("This script was made by Blood-Zone-Menu on Github!")
print("This script is open source! if you do modify this script to make your own and/or upload it somehwhere else please give me credit with a simple print script at the bottom of your script it can say anything as long as it includes "Blood-Zone-Menu on Github"")
