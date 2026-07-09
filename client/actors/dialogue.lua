---@class LamarDialogue
---@field director IntroDirector
---@field index integer
LamarDialogue = {}
LamarDialogue.__index = LamarDialogue

---@param director IntroDirector
---@return LamarDialogue
function LamarDialogue.new(director)
    local self = setmetatable({}, LamarDialogue)
    self.director = director
    self.index = 1
    return self
end

function LamarDialogue:init()
    RequestAdditionalText(Constants.dialogueTextBlock, Constants.dialogueTextSlot)
    WaitUntil(function() return HasAdditionalTextLoaded(Constants.dialogueTextSlot) end, "FMINT dialogue text", 5000)
end

---@param root string
---@param label string
function LamarDialogue:playLine(root, label)
    local ped = self.director.lamar.pedIGLamar
    CreateNewScriptedConversation()
    AddPedToConversation(1, ped, Constants.lamarSpeaker)
    AddLineToConversation(0, root, label, 1, 1, true, false, false, false, -1, true, false, false)
    StartScriptConversation(false, true, false, false)
end

---@param driveTime integer
function LamarDialogue:tick(driveTime)
    local lines = self.director.isMale and Constants.lamarLines.male or Constants.lamarLines.female
    if self.index > #lines then
        return
    end
    local line = lines[self.index]
    if driveTime < line.time or IsScriptedConversationOngoing() then
        return
    end
    self:playLine(line.root, line.label)
    self.index = self.index + 1
end
