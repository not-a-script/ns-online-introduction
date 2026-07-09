---@class LamarDrive
---@field isMale boolean
---@field vehLamar integer?
---@field pedIGLamar integer?
---@field pedCSLamar integer?
LamarDrive = {}
LamarDrive.__index = LamarDrive

---@param isMale boolean
---@return LamarDrive
function LamarDrive.new(isMale)
    local self = setmetatable({}, LamarDrive)
    self.isMale = isMale
    return self
end

---@return boolean
function LamarDrive:driveAnimsLoaded()
    local set = self.isMale and Constants.driveAnims.male or Constants.driveAnims.female
    RequestAnimDict(set.dict)
    RequestAnimDict(Constants.driveAnims.radioDict)
    return HasAnimDictLoaded(set.dict) and HasAnimDictLoaded(Constants.driveAnims.radioDict)
end

function LamarDrive:create()
    local carHash = Util.loadModel(Constants.lamarCarModel)
    local igHash = Util.loadModel(Constants.lamarModel)
    local csHash = Util.loadModel(Constants.csLamarModel)

    RequestVehicleRecording(Constants.lamarRecMain, Constants.lamarRecordingName)
    RequestVehicleRecording(Constants.lamarRecRamp, Constants.lamarRecordingName)
    RequestVehicleRecording(Constants.lamarRecPark, Constants.lamarRecordingName)
    RequestAnimDict(Constants.raceDict)
    WaitUntil(function()
        return HasVehicleRecordingBeenLoaded(Constants.lamarRecMain, Constants.lamarRecordingName)
            and HasVehicleRecordingBeenLoaded(Constants.lamarRecRamp, Constants.lamarRecordingName)
            and HasVehicleRecordingBeenLoaded(Constants.lamarRecPark, Constants.lamarRecordingName)
            and HasAnimDictLoaded(Constants.raceDict)
            and self:driveAnimsLoaded()
    end, "lamar recordings/anims", 15000)

    self.vehLamar = CreateVehicle(carHash, Constants.lamarCarX, Constants.lamarCarY, Constants.lamarCarZ, Constants.lamarCarHeading, false, false)
    SetEntityAlwaysPrerender(self.vehLamar, true)
    SetVehicleRadioEnabled(self.vehLamar, false)
    SetEntityInvincible(self.vehLamar, true)

    self.pedIGLamar = CreatePed(Constants.pedTypeMission, igHash, Constants.lamarX, Constants.lamarY, Constants.lamarZ, Constants.lamarHeading, false, false)
    SetPedIntoVehicle(self.pedIGLamar, self.vehLamar, -1)
    SetBlockingOfNonTemporaryEvents(self.pedIGLamar, true)
    SetEntityInvincible(self.pedIGLamar, true)

    self.pedCSLamar = CreatePed(Constants.pedTypeMission, csHash, Constants.csLamarPos[1], Constants.csLamarPos[2], Constants.csLamarPos[3], Constants.csLamarHeading, false, false)
    SetBlockingOfNonTemporaryEvents(self.pedCSLamar, true)
    SetEntityInvincible(self.pedCSLamar, true)
    SetEntityVisible(self.pedCSLamar, false, false)

    SetModelAsNoLongerNeeded(carHash)
    SetModelAsNoLongerNeeded(igHash)
    SetModelAsNoLongerNeeded(csHash)
end

function LamarDrive:enter()
    SetEntityCoords(self.vehLamar, Constants.lamarStartPos[1], Constants.lamarStartPos[2], Constants.lamarStartPos[3], false, false, false, false)
    SetEntityHeading(self.vehLamar, Constants.lamarStartHeading)
    FreezeEntityPosition(PlayerPedId(), false)
    FreezeEntityPosition(self.vehLamar, false)
    SetPedIntoVehicle(PlayerPedId(), self.vehLamar, 0)
    StartPlaybackRecordedVehicle(self.vehLamar, Constants.lamarRecMain, Constants.lamarRecordingName)
    SkipTimeInPlaybackRecordedVehicle(self.vehLamar, Constants.lamarEntrySkip - GetTimePositionInRecording(self.vehLamar))
