--[[
  Credits
    The original QoL mod for Grounded was created by TheLich:
    https://www.nexusmods.com/grounded/mods/82 (Configurable QoL mod)
]] --
ModName = "oraxQoLMod"
print(ModName .. " init\n")

if OptionsFile == nil then
  OptionsFile = string.format("Mods\\%s\\options.txt", ModName)
end

IsFirstInit = true

Debug = {}

-- alternative values for some variables
-- These values can be set in "options.txt".
Alt = {}

IsInteractTimerModEnabled = false
IsZiplineModEnabled = false
IsBuildAnywhereEnabled = false
IsDropModEnabled = false

-- hook variables
PreIdBuildAnywhere = 0
PostIdBuildAnywhere = 0

-- Enum /Script/Maine.EPlayerStatType
local EPlayerStatType = {
  None = 0,
  Kill = 1,
  CraftItem = 2,
  PickupItem = 3,
  Revive = 4,
  Discover = 5,
  Stamina = 6,
  BasketballShot = 7,
  TamePet = 8,
  ProcessItem = 9,
  ZiplineDistance = 10,
  UseItem = 11,
  Block = 12,
  Scripted = 13,
  TakePhoto = 14,
  RangedAttack = 15,
  DefensePoint = 16,
  Death = 17,
  Coziness = 18,
  EPlayerStatType_MAX = 19
}

-- Enum /Script/Maine.EBuildingState
EBuildingState = {
  None = 0,
  Built = 1,
  BeingPlaced = 2,
  BeingPlacedInvalid = 3,
  UnderConstruction = 4,
  Cancelled = 5,
  Destroyed = 6,
  CollapseDestroy = 7,
  EBuildingState_MAX = 8
}

-- Enum /Script/Maine.EBuildingGridSurfaceType
EBuildingGridSurfaceType = {
  None = 0,
  Invalid = 1,
  Water = 4,
  Default = 7,
  EBuildingGridSurfaceType_MAX = 8
}

DisableFOG = false
DisableDOF = false

AOEPickupMode = 1

StackSize = {
  Default = 10,
  Ammo = 20,
  Single = 1,
  Food = 5,
  Resource = 10,
  LargeResource = 5,
  UpgradeStones = 99
}

DropAmountMultiplier = {}
DropChanceMin = {}

dofile(OptionsFile)

local LocalPlayerCharacter = nil
local playerEffects = {}
local nodeUpdated = {}
local initEvent = false
local calendarComponent = nil
local gameToRealTimeRatio = 30

cache = {}
cache.objects = {}
cache.names = {
  ["engine"] = {"Engine", false},
  ["uiStatics"] = {"/Script/Maine.Default__UserInterfaceStatics", true},
  ["survivalGameplayStatics"] = {"/Script/Maine.Default__SurvivalGameplayStatics", true},
  ["gameplayStatics"] = {"/Script/Engine.Default__GameplayStatics", true},
  ["kismet"] = {"/Script/Engine.Default__KismetSystemLibrary", true},
  ["icon_Build"] = {"/Game/UI/Images/T_UI_Build.T_UI_Build", true},
  ["icon_Sleep"] = {"/Game/UI/Images/FlagIcons/T_UI_Flag_Sleep.T_UI_Flag_Sleep", true},
  ["icon_Zipline"] = {"/Game/Blueprints/Items/Icons/ICO_BLDG_Zipline_Anchor.ICO_BLDG_Zipline_Anchor", true},
  ["icon_CancelBuild"] = {"/Game/UI/Images/ActionIcons/T_UI_CancelBuild.T_UI_CancelBuild", true}
}

cache.mt = {}
cache.mt.__index = function(obj, key)
  local newObj = obj.objects[key]
  if newObj == nil or not newObj:IsValid() then
    local className, isStatic = table.unpack(obj.names[key])
    if isStatic then
      newObj = StaticFindObject(className)
    else
      newObj = FindFirstOf(className)
    end
    if not newObj:IsValid() then
      newObj = nil
    end
    obj.objects[key] = newObj
  end
  return newObj
end

setmetatable(cache, cache.mt)

function printf(...)
  print(string.format(...))
end

function ShowMessage(message, icon)
  local engine = cache.engine
  local uiStatics = cache.uiStatics
  if icon == nil then
    icon = cache.icon_Build -- default icon
  end
  if uiStatics and icon then
    local ui = uiStatics:GetGameUI(engine.GameViewport)
    ui:PostGenericMessage(message, icon)
  end
end

function PostPlayerChatMessage(message)
  local engine = cache.engine
  local uiStatics = cache.uiStatics
  local survivalGameplayStatics = cache.survivalGameplayStatics
  if uiStatics and survivalGameplayStatics then
    local ui = uiStatics:GetGameUI(engine.GameViewport)
    local state = survivalGameplayStatics:GetLocalSurvivalPlayerState(engine.GameViewport)
    ui:PostPlayerChatMessage(message, state)
  end
end

local function SetupInteractTimerMod(player)
  if InteractTimerMax ~= nil then
    player.InteractTimerMax = InteractTimerMax
  end
  if DropInteractTimerMax ~= nil then
    player.DropInteractTimerMax = DropInteractTimerMax
  end
  if CancelInteractTimerMax ~= nil then
    player.CancelInteractTimerMax = CancelInteractTimerMax
  end
end

