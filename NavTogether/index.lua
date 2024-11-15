local maxDistance = 5
local intervalRangeCheck = 2
local debug = false
local tickcount = 0
local allInRange = true
local wasAllInRange = true  -- Track the previous state
local im = require("imgui")
local ubviews = require("utilitybelt.views")
local imgui = im.ImGui
local version = "1.0.0"

-- this function checks the distance between fellow members from the main character and disables nav if they're too far away
function CheckDistance()
    if debug then print("NavTogether: Checking Distance") end
    local fellowship = game.Character.Fellowship.Members
    allInRange = true  -- Assume all are in range initially

    for i in pairs(fellowship) do
        ---@type FellowshipMember
        local member = fellowship[i]
        local distance = game.Character.Weenie.DistanceTo3D(member.Id)
        if (distance > maxDistance) then
            allInRange = false  -- Set to false if any member is out of range
            break
        end
    end

    -- Only trigger the command if the range status has changed
    if allInRange ~= wasAllInRange then
        if allInRange then
            if debug then print("NavTogether: Enabling Navigation") end
            game.Actions.InvokeChat("/vt opt set EnableNav true")
        else
            if debug then print("NavTogether: Disabling Navigation") end
            game.Actions.InvokeChat("/vt opt set EnableNav false")
        end
        wasAllInRange = allInRange  -- Update the previous state
    end
end

-- Check Distance Every Tick
game.World.OnTick.Add(function() 
    tickcount = tickcount + 1
    if math.fmod(tickcount,intervalRangeCheck) == 0 then
        CheckDistance()
    end
end)

print("[LUA]: Loading NavTogether v"..version)
local hud = ubviews.Huds.CreateHud("NavTogether v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

hud.OnRender.Add(function()
    if imgui.Checkbox("Debug", debug) then
        debug = not debug
    end

    local iMaxDistanceChanged, iMaxDistanceResult = imgui.InputInt("Maximum Distance", maxDistance)
    local iIntervalRangeCheckChanged, iIntervalRangeCheckResult = imgui.InputInt("# of Seconds Between Range Checks", intervalRangeCheck)

    if iMaxDistanceChanged and type(iMaxDistanceResult) == "number" then
        maxDistance = iMaxDistanceResult
    end
    if iIntervalRangeCheckChanged and type(iIntervalRangeCheckResult) == "number" then
        intervalRangeCheck = iIntervalRangeCheckResult
    end
end)
