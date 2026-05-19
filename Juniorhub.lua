-- Junior Hub | Rayfield UI
-- Auto M1 + Flight + Mob ESP + Player ESP + Auto Accept All Quests + Auto Stat Points + Auto Ascend + Auto Redeem Codes
-- Place in StarterPlayerScripts as a LocalScript

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ========================================
--          HELPER FUNCTIONS (TOP)
-- ========================================

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ========================================
--              AUTO M1
-- ========================================

local AutoM1Enabled = false
local M1Delay       = 1 / 3
local lastM1        = 0

local function getAttackArgs()
    local root = getRoot()
    if not root then return nil end
    local mouse = LocalPlayer:GetMouse()
    return {
        [1] = 4,
        [2] = {
            ["targetCF"]            = mouse.Hit,
            ["moveDirectionStr"]    = "Forward",
            ["clientPredictCastId"] = HttpService:GenerateGUID(false),
            ["characterType"]       = "Player",
            ["releaseCF"]           = root.CFrame,
            ["characterId"]         = LocalPlayer.UserId,
            ["trackTargetId"]       = "0"
        }
    }
end

RunService.Heartbeat:Connect(function()
    if not AutoM1Enabled then return end
    local now = tick()
    if now - lastM1 >= M1Delay then
        lastM1 = now
        local args = getAttackArgs()
        if args then
            pcall(function()
                RS.Msg.RemoteEvent.ReleaseGroupSkill:FireServer(unpack(args))
            end)
        end
    end
end)

-- ========================================
--               NO FOG
-- ========================================

local NoFogEnabled        = false
local FogConn             = nil
local FogDescConn         = nil
local originalFogEnd      = nil
local originalFogStart    = nil
local savedAtmosphere     = {}

local function applyNoFog()
    local Lighting = game:GetService("Lighting")
    originalFogEnd   = Lighting.FogEnd
    originalFogStart = Lighting.FogStart
    Lighting.FogEnd   = 100000
    Lighting.FogStart = 100000
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            savedAtmosphere = { Density = obj.Density, Offset = obj.Offset, Haze = obj.Haze, Glare = obj.Glare }
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end
    FogConn = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if NoFogEnabled then Lighting.FogEnd = 100000 end
    end)
    FogDescConn = Lighting.DescendantAdded:Connect(function(obj)
        if NoFogEnabled and obj:IsA("Atmosphere") then
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end)
end

local function removeNoFog()
    if FogConn     then FogConn:Disconnect();     FogConn     = nil end
    if FogDescConn then FogDescConn:Disconnect(); FogDescConn = nil end
    local Lighting = game:GetService("Lighting")
    if originalFogEnd   then Lighting.FogEnd   = originalFogEnd   end
    if originalFogStart then Lighting.FogStart = originalFogStart end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") and savedAtmosphere.Density then
            obj.Density = savedAtmosphere.Density; obj.Offset = savedAtmosphere.Offset
            obj.Haze = savedAtmosphere.Haze; obj.Glare = savedAtmosphere.Glare
        end
    end
    savedAtmosphere = {}
end

-- ========================================
--         REMOVE TEXTURES / VISUALS
-- ========================================

local savedShadows, savedGrassLength, savedDecorations = nil, nil, nil

local function removeShadows()
    local L = game:GetService("Lighting")
    savedShadows = L.GlobalShadows; L.GlobalShadows = false
end
local function restoreShadows()
    local L = game:GetService("Lighting")
    if savedShadows ~= nil then L.GlobalShadows = savedShadows end
end

local function removeGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        savedGrassLength = terrain.GrassLength; savedDecorations = terrain.Decoration
        terrain.GrassLength = 0; terrain.Decoration = false
    end
end
local function restoreGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if savedGrassLength ~= nil then terrain.GrassLength = savedGrassLength end
        if savedDecorations ~= nil then terrain.Decoration  = savedDecorations end
    end
end

local savedMaterials, savedTextures = {}, {}