local function ToggleInteractTimerMod()
  if IsInteractTimerModEnabled then
    -- restore default game values if alternative values is not set in options.txt
    LocalPlayerCharacter.InteractTimerMax = Alt.InteractTimerMax
    LocalPlayerCharacter.DropInteractTimerMax = Alt.DropInteractTimerMax
    LocalPlayerCharacter.CancelInteractTimerMax = Alt.CancelInteractTimerMax
  else
    SetupInteractTimerMod()
  end

  ShowMessage("InteractTimerMax = " .. LocalPlayerCharacter.InteractTimerMax)
  ShowMessage("DropInteractTimerMax = " .. LocalPlayerCharacter.DropInteractTimerMax)
  ShowMessage("CancelInteractTimerMax = " .. LocalPlayerCharacter.CancelInteractTimerMax)

  IsInteractTimerModEnabled = not IsInteractTimerModEnabled
end

local function SetupZiplineMod(player)
  local moveComp = player.CharMovementComponent

  if ZiplineIgnoreCollisionDistance ~= nil then
    moveComp.ZiplineIgnoreCollisionDistance = ZiplineIgnoreCollisionDistance
  end
  if ZiplineMaxSpeedMultiplier ~= nil then
    moveComp.ZiplineMaxSpeedMultiplier = ZiplineMaxSpeedMultiplier
  end
  if ZiplineExitVelocityMultiplier ~= nil then
    moveComp.ZiplineExitVelocityMultiplier = ZiplineExitVelocityMultiplier
  end
  if ZiplineAscendAccel ~= nil then
    moveComp.ZiplineAscendAccel = ZiplineAscendAccel
  end
  if ZiplineMaxAscendSpeed ~= nil then
    moveComp.ZiplineMaxAscendSpeed = ZiplineMaxAscendSpeed
  end
end

local function ToggleZiplineMod()
  local moveComp = LocalPlayerCharacter.CharMovementComponent

  if IsZiplineModEnabled then
    -- restore default game values if alternative values is not set in options.txt
    ShowMessage("ZiplineMod: restore default or alternative values", cache.icon_Zipline)
    moveComp.ZiplineIgnoreCollisionDistance = Alt.ZiplineIgnoreCollisionDistance
    moveComp.ZiplineMaxSpeedMultiplier = Alt.ZiplineMaxSpeedMultiplier
    moveComp.ZiplineExitVelocityMultiplier = Alt.ZiplineExitVelocityMultiplier
    moveComp.ZiplineAscendAccel = Alt.ZiplineAscendAccel
    moveComp.ZiplineMaxAscendSpeed = Alt.ZiplineMaxAscendSpeed
  else
    ShowMessage("ZiplineMod: enable", cache.icon_Zipline)
    SetupZiplineMod(LocalPlayerCharacter)
  end

  ShowMessage("IgnoreCollisionDistance = " .. moveComp.ZiplineIgnoreCollisionDistance, cache.icon_Zipline)
  ShowMessage("MaxSpeedMultiplier = " .. moveComp.ZiplineMaxSpeedMultiplier, cache.icon_Zipline)
  ShowMessage("ExitVelocityMultiplier = " .. moveComp.ZiplineExitVelocityMultiplier, cache.icon_Zipline)
  ShowMessage("AscendAccel = " .. moveComp.ZiplineAscendAccel, cache.icon_Zipline)
  ShowMessage("MaxAscendSpeed =" .. moveComp.ZiplineMaxAscendSpeed, cache.icon_Zipline)

  IsZiplineModEnabled = not IsZiplineModEnabled
end

-- cancel nearby blueprints (under construction buildings)
-- Same function you have in game Menu > Game Repair > Cancel Nearby Blueprints,
-- but with a custom range.
local function CancelNearbyBlueprints()
  local survivalGameplayStatics = cache.survivalGameplayStatics

  if not CancelNearbyBlueprintsRange then
    ShowMessage("You need to set a range", cache.icon_CancelBuild)
    return
  end

  local count =
    survivalGameplayStatics:GetCancelNearbyBlueprintsCount(LocalPlayerCharacter, CancelNearbyBlueprintsRange)
  print(tostring(count))
  if count == 0 then
    ShowMessage("No nearby blueprints were found", cache.icon_CancelBuild)
    return
  end

  local text = "Cancel %s nearby blueprint"
  if count > 1 then
    text = text .. "s" -- plural
  end
  ShowMessage(string.format(text, count), cache.icon_CancelBuild)
  survivalGameplayStatics:CancelNearbyBlueprints(LocalPlayerCharacter, CancelNearbyBlueprintsRange)
end

local function SetDayTimeMultiplier(isDayTime)
  if calendarComponent == nil or not calendarComponent:IsValid() then
    return
  end
  local multiplier = 1
  if DayLengthMultiplier ~= nil and isDayTime then
    multiplier = math.abs(DayLengthMultiplier) ^
                   ((DayLengthMultiplier > 0 and 1 or 0) - (DayLengthMultiplier < 0 and 1 or 0))
  elseif NightLengthMultiplier ~= nil and not isDayTime then
    multiplier = math.abs(NightLengthMultiplier) ^
                   ((NightLengthMultiplier > 0 and 1 or 0) - (NightLengthMultiplier < 0 and 1 or 0))
  end
  calendarComponent.GameToRealTimeRatio = gameToRealTimeRatio / multiplier
end

