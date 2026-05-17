-- Junior Hub | Rayfield Edition
-- Auto Clicker + Flight + Mob ESP + Player ESP + Auto Dwarf King Quest + GP Giver + Misc
-- Mobile/Emulator compatible

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

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

local NoFogEnabled     = false
local FogConn          = nil
local FogDescConn      = nil
local originalFogEnd   = nil
local originalFogStart = nil
local savedAtmosphere  = {}

local function applyNoFog()
    local L = game:GetService("Lighting")
    originalFogEnd = L.FogEnd; originalFogStart = L.FogStart
    L.FogEnd = 100000; L.FogStart = 100000
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") then
            savedAtmosphere = {Density=obj.Density,Offset=obj.Offset,Haze=obj.Haze,Glare=obj.Glare}
            obj.Density=0; obj.Offset=0; obj.Haze=0; obj.Glare=0
        end
    end
    FogConn = L:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if NoFogEnabled then L.FogEnd = 100000 end
    end)
    FogDescConn = L.DescendantAdded:Connect(function(obj)
        if NoFogEnabled and obj:IsA("Atmosphere") then
            obj.Density=0; obj.Offset=0; obj.Haze=0; obj.Glare=0
        end
    end)
end

local function removeNoFog()
    if FogConn     then FogConn:Disconnect();     FogConn     = nil end
    if FogDescConn then FogDescConn:Disconnect(); FogDescConn = nil end
    local L = game:GetService("Lighting")
    if originalFogEnd   then L.FogEnd   = originalFogEnd   end
    if originalFogStart then L.FogStart = originalFogStart end
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") and savedAtmosphere.Density then
            obj.Density=savedAtmosphere.Density; obj.Offset=savedAtmosphere.Offset
            obj.Haze=savedAtmosphere.Haze;       obj.Glare=savedAtmosphere.Glare
        end
    end
    savedAtmosphere = {}
end

-- ========================================
--         REMOVE TEXTURES / VISUALS
-- ========================================

local savedShadows=nil; local savedGrassLength=nil; local savedDecorations=nil

local function removeShadows()
    local L=game:GetService("Lighting"); savedShadows=L.GlobalShadows; L.GlobalShadows=false
end
local function restoreShadows()
    local L=game:GetService("Lighting")
    if savedShadows~=nil then L.GlobalShadows=savedShadows end
end
local function removeGrass()
    local t=workspace:FindFirstChildOfClass("Terrain")
    if t then savedGrassLength=t.GrassLength; savedDecorations=t.Decoration; t.GrassLength=0; t.Decoration=false end
end
local function restoreGrass()
    local t=workspace:FindFirstChildOfClass("Terrain")
    if t then
        if savedGrassLength~=nil then t.GrassLength=savedGrassLength end
        if savedDecorations~=nil then t.Decoration=savedDecorations  end
    end
end

local savedMaterials={}; local savedTextures={}
local function removeTextures()
    savedMaterials={}; savedTextures={}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then savedMaterials[obj]=obj.Material; obj.Material=Enum.Material.SmoothPlastic end
        if obj:IsA("Texture") or obj:IsA("Decal") then savedTextures[obj]=obj.Transparency; obj.Transparency=1 end
    end
end
local function restoreTextures()
    for obj,mat  in pairs(savedMaterials) do if obj and obj.Parent then obj.Material=mat end end
    for obj,tr   in pairs(savedTextures)  do if obj and obj.Parent then obj.Transparency=tr end end
    savedMaterials={}; savedTextures={}
end

local savedEffects={}
local function removePostFX()
    savedEffects={}
    for _,obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("PostEffect") then savedEffects[obj]=obj.Enabled; obj.Enabled=false end
    end
end
local function restorePostFX()
    for obj,state in pairs(savedEffects) do if obj and obj.Parent then obj.Enabled=state end end
    savedEffects={}
end

-- ========================================
--           FULL BRIGHT
-- ========================================

