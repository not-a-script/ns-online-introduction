---@class Shot1Phase
---@field director IntroDirector
---@field streamStart integer
Shot1Phase = {}
Shot1Phase.__index = Shot1Phase

---@param director IntroDirector
---@return Shot1Phase
function Shot1Phase.new(director)
    local self = setmetatable({}, Shot1Phase)
    self.director = director
    self.streamStart = 0
    return self
end

function Shot1Phase:enter()
    local scene = Constants.shot1LoadScene
    local dx, dy, dz = Util.rotationToDirection(scene.rot)
    NewLoadSceneStart(scene.pos[1], scene.pos[2], scene.pos[3], dx, dy, dz, scene.radius, 0)
    self.streamStart = GetGameTimer()
    PrepareMusicEvent(Constants.musicStart)
end

---@return boolean
function Shot1Phase:startAdvance()
    if not PrepareMusicEvent(Constants.musicStart) then
        return false
    end
    if not IsNewLoadSceneLoaded() and (GetGameTimer() - self.streamStart) < 5000 then
        return false
    end

    if not self.director.musicStarted then
        TriggerMusicEvent(Constants.musicStart)
        self.director.musicStarted = true
        return false
    end

    if GetMusicPlaytime() <= 0 then
        return false
    end

    NewLoadSceneStop()
    self.director:createScriptedCam(Constants.cams.shot1)
    if self.director.srlEnabled then
        self.director:srlReadahead(Constants.srlReadaheadNormal)
        BeginSrl()
        self.director.srlActive = true
    end
    if IsScreenFadedOut() then
        DoScreenFadeIn(Constants.fadeTime)
    end
    return true
end

---@return IntroStage[]
function Shot1Phase:stages()
    return {
        {
            name = "SHOT1_START",
            setup = function() self:enter() end,
            advance = function() return self:startAdvance() end,
        },
        {
            name = "SHOT1",
            setup = function() end,
            advance = function() return GetMusicPlaytime() >= Constants.stageTimes.shot1 end,
        },
    }
end
