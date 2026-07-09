---@class FinishPhase
---@field director IntroDirector
FinishPhase = {}
FinishPhase.__index = FinishPhase

local SetSrlLongJumpMode = N_0x20c6c7e4eb082a7f

---@param director IntroDirector
---@return FinishPhase
function FinishPhase.new(director)
    local self = setmetatable({}, FinishPhase)
    self.director = director
    return self
end

function FinishPhase:teardownEntities()
    local d = self.director

    if d.heliVehicle and DoesEntityExist(d.heliVehicle) then
        DeleteEntity(d.heliVehicle)
    end
    d.heli:remove()

    for i = 0, 4 do
        if d.racerPeds[i] and DoesEntityExist(d.racerPeds[i]) then
            DeleteEntity(d.racerPeds[i])
        end
        if d.racerVehicles[i] and DoesEntityExist(d.racerVehicles[i]) then
            DeleteEntity(d.racerVehicles[i])
        end
        d.racers[i]:remove()
    end

    for i = 0, 7 do
        if d.garageCars[i] and DoesEntityExist(d.garageCars[i]) then
            DeleteEntity(d.garageCars[i])
        end
    end
    if d.mechanic and DoesEntityExist(d.mechanic) then
        DeleteEntity(d.mechanic)
    end
    RemoveAnimDict(Constants.raceDict)

    d.lamar:cleanup()
    d.ambient:cleanup()
    d.vagos:cleanup()
end

function FinishPhase:teardownWorld()
    local d = self.director

    if d.srlActive then
        EndSrl()
        d.srlActive = false
        SetSrlLongJumpMode(false)
    end

    d:destroyScriptedCam()
    d:destroyRaceCam()
    RenderScriptCams(false, false, 0, true, false)
    ClearFocus()

    d:cleanupLogo()
    AnimpostfxStop(Constants.logoAnimpostfx)
    d.credits:cleanup()

    if IsAudioSceneActive(Constants.audioScene) then
        StopAudioScene(Constants.audioScene)
    end
    if IsAudioSceneActive(Constants.driveAudioScene) then
        StopAudioScene(Constants.driveAudioScene)
    end
    UnloadCloudHat(Constants.driveCloudHat)

    if d.interior and d.interior ~= 0 then
        UnpinInterior(d.interior)
    end
    SetStaticEmitterEnabled(Constants.garageRadioEmitter, true)

    for _, area in ipairs(Constants.roadAreas) do
        SetRoadsBackToOriginalInAngledArea(area.a[1], area.a[2], area.a[3], area.b[1], area.b[2], area.b[3])
    end
    RemoveScenarioBlockingAreas()

    ClearOverrideWeather()
    NetworkClearClockTimeOverride()
end

function FinishPhase:teardownPlayer()
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
end

function FinishPhase:finish()
    self.director.finishing = true

    self:teardownEntities()
    self:teardownWorld()
    self:teardownPlayer()

    DisplayRadar(true)
    DoScreenFadeIn(Constants.fadeTime)
end

---@return IntroStage[]
function FinishPhase:stages()
    return {
        {
            name = "FINISH",
            setup = function() self:finish() end,
            advance = function() return true end,
        },
    }
end
