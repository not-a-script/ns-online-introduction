---@class SetupPhase
---@field director IntroDirector
---@field srlStart integer
---@field srlResolved boolean
SetupPhase = {}
SetupPhase.__index = SetupPhase

local SetSrlLongJumpMode = N_0x20c6c7e4eb082a7f

---@param director IntroDirector
---@return SetupPhase
function SetupPhase.new(director)
    local self = setmetatable({}, SetupPhase)
    self.director = director
    self.srlStart = 0
    self.srlResolved = false
    return self
end

function SetupPhase:enter()
    DoScreenFadeOut(Constants.fadeTime)
    PrefetchSrl(Constants.srlName)
    SetSrlLongJumpMode(true)
    self.srlStart = GetGameTimer()
end

---@return boolean
function SetupPhase:apply()
    if not IsScreenFadedOut() then
        return false
    end

    if not self.srlResolved then
        if IsSrlLoaded() then
            self.director.srlEnabled = true
            self.srlResolved = true
        elseif GetGameTimer() - self.srlStart >= Constants.srlLoadTimeout then
            self.director.srlEnabled = false
            self.srlResolved = true
        else
            return false
        end
    end

    SetOverrideWeather(Constants.overrideWeather)
    NetworkOverrideClockTime(Constants.initHour, Constants.initMinute, Constants.initSecond)

    self.director.scenarioBlock = AddScenarioBlockingArea(
        Constants.scenarioBlockMin[1], Constants.scenarioBlockMin[2], Constants.scenarioBlockMin[3],
        Constants.scenarioBlockMax[1], Constants.scenarioBlockMax[2], Constants.scenarioBlockMax[3],
        false, true, true, true)

    for _, area in ipairs(Constants.roadAreas) do
        SetRoadsInAngledArea(area.a[1], area.a[2], area.a[3], area.b[1], area.b[2], area.b[3], area.width, false, false, false)
    end

    local ped = PlayerPedId()
    SetEntityCoords(ped, Constants.freemodeCutStartPos[1], Constants.freemodeCutStartPos[2], Constants.freemodeCutStartPos[3], false, false, false, false)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)

    return true
end

---@return IntroStage[]
function SetupPhase:stages()
    return {
        {
            name = "INIT",
            setup = function() self:enter() end,
            advance = function() return self:apply() end,
        },
    }
end