local function UpdatePlayer(player)
  if not player:IsValid() then
    print("Player instance not found\n")
    return
  end

  local moveComp = player.CharMovementComponent

  -- get default game values if alternative values are not set in options.txt
  --
  -- "Zipline"
  if Alt.ZiplineIgnoreCollisionDistance == nil then
    Alt.ZiplineIgnoreCollisionDistance = moveComp.ZiplineIgnoreCollisionDistance
  end
  if Alt.ZiplineMaxSpeedMultiplier == nil then
    Alt.ZiplineMaxSpeedMultiplier = moveComp.ZiplineMaxSpeedMultiplier
  end
  if Alt.ZiplineExitVelocityMultiplier == nil then
    Alt.ZiplineExitVelocityMultiplier = moveComp.ZiplineExitVelocityMultiplier
  end
  if Alt.ZiplineAscendAccel == nil then
    Alt.ZiplineAscendAccel = moveComp.ZiplineAscendAccel
  end
  if Alt.ZiplineMaxAscendSpeed == nil then
    Alt.ZiplineMaxAscendSpeed = moveComp.ZiplineMaxAscendSpeed
  end
  --
  -- "Interactions"
  if Alt.InteractTimerMax == nil then
    Alt.InteractTimerMax = player.InteractTimerMax
  end
  if Alt.DropInteractTimerMax == nil then
    Alt.DropInteractTimerMax = player.DropInteractTimerMax
  end
  if Alt.CancelInteractTimerMax == nil then
    Alt.CancelInteractTimerMax = player.CancelInteractTimerMax
  end

  --
  -- set custom values
  --

  -- "Proximity inventory storage radius"
  if StorageRadius ~= nil then
    player.ProximityInventoryComponent.StorageRadius = StorageRadius
  end
  if TypeRestrictedStorageRadius ~= nil then
    player.ProximityInventoryComponent.TypeRestrictedStorageRadius = TypeRestrictedStorageRadius
  end

  -- "Player walk speed"
  if PlayerWalkSpeed ~= nil then
    if PlayerWalkSpeed == -1 then
      moveComp.MaxWalkSpeed = moveComp.MaxSprintSpeed
    end

    if PlayerWalkSpeed > 0 then
      moveComp.MaxWalkSpeed = PlayerWalkSpeed
    end
  end

  -- "Player swim speed"
  if PlayerSwimSpeed ~= nil then
    if PlayerSwimSpeed == -1 then
      moveComp.MaxSwimSpeed = moveComp.MaxSwimSprintSpeed
    end

    if PlayerSwimSpeed > 0 then
      moveComp.MaxSwimSpeed = PlayerSwimSpeed
    end
  end

  -- "Interactions"
  if InteractTraceLength ~= nil then
    player.InteractTraceLength = InteractTraceLength
  end
  if BuildModeInteractionRangeMultiplier ~= nil then
    player.BuildModeInteractionRangeMultiplier = BuildModeInteractionRangeMultiplier
  end
  SetupInteractTimerMod(player)
  IsInteractTimerModEnabled = true

  -- "Zipline"
  SetupZiplineMod(player)
  IsZiplineModEnabled = true

  if HaulingCapacity ~= nil then
    player.HaulingComponent.Capacity = HaulingCapacity
  end

  if PerfectBlockWindow ~= nil then
    player.BlockComponent.PerfectBlockWindow = PerfectBlockWindow
  end

  if PlayerSprintSpeedMultiplier ~= nil then
    player.CharMovementComponent.MaxSprintSpeed = player.CharMovementComponent.MaxSprintSpeed *
                                                    PlayerSprintSpeedMultiplier
  end

  if PlayerSwimSpeedMultiplier ~= nil then
    player.CharMovementComponent.MaxSwimSprintSpeed = player.CharMovementComponent.MaxSwimSprintSpeed *
                                                        PlayerSwimSpeedMultiplier
  end
end

local function UpdateGlobalItemData(globalItemData)
  if not globalItemData:IsValid() then
    print("GlobalItemData instance not found\n")
    return
  end

  if AttackDurability ~= nil then
    globalItemData.AttackDurability = AttackDurability
  end

  if BlockDurability ~= nil then
    globalItemData.BlockDurability = BlockDurability
  end

  if ThrowDurability ~= nil then
    globalItemData.ThrowDurability = ThrowDurability
  end

  if ArmorHitDurability ~= nil then
    globalItemData.ArmorHitDurability = ArmorHitDurability
  end

  if ItemUseCooldown ~= nil then
    globalItemData.ItemUseCooldown = ItemUseCooldown
  end

  if ProductionSpeedMultiplier ~= nil then
    globalItemData.ProcessingData:ForEach(function(idx)
      local itemData = globalItemData.ProcessingData[idx]
      local itemDataTag = itemData.ProcessingTag.TagName:ToString()
      if itemDataTag == "ItemProcessing.Cooking" or itemDataTag == "ItemProcessing.Drying" then
        itemData.ProcessingTime = itemData.ProcessingTime / math.max(0.01, ProductionSpeedMultiplier)
      end
    end)
  end

  -- Stack size
  if StackSizeModIsEnabled == true then
    local stackSizeValue =
      '(((TagName="StackSize.Default"),$Default),((TagName="StackSize.Ammo"),$Ammo),((TagName="StackSize.Single"),$Single),((TagName="StackSize.Food"),$Food),((TagName="StackSize.Resource"),$Resource),((TagName="StackSize.LargeResource"),$LargeResource),((TagName="StackSize.UpgradeStones"),$UpgradeStones))'

    stackSizeValue = string.gsub(stackSizeValue, "%$(%w+)", StackSize)

    local property = globalItemData:Reflection():GetProperty("StackSizes")

    if property:IsValid() then
      property:ImportText(stackSizeValue, property:ContainerPtrToValuePtr(globalItemData), 0, globalItemData)
    else
      print("Can't find 'StackSizes' property.\n")
    end
  end

  -- Stack bonus
  if ItemStackBonusPerTier ~= nil then
    globalItemData.ItemStackBonusPerTier = ItemStackBonusPerTier
  end
  if MaxItemStackTier ~= nil then
    globalItemData.MaxItemStackTier = MaxItemStackTier
  end
  if MaxDropStackSize ~= nil then
    globalItemData.MaxDropStackSize = MaxDropStackSize
  end
