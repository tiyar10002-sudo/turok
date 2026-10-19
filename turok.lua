-- Turok Aimbot | Alkedion PVP & Aladia FFA & Valkadia
-- UI: Rayfield Gen 2
-- Fitur: Aimbot, ESP, Noclip, Auto Redeem, Kill Aura, Teleport, Fly, God Mode (Bypass)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "TUROK AIMBOT",
    subtitle = "BY TUROK ON DISCORD",
    sidebarLayout = true
})

-- ==================== SERVICE ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==================== VARIABEL ====================
local aimbotEnabled = false
local espEnabled = false
local wallCheckEnabled = false
local fovVisible = false
local rainbowFov = false
local noclipEnabled = false
local fovRadius = 100
local lockPart = "Head"
local smoothness = 0.3
local teamCheck = true
local currentTarget = nil
local fovCircle = nil
local espObjects = {}
local selectedGame = "Aladia PVP"

local godModeEnabled = false
local killAuraEnabled = false
local flyEnabled = false
local killAuraRadius = 50
local selectedPlayer = "None"

-- ==================== REDEEM DATA ====================
local redeemData = {
    ["Aladia PVP"] = {
        codes = {"KodeAladia1", "KodeAladia2", "KodeAladia3"},
        remote = "CodeRedeemCommand",
        remoteType = "RemoteEvent",
        command = "/code"
    },
    ["Alkedion"] = {
        codes = {
            "Bblyln", "Vamp", "Waym", "Vos",
            "Shringgin", "Murmlee", "Blueorb", "Vurk",
            "Greternall", "wuwumi", "SolthumAgainBoy", "wChase",
            "UpdateNaBoss", "DiPaPalaHalloween", "HalloweenNaBa",
            "Wanna", "Be", "Talaga"
        },
        remote = "CodeRedeemCommand",
        remoteType = "RemoteEvent",
        command = "/code"
    },
    ["Valkadia PVP"] = {
        codes = {
            "Wanna", "Be", "Talaga",
            "Bblyln", "Vamp", "Waym", "Vos",
            "Shringgin", "Murmlee", "Blueorb", "Vurk",
            "Greternall", "wuwumi", "SolthumAgainBoy", "wChase",
            "UpdateNaBoss", "DiPaPalaHalloween", "HalloweenNaBa"
        },
        remote = "settingShared.commEvents.settingEvents.redeem",
        remoteType = "RemoteEvent",
        command = ""
    }
}

-- ==================== FUNGSI NOTIFIKASI & REMOTE ====================
local function notify(title, content)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = content, Duration = 5 })
    end)
end

