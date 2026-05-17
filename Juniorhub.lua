-- Junior Hub | Rayfield UI
-- Auto Clicker + Flight + Mob ESP + Player ESP + Auto Accept All Quests
-- Place in StarterPlayerScripts as a LocalScript

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")

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
--             AUTO CLICKER
-- ========================================

local AutoClickEnabled = false
local ClickDelay       = 1 / 20
local lastClick        = 0

RunService.Heartbeat:Connect(function()
    if not AutoClickEnabled then return end
    local now = tick()
    if now - lastClick >= ClickDelay then
        lastClick = now
        mouse1click()
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
            savedAtmosphere = {
                Density = obj.Density,
                Offset  = obj.Offset,
                Haze    = obj.Haze,
                Glare   = obj.Glare,
            }
            obj.Density = 0
            obj.Offset  = 0
            obj.Haze    = 0
            obj.Glare   = 0
        end
    end

    FogConn = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if NoFogEnabled then Lighting.FogEnd = 100000 end
    end)
    FogDescConn = Lighting.DescendantAdded:Connect(function(obj)
        if NoFogEnabled and obj:IsA("Atmosphere") then
            obj.Density = 0
            obj.Offset  = 0
            obj.Haze    = 0
            obj.Glare   = 0
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
            obj.Density = savedAtmosphere.Density
            obj.Offset  = savedAtmosphere.Offset
            obj.Haze    = savedAtmosphere.Haze
            obj.Glare   = savedAtmosphere.Glare
        end
    end
    savedAtmosphere = {}
end

-- ========================================
--         REMOVE TEXTURES / VISUALS
-- ========================================

local savedShadows       = nil
local savedGrassLength   = nil
local savedDecorations   = nil

local function removeShadows()
    local Lighting = game:GetService("Lighting")
    savedShadows = Lighting.GlobalShadows
    Lighting.GlobalShadows = false
end
local function restoreShadows()
    local Lighting = game:GetService("Lighting")
    if savedShadows ~= nil then Lighting.GlobalShadows = savedShadows end
end

local function removeGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        savedGrassLength   = terrain.GrassLength
        savedDecorations   = terrain.Decoration
        terrain.GrassLength  = 0
        terrain.Decoration   = false
    end
end
local function restoreGrass()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if savedGrassLength ~= nil then terrain.GrassLength = savedGrassLength end
        if savedDecorations ~= nil then terrain.Decoration  = savedDecorations end
    end
end

local savedMaterials  = {}
local savedTextures   = {}

local function removeTextures()
    savedMaterials = {}
    savedTextures  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            savedMaterials[obj] = obj.Material
            obj.Material = Enum.Material.SmoothPlastic
        end
        if obj:IsA("Texture") or obj:IsA("Decal") then
            savedTextures[obj] = obj.Transparency
            obj.Transparency = 1
        end
    end
end
local function restoreTextures()
    for obj, mat in pairs(savedMaterials) do
        if obj and obj.Parent then obj.Material = mat end
    end
    for obj, trans in pairs(savedTextures) do
        if obj and obj.Parent then obj.Transparency = trans end
    end
    savedMaterials = {}
    savedTextures  = {}
end

local savedEffects = {}
local function removePostFX()
    savedEffects = {}
    local Lighting = game:GetService("Lighting")
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") then
            savedEffects[obj] = obj.Enabled
            obj.Enabled = false
        end
    end
end
local function restorePostFX()
    for obj, state in pairs(savedEffects) do
        if obj and obj.Parent then obj.Enabled = state end
    end
    savedEffects = {}
end

-- ========================================
--           FULL BRIGHT
-- ========================================

local FullBrightEnabled    = false
local FB_savedAmbient      = nil
local FB_savedOutdoor      = nil
local FB_savedBrightness   = nil
local FB_savedColorShift   = nil
local FB_Conn              = nil

local function applyFullBright()
    local L = game:GetService("Lighting")
    FB_savedAmbient    = L.Ambient
    FB_savedOutdoor    = L.OutdoorAmbient
    FB_savedBrightness = L.Brightness
    FB_savedColorShift = L.ColorShift_Bottom
    L.Ambient          = Color3.new(1, 1, 1)
    L.OutdoorAmbient   = Color3.new(1, 1, 1)
    L.Brightness       = 2
    L.ColorShift_Bottom = Color3.new(0, 0, 0)
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

local function setTimeOfDay(hour)
    local L = game:GetService("Lighting")
    L.ClockTime = hour
end

local function lockTime(hour)
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
    local L = game:GetService("Lighting")
    L.ClockTime = hour
    ClockConn = RunService.Heartbeat:Connect(function()
        L.ClockTime = hour
    end)
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
    local qKey  = string.char(229, 143, 145, 230, 148, 190, 228, 187, 187, 229, 138, 161)
    local qBase = string.char(228, 187, 187, 229, 138, 161)
    local qArg1 = string.char(232, 167, 166, 229, 143, 145, 232, 129, 138, 229, 164, 169)
    local qArg2 = string.char(229, 147, 136, 229, 136, 169, 229, 155, 160, 231, 137, 185)

    -- Step 1 & 2: Accept Dwarf King quest
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(qArg1, {qArg2, "10010100"})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(qArg1, {qArg2, 10010501})
    end)
    task.wait(0.4)
    -- Step 3: Talk to NPC (quest 6)
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "6"})
    end)
    task.wait(0.4)
    -- Step 4: Confirm task
    pcall(function()
        RS.Msg.RemoteFunction.Setting:InvokeServer("TASK", 1)
    end)
    task.wait(0.4)
    -- Step 5: Quest 4
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "4"})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteFunction.Setting:InvokeServer("TASK", 1)
    end)
    task.wait(0.4)
    -- Step 6: Quest 3
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "3"})
    end)
    task.wait(0.4)
    -- Step 7: Quest 2
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(qKey, {qBase .. "2"})
    end)
