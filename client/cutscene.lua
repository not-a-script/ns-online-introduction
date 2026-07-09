---@param index integer
---@return string
local function passengerModel(index)
    return Constants.femalePassengers[index] and Constants.femaleFreemodeModel or Constants.maleFreemodeModel
end

---@class Cutscene
---@field player integer
---@field isMale boolean
---@field passengers table<integer, integer>
---@field exhaustPtfx integer[]
---@field plane integer?
---@field lateApplied boolean
---@field tyreSmokeDone boolean
Cutscene = {}
Cutscene.__index = Cutscene

---@return Cutscene
function Cutscene.new()
    local self = setmetatable({}, Cutscene)
    self.player = PlayerPedId()
    self.isMale = IsPedMale(self.player)
    self.passengers = {}
    self.exhaustPtfx = {}
    self.lateApplied = false
    self.tyreSmokeDone = false
    return self
end

---@return boolean
function Cutscene:requestScene()
    local section = self.isMale and Constants.maleSection or Constants.femaleSection
    RequestCutsceneWithPlaybackList(Constants.cutsceneName, section, Constants.playbackFlags)
    return HasCutsceneLoaded()
end

function Cutscene:registerPlayer()
    local ownModel = self.isMale and Constants.maleModel or Constants.femaleModel
    local otherModel = self.isMale and Constants.femaleModel or Constants.maleModel
    local otherFreemode = self.isMale and Constants.femaleFreemodeModel or Constants.maleFreemodeModel

    RegisterEntityForCutscene(self.player, ownModel, Constants.registerAnimate, 0, 0)
    SetCutsceneEntityStreamingFlags(ownModel, 0, Constants.streamingKeepVariations)

    RegisterEntityForCutscene(0, otherModel, Constants.registerDontAnimate, GetHashKey(otherFreemode), 0)
end

---@param ped integer
function Cutscene:clearProps(ped)
    for prop = 0, 8 do
        ClearPedProp(ped, prop)
    end
end

---@param ped integer
---@param index integer
function Cutscene:dressPassenger(ped, index)
    local outfit = Constants.passengerOutfits[index]
    for component = 0, 11 do
        local variation = outfit[component]
        SetPedComponentVariation(ped, component, variation[1], variation[2], 0)
    end
    self:clearProps(ped)
end

function Cutscene:spawnPassengers()
    for index = 0, 6 do
        local model = passengerModel(index)
        Util.loadModel(model)
        local ped = CreatePed(Constants.pedTypeMission, GetHashKey(model), Constants.passengerX, Constants.passengerY, Constants.passengerZ, Constants.passengerHeading, false, false)
        SetModelAsNoLongerNeeded(GetHashKey(model))
        self.passengers[index] = ped

        self:dressPassenger(ped, index)
        FinalizeHeadBlend(ped)
        RegisterEntityForCutscene(ped, Constants.passengerEntities[index], Constants.registerAnimate, 0, Constants.registerIgnoreModel)
        SetCutsceneEntityStreamingFlags(Constants.passengerEntities[index], 0, Constants.streamingKeepVariations)
    end
end

function Cutscene:spawnPlane()
    Util.loadModel(Constants.planeModel)
    self.plane = CreateObject(GetHashKey(Constants.planeModel), Constants.planeX, Constants.planeY, Constants.planeZ, false, false, false)
    SetModelAsNoLongerNeeded(GetHashKey(Constants.planeModel))
    SetEntityLodDist(self.plane, Constants.planeLodDist)
    SetEntityVisible(self.plane, false, false)

    RequestNamedPtfxAsset(Constants.ptfxAsset)
    WaitUntil(function() return HasNamedPtfxAssetLoaded(Constants.ptfxAsset) end, "ptfx " .. Constants.ptfxAsset, 5000)
end

function Cutscene:registerPlane()
    SetEntityVisible(self.plane, true, false)
    RegisterEntityForCutscene(self.plane, Constants.planeEntity, Constants.registerAnimate, 0, 0)
end

function Cutscene:startExhaustPtfx()
    for _, offset in ipairs(Constants.exhaustOffsets) do
        UseParticleFxAsset(Constants.ptfxAsset)
        local handle = StartParticleFxLoopedOnEntity(Constants.exhaustEffect, self.plane, offset[1], offset[2], offset[3], 0.0, 0.0, 0.0, Constants.ptfxScale, false, false, false)
        self.exhaustPtfx[#self.exhaustPtfx + 1] = handle
    end
end

function Cutscene:maintainPtfx()
    if self.tyreSmokeDone then
        return
    end
    if GetCutsceneTime() > Constants.tyreSmokeTime then
        for _, offset in ipairs(Constants.tyreSmokeOffsets) do
            UseParticleFxAsset(Constants.ptfxAsset)
            StartParticleFxNonLoopedOnEntity(Constants.tyreSmokeEffect, self.plane, offset[1], offset[2], offset[3], 0.0, 0.0, 0.0, Constants.ptfxScale, false, false, false)
        end
        self.tyreSmokeDone = true
    end
end

---@param section integer
function Cutscene:applyClockForSection(section)
    if section >= Constants.taxiSection and not self.lateApplied then
        NetworkOverrideClockTime(Constants.lateHour, Constants.lateMinute, Constants.lateSecond)
        self.lateApplied = true
    end
end

function Cutscene:begin()
    NewLoadSceneStartSphere(Constants.loadSceneX, Constants.loadSceneY, Constants.loadSceneZ, Constants.loadSceneRadius, Constants.loadSceneFlags)
    NetworkOverrideClockTime(Constants.nightHour, Constants.nightMinute, Constants.nightSecond)
    StartCutscene(Constants.startFlags)
end

---@return boolean
function Cutscene:isPlaying()
    return IsCutscenePlaying()
end

function Cutscene:teardown()
    if IsCutscenePlaying() then
        StopCutscene(false)
    end
    for _, handle in ipairs(self.exhaustPtfx) do
        StopParticleFxLooped(handle, false)
    end
    for index = 0, 6 do
        if self.passengers[index] then
            DeleteEntity(self.passengers[index])
        end
    end
    if self.plane then
        DeleteEntity(self.plane)
    end
    NewLoadSceneStop()
end