local FullBrightEnabled=false
local FB_savedAmbient=nil; local FB_savedOutdoor=nil
local FB_savedBrightness=nil; local FB_savedColorShift=nil; local FB_Conn=nil

local function applyFullBright()
    local L=game:GetService("Lighting")
    FB_savedAmbient=L.Ambient; FB_savedOutdoor=L.OutdoorAmbient
    FB_savedBrightness=L.Brightness; FB_savedColorShift=L.ColorShift_Bottom
    L.Ambient=Color3.new(1,1,1); L.OutdoorAmbient=Color3.new(1,1,1)
    L.Brightness=2; L.ColorShift_Bottom=Color3.new(0,0,0)
    FB_Conn=L:GetPropertyChangedSignal("Brightness"):Connect(function()
        if FullBrightEnabled then L.Brightness=2 end
    end)
end
local function removeFullBright()
    if FB_Conn then FB_Conn:Disconnect(); FB_Conn=nil end
    local L=game:GetService("Lighting")
    if FB_savedAmbient    then L.Ambient=FB_savedAmbient end
    if FB_savedOutdoor    then L.OutdoorAmbient=FB_savedOutdoor end
    if FB_savedBrightness then L.Brightness=FB_savedBrightness end
    if FB_savedColorShift then L.ColorShift_Bottom=FB_savedColorShift end
end

-- ========================================
--         TIME OF DAY CONTROL
-- ========================================

local ClockConn=nil
local function lockTime(hour)
    if ClockConn then ClockConn:Disconnect(); ClockConn=nil end
    local L=game:GetService("Lighting"); L.ClockTime=hour
    ClockConn=RunService.Heartbeat:Connect(function() L.ClockTime=hour end)
end
local function unlockTime()
    if ClockConn then ClockConn:Disconnect(); ClockConn=nil end
end

-- ========================================
--           AUTO TAKE QUEST
-- ========================================

local AutoQuestEnabled = false
local AutoQuestThread  = nil