end

local function UpdateGameState(gameState)
  if not gameState:IsValid() then
    print("GameState instance not found\n")
    return
  end

  calendarComponent = gameState.CalendarComponent
  if DayLengthMultiplier ~= nil or NightLengthMultiplier ~= nil then
    SetDayTimeMultiplier(calendarComponent:IsDayTime())
  end
end

local function UpdateModeSettings(gameModeManager)
  if not gameModeManager:IsValid() then
    print("GameModeManager instance not found\n")
    return
  end

  local modeSettings = gameModeManager:GetGameModeSettings()
  local CDO = modeSettings:GetClass():GetCDO()
  if CDO:IsValid() then
    if HungerAndThirstMultiplier ~= nil then
      CDO.HungerAndThirstMultiplier = HungerAndThirstMultiplier
    end

    if PlayerDamageMultiplier ~= nil then
      CDO.PlayerDamageMultiplier = PlayerDamageMultiplier
    end

    if EnemyDamageMultiplier ~= nil then
      CDO.EnemyDamageMultiplier = EnemyDamageMultiplier
    end

    if BuildingHealthMultiplier ~= nil then
      CDO.BuildingHealthMultiplier = BuildingHealthMultiplier
    end

    if HeatMultiplier ~= nil then
      CDO.HeatMultiplier = HeatMultiplier
    end

    if ItemSpoilageMultiplier ~= nil then
      CDO.ItemSpoilageMultiplier = ItemSpoilageMultiplier
    end

    if ItemDurabilityMultiplier ~= nil then
      CDO.ItemDurabilityMultiplier = ItemDurabilityMultiplier
    end

    if ItemDurabilityPenaltyOnDeathPercentage ~= nil then
      CDO.ItemDurabilityPenaltyOnDeathPercentage = ItemDurabilityPenaltyOnDeathPercentage
    end

    if SizzleMultiplier ~= nil then
      CDO.SizzleMultiplier = SizzleMultiplier -- 0.1
    end
  end
end

if AOEPickupRadius ~= nil and AOEPickupKey ~= nil then
  local pickupClass = StaticFindObject("/Script/Maine.SpawnedItem")
  local dropletClass = StaticFindObject("/Script/Maine.SpawnedItemDroplet")
  local plankClass = nil
  local logClass = nil
  local picking = false
  local items = {}
  local pickupModes = {"All", "Items only", "Logs&PLanks only"}

  local function PickupMode()
    AOEPickupMode = (AOEPickupMode % 3) + 1
    ShowMessage("Pickup mode: " .. pickupModes[AOEPickupMode])
  end

  local function ValidForPickup(item)
    if item:IsA(dropletClass) then
      return false
    end
    if AOEPickupMode == 1 then
      return true
    end
    if AOEPickupMode == 2 and (item:IsA(plankClass) or item:IsA(logClass)) then
      return false
    end
    if AOEPickupMode == 3 and not (item:IsA(plankClass) or item:IsA(logClass)) then
      return false
    end
    return true
  end

  local function LookForPickupNearby()
    if not LocalPlayerCharacter or not LocalPlayerCharacter:IsValid() then
      print("LocalPlayerCharacter is invalid.\n")
      return
    end

    if not plankClass or not plankClass:IsValid() then
      plankClass = StaticFindObject("/Game/Blueprints/Items/World/Harvested/BP_World_GrassPlank.BP_World_GrassPlank_C")
    end

    if not logClass or not logClass:IsValid() then
      logClass = StaticFindObject("/Game/Blueprints/Items/World/Harvested/BP_World_Log.BP_World_Log_C")
    end

    picking = true
    local engine = cache.engine
    local kismet = cache.kismet
    local types = {1}
    local pos = LocalPlayerCharacter:K2_GetActorLocation()
    local results = {}
    items = {}
    if kismet:SphereOverlapActors(engine.GameViewport, pos, AOEPickupRadius, types, pickupClass, nil, results) then
      for _, value in ipairs(results) do
        local item = value:get()
        if item and item:IsValid() and ValidForPickup(item) then
          table.insert(items, item)
        end
      end
    end
    picking = false
  end

  local function PickupLoop()
    if not LocalPlayerCharacter or not LocalPlayerCharacter:IsValid() then
      return
    end

    if #items > 0 and not picking then
      local item = table.remove(items)
      if item and item:IsValid() then
        if item.Interact:IsValid() then
          item:Interact(0, LocalPlayerCharacter)
        else
          if LocalPlayerCharacter:TryPickupItem(item.Item, false) then
            item:DelayedDestroy()
          end
        end
      end
    end
  end

  local function PickupEvent()
    if #items == 0 and not picking then
      LookForPickupNearby()
    end
  end

  if AOEPickupModifierKey ~= nil then
    RegisterKeyBind(AOEPickupKey, {AOEPickupModifierKey}, PickupEvent)
  else
    RegisterKeyBind(AOEPickupKey, PickupEvent)
  end

  if AOEPickupModeKey ~= nil then
    if AOEPickupModeModifierKey ~= nil then
      RegisterKeyBind(AOEPickupModeKey, {AOEPickupModeModifierKey}, PickupMode)
    else
      RegisterKeyBind(AOEPickupModeKey, PickupMode)
    end
  end

  RegisterHook("/Script/Maine.SurvivalGameState:GetActiveBossForPlayer", PickupLoop)
