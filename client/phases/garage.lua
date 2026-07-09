---@class GaragePhase
---@field director IntroDirector
GaragePhase = {}
GaragePhase.__index = GaragePhase

---@param director IntroDirector
---@return GaragePhase
function GaragePhase.new(director)
    local self = setmetatable({}, GaragePhase)
    self.director = director
    return self
end

function GaragePhase:preload()
    for i = 0, 7 do
        RequestModel(GetHashKey(Constants.garageCars[i].model))
    end
    RequestModel(GetHashKey(Constants.mechanic.model))
    RequestAnimDict(Constants.mechanic.dict)

    local d = self.director
    if not d.interior then
        d.interior = GetInteriorAtCoordsWithType(Constants.garageInteriorCoords[1], Constants.garageInteriorCoords[2], Constants.garageInteriorCoords[3], Constants.garageInteriorName)
        if d.interior ~= 0 then
            PinInteriorInMemory(d.interior)
        end
    end
end

---@param veh integer
---@param def GarageCarDef
function GaragePhase:applyCar(veh, def)
    SetVehicleDirtLevel(veh, 0.0)
    if def.bonnetOpen then
        SetVehicleDoorOpen(veh, 4, false, true)
    end
    if def.colours then
        SetVehicleColours(veh, def.colours[1], def.colours[2])
    end
    if def.extraColours then
        SetVehicleExtraColours(veh, def.extraColours[1], def.extraColours[2])
    end
    if def.modKit then
        SetVehicleModKit(veh, def.modKit)
    end
    if def.mods then
        for _, mod in ipairs(def.mods) do
            SetVehicleMod(veh, mod[1], mod[2], false)
        end
    end
    if def.xenon then
        ToggleVehicleMod(veh, Constants.modXenon, true)
    end
    SetVehicleTyresCanBurst(veh, false)
end

function GaragePhase:createMechanic()
    local d = self.director
    local def = Constants.mechanic
    local scene = CreateSynchronizedScene(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2)
    AttachSynchronizedSceneToEntity(scene, d.garageCars[def.attachTo], 0)

    local hash = Util.loadModel(def.model)
    local ped = CreatePed(Constants.pedTypeCivMale, hash, def.pos[1], def.pos[2], def.pos[3], def.heading, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskSynchronizedScene(ped, scene, def.dict, def.clip, def.blendIn, def.blendOut, def.sceneFlags, 0, def.blendIn, 0)
    SetSynchronizedSceneLooped(scene, true)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)

    for component = 0, 11 do
        local variation = def.components[component]
        SetPedComponentVariation(ped, component, variation[1], variation[2], 0)
    end
    for prop = 0, 8 do
        ClearPedProp(ped, prop)
    end
    SetModelAsNoLongerNeeded(hash)

    d.mechanic = ped
    d.mechanicScene = scene
end

function GaragePhase:createEntities()
    local d = self.director
    local roomHash = GetHashKey(Constants.garageRoomHash)

    RequestAnimDict(Constants.mechanic.dict)
    WaitUntil(function() return HasAnimDictLoaded(Constants.mechanic.dict) end, "mechanic anim", 5000)

    if not d.interior then
        d.interior = GetInteriorAtCoordsWithType(Constants.garageInteriorCoords[1], Constants.garageInteriorCoords[2], Constants.garageInteriorCoords[3], Constants.garageInteriorName)
    end
    if d.interior ~= 0 then
        PinInteriorInMemory(d.interior)
        WaitUntil(function() return IsInteriorReady(d.interior) end, "garage interior", 10000)
        ForceRoomForGameViewport(d.interior, roomHash)
    end

    for i = 0, 7 do
        local def = Constants.garageCars[i]
        local hash = Util.loadModel(def.model)
        local veh = CreateVehicle(hash, def.pos[1], def.pos[2], def.pos[3], def.heading, false, false)
        self:applyCar(veh, def)
        if d.interior ~= 0 then
            ForceRoomForEntity(veh, d.interior, roomHash)
        end
        SetModelAsNoLongerNeeded(hash)
        d.garageCars[i] = veh
    end

    self:createMechanic()
    if d.interior ~= 0 and d.mechanic then
        ForceRoomForEntity(d.mechanic, d.interior, roomHash)
    end

    SetStaticEmitterEnabled(Constants.garageRadioEmitter, false)
