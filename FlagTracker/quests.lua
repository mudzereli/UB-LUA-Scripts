local libQuest = {
    List = {},
    Dictionary = {}
}

---@class Quest: Object
---@field id number
---@field solves number
---@field timestamp number
---@field description string
---@field maxsolves number
---@field delta number
---@field expiretime number

local function OnChatText(evt)
    local taskname, solves, timestamp, description, maxsolves, delta = string.match(evt.Message, "([%w%s%(%)-]+) %- (%d+) solves %((%d+)%)\"([^\"]+)\" (%-?%d+) (%d+)")
    if taskname and solves and timestamp and description and maxsolves and delta then
        table.insert(libQuest.List, {id=taskname,solves=solves,timestamp=timestamp,description=description,maxsolves=maxsolves,delta=delta,expiretime=timestamp+delta})
        libQuest.Dictionary[taskname] = {id=taskname,solves=solves,timestamp=timestamp,description=description,maxsolves=maxsolves,delta=delta,expiretime=timestamp+delta}
    end
end

function libQuest:Clear()
    self.List = {}
    self.Dictionary = {}
end

function libQuest:Refresh()
    self:Clear()
    game.OnTick.Once(function (evt)
        game.World.OnChatText.Add(OnChatText)
        sleep(100)
        game.Actions.InvokeChat("/myquests")
        sleep(3000)
        game.World.OnChatText.Remove(OnChatText)
    end)
end

function libQuest:IsQuestAvailable(queststamp)
    local quest = self.Dictionary[queststamp]
    if quest == nil then return true end
    return quest.expiretime < os.time()
end

function libQuest:IsQuestMaxSolved(queststamp)
    local quest = self.Dictionary[queststamp]
    if quest == nil then return false end
    if tonumber(quest.maxsolves) == tonumber(quest.solves) then return true end
    return false
end

function libQuest:HasQuestFlag(queststamp)
    local quest = self.Dictionary[queststamp]
    return quest ~= nil
end

function libQuest:GetFieldByID(quest, id)
    local fields = {
        quest.id,
        quest.solves,
        quest.timestamp,
        quest.maxsolves,
        quest.delta,
        quest.expiretime
    }
    return fields[id] or quest.id
end

function libQuest:FormatTimeStamp(time)
    return tostring(os.date("%m/%d/%Y %H:%M:%S", time))
end

function libQuest:FormatSeconds(seconds)
    if seconds <= 0 then
        return "0s"
    end
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)
    
    local result = ""
    if days > 0 then
        result = result .. days .. "d "
    end
    if hours > 0 then
        result = result .. hours .. "h "
    end
    if minutes > 0 then
        result = result .. minutes .. "m "
    end
    if seconds > 0 or result == "" then
        result = result .. seconds .. "s"
    end
    
    return result:match("^%s*(.-)%s*$") -- Trim any trailing space
end

function libQuest:GetTimeUntilExpire(quest)
    if quest == nil then return "Unknown" end
    local expireTime = self:FormatSeconds(quest.expiretime - os.time())
    if expireTime == "0s" then
        return "Ready"
    end
    return expireTime
end

return libQuest