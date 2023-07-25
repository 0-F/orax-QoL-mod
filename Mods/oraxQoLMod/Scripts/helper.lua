--[[
  Some code come from QoL mod created by TheLich:
  Configurable QoL mod - https://www.nexusmods.com/grounded/mods/82
]]

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

cache = {}
cache.objects = {}
cache.names = {
  ["engine"] = {"Engine", false},
  ["uiStatics"] = {"/Script/Maine.Default__UserInterfaceStatics", true},
  ["gameStatics"] = {"/Script/Maine.Default__SurvivalGameplayStatics", true},
  ["kismet"] = {"/Script/Engine.Default__KismetSystemLibrary", true},
  ["icon_Build"] = {"/Game/UI/Images/T_UI_Build.T_UI_Build", true},
  ["icon_Zipline"] = {"/Game/Blueprints/Items/Icons/ICO_BLDG_Zipline_Anchor.ICO_BLDG_Zipline_Anchor", true},
  ["icon_CancelBuild"] = {"/Game/UI/Images/ActionIcons/T_UI_CancelBuild.T_UI_CancelBuild", true}
}

cache.mt = {}
cache.mt.__index = function (obj, key)
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

local function PostPlayerChatMessage(message)
  local engine = cache.engine
  local uiStatics = cache.uiStatics
  local gameStatics = cache.gameStatics
  if uiStatics and gameStatics then
    local ui = uiStatics:GetGameUI(engine.GameViewport)
    local state = gameStatics:GetLocalSurvivalPlayerState(engine.GameViewport)
    ui:PostPlayerChatMessage(message, state)
  end
end