end

---@param target number
function LamarDrive:skipMain(target)
    SkipTimeInPlaybackRecordedVehicle(self.vehLamar, target - GetTimePositionInRecording(self.vehLamar))
end

---@param file integer
---@param target number
function LamarDrive:forceRecording(file, target)
    StopPlaybackRecordedVehicle(self.vehLamar)
    StartPlaybackRecordedVehicle(self.vehLamar, file, Constants.lamarRecordingName)
    SkipTimeInPlaybackRecordedVehicle(self.vehLamar, target - GetTimePositionInRecording(self.vehLamar))
end

---@param seat boolean?
function LamarDrive:showDriving(seat)
    SetEntityVisible(self.pedIGLamar, true, false)
    SetEntityVisible(self.pedCSLamar, false, false)
    if seat then
        SetPedIntoVehicle(PlayerPedId(), self.vehLamar, 0)
    end
end

---@param stage DriveStage
function LamarDrive:playAnim(stage)
    SetEntityVisible(self.pedIGLamar, false, false)
    SetEntityVisible(self.pedCSLamar, true, false)

    local set = self.isMale and Constants.driveAnims.male or Constants.driveAnims.female
    local idx = self.isMale and 1 or 2

    local lamarScene = CreateSynchronizedScene(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)
    AttachSynchronizedSceneToEntity(lamarScene, self.vehLamar, GetEntityBoneIndexByName(self.vehLamar, Constants.lamarSeatBone))
    local lamarDict = stage.radio and Constants.driveAnims.radioDict or set.dict
    local lamarClip = stage.radio and Constants.driveAnims.radioClip or set.lamarClip
    TaskSynchronizedScene(self.pedCSLamar, lamarScene, lamarDict, lamarClip, 1000.0, -1000.0, 0, 0, 1000.0, 0)
    SetSynchronizedScenePhase(lamarScene, stage.lamarPhase[idx])

    local playerBone = self.isMale and 0 or GetEntityBoneIndexByName(self.vehLamar, Constants.playerSeatBone)
    local playerScene = CreateSynchronizedScene(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)
    AttachSynchronizedSceneToEntity(playerScene, self.vehLamar, playerBone)
    TaskSynchronizedScene(PlayerPedId(), playerScene, set.dict, set.playerClip, 1000.0, -1000.0, 0, 0, 1000.0, 0)
    SetSynchronizedScenePhase(playerScene, stage.playerPhase[idx])

    ForcePedAiAndAnimationUpdate(self.pedCSLamar)
    ForcePedAiAndAnimationUpdate(PlayerPedId())
end

function LamarDrive:stopIfHalted()
    if self.vehLamar and IsPlaybackGoingOnForVehicle(self.vehLamar) and GetEntitySpeed(self.vehLamar) < 1.0 then
        StopPlaybackRecordedVehicle(self.vehLamar)
    end
end

function LamarDrive:cleanup()
    if self.pedCSLamar and DoesEntityExist(self.pedCSLamar) then
        DeleteEntity(self.pedCSLamar)
    end
    if self.pedIGLamar and DoesEntityExist(self.pedIGLamar) then
        DeleteEntity(self.pedIGLamar)
    end
    if self.vehLamar and DoesEntityExist(self.vehLamar) then
        DeleteEntity(self.vehLamar)
    end
    for _, file in ipairs({ Constants.lamarRecMain, Constants.lamarRecRamp, Constants.lamarRecPark }) do
        RemoveVehicleRecording(file, Constants.lamarRecordingName)
    end
    RemoveAnimDict(Constants.driveAnims.male.dict)
    RemoveAnimDict(Constants.driveAnims.female.dict)
    RemoveAnimDict(Constants.driveAnims.radioDict)
end