local function findRemote(remoteName)
    if string.find(remoteName, "%.") then
        local parts = string.split(remoteName, ".")
        local obj = ReplicatedStorage
        for _, part in ipairs(parts) do
            obj = obj:FindFirstChild(part)
            if not obj then return nil end
        end
        return obj
    end
    local remote = ReplicatedStorage:FindFirstChild(remoteName)
    if remote then return remote end
    for _, obj in ipairs(game:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and obj.Name == remoteName then
            return obj
        end
    end
    return nil
end

local function redeemCode(code, remoteName, remoteType, command)
    local remote = findRemote(remoteName)
    if not remote then return false, "Remote gak ada!" end
    local payload = (command == "" or command == nil) and code or (command .. " " .. code)
    local success = pcall(function()
        if remoteType == "RemoteFunction" then remote:InvokeServer(payload)
        else remote:FireServer(payload) end
    end)
    return success, success and "Berhasil" or "Gagal"
end

-- ==================== AIMBOT & ESP ====================
local function isEnemy(player)
    if not teamCheck then return true end
    if not LocalPlayer.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

local function isVisible(part)
    if not wallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getTarget()
    local closest, shortest = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not isEnemy(player) then continue end
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = player.Character:FindFirstChild(lockPart) or player.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortest and isVisible(part) then
                            closest, shortest = player, dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function aimAt(target)
    if not target or not target.Character then return end
    local part = target.Character:FindFirstChild(lockPart) or target.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local targetPos = part.Position
    local cameraPos = Camera.CFrame.Position
    local direction = (targetPos - cameraPos).Unit
    local newCFrame = CFrame.lookAt(cameraPos, cameraPos + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 1 - smoothness)
end

local function createESP(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TurokESP"
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent = char

    local tracer = Instance.new("Beam")
    tracer.Name = "TurokTracer"
    tracer.FaceCamera = true
    tracer.Width0 = 0.05
    tracer.Width1 = 0.05
    tracer.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    tracer.Transparency = NumberSequence.new(0.3)
    tracer.LightEmission = 1
    tracer.Parent = char

    local attachment0 = Instance.new("Attachment")
    attachment0.Name = "TurokTracerAttach0"
    attachment0.Parent = char

    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "TurokTracerAttach1"
    attachment1.Parent = root

    tracer.Attachment0 = attachment0
    tracer.Attachment1 = attachment1

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TurokName"
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 250, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = player.Name
    textLabel.Parent = billboard

    espObjects[player] = {
        highlight = highlight, tracer = tracer,
        attachment0 = attachment0, attachment1 = attachment1,
        billboard = billboard, text = textLabel
    }
end

local function removeESP(player)
    local data = espObjects[player]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.tracer then data.tracer:Destroy() end
        if data.attachment0 then data.attachment0:Destroy() end
        if data.attachment1 then data.attachment1:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        espObjects[player] = nil
    end
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj.Name == "TurokESP" or obj.Name == "TurokName" or obj.Name == "TurokTracer" then
                obj:Destroy()
            end
        end
    end
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if espEnabled and isEnemy(player) then
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if char and humanoid and humanoid.Health > 0 then
                if not espObjects[player] then createESP(player) end
                local data = espObjects[player]
                if data and data.text and char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
                        data.text.Text = "Name: " .. player.Name .. " | Health: " .. math.floor(humanoid.Health) .. " | Studs: " .. dist
                    end
                end
            else
                if espObjects[player] then removeESP(player) end
            end
        else
            if espObjects[player] then removeESP(player) end
        end
    end
end

-- ==================== FUNGSI NOCLIP & FLY ====================
local function noclipLoop()
    while noclipEnabled do
        task.wait(0.1)
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

local function flyLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    
    while flyEnabled do
        task.wait()
        if not char or not char.Parent then break end
        local cameraCFrame = workspace.CurrentCamera.CFrame
        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += cameraCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= cameraCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= cameraCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += cameraCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection -= Vector3.new(0, 1, 0) end
        
        if moveDirection.Magnitude > 0 then bodyVelocity.Velocity = moveDirection.Unit * 50
        else bodyVelocity.Velocity = Vector3.new(0, 0, 0) end
    end
    if bodyVelocity then bodyVelocity:Destroy() end
end

-- ==================== KILL AURA & GOD MODE (BYPASS) ====================
local function killAuraLoop()
    while killAuraEnabled do
        task.wait(0.1)
        local remote = ReplicatedStorage:FindFirstChild("Blaster")
        if remote then remote = remote:FindFirstChild("Scripts") end
        if remote then remote = remote:FindFirstChild("ShotReplication") end
        if not remote then continue end

        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and isEnemy(player) then
                local targetHead = player.Character:FindFirstChild("Head")
                local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
                
                if targetHead and targetHrp and targetHum and targetHum.Health > 0 then
                    if (hrp.Position - targetHrp.Position).Magnitude <= killAuraRadius then
                        pcall(function()
                            remote:FireServer(targetHead.Position, targetHead)
                        end)
                    end
                end
            end
        end
    end
end

local function godModeBypassLoop()
    while godModeEnabled do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part:SetNetworkOwner(LocalPlayer)
                    end)
                end
            end
        end
    end
end

-- ==================== FOV CIRCLE & MAIN LOOP ====================
RunService.Heartbeat:Connect(function()
    if fovCircle and fovVisible then
        local screenSize = Camera.ViewportSize
        fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovCircle.Radius = fovRadius
        fovCircle.Color = rainbowFov and Color3.fromHSV(tick() % 5 / 5, 1, 1) or Color3.fromRGB(255, 255, 255)
    end
end)

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getTarget()
        if target and target.Character then aimAt(target) end
    end
    if espEnabled then updateESP() end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then createESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player) removeESP(player) end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                removeESP(player); createESP(player)
            end
        end
    end
end)

-- ==================== UI ====================
local MainTab = Window:CreateTab({ name = "Main", icon = "crosshair" })
local VisualTab = Window:CreateTab({ name = "Visual", icon = "eye" })
local MiscTab = Window:CreateTab({ name = "MISC", icon = "code" })
local TeleportTab = Window:CreateTab({ name = "Teleport", icon = "map-pin" })
local GodModeTab = Window:CreateTab({ name = "God Mode", icon = "shield" })
local SettingsTab = Window:CreateTab({ name = "Settings", icon = "settings" })

-- TAB MAIN
MainTab:CreateToggle({ name = "Aimbot", currentValue = false, callback = function(state) aimbotEnabled = state end })
MainTab:CreateToggle({ name = "Wall Check", currentValue = false, callback = function(state) wallCheckEnabled = state end })
MainTab:CreateToggle({ name = "Team Check", currentValue = true, callback = function(state) teamCheck = state end })
MainTab:CreateDropdown({ name = "Lock Part", options = {"Head", "HumanoidRootPart"}, currentOption = "Head", callback = function(option) if type(option) == "table" then lockPart = option[1] else lockPart = option end end })

