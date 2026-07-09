---@class Vagos
---@field peds table<integer, integer>
Vagos = {}
Vagos.__index = Vagos

---@return Vagos
function Vagos.new()
    local self = setmetatable({}, Vagos)
    self.peds = {}
    return self
end

---@param ped integer
---@param def VagosDef
function Vagos:applyPed(ped, def)
    if def.anim == "armed" then
        SetEntityCoords(ped, def.pos[1], def.pos[2], def.pos[3], false, false, false, false)
        SetEntityHeading(ped, def.rot)
        GiveWeaponToPed(ped, GetHashKey(Constants.vagosWeapon), 100, true, true)
        FreezeEntityPosition(ped, true)
        return
    end

    local dict = def.anim == "lean" and Constants.vagosDictLean or Constants.vagosDictHang
    local clip = def.anim == "lean" and Constants.vagosClipLean or Constants.vagosClipHang
    local flag = def.physics and 17 or 1
    TaskPlayAnimAdvanced(ped, dict, clip, def.pos[1], def.pos[2], def.pos[3], 0.0, 0.0, def.rot, 1000.0, -1000.0, -1, flag, 0.0, 2, 0)
end

---@return boolean
function Vagos:create()
    local hash = GetHashKey(Constants.vagosModel)
    RequestModel(hash)
    RequestAnimDict(Constants.vagosDictLean)
    RequestAnimDict(Constants.vagosDictHang)
    if not HasModelLoaded(hash) or not HasAnimDictLoaded(Constants.vagosDictLean) or not HasAnimDictLoaded(Constants.vagosDictHang) then
        return false
    end

    for i = 0, 9 do
        if not self.peds[i] then
            local ped = CreatePed(Constants.pedTypeCivMale, hash, Constants.vagosSpawn[1], Constants.vagosSpawn[2], Constants.vagosSpawn[3], 0.0, false, false)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            self:applyPed(ped, Constants.vagos[i])
            self.peds[i] = ped
        end
    end

    SetModelAsNoLongerNeeded(hash)
    RemoveAnimDict(Constants.vagosDictLean)
    RemoveAnimDict(Constants.vagosDictHang)
    return true
end

function Vagos:cleanup()
    for i = 0, 9 do
        if self.peds[i] and DoesEntityExist(self.peds[i]) then
            DeleteEntity(self.peds[i])
        end
    end
    SetModelAsNoLongerNeeded(GetHashKey(Constants.vagosModel))
end
