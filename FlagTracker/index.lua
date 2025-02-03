local im = require("imgui")
local ubviews = require("utilitybelt.views")
local Quest = require("quests")
local imgui = im.ImGui
local version = "1.3.3"
local currentHUDPosition = nil
local defaultHUDposition = Vector2.new(500,100)

local augmentations = {
    ["Death Augs"] = {
        {"Keep Items",IntId.AugmentationLessDeathItemLoss,3,"Rohula bint Ludun","Ayan Baqur"},
        {"Keep Spells",IntId.AugmentationSpellsRemainPastDeath,1,"Erik Festus","Ayan Baqur"}
    },
    ["Skill Augs"] = {
        {"+5 All Skills",IntId.AugmentationJackOfAllTrades,1,"Arianna the Adept","Bandit Castle"},
        {"+10 Melee Skills",IntId.AugmentationSkilledMelee,1,"Carlito Gallo","Silyun"},
        {"+10 Magic Skills",IntId.AugmentationSkilledMagic,1,"Rahina bint Zalanis","Zaikhal"},
        {"+10 Missile Skills",IntId.AugmentationSkilledMissile,1,"Kilaf","Zaikhal"}
    },
    ["Rating Augs"] = {
        {"25%% Crit Protection",IntId.AugmentationCriticalDefense,1,"Piersanti Linante","Sanamar"},
        {"1%% Critical Chance",IntId.AugmentationCriticalExpertise,1,"Anfram Mellow","Ayan Baqur"},
        {"3%% Critical Damage",IntId.AugmentationCriticalPower,1,"Alishia bint Aldan","Ayan Baqur"},
        {"3%% Damage Rating",IntId.AugmentationDamageBonus,1,"Neela Nashua","Bandit Castle"},
        {"3%% Damage Reduction",IntId.AugmentationDamageReduction,1,"Emily Yarow","Cragstone"}
    },
    ["Burden / Pack Augs"] = {
        {"Extra Carrying Capacity",IntId.AugmentationIncreasedCarryingCapacity,5,"Husoon","Zaikhal"},
        {"Extra Pack Slot",IntId.AugmentationExtraPackSlot,1,"Dumida bint Ruminre","Zaikhal"},
        {"Infused War Magic",IntId.AugmentationInfusedWarMagic,1,"Raphel Detante","Silyun"},
        {"Infused Void Magic",IntId.AugmentationInfusedVoidMagic,1,"Morathe","Candeth Keep"},
        {"Infused Creature Magic",IntId.AugmentationInfusedCreatureMagic,1,"Gustuv Lansdown","Cragstone"},
        {"Infused Life Magic",IntId.AugmentationInfusedLifeMagic,1,"Akemi Fei","Hebian-To"},
        {"Infused Item Magic",IntId.AugmentationInfusedItemMagic,1,"Gan Fo","Hebian-To"}
    },
    ["Misc Augs"] = {
        {"10%% Health Increase",nil,1,"Donatello Linante","Silyun"},
        {"Increased Spell Duration",IntId.AugmentationIncreasedSpellDuration,5,"Nawamara Ujio","Mayoi"},
        {"Faster HP Regen",IntId.AugmentationFasterRegen,2,"Alison Dulane","Bandit Castle"},
        {"5%% Experience Increase",IntId.AugmentationBonusXp,1,"Rickard Dumalia","Silyun"}
    },
    ["Salvage Augs"] = {
        {"Specialized Weapon Tinkering",IntId.AugmentationSpecializeWeaponTinkering,1,"Lenor Turk","Cragstone"},
        {"Specialized Armor Tinkering",IntId.AugmentationSpecializeArmorTinkering,1,"Joshun Felden","Cragstone"},
        {"Specialized Item Tinkering",IntId.AugmentationSpecializeItemTinkering,1,"Brienne Carlus","Cragstone"},
        {"Specialized Magic Item Tinkering",IntId.AugmentationSpecializeMagicItemTinkering,1,"Burrell Sammrun","Cragstone"},
        --{"Specialized GearCraft",IntId.AugmentationSpecializeGearcraft,1,"Alex Brummel","Cragstone"},
        {"Specialized Salvaging",IntId.AugmentationSpecializeSalvaging,1,"Robert Crow","Cragstone"},
        {"25%% More Salvage",IntId.AugmentationBonusSalvage,4,"Kris Cennis","Cragstone"},
        {"5%% Imbue Chance",IntId.AugmentationBonusImbueChance,1,"Lug","Oolutanga's Refuge"}
    },
    ["Stat Augs"] = {
        {"All Stats",IntId.AugmentationInnateFamily,10},
        {"Strength",IntId.AugmentationInnateStrength,10,"Fiun Luunere","Fiun Outpost"},
        {"Endurance",IntId.AugmentationInnateEndurance,10,"Fiun Ruun","Fiun Outpost"},
        {"Coordination",IntId.AugmentationInnateCoordination,10,"Fiun Bayaas","Fiun Outpost"},
        {"Quickness",IntId.AugmentationInnateQuickness,10,"Fiun Riish","Fiun Outpost"},
        {"Focus",IntId.AugmentationInnateFocus,10,"Fiun Vasherr","Fiun Outpost"},
        {"Self",IntId.AugmentationInnateSelf,10,"Fiun Noress","Fiun Outpost"}
    },
    ["Resistance Augs"] = {
        {"All Resistances",IntId.AugmentationResistanceFamily,2},
        {"Blunt",IntId.AugmentationResistanceBlunt,2,"Nawamara Dia","Hebian-To"},
        {"Pierce",IntId.AugmentationResistancePierce,2,"Kyujo Rujen","Hebian-To"},
        {"Slashing",IntId.AugmentationResistanceSlash,2,"Ilin Wis","Hebian-To"},
        {"Fire",IntId.AugmentationResistanceFire,2,"Rikshen Ri","Hebian-To"},
        {"Frost",IntId.AugmentationResistanceFrost,2,"Lu Bao","Hebian-To"},
        {"Acid",IntId.AugmentationResistanceAcid,2,"Shujio Milao","Hebian-To"},
        {"Lightning",IntId.AugmentationResistanceLightning,2,"Enli Yuo","Hebian-To"}
    }
}
local augTreeOpenStates = {
    ["Stat Augs"] = false,
    ["Resistance Augs"] = false
}
local luminanceauras = {
    ["Nalicana Auras"] = {
        {"+1 Aetheria Proc Rating",IntId.LumAugSurgeChanceRating,5},
        {"+1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5},
        {"+1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5},
        {"+1 Damage Rating",IntId.LumAugDamageRating,5},
        {"+1 Crit Damage Rating",IntId.LumAugCritDamageRating,5},
        {"+1 Heal Rating",IntId.LumAugHealingRating,5},
        {"+1 Equipment Mana Rating",IntId.LumAugItemManaUsage,5},
        {"+1 Mana Stone Rating",IntId.LumAugItemManaGain,5},
        {"+1 Crafting Skills",IntId.LumAugSkilledCraft,5},
        {"+1 All Skills",IntId.LumAugAllSkills,10},
    },
    ["Seer Auras"] = {
        {"+2 Specialized Skills",IntId.LumAugSkilledSpec,5},
        {"+1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5},
        {"+1 Damage Rating",IntId.LumAugDamageRating,5},
        {"+1 Crit Damage Rating",IntId.LumAugCritDamageRating,5},
        {"+1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5}
    }
}
local recallspells = {
    {"Recall the Sanctuary",2023},
    {"Aerlinthe Recall",2041},
    {"Mount Lethe Recall",2813},
    {"Recall Aphus Lassel",2931},
    {"Ulgrim's Recall",2941},
    {"Recall to the Singularity Caul",2943},
 --   {"Ulgrim's Recall",3856},
    {"Glenden Wood Recall",3865},
    {"Bur Recall",4084},
    {"Call of the Mhoire Forge",4128},
    {"Paradox-touched Olthoi Infested Area Recall",4198},
    {"Colosseum Recall",4213},
    {"Return to the Keep",4214},
    {"Gear Knight Invasion Area Camp Recall",5330},
    {"Lost City of Neftet Recall",5541},
    {"Rynthid Recall",6150},
    {"Viridian Rise Recall",6321},
    {"Viridian Rise Great Tree Recall",6322}
}
local typeQuest = 0
local typeAetheria = 2
--[[
TO ADD:
    - Factions (Rossu Morta / Whispering Blade)
    - Society / Rank
    - Gauntlet ?
    - Dereth Explorer
    - Enlightenment
    - Paragon
]]--
local characterflags = {
    ["Additional Skill Credits"] = {
        {typeQuest,"+1 Skill Lum Aura","lumaugskillquest",2,2},
        {typeQuest,"+1 Skill Aun Ralirea","arantahkill1",1,2},
        {typeQuest,"+1 Skill Chasing Oswald","oswaldmanualcompleted",1,2},
    },
    ["Aetheria"] = {
        {typeAetheria,"Blue Aetheria (75)",IntId.AetheriaBitfield,1},
        {typeAetheria,"Yellow Aetheria (150)",IntId.AetheriaBitfield,2},
        {typeAetheria,"Red Aetheria (225)",IntId.AetheriaBitfield,4},
    },
    ["Augmentation Gems"] = {
        {typeQuest,"Sir Bellas","augmentationblankgemacquired",1,3},
        {typeQuest,"Gladiator Diemos Token","pickedupmarkerboss10x",1,3},
        {typeQuest,"100K Luminance Gem","blankaugluminancetimer_0511",1,3},
    },
    ["Other Flags"] = {
        {typeQuest,"Candeth Keep Treehouse","strongholdbuildercomplete",1,2},
        {typeQuest,"Bur Flag (Portal)","burflagged(permanent)",1,2},
        {typeQuest,"Singularity Caul","virindiisland",1,2},
        {typeQuest,"Vissidal Island","vissflagcomplete",1,2},
        {typeQuest,"Dark Isle","darkisleflagged",1,2},
        {typeQuest,"Luminance Flag","oracleluminancerewardsaccess_1110",1,2},
        {typeQuest,"Diemos Access","golemstonediemosgiven",1,2}
    }
}
local characterflagTreeOpenStates = {}
local coloryellow = Vector4.new(1,1,0,1)
local colorred = Vector4.new(1,0,0,1)
local colorgreen = Vector4.new(0,1,0,1)

print("[LUA]: Loading FlagTracker v"..version)

local hud = ubviews.Huds.CreateHud("FlagTracker v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize
local flagTreeRenderStatus = {}
local flagTreeInitialOpenStatus = {}

hud.OnRender.Add(function()
    local char = game.Character.Weenie
    if char == nil then return end
    if imgui.BeginTabBar("Flag Tracker Bar") then

        -- Augmentations Tab
        if imgui.BeginTabItem("Augmentations") then
            for category, augList in pairs(augmentations) do
                imgui.Separator()
                imgui.SetNextItemOpen(augTreeOpenStates[category] == nil or augTreeOpenStates[category])
                local isTreeNodeOpen = imgui.TreeNode(category)
                augTreeOpenStates[category] = isTreeNodeOpen
                if isTreeNodeOpen then
                    -- Create a new table for this category
                    local numColumns = 2
                    if imgui.BeginTable("Augmentations_" .. category, numColumns * 2) then
                        imgui.TableSetupColumn("Aug 1", im.ImGuiTableColumnFlags.WidthStretch, 200)
                        imgui.TableSetupColumn("Aug 1 Points", im.ImGuiTableColumnFlags.WidthStretch, 35)
                        imgui.TableSetupColumn("Aug 2", im.ImGuiTableColumnFlags.WidthStretch, 200)
                        imgui.TableSetupColumn("Aug 2 Points", im.ImGuiTableColumnFlags.WidthStretch, 35)

                        local currentColumnIndex = 0

                        for _, augInfo in ipairs(augList) do
                            local prefix = augInfo[1]
                            local augID = augInfo[2]
                            local cap = augInfo[3]
                            local npc = augInfo[4]
                            local town = augInfo[5]
                            local value = 0
                            if augID == nil then
                                value = game.Character.GetInventoryCount("Asheron's Lesser Benediction")
                            else
                                value = char.Value(augID)
                            end

                            local color = coloryellow
                            if value >= cap then
                                color = colorgreen
                            elseif value == 0 then
                                color = colorred
                            end

                            if currentColumnIndex == 0 then
                                imgui.TableNextRow()
                            end

                            imgui.TableSetColumnIndex(currentColumnIndex)
                            imgui.TextColored(color, prefix)

                            if imgui.IsItemHovered() and npc and town then
                                imgui.SetTooltip(string.format("NPC: %s\nTown: %s", npc, town))
                            end

                            if imgui.IsItemClicked() and npc then
                                local npcObject = game.World.GetNearest(npc, DistanceType.T3D)
                                if npcObject then
                                    game.Actions.ObjectSelect(npcObject.Id)
                                end
                            end

                            currentColumnIndex = (currentColumnIndex + 1) % (numColumns * 2)
                            imgui.TableSetColumnIndex(currentColumnIndex)
                            imgui.TextColored(color, value .. "/" .. cap)
                            currentColumnIndex = (currentColumnIndex + 1) % (numColumns * 2)
                        end

                        imgui.EndTable()
                    end

                    imgui.TreePop()
                end
            end

            imgui.EndTabItem()
        end

        -- Luminance Auras Tab
        if imgui.BeginTabItem("Luminance Auras") then
            for category, auraList in pairs(luminanceauras) do
                imgui.SeparatorText(category)
                if imgui.BeginTable("Luminance Auras_"..category, 2) then
                    imgui.TableSetupColumn("Lum Aura",im.ImGuiTableColumnFlags.WidthStretch,200)
                    imgui.TableSetupColumn("Lum Aura Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    for _, auraInfo in ipairs(auraList) do
                        local value = char.Value(auraInfo[2]) or 0
                        local prefix = auraInfo[1]
                        local cap = auraInfo[3]
                        local color = coloryellow
    
                        if value >= cap and category == "Nalicana Auras" then
                            value = cap
                        elseif category == "Seer Auras" and auraInfo[2] ~= IntId.LumAugSkilledSpec then
                            value = math.max(0,value-5)
                        end
    
                        if value >= cap then
                            color = colorgreen
                        elseif value == 0 then
                            color = colorred
                        end
    
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.TextColored(color, prefix)
                        imgui.TableSetColumnIndex(1)
                        imgui.TextColored(color, value .. "/" .. cap)
                    end
                    imgui.EndTable()
                end
            end
            imgui.EndTabItem()
        end

        -- Recall Spells Tab
        if imgui.BeginTabItem("Recalls") then
            if imgui.BeginTable("Recall Spells",2) then
                imgui.TableSetupColumn("RecallColumn1")
                imgui.TableSetupColumn("RecallColumn2")
                for _,recallInfo in ipairs(recallspells) do
                    local spellName = recallInfo[1]
                    local spellID = recallInfo[2]
                    local spellKnown = game.Character.SpellBook.IsKnown(spellID)
                    local color = colorred
                    local status = "Unknown"
                    if spellKnown then
                        color = colorgreen
                        status = "Known"
                    end
                    imgui.TableNextRow()
                    imgui.TableNextColumn()
                    imgui.TextColored(color,spellName)
                    imgui.TableNextColumn()
                    imgui.TextColored(color,status)
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end

        -- Character Flags Tab
        if imgui.BeginTabItem("Flags") then
            for category, flagInfo in pairs(characterflags) do
                imgui.Separator()
                imgui.SetNextItemOpen(characterflagTreeOpenStates[category] == nil or characterflagTreeOpenStates[category])
                local isTreeNodeOpen = imgui.TreeNode(category)
                characterflagTreeOpenStates[category] = isTreeNodeOpen
                if isTreeNodeOpen then
                    if imgui.BeginTable("Character Flags_"..category, 2) then
                        imgui.TableSetupColumn("Flag 1",im.ImGuiTableColumnFlags.WidthStretch,128)
                        imgui.TableSetupColumn("Flag 1 Points",im.ImGuiTableColumnFlags.WidthStretch,64)
                            for _, flag in ipairs(flagInfo) do
                                imgui.TableNextRow()
                                imgui.TableSetColumnIndex(0)
                                imgui.TableSetColumnIndex(1)
                                local type = flag[1]
                                local prefix
                                local cap
                                local value = 0
                                if type == typeQuest then
                                    prefix = flag[2]
                                    cap = flag[4]
                                    local queststamp = flag[3]
                                    local questfield = flag[5]
                                    local quest = Quest.Dictionary[queststamp]
                                    if quest ~= nil then
                                        if questfield == 3 then
                                            if not Quest:IsQuestAvailable(queststamp) then
                                                value = 1
                                            end
                                        else
                                            value = (tonumber(quest.solves) or 0)
                                        end
                                    end
                                elseif type == typeAetheria then
                                    prefix = flag[2]
                                    local bitreq = flag[4]
                                    local bitfield = flag[3]
                                    ---@diagnostic disable-next-line
                                    local bitvalue = char.Value(bitfield)
                                    if bitvalue >= bitreq then
                                        value = 1
                                    end 
                                    cap = 1
                                end
                                local color = coloryellow
                                if value >= cap then
                                    color = colorgreen
                                elseif value == 0 then
                                    color = colorred
                                end
                                local completionString = "Yes"
                                if category == "Additional Skill Credits" then
                                    completionString = tostring(value) .. "/" .. tostring(cap)
                                elseif category == "Augmentation Gems" then
                                    local queststamp = flag[3]
                                    local quest = Quest.Dictionary[queststamp]
                                    if quest == nil then 
                                        completionString = "Augs"
                                    else
                                        completionString = Quest:FormatSeconds(quest.expiretime-os.time())
                                    end
                                elseif value < cap then
                                    completionString = "No"
                                end
                                imgui.TableNextRow()
                                imgui.TableSetColumnIndex(0)
                                imgui.TextColored(color, prefix)
                                imgui.TableSetColumnIndex(1)
                                imgui.TextColored(color, completionString)
                            end
                        imgui.EndTable()
                    end
                    imgui.TreePop()
                end
            end
            imgui.EndTabItem()
        end

        -- General Quests Tab
        if imgui.BeginTabItem("Quests") then
            if imgui.Button("Refresh Quests") then
                Quest:Refresh()
            end
            -- Quests Table
            if imgui.BeginTable("Quests", 7, im.ImGuiTableFlags.ScrollY + im.ImGuiTableFlags.Sortable) then
                imgui.TableSetupColumn("Quest", im.ImGuiTableColumnFlags.WidthFixed, 256)
                imgui.TableSetupColumn("#", im.ImGuiTableColumnFlags.WidthFixed, 64)
                imgui.TableSetupColumn("TimeStamp", im.ImGuiTableColumnFlags.WidthFixed, 128)
                imgui.TableSetupColumn("Description", im.ImGuiTableColumnFlags.WidthFixed, 256)
                imgui.TableSetupColumn("Max", im.ImGuiTableColumnFlags.WidthFixed, 64)
                imgui.TableSetupColumn("Delta", im.ImGuiTableColumnFlags.WidthFixed, 64)
                imgui.TableSetupColumn("Expire", im.ImGuiTableColumnFlags.WidthFixed, 128)
                imgui.TableSetupScrollFreeze(0, 1)
                imgui.TableHeadersRow()
        
                -- Handle sorting
                local sort_specs = imgui.TableGetSortSpecs()
                if sort_specs and sort_specs.SpecsDirty then
                    table.sort(Quest.List,function(a,b) 
                        local sortcol = sort_specs.Specs.ColumnIndex + 1
                        local sortasc = sort_specs.Specs.SortDirection == im.ImGuiSortDirection.Ascending
                        if a and b then
                            local valA = Quest:GetFieldByID(a,sortcol)
                            local valB = Quest:GetFieldByID(b,sortcol)
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

                -- Populate table
                for _, quest in ipairs(Quest.List) do
                    local color = colorred
                    if Quest:IsQuestMaxSolved(quest.id) then
                        color = coloryellow
                    elseif Quest:IsQuestAvailable(quest.id) then
                        color = colorgreen
                    end
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.TextColored(color, quest.id) -- Quest Name
                    imgui.TableSetColumnIndex(1)
                    imgui.TextColored(color, quest.solves) -- Solves
                    imgui.TableSetColumnIndex(2)
                    imgui.TextColored(color, Quest:FormatTimeStamp(quest.timestamp)) -- Timestamp
                    imgui.TableSetColumnIndex(3)
                    imgui.TextColored(color, quest.description) -- Description
                    imgui.TableSetColumnIndex(4)
                    imgui.TextColored(color, quest.maxsolves) -- MaxSolves
                    imgui.TableSetColumnIndex(5)
                    imgui.TextColored(color, quest.delta) -- Delta
                    imgui.TableSetColumnIndex(6)
                    imgui.TextColored(color, Quest:FormatSeconds(quest.expiretime - os.time())) -- Expired
                end
        
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        
        imgui.EndTabBar()
    end

    if currentHUDPosition == nil then
        imgui.SetWindowPos(defaultHUDposition)
        currentHUDPosition = imgui.GetWindowPos()
    end
end)

hud.Visible = true

Quest:Refresh()