local function removeTextures()
    savedMaterials = {}; savedTextures = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then savedMaterials[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic end
        if obj:IsA("Texture") or obj:IsA("Decal") then savedTextures[obj] = obj.Transparency; obj.Transparency = 1 end
    end
end
local function restoreTextures()
    for obj, mat in pairs(savedMaterials) do if obj and obj.Parent then obj.Material = mat end end
    for obj, trans in pairs(savedTextures) do if obj and obj.Parent then obj.Transparency = trans end end
    savedMaterials = {}; savedTextures = {}
end

local savedEffects = {}
local function removePostFX()
    savedEffects = {}
    for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("PostEffect") then savedEffects[obj] = obj.Enabled; obj.Enabled = false end
    end
end
local function restorePostFX()
    for obj, state in pairs(savedEffects) do if obj and obj.Parent then obj.Enabled = state end end
    savedEffects = {}
end

-- ========================================
--           FULL BRIGHT
-- ========================================

local FullBrightEnabled = false
local FB_savedAmbient, FB_savedOutdoor, FB_savedBrightness, FB_savedColorShift, FB_Conn = nil, nil, nil, nil, nil

local function applyFullBright()
    local L = game:GetService("Lighting")
    FB_savedAmbient = L.Ambient; FB_savedOutdoor = L.OutdoorAmbient
    FB_savedBrightness = L.Brightness; FB_savedColorShift = L.ColorShift_Bottom
    L.Ambient = Color3.new(1,1,1); L.OutdoorAmbient = Color3.new(1,1,1)
    L.Brightness = 2; L.ColorShift_Bottom = Color3.new(0,0,0)
    FB_Conn = L:GetPropertyChangedSignal("Brightness"):Connect(function()
        if FullBrightEnabled then L.Brightness = 2 end
    end)
end

local function removeFullBright()
    if FB_Conn then FB_Conn:Disconnect(); FB_Conn = nil end
    local L = game:GetService("Lighting")
    if FB_savedAmbient    then L.Ambient          = FB_savedAmbient    end
    if FB_savedOutdoor    then L.OutdoorAmbient   = FB_savedOutdoor    end
    if FB_savedBrightness then L.Brightness       = FB_savedBrightness end
    if FB_savedColorShift then L.ColorShift_Bottom = FB_savedColorShift end
end

-- ========================================
--         TIME OF DAY CONTROL
-- ========================================

local ClockConn = nil

local function lockTime(hour)
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
    local L = game:GetService("Lighting")
    L.ClockTime = hour
    ClockConn = RunService.Heartbeat:Connect(function() L.ClockTime = hour end)
end

local function unlockTime()
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
end

-- ========================================
--           AUTO TAKE QUEST
-- ========================================

local AutoQuestEnabled = false
local AutoQuestThread  = nil

local function runQuestSequence()
    local qKey  = string.char(229,143,145,230,148,190,228,187,187,229,138,161)
    local qBase = string.char(228,187,187,229,138,161)
    local qArg1 = string.char(232,167,166,229,143,145,232,129,138,229,164,169)
    local qArg2 = string.char(229,147,136,229,136,169,229,155,160,231,137,185)
    pcall(function() RS.Msg.RemoteEvent.RemoteEvent:FireServer(qArg1, {qArg2, "10010100"}) end)
    task.wait(0.4)
    pcall(function() RS.Msg.RemoteEvent.RemoteEvent:FireServer(qArg1, {qArg2, 10010501}) end)
    task.wait(0.4)
    pcall(function() RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "6"}) end)
    task.wait(0.4)
    pcall(function() RS.Msg.RemoteFunction.Setting:InvokeServer("TASK", 1) end)
    task.wait(0.4)
    pcall(function() RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "4"}) end)
    task.wait(0.4)
    pcall(function() RS.Msg.RemoteFunction.Setting:InvokeServer("TASK", 1) end)
    task.wait(0.4)
    pcall(function() RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "3"}) end)
    task.wait(0.4)
    pcall(function() RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "2"}) end)
end

local function startAutoQuest()
    AutoQuestThread = task.spawn(function()
        while AutoQuestEnabled do runQuestSequence(); task.wait(2) end
    end)
end

local function stopAutoQuest()
    AutoQuestEnabled = false
    if AutoQuestThread then task.cancel(AutoQuestThread); AutoQuestThread = nil end
end

-- ========================================
--               AUTO SELL
-- ========================================

local AutoSellEnabled = false
local AutoSellThread  = nil

local function runSellSequence()
    local str1 = string.char(232, 167, 166, 229, 143, 145, 232, 129, 138, 229, 164, 169)
    local str2 = string.char(233, 154, 134, 229, 183, 180, 231, 137, 185)
    local str3 = string.char(230, 137, 147, 229, 188, 128, 231, 149, 140, 233, 157, 162)
    local str4 = string.char(229, 135, 186, 229, 148, 174, 232, 131, 140, 229, 140, 133, 231, 137, 169, 229, 147, 129)
    local str5 = string.char(229, 136, 183, 230, 150, 176, 229, 188, 149, 229, 175, 188)

    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(str1, {str2, "10030100"})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(str1, {str2, 10030401})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(str3, {"SellPop"})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteFunction.RemoteFunction:InvokeServer(str4, {
            ["onlyIDList"] = {1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157}
        })
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(str5)
    end)
end

local function startAutoSell()
    AutoSellThread = task.spawn(function()
        while AutoSellEnabled do runSellSequence(); task.wait(2) end
    end)
end

local function stopAutoSell()
    AutoSellEnabled = false
    if AutoSellThread then task.cancel(AutoSellThread); AutoSellThread = nil end
end

-- ========================================
--             AUTO ASCEND
-- ========================================

local AutoAscendEnabled = false
local AutoAscendThread  = nil

local function tryAscend()
    local isMaxLv = LocalPlayer:FindFirstChild("IsMaxLv")
    if not isMaxLv or not isMaxLv.Value then return false end
    pcall(function() RS.Msg.RemoteFunction.RemoteFunction:InvokeServer("\233\135\141\231\148\159") end)
    task.wait(0.5)
    pcall(function() RS.Msg.RemoteEvent.RemoteEvent:FireServer("\229\136\183\230\150\176\229\188\149\229\175\188") end)
    return true
end

local function startAutoAscend()
    AutoAscendThread = task.spawn(function()
        while AutoAscendEnabled do
            local didAscend = tryAscend()
            task.wait(didAscend and 3 or 1)
        end
    end)
end

local function stopAutoAscend()
    AutoAscendEnabled = false
    if AutoAscendThread then task.cancel(AutoAscendThread); AutoAscendThread = nil end
end

-- ========================================
--           AUTO STAT POINTS
-- ========================================

local STAT_KEY = "\229\177\158\230\128\167\229\138\160\231\130\185"

