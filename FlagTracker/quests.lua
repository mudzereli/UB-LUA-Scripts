local libQuest = {
    List = {},
    Dictionary = {}
}

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

function libQuest:TestQuestFlag(queststamp)
    local quest = self.Dictionary[queststamp]
    return quest ~= nil
end

function libQuest:GetFieldByID(quest, id)
    local fields = {
        quest.id,
        quest.solves,
        quest.timestamp,
        quest.description,
        quest.maxsolves,
        quest.delta,
        quest.expiretime
    }
    return fields[id] or quest.id
end

return libQuest