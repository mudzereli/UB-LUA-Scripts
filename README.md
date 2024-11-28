# Porkchop's Utility Belt LUA Scripts

## Installation

1. Make sure your [Decal](https://www.decaldev.com) is up to date: `2.9.8.3`
2. Make sure you are using the latest beta of [UtilityBelt](https://gitlab.com/utilitybelt/utilitybelt.gitlab.io/-/packages/)
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
- This LUA script is designed so that your main character can run a Nav with other characters following, but it will stop Navigation on the main character if the fellowship members get too far away
- Load the script and then press the `Run NavTogether` button from the Script Hud Bar.
- Interval between Distance Checks and Allowable Range can be changed from the UI which is accessible through the Script Hud Bar.

### FlagTracker
- This LUA script is designed to view important one-time character flags such as Augmentations, Luminance Auras, and certain Quest Flags
- Load the script and then open the UI from the Script Hud Bar.