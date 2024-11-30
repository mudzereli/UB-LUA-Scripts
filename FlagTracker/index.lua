local im = require("imgui")
local ubviews = require("utilitybelt.views")
--local bit = require("bit32")
local imgui = im.ImGui
local version = "1.0.2"
local quests = {}

local augmentations = {
    {"Death Augs","Keep Items",IntId.AugmentationLessDeathItemLoss,3},
    {"Death Augs","Keep Spells",IntId.AugmentationSpellsRemainPastDeath,1},
    {"Skill Augs","+5 All Skills",IntId.AugmentationJackOfAllTrades,1},
    {"Skill Augs","+10 Melee Skills",IntId.AugmentationSkilledMelee,1},
    {"Skill Augs","+10 Magic Skills",IntId.AugmentationSkilledMagic,1},
    {"Skill Augs","+10 Missile Skills",IntId.AugmentationSkilledMissile,1},
    {"Rating Augs","25%% Crit Protection",IntId.AugmentationCriticalDefense,1},
    {"Rating Augs","1%% Critical Chance",IntId.AugmentationCriticalExpertise,1},
    {"Rating Augs","3%% Critical Damage",IntId.AugmentationCriticalPower,1},
    {"Rating Augs","3%% Damage Rating",IntId.AugmentationDamageBonus,1},
    {"Rating Augs","3%% Damage Reduction",IntId.AugmentationDamageReduction,1},
    {"Burden / Pack Augs","Extra Carrying Capacity",IntId.AugmentationIncreasedCarryingCapacity,5},
    {"Burden / Pack Augs","Extra Pack Slot",IntId.AugmentationExtraPackSlot,1},
    {"Burden / Pack Augs","Infused War Magic",IntId.AugmentationInfusedWarMagic,1},
    {"Burden / Pack Augs","Infused Void Magic",IntId.AugmentationInfusedVoidMagic,1},
    {"Burden / Pack Augs","Infused Creature Magic",IntId.AugmentationInfusedCreatureMagic,1},
    {"Burden / Pack Augs","Infused Life Magic",IntId.AugmentationInfusedLifeMagic,1},
    {"Burden / Pack Augs","Infused Item Magic",IntId.AugmentationInfusedItemMagic,1},
    {"Misc Augs","Increased Spell Duration",IntId.AugmentationIncreasedSpellDuration,5},
    {"Misc Augs","Faster HP Regen",IntId.AugmentationFasterRegen,2},
    {"Misc Augs","5%% Experience Increase",IntId.AugmentationBonusXp,1},
    {"Salvage Augs","Specialized Weapon Tinkering",IntId.AugmentationSpecializeWeaponTinkering,1},
    {"Salvage Augs","Specialized Armor Tinkering",IntId.AugmentationSpecializeArmorTinkering,1},
    {"Salvage Augs","Specialized Item Tinkering",IntId.AugmentationSpecializeItemTinkering,1},
    {"Salvage Augs","Specialized Magic Item Tinkering",IntId.AugmentationSpecializeMagicItemTinkering,1},
    {"Salvage Augs","Specialized GearCraft",IntId.AugmentationSpecializeGearcraft,1},
    {"Salvage Augs","Specialized Salvaging",IntId.AugmentationSpecializeSalvaging,1},
    {"Salvage Augs","25%% More Salvage",IntId.AugmentationBonusSalvage,4},
    {"Salvage Augs","5%% Imbue Chance",IntId.AugmentationBonusImbueChance,1},
    {"Stat Augs","All Stats",IntId.AugmentationInnateFamily,10},
    {"Stat Augs","Strength",IntId.AugmentationInnateStrength,10},
    {"Stat Augs","Endurance",IntId.AugmentationInnateEndurance,10},
    {"Stat Augs","Coordination",IntId.AugmentationInnateCoordination,10},
    {"Stat Augs","Quickness",IntId.AugmentationInnateQuickness,10},
    {"Stat Augs","Focus",IntId.AugmentationInnateFocus,10},
    {"Stat Augs","Self",IntId.AugmentationInnateSelf,10},
    {"Resistance Augs","All Resistances",IntId.AugmentationResistanceFamily,2},
    {"Resistance Augs","Blunt",IntId.AugmentationResistanceBlunt,2},
    {"Resistance Augs","Pierce",IntId.AugmentationResistancePierce,2},
    {"Resistance Augs","Slashing",IntId.AugmentationResistanceSlash,2},
    {"Resistance Augs","Fire",IntId.AugmentationResistanceFire,2},
    {"Resistance Augs","Frost",IntId.AugmentationResistanceFrost,2},
    {"Resistance Augs","Acid",IntId.AugmentationResistanceAcid,2},
    {"Resistance Augs","Lightning",IntId.AugmentationResistanceLightning,2}
}
local typeLuminanceAuraNalicana = 0
local typeLuminanceAuraSeer = 1
local luminanceauras = {
    {"+1 Aetheria Proc Rating",IntId.LumAugSurgeChanceRating,5,typeLuminanceAuraNalicana},
    {"+1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5,typeLuminanceAuraNalicana},
    {"+1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5,typeLuminanceAuraNalicana},
    {"+1 Damage Rating",IntId.LumAugDamageRating,5,typeLuminanceAuraNalicana},
    {"+1 Crit Damage Rating",IntId.LumAugCritDamageRating,5,typeLuminanceAuraNalicana},
    {"+1 Heal Rating",IntId.LumAugHealingRating,5,typeLuminanceAuraNalicana},
    {"+1 Equipment Mana Rating",IntId.LumAugItemManaUsage,5,typeLuminanceAuraNalicana},
    {"+1 Mana Stone Rating",IntId.LumAugItemManaGain,5,typeLuminanceAuraNalicana},
    {"+1 Crafting Skills",IntId.LumAugSkilledCraft,5,typeLuminanceAuraNalicana},
    {"+1 All Skills",IntId.LumAugAllSkills,10,typeLuminanceAuraNalicana},
    {"+2 Specialized Skills",IntId.LumAugSkilledSpec,5,typeLuminanceAuraSeer},
    {"+1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5,typeLuminanceAuraSeer},
    {"+1 Damage Rating",IntId.LumAugDamageRating,5,typeLuminanceAuraSeer},
    {"+1 Crit Damage Rating",IntId.LumAugCritDamageRating,5,typeLuminanceAuraSeer},
    {"+1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5,typeLuminanceAuraSeer}
    --{"+1 Aetheria Effect Rating",IntId.LumAugSurgeEffectRating,5},
    --{"+1 Vitality",IntId.LumAugVitality,5},
}
local typeQuest = 0
local typeIntValue = 1
local typeAetheria = 2
local characterflags = {
    {"Additional Skill Credits",typeQuest,"+1 Skill Lum Aura","lumaugskillquest",2,2},
    {"Additional Skill Credits",typeQuest,"+1 Skill Aun Ralirea","arantahkill1",1,2},
    {"Additional Skill Credits",typeQuest,"+1 Skill Chasing Oswald","oswaldmanualcompleted",1,2},
    {"Aetheria",typeAetheria,"Blue Aetheria (75)",IntId.AetheriaBitfield,1},
    {"Aetheria",typeAetheria,"Yellow Aetheria (150)",IntId.AetheriaBitfield,2},
    {"Aetheria",typeAetheria,"Red Aetheria (225)",IntId.AetheriaBitfield,4},
    {"Augmentation Gems",typeQuest,"Sir Bellas","augmentationblankgemacquired",1,3},
    {"Augmentation Gems",typeQuest,"Gladiator Diemos Token","pickedupmarkerboss10x",1,3},
    {"Augmentation Gems",typeQuest,"100K Luminance Gem","blankaugluminancetimer_0511",1,3},
    {"Other Flags",typeQuest,"Recall Aphus Lassel","recalltuskerisland",1,2},
    {"Other Flags",typeQuest,"Candeth Keep Treehouse","strongholdbuildercomplete",1,2},
    {"Other Flags",typeQuest,"Luminance Flag","oracleluminancerewardsaccess_1110",1,2},
    {"Other Flags",typeQuest,"Diemos Access","golemstonediemosgiven",1,2}
    --"OracleLuminanceRewardsAccess_1110"
}
local coloryellow = Vector4.new(1,1,0,1)
local colorred = Vector4.new(1,0,0,1)
local colorgreen = Vector4.new(0,1,0,1)

print("[LUA]: Loading FlagTracker v"..version)

local hud = ubviews.Huds.CreateHud("FlagTracker v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize
local augTreeRenderStatus = {}
local augTreeInitialOpenStatus = {}
augTreeInitialOpenStatus["Stat Augs"] = false
augTreeInitialOpenStatus["Resistance Augs"] = false
local flagTreeRenderStatus = {}
local flagTreeInitialOpenStatus = {}

game.World.OnChatText.Add(function(evt)
    local taskname, solves, timestamp, description, num1, num2 = string.match(evt.Message, "([%w_]+) %- (%d+) solves %((%d+)%)\"([^\"]+)\" (%-?%d+) (%d+)")
    if taskname and solves and timestamp and description and num1 and num2 then
        quests[taskname] = {taskname, solves, timestamp, description, num1, num2}
    end
end)

hud.OnRender.Add(function()
    local char = game.Character.Weenie
    if char == nil then return end
    if imgui.BeginTabBar("Flag Tracker Bar") then
        -- Augmentations Tab
        if imgui.BeginTabItem("Augmentations") then
            local numColumns = 2
            if imgui.BeginTable("Augmentations", numColumns*2) then
                imgui.TableSetupColumn("Aug 1",im.ImGuiTableColumnFlags.WidthStretch,200)
                imgui.TableSetupColumn("Aug 1 Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                imgui.TableSetupColumn("Aug 2",im.ImGuiTableColumnFlags.WidthStretch,200)
                imgui.TableSetupColumn("Aug 2 Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                local lastCategory = nil
                local currentColumnIndex = 0
                for _, v in ipairs(augmentations) do
                    local currentCategory = v[1]
                    if currentCategory ~= lastCategory then
                        if lastCategory ~= nil and augTreeRenderStatus[lastCategory] then
                            imgui.TreePop()
                        end
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.Separator()
                        imgui.SetNextItemOpen(augTreeInitialOpenStatus[currentCategory] == nil or augTreeInitialOpenStatus[currentCategory])
                        augTreeRenderStatus[currentCategory] = imgui.TreeNode(currentCategory)
                        imgui.TableSetColumnIndex(1)
                        imgui.Separator()
                        imgui.TableSetColumnIndex(2)
                        imgui.Separator()
                        imgui.TableSetColumnIndex(3)
                        imgui.Separator()
                        augTreeInitialOpenStatus[currentCategory] = augTreeRenderStatus[currentCategory]
                        lastCategory = currentCategory
                        currentColumnIndex = 0
                    end
                    if augTreeRenderStatus[currentCategory] then
                        local value = char.Value(v[3]) or 0
                        local prefix = v[2]
                        local cap = v[4]
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
                        currentColumnIndex = (currentColumnIndex + 1) % (numColumns*2)
                        imgui.TableSetColumnIndex(currentColumnIndex)
                        imgui.TextColored(color, value .. "/" .. cap)
                        currentColumnIndex = (currentColumnIndex + 1) % (numColumns*2)
                    end
                end
                if lastCategory ~= nil and augTreeRenderStatus[lastCategory] then
                    imgui.TreePop()
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end

        -- Luminance Auras Tab
        if imgui.BeginTabItem("Luminance Auras") then
            if imgui.BeginTable("Luminance Auras", 2) then
                imgui.TableSetupColumn("Lum Aura",im.ImGuiTableColumnFlags.WidthStretch,200)
                imgui.TableSetupColumn("Lum Aura Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                imgui.SeparatorText("Nalicana Auras")
                local lastLuminanceAuraType = typeLuminanceAuraNalicana
                for _, v in ipairs(luminanceauras) do
                    local value = char.Value(v[2]) or 0
                    local prefix = v[1]
                    local cap = v[3]
                    local luminanceAuraType = v[4]
                    local color = coloryellow

                    if luminanceAuraType ~= lastLuminanceAuraType then
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.SeparatorText("Seer Auras")
                    end

                    if value >= cap and luminanceAuraType == typeLuminanceAuraNalicana then
                        value = cap
                    elseif luminanceAuraType == typeLuminanceAuraSeer and v[2] ~= IntId.LumAugSkilledSpec then
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

                    lastLuminanceAuraType = luminanceAuraType
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end

        -- Character Flags Tab
        if imgui.BeginTabItem("Character Flags") then
            if imgui.BeginTable("Character Flags", 2) then
                imgui.TableSetupColumn("Flag 1",im.ImGuiTableColumnFlags.WidthStretch,200)
                imgui.TableSetupColumn("Flag 1 Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                local lastCategory = nil
                for _, v in ipairs(characterflags) do
                    local currentCategory = v[1]
                    if currentCategory ~= lastCategory then
                        if lastCategory ~= nil and flagTreeRenderStatus[lastCategory] then
                            imgui.TreePop()
                        end
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.Separator()
                        imgui.SetNextItemOpen(flagTreeInitialOpenStatus[currentCategory] == nil or flagTreeInitialOpenStatus[currentCategory])
                        flagTreeRenderStatus[currentCategory] = imgui.TreeNode(currentCategory)
                        imgui.TableSetColumnIndex(1)
                        imgui.Separator()
                        flagTreeInitialOpenStatus[currentCategory] = flagTreeRenderStatus[currentCategory]
                    end
                    if flagTreeRenderStatus[currentCategory] then
                        local type = v[2]
                        local prefix
                        local cap
                        local value = 0
                        if type == typeQuest then
                            prefix = v[3]
                            cap = v[5]
                            local queststamp = v[4]
                            local questfield = v[6]
                            local questinfo = quests[queststamp]
                            if questinfo ~= nil then
                                if questfield == 3 then
                                    local expiration = questinfo[questfield] + questinfo[6]
                                    if expiration >= os.time() then
                                        value = 1
                                    end
                                else
                                    value = tonumber(questinfo[questfield])
                                end
                            end
                        elseif type == typeAetheria then
                            prefix = v[3]
                            local bitreq = v[5]
                            local bit = char.Value(v[4]) or 0
                            if bit >= bitreq then
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
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.TextColored(color, prefix)
                        imgui.TableSetColumnIndex(1)
                        imgui.TextColored(color, value .. "/" .. cap)
                    end
                    lastCategory = currentCategory
                end
                if lastCategory ~= nil and flagTreeRenderStatus[lastCategory] then
                    imgui.TreePop()
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end

        -- General Quests Tab
        if imgui.BeginTabItem("Quests") then
            if imgui.BeginTable("Quests", 6) then
                imgui.TableSetupColumn("Quest",im.ImGuiTableColumnFlags.WidthFixed,256)
                imgui.TableSetupColumn("Solves",im.ImGuiTableColumnFlags.WidthFixed,16)
                imgui.TableSetupColumn("TimeStamp",im.ImGuiTableColumnFlags.WidthFixed,128)
                imgui.TableSetupColumn("Description",im.ImGuiTableColumnFlags.WidthFixed,512)
                imgui.TableSetupColumn("Num1",im.ImGuiTableColumnFlags.WidthFixed,16)
                imgui.TableSetupColumn("Num2",im.ImGuiTableColumnFlags.WidthFixed,64)
                for v in pairs(quests) do
                    local quest = quests[v]
                    if quest ~= nil then 
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.TextColored(colorgreen, quest[1])
                        imgui.TableSetColumnIndex(1)
                        imgui.TextColored(colorgreen, quest[2])
                        imgui.TableSetColumnIndex(2)
                        imgui.TextColored(colorgreen, tostring(os.date("%Y-%m-%d %H:%M:%S", quest[3])))
                        imgui.TableSetColumnIndex(3)
                        imgui.TextColored(colorgreen, quest[4])
                        imgui.TableSetColumnIndex(4)
                        imgui.TextColored(colorgreen, quest[5])
                        imgui.TableSetColumnIndex(5)
                        imgui.TextColored(colorgreen, quest[6])
                    end
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
    end
end)

game.Actions.InvokeChat("/myquests")