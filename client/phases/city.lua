---@class CityPhase
---@field director IntroDirector
CityPhase = {}
CityPhase.__index = CityPhase

---@param director IntroDirector
---@return CityPhase
function CityPhase.new(director)
    local self = setmetatable({}, CityPhase)
    self.director = director
    return self
end

---@return boolean
function CityPhase:createHeli()
    local d = self.director
    if d.heliVehicle then
        return true
    end

    local hash = GetHashKey(Constants.froggerModel)
    RequestModel(hash)
    if not d.heli:request() or not HasModelLoaded(hash) then
        return false
    end

    local x, y, z = d.heli:positionAtTime(0.0)
    local veh = CreateVehicle(hash, x, y, z, 0.0, false, false)
    d.heli:attach(veh)
    d.heli:start()
    d.heli:skip(Constants.heliSkip)
    d.heli:pause()
    SetEntityVisible(veh, false, false)
    SetModelAsNoLongerNeeded(hash)
    d.heliVehicle = veh
    return true
end

function CityPhase:revealHeli()
    local d = self.director
    if not d.heliVehicle then
        return
    end
    d.heli:unpause()
    SetEntityVisible(d.heliVehicle, true, false)
    SetHeliBladesFullSpeed(d.heliVehicle)
end

---@return boolean
function CityPhase:shot1Advance()
    if not self:createHeli() then
        return false
    end
    return GetMusicPlaytime() >= Constants.stageTimes.cityShot1
end

---@return boolean
function CityPhase:shot2Advance()
    local d = self.director
    if d.heliVehicle then
        SetHeliBladesFullSpeed(d.heliVehicle)
    end
    if not d.racePhase:createCars() then
        return false
    end
    if GetMusicPlaytime() < Constants.stageTimes.cityShot2 then
        return false
    end

    local ped = PlayerPedId()
    SetEntityCoords(ped, Constants.raceWarp[1], Constants.raceWarp[2], Constants.raceWarp[3], false, false, false, false)
    FreezeEntityPosition(ped, true)
    d.racePhase:startPlayback(Constants.racerStartSkip)
    DoScreenFadeIn(Constants.fadeTime)
    return true
end

---@return IntroStage[]
function CityPhase:stages()
    return {
        {
            name = "CITY_SHOT_1_START",
            setup = function()
                self.director:applyScriptedCam(Constants.cams.cityShot1)
                self.director:srlReadahead(Constants.srlReadaheadHeavy)
            end,
            advance = function() return true end,
        },
        {
            name = "CITY_SHOT_1",
            setup = function() end,
            advance = function() return self:shot1Advance() end,
        },
        {
            name = "CITY_SHOT_2_START",
            setup = function()
                self.director:applyScriptedCam(Constants.cams.cityShot2)
                self.director.racePhase:requestUberAssets()
                self:revealHeli()
            end,
            advance = function() return true end,
        },
        {
            name = "CITY_SHOT_2",
            setup = function() end,
            advance = function() return self:shot2Advance() end,
        },
    }
end
