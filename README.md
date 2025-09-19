# Porkchop's Utility Belt LUA Scripts

## Installation

1. Make sure your [Decal](https://www.decaldev.com) is up to date: `2.9.8.3`
2. Make sure you are using the beta version of [UtilityBelt](https://gitlab.com/utilitybelt/utilitybelt.gitlab.io/-/packages/45801746)
3. Make sure you are using the latest [UtilityBelt Service](https://gitlab.com/utilitybelt/utilitybelt.service/-/releases)
4. Download the [LUA Scripts](https://github.com/mudzereli/UB-LUA-Scripts/archive/refs/heads/main.zip)
5. Extract the folders for the scripts you want to use to your `UtilityBelt\scripts` folder.
    - Usually `C:\Users\<username>\Documents\Decal Plugins\UtilityBelt\scripts`

### RarePointer 
- Upon loading, it marks all existing corpses containing Rare Items with an arrow.
- After loading, any new corpses that are created and contain Rare Items are also marked with an arrow.
- Some options such as Arrow Color & Size are configurable in the UI which is accessible through the Script Hud Bar.

### SummonScribe
- Will inscribe all summons with their percentage of max damage output.
- Load the script and then press the `Run Summon Scribe` button from the Script Hud Bar.
- Pre-score inscription message and decimal rounding can be changed from the UI which is accessible through the Script Hud Bar.
>[!WARNING]
> Items outside of the main pack are not counted as Character Inventory in GDLE, so if you run this script on GDLE, then make sure the summons are in your main pack!

### NavTogether
- This LUA script is designed so that your main character can run a Nav with other characters following, but it will stop Navigation on the main character if the fellowship members get too far away.
- Load the script and then press the `Run NavTogether` button from the Script Hud Bar.
- Interval between Distance Checks and Allowable Range can be changed from the UI which is accessible through the Script Hud Bar.

### FlagTracker
- This LUA script is designed to view important one-time character flags such as:
    - Augmentations
    - Luminance Auras (Including Seer Auras)
    - Learned Recall Spells
    - Society Rank & Quests
    - Skill Credit Quests
    - Aetheria Unlocks
    - Weekly Augmentation Gems
    - Access Flags (Vissidal, Dark Isle, Bur, Etc)
    - Other Flags (Luminance Unlock, Diemos Access)
- Load the script and then open the UI from the Script Hud Bar.

![flagtracker_ui1](https://i.ibb.co/Nr3ryW2/image-2024-12-31-080246218.png)

### QuestHelper
- This LUA script is to help you complete quests by converting a pasted list of steps (from ACPedia or ACFandom) to a checkable list.
- Load the script and open the UI from the Script Hud Bar.
- Open the `Quest Text` tab and then paste the steps from ACPedia or ACFandom into the text box.
- Switch to the `Quest Steps` tab and you will now see that the pasted information has been converted to checkable boxes.
- As you complete the quest, check the boxes to keep track of your progress.
- Editing the `Quest Text` box will reset the `Quest Steps` tab so you can start another quest (or reset a current one) by pasting new steps in here.
