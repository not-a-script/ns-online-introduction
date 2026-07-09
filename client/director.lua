---@class IntroDirector
---@field player integer
---@field isMale boolean
---@field scriptedCam ScriptedCam?
---@field syncCam SyncSceneCam?
---@field focusPos Vec3?
---@field heli Recording
---@field heliVehicle integer?
---@field racers table<integer, Recording>
---@field racerVehicles table<integer, integer>
---@field racerPeds table<integer, integer>
---@field racersCreated boolean
---@field garageCars table<integer, integer>
---@field mechanic integer?
---@field mechanicScene integer?
---@field interior integer?
---@field logo integer?
---@field logoMethodCalled boolean
---@field logoFxPlayed boolean
---@field splashArmed boolean
---@field audioSceneStarted boolean
---@field scenarioBlock integer?
---@field musicStarted boolean
---@field finishing boolean
---@field stages IntroStage[]
---@field stageIndex integer
---@field stageEntered boolean
---@field setupPhase SetupPhase
---@field shot1Phase Shot1Phase
---@field cityPhase CityPhase
---@field racePhase RacePhase
---@field garagePhase GaragePhase
---@field planePhase PlanePhase
---@field drivePhase DrivePhase
---@field arrivalPhase ArrivalPhase
---@field finishPhase FinishPhase
---@field lamar LamarDrive
---@field ambient AmbientTraffic
---@field vagos Vagos
---@field credits CreditsOverlay
---@field dialogue LamarDialogue
---@field creditsActive boolean
---@field creditsPhase string?
---@field srlActive boolean
---@field srlEnabled boolean
---@field mocapStarted boolean
---@field driveStarted boolean
IntroDirector = {}
IntroDirector.__index = IntroDirector

---@return IntroDirector
function IntroDirector.new()
    local self = setmetatable({}, IntroDirector)
    self.player = PlayerPedId()
    self.isMale = IsPedMale(self.player)
    self.heli = Recording.new(Constants.heliRecording, Constants.heliRecordingName)
    self.racers = {}
    self.racerVehicles = {}
    self.racerPeds = {}
    self.garageCars = {}
    for i = 0, 4 do
        self.racers[i] = Recording.new(Constants.raceCars[i].recording, Constants.uberRecordingName)
    end
    self.racersCreated = false
    self.logoMethodCalled = false
    self.logoFxPlayed = false
    self.splashArmed = false
    self.audioSceneStarted = false
    self.musicStarted = false
    self.finishing = false
    self.srlActive = false
    self.srlEnabled = false
    self.mocapStarted = false
    self.driveStarted = false
    self.stageIndex = 1
    self.stageEntered = false
    return self
end

---@return integer
function IntroDirector:assetTimer()
    if not self.mocapStarted then
        return GetMusicPlaytime()
    elseif not self.driveStarted then
        return Constants.mocapStartTime + GetCutsceneTime()
    end
    return Constants.mocapEndTime + GetMusicPlaytime()
end

---@param preset number[]
function IntroDirector:srlReadahead(preset)
    if not self.srlEnabled then
        return
    end
    Citizen.InvokeNative(0xBEB2D9A1D9A8F55A, preset[1], preset[2], preset[3], preset[4])
end

---@param shot CamShot
function IntroDirector:createScriptedCam(shot)
    if not self.scriptedCam then
        self.scriptedCam = ScriptedCam.new()
    end
    self.scriptedCam:apply(shot)
    self.focusPos = shot.pos2
    RenderScriptCams(true, false, 0, true, true)
end

---@param shot CamShot
function IntroDirector:applyScriptedCam(shot)
    if not self.scriptedCam then
        self.scriptedCam = ScriptedCam.new()
    end
    self.scriptedCam:apply(shot)
    self.focusPos = shot.pos2
end

function IntroDirector:destroyScriptedCam()
    if self.scriptedCam then
        self.scriptedCam:destroy()
        self.scriptedCam = nil
    end
end

---@param shot SyncCamShot
function IntroDirector:startRaceCam(shot)
    if not self.syncCam then
        self.syncCam = SyncSceneCam.new()
    end
    self.syncCam:playOrigin(shot, Constants.raceOrigin, Constants.raceOriginRot)
    self.focusPos = Constants.raceOrigin
end

---@param shot SyncCamShot
---@param entity integer
function IntroDirector:startRaceCamAttach(shot, entity)
    if not self.syncCam then
        self.syncCam = SyncSceneCam.new()
    end
    self.syncCam:playAttach(shot, entity, Constants.race3AttachOffset, Constants.raceOriginRot)
end

function IntroDirector:destroyRaceCam()
    if self.syncCam then
        self.syncCam:destroy()
        self.syncCam = nil
    end
end

function IntroDirector:cleanupHeli()
    SetModelAsNoLongerNeeded(GetHashKey(Constants.froggerModel))
    self.heli:remove()
    if self.heliVehicle and DoesEntityExist(self.heliVehicle) then
        DeleteEntity(self.heliVehicle)
    end
    self.heliVehicle = nil