end

local function startAutoQuest()
    AutoQuestThread = task.spawn(function()
        while AutoQuestEnabled do
            runQuestSequence()
            task.wait(2)
        end
    end)
end

local function stopAutoQuest()
    AutoQuestEnabled = false
    if AutoQuestThread then
        task.cancel(AutoQuestThread)
        AutoQuestThread = nil
    end
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
        RS.Msg.RemoteFunction.RemoteFunction:InvokeServer(str4, {["onlyIDList"] = {1137, 1140, 1139, 1138}})
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(str5)
    end)
end

local function startAutoSell()
    AutoSellThread = task.spawn(function()
        while AutoSellEnabled do
            runSellSequence()
            task.wait(2)
        end
    end)
end

local function stopAutoSell()
    AutoSellEnabled = false
    if AutoSellThread then
        task.cancel(AutoSellThread)
        AutoSellThread = nil
    end
end

-- ========================================
--               MOB ESP CONFIG
-- (moved above autofarm so it's available)
-- ========================================

local ESP_CONFIG = {
    MobFolder    = "Monster",
    MobTag       = "",
    NameColor    = Color3.fromRGB(255, 100, 100),
    HealthColor  = Color3.fromRGB(50, 255, 100),
    ShowName     = true,
    ShowHealth   = true,
    ShowDistance = true,
    MaxDistance  = 0,
    IDPrefixes   = {"11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30"},
    FilterByID   = false,
}

-- ========================================
--             MOB AUTOFARM
-- (fixed: uses ESP_CONFIG, GetChildren first
--  then falls back to GetDescendants, better
--  Y offset, radius actually filters mobs)
-- ========================================

local AutoFarmEnabled = false
local AutoFarmThread  = nil
local AutoFarmRadius  = 50

local function getNearestMob()
    local root = getRoot()
    if not root then return nil end

    local nearest, nearestDist = nil, math.huge

    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if not folder then return nil end

    -- Try direct children first, fall back to all descendants
    local candidates = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            table.insert(candidates, obj)
        end
    end
    if #candidates == 0 then
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") then
                table.insert(candidates, obj)
            end
        end
    end

    for _, obj in ipairs(candidates) do
        local hum     = obj:FindFirstChildOfClass("Humanoid")
        local mobRoot = obj:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and mobRoot then
            local dist = (mobRoot.Position - root.Position).Magnitude
            -- Only consider mobs within the farm radius
            if dist < nearestDist and dist <= AutoFarmRadius then
                nearest     = mobRoot
                nearestDist = dist
            end
        end
    end

    return nearest, nearestDist
end

local FARM_HOVER_HEIGHT = 10   -- studs above the mob to hover
local FARM_SNAP_DIST    = 8   -- studs — teleport threshold when far away

local function startAutoFarm()
    AutoFarmThread = task.spawn(function()
        while AutoFarmEnabled do
            local root             = getRoot()
            local mobRoot, mobDist = getNearestMob()
            if root and mobRoot then
                local targetPos = mobRoot.Position + Vector3.new(0, FARM_HOVER_HEIGHT, 0)

                if mobDist > FARM_SNAP_DIST then
                    -- Far away: hard teleport
                    root.CFrame = CFrame.new(targetPos)
                    root.AssemblyLinearVelocity = Vector3.zero
                else
                    -- Already on the mob: continuously push toward hover position
                    -- This fights gravity so you stay floating above it
                    local diff = targetPos - root.Position
                    root.AssemblyLinearVelocity = diff * 10
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopAutoFarm()
    AutoFarmEnabled = false
    if AutoFarmThread then
        task.cancel(AutoFarmThread)
        AutoFarmThread = nil
    end
end

-- ========================================
--               FLIGHT
-- ========================================

local FlyEnabled = false
local FlySpeed   = 60
local FlyConn    = nil
local FlyVel     = nil
local FlyAlign   = nil
local FlyAtt0    = nil
local FlyAtt1    = nil

local function startFly()
    local root = getRoot()
    local hum  = getHumanoid()
    if not root or not hum then return end

    hum.PlatformStand = true

    FlyAtt0        = Instance.new("Attachment")
    FlyAtt0.Parent = root
    FlyAtt1        = Instance.new("Attachment")
    FlyAtt1.Parent = workspace.Terrain

    FlyVel                        = Instance.new("LinearVelocity")
    FlyVel.Attachment0            = FlyAtt0
    FlyVel.MaxForce               = math.huge
    FlyVel.RelativeTo             = Enum.ActuatorRelativeTo.World
    FlyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FlyVel.VectorVelocity         = Vector3.zero
    FlyVel.Parent                 = root

    FlyAlign                    = Instance.new("AlignOrientation")
    FlyAlign.Attachment0        = FlyAtt0
    FlyAlign.Attachment1        = FlyAtt1
    FlyAlign.MaxTorque          = math.huge
    FlyAlign.MaxAngularVelocity = math.huge
    FlyAlign.Responsiveness     = 200
    FlyAlign.RigidityEnabled    = true
    FlyAlign.Parent             = root

    FlyConn = RunService.Heartbeat:Connect(function()
        local r = getRoot()
        if not r then return end

        local dir = Vector3.zero
        local cf  = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis  end

        FlyVel.VectorVelocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * FlySpeed

        local lookDir = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if lookDir.Magnitude > 0 then
            FlyAtt1.CFrame = CFrame.new(Vector3.zero, lookDir)
        end
    end)
end

local function stopFly()
    if FlyConn  then FlyConn:Disconnect();  FlyConn  = nil end
    if FlyVel   then FlyVel:Destroy();      FlyVel   = nil end
    if FlyAlign then FlyAlign:Destroy();    FlyAlign = nil end
    if FlyAtt0  then FlyAtt0:Destroy();     FlyAtt0  = nil end
    if FlyAtt1  then FlyAtt1:Destroy();     FlyAtt1  = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function setFly(state)
    FlyEnabled = state
    if state then startFly() else stopFly() end
end

LocalPlayer.CharacterAdded:Connect(function()
    setFly(false)
    task.wait(0.1)
    if Options and Options.FlyToggle then
        Options.FlyToggle:SetValue(false)
    end
end)

-- ========================================
--               MOB ESP
-- ========================================

local MobESPEnabled = false
local MobESPFolder  = nil

local function mobMatchesIDFilter(obj)
    if not ESP_CONFIG.FilterByID then return true end
    local name = obj.Name
    for _, prefix in ipairs(ESP_CONFIG.IDPrefixes) do
        if name:sub(1, #prefix) == prefix and tonumber(name) then
            return true
        end
    end
    return false
end

local function getMobs()
    local mobs   = {}
    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        -- Check direct children first
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and mobMatchesIDFilter(obj) then
                table.insert(mobs, obj)
            end
        end
        -- If nothing found as direct children, check descendants
        if #mobs == 0 then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and mobMatchesIDFilter(obj) then
                    table.insert(mobs, obj)
                end
            end
        end
    end
    if ESP_CONFIG.MobTag ~= "" then
        for _, obj in ipairs(game:GetService("CollectionService"):GetTagged(ESP_CONFIG.MobTag)) do
            if obj:IsA("Model") then table.insert(mobs, obj) end
        end
    end
    return mobs
end

local MobESPUpdateConn = nil

local function makeMobGui(mob)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildOfClass("BasePart")
    if not root then return end

    local bb = Instance.new("BillboardGui")
    bb.Name        = "MobESP_" .. mob.Name
    bb.Adornee     = root
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0, 160, 0, 70)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.MaxDistance = ESP_CONFIG.MaxDistance > 0 and ESP_CONFIG.MaxDistance or math.huge
    bb.Parent      = MobESPFolder

    if ESP_CONFIG.ShowHealth then
        local hum = mob:FindFirstChildOfClass("Humanoid")

        local hpBg = Instance.new("Frame")
        hpBg.Name             = "HPBg"
        hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        hpBg.BorderSizePixel  = 0
        hpBg.Size             = UDim2.new(0, 7, 1, 0)
        hpBg.Position         = UDim2.new(0, 0, 0, 0)
        hpBg.Parent           = bb

        local stroke = Instance.new("UIStroke")
        stroke.Color     = Color3.fromRGB(200, 200, 200)
        stroke.Thickness = 0.8
        stroke.Parent    = hpBg

        local fill = Instance.new("Frame")
        fill.Name             = "HPFill"
        fill.AnchorPoint      = Vector2.new(0, 1)
        fill.BorderSizePixel  = 0
        fill.BackgroundColor3 = Color3.fromRGB(0, 210, 60)
        fill.Size             = UDim2.new(1, 0, 1, 0)
        fill.Position         = UDim2.new(0, 0, 1, 0)
        fill.Parent           = hpBg

        if hum then
            local function updateHP()
                local pct = hum.Health / math.max(hum.MaxHealth, 1)
                fill.Size             = UDim2.new(1, 0, pct, 0)
                fill.BackgroundColor3 = Color3.fromRGB(
                    math.floor(255 * (1 - pct)),
                    math.floor(210 * pct),
                    20
                )
            end
            updateHP()
            hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
        end
    end

    local cx  = 11
    local yPx = 0

    if ESP_CONFIG.ShowName then
        local lbl = Instance.new("TextLabel")
        lbl.Name                   = "NameLbl"
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, -cx, 0, 24)
        lbl.Position               = UDim2.new(0, cx, 0, yPx)
        lbl.Text                   = mob.Name
        lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0.65
        lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        lbl.TextScaled             = true
        lbl.Font                   = Enum.Font.FredokaOne
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = bb
        yPx += 24
    end

    if ESP_CONFIG.ShowDistance then
        local lbl = Instance.new("TextLabel")
        lbl.Name                   = "DistLbl"
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, -cx, 0, 18)
        lbl.Position               = UDim2.new(0, cx, 0, yPx)
        lbl.Text                   = "0 studs"
        lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0.65
        lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        lbl.TextScaled             = true
        lbl.Font                   = Enum.Font.GothamMedium
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = bb
        yPx += 18
    end

    if ESP_CONFIG.ShowHealth then
        local hum   = mob:FindFirstChildOfClass("Humanoid")
        local hpLbl = Instance.new("TextLabel")
        hpLbl.Name                   = "HPLbl"
        hpLbl.BackgroundTransparency = 1
        hpLbl.Size                   = UDim2.new(1, -cx, 0, 16)
        hpLbl.Position               = UDim2.new(0, cx, 0, yPx)
        hpLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        hpLbl.TextStrokeTransparency = 0.65
        hpLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        hpLbl.TextScaled             = true
        hpLbl.Font                   = Enum.Font.GothamMedium
        hpLbl.TextXAlignment         = Enum.TextXAlignment.Left
        hpLbl.Parent                 = bb
        if hum then
            local function updateHPLbl()
                hpLbl.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            end
            updateHPLbl()
            hum:GetPropertyChangedSignal("Health"):Connect(updateHPLbl)
        end
    end
