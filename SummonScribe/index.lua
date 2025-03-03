local ubviews = require("utilitybelt.views")
local im = require("imgui")
local imgui = im.ImGui
local version = "2.0.0"

-- Holds Script Settings
local Settings = {
    DebugOutput = true,
    ScorePrefix = "Summon Damage Score:",
    ScoreNumDecimalPlaces = 3,
    DefaultIconSize = Vector2.new(24,24)
}

---@class SummonObj: Object
---@field Name string
---@field Id number
---@field Icon number
---@field IconUnderlay number
---@field IconOverlay number
---@field DamageRating number
---@field CritRating number
---@field CritDamageRating number
---@field DamageResistRating number
---@field CritResistRating number
---@field CritDamageResistRating number
---@field Score number

-- Holds Summon Object
local SummonItems = {}

-- This Pulls a Summon Object Field by # (Used for Sorting)
function GetSummonFieldByID(so, id)
    --- @cast so SummonObj
    local fields = {
        so.Name,
        so.DamageRating,
        so.CritRating,
        so.CritDamageRating,
        so.DamageResistRating,
        so.CritResistRating,
        so.CritDamageResistRating,
        so.Score
    }
    return fields[id] or so.Name
end

-- this is a rounding function used to round the results of the score
function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Texture Caching
local function GetOrCreateTexture(iconID)
    if TextureCache == nil then
        TextureCache = {}
    end
    if iconID == nil then
        iconID = 0x06005CE6
    end
    local preloadedTexture = TextureCache[iconID]
    if not preloadedTexture then
        local texture = ubviews.Huds.GetIconTexture(iconID)
        if texture then
            TextureCache[iconID] = texture
            return texture
        end
    else
        return preloadedTexture
    end
end

-- this function calls the inscription function when an appraisal happens
---@param result ObjectAppraiseAction
function OnAppraisalComplete(result)
    MarkSummonStats(game.World.Get(result.ObjectId))
end

-- this function actually inscribes the summon
---@param obj WorldObject
function MarkSummonStats(obj)
    local SkillRequirement = obj.Value(IntId.UseRequiresSkill)
    if SkillRequirement ~= nil and SkillRequirement == 54 then
        if Settings.DebugOutput then 
            print("Marking: "..obj.Name) 
        end
        local SummonItem = {}
        local DamRating = obj.Value(IntId.GearDamage)
        local CritRating = obj.Value(IntId.GearCrit)
        local CritDamageRating = obj.Value(IntId.GearCritDamage)
        SummonItem.Name = obj.Name
        SummonItem.Id = obj.Id
        SummonItem.Icon = obj.DataValues[DataId.Icon]
        SummonItem.IconUnderlay = obj.DataValues[DataId.IconUnderlay]
        SummonItem.IconOverlay = obj.DataValues[DataId.IconOverlay]
        SummonItem.DamageRating = DamRating
        SummonItem.CritRating = CritRating
        SummonItem.CritDamageRating = CritDamageRating
        SummonItem.DamageResistRating = obj.Value(IntId.GearDamageResist)
        SummonItem.CritDamageResistRating = obj.Value(IntId.GearCritDamageResist)
        SummonItem.CritResistRating = obj.Value(IntId.GearCritResist)
        local score = Round((0.625*(1+DamRating/100.00)*(.9-CritRating/100.00)+2*(1+(DamRating+CritDamageRating)/100.00)*(.1+CritRating/100.00))/0.01365,Settings.ScoreNumDecimalPlaces)
        SummonItem.Score = score
        table.insert(SummonItems,SummonItem)
        local inscription = Settings.ScorePrefix.." "..tostring(score)
        local res = await(game.Actions.Inscribe(obj.Id,inscription))
        if Settings.DebugOutput and not res.Success then
            print("Failed to Mark: "..obj.Name.." : "..res.Error.." > "..res.ErrorDetails)
        end
    elseif Settings.DebugOutput then
        print("Skipping: "..obj.Name)
    end
end

