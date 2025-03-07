local im = require("imgui")
local ubviews = require("utilitybelt.views")
local Quests = require("quests")
local imgui = im.ImGui
local version = "1.8.0"
local currentHUDPosition = nil
local defaultHUDposition = Vector2.new(500,100)
local iconVectorSize = Vector2.new(16,16)
local characterTypeSelf = nil
local textures = {}

--[[
    TODO / POTENTIAL WORK LIST
    - Clean Up / Speed Up Code
    - Add Damage Colors To Weapon Types
    - Tracking for Biting Strike / Crushing Blow / Armor Cleaving
    - Better Tooltips
]]--

-- Cached Data for Performance
local CachedData = {
    LuminanceFlagged = false,
    FactionBits = nil,
    SkillTrainingMagicItemTinkering = SkillTrainingType.Untrained,
    SkillTrainingItemTinkering = SkillTrainingType.Untrained,
    SkillTrainingArmorTinkering = SkillTrainingType.Untrained,
    SkillTrainingWeaponTinkering = SkillTrainingType.Untrained,
    AugInnateFamily = 0,
    AugResistanceFamily = 0,
    InventoryCountAsheronsBenediction = 0,
    LastUpdatedTime = os.clock()
}

-- LUA Table for Color Codes
local Colors = {
    Red = Vector4.new(1, 0, 0, 1),
    SoftRed = Vector4.new(1, 0.5, 0.5, 1),
    Orange = Vector4.new(1, 0.7, 0.4, 1),
    SoftOrange = Vector4.new(1, 0.7, 0.2, 1),
    Yellow = Vector4.new(1, 1, 0, 1),
    SoftYellow = Vector4.new(1, 1, 0.5, 1),
    Green = Vector4.new(0, 1, 0, 1),
    SoftGreen = Vector4.new(0.3, 1, 0.3, 1),
    SofterGreen = Vector4.new(0.5, 1, 0.5, 1),
    LightBlue = Vector4.new(0.3, 0.6, 1, 1),
    SoftBlue = Vector4.new(0.5, 0.7, 1, 1),
    SoftPurple = Vector4.new(0.8, 0.5, 1, 1),
    BrightPurple = Vector4.new(0.8, 0.3, 1, 1),

    White = Vector4.new(1, 1, 1, 1),
    LightGray = Vector4.new(0.7, 0.7, 0.7, 1),
    DarkGray = Vector4.new(0.6, 0.6, 0.6, 1)
}

-- Holds Script-Wide Settings
local Settings = {
    showLuminance = true,
    showRecallSpells = true,
    showSociety=true,
    showFacHub=false,
    showQuests=false,
    showFlags=true,
    hideUnacquiredWeapons=false,
    hideMissingCantrips=false,
    hideResistanceCleavingWeapons=true,
    hideNonEssentialCreatureSlayers=true
}

-- Different Character Types (Returned by GetCharacterType)
local CharacterType = {
    Unknown = 0,
    Melee = 1,
    Archer = 2,
    WarMage = 3,
    VoidMage = 4
}

-- Quest Info Type (Used In Character Flags)
local QuestInfoType = {
    SolveCount = 1,
    ReadyCheck = 2,
    StampCheck = 3
}

-- Quest Type (Used For Society Quests)
local QuestType = {
    Other = 0,
    KillTask = 1,
    CollectItem = 2,
    QuestTag = 3,
    MultiQuestTag = 4
}

