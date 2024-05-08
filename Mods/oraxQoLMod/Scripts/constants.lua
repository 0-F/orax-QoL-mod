--- @enum EInteractionChannel
EInteractionChannel = {
  Primary = 0,
  Primary_Hold = 1,
  Cancel = 2,
  Cancel_Hold = 3,
  LightFire = 4,
  Drop = 5,
  Drop_Hold = 6,
  Relocate = 7,
  Customize = 8,
  Pick = 9,
  Count = 10,
  EInteractionChannel_MAX = 11
}

---@enum EInteractionState
EInteractionState = {
  Hidden = 0,
  Disabled = 1,
  Enabled = 2,
  Indeterminate = 3,
  EInteractionState_MAX = 4
}

---@enum EInteractionType
EInteractionType = {
  None = 0,
  Pickup = 1,
  Eat = 2,
  Drink = 3,
  Cook = 4,
  Rest = 5,
  PlaceBuilding = 6,
  AddIngredient = 7,
  LightFire = 8,
  InventoryFull = 9,
  Drying = 10,
  InvalidPlayer = 11,
  Equip = 12,
  Cancel = 13,
  UnableToLightFire = 14,
  Storage = 15,
  Conversation = 16,
  Revive = 17,
  MissingIngredients = 18,
  Busy = 19,
  StartZiplineConnection = 20,
  ZiplineZip = 21,
  Mount = 22,
  CannotHaul = 23,
  Climb = 24,
  Pet = 25,
  PetHome = 26,
  ConfigureSign = 27,
  SpinningWheel = 28,
  Turret = 29,
  EInteractionType_MAX = 30
}

-- Enum /Script/Maine.EPlayerStatType
EPlayerStatType = {
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

StackSize = {
  Default = 10,
  Ammo = 20,
  Single = 1,
  Food = 5,
  Resource = 10,
  LargeResource = 5,
  UpgradeStones = 99
}
