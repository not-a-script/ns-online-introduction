---@class PlanePhase
---@field director IntroDirector
---@field cut Cutscene
---@field started boolean
---@field startTime integer
PlanePhase = {}
PlanePhase.__index = PlanePhase

---@param director IntroDirector
---@return PlanePhase
function PlanePhase.new(director)
    local self = setmetatable({}, PlanePhase)
    self.director = director
    self.cut = Cutscene.new()
    self.started = false
    self.startTime = 0
    return self
end

---@return boolean
function PlanePhase:requestScene()
    return self.cut:requestScene()
end

---@return boolean
function PlanePhase:isLoaded()
    return HasCutsceneLoaded()
end

function PlanePhase:enter()
    local d = self.director
    RenderScriptCams(false, false, 0, true, false)
    d:destroyScriptedCam()
    d:destroyRaceCam()
    d.focusPos = nil
    ClearFocus()

    self.cut:spawnPlane()
    self.cut:spawnPassengers()
    self.cut:registerPlayer()
    self.cut:registerPlane()
    self.cut:begin()
    self.cut:startExhaustPtfx()
    d:srlReadahead(Constants.srlReadaheadNormal)
    d.mocapStarted = true
    self.startTime = GetGameTimer()
end

---@return boolean
function PlanePhase:advance()
    self.cut:applyClockForSection(GetCutsceneSectionPlaying())
    self.cut:maintainPtfx()

    if not self.started then
        if IsCutscenePlaying() then
            self.started = true
        elseif GetGameTimer() - self.startTime > Constants.mocapStartTimeout then
            self.started = true
        end
        return false
    end

    if self.cut:isPlaying() then
        return false
    end

    TriggerMusicEvent(Constants.musicDriveStart)
    self.cut:teardown()
    return true
end

---@return IntroStage[]
function PlanePhase:stages()
    return {
        {
            name = "MOCAP",
            setup = function() self:enter() end,
            advance = function() return self:advance() end,
        },
    }
end
