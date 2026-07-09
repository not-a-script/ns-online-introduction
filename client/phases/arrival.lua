---@class ArrivalPhase
---@field director IntroDirector
---@field confirmed boolean
ArrivalPhase = {}
ArrivalPhase.__index = ArrivalPhase

---@param director IntroDirector
---@return ArrivalPhase
function ArrivalPhase.new(director)
    local self = setmetatable({}, ArrivalPhase)
    self.director = director
    self.confirmed = false
    return self
end

function ArrivalPhase:request()
    local name = self.director.isMale and Constants.arrivalCutsceneMale or Constants.arrivalCutsceneFemale
    RequestCutscene(name, 8)
end

---@return boolean
function ArrivalPhase:isLoaded()
    return HasCutsceneLoaded()
end

function ArrivalPhase:enter()
    local d = self.director
    local handle = d.isMale and Constants.arrivalPlayerHandleMale or Constants.arrivalPlayerHandleFemale

    RegisterEntityForCutscene(PlayerPedId(), handle, Constants.registerAnimate, 0, 0)
    if d.lamar.pedIGLamar then
        RegisterEntityForCutscene(d.lamar.pedIGLamar, Constants.arrivalLamarHandle, Constants.registerAnimate, 0, 0)
    end
    if d.lamar.vehLamar then
        RegisterEntityForCutscene(d.lamar.vehLamar, Constants.arrivalCarHandle, Constants.registerAnimate, 0, 0)
    end

    if IsAudioSceneActive(Constants.driveAudioScene) then
        StopAudioScene(Constants.driveAudioScene)
    end

    StartCutscene(Constants.startFlags)
end

function ArrivalPhase:placePlayer()
    local ped = PlayerPedId()
    SetEntityCoords(ped, Constants.arrivalPlayerPos[1], Constants.arrivalPlayerPos[2], Constants.arrivalPlayerPos[3], false, false, false, false)
    local dx = Constants.arrivalPlayerFace[1] - Constants.arrivalPlayerPos[1]
    local dy = Constants.arrivalPlayerFace[2] - Constants.arrivalPlayerPos[2]
    SetEntityHeading(ped, GetHeadingFromVector_2d(dx, dy))
end

---@return boolean
function ArrivalPhase:advance()
    local d = self.director

    if not self.confirmed then
        if IsCutscenePlaying() then
            RenderScriptCams(false, false, 0, true, false)
            d:destroyScriptedCam()
            d:destroyRaceCam()
            d.creditsPhase = "arrival"
            self.confirmed = true
        end
        return false
    end

    if IsCutscenePlaying() then
        return false
    end

    if not HasCutsceneFinished() then
        StopCutscene(false)
    end
    self:placePlayer()
    return true
end

---@return IntroStage[]
function ArrivalPhase:stages()
    return {
        {
            name = "MP_INT_MCS_5",
            setup = function() self:enter() end,
            advance = function() return self:advance() end,
        },
    }
end
