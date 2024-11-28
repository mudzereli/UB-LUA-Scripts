local im = require("imgui")
local ubviews = require("utilitybelt.views")
--local bit = require("bit32")
local imgui = im.ImGui
local version = "1.0.0"

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
local luminanceauras = {
    {"+1 Skill Credit",IntId.SkillAlterationCount,2},
    {"+1 Aetheria Proc Rating",IntId.LumAugSurgeChanceRating,5},
    {"+1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5},
    {"+1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5},
    {"+1 Damage Rating",IntId.LumAugDamageRating,5},
    {"+1 Crit Damage Rating",IntId.LumAugCritDamageRating,5},
    {"+1 Heal Rating",IntId.LumAugHealingRating,5},
    {"+1 Equipment Mana Consumption Rating",IntId.LumAugItemManaUsage,5},
    {"+1 Mana Stone Rating",IntId.LumAugItemManaGain,5},
    {"+1 Aetheria Effect Rating",IntId.LumAugSurgeEffectRating,5},
    {"+1 Vitality",IntId.LumAugVitality,5},
    {"+1 All Skills",IntId.LumAugAllSkills,10},
}
local coloryellow = Vector4.new(1,1,0,1)
local colorred = Vector4.new(1,0,0,1)
local colorgreen = Vector4.new(0,1,0,1)
local char = nil

print("[LUA]: Loading FlagTracker v"..version)

game.OnStateChanged.Add(function()
    char = game.Character.Weenie
end)

local hud = ubviews.Huds.CreateHud("FlagTracker v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

hud.OnRender.Add(function()
    if imgui.Begin("FlagTracker") then
        if imgui.BeginTabBar("Flag Tracker Bar") then
            if imgui.BeginTabItem("Augmentations") then
                if imgui.BeginTable("Augmentations", 2) then
                    local lastCategory = nil
                    for _, v in ipairs(augmentations) do
                        local currentCategory = v[1]
                        if currentCategory ~= lastCategory then
                            imgui.TableNextRow()
                            imgui.TableSetColumnIndex(0)
                            -- Set the initial open state
                            imgui.SeparatorText(currentCategory)
                            lastCategory = currentCategory
                        end
                        local value = char.Value(v[3]) or 0
                        local prefix = v[2]
                        local cap = v[4]
                        local color = coloryellow
                        if value == cap then
                            color = colorgreen
                        elseif value < cap then
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
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem("Luminance Auras") then
                if imgui.BeginTable("Luminance Auras", 2) then
                    for _, v in ipairs(luminanceauras) do
                        local value = char.Value(v[2]) or 0
                        local prefix = v[1]
                        local cap = v[3]
                        local color = coloryellow

                        if value == cap then
                            color = colorgreen
                        elseif value < cap then
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
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem("Quest Flags") then
                imgui.EndTabItem()
            end
            imgui.EndTabBar()
        end
        imgui.End()
    end
    imgui.ShowDemoWindow()
end)