end

local function OnFirstInit()

  local partyComponent = cache.survivalGameplayStatics:GetPartyComponent(cache.engine.GameViewport)

  -- Raw Science
  --
  -- fix negative value of ScienceFound (current Raw Science)
  -- valid values: 0 to 2147483647
  if partyComponent.ScienceFound < 1 then
    partyComponent.ScienceFound = 0
  end
  --
  -- Science Amount Max
  if ScienceAmountMultiplier ~= nil or ScienceAmountMax ~= nil then
    local signedInt32Max = 2147483647

    -- valid values: 0 to 2147483647
    if ScienceAmountMax == nil then
      ScienceAmountMax = signedInt32Max
    elseif ScienceAmountMax < 0 then
      ScienceAmountMax = 0
    elseif ScienceAmountMax > signedInt32Max then
      ScienceAmountMax = signedInt32Max
    else
      ScienceAmountMax = math.min(signedInt32Max, ScienceAmountMax)
    end

    RegisterHook("/Script/Maine.PartyComponent:ServerAddScienceFound", function(self, ScienceAmount)
      local partyComponent = self:get()
      local added = ScienceAmount:get()

      -- bugged cases
      if partyComponent.ScienceFound < 0 or added < 0 then
        partyComponent.ScienceFound = ScienceAmountMax
        ScienceAmount:set(0)
        return
      end

      if ScienceAmountMultiplier ~= nil then
        local addedNew = math.min(partyComponent.ScienceFound + added * ScienceAmountMultiplier, ScienceAmountMax) -
                           partyComponent.ScienceFound
        ScienceAmount:set(addedNew)
      end
    end)

    RegisterHook(
      "/Game/UI/HUD/Notifications/UI_ScienceFoundNotification.UI_ScienceFoundNotification_C:OnScienceChanged",
      function(self, scienceAdded, totalScience)
        -- /Script/Maine.PartyComponent:OnScienceFoundChangedDelegate => (UI_ScienceFoundNotification.OnScienceChanged)
        local added = scienceAdded:get()
        local total = totalScience:get()

        if total < added or total < 0 or total > ScienceAmountMax then
          partyComponent.ScienceFound = ScienceAmountMax
        end
      end)
  end
end

local function Init()
  LocalPlayerCharacter = nil

  ExecuteWithDelay(2000, function()
    local survivalGameplayStatics = cache.survivalGameplayStatics
    local engine = cache.engine
    if not engine or not survivalGameplayStatics then
      print("Engine or SurvivalGameplayStatics instance not found\n")
      return
    end

    local gameModeManager = survivalGameplayStatics:GetSurvivalGameModeManager(engine.GameViewport)
    local gameState = survivalGameplayStatics:GetSurvivalGameState(engine.GameViewport)
    local globalItemData = survivalGameplayStatics:GetGlobalItemData()

    UpdateGlobalItemData(globalItemData)
    UpdateGameState(gameState)
    UpdateModeSettings(gameModeManager)

    if IsFirstInit == true then
      OnFirstInit()
    end

    IsFirstInit = false

    print(ModName .. " init done\n")
  end)
end

NotifyOnNewObject("/Script/Maine.SurvivalPlayerCharacter", function(player)
  playerEffects[player:GetFullName()] = player.StatusEffectComponent:GetValueForStat(EPlayerStatType.ProcessItem)

  ExecuteWithDelay(2000, function()
    if player.InputComponent:IsValid() then
      LocalPlayerCharacter = player
    end
    UpdatePlayer(player)
  end)
end)

-- Handy Gnat
NotifyOnNewObject("/Script/Maine.BuilderMovementComponent", function(builder)
  ExecuteWithDelay(1000, function()
    if HandyGnatMaxFlySpeed ~= nil then
      builder.MaxFlySpeed = HandyGnatMaxFlySpeed
    end
    if HandyGnatMaxAcceleration ~= nil then
      builder.MaxAcceleration = HandyGnatMaxAcceleration
    end
    if HandyGnatBrakingFrictionFactor ~= nil then
      builder.BrakingFrictionFactor = HandyGnatBrakingFrictionFactor
    end
    if HandyGnatBrakingFriction ~= nil then
      builder.BrakingFriction = HandyGnatBrakingFriction
    end
    if HandyGnatBrakingSubStepTime ~= nil then
      builder.BrakingSubStepTime = HandyGnatBrakingSubStepTime
    end
    if HandyGnatBrakingDecelerationFlying ~= nil then
      builder.BrakingDecelerationFlying = HandyGnatBrakingDecelerationFlying
    end
  end)

end)