end

local function startMobESP()
    MobESPFolder        = Instance.new("Folder")
    MobESPFolder.Name   = "MobESPHolder"
    MobESPFolder.Parent = LocalPlayer.PlayerGui
    for _, mob in ipairs(getMobs()) do makeMobGui(mob) end

    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        folder.DescendantAdded:Connect(function(obj)
            if not MobESPEnabled then return end
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                task.wait()
                makeMobGui(obj)
            end
        end)
    end

    MobESPUpdateConn = RunService.Heartbeat:Connect(function()
        if not MobESPEnabled or not ESP_CONFIG.ShowDistance then return end
        local myRoot = getRoot()
        if not myRoot then return end
        if not MobESPFolder then return end
        for _, bb in ipairs(MobESPFolder:GetChildren()) do
            local lbl      = bb:FindFirstChild("DistLbl")
            local adornee  = bb.Adornee
            if lbl and adornee then
                local dist = math.floor((adornee.Position - myRoot.Position).Magnitude)
                lbl.Text = dist .. " studs"
            end
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
    ShowName     = true,
    ShowHealth   = true,
    ShowTeam     = true,
    ShowDistance = true,
    MaxDistance  = 0,
    NameColor    = Color3.fromRGB(255, 255, 255),
    DistColor    = Color3.fromRGB(255, 220, 50),
}