local function runQuestSequence()
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(
            "\232\167\166\229\143\145\232\129\138\229\164\169",
            {"\229\147\136\229\136\169\229\155\160\231\137\185", "10010100"}
        )
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteEvent.RemoteEvent:FireServer(
            "\232\167\166\229\143\145\232\129\138\229\164\169",
            {"\229\147\136\229\136\169\229\155\160\231\137\185", 10010501}
        )
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.Function.TalkFunc:InvokeServer(
            "\229\143\145\230\148\190\228\187\187\229\138\161",
            {"\228\187\187\229\138\161" .. "6"}
        )
    end)
    task.wait(0.4)
    pcall(function()
        RS.Msg.RemoteFunction.Setting:InvokeServer("TASK", 1)
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
    if AutoQuestThread then task.cancel(AutoQuestThread); AutoQuestThread = nil end
end

-- ========================================
--               FLIGHT
-- ========================================

local FlyEnabled=false; local FlySpeed=60
local FlyConn=nil; local FlyVel=nil; local FlyAlign=nil
local FlyAtt0=nil; local FlyAtt1=nil

local function getRoot()
    local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local c=LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

local function startFly()
    local root=getRoot(); local hum=getHumanoid()
    if not root or not hum then return end
    hum.PlatformStand=true
    FlyAtt0=Instance.new("Attachment"); FlyAtt0.Parent=root
    FlyAtt1=Instance.new("Attachment"); FlyAtt1.Parent=workspace.Terrain
    FlyVel=Instance.new("LinearVelocity")
    FlyVel.Attachment0=FlyAtt0; FlyVel.MaxForce=math.huge
    FlyVel.RelativeTo=Enum.ActuatorRelativeTo.World
    FlyVel.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
    FlyVel.VectorVelocity=Vector3.zero; FlyVel.Parent=root
    FlyAlign=Instance.new("AlignOrientation")
    FlyAlign.Attachment0=FlyAtt0; FlyAlign.Attachment1=FlyAtt1
    FlyAlign.MaxTorque=math.huge; FlyAlign.MaxAngularVelocity=math.huge
    FlyAlign.Responsiveness=200; FlyAlign.RigidityEnabled=true; FlyAlign.Parent=root
    FlyConn=RunService.Heartbeat:Connect(function()
        local r=getRoot(); if not r then return end
        local dir=Vector3.zero; local cf=Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir+=cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir-=cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir+=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir-=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir+=Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.yAxis  end
        FlyVel.VectorVelocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*FlySpeed
        local ld=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
        if ld.Magnitude>0 then FlyAtt1.CFrame=CFrame.new(Vector3.zero,ld) end
    end)
end

local function stopFly()
    if FlyConn  then FlyConn:Disconnect();  FlyConn=nil  end
    if FlyVel   then FlyVel:Destroy();      FlyVel=nil   end
    if FlyAlign then FlyAlign:Destroy();    FlyAlign=nil end
    if FlyAtt0  then FlyAtt0:Destroy();     FlyAtt0=nil  end
    if FlyAtt1  then FlyAtt1:Destroy();     FlyAtt1=nil  end
    local hum=getHumanoid(); if hum then hum.PlatformStand=false end
end

local function setFly(state)
    FlyEnabled=state; if state then startFly() else stopFly() end
end

LocalPlayer.CharacterAdded:Connect(function()
    setFly(false)
end)

-- ========================================
--               MOB ESP
-- ========================================

local ESP_CONFIG = {
    MobFolder   = "Monster",
    ShowName    = true,
    ShowHealth  = true,
    ShowDistance = true,
    MaxDistance = 0,
    FilterByID  = false,
    IDPrefixes  = {"12","14","15","19","20","21"},
}

local MobESPEnabled = false
local MobESPFolder  = nil
local MobESPUpdateConn = nil

local function mobMatchesIDFilter(obj)
    if not ESP_CONFIG.FilterByID then return true end
    local name = obj.Name
    for _, prefix in ipairs(ESP_CONFIG.IDPrefixes) do
        if name:sub(1,#prefix)==prefix and tonumber(name) then return true end
    end
    return false
end

local function getMobs()
    local mobs = {}
    local folder = workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and mobMatchesIDFilter(obj) then
                table.insert(mobs, obj)
            end
        end
    end
    return mobs
end

local function makeMobGui(mob)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildOfClass("BasePart")
    if not root then return end
    local bb = Instance.new("BillboardGui")
    bb.Name="MobESP_"..mob.Name; bb.Adornee=root; bb.AlwaysOnTop=true
    bb.Size=UDim2.new(0,160,0,70); bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.MaxDistance=ESP_CONFIG.MaxDistance>0 and ESP_CONFIG.MaxDistance or math.huge
    bb.Parent=MobESPFolder
    if ESP_CONFIG.ShowHealth then
        local hum=mob:FindFirstChildOfClass("Humanoid")
        local hpBg=Instance.new("Frame"); hpBg.Name="HPBg"
        hpBg.BackgroundColor3=Color3.fromRGB(15,15,15); hpBg.BorderSizePixel=0
        hpBg.Size=UDim2.new(0,7,1,0); hpBg.Position=UDim2.new(0,0,0,0); hpBg.Parent=bb
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(200,200,200); stroke.Thickness=0.8; stroke.Parent=hpBg
        local fill=Instance.new("Frame"); fill.Name="HPFill"
        fill.AnchorPoint=Vector2.new(0,1); fill.BorderSizePixel=0
        fill.BackgroundColor3=Color3.fromRGB(0,210,60)
        fill.Size=UDim2.new(1,0,1,0); fill.Position=UDim2.new(0,0,1,0); fill.Parent=hpBg
        if hum then
            local function updateHP()
                local pct=hum.Health/math.max(hum.MaxHealth,1)
                fill.Size=UDim2.new(1,0,pct,0)
                fill.BackgroundColor3=Color3.fromRGB(math.floor(255*(1-pct)),math.floor(210*pct),20)
            end
            updateHP(); hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
        end
    end
    local cx=11; local yPx=0
    if ESP_CONFIG.ShowName then
        local lbl=Instance.new("TextLabel"); lbl.Name="NameLbl"
        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-cx,0,24)
        lbl.Position=UDim2.new(0,cx,0,yPx); lbl.Text=mob.Name
        lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextStrokeTransparency=0.65
        lbl.TextScaled=true; lbl.Font=Enum.Font.FredokaOne
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=bb; yPx+=24
    end
    if ESP_CONFIG.ShowDistance then
        local lbl=Instance.new("TextLabel"); lbl.Name="DistLbl"
        lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-cx,0,18)
        lbl.Position=UDim2.new(0,cx,0,yPx); lbl.Text="0 studs"
        lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextStrokeTransparency=0.65
        lbl.TextScaled=true; lbl.Font=Enum.Font.GothamMedium
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=bb
    end
