---@class RacePhase
---@field director IntroDirector
RacePhase = {}
RacePhase.__index = RacePhase

---@param director IntroDirector
---@return RacePhase
function RacePhase.new(director)
    local self = setmetatable({}, RacePhase)
    self.director = director
    return self
end

function RacePhase:requestUberAssets()
    for _, model in ipairs(Constants.uberModels) do
        RequestModel(GetHashKey(model))
    end
    for i = 0, 4 do
        RequestVehicleRecording(Constants.raceCars[i].recording, Constants.uberRecordingName)
    end
    RequestAnimDict(Constants.raceDict)
end

---@return boolean
function RacePhase:uberAssetsLoaded()
    for _, model in ipairs(Constants.uberModels) do
        if not HasModelLoaded(GetHashKey(model)) then
            return false
        end
    end
    for i = 0, 4 do
        if not HasVehicleRecordingBeenLoaded(Constants.raceCars[i].recording, Constants.uberRecordingName) then
            return false
        end
    end
    return HasAnimDictLoaded(Constants.raceDict)
end

---@return boolean
function RacePhase:createCars()
    local d = self.director
    if d.racersCreated then
        return true
    end

    self:requestUberAssets()
    if not self:uberAssetsLoaded() then
        return false
    end

    for i = 0, 4 do
        if not d.racerVehicles[i] then
            local def = Constants.raceCars[i]
            local veh = CreateVehicle(GetHashKey(def.model), def.pos[1], def.pos[2], def.pos[3], def.heading, false, false)
            SetVehicleRadioEnabled(veh, false)
            if def.quaternion then
                SetEntityQuaternion(veh, def.quaternion[1], def.quaternion[2], def.quaternion[3], def.quaternion[4])
            end
            if def.colourCombination then
                SetVehicleColourCombination(veh, def.colourCombination)
            end
            if def.colours then
                SetVehicleColours(veh, def.colours[1], def.colours[2])
            end
            if def.extraColours then
                SetVehicleExtraColours(veh, def.extraColours[1], def.extraColours[2])
            end
            if def.modKit then
                SetVehicleModKit(veh, def.modKit)
            end
            if def.xenon then
                ToggleVehicleMod(veh, Constants.modXenon, true)
            end
            SetVehicleTyresCanBurst(veh, false)
            d.racerVehicles[i] = veh
            d.racers[i]:attach(veh)
        end
    end

    local driverModel = GetEntityModel(PlayerPedId())
    for i = 0, 4 do
        if d.racerVehicles[i] and not d.racerPeds[i] then
            local ped = CreatePedInsideVehicle(d.racerVehicles[i], Constants.pedTypeCivMale, driverModel, -1, false, false)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetVehicleEngineOn(d.racerVehicles[i], true, true)
            d.racerPeds[i] = ped
        end
    end

    for _, model in ipairs(Constants.uberModels) do
        SetModelAsNoLongerNeeded(GetHashKey(model))
    end
    d.racersCreated = true
    return true
end

---@param skipMs number
function RacePhase:startPlayback(skipMs)
    local d = self.director
    for i = 0, 4 do
        if d.racerVehicles[i] then
            d.racers[i]:start()
            d.racers[i]:skip(skipMs)
        end
    end
end

---@param skipMs number
---@param car2Offset number?
function RacePhase:skipAllCars(skipMs, car2Offset)
    local d = self.director
    for i = 0, 4 do
        if d.racerVehicles[i] and DoesEntityExist(d.racerVehicles[i]) then
            local target = skipMs
            if i == 2 and car2Offset then
                target = target + car2Offset
            end
            d.racers[i]:skipToTime(target)
        end
    end
end

---@return boolean
function RacePhase:loadLogo()
    local d = self.director
    if d.logo and HasScaleformMovieLoaded(d.logo) then
        return true
    end
    d.logo = RequestScaleformMovie(Constants.gtaoScaleform)
    return HasScaleformMovieLoaded(d.logo)
end

function RacePhase:deleteCrashCars()
    local d = self.director
    for i = 2, 4 do
        if d.racerVehicles[i] and DoesEntityExist(d.racerVehicles[i]) then
            DeleteEntity(d.racerVehicles[i])
            d.racerVehicles[i] = nil
        end
    end
end

---@return boolean
function RacePhase:race5Advance()
    if not self:loadLogo() then
        return false
    end
    if GetMusicPlaytime() < Constants.stageTimes.race5 then
        return false
    end
    self:skipAllCars(Constants.race5Skip)
    return true
end

---@return boolean
function RacePhase:race6Advance()
    local d = self.director
    local playtime = GetMusicPlaytime()
    local endTime = Constants.stageTimes.race6

    if playtime >= (endTime + Constants.logoFxOffset) and not d.logoFxPlayed then
        AnimpostfxPlay(Constants.logoAnimpostfx, 0, false)
        d.logoFxPlayed = true
    end
    if playtime >= (endTime + Constants.splashArmOffset) then
        d.splashArmed = true
    end

    d.garagePhase:preload()
    return playtime >= endTime
end

---@return IntroStage[]
function RacePhase:stages()
    return {
        {
            name = "RACE_1",
            setup = function()
                local d = self.director
                NetworkOverrideClockTime(Constants.raceHour, 0, 0)
                d:cleanupHeli()
                d:startRaceCam(Constants.raceCams.race1)
                d:destroyScriptedCam()
                d:srlReadahead(Constants.srlReadaheadNormalSp)
                StartAudioScene(Constants.audioScene)
                d.audioSceneStarted = true
            end,
            advance = function()
                if GetMusicPlaytime() < Constants.stageTimes.race1 then
                    return false
                end
                self:skipAllCars(Constants.race1Skip)
                NetworkOverrideClockTime(Constants.raceHour, 0, 0)
                return true
            end,
        },
        {
            name = "RACE_2",
            setup = function() self.director:startRaceCam(Constants.raceCams.race2) end,
            advance = function()
                if GetMusicPlaytime() < Constants.stageTimes.race2 then
                    return false
                end
                self:skipAllCars(Constants.race2Skip, Constants.race2Car2Offset)
                return true
            end,
        },
        {
            name = "RACE_3",
            setup = function()
                self.director:startRaceCamAttach(Constants.raceCams.race3, self.director.racerVehicles[4])
            end,
            advance = function()
                if GetMusicPlaytime() < Constants.stageTimes.race3 then
                    return false
                end
                self:skipAllCars(Constants.race3Skip)
                return true
            end,
        },
        {
            name = "RACE_4",
            setup = function() self.director:startRaceCam(Constants.raceCams.race4) end,
            advance = function()
                if GetMusicPlaytime() < Constants.stageTimes.race4 then
                    return false
                end
                self:skipAllCars(Constants.race4Skip)
                return true
            end,
        },
        {
            name = "RACE_5",
            setup = function() self.director:startRaceCam(Constants.raceCams.race5) end,
            advance = function() return self:race5Advance() end,
        },
        {
            name = "RACE_6",
            setup = function()
                self:deleteCrashCars()
                self.director:startRaceCam(Constants.raceCams.race6)
                self.director.garagePhase:preload()
            end,
            advance = function() return self:race6Advance() end,
        },
    }
end
