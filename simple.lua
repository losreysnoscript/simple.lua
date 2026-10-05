--[[
    SIMPLE  |  Auto Sea 3  (FULL FIXED v3)
    - Correct order: Colosseum first
    - Safe high positions (no water deaths)
    - Stronger height lock while moving
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

repeat task.wait() until game.Players.LocalPlayer
    and game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PlaceId = tonumber(game.PlaceId) or game.PlaceId

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 6,
        })
    end)
end

local function DetectSea()
    if PlaceId == 2753915549 then return 1 end
    if PlaceId == 4442272183 then return 2 end
    if PlaceId == 7449423635 then return 3 end
    return 2
end

local SEA = DetectSea()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local CommF = remotes and remotes:FindFirstChild("CommF_")

if not CommF then
    Notify("SIMPLE", "Remotes not found. Wait in Blox Fruits, then execute again.")
    warn("[SIMPLE] CommF_ missing. PlaceId = " .. tostring(PlaceId))
end

local function Invoke(...)
    if not CommF then return end
    local ok, result = pcall(function(...)
        return CommF:InvokeServer(...)
    end, ...)
    if ok then
        return result
    end
end

getgenv().Simple = getgenv().Simple or {}
local S = getgenv().Simple
S.Enabled = true

-- HIGH SAFE POSITIONS (anti water death)
local COLOSSEUM_JAIL = CFrame.new(-2870, 60, -5420)
local MANSION_SAFE   = CFrame.new(2284.5, 40, 905.3)
local GREEN_ZONE_DOCK= CFrame.new(-3140, 30, -3400)

local StatusText = "Starting...  PlaceId " .. tostring(PlaceId)

local function SetStatus(t)
    StatusText = t
end

local function Level()
    return LP.Data and LP.Data.Level and LP.Data.Level.Value or 0
end

local function HRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Hum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Noclip + keep high
RunService.Stepped:Connect(function()
    if S.Enabled and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end
end)

local currentTween = nil
local function TweenTo(cf)
    local root = HRP()
    if not root then return end
    if currentTween then
        currentTween:Cancel()
    end

    -- Force high Y so we never go into water
    local highCF = CFrame.new(cf.X, math.max(cf.Y, 40), cf.Z)

    local dist = (root.Position - highCF.Position).Magnitude
    local duration = math.clamp(dist / 280, 0.2, 14)

    currentTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = highCF})
    currentTween:Play()
    currentTween.Completed:Wait()
    currentTween = nil
end

local function EnemyFolder()
    return workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Enemy")
end

local function FindDonSwan()
    local folder = EnemyFolder()
    if not folder then return end
    for _, e in ipairs(folder:GetChildren()) do
        if e.Name == "Don Swan" then
            local hum = e:FindFirstChildOfClass("Humanoid")
            local rp  = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("RootPart")
            if hum and rp and hum.Health > 0 then
                return e, rp, hum
            end
        end
    end
end

local function EquipCombat()
    local char = LP.Character
    local bag = LP:FindFirstChild("Backpack")
    if not char then return end
    if char:FindFirstChildOfClass("Tool") then return end
    if not bag then return end
    local tool = bag:FindFirstChild("Combat") or bag:FindFirstChildOfClass("Tool")
    local hum = Hum()
    if tool and hum then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
end

local function Attack()
    EquipCombat()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
end

LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- MAIN LOOP
task.spawn(function()
    while task.wait(0.5) do
        if not S.Enabled then
            if currentTween then currentTween:Cancel() end
            SetStatus("Stopped")
            continue
        end

        if not CommF then
            SetStatus("Not in Blox Fruits remotes. PlaceId " .. tostring(PlaceId))
            continue
        end

        if SEA == 3 then
            SetStatus("Already in Sea 3!")
            S.Enabled = false
            continue
        end

        if Level() < 1500 then
            SetStatus("Need Level 1500 (Current: " .. Level() .. ")")
            continue
        end

        if SEA == 1 then
            SetStatus("Traveling to Sea 2...")
            Invoke("TravelDressrosa")
            task.wait(4)
            continue
        end

        -- 1. Go high to Colosseum
        SetStatus("Going to Colosseum (King Red Head)...")
        TweenTo(COLOSSEUM_JAIL)
        task.wait(1.5)

        SetStatus("Talking to King Red Head...")
        Invoke("TalkKingRedHead")
        Invoke("TalkNPC", "King Red Head")
        Invoke("StartSea3Quest")
        task.wait(2)

        -- 2. Check Don Swan
        local swan, rp, hum = FindDonSwan()

        if swan and rp and hum then
            SetStatus("Don Swan needed → safe mansion...")
            TweenTo(MANSION_SAFE)
            task.wait(1)

            Invoke("TalkTrevor", "1")
            task.wait(0.3)
            Invoke("TalkTrevor", "2")
            task.wait(0.3)
            Invoke("TalkTrevor", "3")
            task.wait(0.6)

            swan, rp, hum = FindDonSwan()
            if swan and rp and hum then
                SetStatus("Fighting Don Swan...")
                while S.Enabled and swan and swan.Parent and hum.Health > 0 do
                    local root = HRP()
                    if root then
                        root.CFrame = rp.CFrame * CFrame.new(0, 10, 4)
                    end
                    Attack()
                    task.wait(0.05)
                end
                SetStatus("Don Swan dead.")
                task.wait(2)
            else
                SetStatus("Waiting for Don Swan (safe high)...")
                local start = tick()
                while S.Enabled and tick() - start < 18 do
                    local root = HRP()
                    if root then
                        root.CFrame = MANSION_SAFE
                    end
                    task.wait(0.3)
                    swan, rp, hum = FindDonSwan()
                    if swan and rp and hum then break end
                end
            end
        else
            SetStatus("Going to Mr. Captain (high)...")
            TweenTo(GREEN_ZONE_DOCK)
            task.wait(1.5)

            SetStatus("Talking to Mr. Captain → Sea 3...")
            Invoke("TravelZou")
            Invoke("TalkCaptain")
            Invoke("StartSea3")
            task.wait(5)
        end
    end
end)

-- GUI
pcall(function()
    if CoreGui:FindFirstChild("SimpleGui") then
        CoreGui.SimpleGui:Destroy()
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleGui"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 168)
frame.Position = UDim2.new(0, 18, 0.38, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "SIMPLE  ·  AUTO SEA 3"

local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1, -16, 0, 18)
info.Position = UDim2.new(0, 8, 0, 30)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextColor3 = Color3.fromRGB(160, 160, 170)
info.Text = "Sea " .. tostring(SEA) .. "   Lv " .. tostring(Level())

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -16, 0, 36)
status.Position = UDim2.new(0, 8, 0, 50)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextColor3 = Color3.fromRGB(220, 200, 120)
status.Text = StatusText

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 96)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.AutoButtonColor = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local hint = Instance.new("TextLabel", frame)
hint.Size = UDim2.new(1, -16, 0, 22)
hint.Position = UDim2.new(0, 8, 1, -26)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(120, 120, 130)
hint.Text = "Level 1500 in Sea 2  →  Sea 3"

local function Paint()
    if S.Enabled then
        btn.Text = "ON   Auto Sea 3"
        btn.BackgroundColor3 = Color3.fromRGB(40, 110, 70)
    else
        btn.Text = "OFF   Auto Sea 3"
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    end
end
Paint()

btn.MouseButton1Click:Connect(function()
    S.Enabled = not S.Enabled
    Paint()
end)

task.spawn(function()
    while gui.Parent and task.wait(0.4) do
        info.Text = "Sea " .. tostring(SEA) .. "   Lv " .. tostring(Level())
        status.Text = StatusText
        Paint()
    end
end)

Notify("SIMPLE", "v3 loaded - high paths, no water death")
print("[SIMPLE] Auto Sea 3 FULL FIXED v3 loaded")
