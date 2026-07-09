Util = {}

---@param model string
---@return integer
function Util.loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    WaitUntil(function() return HasModelLoaded(hash) end, "model " .. model, 10000)
    return hash
end

---@param rot Vec3
---@return number, number, number
function Util.rotationToDirection(rot)
    local radZ = math.rad(rot[3])
    local radX = math.rad(rot[1])
    local factor = math.abs(math.cos(radX))
    return -math.sin(radZ) * factor, math.cos(radZ) * factor, math.sin(radX)
end

---@class ScriptedCam
---@field handle integer
ScriptedCam = {}
ScriptedCam.__index = ScriptedCam

---@return ScriptedCam
function ScriptedCam.new()
    local self = setmetatable({}, ScriptedCam)
    self.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
    SetCamActive(self.handle, true)
    return self
end

---@param shot CamShot
function ScriptedCam:apply(shot)
    SetCamParams(self.handle, shot.pos1[1], shot.pos1[2], shot.pos1[3], shot.rot1[1], shot.rot1[2], shot.rot1[3], shot.fov1)
    SetCamParams(self.handle, shot.pos2[1], shot.pos2[2], shot.pos2[3], shot.rot2[1], shot.rot2[2], shot.rot2[3], shot.fov2, shot.duration, shot.graphPos, shot.graphRot, shot.graphFov)
    if shot.shakeType then
        ShakeCam(self.handle, shot.shakeType, shot.shakeAmplitude)
    end
end

function ScriptedCam:stopShaking()
    StopCamShaking(self.handle, true)
end

---@param entity integer
---@param offset Vec3
---@param pointOffset Vec3
---@param fov number
---@param shakeType string
---@param shakeAmp number
function ScriptedCam:attach(entity, offset, pointOffset, fov, shakeType, shakeAmp)
    AttachCamToEntity(self.handle, entity, offset[1], offset[2], offset[3], true)
    PointCamAtEntity(self.handle, entity, pointOffset[1], pointOffset[2], pointOffset[3], true)
    SetCamFov(self.handle, fov)
    ShakeCam(self.handle, shakeType, shakeAmp)
    SetCamActive(self.handle, true)
    RenderScriptCams(true, false, 0, true, true)
end

function ScriptedCam:destroy()
    if DoesCamExist(self.handle) then
        StopCamShaking(self.handle, true)
        DestroyCam(self.handle, false)
    end
end

---@class SyncSceneCam
---@field handle integer
---@field sceneId integer
SyncSceneCam = {}
SyncSceneCam.__index = SyncSceneCam

---@return SyncSceneCam
function SyncSceneCam.new()
    local self = setmetatable({}, SyncSceneCam)
    self.handle = CreateCam("DEFAULT_ANIMATED_CAMERA", false)
    self.sceneId = -1
    return self
end

---@param shot SyncCamShot
---@param origin Vec3
---@param rot Vec3
function SyncSceneCam:playOrigin(shot, origin, rot)
    self.sceneId = CreateSynchronizedScene(origin[1], origin[2], origin[3], rot[1], rot[2], rot[3], 2)
    PlaySynchronizedCamAnim(self.handle, self.sceneId, shot.anim, Constants.raceDict)
    SetSynchronizedScenePhase(self.sceneId, shot.phase)
    SetSynchronizedSceneRate(self.sceneId, shot.rate)
    SetCamActive(self.handle, true)
    RenderScriptCams(true, false, 0, true, true)
end

---@param shot SyncCamShot
---@param entity integer
---@param origin Vec3
---@param rot Vec3
function SyncSceneCam:playAttach(shot, entity, origin, rot)
    self.sceneId = CreateSynchronizedScene(origin[1], origin[2], origin[3], rot[1], rot[2], rot[3], 2)
    AttachSynchronizedSceneToEntity(self.sceneId, entity, 0)
    PlaySynchronizedCamAnim(self.handle, self.sceneId, shot.anim, Constants.raceDict)
    SetCamActive(self.handle, true)
    RenderScriptCams(true, false, 0, true, true)
end

function SyncSceneCam:destroy()
    if DoesCamExist(self.handle) then
        DestroyCam(self.handle, false)
    end
end

---@class Recording
---@field fileId integer
---@field name string
---@field vehicle integer?
Recording = {}
Recording.__index = Recording

---@param fileId integer
---@param name string
---@return Recording
function Recording.new(fileId, name)
    local self = setmetatable({}, Recording)
    self.fileId = fileId
    self.name = name
    return self
end

---@return boolean
function Recording:request()
    RequestVehicleRecording(self.fileId, self.name)
    return HasVehicleRecordingBeenLoaded(self.fileId, self.name)
end

---@param time number
---@return number, number, number
function Recording:positionAtTime(time)
    local pos = GetPositionOfVehicleRecordingAtTime(self.fileId, time, self.name)
    return pos.x, pos.y, pos.z
end

---@param vehicle integer
function Recording:attach(vehicle)
    self.vehicle = vehicle
end

function Recording:start()
    StartPlaybackRecordedVehicle(self.vehicle, self.fileId, self.name)
end

---@param ms number
function Recording:skip(ms)
    SkipTimeInPlaybackRecordedVehicle(self.vehicle, ms)
end

---@param targetMs number
function Recording:skipToTime(targetMs)
    SkipTimeInPlaybackRecordedVehicle(self.vehicle, targetMs - GetTimePositionInRecording(self.vehicle))
end

function Recording:pause()
    PausePlaybackRecordedVehicle(self.vehicle)
end

function Recording:unpause()
    UnpausePlaybackRecordedVehicle(self.vehicle)
end

function Recording:remove()
    RemoveVehicleRecording(self.fileId, self.name)
end
