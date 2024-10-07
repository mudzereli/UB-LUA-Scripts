local num_decimal_places = 20
local score_prefix = "Summon Damage Score: "
local version = "1.0.0.0"

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
        local DamRating = obj.Value(IntId.GearDamage)
        local CritRating = obj.Value(IntId.GearCrit)
        local CritDamageRating = obj.Value(IntId.GearCritDamage)
        local score = Round((0.625*(1+DamRating/100.00)*(.9-CritRating/100.00)+2*(1+(DamRating+CritDamageRating)/100.00)*(.1+CritRating/100.00))/0.01365,num_decimal_places)
        game.Actions.Inscribe(obj.Id,score_prefix..tostring(score))
    end
end

print("[LUA]: Loading SummonScribe v"..version)
-- Start Inscribing All Summons
for _, value in ipairs(game.Character.Inventory) do
    ---@type WorldObject
    local obj = value
    if obj.HasAppraisalData then
        MarkSummonStats(obj)
    else
        obj.Appraise(nil,OnAppraisalComplete)
    end
end