local PlayerESPEnabled    = false
local PlayerESPFolder     = nil
local PlayerESPConns      = {}
local PlayerESPUpdateConn = nil

local function makePlayerGui(player)
    if player == LocalPlayer then return end

    local function build()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local old = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
        if old then old:Destroy() end

        local bb = Instance.new("BillboardGui")
        bb.Name        = "ESP_" .. player.Name
        bb.Adornee     = root
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 170, 0, 70)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.MaxDistance = PlayerESP_CONFIG.MaxDistance > 0 and PlayerESP_CONFIG.MaxDistance or math.huge
        bb.Parent      = PlayerESPFolder

        if PlayerESP_CONFIG.ShowHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")

            local hpBg = Instance.new("Frame")
            hpBg.Name             = "HPBg"
            hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            hpBg.BorderSizePixel  = 0
            hpBg.Size             = UDim2.new(0, 7, 1, 0)
            hpBg.Position         = UDim2.new(0, 0, 0, 0)
            hpBg.Parent           = bb

            local stroke = Instance.new("UIStroke")
            stroke.Color     = Color3.fromRGB(255, 255, 255)
            stroke.Thickness  = 0.8
            stroke.Parent    = hpBg

            local fill = Instance.new("Frame")
            fill.Name             = "HPFill"
            fill.AnchorPoint      = Vector2.new(0, 1)
            fill.BorderSizePixel  = 0
            fill.BackgroundColor3 = Color3.fromRGB(0, 210, 60)
            fill.Size             = UDim2.new(1, 0, 1, 0)
            fill.Position         = UDim2.new(0, 0, 1, 0)
            fill.Parent           = hpBg

            if hum then
                local function updateHP()
                    local pct = hum.Health / math.max(hum.MaxHealth, 1)
                    fill.Size             = UDim2.new(1, 0, pct, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - pct)),
                        math.floor(210 * pct),
                        20
                    )
                end
                updateHP()
                hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
            end
        end

        local cx  = 14
        local yPx = 0

        if PlayerESP_CONFIG.ShowName then
            local lbl = Instance.new("TextLabel")
            lbl.Name                   = "NameLbl"
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -cx, 0, 26)
            lbl.Position               = UDim2.new(0, cx, 0, yPx)
            lbl.Text                   = player.Name
            lbl.TextColor3             = PlayerESP_CONFIG.NameColor
            lbl.TextStrokeTransparency = 0.3
            lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
            lbl.TextScaled             = true
            lbl.Font                   = Enum.Font.FredokaOne
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = bb
            yPx += 26
        end

        if PlayerESP_CONFIG.ShowDistance then
            local lbl = Instance.new("TextLabel")
            lbl.Name                   = "DistLbl"
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -cx, 0, 20)
            lbl.Position               = UDim2.new(0, cx, 0, yPx)
            lbl.Text                   = "0 studs"
            lbl.TextColor3             = PlayerESP_CONFIG.DistColor
            lbl.TextStrokeTransparency = 0.4
            lbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
            lbl.TextScaled             = true
            lbl.Font                   = Enum.Font.GothamMedium
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = bb
            yPx += 20
        end

        if PlayerESP_CONFIG.ShowTeam and player.Team then
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -cx, 0, 18)
            lbl.Position               = UDim2.new(0, cx, 0, yPx)
            lbl.Text                   = "[" .. player.Team.Name .. "]"
            lbl.TextColor3             = player.Team.TeamColor.Color
            lbl.TextStrokeTransparency = 0.5
            lbl.TextScaled             = true
            lbl.Font                   = Enum.Font.GothamMedium
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = bb
        end
    end

    build()

    local conn = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        build()
    end)
    table.insert(PlayerESPConns, conn)