-- Bird (Crow)
if BirdLandedTimeLowerBound ~= nil or BirdLandedTimeUpperBound ~= nil or BirdTimeBetweenSpawnsLowerBound ~= nil or
  BirdTimeBetweenSpawnsUpperBound ~= nil or BirdFlySpeed ~= nil then
  NotifyOnNewObject("/Script/Maine.Bird", function(self)
    ExecuteWithDelay(2000, function()
      self.LandedTime.LowerBound.Value = BirdLandedTimeLowerBound -- default: 120.0
      self.LandedTime.UpperBound.Value = BirdLandedTimeUpperBound -- default: 300.0

      self.TimeBetweenSpawns.LowerBound.Value = BirdTimeBetweenSpawnsLowerBound -- default: 400.0
      self.TimeBetweenSpawns.UpperBound.Value = BirdTimeBetweenSpawnsUpperBound -- default: 800.0

      self.FlySpeed = BirdFlySpeed -- 20000.0
    end)
  end)
end

-- https://grounded.fandom.com/wiki/Status_Effects#Trickle_Regen
if SmallHoTEffect_TimeElapsed ~= nil then
  RegisterHook("/Script/Maine.StatusEffect:GetDataHandle", function(self)
    local effect = self:get()

    if effect.StatusEffectRowHandle.RowName:ToString() == "SmallHoT" then
      effect.TimeElapsed = SmallHoTEffect_TimeElapsed
    end
  end)
end
if SmallHoTEffect_TimeElapsed__2 ~= nil then
  RegisterHook("/Script/Maine.HealthComponent:OnStatusEffectChanged", function(self, owner, statusEffect)
    local effect = statusEffect:get()

    if effect.StatusEffectRowHandle.RowName:ToString() == "SmallHoT" then
      effect.TimeElapsed = SmallHoTEffect_TimeElapsed__2
    end
  end)
end

-- Infinite power (for torch) - https://grounded.fandom.com/wiki/Category:Tools/Light
if InfiniteItemPower == true then
  RegisterHook("/Script/Maine.Item:GetIsPowerOn", function(self)
    local item = self:get()

    ExecuteWithDelay(2000, function()
      if item:IsValid() then
        item.IsPowerOn = false
        item.PowerUsed = 0.0
      end
    end)
  end)
end
if InfiniteItemPower__2 == true then
  RegisterHook("/Script/Maine.Item:GetPowerPercentage", function(self)
    return 1.0
  end)
end

-- Production
if MaxProductionItems ~= nil then
  NotifyOnNewObject("/Script/Maine.ProductionBuilding", function(building)
    building.MaxProductionItems = MaxProductionItems
  end)
end

-- Build anywhere
if ToggleBuildAnywhereModKey ~= nil then
  RegisterHook("/Script/Maine.Building:UpdateCollisionStateChange", function(self)
    if not IsBuildAnywhereEnabled then
      return
    end

    local building = self:get()

    if building.AnchoredSurface == EBuildingGridSurfaceType.None or building.AnchoredSurface ==
      EBuildingGridSurfaceType.Invalid then
      building.AnchoredSurface = EBuildingGridSurfaceType.Default
    end

    if building.BuildingState == EBuildingState.BeingPlacedInvalid then
      building.BuildingState = EBuildingState.BeingPlaced
    end
  end)
end

-- Build anywhere
local function ToggleBuildAnywhereMod()
  if IsBuildAnywhereEnabled then
    ShowMessage("Disable BuildAnywhere")
  else
    ShowMessage("Enable BuildAnywhere")
  end

  IsBuildAnywhereEnabled = not IsBuildAnywhereEnabled
end

-- Pause/unpause the game
local function ToggleGamePaused()
  local pause
  local gameplayStatics = cache.gameplayStatics

  if gameplayStatics:IsGamePaused(LocalPlayerCharacter) then
    pause = false
    ShowMessage("Game unpaused", cache.icon_Sleep)
  else
    pause = true
    ShowMessage("Game paused", cache.icon_Sleep)
  end

  gameplayStatics:SetGamePaused(LocalPlayerCharacter, pause)

  return pause
end

-- Drop mod (loot)
local function ToggleDropMod()
  IsDropModEnabled = not IsDropModEnabled

  if IsDropModEnabled then
    ShowMessage("Drop mod enabled")
  else
    ShowMessage("Drop mod disabled")
  end
end

if LogStorageCapacity ~= nil or PlankStorageCapacity ~= nil or LargePlankStorageCapacity ~= nil or
  LargeLogStorageCapacity ~= nil then
  NotifyOnNewObject("/Script/Maine.TypeRestrictedStorageBuilding", function(createdObject)
    if LogStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_LogStorage.BP_LogStorage_C") then
      createdObject.Capacity = LogStorageCapacity
    elseif PlankStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_PlankStorage.BP_PlankStorage_C") then
      createdObject.Capacity = PlankStorageCapacity
    elseif LargePlankStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_PlankStorage_Tier3.BP_PlankStorage_Tier3_C") then
      createdObject.Capacity = LargePlankStorageCapacity
    elseif LargeLogStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_LogStorage_Tier3.BP_LogStorage_Tier3_C") then
      createdObject.Capacity = LargeLogStorageCapacity
    end
  end)
end