end

local function startMobESP()
    MobESPFolder=Instance.new("Folder")
    MobESPFolder.Name="MobESPHolder"; MobESPFolder.Parent=LocalPlayer.PlayerGui
    for _,mob in ipairs(getMobs()) do makeMobGui(mob) end
    local folder=workspace:FindFirstChild(ESP_CONFIG.MobFolder)
    if folder then
        folder.DescendantAdded:Connect(function(obj)
            if not MobESPEnabled then return end
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                task.wait(); makeMobGui(obj)
            end
        end)
    end
    MobESPUpdateConn=RunService.Heartbeat:Connect(function()
        if not MobESPEnabled or not ESP_CONFIG.ShowDistance then return end
        local myRoot=getRoot(); if not myRoot or not MobESPFolder then return end
        for _,bb in ipairs(MobESPFolder:GetChildren()) do
            local lbl=bb:FindFirstChild("DistLbl"); local adornee=bb.Adornee
            if lbl and adornee then
                lbl.Text=math.floor((adornee.Position-myRoot.Position).Magnitude).." studs"
            end
        end
    end)
end

local function stopMobESP()
    if MobESPUpdateConn then MobESPUpdateConn:Disconnect(); MobESPUpdateConn=nil end
    if MobESPFolder then MobESPFolder:Destroy(); MobESPFolder=nil end
end

-- ========================================
--             PLAYER ESP
-- ========================================

local PlayerESP_CONFIG = {
    ShowName=true; ShowHealth=true; ShowTeam=true; ShowDistance=true;
    MaxDistance=0; NameColor=Color3.fromRGB(255,255,255); DistColor=Color3.fromRGB(255,220,50);
}
local PlayerESPEnabled=false; local PlayerESPFolder=nil
local PlayerESPConns={}; local PlayerESPUpdateConn=nil