local STAT_TYPES = {
    { name = "Strength",           id = 1  },
    { name = "HP",                 id = 5  },
    { name = "Cooldown Reduction", id = 39 },
    { name = "Movement Speed",     id = 41 },
}

local StatPointAlloc = { [1]=0, [5]=0, [39]=0, [41]=0 }

local AutoStatEnabled  = false
local AutoStatThread   = nil
local AutoStatLoopStat = 1

local function putPoints(attrTp, amount)
    if amount <= 0 then return end
    pcall(function()
        RS.Msg.RemoteFunction.RemoteFunction:InvokeServer(STAT_KEY, { ["PointNum"]=amount, ["AttrTp"]=attrTp })
    end)
end

local function runStatSequence()
    for attrTp, amount in pairs(StatPointAlloc) do putPoints(attrTp, amount); task.wait(0.3) end
end

local function runStatLoop()
    AutoStatThread = task.spawn(function()
        while AutoStatEnabled do putPoints(AutoStatLoopStat, 1); task.wait(0.5) end
    end)
end

local function stopAutoStat()
    AutoStatEnabled = false
    if AutoStatThread then task.cancel(AutoStatThread); AutoStatThread = nil end
end

-- ========================================
--           AUTO REDEEM CODES
-- ========================================

local CODES = { "SPELL","BREW","RELEASE","WIZARD","17kCCU","20kMembers" }

local function redeemCode(code)
    pcall(function() RS.Msg.RemoteFunction.RemoteFunction:InvokeServer("\229\133\145\230\141\162\231\160\129", code) end)
end

local function redeemAllCodes()
    for _, code in ipairs(CODES) do redeemCode(code); task.wait(0.5) end
end

-- ========================================
--               MOB ESP CONFIG
-- ========================================

local ESP_CONFIG = {
    MobFolder    = "Monster",
    MobTag       = "",
    ShowName     = true,
    ShowHealth   = true,
    ShowDistance = true,
    MaxDistance  = 0,
    IDPrefixes   = {"11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30"},
    FilterByID   = false,
}

-- ========================================
--             MOB AUTOFARM
-- ========================================

local AutoFarmEnabled    = false
local AutoFarmThread     = nil
local AutoFarmRadius     = 50
local FARM_HOVER_HEIGHT  = 10

local function getNearestMob()
    local root = getRoot()
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if not folder then return nil end
    local candidates = {}
    for _, obj in ipairs(folder:GetChildren()) do if obj:IsA("Model") then table.insert(candidates, obj) end end
    if #candidates == 0 then
        for _, obj in ipairs(folder:GetDescendants()) do if obj:IsA("Model") then table.insert(candidates, obj) end end
    end
    for _, obj in ipairs(candidates) do
        local hum     = obj:FindFirstChildOfClass("Humanoid")
        local mobRoot = obj:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and mobRoot then
            local dist = (mobRoot.Position - root.Position).Magnitude
            if dist < nearestDist and dist <= AutoFarmRadius then nearest = mobRoot; nearestDist = dist end
        end
    end
    return nearest, nearestDist
end

local function startAutoFarm()
    AutoFarmThread = task.spawn(function()
        while AutoFarmEnabled do
            local root = getRoot()
            local mobRoot = getNearestMob()
            if root and mobRoot then
                root.CFrame = CFrame.new(mobRoot.Position + Vector3.new(0, FARM_HOVER_HEIGHT, 0))
                root.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.05)
        end
    end)
end

local function stopAutoFarm()
    AutoFarmEnabled = false
    if AutoFarmThread then task.cancel(AutoFarmThread); AutoFarmThread = nil end
end

-- ========================================
--               FLIGHT
-- ========================================

local FlyEnabled = false
local FlySpeed   = 60
local FlyConn, FlyVel, FlyAlign, FlyAtt0, FlyAtt1 = nil, nil, nil, nil, nil

local function startFly()
    local root = getRoot(); local hum = getHumanoid()
    if not root or not hum then return end
    hum.PlatformStand = true
    FlyAtt0 = Instance.new("Attachment"); FlyAtt0.Parent = root
    FlyAtt1 = Instance.new("Attachment"); FlyAtt1.Parent = workspace.Terrain
    FlyVel = Instance.new("LinearVelocity")
    FlyVel.Attachment0 = FlyAtt0; FlyVel.MaxForce = math.huge
    FlyVel.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FlyVel.VectorVelocity = Vector3.zero; FlyVel.Parent = root
    FlyAlign = Instance.new("AlignOrientation")
    FlyAlign.Attachment0 = FlyAtt0; FlyAlign.Attachment1 = FlyAtt1
    FlyAlign.MaxTorque = math.huge; FlyAlign.MaxAngularVelocity = math.huge
    FlyAlign.Responsiveness = 200; FlyAlign.RigidityEnabled = true; FlyAlign.Parent = root
    FlyConn = RunService.Heartbeat:Connect(function()
        local r = getRoot(); if not r then return end
        local dir = Vector3.zero; local cf = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis  end
        FlyVel.VectorVelocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * FlySpeed
        local lookDir = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if lookDir.Magnitude > 0 then FlyAtt1.CFrame = CFrame.new(Vector3.zero, lookDir) end
    end)
end

