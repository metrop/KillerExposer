if SERVER then return end

local ok, failed, package = pcall(function() return trygetpackage("KillerExposer") end)
if not package then
    print("[KillerExposer] Error: package path not found")
    return 
end

local Configs = {
    isEnabled = nil,
}

local inspectedCorpses = {}
local originalNames = {}

local function getValueConfig(key, typeName, configKey)
    local ok, success, config = pcall(function()
        return ConfigService.TryGetConfig(SettingBase[typeName], package, key)
    end)
    
    if ok and success and config then
        Configs[configKey] = config.Value
        pcall(function()
            config.OnValueChanged.add(function(changed)
                local successChanged, current = pcall(function() return changed.Value end)
                if successChanged and current ~= nil then
                    Configs[configKey] = current
                    print(string.format("Config value '%s' successfully changed to %s!", key, tostring(current)))
                end
            end)
        end)
    else
        print("[KillerExposer] Error: " .. key .. " (ok=" .. tostring(ok) .. ", success=" .. tostring(success) .. ")")
    end
end

getValueConfig("EnableKillerExposer", "Boolean", "isEnabled")

Hook.Add("roundStart", "ClearInspectedCorpses", function()
    inspectedCorpses = {}
end)

Hook.Add("think", "KillerExposerDrawKiller", function()
    if not Game.RoundStarted or not Configs.isEnabled then return end

    for id, cleanName in pairs(originalNames) do
        local char = Entity.FindEntityByID(id)
        if char and not char.Removed and not char.IsDead then
            if char.Info then
                char.Info.Name = cleanName
            end
            originalNames[id] = nil
            inspectedCorpses[id] = nil
        end
    end

    local healthWindow = CharacterHealth.OpenHealthWindow
    if not healthWindow or not healthWindow.Character then return end

    local target = healthWindow.Character
    if not target.IsDead or not target.IsHuman then return end

    local targetId = target.ID
    if inspectedCorpses[targetId] then return end

    local cause = target.CauseOfDeath
    if not cause then return end

    inspectedCorpses[targetId] = true

    local killerName = "Unknown"
    if cause.Killer and cause.Killer.Name then
        killerName = tostring(cause.Killer.Name)
    elseif cause.Affliction and cause.Affliction.Name then
        killerName = tostring(cause.Affliction.Name)
    end

    if target.Info and target.Info.Name then
        local currentName = tostring(target.Info.Name)
        if not originalNames[targetId] then
            originalNames[targetId] = currentName
        end
        
        local killedByText = TextManager.Get("KillerExposer.KilledBy").Value
        target.Info.Name = originalNames[targetId] .. killedByText .. killerName .. "]"
    end
end)