local function makePlayerGui(player)
    if player==LocalPlayer then return end
    local function build()
        local char=player.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local old=PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_"..player.Name)
        if old then old:Destroy() end
        local bb=Instance.new("BillboardGui")
        bb.Name="ESP_"..player.Name; bb.Adornee=root; bb.AlwaysOnTop=true
        bb.Size=UDim2.new(0,170,0,70); bb.StudsOffset=Vector3.new(0,3.5,0)
        bb.MaxDistance=PlayerESP_CONFIG.MaxDistance>0 and PlayerESP_CONFIG.MaxDistance or math.huge
        bb.Parent=PlayerESPFolder
        if PlayerESP_CONFIG.ShowHealth then
            local hum=char:FindFirstChildOfClass("Humanoid")
            local hpBg=Instance.new("Frame"); hpBg.Name="HPBg"
            hpBg.BackgroundColor3=Color3.fromRGB(15,15,15); hpBg.BorderSizePixel=0
            hpBg.Size=UDim2.new(0,7,1,0); hpBg.Position=UDim2.new(0,0,0,0); hpBg.Parent=bb
            local stroke=Instance.new("UIStroke")
            stroke.Color=Color3.fromRGB(255,255,255); stroke.Thickness=0.8; stroke.Parent=hpBg
            local fill=Instance.new("Frame"); fill.Name="HPFill"
            fill.AnchorPoint=Vector2.new(0,1); fill.BorderSizePixel=0
            fill.BackgroundColor3=Color3.fromRGB(0,210,60)
            fill.Size=UDim2.new(1,0,1,0); fill.Position=UDim2.new(0,0,1,0); fill.Parent=hpBg
            if hum then
                local function updateHP()
                    local pct=hum.Health/math.max(hum.MaxHealth,1)
                    fill.Size=UDim2.new(1,0,pct,0)
                    fill.BackgroundColor3=Color3.fromRGB(math.floor(255*(1-pct)),math.floor(210*pct),20)
                end
                updateHP(); hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
            end
        end
        local cx=14; local yPx=0
        if PlayerESP_CONFIG.ShowName then
            local lbl=Instance.new("TextLabel"); lbl.Name="NameLbl"
            lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-cx,0,26)
            lbl.Position=UDim2.new(0,cx,0,yPx); lbl.Text=player.Name
            lbl.TextColor3=PlayerESP_CONFIG.NameColor; lbl.TextStrokeTransparency=0.3
            lbl.TextScaled=true; lbl.Font=Enum.Font.FredokaOne
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=bb; yPx+=26
        end
        if PlayerESP_CONFIG.ShowDistance then
            local lbl=Instance.new("TextLabel"); lbl.Name="DistLbl"
            lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-cx,0,20)
            lbl.Position=UDim2.new(0,cx,0,yPx); lbl.Text="0 studs"
            lbl.TextColor3=PlayerESP_CONFIG.DistColor; lbl.TextStrokeTransparency=0.4
            lbl.TextScaled=true; lbl.Font=Enum.Font.GothamMedium
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=bb
        end
    end
    build()
    local conn=player.CharacterAdded:Connect(function() task.wait(0.5); build() end)
    table.insert(PlayerESPConns,conn)
end

local function startPlayerESP()
    PlayerESPFolder=Instance.new("Folder")
    PlayerESPFolder.Name="PlayerESPHolder"; PlayerESPFolder.Parent=LocalPlayer.PlayerGui
    for _,p in ipairs(Players:GetPlayers()) do makePlayerGui(p) end
    local ac=Players.PlayerAdded:Connect(function(p)
        if not PlayerESPEnabled then return end; task.wait(1); makePlayerGui(p)
    end)
    table.insert(PlayerESPConns,ac)
    local rc=Players.PlayerRemoving:Connect(function(p)
        local g=PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_"..p.Name)
        if g then g:Destroy() end
    end)
    table.insert(PlayerESPConns,rc)
    PlayerESPUpdateConn=RunService.Heartbeat:Connect(function()
        if not PlayerESPEnabled or not PlayerESP_CONFIG.ShowDistance then return end
        local myRoot=getRoot(); if not myRoot then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p==LocalPlayer then continue end
            local c=p.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
            if not r then continue end
            local g=PlayerESPFolder and PlayerESPFolder:FindFirstChild("ESP_"..p.Name)
            local lbl=g and g:FindFirstChild("DistLbl")
            if lbl then lbl.Text=math.floor((r.Position-myRoot.Position).Magnitude).." studs" end
        end
    end)
end

local function stopPlayerESP()
    if PlayerESPUpdateConn then PlayerESPUpdateConn:Disconnect(); PlayerESPUpdateConn=nil end
    for _,c in ipairs(PlayerESPConns) do c:Disconnect() end
    PlayerESPConns={}
    if PlayerESPFolder then PlayerESPFolder:Destroy(); PlayerESPFolder=nil end
