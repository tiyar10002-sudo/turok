local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Disable Aladia PvP's camera
local function disableCameraScript()
    local camScript = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("CVCCamera")
    if camScript and camScript:FindFirstChild("main") then
        camScript.main.Disabled = true
    end
end

task.spawn(function()
    while true do
        disableCameraScript()
        task.wait(1)
    end
end)

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "TUROK UI BY KYO",
    LoadingTitle = "Loading TUROK UI...",
    LoadingSubtitle = "BY TUROK ON DISCORD",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local CreditsTab = Window:CreateTab("Credits", 4483362458)

-- Credits
CreditsTab:CreateParagraph({
    Title = "Made By",
    Content = "turok on Discord\n\nScripted, Designed & Branded using Rayfield UI.\n\nJoin the server: https://discord.gg/YH6fxQa7uz"
})

-- Variables
local aimEnabled = false
local wallCheckEnabled = false
local fovVisible = false
local rainbowFov = false
local rainbowHighlight = false
local fovRadius = 20
local fovCircle = nil
local highlight = nil

-- ==================== TAMBAHAN LOCK BODY ====================
local lockBodyEnabled = false  -- Default: OFF (aim ke kepala)
-- ===========================================================

-- Toggles
MainTab:CreateToggle({
    Name = "AIM Assist",
    CurrentValue = false,
    Callback = function(state)
        aimEnabled = state
    end
})

MainTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(state)
        wallCheckEnabled = state
    end
})

-- ==================== TAMBAHAN TOGGLE LOCK BODY ====================
MainTab:CreateToggle({
    Name = "Lock Body",
    CurrentValue = false,
    Callback = function(state)
        lockBodyEnabled = state
    end
})
-- =================================================================

VisualsTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Callback = function(state)
        fovVisible = state
        if fovVisible and not fovCircle then
            fovCircle = Drawing.new("Circle")
            fovCircle.Thickness = 2
            fovCircle.Filled = false
            fovCircle.Radius = fovRadius
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fovCircle.Visible = true
        elseif not fovVisible and fovCircle then
            fovCircle.Visible = false
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Rainbow FOV Circle",
    CurrentValue = false,
    Callback = function(state)
        rainbowFov = state
    end
})

VisualsTab:CreateToggle({
    Name = "Rainbow Highlights",
    CurrentValue = false,
    Callback = function(state)
        rainbowHighlight = state
    end
})

-- Fix FOV circle drifting
RunService.Heartbeat:Connect(function()
    if fovCircle and fovVisible then
        task.wait()
        local screenSize = Camera.ViewportSize
        fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovCircle.Radius = fovRadius
        fovCircle.Color = rainbowFov and Color3.fromHSV(tick() % 5 / 5, 1, 1) or Color3.fromRGB(255, 255, 255)
    end

    if highlight and rainbowHighlight then
        highlight.FillColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
end)

-- Wall check
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- Get nearest target with respawn fix
local function getTarget()
    local closest, shortest = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortest and (not wallCheckEnabled or isVisible(part)) then
                            closest, shortest = player, dist
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- Aim with camera Y-offset for more accurate headshots
local currentTarget = nil
RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getTarget()
        if target and target.Character then

            -- ==================== LOGIKA LOCK BODY ====================
            local part
            local aimPos

            if lockBodyEnabled then
                -- Lock Body: aim ke HumanoidRootPart (badan)
                part = target.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    aimPos = part.Position
                end
            else
                -- Lock Head: aim ke Head dengan offset naik
                part = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Head")
                if part then
                    -- Offset upward dari HumanoidRootPart ke arah kepala
                    aimPos = part.Position + Vector3.new(0, 1.4, 0)
                end
            end
            -- ==========================================================

            if part and aimPos then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)

                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 1
                    highlight.Parent = game.CoreGui
                end

                if target ~= currentTarget then
                    currentTarget = target
                    highlight.Adornee = target.Character
                end
            end
        else
            currentTarget = nil
            if highlight then
                highlight.Adornee = nil
            end
        end
    else
        currentTarget = nil
        if highlight then
            highlight.Adornee = nil
        end
    end
end)