-- this function starts inscribing all summons
function MarkAllSummons()
    SummonItems = {}
    for _, value in ipairs(game.Character.Inventory) do
        ---@type WorldObject
        local obj = value
        if string.find(obj.Name,"Essence") then
            if obj.HasAppraisalData then
                MarkSummonStats(obj)
            else
                if Settings.DebugOutput then 
                    print("Appraising... "..obj.Name) 
                end
                local res = await(obj.Appraise(nil,OnAppraisalComplete))
                if Settings.DebugOutput and not res.Success then
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
    if imgui.BeginTabBar("SummonScribe") then
        if imgui.BeginTabItem("Summons") then
            -- Button to Run the application
            if imgui.Button("Run Summon Scribe") then
                game.World.OnTick.Once(function()
                    MarkAllSummons()
                end)
            end
            if imgui.BeginTable("Summons",8, im.ImGuiTableFlags.ScrollY + im.ImGuiTableFlags.Sortable) then
                imgui.TableSetupColumn("Name", im.ImGuiTableColumnFlags.WidthFixed, 256)
                imgui.TableSetupColumn("DR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("CR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("CDR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("DRR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("CRR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("CDRR", im.ImGuiTableColumnFlags.WidthFixed, 48)
                imgui.TableSetupColumn("Score", im.ImGuiTableColumnFlags.WidthFixed, 64)
                imgui.TableSetupScrollFreeze(0, 1)
                imgui.TableHeadersRow()

                -- Handle sorting
                local sort_specs = imgui.TableGetSortSpecs()
                if sort_specs and sort_specs.SpecsDirty then
                    table.sort(SummonItems,function(a,b) 
                        local sortcol = sort_specs.Specs.ColumnIndex + 1
                        local sortasc = sort_specs.Specs.SortDirection == im.ImGuiSortDirection.Ascending
                        if a and b then
                            local valA = GetSummonFieldByID(a,sortcol)
                            local valB = GetSummonFieldByID(b,sortcol)
                            if valA and valB then
                                if tonumber(valA) and tonumber(valB) then
                                    ---@diagnostic disable-next-line
                                    valA = tonumber(valA)
                                    ---@diagnostic disable-next-line
                                    valB = tonumber(valB)
                                end
                                if sortasc then
                                    return valA < valB
                                else
                                    return valB < valA
                                end
                            end
                            return true
                        end
                        return true
                    end)
                    sort_specs.SpecsDirty = false -- Mark as sorted
                end

                for _, v in pairs(SummonItems) do
                    --- @cast v SummonObj
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    local pos = imgui.GetCursorScreenPos()
                    imgui.Image(GetOrCreateTexture(v.IconUnderlay).TexturePtr,Settings.DefaultIconSize)
                    imgui.SetCursorScreenPos(pos)
                    imgui.Image(GetOrCreateTexture(v.Icon).TexturePtr,Settings.DefaultIconSize)
                    imgui.SetCursorScreenPos(pos)
                    imgui.Image(GetOrCreateTexture(v.IconOverlay).TexturePtr,Settings.DefaultIconSize)
                    imgui.SameLine()
                    imgui.Text(v.Name)
                    if imgui.IsItemClicked() then
                        game.Actions.ObjectSelect(v.Id)
                    end
                    imgui.TableSetColumnIndex(1)
                    imgui.Text(tostring(v.DamageRating))
                    imgui.TableSetColumnIndex(2)
                    imgui.Text(tostring(v.CritRating))
                    imgui.TableSetColumnIndex(3)
                    imgui.Text(tostring(v.CritDamageRating))
                    imgui.TableSetColumnIndex(4)
                    imgui.Text(tostring(v.DamageResistRating))
                    imgui.TableSetColumnIndex(5)
                    imgui.Text(tostring(v.CritResistRating))
                    imgui.TableSetColumnIndex(6)
                    imgui.Text(tostring(v.CritDamageResistRating))
                    imgui.TableSetColumnIndex(7)
                    imgui.Text(tostring(v.Score))
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem("Settings") then
            -- Checkbox for Enabling Debug Mode
            if imgui.Checkbox("Debug", Settings.DebugOutput) then
                Settings.DebugOutput = not Settings.DebugOutput
            end

            -- Input for Inscription Prefix
            local tInscriptionPrefixChanged, tInscriptionPrefixResult = imgui.InputText("Inscription Prefix",Settings.ScorePrefix,32)
            if tInscriptionPrefixChanged and type(tInscriptionPrefixResult) == "string" then
                Settings.ScorePrefix = tInscriptionPrefixResult
            end

            -- Input for Score Number of Decimal Places
            local iNumDecimalPlacesChanged, iNumDecimalPlacesResult = imgui.InputInt("Number of Decimal Places",Settings.ScoreNumDecimalPlaces)
            if iNumDecimalPlacesChanged and type(iNumDecimalPlacesResult) == "number" then
                Settings.ScoreNumDecimalPlaces = iNumDecimalPlacesResult
            end

            -- Button to Run the application
            if imgui.Button("Run Summon Scribe") then
                game.World.OnTick.Once(function()
                    MarkAllSummons()
                end)
            end
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
    end
end)