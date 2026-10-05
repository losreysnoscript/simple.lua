--[[
    SIMPLE  |  Auto Sea 3
    Requirements: Level 1500+ in Sea 2
    Automates: Trevor dialogue -> Don Swan boss -> Travel to Sea 3
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

local LP = Players.LocalPlayer

-- Verify current sea place ID
local SEA = ({
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
})[game.PlaceId]

if not SEA then
    LP:Kick("Simple Auto Sea 3: Please join Blox Fruits first.")
    return
end

local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local function Invoke(...)
    local ok, result = pcall(function(...)
        return CommF:InvokeServer(...)
    end, ...)
    if ok then
        return result
    end
end

-- Global Configuration
getgenv().Simple = getgenv().Simple or {
    Enabled = true,
}
local S = getgenv().Simple

local MANSION = CFrame.new(2288.23, 15.18, 905.27)
local StatusText = "Starting..."

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

-- Continuous Noclip logic (prevents getting stuck in objects while flying)
RunService.Stepped:Connect(function()
    if S.Enabled and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end
end)

-- Safe Movement (250 studs/sec to prevent rubberbanding)
local currentTween = nil
local function TweenTo(cf)
    local root = HRP()
    if not root then return end
    
    if currentTween then
        currentTween:Cancel()
    end
    
    local dist = (root.Position - cf.Position).Magnitude
    local duration = math.clamp(dist / 250, 0.15, 10)
    
    currentTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = cf})
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

local function Attack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
end

-- Anti-AFK Protection
LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Main Loop
task.spawn(function()
    while task.wait(0.5) do
        if not S.Enabled then
            if currentTween then currentTween:Cancel() end
            SetStatus("Stopped")
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

        -- Step 1: Speak to Trevor
        SetStatus("Talking to Trevor...")
        Invoke("TalkTrevor", "1")
        task.wait(0.3)
        Invoke("TalkTrevor", "2")
        task.wait(0.3)
        Invoke("TalkTrevor", "3")
        task.wait(0.3)

        -- Step 2: Check for Don Swan
        local swan, rp, hum = FindDonSwan()

        if swan and rp and hum then
            SetStatus("Fighting Don Swan...")
            while S.Enabled and swan and swan.Parent and hum.Health > 0 do
                local root = HRP()
                if root then
                    root.CFrame = rp.CFrame * CFrame.new(0, 8, 3)
                end
                Attack()
                task.wait(0.05)
            end
        else
            SetStatus("Going to Don Swan mansion...")
            TweenTo(MANSION)
            task.wait(1)

            swan, rp, hum = FindDonSwan()
            if swan and rp and hum then
                SetStatus("Fighting Don Swan...")
                while S.Enabled and swan and swan.Parent and hum.Health > 0 do
                    local root = HRP()
                    if root then
                        root.CFrame = rp.CFrame * CFrame.new(0, 8, 3)
                    end
                    Attack()
                    task.wait(0.05)
                end
            else
                SetStatus("Attempting to travel to Sea 3...")
                Invoke("TravelZou")
                task.wait(3)

                if SEA == 2 then
                    SetStatus("Waiting for Don Swan to spawn...")
                    task.wait(5)
                end
            end
        end
    end
end)

-- GUI Setup
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

print("[SIMPLE] Auto Sea 3 script fully loaded!")