end

-- ========================================
--           NPC TELEPORT
-- ========================================

local NPC_LIST = {
    { label="Chest TP", id="101" },
    { label="Chest 1",  id="103" },
    { label="Chest 2",  id="104" },
    { label="Chest 3",  id="105" },
    { label="Chest 4",  id="106" },
    { label="Chest 5",  id="107" },
    { label="Chest 6",  id="108" },
    { label="Chest 7",  id="109" },
    { label="Chest 8",  id="110" },
}

local function tpToNPC(npcId)
    local root=getRoot(); if not root then return end
    local npcRoot=nil
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj.Name==npcId and obj:IsA("Model") then
            npcRoot=obj:FindFirstChild("HumanoidRootPart")
            if not npcRoot then
                for _,v in ipairs(obj:GetChildren()) do
                    if v:IsA("BasePart") then npcRoot=v; break end
                end
            end
            break
        end
    end
    if npcRoot then
        root.CFrame=npcRoot.CFrame+Vector3.new(0,3,0)
        Rayfield:Notify({Title="Teleport",Content="Teleported to chest!",Duration=2})
    else
        Rayfield:Notify({Title="Teleport",Content="Chest not found!",Duration=2})
    end
end

-- ========================================
--              RAYFIELD UI
-- ========================================

local Window = Rayfield:CreateWindow({
    Name             = "Junior Hub",
    LoadingTitle     = "Junior Hub",
    LoadingSubtitle  = "Loading features...",
    ConfigurationSaving = {
        Enabled    = false,
        FolderName = nil,
        FileName   = "JuniorHub",
    },
    Discord  = { Enabled=false },
    KeySystem = false,
})

-- ===== COMBAT TAB =====

local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Auto Clicker")

CombatTab:CreateToggle({
    Name         = "Enable Auto Clicker",
    CurrentValue = false,
    Flag         = "AutoClick",
    Callback     = function(v) AutoClickEnabled = v end,
})

CombatTab:CreateSlider({
    Name         = "Clicks Per Second",
    Range        = {1, 50},
    Increment    = 1,
    Suffix       = " CPS",
    CurrentValue = 20,
    Flag         = "CPS",
    Callback     = function(v) ClickDelay = 1/v end,
})

CombatTab:CreateSection("Auto Dwarf King Quest")

CombatTab:CreateToggle({
    Name         = "Enable Auto Quest",
    CurrentValue = false,
    Flag         = "AutoQuest",
    Callback     = function(v)
        AutoQuestEnabled = v
        if v then startAutoQuest() else stopAutoQuest() end
    end,
})

CombatTab:CreateButton({
    Name     = "Take Quest Once",
    Callback = function()
        task.spawn(runQuestSequence)
        Rayfield:Notify({Title="Quest",Content="Quest sequence fired!",Duration=2})
    end,
})

-- ===== FLYING TAB =====

local FlyTab = Window:CreateTab("Flying", 4483362458)

FlyTab:CreateSection("Flight")

local FlyToggleEl
FlyToggleEl = FlyTab:CreateToggle({
    Name         = "Enable Flight",
    CurrentValue = false,
    Flag         = "FlyEnabled",
    Callback     = function(v) setFly(v) end,
})

FlyTab:CreateSlider({
    Name         = "Flight Speed",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = " studs/s",
    CurrentValue = 60,
    Flag         = "FlySpeed",
    Callback     = function(v) FlySpeed = v end,
})

-- ===== ESP TAB =====

local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateSection("Mob ESP")

ESPTab:CreateToggle({
    Name         = "Enable Mob ESP",
    CurrentValue = false,
    Flag         = "MobESP",
    Callback     = function(v)
        MobESPEnabled = v
        if v then startMobESP() else stopMobESP() end
    end,
})

ESPTab:CreateToggle({
    Name         = "Show Mob Names",
    CurrentValue = true,
    Flag         = "MobNames",
    Callback     = function(v) ESP_CONFIG.ShowName = v end,
})