if SmallStorageCapacity ~= nil or BigStorageCapacity ~= nil or LargeStorageCapacity ~= nil or FridgeStorageCapacity ~=
  nil then
  NotifyOnNewObject("/Script/Maine.StorageBuilding", function(createdObject)
    if SmallStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_Storage.BP_Storage_C") then
      createdObject.InventoryComponent.MaxSize = SmallStorageCapacity
    elseif BigStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_Storage_Big.BP_Storage_Big_C") then
      createdObject.InventoryComponent.MaxSize = BigStorageCapacity
    elseif LargeStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_Storage_Tier3.BP_Storage_Tier3_C") then
      createdObject.InventoryComponent.MaxSize = LargeStorageCapacity
    elseif FridgeStorageCapacity ~= nil and
      createdObject:IsA("/Game/Blueprints/Items/Buildings/Storage/BP_StorageFridge.BP_StorageFridge_C") then
      createdObject.InventoryComponent.MaxSize = FridgeStorageCapacity
    end
  end)
end

if DewCollectorAmountPerHour ~= nil then
  NotifyOnNewObject("/Script/Maine.FaucetBuilding", function(createdObject)
    if createdObject:IsA("/Game/Blueprints/Items/Buildings/BP_DewCollector.BP_DewCollector_C") then
      createdObject.FillAmountPerHour = DewCollectorAmountPerHour
    end
  end)
end

NotifyOnNewObject("/Script/Maine.ZiplineAnchorBuilding", function(createdObject)
  if createdObject:IsA("/Game/Blueprints/Items/Buildings/BP_GroundZiplineAnchor_Fixed.BP_GroundZiplineAnchor_Fixed_C") then
    createdObject.bPlayerCanInteract = true
  end
end)

if MaxActiveMutations ~= nil then
  NotifyOnNewObject("/Script/Maine.SurvivalPlayerState", function(createdObject)
    if createdObject:IsA("/Game/Blueprints/Player/BP_SurvivalPlayerState.BP_SurvivalPlayerState_C") then
      createdObject.PerkComponent.MaxEquippedPerks = MaxActiveMutations
    end
  end)
end

if IsDropModEnabled then
  local function setDropValues(lootComponent, dropAmountMultiplier, dropChanceMin)
    lootComponent.Items:ForEach(function(index)
      -- item is a ScriptStruct /Script/Maine.LootData
      local item = lootComponent.Items[index]
      local itemName = item.ItemData.RowName:ToString()

      if ItemsDropAmountMultiplier[itemName] ~= nil then
        dropAmountMultiplier = ItemsDropAmountMultiplier[itemName]
      end
      if ItemsDropChanceMin[itemName] ~= nil then
        dropChanceMin = ItemsDropChanceMin[itemName]
      end

      if dropAmountMultiplier ~= nil then
        item.Count = math.floor(item.Count * dropAmountMultiplier)
      end
      if dropChanceMin ~= nil and item.DropChance < dropChanceMin then
        item.DropChance = math.min(1, dropChanceMin)
      end

      if Debug.drop then
        printf("item=%s dropAmountMultiplier=%s dropChanceMin=%s\n", itemName, dropAmountMultiplier, dropChanceMin)
      end
    end)
  end

  local function debugDrop(lootComponent, name)
    local text = string.format("Creature/resource name: %s\n", name)

    lootComponent.Items:ForEach(function(index, elem)
      local item = elem:get()
      local itemName = item.ItemData.RowName:ToString()

      text = text .. string.format("- Item %s: %s\n", index, itemName)

      text = text .. string.format("    Count: %s\n", item.Count)
      text = text .. string.format("    DropChance: %s\n", item.DropChance)
    end)

    return text
  end

  RegisterHook("/Script/Maine.LootComponent:OnDeath", function(self)
    if not IsDropModEnabled then
      return
    end

    local lootComponent = self:get()
    local fname = lootComponent:GetOuter():GetFName():ToString()
    local name = fname

    -- clean the FName
    -- ex: "BP_Mushroom_Toadstool_B_C_2147421672" -> Mushroom_Toadstool
    name = string.gsub(name, "_%w%f[_]", "") -- _A followed by _ -> _
    name = string.gsub(name, "_%d+$", "") -- _123456789 -> ""
    name = string.gsub(name, "^BP_", "") -- BP_ -> ""

    -- global values
    local dropAmountMultiplier = GlobalDropAmountMultiplier
    local dropChanceMin = GlobalDropChanceMin

    -- values specific to creatures and non-creatures
    -- the multiplier applies on all items of the (non-)creature
    --[[
      example:
        DropAmountMultiplier = {
          Aphid = 0 -- creature name
        }
    ]]
    if type(DropAmountMultiplier[name]) == "number" then
      dropAmountMultiplier = DropAmountMultiplier[name]
    end
    if type(DropChanceMin[name]) == "number" then
      dropChanceMin = DropChanceMin[name]
    end

    local debugText
    if Debug.drop then
      debugText = debugDrop(lootComponent, name)
      printf("Drop table (original) for %s\n", fname)
      print(debugText)
    end

    -- values specific to items than creatures and non-creatures can drop
    --[[
      example:
        DropAmountMultiplier = {
          Aphid = {       -- creature name
            AphidMeat = 0 -- item name
          }
        }
    ]]
    lootComponent.Items:ForEach(function(index, elem)
      -- item is a ScriptStruct /Script/Maine.LootData
      local item = elem:get()
      local itemName = item.ItemData.RowName:ToString()
      local itemDropAmountMultiplier = dropAmountMultiplier
      local itemDropChanceMin = dropChanceMin

      if type(DropAmountMultiplier[name]) == "table" and DropAmountMultiplier[name][itemName] ~= nil then
        itemDropAmountMultiplier = DropAmountMultiplier[name][itemName]
      end
      if type(DropChanceMin[name]) == "table" and DropChanceMin[name][itemName] ~= nil then
        itemDropChanceMin = DropChanceMin[name][itemName]
      end

      if itemDropAmountMultiplier ~= nil and itemDropAmountMultiplier ~= 1 and itemName ~= "None" then
        item.Count = math.floor(item.Count * itemDropAmountMultiplier)
      end
      if itemDropChanceMin ~= nil and itemDropChanceMin ~= -1 and item.DropChance < itemDropChanceMin then
        item.DropChance = math.min(1, itemDropChanceMin)
      end
    end)

    if Debug.drop then
      local debugText2 = debugDrop(lootComponent, name)

      if debugText == debugText2 then
        printf("Drop table is not modified for %s\n", fname)
      else
        printf("Drop table (modified) for %s\n", fname)
        print(debugText2)
      end
    end
  end)