local function stopFly()
    if FlyConn  then FlyConn:Disconnect();  FlyConn  = nil end
    if FlyVel   then FlyVel:Destroy();      FlyVel   = nil end
    if FlyAlign then FlyAlign:Destroy();    FlyAlign = nil end
    if FlyAtt0  then FlyAtt0:Destroy();     FlyAtt0  = nil end
    if FlyAtt1  then FlyAtt1:Destroy();     FlyAtt1  = nil end
    local hum = getHumanoid(); if hum then hum.PlatformStand = false end
end

local function setFly(state) FlyEnabled = state; if state then startFly() else stopFly() end end

LocalPlayer.CharacterAdded:Connect(function() setFly(false); task.wait(0.1) end)

-- ========================================
--               MOB ESP
-- ========================================

local MobESPEnabled      = false
local MobESPFolder       = nil
local MobESPUpdateConn   = nil

local function mobMatchesIDFilter(obj)
    if not ESP_CONFIG.FilterByID then return true end
    for _, prefix in ipairs(ESP_CONFIG.IDPrefixes) do
        if obj.Name:sub(1, #prefix) == prefix and tonumber(obj.Name) then return true end
    end
    return false
end

local function getMobs()
    local mobs = {}; local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and mobMatchesIDFilter(obj) then table.insert(mobs, obj) end
        end
        if #mobs == 0 then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and mobMatchesIDFilter(obj) then table.insert(mobs, obj) end
            end
        end
    end
    return mobs
end

local function makeMobGui(mob)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildOfClass("BasePart")
    if not root then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "MobESP_" .. mob.Name; bb.Adornee = root; bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,160,0,70); bb.StudsOffset = Vector3.new(0,3.2,0)
    bb.MaxDistance = ESP_CONFIG.MaxDistance > 0 and ESP_CONFIG.MaxDistance or math.huge
    bb.Parent = MobESPFolder
    if ESP_CONFIG.ShowHealth then
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local hpBg = Instance.new("Frame"); hpBg.BackgroundColor3 = Color3.fromRGB(15,15,15)
        hpBg.BorderSizePixel = 0; hpBg.Size = UDim2.new(0,7,1,0); hpBg.Position = UDim2.new(0,0,0,0); hpBg.Parent = bb
        local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(200,200,200); stroke.Thickness = 0.8; stroke.Parent = hpBg
        local fill = Instance.new("Frame"); fill.Name = "HPFill"; fill.AnchorPoint = Vector2.new(0,1)
        fill.BorderSizePixel = 0; fill.BackgroundColor3 = Color3.fromRGB(0,210,60)
        fill.Size = UDim2.new(1,0,1,0); fill.Position = UDim2.new(0,0,1,0); fill.Parent = hpBg
        if hum then
            local function updateHP()
                local pct = hum.Health / math.max(hum.MaxHealth, 1)
                fill.Size = UDim2.new(1,0,pct,0)
                fill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(210*pct), 20)
            end
            updateHP(); hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
        end
    end
    local cx = 11; local yPx = 0
    if ESP_CONFIG.ShowName then
        local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1,-cx,0,24); lbl.Position = UDim2.new(0,cx,0,yPx)
        lbl.Text = mob.Name; lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.TextStrokeTransparency = 0.65; lbl.TextScaled = true
        lbl.Font = Enum.Font.FredokaOne; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = bb; yPx += 24
    end
    if ESP_CONFIG.ShowDistance then
        local lbl = Instance.new("TextLabel"); lbl.Name = "DistLbl"; lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1,-cx,0,18); lbl.Position = UDim2.new(0,cx,0,yPx)
        lbl.Text = "0 studs"; lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.TextStrokeTransparency = 0.65; lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = bb; yPx += 18
    end
    if ESP_CONFIG.ShowHealth then
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local hpLbl = Instance.new("TextLabel"); hpLbl.Name = "HPLbl"; hpLbl.BackgroundTransparency = 1
        hpLbl.Size = UDim2.new(1,-cx,0,16); hpLbl.Position = UDim2.new(0,cx,0,yPx)
        hpLbl.TextColor3 = Color3.fromRGB(255,255,255); hpLbl.TextStrokeTransparency = 0.65
        hpLbl.TextScaled = true; hpLbl.Font = Enum.Font.GothamMedium
        hpLbl.TextXAlignment = Enum.TextXAlignment.Left; hpLbl.Parent = bb
        if hum then
            local function updateHPLbl() hpLbl.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) end
            updateHPLbl(); hum:GetPropertyChangedSignal("Health"):Connect(updateHPLbl)
        end
    end
end

local function startMobESP()
    MobESPFolder = Instance.new("Folder"); MobESPFolder.Name = "MobESPHolder"; MobESPFolder.Parent = LocalPlayer.PlayerGui
    for _, mob in ipairs(getMobs()) do makeMobGui(mob) end
    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        folder.DescendantAdded:Connect(function(obj)
            if not MobESPEnabled then return end
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then task.wait(); makeMobGui(obj) end
        end)
    end
    MobESPUpdateConn = RunService.Heartbeat:Connect(function()
        if not MobESPEnabled or not ESP_CONFIG.ShowDistance then return end
        local myRoot = getRoot(); if not myRoot or not MobESPFolder then return end
        for _, bb in ipairs(MobESPFolder:GetChildren()) do
            local lbl = bb:FindFirstChild("DistLbl"); local adornee = bb.Adornee
            if lbl and adornee then lbl.Text = math.floor((adornee.Position - myRoot.Position).Magnitude) .. " studs" end
        end
    end)
end