MainTab:CreateToggle({
    name = "Kill Aura (Auto ShotReplication)",
    currentValue = false,
    callback = function(state) killAuraEnabled = state; if state then task.spawn(killAuraLoop) end end
})
MainTab:CreateSlider({ name = "Radius Kill Aura", range = {10, 150}, increment = 5, suffix = " studs", currentValue = 50, callback = function(value) killAuraRadius = value end })

-- TAB VISUAL
VisualTab:CreateToggle({ name = "ESP (Nama + HP + Studs + Tracer)", currentValue = false, callback = function(state) espEnabled = state; if not state then for player, _ in pairs(espObjects) do removeESP(player) end end end })
VisualTab:CreateToggle({
    name = "Show FOV Circle", currentValue = false,
    callback = function(state)
        fovVisible = state
        if state and not fovCircle then
            fovCircle = Drawing.new("Circle"); fovCircle.Thickness = 2; fovCircle.Filled = false; fovCircle.Radius = fovRadius; fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); fovCircle.Visible = true
        elseif not state and fovCircle then fovCircle.Visible = false end
    end
})
VisualTab:CreateToggle({ name = "Rainbow FOV", currentValue = false, callback = function(state) rainbowFov = state end })

-- TAB TELEPORT
TeleportTab:CreateButton({
    name = "Teleport to Camera",
    callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -5); notify("Teleport", "Berhasil!") end
    end
})
TeleportTab:CreateDropdown({
    name = "Pilih Player (Target TP)", options = {"None"}, currentOption = "None",
    callback = function(option) if type(option) == "table" then selectedPlayer = option[1] else selectedPlayer = option end end
})
TeleportTab:CreateButton({
    name = "Teleport to Selected Player",
    callback = function()
        if selectedPlayer == "None" then return notify("Gagal", "Pilih player dulu!") end
        local target = Players:FindFirstChild(selectedPlayer)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHrp then hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0); notify("Teleport", "Berhasil TP ke " .. selectedPlayer) end
    end
})

-- Update list player tiap 5 detik
task.spawn(function()
    while task.wait(5) do
        local plrs = {"None"}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(plrs, p.Name) end end
    end
end)

-- TAB MISC
MiscTab:CreateToggle({ name = "Noclip (Tembus Tembok)", currentValue = false, callback = function(state) noclipEnabled = state; if state then task.spawn(noclipLoop) end end })
MiscTab:CreateToggle({ name = "Fly (Terbang) - Pakai WASD + Space/Ctrl", currentValue = false, callback = function(state) flyEnabled = state; if state then task.spawn(flyLoop) end end })
MiscTab:CreateDropdown({ name = "Pilih Game (Redeem)", options = {"Aladia PVP", "Alkedion", "Valkadia PVP"}, currentOption = "Aladia PVP", callback = function(option) if type(option) == "table" then selectedGame = option[1] else selectedGame = option end end })
MiscTab:CreateButton({
    name = "Redeem All Codes",
    callback = function()
        local gameName = selectedGame; local data = redeemData[gameName]
        if not data then return notify("❌ Data Gak Ada", "Kode buat " .. gameName .. " belum diisi!") end
        notify("🔄 Redeem Dimulai", "Game: " .. gameName)
        for i, code in ipairs(data.codes) do
            local success, message = redeemCode(code, data.remote, data.remoteType, data.command)
            if success then notify("✅ Redeem Berhasil", "Kode: " .. code) else notify("❌ Redeem Gagal", "Kode: " .. code) end
            task.wait(6)
        end
    end
})
MiscTab:CreateButton({ name = "Join Discord", callback = function() notify("Turok", "Join: @chgabut1") end })

-- TAB GOD MODE
GodModeTab:CreateToggle({
    name = "God Mode (Network Bypass - Kebal Tembakan)",
    currentValue = false,
    callback = function(state)
        godModeEnabled = state
        if state then task.spawn(godModeBypassLoop); notify("God Mode", "Bypass Aktif! Karakter lu gak bisa di-hit (tetap kelihatan).") end
    end
})

-- TAB SETTINGS
SettingsTab:CreateSlider({ name = "FOV Radius", range = {10, 500}, increment = 1, suffix = "", currentValue = 100, callback = function(value) fovRadius = value; if fovCircle then fovCircle.Radius = value end end })
SettingsTab:CreateSlider({ name = "Smoothness", range = {0, 1}, increment = 0.01, suffix = "", currentValue = 0.3, callback = function(value) smoothness = value end })

print("[Turok] Full Script Loaded: Aimbot + ESP + Noclip + Redeem + Kill Aura + Teleport + Fly + God Mode (Bypass)!")