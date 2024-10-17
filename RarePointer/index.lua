local acclient = require("acclient")
local ubviews = require("utilitybelt.views")
local im = require("imgui")
local imgui = im.ImGui
local markercolor = 0xFFFFFF00
local markerdistance = 0.2
local markerscalex = 0.5
local markerscaley = 1
local markerscalez = 1
local markers = {}
local debug = false
local version = "1.1.0"

-- -- -- EVENT HANDLERS

-- this is a callback function which happens when an object is created
---@param evt ObjectCreatedEventArgs
function OnWorldObjectCreated(evt)
    local object = game.World.Get(evt.ObjectId)
    if (object.ObjectClass == ObjectClass.Corpse) then
        if object.HasAppraisalData then
            MarkRareCorpse(object.Id)
        else
            object.Appraise(nil,OnAppraisalComplete)
        end
    end
end

-- this is a callback function which happens when an object is released
---@param evt ObjectReleasedEventArgs
function OnWorldObjectReleased(evt) 
    for i = #markers, 1, -1 do
        local value = markers[i]
        if value.ObjectId == evt.ObjectId then
            table.remove(markers, i)
            ---@type DecalD3DShape
            value.Dispose()
        end
    end
end

-- this is a callback function to mark corpses after appraisal
---@param result ObjectAppraiseAction
function OnAppraisalComplete(result)
    local objID = result.ObjectId
    MarkRareCorpse(objID)
end

-- this is a callback function which happens when the script ends
---@param evt ScriptEventArgs
function OnScriptEnd(evt) 
    for i = #markers, 1, -1 do
        local value = markers[i]
        ---@type DecalD3DShape
        table.remove(markers, i)
        value.Dispose()
    end
end

-- -- -- FUNCTIONS

-- this function checks if an objectID contains the rare item syntax, and marks it with an arrow if so
function MarkRareCorpse(objID)
    local corpse = game.World.Get(objID)
    local longdesc = corpse.StringValues[StringId.LongDesc]

    if debug or string.find(longdesc, "This corpse generated a rare item!") then
        local marker = acclient.DecalD3D.NewD3DObj()
        marker.SetShape(acclient.DecalD3DShape.VerticalArrow)
        marker.ScaleX = markerscalex
        marker.ScaleY = markerscaley
        marker.ScaleZ = markerscalez
        marker.Color = markercolor
        marker.Anchor(objID,markerdistance,0,0,0)
        marker.Visible = true
        -- marker.OrientToPlayer(true)
        markers[objID] = marker
    end
end

print("[LUA]: Loading RarePointer v"..version)

local hud = ubviews.Huds.CreateHud("RarePointer v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

local markercolor_str = string.format("%08X", markercolor) -- Convert initial markercolor to hex string

hud.OnRender.Add(function()
    -- Checkbox for debug mode
    if imgui.Checkbox("Debug", debug) then
        debug = not debug
    end

    -- Input text for marker color
    local inputChanged, textResult = imgui.InputText("Marker Color (Hex)", markercolor_str, 500)

    if inputChanged then
        -- Ensure textResult is a string
        if textResult and type(textResult) == "string" then
            markercolor_str = textResult -- Update the string only when the user changes it
            -- Try to convert the string to a hex number
            local new_markercolor = tonumber(markercolor_str, 16)
            if new_markercolor then
                markercolor = new_markercolor -- Only update markercolor if conversion is successful
            end
        else
            markercolor_str = "FFFFFF00" -- Assign a default value if textResult is nil or not a string
        end
    end
end)


-- this should mark corpses whenever they're created
game.World.OnObjectCreated.Add(OnWorldObjectCreated)

-- this should remove the marker when the corpse is out of range or decays
game.World.OnObjectReleased.Add(OnWorldObjectReleased)

-- this should remove all markers when the script ends
game.OnScriptEnd.Add(OnScriptEnd)

-- this should mark corpses when the script is loaded
for index, value in ipairs(game.World.GetAll(ObjectClass.Corpse)) do
    ---@type WorldObject
    local object = value
    if object.HasAppraisalData then
        MarkRareCorpse(object.Id)
    else
        object.Appraise(nil,OnAppraisalComplete)
    end
end