local num_decimal_places = 3
local score_prefix = "Summon Damage Score: "
local debug = false

local ubviews = require("utilitybelt.views")
local im = require("imgui")
local imgui = im.ImGui

local version = "1.1.0"

-- this is a rounding function used to round the results of the score
function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- this function calls the inscription function when an appraisal happens
---@param result ObjectAppraiseAction
function OnAppraisalComplete(result)
    MarkSummonStats(game.World.Get(result.ObjectId))
end

-- this function actually inscribes the summon
---@param obj WorldObject
function MarkSummonStats(obj)
    local PetClass = obj.Value(IntId.PetClass)
    if PetClass ~= 0 then
        if debug then print("Marking: "..obj.Name) end
        local DamRating = obj.Value(IntId.GearDamage)
        local CritRating = obj.Value(IntId.GearCrit)
        local CritDamageRating = obj.Value(IntId.GearCritDamage)
        local score = Round((0.625*(1+DamRating/100.00)*(.9-CritRating/100.00)+2*(1+(DamRating+CritDamageRating)/100.00)*(.1+CritRating/100.00))/0.01365,num_decimal_places)
        local res = await(game.Actions.Inscribe(obj.Id,score_prefix..tostring(score)))
        if debug and not res.Success then
            print("Failed to Mark: "..obj.Name.." : "..res.Error.." > "..res.ErrorDetails)
        end
    elseif debug then
        print("Skipping: "..obj.Name)
    end
end

-- this function starts inscribing all summons
function MarkAllSummons()
    for _, value in ipairs(game.Character.Inventory) do
        ---@type WorldObject
        local obj = value
        if string.find(obj.Name,"Essence") then
            if obj.HasAppraisalData then
                MarkSummonStats(obj)
            else
                if debug then print("Appraising... "..obj.Name) end
                local res = await(obj.Appraise(nil,OnAppraisalComplete))
                if debug and not res.Success then
                    print("Failed to Appraise: "..obj.Name.." : "..res.Error.." > "..res.ErrorDetails)
                end
            end
        end
    end
    print("[LUA]: All Summons have been inscribed!")
end

-- this code loads the HUD and runs when script is loaded
print("[LUA]: Loading SummonScribe v"..version)
local hud = ubviews.Huds.CreateHud("SummonScribe v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize
hud.OnRender.Add(function()
    -- Checkbox for debug mode
    if imgui.Checkbox("Debug", debug) then
        debug = not debug
    end
    -- Input text for variables
    local tInscriptionPrefixChanged, tInscriptionPrefixResult = imgui.InputText("Inscription Prefix",score_prefix,32)
    local iNumDecimalPlacesChanged, iNumDecimalPlacesResult = imgui.InputInt("Number of Decimal Places",num_decimal_places)
    local btnRun = imgui.Button("Run Summon Scribe")

    if iNumDecimalPlacesChanged and type(iNumDecimalPlacesResult) == "number" then
        num_decimal_places = iNumDecimalPlacesResult
    end
    if tInscriptionPrefixChanged and type(tInscriptionPrefixResult) == "string" then
        score_prefix = tInscriptionPrefixResult
    end
    if btnRun then
        MarkAllSummons()
    end
end)