local function stopMobESP()
    if MobESPUpdateConn then MobESPUpdateConn:Disconnect(); MobESPUpdateConn = nil end
    if MobESPFolder then MobESPFolder:Destroy(); MobESPFolder = nil end
end

-- ========================================
--             PLAYER ESP
-- ========================================

local PlayerESP_CONFIG = {
    ShowName=true, ShowHealth=true, ShowTeam=true, ShowDistance=true, MaxDistance=0,
    NameColor=Color3.fromRGB(255,255,255), DistColor=Color3.fromRGB(255,220,50),
}

local PlayerESPEnabled    = false
local PlayerESPFolder     = nil
local PlayerESPConns      = {}
local PlayerESPUpdateConn = nil

local function makePlayerGui(player)
    if player == LocalPlayer then return end
    local function build()
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local old = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
        if old then old:Destroy() end
        local bb = Instance.new("BillboardGui"); bb.Name = "ESP_" .. player.Name; bb.Adornee = root
        bb.AlwaysOnTop = true; bb.Size = UDim2.new(0,170,0,70); bb.StudsOffset = Vector3.new(0,3.5,0)
        bb.MaxDistance = PlayerESP_CONFIG.MaxDistance > 0 and PlayerESP_CONFIG.MaxDistance or math.huge
        bb.Parent = PlayerESPFolder
        if PlayerESP_CONFIG.ShowHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hpBg = Instance.new("Frame"); hpBg.BackgroundColor3 = Color3.fromRGB(15,15,15)
            hpBg.BorderSizePixel = 0; hpBg.Size = UDim2.new(0,7,1,0); hpBg.Parent = bb
            local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255,255,255); stroke.Thickness = 0.8; stroke.Parent = hpBg
            local fill = Instance.new("Frame"); fill.Name = "HPFill"; fill.AnchorPoint = Vector2.new(0,1)
            fill.BorderSizePixel = 0; fill.BackgroundColor3 = Color3.fromRGB(0,210,60)
            fill.Size = UDim2.new(1,0,1,0); fill.Position = UDim2.new(0,0,1,0); fill.Parent = hpBg
            if hum then
                local function updateHP()
                    local pct = hum.Health / math.max(hum.MaxHealth, 1)
                    fill.Size = UDim2.new(1,0,pct,0)
                    fill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(210*pct), 20)
                end
                updateHP(); hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
            end
        end
        local cx = 14; local yPx = 0
        if PlayerESP_CONFIG.ShowName then
            local lbl = Instance.new("TextLabel"); lbl.Name = "NameLbl"; lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1,-cx,0,26); lbl.Position = UDim2.new(0,cx,0,yPx)
            lbl.Text = player.Name; lbl.TextColor3 = PlayerESP_CONFIG.NameColor
            lbl.TextStrokeTransparency = 0.3; lbl.TextScaled = true
            lbl.Font = Enum.Font.FredokaOne; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = bb; yPx += 26
        end
        if PlayerESP_CONFIG.ShowDistance then
            local lbl = Instance.new("TextLabel"); lbl.Name = "DistLbl"; lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1,-cx,0,20); lbl.Position = UDim2.new(0,cx,0,yPx)
            lbl.Text = "0 studs"; lbl.TextColor3 = PlayerESP_CONFIG.DistColor
            lbl.TextStrokeTransparency = 0.4; lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = bb; yPx += 20
        end
        if PlayerESP_CONFIG.ShowTeam and player.Team then
            local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1,-cx,0,18); lbl.Position = UDim2.new(0,cx,0,yPx)
            lbl.Text = "[" .. player.Team.Name .. "]"; lbl.TextColor3 = player.Team.TeamColor.Color
            lbl.TextStrokeTransparency = 0.5; lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = bb
        end
    end
    build()
    local conn = player.CharacterAdded:Connect(function() task.wait(0.5); build() end)
    table.insert(PlayerESPConns, conn)
end

local function startPlayerESP()
    PlayerESPFolder = Instance.new("Folder"); PlayerESPFolder.Name = "PlayerESPHolder"; PlayerESPFolder.Parent = LocalPlayer.PlayerGui
    for _, player in ipairs(Players:GetPlayers()) do makePlayerGui(player) end
    local addedConn = Players.PlayerAdded:Connect(function(player)
        if not PlayerESPEnabled then return end; task.wait(1); makePlayerGui(player)
    end)
    table.insert(PlayerESPConns, addedConn)
    local removedConn = Players.PlayerRemoving:Connect(function(player)
        local gui = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
        if gui then gui:Destroy() end
    end)
    table.insert(PlayerESPConns, removedConn)
    PlayerESPUpdateConn = RunService.Heartbeat:Connect(function()
        if not PlayerESPEnabled or not PlayerESP_CONFIG.ShowDistance then return end
        local myRoot = getRoot(); if not myRoot then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); if not root then continue end
            local gui = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
            local lbl = gui and gui:FindFirstChild("DistLbl")
            if lbl then lbl.Text = math.floor((root.Position - myRoot.Position).Magnitude) .. " studs" end
        end
    end)
end

local function stopPlayerESP()
    if PlayerESPUpdateConn then PlayerESPUpdateConn:Disconnect(); PlayerESPUpdateConn = nil end
    for _, conn in ipairs(PlayerESPConns) do conn:Disconnect() end
    PlayerESPConns = {}
    if PlayerESPFolder then PlayerESPFolder:Destroy(); PlayerESPFolder = nil end
end

-- ========================================
--           NPC TELEPORT
-- ========================================