-- Maps Numeric Value to CreatureType
local MapCreatureType = {
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

-- Skill Replacement for Cantrips That Have Different Names Than Their Skill
local MapSkillCantripReplacements = {
    [SkillId.MagicDefense] = "MagicResistance",
    [SkillId.MeleeDefense] = "Invulnerability"
}

-- Color Map for Cantrip Levels
local MapCantripColors = {
    ["N/A"] = Colors.LightGray,
    ["Minor"] = Colors.White,
    ["Moderate"] = Colors.SoftGreen,
    ["Major"] = Colors.LightBlue,
    ["Epic"] = Colors.BrightPurple,
    ["Legendary"] = Colors.SoftOrange
}

-- Rank Map for Societies
local MapSocietyRibbons = {
    -- 1 = Min Ribbons
    -- 2 = Max Ribbons
    -- 3 = Ribbons Per Day
    ["Initiate"] = {min = 1, max = 95, perday = 50},
    ["Adept"] = {min = 101, max = 295, perday = 100},
    ["Knight"] = {min = 301, max = 595, perday = 150},
    ["Lord"] = {min = 601, max = 995, perday = 200},
    ["Master"] = {min = 1001, max = 9999, perday = 250}
}

-- State Tracking for Tree Nodes
local TreeOpenStates = {
    ["Stat Augs"] = false,
    ["Resistance Augs"] = false
}

-- Tree Layout for Augmentation Tab
local TabAugmentations = {
    -- 1 = Augmentation Name
    -- 2 = Augmentation Int ID
    -- 3 = Augmentation Times Repeatable
    -- 4 = NPC Trainer
    -- 5 = NPC Trainer Location
    ["Death Augs"] = {
        {name = "Keep Items", id = IntId.AugmentationLessDeathItemLoss, repeatable = 3, trainer = "Rohula bint Ludun", location = "Ayan Baqur"},
        {name = "Keep Spells", id = IntId.AugmentationSpellsRemainPastDeath, repeatable = 1, trainer = "Erik Festus", location = "Ayan Baqur"}
    },
    ["Skill Augs"] = {
        {name = "+5 All Skills", id = IntId.AugmentationJackOfAllTrades, repeatable = 1, trainer = "Arianna the Adept", location = "Bandit Castle"},
        {name = "+10 Melee Skills", id = IntId.AugmentationSkilledMelee, repeatable = 1, trainer = "Carlito Gallo", location = "Silyun"},
        {name = "+10 Magic Skills", id = IntId.AugmentationSkilledMagic, repeatable = 1, trainer = "Rahina bint Zalanis", location = "Zaikhal"},
        {name = "+10 Missile Skills", id = IntId.AugmentationSkilledMissile, repeatable = 1, trainer = "Kilaf", location = "Zaikhal"}
    },
    ["Rating Augs"] = {
        {name = "25%% Crit Protection", id = IntId.AugmentationCriticalDefense, repeatable = 1, trainer = "Piersanti Linante", location = "Sanamar"},
        {name = "1%% Critical Chance", id = IntId.AugmentationCriticalExpertise, repeatable = 1, trainer = "Anfram Mellow", location = "Ayan Baqur"},
        {name = "3%% Critical Damage", id = IntId.AugmentationCriticalPower, repeatable = 1, trainer = "Alishia bint Aldan", location = "Ayan Baqur"},
        {name = "3%% Damage Rating", id = IntId.AugmentationDamageBonus, repeatable = 1, trainer = "Neela Nashua", location = "Bandit Castle"},
        {name = "3%% Damage Reduction", id = IntId.AugmentationDamageReduction, repeatable = 1, trainer = "Emily Yarow", location = "Cragstone"}
    },
    ["Burden / Pack Augs"] = {
        {name = "Extra Carrying Capacity", id = IntId.AugmentationIncreasedCarryingCapacity, repeatable = 5, trainer = "Husoon", location = "Zaikhal"},
        {name = "Extra Pack Slot", id = IntId.AugmentationExtraPackSlot, repeatable = 1, trainer = "Dumida bint Ruminre", location = "Zaikhal"},
        {name = "Infused War Magic", id = IntId.AugmentationInfusedWarMagic, repeatable = 1, trainer = "Raphel Detante", location = "Silyun"},
        {name = "Infused Void Magic", id = IntId.AugmentationInfusedVoidMagic, repeatable = 1, trainer = "Morathe", location = "Candeth Keep"},
        {name = "Infused Creature Magic", id = IntId.AugmentationInfusedCreatureMagic, repeatable = 1, trainer = "Gustuv Lansdown", location = "Cragstone"},
        {name = "Infused Life Magic", id = IntId.AugmentationInfusedLifeMagic, repeatable = 1, trainer = "Akemi Fei", location = "Hebian-To"},
        {name = "Infused Item Magic", id = IntId.AugmentationInfusedItemMagic, repeatable = 1, trainer = "Gan Fo", location = "Hebian-To"}
    },
    ["Misc Augs"] = {
        {name = "10%% Health Increase", id = nil, repeatable = 1, trainer = "Donatello Linante", location = "Silyun"},
        {name = "Increased Spell Duration", id = IntId.AugmentationIncreasedSpellDuration, repeatable = 5, trainer = "Nawamara Ujio", location = "Mayoi"},
        {name = "Faster HP Regen", id = IntId.AugmentationFasterRegen, repeatable = 2, trainer = "Alison Dulane", location = "Bandit Castle"},
        {name = "5%% Experience Increase", id = IntId.AugmentationBonusXp, repeatable = 1, trainer = "Rickard Dumalia", location = "Silyun"}
    },
    ["Salvage Augs"] = {
        {name = "Specialized Weapon Tinkering", id = IntId.AugmentationSpecializeWeaponTinkering, repeatable = 1, trainer = "Lenor Turk", location = "Cragstone"},
        {name = "Specialized Armor Tinkering", id = IntId.AugmentationSpecializeArmorTinkering, repeatable = 1, trainer = "Joshun Felden", location = "Cragstone"},
        {name = "Specialized Item Tinkering", id = IntId.AugmentationSpecializeItemTinkering, repeatable = 1, trainer = "Brienne Carlus", location = "Cragstone"},
        --{"Specialized GearCraft",IntId.AugmentationSpecializeGearcraft,1,"Alex Brummel","Cragstone"},
        {name = "Specialized Magic Item Tinkering", id = IntId.AugmentationSpecializeMagicItemTinkering, repeatable = 1, trainer = "Burrell Sammrun", location = "Cragstone"},
        {name = "Specialized Salvaging", id = IntId.AugmentationSpecializeSalvaging, repeatable = 1, trainer = "Robert Crow", location = "Cragstone"},
        {name = "25%% More Salvage", id = IntId.AugmentationBonusSalvage, repeatable = 4, trainer = "Kris Cennis", location = "Cragstone"},
        {name = "5%% Imbue Chance", id = IntId.AugmentationBonusImbueChance, repeatable = 1, trainer = "Lug", location = "Oolutanga's Refuge"}
    },
    ["Stat Augs"] = {
        {name = "All Stats", id = IntId.AugmentationInnateFamily, repeatable = 10},
        {name = "Strength", id = IntId.AugmentationInnateStrength, repeatable = 10, trainer = "Fiun Luunere", location = "Fiun Outpost"},
        {name = "Endurance", id = IntId.AugmentationInnateEndurance, repeatable = 10, trainer = "Fiun Ruun", location = "Fiun Outpost"},
        {name = "Coordination", id = IntId.AugmentationInnateCoordination, repeatable = 10, trainer = "Fiun Bayaas", location = "Fiun Outpost"},
        {name = "Quickness", id = IntId.AugmentationInnateQuickness, repeatable = 10, trainer = "Fiun Riish", location = "Fiun Outpost"},
        {name = "Focus", id = IntId.AugmentationInnateFocus, repeatable = 10, trainer = "Fiun Vasherr", location = "Fiun Outpost"},
        {name = "Self", id = IntId.AugmentationInnateSelf, repeatable = 10, trainer = "Fiun Noress", location = "Fiun Outpost"}
    },
    ["Resistance Augs"] = {
        {name = "All Resistances", id = IntId.AugmentationResistanceFamily, repeatable = 2},
        {name = "Blunt", id = IntId.AugmentationResistanceBlunt, repeatable = 2, trainer = "Nawamara Dia", location = "Hebian-To"},
        {name = "Pierce", id = IntId.AugmentationResistancePierce, repeatable = 2, trainer = "Kyujo Rujen", location = "Hebian-To"},
        {name = "Slashing", id = IntId.AugmentationResistanceSlash, repeatable = 2, trainer = "Ilin Wis", location = "Hebian-To"},
        {name = "Fire", id = IntId.AugmentationResistanceFire, repeatable = 2, trainer = "Rikshen Ri", location = "Hebian-To"},
        {name = "Frost", id = IntId.AugmentationResistanceFrost, repeatable = 2, trainer = "Lu Bao", location = "Hebian-To"},
        {name = "Acid", id = IntId.AugmentationResistanceAcid, repeatable = 2, trainer = "Shujio Milao", location = "Hebian-To"},
        {name = "Lightning", id = IntId.AugmentationResistanceLightning, repeatable = 2, trainer = "Enli Yuo", location = "Hebian-To"}
    }
}

-- Tree Layout for Luminance Auras
local TabLuminanceAuras = {
    -- 1 = Luminance Aura Name
    -- 2 = Luminance Aura IntID
    -- 3 = Luminance Aura Cap
    -- 4 (Seer Auras Only) = Luminance Aura QuestFlag
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
local TabRecallSpells = {
    -- 1 = Spell Name
    -- 2 = Spell ID
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
local TabCharacterFlags = {
    -- 1 = Flag Name
    -- 2 = Quest Flag
    -- 3 = Quest Info Type
    ["Additional Skill Credits"] = {
        {"+1 Skill Lum Aura","lumaugskillquest",QuestInfoType.SolveCount},
        {"+1 Skill Aun Ralirea","arantahkill1",QuestInfoType.SolveCount},
        {"+1 Skill Chasing Oswald","oswaldmanualcompleted",QuestInfoType.SolveCount},
    },
    ["Aetheria"] = {
        {"Blue Aetheria (75)","efulcentermanafieldused",QuestInfoType.StampCheck},
        {"Yellow Aetheria (150)","efmlcentermanafieldused",QuestInfoType.StampCheck},
        {"Red Aetheria (225)","efllcentermanafieldused",QuestInfoType.StampCheck},
    },
    ["Augmentation Gems"] = {
        {"Sir Bellas","augmentationblankgemacquired",QuestInfoType.ReadyCheck},
        {"Gladiator Diemos Token","pickedupmarkerboss10x",QuestInfoType.ReadyCheck},
        {"100K Luminance Gem","blankaugluminancetimer_0511",QuestInfoType.ReadyCheck},
    },
    ["Other Flags"] = {
        {"Candeth Keep Treehouse","strongholdbuildercomplete",QuestInfoType.StampCheck},
        {"Bur Flag (Portal)","burflagged(permanent)",QuestInfoType.StampCheck},
        {"Singularity Caul","virindiisland",QuestInfoType.StampCheck},
        {"Vissidal Island","vissflagcomplete",QuestInfoType.StampCheck},
        {"Dark Isle","darkisleflagged",QuestInfoType.StampCheck},
        {"Luminance Flag","oracleluminancerewardsaccess_1110",QuestInfoType.StampCheck},
        {"Diemos Access","golemstonediemosgiven",QuestInfoType.StampCheck}
    }
}

-- Tree Layout for Society Quests
local TabSocietyQuests = {
    -- 1 = Quest Name
    -- 2 = Quest Start Tag
    -- 3 = Quest End Tag
    -- 4 = Quest Type
    -- Other Fields (Dependent on QuestType)
    -- QuestType.CollectItem
    -- 5 = Item To Collect
    -- 6 = # Items to Collect
    -- QuestType.QuestTag
    -- 5 = "Ready For Turn In" Quest Tag
    -- 6 = "Quest Started" Item
    -- QuestType.MultiQuestTag
    -- 5 = Additional Quest Tags To Complete (x/cap)
    ["Initiate"] = {
        {"GK: Parts x10","","GearknightPartsCollectionWait_0513",QuestType.CollectItem,"Pile of Gearknight Parts",10},
        {"GK: Phalanx Kill x10","GearknightInvasionPhalanxKilltask_0513","GearknightInvasionPhalanxKillWait_0513",QuestType.KillTask},
        {"GK: Mana Siphon","","GearknightInvasionHighSiphonWait_1009",QuestType.QuestTag,"GearknightInvasionHighSiphonStart_1009","Unstable Mana Stone"},
        {"GY: Skeleton Jaw x8","TaskGrave1JawCollectStarted","TaskGrave1JawCollectWait",QuestType.CollectItem,"Pyre Skeleton Jaw",8},
        {"GY: Wight Sorcerer Kill x12","TaskGrave1WightMageKilltask","TaskGrave1WightMageWait",QuestType.KillTask},
        {"GY: Shambling Archivist Kill","TaskGrave1BossKillStarted","TaskGrave1BossKillWait",QuestType.KillTask},
        {"DI: Vaeshok Kill","TaskDIRuschkBossKillTask","TaskDIRuschkBossKillTaskWait",QuestType.KillTask},
        {"DI: Deliver Remoran Fin","","TaskDIDeliveryWait",QuestType.QuestTag,"TaskDIDelivery","Altered Dark Remoran Fin"}
    },
    ["Adept"] = {
        {"DI: Black Coral x10","TaskDIBlackCoralStarted","TaskDIBlackCoralComplete",QuestType.CollectItem,"Black Coral",10},
        {"DI: Crystal of Perception","TaskDIScoutStarted","TaskDIScoutComplete",QuestType.Other},
        {"DI: Battle Reports x10","TaskDIReportStarted","TaskDIReportWait",QuestType.CollectItem,"Falatacot Battle Report",10},
        {"GY: Supplies to Massilor","","TaskGrave2FedExWait",QuestType.QuestTag,"TaskGrave2FedExDelivered","Supplies for Massilor"},
        {"GY: Stone Tracing","TaskGrave2WallCarvingStarted","TaskGrave2WallCarvingWait",QuestType.CollectItem,"Imprinted Archaeologist's Paper",1}
    },
    ["Knight"] = {
        {"FI: Blessed Moarsman Kill x50","TaskFreebooterMoarsmanKilltask","TaskFreebooterMoarsmanKilltaskWait",QuestType.KillTask},
        {"FI: Bandit Mana Boss Kill","TaskFreebooterBanditBossKill","TaskFreebooterBanditBossKillWait",QuestType.KillTask},
        {"FI: Glowing Jungle Lily x20","TaskFreebooterJungleLilyStarted","TaskFreebooterJungleLilyComplete",QuestType.CollectItem,"Glowing Jungle Lily",20},
        {"FI: Glowing Moar Gland x30","TaskFreebooterMoarGlandStarted","TaskFreebooterMoarGlandComplete",QuestType.CollectItem,"Glowing Moar Gland",30},
        {"FI: Killer Phyntos Wasp Kill x50","KillTaskPhyntosKiller1109","KillTaskPhyntosKillerWait1109",QuestType.KillTask},
        {"FI: Mana-Infused Jungle Flower x20","TaskFreebooterJungleFlowerStarted","TaskFreebooterJungleFlowerComplete",QuestType.CollectItem,"Mana-Infused Jungle Flower",20},
        {"FI: Phyntos Larva Kill x20","KillTaskPhyntosLarvae1109","KillTaskPhyntosLarvaeWait1109",QuestType.KillTask},
        {"FI: Phyntos Honey x10","","PhyntosHoneyComplete1109",QuestType.CollectItem,"Phyntos Honey",10},
        {"FI: Hive Queen Kill","","KillPhyntosQueenPickup1109",QuestType.CollectItem,"Phyntos Queen's Abdomen",1},
        {"FI: Phyntos Hive Splinters x10","","PhyntosHiveComplete1109",QuestType.CollectItem,"Hive Splinter",10}
    },
    ["Lord"] = {
        {"MC: Artifact Collection","TaskMoarsmenArtifactsStarted","TaskMoarsmenArtifactsWait",QuestType.Other},
        {"MC: Coral Tower Destroyer","TaskCoralTowersStarted","TaskCoralTowersWait",QuestType.MultiQuestTag,{"CoralTowerBlackDead","CoralTowerBlueDead","CoralTowerGreenDead","CoralTowerRedDead","CoralTowerWhiteDead"}},
        {"MC: High Priest of T'thuun Kill","KillTaskMoarsmanHighPriestStarted","KillTaskMoarsmanHighPriestWait",QuestType.MultiQuestTag,{"HighPriestAcolyteDead","HighPriestFirstDead","HighPriestSecondDead","HighPriestThirdDead"}},
        {"MC: Magshuth Moarsman Kill x20","KilltaskMagshuthMoarsman","KilltaskMagshuthMoarsmanWait",QuestType.KillTask},
        {"MC: Shoguth Moarsman Kill x40","KilltaskShoguthMoarsman","KilltaskShoguthMoarsmanWait",QuestType.KillTask},
        {"MC: Moguth Moarsman Kill x60","KilltaskMoguthMoarsman","KilltaskMoguthMoarsmanWait",QuestType.KillTask},
        {"MC: Moarsman Spawning Pools","TaskSpawnPoolsStarted","TaskSpawnPoolsWait",QuestType.MultiQuestTag,{"BroodMotherZeroDead","BroodMotherOneDead","BroodMotherTwoDead","BroodMotherThreeDead"}},
        {"MC: Palm Fort Defended","","PalmFortDefended1209",QuestType.Other},
        {"MC: Supply Saboteur","","SuppliesTurnedIn1209",QuestType.Other}
    }
}

-- Tree Layout for Facility Hub Quests
local TabFacilityHubQuests = {
    -- 1 = Fac Hub Quest Name
    -- 2 = Completion Quest Tag
    -- 3 = Starting Quest Tag (if different than normal syntax)
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
local TabCantrips = {
    ["Specialized Skills"] = {},
    ["Trained Skills"] = {},
    ["Attributes"] = {
        ["Strength"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.StrengthSelf8, iconBackground = 0x060013F9},
        ["Endurance"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.EnduranceSelf8, iconBackground = 0x060013F9},
        ["Coordination"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.CoordinationSelf8, iconBackground = 0x060013F9},
        ["Quickness"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.QuicknessSelf8, iconBackground = 0x060013F9},
        ["Focus"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.FocusSelf8, iconBackground = 0x060013F9},
        ["Willpower"] = { value = "N/A", color = Colors.White, spellIcon = SpellId.WillpowerSelf8, iconBackground = 0x060013F9}
    },
    ["Protection Auras"] = {
        ["Armor"] = { value = "N/A", color = Colors.DarkGray, spellIcon = SpellId.ArmorSelf8}, -- Light Gray
        ["Bludgeoning Ward"] = { value = "N/A", color = Colors.LightGray, spellIcon = SpellId.BludgeonProtectionSelf8}, -- Soft Gray
        ["Piercing Ward"] = { value = "N/A", color = Colors.SoftYellow, spellIcon = SpellId.PiercingProtectionSelf8}, -- Pastel Yellow
        ["Slashing Ward"] = { value = "N/A", color = Colors.Orange, spellIcon = SpellId.BladeProtectionSelf8}, -- Pastel Orange
        ["Flame Ward"] = { value = "N/A", color = Colors.SoftRed, spellIcon = SpellId.FireProtectionSelf8}, -- Soft Red
        ["Frost Ward"] = { value = "N/A", color = Colors.SoftBlue, spellIcon = SpellId.ColdProtectionSelf8}, -- Pastel Blue
        ["Acid Ward"] = { value = "N/A", color = Colors.SofterGreen, spellIcon = SpellId.AcidProtectionSelf8}, -- Soft Green
        ["Storm Ward"] = { value = "N/A", color = Colors.SoftPurple, spellIcon = SpellId.LightningProtectionSelf8} -- Pastel Purple
    }
}

-- Tree Layout for Weapons Tab
local TabWeapons = {
    ["Creature Slayer"] = {
        ["Tumerok"] = {IntId.SlayerCreatureType, CreatureType.Tumerok, true, {}},
        ["Olthoi"] = {IntId.SlayerCreatureType, CreatureType.Olthoi, true, {}},
        ["Ghost"] = {IntId.SlayerCreatureType, CreatureType.Ghost, true, {}},
        ["Human"] = {IntId.SlayerCreatureType, CreatureType.Human, true, {}},
        ["Elemental"] = {IntId.SlayerCreatureType, CreatureType.Elemental, false, {}},
        ["FireElemental"] = {IntId.SlayerCreatureType, CreatureType.FireElemental, false, {}},
        ["FrostElemental"] = {IntId.SlayerCreatureType, CreatureType.FrostElemental, false, {}},
        ["AcidElemental"] = {IntId.SlayerCreatureType, CreatureType.AcidElemental, false, {}},
        ["LightningElemental"] = {IntId.SlayerCreatureType, CreatureType.LightningElemental, false, {}},
        ["Shadow"] = {IntId.SlayerCreatureType, CreatureType.Shadow, true, {}},
        ["Virindi"] = {IntId.SlayerCreatureType, CreatureType.Virindi, true, {}},
        ["Anekshay"] = {IntId.SlayerCreatureType, CreatureType.Anekshay, true, {}},
        ["Burun"] = {IntId.SlayerCreatureType, CreatureType.Burun, false, {}},
        ["Mukkir"] = {IntId.SlayerCreatureType, CreatureType.Mukkir, true, {}},
        ["Skeleton"] = {IntId.SlayerCreatureType, CreatureType.Skeleton, true, {}},
        ["Undead"] = {IntId.SlayerCreatureType, CreatureType.Undead, true, {}},
    },
    ["Rending / Resistance Cleaving"] = {
        ["Critical Strike"] = {IntId.ImbuedEffect, 1, true,{}},
        ["Crippling Blow"] = {IntId.ImbuedEffect, 2, true,{}},
        ["Armor Rending"] = {IntId.ImbuedEffect, 4, true,{},{CharacterType.WarMage,CharacterType.VoidMage}},
        ["Slash Rending"] = {IntId.ImbuedEffect, 8, true,{},{CharacterType.VoidMage}},
        ["Pierce Rending"] = {IntId.ImbuedEffect, 16, true,{},{CharacterType.VoidMage}},
        ["Bludgeon Rending"] = {IntId.ImbuedEffect, 32, true,{},{CharacterType.VoidMage}},
        ["Cold Rending"] = {IntId.ImbuedEffect, 128, true,{},{CharacterType.VoidMage}},
        ["Fire Rending"] = {IntId.ImbuedEffect, 512, true,{},{CharacterType.VoidMage}},
        ["Acid Rending"] = {IntId.ImbuedEffect, 64, true,{},{CharacterType.VoidMage}},
        ["Electric Rending"] = {IntId.ImbuedEffect, 256, true,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Slash "] = {IntId.ResistanceModifierType, 1, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Pierce"] = {IntId.ResistanceModifierType, 2, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Bludgeon"] = {IntId.ResistanceModifierType, 4, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Cold"] = {IntId.ResistanceModifierType, 8, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Fire"] = {IntId.ResistanceModifierType, 16, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Acid"] = {IntId.ResistanceModifierType, 32, false,{},{CharacterType.VoidMage}},
        ["Resistance Cleaving: Electric"] = {IntId.ResistanceModifierType, 64, false,{},{CharacterType.VoidMage}}
    }
}

-- Returns the Type of Character of the Player
local function GetCharacterType()
    --- @type Character
    local char = game.Character
    if char == nil then return CharacterType.Unknown end
    local weenie = char.Weenie
    if weenie == nil then return CharacterType.Unknown end
    if weenie.Skills[SkillId.VoidMagic].Training == SkillTrainingType.Specialized then return CharacterType.VoidMage end
    if weenie.Skills[SkillId.WarMagic].Training == SkillTrainingType.Specialized then return CharacterType.WarMage end
    if weenie.Skills[SkillId.WarMagic].Training == SkillTrainingType.Trained then return CharacterType.WarMage end
    if weenie.Skills[SkillId.MissleWeapons].Training == SkillTrainingType.Specialized then return CharacterType.Archer end
    if weenie.Skills[SkillId.HeavyWeapons].Training == SkillTrainingType.Specialized 
        or weenie.Skills[SkillId.LightWeapons].Training == SkillTrainingType.Specialized 
        or weenie.Skills[SkillId.FinesseWeapons].Training == SkillTrainingType.Specialized
        or weenie.Skills[SkillId.TwoHandedCombat].Training == SkillTrainingType.Specialized then return CharacterType.Melee end
    return CharacterType.Unknown
end

-- Texture Caching
local function GetOrCreateTexture(iconID)
    if iconID == nil then
        iconID = 0x06005CE6
    end
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
end

-- Refresh and Populate Cantrips
local function RefreshCantrips() 
    characterTypeSelf = GetCharacterType()
    for id, sk in pairs(game.Character.Weenie.Skills) do
        local skillName = MapSkillCantripReplacements[id]
        if skillName == nil then
            skillName = tostring(id)
        end
        if sk.Training == SkillTrainingType.Specialized then
            TabCantrips["Specialized Skills"][skillName] = {value = "N/A", color = Colors.White, icon = sk.Dat.IconId}
        elseif sk.Training == SkillTrainingType.Trained then
            TabCantrips["Trained Skills"][skillName] = {value = "N/A", color = Colors.White, icon = sk.Dat.IconId}
        end
    end
    for ward, _ in pairs(TabCantrips["Protection Auras"]) do
        TabCantrips["Protection Auras"][ward].value = "N/A"
    end
    for attr, _ in pairs(TabCantrips["Attributes"]) do
        TabCantrips["Attributes"][attr].value = "N/A"
    end
    for _, e in ipairs(game.Character.ActiveEnchantments()) do
        --- @type Enchantment
        local ench = e
        --- @type Spell
        local spell = game.Character.SpellBook.Get(ench.SpellId)
        if spell then
            for type, _ in pairs(MapCantripColors) do
                for ward, _ in pairs(TabCantrips["Protection Auras"]) do
                    local matchstring = type .. " " .. ward
                    if spell.Name == matchstring then
                        TabCantrips["Protection Auras"][ward].value = type
                    end
                end
                for skill, _ in pairs(TabCantrips["Specialized Skills"]) do
                    local matchstring = type .. skill
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        TabCantrips["Specialized Skills"][skill].value = type
                    end
                end
                for skill, _ in pairs(TabCantrips["Trained Skills"]) do
                    local matchstring = type .. skill
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        TabCantrips["Trained Skills"][skill].value = type
                    end
                end
                for attribute, _ in pairs(TabCantrips["Attributes"]) do
                    local matchstring = type .. attribute
                    if string.find(spell.Name:gsub("%s+",""),matchstring) then
                        TabCantrips["Attributes"][attribute].value = type
                    end
                end
            end
        end
    end
end

-- Function Which Takes a WorldObject and Populates Weapons If It's a Tracked Weapon
---@param wobject WorldObject
local function CategorizeWeapon(wobject)
    for _, types in pairs(TabWeapons) do
        for _, values in pairs(types) do
            local weaponIntIDCheck = values[1]
            local weaponIntIDExpectedResult = values[2]
            if weaponIntIDCheck == IntId.CreatureType then
                weaponIntIDExpectedResult = MapCreatureType[weaponIntIDExpectedResult]
            end
            local weaponIntIDResult = wobject.IntValues[weaponIntIDCheck]
            if weaponIntIDResult == weaponIntIDExpectedResult then
                table.insert(values[4],wobject.Id)
            end 
        end
    end
end

-- Takes an Inventory and Categorizes Weapons From It, Calling Appraisals if Needed
local function RefreshWeaponsFromInventory(inventory)
    for _, v in ipairs(inventory) do
        if v.ObjectClass == ObjectClass.MeleeWeapon
            or v.ObjectClass == ObjectClass.MissileWeapon
            or v.ObjectClass == ObjectClass.WandStaffOrb then
            if v.HasAppraisalData then
                CategorizeWeapon(v)
            else
                v.Appraise(nil,function (res)
                    CategorizeWeapon(game.World.Get(res.ObjectId))
                end)
            end
        end
    end
end

-- Refresh and Populate Weapons Using Above Function
local function RefreshWeapons()
    characterTypeSelf = GetCharacterType()
    for _, types in pairs(TabWeapons) do
        for _, values in pairs(types) do
            -- Reset Table That Holds Player Weapons
            values[4] = {}
        end
    end
    RefreshWeaponsFromInventory(game.Character.Equipment)
    RefreshWeaponsFromInventory(game.Character.Inventory)
end

-- Update Cached Data
local function UpdateCachedData()
    CachedData.LuminanceFlagged = Quests:HasQuestFlag("oracleluminancerewardsaccess_1110")
    CachedData.FactionBits = game.Character.Weenie.IntValues[IntId.Faction1Bits]
    CachedData.SkillTrainingMagicItemTinkering = game.Character.Weenie.Skills[SkillId.MagicItemTinkering].Training
    CachedData.SkillTrainingItemTinkering = game.Character.Weenie.Skills[SkillId.ItemTinkering].Training
    CachedData.SkillTrainingWeaponTinkering = game.Character.Weenie.Skills[SkillId.WeaponTinkering].Training
    CachedData.SkillTrainingArmorTinkering = game.Character.Weenie.Skills[SkillId.ArmorTinkering].Training
    CachedData.InventoryCountAsheronsBenediction = game.Character.GetInventoryCount("Asheron's Lesser Benediction")
    CachedData.AugInnateFamily = game.Character.Weenie.Value(IntId.AugmentationInnateFamily)
    CachedData.AugResistanceFamily = game.Character.Weenie.Value(IntId.AugmentationResistanceFamily)
    CachedData.LastUpdatedTime = os.clock()
end

print("[LUA]: Loading FlagTracker v"..version)

local hud = ubviews.Huds.CreateHud("FlagTracker v"..version,0x06005A8A)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

hud.OnRender.Add(function()
    local char = game.Character.Weenie
    if char == nil then return end
    if os.clock() - CachedData.LastUpdatedTime >= 3 then
        UpdateCachedData()
    end
    if imgui.BeginTabBar("Flag Tracker Bar") then

        -- Augmentations Tab
        if imgui.BeginTabItem("Augs") then
            for category, augList in pairs(TabAugmentations) do
                imgui.Separator()
                imgui.SetNextItemOpen(TreeOpenStates[category] == nil or TreeOpenStates[category])
                TreeOpenStates[category] = imgui.TreeNode(category)
                if TreeOpenStates[category] then
                    -- Create a new table for this category
                    local numColumns = 2
                    if imgui.BeginTable("Augmentations_" .. category, numColumns * 2) then
                        imgui.TableSetupColumn("Aug 1", im.ImGuiTableColumnFlags.WidthStretch, 200)
                        imgui.TableSetupColumn("Aug 1 Points", im.ImGuiTableColumnFlags.WidthStretch, 35)
                        imgui.TableSetupColumn("Aug 2", im.ImGuiTableColumnFlags.WidthStretch, 200)
                        imgui.TableSetupColumn("Aug 2 Points", im.ImGuiTableColumnFlags.WidthStretch, 35)

                        local currentColumnIndex = 0
                        
                        for _, augInfo in ipairs(augList) do
                            local prefix = augInfo.name
                            local augID = augInfo.id
                            local cap = augInfo.repeatable
                            local npc = augInfo.trainer
                            local town = augInfo.location
                            local value = 0
                            if augID == nil then
                                value = CachedData.InventoryCountAsheronsBenediction
                            else
                                value = char.Value(augID)
                            end

                            local skip = (category == "Stat Augs" and CachedData.AugInnateFamily == 10 and value == 0) 
                                      or (category == "Resistance Augs" and CachedData.AugResistanceFamily == 2 and value == 0)
                                      or (augID == IntId.AugmentationSpecializeMagicItemTinkering and CachedData.SkillTrainingMagicItemTinkering == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeWeaponTinkering and CachedData.SkillTrainingWeaponTinkering == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeArmorTinkering and CachedData.SkillTrainingArmorTinkering == SkillTrainingType.Untrained)
                                      or (augID == IntId.AugmentationSpecializeItemTinkering and CachedData.SkillTrainingItemTinkering == SkillTrainingType.Untrained)

                            if not skip then
                                local color = Colors.Yellow
                                if value >= cap then
                                    color = Colors.Green
                                elseif value == 0 then
                                    color = Colors.Red
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
        if CachedData.LuminanceFlagged and imgui.BeginTabItem("Lum") then
            for category, auraList in pairs(TabLuminanceAuras) do
                imgui.SeparatorText(category)
                if imgui.BeginTable("Luminance Auras_"..category, 2) then
                    imgui.TableSetupColumn("Lum Aura",im.ImGuiTableColumnFlags.WidthStretch,200)
                    imgui.TableSetupColumn("Lum Aura Points",im.ImGuiTableColumnFlags.WidthStretch,35)
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    local seerAuraCount = 0
                    for _, auraInfo in ipairs(auraList) do
                        local value = char.Value(auraInfo[2]) or 0
                        local prefix = auraInfo[1]
                        local cap = auraInfo[3]
                        local color = Colors.Yellow
                        local skip = false
    
                        if value >= cap and category == "Nalicana Auras" then
                            value = cap
                        elseif category == "Seer Auras" and auraInfo[2] ~= IntId.LumAugSkilledSpec then
                            value = math.max(0,value-5)
                        end
                        
                        if category == "Seer Auras" then
                            local flag = string.lower(auraInfo[4])
                            skip = not Quests:HasQuestFlag(flag)
                        end

                        if not skip then
                            seerAuraCount = seerAuraCount + 1
                            if value >= cap then
                                color = Colors.Green
                            elseif value == 0 then
                                color = Colors.Red
                            end
        
                            imgui.TableNextRow()
                            imgui.TableSetColumnIndex(0)
                            imgui.TextColored(color, prefix)
                            imgui.TableSetColumnIndex(1)
                            imgui.TextColored(color, value .. "/" .. cap)
                        end
                    end
                    if seerAuraCount == 0 then
                        imgui.TableNextRow()
                        imgui.TableSetColumnIndex(0)
                        imgui.TextColored(Colors.Red, "No Seer Auras")
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
                for _,recallInfo in ipairs(TabRecallSpells) do
                    local spellName = recallInfo[1]
                    local spellID = recallInfo[2]
                    local spellKnown = game.Character.SpellBook.IsKnown(spellID)
                    local color = Colors.Red
                    local status = "Unknown"
                    if spellKnown then
                        color = Colors.Green
                        status = "Known"
                    end
                    imgui.TableNextRow()
                    imgui.TableNextColumn()
                    imgui.Image(GetOrCreateTexture(game.Character.SpellBook.Get(spellID).Icon).TexturePtr,iconVectorSize)
                    imgui.SameLine()
                    imgui.TextColored(color,spellName)
                    imgui.TableNextColumn()
                    imgui.TextColored(color,status)
                end
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        
        -- Society Tab
        if CachedData.FactionBits ~= nil
                and CachedData.FactionBits ~= 0 
                and imgui.BeginTabItem("Society") then
            if imgui.Button("Refresh Quests") then
                Quests:Refresh()
            end
            local factionbits = CachedData.FactionBits
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
            for isocietyrank, thresholds in pairs(MapSocietyRibbons) do
                local lowerT = thresholds.min
                local upperT = thresholds.max
                if factionscore >= lowerT and factionscore <= upperT then
                    societyrank = isocietyrank
                    nextfactionrankscore = upperT
                    maxribbonsperday = thresholds.perday
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
                imgui.TextColored(Colors.Green,stringFactionScore)
                ---@type Quest
                local quest = Quests.Dictionary["societyribbonsperdaycounter"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Ribbons per Day (Counter)")
                    imgui.TableSetColumnIndex(1)
                    imgui.TextColored(Colors.Green,tostring(quest.solves).."/"..tostring(maxribbonsperday))
                end
                ---@type Quest
                local quest = Quests.Dictionary["societyribbonsperdaytimer"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Ribbons per Day (Timer)")
                    imgui.TableSetColumnIndex(1)
                    local questColor = Colors.Red
                    local questStatus = Quests:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = Colors.Green
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                ---@type Quest
                local quest = Quests.Dictionary["societyarmorwritwait"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Society Armor Writ")
                    imgui.TableSetColumnIndex(1)
                    local questColor = Colors.Red
                    local questStatus = Quests:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = Colors.Green
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                ---@type Quest
                local quest = Quests.Dictionary["societymasterstipendcollectiontimer"]
                if quest then
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.Text("Society Master Stipend")
                    imgui.TableSetColumnIndex(1)
                    local questColor = Colors.Red
                    local questStatus = Quests:GetTimeUntilExpire(quest)
                    if questStatus == "Ready" then 
                        questColor = Colors.Green
                    end
                    imgui.TextColored(questColor,questStatus)
                end
                imgui.EndTable()
            end
            for isocietyrank, questList in pairs(TabSocietyQuests) do
                local thresholds = MapSocietyRibbons[isocietyrank]
                local lowerT = thresholds.min
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
                                local questColor = Colors.Yellow
                                local questString = "Ready"
                                imgui.TableNextRow()
                                ---@type Quest
                                local questStart = Quests.Dictionary[socquestStart]
                                ---@type Quest
                                local questEnd = Quests.Dictionary[socquestEnd]
                                if questType == QuestType.QuestTag and Quests:IsQuestAvailable(socquestEnd) then
                                    local tag = string.lower(socquest[5])
                                    ---@type Quest
                                    local completeQuest = Quests.Dictionary[tag]
                                    if completeQuest then
                                        questColor = Colors.Green
                                        questString = "Complete"
                                    else
                                        local startItem = socquest[6]
                                        if game.Character.GetInventoryCount(startItem) > 0 then
                                            questString = "Started"
                                        end
                                    end
                                elseif questType == QuestType.MultiQuestTag and Quests:IsQuestAvailable(socquestEnd) and Quests:HasQuestFlag(socquestStart) then
                                    local tags = socquest[5]
                                    local completeCount = 0
                                    for _, tag in pairs(tags) do
                                        if Quests:HasQuestFlag(string.lower(tag)) then
                                            completeCount = completeCount + 1
                                        end
                                    end
                                    if completeCount >= #tags then
                                        questColor = Colors.Green
                                        questString = "Complete ("..completeCount.."/"..#tags..")"
                                    else
                                        questString = "Started ("..completeCount.."/"..#tags..")"
                                    end
                                elseif questType == QuestType.CollectItem and Quests:IsQuestAvailable(socquestEnd) then
                                    local questItem = socquest[5]
                                    local questItemCount = socquest[6]
                                    local collectedCount = game.Character.GetInventoryCount(questItem)
                                    questString = "Started ("..collectedCount..")"
                                    if collectedCount >= questItemCount then
                                        questColor = Colors.Green
                                        questString = "Complete ("..collectedCount..")"
                                    end
                                elseif questStart then
                                    if questType == QuestType.KillTask then
                                        questString = "Started ("..questStart.solves..")"
                                        if questStart.solves == questStart.maxsolves then
                                            questColor = Colors.Green
                                            questString = "Complete ("..questStart.solves..")"
                                        end
                                    elseif questType == QuestType.Other then
                                        questString = "Started"
                                    elseif questType == QuestType.CollectItem then
                                        local questItem = socquest[5]
                                        local questItemCount = socquest[6]
                                        local collectedCount = game.Character.GetInventoryCount(questItem)
                                        questString = "Started ("..collectedCount..")"
                                        if collectedCount >= questItemCount then
                                            questColor = Colors.Green
                                            questString = "Complete ("..collectedCount..")"
                                        end
                                    end
                                elseif questEnd then
                                    questString = Quests:GetTimeUntilExpire(questEnd)
                                    if questString == "Ready" then
                                        questColor = Colors.Yellow
                                    else
                                        questColor = Colors.Red
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
        if Settings.showFacHub and imgui.BeginTabItem("FacHub") then
            if imgui.Button("Refresh Quests") then
                Quests:Refresh()
            end
            imgui.TextDisabled("[F] = Flagged / [X] = Completed / [U] = Unknown")
            for minLevel, fhquests in pairs(TabFacilityHubQuests) do
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
                            if Quests:HasQuestFlag(fhquestCompleted) then
                                stringFHCompleted = "X"
                                colorQuest = Colors.Green
                            elseif Quests:HasQuestFlag(fhquestStarted) then
                                stringFHCompleted = "F"
                                colorQuest = Colors.Yellow
                            else 
                                stringFHCompleted = "U"
                                colorQuest = Colors.Red
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
                Quests:Refresh()
            end
            for category, flagInfo in pairs(TabCharacterFlags) do
                imgui.Separator()
                imgui.SetNextItemOpen(TreeOpenStates[category] == nil or TreeOpenStates[category])
                TreeOpenStates[category] = imgui.TreeNode(category)
                if TreeOpenStates[category] then
                    if imgui.BeginTable("Character Flags_"..category, 2) then
                        imgui.TableSetupColumn("Flag 1",im.ImGuiTableColumnFlags.WidthStretch,128)
                        imgui.TableSetupColumn("Flag 1 Points",im.ImGuiTableColumnFlags.WidthStretch,64)
                        for _, flag in ipairs(flagInfo) do
                            local prefix = flag[1]
                            local queststamp = flag[2]
                            local questinfotype = flag[3]
                            ---@type Quest
                            local quest = Quests.Dictionary[queststamp]
                            local color = Colors.Red
                            local completionString = "Unknown"
                            if questinfotype == QuestInfoType.SolveCount then
                                if quest ~= nil then
                                    if quest.solves >= quest.maxsolves then
                                        color = Colors.Green
                                    elseif quest.solves == 0 then
                                        color = Colors.Red
                                    end
                                    completionString = tostring(quest.solves) .. "/" .. tostring(quest.maxsolves)
                                else
                                    color = Colors.Red
                                    completionString = "None"
                                end
                            elseif questinfotype == QuestInfoType.StampCheck then
                                if Quests:HasQuestFlag(queststamp) then
                                    color = Colors.Green
                                    completionString = "Yes"
                                else
                                    color = Colors.Red
                                    completionString = "No"
                                end
                            elseif questinfotype == QuestInfoType.ReadyCheck then
                                if Quests:IsQuestAvailable(queststamp) then
                                    color = Colors.Yellow
                                    completionString = "Ready"
                                else completionString = Quests:GetTimeUntilExpire(quest)
                                end
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
            for cantripgroup, cantrips in pairs(TabCantrips) do
                imgui.Separator()
                imgui.SetNextItemOpen(TreeOpenStates[cantripgroup] == nil or TreeOpenStates[cantripgroup])
                TreeOpenStates[cantripgroup] = imgui.TreeNode(cantripgroup)
                if TreeOpenStates[cantripgroup] then
                    if imgui.BeginTable(cantripgroup,2) then
                        imgui.TableSetupColumn(cantripgroup,im.ImGuiTableColumnFlags.WidthStretch,64)
                        imgui.TableSetupColumn("Status",im.ImGuiTableColumnFlags.WidthStretch,32)
                        for effect, info in pairs(cantrips) do
                            if not (info.value == "N/A" and Settings.hideMissingCantrips) then
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
                                imgui.TextColored(MapCantripColors[info.value], info.value)
                            end
                        end
                        imgui.EndTable()
                    end
                    imgui.TreePop()
                end
            end
            imgui.EndTabItem()
        end

        -- Weapons Tab
        if imgui.BeginTabItem("Weapons") then
            if imgui.Button("Refresh") then
                RefreshWeapons()
            end
            -- TODO: Merge Slayers / Resistance Cleaving
            -- TODO: Color Weapons Based On Damage Type
            for cat, types in pairs(TabWeapons) do
                imgui.Separator()
                imgui.SetNextItemOpen(TreeOpenStates[cat] == nil or TreeOpenStates[cat])
                TreeOpenStates[cat] = imgui.TreeNode(cat)
                if TreeOpenStates[cat] then
                    if imgui.BeginTable(cat,2) then
                        imgui.TableSetupColumn(cat,im.ImGuiTableColumnFlags.WidthStretch,16)
                        imgui.TableSetupColumn("Weapon Name",im.ImGuiTableColumnFlags.WidthStretch,32)
                        -- TODO: Do We Need Separate Tracking For Slayers Which Are Non-Essential (Rares/Etc?)
                        for type, values in pairs(types) do
                            local essential = values[3]
                            local myWeapons = values[4]
                            local skipCharacterTypes = values[5]
                            local skip = ((cat == "Rending / Resistance Cleaving") and (not essential) and Settings.hideResistanceCleavingWeapons)
                                or ((cat == "Creature Slayer") and (not essential) and Settings.hideNonEssentialCreatureSlayers)
                            if skipCharacterTypes then
                                for _, ctype in ipairs(skipCharacterTypes) do
                                    if characterTypeSelf == ctype then
                                        skip = true
                                    end
                                end
                            end
                            if not skip then
                                if #myWeapons > 0 then
                                    for _, weaponID in ipairs(myWeapons) do
                                        --- @type WorldObject
                                        local weapon = game.World.Get(weaponID)
                                        if weapon then
                                            imgui.TableNextRow()
                                            imgui.TableSetColumnIndex(0)
                                            imgui.TextColored(Colors.Green,type)
                                            imgui.TableSetColumnIndex(1)
                                            local pos = imgui.GetCursorScreenPos()
                                            local icon = GetOrCreateTexture(weapon.DataValues[DataId.Icon])
                                            local iconUnderlayID = weapon.DataValues[DataId.IconUnderlay]
                                            if not iconUnderlayID then
                                                iconUnderlayID = 0x060011CB
                                            end
                                            local iconUnderlayTexture = GetOrCreateTexture(iconUnderlayID)
                                            local iconOverlay = GetOrCreateTexture(weapon.DataValues[DataId.IconOverlay])
                                            imgui.Image(iconUnderlayTexture.TexturePtr,iconVectorSize)
                                            imgui.SetCursorScreenPos(pos)
                                            imgui.Image(icon.TexturePtr,iconVectorSize)
                                            imgui.SetCursorScreenPos(pos)
                                            imgui.Image(iconOverlay.TexturePtr,iconVectorSize)
                                            if imgui.IsItemClicked() then
                                                game.Actions.ObjectSelect(weapon.Id)
                                            end
                                            imgui.SameLine()
                                            imgui.TextColored(Colors.Green,weapon.Name)
                                            if imgui.IsItemClicked() then
                                                game.Actions.ObjectSelect(weapon.Id)
                                            end
                                        end
                                    end
                                elseif not Settings.hideUnacquiredWeapons then
                                    imgui.TableNextRow()
                                    imgui.TableSetColumnIndex(0)
                                    imgui.TextColored(Colors.White,type)
                                    imgui.TableSetColumnIndex(1)
                                    imgui.TextColored(Colors.LightGray,"No Weapon Found")
                                end
                            end
                        end
                        imgui.EndTable()
                    end
                    imgui.TreePop()
                end
            end
            imgui.EndTabItem()
        end

        -- General Quests Tab
        if Settings.showQuests and imgui.BeginTabItem("Quests") then
            if imgui.Button("Refresh Quests") then
                Quests:Refresh()
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
                    table.sort(Quests.List,function(a,b) 
                        local sortcol = sort_specs.Specs.ColumnIndex + 1
                        local sortasc = sort_specs.Specs.SortDirection == im.ImGuiSortDirection.Ascending
                        if a and b then
                            local valA = Quests:GetFieldByID(a,sortcol)
                            local valB = Quests:GetFieldByID(b,sortcol)
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
                for _, quest in ipairs(Quests.List) do
                    local color = Colors.Red
                    if Quests:IsQuestMaxSolved(quest.id) then
                        color = Colors.Yellow
                    elseif Quests:IsQuestAvailable(quest.id) then
                        color = Colors.Green
                    end
                    imgui.TableNextRow()
                    imgui.TableSetColumnIndex(0)
                    imgui.TextColored(color, quest.id) -- Quest Name
                    if imgui.IsItemHovered() and Quests.Description then
                        imgui.SetTooltip(Quests.Description)
                    end
                    imgui.TableSetColumnIndex(1)
                    imgui.TextColored(color, quest.solves) -- Solves
                    imgui.TableSetColumnIndex(2)
                    imgui.TextColored(color, Quests:FormatTimeStamp(quest.timestamp)) -- Timestamp
                    imgui.TableSetColumnIndex(3)
                    imgui.TextColored(color, quest.maxsolves) -- MaxSolves
                    imgui.TableSetColumnIndex(4)
                    imgui.TextColored(color, quest.delta) -- Delta
                    imgui.TableSetColumnIndex(5)
                    imgui.TextColored(color, Quests:GetTimeUntilExpire(quest)) -- Expired
                end
        
                imgui.EndTable()
            end
            imgui.EndTabItem()
        end
        
        -- Settings Tab
        if imgui.BeginTabItem("Settings") then
            imgui.SeparatorText("Tab Visibility")
            if imgui.Checkbox("Show Fac Hub",Settings.showFacHub) then
                Settings.showFacHub = not Settings.showFacHub
            end
            if imgui.Checkbox("Show Quests",Settings.showQuests) then
                Settings.showQuests = not Settings.showQuests
            end
            if imgui.Checkbox("Hide Unacquired Weapons",Settings.hideUnacquiredWeapons) then
                Settings.hideUnacquiredWeapons = not Settings.hideUnacquiredWeapons
            end
            if imgui.Checkbox("Hide Resistance Cleaving Weapons",Settings.hideResistanceCleavingWeapons) then
                Settings.hideResistanceCleavingWeapons = not Settings.hideResistanceCleavingWeapons
            end
            if imgui.Checkbox("Hide Non-Essential Slayer Weapons",Settings.hideNonEssentialCreatureSlayers) then
                Settings.hideNonEssentialCreatureSlayers = not Settings.hideNonEssentialCreatureSlayers
            end
            if imgui.Checkbox("Hide Missing Cantrips",Settings.hideMissingCantrips) then
                Settings.hideMissingCantrips = not Settings.hideMissingCantrips
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

Quests:Refresh()
RefreshCantrips()
RefreshWeapons()