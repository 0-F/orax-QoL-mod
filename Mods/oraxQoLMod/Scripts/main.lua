require("helper")

modName = "oraxQoLMod"
print(modName .. " init\n")

-- alternative values for some variables
-- These values can be set in "options.txt".
Alt = {}

IsInteractTimerModEnabled = true
IsZiplineModEnabled = true

PlayerWalkSpeed = nil
PlayerSwimSpeed = nil

ZiplineIgnoreCollisionDistance = nil
ZiplineMaxSpeedMultiplier = nil
ZiplineExitVelocityMultiplier = nil
ZiplineAscendAccel = nil
ZiplineMaxAscendSpeed = nil

SmallHoTEffect_TimeElapsed = nil

InfiniteItemPower = nil

StorageRadius = nil
TypeRestrictedStorageRadius = nil

CancelUnderConstructionBuildingsKey = nil
CancelUnderConstructionBuildingsModifierKey = nil

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
  if IsInteractTimerModEnabled == true then
    if InteractTimerMax ~= nil then LocalPlayerCharacter.InteractTimerMax = InteractTimerMax end
    if DropInteractTimerMax ~= nil then LocalPlayerCharacter.DropInteractTimerMax = DropInteractTimerMax end
    if CancelInteractTimerMax ~= nil then LocalPlayerCharacter.CancelInteractTimerMax = CancelInteractTimerMax end 
  end
end

local function ToggleInteractTimerMod()
  IsInteractTimerModEnabled = not IsInteractTimerModEnabled

  if IsInteractTimerModEnabled == true then
    ShowMessage("InteractTimerMod: init")
    SetupInteractTimerMod()
  else
    -- restore default game values if alternative values is not set in options.txt
    ShowMessage("InteractTimerMod: restore default or alternative values")
    LocalPlayerCharacter.InteractTimerMax = Alt.InteractTimerMax
    LocalPlayerCharacter.DropInteractTimerMax = Alt.DropInteractTimerMax
    LocalPlayerCharacter.CancelInteractTimerMax = Alt.CancelInteractTimerMax
  end
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
  IsZiplineModEnabled = not IsZiplineModEnabled

  local moveComp = LocalPlayerCharacter.CharMovementComponent

  if IsZiplineModEnabled == true then
    ShowMessage("ZiplineMod: init", cache.icon_Zipline)
    SetupZiplineMod()
  else
    -- restore default game values if alternative values is not set in options.txt
    ShowMessage("ZiplineMod: restore default or alternative values", cache.icon_Zipline)
    moveComp.ZiplineIgnoreCollisionDistance = Alt.ZiplineIgnoreCollisionDistance
    moveComp.ZiplineMaxSpeedMultiplier = Alt.ZiplineMaxSpeedMultiplier
    moveComp.ZiplineExitVelocityMultiplier = Alt.ZiplineExitVelocityMultiplier
    moveComp.ZiplineAscendAccel = Alt.ZiplineAscendAccel
    moveComp.ZiplineMaxAscendSpeed = Alt.ZiplineMaxAscendSpeed
  end
end

-- cancel under construction buildings
-- Same function you have in game Menu > Game Repair > Cancel Nearby Blueprints,
-- but for the whole world (not only nearby).
local function CancelUnderConstructionBuildings()
  ShowMessage("Cancel 'under construction' buildings", cache.icon_CancelBuild)

  local buildingInstances = FindAllOf("Building")
  local buildingClass = StaticFindObject("/Script/Maine.Building")

  if not buildingInstances then
      print("No instances of 'Building' were found\n")
      ShowMessage("No buildings were found", cache.icon_CancelBuild)
  else
    for index, building in pairs(buildingInstances) do
      if building:IsA(buildingClass) and building.BuildingState == EBuildingState.UnderConstruction then
        local name = building:GetName():ToString()

        print(string.format("%s: [%d] Cancel (%s) %s\n", ModName, index, name, building:GetFullName()))
        ShowMessage(name, cache.icon_CancelBuild)

        building:CancelBuild(LocalPlayerCharacter)
      end
    end
  end
end

local function UpdatePlayer(player)
  if not player:IsValid() then
    print("Player instance not found\n")
    return
  end

  LocalPlayerCharacter = player
  local moveComp = player.CharMovementComponent

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

  -- get default game values if alternative values is not set in options.txt
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
  -- "Interact timer"
  if Alt.InteractTimerMax == nil then Alt.InteractTimerMax = player.InteractTimerMax end
  if Alt.DropInteractTimerMax == nil then Alt.DropInteractTimerMax = player.DropInteractTimerMax end
  if Alt.CancelInteractTimerMax == nil then Alt.CancelInteractTimerMax = player.CancelInteractTimerMax end

  SetupZiplineMod()
  SetupInteractTimerMod()
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

-- infinite power (for torch) - https://grounded.fandom.com/wiki/Category:Tools/Light
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

--
-- keybinds
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

if CancelUnderConstructionBuildingsKey ~= nil then
  if CancelUnderConstructionBuildingsModifierKeys ~= nil then
    RegisterKeyBind(CancelUnderConstructionBuildingsKey, CancelUnderConstructionBuildingsModifierKeys, CancelUnderConstructionBuildings)
  else
    RegisterKeyBind(CancelUnderConstructionBuildingsKey, CancelUnderConstructionBuildings)
  end
end