local NPC_LIST = {
    { label = "Chest TP", id = "101" }, { label = "Chest 1",  id = "103" },
    { label = "Chest 2",  id = "104" }, { label = "Chest 3",  id = "105" },
    { label = "Chest 4",  id = "106" }, { label = "Chest 5",  id = "107" },
    { label = "Chest 6",  id = "108" }, { label = "Chest 7",  id = "109" },
    { label = "Chest 8",  id = "110" },
}

local function findNPCAnywhere(npcId)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == npcId and obj:IsA("Model") then return obj end
    end
    return nil
end

local function tpToNPC(npcId)
    local root = getRoot()
    if not root then return end
    local npc = findNPCAnywhere(npcId)
    if not npc then return end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then for _, v in ipairs(npc:GetDescendants()) do if v:IsA("BasePart") then npcRoot = v; break end end end
    if npcRoot then
        root.CFrame = CFrame.new(npcRoot.Position + Vector3.new(0,3,0))
        task.wait(0.3)
        local ok, err = pcall(function() RS.Msg.RemoteFunction.SystemChestRemoteFunction:InvokeServer(npcId) end)
        if not ok then
            pcall(function() RS.Msg.RemoteFunction.SystemChestRemoteFunction:InvokeServer(tonumber(npcId)) end)
        end
    end
end

-- ========================================
--           STOP ALL FEATURES
-- ========================================

local function stopAllFeatures()
    AutoM1Enabled = false; NoFogEnabled = false; _G.DaxinInfJump = false
    stopAutoQuest(); stopAutoFarm(); stopAutoSell(); stopAutoStat(); stopAutoAscend()
    setFly(false); stopMobESP(); stopPlayerESP()
    removeNoFog(); restoreShadows(); restoreGrass(); restoreTextures(); restorePostFX()
    MobESPEnabled = false; PlayerESPEnabled = false
    removeFullBright(); unlockTime(); FullBrightEnabled = false
end

-- ========================================
--              RAYFIELD UI
-- ========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = "Junior Hub",
    Icon             = 0,
    LoadingTitle     = "Junior Hub",
    LoadingSubtitle  = "by Junior",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "JuniorHub",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ===== MAIN TAB =====
local MainTab = Window:CreateTab("⚔️ Main", nil)

-- Auto M1
local M1Section = MainTab:CreateSection("Auto M1")

MainTab:CreateToggle({
    Name        = "Enable Auto M1",
    CurrentValue = false,
    Flag        = "AutoM1",
    Callback    = function(value)
        AutoM1Enabled = value
    end,
})

MainTab:CreateLabel("Attack speed: 3 per second (fixed).")

-- Auto Farm
local FarmSection = MainTab:CreateSection("Mob Auto Farm")

MainTab:CreateToggle({
    Name        = "Enable Auto Farm",
    CurrentValue = false,
    Flag        = "AutoFarm",
    Callback    = function(value)
        AutoFarmEnabled = value
        if value then startAutoFarm() else stopAutoFarm() end
    end,
})

MainTab:CreateSlider({
    Name        = "Farm Radius",
    Range       = {10, 500},
    Increment   = 1,
    Suffix      = " studs",
    CurrentValue = 50,
    Flag        = "FarmRadius",
    Callback    = function(value) AutoFarmRadius = value end,
})

MainTab:CreateSlider({
    Name        = "Hover Height",
    Range       = {10, 50},
    Increment   = 1,
    Suffix      = " studs",
    CurrentValue = 10,
    Flag        = "FarmHover",
    Callback    = function(value) FARM_HOVER_HEIGHT = value end,
})

MainTab:CreateLabel("Enable Auto M1 alongside Auto Farm.")

-- Auto Quest
local QuestSection = MainTab:CreateSection("Auto Accept All Quests")

MainTab:CreateToggle({
    Name        = "Enable Auto Quest",
    CurrentValue = false,
    Flag        = "AutoQuest",
    Callback    = function(value)
        AutoQuestEnabled = value
        if value then startAutoQuest() else stopAutoQuest() end
    end,
})

MainTab:CreateButton({
    Name     = "Take Quest Once",
    Callback = function() task.spawn(runQuestSequence) end,
})

MainTab:CreateLabel("Loop re-takes every 2s.")

-- Auto Sell
local SellSection = MainTab:CreateSection("Auto Sell")

MainTab:CreateToggle({
    Name        = "Enable Auto Sell",
    CurrentValue = false,
    Flag        = "AutoSell",
    Callback    = function(value)
        AutoSellEnabled = value
        if value then startAutoSell() else stopAutoSell() end
    end,
})

MainTab:CreateButton({
    Name     = "Sell Once",
    Callback = function() task.spawn(runSellSequence) end,
})

MainTab:CreateLabel("Only sells trash / useless items. Loop every 2s.")

-- Auto Ascend
local AscendSection = MainTab:CreateSection("Auto Ascend")

MainTab:CreateToggle({
    Name        = "Enable Auto Ascend",
    CurrentValue = false,
    Flag        = "AutoAscend",
    Callback    = function(value)
        AutoAscendEnabled = value
        if value then startAutoAscend() else stopAutoAscend() end
    end,
})

MainTab:CreateButton({
    Name     = "Ascend Once",
    Callback = function() tryAscend() end,
})

MainTab:CreateLabel("Only ascends when max level. Checks every 1s.")

-- Redeem Codes
local CodesSection = MainTab:CreateSection("Redeem Codes")

