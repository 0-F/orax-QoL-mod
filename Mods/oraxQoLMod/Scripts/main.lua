require("helper")

modName = "oraxQoLMod"
print(modName .. " init\n")

-- alternative values for some variables
-- These values can be set in "options.txt".
Alt = {}

IsInteractTimerModEnabled = false
IsZiplineModEnabled = false
IsBuildAnywhereEnabled = false

-- hook variables
PreIdBuildAnywhere = 0
PostIdBuildAnywhere = 0

-- Enum /Script/Maine.EBuildingState
EBuildingState = { 
  None = 0,
  Built = 1,
  BeingPlaced = 2,
  BeingPlacedInvalid = 3,
  UnderConstruction = 4,
  Cancelled = 5,
  Destroyed = 6,
  CollapseDestroy = 7
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
  CollapseDestroy = 7
}

dofile([[Mods\oraxQoLMod\options.txt]])

local LocalPlayerCharacter = nil

function SetupInteractTimerMod()
  if InteractTimerMax ~= nil then LocalPlayerCharacter.InteractTimerMax = InteractTimerMax end
  if DropInteractTimerMax ~= nil then LocalPlayerCharacter.DropInteractTimerMax = DropInteractTimerMax end
  if CancelInteractTimerMax ~= nil then LocalPlayerCharacter.CancelInteractTimerMax = CancelInteractTimerMax end 
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

local function SetupZiplineMod()
  local moveComp = LocalPlayerCharacter.CharMovementComponent

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
    SetupZiplineMod()
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

  local count = survivalGameplayStatics:GetCancelNearbyBlueprintsCount(LocalPlayerCharacter, CancelNearbyBlueprintsRange)
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

local function UpdatePlayer(player)
  if not player:IsValid() then
    print("Player instance not found\n")
    return
  end

  LocalPlayerCharacter = player
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
  if Alt.InteractTimerMax == nil then Alt.InteractTimerMax = player.InteractTimerMax end
  if Alt.DropInteractTimerMax == nil then Alt.DropInteractTimerMax = player.DropInteractTimerMax end
  if Alt.CancelInteractTimerMax == nil then Alt.CancelInteractTimerMax = player.CancelInteractTimerMax end

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
  SetupInteractTimerMod()
  IsInteractTimerModEnabled = true

  -- "Zipline"
  SetupZiplineMod()
  IsZiplineModEnabled = true
end

NotifyOnNewObject("/Script/Maine.SurvivalPlayerCharacter", function(player)
  ExecuteWithDelay(2000, function() 
    UpdatePlayer(player)
  end)
end) 

-- Handy Gnat
NotifyOnNewObject("/Script/Maine.BuilderMovementComponent", function(builder)
  ExecuteWithDelay(1000, function() 
    if HandyGnatMaxFlySpeed ~= nil then builder.MaxFlySpeed = HandyGnatMaxFlySpeed end
    if HandyGnatMaxAcceleration ~= nil then builder.MaxAcceleration = HandyGnatMaxAcceleration end
    if HandyGnatBrakingFrictionFactor ~= nil then builder.BrakingFrictionFactor = HandyGnatBrakingFrictionFactor end
    if HandyGnatBrakingFriction ~= nil then builder.BrakingFriction = HandyGnatBrakingFriction end
    if HandyGnatBrakingSubStepTime ~= nil then builder.BrakingSubStepTime = HandyGnatBrakingSubStepTime end
    if HandyGnatBrakingDecelerationFlying ~= nil then builder.BrakingDecelerationFlying = HandyGnatBrakingDecelerationFlying end
  end)

end)

-- https://grounded.fandom.com/wiki/Status_Effects#Trickle_Regen
if SmallHoTEffect_TimeElapsed ~= nil then
  RegisterHook("/Script/Maine.StatusEffect:GetDataHandle", function(self)
    local effect = self:get()

    if effect.StatusEffectRowHandle.RowName:ToString() == "SmallHoT" then
      effect.TimeElapsed = -82800 -- 82800 seconds = 23 hours
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

-- Build anywhere
if ToggleBuildAnywhereModKey ~= nil then
  RegisterHook("/Script/Maine.Building:UpdateCollisionStateChange", function(self)
    if not IsBuildAnywhereEnabled then return end

    local building = self:get()
    if building.BuildingState == EBuildingState.BeingPlacedInvalid then
      building.BuildingState = EBuildingState.BeingPlaced
    end
  end)
end

function ToggleBuildAnywhereMod()  
  if IsBuildAnywhereEnabled then
    ShowMessage("Disable BuildAnywhere")
  else
    ShowMessage("Enable BuildAnywhere")
  end

  IsBuildAnywhereEnabled = not IsBuildAnywhereEnabled
end

-- Pause/unpause the game
function ToggleGamePaused()
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
    RegisterKeyBind(ToggleBuildAnywhereModKey, ToggleBuildAnywhere)
  end
end

if ToggleGamePausedKey ~= nil then
  if ToggleGamePausedModifierKeys ~= nil then
    RegisterKeyBind(ToggleGamePausedKey, ToggleGamePausedModifierKeys, ToggleGamePaused)
  else
    RegisterKeyBind(ToggleGamePausedKey, ToggleGamePaused)
  end
end
