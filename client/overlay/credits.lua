---@class CreditsOverlay
---@field isMale boolean
---@field handle integer?
---@field shown table<integer, boolean>
---@field hidden table<integer, boolean>
CreditsOverlay = {}
CreditsOverlay.__index = CreditsOverlay

---@param isMale boolean
---@return CreditsOverlay
function CreditsOverlay.new(isMale)
    local self = setmetatable({}, CreditsOverlay)
    self.isMale = isMale
    self.shown = {}
    self.hidden = {}
    return self
end

---@return boolean
function CreditsOverlay:request()
    if not self.handle then
        self.handle = RequestScaleformMovie(Constants.creditsScaleform)
    end
    local loaded = HasScaleformMovieLoaded(self.handle)
    if loaded and not self.loggedLoad then
        self.loggedLoad = true
    end
    return loaded
end

---@param str string
function CreditsOverlay:pushText(str)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandScaleformString()
end

---@param id string
---@param x number
---@param y number
---@param align string
---@param wipeIn number
---@param wipeOut number
---@param gap number
---@param roles table[]
---@param names table[]
function CreditsOverlay:emit(id, x, y, align, wipeIn, wipeOut, gap, roles, names)
    BeginScaleformMovieMethod(self.handle, "SETUP_CREDIT_BLOCK")
    self:pushText(id)
    ScaleformMovieMethodAddParamFloat(x)
    ScaleformMovieMethodAddParamFloat(y)
    self:pushText(align)
    ScaleformMovieMethodAddParamFloat(wipeIn)
    ScaleformMovieMethodAddParamFloat(wipeOut)
    EndScaleformMovieMethod()

    for _, role in ipairs(roles) do
        BeginScaleformMovieMethod(self.handle, "ADD_ROLE_TO_CREDIT_BLOCK")
        self:pushText(id)
        self:pushText(role[1])
        ScaleformMovieMethodAddParamFloat(role[2])
        self:pushText(role[3])
        ScaleformMovieMethodAddParamBool(true)
        EndScaleformMovieMethod()
    end

    for _, entry in ipairs(names) do
        BeginScaleformMovieMethod(self.handle, "ADD_NAMES_TO_CREDIT_BLOCK")
        self:pushText(id)
        self:pushText(entry[1])
        ScaleformMovieMethodAddParamFloat(entry[2])
        self:pushText("|")
        ScaleformMovieMethodAddParamBool(true)
        EndScaleformMovieMethod()
    end

    BeginScaleformMovieMethod(self.handle, "SHOW_CREDIT_BLOCK")
    self:pushText(id)
    ScaleformMovieMethodAddParamFloat(gap)
    EndScaleformMovieMethod()
end

---@param id string
---@param gap number
function CreditsOverlay:hide(id, gap)
    BeginScaleformMovieMethod(self.handle, "HIDE")
    self:pushText(id)
    ScaleformMovieMethodAddParamFloat(gap)
    EndScaleformMovieMethod()
end

---@param driveTime integer
function CreditsOverlay:updateDrive(driveTime)
    for i, block in ipairs(Constants.creditBlocks) do
        if not self.shown[i] then
            if driveTime >= block.show then
                self:emit(block.id, block.x, block.y, block.align, block.wipeIn, block.wipeOut, block.gap, block.roles, block.names)
                self.shown[i] = true
            end
        elseif not self.hidden[i] then
            if driveTime >= block.hide then
                self:hide(block.id, block.gap)
                self.hidden[i] = true
            end
        end
    end
end

---@param driveTime integer
---@param arrivalTime integer
function CreditsOverlay:updateArrival(driveTime, arrivalTime)
    for i, block in ipairs(Constants.creditBlocksArrival) do
        local key = 100 + i
        local showTime = self.isMale and block.showMale or block.showFemale
        local hideTime = self.isMale and block.hideMale or block.hideFemale
        local showOnDrive = self.isMale and block.showMaleDrive

        if not self.shown[key] then
            local ready = showOnDrive and driveTime >= showTime or (not showOnDrive and arrivalTime >= 0 and arrivalTime >= showTime)
            if ready then
                local x = self.isMale and block.xMale or block.xFemale
                local y = self.isMale and block.yMale or block.yFemale
                local align = self.isMale and block.alignMale or block.alignFemale
                local roleX = self.isMale and block.roleXMale or block.roleXFemale
                local nameX = self.isMale and block.nameXMale or block.nameXFemale
                self:emit(block.id, x, y, align, Constants.creditWipeIn, Constants.creditWipeOut, Constants.creditWipeGap,
                    { { block.role, roleX, block.colour } }, { { block.names, nameX } })
                self.shown[key] = true
            end
        elseif not self.hidden[key] then
            if arrivalTime >= 0 and arrivalTime >= hideTime then
                self:hide(block.id, Constants.creditWipeGap)
                self.hidden[key] = true
            end
        end
    end
end

---@param driveTime integer
---@param arrivalTime integer
function CreditsOverlay:tick(driveTime, arrivalTime)
    self:updateDrive(driveTime)
    self:updateArrival(driveTime, arrivalTime)
    DrawScaleformMovieFullscreen(self.handle, 255, 255, 255, 255, 0)
end

function CreditsOverlay:cleanup()
    if self.handle and HasScaleformMovieLoaded(self.handle) then
        SetScaleformMovieAsNoLongerNeeded(self.handle)
    end
end