end

function GaragePhase:forceBonnet()
    local veh = self.director.garageCars[2]
    if veh and DoesEntityExist(veh) then
        SetVehicleDoorControl(veh, 4, 0, 1.0)
    end
end

function GaragePhase:resetMechanicScene()
    local d = self.director
    if d.mechanicScene and d.mechanic and DoesEntityExist(d.mechanic) then
        SetSynchronizedScenePhase(d.mechanicScene, 0.0)
        ForcePedAiAndAnimationUpdate(d.mechanic)
    end
end

---@param index integer
function GaragePhase:cleanupCar(index)
    local veh = self.director.garageCars[index]
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
    self.director.garageCars[index] = nil
    SetModelAsNoLongerNeeded(GetHashKey(Constants.garageCars[index].model))
end

function GaragePhase:startGarage()
    local d = self.director
    self:createEntities()
    d:createScriptedCam(Constants.cams.garage1)
    d:srlReadahead(Constants.srlReadaheadHeavy)
    self:resetMechanicScene()
    d:destroyRaceCam()
    if d.audioSceneStarted and IsAudioSceneActive(Constants.audioScene) then
        StopAudioScene(Constants.audioScene)
        d.audioSceneStarted = false
    end
    d:cleanupUberAssets()
    d:cleanupLogo()
end

---@return boolean
function GaragePhase:garage2StartAdvance()
    self:forceBonnet()
    if GetMusicPlaytime() < Constants.stageTimes.garage2Start then
        return false
    end
    self.director:applyScriptedCam(Constants.cams.garage2)
    self:resetMechanicScene()
    self:cleanupCar(0)
    self:cleanupCar(1)
    self:cleanupCar(5)
    self:cleanupCar(6)
    return true
end

function GaragePhase:garage4Start()
    local d = self.director
    local ped = PlayerPedId()
    SetEntityCoords(ped, Constants.airportWarp[1], Constants.airportWarp[2], Constants.airportWarp[3], false, false, false, false)
    d:applyScriptedCam(Constants.cams.garage4)
    NetworkOverrideClockTime(Constants.garageHour, 0, 0)
    self:cleanupCar(2)
    self:cleanupCar(7)
    if d.mechanic and DoesEntityExist(d.mechanic) then
        DeleteEntity(d.mechanic)
        d.mechanic = nil
    end
end

---@return boolean
function GaragePhase:garage4Advance()
    local d = self.director
    d.planePhase:requestScene()
    if GetMusicPlaytime() < Constants.stageTimes.garage4 then
        return false
    end
    if not PrepareMusicEvent(Constants.musicDriveStart) then
        return false
    end
    return d.planePhase:isLoaded()
end

---@return IntroStage[]
function GaragePhase:stages()
    return {
        {
            name = "START_GARAGE",
            setup = function() self:startGarage() end,
            advance = function() return true end,
        },
        {
            name = "GARAGE_2_START",
            setup = function() end,
            advance = function() return self:garage2StartAdvance() end,
        },
        {
            name = "GARAGE_2",
            setup = function() end,
            advance = function()
                self:forceBonnet()
                return GetMusicPlaytime() >= Constants.stageTimes.garage2
            end,
        },
        {
            name = "GARAGE_4_START",
            setup = function() self:garage4Start() end,
            advance = function() return true end,
        },
        {
            name = "GARAGE_4",
            setup = function() self.director.planePhase:requestScene() end,
            advance = function() return self:garage4Advance() end,
        },
    }
end
