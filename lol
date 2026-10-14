if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local _ENV_GUARD = "dhSAE" .. tostring(game.PlaceId)
pcall(function()
    if _G[_ENV_GUARD] and type(_G[_ENV_GUARD]) == "function" then
        pcall(_G[_ENV_GUARD])
    end
    local ok, h = pcall(function() return gethui() end)
    local root = (ok and typeof(h)=="Instance" and h)
        or game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if root then
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("ScreenGui") and (child.Name:find("DHub") or child.Name:find("DHUB") or child.Name:find("_dh")) then
                pcall(function() child:Destroy() end)
            end
        end
    end
end)

local ScriptConnections = {}
local DHub = {}

DHub.LongAFKRuntime = {
    alive = true,
}

_G[_ENV_GUARD] = function()
    for _, conn in ipairs(ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end

    DHub.LongAFKRuntime.alive = false

    pcall(function()
        if DHub.NotifierCleanup then
            DHub.NotifierCleanup()
        end
    end)

    pcall(function()
        if DHub.AutoSell
            and DHub.AutoSell.Stop
        then
            DHub.AutoSell:Stop()
        end
    end)

    pcall(function()
        if DHub.AutoBestPet
            and DHub.AutoBestPet.Stop
        then
            DHub.AutoBestPet:Stop(false)
        end
    end)

    pcall(function()
        if DHub.AutoBoss
            and DHub.AutoBoss.Stop
        then
            DHub.AutoBoss.Stop(true)
        end
    end)

    pcall(function()
        if DHub.ScrambleFuse
            and DHub.ScrambleFuse.Stop
        then
            DHub.ScrambleFuse.Stop()
        end
    end)
end

local S = {
    Players           = game:GetService("Players"),
    RunService        = game:GetService("RunService"),
    Workspace         = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService  = game:GetService("UserInputService"),
    TweenService      = game:GetService("TweenService"),
    HttpService       = game:GetService("HttpService"),
    TeleportService   = game:GetService("TeleportService"),
    Lighting          = game:GetService("Lighting"),
    PathfindingService= game:GetService("PathfindingService"),
}
local LP = S.Players.LocalPlayer
while not LP do
    task.wait(0.1)
    LP = S.Players.LocalPlayer
end

task.spawn(function()
    while DHub.LongAFKRuntime.alive do
        task.wait(60)

        local writeIndex = 1
        local total = #ScriptConnections

        for readIndex = 1, total do
            local conn = ScriptConnections[readIndex]
            local connected = false

            if conn then
                pcall(function()
                    connected = conn.Connected == true
                end)
            end

            if connected then
                ScriptConnections[writeIndex] = conn
                writeIndex = writeIndex + 1
            end
        end

        for i = total, writeIndex, -1 do
            ScriptConnections[i] = nil
        end
    end
end)

local CONFIG_FOLDER = "D-HUB"
local CONFIG_PATH   = CONFIG_FOLDER .. "/StealAnEggV2.3.json"
local PLACE_ID      = 107778070777162
local SAFEZONE_POS  = Vector3.new(530, 70, -363)

pcall(function()
    if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end)

local LoadedCfg = {}
pcall(function()
    if isfile and isfile(CONFIG_PATH) then
        local raw = readfile(CONFIG_PATH)
        if raw and raw ~= "" then LoadedCfg = S.HttpService:JSONDecode(raw) end
    end
end)
if type(LoadedCfg) ~= "table" then LoadedCfg = {} end


local Cfg = {
    walkSpeed        = math.clamp(tonumber(LoadedCfg.walkSpeed) or 35, 1, 320),
    selectedAreas    = type(LoadedCfg.selectedAreas)=="table"    and LoadedCfg.selectedAreas    or {["All"]=true},
    selectedRarities = type(LoadedCfg.selectedRarities)=="table" and LoadedCfg.selectedRarities or {["All"]=true},
    minWeight        = tonumber(LoadedCfg.minWeight) or 0,
    farmPriority     = LoadedCfg.farmPriority or "Nearest",

    farmMethod       = LoadedCfg.farmMethod == "Fast" and "Fast" or "Normal",

    instantSteal     = LoadedCfg.instantSteal ~= false,
    autoFarm         = LoadedCfg.autoFarm == true,
    antiBoss         = LoadedCfg.antiBoss == true,
    autoTreadmill    = LoadedCfg.autoTreadmill == true,
}

local PlotCfg = {
    selectedRarities = type(LoadedCfg.plotRarities)=="table"  and LoadedCfg.plotRarities  or {["All"]=true},
    minWeight        = tonumber(LoadedCfg.plotMinWeight)       or 0,
    autoPlace        = LoadedCfg.plotAutoPlace                 == true,
    autoHatch        = LoadedCfg.plotAutoHatch                 == true,

    autoBestPet      = LoadedCfg.plotAutoBestPet == true,
    bestPetDelayMin  = math.clamp(tonumber(LoadedCfg.plotBestPetDelayMin) or 10, 0.1, 1440),
}

local ShopCfg = {
    sellEggRarities  = type(LoadedCfg.sellEggRarities)=="table"  and LoadedCfg.sellEggRarities  or {},
    sellPetRarities  = type(LoadedCfg.sellPetRarities)=="table"  and LoadedCfg.sellPetRarities  or {},
    autoSellAll      = LoadedCfg.autoSellAll == true,
    autoUpgradePlot  = LoadedCfg.autoUpgradePlot == true,
    autoUpgradeTread = LoadedCfg.autoUpgradeTread == true,
    selectedPetFuse  = tostring(LoadedCfg.selectedPetFuse or "None"),
    autoFuse         = LoadedCfg.autoFuse == true,
}

local EventCfg = {
    autoBoss         = LoadedCfg.autoBoss == true,

    -- Legacy Wave / Cave Quest are retired in the current event build.
    -- Keep their engine code loaded only because Auto Boss still reuses the
    -- proven dual-bat primitive from ScrambleFarm.State.tickDualBatSwap.
    autoWave         = false,
    autoDoubleBat    = false,

    -- Current Dr. Scramble Lab fuse loop. Migrate old Rift toggle once.
    autoFuseScrambler = LoadedCfg.autoFuseScrambler == true
        or LoadedCfg.autoFuseEvent == true,

    -- Legacy Rift engine is intentionally disabled.
    autoFuseEvent    = false,

    autoConsumable   = LoadedCfg.autoConsumable == true,
    consumableRarities = type(LoadedCfg.consumableRarities) == "table"
        and LoadedCfg.consumableRarities
        or {},

    autoBuyBossShop  = LoadedCfg.autoBuyBossShop == true,
    bossShopItems    = type(LoadedCfg.bossShopItems) == "table"
        and LoadedCfg.bossShopItems
        or {},
}

local MiscCfg = {
    fpsBoost         = LoadedCfg.fpsBoost == true,
    ultraFps         = LoadedCfg.ultraFps == true,
    hopDelay         = tonumber(LoadedCfg.hopDelay) or 30,
    hopMethod        = LoadedCfg.hopMethod or "Small Server",
    autoHop          = LoadedCfg.autoHop == true,

    compactUi        = LoadedCfg.compactUi == true,
}

local ZONES = {
    ["Forest"]         = Vector3.new(597, 71, -330),
    ["Lake"]           = Vector3.new(743, 71, -409),
    ["Desert"]         = Vector3.new(950, 71, -325),
    ["Jungle"]         = Vector3.new(1189, 71, -408),
    ["Snow"]           = Vector3.new(1492, 71, -317),
    ["Volcano"]        = Vector3.new(1880, 71, -396),
    ["Abyss Ocean"]    = Vector3.new(2281, 71, -330),
    ["Prehistoric"]    = Vector3.new(2813, 71, -395),
    ["Cosmic"]         = Vector3.new(3392, 71, -327),
    ["Cherry Blossom"] = Vector3.new(4028, 71, -396),
    ["Titan Temple"]   = Vector3.new(4798, 71, -328),
    ["Light Dark"]     = Vector3.new(5563, 71, -364),
    ["Enchanted Forest"] = Vector3.new(6697, 68, -350),
}

local ZONE_NAMES    = {"All","Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Light Dark","Enchanted Forest"}
local RARITIES      = {"All","Common","Uncommon","Rare","SuperRare","Epic","Legendary","Mythic","Cosmic","Secret","Exotic","Exclusive","Limited","Superior","Eternal","Divine","Titan","BrainrotGod","LightDark"}
local SELL_RARITIES = {"Common","Uncommon","Rare","SuperRare","Epic","Legendary","Mythic","Cosmic","Secret","Exotic","Exclusive","Limited","Superior","Eternal","Divine","Titan","BrainrotGod","LightDark"}

local RARITY_ORDER = {
    Common=1, Basic=1, Uncommon=2, Celestial=2, SuperRare=3,
    Rare=4, Epic=5, Legendary=6,
    Mythic=7, Mythical=7, Rainbow=7, Prismatic=7,
    Cosmic=8, Exclusive=8, Admin=8, Limited=8,
    Secret=9, Exotic=9, Eternal=9,
    Superior=10, Transcendent=10, Divine=10,
    Titan=11, BrainrotGod=12,
}

DHub.RarestFarmRank = {
    Common      = 1,
    Basic       = 1,
    Uncommon    = 2,
    Celestial   = 2,
    Rare        = 3,
    SuperRare   = 4,
    Epic        = 5,
    Legendary   = 6,
    Mythic      = 7,
    Mythical    = 7,
    Rainbow     = 7,
    Prismatic   = 7,
    Cosmic      = 8,
    Secret      = 9,
    Exotic      = 10,
    Exclusive   = 11,
    Admin       = 11,
    Limited     = 12,
    Superior    = 13,
    Transcendent= 13,
    Eternal     = 14,
    Divine      = 15,
    Titan       = 16,
    BrainrotGod = 17,
    LightDark   = 18,
}

DHub.FarmAreaProgressRank = {
    ["Forest"]         = 1,
    ["Lake"]           = 2,
    ["Desert"]         = 3,
    ["Jungle"]         = 4,
    ["Snow"]           = 5,
    ["Volcano"]        = 6,
    ["Abyss Ocean"]    = 7,
    ["Prehistoric"]    = 8,
    ["Cosmic"]         = 9,
    ["Cherry Blossom"] = 10,
    ["Titan Temple"]   = 11,
    ["Light Dark"]     = 12,
    ["Enchanted Forest"] = 13,
}

local function saveConfig()
    pcall(function()
        if isfolder and makefolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        writefile(CONFIG_PATH, S.HttpService:JSONEncode({
            walkSpeed        = Cfg.walkSpeed,
            selectedAreas    = Cfg.selectedAreas,
            selectedRarities = Cfg.selectedRarities,
            minWeight        = Cfg.minWeight,
            farmPriority     = Cfg.farmPriority,
            farmMethod       = Cfg.farmMethod,
            instantSteal     = Cfg.instantSteal,
            autoFarm         = Cfg.autoFarm,
            antiBoss         = Cfg.antiBoss,
            autoTreadmill    = Cfg.autoTreadmill,
            plotRarities     = PlotCfg.selectedRarities,
            plotMinWeight    = PlotCfg.minWeight,
            plotAutoPlace    = PlotCfg.autoPlace,
            plotAutoHatch    = PlotCfg.autoHatch,
            plotAutoBestPet  = PlotCfg.autoBestPet,
            plotBestPetDelayMin = PlotCfg.bestPetDelayMin,
            sellEggRarities  = ShopCfg.sellEggRarities,
            sellPetRarities  = ShopCfg.sellPetRarities,
            autoSellAll      = ShopCfg.autoSellAll,
            autoUpgradePlot  = ShopCfg.autoUpgradePlot,
            autoUpgradeTread = ShopCfg.autoUpgradeTread,
            selectedPetFuse  = ShopCfg.selectedPetFuse,
            autoFuse         = ShopCfg.autoFuse,
            autoBoss         = EventCfg.autoBoss,
            autoWave         = false,
            autoScrambleFarm = false,
            autoDoubleBat    = false,
            autoFuseScrambler= EventCfg.autoFuseScrambler,
            autoFuseEvent    = false,

            autoConsumable   = EventCfg.autoConsumable,
            consumableRarities = EventCfg.consumableRarities,
            autoBuyBossShop  = EventCfg.autoBuyBossShop,
            bossShopItems    = EventCfg.bossShopItems,

            fpsBoost         = MiscCfg.fpsBoost,
            ultraFps         = MiscCfg.ultraFps,
            hopDelay         = MiscCfg.hopDelay,
            hopMethod        = MiscCfg.hopMethod,
            autoHop          = MiscCfg.autoHop,
            compactUi        = MiscCfg.compactUi,
        }))
    end)
end

do
    local function silenceIdle()
        local ok, list = pcall(function() return getconnections(LP.Idled) end)
        if ok and type(list)=="table" then
            for _, c in ipairs(list) do pcall(function() c:Disable() end) end
        end
    end
    silenceIdle()
    LP.Idled:Connect(function()
        silenceIdle()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                local cf = cam.CFrame
                cam.CFrame = cf * CFrame.Angles(0, 0.001, 0)
                task.wait(0.1)
                cam.CFrame = cf
            end
        end)
    end)
end

local function getGuiRoot()
    local ok, h = pcall(function() return gethui() end)
    if ok and typeof(h)=="Instance" then return h end
    return LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
end
local GuiRoot = getGuiRoot()

local NET     = S.ReplicatedStorage:FindFirstChild("Network")
local PKG_NET = S.ReplicatedStorage:FindFirstChild("Packages") and S.ReplicatedStorage.Packages:FindFirstChild("Networking")

local function getRemote(name)
    if PKG_NET and PKG_NET:FindFirstChild(name) then return PKG_NET:FindFirstChild(name) end
    if NET and NET:FindFirstChild(name) then return NET:FindFirstChild(name) end
    return nil
end

local function _pnet(name)
    local PKG = S.ReplicatedStorage:FindFirstChild("Packages")
    local NET2 = PKG and PKG:FindFirstChild("Networking")
    if NET2 then
        local r = NET2:FindFirstChild(name)
        if r then return r end
    end
    return getRemote(name)
end

local RMT = {
    CarryEgg            = _pnet("RF/EggWorld/AskFieldEggCarry") or getRemote("Eggs: RequestAreaEggCarry"),
    Hatch               = _pnet("RF/EggWorld/AskHatch"),
    FinishHatch         = _pnet("RF/EggWorld/AskFinishHatch"),
    FuseryLoadPet       = _pnet("RF/Fusery/LoadPet"),
    FuseryBeginFuse     = _pnet("RF/Fusery/BeginFuse"),
    FuseryFinishReveal  = _pnet("RF/Fusery/FinishReveal"),
    BaseUpgrade         = _pnet("RE/Homestead/AskBaseTierRaise"),
    TreadmillUpgrade    = _pnet("RF/Treadmill/AskTierRaise"),
    RiftAskState        = _pnet("RF/Rift/AskState"),
    RiftAskTradeIn      = _pnet("RF/Rift/AskTradeIn"),
    RiftAskFinishReveal = _pnet("RF/Rift/AskFinishReveal"),

    ScrambleTradeAskState =
        _pnet("RF/ScrambleTradeIn/AskState"),
    ScrambleTradeAskTradeIn =
        _pnet("RF/ScrambleTradeIn/AskTradeIn"),
    ScrambleTradeAskFinishReveal =
        _pnet("RF/ScrambleTradeIn/AskFinishReveal"),
    ScrambleTradeAskRefresh =
        _pnet("RF/ScrambleTradeIn/AskRefresh"),

    ScrambleRequest     = _pnet("RF/Scramble/Request"),
    ScrambleDrones      = _pnet("RE/Scramble/Drones"),
    ScrambleState       = _pnet("RE/Scramble/State"),
    SellSelection       = nil,
}

pcall(function()
    local Remotes = require(S.ReplicatedStorage.Shared.Remotes)
    if Remotes.PetSatchel then
        RMT.SellSelection = Remotes.PetSatchel.SellSelection
    end
end)

if not RMT.SellSelection then
    RMT.SellSelection = _pnet("RE/PetSatchel/SellSelection")
end

local Runtime = {
    rootPart=nil, humanoid=nil, farming=false, isAutoWalking=false,
    steals=0, statusText="Idle", StatusLbl=nil, carryEscapeActive=false,
}

local function UpdateStatus(txt)
    Runtime.statusText=tostring(txt or "Idle")
    if Runtime.StatusLbl then
        Runtime.StatusLbl.Text=string.format("Status: %s  |  Steals: %d",Runtime.statusText,Runtime.steals)
    end
end

local function getChar() return LP.Character end
local function getRoot()
    local char=LP.Character
    if not char then Runtime.rootPart=nil return nil end
    if Runtime.rootPart and Runtime.rootPart.Parent==char then return Runtime.rootPart end
    Runtime.rootPart=char:FindFirstChild("HumanoidRootPart")
    return Runtime.rootPart
end
local function getHumanoid()
    local char=LP.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end
local function ensureCharacter(timeout)
    local deadline=tick()+(tonumber(timeout) or 8)
    repeat
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if char and root and hum and hum.Health>0 then
            Runtime.rootPart=root; Runtime.humanoid=hum
            return char,root,hum
        end
        S.RunService.Heartbeat:Wait()
    until tick()>=deadline
    return LP.Character,getRoot(),getHumanoid()
end

local doFarmLoop
local Notify
local attemptPickup

DHub.CharacterService={
    character=nil,bypassedCharacter=nil,bypassBusy=false,
    characterBornAt=0,rigPrimedAt=0,diedConnection=nil,
}

DHub.RigPrimedRemote=PKG_NET and PKG_NET:FindFirstChild("RE/RigSync/Primed")
if DHub.RigPrimedRemote and DHub.RigPrimedRemote:IsA("RemoteEvent") then
    local conn=DHub.RigPrimedRemote.OnClientEvent:Connect(function()
        DHub.CharacterService.rigPrimedAt=tick()
    end)
    table.insert(ScriptConnections,conn)
end

function DHub.CharacterService:_Bind(char)
    self.character=char
    self.bypassedCharacter=nil
    self.bypassBusy=false
    self.characterBornAt=tick()
    self.rigPrimedAt=0
    Runtime.rootPart=nil; Runtime.humanoid=nil
    if self.diedConnection then pcall(function() self.diedConnection:Disconnect() end); self.diedConnection=nil end
    if not char then return end
    task.spawn(function()
        local hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",8)
        if not hum or LP.Character~=char then return end
        self.diedConnection=hum.Died:Connect(function()
            if self.bypassedCharacter==char then self.bypassedCharacter=nil end
        end)
        table.insert(ScriptConnections,self.diedConnection)
    end)
end

function DHub.CharacterService:ApplyBypassOnce(char)
    char=char or LP.Character
    if not char or LP.Character~=char then return false end
    if self.bypassedCharacter==char then return true end
    if self.bypassBusy then
        local deadline=tick()+3
        while self.bypassBusy and LP.Character==char and tick()<deadline do S.RunService.Heartbeat:Wait() end
        return self.bypassedCharacter==char
    end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false end
    self.bypassBusy=true
    local ok=pcall(function()
        local cam=workspace.CurrentCamera
        local anim=char:FindFirstChild("Animate")
        local ws,jp,jh,hp,mhp=hum.WalkSpeed,hum.JumpPower,hum.JumpHeight,hum.Health,hum.MaxHealth
        if anim and anim:IsA("LocalScript") then anim.Disabled=true end
        local animator=hum:FindFirstChildOfClass("Animator")
        if animator then for _,tr in next,animator:GetPlayingAnimationTracks() do tr:Stop(0) end end
        hum.Archivable=true
        local cloned=hum:Clone()
        for _,ch in next,cloned:GetChildren() do if ch:IsA("Animator") then ch:Destroy() end end
        hum.Name="_OldHumanoid"; cloned.Name="Humanoid"; cloned.Parent=char
        Instance.new("Animator",cloned)
        cloned.WalkSpeed=ws; cloned.JumpPower=jp; cloned.JumpHeight=jh; cloned.MaxHealth=mhp; cloned.Health=math.min(hp,mhp)
        if cam then cam.CameraSubject=cloned end
        hum:Destroy()
        if anim and anim:IsA("LocalScript") then
            task.wait()
            if anim.Parent then
                anim.Disabled=false
                task.defer(function()
                    if anim.Parent then anim.Disabled=true; task.wait(); if anim.Parent then anim.Disabled=false end end
                end)
            end
        end
        task.defer(function() if cloned.Parent then cloned:ChangeState(Enum.HumanoidStateType.Running) end end)
    end)
    self.bypassBusy=false
    if ok and LP.Character==char then self.bypassedCharacter=char; Runtime.rootPart=char:FindFirstChild("HumanoidRootPart"); return true end
    return false
end

function DHub.CharacterService:EnsureFastReady(opts)
    opts=opts or {}
    local char,root,hum=ensureCharacter(opts.timeout or 8)
    if not char or not root or not hum or hum.Health<=0 then return false end
    if self.bypassedCharacter==char then return true end
    for _=1,2 do
        if LP.Character~=char or hum.Health<=0 then return false end
        S.RunService.Heartbeat:Wait()
    end
    return self:ApplyBypassOnce(char)
end
function DHub.CharacterService:IsFastReady()
    local char=LP.Character; local hum=getHumanoid()
    return char and hum and hum.Health>0 and self.bypassedCharacter==char or false
end

DHub.CharacterService:_Bind(LP.Character)
DHub.charAddedConn=LP.CharacterAdded:Connect(function(char)
    DHub.CharacterService:_Bind(char)
    task.spawn(function()
        local c,r,h=ensureCharacter(10)
        if c~=char or not r or not h or h.Health<=0 then return end
        if Cfg.autoFarm and not Runtime.farming then
            if Cfg.farmMethod=="Fast" and Runtime.FastFarmStart then
                -- New Fast mode uses the proven Instant-Steal drop/re-carry
                -- engine. It never applies CharacterService speed/humanoid bypass.
                Runtime.FastFarmStart()
            else
                task.spawn(doFarmLoop)
            end
        end
    end)
end)
table.insert(ScriptConnections,DHub.charAddedConn)

local function isCarryingEgg(otherChar)
    local char=otherChar or getChar(); if not char then return false end
    for _,obj in ipairs(char:GetChildren()) do if obj:IsA("Tool") and obj.Name:lower():find("egg") then return true end end
    for _,obj in ipairs(char:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model")) and obj.Parent==char then
            local n=obj.Name:lower()
            if n:find("egg") and not n:find("zone") and not n:find("root") and not n:find("prompt") then return true end
        end
    end
    return char:GetAttribute("CarryingEgg") or char:GetAttribute("IsCarrying") or char:GetAttribute("HoldingEgg") or false
end

local function isPlayerOnTreadmill()
    local root = getRoot()
    if not root then return false end
    local plots = S.Workspace:FindFirstChild("Plots")
    if plots then
        for _, p in ipairs(plots:GetChildren()) do
            local tb = p:FindFirstChild("TreadmillBottom")
            if tb and (root.Position - tb.Position).Magnitude <= 12 then
                return true, tb
            end
        end
    end
    return false
end

local TreadmillReleasePolicy = {
    lastSafezoneReleaseAt = 0,
}

local function releaseTreadmill(reason)
    reason = tostring(reason or "")

    -- HARD RULE:
    -- Automatic treadmill release is valid ONLY when a movement route is
    -- actually starting toward SAFEZONE_POS.
    --
    -- "manual" is reserved for the user's explicit Bypass Release button.
    if reason ~= "safezone"
        and reason ~= "manual"
    then
        return false
    end

    pcall(function()
        local rf =
            S.ReplicatedStorage
                .Packages
                .Networking:
                FindFirstChild(
                    "RF/Treadmill/AskDoff"
                )

        if rf then
            rf:InvokeServer()
        end
    end)

    pcall(function()
        local tc =
            require(
                LP.PlayerScripts
                    .Game
                    .Plots
                    .TreadmillCharacterPresentationController
            )

        if tc
            and tc.Stop
        then
            tc.Stop()
        end
    end)

    if DHub.TreadmillMount then
        DHub.TreadmillMount.active = false
        DHub.TreadmillMount.activeChangedAt = tick()
        DHub.TreadmillMount.busy = false
    end

    -- Release never jumps/launches the player.
    local root = getRoot()
    local hum =
        LP.Character
        and LP.Character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    if root then
        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if hum
        and root
    then
        pcall(function()
            hum:MoveTo(
                root.Position
            )
        end)
    end

    return true
end

local function isSafezoneRouteTarget(
    targetPos
)
    return typeof(targetPos) == "Vector3"
        and (
            targetPos - SAFEZONE_POS
        ).Magnitude <= 18
end

local function releaseTreadmillForSafezoneRoute(
    targetPos
)
    if not isSafezoneRouteTarget(
        targetPos
    )
    then
        return false
    end

    local physicallyOn =
        isPlayerOnTreadmill()
        == true

    local mounted =
        DHub.TreadmillMount
        and DHub.TreadmillMount.active
            == true

    if not physicallyOn
        and not mounted
    then
        return false
    end

    -- Small de-dupe only for multiple Safezone wrappers entering on
    -- adjacent frames. This is NOT a recurring release loop.
    if tick()
        - (
            TreadmillReleasePolicy
                .lastSafezoneReleaseAt
            or 0
        ) < 0.12
    then
        return false
    end

    local released =
        releaseTreadmill(
            "safezone"
        )

    if released then
        TreadmillReleasePolicy
            .lastSafezoneReleaseAt =
            tick()

        task.wait(0.08)
    end

    return released
end

local function forceUnequipTools()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local ok = pcall(function() hum:UnequipTools() end)
    return ok
end

DHub.TreadmillMount = DHub.TreadmillMount or {
    active = false,
    activeChangedAt = 0,
    busy = false,
    lastAttempt = 0,
    lastWearAt = 0,
    failCount = 0,
    connection = nil,
}

function DHub.TreadmillMount:Start()
    if self.connection
        and self.connection.Connected
    then
        return
    end

    local net =
        S.ReplicatedStorage:FindFirstChild("Packages")
        and S.ReplicatedStorage.Packages:FindFirstChild("Networking")

    local shifted =
        net
        and net:FindFirstChild(
            "RE/Treadmill/RenderStateShifted"
        )

    if shifted
        and shifted:IsA("RemoteEvent")
    then
        self.connection =
            shifted.OnClientEvent:Connect(function(a, b)
                local active = nil

                if type(a) == "table"
                    and a.Active ~= nil
                then
                    active = a.Active == true
                elseif type(b) == "table"
                    and b.Active ~= nil
                then
                    active = b.Active == true
                elseif type(a) == "boolean" then
                    active = a
                elseif type(b) == "boolean" then
                    active = b
                end

                if active ~= nil then
                    self.active = active
                    self.activeChangedAt = tick()

                    if active == true then
                        self.busy = false
                        self.failCount = 0
                    end
                end
            end)

        table.insert(
            ScriptConnections,
            self.connection
        )
    end
end

function DHub.TreadmillMount:TryMount()
    local function idleAllowed()
        if DHub.IsIdleTreadmillAllowed then
            local ok, result =
                pcall(
                    DHub.IsIdleTreadmillAllowed
                )

            return ok
                and result == true
        end

        return Cfg.autoTreadmill == true
            and Cfg.autoFarm == true
    end

    if not idleAllowed() then
        return false,
            "not_idle"
    end

    if DHub.EventWavePriority
        and DHub.EventWavePriority:
            ShouldPauseMainFarm()
    then
        return false,
            "wave_priority"
    end

    if isCarryingEgg() then
        return false,
            "carrying"
    end

    if self.active == true then
        return true,
            "already_active"
    end

    if self.busy then
        return self.active == true,
            "busy"
    end

    local root =
        getRoot()

    local hum =
        getHumanoid()

    if not root
        or not hum
        or hum.Health <= 0
    then
        return false,
            "character_not_ready"
    end

    local near,
        treadmillPart =
        isPlayerOnTreadmill()

    if not near
        or not treadmillPart
    then
        self.active = false

        return false,
            "not_near_treadmill"
    end

    local targetPos =
        treadmillPart.Position
        + Vector3.new(
            0,
            2.25,
            0
        )

    local distanceToMount =
        (
            root.Position
            - targetPos
        ).Magnitude

    if distanceToMount > 4.25 then
        pcall(function()
            hum:MoveTo(
                targetPos
            )
        end)

        local alignDeadline =
            tick() + 1.50

        while tick()
            < alignDeadline
        do
            if not idleAllowed()
                or isCarryingEgg()
                or (
                    DHub.EventWavePriority
                    and DHub.EventWavePriority:
                        ShouldPauseMainFarm()
                )
            then
                return false,
                    "alignment_interrupted"
            end

            root =
                getRoot()

            hum =
                getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                return false,
                    "character_lost"
            end

            distanceToMount =
                (
                    root.Position
                    - targetPos
                ).Magnitude

            if distanceToMount <= 4.25 then
                break
            end

            pcall(function()
                hum:MoveTo(
                    targetPos
                )
            end)

            S.RunService.Heartbeat:
                Wait()
        end

        root =
            getRoot()

        if not root
            or (
                root.Position
                - targetPos
            ).Magnitude > 5.25
        then
            return false,
                "not_centered"
        end
    end

    if self.active == true then
        return true,
            "already_active"
    end

    -- Do not hammer AskWearStill every coordinator tick.
    -- More importantly, do NOT AskDoff just because confirmation was late.
    local now =
        tick()

    if now
        - (
            tonumber(
                self.lastAttempt
            ) or 0
        ) < 1.75
    then
        return false,
            "mount_cooldown"
    end

    local net =
        S.ReplicatedStorage:
            FindFirstChild(
                "Packages"
            )
        and S.ReplicatedStorage
            .Packages:
            FindFirstChild(
                "Networking"
            )

    local wear =
        net
        and net:FindFirstChild(
            "RF/Treadmill/AskWearStill"
        )

    if not wear
        or not wear:IsA(
            "RemoteFunction"
        )
    then
        return false,
            "wear_remote_missing"
    end

    self.busy =
        true

    self.lastAttempt =
        now

    local function finish(
        ok,
        reason
    )
        self.busy =
            false

        if ok then
            self.failCount =
                0
        else
            self.failCount =
                (
                    tonumber(
                        self.failCount
                    ) or 0
                ) + 1
        end

        return ok == true,
            reason
    end

    local function stillAllowed()
        if not idleAllowed()
            or isCarryingEgg()
        then
            return false
        end

        if DHub.EventWavePriority
            and DHub.EventWavePriority:
                ShouldPauseMainFarm()
        then
            return false
        end

        local currentRoot =
            getRoot()

        local currentHum =
            getHumanoid()

        if not currentRoot
            or not currentHum
            or currentHum.Health <= 0
        then
            return false
        end

        -- This is only the physical "standing on the belt" check.
        -- Actual mounted state is self.active from RenderStateShifted.
        return isPlayerOnTreadmill()
            == true
    end

    local function waitActive(
        timeout
    )
        local deadline =
            tick()
            + (
                tonumber(
                    timeout
                ) or 2.0
            )

        while stillAllowed()
            and tick() < deadline
        do
            if self.active == true then
                return true
            end

            S.RunService.Heartbeat:
                Wait()
        end

        return self.active == true
    end

    forceUnequipTools()

    pcall(function()
        root.Anchored =
            false

        root.AssemblyLinearVelocity =
            Vector3.zero

        root.AssemblyAngularVelocity =
            Vector3.zero

        hum:MoveTo(
            root.Position
        )
    end)

    -- Proven stable behavior:
    -- retry AskWearStill, but NEVER AskDoff / Stop presentation between
    -- retries while we are merely waiting with no actionable job.
    for attempt = 1, 3 do
        if not stillAllowed() then
            return finish(
                false,
                "interrupted"
            )
        end

        self.lastWearAt =
            tick()

        self.lastAttempt =
            self.lastWearAt

        local ok,
            result =
            pcall(function()
                return wear:
                    InvokeServer()
            end)

        if waitActive(
            2.0
        ) then
            return finish(
                true,
                "render_state_confirmed"
            )
        end

        -- Some builds directly return an accepted/active result.
        local remoteAccepted =
            ok
            and (
                result == true
                or (
                    type(result)
                        == "table"
                    and (
                        result.Success == true
                        or result.Ok == true
                        or result.Active == true
                    )
                )
            )

        if remoteAccepted then
            self.active =
                true

            self.activeChangedAt =
                tick()

            return finish(
                true,
                "remote_confirmed"
            )
        end

        if not stillAllowed() then
            return finish(
                false,
                "interrupted"
            )
        end

        if attempt < 3 then
            task.wait(
                0.10
            )
        end
    end

    -- IMPORTANT:
    -- No releaseTreadmill(), no AskDoff(), no controller.Stop() here.
    -- Stay physically on the belt and let a later idle health attempt retry.
    return finish(
        false,
        "render_state_timeout"
    )
end

DHub.TreadmillMount:Start()

local function _walkShouldContinue(shouldContinue)
    if shouldContinue then
        local ok, result = pcall(shouldContinue)
        return ok and result == true
    end
    return Cfg.autoFarm
        or PlotCfg.autoPlace
        or EventCfg.autoWave
        or EventCfg.autoDoubleBat
end

local function _stopHumanoidAtCurrentPosition(humanoid, rootPart)
    if humanoid and rootPart then
        pcall(function() humanoid:MoveTo(rootPart.Position) end)
    end
end

DHub.PlayerTrapScanner = DHub.PlayerTrapScanner or {
    entries = setmetatable({}, {__mode = "k"}),
    transient = nil,
    lastSweepAt = 0,
    started = false,
}

function DHub.PlayerTrapScanner:_FindTrapAncestor(obj)
    local transient =
        S.Workspace:FindFirstChild("Transient")

    if not transient or not obj then
        return nil
    end

    local p = obj

    while p
        and p ~= transient
        and p ~= S.Workspace
    do
        if p.Name == "PlayerTrap" then
            return p
        end

        p = p.Parent
    end

    if p
        and p ~= transient
        and p.Name == "PlayerTrap"
    then
        return p
    end

    return nil
end

function DHub.PlayerTrapScanner:_BindTrap(trap)
    if not trap
        or not trap.Parent
        or trap.Name ~= "PlayerTrap"
    then
        return
    end

    local hitbox =
        trap:FindFirstChild("Hitbox", true)

    if hitbox
        and hitbox:IsA("BasePart")
        and hitbox.Parent
    then
        self.entries[trap] = hitbox
    else
        self.entries[trap] = nil
    end
end

function DHub.PlayerTrapScanner:Sweep(force)
    local now = tick()

    if not force
        and now - (self.lastSweepAt or 0) < 0.10
    then
        return
    end

    self.lastSweepAt = now

    local transient =
        S.Workspace:FindFirstChild("Transient")

    self.transient = transient

    if not transient then
        table.clear(self.entries)
        return
    end

    local seen = {}

    for _, obj in ipairs(
        transient:GetDescendants()
    ) do
        if obj.Name == "PlayerTrap" then
            self:_BindTrap(obj)
            seen[obj] = true
        end
    end

    for trap, hitbox in pairs(self.entries) do
        if not trap
            or not trap.Parent
            or not hitbox
            or not hitbox.Parent
            or not seen[trap]
        then
            self.entries[trap] = nil
        end
    end
end

function DHub.PlayerTrapScanner:GetLive()
    self:Sweep(false)

    local result = {}

    for trap, hitbox in pairs(self.entries) do
        if trap
            and trap.Parent
            and hitbox
            and hitbox.Parent
        then
            result[#result + 1] = {
                trap = trap,
                hitbox = hitbox,
            }
        end
    end

    return result
end

function DHub.PlayerTrapScanner:Start()
    if self.started then
        return
    end

    self.started = true
    self:Sweep(true)

    local addConn =
        S.Workspace.DescendantAdded:Connect(
            function(obj)
                if obj.Name == "PlayerTrap"
                    or obj.Name == "Hitbox"
                then
                    task.defer(function()
                        self:Sweep(true)
                    end)
                end
            end
        )

    local removeConn =
        S.Workspace.DescendantRemoving:Connect(
            function(obj)
                if obj.Name == "PlayerTrap"
                    or obj.Name == "Hitbox"
                then
                    task.defer(function()
                        self:Sweep(true)
                    end)
                end
            end
        )

    table.insert(ScriptConnections, addConn)
    table.insert(ScriptConnections, removeConn)
end

DHub.PlayerTrapScanner:Start()

DHub.NormalTrapAvoidance = DHub.NormalTrapAvoidance or {
    jumpedAt = setmetatable({}, {__mode = "k"}),
    lastJumpAt = 0,
    speedEMA = 0,
    humanoid = nil,
}

function DHub.NormalTrapAvoidance:_JumpVelocity(humanoid)
    local gravity =
        math.max(
            tonumber(S.Workspace.Gravity) or 196.2,
            1
        )

    local jumpVelocity = 0

    local useJumpPower = true

    pcall(function()
        useJumpPower =
            humanoid.UseJumpPower ~= false
    end)

    if useJumpPower then
        jumpVelocity =
            math.max(
                tonumber(humanoid.JumpPower) or 50,
                1
            )
    else
        local jumpHeight =
            math.max(
                tonumber(humanoid.JumpHeight) or 7.2,
                0.1
            )

        jumpVelocity =
            math.sqrt(
                2
                * gravity
                * jumpHeight
            )
    end

    return jumpVelocity, gravity
end

function DHub.NormalTrapAvoidance:_RunningSpeed(
    root,
    humanoid
)
    if self.humanoid ~= humanoid then
        self.humanoid = humanoid
        self.speedEMA = 0
    end

    local velocity =
        root.AssemblyLinearVelocity

    local actualSpeed =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        ).Magnitude

    local nativeWalkSpeed =
        math.max(
            tonumber(humanoid.WalkSpeed) or 16,
            1
        )

    local sample =
        math.max(
            actualSpeed,
            nativeWalkSpeed * 0.85
        )

    if (self.speedEMA or 0) <= 0 then
        self.speedEMA = sample
    else
        self.speedEMA =
            self.speedEMA * 0.72
            + sample * 0.28
    end

    return math.max(
        self.speedEMA,
        1
    )
end

function DHub.NormalTrapAvoidance:_MoveDirection(
    root,
    moveGoal
)
    local velocity =
        root.AssemblyLinearVelocity

    local flatVelocity =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )

    -- Once already running, actual movement direction is more accurate
    -- than a Pathfinding waypoint or the original destination.
    if flatVelocity.Magnitude >= 2.0 then
        return flatVelocity.Unit
    end

    if typeof(moveGoal) ~= "Vector3" then
        return nil
    end

    local delta =
        Vector3.new(
            moveGoal.X - root.Position.X,
            0,
            moveGoal.Z - root.Position.Z
        )

    if delta.Magnitude < 0.25 then
        return nil
    end

    return delta.Unit
end

function DHub.NormalTrapAvoidance:GetThreat(
    root,
    humanoid,
    moveGoal
)
    if not root
        or not humanoid
        or humanoid.Health <= 0
    then
        return nil
    end

    local direction =
        self:_MoveDirection(
            root,
            moveGoal
        )

    if not direction then
        return nil
    end

    local speed =
        self:_RunningSpeed(
            root,
            humanoid
        )

    local jumpVelocity, gravity =
        self:_JumpVelocity(humanoid)

    -- Full theoretical airtime at the current game's jump physics.
    local airTime =
        math.max(
            (2 * jumpVelocity) / gravity,
            0.20
        )

    local airDistance =
        speed * airTime

    local side =
        Vector3.new(
            -direction.Z,
            0,
            direction.X
        )

    local characterFront =
        math.max(
            tonumber(root.Size.Z) * 0.5,
            1.25
        )

    local lanePadding =
        math.max(
            tonumber(root.Size.X) * 0.5,
            1.25
        )
        + 0.85

    local footY =
        root.Position.Y
        - math.max(
            root.Size.Y * 0.5 + 1.7,
            2.7
        )

    local best = nil
    local bestContactDistance = math.huge

    for _, entry in ipairs(
        DHub.PlayerTrapScanner:GetLive()
    ) do
        local trap = entry.trap
        local hitbox = entry.hitbox

        if trap
            and trap.Parent
            and hitbox
            and hitbox.Parent
        then
            local trapTop =
                hitbox.Position.Y
                + hitbox.Size.Y * 0.5

            -- "Floor scanner": ignore traps that are on another height/floor.
            local sameFloor =
                math.abs(
                    trapTop - footY
                ) <= 5.0

            if sameFloor then
                local delta =
                    Vector3.new(
                        hitbox.Position.X
                            - root.Position.X,
                        0,
                        hitbox.Position.Z
                            - root.Position.Z
                    )

                local along =
                    delta:Dot(direction)

                local lateral =
                    math.abs(
                        delta:Dot(side)
                    )

                local halfAlong =
                    math.abs(direction.X)
                        * hitbox.Size.X * 0.5
                    + math.abs(direction.Z)
                        * hitbox.Size.Z * 0.5

                local halfAcross =
                    math.abs(side.X)
                        * hitbox.Size.X * 0.5
                    + math.abs(side.Z)
                        * hitbox.Size.Z * 0.5

                -- Distance from the FRONT of our character to the NEAR edge
                -- of the trap. Positive means we have NOT touched it yet.
                local contactDistance =
                    along
                    - halfAlong
                    - characterFront

                local trapTravelLength =
                    halfAlong * 2
                    + characterFront * 2

                if along > 0
                    and lateral
                        <= halfAcross + lanePadding
                then
                    -- We must land AFTER the far edge. This gives the maximum
                    -- legal early-jump distance for the current run speed.
                    local landingReserve =
                        math.clamp(
                            1.25 + speed * 0.035,
                            1.5,
                            4.0
                        )

                    local maxTakeoffLead =
                        airDistance
                        - trapTravelLength
                        - landingReserve

                    -- Input/state reaction + enough rise before feet reach
                    -- the Hitbox. Faster run = farther takeoff point.
                    local desiredTakeoffLead =
                        speed * 0.22
                        + math.clamp(
                            speed * 0.055,
                            1.25,
                            3.75
                        )

                    local takeoffLead

                    if maxTakeoffLead >= 1.35 then
                        takeoffLead =
                            math.clamp(
                                desiredTakeoffLead,
                                1.35,
                                maxTakeoffLead
                            )
                    else
                        -- At very low speed / huge trap the stock jump arc
                        -- cannot mathematically span the whole trap. Still
                        -- choose the latest safe pre-contact takeoff point,
                        -- never an after-contact jump.
                        takeoffLead =
                            math.clamp(
                                math.max(
                                    maxTakeoffLead,
                                    1.10
                                ),
                                1.10,
                                3.25
                            )
                    end

                    -- Important: NEVER trigger once contactDistance <= 0.
                    -- This removes the old "hit trap first, jump afterwards"
                    -- behaviour completely.
                    if contactDistance > 0.35
                        and contactDistance
                            <= takeoffLead
                        and contactDistance
                            < bestContactDistance
                    then
                        bestContactDistance =
                            contactDistance

                        best = {
                            trap = trap,
                            hitbox = hitbox,
                            speed = speed,
                            airTime = airTime,
                            airDistance = airDistance,
                            contactDistance =
                                contactDistance,
                            takeoffLead =
                                takeoffLead,
                            maxTakeoffLead =
                                maxTakeoffLead,
                            trapTravelLength =
                                trapTravelLength,
                        }
                    end
                end
            end
        end
    end

    return best
end

function DHub.NormalTrapAvoidance:Step(
    root,
    humanoid,
    moveGoal
)
    if not root
        or not humanoid
        or humanoid.Health <= 0
    then
        return false
    end

    local threat =
        self:GetThreat(
            root,
            humanoid,
            moveGoal
        )

    if not threat then
        return false
    end

    local now = tick()

    local lastForTrap =
        tonumber(
            self.jumpedAt[threat.trap]
        ) or 0

    -- One jump per trap/pass. The old short cooldown could make the
    -- character bunny-hop again while already crossing the same trap.
    if now - lastForTrap < 2.25
        or now - (self.lastJumpAt or 0) < 0.28
    then
        return false
    end

    if humanoid.FloorMaterial
        == Enum.Material.Air
    then
        return false
    end

    self.jumpedAt[threat.trap] = now
    self.lastJumpAt = now

    Runtime.lastTrapJump = {
        at = now,
        speed = threat.speed,
        distance = threat.contactDistance,
        lead = threat.takeoffLead,
        airDistance = threat.airDistance,
    }

    pcall(function()
        humanoid.Jump = true

        humanoid:ChangeState(
            Enum.HumanoidStateType.Jumping
        )
    end)

    -- Some client frames can consume Jump=true while MoveTo is being
    -- refreshed. Re-assert once on the next heartbeat only if still grounded.
    task.defer(function()
        S.RunService.Heartbeat:Wait()

        if humanoid
            and humanoid.Parent
            and humanoid.Health > 0
            and humanoid.FloorMaterial
                ~= Enum.Material.Air
        then
            pcall(function()
                humanoid.Jump = true

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Jumping
                )
            end)
        end
    end)

    return true
end

local function WalkToTarget(targetPos, stopDistance, keepUnequipped, shouldContinue, walkOptions)
    stopDistance = stopDistance or 4
    keepUnequipped = keepUnequipped == true
    walkOptions = type(walkOptions) == "table" and walkOptions or nil
    Runtime.isAutoWalking = true

    local char, rootPart, humanoid = ensureCharacter(5)
    if not char or not rootPart or not humanoid then
        Runtime.isAutoWalking = false
        return false
    end

    local lastUnequip = 0

    local function cleanup(success)
        local currentRoot = getRoot()
        local currentHum = getHumanoid()
        _stopHumanoidAtCurrentPosition(currentHum, currentRoot)

        if keepUnequipped then forceUnequipTools() end

        Runtime.isAutoWalking = false
        return success == true
    end

    local function alive()
        if not _walkShouldContinue(shouldContinue) then return false end
        local c = getChar()
        local r = getRoot()
        local h = getHumanoid()
        return c ~= nil and r ~= nil and h ~= nil and h.Health > 0
    end

    local function refreshCharacter()
        char = getChar()
        rootPart = getRoot()
        humanoid = getHumanoid()
        return char and rootPart and humanoid and humanoid.Health > 0
    end

    local function maintainUnequip()
        -- If this is a Safezone route and the character becomes attached to
        -- the treadmill while already walking, release it here. For every
        -- non-Safezone destination this helper is a strict no-op.
        releaseTreadmillForSafezoneRoute(
            targetPos
        )

        if keepUnequipped and (tick() - lastUnequip >= 0.10) then
            forceUnequipTools()
            lastUnequip = tick()
        end
    end

    local function trapAvoidanceStep(moveGoal)
        if walkOptions
            and walkOptions.avoidPlayerTraps == true
            and Cfg.farmMethod ~= "Fast"
            and rootPart
            and humanoid
        then
            DHub.NormalTrapAvoidance:Step(
                rootPart,
                humanoid,
                targetPos
            )
        end
    end

    local function nativeSpeed()
        local h = humanoid or getHumanoid()
        return math.max(
            tonumber(h and h.WalkSpeed) or 16,
            1
        )
    end

    if keepUnequipped then forceUnequipTools(); lastUnequip = tick() end

    -- Treadmill release is centralized here ONLY when this route is
    -- actually heading to SAFEZONE_POS. Walking to an egg, plot, treadmill,
    -- fuse object, etc. never releases the treadmill by itself.
    if releaseTreadmillForSafezoneRoute(
        targetPos
    )
    then
        refreshCharacter()
    end

    local initialDistance = (rootPart.Position - targetPos).Magnitude

    if initialDistance < 100 then
        humanoid:MoveTo(targetPos)
        local startTime = tick()
        local lastRefresh = 0
        local timeout = math.max(10, (initialDistance / nativeSpeed()) * 3 + 3)

        while tick() - startTime < timeout do
            if not alive() then return cleanup(false) end
            if not refreshCharacter() then return cleanup(false) end
            maintainUnequip()
            trapAvoidanceStep(targetPos)

            local distance = (rootPart.Position - targetPos).Magnitude
            if distance <= stopDistance then return cleanup(true) end

            if tick() - lastRefresh >= 0.20 then
                humanoid:MoveTo(targetPos)
                lastRefresh = tick()
            end
            task.wait(0.03)
        end
        return cleanup((getRoot() and (getRoot().Position - targetPos).Magnitude <= stopDistance) or false)
    end

    local path = S.PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 20,
    })

    local pathOK = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)

    if not pathOK or path.Status ~= Enum.PathStatus.Success then
        local startTime = tick()
        local timeout = math.max(15, (initialDistance / nativeSpeed()) * 3 + 5)
        humanoid:MoveTo(targetPos)

        while tick() - startTime < timeout do
            if not alive() then return cleanup(false) end
            if not refreshCharacter() then return cleanup(false) end
            maintainUnequip()
            trapAvoidanceStep(targetPos)

            local distance = (rootPart.Position - targetPos).Magnitude
            if distance <= stopDistance then return cleanup(true) end

            humanoid:MoveTo(targetPos)
            task.wait(0.05)
        end
        return cleanup((getRoot() and (getRoot().Position - targetPos).Magnitude <= stopDistance) or false)
    end

    local waypoints = path:GetWaypoints()
    if #waypoints == 0 then return cleanup(false) end

    local currentWaypointIndex = 1
    local nextWaypointThreshold = 8

    while currentWaypointIndex <= #waypoints do
        if not alive() then return cleanup(false) end
        if not refreshCharacter() then return cleanup(false) end

        local waypoint = waypoints[currentWaypointIndex]
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            pcall(function() humanoid.Jump = true end)
        end
        humanoid:MoveTo(waypoint.Position)

        local waypointStart = tick()
        local advanced = false

        while tick() - waypointStart < 3 do
            if not alive() then return cleanup(false) end
            if not refreshCharacter() then return cleanup(false) end
            maintainUnequip()
            trapAvoidanceStep(waypoint.Position)

            local distToWaypoint = (rootPart.Position - waypoint.Position).Magnitude
            local distToTarget = (rootPart.Position - targetPos).Magnitude

            if distToTarget <= stopDistance then return cleanup(true) end

            if distToWaypoint <= nextWaypointThreshold then
                advanced = true
                currentWaypointIndex = currentWaypointIndex + 1
                if currentWaypointIndex <= #waypoints then
                    local nextWaypoint = waypoints[currentWaypointIndex]
                    if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
                        pcall(function() humanoid.Jump = true end)
                    end
                    humanoid:MoveTo(nextWaypoint.Position)
                end
                break
            end
            humanoid:MoveTo(waypoint.Position)
            task.wait(0.02)
        end

        if not advanced then
            currentWaypointIndex = currentWaypointIndex + 1
            if currentWaypointIndex <= #waypoints then
                local nextWaypoint = waypoints[currentWaypointIndex]
                if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
                    pcall(function() humanoid.Jump = true end)
                end
                humanoid:MoveTo(nextWaypoint.Position)
            end
        end
    end

    local finalStart = tick()
    while tick() - finalStart < 5 do
        if not alive() then return cleanup(false) end
        if not refreshCharacter() then return cleanup(false) end
        maintainUnequip()
        trapAvoidanceStep(targetPos)

        local distance = (rootPart.Position - targetPos).Magnitude
        if distance <= stopDistance then return cleanup(true) end

        humanoid:MoveTo(targetPos)
        task.wait(0.03)
    end

    local finalRoot = getRoot()
    return cleanup(finalRoot and (finalRoot.Position - targetPos).Magnitude <= stopDistance)
end

DHub.MovementService={
    sequence=0,currentOwner=nil,currentPriority=-math.huge,
    Priorities={Event=80,Fuse=70,MainFarm=50,Plot=40,IdleTreadmill=10},
}
function DHub.MovementService:_Begin(owner,priority)
    owner=tostring(owner or "MainFarm"); priority=tonumber(priority) or self.Priorities[owner] or 0
    if self.currentOwner and self.currentOwner~=owner and priority<self.currentPriority then return nil end
    self.sequence=self.sequence+1; self.currentOwner=owner; self.currentPriority=priority
    return {owner=owner,id=self.sequence}
end
function DHub.MovementService:_Owns(t) return t and self.currentOwner==t.owner and self.sequence==t.id end
function DHub.MovementService:_End(t) if self:_Owns(t) then self.currentOwner=nil; self.currentPriority=-math.huge; Runtime.isAutoWalking=false end end
function DHub.MovementService:_Resolve(p)
    if typeof(p)=="Vector3" then return p end
    if type(p)=="function" then local ok,v=pcall(p); if ok and typeof(v)=="Vector3" then return v end end
    return nil
end
function DHub.MovementService:Cancel(owner)
    if not owner or self.currentOwner==owner then
        self.sequence=self.sequence+1
        self.currentOwner=nil
        self.currentPriority=-math.huge
        Runtime.isAutoWalking=false
    end
end
function DHub.MovementService:_Velocity(root)
    local old=root:FindFirstChild("_DHubV25FastVelocity"); if old then pcall(function() old:Destroy() end) end
    local bv=Instance.new("BodyVelocity"); bv.Name="_DHubV25FastVelocity"; bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.P=25000; bv.Velocity=Vector3.zero; bv.Parent=root
    return bv
end
function DHub.MovementService:MoveFast(provider,opts)
    opts=opts or {}; local owner=opts.owner or "MainFarm"; local token=self:_Begin(owner,opts.priority or self.Priorities[owner] or 0)
    if not token then return false end
    Runtime.isAutoWalking=true

    local initialTarget =
        self:_Resolve(provider)

    if initialTarget then
        releaseTreadmillForSafezoneRoute(
            initialTarget
        )
    end

    if opts.requireBypass~=false then
        if not DHub.CharacterService:EnsureFastReady({timeout=8}) then
            self:_End(token)
            return false
        end
    end
    local char,root,hum=ensureCharacter(5); if not char or not root or not hum then self:_End(token); return false end
    if opts.keepUnequipped then forceUnequipTools() end
    root.Anchored=false
    local bv=self:_Velocity(root); local stop=tonumber(opts.stopDistance) or 4; local speed=tonumber(opts.speed) or tonumber(Cfg.walkSpeed) or 35
    local deadline=tick()+(tonumber(opts.timeout) or 35); local lastUnequip=0
    local function alive()
        if not self:_Owns(token) then return false end
        if type(opts.shouldContinue)=="function" then local ok,v=pcall(opts.shouldContinue); if not ok or v~=true then return false end end
        local h=getHumanoid(); return LP.Character~=nil and h~=nil and h.Health>0
    end
    while alive() and tick()<deadline do
        local liveTarget =
            self:_Resolve(provider)

        if liveTarget then
            releaseTreadmillForSafezoneRoute(
                liveTarget
            )
        end

        char=LP.Character; root=getRoot(); hum=getHumanoid(); if not char or not root or not hum or hum.Health<=0 then break end
        if bv.Parent~=root then pcall(function() bv:Destroy() end); bv=self:_Velocity(root) end
        if opts.keepUnequipped and tick()-lastUnequip>=0.10 then forceUnequipTools(); lastUnequip=tick() end
        local target=self:_Resolve(provider); if not target then break end
        local d=target-root.Position; local dist=d.Magnitude
        if dist<=stop then
            bv.Velocity=Vector3.zero
            pcall(function() root.Anchored=false; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end)

            pcall(function() bv:Destroy() end)

            if opts.keepUnequipped then forceUnequipTools() end
            self:_End(token)
            return true
        end
        local vmax=math.max(1,speed)*10; local wanted=math.min(vmax,math.max(28,dist*7)); bv.Velocity=d.Unit*wanted
        pcall(function() root.Anchored=false; root.AssemblyAngularVelocity=Vector3.zero end)
        S.RunService.Heartbeat:Wait()
    end
    pcall(function() if bv then bv.Velocity=Vector3.zero; bv:Destroy() end end)
    local r=getRoot(); if r then pcall(function() r.Anchored=false; r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero end) end
    self:_End(token); return false
end
function DHub.MovementService:Move(provider,opts)
    opts=opts or {}

    -- V3 Fast Farm is NOT the old BodyVelocity/Character bypass mode.
    -- Non-egg systems always keep native walking even when Select Method=Fast.
    return WalkToTarget(
        self:_Resolve(provider),
        opts.stopDistance,
        opts.keepUnequipped,
        opts.shouldContinue,
        opts.walkOptions
    )
end

local WalkSpeedRuntime = {
    humanoid = nil,
    originalSpeed = nil,
    wasActive = false,
    lastEnforceAt = 0,
}

-- New Fast mode intentionally does not modify Humanoid.WalkSpeed.
-- The old speed-enforcer is retained only as a compatibility no-op.
local function anyFarmEngineActive()
    return false
end

local function applyConfiguredWalkSpeedNow()
    return
end

local UltraFpsState = {
    enabled = false,
    purged = false,
    conn = nil,
    charConns = {},
    protectedFolder = nil,
    floor = nil,
}

local function applyUltraFps(enabled)
    local U = UltraFpsState
    U.enabled = enabled == true

    local W = S.Workspace
    local DARK =
        BrickColor.new("Dark stone grey").Color

    local function disconnectAll()
        if U.conn then
            pcall(function()
                U.conn:Disconnect()
            end)
            U.conn = nil
        end

        for _,conn in ipairs(U.charConns) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        table.clear(U.charConns)
    end

    if not U.enabled then
        disconnectAll()

        pcall(function()
            if Notify then
                if U.purged then
                    Notify(
                        "Ultra FPS OFF: rejoin required to restore deleted map",
                        4
                    )
                else
                    Notify(
                        "Ultra FPS disabled",
                        2
                    )
                end
            end
        end)

        return
    end

    if U.purged then
        if not U.conn then
            U.enabled = true
        end
    end

    local protected =
        W:FindFirstChild("DHubUltraFPS_Protected")

    if not protected then
        protected = Instance.new("Folder")
        protected.Name = "DHubUltraFPS_Protected"
        protected.Parent = W
    end

    U.protectedFolder = protected

    local function ensureClientFloor()
        local oldSingle =
            protected:FindFirstChild(
                "DHub_ClientFloor"
            )

        if oldSingle then
            pcall(function()
                oldSingle:Destroy()
            end)
        end

        local group =
            protected:FindFirstChild(
                "DHub_ClientFloorGroup"
            )

        if not group
            or not group:IsA("Folder")
        then
            if group then
                pcall(function()
                    group:Destroy()
                end)
            end

            group = Instance.new("Folder")
            group.Name =
                "DHub_ClientFloorGroup"
            group.Parent = protected
        end

        local TILE_SIZE_X = 1800
        local TILE_SIZE_Z = 1800
        local TILE_Y = 65.6
        local TILE_THICKNESS = 4

        local centers = {
            Vector3.new(900,  TILE_Y, -364),
            Vector3.new(2700, TILE_Y, -364),
            Vector3.new(4500, TILE_Y, -364),
            Vector3.new(6300, TILE_Y, -364),
        }

        local aliveNames = {}

        for index,pos in ipairs(centers) do
            local name =
                "DHub_FloorTile_"
                .. tostring(index)

            aliveNames[name] = true

            local tile =
                group:FindFirstChild(name)

            if not tile
                or not tile:IsA("BasePart")
            then
                if tile then
                    pcall(function()
                        tile:Destroy()
                    end)
                end

                tile = Instance.new("Part")
                tile.Name = name
                tile.Parent = group
            end

            tile.Anchored = true
            tile.CanCollide = true
            tile.CanTouch = true
            tile.CanQuery = true

            tile.Size = Vector3.new(
                TILE_SIZE_X,
                TILE_THICKNESS,
                TILE_SIZE_Z
            )

            tile.Position = pos

            tile.Material =
                Enum.Material.SmoothPlastic

            tile.Color =
                BrickColor.new(
                    "Dark stone grey"
                ).Color

            tile.Transparency = 0
            tile.LocalTransparencyModifier = 0
            tile.CastShadow = false

            tile.TopSurface =
                Enum.SurfaceType.Smooth

            tile.BottomSurface =
                Enum.SurfaceType.Smooth

            tile:SetAttribute(
                "DHubUltraFPSProtected",
                true
            )

            tile:SetAttribute(
                "DHubFloorTopY",
                67.6
            )
        end

        for _,child in ipairs(
            group:GetChildren()
        ) do
            if child:IsA("BasePart")
                and not aliveNames[child.Name]
            then
                pcall(function()
                    child:Destroy()
                end)
            end
        end

        group:SetAttribute(
            "DHubFloorTileCount",
            #centers
        )

        group:SetAttribute(
            "DHubFloorCoverage",
            "X=0..7200 Z=-1264..536 TopY=67.6"
        )

        U.floor = group
        return group
    end

    local floor = ensureClientFloor()

    local function isPlayerCharacterDescendant(obj)
        local p = obj

        while p and p ~= W do
            if p:IsA("Model") then
                local plr =
                    S.Players:GetPlayerFromCharacter(p)

                if plr then
                    return true
                end
            end

            p = p.Parent
        end

        return false
    end

    local function ancestorNameContains(obj, needle)
        needle = string.lower(needle)

        local p = obj
        while p and p ~= W do
            if string.find(
                string.lower(p.Name),
                needle,
                1,
                true
            ) then
                return true
            end

            p = p.Parent
        end

        return false
    end

    local function getGuardAreas()
        local objects =
            W:FindFirstChild("__OBJECTS")

        local areas =
            objects
            and objects:FindFirstChild("Areas")

        return areas
            and areas:FindFirstChild("GuardAreas")
            or nil
    end

    local function isGuardAreasDescendant(obj)
        if not obj then return false end

        local guardAreas =
            getGuardAreas()

        return guardAreas
            and (
                obj == guardAreas
                or obj:IsDescendantOf(guardAreas)
            )
            or false
    end

    local function isGuardAreaFunctionalPart(part)
        if not part
            or not part:IsA("BasePart")
            or not isGuardAreasDescendant(part)
        then
            return false
        end

        local n = part.Name

        return n == "Bounds"
            or n == "ClosestExitPoint"
            or n == "Collider"
            or n == "HumanoidRootPart"
            or n == "CENTER"
            or n == "EggPoint"
            or n == "Root"
            or n == "EggSpotBottom"
            or n == "EggFitBounds"
    end

    local protectedPromptHosts =
        setmetatable({}, {__mode = "k"})

    local function markPromptHostPart(part)
        if not part
            or not part:IsA("BasePart")
        then
            return
        end

        protectedPromptHosts[part] = true

        pcall(function()
            part:SetAttribute(
                "DHubPromptHostProtected",
                true
            )
        end)
    end

    local function protectPromptHost(prompt)
        if not prompt
            or not prompt:IsA("ProximityPrompt")
        then
            return 0
        end

        local marked = 0
        local parent = prompt.Parent

        if parent and parent:IsA("BasePart") then
            markPromptHostPart(parent)
            marked = marked + 1
            return marked
        end

        if parent and parent:IsA("Attachment") then
            local host = parent.Parent

            if host and host:IsA("BasePart") then
                markPromptHostPart(host)
                marked = marked + 1
                return marked
            end
        end

        if parent and parent:IsA("Model") then
            for _,desc in ipairs(
                parent:GetDescendants()
            ) do
                if desc:IsA("BasePart") then
                    markPromptHostPart(desc)
                    marked = marked + 1
                end
            end

            return marked
        end

        local p = parent

        while p and p ~= W do
            if p:IsA("BasePart") then
                markPromptHostPart(p)
                marked = marked + 1
                break
            end

            p = p.Parent
        end

        return marked
    end

    local function preProtectAllPromptHosts()
        local promptCount = 0
        local hostCountBefore = 0

        for _ in pairs(protectedPromptHosts) do
            hostCountBefore = hostCountBefore + 1
        end

        for _,obj in ipairs(
            W:GetDescendants()
        ) do
            if obj:IsA("ProximityPrompt") then
                promptCount = promptCount + 1
                protectPromptHost(obj)
            end
        end

        local hostCountAfter = 0

        for _ in pairs(protectedPromptHosts) do
            hostCountAfter = hostCountAfter + 1
        end

        if U.protectedFolder then
            pcall(function()
                U.protectedFolder:SetAttribute(
                    "PromptCountBeforePurge",
                    promptCount
                )

                U.protectedFolder:SetAttribute(
                    "ProtectedPromptHostCount",
                    hostCountAfter
                )
            end)
        end

        return promptCount,
            math.max(
                0,
                hostCountAfter - hostCountBefore
            )
    end

    local function isPromptHostPart(part)
        if not part
            or not part:IsA("BasePart")
        then
            return false
        end

        if protectedPromptHosts[part] then
            return true
        end

        if part.Name == "SmartPromptPart" then
            markPromptHostPart(part)
            return true
        end

        local attr = nil
        pcall(function()
            attr =
                part:GetAttribute(
                    "DHubPromptHostProtected"
                )
        end)

        if attr == true then
            protectedPromptHosts[part] = true
            return true
        end

        if part:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        ) then
            markPromptHostPart(part)
            return true
        end

        local model =
            part:FindFirstAncestorOfClass(
                "Model"
            )

        if model
            and model:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )
        then
            markPromptHostPart(part)
            return true
        end

        return false
    end

    local function isProtectedRootDescendant(obj)
        if not obj then return false end

        if protected
            and (
                obj == protected
                or obj:IsDescendantOf(protected)
            )
        then
            return true
        end

        if isGuardAreasDescendant(obj) then
            return true
        end

        local areaEggs =
            W:FindFirstChild("AreaEggSlotsClient")

        if areaEggs
            and (
                obj == areaEggs
                or obj:IsDescendantOf(areaEggs)
            )
        then
            return true
        end

        local placedEggs =
            W:FindFirstChild("PlacedEggRenders")

        if placedEggs
            and (
                obj == placedEggs
                or obj:IsDescendantOf(placedEggs)
            )
        then
            return true
        end

        if isPlayerCharacterDescendant(obj) then
            return true
        end

        return false
    end

    local function isTreadmillDescendant(obj)
        if not obj then return false end

        if obj.Name == "TreadmillBottom"
            or obj.Name == "TreadmillUpgrade"
        then
            return true
        end

        return ancestorNameContains(
            obj,
            "treadmill"
        )
    end

    local function isPlotEngineAnchor(obj)
        if not obj then return false end

        local plots = W:FindFirstChild("Plots")
        if not plots
            or not obj:IsDescendantOf(plots)
        then
            return false
        end

        if obj.Name == "PlotSign"
            or ancestorNameContains(obj, "plotsign")
        then
            return true
        end

        if obj.Name == "PetArea"
            or obj.Name == "CenterPoint"
            or obj.Name == "SpawnPoint"
        then
            return true
        end

        if ancestorNameContains(obj, "toupdate") then
            return true
        end

        return false
    end

    local function shouldKeepBasePart(part)
        if not part
            or not part:IsA("BasePart")
        then
            return false
        end

        if isProtectedRootDescendant(part) then
            return true
        end

        if isPromptHostPart(part) then
            return true
        end

        if isGuardAreasDescendant(part) then
            return true
        end

        if isTreadmillDescendant(part) then
            return true
        end

        if isPlotEngineAnchor(part) then
            return true
        end

        return false
    end

    local function grayPart(part)
        if not part
            or not part:IsA("BasePart")
            or not part.Parent
        then
            return
        end

        pcall(function()
            part.Color = DARK
            part.Material =
                Enum.Material.SmoothPlastic
            part.MaterialVariant = ""
            part.Reflectance = 0
            part.CastShadow = false

            if part:IsA("MeshPart") then
                part.TextureID = ""
            end
        end)
    end

    local function hidePlotAnchor(part)
        if not part
            or not part:IsA("BasePart")
        then
            return
        end

        pcall(function()
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
            part.CastShadow = false
        end)
    end

    local function processProtectedObject(obj)
        if not U.enabled
            or not obj
            or not obj.Parent
        then
            return
        end

        if obj:IsA("BasePart") then
            if isGuardAreasDescendant(obj) then
                if isGuardAreaFunctionalPart(obj) then
                    pcall(function()
                        obj.CastShadow = false
                    end)
                else
                    pcall(function()
                        obj.LocalTransparencyModifier = 1
                        obj.CastShadow = false
                    end)
                end
            elseif isPlotEngineAnchor(obj)
                and not isTreadmillDescendant(obj)
            then
                hidePlotAnchor(obj)
            else
                grayPart(obj)
            end

            return
        end

        if obj:IsA("Decal")
            or obj:IsA("Texture")
        then
            pcall(function()
                obj.Transparency = 1
            end)
            return
        end

        if obj:IsA("SpecialMesh") then
            pcall(function()
                obj.TextureId = ""
            end)
            return
        end

        if obj:IsA("SurfaceAppearance") then
            pcall(function()
                obj:Destroy()
            end)
            return
        end

        if obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Smoke")
            or obj:IsA("Fire")
            or obj:IsA("Sparkles")
            or obj:IsA("PointLight")
            or obj:IsA("SpotLight")
            or obj:IsA("SurfaceLight")
            or obj:IsA("Highlight")
        then
            pcall(function()
                obj.Enabled = false
            end)
            return
        end

        if obj:IsA("Beam") then
            local keepBeam =
                LP.Character
                and obj:IsDescendantOf(LP.Character)

            if not keepBeam then
                pcall(function()
                    obj.Enabled = false
                end)
            end
            return
        end
    end

    local function processProtectedTree(root)
        if not root or not root.Parent then
            return
        end

        processProtectedObject(root)

        for _,obj in ipairs(root:GetDescendants()) do
            processProtectedObject(obj)
        end
    end


    objects =
        W:FindFirstChild("__OBJECTS")

    local terrain =
        W:FindFirstChildOfClass("Terrain")

    if terrain then
        pcall(function()
            terrain:Clear()
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end)
    end

    local promptCountBeforePurge,
        newlyProtectedPromptHosts =
            preProtectAllPromptHosts()

    local promptProtectConn =
        W.DescendantAdded:Connect(function(obj)
            if U.enabled
                and obj
                and obj:IsA("ProximityPrompt")
            then
                protectPromptHost(obj)

                pcall(function()
                    if Cfg.instantSteal then
                        obj.HoldDuration = 0
                    end
                end)
            end
        end)

    U.charConns[#U.charConns + 1] =
        promptProtectConn

    table.insert(
        ScriptConnections,
        promptProtectConn
    )

    local all =
        W:GetDescendants()

    for i = #all, 1, -1 do
        local obj = all[i]

        if obj
            and obj.Parent
        then
            if obj:IsA("BasePart") then
                if shouldKeepBasePart(obj) then
                    processProtectedObject(obj)
                else
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            elseif obj:IsA("SurfaceAppearance") then
                if isProtectedRootDescendant(obj)
                    or isTreadmillDescendant(obj)
                    or isPlotEngineAnchor(obj)
                then
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            elseif obj:IsA("Decal")
                or obj:IsA("Texture")
                or obj:IsA("SpecialMesh")
                or obj:IsA("ParticleEmitter")
                or obj:IsA("Trail")
                or obj:IsA("Smoke")
                or obj:IsA("Fire")
                or obj:IsA("Sparkles")
                or obj:IsA("Beam")
                or obj:IsA("PointLight")
                or obj:IsA("SpotLight")
                or obj:IsA("SurfaceLight")
                or obj:IsA("Highlight")
            then
                if isProtectedRootDescendant(obj)
                    or isTreadmillDescendant(obj)
                    or isPlotEngineAnchor(obj)
                then
                    processProtectedObject(obj)
                else
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            end
        end
    end

    floor = ensureClientFloor()

    for _,obj in ipairs(W:GetDescendants()) do
        if obj:IsA("BasePart")
            and shouldKeepBasePart(obj)
        then
            processProtectedObject(obj)
        end
    end

    pcall(function()
        S.Lighting.GlobalShadows = false
        S.Lighting.EnvironmentDiffuseScale = 0
        S.Lighting.EnvironmentSpecularScale = 0
        S.Lighting.Ambient = DARK
        S.Lighting.OutdoorAmbient = DARK
        S.Lighting.Brightness = 1
    end)

    for _,obj in ipairs(
        S.Lighting:GetDescendants()
    ) do
        if obj:IsA("BloomEffect")
            or obj:IsA("BlurEffect")
            or obj:IsA("ColorCorrectionEffect")
            or obj:IsA("DepthOfFieldEffect")
            or obj:IsA("SunRaysEffect")
        then
            pcall(function()
                obj.Enabled = false
            end)
        elseif obj:IsA("Atmosphere") then
            pcall(function()
                obj:Destroy()
            end)
        end
    end

    disconnectAll()

    local floorAncestryConn =
        floor.AncestryChanged:Connect(function()
            if U.enabled
                and (
                    not U.floor
                    or not U.floor.Parent
                )
            then
                task.defer(function()
                    if U.enabled then
                        floor = ensureClientFloor()
                    end
                end)
            end
        end)

    U.charConns[#U.charConns + 1] =
        floorAncestryConn

    table.insert(
        ScriptConnections,
        floorAncestryConn
    )

    local floorChildRemovedConn =
        floor.ChildRemoved:Connect(function(child)
            if U.enabled
                and child
                and string.find(
                    child.Name,
                    "DHub_FloorTile_",
                    1,
                    true
                ) == 1
            then
                task.defer(function()
                    if U.enabled then
                        floor = ensureClientFloor()
                    end
                end)
            end
        end)

    U.charConns[#U.charConns + 1] =
        floorChildRemovedConn

    table.insert(
        ScriptConnections,
        floorChildRemovedConn
    )

    U.conn =
        W.DescendantAdded:Connect(function(obj)
            if not U.enabled
                or not obj
                or not obj.Parent
            then
                return
            end

            task.defer(function()
                if not U.enabled
                    or not obj
                    or not obj.Parent
                then
                    return
                end

                if obj:IsA("ProximityPrompt") then
                    protectPromptHost(obj)

                    pcall(function()
                        if Cfg.instantSteal then
                            obj.HoldDuration = 0
                        end
                    end)

                    return
                end

                if obj:IsA("BasePart") then
                    task.wait(0.35)

                    if not U.enabled
                        or not obj
                        or not obj.Parent
                    then
                        return
                    end

                    if shouldKeepBasePart(obj) then
                        processProtectedObject(obj)
                    else
                        pcall(function()
                            obj:Destroy()
                        end)
                    end

                    return
                end

                if obj:IsA("SurfaceAppearance")
                    or obj:IsA("Decal")
                    or obj:IsA("Texture")
                    or obj:IsA("SpecialMesh")
                    or obj:IsA("ParticleEmitter")
                    or obj:IsA("Trail")
                    or obj:IsA("Smoke")
                    or obj:IsA("Fire")
                    or obj:IsA("Sparkles")
                    or obj:IsA("Beam")
                    or obj:IsA("PointLight")
                    or obj:IsA("SpotLight")
                    or obj:IsA("SurfaceLight")
                    or obj:IsA("Highlight")
                then
                    if isProtectedRootDescendant(obj)
                        or isTreadmillDescendant(obj)
                        or isPlotEngineAnchor(obj)
                    then
                        processProtectedObject(obj)
                    else
                        pcall(function()
                            obj:Destroy()
                        end)
                    end
                end
            end)
        end)

    table.insert(
        ScriptConnections,
        U.conn
    )

    local function bindCharacter(char)
        if not char then return end

        local conn =
            char.DescendantAdded:Connect(function(obj)
                if U.enabled then
                    task.defer(function()
                        if U.enabled
                            and obj
                            and obj.Parent
                        then
                            processProtectedObject(obj)
                        end
                    end)
                end
            end)

        U.charConns[#U.charConns + 1] =
            conn

        table.insert(
            ScriptConnections,
            conn
        )

        processProtectedTree(char)
    end

    for _,plr in ipairs(
        S.Players:GetPlayers()
    ) do
        if plr.Character then
            bindCharacter(plr.Character)
        end

        local conn =
            plr.CharacterAdded:Connect(function(char)
                if U.enabled then
                    bindCharacter(char)
                end
            end)

        U.charConns[#U.charConns + 1] =
            conn

        table.insert(
            ScriptConnections,
            conn
        )
    end

    U.purged = true

    pcall(function()
        if Notify then
            Notify(
                "Ultra FPS HARD PURGE enabled | Prompts: "
                    .. tostring(promptCountBeforePurge)
                    .. " | Hosts protected: "
                    .. tostring(newlyProtectedPromptHosts),
                5
            )
        end
    end)
end

DHub.SaveBridge = {module=nil}

function DHub.SaveBridge:GetModule()
    if self.module then
        return self.module
    end

    pcall(function()
        self.module = require(S.ReplicatedStorage.Shared.Save)
    end)

    return self.module
end

function DHub.SaveBridge:Read()
    local module = self:GetModule()
    if not module then
        return nil
    end

    local data = nil

    if type(module.ReadUnguarded) == "function" then
        pcall(function()
            data = module.ReadUnguarded()
        end)

        if type(data) == "table" then
            return data
        end
    end

    if type(module.Get) == "function" then
        pcall(function()
            data = module.Get()
        end)

        if type(data) == "table" then
            return data
        end
    end

    return nil
end

function DHub.SaveBridge:ConnectField(fieldName, callback)
    local module = self:GetModule()
    if not module or type(module.FieldSignal) ~= "function" then
        return nil
    end

    local signal = nil

    pcall(function()
        signal = module.FieldSignal(fieldName)
    end)

    if not signal then
        pcall(function()
            signal = module:FieldSignal(fieldName)
        end)
    end

    if not signal then
        return nil
    end

    local conn = nil

    pcall(function()
        conn = signal:Connect(callback)
    end)

    return conn
end

local function updateBackpackSpeedDisplay()
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        local bg = pg and pg:FindFirstChild("BackpackGui")
        if not bg then return end

        local inv = bg:FindFirstChild("Backpack")
            and bg.Backpack:FindFirstChild("Main")
            and bg.Backpack.Main:FindFirstChild("Inventory")

        if not inv then return end

        local Assets = nil
        local Mutations = nil
        local FormatShort = nil
        local Save = DHub.SaveBridge:Read()

        pcall(function()
            Assets = require(S.ReplicatedStorage.Data.Assets)
        end)

        pcall(function()
            Mutations = require(S.ReplicatedStorage.Shared.Modules.Mutations)
        end)

        pcall(function()
            FormatShort = require(S.ReplicatedStorage.UserGenerated.Strings.FormatShort)
        end)

        local assetsDir = Assets and (Assets.Directory or Assets) or {}

        if not FormatShort then
            FormatShort = function(n)
                n = tonumber(n) or 0
                if n >= 1e12 then return string.format("%.1fT", n/1e12)
                elseif n >= 1e9 then return string.format("%.1fB", n/1e9)
                elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
                elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
                else return tostring(math.floor(n)) end
            end
        end

        local function findAsset(category)
            category = tostring(category or "")
            if category == "" then return nil end

            local direct = assetsDir[category]
            if direct then return direct end

            local wanted = category:lower()

            for key, data in pairs(assetsDir) do
                if tostring(key):lower() == wanted then
                    return data
                end

                if type(data) == "table"
                    and tostring(data.DisplayName or ""):lower() == wanted
                then
                    return data
                end
            end

            return nil
        end

        local function getMutationMultiplier(record)
            if type(record) ~= "table"
                or not Mutations
                or type(Mutations.EarningsFor) ~= "function"
            then
                return 1
            end

            local mutations = type(record.Mutations) == "table"
                and record.Mutations
                or {}

            if #mutations == 0 then
                return 1
            end

            local ok, mult = pcall(function()
                return Mutations.EarningsFor(mutations)
            end)

            if ok and type(mult) == "number" and mult > 0 then
                return mult
            end

            return 1
        end

        local function getRecordIncome(record, kind)
            if type(record) ~= "table" then
                return nil
            end

            local category = kind == "egg"
                and tostring(record.AssetCategory or "")
                or tostring(record.Category or "")

            if category == "" then
                return nil
            end

            local assetData = findAsset(category)
            local baseRate = tonumber(assetData and assetData.EarningRate) or 0
            return baseRate * getMutationMultiplier(record)
        end

        local function getUidFromObject(obj)
            if not obj then return nil end

            for _, attrName in ipairs({
                "Uid","UID","ItemUid","ItemUID",
                "AssetUid","AssetUID","EggUid","EggUID"
            }) do
                local value = nil

                pcall(function()
                    value = obj:GetAttribute(attrName)
                end)

                if value ~= nil and tostring(value) ~= "" then
                    return tostring(value)
                end
            end

            return nil
        end

        local function resolveCardRecord(btn)
            if type(Save) ~= "table" then
                return nil, nil
            end

            local uid = getUidFromObject(btn)

            if not uid then
                local nameUid = tostring(btn.Name or "")

                if type(Save.Inventory) == "table" and Save.Inventory[nameUid] then
                    uid = nameUid
                elseif type(Save.EggInventory) == "table" and Save.EggInventory[nameUid] then
                    uid = nameUid
                end
            end

            if not uid then
                for _, child in ipairs(btn:GetDescendants()) do
                    uid = getUidFromObject(child)
                    if uid then break end

                    if child:IsA("StringValue")
                        and child.Name:lower():find("uid", 1, true)
                        and tostring(child.Value) ~= ""
                    then
                        uid = tostring(child.Value)
                        break
                    end
                end
            end

            if uid then
                if type(Save.Inventory) == "table" and Save.Inventory[uid] then
                    return Save.Inventory[uid], "pet"
                end

                if type(Save.EggInventory) == "table" and Save.EggInventory[uid] then
                    return Save.EggInventory[uid], "egg"
                end
            end

            return nil, nil
        end

        local totalSpeed = 0

        if type(Save) == "table"
            and type(Save.Inventory) == "table"
            and type(Save.EquippedAssets) == "table"
        then
            for _, uidValue in ipairs(Save.EquippedAssets) do
                local uid = tostring(uidValue or "")
                local pet = uid ~= "" and Save.Inventory[uid] or nil

                if pet then
                    totalSpeed = totalSpeed + (getRecordIncome(pet, "pet") or 0)
                end
            end
        end

        local totalLbl = inv:FindFirstChild("DHub_TotalSpeed")

        if not totalLbl then
            totalLbl = Instance.new("TextLabel")
            totalLbl.Name = "DHub_TotalSpeed"
            totalLbl.Parent = inv
            totalLbl.BackgroundTransparency = 1
            totalLbl.Position = UDim2.new(0.35, 0, 0.02, 0)
            totalLbl.Size = UDim2.new(0.35, 0, 0.08, 0)
            totalLbl.Font = Enum.Font.GothamBold
            totalLbl.TextSize = 13
            totalLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            totalLbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        totalLbl.Text = string.format(
            "[Total Speed: +%s/s]",
            tostring(FormatShort(totalSpeed)):upper()
        )

        local sf = inv:FindFirstChild("ScrollingFrame")
        if not sf then return end

        for _, btn in ipairs(sf:GetChildren()) do
            if not btn:IsA("TextButton") or btn.Name == "Template" then
                continue
            end

            local petSpeed = nil
            local record, kind = resolveCardRecord(btn)

            if record and kind then
                petSpeed = getRecordIncome(record, kind)
            end

            if petSpeed == nil then
                local toolNameLbl = btn:FindFirstChild("ToolName", true)

                if toolNameLbl and toolNameLbl.Text ~= "" then
                    local cleanName = toolNameLbl.Text
                        :gsub("%s*%([%d%.,]+%a*%)", "")
                        :gsub("^%s+", "")
                        :gsub("%s+$", "")

                    local mutMult = 1
                    local baseCat = cleanName

                    if Mutations and Mutations.IdSet then
                        for mId in pairs(Mutations.IdSet) do
                            if cleanName:sub(1, #mId) == mId then
                                local ok, mult = pcall(function()
                                    return Mutations.EarningsFor({mId})
                                end)

                                if ok and type(mult) == "number" then
                                    mutMult = mult
                                end

                                baseCat = cleanName
                                    :sub(#mId + 2)
                                    :gsub("^%s+", "")

                                break
                            end
                        end
                    end

                    local assetData = findAsset(baseCat)
                    local rate = tonumber(assetData and assetData.EarningRate) or 0
                    petSpeed = rate * mutMult
                end
            end

            if petSpeed ~= nil then
                local cardSpdLbl = btn:FindFirstChild("DHub_CardSpeed")

                if not cardSpdLbl then
                    cardSpdLbl = Instance.new("TextLabel")
                    cardSpdLbl.Name = "DHub_CardSpeed"
                    cardSpdLbl.Parent = btn
                end

                cardSpdLbl.ZIndex = 1000
                cardSpdLbl.BackgroundColor3 = Color3.fromRGB(15, 12, 28)
                cardSpdLbl.BackgroundTransparency = 0.25
                cardSpdLbl.AnchorPoint = Vector2.new(1, 0)
                cardSpdLbl.Position = UDim2.new(1, -4, 0, 4)
                cardSpdLbl.Size = UDim2.new(0, 56, 0, 16)
                cardSpdLbl.Font = Enum.Font.GothamBold
                cardSpdLbl.TextSize = 10
                cardSpdLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
                cardSpdLbl.TextXAlignment = Enum.TextXAlignment.Center

                local c2 = cardSpdLbl:FindFirstChildOfClass("UICorner")
                    or Instance.new("UICorner", cardSpdLbl)

                c2.CornerRadius = UDim.new(0, 4)

                local stk = cardSpdLbl:FindFirstChildOfClass("UIStroke")
                    or Instance.new("UIStroke", cardSpdLbl)

                stk.Color = Color3.fromRGB(60, 40, 90)
                stk.Thickness = 1
                cardSpdLbl.Text = "+"
                    .. tostring(FormatShort(petSpeed)):upper()
                    .. "/s"
            end
        end
    end)
end

DHub.MoneyDisplay = {
    queued=false,
    minDelay=0.20,
}

function DHub.MoneyDisplay:IsVisible()
    local pg=
        LP:FindFirstChild("PlayerGui")

    local bg=
        pg
        and pg:FindFirstChild("BackpackGui")

    return bg
        and bg.Enabled==true
end

function DHub.MoneyDisplay:Refresh(delaySec,force)
    if force~=true
        and not self:IsVisible()
    then
        return
    end

    if self.queued then
        return
    end

    self.queued=true

    task.delay(
        math.max(
            tonumber(delaySec) or self.minDelay,
            self.minDelay
        ),
        function()
            self.queued=false

            if force==true
                or self:IsVisible()
            then
                pcall(
                    updateBackpackSpeedDisplay
                )
            end
        end
    )
end

task.spawn(function()
    task.wait(1)
    DHub.MoneyDisplay:Refresh(0)

    for _, fieldName in ipairs({"Inventory","EquippedAssets","EggInventory"}) do
        local conn = DHub.SaveBridge:ConnectField(fieldName, function()
            DHub.MoneyDisplay:Refresh(0.20,false)
        end)

        if conn then
            table.insert(ScriptConnections, conn)
        end
    end

    pcall(function()
        local pg = LP:WaitForChild("PlayerGui", 5)
        local bg = pg and pg:WaitForChild("BackpackGui", 5)
        if not bg then return end

        local enabledConn = bg:GetPropertyChangedSignal("Enabled"):Connect(function()
            if bg.Enabled then
                DHub.MoneyDisplay:Refresh(0.10,true)
            end
        end)

        table.insert(ScriptConnections, enabledConn)

        local sf = bg:FindFirstChild("ScrollingFrame", true)

        if sf then
            local childAddedConn = sf.ChildAdded:Connect(function()
                DHub.MoneyDisplay:Refresh(0.20,false)
            end)

            local childRemovedConn = sf.ChildRemoved:Connect(function()
                DHub.MoneyDisplay:Refresh(0.20,false)
            end)

            table.insert(ScriptConnections, childAddedConn)
            table.insert(ScriptConnections, childRemovedConn)
        end
    end)
end)

DHub.EggStateService={module=nil}
pcall(function() DHub.EggStateService.module=require(S.ReplicatedStorage.Client.EggState) end)
function DHub._connectSignal(signal,fn)
    if not signal or type(fn)~="function" then return nil end
    local conn=nil; pcall(function() conn=signal:Connect(fn) end); if conn then table.insert(ScriptConnections,conn) end; return conn
end
DHub.AssetRarityCache, DHub.AssetNumberCache, DHub.AssetDirectory = {}, {}, nil
DHub.AssetRarityBuilt = false
function DHub.buildAssetRarityCache()
    if DHub.AssetRarityBuilt then return end; DHub.AssetRarityBuilt=true
    pcall(function()
        local assets=require(S.ReplicatedStorage.Data.Assets); DHub.AssetDirectory=assets and (assets.Directory or assets) or nil
        if type(DHub.AssetDirectory)~="table" then DHub.AssetDirectory=nil; return end
        for category,data in pairs(DHub.AssetDirectory) do
            if type(data)=="table" then
                local r=data.Rarity; local name=type(r)=="table" and (r._id or r.id or r.Name or r.DisplayName) or (type(r)=="string" and r or nil)
                if name then local key=tostring(category):lower(); DHub.AssetRarityCache[key]=tostring(name); DHub.AssetNumberCache[key]=type(r)=="table" and tonumber(r.RarityNumber) or 1 end
            end
        end
    end)
end
function DHub._rarityOfCategory(category)
    DHub.buildAssetRarityCache(); local data=DHub.AssetDirectory and DHub.AssetDirectory[category]; local r=data and data.Rarity; local key=tostring(category or ""):lower()
    local name=type(r)=="table" and (r._id or r.id or r.Name) or (type(r)=="string" and r or nil) or DHub.AssetRarityCache[key] or "Common"
    local num=(type(r)=="table" and tonumber(r.RarityNumber)) or DHub.AssetNumberCache[key] or RARITY_ORDER[tostring(name)] or 1
    return tostring(name),num
end
function DHub.getRarityFromModel(model) return model and DHub._rarityOfCategory(model:GetAttribute("AssetCategory") or model.Name) or "Common" end
function DHub.getZoneFromPos(pos)
    if typeof(pos)~="Vector3" then return nil end
    local best,bd=nil,math.huge; for n,p in pairs(ZONES) do local d=(pos-p).Magnitude; if d<bd then best,bd=n,d end end
    return bd<=350 and best or nil
end
function DHub.isInsideAnyEggArea(pos)
    if typeof(pos) ~= "Vector3" then return false end
    for _, zonePos in pairs(ZONES) do
        local flat=Vector3.new(pos.X-zonePos.X,0,pos.Z-zonePos.Z).Magnitude
        if flat<=200 and math.abs(pos.Y-zonePos.Y)<=85 then return true end
    end
    return false
end
function DHub.isAreaAllowedExact(areaName,eggPos)
    if Cfg.selectedAreas.All==true or not next(Cfg.selectedAreas) then return true end
    local area=tostring(areaName or "")
    for selected,on in pairs(Cfg.selectedAreas) do if on and selected~="All" then if selected==area then return true end; local zp=ZONES[selected]; if zp and typeof(eggPos)=="Vector3" and (eggPos-zp).Magnitude<=350 then return true end end end
    return false
end
function DHub.isRarityAllowedExact(rarityName)
    if Cfg.selectedRarities.All==true or not next(Cfg.selectedRarities) then return true end
    local wanted=tostring(rarityName or ""):lower(); for selected,on in pairs(Cfg.selectedRarities) do if on and selected~="All" and tostring(selected):lower()==wanted then return true end end
    return false
end
function DHub.getAccurateWeight(model)
    if not model then return 1 end
    local part=model:FindFirstChild("CustomBoundingBox") or model:FindFirstChild("Hitbox") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part and part:IsA("BasePart") then local s=part.Size; return s.X*s.Y*s.Z,part end
    return 1,nil
end
function DHub.isDroppedEggModel(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("AssetCategory") or model:GetAttribute("Uid") or model:GetAttribute("FirstAreaSlotKey") or model:GetAttribute("SlotKey") then return true end
    local uid=tostring(model.Name); return uid:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")~=nil or (#uid==32 and uid:match("^%x+$")~=nil)
end
function DHub._modelForUid(uid)
    local folder=S.Workspace:FindFirstChild("AreaEggSlotsClient"); return folder and folder:FindFirstChild(tostring(uid)) or nil
end
function DHub.getEggPrompt(posOrUid)
    local folder=S.Workspace:FindFirstChild("AreaEggSlotsClient"); if not folder then return nil end
    if type(posOrUid)=="string" then local m=folder:FindFirstChild(posOrUid); return m and m:FindFirstChildWhichIsA("ProximityPrompt",true) or nil end
    if typeof(posOrUid)~="Vector3" then return nil end
    local best,bd=nil,math.huge
    for _,m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then local p=m:FindFirstChild("Hitbox") or m:FindFirstChild("CustomBoundingBox") or m.PrimaryPart; if p and p:IsA("BasePart") then local d=(p.Position-posOrUid).Magnitude; if d<=20 and d<bd then local pr=m:FindFirstChildWhichIsA("ProximityPrompt",true); if pr then best,bd=pr,d end end end end
    end
    return best
end

DHub.ResetBarrierService={
    module=nil,
    sealed=false,

    resetEpoch=0,
    lastResetAt=0,
    kaitunNightPending=false,
}

pcall(function()
    DHub.ResetBarrierService.module=
        require(
            S.ReplicatedStorage.Client.AreaEggResetWall
        )

    if DHub.ResetBarrierService.module
        and DHub.ResetBarrierService.module.IsSealed
    then
        DHub.ResetBarrierService.sealed=
            DHub.ResetBarrierService.module.IsSealed()==true
    end
end)

if DHub.ResetBarrierService.module
    and DHub.ResetBarrierService.module.Changed
then
    DHub._connectSignal(
        DHub.ResetBarrierService.module.Changed,
        function(v)
            local service=
                DHub.ResetBarrierService

            local wasSealed=
                service.sealed==true

            local isSealed=
                v==true

            service.sealed=
                isSealed

            if isSealed==wasSealed then
                return
            end

            if isSealed then
                service.resetEpoch=
                    service.resetEpoch+1

                service.lastResetAt=
                    tick()

                service.kaitunNightPending=true

                task.defer(function()
                    local onTreadmill=
                        isPlayerOnTreadmill()

                    if onTreadmill then
                        if DHub.MovementService then
                            DHub.MovementService:Cancel("MainFarm")
                        end

                        -- treadmill release deferred until an actual Safezone route
                    end

                    if DHub.FarmCoordinator then
                        DHub.FarmCoordinator:Wake()
                    end
                end)

                local epoch=
                    service.resetEpoch

                task.defer(function()
                    if DHub.NotifierResetForEggCycle then
                        pcall(
                            DHub.NotifierResetForEggCycle,
                            epoch
                        )
                    end
                end)
            else
                local epoch=
                    service.resetEpoch

                task.delay(0.35,function()
                    if service.sealed
                        or service.resetEpoch~=epoch
                    then
                        return
                    end

                    if DHub.GlobalEggScanner
                        and DHub.GlobalEggScanner.Resync
                    then
                        DHub.GlobalEggScanner:Resync()
                    end
                end)

                task.delay(1.25,function()
                    if service.sealed
                        or service.resetEpoch~=epoch
                    then
                        return
                    end

                    local scanner=
                        DHub.GlobalEggScanner

                    if scanner
                        and scanner.Resync
                        and (
                            tick()
                            -(scanner.lastEventAt or 0)
                        )>=0.60
                    then
                        scanner:Resync()
                    end
                end)
            end
        end
    )
end
function DHub.ResetBarrierService:IsSealed()
    if self.module and self.module.IsSealed then local ok,v=pcall(self.module.IsSealed); if ok then self.sealed=v==true end end
    return self.sealed==true
end
function DHub.ResetBarrierService:WaitOpen(shouldContinue)
    while self:IsSealed() do
        if type(shouldContinue)=="function" then local ok,v=pcall(shouldContinue); if not ok or v~=true then return false end end
        S.RunService.Heartbeat:Wait()
    end
    return true
end

DHub.GlobalEggScanner={
    Cache={},
    CategoryIndex={},
    started=false,
    revision=0,
    lastEventAt=0,

    DirectReadAt={},
    DirectReadInterval=0.15,
    DirectMissCount={},
    MissingSnapshotCount={},
    SnapshotGrace=2,
}

function DHub.GlobalEggScanner:ClearForEggReset(epoch,phase)
    table.clear(self.DirectReadAt)

    self.lastResetEpoch=
        tonumber(epoch)
        or (
            DHub.ResetBarrierService
            and DHub.ResetBarrierService.resetEpoch
        )
        or 0

    self.lastResetPhase=
        tostring(phase or "reset")

    self.lastResetFlushAt=
        tick()
end

function DHub.GlobalEggScanner:_Pos(rec)
    if type(rec)~="table" then return nil end
    if typeof(rec.BoundsCFrame)=="CFrame" then return rec.BoundsCFrame.Position end
    if typeof(rec.BottomCFrame)=="CFrame" then return rec.BottomCFrame.Position end
    return nil
end

function DHub.GlobalEggScanner:_Weight(rec)
    if rec and typeof(rec.BoundsSize)=="Vector3" then
        local s=rec.BoundsSize
        return s.X*s.Y*s.Z
    end
    return tonumber(rec and rec.AssetScale) or 1
end

function DHub.GlobalEggScanner:_RemoveCategoryEntry(entry)
    if not entry or not entry.category or not entry.uid then
        return
    end

    local bucket=self.CategoryIndex[entry.category]
    if not bucket then return end

    bucket[entry.uid]=nil
    if next(bucket)==nil then
        self.CategoryIndex[entry.category]=nil
    end
end

function DHub.GlobalEggScanner:_AddCategoryEntry(entry)
    if not entry
        or not entry.uid
        or not entry.category
        or not entry.pos
        or (
            entry.state~="Slot"
            and entry.state~="Dropped"
        )
    then
        return
    end

    local bucket=self.CategoryIndex[entry.category]
    if not bucket then
        bucket={}
        self.CategoryIndex[entry.category]=bucket
    end

    bucket[entry.uid]=true
end

function DHub.GlobalEggScanner:_Touch()
    self.revision=self.revision+1
    self.lastEventAt=tick()
end

function DHub.GlobalEggScanner:Upsert(rec,quiet,skipSelector)
    if type(rec)~="table" or not rec.Uid then
        return nil
    end

    local uid=tostring(rec.Uid)
    local old=self.Cache[uid]
    local incomingVersion=tonumber(rec.Version)

    self.DirectMissCount[uid]=nil
    self.MissingSnapshotCount[uid]=nil

    if old
        and tonumber(old.version)
        and incomingVersion
        and incomingVersion<tonumber(old.version)
    then
        return old
    end

    if old
        and incomingVersion
        and incomingVersion>0
        and incomingVersion==tonumber(old.version)
    then
        local incomingPos=self:_Pos(rec)

        local samePos=
            (
                typeof(old.pos)=="Vector3"
                and typeof(incomingPos)=="Vector3"
                and (old.pos-incomingPos).Magnitude<=0.01
            )
            or (
                typeof(old.pos)~="Vector3"
                and typeof(incomingPos)~="Vector3"
            )

        local sameMeaningfulState=
            tostring(old.state or "")
                ==tostring(rec.State or "")
            and tostring(old.areaId or "")
                ==tostring(rec.AreaId or "")
            and tostring(old.category or "")
                ==tostring(rec.AssetCategory or "")
            and tostring(old.carrierUserId or "")
                ==tostring(rec.CarrierUserId or "")
            and tostring(old.nestId or "")
                ==tostring(rec.NestId or "")
            and samePos

        if sameMeaningfulState then
            old.raw=rec
            old.lastSeen=tick()
            return old
        end
    end

    if old then
        self:_RemoveCategoryEntry(old)
    end

    local rarity,rarityNum=
        DHub._rarityOfCategory(rec.AssetCategory)

    local e={
        uid=uid,
        category=tostring(rec.AssetCategory or ""),
        areaId=tostring(rec.AreaId or ""),
        nestId=rec.NestId,
        slotKey=tostring(rec.NestId or rec.Uid),
        pos=self:_Pos(rec),
        boundsCFrame=rec.BoundsCFrame,
        boundsSize=rec.BoundsSize,
        state=tostring(rec.State or ""),
        carrierUserId=rec.CarrierUserId,
        version=tonumber(rec.Version) or 0,
        rarity=rarity,
        rarityNum=rarityNum,
        weight=self:_Weight(rec),
        mutations=rec.Mutations or {},
        baseMutation=rec.BaseMutation,
        raw=rec,
        lastSeen=tick(),
    }

    e.zone=
        e.areaId~=""
        and e.areaId
        or DHub.getZoneFromPos(e.pos)
        or "Unknown"

    local mutationScore=#e.mutations*10
    if e.baseMutation
        and e.baseMutation~=""
        and e.baseMutation~="None"
    then
        mutationScore=mutationScore+25
    end

    e.score=(e.rarityNum or 1)*100+mutationScore

    self.Cache[uid]=e
    self:_AddCategoryEntry(e)

    if not skipSelector
        and DHub.TargetSelector
        and DHub.TargetSelector.OnEggChanged
    then
        DHub.TargetSelector:OnEggChanged(e,old)
    end

    if not quiet then
        self:_Touch()
    end

    return e
end

function DHub.GlobalEggScanner:Remove(uid,quiet,skipSelector)
    uid=tostring(uid or "")
    local old=self.Cache[uid]

    if not old then return end

    self:_RemoveCategoryEntry(old)
    self.Cache[uid]=nil
    self.DirectReadAt[uid]=nil
    self.DirectMissCount[uid]=nil
    self.MissingSnapshotCount[uid]=nil

    if not skipSelector
        and DHub.TargetSelector
        and DHub.TargetSelector.OnEggRemoved
    then
        DHub.TargetSelector:OnEggRemoved(uid,old)
    end

    if not quiet then
        self:_Touch()
    end
end

function DHub.GlobalEggScanner:ApplySnapshot(payload)
    local records=
        type(payload)=="table"
        and (
            payload.Records
            or payload.records
            or (payload[1] and payload)
        )
        or nil

    if type(records)~="table" then
        return
    end

    local seen={}
    local changed=false

    for _,rec in ipairs(records) do
        if type(rec)=="table" and rec.Uid then
            local uid=tostring(rec.Uid)
            local old=self.Cache[uid]
            local incomingPos=self:_Pos(rec)

            seen[uid]=true
            self.MissingSnapshotCount[uid]=nil

            if not old
                or tonumber(old.version or 0)
                    ~=tonumber(rec.Version or 0)
                or tostring(old.state or "")
                    ~=tostring(rec.State or "")
                or tostring(old.areaId or "")
                    ~=tostring(rec.AreaId or "")
                or tostring(old.category or "")
                    ~=tostring(rec.AssetCategory or "")
                or tostring(old.carrierUserId or "")
                    ~=tostring(rec.CarrierUserId or "")
                or tostring(old.nestId or "")
                    ~=tostring(rec.NestId or "")
                or (
                    typeof(old.pos)=="Vector3"
                    and typeof(incomingPos)=="Vector3"
                    and (old.pos-incomingPos).Magnitude>0.01
                )
                or (
                    typeof(old.pos)~="Vector3"
                    and typeof(incomingPos)=="Vector3"
                )
                or (
                    typeof(old.pos)=="Vector3"
                    and typeof(incomingPos)~="Vector3"
                )
            then
                changed=true
            end

            self:Upsert(rec,true,true)
        end
    end

    local stale={}
    local now=tick()

    for uid,e in pairs(self.Cache) do
        if seen[uid] then
            self.MissingSnapshotCount[uid]=nil
        elseif e.state=="Slot"
            or e.state=="Dropped"
        then
            local misses=
                (self.MissingSnapshotCount[uid] or 0)+1

            self.MissingSnapshotCount[uid]=misses

            if misses>=(self.SnapshotGrace or 2)
                and now-(e.lastSeen or 0)>=0.75
            then
                stale[#stale+1]=uid
            end
        end
    end

    for _,uid in ipairs(stale) do
        self:Remove(uid,true,true)
        changed=true
    end

    if changed then
        if DHub.TargetSelector
            and DHub.TargetSelector.RebuildFarmIndex
        then
            DHub.TargetSelector:RebuildFarmIndex()
        end

        self:_Touch()
    else
        self.lastEventAt=now
    end
end

function DHub.GlobalEggScanner:Get(uid,refresh)
    uid=tostring(uid or "")
    if uid=="" then return nil end

    if refresh
        and DHub.EggStateService.module
        and DHub.EggStateService.module.ReadFieldEgg
    then
        local now=tick()
        local last=self.DirectReadAt[uid] or 0

        if now-last >= (self.DirectReadInterval or 0.15) then
            self.DirectReadAt[uid]=now

            local ok,rec=
                pcall(
                    DHub.EggStateService.module.ReadFieldEgg,
                    uid
                )

            if ok then
                if rec then
                    self.DirectMissCount[uid]=nil
                    return self:Upsert(rec)
                end

                local old=self.Cache[uid]
                local misses=
                    (self.DirectMissCount[uid] or 0)+1

                self.DirectMissCount[uid]=misses

                if not old then
                    return nil
                end

                if misses>=3
                    and now-(old.lastSeen or 0)>=0.75
                then
                    self:Remove(uid)
                    return nil
                end

                return old
            end
        end
    end

    return self.Cache[uid]
end

function DHub.GlobalEggScanner:RefreshTarget(target)
    if type(target)~="table" or not target.uid then
        return nil
    end

    local e=self:Get(target.uid,true)
    if not e then return nil end

    if e.state~="Slot"
        and e.state~="Dropped"
        and not (
            e.state=="Carried"
            and tonumber(e.carrierUserId)
                ==tonumber(LP.UserId)
        )
    then
        return nil
    end

    return DHub.TargetSelector:_CopyEntry(
        e,
        getRoot() and getRoot().Position or nil
    )
end

function DHub.GlobalEggScanner:GetByCategory(category)
    local bucket=self.CategoryIndex[tostring(category or "")]
    if not bucket then return {} end

    local root=getRoot()
    local origin=root and root.Position or Vector3.zero
    local out={}

    for uid in pairs(bucket) do
        local e=self.Cache[uid]
        if e and e.pos then
            out[#out+1]=
                DHub.TargetSelector:_CopyEntry(e,origin)
        end
    end

    table.sort(out,function(a,b)
        return (a.dist or math.huge)
            <(b.dist or math.huge)
    end)

    return out
end

function DHub.GlobalEggScanner:GetBestByCategory(category,origin)
    local bucket=self.CategoryIndex[tostring(category or "")]
    if not bucket then return nil end

    if typeof(origin)~="Vector3" then
        local root=getRoot()
        origin=root and root.Position or Vector3.zero
    end

    local best=nil
    local bestDist=math.huge

    for uid in pairs(bucket) do
        local e=self.Cache[uid]

        if e and e.pos then
            local d=(e.pos-origin).Magnitude

            if d<bestDist then
                best=e
                bestDist=d
            end
        end
    end

    if not best then return nil end
    return DHub.TargetSelector:_CopyEntry(best,origin)
end

function DHub.GlobalEggScanner:Resync()
    if not DHub.EggStateService.module then
        return false
    end

    local snap=nil

    if DHub.EggStateService.module.SyncFieldEggs then
        pcall(function()
            snap=
                DHub.EggStateService.module.SyncFieldEggs()
        end)
    end

    if not snap
        and DHub.EggStateService.module.ReadFieldEggs
    then
        pcall(function()
            snap=
                DHub.EggStateService.module.ReadFieldEggs()
        end)
    end

    if snap then
        self:ApplySnapshot(snap)
        return true
    end

    return false
end

DHub.TargetSelector={
    FarmIndex={},
    filterSignature=nil,
    revision=0,

    bestHugestUid=nil,
    bestRarestUid=nil,

    staticBestDirty=false,
}

function DHub.TargetSelector:_EnabledTableSignature(tbl)
    local keys={}

    for k,v in pairs(tbl or {}) do
        if v then
            keys[#keys+1]=tostring(k)
        end
    end

    table.sort(keys)
    return table.concat(keys,",")
end

function DHub.TargetSelector:_CurrentFilterSignature()
    return table.concat({
        self:_EnabledTableSignature(Cfg.selectedAreas),
        self:_EnabledTableSignature(Cfg.selectedRarities),
        tostring(tonumber(Cfg.minWeight) or 0),
    },"|")
end

function DHub.TargetSelector:_IsEligible(e)
    return e~=nil
        and (
            e.state=="Slot"
            or e.state=="Dropped"
        )
        and e.pos~=nil
        and DHub.isAreaAllowedExact(e.areaId,e.pos)
        and DHub.isRarityAllowedExact(e.rarity)
        and (
            (tonumber(Cfg.minWeight) or 0)<=0
            or (tonumber(e.weight) or 0)
                >=(tonumber(Cfg.minWeight) or 0)
        )
end

function DHub.TargetSelector:_CopyEntry(e,origin)
    if not e then return nil end

    local c={}
    for k,v in pairs(e) do
        c[k]=v
    end

    c.model=DHub._modelForUid(e.uid)
    c.isDropped=e.state=="Dropped"

    if typeof(origin)~="Vector3" then
        local root=getRoot()
        origin=root and root.Position or nil
    end

    c.dist=
        origin
        and e.pos
        and (e.pos-origin).Magnitude
        or math.huge

    return c
end

function DHub.TargetSelector:_BetterHugest(a,b)
    if not a then return false end
    if not b then return true end

    local aw=tonumber(a.weight) or 0
    local bw=tonumber(b.weight) or 0

    if aw~=bw then return aw>bw end

    local as=tonumber(a.score) or 0
    local bs=tonumber(b.score) or 0

    if as~=bs then return as>bs end
    return tostring(a.uid)<tostring(b.uid)
end

function DHub.TargetSelector:_BetterRarest(a,b)
    if not a then return false end
    if not b then return true end

    local ar=
        tonumber(
            DHub.RarestFarmRank[
                tostring(a.rarity or "")
            ]
        )
        or tonumber(a.rarityNum)
        or 0

    local br=
        tonumber(
            DHub.RarestFarmRank[
                tostring(b.rarity or "")
            ]
        )
        or tonumber(b.rarityNum)
        or 0

    if ar~=br then
        return ar>br
    end

    local az=
        tostring(
            a.zone
            or a.areaId
            or ""
        )

    local bz=
        tostring(
            b.zone
            or b.areaId
            or ""
        )

    if DHub.FarmAreaProgressRank[az]==nil
        and typeof(a.pos)=="Vector3"
    then
        az=
            DHub.getZoneFromPos(a.pos)
            or az
    end

    if DHub.FarmAreaProgressRank[bz]==nil
        and typeof(b.pos)=="Vector3"
    then
        bz=
            DHub.getZoneFromPos(b.pos)
            or bz
    end

    local aa=
        tonumber(
            DHub.FarmAreaProgressRank[az]
        )
        or 0

    local ba=
        tonumber(
            DHub.FarmAreaProgressRank[bz]
        )
        or 0

    if aa~=ba then
        return aa>ba
    end

    local aw=tonumber(a.weight) or 0
    local bw=tonumber(b.weight) or 0

    if aw~=bw then
        return aw>bw
    end

    local as=tonumber(a.score) or 0
    local bs=tonumber(b.score) or 0

    if as~=bs then
        return as>bs
    end

    return tostring(a.uid)<tostring(b.uid)
end

function DHub.TargetSelector:_RecomputeStaticBest()
    self.bestHugestUid=nil
    self.bestRarestUid=nil

    local huge=nil
    local rare=nil

    for uid in pairs(self.FarmIndex) do
        local e=DHub.GlobalEggScanner.Cache[uid]

        if e then
            if self:_BetterHugest(e,huge) then
                huge=e
                self.bestHugestUid=uid
            end

            if self:_BetterRarest(e,rare) then
                rare=e
                self.bestRarestUid=uid
            end
        end
    end

    self.staticBestDirty=false
end

function DHub.TargetSelector:RebuildFarmIndex()
    table.clear(self.FarmIndex)

    for uid,e in pairs(DHub.GlobalEggScanner.Cache) do
        if self:_IsEligible(e) then
            self.FarmIndex[uid]=true
        end
    end

    self.filterSignature=
        self:_CurrentFilterSignature()

    self:_RecomputeStaticBest()
    self.revision=self.revision+1
end

function DHub.TargetSelector:EnsureFarmIndex()
    local sig=self:_CurrentFilterSignature()

    if self.filterSignature~=sig then
        self:RebuildFarmIndex()
    end
end

function DHub.TargetSelector:InvalidateFarmIndex()
    self.filterSignature=nil
    self.staticBestDirty=true
    self.revision=self.revision+1

    if DHub.GlobalEggScanner then
        DHub.GlobalEggScanner:_Touch()
    end
end

function DHub.TargetSelector:OnEggChanged(e,old)
    if self.filterSignature
        ~=self:_CurrentFilterSignature()
    then
        self.filterSignature=nil
        self.staticBestDirty=true
        self.revision=self.revision+1
        return
    end

    local uid=e.uid
    local was=self.FarmIndex[uid]==true
    local now=self:_IsEligible(e)

    if now then
        self.FarmIndex[uid]=true
    else
        self.FarmIndex[uid]=nil
    end

    local ownsCurrentBest=
        (self.bestHugestUid==uid)
        or (self.bestRarestUid==uid)

    if ownsCurrentBest then
        self.staticBestDirty=true
    elseif now and not self.staticBestDirty then
        local huge=
            self.bestHugestUid
            and DHub.GlobalEggScanner.Cache[self.bestHugestUid]
            or nil

        local rare=
            self.bestRarestUid
            and DHub.GlobalEggScanner.Cache[self.bestRarestUid]
            or nil

        if self:_BetterHugest(e,huge) then
            self.bestHugestUid=uid
        end

        if self:_BetterRarest(e,rare) then
            self.bestRarestUid=uid
        end
    end

    if was~=now or now then
        self.revision=self.revision+1
    end
end

function DHub.TargetSelector:OnEggRemoved(uid)
    local existed=self.FarmIndex[uid]==true
    self.FarmIndex[uid]=nil

    if self.bestHugestUid==uid
        or self.bestRarestUid==uid
    then
        self.staticBestDirty=true
    end

    if existed then
        self.revision=self.revision+1
    end
end

function DHub.TargetSelector:IsFarmEligibleUid(uid)
    self:EnsureFarmIndex()
    return self.FarmIndex[tostring(uid or "")]==true
end

function DHub.TargetSelector:GetFarmTargetByUid(uid)
    uid=tostring(uid or "")
    self:EnsureFarmIndex()

    if not self.FarmIndex[uid] then
        return nil
    end

    local e=DHub.GlobalEggScanner.Cache[uid]
    if not e then return nil end

    return self:_CopyEntry(e)
end

function DHub.TargetSelector:_FindBestByPriority(priority,ignoreUid)
    local root=getRoot()
    local origin=root and root.Position or Vector3.zero

    local best=nil
    local bestDist=math.huge

    for uid in pairs(self.FarmIndex) do
        if not ignoreUid
            or uid~=tostring(ignoreUid)
        then
            local e=DHub.GlobalEggScanner.Cache[uid]

            if e then
                if priority=="Nearest" then
                    local d=(e.pos-origin).Magnitude

                    if d<bestDist then
                        best=e
                        bestDist=d
                    end
                elseif priority=="Hugest" then
                    if self:_BetterHugest(e,best) then
                        best=e
                    end
                else
                    if self:_BetterRarest(e,best) then
                        best=e
                    end
                end
            end
        end
    end

    return best
end

function DHub.TargetSelector:GetBestFarmTarget(options)
    options=options or {}
    self:EnsureFarmIndex()

    local ignoreUid=
        options.ignoreUid
        and tostring(options.ignoreUid)
        or nil

    local preferUid=
        options.preferUid
        and tostring(options.preferUid)
        or nil

    if preferUid
        and preferUid~=ignoreUid
        and self.FarmIndex[preferUid]
    then
        return self:_CopyEntry(
            DHub.GlobalEggScanner.Cache[preferUid]
        )
    end

    local priority=
        options.priority
        or Cfg.farmPriority
        or "Nearest"

    if (
        priority=="Hugest"
        or priority=="Rarest"
    )
        and self.staticBestDirty
    then
        self:_RecomputeStaticBest()
    end

    local best=nil

    if priority=="Hugest"
        and self.bestHugestUid
        and self.bestHugestUid~=ignoreUid
    then
        best=
            DHub.GlobalEggScanner.Cache[
                self.bestHugestUid
            ]
    elseif priority=="Rarest"
        and self.bestRarestUid
        and self.bestRarestUid~=ignoreUid
    then
        best=
            DHub.GlobalEggScanner.Cache[
                self.bestRarestUid
            ]
    else
        best=
            self:_FindBestByPriority(
                priority,
                ignoreUid
            )
    end

    return self:_CopyEntry(best)
end

function DHub.TargetSelector:HasFarmCandidate()
    self:EnsureFarmIndex()
    return next(self.FarmIndex)~=nil
end

function DHub.TargetSelector:GetFarmCandidates()
    self:EnsureFarmIndex()

    local root=getRoot()
    local origin=root and root.Position or Vector3.zero
    local out={}

    for uid in pairs(self.FarmIndex) do
        local e=DHub.GlobalEggScanner.Cache[uid]
        if e then
            out[#out+1]=self:_CopyEntry(e,origin)
        end
    end

    if Cfg.farmPriority=="Hugest" then
        table.sort(out,function(a,b)
            return self:_BetterHugest(a,b)
        end)
    elseif Cfg.farmPriority=="Rarest" then
        table.sort(out,function(a,b)
            return self:_BetterRarest(a,b)
        end)
    else
        table.sort(out,function(a,b)
            return (a.dist or math.huge)
                <(b.dist or math.huge)
        end)
    end

    return out
end

function DHub.GlobalEggScanner:Start()
    if self.started then return end
    self.started=true

    DHub.buildAssetRarityCache()

    if not DHub.EggStateService.module then
        return
    end

    -- Scanner parity with Kaitun: do not seed stale field data while reset is sealed.
    if DHub.ResetBarrierService:IsSealed() then
        self:ClearForEggReset(
            DHub.ResetBarrierService.resetEpoch,
            "startup_sealed"
        )
    elseif DHub.EggStateService.module.ReadFieldEggs then
        pcall(function()
            local snapshot=
                DHub.EggStateService.module.ReadFieldEggs()

            if snapshot then
                self:ApplySnapshot(snapshot)
            end
        end)
    end

    DHub._connectSignal(
        DHub.EggStateService.module.FieldShifted,
        function(rec)
            self:Upsert(rec)
        end
    )

    DHub._connectSignal(
        DHub.EggStateService.module.FieldRefreshed,
        function(payload)
            self:ApplySnapshot(payload)
        end
    )

    DHub._connectSignal(
        DHub.EggStateService.module.FieldGone,
        function(uid)
            self:Remove(uid)
        end
    )
end

DHub.GlobalEggScanner:Start()

local ScanCache={
    eggs={},
    lastScan=0,
    scanning=false,
}


DHub.CarryService={carryUid=nil,carrying=false}
if DHub.EggStateService.module and DHub.EggStateService.module.CarryChanged then DHub._connectSignal(DHub.EggStateService.module.CarryChanged,function(p) if type(p)=="table" then DHub.CarryService.carrying=p.IsCarrying==true; DHub.CarryService.carryUid=DHub.CarryService.carrying and p.Uid and tostring(p.Uid) or nil end end) end
function DHub.CarryService:IsCarrying(uid) if uid then return self.carrying and tostring(self.carryUid)==tostring(uid) end return self.carrying or isCarryingEgg() end
function DHub.CarryService:TryOnce(target)
    if type(target)~="table" or not target.uid then return false end
    local uid=tostring(target.uid); local slot=target.slotKey or target.nestId; local accepted=false
    if DHub.EggStateService.module and DHub.EggStateService.module.CarryFieldEgg then pcall(function() accepted=DHub.EggStateService.module.CarryFieldEgg(uid,slot)==true end) end
    if not accepted and RMT.CarryEgg then pcall(function() local res=RMT.CarryEgg:InvokeServer({Uid=uid,FirstAreaSlotKey=slot}); accepted=res==true or (type(res)=="table" and (res.success==true or res.Success==true)) end) end
    return accepted or self:IsCarrying(uid)
end
function DHub.CarryService:TryCarry(target,opts)
    opts=opts or {}; local deadline=tick()+(tonumber(opts.timeout) or 2.25); local nextPrompt=0
    while tick()<deadline do
        if type(opts.shouldContinue)=="function" then local ok,v=pcall(opts.shouldContinue); if not ok or v~=true then return false end end
        if self:IsCarrying(target.uid) then return true end
        local live=DHub.GlobalEggScanner:RefreshTarget(target); if live then target=live end
        if self:TryOnce(target) then return true end
        if tick()>=nextPrompt then nextPrompt=tick()+0.12; local p=DHub.getEggPrompt(target.uid) or DHub.getEggPrompt(target.pos); if p and p.Parent and p:IsDescendantOf(S.Workspace) then pcall(function() p.HoldDuration=0; fireproximityprompt(p) end) end end
        S.RunService.Heartbeat:Wait()
    end
    return self:IsCarrying(target.uid)
end

local function setPromptInstant(prompt)
    if Cfg.instantSteal then pcall(function() prompt.HoldDuration = 0 end) end
end

local function applyInstantToAll()
    if not Cfg.instantSteal then return end
    for _, obj in ipairs(S.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then setPromptInstant(obj) end
    end
end

S.Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("ProximityPrompt") then setPromptInstant(d) end
end)

local PlotRuntime = {
    placing     = false,
    hatching    = false,
    placedCount = 0,
    statusText  = "Idle",
    StatusLbl2  = nil,
    penInfo     = nil,
    placeGeneration = 0,
    placeOwner      = nil,

    farmAuxRevision          = 0,
    nextFarmPlotProbeAt      = 0,
    cachedFarmHasPlaceable   = false,
    farmPlotSelectorRevision = nil,

    ownerEggCache            = nil,
    ownerEggCacheAt          = 0,
    ownerEggCacheDirty       = true,
    ownerEggCacheTTL         = 0.75,
    ownerEggConn             = nil,

    bestPetRunning           = false,
    bestPetGeneration        = 0,
    bestPetLastInvokeAt      = 0,
}

DHub.FarmCoordinator = {
    state = "Idle",
    targetUid = nil,
    targetMethod = nil,
    revision = 0,
}

function DHub.FarmCoordinator:SetState(state)
    state = tostring(state or "Idle")

    if self.state ~= state then
        self.state = state
        self.revision = self.revision + 1
    end
end

function DHub.FarmCoordinator:LockTarget(method, target)
    if type(target) ~= "table" or not target.uid then
        return false
    end

    self.targetUid = tostring(target.uid)
    self.targetMethod = tostring(method or "")
    self:SetState("FieldTarget")
    return true
end

function DHub.FarmCoordinator:ClearTarget(uid)
    if uid ~= nil
        and self.targetUid ~= nil
        and tostring(uid) ~= tostring(self.targetUid)
    then
        return false
    end

    self.targetUid = nil
    self.targetMethod = nil
    self:SetState("Idle")
    return true
end

function DHub.FarmCoordinator:HasTarget()
    return self.targetUid ~= nil
end

function DHub.FarmCoordinator:GetFieldTarget(options)
    if not DHub.TargetSelector
        or not DHub.TargetSelector.GetBestFarmTarget
    then
        return nil
    end

    return DHub.TargetSelector:GetBestFarmTarget(
        options
    )
end

function DHub.FarmCoordinator:CanPlot()
    if not Cfg.autoFarm
        or not PlotCfg.autoPlace
    then
        return false, "disabled"
    end

    if DHub.EventWavePriority
        and DHub.EventWavePriority:ShouldPauseMainFarm()
    then
        return false, "wave_priority"
    end

    if self:HasTarget() then
        return false, "locked_target"
    end

    if isCarryingEgg() then
        return false, "carry"
    end

    local fieldTarget =
        self:GetFieldTarget()

    if fieldTarget and fieldTarget.uid then
        return false, "farm_target"
    end

    return true, "ok"
end

function DHub.FarmCoordinator:Wake()
    self.revision = self.revision + 1

    if PlotRuntime
        and PlotRuntime.TouchFarmAux
    then
        PlotRuntime.TouchFarmAux(false)
    end
end

function DHub.IsIdleTreadmillAllowed()
    if Cfg.autoTreadmill ~= true then return false end

    local anyAutomation =
        Cfg.autoFarm == true
        or EventCfg.autoBoss == true
        or EventCfg.autoFuseScrambler == true

    if not anyAutomation then return false end

    if isCarryingEgg()
        or Runtime.carryEscapeActive
        or PlotRuntime.placing
    then
        return false
    end

    if DHub.EventBossPriority
        and (
            DHub.EventBossPriority.requested == true
            or DHub.EventBossPriority.active == true
        )
    then
        return false
    end

    if DHub.RiftFusePriorityActive == true then
        return false
    end

    if Cfg.autoFarm then
        if DHub.FarmCoordinator:HasTarget() then return false end

        if DHub.TargetSelector
            and DHub.TargetSelector.HasFarmCandidate
            and DHub.TargetSelector:HasFarmCandidate()
        then
            return false
        end

        if PlotRuntime.HasFarmPlaceableEgg
            and PlotRuntime.HasFarmPlaceableEgg(true)
        then
            return false
        end
    end

    return true
end

local function UpdatePlotStatus(txt)
    PlotRuntime.statusText = txt
    if PlotRuntime.StatusLbl2 then
        PlotRuntime.StatusLbl2.Text = string.format("Plot: %s  |  Placed: %d", txt, PlotRuntime.placedCount)
    end
end

DHub.AutoBestPet = {
    RemoteName = "RF/Haul/WearBest",
    minRequestInterval = 1.65,
    retryDelay = 1.75,
    lastAttemptAt = 0,
}

function DHub.AutoBestPet:Invoke()
    if isCarryingEgg() then
        return false, "carrying"
    end

    local char, root, hum = ensureCharacter(1)

    if not char or not root or not hum or hum.Health <= 0 then
        return false, "character"
    end

    local now = tick()

    if now - (self.lastAttemptAt or 0) < (self.minRequestInterval or 1.65) then
        return false, "cooldown"
    end

    local packages = S.ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    local remote = networking and networking:FindFirstChild(self.RemoteName)

    if not remote then
        return false, "remote"
    end

    self.lastAttemptAt = now

    local ok, result = pcall(function()
        return remote:InvokeServer()
    end)

    if not ok then
        return false, "invoke"
    end

    if result == false then
        return false, "rejected"
    end

    PlotRuntime.bestPetLastInvokeAt = tick()
    return true, "ok"
end

function DHub.AutoBestPet:Stop(keepEnabled)
    PlotRuntime.bestPetGeneration = PlotRuntime.bestPetGeneration + 1
    PlotRuntime.bestPetRunning = false

    if keepEnabled ~= true then
        PlotCfg.autoBestPet = false
    end
end

function DHub.AutoBestPet:Start(fireNow)
    if not PlotCfg.autoBestPet then return end

    PlotRuntime.bestPetGeneration = PlotRuntime.bestPetGeneration + 1
    local generation = PlotRuntime.bestPetGeneration
    PlotRuntime.bestPetRunning = true

    task.spawn(function()
        local nextDue = fireNow == true
            and tick()
            or tick() + math.max(
                6,
                (tonumber(PlotCfg.bestPetDelayMin) or 10) * 60
            )

        while PlotCfg.autoBestPet
            and generation == PlotRuntime.bestPetGeneration
        do
            local now = tick()

            if now < nextDue then
                task.wait(math.min(1, math.max(0.05, nextDue - now)))
                continue
            end

            local success, reason = self:Invoke()

            if success then
                nextDue = tick() + math.max(
                    6,
                    (tonumber(PlotCfg.bestPetDelayMin) or 10) * 60
                )
            else
                nextDue = tick()
                    + (reason == "cooldown" and 0.35 or (self.retryDelay or 1.75))
            end
        end

        if generation == PlotRuntime.bestPetGeneration then
            PlotRuntime.bestPetRunning = false
        end
    end)
end

function DHub.AutoBestPet:Restart(fireNow)
    self:Stop(true)

    if PlotCfg.autoBestPet then
        self:Start(fireNow == true)
    end
end

local function parseCFrameString(str)
    if typeof(str) == "CFrame" then return str end
    if type(str) ~= "string" then return nil end
    local nums = {}
    for n in str:gmatch("[%-]?%d+%.?%d*[eE]?[+-]?%d*") do nums[#nums+1] = tonumber(n) end
    if #nums >= 12 then
        return CFrame.new(nums[1],nums[2],nums[3],nums[4],nums[5],nums[6],nums[7],nums[8],nums[9],nums[10],nums[11],nums[12])
    elseif #nums >= 3 then
        return CFrame.new(nums[1], nums[2], nums[3])
    end
    return nil
end

local function findMyPlot()
    if PlotRuntime.penInfo and PlotRuntime.penInfo.plot and PlotRuntime.penInfo.plot.Parent then
        return PlotRuntime.penInfo
    end

    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local myName = LP.Name:lower()
    local myDisp = LP.DisplayName:lower()

    for _, plot in ipairs(plots:GetChildren()) do
        local isOwner = false
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            for _, desc in ipairs(sign:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text ~= "" then
                    local t = desc.Text:lower()
                    if t:find(myName, 1, true) or t:find(myDisp, 1, true) then
                        isOwner = true
                        break
                    end
                end
            end
        end
        local attr = plot:GetAttribute("Owner") or plot:GetAttribute("PlayerName")
        if attr and tostring(attr):lower() == myName then isOwner = true end

        if isOwner then
            local toUpdate = plot:FindFirstChild("ToUpdate")
            if toUpdate then
                local petArea     = toUpdate:FindFirstChild("PetArea")
                local centerPoint = toUpdate:FindFirstChild("CenterPoint")
                if petArea and centerPoint then
                    local info = {
                        plot        = plot,
                        petArea     = petArea,
                        centerPoint = centerPoint,
                        petAreaPos  = petArea.Position,
                        petAreaSize = petArea.Size,
                    }
                    PlotRuntime.penInfo = info
                    return info
                end
            end
        end
    end
    return nil
end

local function getUnplacedEggs()
    DHub.buildAssetRarityCache()
    local results = {}

    local ownerEggs=nil
    local now=tick()

    if not PlotRuntime.ownerEggCacheDirty
        and type(PlotRuntime.ownerEggCache)=="table"
        and now-(PlotRuntime.ownerEggCacheAt or 0)
            <(PlotRuntime.ownerEggCacheTTL or 0.75)
    then
        ownerEggs=PlotRuntime.ownerEggCache
    else
        local okEggs, freshEggs = pcall(function()
            local es = require(S.ReplicatedStorage.Client.EggState)
            return es.ReadOwnerEggs(LP.UserId)
        end)

        if okEggs and type(freshEggs)=="table" then
            ownerEggs=freshEggs
            PlotRuntime.ownerEggCache=freshEggs
            PlotRuntime.ownerEggCacheAt=now
            PlotRuntime.ownerEggCacheDirty=false
        elseif type(PlotRuntime.ownerEggCache)=="table" then
            ownerEggs=PlotRuntime.ownerEggCache
        end
    end

    if type(ownerEggs)=="table" and next(ownerEggs) then
        for recordId, record in pairs(ownerEggs) do
            if not record.Placement then
                local cat = tostring(record.AssetCategory or "Egg")
                local rarity = DHub.AssetRarityCache[cat:lower()] or DHub.getRarityFromModel({Name = cat})
                local weight = tonumber(record.AssetScale or record.Weight) or 0

                if PlotCfg.minWeight > 0 and weight < PlotCfg.minWeight then continue end

                if not PlotCfg.selectedRarities["All"] and next(PlotCfg.selectedRarities) then
                    local allowed = false
                    local rLower = tostring(rarity):lower()
                    local cLower = tostring(cat):lower()
                    for selRarity, active in pairs(PlotCfg.selectedRarities) do
                        if active and selRarity ~= "All" then
                            local sLower = selRarity:lower()
                            if rLower:find(sLower, 1, true) or sLower:find(rLower, 1, true) or cLower:find(sLower, 1, true) then
                                allowed = true
                                break
                            end
                        end
                    end
                    if not allowed then continue end
                end

                table.insert(results, {
                    id       = recordId,
                    uid      = recordId,
                    category = cat,
                    rarity   = rarity or "Common",
                    weight   = weight,
                    record   = record,
                })
            end
        end
    end

    return results
end

local function doPlotPlaceOnce(mode, generation)
    mode = mode or "manual"

    local function plotStillAllowed()
        if generation and generation ~= PlotRuntime.placeGeneration then return false end

        if DHub.EventWavePriority
            and DHub.EventWavePriority:ShouldPauseMainFarm()
        then
            return false
        end

        if mode == "standalone" then
            return PlotCfg.autoPlace and not Cfg.autoFarm
        elseif mode == "farm" then
            local allowed =
                DHub.FarmCoordinator:CanPlot()

            return allowed == true
        elseif mode == "manual" then
            return not Cfg.autoFarm
        end
        return false
    end

    if not plotStillAllowed() then return false end
    PlotRuntime.placeOwner = mode

    -- treadmill release deferred until an actual Safezone route

    local penInfo = findMyPlot()
    if not penInfo or not plotStillAllowed() then return false end

    local unplaced = getUnplacedEggs()
    if #unplaced == 0 then return false end

    local occupiedKeys = {}
    pcall(function()
        local es = require(S.ReplicatedStorage.Client.EggState)
        local ownerEggs = es.ReadOwnerEggs(LP.UserId)
        if type(ownerEggs) == "table" then
            for _, record in pairs(ownerEggs) do
                if record.Placement and record.Placement.LocalCFrame then
                    local cf = record.Placement.LocalCFrame
                    if typeof(cf) == "CFrame" then
                        local key = string.format("%d_%d",
                            math.floor(cf.X / 5 + 0.5) * 5,
                            math.floor(cf.Z / 5 + 0.5) * 5)
                        occupiedKeys[key] = true
                    elseif type(cf) == "string" then
                        local pcf = parseCFrameString(cf)
                        if pcf then
                            local key = string.format("%d_%d",
                                math.floor(pcf.X / 5 + 0.5) * 5,
                                math.floor(pcf.Z / 5 + 0.5) * 5)
                            occupiedKeys[key] = true
                        end
                    end
                end
            end
        end
    end)

    local SPACING   = 5
    local Y_OFFSET  = -0.025
    local gridSlots = {}

    for z = -15, 15, SPACING do
        for x = -20, 20, SPACING do
            local key = string.format("%d_%d", x, z)
            if not occupiedKeys[key] then table.insert(gridSlots, {x = x, z = z}) end
        end
    end

    if #gridSlots == 0 then
        UpdatePlotStatus("Pen is full!")
        return false
    end

    local petArea = penInfo.petArea

    UpdatePlotStatus(
        Cfg.farmMethod == "Fast"
            and "Fast TPWalk -> PetArea..."
            or "Entering PetArea..."
    )

    local reachedPetArea =
        DHub.MovementService:Move(
            petArea.Position + Vector3.new(0, 2, 0),
            {
                owner = "Plot",
                priority = DHub.MovementService.Priorities.Plot,
                method = Cfg.farmMethod,
                speed = Cfg.walkSpeed,
                stopDistance = 4,
                keepUnequipped = false,
                requireBypass = Cfg.farmMethod == "Fast",
                timeout = 30,
                shouldContinue = plotStillAllowed,
            }
        )

    if not reachedPetArea
        or not plotStillAllowed()
    then
        PlotRuntime.placeOwner = nil
        return false
    end

    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(petArea.Position + Vector3.new(0, 2, 0))
        root.AssemblyLinearVelocity = Vector3.zero
    end

    task.wait(0.2)
    if not plotStillAllowed() then PlotRuntime.placeOwner = nil; return false end

    local placedInCycle = 0
    local slotIdx = 1

    for _, egg in ipairs(unplaced) do
        if not plotStillAllowed() then break end

        for attempt = 1, 5 do
            if not plotStillAllowed() then break end
            if slotIdx > #gridSlots then break end
            local slot = gridSlots[slotIdx]
            slotIdx = slotIdx + 1

            local localCF = CFrame.new(slot.x, Y_OFFSET, slot.z)

            local ok, res = pcall(function()
                local es = require(S.ReplicatedStorage.Client.EggState)
                return es.PlantEgg(egg.id, localCF)
            end)

            if not ok or res ~= true then
                pcall(function()
                    local rf = S.ReplicatedStorage.Packages.Networking:FindFirstChild("RF/EggWorld/AskPlaceEgg")
                    if rf then
                        local r = rf:InvokeServer(egg.id, localCF)
                        if r == true or (type(r) == "table" and r.success == true) then res = true; ok = true end
                    end
                end)
            end

            if ok and (res == true or (type(res) == "table" and res.success == true)) then
                placedInCycle = placedInCycle + 1
                PlotRuntime.placedCount = PlotRuntime.placedCount + 1
                UpdatePlotStatus(string.format("Placed %s [%d]", egg.category, PlotRuntime.placedCount))
                local key = string.format("%d_%d", slot.x, slot.z)
                occupiedKeys[key] = true
                task.wait(0.08)
                break
            end
            task.wait(0.05)
        end
    end

    PlotRuntime.placeOwner = nil
    return placedInCycle > 0
end

PlotRuntime.TouchFarmAux = function(forceProbe)
    PlotRuntime.farmAuxRevision =
        (PlotRuntime.farmAuxRevision or 0) + 1

    if forceProbe then
        PlotRuntime.nextFarmPlotProbeAt = 0
    end
end

PlotRuntime.HasFarmPlaceableEgg = function(forceProbe)
    if not Cfg.autoFarm
        or not PlotCfg.autoPlace
    then
        PlotRuntime.cachedFarmHasPlaceable = false
        return false
    end

    local now = tick()

    if not forceProbe
        and now < (PlotRuntime.nextFarmPlotProbeAt or 0)
    then
        return PlotRuntime.cachedFarmHasPlaceable == true
    end

    PlotRuntime.nextFarmPlotProbeAt = now + 0.35

    local hasPlaceable = false

    pcall(function()
        local eggs = getUnplacedEggs()
        hasPlaceable = #eggs > 0
    end)

    PlotRuntime.cachedFarmHasPlaceable = hasPlaceable
    return hasPlaceable
end

PlotRuntime.ownerEggConn=
    DHub.SaveBridge:ConnectField(
        "EggInventory",
        function()
            PlotRuntime.ownerEggCacheDirty=true
            PlotRuntime.ownerEggCacheAt=0
            PlotRuntime.nextFarmPlotProbeAt=0

            if PlotRuntime.TouchFarmAux then
                PlotRuntime.TouchFarmAux(true)
            end
        end
    )

if PlotRuntime.ownerEggConn then
    table.insert(
        ScriptConnections,
        PlotRuntime.ownerEggConn
    )
end

PlotRuntime.RunFarmPlotPriority = function(statusPrefix)
    statusPrefix = tostring(statusPrefix or "Farm")

    local canPlot, blockReason =
        DHub.FarmCoordinator:CanPlot()

    if not canPlot then
        return false, blockReason
    end

    if PlotRuntime.placing then
        return false, "busy"
    end

    if not PlotRuntime.HasFarmPlaceableEgg(false) then
        return false, "none"
    end

    if isPlayerOnTreadmill() then
        UpdateStatus(
            statusPrefix
                .. ": Auto Plot ready -> releasing treadmill"
        )
        -- treadmill release deferred until an actual Safezone route
        task.wait(0.10)
    end

    local stillAllowed, afterDetachReason =
        DHub.FarmCoordinator:CanPlot()

    if not stillAllowed then
        return false, afterDetachReason
    end

    PlotRuntime.placing = true
    DHub.FarmCoordinator:SetState("Plot")
    PlotRuntime.placeGeneration =
        PlotRuntime.placeGeneration + 1

    local generation =
        PlotRuntime.placeGeneration

    PlotRuntime.placeOwner = "farm"
    PlotRuntime.farmPlotSelectorRevision =
        DHub.TargetSelector.revision

    UpdateStatus(
        statusPrefix
            .. ": Auto Plot -> placing backpack eggs"
    )

    local okCall, placed =
        pcall(
            doPlotPlaceOnce,
            "farm",
            generation
        )

    PlotRuntime.placing = false
    PlotRuntime.placeOwner = nil
    PlotRuntime.farmPlotSelectorRevision = nil
    PlotRuntime.cachedFarmHasPlaceable = false

    if not DHub.FarmCoordinator:HasTarget() then
        DHub.FarmCoordinator:SetState("Idle")
    end

    PlotRuntime.TouchFarmAux(false)

    if not okCall then
        PlotRuntime.nextFarmPlotProbeAt = tick() + 1.50
        UpdatePlotStatus("Farm plot retry")
        return false, "error"
    end

    if placed == true then
        PlotRuntime.nextFarmPlotProbeAt = 0

        UpdateStatus(
            statusPrefix
                .. ": Auto Plot done -> rechecking field eggs"
        )
        return true, "placed"
    end

    local targetNow =
        DHub.TargetSelector:GetBestFarmTarget()

    if targetNow and targetNow.uid then
        PlotRuntime.nextFarmPlotProbeAt = 0
        return false, "farm_target"
    end

    PlotRuntime.nextFarmPlotProbeAt = tick() + 1.50
    return false, "none"
end


local function autoHatchReadyEggs()
    local hatched = false
    local rs = S.ReplicatedStorage
    pcall(function()
        local EggState = require(rs.Client.EggState)
        local PlacedEggRenderer = require(rs.Shared.Eggs.PlacedEggRenderer)
        local owned = EggState.ReadOwnedEggs()
        if type(owned) == "table" then
            for uid, rec in pairs(owned) do
                if rec.Placement and EggState.IsReadyToHatch(uid) then
                    pcall(function() PlacedEggRenderer.ActivateLocalEgg(uid) end)
                    pcall(function() if RMT.Hatch then RMT.Hatch:InvokeServer(uid) end end)
                    task.wait(0.08)
                    pcall(function() if RMT.FinishHatch then RMT.FinishHatch:InvokeServer(uid) end end)
                    hatched = true
                    task.wait(0.15)
                end
            end
        end
    end)

    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        local growing = pg and pg:FindFirstChild("GrowingEggs")
        local frame = growing and growing:FindFirstChild("Frame")
        local sf = frame and frame:FindFirstChild("ScrollingFrame")
        if sf then
            for _, child in ipairs(sf:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "Template" and child.Name ~= "EmptyLast" then
                    local spacer = child:FindFirstChild("Spacer")
                    local openBtn = spacer and spacer:FindFirstChild("Open")
                    if openBtn and openBtn.Visible then
                        local price = openBtn:FindFirstChild("Price")
                        if price and (price.Text == "Open" or price.Text:lower():find("open") or price.Text:lower():find("hatch")) then
                            local uid = child.Name
                            pcall(function() require(rs.Shared.Eggs.PlacedEggRenderer).ActivateLocalEgg(uid) end)
                            pcall(function() if RMT.Hatch then RMT.Hatch:InvokeServer(uid) end end)
                            task.wait(0.08)
                            pcall(function() if RMT.FinishHatch then RMT.FinishHatch:InvokeServer(uid) end end)
                            hatched = true
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end)
    return hatched
end

local function doPlotPlaceLoop()
    if PlotRuntime.placing then return end
    PlotRuntime.placing = true
    PlotRuntime.placeGeneration = PlotRuntime.placeGeneration + 1

    local myGeneration = PlotRuntime.placeGeneration
    PlotRuntime.placeOwner = "standalone"
    UpdatePlotStatus("Starting...")

    local function standaloneAlive()
        return myGeneration == PlotRuntime.placeGeneration and PlotCfg.autoPlace and not Cfg.autoFarm
    end

    while standaloneAlive() do
        local unplaced = getUnplacedEggs()
        if not standaloneAlive() then break end

        if #unplaced == 0 then
            UpdatePlotStatus("No unplaced eggs")
            local waitUntil = tick() + 2
            while standaloneAlive() and tick() < waitUntil do task.wait(0.05) end
            continue
        end

        local ok = doPlotPlaceOnce("standalone", myGeneration)
        if not standaloneAlive() then break end

        if ok then
            UpdatePlotStatus(
                string.format(
                    "OK [%d] -> %s Safezone",
                    PlotRuntime.placedCount,
                    Cfg.farmMethod == "Fast"
                        and "Fast TPWalk"
                        or "Walk"
                )
            )

            DHub.MovementService:Move(
                SAFEZONE_POS,
                {
                    owner = "Plot",
                    priority = DHub.MovementService.Priorities.Plot,
                    method = Cfg.farmMethod,
                    speed = Cfg.walkSpeed,
                    stopDistance = 5,
                    keepUnequipped = false,
                    requireBypass = Cfg.farmMethod == "Fast",
                    timeout = 30,
                    shouldContinue = standaloneAlive,
                }
            )
        else
            if standaloneAlive() then
                UpdatePlotStatus("Pen full / retry")
                local waitUntil = tick() + 2.5
                while standaloneAlive() and tick() < waitUntil do task.wait(0.05) end
            end
        end

        local waitUntil = tick() + 0.5
        while standaloneAlive() and tick() < waitUntil do task.wait(0.05) end
    end

    if myGeneration == PlotRuntime.placeGeneration then PlotRuntime.placeOwner = nil end
    PlotRuntime.placing = false
    UpdatePlotStatus("Idle")
end

local function doHatchLoop()
    if PlotRuntime.hatching then return end
    PlotRuntime.hatching = true

    while PlotCfg.autoHatch do
        local hatched = autoHatchReadyEggs()
        if hatched then
            UpdatePlotStatus("Hatched ready eggs!")
        end
        task.wait(2)
    end

    PlotRuntime.hatching = false
end

DHub.SafeSell = {
    lastFireAt = 0,
    busy = false,
}

function DHub.SafeSell:NormalizeRarity(value)
    local result = tostring(value or ""):lower():gsub("%s+", "")
    if result == "mythical" then result = "mythic" end
    return result
end

function DHub.SafeSell:IsSelected(rarityName, filterTable)
    if type(filterTable) ~= "table" or not next(filterTable) then return false end
    if filterTable.All == true then return true end

    local wanted = self:NormalizeRarity(rarityName)
    if wanted == "" then return false end

    for selected, enabled in pairs(filterTable) do
        if enabled == true
            and selected ~= "All"
            and self:NormalizeRarity(selected) == wanted
        then
            return true
        end
    end

    return false
end

function DHub.SafeSell:GetRarity(category)
    category = tostring(category or "")
    if category == "" then return nil end

    DHub.buildAssetRarityCache()

    local data = DHub.AssetDirectory and DHub.AssetDirectory[category] or nil

    if not data and DHub.AssetDirectory then
        local wanted = category:lower()

        for key, value in pairs(DHub.AssetDirectory) do
            if tostring(key):lower() == wanted then
                data = value
                break
            end
        end
    end

    if type(data) ~= "table" then return nil end

    local rarity = data.Rarity

    if type(rarity) == "string" then return rarity end

    if type(rarity) == "table" then
        return tostring(
            rarity._id
            or rarity.id
            or rarity.Name
            or rarity.DisplayName
            or ""
        )
    end

    return nil
end

function DHub.SafeSell:IsEquipped(uid, equipped)
    if type(equipped) ~= "table" then return false end
    uid = tostring(uid or "")

    for _, equippedUid in ipairs(equipped) do
        if tostring(equippedUid) == uid then
            return true
        end
    end

    return false
end

function DHub.SafeSell:BuildCurrentSelection()
    local Save = DHub.SaveBridge:Read()
    if type(Save) ~= "table" then return {}, {} end

    local assets = {}
    local eggs = {}
    local equipped = Save.EquippedAssets or {}

    if type(Save.Inventory) == "table"
        and type(ShopCfg.sellPetRarities) == "table"
        and next(ShopCfg.sellPetRarities)
    then
        for uid, petData in pairs(Save.Inventory) do
            if type(petData) ~= "table" then continue end

            if petData.InFuse == true
                or petData.IsFavorite == true
                or petData.Favorite == true
                or petData.Locked == true
                or self:IsEquipped(uid, equipped)
            then
                continue
            end

            local rarity = self:GetRarity(petData.Category)

            if rarity and self:IsSelected(rarity, ShopCfg.sellPetRarities) then
                assets[#assets + 1] = tostring(uid)
            end
        end
    end

    if type(Save.EggInventory) == "table"
        and type(ShopCfg.sellEggRarities) == "table"
        and next(ShopCfg.sellEggRarities)
    then
        for uid, eggData in pairs(Save.EggInventory) do
            if type(eggData) ~= "table"
                or eggData.Placement
                or eggData.IsFavorite == true
                or eggData.Favorite == true
                or eggData.Locked == true
            then
                continue
            end

            local rarity = self:GetRarity(eggData.AssetCategory)

            if rarity and self:IsSelected(rarity, ShopCfg.sellEggRarities) then
                eggs[#eggs + 1] = tostring(uid)
            end
        end
    end

    return assets, eggs
end

function DHub.SafeSell:FireSelection(assets, eggs)
    assets = type(assets) == "table" and assets or {}
    eggs = type(eggs) == "table" and eggs or {}

    local total = #assets + #eggs
    if total <= 0 then return false, "No matching selected rarity", 0 end
    if not RMT.SellSelection then return false, "SellSelection remote missing", 0 end

    local waited = 0

    while self.busy and waited < 2 do
        task.wait(0.05)
        waited = waited + 0.05
    end

    if self.busy then return false, "Sell busy", 0 end
    self.busy = true

    local debounceLeft = 0.32 - (tick() - (self.lastFireAt or 0))
    if debounceLeft > 0 then task.wait(debounceLeft) end

    local ok = pcall(function()
        RMT.SellSelection:FireServer({
            Assets = assets,
            Eggs = eggs,
        })
    end)

    if ok then self.lastFireAt = tick() end
    self.busy = false

    if not ok then return false, "SellSelection request failed", 0 end

    return true,
        string.format("Selling %d pet(s), %d egg(s)", #assets, #eggs),
        total
end

function DHub.SafeSell:FireCurrent(force)
    if force ~= true and not ShopCfg.autoSellAll then
        return false, "Auto Sell OFF", 0
    end

    local assets, eggs = self:BuildCurrentSelection()
    return self:FireSelection(assets, eggs)
end

function DHub.SafeSell:FireSpecific(assetSet, eggSet)
    local Save = DHub.SaveBridge:Read()
    if type(Save) ~= "table" then return false, "Save unavailable", 0 end

    local assets = {}
    local eggs = {}
    local equipped = Save.EquippedAssets or {}

    if type(assetSet) == "table" and type(Save.Inventory) == "table" then
        for uid in pairs(assetSet) do
            local petData = Save.Inventory[uid]

            if type(petData) == "table"
                and petData.InFuse ~= true
                and petData.IsFavorite ~= true
                and petData.Favorite ~= true
                and petData.Locked ~= true
                and not self:IsEquipped(uid, equipped)
            then
                local rarity = self:GetRarity(petData.Category)

                if rarity and self:IsSelected(rarity, ShopCfg.sellPetRarities) then
                    assets[#assets + 1] = tostring(uid)
                end
            end
        end
    end

    if type(eggSet) == "table" and type(Save.EggInventory) == "table" then
        for uid in pairs(eggSet) do
            local eggData = Save.EggInventory[uid]

            if type(eggData) == "table"
                and not eggData.Placement
                and eggData.IsFavorite ~= true
                and eggData.Favorite ~= true
                and eggData.Locked ~= true
            then
                local rarity = self:GetRarity(eggData.AssetCategory)

                if rarity and self:IsSelected(rarity, ShopCfg.sellEggRarities) then
                    eggs[#eggs + 1] = tostring(uid)
                end
            end
        end
    end

    return self:FireSelection(assets, eggs)
end

local function doSellCycle(force)
    return DHub.SafeSell:FireCurrent(force)
end

DHub.AutoSell = {
    running = false,
    generation = 0,
    connections = {},
    knownPets = {},
    knownEggs = {},
    pendingPets = {},
    pendingEggs = {},
    flushQueued = false,
}

function DHub.AutoSell:Disconnect()
    for _, conn in ipairs(self.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.connections)
end

function DHub.AutoSell:Snapshot()
    local Save = DHub.SaveBridge:Read()
    table.clear(self.knownPets)
    table.clear(self.knownEggs)

    if type(Save) ~= "table" then return end

    if type(Save.Inventory) == "table" then
        for uid in pairs(Save.Inventory) do
            self.knownPets[tostring(uid)] = true
        end
    end

    if type(Save.EggInventory) == "table" then
        for uid in pairs(Save.EggInventory) do
            self.knownEggs[tostring(uid)] = true
        end
    end
end

function DHub.AutoSell:QueueFlush()
    if self.flushQueued or not self.running or not ShopCfg.autoSellAll then return end

    self.flushQueued = true
    local generation = self.generation

    task.delay(0.35, function()
        self.flushQueued = false

        if not self.running
            or not ShopCfg.autoSellAll
            or generation ~= self.generation
        then
            return
        end

        DHub.SafeSell:FireSpecific(self.pendingPets, self.pendingEggs)
        table.clear(self.pendingPets)
        table.clear(self.pendingEggs)
    end)
end

function DHub.AutoSell:InventoryChanged()
    if not self.running or not ShopCfg.autoSellAll then return end

    local Save = DHub.SaveBridge:Read()
    local inventory = Save and Save.Inventory
    if type(inventory) ~= "table" then return end

    local current = {}

    for uid in pairs(inventory) do
        uid = tostring(uid)
        current[uid] = true
        if not self.knownPets[uid] then self.pendingPets[uid] = true end
    end

    self.knownPets = current
    if next(self.pendingPets) then self:QueueFlush() end
end

function DHub.AutoSell:EggInventoryChanged()
    if not self.running or not ShopCfg.autoSellAll then return end

    local Save = DHub.SaveBridge:Read()
    local inventory = Save and Save.EggInventory
    if type(inventory) ~= "table" then return end

    local current = {}

    for uid in pairs(inventory) do
        uid = tostring(uid)
        current[uid] = true
        if not self.knownEggs[uid] then self.pendingEggs[uid] = true end
    end

    self.knownEggs = current
    if next(self.pendingEggs) then self:QueueFlush() end
end

function DHub.AutoSell:Reevaluate()
    if not self.running or not ShopCfg.autoSellAll then return end

    task.spawn(function()
        doSellCycle(false)
        self:Snapshot()
    end)
end

function DHub.AutoSell:Stop()
    self.generation = self.generation + 1
    self.running = false
    self.flushQueued = false
    self:Disconnect()
    table.clear(self.pendingPets)
    table.clear(self.pendingEggs)
end

function DHub.AutoSell:Start()
    self:Stop()
    if not ShopCfg.autoSellAll then return end

    self.generation = self.generation + 1
    self.running = true
    self:Snapshot()

    local inventoryConn = DHub.SaveBridge:ConnectField("Inventory", function()
        self:InventoryChanged()
    end)

    local eggConn = DHub.SaveBridge:ConnectField("EggInventory", function()
        self:EggInventoryChanged()
    end)

    if inventoryConn then self.connections[#self.connections + 1] = inventoryConn end
    if eggConn then self.connections[#self.connections + 1] = eggConn end

    self:Reevaluate()
end

local function doAutoUpgradePlot()
    if ShopCfg.autoUpgradePlot and RMT.BaseUpgrade then
        pcall(function() RMT.BaseUpgrade:FireServer() end)
    end
end

local function doAutoUpgradeTreadmill()
    if ShopCfg.autoUpgradeTread and RMT.TreadmillUpgrade then
        pcall(function() RMT.TreadmillUpgrade:InvokeServer() end)
    end
end

local function getFusePetOptions()
    local Save = nil
    pcall(function() Save = require(S.ReplicatedStorage.Shared.Save).Get() end)
    local counts = {}
    if Save and Save.Inventory then
        for uid, item in pairs(Save.Inventory) do
            if not item.InFuse and not item.IsFavorite then
                local cat = tostring(item.Category or "Unknown")
                counts[cat] = (counts[cat] or 0) + 1
            end
        end
    end

    local options = {}
    for cat, count in pairs(counts) do
        table.insert(options, {cat = cat, count = count, label = string.format("%s (x%d)", cat, count)})
    end
    table.sort(options, function(a, b) return a.count > b.count end)

    local labels = {"None"}
    for _, opt in ipairs(options) do table.insert(labels, opt.label) end
    return labels, counts
end

local function doFuseOnce()
    if not ShopCfg.autoFuse or ShopCfg.selectedPetFuse == "" or ShopCfg.selectedPetFuse == "None" then return false end

    local chosenCategory = ShopCfg.selectedPetFuse:match("^(.-)%s*%(x%d+%)") or ShopCfg.selectedPetFuse
    if chosenCategory == "" or chosenCategory == "None" then return false end

    local Save = nil
    pcall(function() Save = require(S.ReplicatedStorage.Shared.Save).Get() end)
    if not Save or not Save.Inventory then return false end

    local matchingUids = {}
    for uid, item in pairs(Save.Inventory) do
        if not item.InFuse and not item.IsFavorite and item.Category == chosenCategory then
            table.insert(matchingUids, uid)
            if #matchingUids >= 3 then break end
        end
    end

    if #matchingUids < 3 then return false, "Need at least 3 pets" end

    if RMT.FuseryLoadPet and RMT.FuseryBeginFuse then
        for i = 1, 3 do
            pcall(function() RMT.FuseryLoadPet:InvokeServer(matchingUids[i]) end)
            task.wait(0.1)
        end
        local ok = pcall(function() return RMT.FuseryBeginFuse:InvokeServer() end)
        task.wait(0.2)
        if RMT.FuseryFinishReveal then pcall(function() RMT.FuseryFinishReveal:InvokeServer() end) end
        return ok, "Fuse done for " .. chosenCategory
    end
    return false, "Fusery remote missing"
end

local AntiBossState = {
    enabled      = false,
    teleporting  = false,
    connection   = nil,
    targetPos    = SAFEZONE_POS,
    spamDelay    = 0.01,
    cycleId      = 0,

    overlayGui   = nil,
    overlayToken = 0,
    lastTriggerAt = 0,
    promptConnections = setmetatable({}, {__mode = "k"}),
}

local function isAntiBossForestPosition(pos)
    if typeof(pos) ~= "Vector3" then
        return false
    end

    local zone = nil

    pcall(function()
        zone = DHub.getZoneFromPos(pos)
    end)

    if zone == "Forest" then
        return true
    end

    local forestPos =
        ZONES and ZONES["Forest"] or nil

    if typeof(forestPos) == "Vector3" then
        if (pos - forestPos).Magnitude <= 115 then
            return true
        end
    end

    return false
end

local function isAntiBossCurrentlyInForest()
    local root = getRoot()
    return root
        and isAntiBossForestPosition(root.Position)
        or false
end

local function getAntiBossPromptHostPart(prompt)
    if not prompt or not prompt.Parent then
        return nil
    end

    local p = prompt.Parent

    if p:IsA("BasePart") then
        return p
    end

    if p:IsA("Attachment")
        and p.Parent
        and p.Parent:IsA("BasePart")
    then
        return p.Parent
    end

    if p:IsA("Model") then
        return p.PrimaryPart
            or p:FindFirstChild("SmartPromptPart", true)
            or p:FindFirstChildWhichIsA("BasePart", true)
    end

    while p and p ~= S.Workspace do
        if p:IsA("BasePart") then
            return p
        end
        p = p.Parent
    end

    return nil
end

local function isAntiBossEggPrompt(prompt)
    if not prompt
        or not prompt:IsA("ProximityPrompt")
    then
        return false
    end

    local host =
        getAntiBossPromptHostPart(prompt)

    if not host then
        return false
    end

    local hostName =
        string.lower(host.Name or "")

    if string.find(hostName, "egg", 1, true)
        or string.find(hostName, "smart", 1, true)
    then
        return true
    end

    local eggRoot =
        S.Workspace:FindFirstChild(
            "AreaEggSlotsClient"
        )

    if eggRoot
        and prompt:IsDescendantOf(eggRoot)
    then
        return true
    end

    return false
end

local function ensureAntiBossOverlay()
    local gui = AntiBossState.overlayGui

    if gui and gui.Parent then
        return gui
    end

    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "DHub_BypassingBoss"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Enabled = false

    pcall(function()
        gui.ScreenInsets = Enum.ScreenInsets.None
    end)

    local black = Instance.new("Frame")
    black.Name = "Black"
    black.AnchorPoint = Vector2.new(0, 0)
    black.Position = UDim2.fromScale(0, 0)
    black.Size = UDim2.fromScale(1, 1)
    black.BackgroundColor3 = Color3.new(0, 0, 0)
    black.BackgroundTransparency = 0
    black.BorderSizePixel = 0
    black.Active = true
    black.ZIndex = 2147483000
    black.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.5)
    title.Size = UDim2.new(1, -40, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = "D-Hub Bypassing Boss"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextTransparency = 0
    title.TextStrokeTransparency = 0.75
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.ZIndex = 2147483001
    title.Parent = black

    local parented = false

    pcall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if typeof(h) == "Instance" then
                gui.Parent = h
                parented = true
            end
        end
    end)

    if not parented then
        pcall(function()
            gui.Parent = S.CoreGui
            parented = gui.Parent ~= nil
        end)
    end

    if not parented then
        gui.Parent =
            LP:WaitForChild("PlayerGui")
    end

    AntiBossState.overlayGui = gui
    return gui
end

local function hideAntiBossOverlay()
    AntiBossState.overlayToken =
        AntiBossState.overlayToken + 1

    local gui =
        AntiBossState.overlayGui

    if gui and gui.Parent then
        pcall(function()
            gui.Enabled = false
        end)
    end
end

local function showAntiBossOverlay()
    local gui =
        ensureAntiBossOverlay()

    if not gui then
        return
    end

    AntiBossState.overlayToken =
        AntiBossState.overlayToken + 1

    local token =
        AntiBossState.overlayToken

    pcall(function()
        gui.Enabled = true
    end)

    pcall(function()
        S.RunService.RenderStepped:Wait()
    end)

    task.delay(2, function()
        if AntiBossState.overlayToken ~= token then
            return
        end

        if gui and gui.Parent then
            pcall(function()
                gui.Enabled = false
            end)
        end
    end)
end

local function stopAntiBossSpamTeleport()
    AntiBossState.teleporting = false
    if AntiBossState.connection then
        pcall(function() AntiBossState.connection:Disconnect() end)
        AntiBossState.connection = nil
    end
end

local function startAntiBossSpamTeleport()
    stopAntiBossSpamTeleport()
    AntiBossState.enabled = true
    AntiBossState.teleporting = true
    AntiBossState.targetPos = SAFEZONE_POS
    AntiBossState.cycleId = AntiBossState.cycleId + 1

    local myCycle = AntiBossState.cycleId
    AntiBossState.connection = S.RunService.Heartbeat:Connect(function()
        if not AntiBossState.teleporting or not Cfg.antiBoss or myCycle ~= AntiBossState.cycleId then return end
        local root = getRoot()
        if not root then return end

        local jitter = Vector3.new(
            math.random(-20, 20) / 10,
            math.random(-20, 20) / 10,
            math.random(-20, 20) / 10
        )
        pcall(function()
            root.CFrame = CFrame.new(AntiBossState.targetPos + jitter)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

local function triggerAntiBossSpamTeleport(forceFresh, forceAnyZone)
    if not Cfg.antiBoss then
        return false
    end

    if forceAnyZone ~= true
        and isAntiBossCurrentlyInForest()
    then
        return false
    end

    local now = tick()

    if forceFresh == true then
        if AntiBossState.teleporting then
            stopAntiBossSpamTeleport()
        end
    else
        if AntiBossState.teleporting then
            return true
        end

        if now - (AntiBossState.lastTriggerAt or 0) < 1.0 then
            return true
        end
    end

    AntiBossState.lastTriggerAt = now

    showAntiBossOverlay()
    startAntiBossSpamTeleport()

    local thisCycle =
        AntiBossState.cycleId

    task.delay(0.65, function()
        if thisCycle ~= AntiBossState.cycleId then
            return
        end

        stopAntiBossSpamTeleport()
    end)

    return true
end

local function waitForAntiBossTeleport()
    local started = tick()
    while AntiBossState.teleporting and tick() - started < 2 do
        task.wait(0.05)
    end
    task.wait(0.30)
end

local function instantCarryEscape(forceAntiBossAnyZone)
    if Runtime.carryEscapeActive then return true end
    Runtime.carryEscapeActive = true

    Runtime.steals = Runtime.steals + 1
    ScanCache.lastScan = 0
    ScanCache.eggs = {}

    if Cfg.antiBoss then
        UpdateStatus(string.format("ANTI BOSS → BYPASS PHASE! [%d]", Runtime.steals))

        local bypassTriggered =
            triggerAntiBossSpamTeleport(
                forceAntiBossAnyZone == true,
                forceAntiBossAnyZone == true
            )

        if bypassTriggered then
            waitForAntiBossTeleport()
        end

        UpdateStatus(string.format("ANTI BOSS DONE → WALK SAFEZONE [%d]", Runtime.steals))
        WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            nil,
            {avoidPlayerTraps = true}
        )
    else
        UpdateStatus(string.format("CARRY CONFIRMED → SAFEZONE! [%d]", Runtime.steals))
        WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            nil,
            {avoidPlayerTraps = true}
        )
    end

    stopAntiBossSpamTeleport()
    forceUnequipTools()
    task.wait(0.05)
    forceUnequipTools()
    Runtime.carryEscapeActive = false
    return true
end

local EventRuntime = {
    running = false,
    activeSubEngine = "Idle",
    StatusLbl = nil,
}

local function UpdateEventStatus(txt)
    if EventRuntime.StatusLbl then
        EventRuntime.StatusLbl.Text =
            "Scramble: " .. tostring(txt)
    end
end

DHub.RiftFusePriorityActive = false

-- ============================================================
-- DR. SCRAMBLE AUTO BOSS PRIORITY
--
-- Boss only requests control while the live arena portal/arena exists.
-- A carried/locked Farm Egg is allowed to finish first; after that Boss
-- owns movement until the server destroys ScrambleArena and returns lobby.
-- ============================================================

DHub.EventBossPriority = DHub.EventBossPriority or {
    requested = false,
    active = false,
    revision = 0,
}

function DHub.EventBossPriority:_Touch()
    self.revision = (self.revision or 0) + 1

    if DHub.FarmCoordinator
        and DHub.FarmCoordinator.Wake
    then
        DHub.FarmCoordinator:Wake()
    end
end

function DHub.EventBossPriority:BeginRequest()
    if not EventCfg.autoBoss then
        return
    end

    if self.requested ~= true then
        self.requested = true
        self.active = false
        self:_Touch()
    end
end

function DHub.EventBossPriority:EndRequest()
    local changed =
        self.requested == true
        or self.active == true

    self.requested = false
    self.active = false

    if changed then
        self:_Touch()
    end
end

function DHub.EventBossPriority:IsMainFarmBusy()
    if isCarryingEgg()
        or Runtime.carryEscapeActive
        or PlotRuntime.placing
    then
        return true
    end

    if DHub.FarmCoordinator
        and DHub.FarmCoordinator:HasTarget()
    then
        return true
    end

    if Cfg.autoFarm
        and DHub.TargetSelector
        and DHub.TargetSelector.HasFarmCandidate
        and DHub.TargetSelector:HasFarmCandidate()
    then
        return true
    end

    return false
end

function DHub.EventBossPriority:CanTakeover()
    if self.requested ~= true then
        return false
    end

    if self.active == true then
        return true
    end

    return not self:IsMainFarmBusy()
end

function DHub.EventBossPriority:Claim()
    if not self:CanTakeover() then
        return false
    end

    self.active = true

    pcall(function()
        if DHub.MovementService then
            DHub.MovementService:Cancel("MainFarm")
            DHub.MovementService:Cancel("Fuse")
        end
    end)

    pcall(function()
        if isPlayerOnTreadmill() then
            -- treadmill release deferred until an actual Safezone route
        end
    end)

    self:_Touch()
    return true
end

function DHub.EventBossPriority:ShouldPauseMainFarm()
    if self.active == true then
        return true
    end

    if self.requested ~= true then
        return false
    end

    return not self:IsMainFarmBusy()
end

-- ============================================================
-- DR. SCRAMBLE WAVE PRIORITY ARBITER
--
-- Auto Wave never disables Auto Farm.
-- It only pauses Main Farm when a live wave needs control.
-- If an egg is already being processed (or one valid target is
-- already present exactly when the wave starts), that one egg
-- is allowed to finish first.
-- ============================================================

DHub.EventWavePriority = DHub.EventWavePriority or {
    requested = false,
    active = false,
    graceUid = nil,
    revision = 0,

    eggFirstWaitingReset = false,
    eggFirstProbeUntil = 0,
    eggFirstLastProbeAt = 0,
}

function DHub.EventWavePriority:_Touch()
    self.revision = (self.revision or 0) + 1

    if DHub.FarmCoordinator
        and DHub.FarmCoordinator.Wake
    then
        DHub.FarmCoordinator:Wake()
    end
end

function DHub.EventWavePriority:_ClearEggFirstProbe()
    self.eggFirstWaitingReset = false
    self.eggFirstProbeUntil = 0
    self.eggFirstLastProbeAt = 0
end

function DHub.EventWavePriority:_RefreshGrace()
    if not self.graceUid then
        return false
    end

    local target = nil

    pcall(function()
        target = DHub.FarmCoordinator:GetFieldTarget({
            preferUid = self.graceUid,
        })
    end)

    if target
        and target.uid
        and tostring(target.uid) == tostring(self.graceUid)
    then
        return true
    end

    self.graceUid = nil
    return false
end

function DHub.EventWavePriority:_ProbeFilteredEggFirst()
    if self.requested ~= true
        or self.active == true
        or not Cfg.autoFarm
        or not EventCfg.autoWave
    then
        return false
    end

    if self.graceUid
        and self:_RefreshGrace()
    then
        return true
    end

    local resetService =
        DHub.ResetBarrierService

    if self.eggFirstWaitingReset then
        if resetService
            and resetService:IsSealed()
        then
            return true
        end

        self.eggFirstWaitingReset = false
        self.eggFirstProbeUntil =
            tick() + 2.25
        self.eggFirstLastProbeAt = 0
    end

    if (tonumber(self.eggFirstProbeUntil) or 0) <= 0
        or tick() > self.eggFirstProbeUntil
    then
        return false
    end

    if tick()
        - (tonumber(self.eggFirstLastProbeAt) or 0)
        >= 0.15
    then
        self.eggFirstLastProbeAt = tick()

        pcall(function()
            if DHub.GlobalEggScanner
                and DHub.GlobalEggScanner.Resync
            then
                DHub.GlobalEggScanner:Resync()
            end
        end)

        pcall(function()
            if DHub.TargetSelector then
                DHub.TargetSelector.staticBestDirty = true
            end
        end)
    end

    local target = nil

    pcall(function()
        target =
            DHub.FarmCoordinator:GetFieldTarget()
    end)

    if target and target.uid then
        self.graceUid =
            tostring(target.uid)

        self.eggFirstProbeUntil = 0
        self.eggFirstWaitingReset = false

        self:_Touch()
        return true
    end

    return tick()
        <= (tonumber(self.eggFirstProbeUntil) or 0)
end

function DHub.EventWavePriority:BeginRequest()
    if not (
        EventCfg.autoWave
        or EventCfg.autoDoubleBat
    ) then
        return
    end

    local firstRequest =
        self.requested ~= true

    self.requested = true

    if firstRequest then
        self.active = false
        self.graceUid = nil
        self:_ClearEggFirstProbe()

        local currentlyBusy =
            isCarryingEgg()
            or Runtime.carryEscapeActive
            or PlotRuntime.placing
            or (
                DHub.FarmCoordinator
                and DHub.FarmCoordinator:HasTarget()
            )

        if Cfg.autoFarm
            and EventCfg.autoWave
            and not currentlyBusy
        then
            local resetService =
                DHub.ResetBarrierService

            if resetService
                and resetService:IsSealed()
            then
                self.eggFirstWaitingReset = true
            else
                self.eggFirstProbeUntil =
                    tick() + 1.25
            end

            self:_ProbeFilteredEggFirst()
        end

        self:_Touch()
    end
end

function DHub.EventWavePriority:EndRequest()
    local changed =
        self.requested == true
        or self.active == true
        or self.graceUid ~= nil
        or self.eggFirstWaitingReset == true
        or (tonumber(self.eggFirstProbeUntil) or 0) > 0

    self.requested = false
    self.active = false
    self.graceUid = nil
    self:_ClearEggFirstProbe()

    if changed then
        self:_Touch()
    end
end

function DHub.EventWavePriority:IsMainFarmBusy()
    if isCarryingEgg()
        or Runtime.carryEscapeActive
        or PlotRuntime.placing
    then
        return true
    end

    if DHub.FarmCoordinator
        and DHub.FarmCoordinator:HasTarget()
    then
        return true
    end

    if Cfg.autoFarm
        and DHub.TargetSelector
        and DHub.TargetSelector.HasFarmCandidate
        and DHub.TargetSelector:HasFarmCandidate()
    then
        return true
    end

    if not self.active
        and self.graceUid
        and self:_RefreshGrace()
    then
        return true
    end

    if not self.active
        and self:_ProbeFilteredEggFirst()
    then
        return true
    end

    return false
end

function DHub.EventWavePriority:ShouldPauseMainFarm()
    if DHub.EventBossPriority
        and DHub.EventBossPriority:ShouldPauseMainFarm()
    then
        return true
    end

    if self.active == true then
        return true
    end

    if DHub.RiftFusePriorityActive == true
        and not self:IsMainFarmBusy()
    then
        return true
    end

    if self.requested ~= true then
        return false
    end

    return not self:IsMainFarmBusy()
end

function DHub.EventWavePriority:CanTakeover()
    if DHub.EventBossPriority
        and DHub.EventBossPriority.requested == true
    then
        return false
    end

    if self.requested ~= true then
        return false
    end

    if self.active == true then
        return true
    end

    return not self:IsMainFarmBusy()
end

function DHub.EventWavePriority:Claim()
    if not self:CanTakeover() then
        return false
    end

    self.active = true
    self.graceUid = nil
    self:_ClearEggFirstProbe()

    pcall(function()
        if DHub.MovementService then
            DHub.MovementService:Cancel("MainFarm")
        end
    end)

    pcall(function()
        if isPlayerOnTreadmill() then
            -- treadmill release deferred until an actual Safezone route
        end
    end)

    self:_Touch()
    return true
end

local DoubleBatQuest

local ScrambleFarm = (function()
    -- ============================================================
    -- DR. SCRAMBLE AUTO WAVE — GLOBAL DRONE CACHE
    --
    -- Runtime scan proved that combat drones are virtual entities.
    -- The GLOBAL source of truth is RE/Scramble/Drones.
    -- Workspace.ScrambleLocalVisuals is only a nearby/local render.
    --
    -- FLOW:
    -- Wave starts
    --   -> FAST: bypass once
    --   -> Safezone
    --   -> select GLOBAL highest MaxHP/current HP (tie = nearest)
    --   -> TPWalk/Walk to live drone position
    --   -> stay inside auto-hit range
    --   -> body locks facing target
    --   -> if drone moves out of range, follow it again
    --   -> HP 0 / Death / Removed -> next global target
    -- Wave ends
    --   -> stop + restore body rotation
    --   -> idle until next wave
    --
    -- ============================================================

    local State = {
        running = false,
        generation = 0,

        -- uid -> virtual drone record from RE/Scramble/Drones.
        drones = {},

        currentTarget = nil,
        currentUid = nil,

        waveStarted = false,
        windowActive = false,
        samples = 0,
        nextWindowAt = nil,

        lastSnapshotAt = 0,
        lastSnapshot = nil,

        infoLabel = nil,

        visualFolder = nil,
        visualConnections = {},
        droneRemoteConnection = nil,

        lockedHumanoid = nil,
        lockedAutoRotate = nil,

        dualBatPrimary = nil,
        dualBatScrambler = nil,
        dualBatCurrent = nil,
        dualBatActive = false,
        lastDualBatSwapAt = 0,

        feedProbeIndex = 2,
        lastFeedProbeAt = 0,
        feedProbeActive = false,
    }

    State.resetDualBat = function()
        State.dualBatPrimary = nil
        State.dualBatScrambler = nil
        State.dualBatCurrent = nil
        State.dualBatActive = false
        State.lastDualBatSwapAt = 0
    end

    State.findDualBats = function()
        local char = LP.Character
        local backpack = LP:FindFirstChild("Backpack")

        if not char then
            State.resetDualBat()
            return nil, nil
        end

        local function isScrambler(tool)
            return tool
                and tool:IsA("Tool")
                and tool.Name:lower():find(
                    "scrambler",
                    1,
                    true
                ) ~= nil
        end

        local function isBatLike(tool)
            if not tool or not tool:IsA("Tool") then
                return false
            end

            local name = tool.Name:lower()

            return tool:GetAttribute("IsBat") == true
                or name:find("bat", 1, true) ~= nil
                or name:find("scrambler", 1, true) ~= nil
        end

        local primary = nil
        local scrambler = nil

        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if isScrambler(tool) then
                    scrambler = scrambler or tool
                elseif isBatLike(tool) then
                    primary = primary or tool
                end
            end
        end

        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    if isScrambler(tool) then
                        scrambler = scrambler or tool
                    elseif isBatLike(tool) then
                        primary = primary or tool
                    end
                end
            end
        end

        if not primary
            or not scrambler
            or primary == scrambler
        then
            State.resetDualBat()
            return nil, nil
        end

        State.dualBatPrimary = primary
        State.dualBatScrambler = scrambler
        State.dualBatActive = true

        return primary, scrambler
    end

    State.getDualBatTrigger = function()
        if State.dualBatToolTrigger
            and State.dualBatToolTrigger.Parent
        then
            return State.dualBatToolTrigger
        end

        pcall(function()
            State.dualBatToolTrigger =
                S.ReplicatedStorage
                    .Packages
                    .Networking[
                        "RE/ToolTrigger/Trigger"
                    ]
        end)

        return State.dualBatToolTrigger
    end

    State.fireDualBatHit = function(tool)
        if not tool
            or not tool.Parent
            or not tool:IsA("Tool")
        then
            return false
        end

        local char = LP.Character

        if not char or tool.Parent ~= char then
            return false
        end

        local name = tool.Name:lower()

        if name:find(
            "scrambler",
            1,
            true
        ) then
            local remote =
                State.getDualBatTrigger()

            if remote
                and remote:IsA("RemoteEvent")
            then
                return pcall(function()
                    remote:FireServer(tool)
                end)
            end

            return false
        end

        return pcall(function()
            tool:Activate()
        end)
    end

    State.tickDualBatSwap = function()
        local char = LP.Character
        local hum = getHumanoid()

        if not char
            or not hum
            or hum.Health <= 0
        then
            State.resetDualBat()
            return false
        end

        local primary = State.dualBatPrimary
        local scrambler = State.dualBatScrambler

        if not primary
            or not primary.Parent
            or not scrambler
            or not scrambler.Parent
        then
            primary, scrambler =
                State.findDualBats()
        end

        if not primary or not scrambler then
            return false
        end

        local equipped = nil

        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                equipped = tool
                break
            end
        end

        if not State.dualBatCurrent then
            if equipped == primary
                or equipped == scrambler
            then
                State.dualBatCurrent = equipped
            else
                pcall(function()
                    hum:EquipTool(primary)
                end)

                if primary.Parent == char then
                    State.dualBatCurrent = primary
                else
                    return false
                end
            end

            State.fireDualBatHit(
                State.dualBatCurrent
            )

            State.lastDualBatSwapAt = tick()
            return true
        end

        if tick()
            - (State.lastDualBatSwapAt or 0)
            < 0.14
        then
            return true
        end

        local nextTool =
            State.dualBatCurrent == primary
            and scrambler
            or primary

        if not nextTool
            or not nextTool.Parent
        then
            State.resetDualBat()
            return false
        end

        pcall(function()
            hum:EquipTool(nextTool)
        end)

        if nextTool.Parent ~= char then
            return false
        end

        State.dualBatCurrent = nextTool
        State.lastDualBatSwapAt = tick()

        State.fireDualBatHit(nextTool)

        return true
    end

    local SAFEZONE_STOP_DISTANCE = 5

    -- Runtime scan: automatic hits occur within about 12 studs.
    local APPROACH_STOP_DISTANCE = 7
    local FOLLOW_REENGAGE_DISTANCE = 10.5

    local SNAPSHOT_INTERVAL = 0.25

    -- ------------------------------------------------------------
    -- Generic payload decoding
    -- ------------------------------------------------------------

    local function positionFromValue(value)
        local valueType = typeof(value)

        if valueType == "CFrame" then
            return value.Position
        end

        if valueType == "Vector3" then
            return value
        end

        if type(value) == "table" then
            if typeof(value.Position) == "Vector3" then
                return value.Position
            end

            if typeof(value.CFrame) == "CFrame" then
                return value.CFrame.Position
            end

            local x =
                tonumber(value.X)
                or tonumber(value.x)
                or tonumber(value[1])

            local y =
                tonumber(value.Y)
                or tonumber(value.y)
                or tonumber(value[2])

            local z =
                tonumber(value.Z)
                or tonumber(value.z)
                or tonumber(value[3])

            if x and y and z then
                return Vector3.new(x, y, z)
            end
        end

        -- RemoteSpy/decompiler dumps may stringify CFrame as:
        -- "5972.4, 73.8, -329.7, ..."
        if type(value) == "string" then
            local numbers = {}

            for n in value:gmatch("[-+]?%d*%.?%d+") do
                numbers[#numbers + 1] = tonumber(n)

                if #numbers >= 3 then
                    break
                end
            end

            if numbers[1]
                and numbers[2]
                and numbers[3]
            then
                return Vector3.new(
                    numbers[1],
                    numbers[2],
                    numbers[3]
                )
            end
        end

        return nil
    end

    local function payloadOwnerMatches(payload, upsert)
        local owner =
            (type(upsert) == "table"
                and tonumber(upsert.OwnerUserId))
            or (type(payload) == "table"
                and tonumber(payload.OwnerUserId))

        -- Some revisions may omit owner on an individual upsert.
        -- Only reject when an owner is explicitly present and different.
        return owner == nil
            or owner == tonumber(LP.UserId)
    end

    local function recordState(record)
        local attrs =
            record
            and type(record.attributes) == "table"
            and record.attributes
            or nil

        return tostring(
            (attrs and attrs.DroneState)
            or (record and record.state)
            or ""
        )
    end

    local function recordTier(record)
        local attrs =
            record
            and type(record.attributes) == "table"
            and record.attributes
            or nil

        return tostring(
            (attrs and attrs.ScrambleTier)
            or (record and record.tier)
            or "Drone"
        )
    end

    local function recordArea(record)
        local attrs =
            record
            and type(record.attributes) == "table"
            and record.attributes
            or nil

        return tostring(
            (attrs and attrs.ScrambleArea)
            or (record and record.area)
            or "Unknown"
        )
    end

    -- ------------------------------------------------------------
    -- Nearby visual fallback / realtime local HP
    -- ------------------------------------------------------------

    local function uidFromVisual(model)
        if not model or not model:IsA("Model") then
            return nil
        end

        local attr = model:GetAttribute("ScrambleDroneId")
        if attr ~= nil and tostring(attr) ~= "" then
            return tostring(attr)
        end

        return model.Name:match("^PersonalDrone_(.+)$")
    end

    local function visualHitbox(model)
        if not model
            or not model.Parent
            or not model:IsA("Model")
        then
            return nil
        end

        local hitbox = model:FindFirstChild("Hitbox")

        return hitbox
            and hitbox:IsA("BasePart")
            and hitbox
            or nil
    end

    local function syncRecordFromVisual(record)
        if not record then
            return
        end

        local visual = record.visual

        if not visual or not visual.Parent then
            visual = nil

            local folder = State.visualFolder
            if folder and record.uid then
                local candidate =
                    folder:FindFirstChild(
                        "PersonalDrone_" .. tostring(record.uid)
                    )

                if candidate and candidate:IsA("Model") then
                    visual = candidate
                    record.visual = candidate
                end
            end
        end

        local hitbox = visualHitbox(visual)
        if not hitbox then
            return
        end

        record.position = hitbox.Position

        local hp = tonumber(hitbox:GetAttribute("Health"))
        local maxHp = tonumber(hitbox:GetAttribute("MaxHealth"))

        if hp ~= nil then
            record.health = hp
        end

        if maxHp ~= nil then
            record.maxHealth = maxHp
        end

        local modelState =
            visual:GetAttribute("DroneState")
            or hitbox:GetAttribute("DroneState")

        if modelState ~= nil then
            record.state = tostring(modelState)
        end

        local tier =
            visual:GetAttribute("ScrambleTier")
            or hitbox:GetAttribute("ScrambleTier")

        if tier ~= nil then
            record.tier = tostring(tier)
        end

        local area =
            visual:GetAttribute("ScrambleArea")
            or hitbox:GetAttribute("ScrambleArea")

        if area ~= nil then
            record.area = tostring(area)
        end
    end

    local function attachVisual(model)
        if not model
            or not model:IsA("Model")
            or not model.Name:match("^PersonalDrone_.+$")
        then
            return
        end

        local uid = uidFromVisual(model)
        if not uid then
            return
        end

        local record = State.drones[uid]

        if not record then
            -- Fallback only. Global remote will overwrite/complete it
            -- as soon as an Upsert is received.
            record = {
                uid = uid,
                ownerUserId = LP.UserId,
                source = "visual_fallback",
                attributes = {},
                updatedAt = tick(),
            }

            State.drones[uid] = record
        end

        record.visual = model
        syncRecordFromVisual(record)
    end

    local function detachVisual(model)
        if not model or not model:IsA("Model") then
            return
        end

        local uid =
            uidFromVisual(model)
            or model.Name:match("^PersonalDrone_(.+)$")

        if not uid then
            return
        end

        local record = State.drones[uid]
        if not record then
            return
        end

        if record.visual == model then
            record.visual = nil
        end

        -- If this record was created only from a local render and the
        -- global feed has never confirmed it, removal means it is gone.
        if record.source == "visual_fallback" then
            record.health = 0
            record.state = "Death"
        end
    end

    local function disconnectVisualConnections()
        for _, conn in ipairs(State.visualConnections) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        table.clear(State.visualConnections)
    end

    local function bindVisualFolder(folder)
        if State.visualFolder == folder then
            return
        end

        disconnectVisualConnections()
        State.visualFolder = folder

        if not folder then
            return
        end

        for _, child in ipairs(folder:GetChildren()) do
            attachVisual(child)
        end

        local added =
            folder.ChildAdded:Connect(attachVisual)

        local removed =
            folder.ChildRemoved:Connect(detachVisual)

        table.insert(State.visualConnections, added)
        table.insert(State.visualConnections, removed)

        table.insert(ScriptConnections, added)
        table.insert(ScriptConnections, removed)
    end

    State.bindCurrentVisualFolder = function()
        local folder =
            S.Workspace:FindFirstChild(
                "ScrambleLocalVisuals"
            )

        if folder and folder:IsA("Folder") then
            if State.visualFolder ~= folder then
                bindVisualFolder(folder)
            else
                for _, child in ipairs(
                    folder:GetChildren()
                ) do
                    attachVisual(child)
                end
            end

            return true
        end

        if State.visualFolder then
            bindVisualFolder(nil)
        end

        return false
    end

    State.bindCurrentVisualFolder()

    local workspaceAdded =
        S.Workspace.ChildAdded:Connect(function(child)
            if child.Name == "ScrambleLocalVisuals"
                and child:IsA("Folder")
            then
                State.bindCurrentVisualFolder()
            end
        end)

    local workspaceRemoved =
        S.Workspace.ChildRemoved:Connect(function(child)
            if child == State.visualFolder then
                bindVisualFolder(nil)
            end
        end)

    table.insert(ScriptConnections, workspaceAdded)
    table.insert(ScriptConnections, workspaceRemoved)

    -- ------------------------------------------------------------
    -- GLOBAL RE/Scramble/Drones cache
    -- ------------------------------------------------------------

    local function removeGlobalDrone(uid)
        uid = uid and tostring(uid) or nil
        if not uid then
            return
        end

        State.drones[uid] = nil

        if State.currentUid == uid then
            State.currentTarget = nil
            State.currentUid = nil
        end
    end

    local function applyGlobalUpsert(payload, upsert)
        if type(upsert) ~= "table" then
            return
        end

        if not payloadOwnerMatches(payload, upsert) then
            return
        end

        local uid =
            upsert.Id
            or upsert.ID
            or upsert.Uid
            or upsert.UID

        if uid == nil then
            local attrs =
                type(upsert.Attributes) == "table"
                and upsert.Attributes
                or nil

            uid = attrs and attrs.ScrambleDroneId or nil
        end

        if uid == nil then
            return
        end

        uid = tostring(uid)

        local record = State.drones[uid]

        if not record then
            record = {
                uid = uid,
                attributes = {},
            }

            State.drones[uid] = record
        end

        record.source = "remote"
        record.ownerUserId =
            tonumber(upsert.OwnerUserId)
            or tonumber(payload.OwnerUserId)
            or record.ownerUserId

        if upsert.Health ~= nil then
            record.health = tonumber(upsert.Health)
                or record.health
        end

        if upsert.MaxHealth ~= nil then
            record.maxHealth = tonumber(upsert.MaxHealth)
                or record.maxHealth
        end

        local pos =
            positionFromValue(upsert.CFrame)
            or positionFromValue(upsert.Position)

        if pos then
            record.position = pos
        end

        if type(upsert.Attributes) == "table" then
            record.attributes = upsert.Attributes

            if upsert.Attributes.DroneState ~= nil then
                record.state =
                    tostring(upsert.Attributes.DroneState)
            end

            if upsert.Attributes.ScrambleTier ~= nil then
                record.tier =
                    tostring(upsert.Attributes.ScrambleTier)
            end

            if upsert.Attributes.ScrambleArea ~= nil then
                record.area =
                    tostring(upsert.Attributes.ScrambleArea)
            end
        end

        if upsert.ExpiresAt ~= nil then
            record.expiresAt = tonumber(upsert.ExpiresAt)
        end

        record.revision =
            tonumber(payload.Revision)
            or record.revision

        record.updatedAt = tick()

        -- If the local render already exists, use its exact hitbox/HP.
        local folder = State.visualFolder
        if folder then
            local visual =
                folder:FindFirstChild(
                    "PersonalDrone_" .. uid
                )

            if visual and visual:IsA("Model") then
                record.visual = visual
                syncRecordFromVisual(record)
            end
        end
    end

    local function applyDronePayload(payload)
        if type(payload) ~= "table" then
            return
        end

        local payloadOwner = tonumber(payload.OwnerUserId)
        if payloadOwner
            and payloadOwner ~= tonumber(LP.UserId)
        then
            return
        end

        local removed = payload.Removed
        if type(removed) == "table" then
            for _, entry in pairs(removed) do
                local uid = entry

                if type(entry) == "table" then
                    uid =
                        entry.Id
                        or entry.ID
                        or entry.Uid
                        or entry.UID
                end

                if uid ~= nil then
                    removeGlobalDrone(uid)
                end
            end
        end

        local upserts = payload.Upserts
        if type(upserts) == "table" then
            for _, upsert in pairs(upserts) do
                applyGlobalUpsert(payload, upsert)
            end
        end
    end

    State.ensureDroneRemoteConnection = function(forceReconnect)
        if not RMT.ScrambleDrones
            or not RMT.ScrambleDrones.Parent
            or not RMT.ScrambleDrones:IsA("RemoteEvent")
        then
            RMT.ScrambleDrones =
                _pnet("RE/Scramble/Drones")
        end

        if State.droneRemoteConnection then
            local connected = false

            pcall(function()
                connected =
                    State.droneRemoteConnection.Connected == true
            end)

            if connected and not forceReconnect then
                return true
            end

            pcall(function()
                State.droneRemoteConnection:Disconnect()
            end)

            State.droneRemoteConnection = nil
        end

        if not RMT.ScrambleDrones
            or not RMT.ScrambleDrones:IsA("RemoteEvent")
        then
            return false
        end

        State.droneRemoteConnection =
            RMT.ScrambleDrones.OnClientEvent:Connect(
                applyDronePayload
            )

        table.insert(
            ScriptConnections,
            State.droneRemoteConnection
        )

        return true
    end

    State.ensureDroneRemoteConnection(false)

    -- ------------------------------------------------------------
    -- Record helpers
    -- ------------------------------------------------------------

    local function recordPosition(record)
        if not record then
            return nil
        end

        syncRecordFromVisual(record)

        return record.position
    end

    local function recordHealth(record)
        if not record then
            return nil, nil
        end

        syncRecordFromVisual(record)

        return
            tonumber(record.health),
            tonumber(record.maxHealth)
    end

    local function recordAlive(record)
        if not record then
            return false
        end

        local hp = select(1, recordHealth(record))
        local state = recordState(record)

        return hp ~= nil
            and hp > 0
            and state ~= "Death"
    end

    local function countAliveDrones()
        local total = 0

        for _, record in pairs(State.drones) do
            if recordAlive(record) then
                total = total + 1
            end
        end

        return total
    end

    -- ------------------------------------------------------------
    -- UI + event window snapshot
    -- ------------------------------------------------------------

    local function refreshInfoLabel()
        if not State.infoLabel then
            return
        end

        State.infoLabel.Text = string.format(
            "Wave: %s  |  Samples: %d  |  Robots: %d",
            State.windowActive and "ACTIVE" or "WAITING",
            tonumber(State.samples) or 0,
            countAliveDrones()
        )
    end

    local function setWindowActive(active)
        active = active == true

        local previous =
            State.windowActive == true

        State.windowActive = active

        if active and not previous then
            DHub.EventWavePriority:BeginRequest()

        elseif not active and previous then
            DHub.EventWavePriority:EndRequest()
        end
    end

    local function refreshSnapshot(force)
        local now = tick()

        if not force
            and now - (State.lastSnapshotAt or 0)
                < SNAPSHOT_INTERVAL
        then
            return State.lastSnapshot
        end

        State.lastSnapshotAt = now

        if not RMT.ScrambleRequest then
            setWindowActive(false)
            refreshInfoLabel()
            return nil
        end

        local ok, response = pcall(function()
            return RMT.ScrambleRequest:InvokeServer("snapshot")
        end)

        if not ok or type(response) ~= "table" then
            refreshInfoLabel()
            return State.lastSnapshot
        end

        local snapshot =
            type(response.Snapshot) == "table"
            and response.Snapshot
            or response

        if type(snapshot) == "table" then
            State.lastSnapshot = snapshot

            local window = snapshot.Window

            setWindowActive(
                type(window) == "table"
                and window.Active == true
            )

            State.nextWindowAt =
                type(window) == "table"
                and window.NextAt
                or nil

            local state = snapshot.State

            if type(state) == "table" then
                State.samples =
                    tonumber(state.Samples)
                    or State.samples
                    or 0
            end
        end

        refreshInfoLabel()
        return State.lastSnapshot
    end

    -- State broadcasts are used as a wake-up signal. The authoritative
    -- Window.Active value is still refreshed from the snapshot.
    if RMT.ScrambleState
        and RMT.ScrambleState:IsA("RemoteEvent")
    then
        local scrambleStateWake =
            RMT.ScrambleState.OnClientEvent:Connect(function()
                if (
                    EventCfg.autoWave
                    or EventCfg.autoDoubleBat
                ) and State.running
                then
                    task.defer(function()
                        if (
                            EventCfg.autoWave
                            or EventCfg.autoDoubleBat
                        ) and State.running
                        then
                            pcall(function()
                                refreshSnapshot(true)
                            end)
                        end
                    end)
                end
            end)

        table.insert(
            ScriptConnections,
            scrambleStateWake
        )
    end

    local function engineAlive(gen)
        local hum = getHumanoid()

        return (
                EventCfg.autoWave
                or EventCfg.autoDoubleBat
            )
            and State.running
            and State.generation == gen
            and hum ~= nil
            and hum.Health > 0
    end

    -- ------------------------------------------------------------
    -- Highest HP GLOBAL selector
    -- ------------------------------------------------------------

    local function selectBestDrone()
        local root = getRoot()

        local best = nil
        local bestUid = nil

        local nearestMode =
            DoubleBatQuest
            and EventCfg.autoDoubleBat
            and DoubleBatQuest.ShouldFarmDrones
            and DoubleBatQuest.ShouldFarmDrones() == true

        local bestDistance = math.huge
        local bestMaxHp = -math.huge
        local bestHp = -math.huge

        for uid, record in pairs(State.drones) do
            if recordAlive(record) then
                local pos = recordPosition(record)
                local hp, maxHp = recordHealth(record)

                if pos and hp then
                    maxHp = maxHp or hp

                    local distance =
                        root
                        and (root.Position - pos).Magnitude
                        or math.huge

                    local better = false

                    if nearestMode then
                        -- DronePart is pure server-side RNG at death.
                        -- No pre-death predictor exists, so maximize kills/minute.
                        better = distance < bestDistance
                    else
                        -- Preserve standalone Auto Wave behavior.
                        better =
                            maxHp > bestMaxHp
                            or (
                                maxHp == bestMaxHp
                                and hp > bestHp
                            )
                            or (
                                maxHp == bestMaxHp
                                and hp == bestHp
                                and distance < bestDistance
                            )
                    end

                    if better then
                        best = record
                        bestUid = uid
                        bestDistance = distance
                        bestMaxHp = maxHp
                        bestHp = hp
                    end
                end
            end
        end

        return best, bestUid
    end

    -- ------------------------------------------------------------
    -- Movement + body lock
    -- ------------------------------------------------------------

    local function restoreBodyLock()
        local hum = State.lockedHumanoid

        if hum
            and hum.Parent
            and State.lockedAutoRotate ~= nil
        then
            pcall(function()
                hum.AutoRotate = State.lockedAutoRotate
            end)
        end

        State.lockedHumanoid = nil
        State.lockedAutoRotate = nil
    end

    local function enableBodyLock()
        local hum = getHumanoid()
        if not hum then
            return
        end

        if State.lockedHumanoid ~= hum then
            restoreBodyLock()

            State.lockedHumanoid = hum
            State.lockedAutoRotate = hum.AutoRotate
        end

        pcall(function()
            hum.AutoRotate = false
        end)
    end

    local function facePosition(targetPos)
        if typeof(targetPos) ~= "Vector3" then
            return
        end

        local root = getRoot()
        if not root then
            return
        end

        local flatTarget =
            Vector3.new(
                targetPos.X,
                root.Position.Y,
                targetPos.Z
            )

        if (flatTarget - root.Position).Magnitude <= 0.08 then
            return
        end

        pcall(function()
            root.AssemblyAngularVelocity = Vector3.zero

            -- Rotate only. Position stays exactly where it is.
            root.CFrame =
                CFrame.lookAt(
                    root.Position,
                    flatTarget,
                    Vector3.new(0, 1, 0)
                )
        end)
    end

    local function stopMovement()
        if DHub.MovementService.currentOwner == "Event" then
            DHub.MovementService:Cancel("Event")
        end

        local root = getRoot()
        local hum = getHumanoid()

        if root then
            pcall(function()
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end

        if hum and root then
            pcall(function()
                hum:MoveTo(root.Position)
            end)
        end
    end

    local function ensureFastBypass()
        if Cfg.farmMethod ~= "Fast" then
            return true
        end

        if DHub.CharacterService:IsFastReady() then
            return true
        end

        UpdateEventStatus("Wave started -> bypass FAST...")

        return DHub.CharacterService:EnsureFastReady({
            timeout = 8,
        }) == true
    end

    local function moveToPosition(
        targetProvider,
        stopDistance,
        gen,
        targetRecord
    )
        local function shouldContinue()
            if not engineAlive(gen)
                or not State.windowActive
            then
                return false
            end

            if targetRecord
                and not recordAlive(targetRecord)
            then
                return false
            end

            return true
        end

        if Cfg.farmMethod == "Fast" then
            if not ensureFastBypass() then
                return false
            end

            return DHub.MovementService:MoveFast(
                targetProvider,
                {
                    owner = "Event",
                    priority = 80,
                    speed = Cfg.walkSpeed,
                    stopDistance =
                        stopDistance
                        or APPROACH_STOP_DISTANCE,
                    requireBypass = false,
                    shouldContinue = shouldContinue,
                    timeout = 35,
                }
            ) == true
        end

        local pos =
            type(targetProvider) == "function"
            and targetProvider()
            or targetProvider

        if typeof(pos) ~= "Vector3" then
            return false
        end

        return WalkToTarget(
            pos,
            stopDistance or APPROACH_STOP_DISTANCE,
            false,
            shouldContinue
        ) == true
    end

    local function moveToRecord(record, gen)
        restoreBodyLock()

        if not recordAlive(record) then
            return false
        end

        if Cfg.farmMethod == "Fast" then
            -- Dynamic provider: Fast TPWalk tracks the latest GLOBAL
            -- RE/Scramble/Drones CFrame while traveling across areas.
            return moveToPosition(
                function()
                    return recordPosition(record)
                end,
                APPROACH_STOP_DISTANCE,
                gen,
                record
            )
        end

        -- Normal movement is intentionally simple; if the drone moved,
        -- the tracking loop below immediately issues the next WalkToTarget.
        return moveToPosition(
            recordPosition(record),
            APPROACH_STOP_DISTANCE,
            gen,
            record
        )
    end

    local function startWaveRoute(gen)
        State.currentTarget = nil
        State.currentUid = nil

        restoreBodyLock()

        if Cfg.farmMethod == "Fast" then
            if not ensureFastBypass() then
                UpdateEventStatus(
                    "FAST bypass failed -> retrying wave start..."
                )
                return false
            end
        end

        if not engineAlive(gen)
            or not State.windowActive
        then
            return false
        end

        UpdateEventStatus(
            Cfg.farmMethod == "Fast"
                and "Wave started -> TPWalk Safezone..."
                or "Wave started -> Walk Safezone..."
        )

        local reached =
            moveToPosition(
                SAFEZONE_POS,
                SAFEZONE_STOP_DISTANCE,
                gen,
                nil
            )

        stopMovement()

        if reached
            and engineAlive(gen)
            and State.windowActive
        then
            State.ensureDroneRemoteConnection(false)
            State.bindCurrentVisualFolder()
            refreshSnapshot(true)
        end

        return reached
            and engineAlive(gen)
            and State.windowActive
    end

    -- ------------------------------------------------------------
    -- Track one selected drone until it dies.
    -- Character follows only when target exits the confirmed hit range.
    -- While inside range, movement stops and body faces the target.
    -- ------------------------------------------------------------

    local function farmSelectedDrone(record, gen)
        if not recordAlive(record) then
            return true
        end

        local lastStatusAt = 0
        local holding = false

        while engineAlive(gen)
            and State.windowActive
            and recordAlive(record)
        do
            local targetPos = recordPosition(record)
            local root = getRoot()

            if not targetPos or not root then
                restoreBodyLock()
                stopMovement()
                S.RunService.Heartbeat:Wait()
                continue
            end

            local distance =
                (root.Position - targetPos).Magnitude

            if distance > FOLLOW_REENGAGE_DISTANCE then
                holding = false
                restoreBodyLock()

                local hp, maxHp = recordHealth(record)

                UpdateEventStatus(string.format(
                    "Following %s [%d/%d] | %s | %.1f studs",
                    recordTier(record),
                    tonumber(hp) or 0,
                    tonumber(maxHp or hp) or 0,
                    recordArea(record),
                    distance
                ))

                moveToRecord(record, gen)

                if not engineAlive(gen)
                    or not State.windowActive
                    or not recordAlive(record)
                then
                    break
                end
            else
                if not holding then
                    stopMovement()
                    holding = true
                end

                enableBodyLock()
                facePosition(targetPos)

                State.tickDualBatSwap()

                if tick() - lastStatusAt >= 0.12 then
                    local hp, maxHp = recordHealth(record)

                    UpdateEventStatus(string.format(
                        State.dualBatActive
                            and "LOCK %s [%d/%d] | %s | %.1f studs | DUAL HIT+SWAP"
                            or "LOCK %s [%d/%d] | %s | %.1f studs",
                        recordTier(record),
                        tonumber(hp) or 0,
                        tonumber(maxHp or hp) or 0,
                        recordArea(record),
                        distance
                    ))

                    lastStatusAt = tick()
                end

                S.RunService.Heartbeat:Wait()
            end

            refreshSnapshot(false)
        end

        restoreBodyLock()
        stopMovement()

        return not recordAlive(record)
    end

    -- ------------------------------------------------------------
    -- Main worker
    -- ------------------------------------------------------------

    local function worker(gen)
        EventRuntime.activeSubEngine = "AutoWave"
        EventRuntime.running = true

        State.waveStarted = false
        State.resetDualBat()
        State.feedProbeIndex = 2
        State.lastFeedProbeAt = 0
        State.feedProbeActive = false

        UpdateEventStatus(
            "Idle -> watching Dr. Scramble wave..."
        )

        -- Always get a fresh state when the watcher starts.
        refreshSnapshot(true)

        while engineAlive(gen) do
            -- While idle we intentionally force a fresh snapshot each loop.
            -- This fixes Auto Wave being enabled before the event and then
            -- missing the later Window.Active transition.
            if not State.windowActive then
                refreshSnapshot(true)
            else
                refreshSnapshot(false)
            end

            -- ====================================================
            -- WAVE OFF / END
            -- ====================================================
            if not State.windowActive then
                if State.waveStarted then
                    State.waveStarted = false
                    State.currentTarget = nil
                    State.currentUid = nil

                    restoreBodyLock()
                    stopMovement()

                    State.drones = {}
                    State.resetDualBat()
                    State.feedProbeIndex = 2
                    State.lastFeedProbeAt = 0
                    State.feedProbeActive = false

                    UpdateEventStatus(
                        "Wave ended -> Idle, waiting next wave..."
                    )
                else
                    UpdateEventStatus(
                        "Idle -> watching next Dr. Scramble wave..."
                    )
                end

                task.wait(0.20)
                continue
            end

            -- ====================================================
            -- WAVE ACTIVE: request priority immediately.
            -- Current egg/carry is allowed to finish first.
            -- Idle/treadmill Main Farm yields immediately.
            -- ====================================================
            DHub.EventWavePriority:BeginRequest()

            if not State.waveStarted then
                if not DHub.EventWavePriority:Claim() then
                    UpdateEventStatus(
                        "Wave ACTIVE -> filtered egg priority first..."
                    )
                    task.wait(0.05)
                    continue
                end

                UpdateEventStatus(
                    "Wave ACTIVE -> Main Farm paused -> Safezone..."
                )

                local started = startWaveRoute(gen)

                if not started then
                    if not State.windowActive then
                        continue
                    end

                    task.wait(0.08)
                    continue
                end

                State.waveStarted = true

                UpdateEventStatus(
                    "Safezone reached -> waiting GLOBAL drone feed..."
                )
            end

            if not engineAlive(gen) then
                break
            end

            refreshSnapshot(false)

            if not State.windowActive then
                continue
            end

            -- ====================================================
            -- DOUBLE BAT QUEST STATE MACHINE
            --
            -- STRICT ORDER:
            --   LOST_PARTS -> DRONE_PARTS -> VAULT_CLAIM -> COMPLETED
            --
            -- Lost Parts always block drone farming until 2/2.
            -- Drone Parts reuse THIS ScrambleFarm engine.
            -- ====================================================
            if DoubleBatQuest
                and EventCfg.autoDoubleBat
            then
                local acted = false

                pcall(function()
                    acted =
                        DoubleBatQuest.RunWaveDetour(
                            function()
                                return engineAlive(gen)
                                    and State.windowActive
                            end
                        ) == true
                end)

                if acted then
                    State.currentTarget = nil
                    State.currentUid = nil
                    refreshSnapshot(true)

                    if not State.windowActive then
                        continue
                    end
                end

                local completed =
                    DoubleBatQuest.IsCompleted
                    and DoubleBatQuest.IsCompleted() == true

                if completed and not EventCfg.autoWave then
                    State.currentTarget = nil
                    State.currentUid = nil
                    restoreBodyLock()
                    stopMovement()
                    DHub.EventWavePriority:EndRequest()

                    UpdateEventStatus(
                        "Cave Quest completed -> Idle"
                    )

                    task.wait(0.20)
                    continue
                end

                local blocksDrone =
                    DoubleBatQuest.BlocksDroneFarm
                    and DoubleBatQuest.BlocksDroneFarm() == true

                if blocksDrone then
                    State.currentTarget = nil
                    State.currentUid = nil
                    restoreBodyLock()
                    stopMovement()

                    task.wait(0.05)
                    continue
                end

                -- If Double Bat is ON but it is not currently in the DroneParts
                -- phase, only standalone Auto Wave may continue killing drones.
                local stolenNeedsDrones =
                    DoubleBatQuest.ShouldFarmDrones
                    and DoubleBatQuest.ShouldFarmDrones() == true

                if not stolenNeedsDrones
                    and not EventCfg.autoWave
                then
                    State.currentTarget = nil
                    State.currentUid = nil
                    restoreBodyLock()
                    stopMovement()

                    task.wait(0.05)
                    continue
                end
            end

            -- GLOBAL target.
            -- Double Bat DroneParts phase = NEAREST FIRST.
            -- Standalone Auto Wave = existing high-HP priority.
            local target = State.currentTarget

            if not recordAlive(target) then
                local picked, uid =
                    selectBestDrone()

                target = picked
                State.currentTarget = picked
                State.currentUid = uid
            end

            if not target then
                restoreBodyLock()
                stopMovement()

                State.emptyDroneFeedSince =
                    State.emptyDroneFeedSince
                    or tick()

                if tick()
                    - (State.lastDroneFeedRecoveryAt or 0)
                    >= 0.35
                then
                    State.lastDroneFeedRecoveryAt = tick()

                    State.ensureDroneRemoteConnection(false)
                    State.bindCurrentVisualFolder()

                    pcall(function()
                        refreshSnapshot(true)
                    end)
                end

                if tick()
                    - State.emptyDroneFeedSince
                    >= 1.25
                    and tick()
                        - (State.lastFeedProbeAt or 0)
                        >= 0.75
                then
                    State.lastFeedProbeAt = tick()
                    State.feedProbeActive = true

                    if not ZONE_NAMES[State.feedProbeIndex] then
                        State.feedProbeIndex = 2
                    end

                    local probeArea =
                        ZONE_NAMES[State.feedProbeIndex]

                    if probeArea == "All"
                        or not ZONES[probeArea]
                    then
                        State.feedProbeIndex =
                            State.feedProbeIndex + 1

                        if not ZONE_NAMES[State.feedProbeIndex] then
                            State.feedProbeIndex = 2
                        end

                        probeArea =
                            ZONE_NAMES[State.feedProbeIndex]
                    end

                    local probePos =
                        probeArea
                        and ZONES[probeArea]
                        or nil

                    State.feedProbeIndex =
                        State.feedProbeIndex + 1

                    if not ZONE_NAMES[State.feedProbeIndex] then
                        State.feedProbeIndex = 2
                    end

                    if typeof(probePos) == "Vector3" then
                        UpdateEventStatus(
                            "Wave Robots 0 -> probing "
                            .. tostring(probeArea)
                            .. "..."
                        )

                        State.ensureDroneRemoteConnection(true)

                        moveToPosition(
                            probePos,
                            35,
                            gen,
                            nil
                        )

                        stopMovement()

                        State.bindCurrentVisualFolder()
                        State.ensureDroneRemoteConnection(false)

                        pcall(function()
                            refreshSnapshot(true)
                        end)

                        local probeDeadline =
                            tick() + 0.60

                        while engineAlive(gen)
                            and State.windowActive
                            and tick() < probeDeadline
                        do
                            State.bindCurrentVisualFolder()

                            if countAliveDrones() > 0 then
                                break
                            end

                            task.wait(0.08)
                        end
                    end

                    State.feedProbeActive = false
                else
                    UpdateEventStatus(
                        State.feedProbeActive
                            and "Wave Robots 0 -> probing arena feed..."
                            or "Wave active -> recovering GLOBAL robot feed..."
                    )

                    task.wait(0.08)
                end

                continue
            end

            State.emptyDroneFeedSince = nil
            State.feedProbeIndex = 2
            State.feedProbeActive = false

            local hp, maxHp = recordHealth(target)

            UpdateEventStatus(string.format(
                "GLOBAL target %s [%d/%d] | %s -> %s",
                recordTier(target),
                tonumber(hp) or 0,
                tonumber(maxHp or hp) or 0,
                recordArea(target),
                Cfg.farmMethod == "Fast"
                    and "TPWalk"
                    or "Walk"
            ))

            farmSelectedDrone(target, gen)

            if not recordAlive(target) then
                UpdateEventStatus(
                    (
                        DoubleBatQuest
                        and EventCfg.autoDoubleBat
                        and DoubleBatQuest.ShouldFarmDrones
                        and DoubleBatQuest.ShouldFarmDrones()
                    )
                    and "Robot defeated -> next NEAREST drone..."
                    or "Robot defeated -> selecting next GLOBAL high HP..."
                )
            end

            State.currentTarget = nil
            State.currentUid = nil

            task.wait(0.01)
        end

        restoreBodyLock()
        stopMovement()

        DHub.EventWavePriority:EndRequest()

        State.waveStarted = false
        State.currentTarget = nil
        State.currentUid = nil
        State.running = false

        EventRuntime.running = false
        EventRuntime.activeSubEngine = "Idle"

        UpdateEventStatus("Idle")
        refreshInfoLabel()
    end

    local function start()
        if State.running then
            return
        end

        if DHub.EventBossPriority
            and (
                DHub.EventBossPriority.requested == true
                or DHub.EventBossPriority.active == true
            )
        then
            return
        end

        State.running = true
        State.generation = State.generation + 1

        task.spawn(worker, State.generation)
    end

    local function stop()
        State.running = false
        State.generation = State.generation + 1

        State.waveStarted = false
        State.currentTarget = nil
        State.currentUid = nil

        restoreBodyLock()
        stopMovement()

        DHub.EventWavePriority:EndRequest()

        EventRuntime.running = false
        EventRuntime.activeSubEngine = "Idle"

        UpdateEventStatus("Idle")
        refreshInfoLabel()
    end

    return {
        State = State,
        Start = start,
        Stop = stop,

        RefreshSnapshot = function()
            return refreshSnapshot(true)
        end,

        GetSamples = function()
            refreshSnapshot(false)
            return tonumber(State.samples) or 0
        end,

        RefreshInfo = refreshInfoLabel,
    }
end)()

-- ============================================================
-- DR. SCRAMBLE AUTO BOSS
--
-- Confirmed live state:
--   Portal: Workspace.ScrambleArenaPortal -> touch Portal mesh
--   Arena:  Workspace.ScrambleArena
--
--   MECH:
--     Phase = "Mech"
--     Health / MaxHealth live on ScrambleArena attributes
--
--   BALL:
--     BallStunned authoritative vulnerability flag
--     CoreHealth / CoreMax / CoreStage
--     SpentCoil changes when a coil is destroyed
--
--   HUMAN:
--     Phase = "Human"
--     HumanHits / HumanNeeded
--
--   FINAL:
--     Phase = "Final"
--     server destroys ScrambleArena + auto returns player to lobby
--
-- Combat reuses the exact Auto Wave dual-bat engine.
-- No guessed Boss/Reward remotes are fired here.
-- ============================================================

DHub.AutoBoss = (function()
    local State = {
        running = false,
        generation = 0,
        active = false,
        stage = "WAIT_GATE",
        arena = nil,
        hadArena = false,
        spentSet = {},
        lastSpent = "",
        currentCoil = nil,
        entrySafezoneDone = false,
        coilGuidePos = nil,
        coilGuideName = nil,
        coilGuideSeenAt = 0,
        coilGuideScanAt = 0,
        coilAttempted = {},
        waveWasRunning = false,
        lastStatus = "",
    }

    local ATTACK_RANGE = 12.0
    local FOLLOW_STOP_SURFACE = 6.5
    local MOVE_REFRESH = 0.08
    local PORTAL_TIMEOUT = 12.0

    -- AUTO BOSS precision tuning.
    -- Coil phase: stand just OUTSIDE the selected coil so the Ball can ram
    -- through the player into the coil. Never MoveTo the coil center.
    local COIL_STAND_MARGIN = 3.35
    local COIL_STOP_DISTANCE = 1.60
    local COIL_BARRIER_PADDING = 1.85

    -- Human phase: continuously follow a close offset instead of alternating
    -- walk -> stop -> attack -> walk.
    local HUMAN_FOLLOW_STOP_SURFACE = 2.0
    local HUMAN_FOLLOW_MOVE_REFRESH = 0.045

    -- Infinity-Yield-style CanCollide noclip, scoped only to the boss arena.
    local ArenaNoclip = {
        active = false,
        connection = nil,
        heartbeatConnection = nil,
        originals = setmetatable({}, {__mode = "k"}),
    }

    function ArenaNoclip:_Apply(part)
        if not part
            or not part:IsA("BasePart")
        then
            return
        end

        if self.originals[part] == nil then
            self.originals[part] = part.CanCollide
        end

        if part.CanCollide then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end

    function ArenaNoclip:Start()
        if self.active then
            return
        end

        self.active = true

        local char = LP.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    self:_Apply(obj)
                end
            end
        end

        if self.connection then
            return
        end

        self.connection =
            S.RunService.Stepped:Connect(function()
                if not self.active
                    or not EventCfg.autoBoss
                then
                    return
                end

                local currentChar = LP.Character
                if not currentChar then
                    return
                end

                for _, obj in ipairs(
                    currentChar:GetDescendants()
                ) do
                    if obj:IsA("BasePart") then
                        self:_Apply(obj)
                    end
                end
            end)

        table.insert(
            ScriptConnections,
            self.connection
        )

        -- Reinforce on Heartbeat as well. Some arena/character controllers
        -- rewrite CanCollide between physics steps.
        if not self.heartbeatConnection then
            self.heartbeatConnection =
                S.RunService.Heartbeat:Connect(function()
                    if not self.active
                        or not EventCfg.autoBoss
                    then
                        return
                    end

                    local currentChar = LP.Character
                    if not currentChar then
                        return
                    end

                    for _, obj in ipairs(
                        currentChar:GetDescendants()
                    ) do
                        if obj:IsA("BasePart") then
                            self:_Apply(obj)
                        end
                    end
                end)

            table.insert(
                ScriptConnections,
                self.heartbeatConnection
            )
        end
    end

    function ArenaNoclip:Stop()
        self.active = false

        if self.connection then
            pcall(function()
                self.connection:Disconnect()
            end)
            self.connection = nil
        end

        if self.heartbeatConnection then
            pcall(function()
                self.heartbeatConnection:Disconnect()
            end)
            self.heartbeatConnection = nil
        end

        for part, oldCanCollide in pairs(
            self.originals
        ) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide =
                        oldCanCollide
                end)
            end
        end

        self.originals =
            setmetatable({}, {__mode = "k"})
    end

    local function setStatus(value)
        value = tostring(value or "Idle")

        if State.lastStatus == value then
            return
        end

        State.lastStatus = value

        UpdateEventStatus(
            "BOSS: " .. value
        )
    end

    local function stopCharacter()
        local root = getRoot()
        local hum = getHumanoid()

        if root and hum then
            pcall(function()
                hum:Move(
                    Vector3.zero,
                    false
                )

                hum:MoveTo(
                    root.Position
                )
            end)
        end
    end

    local function firstBasePart(obj)
        if not obj then
            return nil
        end

        if obj:IsA("BasePart") then
            return obj
        end

        return obj:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    local function findCombatPart(
        obj,
        preferredNames
    )
        if not obj or not obj.Parent then
            return nil
        end

        if obj:IsA("BasePart") then
            return obj
        end

        for _, name in ipairs(
            preferredNames or {}
        ) do
            local found =
                obj:FindFirstChild(
                    name,
                    true
                )

            if found
                and found:IsA("BasePart")
            then
                return found
            end
        end

        if obj:IsA("Model")
            and obj.PrimaryPart
        then
            return obj.PrimaryPart
        end

        return firstBasePart(obj)
    end

    local function surfaceDistance(
        part,
        worldPos
    )
        if not part
            or not part:IsA("BasePart")
            or typeof(worldPos) ~= "Vector3"
        then
            return math.huge
        end

        local localPos =
            part.CFrame:PointToObjectSpace(
                worldPos
            )

        local half = part.Size * 0.5

        local nearestLocal =
            Vector3.new(
                math.clamp(
                    localPos.X,
                    -half.X,
                    half.X
                ),
                math.clamp(
                    localPos.Y,
                    -half.Y,
                    half.Y
                ),
                math.clamp(
                    localPos.Z,
                    -half.Z,
                    half.Z
                )
            )

        local nearestWorld =
            part.CFrame:PointToWorldSpace(
                nearestLocal
            )

        return (
            nearestWorld - worldPos
        ).Magnitude
    end

    local function facePart(root, part)
        if not root
            or not part
            or not part.Parent
        then
            return
        end

        local target =
            Vector3.new(
                part.Position.X,
                root.Position.Y,
                part.Position.Z
            )

        if (
            target - root.Position
        ).Magnitude < 0.05
        then
            return
        end

        pcall(function()
            root.CFrame =
                CFrame.lookAt(
                    root.Position,
                    target
                )
        end)
    end

    local function dualHit()
        if not ScrambleFarm
            or not ScrambleFarm.State
            or not ScrambleFarm.State.tickDualBatSwap
        then
            return false
        end

        local ok, result =
            pcall(
                ScrambleFarm.State.tickDualBatSwap
            )

        return ok
            and result == true
    end

    local function coilAttackPulse()
        local state =
            ScrambleFarm
            and ScrambleFarm.State
            or nil

        if not state then
            return false
        end

        -- Keep the proven dual-bat swap engine alive.
        dualHit()

        -- Also fire the currently equipped bat as a continuous basic pulse.
        -- This removes the dead pause when standing directly at the Coil.
        if tick() - (State.lastCoilBasicAt or 0)
            < 0.075
        then
            return true
        end

        local char = LP.Character
        local hum = getHumanoid()

        if not char
            or not hum
            or hum.Health <= 0
        then
            return false
        end

        local tool = state.dualBatCurrent

        if not tool
            or not tool.Parent
            or tool.Parent ~= char
        then
            local primary = nil
            local scrambler = nil

            if state.findDualBats then
                primary, scrambler =
                    state.findDualBats()
            end

            for _, equipped in ipairs(
                char:GetChildren()
            ) do
                if equipped:IsA("Tool") then
                    tool = equipped
                    break
                end
            end

            if not tool then
                tool = primary or scrambler
            end

            if tool
                and tool.Parent ~= char
            then
                pcall(function()
                    hum:EquipTool(tool)
                end)
            end
        end

        if not tool
            or tool.Parent ~= char
        then
            return false
        end

        State.lastCoilBasicAt = tick()

        local fired = false

        if state.fireDualBatHit then
            pcall(function()
                fired =
                    state.fireDualBatHit(tool)
                    == true
            end)
        end

        -- Native/basic fallback. For the normal bat this is the game's own
        -- dynamic BatSwing path; for Scrambler the dual-bat primitive above
        -- already fires ToolTrigger.
        if not fired then
            local ok =
                pcall(function()
                    tool:Activate()
                end)

            fired = ok
        end

        return fired
    end

    local function gateAndPortal()
        local gate =
            S.Workspace:FindFirstChild(
                "ScrambleArenaPortal"
            )

        if not gate then
            return nil, nil
        end

        local portal =
            gate:FindFirstChild(
                "Portal",
                true
            )

        if portal
            and portal:IsA("BasePart")
        then
            return gate, portal
        end

        return gate, firstBasePart(gate)
    end

    local function arena()
        local value =
            S.Workspace:FindFirstChild(
                "ScrambleArena"
            )

        if value
            and value.Parent
        then
            return value
        end

        return nil
    end

    local function phase(currentArena)
        return tostring(
            currentArena
            and currentArena:GetAttribute(
                "Phase"
            )
            or ""
        )
    end

    local function isBallMechanicReady(currentArena)
        if not currentArena
            or not currentArena.Parent
        then
            return false
        end

        local p = phase(currentArena)

        if p == "Ball" then
            return true
        end

        -- Some runtime transitions can keep "Ejecting" briefly while the
        -- Ball + Coils mechanic is already replicated and interactive.
        if p == "Ejecting"
            and currentArena:FindFirstChild("Ball")
            and currentArena:FindFirstChild("Coils")
        then
            return true
        end

        return false
    end

    local function getArenaReferenceParts(currentArena)
        local parts = {}

        if not currentArena
            or not currentArena.Parent
        then
            return parts
        end

        local mech =
            currentArena:FindFirstChild("Mech")

        local mechPart =
            findCombatPart(
                mech,
                {
                    "Hitbox",
                    "RootPart",
                    "HumanoidRootPart",
                }
            )

        if mechPart then
            parts[#parts + 1] = mechPart
        end

        local ball =
            currentArena:FindFirstChild("Ball")

        local ballPart =
            findCombatPart(
                ball,
                {
                    "Hitbox",
                    "RootPart",
                    "HumanoidRootPart",
                    "DrScrambleBall",
                }
            )

        if ballPart then
            parts[#parts + 1] = ballPart
        end

        local human =
            currentArena:FindFirstChild(
                "ScrambleHuman"
            )

        local humanPart =
            findCombatPart(
                human,
                {
                    "Hitbox",
                    "HumanoidRootPart",
                    "RootPart",
                }
            )

        if humanPart then
            parts[#parts + 1] = humanPart
        end

        local coils =
            currentArena:FindFirstChild("Coils")

        if coils then
            for index = 1, 4 do
                local coil =
                    coils:FindFirstChild(
                        "Coil" .. tostring(index)
                    )

                local coilPart =
                    findCombatPart(
                        coil,
                        {
                            "Hitbox",
                            "RootPart",
                            "Core",
                            "Top",
                        }
                    )

                if coilPart then
                    parts[#parts + 1] =
                        coilPart
                end
            end
        end

        return parts
    end

    local function isPlayerInsideArena(
        currentArena
    )
        local root = getRoot()

        if not root
            or not currentArena
            or not currentArena.Parent
        then
            return false
        end

        local bestDistance = math.huge

        for _, part in ipairs(
            getArenaReferenceParts(
                currentArena
            )
        ) do
            if part
                and part.Parent
                and part:IsA("BasePart")
            then
                local distance =
                    (
                        root.Position
                        - part.Position
                    ).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                end
            end
        end

        -- Lobby is ~15k studs away from ScrambleArena in the current map.
        -- Arena combat itself spans only a few hundred studs.
        return bestDistance <= 1200
    end

    local function recordSpent(currentArena)
        if not currentArena then
            return
        end

        local spent =
            tostring(
                currentArena:GetAttribute(
                    "SpentCoil"
                )
                or ""
            )

        if spent ~= "" then
            State.spentSet[spent] = true
            State.lastSpent = spent
        end
    end

    local function coilLooksAlive(coil)
        if not coil
            or not coil.Parent
        then
            return false
        end

        if State.spentSet[coil.Name] then
            return false
        end

        local destroyed =
            coil:GetAttribute("Destroyed")

        local broken =
            coil:GetAttribute("Broken")

        local spent =
            coil:GetAttribute("Spent")

        local alive =
            coil:GetAttribute("Alive")

        local fixed =
            coil:GetAttribute("Fixed")

        if destroyed == true
            or broken == true
            or spent == true
            or alive == false
            or fixed == false
        then
            return false
        end

        local visiblePart = false

        for _, obj in ipairs(
            coil:GetDescendants()
        ) do
            if obj:IsA("BasePart")
                and obj.Transparency < 0.98
                and obj.Size.Magnitude > 0.25
            then
                visiblePart = true
                break
            end
        end

        return visiblePart
    end

    local COIL_FALLBACK_POSITIONS = {
        Coil1 = Vector3.new(-15310.31, -474.28, 5129.16),
        Coil2 = Vector3.new(-14758.93, -474.28, 5129.14),
        Coil3 = Vector3.new(-15310.33, -474.28, 4577.78),
        Coil4 = Vector3.new(-14758.95, -474.28, 4577.77),
    }

    local function directedCoilName(currentArena)
        if not currentArena then
            return nil
        end

        local raw =
            currentArena:GetAttribute(
                "BallCoil"
            )

        if raw == nil then
            return nil
        end

        local value = tostring(raw)

        local direct =
            value:match("(Coil%d+)")

        if not direct then
            local n =
                tonumber(
                    value:match("(%d+)")
                )

            if n and n >= 1 and n <= 4 then
                direct = "Coil" .. tostring(n)
            end
        end

        return direct
    end

    local function chooseCoil(currentArena)
        recordSpent(currentArena)

        local coils =
            currentArena
            and currentArena:FindFirstChild(
                "Coils"
            )

        if not coils then
            State.currentCoil = nil
            return nil, nil
        end

        -- 1) Prefer the server-directed coil whenever BallCoil exposes it.
        local directed =
            directedCoilName(currentArena)

        if directed
            and not State.spentSet[directed]
            and not State.coilAttempted[
                directed
            ]
        then
            local coil =
                coils:FindFirstChild(
                    directed
                )

            if coil and coil.Parent then
                State.currentCoil = coil
                return coil, directed
            end
        end

        -- 2) If BallCoil is briefly empty, prefer an intact/live visual coil.
        -- This avoids revisiting a visibly broken turret whose SpentCoil value
        -- is no longer the latest destroyed one.
        for index = 1, 4 do
            local coilName =
                "Coil" .. tostring(index)

            if not State.spentSet[coilName]
                and not State.coilAttempted[
                    coilName
                ]
            then
                local coil =
                    coils:FindFirstChild(
                        coilName
                    )

                if coil
                    and coil.Parent
                    and coilLooksAlive(
                        coil
                    )
                then
                    State.currentCoil = coil
                    return coil, coilName
                end
            end
        end

        -- 3) Final fallback: deterministic Coil1 -> Coil4.
        for index = 1, 4 do
            local coilName =
                "Coil" .. tostring(index)

            if not State.spentSet[coilName]
                and not State.coilAttempted[
                    coilName
                ]
            then
                local coil =
                    coils:FindFirstChild(
                        coilName
                    )

                State.currentCoil =
                    coil or coilName

                return coil, coilName
            end
        end

        State.currentCoil = nil
        return nil, nil
    end

    local function getCoilTargetPosition(
        currentArena,
        coil,
        coilName
    )
        coilName = tostring(coilName or "")

        -- Prefer the replicated Home coordinate if this revision exposes it.
        if coil and coil.Parent then
            local home = nil

            pcall(function()
                home = coil:GetAttribute("Home")
            end)

            if typeof(home) == "Vector3" then
                return home
            end

            if typeof(home) == "CFrame" then
                return home.Position
            end
        end

        -- The arena is static in the current build. These positions came from
        -- the live Coil scan and are more stable than a broken/animated model pivot.
        local fallback =
            COIL_FALLBACK_POSITIONS[
                coilName
            ]

        if typeof(fallback) == "Vector3" then
            return fallback
        end

        if coil and coil.Parent then
            if coil:IsA("BasePart") then
                return coil.Position
            end

            if coil:IsA("Model") then
                local ok, pivot =
                    pcall(function()
                        return coil:GetPivot()
                    end)

                if ok
                    and typeof(pivot)
                        == "CFrame"
                then
                    return pivot.Position
                end
            end

            local part =
                coil:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if part then
                return part.Position
            end
        end

        return nil
    end

    local function getCoilFacingPart(
        coil
    )
        if not coil
            or typeof(coil) ~= "Instance"
            or not coil.Parent
        then
            return nil
        end

        local preferred = {
            "Hitbox",
            "RootPart",
            "Core",
            "Top",
        }

        for _, name in ipairs(preferred) do
            local part =
                coil:FindFirstChild(
                    name,
                    true
                )

            if part
                and part:IsA("BasePart")
            then
                return part
            end
        end

        return coil:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    local function getBallFacingPart(
        currentArena
    )
        if not currentArena
            or not currentArena.Parent
        then
            return nil
        end

        local ball =
            currentArena:FindFirstChild(
                "Ball"
            )

        local drBall =
            ball
            and ball:FindFirstChild(
                "DrScrambleBall",
                true
            )
            or nil

        return findCombatPart(
            drBall or ball,
            {
                "Hitbox",
                "RootPart",
                "HumanoidRootPart",
                "Core",
                "Glass",
            }
        )
    end

    local function getCoilStandPosition(
        currentArena,
        coil,
        coilName,
        root
    )
        coilName =
            tostring(coilName or "")

        -- Keep one stable guide for the currently selected coil. This prevents
        -- the target point from jumping to the opposite side while the Ball
        -- moves during its charge animation.
        if State.coilGuideName
            == coilName
            and typeof(
                State.coilGuidePos
            ) == "Vector3"
        then
            return State.coilGuidePos
        end

        local coilPart =
            getCoilFacingPart(
                coil
            )

        local coilCenter =
            coilPart
            and coilPart.Position
            or getCoilTargetPosition(
                currentArena,
                coil,
                coilName
            )

        if typeof(coilCenter)
            ~= "Vector3"
        then
            return nil
        end

        local direction = nil

        -- Best mechanic-aware side:
        -- player must stand BETWEEN Ball and Coil.
        local ballPart =
            getBallFacingPart(
                currentArena
            )

        if ballPart
            and ballPart.Parent
        then
            local delta =
                Vector3.new(
                    ballPart.Position.X
                        - coilCenter.X,
                    0,
                    ballPart.Position.Z
                        - coilCenter.Z
                )

            if delta.Magnitude
                > 0.25
            then
                direction =
                    delta.Unit
            end
        end

        -- Fallback: remain on the same side from which the character approached.
        if not direction
            and root
        then
            local delta =
                Vector3.new(
                    root.Position.X
                        - coilCenter.X,
                    0,
                    root.Position.Z
                        - coilCenter.Z
                )

            if delta.Magnitude
                > 0.25
            then
                direction =
                    delta.Unit
            end
        end

        if not direction then
            direction =
                Vector3.new(
                    0,
                    0,
                    -1
                )
        end

        -- Use the selected coil's physical horizontal size as a conservative
        -- radius. This keeps the desired point outside the model even though
        -- character noclip remains enabled for other arena geometry.
        local radius = 4.0

        if coilPart
            and coilPart:IsA(
                "BasePart"
            )
        then
            radius =
                math.max(
                    coilPart.Size.X,
                    coilPart.Size.Z
                ) * 0.5
        elseif coil
            and coil:IsA("Model")
        then
            local ok, size =
                pcall(function()
                    return coil:GetExtentsSize()
                end)

            if ok
                and typeof(size)
                    == "Vector3"
            then
                radius =
                    math.max(
                        size.X,
                        size.Z
                    ) * 0.5
            end
        end

        local standDistance =
            radius
            + COIL_STAND_MARGIN

        local y =
            root
            and root.Position.Y
            or coilCenter.Y

        local standPos =
            Vector3.new(
                coilCenter.X
                    + direction.X
                        * standDistance,
                y,
                coilCenter.Z
                    + direction.Z
                        * standDistance
            )

        State.coilGuideName =
            coilName

        State.coilGuidePos =
            standPos

        State.coilGuideSeenAt =
            tick()

        return standPos
    end

    local function enforceCoilBarrier(
        currentArena,
        coil,
        coilName,
        root
    )
        if not root
            or not root.Parent
        then
            return nil
        end

        local coilPart =
            getCoilFacingPart(
                coil
            )

        local coilCenter =
            coilPart
            and coilPart.Position
            or getCoilTargetPosition(
                currentArena,
                coil,
                coilName
            )

        local standPos =
            getCoilStandPosition(
                currentArena,
                coil,
                coilName,
                root
            )

        if typeof(coilCenter)
            ~= "Vector3"
            or typeof(standPos)
                ~= "Vector3"
        then
            return standPos
        end

        local radius = 4.0

        if coilPart
            and coilPart:IsA(
                "BasePart"
            )
        then
            radius =
                math.max(
                    coilPart.Size.X,
                    coilPart.Size.Z
                ) * 0.5
        end

        local minimumRadius =
            radius
            + COIL_BARRIER_PADDING

        local flatDelta =
            Vector3.new(
                root.Position.X
                    - coilCenter.X,
                0,
                root.Position.Z
                    - coilCenter.Z
            )

        -- Virtual collision wall:
        -- if noclip lets the character enter/cross the coil body, immediately
        -- return to the safe outside guide point. This affects Coil only.
        if flatDelta.Magnitude
            < minimumRadius
        then
            local safe =
                Vector3.new(
                    standPos.X,
                    root.Position.Y,
                    standPos.Z
                )

            local look =
                Vector3.new(
                    coilCenter.X,
                    root.Position.Y,
                    coilCenter.Z
                )

            pcall(function()
                root.CFrame =
                    CFrame.lookAt(
                        safe,
                        look
                    )

                root.AssemblyLinearVelocity =
                    Vector3.zero

                root.AssemblyAngularVelocity =
                    Vector3.zero
            end)
        end

        return standPos
    end

    local function attackCoilUntilOpen(
        currentArena,
        coil,
        coilName
    )
        if not currentArena
            or not currentArena.Parent
            or not coilName
        then
            return false
        end

        coilName = tostring(coilName)

        -- Noclip is scoped ONLY to Coil phase.
        ArenaNoclip:Start()
        State.lastCoilBasicAt = 0

        pcall(function()
            if ScrambleFarm
                and ScrambleFarm.State
                and ScrambleFarm.State.resetDualBat
            then
                ScrambleFarm.State.resetDualBat()
            end
        end)

        local targetPos =
            getCoilStandPosition(
                currentArena,
                coil,
                coilName,
                getRoot()
            )

        if typeof(targetPos) ~= "Vector3" then
            State.coilAttempted[
                coilName
            ] = true

            setStatus(
                coilName
                .. " -> no position, ignored"
            )

            return false
        end

        local beforeSpent =
            tostring(
                currentArena:GetAttribute(
                    "SpentCoil"
                )
                or ""
            )

        local function directedChanged()
            local directed =
                directedCoilName(
                    currentArena
                )

            return directed
                and directed ~= coilName
                and not State.spentSet[
                    directed
                ]
                and not State.coilAttempted[
                    directed
                ]
        end

        local function faceTarget(
            root,
            livePos
        )
            local facingPart =
                getCoilFacingPart(coil)

            if facingPart then
                facePart(
                    root,
                    facingPart
                )

                return
            end

            if root
                and typeof(livePos)
                    == "Vector3"
            then
                local flatTarget =
                    Vector3.new(
                        livePos.X,
                        root.Position.Y,
                        livePos.Z
                    )

                if (
                    flatTarget
                    - root.Position
                ).Magnitude > 0.05
                then
                    pcall(function()
                        root.CFrame =
                            CFrame.lookAt(
                                root.Position,
                                flatTarget
                            )
                    end)
                end
            end
        end

        setStatus(
            coilName
            .. " -> moving to active Coil"
        )

        -- Walk to the selected coil. Start dual-bat BEFORE full arrival as soon
        -- as the character is within practical Bat range.
        local approachDeadline =
            tick() + 20

        while EventCfg.autoBoss
            and State.running
            and currentArena.Parent
            and isBallMechanicReady(
                currentArena
            )
            and tick() < approachDeadline
        do
            if currentArena:GetAttribute(
                "BallStunned"
            ) == true
            then
                State.coilAttempted[
                    coilName
                ] = true

                State.currentCoil = nil
                State.coilGuideName = nil
                State.coilGuidePos = nil
                stopCharacter()
                -- Keep arena noclip alive across BallStunned transition.
                return true
            end

            -- If the server points at a different Coil while we are walking,
            -- immediately abandon this target WITHOUT blacklisting it.
            if directedChanged() then
                State.currentCoil = nil
                stopCharacter()

                setStatus(
                    coilName
                    .. " -> active Coil changed, retargeting"
                )

                return false
            end

            local root = getRoot()
            local hum = getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                ensureCharacter(8)
                task.wait(0.08)
                continue
            end

            targetPos =
                enforceCoilBarrier(
                    currentArena,
                    coil,
                    coilName,
                    root
                )
                or targetPos

            local flatDistance =
                Vector3.new(
                    targetPos.X
                        - root.Position.X,
                    0,
                    targetPos.Z
                        - root.Position.Z
                ).Magnitude

            setStatus(
                string.format(
                    "%s -> WALK+HIT | %.1f studs",
                    coilName,
                    flatDistance
                )
            )

            -- Start attacking on approach, so there is no dead pause when the
            -- character reaches the coil.
            if flatDistance <= 14.0 then
                faceTarget(
                    root,
                    targetPos
                )

                coilAttackPulse()
            end

            if flatDistance <= COIL_STOP_DISTANCE then
                stopCharacter()

                -- Immediate first hit on the exact arrival frame.
                faceTarget(
                    root,
                    targetPos
                )
                coilAttackPulse()

                break
            end

            pcall(function()
                hum:MoveTo(
                    Vector3.new(
                        targetPos.X,
                        root.Position.Y,
                        targetPos.Z
                    )
                )
            end)

            S.RunService.Heartbeat:Wait()
        end

        if not EventCfg.autoBoss
            or not State.running
            or not currentArena.Parent
            or not isBallMechanicReady(
                currentArena
            )
        then
            stopCharacter()
            return false
        end

        if directedChanged() then
            State.currentCoil = nil
            stopCharacter()
            return false
        end

        local arrivalRoot = getRoot()

        if not arrivalRoot then
            return false
        end

        targetPos =
            enforceCoilBarrier(
                currentArena,
                coil,
                coilName,
                arrivalRoot
            )
            or targetPos

        local arrivalDistance =
            Vector3.new(
                targetPos.X
                    - arrivalRoot.Position.X,
                0,
                targetPos.Z
                    - arrivalRoot.Position.Z
            ).Magnitude

        if arrivalDistance > 12 then
            State.coilAttempted[
                coilName
            ] = true

            State.currentCoil = nil

            setStatus(
                coilName
                .. " -> approach failed, ignored"
            )

            stopCharacter()
            return false
        end

        -- Prime the proven dual-bat engine BEFORE the 5 second timer.
        faceTarget(
            arrivalRoot,
            targetPos
        )
        coilAttackPulse()

        local attackEndsAt =
            tick() + 5.0

        setStatus(
            coilName
            .. " -> DUAL HIT 5s"
        )

        while EventCfg.autoBoss
            and State.running
            and currentArena.Parent
            and isBallMechanicReady(
                currentArena
            )
            and tick() < attackEndsAt
        do
            if currentArena:GetAttribute(
                "BallStunned"
            ) == true
            then
                State.coilAttempted[
                    coilName
                ] = true

                State.currentCoil = nil

                setStatus(
                    coilName
                    .. " -> BALL OPEN"
                )

                stopCharacter()
                return true
            end

            if directedChanged() then
                State.currentCoil = nil
                stopCharacter()

                setStatus(
                    coilName
                    .. " -> active Coil changed, retargeting"
                )

                return false
            end

            local nowSpent =
                tostring(
                    currentArena:GetAttribute(
                        "SpentCoil"
                    )
                    or ""
                )

            if nowSpent ~= ""
                and nowSpent ~= beforeSpent
            then
                State.spentSet[
                    nowSpent
                ] = true

                State.coilAttempted[
                    nowSpent
                ] = true

                State.lastSpent =
                    nowSpent

                if nowSpent == coilName then
                    State.currentCoil = nil
                end
            end

            local root = getRoot()
            local hum = getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                ensureCharacter(8)
                task.wait(0.08)
                continue
            end

            targetPos =
                enforceCoilBarrier(
                    currentArena,
                    coil,
                    coilName,
                    root
                )
                or targetPos

            local flatDistance =
                Vector3.new(
                    targetPos.X
                        - root.Position.X,
                    0,
                    targetPos.Z
                        - root.Position.Z
                ).Magnitude

            if flatDistance
                > COIL_STOP_DISTANCE
            then
                pcall(function()
                    hum:MoveTo(
                        Vector3.new(
                            targetPos.X,
                            root.Position.Y,
                            targetPos.Z
                        )
                    )
                end)
            else
                pcall(function()
                    hum:MoveTo(
                        root.Position
                    )
                end)
            end

            faceTarget(
                root,
                targetPos
            )

            -- Every Heartbeat reaches the same proven rate-limited swap engine.
            -- First hit happens immediately; the second bat follows at its
            -- existing ~0.14s swap cadence.
            coilAttackPulse()

            local remaining =
                math.max(
                    attackEndsAt - tick(),
                    0
                )

            setStatus(
                string.format(
                    "%s -> DUAL HIT %.1fs",
                    coilName,
                    remaining
                )
            )

            S.RunService.Heartbeat:Wait()
        end

        if currentArena.Parent
            and currentArena:GetAttribute(
                "BallStunned"
            ) == true
        then
            State.coilAttempted[
                coilName
            ] = true

            State.currentCoil = nil
            State.coilGuideName = nil
            State.coilGuidePos = nil

            stopCharacter()
            -- Keep arena noclip alive across BallStunned transition.
            return true
        end

        -- Five seconds with no Ball vulnerability means this coil position is
        -- treated as inactive for THIS encounter and the next candidate is used.
        State.coilAttempted[
            coilName
        ] = true

        State.currentCoil = nil

        setStatus(
            coilName
            .. " -> 5s no Ball, IGNORE -> next Coil"
        )

        stopCharacter()
        return false
    end

    local function followAndAttack(
        targetProvider,
        shouldContinue,
        statusProvider
    )
        local lastMoveAt = 0

        while EventCfg.autoBoss
            and State.running
        do
            if type(shouldContinue)
                == "function"
            then
                local ok, allowed =
                    pcall(
                        shouldContinue
                    )

                if not ok
                    or allowed ~= true
                then
                    break
                end
            end

            local targetPart = nil

            pcall(function()
                targetPart =
                    targetProvider()
            end)

            if not targetPart
                or not targetPart.Parent
                or not targetPart:IsA(
                    "BasePart"
                )
            then
                task.wait(0.05)
                continue
            end

            local root = getRoot()
            local hum = getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                ensureCharacter(8)
                task.wait(0.08)
                continue
            end

            local distance =
                surfaceDistance(
                    targetPart,
                    root.Position
                )

            if type(statusProvider)
                == "function"
            then
                local ok, label =
                    pcall(
                        statusProvider,
                        distance
                    )

                if ok and label then
                    setStatus(label)
                end
            end

            -- Keep walking toward the LIVE hitbox while still outside
            -- close combat range. This continuously refreshes MoveTo, so
            -- Human/Mech movement never uses a stale position.
            if distance
                > FOLLOW_STOP_SURFACE
            then
                if tick() - lastMoveAt
                    >= MOVE_REFRESH
                then
                    lastMoveAt = tick()

                    pcall(function()
                        hum:MoveTo(
                            targetPart.Position
                        )
                    end)
                end
            else
                pcall(function()
                    hum:MoveTo(
                        root.Position
                    )
                end)
            end

            -- Attack while approaching as soon as native Bat range is met.
            if distance <= ATTACK_RANGE then
                facePart(
                    root,
                    targetPart
                )

                dualHit()
            end

            S.RunService.Heartbeat:Wait()
        end

        stopCharacter()
    end

    local function releaseHumanRootLock()
        local root =
            getRoot()

        local hum =
            getHumanoid()

        if root then
            pcall(function()
                root.Anchored =
                    false

                root.AssemblyLinearVelocity =
                    Vector3.zero

                root.AssemblyAngularVelocity =
                    Vector3.zero
            end)
        end

        if hum then
            pcall(function()
                hum.AutoRotate =
                    true

                hum.PlatformStand =
                    false

                hum.Sit =
                    false

                hum:ChangeState(
                    Enum.HumanoidStateType.Running
                )
            end)
        end
    end

    local function lockAndAttackHuman(
        currentArena,
        needed
    )
        -- HUMAN NATURAL FOLLOW:
        -- No Anchor, no positional CFrame lock, no character pin.
        -- Keep boss-arena noclip active, then use normal Humanoid:MoveTo
        -- against ScrambleHuman's LIVE hitbox while dualHit runs in range.
        ArenaNoclip:Start()

        releaseHumanRootLock()

        local lastMoveAt =
            0

        while EventCfg.autoBoss
            and State.running
            and currentArena
            and currentArena.Parent
            and phase(currentArena)
                == "Human"
        do
            local currentHits =
                tonumber(
                    currentArena:GetAttribute(
                        "HumanHits"
                    )
                )
                or 0

            local currentNeeded =
                tonumber(
                    currentArena:GetAttribute(
                        "HumanNeeded"
                    )
                )
                or needed
                or 3

            if currentHits
                >= currentNeeded
            then
                break
            end

            local human =
                currentArena:FindFirstChild(
                    "ScrambleHuman"
                )

            local targetPart =
                findCombatPart(
                    human,
                    {
                        "Hitbox",
                        "HumanoidRootPart",
                        "RootPart",
                    }
                )

            if not targetPart
                or not targetPart.Parent
            then
                stopCharacter()
                task.wait(0.035)
                continue
            end

            local root =
                getRoot()

            local hum =
                getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                releaseHumanRootLock()
                ensureCharacter(8)
                task.wait(0.05)
                continue
            end

            -- Always keep the player in a normal walking state.
            pcall(function()
                root.Anchored =
                    false

                hum.PlatformStand =
                    false

                hum.Sit =
                    false

                hum.AutoRotate =
                    true
            end)

            local distance =
                surfaceDistance(
                    targetPart,
                    root.Position
                )

            -- Follow the LIVE Human naturally.
            -- Refresh MoveTo frequently because ScrambleHuman moves.
            if distance
                > HUMAN_FOLLOW_STOP_SURFACE
            then
                if tick() - lastMoveAt
                    >= HUMAN_FOLLOW_MOVE_REFRESH
                then
                    lastMoveAt =
                        tick()

                    pcall(function()
                        hum:MoveTo(
                            targetPart.Position
                        )
                    end)
                end
            else
                -- Close enough to the hitbox surface: stop moving forward
                -- so we don't walk through/inside ScrambleHuman.
                pcall(function()
                    hum:MoveTo(
                        root.Position
                    )
                end)
            end

            -- Hit continuously while approaching / following.
            -- Only rotate in place toward the target; never reposition root.
            if distance <= ATTACK_RANGE then
                facePart(
                    root,
                    targetPart
                )

                dualHit()
            end

            setStatus(
                string.format(
                    "HUMAN FOLLOW %d/%d | dist %.1f",
                    currentHits,
                    currentNeeded,
                    distance
                )
            )

            S.RunService.Heartbeat:
                Wait()
        end

        releaseHumanRootLock()
        stopCharacter()
    end

    local function stageBossEntrySafezone(generation)
        if State.entrySafezoneDone then return true end

        local currentArena=arena()
        if currentArena and isPlayerInsideArena(currentArena) then
            State.entrySafezoneDone=true
            return true
        end

        if isPlayerOnTreadmill()
            or (DHub.TreadmillMount and DHub.TreadmillMount.active)
        then
            -- treadmill release deferred until an actual Safezone route
            task.wait(0.08)
        end

        setStatus("BOSS priority -> Safezone staging")

        local reached=WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            function()
                return EventCfg.autoBoss
                    and State.running
                    and State.generation==generation
                    and DHub.EventBossPriority
                    and DHub.EventBossPriority.active==true
            end
        )

        if reached then State.entrySafezoneDone=true end
        return reached==true
    end

    local function enterPortal(
        portal,
        generation
    )
        if not portal
            or not portal.Parent
        then
            return false
        end

        local deadline =
            tick() + PORTAL_TIMEOUT

        setStatus(
            "Gate detected -> walking into Portal"
        )

        while EventCfg.autoBoss
            and State.running
            and State.generation
                == generation
            and tick() < deadline
        do
            local currentArena =
                arena()

            if currentArena
                and isPlayerInsideArena(
                    currentArena
                )
            then
                stopCharacter()
                return true
            end

            if not portal
                or not portal.Parent
            then
                break
            end

            local root = getRoot()
            local hum = getHumanoid()

            if root
                and hum
                and hum.Health > 0
            then
                setStatus(
                    "ENTERING ARENA -> touch Portal"
                )

                pcall(function()
                    -- Arena model may already exist server-side while the
                    -- player is still in lobby. Keep physically walking INTO
                    -- the portal mesh until our character is actually near
                    -- ScrambleArena coordinates.
                    hum:MoveTo(
                        portal.Position
                    )
                end)
            else
                ensureCharacter(8)
            end

            S.RunService.Heartbeat:Wait()
        end

        stopCharacter()

        local currentArena =
            arena()

        return currentArena ~= nil
            and isPlayerInsideArena(
                currentArena
            )
    end

    local function pauseOtherScrambleCombat()
        State.waveWasRunning =
            ScrambleFarm
            and ScrambleFarm.State
            and ScrambleFarm.State.running
            == true
            or false

        if State.waveWasRunning
            and ScrambleFarm
            and ScrambleFarm.Stop
        then
            ScrambleFarm.Stop()
        end

        -- Clear any stale Wave request before Boss claims the shared event slot.
        if DHub.EventWavePriority then
            DHub.EventWavePriority:EndRequest()
        end
    end

    local function resumeOtherScrambleCombat()
        if not EventCfg.autoBoss then
            return
        end

        if EventCfg.autoWave
            or EventCfg.autoDoubleBat
        then
            pcall(
                ScrambleFarm.Start
            )
        end
    end

    local function beginEncounter()
        if State.active then
            return true
        end

        pauseOtherScrambleCombat()

        DHub.EventBossPriority:BeginRequest()

        if not DHub.EventBossPriority:Claim()
        then
            setStatus(
                "Gate ready -> waiting Farm Egg handoff"
            )
            return false
        end

        State.active = true
        State.spentSet = {}
        State.coilAttempted = {}
        State.lastSpent = ""
        State.currentCoil = nil
        State.entrySafezoneDone = false

        return true
    end

    local function finishEncounter(
        keepWaiting
    )
        releaseHumanRootLock()
        releaseHumanRootLock()
        stopCharacter()
        ArenaNoclip:Stop()

        State.active = false
        State.arena = nil
        State.currentCoil = nil
        State.coilGuidePos = nil
        State.coilGuideName = nil
        State.coilAttempted = {}
        State.spentSet = {}
        State.lastSpent = ""
        State.entrySafezoneDone = false
        State.hadArena = false

        DHub.EventBossPriority:EndRequest()

        if keepWaiting ~= false then
            setStatus(
                "Victory -> server returned lobby"
            )

            task.wait(0.35)

            resumeOtherScrambleCombat()

            setStatus(
                "Waiting boss gate"
            )
        end
    end

    local function stepArena(
        currentArena
    )
        State.arena = currentArena
        State.hadArena = true

        recordSpent(currentArena)

        local currentPhase =
            phase(currentArena)

        if currentPhase ~= "Human" then
            releaseHumanRootLock()
        end

        -- AUTO BOSS NOCLIP:
        -- Keep CanCollide=false continuously for the ENTIRE live arena
        -- encounter. Do not restore collisions between Coil -> vulnerable Ball
        -- -> Human transitions; doing so while the Ball has just launched the
        -- character can leave the root suspended/stuck on arena geometry.
        ArenaNoclip:Start()

        if currentPhase == "Mech" then
            State.stage = "MECH"

            local mech =
                currentArena:FindFirstChild(
                    "Mech"
                )

            local hp =
                tonumber(
                    currentArena:GetAttribute(
                        "Health"
                    )
                )
                or 0

            local maxHp =
                tonumber(
                    currentArena:GetAttribute(
                        "MaxHealth"
                    )
                )
                or hp

            if hp <= 0 then
                stopCharacter()

                setStatus(
                    "MECH 0/"
                    .. tostring(maxHp)
                    .. " -> waiting Eject"
                )

                task.wait(0.05)
                return
            end

            followAndAttack(
                function()
                    mech =
                        currentArena:FindFirstChild(
                            "Mech"
                        )

                    return findCombatPart(
                        mech,
                        {
                            "Hitbox",
                            "RootPart",
                            "HumanoidRootPart",
                        }
                    )
                end,
                function()
                    if not EventCfg.autoBoss
                        or not currentArena.Parent
                        or phase(currentArena)
                            ~= "Mech"
                    then
                        return false
                    end

                    local liveHp =
                        tonumber(
                            currentArena:GetAttribute(
                                "Health"
                            )
                        )
                        or 0

                    return liveHp > 0
                end,
                function(distance)
                    local liveHp =
                        tonumber(
                            currentArena:GetAttribute(
                                "Health"
                            )
                        )
                        or 0

                    local liveMax =
                        tonumber(
                            currentArena:GetAttribute(
                                "MaxHealth"
                            )
                        )
                        or maxHp

                    return string.format(
                        "MECH %d/%d | dist %.1f",
                        liveHp,
                        liveMax,
                        distance
                    )
                end
            )

            return
        end

        if currentPhase == "Ejecting"
            and not isBallMechanicReady(
                currentArena
            )
        then
            State.stage = "EJECTING"
            stopCharacter()
            setStatus(
                "MECH defeated -> waiting Ball/Coils"
            )
            task.wait(0.05)
            return
        end

        if isBallMechanicReady(
            currentArena
        ) then
            State.stage = "BALL"

            local rawCoreHealth =
                currentArena:GetAttribute(
                    "CoreHealth"
                )

            local coreHealth =
                tonumber(rawCoreHealth)

            local coreMax =
                tonumber(
                    currentArena:GetAttribute(
                        "CoreMax"
                    )
                )

            local ballModel =
                currentArena:FindFirstChild(
                    "Ball"
                )

            local humanModel =
                currentArena:FindFirstChild(
                    "ScrambleHuman"
                )

            -- CRITICAL:
            -- Before the first Coil opens the Ball, CoreHealth can be nil /
            -- unavailable. The old code converted that to 0 and returned here,
            -- so the Coil movement branch was NEVER reached.
            --
            -- Numeric 0 only means "core finished" when the Ball has actually
            -- disappeared or Human has already spawned.
            if coreHealth ~= nil
                and coreHealth <= 0
                and (
                    not ballModel
                    or humanModel ~= nil
                )
            then
                State.currentCoil = nil
                stopCharacter()

                setStatus(
                    "BALL core depleted -> waiting Human"
                )

                task.wait(0.05)
                return
            end

            local stunned =
                currentArena:GetAttribute(
                    "BallStunned"
                ) == true

            if stunned then
                State.currentCoil = nil

                followAndAttack(
                    function()
                        local ball =
                            currentArena:FindFirstChild(
                                "Ball"
                            )

                        local drBall =
                            ball
                            and ball:FindFirstChild(
                                "DrScrambleBall",
                                true
                            )
                            or nil

                        return findCombatPart(
                            drBall or ball,
                            {
                                "Hitbox",
                                "RootPart",
                                "HumanoidRootPart",
                                "Core",
                                "Glass",
                            }
                        )
                    end,
                    function()
                        if not EventCfg.autoBoss
                            or not currentArena.Parent
                            or phase(currentArena)
                                ~= "Ball"
                        then
                            return false
                        end

                        return isBallMechanicReady(
                            currentArena
                        )
                            and currentArena:GetAttribute(
                                "BallStunned"
                            ) == true
                    end,
                    function(distance)
                        local hp =
                            tonumber(
                                currentArena:GetAttribute(
                                    "CoreHealth"
                                )
                            )

                        local mx =
                            tonumber(
                                currentArena:GetAttribute(
                                    "CoreMax"
                                )
                            )

                        return string.format(
                            "BALL VULNERABLE %s/%s | dist %.1f",
                            hp ~= nil
                                and tostring(hp)
                                or "?",
                            mx ~= nil
                                and tostring(mx)
                                or "?",
                            distance
                        )
                    end
                )

                return
            end

            local coil,
                coilName =
                chooseCoil(
                    currentArena
                )

            if not coilName then
                stopCharacter()
                setStatus(
                    "BALL shielded -> all Coil positions ignored"
                )
                task.wait(0.10)
                return
            end

            State.coilGuideName = nil
            State.coilGuidePos = nil
            State.coilGuideSeenAt = 0

            setStatus(
                tostring(coilName)
                .. " -> selected"
            )

            attackCoilUntilOpen(
                currentArena,
                coil,
                coilName
            )

            recordSpent(currentArena)

            return
        end

        if currentPhase == "Human" then
            State.stage = "HUMAN"
            State.currentCoil = nil

            local hits =
                tonumber(
                    currentArena:GetAttribute(
                        "HumanHits"
                    )
                )
                or 0

            local needed =
                tonumber(
                    currentArena:GetAttribute(
                        "HumanNeeded"
                    )
                )
                or 3

            if hits >= needed then
                stopCharacter()
                setStatus(
                    "HUMAN complete -> waiting Final"
                )
                task.wait(0.05)
                return
            end

            lockAndAttackHuman(
                currentArena,
                needed
            )

            return
        end

        if currentPhase == "Final" then
            State.stage = "FINAL"
            stopCharacter()

            setStatus(
                "FINAL -> waiting reward + auto return"
            )

            task.wait(0.05)
            return
        end

        stopCharacter()

        setStatus(
            "Arena phase: "
            .. (
                currentPhase ~= ""
                and currentPhase
                or "loading"
            )
        )

        task.wait(0.05)
    end

    local function worker(
        generation
    )
        setStatus(
            "Waiting boss gate"
        )

        while EventCfg.autoBoss
            and State.running
            and State.generation
                == generation
        do
            local currentArena =
                arena()

            local gate, portal =
                gateAndPortal()

            if not currentArena
                and not gate
            then
                ArenaNoclip:Stop()

                if State.hadArena then
                    finishEncounter(true)
                elseif State.active
                    or DHub.EventBossPriority
                        .requested
                then
                    State.active = false
                    DHub.EventBossPriority
                        :EndRequest()

                    resumeOtherScrambleCombat()
                end

                setStatus(
                    "Waiting boss gate"
                )

                task.wait(0.18)
                continue
            end

            if not beginEncounter() then
                task.wait(0.08)
                continue
            end

            currentArena = arena()

            -- CRITICAL: ScrambleArena can replicate before the local player
            -- has entered it. Never start Mech/Ball/Human combat from lobby.
            if not currentArena
                or not isPlayerInsideArena(
                    currentArena
                )
            then
                ArenaNoclip:Stop()

                if not stageBossEntrySafezone(generation) then
                    task.wait(0.05)
                    continue
                end

                if portal
                    and portal.Parent
                then
                    enterPortal(
                        portal,
                        generation
                    )
                else
                    setStatus(
                        currentArena
                        and "Arena spawned -> waiting Portal to enter"
                        or "Boss priority -> waiting Portal mesh"
                    )

                    task.wait(0.05)
                end

                continue
            end

            stepArena(
                currentArena
            )

            if not currentArena.Parent then
                finishEncounter(true)
            end

            S.RunService.Heartbeat:Wait()
        end

        stopCharacter()
        ArenaNoclip:Stop()

        State.active = false
        State.arena = nil
        State.currentCoil = nil
        State.hadArena = false
        State.running = false

        DHub.EventBossPriority
            :EndRequest()

        if EventCfg.autoWave
            or EventCfg.autoDoubleBat
        then
            pcall(
                ScrambleFarm.Start
            )
        end

        if not EventCfg.autoBoss then
            setStatus("Idle")
        end
    end

    local function start()
        if State.running then
            return
        end

        State.running = true
        State.generation =
            State.generation + 1

        task.spawn(
            worker,
            State.generation
        )
    end

    local function stop(
        fromCleanup
    )
        State.running = false
        State.generation =
            State.generation + 1

        releaseHumanRootLock()
        stopCharacter()
        ArenaNoclip:Stop()

        State.active = false
        State.arena = nil
        State.currentCoil = nil
        State.entrySafezoneDone = false
        State.hadArena = false
        State.spentSet = {}

        DHub.EventBossPriority
            :EndRequest()

        if not fromCleanup
            and (
                EventCfg.autoWave
                or EventCfg.autoDoubleBat
            )
        then
            task.defer(function()
                if not EventCfg.autoBoss then
                    ScrambleFarm.Start()
                end
            end)
        end

        if not fromCleanup then
            setStatus("Idle")
        end
    end

    return {
        State = State,
        Start = start,
        Stop = stop,
    }
end)()

-- ============================================================
-- DOUBLE BAT QUEST VAULT
--
-- Confirmed runtime sources:
--   RE/Scramble/State
--   RF/Scramble/Request("snapshot")
--
-- Lost Parts:
--   LostPart1 = Mechanical Gear
--   LostPart2 = Wiring Harness
-- Positions come from Snapshot/State Quest.*.Position and are
-- global, so no Workspace scanning loop is needed.
--
-- Drone Parts:
--   counter only (State.DroneParts); Auto Wave kills drones.
--
-- Vault Claim:
--   exact RF action is still UNKNOWN.
--   Safe behavior: only use a real ProximityPrompt if the game
--   injects one into ExperimentVault when requirements are ready.
-- ============================================================

DoubleBatQuest = (function()
    -- ============================================================
    -- DOUBLE BAT QUEST — ONE TOGGLE STATE MACHINE
    --
    -- WAITING_WAVE
    --   -> CHECK_REQ
    --   -> LOST_PARTS      (strictly first)
    --   -> DRONE_PARTS     (reuse ScrambleFarm; nearest first)
    --   -> VAULT_CLAIM
    --   -> COMPLETED
    --
    -- Confirmed:
    -- * Lost Parts persist across waves.
    -- * DroneParts persist across waves.
    -- * DronePart is server-direct RNG at drone death.
    -- * There is NO pre-death DronePart predictor.
    -- * Therefore DroneParts phase prioritizes nearest drone.
    -- ============================================================

    local State = {
        running = false,
        generation = 0,

        revision = 0,
        windowActive = false,
        windowIndex = 0,
        windowEndsAt = 0,
        windowNextAt = 0,

        phase = "WAITING_WAVE",

        lostPartPositions = {
            LostPart1 = nil,
            LostPart2 = nil,
        },

        vaultPosition = nil,

        lostPartsCollected = {
            LostPart1 = false,
            LostPart2 = false,
        },

        dronePartsCount = 0,
        totalParts = 0,
        completed = false,

        -- Requirements complete, but claim rig may still be pending.
        vaultReady = false,
        vaultRigReady = false,
        vaultRigPending = nil,

        lastSnapshotAt = 0,
        lastSnapshot = nil,

        status = "Idle",
        compactLabel = nil,

        stateConnection = nil,
        vaultConnections = {},
        boundVault = nil,
    }

    local PARTS = {
        {
            id = "LostPart1",
            name = "Mechanical Gear",
        },
        {
            id = "LostPart2",
            name = "Wiring Harness",
        },
    }

    local LOST_PART_STOP_DISTANCE = 5.5
    local VAULT_STOP_DISTANCE = 8
    local SNAPSHOT_INTERVAL = 0.60

    local function parsePosition(value)
        if typeof(value) == "Vector3" then
            return value
        end

        if typeof(value) == "CFrame" then
            return value.Position
        end

        if type(value) == "table" then
            if typeof(value.Position) == "Vector3" then
                return value.Position
            end

            local x =
                tonumber(value.X)
                or tonumber(value.x)
                or tonumber(value[1])

            local y =
                tonumber(value.Y)
                or tonumber(value.y)
                or tonumber(value[2])

            local z =
                tonumber(value.Z)
                or tonumber(value.z)
                or tonumber(value[3])

            if x and y and z then
                return Vector3.new(x, y, z)
            end
        end

        if type(value) == "string" then
            local nums = {}

            for n in value:gmatch("[-+]?%d*%.?%d+") do
                nums[#nums + 1] = tonumber(n)
                if #nums >= 3 then
                    break
                end
            end

            if nums[1] and nums[2] and nums[3] then
                return Vector3.new(
                    nums[1],
                    nums[2],
                    nums[3]
                )
            end
        end

        return nil
    end

    local function lostPartsComplete()
        return State.lostPartsCollected.LostPart1 == true
            and State.lostPartsCollected.LostPart2 == true
    end

    local function requirementsComplete()
        return lostPartsComplete()
            and (tonumber(State.dronePartsCount) or 0) >= 3
    end

    local function normalizePending(value)
        if value == nil then
            return nil
        end

        if value == false or value == 0 then
            return false
        end

        if value == true or value == 1 then
            return true
        end

        local s = tostring(value):lower()

        if s == "false" or s == "0" then
            return false
        end

        if s == "true" or s == "1" then
            return true
        end

        return nil
    end

    local function calculatePhase()
        if State.completed then
            return "COMPLETED"
        end

        if not State.windowActive then
            return "WAITING_WAVE"
        end

        if not lostPartsComplete() then
            return "LOST_PARTS"
        end

        if (tonumber(State.dronePartsCount) or 0) < 3 then
            return "DRONE_PARTS"
        end

        return "VAULT_CLAIM"
    end

    local function refreshUI()
        State.vaultReady =
            requirementsComplete()
            and not State.completed

        State.phase = calculatePhase()

        if State.compactLabel then
            local lostCount =
                (State.lostPartsCollected.LostPart1 and 1 or 0)
                + (State.lostPartsCollected.LostPart2 and 1 or 0)

            local droneCount =
                math.clamp(
                    tonumber(State.dronePartsCount) or 0,
                    0,
                    3
                )

            local stateText =
                State.completed
                and "UNLOCKED ✓"
                or tostring(State.status or State.phase)

            State.compactLabel.Text = string.format(
                "Cave Quest  |  Lost %d/2  |  Drone %d/3\n%s",
                lostCount,
                droneCount,
                stateText
            )
        end
    end

    local function setStatus(txt)
        State.status = tostring(txt or "Idle")
        refreshUI()
    end

    local function applyPayload(payload)
        if type(payload) ~= "table" then
            return
        end

        if type(payload.Snapshot) == "table" then
            payload = payload.Snapshot
        end

        if payload.Revision ~= nil then
            State.revision =
                tonumber(payload.Revision)
                or State.revision
                or 0
        end

        if type(payload.Window) == "table" then
            if payload.Window.Active ~= nil then
                State.windowActive =
                    payload.Window.Active == true
            end

            if payload.Window.Index ~= nil then
                State.windowIndex =
                    tonumber(payload.Window.Index)
                    or State.windowIndex
                    or 0
            end

            if payload.Window.EndsAt ~= nil then
                State.windowEndsAt =
                    tonumber(payload.Window.EndsAt)
                    or State.windowEndsAt
                    or 0
            end

            if payload.Window.NextAt ~= nil then
                State.windowNextAt =
                    tonumber(payload.Window.NextAt)
                    or State.windowNextAt
                    or 0
            end
        end

        if type(payload.Quest) == "table" then
            for _, part in ipairs(PARTS) do
                local quest =
                    payload.Quest[part.id]

                if type(quest) == "table" then
                    local pos =
                        parsePosition(
                            quest.Position
                            or quest.Pivot
                        )

                    if pos then
                        State.lostPartPositions[part.id] =
                            pos
                    end
                end
            end

            local vaultQuest =
                payload.Quest.ExperimentVault

            if type(vaultQuest) == "table" then
                local vaultPos =
                    parsePosition(
                        vaultQuest.Position
                        or vaultQuest.Pivot
                    )

                if vaultPos then
                    State.vaultPosition =
                        vaultPos
                end
            end
        end

        if type(payload.State) == "table" then
            local s = payload.State

            -- RE/Scramble/State is incremental. Only overwrite keys that
            -- actually exist in this patch so persistent progress never
            -- gets reset by an omitted field.
            if type(s.LostParts) == "table" then
                if s.LostParts.LostPart1 ~= nil then
                    State.lostPartsCollected.LostPart1 =
                        s.LostParts.LostPart1 == true
                end

                if s.LostParts.LostPart2 ~= nil then
                    State.lostPartsCollected.LostPart2 =
                        s.LostParts.LostPart2 == true
                end
            end

            if s.DroneParts ~= nil then
                State.dronePartsCount =
                    tonumber(s.DroneParts)
                    or State.dronePartsCount
                    or 0
            end

            if s.TotalParts ~= nil then
                State.totalParts =
                    tonumber(s.TotalParts)
                    or State.totalParts
                    or 0
            end

            if s.Completed ~= nil then
                State.completed =
                    s.Completed == true
            end
        end

        State.vaultReady =
            requirementsComplete()
            and not State.completed

        State.phase = calculatePhase()
        refreshUI()
    end

    local function refreshSnapshot(force)
        local now = tick()

        if not force
            and now - (State.lastSnapshotAt or 0)
                < SNAPSHOT_INTERVAL
        then
            return State.lastSnapshot
        end

        State.lastSnapshotAt = now

        if not RMT.ScrambleRequest then
            return nil
        end

        local ok, response = pcall(function()
            return RMT.ScrambleRequest:InvokeServer(
                "snapshot"
            )
        end)

        if not ok or type(response) ~= "table" then
            return State.lastSnapshot
        end

        local snapshot =
            type(response.Snapshot) == "table"
            and response.Snapshot
            or response

        if type(snapshot) == "table" then
            State.lastSnapshot = snapshot
            applyPayload(snapshot)
        end

        return State.lastSnapshot
    end

    if RMT.ScrambleState
        and RMT.ScrambleState:IsA("RemoteEvent")
    then
        State.stateConnection =
            RMT.ScrambleState.OnClientEvent:Connect(
                function(payload)
                    applyPayload(payload)
                end
            )

        table.insert(
            ScriptConnections,
            State.stateConnection
        )
    end

    local function disconnectVaultConnections()
        for _, conn in ipairs(State.vaultConnections) do
            pcall(function()
                conn:Disconnect()
            end)
        end

        table.clear(State.vaultConnections)
        State.boundVault = nil
    end

    local function findVaultPrompt(vault)
        if not vault then
            return nil
        end

        local prompt =
            vault:FindFirstChildWhichIsA(
                "ProximityPrompt",
                true
            )

        if prompt and prompt.Enabled then
            return prompt
        end

        return nil
    end

    local function refreshVaultRig(vault)
        vault = vault or State.boundVault

        if not vault or not vault.Parent then
            State.vaultRigPending = nil
            State.vaultRigReady = false
            refreshUI()
            return
        end

        local pending =
            normalizePending(
                vault:GetAttribute(
                    "ScrambleVaultRigPending"
                )
            )

        State.vaultRigPending = pending

        local prompt =
            findVaultPrompt(vault)

        State.vaultRigReady =
            pending == false
            or prompt ~= nil

        refreshUI()
    end

    local function bindVault(vault)
        if State.boundVault == vault then
            refreshVaultRig(vault)
            return
        end

        disconnectVaultConnections()

        if not vault then
            return
        end

        State.boundVault = vault

        local attrConn =
            vault:GetAttributeChangedSignal(
                "ScrambleVaultRigPending"
            ):Connect(function()
                refreshVaultRig(vault)

                if State.vaultReady
                    and State.vaultRigReady
                then
                    setStatus(
                        "Vault rig ready — claiming..."
                    )
                end
            end)

        local descConn =
            vault.DescendantAdded:Connect(function(obj)
                if obj:IsA("ProximityPrompt") then
                    refreshVaultRig(vault)

                    if State.vaultReady then
                        setStatus(
                            "Vault prompt ready — claiming..."
                        )
                    end
                end
            end)

        local ancestryConn =
            vault.AncestryChanged:Connect(function(_, parent)
                if parent == nil then
                    disconnectVaultConnections()
                end
            end)

        table.insert(State.vaultConnections, attrConn)
        table.insert(State.vaultConnections, descConn)
        table.insert(State.vaultConnections, ancestryConn)

        table.insert(ScriptConnections, attrConn)
        table.insert(ScriptConnections, descConn)
        table.insert(ScriptConnections, ancestryConn)

        refreshVaultRig(vault)
    end

    local function locateAndBindVault()
        local eventModel =
            S.Workspace:FindFirstChild(
                "DrScrambleEvent"
            )

        local vault =
            eventModel
            and eventModel:FindFirstChild(
                "ExperimentVault"
            )

        bindVault(vault)
    end

    locateAndBindVault()

    local worldVaultWatcher =
        S.Workspace.ChildAdded:Connect(function(child)
            if child.Name == "DrScrambleEvent" then
                task.defer(locateAndBindVault)
            end
        end)

    table.insert(
        ScriptConnections,
        worldVaultWatcher
    )

    local function shouldContinue(externalContinue)
        if not EventCfg.autoDoubleBat then
            return false
        end

        if not State.windowActive then
            return false
        end

        if type(externalContinue) == "function" then
            local ok, result =
                pcall(externalContinue)

            return ok and result == true
        end

        return true
    end

    local function ensureFastBypass()
        if Cfg.farmMethod ~= "Fast" then
            return true
        end

        if DHub.CharacterService:IsFastReady() then
            return true
        end

        setStatus("Applying FAST bypass...")

        return DHub.CharacterService:EnsureFastReady({
            timeout = 8,
        }) == true
    end

    local function moveToPosition(
        pos,
        stopDistance,
        externalContinue
    )
        if typeof(pos) ~= "Vector3" then
            return false
        end

        local function alive()
            return shouldContinue(externalContinue)
        end

        if Cfg.farmMethod == "Fast" then
            if not ensureFastBypass() then
                return false
            end

            return DHub.MovementService:MoveFast(
                pos,
                {
                    owner = "Event",
                    priority = 88,
                    speed = Cfg.walkSpeed,
                    stopDistance = stopDistance or 5,
                    requireBypass = false,
                    shouldContinue = alive,
                    timeout = 35,
                }
            ) == true
        end

        return WalkToTarget(
            pos,
            stopDistance or 5,
            false,
            alive
        ) == true
    end

    local function getLostPartPrompt(partId)
        local eventModel =
            S.Workspace:FindFirstChild(
                "DrScrambleEvent"
            )

        local model =
            eventModel
            and eventModel:FindFirstChild(partId)

        local hitbox =
            model
            and model:FindFirstChild("Hitbox")

        local prompt =
            hitbox
            and hitbox:FindFirstChild(
                "ClaimLostPart"
            )

        if prompt
            and prompt:IsA("ProximityPrompt")
        then
            return prompt
        end

        return nil
    end

    local function collectLostPart(
        part,
        externalContinue
    )
        if not part then
            return false
        end

        refreshSnapshot(true)

        if State.lostPartsCollected[part.id] then
            return false
        end

        local pos =
            State.lostPartPositions[part.id]

        if typeof(pos) ~= "Vector3" then
            setStatus(
                part.name
                .. " position unavailable"
            )
            return false
        end

        setStatus(
            "LOST_PARTS — moving to "
            .. part.name
        )

        local reached =
            moveToPosition(
                pos,
                LOST_PART_STOP_DISTANCE,
                externalContinue
            )

        if not reached
            or not shouldContinue(externalContinue)
        then
            return false
        end

        local root = getRoot()
        local holdPosition =
            root
            and root.Position
            or pos

        local function holdStill()
            local currentRoot = getRoot()
            local currentHum = getHumanoid()

            if currentRoot then
                pcall(function()
                    currentRoot.AssemblyLinearVelocity =
                        Vector3.zero

                    currentRoot.AssemblyAngularVelocity =
                        Vector3.zero
                end)
            end

            if currentHum
                and currentRoot
                and currentHum.Health > 0
            then
                pcall(function()
                    currentHum:MoveTo(holdPosition)
                end)
            end
        end

        setStatus(
            "LOST_PARTS — "
            .. part.name
            .. " reached | wait 5s"
        )

        local settleDeadline =
            tick() + 5

        while shouldContinue(externalContinue)
            and tick() < settleDeadline
        do
            holdStill()
            task.wait(0.10)
        end

        if not shouldContinue(externalContinue) then
            return false
        end

        refreshSnapshot(true)
        State.phase = calculatePhase()
        refreshUI()

        if State.lostPartsCollected[part.id] then
            setStatus(
                part.name
                .. " collected ✓"
            )
            return true
        end

        if State.phase ~= "LOST_PARTS" then
            setStatus(
                "CAVE_QUEST — state changed"
            )
            return true
        end

        setStatus(
            "LOST_PARTS — spam pickup "
            .. part.name
        )

        while shouldContinue(externalContinue) do
            holdStill()
            refreshSnapshot(true)

            State.phase = calculatePhase()
            refreshUI()

            if State.lostPartsCollected[part.id] then
                setStatus(
                    part.name
                    .. " collected ✓"
                )
                return true
            end

            if State.phase ~= "LOST_PARTS" then
                setStatus(
                    "CAVE_QUEST — state changed"
                )
                return true
            end

            local prompt =
                getLostPartPrompt(part.id)

            if prompt
                and prompt.Parent
                and prompt.Enabled == true
            then
                local originalHold =
                    prompt.HoldDuration

                pcall(function()
                    prompt.HoldDuration = 0
                end)

                if type(fireproximityprompt)
                    == "function"
                then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                end

                pcall(function()
                    if prompt
                        and prompt.Parent
                    then
                        prompt.HoldDuration =
                            originalHold
                    end
                end)
            end

            task.wait(0.12)
        end

        return false
    end

    local function getVaultPrompt()
        locateAndBindVault()

        local vault = State.boundVault
        if not vault then
            return nil
        end

        return findVaultPrompt(vault)
    end

    local function tryClaimVault(
        externalContinue
    )
        refreshSnapshot(true)
        locateAndBindVault()

        if State.completed then
            setStatus("COMPLETED ✓")
            return false
        end

        if not State.vaultReady then
            return false
        end

        local prompt =
            getVaultPrompt()

        if not State.vaultRigReady
            and not prompt
        then
            setStatus(
                "VAULT_CLAIM — waiting vault rig"
            )
            return false
        end

        if typeof(State.vaultPosition)
            ~= "Vector3"
        then
            setStatus(
                "VAULT_CLAIM — position unavailable"
            )
            return false
        end

        setStatus(
            "VAULT_CLAIM — moving to vault"
        )

        local reached =
            moveToPosition(
                State.vaultPosition,
                VAULT_STOP_DISTANCE,
                externalContinue
            )

        if not reached
            or not shouldContinue(externalContinue)
        then
            return false
        end

        prompt = getVaultPrompt()

        if not prompt then
            setStatus(
                "VAULT_CLAIM — waiting claim prompt"
            )
            return false
        end

        local oldHold =
            prompt.HoldDuration

        pcall(function()
            prompt.HoldDuration = 0
        end)

        local fired = false

        if type(fireproximityprompt) == "function" then
            fired = pcall(function()
                fireproximityprompt(prompt)
            end)
        end

        pcall(function()
            if prompt and prompt.Parent then
                prompt.HoldDuration = oldHold
            end
        end)

        if not fired then
            setStatus(
                "VAULT_CLAIM — prompt failed"
            )
            return false
        end

        local deadline = tick() + 4

        while shouldContinue(externalContinue)
            and tick() < deadline
        do
            refreshSnapshot(true)

            if State.completed then
                setStatus("COMPLETED ✓")
                return true
            end

            task.wait(0.15)
        end

        refreshSnapshot(true)

        if State.completed then
            setStatus("COMPLETED ✓")
            return true
        end

        setStatus(
            "VAULT_CLAIM — not confirmed"
        )

        return false
    end

    local function runWaveDetour(
        externalContinue
    )
        if not EventCfg.autoDoubleBat then
            return false
        end

        refreshSnapshot(true)

        State.phase = calculatePhase()
        refreshUI()

        if State.phase == "WAITING_WAVE" then
            setStatus("WAITING_WAVE")
            return false
        end

        if State.phase == "COMPLETED" then
            setStatus("COMPLETED ✓")
            return false
        end

        if State.phase == "LOST_PARTS" then
            local acted = false

            -- STRICT: LostPart1 / LostPart2 first. No drone kill phase
            -- is allowed until both persistent state flags are true.
            for _, part in ipairs(PARTS) do
                if not State.lostPartsCollected[part.id] then
                    local ok =
                        collectLostPart(
                            part,
                            externalContinue
                        )

                    acted = ok or acted

                    if not shouldContinue(
                        externalContinue
                    ) then
                        return acted
                    end

                    refreshSnapshot(true)
                    State.phase = calculatePhase()
                    refreshUI()

                    if State.phase ~= "LOST_PARTS" then
                        return acted
                    end
                end
            end

            refreshSnapshot(true)
            State.phase = calculatePhase()
            refreshUI()

            if State.phase == "DRONE_PARTS" then
                setStatus(string.format(
                    "DRONE_PARTS %d/3 — nearest-first",
                    math.clamp(
                        tonumber(State.dronePartsCount) or 0,
                        0,
                        3
                    )
                ))
            end

            return acted
        end

        if State.phase == "DRONE_PARTS" then
            setStatus(string.format(
                "DRONE_PARTS %d/3 — nearest-first",
                math.clamp(
                    tonumber(State.dronePartsCount) or 0,
                    0,
                    3
                )
            ))

            -- ScrambleFarm owns the actual drone scanner/movement/follow.
            return false
        end

        if State.phase == "VAULT_CLAIM" then
            return tryClaimVault(
                externalContinue
            )
        end

        return false
    end

    local function watcher(gen)
        refreshSnapshot(true)
        locateAndBindVault()

        while State.running
            and State.generation == gen
            and EventCfg.autoDoubleBat
        do
            refreshSnapshot(
                not State.windowActive
            )

            locateAndBindVault()

            State.phase = calculatePhase()

            if State.phase == "COMPLETED" then
                setStatus("UNLOCKED ✓ — Auto stopped")

                EventCfg.autoDoubleBat = false
                State.running = false

                pcall(saveConfig)

                if DoubleBatQuest.SetToggleVisual then
                    pcall(
                        DoubleBatQuest.SetToggleVisual,
                        false
                    )
                end

                if not EventCfg.autoWave
                    and ScrambleFarm
                then
                    ScrambleFarm.Stop()
                end

                break

            elseif State.phase == "WAITING_WAVE" then
                setStatus("WAITING_WAVE")

            elseif State.phase == "LOST_PARTS" then
                setStatus("LOST_PARTS — collecting requirements")

            elseif State.phase == "DRONE_PARTS" then
                setStatus(string.format(
                    "DRONE_PARTS %d/3 — nearest-first",
                    math.clamp(
                        tonumber(State.dronePartsCount) or 0,
                        0,
                        3
                    )
                ))

            elseif State.phase == "VAULT_CLAIM" then
                if State.vaultRigReady then
                    setStatus(
                        "VAULT_CLAIM — rig ready"
                    )
                else
                    setStatus(
                        "VAULT_CLAIM — waiting rig"
                    )
                end
            end

            task.wait(0.20)
        end

        State.running = false
    end

    local function start()
        if State.running then
            -- Still make sure the shared drone engine exists.
            if ScrambleFarm then
                ScrambleFarm.Start()
            end
            return
        end

        State.running = true
        State.generation =
            State.generation + 1

        -- Reuse the existing Auto Wave drone scanner/movement engine.
        if ScrambleFarm then
            ScrambleFarm.Start()
        end

        task.spawn(
            watcher,
            State.generation
        )
    end

    local function stop()
        State.running = false
        State.generation =
            State.generation + 1

        setStatus("Idle")

        -- ScrambleFarm may still be needed by standalone Auto Wave.
        if not EventCfg.autoWave
            and ScrambleFarm
        then
            ScrambleFarm.Stop()
        end
    end

    return {
        State = State,

        Start = start,
        Stop = stop,

        RefreshSnapshot = function()
            return refreshSnapshot(true)
        end,

        RefreshUI = refreshUI,
        RunWaveDetour = runWaveDetour,

        GetPhase = function()
            State.phase = calculatePhase()
            return State.phase
        end,

        ShouldFarmDrones = function()
            State.phase = calculatePhase()

            return EventCfg.autoDoubleBat
                and State.phase == "DRONE_PARTS"
        end,

        BlocksDroneFarm = function()
            State.phase = calculatePhase()

            return EventCfg.autoDoubleBat
                and (
                    State.phase == "LOST_PARTS"
                    or State.phase == "VAULT_CLAIM"
                )
        end,

        IsCompleted = function()
            return State.completed == true
        end,
    }
end)()



-- ============================================================
-- SCRAMBLE SHARED EVENT HELPERS
--
-- Legacy Rift auto-fuse worker removed. Only primitives still used by
-- Dr. Scramble systems remain.
-- ============================================================

local function isScrambleEventBusy()
    if DHub.EventBossPriority
        and (
            DHub.EventBossPriority.requested == true
            or DHub.EventBossPriority.active == true
        )
    then
        return true
    end

    if not ScrambleFarm
        or not ScrambleFarm.State
        or ScrambleFarm.State.windowActive ~= true
    then
        return false
    end

    return EventCfg.autoWave == true
        or EventCfg.autoDoubleBat == true
end

local function setFusePriority(active)
    active = active == true

    if DHub.RiftFusePriorityActive == active then
        return
    end

    DHub.RiftFusePriorityActive = active

    if DHub.FarmCoordinator
        and DHub.FarmCoordinator.Wake
    then
        DHub.FarmCoordinator:Wake()
    end
end

local function _resolveGuiButton(inst, stopAt)
    if not inst then return nil end
    if inst:IsA("GuiButton") then return inst end

    for _, descendant in ipairs(inst:GetDescendants()) do
        if descendant:IsA("GuiButton") then
            return descendant
        end
    end

    local current = inst.Parent
    while current and current ~= stopAt do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function _fireActivated(button)
    if not button or not button:IsA("GuiButton") then
        return false
    end

    return pcall(function()
        if type(firesignal) ~= "function" then
            error("firesignal unavailable")
        end
        firesignal(button.Activated)
    end)
end


local EventUtility = (function()

    local EventUtilityRuntime = {
        consumableRunning = false,
        shopRunning = false,
        consumableStatus = "Idle",
        shopStatus = "Idle",
        consumableLabel = nil,
        shopLabel = nil,

        mutationOptimisticCount = nil,
        mutationLastSavedCount = nil,
        mutationCompletedUids = {},
        mutationRetryAfter = {},
    }

    local AUTO_CONSUMABLE_RARITIES = RARITIES

    local BOSS_SHOP_UI_ITEMS = {
        "Scrambled Mutation",
        "Experiment #001",
        "Nibbles #013",
        "2x Cash Booster",
        "1.25x Speed",
        "2x Treadmill Booster",
    }

    local BOSS_SHOP_ID_BY_UI = {
        ["Scrambled Mutation"]    = "MutationConsumable",
        ["Experiment #001"]       = "LimitedTimeExperimentPet",
        ["Nibbles #013"]          = "Nibbles013",
        ["2x Cash Booster"]       = "CashBooster",
        ["1.25x Speed"]           = "SpeedBoost",
        ["2x Treadmill Booster"]  = "TreadmillBooster",
    }

    local SCRAMBLE_SHOP_PRICE = {
        MutationConsumable       = 475,
        LimitedTimeExperimentPet = 6500,
        Nibbles013                = 2950,
        CashBooster               = 275,
        SpeedBoost                = 375,
        TreadmillBooster          = 375,
    }

    local SCRAMBLE_SHOP_QUOTE = {
        MutationConsumable =
            "[\"DrScrambleOutbreak\",\"MutationConsumable\",\"MutationConsumable\",\"\",0,1,475,\"Scrambled Mutation\",0,\"rbxassetid://134710848063255\",\"x1 \194\183 10%\",10,true,0]",

        LimitedTimeExperimentPet =
            "[\"DrScrambleOutbreak\",\"LimitedTimeExperimentPet\",\"Egg\",\"LimitedTimeExperimentPet\",1,1,6500,\"Experiment #001\",0,\"rbxassetid://120361722086155\",\"x1\",0,false,1]",

        Nibbles013 =
            "[\"DrScrambleOutbreak\",\"Nibbles013\",\"Egg\",\"Nibbles #013\",1,1,2950,\"Nibbles #013\",0,\"rbxassetid://128576060432452\",\"x1\",0,false,3]",

        CashBooster =
            "[\"DrScrambleOutbreak\",\"CashBooster\",\"CashBooster\",\"\",0,1,275,\"2x Cash Booster\",600,\"rbxassetid://119640363267627\",\"10m\",2,false,0]",

        SpeedBoost =
            "[\"DrScrambleOutbreak\",\"SpeedBoost\",\"SpeedBoost\",\"\",0,1,375,\"1.25x Speed\",300,\"rbxassetid://78137530993637\",\"5m\",1.25,false,0]",

        TreadmillBooster =
            "[\"DrScrambleOutbreak\",\"TreadmillBooster\",\"TreadmillBoost\",\"\",0,1,375,\"2x Treadmill Booster\",600,\"rbxassetid://107126944152347\",\"10m\",2,false,0]",
    }

    local EventUtilityModules = {
        loaded = false,
        Save = nil,
        EggState = nil,
        Assets = nil,
        RarityData = nil,
        BossMastery = nil,
        Remotes = nil,
    }

    local function loadEventUtilityModules()
        if EventUtilityModules.loaded then
            return EventUtilityModules
        end

        local rs = S.ReplicatedStorage

        pcall(function()
            EventUtilityModules.Save = require(rs.Shared.Save)
        end)
        pcall(function()
            EventUtilityModules.EggState = require(rs.Client.EggState)
        end)
        pcall(function()
            EventUtilityModules.Assets = require(rs.Data.Assets)
        end)
        pcall(function()
            EventUtilityModules.RarityData = require(rs.Data.Rarity)
        end)
        pcall(function()
            EventUtilityModules.BossMastery = require(rs.Data.BossMastery)
        end)
        pcall(function()
            EventUtilityModules.Remotes = require(rs.Shared.Remotes)
        end)

        EventUtilityModules.loaded =
            EventUtilityModules.Save ~= nil
            and EventUtilityModules.EggState ~= nil
            and EventUtilityModules.Assets ~= nil
            and EventUtilityModules.BossMastery ~= nil
            and EventUtilityModules.Remotes ~= nil

        return EventUtilityModules
    end

    local function getEventSave()
        local m = loadEventUtilityModules()
        if not m.Save or not m.Save.Get then return nil end

        local save = nil
        pcall(function()
            save = m.Save.Get()
        end)
        return save
    end

    local function isScrambledConsumableTool(obj)
        if not obj or not obj:IsA("Tool") then
            return false
        end

        if obj:GetAttribute("ItemType") == "MutationConsumable" then
            return true
        end

        local lowerName =
            tostring(obj.Name or ""):lower()

        return lowerName:match(
            "^scrambled mutation%s*%[x%d+%]$"
        ) ~= nil
    end

    local function getScrambledToolStackCount(obj)
        if not isScrambledConsumableTool(obj) then
            return 0
        end

        local attrQty =
            tonumber(obj:GetAttribute("Quantity"))
            or tonumber(obj:GetAttribute("Count"))
            or tonumber(obj:GetAttribute("Stack"))
            or tonumber(obj:GetAttribute("Amount"))

        if attrQty and attrQty > 0 then
            return math.floor(attrQty)
        end

        local fromName =
            tostring(obj.Name or ""):match(
                "%[x(%d+)%]$"
            )

        if tonumber(fromName) then
            return math.max(
                1,
                math.floor(tonumber(fromName))
            )
        end

        return 1
    end

    local function getLiveScrambledToolCount()
        local total = 0
        local seen = {}
        local char = LP.Character
        local backpack =
            LP:FindFirstChildOfClass("Backpack")

        local function addContainer(container)
            if not container then return end

            for _, obj in ipairs(container:GetChildren()) do
                if isScrambledConsumableTool(obj)
                    and not seen[obj]
                then
                    seen[obj] = true
                    total =
                        total
                        + getScrambledToolStackCount(obj)
                end
            end
        end

        addContainer(char)
        addContainer(backpack)

        return total
    end

    local function getRawMutationConsumableCount()
        local liveToolCount =
            getLiveScrambledToolCount()

        local save = getEventSave()
        local savedCount = nil

        if save
            and type(save.BossMastery) == "table"
        then
            savedCount =
                math.max(
                    0,
                    tonumber(
                        save.BossMastery
                            .MutationConsumables
                    ) or 0
                )
        end

        -- Runtime Tool stack is decisive when it is visible.
        -- Example: "Scrambled Mutation [X3]" must report 3 even if
        -- Save.Get().BossMastery.MutationConsumables is stale at 0.
        if liveToolCount > 0 then
            if savedCount == nil then
                return liveToolCount, false
            end

            return math.max(
                liveToolCount,
                savedCount
            ),
            true
        end

        if savedCount ~= nil then
            return savedCount, true
        end

        return 0, false
    end

    local function getMutationConsumableCount()
        local rawCount =
            getRawMutationConsumableCount()

        local liveToolCount =
            getLiveScrambledToolCount()

        if liveToolCount > 0 then
            EventUtilityRuntime
                .mutationOptimisticCount =
                liveToolCount

            return liveToolCount
        end

        local optimistic =
            EventUtilityRuntime
                .mutationOptimisticCount

        if optimistic ~= nil then
            return math.max(
                0,
                math.min(
                    tonumber(rawCount) or 0,
                    tonumber(optimistic) or 0
                )
            )
        end

        EventUtilityRuntime
            .mutationOptimisticCount =
            tonumber(rawCount) or 0

        return math.max(
            0,
            tonumber(rawCount) or 0
        )
    end

    local function markMutationConsumableSpent()
        local current =
            getMutationConsumableCount()

        EventUtilityRuntime.mutationOptimisticCount =
            math.max(0, current - 1)

        task.defer(function()
            task.wait(0.15)

            local live =
                getLiveScrambledToolCount()

            if live >= 0 then
                EventUtilityRuntime
                    .mutationOptimisticCount =
                    live
            end
        end)
    end

    local function getBossTokenCount()
        return ScrambleFarm.GetSamples()
    end

    local function normalizeConsumableRarity(name)
        name = tostring(name or "")

        if name == "Basic" then return "Common" end
        if name == "Celestial" then return "Uncommon" end
        if name == "Mythical" then return "Mythic" end
        if name == "Rainbow" or name == "Prismatic" then return "Mythic" end
        if name == "Transcendent" then return "Superior" end
        if name == "Admin" then return "Exclusive" end

        return name
    end

    local function getPlacedEggRarityName(record)
        if type(record) ~= "table" then return nil end

        local m = loadEventUtilityModules()
        local assets = m.Assets
        local directory = assets and (assets.Directory or assets)
        local cfg = directory and directory[record.AssetCategory]
        local rarity = cfg and cfg.Rarity
        if not rarity then return nil end

        if type(rarity) == "table" and rarity._id then
            return tostring(rarity._id)
        end

        local rarityData = m.RarityData
        local rarities = rarityData and (rarityData.Rarities or rarityData)

        if type(rarities) == "table" then
            for rarityName, rarityCfg in pairs(rarities) do
                if rarityCfg == rarity then
                    return tostring(rarityName)
                end
            end
        end

        return nil
    end

    local function isConsumableRaritySelected(rarityName)
        local selected = EventCfg.consumableRarities

        if selected["All"] then return true end
        if not next(selected) then return false end

        local normalized = normalizeConsumableRarity(rarityName)

        for chosen, enabled in pairs(selected) do
            if enabled
                and chosen ~= "All"
                and table.find(
                    AUTO_CONSUMABLE_RARITIES,
                    chosen
                ) ~= nil
                and normalizeConsumableRarity(chosen) == normalized
            then
                return true
            end
        end

        return false
    end

    local function hasBossMutation(record)
        if type(record) ~= "table" then return false end

        local m = loadEventUtilityModules()
        local mutationId =
            (m.BossMastery and m.BossMastery.MutationId)
            or "Boss"

        return table.find(record.Mutations or {}, mutationId) ~= nil
    end

    local function isPlacedEggConsumableEligible(record)
        if type(record) ~= "table" then return false end
        if record.Placement == nil then return false end
        if record.IsHatching == true then return false end
        if record.MutationPresenting == true then return false end
        if hasBossMutation(record) then return false end
        return true
    end

    local function readMyPlacedEggs()
        local m = loadEventUtilityModules()
        if not m.EggState or not m.EggState.ReadOwnerEggs then
            return {}
        end

        local eggs = nil
        pcall(function()
            eggs = m.EggState.ReadOwnerEggs(LP.UserId)
        end)

        return type(eggs) == "table" and eggs or {}
    end

    local function countEligibleConsumableEggs()
        local total = 0
        local now = tick()

        for uid, record in pairs(
            readMyPlacedEggs()
        ) do
            local uidKey = tostring(uid)
            local blockedUntil =
                EventUtilityRuntime.mutationRetryAfter[
                    uidKey
                ]

            if not EventUtilityRuntime
                    .mutationCompletedUids[uidKey]
                and (
                    not blockedUntil
                    or now >= blockedUntil
                )
                and isPlacedEggConsumableEligible(record)
            then
                local rarityName =
                    getPlacedEggRarityName(record)

                if rarityName
                    and isConsumableRaritySelected(
                        rarityName
                    )
                then
                    total = total + 1
                end
            end
        end

        return total
    end

    EventUtilityRuntime.resolveMutationEggPosition =
        function(record)
            if type(record) ~= "table"
                or type(record.Placement) ~= "table"
            then
                return nil, "Egg placement unavailable"
            end

            local penInfo = findMyPlot()

            if not penInfo
                or not penInfo.petArea
                or not penInfo.petArea.Parent
            then
                return nil, "Plot not found"
            end

            local localCF =
                record.Placement.LocalCFrame

            if type(localCF) == "string" then
                localCF = parseCFrameString(localCF)
            end

            if typeof(localCF) ~= "CFrame" then
                return nil, "Egg LocalCFrame unavailable"
            end

            return (
                penInfo.petArea.CFrame
                * localCF
            ).Position,
            nil,
            penInfo
        end

    EventUtilityRuntime.findMutationPromptNear =
        function(plot, targetPos)
            if not plot
                or not plot.Parent
                or typeof(targetPos) ~= "Vector3"
            then
                return nil
            end

            for _, obj in ipairs(plot:GetDescendants()) do
                if obj:IsA("ProximityPrompt")
                    and obj.Enabled
                then
                    local host = obj.Parent

                    if host
                        and host:IsA("Attachment")
                    then
                        host = host.Parent
                    end

                    if host
                        and host:IsA("BasePart")
                        and (
                            host.Position
                            - targetPos
                        ).Magnitude <= 10
                    then
                        local tag = (
                            tostring(obj.Name or "")
                            .. " "
                            .. tostring(obj.ActionText or "")
                            .. " "
                            .. tostring(obj.ObjectText or "")
                        ):lower()

                        if tag:find("mutation", 1, true)
                            or tag:find("scram", 1, true)
                            or tag:find("consum", 1, true)
                        then
                            return obj
                        end
                    end
                end
            end

            return nil
        end

    local function setConsumableUtilityStatus(txt)
        EventUtilityRuntime.consumableStatus = tostring(txt or "Idle")
    end

    local function setBossShopUtilityStatus(txt)
        EventUtilityRuntime.shopStatus = tostring(txt or "Idle")
    end

    local function refreshEventUtilityLabels()
        local consumables =
            getMutationConsumableCount()

        local eligible =
            countEligibleConsumableEggs()

        local tokens =
            getBossTokenCount()

        if EventUtilityRuntime.consumableLabel then
            EventUtilityRuntime.consumableLabel.Text =
                string.format(
                    "Consumables: %d  |  Eligible Eggs: %d  |  %s",
                    consumables,
                    eligible,
                    EventUtilityRuntime.consumableStatus
                )
        end

        if EventUtilityRuntime.shopLabel then
            EventUtilityRuntime.shopLabel.Text =
                string.format(
                    "Samples: %s  |  %s",
                    tostring(tokens),
                    EventUtilityRuntime.shopStatus
                )
        end
    end

    local function getMutationConsumableTool()
        local char = LP.Character
        local backpack = LP:FindFirstChildOfClass("Backpack")

        local function isMutationConsumableTool(obj)
            return isScrambledConsumableTool(obj)
        end

        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if isMutationConsumableTool(obj) then
                    return obj, true
                end
            end
        end

        if backpack then
            for _, obj in ipairs(backpack:GetChildren()) do
                if isMutationConsumableTool(obj) then
                    return obj, false
                end
            end
        end

        return nil, false
    end

    local function ensureMutationConsumableEquipped()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hum or hum.Health <= 0 then
            return false, "Character unavailable"
        end

        local tool, alreadyEquipped = getMutationConsumableTool()

        if not tool then
            return false, "Scrambled consumable tool not found"
        end

        if alreadyEquipped and tool.Parent == char then
            return true, tool
        end

        local ok = pcall(function()
            hum:EquipTool(tool)
        end)

        if not ok then
            return false, "Failed to equip Scrambled consumable"
        end

        task.wait(0.10)

        if tool.Parent == char then
            return true, tool
        end

        return false, "Scrambled consumable did not equip"
    end

    local function invokeMutationConsumable(uid)
        local equipped, equipInfo = ensureMutationConsumableEquipped()

        if not equipped then
            return false, "equip_failed", {
                Success = false,
                Message = tostring(equipInfo),
            }
        end

        local m = loadEventUtilityModules()
        local remote =
            m.Remotes
            and m.Remotes.BossMastery
            and m.Remotes.BossMastery.AskUseMutationConsumable

        if not remote then
            return false, "remote_missing", nil
        end

        local ok, result = pcall(function()
            return remote:InvokeServer(uid)
        end)

        if not ok or type(result) ~= "table" then
            return false, "error", result
        end

        if result.Success ~= true then
            return false, "rejected", result
        end

        -- Success=true means the server processed one consumable attempt.
        -- This includes a fizzled mutation roll, so decrement our local
        -- effective count immediately while Save.Get() catches up.
        markMutationConsumableSpent()

        if result.Mutated == true then
            EventUtilityRuntime.mutationCompletedUids[
                tostring(uid)
            ] = true

            return true, "mutated", result
        end

        return false, "fizzled", result
    end

    local function chooseNextConsumableEgg()
        local eggs = readMyPlacedEggs()

        local bestUid = nil
        local bestRecord = nil
        local bestRarityNumber = -math.huge

        local m = loadEventUtilityModules()
        local assets = m.Assets
        local directory = assets and (assets.Directory or assets)

        for uid, record in pairs(eggs) do
            local uidKey = tostring(uid)
            local retryAfter =
                EventUtilityRuntime.mutationRetryAfter[
                    uidKey
                ]

            if not EventUtilityRuntime
                    .mutationCompletedUids[uidKey]
                and (
                    not retryAfter
                    or tick() >= retryAfter
                )
                and isPlacedEggConsumableEligible(record)
            then
                local rarityName = getPlacedEggRarityName(record)

                if rarityName and isConsumableRaritySelected(rarityName) then
                    local cfg = directory and directory[record.AssetCategory]
                    local rarityNumber =
                        cfg
                        and cfg.Rarity
                        and tonumber(cfg.Rarity.RarityNumber)
                        or 0

                    if not bestRecord
                        or rarityNumber > bestRarityNumber
                        or (
                            rarityNumber == bestRarityNumber
                            and tostring(uid) < tostring(bestUid)
                        )
                    then
                        bestUid = tostring(uid)
                        bestRecord = record
                        bestRarityNumber = rarityNumber
                    end
                end
            end
        end

        return bestUid, bestRecord
    end

    local function runAutoConsumableEngine()
        if EventUtilityRuntime.consumableRunning then return end
        EventUtilityRuntime.consumableRunning = true

        while EventCfg.autoConsumable do
            if isScrambleEventBusy() then
                setConsumableUtilityStatus("Waiting for Auto Boss")
                refreshEventUtilityLabels()
                task.wait(0.35)
                continue
            end

            if getMutationConsumableCount() <= 0 then
                setConsumableUtilityStatus("No Scrambled Mutation tool/stack detected")
                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            if not next(EventCfg.consumableRarities) then
                setConsumableUtilityStatus("Select rarity")
                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            local uid, record = chooseNextConsumableEgg()

            if not uid or not record then
                setConsumableUtilityStatus("No eligible selected-rarity egg")
                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            local rarityName =
                getPlacedEggRarityName(record) or "Unknown"

            setConsumableUtilityStatus(
                string.format(
                    "Equipping Scrambled Mutation -> %s",
                    rarityName
                )
            )
            refreshEventUtilityLabels()

            local equipped, equipInfo =
                ensureMutationConsumableEquipped()

            if not equipped then
                setConsumableUtilityStatus(
                    tostring(
                        equipInfo
                        or "Scrambled Mutation tool not found"
                    )
                )
                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            local targetPos, positionError, penInfo =
                EventUtilityRuntime.resolveMutationEggPosition(
                    record
                )

            if not targetPos then
                setConsumableUtilityStatus(
                    tostring(
                        positionError
                        or "Egg position unavailable"
                    )
                )
                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            setConsumableUtilityStatus(
                string.format("Moving to %s egg...", rarityName)
            )
            refreshEventUtilityLabels()

            local reached =
                DHub.MovementService:Move(
                    targetPos + Vector3.new(0, 2, 0),
                    {
                        owner = "Fuse",
                        priority = DHub.MovementService.Priorities.Fuse,
                        method = Cfg.farmMethod,
                        speed = Cfg.walkSpeed,
                        stopDistance = 5,
                        keepUnequipped = false,
                        requireBypass = Cfg.farmMethod == "Fast",
                        timeout = 25,
                        shouldContinue = function()
                            return EventCfg.autoConsumable
                                and not isScrambleEventBusy()
                        end,
                    }
                ) == true

            if not EventCfg.autoConsumable then break end

            if not reached then
                setConsumableUtilityStatus(
                    isScrambleEventBusy()
                    and "Paused for Auto Boss"
                    or "Could not reach target egg"
                )
                refreshEventUtilityLabels()
                task.wait(0.50)
                continue
            end

            equipped, equipInfo =
                ensureMutationConsumableEquipped()

            if not equipped then
                setConsumableUtilityStatus(
                    tostring(equipInfo or "Consumable equip lost")
                )
                refreshEventUtilityLabels()
                task.wait(0.50)
                continue
            end

            local promptReady = false
            local promptDeadline = tick() + 1.50

            setConsumableUtilityStatus(
                string.format(
                    "At %s egg -> waiting mutation prompt...",
                    rarityName
                )
            )
            refreshEventUtilityLabels()

            while EventCfg.autoConsumable
                and not isScrambleEventBusy()
                and tick() < promptDeadline
            do
                local prompt =
                    EventUtilityRuntime.findMutationPromptNear(
                        penInfo and penInfo.plot,
                        targetPos
                    )

                if prompt then
                    promptReady = true
                    break
                end

                local root = getRoot()

                if not root
                    or (root.Position - targetPos).Magnitude > 7
                then
                    break
                end

                task.wait(0.08)
            end

            if isScrambleEventBusy() then
                setConsumableUtilityStatus("Paused for Auto Boss")
                refreshEventUtilityLabels()
                task.wait(0.35)
                continue
            end

            while EventCfg.autoConsumable do
                local freshEggs = readMyPlacedEggs()
                local fresh = freshEggs[uid]

                if not fresh
                    or not isPlacedEggConsumableEligible(fresh)
                    or EventUtilityRuntime.mutationCompletedUids[
                        tostring(uid)
                    ]
                then
                    break
                end

                if getMutationConsumableCount() <= 0 then
                    break
                end

                local root = getRoot()

                if not root
                    or (root.Position - targetPos).Magnitude > 8
                then
                    break
                end

                equipped, equipInfo =
                    ensureMutationConsumableEquipped()

                if not equipped then
                    setConsumableUtilityStatus(
                        tostring(
                            equipInfo
                            or "No valid Scrambled Mutation tool"
                        )
                    )
                    refreshEventUtilityLabels()
                    task.wait(0.50)
                    break
                end

                setConsumableUtilityStatus(
                    string.format(
                        "%s -> applying%s...",
                        rarityName,
                        promptReady and " at prompt" or ""
                    )
                )
                refreshEventUtilityLabels()

                local mutated, status, result =
                    invokeMutationConsumable(uid)

                if mutated then
                    local confirmDeadline = tick() + 3.0
                    local stateConfirmed = false

                    setConsumableUtilityStatus(
                        string.format(
                            "%s mutated -> syncing...",
                            rarityName
                        )
                    )

                    while EventCfg.autoConsumable
                        and tick() < confirmDeadline
                    do
                        local confirmEggs = readMyPlacedEggs()
                        local confirmRecord = confirmEggs[uid]

                        if not confirmRecord
                            or hasBossMutation(confirmRecord)
                        then
                            stateConfirmed = true
                            break
                        end

                        task.wait(0.10)
                    end

                    setConsumableUtilityStatus(
                        stateConfirmed
                        and string.format(
                            "%s mutation confirmed",
                            rarityName
                        )
                        or string.format(
                            "%s server-confirmed",
                            rarityName
                        )
                    )

                    refreshEventUtilityLabels()
                    task.wait(0.20)
                    break
                end

                if status == "fizzled" then
                    setConsumableUtilityStatus(
                        string.format(
                            "%s fizzled -> next consumable",
                            rarityName
                        )
                    )
                    refreshEventUtilityLabels()
                    task.wait(0.35)

                elseif status == "equip_failed" then
                    setConsumableUtilityStatus(
                        type(result) == "table"
                        and tostring(result.Message or "Equip failed")
                        or "Equip failed"
                    )
                    refreshEventUtilityLabels()
                    task.wait(0.50)
                    break

                elseif status == "rejected" then
                    EventUtilityRuntime.mutationRetryAfter[
                        tostring(uid)
                    ] = tick() + 3.0

                    setConsumableUtilityStatus(
                        type(result) == "table"
                        and tostring(
                            result.Message or "Mutation rejected"
                        )
                        or "Mutation rejected"
                    )
                    refreshEventUtilityLabels()
                    task.wait(0.65)
                    break

                else
                    setConsumableUtilityStatus("Mutation request error")
                    refreshEventUtilityLabels()
                    task.wait(0.75)
                    break
                end
            end

            task.wait(0.15)
        end

        EventUtilityRuntime.consumableRunning = false
        setConsumableUtilityStatus("Idle")
        refreshEventUtilityLabels()
    end

    local function selectedBossShopIdsInPriority()
        local ids = {}
        for _, uiName in ipairs(BOSS_SHOP_UI_ITEMS) do
            if EventCfg.bossShopItems[uiName] then
                local id = BOSS_SHOP_ID_BY_UI[uiName]
                if id then table.insert(ids, {id=id, uiName=uiName}) end
            end
        end
        return ids
    end

    local function getFreshScrambleShopState()
        if not RMT.ScrambleRequest then
            return nil, nil, "Scramble remote missing"
        end

        local ok, response = pcall(function()
            return RMT.ScrambleRequest:InvokeServer(
                "snapshot"
            )
        end)

        if not ok or type(response) ~= "table" then
            return nil, nil, "Snapshot failed"
        end

        local snapshot =
            type(response.Snapshot) == "table"
            and response.Snapshot
            or response

        local state =
            type(snapshot) == "table"
            and snapshot.State
            or nil

        local sequence =
            type(state) == "table"
            and tonumber(state.ShopSequence)
            or nil

        if not sequence then
            return snapshot,
                nil,
                "ShopSequence unavailable"
        end

        return snapshot, sequence, nil
    end

    local function buyScrambleShopItem(entry)
        if not entry or not entry.id then
            return false, "Invalid item"
        end

        local quote =
            SCRAMBLE_SHOP_QUOTE[entry.id]

        if not quote then
            return false, "Quote missing"
        end

        -- CRITICAL:
        -- Manual captures prove Sequence increments after every purchase.
        -- Always get a brand-new snapshot immediately before each request.
        local _, sequence, sequenceError =
            getFreshScrambleShopState()

        if not sequence then
            return false,
                sequenceError
                or "No ShopSequence"
        end

        local beforeSamples =
            getBossTokenCount()

        local ok, result =
            pcall(function()
                return RMT.ScrambleRequest:InvokeServer(
                    "Shop",
                    entry.id,
                    {
                        Quote = quote,
                        Sequence = sequence,
                    }
                )
            end)

        if not ok then
            return false,
                "Invoke failed: "
                .. tostring(result)
        end

        if type(result) == "table" then
            if result.Ok == false
                or result.Success == false
            then
                return false,
                    tostring(
                        result.Reason
                        or result.Message
                        or "Purchase rejected"
                    )
            end
        elseif result == false then
            return false, "Purchase rejected"
        end

        -- Re-snapshot after every accepted request.
        -- This refreshes Samples and, most importantly, advances our
        -- ShopSequence source for the next item.
        local afterSnapshot,
            afterSequence =
            getFreshScrambleShopState()

        pcall(function()
            ScrambleFarm.RefreshSnapshot()
        end)

        local afterSamples =
            getBossTokenCount()

        if afterSequence
            and afterSequence <= sequence
            and afterSamples >= beforeSamples
        then
            -- Don't instantly spam the same stale sequence.
            return false,
                "Purchase not confirmed"
        end

        return true,
            string.format(
                "Purchased | Seq %d -> %s",
                sequence,
                tostring(afterSequence or "?")
            )
    end

    local function runAutoBuyBossShopEngine()
        if EventUtilityRuntime.shopRunning then return end
        EventUtilityRuntime.shopRunning = true

        while EventCfg.autoBuyBossShop do
            local selected =
                selectedBossShopIdsInPriority()

            if #selected == 0 then
                setBossShopUtilityStatus(
                    "Select shop item"
                )

                refreshEventUtilityLabels()
                task.wait(0.75)
                continue
            end

            local samples =
                getBossTokenCount()

            local firstAffordable = nil
            local firstPrice = nil

            for _, entry in ipairs(selected) do
                local price =
                    SCRAMBLE_SHOP_PRICE[
                        entry.id
                    ]

                if price
                    and SCRAMBLE_SHOP_QUOTE[
                        entry.id
                    ]
                    and samples >= price
                then
                    firstAffordable = entry
                    firstPrice = price
                    break
                end
            end

            if firstAffordable then
                setBossShopUtilityStatus(
                    string.format(
                        "Buying %s [%d]...",
                        tostring(
                            firstAffordable.uiName
                        ),
                        tonumber(firstPrice) or 0
                    )
                )

                refreshEventUtilityLabels()

                local bought, message =
                    buyScrambleShopItem(
                        firstAffordable
                    )

                if bought then
                    setBossShopUtilityStatus(
                        string.format(
                            "%s purchased",
                            tostring(
                                firstAffordable.uiName
                            )
                        )
                    )

                    refreshEventUtilityLabels()

                    -- Manual captures show sequential transactions:
                    -- 71,72,73,74,75,76. Small spacing lets the server
                    -- publish the next authoritative ShopSequence.
                    task.wait(0.45)
                else
                    setBossShopUtilityStatus(
                        string.format(
                            "%s failed: %s",
                            tostring(
                                firstAffordable.uiName
                            ),
                            tostring(
                                message or "unknown"
                            )
                        )
                    )

                    refreshEventUtilityLabels()
                    task.wait(0.85)
                end
            else
                setBossShopUtilityStatus(
                    "Waiting for enough Samples"
                )

                refreshEventUtilityLabels()
                task.wait(0.75)
            end
        end

        EventUtilityRuntime.shopRunning = false
        setBossShopUtilityStatus("Idle")
        refreshEventUtilityLabels()
    end

    local function startAutoConsumableEngine()
        if EventCfg.autoConsumable
            and not EventUtilityRuntime.consumableRunning
        then
            task.spawn(runAutoConsumableEngine)
        end
    end

    local function startAutoBuyBossShopEngine()
        if EventCfg.autoBuyBossShop
            and not EventUtilityRuntime.shopRunning
        then
            task.spawn(runAutoBuyBossShopEngine)
        end
    end

    task.spawn(function()
        while DHub.LongAFKRuntime.alive do
            pcall(refreshEventUtilityLabels)
            task.wait(1.25)
        end
    end)

    return {
        Runtime = EventUtilityRuntime,
        Rarities = AUTO_CONSUMABLE_RARITIES,
        ShopItems = BOSS_SHOP_UI_ITEMS,

        StartConsumable = startAutoConsumableEngine,
        StartShop = startAutoBuyBossShopEngine,

        SetConsumableStatus = setConsumableUtilityStatus,
        SetShopStatus = setBossShopUtilityStatus,
        Refresh = refreshEventUtilityLabels,

        GetConsumableCount = getMutationConsumableCount,
        GetBossTokens = getBossTokenCount,
        GetSamples = getBossTokenCount,
    }
end)()

local FpsState = {
    enabled = false,
    savedShadows = nil,
    savedWater = nil,
    savedParticles = {},
    savedPostFx = {},
    conn = nil,

    renderDistance = 300,
    renderParts = {},
    renderPartSet = setmetatable({}, {__mode = "k"}),
    savedLocalTransparency = setmetatable({}, {__mode = "k"}),
    renderCursor = 1,
    renderGeneration = 0,
    renderBatch = 240,
}

local function applyFpsBoost(enabled)
    FpsState.enabled = enabled
    local Lighting = S.Lighting
    local POST = {BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true, DepthOfFieldEffect=true, SunRaysEffect=true}
    local KILL = {ParticleEmitter=true, Trail=true, Smoke=true, Fire=true, Sparkles=true}

    local function isProtectedFpsVisual(obj)
        if not obj then return false end

        local areaEggs =
            S.Workspace:FindFirstChild(
                "AreaEggSlotsClient"
            )

        if areaEggs
            and (
                obj == areaEggs
                or obj:IsDescendantOf(areaEggs)
            )
        then
            return true
        end

        local placedEggs =
            S.Workspace:FindFirstChild(
                "PlacedEggRenders"
            )

        if placedEggs
            and (
                obj == placedEggs
                or obj:IsDescendantOf(placedEggs)
            )
        then
            return true
        end

        local objects =
            S.Workspace:FindFirstChild(
                "__OBJECTS"
            )

        local areas =
            objects
            and objects:FindFirstChild(
                "Areas"
            )

        local guardAreas =
            areas
            and areas:FindFirstChild(
                "GuardAreas"
            )

        if guardAreas
            and (
                obj == guardAreas
                or obj:IsDescendantOf(guardAreas)
            )
        then
            return true
        end

        return false
    end

    local function isEggRenderProtected(obj)
        if not obj then
            return false
        end

        local areaEggs =
            S.Workspace:FindFirstChild(
                "AreaEggSlotsClient"
            )

        if areaEggs
            and (
                obj == areaEggs
                or obj:IsDescendantOf(areaEggs)
            )
        then
            return true
        end

        local placedEggs =
            S.Workspace:FindFirstChild(
                "PlacedEggRenders"
            )

        if placedEggs
            and (
                obj == placedEggs
                or obj:IsDescendantOf(placedEggs)
            )
        then
            return true
        end

        return false
    end

    local function isLocalCharacterPart(obj)
        local char=LP.Character

        return char
            and (
                obj==char
                or obj:IsDescendantOf(char)
            )
            or false
    end

    local function restoreRenderPart(part)
        local saved =
            FpsState.savedLocalTransparency[
                part
            ]

        if saved~=nil
            and part
            and part.Parent
        then
            pcall(function()
                part.LocalTransparencyModifier=
                    saved
            end)
        end
    end

    local function registerRenderPart(obj)
        if not obj
            or not obj:IsA("BasePart")
            or FpsState.renderPartSet[obj]
        then
            return
        end

        FpsState.renderPartSet[obj]=true
        FpsState.renderParts[
            #FpsState.renderParts+1
        ]=obj

        if FpsState.savedLocalTransparency[obj]==nil then
            local ok,value=pcall(function()
                return obj.LocalTransparencyModifier
            end)

            if ok then
                FpsState.savedLocalTransparency[obj]=value
            end
        end
    end

    local function processRenderPart(part,origin)
        if not part
            or not part.Parent
        then
            return
        end

        if isEggRenderProtected(part)
            or isLocalCharacterPart(part)
        then
            restoreRenderPart(part)
            return
        end

        local distance=
            (part.Position-origin).Magnitude

        pcall(function()
            if distance>
                (FpsState.renderDistance or 300)
            then
                part.LocalTransparencyModifier=1
            else
                local saved =
                    FpsState.savedLocalTransparency[
                        part
                    ]

                part.LocalTransparencyModifier=
                    saved~=nil and saved or 0
            end
        end)
    end

    local function startRenderCuller()
        FpsState.renderGeneration=
            (FpsState.renderGeneration or 0)+1

        local generation=
            FpsState.renderGeneration

        task.spawn(function()
            while FpsState.enabled
                and generation==
                    FpsState.renderGeneration
            do
                local root=getRoot()
                local camera=S.Workspace.CurrentCamera

                local origin=
                    root
                    and root.Position
                    or (
                        camera
                        and camera.CFrame.Position
                    )
                    or Vector3.zero

                local parts=
                    FpsState.renderParts

                local total=#parts

                if total<=0 then
                    task.wait(0.25)
                    continue
                end

                local cursor=
                    math.clamp(
                        FpsState.renderCursor or 1,
                        1,
                        math.max(1,total)
                    )

                local budget=
                    math.min(
                        FpsState.renderBatch or 240,
                        total
                    )

                for _=1,budget do
                    if cursor>total then
                        cursor=1
                    end

                    local part=parts[cursor]

                    if part and part.Parent then
                        processRenderPart(
                            part,
                            origin
                        )
                    end

                    cursor=cursor+1
                end

                FpsState.renderCursor=cursor

                task.wait(0.05)
            end
        end)
    end

    local function stopRenderCuller()
        FpsState.renderGeneration=
            (FpsState.renderGeneration or 0)+1

        for part in pairs(
            FpsState.savedLocalTransparency
        ) do
            restoreRenderPart(part)
        end

        table.clear(FpsState.renderParts)
        table.clear(FpsState.renderPartSet)

        FpsState.savedLocalTransparency=
            setmetatable({}, {__mode = "k"})

        FpsState.renderCursor=1
    end

    if enabled then
        pcall(function()
            if FpsState.savedShadows == nil then FpsState.savedShadows = Lighting.GlobalShadows end
            Lighting.GlobalShadows = false
        end)
        pcall(function()
            if S.Workspace.Terrain then
                if FpsState.savedWater == nil then FpsState.savedWater = S.Workspace.Terrain.WaterWaveSpeed end
                S.Workspace.Terrain.Decoration = false
                S.Workspace.Terrain.WaterWaveSize = 0
                S.Workspace.Terrain.WaterWaveSpeed = 0
            end
        end)
        for _, obj in ipairs(S.Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                registerRenderPart(obj)
            end

            if KILL[obj.ClassName]
                and not isProtectedFpsVisual(obj)
            then
                FpsState.savedParticles[obj] = obj.Enabled
                pcall(function() obj.Enabled = false end)
            elseif POST[obj.ClassName] then
                FpsState.savedPostFx[obj] = obj.Enabled
                pcall(function() obj.Enabled = false end)
            end
        end
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if POST[obj.ClassName] then
                FpsState.savedPostFx[obj] = obj.Enabled
                pcall(function() obj.Enabled = false end)
            end
        end
        if not FpsState.conn then
            FpsState.conn = S.Workspace.DescendantAdded:Connect(function(obj)
                if not FpsState.enabled then return end

                if obj:IsA("BasePart") then
                    registerRenderPart(obj)
                end

                if KILL[obj.ClassName]
                    and not isProtectedFpsVisual(obj)
                then
                    pcall(function()
                        obj.Enabled = false
                    end)
                elseif POST[obj.ClassName] then
                    pcall(function()
                        obj.Enabled = false
                    end)
                end
            end)
            table.insert(ScriptConnections, FpsState.conn)
        end

        startRenderCuller()
    else
        pcall(function() if FpsState.savedShadows ~= nil then Lighting.GlobalShadows = FpsState.savedShadows end end)
        pcall(function()
            if S.Workspace.Terrain and FpsState.savedWater ~= nil then
                S.Workspace.Terrain.Decoration = true
                S.Workspace.Terrain.WaterWaveSpeed = FpsState.savedWater
            end
        end)
        for obj, was in pairs(FpsState.savedParticles) do if obj and obj.Parent then pcall(function() obj.Enabled = was end) end end
        for obj, was in pairs(FpsState.savedPostFx) do if obj and obj.Parent then pcall(function() obj.Enabled = was end) end end
        table.clear(FpsState.savedParticles)
        table.clear(FpsState.savedPostFx)

        stopRenderCuller()

        if FpsState.conn then
            FpsState.conn:Disconnect()
            FpsState.conn = nil
        end
    end
end

local HopState = { lastHopCheck = tick() }

local function executeServerHop(method)
    method = method or MiscCfg.hopMethod or "Small Server"
    local placeId = PLACE_ID or game.PlaceId
    local currentJobId = game.JobId

    UpdateStatus("Searching small server...")
    local targetServer = nil

    if method == "Small Server" then
        local cursor = ""
        local minPlayers = math.huge

        for page = 1, 5 do
            local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s",
                tostring(placeId),
                cursor ~= "" and ("&cursor=" .. cursor) or "")

            local ok, res = pcall(function() return game:HttpGet(url) end)
            if not ok or type(res) ~= "string" or res == "" then break end

            local okJson, data = pcall(function() return S.HttpService:JSONDecode(res) end)
            if not okJson or not data or not data.data then break end

            for _, s in ipairs(data.data) do
                local plrs = tonumber(s.playing) or 0
                local maxP = tonumber(s.maxPlayers) or 12
                if s.id ~= currentJobId and plrs > 0 and plrs < maxP then
                    if plrs < minPlayers then
                        minPlayers = plrs
                        targetServer = s
                        if plrs <= 1 then break end
                    end
                end
            end

            if minPlayers <= 1 then break end
            if data.nextPageCursor and data.nextPageCursor ~= "" and data.nextPageCursor ~= "null" then
                cursor = data.nextPageCursor
            else
                break
            end
        end
    else
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(placeId))
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" and res ~= "" then
            local okJson, data = pcall(function() return S.HttpService:JSONDecode(res) end)
            if okJson and data and data.data then
                local valid = {}
                for _, s in ipairs(data.data) do
                    local plrs = tonumber(s.playing) or 0
                    local maxP = tonumber(s.maxPlayers) or 12
                    if s.id ~= currentJobId and plrs > 0 and plrs < maxP then table.insert(valid, s) end
                end
                if #valid > 0 then targetServer = valid[math.random(1, #valid)] end
            end
        end
    end

    if targetServer and targetServer.id then
        task.wait(0.5)
        pcall(function() S.TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LP) end)
        return true
    end

    pcall(function() S.TeleportService:Teleport(placeId, LP) end)
end

task.spawn(function()
    while true do
        task.wait(3)
        pcall(function()
            if ShopCfg.autoUpgradePlot then doAutoUpgradePlot() end
            if ShopCfg.autoUpgradeTread then doAutoUpgradeTreadmill() end
            if ShopCfg.autoFuse then doFuseOnce() end
            if MiscCfg.autoHop then
                local delaySec = (MiscCfg.hopDelay or 30) * 60
                if tick() - HopState.lastHopCheck >= delaySec then
                    HopState.lastHopCheck = tick()
                    executeServerHop(MiscCfg.hopMethod)
                end
            end
        end)
    end
end)

local function connectAntiBossEggPrompt(prompt)
    if not prompt
        or not prompt:IsA("ProximityPrompt")
        or AntiBossState.promptConnections[prompt]
    then
        return
    end

    if not isAntiBossEggPrompt(prompt) then
        return
    end

    local conn =
        prompt.Triggered:Connect(function(player)
            if player ~= LP then
                return
            end

            if not Cfg.antiBoss then
                return
            end

            -- FAST FARM owns its own carry -> DROP_POSITION -> re-carry
            -- transaction. Never start the old Anti Boss Safezone spam writer
            -- while this transaction is active, otherwise two Heartbeat CFrame
            -- writers fight (SAFEZONE vs DROP_POSITION) and the character can
            -- be server-corrected / killed even though the egg drops correctly.
            if Runtime.fastDropTransactionActive == true then
                return
            end

            local host =
                getAntiBossPromptHostPart(prompt)

            local triggeredInForest =
                host
                and isAntiBossForestPosition(
                    host.Position
                )
                or isAntiBossCurrentlyInForest()

            if triggeredInForest then
                return
            end

            task.delay(0.30, function()
                if not Cfg.antiBoss then
                    return
                end

                if Runtime.fastDropTransactionActive == true then
                    return
                end

                triggerAntiBossSpamTeleport()
            end)
        end)

    AntiBossState.promptConnections[prompt] =
        conn

    table.insert(
        ScriptConnections,
        conn
    )
end

local function installAntiBossPromptEngine()
    for _,obj in ipairs(
        S.Workspace:GetDescendants()
    ) do
        if obj:IsA("ProximityPrompt") then
            connectAntiBossEggPrompt(obj)
        end
    end
end

installAntiBossPromptEngine()

S.Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        task.defer(function()
            task.wait(0.05)

            if obj and obj.Parent then
                connectAntiBossEggPrompt(obj)
            end
        end)
    end
end)

local StandaloneAntiBossWatcherStarted = false
local function startStandaloneAntiBossWatcher()
    if StandaloneAntiBossWatcherStarted then return end
    StandaloneAntiBossWatcherStarted = true

    task.spawn(function()
        local wasCarrying = false

        while DHub.LongAFKRuntime.alive do
            local standaloneEnabled =
                Cfg.antiBoss
                and not Cfg.autoFarm

            if not standaloneEnabled then
                wasCarrying = false
                task.wait(0.35)
                continue
            end

            local carrying = false
            pcall(function()
                carrying = isCarryingEgg()
            end)

            if carrying and not wasCarrying then
                if not isAntiBossCurrentlyInForest() then
                    triggerAntiBossSpamTeleport()
                end
            end

            wasCarrying = carrying
            task.wait(0.08)
        end
    end)
end

attemptPickup = function(target, shouldContinue, deferEscape)
    local ok=DHub.CarryService:TryCarry(target,{timeout=2.25,shouldContinue=shouldContinue})
    if not ok then return false end
    if deferEscape then return true end
    instantCarryEscape()
    return true
end

local MainFarmLock = {
    target = nil,
    lostSince = nil,
    initialSafezoneDone = false,
    routeStagedUid = nil,
}

-- Shared normal-farm carry/deposit primitive.
-- Scramble Fuse uses this exact same path after locking a required egg.
local mainFarmCarryEscapeLocked


local function refreshLockedMainFarmTarget(lock)
    if not lock or not lock.target or not lock.target.uid then
        return false
    end

    local live =
        DHub.GlobalEggScanner:RefreshTarget(
            lock.target
        )

    if not live
        or tostring(live.uid)
            ~= tostring(lock.target.uid)
    then
        return false
    end

    lock.target = live
    lock.lastKnownPos = live.pos
    lock.lostSince = nil

    return true
end

local function getLockedEggLivePosition(lock)
    if not lock
        or not lock.target
        or not lock.target.uid
    then
        return nil
    end

    if not refreshLockedMainFarmTarget(lock) then
        return nil
    end

    local target = lock.target
    local uid = tostring(target.uid)

    local prompt =
        DHub.getEggPrompt(uid)
        or (
            target.pos
            and DHub.getEggPrompt(target.pos)
        )

    if prompt
        and prompt.Parent
        and prompt:IsDescendantOf(S.Workspace)
    then
        local host = prompt.Parent

        if host:IsA("Attachment")
            and host.Parent
            and host.Parent:IsA("BasePart")
        then
            host = host.Parent
        end

        if host:IsA("BasePart") then
            return host.Position
        end

        if host:IsA("Model") then
            local part =
                host.PrimaryPart
                or host:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if part then
                return part.Position
            end
        end
    end

    local model = nil

    pcall(function()
        model = DHub._modelForUid(uid)
    end)

    if model and model.Parent then
        if model:IsA("BasePart") then
            return model.Position
        end

        if model:IsA("Model") then
            local ok, pivot =
                pcall(function()
                    return model:GetPivot()
                end)

            if ok and typeof(pivot) == "CFrame" then
                return pivot.Position
            end
        end
    end

    if typeof(target.pos) == "Vector3" then
        return target.pos
    end

    return nil
end

local function WalkToLockedEggRealtime(
    lock,
    stopDistance,
    keepUnequipped,
    shouldContinue
)
    stopDistance = tonumber(stopDistance) or 4
    keepUnequipped = keepUnequipped == true

    Runtime.isAutoWalking = true

    local char, root, hum =
        ensureCharacter(5)

    if not char
        or not root
        or not hum
        or hum.Health <= 0
    then
        Runtime.isAutoWalking = false
        return false
    end

    local lastUnequip = 0
    local lastMoveAt = 0
    local lastGoal = nil
    local missingSince = nil
    local deadline = tick() + 60
    local lastBrakeAt = 0

    local function stopNativeWalk()
        local currentRoot = getRoot()
        local currentHum = getHumanoid()

        if currentRoot and currentHum then
            pcall(function()
                currentHum:Move(
                    Vector3.zero,
                    false
                )

                currentHum:MoveTo(
                    currentRoot.Position
                )
            end)
        end
    end

    local function cleanup(success)
        stopNativeWalk()

        if keepUnequipped then
            forceUnequipTools()
        end

        Runtime.isAutoWalking = false
        return success == true
    end

    local function allowed()
        if type(shouldContinue) == "function" then
            local ok, result =
                pcall(shouldContinue)

            if not ok or result ~= true then
                return false
            end
        end

        return (
                Cfg.autoFarm == true
                or EventCfg.autoFuseScrambler == true
            )
            and not isCarryingEgg()
    end

    local function getPromptReach()
        if not lock
            or not lock.target
            or not lock.target.uid
        then
            return 4.5
        end

        local prompt =
            DHub.getEggPrompt(
                tostring(lock.target.uid)
            )

        if prompt
            and prompt.Parent
            and prompt:IsDescendantOf(
                S.Workspace
            )
        then
            local maxDistance =
                tonumber(
                    prompt.MaxActivationDistance
                )

            if maxDistance
                and maxDistance > 0
            then
                return math.clamp(
                    maxDistance - 0.85,
                    3.5,
                    5.25
                )
            end
        end

        return 4.5
    end

    local function horizontalSpeed(currentRoot)
        local velocity =
            currentRoot.AssemblyLinearVelocity

        return Vector3.new(
            velocity.X,
            0,
            velocity.Z
        ).Magnitude
    end

    local function distances(currentRoot, targetPos)
        local delta =
            targetPos - currentRoot.Position

        local flat =
            Vector3.new(
                delta.X,
                0,
                delta.Z
            )

        return delta.Magnitude, flat.Magnitude, flat
    end

    if keepUnequipped then
        forceUnequipTools()
        lastUnequip = tick()
    end

    if isPlayerOnTreadmill
        and isPlayerOnTreadmill()
    then
        -- treadmill release deferred until an actual Safezone route
        task.wait(0.05)
    end

    while allowed()
        and tick() < deadline
    do
        char = getChar()
        root = getRoot()
        hum = getHumanoid()

        if not char
            or not root
            or not hum
            or hum.Health <= 0
        then
            return cleanup(false)
        end

        if keepUnequipped
            and tick() - lastUnequip >= 0.10
        then
            forceUnequipTools()
            lastUnequip = tick()
        end

        local livePos =
            getLockedEggLivePosition(lock)

        if typeof(livePos) ~= "Vector3" then
            missingSince =
                missingSince or tick()

            if tick() - missingSince >= 0.90 then
                return cleanup(false)
            end

            S.RunService.Heartbeat:Wait()
            continue
        end

        missingSince = nil

        local fullDistance,
            flatDistance,
            flatDelta =
            distances(root, livePos)

        local promptReach =
            getPromptReach()

        if fullDistance <= promptReach
            or (
                flatDistance <= 2.65
                and math.abs(
                    livePos.Y
                    - root.Position.Y
                ) <= 5.0
            )
        then
            stopNativeWalk()

            local settleUntil =
                tick() + 0.10

            while allowed()
                and tick() < settleUntil
            do
                stopNativeWalk()
                S.RunService.Heartbeat:Wait()
            end

            local settledRoot = getRoot()
            local settledPos =
                getLockedEggLivePosition(lock)

            if settledRoot
                and typeof(settledPos)
                    == "Vector3"
            then
                local settledFull,
                    settledFlat =
                    distances(
                        settledRoot,
                        settledPos
                    )

                if settledFull <= promptReach + 0.35
                    or settledFlat <= 3.0
                then
                    return cleanup(true)
                end
            end
        end

        local speed =
            horizontalSpeed(root)

        local nativeSpeed =
            math.max(
                tonumber(hum.WalkSpeed) or 16,
                1
            )

        local predictedSpeed =
            math.max(
                speed,
                nativeSpeed * 0.80,
                1
            )

        local brakeLead =
            math.clamp(
                predictedSpeed * 0.16,
                1.65,
                8.0
            )

        local desiredStandOff =
            math.clamp(
                math.min(
                    stopDistance - 0.65,
                    promptReach - 1.0
                ),
                2.25,
                3.25
            )

        local shouldBrake =
            flatDistance
            <= desiredStandOff + brakeLead

        if shouldBrake
            and tick() - lastBrakeAt >= 0.06
        then
            lastBrakeAt = tick()

            stopNativeWalk()

            S.RunService.Heartbeat:Wait()

            root = getRoot()
            hum = getHumanoid()

            if not root
                or not hum
                or hum.Health <= 0
            then
                return cleanup(false)
            end

            livePos =
                getLockedEggLivePosition(lock)

            if typeof(livePos) == "Vector3" then
                fullDistance,
                    flatDistance,
                    flatDelta =
                    distances(root, livePos)

                promptReach =
                    getPromptReach()

                if fullDistance <= promptReach
                    or flatDistance <= 2.85
                then
                    return cleanup(true)
                end
            end
        end

        if typeof(livePos) ~= "Vector3" then
            S.RunService.Heartbeat:Wait()
            continue
        end

        fullDistance,
            flatDistance,
            flatDelta =
            distances(root, livePos)

        if flatDistance <= 0.10 then
            stopNativeWalk()
            return cleanup(
                fullDistance
                <= getPromptReach() + 0.5
            )
        end

        local direction =
            flatDelta / flatDistance

        local standOff =
            math.clamp(
                math.min(
                    stopDistance - 0.65,
                    getPromptReach() - 1.0
                ),
                2.25,
                3.25
            )

        local approachPos =
            Vector3.new(
                livePos.X
                    - direction.X * standOff,
                livePos.Y,
                livePos.Z
                    - direction.Z * standOff
            )

        local goalChanged =
            typeof(lastGoal) ~= "Vector3"
            or (
                lastGoal
                - approachPos
            ).Magnitude >= 0.45

        if goalChanged
            or tick() - lastMoveAt >= 0.06
        then
            pcall(function()
                hum:MoveTo(approachPos)
            end)

            lastGoal = approachPos
            lastMoveAt = tick()
        end

        S.RunService.Heartbeat:Wait()
    end

    return cleanup(false)
end


-- ============================================================
-- DR. SCRAMBLE'S LAB — AUTO FUSE SCRAMBLER
--
-- Proven live controller:
--   RF/ScrambleTradeIn/AskState
--   PlayerGui.DrScrambleTradeIn / DrScrambleTradeInNEW
--   Main.SacrificeInputs.Input1..3.Empty.Add
--   Inventory.ScrollingFrame.Pet
--   Main.Sacrifice
--
-- Add/selection and final AskTradeIn payload are intentionally delegated
-- to the game's own GUI callbacks. No guessed AskTradeIn argument shape.
-- ============================================================

DHub.ScrambleFuse = (function()
    local RuntimeSF = {
        running = false,
        generation = 0,

        -- Fresh linear Fuse flow:
        -- REQUIREMENTS -> INVENTORY -> WAIT/FARM -> DEPOSIT -> repeat.
        phase = "IDLE",
        lastStatus = "",

        requirements = nil,
        requirementSignature = "",
        selectedUids = {},

        pendingCarryCategory = nil,
        pendingCarryBefore = 0,
        pendingCarryUid = nil,

        rewardWaiting = false,
        rewardBaselineUids = nil,

        resetEpochHandled = -1,

        statusLabel = nil,
        slotLabels = {},

        lastSubmitAt = 0,
        lastFinishRevealAt = 0,
    }

    local function setStatus(message)
        message = tostring(message or "Idle")

        if RuntimeSF.lastStatus == message then
            return
        end

        RuntimeSF.lastStatus = message

        if RuntimeSF.statusLabel
            and RuntimeSF.statusLabel.Parent
        then
            RuntimeSF.statusLabel.Text =
                "Scramble Fuse: " .. message
        end
    end

    local function alive(gen)
        return EventCfg.autoFuseScrambler == true
            and RuntimeSF.running == true
            and RuntimeSF.generation == gen
    end

    local function bossBusy()
        return DHub.EventBossPriority
            and (
                DHub.EventBossPriority.requested == true
                or DHub.EventBossPriority.active == true
            )
            or false
    end

    local function askState()
        local remote =
            RMT.ScrambleTradeAskState

        if not remote
            or not remote:IsA(
                "RemoteFunction"
            )
        then
            return nil
        end

        local ok, state =
            pcall(function()
                return remote:InvokeServer()
            end)

        if ok and type(state) == "table" then
            -- IMPORTANT:
            -- AskState is only a network read. It MUST NOT mutate the active
            -- requirement cycle. Reward polling calls AskState repeatedly,
            -- and the old mutation mixed a NEW server recipe with OLD GUI
            -- slot Full/Empty state.
            RuntimeSF.state = state
            return state
        end

        return nil
    end

    local function normalized(textValue)
        return tostring(textValue or "")
            :lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
    end

    local function requirementKey(value)
        local key =
            normalized(value)
                :gsub("%s+", " ")

        -- AskState requirements use base category names while some live
        -- EggState/save revisions expose the same category with " Egg".
        key = key:gsub("%s+egg$", "")

        return key
    end

    local function sameRequirementCategory(a, b)
        local ka = requirementKey(a)
        local kb = requirementKey(b)

        return ka ~= ""
            and kb ~= ""
            and ka == kb
    end

    local function getBestRequiredEgg(
        category,
        origin
    )
        if typeof(origin) ~= "Vector3" then
            local root = getRoot()
            origin =
                root
                and root.Position
                or Vector3.zero
        end

        -- EXACT same scanner source as normal Auto Farm Egg.
        local target =
            DHub.GlobalEggScanner
                :GetBestByCategory(
                    category,
                    origin
                )

        if target then
            return target
        end

        -- Requirement state sometimes omits the literal " Egg" suffix.
        local categoryText =
            tostring(category or "")

        if categoryText ~= ""
            and not normalized(categoryText)
                :match("%s+egg$")
        then
            return DHub.GlobalEggScanner
                :GetBestByCategory(
                    categoryText .. " Egg",
                    origin
                )
        end

        return nil
    end

    local function getGui()
        local pg =
            LP:FindFirstChild(
                "PlayerGui"
            )

        if not pg then
            return nil
        end

        local normal =
            pg:FindFirstChild(
                "DrScrambleTradeIn"
            )

        local newer =
            pg:FindFirstChild(
                "DrScrambleTradeInNEW"
            )

        local function enabled(gui)
            if not gui then
                return false
            end

            if gui:IsA("ScreenGui") then
                return gui.Enabled == true
            end

            if gui:IsA("GuiObject") then
                return gui.Visible == true
            end

            return true
        end

        if enabled(normal) then
            return normal
        end

        if enabled(newer) then
            return newer
        end

        -- Both controllers are known to use the same hierarchy. A disabled
        -- ScreenGui can still retain its Activated connections, so use the
        -- active-version root first as a fallback.
        return normal or newer
    end

    local function getMainAndInventory()
        local gui = getGui()

        if not gui then
            return nil, nil, nil
        end

        return gui,
            gui:FindFirstChild(
                "DrScrambleTradeInMain"
            ),
            gui:FindFirstChild(
                "DrScrambleTradeInInventory"
            )
    end

    local function slotFrame(index)
        local _, main =
            getMainAndInventory()

        local inputs =
            main
            and main:FindFirstChild(
                "SacrificeInputs"
            )

        return inputs
            and inputs:FindFirstChild(
                "Input"
                .. tostring(index)
            )
            or nil
    end

    local function slotIsFull(index)
        local slot = slotFrame(index)
        local full =
            slot
            and slot:FindFirstChild(
                "Full"
            )

        return full
            and full.Visible == true
            or false
    end

    local function readOwnedEggsRaw()
        -- IMPORTANT:
        -- Scramble Lab needs the CURRENT UNPLACED BACKPACK inventory.
        -- Save.EggInventory is authoritative for that state.
        --
        -- EggState.ReadOwnerEggs can retain stale owner records after an egg
        -- was consumed by Trade-In. That stale cache was why D-HUB showed
        -- "(Owned)" and spammed "You need an unplaced ... egg" until night
        -- reset rebuilt EggState.
        local save = nil

        pcall(function()
            save =
                require(
                    S.ReplicatedStorage
                        .Shared.Save
                ).Get()
        end)

        if save
            and type(
                save.EggInventory
            ) == "table"
        then
            -- Even an EMPTY table is authoritative.
            return save.EggInventory
        end

        -- Fallback only if Save itself is unavailable.
        local ownerEggs = nil

        pcall(function()
            local EggState =
                require(
                    S.ReplicatedStorage
                        .Client.EggState
                )

            if EggState
                and EggState.ReadOwnerEggs
            then
                ownerEggs =
                    EggState.ReadOwnerEggs(
                        LP.UserId
                    )
            end
        end)

        return type(ownerEggs)
                == "table"
            and ownerEggs
            or {}
    end

    local function getOwnedEgg(
        category,
        excluded
    )
        local eggInv =
            readOwnedEggsRaw()

        for uid, data in pairs(eggInv) do
            local uidString =
                tostring(uid)

            if type(data) == "table"
                and sameRequirementCategory(
                    data.AssetCategory,
                    category
                )
                and not data.Placement
                and not (
                    excluded
                    and excluded[
                        uidString
                    ]
                )
            then
                return uidString, data
            end
        end

        return nil, nil
    end

    local function countOwnedRequiredEggs(
        category
    )
        local eggInv =
            readOwnedEggsRaw()

        local count = 0

        for _, data in pairs(eggInv) do
            if type(data) == "table"
                and not data.Placement
                and sameRequirementCategory(
                    data.AssetCategory,
                    category
                )
            then
                count = count + 1
            end
        end

        return count
    end

    local function waitOwnedCategoryIncrease(
        category,
        beforeCount,
        timeout,
        gen
    )
        local deadline =
            tick() + (timeout or 4.0)

        while alive(gen)
            and tick() < deadline
        do
            if countOwnedRequiredEggs(
                category
            ) > (beforeCount or 0)
            then
                return true
            end

            task.wait(0.08)
        end

        return countOwnedRequiredEggs(
            category
        ) > (beforeCount or 0)
    end

    local function deepContainsUid(
        value,
        wanted,
        depth,
        seen
    )
        if depth <= 0 then
            return false
        end

        local valueType =
            type(value)

        if valueType == "string" then
            return value == wanted
        end

        if valueType == "table" then
            if seen[value] then
                return false
            end

            seen[value] = true

            for key, child in pairs(value) do
                if tostring(key) == wanted
                    or deepContainsUid(
                        child,
                        wanted,
                        depth - 1,
                        seen
                    )
                then
                    return true
                end
            end
        end

        return false
    end

    local function connectionHasUid(
        button,
        wantedUid
    )
        if not wantedUid
            or type(getconnections)
                ~= "function"
            or not debug
            or type(debug.getupvalues)
                ~= "function"
        then
            return false
        end

        local okConnections,
            connections =
            pcall(
                getconnections,
                button.Activated
            )

        if not okConnections
            or type(connections)
                ~= "table"
        then
            return false
        end

        local seenFunctions = {}

        local function inspectFunction(
            fn,
            depth
        )
            if type(fn) ~= "function"
                or depth <= 0
                or seenFunctions[fn]
            then
                return false
            end

            seenFunctions[fn] = true

            local ok, values =
                pcall(
                    debug.getupvalues,
                    fn
                )

            if not ok
                or type(values)
                    ~= "table"
            then
                return false
            end

            for _, value in pairs(values) do
                if type(value) == "string"
                    and value == wantedUid
                then
                    return true
                end

                if type(value) == "table"
                    and deepContainsUid(
                        value,
                        wantedUid,
                        3,
                        {}
                    )
                then
                    return true
                end

                if type(value) == "function"
                    and inspectFunction(
                        value,
                        depth - 1
                    )
                then
                    return true
                end
            end

            return false
        end

        for _, connection
            in ipairs(connections)
        do
            local okFn, fn =
                pcall(function()
                    return connection.Function
                end)

            if okFn
                and inspectFunction(
                    fn,
                    4
                )
            then
                return true
            end
        end

        return false
    end

    local function findPickerItem(
        inventory,
        category,
        uid
    )
        if not inventory then
            return nil
        end

        local scrolling =
            inventory:FindFirstChild(
                "ScrollingFrame"
            )

        if not scrolling then
            return nil
        end

        -- 1) Exact UID closure match, when available.
        if uid then
            for _, obj in ipairs(
                scrolling:GetDescendants()
            ) do
                if obj:IsA("GuiButton")
                    and obj.Visible ~= false
                    and connectionHasUid(
                        obj,
                        tostring(uid)
                    )
                then
                    return obj
                end
            end
        end

        -- 2) Same strategy as the old Rift helper:
        -- search visible text for the required category, then resolve
        -- its surrounding GuiButton.
        for _, obj in ipairs(
            scrolling:GetDescendants()
        ) do
            if (
                obj:IsA("TextLabel")
                or obj:IsA("TextButton")
            )
                and obj.Visible ~= false
            then
                local txt =
                    tostring(
                        obj.Text or ""
                    )

                if sameRequirementCategory(
                    txt,
                    category
                )
                then
                    local btn =
                        _resolveGuiButton(
                            obj,
                            inventory
                        )

                    if btn then
                        return btn
                    end
                end
            end
        end

        -- 3) The game's picker is already filtered to the slot's required
        -- egg. If title matching failed, use the first REAL rendered card,
        -- while skipping the template "Pet Name".
        for _, obj in ipairs(
            scrolling:GetDescendants()
        ) do
            if obj:IsA("GuiButton")
                and obj.Visible ~= false
            then
                local title =
                    obj:FindFirstChild(
                        "Title",
                        true
                    )

                local titleText =
                    title
                    and tostring(
                        title.Text or ""
                    )
                    or ""

                if normalized(titleText)
                    ~= "pet name"
                    and normalized(titleText)
                    ~= ""
                then
                    return obj
                end
            end
        end

        return nil
    end

    local function addEggToSlot(
        index,
        category,
        uid
    )
        if slotIsFull(index) then
            return true
        end

        -- Hard safety: Add is only legal after owner inventory confirms
        -- a concrete unplaced egg UID for this requirement.
        if uid == nil
            or tostring(uid) == ""
        then
            return false
        end

        local gui,
            main,
            inventory =
            getMainAndInventory()

        if not gui
            or not main
            or not inventory
        then
            setStatus(
                "Waiting Dr. Scramble Lab GUI..."
            )

            return false
        end

        local slot =
            slotFrame(index)

        local full =
            slot
            and slot:FindFirstChild(
                "Full"
            )

        local empty =
            slot
            and slot:FindFirstChild(
                "Empty"
            )

        local add =
            empty
            and empty:FindFirstChild(
                "Add"
            )

        if not add
            or not add:IsA("GuiButton")
        then
            return false
        end

        _fireActivated(add)

        -- Old Rift helper used a short deterministic UI settle.
        task.wait(0.18)

        local pickerItem =
            findPickerItem(
                inventory,
                category,
                uid
            )

        if not pickerItem then
            local close =
                inventory:FindFirstChild(
                    "Close"
                )

            if close
                and close:IsA("GuiButton")
            then
                _fireActivated(close)
            end

            return false
        end

        _fireActivated(
            pickerItem
        )

        local deadline =
            tick() + 1.25

        while EventCfg.autoFuseScrambler
            and tick() < deadline
        do
            if full
                and full.Visible
            then
                if uid ~= nil then
                    RuntimeSF.selectedUids[
                        tostring(uid)
                    ] = true
                end

                return true
            end

            task.wait(0.05)
        end

        return full
            and full.Visible
            or false
    end

    local function updateSlotLabels(
        requirements
    )
        requirements =
            requirements or {}

        for index = 1, 3 do
            local label =
                RuntimeSF.slotLabels[
                    index
                ]

            if label
                and label.Parent
            then
                local category =
                    requirements[index]

                if not category then
                    label.Text =
                        string.format(
                            "[ ] Slot %d (Waiting...)",
                            index
                        )

                    label.TextColor3 =
                        Color3.fromRGB(237, 232, 255)
                elseif slotIsFull(index) then
                    label.Text =
                        string.format(
                            "[✓] %s (Added)",
                            tostring(category)
                        )

                    label.TextColor3 =
                        Color3.fromRGB(
                            80,
                            255,
                            120
                        )
                else
                    local uid =
                        getOwnedEgg(
                            category,
                            RuntimeSF.selectedUids
                        )

                    label.Text =
                        uid
                        and string.format(
                            "[•] %s (Owned)",
                            tostring(category)
                        )
                        or string.format(
                            "[ ] %s (Need Egg)",
                            tostring(category)
                        )

                    label.TextColor3 =
                        uid
                        and Color3.fromRGB(
                            255,
                            220,
                            90
                        )
                        or Color3.fromRGB(237, 232, 255)
                end
            end
        end
    end

    local function refreshScrambleStatuses(
        requirements
    )
        requirements = requirements or {}

        local statuses = {}
        local usedEggUids = {}
        local fullCount = 0
        local eggInv = readOwnedEggsRaw()

        for index, category in ipairs(requirements) do
            local st = {
                slotIndex = index,
                category = category,
                full = slotIsFull(index),
                status = "Need Egg",
                eggUid = nil,
            }

            if st.full then
                st.status = "Added"
                fullCount = fullCount + 1
            else
                for uid, eggData in pairs(eggInv) do
                    local uidString = tostring(uid)

                    if not usedEggUids[uidString]
                        and type(eggData) == "table"
                        and not eggData.Placement
                        and sameRequirementCategory(
                            eggData.AssetCategory,
                            category
                        )
                    then
                        st.status = "Egg in Backpack"
                        st.eggUid = uidString
                        usedEggUids[uidString] = true
                        break
                    end
                end
            end

            statuses[index] = st

            local label = RuntimeSF.slotLabels[index]

            if label and label.Parent then
                if st.full then
                    label.Text = string.format(
                        "[✓] %s (Added)",
                        tostring(category)
                    )
                    label.TextColor3 =
                        Color3.fromRGB(80, 255, 120)

                elseif st.eggUid then
                    label.Text = string.format(
                        "[•] %s (Egg in Backpack)",
                        tostring(category)
                    )
                    label.TextColor3 =
                        Color3.fromRGB(255, 220, 90)

                else
                    label.Text = string.format(
                        "[ ] %s (Need Egg)",
                        tostring(category)
                    )
                    label.TextColor3 =
                        Color3.fromRGB(237, 232, 255)
                end
            end
        end

        RuntimeSF.slotStatuses = statuses
        return statuses, fullCount, #requirements
    end

    local function requirementsSignature(
        requirements
    )
        local parts = {}

        for index = 1,
            math.max(
                #requirements,
                3
            )
        do
            parts[index] =
                tostring(
                    requirements[index]
                    or ""
                )
        end

        return table.concat(
            parts,
            "\31"
        )
    end

    local function waitMainFarmHandoff(
        gen
    )
        while alive(gen)
            and not bossBusy()
            and Cfg.autoFarm
            and DHub.EventWavePriority
            and DHub.EventWavePriority
                :IsMainFarmBusy()
        do
            setStatus(
                "Waiting current Egg action..."
            )

            task.wait(0.08)
        end

        return alive(gen)
            and not bossBusy()
    end

    local function copyRequirements(source)
        local result = {}

        if type(source) == "table" then
            for index, value in ipairs(source) do
                result[index] =
                    tostring(value)
            end
        end

        return result
    end

    local function clearRequirementScan()
        RuntimeSF.requirements = nil
        RuntimeSF.requirementSignature = ""
        RuntimeSF.selectedUids = {}
    end

    local function clearPendingCarry()
        RuntimeSF.pendingCarryCategory = nil
        RuntimeSF.pendingCarryBefore = 0
        RuntimeSF.pendingCarryUid = nil
    end

    local function snapshotOwnedUids()
        local result = {}

        for uid in pairs(
            readOwnedEggsRaw()
        ) do
            result[tostring(uid)] = true
        end

        return result
    end

    local function hasNewOwnedUid(
        baseline
    )
        baseline =
            baseline or {}

        for uid in pairs(
            readOwnedEggsRaw()
        ) do
            uid = tostring(uid)

            if not baseline[uid] then
                return true, uid
            end
        end

        return false, nil
    end

    local function scanRequirementsOnce()
        RuntimeSF.phase = "SCAN_REQUIREMENTS"
        setStatus("Scanning Lab requirements...")

        local state =
            askState()

        if not state then
            return nil, "no_state"
        end

        if state.PendingReward == true then
            return nil, "pending_reward"
        end

        local requirements =
            copyRequirements(
                state.Requirements
            )

        if #requirements == 0 then
            return nil, "empty"
        end

        RuntimeSF.requirements =
            requirements

        RuntimeSF.requirementSignature =
            requirementsSignature(
                requirements
            )

        RuntimeSF.phase =
            "SCAN_INVENTORY"

        updateSlotLabels(
            requirements
        )

        return requirements, nil
    end

    local function releaseIdleTreadmill()
        local mounted = false
        local physicallyNear = false
        local idleOwner = false

        pcall(function()
            mounted =
                DHub.TreadmillMount
                and DHub.TreadmillMount.active == true
                or false

            physicallyNear =
                isPlayerOnTreadmill() == true

            idleOwner =
                DHub.MovementService
                and DHub.MovementService.currentOwner
                    == "IdleTreadmill"
                or false
        end)

        if DHub.MovementService
            and DHub.MovementService.currentOwner
                == "IdleTreadmill"
        then
            DHub.MovementService:Cancel(
                "IdleTreadmill"
            )
        end

        if DHub.GlobalIdleTreadmill then
            DHub.GlobalIdleTreadmill.stableIdleSince =
                nil

            DHub.GlobalIdleTreadmill.resumeNotBefore =
                tick() + 1.0
        end

        if mounted
            or physicallyNear
        then
            -- treadmill release deferred until an actual Safezone route
            task.wait(0.12)
        elseif idleOwner then
            task.wait(0.08)
        end
    end

    local function moveFuseSafezone(
        gen
    )
        RuntimeSF.phase =
            "SAFEZONE"

        setStatus(
            "Safezone staging..."
        )

        releaseTreadmillForSafezoneRoute(
            SAFEZONE_POS
        )

        releaseIdleTreadmill()

        local function aliveMove()
            return alive(gen)
                and not bossBusy()
        end

        local root = getRoot()
        local humanoid = getHumanoid()

        if not root
            or not humanoid
            or humanoid.Health <= 0
        then
            return false
        end

        if (
            root.Position
            - SAFEZONE_POS
        ).Magnitude <= 7
        then
            return true
        end

        -- Always pathfind Fuse staging.
        -- Corner plots can be physically close to Safezone but blocked by wall.
        local path =
            S.PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentCanClimb = false,
                WaypointSpacing = 8,
            })

        local computed =
            pcall(function()
                path:ComputeAsync(
                    root.Position,
                    SAFEZONE_POS
                )
            end)

        if computed
            and path.Status
                == Enum.PathStatus.Success
        then
            for _, waypoint
                in ipairs(
                    path:GetWaypoints()
                )
            do
                if not aliveMove() then
                    return false
                end

                releaseTreadmillForSafezoneRoute(
                    SAFEZONE_POS
                )

                root = getRoot()
                humanoid = getHumanoid()

                if not root
                    or not humanoid
                then
                    return false
                end

                if waypoint.Action
                    == Enum.PathWaypointAction.Jump
                then
                    pcall(function()
                        humanoid.Jump = true
                    end)
                end

                humanoid:MoveTo(
                    waypoint.Position
                )

                local waypointDeadline =
                    tick() + 3.0

                while aliveMove()
                    and tick()
                        < waypointDeadline
                do
                    root = getRoot()

                    if not root then
                        return false
                    end

                    if (
                        root.Position
                        - SAFEZONE_POS
                    ).Magnitude <= 7
                    then
                        return true
                    end

                    if (
                        root.Position
                        - waypoint.Position
                    ).Magnitude <= 6
                    then
                        break
                    end

                    task.wait(0.04)
                end
            end
        end

        root = getRoot()

        if root
            and (
                root.Position
                - SAFEZONE_POS
            ).Magnitude <= 7
        then
            return true
        end

        -- Fallback to the proven movement helper.
        return WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            aliveMove
        )
    end

    local function handleNightReset(
        gen
    )
        local service =
            DHub.ResetBarrierService

        if not service then
            return false
        end

        local resetActive =
            service:IsSealed()
            or service.kaitunNightPending
                == true

        if not resetActive then
            return false
        end

        local epoch =
            tonumber(
                service.resetEpoch
            ) or 0

        RuntimeSF.phase =
            "RESET_SAFEZONE"

        setFusePriority(true)

        setStatus(
            "Night/reset -> Safezone"
        )

        moveFuseSafezone(
            gen
        )

        clearRequirementScan()
        clearPendingCarry()

        while alive(gen)
            and service:IsSealed()
        do
            task.wait(0.06)
        end

        if not alive(gen) then
            return true
        end

        -- ResetBarrierService itself refreshes GlobalEggScanner on open.
        -- Fuse never creates/resyncs its own scanner.
        task.wait(0.45)

        RuntimeSF.resetEpochHandled =
            epoch

        if Cfg.autoFarm ~= true then
            service.kaitunNightPending =
                false
        end

        setFusePriority(false)

        setStatus(
            "Reset complete -> scanning fresh cycle"
        )

        return true
    end

    local function scanInventoryOnce(
        requirements
    )
        RuntimeSF.phase =
            "SCAN_INVENTORY"

        setStatus(
            "Scanning inventory..."
        )

        -- ONE owner-inventory snapshot for this decision.
        local inventory =
            readOwnedEggsRaw()

        local used = {}

        for slotIndex, category
            in ipairs(requirements)
        do
            if not slotIsFull(
                slotIndex
            )
            then
                local matchedUid = nil

                for uid, eggData
                    in pairs(inventory)
                do
                    uid = tostring(uid)

                    if not used[uid]
                        and type(eggData)
                            == "table"
                        and not eggData.Placement
                        and sameRequirementCategory(
                            eggData.AssetCategory,
                            category
                        )
                    then
                        matchedUid = uid
                        break
                    end
                end

                if matchedUid then
                    used[matchedUid] = true

                    return {
                        slotIndex =
                            slotIndex,
                        category =
                            category,
                        uid =
                            matchedUid,
                    }
                end
            end
        end

        return nil
    end

    local function ownedUidStillUnplaced(
        uid,
        category
    )
        uid = tostring(uid or "")

        if uid == "" then
            return false
        end

        local inventory =
            readOwnedEggsRaw()

        for rawUid, eggData
            in pairs(inventory)
        do
            if tostring(rawUid) == uid
                and type(eggData) == "table"
                and not eggData.Placement
                and sameRequirementCategory(
                    eggData.AssetCategory,
                    category
                )
            then
                return true
            end
        end

        return false
    end

    local function addOwnedEgg(
        owned,
        gen
    )
        if not owned
            or not alive(gen)
        then
            return false
        end

        setFusePriority(true)

        if not waitMainFarmHandoff(
            gen
        ) then
            return false
        end

        releaseIdleTreadmill()

        -- Re-check the exact UID immediately before opening Add.
        -- If inventory changed between scan and click, NEVER press Add.
        if not ownedUidStillUnplaced(
            owned.uid,
            owned.category
        )
        then
            clearRequirementScan()

            setStatus(
                tostring(
                    owned.category
                )
                .. " inventory changed -> rescan"
            )

            task.wait(0.08)
            return false
        end

        RuntimeSF.phase =
            "ADD_SLOT"

        setStatus(
            "Adding "
            .. tostring(
                owned.category
            )
            .. " -> slot "
            .. tostring(
                owned.slotIndex
            )
        )

        local added =
            addEggToSlot(
                owned.slotIndex,
                owned.category,
                owned.uid
            )

        if added then
            RuntimeSF.selectedUids[
                tostring(owned.uid)
            ] = true

            -- Restart EXACT flow from Requirement scan.
            clearRequirementScan()

            task.wait(0.10)
            return true
        end

        setStatus(
            tostring(
                owned.category
            )
            .. " -> Add retry"
        )

        task.wait(0.20)
        return false
    end

    local function findRequiredLiveEgg(
        requirements
    )
        local root = getRoot()

        local origin =
            root
            and root.Position
            or Vector3.zero

        local best = nil
        local bestDistance =
            math.huge

        local missingNames = {}

        for slotIndex, category
            in ipairs(requirements)
        do
            if not slotIsFull(
                slotIndex
            )
            then
                missingNames[
                    #missingNames + 1
                ] = tostring(category)

                local candidate =
                    getBestRequiredEgg(
                        category,
                        origin
                    )

                if candidate
                    and typeof(
                        candidate.pos
                    ) == "Vector3"
                then
                    local distance =
                        (
                            candidate.pos
                            - origin
                        ).Magnitude

                    if distance
                        < bestDistance
                    then
                        bestDistance =
                            distance

                        best = {
                            slotIndex =
                                slotIndex,
                            category =
                                category,
                            egg =
                                candidate,
                        }
                    end
                end
            end
        end

        return best,
            missingNames
    end

    local function finishFuseCarry(
        gen
    )
        if not RuntimeSF
            .pendingCarryCategory
        then
            return false
        end

        local category =
            RuntimeSF
                .pendingCarryCategory

        local before =
            RuntimeSF
                .pendingCarryBefore

        local function fuseAlive()
            return alive(gen)
                and not bossBusy()
        end

        RuntimeSF.phase =
            "DEPOSIT"

        setStatus(
            tostring(category)
            .. " -> returning Safezone"
        )

        local lock = {
            target = {
                uid =
                    RuntimeSF
                        .pendingCarryUid,
            },
        }

        local deposited =
            mainFarmCarryEscapeLocked(
                lock,
                true,
                fuseAlive
            )

        if not deposited then
            return false
        end

        RuntimeSF.phase =
            "WAIT_BACKPACK"

        setStatus(
            tostring(category)
            .. " -> waiting inventory"
        )

        local got =
            waitOwnedCategoryIncrease(
                category,
                before,
                5.0,
                gen
            )

        if not got then
            return false
        end

        clearPendingCarry()
        clearRequirementScan()

        setStatus(
            tostring(category)
            .. " secured -> restart cycle"
        )

        return true
    end

    local function farmRequiredEgg(
        targetInfo,
        gen
    )
        if not targetInfo
            or not targetInfo.egg
        then
            return false
        end

        setFusePriority(true)

        if not waitMainFarmHandoff(
            gen
        ) then
            return false
        end

        -- FAST METHOD: use the SAME proven Instant-Steal transport as the
        -- normal Auto Farm Fast worker. It owns the entire target->redeem flow:
        -- Safezone -> egg -> carry -> instant drop -> physical re-carry -> Safezone.
        if Cfg.farmMethod == "Fast"
            and Runtime.FastFarmCarrySpecificTarget
        then
            local fastTarget =
                DHub.GlobalEggScanner:RefreshTarget(
                    targetInfo.egg
                )

            if not fastTarget then
                setFusePriority(false)
                return false
            end

            local category =
                tostring(targetInfo.category)

            local before =
                countOwnedRequiredEggs(
                    category
                )

            RuntimeSF.phase = "FAST_STEAL"

            local fastOK =
                Runtime.FastFarmCarrySpecificTarget(
                    fastTarget,
                    function()
                        return alive(gen)
                            and not bossBusy()
                    end,
                    function(message)
                        setStatus(message)
                    end
                ) == true

            if not fastOK then
                setFusePriority(false)
                return false
            end

            RuntimeSF.phase = "WAIT_BACKPACK"
            setStatus(
                category
                .. " -> confirming inventory"
            )

            local got =
                waitOwnedCategoryIncrease(
                    category,
                    before,
                    5.0,
                    gen
                )

            if not got then
                return false
            end

            clearPendingCarry()
            clearRequirementScan()

            setStatus(
                category
                .. " secured -> restart cycle"
            )

            return true
        end

        -- NORMAL METHOD keeps the existing proven walk/carry flow unchanged.
        -- required egg spawn -> release treadmill -> SAFEZONE FIRST.
        if not moveFuseSafezone(
            gen
        ) then
            return false
        end

        local target =
            DHub.GlobalEggScanner
                :RefreshTarget(
                    targetInfo.egg
                )

        if not target then
            setFusePriority(false)
            return false
        end

        local category =
            tostring(
                targetInfo.category
            )

        local before =
            countOwnedRequiredEggs(
                category
            )

        local lock = {
            target = target,
            lastKnownPos =
                target.pos,
            lostSince = nil,
        }

        RuntimeSF.phase =
            "FOLLOW_EGG"

        setStatus(
            "Following required "
            .. category
        )

        forceUnequipTools()

        local function fuseAlive()
            return alive(gen)
                and not bossBusy()
                and not isCarryingEgg()
        end

        local reached =
            WalkToLockedEggRealtime(
                lock,
                4,
                true,
                fuseAlive
            )

        if not alive(gen)
            or bossBusy()
        then
            return false
        end

        local pickupConfirmed =
            isCarryingEgg()

        if not pickupConfirmed then
            if not reached then
                return false
            end

            if not refreshLockedMainFarmTarget(
                lock
            ) then
                return false
            end

            RuntimeSF.phase =
                "PICKUP"

            setStatus(
                "Picking up required "
                .. category
            )

            pickupConfirmed =
                attemptPickup(
                    lock.target,
                    function()
                        return alive(gen)
                            and not bossBusy()
                    end,
                    true
                ) == true
        end

        if not pickupConfirmed
            and not isCarryingEgg()
        then
            return false
        end

        RuntimeSF.pendingCarryCategory =
            category

        RuntimeSF.pendingCarryBefore =
            before

        RuntimeSF.pendingCarryUid =
            tostring(
                lock.target
                and lock.target.uid
                or target.uid
                or ""
            )

        return finishFuseCarry(
            gen
        )
    end

    local function sacrificeOnce()
        local _, main =
            getMainAndInventory()

        local rawButton =
            main
            and main:FindFirstChild(
                "Sacrifice",
                true
            )

        local button =
            _resolveGuiButton(
                rawButton,
                main
            )

        if not button
            or not button:IsA(
                "GuiButton"
            )
            or button.Visible == false
        then
            return false
        end

        RuntimeSF.lastSubmitAt =
            tick()

        return _fireActivated(
            button
        )
    end

    local function tryFinishReward()
        local state =
            askState()

        if not state
            or state.PendingReward
                ~= true
        then
            return state
        end

        setStatus(
            "Claiming reward..."
        )

        local gui =
            getGui()

        local clicked = false

        if gui then
            local keywords = {
                "finish",
                "continue",
                "claim",
                "collect",
                "next",
                "reveal",
            }

            for _, object
                in ipairs(
                    gui:GetDescendants()
                )
            do
                if object:IsA(
                    "GuiButton"
                )
                    and object.Visible
                        ~= false
                then
                    local probe =
                        normalized(
                            object.Name
                        )

                    if object:IsA(
                        "TextButton"
                    ) then
                        probe =
                            probe
                            .. " "
                            .. normalized(
                                object.Text
                            )
                    end

                    for _, key
                        in ipairs(
                            keywords
                        )
                    do
                        if probe:find(
                            key,
                            1,
                            true
                        )
                        then
                            clicked =
                                _fireActivated(
                                    object
                                )
                                or clicked

                            break
                        end
                    end
                end
            end
        end

        if not clicked
            and RMT
                .ScrambleTradeAskFinishReveal
            and tick()
                - (
                    RuntimeSF
                        .lastFinishRevealAt
                    or 0
                ) >= 0.75
        then
            RuntimeSF.lastFinishRevealAt =
                tick()

            pcall(function()
                RMT
                    .ScrambleTradeAskFinishReveal
                    :InvokeServer()
            end)
        end

        task.wait(0.30)

        return askState()
    end

    local function labSlotsReset()
        for index = 1, 3 do
            if slotIsFull(index) then
                return false
            end
        end

        return true
    end

    local function installFreshRequirements(
        state,
        requirements
    )
        RuntimeSF.state = state

        RuntimeSF.requirements =
            copyRequirements(
                requirements
            )

        RuntimeSF.requirementSignature =
            requirementsSignature(
                RuntimeSF.requirements
            )

        RuntimeSF.selectedUids = {}
        RuntimeSF.rewardWaiting = false
        RuntimeSF.rewardBaselineUids = nil

        clearPendingCarry()

        RuntimeSF.phase =
            "SCAN_INVENTORY"

        updateSlotLabels(
            RuntimeSF.requirements
        )

        setStatus(
            "New requirements ready -> "
            .. table.concat(
                RuntimeSF.requirements,
                " / "
            )
        )
    end

    local function waitRewardEggAndRestart(
        gen
    )
        RuntimeSF.phase =
            "WAIT_REWARD"

        setFusePriority(true)
        releaseIdleTreadmill()

        if not RuntimeSF
            .rewardBaselineUids
        then
            RuntimeSF.rewardBaselineUids =
                snapshotOwnedUids()
        end

        -- Never display a new recipe against stale Full slots.
        updateSlotLabels({})

        setStatus(
            "Reward claimed -> waiting reward egg"
        )

        local rewardEggArrived = false
        local rewardUid = nil

        local stableSignature = ""
        local stableCount = 0

        while alive(gen)
            and not bossBusy()
        do
            local state =
                askState()

            if state
                and state.PendingReward
                    == true
            then
                tryFinishReward()
                state = askState()
            end

            if not rewardEggArrived then
                rewardEggArrived,
                    rewardUid =
                    hasNewOwnedUid(
                        RuntimeSF
                            .rewardBaselineUids
                    )
            end

            local requirements =
                state
                and state.PendingReward
                    ~= true
                and copyRequirements(
                    state.Requirements
                )
                or {}

            local guiReset =
                labSlotsReset()

            if rewardEggArrived
                and state
                and state.PendingReward
                    ~= true
                and guiReset
                and #requirements > 0
            then
                local signature =
                    requirementsSignature(
                        requirements
                    )

                if signature
                    == stableSignature
                then
                    stableCount =
                        stableCount + 1
                else
                    stableSignature =
                        signature

                    stableCount = 1
                end

                -- Two equal state reads + reset GUI prevents the exact bug
                -- where a new recipe name was painted onto old Full slots.
                if stableCount >= 2 then
                    task.wait(0.20)

                    installFreshRequirements(
                        state,
                        requirements
                    )

                    return true
                end

                setStatus(
                    "Reward egg received -> syncing new Lab"
                )

            elseif rewardEggArrived then
                stableSignature = ""
                stableCount = 0

                setStatus(
                    "Reward egg received -> waiting Lab reset"
                )

            else
                stableSignature = ""
                stableCount = 0

                setStatus(
                    "Reward claimed -> waiting reward egg"
                )
            end

            task.wait(0.12)
        end

        return false
    end

    local function submitIfFull(
        requirements,
        gen
    )
        if #requirements < 3 then
            return false
        end

        for index = 1, 3 do
            if not slotIsFull(index) then
                return false
            end
        end

        setFusePriority(true)
        releaseIdleTreadmill()

        RuntimeSF.phase =
            "SUBMIT"

        setStatus(
            "All required eggs added -> Sacrifice"
        )

        RuntimeSF.rewardBaselineUids =
            snapshotOwnedUids()

        for attempt = 1, 3 do
            if not alive(gen)
                or bossBusy()
            then
                return false
            end

            if sacrificeOnce() then
                local deadline =
                    tick() + 2.0

                while alive(gen)
                    and tick() < deadline
                do
                    local state =
                        askState()

                    if state
                        and (
                            state.PendingReward
                                == true
                            or requirementsSignature(
                                state.Requirements
                                or {}
                            ) ~= RuntimeSF
                                .requirementSignature
                        )
                    then
                        RuntimeSF.rewardWaiting =
                            true

                        return waitRewardEggAndRestart(
                            gen
                        )
                    end

                    task.wait(0.10)
                end
            end

            task.wait(0.20)
        end

        return false
    end

    local function runCycle(gen)
        -- 0) A Fuse-owned pickup must ALWAYS finish its deposit state.
        --
        -- At Safezone the carry visual/state can disappear BEFORE
        -- Save.EggInventory replicates. The old code required
        -- isCarryingEgg()==true here, so it skipped finishFuseCarry exactly
        -- when the egg was being deposited and left Fuse stuck at Safezone.
        if RuntimeSF.pendingCarryCategory then
            setFusePriority(true)

            finishFuseCarry(
                gen
            )

            return
        end

        -- 1) Reward must settle before any new requirement scan.
        if RuntimeSF.rewardWaiting then
            waitRewardEggAndRestart(
                gen
            )
            return
        end

        -- 2) Night/reset:
        -- release treadmill -> Safezone -> wait reset open -> fresh scan.
        if DHub.ResetBarrierService
            and (
                DHub.ResetBarrierService
                    :IsSealed()
                or DHub.ResetBarrierService
                    .kaitunNightPending
                    == true
            )
        then
            handleNightReset(
                gen
            )
            return
        end

        -- Boss still has priority over a new Fuse action.
        if bossBusy() then
            setFusePriority(false)
            setStatus(
                "Paused for Auto Boss"
            )
            task.wait(0.12)
            return
        end

        -- Requirement/Inventory/Add are LOCAL actions and must be allowed to
        -- complete even while Normal Auto Farm has a world target.
        -- Normal Farm priority is checked later, only before Fuse moves out to
        -- steal a live required egg.

        -- 3) SCAN REQUIREMENTS ONCE.
        if not RuntimeSF.requirements then
            local requirements,
                reason =
                scanRequirementsOnce()

            if reason
                == "pending_reward"
            then
                RuntimeSF.rewardWaiting =
                    true

                if not RuntimeSF
                    .rewardBaselineUids
                then
                    -- Startup/reconnect fallback only. Normal Sacrifice sets
                    -- this BEFORE the reward is granted.
                    RuntimeSF
                        .rewardBaselineUids =
                        snapshotOwnedUids()
                end

                waitRewardEggAndRestart(
                    gen
                )

                return
            end

            if not requirements then
                setFusePriority(false)

                setStatus(
                    "Waiting Lab requirements"
                )

                task.wait(0.25)
                return
            end
        end

        local requirements =
            RuntimeSF.requirements

        -- 4) SCAN INVENTORY ONCE.
        local owned =
            scanInventoryOnce(
                requirements
            )

        if owned then
            addOwnedEgg(
                owned,
                gen
            )
            return
        end

        -- 5) If all three slots are already Full, submit.
        if submitIfFull(
            requirements,
            gen
        )
        then
            return
        end

        -- Normal Auto Farm has first priority for WORLD MOVEMENT.
        -- By this point Fuse already had a chance to refresh requirements and
        -- Add any required egg that is safely in the backpack.
        if DHub.EventBossPriority
            and DHub.EventBossPriority
                :IsMainFarmBusy()
        then
            setFusePriority(false)

            setStatus(
                "Waiting Auto Farm Egg"
            )

            task.wait(0.12)
            return
        end

        -- 6) Use the SAME global scanner as Auto Farm Egg.
        local liveTarget,
            missingNames =
            findRequiredLiveEgg(
                requirements
            )

        if not liveTarget then
            -- No work: release Fuse priority and let the existing treadmill
            -- system own idle waiting.
            setFusePriority(false)

            RuntimeSF.phase =
                "WAIT_SPAWN"

            setStatus(
                "Waiting required egg spawn -> "
                .. table.concat(
                    missingNames,
                    " / "
                )
            )

            task.wait(0.20)
            return
        end

        -- 7) Spawn detected:
        -- release treadmill -> Safezone FIRST -> normal Farm Egg engine.
        setFusePriority(true)

        local success =
            farmRequiredEgg(
                liveTarget,
                gen
            )

        if success then
            -- REQUIRED: restart exact flow from Requirement scan.
            clearRequirementScan()

            setStatus(
                tostring(
                    liveTarget.category
                )
                .. " secured -> restart requirement scan"
            )
        else
            -- Keep requirements locked while the same global scanner waits for
            -- a real target again. No extra scanner/state is created.
            RuntimeSF.phase =
                "WAIT_SPAWN"

            setFusePriority(false)

            setStatus(
                "Waiting required egg spawn -> "
                .. table.concat(
                    missingNames,
                    " / "
                )
            )
        end
    end

    local function resetFreshRuntime()
        RuntimeSF.phase = "IDLE"
        RuntimeSF.lastStatus = ""

        clearRequirementScan()
        clearPendingCarry()

        RuntimeSF.rewardWaiting = false
        RuntimeSF.rewardBaselineUids = nil
        RuntimeSF.resetEpochHandled = -1
    end

    local function start()
        if RuntimeSF.running then
            return
        end

        RuntimeSF.running = true
        RuntimeSF.generation =
            RuntimeSF.generation + 1

        resetFreshRuntime()

        -- Never keep the previous cycle's Owned/Added text when the toggle is
        -- re-enabled. The first server/inventory scan repaints it from scratch.
        updateSlotLabels({})

        local gen =
            RuntimeSF.generation

        task.spawn(function()
            while alive(gen) do
                local ok, err =
                    pcall(
                        runCycle,
                        gen
                    )

                if not ok then
                    setStatus(
                        "Retry: "
                        .. tostring(err)
                    )

                    task.wait(0.30)
                else
                    task.wait(0.10)
                end
            end

            setFusePriority(false)
            RuntimeSF.running = false
            setStatus("Idle")
        end)
    end

    local function stop()
        RuntimeSF.generation =
            RuntimeSF.generation + 1

        RuntimeSF.running = false

        resetFreshRuntime()
        setFusePriority(false)

        pcall(function()
            if DHub.MovementService then
                DHub.MovementService:Cancel(
                    "Fuse"
                )
            end
        end)

        setStatus("Idle")
    end

    return {
        Runtime = RuntimeSF,
        Start = start,
        Stop = stop,
        RefreshState = askState,
        UpdateSlots = updateSlotLabels,

        -- Proven low-level primitives reused by the fresh coordinator.
        -- The old worker/state-machine is NOT started by the fresh engine.
        GetOwnedEgg = getOwnedEgg,
        CountOwnedRequiredEggs = countOwnedRequiredEggs,
        AddEggToSlot = addEggToSlot,
        SlotIsFull = slotIsFull,
    }

end)()


-- ============================================================
-- GLOBAL IDLE TREADMILL
-- Normal Egg > Boss > Scramble Fuse > Treadmill
-- ============================================================
DHub.GlobalIdleTreadmill =
    DHub.GlobalIdleTreadmill
    or {
        started = false,
        stableIdleSince = nil,
        resumeNotBefore = 0,
    }

function DHub.GlobalIdleTreadmill:IsResetBlocked()
    if not DHub.ResetBarrierService then
        return false
    end

    local sealed = false
    pcall(function()
        sealed =
            DHub.ResetBarrierService:IsSealed()
                == true
    end)

    local recentReset =
        (
            DHub.ResetBarrierService.lastResetAt
            or 0
        ) > 0
        and tick()
            - (
                DHub.ResetBarrierService.lastResetAt
                or 0
            ) < 2.5

    return sealed
        or DHub.ResetBarrierService.kaitunNightPending == true
        or recentReset
end

function DHub.GlobalIdleTreadmill:ShouldDrive()
    if self:IsResetBlocked() then
        return false
    end

    return Cfg.autoTreadmill == true
        and Cfg.autoFarm ~= true
        and (
            EventCfg.autoBoss == true
            or EventCfg.autoFuseScrambler == true
        )
end

function DHub.GlobalIdleTreadmill:Start()
    if self.started then
        return
    end

    self.started = true

    task.spawn(function()
        while DHub.LongAFKRuntime.alive do
            if self:IsResetBlocked() then
                self.stableIdleSince = nil
                self.resumeNotBefore =
                    math.max(
                        self.resumeNotBefore or 0,
                        tick() + 0.75
                    )

                if DHub.MovementService.currentOwner
                    == "IdleTreadmill"
                then
                    DHub.MovementService:Cancel(
                        "IdleTreadmill"
                    )
                end

                if isPlayerOnTreadmill()
                    or (
                        DHub.TreadmillMount
                        and DHub.TreadmillMount.active
                    )
                then
                    -- treadmill release deferred until an actual Safezone route
                end

                task.wait(0.15)
                continue
            end

            if not self:ShouldDrive() then
                self.stableIdleSince = nil

                if DHub.MovementService.currentOwner
                    == "IdleTreadmill"
                then
                    DHub.MovementService:Cancel(
                        "IdleTreadmill"
                    )
                end

                if Cfg.autoFarm ~= true
                    and Cfg.autoTreadmill ~= true
                    and (
                        isPlayerOnTreadmill()
                        or (
                            DHub.TreadmillMount
                            and DHub.TreadmillMount.active
                        )
                    )
                then
                    -- treadmill release deferred until an actual Safezone route
                end

                task.wait(0.15)
                continue
            end

            if not DHub.IsIdleTreadmillAllowed() then
                self.stableIdleSince = nil
                self.resumeNotBefore =
                    math.max(
                        self.resumeNotBefore or 0,
                        tick() + 0.65
                    )

                if DHub.MovementService.currentOwner
                    == "IdleTreadmill"
                then
                    DHub.MovementService:Cancel(
                        "IdleTreadmill"
                    )
                end

                if isPlayerOnTreadmill()
                    or (
                        DHub.TreadmillMount
                        and DHub.TreadmillMount.active
                    )
                then
                    -- treadmill release deferred until an actual Safezone route
                end

                task.wait(0.08)
                continue
            end

            if not self.stableIdleSince then
                self.stableIdleSince = tick()
            end

            if tick() < (self.resumeNotBefore or 0)
                or tick() - self.stableIdleSince < 0.45
            then
                task.wait(0.08)
                continue
            end

            local penInfo = findMyPlot()
            local treadmill =
                penInfo
                and penInfo.plot
                and penInfo.plot:FindFirstChild(
                    "TreadmillBottom"
                )

            if not treadmill then
                task.wait(0.20)
                continue
            end

            local mounted =
                DHub.TreadmillMount
                and DHub.TreadmillMount.active == true

            if not mounted then
                if isPlayerOnTreadmill() ~= true then
                    DHub.MovementService:Move(
                        treadmill.Position
                            + Vector3.new(0, 2, 0),
                        {
                            owner = "IdleTreadmill",
                            priority =
                                DHub.MovementService
                                    .Priorities
                                    .IdleTreadmill,
                            method = "Normal",
                            stopDistance = 3.25,
                            keepUnequipped = false,
                            requireBypass = false,
                            timeout = 25,
                            shouldContinue =
                                function()
                                    return self:ShouldDrive()
                                        and DHub.IsIdleTreadmillAllowed()
                                        and not self:IsResetBlocked()
                                end,
                        }
                    )
                end

                if self:ShouldDrive()
                    and DHub.IsIdleTreadmillAllowed()
                    and not self:IsResetBlocked()
                then
                    local ok =
                        DHub.TreadmillMount
                        and DHub.TreadmillMount:TryMount()

                    if not ok then
                        task.wait(0.10)
                        continue
                    end
                end
            end

            while self:ShouldDrive()
                and DHub.IsIdleTreadmillAllowed()
                and not self:IsResetBlocked()
                and DHub.TreadmillMount
                and DHub.TreadmillMount.active == true
            do
                task.wait(0.08)
            end

            if (
                    self:IsResetBlocked()
                    or (
                        self:ShouldDrive()
                        and not DHub.IsIdleTreadmillAllowed()
                    )
                )
                and (
                    isPlayerOnTreadmill()
                    or (
                        DHub.TreadmillMount
                        and DHub.TreadmillMount.active
                    )
                )
            then
                -- treadmill release deferred until an actual Safezone route
                self.stableIdleSince = nil
                self.resumeNotBefore = tick() + 0.65
            end

            task.wait(0.08)
        end
    end)
end

DHub.GlobalIdleTreadmill:Start()


mainFarmCarryEscapeLocked = function(
    lock,
    pickupConfirmed,
    shouldContinueOverride
)
    local function active()
        if type(shouldContinueOverride)
            == "function"
        then
            local ok, result =
                pcall(
                    shouldContinueOverride
                )

            return ok
                and result == true
        end

        return Cfg.autoFarm == true
    end

    if not active() then
        return false, "stopped"
    end

    local carryDetected = isCarryingEgg()

    -- This is the key behavior from the proven Normal Farm engine:
    -- a successful CarryService pickup is enough to start escape immediately.
    -- We DO NOT wait for isCarryingEgg() replication first.
    local carryConfirmed =
        pickupConfirmed == true
        or carryDetected

    if not carryConfirmed then
        return false, "lost"
    end

    UpdateStatus(
        Cfg.antiBoss
            and "CARRY CONFIRMED -> ANTI BOSS -> SAFEZONE"
            or "CARRY CONFIRMED -> SAFEZONE"
    )

    local okEscape = false

    pcall(function()
        -- Use the exact normal Farm Egg escape.
        -- This runs the normal Anti Boss flow when Anti Boss is enabled,
        -- then walks back to Safezone.
        okEscape =
            instantCarryEscape()
            == true
    end)

    local settleUntil =
        tick() + 0.45

    while active()
        and tick() < settleUntil
    do
        local root = getRoot()

        if root
            and (
                root.Position
                - SAFEZONE_POS
            ).Magnitude <= 14
        then
            forceUnequipTools()
        end

        task.wait(0.05)
    end

    local root = getRoot()

    local inSafezone =
        root
        and (
            root.Position
            - SAFEZONE_POS
        ).Magnitude <= 14
        or false

    if inSafezone then
        forceUnequipTools()
        task.wait(0.05)
        forceUnequipTools()

        return true, "deposited"
    end

    if active()
        and (
            isCarryingEgg()
            or pickupConfirmed == true
        )
    then
        UpdateStatus(
            "Carry escape retry -> Safezone"
        )

        WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            function()
                return active()
            end,
            {
                avoidPlayerTraps = true,
            }
        )

        forceUnequipTools()
        task.wait(0.05)
        forceUnequipTools()

        root = getRoot()

        inSafezone =
            root
            and (
                root.Position
                - SAFEZONE_POS
            ).Magnitude <= 14
            or false

        if inSafezone then
            return true, "deposited"
        end
    end

    if not isCarryingEgg()
        and lock
        and refreshLockedMainFarmTarget(
            lock
        )
    then
        return false, "lost"
    end

    return okEscape
        and inSafezone,
        inSafezone
            and "deposited"
            or "lost"
end

doFarmLoop = function()
    if Runtime.farming then return end
    Runtime.farming = true

    PlotRuntime.placeGeneration = PlotRuntime.placeGeneration + 1
    PlotRuntime.placeOwner = nil

    MainFarmLock.target = nil
    MainFarmLock.lostSince = nil
    MainFarmLock.initialSafezoneDone = false
    MainFarmLock.routeStagedUid = nil

    DHub.FarmCoordinator:ClearTarget()
    DHub.FarmCoordinator:SetState("Idle")

    UpdateStatus("Waiting for Character...")
    ensureCharacter(15)
    UpdateStatus("Preparing target-lock engine...")
    DHub.buildAssetRarityCache()
    task.wait(0.25)

    if Cfg.autoFarm then
        UpdateStatus("Start -> Safezone once")
        WalkToTarget(SAFEZONE_POS, 5)

        MainFarmLock.initialSafezoneDone = true
    end

    while Cfg.autoFarm do
        if DHub.EventWavePriority
            and DHub.EventWavePriority:ShouldPauseMainFarm()
        then
            if isPlayerOnTreadmill() then
                UpdateStatus(
                    "NORMAL: Event automation -> releasing treadmill"
                )
                -- treadmill release deferred until an actual Safezone route
                task.wait(0.08)
            end

            UpdateStatus(
                "NORMAL: paused for event automation"
            )

            S.RunService.Heartbeat:Wait()
            continue
        end


        local curChar = LP.Character
        local curRoot = getRoot()
        local curHum  = getHumanoid()

        if not curChar
            or not curRoot
            or not curHum
            or not curRoot.Parent
            or curHum.Health <= 0
        then
            UpdateStatus("Respawning...")
            ensureCharacter(10)
            task.wait(0.35)
            continue
        end

        if not MainFarmLock.target
            and isCarryingEgg()
        then
            DHub.FarmCoordinator:SetState("Carry")
            UpdateStatus(
                "Carry detected -> Safezone before any new action"
            )

            pcall(instantCarryEscape)

            DHub.FarmCoordinator:ClearTarget()
            task.wait(0.08)
            continue
        end

        if not MainFarmLock.target then
            UpdateStatus("Scanning...")

            local target =
                DHub.TargetSelector:GetBestFarmTarget()

            if not Cfg.autoFarm then
                break
            end

            while Cfg.autoFarm
                and not target
            do
                if DHub.EventWavePriority
                    and DHub.EventWavePriority:ShouldPauseMainFarm()
                then
                    if isPlayerOnTreadmill() then
                        -- treadmill release deferred until an actual Safezone route
                    end
                    break
                end

                target =
                    DHub.TargetSelector:GetBestFarmTarget()

                if target then
                    break
                end

                local plotted, plotReason =
                    PlotRuntime.RunFarmPlotPriority(
                        "NORMAL"
                    )

                if not Cfg.autoFarm then
                    break
                end

                if plotted then
                    target =
                        DHub.TargetSelector:GetBestFarmTarget()

                    if target then
                        break
                    end

                    continue
                end

                if plotReason == "farm_target" then
                    target =
                        DHub.TargetSelector:GetBestFarmTarget()

                    if target then
                        break
                    end
                elseif plotReason == "busy" then
                    task.wait(0.05)
                    continue
                end

                if Cfg.autoTreadmill then
                    local penInfo =
                        findMyPlot()

                    local treadmill =
                        penInfo
                        and penInfo.plot
                        and penInfo.plot:FindFirstChild(
                            "TreadmillBottom"
                        )

                    if treadmill then
                        local physicallyNear =
                            isPlayerOnTreadmill() == true

                        local actuallyMounted =
                            DHub.TreadmillMount
                            and DHub.TreadmillMount.active == true

                        if not actuallyMounted then
                            if not physicallyNear then
                                UpdateStatus(
                                    "NORMAL: idle -> treadmill"
                                )

                                local treadmillScannerRevision =
                                    DHub.GlobalEggScanner.revision

                                local treadmillSelectorRevision =
                                    DHub.TargetSelector.revision

                                local treadmillAuxRevision =
                                    PlotRuntime.farmAuxRevision

                                local reachedTreadmill =
                                    WalkToTarget(
                                        treadmill.Position
                                            + Vector3.new(0, 2, 0),
                                        4,
                                        false,
                                        function()
                                            return Cfg.autoFarm
                                                and Cfg.autoTreadmill
                                                and not PlotRuntime.placing
                                                and not isCarryingEgg()
                                                and not (
                                                    DHub.EventWavePriority
                                                    and DHub.EventWavePriority:ShouldPauseMainFarm()
                                                )
                                                and not DHub.TargetSelector:HasFarmCandidate()
                                                and not PlotRuntime.HasFarmPlaceableEgg(true)
                                        end
                                    )

                                if not Cfg.autoFarm then
                                    break
                                end

                                target =
                                    DHub.TargetSelector:GetBestFarmTarget()

                                if target then
                                    break
                                end

                                if not reachedTreadmill then
                                    continue
                                end

                                if PlotRuntime.HasFarmPlaceableEgg(true) then
                                    continue
                                end
                            end

                            local mounted, mountReason =
                                DHub.TreadmillMount:TryMount()

                            if not mounted then
                                UpdateStatus(
                                    "NORMAL: treadmill mount retry -> "
                                    .. tostring(mountReason)
                                )

                                task.wait(0.08)
                                continue
                            end
                        end

                        UpdateStatus(
                            "NORMAL: treadmill ACTIVE -> waiting Farm / Plot"
                        )
                    else
                        UpdateStatus(
                            "NORMAL: waiting Farm / Plot"
                        )
                    end
                else
                    local idleRoot =
                        getRoot()

                    local idleInSafezone =
                        idleRoot
                        and (
                            idleRoot.Position
                            - SAFEZONE_POS
                        ).Magnitude <= 7
                        or false

                    if not idleInSafezone then
                        UpdateStatus(
                            "NORMAL: idle -> Safezone"
                        )

                        WalkToTarget(
                            SAFEZONE_POS,
                            5,
                            false,
                            function()
                                return Cfg.autoFarm
                                    and not Cfg.autoTreadmill
                                    and not isCarryingEgg()
                                    and not (
                                        DHub.EventWavePriority
                                        and DHub.EventWavePriority:
                                            ShouldPauseMainFarm()
                                    )
                                    and not DHub.TargetSelector:
                                        HasFarmCandidate()
                            end
                        )
                    else
                        UpdateStatus(
                            "NORMAL: waiting Farm / Plot | Safezone"
                        )
                    end
                end

                local scannerRevision =
                    DHub.GlobalEggScanner.revision

                local selectorRevision =
                    DHub.TargetSelector.revision

                local auxRevision =
                    PlotRuntime.farmAuxRevision

                local probeDeadline =
                    tick() + 0.35

                while Cfg.autoFarm
                    and not target
                    and not (
                        DHub.EventWavePriority
                        and DHub.EventWavePriority:ShouldPauseMainFarm()
                    )
                    and DHub.GlobalEggScanner.revision
                        == scannerRevision
                    and DHub.TargetSelector.revision
                        == selectorRevision
                    and PlotRuntime.farmAuxRevision
                        == auxRevision
                    and tick() < probeDeadline
                do
                    S.RunService.Heartbeat:Wait()
                end

                target =
                    DHub.TargetSelector:GetBestFarmTarget()
            end

            if not Cfg.autoFarm then
                break
            end

            if DHub.EventWavePriority
                and DHub.EventWavePriority:ShouldPauseMainFarm()
                and not target
            then
                continue
            end

            if not target then
                continue
            end

            MainFarmLock.target = {
                uid          = target.uid,
                model        = target.model,
                pos          = target.pos,
                zone         = target.zone,
                rarity       = target.rarity,
                rarityNum    = target.rarityNum,
                category     = target.category,
                weight       = target.weight,
                mutations    = target.mutations,
                baseMutation = target.baseMutation,
                slotKey      = target.slotKey,
                score        = target.score,
                dist         = target.dist,
                isDropped    = target.isDropped,
            }
            MainFarmLock.lastKnownPos = target.pos
            MainFarmLock.lostSince = nil
            MainFarmLock.routeStagedUid = nil

            DHub.FarmCoordinator:LockTarget(
                "Normal",
                MainFarmLock.target
            )

            UpdateStatus(string.format(
                "TARGET LOCKED: [%s] %s | %s",
                tostring(target.rarity or "?"),
                tostring(target.category or "Egg"),
                tostring(target.zone or "Unknown")
            ))
        end

        local lock = MainFarmLock
        local target = lock.target
        if not target then
            task.wait(0.03)
            continue
        end

        if isCarryingEgg() then
            local deposited, reason = mainFarmCarryEscapeLocked(lock)

            if deposited then
                UpdateStatus("Locked egg deposited -> next target")

                local completedUid =
                    MainFarmLock.target
                    and MainFarmLock.target.uid
                    or nil

                MainFarmLock.target = nil
                MainFarmLock.lostSince = nil
                DHub.FarmCoordinator:ClearTarget(
                    completedUid
                )

                task.wait(0.05)
                continue
            end

            UpdateStatus("Egg dropped -> re-locking SAME egg...")
            lock.lostSince = nil
            refreshLockedMainFarmTarget(lock)
            task.wait(0.05)
            continue
        end

        local targetAlive = refreshLockedMainFarmTarget(lock)

        if not targetAlive then
            lock.lostSince = lock.lostSince or tick()

            if tick() - lock.lostSince < 0.85 then
                UpdateStatus(
                    "Locked egg missing -> short replication grace..."
                )
                task.wait(0.06)
                continue
            end

            local vanishedUid =
                lock.target
                and lock.target.uid
                or nil

            UpdateStatus(
                "Locked egg gone -> release lock -> idle coordinator"
            )

            MainFarmLock.target = nil
            MainFarmLock.lostSince = nil

            DHub.FarmCoordinator:ClearTarget(
                vanishedUid
            )

            ScanCache.lastScan = 0
            ScanCache.eggs = {}

            DHub.FarmCoordinator:Wake()

            task.wait(0.03)
            continue
        end

        target = lock.target

        if DHub.ResetBarrierService:IsSealed() then
            UpdateStatus("Egg cached -> waiting reset wall...")
            if not DHub.ResetBarrierService:WaitOpen(function() return Cfg.autoFarm end) then break end
            if not refreshLockedMainFarmTarget(lock) then MainFarmLock.target=nil; MainFarmLock.lostSince=nil; task.wait(0.02); continue end
            target=lock.target
        end

        local targetUid=tostring(target.uid or "")

        if MainFarmLock.routeStagedUid~=targetUid then
            local routeRoot=getRoot()
            local alreadyInEggArea=
                routeRoot
                and DHub.isInsideAnyEggArea(routeRoot.Position)
                or false

            if not alreadyInEggArea then
                UpdateStatus("TARGET LOCKED -> Safezone staging")

                local staged=WalkToTarget(
                    SAFEZONE_POS,
                    5,
                    false,
                    function()
                        return Cfg.autoFarm
                            and lock.target~=nil
                            and tostring(lock.target.uid or "")==targetUid
                            and not isCarryingEgg()
                    end
                )

                if not staged then
                    task.wait(0.05)
                    continue
                end

                if not refreshLockedMainFarmTarget(lock) then
                    task.wait(0.05)
                    continue
                end

                target=lock.target
            end

            MainFarmLock.routeStagedUid=targetUid
        end

        UpdateStatus(string.format(
            "LOCKED FOLLOW -> %s [%s]",
            tostring(target.category or "Egg"),
            tostring(target.rarity or "?")
        ))

        forceUnequipTools()

        local reached =
            WalkToLockedEggRealtime(
                lock,
                4,
                true,
                function()
                    return Cfg.autoFarm
                        and not isCarryingEgg()
                end
            )

        if not Cfg.autoFarm then break end

        if not isCarryingEgg() then
            if not refreshLockedMainFarmTarget(lock) then
                UpdateStatus(
                    "Locked egg moved/missing -> refreshing SAME UID..."
                )
                task.wait(0.04)
                continue
            end

            target = lock.target

            local finalPos =
                getLockedEggLivePosition(lock)

            local finalRoot = getRoot()

            if typeof(finalPos) == "Vector3"
                and finalRoot
            then
                local prompt =
                    DHub.getEggPrompt(
                        tostring(
                            lock.target.uid
                        )
                    )

                local reach =
                    prompt
                    and tonumber(
                        prompt.MaxActivationDistance
                    )
                    or 5.0

                reach =
                    math.clamp(
                        reach - 0.75,
                        3.5,
                        5.25
                    )

                local delta =
                    finalPos
                    - finalRoot.Position

                local flatDistance =
                    Vector3.new(
                        delta.X,
                        0,
                        delta.Z
                    ).Magnitude

                if delta.Magnitude > reach
                    and flatDistance > 3.0
                then
                    UpdateStatus(
                        "Locked egg moved again -> following live position..."
                    )
                    task.wait(0.02)
                    continue
                end
            end
        end

        if isCarryingEgg() then
            local deposited = mainFarmCarryEscapeLocked(lock)
            if deposited then
                local completedUid =
                    MainFarmLock.target
                    and MainFarmLock.target.uid
                    or nil

                MainFarmLock.target = nil
                MainFarmLock.lostSince = nil
                DHub.FarmCoordinator:ClearTarget(
                    completedUid
                )
            else
                UpdateStatus("Carry lost -> recovering locked egg...")
                refreshLockedMainFarmTarget(lock)
            end
            task.wait(0.04)
            continue
        end

        if not reached then
            if refreshLockedMainFarmTarget(lock) then
                UpdateStatus("Target moved/dropped -> continuing lock...")
                task.wait(0.04)
                continue
            end
        end

        UpdateStatus("Stealing LOCKED egg...")

        local carried = attemptPickup(
            target,
            function()
                return Cfg.autoFarm
            end,
            true
        )

        if not Cfg.autoFarm then break end

        if carried or isCarryingEgg() then
            local deposited = mainFarmCarryEscapeLocked(lock, carried == true)

            if deposited then
                UpdateStatus("Locked egg secured!")

                local completedUid =
                    MainFarmLock.target
                    and MainFarmLock.target.uid
                    or nil

                MainFarmLock.target = nil
                MainFarmLock.lostSince = nil
                DHub.FarmCoordinator:ClearTarget(
                    completedUid
                )

            else
                UpdateStatus("Guard dropped egg -> SAME target retained")
                lock.lostSince = nil
                refreshLockedMainFarmTarget(lock)
            end

            task.wait(0.04)
            continue
        end

        if refreshLockedMainFarmTarget(lock) then
            UpdateStatus("Pickup retry -> SAME locked egg")
            task.wait(0.05)
            continue
        end

        lock.lostSince = lock.lostSince or tick()
        task.wait(0.05)
    end

    MainFarmLock.target = nil
    MainFarmLock.lostSince = nil
    MainFarmLock.initialSafezoneDone = false
    MainFarmLock.routeStagedUid = nil

    DHub.FarmCoordinator:ClearTarget()
    DHub.FarmCoordinator:SetState("Idle")

    Runtime.farming = false
    UpdateStatus("Idle")
end

local FastFarm = (function()
    local State = {
        active = false,
        generation = 0,
        workerRunning = false,
        busy = false,
        busyUid = nil,
        latestTarget = nil,
    }

    -- Proven Instant-Steal transport supplied by the user.
    -- NO CharacterService bypass, NO WalkSpeed override, NO BodyVelocity farm.
    local DROP_POSITION = Vector3.new(577, 70.57, -307.58)
    local TARGET_STOP_DISTANCE = 1.5
    local SAFEZONE_STOP_DISTANCE = 4.5
    local DROP_AREA_CARRY_RADIUS = 22.0
    local WALK_REISSUE_INTERVAL = 0.15
    local WALK_UNEQUIP_INTERVAL = 0.15
    local DROP_PIN_PRE_DROP_SECONDS = 0.45
    local DROP_SERVER_SETTLE_SECONDS = 0.50
    local DROP_STATE_STABLE_READS = 3
    local DROP_PROMPT_STABLE_READS = 2
    local DROP_PROMPT_RADIUS = 6.0
    local RECARRY_TIMEOUT = 5.0
    local CAMERA_FREEZE_SECONDS = 1.0

    local RedeemRemote =
        PKG_NET
        and PKG_NET:FindFirstChild(
            "RE/EggWorld/FieldEggRedeemVerdict"
        )
        or nil

    local function eggState()
        return DHub.EggStateService
            and DHub.EggStateService.module
            or nil
    end

    local function emit(statusCallback, textValue)
        textValue = tostring(textValue or "FAST")

        if type(statusCallback) == "function" then
            pcall(statusCallback, textValue)
        else
            UpdateStatus(textValue)
        end
    end

    local function allowed(shouldContinue)
        if type(shouldContinue) ~= "function" then
            return true
        end

        local ok, result = pcall(shouldContinue)
        return ok and result == true
    end

    local function getHorizontalDistance(a, b)
        return Vector2.new(
            a.X - b.X,
            a.Z - b.Z
        ).Magnitude
    end

    local function stopNaturalWalk()
        Runtime.isAutoWalking = false

        local hum = getHumanoid()
        local root = getRoot()

        if hum and root then
            pcall(function()
                hum:MoveTo(root.Position)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    local function naturalWalkToTarget(
        targetPos,
        stopDistance,
        shouldContinue,
        keepUnequipped
    )
        if typeof(targetPos) ~= "Vector3" then
            return false
        end

        stopDistance = tonumber(stopDistance)
            or TARGET_STOP_DISTANCE
        keepUnequipped = keepUnequipped == true

        Runtime.isAutoWalking = true

        local char, root, hum = ensureCharacter(5)
        if not char or not root or not hum then
            Runtime.isAutoWalking = false
            return false
        end

        if releaseTreadmillForSafezoneRoute(
            targetPos
        )
        then
            char, root, hum =
                ensureCharacter(3)
        end

        if not root or not hum then
            Runtime.isAutoWalking = false
            return false
        end

        local currentSpeed = math.max(
            tonumber(hum.WalkSpeed) or 16,
            1
        )

        local initialDist2D =
            getHorizontalDistance(
                targetPos,
                root.Position
            )

        local timeout = math.max(
            12,
            (initialDist2D / currentSpeed) * 2.5 + 8
        )

        local started = tick()
        local lastMoveIssue = 0
        local lastUnequip = 0

        while allowed(shouldContinue)
            and tick() - started < timeout
        do
            releaseTreadmillForSafezoneRoute(
                targetPos
            )

            char = LP.Character
            root = getRoot()
            hum = getHumanoid()

            if not char
                or not root
                or not hum
                or hum.Health <= 0
            then
                break
            end

            local hDist =
                getHorizontalDistance(
                    targetPos,
                    root.Position
                )

            -- Proven sudden brake / exact horizontal stop.
            if hDist <= stopDistance then
                pcall(function()
                    hum:MoveTo(root.Position)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(
                        targetPos.X,
                        root.Position.Y,
                        targetPos.Z
                    )
                end)

                if keepUnequipped then
                    forceUnequipTools()
                end

                Runtime.isAutoWalking = false
                return true
            end

            if hDist <= 4.5 then
                pcall(function()
                    local velocity =
                        root.AssemblyLinearVelocity

                    root.AssemblyLinearVelocity =
                        Vector3.new(
                            velocity.X * 0.45,
                            velocity.Y,
                            velocity.Z * 0.45
                        )
                end)
            end

            local now = tick()

            if keepUnequipped
                and now - lastUnequip
                    >= WALK_UNEQUIP_INTERVAL
            then
                forceUnequipTools()
                lastUnequip = now
            end

            if now - lastMoveIssue
                >= WALK_REISSUE_INTERVAL
            then
                pcall(function()
                    hum:MoveTo(targetPos)
                end)

                lastMoveIssue = now
            end

            S.RunService.Heartbeat:Wait()
        end

        stopNaturalWalk()

        local finalRoot = getRoot()
        return finalRoot ~= nil
            and getHorizontalDistance(
                targetPos,
                finalRoot.Position
            ) <= stopDistance + 2.0
    end

    local CameraFreeze = {
        active = false,
        connection = nil,
        camera = nil,
        cframe = nil,
        focus = nil,
        cameraType = nil,
        cameraSubject = nil,
    }

    local function restoreCameraFreeze()
        local freeze = CameraFreeze

        if not freeze.active
            and not freeze.connection
        then
            return
        end

        if freeze.connection then
            pcall(function()
                freeze.connection:Disconnect()
            end)
            freeze.connection = nil
        end

        local camera =
            S.Workspace.CurrentCamera
            or freeze.camera

        if camera then
            pcall(function()
                camera.CameraType =
                    freeze.cameraType
                    or Enum.CameraType.Custom
            end)

            local hum = getHumanoid()

            if hum then
                pcall(function()
                    camera.CameraSubject = hum
                end)
            elseif freeze.cameraSubject then
                pcall(function()
                    camera.CameraSubject =
                        freeze.cameraSubject
                end)
            end
        end

        freeze.active = false
        freeze.camera = nil
        freeze.cframe = nil
        freeze.focus = nil
        freeze.cameraType = nil
        freeze.cameraSubject = nil
    end

    local function beginCameraFreeze(duration)
        restoreCameraFreeze()

        local camera =
            S.Workspace.CurrentCamera

        if not camera then
            return
        end

        CameraFreeze.active = true
        CameraFreeze.camera = camera
        CameraFreeze.cframe = camera.CFrame
        CameraFreeze.focus = camera.Focus
        CameraFreeze.cameraType = camera.CameraType
        CameraFreeze.cameraSubject = camera.CameraSubject

        pcall(function()
            camera.CameraType =
                Enum.CameraType.Scriptable
            camera.CFrame = CameraFreeze.cframe
            camera.Focus = CameraFreeze.focus
        end)

        CameraFreeze.connection =
            S.RunService.RenderStepped:Connect(
                function()
                    if not CameraFreeze.active then
                        return
                    end

                    local cam =
                        S.Workspace.CurrentCamera

                    if cam then
                        pcall(function()
                            cam.CameraType =
                                Enum.CameraType.Scriptable
                            cam.CFrame =
                                CameraFreeze.cframe
                            cam.Focus =
                                CameraFreeze.focus
                        end)
                    end
                end
            )

        task.delay(
            tonumber(duration)
                or CAMERA_FREEZE_SECONDS,
            function()
                if CameraFreeze.active then
                    restoreCameraFreeze()
                end
            end
        )
    end

    local DropPositionPin = {
        active = false,
        connection = nil,
        cycle = 0,
    }

    local function stopDropPositionPin()
        DropPositionPin.active = false
        DropPositionPin.cycle =
            DropPositionPin.cycle + 1

        if DropPositionPin.connection then
            pcall(function()
                DropPositionPin.connection:Disconnect()
            end)
            DropPositionPin.connection = nil
        end
    end

    local function startDropPositionPin(
        shouldContinue
    )
        stopDropPositionPin()

        DropPositionPin.active = true
        DropPositionPin.cycle =
            DropPositionPin.cycle + 1

        local cycle = DropPositionPin.cycle

        local function apply()
            if not DropPositionPin.active
                or DropPositionPin.cycle ~= cycle
                or not allowed(shouldContinue)
            then
                return false
            end

            local root = getRoot()
            local hum = getHumanoid()

            if not root then
                return false
            end

            pcall(function()
                root.CFrame =
                    CFrame.new(DROP_POSITION)
                root.AssemblyLinearVelocity =
                    Vector3.zero
                root.AssemblyAngularVelocity =
                    Vector3.zero
                root.Anchored = false
            end)

            if hum then
                pcall(function()
                    hum:MoveTo(DROP_POSITION)
                    hum:ChangeState(
                        Enum.HumanoidStateType.Running
                    )
                end)
            end

            return true
        end

        apply()

        DropPositionPin.connection =
            S.RunService.Heartbeat:Connect(
                function()
                    if not apply() then
                        stopDropPositionPin()
                    end
                end
            )
    end

    local function waitDropPositionSync(
        shouldContinue
    )
        local deadline =
            tick() + DROP_PIN_PRE_DROP_SECONDS

        while allowed(shouldContinue)
            and tick() < deadline
        do
            local root = getRoot()

            if not root then
                return false
            end

            pcall(function()
                root.CFrame =
                    CFrame.new(DROP_POSITION)
                root.AssemblyLinearVelocity =
                    Vector3.zero
                root.AssemblyAngularVelocity =
                    Vector3.zero
            end)

            S.RunService.Heartbeat:Wait()
        end

        return allowed(shouldContinue)
    end

    local function eggPosition(record)
        if type(record) ~= "table" then
            return nil
        end

        if typeof(record.BoundsCFrame) == "CFrame" then
            return record.BoundsCFrame.Position
        end

        if typeof(record.BottomCFrame) == "CFrame" then
            return record.BottomCFrame.Position
        end

        return nil
    end

    local function readRawEggRecord(uid)
        uid = tostring(uid or "")
        if uid == "" then
            return nil
        end

        local ES = eggState()

        if ES and type(ES.ReadFieldEgg) == "function" then
            local ok, record = pcall(
                ES.ReadFieldEgg,
                uid
            )

            if ok and type(record) == "table" then
                return record
            end
        end

        local live =
            DHub.GlobalEggScanner:Get(
                uid,
                true
            )

        return live and live.raw or nil
    end

    local function isExactCarryConfirmed(uid)
        uid = tostring(uid or "")

        if DHub.CarryService
            and DHub.CarryService:IsCarrying(uid)
        then
            return true, {
                IsCarrying = true,
                Uid = uid,
            }
        end

        local record = readRawEggRecord(uid)

        if type(record) == "table"
            and tostring(record.State or "") == "Carried"
            and tonumber(record.CarrierUserId)
                == tonumber(LP.UserId)
        then
            return true, {
                IsCarrying = true,
                Uid = uid,
                AreaId = record.AreaId,
                AssetCategory = record.AssetCategory,
            }
        end

        return false, nil
    end

    local function getEggPromptForTarget(
        uid,
        pos,
        maxDistance
    )
        uid = tostring(uid or "")
        maxDistance = tonumber(maxDistance) or 3.5

        local aesc =
            S.Workspace:FindFirstChild(
                "AreaEggSlotsClient"
            )

        if aesc and uid ~= "" then
            local model = aesc:FindFirstChild(uid)

            if model then
                local prompt =
                    model:FindFirstChildWhichIsA(
                        "ProximityPrompt",
                        true
                    )

                if prompt and prompt.Enabled then
                    return prompt
                end
            end
        end

        if uid ~= "" then
            local model =
                S.Workspace:FindFirstChild(uid)

            if model then
                local prompt =
                    model:FindFirstChildWhichIsA(
                        "ProximityPrompt",
                        true
                    )

                if prompt and prompt.Enabled then
                    return prompt
                end
            end
        end

        if typeof(pos) == "Vector3" then
            local bestPrompt = nil
            local bestDistance = maxDistance

            for _, child in ipairs(
                S.Workspace:GetChildren()
            ) do
                if child.Name == "SmartPromptPart"
                    and child:IsA("BasePart")
                then
                    local distance =
                        (child.Position - pos).Magnitude

                    if distance <= bestDistance then
                        local prompt =
                            child:FindFirstChildOfClass(
                                "ProximityPrompt"
                            )

                        if prompt
                            and prompt.Enabled
                        then
                            bestPrompt = prompt
                            bestDistance = distance
                        end
                    end
                end
            end

            if bestPrompt then
                return bestPrompt
            end
        end

        return nil
    end

    local function getEggTargetWalkPosition(target)
        if type(target) ~= "table"
            or typeof(target.pos) ~= "Vector3"
        then
            return nil
        end

        local uid = tostring(target.uid or "")
        local aesc =
            S.Workspace:FindFirstChild(
                "AreaEggSlotsClient"
            )

        if aesc and uid ~= "" then
            local model = aesc:FindFirstChild(uid)

            if model then
                local part =
                    model:FindFirstChild("Hitbox")
                    or model:FindFirstChild(
                        "CustomBoundingBox"
                    )
                    or model.PrimaryPart

                if part and part:IsA("BasePart") then
                    return part.Position
                end
            end
        end

        for _, child in ipairs(
            S.Workspace:GetChildren()
        ) do
            if child.Name == "SmartPromptPart"
                and child:IsA("BasePart")
                and (
                    child.Position - target.pos
                ).Magnitude <= 3.5
            then
                return child.Position
            end
        end

        return target.pos
    end

    local function acquireTargetCarry(
        target,
        shouldContinue
    )
        local uid = tostring(
            target and target.uid or ""
        )

        if uid == "" then
            return false, nil
        end

        local deadline = tick() + 6.0
        local nextPrompt = 0
        local nextRemote = 0
        local ES = eggState()

        while allowed(shouldContinue)
            and tick() < deadline
        do
            local confirmed, payload =
                isExactCarryConfirmed(uid)

            if confirmed then
                return true, payload
            end

            if DHub.CarryService
                and DHub.CarryService.carrying
                and DHub.CarryService.carryUid
                and tostring(
                    DHub.CarryService.carryUid
                ) ~= uid
            then
                pcall(function()
                    if ES and ES.DropFieldEgg then
                        ES.DropFieldEgg(
                            "PlayerRequest"
                        )
                    end
                end)

                task.wait(0.08)
            end

            local now = tick()

            if now >= nextPrompt then
                nextPrompt = now + 0.08

                local prompt =
                    getEggPromptForTarget(
                        uid,
                        target.pos,
                        3.5
                    )

                if prompt then
                    pcall(function()
                        prompt.HoldDuration = 0
                        fireproximityprompt(prompt)
                    end)
                end
            end

            if now >= nextRemote then
                nextRemote = now + 0.10

                if ES and ES.CarryFieldEgg then
                    pcall(function()
                        ES.CarryFieldEgg(uid)
                    end)
                elseif DHub.CarryService then
                    pcall(function()
                        DHub.CarryService:TryOnce(
                            target
                        )
                    end)
                end
            end

            S.RunService.Heartbeat:Wait()
        end

        return isExactCarryConfirmed(uid)
    end

    local function waitCarryTransition(
        expectedCarry,
        action,
        shouldContinue,
        timeout
    )
        local done = false
        local ES = eggState()
        local connection = nil

        if ES
            and ES.CarryChanged
            and type(ES.CarryChanged.Connect)
                == "function"
        then
            connection =
                ES.CarryChanged:Connect(
                    function(data)
                        if type(data) ~= "table" then
                            return
                        end

                        if (
                            data.IsCarrying == true
                        ) == expectedCarry
                        then
                            done = true
                        end
                    end
                )
        end

        pcall(action)

        local deadline =
            tick() + (tonumber(timeout) or 3)

        while not done
            and allowed(shouldContinue)
            and tick() < deadline
        do
            local carrying =
                DHub.CarryService
                and DHub.CarryService.carrying
                or isCarryingEgg()

            if expectedCarry and carrying then
                done = true
            elseif not expectedCarry
                and not carrying
            then
                done = true
            end

            task.wait(0.02)
        end

        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        return done
    end

    local function getPromptWorldPosition(prompt)
        if not prompt or not prompt.Parent then
            return nil
        end

        local parent = prompt.Parent

        if parent:IsA("BasePart") then
            return parent.Position
        end

        if parent:IsA("Attachment")
            and parent.Parent
            and parent.Parent:IsA("BasePart")
        then
            return parent.Parent.Position
        end

        local model =
            prompt:FindFirstAncestorWhichIsA(
                "Model"
            )

        if model then
            local part =
                model:FindFirstChild(
                    "Hitbox",
                    true
                )
                or model:FindFirstChild(
                    "CustomBoundingBox",
                    true
                )
                or model.PrimaryPart
                or model:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            if part and part:IsA("BasePart") then
                return part.Position
            end
        end

        return nil
    end

    local function promptHasUid(prompt, uid)
        uid = tostring(uid or "")
        if uid == "" or not prompt then
            return false
        end

        local node = prompt.Parent

        while node and node ~= S.Workspace do
            if tostring(node.Name) == uid
                or tostring(
                    node:GetAttribute("Uid")
                    or ""
                ) == uid
                or tostring(
                    node:GetAttribute("UID")
                    or ""
                ) == uid
            then
                return true
            end

            node = node.Parent
        end

        return false
    end

    local function isEggPromptCandidate(prompt)
        if not prompt
            or not prompt:IsA("ProximityPrompt")
            or not prompt.Enabled
        then
            return false
        end

        local action = string.lower(
            tostring(prompt.ActionText or "")
        )
        local objectText = string.lower(
            tostring(prompt.ObjectText or "")
        )
        local name = string.lower(
            tostring(prompt.Name or "")
        )
        local parentName =
            prompt.Parent
            and string.lower(
                tostring(prompt.Parent.Name or "")
            )
            or ""

        if action:find("steal", 1, true)
            or action:find("egg", 1, true)
            or action:find("pick", 1, true)
            or action:find("carry", 1, true)
            or objectText:find("egg", 1, true)
            or name:find("egg", 1, true)
            or parentName:find("egg", 1, true)
            or parentName:find(
                "smartprompt",
                1,
                true
            )
        then
            return true
        end

        local aesc =
            S.Workspace:FindFirstChild(
                "AreaEggSlotsClient"
            )

        return aesc ~= nil
            and prompt:IsDescendantOf(aesc)
    end

    local function findDroppedEggPrompt(
        uid,
        searchPos,
        radius
    )
        uid = tostring(uid or "")
        radius = tonumber(radius)
            or DROP_PROMPT_RADIUS

        if typeof(searchPos) ~= "Vector3" then
            return nil, nil
        end

        local root = getRoot()
        if not root then
            return nil, nil
        end

        local bestPrompt = nil
        local bestPos = nil
        local bestScore = math.huge

        for _, object in ipairs(
            S.Workspace:GetDescendants()
        ) do
            if object:IsA("ProximityPrompt")
                and isEggPromptCandidate(object)
            then
                local pos =
                    getPromptWorldPosition(object)

                if typeof(pos) == "Vector3" then
                    local eggDistance =
                        getHorizontalDistance(
                            pos,
                            searchPos
                        )

                    local playerDistance =
                        getHorizontalDistance(
                            root.Position,
                            pos
                        )

                    if eggDistance <= radius
                        and playerDistance <= 12
                    then
                        local score = eggDistance

                        if promptHasUid(
                            object,
                            uid
                        ) then
                            score = score - 2.0
                        end

                        if score < bestScore then
                            bestPrompt = object
                            bestPos = pos
                            bestScore = score
                        end
                    end
                end
            end
        end

        return bestPrompt, bestPos
    end

    local function waitStableDroppedUidNearUs(
        uid,
        shouldContinue,
        timeout
    )
        uid = tostring(uid or "")
        if uid == "" then
            return nil, nil, "uid_missing"
        end

        local deadline =
            tick() + (tonumber(timeout) or 3.5)

        local stable = 0
        local lastPos = nil

        while allowed(shouldContinue)
            and tick() < deadline
        do
            local record =
                readRawEggRecord(uid)

            if type(record) == "table" then
                local state = tostring(
                    record.State or ""
                )
                local pos = eggPosition(record)

                if state == "Dropped"
                    and typeof(pos) == "Vector3"
                then
                    local distance =
                        getHorizontalDistance(
                            pos,
                            DROP_POSITION
                        )

                    if distance
                        <= DROP_AREA_CARRY_RADIUS
                    then
                        if lastPos
                            and getHorizontalDistance(
                                pos,
                                lastPos
                            ) <= 1.5
                        then
                            stable = stable + 1
                        else
                            stable = 1
                        end

                        lastPos = pos

                        if stable
                            >= DROP_STATE_STABLE_READS
                        then
                            return record, pos, nil
                        end
                    else
                        stable = 0
                        lastPos = nil
                    end
                else
                    stable = 0
                    lastPos = nil
                end
            end

            S.RunService.Heartbeat:Wait()
        end

        return nil,
            nil,
            "dropped_uid_not_stable_near_drop"
    end

    local function reCarryAtDropPosition(
        target,
        droppedRecord,
        droppedPos,
        shouldContinue,
        timeout
    )
        local uid = tostring(
            target and target.uid or ""
        )

        if uid == "" then
            return false, nil, "target_uid_missing"
        end

        droppedPos =
            typeof(droppedPos) == "Vector3"
            and droppedPos
            or (
                type(droppedRecord) == "table"
                and eggPosition(droppedRecord)
            )
            or DROP_POSITION

        local deadline =
            tick() + (tonumber(timeout) or RECARRY_TIMEOUT)

        local nextPromptTry = 0
        local lastPrompt = nil
        local stablePromptReads = 0

        while allowed(shouldContinue)
            and tick() < deadline
        do
            local confirmed, payload =
                isExactCarryConfirmed(uid)

            if confirmed then
                return true, payload, nil
            end

            local record =
                readRawEggRecord(uid)
            local livePos = nil

            if type(record) == "table" then
                local state = tostring(
                    record.State or ""
                )
                local pos = eggPosition(record)

                if state == "Carried"
                    and tonumber(
                        record.CarrierUserId
                    ) == tonumber(LP.UserId)
                then
                    return true, {
                        IsCarrying = true,
                        Uid = uid,
                        AssetCategory =
                            record.AssetCategory,
                        AreaId = record.AreaId,
                    }, nil
                end

                if state == "Dropped"
                    and typeof(pos) == "Vector3"
                    and getHorizontalDistance(
                        pos,
                        DROP_POSITION
                    ) <= DROP_AREA_CARRY_RADIUS
                then
                    livePos = pos
                    droppedPos = pos
                    target.pos = pos
                end
            end

            local root = getRoot()
            local hum = getHumanoid()

            if root then
                pcall(function()
                    root.CFrame =
                        CFrame.new(DROP_POSITION)
                    root.AssemblyLinearVelocity =
                        Vector3.zero
                    root.AssemblyAngularVelocity =
                        Vector3.zero
                    root.Anchored = false
                end)
            end

            if hum then
                pcall(function()
                    hum:MoveTo(DROP_POSITION)
                end)
            end

            if livePos
                and tick() >= nextPromptTry
            then
                nextPromptTry = tick() + 0.06

                local prompt, promptPos =
                    findDroppedEggPrompt(
                        uid,
                        livePos,
                        DROP_PROMPT_RADIUS
                    )

                if prompt
                    and typeof(promptPos)
                        == "Vector3"
                then
                    if prompt == lastPrompt then
                        stablePromptReads =
                            stablePromptReads + 1
                    else
                        lastPrompt = prompt
                        stablePromptReads = 1
                    end

                    if stablePromptReads
                        >= DROP_PROMPT_STABLE_READS
                    then
                        pcall(function()
                            prompt.HoldDuration = 0
                            fireproximityprompt(prompt)
                        end)
                    end
                else
                    lastPrompt = nil
                    stablePromptReads = 0
                end
            end

            S.RunService.Heartbeat:Wait()
        end

        local confirmed, payload =
            isExactCarryConfirmed(uid)

        if confirmed then
            return true, payload, nil
        end

        return false, nil, "recarry_timeout"
    end

    local function inventoryUidSet()
        local seen = {}
        local containers = {
            LP:FindFirstChildOfClass("Backpack"),
            LP.Character,
        }

        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(
                    container:GetChildren()
                ) do
                    if item:IsA("Tool")
                        and item:GetAttribute("ItemType")
                            == "AssetEgg"
                    then
                        local uid =
                            item:GetAttribute("UID")

                        if uid then
                            seen[tostring(uid)] = true
                        end
                    end
                end
            end
        end

        return seen
    end

    local function findNewInventoryEgg(
        beforeSet,
        expectedCategory
    )
        local containers = {
            LP:FindFirstChildOfClass("Backpack"),
            LP.Character,
        }

        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(
                    container:GetChildren()
                ) do
                    if item:IsA("Tool")
                        and item:GetAttribute("ItemType")
                            == "AssetEgg"
                    then
                        local uid = tostring(
                            item:GetAttribute("UID")
                            or ""
                        )
                        local category = tostring(
                            item:GetAttribute(
                                "AssetCategory"
                            )
                            or ""
                        )

                        if uid ~= ""
                            and not beforeSet[uid]
                            and (
                                not expectedCategory
                                or category
                                    == expectedCategory
                            )
                        then
                            return item, uid
                        end
                    end
                end
            end
        end

        return nil, nil
    end

    local function waitForRedeemAndInventory(
        expectedCategory,
        beforeSet,
        moveAction,
        shouldContinue,
        timeout
    )
        local verdict = nil
        local verdictSeen = false
        local connection = nil

        if RedeemRemote
            and RedeemRemote:IsA("RemoteEvent")
        then
            connection =
                RedeemRemote.OnClientEvent:Connect(
                    function(data)
                        if type(data) ~= "table" then
                            return
                        end

                        if expectedCategory
                            and data.AssetCategory
                            and tostring(
                                data.AssetCategory
                            ) ~= tostring(
                                expectedCategory
                            )
                        then
                            return
                        end

                        verdict = data
                        verdictSeen = true
                    end
                )
        end

        local moved = moveAction()

        if not moved and not verdictSeen then
            if connection then
                connection:Disconnect()
            end

            return false,
                nil,
                nil,
                "safezone_walk_failed"
        end

        local deadline =
            tick() + (tonumber(timeout) or 8)

        local tool = nil
        local newUid = nil

        repeat
            if not allowed(shouldContinue) then
                break
            end

            tool, newUid =
                findNewInventoryEgg(
                    beforeSet,
                    expectedCategory
                )

            if verdictSeen and tool then
                break
            end

            task.wait(0.03)
        until tick() >= deadline

        if connection then
            connection:Disconnect()
        end

        if verdictSeen and tool then
            return true, verdict, newUid
        end

        if tool then
            return true, verdict or {}, newUid
        end

        return false,
            nil,
            nil,
            "redeem_timeout"
    end

    local function refreshTarget(target)
        return DHub.GlobalEggScanner:RefreshTarget(
            target
        )
    end

    local function runFastStealTarget(
        inputTarget,
        shouldContinue,
        statusCallback
    )
        if State.busy then
            return false, nil, nil, "fast_busy"
        end

        local target =
            refreshTarget(inputTarget)
            or inputTarget

        if type(target) ~= "table"
            or not target.uid
            or typeof(target.pos) ~= "Vector3"
        then
            return false, nil, nil, "target_missing"
        end

        State.busy = true
        State.busyUid = tostring(target.uid)

        local function finish(
            success,
            inventoryUid,
            verdict,
            reason
        )
            stopNaturalWalk()
            stopDropPositionPin()
            restoreCameraFreeze()

            Runtime.fastDropTransactionActive = false

            State.busy = false
            State.busyUid = nil

            return success == true,
                inventoryUid,
                verdict,
                reason
        end

        local beforeInventory =
            inventoryUidSet()

        -- Same opening route as the proven mini engine.
        emit(
            statusCallback,
            "FAST: Safezone first"
        )

        if not naturalWalkToTarget(
            SAFEZONE_POS,
            SAFEZONE_STOP_DISTANCE,
            shouldContinue,
            false
        ) then
            return finish(
                false,
                nil,
                nil,
                "safezone_first_failed"
            )
        end

        if not allowed(shouldContinue) then
            return finish(false, nil, nil, "stopped")
        end

        target = refreshTarget(target)
        if not target then
            return finish(
                false,
                nil,
                nil,
                "target_gone"
            )
        end

        local walkPos =
            getEggTargetWalkPosition(target)

        emit(
            statusCallback,
            "FAST: walking to "
                .. tostring(
                    target.category or "egg"
                )
        )

        if not naturalWalkToTarget(
            walkPos,
            TARGET_STOP_DISTANCE,
            shouldContinue,
            true
        ) then
            return finish(
                false,
                nil,
                nil,
                "walk_failed"
            )
        end

        if not allowed(shouldContinue) then
            return finish(false, nil, nil, "stopped")
        end

        target = refreshTarget(target) or target

        -- From target pickup until this Fast transaction finishes, FastFarm
        -- exclusively owns character transport. Kill any stale Anti Boss
        -- Safezone writer and prevent the prompt listener from starting a new one.
        Runtime.fastDropTransactionActive = true
        stopAntiBossSpamTeleport()

        emit(
            statusCallback,
            "FAST: picking locked egg"
        )

        local carried =
            acquireTargetCarry(
                target,
                shouldContinue
            )

        if not carried then
            return finish(
                false,
                nil,
                nil,
                "first_carry_failed"
            )
        end

        beginCameraFreeze(
            CAMERA_FREEZE_SECONDS
        )

        emit(
            statusCallback,
            "FAST: instant drop position"
        )

        -- Absolute transport ownership: there must be only ONE Heartbeat
        -- CFrame writer while the egg is being dropped/re-carried.
        stopAntiBossSpamTeleport()

        startDropPositionPin(
            shouldContinue
        )

        if not waitDropPositionSync(
            shouldContinue
        ) then
            return finish(false, nil, nil, "stopped")
        end

        emit(statusCallback, "FAST: dropping egg")

        local ES = eggState()

        local dropped =
            waitCarryTransition(
                false,
                function()
                    if ES and ES.DropFieldEgg then
                        ES.DropFieldEgg(
                            "PlayerRequest"
                        )
                    end
                end,
                shouldContinue,
                2.5
            )

        restoreCameraFreeze()

        if not dropped then
            return finish(
                false,
                nil,
                nil,
                "drop_failed"
            )
        end

        emit(
            statusCallback,
            "FAST: server drop settle"
        )

        local settleUntil =
            tick() + DROP_SERVER_SETTLE_SECONDS

        while allowed(shouldContinue)
            and tick() < settleUntil
        do
            S.RunService.Heartbeat:Wait()
        end

        if not allowed(shouldContinue) then
            return finish(false, nil, nil, "stopped")
        end

        local droppedRecord,
            droppedPos,
            dropError =
            waitStableDroppedUidNearUs(
                target.uid,
                shouldContinue,
                3.5
            )

        if not droppedRecord
            or typeof(droppedPos) ~= "Vector3"
        then
            return finish(
                false,
                nil,
                nil,
                dropError
                    or "dropped_uid_not_ready"
            )
        end

        target.pos = droppedPos

        emit(
            statusCallback,
            "FAST: re-carry dropped egg"
        )

        local reCarried,
            _,
            recarryError =
            reCarryAtDropPosition(
                target,
                droppedRecord,
                droppedPos,
                shouldContinue,
                RECARRY_TIMEOUT
            )

        stopDropPositionPin()

        if not reCarried then
            return finish(
                false,
                nil,
                nil,
                recarryError
                    or "recarry_timeout"
            )
        end

        task.wait(0.10)

        emit(
            statusCallback,
            "FAST: carrying -> Safezone"
        )

        local success,
            verdict,
            inventoryUid,
            redeemError =
            waitForRedeemAndInventory(
                tostring(
                    target.category or ""
                ),
                beforeInventory,
                function()
                    return naturalWalkToTarget(
                        SAFEZONE_POS,
                        SAFEZONE_STOP_DISTANCE,
                        shouldContinue,
                        false
                    )
                end,
                shouldContinue,
                14
            )

        if not success then
            return finish(
                false,
                nil,
                nil,
                redeemError
                    or "safezone_failed"
            )
        end

        -- Same successful steal point as the supplied mini script.
        if DHub.EggWebhook
            and DHub.EggWebhook.SendFromFarmResult
        then
            pcall(function()
                DHub.EggWebhook:SendFromFarmResult(
                    target,
                    inventoryUid,
                    verdict
                )
            end)
        end

        Runtime.steals =
            (Runtime.steals or 0) + 1

        return finish(
            true,
            inventoryUid,
            verdict,
            nil
        )
    end

    local function mainAlive(gen)
        return State.active
            and State.generation == gen
            and Cfg.autoFarm == true
            and Cfg.farmMethod == "Fast"
    end

    local function waitIdleTreadmill(gen)
        if not Cfg.autoTreadmill then
            task.wait(0.12)
            return
        end

        local penInfo = findMyPlot()
        local treadmill =
            penInfo
            and penInfo.plot
            and penInfo.plot:FindFirstChild(
                "TreadmillBottom"
            )

        if not treadmill then
            task.wait(0.20)
            return
        end

        local function idleAllowed()
            return mainAlive(gen)
                and Cfg.autoTreadmill
                and not isCarryingEgg()
                and not (
                    DHub.EventWavePriority
                    and DHub.EventWavePriority:
                        ShouldPauseMainFarm()
                )
                and not DHub.TargetSelector:
                    HasFarmCandidate()
        end

        if not idleAllowed() then
            return
        end

        emit(nil, "FAST: idle -> treadmill")

        if not (
            DHub.TreadmillMount
            and DHub.TreadmillMount.active
        )
        then
            if isPlayerOnTreadmill() ~= true then
                naturalWalkToTarget(
                    treadmill.Position
                        + Vector3.new(0, 2.25, 0),
                    3.25,
                    idleAllowed,
                    false
                )
            end

            if idleAllowed()
                and DHub.TreadmillMount
            then
                DHub.TreadmillMount:TryMount()
            end
        end

        while idleAllowed()
            and DHub.TreadmillMount
            and DHub.TreadmillMount.active
        do
            task.wait(0.08)
        end

        if DHub.TreadmillMount
            and DHub.TreadmillMount.active
        then
            -- treadmill release deferred until an actual Safezone route
        end
    end

    local function worker(gen)
        State.workerRunning = true
        Runtime.farming = true

        DHub.FarmCoordinator:ClearTarget()
        DHub.FarmCoordinator:SetState("Idle")

        while mainAlive(gen) do
            if DHub.EventWavePriority
                and DHub.EventWavePriority:
                    ShouldPauseMainFarm()
            then
                if isPlayerOnTreadmill() then
                    -- treadmill release deferred until an actual Safezone route
                end

                emit(nil, "FAST: paused for event automation")
                task.wait(0.08)
                continue
            end

            if DHub.ResetBarrierService:IsSealed()
                or DHub.ResetBarrierService.kaitunNightPending
                    == true
            then
                if isPlayerOnTreadmill() then
                    -- treadmill release deferred until an actual Safezone route
                end

                emit(nil, "FAST: night/reset -> Safezone")

                naturalWalkToTarget(
                    SAFEZONE_POS,
                    SAFEZONE_STOP_DISTANCE,
                    function()
                        return mainAlive(gen)
                    end,
                    false
                )

                DHub.ResetBarrierService:WaitOpen(
                    function()
                        return mainAlive(gen)
                    end
                )

                task.wait(0.25)
                continue
            end

            if isCarryingEgg() then
                emit(nil, "FAST: recovering carry -> Safezone")
                pcall(instantCarryEscape)
                task.wait(0.08)
                continue
            end

            local target =
                DHub.TargetSelector:GetBestFarmTarget()

            if not target then
                local plotted = false

                if PlotRuntime.RunFarmPlotPriority then
                    local ok, result = pcall(
                        PlotRuntime.RunFarmPlotPriority,
                        "FAST"
                    )

                    plotted = ok and result == true
                end

                if plotted then
                    task.wait(0.03)
                    continue
                end

                if DHub.TargetSelector:HasFarmCandidate() then
                    task.wait(0.03)
                    continue
                end

                waitIdleTreadmill(gen)
                continue
            end

            State.latestTarget = target
            State.busyUid = tostring(target.uid)

            DHub.FarmCoordinator:LockTarget(
                "Fast",
                target
            )

            emit(
                nil,
                "FAST TARGET: "
                    .. tostring(
                        target.category or "Egg"
                    )
            )

            local success,
                _,
                _,
                reason =
                runFastStealTarget(
                    target,
                    function()
                        return mainAlive(gen)
                            and not (
                                DHub.EventWavePriority
                                and DHub.EventWavePriority:
                                    ShouldPauseMainFarm()
                            )
                    end,
                    UpdateStatus
                )

            DHub.FarmCoordinator:ClearTarget(
                target.uid
            )

            State.latestTarget = nil
            State.busyUid = nil

            if success then
                UpdateStatus("FAST: egg secured")
                DHub.FarmCoordinator:Wake()
                task.wait(0.12)
            else
                UpdateStatus(
                    "FAST retry: "
                        .. tostring(reason or "unknown")
                )
                task.wait(0.20)
            end
        end

        stopNaturalWalk()
        stopDropPositionPin()
        restoreCameraFreeze()

        DHub.FarmCoordinator:ClearTarget()
        DHub.FarmCoordinator:SetState("Idle")

        State.active = false
        State.workerRunning = false
        State.latestTarget = nil
        State.busyUid = nil
        Runtime.farming = false

        if Cfg.farmMethod == "Fast" then
            UpdateStatus("Idle")
        end
    end

    local function start()
        if State.active
            or Runtime.farming
            or Cfg.farmMethod ~= "Fast"
        then
            return
        end

        State.active = true
        State.generation =
            State.generation + 1

        local gen = State.generation
        task.spawn(function()
            worker(gen)
        end)
    end

    local function stop()
        State.active = false
        State.generation =
            State.generation + 1

        stopNaturalWalk()
        stopDropPositionPin()
        restoreCameraFreeze()

        State.latestTarget = nil
        State.busyUid = nil
        State.busy = false

        if DHub.MovementService.currentOwner
            == "MainFarm"
        then
            DHub.MovementService:Cancel(
                "MainFarm"
            )
        end
    end

    local function farmSpecificTarget(
        target,
        shouldContinue,
        statusCallback
    )
        if Cfg.farmMethod ~= "Fast" then
            return false, nil, nil, "not_fast"
        end

        return runFastStealTarget(
            target,
            shouldContinue,
            statusCallback
        )
    end

    return {
        Start = start,
        Stop = stop,
        State = State,
        FarmSpecificTarget = farmSpecificTarget,
    }
end)()

Runtime.FastFarmStart = function()
    if Cfg.autoFarm
        and Cfg.farmMethod == "Fast"
        and not Runtime.farming
    then
        FastFarm.Start()
    end
end

Runtime.FastFarmStop = function()
    FastFarm.Stop()
end

Runtime.FastFarmCarrySpecificTarget = function(
    target,
    shouldContinue,
    statusCallback
)
    return FastFarm.FarmSpecificTarget(
        target,
        shouldContinue,
        statusCallback
    )
end

-- =====================================================================
-- D-HUB V3 FRESH FARM COORDINATOR
--
-- IMPORTANT:
-- * ORIGINAL V3 UI / TABS / SHOP / PLOT / MISC / INFO ARE NOT REBUILT.
-- * This block replaces ONLY farm-state ownership.
-- * Normal + Fast use the game's current native Humanoid walking speed.
-- * Fast means Instant-Steal transaction, NOT movement-speed modification.
-- * Scramble Lab scanner is standalone and stays alive with Auto Fuse OFF.
-- * One coordinator decides which farm job may run.
-- =====================================================================

(function()
local dhubBootEnv = (type(getgenv) == "function" and getgenv()) or _G
dhubBootEnv.DHubV3BootStage = "FRESH_ENGINE_INIT"

-- Create the namespace BEFORE anything indexes `dhub`.
DHub.DHubFresh = DHub.DHubFresh or {}
local dhub = DHub.DHubFresh

-- Donor primitives from the original V3 engine.
dhub.LegacyFastFarm = FastFarm
dhub.LegacyAutoBoss = DHub.AutoBoss
dhub.LegacyScrambleFuse = DHub.ScrambleFuse

dhub.State = {
    alive = true,
    started = false,

    revision = 0,
    currentJob = nil,
    currentJobId = 0,
    currentJobKind = "IDLE",

    reset = {
        active = false,
        epoch = 0,
        revision = 0,
        openedAt = 0,
    },

    scramble = {
        state = nil,
        requirements = {},
        slots = {nil, nil, nil},
        signature = "",
        revision = 0,
        lastUpdateAt = 0,
        lastError = "",
        automationPhase = "Idle",
        localRetryAt = 0,
    },

    boss = {
        open = false,
        opensAt = 0,
        closesAt = 0,
        arena = nil,
        revision = 0,
        lastUpdateAt = 0,
    },

    idleMounted = false,
    lastIdleMountAttempt = 0,

    autoFarmWatcherGeneration = 0,
}

dhub.WakeEvent = Instance.new("BindableEvent")

local function freshWake()
    dhub.State.revision = dhub.State.revision + 1

    pcall(function()
        dhub.WakeEvent:Fire()
    end)

    pcall(function()
        if DHub.FarmCoordinator
            and DHub.FarmCoordinator.Wake
        then
            DHub.FarmCoordinator:Wake()
        end
    end)
end

local function freshAnyAutomationEnabled()
    return Cfg.autoFarm == true
        or EventCfg.autoBoss == true
        or EventCfg.autoFuseScrambler == true
end

local function freshJobAlive(job)
    return dhub.State.alive
        and DHub.LongAFKRuntime.alive
        and dhub.State.currentJob == job
end

local function freshSetFusePhase(message)
    dhub.State.scramble.automationPhase =
        tostring(message or "Idle")
end

-- Keep original UI control visible, but movement-speed writes are disabled.
-- The slider may still save its value for compatibility; farm movement does
-- not consume it.
applyConfiguredWalkSpeedNow = function()
    return
end

-- Disable the legacy idle treadmill loop. The thread may already exist,
-- but it becomes permanently non-driving and the fresh coordinator owns idle.
if DHub.GlobalIdleTreadmill then
    DHub.GlobalIdleTreadmill.ShouldDrive =
        function()
            return false
        end
end

-- -------------------- RESET SCANNER --------------------

local function freshResetRead()
    local service =
        DHub.ResetBarrierService

    local sealed = false

    if service
        and service.IsSealed
    then
        local ok, result =
            pcall(function()
                return service:IsSealed()
            end)

        sealed =
            ok
            and result == true
            or false
    end

    if sealed ~= dhub.State.reset.active then
        dhub.State.reset.active = sealed
        dhub.State.reset.revision =
            dhub.State.reset.revision + 1

        if sealed then
            dhub.State.reset.epoch =
                dhub.State.reset.epoch + 1
        else
            dhub.State.reset.openedAt =
                tick()

            pcall(function()
                if DHub.GlobalEggScanner
                    and DHub.GlobalEggScanner.Resync
                then
                    DHub.GlobalEggScanner:Resync()
                end
            end)
        end

        freshWake()
    end

    return sealed
end

pcall(function()
    local resetModule =
        DHub.ResetBarrierService
        and DHub.ResetBarrierService.module

    if resetModule
        and resetModule.Changed
        and type(resetModule.Changed.Connect)
            == "function"
    then
        local conn =
            resetModule.Changed:Connect(
                function(value)
                    local sealed =
                        value == true

                    if sealed
                        ~= dhub.State.reset.active
                    then
                        dhub.State.reset.active =
                            sealed

                        dhub.State.reset.revision =
                            dhub.State.reset.revision
                            + 1

                        if sealed then
                            dhub.State.reset.epoch =
                                dhub.State.reset.epoch
                                + 1
                        else
                            dhub.State.reset.openedAt =
                                tick()

                            task.defer(function()
                                pcall(function()
                                    DHub.GlobalEggScanner:
                                        Resync()
                                end)
                            end)
                        end

                        freshWake()
                    end
                end
            )

        table.insert(
            ScriptConnections,
            conn
        )
    end
end)

freshResetRead()

-- -------------------- SCRAMBLE STANDALONE SCANNER --------------------

local function freshScrambleGui()
    local pg =
        LP:FindFirstChildOfClass(
            "PlayerGui"
        )

    if not pg then
        return nil
    end

    return pg:FindFirstChild(
        "DrScrambleTradeIn"
    )
        or pg:FindFirstChild(
            "DrScrambleTradeInNEW"
        )
end

local function freshScrambleMainInventory()
    local gui =
        freshScrambleGui()

    if not gui then
        return nil, nil, nil
    end

    return gui,
        gui:FindFirstChild(
            "DrScrambleTradeInMain",
            true
        ),
        gui:FindFirstChild(
            "DrScrambleTradeInInventory",
            true
        )
end

local function freshScrambleSlotFrame(index)
    local _, main =
        freshScrambleMainInventory()

    local inputs =
        main
        and main:FindFirstChild(
            "SacrificeInputs",
            true
        )

    return inputs
        and inputs:FindFirstChild(
            "Input"
            .. tostring(index)
        )
        or nil
end

local function freshScrambleSlotState(index)
    local slot =
        freshScrambleSlotFrame(index)

    if not slot then
        return nil
    end

    local full =
        slot:FindFirstChild("Full")

    local empty =
        slot:FindFirstChild("Empty")

    if full
        and full.Visible == true
    then
        return true
    end

    if empty
        and empty.Visible == true
    then
        return false
    end

    if empty
        and empty.Visible == false
    then
        return true
    end

    return nil
end

local function freshRequirementKey(value)
    local key =
        tostring(value or "")
            :lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            :gsub("%s+", " ")
            :gsub("%s+egg$", "")

    return key
end

local function freshSameRequirement(a, b)
    local ka =
        freshRequirementKey(a)

    local kb =
        freshRequirementKey(b)

    return ka ~= ""
        and kb ~= ""
        and ka == kb
end

local function freshRequirementSignature(
    requirements,
    slots,
    state
)
    local parts = {}

    for i = 1, 3 do
        parts[#parts + 1] =
            tostring(
                requirements[i]
                or ""
            )

        parts[#parts + 1] =
            tostring(
                slots[i]
            )
    end

    parts[#parts + 1] =
        tostring(
            state
            and state.PendingReward
                == true
            or false
        )

    parts[#parts + 1] =
        tostring(
            state
            and state.BannerId
            or ""
        )

    parts[#parts + 1] =
        tostring(
            state
            and state.PityCount
            or ""
        )

    return table.concat(
        parts,
        "\31"
    )
end

local freshFindOwnedCategory

local function freshUpdateScrambleUi()
    local runtime =
        DHub.ScrambleFuse
        and DHub.ScrambleFuse.Runtime

    if not runtime then
        return
    end

    local state =
        dhub.State.scramble.state

    local requirements =
        dhub.State.scramble.requirements

    local slots =
        dhub.State.scramble.slots

    if runtime.statusLabel
        and runtime.statusLabel.Parent
    then
        local banner =
            state
            and (
                state.BannerDisplayName
                or state.BannerId
            )
            or "Waiting State"

        runtime.statusLabel.Text =
            string.format(
                "Scramble Fuse: Scanner Live | Auto %s | %s | %s",
                EventCfg.autoFuseScrambler
                    and "ON"
                    or "OFF",
                tostring(
                    dhub.State.scramble
                        .automationPhase
                        or "Idle"
                ),
                tostring(banner)
            )
    end

    local usedOwned = {}

    for i = 1, 3 do
        local label =
            runtime.slotLabels
            and runtime.slotLabels[i]

        if label
            and label.Parent
        then
            local category =
                requirements[i]
                or "Scanning..."

            local slot =
                slots[i]

            if slot == true then
                label.Text =
                    string.format(
                        "[✓] %s (Added To Machine)",
                        tostring(category)
                    )

                label.TextColor3 =
                    Color3.fromRGB(
                        100,
                        235,
                        145
                    )
            elseif slot == false then
                -- IMPORTANT ORDER:
                -- First check backpack. A required egg already owned must NOT
                -- be painted as "In World" just because another copy spawned.
                local ownedUid =
                    freshFindOwnedCategory(
                        category,
                        usedOwned
                    )

                if ownedUid then
                    usedOwned[
                        tostring(ownedUid)
                    ] = true

                    label.Text =
                        string.format(
                            "[•] %s (In Backpack)",
                            tostring(category)
                        )

                    label.TextColor3 =
                        Color3.fromRGB(
                            255,
                            220,
                            90
                        )
                else
                    local live =
                        DHub.GlobalEggScanner
                        and DHub.GlobalEggScanner:
                            GetBestByCategory(
                                category
                            )

                    if live then
                        label.Text =
                            string.format(
                                "[ ] %s (In World)",
                                tostring(category)
                            )

                        label.TextColor3 =
                            Color3.fromRGB(
                                255,
                                220,
                                90
                            )
                    else
                        label.Text =
                            string.format(
                                "[ ] %s (Waiting Egg Spawn)",
                                tostring(category)
                            )

                        label.TextColor3 =
                            Color3.fromRGB(
                                237,
                                232,
                                255
                            )
                    end
                end
            else
                label.Text =
                    string.format(
                        "[?] %s (Slot state unknown)",
                        tostring(category)
                    )

                label.TextColor3 =
                    Color3.fromRGB(
                        180,
                        180,
                        195
                    )
            end
        end
    end
end

local function freshScrambleRefresh()
    local remote =
        RMT
        and RMT.ScrambleTradeAskState

    if not remote
        or not remote:IsA(
            "RemoteFunction"
        )
    then
        dhub.State.scramble.lastError =
            "AskState missing"

        freshUpdateScrambleUi()
        return nil
    end

    local ok, state =
        pcall(function()
            return remote:InvokeServer()
        end)

    if not ok
        or type(state) ~= "table"
    then
        dhub.State.scramble.lastError =
            "AskState failed"

        freshUpdateScrambleUi()
        return nil
    end

    local requirements = {}

    if type(state.Requirements)
        == "table"
    then
        for i, category
            in ipairs(
                state.Requirements
            )
        do
            requirements[i] =
                tostring(category)
        end
    end

    local slots = {
        freshScrambleSlotState(1),
        freshScrambleSlotState(2),
        freshScrambleSlotState(3),
    }

    local signature =
        freshRequirementSignature(
            requirements,
            slots,
            state
        )

    if signature
        ~= dhub.State.scramble.signature
    then
        dhub.State.scramble.signature =
            signature

        dhub.State.scramble.revision =
            dhub.State.scramble.revision
            + 1

        freshWake()
    end

    dhub.State.scramble.state =
        state

    dhub.State.scramble.requirements =
        requirements

    dhub.State.scramble.slots =
        slots

    dhub.State.scramble.lastUpdateAt =
        tick()

    dhub.State.scramble.lastError =
        ""

    freshUpdateScrambleUi()

    return state
end

pcall(function()
    if RMT
        and RMT.ScrambleTradeAskRefresh
        and RMT.ScrambleTradeAskRefresh:IsA(
            "RemoteFunction"
        )
    then
        -- No active request here.
        -- Kept only as proof that the remote exists in donor scope.
    end
end)

-- -------------------- BOSS SCANNER --------------------

dhub.BossAskSnapshot =
    _pnet("RF/BossEvent/AskSnapshot")

local function freshBossRefresh()
    local oldOpen =
        dhub.State.boss.open

    local oldArena =
        dhub.State.boss.arena

    if dhub.BossAskSnapshot
        and dhub.BossAskSnapshot:IsA(
            "RemoteFunction"
        )
    then
        local ok, snap =
            pcall(function()
                return dhub.BossAskSnapshot:
                    InvokeServer()
            end)

        if ok
            and type(snap)
                == "table"
        then
            dhub.State.boss.open =
                snap.Open == true

            dhub.State.boss.opensAt =
                tonumber(
                    snap.OpensAt
                ) or 0

            dhub.State.boss.closesAt =
                tonumber(
                    snap.ClosesAt
                ) or 0
        end
    end

    dhub.State.boss.arena =
        S.Workspace:FindFirstChild(
            "ScrambleArena"
        )

    dhub.State.boss.lastUpdateAt =
        tick()

    if oldOpen ~= dhub.State.boss.open
        or oldArena
            ~= dhub.State.boss.arena
    then
        dhub.State.boss.revision =
            dhub.State.boss.revision
            + 1

        freshWake()
    end
end

-- -------------------- INVENTORY HELPERS --------------------

local function freshOwnedEggsRaw()
    local save = nil

    pcall(function()
        save =
            require(
                S.ReplicatedStorage
                    .Shared.Save
            ).Get()
    end)

    if save
        and type(save.EggInventory)
            == "table"
    then
        return save.EggInventory
    end

    local eggStateModule =
        DHub.EggStateService
        and DHub.EggStateService.module

    if eggStateModule
        and eggStateModule.ReadOwnedEggs
    then
        local result = nil

        pcall(function()
            result =
                eggStateModule
                    .ReadOwnedEggs()
        end)

        if type(result)
            == "table"
        then
            for _, owner
                in pairs(result)
            do
                if type(owner) == "table"
                    and tonumber(
                        owner.OwnerUserId
                    )
                        == tonumber(
                            LP.UserId
                        )
                    and type(
                        owner.Records
                    ) == "table"
                then
                    return owner.Records
                end
            end
        end
    end

    return {}
end

freshFindOwnedCategory = function(
    category,
    excluded
)
    -- Use the proven V3 inventory primitive first. It reads the authoritative
    -- unplaced Save.EggInventory and matches the exact Scramble requirement.
    if dhub.LegacyScrambleFuse
        and dhub.LegacyScrambleFuse.GetOwnedEgg
    then
        local ok, uid, record =
            pcall(
                dhub.LegacyScrambleFuse.GetOwnedEgg,
                category,
                excluded
            )

        if ok and uid then
            return tostring(uid), record
        end
    end

    -- Fallback for executors where the donor primitive cannot be called.
    for uid, record
        in pairs(
            freshOwnedEggsRaw()
        )
    do
        uid = tostring(uid)

        if type(record) == "table"
            and not record.Placement
            and not (
                excluded
                and excluded[uid]
            )
            and freshSameRequirement(
                record.AssetCategory,
                category
            )
        then
            return uid, record
        end
    end

    return nil, nil
end

local function freshCountOwnedCategory(
    category
)
    if dhub.LegacyScrambleFuse
        and dhub.LegacyScrambleFuse.CountOwnedRequiredEggs
    then
        local ok, count =
            pcall(
                dhub.LegacyScrambleFuse.CountOwnedRequiredEggs,
                category
            )

        if ok then
            return tonumber(count) or 0
        end
    end

    local count = 0

    for _, record
        in pairs(
            freshOwnedEggsRaw()
        )
    do
        if type(record) == "table"
            and not record.Placement
            and freshSameRequirement(
                record.AssetCategory,
                category
            )
        then
            count = count + 1
        end
    end

    return count
end

local function freshWaitOwnedIncrease(
    category,
    before,
    job,
    timeout
)
    local deadline =
        tick()
        + (
            tonumber(timeout)
            or 6
        )

    while freshJobAlive(job)
        and tick() < deadline
    do
        if freshCountOwnedCategory(
            category
        ) > before
        then
            return true
        end

        task.wait(0.08)
    end

    return false
end

-- -------------------- SCRAMBLE GUI ACTIONS --------------------

local function freshResolveGuiButton(
    instance,
    stopAt
)
    if not instance then
        return nil
    end

    if instance:IsA("GuiButton") then
        return instance
    end

    for _, child
        in ipairs(
            instance:GetDescendants()
        )
    do
        if child:IsA("GuiButton") then
            return child
        end
    end

    local current =
        instance.Parent

    while current
        and current ~= stopAt
    do
        if current:IsA("GuiButton") then
            return current
        end

        current =
            current.Parent
    end

    return nil
end

local function freshFireActivated(button)
    if not button
        or not button:IsA(
            "GuiButton"
        )
    then
        return false
    end

    if type(firesignal)
        == "function"
    then
        return pcall(function()
            firesignal(
                button.Activated
            )
        end)
    end

    return false
end

local function freshFindScramblePickerItem(
    inventory,
    category
)
    if not inventory then
        return nil
    end

    local scrolling =
        inventory:FindFirstChild(
            "ScrollingFrame",
            true
        )

    if not scrolling then
        return nil
    end

    for _, object
        in ipairs(
            scrolling:GetDescendants()
        )
    do
        if (
            object:IsA("TextLabel")
            or object:IsA("TextButton")
        )
            and object.Visible ~= false
            and freshSameRequirement(
                object.Text,
                category
            )
        then
            local button =
                freshResolveGuiButton(
                    object,
                    inventory
                )

            if button then
                return button
            end
        end
    end

    return nil
end

local function freshFuseAddOwned(
    job
)
    freshSetFusePhase(
        "Add "
        .. tostring(
            job.category
        )
    )

    freshUpdateScrambleUi()

    -- Verify that the exact requirement is still in the unplaced backpack
    -- immediately before the Add action.
    local currentUid =
        freshFindOwnedCategory(
            job.category
        )

    if not currentUid then
        freshScrambleRefresh()

        return false,
            "egg_not_in_backpack"
    end

    -- Prefer the original proven V3 picker primitive:
    -- it matches exact UID via Activated closure when possible, then category,
    -- then the first real filtered card. This is much more reliable than the
    -- simplified fresh picker that caused Auto Fuse to sit doing nothing.
    if dhub.LegacyScrambleFuse
        and dhub.LegacyScrambleFuse.AddEggToSlot
    then
        local ok, added =
            pcall(
                dhub.LegacyScrambleFuse.AddEggToSlot,
                job.slotIndex,
                job.category,
                tostring(currentUid)
            )

        if ok and added == true then
            freshSetFusePhase(
                "Added "
                .. tostring(
                    job.category
                )
            )

            task.wait(0.08)
            freshScrambleRefresh()
            freshUpdateScrambleUi()

            return true
        end
    end

    freshScrambleRefresh()

    return false,
        "add_to_machine_failed"
end

local function freshFuseSubmit(
    job
)
    freshSetFusePhase(
        "Sacrifice"
    )

    freshUpdateScrambleUi()

    local _, main =
        freshScrambleMainInventory()

    local raw =
        main
        and main:FindFirstChild(
            "Sacrifice",
            true
        )

    local button =
        freshResolveGuiButton(
            raw,
            main
        )

    if not button
        or button.Visible == false
    then
        return false,
            "sacrifice_button_missing"
    end

    if not freshFireActivated(
        button
    )
    then
        return false,
            "sacrifice_click_failed"
    end

    task.wait(0.35)
    freshScrambleRefresh()

    return true
end

local function freshFuseClaimReward(
    job
)
    freshSetFusePhase(
        "Claim Reward"
    )

    freshUpdateScrambleUi()

    local gui =
        freshScrambleGui()

    local clicked = false

    if gui then
        local keywords = {
            "finish",
            "continue",
            "claim",
            "collect",
            "next",
            "reveal",
        }

        for _, object
            in ipairs(
                gui:GetDescendants()
            )
        do
            if object:IsA(
                "GuiButton"
            )
                and object.Visible
                    ~= false
            then
                local probe =
                    tostring(
                        object.Name
                    ):lower()

                if object:IsA(
                    "TextButton"
                )
                then
                    probe =
                        probe
                        .. " "
                        .. tostring(
                            object.Text
                        ):lower()
                end

                for _, keyword
                    in ipairs(keywords)
                do
                    if probe:find(
                        keyword,
                        1,
                        true
                    )
                    then
                        clicked =
                            freshFireActivated(
                                object
                            )
                            or clicked

                        break
                    end
                end
            end
        end
    end

    if not clicked
        and RMT
        and RMT.ScrambleTradeAskFinishReveal
        and RMT.ScrambleTradeAskFinishReveal:IsA(
            "RemoteFunction"
        )
    then
        pcall(function()
            RMT.ScrambleTradeAskFinishReveal:
                InvokeServer()
        end)
    end

    task.wait(0.35)
    freshScrambleRefresh()

    return true
end

-- -------------------- NATURAL EGG TRANSACTION --------------------

local function freshRefreshTarget(
    target
)
    if not target then
        return nil
    end

    if DHub.GlobalEggScanner
        and DHub.GlobalEggScanner.RefreshTarget
    then
        local refreshed = nil

        pcall(function()
            refreshed =
                DHub.GlobalEggScanner:
                    RefreshTarget(target)
        end)

        if refreshed then
            return refreshed
        end
    end

    return target
end

local function freshRunNormalEgg(
    job,
    target,
    labelPrefix
)
    target =
        freshRefreshTarget(target)

    if not target
        or not target.uid
        or typeof(target.pos)
            ~= "Vector3"
    then
        return false,
            "target_missing"
    end

    local function active()
        return freshJobAlive(job)
            and (
                job.kind
                    ~= "MAIN_EGG"
                or Cfg.autoFarm == true
            )
            and (
                job.kind
                    ~= "FUSE_EGG"
                or EventCfg
                    .autoFuseScrambler
                    == true
            )
    end

    if isPlayerOnTreadmill()
        or (
            DHub.TreadmillMount
            and DHub.TreadmillMount.active
        )
    then
        -- treadmill release deferred until an actual Safezone route
        task.wait(0.10)
    end

    UpdateStatus(
        tostring(labelPrefix)
        .. ": Safezone first"
    )

    if not WalkToTarget(
        SAFEZONE_POS,
        5,
        false,
        active,
        {
            avoidPlayerTraps = true,
        }
    )
    then
        return false,
            "safezone_first_failed"
    end

    if not active() then
        return false,
            "stopped"
    end

    target =
        freshRefreshTarget(target)

    if not target then
        return false,
            "target_gone"
    end

    local lock = {
        target = target,
        lastKnownPos =
            target.pos,
        lostSince = nil,
    }

    UpdateStatus(
        tostring(labelPrefix)
        .. ": following "
        .. tostring(
            target.category
            or "Egg"
        )
    )

    forceUnequipTools()

    local reached =
        WalkToLockedEggRealtime(
            lock,
            4,
            true,
            function()
                return active()
                    and not isCarryingEgg()
            end
        )

    if not active() then
        return false,
            "stopped"
    end

    local pickupConfirmed =
        isCarryingEgg()

    if not pickupConfirmed then
        if not reached then
            return false,
                "walk_failed"
        end

        if not refreshLockedMainFarmTarget(
            lock
        )
        then
            return false,
                "target_lost"
        end

        UpdateStatus(
            tostring(labelPrefix)
            .. ": picking "
            .. tostring(
                lock.target.category
                or "Egg"
            )
        )

        pickupConfirmed =
            attemptPickup(
                lock.target,
                active,
                true
            ) == true
    end

    if not pickupConfirmed
        and not isCarryingEgg()
    then
        return false,
            "pickup_failed"
    end

    local deposited =
        mainFarmCarryEscapeLocked(
            lock,
            pickupConfirmed,
            active
        )

    if not deposited then
        return false,
            "deposit_failed"
    end

    Runtime.steals =
        (Runtime.steals or 0)
        + 1

    UpdateStatus(
        tostring(labelPrefix)
        .. ": secured"
    )

    return true
end

local function freshRunFastEgg(
    job,
    target,
    labelPrefix
)
    if not dhub.LegacyFastFarm
        or not dhub.LegacyFastFarm
            .FarmSpecificTarget
    then
        return false,
            "fast_primitive_missing"
    end

    local function active()
        return freshJobAlive(job)
            and Cfg.farmMethod
                == "Fast"
            and (
                job.kind
                    ~= "MAIN_EGG"
                or Cfg.autoFarm == true
            )
            and (
                job.kind
                    ~= "FUSE_EGG"
                or EventCfg
                    .autoFuseScrambler
                    == true
            )
    end

    if isPlayerOnTreadmill()
        or (
            DHub.TreadmillMount
            and DHub.TreadmillMount.active
        )
    then
        -- treadmill release deferred until an actual Safezone route
        task.wait(0.10)
    end

    local success,
        inventoryUid,
        verdict,
        reason =
        dhub.LegacyFastFarm
            .FarmSpecificTarget(
                target,
                active,
                function(message)
                    UpdateStatus(
                        tostring(labelPrefix)
                        .. ": "
                        .. tostring(message)
                    )
                end
            )

    return success == true,
        reason,
        inventoryUid,
        verdict
end

-- -------------------- BOSS TRANSACTION WRAPPER --------------------

local function freshRunBoss(
    job
)
    if not dhub.LegacyAutoBoss
        or not dhub.LegacyAutoBoss.Start
    then
        return false,
            "boss_primitive_missing"
    end

    if isPlayerOnTreadmill()
        or (
            DHub.TreadmillMount
            and DHub.TreadmillMount.active
        )
    then
        -- treadmill release deferred until an actual Safezone route
        task.wait(0.10)
    end

    local sawArena = false
    local startedAt = tick()

    pcall(function()
        dhub.LegacyAutoBoss.Start()
    end)

    while freshJobAlive(job)
        and EventCfg.autoBoss
        and tick() - startedAt < 240
    do
        local arena =
            S.Workspace:FindFirstChild(
                "ScrambleArena"
            )

        if arena then
            sawArena = true
        end

        freshBossRefresh()

        if sawArena
            and not arena
        then
            pcall(function()
                dhub.LegacyAutoBoss.Stop(true)
            end)

            return true
        end

        -- If the server closes the gate before an arena ever materializes,
        -- return control to the coordinator rather than owning an idle loop.
        if not sawArena
            and tick() - startedAt > 15
            and dhub.State.boss.open
                ~= true
            and not dhub.State.boss.arena
        then
            pcall(function()
                dhub.LegacyAutoBoss.Stop(true)
            end)

            return false,
                "boss_not_entered"
        end

        task.wait(0.10)
    end

    pcall(function()
        dhub.LegacyAutoBoss.Stop(true)
    end)

    return false,
        "boss_stopped"
end

-- -------------------- IDLE TREADMILL --------------------

local function freshFindTreadmill()
    local penInfo =
        findMyPlot()

    local treadmill =
        penInfo
        and penInfo.plot
        and penInfo.plot:FindFirstChild(
            "TreadmillBottom"
        )

    return treadmill
end

local freshPlannerPeek
local freshIdleAllowed

freshIdleAllowed =
    function()
        if not dhub.State.alive
            or not DHub.LongAFKRuntime.alive
            or not Cfg.autoTreadmill
            or not freshAnyAutomationEnabled()
            or dhub.State.currentJob
            or dhub.State.reset.active
            or isCarryingEgg()
            or PlotRuntime.placing
        then
            return false
        end

        return freshPlannerPeek()
            == nil
    end

DHub.IsIdleTreadmillAllowed =
    function()
        return freshIdleAllowed()
    end

local function freshRunIdle()
    if not Cfg.autoTreadmill
        or not freshAnyAutomationEnabled()
    then
        if DHub.MovementService
            and DHub.MovementService.currentOwner
                == "IdleTreadmill"
        then
            DHub.MovementService:Cancel(
                "IdleTreadmill"
            )
        end

        -- Auto Treadmill OFF means Safezone is the idle home.
        -- If the player is currently mounted, WalkToTarget(SAFEZONE_POS)
        -- performs the ONE allowed automatic release at route start.
        if freshAnyAutomationEnabled()
            and not dhub.State.currentJob
            and not dhub.State.reset.active
            and not isCarryingEgg()
        then
            local root =
                getRoot()

            local inSafezone =
                root
                and (
                    root.Position
                    - SAFEZONE_POS
                ).Magnitude <= 7
                or false

            if not inSafezone then
                UpdateStatus(
                    "Idle -> Safezone"
                )

                WalkToTarget(
                    SAFEZONE_POS,
                    5,
                    false,
                    function()
                        return dhub.State.alive
                            and DHub.LongAFKRuntime.alive
                            and Cfg.autoTreadmill
                                ~= true
                            and freshAnyAutomationEnabled()
                            and not dhub.State.currentJob
                            and not dhub.State.reset.active
                            and not isCarryingEgg()
                            and freshPlannerPeek()
                                == nil
                    end
                )
            else
                UpdateStatus(
                    "Idle | Safezone"
                )
            end
        else
            UpdateStatus(
                "Idle"
            )
        end

        return
    end

    local treadmill =
        freshFindTreadmill()

    if not treadmill then
        UpdateStatus(
            "Idle | Treadmill unavailable"
        )

        return
    end

    if not freshIdleAllowed() then
        return
    end

    if not (
        DHub.TreadmillMount
        and DHub.TreadmillMount.active
    )
    then
        if isPlayerOnTreadmill()
            ~= true
        then
            UpdateStatus(
                "Idle -> Treadmill"
            )

            WalkToTarget(
                treadmill.Position
                    + Vector3.new(
                        0,
                        2.25,
                        0
                    ),
                3.25,
                false,
                freshIdleAllowed,
                {
                    allowTreadmill = true,
                }
            )
        end

        if freshIdleAllowed()
            and DHub.TreadmillMount
        then
            DHub.TreadmillMount:
                TryMount()
        end
    end

    if DHub.TreadmillMount
        and DHub.TreadmillMount.active
    then
        dhub.State.idleMounted =
            true

        UpdateStatus(
            "Idle | Treadmill ACTIVE"
        )
    end
end

local function freshLeaveIdle()
    dhub.State.idleMounted =
        false

    if DHub.MovementService
        and DHub.MovementService.currentOwner
            == "IdleTreadmill"
    then
        DHub.MovementService:Cancel(
            "IdleTreadmill"
        )
    end

    -- IMPORTANT:
    -- Do NOT release the treadmill merely because a job was selected.
    -- Egg/Reset/Boss/Fuse world jobs all stage through Safezone; the release
    -- happens once, at the actual Safezone route entry.
end


-- -------------------- JOB PLANNER --------------------

local function freshFuseLocalJob()
    if EventCfg.autoFuseScrambler
        ~= true
    then
        return nil
    end

    if tick()
        < (
            tonumber(
                dhub.State.scramble.localRetryAt
            ) or 0
        )
    then
        return nil
    end

    local state =
        dhub.State.scramble.state

    local requirements =
        dhub.State.scramble.requirements

    local slots =
        dhub.State.scramble.slots

    if type(state) ~= "table"
        or #requirements == 0
    then
        return nil
    end

    if state.PendingReward
        == true
    then
        return {
            kind =
                "FUSE_REWARD",
        }
    end

    local allKnown = true
    local allFull = true

    for i = 1,
        math.min(
            3,
            #requirements
        )
    do
        if slots[i] == nil then
            allKnown = false
            allFull = false
        elseif slots[i]
            ~= true
        then
            allFull = false
        end
    end

    -- Do not guess Full/Empty while the Lab GUI state is not available.
    if not allKnown then
        return nil
    end

    if allFull
        and #requirements >= 3
    then
        return {
            kind =
                "FUSE_SUBMIT",
        }
    end

    local excluded = {}

    for i, category
        in ipairs(
            requirements
        )
    do
        if slots[i]
            ~= true
        then
            local uid =
                freshFindOwnedCategory(
                    category,
                    excluded
                )

            if uid then
                excluded[uid] = true

                return {
                    kind =
                        "FUSE_ADD",
                    slotIndex = i,
                    category =
                        category,
                    uid = uid,
                }
            end
        end
    end

    return nil
end

local function freshFuseLiveJob()
    if EventCfg.autoFuseScrambler
        ~= true
    then
        return nil
    end

    local requirements =
        dhub.State.scramble.requirements

    local slots =
        dhub.State.scramble.slots

    if #requirements == 0 then
        return nil
    end

    for i, category
        in ipairs(
            requirements
        )
    do
        if slots[i] == nil then
            return nil
        end

        if slots[i]
            ~= true
        then
            local owned =
                freshFindOwnedCategory(
                    category
                )

            if not owned then
                local target =
                    DHub.GlobalEggScanner
                    and DHub.GlobalEggScanner:
                        GetBestByCategory(
                            category
                        )

                if target then
                    return {
                        kind =
                            "FUSE_EGG",
                        slotIndex = i,
                        category =
                            category,
                        target = target,
                    }
                end
            end
        end
    end

    return nil
end

freshPlannerPeek =
    function()
        if dhub.State.reset.active then
            return {
                kind = "RESET",
                epoch =
                    dhub.State.reset.epoch,
            }
        end

        if isCarryingEgg() then
            return {
                kind =
                    "CARRY_RECOVERY",
            }
        end

        if EventCfg.autoBoss
            and (
                dhub.State.boss.open
                or dhub.State.boss.arena
                    ~= nil
            )
        then
            return {
                kind = "BOSS",
            }
        end

        local fuseLocal =
            freshFuseLocalJob()

        if fuseLocal then
            return fuseLocal
        end

        if Cfg.autoFarm then
            local target =
                DHub.TargetSelector
                and DHub.TargetSelector:
                    GetBestFarmTarget()

            if target
                and target.uid
            then
                return {
                    kind =
                        "MAIN_EGG",
                    method =
                        Cfg.farmMethod,
                    target =
                        target,
                }
            end
        end

        local fuseLive =
            freshFuseLiveJob()

        if fuseLive then
            return fuseLive
        end

        -- Preserve original V3 Auto Plot behavior:
        -- only run it when no selected farm/fuse world target is actionable.
        if Cfg.autoFarm
            and PlotCfg.autoPlace
            and PlotRuntime.HasFarmPlaceableEgg
            and PlotRuntime.HasFarmPlaceableEgg(false)
        then
            return {
                kind = "PLOT",
            }
        end

        return nil
    end

-- -------------------- JOB EXECUTION --------------------

local function freshResetJob(
    job
)
    freshLeaveIdle()

    UpdateStatus(
        "Reset -> Safezone"
    )

    local root =
        getRoot()

    if not root
        or (
            root.Position
            - SAFEZONE_POS
        ).Magnitude > 7
    then
        WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            function()
                return freshJobAlive(job)
                    and dhub.State.reset.active
            end
        )
    end

    UpdateStatus(
        "Reset -> waiting open"
    )

    while freshJobAlive(job)
        and dhub.State.reset.active
    do
        S.RunService.Heartbeat:
            Wait()
    end

    pcall(function()
        DHub.GlobalEggScanner:
            Resync()
    end)

    task.defer(
        freshScrambleRefresh
    )

    return true
end

local function freshCarryRecoveryJob(
    job
)
    freshLeaveIdle()

    UpdateStatus(
        "Carry recovery -> Safezone"
    )

    local ok = false

    pcall(function()
        ok =
            mainFarmCarryEscapeLocked(
                nil,
                true,
                function()
                    return freshJobAlive(job)
                end
            ) == true
    end)

    if ok then
        return true
    end

    local moved =
        WalkToTarget(
            SAFEZONE_POS,
            5,
            false,
            function()
                return freshJobAlive(job)
            end
        )

    if moved then
        forceUnequipTools()
        task.wait(0.08)
        forceUnequipTools()
    end

    return moved == true
end

local function freshMainEggJob(
    job
)
    freshLeaveIdle()

    -- MAIN FARM now uses the same transaction lifecycle as FUSE_EGG:
    -- 1) snapshot owned count for this exact category
    -- 2) run the SAME Normal/Fast egg transaction
    -- 3) do not release the job immediately after Safezone/deposit
    -- 4) wait until the backpack/inventory actually confirms +1 egg
    --
    -- This removes the old MAIN-only gap where the planner could start the
    -- next egg cycle before the previous redeem/inventory replication settled.
    local target =
        freshRefreshTarget(
            job.target
        )

    if not target
        or not target.uid
    then
        return false,
            "target_missing"
    end

    job.target =
        target

    local category =
        tostring(
            target.category
            or (
                type(target.raw) == "table"
                and target.raw.AssetCategory
            )
            or ""
        )

    if category == "" then
        category =
            tostring(
                target.uid
                or "Egg"
            )
    end

    local before =
        freshCountOwnedCategory(
            category
        )

    local ok, reason

    if job.method == "Fast" then
        ok, reason =
            freshRunFastEgg(
                job,
                target,
                "FAST"
            )
    else
        ok, reason =
            freshRunNormalEgg(
                job,
                target,
                "NORMAL"
            )
    end

    if not ok then
        return false,
            reason
    end

    UpdateStatus(
        "MAIN: confirming inventory "
        .. category
    )

    -- Same authoritative post-farm barrier used by Auto Fuse Scrambler.
    -- The job remains the owner until the newly redeemed egg is actually
    -- visible in owned inventory, preventing the next planner cycle from
    -- colliding with the tail of the previous carry/drop/redeem sequence.
    local got =
        freshWaitOwnedIncrease(
            category,
            before,
            job,
            5
        )

    if not got then
        return false,
            "inventory_not_updated"
    end

    UpdateStatus(
        "MAIN: secured "
        .. category
    )

    return true, nil
end

local function freshFuseEggJob(
    job
)
    freshLeaveIdle()

    freshSetFusePhase(
        "Farm "
        .. tostring(
            job.category
        )
    )

    freshUpdateScrambleUi()

    local before =
        freshCountOwnedCategory(
            job.category
        )

    local ok, reason

    if Cfg.farmMethod
        == "Fast"
    then
        ok, reason =
            freshRunFastEgg(
                job,
                job.target,
                "FUSE"
            )
    else
        ok, reason =
            freshRunNormalEgg(
                job,
                job.target,
                "FUSE"
            )
    end

    if not ok then
        return false, reason
    end

    freshSetFusePhase(
        "Confirm "
        .. tostring(
            job.category
        )
    )

    freshUpdateScrambleUi()

    local got =
        freshWaitOwnedIncrease(
            job.category,
            before,
            job,
            5
        )

    task.defer(
        freshScrambleRefresh
    )

    return got,
        got
            and nil
            or "inventory_not_updated"
end

local function freshBossJob(
    job
)
    freshLeaveIdle()

    UpdateStatus(
        "BOSS -> Safezone / Arena"
    )

    return freshRunBoss(job)
end

local function freshExecuteJob(
    job
)
    dhub.State.currentJobId =
        dhub.State.currentJobId
        + 1

    job.id =
        tostring(job.kind)
        .. ":"
        .. tostring(
            dhub.State.currentJobId
        )

    dhub.State.currentJob =
        job

    dhub.State.currentJobKind =
        job.kind

    DHub.FarmCoordinator:
        SetState(
            tostring(job.kind)
        )

    local ok = false
    local reason = nil

    if job.kind == "RESET" then
        ok, reason =
            freshResetJob(job)

    elseif job.kind
        == "CARRY_RECOVERY"
    then
        ok, reason =
            freshCarryRecoveryJob(
                job
            )

    elseif job.kind
        == "MAIN_EGG"
    then
        pcall(function()
            DHub.FarmCoordinator:
                LockTarget(
                    "Fresh",
                    job.target
                )
        end)

        ok, reason =
            freshMainEggJob(
                job
            )

        pcall(function()
            DHub.FarmCoordinator:
                ClearTarget(
                    job.target
                    and job.target.uid
                )
        end)

    elseif job.kind
        == "FUSE_EGG"
    then
        ok, reason =
            freshFuseEggJob(
                job
            )

    elseif job.kind
        == "FUSE_ADD"
    then
        -- Pure GUI/local transaction: keep treadmill mounted.
        ok, reason =
            freshFuseAddOwned(
                job
            )

        dhub.State.scramble.localRetryAt =
            ok
            and 0
            or (tick() + 0.65)

    elseif job.kind
        == "FUSE_SUBMIT"
    then
        -- Pure GUI/local transaction: keep treadmill mounted.
        ok, reason =
            freshFuseSubmit(
                job
            )

    elseif job.kind
        == "FUSE_REWARD"
    then
        -- Pure GUI/local transaction: keep treadmill mounted.
        ok, reason =
            freshFuseClaimReward(
                job
            )

    elseif job.kind
        == "BOSS"
    then
        ok, reason =
            freshBossJob(
                job
            )

    elseif job.kind
        == "PLOT"
    then
        freshLeaveIdle()

        local placed,
            plotReason =
            PlotRuntime.RunFarmPlotPriority(
                "FRESH"
            )

        ok = placed == true
            or plotReason == "none"
            or plotReason == "farm_target"

        reason =
            ok
            and nil
            or plotReason
    end

    if DHub.MovementService then
        pcall(function()
            DHub.MovementService:Cancel(
                "MainFarm"
            )
        end)

        pcall(function()
            DHub.MovementService:Cancel(
                "Fuse"
            )
        end)
    end

    dhub.State.currentJob =
        nil

    dhub.State.currentJobKind =
        "IDLE"

    DHub.FarmCoordinator:
        SetState("Idle")

    if job.kind:find(
        "FUSE",
        1,
        true
    )
    then
        freshSetFusePhase(
            ok
            and "Idle"
            or (
                "Retry "
                .. tostring(
                    reason
                    or "failed"
                )
            )
        )

        freshUpdateScrambleUi()
    end

    freshWake()

    return ok, reason
end

local function freshWaitWake(
    seconds
)
    local gate =
        Instance.new(
            "BindableEvent"
        )

    local done = false
    local conn = nil

    conn =
        dhub.WakeEvent.Event:
            Connect(function()
                if not done then
                    done = true
                    gate:Fire()
                end
            end)

    task.delay(
        tonumber(seconds)
            or 0.30,
        function()
            if not done then
                done = true
                gate:Fire()
            end
        end
    )

    gate.Event:Wait()

    if conn then
        conn:Disconnect()
    end

    gate:Destroy()
end

local function freshCoordinatorLoop()
    if dhub.State.started then
        return
    end

    dhub.State.started = true

    while dhub.State.alive
        and DHub.LongAFKRuntime.alive
    do
        freshResetRead()

        local job =
            freshPlannerPeek()

        if job then
            freshExecuteJob(
                job
            )

            task.wait(0.04)
        else
            dhub.State.currentJobKind =
                "IDLE"

            DHub.FarmCoordinator:
                SetState("Idle")

            freshRunIdle()
            freshWaitWake(0.25)
        end
    end

    dhub.State.started = false
end

-- -------------------- COMPATIBILITY WRAPPERS FOR ORIGINAL UI --------------------

dhub.FuseRuntime =
    dhub.LegacyScrambleFuse
    and dhub.LegacyScrambleFuse.Runtime
    or {
        running = false,
        statusLabel = nil,
        slotLabels = {},
    }

DHub.ScrambleFuse = {
    Runtime =
        dhub.FuseRuntime,

    Start =
        function()
            dhub.FuseRuntime.running =
                EventCfg.autoFuseScrambler
                    == true

            freshWake()
            freshScrambleRefresh()
        end,

    Stop =
        function()
            dhub.FuseRuntime.running =
                false

            freshSetFusePhase("Idle")
            freshUpdateScrambleUi()
            freshWake()
        end,

    RefreshState =
        function()
            return freshScrambleRefresh()
        end,

    UpdateSlots =
        function()
            freshUpdateScrambleUi()
            return dhub.State.scramble.slots
        end,
}

DHub.AutoBoss = {
    State =
        dhub.LegacyAutoBoss
        and dhub.LegacyAutoBoss.State
        or {},

    Start =
        function()
            freshBossRefresh()
            freshWake()
        end,

    Stop =
        function(fromCleanup)
            if dhub.LegacyAutoBoss
                and dhub.LegacyAutoBoss.Stop
            then
                pcall(
                    dhub.LegacyAutoBoss.Stop,
                    fromCleanup == true
                )
            end

            freshWake()
        end,
}

-- UI Auto Farm compatibility:
-- Runtime.farming remains only a UI/lifecycle marker; the actual worker is
-- the single fresh coordinator above.
doFarmLoop = function()
    if Runtime.farming then
        return
    end

    Runtime.farming = true

    dhub.State.autoFarmWatcherGeneration =
        dhub.State.autoFarmWatcherGeneration
        + 1

    local generation =
        dhub.State.autoFarmWatcherGeneration

    freshWake()

    while DHub.LongAFKRuntime.alive
        and Cfg.autoFarm
        and generation
            == dhub.State.autoFarmWatcherGeneration
    do
        task.wait(0.10)
    end

    if generation
        == dhub.State.autoFarmWatcherGeneration
    then
        Runtime.farming =
            false
    end
end

Runtime.FastFarmStart =
    function()
        if not Cfg.autoFarm then
            return
        end

        if Runtime.farming then
            freshWake()
            return
        end

        task.spawn(
            doFarmLoop
        )
end

Runtime.FastFarmStop =
    function()
        dhub.State.autoFarmWatcherGeneration =
            dhub.State.autoFarmWatcherGeneration
            + 1

        Runtime.farming =
            false

        if dhub.LegacyFastFarm
            and dhub.LegacyFastFarm.Stop
        then
            pcall(
                dhub.LegacyFastFarm.Stop
            )
        end

        freshWake()
    end

-- Fuse calls the exact same Fresh target transaction instead of launching
-- the legacy Fuse worker.
Runtime.FastFarmCarrySpecificTarget =
    function(
        target,
        shouldContinue,
        statusCallback
    )
        if Cfg.farmMethod
            ~= "Fast"
    then
        return false,
            nil,
            nil,
            "not_fast"
    end

        return dhub.LegacyFastFarm
            .FarmSpecificTarget(
                target,
                shouldContinue,
                statusCallback
            )
    end

-- Standalone scanners stay alive regardless of Auto Farm / Auto Fuse toggles.
task.spawn(function()
    while dhub.State.alive
        and DHub.LongAFKRuntime.alive
    do
        pcall(
            freshScrambleRefresh
        )

        task.wait(0.75)
    end
end)

task.spawn(function()
    while dhub.State.alive
        and DHub.LongAFKRuntime.alive
    do
        pcall(
            freshBossRefresh
        )

        task.wait(0.50)
    end
end)

task.spawn(function()
    while dhub.State.alive
        and DHub.LongAFKRuntime.alive
    do
        pcall(
            freshResetRead
        )

        task.wait(0.50)
    end
end)

task.spawn(
    freshCoordinatorLoop
)

dhubBootEnv.DHubV3BootStage = "FRESH_ENGINE_READY"


-- Make cleanup stop only the fresh coordinator in addition to original
-- D-HUB cleanup.
dhub.OldCleanup =
    _G[_ENV_GUARD]

_G[_ENV_GUARD] =
    function()
        dhub.State.alive =
            false

        dhub.WakeEvent:Fire()

        pcall(function()
            if dhub.LegacyAutoBoss
                and dhub.LegacyAutoBoss.Stop
            then
                dhub.LegacyAutoBoss.Stop(true)
            end
        end)

        pcall(function()
            -- treadmill release deferred until an actual Safezone route
        end)

        pcall(function()
            dhub.WakeEvent:Destroy()
        end)

        if type(dhub.OldCleanup)
            == "function"
        then
            pcall(
                dhub.OldCleanup
            )
        end
    end


end)()

Notify = function(text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title="D-Hub V3.0", Text=tostring(text), Duration=dur or 3
        })
    end)
end

local antiStunConn = S.RunService.Heartbeat:Connect(function()
    local now=tick()

    if now-(Runtime.lastAntiStunAt or 0)<0.10 then
        return
    end

    Runtime.lastAntiStunAt=now

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                if hum.PlatformStand then hum.PlatformStand = false end
            end)
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)
table.insert(ScriptConnections, antiStunConn)

local C = {
    BASE     = Color3.fromRGB(10,12,27),
    SURFACE  = Color3.fromRGB(17,20,42),
    ELEVATED = Color3.fromRGB(27,29,58),
    BORDER   = Color3.fromRGB(51,54,93),
    DIVIDER  = Color3.fromRGB(31,34,66),
    TEXT_1   = Color3.fromRGB(240,241,255),
    TEXT_2   = Color3.fromRGB(174,177,215),
    TEXT_3   = Color3.fromRGB(108,111,157),
    ACCENT   = Color3.fromRGB(150,88,255),
    ACCENT_D = Color3.fromRGB(88,56,166),
    GREEN    = Color3.fromRGB(70,190,128),
    DANGER   = Color3.fromRGB(205,91,128),
}
local UI = {activeDD = nil}
local TS = S.TweenService

-- ============================================================
-- LIGHTWEIGHT LUCIDE ICON LAYER
--
-- UI size/layout is NOT driven by icon size.
-- Each control decides its own 18-24px icon box.
--
-- Performance strategy:
--   1. UI renders immediately with a tiny text fallback.
--   2. Lucide library loads asynchronously once.
--   3. Each UNIQUE icon is generated once, then cached.
--   4. All rows using the same icon reuse the cached asset.
--   5. If Lucide/custom asset fails, fallback stays visible.
-- ============================================================

UI.lucide = nil
UI.lucideLoadStarted = false
UI.lucideLoaded = false
UI.lucideLoading = false
UI.lucideRetryCount = 0

UI.iconCache = {}
UI.iconPending = {}
UI.iconResolving = {}

-- Persistent subscribers let already-rendered fallback icons upgrade
-- automatically when Lucide finally becomes available on a later retry.
UI.iconSubscribers = {}
UI.iconRetryCount = {}

local LUCIDE_SOURCE_URL =
    "https://raw.githubusercontent.com/xxpwnxxx420lord/Lucide.Lua/refs/heads/main/lucide.lua"

local UI_ICON = {
    Auto = "sprout",
    Plot = "map-pin",
    Shop = "shopping-cart",
    Event = "zap",
    Misc = "settings",
    Info = "info",
}

local CONTROL_ICON = {
    ["Select Method"] = "route",
    ["Select Area"] = "map-pin",
    ["Select Rarity"] = "gem",
    ["Min Weight"] = "scale",
    ["Farm Priority"] = "list-filter",
    ["Instant Steal (0s Prompt)"] = "zap",
    ["Auto Farm Eggs"] = "star",
    ["Anti Boss"] = "shield",
    ["Auto Treadmill (When Waiting)"] = "activity",
    ["Movement Speed (FAST only)"] = "gauge",
    ["Reset Steal Counter"] = "rotate-ccw",
    ["Force Re-Scan"] = "refresh-cw",

    ["Rarity To Place"] = "gem",
    ["Min Weight To Place"] = "scale",
    ["Auto Place Eggs"] = "map-pin",
    ["Auto Hatch Eggs"] = "egg",
    ["Best Pet Delay (Minutes)"] = "clock-3",
    ["Auto Best Pet"] = "sparkles",
    ["Place Eggs Now"] = "package-plus",
    ["Reset Placed Counter"] = "rotate-ccw",

    ["Egg Rarity to Sell"] = "egg",
    ["Pet Rarity to Sell"] = "paw-print",
    ["Auto Sell By Rarity"] = "shopping-bag",
    ["Sell Now"] = "coins",
    ["Auto Upgrade Plot"] = "trending-up",
    ["Auto Upgrade Treadmill"] = "trending-up",
    ["Select Pet To Fuse"] = "combine",
    ["Fuse Pet"] = "combine",

    ["Auto Boss"] = "swords",
    ["Auto Fuse Scrambler"] = "combine",
    ["Egg Rarity"] = "gem",
    ["Auto Consumable"] = "flask-conical",
    ["Items To Buy"] = "shopping-cart",
    ["Auto Buy Event Shop"] = "shopping-bag",
}

local ICON_FALLBACK = {
    ["sprout"] = "✦",
    ["map-pin"] = "⌖",
    ["shopping-cart"] = "▣",
    ["zap"] = "⚡",
    ["settings"] = "⚙",
    ["info"] = "ⓘ",
    ["route"] = "↯",
    ["gem"] = "◇",
    ["scale"] = "↓",
    ["list-filter"] = "≡",
    ["star"] = "☆",
    ["shield"] = "◉",
    ["activity"] = "↝",
    ["gauge"] = "»",
    ["rotate-ccw"] = "↺",
    ["refresh-cw"] = "↻",
    ["egg"] = "◌",
    ["clock-3"] = "◷",
    ["sparkles"] = "✦",
    ["package-plus"] = "＋",
    ["paw-print"] = "•",
    ["shopping-bag"] = "▣",
    ["coins"] = "$",
    ["trending-up"] = "↑",
    ["combine"] = "∞",
    ["radio-tower"] = "≋",
    ["swords"] = "⚔",
    ["flask-conical"] = "✚",
    ["atom"] = "◎",
}

local function getControlIcon(label)
    local exact = CONTROL_ICON[label]
    if exact then
        return exact
    end

    local s = tostring(label or ""):lower()

    if s:find("rarity") then return "gem" end
    if s:find("weight") then return "scale" end
    if s:find("area") then return "map-pin" end
    if s:find("speed") then return "gauge" end
    if s:find("refresh") or s:find("scan") then return "refresh-cw" end
    if s:find("reset") then return "rotate-ccw" end
    if s:find("sell") or s:find("buy") or s:find("shop") then return "shopping-cart" end
    if s:find("fuse") then return "combine" end
    if s:find("auto") then return "sparkles" end

    return "sparkles"
end

local CONTROL_DESC = {
    ["Select Method"] = "Choose Normal or Fast movement",
    ["Select Area"] = "Choose biomes to search for eggs",
    ["Select Rarity"] = "Filter eggs by selected rarities",
    ["Min Weight"] = "Ignore eggs below this weight",
    ["Farm Priority"] = "Choose which valid egg comes first",
    ["Instant Steal (0s Prompt)"] = "Trigger supported prompts instantly",
    ["Auto Farm Eggs"] = "Find, steal and deliver eggs automatically",
    ["Anti Boss"] = "Protect the farm flow from boss interruptions",
    ["Auto Treadmill (When Waiting)"] = "Use treadmill while waiting for eggs",
    ["Movement Speed (FAST only)"] = "FAST movement speed only; Normal uses native game speed",
    ["Reset Steal Counter"] = "Reset the current session steal count",
    ["Force Re-Scan"] = "Refresh the global egg scanner now",

    ["Rarity To Place"] = "Choose egg rarities allowed to place",
    ["Min Weight To Place"] = "Only place eggs above this weight",
    ["Auto Place Eggs"] = "Place eligible backpack eggs automatically",
    ["Auto Hatch Eggs"] = "Hatch ready eggs automatically",
    ["Best Pet Delay (Minutes)"] = "Delay between automatic pet checks",
    ["Auto Best Pet"] = "Equip the strongest available pet",
    ["Place Eggs Now"] = "Run one manual egg placement cycle",
    ["Reset Placed Counter"] = "Reset the current placed egg count",

    ["Egg Rarity to Sell"] = "Choose egg rarities allowed to sell",
    ["Pet Rarity to Sell"] = "Choose pet rarities allowed to sell",
    ["Auto Sell By Rarity"] = "Sell using the selected rarity filters",
    ["Sell Now"] = "Run one manual sell cycle",
    ["Auto Upgrade Plot"] = "Buy available plot upgrades automatically",
    ["Auto Upgrade Treadmill"] = "Buy treadmill upgrades automatically",
    ["Select Pet To Fuse"] = "Choose the pet category used for fuse",
    ["Fuse Pet"] = "Fuse the selected pet category automatically",

    ["Auto Boss"] = "Enter Dr. Scramble arena and clear every boss phase automatically",
    ["Auto Fuse Scrambler"] = "Farm the three required Lab eggs and submit them automatically",
    ["Egg Rarity"] = "Choose eggs allowed for consumable use",
    ["Auto Consumable"] = "Apply Scrambled consumables automatically",
    ["Items To Buy"] = "Choose event shop items to purchase",
    ["Auto Buy Event Shop"] = "Buy selected event items automatically",

    ["FPS Boost"] = "Reduce visual effects for better performance",
    ["Ultra FPS Boost (HARD PURGE)"] = "Use the strongest performance cleanup",
    ["Select Delay Hop (Minutes)"] = "Set delay before automatic server hop",
    ["Hop Method"] = "Choose how the next server is selected",
    ["Auto Hop Server"] = "Hop servers automatically when enabled",
    ["Hop Now"] = "Move to another server immediately",
    ["Refresh Small Server List"] = "Refresh available low-player servers",
}

local function getControlDescription(label)
    return CONTROL_DESC[label]
        or "Configure this feature"
end


local resolveLucideIcon
local startLucideLoader

local function notifyIconSubscribers(name, asset)
    local subscribers = UI.iconSubscribers[name]

    if type(subscribers) ~= "table" then
        return
    end

    local alive = {}

    for _, cb in ipairs(subscribers) do
        if type(cb) == "function" then
            local ok = pcall(cb, asset)

            -- Keep subscriber for future refreshes only while callback
            -- still executes successfully.
            if ok then
                table.insert(alive, cb)
            end
        end
    end

    UI.iconSubscribers[name] = alive
end

local function scheduleIconRetry(name)
    if UI.iconCache[name] then
        return
    end

    local count =
        (UI.iconRetryCount[name] or 0) + 1

    UI.iconRetryCount[name] = count

    -- 1.5s -> 3s -> 6s -> 12s -> 20s cap.
    -- After the cap it keeps retrying every 20 seconds until success.
    local delaySeconds =
        math.min(
            1.5 * (2 ^ math.max(count - 1, 0)),
            20
        )

    task.delay(delaySeconds, function()
        if UI.iconCache[name]
            or UI.iconResolving[name]
        then
            return
        end

        if UI.lucideLoaded and UI.lucide then
            resolveLucideIcon(name)
        else
            startLucideLoader()
        end
    end)
end

resolveLucideIcon = function(name)
    name = tostring(name or "sparkles")

    local cached = UI.iconCache[name]

    if type(cached) == "string"
        and cached ~= ""
    then
        notifyIconSubscribers(name, cached)
        return
    end

    if UI.iconResolving[name] then
        return
    end

    if not UI.lucideLoaded
        or not UI.lucide
    then
        startLucideLoader()
        return
    end

    UI.iconResolving[name] = true

    task.spawn(function()
        local asset = nil

        if UI.lucide
            and type(UI.lucide.geticon) == "function"
        then
            local ok, result = pcall(function()
                return UI.lucide:geticon(
                    name,
                    {
                        size = 28,
                        color = "#FFFFFF",
                        stroke_width = 1.65,
                    }
                )
            end)

            if ok
                and type(result) == "string"
                and result ~= ""
            then
                asset = result
            end
        end

        UI.iconResolving[name] = nil

        if asset then
            UI.iconCache[name] = asset
            UI.iconRetryCount[name] = 0
            notifyIconSubscribers(name, asset)
        else
            -- IMPORTANT:
            -- Do NOT cache a failed icon as false.
            -- Keeping the cache empty allows later retries to upgrade
            -- all fallback icons automatically.
            UI.iconCache[name] = nil
            scheduleIconRetry(name)
        end
    end)
end

startLucideLoader = function()
    if UI.lucideLoaded
        and UI.lucide
    then
        return
    end

    if UI.lucideLoading then
        return
    end

    UI.lucideLoadStarted = true
    UI.lucideLoading = true

    task.spawn(function()
        local lib = nil

        pcall(function()
            if type(loadstring) ~= "function" then
                return
            end

            local source =
                game:HttpGet(
                    LUCIDE_SOURCE_URL,
                    true
                )

            if type(source) ~= "string"
                or source == ""
            then
                return
            end

            local chunk = loadstring(source)

            if type(chunk) ~= "function" then
                return
            end

            local result = chunk()

            if type(result) == "table"
                and type(result.geticon) == "function"
            then
                lib = result
            end
        end)

        UI.lucideLoading = false

        if lib then
            UI.lucide = lib
            UI.lucideLoaded = true
            UI.lucideRetryCount = 0

            -- Retry every icon currently visible in the UI.
            for name in pairs(UI.iconSubscribers) do
                if not UI.iconCache[name] then
                    resolveLucideIcon(name)
                else
                    notifyIconSubscribers(
                        name,
                        UI.iconCache[name]
                    )
                end
            end

            return
        end

        UI.lucide = nil
        UI.lucideLoaded = false
        UI.lucideRetryCount =
            UI.lucideRetryCount + 1

        -- 2s -> 4s -> 8s -> 15s cap, then keep retrying.
        local retryDelay =
            math.min(
                2 ^ math.min(UI.lucideRetryCount, 4),
                15
            )

        task.delay(retryDelay, function()
            -- Only keep retrying if at least one UI icon still needs Lucide.
            if next(UI.iconSubscribers) ~= nil
                and not UI.lucideLoaded
            then
                startLucideLoader()
            end
        end)
    end)
end

local function requestLucideIcon(name, callback)
    name = tostring(name or "sparkles")

    UI.iconSubscribers[name] =
        UI.iconSubscribers[name] or {}

    table.insert(
        UI.iconSubscribers[name],
        callback
    )

    local cached = UI.iconCache[name]

    if type(cached) == "string"
        and cached ~= ""
    then
        task.defer(callback, cached)
        return
    end

    -- Show fallback immediately; resolve/loader happens in background.
    task.defer(callback, nil)

    if UI.lucideLoaded
        and UI.lucide
    then
        resolveLucideIcon(name)
    else
        startLucideLoader()
    end
end

-- Keep the old helper name so ALL existing layout call sites remain unchanged.
-- It now renders a Lucide ImageLabel with a tiny immediate fallback beneath it.
local function makeGlyph(parent, iconName, size, pos, color, textSize)
    iconName = tostring(iconName or "sparkles")

    local holder = Instance.new("Frame", parent)
    holder.Size = size or UDim2.fromOffset(22, 22)
    holder.Position = pos or UDim2.fromOffset(8, 0)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0

    local fallback = Instance.new("TextLabel", holder)
    fallback.Size = UDim2.new(1, 0, 1, 0)
    fallback.BackgroundTransparency = 1
    fallback.Text =
        ICON_FALLBACK[iconName]
        or "•"
    fallback.TextColor3 = color or C.TEXT_2
    fallback.Font = Enum.Font.GothamBold
    fallback.TextSize =
        math.min(
            tonumber(textSize) or 15,
            14
        )
    fallback.TextXAlignment =
        Enum.TextXAlignment.Center
    fallback.TextYAlignment =
        Enum.TextYAlignment.Center

    local image = Instance.new("ImageLabel", holder)
    image.Size = UDim2.new(1, -2, 1, -2)
    image.Position = UDim2.new(0, 1, 0, 1)
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.Image = ""
    image.ImageColor3 = color or C.TEXT_2
    image.ScaleType = Enum.ScaleType.Fit
    image.Visible = false

    local function applyAsset(asset)
        if not holder.Parent then
            return
        end

        if asset then
            image.Image = asset
            image.Visible = true
            fallback.Visible = false
        else
            image.Visible = false
            fallback.Visible = true
        end
    end

    requestLucideIcon(
        iconName,
        applyAsset
    )

    -- If the holder is re-parented after minimize/rebuild, request again.
    holder.AncestryChanged:Connect(function(_, parentNow)
        if parentNow then
            local cached = UI.iconCache[iconName]

            if cached then
                applyAsset(cached)
            elseif UI.lucideLoaded then
                resolveLucideIcon(iconName)
            else
                startLucideLoader()
            end
        end
    end)

    -- expose both so existing callers can recolor the icon safely
    holder:SetAttribute("DHubLucideIcon", true)

    local function syncColor()
        image.ImageColor3 = fallback.TextColor3
    end

    fallback:GetPropertyChangedSignal(
        "TextColor3"
    ):Connect(syncColor)

    return holder
end

local function setAdaptiveIconColor(iconHolder, color)
    if not iconHolder then return end

    for _, child in ipairs(iconHolder:GetChildren()) do
        if child:IsA("ImageLabel") then
            child.ImageColor3 = color
        elseif child:IsA("TextLabel") then
            child.TextColor3 = color
        end
    end
end

local function corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 6); return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke", p); s.Color = col or C.BORDER; s.Thickness = th or 1; return s
end
local function padding(p, top, bot, left, right)
    local pad = Instance.new("UIPadding", p)
    pad.PaddingTop    = UDim.new(0, top   or 0)
    pad.PaddingBottom = UDim.new(0, bot   or 0)
    pad.PaddingLeft   = UDim.new(0, left  or 0)
    pad.PaddingRight  = UDim.new(0, right or 0)
end
local function listLayout(p, spacing, align)
    local l = Instance.new("UIListLayout", p)
    l.Padding     = UDim.new(0, spacing or 6)
    l.SortOrder   = Enum.SortOrder.LayoutOrder
    if align then l.HorizontalAlignment = align end
    return l
end
local function makeDraggable(root, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = root.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    S.UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d = i.Position - ds
            root.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end
local function makeFrame(parent, size, pos, bg)
    local f = Instance.new("Frame", parent)
    f.Size = size; f.BackgroundColor3 = bg or C.SURFACE; f.BorderSizePixel = 0
    if pos then f.Position = pos end
    return f
end
local function makeLabel(parent, text, size, pos, font, textSize, color, xAlign)
    local l = Instance.new("TextLabel", parent)
    l.Size = size or UDim2.new(1,0,1,0)
    if pos then l.Position = pos end
    l.BackgroundTransparency = 1; l.Text = text
    l.TextColor3 = color or C.TEXT_1; l.Font = font or Enum.Font.GothamMedium
    l.TextSize   = textSize or 12
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    return l
end

local function makeControlTexts(parent, label, titleWidth, xOffset, titleColor)
    local widthScale = tonumber(titleWidth) or 0.40
    local offsetX = tonumber(xOffset) or 38

    local title = makeLabel(
        parent,
        label,
        UDim2.new(widthScale, -6, 0, 16),
        UDim2.new(0, offsetX, 0, 4),
        Enum.Font.GothamBold,
        11,
        titleColor or C.TEXT_1
    )

    local desc = makeLabel(
        parent,
        getControlDescription(label),
        UDim2.new(widthScale, -6, 0, 12),
        UDim2.new(0, offsetX, 0, 22),
        Enum.Font.Gotham,
        8,
        C.TEXT_3
    )

    title.TextTruncate = Enum.TextTruncate.AtEnd
    desc.TextTruncate = Enum.TextTruncate.AtEnd

    return title, desc
end


local function makeButton(parent, text, size, pos, bg)
    local b = Instance.new("TextButton", parent)
    b.Size = size or UDim2.new(1,0,0,36)
    if pos then b.Position = pos end
    b.BackgroundColor3 = bg or C.SURFACE; b.Text = text or ""
    b.TextColor3 = C.TEXT_1; b.Font = Enum.Font.GothamMedium; b.TextSize = 12
    b.AutoButtonColor = false; b.BorderSizePixel = 0
    return b
end

local function BuatToggle(parent, label, default, callback)
    local Row = makeFrame(parent, UDim2.new(1,0,0,42), nil, default and C.ELEVATED or C.SURFACE)
    corner(Row, 8)
    local rs = stroke(Row, default and C.ACCENT_D or C.BORDER)

    -- icon has NO outline/border; intentionally lightweight.
    local icon = makeGlyph(
        Row,
        getControlIcon(label),
        UDim2.new(0,24,1,0),
        UDim2.new(0,8,0,0),
        default and C.ACCENT or C.TEXT_3,
        15
    )

    local lbl, descLbl = makeControlTexts(
        Row,
        label,
        0.62,
        38,
        default and C.TEXT_1 or C.TEXT_2
    )

    local pill = makeFrame(
        Row,
        UDim2.new(0,38,0,20),
        UDim2.new(1,-50,0.5,-10),
        default and C.ACCENT_D or C.DIVIDER
    )
    corner(pill, 10)

    local dot = makeFrame(
        pill,
        UDim2.new(0,14,0,14),
        default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        default and C.TEXT_1 or C.TEXT_3
    )
    corner(dot, 7)

    local btn = makeButton(Row, "", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), nil)
    btn.BackgroundTransparency = 1

    local state = default

    local function setVisual(on)
        TS:Create(Row, TweenInfo.new(0.18), {
            BackgroundColor3 = on and C.ELEVATED or C.SURFACE
        }):Play()

        rs.Color = on and C.ACCENT_D or C.BORDER
        lbl.TextColor3 = on and C.TEXT_1 or C.TEXT_2
        setAdaptiveIconColor(icon, on and C.ACCENT or C.TEXT_3)

        TS:Create(pill, TweenInfo.new(0.18), {
            BackgroundColor3 = on and C.ACCENT_D or C.DIVIDER
        }):Play()

        TS:Create(dot, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
            BackgroundColor3 = on and C.TEXT_1 or C.TEXT_3,
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        setVisual(state)
        if callback then callback(state) end
    end)

    if default == true and callback then
        task.spawn(function()
            task.wait(0.1)
            pcall(callback, true)
        end)
    end

    return btn, function(on)
        state = on == true
        setVisual(state)
    end, function()
        return state
    end
end

local function BuatSlider(parent, label, min, max, default, callback)
    local Row = makeFrame(parent, UDim2.new(1,0,0,52), nil, C.SURFACE)
    corner(Row, 8); stroke(Row, C.BORDER)
    makeGlyph(Row, getControlIcon(label), UDim2.new(0,24,0,32), UDim2.new(0,8,0,2), C.TEXT_3, 15)
    local lbl = makeLabel(
        Row,
        label..": "..default,
        UDim2.new(1,-48,0,17),
        UDim2.new(0,38,0,4),
        Enum.Font.GothamBold,
        12,
        C.TEXT_1
    )
    local sliderDesc = makeLabel(
        Row,
        getControlDescription(label),
        UDim2.new(1,-48,0,11),
        UDim2.new(0,38,0,22),
        Enum.Font.Gotham,
        8,
        C.TEXT_3
    )
    sliderDesc.TextTruncate = Enum.TextTruncate.AtEnd
    local track = makeFrame(Row, UDim2.new(1,-28,0,4), UDim2.new(0,14,1,-9), C.DIVIDER)
    corner(track, 2)
    local prog  = makeFrame(track, UDim2.new(0,0,1,0), nil, C.ACCENT); corner(prog, 2)
    local thumb = makeFrame(track, UDim2.new(0,12,0,12), UDim2.new(0,-6,0.5,-6), C.TEXT_1); corner(thumb, 6)
    local dragger = makeButton(track, "", UDim2.new(1,0,3,0), UDim2.new(0,0,-1,0))
    dragger.BackgroundTransparency = 1
    local function update(v)
        local pct = math.clamp((v-min)/(max-min), 0, 1)
        prog.Size  = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -6, 0.5, -6)
        lbl.Text   = label..": "..math.floor(v)
        if callback then callback(math.floor(v)) end
    end
    update(default)
    local dragging = false
    dragger.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging = true end
    end)
    S.UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging = false end
    end)
    S.UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local rel = i.Position.X - track.AbsolutePosition.X
            update(min + (max-min) * math.clamp(rel/track.AbsoluteSize.X, 0, 1))
        end
    end)
end

local function BuatInput(parent, label, placeholder, default, callback)
    local Row = makeFrame(parent, UDim2.new(1,0,0,42), nil, C.SURFACE)
    corner(Row, 8); stroke(Row, C.BORDER)
    makeGlyph(Row, getControlIcon(label), UDim2.new(0,24,1,0), UDim2.new(0,8,0,0), C.TEXT_3, 15)
    makeControlTexts(Row, label, 0.34, 38, C.TEXT_1)
    local box = Instance.new("TextBox", Row)
    box.Size = UDim2.new(0.45,0,0,26); box.Position = UDim2.new(0.53,0,0.5,-13)
    box.BackgroundColor3 = C.ELEVATED; corner(box, 4); stroke(box, C.DIVIDER)
    box.Text = tostring(default or ""); box.PlaceholderText = placeholder or ""
    box.TextColor3 = C.TEXT_1; box.Font = Enum.Font.Gotham; box.TextSize = 11
    box.FocusLost:Connect(function() if callback then callback(box.Text) end end)
end

local function BuatDropdown(parent, label, options, default, callback)
    local selected = default or options[1]
    local Row = makeFrame(parent, UDim2.new(1,0,0,42), nil, C.SURFACE)
    corner(Row, 8); stroke(Row, C.BORDER)
    makeGlyph(Row, getControlIcon(label), UDim2.new(0,24,1,0), UDim2.new(0,8,0,0), C.TEXT_3, 15)
    makeControlTexts(Row, label, 0.39, 38, C.TEXT_1)
    local btn = makeButton(Row, selected, UDim2.new(0.52,0,0,28), UDim2.new(0.46,0,0.5,-14), C.ELEVATED)
    corner(btn, 4); stroke(btn, C.DIVIDER)
    btn.TextColor3 = C.TEXT_1; btn.TextSize = 11; btn.Font = Enum.Font.GothamMedium

    local Panel = Instance.new("Frame", UI.MainSG)
    Panel.Size = UDim2.new(0,200,0,math.min(#options*28+10, 160))
    Panel.BackgroundColor3 = C.ELEVATED
    corner(Panel, 6); stroke(Panel, C.BORDER); Panel.Visible = false; Panel.ZIndex = 20

    local scroll = Instance.new("ScrollingFrame", Panel)
    scroll.Size = UDim2.new(1,-4,1,-4); scroll.Position = UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3; scroll.ZIndex = 20
    local layout = listLayout(scroll, 2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+4)
    end)

    for _, opt in ipairs(options) do
        local ob = makeButton(scroll, opt, UDim2.new(1,0,0,26), nil, selected==opt and C.ACCENT_D or C.ELEVATED)
        corner(ob, 4); ob.ZIndex = 21
        ob.TextColor3 = selected==opt and C.TEXT_1 or C.TEXT_2; ob.TextSize = 11; ob.Font = Enum.Font.GothamMedium
        ob.MouseButton1Click:Connect(function()
            selected  = opt
            btn.Text  = opt
            if UI.closeActiveDropdown then UI.closeActiveDropdown() else Panel.Visible = false; UI.activeDD = nil end
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = c.Text==opt and C.ACCENT_D or C.ELEVATED
                    c.TextColor3       = c.Text==opt and C.TEXT_1  or C.TEXT_2
                end
            end
            if callback then callback(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if Panel.Visible then
            if UI.closeActiveDropdown then UI.closeActiveDropdown() else Panel.Visible = false; UI.activeDD = nil end
            return
        end
        if UI.closeActiveDropdown then UI.closeActiveDropdown() elseif UI.activeDD and UI.activeDD ~= Panel then UI.activeDD.Visible = false end
        local ap = btn.AbsolutePosition; local as = btn.AbsoluteSize
        Panel.Position = UDim2.fromOffset(ap.X, ap.Y+as.Y+4)
        Panel.Visible  = true
        UI.activeDD = Panel
    end)

    return Row
end

local function BuatMultiSelect(parent, label, options, selectedTable, callback, defaultNone)
    local ROW = makeFrame(parent, UDim2.new(1,0,0,42), nil, C.SURFACE)
    corner(ROW, 8); stroke(ROW, C.BORDER)

    local function summaryText()
        if defaultNone then
            if not next(selectedTable) then return "None" end
        else
            if selectedTable["All"] or not next(selectedTable) then return "All" end
        end
        if selectedTable["All"] then return "All" end
        local list = {}
        for _, opt in ipairs(options) do
            if opt ~= "All" and selectedTable[opt] then table.insert(list, opt) end
        end
        if #list == 0 then return defaultNone and "None" or "All" end
        if #list == 1 then return list[1] end
        return #list .. " Selected"
    end

    makeGlyph(ROW, getControlIcon(label), UDim2.new(0,24,1,0), UDim2.new(0,8,0,0), C.TEXT_3, 15)
    makeControlTexts(ROW, label, 0.34, 38, C.TEXT_1)
    local btn = makeButton(ROW, summaryText(), UDim2.new(0.52,0,0,28), UDim2.new(0.46,0,0.5,-14), C.ELEVATED)
    corner(btn, 4); stroke(btn, C.DIVIDER)
    btn.TextColor3 = C.TEXT_1; btn.TextSize = 11; btn.Font = Enum.Font.GothamMedium

    local Panel = Instance.new("Frame", UI.MainSG)
    Panel.Size = UDim2.new(0,220,0,200); Panel.BackgroundColor3 = C.ELEVATED
    corner(Panel, 6); stroke(Panel, C.BORDER); Panel.Visible = false; Panel.ZIndex = 20

    local scroll = Instance.new("ScrollingFrame", Panel)
    scroll.Size = UDim2.new(1,-4,1,-4); scroll.Position = UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 4; scroll.ZIndex = 20
    local layout = listLayout(scroll, 2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
    end)

    local function refreshList()
        for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

        if defaultNone then
            local noneSelected = not next(selectedTable)
            local ob = makeButton(scroll, (noneSelected and "[✓] " or "[ ] ") .. "None", UDim2.new(1,0,0,26), nil, noneSelected and C.DANGER or C.ELEVATED)
            corner(ob, 4); ob.ZIndex = 21
            ob.TextColor3 = noneSelected and C.TEXT_1 or C.TEXT_2; ob.TextSize = 11; ob.Font = Enum.Font.GothamMedium
            ob.MouseButton1Click:Connect(function()
                table.clear(selectedTable)
                btn.Text = summaryText()
                refreshList()
                if callback then callback(selectedTable) end
            end)
        end

        for _, opt in ipairs(options) do
            local isAll = (opt == "All")
            if defaultNone and isAll then continue end

            local sel = selectedTable[opt]==true or (isAll and selectedTable["All"])
            local ob  = makeButton(scroll, (sel and "[✓] " or "[ ] ")..opt, UDim2.new(1,0,0,26), nil, sel and C.ACCENT_D or C.ELEVATED)
            corner(ob, 4); ob.ZIndex = 21
            ob.TextColor3 = sel and C.TEXT_1 or C.TEXT_2; ob.TextSize = 11; ob.Font = Enum.Font.GothamMedium
            ob.MouseButton1Click:Connect(function()
                if isAll then
                    table.clear(selectedTable); selectedTable["All"] = true
                else
                    selectedTable["All"] = nil
                    if selectedTable[opt] then selectedTable[opt] = nil else selectedTable[opt] = true end
                    if not defaultNone then
                        local any = false
                        for _, v in pairs(selectedTable) do if v then any = true; break end end
                        if not any then selectedTable["All"] = true end
                    end
                end
                btn.Text = summaryText()
                refreshList()
                if callback then callback(selectedTable) end
            end)
        end
    end

    btn.MouseButton1Click:Connect(function()
        if Panel.Visible then
            if UI.closeActiveDropdown then UI.closeActiveDropdown() else Panel.Visible = false; UI.activeDD = nil end
            return
        end
        if UI.closeActiveDropdown then UI.closeActiveDropdown() elseif UI.activeDD and UI.activeDD ~= Panel then UI.activeDD.Visible = false end
        refreshList()
        local ap = btn.AbsolutePosition; local as = btn.AbsoluteSize
        Panel.Position = UDim2.fromOffset(ap.X, ap.Y+as.Y+4)
        Panel.Visible  = true
        UI.activeDD = Panel
    end)

    return ROW
end

local function BuatSection(parent, text)
    local Row = makeFrame(parent, UDim2.new(1,0,0,22), nil, C.BASE)
    Row.BackgroundTransparency = 1
    local acc = makeFrame(Row, UDim2.new(0,3,0,14), UDim2.new(0,0,0.5,-7), C.ACCENT)
    corner(acc, 2)
    local lbl = makeLabel(Row, text:upper(), UDim2.new(1,-12,1,0), UDim2.new(0,10,0,0), Enum.Font.GothamBold, 10, C.TEXT_1)
    lbl.BackgroundTransparency = 1
    return Row
end

local function BuatActionBtn(parent, label, color, callback)
    local Row = makeFrame(parent, UDim2.new(1,0,0,42), nil, color or C.SURFACE)
    corner(Row, 8); stroke(Row, C.BORDER)
    makeGlyph(Row, getControlIcon(label), UDim2.new(0,24,1,0), UDim2.new(0,8,0,0), C.ACCENT, 15)
    makeControlTexts(Row, label, 0.72, 38, C.TEXT_1)
    local arrow = makeLabel(Row, "›", UDim2.new(0,18,1,0), UDim2.new(1,-28,0,0), Enum.Font.GothamBold, 16, C.TEXT_3, Enum.TextXAlignment.Center)
    local btn = makeButton(Row, "", UDim2.new(1,0,1,0)); btn.BackgroundTransparency = 1
    btn.MouseEnter:Connect(function()
        TS:Create(Row, TweenInfo.new(0.12), {BackgroundColor3 = C.ELEVATED}):Play()
        arrow.TextColor3 = C.ACCENT
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(Row, TweenInfo.new(0.12), {BackgroundColor3 = color or C.SURFACE}):Play()
        arrow.TextColor3 = C.TEXT_3
    end)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return Row, btn
end

DHub.ServerBrowser = {
    maxCards = 24,
    loading = false,
    generation = 0,
}

function DHub.ServerBrowser:ResolveRequest()
    local env = nil

    pcall(function()
        if getgenv then
            env = getgenv()
        end
    end)

    env = type(env)=="table" and env or _G

    local candidates = {}

    pcall(function()
        if syn and type(syn.request)=="function" then
            candidates[#candidates+1] = syn.request
        end
    end)

    pcall(function()
        if http and type(http.request)=="function" then
            candidates[#candidates+1] = http.request
        end
    end)

    pcall(function()
        if type(http_request)=="function" then
            candidates[#candidates+1] = http_request
        end
    end)

    pcall(function()
        if fluxus and type(fluxus.request)=="function" then
            candidates[#candidates+1] = fluxus.request
        end
    end)

    pcall(function()
        if type(request)=="function" then
            candidates[#candidates+1] = request
        end
    end)

    for _, name in ipairs({
        "request",
        "http_request",
    }) do
        local fn = env and env[name]
        if type(fn)=="function" then
            candidates[#candidates+1] = fn
        end
    end

    return candidates[1]
end

function DHub.ServerBrowser:RequestPage(cursor)
    local requestFunc = self:ResolveRequest()

    if type(requestFunc)~="function" then
        return nil, "no_request_function"
    end

    local url =
        string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
            game.PlaceId
        )

    if cursor and tostring(cursor)~="" then
        url =
            url
            .. "&cursor="
            .. S.HttpService:UrlEncode(
                tostring(cursor)
            )
    end

    local okRequest, response =
        pcall(function()
            return requestFunc({
                Url = url,
                Method = "GET",
            })
        end)

    if not okRequest
        or type(response)~="table"
    then
        return nil, "request_failed"
    end

    local body =
        response.Body
        or response.body

    if type(body)~="string"
        or body==""
    then
        return nil, "empty_body"
    end

    local okJson, data =
        pcall(function()
            return S.HttpService:JSONDecode(body)
        end)

    if not okJson
        or type(data)~="table"
    then
        return nil, "json_failed"
    end

    return data, nil
end

function DHub.ServerBrowser:FetchFewest()
    local currentJobId = tostring(game.JobId or "")
    local servers = {}
    local seen = {}
    local cursor = nil
    local pageCount = 0

    repeat
        pageCount = pageCount + 1

        local data, err =
            self:RequestPage(cursor)

        if not data then
            if #servers == 0 then
                return nil, err or "fetch_failed"
            end
            break
        end

        if type(data.data)=="table" then
            for _, server in ipairs(data.data) do
                if type(server)=="table"
                    and server.id
                then
                    local sid = tostring(server.id)
                    local playing = tonumber(server.playing) or 0
                    local maxPlayers = tonumber(server.maxPlayers) or 0

                    if sid ~= currentJobId
                        and not seen[sid]
                        and playing > 0
                        and maxPlayers > 0
                        and playing < maxPlayers
                    then
                        seen[sid] = true

                        servers[#servers+1] = {
                            id = sid,
                            playing = playing,
                            maxPlayers = maxPlayers,
                            ping = tonumber(server.ping) or 0,
                            fps = tonumber(server.fps) or 0,
                        }
                    end
                end
            end
        end

        cursor = data.nextPageCursor

        if cursor == nil
            or tostring(cursor)==""
            or tostring(cursor)=="null"
        then
            cursor = nil
        end
    until not cursor or pageCount >= 6

    table.sort(
        servers,
        function(a,b)
            if a.playing ~= b.playing then
                return a.playing < b.playing
            end

            local ap = tonumber(a.ping) or math.huge
            local bp = tonumber(b.ping) or math.huge

            if ap ~= bp then
                return ap < bp
            end

            return tostring(a.id) < tostring(b.id)
        end
    )

    while #servers > self.maxCards do
        table.remove(servers)
    end

    return servers, nil
end

function DHub.ServerBrowser:SyncPanelPosition()
    local panel = UI.ServerPanel
    local root = UI.MainRoot

    if not panel or not root then
        return
    end

    if self.positioning == true then
        return
    end

    self.positioning = true

    local camera = S.Workspace.CurrentCamera
    local viewport =
        camera
        and camera.ViewportSize
        or Vector2.new(1920, 1080)

    local rootPos = root.AbsolutePosition
    local rootSize = root.AbsoluteSize
    local panelSize = panel.AbsoluteSize
    local gap = 7
    local margin = 6

    local desiredPanelX =
        rootPos.X
        + rootSize.X
        + gap

    local overflow =
        (
            desiredPanelX
            + panelSize.X
            + margin
        )
        - viewport.X

    if overflow > 0 then
        local p = root.Position

        root.Position =
            UDim2.new(
                p.X.Scale,
                p.X.Offset - overflow,
                p.Y.Scale,
                p.Y.Offset
            )

        rootPos =
            Vector2.new(
                rootPos.X - overflow,
                rootPos.Y
            )
    end

    local x =
        rootPos.X
        + rootSize.X
        + gap

    local y =
        rootPos.Y

    y =
        math.max(
            margin,
            math.min(
                y,
                math.max(
                    margin,
                    viewport.Y
                        - panelSize.Y
                        - margin
                )
            )
        )

    panel.Position =
        UDim2.fromOffset(
            math.floor(x + 0.5),
            math.floor(y + 0.5)
        )

    self.positioning = false
end

function DHub.ServerBrowser:Join(serverId)
    serverId = tostring(serverId or "")

    if serverId == "" then
        return false
    end

    Notify(
        "Joining selected small server...",
        3
    )

    local ok =
        pcall(function()
            S.TeleportService:TeleportToPlaceInstance(
                PLACE_ID or game.PlaceId,
                serverId,
                LP
            )
        end)

    if not ok then
        Notify(
            "Failed to join selected server.",
            3
        )
    end

    return ok
end

function DHub.ServerBrowser:ClearCards()
    if not UI.ServerList then
        return
    end

    for _, child in ipairs(
        UI.ServerList:GetChildren()
    ) do
        if child:GetAttribute(
            "DHubServerCard"
        ) == true
        then
            child:Destroy()
        end
    end
end

function DHub.ServerBrowser:SetMessage(message)
    if UI.ServerBrowserStatus then
        UI.ServerBrowserStatus.Text =
            tostring(message or "")
    end
end

function DHub.ServerBrowser:Render(servers)
    if not UI.ServerList then
        return
    end

    self:ClearCards()

    if type(servers) ~= "table"
        or #servers == 0
    then
        Notify(
            "No joinable small servers found.",
            3
        )
        return
    end

    for index, server in ipairs(servers) do
        local card =
            makeFrame(
                UI.ServerList,
                UDim2.new(1, -4, 0, 68),
                nil,
                C.SURFACE
            )

        card.Name =
            "ServerCard_"
            .. tostring(index)

        card.ZIndex = 102

        card:SetAttribute(
            "DHubServerCard",
            true
        )

        card.BackgroundTransparency = 0.04
        corner(card, 8)
        stroke(card, C.BORDER, 1)

        local accent =
            makeFrame(
                card,
                UDim2.new(0, 3, 0, 34),
                UDim2.new(0, 0, 0, 10),
                C.ACCENT
            )

        accent.ZIndex = 103
        corner(accent, 2)

        local playerText =
            string.format(
                "%d / %d players",
                tonumber(server.playing) or 0,
                tonumber(server.maxPlayers) or 0
            )

        local title =
            makeLabel(
                card,
                playerText,
                UDim2.new(1, -18, 0, 16),
                UDim2.new(0, 11, 0, 6),
                Enum.Font.GothamBold,
                10,
                C.TEXT_1
            )

        title.ZIndex = 103

        local shortId =
            tostring(server.id or "")

        if #shortId > 9 then
            shortId =
                shortId:sub(1, 5)
                .. ".."
                .. shortId:sub(-3)
        end

        local info =
            string.format(
                "Server ID: %s%s",
                shortId,
                (tonumber(server.ping) or 0) > 0
                    and (
                        "   •   "
                        .. tostring(
                            math.floor(
                                tonumber(server.ping)
                                or 0
                            )
                        )
                        .. " ms"
                    )
                    or ""
            )

        local infoLabel =
            makeLabel(
                card,
                info,
                UDim2.new(1, -18, 0, 14),
                UDim2.new(0, 11, 0, 22),
                Enum.Font.Gotham,
                8,
                C.TEXT_3
            )

        infoLabel.ZIndex = 103

        local join =
            makeButton(
                card,
                "Join",
                UDim2.new(1, -18, 0, 23),
                UDim2.new(0, 9, 1, -27),
                C.ELEVATED
            )

        join.ZIndex = 103
        join.Font = Enum.Font.GothamBold
        join.TextSize = 10
        join.TextColor3 = C.TEXT_1

        corner(join, 5)
        stroke(join, C.BORDER, 1)

        join.MouseEnter:Connect(
            function()
                TS:Create(
                    join,
                    TweenInfo.new(0.12),
                    {
                        BackgroundColor3 = C.ACCENT
                    }
                ):Play()
            end
        )

        join.MouseLeave:Connect(
            function()
                TS:Create(
                    join,
                    TweenInfo.new(0.12),
                    {
                        BackgroundColor3 = C.ELEVATED
                    }
                ):Play()
            end
        )

        join.MouseButton1Click:Connect(
            function()
                DHub.ServerBrowser:Join(
                    server.id
                )
            end
        )
    end
end

function DHub.ServerBrowser:Refresh()
    if self.loading then
        return
    end

    self.loading = true
    self.generation =
        self.generation + 1

    local myGeneration =
        self.generation

    self:SetMessage(
        "Loading fewest-player servers..."
    )

    if UI.ServerRefreshButton then
        UI.ServerRefreshButton.Text =
            "Refreshing..."
    end

    task.spawn(function()
        local ok, servers, fetchError =
            pcall(function()
                return self:FetchFewest()
            end)

        if myGeneration
            ~= self.generation
        then
            return
        end

        self.loading = false

        if UI.ServerRefreshButton then
            UI.ServerRefreshButton.Text =
                "Refresh"
        end

        if not ok
            or type(servers)~="table"
        then
            local reason =
                tostring(
                    fetchError
                    or (
                        not ok
                        and servers
                        or "fetch_failed"
                    )
                )

            Notify(
                "Small Server Browser: "
                    .. reason,
                4
            )

            return
        end

        self:Render(servers)
    end)
end

DHub.UICompact = {
    normalScale = 1,
    compactScale = 0.78,
}

function DHub.UICompact:GetScale()
    return MiscCfg.compactUi
        and self.compactScale
        or self.normalScale
end

function DHub.UICompact:Apply(saveAfter)
    local scale = self:GetScale()

    if UI.MainScale then
        UI.MainScale.Scale = scale
    end

    if UI.ServerScale then
        UI.ServerScale.Scale = scale
    end

    if UI.CompactBtn then
        UI.CompactBtn.Text =
            MiscCfg.compactUi
            and "↗"
            or "↙"
    end

    if DHub.ServerBrowser
        and DHub.ServerBrowser.SyncPanelPosition
    then
        task.defer(function()
            task.wait()
            DHub.ServerBrowser:SyncPanelPosition()
        end)
    end

    if saveAfter == true then
        saveConfig()
    end
end

function DHub.UICompact:Toggle()
    MiscCfg.compactUi =
        not MiscCfg.compactUi

    self:Apply(true)

    Notify(
        MiscCfg.compactUi
            and "UI Size: Compact"
            or "UI Size: Normal",
        2
    )
end

local function buildUI()
    local MainSG = Instance.new("ScreenGui", GuiRoot)
    MainSG.Name = "DHub_SAE_V3.0"; MainSG.ResetOnSpawn = false
    UI.MainSG = MainSG

    local function closeActiveDropdown()
        if UI.activeDD then
            UI.activeDD.Visible = false
            UI.activeDD = nil
        end
    end
    UI.closeActiveDropdown = closeActiveDropdown

    S.UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if not UI.activeDD or not UI.activeDD.Visible then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local p  = inp.Position
        local ap = UI.activeDD.AbsolutePosition
        local as = UI.activeDD.AbsoluteSize
        if not (p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y) then
            closeActiveDropdown()
        end
    end)

    local Root = makeFrame(MainSG, UDim2.new(0,460,0,400))
    Root.Position = UDim2.new(0.5,-230,0.5,-200); Root.BackgroundTransparency = 1
    Root.ClipsDescendants = false
    UI.MainRoot = Root

    UI.MainScale = Instance.new("UIScale", Root)
    UI.MainScale.Name = "DHub_MainUIScale"
    UI.MainScale.Scale = DHub.UICompact:GetScale()

    local ReleaseFloat = makeFrame(
        MainSG,
        UDim2.new(0, 170, 0, 42),
        UDim2.new(1, -190, 0.5, -21),
        C.SURFACE
    )
    ReleaseFloat.Name = "DHub_BypassReleaseFloat"
    ReleaseFloat.ZIndex = 200
    corner(ReleaseFloat, 7)
    stroke(ReleaseFloat, C.BORDER, 1)

    local ReleaseGrip = makeFrame(ReleaseFloat, UDim2.new(0, 24, 1, 0), UDim2.new(0, 0, 0, 0), C.ELEVATED)
    ReleaseGrip.ZIndex = 201; corner(ReleaseGrip, 7)
    local GripLbl = makeLabel(ReleaseGrip, "≡", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Enum.Font.GothamBold, 14, C.TEXT_2, Enum.TextXAlignment.Center)
    GripLbl.ZIndex = 202
    makeDraggable(ReleaseFloat, ReleaseGrip)
    makeDraggable(ReleaseFloat, GripLbl)

    local ReleaseBtn = makeButton(ReleaseFloat, "Bypass Release", UDim2.new(1, -26, 1, -4), UDim2.new(0, 25, 0, 2), C.SURFACE)
    ReleaseBtn.Name = "BypassReleaseButton"
    ReleaseBtn.ZIndex = 201; ReleaseBtn.Font = Enum.Font.GothamBold; ReleaseBtn.TextSize = 11; ReleaseBtn.TextColor3 = C.TEXT_1
    corner(ReleaseBtn, 6)

    ReleaseBtn.MouseEnter:Connect(function() TS:Create(ReleaseBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.ELEVATED}):Play() end)
    ReleaseBtn.MouseLeave:Connect(function() TS:Create(ReleaseBtn, TweenInfo.new(0.12), {BackgroundColor3 = C.SURFACE}):Play() end)
    ReleaseBtn.MouseButton1Click:Connect(function()
        releaseTreadmill("manual")
        Notify("Bypass Release: treadmill released", 2)
    end)

    local MinIcon = Instance.new("ImageButton", Root)
    MinIcon.Size = UDim2.new(0,48,0,48); MinIcon.BackgroundColor3 = C.SURFACE
    MinIcon.Image = "rbxassetid://122511465288707"; MinIcon.Visible = false
    MinIcon.AutoButtonColor = false; corner(MinIcon, 8); stroke(MinIcon, C.BORDER)
    makeDraggable(Root, MinIcon)

    local Win = makeFrame(Root, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BASE)
    Win.ClipsDescendants = true; corner(Win, 8); stroke(Win, C.BORDER)

    local Header = makeFrame(Win, UDim2.new(1,0,0,44), nil, C.SURFACE); corner(Header, 8); stroke(Header, C.DIVIDER, 1)
    makeFrame(Header, UDim2.new(1,0,0,8), UDim2.new(0,0,1,-8), C.SURFACE)
    makeFrame(Header, UDim2.new(0,36,0,3), UDim2.new(0,14,0,0), C.ACCENT)
    local ico = Instance.new("ImageLabel", Header)
    ico.Size = UDim2.new(0,28,0,28); ico.Position = UDim2.new(0,8,0.5,-14)
    ico.BackgroundTransparency = 1; ico.Image = "rbxassetid://122511465288707"; corner(ico, 8)
    local titleLbl = makeLabel(Header, "", UDim2.new(1,-100,1,0), UDim2.new(0,44,0,0), Enum.Font.GothamBold, 13, C.TEXT_1)
    titleLbl.RichText = true
    titleLbl.Text     = "D-HUB  |  <font color='#9658FF'>STEAL AN EGG</font>  <font color='#7C7F9E'>V3.0</font>"
    makeDraggable(Root, Header)

    local origSize = Root.Size

    UI.CompactBtn =
        makeButton(
            Header,
            MiscCfg.compactUi and "↗" or "↙",
            UDim2.new(0,22,0,22),
            UDim2.new(1,-58,0.5,-11),
            C.SURFACE
        )

    UI.CompactBtn.Name = "CompactSizeButton"
    UI.CompactBtn.TextSize = 13
    UI.CompactBtn.Font = Enum.Font.GothamBold
    UI.CompactBtn.TextColor3 = C.TEXT_2
    corner(UI.CompactBtn, 4)

    UI.CompactBtn.MouseEnter:Connect(function()
        TS:Create(
            UI.CompactBtn,
            TweenInfo.new(0.12),
            {BackgroundColor3 = C.ELEVATED}
        ):Play()
    end)

    UI.CompactBtn.MouseLeave:Connect(function()
        TS:Create(
            UI.CompactBtn,
            TweenInfo.new(0.12),
            {BackgroundColor3 = C.SURFACE}
        ):Play()
    end)

    UI.CompactBtn.MouseButton1Click:Connect(function()
        DHub.UICompact:Toggle()
    end)

    local MinBtn   = makeButton(Header, "—", UDim2.new(0,22,0,22), UDim2.new(1,-30,0.5,-11), C.SURFACE)
    corner(MinBtn, 4); MinBtn.TextSize = 13; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextColor3 = C.TEXT_2
    MinBtn.MouseButton1Click:Connect(function()
        Win.Visible = false
        MinIcon.Visible = true

        if UI.ServerPanel then
            UI.ServerPanel.Visible = false
        end

        TS:Create(
            Root,
            TweenInfo.new(0.2),
            {Size=UDim2.new(0,48,0,48)}
        ):Play()
    end)

    MinIcon.MouseButton1Click:Connect(function()
        Win.Visible = true
        MinIcon.Visible = false

        TS:Create(
            Root,
            TweenInfo.new(0.2),
            {Size=origSize}
        ):Play()

        if UI.ServerPanel then
            if UI.ActiveTab == "Misc" then
                DHub.ServerBrowser:SyncPanelPosition()
                UI.ServerPanel.Visible = true
                DHub.ServerBrowser:Refresh()
            else
                UI.ServerPanel.Visible = false
            end
        end
    end)

    local Body = makeFrame(Win, UDim2.new(1,0,1,-44), UDim2.new(0,0,0,44))
    Body.BackgroundTransparency = 1

    local Sidebar = makeFrame(Body, UDim2.new(0,130,1,0), nil, C.SURFACE)
    Sidebar.BorderSizePixel = 0
    makeFrame(Sidebar, UDim2.new(0,1,1,0), UDim2.new(1,0,0,0), C.DIVIDER)

    local TabScroll = Instance.new("ScrollingFrame", Sidebar)
    TabScroll.Size = UDim2.new(1,0,1,-50); TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0; TabScroll.ScrollBarThickness = 2
    local tabLayout = listLayout(TabScroll, 4, Enum.HorizontalAlignment.Center)
    padding(TabScroll, 10, 10, 8, 8)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize = UDim2.new(0,0,0,tabLayout.AbsoluteContentSize.Y+20)
    end)

    local ProfileBar = makeFrame(Sidebar, UDim2.new(1,0,0,50), UDim2.new(0,0,1,-50), C.BASE)
    local avi = Instance.new("ImageLabel", ProfileBar)
    avi.Size = UDim2.new(0,32,0,32); avi.Position = UDim2.new(0,10,0.5,-16)
    avi.BackgroundColor3 = C.ELEVATED; avi.BorderSizePixel = 0; corner(avi, 16); stroke(avi, C.BORDER, 1)
    task.spawn(function()
        pcall(function()
            avi.Image = S.Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
    end)
    makeLabel(ProfileBar, LP.DisplayName, UDim2.new(1,-54,0,16), UDim2.new(0,50,0.5,-16), Enum.Font.GothamBold, 10, C.TEXT_1)
    makeLabel(ProfileBar, "D-Hub V3.0",     UDim2.new(1,-54,0,12), UDim2.new(0,50,0.5,2),   Enum.Font.Gotham,     9,  C.ACCENT)

    local ContentArea = makeFrame(Body, UDim2.new(1,-145,1,0), UDim2.new(0,145,0,0))
    ContentArea.BackgroundTransparency = 1

    local pages   = {}
    local navBtns = {}
    local pageCanvasRefresh = {}

    UI.ActiveTab = "Auto"

    local function makePage(name)
        local page = Instance.new("ScrollingFrame", ContentArea)
        page.Name = name
        page.Size = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = C.DIVIDER
        page.ScrollingDirection = Enum.ScrollingDirection.Y
        page.AutomaticCanvasSize = Enum.AutomaticSize.None
        page.Visible = (name == "Auto")

        local layout = listLayout(page, 8)
        padding(page, 14, 14, 14, 14)

        local function refreshCanvas()
            if not page or not page.Parent then return end
            local contentY = layout.AbsoluteContentSize.Y + 42
            local viewportY = math.max(page.AbsoluteSize.Y, 600)
            page.CanvasSize = UDim2.new(0,0,0,math.max(contentY,viewportY))
        end

        pageCanvasRefresh[name] = refreshCanvas

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            task.defer(refreshCanvas)
        end)
        page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(refreshCanvas)
        end)
        page.ChildAdded:Connect(function()
            task.defer(refreshCanvas)
        end)

        pages[name] = page
        task.defer(refreshCanvas)
        return page
    end

    local function switchTab(name)
        if UI.closeActiveDropdown then
            UI.closeActiveDropdown()
        end

        UI.ActiveTab = name

        if UI.ServerPanel then
            if name == "Misc" then
                DHub.ServerBrowser:SyncPanelPosition()
                UI.ServerPanel.Visible = true
                DHub.ServerBrowser:Refresh()
            else
                UI.ServerPanel.Visible = false
            end
        end

        -- Page visibility.
        for n, p in pairs(pages) do
            local on = (n == name)
            p.Visible = on

            if on then
                local refresh = pageCanvasRefresh[n]
                if refresh then
                    task.defer(refresh)
                    task.delay(0.05, refresh)
                end
            end
        end

        -- IMPORTANT:
        -- Active navigation state is set DIRECTLY, not tweened.
        -- This guarantees exactly ONE purple indicator at a time and
        -- prevents stale tween states when switching tabs quickly.
        for n, d in pairs(navBtns) do
            local on = (n == name)

            d.btn.BackgroundColor3 =
                on and C.ELEVATED or C.SURFACE

            d.ind.BackgroundTransparency =
                on and 0 or 1

            d.lbl.TextColor3 =
                on and C.TEXT_1 or C.TEXT_2

            if d.icon then
                setAdaptiveIconColor(
                    d.icon,
                    on and C.ACCENT or C.TEXT_3
                )
            end
        end
    end

    local NAV_NAME = {
        Auto = "Farming",
        Plot = "Place",
        Shop = "Shop",
        Event = "Event",
        Misc = "Misc",
        Info = "Info",
    }

    local function makeNavBtn(name)
        local btn = makeButton(TabScroll, "", UDim2.new(1,-2,0,34), nil, C.SURFACE)
        corner(btn, 7)

        local ind = makeFrame(btn, UDim2.new(0,3,0,18), UDim2.new(0,0,0.5,-9), C.ACCENT)
        corner(ind, 2)
        ind.BackgroundTransparency = (name == "Auto") and 0 or 1

        local icon = makeGlyph(
            btn,
            UI_ICON[name] or "•",
            UDim2.new(0,24,1,0),
            UDim2.new(0,8,0,0),
            (name == "Auto") and C.ACCENT or C.TEXT_3,
            14
        )

        local lbl = makeLabel(
            btn,
            NAV_NAME[name] or name,
            UDim2.new(1,-48,1,0),
            UDim2.new(0,36,0,0),
            Enum.Font.GothamMedium,
            11,
            (name == "Auto") and C.TEXT_1 or C.TEXT_2
        )

        btn.MouseEnter:Connect(function()
            if UI.ActiveTab ~= name then
                btn.BackgroundColor3 = C.ELEVATED
            end
        end)

        btn.MouseLeave:Connect(function()
            if UI.ActiveTab ~= name then
                btn.BackgroundColor3 = C.SURFACE
            end
        end)

        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        navBtns[name] = {
            btn = btn,
            ind = ind,
            lbl = lbl,
            icon = icon,
        }
    end

    local TAB_LIST = {"Auto", "Plot", "Shop", "Event", "Misc", "Info"}

    for _, t in ipairs(TAB_LIST) do
        makeNavBtn(t)
        makePage(t)
    end

    -- Normalize initial state after every nav/page exists.
    -- Prevents stale/default colors from producing more than one active tab.
    switchTab("Auto")

    do
        UI.ServerPanel =
            makeFrame(
                MainSG,
                UDim2.new(0, 170, 0, 400),
                UDim2.fromOffset(0, 0),
                C.BASE
            )

        UI.ServerPanel.Name =
            "DHub_SmallServerBrowser"

        UI.ServerPanel.BackgroundTransparency = 1
        UI.ServerPanel.BorderSizePixel = 0
        UI.ServerPanel.Visible = false
        UI.ServerPanel.ZIndex = 100
        UI.ServerPanel.ClipsDescendants = false
        UI.ServerPanel.Active = false

        UI.ServerScale = Instance.new("UIScale", UI.ServerPanel)
        UI.ServerScale.Name = "DHub_ServerUIScale"
        UI.ServerScale.Scale = DHub.UICompact:GetScale()

        UI.ServerRefreshButton = nil
        UI.ServerBrowserStatus = nil

        UI.ServerList =
            Instance.new(
                "ScrollingFrame",
                UI.ServerPanel
            )

        UI.ServerList.Name =
            "SmallServerList"

        UI.ServerList.Size =
            UDim2.new(
                1,
                0,
                1,
                0
            )

        UI.ServerList.Position =
            UDim2.fromOffset(0, 0)

        UI.ServerList.BackgroundTransparency = 1
        UI.ServerList.BorderSizePixel = 0
        UI.ServerList.ScrollBarThickness = 2
        UI.ServerList.ScrollBarImageColor3 =
            C.ACCENT
        UI.ServerList.CanvasSize =
            UDim2.new(0, 0, 0, 0)
        UI.ServerList.ZIndex = 101

        local serverLayout =
            listLayout(
                UI.ServerList,
                8
            )

        padding(
            UI.ServerList,
            2,
            6,
            0,
            4
        )

        serverLayout:GetPropertyChangedSignal(
            "AbsoluteContentSize"
        ):Connect(
            function()
                UI.ServerList.CanvasSize =
                    UDim2.new(
                        0,
                        0,
                        0,
                        serverLayout.AbsoluteContentSize.Y
                            + 8
                    )
            end
        )

        DHub.ServerBrowser:SyncPanelPosition()

        Root:GetPropertyChangedSignal(
            "AbsolutePosition"
        ):Connect(
            function()
                DHub.ServerBrowser:SyncPanelPosition()
            end
        )

        Root:GetPropertyChangedSignal(
            "AbsoluteSize"
        ):Connect(
            function()
                DHub.ServerBrowser:SyncPanelPosition()
            end
        )

        if S.Workspace.CurrentCamera then
            S.Workspace.CurrentCamera:GetPropertyChangedSignal(
                "ViewportSize"
            ):Connect(
                function()
                    DHub.ServerBrowser:SyncPanelPosition()
                end
            )
        end
    end

    local P = pages["Auto"]

    BuatSection(P, "Farm Method")

    BuatDropdown(
        P,
        "Select Method",
        {"Normal", "Fast"},
        Cfg.farmMethod,
        function(value)
            local nextMethod =
                value == "Fast"
                and "Fast"
                or "Normal"

            if nextMethod == Cfg.farmMethod then
                return
            end

            local resumeAutoFarm =
                Cfg.autoFarm == true

            -- Stop the current worker without changing the saved Auto Farm toggle.
            if resumeAutoFarm then
                Cfg.autoFarm = false

                if Runtime.FastFarmStop then
                    Runtime.FastFarmStop()
                end

                DHub.MovementService:Cancel()
            end

            Cfg.farmMethod = nextMethod

            if resumeAutoFarm then
                Cfg.autoFarm = true

                -- Wait for the previous worker to fully release Runtime.farming
                -- before starting the newly selected method.
                task.spawn(function()
                    local deadline = tick() + 2.0

                    while Runtime.farming
                        and tick() < deadline
                    do
                        task.wait(0.03)
                    end

                    if not Cfg.autoFarm
                        or Cfg.farmMethod ~= nextMethod
                    then
                        return
                    end

                    if nextMethod == "Fast"
                        and Runtime.FastFarmStart
                    then
                        Runtime.FastFarmStart()
                    elseif not Runtime.farming then
                        task.spawn(doFarmLoop)
                    end
                end)
            end

            saveConfig()
        end
    )

    BuatSection(P, "Egg Farm")

    local statusRow = makeFrame(P, UDim2.new(1,0,0,32), nil, C.SURFACE); corner(statusRow); stroke(statusRow, C.BORDER)
    local statusLbl = makeLabel(statusRow, "Status: Idle  |  Steals: 0", UDim2.new(1,-14,1,0), UDim2.new(0,10,0,0), Enum.Font.Gotham, 11, C.ACCENT)
    Runtime.StatusLbl = statusLbl

    BuatMultiSelect(P, "Select Area", ZONE_NAMES, Cfg.selectedAreas, function(tbl)
        Cfg.selectedAreas = tbl
        DHub.TargetSelector:InvalidateFarmIndex()
        saveConfig()
    end)

    BuatMultiSelect(P, "Select Rarity", RARITIES, Cfg.selectedRarities, function(tbl)
        Cfg.selectedRarities = tbl
        DHub.TargetSelector:InvalidateFarmIndex()
        saveConfig()
    end)

    BuatInput(P, "Min Weight", "0 = All", tostring(Cfg.minWeight), function(v)
        Cfg.minWeight = math.max(0, tonumber(v) or 0)
        DHub.TargetSelector:InvalidateFarmIndex()
        saveConfig()
    end)

    BuatDropdown(P, "Farm Priority", {"Nearest", "Hugest", "Rarest"}, Cfg.farmPriority, function(v)
        Cfg.farmPriority = v or "Nearest"
        DHub.TargetSelector:InvalidateFarmIndex()
        saveConfig()
    end)

    BuatToggle(P, "Instant Steal (0s Prompt)", Cfg.instantSteal, function(v)
        Cfg.instantSteal = v
        if v then applyInstantToAll() end
        saveConfig()
    end)

    BuatToggle(P, "Auto Farm Eggs", Cfg.autoFarm, function(v)
        Cfg.autoFarm = v
        PlotRuntime.placeGeneration = PlotRuntime.placeGeneration + 1
        PlotRuntime.placeOwner = nil
        PlotRuntime.farmPlotSelectorRevision = nil
        PlotRuntime.TouchFarmAux(true)

        if v and not Runtime.farming then
            if Cfg.farmMethod == "Fast"
                and Runtime.FastFarmStart
            then
                Runtime.FastFarmStart()
            else
                task.spawn(doFarmLoop)
            end
        elseif not v then
            if Runtime.FastFarmStop then
                Runtime.FastFarmStop()
            end

            DHub.FarmCoordinator:ClearTarget()
            DHub.FarmCoordinator:SetState("Idle")

            if PlotCfg.autoPlace and not PlotRuntime.placing then
                task.spawn(doPlotPlaceLoop)
            end
        end
        saveConfig()
    end)

    BuatToggle(P, "Anti Boss", Cfg.antiBoss, function(v)
        Cfg.antiBoss = v

        if not v then
            stopAntiBossSpamTeleport()
            hideAntiBossOverlay()
            AntiBossState.lastTriggerAt = 0
        end

        saveConfig()
    end)

    BuatToggle(P, "Auto Treadmill (When Waiting)", Cfg.autoTreadmill, function(v)
        Cfg.autoTreadmill = v

        if DHub.GlobalEggScanner
            and DHub.GlobalEggScanner._Touch
        then
            DHub.GlobalEggScanner:_Touch()
        end

        PlotRuntime.TouchFarmAux(true)

        if FastFarm and FastFarm.State then
            FastFarm.State.treadmillWaiting = false
            FastFarm.State.treadmillReleaseAt = 0
        end

        -- No direct doff here. Turning this OFF changes the idle home
        -- to Safezone; the coordinator will start a Safezone route, and that
        -- route performs the single allowed release.
        pcall(function()
            freshWake()
        end)

        saveConfig()
    end)

    BuatSection(P, "Speed Settings (FAST - Locked)")

    BuatSlider(P, "Movement Speed (FAST only)", 1, 320, Cfg.walkSpeed, function(v)
        Cfg.walkSpeed = math.clamp(tonumber(v) or Cfg.walkSpeed, 1, 320)

        applyConfiguredWalkSpeedNow()

        saveConfig()
    end)

    BuatActionBtn(P, "Reset Steal Counter", C.SURFACE, function()
        Runtime.steals = 0; UpdateStatus(Runtime.statusText)
        Notify("Counter reset", 2)
    end)

    BuatActionBtn(P, "Force Re-Scan", C.SURFACE, function()
        local ok=DHub.GlobalEggScanner:Resync()
        Notify(ok and "Global Egg Cache synchronized" or "Scanner is event-driven; sync unavailable",2)
    end)

    local PP = pages["Plot"]
    BuatSection(PP, "Plot Manager")

    local plotStatusRow = makeFrame(PP, UDim2.new(1,0,0,32), nil, C.SURFACE); corner(plotStatusRow); stroke(plotStatusRow, C.BORDER)
    local plotStatusLbl = makeLabel(plotStatusRow, "Plot: Idle  |  Placed: 0", UDim2.new(1,-14,1,0), UDim2.new(0,10,0,0), Enum.Font.Gotham, 11, C.ACCENT)
    PlotRuntime.StatusLbl2 = plotStatusLbl

    BuatSection(PP, "Place Settings")
    BuatMultiSelect(PP, "Rarity To Place", RARITIES, PlotCfg.selectedRarities, function(tbl)
        PlotCfg.selectedRarities = tbl
        PlotRuntime.TouchFarmAux(true)
        saveConfig()
    end)

    BuatInput(PP, "Min Weight To Place", "0 = place all", tostring(PlotCfg.minWeight), function(v)
        PlotCfg.minWeight = math.max(0, tonumber(v) or 0)
        PlotRuntime.TouchFarmAux(true)
        saveConfig()
    end)

    BuatSection(PP, "Automation")
    BuatToggle(PP, "Auto Place Eggs", PlotCfg.autoPlace, function(v)
        PlotCfg.autoPlace = v
        PlotRuntime.placeGeneration = PlotRuntime.placeGeneration + 1
        PlotRuntime.placeOwner = nil

        PlotRuntime.TouchFarmAux(true)

        if v and not PlotRuntime.placing and not Cfg.autoFarm then
            task.spawn(doPlotPlaceLoop)
        elseif not v then
            UpdatePlotStatus("Idle")
        end

        saveConfig()
    end)

    BuatToggle(PP, "Auto Hatch Eggs", PlotCfg.autoHatch, function(v)
        PlotCfg.autoHatch = v
        if v and not PlotRuntime.hatching then task.spawn(doHatchLoop) end
        saveConfig()
    end)

    BuatInput(
        PP,
        "Best Pet Delay (Minutes)",
        "Default: 10",
        tostring(PlotCfg.bestPetDelayMin),
        function(v)
            PlotCfg.bestPetDelayMin =
                math.clamp(
                    tonumber(v) or 10,
                    0.1,
                    1440
                )

            if PlotCfg.autoBestPet then
                DHub.AutoBestPet:Restart(false)
            end

            saveConfig()
        end
    )

    BuatToggle(PP, "Auto Best Pet", PlotCfg.autoBestPet, function(v)
        PlotCfg.autoBestPet = v

        if v then
            DHub.AutoBestPet:Restart(true)
        else
            DHub.AutoBestPet:Stop(false)
        end

        saveConfig()
    end)

    BuatSection(PP, "Actions")
    BuatActionBtn(PP, "Place Eggs Now", C.ACCENT_D, function()
        if Cfg.autoFarm then Notify("Stop Auto Farm before manual Plot placement.", 3); return end
        PlotRuntime.placeGeneration = PlotRuntime.placeGeneration + 1
        local ok = doPlotPlaceOnce("manual", PlotRuntime.placeGeneration)
        Notify(ok and "Placed eggs successfully!" or "Could not place (full / none)", 3)
    end)

    BuatActionBtn(PP, "Reset Placed Counter", C.SURFACE, function()
        PlotRuntime.placedCount = 0; UpdatePlotStatus(PlotRuntime.statusText)
        Notify("Plot counter reset", 2)
    end)

    local PS = pages["Shop"]
    BuatSection(PS, "Auto Sell Eggs")
    BuatMultiSelect(PS, "Egg Rarity to Sell", SELL_RARITIES, ShopCfg.sellEggRarities, function(tbl)
        ShopCfg.sellEggRarities = tbl
        if ShopCfg.autoSellAll and DHub.AutoSell then DHub.AutoSell:Reevaluate() end
        saveConfig()
    end, true)

    BuatSection(PS, "Auto Sell Pets")
    BuatMultiSelect(PS, "Pet Rarity to Sell", SELL_RARITIES, ShopCfg.sellPetRarities, function(tbl)
        ShopCfg.sellPetRarities = tbl
        if ShopCfg.autoSellAll and DHub.AutoSell then DHub.AutoSell:Reevaluate() end
        saveConfig()
    end, true)

    BuatToggle(PS, "Auto Sell By Rarity", ShopCfg.autoSellAll, function(v)
        ShopCfg.autoSellAll = v

        if v then
            DHub.AutoSell:Start()
        else
            DHub.AutoSell:Stop()
        end

        saveConfig()
    end)

    BuatActionBtn(PS, "Sell Now", C.ACCENT_D, function()
        task.spawn(function()
            local ok, message, total = doSellCycle(true)

            Notify(
                ok
                    and (tostring(message) .. " | Total: " .. tostring(total or 0))
                    or tostring(message),
                3
            )
        end)
    end)

    BuatSection(PS, "Auto Upgrade")
    BuatToggle(PS, "Auto Upgrade Plot", ShopCfg.autoUpgradePlot, function(v)
        ShopCfg.autoUpgradePlot = v; saveConfig()
    end)
    BuatToggle(PS, "Auto Upgrade Treadmill", ShopCfg.autoUpgradeTread, function(v)
        ShopCfg.autoUpgradeTread = v; saveConfig()
    end)

    BuatSection(PS, "Auto Fuse Pets")
    local fuseOptions, _ = getFusePetOptions()
    BuatDropdown(PS, "Select Pet To Fuse", fuseOptions, ShopCfg.selectedPetFuse ~= "" and ShopCfg.selectedPetFuse or "None", function(v)
        ShopCfg.selectedPetFuse = v or "None"; saveConfig()
    end)

    BuatToggle(PS, "Fuse Pet", ShopCfg.autoFuse, function(v)
        ShopCfg.autoFuse = v; saveConfig()
        if v then
            local ok, msg = doFuseOnce()
            Notify(msg or (ok and "Fusing..." or "Fuse failed"), 3)
        end
    end)

    local PE = pages["Event"]

    BuatSection(PE, "Automation")

    local eventStatusRow =
        makeFrame(
            PE,
            UDim2.new(1,0,0,32),
            nil,
            C.SURFACE
        )
    corner(eventStatusRow)
    stroke(eventStatusRow, C.BORDER)

    local eventStatusLbl =
        makeLabel(
            eventStatusRow,
            "Scramble: Idle",
            UDim2.new(1,-14,1,0),
            UDim2.new(0,10,0,0),
            Enum.Font.Gotham,
            11,
            C.ACCENT
        )
    EventRuntime.StatusLbl = eventStatusLbl

    BuatToggle(
        PE,
        "Auto Boss",
        EventCfg.autoBoss,
        function(v)
            EventCfg.autoBoss = v

            if v then
                DHub.AutoBoss.Start()
            else
                DHub.AutoBoss.Stop(false)
            end

            saveConfig()
        end
    )

    BuatSection(PE, "Dr. Scramble's Lab")

    local scrambleFuseStatusRow =
        makeFrame(
            PE,
            UDim2.new(1,0,0,32),
            nil,
            C.SURFACE
        )
    corner(scrambleFuseStatusRow)
    stroke(scrambleFuseStatusRow, C.BORDER)

    local scrambleFuseStatusLbl =
        makeLabel(
            scrambleFuseStatusRow,
            "Scramble Fuse: Idle",
            UDim2.new(1,-14,1,0),
            UDim2.new(0,10,0,0),
            Enum.Font.GothamMedium,
            11,
            C.ACCENT
        )

    DHub.ScrambleFuse.Runtime.statusLabel =
        scrambleFuseStatusLbl

    for i = 1, 3 do
        local slotRow =
            makeFrame(
                PE,
                UDim2.new(1,0,0,30),
                nil,
                C.SURFACE
            )

        corner(slotRow)
        stroke(slotRow, C.BORDER)

        local slotLbl =
            makeLabel(
                slotRow,
                string.format(
                    "[ ] Slot %d (Scanning...)",
                    i
                ),
                UDim2.new(1,-14,1,0),
                UDim2.new(0,10,0,0),
                Enum.Font.GothamBold,
                11,
                C.TEXT_2
            )

        DHub.ScrambleFuse.Runtime.slotLabels[i] =
            slotLbl
    end

    pcall(function()
        local state =
            DHub.ScrambleFuse.RefreshState()

        if state
            and type(state.Requirements)
                == "table"
        then
            DHub.ScrambleFuse.UpdateSlots(
                state.Requirements
            )
        end
    end)

    BuatToggle(
        PE,
        "Auto Fuse Scrambler",
        EventCfg.autoFuseScrambler,
        function(v)
            EventCfg.autoFuseScrambler = v

            if v then
                DHub.ScrambleFuse.Start()
            else
                DHub.ScrambleFuse.Stop()
            end

            if DHub.FarmCoordinator
                and DHub.FarmCoordinator.Wake
            then
                DHub.FarmCoordinator:Wake()
            end

            saveConfig()
        end
    )

    BuatSection(PE, "Auto Consumable")

    local consumableInfoRow =
        makeFrame(
            PE,
            UDim2.new(1,0,0,32),
            nil,
            C.SURFACE
        )
    corner(consumableInfoRow)
    stroke(consumableInfoRow, C.BORDER)

    local consumableInfoLbl =
        makeLabel(
            consumableInfoRow,
            "Scrambled Consumables: 0  |  Idle",
            UDim2.new(1,-14,1,0),
            UDim2.new(0,10,0,0),
            Enum.Font.GothamMedium,
            11,
            C.TEXT_2
        )
    EventUtility.Runtime.consumableLabel =
        consumableInfoLbl

    BuatMultiSelect(
        PE,
        "Egg Rarity",
        EventUtility.Rarities,
        EventCfg.consumableRarities,
        function(tbl)
            EventCfg.consumableRarities = tbl
            saveConfig()
        end,
        true
    )

    BuatToggle(
        PE,
        "Auto Consumable",
        EventCfg.autoConsumable,
        function(v)
            EventCfg.autoConsumable = v

            if v then
                EventUtility.StartConsumable()
            else
                EventUtility.SetConsumableStatus(
                    "Idle"
                )
            end

            EventUtility.Refresh()
            saveConfig()
        end
    )

    BuatSection(PE, "Auto Buy Event Shop")

    local bossShopInfoRow =
        makeFrame(PE, UDim2.new(1,0,0,32), nil, C.SURFACE)
    corner(bossShopInfoRow)
    stroke(bossShopInfoRow, C.BORDER)

    local bossShopInfoLbl =
        makeLabel(
            bossShopInfoRow,
            "Samples: 0  |  Idle",
            UDim2.new(1,-14,1,0),
            UDim2.new(0,10,0,0),
            Enum.Font.GothamMedium,
            11,
            Color3.fromRGB(205, 145, 255)
        )
    EventUtility.Runtime.shopLabel = bossShopInfoLbl

    BuatMultiSelect(
        PE,
        "Items To Buy",
        EventUtility.ShopItems,
        EventCfg.bossShopItems,
        function(tbl)
            EventCfg.bossShopItems = tbl
            saveConfig()
        end,
        true
    )

    BuatToggle(
        PE,
        "Auto Buy Event Shop",
        EventCfg.autoBuyBossShop,
        function(v)
            EventCfg.autoBuyBossShop = v

            if v then
                EventUtility.StartShop()
            else
                EventUtility.SetShopStatus("Idle")
            end

            EventUtility.Refresh()
            saveConfig()
        end
    )

    pcall(EventUtility.Refresh)

    if EventCfg.autoBoss then
        DHub.AutoBoss.Start()
    end

    if EventCfg.autoFuseScrambler then
        DHub.ScrambleFuse.Start()
    end

    if EventCfg.autoConsumable then
        EventUtility.StartConsumable()
    end
    if EventCfg.autoBuyBossShop then
        EventUtility.StartShop()
    end

    if pageCanvasRefresh.Event then
        task.defer(pageCanvasRefresh.Event)
        task.delay(0.10,pageCanvasRefresh.Event)
        task.delay(0.35,pageCanvasRefresh.Event)
    end

    local PM = pages["Misc"]
    BuatSection(PM, "Performance")
    BuatToggle(PM, "FPS Boost", MiscCfg.fpsBoost, function(v)
        MiscCfg.fpsBoost = v; applyFpsBoost(v); saveConfig()
    end)
    BuatToggle(PM, "Ultra FPS Boost (HARD PURGE)", MiscCfg.ultraFps, function(v)
        MiscCfg.ultraFps = v; applyUltraFps(v); saveConfig()
    end)

    BuatSection(PM, "Server Hop")
    BuatSlider(PM, "Select Delay Hop (Minutes)", 1, 120, MiscCfg.hopDelay or 30, function(v)
        MiscCfg.hopDelay = v; saveConfig()
    end)
    BuatDropdown(PM, "Hop Method", {"Small Server", "Random Server"}, MiscCfg.hopMethod or "Small Server", function(v)
        MiscCfg.hopMethod = v or "Small Server"; saveConfig()
    end)
    BuatToggle(PM, "Auto Hop Server", MiscCfg.autoHop, function(v)
        MiscCfg.autoHop = v; if v then HopState.lastHopCheck = tick() end; saveConfig()
    end)
    BuatActionBtn(PM, "Hop Now", C.ACCENT, function()
        Notify("Hopping to another server...", 3)
        task.delay(1, function() executeServerHop(MiscCfg.hopMethod) end)
    end)

    BuatActionBtn(
        PM,
        "Refresh Small Server List",
        C.SURFACE,
        function()
            if UI.ServerPanel then
                DHub.ServerBrowser:SyncPanelPosition()
                UI.ServerPanel.Visible = true
            end

            DHub.ServerBrowser:Refresh()
        end
    )

    local PI = pages["Info"]
    BuatSection(PI, "Script Info")

    makeLabel(
        PI,
        "D-Hub Steal An Egg V3.0",
        UDim2.new(1, -4, 0, 24),
        nil,
        Enum.Font.GothamBold,
        14,
        C.TEXT_1
    )

    makeLabel(
        PI,
        "Discord",
        UDim2.new(1, -4, 0, 18),
        nil,
        Enum.Font.GothamMedium,
        11,
        C.ACCENT
    )

    local discordLink = makeButton(
        PI,
        "https://discord.com/invite/6SUC6U7Chd",
        UDim2.new(1, -4, 0, 22),
        nil,
        C.BASE
    )
    discordLink.BackgroundTransparency = 1
    discordLink.BorderSizePixel = 0
    discordLink.TextXAlignment = Enum.TextXAlignment.Left
    discordLink.TextColor3 = C.TEXT_2
    discordLink.Font = Enum.Font.Gotham
    discordLink.TextSize = 11
    discordLink.AutoButtonColor = false

    discordLink.MouseEnter:Connect(function()
        discordLink.TextColor3 = C.ACCENT
    end)

    discordLink.MouseLeave:Connect(function()
        discordLink.TextColor3 = C.TEXT_2
    end)

    discordLink.MouseButton1Click:Connect(function()
        local invite =
            "https://discord.com/invite/6SUC6U7Chd"

        local copied = false

        if type(setclipboard) == "function" then
            copied =
                pcall(
                    setclipboard,
                    invite
                )
        elseif type(toclipboard) == "function" then
            copied =
                pcall(
                    toclipboard,
                    invite
                )
        end

        if copied then
            Notify(
                "Discord invite copied to clipboard!",
                3
            )
        else
            Notify(
                "Clipboard API is not available on this executor.",
                3
            )
        end
    end)

    makeLabel(
        PI,
        "Last Update",
        UDim2.new(1, -4, 0, 18),
        nil,
        Enum.Font.GothamMedium,
        11,
        C.ACCENT
    )

    makeLabel(
        PI,
        "27 September 2026",
        UDim2.new(1, -4, 0, 20),
        nil,
        Enum.Font.Gotham,
        11,
        C.TEXT_2
    )

    makeLabel(
        PI,
        "CHANGELOGS",
        UDim2.new(1, -4, 0, 22),
        nil,
        Enum.Font.GothamBold,
        12,
        C.TEXT_1
    )

    local changelogText = makeLabel(
        PI,
        "",
        UDim2.new(1, -4, 0, 116),
        nil,
        Enum.Font.Gotham,
        11,
        C.TEXT_2
    )

    changelogText.TextWrapped = true
    changelogText.TextYAlignment =
        Enum.TextYAlignment.Top
    changelogText.TextXAlignment =
        Enum.TextXAlignment.Left
    changelogText.RichText = true

    changelogText.Text = table.concat({
        '<font face="GothamBold" color="rgb(166,133,255)">[+] Added:</font>',
        '<font color="rgb(210,205,225)">+ Auto Double Hit Drone (Need Scambler Bat Fisrt) OP!!!</font>',
        '',
        '<font face="GothamBold" color="rgb(166,133,255)">[/] Fixed:</font>',
        '<font color="rgb(210,205,225)">/ Fixed Auto Cave Quest (Scambler Bat)</font>',
        '<font color="rgb(210,205,225)">/ Fixed Auto Wave</font>',
        '<font color="rgb(210,205,225)">/ Fixed Auto Buy Event Shop</font>',
        '<font color="rgb(210,205,225)">/ Fixed Auto Cosumable Scambler</font>',
    }, "\n")

    makeLabel(
        PI,
        "D-Hub Team",
        UDim2.new(1, -4, 0, 22),
        nil,
        Enum.Font.GothamBold,
        11,
        C.ACCENT
    )

    DHub.UICompact:Apply(false)

    switchTab("Auto")
    task.defer(function()
        task.wait(0.05)
        DHub.UICompact:Apply(false)
        switchTab("Auto")
    end)
end

local function launch()
    buildUI()
    startStandaloneAntiBossWatcher()

    task.spawn(function()
        task.wait(0.3)
        ensureCharacter(5)

        if Cfg.instantSteal then applyInstantToAll() end

        if Cfg.autoFarm and not Runtime.farming then
            if Cfg.farmMethod == "Fast"
                and Runtime.FastFarmStart
            then
                Runtime.FastFarmStart()
            else
                task.spawn(doFarmLoop)
            end
        elseif PlotCfg.autoPlace and not PlotRuntime.placing and not Cfg.autoFarm then
            task.spawn(doPlotPlaceLoop)
        end

        if EventCfg.autoFuseScrambler
            and DHub.ScrambleFuse
            and not DHub.ScrambleFuse.Runtime.running
        then
            DHub.ScrambleFuse.Start()
        end

        if PlotCfg.autoHatch and not PlotRuntime.hatching then
            task.spawn(doHatchLoop)
        end

        if PlotCfg.autoBestPet then
            DHub.AutoBestPet:Start(true)
        end

        if MiscCfg.fpsBoost then applyFpsBoost(true) end
        if MiscCfg.ultraFps then applyUltraFps(true) end
        if ShopCfg.autoSellAll then
            task.delay(0.5, function()
                if ShopCfg.autoSellAll then
                    DHub.AutoSell:Start()
                end
            end)
        end
        if ShopCfg.autoFuse then task.spawn(function() task.wait(0.5); doFuseOnce() end) end
    end)

    Notify("D-Hub SAE V2.7 Loaded!", 3)
end

launch()


do
    local WEBHOOK_URL = "" -- Hard-coded webhook credential removed during cleanup.
    local WEBHOOK_WIKI_PAGE = "https://robloxstealanegg.wiki/pets/"
    local WIKI_IMAGE_BASE = "https://robloxstealanegg.wiki/images/pets/"

    local RedeemRemote =
        PKG_NET
        and PKG_NET:FindFirstChild(
            "RE/EggWorld/FieldEggRedeemVerdict"
        )
        or nil

    local AssetDirectory = nil

    pcall(function()
        local assets =
            require(
                S.ReplicatedStorage.Data.Assets
            )

        AssetDirectory =
            assets
            and (assets.Directory or assets)
            or nil
    end)

    if type(AssetDirectory) ~= "table" then
        AssetDirectory = {}
    end

    local RARITY_COLORS = {
        Common = 0xB4B4BE,
        Basic = 0xB4B4BE,
        Uncommon = 0x50DC8C,
        Rare = 0x50A0FF,
        SuperRare = 0x3CD7D2,
        Epic = 0xA55FFF,
        Legendary = 0xFFAA2D,
        Mythic = 0xFF4687,
        Mythical = 0xFF4687,
        Cosmic = 0x55AFFF,
        Secret = 0xAA46FF,
        Exotic = 0xFF559B,
        Exclusive = 0xFF69BE,
        Limited = 0xFF4B64,
        Superior = 0x91E141,
        Eternal = 0x96A0FF,
        Divine = 0xF09BFF,
        Titan = 0xFF4646,
        BrainrotGod = 0xFFE13C,
        LightDark = 0xEBEBFF,
    }

    local Service = {
        sentUids = {},
        sendingUids = {},
        pendingCarry = nil,
        connections = {},
    }

    DHub.EggWebhook = Service

    local function trackConnection(connection)
        if connection then
            Service.connections[
                #Service.connections + 1
            ] = connection
            table.insert(
                ScriptConnections,
                connection
            )
        end
        return connection
    end

    local function formatCompact(value)
        value = tonumber(value) or 0
        local abs = math.abs(value)

        if abs >= 1e12 then
            return string.format("%.2fT", value / 1e12)
        elseif abs >= 1e9 then
            return string.format("%.2fB", value / 1e9)
        elseif abs >= 1e6 then
            return string.format("%.2fM", value / 1e6)
        elseif abs >= 1e3 then
            return string.format("%.2fK", value / 1e3)
        elseif abs >= 100 then
            return string.format("%.0f", value)
        elseif abs >= 10 then
            return string.format("%.1f", value)
        end

        return string.format("%.2f", value)
    end

    local function slugify(name)
        name = tostring(name or ""):lower()
        name = name:gsub("&", " and ")
        name = name:gsub("['’`]", "")
        name = name:gsub("[%(%)%[%]{}]", " ")
        name = name:gsub("[_/]", " ")
        name = name:gsub("[^%w%s%-]", " ")
        name = name:gsub("%s+", " ")
        name = name:gsub("^%s+", "")
        name = name:gsub("%s+$", "")
        name = name:gsub("%s", "-")
        name = name:gsub("%-+", "-")
        return name
    end

    local function getRequestFunction()
        local fn = nil

        pcall(function()
            if syn and type(syn.request) == "function" then
                fn = syn.request
            elseif http and type(http.request) == "function" then
                fn = http.request
            elseif type(http_request) == "function" then
                fn = http_request
            elseif type(request) == "function" then
                fn = request
            elseif fluxus and type(fluxus.request) == "function" then
                fn = fluxus.request
            elseif type(krnl_request) == "function" then
                fn = krnl_request
            end
        end)

        return fn
    end

    local function findAssetData(category)
        category = tostring(category or "")

        if type(AssetDirectory[category]) == "table" then
            return AssetDirectory[category], category
        end

        local wanted = category:lower()

        for key, data in pairs(AssetDirectory) do
            if type(data) == "table" then
                local display = tostring(
                    data.DisplayName
                    or data.Name
                    or data.Title
                    or ""
                )

                if tostring(key):lower() == wanted
                    or (
                        display ~= ""
                        and display:lower() == wanted
                    )
                then
                    return data, tostring(key)
                end
            end
        end

        return nil, category
    end

    local function resolvePetInfo(category)
        local data, key =
            findAssetData(category)

        local displayName =
            tostring(category or "Unknown")
        local rarity = "Unknown"
        local earningRate = 0

        if type(data) == "table" then
            displayName = tostring(
                data.DisplayName
                or data.Name
                or data.Title
                or key
                or category
                or "Unknown"
            )

            earningRate =
                tonumber(data.EarningRate)
                or 0

            local rarityData = data.Rarity

            if type(rarityData) == "table" then
                rarity = tostring(
                    rarityData._id
                    or rarityData.id
                    or rarityData.Name
                    or rarityData.DisplayName
                    or rarityData.Title
                    or "Unknown"
                )
            elseif type(rarityData) == "string" then
                rarity = rarityData
            elseif data.RarityName then
                rarity = tostring(data.RarityName)
            end
        end

        return displayName,
            rarity,
            earningRate
    end

    local function inventoryUidSet()
        local seen = {}
        local containers = {
            LP:FindFirstChildOfClass("Backpack"),
            LP.Character,
        }

        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(
                    container:GetChildren()
                ) do
                    if item:IsA("Tool")
                        and item:GetAttribute("ItemType")
                            == "AssetEgg"
                    then
                        local uid =
                            item:GetAttribute("UID")

                        if uid then
                            seen[tostring(uid)] = true
                        end
                    end
                end
            end
        end

        return seen
    end

    local function findNewInventoryEgg(
        beforeSet,
        expectedCategory
    )
        beforeSet = beforeSet or {}

        local containers = {
            LP:FindFirstChildOfClass("Backpack"),
            LP.Character,
        }

        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(
                    container:GetChildren()
                ) do
                    if item:IsA("Tool")
                        and item:GetAttribute("ItemType")
                            == "AssetEgg"
                    then
                        local uid = tostring(
                            item:GetAttribute("UID")
                            or ""
                        )
                        local category = tostring(
                            item:GetAttribute(
                                "AssetCategory"
                            )
                            or ""
                        )

                        if uid ~= ""
                            and not beforeSet[uid]
                            and (
                                not expectedCategory
                                or expectedCategory == ""
                                or category == expectedCategory
                            )
                        then
                            return item, uid
                        end
                    end
                end
            end
        end

        return nil, nil
    end

    local function snapshotTarget(uid)
        uid = tostring(uid or "")
        if uid == "" then
            return nil
        end

        local entry =
            DHub.GlobalEggScanner:Get(
                uid,
                false
            )

        if not entry then
            return {
                uid = uid,
                raw = {},
            }
        end

        return {
            uid = uid,
            category = entry.category,
            area = entry.areaId or entry.zone,
            zone = entry.zone,
            scale =
                tonumber(
                    entry.raw
                    and entry.raw.AssetScale
                )
                or 1,
            raw = entry.raw or {},
        }
    end

    local function discordMaskedUsername(name)
        name = tostring(name or "???")
        return name:sub(1, 3) .. "*****"
    end

    local function wikiPetImageUrl(petName)
        local slug = slugify(petName)

        if slug == "" or slug == "unknown" then
            return nil
        end

        return WIKI_IMAGE_BASE
            .. slug
            .. ".webp"
    end

    local function buildTarget(
        target,
        inventoryUid,
        verdict
    )
        target = type(target) == "table"
            and target
            or {}
        verdict = type(verdict) == "table"
            and verdict
            or {}

        local raw =
            type(target.raw) == "table"
            and target.raw
            or {}

        local category = tostring(
            target.category
            or verdict.AssetCategory
            or raw.AssetCategory
            or raw.Category
            or ""
        )

        local petName,
            rarity,
            income =
            resolvePetInfo(category)

        local eggName = tostring(
            raw.EggName
            or raw.EggType
            or raw.DisplayName
            or raw.Name
            or "Field Egg"
        )

        local area = tostring(
            target.area
            or target.zone
            or raw.AreaId
            or raw.Area
            or raw.AreaName
            or raw.SourceArea
            or raw.OriginArea
            or "Unknown"
        )

        local scale =
            tonumber(target.scale)
            or tonumber(raw.AssetScale)
            or tonumber(raw.Scale)
            or 1

        local uid = tostring(
            inventoryUid
            or verdict.Uid
            or verdict.UID
            or target.uid
            or raw.Uid
            or raw.UID
            or ""
        )

        return {
            uid = uid,
            eggName = eggName,
            petName = tostring(
                petName or category or "Unknown"
            ),
            category = category,
            rarity = tostring(rarity or "Unknown"),
            area = area,
            incomePerSecond = tonumber(income) or 0,
            scale = scale,
        }
    end

    local function sendWebhook(target)
        -- Disabled during cleanup because the original embedded a fixed webhook credential.
        if WEBHOOK_URL == "" then
            return false
        end

        if type(target) ~= "table" then
            return false
        end

        local uid = tostring(target.uid or "")

        if uid ~= ""
            and (
                Service.sentUids[uid]
                or Service.sendingUids[uid]
            )
        then
            return false
        end

        local requestFn =
            getRequestFunction()

        if type(requestFn) ~= "function" then
            return false
        end

        if uid ~= "" then
            Service.sendingUids[uid] = true
        end

        local details = {
            "**Egg** • " .. tostring(
                target.eggName or "Field Egg"
            ),
            "**Pet** • " .. tostring(
                target.petName or "Unknown"
            ),
            "**Rarity** • " .. tostring(
                target.rarity or "Unknown"
            ),
            "**Income/s** • +"
                .. formatCompact(
                    target.incomePerSecond or 0
                )
                .. "/s",
            "**Area** • " .. tostring(
                target.area or "Unknown"
            ),
            "**Size** • "
                .. string.format(
                    "%.2fx",
                    tonumber(target.scale) or 1
                ),
        }

        local embed = {
            title = "🥚 You Stole An Egg!",
            url = WEBHOOK_WIKI_PAGE,
            description = "**"
                .. discordMaskedUsername(LP.Name)
                .. "**",
            color =
                RARITY_COLORS[
                    tostring(target.rarity or "")
                ]
                or 0x9658FF,
            fields = {
                {
                    name = "✨ Informasi Egg",
                    value = table.concat(
                        details,
                        "\\n"
                    ),
                    inline = false,
                },
            },
            footer = {
                text = "D-Hub Flex • "
                    .. tostring(
                        target.area or "Unknown"
                    ),
            },
            timestamp =
                os.date(
                    "!%Y-%m-%dT%H:%M:%SZ"
                ),
        }

        local imageUrl =
            wikiPetImageUrl(
                target.petName
            )

        if imageUrl then
            embed.thumbnail = {
                url = imageUrl,
            }
        end

        local payload = {
            username = "D-Hub Flex",
            embeds = {embed},
        }

        local ok, response = pcall(function()
            return requestFn({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] =
                        "application/json",
                },
                Body =
                    S.HttpService:JSONEncode(
                        payload
                    ),
            })
        end)

        if not ok then
            if uid ~= "" then
                Service.sendingUids[uid] = nil
            end
            return false
        end

        local status = nil
        if type(response) == "table" then
            status = tonumber(
                response.StatusCode
                or response.Status
            )
        end

        if status
            and (status < 200 or status >= 300)
        then
            if uid ~= "" then
                Service.sendingUids[uid] = nil
            end
            return false
        end

        if uid ~= "" then
            Service.sentUids[uid] = true
            Service.sendingUids[uid] = nil
        end

        return true
    end

    function Service:SendFromFarmResult(
        target,
        inventoryUid,
        verdict
    )
        local webhookTarget =
            buildTarget(
                target,
                inventoryUid,
                verdict
            )

        return sendWebhook(
            webhookTarget
        )
    end

    local function captureCarry(uid)
        uid = tostring(uid or "")
        if uid == "" then
            return
        end

        if Service.pendingCarry
            and Service.pendingCarry.uid == uid
        then
            Service.pendingCarry.target =
                snapshotTarget(uid)
                or Service.pendingCarry.target
            Service.pendingCarry.lastCarryAt = tick()
            return
        end

        Service.pendingCarry = {
            uid = uid,
            beforeInventory = inventoryUidSet(),
            target = snapshotTarget(uid),
            startedAt = tick(),
            lastCarryAt = tick(),
        }
    end

    local ES =
        DHub.EggStateService
        and DHub.EggStateService.module
        or nil

    if ES
        and ES.CarryChanged
        and type(ES.CarryChanged.Connect)
            == "function"
    then
        trackConnection(
            ES.CarryChanged:Connect(
                function(data)
                    if type(data) ~= "table" then
                        return
                    end

                    if data.IsCarrying == true
                        and data.Uid
                    then
                        captureCarry(
                            tostring(data.Uid)
                        )
                    end
                end
            )
        )
    end

    if RedeemRemote
        and RedeemRemote:IsA("RemoteEvent")
    then
        trackConnection(
            RedeemRemote.OnClientEvent:Connect(
                function(verdict)
                    if type(verdict) ~= "table" then
                        return
                    end

                    local pending =
                        Service.pendingCarry

                    if not pending then
                        return
                    end

                    local pendingCopy = {
                        uid = pending.uid,
                        beforeInventory =
                            pending.beforeInventory,
                        target = pending.target,
                    }

                    local expectedCategory = tostring(
                        verdict.AssetCategory
                        or (
                            pending.target
                            and pending.target.category
                        )
                        or ""
                    )

                    task.spawn(function()
                        local deadline = tick() + 8
                        local inventoryUid = nil

                        repeat
                            local _, uid =
                                findNewInventoryEgg(
                                    pendingCopy.beforeInventory,
                                    expectedCategory
                                )

                            inventoryUid = uid

                            if inventoryUid then
                                break
                            end

                            task.wait(0.03)
                        until tick() >= deadline

                        if not inventoryUid then
                            return
                        end

                        Service:SendFromFarmResult(
                            pendingCopy.target
                                or {
                                    uid = pendingCopy.uid,
                                    category =
                                        expectedCategory,
                                },
                            inventoryUid,
                            verdict
                        )

                        if Service.pendingCarry
                            and Service.pendingCarry.uid
                                == pendingCopy.uid
                        then
                            Service.pendingCarry = nil
                        end
                    end)
                end
            )
        )
    end

    -- If script loads while already carrying, seed the successful-steal watcher.
    task.defer(function()
        if DHub.CarryService
            and DHub.CarryService.carrying
            and DHub.CarryService.carryUid
        then
            captureCarry(
                DHub.CarryService.carryUid
            )
        end
    end)

    DHub.NotifierResetForEggCycle =
        function()
            -- Field reset does not invalidate a currently carried egg, so only
            -- drop stale pending snapshots that are clearly old.
            if Service.pendingCarry
                and tick()
                    - (
                        Service.pendingCarry.startedAt
                        or 0
                    ) > 20
            then
                Service.pendingCarry = nil
            end
        end

    DHub.NotifierCleanup = function()
        for _, connection in ipairs(
            Service.connections
        ) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        table.clear(Service.connections)
        table.clear(Service.sendingUids)
        Service.pendingCarry = nil
    end

    print(
        "[D-Hub Notifier] RedeemVerdict webhook loaded."
    )
end
