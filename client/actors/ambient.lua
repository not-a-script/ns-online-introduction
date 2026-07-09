---@class AmbientTraffic
---@field cars table<integer, integer>
---@field peds table<integer, integer>
AmbientTraffic = {}
AmbientTraffic.__index = AmbientTraffic

---@return AmbientTraffic
function AmbientTraffic.new()
    local self = setmetatable({}, AmbientTraffic)
    self.cars = {}
    self.peds = {}
    return self
end

---@return boolean
function AmbientTraffic:create()
    local hashA = GetHashKey(Constants.ambientModelA)
    local hashB = GetHashKey(Constants.ambientModelB)
    RequestModel(hashA)
    RequestModel(hashB)
    if not HasModelLoaded(hashA) or not HasModelLoaded(hashB) then
        return false
    end

    local half = math.floor(Constants.ambientCount / 2)
    local driverModel = GetEntityModel(PlayerPedId())
    for i = 0, Constants.ambientCount - 1 do
        if not self.cars[i] then
            local model = i < half and hashA or hashB
            local safe = Constants.ambientSafeCoords[i]
            local veh = CreateVehicle(model, safe.pos[1], safe.pos[2], safe.pos[3], safe.heading, false, false)
            SetVehicleColourCombination(veh, i)
            SetEntityInvincible(veh, true)
            SetVehicleLights(veh, 2)
            FreezeEntityPosition(veh, true)
            SetEntityVisible(veh, false, false)
            self.cars[i] = veh
        end
        if self.cars[i] and not self.peds[i] then
            local ped = CreatePedInsideVehicle(self.cars[i], Constants.pedTypeCivMale, driverModel, -1, false, false)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityVisible(ped, false, false)
            self.peds[i] = ped
        end
    end

    SetModelAsNoLongerNeeded(hashA)
    SetModelAsNoLongerNeeded(hashB)
    return true
end

---@param id integer
---@param pos Vec3
---@param heading number
function AmbientTraffic:setupCar(id, pos, heading)
    local veh = self.cars[id]
    local ped = self.peds[id]
    if not veh or not ped then
        return
    end
    FreezeEntityPosition(veh, false)
    SetEntityCollision(veh, true, true)
    SetEntityCoords(veh, pos[1], pos[2], pos[3], false, false, false, false)
    SetEntityHeading(veh, heading)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFixed(veh)
    TaskVehicleDriveWander(ped, veh, Constants.ambientCitySpeed, 786603)
    SetVehicleForwardSpeed(veh, Constants.ambientCityForward)
    SetPedKeepTask(ped, true)
    SetEntityVisible(veh, true, false)
    SetEntityVisible(ped, true, false)
end

---@param id integer
function AmbientTraffic:hideCar(id)
    local veh = self.cars[id]
    if veh then
        local safe = Constants.ambientSafeCoords[id]
        SetEntityCoords(veh, safe.pos[1], safe.pos[2], safe.pos[3], false, false, false, false)
        SetEntityHeading(veh, safe.heading)
        FreezeEntityPosition(veh, true)
        SetVehicleFixed(veh)
        SetEntityCollision(veh, false, false)
        SetEntityVisible(veh, false, false)
    end
    if self.peds[id] then
        SetEntityVisible(self.peds[id], false, false)
    end
end

---@param key string
function AmbientTraffic:stage(key)
    local used = {}
    for _, entry in ipairs(Constants.ambientStages[key]) do
        self:setupCar(entry[1], entry[2], entry[3])
        used[entry[1]] = true
    end
    for i = 0, Constants.ambientCount - 1 do
        if not used[i] then
            self:hideCar(i)
        end
    end
end

function AmbientTraffic:cleanup()
    for i = 0, Constants.ambientCount - 1 do
        if self.peds[i] and DoesEntityExist(self.peds[i]) then
            DeleteEntity(self.peds[i])
        end
        if self.cars[i] and DoesEntityExist(self.cars[i]) then
            DeleteEntity(self.cars[i])
        end
    end
    SetModelAsNoLongerNeeded(GetHashKey(Constants.ambientModelA))
    SetModelAsNoLongerNeeded(GetHashKey(Constants.ambientModelB))
end