end

local function startPlayerESP()
    PlayerESPFolder        = Instance.new("Folder")
    PlayerESPFolder.Name   = "PlayerESPHolder"
    PlayerESPFolder.Parent = LocalPlayer.PlayerGui

    for _, player in ipairs(Players:GetPlayers()) do
        makePlayerGui(player)
    end

    local addedConn = Players.PlayerAdded:Connect(function(player)
        if not PlayerESPEnabled then return end
        task.wait(1)
        makePlayerGui(player)
    end)
    table.insert(PlayerESPConns, addedConn)

    local removedConn = Players.PlayerRemoving:Connect(function(player)
        local gui = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
        if gui then gui:Destroy() end
    end)
    table.insert(PlayerESPConns, removedConn)

    PlayerESPUpdateConn = RunService.Heartbeat:Connect(function()
        if not PlayerESPEnabled or not PlayerESP_CONFIG.ShowDistance then return end
        local myRoot = getRoot()
        if not myRoot then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local gui = PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_" .. player.Name)
            local lbl = gui and gui:FindFirstChild("DistLbl")
            if lbl then
                lbl.Text = math.floor((root.Position - myRoot.Position).Magnitude) .. " studs"
            end
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
--              RAYFIELD UI
-- ========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = "Junior Hub",
    LoadingTitle     = "Junior Hub",
    LoadingSubtitle  = "by Junior",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "JuniorHub",
        FileName = "Config",
    },
    KeySystem = false,
})