end

if DeconstructPercentage ~= nil then
  NotifyOnNewObject("/Script/Maine.Building", function(building)
    building.DropIngredientsPercentage = math.min(1, DeconstructPercentage)
  end)
end

if ProductionSpeedMultiplier ~= nil or ProductionItems ~= nil then
  NotifyOnNewObject("/Script/Maine.ProductionBuilding", function(createdObject)
    if ProductionSpeedMultiplier ~= nil then
      createdObject.ProductionTime = createdObject.ProductionTime / math.max(0.01, ProductionSpeedMultiplier)
    end
    if ProductionItems ~= nil then
      createdObject.MaxSimulateousItems = math.max(1, math.min(createdObject.MaxProductionItems, ProductionItems))
    end
  end)
end

local characterClass = StaticFindObject("/Script/Maine.SurvivalPlayerCharacter")
if HaulingCapacity ~= nil then
  RegisterHook("/Script/Maine.HaulingComponent:OnStatusEffectChanged", function(self)
    local component = self:get()
    local character = component:GetOuter()
    if character:IsA(characterClass) then
      playerEffects[character:GetFullName()] = character.StatusEffectComponent:GetValueForStat(
        EPlayerStatType.ProcessItem)
    end
  end)
  RegisterHook("/Script/Maine.HaulingComponent:GetAdjustedCapacity", function(self)
    local component = self:get()
    local parent = component:GetOuter()
    if parent:IsA(characterClass) then
      local capacity = playerEffects[parent:GetFullName()]
      if type(capacity) == "number" then
        return HaulingCapacity + capacity
      end
      return HaulingCapacity
    end
  end)
end

if DisableFOG or DisableDOF then
  NotifyOnNewObject("/Script/Maine.TimeOfDayLightingManager", function(createdObject)
    if DisableFOG then
      createdObject.FogMultiplierRandom = 0
    end
    if DisableDOF then
      createdObject.DOF = false
    end
  end)
end

if DayLengthMultiplier ~= nil or NightLengthMultiplier ~= nil then
  RegisterHook("/Script/Maine.ZoneManagerComponent:OnDayNightChange", function(self, isDayParam)
    local isDay = isDayParam:get()
    SetDayTimeMultiplier(isDay)
  end)
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", Init)

--
-- Keybinds
--

if ToggleZiplineModKey ~= nil then
  if ToggleZiplineModModifierKeys ~= nil then
    RegisterKeyBind(ToggleZiplineModKey, ToggleZiplineModModifierKeys, ToggleZiplineMod)
  else
    RegisterKeyBind(ToggleZiplineModKey, ToggleZiplineMod)
  end
end

if ToggleInteractTimerModKey ~= nil then
  if ToggleInteractTimerModModifierKeys ~= nil then
    RegisterKeyBind(ToggleInteractTimerModKey, ToggleInteractTimerModModifierKeys, ToggleInteractTimerMod)
  else
    RegisterKeyBind(ToggleInteractTimerModKey, ToggleInteractTimerMod)
  end
end

if CancelNearbyBlueprintsKey ~= nil then
  if CancelNearbyBlueprintsModifierKeys ~= nil then
    RegisterKeyBind(CancelNearbyBlueprintsKey, CancelNearbyBlueprintsModifierKeys, CancelNearbyBlueprints)
  else
    RegisterKeyBind(CancelNearbyBlueprintsKey, CancelNearbyBlueprints)
  end
end

if ToggleBuildAnywhereModKey ~= nil then
  if ToggleBuildAnywhereModModifierKeys ~= nil then
    RegisterKeyBind(ToggleBuildAnywhereModKey, ToggleBuildAnywhereModModifierKeys, ToggleBuildAnywhereMod)
  else
    RegisterKeyBind(ToggleBuildAnywhereModKey, ToggleBuildAnywhereMod)
  end
end

if ToggleGamePausedKey ~= nil then
  if ToggleGamePausedModifierKeys ~= nil then
    RegisterKeyBind(ToggleGamePausedKey, ToggleGamePausedModifierKeys, ToggleGamePaused)
  else
    RegisterKeyBind(ToggleGamePausedKey, ToggleGamePaused)
  end
end

if IsDropModEnabled then
  if ToggleDropModKey ~= nil then
    if ToggleDropModModifierKeys ~= nil then
      RegisterKeyBind(ToggleDropModKey, ToggleDropModModifierKeys, ToggleDropMod)
    else
      RegisterKeyBind(ToggleDropModKey, ToggleDropMod)
    end
  end
end