MainTab:CreateButton({
    Name     = "Redeem All Codes",
    Callback = function() task.spawn(redeemAllCodes) end,
})

MainTab:CreateLabel("Codes: SPELL, BREW, RELEASE, WIZARD, 17kCCU, 20kMembers")

-- Auto Stat Points
local StatSection = MainTab:CreateSection("Auto Stat Points")

for _, stat in ipairs(STAT_TYPES) do
    local capturedId = stat.id
    MainTab:CreateSlider({
        Name        = stat.name .. " Points",
        Range       = {0, 100},
        Increment   = 1,
        Suffix      = " pts",
        CurrentValue = 0,
        Flag        = "Stat_" .. tostring(stat.id),
        Callback    = function(value) StatPointAlloc[capturedId] = value end,
    })
end

MainTab:CreateButton({
    Name     = "Distribute Points Once",
    Callback = function() task.spawn(runStatSequence) end,
})

MainTab:CreateDropdown({
    Name        = "Loop Stat",
    Options     = {"Strength", "HP", "Cooldown Reduction", "Movement Speed"},
    CurrentOption = {"Strength"},
    Flag        = "StatLoopTarget",
    Callback    = function(value)
        local v = type(value) == "table" and value[1] or value
        for _, s in ipairs(STAT_TYPES) do
            if s.name == v then AutoStatLoopStat = s.id; break end
        end
    end,
})

MainTab:CreateToggle({
    Name        = "Enable Stat Loop",
    CurrentValue = false,
    Flag        = "AutoStat",
    Callback    = function(value)
        AutoStatEnabled = value
        if value then runStatLoop() else stopAutoStat() end
    end,
})

MainTab:CreateLabel("Needs free stat points to work.")

-- ===== FLYING TAB =====
local FlyTab = Window:CreateTab("🛫 Flying", nil)
local FlySection = FlyTab:CreateSection("Flight")

FlyTab:CreateToggle({
    Name        = "Enable Flight",
    CurrentValue = false,
    Flag        = "FlyToggle",
    Callback    = function(value) setFly(value) end,
})

FlyTab:CreateSlider({
    Name        = "Flight Speed",
    Range       = {10, 500},
    Increment   = 1,
    Suffix      = " studs/s",
    CurrentValue = 60,
    Flag        = "FlySpeed",
    Callback    = function(value) FlySpeed = value end,
})

FlyTab:CreateSlider({
    Name        = "Walk Speed",
    Range       = {1, 300},
    Increment   = 1,
    Suffix      = " studs/s",
    CurrentValue = 16,
    Flag        = "WalkSpeed",
    Callback    = function(value)
        local hum = getHumanoid(); if hum then hum.WalkSpeed = value end
    end,
})

FlyTab:CreateSlider({
    Name        = "Jump Power",
    Range       = {0, 300},
    Increment   = 1,
    CurrentValue = 50,
    Flag        = "JumpPower",
    Callback    = function(value)
        local hum = getHumanoid()
        if hum then hum.UseJumpPower = true; hum.JumpPower = value end
    end,
})

FlyTab:CreateToggle({
    Name        = "Infinite Jump",
    CurrentValue = false,
    Flag        = "InfJump",
    Callback    = function(value) _G.DaxinInfJump = value end,
})