-- ===== COMBAT TAB =====

local CombatTab = Window:CreateTab("Combat", 4483362458)

local ClickSection = CombatTab:CreateSection("Auto Clicker")

CombatTab:CreateToggle({
    Name       = "Enable Auto Clicker",
    CurrentValue = false,
    Flag       = "AutoClickToggle",
    Callback   = function(value)
        AutoClickEnabled = value
    end,
})

CombatTab:CreateSlider({
    Name     = "Clicks Per Second",
    Range    = {1, 50},
    Increment = 1,
    Suffix   = "CPS",
    CurrentValue = 20,
    Flag     = "CPSSlider",
    Callback = function(value)
        ClickDelay = 1 / value
    end,
})

local FarmSection = CombatTab:CreateSection("Mob Auto Farm")

CombatTab:CreateToggle({
    Name       = "Enable Auto Farm",
    CurrentValue = false,
    Flag       = "AutoFarmToggle",
    Callback   = function(value)
        AutoFarmEnabled = value
        if value then startAutoFarm() else stopAutoFarm() end
    end,
})

CombatTab:CreateSlider({
    Name     = "Farm Radius",
    Range    = {10, 500},
    Increment = 1,
    Suffix   = "studs",
    CurrentValue = 50,
    Flag     = "FarmRadiusSlider",
    Callback = function(value)
        AutoFarmRadius = value
    end,
})

CombatTab:CreateSlider({
    Name     = "Hover Height",
    Range    = {10, 50},
    Increment = 1,
    Suffix   = "studs",
    CurrentValue = 10,
    Flag     = "FarmHoverSlider",
    Callback = function(value)
        FARM_HOVER_HEIGHT = value
    end,
})

CombatTab:CreateLabel("Enable Auto Clicker too for damage!")

local QuestSection = CombatTab:CreateSection("Auto Accept All Quests")

CombatTab:CreateToggle({
    Name       = "Enable Auto Accept All Quests",
    CurrentValue = false,
    Flag       = "AutoQuestToggle",
    Callback   = function(value)
        AutoQuestEnabled = value
        if value then startAutoQuest() else stopAutoQuest() end
    end,
})

CombatTab:CreateButton({
    Name     = "Take Quest Once",
    Callback = function()
        task.spawn(runQuestSequence)
        Rayfield:Notify({Title = "Junior Hub", Content = "Quest sequence fired!", Duration = 2})
    end,
})

CombatTab:CreateLabel("Loop re-takes every 2s.")

local SellSection = CombatTab:CreateSection("Auto Sell")

CombatTab:CreateToggle({
    Name       = "Enable Auto Sell",
    CurrentValue = false,
    Flag       = "AutoSellToggle",
    Callback   = function(value)
        AutoSellEnabled = value
        if value then startAutoSell() else stopAutoSell() end
    end,
})

CombatTab:CreateButton({
    Name     = "Sell Once",
    Callback = function()
        task.spawn(runSellSequence)
        Rayfield:Notify({Title = "Junior Hub", Content = "Sell sequence fired!", Duration = 2})
    end,
})

CombatTab:CreateLabel("Only sells trash / useless items.")
CombatTab:CreateLabel("Loop sells every 2s.")

-- ===== FLYING TAB =====

local FlyTab = Window:CreateTab("Flying", 4483362458)

local FlySection = FlyTab:CreateSection("Flight")

FlyTab:CreateToggle({
    Name       = "Enable Flight",
    CurrentValue = false,
    Flag       = "FlyToggle",
    Callback   = function(value)
        setFly(value)
    end,
})

FlyTab:CreateSlider({
    Name     = "Flight Speed",
    Range    = {10, 500},
    Increment = 1,
    Suffix   = "studs/s",
    CurrentValue = 60,
    Flag     = "FlySpeedSlider",
    Callback = function(value)
        FlySpeed = value
    end,
})

-- ===== ESP TAB =====

local ESPTab = Window:CreateTab("ESP", 4483362458)

local MobESPSection = ESPTab:CreateSection("Mob ESP")

