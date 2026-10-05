--[[
    SIMPLE | Auto Sea 3 (REWRITTEN v6 - ANCHORED FLIGHT & FULL QUEST FLOW)
]]

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local PlaceId = game.PlaceId

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
end

local function DetectSea()
    if PlaceId == 2753915549 then return 1 end
    if PlaceId == 4442272183 then return 2 end
    if PlaceId == 7449423635 then return 3 end
    return 2
end

local SEA = DetectSea()
local CommF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")

local function Invoke(...)
    if not CommF then return end
    local ok, r = pcall(function(...) return CommF:InvokeServer(...) end, ...)
    if ok then return r end
end

getgenv().Simple = getgenv().Simple or {Enabled = true}
local S = getgenv().Simple

-- POSITIONS
local COLOSSEUM_JAIL = CFrame.new(-2870, 65, -5420)
local MANSION_DOOR   = CFrame.new(2284.5, 15, 905.3)
local GREEN_ZONE_DOCK= CFrame.new(-3140, 35, -3400)

local StatusText = "Starting..."

local function SetStatus(t) StatusText = t end
local function Level() return LP.Data and LP.Data.Level and LP.Data.Level.Value or 0 end
local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- Noclip
RunService.Stepped:Connect(function()
    if S.Enabled and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

local currentTween = nil

-- SAFE 3-STAGE ANCHORED FLIGHT (Prevents water drag & anticheat rubberbands)
local function SmoothFlyTo(targetCF)
    local root = HRP()
    if not root then return end
    if currentTween then currentTween:Cancel() end

    -- Anchor character so gravity cannot pull you into water mid-flight
    root.Anchored = true

    local startPos = root.Position
    local flightHeight = math.max(startPos.Y, targetCF.Y, 280) -- Fly high above water
    
    local highStart = Vector3.new(startPos.X, flightHeight, startPos.Z)
    local highTarget = Vector3.new(targetCF.X, flightHeight, targetCF.Z)

    -- Stage 1: Ascend straight up safely
    if (startPos - highStart).Magnitude > 15 then
        local tUp = TweenService:Create(root, TweenInfo.new((startPos - highStart).Magnitude / 150, Enum.EasingStyle.Linear), {CFrame = CFrame.new(highStart)})
        tUp:Play()
        tUp.Completed:Wait()
    end

    -- Stage 2: Fly horizontally across the ocean
    local distAcross = (highStart - highTarget).Magnitude
    if distAcross > 15 then
        local tAcross = TweenService:Create(root, TweenInfo.new(distAcross / 160, Enum.EasingStyle.Linear), {CFrame = CFrame.new(highTarget)})
        tAcross:Play()
        tAcross.Completed:Wait()
    end

    -- Stage 3: Descend smoothly to ground destination (No instant drop)
    local tDown = TweenService:Create(root, TweenInfo.new((highTarget - targetCF.Position).Magnitude / 140, Enum.EasingStyle.Linear), {CFrame = targetCF})
    tDown:Play()
    tDown.Completed:Wait()

    -- Unanchor upon safe arrival
    root.Anchored = false
end

local function FindDonSwan()
    local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Enemy")
    if not folder then return nil end
    for _, e in ipairs(folder:GetChildren()) do
        if e.Name == "Don Swan" then
            local hum = e:FindFirstChildOfClass("Humanoid")
            local rp = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("RootPart")
            if hum and rp and hum.Health > 0 then return e, rp, hum end
        end
    end
    return nil
end

local function Attack()
    local bag = LP:FindFirstChild("Backpack")
    local tool = bag and (bag:FindFirstChild("Combat") or bag:FindFirstChildOfClass("Tool"))
    if tool and Hum() then pcall(function() Hum():EquipTool(tool) end) end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
end

LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- QUEST SEQUENCE TRACKER
local questStep = 1

task.spawn(function()
    while task.wait(0.8) do
        if not S.Enabled then
            if currentTween then currentTween:Cancel() end
            if HRP() then HRP().Anchored = false end
            SetStatus("Stopped")
            continue
        end

        if SEA == 3 then
            SetStatus("Already in Sea 3!")
            S.Enabled = false
            continue
        end

        if Level() < 1500 then
            SetStatus("Need Level 1500")
            continue
        end

        if SEA == 1 then
            SetStatus("Going to Sea 2...")
            Invoke("TravelDressrosa")
            task.wait(4)
            continue
        end

        -- STEP 1: Talk to King Red Head (Initial Quest Start)
        if questStep == 1 then
            SetStatus("1/5: Flying to Colosseum...")
            SmoothFlyTo(COLOSSEUM_JAIL)
            task.wait(1)

            SetStatus("Talking to King Red Head...")
            Invoke("TalkKingRedHead")
            Invoke("TalkNPC", "King Red Head")
            task.wait(2)
            questStep = 2
        end

        -- STEP 2: Unlock Mansion / Don Swan Door
        if questStep == 2 then
            SetStatus("2/5: Flying to Mansion...")
            SmoothFlyTo(MANSION_DOOR)
            task.wait(1)

            SetStatus("Unlocking Swan Mansion...")
            Invoke("TalkTrevor", "1") task.wait(0.5)
            Invoke("TalkTrevor", "2") task.wait(0.5)
            Invoke("TalkTrevor", "3") task.wait(1)
            questStep = 3
        end

        -- STEP 3: Defeat Don Swan
        if questStep == 3 then
            SetStatus("3/5: Checking Don Swan...")
            local swan, rp, hum = FindDonSwan()

            if swan and rp and hum then
                SetStatus("Fighting Don Swan...")
                while S.Enabled and swan and swan.Parent and hum.Health > 0 do
                    local root = HRP()
                    if root then root.CFrame = rp.CFrame * CFrame.new(0, 10, 3) end
                    Attack()
                    task.wait(0.05)
                end
                SetStatus("Don Swan Defeated!")
                task.wait(2)
                questStep = 4
            else
                -- If Don Swan hasn't spawned, wait briefly and re-check
                SetStatus("Waiting for Don Swan to load...")
                task.wait(3)
                swan, rp, hum = FindDonSwan()
                if swan then
                    questStep = 3
                else
                    -- Move on to step 4 if room/quest is already done
                    questStep = 4
                end
            end
        end

        -- STEP 4: Return to King Red Head (Mandatory step to complete quest)
        if questStep == 4 then
            SetStatus("4/5: Returning to King Red Head...")
            SmoothFlyTo(COLOSSEUM_JAIL)
            task.wait(1)

            SetStatus("Completing Quest...")
            Invoke("TalkKingRedHead")
            Invoke("TalkNPC", "King Red Head")
            task.wait(2)
            questStep = 5
        end

        -- STEP 5: Travel to Sea 3 via Mr. Captain
        if questStep == 5 then
            SetStatus("5/5: Flying to Mr. Captain...")
            SmoothFlyTo(GREEN_ZONE_DOCK)
            task.wait(1.5)

            SetStatus("Traveling to Sea 3...")
            Invoke("TravelZou")
            Invoke("TalkCaptain")
            task.wait(5)
        end
    end
end)

-- GUI
pcall(function() if CoreGui:FindFirstChild("SimpleGui") then CoreGui.SimpleGui:Destroy() end end)

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleGui"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 160)
frame.Position = UDim2.new(0, 18, 0.38, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "SIMPLE  ·  AUTO SEA 3"

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -16, 0, 40)
status.Position = UDim2.new(0, 8, 0, 34)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(220, 200, 120)
status.Text = StatusText

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -20, 0, 38)
btn.Position = UDim2.new(0, 10, 0, 90)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.AutoButtonColor = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local function Paint()
    if S.Enabled then
        btn.Text = "ON   Auto Sea 3"
        btn.BackgroundColor3 = Color3.fromRGB(40, 110, 70)
    else
        btn.Text = "OFF  Auto Sea 3"
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    end
end
Paint()

btn.MouseButton1Click:Connect(function()
    S.Enabled = not S.Enabled
    if not S.Enabled and HRP() then HRP().Anchored = false end
    Paint()
end)

task.spawn(function()
    while gui.Parent and task.wait(0.4) do
        status.Text = StatusText
        Paint()
    end
end)

Notify("SIMPLE", "v6 loaded - Anchored flight system")
print("[SIMPLE] Auto Sea 3 REWRITTEN v6")