UserInputService.JumpRequest:Connect(function()
    if _G.DaxinInfJump then
        local hum = getHumanoid(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ===== ESP TAB =====
local ESPTab = Window:CreateTab("👁️ ESP", nil)

local MobESPSection = ESPTab:CreateSection("Mob ESP")

ESPTab:CreateToggle({
    Name        = "Enable Mob ESP",
    CurrentValue = false,
    Flag        = "MobESP",
    Callback    = function(value)
        MobESPEnabled = value
        if value then startMobESP() else stopMobESP() end
    end,
})

ESPTab:CreateToggle({
    Name        = "Show Names",
    CurrentValue = true,
    Flag        = "MobShowNames",
    Callback    = function(value) ESP_CONFIG.ShowName = value end,
})

ESPTab:CreateToggle({
    Name        = "Show Health Bars",
    CurrentValue = true,
    Flag        = "MobShowHealth",
    Callback    = function(value) ESP_CONFIG.ShowHealth = value end,
})

ESPTab:CreateToggle({
    Name        = "Show Distance",
    CurrentValue = true,
    Flag        = "MobShowDistance",
    Callback    = function(value)
        ESP_CONFIG.ShowDistance = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateSlider({
    Name        = "Max Distance (0 = ∞)",
    Range       = {0, 2000},
    Increment   = 1,
    Suffix      = " studs",
    CurrentValue = 0,
    Flag        = "MobESPDist",
    Callback    = function(value)
        ESP_CONFIG.MaxDistance = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateToggle({
    Name        = "Filter by Mob ID",
    CurrentValue = false,
    Flag        = "MobFilterID",
    Callback    = function(value)
        ESP_CONFIG.FilterByID = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateInput({
    Name        = "Mob Folder Name",
    CurrentValue = "Monster",
    PlaceholderText = "e.g. Mobs, Enemies, NPCs",
    RemoveTextAfterFocusLost = false,
    Flag        = "MobFolder",
    Callback    = function(value)
        if value and value ~= "" then
            ESP_CONFIG.MobFolder = value
            if MobESPEnabled then stopMobESP(); startMobESP() end
        end
    end,
})

local PlayerESPSection = ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name        = "Enable Player ESP",
    CurrentValue = false,
    Flag        = "PlayerESP",
    Callback    = function(value)
        PlayerESPEnabled = value
        if value then startPlayerESP() else stopPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name        = "Show Names",
    CurrentValue = true,
    Flag        = "PlayerShowNames",
    Callback    = function(value)
        PlayerESP_CONFIG.ShowName = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name        = "Show Distance",
    CurrentValue = true,
    Flag        = "PlayerShowDist",
    Callback    = function(value)
        PlayerESP_CONFIG.ShowDistance = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name        = "Show Health Bar",
    CurrentValue = true,
    Flag        = "PlayerShowHealth",
    Callback    = function(value)
        PlayerESP_CONFIG.ShowHealth = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateSlider({
    Name        = "Max Distance (0 = ∞)",
    Range       = {0, 2000},
    Increment   = 1,
    Suffix      = " studs",
    CurrentValue = 0,
    Flag        = "PlayerESPDist",
    Callback    = function(value)
        PlayerESP_CONFIG.MaxDistance = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

-- ===== TELEPORT TAB =====
local TPTab = Window:CreateTab("🌀 Teleport", nil)
local TPSection = TPTab:CreateSection("Chest Teleport")

TPTab:CreateLabel("Teleports you to chests and opens them.")

for _, entry in ipairs(NPC_LIST) do
    local capturedId = entry.id
    TPTab:CreateButton({
        Name     = entry.label,
        Callback = function() tpToNPC(capturedId) end,
    })
end

-- ===== MISC TAB =====
local MiscTab = Window:CreateTab("🔧 Misc", nil)

local VisualSection = MiscTab:CreateSection("Visual Tweaks")

MiscTab:CreateToggle({
    Name        = "No Fog",
    CurrentValue = false,
    Flag        = "NoFog",
    Callback    = function(value)
        NoFogEnabled = value
        if value then applyNoFog() else removeNoFog() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Shadows",
    CurrentValue = false,
    Flag        = "NoShadows",
    Callback    = function(value)
        if value then removeShadows() else restoreShadows() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Grass / Decorations",
    CurrentValue = false,
    Flag        = "NoGrass",
    Callback    = function(value)
        if value then removeGrass() else restoreGrass() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Textures",
    CurrentValue = false,
    Flag        = "NoTextures",
    Callback    = function(value)
        if value then removeTextures() else restoreTextures() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Post-Processing FX",
    CurrentValue = false,
    Flag        = "NoPostFX",
    Callback    = function(value)
        if value then removePostFX() else restorePostFX() end
    end,
})

MiscTab:CreateLabel("Tip: combine No Shadows + No Grass for a big FPS boost.")

local LightingSection = MiscTab:CreateSection("Lighting")

MiscTab:CreateToggle({
    Name        = "Full Bright",
    CurrentValue = false,
    Flag        = "FullBright",
    Callback    = function(value)
        FullBrightEnabled = value
        if value then applyFullBright() else removeFullBright() end
    end,
})

MiscTab:CreateSlider({
    Name        = "Time of Day",
    Range       = {0, 24},
    Increment   = 0.1,
    Suffix      = ":00",
    CurrentValue = 14,
    Flag        = "TimeOfDay",
    Callback    = function(value) lockTime(value) end,
})

MiscTab:CreateButton({
    Name     = "Unlock Time",
    Callback = function() unlockTime() end,
})

MiscTab:CreateLabel("0 = midnight, 12 = noon, 18 = dusk.")

-- ===== GP GIVER TAB =====
local GPTab = Window:CreateTab("🎁 GP Giver", nil)
local GPSection = GPTab:CreateSection("GP Giver")

local GP_TargetName = LocalPlayer.Name

GPTab:CreateInput({
    Name        = "Target Username",
    CurrentValue = LocalPlayer.Name,
    PlaceholderText = "Roblox username",
    RemoveTextAfterFocusLost = false,
    Flag        = "GPTarget",
    Callback    = function(value) GP_TargetName = value end,
})

local GP_LIST = {
    { name = "Cauldron 1",     key = "Cauldron_1"    },
    { name = "Fast Alchemy",   key = "FastAlchemy"   },
    { name = "Better Alchemy", key = "BetterAlchemy" },
    { name = "Sell Anywhere",  key = "SellAnywhere"  },
    { name = "Double Storage", key = "DoubleStorage" },
}

for _, gp in ipairs(GP_LIST) do
    local g = gp
    GPTab:CreateButton({
        Name     = g.name,
        Callback = function()
            pcall(function() Players[GP_TargetName].GamePass[g.key].Value = 1 end)
        end,
    })
end

-- ===== SETTINGS TAB =====
local SettingsTab = Window:CreateTab("⚙️ Settings", nil)
local UtilSection = SettingsTab:CreateSection("Utilities")

SettingsTab:CreateButton({
    Name     = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

SettingsTab:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        local hum = getHumanoid(); if hum then hum.Health = 0 end
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy UserId",
    Callback = function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy Game ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
    end,
})

SettingsTab:CreateButton({
    Name     = "Stop All Features",
    Callback = function() stopAllFeatures() end,
})

SettingsTab:CreateLabel('"Stop All" resets every active feature.')

Rayfield:LoadConfiguration()
Rayfield:Notify({ Title = "Junior Hub", Content = "Loaded successfully!", Duration = 3 })
