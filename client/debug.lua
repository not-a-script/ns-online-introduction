DEBUG = true

---@param fmt string
---@param ... any
function dprint(fmt, ...)
    if not DEBUG then
        return
    end
    if select("#", ...) > 0 then
        print("[intro] " .. fmt:format(...))
    else
        print("[intro] " .. fmt)
    end
end

---@param cond fun(): boolean
---@param label string
---@param timeoutMs integer
---@return boolean
function WaitUntil(cond, label, timeoutMs)
    local start = GetGameTimer()
    local nextLog = 500
    while not cond() do
        local elapsed = GetGameTimer() - start
        if elapsed >= timeoutMs then
            dprint("TIMEOUT %s after %dms — continuing", label, elapsed)
            return false
        end
        if elapsed >= nextLog then
            dprint("waiting %s... %dms", label, elapsed)
            nextLog = nextLog + 500
        end
        Wait(0)
    end
    dprint("loaded %s (%dms)", label, GetGameTimer() - start)
    return true
end