end

function IntroDirector:cleanupUberAssets()
    for i = 0, 4 do
        if self.racerPeds[i] and DoesEntityExist(self.racerPeds[i]) then
            DeleteEntity(self.racerPeds[i])
            self.racerPeds[i] = nil
        end
        if self.racerVehicles[i] and DoesEntityExist(self.racerVehicles[i]) then
            DeleteEntity(self.racerVehicles[i])
            self.racerVehicles[i] = nil
        end
        self.racers[i]:remove()
    end
    for _, model in ipairs(Constants.uberModels) do
        SetModelAsNoLongerNeeded(GetHashKey(model))
    end
end

function IntroDirector:cleanupLogo()
    if self.logo and HasScaleformMovieLoaded(self.logo) then
        BeginScaleformMovieMethod(self.logo, Constants.logoMethod)
        ScaleformMovieMethodAddParamInt(1)
        ScaleformMovieMethodAddParamBool(false)
        EndScaleformMovieMethod()
        SetScaleformMovieAsNoLongerNeeded(self.logo)
    end
    self.logoMethodCalled = false
    self.splashArmed = false
end

function IntroDirector:drawLogo()
    DrawScaleformMovieFullscreen(self.logo, 255, 255, 255, 255, 0)
    if not self.logoMethodCalled then
        BeginScaleformMovieMethod(self.logo, Constants.logoMethod)
        ScaleformMovieMethodAddParamInt(1)
        ScaleformMovieMethodAddParamBool(true)
        EndScaleformMovieMethod()
        self.logoMethodCalled = true
    end
end

function IntroDirector:preamble()
    if IsPlayerControlOn(PlayerId()) then
        SetPlayerControl(PlayerId(), false, Constants.controlSuppressFlags)
    end

    SetPedDensityMultiplierThisFrame(0.0)
    SetVehicleDensityMultiplierThisFrame(0.0)
    SetRandomVehicleDensityMultiplierThisFrame(0.0)
    SetParkedVehicleDensityMultiplierThisFrame(0.0)

    for _, id in ipairs(Constants.hudComponentsToHide) do
        HideHudComponentThisFrame(id)
    end
    DisplayRadar(false)

    if self.focusPos then
        SetFocusPosAndVel(self.focusPos[1], self.focusPos[2], self.focusPos[3], 0.0, 0.0, 0.0)
    end

    if self.splashArmed and self.logo and HasScaleformMovieLoaded(self.logo) then
        self:drawLogo()
    end

    if self.srlActive then
        SetSrlTime(self:assetTimer() + 0.0)
    end

    if self.creditsActive then
        if self.creditsPhase == "drive" then
            self.dialogue:tick(GetMusicPlaytime())
        end
        if self.credits:request() then
            local driveTime = self.creditsPhase == "drive" and GetMusicPlaytime() or 999999
            local arrivalTime = self.creditsPhase == "arrival" and GetCutsceneTime() or -1
            self.credits:tick(driveTime, arrivalTime)
        end
    end
end

function IntroDirector:build()
    self.credits = CreditsOverlay.new(self.isMale)
    self.dialogue = LamarDialogue.new(self)
    self.creditsActive = false

    self.setupPhase = SetupPhase.new(self)
    self.shot1Phase = Shot1Phase.new(self)
    self.cityPhase = CityPhase.new(self)
    self.racePhase = RacePhase.new(self)
    self.garagePhase = GaragePhase.new(self)
    self.planePhase = PlanePhase.new(self)
    self.arrivalPhase = ArrivalPhase.new(self)
    self.drivePhase = DrivePhase.new(self)
    self.finishPhase = FinishPhase.new(self)

    self.stages = {}
    local phases = {
        self.setupPhase, self.shot1Phase, self.cityPhase, self.racePhase,
        self.garagePhase, self.planePhase, self.drivePhase, self.arrivalPhase, self.finishPhase,
    }
    for _, phase in ipairs(phases) do
        for _, stage in ipairs(phase:stages()) do
            self.stages[#self.stages + 1] = stage
        end
    end
end

---@param onComplete fun()
function IntroDirector:play(onComplete)
    self:build()
    CreateThread(function()
        while self.stageIndex <= #self.stages do
            local stage = self.stages[self.stageIndex]
            if not self.stageEntered then
                stage.setup()
                self.stageEntered = true
            end
            if not self.finishing then
                self:preamble()
            end
            if stage.advance() then
                self.stageIndex = self.stageIndex + 1
                self.stageEntered = false
            end
            Wait(0)
        end
        TriggerEvent("introCinematic:finished")
        onComplete()
    end)
end

local running = false

RegisterNetEvent("introCinematic:start")
AddEventHandler("introCinematic:start", function()
    if running then
        return
    end
    running = true
    IntroDirector.new():play(function()
        running = false
    end)
end)