ESPTab:CreateToggle({
    Name         = "Show Mob Health",
    CurrentValue = true,
    Flag         = "MobHealth",
    Callback     = function(v) ESP_CONFIG.ShowHealth = v end,
})

ESPTab:CreateToggle({
    Name         = "Show Mob Distance",
    CurrentValue = true,
    Flag         = "MobDist",
    Callback     = function(v) ESP_CONFIG.ShowDistance = v end,
})

ESPTab:CreateToggle({
    Name         = "Filter by Mob ID",
    CurrentValue = false,
    Flag         = "MobFilter",
    Callback     = function(v)
        ESP_CONFIG.FilterByID = v
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateSlider({
    Name         = "Mob Max Distance",
    Range        = {0, 2000},
    Increment    = 50,
    Suffix       = " studs",
    CurrentValue = 0,
    Flag         = "MobESPDist",
    Callback     = function(v)
        ESP_CONFIG.MaxDistance = v
        if MobESPEnabled then stopMobESP(); startMobESP() end
    end,
})

ESPTab:CreateInput({
    Name                  = "Mob Folder Name",
    PlaceholderText       = "e.g. Monster, Mobs, Enemies",
    RemoveTextAfterFocusLost = false,
    Flag                  = "MobFolder",
    Callback              = function(v)
        if v ~= "" then
            ESP_CONFIG.MobFolder = v
            if MobESPEnabled then stopMobESP(); startMobESP() end
        end
    end,
})

ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name         = "Enable Player ESP",
    CurrentValue = false,
    Flag         = "PlayerESP",
    Callback     = function(v)
        PlayerESPEnabled = v
        if v then startPlayerESP() else stopPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name         = "Show Player Names",
    CurrentValue = true,
    Flag         = "PlayerNames",
    Callback     = function(v)
        PlayerESP_CONFIG.ShowName = v
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name         = "Show Player Health",
    CurrentValue = true,
    Flag         = "PlayerHealth",
    Callback     = function(v)
        PlayerESP_CONFIG.ShowHealth = v
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateToggle({
    Name         = "Show Player Distance",
    CurrentValue = true,
    Flag         = "PlayerDist",
    Callback     = function(v)
        PlayerESP_CONFIG.ShowDistance = v
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

ESPTab:CreateSlider({
    Name         = "Player Max Distance",
    Range        = {0, 2000},
    Increment    = 50,
    Suffix       = " studs",
    CurrentValue = 0,
    Flag         = "PlayerESPDist",
    Callback     = function(v)
        PlayerESP_CONFIG.MaxDistance = v
        if PlayerESPEnabled then stopPlayerESP(); startPlayerESP() end
    end,
})

-- ===== TELEPORT TAB =====

local TPTab = Window:CreateTab("Teleport", 4483362458)

TPTab:CreateSection("Chest Teleport")

for _, entry in ipairs(NPC_LIST) do
    local capturedId = entry.id
    TPTab:CreateButton({
        Name     = entry.label,
        Callback = function() tpToNPC(capturedId) end,
    })
end

-- ===== MISC TAB =====

local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Visual Tweaks")

MiscTab:CreateToggle({
    Name         = "No Fog",
    CurrentValue = false,
    Flag         = "NoFog",
    Callback     = function(v)
        NoFogEnabled = v
        if v then applyNoFog() else removeNoFog() end
    end,
})

MiscTab:CreateToggle({
    Name         = "No Shadows",
    CurrentValue = false,
    Flag         = "NoShadows",
    Callback     = function(v)
        if v then removeShadows() else restoreShadows() end
    end,
})

MiscTab:CreateToggle({
    Name         = "No Grass",
    CurrentValue = false,
    Flag         = "NoGrass",
    Callback     = function(v)
        if v then removeGrass() else restoreGrass() end
    end,
})

MiscTab:CreateToggle({
    Name         = "No Textures",
    CurrentValue = false,
    Flag         = "NoTextures",
    Callback     = function(v)
        if v then removeTextures() else restoreTextures() end
    end,
})

MiscTab:CreateToggle({
    Name         = "No Post-Processing FX",
    CurrentValue = false,
    Flag         = "NoPostFX",
    Callback     = function(v)
        if v then removePostFX() else restorePostFX() end
    end,
})

MiscTab:CreateSection("Lighting")

MiscTab:CreateToggle({
    Name         = "Full Bright",
    CurrentValue = false,
    Flag         = "FullBright",
    Callback     = function(v)
        FullBrightEnabled = v
        if v then applyFullBright() else removeFullBright() end
    end,
})

MiscTab:CreateSlider({
    Name         = "Time of Day",
    Range        = {0, 24},
    Increment    = 0.5,
    Suffix       = ":00",
    CurrentValue = 14,
    Flag         = "TimeOfDay",
    Callback     = function(v) lockTime(v) end,
})

MiscTab:CreateButton({
    Name     = "Unlock Time",
    Callback = function()
        unlockTime()
        Rayfield:Notify({Title="Time",Content="Time unlocked.",Duration=2})
    end,
})

-- ===== GP GIVER TAB =====

local GPTab = Window:CreateTab("GP Giver", 4483362458)

GPTab:CreateSection("GamePass Giver")

local GP_TargetName = LocalPlayer.Name

GPTab:CreateInput({
    Name                     = "Target Username",
    PlaceholderText          = "Roblox username",
    RemoveTextAfterFocusLost = false,
    Flag                     = "GPTarget",
    Callback                 = function(v)
        if v ~= "" then GP_TargetName = v end
    end,
})

local GP_LIST = {
    { name="Cauldron 1",     key="Cauldron_1"    },
    { name="Fast Alchemy",   key="FastAlchemy"   },
    { name="Better Alchemy", key="BetterAlchemy" },
    { name="Sell Anywhere",  key="SellAnywhere"  },
    { name="Double Storage", key="DoubleStorage" },
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
                Rayfield:Notify({Title="GP Giver",Content=g.name.." set to 1!",Duration=2})
            else
                Rayfield:Notify({Title="GP Giver",Content="Failed: "..tostring(err),Duration=4})
            end
        end,
    })
end

-- ===== SETTINGS TAB =====

local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Player")

SettingsTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = " stud/s",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(v)
        local hum=getHumanoid(); if hum then hum.WalkSpeed=v end
    end,
})

SettingsTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {0, 300},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(v)
        local hum=getHumanoid()
        if hum then hum.UseJumpPower=true; hum.JumpPower=v end
    end,
})

SettingsTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(v) _G.DaxinInfJump = v end,
})

UserInputService.JumpRequest:Connect(function()
    if _G.DaxinInfJump then
        local hum=getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

SettingsTab:CreateSection("Utilities")

SettingsTab:CreateButton({
    Name     = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

SettingsTab:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        local hum=getHumanoid(); if hum then hum.Health=0 end
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy UserId",
    Callback = function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
        Rayfield:Notify({Title="Copied",Content="UserId: "..LocalPlayer.UserId,Duration=3})
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy Game ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
        Rayfield:Notify({Title="Copied",Content="Place ID: "..game.PlaceId,Duration=3})
    end,
})

SettingsTab:CreateButton({
    Name     = "Stop All Features",
    Callback = function()
        AutoClickEnabled  = false
        AutoQuestEnabled  = false
        NoFogEnabled      = false
        FullBrightEnabled = false
        _G.DaxinInfJump   = false
        stopAutoQuest()
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
        MobESPEnabled    = false
        PlayerESPEnabled = false
        Rayfield:Notify({Title="Stopped",Content="All features stopped.",Duration=2})
    end,
})

Rayfield:Notify({Title="Junior Hub",Content="Loaded successfully!",Duration=3})
