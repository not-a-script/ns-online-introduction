---@class DrivePhase
---@field director IntroDirector
DrivePhase = {}
DrivePhase.__index = DrivePhase

---@param director IntroDirector
---@return DrivePhase
function DrivePhase.new(director)
    local self = setmetatable({}, DrivePhase)
    self.director = director
    director.lamar = LamarDrive.new(director.isMale)
    director.ambient = AmbientTraffic.new()
    director.vagos = Vagos.new()
    return self
end

function DrivePhase:ensureActors()
    local d = self.director
    d.lamar:create()
    WaitUntil(function() return d.ambient:create() end, "ambient cars", 15000)
    WaitUntil(function() return d.vagos:create() end, "vagos", 15000)
end

---@param def DriveStage
function DrivePhase:originCam(def)
    local d = self.director
    if not d.syncCam then
        d.syncCam = SyncSceneCam.new()
    end
    local final = def.kind == "finalorigin"
    local origin = final and Constants.driveFinalOrigin or Constants.driveOrigin
    local rot = final and Constants.driveFinalOriginRot or Constants.driveOriginRot
    d.syncCam:playOrigin({ anim = def.anim, phase = def.phase, rate = def.rate }, origin, rot)
end

function DrivePhase:attachCam()
    local d = self.director
    if not d.scriptedCam then
        d.scriptedCam = ScriptedCam.new()
    end
    d.scriptedCam:attach(d.lamar.vehLamar, Constants.driveAttachOffset, Constants.drivePointOffset, Constants.driveAttachFov, Constants.driveShakeType, Constants.driveShakeAmp)
end

---@param def DriveStage
function DrivePhase:enterStage(def)
    local d = self.director

    if def.entry then
        DoScreenFadeOut(Constants.fadeTime)
        self:ensureActors()
        d.dialogue:init()
        d.driveStarted = true
        d.creditsActive = true
        d.creditsPhase = "drive"
        d.lamar:enter()
        NetworkOverrideClockTime(Constants.lateHour, 0, 0)
        StartAudioScene(Constants.driveAudioScene)
    end

    if def.name == "LAMAR_CAR_DRIVE_10" or def.name == "LAMAR_CAR_DRIVE_17" then
        d:srlReadahead(Constants.srlReadaheadNormalSp)
    end

    if def.clock ~= nil then
        NetworkOverrideClockTime(def.clock, 0, 0)
    end
    if def.cloudUnload then
        UnloadCloudHat(Constants.driveCloudHat)
    end
    if def.vagosCleanup then
        d.vagos:cleanup()
    end

    if def.kind == "attach" then
        self:attachCam()
        d.lamar:playAnim(def)
    else
        self:originCam(def)
        d.lamar:showDriving(def.seat)
    end

    if def.kind == "finalorigin" then
        if IsScreenFadedOut() then
            DoScreenFadeIn(Constants.fadeTime)
        end
        d.arrivalPhase:request()
    end

    d.ambient:stage(def.ambient)

    if def.entry then
        DoScreenFadeIn(Constants.fadeTime)
    end
end

---@param def DriveStage
---@return boolean
function DrivePhase:advanceStage(def)
    local d = self.director

    if def.kind == "finalorigin" then
        d.arrivalPhase:request()
        d.lamar:stopIfHalted()
        if GetMusicPlaytime() < def.endTime or not d.arrivalPhase:isLoaded() then
            return false
        end
        if d.srlActive then
            EndSrl()
            d.srlActive = false
        end
        TriggerMusicEvent(Constants.musicDriveEnd)
        StopPlaybackRecordedVehicle(d.lamar.vehLamar)
        return true
    end

    if def.musicEndGate and not PrepareMusicEvent(Constants.musicDriveEnd) then
        return false
    end
    if GetMusicPlaytime() < def.endTime then
        return false
    end

    if def.skip then
        d.lamar:skipMain(def.skip)
    end
    if def.rampSkip then
        d.lamar:forceRecording(Constants.lamarRecRamp, def.rampSkip)
    end
    if def.parkSkip then
        d.lamar:forceRecording(Constants.lamarRecPark, def.parkSkip)
    end
    return true
end

---@return IntroStage[]
function DrivePhase:stages()
    local stages = {}
    for _, def in ipairs(Constants.driveStages) do
        stages[#stages + 1] = {
            name = def.name,
            setup = function() self:enterStage(def) end,
            advance = function() return self:advanceStage(def) end,
        }
    end
    return stages
end