ESPTab:CreateToggle({
    Name       = "Enable Mob ESP",
    CurrentValue = false,
    Flag       = "MobESPToggle",
    Callback   = function(value)
        MobESPEnabled = value
        if value then startMobESP() else stopMobESP() end
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Names",
    CurrentValue = true,
    Flag       = "MobShowNames",
    Callback   = function(value)
        ESP_CONFIG.ShowName = value
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Health Bars",
    CurrentValue = true,
    Flag       = "MobShowHealth",
    Callback   = function(value)
        ESP_CONFIG.ShowHealth = value
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Distance",
    CurrentValue = true,
    Flag       = "MobShowDistance",
    Callback   = function(value)
        ESP_CONFIG.ShowDistance = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateSlider({
    Name     = "Max Distance (0 = infinite)",
    Range    = {0, 2000},
    Increment = 1,
    Suffix   = "studs",
    CurrentValue = 0,
    Flag     = "MobESPDistance",
    Callback = function(value)
        ESP_CONFIG.MaxDistance = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateToggle({
    Name       = "Filter by Mob ID",
    CurrentValue = false,
    Flag       = "MobFilterByID",
    Callback   = function(value)
        ESP_CONFIG.FilterByID = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateInput({
    Name        = "Mob Folder Name",
    CurrentValue = "Monster",
    PlaceholderText = "e.g. Mobs, Enemies, NPCs",
    RemoveTextAfterFocusLost = false,
    Flag        = "MobFolderInput",
    Callback    = function(value)
        ESP_CONFIG.MobFolder = value
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

local PlayerESPSection = ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name       = "Enable Player ESP",
    CurrentValue = false,
    Flag       = "PlayerESPToggle",
    Callback   = function(value)
        PlayerESPEnabled = value
        if value then startPlayerESP() else stopPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Names",
    CurrentValue = true,
    Flag       = "PlayerShowNames",
    Callback   = function(value)
        PlayerESP_CONFIG.ShowName = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Distance",
    CurrentValue = true,
    Flag       = "PlayerShowDistance",
    Callback   = function(value)
        PlayerESP_CONFIG.ShowDistance = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name       = "Show Health Bar",
    CurrentValue = true,
    Flag       = "PlayerShowHealth",
    Callback   = function(value)
        PlayerESP_CONFIG.ShowHealth = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateSlider({
    Name     = "Max Distance (0 = infinite)",
    Range    = {0, 2000},
    Increment = 1,
    Suffix   = "studs",
    CurrentValue = 0,
    Flag     = "PlayerESPDistance",
    Callback = function(value)
        PlayerESP_CONFIG.MaxDistance = value
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

-- ===== TELEPORT TAB =====

local TPTab = Window:CreateTab("Teleport", 4483362458)

local TPSection = TPTab:CreateSection("Chest Teleport")

TPTab:CreateLabel("Teleports you to chests in the world.")
TPTab:CreateLabel("Searches all of workspace automatically.")

local NPC_LIST = {
    { label = "Chest TP", id = "101" },
    { label = "Chest 1",  id = "103" },
    { label = "Chest 2",  id = "104" },
    { label = "Chest 3",  id = "105" },
    { label = "Chest 4",  id = "106" },
    { label = "Chest 5",  id = "107" },
    { label = "Chest 6",  id = "108" },
    { label = "Chest 7",  id = "109" },
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
    if not root then
        Rayfield:Notify({Title = "Junior Hub", Content = "No character!", Duration = 2})
        return
    end
    local npc = findNPCAnywhere(npcId)
    if not npc then
        Rayfield:Notify({Title = "Junior Hub", Content = "Chest didn't respawn yet!", Duration = 2})
        return
    end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("BasePart") then npcRoot = v; break end
        end
    end
    if npcRoot then
        root.CFrame = npcRoot.CFrame + Vector3.new(0, 3, 0)
        Rayfield:Notify({Title = "Junior Hub", Content = "Teleported to chest!", Duration = 2})
    else
        Rayfield:Notify({Title = "Junior Hub", Content = "Chest didn't respawn yet!", Duration = 2})
    end
end

for _, entry in ipairs(NPC_LIST) do
    local capturedId = entry.id
    TPTab:CreateButton({
        Name     = entry.label,
        Callback = function()
            tpToNPC(capturedId)
        end,
    })
end

-- ===== MISC TAB =====

local MiscTab = Window:CreateTab("Misc", 4483362458)

local VisualSection = MiscTab:CreateSection("Visual Tweaks")

MiscTab:CreateToggle({
    Name       = "No Fog",
    CurrentValue = false,
    Flag       = "NoFogToggle",
    Callback   = function(value)
        NoFogEnabled = value
        if value then applyNoFog() else removeNoFog() end
    end,
})

MiscTab:CreateToggle({
    Name       = "No Shadows",
    CurrentValue = false,
    Flag       = "NoShadowsToggle",
    Callback   = function(value)
        if value then removeShadows() else restoreShadows() end
    end,
})

MiscTab:CreateToggle({
    Name       = "No Grass / Decorations",
    CurrentValue = false,
    Flag       = "NoGrassToggle",
    Callback   = function(value)
        if value then removeGrass() else restoreGrass() end
    end,
})

MiscTab:CreateToggle({
    Name       = "No Textures",
    CurrentValue = false,
    Flag       = "NoTexturesToggle",
    Callback   = function(value)
        if value then removeTextures() else restoreTextures() end
    end,
})

MiscTab:CreateToggle({
    Name       = "No Post-Processing FX",
    CurrentValue = false,
    Flag       = "NoPostFXToggle",
    Callback   = function(value)
        if value then removePostFX() else restorePostFX() end
    end,
})

MiscTab:CreateLabel("Tip: combine No Shadows + No Grass for a big FPS boost.")

local LightingSection = MiscTab:CreateSection("Lighting")

MiscTab:CreateToggle({
    Name       = "Full Bright",
    CurrentValue = false,
    Flag       = "FullBrightToggle",
    Callback   = function(value)
        FullBrightEnabled = value
        if value then applyFullBright() else removeFullBright() end
    end,
})

MiscTab:CreateSlider({
    Name     = "Time of Day",
    Range    = {0, 24},
    Increment = 0.1,
    Suffix   = ":00",
    CurrentValue = 14,
    Flag     = "TimeSlider",
    Callback = function(value)
        lockTime(value)
    end,
})

MiscTab:CreateButton({
    Name     = "Unlock Time",
    Callback = function()
        unlockTime()
        Rayfield:Notify({Title = "Junior Hub", Content = "Time unlocked.", Duration = 2})
    end,
})

MiscTab:CreateLabel("0 = midnight, 12 = noon, 18 = dusk.")

-- ===== GP GIVER TAB =====

local GPTab = Window:CreateTab("GP Giver", 4483362458)

local GPSection = GPTab:CreateSection("GP Giver")

local GP_TargetName = LocalPlayer.Name

GPTab:CreateInput({
    Name        = "Target Username",
    CurrentValue = LocalPlayer.Name,
    PlaceholderText = "Roblox username",
    RemoveTextAfterFocusLost = false,
    Flag        = "GPTargetInput",
    Callback    = function(value)
        GP_TargetName = value
    end,
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
            local ok, err = pcall(function()
                Players[GP_TargetName].GamePass[g.key].Value = 1
            end)
            if ok then
                Rayfield:Notify({Title = "Junior Hub", Content = g.name .. " set to 1!", Duration = 2})
            else
                Rayfield:Notify({Title = "Junior Hub", Content = "Failed: " .. tostring(err), Duration = 4})
            end
        end,
    })
end

-- ===== SETTINGS TAB =====

local SettingsTab = Window:CreateTab("Settings", 4483362458)

local PlayerSection = SettingsTab:CreateSection("Player")

SettingsTab:CreateSlider({
    Name     = "Walk Speed",
    Range    = {1, 300},
    Increment = 1,
    Suffix   = "stud/s",
    CurrentValue = 16,
    Flag     = "WalkSpeedSlider",
    Callback = function(value)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end,
})

SettingsTab:CreateSlider({
    Name     = "Jump Power",
    Range    = {0, 300},
    Increment = 1,
    Suffix   = "",
    CurrentValue = 50,
    Flag     = "JumpPowerSlider",
    Callback = function(value)
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower    = value
        end
    end,
})

SettingsTab:CreateToggle({
    Name       = "Infinite Jump",
    CurrentValue = false,
    Flag       = "InfiniteJumpToggle",
    Callback   = function(value)
        _G.DaxinInfJump = value
    end,
})

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
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy UserId",
    Callback = function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
        Rayfield:Notify({Title = "Junior Hub", Content = "UserId: " .. LocalPlayer.UserId, Duration = 3})
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy Game ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
        Rayfield:Notify({Title = "Junior Hub", Content = "Place ID: " .. game.PlaceId, Duration = 3})
    end,
})

SettingsTab:CreateButton({
    Name     = "Stop All Features",
    Callback = function()
        AutoClickEnabled  = false
        NoFogEnabled      = false
        _G.DaxinInfJump   = false
        FullBrightEnabled = false
        MobESPEnabled     = false
        PlayerESPEnabled  = false
        stopAutoQuest()
        stopAutoFarm()
        stopAutoSell()
        setFly(false)
        stopMobESP()
        stopPlayerESP()
        removeNoFog()
        restoreShadows()
        restoreGrass()
        restoreTextures()
        restorePostFX()
        removeFullBright()
        unlockTime()
        Rayfield:Notify({Title = "Junior Hub", Content = "All features stopped.", Duration = 2})
    end,
})

SettingsTab:CreateLabel('"Stop All" resets everything.')

UserInputService.JumpRequest:Connect(function()
    if _G.DaxinInfJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Rayfield:Notify({Title = "Junior Hub", Content = "Loaded successfully!", Duration = 3})
