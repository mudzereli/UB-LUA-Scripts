local im = require("imgui")
local ubviews = require("utilitybelt.views")
local Quest = require("quests")
local imgui = im.ImGui
local version = "1.7.1"
local currentHUDPosition = nil
local defaultHUDposition = Vector2.new(500,100)
local textures = {}

local colorwhite = Vector4.new(1,1,1,1)
local coloryellow = Vector4.new(1,1,0,1)
local colorred = Vector4.new(1,0,0,1)
local colorgreen = Vector4.new(0,1,0,1)
local colorlightgray = Vector4.new(0.7, 0.7, 0.7, 1)
local iconVectorSize = Vector2.new(16,16)

local settings = {
    showLuminance = true,
    showRecallSpells = true,
    showSociety=true,
    showFacHub=false,
    showQuests=false,
    showFlags=true,
    hideUnacquiredSlayers=false,
    hideMissingCantrips=false
}
local creatureTypeMap = {
    [0] = CreatureType.Invalid,
    [1] = CreatureType.Olthoi,
    [2] = CreatureType.Banderling,
    [3] = CreatureType.Drudge,
    [4] = CreatureType.Mosswart,
    [5] = CreatureType.Lugian,
    [6] = CreatureType.Tumerok,
    [7] = CreatureType.Mite,
    [8] = CreatureType.Tusker,
    [9] = CreatureType.PhyntosWasp,
    [10] = CreatureType.Rat,
    [11] = CreatureType.Auroch,
    [12] = CreatureType.Cow,
    [13] = CreatureType.Golem,
    [14] = CreatureType.Undead,
    [15] = CreatureType.Gromnie,
    [16] = CreatureType.Reedshark,
    [17] = CreatureType.Armoredillo,
    [18] = CreatureType.Fae,
    [19] = CreatureType.Virindi,
    [20] = CreatureType.Wisp,
    [21] = CreatureType.Knathtead,
    [22] = CreatureType.Shadow,
    [23] = CreatureType.Mattekar,
    [24] = CreatureType.Mumiyah,
    [25] = CreatureType.Rabbit,
    [26] = CreatureType.Sclavus,
    [27] = CreatureType.ShallowsShark,
    [28] = CreatureType.Monouga,
    [29] = CreatureType.Zefir,
    [30] = CreatureType.Skeleton,
    [31] = CreatureType.Human,
    [32] = CreatureType.Shreth,
    [33] = CreatureType.Chittick,
    [34] = CreatureType.Moarsman,
    [35] = CreatureType.OlthoiLarvae,
    [36] = CreatureType.Slithis,
    [37] = CreatureType.Deru,
    [38] = CreatureType.FireElemental,
    [39] = CreatureType.Snowman,
    [40] = CreatureType.Unknown,
    [41] = CreatureType.Bunny,
    [42] = CreatureType.LightningElemental,
    [43] = CreatureType.Rockslide,
    [44] = CreatureType.Grievver,
    [45] = CreatureType.Niffis,
    [46] = CreatureType.Ursuin,
    [47] = CreatureType.Crystal,
    [48] = CreatureType.HollowMinion,
    [49] = CreatureType.Scarecrow,
    [50] = CreatureType.Idol,
    [51] = CreatureType.Empyrean,
    [52] = CreatureType.Hopeslayer,
    [53] = CreatureType.Doll,
    [54] = CreatureType.Marionette,
    [55] = CreatureType.Carenzi,
    [56] = CreatureType.Siraluun,
    [57] = CreatureType.AunTumerok,
    [58] = CreatureType.HeaTumerok,
    [59] = CreatureType.Simulacrum,
    [60] = CreatureType.AcidElemental,
    [61] = CreatureType.FrostElemental,
    [62] = CreatureType.Elemental,
    [63] = CreatureType.Statue,
    [64] = CreatureType.Wall,
    [65] = CreatureType.AlteredHuman,
    [66] = CreatureType.Device,
    [67] = CreatureType.Harbinger,
    [68] = CreatureType.DarkSarcophagus,
    [69] = CreatureType.Chicken,
    [70] = CreatureType.GotrokLugian,
    [71] = CreatureType.Margul,
    [72] = CreatureType.BleachedRabbit,
    [73] = CreatureType.NastyRabbit,
    [74] = CreatureType.GrimacingRabbit,
    [75] = CreatureType.Burun,
    [76] = CreatureType.Target,
    [77] = CreatureType.Ghost,
    [78] = CreatureType.Fiun,
    [79] = CreatureType.Eater,
    [80] = CreatureType.Penguin,
    [81] = CreatureType.Ruschk,
    [82] = CreatureType.Thrungus,
    [83] = CreatureType.ViamontianKnight,
    [84] = CreatureType.Remoran,
    [85] = CreatureType.Swarm,
    [86] = CreatureType.Moar,
    [87] = CreatureType.EnchantedArms,
    [88] = CreatureType.Sleech,
    [89] = CreatureType.Mukkir,
    [90] = CreatureType.Merwart,
    [91] = CreatureType.Food,
    [92] = CreatureType.ParadoxOlthoi,
    [93] = CreatureType.Harvest,
    [94] = CreatureType.Energy,
    [95] = CreatureType.Apparition,
    [96] = CreatureType.Aerbax,
    [97] = CreatureType.Touched,
    [98] = CreatureType.BlightedMoarsman,
    [99] = CreatureType.GearKnight,
    [100] = CreatureType.Gurog,
    [101] = CreatureType.Anekshay
}
-- Tree Layout for Augmentation Tab
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
-- State Tracking for Augmentation Tree Nodes
local augTreeOpenStates = {
    ["Stat Augs"] = false,
    ["Resistance Augs"] = false
}
-- Tree Layout for Luminance Auras
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
        {"(Ka'hiri) +2 Specialized Skills",IntId.LumAugSkilledSpec,5,"LoyalToKahiri"},
        {"(Ka'hiri) +1 Damage Rating",IntId.LumAugDamageRating,5,"LoyalToKahiri"},
        {"(Shade of Lady Adja) +2 Specialized Skills",IntId.LumAugSkilledSpec,5,"LoyalToShadeOfLadyAdja"},
        {"(Shade of Lady Adja) +1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5,"LoyalToShadeOfLadyAdja"},
        {"(Liam of Gelid) +1 Damage Rating",IntId.LumAugDamageRating,5,"LoyalToLiamOfGelid"},
        {"(Liam of Gelid) +1 Crit Damage Rating",IntId.LumAugCritDamageRating,5,"LoyalToLiamOfGelid"},
        {"(Lord Tyragar) +1 Crit Reduction Rating",IntId.LumAugCritReductionRating,5,"LoyalToLordTyragar"},
        {"(Lord Tyragar) +1 Damage Reduction Rating",IntId.LumAugDamageReductionRating,5,"LoyalToLordTyragar"},
    }
}
-- Tree Layout for Recall Spells
local recallspells = {
    {"Recall the Sanctuary",2023},
    {"Aerlinthe Recall",2041},
    {"Mount Lethe Recall",2813},
    {"Recall Aphus Lassel",2931},
    {"Ulgrim's Recall",2941},
    {"Recall to the Singularity Caul",2943},
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
-- Tree Layout for Character Flags
local typeQuest = 0
local typeAetheria = 2
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
-- State Tracking for Character Flags
local characterflagTreeOpenStates = {}
-- Tree Layout for Society Quests
local questTypeOther = 0
local questTypeKillTask = 1
local questTypeCollectItem = 2
local questTypeQuestTag = 3
local questTypeMultiQuestTag = 4
local societyquests = {
    ["Initiate"] = {
        {"GK: Parts x10","","GearknightPartsCollectionWait_0513",questTypeCollectItem,"Pile of Gearknight Parts",10},
        {"GK: Phalanx Kill x10","GearknightInvasionPhalanxKilltask_0513","GearknightInvasionPhalanxKillWait_0513",questTypeKillTask},
        {"GK: Mana Siphon","","GearknightInvasionHighSiphonWait_1009",questTypeQuestTag,"GearknightInvasionHighSiphonStart_1009","Unstable Mana Stone"},
        {"GY: Skeleton Jaw x8","TaskGrave1JawCollectStarted","TaskGrave1JawCollectWait",questTypeCollectItem,"Pyre Skeleton Jaw",8},
        {"GY: Wight Sorcerer Kill x12","TaskGrave1WightMageKilltask","TaskGrave1WightMageWait",questTypeKillTask},
        {"GY: Shambling Archivist Kill","TaskGrave1BossKillStarted","TaskGrave1BossKillWait",questTypeKillTask},
        {"DI: Vaeshok Kill","TaskDIRuschkBossKillTask","TaskDIRuschkBossKillTaskWait",questTypeKillTask},
        {"DI: Deliver Remoran Fin","","TaskDIDeliveryWait",questTypeQuestTag,"TaskDIDelivery","Altered Dark Remoran Fin"}
    },
    ["Adept"] = {
        {"DI: Black Coral x10","TaskDIBlackCoralStarted","TaskDIBlackCoralComplete",questTypeCollectItem,"Black Coral",10},
        {"DI: Crystal of Perception","TaskDIScoutStarted","TaskDIScoutComplete",questTypeOther},
        {"DI: Battle Reports x10","TaskDIReportStarted","TaskDIReportWait",questTypeCollectItem,"Falatacot Battle Report",10},
        {"GY: Supplies to Massilor","","TaskGrave2FedExWait",questTypeQuestTag,"TaskGrave2FedExDelivered","Supplies for Massilor"},
        {"GY: Stone Tracing","TaskGrave2WallCarvingStarted","TaskGrave2WallCarvingWait",questTypeCollectItem,"Imprinted Archaeologist's Paper",1}
    },
    ["Knight"] = {
        {"FI: Blessed Moarsman Kill x50","TaskFreebooterMoarsmanKilltask","TaskFreebooterMoarsmanKilltaskWait",questTypeKillTask},
        {"FI: Bandit Mana Boss Kill","TaskFreebooterBanditBossKill","TaskFreebooterBanditBossKillWait",questTypeKillTask},
        {"FI: Glowing Jungle Lily x20","TaskFreebooterJungleLilyStarted","TaskFreebooterJungleLilyComplete",questTypeCollectItem,"Glowing Jungle Lily",20},
        {"FI: Glowing Moar Gland x30","TaskFreebooterMoarGlandStarted","TaskFreebooterMoarGlandComplete",questTypeCollectItem,"Glowing Moar Gland",30},
        {"FI: Killer Phyntos Wasp Kill x50","KillTaskPhyntosKiller1109","KillTaskPhyntosKillerWait1109",questTypeKillTask},
        {"FI: Mana-Infused Jungle Flower x20","TaskFreebooterJungleFlowerStarted","TaskFreebooterJungleFlowerComplete",questTypeCollectItem,"Mana-Infused Jungle Flower",20},
        {"FI: Phyntos Larva Kill x20","KillTaskPhyntosLarvae1109","KillTaskPhyntosLarvaeWait1109",questTypeKillTask},
        {"FI: Phyntos Honey x10","","PhyntosHoneyComplete1109",questTypeCollectItem,"Phyntos Honey",10},
        {"FI: Hive Queen Kill","","KillPhyntosQueenPickup1109",questTypeCollectItem,"Phyntos Queen's Abdomen",1},
        {"FI: Phyntos Hive Splinters x10","","PhyntosHiveComplete1109",questTypeCollectItem,"Hive Splinter",10}
    },
    ["Lord"] = {
        {"MC: Artifact Collection","TaskMoarsmenArtifactsStarted","TaskMoarsmenArtifactsWait",questTypeOther},
        {"MC: Coral Tower Destroyer","TaskCoralTowersStarted","TaskCoralTowersWait",questTypeMultiQuestTag,{"CoralTowerBlackDead","CoralTowerBlueDead","CoralTowerGreenDead","CoralTowerRedDead","CoralTowerWhiteDead"}},
        {"MC: High Priest of T'thuun Kill","KillTaskMoarsmanHighPriestStarted","KillTaskMoarsmanHighPriestWait",questTypeMultiQuestTag,{"HighPriestAcolyteDead","HighPriestFirstDead","HighPriestSecondDead","HighPriestThirdDead"}},
        {"MC: Magshuth Moarsman Kill x20","KilltaskMagshuthMoarsman","KilltaskMagshuthMoarsmanWait",questTypeKillTask},
        {"MC: Shoguth Moarsman Kill x40","KilltaskShoguthMoarsman","KilltaskShoguthMoarsmanWait",questTypeKillTask},
        {"MC: Moguth Moarsman Kill x60","KilltaskMoguthMoarsman","KilltaskMoguthMoarsmanWait",questTypeKillTask},
        {"MC: Moarsman Spawning Pools","TaskSpawnPoolsStarted","TaskSpawnPoolsWait",questTypeMultiQuestTag,{"BroodMotherZeroDead","BroodMotherOneDead","BroodMotherTwoDead","BroodMotherThreeDead"}},
        {"MC: Palm Fort Defended","","PalmFortDefended1209",questTypeOther},
        {"MC: Supply Saboteur","","SuppliesTurnedIn1209",questTypeOther}
    }
}
-- Rank Map for Societies {Min Ribbons,Max Ribbons,Ribbons Per Day}
local societyranks = {
    ["Initiate"] = {1,95,50},
    ["Adept"] = {101,295,100},
    ["Knight"] = {301,595,150},
    ["Lord"] = {601,995,200},
    ["Master"] = {1001,9999,250}
}
-- Tree Layout for Facility Hub Quests
local fachubquests = {
    ["Level 10"] = {
        {"Glenden Wood","fachubglendenwood"},
        {"Folthid Estate","fachubfolthid"},
        {"Mosswart Camp","fachubmosswartcamp"}
    },
    ["Level 15"] = {
        {"Green Mire Grave","fachubgreenmiregrave"},
        {"Colier","fachubcolier"},
        {"Halls of Helm","fachubhallsofhelm"}
    },
    ["Level 20"] = {
        {"Dangerous Cave","fachubdangerouscatacombs"},
        {"Trothyr's Rest","fachubtrothyrsrest"},
        {"Hunter's Leap","fachubhuntersleap"}
    },
    ["Level 25"] = {
        {"Fledgemaster's Camp","fachubfledgemasterscamp"},
        {"Eastham Portals","fachubeastham","fachubeasthamportals_flag"},
        {"Catacombs of the Forgotten","fachubcatacombs"}
    },
    ["Level 30"] = {
        {"Mountain Sewer","fachubmountainsewer"},
        {"Mite Maze","fachubmitemaze"},
        {"Haunted Mansion","fachubhauntedmansion"}
    },
    ["Level 35"] = {
        {"Suntik","fachubsuntik"},
        {"Banderling Camp","fachubbanderlingcamp"},
        {"Skeleton Fort","fachubskeletonfort"}
    },
    ["Level 40"] = {
        {"Bellig Tower","fachubbellig"},
        {"Castle of Baron Nuvillus","fachubcastle"},
        {"Dryreach","fachubdryreach"}
    },
    ["Level 45"] = {
        {"Blackmire","fachubblackmire"}
    }
}
-- Tree Layout for Cantrip Tracker
local cantripmap = {
    ["Specialized Skills"] = {},
    ["Trained Skills"] = {},
    ["Attributes"] = {
        ["Strength"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.StrengthSelf8, iconBackground = 0x060013F9},
        ["Endurance"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.EnduranceSelf8, iconBackground = 0x060013F9},
        ["Coordination"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.CoordinationSelf8, iconBackground = 0x060013F9},
        ["Quickness"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.QuicknessSelf8, iconBackground = 0x060013F9},
        ["Focus"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.FocusSelf8, iconBackground = 0x060013F9},
        ["Willpower"] = { value = "N/A", color = colorwhite, spellIcon = SpellId.WillpowerSelf8, iconBackground = 0x060013F9}
    },
    ["Protection Auras"] = {
        ["Armor"] = { value = "N/A", color = Vector4.new(0.6, 0.6, 0.6, 1), spellIcon = SpellId.ArmorSelf8}, -- Light Gray
        ["Bludgeoning Ward"] = { value = "N/A", color = Vector4.new(0.7, 0.7, 0.7, 1), spellIcon = SpellId.BludgeonProtectionSelf8}, -- Soft Gray
        ["Piercing Ward"] = { value = "N/A", color = Vector4.new(1, 1, 0.5, 1), spellIcon = SpellId.PiercingProtectionSelf8}, -- Pastel Yellow
        ["Slashing Ward"] = { value = "N/A", color = Vector4.new(1, 0.7, 0.4, 1), spellIcon = SpellId.BladeProtectionSelf8}, -- Pastel Orange
        ["Flame Ward"] = { value = "N/A", color = Vector4.new(1, 0.5, 0.5, 1), spellIcon = SpellId.FireProtectionSelf8}, -- Soft Red
        ["Frost Ward"] = { value = "N/A", color = Vector4.new(0.5, 0.7, 1, 1), spellIcon = SpellId.ColdProtectionSelf8}, -- Pastel Blue
        ["Acid Ward"] = { value = "N/A", color = Vector4.new(0.5, 1, 0.5, 1), spellIcon = SpellId.AcidProtectionSelf8}, -- Soft Green
        ["Storm Ward"] = { value = "N/A", color = Vector4.new(0.8, 0.5, 1, 1), spellIcon = SpellId.LightningProtectionSelf8} -- Pastel Purple
    }
}
-- Color Map for Cantrip Levels
local cantriptypes = {
    ["N/A"] = colorlightgray, -- Lighter Gray
    ["Minor"] = Vector4.new(1, 1, 1, 1), -- White (still fine)
    ["Moderate"] = Vector4.new(0.3, 1, 0.3, 1), -- Softer Green
    ["Major"] = Vector4.new(0.3, 0.6, 1, 1), -- Lighter Blue
    ["Epic"] = Vector4.new(0.8, 0.3, 1, 1), -- Brighter Purple
    ["Legendary"] = Vector4.new(1, 0.7, 0.2, 1) -- Softer Orange    
}
-- Skill Replacement for Cantrips That Have Different Names Than Their Skill
local skillcantripreplacements = {
    [SkillId.MagicDefense] = "MagicResistance",
    [SkillId.MeleeDefense] = "Invulnerability"
}
-- Slayer Weapons Checklist
local essentialSlayerWeapons = {
    CreatureType.Anekshay,
    CreatureType.Burun,
    CreatureType.Elemental,
    CreatureType.FireElemental,
    CreatureType.FrostElemental,
    CreatureType.AcidElemental,
    CreatureType.LightningElemental,
    CreatureType.Ghost,
    CreatureType.Human,
    CreatureType.Mukkir,
    CreatureType.Olthoi,
    CreatureType.Shadow,
    CreatureType.Skeleton,
    CreatureType.Tumerok,
    CreatureType.Undead,
    CreatureType.Virindi
}
-- Slayer Weapons Populated From Inventory
local slayerWeapons = {}

-- Lookup For Number > CreatureType
local function GetCreatureType(number)
    return creatureTypeMap[number] or "Unknown"
end

-- Texture Caching
local function GetOrCreateTexture(iconID)
    local preloadedTexture = textures[iconID]
    if not preloadedTexture then
        local texture = ubviews.Huds.GetIconTexture(iconID)
        if texture then
            textures[iconID] = texture
            return texture
        end
    else
        return preloadedTexture
    end
    return ubviews.Huds.GetIconTexture(0x0600109A)
end

-- Refresh and Populate Cantrips
local function RefreshCantrips() 
    for id, sk in pairs(game.Character.Weenie.Skills) do
        local skillName = skillcantripreplacements[id]
        if skillName == nil then
            skillName = tostring(id)
        end
        if sk.Training == SkillTrainingType.Specialized then
            cantripmap["Specialized Skills"][skillName] = {value = "N/A", color = colorwhite, icon = sk.Dat.IconId}
        end
        if sk.Training == SkillTrainingType.Trained then
            cantripmap["Trained Skills"][skillName] = {value = "N/A", color = colorwhite, icon = sk.Dat.IconId}
        end
    end
    for ward, _ in pairs(cantripmap["Protection Auras"]) do
        cantripmap["Protection Auras"][ward].value = "N/A"
    end
    for attr, _ in pairs(cantripmap["Attributes"]) do
        cantripmap["Attributes"][attr].value = "N/A"
    end
    for _, e in ipairs(game.Character.ActiveEnchantments()) do
        --- @type Enchantment
        local ench = e
        --- @type Spell
        local spell = game.Character.SpellBook.Get(ench.SpellId)
        if spell then
            for type, _ in pairs(cantriptypes) do
                for ward, _ in pairs(cantripmap["Protection Auras"]) do
                    local matchstring = type .. " " .. ward
                    if spell.Name == matchstring then
                        cantripmap["Protection Auras"][ward].value = type
                    end
                end
                for skill, _ in pairs(cantripmap["Specialized Skills"]) do
                    local matchstring = type .. skill
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        cantripmap["Specialized Skills"][skill].value = type
                    end
                end
                for skill, _ in pairs(cantripmap["Trained Skills"]) do
                    local matchstring = type .. skill
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        cantripmap["Trained Skills"][skill].value = type
                    end
                end
                for attribute, _ in pairs(cantripmap["Attributes"]) do
                    local matchstring = type .. attribute
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        cantripmap["Attributes"][attribute].value = type
                    end
                end
            end
        end
    end
end

-- Function Which Takes a WorldObject and Populates slayerWeapons If It's a Slayer
---@param wobject WorldObject
local function CategorizeSlayer(wobject)
    local slayerID = wobject.IntValues[IntId.SlayerCreatureType]
    if slayerID then
        local slayerCreatureType = GetCreatureType(slayerID)
        local slayerGroup = slayerWeapons[slayerCreatureType]
        if not slayerGroup then
            slayerGroup = {}
            slayerWeapons[slayerCreatureType] = slayerGroup
        end
        table.insert(slayerGroup,wobject.Id)
    end    
end

-- Refresh and Populate slayerWeapons Using Above Function
local function RefreshSlayers()
    slayerWeapons = {}
    for _, v in ipairs(game.Character.Inventory) do
        if v.ObjectClass == ObjectClass.MeleeWeapon
            or v.ObjectClass == ObjectClass.MissileWeapon
            or v.ObjectClass == ObjectClass.WandStaffOrb then
            if v.HasAppraisalData then
                CategorizeSlayer(v)
            else
                v.Appraise(nil,function (res)
                    CategorizeSlayer(game.World.Get(res.ObjectId))
                end)
            end
        end
    end
end

print("[LUA]: Loading FlagTracker v"..version)

local hud = ubviews.Huds.CreateHud("FlagTracker v"..version,0x06005A8A)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

hud.OnRender.Add(function()
    local char = game.Character.Weenie
    if char == nil then return end
    if imgui.BeginTabBar("Flag Tracker Bar") then

        -- Augmentations Tab
        if imgui.BeginTabItem("Augs") then
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

                            local skip = (category == "Stat Augs" and char.Value(IntId.AugmentationInnateFamily) == 10 and value == 0) 
                                      or (category == "Resistance Augs" and char.Value(IntId.AugmentationResistanceFamily) == 2 and value == 0)
                                      or (augID == IntId.AugmentationSpecializeMagicItemTinkering and char.Skills[SkillId.MagicItemTinkering].Training == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeWeaponTinkering and char.Skills[SkillId.WeaponTinkering].Training == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeArmorTinkering and char.Skills[SkillId.ArmorTinkering].Training == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeItemTinkering and char.Skills[SkillId.ItemTinkering].Training == SkillTrainingType.Untrained)

                            if not skip then
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
                        end

                        imgui.EndTable()
                    end

                    imgui.TreePop()
                end
            end

            imgui.EndTabItem()
        end

        -- Luminance Auras Tab
        if Quest:HasQuestFlag("oracleluminancerewardsaccess_1110") and imgui.BeginTabItem("Lum") then
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
                        local skip = false
    
                        if value >= cap and category == "Nalicana Auras" then
                            value = cap
                        elseif category == "Seer Auras" and auraInfo[2] ~= IntId.LumAugSkilledSpec then
                            value = math.max(0,value-5)
                        end
                        
                        if category == "Seer Auras" then
                            local flag = string.lower(auraInfo[4])
                            skip = not Quest:HasQuestFlag(flag)
                        end

                        if not skip then
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
                    end
                    imgui.EndTable()
                end
            end
            imgui.EndTabItem()
        end
        
        -- Recall Spells Tab
        if imgui.BeginTabItem("Recalls") then
            if imgui.BeginTable("Recall Spells",2) then
                imgui.TableSetupColumn("Recall Spell",im.ImGuiTableColumnFlags.WidthStretch,128)
                imgui.TableSetupColumn("Status",im.ImGuiTableColumnFlags.WidthStretch,32)
                imgui.TableHeadersRow()
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
        
        -- Society Tab
        if char.IntValues[IntId.Faction1Bits] ~= nil
                and char.IntValues[IntId.Faction1Bits] ~= 0 
                and imgui.BeginTabItem("Society") then
            if imgui.Button("Refresh Quests") then
                Quest:Refresh()
            end
            local factionbits = char.IntValues[IntId.Faction1Bits]
            local factionscore = 0
            local nextfactionrankscore = 0
            local society = ""
            local societyrank = ""
            local maxribbonsperday = 0
            -- Determine Which Society
            if factionbits == 1 then
                society = "Celestial Hand"
                factionscore = char.IntValues[IntId.SocietyRankCelhan]
            elseif factionbits == 2 then
                society = "Edlrytch Web"
                factionscore = char.IntValues[IntId.SocietyRankEldweb]
            elseif factionbits == 4 then
                society = "Radiant Blood"
                factionscore = char.IntValues[IntId.SocietyRankRadblo]
            end
            -- Determine Society Rank
            for isocietyrank, thresholds in pairs(societyranks) do
                local lowerT = thresholds[1]
                local upperT = thresholds[2]
                if factionscore >= lowerT and factionscore <= upperT then
                    societyrank = isocietyrank
                    nextfactionrankscore = upperT
                    maxribbonsperday = thresholds[3]
                end
            end
            imgui.SeparatorText(society.." - "..societyrank)
            if imgui.BeginTable("SocietyInfo",2) then
                imgui.TableSetupColumn("Label",im.ImGuiTableColumnFlags.WidthStretch,90)
                imgui.TableSetupColumn("Value",im.ImGuiTableColumnFlags.WidthStretch,32)
                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                imgui.Text("Ribbons for Next Rank")
                imgui.TableSetColumnIndex(1)
                local stringFactionScore
                if nextfactionrankscore == 9999 then
                    stringFactionScore = "Max"
                else 
                    stringFactionScore = tostring(factionscore).."/"..tostring(nextfactionrankscore)
                end
                imgui.TextColored(colorgreen,stringFactionScore)
                local quest = Quest.Dictionary["societyribbonsperdaycounter"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Ribbons per Day (Counter)")
                    imgui.TableSetColumnIndex(1)
                    imgui.TextColored(colorgreen,tostring(quest.solves).."/"..tostring(maxribbonsperday))
                end
                local quest = Quest.Dictionary["societyribbonsperdaytimer"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Ribbons per Day (Timer)")
                    imgui.TableSetColumnIndex(1)
                    local questColor = colorred
                    local questStatus = Quest:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = colorgreen
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                local quest = Quest.Dictionary["societyarmorwritwait"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Society Armor Writ")
                    imgui.TableSetColumnIndex(1)
                    local questColor = colorred
                    local questStatus = Quest:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = colorgreen
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                local quest = Quest.Dictionary["societymasterstipendcollectiontimer"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Society Master Stipend")
                    imgui.TableSetColumnIndex(1)
                    local questColor = colorred
                    local questStatus = Quest:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = colorgreen
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                imgui.EndTable()
            end
            for isocietyrank, questList in pairs(societyquests) do
                local thresholds = societyranks[isocietyrank]
                local lowerT = thresholds[1]
                if factionscore >= lowerT then
                    imgui.Separator()
                    if imgui.TreeNode(isocietyrank.." Quests") then
                        if imgui.BeginTable("SocietyInfo",2) then
                            imgui.TableSetupColumn("Quest1",im.ImGuiTableColumnFlags.WidthStretch,90)
                            imgui.TableSetupColumn("Status1",im.ImGuiTableColumnFlags.WidthStretch,32)
                            for socquest in questList do
                                local socquestName = socquest[1]
                                local socquestStart = string.lower(socquest[2])
                                local socquestEnd = string.lower(socquest[3])
                                local questType = socquest[4]
                                local questColor = coloryellow
                                local questString = "Ready"
                                imgui.TableNextRow()
                                local questStart = Quest.Dictionary[socquestStart]
                                local questEnd = Quest.Dictionary[socquestEnd]
                                if questType == questTypeQuestTag and Quest:IsQuestAvailable(socquestEnd) then
                                    local tag = string.lower(socquest[5])
                                    local completeQuest = Quest.Dictionary[tag]
                                    if completeQuest then
                                        questColor = colorgreen
                                        questString = "Complete"
                                    else
                                        local startItem = socquest[6]
                                        if game.Character.GetInventoryCount(startItem) > 0 then
                                            questString = "Started"
                                        end
                                    end
                                elseif questType == questTypeMultiQuestTag and Quest:IsQuestAvailable(socquestEnd) and Quest:HasQuestFlag(socquestStart) then
                                    local tags = socquest[5]
                                    local completeCount = 0
                                    for _, tag in pairs(tags) do
                                        if Quest:HasQuestFlag(string.lower(tag)) then
                                            completeCount = completeCount + 1
                                        end
                                    end
                                    if completeCount >= #tags then
                                        questColor = colorgreen
                                        questString = "Complete ("..completeCount.."/"..#tags..")"
                                    else
                                        questString = "Started ("..completeCount.."/"..#tags..")"
                                    end
                                elseif questType == questTypeCollectItem and Quest:IsQuestAvailable(socquestEnd) then
                                    local questItem = socquest[5]
                                    local questItemCount = socquest[6]
                                    local collectedCount = game.Character.GetInventoryCount(questItem)
                                    questString = "Started ("..collectedCount..")"
                                    if collectedCount >= questItemCount then
                                        questColor = colorgreen
                                        questString = "Complete ("..collectedCount..")"
                                    end
                                elseif questStart then
                                    if questType == questTypeKillTask then
                                        questString = "Started ("..questStart.solves..")"
                                        if questStart.solves == questStart.maxsolves then
                                            questColor = colorgreen
                                            questString = "Complete ("..questStart.solves..")"
                                        end
                                    elseif questType == questTypeOther then
                                        questString = "Started"
                                    elseif questType == questTypeCollectItem then
                                        local questItem = socquest[5]
                                        local questItemCount = socquest[6]
                                        local collectedCount = game.Character.GetInventoryCount(questItem)
                                        questString = "Started ("..collectedCount..")"
                                        if collectedCount >= questItemCount then
                                            questColor = colorgreen
                                            questString = "Complete ("..collectedCount..")"
                                        end
                                    end
                                elseif questEnd then
                                    questString = Quest:GetTimeUntilExpire(questEnd)
                                    if questString == "Ready" then
                                        questColor = coloryellow
                                    else
                                        questColor = colorred
                                    end
                                end
                                imgui.TableSetColumnIndex(0)
                                imgui.TextColored(questColor,socquestName)
                                imgui.TableSetColumnIndex(1)
                                imgui.TextColored(questColor,questString)
                            end
                            imgui.EndTable()
                        end
                        imgui.TreePop()
                    end
                end
            end
            imgui.EndTabItem()
        end

        -- Fachub Tab
        if settings.showFacHub and imgui.BeginTabItem("FacHub") then
            if imgui.Button("Refresh Quests") then
                Quest:Refresh()
            end
            imgui.TextDisabled("[F] = Flagged / [X] = Completed / [U] = Unknown")
            for minLevel, fhquests in pairs(fachubquests) do
                --imgui.SeparatorText(minLevel.." Quests")
                imgui.Separator()
                if imgui.TreeNode(minLevel.." Quests") then
                    local columnIndex = 0
                    if imgui.BeginTable(minLevel.." Quests",6) then
                        imgui.TableSetupColumn(minLevel.." Quest1",im.ImGuiTableColumnFlags.WidthStretch)
                        imgui.TableSetupColumn(minLevel.." Quest2",im.ImGuiTableColumnFlags.WidthStretch)
                        imgui.TableSetupColumn(minLevel.." Quest3",im.ImGuiTableColumnFlags.WidthStretch)
                        for _, fhquest in pairs(fhquests) do
                            local fhquestName = fhquest[1]
                            local fhquestCompleted = fhquest[2]
                            local fhquestStarted = fhquest[3]
                            if not fhquestStarted then
                                fhquestStarted = fhquestCompleted.."portal_flag"
                            end
                            if columnIndex == 0 then
                                imgui.TableNextRow()
                            end
                            local stringFHCompleted
                            local colorQuest
                            if Quest:HasQuestFlag(fhquestCompleted) then
                                stringFHCompleted = "X"
                                colorQuest = colorgreen
                            elseif Quest:HasQuestFlag(fhquestStarted) then
                                stringFHCompleted = "F"
                                colorQuest = coloryellow
                            else 
                                stringFHCompleted = "U"
                                colorQuest = colorred
                            end
                            imgui.TableSetColumnIndex(columnIndex)
                            imgui.TextColored(colorQuest,"["..stringFHCompleted.."] "..fhquestName)
                            columnIndex = columnIndex + 1
                            if columnIndex >= 3 then
                                columnIndex = 0
                            end
                        end
                        imgui.EndTable()
                    end
                    imgui.TreePop()
                end
            end
            imgui.EndTabItem()
        end

        -- Character Flags Tab
        if imgui.BeginTabItem("Flags") then
            if imgui.Button("Refresh Quests") then
                Quest:Refresh()
            end
            for category, flagInfo in pairs(characterflags) do
                imgui.Separator()
                imgui.SetNextItemOpen(characterflagTreeOpenStates[category] == nil or characterflagTreeOpenStates[category])
                local isTreeNodeOpen = imgui.TreeNode(category)
                characterflagTreeOpenStates[category] = isTreeNodeOpen
                if isTreeNodeOpen then
                    if imgui.BeginTable("Character Flags_"..category, 2) then
                        imgui.TableSetupColumn("Flag 1",im.ImGuiTableColumnFlags.WidthStretch,128)
                        imgui.TableSetupColumn("Flag 1 Points",im.ImGuiTableColumnFlags.WidthStretch,32)
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
                                        completionString = Quest:GetTimeUntilExpire(quest)
                                        if completionString == "Ready" then
                                            color = coloryellow
                                        end
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

        -- Cantrips Tab
        if imgui.BeginTabItem("Cantrips") then
            if imgui.Button("Refresh") then
                RefreshCantrips()
            end
            for cantripgroup, cantrips in pairs(cantripmap) do
                imgui.Separator()
                if imgui.TreeNode(cantripgroup) then
                    if imgui.BeginTable(cantripgroup,2) then
                        imgui.TableSetupColumn(cantripgroup,im.ImGuiTableColumnFlags.WidthStretch,64)
                        imgui.TableSetupColumn("Status",im.ImGuiTableColumnFlags.WidthStretch,32)
                        for effect, info in pairs(cantrips) do
                            if not (info.value == "N/A" and settings.hideMissingCantrips) then
                                local iconID = info.icon
                                local iconBackgroundID = info.iconBackground
                                local spellIcon = info.spellIcon
                                imgui.TableNextRow()
                                imgui.TableSetColumnIndex(0)
                                if iconBackgroundID then
                                    --- @type ManagedTexture
                                    local icon = GetOrCreateTexture(iconBackgroundID)
                                    if icon then
                                        local pos = imgui.GetCursorScreenPos()
                                        imgui.Image(icon.TexturePtr,iconVectorSize)
                                        imgui.SetCursorScreenPos(pos)
                                    end
                                end
                                if iconID then
                                    --- @type ManagedTexture
                                    local icon = GetOrCreateTexture(iconID)
                                    if icon then
                                        imgui.Image(icon.TexturePtr,iconVectorSize)
                                    end
                                    imgui.SameLine()
                                end
                                if spellIcon then
                                    local spell = game.Character.SpellBook.Get(spellIcon.ToNumber())
                                    if spell then
                                        --- @type ManagedTexture
                                        local icon = GetOrCreateTexture(spell.Icon)
                                        if icon then
                                            imgui.Image(icon.TexturePtr,iconVectorSize)
                                        end
                                        imgui.SameLine()
                                    end
                                end
                                imgui.TextColored(info.color, effect)
                                imgui.TableSetColumnIndex(1)
                                imgui.TextColored(cantriptypes[info.value], info.value)
                            end
                        end
                        imgui.EndTable()
                    end
                    imgui.TreePop()
                end
            end
            imgui.EndTabItem()
        end

        -- Slayers Tab
        if imgui.BeginTabItem("Slayers") then
            if imgui.Button("Refresh") then
                RefreshSlayers()
            end
            if imgui.TreeNode("Slayers") then
                if imgui.BeginTable("Slayer Weapons",2) then
                    imgui.TableSetupColumn("Slayer Type",im.ImGuiTableColumnFlags.WidthStretch,16)
                    imgui.TableSetupColumn("Weapon Name",im.ImGuiTableColumnFlags.WidthStretch,32)
                    -- imgui.TableHeadersRow()
                    -- TODO: Do We Need Separate Tracking For Slayers Which Are Non-Essential (Rares/Etc?)
                    for _, category in ipairs(essentialSlayerWeapons) do
                        local slayerGroup = slayerWeapons[category]
                        if slayerGroup then
                            for _, weaponID in ipairs(slayerGroup) do
                                --- @type WorldObject
                                local weapon = game.World.Get(weaponID)
                                if weapon then
                                    imgui.TableNextRow()
                                    imgui.TableSetColumnIndex(0)
                                    imgui.TextColored(colorgreen,tostring(category))
                                    imgui.TableSetColumnIndex(1)
                                    local icon = GetOrCreateTexture(weapon.DataValues[DataId.Icon])
                                    imgui.Image(icon.TexturePtr,iconVectorSize)
                                    if imgui.IsItemClicked() then
                                        game.Actions.ObjectSelect(weapon.Id)
                                    end
                                    imgui.SameLine()
                                    imgui.TextColored(colorgreen,weapon.Name)
                                    if imgui.IsItemClicked() then
                                        game.Actions.ObjectSelect(weapon.Id)
                                    end
                                end
                            end
                        elseif not settings.hideUnacquiredSlayers then
                            imgui.TableNextRow()
                            imgui.TableSetColumnIndex(0)
                            imgui.TextColored(colorlightgray,tostring(category))
                            imgui.TableSetColumnIndex(1)
                            imgui.TextColored(colorlightgray,"No Weapon Found")
                        end
                    end
                    imgui.EndTable()
                end
                imgui.TreePop()
            end
            imgui.EndTabItem()
        end

        -- General Quests Tab
        if settings.showQuests and imgui.BeginTabItem("Quests") then
            if imgui.Button("Refresh Quests") then
                Quest:Refresh()
            end
            -- Quests Table
            if imgui.BeginTable("Quests", 6, im.ImGuiTableFlags.ScrollY + im.ImGuiTableFlags.Sortable) then
                imgui.TableSetupColumn("Quest", im.ImGuiTableColumnFlags.WidthFixed, 256)
                imgui.TableSetupColumn("Solves", im.ImGuiTableColumnFlags.WidthFixed, 64)
                imgui.TableSetupColumn("Completed", im.ImGuiTableColumnFlags.WidthFixed, 128)
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
                    if imgui.IsItemHovered() and quest.description then
                        imgui.SetTooltip(quest.description)
                    end
                    imgui.TableSetColumnIndex(1)
                    imgui.TextColored(color, quest.solves) -- Solves
                    imgui.TableSetColumnIndex(2)
                    imgui.TextColored(color, Quest:FormatTimeStamp(quest.timestamp)) -- Timestamp
                    imgui.TableSetColumnIndex(3)
                    imgui.TextColored(color, quest.maxsolves) -- MaxSolves
                    imgui.TableSetColumnIndex(4)
                    imgui.TextColored(color, quest.delta) -- Delta
                    imgui.TableSetColumnIndex(5)
                    imgui.TextColored(color, Quest:GetTimeUntilExpire(quest)) -- Expired
                end
        
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        
        -- Settings Tab
        if imgui.BeginTabItem("Settings") then
            imgui.SeparatorText("Tab Visibility")
            if imgui.Checkbox("Show Fac Hub",settings.showFacHub) then
                settings.showFacHub = not settings.showFacHub
            end
            if imgui.Checkbox("Show Quests",settings.showQuests) then
                settings.showQuests = not settings.showQuests
            end
            if imgui.Checkbox("Hide Unacquired Slayers",settings.hideUnacquiredSlayers) then
                settings.hideUnacquiredSlayers = not settings.hideUnacquiredSlayers
            end
            if imgui.Checkbox("Hide Missing Cantrips",settings.hideMissingCantrips) then
                settings.hideMissingCantrips = not settings.hideMissingCantrips
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
RefreshCantrips()
RefreshSlayers()