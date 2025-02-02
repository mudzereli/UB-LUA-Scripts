Quest = {
    List = {},
    Dictionary = {},
    Clear = function()
        Quest.List = {}
        Quest.Dictionary = {}
    end,
    Refresh = function()
        Quest.Clear()
        game.OnTick.Once(function (evt)
            game.World.OnChatText.Add(OnChatText)
            sleep(100)
            game.Actions.InvokeChat("/myquests")
            sleep(3000)
            game.World.OnChatText.Remove(OnChatText)
        end)
    end
}

function OnChatText(evt)
    --print("hooked chat message")
    local taskname, solves, timestamp, description, maxsolves, delta = string.match(evt.Message, "([%w%s%(%)-]+) %- (%d+) solves %((%d+)%)\"([^\"]+)\" (%-?%d+) (%d+)")
    if taskname and solves and timestamp and description and maxsolves and delta then
        table.insert(Quest.List, {id=taskname,solves=solves,timestamp=timestamp,description=description,maxsolves=maxsolves,delta=delta})
        Quest.Dictionary[taskname] = {id=taskname,solves=solves,timestamp=timestamp,description=description,maxsolves=maxsolves,delta=delta}
    end
end

function IsQuestAvailable(queststamp)
    local quest = Quest.Dictionary[queststamp]
    if quest == nil then return true end
    local expiration = quest.timestamp + quest.delta
    return expiration < os.time()
end

function IsQuestMaxSolved(queststamp)
    local quest = Quest.Dictionary[queststamp]
    if quest == nil then return false end
    if tonumber(quest.maxsolves) == tonumber(quest.solves) then return true end
    return false
end

function TestQuestFlag(queststamp)
    local quest = Quest.Dictionary[queststamp]
    return quest ~= nil
end

function GetFieldByID(quest,id)
    if id == 1 then return quest.id
    elseif id == 2 then return quest.solves
    elseif id == 3 then return quest.timestamp
    elseif id == 4 then return quest.description
    elseif id == 5 then return quest.maxsolves
    elseif id == 6 then return quest.delta
    elseif id == 7 then return tostring(IsQuestAvailable(quest.id))
    end
    return quest.id
end

return Quest